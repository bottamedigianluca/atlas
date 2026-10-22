# PROGETTOX8 — Rapporto di Decompilazione e Reverse Engineering Completo di Arca Evolution

Data analisi: 21 Ottobre 2026  
Target: Wolters Kluwer / Artel Arca Evolution  
Directory di lavoro: `C:\Users\Bottamedi\.gemini\antigravity\scratch\progettox8\`

---

## 1. Sommario Esecutivo

L'intero impianto software di Arca Evolution è stato sequenziato, decompilato e convertito in sorgenti in chiaro leggibili:
1. **Ambiente .NET (C#)**: decompilate tutte le librerie core (`ArcaNet.dll`, `WkiSigner.dll`, `SdC.RestAPI.SDK.dll`, `Artel.Arca.NIC.dll`).
2. **Decifratura stringhe offuscate**: implementato e applicato con successo l'algoritmo di deoffuscamento SmartAssembly per estrarre tutti gli endpoint REST, token, chiavi e messaggi di errore nascosti in chiaro (`FepaHubClient_clear.cs`, `WkiHub_clear.cs`, `FatturaElettronicaType_clear.cs`).
3. **Ambiente Visual FoxPro (VFP 9.0)**: estratte direttamente dai file di classe binari `.vcx`/`.vct` oltre **2.5 Megabyte** di codice sorgente originale in chiaro (`fedi_doc_extracted.prg`, `fedi_cgmovt_extracted.prg`, `Cmd_DoPrelievoCreazione_extracted.prg`, `ECR_Epson_RT_extracted.prg`).
4. **Modello Dati e Macchina a Stati SQL Server**: mappata l'intera struttura di tabelle (`DOTes`, `DORig`, `CF`, `AR`, `FTE_WorkFlow`, `FTE_Mapping`, `FTE_InBox`, `FTELog`).

---

## 2. Architettura Estratta e Funzionamento Interno

### A. Trasmissione Fattura Elettronica a SDI (`ArcaNet.FatturaPA4Vfp`)
Arca comunica con lo SDI attraverso due canali mappati nel codice:
1. **Canale Cloud Wolters Kluwer Hub (Default per Arca Evolution)**:
   - Client: `WkiHub` / `FepaHubClient`.
   - Endpoint Base: `https://apife-test.wolterskluwer.it/API/` (Collaudo) / Endpoint produzione WKI.
   - Endpoint Invio: `POST FattureAttive/v2/{prodotto}/{licenza}/{idFatturaProd}/{formatoFile}[/ApplySign]`
     - `formatoFile`: `PlainXml` per file `.xml`, `Cades` per file firmati `.p7m`.
     - Payload: byte dell'XML / P7M in `ByteArrayContent`.
     - `ApplySign`: booleano per richiedere la firma automatica da remoto sull'Hub WKI.
   - Endpoint Esiti: `GET FattureAttive/Esiti/v2/{prodotto}/{licenza}/{idFatturaProd}`
   - Endpoint Ciclo Passivo: `POST FatturePassive/Lista/v2/{prodotto}/{licenza}` e `GET FatturePassive/v2/{prodotto}/{licenza}/{idFatturaRx}`.
2. **Canale Diretto SOAP SdI (`SdITrasmissioneFileClient`)**:
   - WSDL ufficiale Agenzia delle Entrate implementato con contratti WCF `Trasmetti` ed `Esito`.
3. **Firma Digitale CAdES (`WKISigner.CadesSigner`)**:
   - Firma PKCS#7 / CAdES-BES conforme ad AgID: algoritmo digest SHA-256 (`2.16.840.1.101.3.4.2.1`), attributo `SigningTime` e attributo `SigningCertificateV2` (`1.2.840.113549.1.9.16.2.47`).

---

### B. Vincoli e Regole di Validazione (Zero Errori)
Nel sorgente `FatturaElettronicaType_clear.cs` e `fedi_doc_extracted.prg` sono cablate le regole inderogabili:
1. **Controllo Aliquota IVA e Natura (Codice 400)**:
   - Se `AliquotaIVA == 0` -> Il campo `Natura` (es. `N4`, `N3.2`, ecc.) è **obbligatorio** a pena di scarto immediato.
   - Se `AliquotaIVA != 0` -> Il campo `Natura` è **vietato**.
2. **Controllo Data Fattura (Codice 403)**:
   - La data del documento non può essere successiva alla data di generazione/invio (`Data > DateTime.Today`).
3. **Controllo Ritenuta d'Acconto (Codici 411, 415)**:
   - Se una linea ha `Ritenuta == SI` o c'è una cassa previdenziale soggetta a ritenuta, il blocco `DatiGenerali/DatiGeneraliDocumento/DatiRitenuta` deve essere presente.
4. **Controllo Cessionario/Committente (Codice 417)**:
   - Almeno uno tra `IdFiscaleIVA` (Partita IVA) e `CodiceFiscale` deve essere valorizzato.
5. **Controllo Importi Negativi**:
   - Acconto percentuale: `If This.Value < 0 -> Return 0` ("L'acconto percentuale non può essere negativo").
   - Acconto fisso: `If This.Value < 0 -> Return 0` ("L'acconto fisso non può essere negativo").
   - Spese accessorie/incasso: `If oControl.Value < 0 -> Return .F.` ("L'importo delle spese non può essere negativo").
   - Righe documento: le note di variazione/accredito usano il tipo documento dedicato `TD04` con quantità positive e prezzi positivi, oppure righe di storno esplicite conformi alle specifiche tecniche SDI.

---

### C. Macchina a Stati Documentale e Blocco Modifiche (`FTE_WorkFlow`)
Il ciclo di vita del documento è tracciato nella tabella `FTE_WorkFlow` e verificato da `fedi_doc_extracted.prg` (righe 10359 e 11859):

| Codice Stato | Descrizione | DaInviare | InviatoHUB | InviatoSDI | Modificabile | Regola di Blocco in Arca |
|---|---|---|---|---|---|---|
| `NULL` | Documento non elettronico | 0 | 0 | 0 | 1 | Modificabile liberamente |
| `000` | Elettronico pronto per l'invio | 1 | 0 | 0 | 1 | Modificabile liberamente prima dell'invio |
| `IN1` | Inviato a HUB WKI | 0 | 1 | 0 | 0 | **BLOCCATO**: "Documento in elaborazione. Modifica/cancellazione inibita." |
| `IN2` | Scartato da HUB WKI | 0 | 1 | 0 | 1 | **SBLOCCATO**: Errore di connessione o formato, modificabile per correzione |
| `IN3` | Trasmesso a SDI | 0 | 0 | 1 | 0 | **BLOCCATO RIGIDO**: Non modificabile |
| `RC` | Consegnato al Cliente | 0 | 0 | 1 | 0 | **BLOCCATO DEFINITIVO**: Fattura valida fiscalmente, sola emissione Nota Credito ammessa |
| `MC` | Mancata Consegna (cassetto fiscale) | 0 | 0 | 1 | 0 | **BLOCCATO DEFINITIVO**: Fattura valida emessa |
| `NS1` | Notifica di Scarto SDI | 0 | 0 | 1 | 1 | **SBLOCCATO TEMPORANEO**: 5 giorni di tempo per correggere ed emettere con stesso numero |

---

### D. Motore Prelievo DDT in Fattura Differita (`Cmd_DoPrelievoCreazione_extracted.prg`)
La procedura `preparazionetestatmp` e `preparazionerighetmp` definisce l'algoritmo esatto:
1. Seleziona tutti i DDT (`TipoDocumento == 'BO'`) per lo stesso Cliente (`Cd_CF`) e con le stesse condizioni di pagamento (`Cd_PG`).
2. Crea la nuova fattura differita (`TipoDocumento == 'FT'`).
3. Per ogni riga DDT selezionata:
   - Copia riga in fattura differita valorizzando `Id_DORig_Evade = DoRig.Id_DORig`.
   - Incrementa `QtaEvasa` sul DDT originale.
   - Inserisce i metadati di correlazione che finiranno nel blocco `<DatiDDT>` dell'XML SDI: `NumeroDDT` e `DataDDT`.

---

### E. Driver Stampante Fiscale Epson FP-81 II (`ECR_Epson_RT_extracted.prg`)
Il modulo scontrini comunica direttamente con `EpsonFpMate` attraverso file di comando:
- Formato comandi:
  - Intestazione: `printerFiscalReceipt\r\nPrinter|1\r\n`
  - Codice Fiscale (scontrino parlante): `directIO|opCodFiscale|<Operatore>|<CodiceFiscale>\r\n`
  - Partita IVA: `directIO|opPartitaIVA|<Operatore>|<PartitaIVA>\r\n`
  - Righe vendita: `printRecItem|...`
  - Chiusura/Subtotale: `printRecTotal|...`
  - Reso / Annullo: `printRecRefund|...`
Nel codice è presente l'esplicito commento di personalizzazione: `&& Tecnobit (1)`.

---

## 3. Mappatura File nel Progetto `progettox8`

Tutto il materiale decompilato e pronto per la ricostruzione è conservato in:
- `C:\Users\Bottamedi\.gemini\antigravity\scratch\progettox8\`
  - `decompiled/ArcaNet/` -> Codice C# completo di ArcaNet
  - `decompiled/ArcaNet/ArcaNet.FatturaPA4Vfp/FepaHubClient_clear.cs` -> Client REST SDI decifrato
  - `decompiled/ArcaNet/ArcaNet.FatturaPA4Vfp/WkiHub_clear.cs` -> Wrapper WKI decifrato
  - `decompiled/ArcaNet/ArcaNet.FatturaPA4Vfp/FatturaPATypes/Fattura_v1_2/FatturaElettronicaType_clear.cs` -> Generatore XML e controlli
  - `decompiled/WkiSigner/` -> Firma CAdES-BES
  - `vfp_extracted/fedi_doc_extracted.prg` -> 901 KB logica documenti
  - `vfp_extracted/fedi_cgmovt_extracted.prg` -> 566 KB contabilità generale
  - `vfp_extracted/Cmd_DoPrelievoCreazione_extracted.prg` -> 135 KB prelievo DDT in fattura
  - `vfp_extracted/ECR_Epson_RT_extracted.prg` -> 52 KB driver Epson FP-81 II RT
  - `deobfuscate_file.ps1` -> Tool automatico di decifratura stringhe
  - `parse_vfp.py` -> Estrattore bytecode/memo VFP
