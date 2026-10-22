// La finestra "Gestione Documenti" di Arca per i DDT (BO): barra degli strumenti, pagine Elenco,
// Generale e DMS come in Arca, barra di stato con esito, totali, server e firma (direttiva
// §3.6-3.7). La pagina Generale tiene montato il DDT in battitura: aprendo un documento
// dall'elenco e tornando indietro, quello che si stava battendo è ancora lì.
//
// La barra strumenti ha l'ordine di quella di Arca: Salva, Annulla | Stampa | Nuovo, Elimina |
// documento precedente e successivo (le frecce arancioni di Arca).
//
// Tasti: Ctrl+N nuovo, F10 salva, F12 salva e stampa, Alt+↓/↑ documento precedente/successivo,
// Ctrl+1/2/3 pagine Elenco/Generale/DMS, F1 informazioni.

import { useCallback, useEffect, useRef, useState } from "react";
import { api, impostaServer, indirizzoServer } from "./api/client";
import { BadgeSemaforo } from "./componenti/Badge";
import { Modale } from "./componenti/Modale";
import { Consultazione } from "./documento/Consultazione";
import { type ComandiDocumento, type Esito, NuovoDocumento } from "./documento/NuovoDocumento";
import { Elenco } from "./elenco/Elenco";
import { importo } from "./griglia/numeri";
import { PannelloSincronizzazione } from "./sincronizzazione/PannelloSincronizzazione";
import { ProviderSincronizzazione, useSincronizzazione } from "./sincronizzazione/contesto";

type Pagina = "Elenco" | "Generale" | "DMS";
type Tema = "sistema" | "chiaro" | "scuro";
type Totali = { righe: number; imponibile: string; totale: string } | null;

const PAGINE: { pagina: Pagina; tasto: string }[] = [
  { pagina: "Elenco", tasto: "1" },
  { pagina: "Generale", tasto: "2" },
  { pagina: "DMS", tasto: "3" },
];

export const INTESTAZIONE =
  "BOTTAMEDI PIERLUIGI — Via Degasperi, 38017 Mezzolombardo (TN) — P.IVA 02273530226 — C.F. BTTPLG77S15F187I";
export const FIRMA = '"ATLAS" // ARCHITECTURE & DOMAIN LOGIC BY BOTTAMEDI GIANLUCA — KERNEL v2.1';
export const SPEC = '[ SPEC: BG-2026 / 46.2144° N, 11.0964° E — MEZZOLOMBARDO, TN — "DESIGNED FOR VELOCITY" ]';

function leggiTema(): Tema {
  try {
    const t = localStorage.getItem("atlas.tema");
    // Predefinito il chiaro, quello della postazione al banco; scuro e sistema si scelgono.
    return t === "sistema" || t === "scuro" ? t : "chiaro";
  } catch {
    return "chiaro";
  }
}

function useTema(): [Tema, () => void] {
  const [tema, setTema] = useState<Tema>(leggiTema);
  useEffect(() => {
    const sistema = window.matchMedia("(prefers-color-scheme: dark)");
    const applica = () => {
      const scuro = tema === "scuro" || (tema === "sistema" && sistema.matches);
      document.documentElement.classList.toggle("scuro", scuro);
      document.documentElement.style.colorScheme = scuro ? "dark" : "light";
    };
    applica();
    try {
      localStorage.setItem("atlas.tema", tema);
    } catch {
      // preferenza non salvata
    }
    sistema.addEventListener("change", applica);
    return () => sistema.removeEventListener("change", applica);
  }, [tema]);
  const prossimo = () => setTema((t) => (t === "chiaro" ? "scuro" : t === "scuro" ? "sistema" : "chiaro"));
  return [tema, prossimo];
}

export function App() {
  return (
    <ProviderSincronizzazione>
      <Guscio />
    </ProviderSincronizzazione>
  );
}

function Guscio() {
  const [pagina, setPagina] = useState<Pagina>("Generale");
  /** Documento salvato aperto dall'elenco; `null`: la pagina Generale mostra il DDT in battitura. */
  const [aperto, setAperto] = useState<number | null>(null);
  const [informazioni, setInformazioni] = useState(false);
  const [sincronizzazione, setSincronizzazione] = useState(false);
  const [esito, setEsito] = useState<Esito | null>(null);
  const [totali, setTotali] = useState<Totali>(null);
  const [tema, cambiaTema] = useTema();
  const { semaforo } = useSincronizzazione();
  const documento = useRef<ComandiDocumento>(null);
  const finestra = informazioni || sincronizzazione;
  const inBattitura = pagina === "Generale" && aperto === null;

  const nuovo = useCallback(() => {
    setAperto(null);
    setPagina("Generale");
    setEsito(null);
    documento.current?.nuovo();
  }, []);
  // Precedente e Successivo scorrono i documenti nell'ordine dell'elenco (dal più recente). Dal
  // documento in battitura, Precedente apre l'ultimo salvato.
  const [documenti, setDocumenti] = useState<number[]>([]);
  const scorri = useCallback(
    async (passo: 1 | -1) => {
      let ids = documenti;
      if (!ids.length) {
        ids = (await api.elencoDdt({ limite: 1000 }).catch(() => [])).map((d) => d.id);
        setDocumenti(ids);
      }
      const posizione = aperto === null ? -1 : ids.indexOf(aperto);
      const prossimo = ids[posizione + passo];
      if (prossimo !== undefined) {
        setAperto(prossimo);
        setPagina("Generale");
      } else if (passo === -1 && aperto !== null) {
        setAperto(null);
      }
    },
    [documenti, aperto],
  );
  const salva = useCallback(
    (stampa: boolean) => {
      if (inBattitura) documento.current?.salva(stampa);
    },
    [inBattitura],
  );

  useEffect(() => {
    if (finestra) return;
    const tasto = (e: KeyboardEvent) => {
      // Con una ricerca o la finestra prezzi aperte i tasti sono loro.
      if (document.querySelector("[role=dialog]")) return;
      if (e.ctrlKey && !e.shiftKey && !e.altKey) {
        const scelta = PAGINE.find((p) => p.tasto === e.key);
        if (scelta) {
          e.preventDefault();
          setPagina(scelta.pagina);
          return;
        }
        if (e.key.toLowerCase() === "n") {
          e.preventDefault();
          nuovo();
          return;
        }
      }
      if (e.altKey && !e.ctrlKey && (e.key === "ArrowDown" || e.key === "ArrowUp")) {
        e.preventDefault();
        void scorri(e.key === "ArrowDown" ? 1 : -1);
        return;
      }
      if (e.key === "F10" || e.key === "F12") {
        e.preventDefault();
        salva(e.key === "F12");
      }
      if (e.key === "F1") {
        e.preventDefault();
        setInformazioni(true);
      }
    };
    window.addEventListener("keydown", tasto);
    return () => window.removeEventListener("keydown", tasto);
  }, [finestra, nuovo, salva, scorri]);

  return (
    <div className="flex h-full flex-col">
      <header className="flex h-9 shrink-0 items-center gap-3 border-b border-zinc-200 bg-white/70 px-3 backdrop-blur-md dark:border-zinc-800/80 dark:bg-zinc-900/60">
        <span className="font-mono text-[12px] font-bold tracking-[0.3em]">ATLAS</span>
        <h1 className="text-[13px] font-semibold">Gestione Documenti</h1>
        <span className="text-[12px] text-zinc-500">DDT — BOLLA VENDITA (BO)</span>
        <span className="hidden truncate text-[11px] text-zinc-400 2xl:inline">{INTESTAZIONE}</span>
        <div className="ml-auto flex items-center gap-2">
          <button type="button" onClick={() => setSincronizzazione(true)} aria-label="Stato della sincronizzazione" title="Sincronizzazione con Arca">
            <BadgeSemaforo semaforo={semaforo} />
          </button>
          <button type="button" className="pulsante h-6 px-2 text-[11px]" onClick={cambiaTema} title="Tema">
            {tema === "sistema" ? "Tema: sistema" : tema === "scuro" ? "Tema: scuro" : "Tema: chiaro"}
          </button>
          <button type="button" className="pulsante h-6 px-2 text-[11px]" onClick={() => setInformazioni(true)}>
            Info <kbd className="tasto">F1</kbd>
          </button>
        </div>
      </header>

      {/* Barra degli strumenti della finestra documenti. */}
      <nav aria-label="Strumenti" className="flex h-9 shrink-0 items-center gap-1 border-b border-zinc-200 bg-zinc-50/80 px-2 dark:border-zinc-800 dark:bg-zinc-900/40">
        <Strumento icona="salva" nome="Salva" tasto="F10" disabled={!inBattitura} onClick={() => salva(false)} />
        <Strumento icona="annulla" nome="Annulla" disabled={!inBattitura} onClick={() => documento.current?.annulla()} />
        <Separatore />
        <Strumento icona="stampa" nome="Salva e stampa" tasto="F12" disabled={!inBattitura} onClick={() => salva(true)} />
        <Separatore />
        <Strumento icona="nuovo" nome="Nuovo" tasto="Ctrl+N" onClick={nuovo} />
        <Strumento icona="elimina" nome="Elimina" disabled title="Eliminazione dei DDT: Task 6" />
        <Separatore />
        <Strumento icona="giu" nome="Precedente" tasto="Alt+↓" title="Documento precedente (più vecchio)" onClick={() => void scorri(1)} />
        <Strumento
          icona="su"
          nome="Successivo"
          tasto="Alt+↑"
          title="Documento successivo (più recente); dall'ultimo torna al documento in battitura"
          disabled={aperto === null}
          onClick={() => void scorri(-1)}
        />
        {aperto !== null && pagina === "Generale" && (
          <>
            <Separatore />
            <Strumento icona="nuovo" nome="Torna al documento in battitura" onClick={() => setAperto(null)} />
          </>
        )}
      </nav>

      {/* Pagine della finestra, a sinistra sotto gli strumenti come in Arca. */}
      <div role="tablist" aria-label="Pagine" className="flex h-7 shrink-0 items-end gap-1 border-b border-zinc-200 px-3 dark:border-zinc-800">
        {PAGINE.map((p) => (
          <button
            key={p.pagina}
            type="button"
            role="tab"
            aria-selected={pagina === p.pagina}
            tabIndex={-1}
            onClick={() => setPagina(p.pagina)}
            className={`-mb-px border-b-2 px-2.5 pb-1 text-[12.5px] font-semibold ${
              pagina === p.pagina
                ? "border-[#c0161e] text-[#c0161e] dark:border-[#ff6b6b] dark:text-[#ff6b6b]"
                : "border-transparent text-zinc-500 hover:text-zinc-800 dark:text-zinc-400 dark:hover:text-zinc-200"
            }`}
          >
            {p.pagina}
            <span className="ml-1 font-mono text-[9.5px] font-normal opacity-50">⌃{p.tasto}</span>
          </button>
        ))}
      </div>

      <main className="min-h-0 flex-1">
        <div className={pagina === "Elenco" ? "h-full" : "hidden"}>
          <Elenco
            attivo={pagina === "Elenco" && !finestra}
            onDocumenti={setDocumenti}
            onApri={(id) => {
              setAperto(id);
              setPagina("Generale");
            }}
          />
        </div>
        <div className={inBattitura ? "h-full" : "hidden"}>
          <NuovoDocumento ref={documento} attivo={inBattitura && !finestra} onEsito={(e) => {
              setEsito(e);
              // Un DDT salvato cambia l'elenco di Precedente/Successivo: si rilegge alla prossima freccia.
              if (e?.tipo === "salvato" || e?.tipo === "avviso") setDocumenti([]);
            }} onTotali={setTotali} />
        </div>
        {pagina === "Generale" && aperto !== null && (
          <div className="h-full">
            <Consultazione key={aperto} id={aperto} attivo={!finestra} />
          </div>
        )}
        {pagina === "DMS" && (
          <div className="flex h-full items-center justify-center text-sm text-zinc-500">
            Archivio documentale (DMS): i PDF dei DDT arrivano con il modulo stampe (Task 7).
          </div>
        )}
      </main>

      <BarraStato esito={esito} totali={inBattitura ? totali : null} />
      {informazioni && <Informazioni onChiudi={() => setInformazioni(false)} />}
      {sincronizzazione && (
        <Modale titolo="Sincronizzazione con Arca" larghezza="max-w-5xl" onChiudi={() => setSincronizzazione(false)}>
          <PannelloSincronizzazione />
        </Modale>
      )}
    </div>
  );
}

type NomeIcona = "salva" | "annulla" | "stampa" | "nuovo" | "elimina" | "giu" | "su";

const ICONE: Record<NomeIcona, React.ReactNode> = {
  salva: <path d="M3 2.5h8.5L14 5v8.5H3zM5.5 2.5v3.5h5v-3.5M5 13.5v-4h7v4" />,
  annulla: <path d="M5 4 2.5 6.5 5 9M2.5 6.5H10a3.5 3.5 0 0 1 0 7H6" />,
  stampa: <path d="M4.5 6V2.5h7V6M4.5 11H2.5V6h11v5h-2M4.5 9h7v4.5h-7z" />,
  nuovo: <path d="M4 1.5h5.5L12.5 4.5v10H4zM9.5 1.5v3h3M8.25 7v5M5.75 9.5h5" />,
  elimina: <path d="M3 4h10M6.5 4V2.5h3V4M4.5 4l.7 9.5h5.6l.7-9.5" />,
  giu: <path d="M8 2.5v11M3.5 9 8 13.5 12.5 9" />,
  su: <path d="M8 13.5v-11M3.5 7 8 2.5 12.5 7" />,
};

function Strumento({ icona, nome, tasto, disabled, title, onClick }: {
  icona: NomeIcona;
  nome: string;
  tasto?: string;
  disabled?: boolean;
  title?: string;
  onClick?: () => void;
}) {
  const freccia = icona === "giu" || icona === "su";
  return (
    <button
      type="button"
      disabled={disabled}
      title={title}
      onClick={onClick}
      className="flex h-7 items-center gap-1.5 rounded-md px-2 text-[12px] font-medium text-zinc-700 hover:bg-zinc-200/70 disabled:opacity-40 disabled:hover:bg-transparent dark:text-zinc-200 dark:hover:bg-zinc-700/60"
    >
      <svg
        viewBox="0 0 16 16"
        aria-hidden
        className={`size-4 shrink-0 fill-none stroke-[1.4] [stroke-linecap:round] [stroke-linejoin:round] ${
          freccia ? "stroke-[#e8890c]" : "stroke-[#007aff] dark:stroke-[#0a84ff]"
        }`}
      >
        {ICONE[icona]}
      </svg>
      {nome}
      {tasto && <kbd className="tasto">{tasto}</kbd>}
    </button>
  );
}

function Separatore() {
  return <span className="mx-1 h-5 w-px bg-zinc-200 dark:bg-zinc-700" />;
}

const COLORI_ESITO = {
  salvato: "text-emerald-700 dark:text-emerald-400",
  avviso: "text-amber-700 dark:text-amber-300",
  errore: "text-rose-600 dark:text-rose-400",
};

function BarraStato({ esito, totali }: { esito: Esito | null; totali: Totali }) {
  const { collegato } = useSincronizzazione();
  return (
    <footer className="flex h-7 shrink-0 items-center gap-3 border-t border-zinc-200 bg-white/60 px-3 dark:border-zinc-800/80 dark:bg-zinc-900/50">
      <span className="flex items-center gap-1.5 text-[11px] text-zinc-500">
        <span className={`size-1.5 rounded-full ${collegato ? "bg-emerald-500" : "bg-rose-500"}`} />
        <span className="font-mono">{indirizzoServer()}</span>
      </span>
      {esito && (
        <span role="status" title={esito.dettagli?.join("\n")} className={`min-w-0 truncate text-[12px] font-medium ${COLORI_ESITO[esito.tipo]}`}>
          {esito.testo}
          {esito.dettagli?.length ? ` (${esito.dettagli.length})` : ""}
        </span>
      )}
      {totali && (
        <span className="cifre ml-auto shrink-0 text-[12px] text-zinc-600 dark:text-zinc-300" aria-label="Totali del documento">
          Righe {totali.righe} · Imponibile {importo(totali.imponibile)} · <b>Totale {importo(totali.totale)}</b>
        </span>
      )}
      <span className={`hidden shrink-0 whitespace-nowrap font-mono text-[9px] tracking-wider text-zinc-500 opacity-40 2xl:inline ${totali ? "" : "ml-auto"}`}>{SPEC}</span>
      <span className={`shrink-0 whitespace-nowrap font-mono text-[10px] tracking-widest text-zinc-500 opacity-35 ${totali ? "" : "ml-auto 2xl:ml-0"}`}>{FIRMA}</span>
    </footer>
  );
}

function Informazioni({ onChiudi }: { onChiudi: () => void }) {
  const { stato } = useSincronizzazione();
  const [server, setServer] = useState(indirizzoServer());
  return (
    <Modale titolo="Informazioni di sistema" larghezza="max-w-xl" onChiudi={onChiudi}>
      <div className="space-y-5 p-6">
        {/* Cartellino industriale (direttiva §3.7). */}
        <div className="relative border border-zinc-400/60 px-6 py-5 font-mono text-[11px] leading-relaxed tracking-[0.18em] text-zinc-600 dark:border-zinc-600 dark:text-zinc-300">
          <span className="absolute -left-px -top-px size-2 border-l-2 border-t-2 border-zinc-900 dark:border-zinc-100" />
          <span className="absolute -bottom-px -right-px size-2 border-b-2 border-r-2 border-zinc-900 dark:border-zinc-100" />
          <p className="text-[13px] font-bold text-zinc-900 dark:text-zinc-50">"ATLAS OPERATING SYSTEM"</p>
          <p>CONCEIVED &amp; ARCHITECTED BY BOTTAMEDI GIANLUCA</p>
          <p>FOR "BOTTAMEDI PIERLUIGI" — MEZZOLOMBARDO (TN)</p>
          <p>P.IVA 02273530226 — ALL RIGHTS RESERVED © 2026</p>
        </div>
        <p className="text-xs text-zinc-500">{INTESTAZIONE}</p>
        <div className="text-xs text-zinc-500">
          Server ATLAS {stato ? `${stato.versione}, schema ${stato.schema}` : "non raggiungibile"}
        </div>
        <form
          className="flex items-end gap-2"
          onSubmit={(e) => {
            e.preventDefault();
            impostaServer(server);
            window.location.reload();
          }}
        >
          <label className="flex flex-1 flex-col gap-1">
            <span className="etichetta">Indirizzo del server</span>
            <input className="campo font-mono" value={server} onChange={(e) => setServer(e.target.value)} />
          </label>
          <button type="submit" className="pulsante">
            Usa e ricarica
          </button>
        </form>
      </div>
    </Modale>
  );
}
