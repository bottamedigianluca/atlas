// Backend per le prove end-to-end: una copia di `dati/atlas.sqlite` in una cartella temporanea
// (il file versionato non si tocca), `atlas-server` sulla porta 7979, senza Arca.
import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { copyFileSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const radice = resolve(import.meta.dirname, "../..");
const cartella = mkdtempSync(join(tmpdir(), "atlas-e2e-"));
const copia = join(cartella, "atlas.sqlite");
copyFileSync(process.env.ATLAS_E2E_DB ?? join(radice, "dati", "atlas.sqlite"), copia);

// VIES finto (la rete delle prove non esce): risponde per la partita IVA di Bottamedi.
const vies = createServer((richiesta, risposta) => {
  let corpo = "";
  richiesta.on("data", (pezzo) => (corpo += pezzo));
  richiesta.on("end", () => {
    const { vatNumber } = JSON.parse(corpo || "{}");
    risposta.setHeader("content-type", "application/json");
    risposta.end(
      JSON.stringify(
        vatNumber === "02273530226"
          ? { countryCode: "IT", vatNumber, valid: true, name: "BOTTAMEDI PIERLUIGI", address: "VIA S. ANTONIO 7 \n38017 MEZZOLOMBARDO TN\n" }
          : { userError: "MS_UNAVAILABLE" },
      ),
    );
  });
}).listen(7980, "127.0.0.1");

const server = spawn("cargo", ["run", "--release", "-q", "-p", "atlas-server", "--", copia], {
  cwd: radice,
  stdio: "inherit",
  env: { ...process.env, ATLAS_INDIRIZZO: "127.0.0.1:7979", ATLAS_ARCA_ADO: "", ATLAS_VIES_URL: "http://127.0.0.1:7980/" },
});
const fine = () => {
  server.kill();
  vies.close();
  rmSync(cartella, { recursive: true, force: true });
};
process.on("SIGINT", fine);
process.on("SIGTERM", fine);
server.on("exit", (codice) => {
  vies.close();
  rmSync(cartella, { recursive: true, force: true });
  process.exit(codice ?? 0);
});
