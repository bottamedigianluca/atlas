//! Coda degli eventi da replicare in Arca (transactional outbox).
//!
//! Gli eventi nascono nella stessa transazione del documento ([`accoda`]) e il worker di
//! replica li consuma in ordine di `id`: segna quelli riusciti con l'identità assegnata da Arca
//! e rinvia quelli falliti, con l'errore e l'istante del prossimo tentativo.

use atlas_core::ddt::Ddt;
use chrono::NaiveDateTime;
use rusqlite::{Connection, Row, params};

use crate::ErroreDb;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Operazione {
    Crea,
    Modifica,
    Cancella,
}

impl Operazione {
    pub fn come_testo(self) -> &'static str {
        match self {
            Self::Crea => "crea",
            Self::Modifica => "modifica",
            Self::Cancella => "cancella",
        }
    }

    fn da_testo(testo: &str) -> Option<Self> {
        match testo {
            "crea" => Some(Self::Crea),
            "modifica" => Some(Self::Modifica),
            "cancella" => Some(Self::Cancella),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Evento {
    pub id: i64,
    pub documento_tipo: String,
    pub documento_id: i64,
    pub operazione: Operazione,
    /// Documento al momento dell'evento (JSON).
    pub payload: String,
    pub creato_il: NaiveDateTime,
    pub tentativi: i64,
    pub ultimo_errore: Option<String>,
}

impl Evento {
    /// Documento dell'evento.
    pub fn ddt(&self) -> Result<Ddt, ErroreDb> {
        Ok(serde_json::from_str(&self.payload)?)
    }

    fn da_riga(r: &Row<'_>) -> Result<Self, ErroreDb> {
        let operazione: String = r.get(3)?;
        Ok(Self {
            id: r.get(0)?,
            documento_tipo: r.get(1)?,
            documento_id: r.get(2)?,
            operazione: Operazione::da_testo(&operazione)
                .ok_or_else(|| ErroreDb::DocumentoNonValido(format!("operazione {operazione}")))?,
            payload: r.get(4)?,
            creato_il: r.get(5)?,
            tentativi: r.get(6)?,
            ultimo_errore: r.get(7)?,
        })
    }
}

const COLONNE: &str = "id, documento_tipo, documento_id, operazione, payload, creato_il, tentativi, ultimo_errore";

/// Accoda un evento. Va chiamata dentro la transazione che scrive il documento.
pub fn accoda(
    conn: &Connection,
    documento_tipo: &str,
    documento_id: i64,
    operazione: Operazione,
    payload: &str,
    adesso: NaiveDateTime,
) -> Result<i64, ErroreDb> {
    conn.prepare_cached(
        "INSERT INTO outbox_eventi (documento_tipo, documento_id, operazione, payload, creato_il) \
         VALUES (?1, ?2, ?3, ?4, ?5)",
    )?
    .execute(params![documento_tipo, documento_id, operazione.come_testo(), payload, adesso])?;
    Ok(conn.last_insert_rowid())
}

/// Primi `limite` eventi non ancora replicati, in ordine di creazione. Un evento in attesa di
/// riprova (`prossimo_tentativo_il` futuro) blocca quelli successivi: la replica conserva
/// l'ordine con cui i documenti sono stati scritti in ATLAS.
pub fn da_replicare(conn: &Connection, adesso: NaiveDateTime, limite: usize) -> Result<Vec<Evento>, ErroreDb> {
    let mut stmt = conn.prepare_cached(
        "SELECT id, documento_tipo, documento_id, operazione, payload, creato_il, tentativi, ultimo_errore, \
         prossimo_tentativo_il FROM outbox_eventi WHERE replicato_il IS NULL ORDER BY id LIMIT ?1",
    )?;
    let mut righe = stmt.query([i64::try_from(limite).unwrap_or(i64::MAX)])?;
    let mut eventi = Vec::new();
    while let Some(r) = righe.next()? {
        let prossimo: Option<NaiveDateTime> = r.get(8)?;
        if prossimo.is_some_and(|p| p > adesso) {
            break;
        }
        eventi.push(Evento::da_riga(r)?);
    }
    Ok(eventi)
}

/// Un evento qualsiasi, replicato o no.
pub fn evento(conn: &Connection, id: i64) -> Result<Evento, ErroreDb> {
    let mut stmt = conn.prepare_cached(&format!("SELECT {COLONNE} FROM outbox_eventi WHERE id = ?1"))?;
    let mut righe = stmt.query([id])?;
    match righe.next()? {
        Some(r) => Evento::da_riga(r),
        None => Err(ErroreDb::NonTrovato(format!("evento {id}"))),
    }
}

/// Segna l'evento come replicato, con l'identità della testata in Arca.
pub fn segna_replicato(conn: &Connection, id: i64, arca_id_testata: i32, adesso: NaiveDateTime) -> Result<(), ErroreDb> {
    let n = conn.execute(
        "UPDATE outbox_eventi SET replicato_il = ?2, arca_id_testata = ?3, tentativi = tentativi + 1, \
         prossimo_tentativo_il = NULL WHERE id = ?1 AND replicato_il IS NULL",
        params![id, adesso, arca_id_testata],
    )?;
    if n == 0 {
        return Err(ErroreDb::NonTrovato(format!("evento {id} da replicare")));
    }
    Ok(())
}

/// Registra un tentativo fallito e rinvia l'evento.
pub fn segna_fallito(conn: &Connection, id: i64, errore: &str, prossimo_tentativo: NaiveDateTime) -> Result<(), ErroreDb> {
    let n = conn.execute(
        "UPDATE outbox_eventi SET tentativi = tentativi + 1, ultimo_errore = ?2, prossimo_tentativo_il = ?3 \
         WHERE id = ?1 AND replicato_il IS NULL",
        params![id, errore, prossimo_tentativo],
    )?;
    if n == 0 {
        return Err(ErroreDb::NonTrovato(format!("evento {id} da replicare")));
    }
    Ok(())
}

/// Eventi in attesa di replica: lo stato che il backend mostra all'operatore.
pub fn in_attesa(conn: &Connection) -> Result<i64, ErroreDb> {
    Ok(conn.query_row("SELECT count(*) FROM outbox_eventi WHERE replicato_il IS NULL", [], |r| r.get(0))?)
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::{Duration, NaiveDate};

    fn alle(ora: u32) -> NaiveDateTime {
        NaiveDate::from_ymd_opt(2026, 10, 22).unwrap().and_hms_opt(ora, 0, 0).unwrap()
    }

    fn coda(n: i64) -> Connection {
        let conn = crate::apri_in_memoria().unwrap();
        for documento in 1..=n {
            accoda(&conn, "BO", documento, Operazione::Crea, "{}", alle(8)).unwrap();
        }
        conn
    }

    #[test]
    fn eventi_in_ordine_e_replicati_escono_dalla_coda() {
        let conn = coda(3);
        let eventi = da_replicare(&conn, alle(9), 10).unwrap();
        assert_eq!(eventi.iter().map(|e| e.documento_id).collect::<Vec<_>>(), [1, 2, 3]);
        segna_replicato(&conn, eventi[0].id, 120545, alle(9)).unwrap();
        assert_eq!(da_replicare(&conn, alle(9), 10).unwrap().len(), 2);
        assert_eq!(in_attesa(&conn).unwrap(), 2);
        assert!(segna_replicato(&conn, eventi[0].id, 1, alle(9)).is_err(), "già replicato");
    }

    #[test]
    fn evento_fallito_blocca_i_successivi_fino_alla_riprova() {
        let conn = coda(2);
        let primo = da_replicare(&conn, alle(9), 10).unwrap()[0].id;
        segna_fallito(&conn, primo, "SQL Server non raggiungibile", alle(9) + Duration::minutes(1)).unwrap();
        assert!(da_replicare(&conn, alle(9), 10).unwrap().is_empty());
        let eventi = da_replicare(&conn, alle(10), 10).unwrap();
        assert_eq!(eventi.len(), 2);
        assert_eq!((eventi[0].tentativi, eventi[0].ultimo_errore.as_deref()), (1, Some("SQL Server non raggiungibile")));
    }

    #[test]
    fn payload_non_json_rifiutato_dallo_schema() {
        let conn = crate::apri_in_memoria().unwrap();
        assert!(accoda(&conn, "BO", 1, Operazione::Crea, "non json", alle(8)).is_err());
        assert!(accoda(&conn, "FT", 1, Operazione::Crea, "{}", alle(8)).is_err(), "tipo non replicabile");
    }
}
