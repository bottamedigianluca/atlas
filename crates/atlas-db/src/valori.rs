//! Conversioni tra i tipi del motore e le colonne SQLite.

use std::str::FromStr;

use rusqlite::types::{FromSql, FromSqlError, FromSqlResult, ToSql, ToSqlOutput, ValueRef};
use rust_decimal::Decimal;

/// Decimale registrato come testo esatto, con la sua scala (`"1.50"` resta `1.50`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Dec(pub Decimal);

impl ToSql for Dec {
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(self.0.to_string()))
    }
}

impl FromSql for Dec {
    fn column_result(valore: ValueRef<'_>) -> FromSqlResult<Self> {
        let testo = valore.as_str()?;
        Decimal::from_str(testo)
            .map(Dec)
            .map_err(|e| FromSqlError::Other(Box::new(e)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rust_decimal_macros::dec;

    #[test]
    fn decimale_conserva_valore_e_scala() {
        let conn = rusqlite::Connection::open_in_memory().unwrap();
        for d in [dec!(1.50), dec!(-0.0199), dec!(999999999.999999), dec!(0)] {
            let letto: Dec = conn.query_row("select ?1", [Dec(d)], |r| r.get(0)).unwrap();
            assert_eq!(letto.0, d);
            assert_eq!(letto.0.scale(), d.scale());
        }
    }

    #[test]
    fn decimale_rifiuta_testo_non_numerico() {
        let conn = rusqlite::Connection::open_in_memory().unwrap();
        assert!(conn.query_row("select 'abc'", [], |r| r.get::<_, Dec>(0)).is_err());
    }
}
