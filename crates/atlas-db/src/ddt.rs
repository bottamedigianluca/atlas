//! DDT di vendita nel database ATLAS.
//!
//! [`crea`] e [`salva`] registrano testata, righe e l'evento di replica in un'unica transazione:
//! o il DDT esiste ed è in coda per Arca, o non esiste affatto. [`crea`] gli dà il numero che gli
//! darebbe Arca. [`importa`] registra un documento letto da Arca, senza evento. Quantità e totali
//! sono calcolati qui con `atlas-core`, sulle aliquote del database.

use atlas_core::aliquota::CodiceAliquota;
use atlas_core::ddt::{Ddt, RigaDdt};
use atlas_core::importo::Limitato;
use atlas_core::iva::Castelletto;
use atlas_core::numerazione::Numeri;
use atlas_core::riga::{Pesata, RigaMerce, Sconto};
use chrono::{Datelike, NaiveDateTime, Timelike};
use rusqlite::types::ToSql;
use rusqlite::{Connection, ErrorCode, OptionalExtension, TransactionBehavior, ffi, params};
use rust_decimal::Decimal;

use crate::anagrafiche::tabella_aliquote;
use crate::numerazione::{self, SEZIONALE_DDT};
use crate::outbox::{self, Operazione};
use crate::valori::Dec;
use crate::ErroreDb;

/// Tipo documento di Arca dei DDT di vendita.
pub const TIPO_DOCUMENTO: &str = "BO";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DdtSalvato {
    pub id: i64,
    /// Evento di replica accodato con il documento.
    pub evento: i64,
}

struct RigaCalcolata {
    quantita: Decimal,
    totale: Decimal,
}

fn calcola(riga: &RigaDdt) -> Result<RigaCalcolata, ErroreDb> {
    let quantita = riga.quantita();
    let merce = RigaMerce {
        quantita: Limitato::nuovo("quantità", quantita)?,
        prezzo_unitario: Limitato::nuovo("prezzo", riga.prezzo_unitario)?,
        prezzo_addizionale: Limitato::ZERO,
        sconto: Sconto::da_testi(&riga.sconto_riga, &riga.sconto_addizionale)?,
        aliquota: Some(riga.aliquota.clone()),
    };
    Ok(RigaCalcolata {
        quantita,
        totale: merce.totale(),
    })
}

/// Righe e castelletto del documento, sulle aliquote del database.
struct Calcolo {
    righe: Vec<RigaCalcolata>,
    castelletto: Castelletto,
}

impl Calcolo {
    fn nuovo(conn: &Connection, ddt: &Ddt) -> Result<Self, ErroreDb> {
        let righe = ddt.righe.iter().map(calcola).collect::<Result<Vec<_>, _>>()?;
        let castelletto = Castelletto::calcola(
            ddt.righe.iter().zip(&righe).map(|(r, c)| (&r.aliquota, c.totale)),
            &tabella_aliquote(conn)?,
        )?;
        Ok(Self { righe, castelletto })
    }
}

/// Il documento deve avere una sola forma possibile, quella che Arca registra e restituisce: la
/// replica riconosce un documento già scritto rileggendolo da Arca e confrontandolo con l'evento.
/// - Istanti al minuto: `TimeIns` e `TrasportoDataora` sono `smalldatetime` e SQL Server
///   arrotonderebbe i secondi.
/// - Quantità forzata solo se diversa dal netto della pesata: Arca registra soltanto `Qta`.
fn controlla_forma(ddt: &Ddt) -> Result<(), ErroreDb> {
    if ddt.righe.is_empty() {
        return Err(ErroreDb::DocumentoNonValido("nessuna riga".into()));
    }
    let al_minuto = |t: &NaiveDateTime| t.second() == 0 && t.nanosecond() == 0;
    if !al_minuto(&ddt.registrato_il) || !ddt.inizio_trasporto.as_ref().is_none_or(al_minuto) {
        return Err(ErroreDb::DocumentoNonValido("istanti con i secondi: Arca li registra al minuto".into()));
    }
    for (n, riga) in (1..).zip(&ddt.righe) {
        if riga.quantita_forzata == Some(riga.pesata.netto()) {
            return Err(ErroreDb::DocumentoNonValido(format!("riga {n}: quantità forzata uguale al netto della pesata")));
        }
    }
    Ok(())
}

/// `?20` è `arca_id_testata`.
const INSERISCI_TESTATA: &str = "INSERT INTO ddt (esercizio, numero, data, cliente, destinazione, sede, pagamento, \
    listino_cliente, iban, bic, conto_banca, agente, inizio_trasporto, scissione_pagamenti, operatore, registrato_il, \
    totale_imponibile, totale_imposta, totale_documento, arca_id_testata) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, \
    ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17, ?18, ?19, ?20)";

/// `?20` è l'`id` del documento.
const AGGIORNA_TESTATA: &str = "UPDATE ddt SET esercizio = ?1, numero = ?2, data = ?3, cliente = ?4, \
    destinazione = ?5, sede = ?6, pagamento = ?7, listino_cliente = ?8, iban = ?9, bic = ?10, conto_banca = ?11, \
    agente = ?12, inizio_trasporto = ?13, scissione_pagamenti = ?14, operatore = ?15, registrato_il = ?16, \
    totale_imponibile = ?17, totale_imposta = ?18, totale_documento = ?19 WHERE id = ?20";

/// Esegue [`INSERISCI_TESTATA`] o [`AGGIORNA_TESTATA`]; un numero già usato nell'esercizio è
/// [`ErroreDb::NumeroOccupato`].
fn scrivi_testata(conn: &Connection, sql: &str, ddt: &Ddt, totali: &Castelletto, ultimo: &dyn ToSql) -> Result<(), ErroreDb> {
    let esercizio = ddt.data.year();
    conn.prepare_cached(sql)?
        .execute(params![
            esercizio,
            ddt.numero,
            ddt.data,
            ddt.cliente,
            ddt.destinazione,
            ddt.sede,
            ddt.pagamento,
            ddt.listino_cliente,
            ddt.iban,
            ddt.bic,
            ddt.conto_banca,
            ddt.agente,
            ddt.inizio_trasporto,
            ddt.scissione_pagamenti,
            ddt.operatore,
            ddt.registrato_il,
            Dec(totali.totale_imponibile),
            Dec(totali.totale_imposta),
            Dec(totali.totale_documento),
            ultimo,
        ])
        .map_err(|e| match e.sqlite_error_code() {
            Some(ErrorCode::ConstraintViolation) if e.to_string().contains("ddt.numero") => ErroreDb::NumeroOccupato {
                esercizio,
                numero: ddt.numero,
            },
            _ => riferimenti(e, ddt),
        })?;
    Ok(())
}

/// Un codice del documento senza anagrafica diventa [`ErroreDb::RiferimentiInesistenti`].
fn riferimenti(e: rusqlite::Error, ddt: &Ddt) -> ErroreDb {
    match e.sqlite_error() {
        Some(f) if f.extended_code == ffi::SQLITE_CONSTRAINT_FOREIGNKEY => ErroreDb::RiferimentiInesistenti(format!(
            "un codice del DDT {}/{} non è nelle anagrafiche",
            ddt.numero,
            ddt.data.year()
        )),
        _ => e.into(),
    }
}

fn inserisci_righe(conn: &Connection, id: i64, ddt: &Ddt, calcolate: &[RigaCalcolata]) -> Result<(), ErroreDb> {
    let mut inserisci = conn.prepare_cached(
        "INSERT INTO ddt_righe (ddt, riga, articolo, descrizione, unita_misura, fattore_um1, conto_ricavo, aliquota, \
         id_listino_articolo, colli, lordo, tara_per_collo, quantita_forzata, quantita, prezzo_unitario, sconto_riga, \
         sconto_addizionale, magazzino, totale) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, \
         ?16, ?17, ?18, ?19)",
    )?;
    for (numero, (r, c)) in (1_i64..).zip(ddt.righe.iter().zip(calcolate)) {
        inserisci
            .execute(params![
                id,
                numero,
                r.articolo,
                r.descrizione,
                r.unita_misura,
                Dec(r.fattore_um1),
                r.conto_ricavo,
                r.aliquota.as_str(),
                r.id_listino_articolo,
                Dec(r.pesata.colli()),
                Dec(r.pesata.lordo()),
                Dec(r.pesata.tara_per_collo()),
                r.quantita_forzata.map(Dec),
                Dec(c.quantita),
                Dec(r.prezzo_unitario),
                r.sconto_riga,
                r.sconto_addizionale,
                r.magazzino,
                Dec(c.totale),
            ])
            .map_err(|e| riferimenti(e, ddt))?;
    }
    Ok(())
}

/// Nuovo documento con le sue righe; `arca_id_testata` se viene da Arca.
fn inserisci(conn: &Connection, ddt: &Ddt, arca_id_testata: Option<i32>) -> Result<i64, ErroreDb> {
    let calcolo = Calcolo::nuovo(conn, ddt)?;
    scrivi_testata(conn, INSERISCI_TESTATA, ddt, &calcolo.castelletto, &arca_id_testata)?;
    let id = conn.last_insert_rowid();
    inserisci_righe(conn, id, ddt, &calcolo.righe)?;
    Ok(id)
}

/// Numeri occupati nell'esercizio del DDT: quelli del database ATLAS e quelli di `arca`.
fn numeri(conn: &Connection, ddt: &Ddt, arca: &Numeri) -> Result<Numeri, ErroreDb> {
    let mut numeri = numerazione::occupati(conn, SEZIONALE_DDT, ddt.data.year())?;
    numeri.unisci(arca);
    Ok(numeri)
}

/// Scrive un nuovo DDT nato in ATLAS con il suo evento di replica.
fn inserisci_e_accoda(conn: &Connection, ddt: &Ddt, adesso: NaiveDateTime) -> Result<DdtSalvato, ErroreDb> {
    let payload = serde_json::to_string(ddt)?;
    let id = inserisci(conn, ddt, None)?;
    let evento = outbox::accoda(conn, TIPO_DOCUMENTO, id, Operazione::Crea, &payload, adesso)?;
    Ok(DdtSalvato { id, evento })
}

/// Salva un nuovo DDT con il numero che porta e accoda la sua replica in Arca. Il numero deve
/// essere libero anche fra i documenti di Arca che ATLAS non sa rappresentare, e rispettare
/// l'ordine delle date se il sezionale lo chiede.
pub fn salva(conn: &mut Connection, ddt: &Ddt, adesso: NaiveDateTime) -> Result<DdtSalvato, ErroreDb> {
    controlla_forma(ddt)?;
    let tx = conn.transaction_with_behavior(TransactionBehavior::Immediate)?;
    numerazione::vicini(&tx, SEZIONALE_DDT, ddt.data.year(), ddt.numero)?
        .verifica(SEZIONALE_DDT.regola(), ddt.numero, ddt.data)
        .map_err(|e| numerazione::errore(e, ddt.data.year()))?;
    let salvato = inserisci_e_accoda(&tx, ddt, adesso)?;
    tx.commit()?;
    Ok(salvato)
}

/// Salva un nuovo DDT con il numero che gli darebbe Arca, scritto in `ddt.numero`, e accoda la
/// sua replica.
///
/// Il numero si calcola nella transazione che scrive il documento (nessun altro salvataggio
/// ATLAS può prenderlo nel frattempo) sui documenti del database ATLAS e su `arca`: i numeri
/// letti da Arca appena prima, vuoto se Arca non risponde. Resta la finestra fra quella lettura
/// e la replica: se Arca nel frattempo usa lo stesso numero, replica e importazione si fermano
/// su [`ErroreDb::NumeroOccupato`] e il documento va rinumerato ([`rinumera`]).
pub fn crea(conn: &mut Connection, ddt: &mut Ddt, arca: &Numeri, adesso: NaiveDateTime) -> Result<DdtSalvato, ErroreDb> {
    controlla_forma(ddt)?;
    let tx = conn.transaction_with_behavior(TransactionBehavior::Immediate)?;
    ddt.numero = numeri(&tx, ddt, arca)?
        .prossimo(SEZIONALE_DDT.regola(), ddt.data)
        .map_err(|e| numerazione::errore(e, ddt.data.year()))?;
    let salvato = inserisci_e_accoda(&tx, ddt, adesso)?;
    tx.commit()?;
    Ok(salvato)
}

/// Dà il prossimo numero (sui documenti ATLAS e su `arca`) a un DDT nato in ATLAS e non ancora
/// in Arca, il cui numero è stato preso in Arca da un altro documento. Gli eventi in coda del
/// documento portano il nuovo numero e si possono replicare subito. Restituisce il nuovo numero.
///
/// Un documento già in Arca non si rinumera da qui: lì è la sua identità.
pub fn rinumera(conn: &mut Connection, id: i64, arca: &Numeri) -> Result<u32, ErroreDb> {
    let tx = conn.transaction_with_behavior(TransactionBehavior::Immediate)?;
    let in_arca: Option<i32> = tx
        .query_row("SELECT arca_id_testata FROM ddt WHERE id = ?1", [id], |r| r.get(0))
        .optional()?
        .ok_or_else(|| ErroreDb::NonTrovato(format!("DDT {id}")))?;
    let mut documento = carica(&tx, id)?;
    if in_arca.is_some() {
        return Err(ErroreDb::DocumentoNonValido(format!(
            "il DDT {} è già in Arca: il numero si cambia lì",
            documento.numero
        )));
    }
    documento.numero = numeri(&tx, &documento, arca)?
        .prossimo(SEZIONALE_DDT.regola(), documento.data)
        .map_err(|e| numerazione::errore(e, documento.data.year()))?;
    tx.execute("UPDATE ddt SET numero = ?2 WHERE id = ?1", params![id, documento.numero])?;
    tx.execute(
        "UPDATE outbox_eventi SET payload = ?3, prossimo_tentativo_il = NULL \
         WHERE documento_tipo = ?1 AND documento_id = ?2 AND replicato_il IS NULL",
        params![TIPO_DOCUMENTO, id, serde_json::to_string(&documento)?],
    )?;
    tx.commit()?;
    Ok(documento.numero)
}

/// Come è entrato nel database ATLAS un documento letto da Arca. Il valore è l'`id` in ATLAS.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Importato {
    Nuovo(i64),
    /// Già importato, con un contenuto diverso: ora è quello di Arca.
    Aggiornato(i64),
    Invariato(i64),
    /// Nato in ATLAS e già scritto in Arca, ma la replica non ne aveva ancora registrato l'esito.
    Collegato(i64),
}

/// Registra un documento letto da Arca, senza accodarne la replica. Va chiamata in una
/// transazione: dopo un errore il documento può essere scritto a metà.
///
/// Il documento si riconosce dal suo `Id_DoTes`. Altrimenti è nuovo, salvo che il suo numero sia
/// già di un documento ATLAS: se è lo stesso documento (nato in ATLAS e replicato) viene
/// collegato, se è un altro il numero è conteso ([`ErroreDb::NumeroOccupato`]) e non si scrive
/// nulla: mai due DDT con lo stesso numero.
pub fn importa(conn: &Connection, ddt: &Ddt, arca_id_testata: i32) -> Result<Importato, ErroreDb> {
    controlla_forma(ddt)?;
    let gia_importato: Option<i64> = conn
        .prepare_cached("SELECT id FROM ddt WHERE arca_id_testata = ?1")?
        .query_row([arca_id_testata], |r| r.get(0))
        .optional()?;
    if let Some(id) = gia_importato {
        if carica(conn, id)? == *ddt {
            return Ok(Importato::Invariato(id));
        }
        let calcolo = Calcolo::nuovo(conn, ddt)?;
        scrivi_testata(conn, AGGIORNA_TESTATA, ddt, &calcolo.castelletto, &id)?;
        conn.prepare_cached("DELETE FROM ddt_righe WHERE ddt = ?1")?.execute([id])?;
        inserisci_righe(conn, id, ddt, &calcolo.righe)?;
        return Ok(Importato::Aggiornato(id));
    }

    let stesso_numero: Option<(i64, Option<i32>)> = conn
        .prepare_cached("SELECT id, arca_id_testata FROM ddt WHERE esercizio = ?1 AND numero = ?2")?
        .query_row(params![ddt.data.year(), ddt.numero], |r| Ok((r.get(0)?, r.get(1)?)))
        .optional()?;
    match stesso_numero {
        None => Ok(Importato::Nuovo(inserisci(conn, ddt, Some(arca_id_testata))?)),
        Some((id, None)) if carica(conn, id)? == *ddt => {
            conn.prepare_cached("UPDATE ddt SET arca_id_testata = ?2 WHERE id = ?1")?
                .execute(params![id, arca_id_testata])?;
            Ok(Importato::Collegato(id))
        }
        Some(_) => Err(ErroreDb::NumeroOccupato {
            esercizio: ddt.data.year(),
            numero: ddt.numero,
        }),
    }
}

/// Totali calcolati al salvataggio.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Totali {
    pub imponibile: Decimal,
    pub imposta: Decimal,
    pub documento: Decimal,
}

pub fn totali(conn: &Connection, id: i64) -> Result<Totali, ErroreDb> {
    conn.query_row(
        "SELECT totale_imponibile, totale_imposta, totale_documento FROM ddt WHERE id = ?1",
        [id],
        |r| {
            Ok(Totali {
                imponibile: r.get::<_, Dec>(0)?.0,
                imposta: r.get::<_, Dec>(1)?.0,
                documento: r.get::<_, Dec>(2)?.0,
            })
        },
    )
    .optional()?
    .ok_or_else(|| ErroreDb::NonTrovato(format!("DDT {id}")))
}

/// Rilegge un DDT come era stato salvato.
pub fn carica(conn: &Connection, id: i64) -> Result<Ddt, ErroreDb> {
    let mut ddt = conn
        .query_row(
            "SELECT numero, data, cliente, destinazione, sede, pagamento, listino_cliente, iban, bic, conto_banca, agente, \
             inizio_trasporto, scissione_pagamenti, operatore, registrato_il FROM ddt WHERE id = ?1",
            [id],
            |r| {
                Ok(Ddt {
                    numero: r.get(0)?,
                    data: r.get(1)?,
                    cliente: r.get(2)?,
                    destinazione: r.get(3)?,
                    sede: r.get(4)?,
                    pagamento: r.get(5)?,
                    listino_cliente: r.get(6)?,
                    iban: r.get(7)?,
                    bic: r.get(8)?,
                    conto_banca: r.get(9)?,
                    agente: r.get(10)?,
                    inizio_trasporto: r.get(11)?,
                    scissione_pagamenti: r.get(12)?,
                    operatore: r.get(13)?,
                    registrato_il: r.get(14)?,
                    righe: Vec::new(),
                })
            },
        )
        .optional()?
        .ok_or_else(|| ErroreDb::NonTrovato(format!("DDT {id}")))?;

    let mut stmt = conn.prepare_cached(
        "SELECT articolo, descrizione, unita_misura, fattore_um1, conto_ricavo, aliquota, id_listino_articolo, colli, \
         lordo, tara_per_collo, quantita_forzata, prezzo_unitario, sconto_riga, sconto_addizionale, magazzino \
         FROM ddt_righe WHERE ddt = ?1 ORDER BY riga",
    )?;
    let mut righe = stmt.query([id])?;
    while let Some(r) = righe.next()? {
        ddt.righe.push(RigaDdt {
            articolo: r.get(0)?,
            descrizione: r.get(1)?,
            unita_misura: r.get(2)?,
            fattore_um1: r.get::<_, Dec>(3)?.0,
            conto_ricavo: r.get(4)?,
            aliquota: CodiceAliquota::nuovo(&r.get::<_, String>(5)?),
            id_listino_articolo: r.get(6)?,
            pesata: Pesata::nuova(r.get::<_, Dec>(7)?.0, r.get::<_, Dec>(8)?.0, r.get::<_, Dec>(9)?.0)?,
            quantita_forzata: r.get::<_, Option<Dec>>(10)?.map(|d| d.0),
            prezzo_unitario: r.get::<_, Dec>(11)?.0,
            sconto_riga: r.get(12)?,
            sconto_addizionale: r.get(13)?,
            magazzino: r.get(14)?,
        });
    }
    Ok(ddt)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::prova::{adesso, database, ddt};
    use rust_decimal_macros::dec;

    #[test]
    fn salva_e_rilegge_lo_stesso_ddt_con_totali_del_motore() {
        let mut conn = database();
        let mut originale = ddt(5457);
        originale.righe[1].quantita_forzata = Some(dec!(0));
        let salvato = salva(&mut conn, &originale, adesso()).unwrap();
        assert_eq!(carica(&conn, salvato.id).unwrap(), originale);

        // BAN: 5,46 − 1 × 0,30 = 5,16 kg × 1,80 = 9,29; PIST forzato a 0.
        let (quantita, totale): (Dec, Dec) = conn
            .query_row("SELECT quantita, totale FROM ddt_righe WHERE ddt = ?1 AND riga = 1", [salvato.id], |r| {
                Ok((r.get(0)?, r.get(1)?))
            })
            .unwrap();
        assert_eq!((quantita.0, totale.0), (dec!(5.16), dec!(9.29)));
        let totali = totali(&conn, salvato.id).unwrap();
        assert_eq!((totali.imponibile, totali.imposta, totali.documento), (dec!(9.29), dec!(0.37), dec!(9.66)));
    }

    #[test]
    fn il_salvataggio_accoda_la_replica_con_il_documento_completo() {
        let mut conn = database();
        let originale = ddt(5457);
        let salvato = salva(&mut conn, &originale, adesso()).unwrap();
        let eventi = outbox::da_replicare(&conn, adesso(), 10).unwrap();
        assert_eq!(eventi.len(), 1);
        let evento = &eventi[0];
        assert_eq!((evento.id, evento.documento_id, evento.operazione), (salvato.evento, salvato.id, Operazione::Crea));
        assert_eq!(evento.ddt().unwrap(), originale);
        assert_eq!(outbox::evento(&conn, salvato.evento).unwrap(), *evento);
    }

    #[test]
    fn numero_occupato_non_lascia_ne_documento_ne_evento() {
        let mut conn = database();
        salva(&mut conn, &ddt(5457), adesso()).unwrap();
        let errore = salva(&mut conn, &ddt(5457), adesso()).unwrap_err();
        assert!(matches!(errore, ErroreDb::NumeroOccupato { esercizio: 2026, numero: 5457 }), "{errore}");
        let conta = |sql: &str| conn.query_row(sql, [], |r| r.get::<_, i64>(0)).unwrap();
        assert_eq!(conta("SELECT count(*) FROM ddt"), 1);
        assert_eq!(conta("SELECT count(*) FROM outbox_eventi"), 1);
    }

    #[test]
    fn riferimento_inesistente_annulla_documento_ed_evento() {
        let mut conn = database();
        let mut errato = ddt(5458);
        errato.righe[1].articolo = "NONESISTE".into();
        assert!(salva(&mut conn, &errato, adesso()).is_err());
        let mut errato = ddt(5459);
        errato.destinazione = Some("XXX".into());
        assert!(salva(&mut conn, &errato, adesso()).is_err());
        let conta = |sql: &str| conn.query_row(sql, [], |r| r.get::<_, i64>(0)).unwrap();
        assert_eq!(conta("SELECT count(*) FROM ddt") + conta("SELECT count(*) FROM outbox_eventi"), 0);
    }

    #[test]
    fn ddt_senza_righe_o_con_sconto_errato_rifiutato() {
        let mut conn = database();
        let mut vuoto = ddt(1);
        vuoto.righe.clear();
        assert!(matches!(salva(&mut conn, &vuoto, adesso()), Err(ErroreDb::DocumentoNonValido(_))));
        let mut sconto = ddt(2);
        sconto.righe[0].sconto_riga = "10++5".into();
        assert!(matches!(salva(&mut conn, &sconto, adesso()), Err(ErroreDb::Calcolo(_))));
    }

    #[test]
    fn documento_in_forma_diversa_da_quella_di_arca_rifiutato() {
        let mut conn = database();
        let mut secondi = ddt(1);
        secondi.registrato_il += chrono::Duration::seconds(30);
        let mut trasporto = ddt(2);
        trasporto.inizio_trasporto = Some(adesso() + chrono::Duration::seconds(1));
        let mut forzata = ddt(3);
        forzata.righe[0].quantita_forzata = Some(dec!(5.16));
        for errato in [secondi, trasporto, forzata] {
            assert!(matches!(salva(&mut conn, &errato, adesso()), Err(ErroreDb::DocumentoNonValido(_))));
        }
        assert_eq!(conn.query_row("SELECT count(*) FROM ddt", [], |r| r.get::<_, i64>(0)).unwrap(), 0);
    }

    fn conta(conn: &Connection, sql: &str) -> i64 {
        conn.query_row(sql, [], |r| r.get(0)).unwrap()
    }

    fn arca_id(conn: &Connection, id: i64) -> Option<i32> {
        conn.query_row("SELECT arca_id_testata FROM ddt WHERE id = ?1", [id], |r| r.get(0)).unwrap()
    }

    #[test]
    fn importazione_senza_evento_e_ripetuta_invariata() {
        let conn = database();
        let documento = ddt(5400);
        let Importato::Nuovo(id) = importa(&conn, &documento, 120000).unwrap() else { panic!() };
        assert_eq!(carica(&conn, id).unwrap(), documento);
        assert_eq!(arca_id(&conn, id), Some(120000));
        assert_eq!(totali(&conn, id).unwrap().documento, dec!(21.98));
        assert_eq!(importa(&conn, &documento, 120000).unwrap(), Importato::Invariato(id));
        assert_eq!(conta(&conn, "SELECT count(*) FROM outbox_eventi"), 0, "nessuna replica di ciò che viene da Arca");
    }

    #[test]
    fn documento_modificato_in_arca_aggiornato_con_i_totali() {
        let conn = database();
        let Importato::Nuovo(id) = importa(&conn, &ddt(5400), 120000).unwrap() else { panic!() };
        let mut modificato = ddt(5401);
        modificato.righe.truncate(1);
        modificato.righe[0].prezzo_unitario = dec!(2);
        assert_eq!(importa(&conn, &modificato, 120000).unwrap(), Importato::Aggiornato(id));
        assert_eq!(carica(&conn, id).unwrap(), modificato);
        // 5,16 kg × 2,00 = 10,32 + IVA 4% 0,41.
        assert_eq!(totali(&conn, id).unwrap().documento, dec!(10.73));
        assert_eq!(conta(&conn, "SELECT count(*) FROM ddt_righe"), 1);
    }

    #[test]
    fn documento_atlas_replicato_si_collega_invece_di_raddoppiare() {
        let mut conn = database();
        let documento = ddt(5458);
        let salvato = salva(&mut conn, &documento, adesso()).unwrap();
        assert_eq!(importa(&conn, &documento, 120546).unwrap(), Importato::Collegato(salvato.id));
        assert_eq!(arca_id(&conn, salvato.id), Some(120546));
        // La replica registra poi lo stesso esito.
        outbox::segna_replicato(&conn, salvato.evento, 120546, adesso()).unwrap();
        assert_eq!(conta(&conn, "SELECT count(*) FROM ddt"), 1);
    }

    #[test]
    fn la_replica_registra_l_identita_di_arca_nel_documento() {
        let mut conn = database();
        let salvato = salva(&mut conn, &ddt(5458), adesso()).unwrap();
        assert_eq!(arca_id(&conn, salvato.id), None);
        outbox::segna_replicato(&conn, salvato.evento, 120546, adesso()).unwrap();
        assert_eq!(arca_id(&conn, salvato.id), Some(120546));
        assert_eq!(importa(&conn, &ddt(5458), 120546).unwrap(), Importato::Invariato(salvato.id));
    }

    #[test]
    fn numero_conteso_non_scrive_nulla() {
        let mut conn = database();
        // DDT ATLAS non ancora replicato e, in Arca, un altro documento con lo stesso numero.
        let salvato = salva(&mut conn, &ddt(5459), adesso()).unwrap();
        let mut altro = ddt(5459);
        altro.cliente = "C000002".into();
        altro.destinazione = None;
        let errore = importa(&conn, &altro, 120600).unwrap_err();
        assert!(matches!(errore, ErroreDb::NumeroOccupato { esercizio: 2026, numero: 5459 }), "{errore}");
        // Un documento già importato che in Arca prende un numero occupato.
        let Importato::Nuovo(_) = importa(&conn, &altro_numero(&altro, 5460), 120601).unwrap() else { panic!() };
        let errore = importa(&conn, &altro_numero(&altro, 5459), 120601).unwrap_err();
        assert!(matches!(errore, ErroreDb::NumeroOccupato { numero: 5459, .. }), "{errore}");
        assert_eq!(carica(&conn, salvato.id).unwrap(), ddt(5459));
    }

    fn altro_numero(documento: &Ddt, numero: u32) -> Ddt {
        Ddt {
            numero,
            ..documento.clone()
        }
    }

    #[test]
    fn crea_numera_dopo_i_ddt_di_atlas_gli_esclusi_e_i_numeri_di_arca() {
        let mut conn = database();
        salva(&mut conn, &ddt(5457), adesso()).unwrap();
        let mut nuovo = ddt(0);
        let salvato = crea(&mut conn, &mut nuovo, &Numeri::default(), adesso()).unwrap();
        assert_eq!(nuovo.numero, 5458);
        assert_eq!(carica(&conn, salvato.id).unwrap(), nuovo);
        assert_eq!(outbox::evento(&conn, salvato.evento).unwrap().ddt().unwrap(), nuovo);

        crate::importazione::escludi(&conn, &escluso(5460), adesso()).unwrap();
        crea(&mut conn, &mut nuovo, &Numeri::default(), adesso()).unwrap();
        assert_eq!(nuovo.numero, 5461, "dopo il BF 5460 di Arca");

        let arca: Numeri = [(5470, nuovo.data)].into_iter().collect();
        crea(&mut conn, &mut nuovo, &arca, adesso()).unwrap();
        assert_eq!(nuovo.numero, 5471, "dopo il 5470 letto da Arca");
    }

    fn escluso(numero: u32) -> crate::importazione::Escluso {
        crate::importazione::Escluso {
            arca_id_testata: 120_000,
            tipo_documento: "BF".into(),
            sezionale: "D00".into(),
            esercizio: 2026,
            numero,
            data: ddt(0).data,
            motivo: "documento di un altro tipo".into(),
        }
    }

    #[test]
    fn salva_rifiuta_il_numero_di_un_documento_escluso() {
        let mut conn = database();
        crate::importazione::escludi(&conn, &escluso(5460), adesso()).unwrap();
        let errore = salva(&mut conn, &ddt(5460), adesso()).unwrap_err();
        assert!(matches!(errore, ErroreDb::NumeroOccupato { esercizio: 2026, numero: 5460 }), "{errore}");
        let errore = salva(&mut conn, &ddt(0), adesso()).unwrap_err();
        assert!(matches!(errore, ErroreDb::Numerazione(_)), "{errore}");
        assert_eq!(conn.query_row("SELECT count(*) FROM outbox_eventi", [], |r| r.get::<_, i64>(0)).unwrap(), 0);
    }

    #[test]
    fn rinumera_documento_e_eventi_in_coda_ma_non_documenti_gia_in_arca() {
        let mut conn = database();
        let conteso = salva(&mut conn, &ddt(5459), adesso()).unwrap();
        outbox::segna_fallito(&conn, conteso.evento, "DDT 5459/2026 già presente", adesso() + chrono::Duration::hours(1))
            .unwrap();
        // In Arca il 5459 è di un altro documento, e c'è già anche il 5460.
        let arca: Numeri = [(5459, ddt(0).data), (5460, ddt(0).data)].into_iter().collect();
        assert_eq!(rinumera(&mut conn, conteso.id, &arca).unwrap(), 5461);
        assert_eq!(carica(&conn, conteso.id).unwrap(), ddt(5461));
        let eventi = outbox::da_replicare(&conn, adesso(), 10).unwrap();
        assert_eq!(eventi.len(), 1, "di nuovo replicabile subito");
        assert_eq!(eventi[0].ddt().unwrap(), ddt(5461));

        outbox::segna_replicato(&conn, conteso.evento, 120_600, adesso()).unwrap();
        let errore = rinumera(&mut conn, conteso.id, &arca).unwrap_err();
        assert!(matches!(errore, ErroreDb::DocumentoNonValido(_)), "{errore}");
        assert!(matches!(rinumera(&mut conn, 999, &arca).unwrap_err(), ErroreDb::NonTrovato(_)));
    }

    #[test]
    fn codice_senza_anagrafica_descritto() {
        let conn = database();
        let mut errato = ddt(5400);
        errato.righe[0].articolo = "NONESISTE".into();
        let errore = importa(&conn, &errato, 120000).unwrap_err();
        assert!(matches!(errore, ErroreDb::RiferimentiInesistenti(_)), "{errore}");
    }
}
