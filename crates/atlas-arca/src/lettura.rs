//! Lettura di un BO nativo di Arca come DDT ATLAS: solo i dati che l'operatore batte o che
//! ATLAS prende dalle anagrafiche. Tutto il resto lo ricalcola la traduzione.
//!
//! L'importazione segue il sezionale dei BO e non il solo tipo `BO`: un documento di un altro
//! tipo sullo stesso sezionale (i `BF` del 2018-2019) ne occupa un numero, e ATLAS deve saperlo.

use std::collections::BTreeSet;

use crate::ErroreArca;
use crate::ddt::{Ddt, RigaDdt};
use crate::scrittura::Connessione;
use atlas_core::aliquota::CodiceAliquota;
use atlas_core::numerazione::{Numeri, Regola, Sezionale, TipoDocumento};
use atlas_core::riga::Pesata;
use chrono::{NaiveDate, NaiveDateTime};
use rust_decimal::Decimal;
use tiberius::{Query, Row};

/// Perché un documento del sezionale dei BO (`DOTes t`) non è rappresentabile come DDT ATLAS:
/// codice di [`motivo`], 0 se lo è. Nello storico 2018-2026 (49.789 documenti): 6 `BF`, e fra i
/// 49.783 BO 1 non esecutivo, 3 con spese, 6 con righe senza articolo, 1 con un suffisso nel
/// numero (`1/PA` del 2018, dalla migrazione dei dati: ha lo stesso `NumeroDocI` del BO 1/2018, e
/// ATLAS numera solo con l'intero).
const ESCLUSIONE: &str = "case when t.Cd_Do <> 'BO' then 5 when t.Esecutivo = 0 then 1 when t.RigheSpesa <> 0 then 2 \
    when exists (select 1 from DORig r where r.Id_DOTes = t.Id_DoTes and r.Cd_AR is null) then 3 \
    when ltrim(rtrim(t.NumeroDoc)) <> cast(t.NumeroDocI as varchar(20)) then 4 else 0 end";

fn motivo(esclusione: i32) -> Option<&'static str> {
    match esclusione {
        0 => None,
        1 => Some("documento non esecutivo"),
        2 => Some("righe di spesa"),
        3 => Some("righe senza articolo"),
        4 => Some("numero con suffisso"),
        5 => Some("tipo documento non gestito"),
        _ => Some("motivo sconosciuto"),
    }
}

/// Sezionale dei BO, quello che l'importazione tiene allineato.
const SEZIONALE_BO: Sezionale = TipoDocumento::BollaVendita.sezionale();

/// BO del periodo replicabili: esecutivi, senza spese e con articolo su ogni riga. Esclusi nel
/// 2026: 1 non esecutivo (98422), 1 con spesa e riga descrittiva (98113).
pub async fn documenti(conn: &mut Connessione, dal: NaiveDate, al: NaiveDate) -> Result<(Vec<i32>, usize), ErroreArca> {
    let sql = format!(
        "select t.Id_DoTes, {ESCLUSIONE} as Esclusione from DOTes t \
         where t.Cd_Do = 'BO' and t.DataDoc between '{}' and '{}' order by t.Id_DoTes",
        dal.format("%Y%m%d"),
        al.format("%Y%m%d")
    );
    let mut replicabili = Vec::new();
    let mut esclusi = 0;
    for row in conn.simple_query(sql).await?.into_first_result().await? {
        let id = intero(&row, "Id_DoTes")?;
        if motivo(intero(&row, "Esclusione")?).is_none() {
            replicabili.push(id);
        } else {
            esclusi += 1;
        }
    }
    Ok((replicabili, esclusi))
}

/// Documento del sezionale dei BO scritto in Arca dopo un certo punto della rowversion.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Modificato {
    pub id_testata: i32,
    /// `DOTes.Cd_Do`.
    pub tipo_documento: String,
    /// `DOTes.Ts`: la testata è l'ultima tabella che Arca scrive salvando un documento
    /// (`asp_Do_End`; vale per tutti i 6.584 documenti nativi del 2026), quindi cambia a ogni
    /// modifica di righe o totali.
    pub ts: i64,
    pub esercizio: i32,
    pub numero: u32,
    pub data: NaiveDate,
    /// Perché ATLAS non può ancora rappresentarlo.
    pub escluso: Option<&'static str>,
}

/// I primi `limite` documenti del sezionale dei BO con `Ts` successivo a `dopo`, in ordine di `Ts`.
///
/// Solo quelli sotto `MIN_ACTIVE_ROWVERSION()`: una transazione ancora aperta ha preso la sua
/// rowversion ma non è confermata, e se il punto la superasse il documento non verrebbe mai
/// letto. Sotto quella soglia ogni documento è confermato.
pub async fn modificati(conn: &mut Connessione, dopo: i64, limite: usize) -> Result<Vec<Modificato>, ErroreArca> {
    let mut query = Query::new(format!(
        "select top (@P2) t.Id_DoTes, t.Cd_Do, cast(t.Ts as bigint) as Ts, cast(t.EsAnno as int) as Esercizio, \
         t.NumeroDocI, t.DataDoc, {ESCLUSIONE} as Esclusione from DOTes t \
         where t.Cd_CN = @P3 and t.Ts > cast(@P1 as binary(8)) and t.Ts < min_active_rowversion() order by t.Ts"
    ));
    query.bind(dopo);
    query.bind(i64::try_from(limite).unwrap_or(i64::MAX));
    query.bind(SEZIONALE_BO.codice());
    let mut modificati = Vec::new();
    for row in query.query(conn).await?.into_first_result().await? {
        let numero = intero(&row, "NumeroDocI")?;
        modificati.push(Modificato {
            id_testata: intero(&row, "Id_DoTes")?,
            tipo_documento: obbligatorio(codice(&row, "Cd_Do")?, "Cd_Do")?,
            ts: obbligatorio(row.try_get::<i64, _>("Ts")?, "Ts")?,
            esercizio: intero(&row, "Esercizio")?,
            numero: u32::try_from(numero).map_err(|_| ErroreArca::DocumentoNonValido(format!("numero {numero}")))?,
            data: obbligatorio(data_ora(&row, "DataDoc")?, "DataDoc")?.date(),
            escluso: motivo(intero(&row, "Esclusione")?),
        });
    }
    Ok(modificati)
}

/// Quanti documenti ci sono in Arca sul sezionale dei BO e la somma dei loro `Id_DoTes`: se
/// coincide con quella dei documenti noti ad ATLAS non c'è nulla da cancellare e non serve
/// l'elenco (5 ms).
///
/// Senza snapshot (`READ_COMMITTED_SNAPSHOT` spento in Arca) la lettura aspetta le transazioni
/// aperte: una cancellazione poi annullata non viene mai vista.
pub async fn impronta(conn: &mut Connessione) -> Result<(i64, i64), ErroreArca> {
    let row = conn
        .simple_query(format!(
            "select count_big(*) as N, isnull(sum(cast(Id_DoTes as bigint)), 0) as Somma from DOTes where Cd_CN = '{}'",
            SEZIONALE_BO.codice()
        ))
        .await?
        .into_row()
        .await?
        .ok_or_else(|| ErroreArca::DocumentoNonValido("impronta dei BO vuota".into()))?;
    Ok((
        obbligatorio(row.try_get::<i64, _>("N")?, "N")?,
        obbligatorio(row.try_get::<i64, _>("Somma")?, "Somma")?,
    ))
}

/// `Id_DoTes` di tutti i documenti di Arca sul sezionale dei BO.
pub async fn identita(conn: &mut Connessione) -> Result<BTreeSet<i32>, ErroreArca> {
    let righe = conn
        .simple_query(format!("select Id_DoTes from DOTes where Cd_CN = '{}'", SEZIONALE_BO.codice()))
        .await?
        .into_first_result()
        .await?;
    righe.iter().map(|r| intero(r, "Id_DoTes")).collect()
}

/// Numeri occupati in Arca nel sezionale e nell'esercizio, con le date: 13-26 ms per un anno
/// intero sull'indice `IX_DoTes_Cover4NextNum`.
pub async fn numeri(conn: &mut Connessione, sezionale: Sezionale, esercizio: i32) -> Result<Numeri, ErroreArca> {
    let mut query = Query::new("select NumeroDocI, DataDoc from DOTes where Cd_CN = @P1 and EsAnno = @P2");
    query.bind(sezionale.codice());
    query.bind(esercizio);
    let mut numeri = Numeri::default();
    for row in query.query(conn).await?.into_first_result().await? {
        let numero = intero(&row, "NumeroDocI")?;
        numeri.aggiungi(
            u32::try_from(numero).map_err(|_| ErroreArca::DocumentoNonValido(format!("numero {numero}")))?,
            obbligatorio(data_ora(&row, "DataDoc")?, "DataDoc")?.date(),
        );
    }
    Ok(numeri)
}

/// Testata del documento che in Arca occupa un numero.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Testata {
    pub id_testata: i32,
    pub cliente: String,
    /// `TimeIns`.
    pub registrato_il: NaiveDateTime,
}

/// Il documento con questo numero nel sezionale e nell'esercizio, senza suffisso (come quelli
/// che scrive ATLAS).
pub async fn con_numero(
    conn: &mut Connessione,
    sezionale: Sezionale,
    esercizio: i32,
    numero: u32,
) -> Result<Option<Testata>, ErroreArca> {
    let mut query = Query::new(
        "select Id_DoTes, Cd_CF, TimeIns from DOTes where Cd_CN = @P1 and EsAnno = @P2 and NumeroDocI = @P3 \
         and ltrim(rtrim(NumeroDoc)) = cast(NumeroDocI as varchar(20))",
    );
    query.bind(sezionale.codice());
    query.bind(esercizio);
    query.bind(i64::from(numero));
    match query.query(conn).await?.into_row().await? {
        None => Ok(None),
        Some(row) => Ok(Some(Testata {
            id_testata: intero(&row, "Id_DoTes")?,
            cliente: obbligatorio(codice(&row, "Cd_CF")?, "Cd_CF")?,
            registrato_il: obbligatorio(data_ora(&row, "TimeIns")?, "TimeIns")?,
        })),
    }
}

/// La numerazione di Arca è quella che ATLAS riproduce: ogni tipo documento sul sezionale di
/// [`TipoDocumento::sezionale`], ogni sezionale con la regola di [`Sezionale::regola`]. Se in
/// Arca cambiano (configurazione o aggiornamento), ATLAS si ferma invece di numerare diverso.
pub async fn controlla_numerazione(conn: &mut Connessione) -> Result<(), ErroreArca> {
    let mut differenze = Vec::new();
    for tipo in TipoDocumento::TUTTI {
        let mut query = Query::new("select Cd_CN from DO where Cd_Do = @P1");
        query.bind(tipo.codice());
        let sezionale = match query.query(conn).await?.into_row().await? {
            Some(row) => codice(&row, "Cd_CN")?,
            None => None,
        };
        if sezionale.as_deref() != Some(tipo.sezionale().codice()) {
            differenze.push(format!("{tipo} sul sezionale {sezionale:?} invece di {}", tipo.sezionale().codice()));
        }
    }
    for sezionale in Sezionale::TUTTI {
        let mut query = Query::new("select NextNumAllaData from CN where Cd_CN = @P1");
        query.bind(sezionale.codice());
        let alla_data = match query.query(conn).await?.into_row().await? {
            Some(row) => row.try_get::<bool, _>("NextNumAllaData")?,
            None => None,
        };
        if alla_data != Some(sezionale.regola() == Regola::AllaData) {
            differenze.push(format!("sezionale {} con NextNumAllaData {alla_data:?}", sezionale.codice()));
        }
    }
    if differenze.is_empty() {
        Ok(())
    } else {
        Err(ErroreArca::Configurazione(format!("numerazione diversa da quella di ATLAS: {}", differenze.join("; "))))
    }
}

fn grezzo(row: &Row, colonna: &str) -> Result<Option<String>, ErroreArca> {
    Ok(row.try_get::<&str, _>(colonna)?.map(str::to_owned))
}

fn codice(row: &Row, colonna: &str) -> Result<Option<String>, ErroreArca> {
    Ok(grezzo(row, colonna)?.map(|s| s.trim().to_owned()))
}

fn obbligatorio<T>(valore: Option<T>, colonna: &str) -> Result<T, ErroreArca> {
    valore.ok_or_else(|| ErroreArca::DocumentoNonValido(format!("{colonna} vuota")))
}

fn intero(row: &Row, colonna: &str) -> Result<i32, ErroreArca> {
    obbligatorio(row.try_get::<i32, _>(colonna)?, colonna)
}

fn decimale(row: &Row, colonna: &str) -> Result<Decimal, ErroreArca> {
    Ok(row.try_get::<Decimal, _>(colonna)?.unwrap_or_default().normalize())
}

fn data_ora(row: &Row, colonna: &str) -> Result<Option<NaiveDateTime>, ErroreArca> {
    Ok(row.try_get::<NaiveDateTime, _>(colonna)?)
}

pub async fn carica(conn: &mut Connessione, id: i32) -> Result<Ddt, ErroreArca> {
    let testata = conn
        .simple_query(format!(
            "select NumeroDocI, DataDoc, Cd_CF, Cd_CFDest, Cd_CFSede, Cd_PG, Cd_LS_1, Iban, BicCode, Cd_CGConto_Banca, \
             Cd_Agente_1, TrasportoDataora, IvaSplit, UserIns, TimeIns from DOTes where Id_DoTes = {id}"
        ))
        .await?
        .into_row()
        .await?
        .ok_or_else(|| ErroreArca::DocumentoNonValido(format!("Id_DoTes {id} inesistente")))?;

    let mut righe = Vec::new();
    for row in conn
        .simple_query(format!(
            "select Qta, Cd_AR, Descrizione, Cd_ARMisura, FattoreToUM1, Cd_CGConto, Cd_Aliquota, Id_LSArticolo, xColli, xLordo, \
             xTara, PrezzoUnitarioV, ScontoRiga, ScontoAddizionale, Cd_MG_P from DORig where Id_DOTes = {id} order by Riga, Id_DORig"
        ))
        .await?
        .into_first_result()
        .await?
    {
        let pesata = Pesata::nuova(decimale(&row, "xColli")?, decimale(&row, "xLordo")?, decimale(&row, "xTara")?)?;
        let quantita = decimale(&row, "Qta")?;
        righe.push(RigaDdt {
            // Fino al 07/11/2018 Arca registrava il codice riempito a 20 caratteri (50.599 righe
            // di 4.469 BO): l'anagrafica ATLAS lo ha senza spazi.
            articolo: obbligatorio(codice(&row, "Cd_AR")?, "Cd_AR")?,
            descrizione: grezzo(&row, "Descrizione")?.unwrap_or_default(),
            unita_misura: obbligatorio(codice(&row, "Cd_ARMisura")?, "Cd_ARMisura")?,
            fattore_um1: decimale(&row, "FattoreToUM1")?,
            conto_ricavo: obbligatorio(codice(&row, "Cd_CGConto")?, "Cd_CGConto")?,
            aliquota: CodiceAliquota::nuovo(&obbligatorio(codice(&row, "Cd_Aliquota")?, "Cd_Aliquota")?),
            id_listino_articolo: row.try_get::<i32, _>("Id_LSArticolo")?,
            // La quantità nativa diventa un dato battuto solo dove la pesata non la spiega.
            quantita_forzata: (quantita != pesata.netto()).then_some(quantita),
            pesata,
            prezzo_unitario: decimale(&row, "PrezzoUnitarioV")?,
            sconto_riga: grezzo(&row, "ScontoRiga")?.unwrap_or_default(),
            sconto_addizionale: grezzo(&row, "ScontoAddizionale")?.unwrap_or_default(),
            magazzino: codice(&row, "Cd_MG_P")?,
        });
    }

    let numero = intero(&testata, "NumeroDocI")?;
    Ok(Ddt {
        numero: u32::try_from(numero).map_err(|_| ErroreArca::DocumentoNonValido(format!("numero {numero}")))?,
        data: obbligatorio(data_ora(&testata, "DataDoc")?, "DataDoc")?.date(),
        cliente: obbligatorio(codice(&testata, "Cd_CF")?, "Cd_CF")?,
        destinazione: codice(&testata, "Cd_CFDest")?,
        sede: codice(&testata, "Cd_CFSede")?,
        pagamento: codice(&testata, "Cd_PG")?,
        listino_cliente: codice(&testata, "Cd_LS_1")?,
        iban: grezzo(&testata, "Iban")?,
        bic: grezzo(&testata, "BicCode")?,
        conto_banca: codice(&testata, "Cd_CGConto_Banca")?,
        agente: codice(&testata, "Cd_Agente_1")?,
        inizio_trasporto: data_ora(&testata, "TrasportoDataora")?,
        scissione_pagamenti: testata.try_get::<bool, _>("IvaSplit")?.unwrap_or_default(),
        operatore: obbligatorio(grezzo(&testata, "UserIns")?, "UserIns")?,
        registrato_il: obbligatorio(data_ora(&testata, "TimeIns")?, "TimeIns")?,
        righe,
    })
}
