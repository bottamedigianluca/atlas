//! Le operazioni del backend, comuni a REST, WebSocket e strumenti: le letture sulle connessioni
//! di sola lettura, le scritture inviate al worker.

use std::sync::Arc;

use chrono::Local;
use serde::Serialize;
use tokio::sync::{broadcast, mpsc, oneshot, watch};

use crate::bozza::{self, Bozza, Calcolo};
use crate::config::Predefiniti;
use crate::consultazione::{self, Conflitto, Coda};
use crate::errore::ErroreApi;
use crate::home;
use crate::lettori::Lettori;
use crate::partita_iva;
use crate::prezzi::{self, Prezzi, RichiestaPrezzi};
use crate::worker::{Comando, DdtCreato, Notifica, NumeriLiberi, OperazioneNota, Rinumerato, StatoSync};

/// Stato condiviso dalle richieste.
#[derive(Debug, Clone)]
pub struct Servizio {
    pub(crate) lettori: Arc<Lettori>,
    pub(crate) comandi: mpsc::Sender<Comando>,
    pub(crate) stato: watch::Receiver<StatoSync>,
    pub(crate) notifiche: broadcast::Sender<Notifica>,
    pub(crate) predefiniti: Arc<Predefiniti>,
    pub(crate) vies: partita_iva::Vies,
}

/// Stato complessivo della sincronizzazione con Arca, per il pannello e il badge.
#[derive(Debug, Clone, Serialize)]
pub struct Stato {
    pub versione: &'static str,
    pub schema: i64,
    pub sincronizzazione: StatoSync,
    pub coda: Coda,
    /// DDT fermi su un conflitto di numero, con l'azione `rinumera`.
    pub conflitti: Vec<Conflitto>,
}

impl Servizio {
    pub fn nuovo(
        lettori: Arc<Lettori>,
        comandi: mpsc::Sender<Comando>,
        stato: watch::Receiver<StatoSync>,
        notifiche: broadcast::Sender<Notifica>,
        predefiniti: Predefiniti,
        vies: partita_iva::Vies,
    ) -> Self {
        Self {
            lettori,
            comandi,
            stato,
            notifiche,
            predefiniti: Arc::new(predefiniti),
            vies,
        }
    }

    pub fn notifiche(&self) -> broadcast::Receiver<Notifica> {
        self.notifiche.subscribe()
    }

    async fn al_worker<T>(&self, comando: impl FnOnce(oneshot::Sender<T>) -> Comando) -> Result<T, ErroreApi> {
        let (risposta, esito) = oneshot::channel();
        self.comandi
            .send(comando(risposta))
            .await
            .map_err(|_| ErroreApi::NonDisponibile("worker fermo".into()))?;
        esito.await.map_err(|_| ErroreApi::NonDisponibile("worker fermo".into()))
    }

    pub async fn calcola(&self, bozza: Bozza) -> Result<Calcolo, ErroreApi> {
        let predefiniti = Arc::clone(&self.predefiniti);
        let adesso = Local::now().naive_local();
        self.lettori.leggi(move |conn| bozza::calcola(conn, &bozza, &predefiniti, adesso)).await
    }

    pub async fn crea_ddt(&self, bozza: Bozza) -> Result<DdtCreato, ErroreApi> {
        self.al_worker(|risposta| Comando::Crea { bozza, risposta }).await?
    }

    pub async fn rinumera(&self, id: i64) -> Result<Rinumerato, ErroreApi> {
        self.al_worker(|risposta| Comando::Rinumera { id, risposta }).await?
    }

    pub async fn liberi(&self, esercizio: i32) -> Result<NumeriLiberi, ErroreApi> {
        self.al_worker(|risposta| Comando::Liberi { esercizio, risposta }).await?
    }

    pub async fn sincronizza(&self) -> Result<(), ErroreApi> {
        self.al_worker(|risposta| Comando::Sincronizza { risposta }).await
    }

    pub async fn note(&self) -> Result<Vec<atlas_db::note::Nota>, ErroreApi> {
        self.lettori.leggi(|conn| Ok(atlas_db::note::elenco(conn)?)).await
    }

    pub async fn nota(&self, operazione: OperazioneNota) -> Result<Option<atlas_db::note::Nota>, ErroreApi> {
        self.al_worker(|risposta| Comando::Nota { operazione, risposta }).await?
    }

    /// Dati ufficiali dell'azienda dalla partita IVA (VIES) e il codice ATLAS se c'è già.
    pub async fn partita_iva(&self, numero: String, richiesta: partita_iva::RichiestaPartitaIva) -> Result<partita_iva::DatiAzienda, ErroreApi> {
        let (nazione, numero) = partita_iva::normalizza(richiesta.nazione.as_deref().unwrap_or("IT"), &numero)?;
        let mut dati = self.vies.cerca(&nazione, &numero).await?;
        let cercata = numero.clone();
        dati.gia_presente = self.lettori.leggi(move |conn| partita_iva::gia_presente(conn, &cercata)).await?;
        Ok(dati)
    }

    pub async fn riepilogo(&self) -> Result<home::Riepilogo, ErroreApi> {
        self.lettori.leggi(home::riepilogo).await
    }

    pub async fn clienti_del_giorno(&self, richiesta: home::RichiestaGiorno) -> Result<home::ClientiDelGiorno, ErroreApi> {
        let data = richiesta.data.unwrap_or_else(|| Local::now().date_naive());
        self.lettori.leggi(move |conn| home::clienti_del_giorno(conn, data)).await
    }

    pub async fn prezzi(&self, richiesta: RichiestaPrezzi) -> Result<Prezzi, ErroreApi> {
        let predefiniti = Arc::clone(&self.predefiniti);
        let oggi = Local::now().date_naive();
        self.lettori
            .leggi(move |conn| prezzi::prezzi(conn, &richiesta, oggi, &predefiniti.listino))
            .await
    }

    pub async fn cerca_clienti(&self, ricerca: consultazione::Ricerca) -> Result<Vec<consultazione::ClienteBreve>, ErroreApi> {
        self.lettori.leggi(move |conn| consultazione::cerca_clienti(conn, &ricerca)).await
    }

    pub async fn cliente(&self, codice: String) -> Result<consultazione::ClienteScheda, ErroreApi> {
        self.lettori.leggi(move |conn| consultazione::cliente(conn, &codice)).await
    }

    pub async fn cerca_articoli(&self, ricerca: consultazione::Ricerca) -> Result<Vec<consultazione::ArticoloBreve>, ErroreApi> {
        self.lettori.leggi(move |conn| consultazione::cerca_articoli(conn, &ricerca)).await
    }

    pub async fn articolo(&self, codice: String) -> Result<consultazione::ArticoloScheda, ErroreApi> {
        self.lettori.leggi(move |conn| consultazione::articolo(conn, &codice)).await
    }

    pub async fn tabelle(&self) -> Result<consultazione::Tabelle, ErroreApi> {
        self.lettori.leggi(consultazione::tabelle).await
    }

    pub async fn elenco_ddt(&self, filtro: consultazione::FiltroDdt) -> Result<Vec<consultazione::DdtBreve>, ErroreApi> {
        self.lettori.leggi(move |conn| consultazione::elenco_ddt(conn, &filtro)).await
    }

    pub async fn ddt(&self, id: i64) -> Result<consultazione::DdtScheda, ErroreApi> {
        self.lettori.leggi(move |conn| consultazione::ddt(conn, id)).await
    }

    pub fn stato_sync(&self) -> StatoSync {
        self.stato.borrow().clone()
    }

    pub async fn stato(&self) -> Result<Stato, ErroreApi> {
        let sincronizzazione = self.stato_sync();
        let fermo_importazione = sincronizzazione.importazione.fermo.clone();
        let (coda, conflitti) = self
            .lettori
            .leggi(move |conn| {
                let coda = consultazione::coda(conn)?;
                let mut conflitti = Vec::new();
                if let Some(fermo) = &coda.fermo {
                    conflitti.push(Conflitto {
                        origine: "replica",
                        ddt: fermo.ddt,
                        esercizio: fermo.esercizio.unwrap_or_default(),
                        numero: fermo.numero.unwrap_or_default(),
                        errore: fermo.ultimo_errore.clone(),
                        azioni: consultazione::azioni(conn, fermo.ddt)?,
                    });
                }
                if let Some(fermo) = fermo_importazione {
                    if let (Some(esercizio), Some(numero)) = (fermo.esercizio, fermo.numero) {
                        if let Some(ddt) = consultazione::conteso(conn, esercizio, numero)? {
                            if !conflitti.iter().any(|c| c.ddt == ddt) {
                                conflitti.push(Conflitto {
                                    origine: "importazione",
                                    ddt,
                                    esercizio,
                                    numero,
                                    errore: format!("{} (Id_DoTes {} in Arca)", fermo.errore, fermo.arca_id_testata),
                                    azioni: consultazione::azioni(conn, ddt)?,
                                });
                            }
                        }
                    }
                }
                Ok((coda, conflitti))
            })
            .await?;
        Ok(Stato {
            versione: env!("CARGO_PKG_VERSION"),
            schema: atlas_db::connessione::versione_schema(),
            sincronizzazione,
            coda,
            conflitti,
        })
    }
}
