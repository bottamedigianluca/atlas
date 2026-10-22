import { type Page, expect } from "@playwright/test";

export async function batti(page: Page, ...tasti: string[]) {
  for (const t of tasti) {
    if (["Enter", "Escape", "ArrowDown", "ArrowUp", "Tab", "F3", "F10", "F12"].includes(t)) await page.keyboard.press(t);
    else await page.keyboard.type(t);
  }
}

export function cella(page: Page, riga: number, campo: string) {
  return page.locator(`input[data-riga="${riga}"][data-campo="${campo}"]`);
}

/** Cliente battuto e `Invio`; se il cliente ha destinazioni, `Invio` anche sulla destinazione proposta. */
export async function cliente(page: Page, codice: string) {
  await expect(page.locator("#testata-cliente")).toBeFocused();
  await batti(page, codice, "Enter");
  const prossimo = page.locator(`#testata-destinazione:focus, input[data-riga="0"][data-campo="articolo"]:focus`);
  await expect(prossimo).toHaveCount(1);
  if ((await prossimo.getAttribute("id")) === "testata-destinazione") await batti(page, "Enter");
  await expect(cella(page, 0, "articolo")).toBeFocused();
}
