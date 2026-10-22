// Fotografie delle schermate principali, chiaro e scuro, da confrontare con `docs/screenshot_arca/`.
import { type Page, expect, test } from "@playwright/test";
import { apri, cliente } from "./aiuti";

async function riempi(page: Page) {
  await apri(page);
  await cliente(page, "C000380");
  for (const [articolo, colli, lordo, tara] of [
    ["GEN", "2", "12.4", "0.3"],
    ["POMG", "1", "6.15", "0.4"],
    ["ZUC", "3", "15.2", "0.3"],
  ]) {
    await page.keyboard.type(articolo!);
    await page.keyboard.press("Enter");
    await page.keyboard.press("Enter");
    for (const v of [colli!, lordo!, tara!]) {
      await page.keyboard.type(v);
      await page.keyboard.press("Enter");
    }
    await page.keyboard.press("Enter");
  }
  await page.keyboard.press("ArrowUp");
  await page.keyboard.press("ArrowUp");
  await page.keyboard.press("ArrowUp");
}

test("maschera piena, chiaro", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await riempi(page);
  await expect(page.getByLabel("Totali del documento")).not.toContainText("Totale 0.00");
  await page.screenshot({ path: "test-results/vetrina-maschera-chiaro.png" });
  for (const scheda of ["Testa", "Piede", "Totali"]) {
    await page.getByRole("tab", { name: new RegExp(`^${scheda}`) }).click();
    await page.screenshot({ path: `test-results/vetrina-scheda-${scheda.toLowerCase()}-chiaro.png` });
  }
});

test("F3 prezzi, chiaro e scuro", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await riempi(page);
  for (let i = 0; i < 5; i++) await page.keyboard.press("Enter");
  await page.keyboard.press("F3");
  await expect(page.getByRole("dialog", { name: "PREZZO/COSTO ARTICOLO" })).toContainText("Ultimi prezzi");
  await page.screenshot({ path: "test-results/vetrina-f3-chiaro.png" });
  await page.emulateMedia({ colorScheme: "dark" });
  await page.screenshot({ path: "test-results/vetrina-f3-scuro.png" });
});

test("elenco documenti e informazioni, chiaro", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await apri(page);
  await page.keyboard.press("Control+1");
  await expect(page.getByRole("grid", { name: "Documenti" }).locator("[role=row][aria-selected=true]")).toBeVisible();
  await page.screenshot({ path: "test-results/vetrina-elenco-chiaro.png" });
  await page.keyboard.press("F1");
  await expect(page.getByRole("dialog", { name: "Informazioni di sistema" })).toContainText("ATLAS OPERATING SYSTEM");
  await page.screenshot({ path: "test-results/vetrina-informazioni-chiaro.png" });
  // I dati dell'azienda confrontati con quelli ufficiali della nostra partita IVA.
  await page.getByRole("button", { name: "Verifica online" }).click();
  const verifica = page.getByRole("dialog", { name: "Partita IVA" });
  await expect(verifica.getByRole("table", { name: "Dati dell'azienda" })).toContainText("Via S. Antonio, 7 ✓");
  await expect(verifica).not.toContainText("≠");
  await page.screenshot({ path: "test-results/vetrina-partita-iva-chiaro.png" });
});
