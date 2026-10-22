# Analisi di Arca Evolution in uso presso Bottamedi

Rilevata il 21-22/10/2026 su `PCARCA-2023 / ADB_BOTTAMEDI`, in sola lettura (`bihortus_reader`
per i dati, autenticazione Windows solo per leggere metadati). Ogni affermazione riporta la misura
che la sostiene. Questo documento prevale sul "Super Prompt" dove i due divergono.

## 1. Perimetro reale

| Area | Uso misurato | Conseguenza per ATLAS |
|---|---|---|
| Documenti vendita | BO 5.455, FA 569, FT 551, NC 7 nel 2026 | Cuore della V1 |
| Ordini (OC/OF), bolle fornitore (BF) | 0 nel 2026; BF ferme al 2019 | Fuori V1 |
| Magazzino | 1 magazzino; movimenti solo da BO/FA; 12 manuali dal 2025; nessun carico da acquisto | Giacenza Arca non significativa: niente "verifica giacenza" finché non si caricano gli acquisti |
| Contabilità generale | Solo registrazioni automatiche: causale 01 (1.122) e 02 (7) nel 2026 | Prima nota e liquidazione si fanno fuori da Arca; ATLAS genera solo ciò che serve all'export |
| Scadenzario | 1 scadenza per fattura (1.129 nel 2026) | Necessario: incassi, RiBa |
| Fattura elettronica attiva | Hub Wolters Kluwer; esiti RC/MC/NS archiviati nel DMS | Serve un canale SdI sostitutivo (decisione aperta) |
| Fatture passive | `FTE_InBox` 1.640 nel 2026 | Già lette dal CRM (motore acquisti) |
| DMS | PDF di ogni FA/FT/NC + XML + esiti | ATLAS archivia PDF/XML propri |
| Vendita al banco (scontrini) | 38 scontrini in totale | Bassa priorità; il driver Epson esiste già nel MCP di produzione |
| Postazioni | 6.583 documenti 2026 inseriti da un solo utente, da questo PC | Un'installazione principale; telefono/CRM/HERMES via API |
| Dimensione DB | 3,7 GB, 138 tabelle con dati su 383 | Migrazione storica fattibile in minuti |

Clienti attivi 2026: 88 (ristorazione, scuole, catering, un Despar). Fatturato 2025: 967.259,72 €
(fonte: CRM, verificato con SQL indipendente).

## 2. Regole di calcolo verificate sullo storico

| Regola | Verifica |
|---|---|
| `Qta = Lordo − Colli × Tara`; se Lordo = 0 allora `Qta = Colli`. La tara è **per collo** | 359.052 righe 2024-2026 |
| Totale riga = `Qta × (Prezzo × (1 − sconto) + addizionale)`, arrotondamento a metà lontano da zero, 2 decimali | 13.694 casi limite, 0 contrari |
| Sconto in cascata: `"1"` + `"1"` → fattore 0,0199 | 2 righe (gli sconti sono quasi inutilizzati) |
| Castelletto: imponibile per aliquota = somma importi; imposta = imponibile × % arrotondata; totale = Σ imponibili + Σ imposte | 14.475 documenti su 14.475 (2025-2026) |
| Spese d'incasso: RiBa (R030, R060) 3,50 € con IVA 04, come riga spesa | 291 documenti 2025-2026 |
| Netto a pagare = totale − IVA se in scissione dei pagamenti (art. 17-ter) − acconto − abbuono | 14.475 su 14.475; 33 in scissione (Fondazione Mach, Comune di San Michele, Museo etnografico) |
| Scadenze delle note di accredito con segno negativo | 19 su 19 |
| Scadenze "DF FM": fine mese della data documento + giorni/30 mesi, a fine mese | 9.373 su 9.373 dal 2019 (186 casi distinguono le interpretazioni) |
| Sezionale fatture unico FA+FT+NC, annuale | 2023-2026: 0 buchi, 0 doppioni |
| Sezionale bolle annuale | buchi ogni anno (384 nel 2024, 1 nel 2026) |
| Fattura differita: una per cliente + condizione di pagamento nel mese; destinazioni miste ammesse | 97.388 righe 2025-2026 |
| In fattura differita ogni DDT apre con `D.D.T. NR. BO   4467     DEL 01-09-2026`; righe copiate 1:1 con pesata | 47.802 righe 2026 |
| Aliquota di riga = `AR.Cd_Aliquota_V`, altrimenti `Impostazione DEFAULT_RIGHE_DOC.Cd_Aliquota_2` (04); conto ricavo = `Cd_CGConto_2` (07010101001) | 101.090 e 101.094 righe BO su 101.094 (2025-2026) |
| Testata BO: pagamento, listino, IBAN, BIC, agente, scissione dal cliente (`CF`) | 99,8-100% di 11.885 BO 2025-2026 (differenze: anagrafica cambiata dopo) |

Il programma `atlas-verify` ripete tutte queste verifiche sul motore Rust.

### Esito di `atlas-verify` (22/10/2026)

- 2025-2026: 14.475 documenti, 227.462 righe. Tutti i controlli di regola al 100%. Restano 6 anomalie
  di dato: 3 righe con Qta incoerente con la propria pesata (BO 5791/2025, BO 2379/2026, FT 962/2026) e
  3 fatture differite del 31/10/2025 per il cliente C000350 compilate a mano senza collegamento ai DDT.
- 2018-2026: 60.496 documenti, 1,6 milioni di righe, caricati e verificati in 11 s. Totale riga e
  sconto al 100% su ogni anno. Difformità solo storiche: 2018 (primo anno, dati migrati: 4.392 righe
  FT e 422 riferimenti DDT in formato diverso); settembre-ottobre 2023 (56 documenti: Arca troncava
  l'IVA invece di arrotondarla, es. 634,14 × 4% = 25,3656 registrato 25,36); 2019-2022 (5 documenti
  con righe IVA a zero conservate); 13 righe e 5 fatture corrette a mano negli anni.
- Conseguenza: lo storico si migra **com'è registrato**, mai ricalcolato.

## 3. Correzioni al "Super Prompt"

1. **Formula del netto sbagliata.** Il piano dice `Lordo − Tara`: è errata sul 13% delle righe a peso.
   La regola vera è nel codice Tecnobit (`fedi_doc.xAssegnaPesoNetto`), vedi §2.
2. **Trappola `Reserved_1`.** A riposo vale `0000000000` su tutte le 1.091.657 righe e le 60.502
   testate: la macchina a stati è transitoria. 507 stored procedure su 527 e 363 trigger su 408 sono
   cifrati. La replica verso Arca va quindi provata **a scatola nera** sul clone, non dedotta.
3. **Trappola fattore UM.** `FattoreToUM1` vale 1 su tutte le righe salvo 2: non è un rischio reale.
4. **Trappola kit padre/componente.** `TipoPC` mai valorizzato (0 righe su 358.841).
5. **Manca la Fattura Immediata (FA)**, 569 nel 2026: vale anche come DDT e scarica il magazzino.
6. **Colonne Ubicazione e Sottocommessa**: tabelle vuote, colonne sempre vuote.
7. **Provenienza e categoria** (obbligatorie per l'ortofrutta) sono in stampa: provenienza =
   `AR.Cd_ARClasse1` (IT, ES, CR…), categoria da verificare sul layout di stampa.
8. **Lotto**: `DORig.Cd_ARLotto` mai usato (0 su 227.484). Il lotto è scritto nella descrizione
   dell'articolo e modificato a mano a ogni cambio partita.
9. **Personalizzazioni morte** (codice presente, configurazione assente): export Conad, Gastropool,
   Hogast (`CF.xCd_Exp` vuoto ovunque), listini per destinazione (`xARListDest` vuota), codici
   alternativi (`ARCodCF` vuota), cambio massivo listini (`Preferenza.xCd_LSMod1-4` nulli), import
   ordini da tablet (`importdtv`: tipo documento `DTV` inesistente), lotto predefinito
   (`DO.xLTAutoSet` falso ovunque).
10. **Personalizzazioni vive**: netto da pesata (documenti e scontrino); pulsante "Importa pesate"
    (CSV `Codice;Lordo;Tara;Colli;Lotto` letto da `PERS\DoImportAscii\Data.txt` o dal percorso in
    `NFile.ini`, con backup in `NFILE_BAK`; cartella assente su questo PC: uso da confermare);
    destinazione e località nell'elenco documenti; IVA obbligatoria in anagrafica articolo; stampa
    consentita solo per documenti esecutivi.

## 4. Prezzo proposto in riga (da chiarire con l'utente)

Su 54.068 righe 2026: coincide con l'ultimo prezzo venduto a chiunque nell'81%, con l'ultimo
prezzo allo stesso cliente nel 67%, con il listino 1 nel 24%; nessuno dei tre nel 9%. Il listino è
aggiornato spesso (258 modifiche nel 2026). Va osservato in Arca quale prezzo viene proposto.

## 5. Ecosistema esistente

- **CRM WhatsApp Bottamedi** (FastAPI + React/TypeScript + SQLite, attivo): legge Arca, motore
  acquisti e margini dalle fatture passive, incassi e banca, listini PDF, nuovi clienti, app telefono.
- **HERMES** (agente WhatsApp), **BOTTAMEDI_MCP_PRODUCTION** (MCP Arca + guardiano stampante Epson).
- Tutti leggono `ADB_BOTTAMEDI` direttamente. ATLAS diventa la loro fonte dati unica tramite API.
- La password di `bihortus_reader` è scritta in chiaro in decine di file e README: va ruotata e
  spostata in variabili d'ambiente prima di esporre qualsiasi API.

## 6. Fonti

- Database: `ADB_BOTTAMEDI` (lettura), schema completo esportato con `dumpschema.py`.
- Personalizzazioni: `C:\Program Files (x86)\Artel\ArcaEvolution\PERS\BOTTAMEDI\` (estratte da
  `.vcx/.vct`; `fedi_doc_ad/_ca/_cp` sono copie identiche di `fedi_doc`).
- Stampe: PDF archiviati in `DmsDocument` (FA, FT, NC).

## 7. Scrittura su Arca a scatola nera (22/10/2026, su `ADB_BOTTAMEDI_DEV`)

### 7.1 Sequenza di salvataggio (dal sorgente)
`fedi_doc_extracted.prg:36395` (`de.update_cursors`), per inserimento e modifica:
`asp_Do_Begin <Id_DoTes>, 1` → scrittura dei cursori (DOTes, DORig, DORigSpesa…) →
`asp_Do_End <Id_DoTes>, <opzioni>`, con opzioni = 1 spese incasso, 2 bolli, 128 salta Intra
(solo in inserimento con cliente non Intra; un BO nuovo usa 128). La cancellazione passa da
`asp_Do_Del <Id_DoTes>` (`:36604`). `Reserved_1` non è mai scritto dal client.
Numero documento: se vuoto lo assegna il server; i buchi di F3 vengono da
`dbo.UnusedCodes_DoTes(contabile, data, Cd_CN)`, che restituisce ogni numero libero con l'intervallo
di date ammesso (es. `5447 [21/10/2026 21/10/2026]`, `5457 [22/10/2026 31/12/2026] Prossimo valore disponibile`).
Sezionali: BO → `D00` (tipo M), FA/FT/NC → `001` (tipo A).

### 7.2 Misure
- Impronta di un BO (Id 108602, 14 righe): DOTes 1, DORig 14, DOTotali 1, DOIva 1, MGMov 14.
  Una FA (Id 108598, 15 righe) aggiunge SC 1, CGMovT 1, CGMovT_NumProt 1.
- `Reserved_1` dopo `INSERT DOTes` vale `I0000000I0`; `asp_DO_Begin` lo riporta a `0000000000`.
- La sessione deve avere `QUOTED_IDENTIFIER ON` (indici su colonne calcolate).
- Il trigger `DORig_atrg_brd` chiama `asp_MGMovDocIns`, che rifiuta con errore 50000
  "Funzionalità non disponibile al di fuori del prodotto" e annulla la transazione.
- Il controllo è `afn_IsArcaConnection(spid)` (CLR, assembly `BlsCode`, classe `Wki.Arca.BLS.SVF`).
  Vale 1 solo per la sessione di Arca che ha `CONTEXT_INFO` di 128 byte: `00000003 00000001`, zeri,
  e 32 byte finali non nulli (gettone generato da Arca all'accesso). Nome applicazione
  `Arca Evolution` e i primi 8 byte di contesto, da soli o insieme, non bastano (provato).
- Ogni prova è avvenuta in transazione: il clone è rimasto senza residui (verificato).

### 7.3 Opzioni per la replica verso Arca (decisione del titolare)
1. **Aggirare il controllo** (riusare o ricostruire il gettone decompilando `BlsCode`). Tecnicamente
   probabile, ma elude una protezione del fornitore: rischio contrattuale e di assistenza, e un
   aggiornamento di Arca può romperlo senza preavviso.
2. **Scrittura diretta delle tabelle con i trigger disattivati**, riproducendo ciò che Arca registra
   (le regole sono già verificate al 100% da `atlas-verify`). Sicuro sul clone; sulla produzione
   significa toccare i trigger del fornitore.
3. **Passare da Arca stessa**: ATLAS produce il file pesate (`Codice;Lordo;Tara;Colli;Lotto`) che la
   personalizzazione "Importa pesate" già legge; l'operatore salva in Arca. Nessuna elusione, ma
   non automatico.
4. **Nessuna replica**: ATLAS diventa fonte unica per i DDT e Arca resta in sola lettura per lo
   storico e per ciò che ATLAS non fa ancora (fattura elettronica via Hub).

### 7.4 Scrittura diretta delle tabelle (scelta del titolare, 22/10/2026)
Implementata in `crates/atlas-arca`; prova con `prova-ddt` solo su database `*_DEV`.
- Footprint del salvataggio nativo (BO 108602, rowversion 78440160-78440239): DOTes 1, DORig 14, MGMov 14,
  DOTotali 1, DOIva 1; nessun'altra tabella con rowversion; le tabelle senza rowversion popolate sono statiche.
- `DOTes_atrg_brd`: all'INSERT imposta `Reserved_1 = I0000000I0`, `UserIns = host;login;app`, `TimeIns = now`, e
  rifiuta la modifica di quelle colonne (900000). `DORig_atrg_brd`: blocca (50000). `MGMov_atrg`: accetta.
  Disattivati per nome nella transazione di scrittura; riattivati prima del commit.
- Regole misurate sui 5.455 BO 2026 e verificate dal replay (5.452/5.452 identici alla creazione):
  `NumeroDoc` = numero allineato su 6 + 4 spazi; `Cd_LS_2` = `DO.Cd_LS_1`; trasporto/spedizione/porto/aspetto da `DO`;
  `QtaEvadibile = Qta`, `RigheMerceEvadibili = RigheMerce` alla creazione; `PrezzoTotaleMovE = PrezzoTotaleV`;
  `TotMerceLordoV = Σ round(Qta × prezzo, 2)` (con sconto 1+1 sul BO 97126 differisce dal netto);
  `DOIva.ImpostaV_NA = round(imponibile × aliquota / 100, 6)`; un `MGMov` per riga con quantità ≠ 0 nei documenti
  esecutivi, con `Quantita = Qta × FattoreToUM1`, `Valore = PrezzoTotaleMovE`, segni dai flag `PP*Q` della causale 003.
- Dopo la creazione Arca modifica il BO quando lo evade in fattura differita (`QtaEvadibile` → 0,
  `RigheMerceEvadibili` → 0) o quando l'operatore lo chiude (`Evasa`) o lo corregge (`TimeUpd`).
- Stato delle FK sulle 5 tabelle: 70 su 83 `is_not_trusted` e 3 disattivate già in produzione (schema del fornitore).
