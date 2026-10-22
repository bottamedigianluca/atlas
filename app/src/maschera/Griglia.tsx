// Griglia righe del DDT: le colonne di UserPref 1443 nel layout dell'operatore. Le celle battute
// sono campi di testo; il resto lo calcola il backend (quantità, totale, aliquota…) e si mostra.
// La tastiera la governa il riduttore (`righe.ts`); qui si traducono i tasti in azioni.

import { type KeyboardEvent, useEffect, useRef, useState } from "react";
import type { RigaCalcolata } from "../api/tipi";
import { ALTEZZA_RIGA, type CampoRiga, type Colonna, PER_ID } from "../griglia/colonne";
import { type Layout, alterna, layoutDiFabbrica, ridimensiona, sposta, visibili } from "../griglia/layout";
import { prezzo as fPrezzo, quantita as fQuantita, importo, mostra } from "../griglia/numeri";
import { type Azione, type RigaUI, type StatoRighe, numeriErrati } from "./righe";

interface Props {
  stato: StatoRighe;
  calcolate: readonly (RigaCalcolata | undefined)[];
  layout: Layout;
  attiva: boolean;
  onLayout: (layout: Layout) => void;
  onAzione: (azione: Azione) => void;
  /** F3 sulla cella: ricerca articolo o prezzi. */
  onF3: (riga: number, campo: CampoRiga) => void;
}

export function idCella(chiave: number, campo: CampoRiga): string {
  return `cella-${chiave}-${campo}`;
}

function visualizza(colonna: Colonna, indice: number, calcolata: RigaCalcolata | undefined): string {
  switch (colonna.calcolato) {
    case "riga":
      return String(indice + 1);
    case "totale":
      return importo(calcolata?.totale);
    case "aliquota":
      return calcolata?.aliquota ?? "";
    case "fattore":
      return calcolata?.fattore_um1 ? mostra(calcolata.fattore_um1, 0, 3) : "";
    case "quantita_evadibile":
      return fQuantita(calcolata?.quantita);
    case "conto":
      return calcolata?.conto_ricavo ?? "";
    default:
      return "";
  }
}

/** Quello che il backend mette nella cella quando l'operatore non batte nulla. */
function proposta(campo: CampoRiga, calcolata: RigaCalcolata | undefined): string {
  if (!calcolata || calcolata.vuota) return "";
  switch (campo) {
    case "descrizione":
      return calcolata.descrizione ?? "";
    case "unita_misura":
      return calcolata.unita_misura ?? "";
    case "quantita":
      return fQuantita(calcolata.quantita);
    case "prezzo":
      return fPrezzo(calcolata.prezzo);
    case "magazzino":
      return calcolata.magazzino ?? "";
    default:
      return "";
  }
}

export function Griglia({ stato, calcolate, layout, attiva, onLayout, onAzione, onF3 }: Props) {
  const colonne = visibili(layout).map((id) => PER_ID.get(id)).filter((c): c is Colonna => !!c);
  const campiVisibili = colonne.flatMap((c) => (c.campo ? [c.campo] : []));
  const larghezzaTotale = colonne.reduce((s, c) => s + (layout.larghezze[c.id] ?? c.larghezza), 0);
  const contenitore = useRef<HTMLDivElement>(null);

  // Il fuoco segue il cursore.
  const riga = stato.righe[stato.cursore.riga];
  useEffect(() => {
    if (!attiva || !riga) return;
    const campo = document.getElementById(idCella(riga.chiave, stato.cursore.campo)) as HTMLInputElement | null;
    if (campo && document.activeElement !== campo) {
      campo.focus({ preventScroll: false });
      campo.select();
    }
  }, [attiva, riga, stato.cursore.campo]);

  const tasto = (e: KeyboardEvent<HTMLInputElement>, indice: number, campo: CampoRiga) => {
    const input = e.currentTarget;
    const inizio = input.selectionStart === 0 && input.selectionEnd === 0;
    const fine = input.selectionStart === input.value.length && input.selectionEnd === input.value.length;
    let azione: Azione | null = null;
    switch (e.key) {
      case "Enter":
        azione = { tipo: "invio", visibili: campiVisibili };
        break;
      case "Escape":
        azione = { tipo: "esc" };
        break;
      case "ArrowDown":
        azione = { tipo: "giu" };
        break;
      case "ArrowUp":
        azione = { tipo: "su" };
        break;
      case "Tab":
        azione = { tipo: "tab", visibili: campiVisibili, indietro: e.shiftKey };
        break;
      case "ArrowLeft":
        if (inizio) azione = { tipo: "tab", visibili: campiVisibili, indietro: true };
        break;
      case "ArrowRight":
        if (fine) azione = { tipo: "tab", visibili: campiVisibili, indietro: false };
        break;
      case "Delete":
        if (e.ctrlKey) azione = { tipo: "elimina_riga" };
        break;
      case "F3":
        e.preventDefault();
        onF3(indice, campo);
        return;
    }
    if (azione) {
      e.preventDefault();
      e.stopPropagation();
      onAzione(azione);
    }
  };

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <div ref={contenitore} className="min-h-0 flex-1 overflow-auto" role="grid" aria-label="Righe del documento">
        <div style={{ width: larghezzaTotale }} className="relative">
          <Intestazione colonne={colonne} layout={layout} onLayout={onLayout} />
          {stato.righe.map((r, i) => (
            <RigaGriglia
              key={r.chiave}
              riga={r}
              indice={i}
              colonne={colonne}
              layout={layout}
              calcolata={calcolate[i]}
              cursore={stato.cursore.riga === i ? stato.cursore.campo : null}
              avviso={stato.avviso?.riga === i ? stato.avviso.codice : null}
              onAzione={onAzione}
              onTasto={tasto}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

function Intestazione({ colonne, layout, onLayout }: { colonne: Colonna[]; layout: Layout; onLayout: (l: Layout) => void }) {
  const [trascinata, setTrascinata] = useState<string | null>(null);
  const fabbrica = layoutDiFabbrica();

  const inizioRidimensiona = (e: React.PointerEvent<HTMLSpanElement>, colonna: Colonna) => {
    e.preventDefault();
    e.stopPropagation();
    const partenza = e.clientX;
    const larghezza = layout.larghezze[colonna.id] ?? colonna.larghezza;
    const maniglia = e.currentTarget;
    maniglia.setPointerCapture(e.pointerId);
    let attuale = layout;
    const muovi = (ev: PointerEvent) => {
      attuale = ridimensiona(layout, colonna.id, larghezza + ev.clientX - partenza);
      onLayout(attuale);
    };
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
      className="sticky top-0 z-10 flex border-b border-zinc-200 bg-zinc-100/90 backdrop-blur-sm dark:border-zinc-800 dark:bg-zinc-900/90"
    >
      {colonne.map((c) => (
        <div
          key={c.id}
          role="columnheader"
          draggable
          title={`${c.etichetta} (${c.id}) — trascina per spostare, bordo destro per allargare`}
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
          style={{ width: layout.larghezze[c.id] ?? c.larghezza }}
          className={`relative flex h-[26px] shrink-0 cursor-grab select-none items-center border-r border-zinc-200 px-1.5 text-[10.5px] font-semibold uppercase tracking-wide text-zinc-500 last:border-r-0 dark:border-zinc-800 dark:text-zinc-400 ${
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

interface PropsRiga {
  riga: RigaUI;
  indice: number;
  colonne: Colonna[];
  layout: Layout;
  calcolata: RigaCalcolata | undefined;
  cursore: CampoRiga | null;
  avviso: string | null;
  onAzione: (azione: Azione) => void;
  onTasto: (e: KeyboardEvent<HTMLInputElement>, indice: number, campo: CampoRiga) => void;
}

function RigaGriglia({ riga, indice, colonne, layout, calcolata, cursore, avviso, onAzione, onTasto }: PropsRiga) {
  const errati = numeriErrati(riga);
  const conErrori = !!calcolata?.errori.length;
  const titoloErrori = calcolata?.errori.join("\n");
  return (
    <div
      role="row"
      aria-rowindex={indice + 1}
      className={`flex border-b border-zinc-100 dark:border-zinc-900 ${
        cursore ? "bg-sky-50/70 dark:bg-sky-500/[0.06]" : indice % 2 ? "bg-zinc-50/60 dark:bg-white/[0.015]" : ""
      }`}
      style={{ height: ALTEZZA_RIGA }}
    >
      {colonne.map((c) => {
        const larghezza = layout.larghezze[c.id] ?? c.larghezza;
        const allineamento = c.numerica ? "text-right" : "";
        if (!c.campo) {
          const testo = visualizza(c, indice, calcolata);
          return (
            <div
              key={c.id}
              role="gridcell"
              style={{ width: larghezza }}
              title={c.calcolato === "riga" && conErrori ? titoloErrori : undefined}
              className={`flex shrink-0 items-center overflow-hidden border-r border-zinc-100 px-1.5 text-[12px] last:border-r-0 dark:border-zinc-900 ${
                c.numerica ? "cifre justify-end" : ""
              } ${c.calcolato === "totale" ? "font-semibold" : "text-zinc-500 dark:text-zinc-400"} ${
                c.calcolato === "riga" && conErrori ? "text-rose-600 dark:text-rose-400" : ""
              }`}
            >
              {c.calcolato === "riga" && (conErrori || calcolata?.avvisi.length) ? (
                <span
                  className={`mr-auto size-1.5 rounded-full ${conErrori ? "bg-rose-500" : "bg-amber-400"}`}
                  aria-label={conErrori ? "riga con errori" : "riga con avvisi"}
                />
              ) : null}
              <span className="truncate">{testo}</span>
            </div>
          );
        }
        const campo = c.campo;
        const modificato = campo === "prezzo" && calcolata?.prezzo_modificato;
        const errato = errati.includes(campo) || (campo === "articolo" && conErrori);
        const inAvviso = avviso && cursore === campo;
        return (
          <div key={c.id} role="gridcell" style={{ width: larghezza }} className="shrink-0 border-r border-zinc-100 last:border-r-0 dark:border-zinc-900">
            <input
              id={idCella(riga.chiave, campo)}
              data-campo={campo}
              data-riga={indice}
              aria-label={`${c.etichetta} riga ${indice + 1}`}
              aria-invalid={errato || undefined}
              title={campo === "articolo" && conErrori ? titoloErrori : undefined}
              autoComplete="off"
              spellCheck={false}
              value={riga[campo]}
              placeholder={proposta(campo, calcolata)}
              onFocus={() => {
                if (cursore !== campo) onAzione({ tipo: "vai", cursore: { riga: indice, campo } });
              }}
              onChange={(e) => {
                const valore = campo === "articolo" ? e.target.value.toUpperCase() : e.target.value;
                onAzione({ tipo: "scrivi", riga: indice, campo, valore });
              }}
              onKeyDown={(e) => onTasto(e, indice, campo)}
              className={`h-full w-full bg-transparent px-1.5 text-[12px] outline-none placeholder:text-zinc-400 focus:bg-white focus:shadow-[inset_0_0_0_2px_var(--color-accento)] dark:placeholder:text-zinc-500 dark:focus:bg-zinc-900 dark:focus:shadow-[inset_0_0_0_2px_var(--color-accento-scuro)] ${allineamento} ${
                c.numerica ? "cifre" : ""
              } ${modificato ? "bg-ambra-tenue dark:bg-ambra-tenue-scuro" : ""} ${
                errato ? "text-rose-600 underline decoration-rose-500 decoration-wavy dark:text-rose-400" : ""
              } ${inAvviso ? "bg-amber-100 dark:bg-amber-500/20" : ""} ${campo === "articolo" ? "font-semibold uppercase" : ""}`}
            />
          </div>
        );
      })}
    </div>
  );
}

/** Menu delle colonne: mostra/nascondi e ripristino del layout di fabbrica (direttiva §3.8). */
export function MenuColonne({ layout, onLayout, onRipristina, onChiudi }: {
  layout: Layout;
  onLayout: (l: Layout) => void;
  onRipristina: () => void;
  onChiudi: () => void;
}) {
  return (
    <div
      role="menu"
      aria-label="Colonne della griglia"
      onKeyDown={(e) => e.key === "Escape" && onChiudi()}
      className="absolute right-0 top-9 z-30 w-64 overflow-hidden rounded-xl border border-zinc-200/80 bg-white/85 shadow-xl backdrop-blur-md dark:border-zinc-700/70 dark:bg-zinc-900/85"
    >
      <div className="max-h-80 overflow-auto p-1.5">
        {layout.ordine.map((id) => {
          const c = PER_ID.get(id);
          if (!c) return null;
          const visibile = !layout.nascoste.includes(id);
          return (
            <label
              key={id}
              className="flex cursor-pointer items-center gap-2 rounded-md px-2 py-1 text-xs hover:bg-zinc-100 dark:hover:bg-zinc-800"
            >
              <input
                type="checkbox"
                checked={visibile}
                disabled={id === "ColCd_AR"}
                onChange={() => onLayout(alterna(layout, id))}
                className="accent-[var(--color-accento)]"
              />
              <span className="flex-1 truncate">{c.etichetta}</span>
              <span className="font-mono text-[10px] text-zinc-400">{c.id}</span>
            </label>
          );
        })}
      </div>
      <div className="border-t border-zinc-200/80 p-1.5 dark:border-zinc-800">
        <button type="button" className="pulsante w-full justify-center" onClick={onRipristina}>
          Ripristina layout di fabbrica
        </button>
      </div>
    </div>
  );
}
