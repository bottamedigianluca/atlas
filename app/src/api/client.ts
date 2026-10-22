// Client del backend ATLAS: REST per le richieste, WebSocket per le notifiche.

import type {
  ArticoloBreve,
  Bozza,
  Calcolo,
  CampiNota,
  ClienteBreve,
  ClienteScheda,
  ClientiDelGiorno,
  CorpoErrore,
  DdtBreve,
  DdtCreato,
  DdtScheda,
  Nota,
  Notifica,
  NumeriLiberi,
  Prezzi,
  Rinumerato,
  Stato,
} from "./tipi";

const CHIAVE_SERVER = "atlas.server";
export const SERVER_PREDEFINITO = "http://127.0.0.1:7878";

/** Indirizzo del backend: impostazione della postazione, poi variabile di build, poi locale. */
export function indirizzoServer(): string {
  try {
    const salvato = localStorage.getItem(CHIAVE_SERVER);
    if (salvato) return salvato.replace(/\/+$/, "");
  } catch {
    // archivio locale non disponibile: si usa il predefinito
  }
  const daBuild = import.meta.env.VITE_ATLAS_SERVER as string | undefined;
  return (daBuild || SERVER_PREDEFINITO).replace(/\/+$/, "");
}

export function impostaServer(indirizzo: string): void {
  try {
    if (indirizzo.trim()) localStorage.setItem(CHIAVE_SERVER, indirizzo.trim());
    else localStorage.removeItem(CHIAVE_SERVER);
  } catch {
    // ignorato: resta l'indirizzo predefinito
  }
}

/** Errore restituito dal backend, con il suo codice stabile. */
export class ErroreApi extends Error {
  constructor(
    readonly stato: number,
    readonly corpo: CorpoErrore,
  ) {
    super(corpo.messaggio);
    this.name = "ErroreApi";
  }

  get dettagli(): string[] {
    return this.corpo.dettagli ?? [];
  }
}

type Parametri = Record<string, string | number | boolean | null | undefined>;

function query(parametri?: Parametri): string {
  if (!parametri) return "";
  const q = new URLSearchParams();
  for (const [chiave, valore] of Object.entries(parametri)) {
    if (valore !== undefined && valore !== null && valore !== "") q.set(chiave, String(valore));
  }
  const testo = q.toString();
  return testo ? `?${testo}` : "";
}

async function chiama<T>(metodo: "GET" | "POST" | "PUT" | "DELETE", percorso: string, corpo?: unknown, segnale?: AbortSignal): Promise<T> {
  let risposta: Response;
  try {
    risposta = await fetch(`${indirizzoServer()}/api${percorso}`, {
      method: metodo,
      headers: corpo === undefined ? undefined : { "content-type": "application/json" },
      body: corpo === undefined ? undefined : JSON.stringify(corpo),
      signal: segnale,
    });
  } catch (e) {
    if (e instanceof DOMException && e.name === "AbortError") throw e;
    throw new ErroreApi(0, { codice: "rete", messaggio: `server ATLAS non raggiungibile (${indirizzoServer()})` });
  }
  const testo = await risposta.text();
  const valore: unknown = testo ? JSON.parse(testo) : null;
  if (!risposta.ok) {
    const corpo = (valore as CorpoErrore | null) ?? { codice: "http", messaggio: `HTTP ${risposta.status}` };
    throw new ErroreApi(risposta.status, corpo);
  }
  return valore as T;
}

export const api = {
  stato: () => chiama<Stato>("GET", "/stato"),
  sincronizza: () => chiama<null>("POST", "/sincronizza"),
  calcola: (bozza: Bozza, segnale?: AbortSignal) => chiama<Calcolo>("POST", "/ddt/calcola", bozza, segnale),
  crea: (bozza: Bozza) => chiama<DdtCreato>("POST", "/ddt", bozza),
  rinumera: (id: number) => chiama<Rinumerato>("POST", `/ddt/${id}/rinumera`),
  liberi: (esercizio: number) => chiama<NumeriLiberi>("GET", `/numerazione/${esercizio}/liberi`),
  elencoDdt: (filtro: { dal?: string; al?: string; cliente?: string; numero?: number; limite?: number }) =>
    chiama<DdtBreve[]>("GET", `/ddt${query(filtro)}`),
  ddt: (id: number) => chiama<DdtScheda>("GET", `/ddt/${id}`),
  clienti: (cerca: string, segnale?: AbortSignal) =>
    chiama<ClienteBreve[]>("GET", `/clienti${query({ cerca, limite: 50 })}`, undefined, segnale),
  cliente: (codice: string) => chiama<ClienteScheda>("GET", `/clienti/${encodeURIComponent(codice)}`),
  articoli: (cerca: string, segnale?: AbortSignal) =>
    chiama<ArticoloBreve[]>("GET", `/articoli${query({ cerca, limite: 50 })}`, undefined, segnale),
  prezzi: (richiesta: {
    articolo: string;
    cliente?: string;
    data?: string;
    unita_misura?: string;
    quantita?: string;
  }) => chiama<Prezzi>("GET", `/prezzi${query(richiesta)}`),
  clientiDelGiorno: (data?: string) => chiama<ClientiDelGiorno>("GET", `/home/clienti${query({ data })}`),
  note: () => chiama<Nota[]>("GET", "/note"),
  creaNota: (campi: CampiNota) => chiama<Nota>("POST", "/note", campi),
  aggiornaNota: (id: number, campi: CampiNota) => chiama<Nota>("PUT", `/note/${id}`, campi),
  eliminaNota: (id: number) => chiama<null>("DELETE", `/note/${id}`),
};

/**
 * Notifiche del backend sul WebSocket, con riconnessione automatica (il backend può essere
 * riavviato). `collegato` dice se il canale è aperto: è anche lo stato della rete.
 */
export function ascoltaNotifiche(
  suNotifica: (n: Notifica) => void,
  suCollegamento: (collegato: boolean) => void,
): () => void {
  let socket: WebSocket | null = null;
  let chiuso = false;
  let attesa = 500;
  let timer: ReturnType<typeof setTimeout> | undefined;

  const apri = () => {
    if (chiuso) return;
    const url = `${indirizzoServer().replace(/^http/, "ws")}/api/ws`;
    socket = new WebSocket(url);
    socket.onopen = () => {
      attesa = 500;
      suCollegamento(true);
    };
    socket.onmessage = (messaggio) => {
      try {
        const valore = JSON.parse(String(messaggio.data)) as Notifica | { id: unknown };
        if ("evento" in valore) suNotifica(valore);
      } catch {
        // messaggio non JSON: ignorato
      }
    };
    socket.onclose = () => {
      suCollegamento(false);
      if (chiuso) return;
      timer = setTimeout(apri, attesa);
      attesa = Math.min(attesa * 2, 10_000);
    };
  };
  apri();
  return () => {
    chiuso = true;
    clearTimeout(timer);
    socket?.close();
  };
}
