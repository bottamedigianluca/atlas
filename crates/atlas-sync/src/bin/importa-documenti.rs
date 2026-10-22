//! Importazione continua: porta nel database ATLAS i BO scritti, modificati o cancellati in Arca.
//!
//! - `importa-documenti DB`: gira finché non viene fermato; controlla Arca ogni secondo. Un errore
//!   (Arca spenta, rete) viene mostrato e il giro riprova dopo [`PAUSA_ERRORE`].
//! - `importa-documenti DB --una-volta`: importa fino a essere in pari con Arca ed esce (codice
//!   0 solo senza documenti fermi). Il primo giro su un database nuovo importa tutto lo storico.
//!
//! Arca è letta in sola lettura da `ATLAS_ARCA_ADO`. Il database ATLAS si lega al primo database
//! di Arca da cui importa e rifiuta poi tutti gli altri.

use std::process::ExitCode;
use std::time::{Duration, Instant};

use atlas_db::importazione;
use atlas_sync::ErroreSync;
use atlas_sync::importazione::{self as import, Arca, Giro};
use chrono::{Local, NaiveDateTime, Timelike};

/// Documenti per giro: abbastanza da recuperare in fretta lo storico, pochi da tenere breve la
/// transazione SQLite.
const DOCUMENTI_PER_GIRO: usize = 500;
const PAUSA: Duration = Duration::from_secs(1);
const PAUSA_ERRORE: Duration = Duration::from_secs(5);

#[derive(Debug, thiserror::Error)]
enum ErroreWorker {
    #[error("variabile d'ambiente ATLAS_ARCA_ADO non impostata")]
    ConnessioneNonConfigurata,
    #[error("uso: importa-documenti DB [--una-volta]")]
    Uso,
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

fn somma(totale: &mut Giro, giro: &Giro) {
    totale.letti += giro.letti;
    totale.nuovi += giro.nuovi;
    totale.aggiornati += giro.aggiornati;
    totale.invariati += giro.invariati;
    totale.collegati += giro.collegati;
    totale.esclusi += giro.esclusi;
    totale.cancellati += giro.cancellati;
}

fn riepilogo(giro: &Giro) -> String {
    format!(
        "letti {}: nuovi {}, aggiornati {}, invariati {}, collegati {}, esclusi {}; cancellati {}",
        giro.letti, giro.nuovi, giro.aggiornati, giro.invariati, giro.collegati, giro.esclusi, giro.cancellati
    )
}

async fn esegui() -> Result<bool, ErroreWorker> {
    let mut argomenti = std::env::args().skip(1);
    let file = argomenti.next().ok_or(ErroreWorker::Uso)?;
    let una_volta = match argomenti.next().as_deref() {
        None => false,
        Some("--una-volta") => true,
        Some(_) => return Err(ErroreWorker::Uso),
    };
    let ado = std::env::var("ATLAS_ARCA_ADO").map_err(|_| ErroreWorker::ConnessioneNonConfigurata)?;
    let mut db = atlas_db::apri(&file)?;
    let mut arca = Arca::nuova(ado);

    let partenza = Instant::now();
    let mut totale = Giro::default();
    let mut fermo: Option<(i32, String)>;
    loop {
        let giro = match import::giro(&mut db, &mut arca, adesso, DOCUMENTI_PER_GIRO).await {
            Ok(giro) => giro,
            Err(e) if una_volta => return Err(e.into()),
            Err(e) => {
                println!("{}  errore: {e}", Local::now().format("%H:%M:%S"));
                arca.scollega();
                tokio::time::sleep(PAUSA_ERRORE).await;
                continue;
            }
        };
        somma(&mut totale, &giro);
        if giro.cambiati() > 0 || giro.letti == DOCUMENTI_PER_GIRO {
            println!("{}  {}", Local::now().format("%H:%M:%S"), riepilogo(&totale));
        }
        if let Some((id, errore)) = &giro.fermo {
            println!("{}  Id_DoTes {id} non importato: {errore}", Local::now().format("%H:%M:%S"));
        }
        fermo = giro.fermo.clone();
        if una_volta && (giro.fermo.is_some() || giro.letti < DOCUMENTI_PER_GIRO) {
            break;
        }
        if giro.letti < DOCUMENTI_PER_GIRO {
            tokio::time::sleep(PAUSA).await;
        }
    }

    let secondi = partenza.elapsed().as_secs_f64();
    let per_documento = match totale.letti {
        0 => String::new(),
        n => format!(", {:.2} ms per documento", secondi * 1000.0 / n as f64),
    };
    println!("\n{} in {secondi:.1} s{per_documento}", riepilogo(&totale));
    let esclusi = importazione::esclusi(&db)?;
    if !esclusi.is_empty() {
        println!("\nesclusi ({}):", esclusi.len());
        for e in &esclusi {
            println!("  {} {}/{} (Id_DoTes {}): {}", e.tipo_documento, e.numero, e.esercizio, e.arca_id_testata, e.motivo);
        }
    }
    Ok(fermo.is_none())
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
