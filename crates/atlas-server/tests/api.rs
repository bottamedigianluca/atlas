//! Il backend da fuori: rotte HTTP, WebSocket e worker, con un'Arca finta.

#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic, clippy::indexing_slicing)]

use std::collections::{BTreeMap, BTreeSet};
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use atlas_arca::ErroreArca;
use atlas_arca::lettura::{Modificato, Testata};
use atlas_core::ddt::Ddt;
use atlas_core::numerazione::{Numeri, Sezionale};
use atlas_db::anagrafiche::Anagrafiche;
use atlas_db::outbox::Evento;
use atlas_server::config::Config;
use atlas_server::servizio::Servizio;
use atlas_server::worker::{Maniglia, Notifica, Replica, Sorgenti};
use atlas_sync::ErroreSync;
use atlas_sync::importazione::Origine;
use atlas_sync::replica::{Destinazione, Replicato};
use axum::Router;
use axum::body::Body;
use axum::http::{Request, StatusCode, header};
use chrono::{Local, NaiveDate, NaiveDateTime};
use futures_util::{SinkExt, StreamExt};
use http_body_util::BodyExt;
use serde_json::{Value, json};
use tower::ServiceExt;

/// Un documento in Arca: chiave (esercizio, numero).
#[derive(Debug, Clone)]
struct InArca {
    id: i32,
    cliente: String,
    data: NaiveDate,
    registrato_il: NaiveDateTime,
}

#[derive(Debug, Default)]
struct StatoFinto {
    documenti: BTreeMap<(i32, u32), InArca>,
    prossimo_id: i32,
    /// `modificati` non risponde mai: un giro di importazione appeso alla rete.
    appesa: bool,
    scollegamenti: usize,
    replicati: Vec<u32>,
    /// Numeri scritti in Arca dopo che ATLAS li ha letti liberi: la lettura dei numeri non li vede.
    dopo_la_lettura: Vec<u32>,
}

/// Arca finta condivisa fra le tre connessioni del worker e il test.
#[derive(Debug, Clone, Default)]
struct Finta(Arc<Mutex<StatoFinto>>);

impl Finta {
    fn con<T>(&self, f: impl FnOnce(&mut StatoFinto) -> T) -> T {
        f(&mut self.0.lock().unwrap())
    }

    /// Un BO scritto in Arca da un altro.
    fn scrivi(&self, numero: u32, cliente: &str) -> i32 {
        self.con(|s| {
            s.prossimo_id += 1;
            let data = oggi();
            s.documenti.insert(
                (2026, numero),
                InArca {
                    id: 120_000 + s.prossimo_id,
                    cliente: cliente.into(),
                    data,
                    registrato_il: data.and_hms_opt(6, 0, 0).unwrap(),
                },
            );
            120_000 + s.prossimo_id
        })
    }
}

impl Origine for Finta {
    async fn database(&mut self) -> Result<String, ErroreSync> {
        Ok("ADB_BOTTAMEDI_DEV".into())
    }

    async fn modificati(&mut self, _dopo: i64, _limite: usize) -> Result<Vec<Modificato>, ErroreSync> {
        if self.con(|s| s.appesa) {
            std::future::pending::<()>().await;
        }
        Ok(Vec::new())
    }

    /// I documenti che ATLAS conosce sono quelli che ha replicato: impronta uguale, nessuna
    /// cancellazione.
    async fn impronta(&mut self) -> Result<(i64, i64), ErroreSync> {
        let ids = self.identita().await?;
        Ok((ids.len() as i64, ids.iter().map(|&i| i64::from(i)).sum()))
    }

    async fn identita(&mut self) -> Result<BTreeSet<i32>, ErroreSync> {
        Ok(self.con(|s| {
            s.documenti
                .iter()
                .filter(|((_, n), _)| s.replicati.contains(n))
                .map(|(_, d)| d.id)
                .collect()
        }))
    }

    async fn carica(&mut self, id: i32) -> Result<Ddt, ErroreArca> {
        Err(ErroreArca::DocumentoNonValido(format!("Id_DoTes {id}")))
    }

    async fn anagrafiche(&mut self) -> Result<Anagrafiche, ErroreSync> {
        Ok(atlas_db::prova::anagrafiche())
    }

    async fn numeri(&mut self, _sezionale: Sezionale, esercizio: i32) -> Result<Numeri, ErroreSync> {
        Ok(self.con(|s| {
            s.documenti
                .iter()
                .filter(|((e, n), _)| *e == esercizio && !s.dopo_la_lettura.contains(n))
                .map(|((_, n), d)| (*n, d.data))
                .collect()
        }))
    }

    async fn con_numero(&mut self, _sezionale: Sezionale, esercizio: i32, numero: u32) -> Result<Option<Testata>, ErroreSync> {
        Ok(self.con(|s| {
            s.documenti.get(&(esercizio, numero)).map(|d| Testata {
                id_testata: d.id,
                cliente: d.cliente.clone(),
                registrato_il: d.registrato_il,
            })
        }))
    }

    fn scollega(&mut self) {
        self.con(|s| s.scollegamenti += 1);
    }
}

impl Destinazione for Finta {
    async fn replica(&mut self, evento: &Evento) -> Result<Replicato, ErroreSync> {
        let ddt = evento.ddt()?;
        self.con(|s| {
            let chiave = (2026, ddt.numero);
            if let Some(occupante) = s.documenti.get(&chiave) {
                return Err(ErroreSync::NumeroOccupato {
                    esercizio: "2026".into(),
                    numero: ddt.numero,
                    id_testata: occupante.id,
                });
            }
            s.prossimo_id += 1;
            let id = 120_000 + s.prossimo_id;
            s.documenti.insert(
                chiave,
                InArca {
                    id,
                    cliente: ddt.cliente.clone(),
                    data: ddt.data,
                    registrato_il: ddt.registrato_il,
                },
            );
            s.replicati.push(ddt.numero);
            Ok(Replicato::Scritto(id))
        })
    }
}

impl Replica for Finta {
    fn lega(&mut self, _database: &str) {}

    fn scollega(&mut self) {
        self.con(|s| s.scollegamenti += 1);
    }
}

fn oggi() -> NaiveDate {
    Local::now().date_naive()
}

struct Banco {
    #[allow(dead_code)]
    servizio: Servizio,
    router: Router,
    maniglia: Option<Maniglia>,
    cartella: PathBuf,
}

impl Drop for Banco {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.cartella);
    }
}

fn banco(nome: &str, arca: Option<Finta>) -> Banco {
    let cartella = std::env::temp_dir().join(format!("atlas-server-{nome}-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&cartella);
    std::fs::create_dir_all(&cartella).unwrap();
    let file = cartella.join("atlas.sqlite");
    let mut db = atlas_db::apri(&file).unwrap();
    atlas_db::anagrafiche::aggiorna(&mut db, &atlas_db::prova::anagrafiche()).unwrap();
    drop(db);
    let sorgenti = Sorgenti {
        numeri: arca.clone(),
        importazione: arca.clone(),
        replica: arca,
    };
    let (servizio, maniglia) = atlas_server::prepara(&Config::nuova(&file), sorgenti).unwrap();
    Banco {
        router: atlas_server::rotte::router(servizio.clone()),
        servizio,
        maniglia: Some(maniglia),
        cartella,
    }
}

async fn chiama(router: &Router, metodo: &str, percorso: &str, corpo: Option<Value>) -> (StatusCode, Value) {
    let mut richiesta = Request::builder().method(metodo).uri(percorso);
    let body = match corpo {
        Some(c) => {
            richiesta = richiesta.header(header::CONTENT_TYPE, "application/json");
            Body::from(c.to_string())
        }
        None => Body::empty(),
    };
    let risposta = router.clone().oneshot(richiesta.body(body).unwrap()).await.unwrap();
    let stato = risposta.status();
    let byte = risposta.into_body().collect().await.unwrap().to_bytes();
    let valore = if byte.is_empty() { Value::Null } else { serde_json::from_slice(&byte).unwrap() };
    (stato, valore)
}

fn bozza() -> Value {
    json!({
        "cliente": "C000380",
        "data": oggi(),
        "righe": [
            {"articolo": "BAN", "colli": 1, "lordo": "5.46", "tara": "0.30"},
            {"articolo": "PIST", "lordo": "0.5", "prezzo": "22.40"},
            {"articolo": ""}
        ]
    })
}

/// Lo stato della sincronizzazione appena soddisfa `condizione` (al più 5 s).
async fn aspetta(router: &Router, condizione: impl Fn(&Value) -> bool) -> Value {
    let inizio = Instant::now();
    loop {
        let (_, stato) = chiama(router, "GET", "/api/stato", None).await;
        if condizione(&stato) || inizio.elapsed() > Duration::from_secs(5) {
            return stato;
        }
        tokio::time::sleep(Duration::from_millis(10)).await;
    }
}

#[tokio::test(flavor = "multi_thread")]
async fn calcola_crea_e_rilegge_senza_arca() {
    let b = banco("senza-arca", None);
    let (stato, calcolo) = chiama(&b.router, "POST", "/api/ddt/calcola", Some(bozza())).await;
    assert_eq!(stato, StatusCode::OK, "{calcolo}");
    assert_eq!(calcolo["salvabile"], true);
    assert_eq!(calcolo["castelletto"]["totale_documento"], "21.98");
    assert_eq!(calcolo["righe"][0]["quantita"], "5.16");
    assert_eq!(calcolo["righe"][2]["vuota"], true);

    let (stato, creato) = chiama(&b.router, "POST", "/api/ddt", Some(bozza())).await;
    assert_eq!(stato, StatusCode::CREATED, "{creato}");
    assert_eq!((creato["numero"].as_u64(), creato["totale_documento"].as_str()), (Some(1), Some("21.98")));
    assert_eq!(creato["senza_arca"], "Arca non configurata");
    let (_, secondo) = chiama(&b.router, "POST", "/api/ddt", Some(bozza())).await;
    assert_eq!(secondo["numero"], 2);

    let id = creato["id"].as_i64().unwrap();
    let (stato, scheda) = chiama(&b.router, "GET", &format!("/api/ddt/{id}"), None).await;
    assert_eq!(stato, StatusCode::OK);
    assert_eq!(scheda["righe"].as_array().unwrap().len(), 2, "la riga vuota non entra");
    assert_eq!(scheda["documento"]["destinazione"], "ALI");
    assert_eq!(scheda["arca"], "in_coda", "nessuna replica senza Arca");
    let (_, elenco) = chiama(&b.router, "GET", "/api/ddt?cliente=c000380", None).await;
    assert_eq!(elenco.as_array().unwrap().len(), 2);

    // Numero scelto a mano: il 2 è occupato, il 10 è libero.
    let mut a_mano = bozza();
    a_mano["numero"] = json!(2);
    let (stato, errore) = chiama(&b.router, "POST", "/api/ddt", Some(a_mano.clone())).await;
    assert_eq!((stato, errore["codice"].as_str()), (StatusCode::CONFLICT, Some("numero_occupato")));
    a_mano["numero"] = json!(10);
    let (stato, _) = chiama(&b.router, "POST", "/api/ddt", Some(a_mano)).await;
    assert_eq!(stato, StatusCode::CREATED);
    let (_, liberi) = chiama(&b.router, "GET", &format!("/api/numerazione/{}/liberi", 2026), None).await;
    assert_eq!(liberi["liberi"][0]["dal"], 3);
    assert_eq!(liberi["liberi"][0]["al"], 9);
    assert_eq!(liberi["prossimo"], 11);

    // Bozza errata: 422 con un motivo per riga.
    let (stato, errore) = chiama(&b.router, "POST", "/api/ddt", Some(json!({"cliente": "C000380", "righe": [{"articolo": "XX"}]}))).await;
    assert_eq!(stato, StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(errore["dettagli"], json!(["riga 1: articolo XX inesistente"]));
    let (stato, _) = chiama(&b.router, "POST", "/api/ddt", Some(json!({"cliente": 1}))).await;
    assert_eq!(stato, StatusCode::BAD_REQUEST);
    let (stato, _) = chiama(&b.router, "GET", "/api/ddt/999", None).await;
    assert_eq!(stato, StatusCode::NOT_FOUND);
    let (stato, errore) = chiama(&b.router, "POST", &format!("/api/ddt/{id}/rinumera"), None).await;
    assert_eq!((stato, errore["codice"].as_str()), (StatusCode::SERVICE_UNAVAILABLE, Some("non_disponibile")));
}

#[tokio::test(flavor = "multi_thread")]
async fn numerazione_unica_replica_e_conflitto_risolto_rinumerando() {
    let arca = Finta::default();
    arca.scrivi(5457, "C000002");
    let b = banco("arca", Some(arca.clone()));

    let (stato, creato) = chiama(&b.router, "POST", "/api/ddt", Some(bozza())).await;
    assert_eq!(stato, StatusCode::CREATED, "{creato}");
    assert_eq!((creato["numero"].as_u64(), &creato["senza_arca"]), (Some(5458), &Value::Null), "dopo il 5457 di Arca");
    let stato = aspetta(&b.router, |s| s["sincronizzazione"]["replica"]["scritti"] == 1).await;
    assert_eq!(stato["coda"]["in_coda"], 0, "{stato}");
    let id = creato["id"].as_i64().unwrap();
    let (_, scheda) = chiama(&b.router, "GET", &format!("/api/ddt/{id}"), None).await;
    assert_eq!(scheda["arca"], "in_arca");
    assert!(scheda["arca_id_testata"].is_i64());

    // Arca prende il 5459 subito dopo che ATLAS lo ha letto libero: la replica si ferma.
    let (_, liberi) = chiama(&b.router, "GET", "/api/numerazione/2026/liberi", None).await;
    assert_eq!(liberi["prossimo"], 5459);
    // Arca scrive il 5459 fra la lettura dei numeri e la replica del DDT ATLAS.
    arca.scrivi(5459, "C000002");
    arca.con(|s| s.dopo_la_lettura.push(5459));
    let mut a_mano = bozza();
    a_mano["numero"] = json!(5459);
    let (stato, conteso) = chiama(&b.router, "POST", "/api/ddt", Some(a_mano.clone())).await;
    assert_eq!(stato, StatusCode::CREATED);
    arca.con(|s| s.dopo_la_lettura.clear());
    let stato = aspetta(&b.router, |s| !s["conflitti"].as_array().unwrap().is_empty()).await;
    let conflitto = &stato["conflitti"][0];
    assert_eq!((conflitto["origine"].as_str(), conflitto["numero"].as_u64()), (Some("replica"), Some(5459)), "{stato}");
    assert_eq!(conflitto["azioni"], json!(["rinumera"]));
    assert_eq!(conflitto["ddt"], conteso["id"]);

    let (stato, rinumerato) = chiama(&b.router, "POST", &format!("/api/ddt/{}/rinumera", conteso["id"]), None).await;
    assert_eq!(stato, StatusCode::OK, "{rinumerato}");
    assert_eq!((rinumerato["prima"].as_u64(), rinumerato["numero"].as_u64()), (Some(5459), Some(5460)));
    let stato = aspetta(&b.router, |s| s["sincronizzazione"]["replica"]["scritti"] == 2).await;
    assert!(stato["conflitti"].as_array().unwrap().is_empty(), "{stato}");
    assert_eq!(arca.con(|s| s.replicati.clone()), [5458, 5460]);

    // Il numero di Arca non si sceglie a mano.
    a_mano["numero"] = json!(5457);
    let (stato, errore) = chiama(&b.router, "POST", "/api/ddt", Some(a_mano)).await;
    assert_eq!((stato, errore["codice"].as_str()), (StatusCode::CONFLICT, Some("numero_occupato")));
}

#[tokio::test(flavor = "multi_thread")]
async fn il_salvataggio_interrompe_un_giro_appeso_alla_rete() {
    let arca = Finta::default();
    arca.con(|s| s.appesa = true);
    let b = banco("appesa", Some(arca.clone()));
    // Il primo giro di importazione parte subito e resta appeso.
    tokio::time::sleep(Duration::from_millis(50)).await;
    let inizio = Instant::now();
    let (stato, creato) = chiama(&b.router, "POST", "/api/ddt", Some(bozza())).await;
    assert_eq!(stato, StatusCode::CREATED, "{creato}");
    assert!(inizio.elapsed() < Duration::from_millis(500), "{:?}", inizio.elapsed());
    assert!(arca.con(|s| s.scollegamenti) >= 1, "connessione del giro interrotto chiusa");
}

#[tokio::test(flavor = "multi_thread")]
async fn prezzi_anagrafiche_e_strumenti() {
    let b = banco("prezzi", None);
    chiama(&b.router, "POST", "/api/ddt", Some(bozza())).await;
    let (stato, prezzi) = chiama(&b.router, "GET", "/api/prezzi?articolo=ban&cliente=C000380", None).await;
    assert_eq!(stato, StatusCode::OK, "{prezzi}");
    assert_eq!(prezzi["listini"][0]["prezzo_riga"], "1.80");
    assert_eq!(prezzi["listini"][0]["proposto"], true);
    assert_eq!(prezzi["ultimi"][0]["tipo"], "ultimo_cliente");
    assert_eq!(prezzi["ultimi"][0]["documento"]["numero"], 1);
    let (stato, _) = chiama(&b.router, "GET", "/api/prezzi?articolo=ban&sconosciuto=1", None).await;
    assert_eq!(stato, StatusCode::BAD_REQUEST);

    let (_, clienti) = chiama(&b.router, "GET", "/api/clienti?cerca=0380", None).await;
    assert_eq!(clienti[0]["codice"], "C000380");
    let (_, articolo) = chiama(&b.router, "GET", "/api/articoli/pist", None).await;
    assert_eq!(articolo["aliquota"], "10");
    let (_, tabelle) = chiama(&b.router, "GET", "/api/tabelle", None).await;
    assert_eq!(tabelle["magazzini"][0]["codice"], "00001");

    let (_, strumenti) = chiama(&b.router, "GET", "/api/strumenti", None).await;
    assert!(strumenti.as_array().unwrap().iter().any(|s| s["name"] == "prezzi_articolo"));
    let (stato, risultato) =
        chiama(&b.router, "POST", "/api/strumenti/calcola_ddt", Some(bozza())).await;
    assert_eq!((stato, &risultato["salvabile"]), (StatusCode::OK, &json!(true)));
    let (stato, _) = chiama(&b.router, "POST", "/api/strumenti/inesistente", Some(json!({}))).await;
    assert_eq!(stato, StatusCode::NOT_FOUND);
}

#[tokio::test(flavor = "multi_thread")]
async fn solo_le_origini_dell_applicazione() {
    let b = banco("origini", None);
    let richiesta = |origine: &str| {
        Request::builder().uri("/api/salute").header(header::ORIGIN, origine).body(Body::empty()).unwrap()
    };
    let estranea = b.router.clone().oneshot(richiesta("https://sito.example")).await.unwrap();
    assert_eq!(estranea.status(), StatusCode::FORBIDDEN);
    let tauri = b.router.clone().oneshot(richiesta("http://tauri.localhost")).await.unwrap();
    assert_eq!(tauri.status(), StatusCode::OK);
    assert_eq!(tauri.headers()[header::ACCESS_CONTROL_ALLOW_ORIGIN], "http://tauri.localhost");
}

#[tokio::test(flavor = "multi_thread")]
async fn websocket_richieste_e_notifiche() {
    let arca = Finta::default();
    let b = banco("ws", Some(arca));
    let ascolto = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let indirizzo = ascolto.local_addr().unwrap();
    let router = b.router.clone();
    tokio::spawn(async move { axum::serve(ascolto, router).await });

    let (mut ws, _) = tokio_tungstenite::connect_async(format!("ws://{indirizzo}/api/ws")).await.unwrap();
    let mut prossimo = async || -> Value {
        let messaggio = tokio::time::timeout(Duration::from_secs(5), ws.next()).await.unwrap().unwrap().unwrap();
        serde_json::from_str(messaggio.to_text().unwrap()).unwrap()
    };
    assert_eq!(prossimo().await["evento"], "stato");

    let richiesta = json!({"id": 7, "metodo": "crea_ddt", "parametri": bozza()});
    ws.send(tokio_tungstenite::tungstenite::Message::text(richiesta.to_string())).await.unwrap();
    let mut visti = Vec::new();
    let mut risposta = Value::Null;
    let inizio = Instant::now();
    while inizio.elapsed() < Duration::from_secs(5) && !(risposta.is_object() && visti.contains(&"replica".to_owned())) {
        let messaggio = tokio::time::timeout(Duration::from_secs(5), ws.next()).await.unwrap().unwrap().unwrap();
        let valore: Value = serde_json::from_str(messaggio.to_text().unwrap()).unwrap();
        match valore["evento"].as_str() {
            Some(evento) => visti.push(evento.to_owned()),
            None => risposta = valore,
        }
    }
    assert_eq!(risposta["id"], 7);
    assert_eq!(risposta["risultato"]["numero"], 1);
    assert!(visti.contains(&"ddt_creato".to_owned()), "{visti:?}");
    assert!(visti.contains(&"replica".to_owned()), "{visti:?}");

    ws.send(tokio_tungstenite::tungstenite::Message::text(r#"{"id": 8, "metodo": "scheda_ddt", "parametri": {"id": 999}}"#))
        .await
        .unwrap();
    let risposta = loop {
        let messaggio = tokio::time::timeout(Duration::from_secs(5), ws.next()).await.unwrap().unwrap().unwrap();
        let valore: Value = serde_json::from_str(messaggio.to_text().unwrap()).unwrap();
        if valore.get("id").is_some() {
            break valore;
        }
    };
    assert_eq!(risposta["errore"]["codice"], "non_trovato");
}

#[tokio::test(flavor = "multi_thread")]
async fn il_worker_si_ferma_quando_si_chiude_il_servizio() {
    let mut b = banco("chiusura", None);
    let maniglia = b.maniglia.take().unwrap();
    drop(b); // servizio e rotte: gli ultimi mittenti dei comandi
    tokio::time::timeout(Duration::from_secs(5), tokio::task::spawn_blocking(move || maniglia.attendi()))
        .await
        .unwrap()
        .unwrap();
}

#[tokio::test(flavor = "multi_thread")]
async fn home_post_it_e_clienti_del_giorno() {
    let b = banco("home", None);
    let mut notifiche = b.servizio.notifiche();
    let (stato, nota) = chiama(&b.router, "POST", "/api/note", Some(json!({"testo": "Cassette a Dinamos", "colore": "rosa"}))).await;
    assert_eq!(stato, StatusCode::CREATED, "{nota}");
    assert_eq!((nota["testo"].as_str(), nota["colore"].as_str()), (Some("Cassette a Dinamos"), Some("rosa")));
    // Prima possono arrivare le notifiche di stato dell'avvio.
    loop {
        let notifica = tokio::time::timeout(std::time::Duration::from_secs(5), notifiche.recv()).await.unwrap().unwrap();
        if matches!(notifica, Notifica::NoteCambiate) {
            break;
        }
    }

    let id = nota["id"].as_i64().unwrap();
    let (stato, spostata) = chiama(&b.router, "PUT", &format!("/api/note/{id}"), Some(json!({"x": 0.4, "y": 0.6}))).await;
    assert_eq!(stato, StatusCode::OK, "{spostata}");
    assert_eq!((spostata["x"].as_f64(), spostata["testo"].as_str()), (Some(0.4), Some("Cassette a Dinamos")));
    let (stato, _) = chiama(&b.router, "PUT", &format!("/api/note/{id}"), Some(json!({"colore": "viola"}))).await;
    assert_eq!(stato, StatusCode::UNPROCESSABLE_ENTITY);
    let (_, elenco) = chiama(&b.router, "GET", "/api/note", None).await;
    assert_eq!(elenco.as_array().map(Vec::len), Some(1));
    let (stato, _) = chiama(&b.router, "DELETE", &format!("/api/note/{id}"), None).await;
    assert_eq!(stato, StatusCode::NO_CONTENT);
    let (stato, _) = chiama(&b.router, "DELETE", &format!("/api/note/{id}"), None).await;
    assert_eq!(stato, StatusCode::NOT_FOUND);

    let (stato, giorno) = chiama(&b.router, "GET", "/api/home/clienti?data=2026-10-22", None).await;
    assert_eq!(stato, StatusCode::OK, "{giorno}");
    assert_eq!((giorno["giorno"].as_str(), giorno["settimane"].as_u64()), (Some("giovedì"), Some(12)));
}
