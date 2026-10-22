//! Verifica un database ATLAS riempito da `importa-documenti` contro Arca, senza scrivere nulla.
//!
//! `verifica-importazione DB`: legge Arca da `ATLAS_ARCA_ADO` (lo stesso database a cui il file
//! è legato) e controlla che:
//! - ogni BO di Arca sia in ATLAS o tra gli esclusi, e che ATLAS non ne abbia altri;
//! - ogni BO importato, riletto ora da Arca, sia uguale a quello in ATLAS;
//! - imponibile, imposta e totale calcolati da ATLAS coincidano con `DOTotali`.

use std::collections::{BTreeSet, HashMap};
use std::process::ExitCode;
use std::time::Instant;

use atlas_arca::{lettura, scrittura};
use atlas_db::ddt::{self, TIPO_DOCUMENTO};
use atlas_db::importazione;
use atlas_sync::ErroreSync;
use rust_decimal::Decimal;

#[derive(Debug, thiserror::Error)]
enum ErroreVerifica {
    #[error("variabile d'ambiente ATLAS_ARCA_ADO non impostata")]
    ConnessioneNonConfigurata,
    #[error("uso: verifica-importazione DB")]
    Uso,
    #[error("{0} non esiste")]
    FileInesistente(String),
    #[error("il database ATLAS è legato a {legato:?}, la connessione porta a {trovato}")]
    AltroDatabase { legato: Option<String>, trovato: String },
    #[error(transparent)]
    Sync(#[from] ErroreSync),
}

impl From<atlas_arca::ErroreArca> for ErroreVerifica {
    fn from(e: atlas_arca::ErroreArca) -> Self {
        Self::Sync(e.into())
    }
}

impl From<atlas_db::ErroreDb> for ErroreVerifica {
    fn from(e: atlas_db::ErroreDb) -> Self {
        Self::Sync(e.into())
    }
}

impl From<tiberius::error::Error> for ErroreVerifica {
    fn from(e: tiberius::error::Error) -> Self {
        Self::Sync(e.into())
    }
}

type Totali = (Decimal, Decimal, Decimal);

/// Totali di Arca, e se l'imposta di Arca è diversa da imponibile × aliquota arrotondato al
/// centesimo in almeno un'aliquota del castelletto. Succede solo in 39 BO dal 21/09 al 02/11/2023
/// (su 734 del periodo, sempre di un centesimo): il castelletto lo calcola `asp_Do_End`, cifrata,
/// e la regola di quelle settimane non si ricostruisce. ATLAS calcola come negli altri 49.744.
async fn totali_arca(conn: &mut scrittura::Connessione) -> Result<HashMap<i32, (Totali, bool)>, ErroreVerifica> {
    let mut totali = HashMap::new();
    for row in conn
        .simple_query(
            "select t.Id_DoTes, o.TotImponibileV, o.TotImpostaV, o.TotDocumentoV, case when exists (select 1 from DOIva i \
               where i.Id_DOTes = t.Id_DoTes and i.ImpostaV <> round(i.ImponibileV * i.Aliquota / 100, 2)) \
               then 1 else 0 end as IvaIncoerente \
             from DOTes t join DOTotali o on o.Id_DoTes = t.Id_DoTes where t.Cd_Do = 'BO'",
        )
        .await?
        .into_first_result()
        .await?
    {
        let valore = |c: &str| -> Result<Decimal, tiberius::error::Error> { Ok(row.try_get::<Decimal, _>(c)?.unwrap_or_default()) };
        if let Some(id) = row.try_get::<i32, _>("Id_DoTes")? {
            let incoerente = row.try_get::<i32, _>("IvaIncoerente")? == Some(1);
            totali.insert(id, ((valore("TotImponibileV")?, valore("TotImpostaV")?, valore("TotDocumentoV")?), incoerente));
        }
    }
    Ok(totali)
}

fn primi(ids: &[i32]) -> String {
    let elenco: Vec<String> = ids.iter().take(10).map(i32::to_string).collect();
    format!("{}{}", elenco.join(", "), if ids.len() > 10 { ", …" } else { "" })
}

async fn esegui() -> Result<bool, ErroreVerifica> {
    let file = std::env::args().nth(1).ok_or(ErroreVerifica::Uso)?;
    if !std::path::Path::new(&file).exists() {
        return Err(ErroreVerifica::FileInesistente(file));
    }
    let ado = std::env::var("ATLAS_ARCA_ADO").map_err(|_| ErroreVerifica::ConnessioneNonConfigurata)?;
    let partenza = Instant::now();
    let mut arca = scrittura::connetti(&ado).await?;
    let database = scrittura::nome_database(&mut arca).await?;
    let db = atlas_db::apri(&file)?;
    let legato = importazione::punto(&db, TIPO_DOCUMENTO)?.map(|p| p.database);
    if legato.as_deref() != Some(database.as_str()) {
        return Err(ErroreVerifica::AltroDatabase { legato, trovato: database });
    }

    let presenti = lettura::identita(&mut arca).await?;
    let noti = importazione::noti(&db)?;
    let mancanti: Vec<i32> = presenti.difference(&noti).copied().collect();
    let in_piu: Vec<i32> = noti.difference(&presenti).copied().collect();
    let esclusi: BTreeSet<i32> = importazione::esclusi(&db)?.iter().map(|e| e.arca_id_testata).collect();

    let mut importati = Vec::new();
    {
        let mut stmt = db
            .prepare("SELECT id, arca_id_testata FROM ddt WHERE arca_id_testata IS NOT NULL ORDER BY arca_id_testata")
            .map_err(atlas_db::ErroreDb::from)?;
        let mut righe = stmt.query([]).map_err(atlas_db::ErroreDb::from)?;
        while let Some(r) = righe.next().map_err(atlas_db::ErroreDb::from)? {
            let coppia: (i64, i32) = (r.get(0).map_err(atlas_db::ErroreDb::from)?, r.get(1).map_err(atlas_db::ErroreDb::from)?);
            importati.push(coppia);
        }
    }
    let senza_arca: i64 = db
        .query_row("SELECT count(*) FROM ddt WHERE arca_id_testata IS NULL", [], |r| r.get(0))
        .map_err(atlas_db::ErroreDb::from)?;

    let totali = totali_arca(&mut arca).await?;
    let mut diversi = Vec::new();
    let mut totali_diversi = Vec::new();
    let mut iva_incoerente = Vec::new();
    for &(id, arca_id) in &importati {
        if esclusi.contains(&arca_id) {
            continue;
        }
        if lettura::carica(&mut arca, arca_id).await? != ddt::carica(&db, id)? {
            diversi.push(arca_id);
        }
        let t = ddt::totali(&db, id)?;
        let (nativi, incoerente) = totali.get(&arca_id).copied().unwrap_or_default();
        let calcolati = (t.imponibile, t.imposta, t.documento);
        if nativi == calcolati {
            continue;
        }
        if incoerente && nativi.0 == calcolati.0 && (nativi.1 - calcolati.1).abs() <= Decimal::new(1, 2) {
            iva_incoerente.push(arca_id);
        } else {
            if totali_diversi.len() < 5 {
                println!("totali Id_DoTes {arca_id}: Arca {nativi:?} / ATLAS {calcolati:?}");
            }
            totali_diversi.push(arca_id);
        }
    }
    let confrontati = importati.len() - importati.iter().filter(|(_, a)| esclusi.contains(a)).count();

    println!("BO di {database} in {file}, verificati in {:.1} s\n", partenza.elapsed().as_secs_f64());
    println!("BO in Arca                 {:>6}", presenti.len());
    println!("importati                  {:>6}", importati.len());
    println!("esclusi                    {:>6}", esclusi.len());
    println!("in Arca, ignoti ad ATLAS   {:>6}", mancanti.len());
    println!("in ATLAS, spariti da Arca  {:>6}", in_piu.len());
    println!("in ATLAS, non ancora in Arca {:>4}", senza_arca);
    println!("riletti identici           {:>6} / {confrontati}", confrontati - diversi.len());
    println!(
        "totali come DOTotali       {:>6} / {confrontati}",
        confrontati - totali_diversi.len() - iva_incoerente.len()
    );
    println!("  imposta di Arca fuori regola (2023, 1 cent) {}", iva_incoerente.len());
    for (titolo, ids) in [
        ("ignoti", &mancanti),
        ("spariti", &in_piu),
        ("diversi", &diversi),
        ("totali diversi", &totali_diversi),
    ] {
        if !ids.is_empty() {
            println!("\n{titolo}: Id_DoTes {}", primi(ids));
        }
    }
    Ok(mancanti.is_empty() && in_piu.is_empty() && diversi.is_empty() && totali_diversi.is_empty())
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
