// Righe della maschera DDT e regole di tastiera, come funzioni pure.
//
// Regole (direttiva §3.3 e §3.5):
// - `Invio` segue la sequenza Articolo → UM → Colli → Lordo → Tara → Prezzo → nuova riga, sulle
//   sole colonne visibili; dalle altre colonne passa alla successiva a destra.
// - `Freccia Giù` scende sulla stessa colonna della riga sotto; se la riga sotto non c'è la crea e
//   si posiziona sull'articolo. Non apre mai tendine. Da una riga vuota in fondo non fa nulla:
//   le righe vuote non si accumulano.
// - Uscendo da Colli con i decimali, o da Tara con tara × colli ≥ lordo, il cursore resta e
//   compare l'avviso: `Invio` conferma (e prosegue), `Esc` torna a correggere. Nessun popup.
// - `Esc` annulla la modifica della cella; su una riga vuota la toglie.

import type { BozzaRiga } from "../api/tipi";
import { type CampoRiga, SEQUENZA_INVIO } from "../griglia/colonne";
import { decimale, valore } from "../griglia/numeri";

export interface RigaUI {
  chiave: number;
  articolo: string;
  descrizione: string;
  unita_misura: string;
  colli: string;
  lordo: string;
  tara: string;
  quantita: string;
  prezzo: string;
  sconto: string;
  magazzino: string;
  /** Avvisi già confermati dall'operatore, con i valori a cui si riferiscono. */
  confermati: string[];
}

export interface Cursore {
  riga: number;
  campo: CampoRiga;
}

export interface AvvisoRiga {
  riga: number;
  codice: "colli_decimali" | "tara_maggiore_lordo";
  messaggio: string;
  /** Dove andava il cursore: ci va se l'operatore conferma. */
  dopo: Cursore;
}

export interface StatoRighe {
  righe: RigaUI[];
  cursore: Cursore;
  avviso: AvvisoRiga | null;
  /** Valore della cella all'arrivo del cursore, per `Esc`. */
  originale: string;
  prossimaChiave: number;
}

const CAMPI: readonly CampoRiga[] = [
  "articolo",
  "descrizione",
  "unita_misura",
  "colli",
  "lordo",
  "tara",
  "quantita",
  "prezzo",
  "sconto",
  "magazzino",
];

export function rigaVuota(chiave: number): RigaUI {
  return {
    chiave,
    articolo: "",
    descrizione: "",
    unita_misura: "",
    colli: "",
    lordo: "",
    tara: "",
    quantita: "",
    prezzo: "",
    sconto: "",
    magazzino: "",
    confermati: [],
  };
}

export function iniziale(): StatoRighe {
  return { righe: [rigaVuota(1)], cursore: { riga: 0, campo: "articolo" }, avviso: null, originale: "", prossimaChiave: 2 };
}

export function vuota(riga: RigaUI): boolean {
  return CAMPI.every((c) => riga[c].trim() === "");
}

function cella(stato: StatoRighe, c: Cursore): string {
  return stato.righe[c.riga]?.[c.campo] ?? "";
}

function posiziona(stato: StatoRighe, cursore: Cursore): StatoRighe {
  return { ...stato, cursore, avviso: null, originale: cella(stato, cursore) };
}

function chiaveConferma(riga: RigaUI, codice: AvvisoRiga["codice"]): string {
  return `${codice}:${riga.colli}|${riga.lordo}|${riga.tara}`;
}

/** L'avviso che l'operatore deve vedere lasciando il campo, se non lo ha già confermato. */
export function controllo(riga: RigaUI, campo: CampoRiga): Omit<AvvisoRiga, "riga" | "dopo"> | null {
  const colli = valore(riga.colli);
  if (campo === "colli" && !Number.isInteger(colli)) {
    const avviso = { codice: "colli_decimali" as const, messaggio: `Colli con i decimali (${riga.colli}): è un peso?` };
    return riga.confermati.includes(chiaveConferma(riga, avviso.codice)) ? null : avviso;
  }
  if (campo === "tara") {
    const lordo = valore(riga.lordo);
    const tara = valore(riga.tara);
    if (lordo > 0 && tara > 0 && colli > 0 && colli * tara >= lordo) {
      const avviso = {
        codice: "tara_maggiore_lordo" as const,
        messaggio: `Tara ${riga.tara} × ${riga.colli} colli ≥ lordo ${riga.lordo}`,
      };
      return riga.confermati.includes(chiaveConferma(riga, avviso.codice)) ? null : avviso;
    }
  }
  return null;
}

/** Porta il cursore a `dove`, fermandosi sull'avviso del campo che lascia. */
function muovi(stato: StatoRighe, dove: Cursore): StatoRighe {
  const { cursore } = stato;
  const lascia = dove.riga !== cursore.riga || dove.campo !== cursore.campo;
  const riga = stato.righe[cursore.riga];
  if (lascia && riga) {
    const avviso = controllo(riga, cursore.campo);
    if (avviso) return { ...stato, avviso: { ...avviso, riga: cursore.riga, dopo: dove } };
  }
  return posiziona(stato, dove);
}

function conNuovaRiga(stato: StatoRighe): StatoRighe {
  return { ...stato, righe: [...stato.righe, rigaVuota(stato.prossimaChiave)], prossimaChiave: stato.prossimaChiave + 1 };
}

/** La riga sotto, o una nuova riga sull'articolo; nulla da una riga vuota in fondo. */
function rigaSotto(stato: StatoRighe, campo: CampoRiga): StatoRighe {
  const { riga } = stato.cursore;
  if (riga + 1 < stato.righe.length) return muovi(stato, { riga: riga + 1, campo });
  const attuale = stato.righe[riga];
  if (!attuale || vuota(attuale)) return stato;
  const dopo = { riga: riga + 1, campo: "articolo" as const };
  const avviso = controllo(attuale, stato.cursore.campo);
  if (avviso) return { ...stato, avviso: { ...avviso, riga, dopo } };
  return posiziona(conNuovaRiga(stato), dopo);
}

export type Azione =
  | { tipo: "scrivi"; riga: number; campo: CampoRiga; valore: string }
  | { tipo: "vai"; cursore: Cursore }
  | { tipo: "invio"; visibili: readonly CampoRiga[] }
  | { tipo: "tab"; visibili: readonly CampoRiga[]; indietro: boolean }
  | { tipo: "giu" }
  | { tipo: "su" }
  | { tipo: "esc" }
  | { tipo: "elimina_riga" }
  | { tipo: "nuovo" };

export function riduci(stato: StatoRighe, azione: Azione): StatoRighe {
  // Con un avviso aperto: Invio conferma, Esc corregge, il resto è fermo.
  if (stato.avviso && azione.tipo !== "scrivi") {
    const avviso = stato.avviso;
    if (azione.tipo === "invio") {
      const righe = stato.righe.map((r, i) =>
        i === avviso.riga ? { ...r, confermati: [...r.confermati, chiaveConferma(r, avviso.codice)] } : r,
      );
      const confermato = { ...stato, righe, avviso: null };
      // La nuova riga, se il cursore andava oltre l'ultima.
      const conRiga = avviso.dopo.riga >= righe.length ? conNuovaRiga(confermato) : confermato;
      return muovi(conRiga, avviso.dopo);
    }
    if (azione.tipo === "esc" || azione.tipo === "vai") return { ...stato, avviso: null };
    return stato;
  }

  switch (azione.tipo) {
    case "scrivi": {
      const righe = stato.righe.map((r, i) => (i === azione.riga ? { ...r, [azione.campo]: azione.valore } : r));
      return { ...stato, righe, avviso: null };
    }
    case "vai":
      if (!stato.righe[azione.cursore.riga]) return stato;
      return muovi(stato, azione.cursore);
    case "invio": {
      const { campo } = stato.cursore;
      const sequenza = SEQUENZA_INVIO.filter((c) => azione.visibili.includes(c));
      const inSequenza = sequenza.indexOf(campo);
      let prossimo: CampoRiga | undefined;
      if (inSequenza >= 0) prossimo = sequenza[inSequenza + 1];
      else prossimo = azione.visibili[azione.visibili.indexOf(campo) + 1];
      if (prossimo) return muovi(stato, { riga: stato.cursore.riga, campo: prossimo });
      return rigaSotto(stato, "articolo");
    }
    case "tab": {
      const indice = azione.visibili.indexOf(stato.cursore.campo);
      const prossimo = azione.visibili[indice + (azione.indietro ? -1 : 1)];
      if (prossimo) return muovi(stato, { riga: stato.cursore.riga, campo: prossimo });
      if (azione.indietro) {
        const ultimo = azione.visibili[azione.visibili.length - 1];
        return stato.cursore.riga > 0 && ultimo ? muovi(stato, { riga: stato.cursore.riga - 1, campo: ultimo }) : stato;
      }
      return rigaSotto(stato, "articolo");
    }
    case "giu":
      return rigaSotto(stato, stato.cursore.campo);
    case "su":
      return stato.cursore.riga > 0 ? muovi(stato, { riga: stato.cursore.riga - 1, campo: stato.cursore.campo }) : stato;
    case "esc": {
      const { riga, campo } = stato.cursore;
      if (cella(stato, stato.cursore) !== stato.originale) {
        return riduci(stato, { tipo: "scrivi", riga, campo, valore: stato.originale });
      }
      const attuale = stato.righe[riga];
      if (attuale && vuota(attuale) && stato.righe.length > 1) return riduci(stato, { tipo: "elimina_riga" });
      return stato;
    }
    case "elimina_riga": {
      if (stato.righe.length === 1) return riduci(stato, { tipo: "nuovo" });
      const righe = stato.righe.filter((_, i) => i !== stato.cursore.riga);
      const riga = Math.min(stato.cursore.riga, righe.length - 1);
      return posiziona({ ...stato, righe }, { riga, campo: stato.cursore.campo });
    }
    case "nuovo":
      return { ...iniziale(), righe: [rigaVuota(stato.prossimaChiave)], prossimaChiave: stato.prossimaChiave + 1 };
  }
}

/** Le righe come le vuole il backend; le righe vuote restano (il backend le salta) per allineare il calcolo. */
export function inBozza(righe: readonly RigaUI[]): BozzaRiga[] {
  return righe.map((r) => {
    const riga: BozzaRiga = { articolo: r.articolo.trim() };
    const numero = (testo: string) => {
      const d = decimale(testo);
      return d === null || d === undefined ? undefined : d;
    };
    if (r.unita_misura.trim()) riga.unita_misura = r.unita_misura.trim();
    riga.colli = numero(r.colli) ?? "0";
    riga.lordo = numero(r.lordo) ?? "0";
    riga.tara = numero(r.tara) ?? "0";
    const prezzo = numero(r.prezzo);
    if (prezzo !== undefined) riga.prezzo = prezzo;
    const quantita = numero(r.quantita);
    if (quantita !== undefined) riga.quantita = quantita;
    if (r.sconto.trim()) riga.sconto = r.sconto.trim();
    if (r.descrizione.trim()) riga.descrizione = r.descrizione;
    if (r.magazzino.trim()) riga.magazzino = r.magazzino.trim();
    return riga;
  });
}

/** Testi battuti che non sono numeri: la cella si segna e la bozza non si salva. */
export function numeriErrati(riga: RigaUI): CampoRiga[] {
  return (["colli", "lordo", "tara", "quantita", "prezzo"] as const).filter((c) => decimale(riga[c]) === undefined);
}
