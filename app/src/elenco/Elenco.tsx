// Pagina Elenco della Gestione Documenti, come in Arca (`docs/screenshot_arca/`, elenco documenti
// della postazione Bottamedi): colonne nell'ordine e con le intestazioni che l'operatore vede in
// Arca, sotto le intestazioni la riga dei filtri per colonna, in fondo la legenda. Le colonne
// che non si vedono nella schermata seguono nell'ordine di `ColumnOrder` di `fedi_doc`, poi le due
// della personalizzazione Bottamedi (destinazione e luogo destinazione).
//
// Nella colonna Stato (in Arca lo stato della fattura elettronica, vuoto sui BO) ATLAS mostra dove
// si trova il documento rispetto ad Arca.
//
// `Freccia Su/Giù` scorrono, `Invio` (o doppio clic) apre il documento nella pagina Generale;
// `Freccia Giù` dalla riga dei filtri scende nella griglia.

import { useEffect, useMemo, useRef, useState } from "react";
import { api } from "../api/client";
import type { DdtBreve } from "../api/tipi";
import { LEGENDA_ARCA, StatoArcaBreve, TESTO_STATO_ARCA } from "../componenti/Badge";
import { Intestazione } from "../griglia/Intestazione";
import { type Griglia, type Layout, carica, salva, visibili } from "../griglia/layout";
import { MenuColonne } from "../griglia/MenuColonne";
import { data as fData, mostra } from "../griglia/numeri";
import { dataIso } from "../documento/Testata";
import { useSincronizzazione } from "../sincronizzazione/contesto";

interface ColonnaElenco {
  id: string;
  etichetta: string;
  larghezza: number;
  numerica?: boolean;
  suggerimento?: string;
  valore: (d: DdtBreve) => React.ReactNode;
  /** Testo su cui filtra la riga dei filtri, se `valore` non è già un testo. */
  testo?: (d: DdtBreve) => string;
}

const SPUNTA = "✓";

/** Importi dell'elenco come in Arca: tre decimali, migliaia separate da spazio ("1 360.060"). */
function totale(testo: string): string {
  const [intera = "", frazione = ""] = mostra(testo, 3).split(".");
  return `${intera.replace(/\B(?=(\d{3})+(?!\d))/g, " ")}.${frazione}`;
}

/**
 * Le larghezze sono quelle della schermata di Arca; il carattere di ATLAS è più largo, quindi si
 * scalano tutte dello stesso fattore: le proporzioni restano quelle di Arca.
 */
const SCALA = 1.3;

const COLONNE_ARCA: readonly ColonnaElenco[] = [
  { id: "Id_DoTes", etichetta: "Identificativo", larghezza: 52, numerica: true, suggerimento: "Id_DoTes in Arca", valore: (d) => d.arca_id_testata ?? "" },
  { id: "EsAnno", etichetta: "Esercizio", larghezza: 29, valore: (d) => d.esercizio },
  { id: "TipoDocumento", etichetta: "Tipo Documento", larghezza: 45, valore: () => "Bolla" },
  { id: "Cd_Do", etichetta: "Tipo", larghezza: 25, valore: (d) => d.tipo },
  { id: "NumeroDoc", etichetta: "Numero", larghezza: 54, numerica: true, valore: (d) => d.numero },
  { id: "DataDoc", etichetta: "Data", larghezza: 56, valore: (d) => fData(d.data) },
  { id: "NumeroDocRif", etichetta: "Num Rif", larghezza: 55, valore: () => "" },
  { id: "DataDocRif", etichetta: "Data Rif", larghezza: 74, valore: () => "" },
  { id: "CFDesc", etichetta: "Ragione Sociale", larghezza: 310, valore: (d) => d.ragione_sociale },
  { id: "Cd_CF", etichetta: "Cli/For", larghezza: 48, valore: (d) => d.cliente },
  { id: "Cd_CFDest", etichetta: "Destinaz.", larghezza: 35, valore: (d) => d.destinazione ?? "" },
  { id: "Cd_CN", etichetta: "Cod. Con.", larghezza: 134, valore: () => "D00 Bolle emesse" },
  { id: "TotDocumentoV", etichetta: "Tot. Doc.", larghezza: 79, numerica: true, suggerimento: "Totale documento", valore: (d) => totale(d.totale_documento) },
  {
    id: "StatoFte",
    etichetta: "Stato",
    larghezza: 132,
    suggerimento: "Dove si trova il documento rispetto ad Arca",
    valore: (d) => <StatoArcaBreve stato={d.arca} />,
    testo: (d) => TESTO_STATO_ARCA(d.arca),
  },
  { id: "Cd_Agente_1", etichetta: "Agente1", larghezza: 65, valore: (d) => d.agente ?? "" },
  { id: "Agente_1_Descrizione", etichetta: "Agente1 Rag. Soc.", larghezza: 134, valore: (d) => d.descrizione_agente ?? "" },
  { id: "Cd_Agente_2", etichetta: "Agente2", larghezza: 65, valore: () => "" },
  { id: "Agente_2_Descrizione", etichetta: "Agente2 Rag. Soc.", larghezza: 135, valore: () => "" },
  { id: "Cd_VL", etichetta: "Valuta", larghezza: 32, valore: () => "EUR" },
  { id: "Cambio", etichetta: "Cambio", larghezza: 33, numerica: true, valore: () => "1.00" },
  { id: "Cd_PG", etichetta: "Pag", larghezza: 52, valore: (d) => d.pagamento ?? "" },
  // Da qui le colonne fuori dalla schermata, nell'ordine di `ColumnOrder`.
  { id: "Cd_LS_1", etichetta: "Listino", larghezza: 44, valore: (d) => d.listino_cliente ?? "" },
  // `DOTes.Cd_LS_2` = `DO.Cd_LS_1`: 0000001 su tutti i BO.
  { id: "Cd_LS_2", etichetta: "Listino 2", larghezza: 44, valore: () => "0000001" },
  { id: "Cd_DoSottocommessa", etichetta: "Sottocommessa", larghezza: 81, valore: () => "" },
  { id: "Righe", etichetta: "Righe", larghezza: 31, numerica: true, valore: (d) => d.righe },
  { id: "RigheEvadibili", etichetta: "Evad.", larghezza: 46, numerica: true, suggerimento: "Righe evadibili", valore: (d) => d.righe },
  { id: "AccontoV", etichetta: "Acconto", larghezza: 45, numerica: true, valore: () => "" },
  { id: "AbbuonoV", etichetta: "Abbuono", larghezza: 48, numerica: true, valore: () => "" },
  { id: "TotaPagareV", etichetta: "A pagare", larghezza: 79, numerica: true, suggerimento: "Netto a pagare in valuta", valore: (d) => totale(d.netto_a_pagare) },
  { id: "Esecutivo", etichetta: "E", larghezza: 20, suggerimento: "Esecutivo", valore: () => SPUNTA },
  { id: "Prelevabile", etichetta: "P", larghezza: 20, suggerimento: "Prelevabile", valore: () => SPUNTA },
  { id: "Modificabile", etichetta: "M", larghezza: 20, suggerimento: "Modificabile", valore: () => SPUNTA },
  { id: "IvaSospesa", etichetta: "IS", larghezza: 21, suggerimento: "IVA ad esigibilità differita", valore: () => "" },
  { id: "OC_Scaduto", etichetta: "Scad.", larghezza: 44, valore: () => "" },
  { id: "Attributi", etichetta: "Attributi", larghezza: 44, valore: () => "" },
  { id: "FactoringStatus", etichetta: "Factoring", larghezza: 110, valore: () => "" },
  // Personalizzazione Bottamedi (`elenco.Grid.Init`): destinazione e località della sede operativa.
  { id: "xColDescDest", etichetta: "Destinazione", larghezza: 100, valore: (d) => d.descrizione_destinazione ?? "" },
  { id: "xColLocDest", etichetta: "Luogo destinazione", larghezza: 100, valore: (d) => d.localita_destinazione ?? "" },
];

function testoFiltro(c: ColonnaElenco, d: DdtBreve): string {
  if (c.testo) return c.testo(d);
  const v = c.valore(d);
  return typeof v === "string" || typeof v === "number" ? String(v) : "";
}

export const COLONNE_ELENCO: readonly ColonnaElenco[] = COLONNE_ARCA.map((c) => ({ ...c, larghezza: Math.round(c.larghezza * SCALA) }));
export const GRIGLIA_ELENCO: Griglia = { colonne: COLONNE_ELENCO, chiave: "atlas.griglia.elenco.v3", fisse: ["NumeroDoc"] };
const PER_ID = new Map(COLONNE_ELENCO.map((c) => [c.id, c]));
const ALTEZZA = 17;

function giorniFa(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return fData(d.toLocaleDateString("sv-SE"));
}

export function Elenco({ attivo, selezionato, onApri, onDocumenti, onSelezione }: {
  attivo: boolean;
  /** Documento aperto nella pagina Generale: l'elenco ci si posiziona, come in Arca. */
  selezionato?: number | null;
  onApri: (id: number) => void;
  /** Gli id nell'ordine dell'elenco (filtri compresi): servono alle frecce della barra strumenti. */
  onDocumenti?: (ids: number[]) => void;
  onSelezione?: (posizione: { id: number; indice: number; totale: number } | null) => void;
}) {
  const [dal, setDal] = useState(giorniFa(7));
  const [al, setAl] = useState("");
  const [caricati, setCaricati] = useState<DdtBreve[]>([]);
  const [filtri, setFiltri] = useState<Record<string, string>>({});
  const [errore, setErrore] = useState<string | null>(null);
  const [scelta, setScelta] = useState(0);
  const [layout, setLayout] = useState<Layout>(() => carica(GRIGLIA_ELENCO));
  const [menu, setMenu] = useState<{ x: number; y: number } | null>(null);
  const griglia = useRef<HTMLDivElement>(null);
  const { ultimaNotifica } = useSincronizzazione();

  useEffect(() => salva(GRIGLIA_ELENCO, layout), [layout]);

  useEffect(() => {
    if (!attivo) return;
    let valida = true;
    api
      .elencoDdt({ dal: dataIso(dal) ?? undefined, al: dataIso(al) ?? undefined, limite: 1000 })
      .then((d) => {
        if (!valida) return;
        setCaricati(d);
        setErrore(null);
      })
      .catch((e: Error) => valida && setErrore(e.message));
    return () => {
      valida = false;
    };
  }, [attivo, dal, al, ultimaNotifica]);

  const colonne = useMemo(() => visibili(layout).map((id) => PER_ID.get(id)).filter((c): c is ColonnaElenco => !!c), [layout]);
  const larghezza = colonne.reduce((s, c) => s + (layout.larghezze[c.id] ?? c.larghezza), 0);

  // Riga dei filtri: ogni colonna filtra sul testo che mostra (senza maiuscole/minuscole).
  const documenti = useMemo(() => {
    const attivi = Object.entries(filtri).filter(([, f]) => f.trim());
    if (!attivi.length) return caricati;
    return caricati.filter((d) =>
      attivi.every(([id, f]) => {
        const c = PER_ID.get(id);
        return !c || testoFiltro(c, d).toLowerCase().includes(f.trim().toLowerCase());
      }),
    );
  }, [caricati, filtri]);

  useEffect(() => {
    onDocumenti?.(documenti.map((x) => x.id));
    setScelta((s) => Math.min(s, Math.max(documenti.length - 1, 0)));
  }, [documenti]); // eslint-disable-line react-hooks/exhaustive-deps

  // Il documento aperto con le frecce della barra strumenti diventa la riga scelta.
  useEffect(() => {
    if (selezionato == null) return;
    const i = documenti.findIndex((d) => d.id === selezionato);
    if (i >= 0) setScelta(i);
  }, [selezionato, documenti]);

  useEffect(() => {
    const d = documenti[scelta];
    onSelezione?.(attivo && d ? { id: d.id, indice: scelta, totale: documenti.length } : null);
  }, [attivo, scelta, documenti]); // eslint-disable-line react-hooks/exhaustive-deps

  // All'arrivo sulla pagina il fuoco va alla griglia: si scorre subito con le frecce.
  useEffect(() => {
    if (attivo) griglia.current?.focus();
  }, [attivo]);

  return (
    <div className="flex h-full min-h-0 flex-col">
      <section aria-label="Filtri" className="flex flex-wrap items-end gap-3 border-b border-zinc-200 px-3 py-1 text-[12px] dark:border-zinc-800">
        <Filtro etichetta="Dal">
          <input className={`campo cifre h-[22px] w-28 text-[12px] ${dal && !dataIso(dal) ? "border-rose-500 text-rose-600" : ""}`} placeholder="GG-MM-AAAA" value={dal} onChange={(e) => setDal(e.target.value)} />
        </Filtro>
        <Filtro etichetta="Al">
          <input className={`campo cifre h-[22px] w-28 text-[12px] ${al && !dataIso(al) ? "border-rose-500 text-rose-600" : ""}`} placeholder="GG-MM-AAAA" value={al} onChange={(e) => setAl(e.target.value)} />
        </Filtro>
        <Filtro etichetta="Documento">
          <select className="campo h-[22px] w-44 py-0 text-[12px]" defaultValue="BO">
            <option value="BO">BO — BOLLA VENDITA</option>
            <option disabled>FT, FA, NC con il Task 7</option>
          </select>
        </Filtro>
      </section>
      {errore && <p className="px-3 py-1 text-sm text-rose-600">{errore}</p>}
      <div
        ref={griglia}
        tabIndex={0}
        role="grid"
        aria-label="Documenti"
        className="min-h-0 flex-1 overflow-auto bg-white outline-none dark:bg-zinc-950"
        onKeyDown={(e) => {
          if (e.target !== e.currentTarget) return;
          if (e.key === "ArrowDown") setScelta((s) => Math.min(s + 1, documenti.length - 1));
          else if (e.key === "ArrowUp") setScelta((s) => Math.max(s - 1, 0));
          else if (e.key === "PageDown") setScelta((s) => Math.min(s + 20, documenti.length - 1));
          else if (e.key === "PageUp") setScelta((s) => Math.max(s - 20, 0));
          else if (e.key === "Home") setScelta(0);
          else if (e.key === "End") setScelta(documenti.length - 1);
          else if (e.key === "Enter" && documenti[scelta]) onApri(documenti[scelta].id);
          else return;
          e.preventDefault();
        }}
      >
        <div style={{ width: larghezza }} className="flex min-h-full flex-col">
          <div className="sticky top-0 z-10">
            <Intestazione griglia={GRIGLIA_ELENCO} colonne={colonne} layout={layout} altezza={20} onLayout={setLayout} onMenu={(x, y) => setMenu({ x, y })} />
            {/* Riga dei filtri sotto le intestazioni, come in Arca. */}
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
                      griglia.current?.focus();
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
          {documenti.map((d, i) => {
            const selezionata = i === scelta;
            return (
              <div
                key={d.id}
                role="row"
                aria-selected={selezionata}
                ref={(el) => {
                  if (selezionata && el) el.scrollIntoView({ block: "nearest" });
                }}
                onMouseDown={() => setScelta(i)}
                onDoubleClick={() => onApri(d.id)}
                style={{ height: ALTEZZA }}
                className={`flex border-b border-zinc-100 text-[11px] dark:border-zinc-900 ${
                  selezionata
                    ? "bg-primario text-white shadow-[inset_4px_0_0_var(--atlas-primario-forte)]"
                    : i % 2
                      ? "bg-[#f9fafb] dark:bg-white/[0.025]"
                      : ""
                }`}
              >
                {colonne.map((c) => (
                  <div
                    key={c.id}
                    role="gridcell"
                    style={{ width: layout.larghezze[c.id] ?? c.larghezza }}
                    className={`flex shrink-0 items-center overflow-hidden whitespace-nowrap border-r px-1 ${
                      selezionata ? "border-white/20" : "border-zinc-100 dark:border-zinc-900"
                    } ${c.numerica ? "justify-end tabular-nums" : ""} ${c.id === "NumeroDoc" ? "font-semibold" : ""}`}
                  >
                    {c.valore(d)}
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
        {menu && (
          <MenuColonne griglia={GRIGLIA_ELENCO} layout={layout} x={menu.x} y={menu.y} onLayout={setLayout} onChiudi={() => setMenu(null)} />
        )}
      </div>
      {/* Legenda in fondo, come in Arca ("Evaso", "Iva esigibilità differita"): qui lo stato in Arca. */}
      <footer className="flex h-6 shrink-0 items-center gap-4 border-t border-zinc-200 px-3 text-[11px] text-zinc-600 dark:border-zinc-800 dark:text-zinc-400">
        {LEGENDA_ARCA.map((l) => (
          <span key={l.stato} className="flex items-center gap-1.5">
            <span className={`size-2.5 rounded-sm ${l.colore}`} />
            {l.testo}
          </span>
        ))}
        <span className="ml-auto tabular-nums">
          {documenti.length === caricati.length ? `${caricati.length} documenti` : `${documenti.length} di ${caricati.length} documenti`}
        </span>
      </footer>
    </div>
  );
}

function Filtro({ etichetta, children }: { etichetta: string; children: React.ReactNode }) {
  return (
    <label className="flex flex-col gap-0.5">
      <span className="text-[11px] text-zinc-500 dark:text-zinc-400">{etichetta}</span>
      {children}
    </label>
  );
}
