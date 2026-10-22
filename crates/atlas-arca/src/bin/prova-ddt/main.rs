//! Prova della replica dei DDT nelle tabelle di Arca, solo su un clone di sviluppo.
//!
//! - `prova-ddt rigioca [DAL] [AL]`: ogni BO nativo del periodo viene riletto come DDT ATLAS,
//!   ricalcolato, scritto in transazione accanto all'originale, confrontato colonna per
//!   colonna e annullato. Il database resta com'era.
//! - `prova-ddt scrivi ID_DOTES`: scrive e conferma un DDT di prova con le righe del BO
//!   `ID_DOTES`, datato oggi e con il primo numero libero, poi lo confronta con il modello.
//! - `prova-ddt confronta MODELLO ID_DOTES`: confronta colonna per colonna un BO già scritto
//!   (per esempio dal worker di replica) con il BO da cui è stato copiato. Non scrive nulla.
//!
//! Connessione da `ATLAS_ARCA_DEV_ADO`, ad esempio
//! `server=tcp:localhost,1433;database=ADB_BOTTAMEDI_DEV;IntegratedSecurity=SSPI;TrustServerCertificate=true`.
//! Il programma rifiuta qualsiasi database il cui nome non finisca in `_DEV`.

mod confronto;

use std::process::ExitCode;
use std::time::Instant;

use atlas_arca::ErroreArca;
use atlas_arca::config::ConfigArca;
use atlas_arca::ddt::InTabelle;
use atlas_arca::lettura as nativo;
use atlas_arca::scrittura::{self, Connessione};
use chrono::{Datelike, Local, NaiveDate, Timelike};

/// Numero usato per le repliche annullate: fuori dalla numerazione reale.
const NUMERO_PROVA: u32 = 999_999;

#[derive(Debug, thiserror::Error)]
enum ErroreProva {
    #[error("variabile d'ambiente ATLAS_ARCA_DEV_ADO non impostata")]
    ConnessioneNonConfigurata,
    #[error("database {0}: la prova scrive solo su un clone *_DEV")]
    NonClone(String),
    #[error("uso: prova-ddt rigioca [DAL] [AL] | prova-ddt scrivi ID_DOTES | prova-ddt confronta MODELLO ID_DOTES")]
    Uso,
    #[error("data non valida \"{0}\": formato atteso AAAA-MM-GG")]
    DataNonValida(String),
    #[error(transparent)]
    Arca(#[from] ErroreArca),
}

impl From<tiberius::error::Error> for ErroreProva {
    fn from(e: tiberius::error::Error) -> Self {
        Self::Arca(e.into())
    }
}

fn data(argomento: Option<String>, predefinita: NaiveDate) -> Result<NaiveDate, ErroreProva> {
    match argomento {
        None => Ok(predefinita),
        Some(testo) => NaiveDate::parse_from_str(&testo, "%Y-%m-%d").map_err(|_| ErroreProva::DataNonValida(testo)),
    }
}

async fn rigioca(conn: &mut Connessione, cfg: &ConfigArca, dal: NaiveDate, al: NaiveDate) -> Result<bool, ErroreProva> {
    let partenza = Instant::now();
    let (documenti, esclusi) = nativo::documenti(conn, dal, al).await?;
    let mut riepilogo = confronto::Riepilogo::default();
    for id in documenti {
        let mut ddt = nativo::carica(conn, id).await?;
        ddt.numero = NUMERO_PROVA;
        let tabelle = ddt.in_tabelle(cfg)?;
        let esito = match scrittura::scrivi(conn, &tabelle).await {
            Ok(scritto) => confronto::confronta(conn, id, scritto.id_testata).await,
            Err(e) => Err(e),
        };
        scrittura::annulla(conn).await?;
        riepilogo.aggiungi(id, esito?);
    }
    println!(
        "BO dal {dal} al {al}, esclusi {esclusi} non replicabili, in {:.1} s\n",
        partenza.elapsed().as_secs_f64()
    );
    print!("{}", riepilogo.testo());
    Ok(riepilogo.identici_alla_creazione == riepilogo.documenti)
}

async fn primo_numero_libero(conn: &mut Connessione, cfg: &ConfigArca, anno: i32) -> Result<u32, ErroreProva> {
    let row = conn
        .simple_query(format!(
            "select isnull(max(NumeroDocI), 0) + 1 as Numero from DOTes where Cd_CN = '{}' and EsAnno = '{anno}'",
            cfg.documento.sezionale
        ))
        .await?
        .into_row()
        .await?;
    let numero = row.and_then(|r| r.try_get::<i32, _>("Numero").ok().flatten()).unwrap_or(1);
    Ok(u32::try_from(numero).unwrap_or(1))
}

async fn scrivi(conn: &mut Connessione, cfg: &ConfigArca, modello: i32) -> Result<bool, ErroreProva> {
    let adesso = Local::now().naive_local();
    let adesso = adesso.with_second(0).and_then(|t| t.with_nanosecond(0)).unwrap_or(adesso);
    let mut ddt = nativo::carica(conn, modello).await?;
    ddt.data = adesso.date();
    ddt.registrato_il = adesso;
    ddt.inizio_trasporto = Some(adesso);
    ddt.numero = primo_numero_libero(conn, cfg, adesso.year()).await?;

    let tabelle = ddt.in_tabelle(cfg)?;
    let scritto = match scrittura::scrivi(conn, &tabelle).await {
        Ok(scritto) => {
            scrittura::conferma(conn).await?;
            scritto
        }
        Err(e) => {
            scrittura::annulla(conn).await?;
            return Err(e.into());
        }
    };
    println!(
        "Scritto BO {} del {} (Id_DoTes {}, {} righe, {} movimenti, {} righe IVA) sul modello Id_DoTes {modello}\n",
        ddt.numero,
        ddt.data.format("%d/%m/%Y"),
        scritto.id_testata,
        scritto.id_righe.len(),
        scritto.id_movimenti.iter().flatten().count(),
        scritto.id_iva.len()
    );
    confronta(conn, modello, scritto.id_testata).await
}

async fn confronta(conn: &mut Connessione, modello: i32, id: i32) -> Result<bool, ErroreProva> {
    let esito = confronto::confronta(conn, modello, id).await?;
    println!("Valori confrontati con il modello: {}, differenze: {}", esito.colonne, esito.differenze.len());
    for d in &esito.differenze {
        println!("  {}.{} riga {}: modello {} / nuovo {}", d.tabella, d.colonna, d.riga, d.nativo, d.replica);
    }
    Ok(true)
}

async fn esegui() -> Result<bool, ErroreProva> {
    let mut argomenti = std::env::args().skip(1);
    let comando = argomenti.next().ok_or(ErroreProva::Uso)?;
    let ado = std::env::var("ATLAS_ARCA_DEV_ADO").map_err(|_| ErroreProva::ConnessioneNonConfigurata)?;
    let mut conn = scrittura::connetti(&ado).await?;
    let database = scrittura::nome_database(&mut conn).await?;
    if !database.to_ascii_uppercase().ends_with("_DEV") {
        return Err(ErroreProva::NonClone(database));
    }
    let cfg = ConfigArca::carica(&mut conn, "BO").await?;

    match comando.as_str() {
        "rigioca" => {
            let oggi = Local::now().date_naive();
            let inizio_anno = NaiveDate::from_ymd_opt(oggi.year(), 1, 1).unwrap_or(oggi);
            let dal = data(argomenti.next(), inizio_anno)?;
            let al = data(argomenti.next(), oggi)?;
            rigioca(&mut conn, &cfg, dal, al).await
        }
        "scrivi" => {
            let modello = argomenti.next().and_then(|a| a.parse().ok()).ok_or(ErroreProva::Uso)?;
            scrivi(&mut conn, &cfg, modello).await
        }
        "confronta" => {
            let mut id = || argomenti.next().and_then(|a| a.parse().ok()).ok_or(ErroreProva::Uso);
            let (modello, scritto) = (id()?, id()?);
            confronta(&mut conn, modello, scritto).await
        }
        _ => Err(ErroreProva::Uso),
    }
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    match esegui().await {
        Ok(true) => ExitCode::SUCCESS,
        Ok(false) => ExitCode::FAILURE,
        Err(e) => {
            eprintln!("errore: {e}");
            ExitCode::from(2)
        }
    }
}
