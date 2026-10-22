//! Arca finta per le prove dei worker: `Id_DoTes` → (`Ts`, documento o motivo di esclusione).

use std::collections::{BTreeMap, BTreeSet};

use atlas_arca::ErroreArca;
use atlas_arca::lettura::{Modificato, Testata};
use atlas_core::ddt::Ddt;
use atlas_core::numerazione::{Numeri, Sezionale};
use atlas_db::anagrafiche::Anagrafiche;
use atlas_db::prova;
use chrono::Datelike;

use crate::ErroreSync;
use crate::importazione::Origine;

/// Arca finta: `Id_DoTes` → (`Ts`, documento o motivo di esclusione).
pub(crate) struct Finta {
    pub database: String,
    pub documenti: BTreeMap<i32, (i64, Result<Ddt, &'static str>)>,
    prossimo_ts: i64,
    /// Cancellato in Arca subito dopo la lettura dei modificati.
    pub cancella_dopo_modificati: Option<i32>,
    /// Risposta ai numeri: errore di rete, o in ritardo di tanto.
    pub spenta: bool,
    pub ritardo: Option<std::time::Duration>,
    pub scollegata: usize,
}

impl Finta {
    pub fn nuova() -> Self {
        Self {
            database: "ADB_BOTTAMEDI_DEV".into(),
            documenti: BTreeMap::new(),
            prossimo_ts: 1000,
            cancella_dopo_modificati: None,
            spenta: false,
            ritardo: None,
            scollegata: 0,
        }
    }

    /// Scrive (o riscrive) un documento, come farebbe Arca: nuova rowversion.
    pub fn scrivi(&mut self, id: i32, documento: Result<Ddt, &'static str>) {
        self.prossimo_ts += 1;
        self.documenti.insert(id, (self.prossimo_ts, documento));
    }
}

impl Origine for Finta {
    async fn database(&mut self) -> Result<String, ErroreSync> {
        Ok(self.database.clone())
    }

    async fn modificati(&mut self, dopo: i64, limite: usize) -> Result<Vec<Modificato>, ErroreSync> {
        let mut modificati: Vec<Modificato> = self
            .documenti
            .iter()
            .filter(|(_, (ts, _))| *ts > dopo)
            .map(|(&id, (ts, documento))| Modificato {
                id_testata: id,
                tipo_documento: "BO".into(),
                ts: *ts,
                esercizio: 2026,
                numero: documento.as_ref().map_or(9999, |d| d.numero),
                data: documento.as_ref().map_or(prova::ddt(0).data, |d| d.data),
                escluso: documento.as_ref().err().copied(),
            })
            .collect();
        modificati.sort_by_key(|m| m.ts);
        modificati.truncate(limite);
        if let Some(id) = self.cancella_dopo_modificati.take() {
            self.documenti.remove(&id);
        }
        Ok(modificati)
    }

    async fn impronta(&mut self) -> Result<(i64, i64), ErroreSync> {
        Ok((self.documenti.len() as i64, self.documenti.keys().map(|&id| i64::from(id)).sum()))
    }

    async fn identita(&mut self) -> Result<BTreeSet<i32>, ErroreSync> {
        Ok(self.documenti.keys().copied().collect())
    }

    async fn carica(&mut self, id_testata: i32) -> Result<Ddt, ErroreArca> {
        match self.documenti.get(&id_testata) {
            Some((_, Ok(documento))) => Ok(documento.clone()),
            _ => Err(ErroreArca::DocumentoNonValido(format!("Id_DoTes {id_testata} inesistente"))),
        }
    }

    async fn anagrafiche(&mut self) -> Result<Anagrafiche, ErroreSync> {
        Ok(prova::anagrafiche())
    }

    async fn numeri(&mut self, _sezionale: Sezionale, esercizio: i32) -> Result<Numeri, ErroreSync> {
        if let Some(ritardo) = self.ritardo {
            tokio::time::sleep(ritardo).await;
        }
        if self.spenta {
            return Err(ErroreArca::Rete(std::io::ErrorKind::ConnectionRefused.into()).into());
        }
        Ok(self.bolle(esercizio).map(|(_, d)| (d.numero, d.data)).collect())
    }

    async fn con_numero(&mut self, _sezionale: Sezionale, esercizio: i32, numero: u32) -> Result<Option<Testata>, ErroreSync> {
        Ok(self.bolle(esercizio).find(|(_, d)| d.numero == numero).map(|(&id_testata, d)| Testata {
            id_testata,
            cliente: d.cliente.clone(),
            registrato_il: d.registrato_il,
        }))
    }

    fn scollega(&mut self) {
        self.scollegata += 1;
    }
}

impl Finta {
    fn bolle(&self, esercizio: i32) -> impl Iterator<Item = (&i32, &Ddt)> {
        self.documenti
            .iter()
            .filter_map(|(id, (_, documento))| documento.as_ref().ok().map(|d| (id, d)))
            .filter(move |(_, d)| d.data.year() == esercizio)
    }
}
