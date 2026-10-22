// La finestra di un'anagrafica (Clienti, Articoli) come quelle di Arca: barra degli strumenti,
// pagine Elenco e Scheda, frecce |◀ ◀ ▶ ▶| che scorrono le anagrafiche nell'ordine dell'elenco
// (filtri compresi).
//
// Tasti: Ctrl+1/2 Elenco/Scheda, Ctrl+N nuovo, F10 salva (solo un'anagrafica nuova: le altre si
// modificano in Arca), Alt+←/→ precedente/successivo, Alt+Home/Fine primo/ultimo, Esc dalla scheda
// torna all'elenco, F5 rilegge.

import { type ReactNode, useCallback, useEffect, useRef, useState } from "react";
import type { Griglia } from "../griglia/layout";
import { type Colonna, GrigliaElenco } from "./GrigliaElenco";

export type PaginaAnagrafica = "Elenco" | "Scheda";

export function Area<T>({ attivo, nome, griglia, colonne, righe, chiave, classeRiga, piede, errore, aperto, onApri, pagina, onPagina, scheda, onNuovo, nuovo, onSalva, onAggiorna }: {
  attivo: boolean;
  nome: string;
  griglia: Griglia;
  colonne: readonly Colonna<T>[];
  righe: T[];
  chiave: (r: T) => string;
  classeRiga?: (r: T) => string | undefined;
  piede?: ReactNode;
  errore?: string | null;
  /** Codice dell'anagrafica aperta nella scheda. */
  aperto: string | null;
  onApri: (codice: string) => void;
  pagina: PaginaAnagrafica;
  onPagina: (p: PaginaAnagrafica) => void;
  scheda: ReactNode;
  onNuovo?: () => void;
  /** Nome del comando Nuovo ("Nuovo cliente"). */
  nuovo?: string;
  /** Salva l'anagrafica nuova in battitura; assente, Salva è spento. */
  onSalva?: () => void;
  onAggiorna: () => void;
}) {
  const filtrate = useRef<T[]>([]);
  const [scelto, setScelto] = useState<string | null>(null);
  const [posizione, setPosizione] = useState<string | null>(null);

  const vai = useCallback(
    (dove: "primo" | "precedente" | "successivo" | "ultimo") => {
      const codici = filtrate.current.map(chiave);
      if (!codici.length) return;
      const corrente = pagina === "Scheda" ? aperto : scelto;
      const i = corrente === null ? -1 : codici.indexOf(corrente);
      const indice =
        dove === "primo" ? 0 : dove === "ultimo" ? codici.length - 1 : Math.min(Math.max(i + (dove === "successivo" ? 1 : -1), 0), codici.length - 1);
      const codice = codici[indice]!;
      setScelto(codice);
      if (pagina === "Scheda") onApri(codice);
    },
    [pagina, aperto, scelto, chiave, onApri],
  );

  useEffect(() => {
    if (!attivo) return;
    const tasto = (e: KeyboardEvent) => {
      if (document.querySelector("[role=dialog]")) return;
      if (e.ctrlKey && !e.altKey && !e.shiftKey) {
        if (e.key === "1" || e.key === "2") {
          e.preventDefault();
          onPagina(e.key === "1" ? "Elenco" : "Scheda");
        } else if (e.key.toLowerCase() === "n" && onNuovo) {
          e.preventDefault();
          onNuovo();
        }
        return;
      }
      if (e.altKey && !e.ctrlKey) {
        const dove = ({ ArrowLeft: "precedente", ArrowRight: "successivo", Home: "primo", End: "ultimo" } as const)[
          e.key as "ArrowLeft" | "ArrowRight" | "Home" | "End"
        ];
        if (dove) {
          e.preventDefault();
          vai(dove);
        }
        return;
      }
      if (e.key === "F5") {
        e.preventDefault();
        onAggiorna();
      } else if (e.key === "F10") {
        e.preventDefault();
        onSalva?.();
      } else if (e.key === "Escape" && pagina === "Scheda" && !e.defaultPrevented) {
        e.preventDefault();
        if (aperto) setScelto(aperto);
        onPagina("Elenco");
      }
    };
    window.addEventListener("keydown", tasto);
    return () => window.removeEventListener("keydown", tasto);
  }, [attivo, pagina, aperto, vai, onPagina, onNuovo, onSalva, onAggiorna]);

  const posizioneScheda = () => {
    const codici = filtrate.current.map(chiave);
    const i = aperto ? codici.indexOf(aperto) : -1;
    return i >= 0 ? `${i + 1}/${codici.length}` : null;
  };

  return (
    <div className="flex h-full flex-col">
      <nav aria-label="Strumenti" className="flex h-9 shrink-0 items-center gap-1 border-b border-zinc-200 bg-zinc-50/80 px-2 dark:border-zinc-800 dark:bg-zinc-900/40">
        <Pulsante
          nome="Salva"
          tasto="F10"
          disabled={!onSalva}
          onClick={onSalva}
          title={onSalva ? undefined : "Si salva un'anagrafica nuova; quelle esistenti si modificano in Arca"}
        />
        <span className="mx-1 h-5 w-px bg-zinc-200 dark:bg-zinc-700" />
        {onNuovo && <Pulsante nome={nuovo ?? "Nuovo"} tasto="Ctrl+N" onClick={onNuovo} />}
        <Pulsante nome="Aggiorna" tasto="F5" onClick={onAggiorna} />
        <span className="mx-1 h-5 w-px bg-zinc-200 dark:bg-zinc-700" />
        {(
          [
            ["primo", "|◀", "Alt+Home"],
            ["precedente", "◀", "Alt+←"],
            ["successivo", "▶", "Alt+→"],
            ["ultimo", "▶|", "Alt+Fine"],
          ] as const
        ).map(([dove, segno, tasto]) => (
          <button
            key={dove}
            type="button"
            tabIndex={-1}
            aria-label={dove[0]!.toUpperCase() + dove.slice(1)}
            title={`${dove[0]!.toUpperCase() + dove.slice(1)} (${tasto})`}
            onClick={() => vai(dove)}
            className="h-7 rounded-md px-2 text-[11px] text-zinc-800 hover:bg-zinc-200/70 dark:text-zinc-100 dark:hover:bg-zinc-700/60"
          >
            {segno}
          </button>
        ))}
        {errore && <span role="alert" className="ml-3 truncate text-[12px] text-rose-600">{errore}</span>}
        <span className="ml-auto text-[11px] tabular-nums text-zinc-500">{pagina === "Scheda" ? posizioneScheda() : posizione}</span>
      </nav>
      <div role="tablist" aria-label={`Pagine ${nome}`} className="flex h-7 shrink-0 items-end gap-1 border-b border-zinc-200 px-3 dark:border-zinc-800">
        {(["Elenco", "Scheda"] as const).map((p, i) => (
          <button
            key={p}
            type="button"
            role="tab"
            aria-selected={pagina === p}
            tabIndex={-1}
            onClick={() => onPagina(p)}
            className={`-mb-px border-b-2 px-2.5 pb-1 text-[12.5px] font-semibold ${
              pagina === p ? "border-primario-testo text-primario-testo" : "border-transparent text-zinc-500 hover:text-zinc-800 dark:text-zinc-400 dark:hover:text-zinc-200"
            }`}
          >
            {p}
            <span className="ml-1 font-mono text-[9.5px] font-normal opacity-50">⌃{i + 1}</span>
          </button>
        ))}
      </div>
      <div className="min-h-0 flex-1">
        <div className={pagina === "Elenco" ? "h-full" : "hidden"}>
          <GrigliaElenco
            nome={`Elenco ${nome}`}
            griglia={griglia}
            colonne={colonne}
            righe={righe}
            chiave={chiave}
            attivo={attivo && pagina === "Elenco"}
            selezionato={scelto}
            classeRiga={classeRiga}
            piede={piede}
            onScelta={(r, tutte) => {
              filtrate.current = tutte;
              const i = r ? tutte.indexOf(r) : -1;
              setPosizione(i >= 0 ? `${i + 1}/${tutte.length}` : null);
              if (r) setScelto(chiave(r));
            }}
            onApri={(r) => {
              onApri(chiave(r));
              onPagina("Scheda");
            }}
          />
        </div>
        {pagina === "Scheda" && <div className="h-full">{scheda}</div>}
      </div>
    </div>
  );
}

function Pulsante({ nome, tasto, disabled, title, onClick }: { nome: string; tasto?: string; disabled?: boolean; title?: string; onClick?: () => void }) {
  return (
    <button
      type="button"
      tabIndex={-1}
      disabled={disabled}
      title={title}
      onClick={onClick}
      className="flex h-7 items-center gap-1.5 rounded-md px-2 text-[12px] font-medium text-zinc-700 hover:bg-zinc-200/70 disabled:opacity-40 disabled:hover:bg-transparent dark:text-zinc-200 dark:hover:bg-zinc-700/60"
    >
      {nome}
      {tasto && <kbd className="tasto">{tasto}</kbd>}
    </button>
  );
}
