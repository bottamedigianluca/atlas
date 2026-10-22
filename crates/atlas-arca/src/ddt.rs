//! DDT di vendita ATLAS e sua traduzione nelle tabelle di Arca.
//!
//! Le regole di colonna sono misurate sui 5.455 BO 2026 di `ADB_BOTTAMEDI_DEV` e verificate
//! rigiocando lo storico con `prova-ddt rigioca`: ogni colonna di ogni tabella, comprese le
//! calcolate e quelle lasciate al default, deve coincidere con il documento nativo.

use atlas_core::importo::{Limitato, arrotonda, arrotonda_importo};
use atlas_core::iva::Castelletto;
use atlas_core::riga::{RigaMerce, Sconto};
use chrono::Datelike;
use rust_decimal::Decimal;

use crate::ErroreArca;
use crate::config::ConfigArca;
use crate::record::{Record, Valore};

pub use atlas_core::ddt::{Ddt, RigaDdt};

/// `Reserved_1` a salvataggio concluso: il trigger di `DOTes` lo porta a `I0000000I0`
/// all'inserimento e `asp_Do_Begin` lo azzera.
const RESERVED_1: &str = "0000000000";

/// `DOTes.ExtraInfo` di ogni BO 2026.
const EXTRA_INFO: &str = "<extrafields/>";

/// Decimali dell'imposta non arrotondata (`DOIva.ImpostaV_NA numeric(18,6)`).
const DECIMALI_IMPOSTA_NA: u32 = 6;

/// Il numero occupa le prime 6 posizioni (`NumeroDocI = left(NumeroDoc, 6)`).
const NUMERO_MASSIMO: u32 = 999_999;

/// Righe da scrivere. Le chiavi esterne (`Id_DOTes`, `Id_DoRig`) le aggiunge la scrittura.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TabelleArca {
    pub testata: Record,
    /// Ogni riga con il suo eventuale movimento di magazzino.
    pub righe: Vec<(Record, Option<Record>)>,
    pub totali: Record,
    pub iva: Vec<Record>,
}

/// `DOTes.NumeroDoc`: numero allineato a destra su 6 posizioni, poi 4 spazi (5.455 BO su 5.455).
pub fn numero_documento(numero: u32) -> Result<String, ErroreArca> {
    if numero == 0 || numero > NUMERO_MASSIMO {
        return Err(ErroreArca::DocumentoNonValido(format!("numero {numero}")));
    }
    Ok(format!("{numero:>6}    "))
}

struct RigaCalcolata<'a> {
    riga: &'a RigaDdt,
    quantita: Decimal,
    totale: Decimal,
    sconto_riga: Sconto,
    sconto_addizionale: Sconto,
    sconto_totale: Sconto,
}

/// Traduzione di un documento ATLAS nelle righe delle tabelle di Arca.
pub trait InTabelle {
    fn in_tabelle(&self, cfg: &ConfigArca) -> Result<TabelleArca, ErroreArca>;
}

impl InTabelle for Ddt {
    fn in_tabelle(&self, cfg: &ConfigArca) -> Result<TabelleArca, ErroreArca> {
        if self.righe.is_empty() {
            return Err(ErroreArca::DocumentoNonValido("nessuna riga".into()));
        }
        let righe_merce = i16::try_from(self.righe.len())
            .map_err(|_| ErroreArca::DocumentoNonValido(format!("{} righe", self.righe.len())))?;
        let numero = numero_documento(self.numero)?;
        let esercizio = self.data.year().to_string();
        let data = self.data.and_hms_opt(0, 0, 0).ok_or_else(|| ErroreArca::DocumentoNonValido("data".into()))?;
        let doc = &cfg.documento;

        let calcolate = self
            .righe
            .iter()
            .map(|riga| {
                let quantita = riga.quantita();
                let sconto_totale = Sconto::da_testi(&riga.sconto_riga, &riga.sconto_addizionale)?;
                let merce = RigaMerce {
                    quantita: Limitato::nuovo("quantità", quantita)?,
                    prezzo_unitario: Limitato::nuovo("prezzo", riga.prezzo_unitario)?,
                    prezzo_addizionale: Limitato::ZERO,
                    sconto: sconto_totale,
                    aliquota: Some(riga.aliquota.clone()),
                };
                Ok(RigaCalcolata {
                    riga,
                    quantita,
                    totale: merce.totale(),
                    sconto_riga: Sconto::da_testi(&riga.sconto_riga, "")?,
                    sconto_addizionale: Sconto::da_testi("", &riga.sconto_addizionale)?,
                    sconto_totale,
                })
            })
            .collect::<Result<Vec<_>, ErroreArca>>()?;

        let castelletto = Castelletto::calcola(calcolate.iter().map(|c| (&c.riga.aliquota, c.totale)), &cfg.aliquote)?;
        // Merce prima degli sconti: somma dei Qta × prezzo arrotondati per riga (5.454 BO su 5.454
        // senza spese; la somma arrotondata alla fine sbaglia 1.958 documenti).
        let merce_lordo: Decimal = calcolate
            .iter()
            .map(|c| arrotonda_importo(c.quantita * c.riga.prezzo_unitario))
            .sum();
        let merce_netto: Decimal = calcolate.iter().map(|c| c.totale).sum();
        let da_pagare = castelletto.netto_a_pagare(self.scissione_pagamenti, Decimal::ZERO);
        let utente = || Valore::testo(&self.operatore);
        let istante = || Valore::DataOra(Some(self.registrato_il));

        let testata = Record::nuovo("DOTes")
            .con("Cd_Do", Valore::testo(&doc.codice))
            .con("TipoDocumento", Valore::testo(&doc.tipo))
            .con("DoBitMask", Valore::Intero(Some(doc.bitmask)))
            .con("Cd_CF", Valore::testo(&self.cliente))
            .con("CliFor", Valore::testo(&doc.cli_for))
            .con("Cd_CFDest", Valore::testo_opz(self.destinazione.as_deref()))
            .con("Cd_CFSede", Valore::testo_opz(self.sede.as_deref()))
            .con("Cd_CN", Valore::testo(&doc.sezionale))
            .con("Esecutivo", Valore::Bit(doc.esecutivo))
            .con("Prelevabile", Valore::Bit(doc.prelevabile))
            .con("Modificabile", Valore::Bit(doc.modificabile))
            .con("NumeroDoc", Valore::testo(&numero))
            .con("DataDoc", Valore::DataOra(Some(data)))
            .con("Cd_MGEsercizio", Valore::testo(&esercizio))
            .con("EsAnno", Valore::testo(&esercizio))
            .con("Iban", Valore::testo_opz(self.iban.as_deref()))
            .con("BicCode", Valore::testo_opz(self.bic.as_deref()))
            .con("Cd_CGConto_Banca", Valore::testo_opz(self.conto_banca.as_deref()))
            .con("Cd_VL", Valore::testo(&cfg.valuta))
            .con("Decimali", Valore::Byte(cfg.decimali))
            .con("DecimaliPrzUn", Valore::Byte(cfg.decimali_prezzo))
            .con("Cambio", Valore::Decimale(Decimal::ONE))
            .con("Cd_MGCausale", Valore::testo(&doc.causale_magazzino))
            .con("MagPFlag", Valore::Bit(cfg.causale.partenza))
            .con("MagAFlag", Valore::Bit(cfg.causale.arrivo))
            .con("Cd_LS_1", Valore::testo_opz(self.listino_cliente.as_deref()))
            .con("Cd_LS_2", Valore::testo_opz(doc.listino.as_deref()))
            .con("Cd_PG", Valore::testo_opz(self.pagamento.as_deref()))
            .con("Cd_Agente_1", Valore::testo_opz(self.agente.as_deref()))
            .con("Cd_DoTrasporto", Valore::testo_opz(doc.trasporto.as_deref()))
            .con("Cd_DoSped", Valore::testo_opz(doc.spedizione.as_deref()))
            .con("Cd_DoPorto", Valore::testo_opz(doc.porto.as_deref()))
            .con("Cd_DoAspBene", Valore::testo_opz(doc.aspetto_beni.as_deref()))
            .con("TrasportoDataora", Valore::DataOra(self.inizio_trasporto))
            .con("RigheMerce", Valore::Piccolo(righe_merce))
            .con("RigheMerceEvadibili", Valore::Piccolo(righe_merce))
            .con("Reserved_1", Valore::testo(RESERVED_1))
            .con("UserIns", utente())
            .con("UserUpd", utente())
            .con("TimeIns", istante())
            .con("TimeUpd", istante())
            .con("IvaSplit", Valore::Bit(self.scissione_pagamenti))
            .con("ExtraInfo", Valore::testo(EXTRA_INFO));

        let mut righe = Vec::with_capacity(calcolate.len());
        for (indice, c) in (1_i16..).zip(&calcolate) {
            let r = c.riga;
            let magazzino = r.magazzino.as_deref().or(cfg.causale.magazzino_partenza.as_deref());
            let aliquota = r.aliquota.as_str();
            let riga = Record::nuovo("DORig")
                .con("NumeroDoc", Valore::testo(&numero))
                .con("DataDoc", Valore::DataOra(Some(data)))
                .con("Cd_MGEsercizio", Valore::testo(&esercizio))
                .con("Cd_DO", Valore::testo(&doc.codice))
                .con("TipoDocumento", Valore::testo(&doc.tipo))
                .con("Cd_CF", Valore::testo(&self.cliente))
                .con("Cd_VL", Valore::testo(&cfg.valuta))
                .con("Cambio", Valore::Decimale(Decimal::ONE))
                .con("Decimali", Valore::Byte(cfg.decimali))
                .con("DecimaliPrzUn", Valore::Byte(cfg.decimali_prezzo))
                .con("Riga", Valore::Piccolo(indice))
                .con("Cd_MGCausale", Valore::testo(&doc.causale_magazzino))
                .con("Cd_MG_P", Valore::testo_opz(magazzino))
                .con("Cd_AR", Valore::testo(&r.articolo))
                .con("Descrizione", Valore::testo(&r.descrizione))
                .con("Cd_ARMisura", Valore::testo(&r.unita_misura))
                .con("Cd_CGConto", Valore::testo(&r.conto_ricavo))
                .con("Cd_Aliquota", Valore::testo(aliquota))
                .con("Cd_Aliquota_R", Valore::testo(aliquota))
                .con("Qta", Valore::Decimale(c.quantita))
                .con("FattoreToUM1", Valore::Decimale(r.fattore_um1))
                .con("QtaEvadibile", Valore::Decimale(c.quantita))
                .con("PrezzoUnitarioV", Valore::Decimale(r.prezzo_unitario))
                .con("ScontoRiga", Valore::testo(r.sconto_riga.trim()))
                .con("PrezzoTotaleV", Valore::Decimale(c.totale))
                .con("PrezzoTotaleMovE", Valore::Decimale(arrotonda_importo(c.totale)))
                .con("Esecutivo", Valore::Bit(doc.esecutivo))
                .con("Reserved_1", Valore::testo(RESERVED_1))
                .con("ScontoAddizionale", Valore::testo(r.sconto_addizionale.trim()))
                .con("FattoreScontoRiga", Valore::Decimale(c.sconto_riga.fattore()))
                .con("FattoreScontoAddizionale", Valore::Decimale(c.sconto_addizionale.fattore()))
                .con("FattoreScontoTotale", Valore::Decimale(c.sconto_totale.fattore()))
                .con("Id_LSArticolo", Valore::Intero(r.id_listino_articolo))
                .con("UserIns", utente())
                .con("UserUpd", utente())
                .con("TimeIns", istante())
                .con("TimeUpd", istante())
                .con("xColli", Valore::Decimale(r.pesata.colli()))
                .con("xLordo", Valore::Decimale(r.pesata.lordo()))
                .con("xTara", Valore::Decimale(r.pesata.tara_per_collo()))
                .con("Omaggio", Valore::Byte(1));

            // Scarico solo per i documenti esecutivi e le quantità non nulle: le 73 righe a
            // quantità zero e le 4 del BO non esecutivo 98422 non hanno movimento (2026).
            let movimento = (doc.esecutivo && !c.quantita.is_zero()).then(|| {
                let causale = &cfg.causale;
                Record::nuovo("MGMov")
                    .con("DataMov", Valore::DataOra(Some(data)))
                    .con("Cd_MGEsercizio", Valore::testo(&esercizio))
                    .con("Cd_AR", Valore::testo(&r.articolo))
                    .con("Cd_MG", Valore::testo_opz(magazzino))
                    .con("Id_MGMovDes", Valore::Byte(causale.descrizione_movimento))
                    .con("PartenzaArrivo", Valore::testo("P"))
                    .con("PadreComponente", Valore::testo("P"))
                    .con("Quantita", Valore::Decimale(c.quantita * r.fattore_um1))
                    .con("Valore", Valore::Decimale(arrotonda_importo(c.totale)))
                    .con("Cd_MGCausale", Valore::testo(&doc.causale_magazzino))
                    .con("Ret", Valore::Piccolo(causale.reso))
                    .con("CarA", Valore::Piccolo(causale.carico_acquisto))
                    .con("CarP", Valore::Piccolo(causale.carico_produzione))
                    .con("CarT", Valore::Piccolo(causale.carico_trasferimento))
                    .con("ScaV", Valore::Piccolo(causale.scarico_vendita))
                    .con("ScaP", Valore::Piccolo(causale.scarico_produzione))
                    .con("ScaT", Valore::Piccolo(causale.scarico_trasferimento))
            });
            righe.push((riga, movimento));
        }

        let totali = Record::nuovo("DOTotali")
            .con("Cambio", Valore::Decimale(Decimal::ONE))
            .con("TotImponibileV", Valore::Decimale(castelletto.totale_imponibile))
            .con("TotImponibileE", Valore::Decimale(castelletto.totale_imponibile))
            .con("TotImpostaV", Valore::Decimale(castelletto.totale_imposta))
            .con("TotImpostaE", Valore::Decimale(castelletto.totale_imposta))
            .con("TotDocumentoV", Valore::Decimale(castelletto.totale_documento))
            .con("TotDocumentoE", Valore::Decimale(castelletto.totale_documento))
            .con("TotMerceLordoV", Valore::Decimale(merce_lordo))
            .con("TotMerceNettoV", Valore::Decimale(merce_netto))
            .con("TotaPagareV", Valore::Decimale(da_pagare))
            .con("TotaPagareE", Valore::Decimale(da_pagare));

        let iva = castelletto
            .righe
            .iter()
            .map(|riga| {
                Record::nuovo("DOIva")
                    .con("Cd_Aliquota", Valore::testo(riga.aliquota.as_str()))
                    .con("Aliquota", Valore::Decimale(riga.percentuale))
                    .con("Cambio", Valore::Decimale(Decimal::ONE))
                    .con("ImponibileV", Valore::Decimale(riga.imponibile))
                    .con("ImpostaV", Valore::Decimale(riga.imposta))
                    .con("Omaggio", Valore::Byte(1))
                    .con(
                        "ImpostaV_NA",
                        Valore::Decimale(arrotonda(
                            riga.imponibile * riga.percentuale / Decimal::ONE_HUNDRED,
                            DECIMALI_IMPOSTA_NA,
                        )),
                    )
            })
            .collect();

        Ok(TabelleArca {
            testata,
            righe,
            totali,
            iva,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{CausaleMagazzino, TipoDocumentoArca};
    use atlas_core::aliquota::{CodiceAliquota, TabellaAliquote};
    use atlas_core::riga::Pesata;
    use chrono::NaiveDate;
    use rust_decimal_macros::dec;

    fn config() -> ConfigArca {
        ConfigArca {
            documento: TipoDocumentoArca {
                codice: "BO".into(),
                tipo: "B".into(),
                bitmask: 4,
                cli_for: "C".into(),
                sezionale: "D00".into(),
                causale_magazzino: "003".into(),
                aspetto_beni: Some("AV".into()),
                trasporto: Some("V".into()),
                spedizione: Some("M".into()),
                porto: Some("F".into()),
                listino: Some("0000001".into()),
                esecutivo: true,
                prelevabile: true,
                modificabile: true,
            },
            causale: CausaleMagazzino {
                partenza: true,
                arrivo: false,
                magazzino_partenza: Some("00001".into()),
                descrizione_movimento: 18,
                carico_acquisto: 0,
                carico_produzione: 0,
                carico_trasferimento: 0,
                scarico_vendita: 1,
                scarico_produzione: 0,
                scarico_trasferimento: 0,
                reso: 0,
            },
            valuta: "EUR".into(),
            decimali: 2,
            decimali_prezzo: 3,
            aliquote: [("04", dec!(4)), ("10", dec!(10))]
                .into_iter()
                .map(|(c, p)| (CodiceAliquota::nuovo(c), p))
                .collect::<TabellaAliquote>(),
        }
    }

    fn riga(colli: Decimal, lordo: Decimal, tara: Decimal, prezzo: Decimal, aliquota: &str) -> RigaDdt {
        RigaDdt {
            articolo: "BAN".into(),
            descrizione: "BANANE".into(),
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
            magazzino: None,
        }
    }

    fn ddt(righe: Vec<RigaDdt>) -> Ddt {
        let registrato_il = NaiveDate::from_ymd_opt(2026, 10, 21).unwrap().and_hms_opt(15, 57, 0).unwrap();
        Ddt {
            numero: 5455,
            data: NaiveDate::from_ymd_opt(2026, 10, 22).unwrap(),
            cliente: "C000380".into(),
            destinazione: Some("ALI".into()),
            sede: None,
            pagamento: Some("B030".into()),
            listino_cliente: None,
            iban: None,
            bic: None,
            conto_banca: None,
            agente: None,
            inizio_trasporto: Some(registrato_il),
            scissione_pagamenti: false,
            operatore: "190".into(),
            registrato_il,
            righe,
        }
    }

    fn decimale(record: &Record, colonna: &str) -> Decimal {
        match record.valore(colonna) {
            Some(Valore::Decimale(d)) => *d,
            altro => panic!("{colonna}: {altro:?}"),
        }
    }

    #[test]
    fn numero_su_sei_posizioni_piu_quattro_spazi() {
        assert_eq!(numero_documento(5455).unwrap(), "  5455    ");
        assert_eq!(numero_documento(999_999).unwrap(), "999999    ");
        assert!(numero_documento(0).is_err());
        assert!(numero_documento(1_000_000).is_err());
    }

    #[test]
    fn righe_movimenti_e_totali() {
        // 2 colli da 10,5 kg lordi con tara 0,35: netto 9,8 kg a 1,20 = 11,76.
        let tabelle = ddt(vec![
            riga(dec!(2), dec!(10.5), dec!(0.35), dec!(1.2), "04"),
            riga(dec!(1), dec!(0), dec!(0), dec!(2.39), "10"),
            riga(dec!(0), dec!(0), dec!(0), dec!(3), "04"),
        ])
        .in_tabelle(&config())
        .unwrap();

        let (prima, movimento) = &tabelle.righe[0];
        assert_eq!(decimale(prima, "Qta"), dec!(9.8));
        assert_eq!(decimale(prima, "QtaEvadibile"), dec!(9.8));
        assert_eq!(decimale(prima, "PrezzoTotaleV"), dec!(11.76));
        let movimento = movimento.as_ref().unwrap();
        assert_eq!(decimale(movimento, "Quantita"), dec!(9.8));
        assert_eq!(decimale(movimento, "Valore"), dec!(11.76));
        assert_eq!(movimento.valore("ScaV"), Some(&Valore::Piccolo(1)));
        // Riga a quantità zero: nessuno scarico.
        assert!(tabelle.righe[2].1.is_none());

        assert_eq!(decimale(&tabelle.totali, "TotImponibileV"), dec!(14.15));
        assert_eq!(decimale(&tabelle.totali, "TotImpostaV"), dec!(0.71));
        assert_eq!(decimale(&tabelle.totali, "TotDocumentoV"), dec!(14.86));
        assert_eq!(decimale(&tabelle.totali, "TotaPagareV"), dec!(14.86));
        assert_eq!(tabelle.iva.len(), 2);
        // 11,76 × 4% = 0,4704: arrotondata 0,47, conservata intera in ImpostaV_NA.
        assert_eq!(decimale(&tabelle.iva[0], "ImpostaV"), dec!(0.47));
        assert_eq!(decimale(&tabelle.iva[0], "ImpostaV_NA"), dec!(0.4704));
        assert_eq!(tabelle.testata.valore("RigheMerce"), Some(&Valore::Piccolo(3)));
    }

    #[test]
    fn merce_lordo_somma_le_righe_arrotondate_prima_dello_sconto() {
        // BO 97126: 1 × 1,20 con sconto 1+1 → netto 1,18, lordo 1,20.
        let mut scontata = riga(dec!(1), dec!(0), dec!(0), dec!(1.2), "04");
        scontata.sconto_riga = "1".into();
        scontata.sconto_addizionale = "1".into();
        let tabelle = ddt(vec![scontata, riga(dec!(1), dec!(0.333), dec!(0), dec!(1.005), "04")])
            .in_tabelle(&config())
            .unwrap();
        let (prima, _) = &tabelle.righe[0];
        assert_eq!(decimale(prima, "PrezzoTotaleV"), dec!(1.18));
        assert_eq!(decimale(prima, "FattoreScontoRiga"), dec!(0.01));
        assert_eq!(decimale(prima, "FattoreScontoTotale"), dec!(0.0199));
        // 0,333 × 1,005 = 0,334665 → 0,33 per riga; 1,20 + 0,33 = 1,53.
        assert_eq!(decimale(&tabelle.totali, "TotMerceLordoV"), dec!(1.53));
        assert_eq!(decimale(&tabelle.totali, "TotMerceNettoV"), dec!(1.51));
    }

    #[test]
    fn quantita_forzata_prevale_sulla_pesata() {
        // BO 102363 riga 13: pesata 0,68 kg, quantità azzerata a mano → niente importo né scarico.
        let mut azzerata = riga(dec!(1), dec!(0.68), dec!(0), dec!(7.4), "04");
        azzerata.quantita_forzata = Some(Decimal::ZERO);
        let tabelle = ddt(vec![azzerata, riga(dec!(1), dec!(1), dec!(0), dec!(2.5), "04")])
            .in_tabelle(&config())
            .unwrap();
        let (prima, movimento) = &tabelle.righe[0];
        assert_eq!(decimale(prima, "Qta"), Decimal::ZERO);
        assert_eq!(decimale(prima, "PrezzoTotaleV"), Decimal::ZERO);
        assert_eq!(decimale(prima, "xLordo"), dec!(0.68));
        assert!(movimento.is_none());
        assert_eq!(decimale(&tabelle.totali, "TotImponibileV"), dec!(2.5));
    }

    #[test]
    fn documento_non_esecutivo_senza_movimenti() {
        let mut cfg = config();
        cfg.documento.esecutivo = false;
        let tabelle = ddt(vec![riga(dec!(1), dec!(0), dec!(0), dec!(1), "04")]).in_tabelle(&cfg).unwrap();
        assert!(tabelle.righe.iter().all(|(_, m)| m.is_none()));
    }

    #[test]
    fn senza_righe_rifiutato() {
        assert!(ddt(Vec::new()).in_tabelle(&config()).is_err());
    }
}
