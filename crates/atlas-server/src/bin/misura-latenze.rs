//! `misura-latenze DB [RIPETIZIONI]`: latenze delle API sul database ATLAS reale.
//!
//! Lavora su una copia del file in una cartella temporanea (migrata all'ultima versione): `DB`
//! non viene né migrato né scritto. Senza Arca. Ogni chiamata passa dalle rotte come una
//! richiesta HTTP (estrazione, lettura, serializzazione JSON), senza la rete. Le richieste sono
//! scelte sui dati: l'articolo più venduto e uno raro, il cliente con più DDT, l'ultimo DDT.
//! Alla fine salva un DDT nella copia (la scrittura passa dal worker).

#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic, clippy::indexing_slicing)]

use std::time::{Duration, Instant};

use atlas_server::config::Config;
use atlas_server::worker::Sorgenti;
use axum::Router;
use axum::body::Body;
use axum::http::{Request, StatusCode, header};
use serde_json::{Value, json};
use tower::ServiceExt;

async fn chiama(router: &Router, metodo: &str, uri: &str, corpo: Option<&Value>) -> (StatusCode, Value) {
    let mut r = Request::builder().method(metodo).uri(uri);
    let body = match corpo {
        Some(c) => {
            r = r.header(header::CONTENT_TYPE, "application/json");
            Body::from(c.to_string())
        }
        None => Body::empty(),
    };
    let risposta = router.clone().oneshot(r.body(body).unwrap()).await.unwrap();
    let stato = risposta.status();
    let byte = axum::body::to_bytes(risposta.into_body(), usize::MAX).await.unwrap();
    (stato, serde_json::from_slice(&byte).unwrap_or(Value::Null))
}

fn percentile(tempi: &[Duration], p: f64) -> f64 {
    let i = ((tempi.len() as f64 - 1.0) * p).round() as usize;
    tempi[i].as_secs_f64() * 1000.0
}

async fn misura(router: &Router, nome: &str, metodo: &str, uri: &str, corpo: Option<&Value>, volte: usize) -> Value {
    let (stato, primo) = chiama(router, metodo, uri, corpo).await;
    assert!(stato.is_success(), "{nome}: {stato} {primo}");
    let mut tempi = Vec::with_capacity(volte);
    for _ in 0..volte {
        let inizio = Instant::now();
        let (stato, _) = chiama(router, metodo, uri, corpo).await;
        tempi.push(inizio.elapsed());
        assert!(stato.is_success());
    }
    tempi.sort();
    println!(
        "{nome:<38} p50 {:>6.3} ms   p99 {:>6.3} ms   max {:>6.3} ms",
        percentile(&tempi, 0.5),
        percentile(&tempi, 0.99),
        percentile(&tempi, 1.0)
    );
    primo
}

#[tokio::main]
async fn main() {
    let mut argomenti = std::env::args().skip(1);
    let origine = argomenti.next().expect("uso: misura-latenze DB [RIPETIZIONI]");
    let volte: usize = argomenti.next().map_or(500, |v| v.parse().expect("RIPETIZIONI numerico"));
    let cartella = std::env::temp_dir().join(format!("atlas-misura-{}", std::process::id()));
    std::fs::create_dir_all(&cartella).unwrap();
    let copia = cartella.join("atlas.sqlite");
    // Copia coerente anche se il file è aperto in WAL da un altro programma.
    rusqlite::Connection::open_with_flags(&origine, rusqlite::OpenFlags::SQLITE_OPEN_READ_ONLY)
        .unwrap()
        .execute("VACUUM INTO ?1", [copia.to_str().unwrap()])
        .unwrap();
    let inizio = Instant::now();
    let (servizio, maniglia) = atlas_server::prepara(&Config::nuova(&copia), Sorgenti::arca(None)).unwrap();
    println!("copia aperta e migrata in {:.0} ms\n", inizio.elapsed().as_secs_f64() * 1000.0);
    let router = atlas_server::rotte::router(servizio.clone());

    let scelta = rusqlite::Connection::open(&copia).unwrap();
    let riga = |sql: &str| -> String { scelta.query_row(sql, [], |r| r.get(0)).unwrap() };
    let frequente = riga("SELECT articolo FROM ddt_righe GROUP BY articolo ORDER BY count(*) DESC LIMIT 1");
    let raro = riga("SELECT articolo FROM ddt_righe GROUP BY articolo ORDER BY count(*), articolo LIMIT 1");
    let cliente = riga("SELECT cliente FROM ddt GROUP BY cliente ORDER BY count(*) DESC LIMIT 1");
    let ultimo: i64 = scelta.query_row("SELECT id FROM ddt ORDER BY data DESC, numero DESC LIMIT 1", [], |r| r.get(0)).unwrap();
    let data: String = riga("SELECT max(data) FROM ddt");
    let righe: Vec<(String, String, String)> = {
        let mut stmt = scelta
            .prepare("SELECT articolo, lordo, tara_per_collo FROM ddt_righe WHERE ddt = ?1 ORDER BY riga")
            .unwrap();
        stmt.query_map([ultimo], |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?))).unwrap().map(Result::unwrap).collect()
    };
    let cliente_ultimo = riga(&format!("SELECT cliente FROM ddt WHERE id = {ultimo}"));
    drop(scelta);
    println!("articolo più venduto {frequente}, più raro {raro}, cliente con più DDT {cliente}, ultimo DDT id {ultimo}\n");

    let bozza = json!({
        "cliente": cliente_ultimo,
        "data": data,
        "righe": righe.iter().map(|(a, l, t)| json!({"articolo": a, "colli": 1, "lordo": l, "tara": t, "prezzo": "1.50"})).collect::<Vec<_>>(),
    });

    misura(&router, "GET  /api/salute", "GET", "/api/salute", None, volte).await;
    misura(&router, "GET  /api/stato", "GET", "/api/stato", None, volte).await;
    let f3 = misura(&router, "GET  /api/prezzi (F3, più venduto)", "GET", &format!("/api/prezzi?articolo={frequente}&cliente={cliente}&data={data}"), None, volte).await;
    misura(&router, "GET  /api/prezzi (F3, articolo raro)", "GET", &format!("/api/prezzi?articolo={raro}&cliente={cliente}&data={data}"), None, volte).await;
    misura(&router, "GET  /api/clienti?cerca=", "GET", "/api/clienti?cerca=ri", None, volte).await;
    misura(&router, "GET  /api/articoli?cerca=", "GET", "/api/articoli?cerca=ME", None, volte).await;
    misura(&router, "GET  /api/clienti/{codice}", "GET", &format!("/api/clienti/{cliente}"), None, volte).await;
    misura(&router, "GET  /api/ddt (ultimi 50)", "GET", "/api/ddt", None, volte).await;
    misura(&router, "GET  /api/ddt?cliente= (ultimi 50)", "GET", &format!("/api/ddt?cliente={cliente}"), None, volte).await;
    misura(&router, "GET  /api/ddt/{id}", "GET", &format!("/api/ddt/{ultimo}"), None, volte).await;
    let calcolo = misura(&router, &format!("POST /api/ddt/calcola ({} righe)", righe.len()), "POST", "/api/ddt/calcola", Some(&bozza), volte).await;
    misura(&router, "GET  /api/tabelle", "GET", "/api/tabelle", None, volte).await;

    println!("\nF3 su {frequente}: {}", serde_json::to_string_pretty(&f3["ultimi"]).unwrap());
    println!("calcolo: salvabile {}, totale {}", calcolo["salvabile"], calcolo["castelletto"]["totale_documento"]);

    let inizio = Instant::now();
    let (stato, creato) = chiama(&router, "POST", "/api/ddt", Some(&bozza)).await;
    println!(
        "\nPOST /api/ddt (salvataggio nella copia, senza Arca): {stato} in {:.3} ms → numero {} del {}",
        inizio.elapsed().as_secs_f64() * 1000.0,
        creato["numero"],
        creato["data"]
    );
    let mut tempi = Vec::new();
    for _ in 0..50 {
        let inizio = Instant::now();
        let (stato, _) = chiama(&router, "POST", "/api/ddt", Some(&bozza)).await;
        assert_eq!(stato, StatusCode::CREATED);
        tempi.push(inizio.elapsed());
    }
    tempi.sort();
    println!("POST /api/ddt × 50: p50 {:.3} ms, max {:.3} ms (synchronous = FULL: ogni commit va su disco)", percentile(&tempi, 0.5), percentile(&tempi, 1.0));

    drop((router, servizio));
    maniglia.attendi();
    let _ = std::fs::remove_dir_all(&cartella);
}
