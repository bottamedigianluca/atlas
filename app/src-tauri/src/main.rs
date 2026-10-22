//! ATLAS desktop: una finestra nativa sul frontend (`app/`), che parla con il backend
//! `atlas-server` via HTTP e WebSocket (indirizzo nelle Informazioni, F1). Nessuna logica qui:
//! documenti, calcoli e sincronizzazione sono tutti nel backend.

// Senza console su Windows in release.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::process::ExitCode;

fn main() -> ExitCode {
    match tauri::Builder::default().run(tauri::generate_context!()) {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("ATLAS: {e}");
            ExitCode::FAILURE
        }
    }
}
