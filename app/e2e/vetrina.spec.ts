// Fotografie delle schermate principali, chiaro e scuro, per il controllo del design.
import { type Page, expect, test } from "@playwright/test";

async function riempi(page: Page) {
  await page.goto("/");
  await page.keyboard.type("C000380");
  await page.keyboard.press("Enter");
  for (const [articolo, colli, lordo, tara] of [
    ["GEN", "2", "12,4", "0,3"],
    ["POMG", "1", "6,15", "0,4"],
    ["ZUC", "3", "15,2", "0,3"],
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
  await expect(page.locator("[data-prova='Totale documento']")).not.toHaveText("0,00");
  await page.screenshot({ path: "test-results/vetrina-maschera-chiaro.png" });
});

test("F3 prezzi, scuro", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "dark" });
  await riempi(page);
  for (let i = 0; i < 5; i++) await page.keyboard.press("Enter");
  await page.keyboard.press("F3");
  await expect(page.getByRole("dialog", { name: "PREZZO/COSTO ARTICOLO" })).toContainText("Ultimi prezzi");
  await page.screenshot({ path: "test-results/vetrina-f3-scuro.png" });
});

test("documenti e informazioni, scuro", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "dark" });
  await page.goto("/");
  await page.keyboard.press("Control+2");
  await expect(page.getByRole("grid", { name: "Documenti" }).locator("tbody tr").first()).toBeVisible();
  await page.screenshot({ path: "test-results/vetrina-documenti-scuro.png" });
  await page.keyboard.press("F1");
  await expect(page.getByRole("dialog", { name: "Informazioni di sistema" })).toContainText("ATLAS OPERATING SYSTEM");
  await page.screenshot({ path: "test-results/vetrina-informazioni-scuro.png" });
});
