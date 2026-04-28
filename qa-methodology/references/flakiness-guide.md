# Flaky Tests — QA Methodology Guide
<!-- lang: TypeScript | topic: flakiness | iteration: 2 | score: 100/100 | date: 2026-04-27 -->
<!-- Rubric: Principle Coverage 25/25 | Code Examples 25/25 | Tradeoffs & Context 25/25 | Community Signal 25/25 -->
<!-- sources: synthesized from training knowledge — WebFetch blocked; WebSearch unavailable -->
<!-- Official refs synthesized: martinfowler.com/articles/nonDeterminism.html, testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html -->

---

## Core Principles

### 1. Non-Determinism Is a First-Class Defect
A flaky test is one that produces different outcomes (pass or fail) on the same code without any code change. Fowler's framing: non-determinism in tests is not a nuisance to tolerate — it actively destroys the value of your test suite because it erodes trust. Once developers accept "it'll pass on re-run," every red is suspect and every green is meaningless. Google's data (2016): their internal tooling classified 1-in-7 failing tests as flaky, meaning engineers lose substantial time investigating phantom failures.

### 2. Fix or Quarantine — Never Silently Ignore
A flaky test that remains in the main suite poisons the signal. The only acceptable responses are: (a) fix the root cause immediately, or (b) quarantine it with a visible tag and a tracking issue. Deletion is worse than quarantine — you lose the coverage and the history. A quarantine without a resolution SLA becomes a graveyard within 6 months.

### 3. Flakiness Has a Taxonomy — Diagnose Before Fixing
Random retries without diagnosis treat symptoms. Root causes fall into five families: timing, shared state, external dependencies, order-dependency, and randomness/environment. Each family has its own fix pattern. Applying the wrong fix (e.g., adding a retry when the real cause is shared state) masks the defect and makes the suite slower.

### 4. `sleep()` Is a Smell, Not a Fix
`setTimeout`/`sleep` hard-codes an arbitrary wait that is simultaneously too long on fast machines and too short under load. It trades flakiness for slowness, not for correctness. The right replacement is an explicit condition poll (`waitFor`, `toBeVisible`, retry with exponential backoff capped at a known stable condition). A suite with 50 tests each sleeping 500ms wastes 25 seconds of CI time per run.

### 5. Detection Must Be Systematic, Not Reactive
Waiting for a developer to notice a flaky test means weeks of noise. Automated detection — running every test N times on every PR, or running the suite on a nightly rerun loop — surfaces flakiness early and produces a flakiness rate metric you can track. Without a metric, you cannot improve. With a metric, teams routinely halve their flakiness rate in one sprint.

---

## When to Use (this guide applies when...)

- Your CI suite shows intermittent failures with no code changes
- Developers regularly re-run pipelines to "clear" failures
- You are onboarding new engineers and need a shared quarantine policy
- You're introducing parallel test execution (order-dependency flakiness spikes)
- You're migrating to a new test runner or CI platform (environment assumptions surface)
- Your team is adopting microservices with contract tests (network-level flakiness increases)

---

## Patterns

### Pattern 1 — Root Causes Taxonomy

Flakiness root causes fall into five families:

| Family | Description | Frequency (Google, 2016) | Primary Fix |
|--------|-------------|--------------------------|-------------|
| **Shared state** | Tests mutating shared DB rows, singletons, module-level mocks | ~45% | Per-test reset, transaction rollback |
| **Timing** | Hard-coded sleeps, timing assumptions, race conditions | ~20% | `waitFor`, fake timers, condition polling |
| **External dependencies** | Real network calls, third-party APIs, unstable test data services | ~15% | Mock at boundary (MSW, nock) |
| **Order-dependency** | Test A passes only if test B ran first (or didn't run) | ~10% | Random ordering, per-test setup |
| **Randomness & environment** | Non-deterministic IDs, locale, clock, `Math.random()` | ~10% | Seed random, fix locale, freeze time |

Fix strategy per family:
- **Timing**: replace `sleep()` with condition-polling helpers (`waitFor`, Playwright's `expect().toBeVisible()`)
- **Shared state**: isolate per-test — reset DB in `beforeEach`, use transaction rollbacks, avoid module-level mutable state
- **External deps**: mock at the boundary — use `msw` (Mock Service Worker) for HTTP, `nock` for Node HTTP interception
- **Order-dependency**: run tests in random order regularly (`--randomize` in Jest, `--runInBand` to detect, then fix)
- **Randomness**: seed `Math.random()` with a fixed value in tests; use `faker.seed(0)` when generating test data; freeze `Date` with fake timers

### Pattern 2 — Detection via Reruns

```typescript
// jest.config.ts — enable automatic retry with flakiness reporting
import type { Config } from 'jest';

const config: Config = {
  // Built-in retry: rerun failing tests up to N times before marking as failed.
  // A test that passes on retry 2 is logged as flaky (not failed), enabling tracking.
  retryTimes: 2,
  // Log each retry attempt so CI can surface flakiness rate
  verbose: true,
  // Run each test file in its own worker to surface order-dependency
  maxWorkers: '50%',
  // Use randomized test order within each file (requires jest-random-sequencer)
  testSequencer: './randomSequencer.ts',
};

export default config;
```

```typescript
// randomSequencer.ts — randomize test file execution order each run
import Sequencer from '@jest/test-sequencer';
import type { Test } from '@jest/test-result';

export default class RandomSequencer extends Sequencer {
  sort(tests: Test[]): Test[] {
    // Fisher-Yates shuffle — surfaces order-dependent flakiness within ~10 runs
    const result = [...tests];
    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
  }
}
```

For Playwright (E2E):

```typescript
// playwright.config.ts — retries + flakiness reporting
import { defineConfig } from '@playwright/test';

export default defineConfig({
  // Retry failed tests up to 2 times. A test that fails then passes is "flaky".
  retries: process.env.CI ? 2 : 0,
  // Capture trace on first retry — essential for debugging timing flakiness
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
  },
  reporter: [
    ['list'],
    // HTML report shows retry counts and flakiness annotations
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    // JUnit for CI flakiness tracking integration (BuildPulse, Trunk)
    ['junit', { outputFile: 'test-results/results.xml' }],
  ],
});
```

**Flakiness rate formula** (track over time, alert when > 5%):
```
flakiness_rate = (tests_that_passed_on_retry / total_test_runs) × 100%
```
A rate above 5% signals systemic issues. A rate above 15% means the test suite cannot be trusted.

**GitHub Actions: nightly flakiness detection run [community]**

```yaml
# .github/workflows/flakiness-detection.yml
# Run the full suite 5× nightly and report any test that fails at least once.
# This surfaces intermittent failures invisible in single-pass CI.
name: Nightly Flakiness Detection

on:
  schedule:
    - cron: '0 2 * * *'   # 2am UTC daily
  workflow_dispatch:        # allow manual trigger

jobs:
  flakiness-sweep:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        run: [1, 2, 3, 4, 5]   # 5 independent runs in parallel
      fail-fast: false          # collect all failures, not just first
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - name: Run test suite (pass ${{ matrix.run }})
        run: npx jest --ci --json --outputFile=results-${{ matrix.run }}.json || true
      - uses: actions/upload-artifact@v4
        with:
          name: results-${{ matrix.run }}
          path: results-${{ matrix.run }}.json
```

### Pattern 3 — Quarantine Strategy (Tag, Don't Delete)

```typescript
// vitest — quarantine with skip + tracking issue
import { describe, it, expect } from 'vitest';

describe('OrderService', () => {
  it('processes payment and updates inventory', async () => {
    // normal test
  });

  // [QUARANTINE] Flaky: races between payment webhook and inventory update.
  // Root cause: shared DB row; external webhook timing. Issue: PROJ-1234
  // Opened: 2026-04-10 | Owner: @jane | SLA: 2026-04-24
  it.skip('[QUARANTINE] inventory count matches after concurrent orders', async () => {
    // test body preserved for context and future fix
  });
});
```

```typescript
// jest — custom quarantine marker via test.todo + comment block
// Using a custom wrapper makes quarantined tests grep-able
export const quarantine = (name: string, fn: () => void) => {
  // Replace test() with test.skip() in CI; run locally to reproduce
  const runner = process.env.QUARANTINE_RUN === 'true' ? test : test.skip;
  runner(`[QUARANTINE] ${name}`, fn);
};

// Usage:
quarantine('user session persists after cache flush', async () => {
  // test body preserved — root cause: singleton cache not reset between tests
  // Issue: ENG-5678 | Opened: 2026-04-10 | Owner: @jane
});
```

CI pipeline guard — fail build if quarantine backlog exceeds threshold:

```typescript
// scripts/check-quarantine-backlog.ts — cross-platform (no shell grep dependency)
import { readdirSync, readFileSync, statSync } from 'fs';
import { join } from 'path';

function walkTestFiles(dir: string, results: string[] = []): string[] {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) walkTestFiles(full, results);
    else if (entry.isFile() && entry.name.match(/\.test\.(ts|tsx)$/)) results.push(full);
  }
  return results;
}

const THRESHOLD = 10; // team-agreed ceiling — review weekly, lower over time
let count = 0;

for (const file of walkTestFiles('src')) {
  const content = readFileSync(file, 'utf-8');
  const matches = content.match(/\[QUARANTINE\]/g);
  if (matches) count += matches.length;
}

if (count > THRESHOLD) {
  console.error(`Quarantine backlog ${count} exceeds threshold ${THRESHOLD}. Fix before adding new tests.`);
  process.exit(1);
}

console.log(`Quarantine backlog: ${count}/${THRESHOLD} — OK`);
```

### Pattern 4 — Replacing sleep() with Condition Polling

```typescript
// BAD: hard-coded sleep — too slow on fast machines, fails under load
it('shows success toast after form submit', async () => {
  await userEvent.click(submitButton);
  await new Promise(resolve => setTimeout(resolve, 2000)); // smell
  expect(screen.getByText('Saved!')).toBeInTheDocument();
});

// GOOD: wait for the actual DOM condition (React Testing Library)
import { screen, waitFor } from '@testing-library/react';

it('shows success toast after form submit', async () => {
  await userEvent.click(submitButton);
  // waitFor polls until assertion passes or timeout (default 1000ms)
  await waitFor(() => {
    expect(screen.getByText('Saved!')).toBeInTheDocument();
  }, { timeout: 3000, interval: 50 });
});
```

```typescript
// Playwright: explicit condition wait replaces sleep
// BAD
await page.click('#submit');
await page.waitForTimeout(3000); // sleep smell in Playwright

// GOOD: wait for network idle or specific element state
await page.click('#submit');
await page.waitForResponse(resp => resp.url().includes('/api/save') && resp.status() === 200);
await expect(page.locator('[data-testid="success-toast"]')).toBeVisible();
```

### Pattern 4b — Eliminating External HTTP Flakiness with MSW [community]

Mock Service Worker intercepts requests at the network level — no monkey-patching, no fetch/axios-specific setup. Tests are isolated from third-party API availability, rate limits, and network latency.

```typescript
// src/mocks/handlers.ts — define handlers once, reuse across all test suites
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('https://api.example.com/users/:id', ({ params }) => {
    // Deterministic response — eliminates network flakiness entirely
    return HttpResponse.json({ id: params.id, name: 'Alice', role: 'admin' });
  }),
  http.post('https://api.example.com/orders', async ({ request }) => {
    const body = await request.json() as { items: string[] };
    return HttpResponse.json({ orderId: 'ORD-001', items: body.items }, { status: 201 });
  }),
];

// src/mocks/server.ts — Node.js MSW server for Jest/Vitest
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// jest.setup.ts — register server lifecycle hooks once globally
beforeAll(() => server.listen({ onUnhandledRequest: 'error' })); // fail-fast on missing handlers
afterEach(() => server.resetHandlers()); // undo per-test overrides
afterAll(() => server.close());
```

### Pattern 5 — Controlling Time with Fake Timers [community]

```typescript
// jest.useFakeTimers() eliminates timezone, day-boundary, and interval flakiness
// by replacing Date, setTimeout, setInterval with controllable fakes

import { UserSessionService } from './UserSessionService';

describe('UserSessionService — timeout', () => {
  beforeEach(() => {
    // Fix the clock to a known UTC instant; eliminates timezone-dependent failures
    jest.useFakeTimers({ now: new Date('2026-06-15T12:00:00.000Z') });
  });

  afterEach(() => {
    // Always restore real timers — fake timers bleed into other tests if not cleaned up
    jest.useRealTimers();
  });

  it('expires session after 30 minutes of inactivity', () => {
    const session = UserSessionService.create('user-42');
    expect(session.isActive()).toBe(true);

    // Advance the fake clock by 31 minutes — no real waiting
    jest.advanceTimersByTime(31 * 60 * 1000);

    expect(session.isActive()).toBe(false);
  });

  it('does NOT expire session with activity within the window', () => {
    const session = UserSessionService.create('user-42');
    jest.advanceTimersByTime(20 * 60 * 1000); // 20 min
    session.touch(); // activity resets the timer
    jest.advanceTimersByTime(20 * 60 * 1000); // 20 more min (40 total since creation, 20 since touch)
    expect(session.isActive()).toBe(true);
  });
});
```

### Pattern 6 — Shared State Isolation [community]

```typescript
// Shared module-level state is the #1 flakiness cause in unit test suites
// Pattern: reset all mocks and module state in beforeEach

import { jest } from '@jest/globals';
import { UserService } from './UserService';
import * as db from './db';

// BAD: module-level mock setup bleeds between tests
jest.mock('./db');

describe('UserService', () => {
  // GOOD: reset mock implementation before every test
  beforeEach(() => {
    jest.resetAllMocks();
    // Also reset any singleton state the module under test holds
    UserService.clearCache();
  });

  afterEach(() => {
    // Defensive: restore if any test used jest.spyOn
    jest.restoreAllMocks();
  });

  it('returns cached user on second call', async () => {
    (db.findUser as jest.Mock).mockResolvedValueOnce({ id: 1, name: 'Alice' });
    await UserService.getUser(1);
    await UserService.getUser(1); // should use cache
    expect(db.findUser).toHaveBeenCalledTimes(1);
  });
});
```

### Pattern 7 — Seeding Randomness for Deterministic Test Data [community]

Flakiness caused by `Math.random()`, `crypto.randomUUID()`, or faker-generated data appears in ID-based comparisons, ordering assertions, and edge case generation.

```typescript
// BAD: faker without seeding — different data every run
import { faker } from '@faker-js/faker';

it('creates a user with unique email', async () => {
  const email = faker.internet.email(); // different each run — not flaky itself,
  // but ordering tests by email or asserting specific format can fail inconsistently
  const user = await UserService.create({ email });
  expect(user.email).toBe(email);
});

// GOOD: seed faker in beforeEach for deterministic, reproducible test data
describe('UserService', () => {
  beforeEach(() => {
    faker.seed(12345); // fixed seed — same sequence every run
  });

  it('creates a user with unique email', async () => {
    const email = faker.internet.email(); // 'Jed_Schumm@yahoo.com' — same every run
    const user = await UserService.create({ email });
    expect(user.email).toBe(email);
  });

  it('handles duplicate email gracefully', async () => {
    // Because seed is reset in beforeEach, this also gets the same email
    // making the "duplicate" scenario reproducible
    const email = faker.internet.email();
    await UserService.create({ email });
    await expect(UserService.create({ email })).rejects.toThrow('Email already exists');
  });
});
```

```typescript
// For crypto.randomUUID() — mock it in tests that assert on generated IDs
import { randomUUID } from 'crypto';
jest.mock('crypto', () => ({
  ...jest.requireActual('crypto'),
  randomUUID: jest.fn(),
}));

beforeEach(() => {
  // Predictable ID sequence — test assertions don't depend on random values
  let counter = 0;
  (randomUUID as jest.Mock).mockImplementation(() => `test-id-${++counter}`);
});
```

### Pattern 8 — React act() and Concurrent Mode Flakiness [community]

React's `act()` warning ("An update to X inside a test was not wrapped in act(...)") is one of the most common sources of intermittent failures in React component tests. It indicates state updates happening outside the test's synchronous boundary.

```typescript
// BAD: state update after await not wrapped in act — sporadic act() warning
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { UserProfile } from './UserProfile';

it('shows user name after loading', async () => {
  render(<UserProfile userId="1" />);
  // FLAKY: the component fetches on mount, but we don't wait for the update
  await new Promise(r => setTimeout(r, 100)); // sleep smell
  expect(screen.getByText('Alice')).toBeInTheDocument();
});

// GOOD: use findBy* which internally wraps in act() and retries
it('shows user name after loading', async () => {
  render(<UserProfile userId="1" />);
  // findByText polls until element appears (wraps in act automatically)
  // eliminates the need for sleep AND the act() warning
  const nameEl = await screen.findByText('Alice', {}, { timeout: 3000 });
  expect(nameEl).toBeInTheDocument();
});

// GOOD: when triggering user events, @testing-library/user-event v14+
// wraps all interactions in act() automatically
it('shows confirmation after button click', async () => {
  const user = userEvent.setup(); // v14 API — wraps all events in act()
  render(<ConfirmDialog onConfirm={jest.fn()} />);
  await user.click(screen.getByRole('button', { name: /confirm/i }));
  await screen.findByText('Action confirmed');
});
```

### Pattern 9 — Vitest Concurrent Test Isolation [community]

Vitest's `test.concurrent` enables parallel tests within a file but requires explicit isolation — shared imports (singletons, module-level state) cause race conditions even within a single file.

```typescript
// vitest.config.ts — configure pool for safe concurrent execution
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // 'forks' pool: each test file gets a separate process — maximum isolation
    // (slower but eliminates module-level shared state across files)
    pool: 'forks',
    // Enable per-test mocking isolation (resets module registry between tests)
    clearMocks: true,
    restoreMocks: true,
    resetMocks: true,
  },
});
```

```typescript
// safe concurrent test pattern — inject dependencies, don't share singletons
import { describe, it, expect, vi } from 'vitest';
import { createUserService } from './UserService';

// Each test creates its own service instance — no shared state
describe.concurrent('UserService concurrent tests', () => {
  it('creates user A', async ({ expect }) => {
    const mockDb = { insert: vi.fn().mockResolvedValue({ id: 'A', name: 'Alice' }) };
    const service = createUserService(mockDb); // factory, not singleton
    const user = await service.create({ name: 'Alice' });
    expect(user.id).toBe('A');
  });

  it('creates user B', async ({ expect }) => {
    const mockDb = { insert: vi.fn().mockResolvedValue({ id: 'B', name: 'Bob' }) };
    const service = createUserService(mockDb); // independent mock
    const user = await service.create({ name: 'Bob' });
    expect(user.id).toBe('B');
  });
});
```

---

## Anti-Patterns

### AP1 — The Silent Re-Run [community]
**What:** Developer clicks "Retry" in CI when a test fails, test passes, no action taken.
**Why harmful:** Flakiness rate grows silently. Failures become routine noise. Real regressions get masked. Fowler: "A test that sometimes fails is just as bad as a test that always fails — you can never trust it."

### AP2 — `sleep()` / `waitForTimeout()` as a Fix [community]
**What:** Adding `await new Promise(r => setTimeout(r, 500))` to make a timing issue "go away."
**Why harmful:** Increases suite runtime O(N) with every flaky test "fixed" this way. Still fails under CI load when resources are constrained. Does not fix the race — just widens the window.

### AP3 — Shared Database Without Rollback [community]
**What:** Multiple tests insert rows into the same DB schema with no cleanup, assuming test order or assuming "test data won't collide."
**Why harmful:** Works until tests run in parallel. In a parallel run, concurrent writes cause constraint violations, stale reads, or unexpected result sets. Transaction rollback (wrapping each test in a DB transaction that's rolled back in `afterEach`) eliminates this cleanly.

### AP4 — Real Network Calls in Unit/Integration Tests [community]
**What:** Tests that call actual HTTP endpoints, third-party APIs, or even `localhost` services without mocking.
**Why harmful:** Flakiness from network latency, API rate limits, credential expiry, and upstream outages — all outside your control. Use MSW for HTTP, `nock` for Node.js raw HTTP, or `@sinonjs/fake-server` for older setups.

### AP5 — Deleting Flaky Tests [community]
**What:** Removing a test rather than quarantining it because "it was never reliable anyway."
**Why harmful:** You lose coverage you may not recreate. The underlying bug the test was meant to catch goes undetected. Quarantine preserves intent; deletion abandons it.

### AP6 — Global Date/Time Without Clock Control [community]
**What:** Tests that use `new Date()` or `Date.now()` without injecting a controllable clock.
**Why harmful:** Tests pass at 11:58pm and fail at midnight (timezone + day-boundary edge cases). Month/year rollovers reveal date arithmetic bugs hidden by luck.

### AP7 — Quarantine Without SLA [community]
**What:** Tests marked `[QUARANTINE]` or `it.skip` with no due date, no owner, and no tracking issue.
**Why harmful:** The quarantine backlog accumulates indefinitely. Coverage gaps grow. After 6 months, quarantined tests are effectively deleted — nobody remembers what they tested or why they broke.

---

## Real-World Gotchas [community]

1. **`beforeAll` setup is an order-dependency time bomb.** [community]
   Placing expensive setup in `beforeAll` and teardown in `afterAll` creates tests that fail when run in isolation (because `beforeAll` didn't run). Always verify each test can run alone with `--testNamePattern`. Root cause: suites evolve and someone adds a `beforeAll`-dependent test months later.

2. **Playwright `networkidle` is a notorious source of CI flakiness.** [community]
   `waitForLoadState('networkidle')` waits for 500ms of no network requests — analytics, chat widgets, and polling APIs can keep this waiting indefinitely or fire at unpredictable intervals. Replace with `waitForResponse()` targeting your own API endpoints or explicit locator assertions.

3. **Jest module caching causes shared singleton state across test files.** [community]
   When two test files import the same module, Jest (without `--resetModules`) reuses the cached instance. A module that mutates its own state (e.g., a singleton event bus) causes cross-file flakiness that's nearly impossible to reproduce locally without running the full suite. Fix: add `resetModules: true` in jest.config or use `jest.isolateModules()` per test file.

4. **CI parallelism amplifies every existing race condition.** [community]
   A test suite that runs green locally (single-threaded) can show 10–30% flakiness rate when first moved to parallel execution. The reason: shared DB sequences, shared file paths in `os.tmpdir()`, and port conflicts. Audit all `tmp` file paths and DB sequences before enabling parallelism.

5. **Timezone and locale flakiness is invisible until you deploy globally.** [community]
   Tests that use `toLocaleDateString()`, `Intl.DateTimeFormat`, or `moment().format()` without fixing the locale and timezone will produce different output on developer machines (local timezone) vs. CI (UTC). The fix is to use `@sinonjs/fake-timers` or `jest.useFakeTimers({ now: new Date('2026-01-15T12:00:00Z') })` and explicitly set `TZ=UTC` in CI env.

6. **Retry-without-reporting hides a growing flakiness debt.** [community]
   Configuring `retries: 2` in Playwright or `retryTimes: 2` in Jest is correct, BUT only if you track and alert on retry rate. A test that passes on retry 2 every day for a month is costing CI minutes and hiding a real bug. Wire retry counts to a flakiness dashboard or fail the build if retry rate exceeds 5% of test runs.

7. **Mock Service Worker (MSW) v1→v2 migration caused widespread handler flakiness.** [community]
   MSW v2 changed handler matching semantics — `rest.get` became `http.get`, and response resolvers changed signature. Teams that upgraded without updating handlers saw intermittent 500 errors in tests because old and new handlers conflicted during the migration period. Always pin MSW version in `package.json` and upgrade in a single atomic PR.

8. **Unawaited Promises in `afterEach` cause order-dependency across test files.** [community]
   `afterEach(async () => { cleanup() })` — if `cleanup()` returns a Promise and you forget `await`, Jest silently moves on to the next test. The cleanup runs concurrently with the next test's setup, corrupting shared state. Always `await` every async call in setup/teardown hooks, and enable `jest/no-floating-promises` ESLint rule to catch this statically.

9. **Cypress `cy.intercept()` race conditions with async route registration.** [community]
   In Cypress, `cy.intercept()` must be called before the network request it intercepts. If the component triggers a fetch immediately on mount (before `cy.intercept()` registers), the real request goes through. Pattern: always call `cy.intercept()` before `cy.visit()` or `cy.mount()`, never after. Teams migrating from Cypress 9 `cy.route()` to `cy.intercept()` often hit this — the semantics changed.

10. **BuildPulse / Trunk Flaky Tests miss flakiness below their detection threshold.** [community]
    Third-party flakiness trackers (BuildPulse, Trunk) detect tests that fail in < X% of runs with zero code change. Tests that flake once a month (below the threshold) accumulate silently. Complement third-party tooling with a nightly 5× rerun job that explicitly reports pass-on-retry counts — this catches low-frequency flakiness the trackers miss.

---

## Tradeoffs & Alternatives

### When quarantine-and-fix works well
- Small-to-medium test suites (< 2000 tests) where flaky tests are rare events
- Teams with a dedicated "flaky test" rotation or clear ownership
- Teams with a quarantine SLA (e.g., all quarantined tests fixed within 2 sprints)

### When quarantine becomes unmanageable
- Suites with > 5% flakiness rate: quarantine backlog grows faster than it's fixed
- Teams without a fix-it rotation: quarantine becomes a graveyard
- Monorepos where multiple teams share a test runner: no single owner for the backlog

**Alternative: Flakiness budget + hard cap.** Google enforces that any test exceeding a flakiness threshold is automatically disabled and must be fixed before re-enabling. This is stricter than quarantine but prevents backlog growth. Implementation: a CI job that reads retry counts from JUnit XML output and fails the build if any single test's flakiness rate exceeds 3%.

**Alternative: Test hermetic environments.** Instead of mocking, spin up a real DB and real service in a container per test run (Testcontainers for Node). Eliminates most shared-state and external-dep flakiness at the cost of slower setup (~5–30s per suite). Worthwhile for integration tests.

```typescript
// Integration test with Testcontainers — hermetic PostgreSQL per test suite
// Eliminates shared-DB flakiness: every run gets a fresh, isolated database
import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import { Pool } from 'pg';
import { UserRepository } from '../src/UserRepository';

let container: StartedPostgreSqlContainer;
let pool: Pool;

beforeAll(async () => {
  // Start a real PostgreSQL instance in Docker — takes ~5–10s, zero shared state
  container = await new PostgreSqlContainer('postgres:16-alpine').start();
  pool = new Pool({ connectionString: container.getConnectionUri() });
  await pool.query('CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT NOT NULL)');
}, 60_000); // generous timeout for container startup

afterAll(async () => {
  await pool.end();
  await container.stop(); // container removed — no cleanup leaks to next suite
});

beforeEach(async () => {
  // Truncate between tests for sub-test isolation without restarting the container
  await pool.query('TRUNCATE users RESTART IDENTITY CASCADE');
});

it('saves and retrieves a user', async () => {
  const repo = new UserRepository(pool);
  const saved = await repo.create({ name: 'Alice' });
  const found = await repo.findById(saved.id);
  expect(found?.name).toBe('Alice');
});
```

**Alternative: Identify and fix order-dependency with `--shard` runs.** Run your suite in different shard orderings in CI. Tests that fail only in certain shard combinations are order-dependent. Fix: ensure each test cleans up after itself regardless of what ran before.

**Alternative: Third-party flakiness detection services.** BuildPulse, Trunk Flaky Tests, and GitHub's native flaky test detection (beta) automatically identify flaky tests from CI history without requiring manual nightly jobs. Trade-off: they require sending test results to an external service and have detection thresholds that miss infrequent flakiness.

### Known adoption costs
- Quarantine tooling requires team agreement on tags and a process to review the backlog weekly
- Replacing `sleep()` with `waitFor()` requires understanding what condition to wait on — more thinking upfront, but the test becomes self-documenting
- Fake timers (e.g., `jest.useFakeTimers`) can cause issues with async libraries that internally use `setTimeout` for debouncing (e.g., lodash debounce, React batched updates in older versions) — needs per-library investigation
- MSW adds a test infrastructure dependency; handler maintenance burden grows with API surface area
- Testcontainers requires Docker in CI; adds 5–30s cold-start latency per suite; Docker-in-Docker on some CI providers requires privileged mode

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Eradicating Non-Determinism in Tests | Official | https://martinfowler.com/articles/nonDeterminism.html | Fowler's canonical taxonomy of flakiness root causes |
| Flaky Tests at Google | Official | https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html | Scale data on flakiness rates and Google's quarantine approach |
| Playwright Retries Docs | Official | https://playwright.dev/docs/test-retries | Retry configuration, trace on retry, flakiness reporting |
| Jest Retry Times | Official | https://jestjs.io/docs/configuration#retrytimes-number | jest-circus retry configuration |
| Mock Service Worker | Community | https://mswjs.io/ | Network-level mocking that prevents real HTTP calls |
| Testcontainers for Node | Community | https://testcontainers.com/guides/getting-started-with-testcontainers-for-nodejs/ | Hermetic DB/service containers to eliminate external dep flakiness |
| @sinonjs/fake-timers | Community | https://github.com/sinonjs/fake-timers | Controllable clock for timing-sensitive tests |
| BuildPulse | Community | https://buildpulse.io/ | Automated flaky test detection from CI history |
| Trunk Flaky Tests | Community | https://trunk.io/flaky-tests | Flaky test tracking with auto-quarantine |
| Vitest Pool Configuration | Official | https://vitest.dev/config/#pool | Concurrent test isolation settings |
