# Copertura delle anagrafiche di Arca in ATLAS

Verifica del 22/10/2026 sulle maschere di Arca e sulle personalizzazioni Bottamedi estratte in
`docs/sorgenti_arca_decompilati/pers_bottamedi/` (`fedi_cfcli`, `fedi_cfdest`, `fedi_articolo`,
`fedi_xarlistdest`, `cmd_xexport*`), sullo schema di `CF` e `AR` del database del negozio
(`04_SCHEMI_DATABASE_E_DATI/schema/schema_arca_core.json`) e sui dati letti dal clone (colonne
obbligatorie di `CF`, trigger, i clienti C000001, C000008, C000041 con i loro contatti).

Legenda: **sì** c'è in ATLAS; **lettura** si vede, si modifica ancora in Arca; **manca** da fare
(con il task); **morta** personalizzazione con il codice ma senza dati in Arca (`ANALISI_ARCA.md` §3.9).

## Colonne

Due prove impediscono che una colonna resti fuori senza saperlo:

- `atlas-sync`, `tutte_le_colonne_di_cf_e_ar_sono_importate`: ogni colonna di `CF` (135) e `AR` (104)
  dello schema del negozio è importata, oppure è in un elenco di escluse con il motivo (identità,
  rowversion, `Reserved_1`, colonne calcolate `*Mks` e classi/gruppi concatenati, cronologia e note in XML,
  che hanno la versione in chiaro `Note_CF`/`Note_AR`).
- `app`, `campi.test.ts`: ogni colonna importata ha il suo campo nella scheda Cliente o Articolo.

`CFDest` e `CFContatto` si importano con `select *`: tutte le colonne, anche quelle che lo schema
esportato non elenca, finiscono nei dati della destinazione e del contatto e la scheda le mostra
("Altri campi di Arca").

## Cliente (`fedi_cfcli`)

| Pagina di Arca | In ATLAS |
|---|---|
| Elenco | **sì**: le colonne di Arca nell'ordine di Arca; Telefono, Fax, Email dal contatto "Aziendale" |
| Generale: codice, ragione sociale, tipo, indirizzo, nazione-provincia, P.IVA con VIES, CF, IPA, obsoleto | **sì** (sezione Anagrafica; VIES con "Nuovo cliente") |
| Generale: telefono, fax, cellulare, email, PEC, URL, persona da contattare | **lettura**: tutti i campi dei contatti importati (`CFContatto`). Il cliente nuovo scrive Telefono, Fax, Email: le altre colonne vanno confermate sul clone prima di scriverle |
| Generale: Storico, Mappa | **manca**: la cronologia (`CF.HistoryData`, XML) non si importa; la mappa non serve al banco |
| Contabilità: conto mastro, banca di sconto, conto merce, IBAN, BIC, ABI/CAB, SDD | **sì** (sezioni Banca e Altro) |
| Varie: zona, settore, classi, gruppi, lingua, valuta, stato, vettore, porto, spedizione | **sì** (Altro, DDT) |
| Destinazioni | **lettura**: tutte le colonne di `CFDest`, compresi codice destinatario e IPA della destinazione e il codice export; si creano e modificano in Arca |
| Esenzioni | **lettura**: aliquota/esenzione (`Cd_Aliquota`) e lettera d'intento (`Cd_CACda`); le dichiarazioni d'intento sono una tabella che ATLAS non importa: **manca** (serve con le fatture, Task 7) |
| Ritenuta | **lettura** del flag `Ritenuta`; i parametri della ritenuta **mancano** (servono solo con le fatture a clienti con ritenuta, Task 7) |
| Listini | **sì**: listino 1 e 2 del cliente; i prezzi del cliente si vedono con F3 nel DDT |
| Movimenti contabili | fuori da ATLAS: la contabilità si tiene fuori da Arca (`ANALISI_ARCA.md`) |
| Documenti | **sì**: gli ultimi 30 DDT del cliente, si aprono nella Gestione Documenti; fatture con il Task 7 |
| Allegati (DMS) | **manca**: Task 7 |
| Export (personalizzazione) | **sì**: `xCd_Exp`. Gli export Conad, Gastropool, Hogast sono **morti** (`xCd_Exp` vuoto ovunque) |
| Nuovo cliente | **sì**: dalla partita IVA, codice successivo, predefiniti di Arca, controlli (P.IVA, CF, IBAN, codice destinatario, lunghezze di `CF`), salvataggio in ATLAS e replica in `CF` + `CFContatto` |
| Modifica ed eliminazione di un cliente | **manca**: per ora in Arca (`CF_atrg_brd` agisce su modifica e cancellazione: va provato sul clone) |
| Fornitori, agenti | **manca**: in Arca |

## Articolo (`fedi_articolo`)

| Pagina di Arca | In ATLAS |
|---|---|
| Elenco | **sì**: Codice … Stato con OB/AF e la legenda Fittizio/Obsoleto; non c'è "Attributi" in colonna (sono nella scheda) |
| Generale: descrizioni, UM, stato, marca, modello, classi, gruppi, kit, fantasma, fittizio, lotto e matricola obbligatori, giacenza non negativa, attributi | **lettura** |
| Altro (personalizzazione): lotto predefinito `xCd_ARLottoP` | **lettura** del codice; la descrizione del lotto (`ARLotto`) non si importa. Il lotto automatico in riga è **morto** (`DO.xLTAutoSet` falso, `DORig.Cd_ARLotto` mai usato) |
| Contabilità: IVA vendite e acquisti, conti, analitica | **lettura**; IVA vendite obbligatoria come in Arca (`xARIvaObb`): la scheda lo segnala se manca |
| Produzione (distinta, MRP) | **lettura** dei campi; distinte non usate |
| Alias/UM | **sì**: unità di misura e fattori |
| Fattura Elettronica | **lettura**: `FTE_CodiceTipo`, `FTE_CodiceValore` |
| Codici alternativi | **morta** (`ARCodCF` vuota) |
| Lotti/Ubicazioni | non usati (0 righe con lotto su 227.484) |
| Immagini | **manca**: le immagini (`ARImg`) non si importano |
| eBusiness | **lettura** |
| Valori, Magazzino | **lettura** di costo, ricarico, scorte, lotti, pesi; la giacenza non è significativa in Arca |
| Listini | **sì**: prezzo valido oggi in ogni listino |
| Documenti | **manca**: le righe di DDT dell'articolo (serve un'API; oggi F3 dà ultimi prezzi per cliente) |
| DMS, Analisi | **manca**: Task 7 |
| Nuovo, modifica, eliminazione | **manca**: in Arca |

## Personalizzazioni che toccano le anagrafiche

| Personalizzazione | Stato |
|---|---|
| `xARListDest`: prezzo e sconto per cliente + destinazione + articolo, che `fedi_doc` mette in riga sopra il listino | **morta** (tabella vuota); se il titolare la vuole usare, va letta in `bozza.rs` dopo il listino, come fa `xGetPriceByDest` |
| `CF.xCd_Exp`, `CFDest.xCd_Exp`: codici per gli export | importati; export **morti** |
| IVA vendite obbligatoria in anagrafica articolo | segnalata nella scheda; obbligatoria quando ATLAS creerà articoli |
| Lotto predefinito | vedi sopra |

## Da verificare sul clone

- `CFContatto`: la colonna del tipo è `Id_CFContattoTipo` (così nei sorgenti di Arca; i dati mostrano -1
  "Aziendale", 1 persona). ATLAS scrive `Cd_CF`, `Descrizione` = "Aziendale", `Telefono`, `Fax`, `Email`,
  `Id_CFContattoTipo` = -1. Una prova di replica di un cliente nuovo sul clone lo conferma.
- `CF.Id_Lingua`: 1040 sui clienti veri (italiano), messo come predefinito.
