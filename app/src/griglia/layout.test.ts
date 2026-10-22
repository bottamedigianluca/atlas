import { COLONNE } from "./colonne";
import { alterna, carica, layoutDiFabbrica, normalizza, ridimensiona, ripristina, salva, sposta, visibili } from "./layout";

test("40 colonne di UserPref 1443 nell'ordine e con le larghezze di Arca", () => {
  expect(COLONNE).toHaveLength(40);
  expect(COLONNE.slice(0, 10).map((c) => [c.etichetta, c.larghezza])).toEqual([
    ["Riga", 39],
    ["Articolo", 162],
    ["Descrizione", 421],
    ["UM", 78],
    ["Colli/Qta", 113],
    ["Lordo", 169],
    ["Tara", 104],
    ["Q.ta/Netto", 124],
    ["Prezzo Un.", 109],
    ["Totale", 147],
  ]);
  expect(new Set(COLONNE.map((c) => c.id)).size).toBe(40);
});

test("sposta, ridimensiona, nascondi; l'articolo resta sempre visibile", () => {
  let l = layoutDiFabbrica();
  l = sposta(l, "COLPREZZOUNITARIOV", "xColColli");
  expect(visibili(l).slice(0, 6)).toEqual(["ColRiga", "ColCd_AR", "ColDescrizione", "ColCd_ARMisura", "COLPREZZOUNITARIOV", "xColColli"]);
  l = ridimensiona(l, "ColDescrizione", 3);
  expect(l.larghezze.ColDescrizione).toBe(16);
  l = alterna(l, "ColDescrizione");
  expect(visibili(l)).not.toContain("ColDescrizione");
  l = alterna(l, "ColCd_AR");
  expect(visibili(l)).toContain("ColCd_AR");
});

test("salvato nella postazione, ripulito alla lettura, ripristinabile", () => {
  salva(alterna(ridimensiona(layoutDiFabbrica(), "xColLordo", 200), "ColDettagli"));
  const letto = carica();
  expect(letto.nascoste).toEqual(["ColDettagli"]);
  expect(letto.larghezze.xColLordo).toBe(200);
  const sporco = normalizza({ ordine: ["ColCd_AR", "Sconosciuta", "ColCd_AR"], larghezze: { ColRiga: "x" }, nascoste: ["ColCd_AR"] });
  expect(sporco.ordine[0]).toBe("ColCd_AR");
  expect(sporco.ordine).toHaveLength(40);
  expect(sporco.larghezze.ColRiga).toBe(39);
  expect(sporco.nascoste).toEqual([]);
  expect(ripristina()).toEqual(layoutDiFabbrica());
  expect(carica()).toEqual(layoutDiFabbrica());
  localStorage.setItem("atlas.griglia.righe.v1", "{non json");
  expect(carica()).toEqual(layoutDiFabbrica());
});
