//! Numeri occupati nel database ATLAS per sezionale ed esercizio: i documenti ATLAS (nati qui o
//! importati) e quelli di Arca che ATLAS non sa rappresentare, che il numero lo tengono comunque.
//! La regola con cui Arca sceglie il numero è in [`atlas_core::numerazione`].

use atlas_core::numerazione::{Liberi, NumeroNonValido, Numeri, Sezionale, TipoDocumento};
use chrono::NaiveDate;
use rusqlite::Connection;

use crate::ErroreDb;

/// Sezionale dei DDT della tabella `ddt`.
pub(crate) const SEZIONALE_DDT: Sezionale = TipoDocumento::BollaVendita.sezionale();

/// Numeri occupati nel sezionale e nell'esercizio, con le date dei documenti.
pub fn occupati(conn: &Connection, sezionale: Sezionale, esercizio: i32) -> Result<Numeri, ErroreDb> {
    let mut numeri = Numeri::default();
    let mut leggi = |sql: &str, parametri: &[&dyn rusqlite::ToSql]| -> Result<(), ErroreDb> {
        let mut stmt = conn.prepare_cached(sql)?;
        let righe = stmt.query_map(parametri, |r| Ok((r.get::<_, u32>(0)?, r.get::<_, NaiveDate>(1)?)))?;
        for riga in righe {
            let (numero, data) = riga?;
            numeri.aggiungi(numero, data);
        }
        Ok(())
    };
    if sezionale == SEZIONALE_DDT {
        leggi("SELECT numero, data FROM ddt WHERE esercizio = ?1", &[&esercizio])?;
    }
    leggi(
        "SELECT numero, data FROM importazione_esclusi WHERE sezionale = ?1 AND esercizio = ?2",
        &[&sezionale.codice(), &esercizio],
    )?;
    Ok(numeri)
}

/// Il numero e i due occupati più vicini, da una parte e dall'altra: quanto serve a
/// [`Numeri::verifica`], senza leggere tutto l'esercizio (letture sugli indici unici).
pub fn vicini(conn: &Connection, sezionale: Sezionale, esercizio: i32, numero: u32) -> Result<Numeri, ErroreDb> {
    let mut numeri = Numeri::default();
    let mut leggi = |sql: &str, parametri: &[&dyn rusqlite::ToSql]| -> Result<(), ErroreDb> {
        let mut stmt = conn.prepare_cached(sql)?;
        let righe = stmt.query_map(parametri, |r| Ok((r.get::<_, u32>(0)?, r.get::<_, NaiveDate>(1)?)))?;
        for riga in righe {
            let (numero, data) = riga?;
            numeri.aggiungi(numero, data);
        }
        Ok(())
    };
    if sezionale == SEZIONALE_DDT {
        leggi(
            "SELECT numero, data FROM ddt WHERE esercizio = ?1 AND numero IN (?2, \
             (SELECT max(numero) FROM ddt WHERE esercizio = ?1 AND numero < ?2), \
             (SELECT min(numero) FROM ddt WHERE esercizio = ?1 AND numero > ?2))",
            &[&esercizio, &numero],
        )?;
    }
    leggi(
        "SELECT numero, data FROM importazione_esclusi WHERE sezionale = ?1 AND esercizio = ?2 AND numero IN (?3, \
         (SELECT max(numero) FROM importazione_esclusi WHERE sezionale = ?1 AND esercizio = ?2 AND numero < ?3), \
         (SELECT min(numero) FROM importazione_esclusi WHERE sezionale = ?1 AND esercizio = ?2 AND numero > ?3))",
        &[&sezionale.codice(), &esercizio, &numero],
    )?;
    Ok(numeri)
}

/// Buchi della numerazione come li elenca Arca (`UnusedCodes_DoTes`), sui documenti noti ad
/// ATLAS e su quelli di `altri` (per esempio i numeri letti ora da Arca).
pub fn liberi(conn: &Connection, sezionale: Sezionale, esercizio: i32, altri: &Numeri) -> Result<Vec<Liberi>, ErroreDb> {
    let mut numeri = occupati(conn, sezionale, esercizio)?;
    numeri.unisci(altri);
    Ok(numeri.liberi())
}

/// Un numero rifiutato: se è di un altro documento resta [`ErroreDb::NumeroOccupato`], come per
/// il vincolo di unicità della tabella, così chi gestisce i conflitti ha un solo caso.
pub(crate) fn errore(e: NumeroNonValido, esercizio: i32) -> ErroreDb {
    match e {
        NumeroNonValido::Occupato { numero, .. } => ErroreDb::NumeroOccupato { esercizio, numero },
        e => ErroreDb::Numerazione(e),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use atlas_core::numerazione::Regola;
    use crate::importazione::{Escluso, escludi};
    use crate::prova::{adesso, database, ddt};

    fn g(giorno: u32, mese: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(2026, mese, giorno).unwrap()
    }

    fn escluso(arca_id_testata: i32, sezionale: &str, numero: u32) -> Escluso {
        Escluso {
            arca_id_testata,
            tipo_documento: "BF".into(),
            sezionale: sezionale.into(),
            esercizio: 2026,
            numero,
            data: g(20, 10),
            motivo: "documento di un altro tipo".into(),
        }
    }

    #[test]
    fn occupati_sono_i_ddt_e_gli_esclusi_dello_stesso_sezionale_ed_esercizio() {
        let mut conn = database();
        crate::ddt::salva(&mut conn, &ddt(5457), adesso()).unwrap();
        let mut anno_prima = ddt(9000);
        anno_prima.data = NaiveDate::from_ymd_opt(2025, 12, 31).unwrap();
        crate::ddt::salva(&mut conn, &anno_prima, adesso()).unwrap();
        escludi(&conn, &escluso(1, "D00", 5459), adesso()).unwrap();
        escludi(&conn, &escluso(2, "001", 7000), adesso()).unwrap();

        let bolle = occupati(&conn, Sezionale::Bolle, 2026).unwrap();
        let attesi: Numeri = [(5457, g(22, 10)), (5459, g(20, 10))].into_iter().collect();
        assert_eq!(bolle, attesi);
        let fatture = occupati(&conn, Sezionale::Fatture, 2026).unwrap();
        assert_eq!(fatture, [(7000, g(20, 10))].into_iter().collect());
        let da_arca: Numeri = [(5450, g(21, 10))].into_iter().collect();
        let buchi = liberi(&conn, Sezionale::Bolle, 2026, &da_arca).unwrap();
        assert_eq!(buchi.iter().map(|l| (l.dal, l.al)).collect::<Vec<_>>(), [(1, 5449), (5451, 5456), (5458, 5458)]);
    }

    #[test]
    fn vicini_bastano_a_verificare_come_tutto_l_esercizio() {
        let mut conn = database();
        for numero in [10, 20, 30] {
            crate::ddt::salva(&mut conn, &ddt(numero), adesso()).unwrap();
        }
        for (id, numero) in [(1, 15), (2, 25), (3, 40)] {
            escludi(&conn, &escluso(id, "D00", numero), adesso()).unwrap();
        }
        let tutti = occupati(&conn, Sezionale::Bolle, 2026).unwrap();
        for numero in 1..=45 {
            let vicini = vicini(&conn, Sezionale::Bolle, 2026, numero).unwrap();
            for data in [g(19, 10), g(20, 10), g(21, 10), g(22, 10), g(23, 10)] {
                for regola in [Regola::Progressiva, Regola::AllaData] {
                    assert_eq!(
                        vicini.verifica(regola, numero, data),
                        tutti.verifica(regola, numero, data),
                        "{numero} {data} {regola:?}"
                    );
                }
            }
        }
    }
}
