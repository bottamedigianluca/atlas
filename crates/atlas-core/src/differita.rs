//! Fatturazione differita di fine mese: raggruppamento dei DDT in fatture.

use std::collections::BTreeMap;

use chrono::NaiveDate;
use serde::{Deserialize, Serialize};

/// DDT candidato alla fatturazione.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DdtDaFatturare {
    pub id: i64,
    pub numero: u32,
    pub data: NaiveDate,
    pub cliente: String,
    pub pagamento: String,
}

/// Fattura differita da generare: un cliente, una condizione di pagamento, i suoi DDT in ordine.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FatturaProposta {
    pub cliente: String,
    pub pagamento: String,
    pub ddt: Vec<DdtDaFatturare>,
}

/// Raggruppa i DDT selezionati per cliente e condizione di pagamento.
///
/// La destinazione merce non separa le fatture (79 righe 2025-2026 uniscono destinazioni
/// diverse). Dentro ogni fattura i DDT seguono data e numero, come le righe di riferimento.
pub fn raggruppa(ddt: impl IntoIterator<Item = DdtDaFatturare>) -> Vec<FatturaProposta> {
    let mut gruppi: BTreeMap<(String, String), Vec<DdtDaFatturare>> = BTreeMap::new();
    for d in ddt {
        gruppi
            .entry((d.cliente.clone(), d.pagamento.clone()))
            .or_default()
            .push(d);
    }
    gruppi
        .into_iter()
        .map(|((cliente, pagamento), mut ddt)| {
            ddt.sort_by_key(|d| (d.data, d.numero));
            FatturaProposta {
                cliente,
                pagamento,
                ddt,
            }
        })
        .collect()
}

/// Riga descrittiva che apre il blocco di ogni DDT in fattura (`DO.NoteDo` del tipo BO):
/// `"D.D.T. NR. BO   4467     DEL 01-09-2026"`, con `Cd_Do char(3)` e `NumeroDoc char(10)`
/// allineato a destra su 6 caratteri, identica a quella scritta da Arca.
pub fn riga_riferimento_ddt(numero: u32, data: NaiveDate) -> String {
    format!(
        "D.D.T. NR. {:<3}{:>6}     DEL {}",
        "BO",
        numero,
        data.format("%d-%m-%Y")
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ddt(id: i64, numero: u32, giorno: u32, cliente: &str, pagamento: &str) -> DdtDaFatturare {
        DdtDaFatturare {
            id,
            numero,
            data: NaiveDate::from_ymd_opt(2026, 9, giorno).unwrap(),
            cliente: cliente.into(),
            pagamento: pagamento.into(),
        }
    }

    #[test]
    fn una_fattura_per_cliente_e_pagamento() {
        let fatture = raggruppa([
            ddt(3, 4801, 17, "C000072", "R030"),
            ddt(1, 4558, 6, "C000072", "R030"),
            ddt(2, 4600, 8, "C000179", "D000"),
            ddt(4, 4700, 12, "C000179", "B000"),
        ]);
        assert_eq!(fatture.len(), 3);
        assert_eq!(fatture[0].cliente, "C000072");
        assert_eq!(fatture[0].ddt.iter().map(|d| d.numero).collect::<Vec<_>>(), [4558, 4801]);
    }

    #[test]
    fn riferimento_identico_ad_arca() {
        let data = NaiveDate::from_ymd_opt(2026, 9, 1).unwrap();
        assert_eq!(riga_riferimento_ddt(4467, data), "D.D.T. NR. BO   4467     DEL 01-09-2026");
    }
}
