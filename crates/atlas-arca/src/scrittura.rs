//! Scrittura transazionale di un documento nelle tabelle di Arca.
//!
//! I trigger di `DOTes` e `DORig` (cifrati) non ammettono la scrittura diretta: quello di
//! `DORig` chiama `asp_MGMovDocIns`, che fuori dalla sessione di Arca risponde 50000
//! "Funzionalità non disponibile al di fuori del prodotto"; quello di `DOTes` riscrive
//! `UserIns`/`TimeIns` con l'utente SQL e ne rifiuta la modifica (errore 900000). Vengono
//! disattivati dentro la transazione stessa: `ALTER TABLE … DISABLE TRIGGER` è transazionale,
//! tiene un blocco di schema fino al commit (le altre sessioni attendono e non li vedono mai
//! spenti) e un errore o un rollback li lascia attivi. `MGMov_atrg` accetta l'inserimento e
//! resta attivo.

use tiberius::{Client, Config};
use tokio::net::TcpStream;
use tokio_util::compat::{Compat, TokioAsyncWriteCompatExt};

use crate::ErroreArca;
use crate::ddt::TabelleArca;
use crate::record::{Record, Valore};

pub type Connessione = Client<Compat<TcpStream>>;

/// Trigger presenti sulle tabelle scritte e trigger da disattivare. Un aggiornamento di Arca che
/// ne aggiunga o ne rinomini uno ferma la replica invece di scrivere con regole non verificate.
const TRIGGER: [(&str, &[&str], bool); 5] = [
    ("DOTes", &["DOTes_atrg_brd"], true),
    ("DORig", &["DORig_atrg_brd"], true),
    ("MGMov", &["MGMov_atrg"], false),
    ("DOTotali", &[], false),
    ("DOIva", &[], false),
];

/// Opzioni di sessione richieste dagli indici sulle colonne calcolate; `XACT_ABORT` annulla la
/// transazione al primo errore.
const OPZIONI_SESSIONE: &str = "SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; \
    SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF; \
    SET XACT_ABORT ON; SET DATEFORMAT ymd";

pub async fn connetti(ado: &str) -> Result<Connessione, ErroreArca> {
    let config = Config::from_ado_string(ado)?;
    let tcp = TcpStream::connect(config.get_addr()).await?;
    tcp.set_nodelay(true)?;
    let mut conn = Client::connect(config, tcp.compat_write()).await?;
    conn.simple_query(OPZIONI_SESSIONE).await?.into_results().await?;
    Ok(conn)
}

pub async fn nome_database(conn: &mut Connessione) -> Result<String, ErroreArca> {
    let row = conn.simple_query("select db_name() as Db").await?.into_row().await?;
    Ok(row
        .and_then(|r| r.try_get::<&str, _>("Db").ok().flatten().map(str::to_owned))
        .unwrap_or_default())
}

/// Identità assegnate da SQL Server al documento scritto.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DocumentoScritto {
    pub id_testata: i32,
    pub id_righe: Vec<i32>,
    pub id_movimenti: Vec<Option<i32>>,
    pub id_totali: i32,
    pub id_iva: Vec<i32>,
}

/// Trigger di `CF` e `CFContatto`: su cancellazione e modifica, nessuno sull'inserimento (letti
/// sul clone il 22/10/2026). Restano attivi.
const TRIGGER_CLIENTI: [(&str, &[&str]); 2] = [("CF", &["CF_atrg_brd", "CF_atrg_iod"]), ("CFContatto", &["CFContatto_atrg_brd"])];

async fn controlla_trigger(conn: &mut Connessione, elenco: &[(&'static str, &'static [&'static str])]) -> Result<(), ErroreArca> {
    for &(tabella, attesi) in elenco {
        let sql = format!("select name from sys.triggers where parent_id = object_id('{tabella}') order by name");
        let mut trovati: Vec<String> = Vec::new();
        for row in conn.simple_query(sql).await?.into_first_result().await? {
            trovati.extend(row.try_get::<&str, _>("name")?.map(str::to_owned));
        }
        if trovati.iter().map(String::as_str).ne(attesi.iter().copied()) {
            return Err(ErroreArca::TriggerInattesi {
                tabella,
                trovati,
                attesi: attesi.to_vec(),
            });
        }
    }
    Ok(())
}

async fn alterna_trigger(conn: &mut Connessione, azione: &str) -> Result<(), ErroreArca> {
    for (tabella, nomi, da_disattivare) in TRIGGER {
        if da_disattivare {
            for nome in nomi {
                conn.simple_query(format!("ALTER TABLE [{tabella}] {azione} TRIGGER [{nome}]"))
                    .await?
                    .into_results()
                    .await?;
            }
        }
    }
    Ok(())
}

async fn inserisci(conn: &mut Connessione, record: &Record) -> Result<i32, ErroreArca> {
    let row = record.insert().query(conn).await?.into_row().await?;
    row.and_then(|r| r.try_get::<i32, _>("Id").ok().flatten())
        .ok_or_else(|| ErroreArca::DocumentoNonValido(format!("{}: identità non restituita", record.tabella)))
}

/// Apre la transazione e scrive il documento. La transazione resta aperta: il chiamante la
/// chiude con [`conferma`] o [`annulla`].
pub async fn scrivi(conn: &mut Connessione, tabelle: &TabelleArca) -> Result<DocumentoScritto, ErroreArca> {
    let elenco: Vec<(&'static str, &'static [&'static str])> = TRIGGER.iter().map(|&(t, n, _)| (t, n)).collect();
    controlla_trigger(conn, &elenco).await?;
    conn.simple_query("BEGIN TRANSACTION").await?.into_results().await?;
    alterna_trigger(conn, "DISABLE").await?;

    let id_testata = inserisci(conn, &tabelle.testata).await?;
    let mut id_righe = Vec::with_capacity(tabelle.righe.len());
    let mut id_movimenti = Vec::with_capacity(tabelle.righe.len());
    for (riga, movimento) in &tabelle.righe {
        let riga = riga.clone().con("Id_DOTes", Valore::Intero(Some(id_testata)));
        let id_riga = inserisci(conn, &riga).await?;
        id_righe.push(id_riga);
        let id_movimento = match movimento {
            Some(m) => Some(inserisci(conn, &m.clone().con("Id_DoRig", Valore::Intero(Some(id_riga)))).await?),
            None => None,
        };
        id_movimenti.push(id_movimento);
    }
    let id_totali = inserisci(conn, &tabelle.totali.clone().con("Id_DoTes", Valore::Intero(Some(id_testata)))).await?;
    let mut id_iva = Vec::with_capacity(tabelle.iva.len());
    for iva in &tabelle.iva {
        id_iva.push(inserisci(conn, &iva.clone().con("Id_DOTes", Valore::Intero(Some(id_testata)))).await?);
    }

    // Arca chiude il salvataggio aggiornando la testata (`asp_Do_End`): il suo `Ts` è il più
    // recente del documento, e l'importazione in ATLAS trova i documenti cambiati da lì.
    conn.simple_query(format!("UPDATE DOTes SET TimeUpd = TimeUpd WHERE Id_DoTes = {id_testata}"))
        .await?
        .into_results()
        .await?;
    alterna_trigger(conn, "ENABLE").await?;
    Ok(DocumentoScritto {
        id_testata,
        id_righe,
        id_movimenti,
        id_totali,
        id_iva,
    })
}

/// Apre la transazione e scrive il cliente nuovo (`CF`) con il suo contatto (`CFContatto`).
/// Restituisce `CF.Id_CF`. La transazione resta aperta: il chiamante la chiude con [`conferma`] o
/// [`annulla`].
pub async fn scrivi_cliente(conn: &mut Connessione, cf: &Record, contatto: Option<&Record>) -> Result<i32, ErroreArca> {
    controlla_trigger(conn, &TRIGGER_CLIENTI).await?;
    conn.simple_query("BEGIN TRANSACTION").await?.into_results().await?;
    let id = inserisci(conn, cf).await?;
    if let Some(contatto) = contatto {
        inserisci(conn, contatto).await?;
    }
    Ok(id)
}

pub async fn conferma(conn: &mut Connessione) -> Result<(), ErroreArca> {
    conn.simple_query("COMMIT TRANSACTION").await?.into_results().await?;
    Ok(())
}

/// Annulla la transazione aperta, se c'è (dopo un errore `XACT_ABORT` l'ha già chiusa).
pub async fn annulla(conn: &mut Connessione) -> Result<(), ErroreArca> {
    conn.simple_query("IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION").await?.into_results().await?;
    Ok(())
}
