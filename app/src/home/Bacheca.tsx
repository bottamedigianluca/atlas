// Bacheca dei post-it della Home, condivisa fra le postazioni: le note stanno nel database ATLAS
// e ogni modifica arriva alle altre postazioni dal WebSocket (`note_cambiate`).
//
// Si trascinano per la testata; il testo si scrive direttamente sulla nota e si salva uscendo
// dalla nota. La posizione è in frazioni della bacheca: resta la stessa su schermi diversi.

import { type PointerEvent, useCallback, useEffect, useRef, useState } from "react";
import { api } from "../api/client";
import type { ColoreNota, Nota } from "../api/tipi";
import { useSincronizzazione } from "../sincronizzazione/contesto";

const LARGHEZZA = 188;
const ALTEZZA = 150;

const COLORI: Record<ColoreNota, string> = {
  giallo: "bg-[#fff3a3] dark:bg-[#5c5420]",
  rosa: "bg-[#ffd3e4] dark:bg-[#5c2a3d]",
  verde: "bg-[#c9f2cf] dark:bg-[#24502c]",
  azzurro: "bg-[#cde9ff] dark:bg-[#1f435c]",
  arancio: "bg-[#ffdcb5] dark:bg-[#5c3d1f]",
};

const PUNTI: Record<ColoreNota, string> = {
  giallo: "bg-[#f5d90a]",
  rosa: "bg-[#f472b6]",
  verde: "bg-[#4ade80]",
  azzurro: "bg-[#38bdf8]",
  arancio: "bg-[#fb923c]",
};

const limita = (v: number) => Math.min(Math.max(v, 0), 1);

export function Bacheca({ attivo }: { attivo: boolean }) {
  const [note, setNote] = useState<Nota[]>([]);
  const [errore, setErrore] = useState<string | null>(null);
  const [trascinata, setTrascinata] = useState<{ id: number; x: number; y: number } | null>(null);
  const bacheca = useRef<HTMLDivElement>(null);
  const presa = useRef<{ id: number; dx: number; dy: number } | null>(null);
  /** Nota appena creata: il cursore ci va appena è in bacheca. */
  const [daScrivere, setDaScrivere] = useState<number | null>(null);
  const { ultimaNotifica } = useSincronizzazione();

  const rileggi = useCallback(() => {
    api.note().then(
      (n) => {
        setNote(n);
        setErrore(null);
      },
      (e: Error) => setErrore(e.message),
    );
  }, []);

  useEffect(() => {
    if (attivo) rileggi();
  }, [attivo, rileggi]);
  useEffect(() => {
    if (ultimaNotifica?.evento === "note_cambiate") rileggi();
  }, [ultimaNotifica, rileggi]);

  useEffect(() => {
    if (daScrivere === null) return;
    const campo = document.getElementById(`nota-${daScrivere}`);
    if (campo) {
      campo.focus();
      setDaScrivere(null);
    }
  }, [daScrivere, note]);

  const modifica = (id: number, campi: Parameters<typeof api.aggiornaNota>[1]) => {
    setNote((n) => n.map((x) => (x.id === id ? { ...x, ...campi } : x)));
    api.aggiornaNota(id, campi).catch((e: Error) => {
      setErrore(e.message);
      rileggi();
    });
  };

  const nuova = () => {
    // Una accanto all'altra, poi a capo: non si coprono le note già in bacheca.
    const n = note.length;
    api
      .creaNota({ testo: "", colore: "giallo", x: limita(((n % 4) * 0.25) + 0.02), y: limita(Math.floor(n / 4) * 0.3 + 0.02) })
      .then((creata) => {
        setNote((tutte) => [...tutte.filter((x) => x.id !== creata.id), creata]);
        setDaScrivere(creata.id);
      })
      .catch((e: Error) => setErrore(e.message));
  };

  const posizione = (e: PointerEvent, dx: number, dy: number) => {
    const r = bacheca.current?.getBoundingClientRect();
    if (!r) return { x: 0, y: 0 };
    return {
      x: limita((e.clientX - r.left - dx) / Math.max(r.width - LARGHEZZA, 1)),
      y: limita((e.clientY - r.top - dy) / Math.max(r.height - ALTEZZA, 1)),
    };
  };

  return (
    <div className="flex min-h-0 flex-1 flex-col gap-2">
      <div className="flex items-center gap-2">
        <button type="button" className="pulsante h-7 px-2.5 text-[12px]" onClick={nuova}>
          + Nuovo post-it
        </button>
        {errore && <span className="text-[12px] text-rose-600">{errore}</span>}
      </div>
      <div
        ref={bacheca}
        role="region"
        aria-label="Post-it"
        className="relative min-h-[420px] flex-1 overflow-hidden rounded-xl bg-[radial-gradient(circle,#d4d4d8_1px,transparent_1px)] bg-[size:18px_18px] dark:bg-[radial-gradient(circle,#3f3f46_1px,transparent_1px)]"
      >
        {note.length === 0 && (
          <p className="absolute inset-0 flex items-center justify-center text-[13px] text-zinc-400">Nessun post-it: "+ Nuovo post-it" per scriverne uno.</p>
        )}
        {note.map((n) => {
          const qui = trascinata?.id === n.id ? trascinata : n;
          const inclinazione = ((n.id * 37) % 5) - 2;
          return (
            <article
              key={n.id}
              aria-label={`Post-it: ${n.testo || "vuoto"}`}
              className={`absolute flex flex-col rounded-md shadow-[0_6px_14px_-6px_rgba(0,0,0,0.35)] ${COLORI[n.colore]} ${
                trascinata?.id === n.id ? "z-20 scale-[1.03] shadow-[0_14px_28px_-8px_rgba(0,0,0,0.4)]" : "z-10"
              }`}
              style={{
                width: LARGHEZZA,
                height: ALTEZZA,
                left: `calc(${qui.x} * (100% - ${LARGHEZZA}px))`,
                top: `calc(${qui.y} * (100% - ${ALTEZZA}px))`,
                rotate: trascinata?.id === n.id ? "0deg" : `${inclinazione * 0.6}deg`,
              }}
            >
              <div
                className="flex h-6 shrink-0 cursor-grab items-center gap-1 px-2 active:cursor-grabbing"
                onPointerDown={(e) => {
                  const r = e.currentTarget.parentElement?.getBoundingClientRect();
                  if (!r) return;
                  e.currentTarget.setPointerCapture(e.pointerId);
                  presa.current = { id: n.id, dx: e.clientX - r.left, dy: e.clientY - r.top };
                }}
                onPointerMove={(e) => {
                  const p = presa.current;
                  if (p?.id === n.id) setTrascinata({ id: n.id, ...posizione(e, p.dx, p.dy) });
                }}
                onPointerUp={() => {
                  const p = presa.current;
                  presa.current = null;
                  if (p && trascinata?.id === p.id) modifica(p.id, { x: trascinata.x, y: trascinata.y });
                  setTrascinata(null);
                }}
                title="Trascina per spostare"
              >
                {(Object.keys(COLORI) as ColoreNota[]).map((c) => (
                  <button
                    key={c}
                    type="button"
                    aria-label={`Colore ${c}`}
                    aria-pressed={n.colore === c}
                    onPointerDown={(e) => e.stopPropagation()}
                    onClick={() => modifica(n.id, { colore: c })}
                    className={`size-2.5 rounded-full ring-black/30 ${PUNTI[c]} ${n.colore === c ? "ring-2" : "opacity-60 hover:opacity-100"}`}
                  />
                ))}
                <button
                  type="button"
                  aria-label="Elimina post-it"
                  onPointerDown={(e) => e.stopPropagation()}
                  onClick={() => {
                    setNote((tutte) => tutte.filter((x) => x.id !== n.id));
                    api.eliminaNota(n.id).catch((e: Error) => {
                      setErrore(e.message);
                      rileggi();
                    });
                  }}
                  className="ml-auto rounded px-1 text-[14px] leading-none text-black/40 hover:bg-black/10 hover:text-black/70 dark:text-white/50"
                >
                  ×
                </button>
              </div>
              <TestoNota id={`nota-${n.id}`} testo={n.testo} onSalva={(testo) => modifica(n.id, { testo })} />
              <footer className="shrink-0 px-2 pb-1 text-[10px] text-black/45 dark:text-white/50">
                {n.autore} · {n.aggiornata_il.slice(8, 10)}/{n.aggiornata_il.slice(5, 7)} {n.aggiornata_il.slice(11, 16)}
              </footer>
            </article>
          );
        })}
      </div>
    </div>
  );
}

/** Il testo della nota: si scrive libero, si salva uscendo (o con Ctrl+Invio). */
function TestoNota({ id, testo, onSalva }: { id: string; testo: string; onSalva: (testo: string) => void }) {
  const [bozza, setBozza] = useState(testo);
  const [scrivendo, setScrivendo] = useState(false);
  useEffect(() => {
    if (!scrivendo) setBozza(testo);
  }, [testo, scrivendo]);
  const salva = () => {
    setScrivendo(false);
    if (bozza !== testo) onSalva(bozza);
  };
  return (
    <textarea
      id={id}
      value={bozza}
      maxLength={500}
      placeholder="Scrivi…"
      aria-label="Testo del post-it"
      onFocus={() => setScrivendo(true)}
      onChange={(e) => setBozza(e.target.value)}
      onBlur={salva}
      onKeyDown={(e) => {
        if (e.key === "Enter" && e.ctrlKey) {
          e.preventDefault();
          e.currentTarget.blur();
        }
        if (e.key === "Escape") {
          e.stopPropagation();
          setBozza(testo);
          setScrivendo(false);
          e.currentTarget.blur();
        }
      }}
      className="min-h-0 flex-1 resize-none bg-transparent px-2 text-[13px] leading-snug text-zinc-800 outline-none placeholder:text-black/30 dark:text-zinc-100 dark:placeholder:text-white/30"
      style={{ fontFamily: '"Bradley Hand", "Segoe Print", "Comic Sans MS", var(--font-sans)' }}
    />
  );
}
