//! Errori delle API: un codice stabile per i programmi, un messaggio per l'operatore, lo stato
//! HTTP. Gli stessi errori viaggiano sul WebSocket e negli strumenti.

use atlas_core::ErroreCalcolo;
use atlas_db::ErroreDb;
use atlas_sync::ErroreSync;
use axum::Json;
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use serde::Serialize;

#[derive(Debug, thiserror::Error)]
pub enum ErroreApi {
    #[error(transparent)]
    Db(#[from] ErroreDb),
    #[error(transparent)]
    Sync(#[from] ErroreSync),
    #[error(transparent)]
    Calcolo(#[from] ErroreCalcolo),
    /// Bozza non trasformabile in documento: un motivo per riga o per la testata.
    #[error("documento non valido: {}", .0.join("; "))]
    Bozza(Vec<String>),
    #[error("richiesta non valida: {0}")]
    Richiesta(String),
    #[error("{0} inesistente")]
    NonTrovato(String),
    #[error("{0}")]
    NonDisponibile(String),
    #[error("errore interno: {0}")]
    Interno(String),
}

impl From<rusqlite::Error> for ErroreApi {
    fn from(e: rusqlite::Error) -> Self {
        Self::Db(ErroreDb::Sqlite(e))
    }
}

/// Corpo JSON di un errore.
#[derive(Debug, Clone, Serialize, PartialEq, Eq)]
pub struct CorpoErrore {
    pub codice: &'static str,
    pub messaggio: String,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub dettagli: Vec<String>,
}

impl ErroreApi {
    /// Codice stabile e stato HTTP.
    pub fn classe(&self) -> (&'static str, StatusCode) {
        match self {
            Self::Db(e) => classe_db(e),
            Self::Sync(e) => match e {
                ErroreSync::Db(e) => classe_db(e),
                ErroreSync::NumeroOccupato { .. } => ("numero_occupato", StatusCode::CONFLICT),
                ErroreSync::CodiceOccupato { .. } => ("codice_occupato", StatusCode::CONFLICT),
                ErroreSync::NessunConflitto { .. } => ("nessun_conflitto", StatusCode::CONFLICT),
                ErroreSync::ForseLoStesso { .. } => ("forse_lo_stesso", StatusCode::CONFLICT),
                ErroreSync::AltroDatabase { .. } | ErroreSync::NonClone(_) => {
                    ("database_arca_errato", StatusCode::CONFLICT)
                }
                ErroreSync::Arca(_) | ErroreSync::Dato { .. } => ("arca", StatusCode::BAD_GATEWAY),
                ErroreSync::NonGestito(_) | ErroreSync::TroppeCancellazioni { .. } => {
                    ("non_gestito", StatusCode::UNPROCESSABLE_ENTITY)
                }
            },
            Self::Calcolo(_) => ("calcolo", StatusCode::UNPROCESSABLE_ENTITY),
            Self::Bozza(_) => ("documento_non_valido", StatusCode::UNPROCESSABLE_ENTITY),
            Self::Richiesta(_) => ("richiesta_non_valida", StatusCode::BAD_REQUEST),
            Self::NonTrovato(_) => ("non_trovato", StatusCode::NOT_FOUND),
            Self::NonDisponibile(_) => ("non_disponibile", StatusCode::SERVICE_UNAVAILABLE),
            Self::Interno(_) => ("interno", StatusCode::INTERNAL_SERVER_ERROR),
        }
    }

    pub fn corpo(&self) -> CorpoErrore {
        let (codice, _) = self.classe();
        CorpoErrore {
            codice,
            messaggio: self.to_string(),
            dettagli: match self {
                Self::Bozza(motivi) => motivi.clone(),
                _ => Vec::new(),
            },
        }
    }
}

fn classe_db(e: &ErroreDb) -> (&'static str, StatusCode) {
    match e {
        ErroreDb::NumeroOccupato { .. } => ("numero_occupato", StatusCode::CONFLICT),
        ErroreDb::CodiceOccupato(_) => ("codice_occupato", StatusCode::CONFLICT),
        ErroreDb::Numerazione(_) => ("numero_non_valido", StatusCode::UNPROCESSABLE_ENTITY),
        ErroreDb::DocumentoNonValido(_) | ErroreDb::RiferimentiInesistenti(_) => {
            ("documento_non_valido", StatusCode::UNPROCESSABLE_ENTITY)
        }
        ErroreDb::Calcolo(_) => ("calcolo", StatusCode::UNPROCESSABLE_ENTITY),
        ErroreDb::NonTrovato(_) => ("non_trovato", StatusCode::NOT_FOUND),
        ErroreDb::Sqlite(e) if e.sqlite_error_code() == Some(rusqlite::ErrorCode::DatabaseBusy) => {
            ("occupato", StatusCode::SERVICE_UNAVAILABLE)
        }
        ErroreDb::Sqlite(_) | ErroreDb::Json(_) | ErroreDb::VersioneSconosciuta { .. } => {
            ("database", StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

impl IntoResponse for ErroreApi {
    fn into_response(self) -> Response {
        let (_, stato) = self.classe();
        (stato, Json(self.corpo())).into_response()
    }
}
