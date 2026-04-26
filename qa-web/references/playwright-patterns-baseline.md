# Playwright Patterns — Baseline Reference

> Source: playwright.dev official documentation (best-practices, page-object-model, locators, test-fixtures pages).
> Compiled: 2026-04-26. Applies to Playwright >= 1.40.

---

## 1. Page Object Model (POM)

### Why POM

Page Objects encapsulate selector logic and page-level actions in one place.
Tests import behaviour, not raw selectors, so a UI change is fixed in one
file rather than every spec that touches that page.

Playwright recommends the class-based Page Object pattern combined with
fixtures for injection.

### Minimal POM skeleton

```typescript
// e2e/pages/LoginPage.ts
import { type Page, type Locator } from "@playwright/test";

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput    = page.getByLabel(/email/i);
    this.passwordInput = page.getByLabel(/password/i);
    this.submitButton  = page.getByRole("button", { name: /sign in|log in/i });
    this.errorMessage  = page.getByRole("alert");
  }

  async goto() {
    await this.page.goto("/login");
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async loginAndWait(email: string, password: string) {
    await this.login(email, password);
    await this.page.waitForURL(/dashboard|home/);
  }
}
```

```typescript
// e2e/pages/DashboardPage.ts
import { type Page, type Locator } from "@playwright/test";

export class DashboardPage {
  readonly page: Page;
  readonly heading: Locator;
  readonly navLinks: Locator;

  constructor(page: Page) {
    this.page     = page;
    this.heading  = page.getByRole("heading", { level: 1 });
    this.navLinks = page.getByRole("navigation").getByRole("link");
  }

  async goto() {
    await this.page.goto("/dashboard");
  }

  async getNavLinkCount(): Promise<number> {
    return this.navLinks.count();
  }
}
```

### Fixtures for POM injection

Fixtures eliminate `new LoginPage(page)` boilerplate in every test and allow
Playwright to manage lifecycle automatically.

```typescript
// e2e/fixtures/pages.ts
import { test as base } from "@playwright/test";
import { LoginPage }     from "../pages/LoginPage";
import { DashboardPage } from "../pages/DashboardPage";

type PageFixtures = {
  loginPage:     LoginPage;
  dashboardPage: DashboardPage;
};

export const test = base.extend<PageFixtures>({
  loginPage:     async ({ page }, use) => use(new LoginPage(page)),
  dashboardPage: async ({ page }, use) => use(new DashboardPage(page)),
});

export { expect } from "@playwright/test";
```

```typescript
// e2e/specs/login.spec.ts
import { test, expect } from "../fixtures/pages";

test("shows error on bad credentials", async ({ loginPage }) => {
  await loginPage.goto();
  await loginPage.login("bad@example.com", "wrong");
  await expect(loginPage.errorMessage).toBeVisible();
});

test("redirects to dashboard on success", async ({ loginPage }) => {
  await loginPage.loginAndWait(
    process.env.E2E_USER_EMAIL    ?? "admin@example.com",
    process.env.E2E_USER_PASSWORD ?? "password123"
  );
  await expect(loginPage.page).toHaveURL(/dashboard/);
});
```

### POM rules

- Locators are **readonly class members** — define them in the constructor.
- Page Objects expose **actions** (`login()`, `search()`) and **assertions**
  (`expectWelcomeVisible()`), not raw locators.
- Never put `expect()` calls inside POM methods unless the method is
  explicitly named `expectXxx` — keep assertions in the test file.
- One class per page/component. Large forms may warrant a sub-component POM
  (e.g. `SearchWidget`).
- Page Objects do **not** extend each other; compose instead.

---

## 2. Locator Strategy (priority order)

Playwright locators are auto-retrying: they poll the DOM until the element
matches or the timeout expires. Always prefer semantic locators — they are
resilient to layout and styling changes.

| Priority | Locator | When to use |
|----------|---------|-------------|
| 1 | `getByRole(role, { name })` | Buttons, links, headings, inputs with accessible names — the gold standard |
| 2 | `getByLabel(text)` | Form inputs associated with a `<label>` |
| 3 | `getByPlaceholder(text)` | Inputs that have placeholder but no label |
| 4 | `getByText(text)` | Non-interactive text content (paragraphs, list items) |
| 5 | `getByAltText(text)` | Images |
| 6 | `getByTitle(text)` | Elements with a `title` attribute |
| 7 | `getByTestId("id")` | Elements with `data-testid` — use when no semantic option exists |
| 8 | `locator("css")` | Last resort — only for integration with legacy markup you cannot change |

### Examples

```typescript
// Role — most resilient
page.getByRole("button", { name: "Submit" })
page.getByRole("link",   { name: "Home" })
page.getByRole("textbox",{ name: "Search" })

// Exact vs. substring
page.getByRole("button", { name: "Submit" })           // exact (default)
page.getByRole("button", { name: /submit/i })          // regex, case-insensitive

// Chaining to scope searches
page.getByRole("dialog").getByRole("button", { name: "Close" })
page.getByRole("row", { name: "Alice" }).getByRole("cell", { name: "Edit" })

// Filter (when multiple elements match)
page.getByRole("listitem").filter({ hasText: "Buy milk" })

// nth when order is stable
page.getByRole("option").nth(0)
```

### What to avoid

```typescript
// AVOID — fragile CSS selectors
page.locator(".btn-primary")
page.locator("#submit-btn")
page.locator("div.modal > button:first-child")

// AVOID — XPath
page.locator("//button[@class='submit']")

// AVOID — text as the only selector when the text is dynamic or translated
page.getByText("January 2024")   // date content changes

// AVOID — locator() with arbitrary attributes (not data-testid)
page.locator("[data-qa='btn']")  // prefer getByTestId if you must use attributes
```

---

## 3. Assertions

### Use web-first assertions

`expect(locator).toBeVisible()` retries internally until the condition is met
or the timeout expires. `expect(value).toBe(...)` is synchronous and does not
retry — avoid it for DOM checks.

```typescript
// GOOD — auto-retrying
await expect(page.getByRole("alert")).toBeVisible();
await expect(page.getByRole("button", { name: "Save" })).toBeEnabled();
await expect(page.getByRole("checkbox")).toBeChecked();
await expect(page.getByRole("textbox")).toHaveValue("hello");
await expect(page.getByRole("list")).toHaveCount(3);
await expect(page).toHaveURL(/dashboard/);
await expect(page).toHaveTitle(/My App/);

// GOOD — soft assertions (collect all failures before throwing)
await expect.soft(page.getByTestId("status")).toHaveText("Active");
await expect.soft(page.getByTestId("count")).toHaveText("5");
expect(test.info().errors).toHaveLength(0);

// AVOID — resolve the locator first, then assert synchronously
const text = await page.getByRole("heading").textContent();
expect(text).toBe("Dashboard");              // no retry — can be flaky
```

### Negative assertions

```typescript
await expect(page.getByRole("dialog")).not.toBeVisible();
await expect(page.getByRole("button", { name: "Delete" })).toBeDisabled();
```

### URL / navigation assertions

```typescript
await expect(page).toHaveURL("/dashboard");
await expect(page).toHaveURL(/\/dashboard/);
await expect(page).not.toHaveURL(/login/);
```

---

## 4. Test Isolation

Playwright tests are isolated by default: each test gets a **new browser
context** (fresh cookies, localStorage, session storage).

### Global auth with storageState

Avoid logging in inside every test. Use a one-time auth setup instead:

```typescript
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  projects: [
    {
      name: "setup",
      testMatch: /auth\.setup\.ts/,
    },
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        storageState: "e2e/.auth/user.json",
      },
      dependencies: ["setup"],
    },
  ],
});
```

```typescript
// e2e/auth.setup.ts
import { test as setup, expect } from "@playwright/test";
import path from "path";

const authFile = path.join(__dirname, ".auth/user.json");

setup("authenticate", async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel(/email/i).fill(process.env.E2E_USER_EMAIL ?? "admin@example.com");
  await page.getByLabel(/password/i).fill(process.env.E2E_USER_PASSWORD ?? "password123");
  await page.getByRole("button", { name: /sign in/i }).click();
  await expect(page).not.toHaveURL(/login/);
  await page.context().storageState({ path: authFile });
});
```

### Isolation anti-patterns

```typescript
// AVOID — shared state between tests via beforeAll with single page
test.describe.configure({ mode: "serial" }); // serial coupling is a last resort

// AVOID — re-using a page object instance across tests
// Each test should create its own page/context
```

---

## 5. Fixtures

Fixtures are the Playwright-idiomatic way to share setup and teardown across
tests without `beforeEach` spaghetti.

### Built-in fixtures available in every test

| Fixture | Type | Description |
|---------|------|-------------|
| `page` | `Page` | Isolated page in a new context |
| `context` | `BrowserContext` | Browser context (cookies, storage) |
| `browser` | `Browser` | Browser instance |
| `request` | `APIRequestContext` | HTTP API context |
| `browserName` | `string` | `"chromium"`, `"firefox"`, `"webkit"` |

### Custom fixture example

```typescript
// e2e/fixtures/auth.ts
import { test as base, expect } from "@playwright/test";

type AuthFixture = {
  authenticatedPage: import("@playwright/test").Page;
};

export const test = base.extend<AuthFixture>({
  authenticatedPage: async ({ page }, use) => {
    await page.goto("/login");
    await page.getByLabel(/email/i).fill(process.env.E2E_USER_EMAIL ?? "admin@example.com");
    await page.getByLabel(/password/i).fill(process.env.E2E_USER_PASSWORD ?? "password123");
    await page.getByRole("button", { name: /sign in/i }).click();
    await expect(page).not.toHaveURL(/login/);
    await use(page);         // hand control to the test
    // teardown runs here after each test
  },
});
```

---

## 6. Project / File Structure

```
e2e/
├── fixtures/
│   ├── pages.ts          ← POM fixture extensions
│   └── auth.ts           ← auth fixture (if not using storageState)
├── pages/
│   ├── LoginPage.ts
│   ├── DashboardPage.ts
│   └── components/
│       └── SearchWidget.ts
├── specs/
│   ├── auth.spec.ts
│   ├── dashboard.spec.ts
│   └── settings.spec.ts
├── auth.setup.ts
└── .auth/
    └── user.json         ← gitignored; written by auth.setup.ts
playwright.config.ts
```

Rules:
- One spec file per feature domain, not per page.
- Fixtures and POMs live under `e2e/`; never in `src/`.
- `auth.setup.ts` is the only file that logs in; tests consume `storageState`.

---

## 7. Parallelism and Serial Mode

Playwright runs spec files in parallel by default and tests within a file
sequentially. Only override this when tests share mutable state.

```typescript
// Within a file: parallel (default) — preferred
test("A", async ({ page }) => { ... });
test("B", async ({ page }) => { ... });

// Within a describe block: serial — use sparingly
test.describe.serial("checkout flow", () => {
  test("add to cart",   async ({ page }) => { ... });
  test("proceed to checkout", async ({ page }) => { ... });
  test("complete order",     async ({ page }) => { ... });
});
```

Set worker count in config to match CI concurrency:

```typescript
// playwright.config.ts
export default defineConfig({
  workers: process.env.CI ? 2 : undefined,  // 2 on CI, auto-detect locally
  fullyParallel: true,
});
```

---

## 8. Anti-Patterns Catalogue

| Anti-pattern | Problem | Fix |
|---|---|---|
| `page.locator(".btn-primary")` | Breaks on CSS refactor | `getByRole("button", { name: "..." })` |
| `await page.waitForTimeout(3000)` | Arbitrary sleep; flaky on slow CI | Use `waitForLoadState` or web-first assertions |
| `await page.waitForSelector(".spinner:not(:visible)")` | DOM polling by CSS | `await expect(spinner).not.toBeVisible()` |
| `page.$$(".row")` then `.click()` on the result | Breaks if DOM updates between query and action | `page.getByRole("row").first().click()` — locator re-evaluates |
| `textContent()` then `toBe()` | Not auto-retrying | `await expect(locator).toHaveText(...)` |
| Auth in every test | Slow; creates coupling | Global `storageState` via `auth.setup.ts` |
| `test.describe.configure({ mode: "serial" })` on everything | Tests run sequentially — kills parallelism benefit | Only use for inherently stateful flows |
| Hardcoded `localhost:3000` URLs in specs | Breaks in different environments | Use `baseURL` from config; `page.goto("/path")` |
| One giant spec file with all tests | Hard to parallelise, hard to maintain | One spec file per feature domain |
| Assertions outside `expect()` | No retry, flaky | Always use `expect(locator).toXxx()` |

---

## 9. Useful Config Snippets

### playwright.config.ts (recommended baseline)

```typescript
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir:       "./e2e",
  testMatch:     "**/*.spec.ts",
  fullyParallel: true,
  forbidOnly:    !!process.env.CI,       // fail if test.only left in
  retries:       process.env.CI ? 2 : 0, // retry flakes on CI only
  workers:       process.env.CI ? 2 : undefined,
  reporter:      [["html"], ["list"]],
  use: {
    baseURL:          process.env.WEB_URL ?? "http://localhost:3000",
    trace:            "on-first-retry",  // capture trace on first retry
    screenshot:       "only-on-failure",
    video:            "on-first-retry",
  },
  projects: [
    { name: "setup", testMatch: /auth\.setup\.ts/ },
    {
      name: "chromium",
      dependencies: ["setup"],
      use: {
        ...devices["Desktop Chrome"],
        storageState: "e2e/.auth/user.json",
      },
    },
  ],
});
```

### .gitignore additions

```
e2e/.auth/
playwright-report/
test-results/
```

---

## 10. Quick-Reference Cheat Sheet

```typescript
// Navigation
await page.goto("/path");                         // uses baseURL from config
await page.waitForURL(/dashboard/);               // wait for URL pattern

// Locators (priority order)
page.getByRole("button", { name: /submit/i })
page.getByLabel("Email")
page.getByPlaceholder("Search...")
page.getByText("Welcome back")
page.getByTestId("submit-btn")

// Actions
await locator.click();
await locator.fill("value");
await locator.selectOption("option");
await locator.check();
await locator.uncheck();
await locator.hover();
await locator.press("Enter");

// Assertions (web-first, auto-retrying)
await expect(locator).toBeVisible();
await expect(locator).toBeHidden();
await expect(locator).toBeEnabled();
await expect(locator).toBeDisabled();
await expect(locator).toHaveText("exact");
await expect(locator).toContainText("partial");
await expect(locator).toHaveValue("input value");
await expect(locator).toBeChecked();
await expect(locator).toHaveCount(3);
await expect(page).toHaveURL(/pattern/);
await expect(page).toHaveTitle(/pattern/);

// Scoping / filtering
page.getByRole("dialog").getByRole("button", { name: "Close" })
page.getByRole("listitem").filter({ hasText: "Buy milk" })
page.getByRole("row").nth(1)
```

---

## 11. See Also

- playwright.dev/docs/best-practices
- playwright.dev/docs/pom
- playwright.dev/docs/locators
- playwright.dev/docs/test-fixtures
- playwright.dev/docs/auth
