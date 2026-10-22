import type { Prezzi, VoceUltimo } from "../api/tipi";
import { costruisciVoci } from "./FinestraPrezzi";

const documento: Prezzi["documento"] = {
  articolo: "ARA2",
  descrizione: "ARANCE",
  cliente: "C000059",
  ragione_sociale: "Cliente di prova",
  listino_cliente: null,
  data: "2026-10-21",
  valuta: "EUR",
  unita_misura: "KG",
  fattore: "1",
  quantita: null,
  aliquota: "4",
  percentuale_iva: "4",
};

const ultimo: VoceUltimo = {
  tipo: "ultimo_assoluto",
  descrizione: "Ultimo prezzo",
  documento: { id: 7, tipo: "BO", numero: 5458, data: "2026-10-22", cliente: "C000387", ragione_sociale: "Altro" },
  riga: 1,
  unita_misura: "KG",
  fattore: "1",
  quantita: "15",
  aliquota: "4",
  percentuale_iva: "4",
  prezzo: "1.55",
  prezzo_ivato: "1.55",
  sconto: "",
  prezzo_riga: "1.55",
};

const prezzi: Prezzi = {
  documento,
  listini: [
    {
      listino: "0000001",
      descrizione: "Listino 1",
      descrizione_revisione: "Listino 1",
      proposto: true,
      ivato: false,
      revisione: 3,
      valido_dal: "2026-01-01",
      id_listino_articolo: 11,
      prezzo_listino: "1.55",
      prezzo_documento: "1.55",
      sconto: null,
      prezzo_riga: "1.55",
    },
    {
      listino: "0000002",
      descrizione: "Listino 2",
      descrizione_revisione: "Listino 2",
      proposto: false,
      ivato: false,
      revisione: null,
      valido_dal: null,
      id_listino_articolo: null,
      prezzo_listino: "0",
      prezzo_documento: "0",
      sconto: null,
      prezzo_riga: null,
    },
  ],
  ultimi: [ultimo],
  ultimo_acquisto: null,
};

test("voci F3 come la maschera PREZZO/COSTO ARTICOLO di Arca", () => {
  const voci = costruisciVoci(prezzi, "1.55");
  expect(voci.map((v) => v.descrizione)).toEqual([
    "Articolo ARA2 doc. BO / C000059 del 21-10-2026",
    "Listino 1 - Listino 1",
    "Listino 2 - Listino 2",
    "Prz. ultimo doc. BOLLA VENDITA di C000059",
    "Prz. ultimo doc. BOLLA VENDITA (BO / C000387 del 22-10-2026)",
    "Prz. ultimo doc. tipo Bolla di C000059",
    "Prz. ultimo doc. tipo Bolla (BO / C000387 del 22-10-2026)",
    "Ultimo Acquisto",
  ]);
  const [doc, l1, l2, bvCliente, bvAssoluto] = voci;
  // Dati da documento: il prezzo già nella riga, non si riporta.
  expect(doc).toMatchObject({ sezione: "documento", prezzoListino: "1.55", riporta: null, quantita: "0" });
  // Il listino senza l'articolo resta, a zero, e si riporta come in Arca.
  expect(l1).toMatchObject({ proposta: true, riporta: "1.55", prezzoDocumento: "1.55" });
  expect(l2).toMatchObject({ prezzoListino: "0", riporta: "0" });
  // Senza documento la voce è vuota (corsivo, nessun riporta).
  expect(bvCliente).toMatchObject({ vuota: true, riporta: null, fattore: "0" });
  expect(bvAssoluto).toMatchObject({ icona: "persona", quantita: "15", aliquota: "4", riporta: "1.55" });
});
