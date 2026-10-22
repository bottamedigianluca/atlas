//! Replica dei documenti ATLAS nel database di Arca Evolution.
//!
//! Il documento viene tradotto nelle righe delle tabelle relazionali che Arca stessa registra
//! salvando un DDT (`DOTes`, `DORig`, `MGMov`, `DOTotali`, `DOIva`; misurato sul BO 108602 con la
//! finestra di rowversion: nessun'altra tabella viene toccata) e scritto in un'unica transazione,
//! senza passare dalle stored procedure `asp_Do_Begin`/`asp_Do_End`.
//!
//! - [`config`]: parametri di Arca letti dal database (tipo documento, causale, valuta, aliquote).
//! - [`ddt`]: il DDT ATLAS e la sua traduzione nelle tabelle, con i calcoli di `atlas-core`.
//! - [`lettura`]: i BO nativi di Arca riletti come DDT ATLAS, e quelli modificati dopo un punto.
//! - [`scrittura`]: connessione e scrittura transazionale.

pub mod config;
pub mod ddt;
pub mod lettura;
pub mod record;
pub mod scrittura;

use atlas_core::ErroreCalcolo;

#[derive(Debug, thiserror::Error)]
pub enum ErroreArca {
    #[error("SQL Server: {0}")]
    Sql(#[from] tiberius::error::Error),
    #[error("rete: {0}")]
    Rete(#[from] std::io::Error),
    #[error(transparent)]
    Calcolo(#[from] ErroreCalcolo),
    #[error("configurazione Arca: {0}")]
    Configurazione(String),
    #[error("documento non replicabile: {0}")]
    DocumentoNonValido(String),
    #[error("trigger inattesi su {tabella}: trovati {trovati:?}, attesi {attesi:?}")]
    TriggerInattesi {
        tabella: &'static str,
        trovati: Vec<String>,
        attesi: Vec<&'static str>,
    },
}
