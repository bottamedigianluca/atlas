//! Codici e percentuali IVA.

use std::collections::BTreeMap;
use std::fmt;

use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};

use crate::ErroreCalcolo;

/// Codice aliquota IVA (`Aliquota.Cd_Aliquota`), senza spazi di riempimento.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct CodiceAliquota(String);

impl CodiceAliquota {
    pub fn nuovo(codice: &str) -> Self {
        Self(codice.trim().to_owned())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for CodiceAliquota {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

/// Tabella delle aliquote in vigore, indicizzata per codice.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct TabellaAliquote {
    percentuali: BTreeMap<CodiceAliquota, Decimal>,
}

impl TabellaAliquote {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn inserisci(&mut self, codice: CodiceAliquota, percentuale: Decimal) {
        self.percentuali.insert(codice, percentuale);
    }

    pub fn percentuale(&self, codice: &CodiceAliquota) -> Result<Decimal, ErroreCalcolo> {
        self.percentuali
            .get(codice)
            .copied()
            .ok_or_else(|| ErroreCalcolo::AliquotaSconosciuta(codice.to_string()))
    }
}

impl FromIterator<(CodiceAliquota, Decimal)> for TabellaAliquote {
    fn from_iter<I: IntoIterator<Item = (CodiceAliquota, Decimal)>>(iter: I) -> Self {
        Self {
            percentuali: iter.into_iter().collect(),
        }
    }
}
