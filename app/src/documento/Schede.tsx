// Schede della pagina Generale come in Arca (`fedi_doc`, pageframe di `pgGenerale`): Testa,
// Righe, Piede, Totali, Info, Evasioni, Stampe. Righe è quella aperta all'avvio. Qui le schede di
// sola consultazione; le righe sono la griglia.
//
// I campi che Arca lascia modificare e che ATLAS ancora non salva (pagamento diverso da quello del
// cliente, sconto cassa, dati del piede…) si vedono al loro posto in sola lettura, con i valori che
// ATLAS registra.

import { CampoCodice, Campo, Riquadro, Spunta } from "./campi";
import { data as fData, importo, mostra, quantita as fQuantita } from "../griglia/numeri";
import { PIEDE_BO, type VistaDocumento, merceAConto, somma } from "./vista";

export const SCHEDE = ["Testa", "Righe", "Piede", "Totali", "Info", "Evasioni", "Stampe"] as const;
export type Scheda = (typeof SCHEDE)[number];

export function BarraSchede({ attiva, onScheda }: { attiva: Scheda; onScheda: (s: Scheda) => void }) {
  return (
    <div role="tablist" aria-label="Schede del documento" className="flex gap-0.5 border-b border-zinc-200 px-3 dark:border-zinc-800">
      {SCHEDE.map((s) => (
        <button
          key={s}
          type="button"
          role="tab"
          aria-selected={attiva === s}
          tabIndex={-1}
          onClick={() => onScheda(s)}
          className={`-mb-px rounded-t-md border px-3 py-1 text-[12px] font-medium ${
            attiva === s
              ? "border-zinc-200 border-b-white bg-white text-zinc-900 dark:border-zinc-800 dark:border-b-zinc-950 dark:bg-zinc-950 dark:text-white"
              : "border-transparent text-zinc-500 hover:text-zinc-800 dark:text-zinc-400 dark:hover:text-zinc-200"
          }`}
        >
          {s}
        </button>
      ))}
      <span className="ml-auto self-center text-[10px] text-zinc-400">
        <kbd className="tasto">Ctrl</kbd>+<kbd className="tasto">PgSu</kbd>/<kbd className="tasto">PgGiù</kbd> scheda
      </span>
    </div>
  );
}

const vuoto = (v: string | null | undefined) => v ?? "";

export function SchedaTesta({ vista }: { vista: VistaDocumento }) {
  return (
    <div className="grid content-start gap-3 overflow-auto p-3 lg:grid-cols-2">
      <Riquadro titolo="Pagamento">
        <CampoCodice etichetta="Pagamento" readOnly value={vuoto(vista.pagamento)} descrizione={vista.descrizionePagamento} larghezza={330} />
        <Campo etichetta="Data pag." readOnly value="" larghezza={90} />
        <CampoCodice etichetta="Agente" readOnly value={vuoto(vista.agente)} descrizione={vista.descrizioneAgente} larghezza={330} />
        <Campo etichetta="Sconto cassa" readOnly value="" larghezza={90} numerico />
      </Riquadro>
      <Riquadro titolo="Listino e fatturazione">
        <CampoCodice etichetta="Listino" readOnly value={vuoto(vista.listino)} descrizione={vista.descrizioneListino} larghezza={330} />
        <CampoCodice etichetta="Cliente fatturazione" readOnly value={vista.cliente} descrizione={vista.ragioneSociale} larghezza={330} />
        <Campo etichetta="Numero / Data rif." readOnly value="" larghezza={200} />
      </Riquadro>
      <Riquadro titolo="Dati contabili">
        <Campo etichetta="IBAN" readOnly value={vuoto(vista.iban)} larghezza={250} className="font-mono" />
        <Campo etichetta="BIC" readOnly value={vuoto(vista.bic)} larghezza={110} className="font-mono" />
        <CampoCodice etichetta="Reverse charge" readOnly value="" larghezza={220} larghezzaCodice={50} />
        <div className="flex gap-4 pb-0.5">
          <Spunta etichetta="IVA sospesa" attiva={false} />
          <Spunta etichetta="Split payment" attiva={vista.scissione} />
        </div>
      </Riquadro>
      <Riquadro titolo="Varie">
        <Campo etichetta="Data consegna" readOnly value="" larghezza={100} />
        <CampoCodice etichetta="Sottocommessa" readOnly value="" larghezza={250} larghezzaCodice={70} />
      </Riquadro>
      <Riquadro titolo="Stato">
        <Spunta etichetta="Esecutivo" attiva />
        <Spunta etichetta="Prelevabile" attiva />
        <Spunta etichetta="Modificabile" attiva />
      </Riquadro>
    </div>
  );
}

export function SchedaPiede({ vista }: { vista: VistaDocumento }) {
  const trasporto = vista.inizioTrasporto ? `${fData(vista.inizioTrasporto.slice(0, 10))} ${vista.inizioTrasporto.slice(11, 16)}`.trim() : "";
  const lordo = somma(vista.righe.map((r) => r.lordo || null), 3);
  const netto = somma(vista.righe.map((r) => r.quantita), 3);
  const colli = somma(vista.righe.map((r) => r.colli || null), 0);
  return (
    <div className="grid content-start gap-3 overflow-auto p-3 lg:grid-cols-2">
      <Riquadro titolo="Dati DDT">
        <Campo etichetta="Trasporto" readOnly value={PIEDE_BO.trasporto} larghezza={70} />
        <Campo etichetta="Vettore 1" readOnly value="" larghezza={110} />
        <Campo etichetta="Vettore 2" readOnly value="" larghezza={110} />
        <Campo etichetta="Spedizione" readOnly value={PIEDE_BO.spedizione} larghezza={70} />
        <Campo etichetta="Porto" readOnly value={PIEDE_BO.porto} larghezza={70} />
        <Campo etichetta="Aspetto beni" readOnly value={PIEDE_BO.aspettoBeni} larghezza={80} />
        <Campo etichetta="Data/ora trasporto" readOnly value={trasporto} larghezza={140} className="cifre" />
        <Campo etichetta="Peso lordo" readOnly value="0.00" larghezza={90} numerico title={`Σ righe: ${fQuantita(lordo)}`} />
        <Campo etichetta="Peso netto" readOnly value="0.00" larghezza={90} numerico title={`Σ righe: ${fQuantita(netto)}`} />
        <Campo etichetta="Volume" readOnly value="" larghezza={80} numerico />
        <Campo etichetta="Colli" readOnly value="0.00" larghezza={70} numerico title={`Σ righe: ${colli}`} />
        <p className="w-full text-[11px] text-zinc-500">
          Somma delle righe: lordo {fQuantita(lordo)} · netto {fQuantita(netto)} · colli {colli}. Nei BO di Arca peso e colli
          del piede restano a zero.
        </p>
      </Riquadro>
      <Riquadro titolo="Spese">
        <table className="w-full text-[12px]">
          <thead className="text-[11px] text-zinc-500">
            <tr>
              <th className="text-left font-medium">Tipo</th>
              <th className="text-left font-medium">Descrizione</th>
              <th className="text-right font-medium">Importo</th>
              <th className="text-left font-medium">IVA</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td colSpan={4} className="py-1 text-zinc-400">
                Nessuna spesa
              </td>
            </tr>
          </tbody>
        </table>
        <Campo etichetta="Acconto" readOnly value="0.00" larghezza={100} numerico />
      </Riquadro>
    </div>
  );
}

function Tabella({ titolo, intestazioni, righe }: { titolo: string; intestazioni: string[]; righe: (string | null)[][] }) {
  return (
    <section aria-label={titolo} className="overflow-hidden rounded-lg border border-zinc-200 dark:border-zinc-800">
      <h3 className="bg-zinc-100 px-3 py-1 text-[11px] font-semibold text-zinc-600 dark:bg-zinc-900 dark:text-zinc-300">{titolo}</h3>
      <table className="w-full text-[12px]">
        <thead className="text-[11px] text-zinc-500">
          <tr>
            {intestazioni.map((t, i) => (
              <th key={t} className={`px-3 py-0.5 font-medium ${i === 0 ? "text-left" : "text-right"}`}>
                {t}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="cifre">
          {righe.length === 0 && (
            <tr>
              <td colSpan={intestazioni.length} className="px-3 py-1 font-sans text-zinc-400">
                —
              </td>
            </tr>
          )}
          {righe.map((r, i) => (
            <tr key={i} className="border-t border-zinc-100 dark:border-zinc-900">
              {r.map((c, j) => (
                <td key={j} className={`px-3 py-0.5 ${j === 0 ? "text-left font-sans" : "text-right"}`}>
                  {c}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}

export function SchedaTotali({ vista }: { vista: VistaDocumento }) {
  const c = vista.castelletto;
  const merce = merceAConto(vista);
  return (
    <div className="grid max-w-3xl content-start gap-3 overflow-auto p-3">
      <Tabella
        titolo="Totali"
        intestazioni={["Voce", "Importo"]}
        righe={[
          ["Totale merce", importo(somma(merce.map((m) => m.importo)))],
          ["Spese", importo("0")],
          ["Imponibile", importo(c?.totale_imponibile ?? "0")],
          ["Imposta", importo(c?.totale_imposta ?? "0")],
          ["Totale documento", importo(c?.totale_documento ?? "0")],
          ["Acconto", importo("0")],
          ["Abbuono", importo("0")],
          ["Netto a pagare", importo(vista.nettoAPagare ?? "0")],
        ]}
      />
      <Tabella titolo="Merce" intestazioni={["Conto", "Imponibile"]} righe={merce.map((m) => [m.conto, importo(m.importo)])} />
      <Tabella
        titolo="IVA"
        intestazioni={["Aliquota", "%", "Imponibile", "Imposta"]}
        righe={(c?.righe ?? []).map((r) => [r.aliquota, mostra(r.percentuale, 2), importo(r.imponibile), importo(r.imposta)])}
      />
      <Tabella titolo="Provvigioni" intestazioni={["Agente", "Imponibile", "Provvigione"]} righe={[]} />
    </div>
  );
}

export function SchedaInfo({ vista }: { vista: VistaDocumento }) {
  const voci: [string, string][] = [
    ["Tipo documento", "BO — BOLLA VENDITA"],
    ["Sezionale", "D00"],
    ["Esercizio", vista.data.slice(0, 4)],
    ["Inserito da", vista.operatore ?? "—"],
    ["Inserito il", vista.registratoIl?.replace("T", " ") ?? "—"],
    ["Id ATLAS", vista.idAtlas ? String(vista.idAtlas) : "—"],
    ["Id_DoTes in Arca", vista.arcaIdTestata ? String(vista.arcaIdTestata) : "—"],
  ];
  return (
    <div className="grid content-start gap-3 overflow-auto p-3 lg:grid-cols-2">
      <Riquadro titolo="Documento">
        <dl className="grid w-full grid-cols-[10rem_1fr] gap-y-0.5 text-[12px]">
          {voci.map(([n, v]) => [
            <dt key={`${n}-n`} className="text-zinc-500">
              {n}
            </dt>,
            <dd key={`${n}-v`} className="cifre">
              {v}
            </dd>,
          ])}
        </dl>
      </Riquadro>
      <Riquadro titolo="Replica in Arca">
        <div className="w-full space-y-0.5 text-[12px]">
          {vista.eventi.length === 0 && <p className="text-zinc-400">{vista.nuovo ? "Al salvataggio" : "—"}</p>}
          {vista.eventi.map((e) => (
            <p key={e.id}>
              {e.operazione}: {e.replicato_il ? `scritto il ${e.replicato_il.replace("T", " ")}` : "in coda"}
              {e.ultimo_errore && <span className="ml-2 text-rose-600">({e.tentativi} tentativi: {e.ultimo_errore})</span>}
            </p>
          ))}
        </div>
      </Riquadro>
    </div>
  );
}

export function SchedaEvasioni() {
  return <p className="p-4 text-[12px] text-zinc-500">Nessun documento evade questo DDT (fatturazione differita con il Task 7).</p>;
}

export function SchedaStampe() {
  return (
    <div className="p-4 text-[12px] text-zinc-500">
      <p>
        Modulo di stampa del BO: <b className="font-mono">xDDT</b> (modello Tecnobit in <code>docs/modelli_stampa_arca</code>).
      </p>
      <p>Stampa in PDF con il Task 7.</p>
    </div>
  );
}
