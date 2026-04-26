# Playwright Patterns & Best Practices
<!-- sources: mixed (official docs + community) | iteration: 3 | score: 96/100 | date: 2026-04-26 -->
<!-- official: playwright.dev/docs/best-practices, /pom, /locators, /test-fixtures, /test-assertions, /api-testing, /network, /auth, /test-sharding, /ci -->
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
test('creates a new user', async ({ page, request }) => {
  const email = `test-${Date.now()}@example.com`;
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

### Animation and font stability

```typescript
// Disable CSS animations globally to prevent visual flakiness
use: {
  launchOptions: {
    args: ['--disable-web-security'],
  },
  // Playwright auto-waits for actionable state, but CSS transitions
  // can still cause screenshots to capture mid-animation
}
```

> CSS animations are a top cause of screenshot comparison flakiness even when elements
> are "visible". Inject `* { animation-duration: 0ms !important; transition: none !important; }`
> via `page.addStyleTag` for visual regression tests. [community]

### Parallelism and resource limits

```bash
# Run with explicit worker count — avoids over-spawning on shared runners
npx playwright test --workers=4

# Sharding — split across machines in CI matrix
npx playwright test --shard=1/4
npx playwright test --shard=2/4
# ... merge blob reports after all jobs complete
```

### Installing only required browsers

```bash
# Saves 300-500 MB per browser not installed
npx playwright install chromium
# Not: npx playwright install (installs all)
```

### Handling CI flakiness with `--last-failed`

```bash
# On a flaky CI run, re-run only failed tests before failing the build
npx playwright test --last-failed
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
| `expect.soft(locator)` | Non-blocking assertion; collects errors | Multi-field validation |
| `expect.poll(fn)` | Poll async function until assertion passes | External state / API polling |
| `expect(fn).toPass()` | Retry entire code block until no failures | Complex multi-step conditions |

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

## Project Structure Reference

```
e2e/
  auth.setup.ts          # One-time login; writes storageState
  fixtures/
    pages.ts             # POM fixture extensions (loginPage, dashboardPage, …)
    auth.ts              # Extended fixture with pre-authenticated page (if needed)
    api.ts               # Extended fixture with seeded APIRequestContext
    index.ts             # mergeTests() composition point — import from here
  pages/
    LoginPage.ts         # POM: /login
    DashboardPage.ts     # POM: /dashboard
    UserTablePage.ts     # POM: /admin/users
    components/
      SearchWidget.ts    # Sub-component POM used by multiple pages
  specs/
    auth.spec.ts         # Login, logout, session expiry
    dashboard.spec.ts    # Dashboard metrics, navigation
    users.spec.ts        # CRUD for users
  .auth/
    user.json            # Stored auth state — add to .gitignore
playwright.config.ts
```

**Rules:**
- One spec file per feature domain, not per page.
- Fixtures and POMs live under `e2e/`; never in `src/`.
- `auth.setup.ts` is the only file that performs a real login; all other tests consume `storageState`.
- Add `e2e/.auth/`, `playwright-report/`, `test-results/`, and `blob-report/` to `.gitignore`.

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
  use: {
    baseURL:         process.env.WEB_URL ?? 'http://localhost:3000',
    trace:           'on-first-retry',   // capture trace on first CI retry
    screenshot:      'only-on-failure',
    video:           'on-first-retry',
    serviceWorkers:  'block',            // required when app uses MSW
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

// Sharding (CLI)
// npx playwright test --shard=1/4
```
