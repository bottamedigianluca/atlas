// Testata del documento come nella maschera di Arca (`docs/screenshot_arca/01_…`): una fila con
// Tipo, Cliente, Data, Numero, Valuta, Cambio e, a destra, il riquadro con ragione sociale,
// indirizzo e codice destinatario in rosso. La destinazione (`txtCFDest`) compare quando il
// cliente ne ha.
//
// Nel DDT nuovo si battono Cliente (F3 ricerca), Data, Numero (F3 numeri liberi; vuoto = il
// prossimo) e Destinazione (F3). `Invio` sul cliente porta alla destinazione, se c'è, e poi
// alle righe; sulla data porta al numero, sul numero alle righe.

import type { KeyboardEvent, ReactNode } from "react";
import { Campo } from "./campi";
import type { VistaDocumento } from "./vista";

export interface CampiTestata {
  numero: string;
  /** Come la batte l'operatore: GG-MM-AAAA. */
  data: string;
  cliente: string;
  destinazione: string;
}

/** GG-MM-AAAA (anche con / o senza separatori, anno a 2 cifre) → AAAA-MM-GG; `null` se non è una data. */
export function dataIso(testo: string): string | null {
  const cifre = testo.trim().match(/^(\d{1,2})[-/.]?(\d{1,2})[-/.]?(\d{2}|\d{4})$/);
  if (!cifre) return null;
  const [, g, m, a] = cifre;
  const anno = a!.length === 2 ? `20${a}` : a!;
  const iso = `${anno}-${m!.padStart(2, "0")}-${g!.padStart(2, "0")}`;
  const d = new Date(`${iso}T00:00:00`);
  return Number.isNaN(d.getTime()) || d.getDate() !== Number(g) ? null : iso;
}

interface Props {
  vista: VistaDocumento;
  /** Valori battuti (solo DDT nuovo). */
  campi?: CampiTestata;
  /** Il cliente ha destinazioni: il campo compare. */
  conDestinazioni?: boolean;
  onCampo?: (campo: keyof CampiTestata, valore: string) => void;
  onTasto?: (campo: keyof CampiTestata, e: KeyboardEvent<HTMLInputElement>) => void;
  onFuoco?: () => void;
  stato?: ReactNode;
}

export function Testata({ vista, campi, conDestinazioni = false, onCampo, onTasto, onFuoco, stato }: Props) {
  const modifica = !!campi;
  const props = (campo: keyof CampiTestata) =>
    modifica
      ? {
          id: `testata-${campo}`,
          value: campi[campo],
          onChange: (e: React.ChangeEvent<HTMLInputElement>) => onCampo?.(campo, e.target.value),
          onKeyDown: (e: KeyboardEvent<HTMLInputElement>) => onTasto?.(campo, e),
          onFocus: onFuoco,
        }
      : {
          readOnly: true,
          value: campo === "data" ? vista.data.split("-").reverse().join("-") : String(vista[campo] ?? ""),
        };
  const dataErrata = modifica && campi.data.trim() !== "" && dataIso(campi.data) === null;
  const mostraDestinazione = conDestinazioni || !!vista.destinazione;

  return (
    <section aria-label="Testata del documento" className="flex items-stretch gap-3 border-b border-zinc-200 px-3 py-1.5 dark:border-zinc-800">
      <div className="flex items-end gap-2">
        <Campo etichetta="Tipo" readOnly value="BO" larghezza={40} tabIndex={-1} className="text-center font-semibold" />
        <Campo etichetta="Cliente" tasto={modifica ? "F3" : undefined} larghezza={96} className="font-mono font-semibold uppercase" {...props("cliente")} />
        <Campo
          etichetta="Data"
          larghezza={92}
          placeholder="GG-MM-AAAA"
          aria-invalid={dataErrata || undefined}
          className={`cifre ${dataErrata ? "border-rose-500 text-rose-600" : ""}`}
          {...props("data")}
        />
        <Campo etichetta="Numero" tasto={modifica ? "F3" : undefined} numerico larghezza={84} placeholder={modifica ? "auto" : ""} inputMode="numeric" {...props("numero")} />
        <Campo etichetta="Valuta" readOnly value="EUR" larghezza={46} tabIndex={-1} />
        <Campo etichetta="Cambio" readOnly value="1.000000" numerico larghezza={76} tabIndex={-1} />
        {mostraDestinazione && (
          <Campo
            etichetta="Destinazione"
            tasto={modifica ? "F3" : undefined}
            larghezza={92}
            className="font-mono uppercase"
            {...props("destinazione")}
          />
        )}
      </div>
      {/* Riquadro anagrafico in rosso, come in Arca. */}
      <div className="min-w-0 flex-1 rounded-md border border-zinc-300 px-2 py-1 text-[11.5px] leading-tight text-[#c0161e] dark:border-zinc-700 dark:text-[#ff6b6b]">
        <div className="truncate font-semibold" data-prova="ragione-sociale">
          {vista.ragioneSociale || " "}
        </div>
        <div className="truncate">{vista.indirizzo || " "}</div>
        <div className="truncate">
          {vista.codiceDestinatario !== null ? `Codice Destinatario: ${vista.codiceDestinatario}` : " "}
          {vista.descrizioneDestinazione && <span className="ml-3">Destinazione: {vista.descrizioneDestinazione}</span>}
        </div>
      </div>
      {stato && <div className="flex w-44 shrink-0 flex-col items-end justify-center gap-1 text-[11px]">{stato}</div>}
    </section>
  );
}
