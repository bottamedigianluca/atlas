//! Verifica del motore ATLAS contro lo storico di Arca Evolution.
//!
//! Uso: `atlas-verify [DAL] [AL]` con date `AAAA-MM-GG` (predefinito: dal 2025-01-01 a oggi).
//! La stringa di connessione ADO.NET si legge da `ATLAS_ARCA_ADO`, ad esempio:
//! `server=tcp:PCARCA-2023,1433;database=ADB_BOTTAMEDI;user=bihortus_reader;password=...;TrustServerCertificate=true`.
//! Il programma esegue solo SELECT; l'utente indicato deve comunque essere in sola lettura.

mod arca;
mod verifica;

use std::process::ExitCode;
use std::time::Instant;

use chrono::{Local, NaiveDate};

#[derive(Debug, thiserror::Error)]
pub enum ErroreVerifica {
    #[error("variabile d'ambiente ATLAS_ARCA_ADO non impostata")]
    ConnessioneNonConfigurata,
    #[error("data non valida \"{0}\": formato atteso AAAA-MM-GG")]
    DataNonValida(String),
    #[error("SQL Server: {0}")]
    Sql(#[from] tiberius::error::Error),
    #[error("rete: {0}")]
    Rete(#[from] std::io::Error),
    #[error("colonna {0} vuota")]
    ColonnaVuota(&'static str),
    #[error(transparent)]
    TipoDocumento(#[from] atlas_core::numerazione::TipoNonGestito),
    #[error("configurazione Arca non gestita: {0}")]
    NonGestito(String),
}

fn data(argomento: Option<String>, predefinita: NaiveDate) -> Result<NaiveDate, ErroreVerifica> {
    match argomento {
        None => Ok(predefinita),
        Some(testo) => NaiveDate::parse_from_str(&testo, "%Y-%m-%d").map_err(|_| ErroreVerifica::DataNonValida(testo)),
    }
}

async fn esegui() -> Result<u64, ErroreVerifica> {
    let mut argomenti = std::env::args().skip(1);
    let inizio_anno = NaiveDate::from_ymd_opt(2025, 1, 1).ok_or(ErroreVerifica::DataNonValida("2025-01-01".into()))?;
    let dal = data(argomenti.next(), inizio_anno)?;
    let al = data(argomenti.next(), Local::now().date_naive())?;
    let ado = std::env::var("ATLAS_ARCA_ADO").map_err(|_| ErroreVerifica::ConnessioneNonConfigurata)?;

    let partenza = Instant::now();
    let mut conn = arca::connetti(&ado).await?;
    let storico = arca::carica(&mut conn, dal, al).await?;
    let caricamento = partenza.elapsed();
    let rapporto = verifica::esegui(&storico);

    println!(
        "Storico Arca dal {dal} al {al}: {} documenti, caricati in {:.1} s, verificati in {:.1} s\n",
        storico.documenti.len(),
        caricamento.as_secs_f64(),
        (partenza.elapsed() - caricamento).as_secs_f64()
    );
    print!("{}", rapporto.testo());
    Ok(rapporto.difformi())
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    match esegui().await {
        Ok(0) => ExitCode::SUCCESS,
        Ok(difformi) => {
            eprintln!("\n{difformi} difformita'");
            ExitCode::FAILURE
        }
        Err(errore) => {
            eprintln!("errore: {errore}");
            ExitCode::from(2)
        }
    }
}
