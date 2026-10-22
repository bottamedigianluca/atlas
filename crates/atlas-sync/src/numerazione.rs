//! Numerazione unica: un DDT nato in ATLAS prende il numero che gli darebbe Arca, calcolato sui
//! documenti dei due sistemi.
//!
//! Al salvataggio ([`crea`]) si leggono da Arca i numeri occupati del sezionale nell'esercizio
//! (13-26 ms) e si uniscono a quelli del database ATLAS, nella transazione che scrive il
//! documento. Leggerli direttamente invece di fare prima un giro di importazione funziona anche
//! quando l'importazione è ferma su un conflitto, e non scrive nulla: nessuna concorrenza con il
//! worker. Se Arca non risponde entro l'attesa si numera sul solo database ATLAS, e il risultato
//! lo dice: l'operatore non aspetta la rete.
//!
//! Resta una finestra: Arca può usare lo stesso numero fra la lettura e la replica (o mentre era
//! irraggiungibile). Replica e importazione si fermano allora su un numero occupato, e il DDT
//! ATLAS, che in Arca non c'è ancora, si rinumera con [`rinumera`].

use std::time::Duration;

use atlas_core::ddt::Ddt;
use atlas_core::numerazione::{Numeri, Sezionale, TipoDocumento};
use atlas_db::Connection;
use atlas_db::ddt::{self, DdtSalvato};
use chrono::{Datelike, NaiveDateTime};

use crate::ErroreSync;
use crate::importazione::Origine;

/// Attesa massima dei numeri di Arca al salvataggio, connessione compresa se va aperta.
pub const ATTESA_ARCA: Duration = Duration::from_secs(1);

const SEZIONALE: Sezionale = TipoDocumento::BollaVendita.sezionale();

/// Un DDT salvato con il suo numero (in `Ddt::numero`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Creato {
    pub salvato: DdtSalvato,
    /// Perché il numero è stato calcolato senza i documenti di Arca, se è successo: va detto
    /// all'operatore, il numero potrebbe risultare occupato alla replica.
    pub senza_arca: Option<String>,
}

/// I numeri di Arca, se arrivano entro `attesa`; altrimenti il motivo, da mostrare
/// all'operatore. Una richiesta fallita o abbandonata chiude la connessione, che resterebbe in
/// uno stato incerto.
pub async fn numeri_di_arca(origine: &mut impl Origine, esercizio: i32, attesa: Duration) -> Result<Numeri, String> {
    let esito = match tokio::time::timeout(attesa, origine.numeri(SEZIONALE, esercizio)).await {
        Ok(Ok(numeri)) => return Ok(numeri),
        Ok(Err(e)) => e.to_string(),
        Err(_) => format!("Arca non ha risposto entro {} ms", attesa.as_millis()),
    };
    origine.scollega();
    Err(esito)
}

/// Salva un nuovo DDT con il prossimo numero sui documenti di ATLAS e di Arca, e accoda la sua
/// replica. Il numero finisce in `ddt.numero`.
pub async fn crea(
    db: &mut Connection,
    origine: &mut impl Origine,
    ddt: &mut Ddt,
    adesso: NaiveDateTime,
    attesa: Duration,
) -> Result<Creato, ErroreSync> {
    let (arca, senza_arca) = match numeri_di_arca(origine, ddt.data.year(), attesa).await {
        Ok(numeri) => (numeri, None),
        Err(motivo) => (Numeri::default(), Some(motivo)),
    };
    let salvato = ddt::crea(db, ddt, &arca, adesso)?;
    Ok(Creato { salvato, senza_arca })
}

/// Dà un nuovo numero al DDT ATLAS `id`, il cui numero in Arca è di un altro documento. Serve
/// Arca: rinumerare alla cieca potrebbe prendere un altro numero già usato. Restituisce il nuovo
/// numero.
///
/// Rifiuta se in Arca quel numero è libero (il blocco ha un'altra causa) o se il documento che
/// lo occupa ha lo stesso cliente e lo stesso istante di salvataggio: è quasi certamente questo
/// DDT, replicato e poi modificato in Arca prima che ATLAS ne registrasse l'esito, e
/// rinumerarlo lo scriverebbe una seconda volta.
pub async fn rinumera(db: &mut Connection, origine: &mut impl Origine, id: i64) -> Result<u32, ErroreSync> {
    let documento = ddt::carica(db, id)?;
    let esercizio = documento.data.year();
    let occupante = origine
        .con_numero(SEZIONALE, esercizio, documento.numero)
        .await?
        .ok_or(ErroreSync::NessunConflitto {
            esercizio,
            numero: documento.numero,
        })?;
    if occupante.cliente.eq_ignore_ascii_case(&documento.cliente) && occupante.registrato_il == documento.registrato_il {
        return Err(ErroreSync::ForseLoStesso {
            numero: documento.numero,
            id_testata: occupante.id_testata,
        });
    }
    let arca = origine.numeri(SEZIONALE, esercizio).await?;
    Ok(ddt::rinumera(db, id, &arca)?)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::finta::Finta;
    use crate::importazione::giro;
    use atlas_db::ErroreDb;
    use atlas_db::outbox;
    use atlas_db::prova::{self, adesso};

    fn conteso(numero: u32) -> Ddt {
        let mut altro = prova::ddt(numero);
        altro.cliente = "C000002".into();
        altro.destinazione = None;
        altro
    }

    #[tokio::test(flavor = "current_thread")]
    async fn numera_dopo_i_documenti_di_arca_non_ancora_importati() {
        let mut db = prova::database();
        let mut arca = Finta::nuova();
        arca.scrivi(100, Ok(prova::ddt(7)));
        let mut nuovo = prova::ddt(0);
        let creato = crea(&mut db, &mut arca, &mut nuovo, adesso(), ATTESA_ARCA).await.unwrap();
        assert_eq!((nuovo.numero, creato.senza_arca), (8, None));
        assert_eq!(ddt::carica(&db, creato.salvato.id).unwrap(), nuovo);
    }

    #[tokio::test(flavor = "current_thread")]
    async fn senza_arca_numera_sul_database_atlas_e_lo_dice() {
        let mut db = prova::database();
        ddt::salva(&mut db, &prova::ddt(5), adesso()).unwrap();
        let mut arca = Finta::nuova();
        arca.scrivi(100, Ok(prova::ddt(7)));
        arca.spenta = true;
        let mut nuovo = prova::ddt(0);
        let creato = crea(&mut db, &mut arca, &mut nuovo, adesso(), ATTESA_ARCA).await.unwrap();
        assert_eq!(nuovo.numero, 6);
        assert!(creato.senza_arca.unwrap().contains("rete"));
        assert_eq!(arca.scollegata, 1);

        arca.spenta = false;
        arca.ritardo = Some(Duration::from_millis(200));
        let creato = crea(&mut db, &mut arca, &mut nuovo, adesso(), Duration::from_millis(20)).await.unwrap();
        assert_eq!(nuovo.numero, 7);
        assert_eq!(creato.senza_arca.unwrap(), "Arca non ha risposto entro 20 ms");
        assert_eq!(arca.scollegata, 2);
    }

    /// Il caso che la numerazione unica lascia aperto: lo stesso numero salvato nei due sistemi
    /// mentre Arca era irraggiungibile. Si fermano replica e importazione; dopo la
    /// rinumerazione ripartono e nessun numero è doppio.
    #[tokio::test(flavor = "current_thread")]
    async fn collisione_risolta_rinumerando_il_ddt_atlas() {
        let mut db = prova::database();
        let mut arca = Finta::nuova();
        arca.scrivi(100, Ok(prova::ddt(1)));
        giro(&mut db, &mut arca, adesso, 10).await.unwrap();

        arca.spenta = true;
        let mut nostro = prova::ddt(0);
        let creato = crea(&mut db, &mut arca, &mut nostro, adesso(), ATTESA_ARCA).await.unwrap();
        assert_eq!(nostro.numero, 2);
        arca.spenta = false;
        arca.scrivi(101, Ok(conteso(2)));
        arca.scrivi(102, Ok(conteso(3)));
        let fermo = giro(&mut db, &mut arca, adesso, 10).await.unwrap().fermo.unwrap();
        assert_eq!(fermo.0, 101);

        assert_eq!(rinumera(&mut db, &mut arca, creato.salvato.id).await.unwrap(), 4);
        let evento = outbox::evento(&db, creato.salvato.evento).unwrap();
        assert_eq!(evento.ddt().unwrap().numero, 4);
        let giro = giro(&mut db, &mut arca, adesso, 10).await.unwrap();
        assert_eq!((giro.nuovi, giro.fermo), (2, None));
        let errore = rinumera(&mut db, &mut arca, creato.salvato.id).await.unwrap_err();
        assert!(matches!(errore, ErroreSync::NessunConflitto { numero: 4, .. }), "{errore}");
    }

    #[tokio::test(flavor = "current_thread")]
    async fn non_rinumera_lo_stesso_documento_modificato_in_arca() {
        let mut db = prova::database();
        let mut arca = Finta::nuova();
        let creato = ddt::salva(&mut db, &prova::ddt(2), adesso()).unwrap();
        // Replicato (esito perso) e poi modificato in Arca: stesso cliente, stesso TimeIns.
        let mut modificato = prova::ddt(2);
        modificato.righe.truncate(1);
        arca.scrivi(101, Ok(modificato));
        let errore = rinumera(&mut db, &mut arca, creato.id).await.unwrap_err();
        assert!(matches!(errore, ErroreSync::ForseLoStesso { numero: 2, id_testata: 101 }), "{errore}");
        assert_eq!(ddt::carica(&db, creato.id).unwrap().numero, 2);
        let errore = rinumera(&mut db, &mut arca, 999).await.unwrap_err();
        assert!(matches!(errore, ErroreSync::Db(ErroreDb::Sqlite(_) | ErroreDb::NonTrovato(_))), "{errore}");
    }
}
