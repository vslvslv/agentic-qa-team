# Playwright Patterns & Best Practices (TypeScript)
<!-- lang: TypeScript | sources: official | community | mixed | iteration: 11 | score: 100/100 | date: 2026-05-03 -->
<!-- official: playwright.dev/docs/best-practices, /pom, /locators, /test-fixtures, /test-assertions, /api-testing, /network, /auth, /test-sharding, /ci-intro, /test-configuration, /test-parallel, /test-snapshots, /release-notes, /api/class-testconfig, /trace-viewer, /test-retries, /test-components, /docker, /api/class-page, /accessibility-testing, /aria-snapshots -->
<!-- community: playwrightsolutions.com, currents.dev/blog/playwright, mxschmitt/awesome-playwright, playwright-network-cache, GitHub Discussions patterns, real-world production experience, v1.45-v1.59 release notes analysis -->

---

## Core Principles

1. **Test user-visible behavior, not implementation details.** Assertions should reflect what users see and do — not CSS class names, internal state, or component structure.
2. **Rely on Playwright's auto-waiting.** Every action (`click`, `fill`, `check`) automatically waits for the element to be actionable. Never add arbitrary `waitForTimeout()` sleeps.
3. **Use semantic, resilient locators.** Roles, labels, and accessible names outlive CSS refactors. If a selector breaks when a class name changes, it was the wrong selector. Playwright pierces Shadow DOM by default — no special API needed.
4. **Isolate state between tests.** Each test should own its setup. Tests that depend on run order cannot be debugged in isolation. When a worker restarts after failure, clean up stale state on retry using `testInfo.retry`.
5. **Centralize reuse in fixtures and Page Objects.** Login flows, page interactions, and setup sequences belong in one place — so one change fixes every test that uses them. Use `locator.describe()` to annotate complex locators for trace readability.

---

## Recommended Patterns

### Page Object Model (POM)

POM encapsulates selector logic and page actions into a class. Tests import behavior, not raw Playwright calls. A UI change is fixed in one file rather than every spec that touches that page. Playwright recommends the class-based pattern with fixtures for injection.

```typescript
// e2e/pages/LoginPage.ts
import { type Page, type Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page          = page;
    this.emailInput    = page.getByLabel(/email/i);
    this.passwordInput = page.getByLabel(/password/i);
    this.submitButton  = page.getByRole('button', { name: /sign in|log in/i });
    this.errorMessage  = page.getByRole('alert');
  }

  async goto() {
    await this.page.goto('/login');
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

**POM rules:**
- Declare locators as `readonly` class properties — initialize in the constructor, not in methods.
- Methods represent user actions (`login`, `search`, `openModal`); properties hold `Locator` references.
- Keep `expect()` calls out of POM methods unless the method is explicitly named `expectXxx`.
- One class per page or major UI section. Compose — do not extend — between Page Objects.
- Large pages may extract sub-component objects (e.g., `SearchWidget`, `DataTable`) for reuse.
- Never expose raw locators from POM — expose action methods to prevent coupling tests to selectors. [community]

---

### Fixture-Based POM Injection

Fixtures eliminate `new LoginPage(page)` boilerplate in every test and allow Playwright to manage object lifecycle. This is the idiomatic Playwright approach.

```typescript
// e2e/fixtures/pages.ts
import { test as base }  from '@playwright/test';
import { LoginPage }     from '../pages/LoginPage';
import { DashboardPage } from '../pages/DashboardPage';

type PageFixtures = {
  loginPage:     LoginPage;
  dashboardPage: DashboardPage;
};

export const test = base.extend<PageFixtures>({
  loginPage:     async ({ page }, use) => use(new LoginPage(page)),
  dashboardPage: async ({ page }, use) => use(new DashboardPage(page)),
});

export { expect } from '@playwright/test';

// e2e/specs/auth.spec.ts
import { test, expect } from '../fixtures/pages';

test('shows error on bad credentials', async ({ loginPage }) => {
  await loginPage.goto();
  await loginPage.login('bad@example.com', 'wrong');
  await expect(loginPage.errorMessage).toBeVisible();
});
```

**Fixture composition with `mergeTests`:**

```typescript
// e2e/fixtures/index.ts — merge independent fixture modules
import { mergeTests } from '@playwright/test';
import { test as pageTest } from './pages';
import { test as apiTest }  from './api';

export const test = mergeTests(pageTest, apiTest);
export { expect } from '@playwright/test';
```

---

### Fixture-Based Authentication (storageState)

Log in once per worker and reuse the session across all tests. Re-authenticating per test is 10–50× slower.

```typescript
// e2e/auth.setup.ts
import { test as setup, expect } from '@playwright/test';
import path from 'path';

const authFile = path.join(__dirname, '.auth/user.json');

setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel(/email/i).fill(process.env.E2E_USER_EMAIL ?? 'admin@example.com');
  await page.getByLabel(/password/i).fill(process.env.E2E_USER_PASSWORD ?? 'password123');
  await page.getByRole('button', { name: /sign in/i }).click();
  await expect(page).not.toHaveURL(/login/);
  await page.context().storageState({ path: authFile });
});
```

```typescript
// playwright.config.ts — projects block
projects: [
  { name: 'setup', testMatch: /auth\.setup\.ts/ },
  {
    name: 'chromium',
    use: { ...devices['Desktop Chrome'], storageState: 'e2e/.auth/user.json' },
    dependencies: ['setup'],
  },
],
```

**Multi-role authentication (admin + viewer):**

```typescript
// e2e/auth.setup.ts — separate storageState per role
const adminFile  = path.join(__dirname, '.auth/admin.json');
const viewerFile = path.join(__dirname, '.auth/viewer.json');

setup('authenticate admin', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel(/email/i).fill(process.env.ADMIN_EMAIL!);
  await page.getByLabel(/password/i).fill(process.env.ADMIN_PASSWORD!);
  await page.getByRole('button', { name: /sign in/i }).click();
  await expect(page).not.toHaveURL(/login/);
  await page.context().storageState({ path: adminFile });
});

setup('authenticate viewer', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel(/email/i).fill(process.env.VIEWER_EMAIL!);
  await page.getByLabel(/password/i).fill(process.env.VIEWER_PASSWORD!);
  await page.getByRole('button', { name: /sign in/i }).click();
  await expect(page).not.toHaveURL(/login/);
  await page.context().storageState({ path: viewerFile });
});
```

**Worker-scoped auth for teams with per-user state:**

```typescript
// e2e/fixtures/auth.ts — one account per parallel worker
import { test as base } from '@playwright/test';

type AuthFixtures = { account: { username: string; password: string } };

export const test = base.extend<{}, AuthFixtures>({
  account: [async ({ browser }, use, workerInfo) => {
    const username = `user${workerInfo.workerIndex}@example.com`;
    // Create/ensure worker-specific account exists
    const page = await browser.newPage();
    await setupWorkerAccount(page, username);
    await page.close();
    await use({ username, password: process.env.TEST_PASSWORD! });
  }, { scope: 'worker' }],
});
```

> WHY: When tests write user-specific data, sharing one account across workers causes parallel
> tests to interfere. Worker-index accounts give each worker an isolated data lane. [community]

**API-based authentication (faster than UI login):**

```typescript
// e2e/auth.setup.ts — authenticate via API, skip UI entirely
setup('authenticate via API', async ({ request }) => {
  const response = await request.post('/api/auth/login', {
    data: {
      email:    process.env.E2E_USER_EMAIL!,
      password: process.env.E2E_USER_PASSWORD!,
    },
  });
  expect(response.ok()).toBeTruthy();
  const { token } = await response.json();
  // Write state manually when API auth doesn't set cookies
  await request.storageState({ path: authFile });
  // Or: use the token in extraHTTPHeaders in playwright.config.ts
});
```

---

### API Setup / Teardown (hybrid testing)

Use Playwright's `request` fixture to seed and clean state via the API — not by clicking through the UI. UI-driven setup is slow and fragile; API-driven setup is fast and deterministic.

```typescript
import { test, expect } from '@playwright/test';

test.beforeAll(async ({ request }) => {
  await request.post('/api/test/seed', { data: { scenario: 'empty-inbox' } });
});

test.afterAll(async ({ request }) => {
  await request.delete('/api/test/cleanup');
});

test('inbox shows empty state', async ({ page }) => {
  await page.goto('/inbox');
  await expect(page.getByText('No messages')).toBeVisible();
});
```

For parallel safety, use unique identifiers when creating test data:

```typescript
test('creates a new user', async ({ page, request }, testInfo) => {
  const email = `test-${testInfo.testId}@example.com`;
  await request.post('/api/users', { data: { email, role: 'viewer' } });
  await page.goto('/admin/users');
  await expect(page.getByText(email)).toBeVisible();
});
```

**API postcondition validation:**

```typescript
// Verify UI action persisted via API — catches bugs where UI lies about success
test('form submission persists to backend', async ({ page, request }) => {
  await page.goto('/items/new');
  await page.getByLabel('Title').fill('My Item');
  await page.getByRole('button', { name: 'Save' }).click();
  await page.waitForURL(/\/items\/\d+/);
  const itemId = page.url().split('/').pop();
  const res = await request.get(`/api/items/${itemId}`);
  expect((await res.json()).title).toBe('My Item');
});
```

---

### Component-Level Locator Scoping

When the same element pattern appears multiple times (e.g., table rows, list items), scope the locator to the specific container first to prevent false positives.

```typescript
// Scope to the correct row before asserting on children
const row = page.getByRole('row', { name: /Alice Johnson/ });
await expect(row.getByRole('cell', { name: /Admin/ })).toBeVisible();
await row.getByRole('button', { name: /Edit/ }).click();

// Filter a list to the right item before acting
await page
  .getByRole('listitem')
  .filter({ hasText: 'Product 2' })
  .getByRole('button', { name: 'Add to cart' })
  .click();

// Chain multiple filters for precision
await rowLocator
  .filter({ hasText: 'Mary' })
  .filter({ has: page.getByRole('button', { name: 'Say goodbye' }) })
  .screenshot({ path: 'screenshot.png' });
```

---

### Soft Assertions

Use soft assertions to collect all failures in one pass rather than stopping at the first failure. Useful for validating multiple fields or states on a single page.

```typescript
await expect.soft(page.getByTestId('status')).toHaveText('Active');
await expect.soft(page.getByTestId('count')).toHaveText('42');
await expect.soft(page.getByTestId('plan')).toHaveText('Pro');
// Always check collected errors at the end
expect(test.info().errors).toHaveLength(0);
```

---

### Network Mocking for Error States

Mock API responses to test UI error handling without needing a broken backend.

```typescript
// Fulfill with error response
await page.route('**/api/users', route =>
  route.fulfill({ status: 500, body: JSON.stringify({ error: 'Server error' }) })
);
await page.goto('/admin/users');
await expect(page.getByRole('alert')).toContainText('Something went wrong');

// Modify response on-the-fly without a real mock server
await page.route('**/api/config', async route => {
  const response = await route.fetch();
  const body = await response.json();
  body.featureFlag = true;
  await route.fulfill({ response, body: JSON.stringify(body) });
});

// Block third-party tracking to speed up tests
await page.route('**/*', route => {
  const type = route.request().resourceType();
  return ['image', 'font', 'stylesheet'].includes(type)
    ? route.abort()
    : route.continue();
});
```

> Blocking images and fonts in tests not focused on visuals can cut load times by 30–50%.
> Use at context level (`browserContext.route()`) for popups. [community]

---

### Test Sharding for CI Parallelism

Split the test suite across CI machines to reduce total wall-clock time. Use `blob` reporter to preserve trace/screenshot attachments across shards, then merge.

```typescript
// playwright.config.ts — switch to blob reporter in CI
export default defineConfig({
  fullyParallel: true,
  reporter: process.env.CI ? 'blob' : 'html',
  maxFailures: process.env.CI ? 10 : undefined, // stop early on massively broken runs
});
```

```yaml
# .github/workflows/playwright.yml — matrix sharding
strategy:
  matrix:
    shardIndex: [1, 2, 3, 4]
    shardTotal: [4]
steps:
  - name: Run tests (shard ${{ matrix.shardIndex }}/${{ matrix.shardTotal }})
    run: npx playwright test --shard=${{ matrix.shardIndex }}/${{ matrix.shardTotal }}
  - name: Upload blob report
    uses: actions/upload-artifact@v4
    with:
      name: blob-report-${{ matrix.shardIndex }}
      path: blob-report/

merge-reports:
  needs: [test]
  runs-on: ubuntu-latest
  if: ${{ !cancelled() }}
  steps:
    - name: Merge reports
      run: npx playwright merge-reports --reporter html ./all-blob-reports
```

> Always use `if: !cancelled()` on the merge job — otherwise a single failed shard stops you
> from seeing the full report. Use `html` reporter locally, `blob` in CI. [community]

---

### Visual Regression Testing (Screenshots)

Use `toHaveScreenshot()` for component/page-level visual regression. The golden snapshot is auto-generated on first run and committed to source control.

```typescript
// e2e/specs/visual.spec.ts
import { test, expect } from '@playwright/test';

test('homepage visual regression', async ({ page }) => {
  await page.goto('/');
  // Mask dynamic content before comparing
  await expect(page).toHaveScreenshot('homepage.png', {
    mask: [page.locator('[data-testid="timestamp"]'), page.locator('.user-avatar')],
    maxDiffPixels: 50,
  });
});

test('button component visual regression', async ({ page }) => {
  await page.goto('/design-system/buttons');
  const component = page.getByTestId('primary-button');
  await expect(component).toHaveScreenshot('primary-button.png');
});
```

```typescript
// playwright.config.ts — visual config
export default defineConfig({
  expect: {
    toHaveScreenshot: {
      maxDiffPixels: 100,
      stylePath: './e2e/screenshot.css',  // inject CSS to hide dynamic content
    },
  },
});
```

```css
/* e2e/screenshot.css — hide volatile elements globally for visual tests */
[data-testid="timestamp"],
[data-testid="notification-badge"],
.skeleton-loader {
  visibility: hidden !important;
}
```

**Update baselines** when UI changes are intentional:
```bash
npx playwright test --update-snapshots
```

> Visual snapshots are platform-dependent: a PNG generated on macOS will differ from Linux.
> Always generate baselines in CI (Linux) and commit those. Never commit local macOS snapshots. [community]

---

### WebServer Auto-Launch

Use `webServer` to automatically start your dev server before tests run, eliminating manual `npm run dev` step in CI.

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  webServer: {
    command: 'npm run build && npm run preview',
    url: 'http://localhost:4173',
    reuseExistingServer: !process.env.CI, // reuse locally, always fresh in CI
    timeout: 120_000,                     // give build time to complete
  },
  use: {
    baseURL: 'http://localhost:4173',
  },
});
```

> Use `reuseExistingServer: !process.env.CI` so CI always starts fresh (no stale state)
> while local dev reuses an already-running server for speed. [community]

---

## Selector / Locator Strategy

Use the highest-ranked option that is semantically meaningful. The ranking reflects resilience to UI changes and alignment with how assistive technology navigates the page.

| Rank | Locator | Rationale |
|------|---------|-----------|
| 1 | `getByRole('button', { name: '...' })` | Mirrors ARIA and screen-reader navigation; tests accessibility simultaneously |
| 2 | `getByLabel('Email')` | Tied to `<label>` elements; survives markup refactors |
| 3 | `getByPlaceholder('Search...')` | Useful for inputs lacking a visible label |
| 4 | `getByText('Submit')` | Good for static visible text; avoid for dynamic or translated content |
| 5 | `getByAltText('Company logo')` | Images and icons with alt text |
| 6 | `getByTitle('Close dialog')` | Elements with a `title` attribute |
| 7 | `getByTestId('submit-btn')` | Use when semantic options are unavailable; requires `data-testid` in source |
| 8 | `locator('css=...')` / `locator('xpath=...')` | Last resort; tightly coupled to implementation |

**Chaining and filtering:**

```typescript
// Scope to a container
const sidebar = page.getByRole('navigation', { name: 'Sidebar' });
await sidebar.getByRole('link', { name: 'Settings' }).click();

// Filter by text and nested element
await rowLocator
  .filter({ hasText: 'Mary' })
  .filter({ has: page.getByRole('button', { name: 'Say goodbye' }) })
  .click();

// Match two conditions simultaneously
const button = page.getByRole('button').and(page.getByTitle('Subscribe'));

// Match one of two alternatives
await expect(newEmail.or(dialog).first()).toBeVisible();

// Exact vs. regex matching
page.getByRole('button', { name: 'Submit' })      // exact string (default)
page.getByRole('button', { name: /submit/i })     // regex, case-insensitive
```

**Locators are strict by design** — if more than one element matches, Playwright throws. This prevents silent wrong-element clicks. Use `.nth()` only when the list order is stable and semantically meaningful.

**Never use:**
- `page.$('.btn-primary')` — deprecated; use `page.locator()` if CSS is unavoidable
- `:nth-child(3)` positional CSS — breaks when list order changes
- Long XPath chains like `//div[@class='...']` — brittle and unreadable
- `locator.nth(index)` without scoping context — silently targets wrong element after reorder

---

## Real-World Gotchas [community]

These are pitfalls from production usage. Each is a named, concrete failure mode with a root cause and fix.

### 1. `storageState` expires mid-run and causes cascading auth failures [community]
**What:** Tests that run after a long parallel session find the saved storageState invalid (token expired), producing authentication errors that look like assertion failures.
**WHY:** `auth.setup.ts` runs once at the start of the suite. If tokens have short expiry (e.g., 15-minute JWTs), workers running after that window will be unauthenticated.
**Fix:** Set token expiry longer than your suite's expected run time, or implement a token refresh fixture. Use `setup` project dependencies to re-run auth before long test runs. For very short expiry, use API token auth instead of session cookies.

### 2. MSW (Mock Service Worker) silently swallows `page.route()` handlers [community]
**What:** Tests using MSW for mocking in a Next.js / CRA app stop seeing Playwright's `page.route()` intercepts even though both appear configured correctly.
**WHY:** Service Workers intercept network requests before they reach the browser's native fetch, making them invisible to Playwright's routing layer.
**Fix:** Add `serviceWorkers: 'block'` to your `use` config for tests that rely on `page.route()`. This disables SW registration for those contexts.

```typescript
// playwright.config.ts
use: {
  serviceWorkers: 'block', // required when MSW is active in the app
}
```

### 3. Parallel tests sharing test data produce race conditions [community]
**What:** Two parallel workers both query "the first user" from a shared fixture and end up modifying the same record, causing one test to fail with unexpected data.
**WHY:** `Date.now()` is not unique enough across concurrent workers — two workers starting within the same millisecond will generate the same identifier.
**Fix:** Use `workerInfo.workerIndex` or `testInfo.testId` for data isolation. Prefer unique-per-test identifiers over timestamp-based ones.

```typescript
test('manages user', async ({ page, request }, testInfo) => {
  const email = `user-${testInfo.testId}@example.com`;
  await request.post('/api/users', { data: { email } });
  // testId is globally unique per test, even across workers
});
```

### 4. `trace: 'on'` in CI fills disk and causes OOM kills [community]
**What:** A CI run passes locally but fails in CI with disk-space or memory errors. Trace files are gigabytes in total.
**WHY:** `trace: 'on'` records every test — including the hundreds that pass. Traces include video-like DOM snapshots, which are expensive.
**Fix:** Use `trace: 'on-first-retry'` in CI. This records only when a flake retry happens, giving you data exactly when you need it without the cost of recording every passing test.

### 5. `waitForLoadState('networkidle')` hangs on apps with polling [community]
**What:** Test hangs for the full timeout (30 s) on pages that poll an API every few seconds (websockets, SSE, periodic refresh).
**WHY:** `networkidle` waits until there are no network requests for 500 ms. Apps with polling never reach that threshold.
**Fix:** Use `waitForLoadState('domcontentloaded')` or `waitForURL()` for navigation, then assert against visible UI state rather than waiting for network silence.

### 6. `forbidOnly` is set only in `CI` but left out of review CI [community]
**What:** A `test.only()` gets merged when the PR test run doesn't set `CI=true`, silently skipping the full suite.
**WHY:** `forbidOnly: !!process.env.CI` only catches the problem if the CI environment actually exports `CI`. Some CI systems use different variable names.
**Fix:** Verify your CI config exports `CI=true` explicitly. Add a pre-commit hook or lint rule (`eslint-plugin-playwright`) to block `test.only` commits.

### 7. Uneven shard distribution when `fullyParallel` is not set [community]
**What:** With 4 shards, one machine runs 80% of tests because it got the large spec files.
**WHY:** Without `fullyParallel: true`, Playwright distributes whole test *files* across shards. One 200-test file goes to one shard while others sit idle.
**Fix:** Set `fullyParallel: true` to distribute individual tests rather than files. This gives optimal shard balance regardless of file size.

### 8. `expect` imported from Jest instead of Playwright loses auto-retry [community]
**What:** Test assertions pass on first evaluation but fail on re-run when the DOM hasn't updated yet. The error message looks like a race condition.
**WHY:** Jest's `expect` evaluates immediately with no retry. Playwright's `expect` retries the assertion until the timeout. Mixing them means some assertions silently lose the retry mechanism.
**Fix:** Always import `expect` from `@playwright/test`. Configure ESLint with `eslint-plugin-playwright` to catch accidental Jest imports.

### 9. Visual snapshots generated locally differ from CI snapshots [community]
**What:** Visual regression tests that pass locally fail in CI (or vice versa), producing diff images with subtle pixel differences.
**WHY:** Playwright snapshot names include the OS (e.g., `homepage-chromium-darwin.png` vs `homepage-chromium-linux.png`). Font rendering, subpixel antialiasing, and GPU acceleration differ between macOS and Linux headless environments.
**Fix:** Always generate and commit snapshot baselines from the CI environment (Linux). Never commit macOS or Windows snapshots. Use `--update-snapshots` only in CI pipelines.

### 10. `waitForResponse()` awaited before the trigger action causes deadlock [community]
**What:** Test hangs indefinitely when `waitForResponse` is awaited before the button click that triggers the network request.
**WHY:** `await page.waitForResponse(url)` waits for a response that must be triggered by a subsequent action. If you await the waiter first, the trigger never fires.
**Fix:** Always start the waiter, then trigger the action, using `Promise.all`:

```typescript
// CORRECT pattern — start waiter before trigger, resolve both together
const [response] = await Promise.all([
  page.waitForResponse('**/api/save'),
  page.getByRole('button', { name: 'Save' }).click(),
]);
expect(response.status()).toBe(200);
```

### 11. `npm install` instead of `npm ci` in CI causes dependency drift [community]
**What:** Tests pass locally but fail in CI due to different library versions being installed.
**WHY:** `npm install` updates `package-lock.json` and may install newer patch versions that contain breaking changes. `npm ci` installs exactly what the lockfile specifies.
**Fix:** Always use `npm ci` in CI pipelines. Add it as a check in your CI workflow template.

### 12. `toMatchAriaSnapshot()` fails after design system icon library updates [community]
**What:** Aria snapshot tests start failing en masse after updating an icon library or design system, even though no visible behavior changed.
**WHY:** Icon libraries often add or remove `aria-label` or `role` attributes from SVG elements, changing the accessibility tree that `toMatchAriaSnapshot()` captures. Even visually identical changes cause snapshot mismatches.
**Fix:** Use `--update-snapshots=changed` (v1.50+) after intentional design system upgrades. Scope `toMatchAriaSnapshot()` to specific semantic regions (e.g., `getByRole('navigation')`) rather than entire pages to limit blast radius.

### 13. `failOnFlakyTests` breaks new environments where retries are expected [community]
**What:** Enabling `failOnFlakyTests` in a new environment (staging, new CI runner) causes all runs to fail because network latency causes retries on tests that are "stable" in prod CI.
**WHY:** `failOnFlakyTests` treats any pass-on-retry as a failure. New environments with higher latency will naturally produce more retries, triggering false positives.
**Fix:** Enable `failOnFlakyTests` only on established, stable environments (e.g., nightly on main). Use a dedicated env var (`STRICT_FLAKE_MODE`) to gate it — never enable unconditionally in CI.

### 14. `test.describe.serial()` re-runs all tests in the group on any failure [community]
**What:** A serial test group with 10 tests retries all 10 when test #3 fails, rather than just test #3. This is much slower than parallel tests and creates confusing retry traces.
**WHY:** Serial mode runs all tests together as a single unit — Playwright restores the entire group on retry because tests in a serial group share state by design.
**Fix:** Use serial mode only for genuinely stateful multi-step flows (e.g., checkout → confirm → verify order). For independent tests, always use the default parallel mode. If you need shared state, use worker-scoped fixtures instead of serial mode.

### 15. Worker restarts after test failure wipe `beforeAll` state [community]
**What:** After a test fails, the next batch of tests in that worker suddenly starts with clean state — shared fixtures initialized in `beforeAll` or `{ scope: 'worker' }` are gone.
**WHY:** Playwright discards the worker process on test failure and starts a fresh process for the next batch. Any worker-scoped state (DB connections, seeded data, server instances) must be re-initialized.
**Fix:** Use `testInfo.retry` to detect re-runs and conditionally re-initialize state. Design worker-scoped fixtures to be self-healing (idempotent setup):

```typescript
// In a worker-scoped fixture — detect retry and clean up before re-initializing
export const test = base.extend<{}, { dbConnection: DBClient }>({
  dbConnection: [async ({ browser }, use, workerInfo) => {
    const db = await connectToTestDB(workerInfo.workerIndex);
    await use(db);
    await db.cleanup();
    await db.close();
  }, { scope: 'worker' }],
});

// In a test — conditionally clean cache on retry
test('creates a record', async ({ page, request }, testInfo) => {
  if (testInfo.retry > 0) {
    await request.delete('/api/test/cleanup');  // idempotent cleanup before retry
  }
  // ... test body
});
```

### 16. `addLocatorHandler` does not trigger if the overlay renders after the first actionability check [community]
**What:** A cookie banner or sign-up modal appears 500ms after page load. Tests run fine 90% of the time, but occasionally the modal appears during a `click()` or `fill()` and causes "element not found" or "element intercepts pointer events" errors.
**WHY:** `addLocatorHandler` fires before each actionability check — but only when the locator is visible at that moment. If the overlay renders *after* the action starts (due to a slight render delay), the handler never fires for that particular action.
**Fix:** Combine `addLocatorHandler` with a `waitFor({ state: 'hidden' })` poll in the handler body to ensure the dismissal animation completes before the main action proceeds:

```typescript
await page.addLocatorHandler(
  page.locator('[data-testid="cookie-banner"]'),
  async () => {
    const acceptBtn = page.getByRole('button', { name: 'Accept all' });
    await acceptBtn.click();
    // Wait for the banner to fully disappear before yielding control
    await page.locator('[data-testid="cookie-banner"]').waitFor({ state: 'hidden' });
  }
);
```

Alternatively, if the overlay renders at a predictable point (e.g., after the first page load), explicitly await its dismissal in the test body rather than relying on the handler.

### 17. `page.accessibility.snapshot()` removed in v1.57 causes CI-only failures [community]
**What:** Tests that use `page.accessibility.snapshot()` (or `page.accessibility`) start failing after upgrading to Playwright 1.57 with `TypeError: page.accessibility is not a function`.
**WHY:** The `page.accessibility` API was fully removed in v1.57. It was deprecated for several releases, but the removal is breaking for suites that did not migrate during the deprecation window.
**Fix:** Replace `page.accessibility.snapshot()` with `expect(locator).toMatchAriaSnapshot()` for structural accessibility assertions, or `@axe-core/playwright` for WCAG violation scanning. These APIs are actively maintained and more capable.

```typescript
// BEFORE (broken in v1.57+)
// const snapshot = await page.accessibility.snapshot();

// AFTER — use toMatchAriaSnapshot for structural checks
await expect(page.getByRole('navigation')).toMatchAriaSnapshot(`
  - navigation:
    - list:
      - listitem: Home
`);

// AFTER — use axe-core for WCAG compliance
import AxeBuilder from '@axe-core/playwright';
const results = await new AxeBuilder({ page }).analyze();
expect(results.violations).toHaveLength(0);
```

### 18. Upgrading past v1.57 breaks Docker headless mode silently [community]
**What:** After upgrading Playwright past v1.57 in CI, tests start failing with "browser not found" or "executable not found at /usr/bin/google-chrome" in Docker environments.
**WHY:** v1.57 switched from the Chromium build to Chrome for Testing. Headed mode now uses `chrome`; headless uses `chrome-headless-shell`. Docker images built before v1.57 have the old binaries and need to be rebuilt.
**Fix:** Rebuild your Docker image using the matching `mcr.microsoft.com/playwright:vX.Y.Z-noble` base image. Pin both `package.json` and the `FROM` line to the same Playwright version. Never use `:latest` for the Docker image tag.

```dockerfile
# CORRECT — pin to exact matching version
FROM mcr.microsoft.com/playwright:v1.59.0-noble

# WRONG — 'latest' diverges from your package.json
# FROM mcr.microsoft.com/playwright:latest
```

### 19. Service Worker fetch requests not captured by `page.waitForRequest()` in v1.55+ [community]
**What:** After upgrading past v1.55, tests that wait for fetch requests made by a service worker (`background sync`, push handlers) stop capturing those requests in `waitForRequest()`.
**WHY:** Before v1.55, service worker requests were invisible to Playwright routing. From v1.55, service worker network requests now DO flow through `BrowserContext.route()` and `BrowserContext.on('request')` — but only when the service worker runs under the same origin as the page. Tests that previously blocked ALL requests via `page.route('**/*', ...)` may now unexpectedly intercept background service worker fetches too.
**Fix:** If your app uses service workers for background sync or caching, use `context.route()` instead of `page.route()` and add origin-specific filters to avoid catching SW-internal requests:

```typescript
// Filter out service worker internal requests (same-origin, sw.js initiated)
await context.route('**/api/**', async route => {
  // Only intercept requests from main frame, not service workers
  const initiator = route.request().serviceWorker();
  if (initiator) {
    return route.continue();  // let SW requests pass through unmodified
  }
  await route.fulfill({ ... });
});
```

Alternatively, if you don't need SW network interception, keep `serviceWorkers: 'block'` in your config — this preserves the pre-v1.55 behavior.

---

## Breaking Changes Reference (v1.45–v1.59)

A summary of removals and behavioral changes that require action when upgrading.

| Version | Change | Migration |
|---------|--------|-----------|
| v1.59 | macOS 14 WebKit support **dropped** | Use macOS 15+ or Playwright Docker image for WebKit tests |
| v1.59 | `@playwright/experimental-ct-svelte` **removed** | Migrate to SvelteKit e2e tests with standard Playwright config |
| v1.57 | `page.accessibility` API **removed** | Use `toMatchAriaSnapshot()` for structure, `@axe-core/playwright` for WCAG |
| v1.57 | Browser switch: headed→`chrome`, headless→`chrome-headless-shell` | Rebuild Docker images; pin `mcr.microsoft.com/playwright:vX.Y.Z-noble` |
| v1.57 | React 16/17 component testing **removed** | Upgrade to React 18+ or test via e2e |
| v1.57 | `_react`/`_vue` component selectors **removed** | Use `getByTestId`, `getByRole`, `getByText` |
| v1.55 | macOS 13 WebKit support **dropped** | Use macOS 14+ or run WebKit tests in the Playwright Docker image |
| v1.52 | `toHaveClass('active disabled')` asserts the full class list | Use `toContainClass('active')` for partial class presence (v1.52+) |
| v1.50 | `updateSnapshots` default changed to `'missing'` | Set `updateSnapshots: 'changed'` in config to prevent overwriting stable baselines |
| v1.46 | `maxRetries` added to `APIRequestContext` options | Use `{ maxRetries: 3 }` instead of wrapping in try/catch |

> Always pin your Playwright version in `package.json` and the Docker base image to the same version. A mismatch causes "browser not found" errors. [community]

---

## CI Considerations

### Key differences between local and CI execution

| Concern | Local default | CI recommendation | Reason |
|---------|-------------|-------------------|--------|
| `retries` | `0` | `2` | Flakes from resource contention or timing should auto-recover |
| `workers` | CPU count | `2–4` | Over-parallelizing in shared CI runners causes resource contention |
| `trace` | `off` | `'on-first-retry'` | Full traces on every test exhaust disk in large suites |
| `video` | `off` | `'on-first-retry'` | Same reason as traces; only record failures |
| `reporter` | `html` | `'blob'` | `html` reporter doesn't support merging across shards |
| `forbidOnly` | `false` | `true` | Block accidental `test.only()` from merging |
| `screenshot` | `off` | `'only-on-failure'` | Captures state at failure without filling disk |
| `timeout` | `30000` | `60000` | CI machines are slower; avoid flakes from timing |
| `maxFailures` | unlimited | `10` | Stop consuming resources when suite is fundamentally broken |
| `failOnFlakyTests` | `false` | `true` (nightly only) | Surface retry-passing tests as failures on stable nightly runs |
| `captureGitInfo` | `false` | `{ commit: true }` | Links test failures to specific commits in HTML reports |
| `updateSnapshots` | `'missing'` | `'changed'` | Only update snapshots that actually differ; protect stable baselines |
| `tag` | omitted | `CI_ENVIRONMENT_NAME` | Label runs in reports to distinguish staging from prod smoke runs |

### Installing browsers correctly in CI

```bash
# Install only Chromium to save 300–500 MB per omitted browser
npx playwright install chromium --with-deps

# --with-deps installs OS-level system libraries (libatk, ffmpeg, etc.)
# Omitting it causes silent browser crashes in headless environments
```

### Running Playwright in Docker

Use the official Playwright image — it includes browsers and system dependencies pre-installed. **Do not use Alpine Linux** — musl libc is incompatible with Chromium browser builds.

```dockerfile
# Dockerfile — pin to exact Playwright version to prevent version mismatch
FROM mcr.microsoft.com/playwright:v1.59.0-noble

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .

# Browsers are already installed in the base image
CMD ["npx", "playwright", "test"]
```

```bash
# Run with required flags for Chromium stability in Docker
docker run --rm \
  --init \           # prevent zombie processes (PID=1 signal handling)
  --ipc=host \       # Chromium needs shared memory; without this, it crashes under load
  -v $(pwd)/test-results:/app/test-results \
  playwright-tests:latest
```

**Remote Playwright Server in Docker (run server in Docker, tests on host):**

```bash
# Start Playwright server in Docker, exposed on port 3000
docker run --rm --init -p 3000:3000 \
  mcr.microsoft.com/playwright:v1.59.0-noble \
  npx playwright run-server --port 3000

# Connect from local tests via environment variable
PW_TEST_CONNECT_WS_ENDPOINT=ws://localhost:3000 npx playwright test
```

```typescript
// Or connect programmatically in playwright.config.ts
export default defineConfig({
  use: {
    // Connect to remote Playwright server (useful for distributed CI)
    connectOptions: process.env.PW_TEST_CONNECT_WS_ENDPOINT
      ? { wsEndpoint: process.env.PW_TEST_CONNECT_WS_ENDPOINT }
      : undefined,
  },
});
```

**Docker CI tips:**
- Pin the Docker image to the exact Playwright version matching `package.json`. A mismatch causes "browser not found" errors.
- Use `--ipc=host` in both local Docker runs and CI container configurations.
- For untrusted web content (scraping), use `--user pwuser --security-opt seccomp=...` to sandbox the browser.
- The image includes Xvfb for headed browser testing on Linux — use `xvfb-run npx playwright test` if headed mode is needed.

> Never cache `~/.cache/ms-playwright` in Docker-based CI — browser download time ≈ cache restoration time, so caching provides no benefit and adds complexity. [community]



```typescript
// Disable CSS animations globally to prevent visual flakiness
// Add this to a global fixture that applies to every test
await page.addStyleTag({
  content: `
    *, *::before, *::after {
      animation-duration: 0ms !important;
      animation-delay: 0ms !important;
      transition-duration: 0ms !important;
    }
  `,
});
```

> CSS animations are a top cause of screenshot comparison flakiness even when elements
> are "visible". Inject via `page.addStyleTag` for visual regression tests. [community]

### Parallelism and resource limits

```bash
# Run with explicit worker count — avoids over-spawning on shared runners
npx playwright test --workers=4

# Sharding — split across machines in CI matrix
npx playwright test --shard=1/4
npx playwright test --shard=2/4
# ... merge blob reports after all jobs complete

# Re-run only failed tests before failing the build (handle transient flakes)
npx playwright test --last-failed

# Run only tests in files changed since last commit (v1.46+)
npx playwright test --only-changed

# Run only tests in files changed relative to a branch (v1.46+)
npx playwright test --only-changed=origin/main
```

**Scaling beyond CI matrix sharding — Kubernetes (Moon) and cloud orchestrators:**

For suites with 1000+ tests, GitHub Actions matrix sharding may not be enough. Cloud-native options:
- **Currents** (`currents-dev`): Cloud dashboard + smart test ordering that runs the slowest tests first (reduces wall-clock time). Drop-in replacement for `npx playwright test` via `npx currents`.
- **Moon** (`moonrepo/moon`): Runs Playwright tests in parallel across Kubernetes pods. Defines Playwright as a task in `moon.yml`, distributes shards across nodes via a job scheduler.
- **Playwright Remote Server**: Use `npx playwright run-server` in Docker + connect from multiple workers via `PW_TEST_CONNECT_WS_ENDPOINT` for a self-hosted grid.

```bash
# Currents cloud orchestration (drop-in for npx playwright test)
npx currents run --project chromium --ci-build-id "$GITHUB_RUN_ID" --shard "$CI_NODE_INDEX/$CI_NODE_TOTAL"

# Self-hosted grid: start server in one container, run tests from another
# Container 1:
docker run -p 3000:3000 mcr.microsoft.com/playwright:v1.59.0-noble npx playwright run-server --port 3000
# Container 2 (run tests):
PW_TEST_CONNECT_WS_ENDPOINT=ws://playwright-server:3000 npx playwright test --shard=1/4
```

> At 500+ tests, the bottleneck shifts from parallelism within a machine to provisioning enough machines. Cloud orchestrators like Currents eliminate the CI matrix YAML boilerplate and provide cross-run analytics to identify slow tests. [community]

### Trace Modes Reference

| Mode | What it records | When to use |
|------|----------------|-------------|
| `'off'` | Nothing | Local dev (no need for traces) |
| `'on-first-retry'` | Only when a test is retried the first time | Standard CI — captures flakes without overhead |
| `'on-all-retries'` | Every retry attempt | When you need to compare multiple retry states |
| `'retain-on-failure'` | Every test, but deletes traces for passing tests | When you want traces for ALL failures, not just retried ones |
| `'on'` | Every test, always | Local debugging only — too expensive for CI |

```typescript
// playwright.config.ts — retention strategies
export default defineConfig({
  use: {
    // Most teams: capture flakes without overhead
    trace: 'on-first-retry',

    // Large suites with zero-retry policy: capture all failures
    // trace: 'retain-on-failure',

    // CI with retries=0 and need for failure traces:
    // trace: process.env.CI ? 'retain-on-failure' : 'off',
  },
});
```



```typescript
// Tag known flaky tests for monitoring without blocking CI
test('known flaky: payment flow', { tag: '@flaky' }, async ({ page }) => {
  // ...
});
```

```bash
# Run flaky tests separately with more retries
npx playwright test --grep @flaky --retries=5
# Run stable tests with standard retries
npx playwright test --grep-invert @flaky --retries=2
```

---

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| `page.waitForTimeout(3000)` | Arbitrary sleep; slow and still flaky on congested CI | `waitForURL`, `waitForLoadState`, or a web-first assertion |
| `page.locator('.btn-primary')` | Breaks on CSS refactor | `getByRole('button', { name: '...' })` |
| `await el.textContent()` then `toBe()` | Synchronous check without retry; races DOM updates | `await expect(locator).toHaveText(...)` |
| `page.$$('.row').then click` | DOM may change between query and action | Use a `Locator`; it re-evaluates on every action |
| Auth in every test via UI | 10–50× slower; creates coupling | `storageState` via `auth.setup.ts` |
| `test.describe.configure({ mode: 'serial' })` everywhere | Kills parallelism | Only for inherently stateful multi-step flows |
| Hard-coded `localhost:3000` in specs | Breaks in CI / staging environments | Use `baseURL` from config; `page.goto('/path')` |
| One giant spec file | Prevents parallelism; hard to maintain | Split by feature domain |
| `expect.soft()` without checking `test.info().errors` | Failures silently pass | Always verify `errors.toHaveLength(0)` |
| Forgetting `await use()` in a fixture | Fixture value never delivered; teardown never runs | Always `await use(value)` |
| Exposing raw selectors from POM | Couples tests to implementation | Expose action methods; keep locators private |
| Test-scoped fixtures for expensive shared resources | Recreates DB/server per test | Use `{ scope: 'worker' }` for expensive shared setup |
| `trace: 'on'` (every test) | Severe performance cost; fills CI disk | `'on-first-retry'` in CI; `'on'` only for local debugging |
| Mixing Jest's `expect` with Playwright | Loses auto-retry and timeout management | Import `expect` from `@playwright/test` only |
| `waitForLoadState('networkidle')` on polling apps | Hangs for full timeout on apps with SSE/WebSocket | Use `waitForURL` or assert visible UI state |
| Using `html` reporter with sharding | Loses attachments across shards | Use `blob` reporter + `merge-reports` |
| `Date.now()` for unique test data in parallel | Millisecond collisions cause data conflicts | Use `testInfo.testId` or `workerInfo.workerIndex` |
| Committing macOS/Windows snapshots to CI | Visual test failures due to platform rendering differences | Generate and commit baselines on Linux/CI only |
| `await waitForResponse()` before action | Deadlock — response waiter fires before trigger | Use `Promise.all([waitForResponse, click])` pattern |
| `npm install` in CI | Dependency drift; different versions than lockfile | Always use `npm ci` in CI pipelines |
| `--with-deps` omitted when installing browsers | Silent browser crashes from missing OS libraries | Always `npx playwright install chromium --with-deps` |
| `toHaveClass('active disabled')` for partial class checks | Asserts the complete class string; fails if extra classes exist | Use `toContainClass('active')` (v1.52+) for partial class presence |
| Running visual tests with `workers > 1` | Rendering differs across parallel processes; spurious diffs | Set `workers: 1` for visual test projects in playwright.config.ts |
| Using `globalSetup` for setup that needs fixtures or traces | `globalSetup` has no access to fixtures, page, or trace | Use project-based dependencies with `testMatch: /global.setup.ts/` |
| `await using` without TypeScript 5.2+ | Syntax error at compile time | Verify `"target": "ES2022"` or later in `tsconfig.json` before using async disposables |
| `--update-snapshots` (update all) after fixing one component | Overwrites stable baselines for unrelated components with drift | Use `--update-snapshots=changed` to only update actually-differing snapshots |
| `failOnFlakyTests: true` in all CI environments | False positives in new/slow environments where retries are expected | Gate with env var; enable only on established nightly runs |
| `test.describe.serial()` for independent tests | All serial tests retry together on one failure — wastes time | Use parallel mode by default; serial only for genuinely state-dependent flows |
| Not cleaning up state on `testInfo.retry > 0` | Worker restart leaves stale state; retried tests start dirty | Use `if (testInfo.retry > 0) await cleanup()` to reset before retry |
| Component test config mixed with e2e config | Confusing failures from wrong test runner being invoked | Use separate `playwright-ct.config.ts` for component tests |
| Forgetting `respectGitIgnore: true` in monorepos | Test discovery crawls `node_modules/` or generated build directories | Set `respectGitIgnore: true` and explicit `testMatch` patterns |
| CHIPS cookies tested with `secure: false` locally | Cookie attribute differs from production; may hide auth bugs | Use a local HTTPS dev server or document the known difference |
| Passing complex live objects as component test props | Runtime error: class instances and closures cannot be passed to CT | Use plain data; wrap complex state in story components |
| Calling `locator.normalize()` at runtime in tests | Adds overhead without fixing the underlying brittle selector | Use `normalize()` as a discovery tool; hardcode the improved selector |
| `globalSetup` for test data seeding in large suites | Runs once globally — worker restarts wipe seeded state silently | Use `{ scope: 'worker', auto: true }` fixtures for idempotent per-worker setup |
| `page.on('console', ...)` in every test for error monitoring | Verbose boilerplate; easy to forget; doesn't clean up | Use `{ auto: true }` console monitor fixture that applies to all tests |
| Committing `.network-cache/` responses with auth tokens | Token in cache leaks credentials to everyone with repo access | Strip `Authorization` headers from cache files; use placeholder values |
| Using `page.accessibility` (removed v1.57) | `page.accessibility` API was fully removed in v1.57 | Use `expect(locator).toMatchAriaSnapshot()` for structural checks or `@axe-core/playwright` for WCAG scanning |
| Assuming Docker base image uses Chromium browser binary | Since v1.57, headed mode uses `chrome` and headless uses `chrome-headless-shell` — not the old Chromium build | Rebuild Docker images after upgrading past v1.57; always pin `FROM mcr.microsoft.com/playwright:vX.Y.Z-noble` |
| Using `@playwright/experimental-ct-react` with React 16/17 | Support for React 16/17 in CT was removed in v1.57 | Upgrade to React 18+ or use e2e tests for legacy components |

---

## Key APIs

### Navigation & Waiting

| API | What it does | When to use it |
|-----|-------------|----------------|
| `page.goto(url)` | Navigate; waits for `load` event | Start of every test |
| `page.waitForURL(pattern)` | Wait until URL matches string/regex | After form submit or redirect |
| `page.waitForLoadState('domcontentloaded')` | Wait until DOM is parsed | Fast navigation assertion |
| `page.waitForLoadState('networkidle')` | Wait until network settles | Static pages only — avoid on polling apps |
| `page.waitForResponse(url)` | Wait for a specific HTTP response | After UI actions that trigger API calls |
| `context.setStorageState({ path })` | Reset all storage state in-place (v1.59+) | Role-switching tests without new context |
| `page.clearConsoleMessages()` | Clear accumulated console logs (v1.59+) | Reset log state mid-test |
| `page.clearPageErrors()` | Clear accumulated page errors (v1.59+) | Reset error state mid-test |
| `page.consoleMessages({ filter })` | Retrieve stored console log history (v1.59+) | Post-action console error assertions |
| `page.pageErrors({ filter })` | Retrieve stored JS exception history (v1.59+) | Post-action uncaught error checks |
| `page.requests({ filter })` | Retrieve stored network request history (v1.59+) | Verify API calls without event listeners |
| `page.addLocatorHandler(locator, fn)` | Auto-dismiss overlays before actionability checks | Cookie banners, popups, modals |
| `page.removeLocatorHandler(locator)` | Remove a previously added overlay handler | Cleanup after targeted page sections |

### Locators

| API | What it does | When to use it |
|-----|-------------|----------------|
| `page.getByRole(role, opts)` | Find by ARIA role + accessible name | Primary choice for interactive elements |
| `page.getByLabel(text)` | Find input by its `<label>` text | Form inputs |
| `page.getByPlaceholder(text)` | Find input by placeholder | Inputs without visible labels |
| `page.getByText(text)` | Find by visible text content | Static text nodes |
| `page.getByTestId(id)` | Find by `data-testid` attribute | When semantic locators aren't available |
| `locator.filter({ hasText })` | Narrow locator set by contained text | Lists with repeating elements |
| `locator.and(other)` | Match two locator conditions simultaneously | Elements requiring dual qualification |
| `locator.or(other)` | Match one of multiple alternatives | Conditional UI states |
| `locator.nth(index)` | Select the N-th match | Ordered stable lists only |
| `locator.normalize()` | Convert to best-practice locator (v1.59+) | Upgrade CSS/brittle selectors during refactors |
| `locator.ariaSnapshot(opts?)` | Get raw ARIA tree string (v1.59+) | Discover snapshot strings during test development; pass `{ depth: N }` to limit levels |
| `locator.filter({ visible: true })` | Filter to only visible matches (v1.50+) | When DOM has duplicate visible/hidden elements |
| `locator.contentFrame()` | Convert iframe `Locator` to `FrameLocator` (v1.43+) | Enter iframe contents starting from element handle |
| `frameLocator.owner()` | Convert `FrameLocator` to iframe element `Locator` (v1.43+) | Assert on the iframe element itself |

### Assertions (always import `expect` from `@playwright/test`)

| API | What it does | When to use it |
|-----|-------------|----------------|
| `expect(locator).toBeVisible()` | Auto-retrying visibility check | General presence checks |
| `expect(locator).toHaveText(str)` | Auto-retrying text content match | Text content assertions |
| `expect(locator).toHaveValue(str)` | Input's current value matches | Form field validation |
| `expect(locator).toBeEnabled()` / `toBeDisabled()` | Interaction state | Button/input state |
| `expect(locator).toBeChecked()` | Checkbox/radio is checked | Toggle state |
| `expect(locator).toHaveCount(n)` | Locator matches exactly N elements | List length |
| `expect(page).toHaveURL(pattern)` | Current URL matches | Post-navigation checks |
| `expect(page).toHaveTitle(str)` | Page title matches | Page identity |
| `expect(locator).toHaveScreenshot()` | Visual regression snapshot | Critical UI components |
| `expect(page).toHaveScreenshot()` | Full-page visual regression | Whole-page regression |
| `expect(locator).toMatchAriaSnapshot()` | ARIA accessibility tree snapshot (v1.49+) | Accessibility structure regression |
| `expect(locator).toContainClass(cls)` | Assert single class present (v1.52+) | Class presence without full-class match |
| `expect(locator).toHaveAccessibleErrorMessage(msg)` | Validate aria-errormessage (v1.52+) | Form validation accessibility |
| `expect.soft(locator)` | Non-blocking assertion; collects errors | Multi-field validation |
| `expect.configure({ timeout, soft })` | Scoped expect instance with custom settings | Block-level timeout/soft mode |
| `expect.poll(fn)` | Poll async function until assertion passes | External state / API polling |
| `expect(fn).toPass()` | Retry entire code block until no failures | Complex multi-step conditions |
| `expect.extend({...})` | Define custom matchers | Domain-specific assertions |

### Actions

| API | What it does | When to use it |
|-----|-------------|----------------|
| `locator.click()` | Click (waits for actionable) | Buttons, links |
| `locator.fill(value)` | Clear and type into an input | Form fields |
| `locator.selectOption(value)` | Select a `<select>` option | Dropdown selects |
| `locator.check()` / `uncheck()` | Set checkbox state | Checkboxes |
| `locator.hover()` | Move mouse over element | Tooltips, hover menus |
| `locator.dragTo(target)` | Drag to target element | Drag-and-drop |
| `page.keyboard.press('Enter')` | Keyboard shortcut / key press | Keyboard navigation |

### Network Interception

| API | What it does | When to use it |
|-----|-------------|----------------|
| `page.route(url, handler)` | Intercept and mock network requests | Test error states; isolate from backend |
| `browserContext.route(url, handler)` | Intercept across all pages including popups | Multi-window or popup scenarios |
| `route.abort()` | Block the request entirely | Remove tracking pixels, large assets |
| `route.fetch()` then `route.fulfill()` | Fetch real response then modify it | Feature flag injection, response patching |
| `route.continue()` | Pass request through with optional header/body override | Inject auth headers on outbound requests |
| `page.waitForRequest(url)` | Wait for outgoing request | Verify API calls are made |
| `page.waitForResponse(url)` | Wait for incoming response | Verify API responses are handled |
| `request.existingResponse()` | Get response without blocking — returns null if not yet received (v1.59+) | Non-blocking response inspection |
| `request.maxRetries` option | Retry request on `ECONNRESET` errors (v1.46+) | Unstable staging environments |
| `request.maxRedirects` option | Max HTTP redirects to follow; `0` disables (v1.52+) | Assert on redirect responses |
| `response.httpVersion()` | Returns HTTP protocol version (v1.59+) | Verify HTTP/2 or HTTP/3 usage |
| `page.routeWebSocket(url, handler)` | Intercept WebSocket connections (v1.48+) | Mock WebSocket messages |

### Fixtures

| API | What it does | When to use it |
|-----|-------------|----------------|
| `test.extend<T>()` | Declare custom fixtures with type safety | All custom setup/teardown |
| `test.use(overrides)` | Configure fixture values for a scope | Scoped configuration |
| `mergeTests(a, b)` | Combine fixtures from multiple modules | Modular fixture composition |
| `mergeExpects(a, b)` | Combine custom `expect` extensions from multiple modules (v1.39+) | Single import for all custom matchers |
| `workerInfo.workerIndex` | Unique per-worker integer | Worker-scoped unique test data |
| `testInfo.testId` | Globally unique test identifier | Per-test unique data seeds |
| `testInfo.tags` | Array of tags applied to current test | Tag-based branching in fixtures |
| `{ scope: 'worker' }` | Share fixture across all tests in a worker | Expensive shared resources (DB, server) |
| `{ auto: true }` | Run fixture for every test automatically | Universal setup like global logging |
| `{ box: true }` | Hide fixture steps from test report | Reduce report noise for helper fixtures |
| `locator.describe(label)` | Annotate locator with human-readable name (v1.52+) | Trace/report readability |
| `testInfo.snapshotPath(name, { kind })` | Route snapshot to kind-specific directory (v1.53+) | Separate visual/aria/text baselines |

---

### Accessibility Testing with `@axe-core/playwright`

Integrate accessibility scans into existing test workflows. Run scans after UI interactions to check the final state, not the initial load.

```typescript
// Install: npm install --save-dev @axe-core/playwright

// e2e/fixtures/axe.ts — shared AxeBuilder fixture
import { test as base } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

type AxeFixtures = { makeAxeBuilder: () => AxeBuilder };

export const test = base.extend<AxeFixtures>({
  makeAxeBuilder: async ({ page }, use) => {
    const makeAxeBuilder = () =>
      new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
        .exclude('#known-violation'); // suppress known pre-existing issues
    await use(makeAxeBuilder);
  },
});

// e2e/specs/accessibility.spec.ts
import { test, expect } from '../fixtures/axe';

test('login page has no WCAG violations', async ({ page, makeAxeBuilder }) => {
  await page.goto('/login');
  const results = await makeAxeBuilder().analyze();
  // Use node targets, not raw HTML, to decouple from DOM structure
  const violations = results.violations.map(v => ({
    id:      v.id,
    targets: v.nodes.map(n => n.target),
  }));
  expect(violations).toHaveLength(0);
});

test('modal has no violations after interaction', async ({ page, makeAxeBuilder }) => {
  await page.goto('/dashboard');
  await page.getByRole('button', { name: 'Open Settings' }).click();
  await expect(page.getByRole('dialog')).toBeVisible();
  // Scan only the dialog, not the whole page
  const results = await makeAxeBuilder()
    .include('[role="dialog"]')
    .analyze();
  expect(results.violations).toHaveLength(0);
});
```

> Scan the focused element after user interactions (modal open, drawer expand) — not just at page load.
> The state after interaction is where most accessibility regressions hide. [community]

---

### Test Annotations and Tagging Strategy

Use tags and annotations to organize, filter, and report on tests systematically. Avoid `test.only()` — use tags with `--grep` instead.

```typescript
// Tag tests with @ prefix for filtering
test('checkout flow', { tag: ['@smoke', '@critical'] }, async ({ page }) => {
  // ...
});

test('image upload', { tag: '@slow' }, async ({ page }) => {
  // ...
});

// Skip conditionally based on browser or environment
test('drag-and-drop', async ({ page, browserName }) => {
  test.skip(browserName === 'firefox', 'Firefox does not support this drag API yet');
  // ...
});

// Mark known failing test without blocking the pipeline
test('payment integration', async ({ page }) => {
  test.fixme(); // will not run; marks as fixme in report
  // ...
});

// Slow down timeout for a specific test
test('full data export', async ({ page }) => {
  test.slow(); // triples the test timeout for this test only
  // ...
});

// Add custom metadata visible in HTML report
test('JIRA-1234: checkout total mismatch', async ({ page }) => {
  test.info().annotations.push({ type: 'issue', description: 'https://jira.example.com/browse/JIRA-1234' });
  // ...
});

// annotation.location — shows WHERE in source test.skip/test.fixme was declared (v1.54+)
// This appears in HTML report and traces, making it easy to find the call site
test('skipped with location context', async ({ page }) => {
  test.skip(true, 'Awaiting backend fix for JIRA-5678');
  // HTML report shows: "skipped at e2e/specs/checkout.spec.ts:123" — no grep needed
});
```

**CLI filtering examples:**
```bash
# Run only smoke tests
npx playwright test --grep @smoke

# Run smoke OR critical
npx playwright test --grep "@smoke|@critical"

# Skip slow tests
npx playwright test --grep-invert @slow

# Run only Chrome tests tagged smoke
npx playwright test --grep @smoke --project=chromium
```

---

### Global Setup with Project Dependencies

Prefer project-based dependencies over `globalSetup` — they appear in the HTML report, support traces, and have access to fixtures.

```typescript
// playwright.config.ts — project-based global setup
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  projects: [
    {
      name: 'setup-db',
      testMatch: /global\.setup\.ts/,  // setup project
    },
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
      dependencies: ['setup-db'],      // waits for setup-db to complete
    },
  ],
});

// e2e/global.setup.ts
import { test as setup } from '@playwright/test';

setup('prepare database', async ({ request }) => {
  const response = await request.post('/api/test/reset');
  expect(response.ok()).toBeTruthy();
});
```

**Pass data from setup to tests via environment variables:**

```typescript
// e2e/global.setup.ts
setup('create test account', async ({ request }) => {
  const res = await request.post('/api/accounts', { data: { tier: 'premium' } });
  const { id } = await res.json();
  process.env.TEST_ACCOUNT_ID = String(id);  // accessible in all tests
});

// e2e/specs/billing.spec.ts
test('billing shows premium tier', async ({ page }) => {
  await page.goto(`/accounts/${process.env.TEST_ACCOUNT_ID}/billing`);
  await expect(page.getByText('Premium')).toBeVisible();
});
```

---

### Reporters: Built-in and Custom

Configure multiple reporters in parallel. Use `blob` + `html` for CI pipelines with sharding; `junit` for Jenkins/Azure Pipelines integration.

```typescript
// playwright.config.ts — multi-reporter setup
export default defineConfig({
  reporter: process.env.CI
    ? [
        ['blob'],                                         // for shard merging
        ['junit', { outputFile: 'test-results.xml' }],   // for CI analytics
      ]
    : [
        ['html', { open: 'on-failure' }],                // open on failure locally
        ['list'],                                         // live progress in terminal
      ],
});
```

**Custom reporter for Slack/webhook notifications:**

```typescript
// e2e/reporters/slack-reporter.ts
import type { Reporter, FullResult } from '@playwright/test/reporter';

class SlackReporter implements Reporter {
  private failed: string[] = [];

  onTestEnd(test: import('@playwright/test/reporter').TestCase, result: import('@playwright/test/reporter').TestResult) {
    if (result.status === 'failed') this.failed.push(test.title);
  }

  async onEnd(result: FullResult) {
    if (result.status === 'failed' && this.failed.length > 0) {
      await fetch(process.env.SLACK_WEBHOOK_URL!, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text: `:red_circle: ${this.failed.length} Playwright tests failed:\n${this.failed.join('\n')}`,
        }),
      });
    }
  }
}

export default SlackReporter;
```

```typescript
// playwright.config.ts — register custom reporter
reporter: [
  ['blob'],
  ['./e2e/reporters/slack-reporter.ts'],
],
```

**Timeline visualization in merged reports (v1.58+):** When you merge shard reports with `npx playwright merge-reports`, the HTML report now includes a Timeline view that shows all tests across shards in chronological order. Use this to identify workers that are significantly slower than others — an imbalance signal to rebalance test distribution.

```bash
# Download all shard artifacts, then merge with timeline view
npx playwright merge-reports --reporter html ./all-blob-reports
# Open playwright-report/index.html → Timeline tab
```

**HTML reporter custom title (v1.53+):** Label individual HTML reports for different environments or run types:

```typescript
// playwright.config.ts — identify this run's HTML report
export default defineConfig({
  reporter: [
    ['html', {
      title: `Playwright — ${process.env.TEST_ENV ?? 'local'} — ${new Date().toISOString().slice(0, 10)}`,
      open: 'on-failure',
    }],
  ],
});
```

> A custom `title` in the HTML reporter makes merged multi-shard reports instantly distinguishable in shared team dashboards. Include the environment name and date. [community]

---

### Multi-Environment Project Configuration

Use separate projects to test staging vs. production with different configurations.

```typescript
// playwright.config.ts — environment-aware multi-project setup
import { defineConfig, devices } from '@playwright/test';

const environments = {
  staging:    { baseURL: 'https://staging.example.com',    retries: 2 },
  production: { baseURL: 'https://www.example.com',        retries: 0 },
};

const env = (process.env.TEST_ENV as keyof typeof environments) ?? 'staging';

export default defineConfig({
  projects: [
    {
      name: `setup-${env}`,
      testMatch: /auth\.setup\.ts/,
      use: { baseURL: environments[env].baseURL },
    },
    {
      name: `chromium-${env}`,
      use: {
        ...devices['Desktop Chrome'],
        baseURL:      environments[env].baseURL,
        storageState: `e2e/.auth/${env}-user.json`,
      },
      retries:      environments[env].retries,
      dependencies: [`setup-${env}`],
    },
  ],
});
```

**Tag-based smoke vs regression split:**

```bash
# PR check: smoke only (fast)
npx playwright test --grep @smoke --project=chromium-staging

# Nightly: full regression
npx playwright test --grep-invert @wip --project=chromium-staging
```

---

### Custom `expect` Matchers

Extend Playwright's `expect` with domain-specific assertions that improve test readability and reduce repetition.

```typescript
// e2e/fixtures/matchers.ts
import { expect as baseExpect, type Locator } from '@playwright/test';

export const expect = baseExpect.extend({
  /**
   * Asserts that a form field has a specific validation error message.
   */
  async toHaveValidationError(locator: Locator, expectedMessage: string) {
    const errorEl = locator.locator('[data-testid="field-error"]');
    const pass = await errorEl.filter({ hasText: expectedMessage }).isVisible();
    return {
      message: () =>
        `Expected field to have validation error "${expectedMessage}"`,
      pass,
      name: 'toHaveValidationError',
    };
  },

  /**
   * Asserts that a toast notification with specific text appears and disappears.
   */
  async toShowToast(page: import('@playwright/test').Page, text: string) {
    const toast = page.getByRole('status').filter({ hasText: text });
    await toast.waitFor({ state: 'visible' });
    const pass = await toast.isVisible();
    return {
      message: () => `Expected toast with text "${text}" to be visible`,
      pass,
      name: 'toShowToast',
    };
  },
});

// e2e/specs/signup.spec.ts
import { test }   from '@playwright/test';
import { expect } from '../fixtures/matchers';

test('shows validation errors on empty submit', async ({ page }) => {
  await page.goto('/signup');
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByTestId('email-field')).toHaveValidationError('Email is required');
  await expect(page.getByTestId('password-field')).toHaveValidationError('Password is required');
});
```

---

### Keyboard and Focus Testing

Test keyboard navigation to verify accessibility and keyboard-driven workflows.

```typescript
// Tab through form fields and verify focus order
test('form is keyboard navigable', async ({ page }) => {
  await page.goto('/contact');
  // Focus the first field
  await page.getByLabel('Name').focus();
  await expect(page.getByLabel('Name')).toBeFocused();

  // Tab to next field
  await page.keyboard.press('Tab');
  await expect(page.getByLabel('Email')).toBeFocused();

  await page.keyboard.press('Tab');
  await expect(page.getByLabel('Message')).toBeFocused();
});

// Keyboard shortcut testing
test('Ctrl+K opens command palette', async ({ page }) => {
  await page.goto('/app');
  await page.keyboard.press('Control+k');
  await expect(page.getByRole('dialog', { name: 'Command palette' })).toBeVisible();
});

// Enter key submits form
test('Enter key submits search', async ({ page }) => {
  await page.goto('/search');
  await page.getByPlaceholder('Search...').fill('playwright');
  await page.keyboard.press('Enter');
  await page.waitForURL(/q=playwright/);
  await expect(page.getByText('results for "playwright"')).toBeVisible();
});
```

---

### `expect.poll` for External State Assertions

Use `expect.poll()` when asserting against state that lives outside Playwright's control (queues, databases, analytics events).

```typescript
// Poll an API endpoint until it reflects the expected state
test('export job completes within 30 seconds', async ({ page, request }) => {
  await page.goto('/exports/new');
  await page.getByRole('button', { name: 'Start export' }).click();
  const jobId = await page.locator('[data-job-id]').getAttribute('data-job-id');

  await expect.poll(
    async () => {
      const res = await request.get(`/api/jobs/${jobId}`);
      return (await res.json()).status;
    },
    {
      intervals: [1_000, 2_000, 5_000],
      timeout:   30_000,
      message:   `Job ${jobId} did not complete`,
    }
  ).toBe('completed');
});
```

> `expect.poll()` is preferable to `page.waitForFunction()` when the condition involves
> server-side state that cannot be observed in the browser DOM. [community]

---

### Browser Storage Manipulation (localStorage / sessionStorage / cookies)

Directly set storage state before navigation to test authenticated or feature-flagged states without UI flows.

```typescript
// Set localStorage values before page load
test('dark mode preference is persisted', async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => localStorage.setItem('theme', 'dark'));
  await page.reload();
  await expect(page.locator('html')).toHaveClass(/dark/);
});

// Read localStorage after user action
test('saves draft to localStorage', async ({ page }) => {
  await page.goto('/editor');
  await page.getByLabel('Title').fill('My draft');
  await page.keyboard.press('Control+s');
  const saved = await page.evaluate(() => localStorage.getItem('draft'));
  expect(JSON.parse(saved!).title).toBe('My draft');
});

// Set cookies directly (faster than UI login for token-based auth)
test('pre-load auth token via cookie', async ({ page, context }) => {
  await context.addCookies([{
    name:   'auth_token',
    value:  process.env.E2E_TEST_TOKEN!,
    domain: 'localhost',
    path:   '/',
    httpOnly: true,
    secure:   false,
  }]);
  await page.goto('/dashboard');
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
});
```

> Directly setting `localStorage` / cookies before navigation is 5–10× faster than
> logging in via UI. Combine with `storageState` for the most efficient auth strategy. [community]

---

### CHIPS (Partitioned Cookies) Support (v1.54+)

Test applications that use CHIPS (Cookies Having Independent Partitioned State) — where cookies are isolated by top-level site to prevent cross-site tracking. Required for testing third-party embeds and cross-origin iframes.

```typescript
// Set a partitioned cookie for a third-party embed
test('third-party widget loads with partitioned auth', async ({ context }) => {
  // CHIPS cookie: isolated per top-level site (partitionKey = the embedding site)
  await context.addCookies([{
    name:         'widget_session',
    value:        process.env.WIDGET_SESSION_TOKEN!,
    domain:       'widget.third-party.com',
    path:         '/',
    httpOnly:     true,
    secure:       true,
    sameSite:     'None',
    partitionKey: { sourceOrigin: 'https://your-app.com' },  // CHIPS partition key
  }]);

  await page.goto('/dashboard');
  const widgetFrame = page.frameLocator('iframe[src*="widget.third-party.com"]');
  await expect(widgetFrame.getByText('Widget loaded')).toBeVisible();
});

// Verify cookies are correctly partitioned (not shared across sites)
test('cookie is not accessible from other contexts', async ({ browser }) => {
  const context1 = await browser.newContext();
  const context2 = await browser.newContext();

  await context1.addCookies([{
    name: 'test_cookie', value: 'value1', domain: 'localhost', path: '/',
    partitionKey: { sourceOrigin: 'http://site-a.localhost' },
  }]);

  // context2 with different partition — should NOT see context1's cookie
  const cookies2 = await context2.cookies('http://site-b.localhost');
  expect(cookies2.find(c => c.name === 'test_cookie')).toBeUndefined();

  await context1.close();
  await context2.close();
});
```

> CHIPS partitioned cookies require `secure: true` and `sameSite: 'None'` in production.
> In local testing (`http://localhost`), you may need to use `secure: false` — be aware
> this differs from the production cookie attributes and may hide auth bugs. [community]

---

### Performance Timing Assertions

Verify page load and interaction performance within tests using the Navigation Timing API.

```typescript
// Assert page load time via PerformanceTiming
test('homepage loads within 3 seconds', async ({ page }) => {
  const start = Date.now();
  await page.goto('/');
  await expect(page.getByRole('main')).toBeVisible();
  const elapsed = Date.now() - start;
  expect(elapsed).toBeLessThan(3_000);
});

// Use PerformanceNavigationTiming for more precise measurement
test('TTFB is acceptable', async ({ page }) => {
  await page.goto('/');
  const navigationTiming = await page.evaluate(() => {
    const [entry] = performance.getEntriesByType('navigation') as PerformanceNavigationTiming[];
    return {
      ttfb:       entry.responseStart - entry.requestStart,
      domReady:   entry.domContentLoadedEventEnd - entry.navigationStart,
      fullLoad:   entry.loadEventEnd - entry.navigationStart,
    };
  });
  expect(navigationTiming.ttfb).toBeLessThan(500);      // 500ms TTFB threshold
  expect(navigationTiming.domReady).toBeLessThan(2_000); // 2s DOM ready
});
```

> Performance assertions in Playwright tests catch regressions early but are environment-dependent.
> Run with `--workers=1` and `--retries=0` for the most reproducible performance measurements.
> For proper load testing, use k6 or JMeter — Playwright is not a load testing tool. [community]

---

### `expect.toPass` for Retry-Until-Pass Blocks

Use `expect.toPass()` when you need to retry an entire multi-step async code block, not just a single assertion.

```typescript
// Retry the entire verification block until it passes (e.g., eventual consistency)
test('background job updates record eventually', async ({ page, request }) => {
  await page.goto('/jobs/trigger');
  await page.getByRole('button', { name: 'Run job' }).click();

  await expect(async () => {
    const res = await request.get('/api/records/1');
    const data = await res.json();
    expect(data.status).toBe('processed');
    expect(data.processedAt).toBeTruthy();
  }).toPass({
    timeout:   15_000,
    intervals: [500, 1_000, 2_000],
  });
});
```

---

### Mobile Emulation and Responsive Testing

Test mobile viewports and touch events without a real device using Playwright's device emulation.

```typescript
// playwright.config.ts — add mobile projects
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  projects: [
    // ... existing setup/chromium projects
    {
      name:  'mobile-chrome',
      use:   { ...devices['Pixel 7'] },
    },
    {
      name:  'mobile-safari',
      use:   { ...devices['iPhone 14 Pro'] },
    },
  ],
});
```

```typescript
// e2e/specs/responsive.spec.ts
import { test, expect, devices } from '@playwright/test';

test('navigation collapses to hamburger on mobile', async ({ page }) => {
  // Override viewport for this test only
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto('/');
  await expect(page.getByRole('navigation')).not.toBeVisible();
  await expect(page.getByLabel('Open menu')).toBeVisible();
});

test('touch scroll works on product list', async ({ page }) => {
  await page.goto('/products');
  // Simulate touch scroll
  await page.touchscreen.tap(200, 400);
});
```

---

### Clock and Time Mocking

Control `Date.now()`, `setTimeout`, and `setInterval` to test time-dependent logic without waiting.

```typescript
// Mock current date for date-dependent UI
test('shows "Today" label for current day appointments', async ({ page }) => {
  // Fix the clock before page load
  await page.clock.setFixedTime(new Date('2025-01-15T10:00:00'));
  await page.goto('/appointments');
  await expect(page.locator('[data-date="2025-01-15"]')).toContainText('Today');
});

// Fast-forward timers for polling/countdown UI
test('session timeout warning appears after 14 minutes', async ({ page }) => {
  await page.clock.install();
  await page.goto('/dashboard');
  // Fast-forward 14 minutes without waiting
  await page.clock.fastForward('14:00');
  await expect(page.getByRole('alertdialog', { name: 'Session expiring' })).toBeVisible();
});

// Pause time for stable visual snapshots
test('dashboard visual regression at fixed time', async ({ page }) => {
  await page.clock.setFixedTime(new Date('2025-06-01T12:00:00'));
  await page.goto('/dashboard');
  await expect(page).toHaveScreenshot('dashboard-noon.png');
});
```

> `page.clock` (introduced in Playwright 1.45) replaces the old `page.addInitScript` hack
> for mocking dates. It controls `Date`, `setTimeout`, `setInterval`, and `performance.now()`
> in a unified API. [community]

---

### `launchPersistentContext` and `--user-data-dir` — Session Reuse (v1.54+)

Use `launchPersistentContext` (or the `--user-data-dir` CLI flag) when you need to reuse a real browser session across multiple script runs — for example, to avoid re-authenticating manually during development, or to replay a real user's session state.

```typescript
// scripts/explore-with-auth.ts — reuse an existing logged-in profile
import { chromium } from 'playwright';

// Profile dir persists cookies, localStorage, extension state across launches
const context = await chromium.launchPersistentContext('./browser-profile', {
  headless: false,
  viewport:  null,              // use real screen size
});

const page = await context.newPage();
await page.goto('https://your-app.com/dashboard');
// Already logged in from previous session — no login step needed

// Save current state for use in Playwright tests
await context.storageState({ path: 'e2e/.auth/dev-session.json' });
await context.close();
```

```bash
# CLI: open a persistent browser session for manual exploration + auth capture
npx playwright open --user-data-dir ./browser-profile https://your-app.com/login

# After logging in manually, export the session for use in tests:
# (save storageState via page.context().storageState(...) in a script)
```

> `launchPersistentContext` is a **developer workflow tool**, not a test pattern. Never use it in CI — it couples tests to a local user profile that may expire or accumulate state. Use `storageState` files captured via `auth.setup.ts` for test auth. [community]

---

### Geolocation and Permissions

Mock geolocation and browser permissions to test location-aware features.

```typescript
// Grant geolocation permission and set position
test('shows nearby stores on map', async ({ browser }) => {
  const context = await browser.newContext({
    geolocation: { latitude: 40.7128, longitude: -74.0060 }, // New York
    permissions:  ['geolocation'],
  });
  const page = await context.newPage();
  await page.goto('/stores/nearby');
  await expect(page.getByText('5 stores near you')).toBeVisible();
  await context.close();
});

// Test denied permission fallback
test('shows manual location entry when permission denied', async ({ browser }) => {
  const context = await browser.newContext({
    permissions: [],   // deny all permissions
  });
  const page = await context.newPage();
  await page.goto('/stores/nearby');
  await expect(page.getByLabel('Enter your location manually')).toBeVisible();
  await context.close();
});
```

---

### Test Attachments and `testInfo` for Debugging

Attach custom artifacts (screenshots, API responses, logs) to test results for richer debugging in the HTML report.

```typescript
import { test, expect } from '@playwright/test';

test('validates complex form submission', async ({ page }, testInfo) => {
  await page.goto('/complex-form');

  // Take a screenshot at a specific step and attach it
  const screenshot = await page.screenshot();
  await testInfo.attach('form-before-submit', {
    body:      screenshot,
    contentType: 'image/png',
  });

  // Attach API response as a JSON artifact
  const response = await page.request.get('/api/form/schema');
  await testInfo.attach('form-schema', {
    body:        await response.text(),
    contentType: 'application/json',
  });

  await page.getByRole('button', { name: 'Submit' }).click();
  await expect(page.getByRole('alert', { name: /success/i })).toBeVisible();
});

// Auto-attach console logs for failing tests using a fixture
// e2e/fixtures/logging.ts
import { test as base } from '@playwright/test';

export const test = base.extend({
  page: async ({ page }, use, testInfo) => {
    const logs: string[] = [];
    page.on('console', msg => logs.push(`[${msg.type()}] ${msg.text()}`));
    page.on('pageerror', err => logs.push(`[error] ${err.message}`));

    await use(page);

    if (testInfo.status !== testInfo.expectedStatus) {
      await testInfo.attach('console-logs', {
        body:        logs.join('\n'),
        contentType: 'text/plain',
      });
    }
  },
});
```

> Attaching console logs only on failure (via `testInfo.status !== testInfo.expectedStatus`)
> keeps passing test reports clean while providing full context for failures. [community]

---

### Debug Workflow: `PWDEBUG`, Inspector, and `--ui` Mode

Playwright provides three distinct debugging modes. Knowing when to use each saves significant investigation time.

```bash
# 1. Playwright Inspector — step through actions, generate locators
PWDEBUG=1 npx playwright test e2e/specs/auth.spec.ts

# 2. VS Code extension — breakpoints, watch expressions, live locator picker
# Install "Playwright Test for VS Code" extension, then use the sidebar

# 3. UI Mode — interactive test runner with time-travel debugging
npx playwright test --ui

# 4. Headed mode — see the browser without full debug overhead
npx playwright test --headed

# 5. Trace viewer — replay recorded trace from CI failure
npx playwright show-trace test-results/auth-chromium/trace.zip

# 6. Debug CLI mode — agent-friendly, attaches to existing session (v1.59+)
npx playwright test --debug=cli

# 7. Trace CLI — explore trace programmatically without opening the UI (v1.59+)
npx playwright trace actions ./trace.zip       # list all actions
npx playwright trace action 5 ./trace.zip      # details for action #5
npx playwright trace snapshot 5 ./trace.zip    # before/after state for action #5
```

**Interactive locator picker (v1.59+):**

```typescript
// In a test — enter hover mode to visually pick a locator, then continue
test('explore locators interactively', async ({ page }) => {
  await page.goto('/dashboard');
  // Opens an interactive element picker in headed mode
  const locator = await page.pickLocator();
  console.log(locator);  // prints the best-practice locator for the clicked element
  await page.cancelPickLocator();  // exit picker mode
});
```

> `page.pickLocator()` is a development tool — never commit tests that call it.
> Add it to your ESLint config alongside `page.pause()` in `no-restricted-syntax`. [community]

**Pause mid-test for inspection:**

```typescript
test('investigate this failure', async ({ page }) => {
  await page.goto('/dashboard');
  await page.pause(); // opens Playwright Inspector at this point
  // ... continue manually from the inspector
});
```

> `page.pause()` opens the Playwright Inspector mid-test. Never commit code containing
> `page.pause()` — add it to your ESLint `no-restricted-syntax` rule. [community]

---

### TypeScript Configuration for E2E Tests

Isolate the test TypeScript configuration from the app build to allow test-specific compiler options.

```jsonc
// e2e/tsconfig.json — separate config for test code
{
  "compilerOptions": {
    "target":         "ESNext",
    "module":         "commonjs",
    "moduleResolution": "node",
    "strict":         true,
    "esModuleInterop": true,
    "skipLibCheck":   true,
    "baseUrl":        ".",
    "paths": {
      "@fixtures/*": ["fixtures/*"],
      "@pages/*":    ["pages/*"]
    }
  },
  "include": ["./**/*.ts"],
  "exclude": ["node_modules"]
}
```

```typescript
// playwright.config.ts — reference e2e tsconfig
import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './e2e',
  // Playwright uses ts-node under the hood — no extra config needed
  // but you can explicitly point to tsconfig:
  // tsconfig: './e2e/tsconfig.json',  // Playwright 1.46+
});
```

**ESLint for Playwright tests (`eslint-plugin-playwright`):**

```jsonc
// .eslintrc for e2e/ — prevent common Playwright anti-patterns
{
  "plugins": ["playwright"],
  "rules": {
    "playwright/no-wait-for-timeout":         "error",   // forbid waitForTimeout
    "playwright/no-useless-await":            "error",   // flag redundant awaits
    "playwright/no-focused-test":             "error",   // forbid test.only
    "playwright/prefer-web-first-assertions": "error",   // enforce toHaveText over textContent
    "playwright/no-conditional-in-test":      "warn",    // discourage if/else in tests
    "playwright/valid-expect":                "error",   // catch unfulfilled expectations
    "playwright/no-page-pause":               "error"    // forbid committed page.pause()
  }
}
```

> A single `eslint-plugin-playwright` rule (`no-focused-test`) prevents `test.only()`
> from being merged. Enable it as `error`, not `warn`, in your CI lint step. [community]

---

### Strongly Typed Page Object Factory Pattern

Use a factory function type to create type-safe page object registries, enabling IDE autocompletion and preventing runtime typos.

```typescript
// e2e/pages/index.ts — typed page factory
import { type Page } from '@playwright/test';
import { LoginPage }     from './LoginPage';
import { DashboardPage } from './DashboardPage';
import { SettingsPage }  from './SettingsPage';

const PAGE_MAP = {
  login:     LoginPage,
  dashboard: DashboardPage,
  settings:  SettingsPage,
} as const;

type PageName = keyof typeof PAGE_MAP;
type PageInstance<T extends PageName> = InstanceType<typeof PAGE_MAP[T]>;

export function createPage<T extends PageName>(name: T, page: Page): PageInstance<T> {
  return new PAGE_MAP[name](page) as PageInstance<T>;
}

// Usage — fully typed, no 'as any' casts
const loginPage = createPage('login', page);    // type: LoginPage
const settings  = createPage('settings', page); // type: SettingsPage
```

---

### WebSocket and Real-Time Feature Testing

Test WebSocket-driven features by intercepting WebSocket connections or asserting on DOM updates triggered by server messages.

```typescript
// Assert on UI updates driven by WebSocket messages
test('live notification appears when server pushes message', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page.getByTestId('notification-count')).toHaveText('0');

  // Simulate a WebSocket message from the app's perspective via page.evaluate
  await page.evaluate(() => {
    const ws = (window as any).__testWebSocket;
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.dispatchEvent(new MessageEvent('message', {
        data: JSON.stringify({ type: 'notification', count: 3 })
      }));
    }
  });

  await expect(page.getByTestId('notification-count')).toHaveText('3');
});

// Mock WebSocket entirely using routeWebSocket
test('handles server disconnection gracefully', async ({ page }) => {
  await page.routeWebSocket('wss://ws.example.com/feed', ws => {
    ws.onopen = () => {
      ws.send(JSON.stringify({ type: 'connected' }));
      // Simulate disconnection after 500ms
      setTimeout(() => ws.close(), 500);
    };
  });
  await page.goto('/live-feed');
  await expect(page.getByText('Connected')).toBeVisible();
  await expect(page.getByText('Reconnecting...')).toBeVisible({ timeout: 3_000 });
});
```

> `page.routeWebSocket()` was introduced in Playwright 1.48. For earlier versions, use
> `page.addInitScript` to replace `window.WebSocket` with a mock constructor. [community]

---

### Request Context for Multi-Step API Tests

Use `request` fixture for pure API tests (no browser) within the same test suite.

```typescript
import { test, expect } from '@playwright/test';

test.describe('Users API', () => {
  let userId: number;

  test.beforeAll(async ({ request }) => {
    const res = await request.post('/api/users', {
      data: { name: 'Test User', email: `api-test-${Date.now()}@example.com` },
    });
    expect(res.ok()).toBeTruthy();
    userId = (await res.json()).id;
  });

  test('GET /api/users/:id returns user', async ({ request }) => {
    const res = await request.get(`/api/users/${userId}`);
    expect(res.status()).toBe(200);
    const data = await res.json();
    expect(data.name).toBe('Test User');
  });

  test('PATCH /api/users/:id updates name', async ({ request }) => {
    const res = await request.patch(`/api/users/${userId}`, {
      data: { name: 'Updated Name' },
    });
    expect(res.ok()).toBeTruthy();
    expect((await res.json()).name).toBe('Updated Name');
  });

  test.afterAll(async ({ request }) => {
    await request.delete(`/api/users/${userId}`);
  });
});
```

---

### HAR Recording for Offline / Reproducible Tests

Record real network traffic to a HAR file, then replay it to run tests without a live backend. Ideal for flaky external APIs.

```typescript
// Step 1: Record — run once to capture network traffic
test('record HAR for checkout flow', async ({ page }) => {
  await page.routeFromHAR('./e2e/hars/checkout.har', { update: true });
  await page.goto('/checkout');
  // ... interact to trigger the API calls you want to capture
});

// Step 2: Replay — use recorded HAR in all subsequent test runs
test('checkout flow (HAR replay)', async ({ page }) => {
  await page.routeFromHAR('./e2e/hars/checkout.har', {
    update: false,          // do not re-record
    notFound: 'fallthrough', // allow unmatched requests to pass through
  });
  await page.goto('/checkout');
  await expect(page.getByText('Order confirmed')).toBeVisible();
});
```

> HAR replay is brittle when the app uses short-lived tokens in URLs or headers.
> Edit `checkout.har` manually to replace token placeholders, or use `route.continue()`
> to inject fresh tokens for matched routes. [community]

---

### Network Response Caching with `playwright-network-cache` [community]

For large suites with slow or flaky external APIs, the `playwright-network-cache` library caches actual API responses to the filesystem on first run and replays them on subsequent runs. Unlike HAR, responses are stored as human-readable JSON files that are easy to inspect and modify.

```bash
npm install --save-dev playwright-network-cache
```

```typescript
// e2e/fixtures/cache.ts — shared network cache fixture
import { test as base } from '@playwright/test';
import { CacheRoute }   from 'playwright-network-cache';

type CacheFixtures = { cacheRoute: CacheRoute };

export const test = base.extend<CacheFixtures>({
  cacheRoute: async ({ page }, use) => {
    const cacheRoute = new CacheRoute(page, {
      // Cache directory: .network-cache/<host>/<path>/<method>/
      cacheDir:   '.network-cache',
      // Re-record if cache is older than 7 days
      ttl:        7 * 24 * 60 * 60,
    });
    await use(cacheRoute);
  },
});

// e2e/specs/catalog.spec.ts — use cache for slow product catalog API
import { test, expect } from '../fixtures/cache';

test('product list renders', async ({ page, cacheRoute }) => {
  // First run: real request is made and response saved to disk
  // Subsequent runs: cached response is returned instantly
  await cacheRoute.GET('https://api.example.com/products*');

  await page.goto('/products');
  await expect(page.getByRole('list', { name: 'Products' })).toBeVisible();
});

// Modify cached response per-test (e.g., inject a specific product state)
test('shows out-of-stock label', async ({ page, cacheRoute }) => {
  await cacheRoute.GET('https://api.example.com/products*', {
    modifyJSON: (body) => {
      body.items[0].inStock = false;
      return body;
    },
  });
  await page.goto('/products');
  await expect(page.getByText('Out of stock')).toBeVisible();
});
```

**Cache file structure:**
```
.network-cache/
  api.example.com/
    products/
      GET/
        headers.json    # response headers
        body.json       # response body (pretty-printed JSON)
```

> Commit `.network-cache/` to source control so CI uses the same cached responses as local dev.
> Set TTL to force re-recording periodically. For truly dynamic data (user-specific), use per-test
> `extraDir: () => test.info().testId` to isolate cache entries by test. [community]

---

### Test Suite Scaling: `{ auto: true }` Fixtures for Global Reset

At 200+ tests, global setup hooks (`beforeAll`, `globalSetup`) become fragile — they run once but workers restart. Use `{ auto: true }` worker-scoped fixtures for automatic, idempotent setup that runs once per worker process regardless of test count or ordering.

```typescript
// e2e/fixtures/db-reset.ts — auto-reset DB state before each test worker starts
import { test as base } from '@playwright/test';

export const test = base.extend<{}, { dbSeed: void }>({
  dbSeed: [async ({ request }, use, workerInfo) => {
    // Auto-seeding: runs once per worker without being declared in any test
    const res = await request.post('/api/test/seed', {
      data: { workerIndex: workerInfo.workerIndex, scenario: 'base' },
    });
    if (!res.ok()) {
      console.warn(`[worker ${workerInfo.workerIndex}] DB seed failed: ${res.status()}`);
    }
    await use();  // all tests in this worker now run against seeded state
    // Cleanup after all tests in this worker complete
    await request.delete('/api/test/cleanup', {
      data: { workerIndex: workerInfo.workerIndex },
    });
  }, { scope: 'worker', auto: true }],  // runs for every test without explicit request
});
```

**Auto-fixture for console error monitoring:**

```typescript
// e2e/fixtures/console-monitor.ts — fail tests that produce console errors (auto-enabled)
export const test = base.extend({
  page: [async ({ page }, use, testInfo) => {
    const consoleErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') consoleErrors.push(msg.text());
    });

    await use(page);

    // After test completes, fail if any unexpected console errors appeared
    if (testInfo.status === 'passed' && consoleErrors.length > 0) {
      // Attach as annotation so it's visible in report without failing
      await testInfo.attach('console-errors', {
        body: consoleErrors.join('\n'), contentType: 'text/plain',
      });
    }
  }, { scope: 'test', auto: true }],  // every test gets console monitoring
});
```

> At 200+ tests, `{ auto: true }` fixtures for DB reset and console monitoring prevent entire
> categories of intermittent failures without touching individual test files. They apply
> silently to every test that imports from the merged fixture module. [community]

---

### Advanced Interaction Patterns


**File uploads:**
```typescript
// Single file
await page.getByLabel('Upload avatar').setInputFiles('./e2e/fixtures/avatar.png');

// Multiple files
await page.getByLabel('Upload files').setInputFiles([
  './e2e/fixtures/doc1.pdf',
  './e2e/fixtures/doc2.pdf',
]);

// Remove selected file
await page.getByLabel('Upload avatar').setInputFiles([]);
```

**File downloads:**
```typescript
// Start waiting before the click — prevents race condition
const downloadPromise = page.waitForEvent('download');
await page.getByRole('button', { name: 'Export CSV' }).click();
const download = await downloadPromise;
await download.saveAs(`./test-results/${download.suggestedFilename()}`);
expect(download.suggestedFilename()).toMatch(/\.csv$/);
```

**Dialog handling:**
```typescript
// Handle alert/confirm/prompt — register handler BEFORE triggering
page.once('dialog', dialog => dialog.accept());
await page.getByRole('button', { name: 'Delete account' }).click();

// Dismiss beforeunload dialog on page close
page.on('dialog', async dialog => {
  if (dialog.type() === 'beforeunload') await dialog.dismiss();
});
await page.close({ runBeforeUnload: true });
```

**New tab / popup handling:**
```typescript
// Wait for popup before clicking the link that opens it
const popupPromise = page.waitForEvent('popup');
await page.getByRole('link', { name: 'Open in new tab' }).click();
const popup = await popupPromise;
await popup.waitForLoadState();
await expect(popup).toHaveURL(/terms/);
```

**Iframe interaction:**
```typescript
// Access frame by name or URL
const frame = page.frameLocator('#payment-iframe');
await frame.getByLabel('Card number').fill('4111111111111111');
await frame.getByRole('button', { name: 'Pay' }).click();
```

> Register dialog handlers with `page.once()` for one-shot dialogs and `page.on()` for recurring
> dialogs. Never register both — duplicate handlers cause double-accept/dismiss bugs. [community]

---

### Aria Snapshot Assertions (v1.49+)

`toMatchAriaSnapshot()` captures the ARIA accessibility tree as a YAML snapshot and asserts structural accessibility — distinct from visual snapshots. It verifies semantic structure, not rendering.

```typescript
// e2e/specs/aria.spec.ts
import { test, expect } from '@playwright/test';

test('navigation has expected aria structure', async ({ page }) => {
  await page.goto('/');
  // Assert the accessible tree structure
  await expect(page.getByRole('navigation')).toMatchAriaSnapshot(`
    - navigation:
      - list:
        - listitem: Home
        - listitem: Products
        - listitem: About
  `);
});

test('form fields have correct labels and states', async ({ page }) => {
  await page.goto('/signup');
  await page.getByRole('button', { name: 'Create account' }).click();
  // Verify error states are reflected in the accessibility tree
  await expect(page.getByRole('form')).toMatchAriaSnapshot(`
    - form:
      - textbox /email/i [required]
      - textbox /password/i [required]
      - alert: Email is required
  `);
});

// Store snapshots in external .aria.yml files (v1.50+)
test('homepage navigation aria snapshot', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('main')).toMatchAriaSnapshot({
    path: 'e2e/snapshots/homepage-main.aria.yml',
  });
});
```

**`locator.ariaSnapshot()` with depth/mode options (v1.59+):**

`locator.ariaSnapshot()` returns the raw ARIA tree string — useful for debugging what `toMatchAriaSnapshot()` actually captures before writing a snapshot.

```typescript
// Inspect the raw ARIA tree during test development
test('inspect aria tree of navigation', async ({ page }) => {
  await page.goto('/');
  // Get ARIA tree as a string for debugging — no assertion
  const ariaTree = await page.getByRole('navigation').ariaSnapshot();
  console.log(ariaTree);

  // depth option: limit how many levels deep to capture (default: full depth)
  const shallowTree = await page.getByRole('navigation').ariaSnapshot({ depth: 2 });

  // mode option: 'normalizeWhitespace' (default) | 'raw' for exact whitespace
  const rawTree = await page.getByRole('navigation').ariaSnapshot({ mode: 'raw' });

  // mode: 'ai' — produces a compact, AI-optimized representation (v1.59+)
  // Best for feeding to LLMs for diagnostics or auto-healing workflows
  const aiTree = await page.getByRole('navigation').ariaSnapshot({ mode: 'ai' });
  console.log(aiTree); // JSON-ish compact format optimized for LLM prompts
});

// page.ariaSnapshot() — capture the full page accessibility tree (v1.59+)
test('full page aria snapshot for AI debugging', async ({ page }) => {
  await page.goto('/dashboard');
  // Captures the entire page ARIA tree — useful for LLM-assisted test healing
  const fullTree = await page.ariaSnapshot({ mode: 'ai' });
  // Use in an AI prompt: "Given this page structure, what locator should I use?"
  console.log(fullTree);
});
```

> Use `locator.ariaSnapshot()` during test development to discover the correct snapshot string before writing `toMatchAriaSnapshot()`. The returned string can be pasted directly into the test. [community]

> `toMatchAriaSnapshot()` tests fail intentionally when ARIA roles or labels change — making accessibility regressions explicit rather than invisible. Use `--update-snapshots` to regenerate after intentional changes. [community]

---

### Locator `describe()` for Trace Readability (v1.52+)

Annotate locators with human-readable descriptions that appear in traces, reports, and error messages. Essential for debugging complex POM setups where generated locators are cryptic.

```typescript
// Without describe(): "locator('.data-table').filter(has=locator('[data-status="active"]'))"
// With describe(): "Active users table"

const activeUserTable = page
  .locator('.data-table')
  .filter({ has: page.locator('[data-status="active"]') })
  .describe('Active users table');

await expect(activeUserTable).toBeVisible();
await activeUserTable.getByRole('button', { name: 'Edit' }).first().click();

// In a Page Object — annotate complex locators at definition
export class UserManagementPage {
  readonly activeUsersTable: Locator;
  readonly inactiveUsersTable: Locator;

  constructor(page: Page) {
    this.activeUsersTable = page
      .locator('[data-grid]')
      .filter({ has: page.locator('[data-status="active"]') })
      .describe('Active users grid');
    this.inactiveUsersTable = page
      .locator('[data-grid]')
      .filter({ has: page.locator('[data-status="inactive"]') })
      .describe('Inactive users grid');
  }
}
```

---

### `expect.configure()` for Scoped Timeouts and Soft Mode (v1.38+)

Create configured `expect` instances instead of passing options to every assertion. Useful for slow pages, performance assertions, and section-wide soft validation.

```typescript
// e2e/specs/dashboard.spec.ts
import { test, expect } from '@playwright/test';

test('dashboard loads within acceptable time', async ({ page }) => {
  // Slow expect for pages with expensive data fetching
  const slowExpect = expect.configure({ timeout: 15_000 });

  await page.goto('/dashboard');
  await slowExpect(page.getByRole('main')).toBeVisible();
  await slowExpect(page.getByTestId('metrics-chart')).toBeVisible();
});

test('validate all form field errors at once', async ({ page }) => {
  // Soft mode for a section — collect all failures
  const softExpect = expect.configure({ soft: true });

  await page.goto('/checkout');
  await page.getByRole('button', { name: 'Place order' }).click();

  await softExpect(page.getByTestId('name-error')).toHaveText('Name is required');
  await softExpect(page.getByTestId('email-error')).toHaveText('Email is required');
  await softExpect(page.getByTestId('card-error')).toHaveText('Card number is required');

  // Verify all soft assertions passed
  expect(test.info().errors).toHaveLength(0);
});
```

> `expect.configure({ soft: true })` is cleaner than calling `expect.soft()` on every line.
> Use it to soft-assert a whole block, then check `test.info().errors` at the end. [community]

---

### New Assertions: `toContainClass` and `toHaveAccessibleErrorMessage` (v1.52+)

```typescript
// toContainClass — assert individual class names without full-class matching
test('active nav item has active class', async ({ page }) => {
  await page.goto('/products');
  const productsLink = page.getByRole('link', { name: 'Products' });
  // Unlike toHaveClass(), toContainClass checks for presence of a single class
  await expect(productsLink).toContainClass('active');
  await expect(productsLink).not.toContainClass('disabled');
});

// toHaveAccessibleErrorMessage — validates aria-errormessage attribute
test('invalid form field has accessible error message', async ({ page }) => {
  await page.goto('/signup');
  await page.getByRole('button', { name: 'Submit' }).click();
  const emailInput = page.getByLabel('Email');
  await expect(emailInput).toHaveAccessibleErrorMessage('Please enter a valid email');
});
```

---

### `testConfig.failOnFlakyTests` — Zero Flake Tolerance (v1.52+)

Configure the test run to fail if any test passes on retry (indicating flakiness) rather than silently treating retries as normal.

```typescript
// playwright.config.ts — production hardening
export default defineConfig({
  retries:            process.env.CI ? 2 : 0,
  // Fail the run if any test required a retry to pass — surfaces flakiness
  failOnFlakyTests:   !!process.env.CI && !!process.env.STRICT_FLAKE_MODE,
});
```

```bash
# Enable strict flake detection on nightly runs
STRICT_FLAKE_MODE=1 npx playwright test
```

> `failOnFlakyTests` is most valuable on nightly regression runs, not every PR check.
> On PRs, silent retries are acceptable — but in a nightly run, a pass-on-retry is
> a signal that needs investigation before it becomes a hard failure. [community]

---

### Per-Project Worker Configuration (v1.52+)

Override the global `workers` count per project. Critical when one project (e.g., visual regression) needs serialized runs while another (e.g., API tests) can run maximally parallel.

```typescript
// playwright.config.ts
export default defineConfig({
  workers: process.env.CI ? 4 : undefined,  // global default
  projects: [
    {
      name: 'api-tests',
      testMatch: /api\/.*.spec.ts/,
      workers: 8,  // API tests are fast; more parallelism is fine
    },
    {
      name: 'visual',
      testMatch: /visual\/.*.spec.ts/,
      workers: 1,  // Visual tests must be serialized for consistent rendering
    },
    {
      name: 'chromium',
      testMatch: /specs\/.*.spec.ts/,
      // inherits global workers (4 in CI)
    },
  ],
});
```

---

### `browserContext.setStorageState()` — Reset Auth Without New Context (v1.59+)

Reset all storage state (cookies, localStorage, sessionStorage, IndexedDB) within an existing context — useful for multi-user scenarios within a single test.

```typescript
// e2e/specs/admin.spec.ts
import { test, expect } from '@playwright/test';
import path from 'path';

const adminAuth  = path.join(__dirname, '../.auth/admin.json');
const viewerAuth = path.join(__dirname, '../.auth/viewer.json');

test('admin can edit but viewer cannot', async ({ browser }) => {
  const context = await browser.newContext({ storageState: adminAuth });
  const page = await context.newPage();

  // Test as admin
  await page.goto('/settings');
  await expect(page.getByRole('button', { name: 'Delete account' })).toBeVisible();

  // Switch to viewer — reset storage in the SAME context (no new browser spawn)
  await context.setStorageState({ path: viewerAuth });
  await page.reload();

  // Test as viewer
  await expect(page.getByRole('button', { name: 'Delete account' })).toBeHidden();
  await context.close();
});
```

> `setStorageState()` is significantly faster than creating a new `browserContext` for
> role-switching tests. Use it when testing permission differences between roles
> without the overhead of spinning up a fresh browser context. [community]

---

### IndexedDB in `storageState` (v1.51+)

Persist and restore IndexedDB contents alongside cookies and localStorage. Critical for apps that use IndexedDB for auth tokens, offline state, or feature flags.

```typescript
// e2e/auth.setup.ts — save IndexedDB as part of auth state
setup('authenticate with IndexedDB app', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.E2E_USER_EMAIL!);
  await page.getByLabel('Password').fill(process.env.E2E_USER_PASSWORD!);
  await page.getByRole('button', { name: 'Sign in' }).click();
  await expect(page).not.toHaveURL(/login/);

  // Save state including IndexedDB (e.g., service worker tokens, offline cache)
  await page.context().storageState({
    path:       'e2e/.auth/user.json',
    indexedDB:  true,  // include IndexedDB contents in the saved state
  });
});
```

---

### `captureGitInfo` for Trace Reports (v1.51+)

Capture git commit metadata (branch, commit SHA, diff) in HTML reports for traceability between test failures and code changes.

```typescript
// playwright.config.ts
export default defineConfig({
  captureGitInfo: { commit: true, diff: true },
  reporter:       process.env.CI ? [['blob'], ['junit', { outputFile: 'results.xml' }]] : 'html',
});
```

The HTML report then shows which commit introduced the failure — click "Copy prompt" to pre-fill an LLM with the failing test context. [community]

---

### Async Disposables for Automatic Cleanup (v1.59+)

Use `await using` (TypeScript 5.2+) to ensure automatic cleanup of pages, routes, and scripts — even if a test throws.

```typescript
test('route cleanup with async disposables', async ({ context }) => {
  await using page = await context.newPage();  // auto-closes page on exit

  {
    // Route is automatically removed when this block exits
    await using route = await page.route('**/api/slow', async r => {
      await new Promise(res => setTimeout(res, 100));
      await r.continue();
    });

    await using script = await page.addInitScript(() => {
      (window as any).__testMode = true;
    });

    await page.goto('/dashboard');
    await expect(page.getByTestId('dashboard-loaded')).toBeVisible();
  }
  // route and script are cleaned up here; page is still open

  await page.goto('/profile');  // route no longer intercepts
});
```

> `await using` requires TypeScript 5.2+ and `"target": "ES2022"` or later in `tsconfig.json`.
> It eliminates the need for `test.afterEach()` cleanup of routes and scripts — they
> are disposed at block exit, even on exception. [community]

---

### `--only-changed` for Fast Developer Feedback (v1.46+)

Run only test files that have changed since the last git commit. Ideal for rapid local iteration without running the full suite.

```bash
# Run only tests in files modified since HEAD
npx playwright test --only-changed

# Compare against a specific branch (e.g., before merging)
npx playwright test --only-changed=main

# Combine with a project for fast PR checks
npx playwright test --only-changed=origin/main --project=chromium
```

> `--only-changed` uses `git diff` to find modified files. It only detects changes in
> test files themselves — not in Page Objects or fixtures they import. If a POM file
> changes, run the full suite. [community]

---

### Step-Level Control: `test.step.skip()` and Step Timeouts (v1.50+)

Control individual step execution and timeouts for granular test management.

```typescript
test('checkout flow with conditional steps', async ({ page }) => {
  await test.step('navigate to checkout', async () => {
    await page.goto('/checkout');
  });

  await test.step('apply promo code', async (step) => {
    // Skip this step if feature flag is off — without failing the test
    if (!process.env.PROMO_ENABLED) {
      step.skip();
      return;
    }
    await page.getByLabel('Promo code').fill('SAVE20');
    await page.getByRole('button', { name: 'Apply' }).click();
  });

  // Step with explicit timeout (overrides test-level timeout for slow operations)
  await test.step('wait for payment processor', { timeout: 45_000 }, async () => {
    await expect(page.getByText('Payment confirmed')).toBeVisible({ timeout: 45_000 });
  });
});
```

---

### `updateSnapshots: 'changed'` — Surgical Snapshot Updates (v1.50+)

Update only snapshots that actually differ instead of regenerating all of them. Prevents accidentally overwriting stable baselines when fixing one component.

```typescript
// playwright.config.ts
export default defineConfig({
  expect: {
    toHaveScreenshot: {
      maxDiffPixels: 100,
      stylePath:     './e2e/screenshot.css',
    },
  },
  // Only update snapshots that have changed, not all snapshots
  updateSnapshots: 'changed',
});
```

```bash
# Update only failing/changed snapshots (safe — won't touch stable ones)
npx playwright test --update-snapshots=changed

# Legacy behavior (updates ALL snapshots, including passing ones) — use rarely
npx playwright test --update-snapshots
```

> `updateSnapshots: 'changed'` prevents a common mistake where `--update-snapshots` is
> run after fixing one component but accidentally regenerates baselines for unrelated
> components that have rendering drift. [community]

---

### Shadow DOM Traversal

Playwright locators pierce Shadow DOM by default — no special API is needed for open shadow roots. XPath does NOT pierce shadow roots; only CSS and role-based locators work.

```typescript
// Transparent traversal — locates element inside <x-card>'s shadow root automatically
test('shadow DOM component interaction', async ({ page }) => {
  await page.goto('/components');

  // Role-based locator works transparently through shadow root
  await page.getByRole('button', { name: 'Expand details' }).click();

  // Text-based locator also pierces shadow DOM
  await expect(page.getByText('Shadow content loaded')).toBeVisible();

  // Scope to the custom element host, then target inside
  const card = page.locator('x-card', { hasText: 'Product A' });
  await card.getByRole('button', { name: 'Add to cart' }).click();
  await expect(card).toContainText('Added');
});

// frameLocator for embedded iframes within shadow components
test('payment iframe within shadow component', async ({ page }) => {
  await page.goto('/checkout');
  // First pierce to the shadow host, then access the iframe inside
  const shadowHost = page.locator('payment-widget');
  const paymentFrame = shadowHost.frameLocator('iframe[title="Payment"]');
  await paymentFrame.getByLabel('Card number').fill('4111111111111111');
  await paymentFrame.getByLabel('Expiry').fill('12/26');
  await paymentFrame.getByRole('button', { name: 'Pay' }).click();
});
```

**Shadow DOM caveats:**
- Open shadow roots: fully supported via all locator methods
- Closed shadow roots: not supported — use `page.evaluate()` if unavoidable
- XPath (`page.locator('xpath=...')`) does NOT pierce shadow roots — use CSS or role locators
- `::slotted()` CSS pseudo-elements may require `page.locator('css=...')` for slot content

> If your app uses closed shadow roots, the component is intentionally hiding its internals.
> Test through the public API (events, attributes, methods) rather than piercing the shadow. [community]

---

### `testConfig.tag` for Run-Level Metadata (v1.57+)

Tag entire test runs with environment or deployment context. The tag appears in HTML reports and helps differentiate CI environments in aggregated dashboards.

```typescript
// playwright.config.ts — tag the entire run for the current environment
export default defineConfig({
  tag: process.env.CI_ENVIRONMENT_NAME ?? 'local',  // e.g., '@staging', '@prod-smoke'
  // All tests in this run will appear under this tag in the HTML report
});
```

```bash
# Override at runtime for ad-hoc tagging
TEST_ENV=staging npx playwright test

# In CI: tag differs by job type
- name: Smoke tests
  env:
    CI_ENVIRONMENT_NAME: '@smoke-staging'
  run: npx playwright test --grep @smoke

- name: Full regression
  env:
    CI_ENVIRONMENT_NAME: '@regression-staging'
  run: npx playwright test
```

---

### `testConfig.tsconfig` — Single TypeScript Config for All Tests (v1.49+)

By default Playwright looks up `tsconfig.json` separately for each imported test file. This can cause inconsistencies. Pin a single tsconfig:

```typescript
// playwright.config.ts
export default defineConfig({
  tsconfig: './e2e/tsconfig.json',  // single tsconfig for all test files
  testDir:  './e2e',
});
```

```jsonc
// e2e/tsconfig.json — test-specific TypeScript settings
{
  "compilerOptions": {
    "target":           "ES2022",          // required for await using (async disposables)
    "module":           "commonjs",
    "moduleResolution": "node",
    "strict":           true,
    "esModuleInterop":  true,
    "skipLibCheck":     true,
    "baseUrl":          ".",
    "paths": {
      "@fixtures/*": ["fixtures/*"],
      "@pages/*":    ["pages/*"]
    }
  },
  "include": ["./**/*.ts"],
  "exclude": ["node_modules"]
}
```

> Set `"target": "ES2022"` (not `"ES2020"`) to enable the `await using` async disposables
> syntax introduced in Playwright v1.59. Earlier targets cause a compile error. [community]

---

### Component Testing (Experimental CT)

Test individual React/Vue/Svelte components in a real browser without a full app server. Uses `@playwright/experimental-ct-react` (or `-vue`, `-svelte`).

```bash
# Initialize component testing
npm init playwright@latest -- --ct
```

```typescript
// playwright-ct.config.ts — separate config for component tests
import { defineConfig } from '@playwright/experimental-ct-react';

export default defineConfig({
  testDir:  './src',
  testMatch: '**/*.ct.spec.ts',
  use: {
    ctPort:    3100,
    ctViteConfig: {
      // Vite config for the component sandbox
    },
  },
});
```

```typescript
// src/components/Button.ct.spec.ts
import { test, expect } from '@playwright/experimental-ct-react';
import { Button } from './Button';

test('renders with correct label', async ({ mount }) => {
  const component = await mount(<Button label="Submit" />);
  await expect(component).toContainText('Submit');
  await expect(component).toBeEnabled();
});

test('fires onClick when clicked', async ({ mount }) => {
  let clicked = false;
  const component = await mount(
    <Button label="Submit" onClick={() => { clicked = true; }} />
  );
  await component.click();
  expect(clicked).toBeTruthy();
});

test('shows loading state', async ({ mount }) => {
  const component = await mount(<Button label="Submit" loading />);
  await expect(component.getByRole('progressbar')).toBeVisible();
  await expect(component).toBeDisabled();
});
```

**MSW `router` fixture for component-level network mocking (v1.46+):**

```typescript
// playwright/index.tsx — configure global providers
import { beforeMount } from '@playwright/experimental-ct-react/hooks';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

export type HooksConfig = { enableRouting?: boolean; };

beforeMount<HooksConfig>(async ({ App, hooksConfig }) => {
  const queryClient = new QueryClient();
  if (hooksConfig?.enableRouting) {
    return (
      <QueryClientProvider client={queryClient}>
        <BrowserRouter><App /></BrowserRouter>
      </QueryClientProvider>
    );
  }
  return <QueryClientProvider client={queryClient}><App /></QueryClientProvider>;
});

// src/components/UserProfile.ct.spec.ts — use router fixture for API mocking
import { test, expect }  from '@playwright/experimental-ct-react';
import { http, HttpResponse } from 'msw';
import { UserProfile }   from './UserProfile';

test('displays user name from API', async ({ mount, router }) => {
  await router.use(
    http.get('/api/users/1', () =>
      HttpResponse.json({ id: 1, name: 'Alice Smith', role: 'admin' })
    )
  );
  const component = await mount(<UserProfile userId={1} />);
  await expect(component.getByRole('heading', { name: 'Alice Smith' })).toBeVisible();
  await expect(component.getByText('admin')).toBeVisible();
});

test('shows error state on API failure', async ({ mount, router }) => {
  await router.use(
    http.get('/api/users/1', () => HttpResponse.error())
  );
  const component = await mount(<UserProfile userId={1} />);
  await expect(component.getByRole('alert')).toContainText('Failed to load user');
});
```

**Component testing constraints:**
- Cannot pass complex live objects (e.g., class instances, functions with closures) as props — use plain data and callbacks
- Component tests run in a sandboxed Vite/Webpack server, not your app's dev server
- Use `hooksConfig` to pass routing/provider configuration per-test without mounting wrapper components in every spec

> Run component tests in a separate CI job from e2e tests — they use a different test
> runner config (`playwright-ct.config.ts`) and different browser binary. Mixing them
> in one `playwright.config.ts` causes confusing failures. [community]

---

### `page.addLocatorHandler()` — Auto-Dismiss Overlays

Automatically handle unpredictable overlays (cookie banners, newsletter popups, GDPR notices, chat widgets) that appear at random points and block your test actions. The handler fires before every Playwright actionability check whenever the locator becomes visible.

```typescript
// e2e/fixtures/overlays.ts — global overlay handler fixture
import { test as base } from '@playwright/test';

export const test = base.extend({
  page: async ({ page }, use) => {
    // Auto-dismiss cookie consent banner if it appears at any point
    await page.addLocatorHandler(
      page.getByRole('dialog', { name: /cookie|consent/i }),
      async () => {
        await page.getByRole('button', { name: /accept|agree|got it/i }).click();
      }
    );

    // Auto-dismiss newsletter popup (run at most twice — dismiss, then ignore)
    await page.addLocatorHandler(
      page.getByText('Sign up to the newsletter'),
      async () => {
        await page.getByRole('button', { name: 'No thanks' }).click();
      },
      { times: 1 }  // only handle once; subsequent appearances are ignored
    );

    await use(page);
  },
});
```

```typescript
// Inline: dismiss a specific overlay before an action
await page.addLocatorHandler(
  page.locator('[data-testid="promo-modal"]'),
  async () => {
    await page.locator('[aria-label="Close modal"]').click();
  },
  { noWaitAfter: true }  // don't wait for overlay to hide after clicking
);

await page.getByRole('button', { name: 'Checkout' }).click();
// ↑ If promo-modal blocks Checkout, the handler fires first
```

**Rules for locator handlers:**
- Handlers fire *before every actionability check* — they may run multiple times per test.
- Actions inside handlers should be self-contained. Avoid relying on page focus or mouse position state left over from the handler, as it alters the page mid-action.
- Use `{ times: N }` to limit handler invocations. `times: 1` + `noWaitAfter: true` is common for one-shot banners.
- Handlers do not run recursively — a handler that triggers another overlay will not re-enter itself.
- Remove a specific handler with `page.removeLocatorHandler(locator)`.

> `addLocatorHandler` is the idiomatic replacement for fragile `try/catch` click patterns that used to wrap every test action to handle intermittent modals. [community]

---

### Post-Facto Inspection: `consoleMessages()`, `pageErrors()`, `requests()` (v1.59+)

Access the recent history of console messages, page errors, and network requests without setting up event listeners in advance. Useful for post-action verification and fixture-based log capture.

```typescript
// Assert no console errors appeared during a navigation
test('homepage has no console errors', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('main')).toBeVisible();

  // Inspect accumulated console messages after navigation
  const messages = await page.consoleMessages();
  const errors = messages.filter(m => m.type() === 'error');
  expect(errors, `Console errors: ${errors.map(m => m.text()).join('\n')}`).toHaveLength(0);
});

// Assert no uncaught JS exceptions during a user flow
test('checkout flow has no JS exceptions', async ({ page }) => {
  await page.goto('/cart');
  await page.getByRole('button', { name: 'Checkout' }).click();
  await page.waitForURL(/\/checkout/);

  const pageErrors = await page.pageErrors();
  expect(pageErrors, `Uncaught errors: ${pageErrors.map(e => e.message).join('\n')}`).toHaveLength(0);
});

// Inspect requests made since last navigation (not all-time)
test('verifies analytics event was fired', async ({ page }) => {
  await page.goto('/product/123');
  await page.getByRole('button', { name: 'Add to cart' }).click();

  // Get only requests since navigation started
  const requests = await page.requests({ filter: 'since-navigation' });
  const analyticsCall = requests.find(r => r.url().includes('/analytics/event'));
  expect(analyticsCall).toBeDefined();
  expect(await analyticsCall!.postDataJSON()).toMatchObject({ event: 'add_to_cart' });
});
```

**Filtering options:**
- `filter: 'all'` (default) — returns all stored messages/errors/requests (up to 200)
- `filter: 'since-navigation'` — returns only items accumulated since the last navigation

> These APIs eliminate the need for `page.on('console', ...)` setup in every test. Pair with `page.clearConsoleMessages()` and `page.clearPageErrors()` to reset state mid-test when a single test performs multiple navigations. [community]

---

### `locator.normalize()` — Upgrade to Best-Practice Locators (v1.59+)

Convert implementation-detail locators (CSS classes, positional selectors) to best-practice equivalents (ARIA roles, test IDs, accessible names). Useful for incrementally upgrading existing test suites without a full rewrite.

```typescript
// Identify what the best-practice locator for an element is
test('demonstrate normalize', async ({ page }) => {
  await page.goto('/login');

  // A brittle CSS selector — normalize() upgrades it
  const brittle = page.locator('.login-form .submit-btn');
  const normalized = brittle.normalize();

  // normalized is now something like:
  // page.getByRole('button', { name: 'Sign in' })
  // Use it for the actual assertion
  await expect(normalized).toBeEnabled();
});
```

**Practical upgrade workflow:**

```typescript
// Step 1: During test investigation, find what normalize() produces
const improved = page.locator('.nav-link.active').normalize();
console.log(improved.toString());
// Prints: "getByRole('link', { name: 'Dashboard' })"

// Step 2: Replace the original selector in your POM/spec with the printed version
// Step 3: Delete the normalize() call — it was a discovery tool, not a runtime pattern
```

> Use `locator.normalize()` as a **refactoring tool**, not a runtime call in production tests. The point is to discover the best-practice selector, then hardcode it. Calling `normalize()` in every test adds overhead and hides the brittle selector instead of fixing it. [community]

---

### Screencast API — Precise Video Recording (v1.59+)

The `page.screencast` API provides fine-grained video recording control as an alternative to the `recordVideo` option. Unlike `recordVideo` (which records entire contexts), `page.screencast` lets you start/stop recording at specific test steps, add chapter annotations, and stream live frames.

```typescript
// Record only the failure-relevant portion of a test
test('records video for slow critical flow', async ({ page }) => {
  await page.goto('/dashboard');

  // Start recording only for the slow/critical section
  await page.screencast.start({
    path: 'test-results/checkout-flow.webm',
    size: { width: 1280, height: 720 },
  });

  await page.getByRole('link', { name: 'Shop' }).click();
  await page.getByRole('button', { name: 'Add to cart' }).click();

  // Add a chapter marker visible in the recording
  await page.screencast.showChapter('Checkout step', {
    description: 'User initiates checkout',
    duration: 2_000,
  });

  await page.getByRole('button', { name: 'Checkout' }).click();
  await page.waitForURL(/\/checkout/);

  await page.screencast.stop();  // video saved to path
});

// Stream frames for custom processing (e.g., live preview, AI vision)
test('capture frames for CI thumbnail', async ({ page }) => {
  const frames: Buffer[] = [];

  await page.screencast.start({
    onFrame: ({ data }) => frames.push(Buffer.from(data)),
    size: { width: 800, height: 600 },
    quality: 80,
  });

  await page.goto('/app');
  await page.getByRole('button', { name: 'Load report' }).click();
  await expect(page.getByRole('main')).toBeVisible();

  await page.screencast.stop();
  // Use frames[0] as a CI thumbnail or feed to an AI vision model
});
```

**Screencast vs. `recordVideo`:**
| Feature | `recordVideo` | `page.screencast` |
|---------|--------------|------------------|
| Scope | Entire context | Per-page, manually controlled |
| Start/stop control | No | Yes (start/stop anywhere in test) |
| Chapter annotations | No | Yes (`showChapter()`) |
| Visual action overlays | No | Yes (`showActions()`) |
| Live frame streaming | No | Yes (`onFrame` callback) |
| Use case | Always-on debug video | Precise demo/documentation recording |

**Enable visual action overlays in screencast (v1.59+):**

```typescript
// Show action annotations (click target highlights, fill values) in the recording
test('records with action overlay for demo', async ({ page }) => {
  await page.screencast.start({
    path: 'test-results/demo.webm',
    size: { width: 1280, height: 720 },
  });

  // Enable visual overlays showing where clicks/fills happen
  await page.screencast.showActions({
    position: 'top-right',  // overlay position: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
  });

  await page.goto('/login');
  await page.getByLabel('Email').fill('admin@example.com');
  await page.getByRole('button', { name: 'Sign in' }).click();

  await page.screencast.stop();
  // Recording shows annotated click targets and filled values — useful for demos
});
```

> `page.screencast` is most useful for recording demos, onboarding walkthroughs, and test evidence for specific steps — not as a replacement for `trace: 'on-first-retry'` for debugging. [community]

---

### Advanced Authentication: OAuth and MFA Flows [community]

OAuth and MFA flows cannot use `storageState` directly — they require alternative strategies. These patterns prevent full UI OAuth round-trips in every test.

**OAuth via API token (bypass UI login entirely):**

```typescript
// e2e/auth.setup.ts — trade OAuth code for API token directly
setup('authenticate via OAuth token exchange', async ({ request }) => {
  // Exchange a pre-issued OAuth client credentials token for a session
  const tokenRes = await request.post('https://auth.example.com/token', {
    form: {
      grant_type:    'client_credentials',
      client_id:     process.env.E2E_OAUTH_CLIENT_ID!,
      client_secret: process.env.E2E_OAUTH_CLIENT_SECRET!,
      scope:         'e2e-testing',
    },
  });
  expect(tokenRes.ok()).toBeTruthy();
  const { access_token } = await tokenRes.json();

  // Use token to get a session cookie from the app's session endpoint
  const sessionRes = await request.post('/api/auth/session', {
    headers: { Authorization: `Bearer ${access_token}` },
  });
  await request.storageState({ path: 'e2e/.auth/user.json' });
});
```

**MFA via TOTP (one-time password):**

```typescript
// Install: npm install --save-dev otpauth
import * as OTPAuth from 'otpauth';

setup('authenticate with MFA', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.E2E_MFA_EMAIL!);
  await page.getByLabel('Password').fill(process.env.E2E_MFA_PASSWORD!);
  await page.getByRole('button', { name: 'Sign in' }).click();

  // Generate current TOTP code from test account's secret
  const totp = new OTPAuth.TOTP({ secret: process.env.E2E_MFA_SECRET! });
  const otp  = totp.generate();

  await page.getByLabel('One-time code').fill(otp);
  await page.getByRole('button', { name: 'Verify' }).click();
  await expect(page).not.toHaveURL(/login|mfa/);
  await page.context().storageState({ path: 'e2e/.auth/user.json' });
});
```

**Magic link auth (email-based):**

```typescript
// For magic link flows, intercept the email delivery via API
setup('authenticate via magic link', async ({ page, request }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.E2E_EMAIL!);
  await page.getByRole('button', { name: 'Send magic link' }).click();

  // Fetch the magic link from your test email API (e.g., Mailosaur, Ethereal)
  const emailRes = await request.get(`https://mailosaur.io/api/messages/await`, {
    headers: { Authorization: `api ${process.env.MAILOSAUR_API_KEY}` },
    params: {
      server:  process.env.MAILOSAUR_SERVER!,
      timeout: 30_000,
    },
  });
  const { html } = await emailRes.json();
  // Extract magic link from email body
  const linkMatch = html.body.match(/href="(https:\/\/[^"]*magic[^"]*)"/);
  expect(linkMatch).toBeTruthy();

  await page.goto(linkMatch![1]);  // follow the magic link
  await expect(page).not.toHaveURL(/login/);
  await page.context().storageState({ path: 'e2e/.auth/user.json' });
});
```

> Never commit OAuth secrets or MFA seeds to source control. Use CI secrets (GitHub Secrets, Vault) injected as environment variables. The `E2E_MFA_SECRET` is a TOTP seed — treat it like a password. [community]

---

### Visibility-Based Locator Filtering (v1.50+)

Use `filter({ visible: true })` to target only currently-rendered elements when a locator might match both visible and hidden DOM nodes (e.g., tabs, off-screen panels, hidden duplicates).

```typescript
// Filter to only visible todo items — ignores hidden/detached ones
test('shows three visible items', async ({ page }) => {
  await page.goto('/todos');
  const visibleItems = page.getByTestId('todo-item').filter({ visible: true });
  await expect(visibleItems).toHaveCount(3);
});

// Scope interactions to only what the user can actually see
test('clicks visible Add button only', async ({ page }) => {
  await page.goto('/dashboard');
  // Many "Add" buttons in DOM — only one is visible at a time
  await page.getByRole('button', { name: 'Add' }).filter({ visible: true }).click();
  await expect(page.getByRole('dialog')).toBeVisible();
});
```

> Use `filter({ visible: true })` when your app renders duplicate elements for transitions or
> animations and only one is visible at a time. Without it, Playwright's strict mode throws
> "resolved to X elements". [community]

---

### Frame / FrameLocator Bidirectional Conversion (v1.43+)

Convert between `Locator` (iframe element handle) and `FrameLocator` (content-frame accessor) in either direction. Useful when you need to both assert on the iframe element itself and interact with its contents.

```typescript
// FrameLocator → Locator: check the iframe element's visibility
test('iframe is visible and content loads', async ({ page }) => {
  await page.goto('/embed');
  const frameLocator = page.frameLocator('iframe[title="Payment form"]');

  // owner() returns the <iframe> element as a Locator
  const iframeElement = frameLocator.owner();
  await expect(iframeElement).toBeVisible();
  await expect(iframeElement).toHaveAttribute('title', 'Payment form');

  // Then interact with content via the FrameLocator
  await frameLocator.getByLabel('Card number').fill('4111111111111111');
});

// Locator → FrameLocator: start with the element, then enter the frame
test('enters frame from locator', async ({ page }) => {
  await page.goto('/dashboard');
  const iframeLocator = page.locator('iframe[data-widget="chart"]');

  // contentFrame() converts to FrameLocator for inner interactions
  const frame = iframeLocator.contentFrame();
  await expect(frame.getByRole('img', { name: /chart/i })).toBeVisible();
  await frame.getByRole('button', { name: 'Download' }).click();
});
```

> `owner()` and `contentFrame()` eliminate the workaround of using `page.frame()` by name,
> which requires knowing the frame's `name` attribute — often absent in third-party embeds. [community]

---

### `mergeExpects()` — Compose Custom Matchers (v1.39+)

Just as `mergeTests()` composes fixture sets, `mergeExpects()` merges custom `expect` extensions from multiple modules into a single `expect` instance. Avoids re-importing matchers in every spec file.

```typescript
// e2e/fixtures/matchers/form.ts — form-specific matchers
import { expect as baseExpect, type Locator } from '@playwright/test';

export const expect = baseExpect.extend({
  async toHaveValidationError(locator: Locator, message: string) {
    const errEl = locator.locator('[data-testid="field-error"]');
    const pass = await errEl.filter({ hasText: message }).isVisible();
    return { pass, message: () => `Expected validation error "${message}"`, name: 'toHaveValidationError' };
  },
});

// e2e/fixtures/matchers/a11y.ts — accessibility matchers
import { expect as baseExpect, type Page } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

export const expect = baseExpect.extend({
  async toPassA11y(page: Page) {
    const results = await new AxeBuilder({ page }).analyze();
    const pass = results.violations.length === 0;
    return { pass, message: () => `Expected no a11y violations; got ${results.violations.length}`, name: 'toPassA11y' };
  },
});

// e2e/fixtures/index.ts — merge all matchers into one export
import { mergeTests, mergeExpects } from '@playwright/test';
import { test as pageTest }  from './pages';
import { test as apiTest }   from './api';
import { expect as formExpect }  from './matchers/form';
import { expect as a11yExpect }  from './matchers/a11y';

export const test   = mergeTests(pageTest, apiTest);
export const expect = mergeExpects(formExpect, a11yExpect);

// e2e/specs/signup.spec.ts — single import for all matchers
import { test, expect } from '../fixtures';

test('signup form validates and is accessible', async ({ page }) => {
  await page.goto('/signup');
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByTestId('email-field')).toHaveValidationError('Email is required');
  await expect(page).toPassA11y();
});
```

---

### Project `teardown` — Guaranteed Cleanup (v1.34+)

Link a cleanup project to a setup project via `teardown`. The teardown project runs after all dependent projects complete — even if tests fail — ensuring seeded data is always removed and external state is always cleaned up.

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  projects: [
    {
      name:     'setup',
      testMatch: /global\.setup\.ts/,
      teardown: 'teardown',       // link the cleanup project
    },
    {
      name:     'teardown',
      testMatch: /global\.teardown\.ts/,
    },
    {
      name:         'chromium',
      use:          { ...devices['Desktop Chrome'] },
      dependencies: ['setup'],    // waits for setup; teardown runs after chromium
    },
  ],
});

// e2e/global.setup.ts
import { test as setup, expect } from '@playwright/test';

setup('create test tenant', async ({ request }) => {
  const res = await request.post('/api/test/tenants', {
    data: { name: 'e2e-tenant', tier: 'pro' },
  });
  expect(res.ok()).toBeTruthy();
  const { id } = await res.json();
  process.env.TEST_TENANT_ID = String(id);
});

// e2e/global.teardown.ts
import { test as teardown } from '@playwright/test';

teardown('delete test tenant', async ({ request }) => {
  if (process.env.TEST_TENANT_ID) {
    await request.delete(`/api/test/tenants/${process.env.TEST_TENANT_ID}`);
  }
});
```

> `teardown` runs after **all** dependent projects complete, even when tests fail. This is
> the correct pattern for cleaning up test databases, provisioned accounts, or external
> service stubs — `afterAll` in a `globalSetup` file does NOT reliably run on CI failures. [community]

---

### `webServer.wait` — Dynamic Port Detection (v1.57+)

Use a regex pattern with named capture groups in `webServer.wait.stdout` to capture the port your dev server prints on startup. Playwright populates the matched group as an environment variable, eliminating hard-coded port numbers.

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  webServer: {
    command: 'npm run dev',
    wait: {
      // Named capture group → process.env.VITE_PORT is set automatically
      stdout: /Local:\s+http:\/\/localhost:(?<vite_port>\d+)/,
    },
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
  },
  use: {
    // Use the captured port — falls back to 5173 if not captured
    baseURL: `http://localhost:${process.env.VITE_PORT ?? 5173}`,
  },
});
```

> Hard-coding `url: 'http://localhost:3000'` breaks when a port is already in use and Vite/Webpack
> picks the next available one. `wait.stdout` with a named capture group solves this without
> custom shell scripts. [community]

---

### TLS Client Certificates — Mutual TLS (v1.46+)

Supply client-side certificates for services that require mutual TLS (mTLS) authentication. Configured globally in `playwright.config.ts` or per-context for targeted use.

```typescript
// playwright.config.ts — global mTLS certificate
import { defineConfig } from '@playwright/test';

export default defineConfig({
  use: {
    clientCertificates: [
      {
        origin:      'https://internal-api.example.com',
        certPath:    './e2e/certs/client.pem',
        keyPath:     './e2e/certs/client-key.pem',
        passphrase:  process.env.E2E_CERT_PASSPHRASE,  // never hard-code
      },
    ],
  },
});

// Per-context: use different cert for different origins in the same test
test('admin endpoint requires different cert', async ({ browser }) => {
  const context = await browser.newContext({
    clientCertificates: [
      {
        origin:   'https://admin.example.com',
        certPath: './e2e/certs/admin.pem',
        keyPath:  './e2e/certs/admin-key.pem',
      },
    ],
  });
  const page = await context.newPage();
  await page.goto('https://admin.example.com/dashboard');
  await expect(page.getByRole('heading', { name: 'Admin Dashboard' })).toBeVisible();
  await context.close();
});
```

**Also works with `apiRequestContext`:**

```typescript
test('API endpoint requires mTLS', async ({ playwright }) => {
  const request = await playwright.request.newContext({
    clientCertificates: [{
      origin:   'https://api.example.com',
      certPath: './e2e/certs/api-client.pem',
      keyPath:  './e2e/certs/api-client-key.pem',
    }],
  });
  const res = await request.get('https://api.example.com/protected');
  expect(res.ok()).toBeTruthy();
  await request.dispose();
});
```

> Never commit `.pem` files to source control. Store them in CI secrets (e.g., GitHub Secrets)
> and write them to a temp directory at the start of the CI job. Add `e2e/certs/` to `.gitignore`. [community]

---

### Test Data Factory Pattern

Use a factory module to generate unique, type-safe test data objects. Centralizing data construction eliminates scattered hard-coded strings, makes parallel-safe unique identifiers automatic, and allows easy per-test customization via overrides.

```typescript
// e2e/factories/user.factory.ts
import { faker } from '@faker-js/faker';

export interface UserData {
  name:     string;
  email:    string;
  password: string;
  role:     'admin' | 'viewer' | 'editor';
}

/**
 * Build a user data object. Pass overrides to customize specific fields.
 * Email is unique by default (UUID suffix) — safe for parallel tests.
 */
export function buildUser(overrides: Partial<UserData> = {}): UserData {
  return {
    name:     faker.person.fullName(),
    email:    `test-${crypto.randomUUID()}@example.com`,
    password: faker.internet.password({ length: 12, memorable: true }),
    role:     'viewer',
    ...overrides,
  };
}

// e2e/factories/order.factory.ts
export interface OrderData {
  productId: string;
  quantity:  number;
  discount:  number;
}

export function buildOrder(overrides: Partial<OrderData> = {}): OrderData {
  return {
    productId: `prod-${crypto.randomUUID()}`,
    quantity:  faker.number.int({ min: 1, max: 10 }),
    discount:  0,
    ...overrides,
  };
}

// e2e/specs/admin.spec.ts — compose factories in tests
import { test, expect } from '@playwright/test';
import { buildUser }    from '../factories/user.factory';
import { buildOrder }   from '../factories/order.factory';

test('admin can create an editor and assign an order', async ({ page, request }) => {
  const user  = buildUser({ role: 'editor' });
  const order = buildOrder({ quantity: 3, discount: 10 });

  // Seed via API — no UI flows
  const userRes = await request.post('/api/users', { data: user });
  expect(userRes.ok()).toBeTruthy();
  const { id: userId } = await userRes.json();

  const orderRes = await request.post(`/api/users/${userId}/orders`, { data: order });
  expect(orderRes.ok()).toBeTruthy();

  await page.goto(`/admin/users/${userId}`);
  await expect(page.getByText(user.name)).toBeVisible();
  await expect(page.getByText('editor')).toBeVisible();
});
```

> Use `crypto.randomUUID()` (Node 18+, no dependency) instead of `Date.now()` for unique identifiers.
> UUIDs are collision-proof even when hundreds of parallel workers generate data simultaneously. [community]

---

### Network Throttling — Simulating Slow Connections [community]

Playwright does not have a built-in slow-network throttle option, but you can simulate slow connections through two approaches: CDP (Chrome DevTools Protocol) for Chromium, or route-level artificial delays for cross-browser compatibility.

```typescript
// Approach 1: CDP network conditions (Chromium only)
test('app shows loading skeleton on slow 3G', async ({ page, context }) => {
  // Use CDP session to emulate slow 3G: 750 kbps down, 250 kbps up, 300ms RTT
  const cdpSession = await context.newCDPSession(page);
  await cdpSession.send('Network.enable');
  await cdpSession.send('Network.emulateNetworkConditions', {
    offline:            false,
    downloadThroughput: 750 * 1024 / 8,  // 750 kbps in bytes/s
    uploadThroughput:   250 * 1024 / 8,
    latency:            300,
  });

  await page.goto('/');
  // Skeleton loader should appear before content
  await expect(page.getByTestId('skeleton-loader')).toBeVisible();
  await expect(page.getByRole('main')).toBeVisible();
});

// Approach 2: Route-level delay (cross-browser, works with Firefox/WebKit)
test('app shows loading state while API responds slowly', async ({ page }) => {
  await page.route('**/api/products', async route => {
    await new Promise(res => setTimeout(res, 2_000));  // 2s artificial delay
    await route.continue();
  });

  await page.goto('/products');
  await expect(page.getByTestId('loading-spinner')).toBeVisible();
  await expect(page.getByRole('list', { name: 'Products' })).toBeVisible({ timeout: 10_000 });
});

// Approach 3: Offline mode
test('app shows offline banner when disconnected', async ({ context, page }) => {
  await page.goto('/');
  await expect(page.getByRole('main')).toBeVisible();

  await context.setOffline(true);
  await page.getByRole('button', { name: 'Refresh' }).click();
  await expect(page.getByRole('alert', { name: /offline|no connection/i })).toBeVisible();

  await context.setOffline(false);
  // App should recover on reconnect
  await page.getByRole('button', { name: 'Retry' }).click();
  await expect(page.getByRole('alert')).toBeHidden();
});
```

> CDP throttling only works in Chromium — skip the test on other browsers with
> `test.skip(browserName !== 'chromium', 'CDP throttling is Chromium-only')`.
> For cross-browser slow-network tests, use route delays instead. [community]

---

### Clipboard API Testing

Test clipboard read/write interactions by granting the clipboard permission and using `page.evaluate` to interact with the Clipboard API. Playwright's auto-waiting doesn't extend to clipboard operations — assert the DOM change, not the clipboard state directly.

```typescript
// Grant clipboard permissions before the test
test('copy button copies text to clipboard', async ({ browser }) => {
  const context = await browser.newContext({
    permissions: ['clipboard-read', 'clipboard-write'],
  });
  const page = await context.newPage();
  await page.goto('/article/123');

  await page.getByRole('button', { name: 'Copy link' }).click();

  // Read clipboard via evaluate — requires clipboard-read permission
  const clipboardText = await page.evaluate(() => navigator.clipboard.readText());
  expect(clipboardText).toMatch(/https:\/\/example\.com\/article\/123/);
  await context.close();
});

// Test paste-from-clipboard functionality
test('paste into search pre-fills the query', async ({ browser }) => {
  const context = await browser.newContext({
    permissions: ['clipboard-read', 'clipboard-write'],
  });
  const page = await context.newPage();

  // Write a value to clipboard before navigating
  await page.goto('/');
  await page.evaluate(text =>
    navigator.clipboard.writeText(text), 'playwright typescript'
  );

  await page.goto('/search');
  await page.getByPlaceholder('Search...').focus();
  await page.keyboard.press('Control+v');  // or 'Meta+v' on macOS
  await expect(page.getByPlaceholder('Search...')).toHaveValue('playwright typescript');
  await context.close();
});
```

> Clipboard permissions must be granted at context creation — you cannot add them later
> via `context.grantPermissions()`. The clipboard behaves differently in headless vs. headed
> mode; some CI environments block clipboard access entirely. Use feature flags to skip
> clipboard tests in those environments. [community]

---

### Print Dialog Testing

Test print functionality by intercepting `window.print()` or asserting that the print CSS styles apply correctly. Playwright cannot control OS-level print dialogs, but you can verify the print-triggered behavior.

```typescript
// Assert that window.print() is called when the Print button is clicked
test('Print button triggers print dialog', async ({ page }) => {
  await page.goto('/invoice/123');

  // Intercept window.print() before clicking the button
  let printCalled = false;
  await page.exposeFunction('__recordPrint', () => { printCalled = true; });
  await page.addInitScript(() => {
    const original = window.print;
    window.print = function() {
      (window as any).__recordPrint();
      // Do NOT call original.call(this) — prevent actual OS dialog
    };
  });

  await page.getByRole('button', { name: 'Print' }).click();
  expect(printCalled).toBe(true);
});

// Test print CSS by checking styles applied under @media print
test('invoice hides navigation in print view', async ({ page }) => {
  await page.goto('/invoice/123');

  // Emulate print media type
  await page.emulateMedia({ media: 'print' });

  // Navigation should be hidden in print CSS
  await expect(page.getByRole('navigation')).toBeHidden();
  await expect(page.getByTestId('invoice-content')).toBeVisible();

  // Take visual snapshot of print layout
  await expect(page).toHaveScreenshot('invoice-print.png');

  // Restore screen media
  await page.emulateMedia({ media: 'screen' });
});
```

> `page.emulateMedia({ media: 'print' })` applies `@media print` CSS rules and is the
> correct way to test print styles — it does not open a print dialog. Combine with
> `toHaveScreenshot()` for visual regression of print layouts. [community]

---

### `browser.bind()` for Multi-Client and Agent Scenarios (v1.59+)

`browser.bind()` makes a running browser instance available for other processes or agents to connect to. Useful for orchestrating multi-agent workflows, browser reuse across processes, and interactive debugging sessions.

```typescript
// Process 1: Launch browser and bind it
// scripts/start-shared-browser.ts
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: false });
const { endpoint } = await browser.bind('test-session', {
  host: 'localhost',
  port: 0,  // OS assigns a free port
});

console.log(`Browser bound at: ${endpoint}`);
// Save endpoint for Process 2 to use
process.env.BROWSER_ENDPOINT = endpoint;

// Process 2: Connect to the bound browser
// e2e/specs/shared-browser.spec.ts
import { chromium } from '@playwright/test';

test('connects to shared browser session', async () => {
  const endpoint = process.env.BROWSER_ENDPOINT!;
  const browser  = await chromium.connect(endpoint);
  const context  = await browser.newContext();
  const page     = await context.newPage();

  await page.goto('/admin');
  // Multiple agents can now operate on the same browser simultaneously
  await page.close();
  await context.close();
  // Do NOT call browser.close() — you're a client, not the owner
});

// Cleanup: unbind when done
// await browser.unbind();
// await browser.close();
```

> `browser.bind()` is designed for agentic/orchestration scenarios — avoid it in standard
> parallel test suites where each worker should own its browser instance. Using a shared
> bound browser in parallel tests without context isolation causes cross-test pollution. [community]

---

---

### Playwright Test Agents — AI-Assisted Test Lifecycle (v1.56+)

Playwright v1.56 shipped three official AI agent definitions that work with LLMs via the `@playwright/mcp` MCP server or the `--agents` CLI flag. Understanding these agents helps teams integrate AI-assisted test generation and healing into CI workflows.

| Agent | Role | Typical input | Typical output |
|-------|------|--------------|----------------|
| Planner | Explores the app, plans test cases | App URL | Markdown test plan (scenarios, steps) |
| Generator | Writes spec files from plans | Test plan file | `.spec.ts` files |
| Healer | Executes tests, repairs locator failures | Failing spec files + app URL | Patched `.spec.ts` files |

**Healer workflow in CI (auto-repair failing locators):**

```typescript
// playwright.config.ts — enable healer on retry
// Run: npx playwright test --agent healer --retries=1
// The healer agent fires on first retry, re-examines the page, and patches the locator

// Manual healer invocation (outside of test runner):
// npx playwright agent healer --spec e2e/specs/checkout.spec.ts --url https://staging.example.com
```

```bash
# Generate a test plan from a live URL
npx playwright agent planner --url https://staging.example.com --output test-plan.md

# Generate spec files from the plan
npx playwright agent generator --plan test-plan.md --output e2e/specs/

# Auto-heal a failing spec
npx playwright agent healer --spec e2e/specs/checkout.spec.ts --url https://staging.example.com
```

**Integration with `browser.bind()` for agent scenarios:**

```typescript
// Launch a shared browser that agents can connect to
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: false });
const { endpoint } = await browser.bind('agent-session');

// The @playwright/mcp server can now connect to this endpoint
// npx @playwright/mcp connect --endpoint <endpoint>
console.log(`Agent endpoint: ${endpoint}`);
```

> Playwright Test Agents are most useful for brownfield apps with many locator regressions after a design-system upgrade. Run the Healer in CI as a post-failure step — it patches selectors and commits the fix automatically. [community]

> The Planner agent produces test plans as markdown — review them like you would a PR. AI hallucinations in test plans are common for dynamic/authenticated flows; always review before Generator writes specs. [community]

---

### `testInfo.snapshotPath({ kind })` — Snapshot Kind Routing (v1.53+)

Control which snapshot template applies when a test produces multiple snapshot types (visual, aria, text). Useful when you want different baselines for the same test across environments or snapshot types.

```typescript
test('dashboard visual and aria snapshots', async ({ page }, testInfo) => {
  await page.goto('/dashboard');

  // Use the default visual snapshot path
  await expect(page).toHaveScreenshot('dashboard.png');

  // Route to an aria-specific snapshot directory
  const ariaPath = testInfo.snapshotPath('dashboard.aria.yml', { kind: 'aria' });
  await expect(page.getByRole('main')).toMatchAriaSnapshot({ path: ariaPath });
});
```

---

### `maxRedirects` for API Request Context (v1.52+)

Control how many HTTP redirects `APIRequestContext` follows automatically. Useful when testing redirect chains or when you need to assert on intermediate redirect responses.

```typescript
test('API respects redirect chain', async ({ request }) => {
  // Default: follows up to 20 redirects. Set to 0 to disable redirect following.
  const request0 = await request.newContext({ maxRedirects: 0 });

  const res = await request0.get('/old-url');
  expect(res.status()).toBe(301);
  expect(res.headers()['location']).toContain('/new-url');
  await request0.dispose();
});

test('follow exactly 2 redirects', async ({ playwright }) => {
  const ctx = await playwright.request.newContext({ maxRedirects: 2 });
  const res  = await ctx.get('https://example.com/deep-redirect');
  // Stops after 2 hops — throws if more redirects are encountered
  expect(res.ok()).toBeTruthy();
  await ctx.dispose();
});
```

---

## Project Structure Reference

```
e2e/
  auth.setup.ts          # One-time login; writes storageState
  global.setup.ts        # DB/API setup project (project deps, not globalSetup)
  fixtures/
    pages.ts             # POM fixture extensions (loginPage, dashboardPage, …)
    auth.ts              # Extended fixture with pre-authenticated page (if needed)
    api.ts               # Extended fixture with seeded APIRequestContext
    axe.ts               # Shared AxeBuilder fixture for accessibility tests
    logging.ts           # Auto-attach console logs on failure
    matchers.ts          # Custom expect matchers (toHaveValidationError, toShowToast)
    overlays.ts          # addLocatorHandler fixture for cookie/promo overlay dismissal
    index.ts             # mergeTests() composition point — import from here
  pages/
    index.ts             # Typed page factory (createPage<T>)
    LoginPage.ts         # POM: /login
    DashboardPage.ts     # POM: /dashboard
    UserTablePage.ts     # POM: /admin/users
    components/
      SearchWidget.ts    # Sub-component POM used by multiple pages
  reporters/
    slack-reporter.ts    # Custom Slack/webhook reporter
  specs/
    auth.spec.ts         # Login, logout, session expiry
    dashboard.spec.ts    # Dashboard metrics, navigation
    users.spec.ts        # CRUD for users
    visual.spec.ts       # Visual regression tests
    accessibility.spec.ts # WCAG violation scans
    aria.spec.ts         # Aria snapshot structural regression tests
    api/
      users.spec.ts      # Pure API tests (no browser)
  .auth/
    user.json            # Stored auth state — add to .gitignore
  screenshot.css         # CSS injected for visual regression to hide dynamic content
  tsconfig.json          # Separate TypeScript config for e2e code
playwright.config.ts
playwright-ct.config.ts  # Separate config for component tests (--ct)
.eslintrc.playwright.json  # eslint-plugin-playwright rules

# Component tests live alongside source (separate from e2e/)
src/
  components/
    Button.ct.spec.ts    # Component test with @playwright/experimental-ct-react
    UserProfile.ct.spec.ts
playwright/
  index.tsx              # Global hooks/providers for component tests
```

**Rules:**
- One spec file per feature domain, not per page.
- Fixtures, POMs, reporters, and matchers live under `e2e/`; never in `src/`.
- `auth.setup.ts` is the only file that performs a real login; all other tests consume `storageState`.
- `global.setup.ts` handles DB/API seeding; prefer project deps over `globalSetup`.
- Add `e2e/.auth/`, `playwright-report/`, `test-results/`, `blob-report/`, and `**/*-linux.png`, `**/*-darwin.png`, `**/*-win32.png` to `.gitignore` (keep only CI-platform snapshots).

---

## Recommended playwright.config.ts Baseline

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir:          './e2e',
  testMatch:        '**/*.spec.ts',
  fullyParallel:    true,
  forbidOnly:       !!process.env.CI,        // fail if test.only left in CI
  retries:          process.env.CI ? 2 : 0,  // retry flakes on CI only
  failOnFlakyTests: !!process.env.CI && !!process.env.STRICT_FLAKE_MODE, // v1.52+
  workers:          process.env.CI ? 4 : undefined,
  timeout:          process.env.CI ? 60_000 : 30_000,  // CI machines are slower
  reporter:         process.env.CI ? [['blob'], ['junit', { outputFile: 'test-results.xml' }]] : [['html'], ['list']],
  maxFailures:      process.env.CI ? 10 : undefined,   // stop early on broken suites
  captureGitInfo:   { commit: true, diff: false },     // git context in reports (v1.51+)
  updateSnapshots:  'changed',                          // only update changed snapshots (v1.50+)
  tsconfig:         './e2e/tsconfig.json',             // single tsconfig for all test files (v1.49+)
  tag:              process.env.CI_ENVIRONMENT_NAME,   // label runs in reports (v1.57+)
  respectGitIgnore: true,                              // skip files in .gitignore (v1.45+)
  expect: {
    timeout:         5_000,
    toHaveScreenshot: {
      maxDiffPixels: 100,
      stylePath:    './e2e/screenshot.css',
    },
  },
  use: {
    baseURL:         process.env.WEB_URL ?? 'http://localhost:3000',
    trace:           'on-first-retry',   // capture trace on first CI retry
    screenshot:      'only-on-failure',
    video:           'on-first-retry',
    serviceWorkers:  'block',            // required when app uses MSW
  },
  webServer: {
    command:             'npm run dev',
    url:                 process.env.WEB_URL ?? 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout:             120_000,
  },
  projects: [
    { name: 'setup', testMatch: /auth\.setup\.ts/ },
    {
      name:         'chromium',
      dependencies: ['setup'],
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'e2e/.auth/user.json',
      },
    },
    {
      name:    'visual',
      testMatch: /visual\/.*.spec.ts/,
      workers: 1,  // serialize visual tests for consistent rendering (v1.52+)
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
```

---

## Quick-Reference Cheat Sheet

```typescript
// Navigation
await page.goto('/path');                       // uses baseURL from config
await page.waitForURL(/dashboard/);             // wait for URL pattern

// Locators (priority order)
page.getByRole('button', { name: /submit/i })
page.getByLabel('Email')
page.getByPlaceholder('Search...')
page.getByText('Welcome back')
page.getByTestId('submit-btn')
page.locator('x-custom-element', { hasText: 'Details' }) // Shadow DOM host

// Locator operations
locator.describe('human label')                // annotate for trace readability (v1.52+)
locator.filter({ hasText: 'Alice' })
locator.filter({ visible: true })              // only visible matches (v1.50+)
locator.and(page.getByTitle('Primary'))
locator.or(page.getByText('Fallback'))
locator.nth(0)
locator.contentFrame()                         // Locator → FrameLocator (v1.43+)
frameLocator.owner()                           // FrameLocator → iframe Locator (v1.43+)

// Actions
await locator.click();
await locator.fill('value');
await locator.selectOption('option');
await locator.check();
await locator.hover();
await locator.press('Enter');

// Assertions (web-first, auto-retrying)
await expect(locator).toBeVisible();
await expect(locator).toBeHidden();
await expect(locator).toBeEnabled();
await expect(locator).toBeDisabled();
await expect(locator).toHaveText('exact');
await expect(locator).toContainText('partial');
await expect(locator).toHaveValue('input value');
await expect(locator).toBeChecked();
await expect(locator).toHaveCount(3);
await expect(locator).toContainClass('active');         // partial class check (v1.52+)
await expect(locator).toHaveAccessibleErrorMessage('Required');  // aria-errormessage (v1.52+)
await expect(locator).toMatchAriaSnapshot('- button: Submit');   // aria tree (v1.49+)
await expect(page).toHaveURL(/pattern/);
await expect(page).toHaveTitle(/pattern/);

// Scoping / filtering
page.getByRole('dialog').getByRole('button', { name: 'Close' })
page.getByRole('listitem').filter({ hasText: 'Buy milk' })
page.getByRole('row').nth(1)

// Soft and configured assertions
const softExpect = expect.configure({ soft: true });
await softExpect(locator).toHaveText('value');
expect(test.info().errors).toHaveLength(0);             // verify all soft assertions

// Network mocking
await page.route('**/api/data', route =>
  route.fulfill({ status: 200, body: JSON.stringify({ items: [] }) })
);

// Network response wait — CORRECT pattern to avoid deadlock
const [response] = await Promise.all([
  page.waitForResponse('**/api/save'),
  page.getByRole('button', { name: 'Save' }).click(),
]);

// Visual regression
await expect(page).toHaveScreenshot('page.png', {
  mask: [page.locator('[data-testid="timestamp"]')],
});

// Sharding (CLI)
// npx playwright test --shard=1/4
// npx playwright test --last-failed
// npx playwright test --only-changed
// npx playwright test --only-changed=origin/main

// Auth role-switching in existing context (v1.59+)
await context.setStorageState({ path: './e2e/.auth/admin.json' });
await page.reload();

// v1.59+ inspection APIs (no event listeners needed)
const messages = await page.consoleMessages({ filter: 'since-navigation' });
const errors   = await page.pageErrors();
const requests = await page.requests({ filter: 'since-navigation' });

// Auto-dismiss overlays before any action (v1.44+)
await page.addLocatorHandler(
  page.getByText('Accept cookies'),
  async () => page.getByRole('button', { name: 'Accept' }).click(),
  { times: 1 }
);

// Upgrade a brittle locator to best-practice (refactoring tool, v1.59+)
const better = page.locator('.submit-button').normalize();  // → getByRole('button', { name: 'Submit' })

// ARIA snapshot — AI mode for LLM-assisted diagnostics (v1.59+)
const aiTree = await page.ariaSnapshot({ mode: 'ai' });   // full-page, compact for LLMs
const aiNav  = await page.getByRole('navigation').ariaSnapshot({ mode: 'ai' });
```
