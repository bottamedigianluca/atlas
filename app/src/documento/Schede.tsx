// Schede della pagina Generale come in Arca (`fedi_doc`, pageframe di `pgGenerale`): Testa,
// Righe, Piede, Totali, Info, Evasioni, Stampe. Righe è quella aperta all'avvio. Qui le schede di
// sola consultazione; le righe sono la griglia.
//
// I campi che Arca lascia modificare e che ATLAS ancora non salva (pagamento diverso da quello del
// cliente, sconto cassa, dati del piede…) si vedono al loro posto in sola lettura, con i valori che
// ATLAS registra.

import { Riquadro, Sezione, Spunta, Voce } from "./campi";
import { data as fData, importo, mostra } from "../griglia/numeri";
import { PIEDE_BO, type VistaDocumento, merceAConto, somma } from "./vista";

export const SCHEDE = ["Testa", "Righe", "Piede", "Totali", "Info", "Evasioni", "Stampe"] as const;
export type Scheda = (typeof SCHEDE)[number];

export function BarraSchede({ attiva, onScheda }: { attiva: Scheda; onScheda: (s: Scheda) => void }) {
  return (
    <div role="tablist" aria-label="Schede del documento" title="Ctrl+PgSu / Ctrl+PgGiù: scheda precedente / successiva" className="flex gap-0.5">
      {SCHEDE.map((s) => (
        <button
          key={s}
          type="button"
          role="tab"
          aria-selected={attiva === s}
          tabIndex={-1}
          onClick={() => onScheda(s)}
          className={`-mb-px rounded-t-md border px-2.5 py-0.5 text-[12px] font-medium ${
            attiva === s
              ? "border-zinc-200 border-b-white bg-white text-zinc-900 dark:border-zinc-800 dark:border-b-zinc-950 dark:bg-zinc-950 dark:text-white"
              : "border-transparent text-zinc-500 hover:text-zinc-800 dark:text-zinc-400 dark:hover:text-zinc-200"
          }`}
        >
          {s}
        </button>
      ))}
    </div>
  );
}

const vuoto = (v: string | null | undefined) => v ?? "";

export function SchedaTesta({ vista }: { vista: VistaDocumento }) {
  // Come la scheda Testa di Arca: pagamento, dati contabili e riferimenti a sinistra; altri dati,
  // fatturare a, stato e listini a destra.
  return (
    <div className="flex min-h-0 flex-1 justify-between gap-8 overflow-auto px-3 py-2">
      <div className="flex flex-col gap-3">
        <Sezione titolo="Condizioni di pagamento">
          <Voce
            etichetta="Agenti"
            valore={vuoto(vista.agente)}
            larghezza={50}
            dopo={<Vuoto larghezza={50} />}
            descrizione={vista.descrizioneAgente ? `/ ${vista.descrizioneAgente}` : "/"}
          />
          <Voce etichetta="Pagamento" valore={vuoto(vista.pagamento)} larghezza={50} descrizione={vista.descrizionePagamento} />
          <Voce etichetta="Sconto Cassa" valore="" />
        </Sezione>
        <Sezione titolo="Dati contabili">
          <Voce etichetta="Tipo Fattura" valore="" larghezza={40} />
          <Voce
            etichetta="Banca C/F"
            valore={vuoto(vista.iban)}
            larghezza={270}
            dopo={
              <>
                <span className="ml-1 text-zinc-600 dark:text-zinc-400">BIC</span>
                <Vuoto larghezza={90} valore={vuoto(vista.bic)} />
              </>
            }
          />
          <Voce etichetta="Banca di Sconto" valore={vuoto(vista.contoBanca)} larghezza={84} title={vista.nuovo ? "La propone il backend al salvataggio" : undefined} />
          {vista.scissione && <Spunta etichetta="Split payment (scissione dei pagamenti)" attiva />}
        </Sezione>
        <Sezione titolo="Riferimenti">
          <Voce etichetta="Numero / Data" valore="" larghezza={130} dopo={<Vuoto larghezza={64} />} />
        </Sezione>
      </div>
      <div className="flex shrink-0 flex-col gap-3">
        <Sezione titolo="Altri dati">
          <Voce etichetta="Zona" valore="" larghezza={36} colonnaEtichetta={84} />
          <Voce etichetta="Consegna" valore="" larghezza={64} colonnaEtichetta={84} descrizione={<span className="text-zinc-500">dal</span>} />
          <Voce etichetta="Sottocommessa" valore="" larghezza={100} colonnaEtichetta={84} />
        </Sezione>
        <Sezione titolo="Fatturare a">
          <Voce etichetta="" valore="" larghezza={56} colonnaEtichetta={0} />
        </Sezione>
        <div className="flex gap-6">
          <Sezione titolo="Stato">
            <Spunta etichetta="Modificabile" attiva />
            <Spunta etichetta="Esecutivo" attiva />
            <Spunta etichetta="Prelevabile" attiva />
          </Sezione>
          <Sezione titolo="Listini">
            <Voce etichetta="" valore={vuoto(vista.listino)} larghezza={64} colonnaEtichetta={0} descrizione={vista.descrizioneListino} />
            {/* `Cd_LS_2` dei BO: il listino 1 su tutti i documenti. */}
            <Voce etichetta="" valore="0000001" larghezza={64} colonnaEtichetta={0} descrizione="Listino 1" />
          </Sezione>
        </div>
      </div>
    </div>
  );
}

function Vuoto({ larghezza, valore = "" }: { larghezza: number; valore?: string }) {
  return (
    <input
      readOnly
      tabIndex={-1}
      value={valore}
      aria-hidden
      style={{ width: larghezza }}
      className="h-[20px] shrink-0 rounded-md border border-zinc-200 bg-zinc-50 px-1.5 text-[12px] text-zinc-700 outline-none dark:border-zinc-800 dark:bg-zinc-900/60 dark:text-zinc-300"
    />
  );
}

/** Descrizioni dei codici del piede come le mostra Arca accanto al campo. */
const DESCRIZIONI_PIEDE = { V: "Vendita", M: "Mittente", F: "FRANCO", AV: "A vista" } as const;

function Somma({ valore }: { valore: string }) {
  return (
    <span className="cursor-help text-[13px] text-zinc-500" title={`Σ righe: ${valore}. Nei BO di Arca il piede resta a zero.`} aria-label={`Somma delle righe ${valore}`}>
      Σ
    </span>
  );
}

const COLONNE_SPESE = [
  ["N. Spesa", 86],
  ["Descrizione Spesa", 106],
  ["Importo", 84],
  ["%", 44],
  ["IVA", 22],
  ["Conto", 72],
  ["RC", 32],
  ["Importo Evadibile", 76],
  ["Importo Evaso", 76],
  ["Sottocommessa", 72],
  ["Riga Evasa", 78],
] as const;

export function SchedaPiede({ vista }: { vista: VistaDocumento }) {
  // Come la scheda Piede di Arca: dati per la spedizione (codici a sinistra e al centro, pesi a
  // destra), poi dati per la fatturazione con la griglia delle spese, in fondo acconto e abbuono.
  const trasporto = vista.inizioTrasporto ? `${fData(vista.inizioTrasporto.slice(0, 10))} ${vista.inizioTrasporto.slice(11, 16)}`.trim() : "";
  const lordo = somma(vista.righe.map((r) => r.lordo || null), 3);
  const netto = somma(vista.righe.map((r) => r.quantita), 3);
  const colli = somma(vista.righe.map((r) => r.colli || null), 0);
  return (
    <div className="flex min-h-0 flex-1 flex-col gap-2 overflow-auto px-3 py-2">
      <Sezione titolo="Dati per la spedizione">
        <div className="flex justify-between gap-6">
          <div className="flex gap-6">
            <div className="flex flex-col gap-1">
              <Voce
                etichetta="Trasporto"
                valore={PIEDE_BO.trasporto}
                larghezza={30}
                colonnaEtichetta={118}
                dopo={<Vuoto larghezza={110} valore={trasporto} />}
                descrizione={DESCRIZIONI_PIEDE[PIEDE_BO.trasporto]}
              />
              <Voce etichetta="Vettore 1" valore="" larghezza={30} colonnaEtichetta={118} dopo={<Vuoto larghezza={110} />} />
              <Voce etichetta="Vettore 2" valore="" larghezza={30} colonnaEtichetta={118} dopo={<Vuoto larghezza={110} />} />
              <Voce etichetta="Caricatore/Committ." valore="" larghezza={30} colonnaEtichetta={118} dopo={<Vuoto larghezza={30} />} />
              <Voce etichetta="Luogo carico/scar." valore="" larghezza={30} colonnaEtichetta={118} dopo={<Vuoto larghezza={30} />} />
              <Voce etichetta="Proprietario merce" valore="" larghezza={30} colonnaEtichetta={118} descrizione={<span className="text-zinc-500">Altro SdT</span>} />
            </div>
            {/* Spedizione, porto e aspetto dei beni accanto alle ultime tre righe, come in Arca. */}
            <div className="flex flex-col justify-end gap-1">
              <Voce etichetta="Spedizione" valore={PIEDE_BO.spedizione} larghezza={30} colonnaEtichetta={66} descrizione={DESCRIZIONI_PIEDE[PIEDE_BO.spedizione]} />
              <Voce etichetta="Porto" valore={PIEDE_BO.porto} larghezza={30} colonnaEtichetta={66} descrizione={DESCRIZIONI_PIEDE[PIEDE_BO.porto]} />
              <Voce etichetta="Asp. Beni" valore={PIEDE_BO.aspettoBeni} larghezza={30} colonnaEtichetta={66} descrizione={DESCRIZIONI_PIEDE[PIEDE_BO.aspettoBeni]} />
            </div>
          </div>
          <div className="flex flex-col items-end gap-1">
            <Voce etichetta="Peso Lordo (Kg)" valore="0.000" numerico larghezza={76} colonnaEtichetta={96} dopo={<Somma valore={mostra(lordo, 3)} />} />
            <Voce etichetta="Peso Netto (Kg)" valore="0.000" numerico larghezza={76} colonnaEtichetta={96} dopo={<Somma valore={mostra(netto, 3)} />} />
            <Voce etichetta="Volume (m³)" valore="0.000" numerico larghezza={76} colonnaEtichetta={96} dopo={<span className="w-[9px]" />} />
            <Voce etichetta="Colli" valore="0" numerico larghezza={76} colonnaEtichetta={96} dopo={<Somma valore={colli} />} />
          </div>
        </div>
      </Sezione>
      <Sezione titolo="Dati per la fatturazione" className="flex min-h-[10rem] flex-1 flex-col">
        <div className="flex min-h-0 flex-1 flex-col overflow-hidden rounded-md border border-zinc-200 dark:border-zinc-800" role="grid" aria-label="Spese">
          <div className="flex border-b border-zinc-300 bg-zinc-50 text-[11px] font-medium text-zinc-600 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-400" role="row">
            {COLONNE_SPESE.map(([t, w]) => (
              <span key={t} role="columnheader" style={{ width: w }} className="shrink-0 truncate border-r border-zinc-200 px-1 py-0.5 dark:border-zinc-800">
                {t}
              </span>
            ))}
          </div>
          <div className="flex flex-1" aria-hidden>
            {COLONNE_SPESE.map(([t, w]) => (
              <span key={t} style={{ width: w }} className="shrink-0 border-r border-zinc-100 dark:border-zinc-900" />
            ))}
          </div>
        </div>
      </Sezione>
      <div className="flex items-center justify-between">
        <div className="flex gap-4">
          <Voce etichetta="Acconto %" valore="0.00" numerico larghezza={50} colonnaEtichetta={64} />
          <Voce etichetta="Fisso" valore="0.00" numerico larghezza={76} colonnaEtichetta={34} />
          <Voce etichetta="Abbuono" valore="0.00" numerico larghezza={76} colonnaEtichetta={54} />
        </div>
        <Spunta etichetta="Bolli per esenzione" attiva={false} />
      </div>
    </div>
  );
}

export function SchedaTotali({ vista }: { vista: VistaDocumento }) {
  // Come la scheda Totali di Arca: "Valori in EUR" netto e lordo a sinistra, sconti, omaggi,
  // abbuono, acconto e netto a pagare a destra; sotto, in più, il riepilogo IVA.
  const c = vista.castelletto;
  const merce = somma(merceAConto(vista).map((m) => m.importo));
  const esente = somma((c?.righe ?? []).filter((r) => Number(r.percentuale) === 0).map((r) => r.imponibile));
  const zero = importo("0");
  const sinistra: [string, string, string][] = [
    ["Merce", importo(merce), importo(merce)],
    ["Spese", zero, ""],
    ["", "", "di cui esente"],
    ["Imponibile", importo(c?.totale_imponibile ?? "0"), importo(esente)],
    ["Imposta", importo(c?.totale_imposta ?? "0"), ""],
    ["", "", ""],
    ["Totale", importo(c?.totale_documento ?? "0"), ""],
  ];
  const destra: [string, string][] = [
    ["Sconto", zero],
    ["Omaggio merce", zero],
    ["Omaggio IVA", zero],
    ["Abbuono", zero],
    ["Rit. Cond.", zero],
    ["Acconto", zero],
    ["Netto a pagare", importo(vista.nettoAPagare ?? "0")],
  ];
  return (
    <div className="flex min-h-0 flex-1 gap-2 overflow-auto px-3 py-2">
      <span className="self-center text-[12px] font-bold tracking-widest text-primario-testo [writing-mode:vertical-rl] rotate-180">TOTALI</span>
      <section aria-label="Totali" className="flex-1 rounded-md border border-zinc-200 p-3 dark:border-zinc-800">
        <div className="flex gap-10 text-[12px]">
          <table className="cifre">
            <thead>
              <tr className="text-[11px] italic text-zinc-500">
                <th className="pr-6 text-left font-sans font-semibold not-italic text-primario-testo">Valori in EUR</th>
                <th className="w-20 text-right font-normal">Netto</th>
                <th className="w-24 text-right font-normal">Lordo</th>
              </tr>
            </thead>
            <tbody>
              {sinistra.map(([voce, netto, lordo], i) => (
                <tr key={i} className="h-[18px]">
                  <td className="pr-6 font-sans italic text-zinc-600 dark:text-zinc-400">{voce}</td>
                  <td className={`text-right ${voce === "Totale" ? "font-semibold" : ""}`}>{netto}</td>
                  <td className={`text-right ${lordo === "di cui esente" ? "font-sans text-[11px] italic text-zinc-500" : ""}`}>{lordo}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <table className="cifre self-start">
            <tbody>
              <tr className="h-[18px]">
                <td colSpan={2} />
              </tr>
              {destra.map(([voce, valore]) => (
                <tr key={voce} className="h-[18px]">
                  <td className="pr-6 font-sans italic text-zinc-600 dark:text-zinc-400">{voce}</td>
                  <td className={`w-20 text-right ${voce === "Netto a pagare" ? "font-semibold" : ""}`}>{valore}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="mt-5 max-w-xl">
          <Tabella
            titolo="Riepilogo IVA"
            intestazioni={["Aliquota", "%", "Imponibile", "Imposta"]}
            righe={(c?.righe ?? []).map((r) => [r.aliquota, mostra(r.percentuale, 2), importo(r.imponibile), importo(r.imposta)])}
          />
        </div>
      </section>
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
