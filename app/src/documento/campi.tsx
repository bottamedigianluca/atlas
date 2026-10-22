// Campi della maschera documenti come quelli di Arca: etichetta sopra il campo (`Field.Top = 11`
// nei contenitori di `fedi_doc`), campo codice con la descrizione accanto (`fkhasdisplay`),
// riquadri con titolo per i contenitori (`cntPagamento`, `cntDatiContabili`…).

import { type InputHTMLAttributes, type ReactNode, forwardRef } from "react";

const BASE =
  "h-[22px] rounded-md border px-1.5 text-[12px] outline-none transition-colors " +
  "border-zinc-300 bg-white focus:border-anello focus:ring-2 focus:ring-anello/25 " +
  "dark:border-zinc-700 dark:bg-zinc-900 " +
  "read-only:border-zinc-200 read-only:bg-zinc-50 read-only:text-zinc-700 read-only:focus:ring-0 " +
  "dark:read-only:border-zinc-800 dark:read-only:bg-zinc-900/60 dark:read-only:text-zinc-300";

export const Campo = forwardRef<
  HTMLInputElement,
  { etichetta: ReactNode; larghezza?: number; numerico?: boolean; tasto?: string } & InputHTMLAttributes<HTMLInputElement>
>(function Campo({ etichetta, larghezza = 80, numerico = false, tasto, className, ...props }, ref) {
  return (
    <label className="flex flex-col gap-0.5" style={{ width: larghezza }}>
      <span className="flex items-center gap-1 truncate text-[11px] text-zinc-500 dark:text-zinc-400">
        {etichetta}
        {tasto && <kbd className="tasto">{tasto}</kbd>}
      </span>
      <input
        ref={ref}
        autoComplete="off"
        spellCheck={false}
        {...props}
        className={`${BASE} ${numerico ? "cifre text-right" : ""} ${className ?? ""}`}
      />
    </label>
  );
});

/** Codice e descrizione decodificata, come i campi di Arca con `fkhasdisplay`. */
export const CampoCodice = forwardRef<
  HTMLInputElement,
  {
    etichetta: ReactNode;
    descrizione?: ReactNode;
    larghezzaCodice?: number;
    larghezza?: number;
    tasto?: string;
  } & InputHTMLAttributes<HTMLInputElement>
>(function CampoCodice({ etichetta, descrizione, larghezzaCodice = 70, larghezza = 300, tasto, className, ...props }, ref) {
  return (
    <div className="flex flex-col gap-0.5" style={{ width: larghezza }}>
      <label htmlFor={props.id} className="flex items-center gap-1 truncate text-[11px] text-zinc-500 dark:text-zinc-400">
        {etichetta}
        {tasto && <kbd className="tasto">{tasto}</kbd>}
      </label>
      <div className="flex gap-1">
        <input
          ref={ref}
          autoComplete="off"
          spellCheck={false}
          {...props}
          style={{ width: larghezzaCodice }}
          className={`${BASE} shrink-0 font-mono uppercase ${className ?? ""}`}
        />
        <div className="flex h-[22px] min-w-0 flex-1 items-center truncate rounded-md border border-zinc-200 bg-zinc-50 px-1.5 text-[12px] text-zinc-700 dark:border-zinc-800 dark:bg-zinc-900/60 dark:text-zinc-300">
          {descrizione}
        </div>
      </div>
    </div>
  );
});

export function Spunta({ etichetta, attiva }: { etichetta: string; attiva: boolean }) {
  return (
    <label className="flex items-center gap-1.5 text-[12px]">
      <input type="checkbox" checked={attiva} readOnly tabIndex={-1} className="pointer-events-none accent-primario" />
      {etichetta}
    </label>
  );
}

export function Riquadro({ titolo, children, className }: { titolo: string; children: ReactNode; className?: string }) {
  return (
    <fieldset
      className={`rounded-lg border border-zinc-200 bg-white/70 px-3 pb-2.5 pt-1 dark:border-zinc-800 dark:bg-zinc-900/40 ${className ?? ""}`}
    >
      <legend className="px-1 text-[11px] font-semibold text-zinc-600 dark:text-zinc-300">{titolo}</legend>
      <div className="flex flex-wrap items-end gap-x-3 gap-y-1.5">{children}</div>
    </fieldset>
  );
}

/**
 * Campo delle schede Testa e Piede di Arca: etichetta a sinistra a larghezza fissa, il campo e,
 * accanto, la descrizione decodificata in evidenza ("R060 Ric.Banc. 60 gg DF FM", "V Vendita").
 */
export function Voce({
  etichetta,
  valore,
  larghezza = 70,
  colonnaEtichetta = 112,
  descrizione,
  numerico = false,
  dopo,
  title,
}: {
  etichetta: ReactNode;
  valore: string;
  larghezza?: number;
  colonnaEtichetta?: number;
  descrizione?: ReactNode;
  numerico?: boolean;
  /** Campi o pulsanti in più sulla stessa riga (secondo codice, Σ…). */
  dopo?: ReactNode;
  title?: string;
}) {
  return (
    <div className="flex h-[22px] items-center gap-1.5 text-[12px]" title={title}>
      <span className="shrink-0 truncate text-zinc-600 dark:text-zinc-400" style={{ width: colonnaEtichetta }}>
        {etichetta}
      </span>
      <input
        readOnly
        tabIndex={-1}
        value={valore}
        aria-label={typeof etichetta === "string" ? etichetta : undefined}
        style={{ width: larghezza }}
        className={`${BASE} h-[20px] shrink-0 ${numerico ? "cifre text-right" : ""}`}
      />
      {dopo}
      {descrizione && <span className="truncate text-primario-testo">{descrizione}</span>}
    </div>
  );
}

/** Titolo di sezione delle schede di Arca ("CONDIZIONI DI PAGAMENTO", "DATI PER LA SPEDIZIONE"). */
export function Sezione({ titolo, children, className }: { titolo: string; children?: ReactNode; className?: string }) {
  return (
    <section aria-label={titolo} className={className}>
      <h3 className="mb-1 text-[12px] font-bold uppercase tracking-wide text-primario-testo">{titolo}</h3>
      <div className="flex min-h-0 flex-1 flex-col gap-1">{children}</div>
    </section>
  );
}
