//! Lettura dello storico Arca Evolution. Solo SELECT: l'utente di connessione deve essere
//! in sola lettura (`bihortus_reader`).

use std::collections::{BTreeMap, HashMap};

use atlas_core::aliquota::{CodiceAliquota, TabellaAliquote};
use atlas_core::numerazione::TipoDocumento;
use atlas_core::pagamento::{CondizionePagamento, Partenza, Rata, TipoRata};
use chrono::{NaiveDate, NaiveDateTime};
use rust_decimal::Decimal;
use tiberius::{Client, Config, Row};
use tokio::net::TcpStream;
use tokio_util::compat::{Compat, TokioAsyncWriteCompatExt};

use crate::ErroreVerifica;

pub type Connessione = Client<Compat<TcpStream>>;

pub async fn connetti(ado: &str) -> Result<Connessione, ErroreVerifica> {
    let config = Config::from_ado_string(ado)?;
    let tcp = TcpStream::connect(config.get_addr()).await?;
    tcp.set_nodelay(true)?;
    Ok(Client::connect(config, tcp.compat_write()).await?)
}

#[derive(Debug)]
pub struct Testata {
    pub tipo: TipoDocumento,
    pub numero: u32,
    pub data: NaiveDate,
    pub cliente: String,
    pub pagamento: Option<String>,
    pub scissione_pagamenti: bool,
}

#[derive(Debug)]
pub struct Riga {
    pub id: i32,
    pub articolo: Option<String>,
    pub descrizione: String,
    pub colli: Option<Decimal>,
    pub lordo: Option<Decimal>,
    pub tara: Option<Decimal>,
    pub qta: Decimal,
    pub prezzo: Decimal,
    pub addizionale: Decimal,
    pub sconto_riga: String,
    pub sconto_addizionale: String,
    pub fattore_sconto: Decimal,
    pub totale: Decimal,
    pub aliquota: Option<CodiceAliquota>,
    pub evade: Option<i32>,
}

#[derive(Debug)]
pub struct Spesa {
    pub aliquota: Option<CodiceAliquota>,
    pub importo: Decimal,
}

#[derive(Debug)]
pub struct RigaIvaArca {
    pub aliquota: CodiceAliquota,
    pub imponibile: Decimal,
    pub imposta: Decimal,
}

#[derive(Debug, Default)]
pub struct Totali {
    pub imponibile: Decimal,
    pub imposta: Decimal,
    pub documento: Decimal,
    pub acconto: Decimal,
    pub abbuono: Decimal,
    pub da_pagare: Decimal,
}

#[derive(Debug)]
pub struct ScadenzaArca {
    pub data: NaiveDate,
    pub importo: Decimal,
}

#[derive(Debug)]
pub struct Documento {
    pub testata: Testata,
    pub righe: Vec<Riga>,
    pub spese: Vec<Spesa>,
    pub iva: Vec<RigaIvaArca>,
    pub totali: Option<Totali>,
    pub scadenze: Vec<ScadenzaArca>,
}

#[derive(Debug)]
pub struct Storico {
    pub aliquote: TabellaAliquote,
    pub pagamenti: HashMap<String, CondizionePagamento>,
    pub documenti: BTreeMap<i32, Documento>,
    /// Testate dei DDT richiamati dalle righe di fattura, indicizzate per riga DDT.
    pub ddt_per_riga: HashMap<i32, (i32, Testata)>,
}

fn testo(row: &Row, colonna: &str) -> Result<Option<String>, ErroreVerifica> {
    Ok(row.try_get::<&str, _>(colonna)?.map(|s| s.trim().to_owned()))
}

fn decimale(row: &Row, colonna: &str) -> Result<Option<Decimal>, ErroreVerifica> {
    Ok(row.try_get::<Decimal, _>(colonna)?.map(|d| d.normalize()))
}

fn decimale_o_zero(row: &Row, colonna: &str) -> Result<Decimal, ErroreVerifica> {
    Ok(decimale(row, colonna)?.unwrap_or_default())
}

fn obbligatorio<T>(valore: Option<T>, colonna: &'static str) -> Result<T, ErroreVerifica> {
    valore.ok_or(ErroreVerifica::ColonnaVuota(colonna))
}

fn data(row: &Row, colonna: &'static str) -> Result<NaiveDate, ErroreVerifica> {
    Ok(obbligatorio(row.try_get::<NaiveDateTime, _>(colonna)?, colonna)?.date())
}

fn intero(row: &Row, colonna: &'static str) -> Result<i32, ErroreVerifica> {
    obbligatorio(row.try_get::<i32, _>(colonna)?, colonna)
}

fn testata(row: &Row) -> Result<Testata, ErroreVerifica> {
    let codice = obbligatorio(testo(row, "Cd_Do")?, "Cd_Do")?;
    Ok(Testata {
        tipo: codice.parse()?,
        numero: u32::try_from(intero(row, "NumeroDocI")?).map_err(|_| ErroreVerifica::ColonnaVuota("NumeroDocI"))?,
        data: data(row, "DataDoc")?,
        cliente: testo(row, "Cd_CF")?.unwrap_or_default(),
        pagamento: testo(row, "Cd_PG")?,
        scissione_pagamenti: row.try_get::<bool, _>("IvaSplit")?.unwrap_or_default(),
    })
}

async fn righe_query(conn: &mut Connessione, sql: &str) -> Result<Vec<Row>, ErroreVerifica> {
    Ok(conn.simple_query(sql).await?.into_first_result().await?)
}

pub async fn carica(conn: &mut Connessione, dal: NaiveDate, al: NaiveDate) -> Result<Storico, ErroreVerifica> {
    let filtro = format!(
        "t.Cd_Do in ('BO','FA','FT','NC') and t.DataDoc between '{}' and '{}'",
        dal.format("%Y%m%d"),
        al.format("%Y%m%d")
    );

    let mut aliquote = TabellaAliquote::new();
    for row in righe_query(conn, "select Cd_Aliquota, Aliquota from Aliquota").await? {
        let codice = obbligatorio(testo(&row, "Cd_Aliquota")?, "Cd_Aliquota")?;
        aliquote.inserisci(CodiceAliquota::nuovo(&codice), decimale_o_zero(&row, "Aliquota")?);
    }

    let mut pagamenti: HashMap<String, CondizionePagamento> = HashMap::new();
    let sql_pg = "select p.Cd_PG, p.Partenza, r.TipoRata, r.Giorni, r.Imponibile, r.Imposta, r.Spese, r.Cd_Aliquota_Spese \
                  from PG p join PGRata r on r.Cd_PG = p.Cd_PG order by p.Cd_PG, r.Id_PGRata";
    for row in righe_query(conn, sql_pg).await? {
        let codice = obbligatorio(testo(&row, "Cd_PG")?, "Cd_PG")?;
        let partenza = match row.try_get::<u8, _>("Partenza")? {
            Some(1) => Partenza::DataDocumento,
            Some(2) => Partenza::FineMese,
            altro => return Err(ErroreVerifica::NonGestito(format!("PG {codice}: Partenza {altro:?}"))),
        };
        let tipo = match testo(&row, "TipoRata")?.as_deref() {
            Some("D") => TipoRata::RimessaDiretta,
            Some("B") => TipoRata::Bonifico,
            Some("R") => TipoRata::RicevutaBancaria,
            Some("C") => TipoRata::Contrassegno,
            Some("L") => TipoRata::BollettinoPostale,
            altro => return Err(ErroreVerifica::NonGestito(format!("PG {codice}: TipoRata {altro:?}"))),
        };
        let giorni = row.try_get::<i16, _>("Giorni")?.unwrap_or_default();
        let rata = Rata {
            tipo,
            giorni: u16::try_from(giorni).map_err(|_| ErroreVerifica::NonGestito(format!("PG {codice}: giorni {giorni}")))?,
            quota_imponibile: decimale_o_zero(&row, "Imponibile")?,
            quota_imposta: decimale_o_zero(&row, "Imposta")?,
            spese: decimale_o_zero(&row, "Spese")?,
            aliquota_spese: testo(&row, "Cd_Aliquota_Spese")?.map(|c| CodiceAliquota::nuovo(&c)),
        };
        pagamenti
            .entry(codice.clone())
            .or_insert_with(|| CondizionePagamento {
                codice,
                partenza,
                rate: Vec::new(),
            })
            .rate
            .push(rata);
    }

    let mut documenti = BTreeMap::new();
    let sql = format!(
        "select t.Id_DoTes, t.Cd_Do, t.NumeroDocI, t.DataDoc, t.Cd_CF, t.Cd_PG, t.IvaSplit from DOTes t where {filtro}"
    );
    for row in righe_query(conn, &sql).await? {
        documenti.insert(
            intero(&row, "Id_DoTes")?,
            Documento {
                testata: testata(&row)?,
                righe: Vec::new(),
                spese: Vec::new(),
                iva: Vec::new(),
                totali: None,
                scadenze: Vec::new(),
            },
        );
    }

    let sql = format!(
        "select r.Id_DoTes, r.Id_DORig, r.Cd_AR, r.Descrizione, r.xColli, r.xLordo, r.xTara, r.Qta, \
         r.PrezzoUnitarioV, r.PrezzoAddizionaleV, r.ScontoRiga, r.ScontoAddizionale, r.FattoreScontoTotale, \
         r.PrezzoTotaleV, r.Cd_Aliquota, r.Id_DORig_Evade \
         from DORig r join DOTes t on t.Id_DoTes = r.Id_DoTes where {filtro} order by r.Id_DoTes, r.Riga"
    );
    for row in righe_query(conn, &sql).await? {
        let Some(doc) = documenti.get_mut(&intero(&row, "Id_DoTes")?) else { continue };
        doc.righe.push(Riga {
            id: intero(&row, "Id_DORig")?,
            articolo: testo(&row, "Cd_AR")?,
            descrizione: testo(&row, "Descrizione")?.unwrap_or_default(),
            colli: decimale(&row, "xColli")?,
            lordo: decimale(&row, "xLordo")?,
            tara: decimale(&row, "xTara")?,
            qta: decimale_o_zero(&row, "Qta")?,
            prezzo: decimale_o_zero(&row, "PrezzoUnitarioV")?,
            addizionale: decimale_o_zero(&row, "PrezzoAddizionaleV")?,
            sconto_riga: testo(&row, "ScontoRiga")?.unwrap_or_default(),
            sconto_addizionale: testo(&row, "ScontoAddizionale")?.unwrap_or_default(),
            fattore_sconto: decimale_o_zero(&row, "FattoreScontoTotale")?,
            totale: decimale_o_zero(&row, "PrezzoTotaleV")?,
            aliquota: testo(&row, "Cd_Aliquota")?.map(|c| CodiceAliquota::nuovo(&c)),
            evade: row.try_get::<i32, _>("Id_DORig_Evade")?,
        });
    }

    let sql = format!(
        "select s.Id_DoTes, s.Cd_Aliquota, s.ImportoV from DORigSpesa s join DOTes t on t.Id_DoTes = s.Id_DoTes where {filtro}"
    );
    for row in righe_query(conn, &sql).await? {
        let Some(doc) = documenti.get_mut(&intero(&row, "Id_DoTes")?) else { continue };
        doc.spese.push(Spesa {
            aliquota: testo(&row, "Cd_Aliquota")?.map(|c| CodiceAliquota::nuovo(&c)),
            importo: decimale_o_zero(&row, "ImportoV")?,
        });
    }

    let sql = format!(
        "select i.Id_DOTes, i.Cd_Aliquota, i.ImponibileV, i.ImpostaV from DOIva i join DOTes t on t.Id_DoTes = i.Id_DOTes where {filtro}"
    );
    for row in righe_query(conn, &sql).await? {
        let Some(doc) = documenti.get_mut(&intero(&row, "Id_DOTes")?) else { continue };
        doc.iva.push(RigaIvaArca {
            aliquota: CodiceAliquota::nuovo(&obbligatorio(testo(&row, "Cd_Aliquota")?, "Cd_Aliquota")?),
            imponibile: decimale_o_zero(&row, "ImponibileV")?,
            imposta: decimale_o_zero(&row, "ImpostaV")?,
        });
    }

    let sql = format!(
        "select x.Id_DoTes, x.TotImponibileV, x.TotImpostaV, x.TotDocumentoV, x.AccontoV, x.AbbuonoV, x.TotaPagareV \
         from DOTotali x join DOTes t on t.Id_DoTes = x.Id_DoTes where {filtro}"
    );
    for row in righe_query(conn, &sql).await? {
        let Some(doc) = documenti.get_mut(&intero(&row, "Id_DoTes")?) else { continue };
        doc.totali = Some(Totali {
            imponibile: decimale_o_zero(&row, "TotImponibileV")?,
            imposta: decimale_o_zero(&row, "TotImpostaV")?,
            documento: decimale_o_zero(&row, "TotDocumentoV")?,
            acconto: decimale_o_zero(&row, "AccontoV")?,
            abbuono: decimale_o_zero(&row, "AbbuonoV")?,
            da_pagare: decimale_o_zero(&row, "TotaPagareV")?,
        });
    }

    let sql = format!(
        "select s.Id_DOTes, s.DataScadenza, s.ImportoV from SC s join DOTes t on t.Id_DoTes = s.Id_DOTes \
         where {filtro} order by s.Id_DOTes, s.DataScadenza, s.Id_SC"
    );
    for row in righe_query(conn, &sql).await? {
        let Some(doc) = documenti.get_mut(&intero(&row, "Id_DOTes")?) else { continue };
        doc.scadenze.push(ScadenzaArca {
            data: data(&row, "DataScadenza")?,
            importo: decimale_o_zero(&row, "ImportoV")?,
        });
    }

    let mut ddt_per_riga = HashMap::new();
    let sql = format!(
        "select b.Id_DORig, bt.Id_DoTes, bt.Cd_Do, bt.NumeroDocI, bt.DataDoc, bt.Cd_CF, bt.Cd_PG, bt.IvaSplit \
         from DORig r join DOTes t on t.Id_DoTes = r.Id_DoTes \
         join DORig b on b.Id_DORig = r.Id_DORig_Evade join DOTes bt on bt.Id_DoTes = b.Id_DoTes \
         where t.Cd_Do = 'FT' and {filtro}"
    );
    for row in righe_query(conn, &sql).await? {
        ddt_per_riga.insert(intero(&row, "Id_DORig")?, (intero(&row, "Id_DoTes")?, testata(&row)?));
    }

    Ok(Storico {
        aliquote,
        pagamenti,
        documenti,
        ddt_per_riga,
    })
}
