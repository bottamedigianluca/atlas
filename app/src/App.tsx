// L'applicazione: barra superiore (viste, semaforo di Arca, tema), vista attiva, barra di stato
// con server e firma (direttiva §3.6-3.7). Le viste restano montate: passando all'elenco
// documenti e tornando, il DDT in battitura è ancora lì.
//
// Tasti: Ctrl+1 maschera DDT, Ctrl+2 documenti, Ctrl+3 sincronizzazione, F1 informazioni.

import { useEffect, useState } from "react";
import { impostaServer, indirizzoServer } from "./api/client";
import { BadgeSemaforo } from "./componenti/Badge";
import { Modale } from "./componenti/Modale";
import { ElencoDocumenti } from "./documenti/ElencoDocumenti";
import { MascheraDdt } from "./maschera/MascheraDdt";
import { PannelloSincronizzazione } from "./sincronizzazione/PannelloSincronizzazione";
import { ProviderSincronizzazione, useSincronizzazione } from "./sincronizzazione/contesto";

type Vista = "maschera" | "documenti" | "sincronizzazione";
type Tema = "sistema" | "chiaro" | "scuro";

const VISTE: { vista: Vista; nome: string; tasto: string }[] = [
  { vista: "maschera", nome: "Nuovo DDT", tasto: "1" },
  { vista: "documenti", nome: "Documenti", tasto: "2" },
  { vista: "sincronizzazione", nome: "Sincronizzazione", tasto: "3" },
];

export const INTESTAZIONE =
  "BOTTAMEDI PIERLUIGI — Via Degasperi, 38017 Mezzolombardo (TN) — P.IVA 02273530226 — C.F. BTTPLG77S15F187I";
export const FIRMA = '"ATLAS" // ARCHITECTURE & DOMAIN LOGIC BY BOTTAMEDI GIANLUCA — KERNEL v2.1';
export const SPEC = '[ SPEC: BG-2026 / 46.2144° N, 11.0964° E — MEZZOLOMBARDO, TN — "DESIGNED FOR VELOCITY" ]';

function leggiTema(): Tema {
  try {
    const t = localStorage.getItem("atlas.tema");
    return t === "chiaro" || t === "scuro" ? t : "sistema";
  } catch {
    return "sistema";
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
  const prossimo = () => setTema((t) => (t === "sistema" ? "scuro" : t === "scuro" ? "chiaro" : "sistema"));
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
  const [vista, setVista] = useState<Vista>("maschera");
  const [informazioni, setInformazioni] = useState(false);
  const [tema, cambiaTema] = useTema();
  const { semaforo } = useSincronizzazione();

  useEffect(() => {
    const tasto = (e: KeyboardEvent) => {
      if (e.ctrlKey && !e.shiftKey && !e.altKey) {
        const scelta = VISTE.find((v) => v.tasto === e.key);
        if (scelta) {
          e.preventDefault();
          setVista(scelta.vista);
        }
      }
      if (e.key === "F1") {
        e.preventDefault();
        setInformazioni(true);
      }
    };
    window.addEventListener("keydown", tasto);
    return () => window.removeEventListener("keydown", tasto);
  }, []);

  return (
    <div className="flex h-full flex-col">
      <header className="flex h-11 shrink-0 items-center gap-4 border-b border-zinc-200 bg-white/70 px-4 backdrop-blur-md dark:border-zinc-800/80 dark:bg-zinc-900/60">
        <span className="font-mono text-[13px] font-bold tracking-[0.3em]">ATLAS</span>
        <nav className="flex gap-1" aria-label="Viste">
          {VISTE.map((v) => (
            <button
              key={v.vista}
              type="button"
              onClick={() => setVista(v.vista)}
              aria-current={vista === v.vista ? "page" : undefined}
              className={`rounded-lg px-3 py-1 text-[13px] font-medium transition-colors ${
                vista === v.vista
                  ? "bg-zinc-900 text-white dark:bg-white dark:text-zinc-900"
                  : "text-zinc-600 hover:bg-zinc-100 dark:text-zinc-300 dark:hover:bg-zinc-800"
              }`}
            >
              {v.nome}
              <span className="ml-1.5 font-mono text-[10px] opacity-50">⌃{v.tasto}</span>
            </button>
          ))}
        </nav>
        <span className="hidden truncate text-[11px] text-zinc-400 xl:inline">{INTESTAZIONE}</span>
        <div className="ml-auto flex items-center gap-3">
          <button type="button" onClick={() => setVista("sincronizzazione")} aria-label="Stato della sincronizzazione">
            <BadgeSemaforo semaforo={semaforo} />
          </button>
          <button type="button" className="pulsante h-7 px-2 text-xs" onClick={cambiaTema} title="Tema">
            {tema === "sistema" ? "Tema: sistema" : tema === "scuro" ? "Tema: scuro" : "Tema: chiaro"}
          </button>
          <button type="button" className="pulsante h-7 px-2 text-xs" onClick={() => setInformazioni(true)}>
            Info <kbd className="tasto">F1</kbd>
          </button>
        </div>
      </header>

      <main className="min-h-0 flex-1">
        <div className={vista === "maschera" ? "h-full" : "hidden"}>
          <MascheraDdt attiva={vista === "maschera" && !informazioni} onEsci={() => setVista("documenti")} />
        </div>
        <div className={vista === "documenti" ? "h-full" : "hidden"}>
          <ElencoDocumenti attiva={vista === "documenti"} />
        </div>
        <div className={vista === "sincronizzazione" ? "h-full" : "hidden"}>
          <PannelloSincronizzazione />
        </div>
      </main>

      <BarraStato />
      {informazioni && <Informazioni onChiudi={() => setInformazioni(false)} />}
    </div>
  );
}

function BarraStato() {
  const { collegato } = useSincronizzazione();
  return (
    <footer className="flex h-7 shrink-0 items-center gap-3 border-t border-zinc-200 bg-white/60 px-4 dark:border-zinc-800/80 dark:bg-zinc-900/50">
      <span className="flex items-center gap-1.5 text-[11px] text-zinc-500">
        <span className={`size-1.5 rounded-full ${collegato ? "bg-emerald-500" : "bg-rose-500"}`} />
        <span className="font-mono">{indirizzoServer()}</span>
      </span>
      <span className="font-mono text-[9px] tracking-wider text-zinc-500 opacity-40">{SPEC}</span>
      <span className="ml-auto font-mono text-[10px] tracking-widest text-zinc-500 opacity-35">{FIRMA}</span>
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
