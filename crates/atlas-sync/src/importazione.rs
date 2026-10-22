//! Importazione continua dei BO di Arca nel database ATLAS: il verso opposto della replica.
//!
//! Ogni [`giro`] riprende dal punto raggiunto (`DOTes.Ts` dell'ultimo documento importato):
//! - legge i BO scritti in Arca dopo quel punto ([`lettura::modificati`]) e li registra con
//!   [`ddt::importa`], senza evento di replica. I documenti nati in ATLAS e replicati tornano
//!   indietro uguali e non cambiano nulla; un documento modificato in Arca viene aggiornato;
//!   quelli che ATLAS non sa ancora rappresentare finiscono tra gli esclusi, con il motivo;
//! - toglie i BO cancellati in Arca (che cancella davvero, senza lasciare traccia): li trova
//!   confrontando i documenti che ATLAS conosce con quelli presenti in Arca.
//!
//! I documenti si leggono da Arca prima di aprire la transazione SQLite, che resta breve: il
//! backend non aspetta mai la rete per salvare. Punto raggiunto e documenti importati sono
//! scritti nella stessa transazione: dopo un'interruzione il giro riparte esattamente da lì.

use std::collections::BTreeSet;

use atlas_arca::ErroreArca;
use atlas_arca::lettura::{self, Modificato, Testata};
use atlas_arca::scrittura::{self, Connessione};
use atlas_core::ddt::Ddt;
use atlas_core::numerazione::{Numeri, Sezionale, TipoDocumento};
use atlas_db::anagrafiche::{self, Anagrafiche};
use atlas_db::ddt::{self, Importato, TIPO_DOCUMENTO};
use atlas_db::importazione::{self, Escluso, Punto};
use atlas_db::{Connection, ErroreDb, TransactionBehavior};
use chrono::NaiveDateTime;

use crate::ErroreSync;
use crate::anagrafiche::leggi_anagrafiche;

/// Oltre questo numero di BO spariti da Arca in un giro l'importazione si ferma invece di
/// cancellarli: Arca non cancella mai tanti DDT insieme, e se succede (database sbagliato,
/// restore, archiviazione) va guardato prima.
pub const CANCELLAZIONI_MASSIME: usize = 100;

/// Da dove vengono i documenti: [`Arca`], o un sostituto nelle prove.
// Il worker gira su un thread suo con il proprio runtime: al futuro non serve `Send`.
#[allow(async_fn_in_trait)]
pub trait Origine {
    /// Nome del database di Arca: gli `Id_DoTes` valgono solo lì.
    async fn database(&mut self) -> Result<String, ErroreSync>;
    async fn modificati(&mut self, dopo: i64, limite: usize) -> Result<Vec<Modificato>, ErroreSync>;
    /// Numero dei BO e somma dei loro `Id_DoTes`.
    async fn impronta(&mut self) -> Result<(i64, i64), ErroreSync>;
    async fn identita(&mut self) -> Result<BTreeSet<i32>, ErroreSync>;
    async fn carica(&mut self, id_testata: i32) -> Result<Ddt, ErroreArca>;
    async fn anagrafiche(&mut self) -> Result<Anagrafiche, ErroreSync>;
    /// Numeri occupati nel sezionale e nell'esercizio.
    async fn numeri(&mut self, sezionale: Sezionale, esercizio: i32) -> Result<Numeri, ErroreSync>;
    /// Il documento che in Arca ha questo numero.
    async fn con_numero(&mut self, sezionale: Sezionale, esercizio: i32, numero: u32) -> Result<Option<Testata>, ErroreSync>;
    /// Chiude la connessione: dopo un errore o una richiesta abbandonata lo stato è incerto.
    fn scollega(&mut self);
}

/// Esito di un giro.
#[derive(Debug, Default, Clone, PartialEq, Eq)]
pub struct Giro {
    /// BO letti da Arca dopo il punto: se sono il limite del giro, ce ne sono altri.
    pub letti: usize,
    pub nuovi: usize,
    pub aggiornati: usize,
    pub invariati: usize,
    pub collegati: usize,
    pub esclusi: usize,
    pub cancellati: usize,
    /// Documento il cui numero è già di un altro DDT ATLAS: il giro si ferma lì (i precedenti
    /// sono importati) e ci riprova al giro dopo, finché il conflitto non viene risolto.
    pub fermo: Option<(i32, String)>,
    /// Esercizio e numero contesi quando il giro è fermo: il DDT ATLAS che lo occupa è quello da
    /// rinumerare, se non è ancora in Arca.
    pub conteso: Option<(i32, u32)>,
}

impl Giro {
    /// Documenti del database ATLAS cambiati dal giro.
    pub fn cambiati(&self) -> usize {
        self.nuovi + self.aggiornati + self.collegati + self.esclusi + self.cancellati
    }
}

enum Esito {
    Importato(Importato),
    Escluso(String),
}

/// Importa fino a `limite` BO scritti in Arca dopo il punto raggiunto e toglie quelli
/// cancellati. `adesso` dà l'istante registrato.
pub async fn giro(
    db: &mut Connection,
    origine: &mut impl Origine,
    adesso: impl Fn() -> NaiveDateTime,
    limite: usize,
) -> Result<Giro, ErroreSync> {
    let database = origine.database().await?;
    let dopo = match importazione::punto(db, TIPO_DOCUMENTO)? {
        Some(punto) if punto.database != database => {
            return Err(ErroreSync::AltroDatabase {
                legato: punto.database,
                trovato: database,
            });
        }
        Some(punto) => punto.ultimo_ts,
        None => 0,
    };
    let mut modificati = origine.modificati(dopo, limite).await?;
    let mut giro = Giro {
        letti: modificati.len(),
        ..Giro::default()
    };
    // Dopo i modificati: un BO cancellato nel frattempo non va reimportato.
    let (cancellati, presenti) = cancella(db, origine).await?;
    giro.cancellati = cancellati;
    if let Some(presenti) = presenti {
        modificati.retain(|m| presenti.contains(&m.id_testata));
    }
    if modificati.is_empty() {
        return Ok(giro);
    }

    // Un documento può citare un codice creato in Arca dopo l'ultimo allineamento.
    anagrafiche::aggiorna(db, &origine.anagrafiche().await?)?;
    let mut letti = Vec::with_capacity(modificati.len());
    for m in modificati {
        let documento = match m.escluso {
            Some(motivo) => Err(motivo.to_owned()),
            None => match origine.carica(m.id_testata).await {
                Ok(documento) => Ok(documento),
                Err(e @ (ErroreArca::DocumentoNonValido(_) | ErroreArca::Calcolo(_))) => Err(e.to_string()),
                Err(e) => return Err(e.into()),
            },
        };
        letti.push((m, documento));
    }

    let mut tx = db.transaction_with_behavior(TransactionBehavior::Immediate).map_err(ErroreDb::from)?;
    let mut punto = Punto {
        database,
        ultimo_ts: dopo,
    };
    for (m, documento) in &letti {
        let esito = match documento {
            Err(motivo) => Esito::Escluso(motivo.clone()),
            Ok(documento) => {
                // Un documento rifiutato a metà scrittura non lascia nulla.
                let sp = tx.savepoint().map_err(ErroreDb::from)?;
                match ddt::importa(&sp, documento, m.id_testata) {
                    Ok(importato) => {
                        sp.commit().map_err(ErroreDb::from)?;
                        Esito::Importato(importato)
                    }
                    Err(
                        e @ (ErroreDb::DocumentoNonValido(_) | ErroreDb::Calcolo(_) | ErroreDb::RiferimentiInesistenti(_)),
                    ) => Esito::Escluso(e.to_string()),
                    Err(e @ ErroreDb::NumeroOccupato { esercizio, numero }) => {
                        giro.conteso = Some((esercizio, numero));
                        giro.fermo = Some((m.id_testata, e.to_string()));
                        break;
                    }
                    Err(e) => return Err(e.into()),
                }
            }
        };
        match esito {
            Esito::Importato(importato) => {
                importazione::riammetti(&tx, m.id_testata)?;
                match importato {
                    Importato::Nuovo(_) => giro.nuovi += 1,
                    Importato::Aggiornato(_) => giro.aggiornati += 1,
                    Importato::Invariato(_) => giro.invariati += 1,
                    Importato::Collegato(_) => giro.collegati += 1,
                }
            }
            Esito::Escluso(motivo) => {
                let escluso = Escluso {
                    arca_id_testata: m.id_testata,
                    tipo_documento: m.tipo_documento.clone(),
                    sezionale: TipoDocumento::BollaVendita.sezionale().codice().into(),
                    esercizio: m.esercizio,
                    numero: m.numero,
                    data: m.data,
                    motivo,
                };
                importazione::escludi(&tx, &escluso, adesso())?;
                giro.esclusi += 1;
            }
        }
        punto.ultimo_ts = m.ts;
    }
    importazione::avanza(&tx, TIPO_DOCUMENTO, &punto, adesso())?;
    tx.commit().map_err(ErroreDb::from)?;
    Ok(giro)
}

/// Toglie dal database ATLAS i BO spariti da Arca. Restituisce quanti e, se è servito
/// scaricarlo, l'elenco dei BO presenti in Arca.
async fn cancella(
    db: &mut Connection,
    origine: &mut impl Origine,
) -> Result<(usize, Option<BTreeSet<i32>>), ErroreSync> {
    let noti = importazione::noti(db)?;
    let impronta = (
        i64::try_from(noti.len()).unwrap_or(i64::MAX),
        noti.iter().map(|&id| i64::from(id)).sum::<i64>(),
    );
    if impronta == origine.impronta().await? {
        return Ok((0, None));
    }
    let presenti = origine.identita().await?;
    let spariti: Vec<i32> = noti.difference(&presenti).copied().collect();
    if spariti.len() > CANCELLAZIONI_MASSIME {
        return Err(ErroreSync::TroppeCancellazioni {
            trovate: spariti.len(),
            massimo: CANCELLAZIONI_MASSIME,
        });
    }
    if !spariti.is_empty() {
        let tx = db.transaction_with_behavior(TransactionBehavior::Immediate).map_err(ErroreDb::from)?;
        for &id in &spariti {
            importazione::dimentica(&tx, id)?;
        }
        tx.commit().map_err(ErroreDb::from)?;
    }
    Ok((spariti.len(), Some(presenti)))
}

/// Il database di Arca in sola lettura, raggiunto con una stringa di connessione ADO. La
/// connessione si apre alla prima richiesta; dopo un errore va chiusa con [`Arca::scollega`].
pub struct Arca {
    ado: String,
    conn: Option<Connessione>,
}

impl std::fmt::Debug for Arca {
    // Senza la stringa di connessione, che può contenere la password.
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Arca").field("connessa", &self.conn.is_some()).finish()
    }
}

impl Arca {
    pub fn nuova(ado: impl Into<String>) -> Self {
        Self {
            ado: ado.into(),
            conn: None,
        }
    }

    /// Chiude la connessione: dopo un errore di rete o di protocollo lo stato è incerto.
    pub fn scollega(&mut self) {
        self.conn = None;
    }

    async fn conn(&mut self) -> Result<&mut Connessione, ErroreArca> {
        let conn = match self.conn.take() {
            Some(conn) => conn,
            None => {
                let mut conn = scrittura::connetti(&self.ado).await?;
                lettura::controlla_numerazione(&mut conn).await?;
                conn
            }
        };
        Ok(self.conn.insert(conn))
    }
}

impl Origine for Arca {
    async fn database(&mut self) -> Result<String, ErroreSync> {
        Ok(scrittura::nome_database(self.conn().await?).await?)
    }

    async fn modificati(&mut self, dopo: i64, limite: usize) -> Result<Vec<Modificato>, ErroreSync> {
        Ok(lettura::modificati(self.conn().await?, dopo, limite).await?)
    }

    async fn impronta(&mut self) -> Result<(i64, i64), ErroreSync> {
        Ok(lettura::impronta(self.conn().await?).await?)
    }

    async fn identita(&mut self) -> Result<BTreeSet<i32>, ErroreSync> {
        Ok(lettura::identita(self.conn().await?).await?)
    }

    async fn carica(&mut self, id_testata: i32) -> Result<Ddt, ErroreArca> {
        lettura::carica(self.conn().await?, id_testata).await
    }

    async fn anagrafiche(&mut self) -> Result<Anagrafiche, ErroreSync> {
        leggi_anagrafiche(self.conn().await?).await
    }

    async fn numeri(&mut self, sezionale: Sezionale, esercizio: i32) -> Result<Numeri, ErroreSync> {
        Ok(lettura::numeri(self.conn().await?, sezionale, esercizio).await?)
    }

    async fn con_numero(&mut self, sezionale: Sezionale, esercizio: i32, numero: u32) -> Result<Option<Testata>, ErroreSync> {
        Ok(lettura::con_numero(self.conn().await?, sezionale, esercizio, numero).await?)
    }

    fn scollega(&mut self) {
        Arca::scollega(self);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::finta::Finta;
    use atlas_db::prova::{self, adesso};
    use rust_decimal::Decimal;

    fn db() -> Connection {
        prova::database()
    }

    async fn gira(db: &mut Connection, arca: &mut Finta, limite: usize) -> Giro {
        giro(db, arca, adesso, limite).await.unwrap()
    }

    fn conta(db: &Connection, sql: &str) -> i64 {
        db.query_row(sql, [], |r| r.get(0)).unwrap()
    }

    fn ultimo_ts(db: &Connection) -> i64 {
        importazione::punto(db, TIPO_DOCUMENTO).unwrap().unwrap().ultimo_ts
    }

    #[tokio::test(flavor = "current_thread")]
    async fn importa_dal_punto_raggiunto_e_poi_non_rifa_nulla() {
        let mut db = db();
        let mut arca = Finta::nuova();
        arca.scrivi(100, Ok(prova::ddt(1)));
        arca.scrivi(101, Err("righe senza articolo"));
        arca.scrivi(102, Ok(prova::ddt(2)));
        let primo = gira(&mut db, &mut arca, 10).await;
        assert_eq!((primo.letti, primo.nuovi, primo.esclusi, primo.fermo), (3, 2, 1, None));
        assert_eq!(ultimo_ts(&db), 1003);
        assert_eq!(importazione::esclusi(&db).unwrap()[0].motivo, "righe senza articolo");
        assert_eq!(conta(&db, "SELECT count(*) FROM outbox_eventi"), 0);
        assert_eq!(gira(&mut db, &mut arca, 10).await, Giro::default());
    }

    #[tokio::test(flavor = "current_thread")]
    async fn a_blocchi_fino_al_pari() {
        let mut db = db();
        let mut arca = Finta::nuova();
        for n in 1..=5 {
            arca.scrivi(100 + n, Ok(prova::ddt(n.unsigned_abs())));
        }
        let mut letti = Vec::new();
        loop {
            let giro = gira(&mut db, &mut arca, 2).await;
            letti.push(giro.letti);
            if giro.letti < 2 {
                break;
            }
        }
        assert_eq!(letti, [2, 2, 1]);
        assert_eq!(conta(&db, "SELECT count(*) FROM ddt"), 5);
    }

    #[tokio::test(flavor = "current_thread")]
    async fn modificato_in_arca_aggiornato_ed_escluso_poi_corretto_importato() {
        let mut db = db();
        let mut arca = Finta::nuova();
        arca.scrivi(100, Ok(prova::ddt(1)));
        arca.scrivi(101, Err("righe di spesa"));
        gira(&mut db, &mut arca, 10).await;

        let mut modificato = prova::ddt(1);
        modificato.righe[0].prezzo_unitario = Decimal::TWO;
        arca.scrivi(100, Ok(modificato.clone()));
        arca.scrivi(101, Ok(prova::ddt(2)));
        let giro = gira(&mut db, &mut arca, 10).await;
        assert_eq!((giro.aggiornati, giro.nuovi, giro.esclusi), (1, 1, 0));
        let id: i64 = db.query_row("SELECT id FROM ddt WHERE arca_id_testata = 100", [], |r| r.get(0)).unwrap();
        assert_eq!(ddt::carica(&db, id).unwrap(), modificato);
        assert!(importazione::esclusi(&db).unwrap().is_empty());
    }

    #[tokio::test(flavor = "current_thread")]
    async fn documento_atlas_replicato_torna_senza_cambiare_nulla() {
        let mut db = db();
        let mut arca = Finta::nuova();
        gira(&mut db, &mut arca, 10).await;
        // Uno replicato con l'esito registrato, uno scritto in Arca ma con l'esito perso.
        let registrato = ddt::salva(&mut db, &prova::ddt(1), adesso()).unwrap();
        atlas_db::outbox::segna_replicato(&db, registrato.evento, 200, adesso()).unwrap();
        ddt::salva(&mut db, &prova::ddt(2), adesso()).unwrap();
        arca.scrivi(200, Ok(prova::ddt(1)));
        arca.scrivi(201, Ok(prova::ddt(2)));
        let giro = gira(&mut db, &mut arca, 10).await;
        assert_eq!((giro.invariati, giro.collegati, giro.nuovi), (1, 1, 0));
        assert_eq!(conta(&db, "SELECT count(*) FROM ddt"), 2);
    }

    #[tokio::test(flavor = "current_thread")]
    async fn cancellati_in_arca_escono_anche_gli_esclusi() {
        let mut db = db();
        let mut arca = Finta::nuova();
        arca.scrivi(100, Ok(prova::ddt(1)));
        arca.scrivi(101, Ok(prova::ddt(2)));
        arca.scrivi(102, Err("documento non esecutivo"));
        gira(&mut db, &mut arca, 10).await;
        arca.documenti.remove(&101);
        arca.documenti.remove(&102);
        let giro = gira(&mut db, &mut arca, 10).await;
        assert_eq!((giro.cancellati, giro.letti), (2, 0));
        assert_eq!(importazione::noti(&db).unwrap(), BTreeSet::from([100]));
        assert_eq!(conta(&db, "SELECT count(*) FROM ddt_righe"), 2);
    }

    #[tokio::test(flavor = "current_thread")]
    async fn cancellato_subito_dopo_la_lettura_non_viene_reimportato() {
        let mut db = db();
        let mut arca = Finta::nuova();
        arca.scrivi(100, Ok(prova::ddt(1)));
        gira(&mut db, &mut arca, 10).await;
        let mut modificato = prova::ddt(1);
        modificato.righe.truncate(1);
        arca.scrivi(100, Ok(modificato));
        arca.cancella_dopo_modificati = Some(100);
        let giro = gira(&mut db, &mut arca, 10).await;
        assert_eq!((giro.letti, giro.cancellati, giro.cambiati()), (1, 1, 1));
        assert_eq!(conta(&db, "SELECT count(*) FROM ddt"), 0);
    }

    #[tokio::test(flavor = "current_thread")]
    async fn numero_conteso_ferma_il_giro_fino_alla_soluzione() {
        let mut db = db();
        let mut arca = Finta::nuova();
        gira(&mut db, &mut arca, 10).await;
        // DDT 2 salvato in ATLAS e non ancora replicato; in Arca un altro BO 2.
        let atlas = ddt::salva(&mut db, &prova::ddt(2), adesso()).unwrap();
        let mut conteso = prova::ddt(2);
        conteso.cliente = "C000002".into();
        conteso.destinazione = None;
        arca.scrivi(100, Ok(prova::ddt(1)));
        arca.scrivi(101, Ok(conteso));
        arca.scrivi(102, Ok(prova::ddt(3)));
        for _ in 0..2 {
            let giro = gira(&mut db, &mut arca, 10).await;
            let (id, errore) = giro.fermo.unwrap();
            assert_eq!((id, errore.as_str()), (101, "DDT 2/2026 già presente"));
            assert_eq!(giro.conteso, Some((2026, 2)));
            assert_eq!(ultimo_ts(&db), 1001, "il punto resta prima del conteso");
        }
        assert_eq!(conta(&db, "SELECT count(*) FROM ddt"), 2);

        // Risolto (qui: il DDT ATLAS rinumerato), il giro riparte dal conteso.
        db.execute("UPDATE ddt SET numero = 4 WHERE id = ?1", [atlas.id]).unwrap();
        let giro = gira(&mut db, &mut arca, 10).await;
        assert_eq!((giro.nuovi, giro.fermo), (2, None));
    }

    #[tokio::test(flavor = "current_thread")]
    async fn database_diverso_da_quello_legato_rifiutato() {
        let mut db = db();
        let mut arca = Finta::nuova();
        arca.scrivi(100, Ok(prova::ddt(1)));
        gira(&mut db, &mut arca, 10).await;
        arca.database = "ADB_BOTTAMEDI".into();
        let errore = giro(&mut db, &mut arca, adesso, 10).await.unwrap_err();
        assert!(matches!(errore, ErroreSync::AltroDatabase { .. }), "{errore}");
    }

    #[tokio::test(flavor = "current_thread")]
    async fn troppe_cancellazioni_insieme_non_cancellano_nulla() {
        let mut db = db();
        let mut arca = Finta::nuova();
        let n = i32::try_from(CANCELLAZIONI_MASSIME).unwrap() + 1;
        for id in 1..=n {
            arca.scrivi(id, Ok(prova::ddt(id.unsigned_abs())));
        }
        gira(&mut db, &mut arca, 1000).await;
        arca.documenti.clear();
        let errore = giro(&mut db, &mut arca, adesso, 10).await.unwrap_err();
        assert!(matches!(errore, ErroreSync::TroppeCancellazioni { trovate: 101, .. }), "{errore}");
        assert_eq!(conta(&db, "SELECT count(*) FROM ddt"), i64::from(n));
    }
}
