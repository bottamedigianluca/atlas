// La Home come quella di Arca (`docs/screenshot_arca/07_…`, 13-16):
// - in alto "La tua Home", a destra "Cerca comando" e "Aggiorna";
// - a sinistra "Cosa vuoi fare?": un clic su una voce allarga il pannello sopra i riquadri con il
//   sottomenu nella seconda colonna, `×` (o `Esc`) lo chiude; in fondo "Favoriti";
// - al centro, al posto dei riquadri di Arca (conteggi, anelli, tutorial), widget piccoli che
//   servono al banco: i clienti da chiamare oggi (un tocco li barra, i già serviti sono barrati
//   da soli), il post-it a righe da barrare, i DDT di oggi, i numeri liberi.
//
// Solo conteggi, nessun importo (direttiva §4.3: al banco nessun dato di fatturato).

import { useEffect, useMemo, useState } from "react";
import { api } from "../api/client";
import type { ClientiDelGiorno, DdtBreve, NumeriLiberi } from "../api/tipi";
import { data as fData, oggi } from "../griglia/numeri";
import { useSincronizzazione } from "../sincronizzazione/contesto";
import { COMANDI, type Comando, type Gruppo, MENU } from "./menu";
import { PostIt } from "./PostIt";

export function Home({ attivo, onNuovo, onElenco, onApri }: {
  attivo: boolean;
  onNuovo: () => void;
  onElenco: () => void;
  onApri: (id: number) => void;
}) {
  const giorno = oggi();
  const { ultimaNotifica } = useSincronizzazione();
  const [clienti, setClienti] = useState<ClientiDelGiorno | null>(null);
  const [ddtOggi, setDdtOggi] = useState<DdtBreve[]>([]);
  const [liberi, setLiberi] = useState<NumeriLiberi | null>(null);
  const [errore, setErrore] = useState<string | null>(null);
  const [giro, setGiro] = useState(0);
  const esegui = (c: Comando) => (c === "nuovo" ? onNuovo() : onElenco());

  // Si rilegge entrando nella Home, con "Aggiorna" e a ogni DDT salvato o importato.
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
  }, [attivo, giorno, ultimaNotifica, giro]);

  const aggiorna = () => setGiro((g) => g + 1);

  return (
    <div className="flex h-full flex-col bg-zinc-100/80 dark:bg-zinc-950">
      <header className="flex shrink-0 items-end gap-4 border-b border-zinc-200 bg-white px-4 pb-2 pt-2 dark:border-zinc-800 dark:bg-zinc-900">
        <div>
          <p className="text-[12px] text-primario-testo">Home</p>
          <h1 className="text-[17px] font-semibold tracking-tight">La tua Home</h1>
        </div>
        {errore && <p className="self-center text-[12px] text-rose-600">{errore}</p>}
        <CercaComando onEsegui={esegui} />
        <Collegamento onClick={aggiorna} icona={<path d="M13 8a5 5 0 1 1-1.5-3.5M13 2.5V5h-2.5" />}>
          Aggiorna
        </Collegamento>
      </header>

      <div className="relative min-h-0 flex-1">
        <CosaVuoiFare onEsegui={esegui} />

        <div className="h-full overflow-auto py-4 pl-[17rem] pr-4">
          <div className="flex flex-wrap content-start gap-4">
            <DaChiamare clienti={clienti} giorno={giorno} />
            <PostIt attivo={attivo} />
            <DdtDiOggi ddt={ddtOggi} onApri={onApri} onNuovo={onNuovo} onElenco={onElenco} />
            <Liberi liberi={liberi} />
          </div>
        </div>
      </div>
    </div>
  );
}

function Collegamento({ onClick, icona, children }: { onClick: () => void; icona: React.ReactNode; children: React.ReactNode }) {
  return (
    <button type="button" onClick={onClick} className="flex items-center gap-1.5 self-center text-[13px] text-primario-testo hover:underline">
      <svg viewBox="0 0 16 16" className="size-4 fill-none stroke-current stroke-[1.5] [stroke-linecap:round]" aria-hidden>
        {icona}
      </svg>
      {children}
    </button>
  );
}

/** "Cerca comando" di Arca: si batte, si sceglie con le frecce, `Invio` esegue. */
function CercaComando({ onEsegui }: { onEsegui: (c: Comando) => void }) {
  const [testo, setTesto] = useState("");
  const [scelta, setScelta] = useState(0);
  const trovati = useMemo(() => {
    const t = testo.trim().toLowerCase();
    return t ? COMANDI.filter((c) => c.percorso.toLowerCase().includes(t)) : [];
  }, [testo]);
  const esegui = (i: number) => {
    const c = trovati[i];
    if (!c) return;
    setTesto("");
    onEsegui(c.voce.comando);
  };
  return (
    <div className="relative ml-auto self-center">
      <input
        value={testo}
        onChange={(e) => {
          setTesto(e.target.value);
          setScelta(0);
        }}
        onKeyDown={(e) => {
          if (e.key === "ArrowDown") setScelta((s) => Math.min(s + 1, trovati.length - 1));
          else if (e.key === "ArrowUp") setScelta((s) => Math.max(s - 1, 0));
          else if (e.key === "Enter") esegui(scelta);
          else if (e.key === "Escape") setTesto("");
          else return;
          e.preventDefault();
        }}
        placeholder="Cerca comando"
        aria-label="Cerca comando"
        className="h-8 w-64 border-b border-zinc-300 bg-transparent px-1 text-[13px] outline-none focus:border-anello dark:border-zinc-700"
      />
      {testo.trim() && (
        <ul className="absolute right-0 top-9 z-30 w-72 overflow-hidden rounded-lg border border-zinc-200 bg-white shadow-lg dark:border-zinc-800 dark:bg-zinc-900" role="listbox" aria-label="Comandi">
          {trovati.length === 0 && <li className="px-3 py-2 text-[12.5px] text-zinc-500">Nessun comando in ATLAS</li>}
          {trovati.map((c, i) => (
            <li key={c.percorso} role="option" aria-selected={i === scelta}>
              <button
                type="button"
                onMouseDown={(e) => {
                  e.preventDefault();
                  esegui(i);
                }}
                className={`w-full px-3 py-1.5 text-left text-[13px] ${i === scelta ? "bg-primario-tenue" : ""}`}
              >
                {c.percorso}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

const CHIAVE_FAVORITI = "atlas.favoriti";

function leggiFavoriti(): string[] {
  try {
    const salvati = JSON.parse(localStorage.getItem(CHIAVE_FAVORITI) ?? "null") as string[] | null;
    return salvati ?? ["Documenti › Nuovo Documento", "Documenti › Gestione"];
  } catch {
    return ["Documenti › Nuovo Documento", "Documenti › Gestione"];
  }
}

/**
 * "Cosa vuoi fare?" come in Arca: la colonna delle voci; un clic su una voce allarga il pannello
 * sopra i riquadri con il sottomenu accanto. La stella accanto a un comando lo mette nei Favoriti.
 */
function CosaVuoiFare({ onEsegui }: { onEsegui: (c: Comando) => void }) {
  const [aperto, setAperto] = useState<Gruppo | null>(null);
  const [favoritiAperti, setFavoritiAperti] = useState(false);
  const [favoriti, setFavoriti] = useState<string[]>(leggiFavoriti);
  const espanso = aperto !== null || favoritiAperti;

  useEffect(() => {
    if (!espanso) return;
    const tasto = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setAperto(null);
        setFavoritiAperti(false);
      }
    };
    window.addEventListener("keydown", tasto);
    return () => window.removeEventListener("keydown", tasto);
  }, [espanso]);

  const alternaFavorito = (percorso: string) =>
    setFavoriti((f) => {
      const nuovi = f.includes(percorso) ? f.filter((x) => x !== percorso) : [...f, percorso];
      try {
        localStorage.setItem(CHIAVE_FAVORITI, JSON.stringify(nuovi));
      } catch {
        // ignorato: i favoriti valgono fino al riavvio
      }
      return nuovi;
    });

  const esegui = (c: Comando) => {
    setAperto(null);
    setFavoritiAperti(false);
    onEsegui(c);
  };

  return (
    <nav
      aria-label="Cosa vuoi fare?"
      className={`absolute inset-y-0 left-0 z-20 flex flex-col px-4 pb-4 pt-3 ${
        espanso ? "w-[31rem] border-r border-zinc-200 bg-zinc-50 shadow-xl dark:border-zinc-800 dark:bg-zinc-900" : "w-[16.5rem]"
      }`}
    >
      <div className="mb-2 flex items-center">
        <h2 className="text-[15px] font-semibold">Cosa vuoi fare?</h2>
        {espanso && (
          <button
            type="button"
            aria-label="Chiudi"
            onClick={() => {
              setAperto(null);
              setFavoritiAperti(false);
            }}
            className="ml-auto px-1 text-[18px] leading-none text-zinc-500 hover:text-zinc-900 dark:hover:text-zinc-100"
          >
            ×
          </button>
        )}
      </div>
      <div className="flex min-h-0 flex-1 overflow-y-auto">
        <ul className="w-60 shrink-0 self-start border-t border-zinc-200 dark:border-zinc-800">
          {MENU.map((g) => {
            const scelto = aperto?.nome === g.nome;
            return (
              <li key={g.nome} className="border-b border-zinc-200 dark:border-zinc-800">
                <button
                  type="button"
                  aria-expanded={scelto}
                  onClick={() => {
                    setFavoritiAperti(false);
                    setAperto(scelto ? null : g);
                  }}
                  className={`flex w-full items-center justify-between px-1 py-2 text-left text-[13.5px] ${
                    scelto ? "bg-primario text-white" : "hover:bg-primario-tenue"
                  } ${!scelto && !g.voci.some((v) => v.comando) ? "text-zinc-500 dark:text-zinc-500" : ""}`}
                >
                  {g.nome}
                  <span aria-hidden>›</span>
                </button>
              </li>
            );
          })}
        </ul>
        {aperto && (
          <ul className="min-w-0 flex-1 self-start" aria-label={aperto.nome} style={{ marginTop: MENU.indexOf(aperto) * 37 }}>
            {aperto.voci.length === 0 && <li className="px-3 py-2 text-[12.5px] text-zinc-500">In ATLAS più avanti: per ora in Arca.</li>}
            {aperto.voci.map((v) => {
              const percorso = `${aperto.nome} › ${v.nome}`;
              const comando = v.comando;
              return (
                <li key={v.nome} className="flex items-center border-b border-zinc-200 dark:border-zinc-800">
                  <button
                    type="button"
                    disabled={!comando}
                    onClick={() => comando && esegui(comando)}
                    title={comando ? undefined : "In ATLAS più avanti: per ora in Arca"}
                    className={`flex min-w-0 flex-1 items-center justify-between px-2 py-2 text-left text-[13.5px] ${
                      comando ? "font-medium hover:bg-primario-tenue" : "text-zinc-400 dark:text-zinc-600"
                    }`}
                  >
                    {v.nome}
                    {v.sottomenu && <span aria-hidden>›</span>}
                  </button>
                  {comando && (
                    <button
                      type="button"
                      aria-label={favoriti.includes(percorso) ? `Togli dai Favoriti: ${v.nome}` : `Aggiungi ai Favoriti: ${v.nome}`}
                      aria-pressed={favoriti.includes(percorso)}
                      onClick={() => alternaFavorito(percorso)}
                      className={`px-2 text-[14px] ${favoriti.includes(percorso) ? "text-amber-500" : "text-zinc-300 hover:text-amber-500"}`}
                    >
                      ★
                    </button>
                  )}
                </li>
              );
            })}
          </ul>
        )}
        {favoritiAperti && (
          <ul className="min-w-0 flex-1 self-end" aria-label="Favoriti">
            {favoriti.length === 0 && <li className="px-3 py-2 text-[12.5px] text-zinc-500">Nessun favorito: la stella accanto a un comando lo aggiunge.</li>}
            {COMANDI.filter((c) => favoriti.includes(c.percorso)).map((c) => (
              <li key={c.percorso} className="border-b border-zinc-200 dark:border-zinc-800">
                <button type="button" onClick={() => esegui(c.voce.comando)} className="w-full px-2 py-2 text-left text-[13.5px] font-medium hover:bg-primario-tenue">
                  {c.percorso}
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
      <button
        type="button"
        aria-expanded={favoritiAperti}
        onClick={() => {
          setAperto(null);
          setFavoritiAperti((f) => !f);
        }}
        className="mt-4 flex h-9 w-56 items-center justify-center gap-2 rounded-full bg-primario text-[13.5px] font-semibold text-white shadow-sm hover:bg-primario-forte"
      >
        ★ Favoriti
      </button>
    </nav>
  );
}

/** I nomi barrati a mano restano barrati per la giornata, su questa postazione. */
function useBarrati(giorno: string): [Set<string>, (codice: string) => void] {
  const chiave = `atlas.chiamati.${giorno}`;
  const [barrati, setBarrati] = useState<Set<string>>(() => {
    try {
      return new Set(JSON.parse(localStorage.getItem(chiave) ?? "[]") as string[]);
    } catch {
      return new Set();
    }
  });
  const alterna = (codice: string) =>
    setBarrati((b) => {
      const nuovi = new Set(b);
      if (nuovi.has(codice)) nuovi.delete(codice);
      else nuovi.add(codice);
      try {
        localStorage.setItem(chiave, JSON.stringify([...nuovi]));
      } catch {
        // ignorato: restano barrati fino al riavvio
      }
      return nuovi;
    });
  return [barrati, alterna];
}

function DaChiamare({ clienti, giorno }: { clienti: ClientiDelGiorno | null; giorno: string }) {
  const [barrati, alterna] = useBarrati(giorno);
  const elenco = clienti?.clienti ?? [];
  const fatti = elenco.filter((c) => c.servito || barrati.has(c.cliente)).length;
  return (
    <Widget
      titolo="Da chiamare oggi"
      conteggio={`${fatti}/${elenco.length}`}
      title={clienti ? `Clienti che il ${clienti.giorno} ordinano quasi sempre (ultime ${clienti.settimane} settimane)` : undefined}
    >
      <ul className="min-h-0 flex-1 overflow-auto" aria-label="Clienti da chiamare">
        {elenco.map((c) => {
          const barrato = !!c.servito || barrati.has(c.cliente);
          return (
            <li key={c.cliente}>
              <button
                type="button"
                aria-pressed={barrato}
                onClick={() => !c.servito && alterna(c.cliente)}
                title={c.servito ? `Servito: DDT ${c.servito.numero}` : "Tocca per barrare"}
                className={`w-full truncate rounded px-1 py-0.5 text-left text-[13px] hover:bg-zinc-50 dark:hover:bg-zinc-800/60 ${
                  barrato ? "text-zinc-400 line-through decoration-zinc-400" : ""
                }`}
              >
                {c.ragione_sociale}
              </button>
            </li>
          );
        })}
      </ul>
    </Widget>
  );
}

/** Il riquadro dei widget piccoli: un quadrato come le schede della Home di Arca. */
function Widget({ titolo, conteggio, title, children }: { titolo: string; conteggio?: string; title?: string; children: React.ReactNode }) {
  return (
    <section
      aria-label={titolo}
      title={title}
      className="flex h-80 w-72 flex-col rounded-xl border border-zinc-200 bg-white p-4 shadow-sm dark:border-zinc-800 dark:bg-zinc-900"
    >
      <h2 className="flex items-baseline gap-2 text-[15px] font-semibold">
        {titolo}
        {conteggio !== undefined && <span className="text-[12px] font-normal tabular-nums text-zinc-500">{conteggio}</span>}
      </h2>
      <div className="mt-2 flex min-h-0 flex-1 flex-col">{children}</div>
    </section>
  );
}

function DdtDiOggi({ ddt, onApri, onNuovo, onElenco }: { ddt: DdtBreve[]; onApri: (id: number) => void; onNuovo: () => void; onElenco: () => void }) {
  return (
    <Widget titolo="DDT di oggi" conteggio={String(ddt.length)}>
      <ul className="min-h-0 flex-1 overflow-auto" aria-label="DDT di oggi">
        {ddt.length === 0 && <li className="py-1 text-[13px] text-zinc-500">Ancora nessuno.</li>}
        {ddt.map((d) => (
          <li key={d.id}>
            <button type="button" onClick={() => onApri(d.id)} className="flex w-full gap-2 rounded px-1 py-0.5 text-left text-[13px] hover:bg-zinc-50 dark:hover:bg-zinc-800/60">
              <span className="w-10 shrink-0 font-semibold tabular-nums">{d.numero}</span>
              <span className="truncate">{d.ragione_sociale}</span>
            </button>
          </li>
        ))}
      </ul>
      <div className="mt-2 flex gap-3 border-t border-zinc-100 pt-2 text-[13px] dark:border-zinc-800">
        <button type="button" className="text-primario-testo hover:underline" onClick={onNuovo}>
          + Nuovo
        </button>
        <button type="button" className="ml-auto text-primario-testo hover:underline" onClick={onElenco}>
          Elenco
        </button>
      </div>
    </Widget>
  );
}

function Liberi({ liberi }: { liberi: NumeriLiberi | null }) {
  return (
    <Widget titolo="Numeri liberi" title="Buchi di numerazione da riempire: F3 sul numero del DDT">
      {liberi && (
        <>
          <p className="text-[13px]">
            Prossimo: <b className="tabular-nums">{liberi.prossimo ?? "—"}</b>
          </p>
          <ul className="mt-1 min-h-0 flex-1 overflow-auto text-[13px]" aria-label="Buchi di numerazione">
            {liberi.liberi.length === 0 && <li className="text-zinc-500">Nessun buco.</li>}
            {[...liberi.liberi].reverse().map((l) => (
              <li key={l.dal} className="flex gap-2 py-0.5">
                <span className="w-20 shrink-0 font-semibold tabular-nums">{l.dal === l.al ? l.dal : `${l.dal}–${l.al}`}</span>
                <span className="text-zinc-500">{l.data_dal && l.data_dal !== l.data_al ? `${fData(l.data_dal)} – ` : ""}{fData(l.data_al)}</span>
              </li>
            ))}
          </ul>
        </>
      )}
    </Widget>
  );
}
