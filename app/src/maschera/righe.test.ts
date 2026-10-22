import type { CampoRiga } from "../griglia/colonne";
import { type Azione, type StatoRighe, inBozza, iniziale, riduci } from "./righe";

const TUTTI: CampoRiga[] = ["articolo", "descrizione", "unita_misura", "colli", "lordo", "tara", "quantita", "prezzo", "sconto", "magazzino"];

function esegui(stato: StatoRighe, ...azioni: Azione[]): StatoRighe {
  return azioni.reduce(riduci, stato);
}

/** Batte `valore` nella cella del cursore e preme Invio. */
function batti(stato: StatoRighe, valore: string, visibili = TUTTI): StatoRighe {
  const { riga, campo } = stato.cursore;
  return esegui(stato, { tipo: "scrivi", riga, campo, valore }, { tipo: "invio", visibili });
}

test("Invio segue Articolo → UM → Colli → Lordo → Tara → Prezzo → nuova riga", () => {
  let s = iniziale();
  const visti: CampoRiga[] = [];
  for (const valore of ["BAN", "", "1", "5,46", "0,30"]) {
    s = batti(s, valore);
    visti.push(s.cursore.campo);
  }
  expect(visti).toEqual(["unita_misura", "colli", "lordo", "tara", "prezzo"]);
  s = batti(s, "1,80");
  expect(s.cursore).toEqual({ riga: 1, campo: "articolo" });
  expect(s.righe).toHaveLength(2);
});

test("la sequenza salta le colonne nascoste", () => {
  const senzaUm = TUTTI.filter((c) => c !== "unita_misura");
  const s = batti(iniziale(), "BAN", senzaUm);
  expect(s.cursore.campo).toBe("colli");
});

test("Invio fuori sequenza va alla colonna a destra", () => {
  const s = esegui(iniziale(), { tipo: "vai", cursore: { riga: 0, campo: "descrizione" } }, { tipo: "invio", visibili: TUTTI });
  expect(s.cursore.campo).toBe("unita_misura");
});

test("Freccia Giù: stessa colonna se la riga sotto c'è, altrimenti nuova riga sull'articolo", () => {
  let s = batti(iniziale(), "BAN");
  s = esegui(s, { tipo: "vai", cursore: { riga: 0, campo: "prezzo" } }, { tipo: "giu" });
  expect(s.cursore).toEqual({ riga: 1, campo: "articolo" });
  expect(s.righe).toHaveLength(2);
  s = batti(s, "PIST");
  s = esegui(s, { tipo: "vai", cursore: { riga: 0, campo: "tara" } }, { tipo: "giu" });
  expect(s.cursore).toEqual({ riga: 1, campo: "tara" });
  expect(s.righe).toHaveLength(2);
  s = esegui(s, { tipo: "su" });
  expect(s.cursore).toEqual({ riga: 0, campo: "tara" });
});

test("Freccia Giù da una riga vuota in fondo non accumula righe vuote", () => {
  const s = esegui(iniziale(), { tipo: "giu" }, { tipo: "giu" });
  expect(s.righe).toHaveLength(1);
  expect(s.cursore).toEqual({ riga: 0, campo: "articolo" });
});

test("tara × colli ≥ lordo: avviso, Esc corregge, Invio conferma e prosegue", () => {
  let s = iniziale();
  for (const v of ["BAN", "", "2", "0,5"]) s = batti(s, v);
  s = batti(s, "0,30");
  expect(s.avviso?.codice).toBe("tara_maggiore_lordo");
  expect(s.cursore.campo).toBe("tara");
  s = riduci(s, { tipo: "esc" });
  expect(s.cursore.campo).toBe("tara");
  expect(s.avviso).toBeNull();
  s = riduci(s, { tipo: "invio", visibili: TUTTI });
  expect(s.avviso?.codice).toBe("tara_maggiore_lordo");
  s = riduci(s, { tipo: "invio", visibili: TUTTI });
  expect(s.avviso).toBeNull();
  expect(s.cursore.campo).toBe("prezzo");
  // Confermato per quei valori: tornando sulla tara non ricompare.
  s = esegui(s, { tipo: "vai", cursore: { riga: 0, campo: "tara" } }, { tipo: "invio", visibili: TUTTI });
  expect(s.avviso).toBeNull();
});

test("colli con i decimali: avviso anche uscendo con la freccia", () => {
  let s = batti(iniziale(), "BAN");
  s = batti(s, "");
  s = riduci(s, { tipo: "scrivi", riga: 0, campo: "colli", valore: "5,4" });
  s = riduci(s, { tipo: "giu" });
  expect(s.avviso?.codice).toBe("colli_decimali");
  s = riduci(s, { tipo: "invio", visibili: TUTTI });
  expect(s.cursore).toEqual({ riga: 1, campo: "articolo" });
  expect(s.righe).toHaveLength(2);
});

test("Esc annulla la modifica della cella, poi toglie la riga vuota", () => {
  let s = batti(iniziale(), "BAN");
  s = esegui(s, { tipo: "vai", cursore: { riga: 0, campo: "prezzo" } }, { tipo: "giu" });
  s = riduci(s, { tipo: "scrivi", riga: 1, campo: "articolo", valore: "PI" });
  s = riduci(s, { tipo: "esc" });
  expect(s.righe[1]?.articolo).toBe("");
  s = riduci(s, { tipo: "esc" });
  expect(s.righe).toHaveLength(1);
  expect(s.cursore.riga).toBe(0);
});

test("righe nella bozza: numeri con il punto, vuoti tolti", () => {
  let s = batti(iniziale(), "BAN");
  for (const v of ["", "1", "5,46", "0,30"]) s = batti(s, v);
  expect(inBozza(s.righe)).toEqual([{ articolo: "BAN", colli: "1", lordo: "5.46", tara: "0.30" }]);
});
