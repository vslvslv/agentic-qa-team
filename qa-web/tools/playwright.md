# Playwright — Web E2E Patterns

> Reference: [playwright-patterns.md](../references/playwright-patterns.md)

## Auth Setup

Create `e2e/auth.setup.ts` and configure `playwright.config.ts` with a `setup` project
and `storageState` so every test inherits auth without re-logging in:

```typescript
// e2e/auth.setup.ts
import { test as setup, expect } from "@playwright/test";
import path from "path";

const authFile = path.join(__dirname, ".auth/user.json");

setup("authenticate", async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel(/email/i).fill(process.env.E2E_USER_EMAIL || "admin@example.com");
  await page.getByLabel(/password/i).fill(process.env.E2E_USER_PASSWORD || "password123");
  await page.getByRole("button", { name: /sign in|log in|submit/i }).click();
  await expect(page).not.toHaveURL(/login/);
  await page.context().storageState({ path: authFile });
});
```

```typescript
// playwright.config.ts (key sections)
projects: [
  { name: "setup", testMatch: /auth\.setup/ },
  { name: "chromium", dependencies: ["setup"],
    use: { ...devices["Desktop Chrome"], storageState: "e2e/.auth/user.json" } },
],
```

## Test Structure

Prefer Page Object Model with fixture injection. One POM class per page in `e2e/pages/`;
one spec file per feature domain in `e2e/specs/`.

```typescript
// e2e/specs/dashboard.spec.ts
import { test, expect } from "@playwright/test";

test.describe("Dashboard", () => {
  test("loads without error", async ({ page }) => {
    await page.goto("/dashboard");
    await expect(page.getByRole("main")).toBeVisible();
  });

  test("shows error banner when API fails", async ({ page }) => {
    await page.route("**/api/metrics", route =>
      route.fulfill({ status: 500, body: JSON.stringify({ error: "Server error" }) })
    );
    await page.goto("/dashboard");
    await expect(page.getByRole("alert")).toBeVisible();
  });
});
```

Use `test.describe.configure({ mode: "serial" })` only for inherently stateful
multi-step flows (e.g., a checkout wizard).

## Selector Strategy (ranked)

1. `getByRole` — semantic, accessible
2. `getByLabel` — form inputs
3. `getByPlaceholder` — inputs without label
4. `getByText` — links/buttons with visible text
5. `getByTestId` — last resort when no semantic selector exists
- Narrow with `.filter({ hasText })` or `.and()` — never `:nth-child` or bare `.nth()`
- **Never** raw CSS (`.btn-primary`), `page.$()`, or bare XPath

## API Mocking

```typescript
// Mock a specific endpoint
await page.route("**/api/users", route =>
  route.fulfill({ status: 200, body: JSON.stringify([{ id: 1, name: "Alice" }]) })
);
// Abort a request
await page.route("**/analytics/**", route => route.abort());
```

## CI Notes

```bash
# Install browsers once (cache this step)
npx playwright install --with-deps chromium

# Run headless (default in CI)
npx playwright test --project=chromium --reporter=json

# Exit code: 1 = test failure, 0 = all passed
```

- `--shard=1/3` for parallelism across CI workers
- Set `retries: 2` in `playwright.config.ts` for flaky test tolerance

## Execute Block

```bash
export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"
[ ! -f "e2e/.auth/user.json" ] && \
  npx playwright test e2e/auth.setup.ts --project=setup 2>/dev/null || true
_SPEC_FILES=$(find . -path "*/e2e/specs/*.spec.ts" -o -path "*/e2e/*.spec.ts" \
  ! -path "*/node_modules/*" 2>/dev/null | tr '\n' ' ')
npx playwright test $_SPEC_FILES --project=chromium --reporter=json \
  2>&1 > "$_TMP/qa-web-pw-output.txt"
echo "PW_EXIT_CODE: $?"
```
