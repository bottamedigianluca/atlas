// Maschera di inserimento DDT, tutta da tastiera (direttiva §3.3-3.5).
//
// Testata: Cliente (F3 ricerca) → `Invio` porta alla prima riga; Destinazione, Data, Numero (F3
// numeri liberi; vuoto = numerazione automatica con Arca). Righe: vedi `righe.ts`. Ogni modifica
// ricalcola il documento sul backend (pesata, prezzi proposti, totali, castelletto): meno di un
// millisecondo, nessuna attesa percepibile. `F10` salva, `F12` salva e stampa.

import { useCallback, useEffect, useMemo, useReducer, useRef, useState } from "react";
import { api, ErroreApi } from "../api/client";
import type { Bozza, Calcolo, ClienteScheda, DdtCreato } from "../api/tipi";
import { type CampoRiga, PER_ID } from "../griglia/colonne";
import * as layouts from "../griglia/layout";
import { data as fData, importo, mostra, oggi, quantita as fQuantita } from "../griglia/numeri";
import { FinestraPrezzi, type RichiestaF3 } from "./FinestraPrezzi";
import { Griglia, MenuColonne } from "./Griglia";
import { NumeriLiberiF3, RicercaArticoli, RicercaClienti } from "./Ricerche";
import { inBozza, iniziale, numeriErrati, riduci, vuota } from "./righe";

type Modale =
  | { tipo: "prezzi"; riga: number; richiesta: RichiestaF3 }
  | { tipo: "articoli"; riga: number; iniziale: string }
  | { tipo: "clienti"; iniziale: string }
  | { tipo: "liberi"; esercizio: number }
  | null;

interface Esito {
  tipo: "salvato" | "errore";
  testo: string;
  dettagli?: string[];
  avviso?: string | null;
}

interface Testata {
  cliente: string;
  /** `undefined`: la destinazione predefinita del cliente; "" nessuna. */
  destinazione: string | undefined;
  data: string;
  numero: string;
}

const TESTATA_NUOVA = (): Testata => ({ cliente: "", destinazione: undefined, data: oggi(), numero: "" });

export function MascheraDdt({ attiva, onEsci }: { attiva: boolean; onEsci: () => void }) {
  const [testata, setTestata] = useState<Testata>(TESTATA_NUOVA);
  const [scheda, setScheda] = useState<ClienteScheda | null>(null);
  const [righe, invia] = useReducer(riduci, undefined, iniziale);
  const [calcolo, setCalcolo] = useState<Calcolo | null>(null);
  const [layout, setLayout] = useState(layouts.carica);
  const [menuColonne, setMenuColonne] = useState(false);
  const [modale, setModale] = useState<Modale>(null);
  const [esito, setEsito] = useState<Esito | null>(null);
  const [salvataggio, setSalvataggio] = useState(false);
  const [zona, setZona] = useState<"testata" | "griglia">("testata");
  const campoCliente = useRef<HTMLInputElement>(null);

  useEffect(() => layouts.salva(layout), [layout]);

  const numero = testata.numero.trim() ? Number(testata.numero.trim()) : undefined;
  const bozza: Bozza = useMemo(
    () => ({
      cliente: testata.cliente.trim(),
      destinazione: testata.destinazione,
      data: testata.data || undefined,
      numero: Number.isInteger(numero) && (numero ?? 0) > 0 ? numero : undefined,
      righe: inBozza(righe.righe),
    }),
    [testata, numero, righe.righe],
  );
  const chiaveBozza = JSON.stringify(bozza);

  // Totalizzazione in tempo reale: ogni bozza nuova annulla la richiesta precedente.
  useEffect(() => {
    if (!bozza.cliente && bozza.righe.every((r) => !r.articolo)) {
      setCalcolo(null);
      return;
    }
    const controllo = new AbortController();
    api.calcola(bozza, controllo.signal).then(setCalcolo, (e: Error) => {
      if (e.name !== "AbortError") setCalcolo(null);
    });
    return () => controllo.abort();
    // la bozza cambia identità a ogni render: conta il contenuto
  }, [chiaveBozza]);

  // La scheda del cliente per le destinazioni.
  const caricaCliente = useCallback(async (codice: string) => {
    if (!codice.trim()) {
      setScheda(null);
      return;
    }
    try {
      const s = await api.cliente(codice.trim());
      setScheda(s);
      setTestata((t) => ({ ...t, cliente: s.codice }));
    } catch {
      setScheda(null);
    }
  }, []);

  const vaiAllaGriglia = () => {
    setZona("griglia");
    if (righe.righe.length === 1 && vuota(righe.righe[0]!)) invia({ tipo: "vai", cursore: { riga: 0, campo: "articolo" } });
  };

  const nuovoDocumento = (mantieniData: boolean) => {
    setTestata((t) => ({ ...TESTATA_NUOVA(), data: mantieniData ? t.data : oggi() }));
    setScheda(null);
    setCalcolo(null);
    invia({ tipo: "nuovo" });
    setZona("testata");
    setTimeout(() => campoCliente.current?.focus(), 0);
  };

  const salva = async (stampa: boolean) => {
    if (salvataggio) return;
    const errati = righe.righe.flatMap((r, i) => numeriErrati(r).map((c) => `riga ${i + 1}: ${PER_ID.get(c)?.etichetta ?? c} non è un numero`));
    if (errati.length) {
      setEsito({ tipo: "errore", testo: "Numeri non validi", dettagli: errati });
      return;
    }
    setSalvataggio(true);
    try {
      const creato: DdtCreato = await api.crea(bozza);
      setEsito({
        tipo: "salvato",
        testo: `DDT ${creato.numero}/${creato.esercizio} del ${fData(creato.data)} salvato — totale € ${importo(creato.totale_documento)}${
          stampa ? " · stampa disponibile con il modulo stampe (Task 7)" : ""
        }`,
        avviso: creato.senza_arca ? `Numerato senza i documenti di Arca: ${creato.senza_arca}` : null,
      });
      nuovoDocumento(true);
    } catch (e) {
      const errore = e instanceof ErroreApi ? e : null;
      setEsito({
        tipo: "errore",
        testo: errore?.message ?? String(e),
        dettagli: errore?.dettagli,
      });
    } finally {
      setSalvataggio(false);
    }
  };

  // Tasti globali della maschera.
  useEffect(() => {
    if (!attiva || modale) return;
    const tasto = (e: KeyboardEvent) => {
      if (e.key === "F10" || e.key === "F12") {
        e.preventDefault();
        void salva(e.key === "F12");
      }
    };
    window.addEventListener("keydown", tasto);
    return () => window.removeEventListener("keydown", tasto);
  });

  const f3Riga = (riga: number, campo: CampoRiga) => {
    const r = righe.righe[riga];
    const c = calcolo?.righe[riga];
    if (!r) return;
    if (campo === "articolo") setModale({ tipo: "articoli", riga, iniziale: r.articolo });
    if (campo === "prezzo" && (r.articolo || c?.articolo)) {
      setModale({
        tipo: "prezzi",
        riga,
        richiesta: {
          articolo: r.articolo || c?.articolo || "",
          cliente: testata.cliente.trim(),
          data: testata.data,
          unita_misura: r.unita_misura || c?.unita_misura || undefined,
          quantita: c?.quantita ?? undefined,
        },
      });
    }
  };

  const testataCalcolata = calcolo?.testata;
  const errori = [
    ...(calcolo?.errori ?? []),
    ...(calcolo?.righe.flatMap((r, i) => r.errori.map((e) => `riga ${i + 1}: ${e}`)) ?? []),
  ];
  const destinazioni = scheda?.destinazioni.filter((d) => !d.obsoleto) ?? [];
  const nRighe = calcolo?.righe.filter((r) => !r.vuota).length ?? 0;

  return (
    <div className="flex h-full min-h-0 flex-col">
      {/* Testata */}
      <section className="flex flex-wrap items-end gap-x-5 gap-y-3 border-b border-zinc-200 px-5 py-3 dark:border-zinc-800/80">
        <div className="flex flex-col gap-1">
          <label htmlFor="cliente" className="etichetta">
            Cliente <kbd className="tasto">F3</kbd>
          </label>
          <input
            id="cliente"
            ref={campoCliente}
            className="campo w-28 font-mono font-semibold uppercase"
            value={testata.cliente}
            autoComplete="off"
            autoFocus
            onFocus={() => setZona("testata")}
            onChange={(e) => {
              setTestata((t) => ({ ...t, cliente: e.target.value.toUpperCase(), destinazione: undefined }));
              setScheda(null);
            }}
            onBlur={() => void caricaCliente(testata.cliente)}
            onKeyDown={(e) => {
              if (e.key === "F3") {
                e.preventDefault();
                setModale({ tipo: "clienti", iniziale: testata.cliente });
              } else if (e.key === "Enter") {
                e.preventDefault();
                void caricaCliente(testata.cliente);
                vaiAllaGriglia();
              } else if (e.key === "Escape" && righe.righe.every(vuota) && !testata.cliente) onEsci();
            }}
          />
        </div>
        <div className="flex min-w-56 max-w-sm flex-1 flex-col gap-1">
          <span className="etichetta">Ragione sociale</span>
          <span className="truncate pb-1.5 text-sm font-semibold" data-prova="ragione-sociale">
            {testataCalcolata?.ragione_sociale ?? scheda?.ragione_sociale ?? <span className="text-zinc-400">—</span>}
          </span>
        </div>
        <div className="flex flex-col gap-1">
          <label htmlFor="destinazione" className="etichetta">
            Destinazione
          </label>
          <select
            id="destinazione"
            className="campo w-56"
            value={testata.destinazione ?? "__predefinita"}
            onFocus={() => setZona("testata")}
            onChange={(e) => setTestata((t) => ({ ...t, destinazione: e.target.value === "__predefinita" ? undefined : e.target.value }))}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                e.preventDefault();
                vaiAllaGriglia();
              }
            }}
          >
            <option value="__predefinita">
              {testataCalcolata?.destinazione ? `Predefinita (${testataCalcolata.destinazione})` : "Predefinita del cliente"}
            </option>
            <option value="">Nessuna destinazione</option>
            {destinazioni.map((d) => (
              <option key={d.codice} value={d.codice}>
                {d.codice} — {d.descrizione}
                {d.localita ? `, ${d.localita}` : ""}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-1">
          <label htmlFor="data" className="etichetta">
            Data documento
          </label>
          <input
            id="data"
            type="date"
            className="campo cifre w-36"
            value={testata.data}
            onFocus={() => setZona("testata")}
            onChange={(e) => setTestata((t) => ({ ...t, data: e.target.value }))}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                e.preventDefault();
                vaiAllaGriglia();
              }
            }}
          />
        </div>
        <div className="flex flex-col gap-1">
          <label htmlFor="numero" className="etichetta">
            Numero <kbd className="tasto">F3</kbd>
          </label>
          <input
            id="numero"
            inputMode="numeric"
            className="campo cifre w-24 text-right"
            placeholder="auto"
            value={testata.numero}
            onFocus={() => setZona("testata")}
            onChange={(e) => setTestata((t) => ({ ...t, numero: e.target.value.replace(/\D/g, "") }))}
            onKeyDown={(e) => {
              if (e.key === "F3") {
                e.preventDefault();
                setModale({ tipo: "liberi", esercizio: Number((testata.data || oggi()).slice(0, 4)) });
              } else if (e.key === "Enter") {
                e.preventDefault();
                vaiAllaGriglia();
              }
            }}
          />
        </div>
        <div className="flex flex-col gap-1 text-xs text-zinc-500 dark:text-zinc-400">
          <span>
            Pagamento <b className="text-zinc-700 dark:text-zinc-200">{scheda?.descrizione_pagamento ?? testataCalcolata?.pagamento ?? "—"}</b>
          </span>
          <span>
            Listino{" "}
            <b className="text-zinc-700 dark:text-zinc-200">
              {testataCalcolata ? (testataCalcolata.listino ?? `nessuno (prezzi dal ${testataCalcolata.listino_prezzi})`) : "—"}
            </b>
            {testataCalcolata?.scissione_pagamenti && (
              <span className="ml-2 rounded bg-violet-500/15 px-1.5 py-0.5 font-semibold text-violet-700 dark:text-violet-300">
                Split payment
              </span>
            )}
          </span>
        </div>
        <div className="relative ml-auto flex gap-2">
          <button type="button" className="pulsante" onClick={() => setMenuColonne((m) => !m)} aria-expanded={menuColonne}>
            Colonne
          </button>
          {menuColonne && (
            <MenuColonne
              layout={layout}
              onLayout={setLayout}
              onRipristina={() => {
                setLayout(layouts.ripristina());
                setMenuColonne(false);
              }}
              onChiudi={() => setMenuColonne(false)}
            />
          )}
          <button type="button" className="pulsante-primario" disabled={salvataggio} onClick={() => void salva(false)}>
            Salva <kbd className="rounded bg-white/20 px-1 font-mono text-[10px]">F10</kbd>
          </button>
        </div>
      </section>

      {/* Righe */}
      <Griglia
        stato={righe}
        calcolate={calcolo?.righe ?? []}
        layout={layout}
        attiva={attiva && zona === "griglia" && !modale}
        onLayout={setLayout}
        onAzione={(a) => {
          setZona("griglia");
          invia(a);
        }}
        onF3={f3Riga}
      />

      {/* Avviso del guardrail: nessun popup, solo una barra. */}
      {righe.avviso && (
        <div
          role="alert"
          className="flex items-center gap-3 border-t border-amber-300/60 bg-amber-50 px-5 py-2 text-sm text-amber-900 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-200"
        >
          <span className="font-semibold">Riga {righe.avviso.riga + 1}</span>
          <span className="flex-1">{righe.avviso.messaggio}</span>
          <span className="text-xs">
            <kbd className="tasto">Invio</kbd> conferma · <kbd className="tasto">Esc</kbd> correggi
          </span>
        </div>
      )}

      {/* Piede: totali e castelletto */}
      <footer className="grid grid-cols-[1fr_auto] gap-6 border-t border-zinc-200 bg-white/60 px-5 py-3 dark:border-zinc-800/80 dark:bg-zinc-900/40">
        <div className="min-w-0 space-y-1.5 text-xs">
          {esito && (
            <p
              role="status"
              className={esito.tipo === "salvato" ? "font-medium text-emerald-700 dark:text-emerald-400" : "font-medium text-rose-600 dark:text-rose-400"}
            >
              {esito.testo}
              {esito.avviso && <span className="ml-2 text-amber-700 dark:text-amber-300">{esito.avviso}</span>}
            </p>
          )}
          {esito?.dettagli?.map((d) => (
            <p key={d} className="text-rose-600 dark:text-rose-400">
              {d}
            </p>
          ))}
          {errori.length > 0 && esito?.tipo !== "errore" && (
            <ul className="space-y-0.5 text-rose-600 dark:text-rose-400">
              {errori.slice(0, 4).map((e) => (
                <li key={e}>{e}</li>
              ))}
            </ul>
          )}
          <p className="flex flex-wrap gap-x-4 gap-y-1 text-zinc-500 dark:text-zinc-400">
            <span><kbd className="tasto">Invio</kbd> avanti</span>
            <span><kbd className="tasto">↓</kbd> riga sotto / nuova</span>
            <span><kbd className="tasto">F3</kbd> cerca · prezzi · numeri</span>
            <span><kbd className="tasto">F10</kbd> salva</span>
            <span><kbd className="tasto">F12</kbd> salva e stampa</span>
            <span><kbd className="tasto">Esc</kbd> annulla</span>
            <span><kbd className="tasto">Ctrl</kbd>+<kbd className="tasto">Canc</kbd> elimina riga</span>
          </p>
        </div>
        <div className="flex items-end gap-6">
          {calcolo && calcolo.castelletto.righe.length > 0 && (
            <table className="text-[11px] text-zinc-500 dark:text-zinc-400" aria-label="Castelletto IVA">
              <thead>
                <tr>
                  <th className="pr-3 text-left font-medium">IVA</th>
                  <th className="pr-3 text-right font-medium">Imponibile</th>
                  <th className="text-right font-medium">Imposta</th>
                </tr>
              </thead>
              <tbody className="cifre">
                {calcolo.castelletto.righe.map((r) => (
                  <tr key={r.aliquota}>
                    <td className="pr-3">
                      {r.aliquota} <span className="text-zinc-400">({mostra(r.percentuale, 0, 2)}%)</span>
                    </td>
                    <td className="pr-3 text-right">{importo(r.imponibile)}</td>
                    <td className="text-right">{importo(r.imposta)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          <Totale nome="Righe" valore={String(nRighe)} />
          <Totale nome="Netto merce kg/pz" valore={fQuantita(sommaQuantita(calcolo))} />
          <Totale nome="Imponibile" valore={importo(calcolo?.castelletto.totale_imponibile ?? "0")} />
          <Totale nome="Imposta" valore={importo(calcolo?.castelletto.totale_imposta ?? "0")} />
          <Totale nome="Totale documento" valore={importo(calcolo?.castelletto.totale_documento ?? "0")} grande />
          {testataCalcolata?.scissione_pagamenti && <Totale nome="Netto a pagare" valore={importo(calcolo?.netto_a_pagare)} />}
        </div>
      </footer>

      {modale?.tipo === "prezzi" && (
        <FinestraPrezzi
          richiesta={modale.richiesta}
          onChiudi={() => setModale(null)}
          onRiporta={(p) => {
            invia({ tipo: "scrivi", riga: modale.riga, campo: "prezzo", valore: p.replace(".", ",") });
            setModale(null);
          }}
        />
      )}
      {modale?.tipo === "articoli" && (
        <RicercaArticoli
          iniziale={modale.iniziale}
          onChiudi={() => setModale(null)}
          onScegli={(a) => {
            invia({ tipo: "scrivi", riga: modale.riga, campo: "articolo", valore: a.codice });
            setModale(null);
          }}
        />
      )}
      {modale?.tipo === "clienti" && (
        <RicercaClienti
          iniziale={modale.iniziale}
          onChiudi={() => setModale(null)}
          onScegli={(c) => {
            setTestata((t) => ({ ...t, cliente: c.codice, destinazione: undefined }));
            void caricaCliente(c.codice);
            setModale(null);
            setTimeout(vaiAllaGriglia, 0);
          }}
        />
      )}
      {modale?.tipo === "liberi" && (
        <NumeriLiberiF3
          esercizio={modale.esercizio}
          onChiudi={() => setModale(null)}
          onScegli={(n) => {
            setTestata((t) => ({ ...t, numero: n === null ? "" : String(n) }));
            setModale(null);
          }}
        />
      )}
    </div>
  );
}

function sommaQuantita(calcolo: Calcolo | null): string {
  if (!calcolo) return "0";
  // Solo per il colpo d'occhio dell'operatore: gli importi restano quelli del backend.
  const somma = calcolo.righe.reduce((s, r) => s + (r.quantita ? Number(r.quantita) : 0), 0);
  return somma.toFixed(3);
}

function Totale({ nome, valore, grande = false }: { nome: string; valore: string; grande?: boolean }) {
  return (
    <div className="text-right">
      <div className="text-[10px] uppercase tracking-wide text-zinc-500 dark:text-zinc-400">{nome}</div>
      <div className={`cifre ${grande ? "text-2xl font-semibold tracking-tight" : "text-sm font-medium"}`} data-prova={nome}>
        {valore}
      </div>
    </div>
  );
}
