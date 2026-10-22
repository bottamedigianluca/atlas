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
    Aliquota, Anagrafiche, Articolo, ClienteFornitore, Codifica, Destinazione, Listino, Pagamento,
    PredefinitiRighe, PrezzoListino, RevisioneListino, UnitaArticolo,
};
use chrono::{NaiveDate, NaiveDateTime};
use rust_decimal::Decimal;
use tiberius::Row;

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
        "select Cd_AR, Descrizione, DescrizioneBreve, Cd_ARMisura, Cd_Aliquota_V, Cd_CGConto_VI, Obsoleto from AR",
        |r| {
            Ok(Articolo {
                codice: r.codice("Cd_AR")?,
                descrizione: r.testo("Descrizione")?,
                descrizione_breve: r.testo_opz("DescrizioneBreve")?,
                unita_misura: r.codice("Cd_ARMisura")?,
                aliquota_vendita: r.codice_opz("Cd_Aliquota_V")?,
                conto_ricavo: r.codice_opz("Cd_CGConto_VI")?,
                obsoleto: r.bit("Obsoleto")?,
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
        "select Cd_CF, Descrizione, Indirizzo, Cap, Localita, Cd_Provincia, Cd_Nazione, PartitaIva, CodiceFiscale, \
         CodiceFPR, CodiceIPA, Cliente, Fornitore, Cd_PG, Cd_LS_1, Iban, BicCode, Cd_CGConto_Banca, Cd_CGConto_Merce, \
         Cd_Agente_1, IvaSplit, EntePubblico, Cd_Aliquota, Cd_CF_Fatt, Fido, Note_CF, Obsoleto from CF",
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
            })
        },
    )
    .await?;

    let destinazioni = leggi(
        conn,
        "CFDest",
        "select Cd_CF, Cd_CFDest, Descrizione, Indirizzo, Cap, Localita, Cd_Provincia, Cd_Nazione, Cd_Agente, \
         Cd_Aliquota, DefaultDestinazione, Obsoleto from CFDest",
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
            })
        },
    )
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
        predefiniti_righe,
    })
}
