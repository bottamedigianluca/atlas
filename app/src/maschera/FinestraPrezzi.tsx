// Tasto F3 sul prezzo: la maschera "PREZZO/COSTO ARTICOLO" (`fastsrcform_arprezzo` di Arca,
// direttiva §3.1) in tre sezioni: dati da documento, prezzi da listino, ultimi prezzi da
// documenti. `Freccia Su/Giù` scorrono le righe, `Invio` o `Spazio` riportano il prezzo nella
// riga del DDT.
//
// In ATLAS l'unico tipo "bolla" è la bolla di vendita (BO): le voci "tipo Bolla" della maschera
// di Arca hanno gli stessi documenti delle voci "BOLLA VENDITA". L'ultimo acquisto non c'è finché
// ATLAS non ha documenti di acquisto (in Arca le BF sono ferme al 2019).

import { useEffect, useMemo, useRef, useState } from "react";
import { api } from "../api/client";
import type { Prezzi, VoceUltimo } from "../api/tipi";
import { Modale } from "../componenti/Modale";
import { data as fData, mostra, prezzo as fPrezzo, quantita as fQuantita } from "../griglia/numeri";

export interface RichiestaF3 {
  articolo: string;
  cliente: string;
  data: string;
  unita_misura?: string;
  quantita?: string;
}

interface Voce {
  chiave: string;
  sezione: "listino" | "documenti" | "acquisto";
  descrizione: string;
  valuta: string;
  prezzoListino: string | null;
  prezzoIvato: string | null;
  um: string;
  fattore: string;
  quantita: string | null;
  aliquota: string;
  sconto: string;
  /** Prezzo da riportare nella riga; `null` se la voce non ha prezzo. */
  riporta: string | null;
  evidenziata?: boolean;
}

function vociDocumenti(prezzi: Prezzi): Voce[] {
  const cliente = prezzi.documento.ragione_sociale ?? prezzi.documento.cliente ?? "";
  const daUltimo = (u: VoceUltimo, descrizione: string, chiave: string): Voce => ({
    chiave,
    sezione: "documenti",
    descrizione,
    valuta: "EUR",
    prezzoListino: u.prezzo,
    prezzoIvato: u.prezzo_ivato,
    um: u.unita_misura,
    fattore: u.fattore,
    quantita: u.quantita,
    aliquota: u.aliquota,
    sconto: u.sconto,
    riporta: u.prezzo_riga,
  });
  const voci: Voce[] = [];
  const alCliente = prezzi.ultimi.find((u) => u.tipo === "ultimo_cliente");
  const assoluto = prezzi.ultimi.find((u) => u.tipo === "ultimo_assoluto");
  const massimo = prezzi.ultimi.find((u) => u.tipo === "massimo_giorno");
  const altro = (u: VoceUltimo) => `(${u.documento.tipo} ${u.documento.numero} / ${u.documento.ragione_sociale} del ${fData(u.documento.data).replaceAll("/", "-")})`;
  for (const [tipo, etichetta] of [
    ["bv", "BOLLA VENDITA"],
    ["tb", "tipo Bolla"],
  ] as const) {
    if (alCliente) voci.push(daUltimo(alCliente, `Prz. ultimo doc. ${etichetta} di ${cliente}`, `${tipo}-cliente`));
    if (assoluto) voci.push(daUltimo(assoluto, `Prz. ultimo doc. ${etichetta} ${altro(assoluto)}`, `${tipo}-assoluto`));
  }
  if (massimo) voci.push(daUltimo(massimo, `Prz. massimo del giorno ${altro(massimo)}`, "massimo"));
  return voci;
}

export function costruisciVoci(prezzi: Prezzi): Voce[] {
  const listini: Voce[] = prezzi.listini.map((l) => ({
    chiave: `listino-${l.listino}`,
    sezione: "listino",
    descrizione: l.descrizione,
    valuta: "EUR",
    prezzoListino: l.prezzo_listino,
    prezzoIvato: l.prezzo_ivato,
    um: prezzi.documento.unita_misura,
    fattore: prezzi.documento.fattore,
    quantita: null,
    aliquota: prezzi.documento.aliquota ?? "",
    sconto: l.sconto ?? "",
    riporta: l.prezzo_riga,
    evidenziata: l.proposto,
  }));
  const acquisto: Voce = {
    chiave: "acquisto",
    sezione: "acquisto",
    descrizione: "Ultimo Acquisto (nessun documento di acquisto in ATLAS)",
    valuta: "EUR",
    prezzoListino: null,
    prezzoIvato: null,
    um: prezzi.documento.unita_misura,
    fattore: prezzi.documento.fattore,
    quantita: null,
    aliquota: prezzi.documento.aliquota ?? "",
    sconto: "",
    riporta: null,
  };
  return [...listini, ...vociDocumenti(prezzi), acquisto];
}

const INTESTAZIONI = [
  "Descrizione",
  "Valuta",
  "Prezzo Val. Listino",
  "Prezzo Val Doc. Ivato",
  "U.M.",
  "Fattore",
  "Q.tà",
  "Aliquota",
  "Sconto",
  "Provvigione 1",
  "Provvigione 2",
  "Riporta",
];

const TITOLI_SEZIONE = {
  listino: "Prezzi da listino",
  documenti: "Ultimi prezzi da documenti",
  acquisto: "Ultimo acquisto",
};

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
    api
      .prezzi({ ...richiesta, cliente: richiesta.cliente || undefined })
      .then((p) => attiva && setPrezzi(p))
      .catch((e: Error) => attiva && setErrore(e.message));
    return () => {
      attiva = false;
    };
  }, [richiesta]);

  const voci = useMemo(() => (prezzi ? costruisciVoci(prezzi) : []), [prezzi]);
  const riportabili = voci.map((v, i) => (v.riporta ? i : -1)).filter((i) => i >= 0);

  // Parte dalla voce del listino proposto, altrimenti dalla prima con un prezzo.
  useEffect(() => {
    const proposta = voci.findIndex((v) => v.evidenziata);
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
    if (voce?.riporta) onRiporta(voce.riporta);
  };

  const doc = prezzi?.documento;
  let sezionePrecedente: Voce["sezione"] | null = null;

  return (
    <Modale
      titolo="PREZZO/COSTO ARTICOLO"
      sottotitolo={doc ? `${doc.articolo} — ${doc.descrizione}` : richiesta.articolo}
      larghezza="max-w-[min(96vw,1440px)]"
      onChiudi={onChiudi}
      piede={
        <span className="flex gap-4">
          <span><kbd className="tasto">↑</kbd> <kbd className="tasto">↓</kbd> scorre</span>
          <span><kbd className="tasto">Invio</kbd> o <kbd className="tasto">Spazio</kbd> riporta il prezzo nella riga</span>
        </span>
      }
    >
      {errore && <p className="px-5 py-4 text-sm text-rose-600 dark:text-rose-400">{errore}</p>}
      {doc && (
        <section className="grid grid-cols-2 gap-x-8 gap-y-1.5 border-b border-zinc-200/80 px-5 py-3 text-xs sm:grid-cols-4 dark:border-zinc-800">
          <h3 className="etichetta col-span-full">Dati da documento</h3>
          <Dato nome="Articolo" valore={`${doc.articolo} ${doc.descrizione}`} />
          <Dato
            nome="Rif. documento"
            valore={`BO / ${doc.cliente ?? "—"} del ${fData(doc.data).replaceAll("/", "-")}`}
          />
          <Dato nome="Valuta" valore={doc.valuta} />
          <Dato nome="U.M. / Fattore" valore={`${doc.unita_misura} / ${mostra(doc.fattore, 0, 3)}`} />
          <Dato nome="Q.tà" valore={fQuantita(doc.quantita)} />
          <Dato nome="Aliquota" valore={doc.aliquota ? `${doc.aliquota} (${mostra(doc.percentuale_iva, 0, 2)}%)` : "—"} />
          <Dato nome="Cliente" valore={doc.ragione_sociale ?? "—"} />
          <Dato nome="Listino cliente" valore={doc.listino_cliente ?? "nessuno"} />
        </section>
      )}
      <div
        ref={tabella}
        tabIndex={0}
        data-fuoco-iniziale
        role="listbox"
        aria-label="Prezzi"
        aria-activedescendant={voci[scelta] ? `prezzo-${voci[scelta].chiave}` : undefined}
        className="outline-none"
        onKeyDown={(e) => {
          if (e.key === "ArrowDown") muovi(1);
          else if (e.key === "ArrowUp") muovi(-1);
          else if (e.key === "Enter" || e.key === " ") riporta(scelta);
          else return;
          e.preventDefault();
        }}
      >
        <table className="w-full border-collapse text-xs">
          <colgroup>
            <col />
            {INTESTAZIONI.slice(1).map((t) => (
              <col key={t} className="w-px" />
            ))}
          </colgroup>
          <thead className="sticky top-0 bg-zinc-100/90 backdrop-blur-sm dark:bg-zinc-900/90">
            <tr>
              {INTESTAZIONI.map((t, i) => (
                <th
                  key={t}
                  className={`whitespace-nowrap px-2 py-1.5 text-[10.5px] font-semibold uppercase tracking-wide text-zinc-500 ${
                    i >= 2 && i !== 4 && i !== 7 && i !== 8 ? "text-right" : "text-left"
                  }`}
                >
                  {t}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {voci.map((v, i) => {
              const titolo = v.sezione !== sezionePrecedente;
              sezionePrecedente = v.sezione;
              const attiva = i === scelta;
              return [
                titolo && (
                  <tr key={`${v.sezione}-titolo`}>
                    <td colSpan={INTESTAZIONI.length} className="etichetta px-2 pb-1 pt-3">
                      {TITOLI_SEZIONE[v.sezione]}
                    </td>
                  </tr>
                ),
                <tr
                  key={v.chiave}
                  id={`prezzo-${v.chiave}`}
                  role="option"
                  aria-selected={attiva}
                  aria-disabled={!v.riporta}
                  onMouseDown={() => v.riporta && setScelta(i)}
                  onDoubleClick={() => riporta(i)}
                  className={`${attiva ? "bg-sky-500/15 dark:bg-sky-400/15" : ""} ${v.riporta ? "cursor-pointer" : "text-zinc-400"} ${
                    v.evidenziata ? "font-semibold" : ""
                  }`}
                >
                  <td className="max-w-[30rem] truncate px-2 py-1" title={v.descrizione}>{v.descrizione}</td>
                  <td className="px-2 py-1">{v.valuta}</td>
                  <td className="cifre px-2 py-1 text-right">{fPrezzo(v.prezzoListino)}</td>
                  <td className="cifre px-2 py-1 text-right">{fPrezzo(v.prezzoIvato)}</td>
                  <td className="px-2 py-1">{v.um}</td>
                  <td className="cifre px-2 py-1 text-right">{mostra(v.fattore, 0, 3)}</td>
                  <td className="cifre px-2 py-1 text-right">{fQuantita(v.quantita)}</td>
                  <td className="px-2 py-1">{v.aliquota}</td>
                  <td className="px-2 py-1">{v.sconto}</td>
                  <td className="cifre px-2 py-1 text-right text-zinc-400">—</td>
                  <td className="cifre px-2 py-1 text-right text-zinc-400">—</td>
                  <td className="px-2 py-1 text-center">
                    <input
                      type="checkbox"
                      tabIndex={-1}
                      readOnly
                      checked={attiva && !!v.riporta}
                      disabled={!v.riporta}
                      aria-label={`Riporta ${v.descrizione}`}
                      onClick={() => riporta(i)}
                      className="accent-[var(--color-accento)]"
                    />
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

function Dato({ nome, valore }: { nome: string; valore: string }) {
  return (
    <div className="min-w-0">
      <div className="text-[10px] uppercase tracking-wide text-zinc-400">{nome}</div>
      <div className="truncate font-medium">{valore}</div>
    </div>
  );
}
