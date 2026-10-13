# Browser tests

These tests render the MCP Apps cards in `cards/` with the card previewer, which
`src/app.cr` mounts at `/mcp/card/preview` in development builds, and check them with
[Playwright](https://playwright.dev).

```shell
npm install
npx playwright install chromium
npm run test:e2e
```

Playwright builds and starts the app on port 3001 (`E2E_PORT`), or reuses one that's
already running there. Open <http://127.0.0.1:3000/mcp/card/preview> while developing to
try cards by hand.

## Writing tests

Every preview can be driven from its URL: the tool's arguments by name, plus
`viewport_size` (`desktop`, `tablet` or `mobile`), `theme` (`light` or `dark`) and
`header.<Name>` request headers.

```typescript
await page.goto("/mcp/card/preview/tools/welcome_api?example=42&viewport_size=mobile");
await expect(page.locator("#stage")).toHaveAttribute("data-state", "ready");
await expect(page.frameLocator("#card").locator("#result")).toHaveText("42");
```

* `#stage[data-state]` is `idle` (waiting for required arguments), `loading`,
  `rendering`, `ready` or `error`. `data-tool-error` is set when the tool failed.
* `page.frameLocator("#card")` looks inside the card.
* `window.cardPreviewer` has the tool `result` and the message `log`.

If you enable MCP authentication, set `extraHTTPHeaders` in `playwright.config.ts` so the
previewer's requests carry test credentials.

To catch visual changes, add `await expect(page.locator("#card")).toHaveScreenshot()`.
Reference images depend on the operating system's fonts, so generate them where the tests
run, i.e. in CI.

See [testing cards in a browser](https://spider-gazelle.net/mcp/ui/#testing-cards-in-a-browser)
for more.
