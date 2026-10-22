// Elenco documenti con filtri per data, tipo e cliente (Task 5). Oggi i documenti di ATLAS sono
// i DDT di vendita: fatture e note di credito arriveranno con il Task 7. `Freccia Su/Giù`
// scorrono, `Invio` apre la scheda.

import { useEffect, useState } from "react";
import { api } from "../api/client";
import type { DdtBreve, DdtScheda } from "../api/tipi";
import { BadgeArca } from "../componenti/Badge";
import { Modale } from "../componenti/Modale";
import { useSincronizzazione } from "../sincronizzazione/contesto";
import { data as fData, importo, mostra, prezzo as fPrezzo, quantita as fQuantita } from "../griglia/numeri";

function giorniFa(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString().slice(0, 10);
}

export function ElencoDocumenti({ attiva }: { attiva: boolean }) {
  const [dal, setDal] = useState(giorniFa(7));
  const [al, setAl] = useState("");
  const [cliente, setCliente] = useState("");
  const [tipo, setTipo] = useState("BO");
  const [documenti, setDocumenti] = useState<DdtBreve[]>([]);
  const [errore, setErrore] = useState<string | null>(null);
  const [scelta, setScelta] = useState(0);
  const [aperto, setAperto] = useState<number | null>(null);
  const { ultimaNotifica } = useSincronizzazione();

  useEffect(() => {
    if (!attiva) return;
    let valida = true;
    api
      .elencoDdt({ dal: dal || undefined, al: al || undefined, cliente: cliente.trim() || undefined, limite: 500 })
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
    // una notifica (nuovo DDT, replica, importazione) aggiorna l'elenco
  }, [attiva, dal, al, cliente, ultimaNotifica]);

  return (
    <div className="flex h-full min-h-0 flex-col">
      <section className="flex flex-wrap items-end gap-4 border-b border-zinc-200 px-5 py-3 dark:border-zinc-800/80">
        <Filtro etichetta="Dal">
          <input type="date" className="campo cifre w-36" value={dal} onChange={(e) => setDal(e.target.value)} />
        </Filtro>
        <Filtro etichetta="Al">
          <input type="date" className="campo cifre w-36" value={al} onChange={(e) => setAl(e.target.value)} />
        </Filtro>
        <Filtro etichetta="Tipo">
          <select className="campo w-44" value={tipo} onChange={(e) => setTipo(e.target.value)}>
            <option value="BO">DDT (bolle di vendita)</option>
            <option value="FT" disabled>
              Fatture (Task 7)
            </option>
            <option value="NC" disabled>
              Note di credito (Task 7)
            </option>
          </select>
        </Filtro>
        <Filtro etichetta="Cliente">
          <input
            className="campo w-32 font-mono uppercase"
            placeholder="codice"
            value={cliente}
            onChange={(e) => setCliente(e.target.value.toUpperCase())}
          />
        </Filtro>
        <span className="ml-auto text-xs text-zinc-500">{documenti.length} documenti</span>
      </section>
      {errore && <p className="px-5 py-2 text-sm text-rose-600">{errore}</p>}
      <div
        className="min-h-0 flex-1 overflow-auto outline-none"
        tabIndex={0}
        role="grid"
        aria-label="Documenti"
        onKeyDown={(e) => {
          if (e.key === "ArrowDown") setScelta((s) => Math.min(s + 1, documenti.length - 1));
          else if (e.key === "ArrowUp") setScelta((s) => Math.max(s - 1, 0));
          else if (e.key === "Enter" && documenti[scelta]) setAperto(documenti[scelta].id);
          else return;
          e.preventDefault();
        }}
      >
        <table className="w-full border-collapse text-[12.5px]">
          <thead className="sticky top-0 bg-zinc-100/90 text-[10.5px] uppercase tracking-wide text-zinc-500 backdrop-blur-sm dark:bg-zinc-900/90">
            <tr>
              <th className="px-3 py-1.5 text-left font-semibold">Tipo</th>
              <th className="px-3 py-1.5 text-right font-semibold">Numero</th>
              <th className="px-3 py-1.5 text-left font-semibold">Data</th>
              <th className="px-3 py-1.5 text-left font-semibold">Cliente</th>
              <th className="px-3 py-1.5 text-left font-semibold">Destinazione</th>
              <th className="px-3 py-1.5 text-right font-semibold">Imponibile</th>
              <th className="px-3 py-1.5 text-right font-semibold">Totale</th>
              <th className="px-3 py-1.5 text-left font-semibold">Arca</th>
            </tr>
          </thead>
          <tbody>
            {documenti.map((d, i) => (
              <tr
                key={d.id}
                aria-selected={i === scelta}
                onMouseDown={() => setScelta(i)}
                onDoubleClick={() => setAperto(d.id)}
                className={`cursor-default border-b border-zinc-100 dark:border-zinc-900 ${
                  i === scelta ? "bg-sky-500/12 dark:bg-sky-400/12" : ""
                }`}
              >
                <td className="px-3 py-1 font-mono text-xs">{d.tipo}</td>
                <td className="cifre px-3 py-1 text-right font-semibold">{d.numero}</td>
                <td className="cifre px-3 py-1">{fData(d.data)}</td>
                <td className="max-w-xs truncate px-3 py-1">
                  <span className="mr-2 font-mono text-xs text-zinc-500">{d.cliente}</span>
                  {d.ragione_sociale}
                </td>
                <td className="max-w-[14rem] truncate px-3 py-1 text-zinc-500">
                  {[d.destinazione, d.localita_destinazione].filter(Boolean).join(" — ")}
                </td>
                <td className="cifre px-3 py-1 text-right">{importo(d.totale_imponibile)}</td>
                <td className="cifre px-3 py-1 text-right font-medium">{importo(d.totale_documento)}</td>
                <td className="px-3 py-1">
                  <BadgeArca stato={d.arca} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {aperto !== null && <SchedaDdtModale id={aperto} onChiudi={() => setAperto(null)} />}
    </div>
  );
}

function Filtro({ etichetta, children }: { etichetta: string; children: React.ReactNode }) {
  return (
    <label className="flex flex-col gap-1">
      <span className="etichetta">{etichetta}</span>
      {children}
    </label>
  );
}

function SchedaDdtModale({ id, onChiudi }: { id: number; onChiudi: () => void }) {
  const [scheda, setScheda] = useState<DdtScheda | null>(null);
  const [errore, setErrore] = useState<string | null>(null);
  useEffect(() => {
    api.ddt(id).then(setScheda, (e: Error) => setErrore(e.message));
  }, [id]);
  const d = scheda?.documento;
  return (
    <Modale
      titolo={scheda ? `DDT ${scheda.numero}/${scheda.esercizio}` : "DDT"}
      sottotitolo={scheda ? `${scheda.ragione_sociale} — ${fData(d?.data)}` : undefined}
      larghezza="max-w-5xl"
      onChiudi={onChiudi}
    >
      {errore && <p className="px-5 py-3 text-sm text-rose-600">{errore}</p>}
      {scheda && d && (
        <div className="space-y-3 p-5 text-xs" tabIndex={0} data-fuoco-iniziale>
          <div className="flex flex-wrap gap-x-6 gap-y-1">
            <span>Cliente <b className="font-mono">{d.cliente}</b></span>
            <span>Destinazione <b>{d.destinazione ?? "—"}</b></span>
            <span>Pagamento <b>{d.pagamento ?? "—"}</b></span>
            <span>Listino <b>{d.listino_cliente ?? "—"}</b></span>
            <span>Registrato il <b className="cifre">{d.registrato_il.replace("T", " ")}</b></span>
            <span className="ml-auto"><BadgeArca stato={scheda.arca} /></span>
          </div>
          <table className="w-full border-collapse">
            <thead className="text-[10.5px] uppercase tracking-wide text-zinc-500">
              <tr className="border-b border-zinc-200 dark:border-zinc-800">
                <th className="py-1 text-left">#</th>
                <th className="py-1 text-left">Articolo</th>
                <th className="py-1 text-left">Descrizione</th>
                <th className="py-1 text-left">UM</th>
                <th className="py-1 text-right">Colli</th>
                <th className="py-1 text-right">Lordo</th>
                <th className="py-1 text-right">Tara</th>
                <th className="py-1 text-right">Netto</th>
                <th className="py-1 text-right">Prezzo</th>
                <th className="py-1 text-right">Totale</th>
                <th className="py-1 text-right">IVA</th>
              </tr>
            </thead>
            <tbody className="cifre">
              {scheda.righe.map((r, i) => (
                <tr key={i} className="border-b border-zinc-100 dark:border-zinc-900">
                  <td className="py-0.5">{i + 1}</td>
                  <td className="py-0.5 font-semibold">{r.articolo}</td>
                  <td className="max-w-xs truncate py-0.5 font-sans">{r.descrizione}</td>
                  <td className="py-0.5">{r.unita_misura}</td>
                  <td className="py-0.5 text-right">{mostra(r.pesata.colli, 0, 3)}</td>
                  <td className="py-0.5 text-right">{fQuantita(r.pesata.lordo)}</td>
                  <td className="py-0.5 text-right">{fQuantita(r.pesata.tara_per_collo)}</td>
                  <td className="py-0.5 text-right">{fQuantita(r.quantita)}</td>
                  <td className="py-0.5 text-right">{fPrezzo(r.prezzo_unitario)}</td>
                  <td className="py-0.5 text-right font-semibold">{importo(r.totale)}</td>
                  <td className="py-0.5 text-right">{r.aliquota}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="flex justify-end gap-6 text-right">
            <span>Imponibile <b className="cifre">{importo(scheda.castelletto.totale_imponibile)}</b></span>
            <span>Imposta <b className="cifre">{importo(scheda.castelletto.totale_imposta)}</b></span>
            <span className="text-base">Totale <b className="cifre">{importo(scheda.castelletto.totale_documento)}</b></span>
          </div>
          {scheda.eventi.length > 0 && (
            <div className="text-zinc-500">
              {scheda.eventi.map((e) => (
                <p key={e.id}>
                  Replica {e.operazione}: {e.replicato_il ? `scritto in Arca il ${e.replicato_il.replace("T", " ")}` : "in coda"}
                  {e.ultimo_errore && <span className="ml-2 text-rose-600">({e.tentativi} tentativi: {e.ultimo_errore})</span>}
                  {scheda.arca_id_testata && ` · Id_DoTes ${scheda.arca_id_testata}`}
                </p>
              ))}
            </div>
          )}
        </div>
      )}
    </Modale>
  );
}
