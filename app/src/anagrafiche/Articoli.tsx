// Articoli: l'elenco con le colonne di quello di Arca (`docs/screenshot_arca/06_…`) e la scheda in
// una pagina sola con tutti i campi di `AR` che ATLAS importa, le unità di misura con i fattori e il
// prezzo valido oggi in ogni listino. In sola lettura: gli articoli si modificano in Arca.

import { useCallback, useEffect, useState } from "react";
import { api } from "../api/client";
import type { ArticoloBreve, ArticoloScheda, Tabelle } from "../api/tipi";
import type { Griglia } from "../griglia/layout";
import { data as fData, fattore, mostra, prezzo } from "../griglia/numeri";
import { Area, type PaginaAnagrafica } from "./Area";
import { SEZIONI_ARTICOLO, recordArticolo } from "./campi";
import type { Colonna } from "./GrigliaElenco";
import { Scheda, Tabella } from "./Scheda";

const x = (r: ArticoloBreve, colonna: string) => {
  const v = r.extra?.[colonna];
  return v === null || v === undefined ? "" : String(v).trimEnd();
};
/** I numeri dell'elenco come in Arca: "0.00" anche quando il campo è vuoto. */
const numero = (r: ArticoloBreve, colonna: string) => mostra(x(r, colonna) || "0", 2);
const spunta = (r: ArticoloBreve, colonna: string) => (r.extra?.[colonna] === true ? "✓" : "");

/** Le colonne dell'elenco articoli di Arca, nel suo ordine. */
export const COLONNE_ARTICOLI: Colonna<ArticoloBreve>[] = [
  { id: "codice", etichetta: "Codice", larghezza: 110, valore: (r) => r.codice },
  { id: "descrizione", etichetta: "Descrizione", larghezza: 280, valore: (r) => r.descrizione },
  { id: "famiglia", etichetta: "Famiglia", larghezza: 55, valore: (r) => x(r, "Cd_ARGruppo1") },
  { id: "marca", etichetta: "Marca", larghezza: 50, valore: (r) => x(r, "Cd_ARMarca") },
  { id: "gruppo", etichetta: "Gruppo", larghezza: 50, valore: (r) => x(r, "Cd_ARGruppo2") },
  { id: "sottogruppo", etichetta: "Sottogruppo", larghezza: 75, valore: (r) => x(r, "Cd_ARGruppo3") },
  { id: "categoria", etichetta: "Categoria", larghezza: 60, valore: (r) => x(r, "Cd_ARClasse1") },
  { id: "classe", etichetta: "Classe", larghezza: 45, valore: (r) => x(r, "Cd_ARClasse2") },
  { id: "sottoclasse", etichetta: "Sottoclasse", larghezza: 70, valore: (r) => x(r, "Cd_ARClasse3") },
  { id: "sconto", etichetta: "Sconto", larghezza: 50, valore: (r) => x(r, "Sconto") },
  { id: "provvigione", etichetta: "Provvigione", larghezza: 70, valore: (r) => x(r, "Provvigione") },
  { id: "scorta_minima", etichetta: "Scorta minima", larghezza: 80, numerica: true, valore: (r) => numero(r, "ScortaMinima") },
  { id: "lotto_minimo", etichetta: "Lotto minimo", larghezza: 75, numerica: true, valore: (r) => numero(r, "LottoMinimo") },
  { id: "lotto_riordino", etichetta: "Lotto riordino", larghezza: 80, numerica: true, valore: (r) => numero(r, "LottoRiordino") },
  { id: "iva_vendite", etichetta: "IVA vend.", larghezza: 55, valore: (r) => r.aliquota ?? "" },
  { id: "iva_acquisti", etichetta: "IVA acq.", larghezza: 55, valore: (r) => x(r, "Cd_Aliquota_A") },
  { id: "obsoleto", etichetta: "OB", larghezza: 26, suggerimento: "Obsoleto", valore: (r) => (r.obsoleto ? "✓" : "") },
  { id: "fittizio", etichetta: "AF", larghezza: 26, suggerimento: "Articolo fittizio", valore: (r) => spunta(r, "Fittizio") },
  { id: "stato", etichetta: "Stato", larghezza: 45, valore: (r) => x(r, "Cd_ARStato") },
  { id: "um", etichetta: "UM", larghezza: 40, valore: (r) => r.unita_misura },
];

export const GRIGLIA_ARTICOLI: Griglia = { colonne: COLONNE_ARTICOLI, chiave: "atlas.griglia.articoli", fisse: ["codice"] };

const OBSOLETO = "text-zinc-400 line-through decoration-zinc-300 dark:text-zinc-600";
const FITTIZIO = "bg-orange-100/70 dark:bg-orange-500/10";

export function Articoli({ attivo }: { attivo: boolean }) {
  const [righe, setRighe] = useState<ArticoloBreve[]>([]);
  const [tabelle, setTabelle] = useState<Tabelle | null>(null);
  const [errore, setErrore] = useState<string | null>(null);
  const [giro, setGiro] = useState(0);
  const [pagina, setPagina] = useState<PaginaAnagrafica>("Elenco");
  const [aperto, setAperto] = useState<string | null>(null);
  const [scheda, setScheda] = useState<ArticoloScheda | null>(null);

  useEffect(() => {
    if (!attivo) return;
    let valida = true;
    Promise.all([api.elencoArticoli(), api.tabelle()])
      .then(([a, t]) => {
        if (!valida) return;
        setRighe(a);
        setTabelle(t);
        setErrore(null);
      })
      .catch((e: Error) => valida && setErrore(e.message));
    return () => {
      valida = false;
    };
  }, [attivo, giro]);

  useEffect(() => {
    if (!aperto) return setScheda(null);
    let valida = true;
    api.articolo(aperto).then(
      (s) => valida && setScheda(s),
      (e: Error) => valida && setErrore(e.message),
    );
    return () => {
      valida = false;
    };
  }, [aperto, giro]);

  const aggiorna = useCallback(() => setGiro((g) => g + 1), []);

  const contenuto = scheda ? (
    <Scheda
      nome="Scheda articolo"
      titolo={
        <>
          <span className="font-mono text-zinc-500">{scheda.codice}</span> {scheda.descrizione}
        </>
      }
      sottotitolo={`UM ${scheda.unita_misura}${scheda.aliquota ? ` — IVA ${scheda.aliquota}` : ""}`}
      sezioni={SEZIONI_ARTICOLO}
      record={recordArticolo(scheda)}
      tabelle={tabelle}
      avviso={
        <>
          {scheda.obsoleto && <p className="mb-2 text-[12px] font-semibold text-rose-600">Articolo obsoleto</p>}
          {!scheda.aliquota && (
            <p role="alert" className="mb-2 text-[12px] font-semibold text-amber-700 dark:text-amber-300">
              Manca l'aliquota IVA per le vendite (in Arca è obbligatoria)
            </p>
          )}
          {(!scheda.extra || Object.keys(scheda.extra).length === 0) && (
            <p role="note" className="mb-3 rounded-md bg-amber-500/12 px-3 py-1.5 text-[12px] text-amber-800 dark:text-amber-300">
              Solo i campi principali: il database ATLAS va riallineato con <code>importa-anagrafiche</code> per avere tutti i campi di Arca.
            </p>
          )}
          <p className="mb-3 text-[11.5px] text-zinc-500">In sola lettura: gli articoli si modificano in Arca e l'importazione li riallinea.</p>
        </>
      }
      aggiunte={{
        generale: (
          <Tabella
            nome="Unità di misura"
            intestazioni={[{ testo: "UM" }, { testo: "Fattore", numerica: true }, { testo: "Predefinita" }]}
            righe={scheda.unita.map((u) => [u.unita_misura, fattore(u.fattore), u.predefinita ? "✓" : ""])}
            vuota="Nessuna unità di misura alternativa"
          />
        ),
        prezzi: (
          <Tabella
            nome="Prezzi validi oggi"
            intestazioni={[
              { testo: "Listino" },
              { testo: "Descrizione" },
              { testo: "Revisione" },
              { testo: "Valido dal" },
              { testo: "Prezzo", numerica: true },
              { testo: "Sconto" },
              { testo: "Ivato" },
            ]}
            righe={scheda.prezzi.map((p) => [
              <span className="font-mono">{p.listino}</span>,
              p.descrizione,
              p.revisione ?? "",
              fData(p.valido_dal),
              prezzo(p.prezzo),
              p.sconto ?? "",
              p.ivato ? "✓" : "",
            ])}
            vuota="L'articolo non è in nessun listino valido oggi"
          />
        ),
      }}
    />
  ) : (
    <div className="flex h-full items-center justify-center text-sm text-zinc-500">
      {aperto ? "Carico…" : "Scegli un articolo nell'elenco (Invio o doppio clic)."}
    </div>
  );

  return (
    <Area
      attivo={attivo}
      nome="Articoli"
      griglia={GRIGLIA_ARTICOLI}
      colonne={COLONNE_ARTICOLI}
      righe={righe}
      chiave={(r) => r.codice}
      classeRiga={(r) => (r.obsoleto ? OBSOLETO : r.extra?.Fittizio === true ? FITTIZIO : undefined)}
      piede={
        <>
          <span className={`rounded-sm px-1 ${FITTIZIO}`}>Fittizio</span>
          <span className={`rounded-sm border border-zinc-300 px-1 dark:border-zinc-700 ${OBSOLETO}`}>Obsoleto</span>
        </>
      }
      errore={errore}
      aperto={aperto}
      onApri={setAperto}
      pagina={pagina}
      onPagina={setPagina}
      scheda={contenuto}
      onAggiorna={aggiorna}
    />
  );
}
