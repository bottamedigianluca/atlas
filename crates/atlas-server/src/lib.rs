//! Backend di ATLAS: API REST e WebSocket sul database ATLAS (Axum).
//!
//! - [`lettori`]: connessioni di sola lettura, per le letture sotto i 2 ms.
//! - [`worker`]: l'unico scrittore, su un thread suo: salvataggio con la numerazione unica,
//!   rinumerazione, replica e importazione con Arca.
//! - [`bozza`]: il DDT battuto dall'operatore, completato e calcolato con `atlas-core`.
//! - [`prezzi`]: la maschera prezzi del tasto `F3`.
//! - [`consultazione`]: anagrafiche, elenco e dettaglio dei DDT, stato della replica.
//! - [`partita_iva`]: cifra di controllo e dati dell'azienda dal servizio VIES.
//! - [`home`]: la Home della postazione (clienti del giorno); i post-it sono in `atlas_db::note`.
//! - [`strumenti`]: le funzioni come strumenti JSON Schema per assistenti e workflow.
//! - [`rotte`]: REST e WebSocket.

pub mod bozza;
pub mod config;
pub mod consultazione;
pub mod errore;
pub mod home;
pub mod lettori;
pub mod partita_iva;
pub mod prezzi;
pub mod rotte;
pub mod servizio;
pub mod strumenti;
pub mod worker;

use atlas_sync::importazione::Origine;
use tokio::sync::broadcast;

use crate::config::Config;
use crate::errore::ErroreApi;
use crate::lettori::Lettori;
use crate::servizio::Servizio;
use crate::worker::{Maniglia, Replica, Sorgenti};

/// Notifiche in attesa per client WebSocket prima che un client lento ne perda.
const NOTIFICHE_IN_CODA: usize = 256;

/// Apre il database (migrandolo), avvia il worker e prepara il servizio delle richieste.
pub fn prepara<O, D>(config: &Config, sorgenti: Sorgenti<O, D>) -> Result<(Servizio, Maniglia), ErroreApi>
where
    O: Origine + Send + 'static,
    D: Replica + Send + 'static,
{
    // Lo scrittore per primo: migra lo schema prima che si aprano i lettori.
    let db = atlas_db::apri(&config.database)?;
    let lettori = Lettori::apri(&config.database, config.lettori)?;
    let (notifiche, _) = broadcast::channel(NOTIFICHE_IN_CODA);
    let maniglia = worker::avvia(db, sorgenti, config.predefiniti.clone(), notifiche.clone())
        .map_err(|e| ErroreApi::Interno(format!("avvio del worker: {e}")))?;
    let servizio = Servizio::nuovo(
        lettori,
        maniglia.comandi.clone(),
        maniglia.stato.clone(),
        notifiche,
        config.predefiniti.clone(),
        partita_iva::Vies::nuovo(&config.vies_url)?,
    );
    Ok((servizio, maniglia))
}
