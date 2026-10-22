// Il DDT in battitura nella pagina Generale: testata e schede come in Arca, righe tutte da
// tastiera (regole in `maschera/righe.ts`). Ogni modifica ricalcola il documento sul backend
// (pesata, prezzo proposto, totali, castelletto). Salvataggio, nuovo documento e annulla li
// chiede la barra degli strumenti della finestra (`F10`, `F12`, `Ctrl+N`, `Esc`).

import { forwardRef, type KeyboardEvent, useCallback, useEffect, useImperativeHandle, useMemo, useReducer, useState } from "react";
import { api, ErroreApi } from "../api/client";
import type { Bozza, Calcolo, ClienteScheda } from "../api/tipi";
import { type CampoRiga, GRIGLIA_RIGHE, PER_ID } from "../griglia/colonne";
import * as layouts from "../griglia/layout";
import { data as fData, importo, oggi, prezzo as fPrezzo } from "../griglia/numeri";

/** Oggi come lo batte l'operatore: GG-MM-AAAA. */
const oggiTesto = () => fData(oggi());
import { FinestraPrezzi, type RichiestaF3 } from "../maschera/FinestraPrezzi";
import { Griglia } from "../maschera/Griglia";
import { NumeriLiberiF3, RicercaArticoli, RicercaClienti, RicercaDestinazioni } from "../maschera/Ricerche";
import { inBozza, iniziale, numeriErrati, riduci, vuota } from "../maschera/righe";
import { BarraSchede, SCHEDE, type Scheda, SchedaEvasioni, SchedaInfo, SchedaPiede, SchedaStampe, SchedaTesta, SchedaTotali } from "./Schede";
import { type CampiTestata, Testata, dataIso } from "./Testata";
import { vistaNuovo } from "./vista";

type Modale =
  | { tipo: "prezzi"; riga: number; richiesta: RichiestaF3 }
  | { tipo: "articoli"; riga: number; iniziale: string }
  | { tipo: "clienti"; iniziale: string }
  | { tipo: "destinazioni" }
  | { tipo: "liberi"; esercizio: number }
  | null;

export interface Esito {
  tipo: "salvato" | "errore" | "avviso";
  testo: string;
  dettagli?: string[];
}

export interface ComandiDocumento {
  salva: (stampa: boolean) => void;
  nuovo: () => void;
  /** Annulla il documento in battitura: la prima volta avvisa, la seconda svuota. */
  annulla: () => void;
}

interface Props {
  attivo: boolean;
  onEsito: (esito: Esito | null) => void;
  onTotali: (totali: { righe: number; imponibile: string; totale: string } | null) => void;
}

const TESTATA_NUOVA = (data = oggiTesto()): CampiTestata => ({ numero: "", data, cliente: "", destinazione: "" });

export const NuovoDocumento = forwardRef<ComandiDocumento, Props>(function NuovoDocumento({ attivo, onEsito, onTotali }, ref) {
  const [campi, setCampi] = useState<CampiTestata>(TESTATA_NUOVA);
  const [scheda, setScheda] = useState<ClienteScheda | null>(null);
  const [righe, invia] = useReducer(riduci, undefined, iniziale);
  const [calcolo, setCalcolo] = useState<Calcolo | null>(null);
  const [layout, setLayout] = useState(() => layouts.carica(GRIGLIA_RIGHE));
  const [schedaAttiva, setSchedaAttiva] = useState<Scheda>("Righe");
  const [modale, setModale] = useState<Modale>(null);
  const [salvataggio, setSalvataggio] = useState(false);
  const [zona, setZona] = useState<"testata" | "griglia">("testata");
  const [annullaArmato, setAnnullaArmato] = useState(false);

  useEffect(() => layouts.salva(GRIGLIA_RIGHE, layout), [layout]);

  const numero = campi.numero.trim() ? Number(campi.numero.trim()) : undefined;
  const iso = dataIso(campi.data) ?? oggi();
  const bozza: Bozza = useMemo(
    () => ({
      cliente: campi.cliente.trim(),
      // Il codice battuto; vuoto = nessuna destinazione (la predefinita la propone la scheda cliente).
      destinazione: campi.destinazione.trim(),
      data: iso,
      numero: Number.isInteger(numero) && (numero ?? 0) > 0 ? numero : undefined,
      righe: inBozza(righe.righe),
    }),
    [campi, numero, righe.righe],
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
  }, [chiaveBozza]); // eslint-disable-line react-hooks/exhaustive-deps

  const nRighe = calcolo?.righe.filter((r) => !r.vuota).length ?? 0;
  useEffect(() => {
    onTotali(
      calcolo ? { righe: nRighe, imponibile: calcolo.castelletto.totale_imponibile, totale: calcolo.castelletto.totale_documento } : null,
    );
  }, [calcolo, nRighe, onTotali]);

  // Scheda del cliente: destinazioni, pagamento, IBAN… La destinazione predefinita si propone
  // come in Arca alla scelta del cliente.
  const caricaCliente = useCallback(async (codice: string): Promise<ClienteScheda | null> => {
    if (!codice.trim()) {
      setScheda(null);
      return null;
    }
    try {
      const s = await api.cliente(codice.trim());
      setScheda(s);
      const predefinita = s.destinazioni.find((d) => d.predefinita && !d.obsoleto)?.codice ?? "";
      setCampi((c) => ({ ...c, cliente: s.codice, destinazione: c.cliente === s.codice && c.destinazione ? c.destinazione : predefinita }));
      return s;
    } catch {
      setScheda(null);
      return null;
    }
  }, []);

  const vaiAllaGriglia = () => {
    setSchedaAttiva("Righe");
    setZona("griglia");
    const prima = righe.righe[0];
    if (righe.righe.length === 1 && prima && vuota(prima)) invia({ tipo: "vai", cursore: { riga: 0, campo: "articolo" } });
  };

  const fuocoTestata = (campo: keyof CampiTestata) => setTimeout(() => document.getElementById(`testata-${campo}`)?.focus(), 0);

  const nuovo = (data?: string) => {
    setCampi(TESTATA_NUOVA(data));
    setScheda(null);
    setCalcolo(null);
    setAnnullaArmato(false);
    invia({ tipo: "nuovo" });
    setSchedaAttiva("Righe");
    setZona("testata");
    fuocoTestata("cliente");
  };

  const salva = async (stampa: boolean) => {
    if (salvataggio) return;
    const errati = righe.righe.flatMap((r, i) => numeriErrati(r).map((c) => `riga ${i + 1}: ${PER_ID.get(c)?.etichetta ?? c} non è un numero`));
    if (errati.length) {
      onEsito({ tipo: "errore", testo: "Numeri non validi", dettagli: errati });
      return;
    }
    setSalvataggio(true);
    try {
      const creato = await api.crea(bozza);
      onEsito({
        tipo: creato.senza_arca ? "avviso" : "salvato",
        testo: `DDT ${creato.numero}/${creato.esercizio} del ${fData(creato.data)} salvato — totale € ${importo(creato.totale_documento)}${
          stampa ? " · stampa con il modulo stampe (Task 7)" : ""
        }${creato.senza_arca ? ` · numerato senza i documenti di Arca: ${creato.senza_arca}` : ""}`,
      });
      nuovo(campi.data);
    } catch (e) {
      const errore = e instanceof ErroreApi ? e : null;
      onEsito({ tipo: "errore", testo: errore?.message ?? String(e), dettagli: errore?.dettagli });
    } finally {
      setSalvataggio(false);
    }
  };

  useImperativeHandle(ref, () => ({
    salva: (stampa) => void salva(stampa),
    nuovo: () => nuovo(),
    annulla: () => {
      const vuotoDoc = !campi.cliente && righe.righe.every(vuota);
      if (vuotoDoc || annullaArmato) {
        nuovo(campi.data);
        onEsito(null);
      } else {
        setAnnullaArmato(true);
        onEsito({ tipo: "avviso", testo: "Il documento non è salvato: Annulla di nuovo per scartarlo" });
      }
    },
  }));

  // Mostrando la pagina con il documento vuoto, il cursore va sul cliente.
  useEffect(() => {
    if (attivo && zona === "testata" && !campi.cliente && righe.righe.every(vuota)) fuocoTestata("cliente");
  }, [attivo]); // eslint-disable-line react-hooks/exhaustive-deps

  // Ctrl+PgGiù / Ctrl+PgSu: scheda successiva / precedente.
  useEffect(() => {
    if (!attivo || modale) return;
    const tasto = (e: globalThis.KeyboardEvent) => {
      if (e.ctrlKey && (e.key === "PageDown" || e.key === "PageUp")) {
        e.preventDefault();
        const i = SCHEDE.indexOf(schedaAttiva);
        const prossima = SCHEDE[(i + (e.key === "PageDown" ? 1 : SCHEDE.length - 1)) % SCHEDE.length] ?? "Righe";
        setSchedaAttiva(prossima);
        if (prossima === "Righe") setZona("griglia");
      }
    };
    window.addEventListener("keydown", tasto);
    return () => window.removeEventListener("keydown", tasto);
  }, [attivo, modale, schedaAttiva]);

  const tastoTestata = (campo: keyof CampiTestata, e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "F3") {
      e.preventDefault();
      if (campo === "cliente") setModale({ tipo: "clienti", iniziale: campi.cliente });
      if (campo === "destinazione" && scheda) setModale({ tipo: "destinazioni" });
      if (campo === "numero") setModale({ tipo: "liberi", esercizio: Number(iso.slice(0, 4)) });
      return;
    }
    if (e.key !== "Enter") return;
    e.preventDefault();
    if (campo === "data") fuocoTestata("numero");
    if (campo === "numero") vaiAllaGriglia();
    if (campo === "cliente") {
      void caricaCliente(campi.cliente).then((s) => {
        if (s?.destinazioni.some((d) => !d.obsoleto)) fuocoTestata("destinazione");
        else vaiAllaGriglia();
      });
    }
    if (campo === "destinazione") vaiAllaGriglia();
  };

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
          cliente: campi.cliente.trim(),
          data: iso,
          unita_misura: r.unita_misura || c?.unita_misura || undefined,
          quantita: c?.quantita ?? undefined,
          prezzo: c?.prezzo ?? undefined,
        },
      });
    }
  };

  const testataCalcolata = calcolo?.testata;
  const vista = vistaNuovo({
    numero: campi.numero,
    data: iso,
    cliente: campi.cliente,
    scheda,
    destinazione: campi.destinazione || null,
    ragioneSociale: testataCalcolata?.ragione_sociale ?? null,
    righe: calcolo?.righe ?? [],
    pesate: righe.righe,
    castelletto: calcolo?.castelletto ?? null,
    nettoAPagare: calcolo?.netto_a_pagare ?? null,
    scissione: testataCalcolata?.scissione_pagamenti ?? false,
  });
  const errori = [
    ...(calcolo?.errori ?? []),
    ...(calcolo?.righe.flatMap((r, i) => r.errori.map((e) => `riga ${i + 1}: ${e}`)) ?? []),
  ];

  return (
    <div className="flex h-full min-h-0 flex-col">
      <Testata
        vista={vista}
        campi={campi}
        conDestinazioni={!!scheda?.destinazioni.some((d) => !d.obsoleto)}
        onCampo={(campo, valore) => {
          const v = campo === "numero" ? valore.replace(/\D/g, "") : campo === "data" ? valore.replace(/[^\d\-/.]/g, "") : valore.toUpperCase();
          setCampi((c) => ({ ...c, [campo]: v, ...(campo === "cliente" ? { destinazione: "" } : {}) }));
          if (campo === "cliente") setScheda(null);
          setAnnullaArmato(false);
        }}
        onTasto={tastoTestata}
        onFuoco={() => setZona("testata")}
        stato={
          <>
            <span className="rounded-full bg-zinc-500/10 px-2 py-0.5 font-medium text-zinc-600 dark:text-zinc-300">Nuovo documento</span>
            {testataCalcolata?.scissione_pagamenti && (
              <span className="rounded-full bg-violet-500/15 px-2 py-0.5 font-semibold text-violet-700 dark:text-violet-300">Split payment</span>
            )}
            {testataCalcolata && !testataCalcolata.listino && (
              <span className="text-zinc-500">prezzi dal listino {testataCalcolata.listino_prezzi}</span>
            )}
          </>
        }
        schede={
          <BarraSchede
            attiva={schedaAttiva}
            onScheda={(s) => {
              setSchedaAttiva(s);
              if (s === "Righe") setZona("griglia");
            }}
          />
        }
      />
      <div className="flex min-h-0 flex-1 flex-col bg-white dark:bg-zinc-950">
        {schedaAttiva === "Righe" && (
          <>
            <h3 className="px-3 pb-0.5 pt-1 text-[11px] font-bold uppercase tracking-wide text-primario-testo">
              Dettaglio documento
            </h3>
            <Griglia
              stato={righe}
              calcolate={calcolo?.righe ?? []}
              layout={layout}
              attiva={attivo && zona === "griglia" && !modale}
              onLayout={setLayout}
              onAzione={(a) => {
                setZona("griglia");
                setAnnullaArmato(false);
                invia(a);
              }}
              onF3={f3Riga}
            />
            {righe.avviso && (
              <div
                role="alert"
                className="flex items-center gap-3 border-t border-amber-300/60 bg-amber-50 px-3 py-1.5 text-[12px] text-amber-900 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-200"
              >
                <span className="font-semibold">Riga {righe.avviso.riga + 1}</span>
                <span className="flex-1">{righe.avviso.messaggio}</span>
                <span>
                  <kbd className="tasto">Invio</kbd> conferma · <kbd className="tasto">Esc</kbd> correggi
                </span>
              </div>
            )}
            {/* Sotto la griglia come in Arca: Evade a sinistra, Importa pesate e Riferimento a destra. */}
            <div className="flex items-center gap-3 border-t border-zinc-200 px-3 py-1 text-[12px] dark:border-zinc-800">
              <label className="flex items-center gap-1.5 text-zinc-500" title="Evasione di un documento a monte: nessun ordine in ATLAS">
                <input type="checkbox" disabled className="accent-primario" /> Evade
              </label>
              <ul className="min-w-0 flex-1 truncate text-rose-600 dark:text-rose-400" aria-label="Errori">
                {errori.slice(0, 2).map((e) => (
                  <li key={e} className="truncate">
                    {e}
                  </li>
                ))}
              </ul>
              <button
                type="button"
                className="pulsante h-7 text-xs text-primario-testo"
                disabled
                title="Importa pesate dal file della bilancia (Codice;Lordo;Tara;Colli;Lotto): da collegare"
              >
                Importa pesate
              </button>
              <button type="button" className="pulsante h-7 text-xs" disabled title="Riferimento a un ordine: nessun ordine in ATLAS">
                Riferimento
              </button>
            </div>
          </>
        )}
        {schedaAttiva === "Testa" && <SchedaTesta vista={vista} />}
        {schedaAttiva === "Piede" && <SchedaPiede vista={vista} />}
        {schedaAttiva === "Totali" && <SchedaTotali vista={vista} />}
        {schedaAttiva === "Info" && <SchedaInfo vista={vista} />}
        {schedaAttiva === "Evasioni" && <SchedaEvasioni />}
        {schedaAttiva === "Stampe" && <SchedaStampe />}
      </div>

      {modale?.tipo === "prezzi" && (
        <FinestraPrezzi
          richiesta={modale.richiesta}
          onChiudi={() => setModale(null)}
          onRiporta={(p) => {
            invia({ tipo: "scrivi", riga: modale.riga, campo: "prezzo", valore: fPrezzo(p) });
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
            setCampi((t) => ({ ...t, cliente: c.codice, destinazione: "" }));
            setModale(null);
            void caricaCliente(c.codice).then((s) => {
              if (s?.destinazioni.some((d) => !d.obsoleto)) fuocoTestata("destinazione");
              else vaiAllaGriglia();
            });
          }}
        />
      )}
      {modale?.tipo === "destinazioni" && scheda && (
        <RicercaDestinazioni
          destinazioni={scheda.destinazioni}
          onChiudi={() => setModale(null)}
          onScegli={(codice) => {
            setCampi((t) => ({ ...t, destinazione: codice }));
            setModale(null);
          }}
        />
      )}
      {modale?.tipo === "liberi" && (
        <NumeriLiberiF3
          esercizio={modale.esercizio}
          onChiudi={() => setModale(null)}
          onScegli={(n) => {
            setCampi((t) => ({ ...t, numero: n === null ? "" : String(n) }));
            setModale(null);
          }}
        />
      )}
    </div>
  );
});
