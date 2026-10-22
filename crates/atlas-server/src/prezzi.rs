//! Lookup prezzi del tasto `F3` sul prezzo: la maschera "PREZZO/COSTO ARTICOLO" di Arca
//! (`fastsrcform_arprezzo`), in tre sezioni.
//!
//! 1. Dati da documento: articolo, cliente, unità, fattore, quantità, aliquota.
//! 2. Prezzi da listino: ogni listino di prezzi (`LS.TipoLS = 1`) con la revisione valida alla
//!    data del documento.
//! 3. Ultimi prezzi da documenti: ultima bolla di vendita al cliente, ultima a chiunque, prezzo
//!    più alto del giorno. L'ultimo acquisto non c'è: ATLAS non ha documenti di acquisto (in Arca
//!    le BF sono ferme al 2019).
//!
//! Ogni voce porta `prezzo_riga`, il prezzo da riportare nella riga (`Invio` o `Riporta`), già
//! nell'unità della riga e senza IVA. Le letture usano gli indici `ddt_righe (articolo, data)` e
//! `(articolo, cliente, data)` (migrazione 4): nessuna scorre i documenti.

use atlas_core::aliquota::CodiceAliquota;
use atlas_core::importo::{DECIMALI_PREZZO, arrotonda};
use chrono::NaiveDate;
use rusqlite::{Connection, OptionalExtension, params};
use rust_decimal::Decimal;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use crate::errore::ErroreApi;

/// Riga di listino valida per un articolo a una data.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PrezzoListino {
    /// `LSArticolo.Id_LSArticolo`, registrato nella riga del documento.
    pub id: i64,
    pub prezzo: Decimal,
    pub sconto: Option<String>,
    pub ivato: bool,
}

impl PrezzoListino {
    /// Prezzo senza IVA nell'unità della riga (`fattore` verso l'unità principale, a cui si
    /// riferisce il listino). Da un listino ivato si scorpora l'IVA, sui decimali del prezzo.
    pub fn prezzo_riga(&self, percentuale: Decimal, fattore: Decimal) -> Decimal {
        let netto = if self.ivato {
            arrotonda(self.prezzo / (Decimal::ONE + percentuale / Decimal::ONE_HUNDRED), DECIMALI_PREZZO)
        } else {
            self.prezzo
        };
        netto * fattore
    }
}

fn decimale(testo: &str) -> rusqlite::Result<Decimal> {
    testo
        .parse()
        .map_err(|e| rusqlite::Error::FromSqlConversionFailure(0, rusqlite::types::Type::Text, Box::new(e)))
}

/// Il prezzo del listino per l'articolo: la revisione più recente valida alla data (senza data
/// di validità vale da sempre) che lo contiene.
pub fn prezzo_listino(conn: &Connection, listino: &str, articolo: &str, data: NaiveDate) -> Result<Option<PrezzoListino>, ErroreApi> {
    Ok(conn
        .prepare_cached(
            "SELECT p.id, p.prezzo, p.sconto, l.ivato FROM listini_prezzi p \
             JOIN listini_revisioni r ON r.id = p.revisione JOIN listini l ON l.codice = r.listino \
             WHERE r.listino = ?1 AND p.articolo = ?2 AND (r.valido_dal IS NULL OR r.valido_dal <= ?3) \
             ORDER BY r.valido_dal DESC, r.id DESC LIMIT 1",
        )?
        .query_row(params![listino, articolo, data], |r| {
            Ok(PrezzoListino {
                id: r.get(0)?,
                prezzo: decimale(&r.get::<_, String>(1)?)?,
                sconto: r.get::<_, Option<String>>(2)?.filter(|s| !s.trim().is_empty()),
                ivato: r.get(3)?,
            })
        })
        .optional()?)
}

/// Richiesta della maschera prezzi.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct RichiestaPrezzi {
    /// Codice articolo.
    pub articolo: String,
    /// Codice cliente del documento: dà il suo listino e il suo ultimo prezzo.
    #[serde(default)]
    pub cliente: Option<String>,
    /// Data del documento. Assente: oggi.
    #[serde(default)]
    pub data: Option<NaiveDate>,
    /// Unità della riga. Assente: l'unità principale dell'articolo.
    #[serde(default)]
    pub unita_misura: Option<String>,
    /// Quantità della riga, solo per la sezione dati da documento.
    #[serde(default)]
    pub quantita: Option<Decimal>,
    /// DDT in modifica (id ATLAS): escluso dagli ultimi prezzi.
    #[serde(default)]
    pub escludi_ddt: Option<i64>,
}

/// Sezione "Dati da documento".
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct DatiDocumento {
    pub articolo: String,
    pub descrizione: String,
    pub cliente: Option<String>,
    pub ragione_sociale: Option<String>,
    pub listino_cliente: Option<String>,
    pub data: NaiveDate,
    pub valuta: &'static str,
    pub unita_misura: String,
    pub fattore: Decimal,
    pub quantita: Option<Decimal>,
    pub aliquota: Option<String>,
    pub percentuale_iva: Option<Decimal>,
}

/// Una riga di listino della sezione "Prezzi da listino".
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct VoceListino {
    pub listino: String,
    pub descrizione: String,
    /// Listino dei prezzi proposti in riga: quello del cliente o, se non ne ha, il predefinito.
    pub proposto: bool,
    pub ivato: bool,
    pub revisione: i64,
    pub valido_dal: Option<NaiveDate>,
    pub id_listino_articolo: i64,
    /// Prezzo come registrato nel listino (unità principale).
    pub prezzo_listino: Decimal,
    pub prezzo_ivato: Option<Decimal>,
    pub sconto: Option<String>,
    /// Prezzo da riportare nella riga: senza IVA, nell'unità della riga.
    pub prezzo_riga: Decimal,
}

/// Le voci della sezione "Ultimi prezzi da documenti".
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum TipoUltimo {
    /// Ultima bolla di vendita a questo cliente.
    UltimoCliente,
    /// Ultima bolla di vendita a chiunque.
    UltimoAssoluto,
    /// Prezzo più alto delle bolle di vendita del giorno del documento.
    MassimoGiorno,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct RiferimentoDocumento {
    pub id: i64,
    pub tipo: &'static str,
    pub numero: u32,
    pub data: NaiveDate,
    pub cliente: String,
    pub ragione_sociale: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct VoceUltimo {
    pub tipo: TipoUltimo,
    /// Come la riga della maschera di Arca: `Prz. ultimo doc. BOLLA VENDITA di …`.
    pub descrizione: String,
    pub documento: RiferimentoDocumento,
    pub riga: u32,
    pub unita_misura: String,
    pub fattore: Decimal,
    pub quantita: Decimal,
    pub aliquota: String,
    /// Prezzo unitario della riga del documento.
    pub prezzo: Decimal,
    pub prezzo_ivato: Option<Decimal>,
    pub sconto: String,
    /// Prezzo da riportare nella riga: convertito nell'unità della riga.
    pub prezzo_riga: Decimal,
}

/// La maschera "PREZZO/COSTO ARTICOLO".
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Prezzi {
    pub documento: DatiDocumento,
    pub listini: Vec<VoceListino>,
    pub ultimi: Vec<VoceUltimo>,
    /// Sempre assente finché ATLAS non ha documenti di acquisto.
    pub ultimo_acquisto: Option<VoceUltimo>,
}

fn ivato(prezzo: Decimal, percentuale: Option<Decimal>) -> Option<Decimal> {
    percentuale.map(|p| arrotonda(prezzo * (Decimal::ONE + p / Decimal::ONE_HUNDRED), DECIMALI_PREZZO))
}

/// Le tre sezioni della maschera prezzi per un articolo.
/// `listino_predefinito` è il listino dei prezzi proposti per i clienti che non ne hanno uno.
pub fn prezzi(
    conn: &Connection,
    richiesta: &RichiestaPrezzi,
    oggi: NaiveDate,
    listino_predefinito: &str,
) -> Result<Prezzi, ErroreApi> {
    let codice = richiesta.articolo.trim();
    let (articolo, descrizione, unita_principale, aliquota_articolo): (String, String, String, Option<String>) = conn
        .prepare_cached("SELECT codice, descrizione, unita_misura, aliquota_vendita FROM articoli WHERE codice = ?1")?
        .query_row([codice], |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?)))
        .optional()?
        .ok_or_else(|| ErroreApi::NonTrovato(format!("articolo {codice}")))?;
    let data = richiesta.data.unwrap_or(oggi);

    let cliente: Option<(String, String, Option<String>)> = match richiesta.cliente.as_deref().map(str::trim) {
        Some(c) if !c.is_empty() => Some(
            conn.prepare_cached("SELECT codice, ragione_sociale, listino FROM clienti_fornitori WHERE codice = ?1")?
                .query_row([c], |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)))
                .optional()?
                .ok_or_else(|| ErroreApi::NonTrovato(format!("cliente {c}")))?,
        ),
        _ => None,
    };

    let aliquota = match aliquota_articolo {
        Some(a) => Some(a),
        None => atlas_db::anagrafiche::predefiniti_righe(conn)?.map(|p| p.aliquota),
    };
    let tabella = atlas_db::anagrafiche::tabella_aliquote(conn)?;
    let percentuale = aliquota.as_deref().and_then(|a| tabella.percentuale(&CodiceAliquota::nuovo(a)).ok());

    let (unita_misura, fattore): (String, Decimal) = match richiesta.unita_misura.as_deref().map(str::trim) {
        Some(um) if !um.is_empty() && !um.eq_ignore_ascii_case(&unita_principale) => {
            let trovata: Option<(String, String)> = conn
                .prepare_cached("SELECT unita_misura, fattore FROM articoli_unita WHERE articolo = ?1 AND unita_misura = ?2")?
                .query_row([articolo.as_str(), um], |r| Ok((r.get(0)?, r.get(1)?)))
                .optional()?;
            let (um, fattore) =
                trovata.ok_or_else(|| ErroreApi::Richiesta(format!("unità {um} non prevista per l'articolo {articolo}")))?;
            (um, fattore.parse().map_err(|_| ErroreApi::Interno(format!("fattore {fattore} non numerico")))?)
        }
        _ => (unita_principale, Decimal::ONE),
    };

    let listino_cliente = cliente.as_ref().and_then(|c| c.2.clone());
    let proposto = listino_cliente.as_deref().unwrap_or(listino_predefinito);
    let listini = listini(conn, &articolo, data, proposto, percentuale, fattore)?;
    let mut ultimi = Vec::with_capacity(3);
    let escludi = richiesta.escludi_ddt.unwrap_or(-1);
    let converti = |voce: &mut VoceUltimo| {
        // Prezzo dell'unità principale, poi nell'unità della riga.
        if !voce.fattore.is_zero() {
            voce.prezzo_riga = arrotonda(voce.prezzo / voce.fattore * fattore, DECIMALI_PREZZO.max(voce.prezzo.scale()));
        }
        voce.prezzo_ivato = ivato(voce.prezzo, percentuale_di(&tabella, &voce.aliquota));
    };
    if let Some((codice_cliente, ragione_sociale, _)) = &cliente {
        if let Some(mut voce) = ultimo(conn, Ricerca::Cliente(codice_cliente), &articolo, escludi)? {
            voce.descrizione = format!("Prz. ultimo doc. BOLLA VENDITA di {}", ragione_sociale.trim_end());
            converti(&mut voce);
            ultimi.push(voce);
        }
    }
    if let Some(mut voce) = ultimo(conn, Ricerca::Tutti, &articolo, escludi)? {
        voce.descrizione = format!(
            "Prz. ultimo doc. BOLLA VENDITA (BO {} / {} del {})",
            voce.documento.numero,
            voce.documento.ragione_sociale,
            voce.documento.data.format("%d-%m-%Y")
        );
        converti(&mut voce);
        ultimi.push(voce);
    }
    if let Some(mut voce) = ultimo(conn, Ricerca::MassimoDelGiorno(data), &articolo, escludi)? {
        voce.descrizione = format!(
            "Prz. massimo BOLLA VENDITA del {} (BO {} / {})",
            data.format("%d-%m-%Y"),
            voce.documento.numero,
            voce.documento.ragione_sociale
        );
        converti(&mut voce);
        ultimi.push(voce);
    }

    Ok(Prezzi {
        documento: DatiDocumento {
            articolo,
            descrizione,
            cliente: cliente.as_ref().map(|c| c.0.clone()),
            ragione_sociale: cliente.map(|c| c.1.trim_end().to_owned()),
            listino_cliente,
            data,
            valuta: "EUR",
            unita_misura,
            fattore,
            quantita: richiesta.quantita,
            aliquota,
            percentuale_iva: percentuale,
        },
        listini,
        ultimi,
        ultimo_acquisto: None,
    })
}

fn percentuale_di(tabella: &atlas_core::aliquota::TabellaAliquote, aliquota: &str) -> Option<Decimal> {
    tabella.percentuale(&CodiceAliquota::nuovo(aliquota)).ok()
}

fn listini(
    conn: &Connection,
    articolo: &str,
    data: NaiveDate,
    proposto: &str,
    percentuale: Option<Decimal>,
    fattore: Decimal,
) -> Result<Vec<VoceListino>, ErroreApi> {
    let mut stmt = conn.prepare_cached(
        "SELECT l.codice, l.descrizione, l.ivato, r.id, r.valido_dal, p.id, p.prezzo, p.sconto FROM listini_prezzi p \
         JOIN listini_revisioni r ON r.id = p.revisione JOIN listini l ON l.codice = r.listino \
         WHERE p.articolo = ?1 AND l.tipo = 1 AND (r.valido_dal IS NULL OR r.valido_dal <= ?2) \
         ORDER BY l.codice, r.valido_dal DESC, r.id DESC",
    )?;
    let mut righe = stmt.query(params![articolo, data])?;
    let mut voci: Vec<VoceListino> = Vec::new();
    while let Some(r) = righe.next()? {
        let codice: String = r.get(0)?;
        if voci.last().is_some_and(|v| v.listino == codice) {
            continue; // revisione meno recente dello stesso listino
        }
        let listino = PrezzoListino {
            id: r.get(5)?,
            prezzo: decimale(&r.get::<_, String>(6)?)?,
            sconto: r.get::<_, Option<String>>(7)?.filter(|s| !s.trim().is_empty()),
            ivato: r.get(2)?,
        };
        voci.push(VoceListino {
            proposto: proposto.eq_ignore_ascii_case(&codice),
            listino: codice,
            descrizione: r.get::<_, String>(1)?.trim_end().to_owned(),
            ivato: listino.ivato,
            revisione: r.get(3)?,
            valido_dal: r.get(4)?,
            id_listino_articolo: listino.id,
            prezzo_listino: listino.prezzo,
            prezzo_ivato: if listino.ivato { Some(listino.prezzo) } else { ivato(listino.prezzo, percentuale) },
            sconto: listino.sconto.clone(),
            prezzo_riga: listino.prezzo_riga(percentuale.unwrap_or_default(), fattore),
        });
    }
    Ok(voci)
}

enum Ricerca<'a> {
    Cliente(&'a str),
    Tutti,
    MassimoDelGiorno(NaiveDate),
}

const COLONNE_ULTIMO: &str = "d.id, d.numero, d.data, d.cliente, c.ragione_sociale, r.riga, r.unita_misura, \
    r.fattore_um1, r.quantita, r.aliquota, r.prezzo_unitario, r.sconto_riga";

fn ultimo(conn: &Connection, ricerca: Ricerca<'_>, articolo: &str, escludi: i64) -> Result<Option<VoceUltimo>, ErroreApi> {
    let (sql, filtro): (String, Box<dyn rusqlite::ToSql>) = match ricerca {
        Ricerca::Cliente(cliente) => (
            format!(
                "SELECT {COLONNE_ULTIMO} FROM ddt_righe r JOIN ddt d ON d.id = r.ddt \
                 JOIN clienti_fornitori c ON c.codice = d.cliente \
                 WHERE r.articolo = ?1 AND r.cliente = ?2 AND r.ddt <> ?3 \
                 ORDER BY r.data DESC, d.numero DESC, r.riga DESC LIMIT 1"
            ),
            Box::new(cliente.to_owned()),
        ),
        Ricerca::Tutti => (
            format!(
                "SELECT {COLONNE_ULTIMO} FROM ddt_righe r JOIN ddt d ON d.id = r.ddt \
                 JOIN clienti_fornitori c ON c.codice = d.cliente \
                 WHERE r.articolo = ?1 AND ?2 IS NULL AND r.ddt <> ?3 \
                 ORDER BY r.data DESC, d.numero DESC, r.riga DESC LIMIT 1"
            ),
            Box::new(Option::<String>::None),
        ),
        // Il confronto sui prezzi è numerico, nell'unità principale; il valore restituito è il
        // testo esatto della riga.
        Ricerca::MassimoDelGiorno(data) => (
            format!(
                "SELECT {COLONNE_ULTIMO} FROM ddt_righe r JOIN ddt d ON d.id = r.ddt \
                 JOIN clienti_fornitori c ON c.codice = d.cliente \
                 WHERE r.articolo = ?1 AND r.data = ?2 AND r.ddt <> ?3 \
                 ORDER BY CAST(r.prezzo_unitario AS REAL) / nullif(CAST(r.fattore_um1 AS REAL), 0) DESC, \
                 d.numero DESC, r.riga DESC LIMIT 1"
            ),
            Box::new(data),
        ),
    };
    Ok(conn
        .prepare_cached(&sql)?
        .query_row(params![articolo, filtro, escludi], |r| {
            let prezzo = decimale(&r.get::<_, String>(10)?)?;
            Ok(VoceUltimo {
                tipo: TipoUltimo::UltimoCliente,
                descrizione: String::new(),
                documento: RiferimentoDocumento {
                    id: r.get(0)?,
                    tipo: atlas_db::ddt::TIPO_DOCUMENTO,
                    numero: r.get(1)?,
                    data: r.get(2)?,
                    cliente: r.get(3)?,
                    // Arca riempie i `char`: in maschera senza gli spazi finali.
                    ragione_sociale: r.get::<_, String>(4)?.trim_end().to_owned(),
                },
                riga: r.get(5)?,
                unita_misura: r.get(6)?,
                fattore: decimale(&r.get::<_, String>(7)?)?,
                quantita: decimale(&r.get::<_, String>(8)?)?,
                aliquota: r.get(9)?,
                prezzo,
                prezzo_ivato: None,
                sconto: r.get(11)?,
                prezzo_riga: prezzo,
            })
        })
        .optional()?
        .map(|mut voce| {
            voce.tipo = match ricerca {
                Ricerca::Cliente(_) => TipoUltimo::UltimoCliente,
                Ricerca::Tutti => TipoUltimo::UltimoAssoluto,
                Ricerca::MassimoDelGiorno(_) => TipoUltimo::MassimoGiorno,
            };
            voce
        }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use atlas_db::anagrafiche::{Listino, PrezzoListino as Riga, RevisioneListino, aggiorna};
    use atlas_db::ddt::salva;
    use atlas_db::prova::{adesso, anagrafiche, database, ddt};
    use rust_decimal_macros::dec;

    fn giorno(g: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(2026, 10, g).unwrap()
    }

    fn con_data(numero: u32, data: NaiveDate, cliente: &str, prezzo: Decimal) -> atlas_core::ddt::Ddt {
        let mut d = ddt(numero);
        d.data = data;
        d.cliente = cliente.into();
        if cliente != "C000380" {
            d.destinazione = None;
        }
        d.righe[0].prezzo_unitario = prezzo;
        d
    }

    fn richiesta(cliente: Option<&str>) -> RichiestaPrezzi {
        RichiestaPrezzi {
            articolo: "ban".into(),
            cliente: cliente.map(Into::into),
            data: Some(giorno(22)),
            ..RichiestaPrezzi::default()
        }
    }

    #[test]
    fn listini_alla_data_con_la_revisione_valida() {
        let mut conn = database();
        let mut dati = anagrafiche();
        dati.listini.push(Listino {
            codice: "0000002".into(),
            descrizione: "Listino 2 ivato".into(),
            ivato: true,
            tipo: 1,
        });
        for (id, listino, dal) in [(2, "0000001", Some(giorno(20))), (3, "0000001", Some(giorno(25))), (4, "0000002", None)] {
            dati.revisioni_listino.push(RevisioneListino {
                id,
                listino: listino.into(),
                descrizione: format!("revisione {id}"),
                valido_dal: dal,
                pubblicata_il: None,
            });
        }
        for (id, revisione, prezzo) in [(334, 2, dec!(1.90)), (335, 3, dec!(2.50)), (336, 4, dec!(2.08))] {
            dati.prezzi_listino.push(Riga {
                id,
                revisione,
                articolo: "BAN".into(),
                prezzo,
                sconto: None,
            });
        }
        aggiorna(&mut conn, &dati).unwrap();

        let prezzi = prezzi(&conn, &richiesta(Some("C000380")), giorno(22), "0000002").unwrap();
        let voci: Vec<(&str, i64, Decimal, Decimal, bool)> = prezzi
            .listini
            .iter()
            .map(|v| (v.listino.as_str(), v.id_listino_articolo, v.prezzo_listino, v.prezzo_riga, v.proposto))
            .collect();
        // Listino 1: la revisione del 20/10, non quella del 25/10 non ancora valida; listino 2
        // ivato: 2,08 / 1,04 = 2,00.
        assert_eq!(voci, [("0000001", 334, dec!(1.90), dec!(1.90), true), ("0000002", 336, dec!(2.08), dec!(2.000), false)]);
        assert_eq!(prezzi.listini[0].prezzo_ivato, Some(dec!(1.976)));
        let dal_listino = prezzo_listino(&conn, "0000001", "BAN", giorno(26)).unwrap().unwrap();
        assert_eq!(dal_listino.prezzo, dec!(2.50));
    }

    #[test]
    fn ultimo_al_cliente_ultimo_assoluto_e_massimo_del_giorno() {
        let mut conn = database();
        salva(&mut conn, &con_data(10, giorno(20), "C000380", dec!(1.70)), adesso()).unwrap();
        salva(&mut conn, &con_data(11, giorno(21), "C000002", dec!(1.95)), adesso()).unwrap();
        salva(&mut conn, &con_data(12, giorno(22), "C000002", dec!(2.10)), adesso()).unwrap();
        let in_modifica = salva(&mut conn, &con_data(13, giorno(22), "C000002", dec!(9.99)), adesso()).unwrap();
        let mut r = richiesta(Some("C000380"));
        r.escludi_ddt = Some(in_modifica.id);
        let prezzi = prezzi(&conn, &r, giorno(22), "0000001").unwrap();
        let ultimi: Vec<(TipoUltimo, u32, Decimal)> =
            prezzi.ultimi.iter().map(|u| (u.tipo, u.documento.numero, u.prezzo_riga)).collect();
        assert_eq!(
            ultimi,
            [
                (TipoUltimo::UltimoCliente, 10, dec!(1.70)),
                (TipoUltimo::UltimoAssoluto, 12, dec!(2.10)),
                (TipoUltimo::MassimoGiorno, 12, dec!(2.10)),
            ]
        );
        assert_eq!(prezzi.ultimi[1].descrizione, "Prz. ultimo doc. BOLLA VENDITA (BO 12 / Cliente C000002 del 22-10-2026)");
        assert_eq!(prezzi.ultimi[0].prezzo_ivato, Some(dec!(1.768)));
        assert_eq!(prezzi.documento.listino_cliente.as_deref(), Some("0000001"));
        assert!(prezzi.ultimo_acquisto.is_none());

        // Senza cliente: nessun ultimo al cliente. Il massimo confronta i numeri, non i testi.
        salva(&mut conn, &con_data(14, giorno(22), "C000002", dec!(10.5)), adesso()).unwrap();
        let prezzi = super::prezzi(&conn, &richiesta(None), giorno(22), "0000001").unwrap();
        assert_eq!(prezzi.ultimi.iter().map(|u| u.tipo).collect::<Vec<_>>(), [TipoUltimo::UltimoAssoluto, TipoUltimo::MassimoGiorno]);
        assert_eq!(prezzi.ultimi[1].prezzo, dec!(10.5));
    }

    #[test]
    fn articolo_o_unita_inesistenti() {
        let conn = database();
        let mut r = richiesta(None);
        r.articolo = "NONESISTE".into();
        assert!(matches!(prezzi(&conn, &r, giorno(22), "0000001"), Err(ErroreApi::NonTrovato(_))));
        let mut r = richiesta(None);
        r.unita_misura = Some("PZ".into());
        assert!(matches!(prezzi(&conn, &r, giorno(22), "0000001"), Err(ErroreApi::Richiesta(_))));
    }
}
