// Tasto F3 sul prezzo: la maschera "PREZZO/COSTO ARTICOLO" (`fastsrcform_arprezzo` di Arca,
// direttiva §3.1), ricalcata su `docs/screenshot_arca/04_…`: stesse colonne, stesse sezioni a
// barra grigia ("Dati da documento", "Prezzi da listino", "Ultimi prezzi da documenti"), stesse
// voci nello stesso ordine. `Freccia Su/Giù` scorrono le voci, `Invio` o `Spazio` riportano il
// prezzo nella riga del DDT.
//
// Come in Arca, Listino 1 e Listino 2 compaiono sempre (a 0.000 se l'articolo non c'è) e le voci
// "ultimo doc." senza documento restano in corsivo, vuote. In ATLAS l'unico tipo "bolla" è la
// bolla di vendita (BO): le voci "tipo Bolla" hanno gli stessi documenti delle voci "BOLLA
// VENDITA". L'ultimo acquisto resta vuoto finché ATLAS non ha documenti di acquisto. La BO non è
// ivata: "Prezzo Val Doc. Ivato" è il prezzo nella valuta del documento.

import { useEffect, useMemo, useRef, useState } from "react";
import { api } from "../api/client";
import type { Prezzi, VoceUltimo } from "../api/tipi";
import { Modale } from "../componenti/Modale";
import { data as fData, fattore as fFattore, mostra, prezzo as fPrezzo, quantita as fQuantita } from "../griglia/numeri";

export interface RichiestaF3 {
  articolo: string;
  cliente: string;
  data: string;
  unita_misura?: string;
  quantita?: string;
  /** Prezzo già nella riga: è quello della voce "Dati da documento". */
  prezzo?: string;
}

export interface Voce {
  chiave: string;
  sezione: "documento" | "listino" | "documenti";
  descrizione: string;
  icona: "listino" | "persona" | null;
  /** Voce senza dati (corsivo, solo il fattore a zero). */
  vuota: boolean;
  valuta: string;
  prezzoListino: string | null;
  prezzoDocumento: string | null;
  um: string;
  fattore: string;
  quantita: string | null;
  aliquota: string;
  sconto: string;
  /** Prezzo da riportare nella riga; `null` se la voce non si riporta. */
  riporta: string | null;
  proposta?: boolean;
}

const VUOTA = { valuta: "", prezzoListino: null, prezzoDocumento: null, um: "", fattore: "0", quantita: null, aliquota: "", sconto: "", riporta: null };

function riferimento(u: VoceUltimo): string {
  return `(${u.documento.tipo} / ${u.documento.cliente} del ${fData(u.documento.data)})`;
}

function daUltimo(u: VoceUltimo, descrizione: string, chiave: string): Voce {
  return {
    chiave,
    sezione: "documenti",
    descrizione,
    icona: "persona",
    vuota: false,
    valuta: "EUR",
    prezzoListino: u.prezzo,
    prezzoDocumento: u.prezzo_ivato ?? u.prezzo_riga,
    um: u.unita_misura,
    fattore: u.fattore,
    quantita: u.quantita,
    aliquota: u.percentuale_iva ?? u.aliquota,
    sconto: u.sconto,
    riporta: u.prezzo_riga,
  };
}

export function costruisciVoci(prezzi: Prezzi, prezzoRiga?: string): Voce[] {
  const doc = prezzi.documento;
  const corrente = prezzoRiga?.trim() ? prezzoRiga : "0";
  const voci: Voce[] = [
    {
      chiave: "documento",
      sezione: "documento",
      descrizione: `Articolo ${doc.articolo} doc. BO / ${doc.cliente ?? ""} del ${fData(doc.data)}`,
      icona: null,
      vuota: false,
      valuta: doc.valuta,
      prezzoListino: corrente,
      prezzoDocumento: corrente,
      um: doc.unita_misura,
      fattore: doc.fattore,
      quantita: doc.quantita ?? "0",
      aliquota: "",
      sconto: "",
      riporta: null,
    },
  ];

  for (const l of prezzi.listini) {
    voci.push({
      chiave: `listino-${l.listino}`,
      sezione: "listino",
      descrizione: [l.descrizione, l.descrizione_revisione].filter(Boolean).join(" - "),
      icona: "listino",
      vuota: false,
      valuta: "EUR",
      prezzoListino: l.prezzo_listino,
      prezzoDocumento: l.prezzo_documento,
      um: doc.unita_misura,
      fattore: doc.fattore,
      quantita: null,
      aliquota: "",
      sconto: l.sconto ?? "",
      riporta: l.prezzo_riga ?? l.prezzo_documento,
      proposta: l.proposto,
    });
  }

  const alCliente = prezzi.ultimi.find((u) => u.tipo === "ultimo_cliente");
  const assoluto = prezzi.ultimi.find((u) => u.tipo === "ultimo_assoluto");
  const massimo = prezzi.ultimi.find((u) => u.tipo === "massimo_giorno");
  const cliente = doc.cliente ?? "";
  for (const [tipo, etichetta] of [
    ["bv", "BOLLA VENDITA"],
    ["tb", "tipo Bolla"],
  ] as const) {
    const titolo = `Prz. ultimo doc. ${etichetta}`;
    voci.push(
      alCliente
        ? daUltimo(alCliente, `${titolo} di ${cliente}`, `${tipo}-cliente`)
        : { ...VUOTA, chiave: `${tipo}-cliente`, sezione: "documenti", descrizione: `${titolo} di ${cliente}`, icona: null, vuota: true },
    );
    if (assoluto) {
      voci.push(daUltimo(assoluto, `${titolo} ${riferimento(assoluto)}`, `${tipo}-assoluto`));
    }
  }
  voci.push(
    prezzi.ultimo_acquisto
      ? daUltimo(prezzi.ultimo_acquisto, `Ultimo Acquisto ${riferimento(prezzi.ultimo_acquisto)}`, "acquisto")
      : { ...VUOTA, chiave: "acquisto", sezione: "documenti", descrizione: "Ultimo Acquisto", icona: null, vuota: true },
  );
  if (massimo) voci.push(daUltimo(massimo, `Prz. massimo del giorno ${riferimento(massimo)}`, "massimo"));
  return voci;
}

const COLONNE = [
  { titolo: "Descrizione", larghezza: undefined, destra: false },
  { titolo: "Valuta", larghezza: 48, destra: false },
  { titolo: "Prezzo Val. Listino", larghezza: 104, destra: true },
  { titolo: "Prezzo Val Doc. Ivato", larghezza: 114, destra: true },
  { titolo: "U.M.", larghezza: 38, destra: false },
  { titolo: "Fattore", larghezza: 66, destra: true },
  { titolo: "Q.tà", larghezza: 52, destra: true },
  { titolo: "Aliquota", larghezza: 58, destra: true },
  { titolo: "Sconto", larghezza: 52, destra: false },
  { titolo: "Provvigione1", larghezza: 80, destra: true },
  { titolo: "Provvigione2", larghezza: 80, destra: true },
  { titolo: "Riporta", larghezza: 50, destra: false },
] as const;

const TITOLI_SEZIONE = {
  documento: "Dati da documento",
  listino: "Prezzi da listino",
  documenti: "Ultimi prezzi da documenti",
};

function Icona({ tipo }: { tipo: Voce["icona"] }) {
  if (tipo === "listino") {
    return (
      <svg viewBox="0 0 16 16" className="size-3.5 shrink-0" aria-label="listino" role="img">
        <path fill="currentColor" d="M2 2h5.6l6.4 6.4-5.6 5.6L2 7.6V2Zm2.6 1.6a1 1 0 1 0 0 2 1 1 0 0 0 0-2Z" />
      </svg>
    );
  }
  if (tipo === "persona") {
    return (
      <svg viewBox="0 0 16 16" className="size-3.5 shrink-0" aria-label="documento" role="img">
        <circle cx="8" cy="4.5" r="3" fill="currentColor" />
        <path fill="currentColor" d="M2 15c0-3.3 2.7-5.5 6-5.5s6 2.2 6 5.5H2Z" />
      </svg>
    );
  }
  return <span className="size-3.5 shrink-0" />;
}

export function FinestraPrezzi({ richiesta, onRiporta, onChiudi }: {
  richiesta: RichiestaF3;
  onRiporta: (prezzo: string) => void;
  onChiudi: () => void;
}) {
  const [prezzi, setPrezzi] = useState<Prezzi | null>(null);
  const [errore, setErrore] = useState<string | null>(null);
  const [scelta, setScelta] = useState(0);
  const tabella = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let attiva = true;
    const { prezzo: _prezzo, ...domanda } = richiesta;
    api
      .prezzi({ ...domanda, cliente: domanda.cliente || undefined })
      .then((p) => attiva && setPrezzi(p))
      .catch((e: Error) => attiva && setErrore(e.message));
    return () => {
      attiva = false;
    };
  }, [richiesta]);

  const voci = useMemo(() => (prezzi ? costruisciVoci(prezzi, richiesta.prezzo) : []), [prezzi, richiesta.prezzo]);
  const riportabili = voci.map((v, i) => (v.riporta !== null ? i : -1)).filter((i) => i >= 0);

  // Parte dal listino proposto (quello del cliente o il predefinito), altrimenti dalla prima voce riportabile.
  useEffect(() => {
    const proposta = voci.findIndex((v) => v.proposta);
    setScelta(proposta >= 0 ? proposta : (riportabili[0] ?? 0));
    tabella.current?.focus();
    // solo quando arrivano i prezzi
  }, [voci]);

  const muovi = (passo: number) => {
    const posizione = riportabili.indexOf(scelta);
    const prossima = riportabili[Math.min(Math.max(posizione + passo, 0), riportabili.length - 1)];
    if (prossima !== undefined) setScelta(prossima);
  };

  const riporta = (indice: number) => {
    const voce = voci[indice];
    if (voce && voce.riporta !== null) onRiporta(voce.riporta);
  };

  let sezionePrecedente: Voce["sezione"] | null = null;
  const cella = "border-r border-zinc-200 px-1.5 last:border-r-0 dark:border-zinc-800";

  return (
    <Modale
      titolo="PREZZO/COSTO ARTICOLO"
      titoloArca
      larghezza="max-w-[min(96vw,1280px)]"
      onChiudi={onChiudi}
      piede={
        <span className="flex gap-4">
          <span>
            <kbd className="tasto">↑</kbd> <kbd className="tasto">↓</kbd> scorre
          </span>
          <span>
            <kbd className="tasto">Invio</kbd> o <kbd className="tasto">Spazio</kbd> riporta il prezzo nella riga
          </span>
        </span>
      }
    >
      {errore && <p className="px-4 py-3 text-sm text-rose-600 dark:text-rose-400">{errore}</p>}
      <div
        ref={tabella}
        tabIndex={0}
        data-fuoco-iniziale
        role="listbox"
        aria-label="Prezzi"
        aria-activedescendant={voci[scelta] ? `prezzo-${voci[scelta].chiave}` : undefined}
        className="min-h-[18rem] outline-none"
        onKeyDown={(e) => {
          if (e.key === "ArrowDown") muovi(1);
          else if (e.key === "ArrowUp") muovi(-1);
          else if (e.key === "Enter" || e.key === " ") riporta(scelta);
          else return;
          e.preventDefault();
        }}
      >
        <table className="w-full table-fixed border-collapse text-[11.5px]">
          <colgroup>
            {COLONNE.map((c) => (
              <col key={c.titolo} style={c.larghezza ? { width: c.larghezza } : undefined} />
            ))}
          </colgroup>
          <thead className="sticky top-0 z-10 bg-white/95 backdrop-blur-sm dark:bg-zinc-900/95">
            <tr className="border-b border-zinc-300 dark:border-zinc-700">
              {COLONNE.map((c) => (
                <th
                  key={c.titolo}
                  className={`truncate px-1.5 py-1 text-[10.5px] font-normal text-zinc-600 dark:text-zinc-400 ${c.destra ? "text-right" : "text-left"}`}
                >
                  {c.titolo}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {voci.map((v, i) => {
              const titolo = v.sezione !== sezionePrecedente;
              sezionePrecedente = v.sezione;
              const attiva = i === scelta && v.riporta !== null;
              const riportabile = v.riporta !== null;
              const colore = attiva
                ? "bg-[#007aff] text-white dark:bg-[#0a84ff]"
                : v.sezione === "documento"
                  ? "text-[#1d4ed8] italic dark:text-sky-300"
                  : v.sezione === "listino" && i % 2
                    ? "bg-zinc-100/80 dark:bg-white/[0.04]"
                    : "";
              return [
                titolo && (
                  <tr key={`${v.sezione}-titolo`} className="bg-zinc-400 text-white dark:bg-zinc-600">
                    <td colSpan={COLONNE.length} className="px-1.5 py-0.5 text-[12.5px] font-semibold">
                      {TITOLI_SEZIONE[v.sezione]}
                    </td>
                  </tr>
                ),
                <tr
                  key={v.chiave}
                  id={`prezzo-${v.chiave}`}
                  role="option"
                  aria-selected={attiva}
                  aria-disabled={!riportabile}
                  onMouseDown={() => riportabile && setScelta(i)}
                  onDoubleClick={() => riporta(i)}
                  className={`h-[19px] border-b border-zinc-100 dark:border-zinc-800/60 ${colore} ${riportabile ? "cursor-pointer" : ""} ${
                    v.vuota ? "italic" : ""
                  }`}
                >
                  <td className={cella}>
                    <span className="flex items-center gap-1.5 truncate" title={v.descrizione}>
                      <Icona tipo={v.icona} />
                      <span className="truncate">{v.descrizione}</span>
                    </span>
                  </td>
                  <td className={cella}>{v.valuta}</td>
                  <td className={`${cella} cifre text-right`}>{v.prezzoListino === null ? "" : fPrezzo(v.prezzoListino)}</td>
                  <td className={`${cella} cifre text-right`}>{v.prezzoDocumento === null ? "" : fPrezzo(v.prezzoDocumento)}</td>
                  <td className={cella}>{v.um}</td>
                  <td className={`${cella} cifre text-right`}>{fFattore(v.fattore)}</td>
                  <td className={`${cella} cifre text-right`}>{v.quantita === null ? "" : fQuantita(v.quantita)}</td>
                  <td className={`${cella} cifre text-right`}>{/^\d+(\.\d+)?$/.test(v.aliquota) ? mostra(v.aliquota, 2) : v.aliquota}</td>
                  <td className={cella}>{v.sconto}</td>
                  <td className={cella} />
                  <td className={cella} />
                  <td className={`${cella} text-center`}>
                    {riportabile && (
                      <input
                        type="checkbox"
                        tabIndex={-1}
                        readOnly
                        checked
                        aria-label={`Riporta ${v.descrizione}`}
                        onClick={() => riporta(i)}
                        className="size-3 align-middle accent-[#007aff]"
                      />
                    )}
                  </td>
                </tr>,
              ];
            })}
          </tbody>
        </table>
      </div>
    </Modale>
  );
}
