//! Parametri di Arca che determinano le colonne del documento, letti dalle tabelle di
//! configurazione (`DO`, `MGCausale`, `VL`, `Aliquota`) e non scritti nel codice.

use atlas_core::aliquota::{CodiceAliquota, TabellaAliquote};
use rust_decimal::Decimal;
use tiberius::Row;

use crate::ErroreArca;
use crate::scrittura::Connessione;

/// Tipo documento (`DO`), per esempio `BO`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TipoDocumentoArca {
    pub codice: String,
    /// `DO.TipoDocumento`: `B` bolla.
    pub tipo: String,
    pub bitmask: i32,
    pub cli_for: String,
    /// Sezionale di numerazione (`DO.Cd_CN`).
    pub sezionale: String,
    pub causale_magazzino: String,
    pub aspetto_beni: Option<String>,
    pub trasporto: Option<String>,
    pub spedizione: Option<String>,
    pub porto: Option<String>,
    /// `DO.Cd_LS_1`, che Arca registra come listino del documento (`DOTes.Cd_LS_2`).
    pub listino: Option<String>,
    pub esecutivo: bool,
    pub prelevabile: bool,
    pub modificabile: bool,
}

/// Causale di magazzino (`MGCausale`), lato partenza.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CausaleMagazzino {
    pub partenza: bool,
    pub arrivo: bool,
    pub magazzino_partenza: Option<String>,
    /// `MGCausale.Id_MGMovDes_PP`, descrizione del movimento (`MGMov.Id_MGMovDes`).
    pub descrizione_movimento: u8,
    /// Segni del movimento (`MGMov.CarA … ScaT`, `Ret`) dai flag `PP*Q` della causale.
    pub carico_acquisto: i16,
    pub carico_produzione: i16,
    pub carico_trasferimento: i16,
    pub scarico_vendita: i16,
    pub scarico_produzione: i16,
    pub scarico_trasferimento: i16,
    pub reso: i16,
}

#[derive(Debug, Clone)]
pub struct ConfigArca {
    pub documento: TipoDocumentoArca,
    pub causale: CausaleMagazzino,
    pub valuta: String,
    pub decimali: u8,
    pub decimali_prezzo: u8,
    pub aliquote: TabellaAliquote,
}

/// `DOTes.DoBitMask` per `DO.TipoDocumento`: 4 su tutti i 5.455 BO 2026. Gli altri tipi non
/// sono ancora replicati.
fn bitmask(tipo: &str) -> Result<i32, ErroreArca> {
    match tipo {
        "B" => Ok(4),
        altro => Err(ErroreArca::Configurazione(format!("TipoDocumento {altro} non gestito"))),
    }
}

fn testo(row: &Row, colonna: &str) -> Result<Option<String>, ErroreArca> {
    Ok(row.try_get::<&str, _>(colonna)?.map(|s| s.trim().to_owned()))
}

fn obbligatorio(row: &Row, colonna: &str) -> Result<String, ErroreArca> {
    testo(row, colonna)?.ok_or_else(|| ErroreArca::Configurazione(format!("{colonna} vuota")))
}

fn bit(row: &Row, colonna: &str) -> Result<bool, ErroreArca> {
    Ok(row.try_get::<bool, _>(colonna)?.unwrap_or_default())
}

fn segno(row: &Row, colonna: &str) -> Result<i16, ErroreArca> {
    let valore = row.try_get::<i32, _>(colonna)?.unwrap_or_default();
    i16::try_from(valore).map_err(|_| ErroreArca::Configurazione(format!("{colonna} = {valore}")))
}

async fn unica(conn: &mut Connessione, sql: &str, cosa: &str) -> Result<Row, ErroreArca> {
    let mut righe = conn.simple_query(sql).await?.into_first_result().await?;
    match (righe.pop(), righe.is_empty()) {
        (Some(row), true) => Ok(row),
        _ => Err(ErroreArca::Configurazione(format!("{cosa}: attesa una riga"))),
    }
}

impl ConfigArca {
    /// Legge la configurazione per il tipo documento `codice` (per esempio `"BO"`).
    pub async fn carica(conn: &mut Connessione, codice: &str) -> Result<Self, ErroreArca> {
        if !codice.chars().all(|c| c.is_ascii_alphanumeric()) {
            return Err(ErroreArca::Configurazione(format!("codice documento {codice:?}")));
        }
        let row = unica(
            conn,
            &format!(
                "select Cd_Do, TipoDocumento, CliFor, Cd_CN, Cd_MGCausale, Cd_DOAspBene, Cd_DOTrasporto, Cd_DOSped, \
                 Cd_DOPorto, Cd_LS_1, Esecutivo, Prelevabile, Modificabile from DO where Cd_Do = '{codice}'"
            ),
            "DO",
        )
        .await?;
        let tipo = obbligatorio(&row, "TipoDocumento")?;
        let documento = TipoDocumentoArca {
            codice: obbligatorio(&row, "Cd_Do")?,
            bitmask: bitmask(&tipo)?,
            tipo,
            cli_for: obbligatorio(&row, "CliFor")?,
            sezionale: obbligatorio(&row, "Cd_CN")?,
            causale_magazzino: obbligatorio(&row, "Cd_MGCausale")?,
            aspetto_beni: testo(&row, "Cd_DOAspBene")?,
            trasporto: testo(&row, "Cd_DOTrasporto")?,
            spedizione: testo(&row, "Cd_DOSped")?,
            porto: testo(&row, "Cd_DOPorto")?,
            listino: testo(&row, "Cd_LS_1")?,
            esecutivo: bit(&row, "Esecutivo")?,
            prelevabile: bit(&row, "Prelevabile")?,
            modificabile: bit(&row, "Modificabile")?,
        };

        let row = unica(
            conn,
            &format!(
                "select MagPFlag, MagAFlag, Cd_MG_P, Id_MGMovDes_PP, PPCarQAs, PPCarQPs, PPCarQTs, PPScaQVs, PPScaQPs, \
                 PPScaQTs, PPRetQs from MGCausale where Cd_MGCausale = '{}'",
                documento.causale_magazzino
            ),
            "MGCausale",
        )
        .await?;
        let causale = CausaleMagazzino {
            partenza: bit(&row, "MagPFlag")?,
            arrivo: bit(&row, "MagAFlag")?,
            magazzino_partenza: testo(&row, "Cd_MG_P")?,
            descrizione_movimento: row
                .try_get::<u8, _>("Id_MGMovDes_PP")?
                .ok_or_else(|| ErroreArca::Configurazione("Id_MGMovDes_PP vuota".into()))?,
            carico_acquisto: segno(&row, "PPCarQAs")?,
            carico_produzione: segno(&row, "PPCarQPs")?,
            carico_trasferimento: segno(&row, "PPCarQTs")?,
            scarico_vendita: segno(&row, "PPScaQVs")?,
            scarico_produzione: segno(&row, "PPScaQPs")?,
            scarico_trasferimento: segno(&row, "PPScaQTs")?,
            reso: segno(&row, "PPRetQs")?,
        };
        if !causale.partenza || causale.arrivo {
            return Err(ErroreArca::Configurazione(format!(
                "causale {}: gestito solo lo scarico dal magazzino di partenza",
                documento.causale_magazzino
            )));
        }

        let row = unica(conn, "select Cd_VL, Decimali, DecimaliPrzUn from VL where Cd_VL = 'EUR'", "VL").await?;
        let valuta = obbligatorio(&row, "Cd_VL")?;
        let decimali = row.try_get::<u8, _>("Decimali")?.unwrap_or(2);
        let decimali_prezzo = row.try_get::<u8, _>("DecimaliPrzUn")?.unwrap_or(2);

        let mut aliquote = TabellaAliquote::new();
        for row in conn
            .simple_query("select Cd_Aliquota, Aliquota from Aliquota")
            .await?
            .into_first_result()
            .await?
        {
            let percentuale = row.try_get::<Decimal, _>("Aliquota")?.unwrap_or_default().normalize();
            aliquote.inserisci(CodiceAliquota::nuovo(&obbligatorio(&row, "Cd_Aliquota")?), percentuale);
        }

        Ok(Self {
            documento,
            causale,
            valuta,
            decimali,
            decimali_prezzo,
            aliquote,
        })
    }
}
