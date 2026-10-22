//! Database primario di ATLAS: un file SQLite in modalità WAL aperto dal solo backend.
//!
//! - [`connessione`]: apertura, impostazioni di sessione e migrazioni dello schema.
//! - [`anagrafiche`]: tabelle importate da Arca e loro aggiornamento idempotente.
//! - [`ddt`]: salvataggio e lettura dei DDT; ogni scrittura accoda l'evento di replica, tranne
//!   l'importazione dei documenti di Arca.
//! - [`importazione`]: fin dove è arrivata l'importazione da Arca e cosa ha escluso.
//! - [`numerazione`]: numeri occupati per sezionale ed esercizio.
//! - [`outbox`]: coda degli eventi da replicare in Arca.

pub mod anagrafiche;
pub mod connessione;
pub mod ddt;
pub mod importazione;
pub mod numerazione;
pub mod outbox;
#[cfg(any(test, feature = "prova"))]
pub mod prova;
mod valori;

use atlas_core::ErroreCalcolo;
use atlas_core::numerazione::NumeroNonValido;

pub use connessione::{apri, apri_in_memoria};
pub use rusqlite::{Connection, TransactionBehavior};

#[derive(Debug, thiserror::Error)]
pub enum ErroreDb {
    #[error("SQLite: {0}")]
    Sqlite(#[from] rusqlite::Error),
    #[error(transparent)]
    Calcolo(#[from] ErroreCalcolo),
    #[error("JSON: {0}")]
    Json(#[from] serde_json::Error),
    #[error("database alla versione {trovata}, il programma conosce fino alla {nota}")]
    VersioneSconosciuta { trovata: i64, nota: i64 },
    #[error("DDT {numero}/{esercizio} già presente")]
    NumeroOccupato { esercizio: i32, numero: u32 },
    #[error(transparent)]
    Numerazione(NumeroNonValido),
    #[error("documento non valido: {0}")]
    DocumentoNonValido(String),
    #[error("riferimenti inesistenti: {0}")]
    RiferimentiInesistenti(String),
    #[error("{0} inesistente")]
    NonTrovato(String),
}
