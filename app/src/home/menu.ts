// Il menu "Cosa vuoi fare?" della Home di Arca, voce per voce come nelle schermate
// (`docs/screenshot_arca/07_…`, 13-16). In ATLAS si aprono i comandi che ci sono già; gli altri
// restano al loro posto, spenti, finché non arrivano i moduli (fino ad allora si usano in Arca).

/** Comandi che ATLAS sa eseguire dalla Home. */
export type Comando = "elenco" | "nuovo";

export interface Voce {
  nome: string;
  comando?: Comando;
  /** Ha un altro livello (la freccia ›). */
  sottomenu?: boolean;
}

export interface Gruppo {
  nome: string;
  voci: Voce[];
}

export const MENU: Gruppo[] = [
  { nome: "DMS", voci: [] },
  {
    nome: "Anagrafiche",
    voci: [
      { nome: "Clienti", sottomenu: true },
      { nome: "Fornitori", sottomenu: true },
      { nome: "Potenziali Clienti", sottomenu: true },
      { nome: "Potenziali Fornitori", sottomenu: true },
      { nome: "Operatori", sottomenu: true },
      { nome: "Tabelle", sottomenu: true },
      { nome: "AADAI" },
    ],
  },
  {
    nome: "Contabilità",
    voci: [
      { nome: "Ricevi Fatture Elettroniche" },
      { nome: "Piano dei Conti", sottomenu: true },
      { nome: "Tabelle", sottomenu: true },
      { nome: "Banche", sottomenu: true },
      { nome: "Collegamento B.Point", sottomenu: true },
    ],
  },
  {
    nome: "Scadenzario",
    voci: [
      { nome: "Portafoglio Effetti", sottomenu: true },
      { nome: "Distinte Effetti", sottomenu: true },
      { nome: "Scadenze" },
      { nome: "Stampa" },
      { nome: "Registra Pagato" },
      { nome: "Vista Accorpamenti" },
      { nome: "Gestione" },
      { nome: "Note" },
    ],
  },
  {
    nome: "Agenti",
    voci: [
      { nome: "Agenti" },
      { nome: "Controllo/Selezione" },
      { nome: "Elenco Provvigioni" },
      { nome: "Stampe" },
      { nome: "Liquidazione" },
      { nome: "Note" },
      { nome: "Attributi" },
      { nome: "Manutenz. Attributi" },
    ],
  },
  { nome: "Beni Usati", voci: [] },
  {
    nome: "Documenti",
    voci: [
      { nome: "Gestione", comando: "elenco" },
      { nome: "Ricevi Fatture Elettroniche" },
      { nome: "Situazione Articolo" },
      { nome: "Nuovo Documento", comando: "nuovo" },
      { nome: "Evasione" },
      { nome: "Ristampa Documenti" },
      { nome: "Stampe di Controllo" },
      { nome: "Imposta Stato" },
      { nome: "Controllo/Selezione" },
      { nome: "Interrogazione" },
      { nome: "Eliminazione" },
      { nome: "Documenti Elettronici", sottomenu: true },
      { nome: "Configurazione" },
      { nome: "Moduli di Stampa" },
      { nome: "Commesse", sottomenu: true },
      { nome: "Tabelle", sottomenu: true },
      { nome: "Tutorial" },
    ],
  },
  { nome: "Vendite al Banco", voci: [] },
  { nome: "Articoli", voci: [] },
  { nome: "Listini", voci: [] },
  { nome: "Magazzini", voci: [] },
  { nome: "Servizio", voci: [] },
];

/** I comandi che si possono eseguire, con il percorso: per "Cerca comando" e i Favoriti. */
export const COMANDI: { percorso: string; voce: Voce & { comando: Comando } }[] = MENU.flatMap((g) =>
  g.voci.flatMap((v) => (v.comando ? [{ percorso: `${g.nome} › ${v.nome}`, voce: { ...v, comando: v.comando } }] : [])),
);
