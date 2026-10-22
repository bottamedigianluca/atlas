import { defineConfig, devices } from "@playwright/test";

// Prove end-to-end sul database reale (copia) con il backend vero e il frontend di sviluppo.
// Prima esecuzione: compila `atlas-server` in release (qualche minuto).
export default defineConfig({
  testDir: "e2e",
  timeout: 30_000,
  fullyParallel: false,
  workers: 1,
  reporter: [["list"]],
  use: {
    baseURL: "http://localhost:1420",
    ...devices["Desktop Chrome"],
    viewport: { width: 1600, height: 900 },
    locale: "it-IT",
    timezoneId: "Europe/Rome",
    trace: "retain-on-failure",
  },
  webServer: [
    {
      command: "node e2e/server.mjs",
      url: "http://127.0.0.1:7979/api/salute",
      timeout: 900_000,
      reuseExistingServer: false,
      stdout: "pipe",
    },
    {
      command: "npx vite --port 1420 --strictPort",
      url: "http://localhost:1420",
      timeout: 60_000,
      reuseExistingServer: false,
      env: { VITE_ATLAS_SERVER: "http://127.0.0.1:7979" },
    },
  ],
});
