// Backend per le prove end-to-end: una copia di `dati/atlas.sqlite` in una cartella temporanea
// (il file versionato non si tocca), `atlas-server` sulla porta 7979, senza Arca.
import { spawn } from "node:child_process";
import { copyFileSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const radice = resolve(import.meta.dirname, "../..");
const cartella = mkdtempSync(join(tmpdir(), "atlas-e2e-"));
const copia = join(cartella, "atlas.sqlite");
copyFileSync(process.env.ATLAS_E2E_DB ?? join(radice, "dati", "atlas.sqlite"), copia);

const server = spawn("cargo", ["run", "--release", "-q", "-p", "atlas-server", "--", copia], {
  cwd: radice,
  stdio: "inherit",
  env: { ...process.env, ATLAS_INDIRIZZO: "127.0.0.1:7979", ATLAS_ARCA_ADO: "" },
});
const fine = () => {
  server.kill();
  rmSync(cartella, { recursive: true, force: true });
};
process.on("SIGINT", fine);
process.on("SIGTERM", fine);
server.on("exit", (codice) => {
  rmSync(cartella, { recursive: true, force: true });
  process.exit(codice ?? 0);
});
