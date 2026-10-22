//! Le funzioni del backend come strumenti tipizzati per assistenti e workflow automatici: nome,
//! descrizione e JSON Schema dei parametri (`input_schema`, il formato degli strumenti di Claude;
//! gli altri modelli accettano lo stesso schema). [`invoca`] le esegue: è anche il dispatcher dei
//! messaggi WebSocket.

use schemars::{JsonSchema, Schema, schema_for};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::bozza::Bozza;
use crate::consultazione::{FiltroDdt, Ricerca};
use crate::errore::ErroreApi;
use crate::prezzi::RichiestaPrezzi;
use crate::servizio::Servizio;

#[derive(Debug, Clone, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct Codice {
    /// Codice in anagrafica, senza distinzione fra maiuscole e minuscole.
    pub codice: String,
}

#[derive(Debug, Clone, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct IdDdt {
    /// Identificativo del DDT nel database ATLAS (non il numero).
    pub id: i64,
}

#[derive(Debug, Clone, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct Esercizio {
    /// Anno dell'esercizio.
    pub esercizio: i32,
}

#[derive(Debug, Clone, Default, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct Nessuno {}

/// Descrizione di uno strumento.
#[derive(Debug, Clone, Serialize)]
pub struct Strumento {
    pub name: &'static str,
    pub description: &'static str,
    pub input_schema: Schema,
    /// Lo strumento scrive nel database (e, con la replica, in Arca): un assistente deve chiedere
    /// conferma prima di usarlo.
    pub scrittura: bool,
}

fn strumento<T: JsonSchema>(name: &'static str, description: &'static str, scrittura: bool) -> Strumento {
    let mut input_schema = schema_for!(T);
    // Il titolo è il nome del tipo Rust, inutile per chi chiama.
    input_schema.remove("title");
    input_schema.remove("$schema");
    Strumento {
        name,
        description,
        input_schema,
        scrittura,
    }
}

pub fn elenco() -> Vec<Strumento> {
    vec![
        strumento::<Ricerca>("cerca_clienti", "Cerca i clienti per codice o ragione sociale.", false),
        strumento::<Codice>("scheda_cliente", "Scheda di un cliente con pagamento, listino e destinazioni.", false),
        strumento::<Ricerca>("cerca_articoli", "Cerca gli articoli per codice o descrizione.", false),
        strumento::<Codice>("scheda_articolo", "Scheda di un articolo con le unità di misura.", false),
        strumento::<Nessuno>(
            "tabelle",
            "Codifiche: aliquote IVA, pagamenti, unità di misura, magazzini, agenti, listini.",
            false,
        ),
        strumento::<FiltroDdt>(
            "elenco_ddt",
            "DDT di vendita dai più recenti, filtrati per periodo, cliente o numero, con lo stato in Arca.",
            false,
        ),
        strumento::<IdDdt>("scheda_ddt", "Un DDT completo: righe, quantità, totali, castelletto IVA, replica in Arca.", false),
        strumento::<RichiestaPrezzi>(
            "prezzi_articolo",
            "Maschera prezzi (F3): prezzi di listino, ultimo prezzo al cliente, ultimo prezzo a chiunque, prezzo \
             massimo del giorno. Ogni voce ha prezzo_riga, il prezzo da usare nella riga del DDT.",
            false,
        ),
        strumento::<Bozza>(
            "calcola_ddt",
            "Completa e calcola un DDT senza salvarlo: quantità nette dalla pesata (lordo − colli × tara), prezzi \
             proposti, totali e castelletto IVA, avvisi ed errori per riga.",
            false,
        ),
        strumento::<Bozza>(
            "crea_ddt",
            "Salva un nuovo DDT di vendita con il numero della numerazione unica con Arca e lo mette in coda per \
             la replica in Arca. Usare prima calcola_ddt e chiedere conferma.",
            true,
        ),
        strumento::<IdDdt>(
            "rinumera_ddt",
            "Dà il prossimo numero a un DDT ATLAS non ancora in Arca il cui numero, in Arca, è di un altro \
             documento (conflitto di replica o di importazione).",
            true,
        ),
        strumento::<Esercizio>(
            "numeri_liberi",
            "Buchi della numerazione dei DDT in un esercizio, con le date ammesse, e il prossimo numero.",
            false,
        ),
        strumento::<Nessuno>(
            "stato_sincronizzazione",
            "Stato della sincronizzazione con Arca: coda di replica, importazione, conflitti da risolvere.",
            false,
        ),
        strumento::<Nessuno>("sincronizza", "Avvia subito un giro di replica e uno di importazione.", false),
    ]
}

fn parametri<T: DeserializeOwned>(valore: Value) -> Result<T, ErroreApi> {
    let valore = match valore {
        Value::Null => Value::Object(serde_json::Map::new()),
        v => v,
    };
    serde_json::from_value(valore).map_err(|e| ErroreApi::Richiesta(e.to_string()))
}

fn json<T: Serialize>(valore: T) -> Result<Value, ErroreApi> {
    serde_json::to_value(valore).map_err(|e| ErroreApi::Interno(e.to_string()))
}

/// Esegue lo strumento `nome` con i parametri JSON.
pub async fn invoca(servizio: &Servizio, nome: &str, p: Value) -> Result<Value, ErroreApi> {
    match nome {
        "cerca_clienti" => json(servizio.cerca_clienti(parametri(p)?).await?),
        "scheda_cliente" => json(servizio.cliente(parametri::<Codice>(p)?.codice).await?),
        "cerca_articoli" => json(servizio.cerca_articoli(parametri(p)?).await?),
        "scheda_articolo" => json(servizio.articolo(parametri::<Codice>(p)?.codice).await?),
        "tabelle" => {
            parametri::<Nessuno>(p)?;
            json(servizio.tabelle().await?)
        }
        "elenco_ddt" => json(servizio.elenco_ddt(parametri(p)?).await?),
        "scheda_ddt" => json(servizio.ddt(parametri::<IdDdt>(p)?.id).await?),
        "prezzi_articolo" => json(servizio.prezzi(parametri(p)?).await?),
        "calcola_ddt" => json(servizio.calcola(parametri(p)?).await?),
        "crea_ddt" => json(servizio.crea_ddt(parametri(p)?).await?),
        "rinumera_ddt" => json(servizio.rinumera(parametri::<IdDdt>(p)?.id).await?),
        "numeri_liberi" => json(servizio.liberi(parametri::<Esercizio>(p)?.esercizio).await?),
        "stato_sincronizzazione" => {
            parametri::<Nessuno>(p)?;
            json(servizio.stato().await?)
        }
        "sincronizza" => {
            parametri::<Nessuno>(p)?;
            json(servizio.sincronizza().await?)
        }
        _ => Err(ErroreApi::NonTrovato(format!("strumento {nome}"))),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ogni_strumento_ha_uno_schema_a_oggetto() {
        let strumenti = elenco();
        assert_eq!(strumenti.len(), 14);
        for s in &strumenti {
            let schema = serde_json::to_value(&s.input_schema).unwrap();
            assert_eq!(schema["type"], "object", "{}", s.name);
            assert!(s.name.chars().all(|c| c.is_ascii_lowercase() || c == '_'));
        }
        let bozza = strumenti.iter().find(|s| s.name == "crea_ddt").unwrap();
        let schema = serde_json::to_value(&bozza.input_schema).unwrap();
        assert_eq!(schema["required"], serde_json::json!(["cliente"]));
        assert!(schema.to_string().contains("lordo"));
    }
}
