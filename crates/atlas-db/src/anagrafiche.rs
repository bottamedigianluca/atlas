//! Anagrafiche di ATLAS, oggi importate da Arca.
//!
//! [`aggiorna`] porta il database allo stato letto in un'unica transazione: inserisce le righe
//! nuove, aggiorna solo quelle cambiate e non cancella nulla (una riga sparita da Arca può
//! essere citata dai documenti: viene contata e lasciata). Ripetere l'import con gli stessi dati
//! non modifica nessuna riga.

use atlas_core::aliquota::{CodiceAliquota, TabellaAliquote};
use chrono::NaiveDate;
use rusqlite::types::Value;
use rusqlite::{Connection, OptionalExtension, TransactionBehavior, params_from_iter};
use rust_decimal::Decimal;

use crate::ErroreDb;
use crate::valori::Dec;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Aliquota {
    pub codice: String,
    pub descrizione: String,
    pub percentuale: Decimal,
    pub natura: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Pagamento {
    pub codice: String,
    pub descrizione: String,
    pub conto_banca: Option<String>,
}

/// Anagrafica con solo codice e descrizione (unità di misura, magazzini, agenti).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Codifica {
    pub codice: String,
    pub descrizione: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Listino {
    pub codice: String,
    pub descrizione: String,
    pub ivato: bool,
    pub tipo: i64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RevisioneListino {
    pub id: i64,
    pub listino: String,
    pub descrizione: String,
    pub valido_dal: Option<NaiveDate>,
    pub pubblicata_il: Option<NaiveDate>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Articolo {
    pub codice: String,
    pub descrizione: String,
    pub descrizione_breve: Option<String>,
    pub unita_misura: String,
    pub aliquota_vendita: Option<String>,
    pub conto_ricavo: Option<String>,
    pub obsoleto: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UnitaArticolo {
    pub articolo: String,
    pub unita_misura: String,
    pub fattore: Decimal,
    pub predefinita: bool,
    pub ordine: i64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PrezzoListino {
    pub id: i64,
    pub revisione: i64,
    pub articolo: String,
    pub prezzo: Decimal,
    pub sconto: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ClienteFornitore {
    pub codice: String,
    pub ragione_sociale: String,
    pub indirizzo: Option<String>,
    pub cap: Option<String>,
    pub localita: Option<String>,
    pub provincia: Option<String>,
    pub nazione: Option<String>,
    pub partita_iva: Option<String>,
    pub codice_fiscale: Option<String>,
    pub codice_destinatario: Option<String>,
    pub codice_ipa: Option<String>,
    pub cliente: bool,
    pub fornitore: bool,
    pub pagamento: Option<String>,
    pub listino: Option<String>,
    pub iban: Option<String>,
    pub bic: Option<String>,
    pub conto_banca: Option<String>,
    pub conto_merce: Option<String>,
    pub agente: Option<String>,
    pub scissione_pagamenti: bool,
    pub ente_pubblico: bool,
    pub aliquota: Option<String>,
    pub cliente_fatturazione: Option<String>,
    pub fido: Option<Decimal>,
    pub note: Option<String>,
    pub obsoleto: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Destinazione {
    pub cliente: String,
    pub codice: String,
    pub descrizione: String,
    pub indirizzo: Option<String>,
    pub cap: Option<String>,
    pub localita: Option<String>,
    pub provincia: Option<String>,
    pub nazione: Option<String>,
    pub agente: Option<String>,
    pub aliquota: Option<String>,
    pub predefinita: bool,
    pub obsoleto: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PredefinitiRighe {
    pub conto_ricavo: String,
    pub aliquota: String,
}

/// Fotografia completa delle anagrafiche da portare nel database.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Anagrafiche {
    pub aliquote: Vec<Aliquota>,
    pub pagamenti: Vec<Pagamento>,
    pub unita_misura: Vec<Codifica>,
    pub magazzini: Vec<Codifica>,
    pub agenti: Vec<Codifica>,
    pub listini: Vec<Listino>,
    pub revisioni_listino: Vec<RevisioneListino>,
    pub articoli: Vec<Articolo>,
    pub unita_articoli: Vec<UnitaArticolo>,
    pub prezzi_listino: Vec<PrezzoListino>,
    pub clienti_fornitori: Vec<ClienteFornitore>,
    pub destinazioni: Vec<Destinazione>,
    pub predefiniti_righe: PredefinitiRighe,
}

/// Esito dell'aggiornamento di una tabella.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Esito {
    pub tabella: &'static str,
    pub inserite: usize,
    pub aggiornate: usize,
    pub invariate: usize,
    /// Righe presenti in ATLAS ma non nei dati importati.
    pub assenti: usize,
}

fn testo(valore: &str) -> Value {
    Value::Text(valore.to_owned())
}

fn testo_opz(valore: Option<&str>) -> Value {
    valore.map_or(Value::Null, testo)
}

fn bit(valore: bool) -> Value {
    Value::Integer(i64::from(valore))
}

fn decimale(valore: Decimal) -> Value {
    Value::Text(valore.to_string())
}

fn data_opz(valore: Option<NaiveDate>) -> Value {
    valore.map_or(Value::Null, |d| Value::Text(d.format("%Y-%m-%d").to_string()))
}

/// Riga di una tabella di anagrafica: prima le colonne di chiave, poi le altre.
trait Tabella {
    const NOME: &'static str;
    const CHIAVE: &'static [&'static str];
    const COLONNE: &'static [&'static str];
    fn valori(&self) -> Vec<Value>;
}

impl Tabella for Aliquota {
    const NOME: &'static str = "aliquote";
    const CHIAVE: &'static [&'static str] = &["codice"];
    const COLONNE: &'static [&'static str] = &["descrizione", "percentuale", "natura"];
    fn valori(&self) -> Vec<Value> {
        vec![
            testo(&self.codice),
            testo(&self.descrizione),
            decimale(self.percentuale),
            testo_opz(self.natura.as_deref()),
        ]
    }
}

impl Tabella for Pagamento {
    const NOME: &'static str = "pagamenti";
    const CHIAVE: &'static [&'static str] = &["codice"];
    const COLONNE: &'static [&'static str] = &["descrizione", "conto_banca"];
    fn valori(&self) -> Vec<Value> {
        vec![testo(&self.codice), testo(&self.descrizione), testo_opz(self.conto_banca.as_deref())]
    }
}

/// Le tabelle di sola codifica condividono la struttura e differiscono per nome.
macro_rules! codifica {
    ($tipo:ident, $nome:literal) => {
        struct $tipo<'a>(&'a Codifica);
        impl Tabella for $tipo<'_> {
            const NOME: &'static str = $nome;
            const CHIAVE: &'static [&'static str] = &["codice"];
            const COLONNE: &'static [&'static str] = &["descrizione"];
            fn valori(&self) -> Vec<Value> {
                vec![testo(&self.0.codice), testo(&self.0.descrizione)]
            }
        }
    };
}
codifica!(UnitaMisura, "unita_misura");
codifica!(Magazzino, "magazzini");
codifica!(Agente, "agenti");

impl Tabella for Listino {
    const NOME: &'static str = "listini";
    const CHIAVE: &'static [&'static str] = &["codice"];
    const COLONNE: &'static [&'static str] = &["descrizione", "ivato", "tipo"];
    fn valori(&self) -> Vec<Value> {
        vec![
            testo(&self.codice),
            testo(&self.descrizione),
            bit(self.ivato),
            Value::Integer(self.tipo),
        ]
    }
}

impl Tabella for RevisioneListino {
    const NOME: &'static str = "listini_revisioni";
    const CHIAVE: &'static [&'static str] = &["id"];
    const COLONNE: &'static [&'static str] = &["listino", "descrizione", "valido_dal", "pubblicata_il"];
    fn valori(&self) -> Vec<Value> {
        vec![
            Value::Integer(self.id),
            testo(&self.listino),
            testo(&self.descrizione),
            data_opz(self.valido_dal),
            data_opz(self.pubblicata_il),
        ]
    }
}

impl Tabella for Articolo {
    const NOME: &'static str = "articoli";
    const CHIAVE: &'static [&'static str] = &["codice"];
    const COLONNE: &'static [&'static str] = &[
        "descrizione",
        "descrizione_breve",
        "unita_misura",
        "aliquota_vendita",
        "conto_ricavo",
        "obsoleto",
    ];
    fn valori(&self) -> Vec<Value> {
        vec![
            testo(&self.codice),
            testo(&self.descrizione),
            testo_opz(self.descrizione_breve.as_deref()),
            testo(&self.unita_misura),
            testo_opz(self.aliquota_vendita.as_deref()),
            testo_opz(self.conto_ricavo.as_deref()),
            bit(self.obsoleto),
        ]
    }
}

impl Tabella for UnitaArticolo {
    const NOME: &'static str = "articoli_unita";
    const CHIAVE: &'static [&'static str] = &["articolo", "unita_misura"];
    const COLONNE: &'static [&'static str] = &["fattore", "predefinita", "ordine"];
    fn valori(&self) -> Vec<Value> {
        vec![
            testo(&self.articolo),
            testo(&self.unita_misura),
            decimale(self.fattore),
            bit(self.predefinita),
            Value::Integer(self.ordine),
        ]
    }
}

impl Tabella for PrezzoListino {
    const NOME: &'static str = "listini_prezzi";
    const CHIAVE: &'static [&'static str] = &["id"];
    const COLONNE: &'static [&'static str] = &["revisione", "articolo", "prezzo", "sconto"];
    fn valori(&self) -> Vec<Value> {
        vec![
            Value::Integer(self.id),
            Value::Integer(self.revisione),
            testo(&self.articolo),
            decimale(self.prezzo),
            testo_opz(self.sconto.as_deref()),
        ]
    }
}

impl Tabella for ClienteFornitore {
    const NOME: &'static str = "clienti_fornitori";
    const CHIAVE: &'static [&'static str] = &["codice"];
    const COLONNE: &'static [&'static str] = &[
        "ragione_sociale",
        "indirizzo",
        "cap",
        "localita",
        "provincia",
        "nazione",
        "partita_iva",
        "codice_fiscale",
        "codice_destinatario",
        "codice_ipa",
        "cliente",
        "fornitore",
        "pagamento",
        "listino",
        "iban",
        "bic",
        "conto_banca",
        "conto_merce",
        "agente",
        "scissione_pagamenti",
        "ente_pubblico",
        "aliquota",
        "cliente_fatturazione",
        "fido",
        "note",
        "obsoleto",
    ];
    fn valori(&self) -> Vec<Value> {
        vec![
            testo(&self.codice),
            testo(&self.ragione_sociale),
            testo_opz(self.indirizzo.as_deref()),
            testo_opz(self.cap.as_deref()),
            testo_opz(self.localita.as_deref()),
            testo_opz(self.provincia.as_deref()),
            testo_opz(self.nazione.as_deref()),
            testo_opz(self.partita_iva.as_deref()),
            testo_opz(self.codice_fiscale.as_deref()),
            testo_opz(self.codice_destinatario.as_deref()),
            testo_opz(self.codice_ipa.as_deref()),
            bit(self.cliente),
            bit(self.fornitore),
            testo_opz(self.pagamento.as_deref()),
            testo_opz(self.listino.as_deref()),
            testo_opz(self.iban.as_deref()),
            testo_opz(self.bic.as_deref()),
            testo_opz(self.conto_banca.as_deref()),
            testo_opz(self.conto_merce.as_deref()),
            testo_opz(self.agente.as_deref()),
            bit(self.scissione_pagamenti),
            bit(self.ente_pubblico),
            testo_opz(self.aliquota.as_deref()),
            testo_opz(self.cliente_fatturazione.as_deref()),
            self.fido.map_or(Value::Null, decimale),
            testo_opz(self.note.as_deref()),
            bit(self.obsoleto),
        ]
    }
}

impl Tabella for Destinazione {
    const NOME: &'static str = "destinazioni";
    const CHIAVE: &'static [&'static str] = &["cliente", "codice"];
    const COLONNE: &'static [&'static str] = &[
        "descrizione",
        "indirizzo",
        "cap",
        "localita",
        "provincia",
        "nazione",
        "agente",
        "aliquota",
        "predefinita",
        "obsoleto",
    ];
    fn valori(&self) -> Vec<Value> {
        vec![
            testo(&self.cliente),
            testo(&self.codice),
            testo(&self.descrizione),
            testo_opz(self.indirizzo.as_deref()),
            testo_opz(self.cap.as_deref()),
            testo_opz(self.localita.as_deref()),
            testo_opz(self.provincia.as_deref()),
            testo_opz(self.nazione.as_deref()),
            testo_opz(self.agente.as_deref()),
            testo_opz(self.aliquota.as_deref()),
            bit(self.predefinita),
            bit(self.obsoleto),
        ]
    }
}

impl Tabella for PredefinitiRighe {
    const NOME: &'static str = "predefiniti_righe";
    const CHIAVE: &'static [&'static str] = &["id"];
    const COLONNE: &'static [&'static str] = &["conto_ricavo", "aliquota"];
    fn valori(&self) -> Vec<Value> {
        vec![Value::Integer(1), testo(&self.conto_ricavo), testo(&self.aliquota)]
    }
}

/// Inserisce le righe nuove e aggiorna quelle cambiate. Il confronto è binario anche sulle
/// colonne `NOCASE`, così un codice corretto da `kg` a `KG` viene aggiornato.
fn allinea<T: Tabella>(conn: &Connection, righe: &[T]) -> Result<Esito, ErroreDb> {
    let tutte: Vec<&str> = T::CHIAVE.iter().chain(T::COLONNE).copied().collect();
    let segnaposti: Vec<String> = (1..=tutte.len()).map(|i| format!("?{i}")).collect();
    let inserisci = format!(
        "INSERT INTO {} ({}) VALUES ({}) ON CONFLICT DO NOTHING",
        T::NOME,
        tutte.join(", "),
        segnaposti.join(", ")
    );
    let chiave = T::CHIAVE.len();
    let assegna: Vec<String> = T::COLONNE
        .iter()
        .enumerate()
        .map(|(i, c)| format!("{c} = ?{}", chiave + i + 1))
        .collect();
    let dove: Vec<String> = T::CHIAVE.iter().enumerate().map(|(i, c)| format!("{c} = ?{}", i + 1)).collect();
    let diversa: Vec<String> = T::COLONNE
        .iter()
        .enumerate()
        .map(|(i, c)| format!("{c} IS NOT ?{} COLLATE BINARY", chiave + i + 1))
        .collect();
    let aggiorna = format!(
        "UPDATE {} SET {} WHERE {} AND ({})",
        T::NOME,
        assegna.join(", "),
        dove.join(" AND "),
        diversa.join(" OR ")
    );

    let mut esito = Esito {
        tabella: T::NOME,
        ..Esito::default()
    };
    let mut inserimento = conn.prepare_cached(&inserisci)?;
    let mut aggiornamento = conn.prepare_cached(&aggiorna)?;
    for riga in righe {
        let valori = riga.valori();
        if inserimento.execute(params_from_iter(&valori))? == 1 {
            esito.inserite += 1;
        } else if aggiornamento.execute(params_from_iter(&valori))? == 1 {
            esito.aggiornate += 1;
        } else {
            esito.invariate += 1;
        }
    }
    let presenti: i64 = conn.query_row(&format!("SELECT count(*) FROM {}", T::NOME), [], |r| r.get(0))?;
    esito.assenti = usize::try_from(presenti).unwrap_or_default().saturating_sub(righe.len());
    Ok(esito)
}

/// Porta le anagrafiche allo stato `dati` in una transazione. Le chiavi esterne sono
/// controllate alla fine, così l'ordine delle tabelle non conta; una violazione annulla tutto
/// e viene descritta riga per riga.
pub fn aggiorna(conn: &mut Connection, dati: &Anagrafiche) -> Result<Vec<Esito>, ErroreDb> {
    let tx = conn.transaction_with_behavior(TransactionBehavior::Immediate)?;
    tx.pragma_update(None, "defer_foreign_keys", true)?;
    let esiti = vec![
        allinea(&tx, &dati.aliquote)?,
        allinea(&tx, &dati.pagamenti)?,
        allinea(&tx, &dati.unita_misura.iter().map(UnitaMisura).collect::<Vec<_>>())?,
        allinea(&tx, &dati.magazzini.iter().map(Magazzino).collect::<Vec<_>>())?,
        allinea(&tx, &dati.agenti.iter().map(Agente).collect::<Vec<_>>())?,
        allinea(&tx, &dati.listini)?,
        allinea(&tx, &dati.revisioni_listino)?,
        allinea(&tx, &dati.articoli)?,
        allinea(&tx, &dati.unita_articoli)?,
        allinea(&tx, &dati.prezzi_listino)?,
        allinea(&tx, &dati.clienti_fornitori)?,
        allinea(&tx, &dati.destinazioni)?,
        allinea(&tx, std::slice::from_ref(&dati.predefiniti_righe))?,
    ];
    let violazioni = violazioni_chiavi_esterne(&tx)?;
    if !violazioni.is_empty() {
        return Err(ErroreDb::RiferimentiInesistenti(violazioni.join("; ")));
    }
    tx.commit()?;
    Ok(esiti)
}

/// Righe che citano una chiave inesistente (`PRAGMA foreign_key_check`), al massimo 20.
fn violazioni_chiavi_esterne(conn: &Connection) -> Result<Vec<String>, ErroreDb> {
    let mut stmt = conn.prepare("PRAGMA foreign_key_check")?;
    let righe = stmt.query_map([], |r| {
        Ok(format!(
            "{} (riga {}) → {}",
            r.get::<_, String>(0)?,
            r.get::<_, Option<i64>>(1)?.map_or_else(|| "?".to_owned(), |n| n.to_string()),
            r.get::<_, String>(2)?
        ))
    })?;
    Ok(righe.take(20).collect::<Result<_, _>>()?)
}

/// Aliquote in vigore, per i calcoli del motore.
pub fn tabella_aliquote(conn: &Connection) -> Result<TabellaAliquote, ErroreDb> {
    let mut stmt = conn.prepare_cached("SELECT codice, percentuale FROM aliquote")?;
    let righe = stmt.query_map([], |r| {
        Ok((CodiceAliquota::nuovo(&r.get::<_, String>(0)?), r.get::<_, Dec>(1)?.0))
    })?;
    Ok(righe.collect::<Result<_, _>>()?)
}

pub fn predefiniti_righe(conn: &Connection) -> Result<Option<PredefinitiRighe>, ErroreDb> {
    Ok(conn
        .query_row("SELECT conto_ricavo, aliquota FROM predefiniti_righe WHERE id = 1", [], |r| {
            Ok(PredefinitiRighe {
                conto_ricavo: r.get(0)?,
                aliquota: r.get(1)?,
            })
        })
        .optional()?)
}

#[cfg(test)]
mod tests {
    use crate::prova::*;
    use super::*;
    use rust_decimal_macros::dec;

    fn conteggi(esiti: &[Esito]) -> (usize, usize, usize, usize) {
        esiti.iter().fold((0, 0, 0, 0), |(i, a, v, s), e| {
            (i + e.inserite, a + e.aggiornate, v + e.invariate, s + e.assenti)
        })
    }

    #[test]
    fn import_ripetuto_non_modifica_nulla() {
        let mut conn = crate::apri_in_memoria().unwrap();
        let dati = anagrafiche();
        let (inserite, aggiornate, _, _) = conteggi(&aggiorna(&mut conn, &dati).unwrap());
        assert_eq!((inserite, aggiornate), (19, 0));
        assert_eq!(conteggi(&aggiorna(&mut conn, &dati).unwrap()), (0, 0, 19, 0));
    }

    #[test]
    fn aggiorna_solo_le_righe_cambiate_e_conta_le_assenti() {
        let mut conn = database();
        let mut dati = anagrafiche();
        dati.articoli[0].unita_misura = "KG".into();
        dati.prezzi_listino[0].prezzo = dec!(1.85);
        dati.clienti_fornitori.pop();
        let esiti = aggiorna(&mut conn, &dati).unwrap();
        let di = |t: &str| esiti.iter().find(|e| e.tabella == t).copied().unwrap();
        assert_eq!(di("articoli").aggiornate, 1, "kg → KG è una modifica");
        assert_eq!(di("listini_prezzi").aggiornate, 1);
        assert_eq!(di("clienti_fornitori").assenti, 1);
        let prezzo: Dec = conn.query_row("SELECT prezzo FROM listini_prezzi WHERE id = 333", [], |r| r.get(0)).unwrap();
        assert_eq!(prezzo.0, dec!(1.85));
    }

    #[test]
    fn codici_senza_distinzione_di_maiuscole_come_in_arca() {
        let conn = database();
        // L'articolo BAN ha UM `kg`, l'anagrafica `KG`: la chiave esterna è soddisfatta.
        let n: i64 = conn
            .query_row("SELECT count(*) FROM articoli a JOIN unita_misura u ON u.codice = a.unita_misura", [], |r| r.get(0))
            .unwrap();
        assert_eq!(n, 2);
        let n: i64 = conn.query_row("SELECT count(*) FROM clienti_fornitori WHERE codice = 'c000380'", [], |r| r.get(0)).unwrap();
        assert_eq!(n, 1);
    }

    #[test]
    fn riferimento_inesistente_annulla_tutto_e_lo_descrive() {
        let mut conn = crate::apri_in_memoria().unwrap();
        let mut dati = anagrafiche();
        dati.articoli[1].aliquota_vendita = Some("99".into());
        let errore = aggiorna(&mut conn, &dati).unwrap_err().to_string();
        assert!(errore.contains("articoli"), "{errore}");
        let n: i64 = conn.query_row("SELECT count(*) FROM aliquote", [], |r| r.get(0)).unwrap();
        assert_eq!(n, 0, "transazione annullata");
    }

    #[test]
    fn aliquote_e_predefiniti_per_il_motore() {
        let conn = database();
        let tabella = tabella_aliquote(&conn).unwrap();
        assert_eq!(tabella.percentuale(&CodiceAliquota::nuovo("10")).unwrap(), dec!(10));
        assert_eq!(predefiniti_righe(&conn).unwrap().unwrap().aliquota, "04");
    }
}
