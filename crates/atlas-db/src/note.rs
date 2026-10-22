//! Post-it della Home: righe di promemoria condivise fra le postazioni, che si barrano quando
//! sono fatte. Sono solo di ATLAS: non c'è evento di replica.

use chrono::NaiveDateTime;
use rusqlite::{Connection, OptionalExtension, Row, params};
use serde::{Deserialize, Serialize};

use crate::ErroreDb;

/// Testo massimo di una riga: un promemoria, non un documento.
pub const LUNGHEZZA_MASSIMA: usize = 500;

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Nota {
    pub id: i64,
    pub testo: String,
    pub fatta: bool,
    pub autore: String,
    pub creata_il: NaiveDateTime,
    pub aggiornata_il: NaiveDateTime,
}

/// I campi che la Home scrive; nella modifica quelli assenti restano com'erano.
#[derive(Debug, Clone, Default, PartialEq, Eq, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CampiNota {
    pub testo: Option<String>,
    pub fatta: Option<bool>,
}

fn da_riga(r: &Row<'_>) -> rusqlite::Result<Nota> {
    Ok(Nota {
        id: r.get(0)?,
        testo: r.get(1)?,
        fatta: r.get(2)?,
        autore: r.get(3)?,
        creata_il: r.get(4)?,
        aggiornata_il: r.get(5)?,
    })
}

const COLONNE: &str = "id, testo, fatta, autore, creata_il, aggiornata_il";

/// Il testo pulito, se c'è; vuoto o troppo lungo è un errore.
fn testo(campi: &CampiNota) -> Result<Option<String>, ErroreDb> {
    let Some(testo) = &campi.testo else { return Ok(None) };
    let testo = testo.trim();
    if testo.is_empty() {
        return Err(ErroreDb::DocumentoNonValido("nota vuota".into()));
    }
    if testo.chars().count() > LUNGHEZZA_MASSIMA {
        return Err(ErroreDb::DocumentoNonValido(format!("nota oltre {LUNGHEZZA_MASSIMA} caratteri")));
    }
    Ok(Some(testo.to_owned()))
}

/// Le righe nell'ordine in cui sono state scritte.
pub fn elenco(conn: &Connection) -> Result<Vec<Nota>, ErroreDb> {
    let mut q = conn.prepare_cached(&format!("SELECT {COLONNE} FROM note ORDER BY id"))?;
    let note = q.query_map([], da_riga)?.collect::<Result<_, _>>()?;
    Ok(note)
}

pub fn crea(conn: &Connection, campi: &CampiNota, autore: &str, adesso: NaiveDateTime) -> Result<Nota, ErroreDb> {
    let testo = testo(campi)?.ok_or_else(|| ErroreDb::DocumentoNonValido("nota vuota".into()))?;
    let id = conn
        .prepare_cached(
            "INSERT INTO note (testo, fatta, autore, creata_il, aggiornata_il) VALUES (?1, ?2, ?3, ?4, ?4) RETURNING id",
        )?
        .query_row(params![testo, campi.fatta.unwrap_or(false), autore, adesso], |r| r.get(0))?;
    leggi(conn, id)
}

pub fn aggiorna(conn: &Connection, id: i64, campi: &CampiNota, adesso: NaiveDateTime) -> Result<Nota, ErroreDb> {
    let testo = testo(campi)?;
    let cambiate = conn
        .prepare_cached(
            "UPDATE note SET testo = coalesce(?2, testo), fatta = coalesce(?3, fatta), aggiornata_il = ?4 WHERE id = ?1",
        )?
        .execute(params![id, testo, campi.fatta, adesso])?;
    if cambiate == 0 {
        return Err(ErroreDb::NonTrovato(format!("nota {id}")));
    }
    leggi(conn, id)
}

pub fn elimina(conn: &Connection, id: i64) -> Result<(), ErroreDb> {
    if conn.prepare_cached("DELETE FROM note WHERE id = ?1")?.execute([id])? == 0 {
        return Err(ErroreDb::NonTrovato(format!("nota {id}")));
    }
    Ok(())
}

fn leggi(conn: &Connection, id: i64) -> Result<Nota, ErroreDb> {
    conn.prepare_cached(&format!("SELECT {COLONNE} FROM note WHERE id = ?1"))?
        .query_row([id], da_riga)
        .optional()?
        .ok_or_else(|| ErroreDb::NonTrovato(format!("nota {id}")))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::apri_in_memoria;
    use chrono::NaiveDate;

    fn alle(h: u32) -> NaiveDateTime {
        NaiveDate::from_ymd_opt(2026, 10, 22).unwrap().and_hms_opt(h, 0, 0).unwrap()
    }

    fn scrivi(testo: &str) -> CampiNota {
        CampiNota { testo: Some(testo.into()), fatta: None }
    }

    #[test]
    fn crea_barra_ed_elimina() {
        let conn = apri_in_memoria().unwrap();
        let nota = crea(&conn, &scrivi("  Cassette a Dinamos "), "190", alle(8)).unwrap();
        assert_eq!((nota.testo.as_str(), nota.fatta, nota.autore.as_str()), ("Cassette a Dinamos", false, "190"));

        let barrata = aggiorna(&conn, nota.id, &CampiNota { testo: None, fatta: Some(true) }, alle(9)).unwrap();
        assert_eq!((barrata.testo.as_str(), barrata.fatta), ("Cassette a Dinamos", true));
        assert_eq!((barrata.creata_il, barrata.aggiornata_il), (alle(8), alle(9)));
        assert_eq!(elenco(&conn).unwrap(), [barrata]);

        elimina(&conn, nota.id).unwrap();
        assert!(elenco(&conn).unwrap().is_empty());
        assert!(matches!(elimina(&conn, nota.id), Err(ErroreDb::NonTrovato(_))));
    }

    #[test]
    fn rifiuta_righe_vuote_o_troppo_lunghe() {
        let conn = apri_in_memoria().unwrap();
        for testo in ["   ", &"x".repeat(LUNGHEZZA_MASSIMA + 1)] {
            assert!(matches!(crea(&conn, &scrivi(testo), "190", alle(8)), Err(ErroreDb::DocumentoNonValido(_))));
        }
        assert!(matches!(crea(&conn, &CampiNota::default(), "190", alle(8)), Err(ErroreDb::DocumentoNonValido(_))));
        assert!(matches!(aggiorna(&conn, 99, &CampiNota::default(), alle(8)), Err(ErroreDb::NonTrovato(_))));
    }
}
