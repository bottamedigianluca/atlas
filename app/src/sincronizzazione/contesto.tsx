// Stato della sincronizzazione con Arca, condiviso dall'app: canale WebSocket per le notifiche,
// `GET /api/stato` per la fotografia completa (coda e conflitti) a ogni notifica.

import { createContext, type ReactNode, useCallback, useContext, useEffect, useRef, useState } from "react";
import { api, ascoltaNotifiche } from "../api/client";
import type { Notifica, Stato } from "../api/tipi";

export type Semaforo = "sincronizzato" | "in_coda" | "errore" | "scollegato" | "senza_arca";

interface Sincronizzazione {
  collegato: boolean;
  stato: Stato | null;
  semaforo: Semaforo;
  ultimaNotifica: Notifica | null;
  aggiorna: () => void;
}

const Contesto = createContext<Sincronizzazione | null>(null);

export function semaforo(collegato: boolean, stato: Stato | null): Semaforo {
  if (!collegato || !stato) return "scollegato";
  const { replica, importazione } = stato.sincronizzazione;
  if (stato.conflitti.length > 0 || stato.coda.fermo || replica.errore || importazione.errore || importazione.fermo) {
    return "errore";
  }
  if (stato.coda.in_coda > 0) return replica.configurata ? "in_coda" : "senza_arca";
  return replica.configurata ? "sincronizzato" : "senza_arca";
}

export function ProviderSincronizzazione({ children }: { children: ReactNode }) {
  const [collegato, setCollegato] = useState(false);
  const [stato, setStato] = useState<Stato | null>(null);
  const [ultimaNotifica, setUltimaNotifica] = useState<Notifica | null>(null);
  const inCorso = useRef(false);
  const ancora = useRef(false);

  // Una lettura alla volta: le notifiche ravvicinate ne fanno al più un'altra.
  const aggiorna = useCallback(() => {
    if (inCorso.current) {
      ancora.current = true;
      return;
    }
    inCorso.current = true;
    api
      .stato()
      .then(setStato)
      .catch(() => setStato(null))
      .finally(() => {
        inCorso.current = false;
        if (ancora.current) {
          ancora.current = false;
          aggiorna();
        }
      });
  }, []);

  useEffect(
    () =>
      ascoltaNotifiche(
        (notifica) => {
          setUltimaNotifica(notifica);
          aggiorna();
        },
        (aperto) => {
          setCollegato(aperto);
          if (aperto) aggiorna();
        },
      ),
    [aggiorna],
  );

  return (
    <Contesto.Provider value={{ collegato, stato, semaforo: semaforo(collegato, stato), ultimaNotifica, aggiorna }}>
      {children}
    </Contesto.Provider>
  );
}

export function useSincronizzazione(): Sincronizzazione {
  const valore = useContext(Contesto);
  if (!valore) throw new Error("useSincronizzazione fuori da ProviderSincronizzazione");
  return valore;
}
