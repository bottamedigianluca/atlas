// Menu delle colonne di una griglia, col clic destro sulle intestazioni come in Arca: mostra o
// nascondi ogni colonna, ripristina il layout di fabbrica. `Esc` o un clic fuori lo chiude.

import { useEffect, useRef } from "react";
import { type Griglia, type Layout, alterna, ripristina } from "./layout";

interface Props {
  griglia: Griglia;
  layout: Layout;
  x: number;
  y: number;
  onLayout: (layout: Layout) => void;
  onChiudi: () => void;
}

export function MenuColonne({ griglia, layout, x, y, onLayout, onChiudi }: Props) {
  const menu = useRef<HTMLDivElement>(null);
  useEffect(() => {
    menu.current?.querySelector<HTMLElement>("input")?.focus();
    const fuori = (e: MouseEvent) => {
      if (!menu.current?.contains(e.target as Node)) onChiudi();
    };
    window.addEventListener("mousedown", fuori);
    return () => window.removeEventListener("mousedown", fuori);
  }, [onChiudi]);

  const etichette = new Map(griglia.colonne.map((c) => [c.id, c.etichetta]));
  // Il menu resta dentro la finestra.
  const sinistra = Math.min(x, window.innerWidth - 270);
  const alto = Math.min(y, window.innerHeight - 380);
  return (
    <div
      ref={menu}
      role="menu"
      aria-label="Colonne della griglia"
      onKeyDown={(e) => {
        if (e.key === "Escape") {
          e.stopPropagation();
          onChiudi();
        }
      }}
      style={{ left: sinistra, top: alto }}
      className="fixed z-40 w-64 overflow-hidden rounded-xl border border-zinc-200/80 bg-white/90 shadow-xl backdrop-blur-md dark:border-zinc-700/70 dark:bg-zinc-900/90"
    >
      <div className="max-h-80 overflow-auto p-1.5">
        {layout.ordine.map((id) => {
          const visibile = !layout.nascoste.includes(id);
          return (
            <label
              key={id}
              className="flex cursor-pointer items-center gap-2 rounded-md px-2 py-0.5 text-xs hover:bg-zinc-100 dark:hover:bg-zinc-800"
            >
              <input
                type="checkbox"
                checked={visibile}
                disabled={griglia.fisse.includes(id)}
                onChange={() => onLayout(alterna(griglia, layout, id))}
                className="accent-primario"
              />
              <span className="flex-1 truncate">{etichette.get(id) ?? id}</span>
            </label>
          );
        })}
      </div>
      <div className="border-t border-zinc-200/80 p-1.5 dark:border-zinc-800">
        <button
          type="button"
          className="pulsante w-full justify-center text-xs"
          onClick={() => {
            onLayout(ripristina(griglia));
            onChiudi();
          }}
        >
          Ripristina layout di fabbrica
        </button>
      </div>
    </div>
  );
}
