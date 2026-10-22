import { type Page, expect, test } from "@playwright/test";

async function apriDalMenu(page: Page, gruppo: string, voce: string) {
  await page.goto("/");
  const menu = page.getByRole("navigation", { name: "Cosa vuoi fare?" });
  await menu.getByRole("button", { name: gruppo, exact: true }).click();
  await menu.getByRole("button", { name: voce, exact: true }).click();
}

test("Clienti: elenco con le colonne di Arca, scheda a sezioni, documenti, frecce ed Esc", async ({ page }) => {
  await apriDalMenu(page, "Anagrafiche", "Clienti");
  const elenco = page.getByRole("grid", { name: "Elenco Clienti" });
  await expect(elenco).toBeFocused();
  const nomi = await page.getByRole("columnheader").allTextContents();
  expect(nomi.slice(0, 8)).toEqual(["Ragione Sociale", "Codice", "Indirizzo", "CAP", "Località", "Provincia", "Nazione", "Telefono"]);
  expect(nomi).toContain("Cod.Dest./Email B2B");

  // Filtro sul codice, Invio torna alla griglia, Invio apre la scheda.
  await elenco.getByLabel("Filtro Codice", { exact: true }).fill("C000179");
  await page.keyboard.press("Enter");
  await expect(elenco.getByRole("row", { selected: true })).toContainText("Catering Service");
  await page.keyboard.press("Enter");
  const scheda = page.getByRole("region", { name: "Scheda cliente" });
  await expect(scheda.getByRole("heading", { level: 2 })).toContainText("C000179");
  for (const sezione of ["Anagrafica", "Contatti", "Fatturazione elettronica", "Condizioni", "Banca", "DDT", "Export", "Documenti", "Note"]) {
    await expect(scheda.getByRole("region", { name: sezione, exact: true })).toBeVisible();
  }
  await expect(scheda.getByLabel("Ragione sociale", { exact: true })).toHaveValue(/Catering Service/);
  await expect(scheda.getByLabel("Ragione sociale", { exact: true })).toHaveAttribute("readonly", "");
  const documenti = scheda.getByRole("table", { name: "Documenti del cliente" });
  await expect(documenti.getByRole("row")).toHaveCount(31);
  await page.screenshot({ path: "test-results/vetrina-cliente-chiaro.png" });

  // Il DDT si apre nella Gestione Documenti.
  await documenti.getByRole("button", { name: "Apri" }).first().click();
  await expect(page.getByRole("tab", { name: /Gestione Documenti/, selected: true })).toBeVisible();
  await page.getByRole("tab", { name: "Clienti" }).click();

  // Esc torna all'elenco sulla stessa riga; senza filtro, Alt+→ apre il cliente dopo.
  await page.keyboard.press("Escape");
  await expect(elenco).toBeVisible();
  await elenco.getByLabel("Filtro Codice", { exact: true }).fill("");
  await page.keyboard.press("Enter");
  await expect(elenco.getByRole("row", { selected: true })).toContainText("C000179");
  await page.keyboard.press("Control+2");
  await page.keyboard.press("Alt+ArrowRight");
  await expect(scheda.getByRole("heading", { level: 2 })).not.toContainText("C000179");
});

test("Nuovo cliente dalla partita IVA: controlli, F10 salva in ATLAS e la scheda lo mostra", async ({ page }) => {
  await apriDalMenu(page, "Anagrafiche", "Clienti");
  await expect(page.getByRole("grid", { name: "Elenco Clienti" })).toBeFocused();

  // Senza ragione sociale né partita IVA: F10 dice cosa manca, senza salvare.
  await page.keyboard.press("Control+n");
  const finestra = page.getByRole("dialog", { name: "Partita IVA" });
  await finestra.getByRole("button", { name: "Nuovo cliente senza partita IVA" }).click();
  const scheda = page.getByRole("region", { name: "Scheda cliente" });
  await expect(scheda.getByRole("heading", { level: 2 })).toContainText("Nuovo cliente C");
  await page.keyboard.press("F10");
  const errore = scheda.getByRole("alert");
  await expect(errore).toContainText("manca la ragione sociale");
  await expect(errore).toContainText("serve la partita IVA o il codice fiscale");

  // Dalla partita IVA: VIES riempie la scheda con i predefiniti di Arca.
  await page.keyboard.press("Control+n");
  await finestra.getByLabel("Partita IVA", { exact: true }).fill("02273530226");
  await page.keyboard.press("Enter");
  await finestra.getByRole("button", { name: "Nuovo cliente con questi dati" }).click();
  const titolo = scheda.getByRole("heading", { level: 2 });
  await expect(titolo).toContainText("Nuovo cliente C");
  const codice = ((await titolo.textContent()) ?? "").match(/C\d{6}/)![0];
  await expect(scheda.getByLabel("Ragione sociale", { exact: true })).toHaveValue("BOTTAMEDI PIERLUIGI");
  await expect(scheda.getByLabel("Valuta", { exact: true })).toHaveValue("EUR");
  await expect(scheda.getByLabel("Conto mastro", { exact: true })).toHaveValue("04010101001");
  await scheda.getByLabel("Telefono", { exact: true }).fill("0461 602534");
  await scheda.getByLabel("Codice destinatario", { exact: true }).fill("0000000");
  await page.screenshot({ path: "test-results/vetrina-nuovo-cliente-chiaro.png" });
  await page.keyboard.press("F10");

  await expect(scheda.getByRole("status")).toContainText(`Cliente ${codice} salvato: in coda per Arca`);
  await expect(titolo).toContainText(codice);
  await expect(scheda.getByLabel("Ragione sociale", { exact: true })).toHaveAttribute("readonly", "");
  await expect(scheda.getByRole("table", { name: "Contatti" })).toContainText("Aziendale");
  await expect(scheda.getByLabel("Lingua", { exact: true })).toHaveValue("1040");

  // Nell'elenco, con il telefono del contatto aziendale.
  await page.keyboard.press("Escape");
  const elenco = page.getByRole("grid", { name: "Elenco Clienti" });
  await elenco.getByLabel("Filtro Codice", { exact: true }).fill(codice);
  await expect(elenco.getByRole("row", { selected: true })).toContainText("0461 602534");
});

test("Articoli: elenco come Arca e scheda con unità di misura e prezzi validi oggi", async ({ page }) => {
  await apriDalMenu(page, "Articoli", "Gestione Articoli");
  const elenco = page.getByRole("grid", { name: "Elenco Articoli" });
  await expect(elenco).toBeFocused();
  const nomi = await page.getByRole("columnheader").allTextContents();
  expect(nomi.slice(0, 4)).toEqual(["Codice", "Descrizione", "Famiglia", "Marca"]);
  expect(nomi).toContain("IVA vend.");
  await elenco.getByLabel("Filtro Codice", { exact: true }).fill("TREN");
  await page.keyboard.press("Enter");
  await page.keyboard.press("Enter");
  const scheda = page.getByRole("region", { name: "Scheda articolo" });
  await expect(scheda.getByRole("heading", { level: 2 })).toContainText("TREN");
  for (const sezione of ["Generale", "IVA e conti", "Fattura elettronica", "Prezzi", "Magazzino", "Produzione", "eBusiness"]) {
    await expect(scheda.getByRole("region", { name: sezione, exact: true })).toBeVisible();
  }
  await expect(scheda.getByRole("table", { name: "Unità di misura" })).toBeVisible();
  await expect(scheda.getByRole("table", { name: "Prezzi validi oggi" }).getByRole("row")).not.toHaveCount(1);
  await page.screenshot({ path: "test-results/vetrina-articolo-chiaro.png" });
  // Gli articoli si modificano in Arca: Salva resta spento.
  await expect(page.getByRole("button", { name: /^Salva/ })).toBeDisabled();
});
