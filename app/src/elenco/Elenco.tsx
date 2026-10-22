// Pagina Elenco della Gestione Documenti, come in Arca (`fedi_doc`, contenitore `elenco`): le 36
// colonne della griglia nell'ordine (`ColumnOrder`) e con le larghezze di Arca, righe da 17 px,
// più le due colonne della personalizzazione Bottamedi (destinazione e luogo destinazione) e lo
// stato della replica in Arca. Le intestazioni non sono nei sorgenti estratti: sono i nomi dei
// campi di `DOTes`.
//
// `Freccia Su/Giù` scorrono, `Invio` (o doppio clic) apre il documento nella pagina Generale.

import { useEffect, useMemo, useRef, useState } from "react";
import { api } from "../api/client";
import type { DdtBreve } from "../api/tipi";
import { BadgeArca } from "../componenti/Badge";
import { Intestazione } from "../griglia/Intestazione";
import { type Griglia, type Layout, carica, salva, visibili } from "../griglia/layout";
import { MenuColonne } from "../griglia/MenuColonne";
import { data as fData, importo } from "../griglia/numeri";
import { dataIso } from "../documento/Testata";
import { useSincronizzazione } from "../sincronizzazione/contesto";

interface ColonnaElenco {
  id: string;
  etichetta: string;
  larghezza: number;
  numerica?: boolean;
  suggerimento?: string;
  valore: (d: DdtBreve) => React.ReactNode;
}

const SPUNTA = "✓";

/**
 * Le larghezze di Arca sono misurate sul suo carattere (Tahoma 8 pt); il carattere di ATLAS è più
 * largo, quindi si scalano tutte dello stesso fattore: le proporzioni restano quelle di Arca.
 */
const SCALA = 1.2;

/** Colonne nell'ordine della griglia di Arca (Colbase1…36 per `ColumnOrder`). */
const COLONNE_ARCA: readonly ColonnaElenco[] = [
  { id: "Id_DoTes", etichetta: "Id", larghezza: 64, numerica: true, suggerimento: "Id_DoTes in Arca", valore: (d) => d.arca_id_testata ?? "" },
  { id: "EsAnno", etichetta: "Anno", larghezza: 30, valore: (d) => d.esercizio },
  { id: "TipoDocumento", etichetta: "Tipo", larghezza: 81, valore: () => "Bolla" },
  { id: "Cd_Do", etichetta: "Doc.", larghezza: 26, valore: (d) => d.tipo },
  { id: "NumeroDoc", etichetta: "Numero", larghezza: 60, numerica: true, valore: (d) => d.numero },
  { id: "DataDoc", etichetta: "Data", larghezza: 63, valore: (d) => fData(d.data) },
  { id: "NumeroDocRif", etichetta: "Num. rif.", larghezza: 60, valore: () => "" },
  { id: "DataDocRif", etichetta: "Data rif.", larghezza: 63, valore: () => "" },
  { id: "Cd_CF", etichetta: "Cliente", larghezza: 54, valore: (d) => d.cliente },
  { id: "CFDesc", etichetta: "Descrizione", larghezza: 200, valore: (d) => d.ragione_sociale },
  { id: "Cd_CFDest", etichetta: "Dest.", larghezza: 39, valore: (d) => d.destinazione ?? "" },
  { id: "Cd_CN", etichetta: "Sezionale", larghezza: 150, valore: () => "D00" },
  { id: "Cd_Agente_1", etichetta: "Agente", larghezza: 73, valore: (d) => d.agente ?? "" },
  { id: "Agente_1_Descrizione", etichetta: "Descrizione agente", larghezza: 150, valore: (d) => d.descrizione_agente ?? "" },
  { id: "Cd_Agente_2", etichetta: "Agente 2", larghezza: 73, valore: () => "" },
  { id: "Agente_2_Descrizione", etichetta: "Descrizione agente 2", larghezza: 150, valore: () => "" },
  { id: "Cd_VL", etichetta: "Valuta", larghezza: 35, valore: () => "EUR" },
  { id: "Cambio", etichetta: "Cambio", larghezza: 39, numerica: true, valore: () => "1.000000" },
  { id: "Cd_PG", etichetta: "Pag.", larghezza: 57, valore: (d) => d.pagamento ?? "" },
  { id: "Cd_LS_1", etichetta: "Listino", larghezza: 44, valore: (d) => d.listino_cliente ?? "" },
  // `DOTes.Cd_LS_2` = `DO.Cd_LS_1`: 0000001 su tutti i BO.
  { id: "Cd_LS_2", etichetta: "Listino 2", larghezza: 44, valore: () => "0000001" },
  { id: "Cd_DoSottocommessa", etichetta: "Sottocommessa", larghezza: 81, valore: () => "" },
  { id: "Righe", etichetta: "Righe", larghezza: 31, numerica: true, valore: (d) => d.righe },
  { id: "RigheEvadibili", etichetta: "Evad.", larghezza: 46, numerica: true, suggerimento: "Righe evadibili", valore: (d) => d.righe },
  { id: "AccontoV", etichetta: "Acconto", larghezza: 45, numerica: true, valore: () => "" },
  { id: "AbbuonoV", etichetta: "Abbuono", larghezza: 48, numerica: true, valore: () => "" },
  { id: "TotDocumentoV", etichetta: "Totale", larghezza: 89, numerica: true, suggerimento: "Totale Documento in Valuta", valore: (d) => importo(d.totale_documento) },
  { id: "TotaPagareV", etichetta: "A pagare", larghezza: 89, numerica: true, suggerimento: "Netto a pagare in valuta", valore: (d) => importo(d.netto_a_pagare) },
  { id: "Esecutivo", etichetta: "E", larghezza: 20, suggerimento: "Esecutivo", valore: () => SPUNTA },
  { id: "Prelevabile", etichetta: "P", larghezza: 20, suggerimento: "Prelevabile", valore: () => SPUNTA },
  { id: "Modificabile", etichetta: "M", larghezza: 20, suggerimento: "Modificabile", valore: () => SPUNTA },
  { id: "IvaSospesa", etichetta: "IS", larghezza: 21, suggerimento: "IVA ad esigibilità differita", valore: () => "" },
  { id: "OC_Scaduto", etichetta: "Scad.", larghezza: 44, valore: () => "" },
  { id: "StatoFte", etichetta: "Stato FTE", larghezza: 74, valore: () => "" },
  { id: "Attributi", etichetta: "Attributi", larghezza: 44, valore: () => "" },
  { id: "FactoringStatus", etichetta: "Factoring", larghezza: 110, valore: () => "" },
  // Personalizzazione Bottamedi (`elenco.Grid.Init`): destinazione e località della sede operativa.
  { id: "xColDescDest", etichetta: "Destinazione", larghezza: 100, valore: (d) => d.descrizione_destinazione ?? "" },
  { id: "xColLocDest", etichetta: "Luogo destinazione", larghezza: 100, valore: (d) => d.localita_destinazione ?? "" },
  // ATLAS: dove si trova il documento rispetto ad Arca.
  { id: "AtlasArca", etichetta: "Arca", larghezza: 84, suggerimento: "Stato della replica in Arca", valore: (d) => <BadgeArca stato={d.arca} /> },
];

export const COLONNE_ELENCO: readonly ColonnaElenco[] = COLONNE_ARCA.map((c) => ({ ...c, larghezza: Math.round(c.larghezza * SCALA) }));
export const GRIGLIA_ELENCO: Griglia = { colonne: COLONNE_ELENCO, chiave: "atlas.griglia.elenco.v2", fisse: ["NumeroDoc"] };
const PER_ID = new Map(COLONNE_ELENCO.map((c) => [c.id, c]));
const ALTEZZA = 17;

function giorniFa(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return fData(d.toLocaleDateString("sv-SE"));
}

export function Elenco({ attivo, onApri }: { attivo: boolean; onApri: (id: number) => void }) {
  const [dal, setDal] = useState(giorniFa(7));
  const [al, setAl] = useState("");
  const [cliente, setCliente] = useState("");
  const [documenti, setDocumenti] = useState<DdtBreve[]>([]);
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
      .elencoDdt({ dal: dataIso(dal) ?? undefined, al: dataIso(al) ?? undefined, cliente: cliente.trim() || undefined, limite: 1000 })
      .then((d) => {
        if (!valida) return;
        setDocumenti(d);
        setErrore(null);
        setScelta((s) => Math.min(s, Math.max(d.length - 1, 0)));
      })
      .catch((e: Error) => valida && setErrore(e.message));
    return () => {
      valida = false;
    };
  }, [attivo, dal, al, cliente, ultimaNotifica]);

  // All'arrivo sulla pagina il fuoco va alla griglia: si scorre subito con le frecce.
  useEffect(() => {
    if (attivo) griglia.current?.focus();
  }, [attivo]);

  const colonne = useMemo(() => visibili(layout).map((id) => PER_ID.get(id)).filter((c): c is ColonnaElenco => !!c), [layout]);
  const larghezza = colonne.reduce((s, c) => s + (layout.larghezze[c.id] ?? c.larghezza), 0);

  return (
    <div className="flex h-full min-h-0 flex-col">
      <section aria-label="Filtri" className="flex flex-wrap items-end gap-3 border-b border-zinc-200 px-3 py-1.5 text-[12px] dark:border-zinc-800">
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
        <Filtro etichetta="Cliente">
          <input
            className="campo h-[22px] w-28 font-mono text-[12px] uppercase"
            value={cliente}
            onChange={(e) => setCliente(e.target.value.toUpperCase())}
          />
        </Filtro>
        <span className="ml-auto text-zinc-500">{documenti.length} documenti</span>
      </section>
      {errore && <p className="px-3 py-1 text-sm text-rose-600">{errore}</p>}
      <div
        ref={griglia}
        tabIndex={0}
        role="grid"
        aria-label="Documenti"
        className="min-h-0 flex-1 overflow-auto bg-white outline-none dark:bg-zinc-950"
        onKeyDown={(e) => {
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
        <div style={{ width: larghezza }}>
          <Intestazione griglia={GRIGLIA_ELENCO} colonne={colonne} layout={layout} altezza={20} onLayout={setLayout} onMenu={(x, y) => setMenu({ x, y })} />
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
                    ? "bg-[#007aff] text-white shadow-[inset_4px_0_0_#00347a] dark:bg-[#0a84ff]"
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
        </div>
        {menu && (
          <MenuColonne griglia={GRIGLIA_ELENCO} layout={layout} x={menu.x} y={menu.y} onLayout={setLayout} onChiudi={() => setMenu(null)} />
        )}
      </div>
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
