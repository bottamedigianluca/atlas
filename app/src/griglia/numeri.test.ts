import { data, decimale, fattore, importo, mostra, prezzo, quantita, valore } from "./numeri";

test("decimali battuti con la virgola o il punto", () => {
  expect(decimale("5,46")).toBe("5.46");
  expect(decimale(" 0.30 ")).toBe("0.30");
  expect(decimale("12")).toBe("12");
  expect(decimale(",5")).toBe(".5");
  expect(decimale("3,")).toBe("3");
  expect(decimale("-1,5")).toBe("-1.5");
  expect(decimale("")).toBeNull();
  for (const errato of ["abc", "1.234,5", "1,2,3", "--1"]) expect(decimale(errato)).toBeUndefined();
  expect(valore("2,5")).toBe(2.5);
  expect(valore("x")).toBe(0);
});

test("numeri e date del backend come li mostra Arca", () => {
  expect(importo("1234.5")).toBe("1234.50");
  expect(prezzo("1.55")).toBe("1.550");
  expect(prezzo("1.8125")).toBe("1.8125");
  expect(fattore("1")).toBe("1.00000");
  expect(quantita("0")).toBe("0.00");
  expect(mostra("5.16")).toBe("5.16");
  expect(mostra(null)).toBe("");
  expect(data("2026-10-21")).toBe("21-10-2026");
});
