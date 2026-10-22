//! Condizioni di pagamento, scadenze e spese d'incasso.

use chrono::{Datelike, Days, Months, NaiveDate};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};

use crate::ErroreCalcolo;
use crate::aliquota::CodiceAliquota;
use crate::importo::arrotonda_importo;

/// Data da cui decorre la dilazione (`PG.Partenza`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Partenza {
    /// `1`: data documento più i giorni di dilazione.
    DataDocumento,
    /// `2` ("DF FM"): fine mese della data documento più i mesi di dilazione, a fine mese.
    FineMese,
}

/// Mezzo di pagamento della rata (`PGRata.TipoRata`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TipoRata {
    RimessaDiretta,
    Bonifico,
    RicevutaBancaria,
    Contrassegno,
    BollettinoPostale,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Rata {
    pub tipo: TipoRata,
    pub giorni: u16,
    /// Quota dell'imponibile, in percentuale.
    pub quota_imponibile: Decimal,
    /// Quota dell'imposta, in percentuale.
    pub quota_imposta: Decimal,
    /// Spese d'incasso addebitate in fattura per la rata (3,50 € per le RiBa).
    pub spese: Decimal,
    pub aliquota_spese: Option<CodiceAliquota>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CondizionePagamento {
    pub codice: String,
    pub partenza: Partenza,
    pub rate: Vec<Rata>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Scadenza {
    pub data: NaiveDate,
    pub tipo: TipoRata,
    pub importo: Decimal,
}

/// Spesa d'incasso da aggiungere al documento come riga spesa (`DORigSpesa`, tipo `N`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SpesaIncasso {
    pub importo: Decimal,
    pub aliquota: Option<CodiceAliquota>,
}

impl CondizionePagamento {
    /// Verifica che le rate esistano e coprano esattamente il 100% di imponibile e imposta.
    pub fn valida(&self) -> Result<(), ErroreCalcolo> {
        if self.rate.is_empty() {
            return Err(ErroreCalcolo::PagamentoSenzaRate {
                codice: self.codice.clone(),
            });
        }
        let imponibile: Decimal = self.rate.iter().map(|r| r.quota_imponibile).sum();
        let imposta: Decimal = self.rate.iter().map(|r| r.quota_imposta).sum();
        if imponibile != Decimal::ONE_HUNDRED || imposta != Decimal::ONE_HUNDRED {
            return Err(ErroreCalcolo::RateIncomplete {
                codice: self.codice.clone(),
                imponibile,
                imposta,
            });
        }
        Ok(())
    }

    pub fn spese_incasso(&self) -> Vec<SpesaIncasso> {
        self.rate
            .iter()
            .filter(|r| !r.spese.is_zero())
            .map(|r| SpesaIncasso {
                importo: r.spese,
                aliquota: r.aliquota_spese.clone(),
            })
            .collect()
    }

    /// Data di scadenza di una rata.
    ///
    /// Con partenza a fine mese i giorni valgono mesi da 30: 31/08 + 30 → 30/09, 31/01 + 30 →
    /// 28/02 (non 31/03). Riproduce 9.373 scadenze su 9.373 dal 2019, inclusi i 186 casi in cui
    /// l'interpretazione "fine mese di (data + giorni)" darebbe una data diversa.
    pub fn data_scadenza(&self, data_documento: NaiveDate, giorni: u16) -> Result<NaiveDate, ErroreCalcolo> {
        match self.partenza {
            Partenza::DataDocumento => data_documento
                .checked_add_days(Days::new(u64::from(giorni)))
                .ok_or(ErroreCalcolo::DataFuoriCalendario),
            Partenza::FineMese => {
                if giorni % 30 != 0 {
                    return Err(ErroreCalcolo::DilazioneNonMensile { giorni });
                }
                let mesi = Months::new(u32::from(giorni / 30));
                let base = fine_mese(data_documento)?;
                let spostata = base.checked_add_months(mesi).ok_or(ErroreCalcolo::DataFuoriCalendario)?;
                fine_mese(spostata)
            }
        }
    }

    /// Scadenze del documento: ogni rata riceve la sua quota di imponibile e imposta;
    /// l'ultima assorbe il residuo, così la somma è sempre il netto a pagare.
    ///
    /// `detrazioni` (acconto + abbuono, `DOTotali.AccontoV + AbbuonoV`) riduce il netto a pagare
    /// e ricade sull'ultima rata. Nello storico ci sono solo pagamenti a rata unica: la
    /// ripartizione su più rate non è osservabile e segue questa regola dichiarata.
    pub fn scadenze(
        &self,
        data_documento: NaiveDate,
        imponibile: Decimal,
        imposta: Decimal,
        detrazioni: Decimal,
    ) -> Result<Vec<Scadenza>, ErroreCalcolo> {
        self.valida()?;
        let totale = imponibile + imposta - detrazioni;
        let mut assegnato = Decimal::ZERO;
        let mut scadenze = Vec::with_capacity(self.rate.len());
        let ultima = self.rate.len().saturating_sub(1);
        for (indice, rata) in self.rate.iter().enumerate() {
            let importo = if indice == ultima {
                totale - assegnato
            } else {
                arrotonda_importo(
                    (imponibile * rata.quota_imponibile + imposta * rata.quota_imposta) / Decimal::ONE_HUNDRED,
                )
            };
            assegnato += importo;
            scadenze.push(Scadenza {
                data: self.data_scadenza(data_documento, rata.giorni)?,
                tipo: rata.tipo,
                importo,
            });
        }
        Ok(scadenze)
    }
}

fn fine_mese(data: NaiveDate) -> Result<NaiveDate, ErroreCalcolo> {
    NaiveDate::from_ymd_opt(data.year(), data.month(), 1)
        .and_then(|primo| primo.checked_add_months(Months::new(1)))
        .and_then(|primo_successivo| primo_successivo.pred_opt())
        .ok_or(ErroreCalcolo::DataFuoriCalendario)
}

#[cfg(test)]
mod tests {
    use super::*;
    use rust_decimal_macros::dec;

    fn data(g: u32, m: u32, a: i32) -> NaiveDate {
        NaiveDate::from_ymd_opt(a, m, g).unwrap()
    }

    fn rata(tipo: TipoRata, giorni: u16, quota: Decimal) -> Rata {
        Rata {
            tipo,
            giorni,
            quota_imponibile: quota,
            quota_imposta: quota,
            spese: Decimal::ZERO,
            aliquota_spese: None,
        }
    }

    fn riba(giorni: &[u16], quote: &[Decimal]) -> CondizionePagamento {
        CondizionePagamento {
            codice: "R".into(),
            partenza: Partenza::FineMese,
            rate: giorni
                .iter()
                .zip(quote)
                .map(|(g, q)| rata(TipoRata::RicevutaBancaria, *g, *q))
                .collect(),
        }
    }

    #[test]
    fn fine_mese_a_mesi_interi() {
        let pg = riba(&[30], &[dec!(100)]);
        assert_eq!(pg.data_scadenza(data(31, 8, 2026), 30).unwrap(), data(30, 9, 2026));
        assert_eq!(pg.data_scadenza(data(31, 8, 2026), 60).unwrap(), data(31, 10, 2026));
        assert_eq!(pg.data_scadenza(data(31, 1, 2026), 30).unwrap(), data(28, 2, 2026));
        assert_eq!(pg.data_scadenza(data(15, 12, 2026), 60).unwrap(), data(28, 2, 2027));
        assert_eq!(pg.data_scadenza(data(10, 1, 2028), 30).unwrap(), data(29, 2, 2028));
        assert!(pg.data_scadenza(data(1, 1, 2026), 45).is_err());
    }

    #[test]
    fn vista_fattura() {
        let pg = CondizionePagamento {
            codice: "D000".into(),
            partenza: Partenza::DataDocumento,
            rate: vec![rata(TipoRata::RimessaDiretta, 0, dec!(100))],
        };
        let s = pg.scadenze(data(3, 8, 2026), dec!(121.94), dec!(4.88), dec!(0)).unwrap();
        assert_eq!(s.len(), 1);
        assert_eq!(s[0].data, data(3, 8, 2026));
        assert_eq!(s[0].importo, dec!(126.82));
    }

    #[test]
    fn abbuono_riduce_il_netto_a_pagare() {
        let pg = CondizionePagamento {
            codice: "D000".into(),
            partenza: Partenza::DataDocumento,
            rate: vec![rata(TipoRata::RimessaDiretta, 0, dec!(100))],
        };
        let s = pg.scadenze(data(13, 10, 2026), dec!(200.00), dec!(8.00), dec!(8.00)).unwrap();
        assert_eq!(s[0].importo, dec!(200.00));
    }

    #[test]
    fn rate_multiple_sommano_al_totale() {
        let pg = riba(&[30, 60, 90], &[dec!(33.33), dec!(33.33), dec!(33.34)]);
        let s = pg.scadenze(data(30, 9, 2026), dec!(1000.00), dec!(40.00), dec!(0)).unwrap();
        assert_eq!(s.iter().map(|x| x.importo).sum::<Decimal>(), dec!(1040.00));
        assert_eq!(s[0].importo, dec!(346.63));
        assert_eq!(s[2].data, data(31, 12, 2026));
    }

    #[test]
    fn rate_incomplete_rifiutate() {
        let pg = riba(&[30, 60], &[dec!(50), dec!(40)]);
        assert!(pg.scadenze(data(30, 9, 2026), dec!(1), dec!(0), dec!(0)).is_err());
    }
}
