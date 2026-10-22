//! Confronto colonna per colonna fra un documento nativo e la sua replica, su tutte le colonne
//! delle cinque tabelle (anche calcolate e di default), escluse identità, chiavi esterne,
//! rowversion e numero documento.

use std::collections::BTreeMap;

use atlas_arca::ErroreArca;
use atlas_arca::scrittura::Connessione;
use tiberius::Row;

/// Tabella, query che restituisce le righe del documento `{id}` in ordine di confronto, colonne
/// escluse.
const TABELLE: [(&str, &str, &[&str]); 5] = [
    ("DOTes", "select * from DOTes where Id_DoTes = {id}", &["Id_DoTes", "Ts", "NumeroDoc", "NumeroDocI"]),
    (
        "DORig",
        "select * from DORig where Id_DOTes = {id} order by Riga, Id_DORig",
        &["Id_DORig", "Id_DOTes", "Ts", "NumeroDoc"],
    ),
    (
        "MGMov",
        "select row_number() over (order by r.Riga, r.Id_DORig) as Pos, m.* from DORig r \
         left join MGMov m on m.Id_DoRig = r.Id_DORig where r.Id_DOTes = {id} order by Pos",
        &["Pos", "Id_MGMov", "Id_DoRig", "Ts"],
    ),
    ("DOTotali", "select * from DOTotali where Id_DoTes = {id}", &["Id_DoTotali", "Id_DoTes", "Ts"]),
    (
        "DOIva",
        "select * from DOIva where Id_DOTes = {id} order by Cd_Aliquota",
        &["Id_DOIva", "Id_DOTes", "Ts"],
    ),
];

/// Colonne che Arca cambia dopo la creazione del BO, verificate sul 2026: evasione in fattura
/// differita (`QtaEvadibile` e derivate, 5.039 BO, tutti con righe richiamate da una FT),
/// chiusura manuale (`Evasa`, 42 BO senza FT), modifiche successive (`TimeUpd`, 923 BO; righe
/// aggiunte o corrette, `DORig.TimeIns`/`TimeUpd`, 417 e 861 BO). La replica riproduce il
/// documento al salvataggio, quindi qui può divergere dallo stato attuale del nativo.
const CICLO_DI_VITA: [(&str, &str); 9] = [
    ("DOTes", "RigheMerceEvadibili"),
    ("DOTes", "RigheEvadibili"),
    ("DOTes", "TimeUpd"),
    ("DORig", "QtaEvadibile"),
    ("DORig", "PrezzoResiduoV"),
    ("DORig", "PrezzoResiduoE"),
    ("DORig", "Evasa"),
    ("DORig", "TimeIns"),
    ("DORig", "TimeUpd"),
];

#[derive(Debug, Clone)]
pub struct Differenza {
    pub tabella: &'static str,
    pub colonna: String,
    pub riga: usize,
    pub nativo: String,
    pub replica: String,
}

impl Differenza {
    pub fn ciclo_di_vita(&self) -> bool {
        CICLO_DI_VITA.contains(&(self.tabella, self.colonna.as_str()))
    }
}

/// Esito di un confronto: colonne confrontate e differenze trovate.
#[derive(Debug, Default)]
pub struct Esito {
    pub colonne: usize,
    pub differenze: Vec<Differenza>,
}

async fn righe(conn: &mut Connessione, modello: &str, id: i32) -> Result<Vec<Row>, ErroreArca> {
    Ok(conn
        .simple_query(modello.replace("{id}", &id.to_string()))
        .await?
        .into_first_result()
        .await?)
}

fn celle(row: &Row) -> Vec<(String, String)> {
    row.cells().map(|(c, v)| (c.name().to_owned(), format!("{v:?}"))).collect()
}

/// Arca chiude il salvataggio aggiornando la testata (`asp_Do_End`): il suo `Ts` supera quello
/// di righe, movimenti, totali e IVA in tutti i 6.584 documenti nativi del 2026. L'importazione
/// in ATLAS cerca i documenti cambiati solo su `DOTes.Ts`.
async fn testata_per_ultima(conn: &mut Connessione, id: i32) -> Result<String, ErroreArca> {
    let sql = format!(
        "select case when t.Ts > isnull((select max(u.Ts) from (            select Ts from DORig where Id_DOTes = t.Id_DoTes            union all select m.Ts from MGMov m join DORig r on r.Id_DORig = m.Id_DoRig where r.Id_DOTes = t.Id_DoTes            union all select Ts from DOTotali where Id_DoTes = t.Id_DoTes            union all select Ts from DOIva where Id_DOTes = t.Id_DoTes) u), 0x00) then 'sì' else 'no' end as Ultima          from DOTes t where t.Id_DoTes = {id}"
    );
    let row = conn.simple_query(sql).await?.into_row().await?;
    Ok(row
        .and_then(|r| r.try_get::<&str, _>("Ultima").ok().flatten().map(str::to_owned))
        .unwrap_or_default())
}

pub async fn confronta(conn: &mut Connessione, nativo: i32, replica: i32) -> Result<Esito, ErroreArca> {
    let mut esito = Esito::default();
    let (a, b) = (testata_per_ultima(conn, nativo).await?, testata_per_ultima(conn, replica).await?);
    esito.colonne += 1;
    if a != b {
        esito.differenze.push(Differenza {
            tabella: "DOTes",
            colonna: "(testata scritta per ultima)".into(),
            riga: 1,
            nativo: a,
            replica: b,
        });
    }
    for (tabella, modello, escluse) in TABELLE {
        let a = righe(conn, modello, nativo).await?;
        let b = righe(conn, modello, replica).await?;
        if a.len() != b.len() {
            esito.differenze.push(Differenza {
                tabella,
                colonna: "(numero di righe)".into(),
                riga: 0,
                nativo: a.len().to_string(),
                replica: b.len().to_string(),
            });
        }
        for (riga, (ra, rb)) in a.iter().zip(&b).enumerate() {
            for ((colonna, va), (_, vb)) in celle(ra).into_iter().zip(celle(rb)) {
                if escluse.contains(&colonna.as_str()) {
                    continue;
                }
                esito.colonne += 1;
                if va != vb {
                    esito.differenze.push(Differenza {
                        tabella,
                        colonna,
                        riga: riga + 1,
                        nativo: va,
                        replica: vb,
                    });
                }
            }
        }
    }
    Ok(esito)
}

/// Differenze aggregate su molti documenti: per tabella e colonna, quanti documenti e il primo
/// esempio.
#[derive(Debug, Default)]
pub struct Riepilogo {
    pub documenti: usize,
    pub identici: usize,
    /// Identici a meno delle sole colonne di ciclo di vita.
    pub identici_alla_creazione: usize,
    pub colonne: usize,
    pub per_colonna: BTreeMap<(&'static str, String), (usize, i32, Differenza)>,
}

impl Riepilogo {
    pub fn aggiungi(&mut self, nativo: i32, esito: Esito) {
        self.documenti += 1;
        self.colonne += esito.colonne;
        if esito.differenze.is_empty() {
            self.identici += 1;
        }
        if esito.differenze.iter().all(Differenza::ciclo_di_vita) {
            self.identici_alla_creazione += 1;
        }
        let mut viste = std::collections::BTreeSet::new();
        for d in esito.differenze {
            let chiave = (d.tabella, d.colonna.clone());
            if !viste.insert(chiave.clone()) {
                continue;
            }
            self.per_colonna.entry(chiave).and_modify(|(n, _, _)| *n += 1).or_insert((1, nativo, d));
        }
    }

    pub fn testo(&self) -> String {
        let mut s = format!(
            "Documenti rigiocati: {}\nIdentici in ogni colonna: {}\nIdentici a meno del ciclo di vita: {}\nValori confrontati: {}\n",
            self.documenti, self.identici, self.identici_alla_creazione, self.colonne
        );
        if !self.per_colonna.is_empty() {
            s.push_str("\nColonne con differenze (documenti, primo esempio):\n");
            for ((tabella, colonna), (n, id, d)) in &self.per_colonna {
                let ciclo = if d.ciclo_di_vita() { " [ciclo di vita]" } else { "" };
                s.push_str(&format!(
                    "  {tabella}.{colonna}{ciclo}: {n} doc — Id_DoTes {id} riga {}: nativo {} / replica {}\n",
                    d.riga, d.nativo, d.replica
                ));
            }
        }
        s
    }
}
