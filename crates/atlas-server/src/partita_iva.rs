//! Partita IVA: controllo della cifra di controllo e dati dell'azienda dal servizio VIES della
//! Commissione europea (per l'Italia restituisce ragione sociale e indirizzo registrati
//! all'Agenzia delle Entrate). Serve a precompilare l'anagrafica di un cliente nuovo e a
//! confrontare i dati che si hanno con quelli ufficiali.
//!
//! Il backend chiama VIES (non il browser): la postazione deve poter uscire su internet. Senza
//! rete la risposta è `non_disponibile` e si scrive a mano come prima.

use std::time::Duration;

use rusqlite::{Connection, OptionalExtension};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use crate::errore::ErroreApi;

pub const VIES_PREDEFINITO: &str = "https://ec.europa.eu/taxation_customs/vies/rest-api/check-vat-number";

/// Oltre questo tempo VIES si considera non raggiungibile: chi batte non resta ad aspettare.
const ATTESA: Duration = Duration::from_secs(8);

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct RichiestaPartitaIva {
    /// Codice ISO del paese (predefinito IT).
    #[serde(default)]
    pub nazione: Option<String>,
}

/// I dati ufficiali dell'azienda, già divisi nei campi dell'anagrafica.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct DatiAzienda {
    pub nazione: String,
    pub partita_iva: String,
    /// Partita IVA attiva secondo VIES.
    pub attiva: bool,
    pub ragione_sociale: Option<String>,
    pub indirizzo: Option<String>,
    pub cap: Option<String>,
    pub localita: Option<String>,
    pub provincia: Option<String>,
    /// L'indirizzo come lo restituisce VIES, per controllo.
    pub indirizzo_vies: Option<String>,
    /// Il cliente o fornitore che in ATLAS ha già questa partita IVA.
    pub gia_presente: Option<String>,
}

/// Partita IVA ripulita (spazi, prefisso del paese) e controllata; per l'Italia 11 cifre con la
/// cifra di controllo giusta.
pub fn normalizza(nazione: &str, numero: &str) -> Result<(String, String), ErroreApi> {
    let nazione = nazione.trim().to_uppercase();
    if nazione.len() != 2 || !nazione.chars().all(|c| c.is_ascii_alphabetic()) {
        return Err(ErroreApi::Richiesta(format!("nazione {nazione} non valida")));
    }
    let mut numero: String = numero.chars().filter(|c| !c.is_whitespace() && *c != '.' && *c != '-').collect();
    numero = numero.to_uppercase();
    if let Some(senza) = numero.strip_prefix(&nazione) {
        numero = senza.to_owned();
    }
    if numero.is_empty() || numero.len() > 14 || !numero.chars().all(|c| c.is_ascii_alphanumeric()) {
        return Err(ErroreApi::Bozza(vec![format!("partita IVA {numero} non valida")]));
    }
    if nazione == "IT" && !cifra_di_controllo(&numero) {
        return Err(ErroreApi::Bozza(vec![format!("partita IVA {numero} non valida: la cifra di controllo non torna")]));
    }
    Ok((nazione, numero))
}

/// Cifra di controllo della partita IVA italiana (algoritmo di Luhn sulle prime 10 cifre).
fn cifra_di_controllo(numero: &str) -> bool {
    let cifre: Vec<u32> = numero.chars().filter_map(|c| c.to_digit(10)).collect();
    if cifre.len() != 11 || numero.len() != 11 {
        return false;
    }
    let somma: u32 = cifre
        .iter()
        .take(10)
        .enumerate()
        .map(|(i, &c)| {
            if i.is_multiple_of(2) {
                c
            } else {
                let doppio = c * 2;
                if doppio > 9 { doppio - 9 } else { doppio }
            }
        })
        .sum();
    cifre.get(10) == Some(&((10 - somma % 10) % 10))
}

/// Indirizzo italiano di VIES ("VIA S. ANTONIO 7 \n38017 MEZZOLOMBARDO TN\n") nei campi
/// dell'anagrafica; se non ha la forma attesa resta tutto in `indirizzo`.
fn dividi_indirizzo(testo: &str) -> (Option<String>, Option<String>, Option<String>, Option<String>) {
    let righe: Vec<&str> = testo.lines().map(str::trim).filter(|r| !r.is_empty()).collect();
    let Some((ultima, prima)) = righe.split_last() else { return (None, None, None, None) };
    let parole: Vec<&str> = ultima.split_whitespace().collect();
    let cap = parole.first().filter(|p| p.len() == 5 && p.chars().all(|c| c.is_ascii_digit()));
    let provincia = parole.last().filter(|p| parole.len() > 2 && p.len() == 2 && p.chars().all(|c| c.is_ascii_alphabetic()));
    match (cap, provincia) {
        (Some(cap), Some(provincia)) if !prima.is_empty() => (
            Some(prima.join(", ")),
            Some((*cap).to_owned()),
            parole.get(1..parole.len() - 1).map(|p| p.join(" ")),
            Some((*provincia).to_owned()),
        ),
        _ => (Some(righe.join(", ")), None, None, None),
    }
}

fn pulito(testo: Option<String>) -> Option<String> {
    testo.map(|t| t.trim().to_owned()).filter(|t| !t.is_empty() && t != "---")
}

/// Il cliente o fornitore di ATLAS con questa partita IVA, se c'è già.
pub fn gia_presente(conn: &Connection, partita_iva: &str) -> Result<Option<String>, ErroreApi> {
    Ok(conn
        .prepare_cached("SELECT codice FROM clienti_fornitori WHERE partita_iva = ?1 ORDER BY obsoleto, codice LIMIT 1")?
        .query_row([partita_iva], |r| r.get(0))
        .optional()?)
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct RispostaVies {
    #[serde(default)]
    valid: bool,
    #[serde(default)]
    name: Option<String>,
    #[serde(default)]
    address: Option<String>,
    /// Presente quando VIES non ha potuto rispondere ("MS_UNAVAILABLE", "TIMEOUT"…).
    #[serde(default)]
    user_error: Option<String>,
}

/// Il client del servizio VIES.
#[derive(Debug, Clone)]
pub struct Vies {
    client: reqwest::Client,
    url: String,
}

impl Vies {
    pub fn nuovo(url: impl Into<String>) -> Result<Self, ErroreApi> {
        let client = reqwest::Client::builder()
            .timeout(ATTESA)
            .build()
            .map_err(|e| ErroreApi::Interno(format!("client VIES: {e}")))?;
        Ok(Self { client, url: url.into() })
    }

    /// Dati dell'azienda da VIES; `gia_presente` lo completa chi ha il database.
    pub async fn cerca(&self, nazione: &str, partita_iva: &str) -> Result<DatiAzienda, ErroreApi> {
        let non_disponibile = |motivo: String| ErroreApi::NonDisponibile(format!("servizio VIES non raggiungibile ({motivo}): dati da scrivere a mano"));
        let risposta = self
            .client
            .post(&self.url)
            .json(&serde_json::json!({ "countryCode": nazione, "vatNumber": partita_iva }))
            .send()
            .await
            .map_err(|e| non_disponibile(if e.is_timeout() { "tempo scaduto".into() } else { "rete".into() }))?;
        if !risposta.status().is_success() {
            return Err(non_disponibile(format!("HTTP {}", risposta.status().as_u16())));
        }
        let vies: RispostaVies = risposta.json().await.map_err(|e| non_disponibile(format!("risposta non leggibile: {e}")))?;
        if let Some(errore) = vies.user_error.as_deref().filter(|e| *e != "VALID" && *e != "INVALID") {
            return Err(non_disponibile(errore.to_owned()));
        }
        let indirizzo_vies = pulito(vies.address);
        let (indirizzo, cap, localita, provincia) = indirizzo_vies.as_deref().map(dividi_indirizzo).unwrap_or_default();
        Ok(DatiAzienda {
            nazione: nazione.to_owned(),
            partita_iva: partita_iva.to_owned(),
            attiva: vies.valid,
            ragione_sociale: pulito(vies.name),
            indirizzo,
            cap,
            localita,
            provincia,
            indirizzo_vies,
            gia_presente: None,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cifra_di_controllo_italiana() {
        assert!(cifra_di_controllo("02273530226"), "Bottamedi Pierluigi");
        assert!(cifra_di_controllo("01484340227"));
        assert!(!cifra_di_controllo("02273530227"));
        assert!(!cifra_di_controllo("0227353022"));
        assert_eq!(normalizza("it", " IT 022 735 302 26 ").unwrap(), ("IT".into(), "02273530226".into()));
        assert!(matches!(normalizza("IT", "02273530227"), Err(ErroreApi::Bozza(_))));
        // Fuori dall'Italia la controlla VIES.
        assert_eq!(normalizza("DE", "DE123456789").unwrap(), ("DE".into(), "123456789".into()));
    }

    #[test]
    fn indirizzo_di_vies_nei_campi() {
        assert_eq!(
            dividi_indirizzo("VIA S. ANTONIO 7 \n38017 MEZZOLOMBARDO TN\n"),
            (Some("VIA S. ANTONIO 7".into()), Some("38017".into()), Some("MEZZOLOMBARDO".into()), Some("TN".into()))
        );
        assert_eq!(
            dividi_indirizzo("VIA ROMA 1\n38010 SAN MICHELE ALL'ADIGE TN"),
            (Some("VIA ROMA 1".into()), Some("38010".into()), Some("SAN MICHELE ALL'ADIGE".into()), Some("TN".into()))
        );
        assert_eq!(dividi_indirizzo("RUE X 4, PARIS"), (Some("RUE X 4, PARIS".into()), None, None, None));
    }
}
