// Layout di una griglia scelto dall'operatore: ordine, larghezze e visibilità delle colonne,
// salvato nella postazione. Il layout di fabbrica è quello di Arca (UserPref 1443 per le righe,
// la griglia dell'elenco documenti per l'elenco).

export interface Layout {
  /** Identificativi delle colonne nell'ordine visibile, anche quelle nascoste. */
  ordine: string[];
  larghezze: Record<string, number>;
  nascoste: string[];
}

export interface ColonnaBase {
  id: string;
  etichetta: string;
  larghezza: number;
}

export const LARGHEZZA_MINIMA = 16;

/** Il layout di una griglia: colonne di fabbrica, chiave d'archivio, colonne che non si nascondono. */
export interface Griglia {
  colonne: readonly ColonnaBase[];
  chiave: string;
  fisse: readonly string[];
}

export function layoutDiFabbrica(griglia: Griglia): Layout {
  return {
    ordine: griglia.colonne.map((c) => c.id),
    larghezze: Object.fromEntries(griglia.colonne.map((c) => [c.id, c.larghezza])),
    nascoste: [],
  };
}

/**
 * Un layout letto dall'archivio, ripulito: colonne sconosciute tolte, colonne nuove aggiunte in
 * fondo con la larghezza di fabbrica. Un layout illeggibile torna quello di fabbrica.
 */
export function normalizza(griglia: Griglia, grezzo: unknown): Layout {
  const fabbrica = layoutDiFabbrica(griglia);
  if (!grezzo || typeof grezzo !== "object") return fabbrica;
  const note = new Set(fabbrica.ordine);
  const g = grezzo as Partial<Layout>;
  const ordine = Array.isArray(g.ordine) ? g.ordine.filter((id): id is string => note.has(id as string)) : [];
  const unici = [...new Set(ordine)];
  for (const id of fabbrica.ordine) if (!unici.includes(id)) unici.push(id);
  const larghezze: Record<string, number> = { ...fabbrica.larghezze };
  if (g.larghezze && typeof g.larghezze === "object") {
    for (const [id, l] of Object.entries(g.larghezze)) {
      if (note.has(id) && typeof l === "number" && Number.isFinite(l)) larghezze[id] = Math.max(LARGHEZZA_MINIMA, Math.round(l));
    }
  }
  const nascoste = Array.isArray(g.nascoste) ? g.nascoste.filter((id) => note.has(id as string)) : [];
  return { ordine: unici, larghezze, nascoste: [...new Set(nascoste)].filter((id) => !griglia.fisse.includes(id)) };
}

export function carica(griglia: Griglia): Layout {
  try {
    const testo = localStorage.getItem(griglia.chiave);
    return testo ? normalizza(griglia, JSON.parse(testo)) : layoutDiFabbrica(griglia);
  } catch {
    return layoutDiFabbrica(griglia);
  }
}

export function salva(griglia: Griglia, layout: Layout): void {
  try {
    localStorage.setItem(griglia.chiave, JSON.stringify(layout));
  } catch {
    // archivio non disponibile: il layout vale fino alla chiusura
  }
}

export function ripristina(griglia: Griglia): Layout {
  try {
    localStorage.removeItem(griglia.chiave);
  } catch {
    // niente da togliere
  }
  return layoutDiFabbrica(griglia);
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

export function alterna(griglia: Griglia, layout: Layout, id: string): Layout {
  if (griglia.fisse.includes(id)) return layout;
  const nascoste = layout.nascoste.includes(id) ? layout.nascoste.filter((c) => c !== id) : [...layout.nascoste, id];
  return { ...layout, nascoste };
}
