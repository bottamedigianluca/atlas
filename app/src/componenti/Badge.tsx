// Badge a pillola dello stato in Arca (direttiva §3.6): verde sincronizzato, blu in coda, rosso
// errore.

import type { StatoArca } from "../api/tipi";
import type { Semaforo } from "../sincronizzazione/contesto";

const COLORI = {
  verde: "bg-emerald-500/12 text-emerald-700 ring-emerald-500/30 dark:text-emerald-300",
  blu: "bg-sky-500/12 text-sky-700 ring-sky-500/30 dark:text-sky-300",
  rosso: "bg-rose-500/12 text-rose-700 ring-rose-500/30 dark:text-rose-300",
  grigio: "bg-zinc-500/10 text-zinc-600 ring-zinc-500/25 dark:text-zinc-300",
};

const PUNTI = {
  verde: "bg-emerald-500",
  blu: "bg-sky-500",
  rosso: "bg-rose-500",
  grigio: "bg-zinc-400",
};

type Colore = keyof typeof COLORI;

export function Pillola({ colore, children, pulsa = false }: { colore: Colore; children: React.ReactNode; pulsa?: boolean }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-[11px] font-medium ring-1 ring-inset ${COLORI[colore]}`}
    >
      <span className={`size-1.5 rounded-full ${PUNTI[colore]} ${pulsa ? "animate-pulse" : ""}`} />
      {children}
    </span>
  );
}

const STATI_DOCUMENTO: Record<StatoArca, [Colore, string]> = {
  in_arca: ["verde", "In Arca"],
  in_coda: ["blu", "In coda"],
  errore: ["rosso", "Errore"],
  solo_atlas: ["grigio", "Solo ATLAS"],
};

export function BadgeArca({ stato }: { stato: StatoArca }) {
  const [colore, testo] = STATI_DOCUMENTO[stato];
  return <Pillola colore={colore}>{testo}</Pillola>;
}

const SEMAFORI: Record<Semaforo, [Colore, string]> = {
  sincronizzato: ["verde", "Arca sincronizzata"],
  in_coda: ["blu", "Replica in corso"],
  errore: ["rosso", "Sincronizzazione ferma"],
  scollegato: ["rosso", "Server non raggiungibile"],
  senza_arca: ["grigio", "Arca non configurata"],
};

export function BadgeSemaforo({ semaforo }: { semaforo: Semaforo }) {
  const [colore, testo] = SEMAFORI[semaforo];
  return (
    <Pillola colore={colore} pulsa={semaforo === "in_coda"}>
      {testo}
    </Pillola>
  );
}
