//! Importa (o riallinea) le anagrafiche di Arca nel database ATLAS.
//!
//! `importa-anagrafiche PERCORSO.sqlite`: legge Arca in sola lettura da `ATLAS_ARCA_ADO`, per
//! esempio `server=tcp:localhost,1433;database=ADB_BOTTAMEDI_DEV;IntegratedSecurity=SSPI;TrustServerCertificate=true`,
//! crea il database se manca e lo porta allo stato di Arca in un'unica transazione. Ripetuto
//! con gli stessi dati non modifica nulla.

use std::process::ExitCode;
use std::time::Instant;

use atlas_arca::scrittura;
use atlas_db::anagrafiche::{self, Esito};
use atlas_sync::ErroreSync;
use atlas_sync::anagrafiche::leggi_anagrafiche;

#[derive(Debug, thiserror::Error)]
enum ErroreImport {
    #[error("variabile d'ambiente ATLAS_ARCA_ADO non impostata")]
    ConnessioneNonConfigurata,
    #[error("uso: importa-anagrafiche PERCORSO.sqlite")]
    Uso,
    #[error(transparent)]
    Sync(#[from] ErroreSync),
}

fn tabella(esiti: &[Esito]) -> String {
    let mut testo = format!(
        "{:<20} {:>9} {:>10} {:>9} {:>8}\n",
        "tabella", "inserite", "aggiornate", "invariate", "assenti"
    );
    for e in esiti {
        testo.push_str(&format!(
            "{:<20} {:>9} {:>10} {:>9} {:>8}\n",
            e.tabella, e.inserite, e.aggiornate, e.invariate, e.assenti
        ));
    }
    testo
}

async fn esegui() -> Result<(), ErroreImport> {
    let percorso = std::env::args().nth(1).ok_or(ErroreImport::Uso)?;
    let ado = std::env::var("ATLAS_ARCA_ADO").map_err(|_| ErroreImport::ConnessioneNonConfigurata)?;

    let partenza = Instant::now();
    let mut arca = scrittura::connetti(&ado).await.map_err(ErroreSync::from)?;
    let database = scrittura::nome_database(&mut arca).await.map_err(ErroreSync::from)?;
    let dati = leggi_anagrafiche(&mut arca).await?;
    let lettura = partenza.elapsed();

    let mut atlas = atlas_db::apri(&percorso).map_err(ErroreSync::from)?;
    let esiti = anagrafiche::aggiorna(&mut atlas, &dati).map_err(ErroreSync::from)?;
    println!(
        "Anagrafiche da {database} in {percorso}: lettura {:.0} ms, scrittura {:.0} ms\n",
        lettura.as_secs_f64() * 1000.0,
        (partenza.elapsed() - lettura).as_secs_f64() * 1000.0
    );
    print!("{}", tabella(&esiti));
    Ok(())
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    match esegui().await {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("errore: {e}");
            ExitCode::from(2)
        }
    }
}
