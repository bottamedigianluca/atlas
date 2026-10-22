//! Tipi documento, sezionali e numerazione come la fa Arca.
//!
//! Le funzioni di Arca che numerano (`asp_NumDoc_Next`, `UnusedCodes_DoTes`) sono cifrate: la
//! regola è ricavata a scatola nera sul clone e confrontata con le funzioni stesse (vedi
//! [`Numeri`]).

use std::collections::BTreeMap;
use std::fmt;
use std::str::FromStr;

use chrono::NaiveDate;
use serde::{Deserialize, Serialize};

/// Tipi documento del ciclo attivo in uso (`DO.Cd_Do`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub enum TipoDocumento {
    /// Documento di trasporto (DDT) di vendita.
    BollaVendita,
    /// Fattura accompagnatoria: vale anche come DDT e scarica il magazzino.
    FatturaImmediata,
    /// Fattura differita di fine mese, generata dai DDT.
    FatturaDifferita,
    NotaAccredito,
}

/// Registro di numerazione progressiva annuale (`CN`). In Arca lo condividono tutti i tipi
/// documento con lo stesso `DO.Cd_CN`, anche quelli che ATLAS non gestisce (i 6 `BF` del
/// 2018-2019 sono sul sezionale delle bolle).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub enum Sezionale {
    Bolle,
    /// Unico per FA, FT e NC: dal 2023 a oggi nessun buco e nessun doppione.
    Fatture,
}

impl Sezionale {
    pub const TUTTI: [Self; 2] = [Self::Bolle, Self::Fatture];

    /// `CN.Cd_CN` di Arca.
    pub fn codice(self) -> &'static str {
        match self {
            Self::Bolle => "D00",
            Self::Fatture => "001",
        }
    }

    /// `CN.NextNumAllaData`: 0 per `D00`, 1 per `001`.
    pub fn regola(self) -> Regola {
        match self {
            Self::Bolle => Regola::Progressiva,
            Self::Fatture => Regola::AllaData,
        }
    }
}

/// Come Arca sceglie il numero di un nuovo documento (`CN.NextNumAllaData`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum Regola {
    /// Il successivo al più alto dell'esercizio, qualunque sia la data.
    Progressiva,
    /// Il successivo al più alto fra i documenti con data fino a quella del nuovo. Se è già di
    /// un documento con data successiva il numero non c'è: i numeri seguono l'ordine delle date.
    AllaData,
}

/// Numero più alto: `DOTes.NumeroDoc` ha sei cifre prima del suffisso.
pub const NUMERO_MASSIMO: u32 = 999_999;

#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum NumeroNonValido {
    #[error("numero {0} fuori dall'intervallo 1-{NUMERO_MASSIMO}")]
    FuoriIntervallo(u32),
    #[error("il numero {numero} è già del documento del {}", data.format("%d/%m/%Y"))]
    Occupato { numero: u32, data: NaiveDate },
    #[error("il numero {numero} si può usare solo con data {}", intervallo(*dal, *al))]
    FuoriData {
        numero: u32,
        dal: Option<NaiveDate>,
        al: Option<NaiveDate>,
    },
}

fn intervallo(dal: Option<NaiveDate>, al: Option<NaiveDate>) -> String {
    match (dal, al) {
        (Some(dal), Some(al)) => format!("dal {} al {}", dal.format("%d/%m/%Y"), al.format("%d/%m/%Y")),
        (Some(dal), None) => format!("dal {} in poi", dal.format("%d/%m/%Y")),
        (None, Some(al)) => format!("fino al {}", al.format("%d/%m/%Y")),
        (None, None) => "qualsiasi".to_owned(),
    }
}

/// Numeri occupati di un sezionale in un esercizio, con la data dei documenti che li hanno.
///
/// Riproduce le funzioni cifrate di Arca, confrontate sul clone:
/// - [`Numeri::prossimo`] come `asp_NumDoc_Next`: per ogni giorno del 2026, 365/365 numeri
///   uguali su `D00`; su `001` 72/72 numeri uguali e 293/293 rifiuti (errore 900308) sullo
///   stesso numero, già di un documento con data successiva;
/// - [`Numeri::liberi`] come `UnusedCodes_DoTes`: 1.157/1.157 righe uguali su tutti gli
///   esercizi 2018-2026 dei due sezionali, intervalli di date compresi.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Numeri {
    /// Numero → data più vecchia e più recente dei documenti che lo hanno (due documenti con lo
    /// stesso numero intero: `1` e `1/PA` del 2018).
    occupati: BTreeMap<u32, (NaiveDate, NaiveDate)>,
}

/// Numeri liberi consecutivi fra due documenti, con le date entro cui usarli: quella del
/// documento precedente e quella del successivo.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Liberi {
    pub dal: u32,
    pub al: u32,
    /// Senza documento precedente il buco è all'inizio dell'esercizio.
    pub data_dal: Option<NaiveDate>,
    pub data_al: NaiveDate,
}

impl Numeri {
    pub fn aggiungi(&mut self, numero: u32, data: NaiveDate) {
        self.occupati
            .entry(numero)
            .and_modify(|(prima, ultima)| {
                *prima = (*prima).min(data);
                *ultima = (*ultima).max(data);
            })
            .or_insert((data, data));
    }

    /// Aggiunge i numeri di un'altra fonte (per esempio quelli letti da Arca).
    pub fn unisci(&mut self, altri: &Self) {
        for (&numero, &(prima, ultima)) in &altri.occupati {
            self.aggiungi(numero, prima);
            self.aggiungi(numero, ultima);
        }
    }

    pub fn contiene(&self, numero: u32) -> bool {
        self.occupati.contains_key(&numero)
    }

    /// I numeri occupati, in ordine.
    pub fn numeri(&self) -> impl Iterator<Item = u32> + '_ {
        self.occupati.keys().copied()
    }

    /// Data del documento più recente: da lì vale il prossimo numero.
    pub fn ultima_data(&self) -> Option<NaiveDate> {
        self.occupati.values().map(|&(_, ultima)| ultima).max()
    }

    /// Il numero che Arca assegnerebbe a un nuovo documento con questa data.
    pub fn prossimo(&self, regola: Regola, data: NaiveDate) -> Result<u32, NumeroNonValido> {
        let ultimo = match regola {
            Regola::Progressiva => self.occupati.keys().next_back().copied(),
            Regola::AllaData => self
                .occupati
                .iter()
                .rev()
                .find(|(_, (prima, _))| *prima <= data)
                .map(|(&numero, _)| numero),
        };
        let numero = ultimo.map_or(1, |n| n.saturating_add(1));
        if numero > NUMERO_MASSIMO {
            return Err(NumeroNonValido::FuoriIntervallo(numero));
        }
        match self.occupati.get(&numero) {
            Some(&(prima, _)) => Err(NumeroNonValido::Occupato { numero, data: prima }),
            None => Ok(numero),
        }
    }

    /// Un numero scelto per un nuovo documento: libero e, con [`Regola::AllaData`], fra la
    /// data del documento precedente e quella del successivo (l'intervallo di [`Numeri::liberi`]).
    pub fn verifica(&self, regola: Regola, numero: u32, data: NaiveDate) -> Result<(), NumeroNonValido> {
        if !(1..=NUMERO_MASSIMO).contains(&numero) {
            return Err(NumeroNonValido::FuoriIntervallo(numero));
        }
        if let Some(&(prima, _)) = self.occupati.get(&numero) {
            return Err(NumeroNonValido::Occupato { numero, data: prima });
        }
        if regola == Regola::AllaData {
            let dal = self.occupati.range(..numero).next_back().map(|(_, &(_, ultima))| ultima);
            let al = self.occupati.range(numero..).next().map(|(_, &(prima, _))| prima);
            if dal.is_some_and(|dal| data < dal) || al.is_some_and(|al| data > al) {
                return Err(NumeroNonValido::FuoriData { numero, dal, al });
            }
        }
        Ok(())
    }

    /// Buchi della numerazione, in ordine: i numeri mancanti sotto il più alto occupato.
    pub fn liberi(&self) -> Vec<Liberi> {
        let mut liberi = Vec::new();
        let mut precedente: Option<(u32, NaiveDate)> = None;
        for (&numero, &(prima, ultima)) in &self.occupati {
            let dal = precedente.map_or(1, |(n, _)| n.saturating_add(1));
            if numero > dal {
                liberi.push(Liberi {
                    dal,
                    al: numero - 1,
                    data_dal: precedente.map(|(_, data)| data),
                    data_al: prima,
                });
            }
            precedente = Some((numero, ultima));
        }
        liberi
    }
}

impl Extend<(u32, NaiveDate)> for Numeri {
    fn extend<I: IntoIterator<Item = (u32, NaiveDate)>>(&mut self, numeri: I) {
        for (numero, data) in numeri {
            self.aggiungi(numero, data);
        }
    }
}

impl FromIterator<(u32, NaiveDate)> for Numeri {
    fn from_iter<I: IntoIterator<Item = (u32, NaiveDate)>>(numeri: I) -> Self {
        let mut tutti = Self::default();
        tutti.extend(numeri);
        tutti
    }
}

impl TipoDocumento {
    pub const TUTTI: [Self; 4] = [
        Self::BollaVendita,
        Self::FatturaImmediata,
        Self::FatturaDifferita,
        Self::NotaAccredito,
    ];

    pub fn codice(self) -> &'static str {
        match self {
            Self::BollaVendita => "BO",
            Self::FatturaImmediata => "FA",
            Self::FatturaDifferita => "FT",
            Self::NotaAccredito => "NC",
        }
    }

    pub const fn sezionale(self) -> Sezionale {
        match self {
            Self::BollaVendita => Sezionale::Bolle,
            Self::FatturaImmediata | Self::FatturaDifferita | Self::NotaAccredito => Sezionale::Fatture,
        }
    }

    /// Il documento movimenta il magazzino. La fattura differita no: lo hanno già fatto i DDT.
    pub fn movimenta_magazzino(self) -> bool {
        matches!(self, Self::BollaVendita | Self::FatturaImmediata)
    }

    /// Segno degli importi in scadenzario e contabilità (`DOTes.SegnoDocumento`).
    pub fn segno(self) -> rust_decimal::Decimal {
        match self {
            Self::NotaAccredito => rust_decimal::Decimal::NEGATIVE_ONE,
            _ => rust_decimal::Decimal::ONE,
        }
    }

    /// Il documento genera registrazione contabile, scadenze e fattura elettronica.
    pub fn fiscale(self) -> bool {
        self.sezionale() == Sezionale::Fatture
    }
}

impl fmt::Display for TipoDocumento {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.codice())
    }
}

#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
#[error("tipo documento non gestito: {0}")]
pub struct TipoNonGestito(pub String);

impl FromStr for TipoDocumento {
    type Err = TipoNonGestito;

    fn from_str(codice: &str) -> Result<Self, Self::Err> {
        let codice = codice.trim();
        Self::TUTTI
            .into_iter()
            .find(|t| t.codice() == codice)
            .ok_or_else(|| TipoNonGestito(codice.to_owned()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn codici_arca() {
        for tipo in TipoDocumento::TUTTI {
            assert_eq!(tipo.codice().parse::<TipoDocumento>().unwrap(), tipo);
        }
        assert_eq!("BO ".parse::<TipoDocumento>().unwrap(), TipoDocumento::BollaVendita);
        assert!("OC".parse::<TipoDocumento>().is_err());
    }

    #[test]
    fn fatture_condividono_il_sezionale() {
        assert_eq!(TipoDocumento::FatturaImmediata.sezionale(), Sezionale::Fatture);
        assert_eq!(TipoDocumento::NotaAccredito.sezionale(), Sezionale::Fatture);
        assert_eq!(TipoDocumento::BollaVendita.sezionale(), Sezionale::Bolle);
    }

    fn g(giorno: u32, mese: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(2026, mese, giorno).unwrap()
    }

    /// FA/FT di inizio 2026 sul clone: 1-3 del 02/01, 4 del 05/01, 5 del 10/01.
    fn fatture_gennaio() -> Numeri {
        [(1, g(2, 1)), (2, g(2, 1)), (3, g(2, 1)), (4, g(5, 1)), (5, g(10, 1))]
            .into_iter()
            .collect()
    }

    #[test]
    fn progressiva_ignora_la_data_e_i_buchi() {
        // BO 2026 sul clone: 5446 e 5448 del 21/10, 5458 del 22/10, 5447 libero.
        let bolle: Numeri = [(5446, g(21, 10)), (5448, g(21, 10)), (5458, g(22, 10))].into_iter().collect();
        assert_eq!(bolle.prossimo(Regola::Progressiva, g(15, 1)), Ok(5459));
        assert_eq!(bolle.prossimo(Regola::Progressiva, g(31, 12)), Ok(5459));
        assert_eq!(Numeri::default().prossimo(Regola::Progressiva, g(1, 1)), Ok(1));
    }

    #[test]
    fn alla_data_segue_l_ultimo_documento_fino_a_quella_data() {
        let fatture = fatture_gennaio();
        assert_eq!(fatture.prossimo(Regola::AllaData, g(10, 1)), Ok(6));
        assert_eq!(fatture.prossimo(Regola::AllaData, g(31, 1)), Ok(6));
        // Arca: "per la data 02-01-2026 sarebbe 4 ma questo numero è già utilizzato dal
        // documento FA 4 del 05-01-2026".
        assert_eq!(
            fatture.prossimo(Regola::AllaData, g(2, 1)),
            Err(NumeroNonValido::Occupato { numero: 4, data: g(5, 1) })
        );
        assert_eq!(
            fatture.prossimo(Regola::AllaData, g(1, 1)),
            Err(NumeroNonValido::Occupato { numero: 1, data: g(2, 1) })
        );
    }

    #[test]
    fn numero_massimo_non_superato() {
        let pieno: Numeri = [(NUMERO_MASSIMO, g(1, 1))].into_iter().collect();
        assert_eq!(
            pieno.prossimo(Regola::Progressiva, g(1, 1)),
            Err(NumeroNonValido::FuoriIntervallo(NUMERO_MASSIMO + 1))
        );
    }

    #[test]
    fn buchi_come_unused_codes() {
        // D00 2018 sul clone: "[04/01/2018  04/01/2018]  2 numeri liberi (dal 27 al 28)".
        let bolle: Numeri = [(1, g(2, 1)), (26, g(4, 1)), (29, g(4, 1)), (31, g(5, 1)), (30, g(5, 1))]
            .into_iter()
            .collect();
        assert_eq!(
            bolle.liberi(),
            vec![
                Liberi { dal: 2, al: 25, data_dal: Some(g(2, 1)), data_al: g(4, 1) },
                Liberi { dal: 27, al: 28, data_dal: Some(g(4, 1)), data_al: g(4, 1) },
            ]
        );
        let da_tre: Numeri = [(3, g(7, 1))].into_iter().collect();
        assert_eq!(da_tre.liberi(), vec![Liberi { dal: 1, al: 2, data_dal: None, data_al: g(7, 1) }]);
    }

    #[test]
    fn stesso_numero_due_volte_vale_l_intervallo_delle_date() {
        // BO 1 e 1/PA del 2018 hanno lo stesso numero intero.
        let mut bolle = Numeri::default();
        bolle.aggiungi(1, g(3, 1));
        bolle.aggiungi(1, g(2, 1));
        bolle.aggiungi(3, g(9, 1));
        assert_eq!(bolle.liberi(), vec![Liberi { dal: 2, al: 2, data_dal: Some(g(3, 1)), data_al: g(9, 1) }]);
        assert_eq!(bolle.prossimo(Regola::AllaData, g(2, 1)), Ok(2));
    }

    #[test]
    fn numero_scelto_libero_e_nelle_date_del_buco() {
        let mut fatture = fatture_gennaio();
        fatture.aggiungi(8, g(20, 1));
        assert_eq!(
            fatture.verifica(Regola::AllaData, 4, g(5, 1)),
            Err(NumeroNonValido::Occupato { numero: 4, data: g(5, 1) })
        );
        assert_eq!(fatture.verifica(Regola::AllaData, 6, g(10, 1)), Ok(()));
        assert_eq!(fatture.verifica(Regola::AllaData, 7, g(20, 1)), Ok(()));
        let fuori = fatture.verifica(Regola::AllaData, 6, g(21, 1));
        assert_eq!(
            fuori,
            Err(NumeroNonValido::FuoriData { numero: 6, dal: Some(g(10, 1)), al: Some(g(20, 1)) })
        );
        assert_eq!(
            fuori.unwrap_err().to_string(),
            "il numero 6 si può usare solo con data dal 10/01/2026 al 20/01/2026"
        );
        assert_eq!(fatture.verifica(Regola::Progressiva, 6, g(21, 1)), Ok(()));
        assert_eq!(
            fatture.verifica(Regola::AllaData, 9, g(19, 1)),
            Err(NumeroNonValido::FuoriData { numero: 9, dal: Some(g(20, 1)), al: None })
        );
        assert_eq!(fatture.verifica(Regola::AllaData, 0, g(1, 1)), Err(NumeroNonValido::FuoriIntervallo(0)));
    }
}
