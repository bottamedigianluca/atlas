// I campi delle schede Cliente e Articolo, con i nomi delle colonne di Arca (`CF`, `AR`): la
// scheda è una pagina sola a sezioni, "snella ma con tutto completa". Ogni colonna che ATLAS
// importa da Arca ha il suo posto in una sezione (lo controlla `campi.test.ts` sull'elenco delle
// colonne dell'importazione, `CF_EXTRA` e `AR_EXTRA` in `atlas-sync/src/anagrafiche.rs`).
//
// Il valore di un campo si legge da un "record" con le chiavi di Arca: i campi della scheda del
// backend rinominati (`ragione_sociale` → `Descrizione`…) più `extra`, che ha già i nomi di Arca.
// Lo stesso record sarà quello da scrivere in `CF`/`AR` quando ATLAS salverà le anagrafiche.

import type { ArticoloScheda, CampiArca, ClienteScheda, DatiAzienda, NuovoCliente, Tabelle } from "../api/tipi";
import { data as fData, mostra } from "../griglia/numeri";

export type Valore = string | number | boolean | null;
export type Record_ = Record<string, Valore>;

export type TipoCampo = "testo" | "spunta" | "numero" | "data" | "nota";

export interface CampoScheda {
  /** La colonna di Arca. */
  colonna: string;
  etichetta: string;
  tipo?: TipoCampo;
  /** Larghezza del campo in pixel (testi e numeri). */
  larghezza?: number;
  /** Tabella di codifica per la descrizione accanto al codice. */
  decodifica?: keyof Tabelle;
  /** Valori fissi con il loro significato ("F" persona fisica…). */
  scelte?: Record<string, string>;
  /** Decimali con cui mostrare un numero (`mostra`). */
  decimali?: number;
  suggerimento?: string;
}

export interface SezioneScheda {
  id: string;
  titolo: string;
  campi: CampoScheda[];
  /** Testo sotto il titolo: da dove vengono i dati, cosa manca. */
  nota?: string;
}

const t = (colonna: string, etichetta: string, larghezza = 90, altro: Partial<CampoScheda> = {}): CampoScheda => ({
  colonna,
  etichetta,
  larghezza,
  ...altro,
});
const s = (colonna: string, etichetta: string, suggerimento?: string): CampoScheda => ({ colonna, etichetta, tipo: "spunta", suggerimento });
const n = (colonna: string, etichetta: string, decimali = 0, larghezza = 70): CampoScheda => ({ colonna, etichetta, tipo: "numero", decimali, larghezza });
const d = (colonna: string, etichetta: string): CampoScheda => ({ colonna, etichetta, tipo: "data", larghezza: 90 });

// ---------------------------------------------------------------- Clienti

/** Prefisso dei campi del contatto "Aziendale" (`CFContatto`) nel record del cliente. */
export const CONTATTO = "CFContatto.";

/** I campi della scheda del backend con il nome della colonna di `CF`. */
const CLIENTE_ARCA: [keyof ClienteScheda, string][] = [
  ["codice", "Cd_CF"],
  ["ragione_sociale", "Descrizione"],
  ["indirizzo", "Indirizzo"],
  ["cap", "Cap"],
  ["localita", "Localita"],
  ["provincia", "Cd_Provincia"],
  ["nazione", "Cd_Nazione"],
  ["partita_iva", "PartitaIva"],
  ["codice_fiscale", "CodiceFiscale"],
  ["codice_destinatario", "CodiceFPR"],
  ["codice_ipa", "CodiceIPA"],
  ["pagamento", "Cd_PG"],
  ["listino", "Cd_LS_1"],
  ["agente", "Cd_Agente_1"],
  ["iban", "Iban"],
  ["bic", "BicCode"],
  ["conto_banca", "Cd_CGConto_Banca"],
  ["conto_merce", "Cd_CGConto_Merce"],
  ["scissione_pagamenti", "IvaSplit"],
  ["ente_pubblico", "EntePubblico"],
  ["aliquota", "Cd_Aliquota"],
  ["cliente_fatturazione", "Cd_CF_Fatt"],
  ["fido", "Fido"],
  ["note", "Note_CF"],
  ["obsoleto", "Obsoleto"],
];

export function recordCliente(c: ClienteScheda): Record_ {
  const r: Record_ = { ...(c.extra ?? {}) };
  for (const [campo, colonna] of CLIENTE_ARCA) r[colonna] = c[campo] as Valore;
  const aziendale = c.contatti.find((k) => !k.destinazione && k.dati.Id_CFContattoTipo === -1) ?? c.contatti.find((k) => !k.destinazione);
  for (const [chiave, valore] of Object.entries(aziendale?.dati ?? {})) r[CONTATTO + chiave] = valore;
  return r;
}

/** Il corpo di `POST /api/clienti`: i campi di `CF` e quelli del contatto aziendale. */
export function corpoNuovoCliente(r: Record_): NuovoCliente {
  const cf: CampiArca = {};
  const contatto: CampiArca = {};
  for (const [chiave, valore] of Object.entries(r)) {
    if (chiave.startsWith(CONTATTO)) contatto[chiave.slice(CONTATTO.length)] = valore;
    else cf[chiave] = valore;
  }
  return { cf, contatto: Object.values(contatto).some((v) => v !== null && v !== "") ? contatto : null };
}

export const SEZIONI_CLIENTE: SezioneScheda[] = [
  {
    id: "anagrafica",
    titolo: "Anagrafica",
    campi: [
      t("Cd_CF", "Codice", 80),
      t("Descrizione", "Ragione sociale", 420),
      t("TipoDitta", "Tipo figura", 40, { scelte: { F: "persona fisica", G: "persona giuridica" } }),
      t("PartitaIva", "Partita IVA", 120),
      t("Cd_NazioneIva", "Nazione IVA", 40),
      t("CodiceFiscale", "Codice fiscale", 150),
      t("Peppol_Endpoint", "PEPPOL", 160),
      t("Indirizzo", "Indirizzo", 320),
      t("Cap", "CAP", 60),
      t("Localita", "Località", 200),
      t("Cd_Provincia", "Prov.", 40),
      t("Cd_Nazione", "Nazione", 40),
      t("Cd_NazioneProvincia", "Nazione-prov.", 60, { suggerimento: "Calcolato da Arca" }),
      s("Obsoleto", "Obsoleto"),
    ],
  },
  {
    id: "contatti",
    titolo: "Contatti",
    nota: "I contatti del cliente in Arca (CFContatto): l'\"Aziendale\" con telefono e fax dell'azienda, poi le persone.",
    campi: [
      t(`${CONTATTO}Telefono`, "Telefono", 130),
      t(`${CONTATTO}Fax`, "Fax", 130),
      t(`${CONTATTO}Email`, "Email", 260),
    ],
  },
  {
    id: "fe",
    titolo: "Fatturazione elettronica",
    campi: [
      t("CodiceFPR", "Codice destinatario", 80),
      s("FE_Ignore_CodiceFPR", "Ignora codice destinatario"),
      t("CodiceIPA", "Codice IPA", 80),
      s("EntePubblico", "Ente pubblico"),
      s("IvaSplit", "Split payment"),
      s("IvaSplitLog", "Split payment (registro)"),
      s("IvaSospesa", "IVA sospesa"),
      n("Tipofattura", "Tipo fattura", 0, 40),
      t("Cd_Aliquota", "Aliquota / esenzione", 50, { decodifica: "aliquote" }),
      t("CD_ReverseCharge", "Reverse charge", 60),
      n("FTE_AutoTipo", "Autofattura", 0, 40),
      t("FTE_RegimeFiscale", "Regime fiscale", 60),
      t("FTE_Cd_CN", "Sezionale FE", 50),
      t("Cd_CACda", "Lettera d'intento", 160),
      s("FE_AddASW", "Aggiungi ASW alla fattura", "Allegato AssoSoftware nell'XML della fattura (FE_AddASW)"),
    ],
  },
  {
    id: "so",
    titolo: "Stabile organizzazione e rappresentante fiscale",
    nota: "Per i clienti esteri nella fattura elettronica.",
    campi: [
      t("SO_Indirizzo", "S.O. indirizzo", 260),
      t("SO_NumeroCivico", "Civico", 60),
      t("SO_Cap", "CAP", 60),
      t("SO_Localita", "Località", 180),
      t("SO_Cd_Provincia", "Prov.", 40),
      t("SO_Cd_Nazione", "Nazione", 40),
      t("RF_PartitaIva", "R.F. partita IVA", 140),
      t("RF_Cd_Nazione", "Nazione", 40),
      t("RF_RagioneSociale", "R.F. ragione sociale", 260),
      t("RF_Nome", "Nome", 160),
      t("RF_Cognome", "Cognome", 160),
    ],
  },
  {
    id: "condizioni",
    titolo: "Condizioni",
    campi: [
      t("Cd_PG", "Pagamento", 60, { decodifica: "pagamenti" }),
      t("Cd_LS_1", "Listino 1", 80, { decodifica: "listini" }),
      t("Cd_LS_2", "Listino 2", 80, { decodifica: "listini" }),
      t("Cd_Agente_1", "Agente 1", 60, { decodifica: "agenti" }),
      t("Cd_Agente_2", "Agente 2", 60, { decodifica: "agenti" }),
      t("Sconto", "Sconto", 90),
      t("Provvigione", "Provvigione", 90),
      n("ScGiornoFisso1", "Giorno fisso 1", 0, 40),
      n("ScGiornoFisso2", "Giorno fisso 2", 0, 40),
      n("ScGiornoFisso3", "Giorno fisso 3", 0, 40),
      t("Ricarica", "Ricarica", 90),
      s("SpeseIncasso", "Spese di incasso"),
      s("SpeseBolli", "Spese bolli"),
    ],
  },
  {
    id: "banca",
    titolo: "Banca",
    campi: [
      t("Iban", "IBAN", 260),
      t("BicCode", "BIC", 100),
      t("Cd_CGConto_Banca", "Banca di sconto", 110),
      t("Cd_Abicab", "ABI/CAB", 100),
      t("ContoCorrente", "Conto corrente", 140),
      t("SDD_IdMandato", "Mandato SDD", 160),
      d("SDD_DtMandato", "Data mandato"),
    ],
  },
  {
    id: "ddt",
    titolo: "DDT",
    nota: "Le destinazioni diverse sono sotto, nell'elenco.",
    campi: [
      t("Cd_DOVettore", "Vettore", 70),
      t("Cd_DOPorto", "Porto", 50),
      t("Cd_DOSped", "Spedizione", 50),
      t("Cd_CGConto_Merce", "Conto merce", 110),
    ],
  },
  {
    id: "intra",
    titolo: "Intra",
    campi: [
      t("Cd_INTRAConsegna", "Consegna", 40),
      t("Cd_INTRATrasporto", "Trasporto", 40),
      t("Cd_INTRATransazione", "Transazione", 40),
      t("Cd_Nazione_Origine", "Nazione origine", 40),
      t("Cd_Provincia_Origine", "Prov. origine", 40),
      t("Cd_Nazione_Destinazione", "Nazione destinazione", 40),
      t("Cd_Provincia_Destinazione", "Prov. destinazione", 40),
      t("Cd_Nazione_Provenienza", "Nazione provenienza", 40),
    ],
  },
  {
    id: "export",
    titolo: "Export",
    nota: "Personalizzazione Bottamedi: il codice del cliente negli export Conad, Gastropool e Hogast (scheda Export di Arca).",
    campi: [t("xCd_Exp", "Codice export", 200)],
  },
  {
    id: "fatturazione",
    titolo: "Fatturazione differita",
    campi: [
      s("PdAbilita", "Fatturazione differita"),
      n("PdPriorita", "Priorità", 0, 40),
      t("Cd_CF_Fatt", "Cliente di fatturazione", 80),
      s("PdInt4ClienteFatturazione", "Intestata al cliente di fatturazione"),
      s("PdBrk4DocumentoPrelevato", "Una fattura per documento"),
      s("PdBrk4ClienteFornitore", "Una per cliente"),
      s("PdBrk4Pagamento", "Una per pagamento"),
      s("PdBrk4Agente_1", "Una per agente 1"),
      s("PdBrk4Agente_2", "Una per agente 2"),
      s("PdBrk4Zona", "Una per zona"),
      s("PdBrk4SedeAmministrativa", "Una per sede amministrativa"),
      s("PdBrk4DestinazioneDiversa", "Una per destinazione"),
    ],
  },
  {
    id: "altro",
    titolo: "Altro",
    campi: [
      t("Cd_CGConto_Mastro", "Conto mastro", 110),
      t("Cd_VL", "Valuta", 50),
      t("TipoCF", "Tipo", 40),
      t("TipoCF_1", "Tipo (stato)", 40),
      t("Cd_CFStato", "Stato", 50),
      t("Fido", "Fido", 90, { tipo: "numero", decimali: 2 }),
      t("Cd_CFZona", "Zona", 60),
      t("Cd_CFSettore", "Settore", 60),
      t("Cd_SL", "Sollecito", 60),
      t("Id_Lingua", "Lingua", 50, { scelte: { "1040": "italiano" } }),
      t("Cd_CFClasse1", "Classe 1", 60),
      t("Cd_CFClasse2", "Classe 2", 60),
      t("Cd_CFClasse3", "Classe 3", 60),
      t("Cd_CFGruppo1", "Famiglia", 60),
      t("Cd_CFGruppo2", "Gruppo", 60),
      t("Cd_CFGruppo3", "Sottogruppo", 60),
      t("NRea", "REA", 100),
      t("Cd_AE_Atecofin", "ATECO", 80),
      t("Cd_AE_NaturaGiuridica", "Natura giuridica", 50),
      t("Cd_F24Comune", "Comune (F24)", 60),
      t("Cd_ParcT", "Parcellazione", 90),
      t("Cd_CF_BPoint", "Cliente BPoint", 80),
      s("Ue", "UE"),
      s("Intra", "Intra"),
      s("Ritenuta", "Ritenuta"),
      s("Elenchi", "Elenchi"),
      s("ConsumatoreFinale", "Consumatore finale"),
      s("Condominio", "Condominio"),
      s("ProceduraConcorsuale", "Procedura concorsuale"),
      s("EsclusoSpesometro", "Escluso spesometro"),
      s("EsclusoBlackList", "Escluso black list"),
      s("EsclusoOver3000", "Escluso oltre 3000"),
      s("DF_Escluso", "Escluso dai dati fattura"),
      s("ProspectCliente", "Potenziale cliente"),
      s("ProspectFornitore", "Potenziale fornitore"),
      { colonna: "Attributi", etichetta: "Attributi (XML di Arca)", tipo: "nota" },
      { colonna: "ExtraInfo", etichetta: "Informazioni aggiuntive (XML di Arca)", tipo: "nota" },
    ],
  },
  { id: "documenti", titolo: "Documenti", nota: "Gli ultimi DDT del cliente, dal più recente.", campi: [] },
  { id: "note", titolo: "Note", campi: [{ colonna: "Note_CF", etichetta: "Note", tipo: "nota" }] },
  {
    id: "registrazione",
    titolo: "Inserito / modificato",
    campi: [t("UserIns", "Inserito da", 60), d("TimeIns", "il"), t("UserUpd", "Modificato da", 60), d("TimeUpd", "il")],
  },
];

/**
 * Il cliente nuovo come lo propone Arca, dai dati ufficiali della partita IVA: codice successivo,
 * euro, conto mastro dei clienti, escluso black list, ASW in fattura, italiano (1040), persona
 * giuridica. Il backend completa gli altri campi obbligatori di `CF` (`atlas-sync/src/clienti.rs`).
 */
export function nuovoCliente(codice: string, vies: DatiAzienda | null, partitaIva = ""): Record_ {
  return {
    Cd_CF: codice,
    Descrizione: vies?.ragione_sociale ?? "",
    TipoDitta: "G",
    PartitaIva: vies?.partita_iva ?? partitaIva,
    Cd_NazioneIva: vies?.nazione ?? "IT",
    Indirizzo: vies?.indirizzo ?? "",
    Cap: vies?.cap ?? "",
    Localita: vies?.localita ?? "",
    Cd_Provincia: vies?.provincia ?? "",
    Cd_Nazione: vies?.nazione ?? "IT",
    Cd_VL: "EUR",
    Cd_CGConto_Mastro: "04010101001",
    EsclusoBlackList: true,
    FE_AddASW: true,
    Id_Lingua: 1040,
    TipoCF: "C",
    Obsoleto: false,
  };
}

// ---------------------------------------------------------------- Articoli

const ARTICOLO_ARCA: [keyof ArticoloScheda, string][] = [
  ["codice", "Cd_AR"],
  ["descrizione", "Descrizione"],
  ["descrizione_breve", "DescrizioneBreve"],
  ["unita_misura", "Cd_ARMisura"],
  ["aliquota", "Cd_Aliquota_V"],
  ["conto_ricavo", "Cd_CGConto_VI"],
  ["obsoleto", "Obsoleto"],
];

export function recordArticolo(a: ArticoloScheda): Record_ {
  const r: Record_ = { ...(a.extra ?? {}) };
  for (const [campo, colonna] of ARTICOLO_ARCA) r[colonna] = a[campo] as Valore;
  return r;
}

export const SEZIONI_ARTICOLO: SezioneScheda[] = [
  {
    id: "generale",
    titolo: "Generale",
    nota: "Unità di misura e fattori sono nella tabella sotto.",
    campi: [
      t("Cd_AR", "Codice", 110),
      t("Descrizione", "Descrizione", 420),
      t("DescrizioneBreve", "Descrizione breve", 220),
      t("VBDescrizione", "Descrizione al banco", 220),
      t("WebDescrizione", "Descrizione web", 220),
      t("Cd_ARMisura", "UM", 40, { decodifica: "unita_misura" }),
      t("Cd_ARStato", "Stato", 50),
      t("Cd_ARMarca", "Marca", 70),
      t("Modello", "Modello", 140),
      t("xCd_ARLottoP", "Lotto predefinito", 120, { suggerimento: "Personalizzazione Bottamedi (scheda Altro di Arca)" }),
      t("Cd_ARGruppo1", "Famiglia", 60),
      t("Cd_ARGruppo2", "Gruppo", 60),
      t("Cd_ARGruppo3", "Sottogruppo", 60),
      t("Cd_ARClasse1", "Categoria", 60),
      t("Cd_ARClasse2", "Classe", 60),
      t("Cd_ARClasse3", "Sottoclasse", 60),
      t("Cd_VbReparto", "Reparto (banco)", 50),
      t("Cd_Nazione_Origine", "Nazione di origine", 40),
      t("Cd_Provincia_Origine", "Provincia di origine", 40),
      t("Cd_ARNomenclatura", "Nomenclatura (Intra)", 100),
      t("IntraTipo", "Tipo Intra", 40),
      t("Cd_IntraServizio", "Servizio Intra", 70),
      n("Id_ARCategoria", "Categoria (id)", 0, 60),
      s("Fittizio", "Fittizio"),
      s("Obsoleto", "Obsoleto"),
    ],
  },
  {
    id: "iva",
    titolo: "IVA e conti",
    nota: "L'IVA vendite è obbligatoria, come in Arca (preferenza xARIvaObb).",
    campi: [
      t("Cd_Aliquota_V", "IVA vendite", 50, { decodifica: "aliquote" }),
      t("Cd_Aliquota_A", "IVA acquisti", 50, { decodifica: "aliquote" }),
      t("Cd_CGConto_VI", "Ricavo Italia", 110),
      t("Cd_CGConto_VE", "Ricavo estero", 110),
      t("Cd_CGConto_AI", "Costo Italia", 110),
      t("Cd_CGConto_AE", "Costo estero", 110),
      t("Cd_CAVda_VI", "Analitica ricavo Italia", 110),
      t("Cd_CAVda_VE", "Analitica ricavo estero", 110),
      t("Cd_CAVda_AI", "Analitica costo Italia", 110),
      t("Cd_CAVda_AE", "Analitica costo estero", 110),
    ],
  },
  {
    id: "fe",
    titolo: "Fattura elettronica",
    nota: "Il codice dell'articolo nell'XML della fattura (CodiceArticolo).",
    campi: [t("FTE_CodiceTipo", "Tipo codice", 160), t("FTE_CodiceValore", "Valore codice", 200)],
  },
  {
    id: "prezzi",
    titolo: "Prezzi",
    nota: "Il prezzo valido oggi in ogni listino è nella tabella sotto.",
    campi: [
      t("Sconto", "Sconto", 90),
      t("Provvigione", "Provvigione", 90),
      t("Ricarica", "Ricarica", 90),
      n("xCosto", "Costo", 3, 90),
      n("xRicarico", "Ricarico", 2, 70),
      n("CostoStandard", "Costo standard", 3, 90),
    ],
  },
  {
    id: "magazzino",
    titolo: "Magazzino",
    campi: [
      n("ScortaMinima", "Scorta minima", 2, 80),
      n("ScortaMassima", "Scorta massima", 2, 80),
      n("LottoMinimo", "Lotto minimo", 2, 80),
      n("LottoRiordino", "Lotto riordino", 2, 80),
      t("ClasseAbc", "Classe ABC", 40),
      n("TipoValorizzazione", "Valorizzazione", 0, 40),
      s("MG_LottoObbligatorio", "Lotto obbligatorio"),
      s("MG_MatricolaObbligatoria", "Matricola obbligatoria"),
      s("MG_GiacenzaNonNegativa", "Giacenza non negativa"),
      s("NoInventario", "Escluso dall'inventario"),
      s("NoGiornale", "Escluso dal giornale"),
      n("PesoLordo", "Peso lordo", 3, 80),
      n("PesoNetto", "Peso netto", 3, 80),
      n("Altezza", "Altezza", 2, 70),
      n("Lunghezza", "Lunghezza", 2, 70),
      n("Larghezza", "Larghezza", 2, 70),
      n("PesoFattore", "Fattore peso", 5, 80),
      n("DimensioniFattore", "Fattore dimensioni", 5, 80),
    ],
  },
  {
    id: "produzione",
    titolo: "Produzione",
    nota: "Distinta base e riordino (MRP) di Arca.",
    campi: [
      t("Cd_ARPrdClasse", "Classe produzione", 60),
      n("TipoGestComm", "Gestione commessa", 0, 40),
      n("MrpGiorniRiordino", "Giorni riordino", 0, 50),
      n("MrpGiorniCopertura", "Giorni copertura", 0, 50),
      n("MrpResa", "Resa", 0, 50),
      n("MrpPuntoRiordino", "Punto riordino", 0, 40),
      n("MrpProduzioneMassima", "Produzione massima", 2, 90),
      s("DBKit", "Kit"),
      s("DBFantasma", "Fantasma"),
      s("MrpIncludi", "Nel calcolo MRP"),
      s("MrpLottoRiordino", "Lotto di riordino"),
      s("MrpLottoMinimo", "Lotto minimo"),
      s("MrpIgnoraDistinta", "Ignora la distinta"),
      s("MrpAggiornaCostoDistinta", "Aggiorna il costo dalla distinta"),
      s("MrpForzaExpDistinta", "Forza l'esplosione della distinta"),
      s("MRPConsideraDaAcquistare", "Considera da acquistare"),
    ],
  },
  {
    id: "ebusiness",
    titolo: "eBusiness",
    campi: [
      t("WebInfoLink", "Collegamento", 320),
      n("WebGiacenza", "Giacenza web", 2, 80),
      s("WebB2CPubblica", "Pubblicato B2C"),
      s("WebB2BPubblica", "Pubblicato B2B"),
      { colonna: "WebNote_AR", etichetta: "Note web", tipo: "nota" },
    ],
  },
  {
    id: "note",
    titolo: "Note",
    campi: [
      { colonna: "Note_AR", etichetta: "Note", tipo: "nota" },
      { colonna: "NoteOfferta", etichetta: "Note per le offerte", tipo: "nota" },
    ],
  },
  {
    id: "altro",
    titolo: "Altro",
    campi: [
      s("AmsManaged", "Gestito da AMS"),
      { colonna: "Attributi", etichetta: "Attributi (XML di Arca)", tipo: "nota" },
      { colonna: "ExtraInfo", etichetta: "Informazioni aggiuntive (XML di Arca)", tipo: "nota" },
    ],
  },
  {
    id: "registrazione",
    titolo: "Inserito / modificato",
    campi: [t("UserIns", "Inserito da", 60), d("TimeIns", "il"), t("UserUpd", "Modificato da", 60), d("TimeUpd", "il")],
  },
];

// ---------------------------------------------------------------- Valori

/** Il valore come si legge nel campo: numeri con i decimali di Arca, date GG-MM-AAAA. */
export function testoCampo(campo: CampoScheda, v: Valore | undefined): string {
  if (v === null || v === undefined) return "";
  if (campo.tipo === "data") return typeof v === "string" ? fData(v) + (v.length > 10 && !v.endsWith("00:00:00") ? ` ${v.slice(11, 16)}` : "") : String(v);
  if (campo.tipo === "numero" && campo.decimali) return mostra(String(v), campo.decimali);
  return typeof v === "boolean" ? (v ? "Sì" : "No") : String(v).trimEnd();
}

/** La descrizione accanto al codice: dalla tabella di codifica o dalle scelte fisse. */
export function descrizioneCampo(campo: CampoScheda, v: Valore | undefined, tabelle: Tabelle | null): string | undefined {
  if (v === null || v === undefined || v === "") return undefined;
  const codice = String(v).trim();
  if (campo.scelte) return campo.scelte[codice];
  if (!campo.decodifica || !tabelle) return undefined;
  return tabelle[campo.decodifica].find((c) => c.codice.trim() === codice)?.descrizione;
}

/** Tutte le colonne delle sezioni, per il controllo "nessun campo manca". */
export const colonne = (sezioni: SezioneScheda[]) => sezioni.flatMap((s) => s.campi.map((c) => c.colonna));
