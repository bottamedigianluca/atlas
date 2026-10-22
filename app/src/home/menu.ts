// Il menu "Cosa vuoi fare?" della Home: la forma di quello di Arca (`docs/screenshot_arca/07_…`),
// ma solo con le voci che a Bottamedi servono, secondo l'uso vero di Arca (`docs/ANALISI_ARCA.md`).
// Tolte: Servizio, Beni Usati, Contabilità (la prima nota si fa fuori da Arca), Magazzini (giacenza
// non significativa), Vendite al Banco (38 scontrini in tutto), potenziali clienti e fornitori,
// commesse e tabelle vuote. Aggiunte quelle di ATLAS: partita IVA online, sincronizzazione con Arca,
// fatturazione differita. Le voci che ATLAS non ha ancora restano visibili e spente, con il task che
// le porta o "in Arca" (fino ad allora si fanno lì).

/** Comandi che ATLAS sa eseguire dalla Home. */
export type Comando = "elenco" | "nuovo" | "partitaIva" | "sincronizzazione" | "clienti" | "articoli";

export interface Voce {
  nome: string;
  comando?: Comando;
  /** Senza comando: dove si fa per ora ("in Arca") o il task che la porta ("Task 7"). */
  nota?: string;
}

export interface Gruppo {
  nome: string;
  voci: Voce[];
}

const ARCA = "in Arca";

export const MENU: Gruppo[] = [
  {
    nome: "Documenti",
    voci: [
      { nome: "Gestione", comando: "elenco" },
      { nome: "Nuovo Documento", comando: "nuovo" },
      { nome: "Fatturazione differita", nota: "Task 7" },
      { nome: "Ristampa Documenti", nota: "Task 7" },
      { nome: "Fatture elettroniche (SdI)", nota: "Task 7" },
      { nome: "Eliminazione", nota: "Task 6" },
    ],
  },
  {
    nome: "Anagrafiche",
    voci: [
      { nome: "Partita IVA online", comando: "partitaIva" },
      { nome: "Clienti", comando: "clienti" },
      { nome: "Fornitori", nota: ARCA },
      { nome: "Agenti", nota: ARCA },
    ],
  },
  { nome: "Articoli", voci: [{ nome: "Gestione Articoli", comando: "articoli" }] },
  { nome: "Listini", voci: [{ nome: "Gestione Listini", nota: ARCA }] },
  {
    nome: "Scadenzario",
    voci: [
      { nome: "Scadenze", nota: ARCA },
      { nome: "Registra Pagato", nota: ARCA },
      { nome: "Portafoglio Effetti (RiBa)", nota: ARCA },
      { nome: "Distinte Effetti", nota: ARCA },
    ],
  },
  { nome: "DMS", voci: [{ nome: "PDF e XML dei documenti", nota: "Task 7" }] },
  { nome: "Sincronizzazione Arca", voci: [{ nome: "Stato, coda e conflitti", comando: "sincronizzazione" }] },
];

/** I comandi che si possono eseguire, con il percorso: per "Cerca comando" e i Favoriti. */
export const COMANDI: { percorso: string; voce: Voce & { comando: Comando } }[] = MENU.flatMap((g) =>
  g.voci.flatMap((v) => (v.comando ? [{ percorso: `${g.nome} › ${v.nome}`, voce: { ...v, comando: v.comando } }] : [])),
);
