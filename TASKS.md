# TASKS — ATLAS ERP

Documento supremo di riferimento: `docs/DIRETTIVA_ARCHITETTURALE_ATLAS.md` (visione State-Of-The-Art, doppia compatibilità con Shadow Sync Outbox verso Arca, lookup prezzi F3, ergonomia keyboard-first, gestione cancellazioni e buchi, Second Brain).

## REGOLA FONDAMENTALE DI LAVORO
- **VIETATO ESEGUIRE DECOMPILATORI**: Non usare mai strumenti come `ilspycmd`, `dotnet-dump` o altri tool binari, e non estrarre assembly da SQL Server.
- **TUTTO IL CODICE È GIÀ ESTRATTO IN CHIARO**: Tutti i sorgenti di Arca e delle personalizzazioni sono **già presenti come file di testo** nella cartella `docs/sorgenti_arca_decompilati/` (inclusi i 51.373 righe di `02_SORGENTI_FOXPRO_VFP/fedi_doc_extracted.prg` e i file in `pers_bottamedi/`). Consulta **SOLO** questi file già aperti ed estratti per capire strutture tabelle, campi e logiche.

## OBIETTIVO CHIAVE: DOPPIA COMPATIBILITÀ (SHADOW SYNC)
- ATLAS opera con **doppia compatibilità**: ogni documento creato in ATLAS viene salvato sia nel DB primario sia replicato fedelmente nel database di Arca su SQL Server (`ADB_BOTTAMEDI_DEV` in test, e poi produzione).
- Arca Evolution deve poter aprire, visualizzare, stampare e gestire i documenti come se fossero nati dentro Arca stessa, in totale trasparenza ("senza che Arca se ne accorga").
- **Come scrivere su Arca senza blocchi**:
  Poiché le stored procedure native hanno vincoli interni, la replica su SQL Server popola **direttamente le tabelle relazionali** (`DOTes`, `DORig`, `DOTotali`, `DOIva`, `MGMov`, `SC`) sul database clone `ADB_BOTTAMEDI_DEV`. I campi e i calcoli da inserire sono quelli già verificati al 100% in `atlas-core` e documentati riga per riga in `fedi_doc_extracted.prg`.

## Fatto
- [x] 21-22/10/2026 Analisi completa dei dati e delle personalizzazioni ortofrutta su DB reale.
- [x] Workspace Rust: `atlas-core` (pesata, sconti a cascata, netto merce, castelletto IVA, scadenze DF FM, sezionali, raggruppamento differita, formattazione riga riferimento DDT) con test unitari sui casi reali.
- [x] `atlas-verify`: ripasso dello storico nel motore Rust, 8 controlli contabili per tipo documento, sola lettura.
- [x] Toolset C++ MSVC aggiunto ai Build Tools 2022 (cargo compila e linka correttamente).
- [x] 22 test unitari ok, clippy pulito. `atlas-verify` 2025-2026: 14.475 documenti verificati, 100% delle regole conformi. Storico 2018-2026: 60.496 documenti verificati in 11 secondi.
- [x] Regole contabili confermate e coperte da test: scissione dei pagamenti (Split Payment art. 17-ter), segno note di credito nello scadenziario, gestione acconti/abbuoni nel netto a pagare.
- [x] Griglia righe operatore decodificata: `docs/griglia_righe_userpref_1443.json` (40 colonne, ordine e larghezze esatte dell'interfaccia storica).
- [x] Clone `ADB_BOTTAMEDI_DEV` creato e verificato (restore COPY_ONLY, 60.502 testate).
- [x] Mappatura salvataggio da codice chiaro: sequenza di campi e tabelle verificata in `fedi_doc_extracted.prg:36395` (`DOTes`, `DORig`, `DOTotali`, `DOIva`, `MGMov`).

- [x] 22/10/2026 **Task 1, scrittura diretta delle tabelle sul clone** (`crates/atlas-arca`):
  - Scrittura nativa misurata con la finestra di rowversion del BO 108602: solo `DOTes`, `DORig`, `MGMov`, `DOTotali`, `DOIva`
    (nessuna tabella di saldi; `xAmk_*` sono mappature statiche del 2018).
  - Trigger: `DORig_atrg_brd` blocca l'INSERT (50000), `DOTes_atrg_brd` riscrive e blocca `UserIns/TimeIns` (900000).
    Vengono disattivati **dentro la transazione** (`ALTER TABLE … DISABLE TRIGGER`, transazionale: le altre sessioni
    attendono, un errore o un rollback li lascia attivi, verificato). `MGMov_atrg` resta attivo. Se i trigger presenti
    non sono esattamente quelli attesi la scrittura si rifiuta.
  - `prova-ddt rigioca 2026`: 5.452 BO riscritti, confrontati su 6.933.271 valori (tutte le colonne, anche calcolate e
    di default) e annullati. **5.452/5.452 identici** a meno delle colonne di ciclo di vita (evasione in FT su 5.039 BO,
    chiusura manuale su 42, modifiche successive su 923); ciascuna spiegata con una query. Esclusi 3 BO (non esecutivo,
    riga descrittiva, riga spesa). 1.899 s.
  - Quantità forzata a mano (BO 102363 riga 13: pesata 0,68, Qta 0) aggiunta al modello con test.
  - `prova-ddt scrivi 108602`: confermato il **BO 5457** (Id_DoTes 120545): 1.970 valori uguali al modello, 31 diversi
    (solo gli istanti di salvataggio). `UnusedCodes_DoTes` di Arca lo vede e propone 5458. 6 test unitari, clippy pulito.

- [x] 22/10/2026 **Task 1 chiuso**: il titolare ha controllato il BO 5457 sul clone (senza aprirlo in Arca, per non
  alterarlo): perfetto.

- [x] 22/10/2026 **Task 2, database primario ATLAS + outbox** (SQLite WAL, scelta del titolare):
  - `Ddt`/`RigaDdt` spostati in `atlas_core::ddt` (servono a DB, outbox e replica); in `atlas-arca` la traduzione è il
    trait `InTabelle`, il lettore dei BO nativi è `atlas_arca::lettura` (ex `prova-ddt/nativo.rs`).
  - `crates/atlas-db` (rusqlite 0.37, SQLite incluso): schema `migrazioni/0001_iniziale.sql` versionato con
    `user_version`; WAL, `synchronous=FULL`, chiavi esterne attive. Tabelle STRICT, codici `COLLATE NOCASE` (Arca è
    `Latin1_General_CI_AS`), decimali in TEXT esatto. `ddt::salva` scrive testata, righe e evento `outbox_eventi` in
    **una** transazione; `outbox::{da_replicare, segna_replicato, segna_fallito, evento}` per il worker (ordine FIFO:
    un evento in riprova blocca i successivi). 17 test.
  - `crates/atlas-sync`: `importa-anagrafiche DB` (env `ATLAS_ARCA_ADO`, solo SELECT, upsert idempotente, non cancella,
    controllo chiavi esterne con elenco delle violazioni prima del commit). Sul clone: 13 tabelle, conteggi identici ad
    Arca (CF 404, AR 466, ARARMisura 518, CFDest 35, LS 14, LSRevisione 10, LSArticolo 475, PG 12, MG 10, Aliquota 11),
    83 ms; secondo giro 0 modifiche. DB in `dati/atlas.sqlite`.
  - `verifica-db [DAL] [AL] [FILE]`: tutti i BO 2025-2026 salvati in ATLAS: **11.881/11.881** salvati (ogni riferimento
    trova l'anagrafica), riletti identici, evento outbox identico, totali = `DOTotali`. Salvataggio su file con FULL:
    **1,15 ms a documento**; 63 MB per 11.881 BO.
  - Regole misurate: aliquota di riga = `AR.Cd_Aliquota_V`, altrimenti `Impostazione DEFAULT_RIGHE_DOC.Cd_Aliquota_2`
    (`04`): 101.090/101.094 righe 2025-2026 (4 eccezioni: MAISS cambiato nel 2026, FRU corretto a mano). Conto ricavo
    = `Cd_CGConto_2` (`07010101001`) 101.094/101.094. La funzione `DORig_Defaults_AliquotaConto` è cifrata e fuori da
    Arca restituisce vuoto: precedenza tra aliquota del cliente/destinazione e quella dell'articolo non verificabile
    (nessun cliente o destinazione ha un'aliquota). Testata: pagamento, listino, IBAN, agente, split dal cliente
    nel 99,8-100% dei BO.
  - Codici: senza spazi finali anche i `varchar` (Arca riempie `AR.Cd_AR` a 20 in 376 articoli, ma dal 11/2018 righe e
    listini lo registrano senza spazi: 931.730 righe). Descrizioni, indirizzi, IBAN, note: come in Arca.

- [x] 22/10/2026 **Task 3, worker di replica** (`atlas_sync::replica`, binario `replica DB [--una-volta]`):
  - `giro`: eventi in ordine di `id`, uno per transazione SQL Server; al primo errore `segna_fallito` con riprova a
    5 s, 10 s, 20 s … fino a 5 min, e la coda si ferma lì (ordine conservato). Connessione aperta al primo evento e
    riaperta se `annulla` fallisce; un SQL Server spento è un errore dell'evento come un altro (resta in coda).
  - Idempotenza: prima di scrivere cerca in Arca la chiave `UK_DOTes` (Cd_CN, EsAnno, NumeroDoc); se c'è e riletta con
    `lettura::carica` è uguale all'evento → "già presente" con il suo `Id_DoTes`; se è un altro documento →
    `NumeroOccupato` e coda ferma (mai due BO con lo stesso numero).
  - Perché il confronto funzioni il documento deve avere la forma che Arca restituisce: `ddt::salva` ora rifiuta istanti
    con i secondi (`TimeIns`/`TrasportoDataora` sono `smalldatetime`) e quantità forzate uguali al netto della pesata.
    Tutti i 5.453 BO 2026 la rispettano.
  - Solo clone: rifiuta i database che non finiscono in `_DEV` (env `ATLAS_ARCA_DEV_ADO`) finché non si decide sulla
    produzione. Il trait `Destinazione` permette i test senza SQL Server (4 test: ordine, blocco e riprova, attese).
  - Prove sul clone: 5.453 eventi BO 2026 (da `verifica-db`) → **5.453/5.453 già presenti**, `Id_DoTes` uguale
    all'originale per tutti, 0 scritture (60.503 testate prima e dopo), 10 ms a documento. Nuovo DDT (`prova-replica
    nuovo`, righe del 108602) → scritto **BO 5458, Id_DoTes 120546**: 1.970 valori uguali al modello, 31 diversi (solo
    istanti di salvataggio). Crash simulato (DB ATLAS di prima della replica) → riconosciuto già presente, stesso Id,
    nessun doppione. Numero preso da un altro documento → `NumeroOccupato`, nulla scritto. Porta chiusa → errore di
    rete, evento in coda, riprova. 50 test nel workspace, clippy pulito.
  - Sul clone ora ci sono due BO scritti da ATLAS: 5457 (Task 1) e 5458 (Task 3). Sono scritti prima della correzione
    sotto (testata non ultima): l'importazione non deve contare su di loro come esempio.
- [x] 22/10/2026 **Testata scritta per ultima, come Arca**: `scrittura::scrivi` chiude con
  `UPDATE DOTes SET TimeUpd = TimeUpd` (trigger ancora spenti). Il confronto di `prova-ddt` ha la colonna virtuale
  "(testata scritta per ultima)". `rigioca` 1-21/10/2026: prima 0/410 documenti con testata ultima, dopo 410/410 e
  **410/410 identici alla creazione** (523.294 valori). Anno intero non rigiocato (30 min): il valore delle colonne
  non cambia, cambia solo il `Ts`.

- [x] 22/10/2026 **Task 3b, importazione continua Arca → ATLAS (BO)** (`atlas_sync::importazione`, binari
  `importa-documenti DB [--una-volta]` e `verifica-importazione DB`, Arca da `ATLAS_ARCA_ADO` in sola lettura):
  - Migrazione `0002_importazione_arca.sql`: `ddt.arca_id_testata` (unico; riempito dall'importazione e, con il
    trigger `outbox_replicato`, dalla replica nello stesso statement di `segna_replicato`; ripreso dagli eventi già
    replicati), `importazione_arca` (punto raggiunto per tipo documento + database di Arca a cui il file è legato),
    `importazione_esclusi` (documenti non rappresentabili, con il motivo).
  - Rilevazione: `Ts > punto and Ts < MIN_ACTIVE_ROWVERSION()` (mai saltare una transazione di Arca ancora aperta),
    5 ms senza indice su `Ts`. Cancellazioni: impronta (conteggio + somma `Id_DoTes` dei BO, 5 ms) contro i documenti
    noti ad ATLAS; solo se diverge si scarica l'elenco. Arca è a lock (RCSI spento): una cancellazione non confermata
    non si vede. Oltre 100 BO spariti in un giro: si ferma senza cancellare (`TroppeCancellazioni`).
  - Lettura da Arca prima della transazione SQLite (il backend non aspetta la rete); scrittura in una transazione
    con savepoint per documento, punto raggiunto nella stessa transazione. Anagrafiche riallineate a ogni giro con
    novità. `ddt::importa`: invariato / aggiornato / nuovo / **collegato** (documento ATLAS replicato di cui si era
    perso l'esito); numero già di un altro DDT ATLAS → `NumeroOccupato`, giro fermo lì e riprova (mai due DDT con
    lo stesso numero). Un database Arca diverso da quello legato è rifiutato (`AltroDatabase`).
  - Due errori di lettura trovati sullo storico e corretti: `DORig.Cd_AR` riempito a 20 caratteri fino al
    07/11/2018 (50.599 righe di 4.469 BO, ora senza spazi; test `atlas-arca/tests/lettura_clone.rs`, `--ignored`);
    BO `1/PA` del 2018 con lo stesso `NumeroDocI` del BO 1 (la chiave di Arca è il testo `NumeroDoc`): escluso come
    "numero con suffisso" (anche 7 FT `n/PA`, da considerare con le fatture).
  - Clone, database nuovo: **49.783 BO → 49.772 importati + 11 esclusi** (1 suffisso, 6 righe senza articolo, 3
    spese, 1 non esecutivo), 71,7 s, 1,44 ms a documento, 77 MB. `verifica-importazione`: 0 ignoti, 0 spariti,
    **49.772/49.772 riletti identici**, totali = `DOTotali` in 49.733; i 39 restanti sono BO dal 21/09 al
    02/11/2023 (39 su 734 del periodo) in cui l'imposta di Arca è diversa di 1 cent da imponibile × aliquota (Arca
    fuori dalla sua stessa regola; il castelletto lo fa `asp_Do_End`, cifrata). ATLAS tiene il suo calcolo.
  - Giro a vuoto 0,1 s compresa la connessione. Prove sul clone: DDT 5459 nuovo in ATLAS → replica → torna
    **invariato**; con l'esito della replica perso → **collegato**, poi la replica lo trova già presente; `Cd_PG`
    cambiato in Arca → **aggiornato**, ripristinato → aggiornato e di nuovo identico; BO 5459 cancellato in Arca
    → **cancellato** in ATLAS. Il clone è tornato a 49.783 BO (5459 cancellato: ora è un buco).
  - 70 test nel workspace (13 nuovi del giro con un'Arca finta, 11 nuovi in `atlas-db`), clippy pulito. Dati di
    prova di `atlas-db` in `atlas_db::prova` (feature `prova` per i test degli altri crate).

- [x] 22/10/2026 **Task 3c, numerazione unica** (`atlas_core::numerazione`, `atlas_db::numerazione`,
  `atlas_sync::numerazione`, binario `verifica-numerazione [DB] [ANNO]`):
  - Regola di Arca ricavata a scatola nera (`asp_NumDoc_Next`, `UnusedCodes_DoTes`, `NumDoc_Following` cifrate) e
    riprodotta in `Numeri`: `D00` (`NextNumAllaData = 0`) = più alto dell'esercizio + 1, qualunque data; `001` (= 1)
    = più alto fra i documenti con data ≤ quella del nuovo + 1, rifiutato se già di un documento con data successiva
    (errore 900308 di Arca). I buchi non si riusano da soli: si elencano con l'intervallo di date dei vicini.
  - Confronto del codice Rust con le funzioni di Arca sul clone: `UnusedCodes_DoTes` **1.157/1.157** righe uguali
    (18 esercizi, 2 sezionali, descrizioni comprese); `asp_NumDoc_Next` giorno per giorno **365/365** su entrambi i
    sezionali nel 2018, 2019, 2023, 2025, 2026 (fatture 2026: 72 numeri + 293 rifiuti sullo stesso numero).
    `EsAnno` = anno di `DataDoc` in tutti i 60.504 documenti.
  - Il sezionale lo condividono tutti i tipi con lo stesso `DO.Cd_CN`: sul `D00` ci sono anche 6 `BF` (2018-2019).
    L'importazione ora segue il sezionale (`Cd_CN = 'D00'`) e non il tipo: i documenti di altri tipi finiscono tra
    gli esclusi ("tipo documento non gestito") e il loro numero resta occupato. Migrazione `0003_numerazione.sql`:
    esclusi con sezionale e data, punto azzerato (il primo giro rilegge tutto, i documenti restano invariati).
    Clone da zero: **49.789 documenti → 49.772 importati + 17 esclusi** (11 + 6 BF), 81,9 s; numeri occupati in
    ATLAS uguali ad Arca in **9/9 esercizi**, date comprese; `verifica-importazione` invariata (49.772/49.772).
  - Al salvataggio (`numerazione::crea`) ATLAS legge da Arca i numeri del sezionale nell'esercizio (13-26 ms,
    indice `IX_DoTes_Cover4NextNum`) e li unisce ai propri nella transazione che scrive il DDT. Meglio del "giro di
    importazione prima di salvare" previsto: funziona anche con l'importazione ferma su un conflitto e non scrive
    nulla (nessuna concorrenza con il worker). Arca muta o lenta oltre `ATTESA_ARCA` (1 s) → numera sul database
    ATLAS e lo dice (`Creato::senza_arca`).
  - `ddt::salva` (numero scelto) ora rifiuta anche i numeri degli esclusi e, sui sezionali alla data, le date fuori
    dall'intervallo dei vicini; letture puntuali (`numerazione::vicini`): **1,20 ms** a documento (`verifica-db`
    2026, 5.454/5.454), prima 1,15.
  - Collisione residua (stesso numero nei due sistemi mentre Arca era irraggiungibile): replica e importazione si
    fermano su `NumeroOccupato`; `numerazione::rinumera` dà al DDT ATLAS (solo se non è già in Arca) il prossimo
    numero sui dati dei due sistemi e aggiorna gli eventi in coda. Rifiuta se in Arca il numero è libero
    (`NessunConflitto`) o se l'occupante ha stesso cliente e stesso `TimeIns` (`ForseLoStesso`: sarebbe lo stesso
    DDT modificato in Arca, rinumerarlo lo raddoppierebbe).
  - Prova end-to-end sul clone: DDT numerato con Arca → BO 5459 replicato; secondo database ATLAS "offline" → 5459
    anche lui, replica ferma (`Id_DoTes 121368`), importazione ferma; `rinumera` → 5460, replica scrive, le due
    importazioni ripartono; entrambi i database ATLAS uguali ad Arca (9/9 esercizi, 49.774/49.774 riletti
    identici). Poi i due BO cancellati dal clone (righe, movimenti, totali, IVA a cascata, nessun orfano): clone di
    nuovo a 60.504 testate, prossimo numero 5459.
  - Alla connessione importazione e replica verificano che in Arca BO/FA/FT/NC siano ancora sui sezionali
    `D00`/`001` con le stesse regole (`lettura::controlla_numerazione`); altrimenti si fermano.
  - 86 test nel workspace (16 nuovi; Arca finta condivisa in `atlas-sync/src/finta.rs`), clippy pulito.

- [x] 22/10/2026 **Task 4, backend ATLAS** (`crates/atlas-server`, binari `atlas-server [DB]` e `misura-latenze DB`):
  - Un solo scrittore: il worker, su un thread suo con runtime `current_thread`, tiene l'unica connessione SQLite di
    scrittura e tre connessioni ad Arca (numeri, importazione, replica) dalla stessa `ATLAS_ARCA_ADO`. Esegue i
    comandi (salvataggio con `numerazione::crea`, numero scelto a mano verificato anche sui numeri di Arca,
    `rinumera`, numeri liberi) e nel tempo che resta i giri: replica svegliata a ogni salvataggio e poi all'istante
    della riprova del primo evento (`outbox::prossimo_tentativo`), importazione ogni secondo (200 BO per giro). Un
    comando interrompe il giro in corso al punto di attesa della rete (mai dentro una transazione SQLite) e ne chiude
    la connessione: un salvataggio non aspetta Arca oltre `ATTESA_ARCA` (provato con un'Arca appesa: < 500 ms).
  - La replica ora rifiuta un database diverso da quello da cui il file importa (`replica::Arca::lega`); continua a
    scrivere solo su `*_DEV`.
  - Letture su 4 connessioni di sola lettura (`atlas_db::apri_lettura`, WAL). Migrazione `0004_prezzi_righe.sql`:
    data e cliente della testata ripetuti in `ddt_righe` con indici `(articolo, data)` e `(articolo, cliente, data)`
    per la maschera F3 (sul DB reale da 70 MB: 4,9 s una volta sola).
  - Bozza → DDT (`bozza.rs`): testata dal cliente (pagamento, listino, IBAN, BIC, conto banca, agente, scissione),
    destinazione predefinita, data trasporto = data documento, istanti al minuto; righe dall'articolo (descrizione,
    unità predefinita e fattore, aliquota/conto o predefiniti), prezzo dal listino del cliente o, se non ne ha,
    da `ATLAS_LISTINO` (0000001); magazzino sempre scritto (`ATLAS_MAGAZZINO`, 00001: senza, Arca metterebbe quello
    della causale e il documento riletto sarebbe diverso). Calcolo tollerante per la maschera: per riga quantità,
    totale, errori, avvisi (`tara_maggiore_lordo`, `colli_decimali`), `prezzo_modificato` (cella ambra).
  - F3 (`prezzi.rs`): dati documento, listini di prezzi alla data (revisione valida più recente), ultimo prezzo al
    cliente, ultimo a chiunque, massimo del giorno, ciascuno con `prezzo_riga` da riportare; ultimo acquisto assente
    (nessun documento di acquisto in ATLAS).
  - Stato (`GET /api/stato`): giri di replica e importazione, coda, conflitti con l'azione `rinumera` (evento fermo
    della replica, o `Giro::conteso` dell'importazione → DDT ATLAS con quel numero non ancora in Arca).
  - WebSocket `/api/ws`: le stesse operazioni come richieste `{"id","metodo","parametri"}` e notifiche (`stato`,
    `ddt_creato`, `ddt_rinumerato`, `replica`, `importazione`). 14 strumenti con JSON Schema (`GET /api/strumenti`,
    `POST /api/strumenti/{nome}`), con il flag `scrittura` su `crea_ddt` e `rinumera_ddt`.
  - Sicurezza: ascolto su `127.0.0.1:7878`; richieste dei browser solo dalle origini Tauri e Vite (anche il
    WebSocket, che il browser non sottopone a CORS). mTLS fra postazioni: Task 8.
  - Latenze sul DB reale (49.772 DDT, 483.674 righe; release, 500 ripetizioni, dalle rotte senza rete): tutte le
    letture p50 < 1 ms e p99 < 2 ms; F3 sull'articolo più venduto (GEN, 18.195 righe) p50 0,23 ms, p99 0,93;
    calcolo di un DDT di 14 righe p50 0,41 ms; elenco 50 DDT p50 0,63 ms. Salvataggio senza Arca p50 5 ms (fsync,
    `synchronous = FULL`); con Arca si aggiungono i 13-26 ms della lettura dei numeri.
  - Prova sulla copia del DB reale: numeri liberi 2026 = buco 5447 (21/10) e prossimo 5459, come Arca sul clone.
  - 107 test nel workspace (18 nuovi nel server, 7 end-to-end con un'Arca finta: numerazione dopo i numeri di Arca,
    replica, conflitto risolto con `rinumera`, giro appeso interrotto, WebSocket, origini), clippy pulito sul nuovo
    codice.
  - **Da provare sul clone** (qui SQL Server non è raggiungibile), su una copia di `dati\atlas.sqlite`:
    `copy dati\atlas.sqlite dati\prova-server.sqlite`, `$env:ATLAS_ARCA_ADO` sul clone,
    `cargo run --release -p atlas-server -- dati\prova-server.sqlite`, poi
    `Invoke-RestMethod -Method Post http://127.0.0.1:7878/api/ddt -ContentType application/json -Body
    '{"cliente":"C000179","righe":[{"articolo":"GEN","colli":2,"lordo":"12.4","tara":"0.3"}]}'` e
    `Invoke-RestMethod http://127.0.0.1:7878/api/stato`. Atteso: numero 5459, `senza_arca` vuoto, replica `scritti`
    1 e coda 0, nessun conflitto; il giro di importazione successivo ritrova il BO invariato (nessun aggiornato).
    `prova-ddt confronta` sul BO scritto e poi cancellarlo dal clone come per il 5459 della prova 3c.

- [x] 22/10/2026 **Prova del Task 4 sul clone** (titolare): BO 5459 numerato con Arca (nessun `senza_arca`), replicato
  subito (`Id_DoTes 121370`), coda vuota e nessun conflitto; DDT di prova tolto dal clone. `misura-latenze` sul PC di
  Arca: F3 su GEN 0,093 ms p50, calcolo di 14 righe 0,32 ms.

- [x] 22/10/2026 **Task 5, frontend desktop** (`app/`: React 19 + TypeScript + Tailwind 4, shell Tauri v2 in
  `app/src-tauri`):
  - **Rifatta sulla finestra di Arca** (richiesta del titolare: "stile iOS ma praticamente come era su Arca, se no un
    operatore non sa più come muoversi"; riferimenti `docs/screenshot_arca/01_…` e `04_…` e la struttura di
    `fedi_doc`): finestra "Gestione Documenti" con la barra strumenti nell'ordine di quella di Arca (Salva `F10`,
    Annulla | Salva e stampa `F12` | Nuovo `Ctrl+N`, Elimina per il Task 6 | documento Precedente/Successivo
    `Alt+↓/↑`, le frecce arancioni di Arca) e le pagine Elenco / Generale / DMS (`Ctrl+1/2/3`). Tema chiaro
    predefinito (priorità del titolare: le posizioni come in Arca, colori e forme liberi). Generale: testata in
    una fila (Tipo BO, Cliente, Data GG-MM-AAAA, Numero, Valuta EUR, Cambio 1.000000, Destinazione se il cliente ne
    ha) e sotto le schede, con il riquadro rosso di ragione sociale, indirizzo e codice destinatario alla loro destra;
    le linee delle colonne della griglia arrivano fino in fondo come in Arca; schede Testa, Righe, Piede, Totali,
    Info, Evasioni, Stampe (`Ctrl+PgSu/PgGiù`) con i riquadri dei contenitori di Arca (pagamento, dati contabili,
    varie, stato; dati DDT con trasporto V, spedizione M, porto F, aspetto beni AV e pesi a zero come nei BO di
    Arca; totali, merce, IVA, provvigioni). Righe: titolo rosso "DETTAGLIO DOCUMENTO", griglia, sotto "Evade" a
    sinistra e "Importa pesate"/"Riferimento" a destra. Numeri e date nel formato di Arca: punto decimale e decimali
    fissi (importi 2, prezzi 3, fattore 5), date GG-MM-AAAA. Un DDT aperto dall'elenco si legge nella pagina
    Generale con la stessa testata e le stesse schede; il DDT in battitura resta dov'era.
  - Ancora in sola lettura o spenti, perché ATLAS non ha i dati o le API: i campi delle schede Testa e Piede
    (vengono da cliente e costanti BO), Importa pesate (file della bilancia da collegare), Riferimento ed Evade
    (nessun ordine in ATLAS), Elimina (Task 6), DMS e stampa (Task 7).
  - Maschera DDT tutta da tastiera. Testata: Cliente (F3 ricerca) → `Invio` sulla prima riga; destinazione
    (predefinita del cliente, altre o nessuna), data, numero (vuoto = numerazione unica; F3 = buchi di Arca con le
    date ammesse e il prossimo numero). Griglia sulle 40 colonne di UserPref 1443 (ordine e larghezze esatte,
    riga 19 px), le colonne che ATLAS non usa restano vuote.
  - Regole (`app/src/maschera/righe.ts`, funzioni pure con test): `Invio` segue Articolo → UM → Colli → Lordo →
    Tara → Prezzo → nuova riga sulle colonne visibili, qualunque sia l'ordine scelto; `Freccia Giù` scende sulla
    stessa colonna o crea la riga e va sull'articolo (mai da una riga vuota in fondo: nessuna fila di righe vuote);
    `Esc` annulla la modifica della cella, poi toglie la riga vuota; `Ctrl+Canc` elimina la riga. Guardrail senza
    popup, anche uscendo con le frecce: colli con i decimali e tara × colli ≥ lordo fermano il cursore con una barra
    (`Invio` conferma per quei valori, `Esc` torna a correggere).
  - Ogni modifica ricalcola la bozza sul backend (`POST /api/ddt/calcola`, la richiesta precedente si annulla):
    netto, prezzo proposto (in grigio nella cella), totali e castelletto in tempo reale; prezzo battuto diverso dal
    listino in ambra chiaro; errori di riga sul codice articolo e nel piede. `F10` salva (numero, totale, avviso se
    numerato senza Arca) e prepara il DDT successivo con la stessa data.
  - F3 sul prezzo: "PREZZO/COSTO ARTICOLO" come in Arca: barre grigie "Dati da documento" (articolo, doc. BO /
    cliente del GG-MM-AAAA, prezzo della riga), "Prezzi da listino" (Listino 1 e Listino 2 sempre, a 0.000 se
    l'articolo non c'è; "Prezzo Val Doc. Ivato" = prezzo del BO, che non è ivato) e "Ultimi prezzi da documenti"
    (ultimo BOLLA VENDITA del cliente e assoluto con "(BO / C000387 del 22-10-2026)", le stesse voci "tipo Bolla",
    Ultimo Acquisto; le voci senza documento in corsivo); stesse colonne fino a `Riporta`, spuntato sulle voci
    riportabili. `↑/↓` e `Invio`/`Spazio` riportano il prezzo nella riga. Provvigioni vuote (non gestite); ultimo
    acquisto vuoto finché ATLAS non ha documenti di acquisto.
  - Griglia personalizzabile e salvata nella postazione (`localStorage`): larghezza a trascinamento del bordo
    (doppio clic = larghezza di fabbrica), riordino a trascinamento delle intestazioni, clic destro sulle
    intestazioni per mostrare/nascondere (l'articolo resta) e "Ripristina layout di fabbrica". Riga attiva blu
    #007AFF con barra a sinistra, righe alterne #F9FAFB (piano architetturale).
  - Pagina Elenco (`Ctrl+1`) con le 36 colonne della griglia di Arca nel suo ordine (più Destinazione e Luogo
    destinazione della personalizzazione Bottamedi e il badge dello stato in Arca), larghezze di Arca scalate di 1,2
    per il carattere più largo, stessa personalizzazione della griglia righe; filtri dal/al (GG-MM-AAAA), tipo (DDT;
    fatture e NC con il Task 7) e cliente; frecce, PgSu/PgGiù, Home/Fine, `Invio` o doppio clic apre il DDT.
    Sincronizzazione (coda, importazione, conflitti con "Rinumera") in una finestra che si apre dal semaforo nella
    barra (verde in Arca, blu in coda, rosso fermo o server irraggiungibile), aggiornato dal WebSocket.
  - Design §3.6-3.7: chiaro e scuro (segue il sistema, cambiabile), finestre satinate, focus ring blu, cifre
    tabulari monospazio a destra; intestazione aziendale, firma e coordinate nella barra di stato, cartellino in
    Informazioni (`F1`), dove si imposta anche l'indirizzo del server.
  - Backend: la riga calcolata porta magazzino e conto; ricerche clienti e articoli con il codice uguale e poi i
    codici che iniziano con il testo in cima (chi batte "ZUC" trova ZUC prima di FIOR "fiori di zucchina");
    `cargo run -p atlas-server -- DB` avvia il server (`default-run`: con due binari il comando del README falliva).
  - Shell Tauri: CSP che permette solo il backend locale (`127.0.0.1`/`localhost`), capability `core:default`,
    nessun comando nativo. Il backend accetta le origini Tauri e Vite. Compilata in release su Linux (6 MB) e avviata:
    WebSocket e API raggiungibili.
  - Backend per la maschera: scheda cliente con codice destinatario, descrizioni di listino e agente, IBAN e BIC;
    elenco DDT con le colonne della griglia di Arca (destinazione, pagamento, listino, agente, righe, netto a pagare,
    Id_DoTes); F3 con Listino 1 e 2 sempre presenti, descrizione della revisione, prezzo nella valuta del documento
    e percentuale IVA degli ultimi prezzi. Corretta una prova instabile del conflitto di numero (la replica poteva
    scrivere prima dell'iniezione del conflitto).
  - Prove: 16 vitest (tastiera, layout, numeri, voci F3, date) e 7 scenari Playwright end-to-end sul database reale
    (copia) con il backend vero: un DDT battuto solo da tastiera fino a F10 e riletto dalle API (GEN 11.8 kg × 1.50 +
    ZUC, totale 22.57), guardrail, F3 prezzi con le voci di Arca e riporta, ambra, Freccia Giù/Su, scheda Totali,
    riapertura dall'Elenco, colonne (larghezza, nascondi dal clic destro, persistenza, ripristino, riordino con la
    sequenza Invio invariata), F3 cliente/articolo/numeri liberi; fotografie chiaro/scuro in `app/test-results/`.
  - **F12**: `TASKS.md` lo dava come "nuova riga", la direttiva (documento supremo) come "salva e stampa": seguita la
    direttiva. Finché non c'è il modulo stampe (Task 7) F12 salva e lo dice.
  - Fuori da questo task: F2 per sbloccare i prezzi in anagrafica (§3.2: le anagrafiche si modificano ancora in
    Arca, il backend non ha API di scrittura) e l'area riservata con PIN (§4.2-4.3, Task 6). La postazione banco non
    mostra dati aggregati di fatturato (§4.3).
  - **Da provare in Windows**: `cd app`, `npm ci`, `npm run tauri build`, installare e verificare F10/F12/F3 in
    WebView2 (in sviluppo F12 potrebbe aprire anche gli strumenti di sviluppo).

## Decisioni prese (titolare)
- 22/10/2026 **Sincronizzazione nei due sensi, numerazione unica**: un documento fatto in Arca entra nel database
  ATLAS; uno fatto in ATLAS entra in Arca come se lo avesse scritto Arca, che ne tiene conto nella numerazione.
  BO, FA e FT (e NC) hanno la stessa numerazione nei due sistemi.
  Misurato sul clone: dopo il BO 5458 scritto da ATLAS, `UnusedCodes_DoTes` propone 5459 (Arca conta già i
  documenti di ATLAS) e segnala il buco 5447, riempibile solo con data 21/10.
  Sezionali: BO `D00` (`NextNumAllaData = 0`); FA, FT, NC tutti su `001` (`NextNumAllaData = 1`: numero vincolato
  all'ordine delle date). Il numero in Arca lo assegna il server al salvataggio (`fedi_doc` parte con
  `NumeroDoc = ''`, `asp_NumDoc_Next` cifrata): nessun numero resta prenotato da una maschera aperta.

## Decisioni in sospeso (titolare)
- **Prezzo proposto in riga**: oggi il listino del cliente, o `ATLAS_LISTINO` (0000001) per i 370 clienti su 387
  che non ne hanno uno. Su 54.068 righe 2026 il prezzo battuto coincide con l'ultimo venduto a chiunque nell'81% dei
  casi e con il listino 1 nel 24% (§4 di `ANALISI_ARCA.md`): se la maschera deve proporre l'ultimo prezzo, basta
  cambiare la regola in `bozza.rs` (le letture ci sono già, F3). Da verificare anche `DO.Cd_LS_1` dei BO.
- **Produzione**: la replica richiede un login con `ALTER` su `DOTes`/`DORig` e spegne per pochi millisecondi, in
  transazione, due trigger del fornitore. Sul clone è innocuo; in produzione è un intervento sugli oggetti di Arca
  (assistenza/contratto Tecnobit e aggiornamenti che rinominano i trigger: in quel caso la replica si ferma da sola).
- **Utente registrato**: oggi `UserIns/UserUpd = '190'` come Arca (indistinguibile). In alternativa un utente Arca
  dedicato ad ATLAS per riconoscere i documenti replicati.

## Vincoli tecnici della replica
- Non gestiti ancora: righe descrittive senza articolo, righe spesa (`DORigSpesa`), documenti non esecutivi, FA/FT/NC
  (per FA servono anche `SC`, `CGMovT`, `CGMovT_NumProt`).
- Il replay consuma identità sul clone (rollback non le restituisce): innocuo su `_DEV`, il programma rifiuta altri DB.
- Database ATLAS: solo il backend lo apre (SQLite, un solo scrittore). `dati/atlas.sqlite` è il DB di sviluppo; non
  far mai girare `verifica-db` sul DB reale (rifiuta file esistenti) perché accoderebbe eventi di replica dello storico.
- Le anagrafiche restano gestite in Arca finché ATLAS non ha le sue maschere: rilanciare `importa-anagrafiche` (idempotente).
  L'importazione dei documenti le riallinea da sola a ogni giro con novità.
- Un file ATLAS è legato al database di Arca da cui ha importato per primo. La replica non lo controlla ancora
  (usa `ATLAS_ARCA_DEV_ADO`, l'importazione `ATLAS_ARCA_ADO`): il backend dovrà usare la stessa connessione per i due
  versi e rifiutare un database diverso anche nella replica.
- Esclusi già importati restano com'erano in ATLAS (e sono tra gli esclusi) se in Arca diventano non rappresentabili.
  Quando il modello coprirà righe descrittive, spese e non esecutivi, gli esclusi vanno riletti (sono in
  `importazione_esclusi`): il punto raggiunto li ha già superati.
- `dati/atlas.sqlite` (DB di sviluppo, 11.881 BO di `verifica-db` con eventi) passa alla versione 3 alla prossima
  apertura. I database delle prove sono nello scratchpad della sessione, non nel progetto.
- Numerazione: le fatture (`001`) in ATLAS non ci sono ancora; quando arriveranno, `numerazione::occupati` deve
  leggere anche la loro tabella e l'importazione seguire il sezionale `001` come fa con `D00`.
- `numerazione::crea` va chiamata da chi possiede l'unica connessione di scrittura (il thread del worker nel
  backend); la connessione ad Arca va tenuta aperta, altrimenti ogni salvataggio paga anche il login.
- `dati/atlas.sqlite` è versionato (storico 2018-2026, schema 3): il backend lo porterebbe alla versione 4 alla prima
  apertura. Per le prove usare una copia; `misura-latenze` lavora già su una copia.

## Da fare, in ordine

3. Worker di replica, importazione e numerazione unica (3b, 3c): fatti (vedi sopra). Il backend (Task 4) li farà
   girare su un thread suo, con la propria connessione SQLite e un runtime `current_thread`, svegliando la replica a
   ogni salvataggio invece del controllo ogni secondo dei binari. FA/FT/NC si importeranno quando il database ATLAS
   avrà le fatture.

4. **Server Backend ATLAS (Rust / Axum)** — fatto e provato sul clone (vedi sopra). Previsto in origine:
   - Salvataggio DDT con `numerazione::crea` sul thread del worker; mostrare `Creato::senza_arca` e i conflitti
     (`ultimo_errore` dell'evento fermo, `Giro::fermo` dell'importazione) con l'azione "rinumera"; buchi da
     `numerazione::liberi` per il numero scelto a mano (Task 6).
   - Web API REST ad altissime prestazioni per gestione anagrafiche e documenti (<2ms).
   - Integrazione di `atlas-core` per calcolo pesata in tempo reale e totalizzazione istantanea.
   - Endpoint per lookup prezzi contestuale (`F3`): listino base, ultimo prezzo cliente, prezzo massimo odierno, ultimo prezzo assoluto.
   - Tool JSON Schema per integrazione con assistente e workflow automatici.

5. **Frontend Desktop (Tauri v2 + React / TypeScript + Tailwind CSS)** — fatto (vedi sopra), resta la prova in Windows:
   - Elenco documenti rapido con filtri per data, tipo documento (DDT, Fattura, NC) e cliente.
   - Maschera inserimento DDT keyboard-first conforme a UserPref 1443 (40 colonne, ordine e larghezze esatte).
   - Sequenza tastiera fluida: `Articolo -> UM -> Colli -> Lordo -> Tara -> Prezzo`.
   - **Navigazione verticale con `Freccia Giù`**: scende sulla cella corrispondente della riga sotto se esiste già; se la riga sotto non esiste (era l'ultima), crea all'istante la nuova riga e si posiziona sulla **PRIMA COLONNA (`Codice Articolo`)**. `Freccia Giù` non apre mai popup o tendine.
   - **Tasto `F3` sul Prezzo (Maschera "PREZZO/COSTO ARTICOLO")**: apre la finestra dedicata conforme a `fastsrcform_arprezzo` di Arca (Dati Documento, Prezzi da Listino, Ultimi prezzi da documenti cliente e assoluti, Ultimo Acquisto, colonna casella `Riporta` con selezione da tastiera `Invio`).
   - Evidenziazione visiva prezzo modificato: cella con sfondo tenue (ambra chiaro), **zero popup bloccanti**.
   - Guardrail antierrore da tastiera: avviso per `Tara >= Lordo` o `Colli con decimali` (gestibili al 100% da tastiera: `Esc` correggi, `Invio` conferma).
   - Tasti funzione: `F3` (lookup prezzi), `F10` (salva documento), `Esc` (esci/annulla riga), `F12` (nuova riga).

6. **Gestione Cancellazioni Documenti e Riuso Numerazione**:
   - Hard Delete dal database operativo (zero colonne `is_deleted` nel DB ordinario).
   - Recupero immediato del numero documento cancellato come buco disponibile nel progressivo.
   - Snapshot di emergenza locale isolato fuori dal DB (cifrato, accessibile solo da menu riservato con PIN).

7. **Modulo Fatturazione Differita e Stampe**:
   - Selezione massiva DDT del periodo per cliente con spunte e totali in tempo reale.
   - Generazione automatica fattura differita con raggruppamento e righe di riferimento DDT.
   - Generazione file standard ministeriale XML FatturaPA 1.2.2 per invio a Sistema di Interscambio (SdI).
   - Modulo stampa DDT e fattura in formato PDF.


8. **Connettività Distribuita SOTA (mTLS 1.3) & Resilienza Offline**:
   - Connessione sicura tra postazioni (banchi, ufficio, filiali) tramite HTTPS con certificati client (Mutual TLS 1.3): zero demoni VPN da gestire.
   - Cache locale offline alla pesa: continua a stampare e pesare anche in caso di caduta momentanea della rete o Wi-Fi, con riconciliazione automatica via Outbox.

9. **Unificazione CRM WhatsApp Nativo in Rust (crates/atlas-crm)**:
   - Riscrittura del modulo CRM WhatsApp (HERMES) direttamente in Rust puro integrato nel workspace come crate nativo.
   - Accesso diretto in memoria tra ERP e WhatsApp: ordini, conferme DDT, situazione scadenze senza passare per bridge esterni.
   - Tab CRM integrato direttamente nella dashboard desktop di ATLAS dell'Area Riservata Titolare.
