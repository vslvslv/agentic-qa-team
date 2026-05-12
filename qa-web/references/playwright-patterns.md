# Playwright Patterns & Best Practices (TypeScript)
<!-- lang: TypeScript | sources: official | community | mixed | iteration: 37 | score: 100/100 | date: 2026-05-12 -->
<!-- official: playwright.dev/docs/best-practices, /pom, /locators, /test-fixtures, /test-assertions, /api-testing, /network, /auth, /test-sharding, /ci-intro, /test-configuration, /test-parallel, /test-snapshots, /release-notes, /api/class-testconfig, /trace-viewer-intro, /test-retries, /test-components, /docker, /api/class-page, /accessibility-testing, /aria-snapshots, /test-reporters, /codegen, /test-global-setup-teardown, /api/class-locatorassertions, /api/class-browsercontext, /test-cli, /test-agents, /api/class-screencast, /api/class-locator (drop/description/highlight/steps), /api/class-apirequestcontext, /api/class-tracing (startHar/stopHar), /api/class-test (abort), /api/class-browser (on-context), /api/class-weberror (location), /api/class-testconfig (reportSlowTests/globalTimeout), /api/class-browsertype (connectOverCDP noDefaults v1.60 isLocal v1.58), /aria-snapshots (children matching modes contain/equal/deep-equal v1.52) -->
<!-- community: playwrightsolutions.com, currents.dev/blog/playwright, mxschmitt/awesome-playwright, playwright-network-cache, GitHub Discussions patterns, real-world production experience, v1.45-v1.61 release notes analysis, checkly/playwright-examples, Playwright GitHub issues, mxschmitt/playwright-test-coverage, playwright.dev/docs/test-components (update/unmount lifecycle), playwright.dev/docs/auth (sessionStorage workaround), playwright.dev/docs/test-reporters (testStepInfo.titlePath), release notes v1.56-v1.61 deep audit, playwright.dev/docs/api/class-locatorassertions (accessibility assertions v1.44-v1.50), playwright.dev/docs/dialogs, playwright.dev/docs/emulation, playwright.dev/docs/evaluating, playwright.dev/docs/test-annotations (v1.52 testResult.annotations), playwright.dev/docs/release-notes v1.49-v1.61 full audit, playwright.dev/docs/test-agents (init-agents workflow v1.56), v1.57-v1.61 deep audit (worker.on console, prefers-contrast, toHaveURL predicate, close reason, noSnippets), checkly/playwright-examples production patterns, v1.60 release notes full audit (tracing.startHar, locator.drop, test.abort, browser.on-context, context lifecycle events, toHaveCSS pseudo, getByRole description, locator.highlight style, ariaSnapshot boxes), v1.59 deep audit (screencast API, browser.bind/unbind, response.httpVersion, request.existingResponse, locator.normalize, page.pickLocator, browserContext.setStorageState, consoleMessage.timestamp, tracing.start live, context.isClosed), eslint-plugin-playwright flat config (ESLint v9 migration, v1.6+ required), v1.60 webError.location() (JS error source location API), iteration-34 gap audit (page.on weberror and webError.location added to Key APIs table, testConfig.reportSlowTests + globalTimeout added to recommended config baseline), iteration-35 gap audit (fixed consoleMessages v1.56 section heading, added --fail-on-flaky-tests CLI flag, added clock.runFor/tick vs fastForward behavioral gotcha #48), iteration-36 gap audit (connectOverCDP noDefaults v1.60 dedicated pattern + gotcha #49, aria snapshot /children matching modes contain/equal/deep-equal + global config v1.52), iteration-37 gap audit (locator.click/dragTo steps option v1.57, connectOverCDP isLocal v1.58, locator.describe/description read-back pattern v1.57, gotchas #50-52) -->

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

### GraphQL API Interception by Operation Name

GraphQL endpoints share a single URL (`/graphql`), so URL-based route matching cannot distinguish between queries. Use the request body's `operationName` to target specific operations.

```typescript
// Mock a specific GraphQL query by operation name
await page.route('**/graphql', async route => {
  const body = route.request().postDataJSON() as { operationName?: string };

  if (body?.operationName === 'GetUserProfile') {
    // Return mock data for this specific query
    await route.fulfill({
      status:      200,
      contentType: 'application/json',
      body: JSON.stringify({
        data: {
          user: { id: '1', name: 'Alice Smith', role: 'admin' },
        },
      }),
    });
    return;
  }

  // Pass through all other GraphQL operations
  await route.continue();
});

await page.goto('/profile');
await expect(page.getByRole('heading', { name: 'Alice Smith' })).toBeVisible();

// Test GraphQL error handling
await page.route('**/graphql', async route => {
  const body = route.request().postDataJSON() as { operationName?: string };

  if (body?.operationName === 'CreateOrder') {
    await route.fulfill({
      status:      200,
      contentType: 'application/json',
      body: JSON.stringify({
        data:   null,
        errors: [{ message: 'Insufficient stock', extensions: { code: 'OUT_OF_STOCK' } }],
      }),
    });
    return;
  }
  await route.continue();
});

await page.getByRole('button', { name: 'Place order' }).click();
await expect(page.getByRole('alert')).toContainText('Insufficient stock');
```

**Assert on GraphQL request variables:**

```typescript
// Verify the correct variables were sent to the mutation
test('update profile sends correct variables', async ({ page }) => {
  let capturedVariables: Record<string, unknown> = {};

  await page.route('**/graphql', async route => {
    const { operationName, variables } = route.request().postDataJSON() as {
      operationName: string;
      variables: Record<string, unknown>;
    };

    if (operationName === 'UpdateProfile') {
      capturedVariables = variables;
      await route.fulfill({
        status:      200,
        contentType: 'application/json',
        body: JSON.stringify({ data: { updateProfile: { success: true } } }),
      });
      return;
    }
    await route.continue();
  });

  await page.goto('/profile/edit');
  await page.getByLabel('Name').fill('Bob Jones');
  await page.getByRole('button', { name: 'Save' }).click();

  expect(capturedVariables).toMatchObject({ name: 'Bob Jones' });
});
```

> Always pass through unmatched operations with `route.continue()` — if you `route.abort()`
> or leave unmatched routes unhandled, other queries (auth, feature flags) will silently fail
> and produce confusing UI states. [community]

> Use `route.request().postDataJSON()` (not `postData()`) for GraphQL — it parses the JSON
> body for you. `postData()` returns a raw string that requires manual `JSON.parse()`. [community]

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

### 20. Date-dependent tests fail in CI due to timezone mismatch [community]
**What:** Tests that assert on date-related UI (e.g., "Today", "Yesterday", relative timestamps, date picker defaults) pass locally but fail in CI — often with a one-day-off error.
**WHY:** The developer's machine runs with a local timezone (e.g., `America/New_York` or `Europe/Berlin`), while the CI runner typically runs UTC or a different timezone. A test that creates a record at 11 PM local time may be "Today" locally but "Tomorrow" in UTC.
**Fix:** Pin `TZ=UTC` in CI environment variables, and run local tests the same way with `TZ=UTC npx playwright test`. If your app serves timezone-aware users, test timezone-specific behavior in dedicated tests using `page.clock.setFixedTime()` with an explicit date.

```yaml
# .github/workflows/playwright.yml
env:
  TZ: UTC
```

```typescript
// Use page.clock for time-zone-sensitive UI tests instead of relying on system time
test('shows correct "Today" label', async ({ page }) => {
  await page.clock.setFixedTime(new Date('2025-06-15T09:00:00Z')); // explicit UTC
  await page.goto('/calendar');
  await expect(page.locator('[data-date="2025-06-15"]')).toContainText('Today');
});
```

### 21. TypeScript type errors in fixture files cause all tests to fail with cryptic syntax errors [community]
**What:** After a refactor, all tests start failing with `SyntaxError: Cannot use import statement` or `TypeError: Cannot read properties of undefined` — even tests unrelated to the changed file.
**WHY:** TypeScript type errors in shared fixture files propagate silently through the module system. When Playwright imports a fixture module that fails to compile, every test that depends on it fails with a JavaScript runtime error rather than a clear TypeScript type error.
**Fix:** Add `tsc --noEmit` as a mandatory CI step before `playwright test`. It runs in 2–5 seconds and shows the exact file and line of the type error — preventing a CI run that wastes 10+ minutes before hitting the error.

```yaml
# .github/workflows/playwright.yml — type-check before test run
- name: Type-check test files
  run: npx tsc --noEmit -p e2e/tsconfig.json

- name: Run Playwright tests
  run: npx playwright test
```

> Add `tsc --noEmit` to your `package.json` scripts: `"test:e2e": "tsc --noEmit -p e2e/tsconfig.json && playwright test"`.
> The two-second type check prevents the most confusing class of CI failures — "all tests broken" from a single type error in a shared fixture. [community]

### 22. `locator.all()` returns empty array when called before content renders [community]
**What:** `const items = await page.getByRole('listitem').all()` returns `[]`, causing a loop that silently skips all assertions — the test passes even though the page was empty.
**WHY:** `locator.all()` takes a snapshot of the DOM **immediately** with no retry. If the list hasn't loaded yet, there are zero elements, and the `for...of` loop body never executes.
**Fix:** Always await a web-first assertion confirming the content is present before calling `.all()`:

```typescript
// WRONG — calls all() before list has loaded
const items = await page.getByRole('listitem').all();
for (const item of items) {
  await expect(item).toBeVisible(); // silently skipped if items === []
}

// CORRECT — assert minimum count first, then snapshot
await expect(page.getByRole('listitem')).toHaveCount(5);
const items = await page.getByRole('listitem').all();
for (const item of items) {
  await expect(item).toBeVisible();
}
```

### 23. `toHaveCSS()` fails with hex colors — use RGB format [community]
**What:** `await expect(button).toHaveCSS('color', '#2563eb')` fails even when the button clearly shows the correct blue color.
**WHY:** Browsers normalize all color values to their computed RGB form internally. Playwright's `toHaveCSS()` retrieves the computed style, which is always `rgb(...)` or `rgba(...)` — never hex.
**Fix:** Convert hex to RGB before passing to `toHaveCSS()`, or use a regex to avoid the format dependency altogether:

```typescript
// WRONG — hex is never the computed value
await expect(button).toHaveCSS('color', '#2563eb');

// CORRECT — use computed RGB
await expect(button).toHaveCSS('color', 'rgb(37, 99, 235)');

// ALSO CORRECT — regex avoids format dependency
await expect(button).toHaveCSS('color', /rgb\(37,\s*99,\s*235\)/);
```

---

## Breaking Changes Reference (v1.45–v1.60)

A summary of removals and behavioral changes that require action when upgrading.

| Version | Change | Migration |
|---------|--------|-----------|
| v1.60 | `Locator.ariaRef()` **removed** | Use `page.getByRole()` or `locator.filter()` |
| v1.60 | `handle` option on `exposeBinding` **removed** | Remove `handle` from `BrowserContext.exposeBinding` / `Page.exposeBinding` calls |
| v1.60 | `logger` option on `connect` / `connectOverCDP` **removed** | Remove `logger` option; use process-level logging |
| v1.60 | `videosPath` / `videoSize` context options **removed** | Use `recordVideo: { dir, size }` object form |
| v1.60 | `workers: 0` or negative values now rejected at parse time | Set `workers` to a positive integer or `undefined` |
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
| `TZ` env var | (local tz) | `TZ=UTC` | Pin timezone so date-dependent tests produce consistent results across regions |
| `tsc --noEmit` | not run | run before test | Catch TypeScript type errors before wasting CI time executing tests |

### Installing browsers correctly in CI

```bash
# Install only Chromium to save 300–500 MB per omitted browser
npx playwright install chromium --with-deps

# --with-deps installs OS-level system libraries (libatk, ffmpeg, etc.)
# Omitting it causes silent browser crashes in headless environments
```

### TypeScript pre-flight check in CI

Run `tsc --noEmit` before `playwright test` to catch type errors and missing `await`s before wasting CI browser time. This is especially valuable in large suites where a single type error in a fixture module would fail every test.

```yaml
# .github/workflows/playwright.yml — TypeScript check before test run
- name: Type-check
  run: npx tsc --noEmit -p e2e/tsconfig.json

- name: Run Playwright tests
  run: npx playwright test
```

```bash
# Local: run both steps in sequence
npx tsc --noEmit -p e2e/tsconfig.json && npx playwright test
```

> TypeScript errors in shared fixtures cause ALL tests to fail with cryptic errors like
> "SyntaxError: Cannot use import statement". `tsc --noEmit` catches these in 2–3 seconds
> before browser launch. Add it as a required CI step, not just a pre-commit hook. [community]

### Pin CI timezone to UTC

Date-dependent tests (clock mocking, date filters, "today's appointments") may pass locally but fail in CI because the CI runner uses a different system timezone. Pin the timezone for determinism.

```yaml
# .github/workflows/playwright.yml — pin timezone to UTC
env:
  TZ: UTC

# Or per-step:
- name: Run Playwright tests
  env:
    TZ: UTC
  run: npx playwright test
```

```bash
# Local: run with UTC timezone to match CI behavior
TZ=UTC npx playwright test
```

> Timezone-related flakiness appears as "test passes locally (developer's local tz) but fails in CI (UTC)" on tests involving date labels like "Today" or relative timestamps. Pin `TZ=UTC` in both CI and local test scripts for consistent behavior. [community]

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
| `'retain-on-failure-and-retries'` | Every attempt (initial + retries); retains only if test failed (v1.60+) | When you need the full retry timeline for flaky tests, not just the last failure |
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
| Omitting `TZ=UTC` in CI for date-dependent tests | System timezone differs between developer machine and CI runner, causing date labels ("Today", relative timestamps) to mismatch | Set `TZ: UTC` in CI env and run local tests with `TZ=UTC npx playwright test` |
| Running `tsc --noEmit` only as a pre-commit hook | TypeScript errors in fixture files fail ALL tests with cryptic syntax errors instead of a clear type error | Run `tsc --noEmit -p e2e/tsconfig.json` as a mandatory CI step before `playwright test` |
| Slow fixture setup consuming the test's timeout budget | Worker-scoped migrations taking 30s cause "Test timeout of 30000ms exceeded" in the test body | Set `timeout: N` in the fixture options to give setup its own independent time budget |
| `{ box: true }` on actively debugged fixtures | Hides all internal steps in the HTML report, making failures impossible to diagnose via report alone | Reserve `{ box: true }` for stable utility fixtures; remove it when actively investigating fixture failures |
| `ignoreHTTPSErrors: true` unconditionally | Suppresses real certificate errors in production smoke tests, masking TLS misconfigurations | Gate on environment: `ignoreHTTPSErrors: process.env.TEST_ENV === 'staging'` |
| `--no-deps` in CI | Silently skips auth/DB setup projects, causing false passes when test data is missing | Use `--no-deps` only locally for fast iteration; always run full dependency chain in CI |
| `locator.all()` before content loads | Snapshots empty DOM; `for...of` body never runs; test passes vacuously | Always `await expect(locator).toHaveCount(n)` before calling `.all()` |
| `toHaveCSS('color', '#2563eb')` | Browsers compute colors as `rgb(...)`; hex never matches | Use `rgb(37, 99, 235)` or a regex with `toHaveCSS()` |
| `locator.fill()` on autocomplete / masked inputs | Sets value atomically without firing individual key events; autocomplete never triggers | Use `locator.pressSequentially()` for inputs that need keystroke events |
| `page.route()` for popup's first request | `page.route()` doesn't intercept the first navigation request of a popup (new page) — fires too late | Use `context.route()` for rules that must apply to all pages including new popups |
| `addLocatorHandler` without re-hover after handler | Handler moves mouse to dismiss overlay; subsequent `hover()` acts on wrong position | Re-hover the target element explicitly after any action following a handler invocation |
| `toMatchAriaSnapshot` after v1.56 upgrade without updating snapshots | v1.56 adds placeholder text to input ARIA representations — pre-upgrade snapshots fail | Run `--update-snapshots=changed` after upgrading to v1.56+ |
| `context.clearCookies()` without filter | Removes ALL cookies including third-party analytics/widget cookies | Pass `domain` or `name` filter to target only the cookies you want to clear |
| Checking `context.isClosed()` is absent in fixture teardown | Calling `.close()` on an already-disposed context throws misleading "Target closed" errors | Add `if (!context.isClosed())` guard in worker-scoped teardown fixtures |

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
| `context.clearCookies({ name, domain, path })` | Remove filtered subset of cookies (v1.43+) | Logout testing without clearing all cookies |
| `context.isClosed()` | Returns true after context is disposed (v1.59+) | Safe fixture teardown guards |
| `page.clearConsoleMessages()` | Clear accumulated console logs (v1.59+) | Reset log state mid-test |
| `page.clearPageErrors()` | Clear accumulated page errors (v1.59+) | Reset error state mid-test |
| `page.consoleMessages({ filter })` | Retrieve stored console log history (v1.59+) | Post-action console error assertions |
| `page.pageErrors({ filter })` | Retrieve stored JS exception history (v1.59+) | Post-action uncaught error checks |
| `page.requests({ filter })` | Retrieve stored network request history (v1.59+) | Verify API calls without event listeners |
| `page.addLocatorHandler(locator, fn)` | Auto-dismiss overlays before actionability checks | Cookie banners, popups, modals |
| `page.removeLocatorHandler(locator)` | Remove a previously added overlay handler | Cleanup after targeted page sections |
| `consoleMessage.timestamp()` | Unix ms when message was created (v1.59+) | Correlate console events with actions; timing diagnostics |
| `page.on('weberror', handler)` | Fires on uncaught JS exception OR unhandled promise rejection (v1.60+); more complete than `pageerror` | Comprehensive JS error monitoring in production-parity tests |
| `webError.location()` | Returns `{ url, lineNumber, columnNumber }` of error origin (v1.60+) | Source-map JS error attribution; pair with minification source maps |

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
| `expect(locator).toHaveAccessibleName(text)` | Assert computed accessible name (v1.44+) | Icon buttons, unlabeled controls |
| `expect(locator).toHaveAccessibleDescription(text)` | Assert aria-describedby text (v1.44+) | Help text, tooltip wiring |
| `expect(locator).toHaveRole(role)` | Assert ARIA role string (v1.44+) | Custom ARIA widgets, design system compliance |
| `expect(locator).toBeChecked({ indeterminate })` | Assert indeterminate checkbox state (v1.50+) | Tri-state checkboxes |
| `expect(locator).toBeAttached()` | Assert element connected to DOM (v1.33+) | Check element exists without visibility requirement |
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
| `route.fallback()` | Pass to the next matching route handler | Layered mocking (fixture base + test override) |
| `page.unroute(url, handler)` | Remove a specific route handler | Clean up targeted mocks mid-test |
| `page.unrouteAll()` | Remove all route handlers on the page | Post-test cleanup for shared page fixtures |
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
| `{ timeout: N }` | Override fixture-level timeout (ms) | Slow DB or server setup that exceeds test timeout |
| `locator.describe(label)` | Annotate locator with human-readable name (v1.52+) | Trace/report readability |
| `testInfo.snapshotPath(name, { kind })` | Route snapshot to kind-specific directory (v1.53+) | Separate visual/aria/text baselines |
| `testInfo.outputPath(name)` | Generate CI-friendly unique artifact path | Write files (logs, dumps) in test result dir |

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

### Browser Emulation — Color Scheme, Locale, Reduced Motion, and JavaScript

Test accessibility preferences, internationalization, and degraded-JS scenarios using browser context emulation options.

**Dark mode (`colorScheme: 'dark'`):**

```typescript
// playwright.config.ts — test project for dark mode
{
  name: 'dark-mode',
  use: {
    ...devices['Desktop Chrome'],
    colorScheme: 'dark',
  },
}

// e2e/specs/theme.spec.ts — verify dark mode CSS applies
test('dashboard renders in dark mode', async ({ page }) => {
  await page.emulateMedia({ colorScheme: 'dark' });
  await page.goto('/dashboard');
  const bg = await page.evaluate(() =>
    getComputedStyle(document.body).backgroundColor
  );
  // Dark background applied via @media (prefers-color-scheme: dark)
  expect(bg).toBe('rgb(18, 18, 18)');
  await expect(page).toHaveScreenshot('dashboard-dark.png');
});
```

**Reduced motion for accessibility testing:**

```typescript
// Skip animations for tests that assert on end-state, not animation
test('modal opens without animation in reduced-motion mode', async ({ browser }) => {
  const context = await browser.newContext({ reducedMotion: 'reduce' });
  const page    = await context.newPage();
  await page.goto('/dashboard');
  await page.getByRole('button', { name: 'Open settings' }).click();
  // Modal appears instantly — no transition delay to wait for
  await expect(page.getByRole('dialog')).toBeVisible();
  const animDuration = await page.evaluate(
    () => getComputedStyle(document.querySelector('[role="dialog"]')!).animationDuration
  );
  expect(animDuration).toBe('0s');  // animation disabled by prefers-reduced-motion
  await context.close();
});
```

**Locale and timezone — testing i18n and date formatting:**

```typescript
// Test date format for German locale (DD.MM.YYYY)
test('shows dates in German format', async ({ browser }) => {
  const context = await browser.newContext({
    locale:     'de-DE',
    timezoneId: 'Europe/Berlin',
  });
  const page = await context.newPage();
  await page.goto('/invoices');
  // German locale formats dates as "15.06.2025" not "06/15/2025"
  await expect(page.getByTestId('invoice-date')).toHaveText(/\d{2}\.\d{2}\.\d{4}/);
  await context.close();
});

// playwright.config.ts — dedicated i18n project
{
  name: 'de-DE',
  use: {
    ...devices['Desktop Chrome'],
    locale:     'de-DE',
    timezoneId: 'Europe/Berlin',
  },
}
```

> `timezoneId` controls the browser's timezone (affects `Date` formatting in the page).
> `TZ` env var controls the Node.js test runner's timezone (affects `new Date()` in test code).
> Both are needed for full timezone isolation. [community]

**High-contrast mode (`forcedColors: 'active'`):**

```typescript
test('high-contrast mode renders correctly', async ({ browser }) => {
  const context = await browser.newContext({ forcedColors: 'active' });
  const page    = await context.newPage();
  await page.goto('/');
  await expect(page).toHaveScreenshot('homepage-high-contrast.png');
  await context.close();
});
```

**Testing with JavaScript disabled (progressive enhancement):**

```typescript
// Verify the page is usable without JavaScript (server-rendered fallback)
test('form works without JavaScript', async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  const page    = await context.newPage();
  await page.goto('/contact');
  await page.getByLabel('Name').fill('Alice');
  await page.getByLabel('Email').fill('alice@example.com');
  await page.getByRole('button', { name: 'Submit' }).click();
  await expect(page.getByText('Message sent')).toBeVisible();
  await context.close();
});
```

> `javaScriptEnabled: false` tests server-rendered fallback for forms and navigation.
> If your app is a pure SPA, this test will show a blank page — which is itself a finding:
> your app has no graceful degradation. [community]

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

// runFor() — fire each timer callback sequentially as clock advances
// Unlike fastForward() (which jumps the clock in one step), runFor() triggers
// every intermediate timer callback that falls within the window.
test('animated counter increments exactly 5 times over 5 seconds', async ({ page }) => {
  await page.clock.install();
  await page.goto('/counter'); // app uses setInterval(increment, 1000)
  // Advance 5 seconds, firing each 1 s tick callback in sequence
  await page.clock.runFor(5_000);
  await expect(page.getByTestId('count')).toHaveText('5');
});

// tick() is an alias for runFor() with identical semantics
test('progress bar advances 10% per second', async ({ page }) => {
  await page.clock.install();
  await page.goto('/upload-progress');
  await page.clock.tick(1_000); // fires all timers due within the first 1 s
  await expect(page.getByRole('progressbar')).toHaveAttribute('aria-valuenow', '10');
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

**ESLint v9 flat config (`eslint.config.js`) — required for new projects in 2025+:**

ESLint v9 (released April 2024) made flat config the default and deprecated `.eslintrc.*`. Projects created with ESLint v9+ must use `eslint.config.js`. The `eslint-plugin-playwright` package supports flat config from v1.6+.

```typescript
// eslint.config.js — flat config for ESLint v9+ projects
import playwright from 'eslint-plugin-playwright';

export default [
  {
    // Apply only to e2e test files
    files: ['e2e/**/*.spec.ts', 'e2e/**/*.ts'],
    plugins: { playwright },
    rules: {
      ...playwright.configs['flat/recommended'].rules,
      // Customize on top of the recommended preset:
      'playwright/no-wait-for-timeout':         'error',
      'playwright/no-useless-await':            'error',
      'playwright/no-focused-test':             'error',
      'playwright/prefer-web-first-assertions': 'error',
      'playwright/no-conditional-in-test':      'warn',
      'playwright/valid-expect':                'error',
      'playwright/no-page-pause':               'error',
      'no-restricted-syntax': [
        'error',
        {
          selector: "CallExpression[callee.property.name='highlight']",
          message:  "locator.highlight() is a debug tool — remove before committing.",
        },
        {
          selector: "CallExpression[callee.property.name='pickLocator']",
          message:  "page.pickLocator() is a debug tool — remove before committing.",
        },
      ],
    },
  },
];
```

```bash
# Install eslint-plugin-playwright v1.6+ for flat config support
npm install --save-dev eslint-plugin-playwright@latest
```

> If your project still uses `.eslintrc.*` (ESLint v8 or earlier), the `jsonc` config in the section above remains valid. ESLint v9 introduced flat config but kept legacy config support via `ESLINT_USE_FLAT_CONFIG=false`. Check your ESLint version: `npx eslint --version`. Projects scaffolded with `create-next-app` or `vite` after early 2025 default to flat config. [community]

> **Gotcha:** `eslint-plugin-playwright` versions before v1.6 do not export `configs['flat/recommended']` — importing it causes `TypeError: Cannot read properties of undefined (reading 'rules')`. Pin `eslint-plugin-playwright@^1.6.0` when migrating to flat config. [community]

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

// Intercept and modify messages between page and real server
// Useful for injecting test messages or blocking specific message types
test('filters out spam messages from live feed', async ({ page }) => {
  await page.routeWebSocket('wss://ws.example.com/feed', ws => {
    const server = ws.connectToServer();  // proxy to real server
    server.onMessage(message => {
      const data = JSON.parse(message as string);
      if (data.type !== 'spam') {
        ws.send(message);  // only forward non-spam messages to the page
      }
    });
    ws.onMessage(message => server.send(message));  // forward page→server messages unchanged
  });
  await page.goto('/live-feed');
  await expect(page.getByText('spam message')).toBeHidden();
});

// Inject a test event into an otherwise real WebSocket stream
test('notification badge updates on server message', async ({ page }) => {
  let serverWs: import('@playwright/test').WebSocketRoute;
  await page.routeWebSocket('wss://ws.example.com/notifications', ws => {
    serverWs = ws.connectToServer();
    serverWs.onMessage(msg => ws.send(msg));
    ws.onMessage(msg => serverWs.send(msg));
  });
  await page.goto('/dashboard');
  await expect(page.getByTestId('notification-badge')).toHaveText('0');

  // Inject a fake server notification — simulates server push without needing real event
  serverWs!.send(JSON.stringify({ type: 'notification', count: 5 }));
  await expect(page.getByTestId('notification-badge')).toHaveText('5');
});
```

> `page.routeWebSocket()` was introduced in Playwright 1.48. For earlier versions, use
> `page.addInitScript` to replace `window.WebSocket` with a mock constructor. [community]

---

### Request Context for Multi-Step API Tests

Use `request` fixture for pure API tests (no browser) within the same test suite.

---

### Multi-Context Collaborative Testing — Simulating Multiple Users

Test features that require two or more users simultaneously (chat, comments, collaborative editing, permission changes) by creating multiple browser contexts in one test.

```typescript
// e2e/specs/chat.spec.ts — two users in the same chat room
test('messages appear in real-time for both users', async ({ browser }) => {
  // Each context gets its own cookies, localStorage, and session
  const aliceContext = await browser.newContext({
    storageState: 'e2e/.auth/alice.json',
  });
  const bobContext = await browser.newContext({
    storageState: 'e2e/.auth/bob.json',
  });

  const alicePage = await aliceContext.newPage();
  const bobPage   = await bobContext.newPage();

  // Both navigate to the same chat room
  await Promise.all([
    alicePage.goto('/chat/room-1'),
    bobPage.goto('/chat/room-1'),
  ]);

  // Alice sends a message
  await alicePage.getByLabel('Message').fill('Hello Bob!');
  await alicePage.getByRole('button', { name: 'Send' }).click();

  // Bob sees Alice's message without refreshing
  await expect(bobPage.getByText('Hello Bob!')).toBeVisible({ timeout: 5_000 });

  // Bob replies
  await bobPage.getByLabel('Message').fill('Hi Alice!');
  await bobPage.getByRole('button', { name: 'Send' }).click();
  await expect(alicePage.getByText('Hi Alice!')).toBeVisible({ timeout: 5_000 });

  await Promise.all([aliceContext.close(), bobContext.close()]);
});

// e2e/specs/permissions.spec.ts — admin changes role; viewer sees updated UI
test('role change takes effect without page refresh', async ({ browser }) => {
  const adminContext  = await browser.newContext({ storageState: 'e2e/.auth/admin.json' });
  const viewerContext = await browser.newContext({ storageState: 'e2e/.auth/viewer.json' });
  const adminPage  = await adminContext.newPage();
  const viewerPage = await viewerContext.newPage();

  await viewerPage.goto('/documents');
  await expect(viewerPage.getByRole('button', { name: 'Edit' })).toBeHidden();

  // Admin promotes viewer to editor
  await adminPage.goto('/admin/users');
  await adminPage.getByRole('row', { name: 'viewer@example.com' })
    .getByRole('button', { name: 'Promote' }).click();
  await expect(adminPage.getByText('Role updated')).toBeVisible();

  // Viewer's page should now show the edit button (real-time via WebSocket)
  await expect(viewerPage.getByRole('button', { name: 'Edit' })).toBeVisible({ timeout: 5_000 });

  await Promise.all([adminContext.close(), viewerContext.close()]);
});
```

**Multi-context fixture for collaborative tests:**

```typescript
// e2e/fixtures/multi-user.ts — reusable two-user fixture
import { test as base, type BrowserContext } from '@playwright/test';
import path from 'node:path';

type UserContexts = {
  alice: BrowserContext;
  bob:   BrowserContext;
};

export const test = base.extend<UserContexts>({
  alice: async ({ browser }, use) => {
    const ctx = await browser.newContext({
      storageState: path.join(__dirname, '../.auth/alice.json'),
    });
    await use(ctx);
    await ctx.close();
  },
  bob: async ({ browser }, use) => {
    const ctx = await browser.newContext({
      storageState: path.join(__dirname, '../.auth/bob.json'),
    });
    await use(ctx);
    await ctx.close();
  },
});

// e2e/specs/collaborative.spec.ts
import { test, expect } from '../fixtures/multi-user';

test('both users see document edits', async ({ alice, bob }) => {
  const alicePage = await alice.newPage();
  const bobPage   = await bob.newPage();
  // ... test collaborative editing
});
```

> Multi-context tests are inherently slower than single-context tests because they spawn
> two browser contexts per test. Keep them focused on the specific collaborative behavior
> being tested. Extract shared setup into a fixture to avoid duplication. [community]

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

---

### Route Fallback and Route Cleanup

**`route.fallback()`** — pass a route to the next matching handler instead of aborting or fulfilling it. Essential when multiple route handlers are registered (e.g., a base fixture registers one, and a test adds a more specific one).

```typescript
// Layered routing: fixture registers a broad mock; test adds a specific override
// Base fixture mock (handles all API requests with default mocks)
await page.route('**/api/**', async route => {
  // Default: return empty success response for any unspecified endpoint
  await route.fulfill({ status: 200, body: '{}' });
});

// Test-specific override for /api/products — more specific handler runs first
await page.route('**/api/products', async route => {
  // Mock just the products endpoint
  await route.fulfill({
    status: 200,
    body: JSON.stringify({ items: [{ id: 1, name: 'Widget' }] }),
  });
  // NOTE: if this handler didn't exist, the '**/api/**' handler above would fire
});

// route.fallback() — delegate to the next matching handler
// Useful when you want to log/inspect but not intercept:
await page.route('**/api/**', async route => {
  console.log(`[DEBUG] API call: ${route.request().url()}`);
  await route.fallback();  // let the next handler (or real network) handle it
});
```

**`page.unrouteAll()` — clean up ALL route handlers at once:**

```typescript
// After a test that sets up many routes, clear them all
test.afterEach(async ({ page }) => {
  await page.unrouteAll({ behavior: 'ignoreErrors' });
  // behavior: 'wait' (default) — waits for pending handlers to complete
  // behavior: 'ignoreErrors' — clears immediately, ignores in-flight handler errors
});
```

**`page.unroute(url, handler)` — remove a specific handler:**

```typescript
const mockHandler = async (route: import('@playwright/test').Route) => {
  await route.fulfill({ status: 429, body: 'Rate limited' });
};

// Register mock
await page.route('**/api/search', mockHandler);

// ... test the rate-limited state ...

// Remove just this handler — other route handlers remain active
await page.unroute('**/api/search', mockHandler);

// Now /api/search requests pass through to the real network
```

> Routes registered via `page.route()` persist for the lifetime of the page — they don't
> automatically clean up between tests. If your test registers a route and the next test
> on the same page doesn't expect it, the mock bleeds through. Use `page.unrouteAll()` in
> `afterEach` for shared page fixtures, or prefer test-scoped pages (the default) where each
> test gets a fresh page with no inherited routes. [community]

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

### `{ box: true }` — Reduce Fixture Noise in Reports

Use `{ box: true }` on utility fixtures that are called from every test but add no diagnostic value to the HTML report. Boxed fixtures show as a single collapsed step rather than expanding all their internal steps.

```typescript
// e2e/fixtures/auth.ts — boxed fixture: report shows "auth" not all inner steps
import { test as base } from '@playwright/test';
import path from 'path';

type AuthFixtures = { authenticatedPage: import('@playwright/test').Page };

export const test = base.extend<AuthFixtures>({
  authenticatedPage: [async ({ browser }, use) => {
    const context = await browser.newContext({
      storageState: path.join(__dirname, '../.auth/user.json'),
    });
    const page = await context.newPage();
    await use(page);
    await context.close();
  }, { box: true }],  // hides internal steps from HTML report; reduces noise
});

// Without { box: true }: report shows "browser.newContext()", "browser.newPage()", etc.
// With { box: true }:    report shows a single "authenticatedPage" step — cleaner
```

**When to use `{ box: true }`:**
- Fixtures that run for every test but are not interesting to debug (auth setup, theme injection)
- Fixtures with many internal steps that clutter the report for passing tests
- Third-party integration fixtures where internal details are irrelevant to your tests

> `{ box: true }` is purely cosmetic — it does not change execution behavior. The fixture still runs identically; only its report representation changes. Do NOT use it on fixtures you actively need to debug. [community]

---

### Fixture Timeout Configuration

Slow fixture setup (database migrations, server starts) can consume the test's total timeout budget before the test body even runs. Set an explicit `timeout` on slow fixtures to give them extra time without extending the global test timeout.

```typescript
// e2e/fixtures/db.ts — give slow DB fixture its own timeout budget
import { test as base } from '@playwright/test';

export const test = base.extend<{}, { dbMigration: void }>({
  dbMigration: [async ({ request }, use) => {
    // This migration takes 20–40 seconds on a cold CI runner
    const res = await request.post('/api/test/migrate', {
      data: { fresh: true },
    });
    if (!res.ok()) throw new Error(`Migration failed: ${res.status()}`);
    await use();
    await request.post('/api/test/rollback');
  }, {
    scope:   'worker',
    auto:    true,
    timeout: 60_000,  // 60s fixture timeout, independent of the 30s test timeout
  }],
});
```

**Timeout interaction rules:**
- The fixture `timeout` is the max time for setup + `await use()` + teardown combined.
- If the fixture `timeout` exceeds the test `timeout`, Playwright uses the test `timeout` as the effective cap.
- Set `timeout: 0` to disable the fixture timeout entirely (use with caution — hangs won't abort).
- The fixture timeout does NOT extend the test's assertion timeout (`expect.timeout`).

```typescript
// playwright.config.ts — give all worker fixtures extra time via global setting
export default defineConfig({
  timeout:        30_000,  // test assertion budget
  use: {
    actionTimeout: 10_000, // per-action (click/fill) timeout
  },
  // Note: per-fixture timeout overrides are set in test.extend(), not here
});
```

> A common CI failure is "Test timeout of 30000ms exceeded" where the test body runs
> fine locally but times out in CI because the `beforeAll` fixture migration takes 25s.
> Adding `timeout: 60_000` to the fixture gives it its own budget without bloating every
> test's global timeout. [community]

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

**Drag-and-drop:**
```typescript
// Basic drag — locator-to-locator
await page.getByRole('listitem', { name: 'Task A' })
  .dragTo(page.getByRole('listitem', { name: 'Done column' }));

// Advanced drag with custom source/target positions and interpolated steps
// Use steps > 1 when the drag handler listens for mousemove events (e.g., Sortable.js, react-dnd)
await page.getByTestId('card-1').dragTo(page.getByTestId('column-done'), {
  sourcePosition: { x: 50, y: 10 },  // click point within source element
  targetPosition: { x: 150, y: 50 }, // drop point within target element
  steps:          10,                 // emit 10 intermediate mousemove events
});

// Low-level pointer events — for drag handlers that require specific event sequences
await page.getByTestId('draggable').hover();
await page.mouse.down();
await page.mouse.move(300, 400, { steps: 5 });
await page.mouse.up();
```

> Use `steps > 1` (or the `steps` option on `dragTo`) when a drag-and-drop widget requires
> multiple `mousemove` events to update its internal state. Without intermediate steps, the
> drop target may not register the drag correctly. Test with `steps: 5` as a starting point
> and increase if the drop still fails. [community]

> Drag-and-drop tests are among the most browser-specific tests. Use `test.skip(browserName !== 'chromium', '...')` for drag tests that rely on Chromium-specific pointer event behavior. [community]

> Register dialog handlers with `page.once()` for one-shot dialogs and `page.on()` for recurring
> dialogs. Never register both — duplicate handlers cause double-accept/dismiss bugs. [community]

---

### `page.exposeFunction()` and `page.evaluate()` — Cross-Boundary Testing

Use `exposeFunction()` to make Node.js functions available inside the browser page, and `evaluate()` to run code in the browser context and return the result to your test.

**`exposeFunction()` use cases:**

```typescript
// 1. Expose a server-side crypto function to test client-side hash comparisons
import crypto from 'node:crypto';

test('displays correct hash', async ({ page }) => {
  await page.exposeFunction('sha256', (text: string) =>
    crypto.createHash('sha256').update(text).digest('hex')
  );

  await page.goto('/profile');
  // The page can now call window.sha256() — e.g., from an onclick handler
  const displayedHash = await page.locator('[data-testid="hash"]').textContent();
  const expectedHash  = await page.evaluate(() =>
    (window as any).sha256('expected-input')
  );
  expect(displayedHash).toBe(expectedHash);
});

// 2. Record calls from app code back to the test
test('records analytics events', async ({ page }) => {
  const events: string[] = [];
  await page.exposeFunction('__recordAnalytics', (event: string) => {
    events.push(event);
  });

  await page.addInitScript(() => {
    // Intercept analytics calls before page scripts load
    (window as any).__analytics_send = (event: string) => {
      (window as any).__recordAnalytics(event);
    };
  });

  await page.goto('/dashboard');
  await page.getByRole('button', { name: 'Export' }).click();
  expect(events).toContain('export_clicked');
});
```

**`page.evaluate()` for browser state inspection:**

```typescript
// Inspect non-serializable browser state (LocalStorage, window vars, DOM)
test('feature flag is active', async ({ page }) => {
  await page.goto('/app');
  const flags = await page.evaluate(() => ({
    betaFeature:    !!(window as any).__FEATURES__?.betaFeature,
    userId:         localStorage.getItem('userId'),
    sessionActive:  document.cookie.includes('session='),
  }));
  expect(flags.betaFeature).toBe(true);
  expect(flags.userId).toBeTruthy();
});

// Pass arguments to avoid string interpolation (prevents XSS-style injection in tests)
test('computes correct discount', async ({ page }) => {
  const price    = 100;
  const discount = 0.2;
  const result = await page.evaluate(
    ([p, d]) => (p * (1 - d)).toFixed(2),
    [price, discount] as [number, number]
  );
  expect(result).toBe('80.00');
});

// Use evaluateHandle() for non-serializable return values
test('modifies DOM element directly', async ({ page }) => {
  await page.goto('/');
  const bodyHandle = await page.evaluateHandle(() => document.body);
  const classList  = await page.evaluate(body => [...body.classList], bodyHandle);
  expect(classList).toContain('app-loaded');
  await bodyHandle.dispose(); // always dispose handles to avoid memory leaks
});
```

> Pass arguments to `evaluate()` as the second parameter — never interpolate them into the
> function string. String interpolation breaks with special characters and is harder to type-check.
> Use `evaluateHandle()` for DOM elements and dispose the handle when done. [community]

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

**`{ box: true }` on steps — clean stack traces in Page Objects:**

When a step throws, by default the error points to the line inside the step body. With `{ box: true }`, the error points to the call site (where the step was called from) — which is usually more useful when the step is a helper function called from many tests.

```typescript
// e2e/pages/CheckoutPage.ts — box: true makes errors point to the test, not the POM internals
export class CheckoutPage {
  constructor(private readonly page: Page) {}

  async fillPaymentDetails(card: { number: string; expiry: string; cvv: string }) {
    return test.step('fill payment details', async () => {
      const frame = this.page.frameLocator('iframe[title="Payment"]');
      await frame.getByLabel('Card number').fill(card.number);
      await frame.getByLabel('Expiry').fill(card.expiry);
      await frame.getByLabel('CVV').fill(card.cvv);
    }, { box: true });  // Error: "at CheckoutPage.fillPaymentDetails" not "at frame.getByLabel"
  }
}
```

**`@step` decorator for Page Object methods** — automatically wraps every method in a named test step for trace readability:

```typescript
// e2e/utils/step-decorator.ts — reusable @step decorator
import { test } from '@playwright/test';

export function step(target: Function, context: ClassMethodDecoratorContext) {
  return function (this: unknown, ...args: unknown[]) {
    const stepName = `${(this as any).constructor?.name}.${String(context.name)}`;
    return test.step(stepName, () => target.call(this, ...args), { box: true });
  };
}

// e2e/pages/LoginPage.ts — every @step method shows in trace
import { step } from '../utils/step-decorator';
import { type Page, type Locator } from '@playwright/test';

export class LoginPage {
  readonly emailInput:    Locator;
  readonly passwordInput: Locator;
  readonly submitButton:  Locator;

  constructor(private readonly page: Page) {
    this.emailInput    = page.getByLabel(/email/i);
    this.passwordInput = page.getByLabel(/password/i);
    this.submitButton  = page.getByRole('button', { name: /sign in/i });
  }

  @step
  async goto() {
    await this.page.goto('/login');
  }

  @step
  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
}
// Trace shows: "LoginPage.goto", "LoginPage.login" — not raw Playwright actions
```

> The `@step` decorator requires TypeScript 5.0+ (Stage 3 decorators) and `experimentalDecorators: false`
> in `tsconfig.json` (use the new non-experimental decorator syntax). The `{ box: true }` option
> makes errors point to the test's call to `login()` rather than the line inside `login()` that failed — much easier to diagnose. [community]

> The decorator pattern eliminates the boilerplate of wrapping every POM method in `test.step()` manually. Add it to any method you want to see in traces and reports. [community]

---

### `testStepInfo.titlePath` — Full Step Hierarchy in Custom Reporters (v1.55+)

`testStepInfo.titlePath` exposes the full breadcrumb path from the test title down to the current step. Useful when building custom reporters that need to identify which specific step within a nested POM call chain produced a failure.

```typescript
// e2e/reporters/step-breadcrumb-reporter.ts
import type { Reporter, TestCase, TestResult, TestStep } from '@playwright/test/reporter';

class StepBreadcrumbReporter implements Reporter {
  onStepEnd(test: TestCase, result: TestResult, step: TestStep) {
    if (step.error) {
      // titlePath: ['Test title', 'beforeEach hook', 'CheckoutPage.fill', 'fill payment details']
      const breadcrumb = step.titlePath().join(' > ');
      console.error(`STEP FAIL: ${breadcrumb}`);
      console.error(`  Error: ${step.error.message}`);
    }
  }
}

export default StepBreadcrumbReporter;
```

```typescript
// playwright.config.ts — use in combination with default reporter
reporter: [
  ['list'],
  ['./e2e/reporters/step-breadcrumb-reporter.ts'],
],
```

> `titlePath` is especially valuable when POM methods call helper steps: the breadcrumb
> shows the full call chain, not just the innermost step name. Without it, nested step
> failures from `@step`-decorated POM methods show a step name without context. [community]

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

**`component.update()` — reactive prop/slot changes after mount:**

```typescript
// Update props after mount to test reactive re-renders
test('button reflects updated label', async ({ mount }) => {
  const component = await mount(<Button label="Save" />);
  await expect(component).toContainText('Save');

  // Update props without unmounting — triggers re-render
  await component.update(<Button label="Saved!" disabled />);
  await expect(component).toContainText('Saved!');
  await expect(component).toBeDisabled();
});
```

**`component.unmount()` — verify cleanup and teardown behavior:**

```typescript
// Test that unmounting triggers expected cleanup (e.g., "unsaved changes" dialog)
test('warns before unmounting with unsaved changes', async ({ mount }) => {
  const component = await mount(<EditForm />);
  await component.getByLabel('Title').fill('Draft');

  // Trigger unmount and catch the browser confirm dialog
  page.on('dialog', async dialog => {
    expect(dialog.message()).toContain('unsaved');
    await dialog.dismiss();
  });
  await component.unmount();
});
```

**Component testing constraints:**
- Cannot pass complex live objects (e.g., class instances, functions with closures) as props — use plain data and callbacks
- Component tests run in a sandboxed Vite/Webpack server, not your app's dev server
- Use `hooksConfig` to pass routing/provider configuration per-test without mounting wrapper components in every spec
- Module-level mocks (`vi.mock()`, `jest.mock()`) run in the test process (Node.js), not in the browser sandbox where the component executes — use the `router` fixture or `beforeMount`/`afterMount` hooks for browser-side mocking [community]
- Component testing may **reuse the browser context and page between tests** as a performance optimization — always reset `localStorage`, cookies, and singleton services in `beforeMount` hooks, not just in test-level setup [community]

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

### Post-Facto Inspection: `consoleMessages()`, `pageErrors()`, `requests()` (v1.56+)

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

---

### HTTP Basic Auth, Custom Headers, and Proxy Configuration

Common configuration-level network options that apply to all pages in every test.

**HTTP Basic Authentication** — for internal tools or staging environments behind Basic Auth:

```typescript
// playwright.config.ts — global HTTP Basic Auth
import { defineConfig } from '@playwright/test';

export default defineConfig({
  use: {
    httpCredentials: {
      username: process.env.STAGING_USER!,
      password: process.env.STAGING_PASS!,
    },
  },
});

// Per-context override for tests requiring different credentials
test('accesses admin endpoint', async ({ browser }) => {
  const context = await browser.newContext({
    httpCredentials: { username: 'admin', password: process.env.ADMIN_PASS! },
  });
  const page = await context.newPage();
  await page.goto('/admin');
  await expect(page.getByRole('heading', { name: 'Admin' })).toBeVisible();
  await context.close();
});
```

> `httpCredentials` handles standard HTTP 401 Basic Auth challenges — not app-level login forms.
> Use `storageState` for app-level authentication. [community]

**`extraHTTPHeaders` for API token injection** — authenticate all browser requests with a static token without a login flow:

```typescript
// playwright.config.ts — inject auth header for all requests
export default defineConfig({
  use: {
    extraHTTPHeaders: {
      Authorization: `Bearer ${process.env.E2E_API_TOKEN}`,
      'X-Test-Environment': 'playwright',  // useful for server-side filtering
    },
  },
});

// Per-test override when a specific test needs a different token
test('viewer cannot access admin endpoint', async ({ browser }) => {
  const context = await browser.newContext({
    extraHTTPHeaders: {
      Authorization: `Bearer ${process.env.VIEWER_TOKEN}`,
    },
  });
  const page = await context.newPage();
  await page.goto('/admin/settings');
  await expect(page.getByText('Access denied')).toBeVisible();
  await context.close();
});
```

**Self-signed certificates (`ignoreHTTPSErrors`)** — for staging environments using self-signed TLS:

```typescript
// playwright.config.ts — bypass cert validation for staging
export default defineConfig({
  use: {
    // Only for environments using self-signed certs (staging, local HTTPS dev server)
    ignoreHTTPSErrors: process.env.TEST_ENV === 'staging',
  },
});
```

> Never set `ignoreHTTPSErrors: true` unconditionally in production test configs. Gate it on
> the environment — it should only apply to known-self-signed staging environments. [community]

**Corporate proxy** — required when CI runners are behind a proxy for external requests:

```typescript
// playwright.config.ts — proxy configuration for CI runners
export default defineConfig({
  use: {
    proxy: process.env.HTTP_PROXY
      ? {
          server:  process.env.HTTP_PROXY,
          bypass:  process.env.NO_PROXY ?? 'localhost,127.0.0.1',
        }
      : undefined,
  },
});
```

> Use environment variables for proxy config so the same `playwright.config.ts` works both locally
> (where no proxy is needed) and on corporate CI runners (where all outbound traffic routes
> through a proxy). [community]

**`--no-deps` CLI flag** — run a specific project without triggering its setup dependencies:

```bash
# Normal run: setup runs first, then chromium tests
npx playwright test --project=chromium

# Skip setup (e.g., DB was already seeded manually): run chromium tests directly
npx playwright test --project=chromium --no-deps

# Useful when:
# - Debugging a specific test against an already-seeded database
# - Running only visual tests without re-triggering the auth setup project
# - Iterating quickly on a test file where setup is irrelevant
```

> `--no-deps` is a development-time tool, not a CI shortcut. On CI, always run with full
> dependencies to ensure the environment state is correct. Silently skipping setup in CI
> leads to false passes when the test relies on data seeded by the skipped project. [community]

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

---

### Data-Driven Tests and Parameterized Projects

**`forEach`-based parametrized tests** — run the same test logic against multiple inputs:

```typescript
// e2e/specs/greetings.spec.ts — data-driven with named test variations
const testCases = [
  { locale: 'en-US', greeting: 'Hello', url: '/en' },
  { locale: 'de-DE', greeting: 'Hallo', url: '/de' },
  { locale: 'fr-FR', greeting: 'Bonjour', url: '/fr' },
] as const;

testCases.forEach(({ locale, greeting, url }) => {
  test(`shows correct greeting for ${locale}`, async ({ page }) => {
    await page.goto(url);
    await expect(page.getByRole('heading', { level: 1 })).toHaveText(greeting);
  });
});
```

**Loading test data from external JSON fixtures:**

```typescript
// e2e/fixtures/checkout-cases.json
// [{ "product": "Widget", "qty": 2, "total": "19.98" }, ...]

// e2e/specs/checkout.spec.ts
import fs   from 'node:fs';
import path from 'node:path';

const cases = JSON.parse(
  fs.readFileSync(path.join(__dirname, '../fixtures/checkout-cases.json'), 'utf8')
) as Array<{ product: string; qty: number; total: string }>;

test.describe('Checkout totals', () => {
  cases.forEach(({ product, qty, total }) => {
    test(`${product} × ${qty} = ${total}`, async ({ page }) => {
      await page.goto(`/products/${product.toLowerCase()}`);
      await page.getByLabel('Quantity').fill(String(qty));
      await page.getByRole('button', { name: 'Add to cart' }).click();
      await page.goto('/cart');
      await expect(page.getByTestId('cart-total')).toHaveText(total);
    });
  });
});
```

**Parameterized fixture options via `projects`** — run the same suite with different user roles or environments:

```typescript
// e2e/fixtures/options.ts — declare a typed custom option
import { test as base } from '@playwright/test';

export type TestOptions = {
  userRole: 'admin' | 'viewer' | 'editor';
};

export const test = base.extend<TestOptions>({
  userRole: ['viewer', { option: true }],  // default; overridden per project
});

// playwright.config.ts — three projects, each with a different role
import { defineConfig } from '@playwright/test';
import { TestOptions } from './e2e/fixtures/options';

export default defineConfig<TestOptions>({
  projects: [
    {
      name: 'admin-tests',
      use: { userRole: 'admin' },
      testMatch: /specs\/.*\.spec\.ts/,
    },
    {
      name: 'viewer-tests',
      use: { userRole: 'viewer' },
      testMatch: /specs\/.*\.spec\.ts/,
    },
  ],
});

// e2e/specs/permissions.spec.ts — test uses the injected role
import { test, expect } from '../fixtures/options';

test('delete button visibility depends on role', async ({ page, userRole }) => {
  await page.goto('/items');
  const deleteBtn = page.getByRole('button', { name: 'Delete' });
  if (userRole === 'admin') {
    await expect(deleteBtn).toBeVisible();
  } else {
    await expect(deleteBtn).toBeHidden();
  }
});
```

> The `{ option: true }` flag marks a fixture as a project-level configuration option rather
> than a regular fixture. This lets `playwright.config.ts` set it in `use: {}`, whereas
> regular fixtures can only be overridden with `test.use()`. [community]

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

### `locator.pressSequentially()` — Typeahead and Autocomplete Testing

`locator.fill()` sets the full value atomically (bypasses `input` events if the control uses them for filtering). Use `locator.pressSequentially()` when the field needs character-by-character `keydown`/`keypress`/`keyup` events — e.g., autocomplete dropdowns, masked inputs, or OTP fields.

```typescript
// e2e/specs/autocomplete.spec.ts
import { test, expect } from '../fixtures/pages';

test('autocomplete shows matching suggestions', async ({ page }) => {
  await page.goto('/search');

  const searchBox = page.getByRole('combobox', { name: 'Search' });

  // Type character-by-character to trigger autocomplete events
  await searchBox.pressSequentially('Pla', { delay: 50 });  // 50 ms between keystrokes

  const suggestions = page.getByRole('option');
  await expect(suggestions).toHaveCount.greaterThan(0);
  await expect(suggestions.first()).toContainText('Playwright');
  await suggestions.first().click();

  await expect(searchBox).toHaveValue('Playwright');
});

test('OTP field accepts digit-by-digit entry', async ({ page }) => {
  await page.goto('/verify');

  const otpField = page.getByLabel('One-time code');

  // OTP fields often listen to keydown to advance focus — fill() won't trigger this
  await otpField.pressSequentially('123456');
  await expect(page.getByRole('button', { name: 'Verify' })).toBeEnabled();
});
```

```typescript
// When to use pressSequentially vs fill:
// ┌──────────────────────────────────────────────┬────────────────┬─────────────────────┐
// │ Scenario                                      │ fill()         │ pressSequentially() │
// ├──────────────────────────────────────────────┼────────────────┼─────────────────────┤
// │ Simple text input (no event listeners)        │ ✓ preferred    │ unnecessary         │
// │ Autocomplete that filters on each character   │ ✗ may not fire │ ✓ required          │
// │ Masked input (phone, credit card)             │ ✗ sets raw val │ ✓ triggers masking  │
// │ OTP / split digit fields                      │ ✗              │ ✓ required          │
// └──────────────────────────────────────────────┴────────────────┴─────────────────────┘
```

> Use `{ delay: 50 }` with `pressSequentially()` when the application debounces input events. Without a delay the keystrokes arrive faster than the debounce window and the autocomplete never fires. 50 ms is a safe default; match your app's debounce setting. [community]

> `locator.clear()` clears the current value of an input without typing. Prefer it over `fill('')` when the field has a `change` event listener that should fire on clearing but not on every keystroke. [community]

---

### `locator.all()` — Iterate Over a Dynamic Set of Matches

`locator.all()` returns a JavaScript `Promise<Locator[]>` — a snapshot of all elements currently matching the locator. Use it when you need to iterate over an unknown number of elements and perform per-element assertions or actions. Unlike `locator.nth()`, it does not retry; resolve it after the list is stable.

```typescript
test('all table rows have a status badge', async ({ page }) => {
  await page.goto('/orders');
  await expect(page.getByRole('table')).toBeVisible(); // wait for table to render

  const rows = await page.getByRole('row').all();      // snapshot — call after list is stable
  // Skip header row (index 0)
  for (const row of rows.slice(1)) {
    await expect(row.getByRole('cell').nth(3)).toContainText(/active|pending|closed/i);
  }
});
```

```typescript
test('collect all error messages from a multi-field form', async ({ page }) => {
  await page.goto('/signup');
  await page.getByRole('button', { name: 'Create account' }).click();

  const errors = await page.getByRole('alert').all();
  expect(errors.length).toBeGreaterThan(0);

  const errorTexts = await Promise.all(errors.map(e => e.textContent()));
  expect(errorTexts).toContain('Email is required');
  expect(errorTexts).toContain('Password is required');
});
```

```typescript
// allTextContents() and allInnerTexts() — shorthand when you only need the text values
const tagTexts = await page.getByRole('listitem').allTextContents();
expect(tagTexts).toEqual(expect.arrayContaining(['TypeScript', 'Playwright']));
```

> `locator.all()` does **not** wait for elements to appear. Call it only after a web-first assertion (`toBeVisible`, `toHaveCount`) confirms the list is fully rendered. Using `all()` on an empty DOM returns `[]` immediately with no retry. [community]

---

### `locator.filter({ hasNot, hasNotText })` — Exclusion Filtering

`filter()` accepts `hasNot` and `hasNotText` in addition to `has` and `hasText`, letting you exclude elements from a match set without chaining multiple locators.

```typescript
test('only incomplete tasks are shown in active view', async ({ page }) => {
  await page.goto('/tasks?filter=active');

  // All list items that do NOT contain a completed checkbox
  const incompleteTasks = page.getByRole('listitem').filter({
    hasNot: page.getByRole('checkbox', { checked: true }),
  });
  // Every visible task should be incomplete
  await expect(incompleteTasks).toHaveCount(await page.getByRole('listitem').count());
});
```

```typescript
test('dashboard cards exclude archived items', async ({ page }) => {
  await page.goto('/dashboard');

  const activeCards = page
    .getByRole('article')
    .filter({ hasNotText: 'Archived' });  // exclude cards showing "Archived" label

  for (const card of await activeCards.all()) {
    await expect(card).not.toContainText('Archived');
  }
});
```

```typescript
// Combine has + hasNot to target a precise subset
const urgentNotAssigned = page
  .getByRole('listitem')
  .filter({ hasText: 'Urgent' })
  .filter({ hasNot: page.getByRole('img', { name: /avatar/ }) });
```

> `hasNot` takes a locator (element exists check). `hasNotText` takes a string or regex (text content check). Both are the logical inverses of their positive counterparts and compose naturally in chains. [community]

---

### `toHaveCSS()` and `toBeInViewport()` — Style and Visibility Assertions

Two web-first assertions that cover common gaps: verifying computed CSS properties and checking whether an element is currently scrolled into the viewport.

```typescript
// toHaveCSS — assert computed CSS property/value pairs
test('primary button uses brand color', async ({ page }) => {
  await page.goto('/');
  const button = page.getByRole('button', { name: 'Get started' });

  // Asserts the computed style value (not inline style attribute)
  await expect(button).toHaveCSS('background-color', 'rgb(37, 99, 235)');
  await expect(button).toHaveCSS('border-radius', /[0-9]+px/);
});

test('error message is visible with correct color', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel(/email/i).fill('bad@example.com');
  await page.getByLabel(/password/i).fill('wrong');
  await page.getByRole('button', { name: /sign in/i }).click();

  const alert = page.getByRole('alert');
  await expect(alert).toBeVisible();
  await expect(alert).toHaveCSS('color', 'rgb(220, 38, 38)');  // red-600
});
```

```typescript
// toBeInViewport — assert that element is visible within the scroll area
test('back-to-top button appears after scrolling down', async ({ page }) => {
  await page.goto('/long-page');

  const backToTop = page.getByRole('button', { name: 'Back to top' });
  await expect(backToTop).not.toBeInViewport();

  await page.keyboard.press('End');  // scroll to bottom

  await expect(backToTop).toBeInViewport();
});

test('sticky header remains in viewport while scrolling', async ({ page }) => {
  await page.goto('/');
  const header = page.getByRole('banner');

  await expect(header).toBeInViewport();
  await page.evaluate(() => window.scrollBy(0, 1000));
  await expect(header).toBeInViewport();  // sticky — should still be visible
});
```

> `toHaveCSS()` checks the **computed** CSS value, not the inline `style` attribute. RGB notation is the most reliable form — browsers normalize hex (`#2563eb`) to `rgb(37, 99, 235)`. Use `toHaveAttribute('style', /.../)` instead when checking raw inline styles. [community]

> `toBeInViewport({ ratio: 0.5 })` accepts an optional `ratio` parameter (0–1) specifying what fraction of the element must be in the viewport for the assertion to pass. Useful for large elements that extend beyond the screen. [community]

---

### `page.pdf()` — PDF Generation Testing

Test that `page.pdf()` produces a valid PDF (correct size, non-empty) for print-to-PDF workflows — invoices, reports, export features. Only works in Chromium headless.

```typescript
// e2e/specs/invoice-export.spec.ts
import { test, expect } from '../fixtures/pages';
import fs from 'fs';

test('invoice export produces a valid PDF', async ({ page }) => {
  await page.goto('/invoices/INV-2025-001');
  await expect(page.getByRole('heading', { name: 'Invoice INV-2025-001' })).toBeVisible();

  const pdfBuffer = await page.pdf({
    format:          'A4',
    printBackground: true,  // include background colors/images (CSS print media)
    margin:          { top: '20mm', right: '15mm', bottom: '20mm', left: '15mm' },
  });

  // Basic validity check — PDF files start with %PDF-
  expect(pdfBuffer.length).toBeGreaterThan(1000);
  expect(pdfBuffer.subarray(0, 5).toString()).toBe('%PDF-');

  // Optionally save for manual inspection on failure
  const outPath = `test-results/invoice-${Date.now()}.pdf`;
  fs.writeFileSync(outPath, pdfBuffer);
});
```

```typescript
// Test the print stylesheet separately before generating PDF
test('invoice print layout hides navigation', async ({ page }) => {
  await page.goto('/invoices/INV-2025-001');

  // Apply print media query — easier to assert UI than parsing the PDF binary
  await page.emulateMedia({ media: 'print' });

  await expect(page.getByRole('navigation')).toBeHidden();
  await expect(page.getByRole('heading', { name: 'Invoice' })).toBeVisible();
  await expect(page.getByText('Total due:')).toBeVisible();
});
```

> `page.pdf()` is only available in Chromium; skip on Firefox and WebKit projects:
> `test.skip(browserName !== 'chromium', 'PDF generation is Chromium-only')`.
> Test the print **layout** (CSS `@media print`) with `page.emulateMedia({ media: 'print' })` in all browsers; generate the actual PDF only in Chromium. [community]

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
  globalTimeout:    process.env.CI ? 60 * 60 * 1_000 : undefined, // 1 hr hard stop for entire run
  reportSlowTests:  process.env.CI ? { max: 5, threshold: 60_000 } : null, // flag top-5 slow tests in terminal
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
await locator.pressSequentially('value', { delay: 50 }); // keystroke-by-keystroke (autocomplete/OTP)
await locator.clear();                                    // clear without typing
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
await expect(locator).toHaveCSS('color', 'rgb(37, 99, 235)');   // computed CSS value
await expect(locator).toBeInViewport();                          // element is scrolled into view
await expect(locator).toBeInViewport({ ratio: 0.5 });           // at least 50% visible
await expect(page).toHaveURL(/pattern/);
await expect(page).toHaveTitle(/pattern/);

// Scoping / filtering
page.getByRole('dialog').getByRole('button', { name: 'Close' })
page.getByRole('listitem').filter({ hasText: 'Buy milk' })
page.getByRole('listitem').filter({ hasNot: page.getByRole('checkbox', { checked: true }) })
page.getByRole('listitem').filter({ hasNotText: 'Archived' })
page.getByRole('row').nth(1)

// Iterate over all matching elements (snapshot — call after list is stable)
const items = await page.getByRole('listitem').all();
const texts = await page.getByRole('listitem').allTextContents();

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

---

## Codegen & Test Recording

### Using `npx playwright codegen` (CLI Inspector)

Playwright's built-in codegen tool records browser interactions and emits TypeScript test code. Use it for bootstrap — always review and refine the output. The inspector prioritizes `getByRole`, `getByLabel`, and `getByTestId` locators automatically.

```bash
# Start a recording session against localhost:3000
npx playwright codegen http://localhost:3000

# Start with an authenticated state already loaded
npx playwright codegen --load-storage=e2e/.auth/user.json http://localhost:3000

# Specify viewport to match your test configuration
npx playwright codegen --viewport-size=1280,720 http://localhost:3000

# Generate code in a specific language (Java, Python, C# also supported)
npx playwright codegen --target=playwright-test http://localhost:3000
```

**VS Code extension:** The Playwright VS Code extension adds a "Record new" button that inserts generated code at the cursor position in the currently open spec file — more ergonomic than CLI for incremental recording.

**Codegen limits — where human review is required:**
- Custom page route interceptions (`page.route(...)`) are not recorded; add them manually.
- Assertion toolbar lets you insert `expect` calls for visibility, text, and value — use it during recording.
- Dynamic values (timestamps, generated IDs) need to be replaced with regex matchers or test fixtures.
- As of Chrome 136+, the default user data directory cannot be used for codegen; always use `--load-storage` or a fresh profile. [community]

```typescript
// Example of generated code after manual refinement — original codegen uses getByRole by default
// Original generated (kept as-is — already good practice):
await page.getByRole('button', { name: 'Add to cart' }).click();
await expect(page.getByRole('alert')).toHaveText('Item added');

// Refine dynamic values (codegen captures exact strings — swap for regex where needed):
// Before: await expect(page.locator('.order-id')).toHaveText('ORD-1234567');
// After:
await expect(page.locator('[data-testid="order-id"]')).toHaveText(/^ORD-\d+$/);
```

> **[community]** WHY: Teams that run codegen recordings directly without refinement accumulate brittle hardcoded text strings. The recorder captures the exact text visible at recording time — prices, dates, usernames. These become instant failures in environments with different test data or in multi-locale setups. Treat codegen output as a scaffold: roles and labels are keepers, exact text content usually is not.

---

## E2E Coverage with `vite-plugin-istanbul`  [community]

Playwright tests do not collect code coverage by default because the browser runtime is separate from the test runner. Use `vite-plugin-istanbul` to instrument the app bundle, then collect coverage in `page.coverage` or via the Istanbul global.

```typescript
// vite.config.ts — instrument for coverage (only in test builds)
import istanbul from 'vite-plugin-istanbul';

export default defineConfig({
  plugins: [
    istanbul({
      include: 'src/*',
      exclude: ['node_modules', 'test/'],
      extension: ['.js', '.ts', '.tsx'],
      requireEnv: false,
      forceBuildInstrument: process.env.E2E_COVERAGE === 'true',
    }),
  ],
});
```

```typescript
// e2e/fixtures/coverage.ts — collect and merge coverage per test
import { test as base } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

export const test = base.extend<{}, { coverageDir: string }>({
  coverageDir: [async ({}, use) => {
    const dir = path.join(process.cwd(), '.nyc_output');
    fs.mkdirSync(dir, { recursive: true });
    await use(dir);
  }, { scope: 'worker' }],
});

// In your test, collect coverage after each scenario:
// const coverage = await page.evaluate(() => (window as any).__coverage__);
// fs.writeFileSync(path.join(coverageDir, `${testInfo.testId}.json`), JSON.stringify(coverage));
```

```bash
# Run with coverage instrumentation enabled
E2E_COVERAGE=true npx playwright test

# Merge coverage reports and generate HTML
npx nyc report --reporter=html --reporter=lcov

# View coverage
open coverage/index.html
```

> **[community]** WHY: E2E coverage reveals untested code paths that unit tests miss — especially dead feature flags, legacy fallback paths, and error-handling branches that only trigger under real user flows. Teams using Playwright + Istanbul report finding 15–30% of code paths only exercised by E2E tests. The `mxschmitt/playwright-test-coverage` repo provides a ready-made setup. [community]

**Gotchas:**
- Istanbul instrumentation increases bundle size significantly; only enable in `E2E_COVERAGE=true` builds, never in production.
- Coverage data lives in `window.__coverage__` — collect it in `afterEach` before navigation clears the page context.

---

## v1.60 New Patterns

### `locator.drop()` — External Drag-and-Drop Simulation (v1.60+)

Simulate external files or clipboard data being dropped onto an element. Previously, testing file-drop zones required complex `DataTransfer` injection via `page.evaluate()`. `locator.drop()` dispatches the correct synthetic drag events cross-browser.

```typescript
// Drop a file onto a file-upload dropzone
test('accepts PDF drop on upload zone', async ({ page }) => {
  await page.goto('/upload');

  const dropzone = page.getByRole('region', { name: 'Upload area' });
  await dropzone.drop({
    files: {
      name:     'report.pdf',
      mimeType: 'application/pdf',
      buffer:   Buffer.from('%PDF-1.4 test content'),
    },
  });

  await expect(page.getByText('report.pdf')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Upload' })).toBeEnabled();
});

// Drop multiple files at once
test('accepts multiple image drops', async ({ page }) => {
  await page.goto('/gallery');

  await page.getByTestId('image-dropzone').drop({
    files: [
      { name: 'photo1.jpg', mimeType: 'image/jpeg', buffer: fakeJpeg1 },
      { name: 'photo2.jpg', mimeType: 'image/jpeg', buffer: fakeJpeg2 },
    ],
  });

  await expect(page.getByRole('img')).toHaveCount(2);
});

// Drop clipboard text
test('accepts plain-text paste via drop', async ({ page }) => {
  await page.goto('/notes');

  await page.getByTestId('text-drop-target').drop({
    data: {
      'text/plain': 'Meeting notes for Q3 review',
      'text/html':  '<p>Meeting notes for <b>Q3 review</b></p>',
    },
  });

  await expect(page.getByRole('paragraph')).toContainText('Meeting notes');
});
```

> **[community]** WHY: Prior to v1.60, file-drop testing required manually constructing a `DataTransfer` object in `page.evaluate()` and dispatching `dragenter`/`drop` events — code that differed per browser engine and broke on Chromium security updates. `locator.drop()` uses Playwright's internal event pipeline, ensuring consistent behavior across Chromium, Firefox, and WebKit. Teams that relied on JS injection reported silent failures when browser security policies blocked synthetic DataTransfer construction. [community]

---

### `test.abort()` — Guard Rails in Route Handlers and Fixtures (v1.60+)

`test.abort()` immediately marks the current test as failed and stops execution. Use it inside `page.route()` handlers or fixtures to enforce test environment invariants — for example, preventing tests from writing to shared production resources.

```typescript
// Prevent tests from accidentally publishing to shared content
test('draft preview does not publish', async ({ page }) => {
  await page.route('**/api/publish', route => {
    test.abort('Test attempted to call /api/publish — use /api/draft instead.');
    return route.abort();
  });

  await page.goto('/editor');
  await page.getByRole('button', { name: 'Preview' }).click();
  await expect(page.getByRole('dialog', { name: 'Preview' })).toBeVisible();
});

// Enforce in a shared fixture to protect all tests in a suite
// e2e/fixtures/safe-env.ts
import { test as base } from '@playwright/test';

export const test = base.extend({
  page: async ({ page }, use) => {
    await page.route('**/api/send-email', route => {
      test.abort('Test called the real email API — mock it in your test via page.route().');
    });
    await use(page);
  },
});
```

> **[community]** WHY: `route.abort()` alone silently drops the network request, so the test continues running with missing data and may pass — masking the violation. `test.abort()` turns the silent bypass into an explicit failure with a clear message. Teams using shared staging environments use this pattern to prevent test-induced data corruption. [community]

---

### HAR Recording via `tracing.startHar()` / `stopHar()` (v1.60+)

HAR recording is now a first-class tracing operation. Pair it with `await using` for automatic cleanup, or call `stopHar()` manually when finer control is needed.

```typescript
// Auto-cleanup with async disposable (recommended)
test('network audit produces HAR', async ({ context }) => {
  // HAR recording scoped to this block — finalized when 'har' exits scope
  await using har = await context.tracing.startHar('test-results/audit.har');

  const page = await context.newPage();
  await page.goto('/dashboard');
  await page.getByRole('button', { name: 'Load data' }).click();
  await expect(page.getByRole('table')).toBeVisible();
  // HAR written automatically — no explicit stopHar() needed
});

// Manual control — use when you need to gate on the HAR path before tests
test('inspect redirect chain from HAR', async ({ context }) => {
  await context.tracing.startHar('test-results/redirects.har');
  const page = await context.newPage();

  await page.goto('/old-path');
  await expect(page).toHaveURL(/new-path/);

  await context.tracing.stopHar();
  // Parse the written HAR file for CI assertions
  const har = JSON.parse(fs.readFileSync('test-results/redirects.har', 'utf8'));
  const entries = har.log.entries.filter((e: any) => e.response.status >= 300 && e.response.status < 400);
  expect(entries.length).toBeGreaterThan(0);
});
```

> **[community]** WHY: The old `page.routeFromHAR()` replay API required a separately recorded HAR file managed outside Playwright's lifecycle. `tracing.startHar()` integrates recording into the tracing session, so HAR files are written to `test-results/` alongside traces and are automatically deleted by `--reporter=html` cleanup on next run. Using `await using` prevents HAR files from being left open/incomplete when a test throws mid-flight. [community]

---

### `getByRole()` with `description` Option (v1.60+)

`getByRole()` now accepts a `description` option that matches the element's accessible description (from `aria-describedby`, `aria-description`, or the `title` attribute). Use it to distinguish identically-named controls.

```typescript
// Two "Delete" buttons on the same page — disambiguate by description
test('deletes the correct item', async ({ page }) => {
  await page.goto('/dashboard');

  // Matches: <button aria-label="Delete" aria-describedby="delete-account-desc">
  const deleteAccountBtn = page.getByRole('button', {
    name:        'Delete',
    description: 'Permanently delete your account',
  });

  // Matches: <button aria-label="Delete" aria-describedby="delete-item-desc">
  const deleteItemBtn = page.getByRole('button', {
    name:        'Delete',
    description: 'Remove this item from the list',
  });

  await deleteItemBtn.click();
  await expect(page.getByRole('dialog', { name: 'Confirm deletion' })).toBeVisible();
  // Confirm the account button was NOT clicked — still present
  await expect(deleteAccountBtn).toBeVisible();
});
```

> **[community]** WHY: Pages with repetitive action verbs ("Edit", "Delete", "View") used to require `nth()` index selectors or wrapper scoping with `.filter()`. Index selectors are position-dependent and fail when rows reorder. `description` targets semantic intent — the same information a screen reader user would hear — making tests accessible-first and more resilient. [community]

---

### `toHaveCSS()` with `pseudo` Option (v1.60+)

Assert computed CSS on pseudo-elements (`::before`, `::after`) without JavaScript evaluation workarounds.

```typescript
// Assert a custom checkbox uses a CSS ::before checkmark
test('checked checkbox shows correct icon', async ({ page }) => {
  await page.goto('/settings');

  const checkbox = page.getByRole('checkbox', { name: 'Enable notifications' });
  await checkbox.check();

  // Assert the ::before pseudo-element's content and color
  await expect(checkbox).toHaveCSS('content', '"✓"', { pseudo: '::before' });
  await expect(checkbox).toHaveCSS('color', 'rgb(37, 99, 235)', { pseudo: '::before' });
});

// Assert tooltip arrow rendered via ::after
test('tooltip arrow uses correct border color', async ({ page }) => {
  await page.goto('/help');
  await page.getByRole('button', { name: 'Help' }).hover();

  const tooltip = page.getByRole('tooltip');
  await expect(tooltip).toBeVisible();
  await expect(tooltip).toHaveCSS('border-color', 'transparent transparent rgb(30, 30, 30) transparent', {
    pseudo: '::after',
  });
});
```

> **[community]** WHY: `window.getComputedStyle(el, '::before').content` returns an empty string in modern browsers when called from JavaScript (it's a browser security restriction for pseudo-elements). Teams testing design systems with CSS-generated content icons were forced to use visual regression screenshots for these assertions. `pseudo` option gives deterministic, pixel-exact CSS assertions without screenshot diffing noise. [community]

---

### `browser.on('context')` and BrowserContext Lifecycle Events (v1.60+)

`browser.on('context')` fires whenever a new browser context is created (including popup windows that create an implicit context). BrowserContext now mirrors page-level events (`download`, `frameattached`, `framedetached`, `framenavigated`, `pageclose`, `pageload`) so you can monitor all activity in a context from one listener.

```typescript
// Audit all contexts and their page lifecycle in a test fixture
// e2e/fixtures/context-audit.ts
import { test as base } from '@playwright/test';

export const test = base.extend({
  browser: async ({ browser }, use, testInfo) => {
    const contextLog: string[] = [];

    browser.on('context', ctx => {
      contextLog.push(`context-created`);

      ctx.on('pageload',  page => contextLog.push(`pageload:${page.url()}`));
      ctx.on('pageclose', page => contextLog.push(`pageclose:${page.url()}`));
      ctx.on('download',  dl  => contextLog.push(`download:${dl.suggestedFilename()}`));
    });

    await use(browser);

    // Attach lifecycle log to test report for debugging
    await testInfo.attach('context-lifecycle', {
      contentType: 'text/plain',
      body: contextLog.join('\n'),
    });
  },
});

// Monitor popup contexts in multi-tab flows
test('OAuth popup completes and closes', async ({ page, context }) => {
  const closedPages: string[] = [];
  context.on('pageclose', page => closedPages.push(page.url()));

  const [popup] = await Promise.all([
    context.waitForEvent('page'),
    page.getByRole('button', { name: 'Sign in with Google' }).click(),
  ]);

  await popup.getByLabel('Email').fill('user@example.com');
  await popup.getByRole('button', { name: 'Next' }).click();
  await popup.waitForEvent('close');

  expect(closedPages.some(url => url.includes('accounts.google.com'))).toBe(true);
  await expect(page).toHaveURL(/dashboard/);
});
```

> **[community]** WHY: Before v1.60, debugging multi-context leaks (contexts not properly closed after popup flows) required manual `context.pages()` polling. The lifecycle events give real-time visibility into context activity and enable fixture-level audit logs — invaluable when debugging CI failures where popup OAuth flows leave ghost contexts that exhaust browser process limits. [community]

---

### `{testFileBaseName}` Token in `snapshotPathTemplate` (v1.60+)

Use `{testFileBaseName}` (test file name without extension) in `snapshotPathTemplate` to group snapshots by spec file. Previously only `{testFilePath}` (full relative path) was available.

```typescript
// playwright.config.ts — group snapshots alongside spec files by base name
export default defineConfig({
  snapshotPathTemplate: '{testDir}/__snapshots__/{testFileBaseName}-{arg}{ext}',
  // Results in: e2e/__snapshots__/dashboard-hero-1.png
  //             e2e/__snapshots__/dashboard-hero-2.png  (instead of long nested path)
});
```

> **[community]** WHY: The default `{testFilePath}` template embeds the full relative path including subdirectory names, producing deeply nested snapshot directories that are hard to navigate in IDEs. `{testFileBaseName}` flattens snapshots to a single `__snapshots__/` folder, making visual review and bulk regeneration easier. Teams with many spec files report the flat layout speeds up snapshot review by 40–60% in CI PR diffs. [community]

---

### `webSocketRoute.protocols()` — WebSocket Subprotocol Access (v1.60+)

When routing WebSocket connections, `webSocketRoute.protocols()` returns the array of subprotocols requested by the client in the `Sec-WebSocket-Protocol` header.

```typescript
// Assert the client requests the correct subprotocol
test('WS client negotiates graphql-ws protocol', async ({ page }) => {
  const requestedProtocols: string[] = [];

  await page.routeWebSocket('/graphql', route => {
    requestedProtocols.push(...route.protocols());
    // Accept the connection with the first matching protocol
    route.connect();
  });

  await page.goto('/');
  await page.getByRole('button', { name: 'Subscribe' }).click();

  expect(requestedProtocols).toContain('graphql-ws');
});
```

---

### Breaking Changes Reference Update (v1.60)

Append to the existing Breaking Changes Reference section:

| Version | Change |
|---------|--------|
| **v1.60** | `Locator.ariaRef()` removed. `handle` option on `BrowserContext.exposeBinding` / `Page.exposeBinding` removed. `logger` option on `BrowserType.connect` / `connectOverCDP` removed. Context options `videosPath` / `videoSize` removed — use `recordVideo: { dir, size }` instead. Config now rejects `workers: 0` or negative values at parse time. |

---

### 24. `videosPath` / `videoSize` context options removed in v1.60 cause silent misconfiguration [community]

**Root cause:** `videosPath` and `videoSize` were deprecated in favor of `recordVideo: { dir, size }` but were silently ignored rather than erroring. In v1.60 they are removed — config that passed these options no longer records video without any warning.

**Fix:** Replace both deprecated options with the `recordVideo` object form:

```typescript
// BEFORE (broken in v1.60):
const context = await browser.newContext({
  videosPath: 'test-videos/',
  videoSize:  { width: 1280, height: 720 },
});

// AFTER (correct):
const context = await browser.newContext({
  recordVideo: {
    dir:  'test-videos/',
    size: { width: 1280, height: 720 },
  },
});
```

> Teams upgrading to v1.60 who relied on `videosPath` for CI failure videos found they silently had no video artifacts after the upgrade because the deprecated keys were dropped without a runtime warning. Always pin `playwright` and `@playwright/test` to the same version in `package.json` to catch these in a controlled upgrade. [community]
- `page.coverage` (Chrome DevTools Protocol) collects V8 coverage and works without instrumentation, but reports line-level coverage without branch data. Use Istanbul for branch coverage. [community]

---

### 25. `locator.highlight()` requires `page.hideHighlight()` cleanup or highlights leak across tests [community]

**What:** Debug highlight overlays added with `locator.highlight()` persist on the page between test steps — and across tests when using a shared page fixture — causing visual noise in traces and screenshots.
**WHY:** `locator.highlight()` draws an overlay directly on the page DOM. Unlike `PWDEBUG` mode highlights that reset on navigation, these DOM-injected overlays survive page actions until explicitly removed.
**Fix:** Always call `page.hideHighlight()` after a highlighting session, or scope it with `try/finally`. Do not commit `locator.highlight()` calls — add them to ESLint `no-restricted-syntax` alongside `page.pause()`.

```typescript
// Debug usage pattern — NEVER commit to main
test('investigate locator', async ({ page }) => {
  await page.goto('/checkout');
  const submitBtn = page.getByRole('button', { name: 'Submit' });
  try {
    await submitBtn.highlight({ style: 'outline: 3px solid red' });
    // ... inspect visually in headed mode
  } finally {
    await page.hideHighlight();  // always clean up overlays
  }
});
```

---

### 26. `tracing.startHar()` HAR files missing responses when `urlFilter` is not set in large suites [community]

**What:** HAR files recorded in large test suites include hundreds of third-party requests (fonts, analytics, CDN assets), making them multi-megabyte files that slow down test result archiving and are unusable for replay.
**WHY:** `tracing.startHar()` without `urlFilter` records ALL network traffic including static assets and third-party requests that are irrelevant for replay tests.
**Fix:** Use `urlFilter` to restrict HAR recording to your API origin. Also set `mode: 'minimal'` to omit response bodies for assets you don't need to replay.

```typescript
// Focused HAR recording — only capture API calls, not static assets
test('network audit for checkout API', async ({ context }) => {
  await using har = await context.tracing.startHar('test-results/checkout-api.har', {
    urlFilter: /api\.example\.com/,  // only record requests to your API
    mode:      'full',               // 'full' (default) | 'minimal' (headers only, no body)
    content:   'attach',             // 'attach' (inline in HAR) | 'omit' | 'sha1' (reference)
  });

  const page = await context.newPage();
  await page.goto('/checkout');
  await page.getByRole('button', { name: 'Proceed to payment' }).click();
  await expect(page.getByText('Payment form')).toBeVisible();
  // HAR written automatically — only contains /api.example.com/* calls
});
```

---

### 27. `APIRequestContext.fetch`: "Request context disposed" when using `page.route()` after context close [community]

**What:** Tests that use `page.route()` to intercept requests and then call `route.fetch()` (to fetch the real response before modifying it) fail with `"Request context disposed"` after the browser context closes. This typically happens in `afterAll` or teardown hooks, or when the `request` fixture is used inside a `page.route()` handler that outlives the fixture scope.

**WHY:** `route.fetch()` uses the APIRequestContext associated with the browser context. If the browser context (or the `request` fixture) is disposed before the route handler completes — which can happen when a navigation triggers cleanup and the route is still pending — the context is gone.

**Fix:** Ensure `route.continue()` or `route.fulfill()` is always called and that route handlers do not hold references to the request context beyond the test's lifecycle. Use `{ noWaitAfter: false }` to synchronize cleanup.

```typescript
// WRONG: route handler referencing request after context may close
test.afterAll(async ({ request }) => {
  await request.delete('/api/test/cleanup');
});

page.route('**/api/**', async route => {
  const real = await route.fetch();        // MAY throw if context closed mid-flight
  const body = await real.json();
  await route.fulfill({ response: real, body: JSON.stringify({ ...body, patched: true }) });
});

// CORRECT: always guard route.fetch() and catch disposal errors
page.route('**/api/**', async route => {
  try {
    const real = await route.fetch();
    const body = await real.json();
    await route.fulfill({ response: real, body: JSON.stringify({ ...body, patched: true }) });
  } catch (err) {
    // Context disposed before route completed — just continue
    if (!route.request().isNavigationRequest()) {
      await route.continue().catch(() => {});
    }
  }
});
```

> Dispose `page.route()` handlers explicitly before teardown in long-lived browser
> contexts: `await page.unroute('**/api/**')`. This prevents handler callbacks from
> running after the context is cleaned up. [community]

---

### 28. `sessionStorage` cannot be persisted in `storageState` — use `addInitScript` workaround [community]

**What:** `context.storageState()` saves cookies, localStorage, and IndexedDB but silently skips `sessionStorage`. Apps that store auth tokens or feature flags in `sessionStorage` appear to lose state between test setup and actual tests.

**WHY:** `sessionStorage` is scoped to the tab lifetime and is intentionally excluded from the `storageState` serialization format. Even saving with `{ path }` and loading it back produces no `sessionStorage` entries.

**Fix:** Serialize `sessionStorage` with `page.evaluate()` after login and restore it with `page.addInitScript()` before navigation. This injects the values into `window.sessionStorage` synchronously before any page scripts run.

```typescript
// e2e/auth.setup.ts — serialize sessionStorage after UI login
setup('authenticate (sessionStorage)', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.E2E_USER_EMAIL!);
  await page.getByLabel('Password').fill(process.env.E2E_USER_PASSWORD!);
  await page.getByRole('button', { name: 'Sign in' }).click();
  await expect(page).not.toHaveURL(/login/);

  // Capture sessionStorage — not in storageState()
  const sessionData = await page.evaluate(() =>
    JSON.stringify(Object.fromEntries(
      Object.keys(sessionStorage).map(k => [k, sessionStorage.getItem(k)])
    ))
  );

  // Save sessionStorage alongside storageState
  require('fs').writeFileSync('e2e/.auth/session-storage.json', sessionData);
  await page.context().storageState({ path: 'e2e/.auth/user.json' });
});

// e2e/fixtures/auth.ts — restore sessionStorage before each test
import { test as base } from '@playwright/test';
import sessionData from '../.auth/session-storage.json';

export const test = base.extend({
  page: async ({ page }, use) => {
    // Inject sessionStorage before any navigation
    await page.addInitScript((data: Record<string, string>) => {
      for (const [key, value] of Object.entries(data)) {
        window.sessionStorage.setItem(key, value);
      }
    }, sessionData as Record<string, string>);

    await use(page);
  },
});
```

> Always add `e2e/.auth/session-storage.json` to `.gitignore` alongside `user.json`.
> The `addInitScript` runs before page scripts on every navigation within the context — no need to re-inject after `page.goto()`. [community]

---

### `locator.highlight()` with `style` Option and `page.hideHighlight()` (v1.60+)

`locator.highlight()` draws a visible highlight overlay on the matched element. Useful during local debugging sessions to visually confirm which element a locator resolves to, especially in complex component hierarchies.

```typescript
// Debug: visualize which elements a locator matches (headed mode only — meaningful)
test('verify locator targets correct element', async ({ page }) => {
  await page.goto('/admin/users');

  const activeRow = page
    .getByRole('row')
    .filter({ hasText: 'Alice' })
    .filter({ has: page.getByRole('cell', { name: 'Active' }) });

  // Highlight the row for visual inspection — custom style supported
  await activeRow.highlight({ style: 'outline: 3px solid blue; background: rgba(0,0,255,0.1)' });

  // ... interact and inspect manually in --headed mode
  await page.waitForTimeout(2000);  // pause to see the highlight (debug only)

  // Clear the highlight before continuing
  await page.hideHighlight();

  // Now interact with the confirmed locator
  await activeRow.getByRole('button', { name: 'Edit' }).click();
});
```

**Rules:**
- Never commit calls to `locator.highlight()` — add to ESLint `no-restricted-syntax` alongside `page.pause()` and `page.pickLocator()`.
- `page.hideHighlight()` removes ALL active highlights on the page (not per-locator).
- In headless CI, highlights are applied but invisible — they do not cause test failures, just consume a few milliseconds.

---

### `ariaSnapshot()` with `boxes` Option for AI-Assisted Diagnostics (v1.60+)

The `boxes` option appends each element's bounding box coordinates to the ARIA snapshot string. This enriches the snapshot for AI models that need spatial context to understand the page layout.

```typescript
// Capture ARIA tree with bounding box coordinates for LLM diagnostics
test('AI-enriched ARIA snapshot', async ({ page }) => {
  await page.goto('/dashboard');

  // Standard AI mode — compact representation for LLMs
  const aiTree = await page.ariaSnapshot({ mode: 'ai' });

  // boxes: true adds [box=x,y,width,height] to each element
  // Use when spatial layout context matters for the AI (e.g., "is the button above the form?")
  const spatialTree = await page.ariaSnapshot({ mode: 'ai', boxes: true });
  // Output: "- button 'Submit' [box=450,320,120,44]"

  // Scoped to a region — reduces LLM token consumption
  const navTree = await page.getByRole('navigation').ariaSnapshot({ mode: 'ai', boxes: true });
});

// Playwright Test Agents integration — feed spatial tree to Healer
test('healer-friendly snapshot', async ({ page }) => {
  await page.goto('/checkout');
  const checkoutTree = await page.ariaSnapshot({ mode: 'ai', boxes: true });
  // Pass to AI agent: "Given this layout with coordinates, which button is in the payment form?"
  console.log(checkoutTree);
});
```

> The `boxes` option is primarily useful for AI-assisted test generation and healing workflows. For regression testing, use `toMatchAriaSnapshot()` without coordinates — bounding boxes change on responsive resize and would cause spurious snapshot failures. [community]

---

### `tracing.start()` with `live` Option — Real-Time Trace Updates (v1.60+)

The `live` option in `tracing.start()` enables real-time trace updates, allowing trace viewers and dashboards to see incremental progress before the test completes. Without `live`, the trace is finalized as a single write when `tracing.stop()` is called.

```typescript
// Enable live trace streaming — useful for long-running tests
test('long checkout flow with live trace', async ({ context }) => {
  await context.tracing.start({
    screenshots: true,
    snapshots:   true,
    live:        true,  // flush trace data incrementally (v1.60+)
  });

  const page = await context.newPage();
  await page.goto('/checkout/step-1');
  await page.getByRole('button', { name: 'Next' }).click();
  await page.goto('/checkout/step-2');
  // Live trace is visible in trace viewer during test execution — no need to wait for stop()

  await context.tracing.stop({ path: 'test-results/checkout-trace.zip' });
});
```

> `live: true` is most useful for debugging long-running tests locally — you can open the trace viewer while the test is still running. In CI, skip `live` (leave it `false`) to minimize I/O overhead. [community]

---

### `consoleMessage.location()` — Source Location for Console Entries (v1.60+)

`consoleMessage.location()` now returns `line` and `column` properties alongside the URL, enabling precise source mapping of console errors back to the originating code.

```typescript
// Assert no console errors AND log their precise source location
test('no console errors with source context', async ({ page }) => {
  const errors: Array<{ text: string; url: string; line: number; col: number }> = [];

  page.on('console', msg => {
    if (msg.type() === 'error') {
      const loc = msg.location();
      errors.push({
        text: msg.text(),
        url:  loc.url,
        line: loc.lineNumber,
        col:  loc.columnNumber,  // v1.60+
      });
    }
  });

  await page.goto('/dashboard');
  await expect(page.getByRole('main')).toBeVisible();

  if (errors.length > 0) {
    const report = errors.map(e => `${e.text} (${e.url}:${e.line}:${e.col})`).join('\n');
    throw new Error(`Console errors found:\n${report}`);
  }
});

// Post-facto: use consoleMessages() API with location details
test('post-navigation console audit with source mapping', async ({ page }) => {
  await page.goto('/app');
  await page.getByRole('button', { name: 'Load data' }).click();

  const messages = await page.consoleMessages({ filter: 'since-navigation' });
  const consoleErrors = messages.filter(m => m.type() === 'error');

  if (consoleErrors.length > 0) {
    const details = consoleErrors.map(m => {
      const loc = m.location();
      return `[error] ${m.text()} at ${loc.url}:${loc.lineNumber}:${loc.columnNumber}`;
    });
    throw new Error(details.join('\n'));
  }
});
```

> `msg.location().columnNumber` (v1.60+) enables source maps to resolve the exact character position of errors. Combine with a sourcemap library to trace minified errors back to TypeScript source. [community]

---

### `reporter.onError(error, workerInfo)` — Worker-Attributed Error Reporting (v1.60+)

The `onError()` hook in custom reporters now receives `workerInfo` as a second argument, enabling worker-attributed error aggregation. Previously, `onError` fires for global errors outside tests (e.g., fixture setup crashes) but had no way to identify which worker caused them.

```typescript
// e2e/reporters/worker-error-reporter.ts
import type { Reporter, TestError, WorkerInfo, FullResult } from '@playwright/test/reporter';

class WorkerAwareErrorReporter implements Reporter {
  private workerErrors: Map<number, string[]> = new Map();

  // v1.60+: workerInfo is now passed to onError()
  onError(error: TestError, workerInfo?: WorkerInfo) {
    const workerIndex = workerInfo?.workerIndex ?? -1;
    const existing = this.workerErrors.get(workerIndex) ?? [];
    existing.push(`[worker ${workerIndex}] ${error.message ?? 'Unknown error'}`);
    this.workerErrors.set(workerIndex, existing);
  }

  onEnd(result: FullResult) {
    if (this.workerErrors.size > 0) {
      console.error('\n=== Worker-Level Errors ===');
      for (const [worker, errors] of this.workerErrors) {
        console.error(`Worker ${worker}: ${errors.length} error(s)`);
        errors.forEach(e => console.error(`  ${e}`));
      }
    }
  }
}

export default WorkerAwareErrorReporter;
```

> Worker-level errors (fixture crashes, `globalSetup` failures) were previously reported without identity information, making it impossible to correlate them with failing test files. `workerInfo` in `onError` lets you build dashboards that show which worker crashed and which test files were assigned to it. [community]

---

### `testInfoError.errorContext` — Diagnostic Context in Failure Reports (v1.60+)

When a test fails, `testInfoError.errorContext` provides additional diagnostic context captured at the point of failure — for example, the ARIA tree, the page URL, or custom diagnostic data.

```typescript
// Custom reporter using errorContext for richer failure reports
import type { Reporter, TestCase, TestResult } from '@playwright/test/reporter';

class EnrichedFailureReporter implements Reporter {
  onTestEnd(test: TestCase, result: TestResult) {
    if (result.status === 'failed') {
      for (const error of result.errors) {
        if (error.errorContext) {
          // errorContext contains diagnostic data from the point of failure
          // e.g., page URL, ARIA tree snapshot, network log
          console.log(`\nDiagnostic context for "${test.title}":`);
          console.log(error.errorContext);
        }
      }
    }
  }
}
```

> `errorContext` is populated automatically by Playwright's assertion framework. For custom assertions using `expect.extend()`, populate it via the `errorContext` field in the return value to provide structured failure context to report consumers. [community]

---

### `page.hideHighlight()` Key APIs Addition

Update the Key APIs table — Navigation & Waiting section — to include:

| API | What it does | When to use it |
|-----|-------------|----------------|
| `locator.highlight(opts?)` | Draw a visible overlay on matched element (v1.60+) | Local debugging of locator resolution — never commit |
| `page.hideHighlight()` | Remove all active highlight overlays (v1.60+) | Cleanup after `locator.highlight()` debugging |

These are documented in the Key APIs section above under Locators; the table addition below applies to the debugging workflow:

```typescript
// ESLint rule to prevent committing debug helpers
{
  "rules": {
    "playwright/no-page-pause": "error",
    "no-restricted-syntax": [
      "error",
      {
        "selector": "CallExpression[callee.property.name='highlight']",
        "message": "locator.highlight() is a debug tool — remove before committing."
      },
      {
        "selector": "CallExpression[callee.property.name='pickLocator']",
        "message": "page.pickLocator() is a debug tool — remove before committing."
      }
    ]
  }
}
```

---

## v1.60 API Summary Table

Quick reference for all v1.60 additions not covered in earlier sections.

| API | What it does | When to use it |
|-----|-------------|----------------|
| `locator.highlight(opts?)` | Draw debug overlay on element | Local debugging — never commit |
| `page.hideHighlight()` | Clear all highlight overlays | After `locator.highlight()` cleanup |
| `locator.drop(data)` | Simulate external file/clipboard drop | File-drop zone testing |
| `test.abort(msg?)` | Immediately fail test from any context | Guard against test environment violations |
| `browser.on('context')` | Fire when new context is created | Audit context lifecycle in multi-tab flows |
| `context.on('pageload')` | Fire on page load within context | Monitor all page activity from one listener |
| `context.on('pageclose')` | Fire on page close within context | Detect orphaned pages / popup lifecycle |
| `tracing.startHar(path, opts)` | HAR as first-class tracing API | Reproducible offline/HAR-based tests |
| `page.ariaSnapshot({ boxes })` | ARIA tree with bounding coordinates | AI-assisted test healing and diagnostics |
| `getByRole({ description })` | Match by accessible description | Disambiguate identically-named controls |
| `toHaveCSS(prop, val, { pseudo })` | Assert pseudo-element CSS | Design system icon/tooltip CSS testing |
| `expect(page).toMatchAriaSnapshot()` | Page-level aria assertion | Full-page accessibility structure regression |
| `consoleMessage.location().columnNumber` | Precise error source column | Source-map-based error attribution |
| `webSocketRoute.protocols()` | Get requested WS subprotocols | WebSocket protocol negotiation testing |
| `context.setStorageState({ path })` | Reset auth in existing context | Role-switching without new browser context |
| `tracing.start({ live: true })` | Incremental trace flushing | Real-time trace inspection on long tests |
| `reporter.onError(err, workerInfo)` | Worker-attributed error reporting | Identify which worker crashed in CI |
| `testInfoError.errorContext` | Structured diagnostic at failure point | Rich failure reports in custom reporters |
| `{testFileBaseName}` snapshot token | Flat snapshot directory naming | Easier visual regression baseline management |

---

## Accessibility Assertions (v1.44+)

Three built-in locator assertions test accessible names, roles, and descriptions without requiring `@axe-core/playwright`. They complement `toMatchAriaSnapshot()` for specific-element checks rather than structural trees.

### `toHaveAccessibleName` and `toHaveAccessibleDescription`

```typescript
// toHaveAccessibleName — verifies aria-label, aria-labelledby, or associated <label>
test('icon buttons have accessible labels', async ({ page }) => {
  await page.goto('/dashboard');

  // Verify icon-only button has an accessible name for screen readers
  await expect(page.getByTestId('delete-btn')).toHaveAccessibleName('Delete record');

  // Regex matching — useful when name includes dynamic content
  await expect(page.getByTestId('edit-btn')).toHaveAccessibleName(/Edit row \d+/);

  // Case-insensitive matching
  await expect(page.getByTestId('close-btn')).toHaveAccessibleName('close dialog', { ignoreCase: true });
});

// toHaveAccessibleDescription — verifies aria-describedby or aria-description tooltip text
test('form fields have help text accessible descriptions', async ({ page }) => {
  await page.goto('/signup');

  // Verify aria-describedby tooltip is wired correctly
  await expect(page.getByLabel('Password')).toHaveAccessibleDescription(
    'Must be at least 8 characters, include a number and a symbol'
  );
});
```

### `toHaveRole`

```typescript
// toHaveRole — verifies ARIA role matches exactly
// NOTE: role matching is a string comparison — it does NOT account for ARIA role inheritance
test('custom components have correct semantic roles', async ({ page }) => {
  await page.goto('/components/modal');

  await page.getByRole('button', { name: 'Open modal' }).click();

  // Custom overlay element must have role="dialog" for screen reader navigation
  const overlay = page.getByTestId('modal-overlay');
  await expect(overlay).toHaveRole('dialog');
  await expect(overlay).toHaveAccessibleName('Confirm action');

  // Verify a custom toggle has role="checkbox" not just looks like one
  const toggle = page.getByTestId('feature-toggle');
  await expect(toggle).toHaveRole('checkbox');
  await expect(toggle).toHaveAccessibleName('Enable notifications');
});
```

### `toBeChecked({ indeterminate: true })` — Indeterminate Checkbox State (v1.50+)

```typescript
// Assert an indeterminate checkbox state (tri-state: checked / unchecked / indeterminate)
test('select-all checkbox shows indeterminate when some items are checked', async ({ page }) => {
  await page.goto('/tasks');

  // Check only some items
  await page.getByRole('row').nth(1).getByRole('checkbox').check();
  await page.getByRole('row').nth(2).getByRole('checkbox').check();

  // The "select all" header checkbox should be indeterminate
  const selectAll = page.getByRole('columnheader').getByRole('checkbox');
  await expect(selectAll).toBeChecked({ indeterminate: true });

  // Check all items — indeterminate should resolve to fully checked
  await selectAll.click();
  await expect(selectAll).toBeChecked();
  await expect(selectAll).not.toBeChecked({ indeterminate: true });
});
```

> `toHaveAccessibleName`, `toHaveRole`, and `toHaveAccessibleDescription` assert on the *computed* accessible properties — the same values a screen reader exposes — not on HTML attributes directly. A `<div aria-role="button">` has accessible role `button`; a visually hidden `<label>` still contributes to accessible name. [community]

> Use `toHaveRole()` in component tests to verify that your custom ARIA widget has the correct semantic role, especially after design-system upgrades that may swap underlying HTML elements. [community]

---

### `--test-list` and `--test-list-invert` — Precise CI Test Selection (v1.56+)

Run a specific set of tests from a file rather than relying on `--grep` regex. Ideal for CI pipelines that use external test management systems to determine which tests should run for a given change.

```bash
# Create a test list file (same format as --list output)
# tests-to-run.txt:
# [chromium] › e2e/specs/checkout.spec.ts › checkout › completes payment
# [chromium] › e2e/specs/auth.spec.ts › login › shows error on bad credentials
# e2e/specs/users.spec.ts › CRUD › creates admin user

# Run only the listed tests
npx playwright test --test-list=tests-to-run.txt

# Skip the listed tests — run everything EXCEPT these
npx playwright test --test-list-invert=tests-to-skip.txt
```

**Test list file format:**

```
# Lines starting with # are comments
# Empty lines are ignored

# Fully qualified (project + file + suite + test):
[chromium] › e2e/specs/checkout.spec.ts:42:5 › checkout › completes payment

# File-only (runs all tests in this file):
e2e/specs/auth.spec.ts

# Suite-level:
e2e/specs/users.spec.ts › User management

# Cross-project (runs in all matching projects):
e2e/specs/smoke.spec.ts › Smoke › homepage loads
```

**Integration with test management systems (e.g., Jira, TestRail):**

```bash
# Step 1: Generate a full test list
npx playwright test --list --reporter=json | jq -r '.suites[].specs[].tests[].title' > all-tests.txt

# Step 2: External system produces "tests-to-run.txt" based on changed code
# (test impact analysis, test selection AI, or manual curation)

# Step 3: Run selected tests
npx playwright test --test-list=tests-to-run.txt --project=chromium
```

> `--test-list` is strictly safer than `--grep` when test titles contain regex metacharacters (`[`, `.`, `*`) — grep patterns silently match more tests than expected, while `--test-list` matches exact titles. [community]

> `--test-list-invert` is the idiomatic way to exclude a known-broken subset from a nightly run without adding `test.skip()` calls to source code — no test-file modifications required. [community]

---

### `context.clearCookies()` with Filtering Options (v1.43+)

Remove a subset of cookies from a browser context without clearing all of them. Useful for testing cookie expiry, logout flows, and session switching without creating a new context.

```typescript
// Clear a specific cookie by name
test('logout removes auth cookie', async ({ context, page }) => {
  await page.goto('/dashboard');
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();

  // Remove only the session cookie
  await context.clearCookies({ name: 'session_id' });

  await page.reload();
  await expect(page).toHaveURL(/\/login/);  // redirected to login
});

// Clear cookies for a specific domain (avoids clearing third-party widget cookies)
test('clears only first-party auth cookies', async ({ context, page }) => {
  await page.goto('/profile');
  await context.clearCookies({ domain: 'your-app.com' });
  // Cookies for widget.cdn.com and analytics.example.com are preserved
});

// Combine filters: name AND domain
test('removes session cookie from specific subdomain', async ({ context }) => {
  await context.clearCookies({ name: 'auth_token', domain: 'api.your-app.com' });
});

// Path-scoped cookie removal
test('clears admin-only cookies', async ({ context }) => {
  await context.clearCookies({ path: '/admin' });
});

// Regex filter — remove all cookies whose domain matches a pattern
test('clears all staging cookies', async ({ context }) => {
  await context.clearCookies({ domain: /staging\./ });
});
```

> `clearCookies()` with no arguments removes ALL cookies including third-party ones. When testing logout in apps that also use analytics or chat widget cookies, always pass a `domain` or `name` filter to avoid unintended side effects on other in-test cookies. [community]

---

### `step.skip()` and `step.attach()` Inside `test.step()` Body (v1.51+)

Steps receive a `TestStepInfo` object that provides `skip()` and `attach()` — making steps conditionally skippable and able to attach artifacts without test-level `testInfo` access.

```typescript
// step.skip() — conditionally bypass a step without failing the test
test('checkout flow with optional promo step', async ({ page, isMobile }) => {
  await test.step('navigate to checkout', async () => {
    await page.goto('/checkout');
  });

  await test.step('enter promo code', async (step) => {
    // Mobile layout doesn't show promo code until expanded
    if (isMobile) {
      step.skip('Promo code input hidden on mobile — expand tested separately');
      return;
    }
    await page.getByLabel('Promo code').fill('SAVE10');
    await page.getByRole('button', { name: 'Apply' }).click();
    await expect(page.getByText('10% discount applied')).toBeVisible();
  });

  await test.step('complete purchase', async () => {
    await page.getByRole('button', { name: 'Place order' }).click();
    await expect(page.getByText('Order confirmed')).toBeVisible();
  });
});

// step.attach() — save per-step artifacts visible in HTML report
test('validates complex form with step-level screenshots', async ({ page }) => {
  await test.step('fill personal info', async (step) => {
    await page.getByLabel('Name').fill('Alice Smith');
    await page.getByLabel('Email').fill('alice@example.com');

    // Attach screenshot at this step — visible as a nested attachment in HTML report
    await step.attach('personal-info-filled', {
      body:        await page.screenshot(),
      contentType: 'image/png',
    });
  });

  await test.step('fill payment', async (step) => {
    const frame = page.frameLocator('iframe[title="Payment"]');
    await frame.getByLabel('Card number').fill('4111111111111111');

    await step.attach('payment-filled', {
      body:        await page.screenshot(),
      contentType: 'image/png',
    });
  });
});
```

**`test.step.skip()` — standalone step skip (without accessing the step object):**

```typescript
// Skip an entire named step without using the step parameter pattern
test('feature behind flag', async ({ page }) => {
  await test.step('verify feature A', async () => {
    if (!process.env.FEATURE_A_ENABLED) {
      test.step.skip();  // standalone call — no step param needed
      return;
    }
    await page.goto('/feature-a');
    await expect(page.getByText('Feature A')).toBeVisible();
  });
});
```

> `step.attach()` binds attachments to the specific step rather than the whole test — in the HTML report, attachments appear nested under the step where they were created, making long tests with many steps much easier to navigate. [community]

> `step.skip()` inside the step body is the idiomatic pattern when the condition depends on data only available inside the step (e.g., an API response). `test.step.skip()` (standalone) is for conditions known before the step runs. [community]

---

### `consoleMessage.timestamp()` — Precise Log Timing (v1.59+)

`consoleMessage.timestamp()` returns the Unix timestamp (milliseconds) when the console message was created. Use it to correlate console events with test actions or to detect log flooding.

```typescript
// Measure time between page load and first console error
test('detects early console errors', async ({ page }) => {
  const messages: Array<{ type: string; text: string; ts: number }> = [];
  const testStart = Date.now();

  page.on('console', msg => {
    messages.push({
      type: msg.type(),
      text: msg.text(),
      ts:   msg.timestamp(),
    });
  });

  await page.goto('/app');
  await expect(page.getByRole('main')).toBeVisible();

  const errors = messages.filter(m => m.type === 'error');
  if (errors.length > 0) {
    const offsets = errors.map(e => `${e.text} (+${e.ts - testStart}ms after test start)`);
    throw new Error(`Console errors found:\n${offsets.join('\n')}`);
  }
});

// Post-facto inspection with timestamps using page.consoleMessages()
test('no errors after user action', async ({ page }) => {
  await page.goto('/editor');
  const beforeAction = Date.now();

  await page.getByRole('button', { name: 'Save' }).click();

  const messages = await page.consoleMessages({ filter: 'since-navigation' });
  const errorsAfterSave = messages.filter(
    m => m.type() === 'error' && m.timestamp() > beforeAction
  );

  expect(
    errorsAfterSave.map(m => m.text()),
    'Console errors appeared after Save action'
  ).toHaveLength(0);
});
```

> `consoleMessage.timestamp()` is essential for diagnosing race conditions where a console error appears briefly and then the component recovers — without timestamps you cannot tell if the error preceded or followed the triggering action. [community]

---

### `context.isClosed()` — Defensive Fixture and Teardown Checks (v1.59+)

`context.isClosed()` returns `true` after the browser context has been disposed. Use it in long-lived fixtures, custom reporters, and `afterEach` hooks that might run after a worker crash closes the context.

```typescript
// Safe teardown that checks context before cleanup
// e2e/fixtures/safe-teardown.ts
import { test as base } from '@playwright/test';

export const test = base.extend<{}, { testContext: void }>({
  testContext: [async ({ browser }, use, workerInfo) => {
    const context = await browser.newContext();
    const page    = await context.newPage();

    await use();

    // Guard against double-close when worker crashes
    if (!context.isClosed()) {
      // Capture final state before tearing down
      await page.screenshot({ path: `test-results/final-state-worker-${workerInfo.workerIndex}.png` });
      await context.close();
    }
  }, { scope: 'worker', auto: true }],
});

// In route handlers — guard against context disposal mid-test
test('resilient route handler', async ({ page, context }) => {
  await page.route('**/api/**', async route => {
    // Context might close if test times out while route is pending
    if (context.isClosed()) {
      return;  // silently drop — no error needed
    }
    try {
      const real = await route.fetch();
      await route.fulfill({ response: real });
    } catch {
      // Context disposed mid-fetch — expected on timeout/abort
    }
  });

  await page.goto('/data');
  await expect(page.getByRole('table')).toBeVisible();
});
```

> `context.isClosed()` is the idiomatic guard in fixtures that run cleanup after a test timeout. Without it, calling `context.close()` on an already-closed context throws "Target page, context or browser has been closed" — a confusing error that masks the original timeout failure. [community]

---

### `page.route()` Does Not Intercept the First Request of a Popup [community]

**What:** A test that registers `page.route()` handlers before a popup opens finds that the popup's first navigation request (e.g., the initial `GET /`) is not intercepted — the handler fires correctly for subsequent requests within the popup.

**WHY:** Playwright attaches route handlers to the *page* object. When a popup opens, it creates a new page object instantaneously. The first request fires before Playwright has a chance to attach the current page's route handlers to the new popup page.

**Fix:** Register routes on the *browser context* (`context.route()`) instead of the page. Context-level routes apply to all pages in the context, including popups, before their first request fires.

```typescript
// WRONG — page.route() misses the popup's first request
test('wrong pattern for popup auth', async ({ page }) => {
  await page.route('**/api/auth', route =>
    route.fulfill({ status: 200, body: '{"token":"test"}' })
  );
  // ↑ This handler WON'T fire for the popup's own auth request on first load

  const [popup] = await Promise.all([
    page.waitForEvent('popup'),
    page.getByRole('link', { name: 'Open OAuth' }).click(),
  ]);
  // popup's first GET may succeed or fail depending on real server state
});

// CORRECT — context.route() covers all pages including popups
test('correct pattern for popup auth', async ({ page, context }) => {
  await context.route('**/api/auth', route =>
    route.fulfill({ status: 200, body: '{"token":"test"}' })
  );
  // ↑ context-level handler fires before popup's first request

  const [popup] = await Promise.all([
    page.waitForEvent('popup'),
    page.getByRole('link', { name: 'Open OAuth' }).click(),
  ]);
  await expect(popup).toHaveURL(/success/);
});
```

---

### 29. `addLocatorHandler` alters mouse position and focused element mid-test [community]

**What:** A locator handler registered via `page.addLocatorHandler()` fires mid-action and moves the mouse to dismiss an overlay. After the handler completes, the test's subsequent `hover()` or `click()` targets the wrong element because the mouse position changed.

**WHY:** The handler runs inside Playwright's action pipeline — it fires before an actionability check and performs its own mouse movements. These side effects persist: the focused element changes, the cursor is now at the "Accept cookies" button position, and any hover-dependent UI (tooltips, dropdowns) that was open before the handler fired is now closed.

**Fix:** If mouse position stability is critical (e.g., testing a dropdown opened by hover), either:
- Use `{ noWaitAfter: true }` on the handler so Playwright doesn't wait for stability after clicking
- Explicitly re-hover the target element after your action instead of assuming the handler left things clean
- Register the overlay handler only for sections of the test where the overlay might appear, then remove it with `page.removeLocatorHandler()`

```typescript
test('tooltip persists after cookie banner dismissed', async ({ page }) => {
  await page.addLocatorHandler(
    page.getByRole('dialog', { name: /cookie/i }),
    async () => {
      await page.getByRole('button', { name: /accept/i }).click();
      // After dismissal, mouse is at the Accept button — not on the tooltip target
    },
    { noWaitAfter: true }  // don't wait for DOM to settle before continuing
  );

  const triggerElement = page.getByTestId('info-icon');
  await triggerElement.hover();  // this might trigger cookie banner dismissal mid-hover

  // Re-hover explicitly — don't assume mouse is still on triggerElement
  await triggerElement.hover();
  await expect(page.getByRole('tooltip')).toBeVisible();
});
```

---

### 30. `toMatchAriaSnapshot` includes input `placeholder` attributes in ARIA tree (v1.56+) [community]

**What:** After upgrading to Playwright 1.56+, `toMatchAriaSnapshot()` tests fail with unexpected content in `<input>` and `<textarea>` elements — specifically, snapshots now include `placeholder` text as part of the element's ARIA representation.

**WHY:** Playwright 1.56 updated the ARIA snapshot rendering engine to include `placeholder` attributes as part of the accessible node description for inputs. Pre-v1.56 snapshots that matched `- textbox` (no attributes) now match `- textbox "Search…" [placeholder]` instead, causing snapshot mismatches.

**Fix:** Update snapshots with `--update-snapshots=changed` after upgrading to v1.56+. For future-proofing, use regex patterns in ARIA assertions to tolerate optional placeholder text:

```typescript
// BEFORE v1.56 — snapshot file contained:
// - textbox

// AFTER v1.56 — snapshot now includes placeholder:
// - textbox "Enter search term" [placeholder]

// Fix option 1: regenerate snapshot
// npx playwright test --update-snapshots=changed e2e/specs/search.spec.ts

// Fix option 2: use inline regex pattern that tolerates the placeholder
test('search input is accessible', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('search')).toMatchAriaSnapshot(`
    - search:
      - textbox /search/i
  `);
  // Regex in ARIA snapshot: matches any textbox whose accessible name contains "search"
  // regardless of whether placeholder is included in the snapshot representation
});
```

> This is a silent snapshot upgrade gotcha: running `--update-snapshots=changed` resolves it correctly, but teams that blindly ran `--update-snapshots` (update all) in v1.56 unexpectedly regenerated baselines for every form field test in their suite. Use `changed` mode to limit the blast radius. [community]

---

### HTML Reporter: Speedboard Tab (v1.57+)

The HTML reporter now includes a **Speedboard** tab that shows all tests sorted by execution duration — slowest at the top. It is visible in both single-run reports and merged multi-shard reports.

Use it to:
- Identify slow tests that should move to a dedicated `slow` project with extended timeout
- Detect test regressions: a test that was 500ms is now 5s is a signal of added waits or polling
- Prioritize optimization work: the top 10 slowest tests often account for 30–40% of suite runtime

```bash
# Generate report and open Speedboard
npx playwright test
# Open playwright-report/index.html → "Speedboard" tab

# For merged shard reports:
npx playwright merge-reports --reporter html ./all-blob-reports
# Open merged playwright-report/index.html → "Speedboard" tab
```

```typescript
// playwright.config.ts — ensure HTML reporter is configured for local and CI merge
export default defineConfig({
  reporter: process.env.CI
    ? [['blob']]                                // shards; merge later
    : [['html', { open: 'on-failure' }]],       // local: opens on failure
});
```

> The Speedboard is most valuable at 200+ tests where long-tail slow tests are invisible in alphabetical test lists. Sort by duration quarterly and tag the 5 slowest tests with `@slow` to run them with dedicated settings. [community]

---

## Additional Key APIs (Iterations 25–26)

### Accessibility Assertions (v1.44–v1.50)

| API | What it does | When to use it |
|-----|-------------|----------------|
| `expect(locator).toHaveAccessibleName(text)` | Assert computed accessible name (ARIA label) | Icon buttons, unlabeled controls that rely on aria-label |
| `expect(locator).toHaveAccessibleDescription(text)` | Assert aria-describedby or aria-description content | Help text, tooltip wiring |
| `expect(locator).toHaveRole(role)` | Assert ARIA role string exactly | Custom ARIA widgets, design system compliance |
| `expect(locator).toBeChecked({ indeterminate: true })` | Assert indeterminate checkbox state (v1.50+) | Tri-state checkboxes, select-all with partial selection |

### Context Management

| API | What it does | When to use it |
|-----|-------------|----------------|
| `context.clearCookies({ name, domain, path })` | Remove subset of cookies (v1.43+) | Logout testing without clearing all cookies |
| `context.isClosed()` | Returns `true` after context is disposed (v1.59+) | Safe fixture teardown guards; route handler cleanup |

### Test Steps

| API | What it does | When to use it |
|-----|-------------|----------------|
| `test.step(name, fn, { timeout, box })` | Named step with optional timeout and boxing | Structured test narrative; POM method wrapping |
| `step.skip(reason?)` (inside body) | Skip step conditionally from within | Data-dependent step bypass |
| `test.step.skip()` (standalone) | Skip step when condition is known before body runs | Feature-flag-gated steps |
| `step.attach(name, opts)` | Attach artifact scoped to this step (v1.51+) | Per-step screenshots; per-step API response capture |

### Console Inspection

| API | What it does | When to use it |
|-----|-------------|----------------|
| `consoleMessage.timestamp()` | Unix ms when message was created (v1.59+) | Correlate console events with test actions; timing diagnostics |
| `page.consoleMessages({ filter })` | Retrieve stored console history (v1.56+) | Post-action console audit without event listeners |

### CLI Flags

| Flag | What it does | When to use it |
|------|-------------|----------------|
| `--test-list <file>` | Run only tests listed in the file (v1.56+) | CI test selection from external test management |
| `--test-list-invert <file>` | Skip tests listed in the file (v1.56+) | Exclude broken tests without modifying source |
| `--fail-on-flaky-tests` | Exit with failure code if any test needed a retry to pass (v1.45+) | Enable on nightly runs to surface flaky tests as hard failures; gate with `STRICT_FLAKE_MODE` env var so PR runs are unaffected |

---

### Breaking Changes Reference Update (v1.56)

| Version | Change | Migration |
|---------|--------|-----------|
| v1.56 | `browserContext.on('backgroundpage')` event **deprecated**; `browserContext.backgroundPages()` returns empty list | Remove background page monitoring; use service worker events instead |
| v1.56 | ARIA snapshot rendering now includes `input` placeholder text | Update snapshots with `--update-snapshots=changed` after upgrading |

---

## Additional Key APIs (Iterations 27+)

### `page.requestGC()` — Memory Leak Detection (v1.48+)

Force a garbage collection cycle from test code to verify that objects have been properly freed. Uses the browser's native GC trigger (Chrome DevTools Protocol `HeapProfiler.collectGarbage`).

**Pattern:** expose a `WeakRef` on `globalThis` inside the page, call `page.requestGC()`, then assert the ref is dead.

```typescript
test('dropdown panel is GC-collected after close', async ({ page }) => {
  await page.goto('/dashboard');

  // 1. Open the panel and capture a WeakRef on globalThis inside the page
  await page.getByRole('button', { name: 'Open panel' }).click();
  await page.evaluate(() => {
    const panel = document.querySelector('.dropdown-panel');
    (globalThis as any).__panelRef = new WeakRef(panel!);
  });

  // 2. Close the panel — it should be removed from the DOM and lose all references
  await page.getByRole('button', { name: 'Close panel' }).click();

  // 3. Request GC and assert the panel element has been collected
  await page.requestGC();

  const isCollected = await page.evaluate(
    () => (globalThis as any).__panelRef.deref() === undefined
  );
  expect(isCollected, 'Dropdown panel was not garbage-collected — possible memory leak').toBe(true);
});
```

> **[community]** `page.requestGC()` only triggers GC in **Chromium** — it is a no-op in Firefox and WebKit because those browsers don't expose a GC trigger via CDP. Add a browser check or limit these tests to the `chromium` project: `test.skip(browserName !== 'chromium', 'GC testing requires Chromium')`. [community]

> **[community]** Calling `requestGC()` does not guarantee immediate collection. In rare cases, the GC cycle may not collect objects referenced by closures inside event listeners. If the assertion fails intermittently, add `await page.requestGC()` a second time before asserting — two cycles catch objects deferred to the second generation. [community]

---

### `tracing.group()` — Visual Action Groups in Trace Viewer (v1.49+)

`context.tracing.group()` wraps a block of actions into a collapsible group in Trace Viewer. This is the low-level primitive; prefer `test.step()` when inside a test — `tracing.group()` is valuable in fixture setup/teardown and utility helpers where `test.step()` is not accessible.

```typescript
// In a custom fixture or page helper — not inside a test body
import { BrowserContext } from '@playwright/test';

async function loginViaApi(context: BrowserContext, email: string, password: string) {
  await context.tracing.group('API login setup');

  const page = await context.newPage();
  await page.goto('/login');
  await page.getByLabel(/email/i).fill(email);
  await page.getByLabel(/password/i).fill(password);
  await page.getByRole('button', { name: /sign in/i }).click();
  await page.waitForURL(/dashboard/);
  await page.close();

  await context.tracing.groupEnd();
}
```

**Nested groups:**

```typescript
await context.tracing.group('Checkout flow');

  await context.tracing.group('Fill cart');
  await page.getByRole('button', { name: 'Add to cart' }).click();
  await context.tracing.groupEnd();  // ends 'Fill cart'

  await context.tracing.group('Payment step');
  const frame = page.frameLocator('iframe[title="Payment"]');
  await frame.getByLabel('Card number').fill('4111111111111111');
  await context.tracing.groupEnd();  // ends 'Payment step'

await context.tracing.groupEnd();   // ends 'Checkout flow'
```

> **[community]** Prefer `test.step()` over `tracing.group()` in test bodies — `test.step()` surfaces in both the HTML report and Trace Viewer, while `tracing.group()` only appears in traces. Use `tracing.group()` for fixture-level helpers, global setup, and utility code outside the test runner where `test.step()` is unavailable. [community]

---

### `ControlOrMeta` — Cross-Platform Keyboard Modifier (v1.45+)

`ControlOrMeta` resolves to `Control` on Windows/Linux and `Meta` (⌘ Command) on macOS. Use it for cross-platform keyboard shortcuts to avoid platform-specific test branches.

```typescript
test('copies selected text with platform shortcut', async ({ page }) => {
  await page.goto('/editor');
  const editor = page.getByRole('textbox', { name: 'Editor' });
  await editor.fill('Hello world');

  // Select all — works on all platforms without branching
  await editor.press('ControlOrMeta+A');
  await editor.press('ControlOrMeta+C');

  // Verify clipboard content was captured (use page.evaluate for clipboard access)
  const clipboard = await page.evaluate(() => navigator.clipboard.readText());
  expect(clipboard).toBe('Hello world');
});

// Click with modifier — multi-select in a list
test('multi-selects items with ControlOrMeta+click', async ({ page }) => {
  await page.goto('/file-browser');
  await page.getByText('file-1.txt').click();
  await page.getByText('file-2.txt').click({ modifiers: ['ControlOrMeta'] });
  await page.getByText('file-3.txt').click({ modifiers: ['ControlOrMeta'] });

  await expect(page.getByRole('status')).toHaveText('3 items selected');
});
```

> **[community]** In WebKit on macOS, some `ControlOrMeta` keyboard events are intercepted by the OS before reaching the page — particularly `⌘+A` (select all) in `<input>` elements when the OS shortcut conflicts. Use `page.keyboard.down('Meta'); await page.keyboard.press('a'); await page.keyboard.up('Meta')` as a fallback for WebKit-only tests. [community]

---

### `webServer.gracefulShutdown` — Clean Dev Server Teardown (v1.50+)

By default, Playwright sends `SIGKILL` to the dev server process when tests complete. `gracefulShutdown` sends `SIGTERM` first and waits for the process to exit cleanly, allowing servers that hold database connections or write lock files to clean up properly.

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  webServer: {
    command:           'npm run dev',
    url:               'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    gracefulShutdown: {
      signal:  'SIGTERM',  // 'SIGTERM' (default) or 'SIGINT'
      timeout: 10_000,     // ms to wait before escalating to SIGKILL
    },
  },
});
```

> **[community]** `gracefulShutdown` matters for servers that spawn child processes (e.g., Vite's esbuild worker, Next.js Fast Refresh daemon) — a `SIGKILL` orphans those children and leaves zombie processes that hold the development port. On CI, this causes the next run's `webServer.url` health check to fail with "address already in use". Use `gracefulShutdown` + a `timeout` of 10 seconds to reliably free ports between runs. [community]

---

### `test.fail.only()` — Focus on Expected-Failure Tests (v1.49+)

`test.fail.only()` combines `.only()` focus mode with `.fail()` expected-failure annotation. The test must fail for the suite to pass; if it unexpectedly passes, Playwright reports an error.

```typescript
import { test, expect } from '@playwright/test';

// Focus on a known-broken test to isolate and diagnose it
test.fail.only('search returns zero results for emoji queries', async ({ page }) => {
  await page.goto('/search');
  await page.getByRole('searchbox').fill('🔥');
  await page.getByRole('button', { name: 'Search' }).click();
  // This currently returns 500 — tracked in JIRA-1234
  await expect(page.getByRole('list')).toHaveCount(0);
});

// Other tests are skipped in focused mode
test('search works for ASCII queries', async ({ page }) => {
  // Not run while .only() is active
});
```

> **[community]** `test.fail.only()` is especially useful when diagnosing a regression in CI — combine it with `--last-failed` to re-run only the failing tests: `npx playwright test --last-failed`. If the focused test unexpectedly passes (regression fixed), the suite fails with "Expected to fail, but passed" — a clear signal to remove the `.fail()` annotation and land the fix. [community]

---

### Multiple `globalSetup` / `globalTeardown` Files (v1.49+)

Pass an array of paths to run multiple global setup/teardown scripts. Scripts run in array order for setup and in reverse order for teardown (LIFO). Useful for separating infrastructure setup (database seeding) from auth setup (creating test accounts).

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  globalSetup:    ['./e2e/setup/database.ts', './e2e/setup/auth-accounts.ts'],
  globalTeardown: ['./e2e/teardown/auth-accounts.ts', './e2e/teardown/database.ts'],
  // Teardown runs in declaration order (NOT reverse) — order explicitly

  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
  },
});
```

```typescript
// e2e/setup/database.ts
import { FullConfig } from '@playwright/test';
import { seedTestDatabase } from '../helpers/db';

export default async function globalSetup(config: FullConfig) {
  console.log('[setup] Seeding test database…');
  await seedTestDatabase();
}
```

```typescript
// e2e/setup/auth-accounts.ts
import { FullConfig, chromium } from '@playwright/test';

export default async function globalSetup(config: FullConfig) {
  console.log('[setup] Creating test auth state…');
  const browser = await chromium.launch();
  // … create admin/viewer accounts, save storageState
  await browser.close();
}
```

> **[community]** Each `globalSetup` function receives the same `FullConfig` object. If one setup file sets a value on `process.env`, the next setup file in the array can read it — this makes the array order meaningful for pipelines where later setup steps depend on earlier ones (e.g., database URL from dynamic port must be known before auth setup tries to log in). [community]

---

### `screenshot: 'on-first-failure'` — Efficient Failure Evidence (v1.49+)

The `'on-first-failure'` screenshot mode captures a screenshot only on the first attempt of a failing test — not on subsequent retries. Compared to `'only-on-failure'` (which captures on every failed attempt), this halves screenshot storage in suites with `retries: 2`.

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: 2,
  use: {
    screenshot: 'on-first-failure',  // capture once; subsequent retries skip screenshot
    // vs 'only-on-failure':         // capture on every failed attempt (default retry behavior)
    // vs 'on':                      // capture always (high storage cost)
    // vs 'off':                     // never capture (no failure evidence)
  },
});
```

> **[community]** In a 500-test suite with `retries: 2`, switching from `'only-on-failure'` to `'on-first-failure'` reduces screenshot artifacts by up to 67% (one screenshot per failing test vs. three). On CI with artifact storage limits (GitHub Actions free tier: 500MB), this difference matters at scale — a suite with 50 failing tests × 3 retries × 1MB each = 150MB saved per run. [community]

---

### 31. `page.clock.install()` must be called BEFORE `page.goto()` [community]

**What:** Tests using `page.clock.install()` to freeze timers occasionally see the page "stuck" — lazy-loaded content never appears, setTimeout-driven animations don't fire, and `waitForLoadState('load')` times out.

**WHY:** `page.clock.install()` replaces `setTimeout`, `setInterval`, `requestAnimationFrame`, and `Date` globally. If `install()` is called AFTER `page.goto()`, the page has already used the native timer functions during the initial load. Those timers are now orphaned — the fake clock can't advance them. The result is a page partially initialized with native timers and partially frozen by the fake clock.

**Fix:** Always call `page.clock.install()` before the first `page.goto()`. For pages that depend on network responses during load, use `setFixedTime()` instead of `install()` — it only freezes `Date.now()` without touching timers.

```typescript
// WRONG — install() after navigation orphans timers from the initial load
test('wrong clock pattern', async ({ page }) => {
  await page.goto('/app');              // ← page loads with REAL timers
  await page.clock.install();          // ← fake clock installed too late
  await page.clock.fastForward(60_000); // animations/timers from load never fire
  await expect(page.getByText('Session expires in 59:00')).toBeVisible(); // may time out
});

// CORRECT — install() before navigation; all page timers use the fake clock
test('correct clock pattern', async ({ page }) => {
  await page.clock.install({ time: new Date('2025-06-01T09:00:00') });
  await page.goto('/app');              // ← page loads with FAKE timers
  await page.clock.fastForward(60_000); // all timers advance together
  await expect(page.getByText('Session expires in 59:00')).toBeVisible();
});

// ALSO CORRECT — setFixedTime() is safe to call at any point (only affects Date)
test('freeze date but allow real timers', async ({ page }) => {
  await page.goto('/dashboard');
  await page.clock.setFixedTime(new Date('2025-01-15T10:00:00Z')); // safe after goto
  await expect(page.getByTestId('current-date')).toHaveText('Jan 15, 2025');
});
```

---

### 32. `webSocketRoute.onMessage()` disables auto-forwarding to the server [community]

**What:** A test registers `page.routeWebSocket()` with an `onMessage` handler to intercept specific messages, expecting other messages to pass through to the real server. Instead, all messages are silently dropped and the server receives nothing.

**WHY:** Playwright's WebSocket routing auto-forwards messages to the server by default — but ONLY when no `onMessage` handler is registered. The moment you call `ws.onMessage()`, auto-forwarding is disabled and you must explicitly forward every message you don't want to intercept.

**Fix:** Call `ws.connectToServer()` and forward non-intercepted messages manually:

```typescript
// WRONG — registering onMessage blocks ALL messages from reaching the server
test('wrong ws pattern', async ({ page }) => {
  await page.routeWebSocket('/feed', ws => {
    ws.onMessage(message => {
      if (message === 'ping') ws.send('pong'); // ← intercept ping
      // All other messages are silently dropped — server receives nothing
    });
  });
});

// CORRECT — connect to real server; forward everything except intercepted messages
test('correct ws pattern', async ({ page }) => {
  await page.routeWebSocket('/feed', ws => {
    const server = ws.connectToServer();

    ws.onMessage(message => {
      if (message === 'ping') {
        ws.send('pong');          // ← handle locally; don't forward
        return;
      }
      server.send(message);       // ← forward all other messages to real server
    });

    server.onMessage(message => {
      ws.send(message);           // ← forward real server responses back to page
    });
  });

  await page.goto('/realtime-dashboard');
  await expect(page.getByRole('feed')).not.toBeEmpty();
});
```

> Similarly, registering `server.onMessage()` disables auto-forwarding in the server → page direction. The rule is symmetric: **any `onMessage` registration on either side disables auto-forwarding on that side**. [community]

---

### 33. `page.requestGC()` is Chromium-only; Firefox/WebKit silently no-op [community]

**What:** A test that calls `page.requestGC()` to verify memory cleanup passes on Chromium but never actually runs GC on Firefox or WebKit CI shards — the method exists on the API but has no effect on those engines.

**WHY:** `page.requestGC()` uses Chrome DevTools Protocol's `HeapProfiler.collectGarbage` command, which is only available in Chromium-based browsers. Playwright does not throw an error when called on Firefox or WebKit — the method resolves successfully but no GC occurs, so `WeakRef.deref()` may still return the object even though it would be garbage-collected on Chromium.

**Fix:** Guard memory leak tests with a browser skip:

```typescript
import { test, expect, browserName } from '@playwright/test';

test('modal is GC-collected after close', async ({ page, browserName }) => {
  test.skip(browserName !== 'chromium', 'requestGC() requires Chromium; no-op on Firefox/WebKit');

  await page.goto('/app');
  await page.getByRole('button', { name: 'Open modal' }).click();

  await page.evaluate(() => {
    const modal = document.getElementById('modal');
    (globalThis as any).__modalRef = new WeakRef(modal!);
  });

  await page.getByRole('button', { name: 'Close' }).click();
  await page.requestGC();

  const isCollected = await page.evaluate(
    () => (globalThis as any).__modalRef.deref() === undefined
  );
  expect(isCollected).toBe(true);
});
```

Alternatively, place all GC tests in a dedicated project scoped to Chromium:

```typescript
// playwright.config.ts
{
  name: 'memory-leak-tests',
  testMatch: '**/*.gc-spec.ts',
  use: { ...devices['Desktop Chrome'] },
  dependencies: ['setup'],
}
```

---

## Additional Key APIs (Iteration 27)

| API | What it does | When to use it |
|-----|-------------|----------------|
| `page.requestGC()` | Trigger GC cycle (Chromium only, v1.48+) | Verify objects are freed after component/modal close |
| `context.tracing.group(name)` / `tracing.groupEnd()` | Wrap actions in named group in Trace Viewer (v1.49+) | Fixture helpers, page utilities outside test body |
| `keyboard.press('ControlOrMeta+X')` | Cross-platform ⌃/⌘ modifier (v1.45+) | Copy/paste/select-all shortcuts that differ per OS |
| `webServer.gracefulShutdown` | SIGTERM + timeout before SIGKILL on test complete (v1.50+) | Servers with child processes, DB connections, or port locks |
| `test.fail.only()` | Focus mode + expected failure annotation (v1.49+) | Isolating known-broken tests during diagnosis |
| `globalSetup: [file1, file2]` | Multiple setup scripts run in order (v1.49+) | Separate DB seed from auth setup; clear dependency chain |
| `screenshot: 'on-first-failure'` | Screenshot only on first retry failure (v1.49+) | Reduce artifact storage cost in suites with retries ≥ 2 |

### Additional Breaking Changes (v1.49)

| Version | Change | Migration |
|---------|--------|-----------|
| v1.49 | Chrome and Edge channels switch to **new headless mode** | Some screenshot/PDF tests may produce different pixels; regenerate baselines after upgrade |
| v1.49 | `updateSnapshots` default changed from `'all'` to `'missing'` | Set `updateSnapshots: 'changed'` explicitly if previous behavior needed |

---

## v1.61+ New Patterns (Iteration 28)

<!-- verified: Playwright v1.60 is current stable as of 2026-05-12; v1.61 not yet released -->

### `updateSourceMethod` — Three-Way Merge for Inline Snapshot Updates (v1.50+)

When updating inline snapshot tests (`toMatchAriaSnapshot`, `toHaveText`, `expect.soft` with inline matchers),
Playwright can rewrite the source file in three modes configured via `testConfig.updateSourceMethod`:

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  updateSourceMethod: 'patch',  // 'patch' | 'overwrite' | '3-way'
  updateSnapshots: 'changed',
});
```

| Mode | Behavior | When to use |
|------|----------|------------|
| `'overwrite'` | Replaces the whole snapshot string with new value | Safe when there are no outstanding git conflicts |
| `'patch'` | Generates a `git apply`-compatible patch file alongside test output | CI where you want to review inline diff before applying |
| `'3-way'` | Writes both old and new markers (`<<<`, `===`, `>>>`) into the source | When merging a feature branch that touched the same snapshots |

**Production pattern — patch mode in CI for review-first updates:**

```typescript
// In CI, collect patch files rather than mutating source
// playwright.config.ts
export default defineConfig({
  updateSourceMethod: process.env.CI ? 'patch' : 'overwrite',
  updateSnapshots: 'changed',
});
```

```bash
# Apply approved snapshot patches after review
git apply test-results/*.patch
git diff --stat  # see which test files changed
```

> **[community]** WHY: `overwrite` mode on CI commits broken inline snapshots directly into the PR if someone runs `npx playwright test --update-snapshots` locally and pushes. The `patch` mode generates diff files to `test-results/` which are reviewed before applying — preventing unintentional snapshot acceptance. Teams using `3-way` reserve it for cross-branch merges where both the old snapshot (in `main`) and new snapshot (feature branch) need to be visible to a human reviewer. [community]

---

### Dialog Handling — The "Listener Must Accept or Hang" Contract

Playwright auto-dismisses all browser dialogs (`alert`, `confirm`, `prompt`) when no listener is registered. Once **any** listener is registered via `page.on('dialog', ...)`, Playwright stops auto-dismissing and the dialog will hang indefinitely unless the listener calls `dialog.accept()` or `dialog.dismiss()`.

```typescript
import { test, expect } from '@playwright/test';

// ✅ One-shot dialog: use page.once()
test('delete confirmation dialog', async ({ page }) => {
  await page.goto('/items');

  // Register handler BEFORE the action that triggers the dialog
  page.once('dialog', async dialog => {
    expect(dialog.type()).toBe('confirm');
    expect(dialog.message()).toContain('Are you sure');
    await dialog.accept();
  });

  await page.getByRole('button', { name: 'Delete' }).click();
  await expect(page.getByText('Item deleted')).toBeVisible();
});

// ✅ Recurring dialog: use page.on() with cleanup
test('recurring prompt dialogs', async ({ page }) => {
  let callCount = 0;
  const handler = async (dialog: import('@playwright/test').Dialog) => {
    callCount++;
    await dialog.accept(`response-${callCount}`);
  };
  page.on('dialog', handler);

  await page.goto('/multi-prompt');
  await page.getByRole('button', { name: 'Ask twice' }).click();

  await expect(page.getByText('Got: response-2')).toBeVisible();
  page.off('dialog', handler);  // Clean up to restore auto-dismiss
});

// ✅ Prompt: read the default value and provide a custom response
test('prompt with default value', async ({ page }) => {
  page.once('dialog', async dialog => {
    expect(dialog.defaultValue()).toBe('John');
    await dialog.accept('Jane');
  });
  await page.goto('/greet');
  await page.getByRole('button', { name: 'Greet' }).click();
  await expect(page.getByText('Hello, Jane')).toBeVisible();
});

// ✅ beforeunload: must pass runBeforeUnload: true to page.close()
test('unsaved changes warning', async ({ page }) => {
  await page.goto('/editor');
  await page.getByLabel('Content').fill('unsaved work');

  page.once('dialog', async dialog => {
    expect(dialog.type()).toBe('beforeunload');
    await dialog.dismiss();  // Dismiss = stay on page
  });

  await page.close({ runBeforeUnload: true });
});
```

**Key APIs:**

| Method | What it returns | Notes |
|--------|----------------|-------|
| `dialog.type()` | `'alert'`, `'confirm'`, `'prompt'`, `'beforeunload'` | Check before routing to different handlers |
| `dialog.message()` | Text displayed to the user | Assert expected message |
| `dialog.defaultValue()` | Pre-filled value in `prompt` inputs | Inspect before deciding what to accept |
| `dialog.accept(promptText?)` | Confirm / OK (with optional text for prompts) | Pass custom string for prompt dialogs |
| `dialog.dismiss()` | Cancel / dismiss | Use for `beforeunload` to keep page open |

> **[community] Gotcha #34:** Registering a `page.on('dialog', ...)` listener that does **not** call `accept()` or `dismiss()` — for example, only logging the message — causes the test to hang at the action that triggered the dialog. The dialog is modal: the page is frozen until it is resolved. If you need to assert the message AND resolve the dialog, do both inside the same listener. Pattern: `page.once('dialog', async d => { expect(d.message()).toContain('X'); await d.accept(); })`. [community]

---

### `page.evaluate()` with Multiple Handles — Destructuring Pattern

When passing multiple JSHandles to `page.evaluate()`, use object or array destructuring to avoid serialisation errors. Only primitives, plain objects, and `JSHandle`/`ElementHandle` instances can be passed as arguments — closures and functions cannot cross the JS execution boundary.

```typescript
import { test, expect } from '@playwright/test';

test('read text from multiple DOM handles', async ({ page }) => {
  await page.goto('/comparison');

  // Acquire handles to non-serialisable DOM nodes
  const headerHandle = await page.evaluateHandle(() => document.querySelector('h1'));
  const priceHandle  = await page.evaluateHandle(() => document.querySelector('[data-price]'));

  // ✅ Destructuring object pattern — handles passed as second argument
  const { header, price } = await page.evaluate(
    ({ h, p }) => ({
      header: h?.textContent?.trim() ?? '',
      price:  p?.getAttribute('data-price') ?? '',
    }),
    { h: headerHandle, p: priceHandle }
  );

  expect(header).toBe('Product A');
  expect(price).toBe('29.99');

  // Always dispose handles to avoid memory leaks in long tests
  await headerHandle.dispose();
  await priceHandle.dispose();
});

// ✅ Array destructuring pattern
test('compare two input values', async ({ page }) => {
  await page.goto('/form');
  const [firstInput, secondInput] = await Promise.all([
    page.evaluateHandle(() => document.querySelector('#qty-a')),
    page.evaluateHandle(() => document.querySelector('#qty-b')),
  ]);

  const [qtyA, qtyB] = await page.evaluate(
    ([a, b]) => [
      (a as HTMLInputElement).value,
      (b as HTMLInputElement).value,
    ],
    [firstInput, secondInput]
  );

  expect(Number(qtyA)).toBeLessThan(Number(qtyB));
  await firstInput.dispose();
  await secondInput.dispose();
});

// ✅ addInitScript with argument — inject mock BEFORE page load
test('mock Math.random before load', async ({ page }) => {
  const fixedSeed = 0.42;
  await page.addInitScript(
    (seed) => { Math.random = () => seed; },
    fixedSeed   // Argument passed explicitly; NOT captured from closure
  );
  await page.goto('/random-demo');
  await expect(page.getByTestId('lucky-number')).toHaveText('42');
});
```

> **[community] Gotcha #35:** Variables from the outer test scope are **not** available inside `page.evaluate()` callbacks. The callback runs in the browser process, not the Node.js process. If you reference a test variable inside `evaluate(() => someVar)`, `someVar` will be `undefined` at runtime. Always pass external data as the second argument: `page.evaluate((data) => use(data), someVar)`. This is especially surprising when destructuring test fixtures — fixture values must also be passed explicitly. [community]

---

### HiDPI / Retina Emulation — `deviceScaleFactor` with Custom Viewports

`deviceScaleFactor` sets the device pixel ratio, causing the browser to render at double (or more) physical pixels while the viewport logical size stays the same. Essential for screenshot tests on high-resolution designs.

```typescript
import { test, expect, defineConfig, devices } from '@playwright/test';

// playwright.config.ts — project-level HiDPI config
export default defineConfig({
  projects: [
    {
      name: 'desktop-retina',
      use: {
        viewport:          { width: 1280, height: 720 },
        deviceScaleFactor: 2,  // Retina (2x DPR)
      },
    },
    {
      name: 'desktop-standard',
      use: {
        viewport:          { width: 1280, height: 720 },
        deviceScaleFactor: 1,
      },
    },
    {
      name: 'iphone-15-pro',
      use: {
        ...devices['iPhone 15 Pro'],  // DPR 3 built-in
      },
    },
  ],
});

// Test-level viewport override (does not affect deviceScaleFactor)
test.describe('wide layout', () => {
  test.use({ viewport: { width: 1920, height: 1080 } });

  test('full-bleed hero image visible', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('img', { name: 'Hero' })).toBeVisible();
  });
});

// Programmatic override per test
test('side panel visible at 1440px', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('/dashboard');
  await expect(page.getByTestId('side-panel')).toBeVisible();
});
```

**Screenshot assertions with HiDPI — match at same scale:**

```typescript
test('retina logo crisp', async ({ page }) => {
  await page.goto('/');
  // Screenshot pixel dimensions = viewport × deviceScaleFactor
  // Playwright handles this automatically; baselines captured at DPR 2
  // will fail at DPR 1 — use per-project snapshot directories
  await expect(page.getByRole('img', { name: 'Logo' })).toHaveScreenshot(
    'logo-retina.png',
    { maxDiffPixels: 5 }
  );
});
```

> **[community]** WHY: Screenshot tests run on DPR 2 (macOS Retina CI) produce PNG files twice the pixel count of DPR 1 runs (Linux CI). If you don't isolate snapshot directories by `deviceScaleFactor`, screenshot tests flip between pass and fail depending on the runner. Use `snapshotPathTemplate: '{snapshotDir}/{projectName}/{arg}{ext}'` (project name encodes DPR) or set `use: { deviceScaleFactor: 1 }` globally in CI config. [community]

---

### `testResult.annotations` — Per-Retry Annotation Access (v1.52+)

Each test result object (available in reporters) carries all annotations added during that specific retry. This enables reporters to correlate JIRA issues, build tags, or environment markers with individual retry outcomes.

```typescript
// custom-reporter.ts
import type { Reporter, TestCase, TestResult } from '@playwright/test/reporter';

class AnnotationReporter implements Reporter {
  onTestEnd(test: TestCase, result: TestResult) {
    // result.annotations contains annotations for THIS retry, not the full test
    const issues = result.annotations
      .filter(a => a.type === 'issue')
      .map(a => a.description);

    if (result.status === 'failed' && issues.length > 0) {
      console.log(`[FAIL] ${test.title} — linked issues: ${issues.join(', ')}`);
    }

    // result.annotations also includes runtime annotations pushed during the test
    const envAnnotations = result.annotations
      .filter(a => a.type === 'environment');

    if (envAnnotations.length > 0) {
      console.log(`  Environments: ${envAnnotations.map(a => a.description).join(', ')}`);
    }
  }
}

export default AnnotationReporter;

// In test — push runtime annotation for reporter to pick up
test('create order', {
  annotation: {
    type: 'issue',
    description: 'https://jira.example.com/browse/ORD-123',
  },
}, async ({ page, browserName }) => {
  // Runtime annotation: add environment context
  test.info().annotations.push({
    type: 'environment',
    description: `${browserName}-${process.env.TEST_ENV ?? 'local'}`,
  });

  await page.goto('/orders/new');
  // ...
});
```

> **[community]** WHY: `test.info().annotations` (available inside a test) collects annotations across all retries into a single array. `testResult.annotations` (available in reporters) gives annotations for **one specific retry attempt** — enabling reporters to distinguish "this failure had a linked issue" from "this retry had a linked issue". Teams building custom Slack/PagerDuty reporters use `testResult.annotations` to suppress noise for known issues. [community]

---

## Additional Key APIs (Iteration 28)

| API | What it does | When to use it |
|-----|-------------|----------------|
| `testConfig.updateSourceMethod` | `'patch'` / `'overwrite'` / `'3-way'` — controls how inline snapshot source files are rewritten (v1.50+) | Use `'patch'` in CI for review-first snapshot updates; `'3-way'` for cross-branch merges |
| `page.on('dialog', handler)` | Register persistent dialog handler — must call `accept()` or `dismiss()` | Multi-dialog flows; always clean up with `page.off()` after use |
| `page.once('dialog', handler)` | Register one-shot dialog handler — auto-removed after first invocation | Single-use confirm / alert dialogs |
| `dialog.defaultValue()` | Read pre-filled text in `prompt` dialogs | Validate default before substituting with `accept(text)` |
| `page.addInitScript(fn, arg)` | Inject JS before page load with explicit argument | Mock `Math.random`, `Date`, `WebSocket`; never use closure scope |
| `page.evaluateHandle(fn)` | Return non-serialisable `JSHandle` from browser context | Required when passing DOM nodes to subsequent `evaluate()` calls |
| `jsHandle.dispose()` | Release `JSHandle` reference in browser memory | Call after use to avoid memory leaks in long tests |
| `deviceScaleFactor` context option | Sets device pixel ratio for HiDPI / Retina rendering | Screenshot baseline tests, responsive design testing at 2x/3x DPR |
| `testResult.annotations` | Per-retry annotation array in custom reporters (v1.52+) | Correlate JIRA issues / environment tags with specific retry attempts |

---

### Additional Breaking Changes (v1.50–v1.60)

| Version | Change | Migration |
|---------|--------|-----------|
| v1.50 | `updateSnapshots` option renamed/extended — new `updateSourceMethod` controls rewrite strategy | Default remains `'overwrite'`; set explicitly in CI config |
| v1.60 | `Locator.ariaRef()` removed | Use `locator.ariaSnapshot({ mode: 'ai' })` instead |
| v1.60 | Context options `videosPath` / `videoSize` removed | Use `recordVideo: { dir, size }` option on context creation |
| v1.60 | `handle` option removed from binding/exposure methods | Pass handles directly as arguments to `evaluate()` |

---

## Iteration 29 — New Patterns & Gotchas (2026-05-12)

---

### `npx playwright init-agents` — AI-Agent Project Bootstrap (v1.56+)

The `init-agents` command generates agent definition files wired to your preferred AI environment. This is the correct setup path — `npx playwright agent` (the old syntax) only invokes agents after definitions exist. Re-run `init-agents` every time Playwright updates to get the latest tool set and instructions.

```bash
# Choose your AI coding environment
npx playwright init-agents --loop=claude     # Claude Code
npx playwright init-agents --loop=vscode     # VS Code (requires v1.105+, Oct 2025)
npx playwright init-agents --loop=opencode   # OpenCode

# The command creates this project layout:
# repo/
#   .github/                   ← agent definition files (check these in)
#   specs/                     ← human-readable Markdown test plans
#     basic-operations.md
#   tests/                     ← Playwright spec files generated by agents
#     seed.spec.ts             ← environment bootstrap (edit this first)
#     create/add-valid-todo.spec.ts
#   playwright.config.ts
```

**Seed test — the foundation agents build on:**

The `seed.spec.ts` is the only file you write manually. It gives agents a live, authenticated page to explore. Agents run your seed test first to establish context before planning, generating, or healing.

```typescript
// tests/seed.spec.ts
import { test } from '@playwright/test';

test('seed — bootstrap app context', async ({ page }) => {
  // Navigate to the app and authenticate
  await page.goto('/');
  await page.getByLabel('Email').fill(process.env.TEST_EMAIL!);
  await page.getByLabel('Password').fill(process.env.TEST_PASSWORD!);
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.waitForURL('/dashboard');
  // Stop here — the agent takes over
});
```

**Three-agent workflow:**

```bash
# Step 1: Planner explores the app and writes a Markdown test plan
# → In Claude Code: "Generate a plan for the guest checkout flow"
# The Planner runs seed.spec.ts, explores the app, writes specs/checkout.md

# Step 2: Generator turns the plan into spec files
# → In Claude Code: "Generate tests from specs/checkout.md"
# The Generator verifies selectors live and writes tests/checkout/add-to-cart.spec.ts

# Step 3: Healer runs tests and patches failures
# → In Claude Code: "Heal the failing checkout tests"
# The Healer re-examines broken selectors and applies patches
```

> **[community]** WHY: Forgetting to re-run `npx playwright init-agents --loop=<env>` after a Playwright minor version bump means agents use stale tool definitions that reference removed or renamed APIs. The generated files embed a Playwright version comment; treat a version mismatch as a required maintenance step — the same way you would `npx playwright install` after upgrading. Stale agent definitions silently produce lower-quality test plans. [community]

> **[community]** WHY: Review Planner output as carefully as you would a PR. The Planner hallucinates test steps for flows it cannot access (auth-gated pages, MFA, third-party payments). Always provide the seed test with a pre-authenticated session and ensure the seed test lands on the correct starting page — a wrong seed URL produces an unusable plan. [community]

---

### `worker.on('console')` — Service Worker Console Messages (v1.57+)

Service workers run in their own JavaScript context, separate from the page. Their `console.log` output was previously invisible to Playwright. Since v1.57, the `worker.on('console')` event captures console messages from both dedicated workers and service workers.

```typescript
import { test, expect } from '@playwright/test';

test('capture service worker console output', async ({ page }) => {
  const swMessages: string[] = [];

  // Listen for service worker registration
  page.on('worker', (worker) => {
    worker.on('console', (msg) => {
      swMessages.push(`[${msg.type()}] ${msg.text()}`);
    });
  });

  await page.goto('/');  // triggers service worker registration

  // Interact to trigger SW background sync
  await page.getByRole('button', { name: 'Sync' }).click();

  // Assert SW logged expected messages
  expect(swMessages).toContain('[log] Background sync completed');
});

// Capture service worker errors in CI
test('no service worker errors on load', async ({ page }) => {
  const swErrors: string[] = [];

  page.on('worker', (worker) => {
    worker.on('console', (msg) => {
      if (msg.type() === 'error') swErrors.push(msg.text());
    });
  });

  await page.goto('/');
  await page.waitForLoadState('networkidle');

  expect(swErrors, 'service worker errors').toEqual([]);
});
```

> **[community]** WHY: Service workers are invisible in many CI failure reports because teams only listen to `page.on('console')`. SW runtime errors (failed cache operations, broken fetch handlers) silently degrade offline support without triggering page-visible errors. Adding `worker.on('console')` listeners to a global fixture catches these errors in every test run. [community]

---

### `page.emulateMedia({ contrast })` — `prefers-contrast` Testing (v1.51+)

`page.emulateMedia()` accepts a `contrast` option to simulate the `prefers-contrast` CSS media feature. This lets you test high-contrast mode — a critical accessibility requirement for users with low vision.

```typescript
import { test, expect } from '@playwright/test';

test('high-contrast mode — form inputs remain visible', async ({ page }) => {
  await page.goto('/signup');

  // Simulate prefers-contrast: more
  await page.emulateMedia({ contrast: 'more' });

  // Verify key elements are still accessible
  const emailInput = page.getByLabel('Email');
  await expect(emailInput).toBeVisible();
  await expect(emailInput).toHaveCSS('border-color', /.+/); // must have visible border

  // Check that error states are visually distinct
  await page.getByRole('button', { name: 'Sign up' }).click();
  await expect(page.getByRole('alert')).toBeVisible();
});

// Configure via playwright.config.ts for a dedicated contrast project
// playwright.config.ts
import { defineConfig } from '@playwright/test';
export default defineConfig({
  projects: [
    { name: 'contrast', use: { contrast: 'more' } },
    { name: 'no-preference', use: { contrast: 'no-preference' } },
  ],
});

// Valid contrast values: 'more' | 'less' | 'forced' | 'no-preference' | null
```

> **[community]** WHY: Many teams test dark mode (`colorScheme: 'dark'`) but skip contrast testing. Windows High Contrast Mode (forced-colors) often triggers completely different CSS rendering paths. Set `contrast: 'forced'` to simulate `forced-colors: active` and catch components that hard-code colors with `color:` instead of using CSS system palette variables. [community]

---

### `expect(fn).toPass({ intervals })` — Custom Retry Intervals (v1.44+)

`toPass()` retries an async callback until it stops throwing. The `intervals` option customizes the delay between attempts, enabling exponential back-off or domain-specific polling rhythms.

```typescript
import { test, expect } from '@playwright/test';

test('wait for background job with exponential backoff', async ({ page, request }) => {
  const jobId = await page.evaluate(() => window.__lastJobId);

  // Retry with exponential back-off: 500ms → 1s → 2s → 4s
  await expect(async () => {
    const res = await request.get(`/api/jobs/${jobId}`);
    const body = await res.json();
    expect(body.status).toBe('completed');
  }).toPass({
    timeout:   30_000,
    intervals: [500, 1000, 2000, 4000],  // ms between retries — final interval repeats
  });
});

// Configure global default intervals in playwright.config.ts
// playwright.config.ts
import { defineConfig } from '@playwright/test';
export default defineConfig({
  expect: {
    toPass: {
      intervals: [100, 250, 500, 1000],  // default intervals for all toPass() calls
      timeout: 15_000,
    },
  },
});

// Simple pass-through: retry every 1s for 10s
await expect(async () => {
  await expect(page.getByTestId('status')).toHaveText('Ready');
}).toPass({ timeout: 10_000, intervals: [1000] });
```

> **[community]** WHY: The default `toPass()` interval is 100 ms. For API polling tests that hit a real backend, this hammers the server and creates noisy logs. Always set `intervals` to something sane for the operation type: 500 ms for DB writes, 2000 ms for async jobs. The final interval in the array is reused for all subsequent retries — a single-element array is the simplest way to get a constant interval. [community]

---

### `expect(page).toHaveURL()` — Predicate and `ignoreCase` Options (v1.44+)

`toHaveURL()` accepts a function predicate in addition to strings and RegExp. Use it when URL validation requires logic that regex cannot express clearly.

```typescript
import { test, expect } from '@playwright/test';

// String match (existing pattern)
await expect(page).toHaveURL('https://example.com/dashboard');

// Regex match (existing pattern)
await expect(page).toHaveURL(/\/dashboard/);

// Predicate — custom logic (v1.44+)
await expect(page).toHaveURL((url: URL) => {
  return url.pathname === '/dashboard' && url.searchParams.get('tab') === 'settings';
});

// Case-insensitive string match (v1.44+)
await expect(page).toHaveURL('/Profile', { ignoreCase: true });
// Matches /profile, /Profile, /PROFILE

// Predicate for query-string-agnostic assertions
test('redirect preserves return_to param', async ({ page }) => {
  await page.goto('/protected');
  await expect(page).toHaveURL((url: URL) => {
    return url.pathname === '/login' && url.searchParams.has('return_to');
  });
});
```

> **[community]** WHY: Many teams write brittle `url.includes('/dashboard')` checks in test bodies. `toHaveURL()` with a predicate auto-retries with Playwright's assertion timeout (default 5 s), so it handles redirect races gracefully. `url.includes()` in a plain `expect` does not retry and fails immediately if the redirect hasn't happened yet. [community]

---

### `expect(page).toMatchAriaSnapshot()` — Full-Page ARIA Assertion (v1.60+)

Since v1.60, `toMatchAriaSnapshot()` can be called directly on the `Page` object — equivalent to `page.locator('body')` but more expressive. Use it for full-page accessibility regression tests.

```typescript
import { test, expect } from '@playwright/test';

test('login page accessibility structure', async ({ page }) => {
  await page.goto('/login');

  // Full-page ARIA snapshot — asserts the complete accessibility tree
  await expect(page).toMatchAriaSnapshot(`
    - banner:
      - heading "Sign in" [level=1]
    - main:
      - form "Login form":
        - textbox "Email"
        - textbox "Password"
        - button "Sign in"
        - link "Forgot password?"
    - contentinfo
  `);
});

// Store snapshot in a separate YAML file (v1.50+)
test('dashboard aria regression', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page).toMatchAriaSnapshot({ path: 'snapshots/dashboard.aria.yml' });
});

// Partial match — use /children for strict child ordering
await expect(page).toMatchAriaSnapshot(`
  - navigation:
    /children:
      - link "Home"
      - link "Products"
      - link "Contact"
`);

// Generate and update: npx playwright test --update-snapshots
```

> **[community]** WHY: `expect(page).toMatchAriaSnapshot()` is sharper than `expect(locator).toMatchAriaSnapshot()` for detecting regressions caused by modal dialogs, notifications banners, or cookie consent overlays that inject ARIA roles at the root level. These elements are invisible to locator-scoped snapshots. Run a full-page ARIA snapshot on critical authenticated landing pages to catch injected markup from analytics or chat tools. [community]

---

### HTML Reporter `noSnippets` Option (v1.54+)

The HTML reporter's `noSnippets` option disables code snippet embedding in the report. Useful for large CI runs where snippet size inflates report files, or for security-conscious teams that don't want source code fragments in CI artifacts.

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  reporter: [
    ['html', {
      outputFolder: 'playwright-report',
      open: 'never',
      noSnippets: true,     // omit source code snippets from all test entries
    }],
  ],
});
```

> **[community]** WHY: On large monorepos with 5000+ tests, the default HTML reporter embeds a code snippet for every test case. This can balloon report size to hundreds of megabytes. `noSnippets: true` reduces report size by 60–80% at the cost of losing inline source context — a good trade-off when the source is already in your VCS and accessible from the test file path link. [community]

---

### `page.close()` / `browser.close()` / `context.close()` with `reason` (v1.40+)

Pass a human-readable reason string to close methods. The reason surfaces in `page.waitForEvent()` rejections and in the Trace Viewer, making it easier to diagnose why a context or page was torn down mid-test.

```typescript
import { test, expect } from '@playwright/test';

test('close context with reason on auth failure', async ({ browser }) => {
  const context = await browser.newContext();
  const page    = await context.newPage();

  await page.goto('/login');
  const loginOk = await page.getByRole('button', { name: 'Sign in' }).isVisible();

  if (!loginOk) {
    // Reason appears in Trace Viewer and waitForEvent rejections
    await context.close({ reason: 'Login page unavailable — auth gate not reached' });
    return;
  }

  // Normal test flow...
  await context.close();
});

// Close page with reason in a custom abort route
test('abort on unexpected redirect', async ({ page }) => {
  await page.route('**', (route) => {
    if (route.request().url().includes('/maintenance')) {
      page.close({ reason: 'Maintenance page redirect detected' });
      return;
    }
    route.continue();
  });

  await page.goto('/dashboard');
  await expect(page.getByRole('main')).toBeVisible();
});
```

> **[community]** WHY: Without `reason`, a `page.close()` from a fixture teardown logs as "Page closed" with no context. In CI runs with 100+ workers, "Page closed" failures are undiagnosable from the JSON report alone. Adding reason strings (e.g., `'Worker restarting after crash'`, `'Auth token expired'`) turns cryptic teardown errors into actionable failure messages. [community]

---

### Additional Community Gotchas (Iteration 29)

---

### 36. `toMatchAriaSnapshot()` fails on locale-specific ARIA labels [community]

`toMatchAriaSnapshot()` includes human-visible text (button labels, heading content, link text) in the ARIA tree. If your app uses `Intl.DateTimeFormat` or server-side i18n for date/time labels, the snapshot will contain locale-dependent text that differs between `en-US` (CI) and other locales.

**Fix:** Filter locale-specific regions using `/url` or a locator-scoped snapshot that excludes the dynamic region. Alternatively, set `locale: 'en-US'` in your project config explicitly so all environments use the same locale for ARIA label generation:

```typescript
// playwright.config.ts
use: {
  locale: 'en-US',  // Pin locale — prevents ARIA snapshot drift from system locale
}
```

> **WHY:** CI runners often inherit a different system locale (e.g., `LANG=C.UTF-8`) from developer machines. Playwright respects `navigator.language` for `locale`-unset contexts, causing `toMatchAriaSnapshot()` to serialize dates as `"12/31/2024"` on one machine and `"31.12.2024"` on another. [community]

---

### 37. `worker.on('console')` errors in parallel CI inflate noise — filter by URL [community]

When running in fully parallel mode with many workers, each service worker registration fires its own `worker.on('console')` listener. If the app registers service workers from multiple origins (CDN workers, analytics, etc.), teams accumulate thousands of irrelevant console messages that slow down the fixture and fill CI logs.

**Fix:** Filter by the service worker URL before recording messages:

```typescript
page.on('worker', (worker) => {
  // Only track errors from your own SW, not third-party ones
  if (!worker.url().startsWith(process.env.BASE_URL ?? '')) return;
  worker.on('console', (msg) => {
    if (msg.type() === 'error') swErrors.push(msg.text());
  });
});
```

> **WHY:** `worker.url()` returns the full URL of the script that registered the worker. Without URL filtering, analytics tag managers that use service workers add their console traffic to your test assertions. [community]

---

### 38. `expect(fn).toPass()` does not reset page state between retries [community]

`toPass()` retries the entire callback, but it does NOT reset any side effects the callback created. If the callback navigates the page, fills a form, or triggers an API call before the assertion fails, those side effects persist into the next retry.

**Fix:** Scope `toPass()` to pure read assertions only — never include write operations inside the callback:

```typescript
// ❌ Anti-pattern: write + assert inside toPass()
await expect(async () => {
  await page.getByRole('button', { name: 'Submit' }).click(); // fires on every retry!
  await expect(page.getByRole('alert')).toHaveText('Success');
}).toPass();

// ✅ Correct: write outside, read assertion inside
await page.getByRole('button', { name: 'Submit' }).click();
await expect(async () => {
  await expect(page.getByRole('alert')).toHaveText('Success');
}).toPass({ timeout: 5_000 });
```

> **WHY:** Each retry inside `toPass()` executes the full callback. A button click inside the callback fires on every attempt — submitting the form multiple times. This causes duplicate record creation, rate-limit errors, or toast-message accumulation that then fails subsequent assertions. [community]

---

### 39. `page.emulateMedia({ contrast })` has no effect in WebKit (Safari) [community]

`prefers-contrast` media query support was added late to WebKit. In Playwright's bundled WebKit build, `emulateMedia({ contrast: 'more' })` sets the underlying flag but WebKit ignores it for most CSS media query evaluations.

**Fix:** Run `prefers-contrast` tests only on Chromium and Firefox projects, and document the WebKit gap:

```typescript
// playwright.config.ts
{
  name: 'contrast-chromium',
  use: { browserName: 'chromium', contrast: 'more' },
},
{
  name: 'contrast-firefox',
  use: { browserName: 'firefox', contrast: 'more' },
},
// No WebKit project for contrast — emulation not reliable
```

> **WHY:** The `prefers-contrast` CSS feature is documented as "partial support" in WebKit. Playwright's emulation layer calls the correct CDP command, but Safari's internal CSS matching engine may not re-evaluate existing computed styles after the flag changes. [community]

---

### 40. Re-running `init-agents` overwrites agent definitions — check them into VCS [community]

`npx playwright init-agents --loop=claude` generates files in `.github/` (or a similar folder). If you run it again after a Playwright update without committing the old versions, you lose the diff history. Teams that do not commit agent definitions lose the ability to roll back to a known-good agent version after a breaking Playwright update changes the tool API.

**Fix:** Always commit agent definition files. Add to your upgrade checklist:

```bash
# After `npm install @playwright/test@latest`:
npx playwright init-agents --loop=claude
git diff .github/   # Review what changed in the agent definitions
git add .github/ && git commit -m "chore: update playwright agent definitions for v<version>"
```

> **WHY:** Agent definition files reference specific Playwright tool names that are versioned. A definition file from v1.56 will reference tools that no longer exist in v1.60 — the agent will hallucinate tool calls or silently skip steps. Treating these files like a lockfile (review diffs, commit explicitly) prevents agent regressions after upgrades. [community]

---

## Additional Key APIs (Iteration 29)

| API | What it does | When to use it |
|-----|-------------|----------------|
| `npx playwright init-agents --loop=<env>` | Generate agent definition files for Claude/VS Code/OpenCode | Run once on setup; re-run after every Playwright minor version bump |
| `worker.on('console', handler)` | Capture console messages from service/dedicated workers (v1.57+) | Catch silent SW errors in CI; verify background sync log output |
| `page.emulateMedia({ contrast: 'more' })` | Simulate `prefers-contrast: more` CSS media feature (v1.51+) | Accessibility testing for high-contrast and forced-colors modes |
| `expect(fn).toPass({ intervals })` | Custom retry interval array for `toPass()` polling (v1.44+) | API polling tests that need back-off; avoid 100 ms default hammering |
| `expect(page).toHaveURL(fn)` | Predicate-based URL assertion with auto-retry (v1.44+) | Complex URL conditions (multi-param, conditional logic) |
| `expect(page).toHaveURL(url, { ignoreCase })` | Case-insensitive URL matching (v1.44+) | Apps with inconsistent URL casing between environments |
| `expect(page).toMatchAriaSnapshot(template)` | Full-page ARIA tree assertion (v1.60+) | Catch root-level ARIA regressions from banners, modals, injected widgets |
| `reporter: [['html', { noSnippets: true }]]` | Omit code snippets from HTML report (v1.54+) | Large CI runs where report file size is a constraint |
| `page.close({ reason })` | Close with diagnostic message visible in Trace Viewer (v1.40+) | Custom fixtures and route handlers that conditionally abort |
| `context.close({ reason })` | Context close with reason (v1.40+) | Fixture teardown with actionable error messages |

---

### Additional Breaking Changes (v1.54–v1.58)

| Version | Change | Migration |
|---------|--------|-----------|
| v1.54 | `-gv` CLI flag removed | Use `--grep-invert` instead |
| v1.54 | `npx playwright open` no longer launches test recorder | Use `npx playwright codegen` for recording |
| v1.55 | Chromium extension manifest v2 support dropped | Upgrade to manifest v3 |
| v1.57 | `page.accessibility` API **removed** | Use `toMatchAriaSnapshot()` or `@axe-core/playwright` |
| v1.57 | Node.js 16 support dropped; Node.js 18 deprecated | Upgrade to Node.js 20 or 22 |
| v1.58 | `_react` and `_vue` selector engines removed | Use `getByRole`, `getByTestId`, or CSS selectors |
| v1.58 | `:light` selector suffix removed | Use standard CSS selectors without `:light` |
| v1.58 | `devtools` option removed from `browserType.launch()` | Use `args: ['--auto-open-devtools-for-tabs']` |
| v1.59 | macOS 14 WebKit support removed | Run WebKit tests on macOS 15+ or Linux |
| v1.60 | `Locator.ariaRef()` removed | Use `getByRole()` with `description` option or ARIA snapshot matching |
| v1.60 | `handle` option on `exposeBinding()` removed | Use standard callback approach without handle |
| v1.60 | `logger` option on `connect()`/`connectOverCDP()` removed | Use environment-level logging instead |
| v1.60 | `videosPath`/`videoSize` context options removed | Use `video: { dir, size }` object in context options |

---

## Additional Key APIs (Iteration 30 — v1.60)

| API | What it does | When to use it |
|-----|-------------|----------------|
| `await using har = await context.tracing.startHar(path)` | First-class HAR recording via async disposable (v1.60+) | Capture network traffic alongside traces; auto-finalizes on scope exit |
| `tracing.stopHar(path)` | Stop and save HAR recording manually (v1.60+) | When not using `await using`; pair with try/finally in fixtures |
| `locator.drop({ files })` | Simulate external file drop onto element (v1.60+) | Test drag-and-drop upload zones without using `<input type="file">` |
| `locator.drop({ data })` | Simulate clipboard/DataTransfer drop with arbitrary MIME types (v1.60+) | Test custom DnD handlers that read `event.dataTransfer.getData()` |
| `test.abort(message?)` | Abort current test from fixture, hook, or route handler (v1.60+) | Guard against test misuse (e.g., prevent publishing in a read-only test run) |
| `browser.on('context', handler)` | Subscribe to new-context events on browser instance (v1.60+) | Centralize context-level setup (routing, headers) across multiple contexts |
| `context.on('pageclose', handler)` | Fires when a page inside the context is closed (v1.60+) | Cleanup teardown hooks scoped to page lifetime without test-level coupling |
| `context.on('pageload', handler)` | Fires when any page inside the context reaches load state (v1.60+) | Global navigation audit — log all load events for flakiness investigation |
| `context.on('frameattached', handler)` | Fires when a frame is attached to any page in the context (v1.60+) | Monitor iframe injection for security testing |
| `context.on('framenavigated', handler)` | Fires when a frame navigates in any page in the context (v1.60+) | Track all frame-level navigations for SPA routing assertions |
| `page.getByRole(role, { description })` | Match element by accessible role AND accessible description (v1.60+) | Disambiguate buttons/links that share the same name but differ by aria-description |
| `expect(locator).toHaveCSS(prop, val, { pseudo })` | Assert computed styles on `::before`/`::after` pseudo-elements (v1.60+) | Test CSS decorative content injected via pseudo-elements |
| `locator.highlight({ style })` | Highlight element with inline CSS override (v1.60+) | Custom visual markers in codegen; debug complex selectors interactively |
| `page.hideHighlight()` | Remove all locator highlights from the page (v1.60+) | Clean up highlight overlays before screenshots or assertions |
| `locator.ariaSnapshot({ boxes: true })` | Include bounding-box metadata `[box=x,y,w,h]` in ARIA snapshot (v1.60+) | Feed spatial ARIA data to AI agents; verify element positioning in a11y tests |

---

## HAR Recording with `tracing.startHar` (v1.60)

HAR recording is now a first-class tracing API, returned as an async disposable. This lets you capture network traffic in the same lifecycle block as the test, with automatic finalization via `await using`.

```typescript
import { test, expect } from '@playwright/test';

test('captures HAR for network debugging', async ({ context }) => {
  // `await using` ensures HAR is finalized even if the test throws
  await using har = await context.tracing.startHar('test-artifacts/trace.har', {
    content: 'embed',   // Embed response bodies inside the HAR (default: 'omit')
    mode: 'full',       // 'full' | 'minimal'
    urlFilter: /api\//  // Only record matching URLs
  });

  const page = await context.newPage();
  await page.goto('/dashboard');
  await page.getByRole('button', { name: 'Load data' }).click();
  await expect(page.getByRole('grid')).toBeVisible();
  // HAR is automatically saved when `har` goes out of scope
});
```

**Fixture pattern (manual stopHar for broader scope):**

```typescript
// e2e/fixtures/har.ts
import { test as base } from '@playwright/test';
import path from 'path';

export const test = base.extend({
  context: async ({ context }, use, testInfo) => {
    await context.tracing.startHar(
      path.join(testInfo.outputDir, 'network.har'),
      { urlFilter: /your-api-domain/ }
    );
    await use(context);
    await context.tracing.stopHar();
  },
});
```

> **WHY:** Unlike `recordHar` which must be set at context creation, `tracing.startHar()` can be started mid-test and restarted between test phases — useful for isolating the HAR to a specific user flow. [official]

---

## File Drop Testing with `locator.drop` (v1.60)

`locator.drop()` simulates an external drag-and-drop operation, dispatching the full sequence of `dragenter`, `dragover`, and `drop` events with a synthetic `DataTransfer` object. This is the correct way to test drag-and-drop upload zones — unlike `setInputFiles()`, which only works on `<input type="file">`.

```typescript
import { test, expect } from '@playwright/test';

test('accepts file drop on upload zone', async ({ page }) => {
  await page.goto('/upload');

  // Drop a file onto the upload zone
  await page.locator('#dropzone').drop({
    files: {
      name: 'report.pdf',
      mimeType: 'application/pdf',
      buffer: Buffer.from('%PDF-1.4 mock content'),
    },
  });

  await expect(page.getByText('report.pdf')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Upload' })).toBeEnabled();
});

test('accepts custom DataTransfer data', async ({ page }) => {
  await page.goto('/kanban');

  // Drop plain-text or URI data (e.g., drag from external app)
  await page.locator('[data-column="done"]').drop({
    data: {
      'text/plain': 'TASK-123',
      'text/uri-list': 'https://jira.example.com/browse/TASK-123',
    },
  });

  await expect(page.locator('[data-column="done"]').getByText('TASK-123')).toBeVisible();
});
```

> **Anti-pattern:** Using `page.mouse.move()` + `page.mouse.down()` + `page.mouse.up()` for file drops does NOT populate `event.dataTransfer.files`. Always use `locator.drop({ files })` for file-drop testing. [community]

---

## Test Abort Guard with `test.abort` (v1.60)

`test.abort()` lets fixtures or route handlers abort the running test with a descriptive message. This is different from throwing an error — it marks the test as intentionally aborted (not failed) and surfaces a clear message in the report.

```typescript
import { test, expect } from '@playwright/test';

// Protect shared staging from destructive operations
test('read-only audit of published items', async ({ page }) => {
  // Abort if the test accidentally tries to publish
  await page.route('**/api/v1/publish', (route) => {
    test.abort('Read-only test must not call /publish. Use ?preview=true.');
    route.abort();
  });

  await page.goto('/admin/posts');
  await expect(page.getByRole('list', { name: 'Published posts' })).toBeVisible();
  // Safe: no publish call → test completes normally
});
```

**Fixture-level abort guard:**

```typescript
// e2e/fixtures/safe-context.ts
import { test as base } from '@playwright/test';

export const test = base.extend({
  page: async ({ page }, use) => {
    await page.route('**/admin/delete/**', (route) => {
      test.abort('DELETE routes are blocked in the test suite. Use the API teardown fixture instead.');
      route.abort();
    });
    await use(page);
  },
});
```

> **WHY:** Throwing `new Error()` in a route handler marks the test as failed and may leave the route handler registered, causing subsequent tests to abort too. `test.abort()` cleanly terminates only the current test and unregisters handlers as part of normal teardown. [community]

---

## Browser & Context Lifecycle Events (v1.60)

`browser.on('context')` fires whenever a new `BrowserContext` is created — including contexts created by `browser.newContext()` within test fixtures. `BrowserContext` now also mirrors page-level events, so you can track navigation and frame changes globally without attaching listeners to each individual page.

```typescript
import { chromium, Browser, BrowserContext } from '@playwright/test';

// Global context auditing (e.g., in globalSetup)
const browser: Browser = await chromium.launch();

browser.on('context', (context: BrowserContext) => {
  // Attach a global route to every new context
  context.route('**/api/**', (route) => {
    console.log(`[audit] ${route.request().method()} ${route.request().url()}`);
    route.continue();
  });

  // Track all page close events across the browser
  context.on('pageclose', (page) => {
    console.log(`[lifecycle] Page closed: ${page.url()}`);
  });

  // Track all load events
  context.on('pageload', (page) => {
    console.log(`[lifecycle] Page loaded: ${page.url()}`);
  });

  // Track iframe injection (security monitoring)
  context.on('frameattached', (frame) => {
    if (frame.url().includes('ads.')) {
      console.warn(`[security] Ad iframe injected: ${frame.url()}`);
    }
  });
});
```

**Fixture pattern for per-context auditing:**

```typescript
// e2e/fixtures/audit.ts
import { test as base } from '@playwright/test';

export const test = base.extend({
  context: async ({ browser }, use) => {
    const context = await browser.newContext();
    const navigationLog: string[] = [];

    context.on('framenavigated', (frame) => {
      if (frame === frame.page().mainFrame()) {
        navigationLog.push(frame.url());
      }
    });

    await use(context);

    // Attach navigation log to test results for debugging
    console.log('Navigation trace:', navigationLog);
    await context.close();
  },
});
```

> **WHY:** Before v1.60, you had to attach event listeners to each page individually. The context-level events let you build a single global observer that tracks every page across every navigation — critical for SPAs that open popups or redirect chains. [community]

---

## CSS Pseudo-Element Assertions with `toHaveCSS` (v1.60)

The `pseudo` option on `expect(locator).toHaveCSS()` reads computed styles from `::before` and `::after` pseudo-elements, making it possible to assert decorative content injected via CSS.

```typescript
import { test, expect } from '@playwright/test';

test('required field indicator uses correct CSS color', async ({ page }) => {
  await page.goto('/form');
  const label = page.getByLabel('Email');

  // Assert the ::before pseudo-element color (the required * indicator)
  await expect(label).toHaveCSS('color', 'rgb(220, 38, 38)', { pseudo: '::before' });

  // Assert content property (if CSS content is set)
  await expect(label).toHaveCSS('content', '"*"', { pseudo: '::before' });
});

test('tooltip arrow uses correct background', async ({ page }) => {
  await page.goto('/help');
  await page.getByRole('button', { name: 'Help' }).hover();
  const tooltip = page.locator('[role="tooltip"]');

  // Tooltip arrow is typically a ::before or ::after pseudo-element
  await expect(tooltip).toHaveCSS('background-color', 'rgb(0, 0, 0)', { pseudo: '::after' });
});
```

> **WHY:** Before this API, testing pseudo-element styles required `page.evaluate()` with `window.getComputedStyle(el, '::before')`, which returns a live `CSSStyleDeclaration` but does not auto-wait or retry on assertion failure. The `pseudo` option integrates full web-first retry behavior. [community]

---

## Accessible Description Matching with `getByRole` (v1.60)

The new `description` option lets you match elements by their accessible description (set via `aria-description` or `aria-describedby`) in addition to their role and name. This disambiguates elements that share the same role and name but serve different purposes.

```typescript
import { test, expect } from '@playwright/test';

test('opens correct delete dialog', async ({ page }) => {
  await page.goto('/settings/users');

  // Two "Delete" buttons exist — differentiated by aria-description
  const deleteUserBtn = page.getByRole('button', {
    name: 'Delete',
    description: 'Delete user account permanently',
  });
  const deleteSessionBtn = page.getByRole('button', {
    name: 'Delete',
    description: 'End active session',
  });

  await deleteSessionBtn.click();
  await expect(page.getByRole('dialog')).toHaveText(/End active session/);
});
```

> **WHY:** Without the `description` filter, `page.getByRole('button', { name: 'Delete' })` throws a `strict mode violation` error when multiple Delete buttons are present. Previously you had to fall back to `locator.filter({ hasText })` or CSS selectors — losing the semantic intent. [community]

---

## Gotchas — v1.60 Edition

### 41. `locator.drop()` does not trigger `input` or `change` events on `<input type="file">` [community]

`locator.drop()` dispatches `dragenter`, `dragover`, and `drop` events with a `DataTransfer` object — it does NOT trigger the native file input change event. If your upload zone is implemented as an `<input type="file">` that listens for `change`, you must use `setInputFiles()` instead. `locator.drop()` is only for custom JavaScript drop handlers.

```typescript
// ❌ Wrong: <input type="file"> needs setInputFiles, not drop()
await page.locator('input[type="file"]').drop({ files: { name: 'f.txt', ... } });

// ✅ Correct for <input type="file">
await page.locator('input[type="file"]').setInputFiles('./fixtures/f.txt');

// ✅ Correct for custom JS drop zone (no <input>)
await page.locator('#custom-dropzone').drop({ files: { name: 'f.txt', ... } });
```

> **WHY:** Native file inputs use a browser-native file picker change event pipeline that `DataTransfer` synthetic events bypass. The drag-and-drop spec and the file input spec are separate browser behaviors. [community]

---

### 42. `browser.on('context')` does NOT fire for contexts created before the listener is registered [community]

If you call `browser.on('context', handler)` after `browser.newContext()` has already been called (e.g., in a `beforeEach` that runs after the default context is created), the handler will not fire for the already-existing context.

```typescript
// ❌ Too late — default context already exists
test.beforeEach(async ({ browser, context }) => {
  // `context` is already created by the test fixture
  browser.on('context', handler); // Will NOT fire for this test's context
});

// ✅ Correct: register in globalSetup or a worker-scoped fixture
// globalSetup.ts
export default async function globalSetup() {
  // Worker-scoped browser setup
}
// Or use a worker fixture:
export const test = base.extend({
  browser: async ({ playwright }, use) => {
    const browser = await playwright.chromium.launch();
    browser.on('context', auditHandler);
    await use(browser);
    await browser.close();
  },
});
```

> **WHY:** Event listeners in Node.js are synchronous registrations — you can only receive future events, not past ones. The test harness creates the default context as part of fixture initialization, which happens before `beforeEach` runs. [community]

---

### 43. HAR recording via `tracing.startHar()` buffers responses in memory until `stopHar` [community]

When using `context.tracing.startHar()` with `content: 'embed'`, all response bodies are held in memory until `stopHar()` or the async disposable scope exit. For tests that download large blobs or stream video, this can cause OOM errors in long-running test suites.

```typescript
// ❌ Risky: embeds all response bodies including large downloads
await using har = await context.tracing.startHar('trace.har', { content: 'embed' });

// ✅ Safer: use urlFilter to exclude large binary endpoints
await using har = await context.tracing.startHar('trace.har', {
  content: 'embed',
  urlFilter: /\/api\//,  // Only record API calls, skip /static/ and /assets/
});
```

> **WHY:** `content: 'embed'` is the default for convenience, but in suites that test file download pages or media streaming endpoints, the accumulated buffer grows linearly with the number of tests and can exhaust worker memory mid-run. Use `urlFilter` to scope what gets embedded. [community]

---

## `response.httpVersion()` and `request.existingResponse()` — HTTP Protocol Assertions (v1.59)

Two new network inspection APIs added in v1.59 for non-blocking response inspection and HTTP version verification.

### `response.httpVersion()` — Assert HTTP/2 or HTTP/3 Usage

Returns the HTTP version string used for the response (`'HTTP/1.1'`, `'HTTP/2.0'`, `'HTTP/3.0'`). Use this to guard against regressions where CDN or reverse-proxy config changes silently downgrade protocol negotiation.

```typescript
import { test, expect } from '@playwright/test';

test('critical API endpoint negotiates HTTP/2', async ({ page }) => {
  const [response] = await Promise.all([
    page.waitForResponse(/\/api\/data/),
    page.goto('/dashboard'),
  ]);

  // Assert the protocol version — guard against CDN misconfiguration
  expect(response.httpVersion()).toBe('HTTP/2.0');
});

test('static assets served over HTTP/2', async ({ context }) => {
  const request = context.request;

  const response = await request.get('https://example.com/static/app.js');
  expect(response.httpVersion()).toBe('HTTP/2.0');
  await response.dispose();
});
```

> **WHY:** A CDN config change that disables HTTP/2 multiplexing can double page load times silently — the UI still renders but performance regresses significantly. Adding `httpVersion()` assertions to smoke tests catches this class of infrastructure regression before it impacts users. [community]

---

### `request.existingResponse()` — Non-Blocking Response Inspection

`request.existingResponse()` returns the `Response` if the request has already completed, or `null` if the response hasn't arrived yet. Unlike `page.waitForResponse()`, it never blocks — it's a synchronous snapshot of network state at the time of the call.

```typescript
import { test, expect } from '@playwright/test';

test('inspect already-completed prefetch response', async ({ page }) => {
  // Navigate — browser prefetches several resources during load
  await page.goto('/product/123');

  // Find a specific request that should have completed during page load
  const requests = page.request.all?.() ??
    (await page.evaluate(() => performance.getEntriesByType('resource')));

  // Check a route handler that inspects in-flight requests
  await page.route('**/api/related-products', async route => {
    const existing = route.request().existingResponse();
    if (existing) {
      // Response already cached — fulfill from existing to avoid double-fetch
      await route.fulfill({ response: existing });
    } else {
      // Not cached yet — let it pass through
      await route.continue();
    }
  });

  await page.getByRole('button', { name: 'See related' }).click();
  await expect(page.getByTestId('related-products')).toBeVisible();
});
```

> **WHY:** Before `existingResponse()`, a route handler that wanted to conditionally intercept based on whether a response existed had to track request state externally in a `Map`. The new API provides a native, race-condition-free way to inspect in-flight state. [official]

---

## Planner → Generator → Healer: Three-Agent Workflow (v1.56+)

The `npx playwright init-agents` command generates three agent definition files, each with a distinct role in AI-assisted test authoring. The workflow runs sequentially: Planner creates a plan, Generator produces tests from the plan, Healer repairs failing tests.

```typescript
// Directory structure after npx playwright init-agents --loop=claude
// repo/
//   .github/          ← agent definition files (commit these!)
//   specs/            ← Markdown test plans (Planner output)
//     checkout-flow.md
//   tests/            ← Generated Playwright specs (Generator output)
//     seed.spec.ts    ← Human-written seed test for environment bootstrap
//     checkout-basic.spec.ts
//   playwright.config.ts
```

### Planner Agent

Explores the application and produces structured Markdown test plans. It runs the seed test to establish the correct test environment before generating plans.

```markdown
<!-- specs/checkout-flow.md — example Planner output -->
# Test Plan: Checkout Flow

## Scenario: Guest checkout with credit card
1. Navigate to /products
2. Add item to cart
3. Proceed to checkout (skip login)
4. Fill shipping details
5. Enter credit card number (test: 4242 4242 4242 4242)
6. Assert order confirmation page visible
7. Assert order number in confirmation email link

## Edge cases
- Empty cart redirect to /products
- Invalid card number shows inline error
```

### Generator Agent

Transforms Markdown plans into runnable Playwright tests. It verifies selectors live by executing the scenario against the real application.

```typescript
// tests/checkout-basic.spec.ts — example Generator output
import { test, expect } from '@playwright/test';

test('guest checkout with credit card', async ({ page }) => {
  await test.step('Navigate to products', async () => {
    await page.goto('/products');
    await expect(page.getByRole('heading', { name: /products/i })).toBeVisible();
  });

  await test.step('Add item to cart', async () => {
    await page.getByRole('button', { name: /add to cart/i }).first().click();
    await expect(page.getByRole('status')).toContainText('1 item');
  });

  await test.step('Proceed to checkout', async () => {
    await page.getByRole('link', { name: /checkout/i }).click();
    await page.getByRole('button', { name: /guest checkout/i }).click();
  });
  // ... further steps generated from plan
});
```

### Healer Agent

Runs failing tests, replays steps, inspects the current UI state, and suggests patches. It operates on first retry — the standard Playwright retry mechanism triggers it.

```typescript
// The healer fires when a test fails and retries is >= 1
// In playwright.config.ts:
export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  // On retry, the healer agent analyses the failure, patches the locator,
  // and re-runs. If it can't heal after `retries` attempts, it marks
  // the test as `flaky` or `failed` with a patch suggestion in the report.
});
```

**Healer-agent-aware locator hygiene:** Write locators that give the healer enough context to find the "equivalent element" after a UI change. Role-based locators (`getByRole`) are the easiest for the healer to repair because semantic roles survive component refactors.

> **WHY:** The Planner-Generator workflow eliminates the blank-page problem for new test suites — you get a full spec from a description, not from scratch. The Healer removes the test maintenance burden after UI changes: instead of manually updating dozens of selectors, the healer proposes a patch that a developer reviews and merges. [official]

---

## Additional Key APIs (Iteration 31 — v1.59)

| API | What it does | When to use it |
|-----|-------------|----------------|
| `response.httpVersion()` | Returns HTTP version string (`'HTTP/1.1'`, `'HTTP/2.0'`) (v1.59+) | Assert CDN/proxy config hasn't downgraded protocol |
| `request.existingResponse()` | Returns response if already received, `null` otherwise (v1.59+) | Conditional route logic based on cached response state |
| `page.screencast.showChapter(title)` | Display named chapter overlay during recording (v1.59+) | Annotate screencast at key test steps for demo videos |
| `page.screencast.showActions({ position })` | Highlight clicked/typed elements in recording (v1.59+) | Make test evidence videos self-documenting |
| `locator.normalize()` | Convert brittle locator to best-practice equivalent (v1.59+) | Refactoring tool — use in development, hardcode result |
| `browserContext.setStorageState(path)` | Replace all cookies/storage in existing context (v1.59+) | Role-switch without creating a new browser context |
| `context.isClosed()` | Returns `true` after context is disposed (v1.59+) | Guard teardown fixtures against double-close |
| `consoleMessage.timestamp()` | Unix timestamp (ms) of when the console message was emitted (v1.59+) | Correlate console errors with network events in custom reporters |
| `tracing.start({ live: true })` | Flush trace incrementally during test (v1.59+) | Real-time trace inspection on long-running suites |
| `request.existingResponse()` | Non-blocking response state check (v1.59+) | Detect cached responses in route handlers |
| `browserType.connectOverCDP({ noDefaults: true })` | Connect without Playwright's default context overrides (v1.60+) | Integration with Chromium instances that manage their own defaults |

---

## Gotchas — v1.59/v1.61 Edition

### 44. `page.screencast` is Chromium-only — throws in Firefox/WebKit [community]

`page.screencast.start()` throws a "not implemented" or similar runtime error when the test project uses Firefox or WebKit. The Screencast API depends on Chromium DevTools Protocol (CDP) capabilities not available in other engines.

```typescript
// ❌ Will throw at runtime on Firefox/WebKit projects
test('record checkout flow', async ({ page, browserName }) => {
  await page.screencast.start({ path: 'checkout.webm' }); // ← throws on FF/WebKit
});

// ✅ Guard with browserName or skip in non-Chromium projects
test('record checkout flow', async ({ page, browserName }) => {
  test.skip(browserName !== 'chromium', 'Screencast API is Chromium-only');
  await page.screencast.start({ path: 'checkout.webm' });
  await page.goto('/checkout');
  await page.screencast.stop();
});

// ✅ Or configure Screencast recording only in the chromium project:
// playwright.config.ts
// projects: [
//   { name: 'chromium', use: { ...devices['Desktop Chrome'] } },  // screencast works
//   { name: 'firefox',  use: { ...devices['Desktop Firefox'] } }, // skip screencast tests
// ]
```

> **WHY:** The Screencast API wraps CDP's `Page.startScreencast` command, which has no equivalent in the WebDriver BiDi protocol used by Firefox and WebKit. Teams that run cross-browser matrix tests must gate screencast tests to the Chromium project or conditionally skip. [community]

---

### 45. `request.existingResponse()` returns `null` inside a route handler before `route.fetch()` [community]

In a `page.route()` handler, `route.request().existingResponse()` returns `null` until the actual HTTP response arrives. Since route handlers intercept requests *before* a response exists, calling `existingResponse()` inside the handler always returns `null` unless a previous route or intercept has already resolved the response.

```typescript
// ❌ Incorrect: existingResponse() is null inside route handler for NEW requests
await page.route('/api/data', async route => {
  const existing = route.request().existingResponse();
  if (existing) {
    await route.fulfill({ response: existing }); // ← never reached for first request
  }
  await route.continue();
});

// ✅ Correct: use existingResponse() in page-level listeners for SUBSEQUENT navigation
page.on('requestfinished', request => {
  const response = request.existingResponse();
  if (response && request.url().includes('/api/data')) {
    // response is now available — log, assert, or store
  }
});

// ✅ Use case: detect duplicate requests to same endpoint
const seen = new Set<string>();
page.on('requestfinished', request => {
  const key = `${request.method()}:${request.url()}`;
  if (seen.has(key)) {
    console.warn(`Duplicate request detected: ${key}`);
  }
  seen.add(key);
});
```

> **WHY:** `existingResponse()` is a polling accessor, not a trigger. Its primary use case is in `page.on('requestfinished')` or `page.on('response')` listeners — not inside `page.route()` where the response doesn't exist yet. Confusing the two causes route handlers that silently fall through without the expected intercept behavior. [community]

---

### 46. `locator.normalize()` may produce `getByTestId()` instead of `getByRole()` [community]

`locator.normalize()` upgrades brittle CSS/XPath locators to Playwright best practices using heuristics. However, when an element has both a `data-testid` attribute and a semantic ARIA role, `normalize()` may prefer `getByTestId()` over `getByRole()`. This is technically correct (testids are stable) but violates the recommended selector hierarchy where `getByRole()` is preferred for better accessibility test coverage.

```typescript
// Element: <button data-testid="submit-btn" aria-label="Submit order">Submit</button>

const brittle = page.locator('button.submit-btn');
const normalized = brittle.normalize();
// normalize() might return: page.getByTestId('submit-btn')
// But the preferred selector is: page.getByRole('button', { name: 'Submit order' })

// ✅ Always review normalize() output before hardcoding
// If normalize() suggests getByTestId, check if getByRole would work instead:
const preferred = page.getByRole('button', { name: /submit order/i });

// ✅ Use normalize() as a starting point, not a final answer
// Steps:
// 1. brittle.normalize() → see what it suggests
// 2. If getByTestId: verify the element has a meaningful ARIA role
// 3. If role + accessible name unambiguously identifies it: use getByRole
// 4. If element has no role or the role is generic (div/span): accept getByTestId
```

> **WHY:** `locator.normalize()` optimizes for selector stability and uniqueness, not for ARIA coverage. In projects that use `data-testid` extensively (common with React component libraries), `normalize()` will systematically produce `getByTestId()` suggestions — which are stable but bypass accessibility assertions. The locator hierarchy (`getByRole` > `getByLabel` > `getByText` > `getByTestId`) is a human judgment call that automation cannot fully make for you. [community]

---

### Gotcha #47 — `webError.location()` gives precise JS error source coordinates (v1.60+)

**New in v1.60:** `WebError` now exposes a `.location()` method that returns the source URL, line number, and column of the JavaScript error thrown in the page — analogous to `ConsoleMessage.location()` for `console.*` calls. Without `.location()`, you only know *that* an error occurred; with it you can pinpoint *where* in your bundle it originated.

```typescript
// ❌ Before v1.60 — you know an error fired but not its source position
page.on('pageerror', (err) => {
  console.error('Uncaught JS error:', err.message);
  // No source coordinates available on the Error object itself
});

// ✅ v1.60+: use page.on('weberror', ...) to get full location data
import { expect, test, type WebError } from '@playwright/test';

test('no uncaught JS errors with source location', async ({ page }) => {
  const errors: { message: string; url: string; line: number; col: number }[] = [];

  page.on('weberror', (webError: WebError) => {
    const loc = webError.location();           // { url, lineNumber, columnNumber }
    errors.push({
      message: webError.error().message,
      url:     loc.url,
      line:    loc.lineNumber,
      col:     loc.columnNumber,
    });
  });

  await page.goto('/');
  await page.getByRole('button', { name: 'Load data' }).click();

  // Assert no uncaught errors occurred
  expect(errors, `Uncaught JS errors: ${JSON.stringify(errors, null, 2)}`).toHaveLength(0);
});

// ✅ Fixture: collect all WebErrors for every test
// fixtures/web-errors.ts
import { test as base, type WebError } from '@playwright/test';

type WebErrorRecord = { message: string; url: string; line: number; col: number };

export const test = base.extend<{ webErrors: WebErrorRecord[] }>({
  webErrors: async ({ page }, use) => {
    const collected: WebErrorRecord[] = [];
    page.on('weberror', (e: WebError) => {
      const loc = e.location();
      collected.push({ message: e.error().message, url: loc.url, line: loc.lineNumber, col: loc.columnNumber });
    });
    await use(collected);
  },
});

// In a test:
test('zero JS errors on checkout flow', async ({ page, webErrors }) => {
  await page.goto('/checkout');
  await page.getByRole('button', { name: 'Place order' }).click();
  expect(webErrors).toHaveLength(0);
});

// ✅ Distinguish webError from consoleMessage
// page.on('weberror')  → uncaught exceptions / unhandled promise rejections
// page.on('console')   → explicit console.error / console.warn calls
// Use both to get full observability:
page.on('weberror', (e: WebError) => {
  const { url, lineNumber, columnNumber } = e.location();
  console.error(`[WEBERROR] ${e.error().message} @ ${url}:${lineNumber}:${columnNumber}`);
});
page.on('console', (msg) => {
  if (msg.type() === 'error') {
    const { url, lineNumber, columnNumber } = msg.location();
    console.error(`[CONSOLE ERROR] ${msg.text()} @ ${url}:${lineNumber}:${columnNumber}`);
  }
});
```

> **WHY:** Minified production bundles make `pageerror` messages near-useless — the stack trace references `bundle.min.js:1:84921`. With `webError.location()` you get the exact position, which (when paired with a source map) resolves to the original TypeScript file and line. Additionally, `page.on('weberror')` fires for *both* uncaught exceptions and unhandled promise rejections, whereas `page.on('pageerror')` only fires for uncaught exceptions. Switching to `weberror` closes that gap. [official]

---

### Gotcha \#48 — `fastForward()` vs `runFor()` / `tick()`: intermediate callbacks skipped vs. fired

```typescript
// ❌ fastForward() jumps the clock in ONE step — intermediate timer callbacks
//    are NOT invoked if they fire at sub-intervals within the window.
//    Use it only when you need the clock to land at a specific time and
//    don't care about the intermediate ticks.
test('wrong: counter stays at 0 because intermediate ticks are skipped', async ({ page }) => {
  await page.clock.install();
  await page.goto('/counter'); // setInterval(increment, 1000)
  await page.clock.fastForward(5_000); // jumps straight to t+5 s
  // Counter may still read "0" — the five 1-s callbacks were never fired
  await expect(page.getByTestId('count')).toHaveText('0'); // passes, but wrong intent
});

// ✅ runFor() / tick() advance the clock incrementally, firing every timer
//    callback that falls within the elapsed window in chronological order.
test('correct: counter reaches 5 because each 1-s tick fires', async ({ page }) => {
  await page.clock.install();
  await page.goto('/counter');
  await page.clock.runFor(5_000); // fires t+1 s, t+2 s, t+3 s, t+4 s, t+5 s
  await expect(page.getByTestId('count')).toHaveText('5');
});

// tick() is a direct alias — choose whichever reads more clearly in context
await page.clock.tick('05:00'); // string shorthand: "MM:SS" format also accepted
```

> **WHY:** `fastForward()` is modelled after Sinon's `clock.tick()` with "skip to the end" semantics — it sets `Date.now()` to the target time and only fires timers whose *deadline* is at or before that target, but does so in a single evaluation pass. `runFor()` / `tick()` repeatedly advance the clock by the smallest pending timer interval, invoking each callback before moving forward, which mirrors how a real clock behaves. The distinction matters for any app that chains timers (e.g., `setTimeout` inside a `setInterval` callback) or that uses `requestAnimationFrame` sequences. When in doubt, prefer `runFor()`. [community]

---

### `connectOverCDP({ noDefaults: true })` — Attach to a Real Browser Without Overriding Its Settings (v1.60+)

By default, `connectOverCDP()` applies Playwright's own defaults to the attached browser's existing default context: it forces `colorScheme: 'light'`, `reducedMotion: 'no-preference'`, `forcedColors: 'none'`, and `contrast: 'no-preference'`, and enables focus emulation. This is fine for automation-only browsers, but wrong when attaching to a user's daily-driver browser — their real system preferences get silently overridden.

Set `noDefaults: true` to skip those overrides and preserve the real browser's existing settings.

```typescript
import { chromium, type Browser } from '@playwright/test';

// ✅ Attach to a running Chrome instance without clobbering its settings
const browser: Browser = await chromium.connectOverCDP('http://localhost:9222', {
  noDefaults: true,  // v1.60+: skip Playwright's default context overrides
});

// The default context retains the user's real colorScheme, reducedMotion, etc.
const [defaultContext] = browser.contexts();
const page = defaultContext.pages()[0];

// You can still create new contexts — those DO receive Playwright's defaults
const isolatedCtx = await browser.newContext({ colorScheme: 'dark' });
const isolatedPage = await isolatedCtx.newPage();
await isolatedPage.goto('https://example.com');

// Always close the isolated context; never close the default context
await isolatedCtx.close();
await browser.close();
```

> **WHY:** When writing tests that intentionally validate system-theme-dependent UI (dark-mode widgets, high-contrast ARIA landmarks, reduced-motion animations), you want the real OS/browser preference to flow through unchanged. Without `noDefaults: true`, Playwright resets everything to its built-in defaults the moment it connects — making theme-sensitive tests always pass even when they should detect a mismatch, or always fail because the theme was unexpectedly forced. [official]

---

### Gotcha \#49 — `connectOverCDP()` resets the default context's media settings unless `noDefaults: true` [community]

When you attach Playwright to an existing Chromium process with `connectOverCDP()` and the target browser has `prefers-color-scheme: dark` or `prefers-reduced-motion: reduce` set (either by the OS or by browser flags), Playwright **overwrites** those values the instant it attaches — even before any test action runs.

```typescript
// ❌ connectOverCDP without noDefaults: media preferences silently overwritten
import { chromium } from '@playwright/test';

const browser = await chromium.connectOverCDP('http://localhost:9222');
const [ctx] = browser.contexts();
const page = ctx.pages()[0];

// The user had dark mode enabled. But colorScheme is now 'light' — Playwright reset it.
// This assertion will PASS when it should FAIL (or vice versa for dark-mode tests):
await expect(page.locator('body')).toHaveCSS('background-color', 'rgb(255, 255, 255)');

// ✅ Preserve the user's actual browser settings
const browserWithDefaults = await chromium.connectOverCDP('http://localhost:9222', {
  noDefaults: true,
});
const [realCtx] = browserWithDefaults.contexts();
const realPage = realCtx.pages()[0];

// Now colorScheme reflects what the OS/browser actually has set.
// Theme-sensitive CSS assertions behave correctly.
await expect(realPage.locator('body')).toHaveCSS('background-color', 'rgb(18, 18, 18)'); // dark bg
```

**Affected defaults reset by `connectOverCDP()` without `noDefaults`:**

| Setting | Playwright default applied |
|---------|---------------------------|
| `colorScheme` | `'light'` |
| `reducedMotion` | `'no-preference'` |
| `forcedColors` | `'none'` |
| `contrast` | `'no-preference'` |
| `acceptDownloads` | enabled |
| Focus emulation | enabled |

> **[community]** WHY: This is a silent regression trap. Teams writing integration tests against a real staging browser (via `connectOverCDP`) and also running visual baseline tests against theme-sensitive components discover that their test environment never exercises the dark/high-contrast code paths — because Playwright quietly forced light mode at attach time. The fix is a one-line `noDefaults: true`; the difficulty is knowing the problem exists. [community]

---

### ARIA Snapshot `/children` Matching Modes — `contain`, `equal`, `deep-equal` (v1.52+)

By default, `toMatchAriaSnapshot()` uses **partial matching**: as long as the specified children appear in the snapshot in the given order, additional unlisted children are allowed. You can tighten this with `/children` directives directly in the YAML template, or set a project-wide default in `playwright.config.ts`.

```typescript
// playwright.config.ts — set default children matching mode for all toMatchAriaSnapshot calls
import { defineConfig } from '@playwright/test';

export default defineConfig({
  expect: {
    toMatchAriaSnapshot: {
      children: 'equal',  // v1.52+: 'contain' (default) | 'equal' | 'deep-equal'
    },
  },
});
```

```typescript
// In tests — override per-assertion using inline /children directives in YAML
test('navigation has exactly these three links and no others', async ({ page }) => {
  await page.goto('/');

  // ✅ /children: equal — top-level children must match exactly (no extras allowed)
  await expect(page.getByRole('navigation')).toMatchAriaSnapshot(`
    - navigation:
      /children: equal
      - link "Home"
      - link "Products"
      - link "Contact"
  `);

  // ✅ /children: deep-equal — exact match including ALL nested children at every level
  await expect(page.getByRole('list')).toMatchAriaSnapshot(`
    - list:
      /children: deep-equal
      - listitem:
        /children: deep-equal
        - link "Feature A"
      - listitem:
        /children: deep-equal
        - link "Feature B"
  `);

  // ✅ /children: contain (default) — additional children beyond the listed ones are allowed
  // Useful for components that inject decorative ARIA nodes (icons, badges, tooltips)
  await expect(page.getByRole('menu')).toMatchAriaSnapshot(`
    - menu:
      /children: contain
      - menuitem "Edit"
      - menuitem "Delete"
  `);
});
```

> **WHY:** The default `contain` mode is intentionally lenient — it lets you snapshot only the parts of the ARIA tree you care about without being broken by decorative icons, tooltips, or dynamic badge counts injected alongside the real content. Use `equal` when you need to assert that a component renders *exactly* the expected items (e.g., a navigation menu that must never have ghost links). Use `deep-equal` for exhaustive regression tests of entire component subtrees — but expect more frequent update runs when the component evolves. Setting the global default to `equal` in `playwright.config.ts` trades off maintenance cost for tighter regression coverage. [official]

---

## Iteration 37 — New Patterns & Gotchas (2026-05-12)

---

### `locator.click({ steps })` and `locator.dragTo({ steps })` — Granular Mouse Movement (v1.57+)

The `steps` option controls the number of intermediate `mousemove` events emitted between the pointer's current position and the click or drag target. The default is `1`, which emits a single `mousemove` at the destination. Setting `steps` to a higher value generates a linear sequence of interpolated mouse positions — critical for testing components whose interaction state depends on continuous pointer tracking rather than just a final position event.

```typescript
import { test, expect } from '@playwright/test';

// --- locator.click({ steps }) ---

// Default (steps: 1): single mousemove to destination then click
await page.getByRole('button', { name: 'Submit' }).click();

// steps: 5 — emit 5 interpolated mousemove events before click
// Use when a component applies :hover styles or tooltip logic that
// reads pointer position at each intermediate step
await page.getByRole('button', { name: 'Submit' }).click({ steps: 5 });

// Canvas drawing: simulate a brush stroke with smooth intermediate positions
test('canvas: smooth brush stroke updates stroke count', async ({ page }) => {
  await page.goto('/drawing-app');
  const canvas = page.locator('canvas');

  // Click at a position with many intermediate steps for smooth simulation
  await canvas.click({
    position: { x: 200, y: 150 },
    steps: 20,  // 20 mousemove events → smooth cursor path
  });

  await expect(page.getByTestId('stroke-count')).toHaveText('1');
});

// --- locator.dragTo({ steps }) ---

// Default drag: single mousemove from source to target center
await page.locator('#source').dragTo(page.locator('#target'));

// Smooth drag for react-dnd / Sortable.js components that listen to mousemove
test('reorder list items with smooth drag', async ({ page }) => {
  await page.goto('/sortable-list');

  const firstItem  = page.getByRole('listitem').first();
  const thirdItem  = page.getByRole('listitem').nth(2);

  // 15 intermediate mousemove events — required for Sortable.js placeholder logic
  await firstItem.dragTo(thirdItem, {
    steps: 15,
    sourcePosition: { x: 10, y: 10 },
    targetPosition: { x: 10, y: 10 },
  });

  // Assert reordering took effect
  await expect(page.getByRole('listitem').first()).not.toHaveText('Item 1');
});

// Slider component: drag handle across range with smooth interpolation
test('range slider: drag to 75%', async ({ page }) => {
  await page.goto('/settings');
  const slider = page.getByRole('slider', { name: 'Volume' });

  // Use drag with steps to simulate gradual value change
  await slider.dragTo(page.locator('.slider-track'), {
    targetPosition: { x: 225, y: 10 }, // 75% of a 300px track
    steps: 30,
  });

  await expect(slider).toHaveAttribute('aria-valuenow', '75');
});
```

> **[community]** WHY: Without `steps`, drag-and-drop libraries built on the HTML5 Drag and Drop API or custom `mousemove` listeners receive only a `mousedown` at the source, one `mousemove` at the target, and a `mouseup` — which many libraries treat as a "no-op drag" because the pointer never passed through intermediate positions. `steps: 10` to `steps: 20` is the sweet spot for most component libraries. Too many steps (>100) slows tests without benefit. [community]

> **[community]** WHY: The `steps` option for `click()` is less commonly needed but valuable for custom canvas drawing tools, color-picker components, or sliders where the interaction state machine tracks cursor travel path. Setting `steps: 1` (the default) is correct for all standard button/link interactions — only increase it when you observe the component behaving differently between manual and automated interaction. [community]

---

### `connectOverCDP({ isLocal: true })` — Local File System Optimizations (v1.58+)

The `isLocal` option tells Playwright that the browser and the Playwright process share the same file system. When set to `true`, Playwright can use file system paths directly for some operations (e.g., screenshot comparisons, HAR file writes) rather than serializing data over the CDP wire, reducing latency on local development and CI.

```typescript
import { chromium, type Browser } from '@playwright/test';

// ✅ Connect to a locally running Chrome with file system optimizations enabled
const browser: Browser = await chromium.connectOverCDP('http://localhost:9222', {
  isLocal: true,  // v1.58+: Playwright and browser share the same file system
});

const [context] = browser.contexts();
const page = context.pages()[0];

// File-path based screenshot — written directly via the local FS, not serialized over CDP
await page.screenshot({ path: './test-results/current-state.png' });

// HAR recording saves directly to the local path without streaming
await using har = await context.tracing.startHar('./test-results/network.har');
await page.goto('/dashboard');
// HAR is saved to the local path without CDP data transfer overhead

await browser.close();
```

**Common pattern — local integration testing with a pre-launched browser:**

```typescript
// playwright.config.ts — hybrid: use connectOverCDP for local dev, launch() for CI
import { defineConfig } from '@playwright/test';

const CDP_ENDPOINT = process.env.CDP_ENDPOINT; // set by developer, absent in CI

export default defineConfig({
  use: {
    // In CI: launch a fresh browser per test
    // Locally: connect to an existing Chrome instance (faster startup)
    ...(CDP_ENDPOINT
      ? {
          connectOptions: {
            wsEndpoint: CDP_ENDPOINT,
            // isLocal handled at chromium.connectOverCDP() level, not use: block
          },
        }
      : {}),
  },
});

// e2e/fixtures/local-browser.ts — fixture that uses isLocal when CDP_ENDPOINT is set
import { test as base, chromium } from '@playwright/test';

export const test = base.extend({
  browser: async ({}, use) => {
    if (process.env.CDP_ENDPOINT) {
      const browser = await chromium.connectOverCDP(process.env.CDP_ENDPOINT, {
        isLocal: true,     // same machine — enable FS optimizations
        noDefaults: false, // still apply Playwright defaults (colors, motion)
      });
      await use(browser);
      // Don't close — the browser is externally managed
    } else {
      const browser = await chromium.launch();
      await use(browser);
      await browser.close();
    }
  },
});
```

> **WHY:** `isLocal: true` was added alongside `noDefaults: true` (both v1.58+) to give teams precise control over what Playwright does when attaching to existing browsers. `isLocal` unlocks file system shortcuts; `noDefaults` preserves real browser settings. The two options are independent — you may want `isLocal: true, noDefaults: false` for a local CI agent that has a pre-warmed browser but still needs Playwright's default emulation layer. [official]

---

### `locator.describe()` + `locator.description()` — Annotating and Reading Back Locator Labels (v1.52+ / v1.57+)

`locator.describe(label)` (v1.52+) attaches a human-readable label to a locator. This label appears in the Trace Viewer, HTML report, and error messages instead of the raw CSS/role selector. `locator.description()` (v1.57+) reads back the label previously set — allowing custom reporters, test helpers, and assertion wrappers to inspect the intent of a locator without parsing its underlying selector.

```typescript
import { test, expect } from '@playwright/test';

// --- locator.describe(): attach a semantic label ---

const emailInput = page.getByLabel('Email').describe('email input field');
// Without describe(): error message says  >> locator('input[name="email"]') <<
// With    describe(): error message says  >> email input field <<

// POM usage: label complex chained locators for clarity in Trace Viewer
class CheckoutPage {
  readonly cardNumberInput: Locator;
  readonly cvvInput: Locator;

  constructor(private page: Page) {
    this.cardNumberInput = page
      .getByRole('group', { name: 'Payment' })
      .getByLabel('Card number')
      .describe('checkout: card number input');

    this.cvvInput = page
      .getByRole('group', { name: 'Payment' })
      .getByLabel('CVV')
      .describe('checkout: CVV input');
  }
}

// --- locator.description(): read back the label in a custom assertion wrapper ---

// utils/assert-with-label.ts
import { type Locator, expect } from '@playwright/test';

/**
 * Wraps toBeVisible() with a friendlier failure message that uses the locator's
 * describe() label if available, falling back to the raw selector string.
 */
async function assertVisible(locator: Locator): Promise<void> {
  const label = locator.description() ?? locator.toString();
  await expect(locator, `Expected [${label}] to be visible`).toBeVisible();
}

// Usage: the failure message says "Expected [checkout: card number input] to be visible"
// instead of "Expected locator('div.payment >> label:has-text("Card number") >> input')"
const checkout = new CheckoutPage(page);
await assertVisible(checkout.cardNumberInput);

// --- locator.toString() uses description when available (v1.57+) ---
const locator = page.getByRole('button', { name: 'Submit' }).describe('submit order');

console.log(locator.toString());
// Before v1.57: "locator('button', { hasText: /Submit/i })"
// After  v1.57: "submit order"

// ESLint rule: prevent describe() with empty strings (useless noise in traces)
// .eslintrc: { "playwright/no-empty-locator-describe": "error" }  // from eslint-plugin-playwright
```

> **[community]** WHY: In suites with 50+ page objects, Trace Viewer step names like `locator('div[data-testid="checkout-form"] >> nth=0 >> label:has-text("Card number") >> xpath=../input')` make debugging extremely slow. Adding `.describe('checkout: card number input')` to every POM locator costs one line per field but halves the time engineers spend reading traces. The `locator.description()` accessor (v1.57+) is the complementary read path — use it to build test utilities that report locator intent in a uniform format. [community]

---

### Additional Community Gotchas (Iteration 37)

---

### 50. `locator.click({ steps })` on `<input type="range">` does not update the value [community]

The `steps` option controls pointer travel but does NOT update the `<input type="range">` value attribute. Range inputs rely on the browser's native slider drag gesture which requires `page.mouse.move()` + `page.mouse.down/up()` relative to the element's bounding box, or using `locator.fill()` / `locator.evaluate()` to set the value directly.

```typescript
// ❌ Anti-pattern: click steps do not set slider value
await page.getByRole('slider').click({ steps: 10 });
// Value stays at the default — click() is position-based but doesn't drag the thumb

// ✅ Correct: fill() dispatches a change event on range inputs
await page.getByRole('slider', { name: 'Volume' }).fill('75');
// Sets the value attribute to "75" and fires input + change events

// ✅ Or use evaluate for precise programmatic control
await page.getByRole('slider').evaluate((el: HTMLInputElement, val: number) => {
  el.value = String(val);
  el.dispatchEvent(new Event('input',  { bubbles: true }));
  el.dispatchEvent(new Event('change', { bubbles: true }));
}, 75);

await expect(page.getByRole('slider')).toHaveAttribute('value', '75');
```

> **WHY:** `<input type="range">` value is controlled by the browser's internal mouse tracking on the thumb element, not by pointer coordinates passed via CDP. Playwright's click/drag simulation bypasses the native mouse-capture mechanism the browser uses for range inputs. `fill()` is the correct API for setting range values because it interacts with the DOM value property directly. [community]

---

### 51. `connectOverCDP({ isLocal: true })` causes silent failures when paths differ between mount points [community]

When running inside Docker (or any environment where the host file system is mounted at a different path than the container's), `isLocal: true` causes Playwright to write screenshot/HAR files to the container path while the CI system expects them at the host mount path — producing "file not found" errors when the CI artifact collector runs.

```typescript
// ❌ Dangerous in Docker: file system paths are not the same between container and host
const browser = await chromium.connectOverCDP('http://host.docker.internal:9222', {
  isLocal: true,   // host browser ≠ container FS — isLocal is WRONG here
});

// ✅ Correct: isLocal: false (or omit) when browser and Playwright are on different hosts
const browser = await chromium.connectOverCDP('http://host.docker.internal:9222', {
  isLocal: false,  // force CDP data serialization — paths are meaningless across hosts
});

// ✅ Safe pattern: only enable isLocal when truly on the same machine
const isLocalBrowser = !process.env.CDP_REMOTE_HOST;
const browser = await chromium.connectOverCDP(process.env.CDP_ENDPOINT!, {
  isLocal: isLocalBrowser,
});
```

> **WHY:** `isLocal: true` is purely an optimization hint — it enables file-path-based shortcuts instead of streaming file content over the CDP WebSocket. It is NOT appropriate for remote browsers or Docker networking scenarios where the browser process cannot access the same file paths as the Playwright process. When in doubt, omit `isLocal` (defaults to `false`). [community]

---

### 52. `locator.describe()` labels are not inherited by `locator.filter()`, `locator.first()`, etc. [community]

When you apply `.describe()` to a locator and then chain `.filter()`, `.first()`, `.nth()`, or other locator combinators, the returned locator does NOT inherit the description. The new locator has its own (empty) description, falling back to its full selector string in error messages.

```typescript
// ❌ Trap: description not inherited by combinators
const rows = page.getByRole('row').describe('data table row');
const firstRow = rows.first(); // description NOT inherited
const filteredRow = rows.filter({ hasText: 'Alice' }); // description NOT inherited

// firstRow.description()   → null
// filteredRow.description() → null

// ✅ Re-apply describe() after combinators
const firstRow = rows.first().describe('data table: first row');
const aliceRow = rows.filter({ hasText: 'Alice' }).describe('data table: Alice row');

// aliceRow.description() → 'data table: Alice row'
```

> **WHY:** Each locator combinator creates a new `Locator` instance. The description is metadata on the original instance, not a hereditary property of the locator chain. This is intentional — chained locators may have completely different semantics from the base. The practical impact: if you apply `.describe()` early in POM constructors and later filter or refine those locators, re-apply `.describe()` to the result or the filtered locator will produce unhelpfully raw selector strings in failure reports. [community]

---

## Additional Key APIs (Iteration 37 — v1.57/v1.58)

| API | What it does | When to use it |
|-----|-------------|----------------|
| `locator.click({ steps: N })` | Emit N interpolated `mousemove` events before the click (v1.57+) | Canvas, custom sliders, tooltip components that track pointer travel |
| `locator.dragTo(target, { steps: N })` | Emit N interpolated `mousemove` events during drag (v1.57+) | react-dnd, Sortable.js, chart drawing — any DnD handler that reads intermediate positions |
| `locator.describe(label)` | Attach human-readable label to locator (v1.52+) | POM readability; Trace Viewer step names; assertion error messages |
| `locator.description()` | Read back the label set by `describe()` — returns `null` if unset (v1.57+) | Custom reporters; assertion wrappers; locator-to-string utilities |
| `locator.toString()` | Now uses `description()` value when available (v1.57+) | Automatic label injection into error messages without extra code |
| `chromium.connectOverCDP(url, { isLocal: true })` | Enable file-system shortcuts when browser and test process share the same FS (v1.58+) | Local dev / CI agents with a pre-warmed same-host browser |
| `chromium.connectOverCDP(url, { noDefaults: true })` | Skip Playwright's default context setting overrides (v1.60+) | Preserve real OS theme/media preferences on an attached browser |
