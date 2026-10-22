//! Sincronizzazione tra ATLAS e Arca.
//!
//! - [`anagrafiche`]: lettura delle anagrafiche di Arca per il database ATLAS (sola lettura).
//! - [`clienti`]: il cliente nuovo creato in ATLAS, con le righe di `CF` e `CFContatto`.
//! - [`replica`]: il worker che scrive in Arca i documenti (e i clienti nuovi) accodati nell'outbox.
//! - [`importazione`]: il worker che porta nel database ATLAS i BO scritti o cancellati in Arca.
//! - [`numerazione`]: il numero dei nuovi documenti, sui documenti dei due sistemi.

pub mod anagrafiche;
pub mod clienti;
#[cfg(test)]
mod finta;
pub mod importazione;
pub mod numerazione;
pub mod replica;

use atlas_arca::ErroreArca;
use atlas_db::ErroreDb;

#[derive(Debug, thiserror::Error)]
pub enum ErroreSync {
    #[error(transparent)]
    Arca(#[from] ErroreArca),
    #[error(transparent)]
    Db(#[from] ErroreDb),
    #[error("BO {numero}/{esercizio} già presente in Arca con un altro contenuto (Id_DoTes {id_testata})")]
    NumeroOccupato {
        esercizio: String,
        numero: u32,
        id_testata: i32,
    },
    #[error("in Arca il {numero}/{esercizio} non è di un altro documento: non c'è nulla da rinumerare")]
    NessunConflitto { esercizio: i32, numero: u32 },
    #[error(
        "in Arca il {numero} (Id_DoTes {id_testata}) ha lo stesso cliente e lo stesso istante di salvataggio del DDT \
         ATLAS: sembra lo stesso documento modificato in Arca dopo la replica, rinumerarlo lo raddoppierebbe"
    )]
    ForseLoStesso { numero: u32, id_testata: i32 },
    #[error("cliente {codice} già presente in Arca con un'altra ragione sociale (Id_CF {id}): va scelto un altro codice")]
    CodiceOccupato { codice: String, id: i32 },
    #[error("replica non gestita: {0}")]
    NonGestito(String),
    #[error("database {0}: la replica scrive solo su un clone *_DEV")]
    NonClone(String),
    #[error("il database ATLAS importa da {legato}, non da {trovato}: gli Id_DoTes indicherebbero altri documenti")]
    AltroDatabase { legato: String, trovato: String },
    #[error("{trovate} BO spariti da Arca in un giro (al massimo {massimo}): importazione ferma, nulla cancellato")]
    TroppeCancellazioni { trovate: usize, massimo: usize },
    #[error("Arca, {tabella}.{colonna}: {problema}")]
    Dato {
        tabella: &'static str,
        colonna: &'static str,
        problema: String,
    },
}

impl From<tiberius::error::Error> for ErroreSync {
    fn from(e: tiberius::error::Error) -> Self {
        Self::Arca(e.into())
    }
}
