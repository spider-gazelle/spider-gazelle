import { defineConfig } from "@playwright/test";

// the app is started on its own port, so it doesn't clash with a development server
const port = Number(process.env.E2E_PORT ?? 3001);

// Browser tests for the MCP Apps cards, see e2e/README.md
export default defineConfig({
  testDir: "e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [["list"], ["html", { open: "never" }]] : "list",
  use: {
    baseURL: `http://127.0.0.1:${port}`,
    // wide enough for the previewer's desktop viewport (1280px) beside its form
    viewport: { width: 1920, height: 1080 },
    trace: "retain-on-failure",
    // when MCP authentication is enabled, send test credentials with every request:
    // extraHTTPHeaders: { Authorization: `Bearer ${process.env.E2E_TOKEN}` },
  },
  webServer: {
    // a development build, release builds don't include the card previewer
    command: `mkdir -p bin && crystal build src/app.cr -o bin/app && ./bin/app -p ${port}`,
    url: `http://127.0.0.1:${port}/mcp/card/preview`,
    reuseExistingServer: !process.env.CI,
    timeout: 300_000, // the first build can be slow
  },
});
