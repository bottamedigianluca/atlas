//! La Home della postazione: quanti documenti e anagrafiche ci sono (i riquadri familiari di Arca)
//! e i clienti che di solito ordinano nel giorno della settimana, già serviti o da chiamare. Solo
//! conteggi e orari, nessun importo (direttiva §4.3: al banco nessun dato di fatturato).

use std::collections::HashMap;

use chrono::{Datelike, NaiveDate, Weekday};
use rusqlite::Connection;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use crate::errore::ErroreApi;

/// Quante settimane indietro si guarda: tre mesi di abitudini, senza la stagione passata.
pub const SETTIMANE: u32 = 12;

/// Un cliente è "del giorno" se ha ordinato almeno in metà dei giorni lavorati uguali e almeno 3 volte.
const MINIMO_VOLTE: u32 = 3;

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(deny_unknown_fields)]
pub struct RichiestaGiorno {
    /// Il giorno (predefinito oggi).
    #[serde(default)]
    pub data: Option<NaiveDate>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ServitoOggi {
    pub id: i64,
    pub numero: u32,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ClienteDelGiorno {
    pub cliente: String,
    pub ragione_sociale: String,
    pub localita: Option<String>,
    /// In quanti degli stessi giorni della settimana ha avuto un DDT…
    pub volte: u32,
    /// …su quanti giorni lavorati (con almeno un DDT di qualcuno).
    pub su: u32,
    /// Ultimo DDT in uno di quei giorni.
    pub ultimo: NaiveDate,
    /// Ora mediana di registrazione dei suoi DDT in quei giorni ("09:10"), se registrati in giornata.
    pub ora_tipica: Option<String>,
    /// Destinazione più frequente in quei giorni.
    pub destinazione: Option<String>,
    /// Il DDT del giorno, se c'è già.
    pub servito: Option<ServitoOggi>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ClientiDelGiorno {
    pub data: NaiveDate,
    pub giorno: &'static str,
    pub settimane: u32,
    pub giorni_lavorati: u32,
    /// Da servire prima, in ordine di ora tipica; poi quelli già serviti.
    pub clienti: Vec<ClienteDelGiorno>,
}

pub fn nome_giorno(giorno: Weekday) -> &'static str {
    match giorno {
        Weekday::Mon => "lunedì",
        Weekday::Tue => "martedì",
        Weekday::Wed => "mercoledì",
        Weekday::Thu => "giovedì",
        Weekday::Fri => "venerdì",
        Weekday::Sat => "sabato",
        Weekday::Sun => "domenica",
    }
}

/// I giorni uguali al giorno dato nelle settimane prima (lo stesso giorno della settimana).
const GIORNI: &str = "WITH giorni AS ( \
     SELECT DISTINCT data FROM ddt \
     WHERE data < ?1 AND data >= date(?1, ?2) AND strftime('%w', data) = strftime('%w', ?1))";

pub fn clienti_del_giorno(conn: &Connection, data: NaiveDate) -> Result<ClientiDelGiorno, ErroreApi> {
    let indietro = format!("-{} days", SETTIMANE * 7);
    let giorni_lavorati: u32 = conn
        .prepare_cached(&format!("{GIORNI} SELECT count(*) FROM giorni"))?
        .query_row(rusqlite::params![data, indietro], |r| r.get(0))?;
    let soglia = MINIMO_VOLTE.max(giorni_lavorati.div_ceil(2));

    let mut clienti: Vec<ClienteDelGiorno> = conn
        .prepare_cached(&format!(
            "{GIORNI}, abituali AS ( \
               SELECT d.cliente, count(DISTINCT d.data) AS volte, max(d.data) AS ultimo \
               FROM ddt d JOIN giorni g ON g.data = d.data GROUP BY d.cliente) \
             SELECT a.cliente, cf.ragione_sociale, cf.localita, a.volte, a.ultimo, \
               (SELECT d.destinazione FROM ddt d JOIN giorni g ON g.data = d.data \
                WHERE d.cliente = a.cliente AND d.destinazione IS NOT NULL \
                GROUP BY d.destinazione ORDER BY count(*) DESC, d.destinazione LIMIT 1), \
               (SELECT d.id FROM ddt d WHERE d.cliente = a.cliente AND d.data = ?1 ORDER BY d.numero LIMIT 1), \
               (SELECT d.numero FROM ddt d WHERE d.cliente = a.cliente AND d.data = ?1 ORDER BY d.numero LIMIT 1) \
             FROM abituali a JOIN clienti_fornitori cf ON cf.codice = a.cliente \
             WHERE a.volte >= ?3"
        ))?
        .query_map(rusqlite::params![data, indietro, soglia], |r| {
            let id: Option<i64> = r.get(6)?;
            let numero: Option<u32> = r.get(7)?;
            Ok(ClienteDelGiorno {
                cliente: r.get(0)?,
                ragione_sociale: r.get(1)?,
                localita: r.get(2)?,
                volte: r.get(3)?,
                su: giorni_lavorati,
                ultimo: r.get(4)?,
                ora_tipica: None,
                destinazione: r.get(5)?,
                servito: id.zip(numero).map(|(id, numero)| ServitoOggi { id, numero }),
            })
        })?
        .collect::<Result<_, _>>()?;

    // Ora tipica: la mediana delle ore di registrazione dei DDT registrati il giorno stesso (quelli
    // preparati la sera prima non dicono quando il cliente ordina).
    let mut ore: HashMap<String, Vec<String>> = HashMap::new();
    let mut q = conn.prepare_cached(&format!(
        "{GIORNI} SELECT d.cliente, substr(d.registrato_il, 12, 5) FROM ddt d JOIN giorni g ON g.data = d.data \
         WHERE substr(d.registrato_il, 1, 10) = d.data"
    ))?;
    let mut righe = q.query(rusqlite::params![data, indietro])?;
    while let Some(r) = righe.next()? {
        ore.entry(r.get::<_, String>(0)?.to_uppercase()).or_default().push(r.get(1)?);
    }
    for c in &mut clienti {
        if let Some(lista) = ore.get_mut(&c.cliente.to_uppercase()) {
            lista.sort();
            c.ora_tipica = lista.get(lista.len() / 2).cloned();
        }
    }

    clienti.sort_by(|a, b| {
        a.servito
            .is_some()
            .cmp(&b.servito.is_some())
            .then_with(|| a.ora_tipica.as_deref().unwrap_or("99").cmp(b.ora_tipica.as_deref().unwrap_or("99")))
            .then_with(|| b.volte.cmp(&a.volte))
            .then_with(|| a.ragione_sociale.cmp(&b.ragione_sociale))
    });
    Ok(ClientiDelGiorno {
        data,
        giorno: nome_giorno(data.weekday()),
        settimane: SETTIMANE,
        giorni_lavorati,
        clienti,
    })
}

/// Paesi dell'Unione europea oltre all'Italia (codici ISO di `CF.Cd_Nazione`).
const UE: [&str; 26] = [
    "AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "ES", "FI", "FR", "GR", "HR", "HU", "IE", "LT", "LU", "LV", "MT", "NL",
    "PL", "PT", "RO", "SE", "SI", "SK",
];

/// Anagrafiche per area, come gli anelli di Arca (Italia, UE, Extra UE). Senza nazione = Italia.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize)]
pub struct PerArea {
    pub totale: u32,
    pub italia: u32,
    pub ue: u32,
    pub extra_ue: u32,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Riepilogo {
    /// DDT di vendita nel database (tutti gli anni), come la casella "Bolla" di Arca.
    pub bolle: u32,
    pub clienti: PerArea,
    pub fornitori: PerArea,
}

pub fn riepilogo(conn: &Connection) -> Result<Riepilogo, ErroreApi> {
    let bolle = conn.prepare_cached("SELECT count(*) FROM ddt")?.query_row([], |r| r.get(0))?;
    let mut clienti = PerArea::default();
    let mut fornitori = PerArea::default();
    let mut q = conn.prepare_cached(
        "SELECT upper(coalesce(nullif(trim(nazione), ''), 'IT')), cliente, fornitore, count(*) FROM clienti_fornitori \
         WHERE obsoleto = 0 GROUP BY 1, 2, 3",
    )?;
    let mut righe = q.query([])?;
    while let Some(r) = righe.next()? {
        let nazione: String = r.get(0)?;
        let (cliente, fornitore, quanti): (bool, bool, u32) = (r.get(1)?, r.get(2)?, r.get(3)?);
        for (vale, area) in [(cliente, &mut clienti), (fornitore, &mut fornitori)] {
            if !vale {
                continue;
            }
            area.totale += quanti;
            match nazione.as_str() {
                "IT" => area.italia += quanti,
                n if UE.contains(&n) => area.ue += quanti,
                _ => area.extra_ue += quanti,
            }
        }
    }
    Ok(Riepilogo { bolle, clienti, fornitori })
}

#[cfg(test)]
mod tests {
    use super::*;
    use atlas_db::ddt::salva;
    use atlas_db::prova::{adesso, database, ddt};
    use chrono::{Duration, NaiveDateTime};

    fn giovedi(settimane_fa: i64) -> NaiveDate {
        NaiveDate::from_ymd_opt(2026, 10, 22).unwrap() - Duration::weeks(settimane_fa)
    }

    fn salva_il(conn: &mut Connection, numero: u32, data: NaiveDate, cliente: &str, registrato: NaiveDateTime) {
        let mut d = ddt(numero);
        d.data = data;
        d.cliente = cliente.into();
        d.registrato_il = registrato;
        if cliente != "C000380" {
            d.destinazione = None;
        }
        salva(conn, &d, adesso()).unwrap();
    }

    #[test]
    fn clienti_abituali_del_giovedi_serviti_e_da_chiamare() {
        let mut conn = database();
        let mut numero = 1;
        // C000380 ogni giovedì da 6 settimane verso le 9; C000002 due giovedì su sei (non abituale).
        for s in 1..=6 {
            let data = giovedi(s);
            salva_il(&mut conn, numero, data, "C000380", data.and_hms_opt(9, s as u32, 0).unwrap());
            numero += 1;
            if s <= 2 {
                salva_il(&mut conn, numero, data, "C000002", data.and_hms_opt(14, 0, 0).unwrap());
                numero += 1;
            }
        }
        // Un mercoledì non conta.
        salva_il(&mut conn, numero, giovedi(1) - Duration::days(1), "C000002", giovedi(1).and_hms_opt(8, 0, 0).unwrap());

        let oggi = clienti_del_giorno(&conn, giovedi(0)).unwrap();
        assert_eq!((oggi.giorno, oggi.giorni_lavorati), ("giovedì", 6));
        assert_eq!(oggi.clienti.len(), 1);
        let c = &oggi.clienti[0];
        assert_eq!((c.cliente.as_str(), c.volte, c.su, c.ultimo), ("C000380", 6, 6, giovedi(1)));
        assert_eq!(c.ora_tipica.as_deref(), Some("09:04"));
        assert_eq!(c.servito, None);

        // Servito oggi: resta in elenco, con il DDT.
        salva_il(&mut conn, 100, giovedi(0), "C000380", giovedi(0).and_hms_opt(8, 30, 0).unwrap());
        let oggi = clienti_del_giorno(&conn, giovedi(0)).unwrap();
        assert_eq!(oggi.clienti[0].servito.as_ref().map(|s| s.numero), Some(100));

        let r = riepilogo(&conn).unwrap();
        assert_eq!(r.bolle, 10);
        assert!(r.clienti.totale > 0);
        assert_eq!(r.clienti.totale, r.clienti.italia + r.clienti.ue + r.clienti.extra_ue);
    }
}
