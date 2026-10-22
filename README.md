# ATLAS

Gestionale di Bottamedi Pierluigi, successore di Arca Evolution.

```
crates/atlas-core     regole di dominio pure (pesata, importi, IVA, pagamenti, fatturazione differita)
crates/atlas-verify   collaudo del motore contro lo storico Arca, in sola lettura
crates/atlas-arca     replica dei DDT nelle tabelle di Arca (DOTes, DORig, MGMov, DOTotali, DOIva)
crates/atlas-db       database primario ATLAS (SQLite WAL) con outbox di replica
crates/atlas-sync     import anagrafiche e documenti da Arca, worker di replica dell'outbox, numerazione unica
docs/ANALISI_ARCA.md  comportamento reale di Arca, misurato sui dati
TASKS.md              stato del lavoro, decisioni aperte, vincoli
```

## Requisiti

- Rust 1.87 (MSVC) con Visual Studio Build Tools 2022, carico di lavoro "Sviluppo di applicazioni desktop C++".

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
