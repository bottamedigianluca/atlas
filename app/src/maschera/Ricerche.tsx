// Ricerche del tasto F3: articoli, clienti, numeri liberi. Tutte da tastiera: si batte per
// filtrare, `Freccia Su/Giù` scorrono, `Invio` sceglie, `Esc` chiude.

import { type ReactNode, useEffect, useState } from "react";
import { api } from "../api/client";
import type { ArticoloBreve, ClienteBreve, DestinazioneVista, NumeriLiberi } from "../api/tipi";
import { Modale } from "../componenti/Modale";
import { data as fData } from "../griglia/numeri";

interface PropsLista<T> {
  titolo: string;
  iniziale: string;
  cerca: (testo: string, segnale: AbortSignal) => Promise<T[]>;
  chiave: (v: T) => string;
  riga: (v: T) => ReactNode;
  onScegli: (v: T) => void;
  onChiudi: () => void;
}

function Lista<T>({ titolo, iniziale, cerca, chiave, riga, onScegli, onChiudi }: PropsLista<T>) {
  const [testo, setTesto] = useState(iniziale);
  const [risultati, setRisultati] = useState<T[]>([]);
  const [scelta, setScelta] = useState(0);
  const [errore, setErrore] = useState<string | null>(null);

  useEffect(() => {
    const controllo = new AbortController();
    cerca(testo, controllo.signal)
      .then((r) => {
        setRisultati(r);
        setScelta(0);
        setErrore(null);
      })
      .catch((e: Error) => e.name !== "AbortError" && setErrore(e.message));
    return () => controllo.abort();
  }, [testo, cerca]);

  return (
    <Modale
      titolo={titolo}
      onChiudi={onChiudi}
      piede={
        <span>
          <kbd className="tasto">↑</kbd> <kbd className="tasto">↓</kbd> scorre · <kbd className="tasto">Invio</kbd> sceglie
        </span>
      }
    >
      <div className="border-b border-zinc-200/80 p-3 dark:border-zinc-800">
        <input
          data-fuoco-iniziale
          className="campo w-full"
          value={testo}
          placeholder="Codice o descrizione"
          aria-label="Cerca"
          onChange={(e) => setTesto(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "ArrowDown") setScelta((s) => Math.min(s + 1, risultati.length - 1));
            else if (e.key === "ArrowUp") setScelta((s) => Math.max(s - 1, 0));
            else if (e.key === "Enter") {
              const v = risultati[scelta];
              if (v) onScegli(v);
            } else return;
            e.preventDefault();
          }}
        />
      </div>
      {errore && <p className="px-5 py-3 text-sm text-rose-600">{errore}</p>}
      <ul role="listbox" aria-label={titolo} className="py-1">
        {risultati.map((v, i) => (
          <li
            key={chiave(v)}
            role="option"
            aria-selected={i === scelta}
            onMouseDown={() => onScegli(v)}
            className={`flex cursor-pointer items-baseline gap-3 px-4 py-1.5 text-sm ${
              i === scelta ? "bg-primario-tenue" : "hover:bg-zinc-100 dark:hover:bg-zinc-800/60"
            }`}
          >
            {riga(v)}
          </li>
        ))}
        {risultati.length === 0 && !errore && <li className="px-4 py-3 text-sm text-zinc-500">Nessun risultato</li>}
      </ul>
    </Modale>
  );
}

const cercaArticoli = (t: string, s: AbortSignal) => api.articoli(t, s);
const cercaClienti = (t: string, s: AbortSignal) => api.clienti(t, s);

export function RicercaArticoli(props: { iniziale: string; onScegli: (a: ArticoloBreve) => void; onChiudi: () => void }) {
  return (
    <Lista
      titolo="Articoli"
      cerca={cercaArticoli}
      chiave={(a) => a.codice}
      riga={(a) => (
        <>
          <span className="w-24 shrink-0 font-mono text-xs font-semibold">{a.codice}</span>
          <span className="flex-1 truncate">{a.descrizione}</span>
          <span className="text-xs text-zinc-500">{a.unita_misura}</span>
          <span className="w-8 text-right text-xs text-zinc-500">{a.aliquota ?? ""}</span>
        </>
      )}
      {...props}
    />
  );
}

export function RicercaClienti(props: { iniziale: string; onScegli: (c: ClienteBreve) => void; onChiudi: () => void }) {
  return (
    <Lista
      titolo="Clienti"
      cerca={cercaClienti}
      chiave={(c) => c.codice}
      riga={(c) => (
        <>
          <span className="w-20 shrink-0 font-mono text-xs font-semibold">{c.codice}</span>
          <span className="flex-1 truncate">{c.ragione_sociale}</span>
          <span className="truncate text-xs text-zinc-500">{c.localita ?? ""}</span>
        </>
      )}
      {...props}
    />
  );
}

/** I buchi della numerazione (F3 sul numero), con le date ammesse, e il prossimo numero. */
export function NumeriLiberiF3({ esercizio, onScegli, onChiudi }: {
  esercizio: number;
  onScegli: (numero: number | null) => void;
  onChiudi: () => void;
}) {
  const [liberi, setLiberi] = useState<NumeriLiberi | null>(null);
  const [errore, setErrore] = useState<string | null>(null);
  const [scelta, setScelta] = useState(0);

  useEffect(() => {
    api.liberi(esercizio).then(setLiberi, (e: Error) => setErrore(e.message));
  }, [esercizio]);

  // Prima voce: il prossimo numero (numerazione automatica), poi i buchi dal più recente.
  const voci = liberi
    ? [
        { numero: null as number | null, testo: `Prossimo valore disponibile: ${liberi.prossimo ?? "—"}`, date: "" },
        ...liberi.liberi
          .slice()
          .reverse()
          .map((l) => ({
            numero: l.dal,
            testo: l.dal === l.al ? `${l.dal}` : `${l.dal} – ${l.al}`,
            date: `${l.data_dal ? fData(l.data_dal) : "inizio esercizio"} → ${fData(l.data_al)}`,
          })),
      ]
    : [];

  return (
    <Modale
      titolo={`Numeri liberi BO ${esercizio}`}
      sottotitolo={liberi?.senza_arca ? `Senza i numeri di Arca: ${liberi.senza_arca}` : "Sui documenti di ATLAS e di Arca"}
      larghezza="max-w-lg"
      onChiudi={onChiudi}
      piede={<span><kbd className="tasto">Invio</kbd> usa il numero</span>}
    >
      {errore && <p className="px-5 py-3 text-sm text-rose-600">{errore}</p>}
      <ul
        role="listbox"
        aria-label="Numeri liberi"
        tabIndex={0}
        data-fuoco-iniziale
        className="py-1 outline-none"
        onKeyDown={(e) => {
          if (e.key === "ArrowDown") setScelta((s) => Math.min(s + 1, voci.length - 1));
          else if (e.key === "ArrowUp") setScelta((s) => Math.max(s - 1, 0));
          else if (e.key === "Enter") {
            const v = voci[scelta];
            if (v) onScegli(v.numero);
          } else return;
          e.preventDefault();
        }}
      >
        {voci.map((v, i) => (
          <li
            key={v.testo}
            role="option"
            aria-selected={i === scelta}
            onMouseDown={() => onScegli(v.numero)}
            className={`flex cursor-pointer justify-between px-4 py-1.5 text-sm ${i === scelta ? "bg-primario-tenue" : ""}`}
          >
            <span className="cifre">{v.testo}</span>
            <span className="text-xs text-zinc-500">{v.date}</span>
          </li>
        ))}
      </ul>
    </Modale>
  );
}

/** Destinazioni del cliente (F3 sul campo Destinazione). */
export function RicercaDestinazioni({ destinazioni, onScegli, onChiudi }: {
  destinazioni: readonly DestinazioneVista[];
  onScegli: (codice: string) => void;
  onChiudi: () => void;
}) {
  const voci = destinazioni.filter((d) => !d.obsoleto);
  const [scelta, setScelta] = useState(0);
  return (
    <Modale titolo="Destinazioni" larghezza="max-w-xl" onChiudi={onChiudi} piede={<span><kbd className="tasto">Invio</kbd> sceglie</span>}>
      <ul
        role="listbox"
        aria-label="Destinazioni"
        tabIndex={0}
        data-fuoco-iniziale
        className="py-1 outline-none"
        onKeyDown={(e) => {
          if (e.key === "ArrowDown") setScelta((s) => Math.min(s + 1, voci.length - 1));
          else if (e.key === "ArrowUp") setScelta((s) => Math.max(s - 1, 0));
          else if (e.key === "Enter") {
            const v = voci[scelta];
            if (v) onScegli(v.codice);
          } else return;
          e.preventDefault();
        }}
      >
        {voci.map((d, i) => (
          <li
            key={d.codice}
            role="option"
            aria-selected={i === scelta}
            onMouseDown={() => onScegli(d.codice)}
            className={`flex cursor-pointer items-baseline gap-3 px-4 py-1.5 text-sm ${i === scelta ? "bg-primario-tenue" : ""}`}
          >
            <span className="w-14 shrink-0 font-mono text-xs font-semibold">{d.codice}</span>
            <span className="flex-1 truncate">{d.descrizione}</span>
            <span className="truncate text-xs text-zinc-500">{d.localita ?? ""}</span>
            {d.predefinita && <span className="text-[10px] text-zinc-400">predefinita</span>}
          </li>
        ))}
        {voci.length === 0 && <li className="px-4 py-3 text-sm text-zinc-500">Il cliente non ha destinazioni</li>}
      </ul>
    </Modale>
  );
}
