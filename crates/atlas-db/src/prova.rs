//! Dati di prova sul modello del BO 5455: anagrafiche minime e un DDT con due righe.
//!
//! Per le prove di questo crate e, con la feature `prova`, di quelli che lo usano.

#![allow(clippy::unwrap_used, clippy::missing_panics_doc)]

use atlas_core::aliquota::CodiceAliquota;
use atlas_core::ddt::{Ddt, RigaDdt};
use atlas_core::riga::Pesata;
use chrono::{NaiveDate, NaiveDateTime};
use rusqlite::Connection;
use rust_decimal::Decimal;
use rust_decimal_macros::dec;

use crate::anagrafiche::*;

fn codifica(codice: &str, descrizione: &str) -> Codifica {
    Codifica {
        codice: codice.into(),
        descrizione: descrizione.into(),
    }
}

pub fn cliente(codice: &str) -> ClienteFornitore {
    ClienteFornitore {
        codice: codice.into(),
        ragione_sociale: format!("Cliente {codice}"),
        indirizzo: None,
        cap: None,
        localita: None,
        provincia: None,
        nazione: Some("IT".into()),
        partita_iva: Some("01392110225      ".into()),
        codice_fiscale: None,
        codice_destinatario: Some("X2PH38J".into()),
        codice_ipa: None,
        cliente: true,
        fornitore: false,
        pagamento: Some("B030".into()),
        listino: Some("0000001".into()),
        iban: None,
        bic: None,
        conto_banca: None,
        conto_merce: None,
        agente: None,
        scissione_pagamenti: false,
        ente_pubblico: false,
        aliquota: None,
        cliente_fatturazione: None,
        fido: None,
        note: None,
        obsoleto: false,
        extra: r#"{"Cd_CFZona":"MEZ","Cd_VL":"EUR","EsclusoBlackList":true}"#.into(),
    }
}

pub fn anagrafiche() -> Anagrafiche {
    Anagrafiche {
        aliquote: [("04", dec!(4)), ("10", dec!(10)), ("22", dec!(22))]
            .into_iter()
            .map(|(c, p)| Aliquota {
                codice: c.into(),
                descrizione: format!("IVA {p}%"),
                percentuale: p,
                natura: None,
            })
            .collect(),
        pagamenti: vec![Pagamento {
            codice: "B030".into(),
            descrizione: "Bonifico 30 gg".into(),
            conto_banca: None,
        }],
        unita_misura: vec![codifica("KG", "KG"), codifica("CO", "CO"), codifica("PZ", "PZ")],
        magazzini: vec![codifica("00001", "Magazzino Centrale")],
        agenti: vec![codifica("001", "..")],
        listini: vec![Listino {
            codice: "0000001".into(),
            descrizione: "Listino 1".into(),
            ivato: false,
            tipo: 1,
        }],
        revisioni_listino: vec![RevisioneListino {
            id: 1,
            listino: "0000001".into(),
            descrizione: "Listino 1".into(),
            valido_dal: NaiveDate::from_ymd_opt(2005, 1, 1),
            pubblicata_il: None,
        }],
        articoli: vec![
            Articolo {
                codice: "BAN".into(),
                descrizione: "BANANE".into(),
                descrizione_breve: None,
                unita_misura: "kg".into(),
                aliquota_vendita: None,
                conto_ricavo: None,
                obsoleto: false,
                extra: "{}".into(),
            },
            Articolo {
                codice: "PIST".into(),
                descrizione: "PISTACCHI".into(),
                descrizione_breve: None,
                unita_misura: "KG".into(),
                aliquota_vendita: Some("10".into()),
                conto_ricavo: None,
                obsoleto: false,
                extra: "{}".into(),
            },
        ],
        unita_articoli: vec![UnitaArticolo {
            articolo: "BAN".into(),
            unita_misura: "KG".into(),
            fattore: Decimal::ONE,
            predefinita: true,
            ordine: 1,
        }],
        prezzi_listino: vec![PrezzoListino {
            id: 333,
            revisione: 1,
            articolo: "BAN".into(),
            prezzo: dec!(1.80),
            sconto: None,
        }],
        clienti_fornitori: vec![cliente("C000380"), cliente("C000002")],
        destinazioni: vec![Destinazione {
            cliente: "C000380".into(),
            codice: "ALI".into(),
            descrizione: "Mensa".into(),
            indirizzo: None,
            cap: None,
            localita: None,
            provincia: None,
            nazione: None,
            agente: None,
            aliquota: None,
            predefinita: true,
            obsoleto: false,
            extra: r#"{"CodiceFPR":null,"xCd_Exp":null}"#.into(),
        }],
        contatti: vec![Contatto {
            id: 1,
            cliente: "C000380".into(),
            destinazione: None,
            dati: r#"{"Descrizione":"Aziendale","Fax":"0461 602772","Id_CFContattoTipo":-1,"Telefono":"0461 602772"}"#.into(),
        }],
        predefiniti_righe: PredefinitiRighe {
            conto_ricavo: "07010101001".into(),
            aliquota: "04".into(),
        },
    }
}

pub fn database() -> Connection {
    let mut conn = crate::apri_in_memoria().unwrap();
    aggiorna(&mut conn, &anagrafiche()).unwrap();
    conn
}

fn riga(articolo: &str, colli: Decimal, lordo: Decimal, tara: Decimal, prezzo: Decimal, aliquota: &str) -> RigaDdt {
    RigaDdt {
        articolo: articolo.into(),
        descrizione: articolo.into(),
        unita_misura: "KG".into(),
        fattore_um1: Decimal::ONE,
        conto_ricavo: "07010101001".into(),
        aliquota: CodiceAliquota::nuovo(aliquota),
        id_listino_articolo: Some(333),
        pesata: Pesata::nuova(colli, lordo, tara).unwrap(),
        quantita_forzata: None,
        prezzo_unitario: prezzo,
        sconto_riga: String::new(),
        sconto_addizionale: String::new(),
        magazzino: Some("00001".into()),
    }
}

pub fn adesso() -> NaiveDateTime {
    NaiveDate::from_ymd_opt(2026, 10, 22).unwrap().and_hms_opt(8, 15, 0).unwrap()
}

pub fn ddt(numero: u32) -> Ddt {
    Ddt {
        numero,
        data: NaiveDate::from_ymd_opt(2026, 10, 22).unwrap(),
        cliente: "C000380".into(),
        destinazione: Some("ALI".into()),
        sede: None,
        pagamento: Some("B030".into()),
        listino_cliente: Some("0000001".into()),
        iban: None,
        bic: None,
        conto_banca: None,
        agente: None,
        inizio_trasporto: Some(adesso()),
        scissione_pagamenti: false,
        operatore: "190".into(),
        registrato_il: adesso(),
        righe: vec![
            riga("BAN", dec!(1), dec!(5.46), dec!(0.30), dec!(1.8), "04"),
            riga("PIST", dec!(0), dec!(0.5), dec!(0), dec!(22.40), "10"),
        ],
    }
}
