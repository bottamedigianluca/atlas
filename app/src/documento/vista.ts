// Il documento come lo mostrano testata e schede, comune al DDT in battitura e a quello salvato
// aperto dall'elenco.

import type { Castelletto, ClienteScheda, DdtScheda, EventoVista, RigaCalcolata, StatoArca } from "../api/tipi";

/** `DO.Descrizione` del tipo BO in Arca: è il testo delle voci "BOLLA VENDITA" della maschera prezzi. */
export const DESCRIZIONE_BO = "BOLLA VENDITA";

/**
 * Trasporto, spedizione, porto e aspetto dei beni dei BO: Arca li prende dal tipo documento (`DO`),
 * uguali su tutti i 5.452 BO 2026 rigiocati (misurati sul BO 108602). ATLAS non li cambia.
 */
export const PIEDE_BO = { trasporto: "V", spedizione: "M", porto: "F", aspettoBeni: "AV" } as const;

export interface VistaDocumento {
  nuovo: boolean;
  numero: string;
  data: string;
  cliente: string;
  ragioneSociale: string;
  indirizzo: string;
  codiceDestinatario: string | null;
  destinazione: string | null;
  descrizioneDestinazione: string | null;
  sede: string | null;
  pagamento: string | null;
  descrizionePagamento: string | null;
  agente: string | null;
  descrizioneAgente: string | null;
  listino: string | null;
  descrizioneListino: string | null;
  iban: string | null;
  bic: string | null;
  scissione: boolean;
  inizioTrasporto: string | null;
  righe: { totale: string | null; conto: string | null; quantita: string | null; colli: string; lordo: string }[];
  castelletto: Castelletto | null;
  nettoAPagare: string | null;
  operatore: string | null;
  registratoIl: string | null;
  idAtlas: number | null;
  arcaIdTestata: number | null;
  arca: StatoArca | null;
  eventi: EventoVista[];
}

function indirizzo(scheda: ClienteScheda | null): string {
  if (!scheda) return "";
  const luogo = [scheda.cap, scheda.localita, scheda.provincia ? `(${scheda.provincia})` : null].filter(Boolean).join(" ");
  return [scheda.indirizzo?.trim(), luogo].filter(Boolean).join(" — ");
}

function destinazione(scheda: ClienteScheda | null, codice: string | null): string | null {
  const d = scheda?.destinazioni.find((x) => x.codice.toUpperCase() === codice?.toUpperCase());
  return d ? [d.descrizione.trim(), d.localita?.trim()].filter(Boolean).join(" — ") : null;
}

export function vistaNuovo(args: {
  numero: string;
  data: string;
  cliente: string;
  scheda: ClienteScheda | null;
  destinazione: string | null;
  ragioneSociale: string | null;
  righe: (RigaCalcolata | undefined)[];
  pesate: { colli: string; lordo: string }[];
  castelletto: Castelletto | null;
  nettoAPagare: string | null;
  scissione: boolean;
}): VistaDocumento {
  const { scheda } = args;
  return {
    nuovo: true,
    numero: args.numero,
    data: args.data,
    cliente: args.cliente,
    ragioneSociale: args.ragioneSociale ?? scheda?.ragione_sociale ?? "",
    indirizzo: indirizzo(scheda),
    codiceDestinatario: scheda?.codice_destinatario ?? null,
    destinazione: args.destinazione,
    descrizioneDestinazione: destinazione(scheda, args.destinazione),
    sede: null,
    pagamento: scheda?.pagamento ?? null,
    descrizionePagamento: scheda?.descrizione_pagamento ?? null,
    agente: scheda?.agente ?? null,
    descrizioneAgente: scheda?.descrizione_agente ?? null,
    listino: scheda?.listino ?? null,
    descrizioneListino: scheda?.descrizione_listino ?? null,
    iban: scheda?.iban ?? null,
    bic: scheda?.bic ?? null,
    scissione: args.scissione,
    inizioTrasporto: args.data ? `${args.data}T` : null,
    righe: args.righe.map((r, i) => ({
      totale: r?.totale ?? null,
      conto: r?.conto_ricavo ?? null,
      quantita: r?.quantita ?? null,
      colli: args.pesate[i]?.colli ?? "",
      lordo: args.pesate[i]?.lordo ?? "",
    })),
    castelletto: args.castelletto,
    nettoAPagare: args.nettoAPagare,
    operatore: null,
    registratoIl: null,
    idAtlas: null,
    arcaIdTestata: null,
    arca: null,
    eventi: [],
  };
}

export function vistaSalvato(ddt: DdtScheda, scheda: ClienteScheda | null): VistaDocumento {
  const d = ddt.documento;
  return {
    nuovo: false,
    numero: String(ddt.numero),
    data: d.data,
    cliente: d.cliente,
    ragioneSociale: ddt.ragione_sociale,
    indirizzo: indirizzo(scheda),
    codiceDestinatario: scheda?.codice_destinatario ?? null,
    destinazione: d.destinazione,
    descrizioneDestinazione: destinazione(scheda, d.destinazione),
    sede: d.sede,
    pagamento: d.pagamento,
    descrizionePagamento: scheda?.pagamento === d.pagamento ? (scheda?.descrizione_pagamento ?? null) : null,
    agente: d.agente,
    descrizioneAgente: scheda?.agente === d.agente ? (scheda?.descrizione_agente ?? null) : null,
    listino: d.listino_cliente,
    descrizioneListino: scheda?.listino === d.listino_cliente ? (scheda?.descrizione_listino ?? null) : null,
    iban: d.iban,
    bic: d.bic,
    scissione: d.scissione_pagamenti,
    inizioTrasporto: d.inizio_trasporto,
    righe: ddt.righe.map((r) => ({
      totale: r.totale,
      conto: r.conto_ricavo,
      quantita: r.quantita,
      colli: r.pesata.colli,
      lordo: r.pesata.lordo,
    })),
    castelletto: ddt.castelletto,
    nettoAPagare: ddt.netto_a_pagare,
    operatore: d.operatore,
    registratoIl: d.registrato_il,
    idAtlas: ddt.id,
    arcaIdTestata: ddt.arca_id_testata,
    arca: ddt.arca,
    eventi: ddt.eventi,
  };
}

/** Somma esatta di importi in testo decimale (centesimi interi): per i riepiloghi a video. */
export function somma(importi: (string | null | undefined)[], decimali = 2): string {
  const scala = 10 ** decimali;
  let totale = 0;
  for (const i of importi) {
    if (!i) continue;
    const n = Number(i);
    if (Number.isFinite(n)) totale += Math.round(n * scala);
  }
  return (totale / scala).toFixed(decimali);
}

/** Imponibile per conto ricavo (riquadro "Merce" dei totali). */
export function merceAConto(vista: VistaDocumento): { conto: string; importo: string }[] {
  const conti = new Map<string, string[]>();
  for (const r of vista.righe) {
    if (!r.conto || !r.totale) continue;
    conti.set(r.conto, [...(conti.get(r.conto) ?? []), r.totale]);
  }
  return [...conti].map(([conto, importi]) => ({ conto, importo: somma(importi) }));
}
