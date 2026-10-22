import { type Page, expect, test } from "@playwright/test";
import { cliente } from "./aiuti";

async function menuColonne(page: Page) {
  await page.getByRole("columnheader", { name: "Articolo" }).click({ button: "right" });
  return page.getByRole("menu", { name: "Colonne della griglia" });
}

test("colonne: nascondi dal clic destro, larghezza a trascinamento, persistenza e ripristino di fabbrica", async ({ page }) => {
  await page.goto("/");
  const intestazioni = page.getByRole("columnheader");
  await expect(intestazioni).toHaveCount(40);
  const descrizione = page.getByRole("columnheader", { name: "Descrizione" });
  expect((await descrizione.boundingBox())?.width).toBe(421);

  // Allarga la colonna Lordo trascinando il bordo destro.
  const lordo = page.getByRole("columnheader", { name: "Lordo", exact: true });
  const box = (await lordo.boundingBox())!;
  await page.mouse.move(box.x + box.width - 1, box.y + box.height / 2);
  await page.mouse.down();
  await page.mouse.move(box.x + box.width + 60, box.y + box.height / 2, { steps: 5 });
  await page.mouse.up();
  const allargata = Math.round((await lordo.boundingBox())!.width);
  expect(allargata).toBeGreaterThanOrEqual(228);
  expect(allargata).toBeLessThanOrEqual(231);

  // Nascondi la descrizione dal menu delle colonne (clic destro sulle intestazioni, come in Arca).
  await (await menuColonne(page)).getByLabel("Descrizione").uncheck();
  await page.keyboard.press("Escape");
  await expect(intestazioni).toHaveCount(39);

  // Dopo il riavvio il layout è quello dell'operatore.
  await page.reload();
  await expect(page.getByRole("columnheader")).toHaveCount(39);
  expect(Math.round((await page.getByRole("columnheader", { name: "Lordo", exact: true }).boundingBox())!.width)).toBe(allargata);

  // Ripristina layout di fabbrica.
  await (await menuColonne(page)).getByRole("button", { name: "Ripristina layout di fabbrica" }).click();
  await expect(page.getByRole("columnheader")).toHaveCount(40);
  expect((await page.getByRole("columnheader", { name: "Lordo", exact: true }).boundingBox())?.width).toBe(169);
});

test("riordino a trascinamento: la sequenza Invio non cambia", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("columnheader", { name: "Prezzo Un." }).dragTo(page.getByRole("columnheader", { name: "Colli/Qta" }));
  const nomi = await page.getByRole("columnheader").allTextContents();
  expect(nomi.slice(3, 6)).toEqual(["UM", "Prezzo Un.", "Colli/Qta"]);
  await page.locator("#testata-cliente").focus();
  await cliente(page, "C000179");
  await page.keyboard.type("GEN");
  for (const atteso of ["unita_misura", "colli", "lordo", "tara", "prezzo"]) {
    await page.keyboard.press("Enter");
    await expect(page.locator(`input[data-riga="0"][data-campo="${atteso}"]`)).toBeFocused();
  }
});

test("F3: ricerca cliente e articolo, numeri liberi, elenco documenti", async ({ page }) => {
  await page.goto("/");
  await expect(page.locator("#testata-cliente")).toBeFocused();
  await page.keyboard.press("F3");
  const clienti = page.getByRole("dialog", { name: "Clienti" });
  await page.keyboard.type("catering");
  await expect(clienti.getByRole("option").first()).toContainText("Catering Service");
  await page.keyboard.press("Enter");
  await expect(page.locator("#testata-cliente")).toHaveValue("C000179");
  const prossimo = page.locator(`#testata-destinazione:focus, input[data-riga="0"][data-campo="articolo"]:focus`);
  await expect(prossimo).toHaveCount(1);
  if ((await prossimo.getAttribute("id")) === "testata-destinazione") await page.keyboard.press("Enter");
  await expect(page.locator('input[data-riga="0"][data-campo="articolo"]')).toBeFocused();

  await page.keyboard.press("F3");
  // Il codice battuto per intero viene prima degli articoli che lo hanno nella descrizione.
  await page.keyboard.type("zuc");
  await expect(page.getByRole("dialog", { name: "Articoli" }).getByRole("option").first().locator("span").first()).toHaveText("ZUC");
  await page.keyboard.press("Enter");
  await expect(page.locator('input[data-riga="0"][data-campo="articolo"]')).toHaveValue("ZUC");

  // F3 sul numero: i buchi di Arca (il 5447 del 21-10) e il prossimo numero.
  await page.locator("#testata-numero").focus();
  await page.keyboard.press("F3");
  const liberi = page.getByRole("dialog", { name: /Numeri liberi BO/ });
  await expect(liberi).toContainText("Prossimo valore disponibile: 5459");
  await expect(liberi).toContainText("5447");
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Enter");
  await expect(page.locator("#testata-numero")).toHaveValue("5447");

  // Pagina Elenco (Ctrl+1): Invio apre il DDT nella pagina Generale; il documento in battitura resta.
  await page.keyboard.press("Control+1");
  const elenco = page.getByRole("grid", { name: "Documenti" });
  await expect(elenco).toBeFocused();
  await expect(elenco.locator("[role=row][aria-selected=true]")).toContainText("5458");
  await page.keyboard.press("Enter");
  await expect(page.locator("[data-prova=ragione-sociale]:visible")).toContainText("Dinamos");
  await page.getByRole("button", { name: "Torna al documento in battitura" }).click();
  await expect(page.locator("#testata-numero")).toHaveValue("5447");
});
