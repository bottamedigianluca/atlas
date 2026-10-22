//! Confronto fra il motore ATLAS e quanto registrato da Arca, controllo per controllo.

use std::collections::{BTreeMap, BTreeSet};
use std::fmt::Write as _;

use atlas_core::aliquota::CodiceAliquota;
use atlas_core::differita::{DdtDaFatturare, raggruppa, riga_riferimento_ddt};
use atlas_core::importo::Limitato;
use atlas_core::iva::Castelletto;
use atlas_core::numerazione::TipoDocumento;
use atlas_core::riga::{Pesata, RigaMerce, Sconto};

use crate::arca::{Documento, Riga, Storico};

const ESEMPI_PER_CONTROLLO: usize = 5;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Controllo {
    QuantitaNetta,
    FattoreSconto,
    TotaleRiga,
    CastellettoIva,
    TotaliDocumento,
    NettoAPagare,
    Scadenze,
    RiferimentiDdt,
    RaggruppamentoFattura,
    /// Fattura differita compilata a mano in Arca, senza righe collegate ai DDT: non è una
    /// regola di ATLAS, è un'anomalia dello storico che va conosciuta.
    DifferitaSenzaCollegamenti,
}

impl Controllo {
    pub fn nome(self) -> &'static str {
        match self {
            Self::QuantitaNetta => "Quantita' netta da pesata (righe)",
            Self::FattoreSconto => "Fattore sconto (righe)",
            Self::TotaleRiga => "Totale riga (righe)",
            Self::CastellettoIva => "Castelletto IVA (documenti)",
            Self::TotaliDocumento => "Totali documento (documenti)",
            Self::NettoAPagare => "Netto a pagare (documenti)",
            Self::Scadenze => "Scadenze (documenti)",
            Self::RiferimentiDdt => "Righe di riferimento DDT (fatture differite)",
            Self::RaggruppamentoFattura => "Raggruppamento DDT in fattura (fatture differite)",
            Self::DifferitaSenzaCollegamenti => "Fattura differita collegata ai DDT (fatture differite)",
        }
    }
}

#[derive(Debug, Default)]
pub struct Esito {
    pub conformi: u64,
    pub difformi: u64,
    pub esempi: Vec<String>,
}

#[derive(Debug, Default)]
pub struct Rapporto {
    pub esiti: BTreeMap<(Controllo, TipoDocumento), Esito>,
}

impl Rapporto {
    fn registra(&mut self, controllo: Controllo, tipo: TipoDocumento, conforme: bool, dettaglio: impl FnOnce() -> String) {
        let esito = self.esiti.entry((controllo, tipo)).or_default();
        if conforme {
            esito.conformi += 1;
        } else {
            esito.difformi += 1;
            if esito.esempi.len() < ESEMPI_PER_CONTROLLO {
                esito.esempi.push(dettaglio());
            }
        }
    }

    pub fn difformi(&self) -> u64 {
        self.esiti.values().map(|e| e.difformi).sum()
    }

    pub fn testo(&self) -> String {
        let mut out = String::new();
        let _ = writeln!(out, "{:<52} {:>4} {:>10} {:>9}", "Controllo", "Tipo", "Conformi", "Difformi");
        for ((controllo, tipo), esito) in &self.esiti {
            let _ = writeln!(
                out,
                "{:<52} {:>4} {:>10} {:>9}",
                controllo.nome(),
                tipo.codice(),
                esito.conformi,
                esito.difformi
            );
        }
        for ((controllo, tipo), esito) in &self.esiti {
            for esempio in &esito.esempi {
                let _ = writeln!(out, "  [{} {}] {esempio}", controllo.nome(), tipo.codice());
            }
        }
        out
    }
}

pub fn esegui(storico: &Storico) -> Rapporto {
    let mut rapporto = Rapporto::default();
    for (id, doc) in &storico.documenti {
        verifica_righe(&mut rapporto, *id, doc);
        verifica_importi(&mut rapporto, storico, *id, doc);
        if doc.testata.tipo == TipoDocumento::FatturaDifferita {
            verifica_differita(&mut rapporto, storico, *id, doc);
        }
    }
    rapporto
}

fn rif(id: i32, doc: &Documento) -> String {
    format!("{} {} del {} (Id {id})", doc.testata.tipo, doc.testata.numero, doc.testata.data)
}

fn verifica_righe(rapporto: &mut Rapporto, id: i32, doc: &Documento) {
    let tipo = doc.testata.tipo;
    for riga in &doc.righe {
        if riga.colli.is_some() || riga.lordo.is_some() || riga.tara.is_some() {
            let atteso = Pesata::nuova(
                riga.colli.unwrap_or_default(),
                riga.lordo.unwrap_or_default(),
                riga.tara.unwrap_or_default(),
            )
            .map(|p| p.netto());
            let conforme = atteso.as_ref().is_ok_and(|q| *q == riga.qta);
            rapporto.registra(Controllo::QuantitaNetta, tipo, conforme, || {
                format!(
                    "{} riga {}: colli {:?} lordo {:?} tara {:?} -> ATLAS {:?}, Arca {}",
                    rif(id, doc),
                    riga.id,
                    riga.colli,
                    riga.lordo,
                    riga.tara,
                    atteso,
                    riga.qta
                )
            });
        }

        let sconto = Sconto::da_testi(&riga.sconto_riga, &riga.sconto_addizionale);
        let conforme = sconto.as_ref().is_ok_and(|s| s.fattore() == riga.fattore_sconto);
        rapporto.registra(Controllo::FattoreSconto, tipo, conforme, || {
            format!(
                "{} riga {}: \"{}\" + \"{}\" -> ATLAS {:?}, Arca {}",
                rif(id, doc),
                riga.id,
                riga.sconto_riga,
                riga.sconto_addizionale,
                sconto,
                riga.fattore_sconto
            )
        });

        let totale = riga_merce(riga).map(|r| r.totale());
        let conforme = totale.as_ref().is_ok_and(|t| *t == riga.totale);
        rapporto.registra(Controllo::TotaleRiga, tipo, conforme, || {
            format!(
                "{} riga {}: {} x {} -> ATLAS {:?}, Arca {}",
                rif(id, doc),
                riga.id,
                riga.qta,
                riga.prezzo,
                totale,
                riga.totale
            )
        });
    }
}

fn riga_merce(riga: &Riga) -> Result<RigaMerce, atlas_core::ErroreCalcolo> {
    Ok(RigaMerce {
        quantita: Limitato::nuovo("qta", riga.qta)?,
        prezzo_unitario: Limitato::nuovo("prezzo", riga.prezzo)?,
        prezzo_addizionale: Limitato::nuovo("addizionale", riga.addizionale)?,
        sconto: Sconto::da_testi(&riga.sconto_riga, &riga.sconto_addizionale)?,
        aliquota: riga.aliquota.clone(),
    })
}

fn verifica_importi(rapporto: &mut Rapporto, storico: &Storico, id: i32, doc: &Documento) {
    let tipo = doc.testata.tipo;
    let importi: Vec<(&CodiceAliquota, rust_decimal::Decimal)> = doc
        .righe
        .iter()
        .filter_map(|r| r.aliquota.as_ref().map(|a| (a, r.totale)))
        .chain(doc.spese.iter().filter_map(|s| s.aliquota.as_ref().map(|a| (a, s.importo))))
        .collect();
    let castelletto = match Castelletto::calcola(importi, &storico.aliquote) {
        Ok(c) => c,
        Err(errore) => {
            rapporto.registra(Controllo::CastellettoIva, tipo, false, || format!("{}: {errore}", rif(id, doc)));
            return;
        }
    };

    let mut arca: Vec<(&CodiceAliquota, _, _)> = doc.iva.iter().map(|r| (&r.aliquota, r.imponibile, r.imposta)).collect();
    arca.sort_by(|a, b| a.0.cmp(b.0));
    let atlas: Vec<(&CodiceAliquota, _, _)> = castelletto
        .righe
        .iter()
        .map(|r| (&r.aliquota, r.imponibile, r.imposta))
        .collect();
    rapporto.registra(Controllo::CastellettoIva, tipo, arca == atlas, || {
        format!("{}: ATLAS {atlas:?}, Arca {arca:?}", rif(id, doc))
    });

    let detrazioni = doc.totali.as_ref().map(|t| t.acconto + t.abbuono).unwrap_or_default();
    let scissione = doc.testata.scissione_pagamenti;
    if let Some(totali) = &doc.totali {
        let atteso = castelletto.netto_a_pagare(scissione, detrazioni);
        rapporto.registra(Controllo::NettoAPagare, tipo, totali.da_pagare == atteso, || {
            format!(
                "{}: ATLAS {atteso} (acconto {}, abbuono {}), Arca {}",
                rif(id, doc),
                totali.acconto,
                totali.abbuono,
                totali.da_pagare
            )
        });
        let conforme = totali.imponibile == castelletto.totale_imponibile
            && totali.imposta == castelletto.totale_imposta
            && totali.documento == castelletto.totale_documento;
        rapporto.registra(Controllo::TotaliDocumento, tipo, conforme, || {
            format!(
                "{}: ATLAS {}/{}/{}, Arca {}/{}/{}",
                rif(id, doc),
                castelletto.totale_imponibile,
                castelletto.totale_imposta,
                castelletto.totale_documento,
                totali.imponibile,
                totali.imposta,
                totali.documento
            )
        });
    }

    if !tipo.fiscale() {
        return;
    }
    let Some(codice) = &doc.testata.pagamento else { return };
    let Some(condizione) = storico.pagamenti.get(codice) else {
        rapporto.registra(Controllo::Scadenze, tipo, false, || format!("{}: pagamento {codice} sconosciuto", rif(id, doc)));
        return;
    };
    let atteso = condizione.scadenze(
        doc.testata.data,
        castelletto.totale_imponibile,
        castelletto.imposta_a_carico_cliente(scissione),
        detrazioni,
    );
    let segno = tipo.segno();
    let conforme = atteso.as_ref().is_ok_and(|s| {
        s.len() == doc.scadenze.len()
            && s.iter()
                .zip(&doc.scadenze)
                .all(|(a, b)| a.data == b.data && a.importo * segno == b.importo)
    });
    rapporto.registra(Controllo::Scadenze, tipo, conforme, || {
        let arca: Vec<_> = doc.scadenze.iter().map(|s| (s.data, s.importo)).collect();
        let atlas: Result<Vec<_>, _> = atteso.as_ref().map(|v| v.iter().map(|s| (s.data, s.importo)).collect::<Vec<_>>());
        format!("{} [{codice}]: ATLAS {atlas:?}, Arca {arca:?}", rif(id, doc))
    });
}

fn verifica_differita(rapporto: &mut Rapporto, storico: &Storico, id: i32, doc: &Documento) {
    let tipo = doc.testata.tipo;
    let mut ddt: BTreeMap<i32, &crate::arca::Testata> = BTreeMap::new();
    for riga in &doc.righe {
        if let Some((id_ddt, testata)) = riga.evade.and_then(|e| storico.ddt_per_riga.get(&e)) {
            ddt.insert(*id_ddt, testata);
        }
    }
    rapporto.registra(Controllo::DifferitaSenzaCollegamenti, tipo, !ddt.is_empty(), || {
        let riferimenti: Vec<&str> = doc
            .righe
            .iter()
            .filter(|r| r.descrizione.starts_with("D.D.T."))
            .map(|r| r.descrizione.as_str())
            .collect();
        format!("{} cliente {}: righe scritte a mano {riferimenti:?}", rif(id, doc), doc.testata.cliente)
    });
    if ddt.is_empty() {
        return;
    }

    let attesi: BTreeSet<String> = ddt.values().map(|t| riga_riferimento_ddt(t.numero, t.data)).collect();
    let trovati: BTreeSet<String> = doc
        .righe
        .iter()
        .filter(|r| r.articolo.is_none() && r.descrizione.starts_with("D.D.T."))
        .map(|r| r.descrizione.clone())
        .collect();
    rapporto.registra(Controllo::RiferimentiDdt, tipo, attesi == trovati, || {
        format!("{}: ATLAS {attesi:?}, Arca {trovati:?}", rif(id, doc))
    });

    let proposte = raggruppa(ddt.iter().map(|(id_ddt, t)| DdtDaFatturare {
        id: i64::from(*id_ddt),
        numero: t.numero,
        data: t.data,
        cliente: t.cliente.clone(),
        pagamento: t.pagamento.clone().unwrap_or_default(),
    }));
    let conforme = proposte.len() == 1
        && proposte.iter().all(|p| {
            p.cliente == doc.testata.cliente && Some(&p.pagamento) == doc.testata.pagamento.as_ref()
        });
    rapporto.registra(Controllo::RaggruppamentoFattura, tipo, conforme, || {
        let gruppi: Vec<_> = proposte.iter().map(|p| (p.cliente.as_str(), p.pagamento.as_str(), p.ddt.len())).collect();
        format!(
            "{} cliente {} pagamento {:?}: gruppi ATLAS {gruppi:?}",
            rif(id, doc),
            doc.testata.cliente,
            doc.testata.pagamento
        )
    });
}
