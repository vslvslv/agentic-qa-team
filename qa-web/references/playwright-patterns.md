# Playwright Patterns & Best Practices (TypeScript)
<!-- lang: TypeScript | sources: official | community | mixed | iteration: 10 | score: 100/100 | date: 2026-04-26 -->
<!-- official: playwright.dev/docs/best-practices, /pom, /locators, /test-fixtures, /test-assertions, /api-testing, /network, /auth, /test-sharding, /ci-intro, /test-configuration, /test-parallel, /test-snapshots -->
<!-- community: playwrightsolutions.com, currents.dev/blog/playwright, mxschmitt/awesome-playwright, GitHub Discussions patterns, real-world production experience -->

---

## Core Principles

1. **Test user-visible behavior, not implementation details.** Assertions should reflect what users see and do — not CSS class names, internal state, or component structure.
2. **Rely on Playwright's auto-waiting.** Every action (`click`, `fill`, `check`) automatically waits for the element to be actionable. Never add arbitrary `waitForTimeout()` sleeps.
3. **Use semantic, resilient locators.** Roles, labels, and accessible names outlive CSS refactors. If a selector breaks when a class name changes, it was the wrong selector.
4. **Isolate state between tests.** Each test should own its setup. Tests that depend on run order cannot be debugged in isolation.
5. **Centralize reuse in fixtures and Page Objects.** Login flows, page interactions, and setup sequences belong in one place — so one change fixes every test that uses them.

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

### Installing browsers correctly in CI

```bash
# Install only Chromium to save 300–500 MB per omitted browser
npx playwright install chromium --with-deps

# --with-deps installs OS-level system libraries (libatk, ffmpeg, etc.)
# Omitting it causes silent browser crashes in headless environments
```

### Animation and font stability

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
```

### Handling flaky tests strategically

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
| `expect.soft(locator)` | Non-blocking assertion; collects errors | Multi-field validation |
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
| `page.waitForRequest(url)` | Wait for outgoing request | Verify API calls are made |
| `page.waitForResponse(url)` | Wait for incoming response | Verify API responses are handled |

### Fixtures

| API | What it does | When to use it |
|-----|-------------|----------------|
| `test.extend<T>()` | Declare custom fixtures with type safety | All custom setup/teardown |
| `test.use(overrides)` | Configure fixture values for a scope | Scoped configuration |
| `mergeTests(a, b)` | Combine fixtures from multiple modules | Modular fixture composition |
| `workerInfo.workerIndex` | Unique per-worker integer | Worker-scoped unique test data |
| `testInfo.testId` | Globally unique test identifier | Per-test unique data seeds |
| `{ scope: 'worker' }` | Share fixture across all tests in a worker | Expensive shared resources (DB, server) |
| `{ auto: true }` | Run fixture for every test automatically | Universal setup like global logging |
| `{ box: true }` | Hide fixture steps from test report | Reduce report noise for helper fixtures |

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
```

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
    api/
      users.spec.ts      # Pure API tests (no browser)
  .auth/
    user.json            # Stored auth state — add to .gitignore
  screenshot.css         # CSS injected for visual regression to hide dynamic content
  tsconfig.json          # Separate TypeScript config for e2e code
playwright.config.ts
.eslintrc.playwright.json  # eslint-plugin-playwright rules
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
  testDir:       './e2e',
  testMatch:     '**/*.spec.ts',
  fullyParallel: true,
  forbidOnly:    !!process.env.CI,        // fail if test.only left in CI
  retries:       process.env.CI ? 2 : 0,  // retry flakes on CI only
  workers:       process.env.CI ? 4 : undefined,
  timeout:       process.env.CI ? 60_000 : 30_000,  // CI machines are slower
  reporter:      process.env.CI ? 'blob' : [['html'], ['list']],
  maxFailures:   process.env.CI ? 10 : undefined,   // stop early on broken suites
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
await expect(page).toHaveURL(/pattern/);
await expect(page).toHaveTitle(/pattern/);

// Scoping / filtering
page.getByRole('dialog').getByRole('button', { name: 'Close' })
page.getByRole('listitem').filter({ hasText: 'Buy milk' })
page.getByRole('row').nth(1)

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
```
