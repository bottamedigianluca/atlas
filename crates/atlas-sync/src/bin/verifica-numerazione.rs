//! Confronta la numerazione di ATLAS con quella di Arca, sul database di `ATLAS_ARCA_ADO`.
//!
//! `verifica-numerazione [DB] [ANNO]`:
//! - per ogni sezionale ed esercizio di Arca, i buchi e il prossimo numero calcolati da ATLAS sui
//!   numeri letti da Arca contro le righe di `UnusedCodes_DoTes`, descrizione compresa;
//! - per ogni giorno di `ANNO` (l'anno in corso se manca), il prossimo numero contro
//!   `asp_NumDoc_Next`, rifiuti compresi (chiamata in una transazione annullata);
//! - con `DB`, i numeri occupati nel database ATLAS (BO importati e nati in ATLAS, documenti
//!   esclusi) contro quelli di Arca sul sezionale dei BO, esercizio per esercizio.
//!
//! Sola lettura. Esce con 1 se trova differenze.

use std::process::ExitCode;
use std::time::Instant;

use atlas_arca::lettura;
use atlas_arca::scrittura::{self, Connessione};
use atlas_core::numerazione::{Liberi, NumeroNonValido, Numeri, Sezionale};
use chrono::{Datelike, Local, NaiveDate};
use tiberius::Query;

#[derive(Debug, thiserror::Error)]
enum ErroreVerifica {
    #[error("variabile d'ambiente ATLAS_ARCA_ADO non impostata")]
    ConnessioneNonConfigurata,
    #[error("uso: verifica-numerazione [DB] [ANNO]")]
    Uso,
    #[error("{0} non esiste")]
    FileInesistente(String),
    #[error(transparent)]
    Arca(#[from] atlas_arca::ErroreArca),
    #[error(transparent)]
    Db(#[from] atlas_db::ErroreDb),
    #[error("SQL Server: {0}")]
    Sql(#[from] tiberius::error::Error),
}

fn giorno(data: NaiveDate) -> String {
    data.format("%d/%m/%Y").to_string()
}

/// Le righe che `UnusedCodes_DoTes` darebbe per questi numeri: numero e descrizione.
fn come_unused_codes(numeri: &Numeri, esercizio: i32) -> Vec<(u32, String)> {
    let mut righe: Vec<(u32, String)> = numeri
        .liberi()
        .iter()
        .map(|&Liberi { dal, al, data_dal, data_al }| {
            let inizio = data_dal.map_or_else(|| format!("01/01/{esercizio}"), giorno);
            let mut descrizione = format!("[{inizio}  {}]", giorno(data_al));
            if al > dal {
                descrizione += &format!("  {} numeri liberi (dal {dal} al {al})", al - dal + 1);
            }
            (dal, descrizione)
        })
        .collect();
    if let (Some(ultimo), Some(data)) = (numeri.numeri().last(), numeri.ultima_data()) {
        righe.push((ultimo + 1, format!("[{}  31/12/{esercizio}]  Prossimo valore disponibile", giorno(data))));
    }
    righe
}

async fn unused_codes(conn: &mut Connessione, sezionale: Sezionale, esercizio: i32) -> Result<Vec<(u32, String)>, ErroreVerifica> {
    // Contabile come lo passa la maschera di Arca (`fedi_doc`: DO.Contabile o CN.Tipo = 'A').
    let mut query = Query::new("select NumeroDoc, Descrizione from dbo.UnusedCodes_DoTes(@P1, @P2, @P3)");
    query.bind(sezionale == Sezionale::Fatture);
    query.bind(NaiveDate::from_ymd_opt(esercizio, 6, 1).and_then(|d| d.and_hms_opt(0, 0, 0)));
    query.bind(sezionale.codice());
    let mut righe = Vec::new();
    for row in query.query(conn).await?.into_first_result().await? {
        let numero = row.try_get::<&str, _>("NumeroDoc")?.unwrap_or_default().trim().parse().unwrap_or(0);
        let descrizione = row.try_get::<&str, _>("Descrizione")?.unwrap_or_default().trim_end().to_owned();
        righe.push((numero, descrizione));
    }
    Ok(righe)
}

/// `asp_NumDoc_Next` per ogni giorno dell'anno: data, numero proposto, messaggio d'errore.
async fn proposte_arca(
    conn: &mut Connessione,
    sezionale: Sezionale,
    anno: i32,
) -> Result<Vec<(NaiveDate, Option<u32>, Option<String>)>, ErroreVerifica> {
    let sql = format!(
        "set nocount on; set xact_abort off;
         declare @r table (d smalldatetime, n varchar(10), msg nvarchar(800));
         declare @d smalldatetime = '{anno}0101', @n varchar(10);
         begin tran;
         while year(@d) = {anno} begin
           set @n = null;
           begin try exec asp_NumDoc_Next '{cn}', @d, 1, @n output; insert @r values (@d, @n, null); end try
           begin catch insert @r values (@d, null, error_message()); end catch
           set @d = dateadd(day, 1, @d);
         end
         rollback;
         select d, n, msg from @r order by d;",
        cn = sezionale.codice()
    );
    let mut proposte = Vec::new();
    for row in conn.simple_query(sql).await?.into_first_result().await? {
        let data = row.try_get::<chrono::NaiveDateTime, _>("d")?.map(|d| d.date()).unwrap_or_default();
        let numero = row.try_get::<&str, _>("n")?.and_then(|n| n.trim().parse().ok());
        let messaggio = row.try_get::<&str, _>("msg")?.map(str::to_owned);
        proposte.push((data, numero, messaggio));
    }
    Ok(proposte)
}

/// Il numero citato nel rifiuto di Arca: "… per la data … sarebbe 4 ma questo numero è già …".
fn numero_rifiutato(messaggio: &str) -> Option<u32> {
    let dopo = messaggio.split("sarebbe ").nth(1)?;
    dopo.split_whitespace().next()?.parse().ok()
}

async fn esegui() -> Result<bool, ErroreVerifica> {
    let mut file = None;
    let mut anno = Local::now().year();
    for argomento in std::env::args().skip(1) {
        match argomento.parse::<i32>() {
            Ok(a) => anno = a,
            Err(_) if file.is_none() => file = Some(argomento),
            Err(_) => return Err(ErroreVerifica::Uso),
        }
    }
    let ado = std::env::var("ATLAS_ARCA_ADO").map_err(|_| ErroreVerifica::ConnessioneNonConfigurata)?;
    let partenza = Instant::now();
    let mut arca = scrittura::connetti(&ado).await?;
    lettura::controlla_numerazione(&mut arca).await?;
    let mut tutto_uguale = true;

    let mut esercizi = Vec::new();
    for row in arca
        .simple_query("select distinct Cd_CN, cast(EsAnno as int) as EsAnno from DOTes where Cd_CN in ('D00', '001')")
        .await?
        .into_first_result()
        .await?
    {
        let cn = row.try_get::<&str, _>("Cd_CN")?.unwrap_or_default().trim().to_owned();
        if let (Some(sezionale), Some(esercizio)) =
            (Sezionale::TUTTI.into_iter().find(|s| s.codice() == cn), row.try_get::<i32, _>("EsAnno")?)
        {
            esercizi.push((sezionale, esercizio));
        }
    }
    esercizi.sort();

    println!("buchi e prossimo numero contro UnusedCodes_DoTes:");
    let (mut righe, mut uguali) = (0, 0);
    for &(sezionale, esercizio) in &esercizi {
        let numeri = lettura::numeri(&mut arca, sezionale, esercizio).await?;
        let atlas = come_unused_codes(&numeri, esercizio);
        let arca_righe = unused_codes(&mut arca, sezionale, esercizio).await?;
        righe += arca_righe.len();
        uguali += arca_righe.iter().filter(|r| atlas.contains(r)).count();
        if atlas != arca_righe {
            tutto_uguale = false;
            let solo_arca: Vec<_> = arca_righe.iter().filter(|r| !atlas.contains(r)).take(3).collect();
            let solo_atlas: Vec<_> = atlas.iter().filter(|r| !arca_righe.contains(r)).take(3).collect();
            println!("  {} {esercizio}: solo Arca {solo_arca:?}, solo ATLAS {solo_atlas:?}", sezionale.codice());
        }
    }
    println!("  {uguali}/{righe} righe di Arca uguali, {} esercizi", esercizi.len());

    println!("prossimo numero per ogni giorno del {anno} contro asp_NumDoc_Next:");
    for sezionale in Sezionale::TUTTI {
        let numeri = lettura::numeri(&mut arca, sezionale, anno).await?;
        let (mut numeri_uguali, mut rifiuti_uguali, mut diversi) = (0, 0, Vec::new());
        let proposte = proposte_arca(&mut arca, sezionale, anno).await?;
        for (data, numero, messaggio) in &proposte {
            match (numeri.prossimo(sezionale.regola(), *data), numero, messaggio) {
                (Ok(n), Some(a), None) if n == *a => numeri_uguali += 1,
                (Err(NumeroNonValido::Occupato { numero: n, .. }), None, Some(m)) if numero_rifiutato(m) == Some(n) => {
                    rifiuti_uguali += 1;
                }
                (atlas, _, _) => diversi.push(format!("{}: ATLAS {atlas:?}, Arca {numero:?} {messaggio:?}", giorno(*data))),
            }
        }
        println!(
            "  {}: {numeri_uguali} numeri e {rifiuti_uguali} rifiuti uguali su {} giorni",
            sezionale.codice(),
            proposte.len()
        );
        for d in diversi.iter().take(5) {
            println!("    {d}");
        }
        tutto_uguale &= diversi.is_empty();
    }

    if let Some(file) = file {
        if !std::path::Path::new(&file).exists() {
            return Err(ErroreVerifica::FileInesistente(file));
        }
        let db = atlas_db::apri(&file)?;
        println!("numeri occupati nel database ATLAS contro Arca, sezionale D00:");
        let (mut esercizi_uguali, mut totale) = (0, 0);
        for &(sezionale, esercizio) in esercizi.iter().filter(|(s, _)| *s == Sezionale::Bolle) {
            totale += 1;
            let in_arca = lettura::numeri(&mut arca, sezionale, esercizio).await?;
            let in_atlas = atlas_db::numerazione::occupati(&db, sezionale, esercizio)?;
            if in_arca == in_atlas {
                esercizi_uguali += 1;
            } else {
                tutto_uguale = false;
                let solo_arca: Vec<u32> = in_arca.numeri().filter(|&n| !in_atlas.contiene(n)).take(10).collect();
                let solo_atlas: Vec<u32> = in_atlas.numeri().filter(|&n| !in_arca.contiene(n)).take(10).collect();
                println!("  {esercizio}: solo Arca {solo_arca:?}, solo ATLAS {solo_atlas:?} (o date diverse)");
            }
        }
        println!("  {esercizi_uguali}/{totale} esercizi uguali, date comprese");
    }
    println!("{:.1} s", partenza.elapsed().as_secs_f64());
    Ok(tutto_uguale)
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    match esegui().await {
        Ok(true) => ExitCode::SUCCESS,
        Ok(false) => ExitCode::FAILURE,
        Err(e) => {
            eprintln!("errore: {e}");
            ExitCode::from(2)
        }
    }
}
