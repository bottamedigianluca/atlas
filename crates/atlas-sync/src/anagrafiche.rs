//! Lettura delle anagrafiche di Arca nel formato del database ATLAS.
//!
//! Solo `SELECT`. Codici e identificativi perdono gli spazi finali e un codice vuoto vale
//! assente: sono i `char` di Arca (riscritti in una colonna `char` tornano identici) e alcuni
//! `varchar` che Arca riempie, come `AR.Cd_AR` (riempito a 20 in 376 articoli su 466, mentre
//! dal novembre 2018 righe e listini lo registrano senza spazi: 931.730 righe). Gli altri testi
//! (descrizioni, indirizzi, IBAN, note) restano come in Arca, perché alcuni finiscono tali e
//! quali nei documenti replicati.

use atlas_arca::scrittura::Connessione;
use atlas_db::anagrafiche::{
    Aliquota, Anagrafiche, Articolo, ClienteFornitore, Codifica, Contatto, Destinazione, Listino, Pagamento,
    PredefinitiRighe, PrezzoListino, RevisioneListino, UnitaArticolo,
};
use chrono::{NaiveDate, NaiveDateTime};
use rust_decimal::Decimal;
use tiberius::{ColumnData, FromSql, Row};

use crate::ErroreSync;

/// Accesso tipizzato alle colonne di una riga di `tabella`.
struct Riga<'a> {
    tabella: &'static str,
    row: &'a Row,
}

impl Riga<'_> {
    fn errore(&self, colonna: &'static str, problema: impl Into<String>) -> ErroreSync {
        ErroreSync::Dato {
            tabella: self.tabella,
            colonna,
            problema: problema.into(),
        }
    }

    /// Codice facoltativo: senza spazi finali, vuoto = assente.
    fn codice_opz(&self, colonna: &'static str) -> Result<Option<String>, ErroreSync> {
        Ok(self
            .row
            .try_get::<&str, _>(colonna)?
            .map(str::trim_end)
            .filter(|s| !s.is_empty())
            .map(str::to_owned))
    }

    fn codice(&self, colonna: &'static str) -> Result<String, ErroreSync> {
        self.codice_opz(colonna)?.ok_or_else(|| self.errore(colonna, "vuota"))
    }

    /// Colonna `varchar` facoltativa, come in Arca.
    fn testo_opz(&self, colonna: &'static str) -> Result<Option<String>, ErroreSync> {
        Ok(self.row.try_get::<&str, _>(colonna)?.map(str::to_owned))
    }

    fn testo(&self, colonna: &'static str) -> Result<String, ErroreSync> {
        self.testo_opz(colonna)?.ok_or_else(|| self.errore(colonna, "nulla"))
    }

    fn bit(&self, colonna: &'static str) -> Result<bool, ErroreSync> {
        Ok(self.row.try_get::<bool, _>(colonna)?.unwrap_or_default())
    }

    fn decimale_opz(&self, colonna: &'static str) -> Result<Option<Decimal>, ErroreSync> {
        Ok(self.row.try_get::<Decimal, _>(colonna)?.map(|d| d.normalize()))
    }

    fn decimale(&self, colonna: &'static str) -> Result<Decimal, ErroreSync> {
        self.decimale_opz(colonna)?.ok_or_else(|| self.errore(colonna, "nulla"))
    }

    fn intero(&self, colonna: &'static str) -> Result<i64, ErroreSync> {
        self.row
            .try_get::<i32, _>(colonna)?
            .map(i64::from)
            .ok_or_else(|| self.errore(colonna, "nulla"))
    }

    fn byte(&self, colonna: &'static str) -> Result<i64, ErroreSync> {
        self.row
            .try_get::<u8, _>(colonna)?
            .map(i64::from)
            .ok_or_else(|| self.errore(colonna, "nulla"))
    }

    fn data_opz(&self, colonna: &'static str) -> Result<Option<NaiveDate>, ErroreSync> {
        Ok(self.row.try_get::<NaiveDateTime, _>(colonna)?.map(|d| d.date()))
    }
}

/// Tipo SQL Server di una colonna letta così com'è nei campi `extra` delle anagrafiche.
#[derive(Debug, Clone, Copy)]
pub(crate) enum Tipo {
    /// `char`/`varchar`: senza spazi finali, vuoto = assente.
    Testo,
    Bit,
    /// `tinyint`
    Byte,
    /// `smallint`
    Corto,
    /// `numeric`: testo decimale esatto.
    Decimale,
    /// `smalldatetime`: "AAAA-MM-GG hh:mm:ss".
    Data,
    /// `int`
    Intero,
    /// `xml`: letto come testo (`CAST … AS nvarchar(max)`).
    Xml,
}

/// I campi di `CF` che la scheda cliente mostra oltre a quelli che ATLAS usa nei calcoli
/// (nomi e tipi dallo schema di Arca in `docs/sorgenti_arca_decompilati/04_SCHEMI_DATABASE_E_DATI`).
/// Le colonne di `CF` che sono colonne vere di `clienti_fornitori`.
pub(crate) const CF_COLONNE: &str = "Cd_CF, Descrizione, Indirizzo, Cap, Localita, Cd_Provincia, Cd_Nazione, PartitaIva, \
    CodiceFiscale, CodiceFPR, CodiceIPA, Cliente, Fornitore, Cd_PG, Cd_LS_1, Iban, BicCode, Cd_CGConto_Banca, \
    Cd_CGConto_Merce, Cd_Agente_1, IvaSplit, EntePubblico, Cd_Aliquota, Cd_CF_Fatt, Fido, Note_CF, Obsoleto";

/// Le colonne di `AR` che sono colonne vere di `articoli`.
pub(crate) const AR_COLONNE: &str = "Cd_AR, Descrizione, DescrizioneBreve, Cd_ARMisura, Cd_Aliquota_V, Cd_CGConto_VI, Obsoleto";

pub(crate) const CF_EXTRA: &[(&str, Tipo)] = &[
    ("TipoDitta", Tipo::Testo),
    ("Cd_NazioneIva", Tipo::Testo),
    ("Peppol_Endpoint", Tipo::Testo),
    ("TipoCF", Tipo::Testo),
    ("Cd_CGConto_Mastro", Tipo::Testo),
    ("Cd_LS_2", Tipo::Testo),
    ("Cd_VL", Tipo::Testo),
    ("Cd_CFStato", Tipo::Testo),
    ("Cd_CFZona", Tipo::Testo),
    ("Cd_CFSettore", Tipo::Testo),
    ("Cd_DOPorto", Tipo::Testo),
    ("Cd_DOSped", Tipo::Testo),
    ("Cd_DOVettore", Tipo::Testo),
    ("Cd_SL", Tipo::Testo),
    ("Cd_Agente_2", Tipo::Testo),
    ("Id_Lingua", Tipo::Corto),
    ("Sconto", Tipo::Testo),
    ("Provvigione", Tipo::Testo),
    ("SpeseIncasso", Tipo::Bit),
    ("SpeseBolli", Tipo::Bit),
    ("ScGiornoFisso1", Tipo::Byte),
    ("ScGiornoFisso2", Tipo::Byte),
    ("ScGiornoFisso3", Tipo::Byte),
    ("Cd_CFClasse1", Tipo::Testo),
    ("Cd_CFClasse2", Tipo::Testo),
    ("Cd_CFClasse3", Tipo::Testo),
    ("Cd_CFGruppo1", Tipo::Testo),
    ("Cd_CFGruppo2", Tipo::Testo),
    ("Cd_CFGruppo3", Tipo::Testo),
    ("IvaSospesa", Tipo::Bit),
    ("ProceduraConcorsuale", Tipo::Bit),
    ("ConsumatoreFinale", Tipo::Bit),
    ("Condominio", Tipo::Bit),
    ("EsclusoSpesometro", Tipo::Bit),
    ("EsclusoBlackList", Tipo::Bit),
    ("EsclusoOver3000", Tipo::Bit),
    ("DF_Escluso", Tipo::Bit),
    ("Tipofattura", Tipo::Byte),
    ("NRea", Tipo::Testo),
    ("Cd_F24Comune", Tipo::Testo),
    ("Cd_AE_NaturaGiuridica", Tipo::Testo),
    ("Cd_AE_Atecofin", Tipo::Testo),
    ("SDD_IdMandato", Tipo::Testo),
    ("SDD_DtMandato", Tipo::Data),
    ("FE_AddASW", Tipo::Bit),
    ("FE_Ignore_CodiceFPR", Tipo::Bit),
    ("FTE_AutoTipo", Tipo::Byte),
    ("IvaSplitLog", Tipo::Bit),
    ("CD_ReverseCharge", Tipo::Testo),
    ("Cd_Abicab", Tipo::Testo),
    ("ContoCorrente", Tipo::Testo),
    ("Ue", Tipo::Bit),
    ("Intra", Tipo::Bit),
    ("Ritenuta", Tipo::Bit),
    ("Elenchi", Tipo::Bit),
    ("PdAbilita", Tipo::Bit),
    ("PdPriorita", Tipo::Byte),
    ("PdInt4ClienteFatturazione", Tipo::Bit),
    ("PdBrk4DocumentoPrelevato", Tipo::Bit),
    ("PdBrk4ClienteFornitore", Tipo::Bit),
    ("PdBrk4Pagamento", Tipo::Bit),
    ("PdBrk4Agente_1", Tipo::Bit),
    ("PdBrk4Agente_2", Tipo::Bit),
    ("PdBrk4Zona", Tipo::Bit),
    ("PdBrk4SedeAmministrativa", Tipo::Bit),
    ("PdBrk4DestinazioneDiversa", Tipo::Bit),
    ("Cd_NazioneProvincia", Tipo::Testo),
    ("ProspectCliente", Tipo::Bit),
    ("ProspectFornitore", Tipo::Bit),
    ("TipoCF_1", Tipo::Testo),
    ("Cd_INTRAConsegna", Tipo::Testo),
    ("Cd_INTRATrasporto", Tipo::Testo),
    ("Cd_INTRATransazione", Tipo::Testo),
    ("Cd_Nazione_Origine", Tipo::Testo),
    ("Cd_Provincia_Origine", Tipo::Testo),
    ("Cd_Nazione_Destinazione", Tipo::Testo),
    ("Cd_Provincia_Destinazione", Tipo::Testo),
    ("Cd_Nazione_Provenienza", Tipo::Testo),
    ("Cd_CACda", Tipo::Testo),
    ("SO_Indirizzo", Tipo::Testo),
    ("SO_NumeroCivico", Tipo::Testo),
    ("SO_Cap", Tipo::Testo),
    ("SO_Localita", Tipo::Testo),
    ("SO_Cd_Provincia", Tipo::Testo),
    ("SO_Cd_Nazione", Tipo::Testo),
    ("RF_PartitaIva", Tipo::Testo),
    ("RF_RagioneSociale", Tipo::Testo),
    ("RF_Nome", Tipo::Testo),
    ("RF_Cognome", Tipo::Testo),
    ("RF_Cd_Nazione", Tipo::Testo),
    ("FTE_RegimeFiscale", Tipo::Testo),
    ("FTE_Cd_CN", Tipo::Testo),
    ("Cd_ParcT", Tipo::Testo),
    ("Cd_CF_BPoint", Tipo::Testo),
    ("Ricarica", Tipo::Testo),
    // Personalizzazione Bottamedi: codice cliente negli export Conad, Gastropool, Hogast.
    ("xCd_Exp", Tipo::Testo),
    ("Attributi", Tipo::Xml),
    ("ExtraInfo", Tipo::Xml),
    ("UserIns", Tipo::Testo),
    ("TimeIns", Tipo::Data),
    ("UserUpd", Tipo::Testo),
    ("TimeUpd", Tipo::Data),
];

/// I campi di `AR` che la scheda articolo mostra oltre a quelli che ATLAS usa nei calcoli.
pub(crate) const AR_EXTRA: &[(&str, Tipo)] = &[
    ("Note_AR", Tipo::Testo),
    ("VBDescrizione", Tipo::Testo),
    ("Cd_ARGruppo1", Tipo::Testo),
    ("Cd_ARGruppo2", Tipo::Testo),
    ("Cd_ARGruppo3", Tipo::Testo),
    ("Cd_ARClasse1", Tipo::Testo),
    ("Cd_ARClasse2", Tipo::Testo),
    ("Cd_ARClasse3", Tipo::Testo),
    ("Cd_VbReparto", Tipo::Testo),
    ("Cd_Aliquota_A", Tipo::Testo),
    ("Cd_CGConto_VE", Tipo::Testo),
    ("Cd_CGConto_AI", Tipo::Testo),
    ("Cd_CGConto_AE", Tipo::Testo),
    ("Cd_ARStato", Tipo::Testo),
    ("Cd_ARMarca", Tipo::Testo),
    ("Modello", Tipo::Testo),
    ("Cd_ARNomenclatura", Tipo::Testo),
    ("IntraTipo", Tipo::Testo),
    ("Sconto", Tipo::Testo),
    ("Provvigione", Tipo::Testo),
    ("Ricarica", Tipo::Testo),
    ("ScortaMinima", Tipo::Decimale),
    ("LottoMinimo", Tipo::Decimale),
    ("LottoRiordino", Tipo::Decimale),
    ("PesoLordo", Tipo::Decimale),
    ("PesoNetto", Tipo::Decimale),
    ("Altezza", Tipo::Decimale),
    ("Lunghezza", Tipo::Decimale),
    ("Larghezza", Tipo::Decimale),
    ("CostoStandard", Tipo::Decimale),
    ("ClasseAbc", Tipo::Testo),
    ("TipoValorizzazione", Tipo::Byte),
    ("Fittizio", Tipo::Bit),
    ("NoInventario", Tipo::Bit),
    ("NoGiornale", Tipo::Bit),
    ("MG_LottoObbligatorio", Tipo::Bit),
    ("MG_MatricolaObbligatoria", Tipo::Bit),
    ("MG_GiacenzaNonNegativa", Tipo::Bit),
    ("Cd_Nazione_Origine", Tipo::Testo),
    ("Cd_Provincia_Origine", Tipo::Testo),
    ("xCosto", Tipo::Decimale),
    ("xRicarico", Tipo::Decimale),
    ("xCd_ARLottoP", Tipo::Testo),
    ("WebDescrizione", Tipo::Testo),
    ("WebNote_AR", Tipo::Testo),
    ("WebInfoLink", Tipo::Testo),
    ("WebGiacenza", Tipo::Decimale),
    ("WebB2CPubblica", Tipo::Bit),
    ("WebB2BPubblica", Tipo::Bit),
    ("NoteOfferta", Tipo::Testo),
    ("Cd_CAVda_VI", Tipo::Testo),
    ("Cd_CAVda_VE", Tipo::Testo),
    ("Cd_CAVda_AI", Tipo::Testo),
    ("Cd_CAVda_AE", Tipo::Testo),
    ("Cd_ARPrdClasse", Tipo::Testo),
    ("Id_ARCategoria", Tipo::Intero),
    ("Cd_IntraServizio", Tipo::Testo),
    ("ScortaMassima", Tipo::Decimale),
    ("PesoFattore", Tipo::Decimale),
    ("DimensioniFattore", Tipo::Decimale),
    ("DBKit", Tipo::Bit),
    ("DBFantasma", Tipo::Bit),
    ("TipoGestComm", Tipo::Byte),
    ("MrpGiorniRiordino", Tipo::Corto),
    ("MrpProduzioneMassima", Tipo::Decimale),
    ("MrpIncludi", Tipo::Bit),
    ("MrpGiorniCopertura", Tipo::Corto),
    ("MrpResa", Tipo::Corto),
    ("MrpLottoRiordino", Tipo::Bit),
    ("MrpLottoMinimo", Tipo::Bit),
    ("MrpPuntoRiordino", Tipo::Byte),
    ("MrpIgnoraDistinta", Tipo::Bit),
    ("MrpAggiornaCostoDistinta", Tipo::Bit),
    ("MrpForzaExpDistinta", Tipo::Bit),
    ("MRPConsideraDaAcquistare", Tipo::Bit),
    ("AmsManaged", Tipo::Bit),
    ("FTE_CodiceTipo", Tipo::Testo),
    ("FTE_CodiceValore", Tipo::Testo),
    ("Attributi", Tipo::Xml),
    ("ExtraInfo", Tipo::Xml),
    ("UserIns", Tipo::Testo),
    ("TimeIns", Tipo::Data),
    ("UserUpd", Tipo::Testo),
    ("TimeUpd", Tipo::Data),
];

impl Riga<'_> {
    /// Le colonne `colonne` in un oggetto JSON (chiavi ordinate: lo stesso dato dà lo stesso testo,
    /// e l'aggiornamento idempotente non riscrive le righe invariate).
    fn extra(&self, colonne: &[(&'static str, Tipo)]) -> Result<String, ErroreSync> {
        let mut oggetto = serde_json::Map::new();
        for &(colonna, tipo) in colonne {
            let valore = match tipo {
                Tipo::Testo => self.codice_opz(colonna)?.map(serde_json::Value::from),
                Tipo::Bit => self.row.try_get::<bool, _>(colonna)?.map(serde_json::Value::from),
                Tipo::Byte => self.row.try_get::<u8, _>(colonna)?.map(serde_json::Value::from),
                Tipo::Corto => self.row.try_get::<i16, _>(colonna)?.map(serde_json::Value::from),
                Tipo::Intero => self.row.try_get::<i32, _>(colonna)?.map(serde_json::Value::from),
                Tipo::Xml => self.codice_opz(colonna)?.map(serde_json::Value::from),
                Tipo::Decimale => self.decimale_opz(colonna)?.map(|d| serde_json::Value::from(d.to_string())),
                Tipo::Data => self
                    .row
                    .try_get::<NaiveDateTime, _>(colonna)?
                    .map(|d| serde_json::Value::from(d.format("%Y-%m-%d %H:%M:%S").to_string())),
            };
            oggetto.insert(colonna.to_owned(), valore.unwrap_or(serde_json::Value::Null));
        }
        serde_json::to_string(&oggetto).map_err(|e| self.errore("extra", e.to_string()))
    }
}

/// `select` delle colonne date più quelle `extra` (gli `xml` convertiti in testo).
fn con_extra(colonne: &str, extra: &[(&str, Tipo)], tabella: &str) -> String {
    let altre: Vec<String> = extra
        .iter()
        .map(|&(c, tipo)| match tipo {
            Tipo::Xml => format!("CAST({c} AS nvarchar(max)) AS {c}"),
            _ => c.to_owned(),
        })
        .collect();
    format!("select {colonne}, {} from {tabella}", altre.join(", "))
}

/// Tutte le colonne di una riga letta con `select *`, tranne `escluse`, in un oggetto JSON con i
/// nomi di Arca: per le tabelle di cui non si scrive a mano l'elenco (`CFDest`, `CFContatto`), così
/// nessun campo resta fuori. Stessi formati di [`Riga::extra`]; i binari (`timestamp`) si saltano.
fn tutte_le_colonne(row: &Row, tabella: &'static str, escluse: &[&str]) -> Result<String, ErroreSync> {
    let mut oggetto = serde_json::Map::new();
    for (colonna, dato) in row.cells() {
        let nome = colonna.name();
        if escluse.iter().any(|e| e.eq_ignore_ascii_case(nome)) {
            continue;
        }
        let errore = |e: tiberius::error::Error| ErroreSync::Dato {
            tabella,
            colonna: "*",
            problema: format!("{nome}: {e}"),
        };
        let valore = match dato {
            ColumnData::U8(v) => v.map(serde_json::Value::from),
            ColumnData::I16(v) => v.map(serde_json::Value::from),
            ColumnData::I32(v) => v.map(serde_json::Value::from),
            ColumnData::I64(v) => v.map(serde_json::Value::from),
            ColumnData::F32(v) => v.map(serde_json::Value::from),
            ColumnData::F64(v) => v.map(serde_json::Value::from),
            ColumnData::Bit(v) => v.map(serde_json::Value::from),
            ColumnData::String(v) => v
                .as_deref()
                .map(str::trim_end)
                .filter(|t| !t.is_empty())
                .map(serde_json::Value::from),
            ColumnData::Guid(v) => v.map(|g| serde_json::Value::from(g.to_string())),
            ColumnData::Numeric(_) => Decimal::from_sql(dato)
                .map_err(errore)?
                .map(|d| serde_json::Value::from(d.normalize().to_string())),
            ColumnData::Xml(v) => v.as_deref().map(|x| serde_json::Value::from(x.to_string())),
            ColumnData::Binary(_) => continue,
            _ => NaiveDateTime::from_sql(dato)
                .map_err(errore)?
                .map(|d| serde_json::Value::from(d.format("%Y-%m-%d %H:%M:%S").to_string())),
        };
        oggetto.insert(nome.to_owned(), valore.unwrap_or(serde_json::Value::Null));
    }
    serde_json::to_string(&oggetto).map_err(|e| ErroreSync::Dato {
        tabella,
        colonna: "*",
        problema: e.to_string(),
    })
}

/// Colonne di `CFDest` già colonne vere di `destinazioni`, o tecniche.
const CFDEST_DATE: &[&str] = &[
    "Id_CFDest", "Cd_CF", "Cd_CFDest", "Descrizione", "Indirizzo", "Cap", "Localita", "Cd_Provincia", "Cd_Nazione",
    "Cd_Agente", "Cd_Aliquota", "DefaultDestinazione", "Obsoleto", "Ts",
];

/// Colonne tecniche di `CFContatto`, fuori dai dati del contatto.
const CFCONTATTO_ESCLUSE: &[&str] = &["Ts"];

async fn leggi<T>(
    conn: &mut Connessione,
    tabella: &'static str,
    sql: &str,
    mut converti: impl FnMut(&Riga<'_>) -> Result<T, ErroreSync>,
) -> Result<Vec<T>, ErroreSync> {
    let righe = conn.simple_query(sql).await?.into_first_result().await?;
    righe.iter().map(|row| converti(&Riga { tabella, row })).collect()
}

fn codifica(r: &Riga<'_>, colonna: &'static str) -> Result<Codifica, ErroreSync> {
    Ok(Codifica {
        codice: r.codice(colonna)?,
        descrizione: r.testo("Descrizione")?,
    })
}

/// Legge da Arca tutte le anagrafiche che ATLAS usa.
pub async fn leggi_anagrafiche(conn: &mut Connessione) -> Result<Anagrafiche, ErroreSync> {
    let aliquote = leggi(conn, "Aliquota", "select Cd_Aliquota, Descrizione, Aliquota, Cd_Natura from Aliquota", |r| {
        Ok(Aliquota {
            codice: r.codice("Cd_Aliquota")?,
            descrizione: r.testo("Descrizione")?,
            percentuale: r.decimale("Aliquota")?,
            natura: r.codice_opz("Cd_Natura")?,
        })
    })
    .await?;

    let pagamenti = leggi(conn, "PG", "select Cd_PG, Descrizione, Cd_CGConto_Banca from PG", |r| {
        Ok(Pagamento {
            codice: r.codice("Cd_PG")?,
            descrizione: r.testo("Descrizione")?,
            conto_banca: r.codice_opz("Cd_CGConto_Banca")?,
        })
    })
    .await?;

    let unita_misura = leggi(conn, "ARMisura", "select Cd_ARMisura, Descrizione from ARMisura", |r| {
        codifica(r, "Cd_ARMisura")
    })
    .await?;
    let magazzini = leggi(conn, "MG", "select Cd_MG, Descrizione from MG", |r| codifica(r, "Cd_MG")).await?;
    let agenti = leggi(conn, "Agente", "select Cd_Agente, Descrizione from Agente", |r| codifica(r, "Cd_Agente")).await?;

    let listini = leggi(conn, "LS", "select Cd_LS, Descrizione, Ivato, TipoLS from LS", |r| {
        Ok(Listino {
            codice: r.codice("Cd_LS")?,
            descrizione: r.testo("Descrizione")?,
            ivato: r.bit("Ivato")?,
            tipo: r.byte("TipoLS")?,
        })
    })
    .await?;

    let revisioni_listino = leggi(
        conn,
        "LSRevisione",
        "select Id_LSRevisione, Cd_LS, Descrizione, DaData, DataPubblicazione from LSRevisione",
        |r| {
            Ok(RevisioneListino {
                id: r.intero("Id_LSRevisione")?,
                listino: r.codice("Cd_LS")?,
                descrizione: r.testo("Descrizione")?,
                valido_dal: r.data_opz("DaData")?,
                pubblicata_il: r.data_opz("DataPubblicazione")?,
            })
        },
    )
    .await?;

    let articoli = leggi(
        conn,
        "AR",
        &con_extra(AR_COLONNE, AR_EXTRA, "AR"),
        |r| {
            Ok(Articolo {
                codice: r.codice("Cd_AR")?,
                descrizione: r.testo("Descrizione")?,
                descrizione_breve: r.testo_opz("DescrizioneBreve")?,
                unita_misura: r.codice("Cd_ARMisura")?,
                aliquota_vendita: r.codice_opz("Cd_Aliquota_V")?,
                conto_ricavo: r.codice_opz("Cd_CGConto_VI")?,
                obsoleto: r.bit("Obsoleto")?,
                extra: r.extra(AR_EXTRA)?,
            })
        },
    )
    .await?;

    let unita_articoli = leggi(
        conn,
        "ARARMisura",
        "select Cd_AR, Cd_ARMisura, UMFatt, DefaultMisura, Riga from ARARMisura",
        |r| {
            Ok(UnitaArticolo {
                articolo: r.codice("Cd_AR")?,
                unita_misura: r.codice("Cd_ARMisura")?,
                fattore: r.decimale("UMFatt")?,
                predefinita: r.bit("DefaultMisura")?,
                ordine: r.byte("Riga")?,
            })
        },
    )
    .await?;

    let prezzi_listino = leggi(
        conn,
        "LSArticolo",
        "select Id_LSArticolo, Id_LSRevisione, Cd_AR, Prezzo, Sconto from LSArticolo",
        |r| {
            Ok(PrezzoListino {
                id: r.intero("Id_LSArticolo")?,
                revisione: r.intero("Id_LSRevisione")?,
                articolo: r.codice("Cd_AR")?,
                prezzo: r.decimale("Prezzo")?,
                sconto: r.testo_opz("Sconto")?,
            })
        },
    )
    .await?;

    let clienti_fornitori = leggi(
        conn,
        "CF",
        &con_extra(
            CF_COLONNE,
            CF_EXTRA,
            "CF",
        ),
        |r| {
            Ok(ClienteFornitore {
                codice: r.codice("Cd_CF")?,
                ragione_sociale: r.testo("Descrizione")?,
                indirizzo: r.testo_opz("Indirizzo")?,
                cap: r.testo_opz("Cap")?,
                localita: r.testo_opz("Localita")?,
                provincia: r.codice_opz("Cd_Provincia")?,
                nazione: r.codice_opz("Cd_Nazione")?,
                partita_iva: r.codice_opz("PartitaIva")?,
                codice_fiscale: r.codice_opz("CodiceFiscale")?,
                codice_destinatario: r.codice_opz("CodiceFPR")?,
                codice_ipa: r.codice_opz("CodiceIPA")?,
                cliente: r.bit("Cliente")?,
                fornitore: r.bit("Fornitore")?,
                pagamento: r.codice_opz("Cd_PG")?,
                listino: r.codice_opz("Cd_LS_1")?,
                iban: r.testo_opz("Iban")?,
                bic: r.codice_opz("BicCode")?,
                conto_banca: r.codice_opz("Cd_CGConto_Banca")?,
                conto_merce: r.codice_opz("Cd_CGConto_Merce")?,
                agente: r.codice_opz("Cd_Agente_1")?,
                scissione_pagamenti: r.bit("IvaSplit")?,
                ente_pubblico: r.bit("EntePubblico")?,
                aliquota: r.codice_opz("Cd_Aliquota")?,
                cliente_fatturazione: r.codice_opz("Cd_CF_Fatt")?,
                fido: r.decimale_opz("Fido")?,
                note: r.testo_opz("Note_CF")?,
                obsoleto: r.bit("Obsoleto")?,
                extra: r.extra(CF_EXTRA)?,
            })
        },
    )
    .await?;

    let destinazioni = leggi(
        conn,
        "CFDest",
        "select * from CFDest",
        |r| {
            Ok(Destinazione {
                cliente: r.codice("Cd_CF")?,
                codice: r.codice("Cd_CFDest")?,
                descrizione: r.testo("Descrizione")?,
                indirizzo: r.testo_opz("Indirizzo")?,
                cap: r.testo_opz("Cap")?,
                localita: r.testo_opz("Localita")?,
                provincia: r.codice_opz("Cd_Provincia")?,
                nazione: r.codice_opz("Cd_Nazione")?,
                agente: r.codice_opz("Cd_Agente")?,
                aliquota: r.codice_opz("Cd_Aliquota")?,
                predefinita: r.bit("DefaultDestinazione")?,
                obsoleto: r.bit("Obsoleto")?,
                extra: tutte_le_colonne(r.row, "CFDest", CFDEST_DATE)?,
            })
        },
    )
    .await?;

    // Contatti dei clienti e delle destinazioni (telefono, email, PEC…): tutte le colonne.
    let contatti = leggi(conn, "CFContatto", "select * from CFContatto", |r| {
        Ok(Contatto {
            id: r.intero("Id_CFContatto")?,
            cliente: r.codice("Cd_CF")?,
            destinazione: r.codice_opz("Cd_CFDest")?,
            dati: tutte_le_colonne(r.row, "CFContatto", CFCONTATTO_ESCLUSE)?,
        })
    })
    .await?;

    // Default delle righe documento di vendita (`fedi_doc`, cursore `Impostazione`).
    let mut predefiniti = leggi(
        conn,
        "Impostazione",
        "select Cd_CGConto_2, Cd_Aliquota_2 from Impostazione where Cd_Impostazione = 'DEFAULT_RIGHE_DOC'",
        |r| {
            Ok(PredefinitiRighe {
                conto_ricavo: r.codice("Cd_CGConto_2")?,
                aliquota: r.codice("Cd_Aliquota_2")?,
            })
        },
    )
    .await?;
    let predefiniti_righe = match (predefiniti.pop(), predefiniti.is_empty()) {
        (Some(p), true) => p,
        _ => {
            return Err(ErroreSync::Dato {
                tabella: "Impostazione",
                colonna: "Cd_Impostazione",
                problema: "attesa una riga DEFAULT_RIGHE_DOC".into(),
            });
        }
    };

    Ok(Anagrafiche {
        aliquote,
        pagamenti,
        unita_misura,
        magazzini,
        agenti,
        listini,
        revisioni_listino,
        articoli,
        unita_articoli,
        prezzi_listino,
        clienti_fornitori,
        destinazioni,
        contatti,
        predefiniti_righe,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Lo schema delle tabelle di Arca esportato dal database del negozio.
    const SCHEMA: &str = include_str!("../../../docs/sorgenti_arca_decompilati/04_SCHEMI_DATABASE_E_DATI/schema/schema_arca_core.json");

    fn colonne_di_arca(tabella: &str) -> Vec<String> {
        let schema: serde_json::Value = serde_json::from_str(SCHEMA).unwrap();
        let mut colonne: Vec<String> = Vec::new();
        for c in schema[tabella].as_array().unwrap() {
            let nome = c["COLUMN_NAME"].as_str().unwrap().to_owned();
            if !colonne.contains(&nome) {
                colonne.push(nome);
            }
        }
        colonne
    }

    /// Tabella di Arca, colonne vere, colonne `extra` e colonne lasciate fuori.
    type Caso = (&'static str, &'static str, &'static [(&'static str, Tipo)], &'static [&'static str]);

    /// Nessuna colonna di `CF` e `AR` resta fuori dall'importazione senza un motivo scritto qui.
    #[test]
    fn tutte_le_colonne_di_cf_e_ar_sono_importate() {
        let casi: [Caso; 2] = [
            (
                "CF",
                CF_COLONNE,
                CF_EXTRA,
                // Identità e rowversion; stato interno di Arca; cronologia e note in XML (le note in
                // chiaro sono `Note_CF`).
                &["Id_CF", "Ts", "Reserved_1", "EvtnInfo", "HistoryData", "NoteXML"],
            ),
            (
                "AR",
                AR_COLONNE,
                AR_EXTRA,
                // Identità e rowversion; colonne calcolate da Arca (misure in unità MKS, classi e
                // gruppi concatenati); note in XML (in chiaro `Note_AR`).
                &[
                    "Id_AR", "Ts", "NoteXML", "PesoLordoMks", "PesoNettoMks", "AltezzaMks", "LunghezzaMks", "LarghezzaMks",
                    "VolumeMks", "Cd_ARClasse12", "Cd_ARClasse123", "Cd_ARGruppo12", "Cd_ARGruppo123",
                ],
            ),
        ];
        for (tabella, base, extra, escluse) in casi {
            let lette: Vec<&str> = base
                .split(',')
                .map(str::trim)
                .chain(extra.iter().map(|(c, _)| *c))
                .chain(escluse.iter().copied())
                .collect();
            let mancanti: Vec<String> = colonne_di_arca(tabella).into_iter().filter(|c| !lette.contains(&c.as_str())).collect();
            assert!(mancanti.is_empty(), "{tabella}: colonne non importate {mancanti:?}");
            assert!(con_extra(base, extra, tabella).starts_with(&format!("select {base}")));
        }
    }
}
