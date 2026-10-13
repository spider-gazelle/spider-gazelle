import { test, expect, type Page } from "@playwright/test";

// Tests for the MCP Apps cards in ./cards, using the card previewer that src/app.cr
// mounts in development builds. Every preview can be driven from its URL:
// /mcp/card/preview/tools/<tool>?<argument>=<value>&viewport_size=mobile&theme=dark
const preview = (tool: string, params: Record<string, string> = {}) =>
  `/mcp/card/preview/tools/${tool}?${new URLSearchParams(params)}`;

// opens a preview and waits for the card to receive the tool result
async function renderCard(page: Page, tool: string, params: Record<string, string> = {}) {
  await page.goto(preview(tool, params));
  await expect(page.locator("#stage")).toHaveAttribute("data-state", "ready");
  return page.frameLocator("#card");
}

// the previewer logs protocol problems, such as failed requests or unsupported messages
async function previewerErrors(page: Page) {
  const log = await page.evaluate(() => (window as any).cardPreviewer.log);
  return log.filter((entry: { level: string }) => entry.level === "error");
}

const pageErrors = new WeakMap<Page, string[]>();

test.beforeEach(({ page }) => {
  const errors: string[] = [];
  pageErrors.set(page, errors);
  page.on("pageerror", (error) => errors.push(error.message));
});

test.afterEach(({ page }) => {
  expect(pageErrors.get(page)).toEqual([]);
});

test("the index lists each card with its tools", async ({ page }) => {
  await page.goto("/mcp/card/preview");
  const card = page.locator('[data-card="ui://welcome/result.html"]');
  await expect(card).toBeVisible();

  await card.locator('a[data-tool="welcome_api"]').click();
  await expect(page).toHaveURL(/\/tools\/welcome_api/);
});

test.describe("welcome card", () => {
  for (const viewport of ["desktop", "tablet", "mobile"]) {
    test(`shows the result on ${viewport}`, async ({ page }) => {
      const card = await renderCard(page, "welcome_api", { example: "42", viewport_size: viewport });

      await expect(card.locator("#result")).toHaveText("42");
      await expect(card.locator("#label")).toHaveText("is the result");

      // the card fits the viewport without scrolling sideways
      const overflows = await card.locator("body").evaluate(
        (body) => body.scrollWidth > body.ownerDocument.documentElement.clientWidth,
      );
      expect(overflows).toBe(false);
      expect(await previewerErrors(page)).toEqual([]);
    });
  }

  test("follows the host's theme", async ({ page }) => {
    const card = await renderCard(page, "welcome_api", { example: "1", theme: "dark" });
    await expect(card.locator("html")).toHaveAttribute("data-theme", "dark");

    // the previewer notifies the card when the theme changes
    await page.locator('[data-theme-choice="light"]').click();
    await expect(card.locator("html")).toHaveAttribute("data-theme", "light");
  });

  test("renders once the required argument is provided", async ({ page }) => {
    await page.goto(preview("welcome_api"));
    await expect(page.locator("#stage")).toHaveAttribute("data-state", "idle");

    await page.locator("#run").click();
    await expect(page.locator('.field.invalid[data-name="example"]')).toBeVisible();

    await page.locator("#arg-example").fill("7");
    await page.locator("#run").click();
    await expect(page.locator("#stage")).toHaveAttribute("data-state", "ready");
    await expect(page.frameLocator("#card").locator("#result")).toHaveText("7");
    await expect(page).toHaveURL(/example=7/);
  });

  test("shows a failed request", async ({ page }) => {
    // too large for the route's Int32 parameter, so the route responds 400
    const card = await renderCard(page, "welcome_api", { example: "9999999999" });

    await expect(page.locator("#stage")).toHaveAttribute("data-tool-error", "true");
    await expect(card.locator("#label")).toHaveText("the request failed");
  });
});
