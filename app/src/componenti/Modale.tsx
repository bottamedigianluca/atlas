// Finestra modale satinata (direttiva §3.6): sfondo sfocato, bordo da 1 px, angoli arrotondati.
// `Esc` chiude; il fuoco resta dentro finché è aperta e torna dov'era alla chiusura.

import { type ReactNode, useEffect, useRef } from "react";

interface Props {
  titolo: string;
  sottotitolo?: string;
  larghezza?: string;
  onChiudi: () => void;
  children: ReactNode;
  piede?: ReactNode;
  /** Titolo rosso a destra, come le maschere di ricerca di Arca. */
  titoloArca?: boolean;
}

export function Modale({ titolo, sottotitolo, larghezza = "max-w-3xl", onChiudi, children, piede, titoloArca = false }: Props) {
  const riquadro = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const prima = document.activeElement as HTMLElement | null;
    const primo = riquadro.current?.querySelector<HTMLElement>("[data-fuoco-iniziale], input, button, [tabindex='0']");
    primo?.focus();
    return () => prima?.focus();
  }, []);

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center bg-zinc-900/20 p-6 pt-[8vh] backdrop-blur-sm dark:bg-black/40"
      onMouseDown={(e) => e.target === e.currentTarget && onChiudi()}
    >
      <div
        ref={riquadro}
        role="dialog"
        aria-modal="true"
        aria-label={titolo}
        className={`w-full ${larghezza} overflow-hidden rounded-xl border border-zinc-200/80 bg-white/80 shadow-2xl shadow-zinc-900/10 backdrop-blur-md dark:border-zinc-700/70 dark:bg-zinc-900/80`}
        onKeyDown={(e) => {
          if (e.key === "Escape") {
            e.preventDefault();
            e.stopPropagation();
            onChiudi();
          }
          if (e.key === "Tab") {
            const focalizzabili = riquadro.current?.querySelectorAll<HTMLElement>(
              "input, button, select, [tabindex='0']",
            );
            if (!focalizzabili?.length) return;
            const primo = focalizzabili[0];
            const ultimo = focalizzabili[focalizzabili.length - 1];
            if (e.shiftKey && document.activeElement === primo) {
              e.preventDefault();
              ultimo?.focus();
            } else if (!e.shiftKey && document.activeElement === ultimo) {
              e.preventDefault();
              primo?.focus();
            }
          }
        }}
      >
        {titoloArca ? (
          <header className="flex items-baseline justify-between gap-4 border-b border-zinc-200/80 px-4 py-2 dark:border-zinc-800">
            <span className="text-[11px] text-zinc-400">
              <kbd className="tasto">Esc</kbd> chiude
            </span>
            <h2 className="text-[17px] font-bold tracking-wide text-[#c0161e] dark:text-[#ff6b6b]">{titolo}</h2>
          </header>
        ) : (
          <header className="flex items-baseline justify-between gap-4 border-b border-zinc-200/80 px-5 py-3 dark:border-zinc-800">
            <div>
              <h2 className="text-[13px] font-semibold tracking-wide">{titolo}</h2>
              {sottotitolo && <p className="mt-0.5 text-xs text-zinc-500 dark:text-zinc-400">{sottotitolo}</p>}
            </div>
            <span className="text-[11px] text-zinc-400">
              <kbd className="tasto">Esc</kbd> chiude
            </span>
          </header>
        )}
        <div className="max-h-[70vh] overflow-auto">{children}</div>
        {piede && (
          <footer className="border-t border-zinc-200/80 px-5 py-2.5 text-xs text-zinc-500 dark:border-zinc-800 dark:text-zinc-400">
            {piede}
          </footer>
        )}
      </div>
    </div>
  );
}
