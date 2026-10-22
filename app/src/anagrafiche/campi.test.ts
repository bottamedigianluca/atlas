import sorgente from "../../../crates/atlas-sync/src/anagrafiche.rs?raw";
import type { ArticoloScheda, ClienteScheda, Tabelle } from "../api/tipi";
import {
  SEZIONI_ARTICOLO,
  SEZIONI_CLIENTE,
  colonne,
  corpoNuovoCliente,
  descrizioneCampo,
  nuovoCliente,
  recordArticolo,
  recordCliente,
  testoCampo,
} from "./campi";

/** Le colonne di un elenco `const NOME: &[(&str, Tipo)]` dell'importazione. */
function colonneImportate(nome: string): string[] {
  const inizio = sorgente.indexOf(`const ${nome}`);
  const fine = sorgente.indexOf("];", inizio);
  expect(inizio).toBeGreaterThan(0);
  return [...sorgente.slice(inizio, fine).matchAll(/\("(\w+)", Tipo::/g)].map((m) => m[1]!);
}

test("ogni colonna di CF e AR importata da Arca ha il suo campo nella scheda", () => {
  const cf = colonneImportate("CF_EXTRA");
  const ar = colonneImportate("AR_EXTRA");
  expect(cf.length).toBeGreaterThanOrEqual(70);
  expect(ar.length).toBeGreaterThanOrEqual(48);
  expect(cf.filter((c) => !colonne(SEZIONI_CLIENTE).includes(c))).toEqual([]);
  expect(ar.filter((c) => !colonne(SEZIONI_ARTICOLO).includes(c))).toEqual([]);
});

test("nessuna colonna compare due volte nella stessa scheda", () => {
  for (const sezioni of [SEZIONI_CLIENTE, SEZIONI_ARTICOLO]) {
    const tutte = colonne(sezioni);
    expect(tutte.filter((c, i) => tutte.indexOf(c) !== i)).toEqual([]);
  }
});

test("record con i nomi di Arca: campi della scheda più extra", () => {
  const cliente = {
    codice: "C000179",
    ragione_sociale: "DINAMOS",
    pagamento: "R060",
    scissione_pagamenti: true,
    destinazioni: [],
    // Come C000001 in Arca: prima una persona, poi l'"Aziendale" (tipo -1) con telefono e fax.
    contatti: [
      { id: 604, destinazione: null, dati: { Descrizione: "BEATRICI EDY", Id_CFContattoTipo: 1 } },
      { id: 357, destinazione: null, dati: { Descrizione: "Aziendale", Telefono: "0461 602772", Fax: "0461 602772", Id_CFContattoTipo: -1 } },
    ],
    extra: { Cd_LS_2: "0000002", SpeseBolli: false },
  } as unknown as ClienteScheda;
  const r = recordCliente(cliente);
  expect(r).toMatchObject({ Cd_CF: "C000179", Descrizione: "DINAMOS", Cd_PG: "R060", IvaSplit: true, Cd_LS_2: "0000002", SpeseBolli: false });
  expect(r["CFContatto.Telefono"]).toBe("0461 602772");
  const articolo = { codice: "GEN", descrizione: "GENERICO", unita_misura: "KG", aliquota: "04", extra: null } as unknown as ArticoloScheda;
  expect(recordArticolo(articolo)).toMatchObject({ Cd_AR: "GEN", Cd_ARMisura: "KG", Cd_Aliquota_V: "04" });
});

test("valori come in Arca e decodifiche", () => {
  const campo = (colonna: string) => [...SEZIONI_CLIENTE, ...SEZIONI_ARTICOLO].flatMap((s) => s.campi).find((c) => c.colonna === colonna)!;
  expect(testoCampo(campo("SDD_DtMandato"), "2024-03-01 00:00:00")).toBe("01-03-2024");
  expect(testoCampo(campo("TimeUpd"), "2026-10-22 08:15:00")).toBe("22-10-2026 08:15");
  expect(testoCampo(campo("xCosto"), "1.5")).toBe("1.500");
  expect(testoCampo(campo("Fido"), null)).toBe("");
  const tabelle = { pagamenti: [{ codice: "R060", descrizione: "Ric.Banc. 60 gg DF FM" }] } as unknown as Tabelle;
  expect(descrizioneCampo(campo("Cd_PG"), "R060", tabelle)).toBe("Ric.Banc. 60 gg DF FM");
  expect(descrizioneCampo(campo("TipoDitta"), "G", null)).toBe("persona giuridica");
  expect(descrizioneCampo(campo("Cd_PG"), "", tabelle)).toBeUndefined();
});

test("cliente nuovo dai dati ufficiali con i predefiniti di Arca", () => {
  const r = nuovoCliente(
    "C000400",
    {
      nazione: "IT",
      partita_iva: "02273530226",
      attiva: true,
      ragione_sociale: "BOTTAMEDI PIERLUIGI",
      indirizzo: "VIA S. ANTONIO 7",
      cap: "38017",
      localita: "MEZZOLOMBARDO",
      provincia: "TN",
      indirizzo_vies: null,
      gia_presente: null,
    },
  );
  expect(r).toMatchObject({
    Cd_CF: "C000400",
    Descrizione: "BOTTAMEDI PIERLUIGI",
    PartitaIva: "02273530226",
    Localita: "MEZZOLOMBARDO",
    Cd_VL: "EUR",
    Cd_CGConto_Mastro: "04010101001",
    EsclusoBlackList: true,
    FE_AddASW: true,
  });
  expect(nuovoCliente("C000401", null, "12345678901")).toMatchObject({ PartitaIva: "12345678901", Descrizione: "", Id_Lingua: 1040 });
});

test("corpo di POST /api/clienti: CF e contatto aziendale separati", () => {
  const r = { ...nuovoCliente("C000400", null, "02273530226"), "CFContatto.Telefono": "0461 602534", "CFContatto.Email": "" };
  const corpo = corpoNuovoCliente(r);
  expect(corpo.cf.PartitaIva).toBe("02273530226");
  expect(corpo.cf["CFContatto.Telefono"]).toBeUndefined();
  expect(corpo.contatto).toEqual({ Telefono: "0461 602534", Email: "" });
  expect(corpoNuovoCliente(nuovoCliente("C000400", null)).contatto).toBeNull();
});
