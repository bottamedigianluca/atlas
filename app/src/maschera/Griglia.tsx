// Griglia righe del documento: le colonne di UserPref 1443 nel layout dell'operatore. Le celle
// battute sono campi di testo; il resto lo calcola il backend (quantità, totale, aliquota…).
// La tastiera la governa il riduttore (`righe.ts`); qui si traducono i tasti in azioni.
//
// Riga attiva in blu pieno con testo bianco e barra a sinistra (piano architetturale, griglia
// documenti); clic destro sulle intestazioni per mostrare o nascondere le colonne, come in Arca.

import { type KeyboardEvent, useEffect, useState } from "react";
import type { RigaCalcolata } from "../api/tipi";
import { ALTEZZA_RIGA, type CampoRiga, type Colonna, GRIGLIA_RIGHE, PER_ID } from "../griglia/colonne";
import { Intestazione } from "../griglia/Intestazione";
import { type Layout, visibili } from "../griglia/layout";
import { MenuColonne } from "../griglia/MenuColonne";
import { decimale, fattore, mostra, prezzo as fPrezzo, quantita as fQuantita, importo } from "../griglia/numeri";
import { type Azione, type RigaUI, type StatoRighe, numeriErrati } from "./righe";

interface Props {
  stato: StatoRighe;
  calcolate: readonly (RigaCalcolata | undefined)[];
  layout: Layout;
  attiva: boolean;
  /** Documento salvato in consultazione: le celle si leggono e basta. */
  solaLettura?: boolean;
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
      return importo(calcolata?.totale ?? "0");
    case "aliquota":
      return calcolata?.aliquota ?? "";
    case "fattore":
      return fattore(calcolata?.fattore_um1 ?? "0");
    case "quantita_evadibile":
      return fQuantita(calcolata?.quantita ?? "0");
    case "conto":
      return calcolata?.conto_ricavo ?? "";
    default:
      return "";
  }
}

/**
 * Quello che il backend mette nella cella quando l'operatore non batte nulla; nelle colonne
 * numeriche lo zero, come la riga vuota di Arca.
 */
function proposta(campo: CampoRiga, calcolata: RigaCalcolata | undefined): string {
  if (campo === "colli" || campo === "lordo" || campo === "tara") return "0.00";
  if (!calcolata || calcolata.vuota) {
    if (campo === "quantita") return "0.00";
    if (campo === "prezzo") return "0.000";
    return "";
  }
  switch (campo) {
    case "descrizione":
      return calcolata.descrizione ?? "";
    case "unita_misura":
      return calcolata.unita_misura ?? "";
    case "quantita":
      return fQuantita(calcolata.quantita ?? "0");
    case "prezzo":
      return fPrezzo(calcolata.prezzo ?? "0");
    case "magazzino":
      return calcolata.magazzino ?? "";
    default:
      return "";
  }
}

/** Decimali fissi delle celle numeriche battute, come le mostra Arca fuori dalla cella attiva. */
const DECIMALI: Partial<Record<CampoRiga, number>> = { colli: 2, lordo: 2, tara: 2, quantita: 2, prezzo: 3 };

/** Il valore battuto, nel formato di Arca quando il cursore non è sulla cella ("12.4" → "12.40"). */
function aVideo(campo: CampoRiga, testo: string, attiva: boolean): string {
  const decimali = DECIMALI[campo];
  if (attiva || decimali === undefined) return testo;
  const d = decimale(testo);
  return d ? mostra(d, decimali) : testo;
}

export function Griglia({ stato, calcolate, layout, attiva, solaLettura = false, onLayout, onAzione, onF3 }: Props) {
  const colonne = visibili(layout).map((id) => PER_ID.get(id)).filter((c): c is Colonna => !!c);
  const campiVisibili = colonne.flatMap((c) => (c.campo ? [c.campo] : []));
  const larghezzaTotale = colonne.reduce((s, c) => s + (layout.larghezze[c.id] ?? c.larghezza), 0);
  const [menu, setMenu] = useState<{ x: number; y: number } | null>(null);

  // Il fuoco segue il cursore.
  const riga = stato.righe[stato.cursore.riga];
  useEffect(() => {
    if (!attiva || !riga || solaLettura) return;
    const campo = document.getElementById(idCella(riga.chiave, stato.cursore.campo)) as HTMLInputElement | null;
    if (campo && document.activeElement !== campo) {
      campo.focus({ preventScroll: false });
      campo.select();
    }
  }, [attiva, riga, stato.cursore.campo, solaLettura]);

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
    <div className="min-h-0 flex-1 overflow-auto bg-white dark:bg-zinc-950" role="grid" aria-label="Righe del documento">
      <div style={{ width: larghezzaTotale }} className="relative flex min-h-full flex-col">
        <Intestazione
          griglia={GRIGLIA_RIGHE}
          colonne={colonne}
          layout={layout}
          onLayout={onLayout}
          onMenu={(x, y) => setMenu({ x, y })}
        />
        {stato.righe.map((r, i) => (
          <RigaGriglia
            key={r.chiave}
            riga={r}
            indice={i}
            colonne={colonne}
            layout={layout}
            calcolata={calcolate[i]}
            selezionata={stato.cursore.riga === i}
            cursore={stato.cursore.riga === i ? stato.cursore.campo : null}
            avviso={stato.avviso?.riga === i ? stato.avviso.codice : null}
            solaLettura={solaLettura}
            onAzione={onAzione}
            onTasto={tasto}
          />
        ))}
        {/* Sotto le righe le linee delle colonne continuano fino in fondo, come nella griglia di Arca. */}
        <div aria-hidden className="flex flex-1">
          {colonne.map((c) => (
            <div key={c.id} style={{ width: layout.larghezze[c.id] ?? c.larghezza }} className="shrink-0 border-r border-zinc-200/70 last:border-r-0 dark:border-zinc-800" />
          ))}
        </div>
      </div>
      {menu && (
        <MenuColonne
          griglia={GRIGLIA_RIGHE}
          layout={layout}
          x={menu.x}
          y={menu.y}
          onLayout={onLayout}
          onChiudi={() => setMenu(null)}
        />
      )}
    </div>
  );
}

interface PropsRiga {
  riga: RigaUI;
  indice: number;
  colonne: Colonna[];
  layout: Layout;
  calcolata: RigaCalcolata | undefined;
  selezionata: boolean;
  cursore: CampoRiga | null;
  avviso: string | null;
  solaLettura: boolean;
  onAzione: (azione: Azione) => void;
  onTasto: (e: KeyboardEvent<HTMLInputElement>, indice: number, campo: CampoRiga) => void;
}

function RigaGriglia({ riga, indice, colonne, layout, calcolata, selezionata, cursore, avviso, solaLettura, onAzione, onTasto }: PropsRiga) {
  const errati = numeriErrati(riga);
  const conErrori = !!calcolata?.errori.length;
  const titoloErrori = calcolata?.errori.join("\n");
  const sfondo = selezionata
    ? "bg-[#007aff] text-white shadow-[inset_4px_0_0_#00347a] dark:bg-[#0a84ff]"
    : indice % 2
      ? "bg-[#f9fafb] dark:bg-white/[0.025]"
      : "bg-white dark:bg-transparent";
  return (
    <div
      role="row"
      aria-rowindex={indice + 1}
      aria-selected={selezionata}
      onMouseDown={() => solaLettura && onAzione({ tipo: "vai", cursore: { riga: indice, campo: "articolo" } })}
      className={`flex border-b border-zinc-200/70 dark:border-zinc-800 ${sfondo}`}
      style={{ height: ALTEZZA_RIGA }}
    >
      {colonne.map((c) => {
        const larghezza = layout.larghezze[c.id] ?? c.larghezza;
        const separatore = selezionata ? "border-white/25" : "border-zinc-200/70 dark:border-zinc-800";
        if (!c.campo || solaLettura) {
          const testo = c.campo ? (c.campo === "descrizione" || c.campo === "unita_misura" || c.campo === "quantita" || c.campo === "prezzo" || c.campo === "magazzino"
            ? riga[c.campo] || proposta(c.campo, calcolata)
            : riga[c.campo]) : visualizza(c, indice, calcolata);
          return (
            <div
              key={c.id}
              role="gridcell"
              style={{ width: larghezza }}
              title={c.calcolato === "riga" && conErrori ? titoloErrori : undefined}
              className={`flex shrink-0 items-center overflow-hidden border-r last:border-r-0 ${separatore} ${
                c.numerica ? "cifre justify-end px-1 text-[11px]" : "px-1.5 text-[12px]"
              } ${c.calcolato === "totale" || c.campo === "articolo" ? "font-semibold" : ""} ${
                !selezionata && !c.campo && c.calcolato !== "totale" ? "text-zinc-500 dark:text-zinc-400" : ""
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
        const coloreCella = inAvviso
          ? "bg-amber-200 text-zinc-900"
          : modificato
            ? "bg-ambra-tenue text-zinc-900 dark:bg-ambra-tenue-scuro dark:text-amber-100"
            : selezionata
              ? "text-white placeholder:text-white/70"
              : "placeholder:text-zinc-400 dark:placeholder:text-zinc-500";
        return (
          <div key={c.id} role="gridcell" style={{ width: larghezza }} className={`shrink-0 border-r last:border-r-0 ${separatore}`}>
            <input
              id={idCella(riga.chiave, campo)}
              data-campo={campo}
              data-riga={indice}
              aria-label={`${c.etichetta} riga ${indice + 1}`}
              aria-invalid={errato || undefined}
              title={campo === "articolo" && conErrori ? titoloErrori : undefined}
              autoComplete="off"
              spellCheck={false}
              value={aVideo(campo, riga[campo], cursore === campo)}
              placeholder={proposta(campo, calcolata)}
              onFocus={() => {
                if (cursore !== campo) onAzione({ tipo: "vai", cursore: { riga: indice, campo } });
              }}
              onChange={(e) => {
                const valore = campo === "articolo" ? e.target.value.toUpperCase() : e.target.value;
                onAzione({ tipo: "scrivi", riga: indice, campo, valore });
              }}
              onKeyDown={(e) => onTasto(e, indice, campo)}
              className={`block h-full w-full bg-transparent outline-none focus:bg-white focus:text-zinc-900 focus:placeholder:text-zinc-400 focus:shadow-[inset_0_0_0_2px_#00347a] dark:focus:bg-zinc-900 dark:focus:text-zinc-100 ${
                c.numerica ? "cifre px-1 text-right text-[11px]" : "px-1.5 text-[12px]"
              } ${coloreCella} ${errato ? "underline decoration-rose-500 decoration-wavy" : ""} ${
                campo === "articolo" ? "font-semibold uppercase" : ""
              }`}
            />
          </div>
        );
      })}
    </div>
  );
}
