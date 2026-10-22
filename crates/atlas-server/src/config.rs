//! Configurazione del backend, dalle variabili d'ambiente.
//!
//! - `ATLAS_DB` (o primo argomento): file del database ATLAS. Lo apre solo il backend.
//! - `ATLAS_ARCA_ADO`: stringa di connessione ADO ad Arca, la stessa per i due versi
//!   (importazione e numerazione in lettura, replica in scrittura). Senza, il backend numera sul
//!   solo database ATLAS e non sincronizza. La replica scrive solo su un clone `*_DEV` e solo nel
//!   database da cui il file ATLAS importa.
//! - `ATLAS_INDIRIZZO`: indirizzo di ascolto, predefinito `127.0.0.1:7878` (solo questa
//!   postazione: le altre arriveranno con mTLS, Task 8).
//! - `ATLAS_OPERATORE`: utente Arca registrato nei documenti (`UserIns`), predefinito `190`.
//! - `ATLAS_LETTORI`: connessioni di lettura, predefinite 4.
//! - `ATLAS_MAGAZZINO`: magazzino di scarico delle righe che non lo indicano, predefinito `00001`
//!   (Magazzino Centrale, quello della causale 003 dei BO: l'anagrafica ne ha 10, se ne usa uno).
//! - `ATLAS_LISTINO`: listino del prezzo proposto quando il cliente non ne ha uno (370 clienti su
//!   387), predefinito `0000001`. Non entra nel documento: `listino_cliente` resta del cliente.

use std::net::SocketAddr;
use std::path::PathBuf;

#[derive(Clone)]
pub struct Config {
    pub database: PathBuf,
    pub arca_ado: Option<String>,
    pub indirizzo: SocketAddr,
    pub lettori: usize,
    pub predefiniti: Predefiniti,
}

/// Valori che la maschera usa quando l'operatore non li batte.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Predefiniti {
    /// Utente Arca registrato nei documenti (`UserIns`).
    pub operatore: String,
    pub magazzino: String,
    pub listino: String,
}

impl Default for Predefiniti {
    fn default() -> Self {
        Self {
            operatore: OPERATORE_PREDEFINITO.to_owned(),
            magazzino: MAGAZZINO_PREDEFINITO.to_owned(),
            listino: LISTINO_PREDEFINITO.to_owned(),
        }
    }
}

impl std::fmt::Debug for Config {
    // Senza la stringa di connessione, che può contenere la password.
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Config")
            .field("database", &self.database)
            .field("arca", &self.arca_ado.is_some())
            .field("indirizzo", &self.indirizzo)
            .field("lettori", &self.lettori)
            .field("predefiniti", &self.predefiniti)
            .finish()
    }
}

pub const INDIRIZZO_PREDEFINITO: &str = "127.0.0.1:7878";
pub const OPERATORE_PREDEFINITO: &str = "190";
pub const LETTORI_PREDEFINITI: usize = 4;
pub const MAGAZZINO_PREDEFINITO: &str = "00001";
pub const LISTINO_PREDEFINITO: &str = "0000001";

#[derive(Debug, thiserror::Error)]
pub enum ErroreConfig {
    #[error("uso: atlas-server [DB] (oppure ATLAS_DB)")]
    Uso,
    #[error("{variabile}: {problema}")]
    Valore { variabile: &'static str, problema: String },
}

impl Config {
    /// Configurazione con i valori predefiniti, per le prove e per chi la compone a mano.
    pub fn nuova(database: impl Into<PathBuf>) -> Self {
        Self {
            database: database.into(),
            arca_ado: None,
            indirizzo: SocketAddr::from(([127, 0, 0, 1], 7878)),
            lettori: LETTORI_PREDEFINITI,
            predefiniti: Predefiniti::default(),
        }
    }

    pub fn da_ambiente(argomenti: impl IntoIterator<Item = String>) -> Result<Self, ErroreConfig> {
        let variabile = |nome: &str| std::env::var(nome).ok().filter(|v| !v.trim().is_empty());
        let database = argomenti.into_iter().next().or_else(|| variabile("ATLAS_DB")).ok_or(ErroreConfig::Uso)?;
        let indirizzo = variabile("ATLAS_INDIRIZZO")
            .unwrap_or_else(|| INDIRIZZO_PREDEFINITO.to_owned())
            .parse()
            .map_err(|e: std::net::AddrParseError| ErroreConfig::Valore {
                variabile: "ATLAS_INDIRIZZO",
                problema: e.to_string(),
            })?;
        let lettori = match variabile("ATLAS_LETTORI") {
            None => LETTORI_PREDEFINITI,
            Some(v) => v.parse().ok().filter(|n| (1..=64).contains(n)).ok_or(ErroreConfig::Valore {
                variabile: "ATLAS_LETTORI",
                problema: format!("{v}: atteso un numero da 1 a 64"),
            })?,
        };
        Ok(Self {
            database: database.into(),
            arca_ado: variabile("ATLAS_ARCA_ADO"),
            indirizzo,
            lettori,
            predefiniti: Predefiniti {
                operatore: variabile("ATLAS_OPERATORE").unwrap_or_else(|| OPERATORE_PREDEFINITO.to_owned()),
                magazzino: variabile("ATLAS_MAGAZZINO").unwrap_or_else(|| MAGAZZINO_PREDEFINITO.to_owned()),
                listino: variabile("ATLAS_LISTINO").unwrap_or_else(|| LISTINO_PREDEFINITO.to_owned()),
            },
        })
    }
}
