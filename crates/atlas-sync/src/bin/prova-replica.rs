//! Prepara le prove del worker di replica sul clone.
//!
//! `prova-replica nuovo DB ID_DOTES [NUMERO | --senza-arca]`: salva nel database ATLAS `DB` (con
//! le anagrafiche già importate) un nuovo DDT con le righe del BO `ID_DOTES` del clone, datato
//! adesso, e lo mette in coda per la replica. Il numero è `NUMERO` o quello della numerazione
//! unica ([`numerazione::crea`]); con `--senza-arca` la numerazione non raggiunge Arca (indirizzo
//! chiuso) e numera sul solo database ATLAS, come con Arca spenta.
//!
//! `prova-replica rinumera DB ID`: rinumera il DDT ATLAS `ID` il cui numero in Arca è di un altro
//! documento ([`numerazione::rinumera`]).
//!
//! Connessione da `ATLAS_ARCA_DEV_ADO`; il programma rifiuta i database che non finiscono in `_DEV`.

use std::process::ExitCode;

use atlas_arca::{lettura, scrittura};
use atlas_db::ddt;
use atlas_sync::ErroreSync;
use atlas_sync::importazione::Arca;
use atlas_sync::numerazione::{self, ATTESA_ARCA};
use chrono::{Datelike, Local, Timelike};

/// Porta TCP chiusa: la connessione è rifiutata subito.
const ARCA_IRRAGGIUNGIBILE: &str = "server=tcp:127.0.0.1,9;database=ADB_BOTTAMEDI_DEV;IntegratedSecurity=SSPI";

#[derive(Debug, thiserror::Error)]
enum ErroreProva {
    #[error("variabile d'ambiente ATLAS_ARCA_DEV_ADO non impostata")]
    ConnessioneNonConfigurata,
    #[error("uso: prova-replica nuovo DB ID_DOTES [NUMERO | --senza-arca] | rinumera DB ID")]
    Uso,
    #[error("{0} non esiste")]
    FileInesistente(String),
    #[error(transparent)]
    Sync(#[from] ErroreSync),
}

impl From<atlas_arca::ErroreArca> for ErroreProva {
    fn from(e: atlas_arca::ErroreArca) -> Self {
        Self::Sync(e.into())
    }
}

impl From<atlas_db::ErroreDb> for ErroreProva {
    fn from(e: atlas_db::ErroreDb) -> Self {
        Self::Sync(e.into())
    }
}

impl From<tiberius::error::Error> for ErroreProva {
    fn from(e: tiberius::error::Error) -> Self {
        Self::Sync(e.into())
    }
}

async fn esegui() -> Result<(), ErroreProva> {
    let mut argomenti = std::env::args().skip(1);
    let comando = argomenti.next().ok_or(ErroreProva::Uso)?;
    let file = argomenti.next().ok_or(ErroreProva::Uso)?;
    if !std::path::Path::new(&file).exists() {
        return Err(ErroreProva::FileInesistente(file));
    }
    let ado = std::env::var("ATLAS_ARCA_DEV_ADO").map_err(|_| ErroreProva::ConnessioneNonConfigurata)?;
    if comando == "rinumera" {
        let id: i64 = argomenti.next().and_then(|a| a.parse().ok()).ok_or(ErroreProva::Uso)?;
        let mut db = atlas_db::apri(&file)?;
        let prima = ddt::carica(&db, id)?.numero;
        let numero = numerazione::rinumera(&mut db, &mut Arca::nuova(ado), id).await?;
        println!("DDT ATLAS {id}: numero {prima} occupato in Arca, ora {numero}; eventi in coda aggiornati");
        return Ok(());
    }
    if comando != "nuovo" {
        return Err(ErroreProva::Uso);
    }
    let modello: i32 = argomenti.next().and_then(|a| a.parse().ok()).ok_or(ErroreProva::Uso)?;
    let (numero, senza_arca) = match argomenti.next().as_deref() {
        None => (None, false),
        Some("--senza-arca") => (None, true),
        Some(a) => (Some(a.parse().map_err(|_| ErroreProva::Uso)?), false),
    };
    let mut arca = scrittura::connetti(&ado).await?;
    let database = scrittura::nome_database(&mut arca).await?;
    if !database.to_ascii_uppercase().ends_with("_DEV") {
        return Err(ErroreSync::NonClone(database).into());
    }

    let adesso = Local::now().naive_local();
    let adesso = adesso.with_second(0).and_then(|t| t.with_nanosecond(0)).unwrap_or(adesso);
    let mut nuovo = lettura::carica(&mut arca, modello).await?;
    nuovo.data = adesso.date();
    nuovo.registrato_il = adesso;
    nuovo.inizio_trasporto = Some(adesso);

    let mut db = atlas_db::apri(&file)?;
    let salvato = match numero {
        Some(n) => {
            nuovo.numero = n;
            ddt::salva(&mut db, &nuovo, adesso)?
        }
        None => {
            let mut origine = Arca::nuova(if senza_arca { ARCA_IRRAGGIUNGIBILE } else { ado.as_str() });
            let creato = numerazione::crea(&mut db, &mut origine, &mut nuovo, adesso, ATTESA_ARCA).await?;
            if let Some(motivo) = creato.senza_arca {
                println!("numerato senza Arca: {motivo}");
            }
            creato.salvato
        }
    };
    println!(
        "DDT {}/{} del {} ({} righe, righe del BO Id_DoTes {modello}) salvato in ATLAS: id {}, evento {}",
        nuovo.numero,
        adesso.year(),
        nuovo.data.format("%d/%m/%Y"),
        nuovo.righe.len(),
        salvato.id,
        salvato.evento
    );
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
