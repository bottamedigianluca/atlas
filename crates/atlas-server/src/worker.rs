//! Il worker: l'unico scrittore del database ATLAS, su un thread suo con un runtime
//! `current_thread`.
//!
//! Esegue i comandi delle API (salvataggio con la numerazione unica, rinumerazione, numeri
//! liberi) e, nel tempo che resta, i giri di sincronizzazione con Arca:
//! - replica dell'outbox, svegliata a ogni salvataggio e poi all'istante della riprova del primo
//!   evento in coda (non ogni secondo come il binario `replica`);
//! - importazione dei documenti scritti, modificati o cancellati in Arca, ogni secondo.
//!
//! Un comando ha la precedenza: se arriva durante un giro, il giro si interrompe (al punto di
//! attesa della rete: nessuna transazione SQLite è aperta durante un'attesa) e la connessione di
//! quel giro si chiude, perché resterebbe in uno stato incerto; il giro riparte dopo il comando.
//! Così un salvataggio non aspetta mai Arca oltre `ATTESA_ARCA` (lettura dei numeri). La replica
//! interrotta dopo il commit in Arca ritrova il documento già presente al giro successivo.
//!
//! Le connessioni ad Arca sono tre e restano aperte: numeri (al salvataggio), importazione,
//! replica. Tutte dalla stessa stringa ADO; la replica rifiuta un database diverso da quello da
//! cui il file ATLAS importa.

use std::cell::Cell;
use std::time::Duration;

use atlas_core::numerazione::{NumeroNonValido, Sezionale, TipoDocumento};
use atlas_db::ddt::{self, TIPO_DOCUMENTO};
use atlas_db::note::{self, CampiNota, Nota};
use atlas_db::{ErroreDb, importazione as stato_importazione, outbox};
use atlas_sync::clienti::NuovoCliente;
use atlas_sync::importazione::{self, Origine};
use atlas_sync::numerazione::{self, ATTESA_ARCA};
use atlas_sync::replica::{self, Destinazione};
use chrono::{Datelike, Local, NaiveDate, NaiveDateTime, Timelike};
use rusqlite::Connection;
use rust_decimal::Decimal;
use serde::Serialize;
use tokio::sync::{broadcast, mpsc, oneshot, watch};
use tokio::time::Instant;

use crate::bozza::{self, Bozza};
use crate::config::Predefiniti;
use crate::errore::ErroreApi;

/// Eventi replicati per giro: un giro breve lascia passare presto il comando successivo.
pub const EVENTI_PER_GIRO: usize = 20;
/// Documenti importati per giro: pochi da tenere breve la transazione SQLite.
pub const DOCUMENTI_PER_GIRO: usize = 200;
/// Pausa fra due giri di importazione in pari con Arca.
pub const PAUSA_IMPORTAZIONE: Duration = Duration::from_secs(1);
/// Pausa dopo un giro fallito (Arca spenta, rete).
pub const PAUSA_ERRORE: Duration = Duration::from_secs(5);
/// Un giro che non finisce entro questo tempo viene abbandonato e la connessione chiusa.
pub const ATTESA_GIRO: Duration = Duration::from_secs(60);
/// Attesa massima di Arca per una rinumerazione, connessione compresa.
pub const ATTESA_RINUMERA: Duration = Duration::from_secs(5);

const SEZIONALE: Sezionale = TipoDocumento::BollaVendita.sezionale();
const SENZA_ARCA: &str = "Arca non configurata";

/// Al secondo, come gli altri istanti del database ATLAS.
pub fn adesso() -> NaiveDateTime {
    let adesso = Local::now().naive_local();
    adesso.with_nanosecond(0).unwrap_or(adesso)
}

/// La replica verso Arca come la usa il worker.
#[allow(async_fn_in_trait)]
pub trait Replica: Destinazione {
    /// Lega la replica al database da cui il file ATLAS importa.
    fn lega(&mut self, database: &str);
    /// Chiude la connessione dopo un giro interrotto.
    fn scollega(&mut self);
}

impl Replica for replica::Arca {
    fn lega(&mut self, database: &str) {
        replica::Arca::lega(self, database);
    }

    fn scollega(&mut self) {
        replica::Arca::scollega(self);
    }
}

/// Le connessioni ad Arca del worker; senza, il worker numera sul solo database ATLAS.
#[derive(Debug)]
pub struct Sorgenti<O, D> {
    pub numeri: Option<O>,
    pub importazione: Option<O>,
    pub replica: Option<D>,
}

impl Sorgenti<importazione::Arca, replica::Arca> {
    pub fn arca(ado: Option<&str>) -> Self {
        Self {
            numeri: ado.map(importazione::Arca::nuova),
            importazione: ado.map(importazione::Arca::nuova),
            replica: ado.map(replica::Arca::nuova),
        }
    }
}

/// Un DDT appena salvato.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct DdtCreato {
    pub id: i64,
    /// Evento di replica accodato.
    pub evento: i64,
    pub esercizio: i32,
    pub numero: u32,
    pub data: NaiveDate,
    pub cliente: String,
    pub totale_imponibile: Decimal,
    pub totale_imposta: Decimal,
    pub totale_documento: Decimal,
    /// Perché il numero è stato deciso senza i documenti di Arca: va detto all'operatore, alla
    /// replica il numero potrebbe risultare occupato.
    pub senza_arca: Option<String>,
}

/// Un cliente nuovo appena salvato in ATLAS.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ClienteCreato {
    pub codice: String,
    /// Evento di replica accodato.
    pub evento: i64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Rinumerato {
    pub id: i64,
    pub esercizio: i32,
    pub prima: u32,
    pub numero: u32,
}

/// Buchi della numerazione dei DDT (tasto `F3` sul numero).
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct NumeriLiberi {
    pub esercizio: i32,
    pub liberi: Vec<atlas_core::numerazione::Liberi>,
    /// Il numero che avrebbe un nuovo DDT con data di oggi (o dell'ultimo giorno dell'esercizio).
    pub prossimo: Option<u32>,
    pub senza_arca: Option<String>,
}

pub enum Comando {
    Crea {
        bozza: Bozza,
        risposta: oneshot::Sender<Result<DdtCreato, ErroreApi>>,
    },
    Rinumera {
        id: i64,
        risposta: oneshot::Sender<Result<Rinumerato, ErroreApi>>,
    },
    Liberi {
        esercizio: i32,
        risposta: oneshot::Sender<Result<NumeriLiberi, ErroreApi>>,
    },
    /// Cliente nuovo: salvato in ATLAS e accodato per Arca (`CF`, `CFContatto`).
    CreaCliente {
        cliente: Box<NuovoCliente>,
        risposta: oneshot::Sender<Result<ClienteCreato, ErroreApi>>,
    },
    /// Giri di replica e importazione subito.
    Sincronizza { risposta: oneshot::Sender<()> },
    /// Post-it della Home: crea, modifica o elimina (allora la risposta è `None`).
    Nota {
        operazione: OperazioneNota,
        risposta: oneshot::Sender<Result<Option<Nota>, ErroreApi>>,
    },
}

#[derive(Debug)]
pub enum OperazioneNota {
    Crea(CampiNota),
    Aggiorna(i64, CampiNota),
    Elimina(i64),
}

impl std::fmt::Debug for Comando {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Crea { bozza, .. } => f.debug_struct("Crea").field("cliente", &bozza.cliente).finish(),
            Self::Rinumera { id, .. } => f.debug_struct("Rinumera").field("id", id).finish(),
            Self::Liberi { esercizio, .. } => f.debug_struct("Liberi").field("esercizio", esercizio).finish(),
            Self::CreaCliente { cliente, .. } => f.debug_struct("CreaCliente").field("codice", &cliente.codice()).finish(),
            Self::Sincronizza { .. } => f.write_str("Sincronizza"),
            Self::Nota { operazione, .. } => f.debug_tuple("Nota").field(operazione).finish(),
        }
    }
}

/// Documento di Arca su cui l'importazione è ferma.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct FermoImportazione {
    pub arca_id_testata: i32,
    pub errore: String,
    pub esercizio: Option<i32>,
    pub numero: Option<u32>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize)]
pub struct StatoReplica {
    pub configurata: bool,
    pub ultimo_giro: Option<NaiveDateTime>,
    /// Dall'avvio del backend.
    pub scritti: usize,
    pub gia_presenti: usize,
    /// Errore dell'ultimo giro (database ATLAS, giro abbandonato): non di un evento, che ha il
    /// suo errore nella coda.
    pub errore: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize)]
pub struct StatoImportazione {
    pub configurata: bool,
    pub ultimo_giro: Option<NaiveDateTime>,
    /// Dall'avvio del backend.
    pub nuovi: usize,
    pub aggiornati: usize,
    pub collegati: usize,
    pub esclusi: usize,
    pub cancellati: usize,
    pub fermo: Option<FermoImportazione>,
    pub errore: Option<String>,
}

/// Stato dei giri di sincronizzazione, pubblicato dal worker.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize)]
pub struct StatoSync {
    pub replica: StatoReplica,
    pub importazione: StatoImportazione,
}

impl StatoSync {
    /// Stesso stato a meno degli istanti dei giri: solo i cambiamenti veri si notificano.
    fn equivale(&self, altro: &Self) -> bool {
        let senza_istanti = |s: &Self| {
            let mut s = s.clone();
            s.replica.ultimo_giro = None;
            s.importazione.ultimo_giro = None;
            s
        };
        senza_istanti(self) == senza_istanti(altro)
    }
}

/// Notifiche ai client WebSocket: `{"evento": "...", "dati": {...}}`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(tag = "evento", content = "dati", rename_all = "snake_case")]
pub enum Notifica {
    DdtCreato(DdtCreato),
    DdtRinumerato(Rinumerato),
    ClienteCreato(ClienteCreato),
    /// Documenti scritti in Arca da un giro di replica.
    Replica { scritti: usize, gia_presenti: usize, fallito: Option<(i64, String)> },
    /// Documenti del database ATLAS cambiati da un giro di importazione.
    Importazione {
        nuovi: usize,
        aggiornati: usize,
        collegati: usize,
        esclusi: usize,
        cancellati: usize,
    },
    Stato(StatoSync),
    /// I post-it della Home sono cambiati: i client li rileggono (`GET /api/note`).
    NoteCambiate,
}

/// Il worker in esecuzione.
#[derive(Debug)]
pub struct Maniglia {
    pub comandi: mpsc::Sender<Comando>,
    pub stato: watch::Receiver<StatoSync>,
    thread: std::thread::JoinHandle<()>,
}

impl Maniglia {
    /// Attende la fine del worker, che termina quando tutti i mittenti dei comandi sono chiusi.
    pub fn attendi(self) {
        drop(self.comandi);
        let _ = self.thread.join();
    }
}

/// Avvia il worker sul database `db`, già aperto in scrittura e migrato.
pub fn avvia<O, D>(
    db: Connection,
    sorgenti: Sorgenti<O, D>,
    predefiniti: Predefiniti,
    notifiche: broadcast::Sender<Notifica>,
) -> std::io::Result<Maniglia>
where
    O: Origine + Send + 'static,
    D: Replica + Send + 'static,
{
    let (comandi, ricevuti) = mpsc::channel(64);
    let iniziale = StatoSync {
        replica: StatoReplica {
            configurata: sorgenti.replica.is_some(),
            ..StatoReplica::default()
        },
        importazione: StatoImportazione {
            configurata: sorgenti.importazione.is_some(),
            ..StatoImportazione::default()
        },
    };
    let (stato, osservato) = watch::channel(iniziale);
    let runtime = tokio::runtime::Builder::new_current_thread().enable_all().build()?;
    let thread = std::thread::Builder::new().name("atlas-worker".into()).spawn(move || {
        let worker = Worker {
            db,
            numeri: sorgenti.numeri,
            importazione: sorgenti.importazione,
            replica: sorgenti.replica,
            predefiniti,
            notifiche,
            stato,
            prossima_replica: None,
            prossima_importazione: Instant::now(),
        };
        runtime.block_on(worker.esegui(ricevuti));
    })?;
    Ok(Maniglia {
        comandi,
        stato: osservato,
        thread,
    })
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Lavoro {
    Replica,
    Importazione,
}

enum Evento {
    Comando(Option<Comando>),
    Fatto,
    Tempo,
}

struct Worker<O, D> {
    db: Connection,
    numeri: Option<O>,
    importazione: Option<O>,
    replica: Option<D>,
    predefiniti: Predefiniti,
    notifiche: broadcast::Sender<Notifica>,
    stato: watch::Sender<StatoSync>,
    /// Quando replicare: `None` con la coda vuota.
    prossima_replica: Option<Instant>,
    prossima_importazione: Instant,
}

/// L'istante del database (ora locale) come istante del runtime.
fn istante(quando: NaiveDateTime) -> Instant {
    let attesa = (quando - adesso()).to_std().unwrap_or_default();
    Instant::now() + attesa
}

impl<O: Origine, D: Replica> Worker<O, D> {
    async fn esegui(mut self, mut comandi: mpsc::Receiver<Comando>) {
        self.pianifica_replica();
        loop {
            let ora = Instant::now();
            let replica_dovuta = self.replica.is_some() && self.prossima_replica.is_some_and(|p| p <= ora);
            let importazione_dovuta = self.importazione.is_some() && self.prossima_importazione <= ora;
            let lavoro = if replica_dovuta {
                Some(Lavoro::Replica)
            } else if importazione_dovuta {
                Some(Lavoro::Importazione)
            } else {
                None
            };
            let evento = match lavoro {
                Some(lavoro) => {
                    let iniziato = Cell::new(false);
                    let evento = tokio::select! {
                        biased;
                        comando = comandi.recv() => Evento::Comando(comando),
                        () = self.lavora(lavoro, &iniziato) => Evento::Fatto,
                    };
                    if matches!(evento, Evento::Comando(_)) && iniziato.get() {
                        self.interrotto(lavoro);
                    }
                    evento
                }
                None => {
                    let scadenza = self.scadenza();
                    tokio::select! {
                        biased;
                        comando = comandi.recv() => Evento::Comando(comando),
                        () = tokio::time::sleep_until(scadenza) => Evento::Tempo,
                    }
                }
            };
            match evento {
                Evento::Comando(None) => break,
                Evento::Comando(Some(comando)) => self.gestisci(comando).await,
                Evento::Fatto | Evento::Tempo => {}
            }
        }
    }

    fn scadenza(&self) -> Instant {
        let mut scadenza = Instant::now() + Duration::from_secs(3600);
        if self.replica.is_some() {
            if let Some(p) = self.prossima_replica {
                scadenza = scadenza.min(p);
            }
        }
        if self.importazione.is_some() {
            scadenza = scadenza.min(self.prossima_importazione);
        }
        scadenza
    }

    /// Prossima replica dal primo evento in coda.
    fn pianifica_replica(&mut self) {
        self.prossima_replica = match outbox::prossimo_tentativo(&self.db, adesso()) {
            Ok(prossimo) => prossimo.map(istante),
            Err(e) => {
                self.aggiorna_stato(|s| s.replica.errore = Some(e.to_string()));
                Some(Instant::now() + PAUSA_ERRORE)
            }
        };
    }

    /// Un giro interrotto da un comando: la sua connessione è in uno stato incerto.
    fn interrotto(&mut self, lavoro: Lavoro) {
        match lavoro {
            Lavoro::Replica => {
                if let Some(r) = self.replica.as_mut() {
                    r.scollega();
                }
            }
            Lavoro::Importazione => {
                if let Some(o) = self.importazione.as_mut() {
                    o.scollega();
                }
            }
        }
    }

    fn aggiorna_stato(&self, modifica: impl FnOnce(&mut StatoSync)) {
        let mut cambiato = None;
        self.stato.send_if_modified(|stato| {
            let prima = stato.clone();
            modifica(stato);
            let vero = !prima.equivale(stato);
            if vero {
                cambiato = Some(stato.clone());
            }
            vero || prima != *stato
        });
        if let Some(stato) = cambiato {
            let _ = self.notifiche.send(Notifica::Stato(stato));
        }
    }

    async fn lavora(&mut self, lavoro: Lavoro, iniziato: &Cell<bool>) {
        iniziato.set(true);
        match lavoro {
            Lavoro::Replica => self.giro_replica().await,
            Lavoro::Importazione => self.giro_importazione().await,
        }
    }

    async fn giro_replica(&mut self) {
        let Some(destinazione) = self.replica.as_mut() else {
            return;
        };
        match stato_importazione::punto(&self.db, TIPO_DOCUMENTO) {
            Ok(Some(punto)) => destinazione.lega(&punto.database),
            Ok(None) => {}
            Err(e) => {
                self.aggiorna_stato(|s| s.replica.errore = Some(e.to_string()));
                self.prossima_replica = Some(Instant::now() + PAUSA_ERRORE);
                return;
            }
        }
        let esito = tokio::time::timeout(ATTESA_GIRO, replica::giro(&self.db, destinazione, adesso, EVENTI_PER_GIRO)).await;
        let ora = adesso();
        match esito {
            Ok(Ok(giro)) => {
                if giro.replicati() > 0 || giro.fallito.is_some() {
                    let _ = self.notifiche.send(Notifica::Replica {
                        scritti: giro.scritti,
                        gia_presenti: giro.gia_presenti,
                        fallito: giro.fallito.clone(),
                    });
                }
                self.aggiorna_stato(|s| {
                    s.replica.ultimo_giro = Some(ora);
                    s.replica.scritti += giro.scritti;
                    s.replica.gia_presenti += giro.gia_presenti;
                    s.replica.errore = None;
                });
                self.pianifica_replica();
            }
            Ok(Err(e)) => {
                destinazione_scollega(&mut self.replica);
                self.aggiorna_stato(|s| {
                    s.replica.ultimo_giro = Some(ora);
                    s.replica.errore = Some(e.to_string());
                });
                self.prossima_replica = Some(Instant::now() + PAUSA_ERRORE);
            }
            Err(_) => {
                destinazione_scollega(&mut self.replica);
                self.aggiorna_stato(|s| {
                    s.replica.ultimo_giro = Some(ora);
                    s.replica.errore = Some(format!("giro di replica oltre {} s, abbandonato", ATTESA_GIRO.as_secs()));
                });
                self.prossima_replica = Some(Instant::now() + PAUSA_ERRORE);
            }
        }
    }

    async fn giro_importazione(&mut self) {
        let Some(origine) = self.importazione.as_mut() else {
            return;
        };
        let esito =
            tokio::time::timeout(ATTESA_GIRO, importazione::giro(&mut self.db, origine, adesso, DOCUMENTI_PER_GIRO)).await;
        let ora = adesso();
        match esito {
            Ok(Ok(giro)) => {
                if giro.cambiati() > 0 {
                    let _ = self.notifiche.send(Notifica::Importazione {
                        nuovi: giro.nuovi,
                        aggiornati: giro.aggiornati,
                        collegati: giro.collegati,
                        esclusi: giro.esclusi,
                        cancellati: giro.cancellati,
                    });
                }
                let fermo = giro.fermo.as_ref().map(|(id, errore)| FermoImportazione {
                    arca_id_testata: *id,
                    errore: errore.clone(),
                    esercizio: giro.conteso.map(|c| c.0),
                    numero: giro.conteso.map(|c| c.1),
                });
                self.aggiorna_stato(|s| {
                    let i = &mut s.importazione;
                    i.ultimo_giro = Some(ora);
                    i.nuovi += giro.nuovi;
                    i.aggiornati += giro.aggiornati;
                    i.collegati += giro.collegati;
                    i.esclusi += giro.esclusi;
                    i.cancellati += giro.cancellati;
                    i.fermo = fermo;
                    i.errore = None;
                });
                // Ancora documenti da leggere: subito un altro giro.
                let pausa = if giro.letti >= DOCUMENTI_PER_GIRO && giro.fermo.is_none() {
                    Duration::ZERO
                } else {
                    PAUSA_IMPORTAZIONE
                };
                self.prossima_importazione = Instant::now() + pausa;
            }
            Ok(Err(e)) => {
                origine_scollega(&mut self.importazione);
                self.aggiorna_stato(|s| {
                    s.importazione.ultimo_giro = Some(ora);
                    s.importazione.errore = Some(e.to_string());
                });
                self.prossima_importazione = Instant::now() + PAUSA_ERRORE;
            }
            Err(_) => {
                origine_scollega(&mut self.importazione);
                self.aggiorna_stato(|s| {
                    s.importazione.ultimo_giro = Some(ora);
                    s.importazione.errore =
                        Some(format!("giro di importazione oltre {} s, abbandonato", ATTESA_GIRO.as_secs()));
                });
                self.prossima_importazione = Instant::now() + PAUSA_ERRORE;
            }
        }
    }

    async fn gestisci(&mut self, comando: Comando) {
        match comando {
            Comando::Crea { bozza, risposta } => {
                let esito = self.crea(&bozza).await;
                if let Ok(creato) = &esito {
                    let _ = self.notifiche.send(Notifica::DdtCreato(creato.clone()));
                    self.prossima_replica = Some(Instant::now());
                }
                let _ = risposta.send(esito);
            }
            Comando::Rinumera { id, risposta } => {
                let esito = self.rinumera(id).await;
                if let Ok(rinumerato) = &esito {
                    let _ = self.notifiche.send(Notifica::DdtRinumerato(rinumerato.clone()));
                    // Il DDT si può replicare subito e l'importazione ferma sul conflitto riparte.
                    self.prossima_replica = Some(Instant::now());
                    self.prossima_importazione = Instant::now();
                }
                let _ = risposta.send(esito);
            }
            Comando::Liberi { esercizio, risposta } => {
                let _ = risposta.send(self.liberi(esercizio).await);
            }
            Comando::CreaCliente { mut cliente, risposta } => {
                let esito = self.crea_cliente(&mut cliente);
                if let Ok(creato) = &esito {
                    let _ = self.notifiche.send(Notifica::ClienteCreato(creato.clone()));
                    self.prossima_replica = Some(Instant::now());
                }
                let _ = risposta.send(esito);
            }
            Comando::Sincronizza { risposta } => {
                self.prossima_replica = Some(Instant::now());
                self.prossima_importazione = Instant::now();
                let _ = risposta.send(());
            }
            Comando::Nota { operazione, risposta } => {
                let esito = self.nota(operazione);
                if esito.is_ok() {
                    let _ = self.notifiche.send(Notifica::NoteCambiate);
                }
                let _ = risposta.send(esito);
            }
        }
    }

    /// Completa il cliente con i predefiniti di Arca, lo controlla e lo salva con il suo evento.
    fn crea_cliente(&mut self, cliente: &mut NuovoCliente) -> Result<ClienteCreato, ErroreApi> {
        let adesso = adesso();
        cliente.completa(&self.predefiniti.operatore, adesso);
        let problemi = cliente.controlla();
        if !problemi.is_empty() {
            return Err(ErroreApi::Bozza(problemi));
        }
        let payload = serde_json::to_string(&cliente).map_err(ErroreDb::from)?;
        let contatto = cliente.contatto.as_ref().map(|c| serde_json::Value::Object(c.clone()).to_string());
        let salvato = atlas_db::anagrafiche::crea_cliente(&mut self.db, &cliente.in_atlas(), contatto.as_deref(), &payload, adesso)?;
        Ok(ClienteCreato {
            codice: salvato.codice,
            evento: salvato.evento,
        })
    }

    fn nota(&self, operazione: OperazioneNota) -> Result<Option<Nota>, ErroreApi> {
        let adesso = adesso();
        Ok(match operazione {
            OperazioneNota::Crea(campi) => Some(note::crea(&self.db, &campi, &self.predefiniti.operatore, adesso)?),
            OperazioneNota::Aggiorna(id, campi) => Some(note::aggiorna(&self.db, id, &campi, adesso)?),
            OperazioneNota::Elimina(id) => {
                note::elimina(&self.db, id)?;
                None
            }
        })
    }

    async fn crea(&mut self, bozza: &Bozza) -> Result<DdtCreato, ErroreApi> {
        let adesso = adesso();
        let calcolo = bozza::calcola(&self.db, bozza, &self.predefiniti, adesso)?;
        let castelletto = calcolo.castelletto.clone();
        let mut documento = calcolo.in_ddt()?;
        let (salvato, senza_arca) = match bozza.numero {
            None => match self.numeri.as_mut() {
                Some(origine) => {
                    let creato = numerazione::crea(&mut self.db, origine, &mut documento, adesso, ATTESA_ARCA).await?;
                    (creato.salvato, creato.senza_arca)
                }
                None => (
                    ddt::crea(&mut self.db, &mut documento, &Default::default(), adesso)?,
                    Some(SENZA_ARCA.to_owned()),
                ),
            },
            // Numero scelto a mano: libero anche fra i documenti di Arca non ancora importati.
            Some(numero) => {
                let esercizio = documento.data.year();
                let senza_arca = match self.numeri.as_mut() {
                    Some(origine) => match numerazione::numeri_di_arca(origine, esercizio, ATTESA_ARCA).await {
                        Ok(arca) => {
                            arca.verifica(SEZIONALE.regola(), numero, documento.data)
                                .map_err(|e| errore_numero(e, esercizio))?;
                            None
                        }
                        Err(motivo) => Some(motivo),
                    },
                    None => Some(SENZA_ARCA.to_owned()),
                };
                (ddt::salva(&mut self.db, &documento, adesso)?, senza_arca)
            }
        };
        Ok(DdtCreato {
            id: salvato.id,
            evento: salvato.evento,
            esercizio: documento.data.year(),
            numero: documento.numero,
            data: documento.data,
            cliente: documento.cliente,
            totale_imponibile: castelletto.totale_imponibile,
            totale_imposta: castelletto.totale_imposta,
            totale_documento: castelletto.totale_documento,
            senza_arca,
        })
    }

    async fn rinumera(&mut self, id: i64) -> Result<Rinumerato, ErroreApi> {
        let prima = match ddt::carica(&self.db, id) {
            Err(ErroreDb::NonTrovato(_)) => return Err(ErroreApi::NonTrovato(format!("DDT {id}"))),
            esito => esito?,
        };
        let Some(origine) = self.numeri.as_mut() else {
            return Err(ErroreApi::NonDisponibile(format!("{SENZA_ARCA}: per rinumerare serve leggere Arca")));
        };
        match tokio::time::timeout(ATTESA_RINUMERA, numerazione::rinumera(&mut self.db, origine, id)).await {
            Ok(esito) => {
                let numero = esito.inspect_err(|_| origine.scollega())?;
                Ok(Rinumerato {
                    id,
                    esercizio: prima.data.year(),
                    prima: prima.numero,
                    numero,
                })
            }
            Err(_) => {
                origine.scollega();
                Err(ErroreApi::NonDisponibile(format!(
                    "Arca non ha risposto entro {} s: DDT non rinumerato",
                    ATTESA_RINUMERA.as_secs()
                )))
            }
        }
    }

    async fn liberi(&mut self, esercizio: i32) -> Result<NumeriLiberi, ErroreApi> {
        let (arca, senza_arca) = match self.numeri.as_mut() {
            Some(origine) => match numerazione::numeri_di_arca(origine, esercizio, ATTESA_ARCA).await {
                Ok(numeri) => (numeri, None),
                Err(motivo) => (Default::default(), Some(motivo)),
            },
            None => (Default::default(), Some(SENZA_ARCA.to_owned())),
        };
        let mut numeri = atlas_db::numerazione::occupati(&self.db, SEZIONALE, esercizio)?;
        numeri.unisci(&arca);
        let oggi = adesso().date();
        let data = if oggi.year() == esercizio {
            Some(oggi)
        } else {
            NaiveDate::from_ymd_opt(esercizio, 12, 31)
        };
        Ok(NumeriLiberi {
            esercizio,
            liberi: numeri.liberi(),
            prossimo: data.and_then(|d| numeri.prossimo(SEZIONALE.regola(), d).ok()),
            senza_arca,
        })
    }
}

fn destinazione_scollega<D: Replica>(replica: &mut Option<D>) {
    if let Some(r) = replica.as_mut() {
        r.scollega();
    }
}

fn origine_scollega<O: Origine>(origine: &mut Option<O>) {
    if let Some(o) = origine.as_mut() {
        o.scollega();
    }
}

/// Come `atlas_db::numerazione::errore`: un numero di un altro documento è sempre
/// [`ErroreDb::NumeroOccupato`].
fn errore_numero(e: NumeroNonValido, esercizio: i32) -> ErroreDb {
    match e {
        NumeroNonValido::Occupato { numero, .. } => ErroreDb::NumeroOccupato { esercizio, numero },
        e => ErroreDb::Numerazione(e),
    }
}
