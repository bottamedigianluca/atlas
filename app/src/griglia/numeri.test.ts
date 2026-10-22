import { data, decimale, importo, mostra, prezzo, valore } from "./numeri";

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

test("numeri del backend in formato italiano senza perdere cifre", () => {
  expect(importo("1234.5")).toBe("1.234,50");
  expect(prezzo("1.5")).toBe("1,50");
  expect(prezzo("1.8125")).toBe("1,8125");
  expect(mostra("5.16")).toBe("5,16");
  expect(mostra(null)).toBe("");
  expect(data("2026-10-22")).toBe("22/10/2026");
});
