// Un DDT salvato, aperto dall'elenco nella pagina Generale come in Arca: stessa testata e stesse
// schede del documento in battitura, in sola lettura (la modifica dei DDT salvati non c'è ancora).

import { useEffect, useMemo, useState } from "react";
import { api } from "../api/client";
import type { ClienteScheda, DdtScheda, RigaCalcolata } from "../api/tipi";
import { BadgeArca } from "../componenti/Badge";
import { GRIGLIA_RIGHE } from "../griglia/colonne";
import * as layouts from "../griglia/layout";
import { prezzo as fPrezzo, quantita as fQuantita } from "../griglia/numeri";
import { Griglia } from "../maschera/Griglia";
import { type Azione, type StatoRighe, riduci, rigaVuota } from "../maschera/righe";
import { BarraSchede, type Scheda, SchedaEvasioni, SchedaInfo, SchedaPiede, SchedaStampe, SchedaTesta, SchedaTotali } from "./Schede";
import { Testata } from "./Testata";
import { vistaSalvato } from "./vista";

function inRighe(ddt: DdtScheda): { stato: StatoRighe; calcolate: RigaCalcolata[] } {
  const righe = ddt.righe.map((r, i) => ({
    ...rigaVuota(i + 1),
    articolo: r.articolo,
    descrizione: r.descrizione,
    unita_misura: r.unita_misura,
    colli: fQuantita(r.pesata.colli),
    lordo: fQuantita(r.pesata.lordo),
    tara: fQuantita(r.pesata.tara_per_collo),
    quantita: fQuantita(r.quantita),
    prezzo: fPrezzo(r.prezzo_unitario),
    sconto: r.sconto_riga,
    magazzino: r.magazzino ?? "",
  }));
  const calcolate: RigaCalcolata[] = ddt.righe.map((r) => ({
    vuota: false,
    articolo: r.articolo,
    descrizione: r.descrizione,
    unita_misura: r.unita_misura,
    fattore_um1: r.fattore_um1,
    aliquota: r.aliquota,
    conto_ricavo: r.conto_ricavo,
    magazzino: r.magazzino,
    quantita: r.quantita,
    prezzo: r.prezzo_unitario,
    origine_prezzo: null,
    prezzo_listino: null,
    prezzo_modificato: false,
    totale: r.totale,
    avvisi: [],
    errori: [],
  }));
  return {
    stato: { righe, cursore: { riga: 0, campo: "articolo" }, avviso: null, originale: "", prossimaChiave: righe.length + 1 },
    calcolate,
  };
}

export function Consultazione({ id, attivo }: { id: number; attivo: boolean }) {
  const [ddt, setDdt] = useState<DdtScheda | null>(null);
  const [scheda, setScheda] = useState<ClienteScheda | null>(null);
  const [errore, setErrore] = useState<string | null>(null);
  const [schedaAttiva, setSchedaAttiva] = useState<Scheda>("Righe");
  const [layout, setLayout] = useState(() => layouts.carica(GRIGLIA_RIGHE));
  const [cursore, setCursore] = useState<StatoRighe | null>(null);

  useEffect(() => {
    let valido = true;
    setDdt(null);
    api
      .ddt(id)
      .then(async (d) => {
        if (!valido) return;
        setDdt(d);
        setScheda(await api.cliente(d.documento.cliente).catch(() => null));
      })
      .catch((e: Error) => valido && setErrore(e.message));
    return () => {
      valido = false;
    };
  }, [id]);

  useEffect(() => layouts.salva(GRIGLIA_RIGHE, layout), [layout]);
  const righe = useMemo(() => (ddt ? inRighe(ddt) : null), [ddt]);
  useEffect(() => setCursore(righe?.stato ?? null), [righe]);

  if (errore) return <p className="p-4 text-sm text-rose-600">{errore}</p>;
  if (!ddt || !righe || !cursore) return <p className="p-4 text-sm text-zinc-500">Caricamento…</p>;
  const vista = vistaSalvato(ddt, scheda);
  return (
    <div className="flex h-full min-h-0 flex-col">
      <Testata
        vista={vista}
        stato={
          <>
            <span className="rounded-full bg-zinc-500/10 px-2 py-0.5 font-medium text-zinc-600 dark:text-zinc-300">Consultazione</span>
            <BadgeArca stato={ddt.arca} />
          </>
        }
      />
      <BarraSchede attiva={schedaAttiva} onScheda={setSchedaAttiva} />
      <div className="flex min-h-0 flex-1 flex-col bg-white dark:bg-zinc-950">
        {schedaAttiva === "Righe" && (
          <Griglia
            stato={cursore}
            calcolate={righe.calcolate}
            layout={layout}
            attiva={attivo}
            solaLettura
            onLayout={setLayout}
            onAzione={(a: Azione) => setCursore((s) => (s ? riduci(s, a) : s))}
            onF3={() => {}}
          />
        )}
        {schedaAttiva === "Testa" && <SchedaTesta vista={vista} />}
        {schedaAttiva === "Piede" && <SchedaPiede vista={vista} />}
        {schedaAttiva === "Totali" && <SchedaTotali vista={vista} />}
        {schedaAttiva === "Info" && <SchedaInfo vista={vista} />}
        {schedaAttiva === "Evasioni" && <SchedaEvasioni />}
        {schedaAttiva === "Stampe" && <SchedaStampe />}
      </div>
    </div>
  );
}
