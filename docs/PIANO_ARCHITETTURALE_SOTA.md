# 🏛️ SUPER PROMPT MASTER: SPECIFICHE DEFINITIVE "ATLAS"
### (State-of-the-Art Architecture, AI-Native Jarvis Hooks, Sandbox Cloned DB & Deployment Globale)

---

## ⚡ MANDATO DI INGEGNERIA: "STATE-OF-THE-ART CODEBASE"
> **DIRETTIVA ASSOLUTA PER L'AGENTE PROGRAMMATORE:**
> Agisci come **Principal Software Architect e Lead Systems Engineer di livello mondiale**.
> Questo progetto non ammette codice provvisorio, hack temporanei o soluzioni mediocri. L'obiettivo è produrre **il miglior codice gestionale mai scritto per il settore enterprise delle PMI**:
> - **Rust idiomatico, elegante e indistruttibile**: gestione rigorosa degli errori con `Result<T, E>` (zero `unwrap()` o `panic` su percorsi operativi), concorrenza asincrona scalabile con `tokio`, tipizzazione forte, zero memory leak, allocazione atomica e footprint RAM rigorosamente <30 MB.
> - **Frontend Desktop Tauri v2 da riferimento**: architettura reattiva (Svelte o React/TypeScript), gestione deterministica del focus della tastiera, rendering istantaneo sotto i 16 ms (60-120 fps fluidi), design system rifinito in stile Apple/iOS con contrasto industriale elevato.
> - **Integrità Transazionale ACID Totale**: ogni operazione su database deve essere atomica, tracciabile e deterministica. Se si verifica un'interruzione di rete o caduta di alimentazione, il sistema deve garantire zero record orfani e consistenza contabile al 100%.

---

## 🚫 ZERO "AI SLOP" POLICY: SOFTWARE ENTERPRISE PURO E SOBRIO
> **DIVIETO CATEGORICO DI OGNI ELEMENTO O STILE CHE RICORDI TESTI O GRAFICHE "GENERATI DA AI":**
> Questo è un software gestionale industriale di livello bancario/commerciale per un'azienda con milioni di euro di transato annuo. Deve trasmettere serietà, precisione millimetrica e autorevolezza:
> 1. **ZERO Emoji nell'Interfaccia Utente**: È TASSATIVAMENTE VIETATO usare emoji (🚀, 💡, 📦, 📝, 🔥, ecc.) nei bottoni, nei menù, nei titoli delle finestre, nei campi o nelle notifiche/toast. Utilizzare esclusivamente testo pulito o icone vettoriali SVG monocromatiche professionali e sobrie (stile Apple SF Symbols o Lucide Icons a tratto sottile da 1px).
> 2. **ZERO Testi Fuffa o Frasi Tipiche da Chatbot**: Niente formule di benvenuto informali ("Bentornato, campione!"), niente messaggi motivazionali, niente gergo da startup web. Usare rigorosamente la **terminologia contabile, amministrativa e di magazzino italiana standard**: *"Documento di Trasporto (DDT)", "Fattura Differita", "Codice Articolo", "Lordo / Tara / Netto", "Salva [F10]", "Stampa [F12]", "Annulla [Esc]"*.
> 3. **ZERO Grafiche Giocattolo o Gradienti AI**: Nessun gradiente violaceo, nessun bagliore neon o pulsanti gonfi. L'interfaccia deve avere un'estetica sobria, solida e industriale: palette neutra (bianco, grigio ardesia `#F3F4F6`, bordi netti `#E5E7EB`, testo grigio scuro/nero profondo `#111827`, e blu istituzionale `#007AFF` per la selezione attiva).
> 4. **Codice Pulito e Professionale**: Nessun commento prolisso, infantile o didattico nel codice (es. niente `// Let's create an awesome function here`). Solo codice puro, tipizzato, commentato con precisione tecnica su logiche di dominio complesse.

---

## 🎯 VISIONE E OBIETTIVI: IL SISTEMA "ATLAS"
Progettare e sviluppare da zero **ATLAS**, il nuovo motore gestionale di riferimento per l'azienda (in sostituzione del monolite legacy Arca Evolution su Visual FoxPro 9 + SQL Server), progettato per dialogare in perfetta sinergia con **HERMES** (il sistema intelligente su WhatsApp) per creare l'embrione di un vero e proprio **Second Brain / Jarvis Aziendale di Magazzino**.

I pilastri della **Versione 1 (V1)** sono:
1. **Replicare fedelmente la logica, le maschere e i flussi di Arca**: nessuna rivoluzione nei processi consolidati. Gli operatori, il personale di magazzino e il titolare senior devono ritrovare esattamente le loro abitudini quotidiane.
2. **Azzerare tempi morti, bug e canoni di licenza**: passare da un runtime del 2005 a un motore nativo che risponde in **<5 millisecondi**, eliminando per sempre i canoni software forzati.
3. **Preservare al 100% l'ergonomia reale e la memoria muscolare**: la sequenza delle colonne (Articolo, UM, Colli, Lordo, Tara, Netto, Prezzo), le scorciatoie storiche (`F10`, `F12`, `F3`, `Esc`, `F2`) e il layout visivo scelto dal titolare sono intoccabili.
4. **Transizione a Rischio Zero (Dual-Write Shadow Sync)**: durante la convivenza, ATLAS scrive sul proprio database moderno e pulito e replica contemporaneamente i dati sul vecchio database SQL Server in background.

---

## 🛡️ REGOLA DI SICUREZZA ASSOLUTA & POLITICA CREDENZIALI DATABASE
> **ATTENZIONE CRUCIALE SULL'ACCESSO AL DATABASE:**
> 1. **Utente Ispezione Sola Lettura (`bihortus_reader`)**:
>    Le credenziali `user='bihortus_reader'` e `password='BiHortus2025!'` su `PCARCA-2023 / ADB_BOTTAMEDI` sono state create intenzionalmente con **permessi rigorosi di SOLA LETTURA**. Servono all'agente AI per esplorare schemi, trigger e record senza alcun rischio di alterare i dati vivi.
> 2. **Autenticazione a Pieno Accesso (Windows Auth)**:
>    L'istanza SQL Server `PCARCA-2023` accetta nativamente l'Autenticazione Integrata di Windows (`Trusted_Connection=True` / SSPI con l'account `PCARCA-2023\Bottamedi` che è SysAdmin a pieno accesso).
> 3. **Divieto di Scrittura su Produzione & Sandbox Clone**:
>    Durante tutta la fase di sviluppo e test iniziali dei worker di replica, **È TASSATIVAMENTE VIETATO SCRIVERE SU `ADB_BOTTAMEDI`**.
>    Lo sviluppatore deve operare le scritture unicamente su una **copia clonata di test** (es. `ADB_BOTTAMEDI_DEV`). Il collegamento in scrittura alla produzione reale avverrà solo quando ATLAS entrerà nel periodo di prova reale affiancato.

---

## 📂 LOCALIZZAZIONE FILE SORGENTI, REPOSITORY E SCHEMI
Tutti i sorgenti estratti, i moduli deoffuscati e gli schemi reali si trovano già archiviati sulla workstation:

1. **Archivio ZIP completo**:
   * Percorso: `C:\Users\Bottamedi\.gemini\antigravity\scratch\progettox8\PROGETTOX8_CODICE_APERTO_ARCA.zip`
2. **Sorgenti FoxPro VFP estratti (.prg)**:
   * Percorso: `C:\Users\Bottamedi\.gemini\antigravity\scratch\progettox8\PROGETTOX8_ARCA_PACKAGE\02_SORGENTI_FOXPRO_VFP\`
   * File cardine: `fedi_doc_extracted.prg` (51.373 righe - gestione documenti, griglia e date), `ECR_Epson_RT_extracted.prg` (driver cassa Epson), `Cmd_DoPrelievoCreazione_extracted.prg` (fatturazione differita fine mese).
3. **Sorgenti C# .NET deoffuscati (.cs)**:
   * Percorso: `C:\Users\Bottamedi\.gemini\antigravity\scratch\progettox8\PROGETTOX8_ARCA_PACKAGE\03_SORGENTI_CSHARP_NET\`
   * File cardine: `FepaHubClient_clear.cs`, `WkiHub_clear.cs` (REST FatturaPA), `CadesSigner.cs` (firma digitale CAdES-BES PKCS#7), `SdITrasmissioneFileClient.cs` (SOAP SdI).
4. **PERSONALIZZAZIONI TECNOBIT SU MISURA PER BOTTAMEDI (`PERS/BOTTAMEDI`)**:
   * Percorso sorgenti originali: `C:\Program Files (x86)\Artel\ArcaEvolution\PERS\BOTTAMEDI\`
   * Percorso estratto deoffuscato: `C:\Users\Bottamedi\.gemini\antigravity\scratch\progettox8\extracted_pers_bottamedi\`
   * Pacchetto ZIP dedicato: `PERS_BOTTAMEDI_TECNOBIT_CUSTOM.zip` (inviato anche su WhatsApp)
   * **Moduli critici su misura da conoscere e replicare**:
     * `cmd_xexportconad_extracted.prg`: Tracciato export EDI fatture/DDT per CONAD.
     * `cmd_xexportgastropool_extracted.prg`: Tracciato export EDI per GASTROPOOL.
     * `cmd_xexporthogast_extracted.prg`: Tracciato export EDI per HOGAST.
     * `cmd_xlschange_extracted.prg`: Modulo cambio listini personalizzato Tecnobit.
     * `fedi_xarlistdest_extracted.prg`: Gestione listini articoli specifici per destinazione cliente (`xARListDest`).
     * `importdtv.prg` + `importdtv.ini`: Importazione DDT da tentata vendita palmari/bilance web (`DTV`).
     * `Fedi_VBScontrino_extracted.prg`: Gestione personalizzata scontrini cassa e interfaccia RT.
     * `fedi_doc_ad`, `fedi_doc_ca`, `fedi_doc_cp`: Override personalizzati di testata/righe documento per Bottamedi.
5. **Schemi Database e Campioni Reali (.json / .sql)**:
   * Percorso: `C:\Users\Bottamedi\.gemini\antigravity\scratch\progettox8\PROGETTOX8_ARCA_PACKAGE\04_SCHEMI_DATABASE_E_DATI\`
   * File cardine: `schema/schema_arca_core.json`, `samples/sample_bolla_bo.json`, `samples/sample_fattura_ft.json`.
5. **Parametri Server SQL (PC Ufficio)**:
   * Host: `PCARCA-2023` | Porta: `1433` | Database Prod: `ADB_BOTTAMEDI` | Database Clone Test: `ADB_BOTTAMEDI_DEV`

---

## 🧠 ARCHITETTURA "AI-NATIVE" & PREDISPOSIZIONE JARVIS / SECOND BRAIN
ATLAS non è solo un gestionale veloce, ma è la base dati e operativa per il futuro assistente intelligente dell'azienda:
1. **Headless API & Function Calling Ready**:
   Il Core Engine in Rust espone internamente endpoint e funzioni conformi allo standard JSON Schema / Tool Calling. Qualsiasi modello AI (Claude, GPT, Hermes locale su Ollama) può invocare direttamente le azioni di business (`crea_bozza_ddt`, `verifica_giacenza`, `estrai_prezzo_storico`, `conferma_carico`).
2. **Ponte Diretto ATLAS $\leftrightarrow$ HERMES**:
   Quando un cliente invia un messaggio o un audio su WhatsApp (*"Mandami 5 casse di insalata e 2 di mele per domattina"*), HERMES interpreta la richiesta e genera una bozza pronta in ATLAS con 1 click.
3. **Predisposizione Comandi Vocali a Mani Libere in Magazzino**:
   Porta di ascolto per comandi vocali rapidi per gli operatori con le mani occupate al banco o sui bancali.
4. **Matching Semantico Articoli**:
   Riconoscimento intelligente di sinonimi o nomi popolari/dialettali dei prodotti (es. "pomodoro da sugo" $\rightarrow$ codice `CUOR_BUE`).

---

## ⚠️ LE 5 TRAPPOLE CRITICHE DEL CODICE LEGACY DA REPLICARE CON PRECISIONE CHIRURGICA

1. **La Macchina a Stati Posizionale in `Reserved_1` e il Protocollo `asp_Do_Begin / asp_Do_End`**:
   * I trigger SQL crittografati non ricalcolano i totali da soli, ma leggono una stringa posizionale di 10 caratteri `Reserved_1`:
     * Posizione 1 (`'R'`): Triggera il ricalcolo di IVA, totali e spese bolli.
     * Posizione 2 (`'I'/'R'`): Triggera la generazione della prima nota contabile (`CGMovT`).
     * Posizione 3 (`'U'`): Triggera lo scarico/carico del magazzino.
     * Posizione 4 (`'R'`): Triggera lo scadenziario partite (`SC`).
   * **Protocollo obbligato nella replica su SQL Server**: Chiamata a `Exec asp_Do_Begin @Id_DoTes, 1` $\rightarrow$ Scrittura record con flag `Reserved_1` $\rightarrow$ Chiamata finale a `Exec asp_Do_End @Id_DoTes, @Options`.
2. **La Conversione Unità di Misura (`FattoreToUM1`) nell'Evasione Documenti**:
   * Quando una riga di Bolla (BO) evade un Ordine o una Fattura (FT) evade una Bolla (`DORig.Id_DORig_Evade`), l'unità di misura può variare (es. da Colli a Kg).
   * La quantità evasa sulla riga figlia viene convertita nell'unità di misura del padre tramite:
     $$\text{DORig.QtaEvasa} = \frac{\text{riga\_figlia.Qta} \times \text{riga\_figlia.FattoreToUM1}}{\text{riga\_padre.FattoreToUM1}}$$
3. **La Logica Padre/Componente (`TipoPC = 'P' / 'C'`) nei Kit Ortofrutta**:
   * Nelle righe di tipo Componente (`TipoPC == 'C'`), azzerare forzatamente `Cd_Aliquota`, `Cd_CGConto` e le provvigioni degli agenti. Le imposte e i ricavi devono gravare unicamente sulla riga Padre (`'P'`).
4. **Il "BUG 5991" sugli Sconti a Cascata (Divergenza Centesimi)**:
   * In ATLAS tutta la matematica usa **Fixed-Point Decimal** deterministico (`Decimal(19,6)` per i prezzi e `Decimal(19,2)` per i totali), calcolando il castelletto IVA per codice aliquota aggregato a norma FatturaPA 1.2.2.
5. **I Campi Custom Ortofrutta (`xColli`, `xLordo`, `xTara`, `Qta Netto`)**:
   * In `DORig` sono presenti i campi personalizzati `xColli` (numero cassette), `xLordo` (peso lordo bilancia), `xTara` (tara imballi).
   * La quantità netta di riga è rigorosamente calcolata come: $\text{Qta} = \text{xLordo} - \text{xTara}$.

---

## 🎨 DESIGN SYSTEM & UI AESTHETICS: STILE APPLE/iOS CON CONTRASTO ELEVATO
* **Stile Moderno e Raffinato (Apple Polish)**:
  * Tipografia nitida su display Retina/HiDPI (font di sistema `SF Pro Display` o `Inter`).
  * Bordi sottili da 1px (`#E5E7EB`), angoli dolcemente smussati (`rounded-md`, 4-6px), icone SVG vettoriali pulite a tratto sottile.
* **Contrasti Netti e Guida Visiva Orizzontale (Zero Abbagli)**:
  * **Riga Selezionata ad Altissima Visibilità**: la riga attiva deve essere **evidenziatissima** (sfondo blu istituzionale Apple `#007AFF` con testo bianco ad alto contrasto e indicatore di bordo sinistro da 4px).
  * **Zebra Striping Delicato**: leggera alternanza di fondo (bianco puro e grigio chiarissimo `#F9FAFB`).
  * **Allineamento Numerico Monospace**: pesi e prezzi con font a spaziatura fissa allineati a destra e decimali perfettamente incolonnati.

---

## 📋 CONFIGURAZIONE REALE DELLA GRIGLIA DOCUMENTI (SETTORE ORTOFRUTTA)
L'ordine delle colonne e le loro larghezze sono state accuratamente calibrate dal titolare (`UserPref` ID 1443 per `PCARCA-2023\Bottamedi`) e **NON VANNO SCONVOLTE**:

### Struttura Testata Documento:
* `Tipo`: **BO** (Bolla Vendita) / **FT** (Fattura)
* `Cliente`: Codice (es. `C000059`) + Ragione Sociale + Indirizzo + Codice Destinatario
* `Data`: `DataDoc` (es. `21-10-2026`)
* `Numero`: `NumeroDoc` / serie contatore
* `Valuta`: `EUR` (Cambio: `1.000000`)
* Schede secondarie mantenute identiche: `Testa`, `Righe` (attiva di default), `Piede`, `Totali`, `Info`, `Evasioni`, `Stampe`.

### Colonne della Griglia Articoli (Ordine Rigoroso da Sinistra a Destra):
1. **Riga**: progressivo numerico (`1, 2, 3...`).
2. **Articolo (`Cd_AR`)**: codice rapido articolo (es. `GEN`, `MIR`, `FRAG`, `LAMPO`).
3. **Descrizione**: descrizione articolo estesa e lotto (es. *INSALATA GENTILE lotto 549*).
4. **UM (`Cd_ARMisura`)**: Unità di Misura principale (es. `KG`, `CO` per colli/casse, `PZ`).
5. **Colli/Qta (`xColli`)**: numero di cassette/colli fisici (es. `1.00`, `5.00`).
6. **Lordo (`xLordo`)**: peso lordo totale pesato sulla bilancia (es. `3.48` kg).
7. **Tara (`xTara`)**: tara delle cassette/imballi (es. `0.30` kg).
8. **Qta/Netto (`Qta`)**: quantità netta venduta calcolata automaticamente: $\text{Qta} = \text{xLordo} - \text{xTara}$ (es. `3.18` kg).
9. **Prezzo Un. (`PrezzoUnitarioV`)**: prezzo unitario a 3 decimali (es. `1.500` €).
10. **Totale (`PrezzoTotaleV`)**: importo totale riga calcolato: $\text{Qta} \times \text{PrezzoUnitarioV}$ (es. `4.77` €).
11. **IVA (`Cd_Aliquota`)**: codice aliquota IVA (default `04` per ortofrutta al 4%).
12. **Fattore (`ColFattoreToUM1`)**: fattore di conversione verso l'unità di misura base.
13. **Note (`colNote`)**: note specifiche di riga.
14. **Qta Evadibile (`COLQTAEVADIBILE`)**: saldo residuo evadibile.
15. **Mag. P. (`ColCd_MG_P`)**: magazzino di partenza (default 001).
16. **Ubicazione P. (`ColCd_MGUbicazione_P`)**: ubicazione fisica magazzino.
17. **Sottocomm... (`ColCd_DOSottoCommessa`)**: commessa/partita.
*(Nota: la colonna Sconto è volutamente collocata in posizione distante poiché non utilizzata nella routine quotidiana).*

### Controlli e Funzioni Speciali a Bordo Griglia:
* **Pulsante "Importa pesate"** (in basso a destra): interfaccia rapida per acquisire i pesi direttamente dalla bilancia.
* **Pulsante "Riferimento..."**: note/collegamento ordini.
* **Casella di spunta `[ ] Evade`**: per forzare l'evasione parziale o totale del documento a monte.

### Sequenza di Battitura da Tastiera (Cadenza Operatore):
`Cd_AR` $\rightarrow$ `Invio` $\rightarrow$ `UM` $\rightarrow$ `Colli` $\rightarrow$ `Invio` $\rightarrow$ `Lordo` $\rightarrow$ `Invio` $\rightarrow$ `Tara` $\rightarrow$ `Invio` $\rightarrow$ `Prezzo` $\rightarrow$ `Invio` $\rightarrow$ Nuova riga (Netto e Totale autocalcolati istantaneamente).

---

## ⚙️ MODULI OPERATIVI E WORKFLOW AZIENDALI

### 1. Risoluzione Definitiva Bug Date (DataDoc vs DataConsegna)
* Quando l'operatore modifica la data del documento in testata, le date di consegna e trasporto nel piede si aggiornano automaticamente in tempo reale (`DataConsegna = max(DataConsegna, DataDoc)`). Nessun popup di blocco.

### 2. Modifica Prezzi Sicura con Scorciatoie da Tastiera e Lookup Prezzi Storici
* **Prezzo Default Automatico**: la riga del DDT acquisisce in automatico il **Prezzo di Listino** (listino base associato).
* **Popup Lookup Prezzi Rapido (`F3` sul campo Prezzo)**:
  * *Ultimo prezzo fatto a QUESTO cliente* (con riferimento esatto del documento e data: es. `BO 2341 del 15/10/2026 - 1,80 €`).
  * *Prezzo più alto fatto oggi per questo articolo* (a chiunque, per monitorare il tetto massimo di vendita odierno).
  * *Ultimo prezzo fatto oggi in assoluto* (a chiunque).
  * Navigazione istantanea con tasti Freccia Su/Giù e conferma con `Invio` per applicare il prezzo al volo nella riga.
* **Protezione Prezzi Anagrafica**: l'anagrafica articoli e i prezzi sono protetti in sola lettura per evitare modifiche involontarie. Si entra in modifica con una scorciatoia rapida da tastiera (es. **`F2`**), si digita il nuovo prezzo e si conferma con **`F10`** (Salva immediato). Massima velocità senza toccare il mouse, ma zero rischio di toccare un prezzo per sbaglio.
* **Griglie Universali Dinamiche**: in qualsiasi tabella (documenti, articoli, clienti), click destro per mostrare/nascondere colonne, riordinarle con drag-and-drop e ridimensionarle. Le impostazioni vengono salvate per singolo utente.

### 3. Gestione Cancellazione Documenti e Staging Disaster Recovery (Menu Blindato)
Flusso di sicurezza operativa per la cancellazione rapida e il recupero da errori materiali dell'operatore:
* L'operatore può eliminare un documento errato premendo in alto il pulsante **"ELIMINA"**.
* Il documento viene rimosso dal gestionale attivo, rendendo il numero progressivo disponibile come buco di numerazione.
* Premendo **`F3`** sul campo numero documento della nuova bolla, si apre l'elenco dei buchi di numerazione da riutilizzare immediatamente per non lasciare salti sequenziali.
* **Disaster Recovery Staging Buffer (Snapshot Locale Cifrato AES-256)**: per proteggere l'azienda da cancellazioni accidentali involontarie durante i ritmi frenetici del carico/scarico, il documento eliminato viene salvato in uno snapshot locale protetto.
* **Menu Blindato (PIN Supervisore)**:
  * **Retention Temporale Configurabile dal Titolare**: il valore predefinito di preset è **0 giorni** (nessun accumulo di default). Dal menu blindato il titolare imposta liberamente i giorni di conservazione degli snapshot (es. 0, 30, 60, 90 giorni).
  * **Pulsante "Ripristina DDT"**: permette al titolare di ricaricare all'istante l'intero documento cancellato con colli, lordo, tara, righe e prezzi originali in caso di sbaglio dell'operatore.
  * **Pulsante "Svuota Staging Definitivamente"**: per pulire manualmente lo staging in qualsiasi momento.

### 4. Fatturazione Differita Fine Mese (Workflow Titolare Senior)
* Schermata identica ad Arca per il titolare: selezione periodo date, selezione cliente, lista con caselle di spunta (checkbox) per selezionare i DDT, e tasto *"Genera Fatture"* (elaborazione batch atomica in <3 secondi).

### 5. Privacy Postazioni (Segregazione Dipendenti vs Titolare)
* **Default Dipendenti al banco**: interfaccia asettica e operativa (*Nuovo DDT, Nuova Fattura, Magazzino, Ricerca*). Nessun totale aziendale, nessun grafico di fatturato, nessun margine e zero chat private visibili.
* **Area Titolare**: protetta da PIN, con Business Intelligence, margini, cassa contanti e CRM WhatsApp.

---

## 🚀 DISTRIBUZIONE, ESEGUIBILE E AGGIORNAMENTO GLOBALE (OTA UPDATER)
1. **Applicazione Desktop Nativa Windows**:
   * Eseguibile nativo autonomo (`Atlas.exe`) generato tramite Tauri v2 con runtime Rust compilato a 64-bit.
   * Installer Windows standard (`Setup_Atlas.exe` / `.msi`), icona aziendale sul desktop e avvio rapido in <1 secondo.
2. **Sistema di Auto-Update Cifrato su Rete Esterna (OTA Update Engine)**:
   * Funzionamento su qualsiasi rete (Wi-Fi ufficio, hotspot 4G, casa, clienti) tramite interrogazione periodica a un endpoint sicuro HTTPS (`latest.json`).
   * **Firma Crittografica Ed25519 / Minisign**: il binario scaricato viene verificato prima dell'esecuzione per impedire qualsiasi manomissione o corruzione.
   * **Banner di Notifica Elegante con Finestra Changelog**: visualizza in Markdown l'elenco delle novità introdotte.
   * **Backup Preventivo del Database & Integrità**: prima di scambiare il binario, il sistema congela e copia il database locale (`backup_pre_update.db`).
   * **Rollback Atomico Istantaneo**: se l'aggiornamento o la migrazione fallisce, l'app ripristina la versione precedente senza alcun fermo operativo.

---

## 🛠️ MODULI FISCALI E ACCESSORI
* **Stampante Fiscale Epson FP-81 II**: comandi testuali diretti `printerFiscalReceipt`, `printRecItem`, `printRecTotal` su socket TCP/IP porta stampante o spooler locale (zero canoni).
* **Fattura Elettronica SdI**: generatore XML FatturaPA 1.2.2 validato, firma CAdES-BES locale, trasmissione sicura TLS 1.3 verificata.
* **Export Excel Nativo**: generazione diretta file `.xlsx` in 0,2 secondi senza richiedere Microsoft Office/Excel installato.
* **CRM WhatsApp**: modulo per pre-compilare i DDT direttamente dai messaggi degli ordini dei clienti.

---

## 📋 ISTRUZIONI DI OUTPUT PER IL CODING AGENT
1. Progetta l'architettura software e lo schema del database ATLAS (SQLite WAL / PostgreSQL) con supporto nativo ai campi `xColli`, `xLordo`, `xTara`, `Qta Netto` e predisposizione JSON Schema per il Function Calling degli LLM.
2. Implementa il Core Engine con matematica `Decimal` e formula $\text{Qta Netta} = \text{Lordo} - \text{Tara}$.
3. Configura la Sandbox di Test: implementa lo Shadow Sync Worker puntando al database clone di sviluppo (`ADB_BOTTAMEDI_DEV`) con Windows Authentication.
4. Implementa l'interfaccia grafica in stile **Apple/iOS ad alto contrasto** (con evidenziazione marcata della riga attiva, font nitidi `Inter/SF Pro`, e griglia colonne conforme al 100% al profilo `UserPref` ID 1443).
5. Implementa la navigazione da tastiera (`Invio`, `F10`, `F12`, `F3`, `F2` per Modifica Protetta Prezzi).
6. Implementa il modulo Disaster Recovery & Undo Staging (snapshot locale cifrato AES-256 dei documenti eliminati, con ripristino rapido 1-click in caso di errore materiale operatore e auto-vacuum a 60-90 giorni).
7. Implementa il modulo Auto-Updater sicuro con firma crittografica, pre-backup e changelog.
