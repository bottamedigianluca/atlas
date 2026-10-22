// Intestazione di una griglia con le colonne personalizzabili (direttiva §3.8): trascina per
// spostare, bordo destro per allargare (doppio clic = larghezza di fabbrica), clic destro per il
// menu delle colonne come in Arca.

import { useState } from "react";
import { type ColonnaBase, type Griglia, type Layout, layoutDiFabbrica, ridimensiona, sposta } from "./layout";

export function Intestazione<C extends ColonnaBase & { numerica?: boolean; suggerimento?: string }>({
  griglia,
  colonne,
  layout,
  altezza = 22,
  onLayout,
  onMenu,
}: {
  griglia: Griglia;
  colonne: C[];
  layout: Layout;
  altezza?: number;
  onLayout: (l: Layout) => void;
  onMenu: (x: number, y: number) => void;
}) {
  const [trascinata, setTrascinata] = useState<string | null>(null);
  const fabbrica = layoutDiFabbrica(griglia);

  const inizioRidimensiona = (e: React.PointerEvent<HTMLSpanElement>, colonna: C) => {
    e.preventDefault();
    e.stopPropagation();
    const partenza = e.clientX;
    const larghezza = layout.larghezze[colonna.id] ?? colonna.larghezza;
    const maniglia = e.currentTarget;
    maniglia.setPointerCapture(e.pointerId);
    const muovi = (ev: PointerEvent) => onLayout(ridimensiona(layout, colonna.id, larghezza + ev.clientX - partenza));
    const fine = () => {
      maniglia.removeEventListener("pointermove", muovi);
      maniglia.removeEventListener("pointerup", fine);
      maniglia.removeEventListener("pointercancel", fine);
    };
    maniglia.addEventListener("pointermove", muovi);
    maniglia.addEventListener("pointerup", fine);
    maniglia.addEventListener("pointercancel", fine);
  };

  return (
    <div
      role="row"
      onContextMenu={(e) => {
        e.preventDefault();
        onMenu(e.clientX, e.clientY);
      }}
      className="sticky top-0 z-10 flex border-b border-zinc-300 bg-zinc-100 dark:border-zinc-700 dark:bg-zinc-900"
    >
      {colonne.map((c) => (
        <div
          key={c.id}
          role="columnheader"
          draggable
          title={`${c.suggerimento ?? c.etichetta} — trascina per spostare, bordo destro per allargare, clic destro per le colonne`}
          onDragStart={(e) => {
            setTrascinata(c.id);
            e.dataTransfer.effectAllowed = "move";
          }}
          onDragOver={(e) => trascinata && e.preventDefault()}
          onDrop={(e) => {
            e.preventDefault();
            if (trascinata) onLayout(sposta(layout, trascinata, c.id));
            setTrascinata(null);
          }}
          onDragEnd={() => setTrascinata(null)}
          style={{ width: layout.larghezze[c.id] ?? c.larghezza, height: altezza }}
          className={`relative flex shrink-0 cursor-default select-none items-center border-r border-zinc-300 px-1.5 text-[11px] font-semibold text-zinc-600 last:border-r-0 dark:border-zinc-700 dark:text-zinc-300 ${
            c.numerica ? "justify-end" : ""
          } ${trascinata === c.id ? "opacity-40" : ""}`}
        >
          <span className="truncate">{c.etichetta}</span>
          <span
            aria-hidden
            onPointerDown={(e) => inizioRidimensiona(e, c)}
            onDoubleClick={() => onLayout(ridimensiona(layout, c.id, fabbrica.larghezze[c.id] ?? c.larghezza))}
            className="absolute -right-1 top-0 z-10 h-full w-2 cursor-col-resize hover:bg-sky-500/30"
          />
        </div>
      ))}
    </div>
  );
}
