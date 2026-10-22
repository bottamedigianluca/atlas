// Tipi delle API del backend (`crates/atlas-server`). I decimali viaggiano come testo esatto
// ("5.16"): il frontend non fa conti sugli importi, li mostra.

export type Decimale = string;
export type Data = string; // AAAA-MM-GG
export type Istante = string; // AAAA-MM-GGTHH:MM:SS

export interface BozzaRiga {
  articolo: string;
  unita_misura?: string;
  colli?: Decimale;
  lordo?: Decimale;
  tara?: Decimale;
  prezzo?: Decimale;
  sconto?: string;
  sconto_addizionale?: string;
  quantita?: Decimale;
  descrizione?: string;
  magazzino?: string;
}

export interface Bozza {
  cliente: string;
  /** Assente: la destinazione predefinita del cliente; "" nessuna. */
  destinazione?: string;
  data?: Data;
  numero?: number;
  righe: BozzaRiga[];
}

export interface Avviso {
  codice: "tara_maggiore_lordo" | "colli_decimali" | string;
  messaggio: string;
}

export interface RigaCalcolata {
  vuota: boolean;
  articolo: string;
  descrizione: string | null;
  unita_misura: string | null;
  fattore_um1: Decimale | null;
  aliquota: string | null;
  conto_ricavo: string | null;
  magazzino: string | null;
  quantita: Decimale | null;
  prezzo: Decimale | null;
  origine_prezzo: "listino" | "manuale" | null;
  prezzo_listino: Decimale | null;
  prezzo_modificato: boolean;
  totale: Decimale | null;
  avvisi: Avviso[];
  errori: string[];
}

export interface TestataCalcolata {
  cliente: string;
  ragione_sociale: string;
  destinazione: string | null;
  data: Data;
  esercizio: number;
  numero: number | null;
  pagamento: string | null;
  listino: string | null;
  listino_prezzi: string;
  scissione_pagamenti: boolean;
  inizio_trasporto: Istante;
}

export interface RigaIva {
  aliquota: string;
  percentuale: Decimale;
  imponibile: Decimale;
  imposta: Decimale;
}

export interface Castelletto {
  righe: RigaIva[];
  totale_imponibile: Decimale;
  totale_imposta: Decimale;
  totale_documento: Decimale;
}

export interface Calcolo {
  testata: TestataCalcolata | null;
  righe: RigaCalcolata[];
  castelletto: Castelletto;
  netto_a_pagare: Decimale;
  errori: string[];
  salvabile: boolean;
}

export interface DdtCreato {
  id: number;
  evento: number;
  esercizio: number;
  numero: number;
  data: Data;
  cliente: string;
  totale_imponibile: Decimale;
  totale_imposta: Decimale;
  totale_documento: Decimale;
  senza_arca: string | null;
}

export interface Rinumerato {
  id: number;
  esercizio: number;
  prima: number;
  numero: number;
}

export interface Liberi {
  dal: number;
  al: number;
  data_dal: Data | null;
  data_al: Data;
}

export interface NumeriLiberi {
  esercizio: number;
  liberi: Liberi[];
  prossimo: number | null;
  senza_arca: string | null;
}

export interface ClienteBreve {
  codice: string;
  ragione_sociale: string;
  localita: string | null;
  partita_iva: string | null;
  obsoleto: boolean;
}

export interface DestinazioneVista {
  codice: string;
  descrizione: string;
  indirizzo: string | null;
  localita: string | null;
  provincia: string | null;
  predefinita: boolean;
  obsoleto: boolean;
}

export interface ClienteScheda {
  codice: string;
  ragione_sociale: string;
  indirizzo: string | null;
  cap: string | null;
  localita: string | null;
  provincia: string | null;
  partita_iva: string | null;
  codice_fiscale: string | null;
  codice_destinatario: string | null;
  pagamento: string | null;
  descrizione_pagamento: string | null;
  listino: string | null;
  descrizione_listino: string | null;
  agente: string | null;
  descrizione_agente: string | null;
  iban: string | null;
  bic: string | null;
  scissione_pagamenti: boolean;
  obsoleto: boolean;
  destinazioni: DestinazioneVista[];
}

export interface ArticoloBreve {
  codice: string;
  descrizione: string;
  unita_misura: string;
  aliquota: string | null;
  obsoleto: boolean;
}

export type StatoArca = "in_arca" | "in_coda" | "errore" | "solo_atlas";

export interface DdtBreve {
  id: number;
  tipo: string;
  esercizio: number;
  numero: number;
  data: Data;
  cliente: string;
  ragione_sociale: string;
  destinazione: string | null;
  descrizione_destinazione: string | null;
  localita_destinazione: string | null;
  pagamento: string | null;
  listino_cliente: string | null;
  agente: string | null;
  descrizione_agente: string | null;
  righe: number;
  totale_imponibile: Decimale;
  totale_documento: Decimale;
  netto_a_pagare: Decimale;
  arca_id_testata: number | null;
  arca: StatoArca;
}

export interface Pesata {
  colli: Decimale;
  lordo: Decimale;
  tara_per_collo: Decimale;
}

export interface RigaDdt {
  articolo: string;
  descrizione: string;
  unita_misura: string;
  fattore_um1: Decimale;
  conto_ricavo: string;
  aliquota: string;
  id_listino_articolo: number | null;
  pesata: Pesata;
  quantita_forzata: Decimale | null;
  prezzo_unitario: Decimale;
  sconto_riga: string;
  sconto_addizionale: string;
  magazzino: string | null;
}

export interface RigaVista extends RigaDdt {
  quantita: Decimale;
  totale: Decimale;
}

export interface EventoVista {
  id: number;
  operazione: string;
  creato_il: Istante;
  tentativi: number;
  ultimo_errore: string | null;
  prossimo_tentativo_il: Istante | null;
  replicato_il: Istante | null;
}

export interface DdtScheda {
  id: number;
  tipo: string;
  esercizio: number;
  numero: number;
  ragione_sociale: string;
  documento: {
    numero: number;
    data: Data;
    cliente: string;
    destinazione: string | null;
    sede: string | null;
    pagamento: string | null;
    listino_cliente: string | null;
    iban: string | null;
    bic: string | null;
    conto_banca: string | null;
    agente: string | null;
    inizio_trasporto: Istante | null;
    scissione_pagamenti: boolean;
    operatore: string;
    registrato_il: Istante;
  };
  righe: RigaVista[];
  castelletto: Castelletto;
  netto_a_pagare: Decimale;
  arca: StatoArca;
  arca_id_testata: number | null;
  eventi: EventoVista[];
}

export interface VoceListino {
  listino: string;
  descrizione: string;
  descrizione_revisione: string | null;
  proposto: boolean;
  ivato: boolean;
  revisione: number | null;
  valido_dal: Data | null;
  id_listino_articolo: number | null;
  prezzo_listino: Decimale;
  prezzo_documento: Decimale;
  sconto: string | null;
  /** `null`: il listino non ha l'articolo. */
  prezzo_riga: Decimale | null;
}

export interface RiferimentoDocumento {
  id: number;
  tipo: string;
  numero: number;
  data: Data;
  cliente: string;
  ragione_sociale: string;
}

export interface VoceUltimo {
  tipo: "ultimo_cliente" | "ultimo_assoluto" | "massimo_giorno";
  descrizione: string;
  documento: RiferimentoDocumento;
  riga: number;
  unita_misura: string;
  fattore: Decimale;
  quantita: Decimale;
  aliquota: string;
  percentuale_iva: Decimale | null;
  prezzo: Decimale;
  prezzo_ivato: Decimale | null;
  sconto: string;
  prezzo_riga: Decimale;
}

export interface Prezzi {
  documento: {
    articolo: string;
    descrizione: string;
    cliente: string | null;
    ragione_sociale: string | null;
    listino_cliente: string | null;
    data: Data;
    valuta: string;
    unita_misura: string;
    fattore: Decimale;
    quantita: Decimale | null;
    aliquota: string | null;
    percentuale_iva: Decimale | null;
  };
  listini: VoceListino[];
  ultimi: VoceUltimo[];
  ultimo_acquisto: VoceUltimo | null;
}

export interface FermoImportazione {
  arca_id_testata: number;
  errore: string;
  esercizio: number | null;
  numero: number | null;
}

export interface StatoSync {
  replica: {
    configurata: boolean;
    ultimo_giro: Istante | null;
    scritti: number;
    gia_presenti: number;
    errore: string | null;
  };
  importazione: {
    configurata: boolean;
    ultimo_giro: Istante | null;
    nuovi: number;
    aggiornati: number;
    collegati: number;
    esclusi: number;
    cancellati: number;
    fermo: FermoImportazione | null;
    errore: string | null;
  };
}

export interface Conflitto {
  origine: "replica" | "importazione";
  ddt: number;
  esercizio: number;
  numero: number;
  errore: string;
  azioni: string[];
}

export interface Stato {
  versione: string;
  schema: number;
  sincronizzazione: StatoSync;
  coda: {
    in_coda: number;
    fermo: {
      evento: number;
      ddt: number;
      numero: number | null;
      esercizio: number | null;
      tentativi: number;
      ultimo_errore: string;
      prossimo_tentativo_il: Istante | null;
    } | null;
  };
  conflitti: Conflitto[];
}

export interface CorpoErrore {
  codice: string;
  messaggio: string;
  dettagli?: string[];
}

/** Notifiche del WebSocket. */
export type Notifica =
  | { evento: "stato"; dati: StatoSync }
  | { evento: "ddt_creato"; dati: DdtCreato }
  | { evento: "ddt_rinumerato"; dati: Rinumerato }
  | { evento: "replica"; dati: { scritti: number; gia_presenti: number; fallito: [number, string] | null } }
  | {
      evento: "importazione";
      dati: { nuovi: number; aggiornati: number; collegati: number; esclusi: number; cancellati: number };
    }
  | { evento: "note_cambiate" }
  | { evento: "ritardo"; dati: { perse: number } };

/** Riga del post-it della Home, condivisa fra le postazioni; si barra quando è fatta. */
export interface Nota {
  id: number;
  testo: string;
  fatta: boolean;
  autore: string;
  creata_il: Istante;
  aggiornata_il: Istante;
}

export interface CampiNota {
  testo?: string;
  fatta?: boolean;
}

/** Dati ufficiali dell'azienda dalla partita IVA (servizio VIES), nei campi dell'anagrafica. */
export interface DatiAzienda {
  nazione: string;
  partita_iva: string;
  attiva: boolean;
  ragione_sociale: string | null;
  indirizzo: string | null;
  cap: string | null;
  localita: string | null;
  provincia: string | null;
  indirizzo_vies: string | null;
  gia_presente: string | null;
}

export interface PerArea {
  totale: number;
  italia: number;
  ue: number;
  extra_ue: number;
}

export interface Riepilogo {
  bolle: number;
  clienti: PerArea;
  fornitori: PerArea;
}

export interface ClienteDelGiorno {
  cliente: string;
  ragione_sociale: string;
  localita: string | null;
  volte: number;
  su: number;
  ultimo: Data;
  /** "09:10": ora mediana di registrazione dei suoi DDT in quel giorno della settimana. */
  ora_tipica: string | null;
  destinazione: string | null;
  servito: { id: number; numero: number } | null;
}

export interface ClientiDelGiorno {
  data: Data;
  giorno: string;
  settimane: number;
  giorni_lavorati: number;
  clienti: ClienteDelGiorno[];
}
