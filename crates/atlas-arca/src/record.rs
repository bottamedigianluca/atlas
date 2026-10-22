//! Riga di una tabella di Arca: colonne e valori, nell'ordine di scrittura.

use chrono::NaiveDateTime;
use rust_decimal::Decimal;
use tiberius::Query;
use tiberius::numeric::Numeric;

/// Valore di colonna. I tipi seguono quelli di SQL Server; le conversioni implicite
/// (`nvarchar` → `char`/`xml`, `datetime2` → `smalldatetime`) sono quelle di SQL Server.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Valore {
    Testo(Option<String>),
    Intero(Option<i32>),
    Piccolo(i16),
    Byte(u8),
    Decimale(Decimal),
    Bit(bool),
    DataOra(Option<NaiveDateTime>),
}

impl Valore {
    pub fn testo(valore: &str) -> Self {
        Self::Testo(Some(valore.to_owned()))
    }

    pub fn testo_opz(valore: Option<&str>) -> Self {
        Self::Testo(valore.map(str::to_owned))
    }
}

/// Le colonne non elencate prendono il default della tabella: il confronto con i documenti
/// nativi (`prova-ddt rigioca`) controlla anche quelle.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Record {
    pub tabella: &'static str,
    pub colonne: Vec<(&'static str, Valore)>,
}

impl Record {
    pub fn nuovo(tabella: &'static str) -> Self {
        Self { tabella, colonne: Vec::new() }
    }

    pub fn con(mut self, colonna: &'static str, valore: Valore) -> Self {
        self.colonne.push((colonna, valore));
        self
    }

    pub fn valore(&self, colonna: &str) -> Option<&Valore> {
        self.colonne.iter().find(|(c, _)| *c == colonna).map(|(_, v)| v)
    }

    /// `INSERT` parametrico che restituisce l'identità generata (`SCOPE_IDENTITY`: vale anche
    /// sulle tabelle con trigger attivi, dove `OUTPUT` senza `INTO` non è ammesso).
    pub fn insert(&self) -> Query<'static> {
        let colonne: Vec<String> = self.colonne.iter().map(|(c, _)| format!("[{c}]")).collect();
        let parametri: Vec<String> = (1..=self.colonne.len()).map(|i| format!("@P{i}")).collect();
        let sql = format!(
            "INSERT INTO [{}] ({}) VALUES ({}); SELECT CAST(SCOPE_IDENTITY() AS int) AS Id",
            self.tabella,
            colonne.join(", "),
            parametri.join(", ")
        );
        let mut query = Query::new(sql);
        for (_, valore) in &self.colonne {
            match valore.clone() {
                Valore::Testo(v) => query.bind(v),
                Valore::Intero(v) => query.bind(v),
                Valore::Piccolo(v) => query.bind(v),
                Valore::Byte(v) => query.bind(v),
                // La scala di `Decimal` non supera 28: la conversione è senza perdita.
                Valore::Decimale(v) => query.bind(Numeric::new_with_scale(v.mantissa(), v.scale() as u8)),
                Valore::Bit(v) => query.bind(v),
                Valore::DataOra(v) => query.bind(v),
            }
        }
        query
    }
}
