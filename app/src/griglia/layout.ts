// Layout della griglia scelto dall'operatore: ordine, larghezze e visibilità delle colonne,
// salvato nella postazione. Il layout di fabbrica è quello storico di Arca (UserPref 1443).

import { COLONNE, PER_ID } from "./colonne";

export interface Layout {
  /** Identificativi delle colonne nell'ordine visibile, anche quelle nascoste. */
  ordine: string[];
  larghezze: Record<string, number>;
  nascoste: string[];
}

const CHIAVE = "atlas.griglia.righe.v1";
export const LARGHEZZA_MINIMA = 16;

export function layoutDiFabbrica(): Layout {
  return {
    ordine: COLONNE.map((c) => c.id),
    larghezze: Object.fromEntries(COLONNE.map((c) => [c.id, c.larghezza])),
    nascoste: [],
  };
}

/**
 * Un layout letto dall'archivio, ripulito: colonne sconosciute tolte, colonne nuove aggiunte in
 * fondo con la larghezza di fabbrica. Un layout illeggibile torna quello di fabbrica.
 */
export function normalizza(grezzo: unknown): Layout {
  const fabbrica = layoutDiFabbrica();
  if (!grezzo || typeof grezzo !== "object") return fabbrica;
  const g = grezzo as Partial<Layout>;
  const ordine = Array.isArray(g.ordine) ? g.ordine.filter((id): id is string => PER_ID.has(id as string)) : [];
  const unici = [...new Set(ordine)];
  for (const id of fabbrica.ordine) if (!unici.includes(id)) unici.push(id);
  const larghezze: Record<string, number> = { ...fabbrica.larghezze };
  if (g.larghezze && typeof g.larghezze === "object") {
    for (const [id, l] of Object.entries(g.larghezze)) {
      if (PER_ID.has(id) && typeof l === "number" && Number.isFinite(l)) {
        larghezze[id] = Math.max(LARGHEZZA_MINIMA, Math.round(l));
      }
    }
  }
  const nascoste = Array.isArray(g.nascoste) ? g.nascoste.filter((id) => PER_ID.has(id as string)) : [];
  // L'articolo non si nasconde: è dove parte ogni riga.
  return { ordine: unici, larghezze, nascoste: [...new Set(nascoste)].filter((id) => id !== "ColCd_AR") };
}

export function carica(): Layout {
  try {
    const testo = localStorage.getItem(CHIAVE);
    return testo ? normalizza(JSON.parse(testo)) : layoutDiFabbrica();
  } catch {
    return layoutDiFabbrica();
  }
}

export function salva(layout: Layout): void {
  try {
    localStorage.setItem(CHIAVE, JSON.stringify(layout));
  } catch {
    // archivio non disponibile: il layout vale fino alla chiusura
  }
}

export function ripristina(): Layout {
  try {
    localStorage.removeItem(CHIAVE);
  } catch {
    // niente da togliere
  }
  return layoutDiFabbrica();
}

export function visibili(layout: Layout): string[] {
  return layout.ordine.filter((id) => !layout.nascoste.includes(id));
}

/** Sposta la colonna `id` prima della colonna `prima` (in fondo se `prima` è assente). */
export function sposta(layout: Layout, id: string, prima: string | null): Layout {
  if (id === prima) return layout;
  const ordine = layout.ordine.filter((c) => c !== id);
  const indice = prima === null ? ordine.length : ordine.indexOf(prima);
  ordine.splice(indice < 0 ? ordine.length : indice, 0, id);
  return { ...layout, ordine };
}

export function ridimensiona(layout: Layout, id: string, larghezza: number): Layout {
  return { ...layout, larghezze: { ...layout.larghezze, [id]: Math.max(LARGHEZZA_MINIMA, Math.round(larghezza)) } };
}

export function alterna(layout: Layout, id: string): Layout {
  if (id === "ColCd_AR") return layout;
  const nascoste = layout.nascoste.includes(id) ? layout.nascoste.filter((c) => c !== id) : [...layout.nascoste, id];
  return { ...layout, nascoste };
}
