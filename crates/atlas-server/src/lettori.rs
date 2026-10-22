//! Connessioni di sola lettura al database ATLAS per le richieste HTTP e WebSocket.
//!
//! SQLite in WAL lascia leggere mentre l'unico scrittore (il worker) scrive: le letture non
//! aspettano mai un salvataggio né la rete. Le connessioni restano aperte con le istruzioni già
//! preparate (`prepare_cached`), così una lettura costa le sole pagine toccate.

use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};

use rusqlite::Connection;
use tokio::sync::Semaphore;

use crate::errore::ErroreApi;

#[derive(Debug)]
pub struct Lettori {
    percorso: PathBuf,
    libere: Mutex<Vec<Connection>>,
    posti: Arc<Semaphore>,
}

impl Lettori {
    /// Apre `quante` connessioni; il database deve essere già migrato dallo scrittore.
    pub fn apri(percorso: &Path, quante: usize) -> Result<Arc<Self>, ErroreApi> {
        let quante = quante.max(1);
        let libere = (0..quante)
            .map(|_| atlas_db::apri_lettura(percorso))
            .collect::<Result<Vec<_>, _>>()?;
        Ok(Arc::new(Self {
            percorso: percorso.to_owned(),
            libere: Mutex::new(libere),
            posti: Arc::new(Semaphore::new(quante)),
        }))
    }

    /// Esegue `f` su una connessione libera, fuori dai thread asincroni.
    pub async fn leggi<T, F>(self: &Arc<Self>, f: F) -> Result<T, ErroreApi>
    where
        T: Send + 'static,
        F: FnOnce(&Connection) -> Result<T, ErroreApi> + Send + 'static,
    {
        let posto = Arc::clone(&self.posti)
            .acquire_owned()
            .await
            .map_err(|_| ErroreApi::NonDisponibile("server in chiusura".into()))?;
        let lettori = Arc::clone(self);
        tokio::task::spawn_blocking(move || {
            let conn = lettori.prendi()?;
            let esito = f(&conn);
            lettori.rendi(conn);
            drop(posto);
            esito
        })
        .await
        .map_err(|e| ErroreApi::Interno(format!("lettura interrotta: {e}")))?
    }

    fn prendi(&self) -> Result<Connection, ErroreApi> {
        let libera = self.libere.lock().ok().and_then(|mut l| l.pop());
        match libera {
            Some(conn) => Ok(conn),
            // Una connessione persa (lettura interrotta) si sostituisce.
            None => Ok(atlas_db::apri_lettura(&self.percorso)?),
        }
    }

    fn rendi(&self, conn: Connection) {
        if let Ok(mut libere) = self.libere.lock() {
            libere.push(conn);
        }
    }
}
