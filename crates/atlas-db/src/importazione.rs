//! Stato dell'importazione dei documenti di Arca: fin dove è arrivata, quali documenti non sa
//! ancora rappresentare, quali documenti di Arca il database ATLAS conosce.
//!
//! Il documento importato è in `ddt` ([`crate::ddt::importa`]); qui solo ciò che serve al giro
//! successivo per riprendere dal punto giusto e accorgersi delle cancellazioni.

use std::collections::BTreeSet;

use atlas_core::numerazione::Sezionale;
use chrono::{NaiveDate, NaiveDateTime};
use rusqlite::{Connection, OptionalExtension, params};

use crate::ErroreDb;

/// Sezionale dei documenti che l'importazione dei BO tiene allineati: i BO e gli altri tipi
/// che ne condividono la numerazione.
const SEZIONALE_BO: Sezionale = Sezionale::Bolle;

/// Fin dove è arrivata l'importazione di un tipo documento.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Punto {
    /// Database di Arca a cui è legato il file ATLAS.
    pub database: String,
    /// `DOTes.Ts` dell'ultimo documento importato.
    pub ultimo_ts: i64,
}

pub fn punto(conn: &Connection, tipo_documento: &str) -> Result<Option<Punto>, ErroreDb> {
    Ok(conn
        .prepare_cached("SELECT database, ultimo_ts FROM importazione_arca WHERE tipo_documento = ?1")?
        .query_row([tipo_documento], |r| {
            Ok(Punto {
                database: r.get(0)?,
                ultimo_ts: r.get(1)?,
            })
        })
        .optional()?)
}

/// Registra il punto raggiunto. Va chiamata nella transazione che importa i documenti.
pub fn avanza(conn: &Connection, tipo_documento: &str, punto: &Punto, adesso: NaiveDateTime) -> Result<(), ErroreDb> {
    conn.prepare_cached(
        "INSERT INTO importazione_arca (tipo_documento, database, ultimo_ts, aggiornato_il) VALUES (?1, ?2, ?3, ?4) \
         ON CONFLICT (tipo_documento) DO UPDATE SET database = ?2, ultimo_ts = ?3, aggiornato_il = ?4",
    )?
    .execute(params![tipo_documento, punto.database, punto.ultimo_ts, adesso])?;
    Ok(())
}

/// Documento di Arca che ATLAS non sa ancora rappresentare. Il suo numero resta occupato.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Escluso {
    pub arca_id_testata: i32,
    pub tipo_documento: String,
    /// `DOTes.Cd_CN`.
    pub sezionale: String,
    pub esercizio: i32,
    pub numero: u32,
    pub data: NaiveDate,
    pub motivo: String,
}

pub fn escludi(conn: &Connection, escluso: &Escluso, adesso: NaiveDateTime) -> Result<(), ErroreDb> {
    conn.prepare_cached(
        "INSERT INTO importazione_esclusi (arca_id_testata, tipo_documento, sezionale, esercizio, numero, data, \
         motivo, rilevato_il) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8) ON CONFLICT (arca_id_testata) DO UPDATE SET \
         tipo_documento = ?2, sezionale = ?3, esercizio = ?4, numero = ?5, data = ?6, motivo = ?7, rilevato_il = ?8",
    )?
    .execute(params![
        escluso.arca_id_testata,
        escluso.tipo_documento,
        escluso.sezionale,
        escluso.esercizio,
        escluso.numero,
        escluso.data,
        escluso.motivo,
        adesso
    ])?;
    Ok(())
}

/// Toglie dagli esclusi un documento ora importato.
pub fn riammetti(conn: &Connection, arca_id_testata: i32) -> Result<(), ErroreDb> {
    conn.prepare_cached("DELETE FROM importazione_esclusi WHERE arca_id_testata = ?1")?
        .execute([arca_id_testata])?;
    Ok(())
}

pub fn esclusi(conn: &Connection) -> Result<Vec<Escluso>, ErroreDb> {
    let mut stmt = conn.prepare_cached(
        "SELECT arca_id_testata, tipo_documento, sezionale, esercizio, numero, data, motivo \
         FROM importazione_esclusi ORDER BY sezionale, esercizio, numero",
    )?;
    let righe = stmt.query_map([], |r| {
        Ok(Escluso {
            arca_id_testata: r.get(0)?,
            tipo_documento: r.get(1)?,
            sezionale: r.get(2)?,
            esercizio: r.get(3)?,
            numero: r.get(4)?,
            data: r.get(5)?,
            motivo: r.get(6)?,
        })
    })?;
    Ok(righe.collect::<Result<_, _>>()?)
}

/// `Id_DoTes` dei documenti del sezionale dei BO che il database ATLAS conosce: importati,
/// replicati o esclusi.
pub fn noti(conn: &Connection) -> Result<BTreeSet<i32>, ErroreDb> {
    let mut stmt = conn.prepare_cached(
        "SELECT arca_id_testata FROM ddt WHERE arca_id_testata IS NOT NULL \
         UNION SELECT arca_id_testata FROM importazione_esclusi WHERE sezionale = ?1",
    )?;
    let righe = stmt.query_map([SEZIONALE_BO.codice()], |r| r.get(0))?;
    Ok(righe.collect::<Result<_, _>>()?)
}

/// Il documento è stato cancellato in Arca: esce dal database ATLAS, righe comprese, e dagli
/// esclusi. Vero se c'era.
pub fn dimentica(conn: &Connection, arca_id_testata: i32) -> Result<bool, ErroreDb> {
    let documenti = conn
        .prepare_cached("DELETE FROM ddt WHERE arca_id_testata = ?1")?
        .execute([arca_id_testata])?;
    let esclusi = conn
        .prepare_cached("DELETE FROM importazione_esclusi WHERE arca_id_testata = ?1 AND sezionale = ?2")?
        .execute(params![arca_id_testata, SEZIONALE_BO.codice()])?;
    Ok(documenti + esclusi > 0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::prova::{adesso, database, ddt};
    use crate::ddt::{self as documenti, Importato};

    fn escluso(arca_id_testata: i32) -> Escluso {
        Escluso {
            arca_id_testata,
            tipo_documento: "BO".into(),
            sezionale: "D00".into(),
            esercizio: 2026,
            numero: 5400,
            data: NaiveDate::from_ymd_opt(2026, 10, 20).unwrap(),
            motivo: "righe senza articolo".into(),
        }
    }

    #[test]
    fn punto_registrato_e_aggiornato() {
        let conn = database();
        assert_eq!(punto(&conn, "BO").unwrap(), None);
        let mut p = Punto {
            database: "ADB_BOTTAMEDI_DEV".into(),
            ultimo_ts: 78_758_209,
        };
        avanza(&conn, "BO", &p, adesso()).unwrap();
        p.ultimo_ts += 1;
        avanza(&conn, "BO", &p, adesso()).unwrap();
        assert_eq!(punto(&conn, "BO").unwrap(), Some(p));
    }

    #[test]
    fn noti_sono_importati_replicati_ed_esclusi_ma_non_i_documenti_in_coda() {
        let mut conn = database();
        documenti::importa(&conn, &ddt(1), 100).unwrap();
        let replicato = documenti::salva(&mut conn, &ddt(2), adesso()).unwrap();
        crate::outbox::segna_replicato(&conn, replicato.evento, 101, adesso()).unwrap();
        documenti::salva(&mut conn, &ddt(3), adesso()).unwrap();
        escludi(&conn, &escluso(102), adesso()).unwrap();
        // Già importato e poi diventato non rappresentabile: conta una volta.
        escludi(&conn, &escluso(100), adesso()).unwrap();
        assert_eq!(noti(&conn).unwrap(), BTreeSet::from([100, 101, 102]));
        assert_eq!(esclusi(&conn).unwrap().len(), 2);
    }

    #[test]
    fn documento_cancellato_in_arca_esce_con_le_righe() {
        let conn = database();
        let Importato::Nuovo(_) = documenti::importa(&conn, &ddt(1), 100).unwrap() else { panic!() };
        escludi(&conn, &escluso(102), adesso()).unwrap();
        assert!(dimentica(&conn, 100).unwrap());
        assert!(dimentica(&conn, 102).unwrap());
        assert!(!dimentica(&conn, 100).unwrap());
        let conta = |sql: &str| conn.query_row(sql, [], |r| r.get::<_, i64>(0)).unwrap();
        assert_eq!(conta("SELECT count(*) FROM ddt") + conta("SELECT count(*) FROM ddt_righe"), 0);
        assert!(noti(&conn).unwrap().is_empty());
    }

    #[test]
    fn documento_riammesso_esce_dagli_esclusi() {
        let conn = database();
        escludi(&conn, &escluso(100), adesso()).unwrap();
        riammetti(&conn, 100).unwrap();
        assert!(esclusi(&conn).unwrap().is_empty());
    }
}
