//! Apertura del database e migrazioni.
//!
//! Lo schema è versionato con `PRAGMA user_version`: la migrazione `n` porta il database dalla
//! versione `n - 1` alla `n`, in una transazione. Un database più recente del programma non
//! viene aperto.

use std::path::Path;
use std::time::Duration;

use rusqlite::{Connection, OpenFlags, TransactionBehavior};

use crate::ErroreDb;

const MIGRAZIONI: &[&str] = &[
    include_str!("../migrazioni/0001_iniziale.sql"),
    include_str!("../migrazioni/0002_importazione_arca.sql"),
    include_str!("../migrazioni/0003_numerazione.sql"),
    include_str!("../migrazioni/0004_prezzi_righe.sql"),
    include_str!("../migrazioni/0005_note.sql"),
    include_str!("../migrazioni/0006_anagrafiche_complete.sql"),
];

/// Attesa massima di un blocco tenuto da un'altra connessione prima di rispondere `SQLITE_BUSY`.
const ATTESA_BLOCCO: Duration = Duration::from_secs(5);

/// Apre (o crea) il database e lo porta all'ultima versione dello schema.
///
/// WAL lascia leggere mentre si scrive; `synchronous = FULL` rende durevole ogni commit anche
/// in caso di mancanza di corrente (con `NORMAL` si perderebbero gli ultimi documenti salvati).
pub fn apri(percorso: impl AsRef<Path>) -> Result<Connection, ErroreDb> {
    let mut conn = Connection::open(percorso)?;
    conn.pragma_update(None, "journal_mode", "WAL")?;
    imposta(&mut conn)?;
    Ok(conn)
}

/// Apre in sola lettura un database già all'ultima versione dello schema: le connessioni di
/// lettura del backend, accanto all'unica di scrittura (WAL lascia leggere mentre si scrive).
/// Non migra: un database di un'altra versione è rifiutato.
pub fn apri_lettura(percorso: impl AsRef<Path>) -> Result<Connection, ErroreDb> {
    let conn = Connection::open_with_flags(
        percorso,
        OpenFlags::SQLITE_OPEN_READ_ONLY | OpenFlags::SQLITE_OPEN_NO_MUTEX | OpenFlags::SQLITE_OPEN_URI,
    )?;
    conn.busy_timeout(ATTESA_BLOCCO)?;
    conn.pragma_update(None, "query_only", true)?;
    conn.pragma_update(None, "trusted_schema", false)?;
    let trovata: i64 = conn.pragma_query_value(None, "user_version", |r| r.get(0))?;
    if trovata != versione_schema() {
        return Err(ErroreDb::VersioneSconosciuta {
            trovata,
            nota: versione_schema(),
        });
    }
    Ok(conn)
}

/// Database vuoto in memoria con lo schema completo, per le prove.
pub fn apri_in_memoria() -> Result<Connection, ErroreDb> {
    let mut conn = Connection::open_in_memory()?;
    imposta(&mut conn)?;
    Ok(conn)
}

fn imposta(conn: &mut Connection) -> Result<(), ErroreDb> {
    conn.busy_timeout(ATTESA_BLOCCO)?;
    conn.pragma_update(None, "synchronous", "FULL")?;
    conn.pragma_update(None, "foreign_keys", true)?;
    conn.pragma_update(None, "trusted_schema", false)?;
    migra(conn)
}

/// Versione dello schema prodotta dall'ultima migrazione nota.
pub fn versione_schema() -> i64 {
    MIGRAZIONI.len() as i64
}

fn migra(conn: &mut Connection) -> Result<(), ErroreDb> {
    let tx = conn.transaction_with_behavior(TransactionBehavior::Immediate)?;
    let attuale: i64 = tx.pragma_query_value(None, "user_version", |r| r.get(0))?;
    let nota = versione_schema();
    if attuale > nota {
        return Err(ErroreDb::VersioneSconosciuta { trovata: attuale, nota });
    }
    for (versione, sql) in (1_i64..).zip(MIGRAZIONI).skip(attuale as usize) {
        tx.execute_batch(sql)?;
        tx.pragma_update(None, "user_version", versione)?;
    }
    tx.commit()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn schema_all_ultima_versione_e_chiavi_esterne_attive() {
        let conn = apri_in_memoria().unwrap();
        let versione: i64 = conn.pragma_query_value(None, "user_version", |r| r.get(0)).unwrap();
        assert_eq!(versione, versione_schema());
        let fk: bool = conn.pragma_query_value(None, "foreign_keys", |r| r.get(0)).unwrap();
        assert!(fk);
    }

    #[test]
    fn riapertura_non_rimigra_e_rifiuta_versioni_future() {
        let cartella = std::env::temp_dir().join(format!("atlas-db-prova-{}", std::process::id()));
        std::fs::create_dir_all(&cartella).unwrap();
        let file = cartella.join("atlas.sqlite");
        let _ = std::fs::remove_file(&file);
        drop(apri(&file).unwrap());
        let conn = apri(&file).unwrap();
        let modo: String = conn.pragma_query_value(None, "journal_mode", |r| r.get(0)).unwrap();
        assert_eq!(modo, "wal");
        conn.pragma_update(None, "user_version", versione_schema() + 1).unwrap();
        drop(conn);
        assert!(matches!(apri(&file), Err(ErroreDb::VersioneSconosciuta { .. })));
        let _ = std::fs::remove_dir_all(&cartella);
    }

    #[test]
    fn lettura_solo_su_database_alla_versione_e_senza_scrivere() {
        let cartella = std::env::temp_dir().join(format!("atlas-db-lettura-{}", std::process::id()));
        std::fs::create_dir_all(&cartella).unwrap();
        let file = cartella.join("atlas.sqlite");
        let _ = std::fs::remove_file(&file);
        let scrittura = apri(&file).unwrap();
        let lettura = apri_lettura(&file).unwrap();
        assert!(lettura.execute("DELETE FROM ddt", []).is_err());
        scrittura.pragma_update(None, "user_version", versione_schema() - 1).unwrap();
        assert!(matches!(apri_lettura(&file), Err(ErroreDb::VersioneSconosciuta { .. })));
        drop((scrittura, lettura));
        let _ = std::fs::remove_dir_all(&cartella);
    }

    #[test]
    fn migrazione_4_copia_data_e_cliente_nelle_righe() {
        let mut conn = Connection::open_in_memory().unwrap();
        for sql in &MIGRAZIONI[..3] {
            conn.execute_batch(sql).unwrap();
        }
        conn.pragma_update(None, "user_version", 3).unwrap();
        conn.execute_batch(
            "INSERT INTO unita_misura VALUES ('KG', 'KG');
             INSERT INTO aliquote VALUES ('04', 'IVA 4%', '4', NULL);
             INSERT INTO articoli VALUES ('BAN', 'BANANE', NULL, 'KG', NULL, NULL, 0);
             INSERT INTO clienti_fornitori (codice, ragione_sociale, cliente, fornitore, scissione_pagamenti, \
                 ente_pubblico, obsoleto) VALUES ('C000380', 'Cliente', 1, 0, 0, 0, 0);
             INSERT INTO ddt (id, esercizio, numero, data, cliente, scissione_pagamenti, operatore, registrato_il, \
                 totale_imponibile, totale_imposta, totale_documento) \
                 VALUES (1, 2026, 5457, '2026-10-22', 'C000380', 0, '190', '2026-10-22 08:00:00', '0', '0', '0');
             INSERT INTO ddt_righe (ddt, riga, articolo, descrizione, unita_misura, fattore_um1, conto_ricavo, aliquota, \
                 colli, lordo, tara_per_collo, quantita, prezzo_unitario, sconto_riga, sconto_addizionale, totale) \
                 VALUES (1, 1, 'BAN', 'BANANE', 'KG', '1', '07010101001', '04', '1', '2', '0', '2', '1', '', '', '2');",
        )
        .unwrap();
        imposta(&mut conn).unwrap();
        let riga = || -> (String, String) {
            conn.query_row("SELECT data, cliente FROM ddt_righe", [], |r| Ok((r.get(0)?, r.get(1)?))).unwrap()
        };
        assert_eq!(riga(), ("2026-10-22".to_owned(), "C000380".to_owned()));
        conn.execute("UPDATE ddt SET data = '2026-10-21' WHERE id = 1", []).unwrap();
        assert_eq!(riga().0, "2026-10-21", "il trigger segue la testata");
    }

    #[test]
    fn migrazione_2_porta_nei_ddt_l_identita_dei_documenti_gia_replicati() {
        // Database alla versione 1 con due DDT, il primo replicato.
        let mut conn = Connection::open_in_memory().unwrap();
        conn.execute_batch(MIGRAZIONI[0]).unwrap();
        conn.pragma_update(None, "user_version", 1).unwrap();
        conn.execute(
            "INSERT INTO clienti_fornitori (codice, ragione_sociale, cliente, fornitore, scissione_pagamenti, \
             ente_pubblico, obsoleto) VALUES ('C000380', 'Cliente', 1, 0, 0, 0, 0)",
            [],
        )
        .unwrap();
        for (id, numero) in [(1, 5457), (2, 5458)] {
            conn.execute(
                "INSERT INTO ddt (id, esercizio, numero, data, cliente, scissione_pagamenti, operatore, registrato_il, \
                 totale_imponibile, totale_imposta, totale_documento) \
                 VALUES (?1, 2026, ?2, '2026-10-22', 'C000380', 0, '190', '2026-10-22 08:00:00', '0', '0', '0')",
                [id, numero],
            )
            .unwrap();
        }
        conn.execute_batch(
            "INSERT INTO outbox_eventi (documento_tipo, documento_id, operazione, payload, creato_il, replicato_il, \
             arca_id_testata) VALUES ('BO', 1, 'crea', '{}', '2026-10-22 08:00:00', '2026-10-22 08:00:01', 120545);
             INSERT INTO outbox_eventi (documento_tipo, documento_id, operazione, payload, creato_il) \
             VALUES ('BO', 2, 'crea', '{}', '2026-10-22 08:00:00');",
        )
        .unwrap();
        imposta(&mut conn).unwrap();
        let arca_id = |id: i64| -> Option<i32> {
            conn.query_row("SELECT arca_id_testata FROM ddt WHERE id = ?1", [id], |r| r.get(0)).unwrap()
        };
        assert_eq!((arca_id(1), arca_id(2)), (Some(120545), None));
    }

    #[test]
    fn migrazione_3_riparte_dall_inizio_con_gli_esclusi_da_rileggere() {
        let mut conn = Connection::open_in_memory().unwrap();
        conn.execute_batch(MIGRAZIONI[0]).unwrap();
        conn.execute_batch(MIGRAZIONI[1]).unwrap();
        conn.pragma_update(None, "user_version", 2).unwrap();
        conn.execute_batch(
            "INSERT INTO importazione_arca VALUES ('BO', 'ADB_BOTTAMEDI_DEV', 78758209, '2026-10-22 08:00:00');
             INSERT INTO importazione_esclusi VALUES (98422, 'BO', 2026, 812, 'documento non esecutivo', '2026-10-22 08:00:00');",
        )
        .unwrap();
        imposta(&mut conn).unwrap();
        let punto: (String, i64) = conn
            .query_row("SELECT database, ultimo_ts FROM importazione_arca", [], |r| Ok((r.get(0)?, r.get(1)?)))
            .unwrap();
        assert_eq!(punto, ("ADB_BOTTAMEDI_DEV".to_owned(), 0), "database legato conservato");
        let esclusi: i64 = conn.query_row("SELECT count(*) FROM importazione_esclusi", [], |r| r.get(0)).unwrap();
        assert_eq!(esclusi, 0);
    }
}
