// Stato della sincronizzazione con Arca: coda di replica, importazione, conflitti di numero con
// l'azione "rinumera" (un DDT ATLAS non ancora in Arca il cui numero, in Arca, è di un altro
// documento).

import { useState } from "react";
import { api, ErroreApi } from "../api/client";
import { BadgeSemaforo } from "../componenti/Badge";
import { useSincronizzazione } from "./contesto";

export function PannelloSincronizzazione() {
  const { stato, semaforo, collegato, aggiorna } = useSincronizzazione();
  const [messaggio, setMessaggio] = useState<string | null>(null);
  const [inCorso, setInCorso] = useState<number | null>(null);

  const rinumera = async (id: number) => {
    setInCorso(id);
    try {
      const r = await api.rinumera(id);
      setMessaggio(`DDT ${r.prima}/${r.esercizio} rinumerato: ora è il ${r.numero}`);
    } catch (e) {
      setMessaggio(e instanceof ErroreApi ? e.message : String(e));
    } finally {
      setInCorso(null);
      aggiorna();
    }
  };

  const s = stato?.sincronizzazione;
  return (
    <div className="h-full overflow-auto p-6">
      <div className="mx-auto max-w-4xl space-y-5">
        <div className="flex items-center gap-3">
          <h2 className="text-lg font-semibold tracking-tight">Sincronizzazione con Arca</h2>
          <BadgeSemaforo semaforo={semaforo} />
          <button type="button" className="pulsante ml-auto" disabled={!collegato} onClick={() => void api.sincronizza().then(aggiorna)}>
            Sincronizza ora
          </button>
        </div>
        {messaggio && <p className="text-sm font-medium" role="status">{messaggio}</p>}
        {!stato && <p className="text-sm text-zinc-500">Server ATLAS non raggiungibile.</p>}
        {stato && s && (
          <>
            <section className="grid gap-4 sm:grid-cols-2">
              <Riquadro titolo="Replica ATLAS → Arca">
                <Voce nome="Configurata" valore={s.replica.configurata ? "sì" : "no (ATLAS_ARCA_ADO)"} />
                <Voce nome="In coda" valore={String(stato.coda.in_coda)} />
                <Voce nome="Scritti dall'avvio" valore={`${s.replica.scritti} (+${s.replica.gia_presenti} già presenti)`} />
                <Voce nome="Ultimo giro" valore={s.replica.ultimo_giro?.replace("T", " ") ?? "—"} />
                {stato.coda.fermo && (
                  <p className="mt-2 text-rose-600 dark:text-rose-400">
                    Fermo sul DDT {stato.coda.fermo.numero}/{stato.coda.fermo.esercizio} ({stato.coda.fermo.tentativi} tentativi):{" "}
                    {stato.coda.fermo.ultimo_errore}
                  </p>
                )}
                {s.replica.errore && <p className="mt-2 text-rose-600">{s.replica.errore}</p>}
              </Riquadro>
              <Riquadro titolo="Importazione Arca → ATLAS">
                <Voce nome="Configurata" valore={s.importazione.configurata ? "sì" : "no"} />
                <Voce
                  nome="Dall'avvio"
                  valore={`${s.importazione.nuovi} nuovi, ${s.importazione.aggiornati} aggiornati, ${s.importazione.cancellati} cancellati, ${s.importazione.esclusi} esclusi`}
                />
                <Voce nome="Ultimo giro" valore={s.importazione.ultimo_giro?.replace("T", " ") ?? "—"} />
                {s.importazione.fermo && (
                  <p className="mt-2 text-rose-600 dark:text-rose-400">
                    Fermo su Id_DoTes {s.importazione.fermo.arca_id_testata}: {s.importazione.fermo.errore}
                  </p>
                )}
                {s.importazione.errore && <p className="mt-2 text-rose-600">{s.importazione.errore}</p>}
              </Riquadro>
            </section>
            <section>
              <h3 className="etichetta mb-2">Conflitti da risolvere</h3>
              {stato.conflitti.length === 0 ? (
                <p className="text-sm text-zinc-500">Nessun conflitto.</p>
              ) : (
                <ul className="space-y-2">
                  {stato.conflitti.map((c) => (
                    <li
                      key={`${c.origine}-${c.ddt}`}
                      className="flex items-center gap-3 rounded-xl border border-rose-300/60 bg-rose-50/60 px-4 py-2.5 text-sm dark:border-rose-500/30 dark:bg-rose-500/10"
                    >
                      <span className="font-semibold">
                        DDT {c.numero}/{c.esercizio}
                      </span>
                      <span className="flex-1 text-xs text-zinc-600 dark:text-zinc-300">
                        {c.origine}: {c.errore}
                      </span>
                      {c.azioni.includes("rinumera") && (
                        <button type="button" className="pulsante-primario" disabled={inCorso === c.ddt} onClick={() => void rinumera(c.ddt)}>
                          Rinumera
                        </button>
                      )}
                    </li>
                  ))}
                </ul>
              )}
            </section>
          </>
        )}
      </div>
    </div>
  );
}

function Riquadro({ titolo, children }: { titolo: string; children: React.ReactNode }) {
  return (
    <div className="rounded-xl border border-zinc-200 bg-white/70 p-4 text-sm dark:border-zinc-800 dark:bg-zinc-900/50">
      <h3 className="etichetta mb-2">{titolo}</h3>
      {children}
    </div>
  );
}

function Voce({ nome, valore }: { nome: string; valore: string }) {
  return (
    <div className="flex justify-between gap-4 py-0.5">
      <span className="text-zinc-500">{nome}</span>
      <span className="cifre text-right">{valore}</span>
    </div>
  );
}
