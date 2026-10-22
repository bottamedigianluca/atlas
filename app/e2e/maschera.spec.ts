import { type Page, expect, test } from "@playwright/test";

const SERVER = "http://127.0.0.1:7979/api";

async function batti(page: Page, ...tasti: string[]) {
  for (const t of tasti) {
    if (["Enter", "Escape", "ArrowDown", "ArrowUp", "Tab", "F3", "F10", "F12"].includes(t)) await page.keyboard.press(t);
    else await page.keyboard.type(t);
  }
}

function cella(page: Page, riga: number, campo: string) {
  return page.locator(`input[data-riga="${riga}"][data-campo="${campo}"]`);
}

test("un DDT battuto solo da tastiera, con F3 prezzi, guardrail e F10", async ({ page }) => {
  await page.goto("/");
  await expect(page.locator("#cliente")).toBeFocused();

  // Cliente → Invio porta sull'articolo della prima riga.
  await batti(page, "C000179", "Enter");
  await expect(cella(page, 0, "articolo")).toBeFocused();
  await expect(page.locator("[data-prova=ragione-sociale]")).toContainText("Catering Service");

  // Articolo → UM → Colli → Lordo → Tara → Prezzo → nuova riga.
  await batti(page, "GEN", "Enter");
  await expect(cella(page, 0, "unita_misura")).toBeFocused();
  await batti(page, "Enter", "2", "Enter", "12,4", "Enter", "0,3", "Enter");
  await expect(cella(page, 0, "prezzo")).toBeFocused();
  // Prezzo proposto dal listino; Invio lo accetta e apre la riga 2.
  await expect(cella(page, 0, "prezzo")).toHaveAttribute("placeholder", "1,50");
  await batti(page, "Enter");
  await expect(cella(page, 1, "articolo")).toBeFocused();

  // Guardrail: tara × colli ≥ lordo. Esc torna sulla tara, Invio conferma.
  await batti(page, "ZUC", "Enter", "Enter", "3", "Enter", "1", "Enter", "0,4", "Enter");
  await expect(page.getByRole("alert")).toContainText("Tara 0,4 × 3 colli ≥ lordo 1");
  await batti(page, "Escape");
  await expect(page.getByRole("alert")).toHaveCount(0);
  await expect(cella(page, 1, "tara")).toBeFocused();
  await page.keyboard.press("Control+a");
  await batti(page, "0,2", "Enter");
  await expect(cella(page, 1, "prezzo")).toBeFocused();

  // F3 sul prezzo: la maschera PREZZO/COSTO ARTICOLO, Invio riporta il prezzo.
  await batti(page, "F3");
  const finestra = page.getByRole("dialog", { name: "PREZZO/COSTO ARTICOLO" });
  await expect(finestra).toBeVisible();
  await expect(finestra).toContainText("Prezzi da listino");
  await expect(finestra).toContainText("Ultimi prezzi da documenti");
  await expect(finestra).toContainText("Prz. ultimo doc. BOLLA VENDITA di Catering Service");
  await batti(page, "ArrowDown", "Enter");
  await expect(finestra).toHaveCount(0);
  await expect(cella(page, 1, "prezzo")).toBeFocused();
  await expect(cella(page, 1, "prezzo")).not.toHaveValue("");

  // Prezzo battuto a mano diverso dal listino: cella ambra.
  await page.keyboard.press("Control+a");
  await batti(page, "9,99");
  await expect(cella(page, 1, "prezzo")).toHaveClass(/bg-ambra-tenue/);

  // Freccia Giù dall'ultima riga: nuova riga sull'articolo. Da una riga vuota non ne crea altre.
  await batti(page, "ArrowDown");
  await expect(cella(page, 2, "articolo")).toBeFocused();
  await batti(page, "ArrowDown");
  await expect(cella(page, 3, "articolo")).toHaveCount(0);
  // Freccia Su: stessa colonna della riga sopra.
  await batti(page, "ArrowUp");
  await expect(cella(page, 1, "articolo")).toBeFocused();

  // Totali in tempo reale: GEN 12,4 − 2 × 0,3 = 11,8 kg × 1,50 = 17,70; ZUC 1 − 3 × 0,2 = 0,4 × 9,99 = 4,00.
  await expect(page.locator("[data-prova=Imponibile]")).toHaveText("21,70");

  // F10 salva: numero dalla numerazione unica, maschera pronta per il prossimo.
  await batti(page, "F10");
  const esito = page.getByRole("status");
  await expect(esito).toContainText(/DDT \d+\/\d{4} del .* salvato — totale € 22,57/);
  await expect(page.locator("#cliente")).toBeFocused();
  const numero = Number((await esito.textContent())?.match(/DDT (\d+)\//)?.[1]);

  const oggi = new Date().toLocaleDateString("sv-SE");
  const elenco = await (await page.request.get(`${SERVER}/ddt?numero=${numero}&dal=${oggi}`)).json();
  expect(elenco).toHaveLength(1);
  const scheda = await (await page.request.get(`${SERVER}/ddt/${elenco[0].id}`)).json();
  expect(scheda.righe.map((r: { articolo: string; quantita: string; totale: string }) => [r.articolo, r.quantita, r.totale])).toEqual([
    ["GEN", "11.8", "17.70"],
    ["ZUC", "0.4", "4.00"],
  ]);
  expect(scheda.documento.cliente).toBe("C000179");
  await page.screenshot({ path: "test-results/maschera-salvata.png" });
});
