import { expect, test } from "@playwright/test";

test("Home: clienti da chiamare, post-it condivisi, nuovo DDT intestato", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.goto("/");
  const daChiamare = page.getByRole("region", { name: "Da chiamare oggi" });
  await expect(daChiamare).toBeVisible();
  await expect(daChiamare).toContainText(/Clienti che il \S+ ordinano quasi sempre/);
  await expect(page.getByRole("region", { name: "DDT di oggi" })).toBeVisible();
  await expect(page.getByRole("region", { name: "Numeri liberi" })).toContainText("Prossimo numero");

  // Post-it: si scrive, resta dopo il riavvio (è nel database), si elimina.
  await page.getByRole("button", { name: "+ Nuovo post-it" }).click();
  const testo = page.getByLabel("Testo del post-it").last();
  await expect(testo).toBeFocused();
  await page.keyboard.type("Chiamare Dinamos per le cassette");
  await page.getByRole("heading", { name: "Bacheca" }).click();
  await expect(page.getByRole("article", { name: "Post-it: Chiamare Dinamos per le cassette" })).toBeVisible();
  await page.screenshot({ path: "test-results/vetrina-home-chiaro.png" });
  await page.reload();
  const nota = page.getByRole("article", { name: "Post-it: Chiamare Dinamos per le cassette" });
  await expect(nota).toBeVisible();
  await nota.getByRole("button", { name: "Colore rosa" }).click();
  await expect(nota).toHaveClass(/ffd3e4/);
  await nota.getByRole("button", { name: "Elimina post-it" }).click();
  await expect(nota).toHaveCount(0);

  // "Nuovo DDT" su un cliente da chiamare: la maschera è già intestata a lui.
  const primo = daChiamare.getByRole("button", { name: /^Nuovo DDT per / }).first();
  if (await primo.count()) {
    await primo.click();
    await expect(page.getByRole("tab", { name: /Generale/ })).toHaveAttribute("aria-selected", "true");
    await expect(page.locator("#testata-cliente")).toHaveValue(/^C\d+$/);
    await expect(page.locator("[data-prova=ragione-sociale]:visible")).not.toBeEmpty();
    // Ctrl+0 torna alla Home.
    await page.keyboard.press("Control+0");
    await expect(daChiamare).toBeVisible();
  }
});
