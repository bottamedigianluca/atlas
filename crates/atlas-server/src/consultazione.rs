//! Letture per le maschere: anagrafiche, elenco e dettaglio dei DDT, stato della
//! sincronizzazione dei documenti. Tutte su una connessione di sola lettura.

use atlas_core::aliquota::CodiceAliquota;
use atlas_core::ddt::{Ddt, RigaDdt};
use atlas_core::iva::Castelletto;
use chrono::{NaiveDate, NaiveDateTime};
use rusqlite::{Connection, OptionalExtension, params};
use rust_decimal::Decimal;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use crate::errore::ErroreApi;

const LIMITE_PREDEFINITO: u32 = 50;
const LIMITE_MASSIMO: u32 = 1000;

fn limite(richiesto: Option<u32>) -> u32 {
    richiesto.unwrap_or(LIMITE_PREDEFINITO).clamp(1, LIMITE_MASSIMO)
}

/// Il testo con i caratteri speciali di `LIKE` presi alla lettera.
fn letterale(testo: &str) -> String {
    let mut modello = String::with_capacity(testo.len() + 2);
    for c in testo.trim().chars() {
        if matches!(c, '%' | '_' | '\\') {
            modello.push('\\');
        }
        modello.push(c);
    }
    modello
}

/// `%testo%` per `LIKE`.
fn contiene(testo: &str) -> String {
    format!("%{}%", letterale(testo))
}

/// Parametri dell'ordinamento per pertinenza: prima il codice uguale al testo, poi i codici che
/// cominciano con il testo, poi il resto (descrizioni) in ordine di codice. Chi batte un codice
/// lo trova in cima.
fn pertinenza(cerca: Option<&str>) -> (String, String) {
    let testo = cerca.unwrap_or_default().trim();
    (testo.to_owned(), format!("{}%", letterale(testo)))
}

/// Ricerca in un'anagrafica: per codice o per descrizione.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct Ricerca {
    /// Testo contenuto nel codice o nella descrizione; assente: tutti.
    #[serde(default)]
    pub cerca: Option<String>,
    /// Anche le anagrafiche obsolete.
    #[serde(default)]
    pub obsoleti: bool,
    /// Massimo di risultati (predefinito 50, al più 1000).
    #[serde(default)]
    pub limite: Option<u32>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ClienteBreve {
    pub codice: String,
    pub ragione_sociale: String,
    pub localita: Option<String>,
    pub partita_iva: Option<String>,
    pub obsoleto: bool,
    pub indirizzo: Option<String>,
    pub cap: Option<String>,
    pub provincia: Option<String>,
    pub nazione: Option<String>,
    pub codice_fiscale: Option<String>,
    /// Codice destinatario SdI o PEC (`CF.CodiceFPR`).
    pub codice_destinatario: Option<String>,
    /// Gli altri campi di Arca (`CF.Cd_CFGruppo1`…), per le colonne dell'elenco.
    pub extra: serde_json::Value,
}

/// I campi `extra` delle anagrafiche (oggetto JSON scritto dall'importazione).
fn json(testo: &str) -> serde_json::Value {
    serde_json::from_str(testo).unwrap_or(serde_json::Value::Null)
}

/// Il prossimo codice cliente, come lo propone Arca: "C" e sei cifre, il più alto più uno.
pub fn prossimo_codice_cliente(conn: &Connection) -> Result<String, ErroreApi> {
    let massimo: Option<i64> = conn
        .prepare_cached(
            "SELECT max(CAST(substr(codice, 2) AS INTEGER)) FROM clienti_fornitori \
             WHERE codice GLOB 'C[0-9][0-9][0-9][0-9][0-9][0-9]'",
        )?
        .query_row([], |r| r.get(0))?;
    Ok(format!("C{:06}", massimo.unwrap_or(0) + 1))
}

pub fn cerca_clienti(conn: &Connection, ricerca: &Ricerca) -> Result<Vec<ClienteBreve>, ErroreApi> {
    let mut stmt = conn.prepare_cached(
        "SELECT codice, ragione_sociale, localita, partita_iva, obsoleto, indirizzo, cap, provincia, nazione, \
         codice_fiscale, codice_destinatario, extra FROM clienti_fornitori \
         WHERE cliente = 1 AND (?1 OR obsoleto = 0) \
         AND (?2 IS NULL OR codice LIKE ?2 ESCAPE '\\' OR ragione_sociale LIKE ?2 ESCAPE '\\') \
         ORDER BY codice <> ?4, NOT codice LIKE ?5 ESCAPE '\\', codice LIMIT ?3",
    )?;
    let cerca = ricerca.cerca.as_deref().filter(|c| !c.trim().is_empty());
    let (uguale, inizia) = pertinenza(cerca);
    let righe = stmt.query_map(params![ricerca.obsoleti, cerca.map(contiene), limite(ricerca.limite), uguale, inizia], |r| {
        Ok(ClienteBreve {
            codice: r.get(0)?,
            ragione_sociale: r.get::<_, String>(1)?.trim_end().to_owned(),
            localita: r.get(2)?,
            partita_iva: r.get::<_, Option<String>>(3)?.map(|p| p.trim().to_owned()),
            obsoleto: r.get(4)?,
            indirizzo: r.get(5)?,
            cap: r.get(6)?,
            provincia: r.get(7)?,
            nazione: r.get(8)?,
            codice_fiscale: r.get(9)?,
            codice_destinatario: r.get(10)?,
            extra: json(&r.get::<_, String>(11)?),
        })
    })?;
    Ok(righe.collect::<Result<_, _>>()?)
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct DestinazioneVista {
    pub codice: String,
    pub descrizione: String,
    pub indirizzo: Option<String>,
    pub localita: Option<String>,
    pub provincia: Option<String>,
    pub predefinita: bool,
    pub obsoleto: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ClienteScheda {
    pub codice: String,
    pub ragione_sociale: String,
    pub indirizzo: Option<String>,
    pub cap: Option<String>,
    pub localita: Option<String>,
    pub provincia: Option<String>,
    pub partita_iva: Option<String>,
    pub codice_fiscale: Option<String>,
    /// Codice destinatario SdI (`CF.CodiceFPR`).
    pub codice_destinatario: Option<String>,
    pub pagamento: Option<String>,
    pub descrizione_pagamento: Option<String>,
    pub listino: Option<String>,
    pub descrizione_listino: Option<String>,
    pub agente: Option<String>,
    pub descrizione_agente: Option<String>,
    pub iban: Option<String>,
    pub bic: Option<String>,
    pub scissione_pagamenti: bool,
    pub obsoleto: bool,
    pub destinazioni: Vec<DestinazioneVista>,
    pub nazione: Option<String>,
    /// Codice ufficio della PA (`CF.CodiceIPA`).
    pub codice_ipa: Option<String>,
    pub conto_banca: Option<String>,
    pub conto_merce: Option<String>,
    pub ente_pubblico: bool,
    /// Esenzione o aliquota del cliente (`CF.Cd_Aliquota`).
    pub aliquota: Option<String>,
    pub cliente_fatturazione: Option<String>,
    pub fido: Option<String>,
    pub note: Option<String>,
    /// Gli altri campi di `CF` con i nomi delle colonne di Arca.
    pub extra: serde_json::Value,
}

pub fn cliente(conn: &Connection, codice: &str) -> Result<ClienteScheda, ErroreApi> {
    let mut scheda = conn
        .prepare_cached(
            "SELECT c.codice, c.ragione_sociale, c.indirizzo, c.cap, c.localita, c.provincia, c.partita_iva, \
             c.codice_fiscale, c.pagamento, p.descrizione, c.listino, c.agente, c.scissione_pagamenti, c.obsoleto, \
             c.codice_destinatario, l.descrizione, a.descrizione, c.iban, c.bic \
             FROM clienti_fornitori c LEFT JOIN pagamenti p ON p.codice = c.pagamento \
             LEFT JOIN listini l ON l.codice = c.listino LEFT JOIN agenti a ON a.codice = c.agente \
             WHERE c.codice = ?1 AND c.cliente = 1",
        )?
        .query_row([codice.trim()], |r| {
            Ok(ClienteScheda {
                codice: r.get(0)?,
                ragione_sociale: r.get::<_, String>(1)?.trim_end().to_owned(),
                indirizzo: r.get(2)?,
                cap: r.get(3)?,
                localita: r.get(4)?,
                provincia: r.get(5)?,
                partita_iva: r.get::<_, Option<String>>(6)?.map(|p| p.trim().to_owned()),
                codice_fiscale: r.get(7)?,
                pagamento: r.get(8)?,
                descrizione_pagamento: r.get(9)?,
                listino: r.get(10)?,
                agente: r.get(11)?,
                scissione_pagamenti: r.get(12)?,
                obsoleto: r.get(13)?,
                codice_destinatario: r.get(14)?,
                descrizione_listino: r.get::<_, Option<String>>(15)?.map(|d| d.trim_end().to_owned()),
                descrizione_agente: r.get::<_, Option<String>>(16)?.map(|d| d.trim_end().to_owned()),
                iban: r.get(17)?,
                bic: r.get(18)?,
                destinazioni: Vec::new(),
                nazione: None,
                codice_ipa: None,
                conto_banca: None,
                conto_merce: None,
                ente_pubblico: false,
                aliquota: None,
                cliente_fatturazione: None,
                fido: None,
                note: None,
                extra: serde_json::Value::Null,
            })
        })
        .optional()?
        .ok_or_else(|| ErroreApi::NonTrovato(format!("cliente {}", codice.trim())))?;
    conn.prepare_cached(
        "SELECT nazione, codice_ipa, conto_banca, conto_merce, ente_pubblico, aliquota, cliente_fatturazione, fido, note, extra \
         FROM clienti_fornitori WHERE codice = ?1",
    )?
    .query_row([&scheda.codice], |r| {
        scheda.nazione = r.get(0)?;
        scheda.codice_ipa = r.get(1)?;
        scheda.conto_banca = r.get(2)?;
        scheda.conto_merce = r.get(3)?;
        scheda.ente_pubblico = r.get(4)?;
        scheda.aliquota = r.get(5)?;
        scheda.cliente_fatturazione = r.get(6)?;
        scheda.fido = r.get(7)?;
        scheda.note = r.get(8)?;
        scheda.extra = json(&r.get::<_, String>(9)?);
        Ok(())
    })?;
    let mut stmt = conn.prepare_cached(
        "SELECT codice, descrizione, indirizzo, localita, provincia, predefinita, obsoleto FROM destinazioni \
         WHERE cliente = ?1 ORDER BY predefinita DESC, codice",
    )?;
    let destinazioni = stmt.query_map([&scheda.codice], |r| {
        Ok(DestinazioneVista {
            codice: r.get(0)?,
            descrizione: r.get(1)?,
            indirizzo: r.get(2)?,
            localita: r.get(3)?,
            provincia: r.get(4)?,
            predefinita: r.get(5)?,
            obsoleto: r.get(6)?,
        })
    })?;
    scheda.destinazioni = destinazioni.collect::<Result<_, _>>()?;
    Ok(scheda)
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ArticoloBreve {
    pub codice: String,
    pub descrizione: String,
    pub unita_misura: String,
    pub aliquota: Option<String>,
    pub obsoleto: bool,
    /// Gli altri campi di Arca (`AR.Cd_ARClasse1`…), per le colonne dell'elenco.
    pub extra: serde_json::Value,
}

pub fn cerca_articoli(conn: &Connection, ricerca: &Ricerca) -> Result<Vec<ArticoloBreve>, ErroreApi> {
    let mut stmt = conn.prepare_cached(
        "SELECT codice, descrizione, unita_misura, aliquota_vendita, obsoleto, extra FROM articoli \
         WHERE (?1 OR obsoleto = 0) \
         AND (?2 IS NULL OR codice LIKE ?2 ESCAPE '\\' OR descrizione LIKE ?2 ESCAPE '\\') \
         ORDER BY codice <> ?4, NOT codice LIKE ?5 ESCAPE '\\', codice LIMIT ?3",
    )?;
    let cerca = ricerca.cerca.as_deref().filter(|c| !c.trim().is_empty());
    let (uguale, inizia) = pertinenza(cerca);
    let righe = stmt.query_map(params![ricerca.obsoleti, cerca.map(contiene), limite(ricerca.limite), uguale, inizia], |r| {
        Ok(ArticoloBreve {
            codice: r.get(0)?,
            descrizione: r.get::<_, String>(1)?.trim_end().to_owned(),
            unita_misura: r.get(2)?,
            aliquota: r.get(3)?,
            obsoleto: r.get(4)?,
            extra: json(&r.get::<_, String>(5)?),
        })
    })?;
    Ok(righe.collect::<Result<_, _>>()?)
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct UnitaVista {
    pub unita_misura: String,
    pub fattore: String,
    pub predefinita: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ArticoloScheda {
    pub codice: String,
    pub descrizione: String,
    pub descrizione_breve: Option<String>,
    pub unita_misura: String,
    pub aliquota: Option<String>,
    pub conto_ricavo: Option<String>,
    pub obsoleto: bool,
    pub unita: Vec<UnitaVista>,
    /// Gli altri campi di `AR` con i nomi delle colonne di Arca.
    pub extra: serde_json::Value,
    /// Il prezzo valido oggi in ogni listino che ha l'articolo.
    pub prezzi: Vec<PrezzoArticolo>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct PrezzoArticolo {
    pub listino: String,
    pub descrizione: String,
    pub revisione: Option<String>,
    pub valido_dal: Option<NaiveDate>,
    pub prezzo: String,
    pub sconto: Option<String>,
    pub ivato: bool,
}

pub fn articolo(conn: &Connection, codice: &str) -> Result<ArticoloScheda, ErroreApi> {
    let mut scheda = conn
        .prepare_cached(
            "SELECT codice, descrizione, descrizione_breve, unita_misura, aliquota_vendita, conto_ricavo, obsoleto, extra \
             FROM articoli WHERE codice = ?1",
        )?
        .query_row([codice.trim()], |r| {
            Ok(ArticoloScheda {
                codice: r.get(0)?,
                descrizione: r.get(1)?,
                descrizione_breve: r.get(2)?,
                unita_misura: r.get(3)?,
                aliquota: r.get(4)?,
                conto_ricavo: r.get(5)?,
                obsoleto: r.get(6)?,
                unita: Vec::new(),
                extra: json(&r.get::<_, String>(7)?),
                prezzi: Vec::new(),
            })
        })
        .optional()?
        .ok_or_else(|| ErroreApi::NonTrovato(format!("articolo {}", codice.trim())))?;
    let mut stmt = conn.prepare_cached(
        "SELECT unita_misura, fattore, predefinita FROM articoli_unita WHERE articolo = ?1 ORDER BY ordine",
    )?;
    let unita = stmt.query_map([&scheda.codice], |r| {
        Ok(UnitaVista {
            unita_misura: r.get(0)?,
            fattore: r.get(1)?,
            predefinita: r.get(2)?,
        })
    })?;
    scheda.unita = unita.collect::<Result<_, _>>()?;
    // Per ogni listino, il prezzo nella revisione valida oggi più recente che contiene l'articolo.
    let mut stmt = conn.prepare_cached(
        "SELECT l.codice, l.descrizione, r.descrizione, r.valido_dal, p.prezzo, p.sconto, l.ivato \
         FROM listini l \
         JOIN listini_prezzi p ON p.id = (SELECT p2.id FROM listini_prezzi p2 \
              JOIN listini_revisioni r2 ON r2.id = p2.revisione \
              WHERE r2.listino = l.codice AND p2.articolo = ?1 AND (r2.valido_dal IS NULL OR r2.valido_dal <= ?2) \
              ORDER BY r2.valido_dal DESC, r2.id DESC LIMIT 1) \
         JOIN listini_revisioni r ON r.id = p.revisione \
         ORDER BY l.codice",
    )?;
    let oggi = chrono::Local::now().date_naive();
    let prezzi = stmt.query_map(rusqlite::params![&scheda.codice, oggi], |r| {
        Ok(PrezzoArticolo {
            listino: r.get(0)?,
            descrizione: r.get::<_, String>(1)?.trim_end().to_owned(),
            revisione: r.get::<_, Option<String>>(2)?.map(|d| d.trim_end().to_owned()),
            valido_dal: r.get(3)?,
            prezzo: r.get(4)?,
            sconto: r.get::<_, Option<String>>(5)?.filter(|s| !s.trim().is_empty()),
            ivato: r.get(6)?,
        })
    })?;
    scheda.prezzi = prezzi.collect::<Result<_, _>>()?;
    Ok(scheda)
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Codifica {
    pub codice: String,
    pub descrizione: String,
}

/// Tabelle di codifica per le tendine e le ricerche della maschera.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Tabelle {
    pub aliquote: Vec<Codifica>,
    pub pagamenti: Vec<Codifica>,
    pub unita_misura: Vec<Codifica>,
    pub magazzini: Vec<Codifica>,
    pub agenti: Vec<Codifica>,
    pub listini: Vec<Codifica>,
}

pub fn tabelle(conn: &Connection) -> Result<Tabelle, ErroreApi> {
    let leggi = |tabella: &str| -> Result<Vec<Codifica>, ErroreApi> {
        let mut stmt = conn.prepare_cached(&format!("SELECT codice, descrizione FROM {tabella} ORDER BY codice"))?;
        let righe = stmt.query_map([], |r| {
            Ok(Codifica {
                codice: r.get(0)?,
                descrizione: r.get::<_, String>(1)?.trim_end().to_owned(),
            })
        })?;
        Ok(righe.collect::<Result<_, _>>()?)
    };
    Ok(Tabelle {
        aliquote: leggi("aliquote")?,
        pagamenti: leggi("pagamenti")?,
        unita_misura: leggi("unita_misura")?,
        magazzini: leggi("magazzini")?,
        agenti: leggi("agenti")?,
        listini: leggi("listini")?,
    })
}

/// Dove si trova un DDT rispetto ad Arca: il badge dell'elenco.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum StatoArca {
    /// Scritto in Arca (verde).
    InArca,
    /// In coda per la replica (blu).
    InCoda,
    /// La replica è fallita e riprova (rosso).
    Errore,
    /// Né in Arca né in coda.
    SoloAtlas,
}

const STATO_ARCA: &str = "CASE \
    WHEN EXISTS (SELECT 1 FROM outbox_eventi o WHERE o.documento_tipo = 'BO' AND o.documento_id = d.id \
        AND o.replicato_il IS NULL AND o.ultimo_errore IS NOT NULL) THEN 'errore' \
    WHEN EXISTS (SELECT 1 FROM outbox_eventi o WHERE o.documento_tipo = 'BO' AND o.documento_id = d.id \
        AND o.replicato_il IS NULL) THEN 'in_coda' \
    WHEN d.arca_id_testata IS NOT NULL THEN 'in_arca' ELSE 'solo_atlas' END";

fn stato_arca(testo: &str) -> StatoArca {
    match testo {
        "in_arca" => StatoArca::InArca,
        "in_coda" => StatoArca::InCoda,
        "errore" => StatoArca::Errore,
        _ => StatoArca::SoloAtlas,
    }
}

/// Filtri dell'elenco documenti.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct FiltroDdt {
    #[serde(default)]
    pub dal: Option<NaiveDate>,
    #[serde(default)]
    pub al: Option<NaiveDate>,
    /// Codice cliente.
    #[serde(default)]
    pub cliente: Option<String>,
    #[serde(default)]
    pub numero: Option<u32>,
    /// Massimo di risultati, dai più recenti (predefinito 50, al più 1000).
    #[serde(default)]
    pub limite: Option<u32>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct DdtBreve {
    pub id: i64,
    pub tipo: &'static str,
    pub esercizio: i32,
    pub numero: u32,
    pub data: NaiveDate,
    pub cliente: String,
    pub ragione_sociale: String,
    pub destinazione: Option<String>,
    /// Descrizione e località della destinazione (colonne Bottamedi dell'elenco di Arca).
    pub descrizione_destinazione: Option<String>,
    pub localita_destinazione: Option<String>,
    pub pagamento: Option<String>,
    pub listino_cliente: Option<String>,
    pub agente: Option<String>,
    pub descrizione_agente: Option<String>,
    pub righe: i64,
    pub totale_imponibile: Decimal,
    pub totale_documento: Decimal,
    /// Netto a pagare: senza l'imposta in scissione dei pagamenti.
    pub netto_a_pagare: Decimal,
    /// `DOTes.Id_DoTes` in Arca.
    pub arca_id_testata: Option<i32>,
    pub arca: StatoArca,
}

fn decimale(r: &rusqlite::Row<'_>, i: usize) -> rusqlite::Result<Decimal> {
    let testo: String = r.get(i)?;
    testo
        .parse()
        .map_err(|e| rusqlite::Error::FromSqlConversionFailure(i, rusqlite::types::Type::Text, Box::new(e)))
}

pub fn elenco_ddt(conn: &Connection, filtro: &FiltroDdt) -> Result<Vec<DdtBreve>, ErroreApi> {
    let mut stmt = conn.prepare_cached(&format!(
        "SELECT d.id, d.esercizio, d.numero, d.data, d.cliente, c.ragione_sociale, d.destinazione, t.localita, \
         d.totale_imponibile, d.totale_documento, {STATO_ARCA}, t.descrizione, d.pagamento, d.listino_cliente, \
         d.agente, a.descrizione, (SELECT count(*) FROM ddt_righe r WHERE r.ddt = d.id), \
         CASE WHEN d.scissione_pagamenti THEN d.totale_imponibile ELSE d.totale_documento END, d.arca_id_testata \
         FROM ddt d JOIN clienti_fornitori c ON c.codice = d.cliente \
         LEFT JOIN destinazioni t ON t.cliente = d.cliente AND t.codice = d.destinazione \
         LEFT JOIN agenti a ON a.codice = d.agente \
         WHERE (?1 IS NULL OR d.data >= ?1) AND (?2 IS NULL OR d.data <= ?2) AND (?3 IS NULL OR d.cliente = ?3) \
         AND (?4 IS NULL OR d.numero = ?4) \
         ORDER BY d.data DESC, d.numero DESC LIMIT ?5"
    ))?;
    let cliente = filtro.cliente.as_deref().map(str::trim).filter(|c| !c.is_empty());
    let righe = stmt.query_map(params![filtro.dal, filtro.al, cliente, filtro.numero, limite(filtro.limite)], |r| {
        Ok(DdtBreve {
            id: r.get(0)?,
            tipo: atlas_db::ddt::TIPO_DOCUMENTO,
            esercizio: r.get(1)?,
            numero: r.get(2)?,
            data: r.get(3)?,
            cliente: r.get(4)?,
            ragione_sociale: r.get::<_, String>(5)?.trim_end().to_owned(),
            destinazione: r.get(6)?,
            localita_destinazione: r.get::<_, Option<String>>(7)?.map(|d| d.trim_end().to_owned()),
            totale_imponibile: decimale(r, 8)?,
            totale_documento: decimale(r, 9)?,
            arca: stato_arca(&r.get::<_, String>(10)?),
            descrizione_destinazione: r.get::<_, Option<String>>(11)?.map(|d| d.trim_end().to_owned()),
            pagamento: r.get(12)?,
            listino_cliente: r.get(13)?,
            agente: r.get(14)?,
            descrizione_agente: r.get::<_, Option<String>>(15)?.map(|d| d.trim_end().to_owned()),
            righe: r.get(16)?,
            netto_a_pagare: decimale(r, 17)?,
            arca_id_testata: r.get(18)?,
        })
    })?;
    Ok(righe.collect::<Result<_, _>>()?)
}

/// Riga del DDT con quantità e totale calcolati al salvataggio.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct RigaVista {
    #[serde(flatten)]
    pub riga: RigaDdt,
    pub quantita: Decimal,
    pub totale: Decimal,
}

/// Evento di replica di un documento.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct EventoVista {
    pub id: i64,
    pub operazione: String,
    pub creato_il: NaiveDateTime,
    pub tentativi: i64,
    pub ultimo_errore: Option<String>,
    pub prossimo_tentativo_il: Option<NaiveDateTime>,
    pub replicato_il: Option<NaiveDateTime>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct DdtScheda {
    pub id: i64,
    pub tipo: &'static str,
    pub esercizio: i32,
    pub numero: u32,
    pub ragione_sociale: String,
    pub documento: Ddt,
    pub righe: Vec<RigaVista>,
    pub castelletto: Castelletto,
    pub netto_a_pagare: Decimal,
    pub arca: StatoArca,
    /// `DOTes.Id_DoTes` in Arca.
    pub arca_id_testata: Option<i32>,
    pub eventi: Vec<EventoVista>,
}

pub fn ddt(conn: &Connection, id: i64) -> Result<DdtScheda, ErroreApi> {
    // Testata, righe ed eventi dalla stessa fotografia del database.
    let tx = conn.unchecked_transaction()?;
    let documento = match atlas_db::ddt::carica(&tx, id) {
        Err(atlas_db::ErroreDb::NonTrovato(_)) => return Err(ErroreApi::NonTrovato(format!("DDT {id}"))),
        esito => esito?,
    };
    let (esercizio, ragione_sociale, arca_id_testata, arca): (i32, String, Option<i32>, String) = tx
        .prepare_cached(&format!(
            "SELECT d.esercizio, c.ragione_sociale, d.arca_id_testata, {STATO_ARCA} FROM ddt d \
             JOIN clienti_fornitori c ON c.codice = d.cliente WHERE d.id = ?1"
        ))?
        .query_row([id], |r| Ok((r.get(0)?, r.get::<_, String>(1)?.trim_end().to_owned(), r.get(2)?, r.get(3)?)))?;
    let mut stmt = tx.prepare_cached("SELECT quantita, totale FROM ddt_righe WHERE ddt = ?1 ORDER BY riga")?;
    let calcolate: Vec<(Decimal, Decimal)> =
        stmt.query_map([id], |r| Ok((decimale(r, 0)?, decimale(r, 1)?)))?.collect::<Result<_, _>>()?;
    let righe: Vec<RigaVista> = documento
        .righe
        .iter()
        .zip(calcolate)
        .map(|(riga, (quantita, totale))| RigaVista {
            riga: riga.clone(),
            quantita,
            totale,
        })
        .collect();
    let aliquote = atlas_db::anagrafiche::tabella_aliquote(&tx)?;
    let codici: Vec<CodiceAliquota> = righe.iter().map(|r| r.riga.aliquota.clone()).collect();
    let castelletto = Castelletto::calcola(codici.iter().zip(&righe).map(|(a, r)| (a, r.totale)), &aliquote)?;
    let mut stmt = tx.prepare_cached(
        "SELECT id, operazione, creato_il, tentativi, ultimo_errore, prossimo_tentativo_il, replicato_il \
         FROM outbox_eventi WHERE documento_tipo = 'BO' AND documento_id = ?1 ORDER BY id",
    )?;
    let eventi = stmt
        .query_map([id], |r| {
            Ok(EventoVista {
                id: r.get(0)?,
                operazione: r.get(1)?,
                creato_il: r.get(2)?,
                tentativi: r.get(3)?,
                ultimo_errore: r.get(4)?,
                prossimo_tentativo_il: r.get(5)?,
                replicato_il: r.get(6)?,
            })
        })?
        .collect::<Result<_, _>>()?;
    Ok(DdtScheda {
        id,
        tipo: atlas_db::ddt::TIPO_DOCUMENTO,
        esercizio,
        numero: documento.numero,
        ragione_sociale,
        netto_a_pagare: castelletto.netto_a_pagare(documento.scissione_pagamenti, Decimal::ZERO),
        documento,
        righe,
        castelletto,
        arca: stato_arca(&arca),
        arca_id_testata,
        eventi,
    })
}

/// Un DDT ATLAS fermo su un conflitto con Arca, con le azioni possibili.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Conflitto {
    /// `replica` (evento in coda che fallisce) o `importazione` (documento di Arca con lo stesso
    /// numero di un DDT ATLAS).
    pub origine: &'static str,
    pub ddt: i64,
    pub esercizio: i32,
    pub numero: u32,
    pub errore: String,
    /// `rinumera` solo se il DDT non è ancora in Arca: lì il numero è la sua identità.
    pub azioni: Vec<&'static str>,
}

/// Coda di replica vista dal database.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Coda {
    pub in_coda: i64,
    /// Primo evento in coda, se ha già fallito: ferma quelli dopo.
    pub fermo: Option<EventoFermo>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct EventoFermo {
    pub evento: i64,
    pub ddt: i64,
    pub numero: Option<u32>,
    pub esercizio: Option<i32>,
    pub tentativi: i64,
    pub ultimo_errore: String,
    pub prossimo_tentativo_il: Option<NaiveDateTime>,
}

pub fn coda(conn: &Connection) -> Result<Coda, ErroreApi> {
    let in_coda = atlas_db::outbox::in_attesa(conn)?;
    let fermo = conn
        .prepare_cached(
            "SELECT o.id, o.documento_id, d.numero, d.esercizio, o.tentativi, o.ultimo_errore, o.prossimo_tentativo_il \
             FROM outbox_eventi o LEFT JOIN ddt d ON d.id = o.documento_id \
             WHERE o.replicato_il IS NULL AND o.ultimo_errore IS NOT NULL \
             AND o.id = (SELECT min(id) FROM outbox_eventi WHERE replicato_il IS NULL)",
        )?
        .query_row([], |r| {
            Ok(EventoFermo {
                evento: r.get(0)?,
                ddt: r.get(1)?,
                numero: r.get(2)?,
                esercizio: r.get(3)?,
                tentativi: r.get(4)?,
                ultimo_errore: r.get(5)?,
                prossimo_tentativo_il: r.get(6)?,
            })
        })
        .optional()?;
    Ok(Coda { in_coda, fermo })
}

/// Il DDT ATLAS non ancora in Arca con questo numero: quello conteso da un documento di Arca.
pub fn conteso(conn: &Connection, esercizio: i32, numero: u32) -> Result<Option<i64>, ErroreApi> {
    Ok(conn
        .prepare_cached("SELECT id FROM ddt WHERE esercizio = ?1 AND numero = ?2 AND arca_id_testata IS NULL")?
        .query_row(params![esercizio, numero], |r| r.get(0))
        .optional()?)
}

/// `rinumera` se il DDT non è in Arca.
pub fn azioni(conn: &Connection, ddt: i64) -> Result<Vec<&'static str>, ErroreApi> {
    let in_arca: Option<Option<i32>> = conn
        .prepare_cached("SELECT arca_id_testata FROM ddt WHERE id = ?1")?
        .query_row([ddt], |r| r.get(0))
        .optional()?;
    Ok(match in_arca {
        Some(None) => vec!["rinumera"],
        _ => Vec::new(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use atlas_db::ddt::salva;
    use atlas_db::outbox;
    use atlas_db::prova::{adesso, database, ddt as prova};
    use rust_decimal_macros::dec;

    #[test]
    fn ricerche_per_codice_e_descrizione() {
        let conn = database();
        let tutti = cerca_clienti(&conn, &Ricerca::default()).unwrap();
        assert_eq!(tutti.len(), 2);
        let ricerca = Ricerca {
            cerca: Some("0380".into()),
            ..Ricerca::default()
        };
        assert_eq!(cerca_clienti(&conn, &ricerca).unwrap()[0].partita_iva.as_deref(), Some("01392110225"));
        let ricerca = Ricerca {
            cerca: Some("pist".into()),
            ..Ricerca::default()
        };
        assert_eq!(cerca_articoli(&conn, &ricerca).unwrap()[0].codice, "PIST");
        // "BAN" è nella descrizione di PIST (finta) e uguale al codice BAN: BAN viene prima.
        conn.execute("UPDATE articoli SET descrizione = 'PISTACCHI BANCO' WHERE codice = 'PIST'", []).unwrap();
        let ricerca = Ricerca {
            cerca: Some("ban".into()),
            ..Ricerca::default()
        };
        let trovati: Vec<String> = cerca_articoli(&conn, &ricerca).unwrap().into_iter().map(|a| a.codice).collect();
        assert_eq!(trovati, ["BAN", "PIST"]);
        let ricerca = Ricerca {
            cerca: Some("%".into()),
            ..Ricerca::default()
        };
        assert!(cerca_articoli(&conn, &ricerca).unwrap().is_empty(), "% preso alla lettera");
        assert_eq!(cliente(&conn, "c000380").unwrap().destinazioni[0].codice, "ALI");
        assert_eq!(articolo(&conn, "ban").unwrap().unita[0].unita_misura, "KG");
        assert_eq!(tabelle(&conn).unwrap().aliquote.len(), 3);
    }

    #[test]
    fn elenco_e_scheda_con_lo_stato_in_arca() {
        let mut conn = database();
        let primo = salva(&mut conn, &prova(5457), adesso()).unwrap();
        let secondo = salva(&mut conn, &prova(5458), adesso()).unwrap();
        outbox::segna_replicato(&conn, primo.evento, 120_545, adesso()).unwrap();
        outbox::segna_fallito(&conn, secondo.evento, "rete", adesso()).unwrap();
        let elenco = elenco_ddt(&conn, &FiltroDdt::default()).unwrap();
        let stati: Vec<(u32, StatoArca)> = elenco.iter().map(|d| (d.numero, d.arca)).collect();
        assert_eq!(stati, [(5458, StatoArca::Errore), (5457, StatoArca::InArca)]);
        assert_eq!(elenco[0].totale_documento, dec!(21.98));
        assert_eq!((elenco[0].righe, elenco[0].netto_a_pagare, elenco[1].arca_id_testata), (2, dec!(21.98), Some(120_545)));
        assert_eq!(elenco[0].descrizione_destinazione.as_deref(), Some("Mensa"));
        let filtro = FiltroDdt {
            numero: Some(5457),
            ..FiltroDdt::default()
        };
        assert_eq!(elenco_ddt(&conn, &filtro).unwrap().len(), 1);

        let scheda = ddt(&conn, secondo.id).unwrap();
        assert_eq!((scheda.righe[0].quantita, scheda.righe[0].totale), (dec!(5.16), dec!(9.29)));
        assert_eq!(scheda.castelletto.totale_documento, dec!(21.98));
        assert_eq!(scheda.eventi[0].ultimo_errore.as_deref(), Some("rete"));
        assert!(matches!(ddt(&conn, 999), Err(ErroreApi::NonTrovato(_))));

        let coda = coda(&conn).unwrap();
        assert_eq!((coda.in_coda, coda.fermo.unwrap().numero), (1, Some(5458)));
        assert_eq!(conteso(&conn, 2026, 5458).unwrap(), Some(secondo.id));
        assert_eq!(conteso(&conn, 2026, 5457).unwrap(), None, "già in Arca");
        assert_eq!(azioni(&conn, secondo.id).unwrap(), ["rinumera"]);
        assert!(azioni(&conn, primo.id).unwrap().is_empty());
    }
}
