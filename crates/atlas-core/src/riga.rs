//! Riga merce: pesata, quantità netta, sconto, totale.

use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};

use crate::ErroreCalcolo;
use crate::aliquota::CodiceAliquota;
use crate::importo::{DECIMALI_FATTORE_SCONTO, Limitato, arrotonda, arrotonda_importo};

/// Pesata di riga del settore ortofrutta (`DORig.xColli`, `xLordo`, `xTara`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct Pesata {
    colli: Limitato,
    lordo: Limitato,
    tara_per_collo: Limitato,
}

impl Pesata {
    pub fn nuova(colli: Decimal, lordo: Decimal, tara_per_collo: Decimal) -> Result<Self, ErroreCalcolo> {
        Ok(Self {
            colli: Limitato::nuovo("colli", colli)?,
            lordo: Limitato::nuovo("lordo", lordo)?,
            tara_per_collo: Limitato::nuovo("tara", tara_per_collo)?,
        })
    }

    pub fn colli(&self) -> Decimal {
        self.colli.valore()
    }

    pub fn lordo(&self) -> Decimal {
        self.lordo.valore()
    }

    pub fn tara_per_collo(&self) -> Decimal {
        self.tara_per_collo.valore()
    }

    /// Quantità netta della riga (`DORig.Qta`).
    ///
    /// La tara è per collo. Senza peso lordo la merce è venduta a colli o a pezzi e la
    /// quantità coincide con i colli (personalizzazione `fedi_doc.xAssegnaPesoNetto`).
    /// Riproduce 359.000 righe su 359.052 del 2024-2026; le restanti hanno pesata vuota.
    pub fn netto(&self) -> Decimal {
        if self.lordo.is_zero() {
            self.colli.valore()
        } else {
            self.lordo.valore() - self.colli.valore() * self.tara_per_collo.valore()
        }
    }
}

/// Sconto di riga in cascata, nella notazione di Arca: `"10"`, `"10+5"`, `"-3"` (maggiorazione).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct Sconto {
    /// Quota sottratta al prezzo unitario (`DORig.FattoreScontoTotale`): 0,0199 per `"1+1"`.
    fattore: Decimal,
}

impl Sconto {
    pub const NESSUNO: Self = Self { fattore: Decimal::ZERO };
    const MASSIMO_TERMINI: u8 = 8;

    /// Composizione di sconto riga e sconto addizionale, come `DORig.ScontoTotale`.
    pub fn da_testi(riga: &str, addizionale: &str) -> Result<Self, ErroreCalcolo> {
        let mut residuo = Decimal::ONE;
        for testo in [riga, addizionale] {
            residuo *= Self::residuo(testo)?;
        }
        Ok(Self {
            fattore: arrotonda(Decimal::ONE - residuo, DECIMALI_FATTORE_SCONTO),
        })
    }

    pub fn fattore(&self) -> Decimal {
        self.fattore
    }

    fn residuo(testo: &str) -> Result<Decimal, ErroreCalcolo> {
        let testo = testo.trim();
        let mut residuo = Decimal::ONE;
        if testo.is_empty() {
            return Ok(residuo);
        }
        let non_valido = || ErroreCalcolo::ScontoNonValido(testo.to_owned());
        let mut resto = testo;
        let mut termini = 0_u8;
        while !resto.is_empty() {
            termini += 1;
            if termini > Self::MASSIMO_TERMINI {
                return Err(non_valido());
            }
            let (segno, dopo) = match resto.as_bytes().first() {
                Some(b'+') => (Decimal::ONE, resto.get(1..).ok_or_else(non_valido)?),
                Some(b'-') => (Decimal::NEGATIVE_ONE, resto.get(1..).ok_or_else(non_valido)?),
                _ => (Decimal::ONE, resto),
            };
            let fine = dopo.find(['+', '-']).unwrap_or(dopo.len());
            let (numero, coda) = dopo.split_at(fine);
            let percentuale: Decimal = numero.trim().replace(',', ".").parse().map_err(|_| non_valido())?;
            if percentuale.is_sign_negative() || percentuale > Decimal::ONE_HUNDRED {
                return Err(non_valido());
            }
            residuo *= Decimal::ONE - segno * percentuale / Decimal::ONE_HUNDRED;
            resto = coda;
        }
        Ok(residuo)
    }
}

/// Riga merce di un documento, nelle grandezze che determinano gli importi.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RigaMerce {
    pub quantita: Limitato,
    pub prezzo_unitario: Limitato,
    pub prezzo_addizionale: Limitato,
    pub sconto: Sconto,
    pub aliquota: Option<CodiceAliquota>,
}

impl RigaMerce {
    /// Totale riga (`DORig.PrezzoTotaleV`): `Qta × (Prezzo × (1 − sconto) + addizionale)`,
    /// arrotondato a metà lontano da zero sui decimali dell'importo.
    pub fn totale(&self) -> Decimal {
        let unitario_netto = self.prezzo_unitario.valore() * (Decimal::ONE - self.sconto.fattore())
            + self.prezzo_addizionale.valore();
        arrotonda_importo(self.quantita.valore() * unitario_netto)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rust_decimal_macros::dec;

    fn pesata(colli: Decimal, lordo: Decimal, tara: Decimal) -> Pesata {
        Pesata::nuova(colli, lordo, tara).unwrap()
    }

    #[test]
    fn netto_tara_per_collo() {
        assert_eq!(pesata(dec!(2), dec!(10.84), dec!(0.30)).netto(), dec!(10.24));
        assert_eq!(pesata(dec!(20), dec!(84), dec!(0.30)).netto(), dec!(78.00));
        assert_eq!(pesata(dec!(1), dec!(5.46), dec!(0.30)).netto(), dec!(5.16));
    }

    #[test]
    fn netto_senza_colli_ignora_la_tara() {
        assert_eq!(pesata(dec!(0), dec!(5.24), dec!(0.40)).netto(), dec!(5.24));
    }

    #[test]
    fn netto_senza_lordo_vale_i_colli() {
        assert_eq!(pesata(dec!(8), dec!(0), dec!(0)).netto(), dec!(8));
        assert_eq!(pesata(dec!(3), dec!(0), dec!(0.30)).netto(), dec!(3));
    }

    #[test]
    fn sconti_in_cascata() {
        assert_eq!(Sconto::da_testi("", "").unwrap().fattore(), dec!(0));
        assert_eq!(Sconto::da_testi("1", "1").unwrap().fattore(), dec!(0.0199));
        assert_eq!(Sconto::da_testi("10+5", "").unwrap().fattore(), dec!(0.145));
        assert_eq!(Sconto::da_testi("10", "-5").unwrap().fattore(), dec!(0.055));
        assert_eq!(Sconto::da_testi("12,5", "").unwrap().fattore(), dec!(0.125));
    }

    #[test]
    fn sconti_non_validi() {
        for testo in ["abc", "10+", "+", "150", "10++5"] {
            assert!(Sconto::da_testi(testo, "").is_err(), "{testo}");
        }
    }

    fn riga(qta: Decimal, prezzo: Decimal, sconto: Sconto) -> RigaMerce {
        RigaMerce {
            quantita: Limitato::nuovo("qta", qta).unwrap(),
            prezzo_unitario: Limitato::nuovo("prezzo", prezzo).unwrap(),
            prezzo_addizionale: Limitato::ZERO,
            sconto,
            aliquota: Some(CodiceAliquota::nuovo("04")),
        }
    }

    #[test]
    fn totale_riga_come_arca() {
        assert_eq!(riga(dec!(5.16), dec!(1.8), Sconto::NESSUNO).totale(), dec!(9.29));
        assert_eq!(riga(dec!(6.95), dec!(2.95), Sconto::NESSUNO).totale(), dec!(20.50));
        assert_eq!(riga(dec!(4.7), dec!(2.45), Sconto::NESSUNO).totale(), dec!(11.52));
        assert_eq!(riga(dec!(10.24), dec!(3.4), Sconto::NESSUNO).totale(), dec!(34.82));
        let sconto = Sconto::da_testi("1", "1").unwrap();
        assert_eq!(riga(dec!(1), dec!(1.2), sconto).totale(), dec!(1.18));
    }
}
