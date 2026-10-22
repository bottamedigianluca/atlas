//! Verifica del database ATLAS sui documenti reali di Arca, senza scrivere nulla in Arca.
//!
//! `verifica-db [DAL] [AL] [FILE]`: importa le anagrafiche da `ATLAS_ARCA_ADO` in un database
//! ATLAS in memoria (o in `FILE`, che non deve esistere: misura i tempi reali su disco), poi salva ogni BO replicabile del periodo (predefinito: dal 1° gennaio dell'anno
//! scorso a oggi) con `atlas_db::ddt::salva` e controlla che:
//! - ogni riferimento del documento trovi la sua anagrafica (chiavi esterne);
//! - il DDT riletto e il documento nell'evento di replica coincidano con quello salvato;
//! - imponibile, imposta e totale calcolati coincidano con `DOTotali` di Arca.

use std::collections::{BTreeMap, HashMap};
use std::process::ExitCode;
use std::time::Instant;

use atlas_arca::{lettura, scrittura};
use atlas_db::{anagrafiche, ddt, outbox};
use atlas_sync::ErroreSync;
use atlas_sync::anagrafiche::leggi_anagrafiche;
use chrono::{Datelike, Local, NaiveDate};
use rust_decimal::Decimal;

#[derive(Debug, thiserror::Error)]
enum ErroreVerifica {
    #[error("variabile d'ambiente ATLAS_ARCA_ADO non impostata")]
    ConnessioneNonConfigurata,
    #[error("data non valida \"{0}\": formato atteso AAAA-MM-GG")]
    DataNonValida(String),
    #[error("{0} esiste già: la verifica scrive solo in un database nuovo")]
    FileEsistente(String),
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

fn data(argomento: Option<String>, predefinita: NaiveDate) -> Result<NaiveDate, ErroreVerifica> {
    match argomento {
        None => Ok(predefinita),
        Some(testo) => NaiveDate::parse_from_str(&testo, "%Y-%m-%d").map_err(|_| ErroreVerifica::DataNonValida(testo)),
    }
}

type Totali = (Decimal, Decimal, Decimal);

async fn totali_arca(
    conn: &mut scrittura::Connessione,
    dal: NaiveDate,
    al: NaiveDate,
) -> Result<HashMap<i32, Totali>, ErroreVerifica> {
    let sql = format!(
        "select t.Id_DoTes, o.TotImponibileV, o.TotImpostaV, o.TotDocumentoV from DOTes t \
         join DOTotali o on o.Id_DoTes = t.Id_DoTes where t.Cd_Do = 'BO' and t.DataDoc between '{}' and '{}'",
        dal.format("%Y%m%d"),
        al.format("%Y%m%d")
    );
    let mut totali = HashMap::new();
    for row in conn.simple_query(sql).await?.into_first_result().await? {
        let valore = |c: &str| -> Result<Decimal, tiberius::error::Error> { Ok(row.try_get::<Decimal, _>(c)?.unwrap_or_default()) };
        if let Some(id) = row.try_get::<i32, _>("Id_DoTes")? {
            totali.insert(id, (valore("TotImponibileV")?, valore("TotImpostaV")?, valore("TotDocumentoV")?));
        }
    }
    Ok(totali)
}

#[derive(Debug, Default)]
struct Riepilogo {
    documenti: usize,
    salvati: usize,
    rifiutati: BTreeMap<String, Vec<i32>>,
    riletti_diversi: Vec<i32>,
    payload_diversi: Vec<i32>,
    totali_diversi: Vec<(i32, Totali, Totali)>,
}

fn primi(ids: &[i32]) -> String {
    let elenco: Vec<String> = ids.iter().take(10).map(i32::to_string).collect();
    format!("{}{}", elenco.join(", "), if ids.len() > 10 { ", …" } else { "" })
}

async fn esegui() -> Result<bool, ErroreVerifica> {
    let mut argomenti = std::env::args().skip(1);
    let oggi = Local::now().date_naive();
    let inizio = NaiveDate::from_ymd_opt(oggi.year() - 1, 1, 1).unwrap_or(oggi);
    let dal = data(argomenti.next(), inizio)?;
    let al = data(argomenti.next(), oggi)?;
    let ado = std::env::var("ATLAS_ARCA_ADO").map_err(|_| ErroreVerifica::ConnessioneNonConfigurata)?;

    let partenza = Instant::now();
    let mut arca = scrittura::connetti(&ado).await?;
    let mut db = match argomenti.next() {
        None => atlas_db::apri_in_memoria()?,
        Some(file) if std::path::Path::new(&file).exists() => return Err(ErroreVerifica::FileEsistente(file)),
        Some(file) => atlas_db::apri(&file)?,
    };
    anagrafiche::aggiorna(&mut db, &leggi_anagrafiche(&mut arca).await?)?;
    let totali = totali_arca(&mut arca, dal, al).await?;
    let (documenti, esclusi) = lettura::documenti(&mut arca, dal, al).await?;

    let mut r = Riepilogo {
        documenti: documenti.len(),
        ..Riepilogo::default()
    };
    let mut tempo_salvataggio = std::time::Duration::ZERO;
    for id in documenti {
        let originale = lettura::carica(&mut arca, id).await?;
        let inizio_salvataggio = Instant::now();
        let esito = ddt::salva(&mut db, &originale, originale.registrato_il);
        tempo_salvataggio += inizio_salvataggio.elapsed();
        let salvato = match esito {
            Ok(salvato) => salvato,
            Err(e) => {
                r.rifiutati.entry(e.to_string()).or_default().push(id);
                continue;
            }
        };
        r.salvati += 1;
        if ddt::carica(&db, salvato.id)? != originale {
            r.riletti_diversi.push(id);
        }
        if outbox::evento(&db, salvato.evento)?.ddt().ok().as_ref() != Some(&originale) {
            r.payload_diversi.push(id);
        }
        let t = ddt::totali(&db, salvato.id)?;
        let calcolati: Totali = (t.imponibile, t.imposta, t.documento);
        let nativi = totali.get(&id).copied().unwrap_or_default();
        if calcolati != nativi {
            r.totali_diversi.push((id, nativi, calcolati));
        }
    }

    println!(
        "BO dal {dal} al {al}: {} replicabili ({esclusi} esclusi), in {:.1} s; salvataggio in ATLAS {:.2} ms per documento\n",
        r.documenti,
        partenza.elapsed().as_secs_f64(),
        tempo_salvataggio.as_secs_f64() * 1000.0 / r.salvati.max(1) as f64
    );
    println!("salvati in ATLAS        {:>6} / {}", r.salvati, r.documenti);
    println!("riletti identici        {:>6} / {}", r.salvati - r.riletti_diversi.len(), r.salvati);
    println!("evento outbox identico  {:>6} / {}", r.salvati - r.payload_diversi.len(), r.salvati);
    println!("totali come DOTotali    {:>6} / {}", r.salvati - r.totali_diversi.len(), r.salvati);
    for (errore, ids) in &r.rifiutati {
        println!("\nrifiutati ({}): {errore}\n  Id_DoTes {}", ids.len(), primi(ids));
    }
    if !r.riletti_diversi.is_empty() {
        println!("\nriletti diversi: Id_DoTes {}", primi(&r.riletti_diversi));
    }
    if !r.payload_diversi.is_empty() {
        println!("\nevento diverso: Id_DoTes {}", primi(&r.payload_diversi));
    }
    for (id, nativi, calcolati) in r.totali_diversi.iter().take(10) {
        println!("\ntotali Id_DoTes {id}: Arca {nativi:?} / ATLAS {calcolati:?}");
    }
    Ok(r.salvati == r.documenti
        && r.riletti_diversi.is_empty()
        && r.payload_diversi.is_empty()
        && r.totali_diversi.is_empty())
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
