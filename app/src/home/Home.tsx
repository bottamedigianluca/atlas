// La Home della postazione: al posto della pagina di benvenuto di Arca, quello che serve al banco.
//
// - Da chiamare oggi: i clienti che in questo giorno della settimana ordinano quasi sempre e non
//   hanno ancora un DDT; "in ritardo" quando è passata la loro ora solita. `Invio` (o il pulsante)
//   apre un DDT già intestato al cliente.
// - Bacheca: post-it condivisi fra le postazioni, da trascinare dove servono.
// - DDT di oggi, numeri liberi da riempire, stato di Arca.
//
// Solo conteggi, orari e numeri di documento: nessun importo (direttiva §4.3, al banco nessun dato
// di fatturato).

import { useEffect, useMemo, useState } from "react";
import { api } from "../api/client";
import type { ClientiDelGiorno, DdtBreve, NumeriLiberi } from "../api/tipi";
import { BadgeSemaforo, StatoArcaBreve } from "../componenti/Badge";
import { data as fData, oggi } from "../griglia/numeri";
import { useSincronizzazione } from "../sincronizzazione/contesto";
import { Bacheca } from "./Bacheca";

/** Minuti di tolleranza dopo l'ora solita prima di dire "in ritardo". */
const TOLLERANZA = 30;

function minuti(ora: string): number {
  const [h = "0", m = "0"] = ora.split(":");
  return Number(h) * 60 + Number(m);
}

function useOra(): Date {
  const [ora, setOra] = useState(() => new Date());
  useEffect(() => {
    const t = setInterval(() => setOra(new Date()), 30_000);
    return () => clearInterval(t);
  }, []);
  return ora;
}

export function Home({ attivo, onNuovoPer, onNuovo, onApri, onElenco }: {
  attivo: boolean;
  onNuovoPer: (cliente: string) => void;
  onNuovo: () => void;
  onApri: (id: number) => void;
  onElenco: () => void;
}) {
  const ora = useOra();
  const giorno = oggi();
  const { ultimaNotifica } = useSincronizzazione();
  const [clienti, setClienti] = useState<ClientiDelGiorno | null>(null);
  const [ddtOggi, setDdtOggi] = useState<DdtBreve[]>([]);
  const [liberi, setLiberi] = useState<NumeriLiberi | null>(null);
  const [errore, setErrore] = useState<string | null>(null);

  // Si rilegge entrando nella Home e a ogni DDT salvato o importato.
  useEffect(() => {
    if (!attivo) return;
    let valida = true;
    Promise.all([api.clientiDelGiorno(giorno), api.elencoDdt({ dal: giorno, al: giorno, limite: 1000 }), api.liberi(Number(giorno.slice(0, 4)))])
      .then(([c, d, l]) => {
        if (!valida) return;
        setClienti(c);
        setDdtOggi(d);
        setLiberi(l);
        setErrore(null);
      })
      .catch((e: Error) => valida && setErrore(e.message));
    return () => {
      valida = false;
    };
  }, [attivo, giorno, ultimaNotifica]);

  const adesso = ora.getHours() * 60 + ora.getMinutes();
  const daChiamare = useMemo(() => clienti?.clienti.filter((c) => !c.servito) ?? [], [clienti]);
  const serviti = useMemo(() => clienti?.clienti.filter((c) => c.servito) ?? [], [clienti]);
  const saluto = ora.getHours() < 13 ? "Buongiorno" : ora.getHours() < 18 ? "Buon pomeriggio" : "Buonasera";
  const dataLunga = ora.toLocaleDateString("it-IT", { weekday: "long", day: "numeric", month: "long", year: "numeric" });

  return (
    <div className="h-full overflow-auto bg-zinc-100/70 dark:bg-zinc-950">
      <div className="mx-auto flex max-w-[1600px] flex-col gap-4 p-4">
        <header className="flex flex-wrap items-end gap-4">
          <div>
            <h1 className="text-[22px] font-semibold tracking-tight">{saluto}</h1>
            <p className="text-[13px] text-zinc-500 first-letter:uppercase">
              {dataLunga} · <span className="tabular-nums">{ora.toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit" })}</span>
            </p>
          </div>
          <div className="ml-auto flex gap-2">
            <button type="button" className="pulsante-primario h-9 px-4" onClick={onNuovo}>
              Nuovo DDT <kbd className="tasto ml-1 opacity-80">Ctrl+N</kbd>
            </button>
            <button type="button" className="pulsante h-9 px-4" onClick={onElenco}>
              Elenco documenti <kbd className="tasto ml-1">Ctrl+1</kbd>
            </button>
          </div>
        </header>
        {errore && <p className="text-sm text-rose-600">{errore}</p>}

        <div className="grid gap-4 xl:grid-cols-[minmax(360px,1.1fr)_minmax(420px,1.6fr)_minmax(280px,0.9fr)]">
          {/* Da chiamare oggi */}
          <Widget
            titolo="Da chiamare oggi"
            sottotitolo={
              clienti
                ? `Clienti che il ${clienti.giorno} ordinano quasi sempre (ultime ${clienti.settimane} settimane) e non hanno ancora un DDT`
                : "…"
            }
            conteggio={daChiamare.length}
          >
            <ul className="divide-y divide-zinc-100 dark:divide-zinc-800" aria-label="Clienti da chiamare">
              {clienti && daChiamare.length === 0 && (
                <li className="py-6 text-center text-[13px] text-zinc-500">Tutti i clienti abituali del {clienti.giorno} sono serviti.</li>
              )}
              {daChiamare.map((c) => {
                const ritardo = c.ora_tipica !== null && adesso > minuti(c.ora_tipica) + TOLLERANZA;
                return (
                  <li key={c.cliente} className="flex items-center gap-3 py-2">
                    <span className={`size-2.5 shrink-0 rounded-full ${ritardo ? "bg-amber-500" : "bg-primario"}`} aria-hidden />
                    <div className="min-w-0 flex-1">
                      <div className="flex items-baseline gap-2">
                        <span className="truncate text-[13.5px] font-semibold">{c.ragione_sociale}</span>
                        <span className="shrink-0 font-mono text-[11px] text-zinc-400">{c.cliente}</span>
                      </div>
                      <div className="flex flex-wrap gap-x-3 text-[12px] text-zinc-500">
                        {c.localita && <span>{c.localita}</span>}
                        <span>
                          {c.volte} {clienti?.giorno} su {c.su}
                        </span>
                        {c.ora_tipica && (
                          <span className={ritardo ? "font-semibold text-amber-700 dark:text-amber-400" : ""}>
                            di solito alle {c.ora_tipica}
                            {ritardo && " · in ritardo"}
                          </span>
                        )}
                      </div>
                    </div>
                    <button
                      type="button"
                      className="pulsante h-7 shrink-0 px-2.5 text-[12px] text-primario-testo"
                      onClick={() => onNuovoPer(c.cliente)}
                      aria-label={`Nuovo DDT per ${c.ragione_sociale}`}
                    >
                      Nuovo DDT
                    </button>
                  </li>
                );
              })}
            </ul>
            {serviti.length > 0 && (
              <details className="mt-2 text-[12px]">
                <summary className="cursor-pointer select-none text-zinc-500">Già serviti oggi ({serviti.length})</summary>
                <ul className="mt-1 space-y-0.5" aria-label="Clienti già serviti">
                  {serviti.map((c) => (
                    <li key={c.cliente} className="flex items-center gap-2 text-zinc-600 dark:text-zinc-400">
                      <span className="text-emerald-600">✓</span>
                      <span className="min-w-0 flex-1 truncate">{c.ragione_sociale}</span>
                      <button type="button" className="font-mono text-primario-testo hover:underline" onClick={() => c.servito && onApri(c.servito.id)}>
                        DDT {c.servito?.numero}
                      </button>
                    </li>
                  ))}
                </ul>
              </details>
            )}
          </Widget>

          {/* Bacheca dei post-it */}
          <Widget titolo="Bacheca" sottotitolo="Post-it per tutte le postazioni: trascinali dove vuoi" pieno>
            <Bacheca attivo={attivo} />
          </Widget>

          <div className="flex flex-col gap-4">
            <Widget titolo="DDT di oggi" conteggio={ddtOggi.length}>
              <ul className="space-y-0.5 text-[12.5px]" aria-label="DDT di oggi">
                {ddtOggi.length === 0 && <li className="py-2 text-zinc-500">Ancora nessun DDT oggi.</li>}
                {ddtOggi.slice(0, 8).map((d) => (
                  <li key={d.id}>
                    <button type="button" onClick={() => onApri(d.id)} className="flex w-full items-center gap-2 rounded-md px-1 py-0.5 text-left hover:bg-zinc-100 dark:hover:bg-zinc-800">
                      <span className="w-12 shrink-0 font-mono font-semibold tabular-nums">{d.numero}</span>
                      <span className="min-w-0 flex-1 truncate">{d.ragione_sociale}</span>
                      <span className="shrink-0 text-[11px]">
                        <StatoArcaBreve stato={d.arca} />
                      </span>
                    </button>
                  </li>
                ))}
              </ul>
              {ddtOggi.length > 8 && (
                <button type="button" className="mt-1 text-[12px] text-primario-testo hover:underline" onClick={onElenco}>
                  Tutti nell'elenco ({ddtOggi.length})
                </button>
              )}
            </Widget>

            <Widget titolo="Numeri liberi" sottotitolo="Buchi di numerazione da riempire (F3 sul numero)">
              {liberi && (
                <div className="space-y-1 text-[12.5px]">
                  <p>
                    Prossimo numero: <b className="font-mono tabular-nums">{liberi.prossimo ?? "—"}</b>
                  </p>
                  {liberi.liberi.length === 0 && <p className="text-zinc-500">Nessun buco.</p>}
                  <ul className="space-y-0.5" aria-label="Buchi di numerazione">
                    {liberi.liberi.slice(-5).reverse().map((l) => (
                      <li key={l.dal} className="flex gap-2">
                        <span className="w-24 font-mono tabular-nums">{l.dal === l.al ? l.dal : `${l.dal}–${l.al}`}</span>
                        <span className="text-zinc-500">
                          {l.data_dal ? `dal ${fData(l.data_dal)} ` : ""}al {fData(l.data_al)}
                        </span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </Widget>

            <WidgetArca />
          </div>
        </div>
      </div>
    </div>
  );
}

function WidgetArca() {
  const { stato, semaforo, collegato, aggiorna } = useSincronizzazione();
  return (
    <Widget titolo="Arca">
      <div className="flex flex-wrap items-center gap-2 text-[12.5px]">
        <BadgeSemaforo semaforo={semaforo} />
        {stato && <span className="text-zinc-500">{stato.coda.in_coda} in coda</span>}
        <button type="button" className="pulsante ml-auto h-7 px-2.5 text-[12px]" disabled={!collegato} onClick={() => void api.sincronizza().then(aggiorna)}>
          Sincronizza ora
        </button>
      </div>
    </Widget>
  );
}

function Widget({ titolo, sottotitolo, conteggio, pieno = false, children }: {
  titolo: string;
  sottotitolo?: string;
  conteggio?: number;
  /** Il contenuto occupa tutta l'altezza (la bacheca). */
  pieno?: boolean;
  children: React.ReactNode;
}) {
  return (
    <section
      aria-label={titolo}
      className={`flex flex-col rounded-2xl border border-zinc-200/80 bg-white p-4 shadow-sm dark:border-zinc-800 dark:bg-zinc-900 ${pieno ? "min-h-[520px]" : ""}`}
    >
      <header className="mb-2">
        <h2 className="flex items-center gap-2 text-[15px] font-semibold tracking-tight">
          {titolo}
          {conteggio !== undefined && (
            <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-[11.5px] font-semibold tabular-nums text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300">
              {conteggio}
            </span>
          )}
        </h2>
        {sottotitolo && <p className="text-[11.5px] text-zinc-500">{sottotitolo}</p>}
      </header>
      <div className={pieno ? "flex min-h-0 flex-1 flex-col" : ""}>{children}</div>
    </section>
  );
}
