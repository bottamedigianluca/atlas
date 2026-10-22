//! Cliente nuovo creato in ATLAS: i campi con i nomi delle colonne di Arca, i predefiniti che Arca
//! mette a un cliente nuovo, i controlli prima del salvataggio e le righe di `CF` e `CFContatto`
//! che la replica scrive.
//!
//! Colonne obbligatorie di `CF` (NOT NULL senza default, lette dal clone il 22/10/2026): `Cd_CF`,
//! `Descrizione`, `TipoDitta`, `Cliente`, `Fornitore`, `ProspectCliente`, `ProspectFornitore`,
//! `TipoCF`, `Cd_VL`, `Id_Lingua`, `Sconto`, `Provvigione`, `SpeseIncasso`, `SpeseBolli`, `Fido`,
//! `ScGiornoFisso1-3`, `Ue`, `Intra`, `Ritenuta`, `IvaSospesa`, `IvaSplit`,
//! `ProceduraConcorsuale`, `ConsumatoreFinale`, `EntePubblico`, `Obsoleto`. In `CFContatto` solo
//! `Cd_CF`. Sui clienti veri (C000001, C000008, C000041) `Id_Lingua` vale 1040 (italiano) e il
//! primo contatto è "Aziendale" con tipo -1 (telefono e fax dell'azienda); le persone hanno tipo 1. Nessuno dei due ha trigger sull'inserimento (`CF_atrg_iod`, `CF_atrg_brd`,
//! `CFContatto_atrg_brd` sono su cancellazione e modifica): l'`INSERT` diretto è quello di Arca.

use atlas_arca::record::{Record, Valore};
use atlas_db::anagrafiche::ClienteFornitore;
use chrono::NaiveDateTime;
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value, json};

use crate::ErroreSync;
use crate::anagrafiche::{CF_EXTRA, Tipo};

pub type Campi = Map<String, Value>;

/// Il cliente nuovo: i campi di `CF` e del contatto principale (`CFContatto`).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct NuovoCliente {
    pub cf: Campi,
    #[serde(default)]
    pub contatto: Option<Campi>,
}

/// Le colonne di `CF` che sono colonne vere di `clienti_fornitori`, con il loro tipo.
const CF_BASE: &[(&str, Tipo)] = &[
    ("Cd_CF", Tipo::Testo),
    ("Descrizione", Tipo::Testo),
    ("Indirizzo", Tipo::Testo),
    ("Cap", Tipo::Testo),
    ("Localita", Tipo::Testo),
    ("Cd_Provincia", Tipo::Testo),
    ("Cd_Nazione", Tipo::Testo),
    ("PartitaIva", Tipo::Testo),
    ("CodiceFiscale", Tipo::Testo),
    ("CodiceFPR", Tipo::Testo),
    ("CodiceIPA", Tipo::Testo),
    ("Cliente", Tipo::Bit),
    ("Fornitore", Tipo::Bit),
    ("Cd_PG", Tipo::Testo),
    ("Cd_LS_1", Tipo::Testo),
    ("Iban", Tipo::Testo),
    ("BicCode", Tipo::Testo),
    ("Cd_CGConto_Banca", Tipo::Testo),
    ("Cd_CGConto_Merce", Tipo::Testo),
    ("Cd_Agente_1", Tipo::Testo),
    ("IvaSplit", Tipo::Bit),
    ("EntePubblico", Tipo::Bit),
    ("Cd_Aliquota", Tipo::Testo),
    ("Cd_CF_Fatt", Tipo::Testo),
    ("Fido", Tipo::Decimale),
    ("Note_CF", Tipo::Testo),
    ("Obsoleto", Tipo::Bit),
];

/// Colonne che il cliente nuovo non scrive: calcolate da Arca o interne (XML).
const NON_SCRITTE: &[&str] = &["Cd_NazioneProvincia", "Attributi", "ExtraInfo"];

/// Lunghezza massima dei testi di `CF` (schema del database del negozio).
const LUNGHEZZE: &[(&str, usize)] = &[
    ("Cd_CF", 7), ("Descrizione", 80), ("Indirizzo", 80), ("Localita", 60), ("Cap", 10), ("Cd_Provincia", 3),
    ("Cd_Nazione", 2), ("PartitaIva", 17), ("CodiceFiscale", 16), ("CodiceIPA", 6), ("CodiceFPR", 100),
    ("TipoDitta", 1), ("TipoCF", 1), ("TipoCF_1", 1), ("Cd_CFClasse1", 3), ("Cd_CFClasse2", 3), ("Cd_CFClasse3", 3),
    ("Cd_CFGruppo1", 3), ("Cd_CFGruppo2", 3), ("Cd_CFGruppo3", 3), ("Cd_PG", 4), ("Cd_CGConto_Mastro", 12),
    ("Cd_CGConto_Banca", 12), ("Cd_CGConto_Merce", 12), ("Cd_LS_1", 7), ("Cd_LS_2", 7), ("Cd_VL", 3), ("Cd_CFStato", 3),
    ("Cd_CFZona", 3), ("Cd_CFSettore", 3), ("Cd_DOPorto", 3), ("Cd_DOSped", 3), ("Cd_DOVettore", 2), ("Cd_SL", 10),
    ("Cd_Agente_1", 3), ("Cd_Agente_2", 3), ("Sconto", 10), ("Provvigione", 10), ("Cd_INTRAConsegna", 1),
    ("Cd_INTRATrasporto", 1), ("Cd_INTRATransazione", 2), ("Cd_Nazione_Origine", 2), ("Cd_Provincia_Origine", 3),
    ("Cd_Nazione_Destinazione", 2), ("Cd_Provincia_Destinazione", 3), ("Cd_Nazione_Provenienza", 2), ("Cd_CACda", 20),
    ("Cd_Aliquota", 3), ("Cd_CF_Fatt", 7), ("Iban", 34), ("BicCode", 11), ("Cd_Abicab", 10), ("ContoCorrente", 20),
    ("Ricarica", 15), ("NRea", 10), ("Cd_F24Comune", 4), ("Cd_AE_NaturaGiuridica", 2), ("Cd_AE_Atecofin", 6),
    ("SDD_IdMandato", 35), ("CD_ReverseCharge", 3), ("Peppol_Endpoint", 22), ("SO_Indirizzo", 60),
    ("SO_NumeroCivico", 8), ("SO_Cap", 5), ("SO_Localita", 60), ("SO_Cd_Provincia", 3), ("SO_Cd_Nazione", 2),
    ("RF_PartitaIva", 28), ("RF_RagioneSociale", 80), ("RF_Nome", 60), ("RF_Cognome", 60), ("UserIns", 48),
    ("UserUpd", 48), ("xCd_Exp", 30), ("RF_Cd_Nazione", 2), ("Cd_NazioneIva", 2), ("FTE_RegimeFiscale", 4),
    ("FTE_Cd_CN", 3), ("Cd_ParcT", 10), ("Cd_CF_BPoint", 7),
];

/// Le colonne di `CFContatto` scritte per il contatto "Aziendale": quelle viste sui clienti veri.
/// Il tipo è `Id_CFContattoTipo` (-1 aziendale, 1 persona, -5 destinazione diversa: così lo usa
/// `fedi_xarlistdest`).
const CONTATTO: &[&str] = &["Cd_CF", "Descrizione", "Telefono", "Fax", "Email", "Id_CFContattoTipo"];

/// Il tipo del contatto aziendale, quello che Arca crea con il cliente.
pub const CONTATTO_AZIENDALE: i64 = -1;

/// Codici, maiuscoli come li salva Arca.
const MAIUSCOLI: &[&str] = &[
    "Cd_CF", "Cd_Provincia", "Cd_Nazione", "Cd_NazioneIva", "PartitaIva", "CodiceFiscale", "CodiceIPA", "Iban", "BicCode",
    "TipoDitta",
];

/// Nazioni dell'Unione europea: per loro `CF.Ue = 1` (Italia compresa).
const UE: &[&str] = &[
    "AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "ES", "FI", "FR", "GR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
    "NL", "PL", "PT", "RO", "SE", "SI", "SK",
];

/// Cifra di controllo della partita IVA italiana (algoritmo di Luhn sulle prime 10 cifre).
pub fn cifra_di_controllo(numero: &str) -> bool {
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

/// IBAN con il controllo modulo 97.
fn iban_valido(iban: &str) -> bool {
    if !(15..=34).contains(&iban.len()) || !iban.chars().all(|c| c.is_ascii_alphanumeric()) {
        return false;
    }
    let (testa, coda) = iban.split_at(4);
    let mut resto: u32 = 0;
    for c in coda.chars().chain(testa.chars()) {
        let Some(v) = c.to_digit(36) else { return false };
        for cifra in v.to_string().chars().filter_map(|d| d.to_digit(10)) {
            resto = (resto * 10 + cifra) % 97;
        }
    }
    resto == 1
}

fn tipo_di(colonna: &str) -> Option<Tipo> {
    CF_BASE.iter().chain(CF_EXTRA).find(|(c, _)| *c == colonna).map(|&(_, t)| t)
}

fn testo<'a>(campi: &'a Campi, colonna: &str) -> &'a str {
    campi.get(colonna).and_then(Value::as_str).map_or("", str::trim)
}

/// Il valore JSON nel tipo della colonna; `None` se vuoto.
fn valore(colonna: &str, tipo: Tipo, v: &Value) -> Result<Option<Valore>, String> {
    let sbagliato = || format!("{colonna}: valore {v} non valido");
    if v.is_null() {
        return Ok(None);
    }
    Ok(Some(match tipo {
        Tipo::Testo | Tipo::Xml => match v {
            Value::String(t) => Valore::Testo(Some(t.trim_end().to_owned())),
            _ => return Err(sbagliato()),
        },
        Tipo::Bit => Valore::Bit(match v {
            Value::Bool(b) => *b,
            Value::Number(n) if n.as_u64() == Some(0) || n.as_u64() == Some(1) => n.as_u64() == Some(1),
            _ => return Err(sbagliato()),
        }),
        Tipo::Byte | Tipo::Corto | Tipo::Intero => {
            let n = match v {
                Value::Number(n) => n.as_i64(),
                Value::String(t) if t.trim().is_empty() => return Ok(None),
                Value::String(t) => t.trim().parse().ok(),
                _ => None,
            }
            .ok_or_else(sbagliato)?;
            match tipo {
                Tipo::Byte => Valore::Byte(u8::try_from(n).map_err(|_| sbagliato())?),
                Tipo::Corto => Valore::Piccolo(i16::try_from(n).map_err(|_| sbagliato())?),
                _ => Valore::Intero(Some(i32::try_from(n).map_err(|_| sbagliato())?)),
            }
        }
        Tipo::Decimale => {
            let t = match v {
                Value::Number(n) => n.to_string(),
                Value::String(t) if t.trim().is_empty() => return Ok(None),
                Value::String(t) => t.trim().replace(',', "."),
                _ => return Err(sbagliato()),
            };
            Valore::Decimale(t.parse::<Decimal>().map_err(|_| sbagliato())?)
        }
        Tipo::Data => match v {
            Value::String(t) if t.trim().is_empty() => return Ok(None),
            Value::String(t) => {
                let t = t.trim();
                let completa = if t.len() == 10 { format!("{t} 00:00:00") } else { t.to_owned() };
                Valore::DataOra(Some(
                    NaiveDateTime::parse_from_str(&completa, "%Y-%m-%d %H:%M:%S").map_err(|_| sbagliato())?,
                ))
            }
            _ => return Err(sbagliato()),
        },
    }))
}

impl NuovoCliente {
    pub fn codice(&self) -> &str {
        testo(&self.cf, "Cd_CF")
    }

    /// I predefiniti di Arca per un cliente nuovo dove il campo manca, testi puliti e codici in
    /// maiuscolo, l'operatore e l'istante di registrazione.
    pub fn completa(&mut self, operatore: &str, adesso: NaiveDateTime) {
        for (colonna, v) in self.cf.iter_mut() {
            if let Value::String(t) = v {
                let pulito = t.trim();
                *t = if MAIUSCOLI.contains(&colonna.as_str()) {
                    pulito.to_uppercase().replace(' ', "")
                } else {
                    pulito.to_owned()
                };
            }
        }
        let predefiniti = [
            ("TipoDitta", json!("G")),
            ("ProspectCliente", json!(false)),
            ("ProspectFornitore", json!(false)),
            ("TipoCF", json!("C")),
            ("Cd_VL", json!("EUR")),
            ("Id_Lingua", json!(1040)),
            ("Sconto", json!("")),
            ("Provvigione", json!("")),
            ("SpeseIncasso", json!(false)),
            ("SpeseBolli", json!(false)),
            ("Fido", json!("0")),
            ("ScGiornoFisso1", json!(0)),
            ("ScGiornoFisso2", json!(0)),
            ("ScGiornoFisso3", json!(0)),
            ("Intra", json!(false)),
            ("Ritenuta", json!(false)),
            ("IvaSospesa", json!(false)),
            ("IvaSplit", json!(false)),
            ("ProceduraConcorsuale", json!(false)),
            ("ConsumatoreFinale", json!(false)),
            ("EntePubblico", json!(false)),
            ("Obsoleto", json!(false)),
            ("Cd_Nazione", json!("IT")),
            ("Cd_CGConto_Mastro", json!("04010101001")),
            ("EsclusoBlackList", json!(true)),
            ("FE_AddASW", json!(true)),
        ];
        for (colonna, v) in predefiniti {
            let vuoto = match self.cf.get(colonna) {
                None | Some(Value::Null) => true,
                Some(Value::String(t)) => t.is_empty() && !matches!(colonna, "Sconto" | "Provvigione"),
                _ => false,
            };
            if vuoto {
                self.cf.insert(colonna.to_owned(), v);
            }
        }
        if testo(&self.cf, "Cd_NazioneIva").is_empty() && !testo(&self.cf, "PartitaIva").is_empty() {
            let nazione = testo(&self.cf, "Cd_Nazione").to_owned();
            self.cf.insert("Cd_NazioneIva".into(), json!(nazione));
        }
        let ue = UE.contains(&testo(&self.cf, "Cd_Nazione"));
        self.cf.insert("Ue".into(), json!(ue));
        self.cf.insert("Cliente".into(), json!(true));
        self.cf.insert("Fornitore".into(), json!(false));
        let istante = json!(adesso.format("%Y-%m-%d %H:%M:%S").to_string());
        for (colonna, v) in [("UserIns", json!(operatore)), ("UserUpd", json!(operatore)), ("TimeIns", istante.clone()), ("TimeUpd", istante)] {
            self.cf.insert(colonna.into(), v);
        }
        if let Some(contatto) = self.contatto.as_mut() {
            contatto.retain(|_, v| v.as_str().is_none_or(|t| !t.trim().is_empty()) && !v.is_null());
            for v in contatto.values_mut() {
                if let Value::String(t) = v {
                    *t = t.trim().to_owned();
                }
            }
            // Un contatto senza telefono, fax né email non serve.
            if !contatto.keys().any(|k| k != "Descrizione" && k != "Id_CFContattoTipo" && k != "Cd_CF") {
                self.contatto = None;
            }
        }
        if let Some(contatto) = self.contatto.as_mut() {
            let codice = testo(&self.cf, "Cd_CF").to_owned();
            contatto.insert("Cd_CF".into(), json!(codice));
            contatto.entry("Descrizione").or_insert(json!("Aziendale"));
            contatto.entry("Id_CFContattoTipo").or_insert(json!(CONTATTO_AZIENDALE));
        }
    }

    /// I problemi che impediscono di salvare il cliente, uno per riga; vuoto se si può salvare.
    pub fn controlla(&self) -> Vec<String> {
        let mut problemi = Vec::new();
        let cf = &self.cf;
        let codice = testo(cf, "Cd_CF");
        if !(codice.len() == 7 && codice.starts_with('C') && codice[1..].chars().all(|c| c.is_ascii_digit())) {
            problemi.push(format!("codice {codice:?} non nella forma C000000"));
        }
        if testo(cf, "Descrizione").is_empty() {
            problemi.push("manca la ragione sociale".into());
        }
        if !matches!(testo(cf, "TipoDitta"), "G" | "F") {
            problemi.push("tipo figura: G persona giuridica o F persona fisica".into());
        }
        let partita_iva = testo(cf, "PartitaIva");
        let codice_fiscale = testo(cf, "CodiceFiscale");
        let nazione_iva = match testo(cf, "Cd_NazioneIva") {
            "" => testo(cf, "Cd_Nazione"),
            n => n,
        };
        if partita_iva.is_empty() && codice_fiscale.is_empty() {
            problemi.push("serve la partita IVA o il codice fiscale (fattura elettronica)".into());
        }
        if !partita_iva.is_empty() && nazione_iva == "IT" && !cifra_di_controllo(partita_iva) {
            problemi.push(format!("partita IVA {partita_iva} non valida: la cifra di controllo non torna"));
        }
        if !codice_fiscale.is_empty()
            && !(codice_fiscale.len() == 16 && codice_fiscale.chars().all(|c| c.is_ascii_alphanumeric())
                || codice_fiscale.len() == 11 && codice_fiscale.chars().all(|c| c.is_ascii_digit()))
        {
            problemi.push(format!("codice fiscale {codice_fiscale} non valido: 16 caratteri, o 11 cifre per le società"));
        }
        let destinatario = testo(cf, "CodiceFPR");
        if !destinatario.is_empty() && !(destinatario.len() == 7 && destinatario.chars().all(|c| c.is_ascii_alphanumeric()) || destinatario.contains('@')) {
            problemi.push(format!("codice destinatario {destinatario}: 7 caratteri, oppure l'indirizzo PEC"));
        }
        let iban = testo(cf, "Iban");
        if !iban.is_empty() && !iban_valido(iban) {
            problemi.push(format!("IBAN {iban} non valido"));
        }
        for (colonna, v) in cf {
            if NON_SCRITTE.contains(&colonna.as_str()) {
                continue;
            }
            let Some(tipo) = tipo_di(colonna) else {
                problemi.push(format!("campo {colonna} sconosciuto in CF"));
                continue;
            };
            if let Err(e) = valore(colonna, tipo, v) {
                problemi.push(e);
            }
            if let (Some(t), Some((_, massimo))) = (v.as_str(), LUNGHEZZE.iter().find(|(c, _)| c == colonna)) {
                if t.chars().count() > *massimo {
                    problemi.push(format!("{colonna}: al massimo {massimo} caratteri"));
                }
            }
        }
        if let Some(contatto) = &self.contatto {
            for (colonna, v) in contatto {
                if !CONTATTO.contains(&colonna.as_str()) {
                    problemi.push(format!("campo {colonna} del contatto non ancora scritto da ATLAS"));
                } else if colonna == "Id_CFContattoTipo" {
                    if v.as_i64().is_none_or(|t| i32::try_from(t).is_err()) {
                        problemi.push(format!("contatto, tipo {v} non valido"));
                    }
                } else if !v.is_string() {
                    problemi.push(format!("contatto, {colonna}: valore {v} non valido"));
                }
            }
            let email = testo(contatto, "Email");
            if !email.is_empty() && !(email.contains('@') && email.contains('.')) {
                problemi.push(format!("email {email} non valida"));
            }
        }
        problemi
    }

    /// Il cliente nel database ATLAS: le colonne vere e gli altri campi di `CF` in `extra`, come
    /// li scrive l'importazione.
    pub fn in_atlas(&self) -> ClienteFornitore {
        let cf = &self.cf;
        let opz = |c: &str| Some(testo(cf, c).to_owned()).filter(|t| !t.is_empty());
        let bit = |c: &str| cf.get(c).and_then(Value::as_bool).unwrap_or(false);
        let extra: Campi = CF_EXTRA
            .iter()
            .map(|(c, _)| ((*c).to_owned(), cf.get(*c).cloned().unwrap_or(Value::Null)))
            .collect();
        ClienteFornitore {
            codice: self.codice().to_owned(),
            ragione_sociale: testo(cf, "Descrizione").to_owned(),
            indirizzo: opz("Indirizzo"),
            cap: opz("Cap"),
            localita: opz("Localita"),
            provincia: opz("Cd_Provincia"),
            nazione: opz("Cd_Nazione"),
            partita_iva: opz("PartitaIva"),
            codice_fiscale: opz("CodiceFiscale"),
            codice_destinatario: opz("CodiceFPR"),
            codice_ipa: opz("CodiceIPA"),
            cliente: true,
            fornitore: false,
            pagamento: opz("Cd_PG"),
            listino: opz("Cd_LS_1"),
            iban: opz("Iban"),
            bic: opz("BicCode"),
            conto_banca: opz("Cd_CGConto_Banca"),
            conto_merce: opz("Cd_CGConto_Merce"),
            agente: opz("Cd_Agente_1"),
            scissione_pagamenti: bit("IvaSplit"),
            ente_pubblico: bit("EntePubblico"),
            aliquota: opz("Cd_Aliquota"),
            cliente_fatturazione: opz("Cd_CF_Fatt"),
            fido: match cf.get("Fido").map(|v| valore("Fido", Tipo::Decimale, v)) {
                Some(Ok(Some(Valore::Decimale(d)))) => Some(d.normalize()),
                _ => None,
            },
            note: opz("Note_CF"),
            obsoleto: bit("Obsoleto"),
            extra: Value::Object(extra).to_string(),
        }
    }

    /// Le righe di `CF` e, se c'è, di `CFContatto`, con i soli campi valorizzati: gli altri
    /// prendono il default della tabella, come in un cliente nuovo di Arca.
    pub fn righe_arca(&self) -> Result<(Record, Option<Record>), ErroreSync> {
        let mut cf = Record::nuovo("CF");
        for &(colonna, tipo) in CF_BASE.iter().chain(CF_EXTRA) {
            if NON_SCRITTE.contains(&colonna) {
                continue;
            }
            if let Some(v) = self.cf.get(colonna) {
                let valore = valore(colonna, tipo, v).map_err(|problema| ErroreSync::Dato {
                    tabella: "CF",
                    colonna,
                    problema,
                })?;
                if let Some(valore) = valore {
                    // Un testo vuoto vale assente, salvo i NOT NULL che Arca scrive vuoti.
                    let vuoto = matches!(&valore, Valore::Testo(Some(t)) if t.is_empty());
                    if !vuoto || matches!(colonna, "Sconto" | "Provvigione") {
                        cf = cf.con(colonna, valore);
                    }
                }
            }
        }
        let contatto = self.contatto.as_ref().map(|c| {
            CONTATTO.iter().fold(Record::nuovo("CFContatto"), |r, &colonna| match c.get(colonna) {
                Some(Value::String(t)) if !t.is_empty() => r.con(colonna, Valore::testo(t)),
                Some(Value::Number(n)) => match n.as_i64().and_then(|n| i32::try_from(n).ok()) {
                    Some(n) => r.con(colonna, Valore::Intero(Some(n))),
                    None => r,
                },
                _ => r,
            })
        });
        Ok((cf, contatto))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::NaiveDate;

    fn adesso() -> NaiveDateTime {
        NaiveDate::from_ymd_opt(2026, 10, 22).unwrap().and_hms_opt(9, 30, 0).unwrap()
    }

    fn nuovo() -> NuovoCliente {
        serde_json::from_value(json!({
            "cf": {
                "Cd_CF": "C000405",
                "Descrizione": " BOTTAMEDI KATIA FRUTTA E VERDURA ",
                "PartitaIva": "01392110225",
                "Indirizzo": "VIA ARTURO DE VARDA,16/a",
                "Cap": "38017",
                "Localita": "MEZZOLOMBARDO",
                "Cd_Provincia": "tn",
                "Cd_PG": "CON1",
                "Cd_LS_1": "0000001",
                "CodiceFPR": "X2PH38J",
                "Sconto": "",
                "ScGiornoFisso1": "",
            },
            "contatto": { "Telefono": "0461 602772", "Fax": "0461 602772", "Email": "" }
        }))
        .unwrap()
    }

    #[test]
    fn predefiniti_di_arca_e_campi_puliti() {
        let mut c = nuovo();
        c.completa("190", adesso());
        assert_eq!(c.controlla(), Vec::<String>::new());
        let cf = &c.cf;
        for (colonna, atteso) in [
            ("Descrizione", json!("BOTTAMEDI KATIA FRUTTA E VERDURA")),
            ("Cd_Provincia", json!("TN")),
            ("TipoDitta", json!("G")),
            ("Cliente", json!(true)),
            ("Fornitore", json!(false)),
            ("TipoCF", json!("C")),
            ("Cd_VL", json!("EUR")),
            ("Id_Lingua", json!(1040)),
            ("Sconto", json!("")),
            ("Provvigione", json!("")),
            ("Ue", json!(true)),
            ("Cd_NazioneIva", json!("IT")),
            ("Cd_CGConto_Mastro", json!("04010101001")),
            ("EsclusoBlackList", json!(true)),
            ("FE_AddASW", json!(true)),
            ("UserIns", json!("190")),
            ("TimeIns", json!("2026-10-22 09:30:00")),
        ] {
            assert_eq!(cf[colonna], atteso, "{colonna}");
        }
        let contatto = c.contatto.as_ref().unwrap();
        assert_eq!(contatto["Id_CFContattoTipo"], CONTATTO_AZIENDALE);
        assert_eq!(contatto["Descrizione"], "Aziendale");
        assert!(!contatto.contains_key("Email"), "i campi vuoti non si scrivono");
    }

    #[test]
    fn righe_di_cf_e_cfcontatto_con_i_tipi_di_arca() {
        let mut c = nuovo();
        c.completa("190", adesso());
        let (cf, contatto) = c.righe_arca().unwrap();
        assert_eq!(cf.valore("Cd_CF"), Some(&Valore::testo("C000405")));
        assert_eq!(cf.valore("Id_Lingua"), Some(&Valore::Piccolo(1040)));
        assert_eq!(cf.valore("ScGiornoFisso1"), Some(&Valore::Byte(0)));
        assert_eq!(cf.valore("Fido"), Some(&Valore::Decimale(Decimal::ZERO)));
        assert_eq!(cf.valore("Sconto"), Some(&Valore::testo("")));
        assert_eq!(cf.valore("Cliente"), Some(&Valore::Bit(true)));
        assert_eq!(cf.valore("TimeIns"), Some(&Valore::DataOra(Some(adesso()))));
        assert!(cf.valore("CodiceIPA").is_none(), "assente: default della tabella");
        // Tutte le colonne obbligatorie senza default ci sono.
        for colonna in [
            "Cd_CF", "Descrizione", "TipoDitta", "Cliente", "Fornitore", "ProspectCliente", "ProspectFornitore", "TipoCF",
            "Cd_VL", "Id_Lingua", "Sconto", "Provvigione", "SpeseIncasso", "SpeseBolli", "Fido", "ScGiornoFisso1",
            "ScGiornoFisso2", "ScGiornoFisso3", "Ue", "Intra", "Ritenuta", "IvaSospesa", "IvaSplit", "ProceduraConcorsuale",
            "ConsumatoreFinale", "EntePubblico", "Obsoleto",
        ] {
            assert!(cf.valore(colonna).is_some(), "{colonna} obbligatoria");
        }
        let contatto = contatto.unwrap();
        assert_eq!(contatto.valore("Cd_CF"), Some(&Valore::testo("C000405")));
        assert_eq!(contatto.valore("Telefono"), Some(&Valore::testo("0461 602772")));
        assert_eq!(contatto.valore("Fax"), Some(&Valore::testo("0461 602772")));
        assert_eq!(contatto.valore("Id_CFContattoTipo"), Some(&Valore::Intero(Some(-1))));
        let atlas = c.in_atlas();
        assert_eq!((atlas.codice.as_str(), atlas.pagamento.as_deref(), atlas.fido), ("C000405", Some("CON1"), Some(Decimal::ZERO)));
        let extra: Campi = serde_json::from_str(&atlas.extra).unwrap();
        assert_eq!(extra.len(), CF_EXTRA.len());
        assert_eq!(extra["Cd_VL"], "EUR");
    }

    #[test]
    fn controlli_prima_del_salvataggio() {
        let mut c = nuovo();
        c.cf.insert("PartitaIva".into(), json!("01392110226"));
        c.cf.insert("Descrizione".into(), json!(""));
        c.cf.insert("Iban".into(), json!("IT60X0542811101000000123457"));
        c.cf.insert("CodiceFPR".into(), json!("12345"));
        c.cf.insert("Cd_CFZona".into(), json!("TROPPO"));
        c.cf.insert("Inventato".into(), json!("x"));
        c.contatto.as_mut().unwrap().insert("Email".into(), json!("info"));
        c.completa("190", adesso());
        let problemi = c.controlla().join("\n");
        for atteso in ["ragione sociale", "cifra di controllo", "IBAN", "codice destinatario", "Cd_CFZona: al massimo 3", "Inventato sconosciuto", "email info"] {
            assert!(problemi.contains(atteso), "{atteso} in\n{problemi}");
        }
        assert!(iban_valido("IT60X0542811101000000123456"));
        for vera in ["02273530226", "01392110225", "01811370228", "02455240222"] {
            assert!(cifra_di_controllo(vera), "{vera}");
        }
    }

    #[test]
    fn senza_partita_iva_serve_il_codice_fiscale() {
        let mut c = nuovo();
        c.cf.remove("PartitaIva");
        c.cf.insert("TipoDitta".into(), json!("F"));
        c.completa("190", adesso());
        assert!(c.controlla().iter().any(|p| p.contains("codice fiscale")));
        c.cf.insert("CodiceFiscale".into(), json!("DLLMSM64R25F187A"));
        assert!(c.controlla().is_empty(), "{:?}", c.controlla());
        assert!(c.cf.get("Cd_NazioneIva").is_none(), "nazione IVA solo con la partita IVA");
    }
}
