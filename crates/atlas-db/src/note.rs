//! Post-it della Home: note condivise fra le postazioni. Sono solo di ATLAS (non c'è evento di
//! replica) e la posizione è in frazioni della bacheca.

use chrono::NaiveDateTime;
use rusqlite::{Connection, OptionalExtension, Row, params};
use serde::{Deserialize, Serialize};

use crate::ErroreDb;

pub const COLORI: [&str; 5] = ["giallo", "rosa", "verde", "azzurro", "arancio"];

/// Testo massimo di una nota: un post-it, non un documento.
pub const LUNGHEZZA_MASSIMA: usize = 500;

#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct Nota {
    pub id: i64,
    pub testo: String,
    pub colore: String,
    pub x: f64,
    pub y: f64,
    pub autore: String,
    pub creata_il: NaiveDateTime,
    pub aggiornata_il: NaiveDateTime,
}

/// I campi di una nota che la bacheca scrive; nella modifica quelli assenti restano com'erano.
#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
pub struct CampiNota {
    pub testo: Option<String>,
    pub colore: Option<String>,
    pub x: Option<f64>,
    pub y: Option<f64>,
}

fn da_riga(r: &Row<'_>) -> rusqlite::Result<Nota> {
    Ok(Nota {
        id: r.get(0)?,
        testo: r.get(1)?,
        colore: r.get(2)?,
        x: r.get(3)?,
        y: r.get(4)?,
        autore: r.get(5)?,
        creata_il: r.get(6)?,
        aggiornata_il: r.get(7)?,
    })
}

const COLONNE: &str = "id, testo, colore, x, y, autore, creata_il, aggiornata_il";

fn controlla(campi: &CampiNota) -> Result<(), ErroreDb> {
    if let Some(testo) = &campi.testo {
        if testo.chars().count() > LUNGHEZZA_MASSIMA {
            return Err(ErroreDb::DocumentoNonValido(format!("nota oltre {LUNGHEZZA_MASSIMA} caratteri")));
        }
    }
    if let Some(colore) = &campi.colore {
        if !COLORI.contains(&colore.as_str()) {
            return Err(ErroreDb::DocumentoNonValido(format!("colore {colore} non previsto")));
        }
    }
    for v in [campi.x, campi.y].into_iter().flatten() {
        if !(0.0..=1.0).contains(&v) {
            return Err(ErroreDb::DocumentoNonValido("posizione fuori dalla bacheca".into()));
        }
    }
    Ok(())
}

/// Le note dalla più vecchia: le nuove stanno sopra.
pub fn elenco(conn: &Connection) -> Result<Vec<Nota>, ErroreDb> {
    let mut q = conn.prepare_cached(&format!("SELECT {COLONNE} FROM note ORDER BY aggiornata_il, id"))?;
    let note = q.query_map([], da_riga)?.collect::<Result<_, _>>()?;
    Ok(note)
}

pub fn crea(conn: &Connection, campi: &CampiNota, autore: &str, adesso: NaiveDateTime) -> Result<Nota, ErroreDb> {
    controlla(campi)?;
    let id = conn
        .prepare_cached(
            "INSERT INTO note (testo, colore, x, y, autore, creata_il, aggiornata_il) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?6) \
             RETURNING id",
        )?
        .query_row(
            params![
                campi.testo.as_deref().unwrap_or(""),
                campi.colore.as_deref().unwrap_or("giallo"),
                campi.x.unwrap_or(0.05),
                campi.y.unwrap_or(0.05),
                autore,
                adesso
            ],
            |r| r.get(0),
        )?;
    leggi(conn, id)
}

pub fn aggiorna(conn: &Connection, id: i64, campi: &CampiNota, adesso: NaiveDateTime) -> Result<Nota, ErroreDb> {
    controlla(campi)?;
    let cambiate = conn.prepare_cached(
        "UPDATE note SET testo = coalesce(?2, testo), colore = coalesce(?3, colore), x = coalesce(?4, x), \
         y = coalesce(?5, y), aggiornata_il = ?6 WHERE id = ?1",
    )?
    .execute(params![id, campi.testo, campi.colore, campi.x, campi.y, adesso])?;
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

    #[test]
    fn crea_sposta_modifica_ed_elimina() {
        let conn = apri_in_memoria().unwrap();
        let campi = CampiNota { testo: Some("Chiamare Dinamos per le cassette".into()), ..CampiNota::default() };
        let nota = crea(&conn, &campi, "190", alle(8)).unwrap();
        assert_eq!((nota.colore.as_str(), nota.autore.as_str()), ("giallo", "190"));

        let spostata = aggiorna(&conn, nota.id, &CampiNota { x: Some(0.5), y: Some(0.25), ..CampiNota::default() }, alle(9)).unwrap();
        assert_eq!((spostata.testo.as_str(), spostata.x, spostata.y), ("Chiamare Dinamos per le cassette", 0.5, 0.25));
        assert_eq!((spostata.creata_il, spostata.aggiornata_il), (alle(8), alle(9)));
        assert_eq!(elenco(&conn).unwrap(), [spostata]);

        elimina(&conn, nota.id).unwrap();
        assert!(elenco(&conn).unwrap().is_empty());
        assert!(matches!(elimina(&conn, nota.id), Err(ErroreDb::NonTrovato(_))));
    }

    #[test]
    fn rifiuta_colori_posizioni_e_testi_fuori_misura() {
        let conn = apri_in_memoria().unwrap();
        for campi in [
            CampiNota { colore: Some("viola".into()), ..CampiNota::default() },
            CampiNota { x: Some(1.5), ..CampiNota::default() },
            CampiNota { testo: Some("x".repeat(LUNGHEZZA_MASSIMA + 1)), ..CampiNota::default() },
        ] {
            assert!(matches!(crea(&conn, &campi, "190", alle(8)), Err(ErroreDb::DocumentoNonValido(_))));
        }
        assert!(matches!(
            aggiorna(&conn, 99, &CampiNota::default(), alle(8)),
            Err(ErroreDb::NonTrovato(_))
        ));
    }
}
