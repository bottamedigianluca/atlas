//! Worker di replica: scrive in Arca i documenti accodati nel database ATLAS.
//!
//! - `replica DB`: gira finché non viene fermato; controlla la coda ogni secondo.
//! - `replica DB --una-volta`: svuota la coda, o si ferma al primo evento che fallisce, ed esce
//!   (codice 0 solo con la coda vuota). Per le prove.
//!
//! Connessione da `ATLAS_ARCA_DEV_ADO`: finché non si decide sulla produzione la replica
//! rifiuta qualsiasi database il cui nome non finisca in `_DEV`.

use std::process::ExitCode;
use std::time::{Duration, Instant};

use atlas_db::outbox;
use atlas_sync::ErroreSync;
use atlas_sync::replica::{self, Arca, Giro};
use chrono::{Local, NaiveDateTime, Timelike};

/// Eventi per giro: tra un giro e l'altro il worker registra l'avanzamento a video.
const EVENTI_PER_GIRO: usize = 100;
const PAUSA: Duration = Duration::from_secs(1);

#[derive(Debug, thiserror::Error)]
enum ErroreWorker {
    #[error("variabile d'ambiente ATLAS_ARCA_DEV_ADO non impostata")]
    ConnessioneNonConfigurata,
    #[error("uso: replica DB [--una-volta]")]
    Uso,
    #[error("{0} non esiste")]
    FileInesistente(String),
    #[error(transparent)]
    Sync(#[from] ErroreSync),
}

impl From<atlas_db::ErroreDb> for ErroreWorker {
    fn from(e: atlas_db::ErroreDb) -> Self {
        Self::Sync(e.into())
    }
}

/// Al secondo, come gli altri istanti del database ATLAS.
fn adesso() -> NaiveDateTime {
    let adesso = Local::now().naive_local();
    adesso.with_nanosecond(0).unwrap_or(adesso)
}

async fn esegui() -> Result<bool, ErroreWorker> {
    let mut argomenti = std::env::args().skip(1);
    let file = argomenti.next().ok_or(ErroreWorker::Uso)?;
    let una_volta = match argomenti.next().as_deref() {
        None => false,
        Some("--una-volta") => true,
        Some(_) => return Err(ErroreWorker::Uso),
    };
    if !std::path::Path::new(&file).exists() {
        return Err(ErroreWorker::FileInesistente(file));
    }
    let ado = std::env::var("ATLAS_ARCA_DEV_ADO").map_err(|_| ErroreWorker::ConnessioneNonConfigurata)?;
    let db = atlas_db::apri(&file)?;
    let mut arca = Arca::nuova(ado);

    let partenza = Instant::now();
    let mut totale = Giro::default();
    println!("in coda: {}", outbox::in_attesa(&db)?);
    loop {
        let giro = replica::giro(&db, &mut arca, adesso, EVENTI_PER_GIRO).await?;
        totale.scritti += giro.scritti;
        totale.gia_presenti += giro.gia_presenti;
        if giro.replicati() > 0 {
            println!(
                "{}  scritti {}, già presenti {}, in coda {}",
                Local::now().format("%H:%M:%S"),
                totale.scritti,
                totale.gia_presenti,
                outbox::in_attesa(&db)?
            );
        }
        if let Some((id, errore)) = &giro.fallito {
            println!("{}  evento {id} non replicato: {errore}", Local::now().format("%H:%M:%S"));
            totale.fallito = giro.fallito.clone();
        }
        if una_volta && (giro.fallito.is_some() || outbox::in_attesa(&db)? == 0) {
            break;
        }
        if giro.replicati() < EVENTI_PER_GIRO {
            tokio::time::sleep(PAUSA).await;
        }
    }
    let replicati = totale.replicati();
    let secondi = partenza.elapsed().as_secs_f64();
    let per_documento = match replicati {
        0 => String::new(),
        n => format!(", {:.1} ms per documento", secondi * 1000.0 / n as f64),
    };
    println!(
        "\nreplicati {replicati} (scritti {}, già presenti {}) in {secondi:.1} s{per_documento}; in coda {}",
        totale.scritti,
        totale.gia_presenti,
        outbox::in_attesa(&db)?
    );
    Ok(totale.fallito.is_none())
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
