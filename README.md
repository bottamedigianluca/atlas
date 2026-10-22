# ATLAS

Gestionale di Bottamedi Pierluigi, successore di Arca Evolution.

```
crates/atlas-core     regole di dominio pure (pesata, importi, IVA, pagamenti, fatturazione differita)
crates/atlas-verify   collaudo del motore contro lo storico Arca, in sola lettura
crates/atlas-arca     replica dei DDT nelle tabelle di Arca (DOTes, DORig, MGMov, DOTotali, DOIva)
crates/atlas-db       database primario ATLAS (SQLite WAL) con outbox di replica
crates/atlas-sync     import anagrafiche e documenti da Arca, worker di replica dell'outbox, numerazione unica
crates/atlas-server   backend Axum: API REST e WebSocket, worker unico scrittore (numerazione, replica, importazione)
app/                  frontend desktop: React + TypeScript + Tailwind (finestra "Gestione Documenti" come in Arca)
app/src-tauri         shell Tauri v2 (finestra nativa, installer NSIS/MSI); fuori dal workspace Cargo
docs/ANALISI_ARCA.md  comportamento reale di Arca, misurato sui dati
TASKS.md              stato del lavoro, decisioni aperte, vincoli
```

## Requisiti

- Rust 1.87 (MSVC) con Visual Studio Build Tools 2022, carico di lavoro "Sviluppo di applicazioni desktop C++".
- Per l'app desktop: Node.js 22 e WebView2 (già presente in Windows 10/11).

## Comandi

```powershell
cargo test --workspace
$env:ATLAS_ARCA_ADO = "server=tcp:PCARCA-2023,1433;database=ADB_BOTTAMEDI;user=bihortus_reader;password=<...>;TrustServerCertificate=true"
cargo run --release -p atlas-verify -- 2025-01-01 2026-12-31
```

`atlas-verify` termina con codice 0 solo se ogni documento del periodo è riprodotto esattamente.

```powershell
# sola lettura su Arca
cargo run --release -p atlas-sync --bin importa-documenti -- dati\prova.sqlite --una-volta  # BO di Arca nel database ATLAS
cargo run --release -p atlas-sync --bin verifica-importazione -- dati\prova.sqlite         # database ATLAS contro Arca
cargo run --release -p atlas-sync --bin verifica-numerazione -- dati\prova.sqlite 2026    # numerazione ATLAS contro le funzioni di Arca
```

```powershell
# solo sul clone: il programma rifiuta i database che non finiscono in _DEV
$env:ATLAS_ARCA_DEV_ADO = "server=tcp:localhost,1433;database=ADB_BOTTAMEDI_DEV;IntegratedSecurity=SSPI;TrustServerCertificate=true"
cargo run --release -p atlas-arca --bin prova-ddt -- rigioca 2026-01-01 2026-12-31   # replica e annulla, confronto colonna per colonna
cargo run --release -p atlas-arca --bin prova-ddt -- scrivi 108602                   # DDT di prova confermato, righe del BO 108602
cargo run --release -p atlas-arca --bin prova-ddt -- confronta 108602 120546         # BO già scritto contro il suo modello
cargo run --release -p atlas-sync --bin prova-replica -- nuovo dati\prova.sqlite 108602   # DDT nuovo in ATLAS, numerato con Arca, in coda
cargo run --release -p atlas-sync --bin prova-replica -- nuovo dati\prova.sqlite 108601 --senza-arca  # numerato come con Arca spenta
cargo run --release -p atlas-sync --bin prova-replica -- rinumera dati\prova.sqlite ID    # risolve un numero preso in Arca nel frattempo
cargo run --release -p atlas-sync --bin replica -- dati\prova.sqlite --una-volta          # worker: svuota la coda ed esce
```

```powershell
# backend: legge e scrive solo il database ATLAS; con ATLAS_ARCA_ADO numera con Arca, replica (solo *_DEV) e importa
$env:ATLAS_ARCA_ADO = "server=tcp:localhost,1433;database=ADB_BOTTAMEDI_DEV;IntegratedSecurity=SSPI;TrustServerCertificate=true"
cargo run --release -p atlas-server -- dati\prova.sqlite                     # http://127.0.0.1:7878/api, WebSocket /api/ws
cargo run --release -p atlas-server --bin misura-latenze -- dati\atlas.sqlite  # latenze delle API su una copia del file
```

API del backend (dettagli in `crates/atlas-server/src/rotte.rs`): `POST /api/ddt/calcola` (pesata e totali in tempo
reale), `POST /api/ddt` (salvataggio con numerazione unica), `GET /api/prezzi` (tasto F3), `GET /api/ddt`,
`GET /api/ddt/{id}`, `GET /api/stato` (replica, importazione, conflitti), `POST /api/ddt/{id}/rinumera`,
`GET /api/numerazione/{anno}/liberi`, `GET /api/home/clienti` (clienti del giorno), `GET /api/home/riepilogo`,
`GET /api/partita-iva/{numero}` (dati dell'azienda da VIES), `GET/POST/PUT/DELETE /api/note`
(post-it della Home), anagrafiche, `GET /api/strumenti` (JSON Schema per assistenti).

```powershell
# app desktop (il backend deve essere avviato: indirizzo predefinito http://127.0.0.1:7878, modificabile con F1)
cd app
npm ci
npm run tauri dev        # finestra nativa con ricarica a caldo
npm run tauri build      # installer in app\src-tauri\target\release\bundle (NSIS e MSI)
npm test                 # regole di tastiera e layout della griglia (vitest)
npm run e2e              # prove end-to-end su una copia di dati\atlas.sqlite (Playwright; npx playwright install chromium la prima volta)
```

La finestra ricalca "Gestione Documenti" di Arca (pagine Elenco, Generale, DMS; schede Testa, Righe, Piede, Totali,
Info, Evasioni, Stampe; F3 "PREZZO/COSTO ARTICOLO"), con numeri a punto decimale e date GG-MM-AAAA come in Arca.
All'avvio c'è la Home (`Ctrl+0`), con il menu di Arca e i widget: clienti da chiamare oggi, post-it condiviso, DDT di oggi, numeri liberi.
Tasti: `Invio` avanti (Articolo → UM → Colli → Lordo → Tara → Prezzo → nuova riga), `↓` riga sotto o nuova riga
sull'articolo, `F3` ricerca cliente/articolo/destinazione, prezzi (sul prezzo), numeri liberi (sul numero), `Ctrl+N`
nuovo, `F10` salva, `F12` salva e stampa, `Alt+←/→` documento precedente/successivo (`Alt+Home/Fine` primo/ultimo), `Esc` annulla la cella, `Ctrl+Canc` elimina riga, `Ctrl+PgSu/PgGiù` schede,
`Ctrl+1/2/3` pagine Elenco/Generale/DMS, clic destro sulle intestazioni per le colonne, `F1` informazioni.
