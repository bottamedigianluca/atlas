//! Bozza di DDT: ciò che l'operatore batte. Il backend la completa con le anagrafiche (testata
//! dal cliente, righe dall'articolo, prezzo dal listino del cliente), la calcola con `atlas-core`
//! e la trasforma nel [`Ddt`] da salvare.
//!
//! [`calcola`] non fallisce per una riga incompleta: restituisce per ogni riga quantità, totale,
//! avvisi ed errori, e il castelletto delle righe valide. È la totalizzazione in tempo reale della
//! maschera. [`Calcolo::in_ddt`] dà il documento solo se non c'è nessun errore.
//!
//! Regole delle anagrafiche (misurate su 11.885 BO 2025-2026, `docs/ANALISI_ARCA.md`):
//! pagamento, listino, IBAN, BIC, conto banca, agente e scissione dei pagamenti dal cliente;
//! aliquota e conto dall'articolo, altrimenti i predefiniti delle righe. Il prezzo proposto viene
//! dal listino del cliente o, se non ne ha, da quello predefinito ([`Predefiniti::listino`]).

use atlas_core::aliquota::{CodiceAliquota, TabellaAliquote};
use atlas_core::ddt::{Ddt, RigaDdt};
use atlas_core::importo::Limitato;
use atlas_core::iva::Castelletto;
use atlas_core::riga::{Pesata, RigaMerce, Sconto};
use chrono::{Datelike, NaiveDate, NaiveDateTime, Timelike};
use rusqlite::{Connection, OptionalExtension};
use rust_decimal::Decimal;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use crate::config::Predefiniti;
use crate::errore::ErroreApi;
use crate::prezzi::{self, PrezzoListino};

/// Testata e righe come le batte l'operatore.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct Bozza {
    /// Codice del cliente (`CF.Cd_CF`), per esempio `C000380`.
    pub cliente: String,
    /// Codice della destinazione del cliente. Assente: la destinazione predefinita del cliente;
    /// stringa vuota: nessuna destinazione.
    #[serde(default)]
    pub destinazione: Option<String>,
    /// Data del documento (AAAA-MM-GG). Assente: oggi. Inizio trasporto alla stessa data.
    #[serde(default)]
    pub data: Option<NaiveDate>,
    /// Numero scelto a mano, fra i liberi (`numeri_liberi`). Assente: il prossimo della
    /// numerazione unica con Arca.
    #[serde(default)]
    pub numero: Option<u32>,
    #[serde(default)]
    pub righe: Vec<BozzaRiga>,
}

/// Riga merce. La quantità è il netto della pesata: `lordo − colli × tara`; senza lordo, i colli.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct BozzaRiga {
    /// Codice articolo. Una riga senza articolo è una riga vuota e non entra nel documento.
    #[serde(default)]
    pub articolo: String,
    /// Unità di misura. Assente: la predefinita dell'articolo.
    #[serde(default)]
    pub unita_misura: Option<String>,
    #[serde(default)]
    pub colli: Decimal,
    /// Peso lordo.
    #[serde(default)]
    pub lordo: Decimal,
    /// Tara per collo.
    #[serde(default)]
    pub tara: Decimal,
    /// Prezzo unitario. Assente: il prezzo del listino del cliente (o del listino predefinito, se
    /// il cliente non ne ha) alla data del documento.
    #[serde(default)]
    pub prezzo: Option<Decimal>,
    /// Sconto di riga nella notazione di Arca (`10`, `10+5`). Assente: quello del listino se il
    /// prezzo viene dal listino.
    #[serde(default)]
    pub sconto: Option<String>,
    #[serde(default)]
    pub sconto_addizionale: Option<String>,
    /// Quantità battuta a mano al posto del netto della pesata.
    #[serde(default)]
    pub quantita: Option<Decimal>,
    /// Descrizione al posto di quella dell'articolo (per esempio con il lotto).
    #[serde(default)]
    pub descrizione: Option<String>,
    /// Magazzino di scarico. Assente: il magazzino predefinito (`00001`).
    #[serde(default)]
    pub magazzino: Option<String>,
}

/// Avviso non bloccante della maschera (guardrail da tastiera: `Esc` corregge, `Invio` conferma).
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Avviso {
    pub codice: &'static str,
    pub messaggio: String,
}

/// Da dove viene il prezzo della riga.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum OriginePrezzo {
    Listino,
    Manuale,
}

/// Una riga della bozza completata e calcolata.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct RigaCalcolata {
    /// Riga senza articolo: non entra nel documento.
    pub vuota: bool,
    pub articolo: String,
    pub descrizione: Option<String>,
    pub unita_misura: Option<String>,
    pub fattore_um1: Option<Decimal>,
    pub aliquota: Option<String>,
    pub quantita: Option<Decimal>,
    pub prezzo: Option<Decimal>,
    pub origine_prezzo: Option<OriginePrezzo>,
    /// Prezzo di listino nell'unità della riga.
    pub prezzo_listino: Option<Decimal>,
    /// Prezzo battuto diverso da quello di listino: la cella si colora (ambra chiaro).
    pub prezzo_modificato: bool,
    pub totale: Option<Decimal>,
    pub avvisi: Vec<Avviso>,
    pub errori: Vec<String>,
}

/// Testata completata dalle anagrafiche.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct TestataCalcolata {
    pub cliente: String,
    pub ragione_sociale: String,
    pub destinazione: Option<String>,
    pub data: NaiveDate,
    pub esercizio: i32,
    pub numero: Option<u32>,
    pub pagamento: Option<String>,
    pub listino: Option<String>,
    /// Listino dei prezzi proposti: quello del cliente o il predefinito.
    pub listino_prezzi: String,
    pub scissione_pagamenti: bool,
    pub inizio_trasporto: NaiveDateTime,
}

/// Bozza calcolata: la risposta della totalizzazione in tempo reale.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Calcolo {
    pub testata: Option<TestataCalcolata>,
    pub righe: Vec<RigaCalcolata>,
    /// Castelletto IVA e totali delle righe senza errori.
    pub castelletto: Castelletto,
    pub netto_a_pagare: Decimal,
    /// Errori della testata.
    pub errori: Vec<String>,
    /// Nessun errore e almeno una riga: il documento si può salvare.
    pub salvabile: bool,
    #[serde(skip)]
    documento: Option<Ddt>,
}

impl Calcolo {
    /// Il documento da salvare, o tutti gli errori con la riga a cui si riferiscono.
    pub fn in_ddt(self) -> Result<Ddt, ErroreApi> {
        match self.documento {
            Some(ddt) if self.salvabile => Ok(ddt),
            _ => {
                let mut motivi = self.errori;
                for (n, riga) in (1..).zip(&self.righe) {
                    motivi.extend(riga.errori.iter().map(|e| format!("riga {n}: {e}")));
                }
                if motivi.is_empty() {
                    motivi.push("nessuna riga".into());
                }
                Err(ErroreApi::Bozza(motivi))
            }
        }
    }
}

struct Cliente {
    codice: String,
    ragione_sociale: String,
    pagamento: Option<String>,
    listino: Option<String>,
    iban: Option<String>,
    bic: Option<String>,
    conto_banca: Option<String>,
    agente: Option<String>,
    scissione_pagamenti: bool,
}

fn cliente(conn: &Connection, codice: &str, errori: &mut Vec<String>) -> Result<Option<Cliente>, ErroreApi> {
    let trovato = conn
        .prepare_cached(
            "SELECT codice, ragione_sociale, pagamento, listino, iban, bic, conto_banca, agente, scissione_pagamenti, \
             cliente, obsoleto FROM clienti_fornitori WHERE codice = ?1",
        )?
        .query_row([codice.trim()], |r| {
            Ok((
                Cliente {
                    codice: r.get(0)?,
                    ragione_sociale: r.get(1)?,
                    pagamento: r.get(2)?,
                    listino: r.get(3)?,
                    iban: r.get(4)?,
                    bic: r.get(5)?,
                    conto_banca: r.get(6)?,
                    agente: r.get(7)?,
                    scissione_pagamenti: r.get(8)?,
                },
                r.get::<_, bool>(9)?,
                r.get::<_, bool>(10)?,
            ))
        })
        .optional()?;
    Ok(match trovato {
        None => {
            errori.push(format!("cliente {} inesistente", codice.trim()));
            None
        }
        Some((_, false, _)) => {
            errori.push(format!("{} non è un cliente", codice.trim()));
            None
        }
        Some((_, _, true)) => {
            errori.push(format!("cliente {} obsoleto", codice.trim()));
            None
        }
        Some((cliente, true, false)) => Some(cliente),
    })
}

fn destinazione(
    conn: &Connection,
    cliente: &str,
    richiesta: Option<&str>,
    errori: &mut Vec<String>,
) -> Result<Option<String>, ErroreApi> {
    match richiesta.map(str::trim) {
        Some("") => Ok(None),
        None => Ok(conn
            .prepare_cached(
                "SELECT codice FROM destinazioni WHERE cliente = ?1 AND predefinita = 1 AND obsoleto = 0 \
                 ORDER BY codice LIMIT 1",
            )?
            .query_row([cliente], |r| r.get(0))
            .optional()?),
        Some(codice) => {
            let trovata: Option<String> = conn
                .prepare_cached("SELECT codice FROM destinazioni WHERE cliente = ?1 AND codice = ?2")?
                .query_row([cliente, codice], |r| r.get(0))
                .optional()?;
            if trovata.is_none() {
                errori.push(format!("destinazione {codice} inesistente per il cliente {cliente}"));
            }
            Ok(trovata)
        }
    }
}

struct Articolo {
    codice: String,
    descrizione: String,
    unita_misura: String,
    aliquota: Option<String>,
    conto_ricavo: Option<String>,
    obsoleto: bool,
}

fn articolo(conn: &Connection, codice: &str) -> Result<Option<Articolo>, ErroreApi> {
    Ok(conn
        .prepare_cached(
            "SELECT codice, descrizione, unita_misura, aliquota_vendita, conto_ricavo, obsoleto FROM articoli \
             WHERE codice = ?1",
        )?
        .query_row([codice], |r| {
            Ok(Articolo {
                codice: r.get(0)?,
                descrizione: r.get(1)?,
                unita_misura: r.get(2)?,
                aliquota: r.get(3)?,
                conto_ricavo: r.get(4)?,
                obsoleto: r.get(5)?,
            })
        })
        .optional()?)
}

/// Unità della riga, scritta come in anagrafica, e fattore verso l'unità principale.
fn unita(conn: &Connection, articolo: &Articolo, richiesta: Option<&str>) -> Result<Result<(String, Decimal), String>, ErroreApi> {
    let mut stmt = conn.prepare_cached(
        "SELECT unita_misura, fattore FROM articoli_unita WHERE articolo = ?1 \
         AND (unita_misura = ?2 OR (?2 IS NULL AND predefinita = 1)) ORDER BY ordine LIMIT 1",
    )?;
    let richiesta = richiesta.map(str::trim).filter(|u| !u.is_empty());
    let trovata: Option<(String, String)> =
        stmt.query_row(rusqlite::params![articolo.codice, richiesta], |r| Ok((r.get(0)?, r.get(1)?))).optional()?;
    if let Some((um, fattore)) = trovata {
        return Ok(fattore
            .parse::<Decimal>()
            .map(|f| (um, f))
            .map_err(|_| format!("fattore {fattore} non numerico")));
    }
    let principale = richiesta.is_none_or(|u| u.eq_ignore_ascii_case(&articolo.unita_misura));
    if !principale {
        return Ok(Err(format!(
            "unità {} non prevista per l'articolo {}",
            richiesta.unwrap_or_default(),
            articolo.codice
        )));
    }
    let codice: Option<String> = conn
        .prepare_cached("SELECT codice FROM unita_misura WHERE codice = ?1")?
        .query_row([&articolo.unita_misura], |r| r.get(0))
        .optional()?;
    Ok(Ok((codice.unwrap_or_else(|| articolo.unita_misura.clone()), Decimal::ONE)))
}

/// Magazzino di scarico: quello indicato o il predefinito. Va sempre scritto: senza, Arca
/// registrerebbe quello della causale e il documento riletto sarebbe diverso dall'evento.
fn magazzino(conn: &Connection, richiesto: Option<&str>, predefinito: &str) -> Result<Result<String, String>, ErroreApi> {
    let codice = richiesto.map(str::trim).filter(|m| !m.is_empty()).unwrap_or(predefinito);
    Ok(conn
        .prepare_cached("SELECT codice FROM magazzini WHERE codice = ?1")?
        .query_row([codice], |r| r.get(0))
        .optional()?
        .ok_or_else(|| format!("magazzino {codice} inesistente")))
}

/// Istante al minuto: `TimeIns` e `TrasportoDataora` sono `smalldatetime` in Arca.
pub fn al_minuto(istante: NaiveDateTime) -> NaiveDateTime {
    istante.with_second(0).and_then(|t| t.with_nanosecond(0)).unwrap_or(istante)
}

/// Completa e calcola la bozza sulle anagrafiche del database, all'istante `adesso`.
pub fn calcola(conn: &Connection, bozza: &Bozza, predefiniti: &Predefiniti, adesso: NaiveDateTime) -> Result<Calcolo, ErroreApi> {
    let mut errori = Vec::new();
    let registrato_il = al_minuto(adesso);
    let data = bozza.data.unwrap_or(registrato_il.date());
    let inizio_trasporto = data.and_time(registrato_il.time());
    let cliente = cliente(conn, &bozza.cliente, &mut errori)?;
    let destinazione = match &cliente {
        Some(c) => destinazione(conn, &c.codice, bozza.destinazione.as_deref(), &mut errori)?,
        None => None,
    };
    if bozza.numero == Some(0) {
        errori.push("numero 0: lasciare vuoto per il prossimo numero".into());
    }

    let aliquote = atlas_db::anagrafiche::tabella_aliquote(conn)?;
    let predefiniti_righe = atlas_db::anagrafiche::predefiniti_righe(conn)?;
    let listino = cliente
        .as_ref()
        .and_then(|c| c.listino.clone())
        .unwrap_or_else(|| predefiniti.listino.clone());
    let mut righe = Vec::with_capacity(bozza.righe.len());
    let mut documento = Vec::with_capacity(bozza.righe.len());
    for riga in &bozza.righe {
        let (calcolata, completa) = calcola_riga(
            conn,
            riga,
            &Contesto {
                listino: &listino,
                magazzino: &predefiniti.magazzino,
                data,
                aliquote: &aliquote,
                predefiniti: predefiniti_righe.as_ref(),
            },
        )?;
        righe.push(calcolata);
        if let Some(completa) = completa {
            documento.push(completa);
        }
    }

    let valide: Vec<(CodiceAliquota, Decimal)> = righe
        .iter()
        .filter(|r| r.errori.is_empty())
        .filter_map(|r| Some((CodiceAliquota::nuovo(r.aliquota.as_deref()?), r.totale?)))
        .collect();
    let castelletto = match Castelletto::calcola(valide.iter().map(|(a, t)| (a, *t)), &aliquote) {
        Ok(castelletto) => castelletto,
        Err(e) => {
            errori.push(e.to_string());
            Castelletto::default()
        }
    };
    let scissione = cliente.as_ref().is_some_and(|c| c.scissione_pagamenti);
    let netto_a_pagare = castelletto.netto_a_pagare(scissione, Decimal::ZERO);
    let righe_con_errori = righe.iter().any(|r| !r.errori.is_empty());
    let salvabile = errori.is_empty() && !righe_con_errori && !documento.is_empty();

    let testata = cliente.as_ref().map(|c| TestataCalcolata {
        cliente: c.codice.clone(),
        ragione_sociale: c.ragione_sociale.clone(),
        destinazione: destinazione.clone(),
        data,
        esercizio: data.year(),
        numero: bozza.numero,
        pagamento: c.pagamento.clone(),
        listino: c.listino.clone(),
        listino_prezzi: listino.clone(),
        scissione_pagamenti: c.scissione_pagamenti,
        inizio_trasporto,
    });
    let documento = match cliente {
        Some(c) if salvabile => Some(Ddt {
            numero: bozza.numero.unwrap_or(0),
            data,
            cliente: c.codice,
            destinazione,
            sede: None,
            pagamento: c.pagamento,
            listino_cliente: c.listino,
            iban: c.iban,
            bic: c.bic,
            conto_banca: c.conto_banca,
            agente: c.agente,
            inizio_trasporto: Some(inizio_trasporto),
            scissione_pagamenti: c.scissione_pagamenti,
            operatore: predefiniti.operatore.clone(),
            registrato_il,
            righe: documento,
        }),
        _ => None,
    };
    Ok(Calcolo {
        testata,
        righe,
        castelletto,
        netto_a_pagare,
        errori,
        salvabile,
        documento,
    })
}

struct Contesto<'a> {
    listino: &'a str,
    magazzino: &'a str,
    data: NaiveDate,
    aliquote: &'a TabellaAliquote,
    predefiniti: Option<&'a atlas_db::anagrafiche::PredefinitiRighe>,
}

fn vuota(riga: &BozzaRiga) -> RigaCalcolata {
    RigaCalcolata {
        vuota: true,
        articolo: riga.articolo.clone(),
        descrizione: None,
        unita_misura: None,
        fattore_um1: None,
        aliquota: None,
        quantita: None,
        prezzo: None,
        origine_prezzo: None,
        prezzo_listino: None,
        prezzo_modificato: false,
        totale: None,
        avvisi: Vec::new(),
        errori: Vec::new(),
    }
}

/// Guardrail della pesata: tara che annulla il lordo, colli con i decimali.
pub fn avvisi_pesata(colli: Decimal, lordo: Decimal, tara: Decimal) -> Vec<Avviso> {
    let mut avvisi = Vec::new();
    if !lordo.is_zero() && !tara.is_zero() && !colli.is_zero() && colli * tara >= lordo {
        avvisi.push(Avviso {
            codice: "tara_maggiore_lordo",
            messaggio: format!("tara {} × {} colli ≥ lordo {}", tara.normalize(), colli.normalize(), lordo.normalize()),
        });
    }
    if !colli.fract().is_zero() {
        avvisi.push(Avviso {
            codice: "colli_decimali",
            messaggio: format!("colli con decimali: {}", colli.normalize()),
        });
    }
    avvisi
}

fn calcola_riga(conn: &Connection, riga: &BozzaRiga, ctx: &Contesto<'_>) -> Result<(RigaCalcolata, Option<RigaDdt>), ErroreApi> {
    let codice = riga.articolo.trim();
    let mut esito = vuota(riga);
    if codice.is_empty() {
        return Ok((esito, None));
    }
    esito.vuota = false;
    esito.avvisi = avvisi_pesata(riga.colli, riga.lordo, riga.tara);
    let Some(articolo) = articolo(conn, codice)? else {
        esito.errori.push(format!("articolo {codice} inesistente"));
        return Ok((esito, None));
    };
    esito.articolo = articolo.codice.clone();
    if articolo.obsoleto {
        esito.errori.push(format!("articolo {} obsoleto", articolo.codice));
    }
    let descrizione = riga.descrizione.clone().unwrap_or_else(|| articolo.descrizione.clone());
    esito.descrizione = Some(descrizione.clone());

    let (unita_misura, fattore) = match unita(conn, &articolo, riga.unita_misura.as_deref())? {
        Ok(u) => u,
        Err(e) => {
            esito.errori.push(e);
            (articolo.unita_misura.clone(), Decimal::ONE)
        }
    };
    esito.unita_misura = Some(unita_misura.clone());
    esito.fattore_um1 = Some(fattore);

    let aliquota = articolo.aliquota.clone().or_else(|| ctx.predefiniti.map(|p| p.aliquota.clone()));
    let conto_ricavo = articolo.conto_ricavo.clone().or_else(|| ctx.predefiniti.map(|p| p.conto_ricavo.clone()));
    let (Some(aliquota), Some(conto_ricavo)) = (aliquota, conto_ricavo) else {
        esito.errori.push("aliquota o conto ricavo mancanti (predefiniti delle righe non importati)".into());
        return Ok((esito, None));
    };
    let aliquota = CodiceAliquota::nuovo(&aliquota);
    esito.aliquota = Some(aliquota.as_str().to_owned());
    let percentuale = match ctx.aliquote.percentuale(&aliquota) {
        Ok(p) => p,
        Err(e) => {
            esito.errori.push(e.to_string());
            Decimal::ZERO
        }
    };

    let listino: Option<PrezzoListino> = prezzi::prezzo_listino(conn, ctx.listino, &articolo.codice, ctx.data)?;
    let prezzo_listino = listino.as_ref().map(|l| l.prezzo_riga(percentuale, fattore));
    esito.prezzo_listino = prezzo_listino;
    let (prezzo, origine, sconto) = match (riga.prezzo, prezzo_listino) {
        (Some(p), _) => (p, OriginePrezzo::Manuale, riga.sconto.clone().unwrap_or_default()),
        (None, Some(p)) => (
            p,
            OriginePrezzo::Listino,
            riga.sconto.clone().or_else(|| listino.as_ref().and_then(|l| l.sconto.clone())).unwrap_or_default(),
        ),
        (None, None) => {
            esito.errori.push(format!("prezzo mancante: l'articolo non è nel listino {}", ctx.listino));
            return Ok((esito, None));
        }
    };
    esito.prezzo = Some(prezzo);
    esito.origine_prezzo = Some(origine);
    esito.prezzo_modificato = origine == OriginePrezzo::Manuale && prezzo_listino.is_some_and(|l| l != prezzo);
    let sconto_addizionale = riga.sconto_addizionale.clone().unwrap_or_default();

    let pesata = match Pesata::nuova(riga.colli, riga.lordo, riga.tara) {
        Ok(p) => p,
        Err(e) => {
            esito.errori.push(e.to_string());
            return Ok((esito, None));
        }
    };
    // Arca registra solo `Qta`: una quantità uguale al netto non è una quantità forzata.
    let quantita_forzata = riga.quantita.filter(|q| *q != pesata.netto());
    let quantita = quantita_forzata.unwrap_or_else(|| pesata.netto());
    esito.quantita = Some(quantita);
    let merce = (|| {
        Ok::<_, atlas_core::ErroreCalcolo>(RigaMerce {
            quantita: Limitato::nuovo("quantità", quantita)?,
            prezzo_unitario: Limitato::nuovo("prezzo", prezzo)?,
            prezzo_addizionale: Limitato::ZERO,
            sconto: Sconto::da_testi(&sconto, &sconto_addizionale)?,
            aliquota: Some(aliquota.clone()),
        })
    })();
    match merce {
        Ok(merce) => esito.totale = Some(merce.totale()),
        Err(e) => esito.errori.push(e.to_string()),
    }
    let magazzino = match magazzino(conn, riga.magazzino.as_deref(), ctx.magazzino)? {
        Ok(m) => Some(m),
        Err(e) => {
            esito.errori.push(e);
            None
        }
    };
    if !esito.errori.is_empty() {
        return Ok((esito, None));
    }
    let completa = RigaDdt {
        articolo: articolo.codice,
        descrizione,
        unita_misura,
        fattore_um1: fattore,
        conto_ricavo,
        aliquota,
        id_listino_articolo: listino.and_then(|l| i32::try_from(l.id).ok()),
        pesata,
        quantita_forzata,
        prezzo_unitario: prezzo,
        sconto_riga: sconto,
        sconto_addizionale,
        magazzino,
    };
    Ok((esito, Some(completa)))
}

#[cfg(test)]
mod tests {
    use super::*;
    use atlas_db::prova::{adesso, database};
    use rust_decimal_macros::dec;

    fn riga(articolo: &str, colli: Decimal, lordo: Decimal, tara: Decimal) -> BozzaRiga {
        BozzaRiga {
            articolo: articolo.into(),
            colli,
            lordo,
            tara,
            ..BozzaRiga::default()
        }
    }

    fn bozza(righe: Vec<BozzaRiga>) -> Bozza {
        Bozza {
            cliente: "c000380".into(),
            righe,
            ..Bozza::default()
        }
    }

    #[test]
    fn completa_testata_e_righe_dalle_anagrafiche_come_il_bo_5455() {
        let conn = database();
        let mut pist = riga("pist", dec!(0), dec!(0.5), dec!(0));
        pist.prezzo = Some(dec!(22.40));
        let calcolo = calcola(&conn, &bozza(vec![riga("BAN", dec!(1), dec!(5.46), dec!(0.30)), pist]), &Predefiniti::default(), adesso()).unwrap();
        assert!(calcolo.salvabile, "{calcolo:?}");
        let testata = calcolo.testata.clone().unwrap();
        assert_eq!((testata.cliente.as_str(), testata.destinazione.as_deref()), ("C000380", Some("ALI")));
        // BAN: 5,16 kg × 1,80 di listino = 9,29 al 4%; PIST: 0,5 × 22,40 = 11,20 al 10%.
        let banane = &calcolo.righe[0];
        assert_eq!((banane.quantita, banane.prezzo, banane.totale), (Some(dec!(5.16)), Some(dec!(1.80)), Some(dec!(9.29))));
        assert_eq!((banane.origine_prezzo, banane.prezzo_modificato), (Some(OriginePrezzo::Listino), false));
        assert_eq!(calcolo.righe[1].aliquota.as_deref(), Some("10"));
        assert_eq!(calcolo.castelletto.totale_documento, dec!(9.29) + dec!(0.37) + dec!(11.20) + dec!(1.12));

        let ddt = calcolo.in_ddt().unwrap();
        let mut atteso = atlas_db::prova::ddt(0).righe.remove(0);
        atteso.descrizione = "BANANE".into(); // dall'anagrafica
        assert_eq!(ddt.righe[0], atteso, "stessa riga del BO di prova");
        assert_eq!((ddt.righe[1].articolo.as_str(), ddt.righe[1].id_listino_articolo), ("PIST", None));
        assert_eq!((ddt.registrato_il, ddt.inizio_trasporto), (adesso(), Some(adesso())));
        assert_eq!((ddt.pagamento.as_deref(), ddt.listino_cliente.as_deref()), (Some("B030"), Some("0000001")));
    }

    #[test]
    fn righe_incomplete_calcolate_lo_stesso_con_errori_e_avvisi() {
        let conn = database();
        let mut modificata = riga("BAN", dec!(2.5), dec!(0.5), dec!(0.30));
        modificata.prezzo = Some(dec!(2));
        let righe = vec![modificata, riga("", dec!(0), dec!(0), dec!(0)), riga("NONESISTE", dec!(1), dec!(1), dec!(0))];
        let calcolo = calcola(&conn, &bozza(righe), &Predefiniti::default(), adesso()).unwrap();
        assert!(!calcolo.salvabile);
        let codici: Vec<&str> = calcolo.righe[0].avvisi.iter().map(|a| a.codice).collect();
        assert_eq!(codici, ["tara_maggiore_lordo", "colli_decimali"]);
        assert!(calcolo.righe[0].prezzo_modificato);
        assert!(calcolo.righe[1].vuota);
        assert_eq!(calcolo.righe[2].errori, ["articolo NONESISTE inesistente"]);
        // Il castelletto conta la riga valida: −0,25 kg × 2,00.
        assert_eq!(calcolo.castelletto.totale_imponibile, dec!(-0.50));
        let ErroreApi::Bozza(motivi) = calcolo.in_ddt().unwrap_err() else { panic!() };
        assert_eq!(motivi, ["riga 3: articolo NONESISTE inesistente"]);
    }

    #[test]
    fn testata_errata_e_numero_zero_rifiutati() {
        let conn = database();
        let mut errata = bozza(vec![riga("BAN", dec!(1), dec!(1), dec!(0))]);
        errata.cliente = "C999".into();
        errata.numero = Some(0);
        let calcolo = calcola(&conn, &errata, &Predefiniti::default(), adesso()).unwrap();
        assert_eq!(calcolo.errori.len(), 2, "{:?}", calcolo.errori);
        let mut destinazione = bozza(vec![riga("BAN", dec!(1), dec!(1), dec!(0))]);
        destinazione.destinazione = Some("XXX".into());
        assert!(!calcola(&conn, &destinazione, &Predefiniti::default(), adesso()).unwrap().salvabile);
        destinazione.destinazione = Some(String::new());
        let calcolo = calcola(&conn, &destinazione, &Predefiniti::default(), adesso()).unwrap();
        assert_eq!(calcolo.testata.unwrap().destinazione, None, "stringa vuota: nessuna destinazione");
    }

    #[test]
    fn quantita_uguale_al_netto_non_e_forzata_e_unita_non_prevista_rifiutata() {
        let conn = database();
        let mut uguale = riga("BAN", dec!(1), dec!(5.46), dec!(0.30));
        uguale.quantita = Some(dec!(5.16));
        let mut pezzi = riga("BAN", dec!(1), dec!(0), dec!(0));
        pezzi.unita_misura = Some("PZ".into());
        let calcolo = calcola(&conn, &bozza(vec![uguale, pezzi]), &Predefiniti::default(), adesso()).unwrap();
        assert_eq!(calcolo.righe[1].errori, ["unità PZ non prevista per l'articolo BAN"]);
        let calcolo = calcola(&conn, &bozza(vec![calcolo_riga_sola()]), &Predefiniti::default(), adesso()).unwrap();
        assert_eq!(calcolo.in_ddt().unwrap().righe[0].quantita_forzata, None);
    }

    fn calcolo_riga_sola() -> BozzaRiga {
        let mut r = riga("BAN", dec!(1), dec!(5.46), dec!(0.30));
        r.quantita = Some(dec!(5.16));
        r
    }

    #[test]
    fn bozza_da_json_con_numeri_e_testi() {
        let bozza: Bozza = serde_json::from_str(
            r#"{"cliente": "C000380", "righe": [{"articolo": "BAN", "colli": 1, "lordo": "5.46", "tara": 0.3}]}"#,
        )
        .unwrap();
        assert_eq!((bozza.righe[0].lordo, bozza.righe[0].tara), (dec!(5.46), dec!(0.3)));
        assert!(serde_json::from_str::<Bozza>(r#"{"cliente": "C1", "sconosciuto": 1}"#).is_err());
    }
}
