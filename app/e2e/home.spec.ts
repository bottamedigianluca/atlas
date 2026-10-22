import { expect, test } from "@playwright/test";

test("Home come Arca: menu, cerca comando, nomi e post-it da barrare", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.goto("/");
  for (const widget of ["Da chiamare oggi", "Post-it", "DDT di oggi", "Numeri liberi"]) {
    await expect(page.getByRole("region", { name: widget })).toBeVisible();
  }
  await expect(page.getByRole("region", { name: "Numeri liberi" })).toContainText("Prossimo");

  // Da chiamare: un tocco barra il nome.
  const nomi = page.getByRole("list", { name: "Clienti da chiamare" }).getByRole("button", { pressed: false });
  if (await nomi.count()) {
    const nome = (await nomi.first().textContent()) ?? "";
    await nomi.first().click();
    await expect(page.getByRole("button", { name: nome, exact: true })).toHaveAttribute("aria-pressed", "true");
  }

  // Post-it: la riga si scrive con Invio, si barra con un tocco, resta dopo il riavvio, si toglie.
  await page.getByLabel("Nuova riga del post-it").fill("Cassette a Dinamos");
  await page.keyboard.press("Enter");
  const riga = page.getByRole("list", { name: "Righe del post-it" }).getByRole("button", { name: "Cassette a Dinamos", exact: true });
  await expect(riga).toHaveAttribute("aria-pressed", "false");
  await riga.click();
  await expect(riga).toHaveAttribute("aria-pressed", "true");
  await page.screenshot({ path: "test-results/vetrina-home-chiaro.png" });
  await page.reload();
  await expect(riga).toHaveAttribute("aria-pressed", "true");
  await page.getByRole("button", { name: "Togli: Cassette a Dinamos" }).click();
  await expect(riga).toHaveCount(0);

  // "Cosa vuoi fare?" › Documenti › Nuovo Documento, come in Arca.
  const menu = page.getByRole("navigation", { name: "Cosa vuoi fare?" });
  await menu.getByRole("button", { name: "Documenti", exact: true }).click();
  await expect(menu.getByRole("button", { name: "Gestione", exact: true })).toBeVisible();
  await page.screenshot({ path: "test-results/vetrina-home-menu-chiaro.png" });
  await menu.getByRole("button", { name: "Nuovo Documento", exact: true }).click();
  await expect(page.locator("#testata-cliente")).toBeFocused();

  // Partita IVA online dal menu Anagrafiche: i dati ufficiali nei campi dell'anagrafica.
  await page.keyboard.press("Control+0");
  await menu.getByRole("button", { name: "Anagrafiche", exact: true }).click();
  await menu.getByRole("button", { name: "Partita IVA online", exact: true }).click();
  const finestra = page.getByRole("dialog", { name: "Partita IVA" });
  await finestra.getByLabel("Partita IVA").fill("IT 02273530226");
  await page.keyboard.press("Enter");
  const dati = finestra.getByRole("table", { name: "Dati dell'azienda" });
  await expect(dati).toContainText("BOTTAMEDI PIERLUIGI");
  await expect(dati).toContainText("VIA S. ANTONIO 7");
  await expect(dati).toContainText("MEZZOLOMBARDO");
  await expect(finestra).toContainText("Partita IVA attiva");
  await finestra.getByLabel("Partita IVA").fill("02273530227");
  await page.keyboard.press("Enter");
  await expect(finestra.getByRole("alert")).toContainText("cifra di controllo");
  await page.keyboard.press("Escape");

  // Cerca comando: "gest" + Invio apre l'elenco.
  await page.getByLabel("Cerca comando").fill("gest");
  await page.keyboard.press("Enter");
  await expect(page.getByRole("grid", { name: "Documenti" })).toBeVisible();
});
