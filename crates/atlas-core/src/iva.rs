//! Castelletto IVA e totali documento.

use std::collections::BTreeMap;

use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};

use crate::ErroreCalcolo;
use crate::aliquota::{CodiceAliquota, TabellaAliquote};
use crate::importo::arrotonda_importo;

/// Riga del castelletto (`DOIva`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RigaIva {
    pub aliquota: CodiceAliquota,
    pub percentuale: Decimal,
    pub imponibile: Decimal,
    pub imposta: Decimal,
}

/// Castelletto IVA e totali del documento (`DOIva` e `DOTotali`).
#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct Castelletto {
    pub righe: Vec<RigaIva>,
    pub totale_imponibile: Decimal,
    pub totale_imposta: Decimal,
    pub totale_documento: Decimal,
}

impl Castelletto {
    /// Calcola il castelletto dagli importi imponibili del documento (righe merce e spese).
    ///
    /// Per ogni aliquota: imponibile = somma degli importi, arrotondata; imposta = imponibile ×
    /// percentuale, arrotondata a metà lontano da zero. Le aliquote con imponibile nullo non
    /// compaiono. Totale documento = Σ imponibili + Σ imposte. Riproduce DOIva e DOTotali di
    /// 14.475 documenti su 14.475 (BO, FA, FT, NC 2025-2026).
    pub fn calcola<'a, I>(importi: I, tabella: &TabellaAliquote) -> Result<Self, ErroreCalcolo>
    where
        I: IntoIterator<Item = (&'a CodiceAliquota, Decimal)>,
    {
        let mut per_aliquota: BTreeMap<&CodiceAliquota, Decimal> = BTreeMap::new();
        for (aliquota, importo) in importi {
            *per_aliquota.entry(aliquota).or_default() += importo;
        }

        let mut castelletto = Self::default();
        for (aliquota, somma) in per_aliquota {
            let imponibile = arrotonda_importo(somma);
            if imponibile.is_zero() {
                continue;
            }
            let percentuale = tabella.percentuale(aliquota)?;
            let imposta = arrotonda_importo(imponibile * percentuale / Decimal::ONE_HUNDRED);
            castelletto.totale_imponibile += imponibile;
            castelletto.totale_imposta += imposta;
            castelletto.righe.push(RigaIva {
                aliquota: aliquota.clone(),
                percentuale,
                imponibile,
                imposta,
            });
        }
        castelletto.totale_documento = castelletto.totale_imponibile + castelletto.totale_imposta;
        Ok(castelletto)
    }

    /// Imposta che il cliente paga a noi. In scissione dei pagamenti (art. 17-ter DPR 633/72,
    /// `DOTes.IvaSplit`) l'ente la versa direttamente all'Erario.
    pub fn imposta_a_carico_cliente(&self, scissione_pagamenti: bool) -> Decimal {
        if scissione_pagamenti {
            Decimal::ZERO
        } else {
            self.totale_imposta
        }
    }

    /// Netto a pagare (`DOTotali.TotaPagareV`): totale, meno l'imposta in scissione dei
    /// pagamenti, meno acconto e abbuono. Riproduce 14.475 documenti su 14.475 (2025-2026),
    /// di cui 33 in scissione dei pagamenti.
    pub fn netto_a_pagare(&self, scissione_pagamenti: bool, detrazioni: Decimal) -> Decimal {
        self.totale_imponibile + self.imposta_a_carico_cliente(scissione_pagamenti) - detrazioni
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rust_decimal_macros::dec;

    fn tabella() -> TabellaAliquote {
        [("04", dec!(4)), ("05", dec!(5)), ("10", dec!(10)), ("22", dec!(22)), ("E10", dec!(0))]
            .into_iter()
            .map(|(c, p)| (CodiceAliquota::nuovo(c), p))
            .collect()
    }

    #[test]
    fn imposta_calcolata_sul_totale_per_aliquota() {
        let a04 = CodiceAliquota::nuovo("04");
        let a22 = CodiceAliquota::nuovo("22");
        let importi = [(&a04, dec!(1374.63)), (&a22, dec!(1.80)), (&a04, dec!(0))];
        let c = Castelletto::calcola(importi, &tabella()).unwrap();
        assert_eq!(c.righe.len(), 2);
        assert_eq!(c.righe[0].imposta, dec!(54.99));
        assert_eq!(c.righe[1].imposta, dec!(0.40));
        assert_eq!(c.totale_documento, dec!(1376.43) + dec!(55.39));
    }

    #[test]
    fn imposta_non_e_la_somma_delle_imposte_di_riga() {
        let a04 = CodiceAliquota::nuovo("04");
        let importi = [(&a04, dec!(0.13)), (&a04, dec!(0.13)), (&a04, dec!(0.13))];
        let c = Castelletto::calcola(importi, &tabella()).unwrap();
        assert_eq!(c.totale_imposta, dec!(0.02));
    }

    #[test]
    fn aliquote_annullate_non_compaiono() {
        let a10 = CodiceAliquota::nuovo("10");
        let importi = [(&a10, dec!(12.50)), (&a10, dec!(-12.50))];
        let c = Castelletto::calcola(importi, &tabella()).unwrap();
        assert!(c.righe.is_empty());
        assert_eq!(c.totale_documento, dec!(0));
    }

    #[test]
    fn scissione_dei_pagamenti_esclude_l_imposta() {
        let a04 = CodiceAliquota::nuovo("04");
        let c = Castelletto::calcola([(&a04, dec!(200.00))], &tabella()).unwrap();
        assert_eq!(c.totale_documento, dec!(208.00));
        assert_eq!(c.netto_a_pagare(true, dec!(0)), dec!(200.00));
        assert_eq!(c.netto_a_pagare(false, dec!(0)), dec!(208.00));
        assert_eq!(c.netto_a_pagare(false, dec!(8.00)), dec!(200.00));
    }

    #[test]
    fn aliquota_sconosciuta_e_un_errore() {
        let x = CodiceAliquota::nuovo("99");
        assert!(Castelletto::calcola([(&x, dec!(1))], &tabella()).is_err());
    }
}
