//! Prove di lettura sul clone di Arca: girano solo con `cargo test -- --ignored` e
//! `ATLAS_ARCA_ADO` impostata (SQL Server raggiungibile).

#![allow(clippy::unwrap_used, clippy::expect_used)]

use atlas_arca::{lettura, scrittura};

async fn connetti() -> scrittura::Connessione {
    let ado = std::env::var("ATLAS_ARCA_ADO").expect("ATLAS_ARCA_ADO non impostata");
    scrittura::connetti(&ado).await.unwrap()
}

/// BO 4832/2018 (Id_DoTes 5602): `DORig.Cd_AR` registrato con gli spazi finali. Letto con gli
/// spazi non trovava l'articolo nelle anagrafiche ATLAS e il documento veniva escluso.
#[tokio::test(flavor = "current_thread")]
#[ignore = "richiede il clone di Arca"]
async fn codice_articolo_del_2018_senza_spazi_finali() {
    let mut conn = connetti().await;
    let ddt = lettura::carica(&mut conn, 5602).await.unwrap();
    assert!(!ddt.righe.is_empty());
    for riga in &ddt.righe {
        assert_eq!(riga.articolo, riga.articolo.trim_end(), "articolo {:?}", riga.articolo);
    }
}
