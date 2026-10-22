//! Replica dei documenti in Arca: il worker che consuma l'outbox.
//!
//! Ogni [`giro`] prende gli eventi in coda in ordine di `id` e li scrive in Arca, una
//! transazione SQL Server per documento. L'operatore non aspetta mai Arca: il documento è già
//! salvato in ATLAS quando l'evento entra in coda, e se SQL Server è lento o spento gli eventi
//! restano in coda, con l'errore e l'istante della riprova, fino al giro buono.
//!
//! Idempotenza: tra il commit in Arca e [`outbox::segna_replicato`] il programma può fermarsi
//! (o la risposta al commit può perdersi in rete). Prima di scrivere, [`Arca`] cerca il
//! documento con la stessa chiave di numerazione (`UK_DOTes`: sezionale, esercizio, numero); se
//! c'è e, riletto, coincide con quello dell'evento lo segna replicato con la sua identità invece
//! di riscriverlo. Se c'è ma è un altro documento (numero preso in Arca nel frattempo) l'evento
//! fallisce e la coda si ferma finché il conflitto non viene risolto.

use std::time::Duration;

use atlas_arca::ErroreArca;
use atlas_arca::config::ConfigArca;
use atlas_arca::ddt::InTabelle;
use atlas_arca::lettura;
use atlas_arca::record::{Record, Valore};
use atlas_arca::scrittura::{self, Connessione};
use atlas_db::Connection;
use atlas_db::ddt::TIPO_DOCUMENTO;
use atlas_db::outbox::{self, Evento, Operazione};
use chrono::NaiveDateTime;
use tiberius::Query;

use crate::ErroreSync;
use crate::clienti::NuovoCliente;

/// Tipo dell'evento di un cliente nuovo nell'outbox.
pub const TIPO_CLIENTE: &str = "CF";

/// Prima attesa dopo un tentativo fallito; raddoppia a ogni tentativo fino a [`ATTESA_MASSIMA`].
const ATTESA_INIZIALE: Duration = Duration::from_secs(5);
const ATTESA_MASSIMA: Duration = Duration::from_secs(300);

/// Attesa prima del tentativo successivo al `tentativi`-esimo fallito: 5 s, 10 s, 20 s … 5 min.
pub fn attesa(tentativi: i64) -> Duration {
    let raddoppi = u32::try_from(tentativi.saturating_sub(1).clamp(0, 16)).unwrap_or(16);
    ATTESA_INIZIALE.saturating_mul(1 << raddoppi).min(ATTESA_MASSIMA)
}

/// Come è finito in Arca il documento (o il cliente) di un evento.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Replicato {
    Scritto(i32),
    /// Già scritto da un tentativo precedente di cui non era stato registrato l'esito.
    GiaPresente(i32),
}

impl Replicato {
    /// `DOTes.Id_DoTes` del documento in Arca.
    pub fn id_testata(self) -> i32 {
        match self {
            Self::Scritto(id) | Self::GiaPresente(id) => id,
        }
    }
}

/// Dove vanno scritti i documenti: [`Arca`], o un sostituto nelle prove.
// Il worker gira su un thread suo con il proprio runtime: al futuro non serve `Send`.
#[allow(async_fn_in_trait)]
pub trait Destinazione {
    async fn replica(&mut self, evento: &Evento) -> Result<Replicato, ErroreSync>;
}

/// Esito di un giro sulla coda.
#[derive(Debug, Default, Clone, PartialEq, Eq)]
pub struct Giro {
    pub scritti: usize,
    pub gia_presenti: usize,
    /// Evento fallito, con l'errore: ferma il giro e, fino alla riprova, la coda.
    pub fallito: Option<(i64, String)>,
}

impl Giro {
    pub fn replicati(&self) -> usize {
        self.scritti + self.gia_presenti
    }
}

/// Replica fino a `limite` eventi in coda, in ordine, fermandosi al primo che fallisce.
/// `adesso` dà l'istante registrato a ogni passo. Un errore del database ATLAS interrompe il
/// giro: l'evento resta in coda e alla riprova risulterà già presente in Arca.
pub async fn giro(
    db: &Connection,
    destinazione: &mut impl Destinazione,
    adesso: impl Fn() -> NaiveDateTime,
    limite: usize,
) -> Result<Giro, ErroreSync> {
    let mut giro = Giro::default();
    for evento in outbox::da_replicare(db, adesso(), limite)? {
        match destinazione.replica(&evento).await {
            Ok(replicato) => {
                outbox::segna_replicato(db, evento.id, replicato.id_testata(), adesso())?;
                match replicato {
                    Replicato::Scritto(_) => giro.scritti += 1,
                    Replicato::GiaPresente(_) => giro.gia_presenti += 1,
                }
            }
            Err(e) => {
                let errore = e.to_string();
                let riprova = adesso() + attesa(evento.tentativi + 1);
                outbox::segna_fallito(db, evento.id, &errore, riprova)?;
                giro.fallito = Some((evento.id, errore));
                break;
            }
        }
    }
    Ok(giro)
}

struct Sessione {
    conn: Connessione,
    cfg: ConfigArca,
}

/// Il database di Arca, raggiunto con una stringa di connessione ADO. La connessione si apre al
/// primo evento e si riapre dopo un errore che la lascia in uno stato incerto.
pub struct Arca {
    ado: String,
    sessione: Option<Sessione>,
    /// Database di Arca a cui è legato il file ATLAS (quello da cui importa): la replica rifiuta
    /// gli altri, dove gli stessi `Id_DoTes` indicherebbero documenti diversi.
    legata: Option<String>,
}

impl std::fmt::Debug for Arca {
    // Senza la stringa di connessione, che può contenere la password.
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Arca")
            .field("connessa", &self.sessione.is_some())
            .field("legata", &self.legata)
            .finish()
    }
}

impl Arca {
    pub fn nuova(ado: impl Into<String>) -> Self {
        Self {
            ado: ado.into(),
            sessione: None,
            legata: None,
        }
    }

    /// Lega la replica al database di Arca da cui il file ATLAS importa (vedi
    /// [`atlas_db::importazione::punto`]). Una connessione già aperta su un altro database si
    /// chiude: il controllo si ripete alla riapertura.
    pub fn lega(&mut self, database: impl Into<String>) {
        let database = database.into();
        if self.legata.as_ref() != Some(&database) {
            self.sessione = None;
            self.legata = Some(database);
        }
    }

    /// Chiude la connessione: dopo una richiesta abbandonata (giro interrotto) lo stato è
    /// incerto. Una transazione aperta in Arca viene annullata dal server alla chiusura.
    pub fn scollega(&mut self) {
        self.sessione = None;
    }

    async fn sessione(&mut self) -> Result<&mut Sessione, ErroreSync> {
        let sessione = match self.sessione.take() {
            Some(sessione) => sessione,
            None => {
                let mut conn = scrittura::connetti(&self.ado).await?;
                // Finché il titolare non decide sulla produzione (login con ALTER, trigger del
                // fornitore spenti in transazione: vedi TASKS.md) si replica solo sul clone.
                let database = scrittura::nome_database(&mut conn).await?;
                if !database.to_ascii_uppercase().ends_with("_DEV") {
                    return Err(ErroreSync::NonClone(database));
                }
                if let Some(legata) = self.legata.as_ref().filter(|l| !l.eq_ignore_ascii_case(&database)) {
                    return Err(ErroreSync::AltroDatabase {
                        legato: legata.clone(),
                        trovato: database,
                    });
                }
                // Il numero dei documenti lo ha deciso ATLAS con la regola di Arca.
                lettura::controlla_numerazione(&mut conn).await?;
                let cfg = ConfigArca::carica(&mut conn, TIPO_DOCUMENTO).await?;
                Sessione { conn, cfg }
            }
        };
        Ok(self.sessione.insert(sessione))
    }

    async fn scrivi(&mut self, evento: &Evento) -> Result<Replicato, ErroreSync> {
        if evento.documento_tipo == TIPO_CLIENTE && evento.operazione == Operazione::Crea {
            return self.scrivi_cliente(evento).await;
        }
        if evento.documento_tipo != TIPO_DOCUMENTO || evento.operazione != Operazione::Crea {
            return Err(ErroreSync::NonGestito(format!(
                "{} {} di Arca",
                evento.operazione.come_testo(),
                evento.documento_tipo
            )));
        }
        let ddt = evento.ddt()?;
        let s = self.sessione().await?;
        let tabelle = ddt.in_tabelle(&s.cfg)?;
        if let Some(id) = con_lo_stesso_numero(&mut s.conn, &tabelle.testata).await? {
            return match lettura::carica(&mut s.conn, id).await {
                Ok(presente) if presente == ddt => Ok(Replicato::GiaPresente(id)),
                Ok(_) | Err(ErroreArca::DocumentoNonValido(_)) => Err(ErroreSync::NumeroOccupato {
                    esercizio: ddt.data.format("%Y").to_string(),
                    numero: ddt.numero,
                    id_testata: id,
                }),
                Err(e) => Err(e.into()),
            };
        }
        let scritto = scrittura::scrivi(&mut s.conn, &tabelle).await?;
        scrittura::conferma(&mut s.conn).await?;
        Ok(Replicato::Scritto(scritto.id_testata))
    }
}

impl Arca {
    /// Il cliente nuovo in `CF` e `CFContatto`. Se il codice c'è già con la stessa ragione sociale
    /// è lo stesso cliente scritto da un tentativo precedente; con un'altra, il codice è stato preso
    /// in Arca nel frattempo e la coda si ferma.
    async fn scrivi_cliente(&mut self, evento: &Evento) -> Result<Replicato, ErroreSync> {
        let cliente: NuovoCliente = serde_json::from_str(&evento.payload).map_err(atlas_db::ErroreDb::from)?;
        let (cf, contatto) = cliente.righe_arca()?;
        let s = self.sessione().await?;
        let mut query = Query::new("select Id_CF, Descrizione from CF where Cd_CF = @P1");
        query.bind(cliente.codice().to_owned());
        if let Some(row) = query.query(&mut s.conn).await?.into_row().await? {
            let id = row.try_get::<i32, _>("Id_CF")?.unwrap_or_default();
            let descrizione = row.try_get::<&str, _>("Descrizione")?.unwrap_or_default().trim_end();
            let nostra = cliente.cf.get("Descrizione").and_then(serde_json::Value::as_str).unwrap_or_default().trim_end();
            return if descrizione == nostra {
                Ok(Replicato::GiaPresente(id))
            } else {
                Err(ErroreSync::CodiceOccupato {
                    codice: cliente.codice().to_owned(),
                    id,
                })
            };
        }
        let id = scrittura::scrivi_cliente(&mut s.conn, &cf, contatto.as_ref()).await?;
        scrittura::conferma(&mut s.conn).await?;
        Ok(Replicato::Scritto(id))
    }
}

impl Destinazione for Arca {
    async fn replica(&mut self, evento: &Evento) -> Result<Replicato, ErroreSync> {
        let esito = self.scrivi(evento).await;
        if esito.is_err() {
            if let Some(s) = self.sessione.as_mut() {
                if scrittura::annulla(&mut s.conn).await.is_err() {
                    self.sessione = None;
                }
            }
        }
        esito
    }
}

fn testo(record: &Record, colonna: &'static str) -> Result<String, ErroreSync> {
    match record.valore(colonna) {
        Some(Valore::Testo(Some(t))) => Ok(t.clone()),
        _ => Err(ErroreSync::Dato {
            tabella: record.tabella,
            colonna,
            problema: "assente nella testata da scrivere".into(),
        }),
    }
}

/// Documento di Arca con la chiave di numerazione della testata (`UK_DOTes`).
async fn con_lo_stesso_numero(conn: &mut Connessione, testata: &Record) -> Result<Option<i32>, ErroreSync> {
    let mut query = Query::new("select Id_DoTes from DOTes where Cd_CN = @P1 and EsAnno = @P2 and NumeroDoc = @P3");
    for colonna in ["Cd_CN", "EsAnno", "NumeroDoc"] {
        query.bind(testo(testata, colonna)?);
    }
    let row = query.query(conn).await?.into_row().await?;
    Ok(row.and_then(|r| r.try_get::<i32, _>("Id_DoTes").ok().flatten()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use atlas_db::outbox::accoda;
    use chrono::NaiveDate;
    use std::cell::Cell;
    use std::collections::HashMap;

    fn alle(secondi: i64) -> NaiveDateTime {
        NaiveDate::from_ymd_opt(2026, 10, 22).unwrap().and_hms_opt(9, 0, 0).unwrap() + chrono::Duration::seconds(secondi)
    }

    /// Arca finta: documento → esito; i documenti senza esito falliscono.
    #[derive(Default)]
    struct Finta {
        esiti: HashMap<i64, Replicato>,
        chiamate: Vec<i64>,
    }

    impl Destinazione for Finta {
        async fn replica(&mut self, evento: &Evento) -> Result<Replicato, ErroreSync> {
            self.chiamate.push(evento.documento_id);
            self.esiti
                .get(&evento.documento_id)
                .copied()
                .ok_or_else(|| ErroreSync::NonGestito("SQL Server non raggiungibile".into()))
        }
    }

    fn coda(documenti: i64) -> Connection {
        let db = atlas_db::apri_in_memoria().unwrap();
        for documento in 1..=documenti {
            accoda(&db, "BO", documento, Operazione::Crea, "{}", alle(0)).unwrap();
        }
        db
    }

    fn arca_id(db: &Connection, documento: i64) -> Option<i32> {
        db.query_row("SELECT arca_id_testata FROM outbox_eventi WHERE documento_id = ?1", [documento], |r| r.get(0))
            .unwrap()
    }

    #[tokio::test(flavor = "current_thread")]
    async fn replica_in_ordine_e_registra_l_identita_di_arca() {
        let db = coda(3);
        let mut arca = Finta::default();
        arca.esiti.extend([(1, Replicato::Scritto(500)), (2, Replicato::GiaPresente(400)), (3, Replicato::Scritto(501))]);
        let giro = giro(&db, &mut arca, || alle(1), 10).await.unwrap();
        assert_eq!((giro.scritti, giro.gia_presenti, giro.fallito), (2, 1, None));
        assert_eq!(arca.chiamate, [1, 2, 3]);
        assert_eq!([arca_id(&db, 1), arca_id(&db, 2), arca_id(&db, 3)], [Some(500), Some(400), Some(501)]);
        assert_eq!(outbox::in_attesa(&db).unwrap(), 0);
    }

    #[tokio::test(flavor = "current_thread")]
    async fn evento_fallito_ferma_la_coda_fino_alla_riprova() {
        let db = coda(3);
        let mut arca = Finta::default();
        arca.esiti.insert(1, Replicato::Scritto(500));
        let primo = giro(&db, &mut arca, || alle(1), 10).await.unwrap();
        assert_eq!(primo.scritti, 1);
        let (id, errore) = primo.fallito.unwrap();
        assert_eq!(errore, "replica non gestita: SQL Server non raggiungibile");
        assert_eq!(arca.chiamate, [1, 2], "il 3 non viene tentato prima del 2");

        // Prima della riprova (5 s dopo il primo fallimento) il worker non tocca Arca.
        assert_eq!(giro(&db, &mut arca, || alle(5), 10).await.unwrap(), Giro::default());
        assert_eq!(arca.chiamate.len(), 2);

        // Arca torna: il 2 e il 3 passano nell'ordine.
        arca.esiti.extend([(2, Replicato::Scritto(501)), (3, Replicato::Scritto(502))]);
        let secondo = giro(&db, &mut arca, || alle(6), 10).await.unwrap();
        assert_eq!((secondo.scritti, secondo.fallito), (2, None));
        let evento = outbox::evento(&db, id).unwrap();
        assert_eq!((evento.tentativi, evento.ultimo_errore.as_deref()), (2, Some(errore.as_str())));
    }

    #[tokio::test(flavor = "current_thread")]
    async fn le_riprove_si_diradano() {
        let db = coda(1);
        let mut arca = Finta::default();
        let ora = Cell::new(0);
        let mut riprese = Vec::new();
        for _ in 0..8 {
            giro(&db, &mut arca, || alle(ora.get()), 10).await.unwrap();
            let prossimo: NaiveDateTime =
                db.query_row("SELECT prossimo_tentativo_il FROM outbox_eventi", [], |r| r.get(0)).unwrap();
            riprese.push((prossimo - alle(ora.get())).num_seconds());
            ora.set((prossimo - alle(0)).num_seconds());
        }
        assert_eq!(riprese, [5, 10, 20, 40, 80, 160, 300, 300]);
        assert_eq!(arca.chiamate.len(), 8);
    }

    #[test]
    fn attesa_limitata_anche_con_contatori_assurdi() {
        assert_eq!(attesa(0), ATTESA_INIZIALE);
        assert_eq!(attesa(i64::MAX), ATTESA_MASSIMA);
    }
}
