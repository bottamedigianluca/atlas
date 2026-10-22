//! Aritmetica decimale a virgola fissa e arrotondamenti.

use rust_decimal::{Decimal, RoundingStrategy};
use serde::{Deserialize, Serialize};

use crate::ErroreCalcolo;

/// Decimali degli importi in euro (`DOTes.Decimali`, 2 su tutti i 60.502 documenti).
pub const DECIMALI_IMPORTO: u32 = 2;

/// Decimali del prezzo unitario a video e in stampa (`DOTes.DecimaliPrzUn`).
pub const DECIMALI_PREZZO: u32 = 3;

/// Precisione del fattore di sconto (`DORig.FattoreScontoTotale numeric(10,9)`).
pub const DECIMALI_FATTORE_SCONTO: u32 = 9;

/// Arrotondamento a metà lontano da zero.
///
/// È la semantica di `ROUND()` di SQL Server e quella registrata da Arca: sui 13.694 totali
/// riga 2024-2026 in cui metà-pari e metà-lontano divergono, Arca ha sempre usato la seconda.
pub fn arrotonda(valore: Decimal, decimali: u32) -> Decimal {
    valore.round_dp_with_strategy(decimali, RoundingStrategy::MidpointAwayFromZero)
}

pub fn arrotonda_importo(valore: Decimal) -> Decimal {
    arrotonda(valore, DECIMALI_IMPORTO)
}

/// Decimale con modulo limitato a `10^9`.
///
/// Prodotti e somme di valori limitati restano molti ordini di grandezza sotto la capacità
/// di `Decimal` (circa `7.9 × 10^28`): il motore non può andare in overflow.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Default, Serialize, Deserialize)]
#[serde(try_from = "Decimal", into = "Decimal")]
pub struct Limitato(Decimal);

impl Limitato {
    pub const LIMITE: Decimal = Decimal::from_parts(1_000_000_000, 0, 0, false, 0);
    pub const ZERO: Self = Self(Decimal::ZERO);

    pub fn nuovo(campo: &'static str, valore: Decimal) -> Result<Self, ErroreCalcolo> {
        if valore.abs() >= Self::LIMITE {
            return Err(ErroreCalcolo::FuoriIntervallo {
                campo,
                valore,
                limite: Self::LIMITE,
            });
        }
        Ok(Self(valore))
    }

    pub fn valore(self) -> Decimal {
        self.0
    }

    pub fn is_zero(self) -> bool {
        self.0.is_zero()
    }
}

impl TryFrom<Decimal> for Limitato {
    type Error = ErroreCalcolo;

    fn try_from(valore: Decimal) -> Result<Self, Self::Error> {
        Self::nuovo("valore", valore)
    }
}

impl From<Limitato> for Decimal {
    fn from(valore: Limitato) -> Self {
        valore.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rust_decimal_macros::dec;

    #[test]
    fn arrotondamento_meta_lontano_da_zero() {
        assert_eq!(arrotonda_importo(dec!(11.515)), dec!(11.52));
        assert_eq!(arrotonda_importo(dec!(18.125)), dec!(18.13));
        assert_eq!(arrotonda_importo(dec!(-18.125)), dec!(-18.13));
        assert_eq!(arrotonda_importo(dec!(9.288)), dec!(9.29));
        assert_eq!(arrotonda_importo(dec!(20.5025)), dec!(20.50));
    }

    #[test]
    fn limitato_rifiuta_valori_fuori_scala() {
        assert!(Limitato::nuovo("qta", dec!(999_999_999.99)).is_ok());
        assert!(Limitato::nuovo("qta", dec!(1_000_000_000)).is_err());
        assert!(Limitato::nuovo("qta", dec!(-1_000_000_000)).is_err());
    }
}
