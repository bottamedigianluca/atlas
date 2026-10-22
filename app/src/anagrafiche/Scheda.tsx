// La scheda di un'anagrafica in una pagina sola: a sinistra l'indice delle sezioni (un clic, o
// Alt+1…9, porta alla sezione), a destra le sezioni una sotto l'altra con i campi di Arca. Le
// tabelle collegate (destinazioni, unità di misura, prezzi) stanno nella loro sezione.
//
// In consultazione i campi sono in sola lettura: le anagrafiche si modificano ancora in Arca. Con
// `onCambia` (cliente nuovo) i campi si battono.

import { type ReactNode, useEffect, useRef } from "react";
import type { Tabelle } from "../api/tipi";
import { type CampoScheda, type Record_, type SezioneScheda, type Valore, descrizioneCampo, testoCampo } from "./campi";

export function Scheda({ nome, titolo, sottotitolo, sezioni, record, tabelle, aggiunte, avviso, onCambia }: {
  /** Nome della scheda per i lettori di schermo ("Scheda cliente"). */
  nome: string;
  titolo: ReactNode;
  sottotitolo?: ReactNode;
  sezioni: SezioneScheda[];
  record: Record_;
  tabelle: Tabelle | null;
  /** Contenuto in più in fondo a una sezione, per id di sezione. */
  aggiunte?: Partial<Record<string, ReactNode>>;
  /** Riga sopra le sezioni (stato, perché il salvataggio è spento…). */
  avviso?: ReactNode;
  onCambia?: (colonna: string, valore: Valore) => void;
}) {
  const corpo = useRef<HTMLDivElement>(null);
  const vai = (id: string) => corpo.current?.querySelector(`#sezione-${id}`)?.scrollIntoView({ block: "start" });

  useEffect(() => {
    const tasto = (e: KeyboardEvent) => {
      if (!e.altKey || e.ctrlKey || document.querySelector("[role=dialog]")) return;
      const sezione = sezioni[Number(e.key) - 1];
      if (sezione && /^[1-9]$/.test(e.key)) {
        e.preventDefault();
        vai(sezione.id);
      }
    };
    window.addEventListener("keydown", tasto);
    return () => window.removeEventListener("keydown", tasto);
  }, [sezioni]);

  useEffect(() => {
    corpo.current?.scrollTo({ top: 0 });
    if (onCambia) corpo.current?.querySelector<HTMLInputElement>("input:not([readonly])")?.focus();
  }, [record.Cd_CF, record.Cd_AR]); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div role="region" aria-label={nome} className="flex h-full min-h-0">
      <nav aria-label="Sezioni della scheda" className="w-48 shrink-0 overflow-auto border-r border-zinc-200 bg-zinc-50/70 py-3 dark:border-zinc-800 dark:bg-zinc-900/40">
        {sezioni.map((s, i) => (
          <button
            key={s.id}
            type="button"
            tabIndex={-1}
            onClick={() => vai(s.id)}
            className="flex w-full items-center gap-2 px-4 py-1 text-left text-[12.5px] text-zinc-700 hover:bg-primario-tenue dark:text-zinc-300"
          >
            {s.titolo}
            {i < 9 && <span className="ml-auto font-mono text-[9.5px] text-zinc-400">⌥{i + 1}</span>}
          </button>
        ))}
      </nav>
      <div ref={corpo} className="min-h-0 flex-1 overflow-auto px-5 pb-24 pt-3">
        <header className="mb-3">
          <h2 className="text-[17px] font-semibold text-zinc-900 dark:text-zinc-50">{titolo}</h2>
          {sottotitolo && <p className="text-[12px] text-zinc-500">{sottotitolo}</p>}
        </header>
        {avviso}
        <div className="flex flex-col gap-4">
          {sezioni.map((s) => (
            <section key={s.id} id={`sezione-${s.id}`} aria-label={s.titolo} className="scroll-mt-2">
              <h3 className="mb-1.5 border-b border-zinc-200 pb-0.5 text-[12px] font-bold uppercase tracking-wide text-primario-testo dark:border-zinc-800">
                {s.titolo}
              </h3>
              {s.nota && <p className="mb-1.5 text-[11.5px] text-zinc-500">{s.nota}</p>}
              {s.campi.some((c) => c.tipo !== "spunta") && (
                <div className="flex flex-wrap items-end gap-x-3 gap-y-2">
                  {s.campi.filter((c) => c.tipo !== "spunta").map((c) => (
                    <CampoAnagrafica key={c.colonna} campo={c} valore={record[c.colonna]} tabelle={tabelle} onCambia={onCambia} />
                  ))}
                </div>
              )}
              {s.campi.some((c) => c.tipo === "spunta") && (
                <div className="mt-2 flex flex-wrap gap-x-5 gap-y-1">
                  {s.campi.filter((c) => c.tipo === "spunta").map((c) => (
                    <label key={c.colonna} className="flex items-center gap-1.5 text-[12px]" title={c.suggerimento ?? c.colonna}>
                      <input
                        type="checkbox"
                        checked={record[c.colonna] === true || record[c.colonna] === 1}
                        readOnly={!onCambia}
                        tabIndex={onCambia ? 0 : -1}
                        onChange={(e) => onCambia?.(c.colonna, e.target.checked)}
                        className={`accent-primario ${onCambia ? "" : "pointer-events-none"}`}
                      />
                      {c.etichetta}
                    </label>
                  ))}
                </div>
              )}
              {aggiunte?.[s.id]}
            </section>
          ))}
        </div>
      </div>
    </div>
  );
}

const CAMPO =
  "h-[22px] rounded-md border px-1.5 text-[12px] outline-none transition-colors " +
  "border-zinc-300 bg-white focus:border-anello focus:ring-2 focus:ring-anello/25 " +
  "dark:border-zinc-700 dark:bg-zinc-900 " +
  "read-only:border-zinc-200 read-only:bg-zinc-50 read-only:text-zinc-700 read-only:focus:ring-0 " +
  "dark:read-only:border-zinc-800 dark:read-only:bg-zinc-900/60 dark:read-only:text-zinc-300";

function CampoAnagrafica({ campo, valore, tabelle, onCambia }: {
  campo: CampoScheda;
  valore: Valore | undefined;
  tabelle: Tabelle | null;
  onCambia?: (colonna: string, valore: Valore) => void;
}) {
  const testo = testoCampo(campo, valore);
  const descrizione = descrizioneCampo(campo, valore, tabelle);
  const modificabile = !!onCambia && campo.tipo !== "data";
  if (campo.tipo === "nota") {
    return (
      <textarea
        aria-label={campo.etichetta}
        value={testo}
        readOnly={!modificabile}
        onChange={(e) => onCambia?.(campo.colonna, e.target.value)}
        rows={4}
        className="w-full max-w-3xl rounded-md border border-zinc-300 bg-white px-1.5 py-1 text-[12px] outline-none focus:border-anello focus:ring-2 focus:ring-anello/25 read-only:border-zinc-200 read-only:bg-zinc-50 dark:border-zinc-700 dark:bg-zinc-900 dark:read-only:border-zinc-800 dark:read-only:bg-zinc-900/60"
      />
    );
  }
  const larghezza = campo.larghezza ?? 90;
  // L'etichetta intera anche sopra un campo stretto ("Tipo figura" su un campo di una lettera).
  return (
    <div className="flex items-end gap-1.5" title={campo.suggerimento ?? campo.colonna}>
      <label className="flex flex-col gap-0.5">
        <span className="whitespace-nowrap text-[11px] text-zinc-500 dark:text-zinc-400">{campo.etichetta}</span>
        <input
          value={testo}
          readOnly={!modificabile}
          tabIndex={modificabile ? 0 : -1}
          autoComplete="off"
          spellCheck={false}
          onChange={(e) => onCambia?.(campo.colonna, campo.tipo === "numero" ? e.target.value.replace(",", ".") : e.target.value)}
          style={{ width: larghezza }}
          className={`${CAMPO} ${campo.tipo === "numero" ? "cifre text-right" : ""}`}
        />
      </label>
      {descrizione && <span className="mb-[3px] max-w-56 truncate text-[12px] text-primario-testo">{descrizione}</span>}
    </div>
  );
}

/** Tabella semplice delle sezioni (destinazioni, unità di misura, prezzi). */
export function Tabella({ nome, intestazioni, righe, vuota }: {
  nome: string;
  intestazioni: { testo: string; numerica?: boolean }[];
  righe: ReactNode[][];
  vuota: string;
}) {
  return (
    <table aria-label={nome} className="mt-2 min-w-[32rem] border-collapse text-[12px]">
      <thead>
        <tr className="bg-primario-tenue/70 text-left text-[11px] text-zinc-600 dark:text-zinc-300">
          {intestazioni.map((i) => (
            <th key={i.testo} className={`border border-zinc-200 px-1.5 py-0.5 font-semibold dark:border-zinc-800 ${i.numerica ? "text-right" : ""}`}>
              {i.testo}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {righe.length === 0 && (
          <tr>
            <td colSpan={intestazioni.length} className="border border-zinc-200 px-1.5 py-1 text-zinc-500 dark:border-zinc-800">
              {vuota}
            </td>
          </tr>
        )}
        {righe.map((r, i) => (
          <tr key={i} className={i % 2 ? "bg-[#f9fafb] dark:bg-white/[0.025]" : ""}>
            {r.map((c, j) => (
              <td key={j} className={`border border-zinc-200 px-1.5 py-0.5 dark:border-zinc-800 ${intestazioni[j]?.numerica ? "cifre text-right" : ""}`}>
                {c}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

/**
 * Tutti i campi valorizzati di un oggetto di Arca che la scheda non mostra già (un contatto, una
 * destinazione): nessun dato importato resta nascosto.
 */
export function AltriCampi({ dati, escluse = [] }: { dati: Record<string, string | number | boolean | null> | null; escluse?: string[] }) {
  const voci = Object.entries(dati ?? {}).filter(([k, v]) => v !== null && v !== "" && v !== false && !escluse.includes(k));
  if (!voci.length) return null;
  return (
    <span className="text-[11px] text-zinc-500">
      {voci.map(([k, v], i) => (
        <span key={k}>
          {i > 0 && " · "}
          {k} <b className="font-medium text-zinc-700 dark:text-zinc-300">{v === true ? "✓" : String(v)}</b>
        </span>
      ))}
    </span>
  );
}
