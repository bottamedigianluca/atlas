// "Partita IVA": si batte il numero e si leggono i dati ufficiali dell'azienda (servizio VIES della
// Commissione europea, chiamato dal backend), già divisi nei campi dell'anagrafica: ragione
// sociale, indirizzo, CAP, località, provincia. È il primo passo dell'anagrafica di un cliente
// nuovo (con `onNuovo`, dalla maschera Clienti); con `confronto` mette accanto i dati che si hanno,
// per vedere se sono quelli ufficiali.

import { useEffect, useRef, useState } from "react";
import { api, ErroreApi } from "../api/client";
import type { DatiAzienda } from "../api/tipi";
import { Modale } from "../componenti/Modale";

type Campo = "ragione_sociale" | "indirizzo" | "cap" | "localita" | "provincia";

const CAMPI: [Campo, string][] = [
  ["ragione_sociale", "Ragione sociale"],
  ["indirizzo", "Indirizzo"],
  ["cap", "CAP"],
  ["localita", "Località"],
  ["provincia", "Provincia"],
];

/** Confronto senza maiuscole, punteggiatura e spazi doppi: "Via S. Antonio, 7" = "VIA S. ANTONIO 7". */
const uguale = (a: string, b: string) => {
  const semplice = (t: string) => t.toUpperCase().replace(/[.,]/g, " ").replace(/\s+/g, " ").trim();
  return semplice(a) === semplice(b);
};

export function PartitaIva({ iniziale = "", confronto, onChiudi, onNuovo, onApri }: {
  iniziale?: string;
  /** I dati che si hanno, campo per campo, da confrontare con quelli ufficiali. */
  confronto?: Partial<Record<Campo, string>>;
  onChiudi: () => void;
  /** Cliente nuovo con i dati ufficiali (`null`: senza, per chi non ha partita IVA o senza rete). */
  onNuovo?: (dati: DatiAzienda | null, numero: string) => void;
  /** Apre il cliente che ha già questa partita IVA. */
  onApri?: (codice: string) => void;
}) {
  const [numero, setNumero] = useState(iniziale);
  const [dati, setDati] = useState<DatiAzienda | null>(null);
  const [errore, setErrore] = useState<string | null>(null);
  const [inCorso, setInCorso] = useState(false);
  const campo = useRef<HTMLInputElement>(null);

  const cerca = (n: string) => {
    if (!n.trim()) return;
    setInCorso(true);
    setErrore(null);
    api
      .partitaIva(n.trim())
      .then(setDati, (e: unknown) => {
        setDati(null);
        setErrore(e instanceof ErroreApi ? e.message : String(e));
      })
      .finally(() => setInCorso(false));
  };

  // Con un numero già dato si cerca subito.
  useEffect(() => {
    if (iniziale) cerca(iniziale);
    else campo.current?.focus();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <Modale titolo="Partita IVA" sottotitolo="Dati ufficiali dell'azienda dal servizio VIES della Commissione europea" larghezza="max-w-2xl" onChiudi={onChiudi}>
      <div className="space-y-4 p-5">
        <form
          className="flex items-end gap-2"
          onSubmit={(e) => {
            e.preventDefault();
            cerca(numero);
          }}
        >
          <label className="flex flex-1 flex-col gap-1">
            <span className="etichetta">Partita IVA</span>
            <input
              ref={campo}
              className="campo font-mono"
              value={numero}
              onChange={(e) => setNumero(e.target.value.toUpperCase())}
              placeholder="es. 02273530226 o IT02273530226"
              aria-label="Partita IVA"
              autoComplete="off"
            />
          </label>
          <button type="submit" className="pulsante-primario" disabled={inCorso || !numero.trim()}>
            {inCorso ? "Cerco…" : "Cerca online"}
          </button>
        </form>

        {errore && (
          <p role="alert" className="rounded-lg bg-rose-50 px-3 py-2 text-[13px] text-rose-700 dark:bg-rose-500/10 dark:text-rose-300">
            {errore}
          </p>
        )}

        {dati && (
          <div className="space-y-3">
            <p className="flex flex-wrap items-center gap-2 text-[12.5px]">
              <span
                className={`rounded-full px-2 py-0.5 font-semibold ${
                  dati.attiva ? "bg-emerald-500/12 text-emerald-700 dark:text-emerald-300" : "bg-rose-500/12 text-rose-700 dark:text-rose-300"
                }`}
              >
                {dati.attiva ? "Partita IVA attiva" : "Partita IVA non attiva"}
              </span>
              <span className="font-mono text-zinc-500">
                {dati.nazione} {dati.partita_iva}
              </span>
              {dati.gia_presente && (
                <span className="rounded-full bg-amber-500/15 px-2 py-0.5 font-semibold text-amber-800 dark:text-amber-300">
                  Già in anagrafica: {dati.gia_presente}
                </span>
              )}
            </p>
            <table className="w-full text-[13px]" aria-label="Dati dell'azienda">
              <thead>
                <tr className="text-left text-[11px] uppercase tracking-wide text-zinc-500">
                  <th className="w-32 py-1 font-medium" />
                  <th className="py-1 font-medium">Ufficiale (VIES)</th>
                  {confronto && <th className="py-1 font-medium">In ATLAS</th>}
                </tr>
              </thead>
              <tbody>
                {CAMPI.map(([chiave, nome]) => {
                  const ufficiale = dati[chiave] ?? "";
                  const nostro = confronto?.[chiave];
                  const stesso = nostro !== undefined && uguale(nostro, ufficiale);
                  return (
                    <tr key={chiave} className="border-t border-zinc-100 dark:border-zinc-800">
                      <td className="py-1.5 text-zinc-500">{nome}</td>
                      <td className="py-1.5 font-medium">{ufficiale || <span className="text-zinc-400">—</span>}</td>
                      {confronto && (
                        <td className={`py-1.5 ${nostro === undefined ? "text-zinc-400" : stesso ? "text-emerald-700 dark:text-emerald-400" : "text-amber-700 dark:text-amber-400"}`}>
                          {nostro ?? "—"} {nostro !== undefined && (stesso ? "✓" : "≠")}
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
            {dati.indirizzo_vies && <p className="text-[11px] text-zinc-400">Indirizzo come lo dà VIES: {dati.indirizzo_vies.replace(/\n/g, " · ")}</p>}
          </div>
        )}

        {onNuovo && (
          <div className="flex items-center justify-end gap-2 border-t border-zinc-100 pt-3 dark:border-zinc-800">
            <button type="button" className="pulsante" onClick={() => onNuovo(null, numero.trim())}>
              {numero.trim() ? "Nuovo cliente senza i dati ufficiali" : "Nuovo cliente senza partita IVA"}
            </button>
            {dati?.gia_presente && onApri ? (
              <button type="button" className="pulsante-primario" onClick={() => onApri(dati.gia_presente!)}>
                Apri {dati.gia_presente}
              </button>
            ) : (
              dati && (
                <button type="button" className="pulsante-primario" onClick={() => onNuovo(dati, numero.trim())}>
                  Nuovo cliente con questi dati
                </button>
              )
            )}
          </div>
        )}
      </div>
    </Modale>
  );
}
