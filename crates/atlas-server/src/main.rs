//! `atlas-server [DB]`: il backend ATLAS. Configurazione in [`atlas_server::config`].

use std::process::ExitCode;

use atlas_server::config::Config;
use atlas_server::worker::Sorgenti;

async fn esegui() -> Result<(), String> {
    let config = Config::da_ambiente(std::env::args().skip(1)).map_err(|e| e.to_string())?;
    let sorgenti = Sorgenti::arca(config.arca_ado.as_deref());
    let (servizio, maniglia) = atlas_server::prepara(&config, sorgenti).map_err(|e| e.to_string())?;
    let ascolto = tokio::net::TcpListener::bind(config.indirizzo)
        .await
        .map_err(|e| format!("{}: {e}", config.indirizzo))?;
    println!(
        "ATLAS {} su http://{} — database {}, Arca {}",
        env!("CARGO_PKG_VERSION"),
        config.indirizzo,
        config.database.display(),
        if config.arca_ado.is_some() { "configurata" } else { "non configurata" }
    );
    axum::serve(ascolto, atlas_server::rotte::router(servizio))
        .with_graceful_shutdown(async {
            let _ = tokio::signal::ctrl_c().await;
        })
        .await
        .map_err(|e| e.to_string())?;
    // Il servizio è chiuso: il worker finisce il comando in corso ed esce.
    tokio::task::spawn_blocking(move || maniglia.attendi()).await.map_err(|e| e.to_string())?;
    println!("ATLAS fermo");
    Ok(())
}

#[tokio::main]
async fn main() -> ExitCode {
    match esegui().await {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("errore: {e}");
            ExitCode::from(2)
        }
    }
}
