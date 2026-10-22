// Numeri battuti e numeri mostrati. L'operatore batte con la virgola o con il punto; al
// backend vanno testi decimali con il punto. Il formato a video è italiano.

/** Testo battuto → decimale per il backend; `null` se vuoto, `undefined` se non è un numero. */
export function decimale(testo: string): string | null | undefined {
  const pulito = testo.trim().replace(/\s/g, "");
  if (pulito === "") return null;
  // Separatore delle migliaia non ammesso: "1.234,5" è ambiguo al banco, si rifiuta.
  const normalizzato = pulito.replace(",", ".");
  if (!/^-?\d*\.?\d+$|^-?\d+\.$/.test(normalizzato)) return undefined;
  return normalizzato.endsWith(".") ? normalizzato.slice(0, -1) : normalizzato;
}

/** Valore numerico per i controlli a video (mai per gli importi). */
export function valore(testo: string): number {
  const d = decimale(testo);
  return d ? Number(d) : 0;
}

const formati = new Map<string, Intl.NumberFormat>();

function formato(min: number, max: number): Intl.NumberFormat {
  const chiave = `${min}-${max}`;
  let f = formati.get(chiave);
  if (!f) {
    f = new Intl.NumberFormat("it-IT", { minimumFractionDigits: min, maximumFractionDigits: max, useGrouping: true });
    formati.set(chiave, f);
  }
  return f;
}

/** Un decimale del backend in formato italiano, senza perdere cifre: "1234.5" → "1.234,50". */
export function mostra(testo: string | null | undefined, decimaliMinimi = 2, decimaliMassimi = 3): string {
  if (testo === null || testo === undefined || testo === "") return "";
  const n = Number(testo);
  if (!Number.isFinite(n)) return testo;
  const [, frazione = ""] = testo.split(".");
  const massimi = Math.max(decimaliMassimi, Math.min(frazione.replace(/0+$/, "").length, 6));
  return formato(decimaliMinimi, massimi).format(n);
}

export const importo = (testo: string | null | undefined) => mostra(testo, 2, 2);
export const quantita = (testo: string | null | undefined) => mostra(testo, 2, 3);
export const prezzo = (testo: string | null | undefined) => mostra(testo, 2, 3);

/** Data AAAA-MM-GG → GG/MM/AAAA. */
export function data(iso: string | null | undefined): string {
  if (!iso) return "";
  const [a, m, g] = iso.slice(0, 10).split("-");
  return a && m && g ? `${g}/${m}/${a}` : iso;
}

/** Oggi in ora locale, AAAA-MM-GG. */
export function oggi(): string {
  const d = new Date();
  const due = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${due(d.getMonth() + 1)}-${due(d.getDate())}`;
}
