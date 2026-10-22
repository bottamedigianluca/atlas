//! DDT di vendita: i dati che l'operatore batte o che ATLAS prende dalle anagrafiche al momento
//! dell'emissione. Tutto il resto (quantità netta, totali, castelletto) si ricalcola da qui.
//!
//! È il contenuto del documento nel database ATLAS e nell'evento di replica verso Arca.

use chrono::{NaiveDate, NaiveDateTime};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};

use crate::aliquota::CodiceAliquota;
use crate::riga::Pesata;

/// Testata del DDT con i dati già decisi da ATLAS (anagrafica cliente al momento dell'emissione).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Ddt {
    pub numero: u32,
    pub data: NaiveDate,
    pub cliente: String,
    pub destinazione: Option<String>,
    pub sede: Option<String>,
    pub pagamento: Option<String>,
    /// Listino del cliente (`DOTes.Cd_LS_1`).
    pub listino_cliente: Option<String>,
    pub iban: Option<String>,
    pub bic: Option<String>,
    pub conto_banca: Option<String>,
    pub agente: Option<String>,
    pub inizio_trasporto: Option<NaiveDateTime>,
    pub scissione_pagamenti: bool,
    /// Utente Arca registrato in `UserIns`/`UserUpd`.
    pub operatore: String,
    /// Istante di salvataggio, al minuto (`smalldatetime`).
    pub registrato_il: NaiveDateTime,
    pub righe: Vec<RigaDdt>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RigaDdt {
    pub articolo: String,
    pub descrizione: String,
    pub unita_misura: String,
    /// Conversione verso l'unità principale dell'articolo (`DORig.FattoreToUM1`).
    pub fattore_um1: Decimal,
    pub conto_ricavo: String,
    pub aliquota: CodiceAliquota,
    /// Riga di listino da cui viene il prezzo (`DORig.Id_LSArticolo`).
    pub id_listino_articolo: Option<i32>,
    pub pesata: Pesata,
    /// Quantità battuta a mano al posto di quella della pesata (BO 102363 riga 13: pesata
    /// 0,68 kg, quantità azzerata dall'operatore).
    pub quantita_forzata: Option<Decimal>,
    pub prezzo_unitario: Decimal,
    pub sconto_riga: String,
    pub sconto_addizionale: String,
    /// Magazzino di scarico; senza indicazione quello della causale.
    pub magazzino: Option<String>,
}

impl RigaDdt {
    /// Quantità della riga (`DORig.Qta`): quella battuta a mano, altrimenti il netto della pesata.
    pub fn quantita(&self) -> Decimal {
        self.quantita_forzata.unwrap_or_else(|| self.pesata.netto())
    }
}
