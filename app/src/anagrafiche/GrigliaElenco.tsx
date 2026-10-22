// Griglia degli elenchi delle anagrafiche (clienti, articoli), come l'Elenco di Arca: intestazioni
// personalizzabili (larghezza, ordine, clic destro per mostrare e nascondere), riga dei filtri per
// colonna sotto le intestazioni, riga scelta piena nel colore guida. Frecce, PgSu/PgGiù, Home/Fine;
// `Invio` o doppio clic apre la scheda.

import { useEffect, useMemo, useRef, useState } from "react";
import { Intestazione } from "../griglia/Intestazione";
import { type Griglia, type Layout, carica, salva, visibili } from "../griglia/layout";
import { MenuColonne } from "../griglia/MenuColonne";

export interface Colonna<T> {
  id: string;
  etichetta: string;
  larghezza: number;
  numerica?: boolean;
  suggerimento?: string;
  valore: (r: T) => React.ReactNode;
  /** Testo su cui filtra la riga dei filtri, se `valore` non è già un testo. */
  testo?: (r: T) => string;
}

const ALTEZZA = 18;

function testoFiltro<T>(c: Colonna<T>, r: T): string {
  if (c.testo) return c.testo(r);
  const v = c.valore(r);
  return typeof v === "string" || typeof v === "number" ? String(v) : "";
}

export function GrigliaElenco<T>({ nome, griglia, colonne: tutte, righe, chiave, attivo, onApri, piede }: {
  nome: string;
  griglia: Griglia;
  colonne: readonly Colonna<T>[];
  righe: T[];
  chiave: (r: T) => string;
  attivo: boolean;
  onApri: (r: T) => void;
  /** Legenda a sinistra della barra in fondo. */
  piede?: React.ReactNode;
}) {
  const [filtri, setFiltri] = useState<Record<string, string>>({});
  const [scelta, setScelta] = useState(0);
  const [layout, setLayout] = useState<Layout>(() => carica(griglia));
  const [menu, setMenu] = useState<{ x: number; y: number } | null>(null);
  const contenitore = useRef<HTMLDivElement>(null);
  const perId = useMemo(() => new Map(tutte.map((c) => [c.id, c])), [tutte]);

  useEffect(() => salva(griglia, layout), [griglia, layout]);
  useEffect(() => {
    if (attivo) contenitore.current?.focus();
  }, [attivo]);

  const colonne = visibili(layout).map((id) => perId.get(id)).filter((c): c is Colonna<T> => !!c);
  const larghezza = colonne.reduce((s, c) => s + (layout.larghezze[c.id] ?? c.larghezza), 0);
  const filtrate = useMemo(() => {
    const attivi = Object.entries(filtri).filter(([, f]) => f.trim());
    if (!attivi.length) return righe;
    return righe.filter((r) =>
      attivi.every(([id, f]) => {
        const c = perId.get(id);
        return !c || testoFiltro(c, r).toLowerCase().includes(f.trim().toLowerCase());
      }),
    );
  }, [righe, filtri, perId]);
  useEffect(() => setScelta((s) => Math.min(s, Math.max(filtrate.length - 1, 0))), [filtrate]);

  return (
    <div className="flex h-full min-h-0 flex-col">
      <div
        ref={contenitore}
        tabIndex={0}
        role="grid"
        aria-label={nome}
        className="min-h-0 flex-1 overflow-auto bg-white outline-none dark:bg-zinc-950"
        onKeyDown={(e) => {
          if (e.target !== e.currentTarget) return;
          const ultimo = filtrate.length - 1;
          if (e.key === "ArrowDown") setScelta((s) => Math.min(s + 1, ultimo));
          else if (e.key === "ArrowUp") setScelta((s) => Math.max(s - 1, 0));
          else if (e.key === "PageDown") setScelta((s) => Math.min(s + 20, ultimo));
          else if (e.key === "PageUp") setScelta((s) => Math.max(s - 20, 0));
          else if (e.key === "Home") setScelta(0);
          else if (e.key === "End") setScelta(ultimo);
          else if (e.key === "Enter" && filtrate[scelta]) onApri(filtrate[scelta]);
          else return;
          e.preventDefault();
        }}
      >
        <div style={{ width: larghezza }} className="flex min-h-full flex-col">
          <div className="sticky top-0 z-10">
            <Intestazione griglia={griglia} colonne={colonne} layout={layout} altezza={20} onLayout={setLayout} onMenu={(x, y) => setMenu({ x, y })} />
            <div role="row" aria-label="Filtri per colonna" className="flex border-b border-zinc-300 bg-primario-tenue/70 dark:border-zinc-700" style={{ height: ALTEZZA + 2 }}>
              {colonne.map((c) => (
                <input
                  key={c.id}
                  aria-label={`Filtro ${c.etichetta}`}
                  value={filtri[c.id] ?? ""}
                  onChange={(e) => setFiltri((f) => ({ ...f, [c.id]: e.target.value }))}
                  onKeyDown={(e) => {
                    if (e.key === "ArrowDown" || e.key === "Enter") {
                      e.preventDefault();
                      contenitore.current?.focus();
                    }
                    if (e.key === "Escape" && filtri[c.id]) {
                      e.preventDefault();
                      e.stopPropagation();
                      setFiltri((f) => ({ ...f, [c.id]: "" }));
                    }
                  }}
                  spellCheck={false}
                  autoComplete="off"
                  style={{ width: layout.larghezze[c.id] ?? c.larghezza }}
                  className={`h-full shrink-0 border-r border-zinc-200 bg-transparent px-1 text-[11px] outline-none focus:bg-white focus:shadow-[inset_0_0_0_2px_var(--atlas-anello)] dark:border-zinc-800 dark:focus:bg-zinc-900 ${
                    c.numerica ? "text-right tabular-nums" : ""
                  }`}
                />
              ))}
            </div>
          </div>
          {filtrate.map((r, i) => {
            const selezionata = i === scelta;
            return (
              <div
                key={chiave(r)}
                role="row"
                aria-selected={selezionata}
                ref={(el) => {
                  if (selezionata && el) el.scrollIntoView({ block: "nearest" });
                }}
                onMouseDown={() => setScelta(i)}
                onDoubleClick={() => onApri(r)}
                style={{ height: ALTEZZA }}
                className={`flex border-b border-zinc-100 text-[11.5px] dark:border-zinc-900 ${
                  selezionata ? "bg-primario text-white shadow-[inset_4px_0_0_var(--atlas-primario-forte)]" : i % 2 ? "bg-[#f9fafb] dark:bg-white/[0.025]" : ""
                }`}
              >
                {colonne.map((c) => (
                  <div
                    key={c.id}
                    role="gridcell"
                    style={{ width: layout.larghezze[c.id] ?? c.larghezza }}
                    className={`flex shrink-0 items-center overflow-hidden whitespace-nowrap border-r px-1 ${
                      selezionata ? "border-white/20" : "border-zinc-100 dark:border-zinc-900"
                    } ${c.numerica ? "justify-end tabular-nums" : ""}`}
                  >
                    {c.valore(r)}
                  </div>
                ))}
              </div>
            );
          })}
          <div aria-hidden className="flex flex-1">
            {colonne.map((c) => (
              <div key={c.id} style={{ width: layout.larghezze[c.id] ?? c.larghezza }} className="shrink-0 border-r border-zinc-100 dark:border-zinc-900" />
            ))}
          </div>
        </div>
        {menu && <MenuColonne griglia={griglia} layout={layout} x={menu.x} y={menu.y} onLayout={setLayout} onChiudi={() => setMenu(null)} />}
      </div>
      <footer className="flex h-6 shrink-0 items-center gap-4 border-t border-zinc-200 px-3 text-[11px] text-zinc-600 dark:border-zinc-800 dark:text-zinc-400">
        {piede}
        <span className="ml-auto tabular-nums">
          {filtrate.length === righe.length ? `${righe.length}` : `${filtrate.length} di ${righe.length}`} · {filtrate[scelta] ? `${scelta + 1}/${filtrate.length}` : "—"}
        </span>
      </footer>
    </div>
  );
}
