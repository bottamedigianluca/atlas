// Le 40 colonne della griglia righe di Arca (UserPref 1443): ordine e larghezze dell'interfaccia
// storica, lette da `docs/griglia_righe_userpref_1443.json`. Qui si aggiunge solo ciò che serve
// ad ATLAS: il dato che ogni colonna mostra e se l'operatore lo batte.

import userPref from "../../../docs/griglia_righe_userpref_1443.json";

/** Campi della riga che l'operatore batte. */
export type CampoRiga =
  | "articolo"
  | "descrizione"
  | "unita_misura"
  | "colli"
  | "lordo"
  | "tara"
  | "quantita"
  | "prezzo"
  | "sconto"
  | "magazzino";

/** Valori calcolati dal backend mostrati in sola lettura. */
export type Calcolato =
  | "riga"
  | "totale"
  | "aliquota"
  | "fattore"
  | "quantita_evadibile"
  | "conto";

export interface Colonna {
  /** Identificativo di Arca (`ColCd_AR`, `xColLordo`…): chiave del layout salvato. */
  id: string;
  etichetta: string;
  larghezza: number;
  /** Dato battuto dall'operatore, o calcolato, o nessuno (colonna di Arca che ATLAS non usa). */
  campo?: CampoRiga;
  calcolato?: Calcolato;
  numerica: boolean;
}

interface ColonnaUserPref {
  ordine: number;
  arca: string;
  etichetta: string | null;
  larghezza_px: number;
}

/** Il dato di ogni colonna; le altre restano vuote (Arca le ha, i BO di Bottamedi non le usano). */
const DATI: Record<string, Pick<Colonna, "campo" | "calcolato"> & { etichetta?: string; numerica?: boolean }> = {
  ColRiga: { calcolato: "riga", numerica: true },
  ColCd_AR: { campo: "articolo" },
  ColDescrizione: { campo: "descrizione" },
  ColCd_ARMisura: { campo: "unita_misura" },
  xColColli: { campo: "colli", numerica: true },
  xColLordo: { campo: "lordo", numerica: true },
  xColTara: { campo: "tara", numerica: true },
  COLQTA: { campo: "quantita", numerica: true },
  COLPREZZOUNITARIOV: { campo: "prezzo", numerica: true },
  COLPREZZOTOTALEV: { calcolato: "totale", numerica: true },
  ColCd_Aliquota: { calcolato: "aliquota" },
  ColFattoreToUM1: { calcolato: "fattore", numerica: true },
  COLQTAEVADIBILE: { calcolato: "quantita_evadibile", numerica: true },
  ColCd_MG_P: { campo: "magazzino" },
  ColScontoRiga: { campo: "sconto" },
  ColCd_CGConto: { calcolato: "conto", etichetta: "Conto" },
  // Senza etichetta in UserPref (icone o colonne vuote in Arca): un nome per il menu delle colonne.
  COLDISTINTA: { etichetta: "Distinta" },
  ColDettagli: { etichetta: "Dettagli" },
  ColTipoPC: { etichetta: "Tipo P/C" },
  ColCd_MGUbicazione_P: { etichetta: "Ubic. P." },
  ColCd_MG_A: { etichetta: "Mag. A." },
  ColCd_MGUbicazione_A: { etichetta: "Ubic. A." },
  ColCd_DOSottoCommessa: { etichetta: "Sottocommessa" },
  ColDoIntento: { etichetta: "Intento" },
  COLCD_REVERSECHARGE: { etichetta: "Reverse ch." },
  ColProvvigioneRiga_1: { etichetta: "Provv. 1" },
  ColProvvigioneRiga_2: { etichetta: "Provv. 2" },
  ColDataConsegna: { etichetta: "Consegna" },
  ColCd_ARLotto: { etichetta: "Lotto" },
  ColCd_CAVda: { etichetta: "CA voce" },
  ColCd_CACda: { etichetta: "CA centro" },
  ColCd_CAFormula: { etichetta: "CA formula" },
  COLCAPARTENZA: { etichetta: "CA partenza" },
  COLCADURATA: { etichetta: "CA durata" },
  ColRR_DataInizio: { etichetta: "Rateo dal" },
  ColRR_DataFine: { etichetta: "Rateo al" },
  ColRR_Cd_CGConto: { etichetta: "Rateo conto" },
  colMatricole: { etichetta: "Matricole" },
  ColId_MGMov_Carico: { etichetta: "Mov. carico" },
};

export const ALTEZZA_RIGA = (userPref as { altezza_riga_px: number }).altezza_riga_px;

/** Le colonne nell'ordine di fabbrica (UserPref 1443). */
export const COLONNE: readonly Colonna[] = (userPref.colonne as ColonnaUserPref[])
  .slice()
  .sort((a, b) => a.ordine - b.ordine)
  .map((c) => {
    const dati = DATI[c.arca] ?? {};
    return {
      id: c.arca,
      etichetta: c.etichetta ?? dati.etichetta ?? c.arca,
      larghezza: c.larghezza_px,
      campo: dati.campo,
      calcolato: dati.calcolato,
      numerica: dati.numerica ?? false,
    };
  });

export const PER_ID: ReadonlyMap<string, Colonna> = new Map(COLONNE.map((c) => [c.id, c]));

/** La colonna che mostra un campo battuto. */
export function colonnaDi(campo: CampoRiga): Colonna {
  const colonna = COLONNE.find((c) => c.campo === campo);
  if (!colonna) throw new Error(`nessuna colonna per ${campo}`);
  return colonna;
}

/**
 * Sequenza di battitura con `Invio` (memoria muscolare dell'operatore, direttiva §3.3):
 * Articolo → UM → Colli → Lordo → Tara → Prezzo → nuova riga. Vale qualunque sia l'ordine
 * delle colonne scelto dall'operatore.
 */
export const SEQUENZA_INVIO: readonly CampoRiga[] = ["articolo", "unita_misura", "colli", "lordo", "tara", "prezzo"];

/** La griglia righe per il layout salvato: l'articolo non si nasconde, è dove parte ogni riga. */
export const GRIGLIA_RIGHE = { colonne: COLONNE, chiave: "atlas.griglia.righe.v1", fisse: ["ColCd_AR"] } as const;
