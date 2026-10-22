// Il post-it della Home: righe di promemoria condivise fra le postazioni (database ATLAS, notifica
// `note_cambiate` dal WebSocket). Un tocco barra la riga (o la riprende), `×` la toglie; la riga
// nuova si scrive in fondo e si aggiunge con `Invio`.

import { useCallback, useEffect, useState } from "react";
import { api } from "../api/client";
import type { Nota } from "../api/tipi";
import { useSincronizzazione } from "../sincronizzazione/contesto";
import { Etichetta, Strisce } from "./stile";

export function PostIt({ attivo }: { attivo: boolean }) {
  const [note, setNote] = useState<Nota[]>([]);
  const [nuova, setNuova] = useState("");
  const [errore, setErrore] = useState<string | null>(null);
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

  const fallita = (e: Error) => {
    setErrore(e.message);
    rileggi();
  };

  return (
    <section
      aria-label="Post-it"
      className="flex h-80 w-72 rotate-[-0.6deg] flex-col rounded-sm bg-[#fff3a3] p-4 text-zinc-800 shadow-[0_10px_20px_-10px_rgba(0,0,0,0.45)] dark:bg-[#4d4620] dark:text-zinc-100"
    >
      <h2 className="flex items-center">
        <Etichetta>Post-it</Etichetta>
        <Strisce className="ml-auto size-3 text-black/20 dark:text-white/25" />
      </h2>
      <ul className="mt-2 min-h-0 flex-1 overflow-auto" aria-label="Righe del post-it">
        {note.map((n) => (
          <li key={n.id} className="group flex items-start gap-1">
            <button
              type="button"
              aria-pressed={n.fatta}
              onClick={() => {
                setNote((tutte) => tutte.map((x) => (x.id === n.id ? { ...x, fatta: !x.fatta } : x)));
                api.aggiornaNota(n.id, { fatta: !n.fatta }).catch(fallita);
              }}
              title={`${n.autore}, ${n.creata_il.slice(8, 10)}/${n.creata_il.slice(5, 7)} ${n.creata_il.slice(11, 16)}`}
              className={`min-w-0 flex-1 break-words border-b border-black/10 py-0.5 text-left text-[13.5px] leading-snug dark:border-white/10 ${
                n.fatta ? "text-black/40 line-through dark:text-white/40" : ""
              }`}
              style={{ fontFamily: '"Bradley Hand", "Segoe Print", "Comic Sans MS", var(--font-sans)' }}
            >
              {n.testo}
            </button>
            <button
              type="button"
              aria-label={`Togli: ${n.testo}`}
              onClick={() => {
                setNote((tutte) => tutte.filter((x) => x.id !== n.id));
                api.eliminaNota(n.id).catch(fallita);
              }}
              className="px-1 text-[14px] leading-6 text-black/30 opacity-0 hover:text-black/70 focus:opacity-100 group-hover:opacity-100 dark:text-white/40"
            >
              ×
            </button>
          </li>
        ))}
      </ul>
      {errore && <p className="text-[11px] text-rose-700">{errore}</p>}
      <input
        value={nuova}
        maxLength={500}
        onChange={(e) => setNuova(e.target.value)}
        onKeyDown={(e) => {
          if (e.key !== "Enter" || !nuova.trim()) return;
          e.preventDefault();
          const testo = nuova.trim();
          setNuova("");
          api
            .creaNota({ testo })
            .then((creata) => setNote((tutte) => [...tutte.filter((x) => x.id !== creata.id), creata]))
            .catch(fallita);
        }}
        placeholder="Scrivi e premi Invio…"
        aria-label="Nuova riga del post-it"
        className="mt-2 border-b border-black/20 bg-transparent py-1 text-[13px] outline-none placeholder:text-black/35 focus:border-black/50 dark:border-white/20 dark:placeholder:text-white/35"
      />
    </section>
  );
}
