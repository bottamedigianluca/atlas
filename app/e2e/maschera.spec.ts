import { expect, test } from "@playwright/test";
import { apri, batti, cella, cliente } from "./aiuti";

const SERVER = "http://127.0.0.1:7979/api";

test("un DDT battuto solo da tastiera, con F3 prezzi, guardrail e F10", async ({ page }) => {
  await apri(page);
  // La finestra si apre sulla pagina Generale con il cursore sul cliente, come in Arca.
  await expect(page.getByRole("tab", { name: /Generale/ })).toHaveAttribute("aria-selected", "true");
  const oggi = new Date();
  const oggiArca = `${String(oggi.getDate()).padStart(2, "0")}-${String(oggi.getMonth() + 1).padStart(2, "0")}-${oggi.getFullYear()}`;
  await expect(page.locator("#testata-data")).toHaveValue(oggiArca);

  await cliente(page, "C000179");
  await expect(page.locator("[data-prova=ragione-sociale]")).toContainText("Catering Service");

  // Articolo → UM → Colli → Lordo → Tara → Prezzo → nuova riga.
  await batti(page, "GEN", "Enter");
  await expect(cella(page, 0, "unita_misura")).toBeFocused();
  await batti(page, "Enter", "2", "Enter", "12.4", "Enter", "0.3", "Enter");
  await expect(cella(page, 0, "prezzo")).toBeFocused();
  // Prezzo proposto dal listino, con i decimali di Arca; Invio lo accetta e apre la riga 2.
  await expect(cella(page, 0, "prezzo")).toHaveAttribute("placeholder", "1.500");
  await batti(page, "Enter");
  await expect(cella(page, 1, "articolo")).toBeFocused();

  // Guardrail: tara × colli ≥ lordo. Esc torna sulla tara, Invio conferma.
  await batti(page, "ZUC", "Enter", "Enter", "3", "Enter", "1", "Enter", "0.4", "Enter");
  await expect(page.getByRole("alert")).toContainText("Tara 0.4 × 3 colli ≥ lordo 1");
  await batti(page, "Escape");
  await expect(page.getByRole("alert")).toHaveCount(0);
  await expect(cella(page, 1, "tara")).toBeFocused();
  await page.keyboard.press("Control+a");
  await batti(page, "0.2", "Enter");
  await expect(cella(page, 1, "prezzo")).toBeFocused();

  // F3 sul prezzo: la maschera PREZZO/COSTO ARTICOLO di Arca, Invio riporta il prezzo.
  await batti(page, "F3");
  const finestra = page.getByRole("dialog", { name: "PREZZO/COSTO ARTICOLO" });
  await expect(finestra).toBeVisible();
  for (const testo of ["Dati da documento", "Prezzi da listino", "Ultimi prezzi da documenti", "Listino 1", "Listino 2", "Ultimo Acquisto"]) {
    await expect(finestra).toContainText(testo);
  }
  await expect(finestra).toContainText("Articolo ZUC doc. BO / C000179 del");
  await expect(finestra).toContainText("Prz. ultimo doc. BOLLA VENDITA di C000179");
  await expect(finestra).toContainText("Prz. ultimo doc. tipo Bolla di C000179");
  await batti(page, "Enter");
  await expect(finestra).toHaveCount(0);
  await expect(cella(page, 1, "prezzo")).toBeFocused();
  await expect(cella(page, 1, "prezzo")).toHaveValue(/^\d+\.\d{3}$/);

  // Prezzo battuto a mano diverso dal listino: cella ambra.
  await page.keyboard.press("Control+a");
  await batti(page, "9.99");
  await expect(cella(page, 1, "prezzo")).toHaveClass(/bg-ambra-tenue/);

  // Freccia Giù dall'ultima riga: nuova riga sull'articolo. Da una riga vuota non ne crea altre.
  await batti(page, "ArrowDown");
  await expect(cella(page, 2, "articolo")).toBeFocused();
  await batti(page, "ArrowDown");
  await expect(cella(page, 3, "articolo")).toHaveCount(0);
  // Freccia Su: stessa colonna della riga sopra.
  await batti(page, "ArrowUp");
  await expect(cella(page, 1, "articolo")).toBeFocused();

  // Totali in tempo reale: GEN 12.4 − 2 × 0.3 = 11.8 kg × 1.50 = 17.70; ZUC 1 − 3 × 0.2 = 0.4 × 9.99 = 4.00.
  await expect(page.getByLabel("Totali del documento")).toContainText("Imponibile 21.70");

  // Scheda Totali (Ctrl+PgGiù fino a Totali) e ritorno alle Righe.
  await page.getByRole("tab", { name: /^Totali/ }).click();
  await expect(page.getByRole("region", { name: "Totali" })).toContainText("21.70");
  await page.getByRole("tab", { name: /^Righe/ }).click();

  // F10 salva: numero dalla numerazione unica, maschera pronta per il prossimo.
  await batti(page, "F10");
  const esito = page.getByRole("status");
  await expect(esito).toContainText(/DDT \d+\/\d{4} del \d{2}-\d{2}-\d{4} salvato — totale € 22.57/);
  await expect(page.locator("#testata-cliente")).toBeFocused();
  const numero = Number((await esito.textContent())?.match(/DDT (\d+)\//)?.[1]);

  const iso = oggi.toLocaleDateString("sv-SE");
  const elenco = await (await page.request.get(`${SERVER}/ddt?numero=${numero}&dal=${iso}`)).json();
  expect(elenco).toHaveLength(1);
  const scheda = await (await page.request.get(`${SERVER}/ddt/${elenco[0].id}`)).json();
  expect(scheda.righe.map((r: { articolo: string; quantita: string; totale: string }) => [r.articolo, r.quantita, r.totale])).toEqual([
    ["GEN", "11.8", "17.70"],
    ["ZUC", "0.4", "4.00"],
  ]);
  expect(scheda.documento.cliente).toBe("C000179");

  // Il DDT salvato è nell'elenco (Ctrl+1) e si riapre nella pagina Generale in sola lettura.
  await page.keyboard.press("Control+1");
  const documenti = page.getByRole("grid", { name: "Documenti" });
  await expect(documenti.locator("[role=row][aria-selected=true]")).toContainText(String(numero));
  await page.keyboard.press("Enter");
  await expect(page.locator("[data-prova=ragione-sociale]:visible")).toContainText("Catering Service");
  await expect(page.getByRole("button", { name: "Torna al documento in battitura" })).toBeVisible();
  // Riga dei filtri dell'elenco: la ragione sociale filtra le righe.
  await page.keyboard.press("Control+1");
  await page.getByLabel("Filtro Ragione Sociale").fill("catering");
  await expect(documenti.locator("[role=row][aria-selected]").first()).toContainText("Catering Service");
  await expect(page.getByText(/\d+ di \d+ documenti/)).toBeVisible();
  await page.getByLabel("Filtro Ragione Sociale").fill("");

  // Dal documento in battitura, Alt+→ (▶ di Arca) apre il documento più recente; il contatore dice dove si è.
  await page.keyboard.press("Control+2");
  await page.getByRole("button", { name: "Torna al documento in battitura" }).click();
  await expect(page.locator("#testata-cliente")).toBeVisible();
  await page.keyboard.press("Alt+ArrowRight");
  await expect(page.locator("[data-prova=ragione-sociale]:visible")).toContainText("Catering Service");
  await expect(page.getByLabel("Posizione nell'elenco")).toHaveText(/^1\/\d+$/);
  await page.keyboard.press("Alt+ArrowRight");
  await expect(page.getByLabel("Posizione nell'elenco")).toHaveText(/^2\/\d+$/);
  await page.screenshot({ path: "test-results/maschera-salvata.png" });
});
