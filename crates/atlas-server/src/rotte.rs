//! Rotte HTTP e WebSocket.
//!
//! REST (JSON, prefisso `/api`):
//! - `GET  /salute`, `GET /stato`, `POST /sincronizza`
//! - `GET  /tabelle`, `GET /clienti?cerca=`, `GET /clienti/{codice}`, `GET /articoli?cerca=`,
//!   `GET /articoli/{codice}`
//! - `GET  /prezzi?articolo=&cliente=&data=&unita_misura=&quantita=&escludi_ddt=` (tasto `F3`)
//! - `GET  /ddt?dal=&al=&cliente=&numero=&limite=`, `GET /ddt/{id}`
//! - `POST /ddt/calcola` (totalizzazione in tempo reale), `POST /ddt` (salvataggio, `F10`),
//!   `POST /ddt/{id}/rinumera`, `GET /numerazione/{esercizio}/liberi` (`F3` sul numero)
//! - `GET  /home/clienti?data=` (clienti che di solito ordinano in quel giorno della settimana)
//! - `GET  /note`, `POST /note`, `PUT /note/{id}`, `DELETE /note/{id}` (post-it della Home)
//! - `GET  /strumenti`, `POST /strumenti/{nome}`
//!
//! WebSocket `GET /api/ws`: richieste `{"id": …, "metodo": "<strumento>", "parametri": {…}}`,
//! risposte `{"id": …, "risultato": …}` o `{"id": …, "errore": {…}}`; notifiche
//! `{"evento": "…", "dati": …}` (`stato` alla connessione e a ogni cambiamento, `ddt_creato`,
//! `ddt_rinumerato`, `replica`, `importazione`, `note_cambiate`; `ritardo` se il client ne ha perse).
//!
//! Le richieste dei browser sono accettate solo dalle origini dell'applicazione desktop (Tauri) e
//! di sviluppo: una pagina qualsiasi aperta nel browser della postazione non può usare le API,
//! WebSocket compreso (che il browser non sottopone a CORS).

use axum::Json;
use axum::Router;
use axum::extract::rejection::{JsonRejection, QueryRejection};
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Path, Query, Request, State};
use axum::http::{HeaderMap, HeaderValue, Method, StatusCode, header};
use axum::middleware::{self, Next};
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use tokio::sync::broadcast::error::RecvError;

use crate::bozza::Bozza;
use crate::consultazione::{FiltroDdt, Ricerca};
use crate::errore::{CorpoErrore, ErroreApi};
use crate::prezzi::RichiestaPrezzi;
use crate::servizio::Servizio;
use crate::strumenti;
use crate::worker::{Notifica, OperazioneNota};

/// Origini ammesse per le richieste dei browser: l'app Tauri v2 (Windows, macOS/Linux) e il
/// server di sviluppo Vite di Tauri.
pub const ORIGINI: &[&str] = &[
    "http://tauri.localhost",
    "https://tauri.localhost",
    "tauri://localhost",
    "http://localhost:1420",
];

pub fn router(servizio: Servizio) -> Router {
    let api = Router::new()
        .route("/salute", get(salute))
        .route("/stato", get(stato))
        .route("/sincronizza", post(sincronizza))
        .route("/tabelle", get(tabelle))
        .route("/clienti", get(cerca_clienti))
        .route("/clienti/{codice}", get(cliente))
        .route("/articoli", get(cerca_articoli))
        .route("/articoli/{codice}", get(articolo))
        .route("/prezzi", get(prezzi))
        .route("/ddt", get(elenco_ddt).post(crea_ddt))
        .route("/ddt/calcola", post(calcola_ddt))
        .route("/ddt/{id}", get(ddt))
        .route("/ddt/{id}/rinumera", post(rinumera))
        .route("/numerazione/{esercizio}/liberi", get(liberi))
        .route("/home/clienti", get(clienti_del_giorno))
        .route("/note", get(note).post(crea_nota))
        .route("/note/{id}", axum::routing::put(aggiorna_nota).delete(elimina_nota))
        .route("/strumenti", get(elenco_strumenti))
        .route("/strumenti/{nome}", post(invoca_strumento))
        .route("/ws", get(ws));
    Router::new()
        .nest("/api", api)
        .fallback(|| async { ErroreApi::NonTrovato("percorso".into()) })
        .layer(middleware::from_fn(origine))
        .with_state(servizio)
}

/// Rifiuta le origini estranee e risponde al CORS delle origini ammesse.
async fn origine(richiesta: Request, next: Next) -> Response {
    let origine = richiesta.headers().get(header::ORIGIN).cloned();
    let ammessa = origine.as_ref().is_none_or(|o| o.to_str().is_ok_and(|o| ORIGINI.contains(&o)));
    if !ammessa {
        return (
            StatusCode::FORBIDDEN,
            Json(CorpoErrore {
                codice: "origine_non_ammessa",
                messaggio: "origine non ammessa".into(),
                dettagli: Vec::new(),
            }),
        )
            .into_response();
    }
    let preflight = richiesta.method() == Method::OPTIONS;
    let mut risposta = if preflight {
        StatusCode::NO_CONTENT.into_response()
    } else {
        next.run(richiesta).await
    };
    if let Some(origine) = origine {
        let h = risposta.headers_mut();
        h.insert(header::ACCESS_CONTROL_ALLOW_ORIGIN, origine);
        h.insert(header::VARY, HeaderValue::from_static("origin"));
        if preflight {
            h.insert(header::ACCESS_CONTROL_ALLOW_METHODS, HeaderValue::from_static("GET, POST, PUT, DELETE"));
            h.insert(header::ACCESS_CONTROL_ALLOW_HEADERS, HeaderValue::from_static("content-type"));
            h.insert(header::ACCESS_CONTROL_MAX_AGE, HeaderValue::from_static("86400"));
        }
    }
    risposta
}

type Esito<T> = Result<Json<T>, ErroreApi>;

fn corpo<T>(corpo: Result<Json<T>, JsonRejection>) -> Result<T, ErroreApi> {
    corpo.map(|Json(c)| c).map_err(|e| ErroreApi::Richiesta(e.body_text()))
}

fn query<T>(query: Result<Query<T>, QueryRejection>) -> Result<T, ErroreApi> {
    query.map(|Query(q)| q).map_err(|e| ErroreApi::Richiesta(e.body_text()))
}

#[derive(Debug, Serialize)]
struct Salute {
    versione: &'static str,
    schema: i64,
}

async fn salute() -> Json<Salute> {
    Json(Salute {
        versione: env!("CARGO_PKG_VERSION"),
        schema: atlas_db::connessione::versione_schema(),
    })
}

async fn stato(State(s): State<Servizio>) -> Esito<crate::servizio::Stato> {
    Ok(Json(s.stato().await?))
}

async fn sincronizza(State(s): State<Servizio>) -> Result<StatusCode, ErroreApi> {
    s.sincronizza().await?;
    Ok(StatusCode::ACCEPTED)
}

async fn tabelle(State(s): State<Servizio>) -> Esito<crate::consultazione::Tabelle> {
    Ok(Json(s.tabelle().await?))
}

async fn cerca_clienti(State(s): State<Servizio>, q: Result<Query<Ricerca>, QueryRejection>) -> Esito<Vec<crate::consultazione::ClienteBreve>> {
    Ok(Json(s.cerca_clienti(query(q)?).await?))
}

async fn cliente(State(s): State<Servizio>, Path(codice): Path<String>) -> Esito<crate::consultazione::ClienteScheda> {
    Ok(Json(s.cliente(codice).await?))
}

async fn cerca_articoli(State(s): State<Servizio>, q: Result<Query<Ricerca>, QueryRejection>) -> Esito<Vec<crate::consultazione::ArticoloBreve>> {
    Ok(Json(s.cerca_articoli(query(q)?).await?))
}

async fn articolo(State(s): State<Servizio>, Path(codice): Path<String>) -> Esito<crate::consultazione::ArticoloScheda> {
    Ok(Json(s.articolo(codice).await?))
}

async fn prezzi(State(s): State<Servizio>, q: Result<Query<RichiestaPrezzi>, QueryRejection>) -> Esito<crate::prezzi::Prezzi> {
    Ok(Json(s.prezzi(query(q)?).await?))
}

async fn elenco_ddt(State(s): State<Servizio>, q: Result<Query<FiltroDdt>, QueryRejection>) -> Esito<Vec<crate::consultazione::DdtBreve>> {
    Ok(Json(s.elenco_ddt(query(q)?).await?))
}

async fn ddt(State(s): State<Servizio>, Path(id): Path<i64>) -> Esito<crate::consultazione::DdtScheda> {
    Ok(Json(s.ddt(id).await?))
}

async fn calcola_ddt(State(s): State<Servizio>, c: Result<Json<Bozza>, JsonRejection>) -> Esito<crate::bozza::Calcolo> {
    Ok(Json(s.calcola(corpo(c)?).await?))
}

async fn crea_ddt(State(s): State<Servizio>, c: Result<Json<Bozza>, JsonRejection>) -> Result<Response, ErroreApi> {
    let creato = s.crea_ddt(corpo(c)?).await?;
    let mut intestazioni = HeaderMap::new();
    if let Ok(dove) = HeaderValue::from_str(&format!("/api/ddt/{}", creato.id)) {
        intestazioni.insert(header::LOCATION, dove);
    }
    Ok((StatusCode::CREATED, intestazioni, Json(creato)).into_response())
}

async fn rinumera(State(s): State<Servizio>, Path(id): Path<i64>) -> Esito<crate::worker::Rinumerato> {
    Ok(Json(s.rinumera(id).await?))
}

async fn liberi(State(s): State<Servizio>, Path(esercizio): Path<i32>) -> Esito<crate::worker::NumeriLiberi> {
    Ok(Json(s.liberi(esercizio).await?))
}

async fn clienti_del_giorno(
    State(s): State<Servizio>,
    q: Result<Query<crate::home::RichiestaGiorno>, QueryRejection>,
) -> Esito<crate::home::ClientiDelGiorno> {
    Ok(Json(s.clienti_del_giorno(query(q)?).await?))
}

async fn note(State(s): State<Servizio>) -> Esito<Vec<atlas_db::note::Nota>> {
    Ok(Json(s.note().await?))
}

async fn crea_nota(State(s): State<Servizio>, c: Result<Json<atlas_db::note::CampiNota>, JsonRejection>) -> Result<Response, ErroreApi> {
    let nota = s.nota(OperazioneNota::Crea(corpo(c)?)).await?;
    Ok((StatusCode::CREATED, Json(nota)).into_response())
}

async fn aggiorna_nota(
    State(s): State<Servizio>,
    Path(id): Path<i64>,
    c: Result<Json<atlas_db::note::CampiNota>, JsonRejection>,
) -> Esito<Option<atlas_db::note::Nota>> {
    Ok(Json(s.nota(OperazioneNota::Aggiorna(id, corpo(c)?)).await?))
}

async fn elimina_nota(State(s): State<Servizio>, Path(id): Path<i64>) -> Result<StatusCode, ErroreApi> {
    s.nota(OperazioneNota::Elimina(id)).await?;
    Ok(StatusCode::NO_CONTENT)
}

async fn elenco_strumenti() -> Json<Vec<strumenti::Strumento>> {
    Json(strumenti::elenco())
}

async fn invoca_strumento(
    State(s): State<Servizio>,
    Path(nome): Path<String>,
    c: Result<Json<Value>, JsonRejection>,
) -> Esito<Value> {
    Ok(Json(strumenti::invoca(&s, &nome, corpo(c)?).await?))
}

/// Richiesta sul WebSocket.
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct RichiestaWs {
    #[serde(default)]
    id: Value,
    metodo: String,
    #[serde(default)]
    parametri: Value,
}

async fn ws(State(s): State<Servizio>, upgrade: WebSocketUpgrade) -> Response {
    upgrade.on_upgrade(move |socket| sessione_ws(s, socket))
}

async fn invia(socket: &mut WebSocket, valore: &Value) -> bool {
    socket.send(Message::Text(valore.to_string().into())).await.is_ok()
}

fn notifica(n: &Notifica) -> Value {
    serde_json::to_value(n).unwrap_or_else(|e| json!({"evento": "errore", "dati": e.to_string()}))
}

/// Una connessione WebSocket: le richieste si servono in ordine, le notifiche arrivano fra una
/// richiesta e l'altra.
async fn sessione_ws(servizio: Servizio, mut socket: WebSocket) {
    let mut notifiche = servizio.notifiche();
    if !invia(&mut socket, &notifica(&Notifica::Stato(servizio.stato_sync()))).await {
        return;
    }
    loop {
        tokio::select! {
            messaggio = socket.recv() => {
                let testo = match messaggio {
                    Some(Ok(Message::Text(t))) => t,
                    Some(Ok(Message::Ping(_) | Message::Pong(_))) => continue,
                    Some(Ok(Message::Binary(_))) => {
                        let errore = ErroreApi::Richiesta("messaggi binari non gestiti".into()).corpo();
                        if !invia(&mut socket, &json!({"id": null, "errore": errore})).await { return; }
                        continue;
                    }
                    Some(Ok(Message::Close(_)) | Err(_)) | None => return,
                };
                let risposta = match serde_json::from_str::<RichiestaWs>(&testo) {
                    Err(e) => json!({"id": null, "errore": ErroreApi::Richiesta(e.to_string()).corpo()}),
                    Ok(r) => match strumenti::invoca(&servizio, &r.metodo, r.parametri).await {
                        Ok(risultato) => json!({"id": r.id, "risultato": risultato}),
                        Err(e) => json!({"id": r.id, "errore": e.corpo()}),
                    },
                };
                if !invia(&mut socket, &risposta).await { return; }
            }
            n = notifiche.recv() => {
                let valore = match n {
                    Ok(n) => notifica(&n),
                    Err(RecvError::Lagged(perse)) => json!({"evento": "ritardo", "dati": {"perse": perse}}),
                    Err(RecvError::Closed) => return,
                };
                if !invia(&mut socket, &valore).await { return; }
            }
        }
    }
}
