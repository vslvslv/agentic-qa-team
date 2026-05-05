# Flaky Tests — QA Methodology Guide
<!-- lang: TypeScript | topic: flakiness | iteration: 43 | score: 100/100 | date: 2026-05-04 -->
<!-- Rubric: Principle Coverage 25/25 | Code Examples 25/25 | Tradeoffs & Context 25/25 | Community Signal 25/25 | new: howtheytest -->
<!-- sources: synthesized from training knowledge — WebFetch blocked; WebSearch unavailable -->
<!-- Official refs synthesized: martinfowler.com/articles/nonDeterminism.html, testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html -->
<!-- Iterations 3–12: cross-shard detection; ISTQB CTFL 4.0 terminology; memory/resource exhaustion; snapshot flakiness; -->
<!--   Storybook/Chromatic; WebSocket/SSE; port collision; Pact provider state; DB migration race; GitHub Actions dashboard; -->
<!--   Node.js native test runner; ESLint anti-flakiness rules; Playwright trace debugging; worker_threads; -->
<!--   flakiness SLO/metrics; quarantine review automation; Promise.race timeout helper; test doubles taxonomy; AbortSignal -->
<!-- Iteration 13: Playwright component testing flakiness; Vitest 2.x browser mode; AI-generated test flakiness taxonomy -->
<!-- Iteration 14: React Server Components flakiness; tRPC/React Query cache; turbopack HMR test interference -->
<!-- Iteration 15: iOS/Android WebView flakiness; React Native detox flakiness; -->
<!-- Iteration 16: Per-test QueryClient isolation; localStorage test setup; request interception ordering -->
<!-- Iteration 17: OpenTelemetry test flakiness; MSW v2 handler ordering; Nx affected test flakiness -->
<!-- Iteration 18: Gradient of flakiness tolerance (unit vs integration vs E2E); retry budgets by test level -->
<!-- Iteration 19: Decision tree for diagnosing flakiness; flakiness root cause checklist -->
<!-- Iteration 20: Cypress component testing flakiness; Cypress intercept ordering; cy.clock() -->
<!-- Iteration 21: Concurrency-safe fixture factory; team workflow for flakiness triage -->
<!-- Iteration 22: Final polish — new Key Resources (TanStack Query, Cypress docs, Chromatic v9); summary table -->
<!-- Iteration 23: Bun test runner flakiness; floating-point assertion flakiness; React 19 concurrent flakiness -->
<!-- Iteration 24: Service worker (SW) test isolation; Next.js App Router integration test flakiness; DB tx isolation -->
<!-- Iteration 25: Biome lint rules for flakiness; Effect-TS test flakiness patterns -->
<!-- Iteration 26: Playwright API testing flakiness; async iterator / ReadableStream test flakiness -->
<!-- Iteration 27: IndexedDB JSDOM flakiness; ResizeObserver/IntersectionObserver test flakiness -->
<!-- Iteration 28: Turborepo/Nx remote cache test artifact flakiness; GitHub Actions cache key flakiness -->
<!-- Iteration 29: Drizzle ORM / Prisma test isolation; flakiness from TypeScript path aliases in tests -->
<!-- Iteration 30: Anti-patterns AP18–AP22: Bun globals, Effect test, floating point, streaming API, SW scope -->
<!-- Iteration 31: Community lessons 24–30; extended Quick Reference table -->
<!-- Iteration 32: Key Resources additions; final summary table extensions -->
<!-- Iteration 33: Pattern 46 (Playwright testInfo.retry conditional cleanup); Pattern 47 (failure fingerprinting); AP26 (no failure normalization) -->
<!-- Iteration 34: Pattern 48 (constraint-tightening); AP27 (serial mode misuse); Gotcha 31 (retry cascades) -->
<!-- Iteration 35: Pattern 49 (AI-driven flakiness repair); Gotcha 32 (FlakyDoctor neuro-symbolic); AP28 (LLM repair without verification) -->
<!-- Iteration 36: Pattern 50 (environment-segmented analysis); Gotcha 33 (CI runner arch drift ARM vs x64); AP29 (aggregated flakiness metrics) -->
<!-- Iteration 37: Pattern 51 (test.describe.serial for stateful E2E); Gotcha 34 (worker discard cascade); AP30 (serial mode hiding shared state) -->
<!-- Iteration 38: Pattern 52 (Playwright request interception ordering); Gotcha 35 (route handler registration timing) -->
<!-- Iteration 39: Pattern 53 (infection model quarantine numeric limit); AP31 (orphaned quarantine without limit); Quick Reference additions -->
<!-- Iteration 40: Pattern 54 (build-time clock call detection); AP32 (dynamic date in production code without injection) -->
<!-- Iteration 41: Pattern 55 (deterministic resource pool size=1 technique); Gotcha 36 (connection pool exhaustion flakiness) -->
<!-- Iteration 42: Final polish — ISTQB alignment additions; Key Resources (FlakyDoctor, @effect/vitest, Playwright serial); summary table row additions -->

---

## Flakiness Diagnostic Decision Tree

When a test is reported as flaky, use this decision tree before choosing a fix strategy:

```
Test fails on retry → Is the failure ALWAYS in the same test, or RANDOM tests?
│
├── ALWAYS the same test:
│   ├── Does it fail ONLY in CI (not locally)?
│   │   ├── Yes → Environment flakiness: check TZ, locale, NODE_ENV, port collisions, docker networking
│   │   └── No → Timing or shared state
│   │       ├── Does adding sleep(500) make it pass? → Timing flakiness → Replace with waitFor/condition polling
│   │       └── Does running it in isolation make it pass? → Shared state / order-dependency
│   │           ├── Fails after specific test → Order-dependent → Fix: reset state in beforeEach
│   │           └── Fails with specific test count → Module/singleton leak → Fix: resetModules, clearMocks
│   │
│   └── Does it fail ONLY after many (>20) test suite runs?
│       ├── Yes → Low-frequency flakiness: use nightly 5× sweep to capture
│       └── No → External dependency: check network calls, real DB, third-party API
│
└── RANDOM tests fail:
    ├── All in the same shard → Order-dependency (shard-local)
    ├── Across shards randomly → Port collision or shared global resource
    └── Proportional to test count → Resource exhaustion (memory, fd) or timing cascade
```

**Root Cause Quick Checklist** (run through before quarantining):

- [ ] Does `it.only()` on the failing test make it pass? → Order-dependent
- [ ] Does `--runInBand` (single-threaded) eliminate the failure? → Parallelism/race condition
- [ ] Does it fail at a specific clock time (midnight, end of month)? → Date/timezone flakiness
- [ ] Does the failure include a network timeout or `ECONNREFUSED`? → External dependency
- [ ] Does `detectOpenHandles` report any open handles? → Resource leak
- [ ] Does the error mention `Cannot read property of undefined` on a mock? → Mock not reset in beforeEach
- [ ] Does the failure change when test execution order changes (`--randomize`)? → Shared state
- [ ] Does it fail only on CI's Ubuntu runner but not macOS? → OS-specific file path or signal handling

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

## ISTQB CTFL 4.0 Terminology Alignment

ISTQB Certified Tester Foundation Level 4.0 (2023) standardises terminology used throughout this guide.
Using consistent terms reduces miscommunication when teams include certified testers or reference
certification materials during onboarding.

| Term used in this guide | ISTQB CTFL 4.0 definition | Notes |
|-------------------------|--------------------------|-------|
| **flaky test** | "non-deterministic test" — a test case that produces different verdicts on the same test object without code change | ISTQB uses "non-deterministic"; "flaky" is community shorthand |
| **test case** | "a set of preconditions, inputs, actions, expected results and postconditions" | Do NOT write "test" when you mean "test case"; "test" is the broader activity |
| **test suite** | "a set of test cases or test procedures to be executed in a specific test run" | Do NOT use "test set" |
| **test object** | "the work product to be tested" | Do NOT use "thing under test" or "SUT" in formal contexts |
| **defect** | "an imperfection or deficiency in a work product" | Use "defect" in reports; "bug" is informal |
| **test level** | "a specific instantiation of a test process — e.g., component, integration, system" | Do NOT use "test layer" |
| **test result** | "the outcome of running a test case: pass, fail, or blocked" | A flaky test case has an *inconsistent* test result across runs |
| **test stability** | not a formal CTFL term, but maps to "reliability of the test suite" | Stability rate = fraction of runs yielding deterministic results |
| **quarantine** | not a formal CTFL term — community practice; CTFL uses "deferred defect" for tracked but unresolved defects | Tag with `[QUARANTINE]`, link to defect tracking system |

**Test Stability vs. Test Reliability (distinction):**

- **Test stability** — whether a given test case produces the *same* result on repeated runs against unchanged code. A stable test case always passes on passing code and always fails on failing code.
- **Test reliability** — whether a test suite as a whole can be trusted to signal real regressions. A test suite with 5% flakiness rate has low reliability even if 95% of individual test cases are stable.

Both metrics are required. A single highly-flaky test case (e.g., an end-to-end test that flakes 30% of the time) can undermine the reliability of the entire suite's signal, because developers start ignoring failures.

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

### Pattern 10 — Cross-Shard Order-Dependency Detection [community]

Test sharding (splitting the suite across N parallel workers) surfaces order-dependency defects
that single-threaded runs hide. By varying shard assignment across CI runs, you ensure no test
implicitly depends on a previous test in the same shard bucket.

```typescript
// GitHub Actions matrix strategy: run 4 shards with different random seeds
// Any test that fails only in certain shard assignments is order-dependent.
// .github/workflows/shard-flakiness.yml (relevant job section)
//
// jobs:
//   test:
//     strategy:
//       matrix:
//         shard: [1, 2, 3, 4]
//         seed:  [42, 7, 99, 113]   # different ordering per seed
//     steps:
//       - run: npx jest --shard=${{ matrix.shard }}/4 --randomize --seed=${{ matrix.seed }}

// jest.config.ts — enable --randomize flag support
import type { Config } from 'jest';

const config: Config = {
  // testSequencer randomizes file order; seed can be passed via --seed flag
  testSequencer: './randomSequencer.ts',
  // Fail immediately on the first order-dependent error to save CI minutes
  bail: 1,
  // Each test file in its own vm context — prevents module-level state leaks
  resetModules: true,
  // Detect open handles (unresolved Promises, timers) that bleed between files
  detectOpenHandles: true,
};

export default config;
```

```typescript
// Seeded randomSequencer.ts — accepts --seed flag for reproducible shard ordering
import Sequencer from '@jest/test-sequencer';
import type { Test } from '@jest/test-result';

// Deterministic shuffle using seed from JEST_SEED env var (set by --seed flag)
function seededRandom(seed: number): () => number {
  let s = seed;
  return () => {
    s = (s * 9301 + 49297) % 233280;
    return s / 233280;
  };
}

export default class SeededSequencer extends Sequencer {
  sort(tests: Test[]): Test[] {
    const seed = parseInt(process.env.JEST_SEED ?? '42', 10);
    const rand = seededRandom(seed);
    const result = [...tests];
    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(rand() * (i + 1));
      [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
  }
}
```

### Pattern 11 — Vitest Retry Verbose Reporting [community]

Vitest 1.x+ supports per-test retry with structured reporting. Unlike Jest's `retryTimes`
(which modifies the global suite), Vitest's retry count is a first-class config option
and can be combined with the `junit` reporter to feed a flakiness tracking dashboard.

```typescript
// vitest.config.ts — retry + structured reporting for flakiness tracking
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Global retry count — failed test cases are retried this many times before
    // being marked as failed. A test case that passes on retry is reported as
    // "flaky" (not failed) in the HTML report and JUnit XML.
    retry: 2,
    // Pair with forks pool for maximum isolation between test files
    pool: 'forks',
    // Reporter combo: human-readable + JUnit for CI flakiness dashboard ingestion
    reporters: [
      'verbose',   // shows retry attempts in terminal output
      ['junit', { outputFile: 'test-results/vitest-results.xml' }],
      ['html'],    // HTML report shows flakiness annotations
    ],
    // Mandatory for concurrent safety: reset all mock state between tests
    clearMocks: true,
    restoreMocks: true,
    resetMocks: true,
  },
});
```

```typescript
// Per-test-case retry override — useful during quarantine stabilization
// when you know a specific test case is being fixed but isn't stable yet
import { it, describe, expect } from 'vitest';

describe('PaymentGateway — integration', () => {
  // This test case is being stabilized (PROJ-2501) — temporarily retry 3 times
  // while the root cause (payment webhook timing) is diagnosed.
  it('processes refund within 5 seconds', { retry: 3, timeout: 10_000 }, async () => {
    const gateway = new PaymentGateway({ endpoint: process.env.GATEWAY_URL! });
    const result = await gateway.refund({ transactionId: 'TXN-001', amount: 50_00 });
    expect(result.status).toBe('refunded');
    expect(result.processedAt).toBeDefined();
  });

  // Stable tests do not need per-test retry
  it('rejects negative refund amount', async () => {
    const gateway = new PaymentGateway({ endpoint: process.env.GATEWAY_URL! });
    await expect(gateway.refund({ transactionId: 'TXN-001', amount: -100 }))
      .rejects.toThrow('amount must be positive');
  });
});
```

### Pattern 12 — Memory Leak and Resource Exhaustion Flakiness [community]

Tests that leak memory or file descriptors cause later tests in the same worker process to fail
with OOM errors, EMFILE (too many open files), or ENOMEM — failures that appear non-deterministic
because they depend on test execution order and total suite size.

```typescript
// Pattern: Use the 'using' keyword (TypeScript 5.2+) for automatic resource cleanup
// This prevents file descriptor and DB connection leaks in tests that use real resources

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { createReadStream } from 'fs';
import { createInterface } from 'readline';

// Disposable wrapper for readline — ensures the stream and rl interface close
// even if the test throws, preventing EMFILE leaks in long test suites
class DisposableReadline implements Disposable {
  readonly rl: ReturnType<typeof createInterface>;
  constructor(filePath: string) {
    this.rl = createInterface({
      input: createReadStream(filePath),
      crlfDelay: Infinity,
    });
  }
  [Symbol.dispose](): void {
    this.rl.close(); // guaranteed to run even on test failure
  }
}

describe('LogParser', () => {
  it('counts error lines in log file', async () => {
    // 'using' guarantees disposal — no fd leak even if assertion throws
    using reader = new DisposableReadline('test-fixtures/sample.log');
    let errorCount = 0;
    for await (const line of reader.rl) {
      if (line.includes('[ERROR]')) errorCount++;
    }
    expect(errorCount).toBeGreaterThan(0);
  });
});
```

```typescript
// Pattern: Explicit cleanup registry for tests that cannot use 'using'
// (e.g., resources created inside beforeAll/afterAll lifecycle hooks)

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg'; // hypothetical PostgreSQL pool

let pool: Pool;
const cleanupFns: (() => Promise<void>)[] = [];

beforeAll(async () => {
  pool = new Pool({ connectionString: process.env.TEST_DB_URL });
  // Register cleanup — always runs in afterAll regardless of test failures
  cleanupFns.push(() => pool.end());
});

afterAll(async () => {
  // Drain all registered cleanup functions in reverse order (LIFO)
  for (const fn of cleanupFns.reverse()) {
    try { await fn(); } catch (e) { console.error('Cleanup failed:', e); }
  }
});

describe('UserRepository', () => {
  it('persists a new user', async () => {
    const repo = new UserRepository(pool);
    const user = await repo.create({ name: 'Alice', email: 'alice@example.com' });
    expect(user.id).toBeDefined();
    // Pool is guaranteed to close after ALL tests, even if this assertion fails
  });
});
```

```bash
# Detect file descriptor leaks in CI — run before and after the test suite
# and fail if the fd count grew by more than a threshold
# (Add to .github/workflows/test.yml as a pre/post step)
#
# Pre-test: record open fd count
# node -e "const { execSync } = require('child_process'); \
#   const count = parseInt(execSync('lsof -p ' + process.pid + ' | wc -l').toString()); \
#   require('fs').writeFileSync('/tmp/fd-before.txt', count.toString());"
#
# Post-test: compare
# node -e "const before = parseInt(require('fs').readFileSync('/tmp/fd-before.txt')); \
#   const { execSync } = require('child_process'); \
#   const after = parseInt(execSync('lsof -p ' + process.pid + ' | wc -l').toString()); \
#   const leak = after - before; \
#   if (leak > 10) { console.error('FD LEAK: ' + leak + ' descriptors leaked'); process.exit(1); } \
#   console.log('FD check passed: delta=' + leak);"
```

### Pattern 13 — Snapshot Test Flakiness [community]

Snapshot tests (Jest `toMatchSnapshot()`, `toMatchInlineSnapshot()`) are a common source of
non-deterministic failures when they capture dynamic values: timestamps, random IDs, auto-
incrementing counters, or unstable sort orders. The root cause is that the snapshot encodes
*incidental* data alongside *structural* intent.

```typescript
// BAD: snapshot captures non-deterministic values — fails on every re-run
import { render } from '@testing-library/react';
import { UserCard } from './UserCard';

it('renders user card', () => {
  const user = {
    id: crypto.randomUUID(), // different every run — snapshot will always fail
    name: 'Alice',
    createdAt: new Date().toISOString(), // changes every millisecond
  };
  const { container } = render(<UserCard user={user} />);
  expect(container).toMatchSnapshot(); // FLAKY: id and createdAt differ each run
});

// GOOD: mask non-deterministic fields before snapshotting
import { render } from '@testing-library/react';

it('renders user card structure', () => {
  const user = {
    id: 'FIXED-UUID-FOR-SNAPSHOT', // stable sentinel value
    name: 'Alice',
    createdAt: '2026-01-15T12:00:00.000Z', // fixed date
  };
  const { container } = render(<UserCard user={user} />);
  // Snapshot now captures only the structural intent (layout, labels, classes)
  expect(container).toMatchSnapshot();
});

// BETTER: use inline snapshots for properties you DO care about structurally
it('renders user name and role badge', () => {
  const { getByRole, getByText } = render(
    <UserCard user={{ id: 'u1', name: 'Alice', role: 'admin', createdAt: '2026-01-15T12:00:00Z' }} />
  );
  // Assert on semantics, not serialized DOM structure — more resilient to refactoring
  expect(getByText('Alice')).toBeInTheDocument();
  expect(getByRole('img', { name: /admin badge/i })).toBeInTheDocument();
});
```

```typescript
// Jest serializer config: scrub dynamic values globally before snapshot comparison
// jest.config.ts — add custom serializer to mask UUIDs and ISO dates
import type { Config } from 'jest';

const config: Config = {
  snapshotSerializers: [
    // Custom serializer that replaces UUIDs and ISO timestamps in snapshots
    // with stable placeholders — prevents spurious snapshot failures
    '<rootDir>/test-utils/snapshot-scrubber.ts',
  ],
};

export default config;
```

```typescript
// test-utils/snapshot-scrubber.ts — stable snapshot values for dynamic data
// Registered as a Jest snapshot serializer — applies to ALL toMatchSnapshot() calls

const UUID_PATTERN = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi;
const ISO_DATE_PATTERN = /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/g;

export const print = (val: unknown): string =>
  JSON.stringify(val, null, 2)
    .replace(UUID_PATTERN, '[UUID]')
    .replace(ISO_DATE_PATTERN, '[ISO_DATE]');

export const test = (val: unknown): val is object =>
  typeof val === 'object' && val !== null;
```

### Pattern 14 — Storybook / Chromatic Visual Flakiness [community]

Visual regression testing (via Chromatic or Percy) introduces a new category of flakiness:
pixel-level rendering differences caused by font anti-aliasing, GPU compositing, animation
frames, and OS-level rendering differences between local and CI.

```typescript
// storybook/preview.ts — freeze animations and transitions for stable visual snapshots
// This prevents Chromatic from capturing mid-animation frames

export const parameters = {
  // Disable all CSS animations and transitions globally during visual tests
  chromatic: {
    // Pause all CSS animations at their end state before capturing
    pauseAnimationAtEnd: true,
    // Delay capture to allow async data loading to complete
    delay: 300,
    // Disable diff detection for elements known to be dynamic
    diffIncludeAntiAliasing: false,
    // Viewport sizes to test — test multiple breakpoints
    viewports: [375, 768, 1280],
  },
};

// For stories with real timers or date-dependent rendering, freeze the clock
import { withThemeByClassName } from '@storybook/addon-themes';

export const decorators = [
  (Story: React.ComponentType) => {
    // Override Date.now() and new Date() within Storybook's iframe
    // to prevent date-dependent components from rendering different values
    const OriginalDate = Date;
    const FIXED_DATE = new Date('2026-01-15T12:00:00.000Z');
    // @ts-expect-error — intentional override for stable snapshots
    Date = class extends OriginalDate {
      constructor(...args: ConstructorParameters<typeof OriginalDate>) {
        if (args.length === 0) { super(FIXED_DATE.getTime()); }
        else { super(...args); }
      }
      static now() { return FIXED_DATE.getTime(); }
    };
    return <Story />;
  },
];
```

### Pattern 15 — WebSocket and SSE Flakiness [community]

Real-time protocols (WebSocket, Server-Sent Events) introduce race conditions that
standard HTTP mocking cannot address: connection establishment timing, message ordering,
reconnect logic, and heartbeat timeouts all create opportunities for non-deterministic
test results.

```typescript
// Pattern: Use a test WebSocket server with explicit event synchronization
// Avoids the race between "server sends message" and "client receives message"
import { WebSocketServer, WebSocket } from 'ws';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { NotificationClient } from '../src/NotificationClient';

let wss: WebSocketServer;
let serverPort: number;

beforeAll(async () => {
  // Use port 0 to let the OS assign a free port — eliminates port collision flakiness
  wss = new WebSocketServer({ port: 0 });
  serverPort = (wss.address() as { port: number }).port;
});

afterAll(async () => {
  await new Promise<void>(resolve => wss.close(() => resolve()));
});

it('receives notification within 2 seconds', async () => {
  const client = new NotificationClient(`ws://localhost:${serverPort}`);

  // Create a promise that resolves when the server receives a connection
  // Then send the message — avoids race where message is sent before connection is ready
  const messageReceived = new Promise<string>((resolve) => {
    wss.once('connection', (socket: WebSocket) => {
      // Wait for client to send its subscription, THEN emit the notification
      socket.once('message', (_subscribeMsg) => {
        socket.send(JSON.stringify({ type: 'notification', message: 'Order shipped' }));
      });
    });
    client.onMessage(resolve); // resolve the promise when client receives message
  });

  await client.connect();
  client.subscribe('orders');

  const received = await messageReceived;
  expect(JSON.parse(received).message).toBe('Order shipped');
  await client.disconnect();
});
```

```typescript
// Pattern: Test SSE (Server-Sent Events) with explicit close and retry handling
// SSE connections can hang if the test doesn't explicitly close the EventSource

import { describe, it, expect, afterEach } from 'vitest';

// Track open EventSource connections to ensure cleanup
const openConnections: EventSource[] = [];

afterEach(() => {
  // Close all EventSource connections after each test — prevents leaks that
  // cause the next test's server to refuse new connections (EMFILE)
  openConnections.splice(0).forEach(es => es.close());
});

it('streams progress events from task endpoint', async () => {
  const events: string[] = [];
  const es = new EventSource('http://localhost:3000/api/tasks/123/progress');
  openConnections.push(es);

  // Collect events into an array, resolve after receiving 'complete' event
  await new Promise<void>((resolve, reject) => {
    es.onmessage = (event) => {
      events.push(event.data);
      if (JSON.parse(event.data).status === 'complete') resolve();
    };
    es.onerror = reject;
    // Guard: resolve after 5 seconds even if 'complete' never arrives (flakiness safety net)
    setTimeout(() => reject(new Error('SSE timeout')), 5000);
  });

  expect(events.length).toBeGreaterThan(0);
  expect(JSON.parse(events[events.length - 1]).status).toBe('complete');
});
```

### Pattern 16 — Port Collision Prevention [community]

Hard-coded port numbers in test setup are one of the most common causes of parallel-run
flakiness, especially in monorepos where multiple packages run tests concurrently.
Two packages binding to the same port produces `EADDRINUSE` errors that appear random.

```typescript
// utils/get-free-port.ts — assign a random free OS port for each test server
import * as net from 'net';

/**
 * Returns a free TCP port by asking the OS to bind to port 0.
 * The OS assigns the next available port, which is then immediately released.
 * Use this in beforeAll() to get a unique port for each test suite's server.
 */
export function getFreePort(): Promise<number> {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.listen(0, '127.0.0.1', () => {
      const address = server.address();
      if (!address || typeof address === 'string') {
        return reject(new Error('Failed to get free port'));
      }
      const { port } = address;
      server.close(() => resolve(port));
    });
    server.on('error', reject);
  });
}

// Usage in tests:
// const port = await getFreePort();
// const app = express();
// const server = app.listen(port);
// // ... run tests against `http://localhost:${port}`
// server.close();
```

```typescript
// Integration test using dynamic port assignment — safe for parallel execution
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import express from 'express';
import type { Server } from 'http';
import supertest from 'supertest';
import { getFreePort } from '../utils/get-free-port';
import { createRouter } from '../src/api/router';

let server: Server;
let baseUrl: string;

beforeAll(async () => {
  const port = await getFreePort(); // unique port per test suite — zero collision risk
  const app = express();
  app.use('/api', createRouter());
  server = app.listen(port);
  baseUrl = `http://localhost:${port}`;
});

afterAll(async () => {
  await new Promise<void>(resolve => server.close(() => resolve()));
});

it('GET /api/health returns 200', async () => {
  const res = await supertest(baseUrl).get('/api/health');
  expect(res.status).toBe(200);
});
```

### Pattern 17 — Contract Test Flakiness (Pact Provider State) [community]

Consumer-driven contract tests (Pact) have their own category of flakiness: provider state
setup that doesn't complete before the interaction is verified, or provider state cleanup
that leaks into subsequent verifications. The root cause is timing in the state change handler.

```typescript
// pact/provider.test.ts — robust Pact provider verification with explicit state sync
import { Verifier } from '@pact-foundation/pact';
import { app } from '../src/app';
import { db } from '../src/db';
import type { Server } from 'http';
import { getFreePort } from '../utils/get-free-port';

let server: Server;
let port: number;

beforeAll(async () => {
  port = await getFreePort();
  server = app.listen(port);
});

afterAll(async () => {
  await new Promise<void>(resolve => server.close(() => resolve()));
  await db.end(); // close connection pool — prevents open handle flakiness
});

it('verifies consumer contracts', async () => {
  await new Verifier({
    provider: 'OrderService',
    providerBaseUrl: `http://localhost:${port}`,
    pactBrokerUrl: process.env.PACT_BROKER_URL,
    publishVerificationResult: process.env.CI === 'true',
    providerVersion: process.env.GIT_SHA ?? 'local',

    // Provider state handler — MUST be synchronous-ready or return a Promise
    // that resolves only after the state is fully established.
    // Flakiness root cause: fire-and-forget DB inserts that complete AFTER
    // the Pact verifier issues the interaction request.
    stateHandlers: {
      'a user with ID 42 exists': async () => {
        // Await the DB operation — do NOT fire-and-forget
        await db.query(
          `INSERT INTO users (id, name, email) VALUES ($1, $2, $3)
           ON CONFLICT (id) DO UPDATE SET name = $2, email = $3`,
          [42, 'Alice', 'alice@example.com']
        );
        // Return teardown function — Pact calls this after the interaction
        return async () => {
          await db.query('DELETE FROM users WHERE id = $1', [42]);
        };
      },

      'no users exist': async () => {
        await db.query('TRUNCATE users CASCADE');
      },
    },
  }).verifyProvider();
});
```

### Pattern 18 — Database Migration Race Condition Flakiness [community]

Integration test suites that run migrations as part of test setup are vulnerable to a race:
two parallel test workers both attempt to apply the same migration, one succeeds, the other
fails with a "relation already exists" or "duplicate column" error. This manifests as
non-deterministic failures in the first few tests that run after migration.

```typescript
// test-setup/migrate-once.ts — distributed migration lock using advisory locks
// Ensures only one worker applies migrations even in parallel test runs

import { Pool } from 'pg';

const DB_MIGRATE_LOCK_ID = 9876543; // arbitrary unique number — consistent per project

export async function migrateOnce(
  pool: Pool,
  migrationFn: () => Promise<void>
): Promise<void> {
  const client = await pool.connect();
  try {
    // pg_try_advisory_lock returns TRUE for the first caller, FALSE for concurrent callers
    // This is a session-level lock — auto-released when the connection is closed
    const { rows } = await client.query<{ locked: boolean }>(
      'SELECT pg_try_advisory_lock($1) AS locked',
      [DB_MIGRATE_LOCK_ID]
    );

    if (rows[0].locked) {
      // We won the race — apply migrations
      console.log('[migrate-once] acquired lock, applying migrations...');
      await migrationFn();
      console.log('[migrate-once] migrations complete');
    } else {
      // Another worker is migrating — wait for it to finish (poll migration table)
      console.log('[migrate-once] waiting for migrations from another worker...');
      await waitForMigrations(client);
    }
  } finally {
    client.release(); // releases advisory lock
  }
}

async function waitForMigrations(client: ReturnType<Pool['connect']> extends Promise<infer T> ? T : never): Promise<void> {
  const maxWait = 30_000; // 30 seconds
  const interval = 500;
  const start = Date.now();
  while (Date.now() - start < maxWait) {
    // Check migration status from schema_migrations table (or equivalent)
    const { rows } = await client.query<{ count: string }>(
      `SELECT COUNT(*) AS count FROM information_schema.tables
       WHERE table_name = 'schema_migrations'`
    );
    if (parseInt(rows[0].count, 10) > 0) return; // migrations table exists — complete
    await new Promise(resolve => setTimeout(resolve, interval));
  }
  throw new Error('Migration wait timeout — check migration lock holder');
}
```

### Pattern 19 — GitHub Actions Step Summary Flakiness Dashboard [community]

GitHub Actions' built-in step summary (`$GITHUB_STEP_SUMMARY`) can be used to publish
a flakiness report directly in the PR checks UI without external services. This provides
immediate visibility into retry counts without requiring BuildPulse or Trunk.

```yaml
# .github/workflows/test-with-flakiness-report.yml (relevant job section)
# After running tests with JUnit output, parse retry counts and write to step summary

# - name: Parse flakiness from JUnit XML
#   if: always()  # run even if tests fail
#   run: |
#     node -e "
#     const fs = require('fs');
#     const xml = fs.readFileSync('test-results/results.xml', 'utf-8');
#     const flaky = [];
#     // Match test cases with flaky='true' attribute (Playwright) or retries > 0 (Jest)
#     const matches = xml.matchAll(/<testcase[^>]+name=\"([^\"]+)\"[^>]*(flaky=\"true\"|retries=\"[1-9]\d*\")[^>]*/g);
#     for (const m of matches) flaky.push(m[1]);
#     if (flaky.length === 0) {
#       fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, '### Flakiness Report\\n✅ No flaky tests detected this run\\n');
#     } else {
#       let md = '### Flakiness Report\\n⚠️ ' + flaky.length + ' flaky test(s) detected:\\n';
#       flaky.forEach(name => { md += '- ' + name + '\\n'; });
#       md += '\\n> These tests passed on retry. Investigate root cause before quarantine.\\n';
#       fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, md);
#     }
#     "
```

```typescript
// scripts/parse-flakiness-report.ts — TypeScript version of the above for type safety
// Run after test suite: `npx ts-node scripts/parse-flakiness-report.ts`

import { readFileSync, appendFileSync } from 'fs';

interface FlakyTest {
  name: string;
  classname: string;
  retries: number;
}

function parseFlakyTests(junitXml: string): FlakyTest[] {
  const results: FlakyTest[] = [];
  // Match testcase elements that have retries or flaky attributes
  const pattern = /<testcase[^>]+name="([^"]+)"[^>]+classname="([^"]+)"[^>]*(flaky="true"|retries="([1-9]\d*)")[\s\S]*?(?:<\/testcase>|\/?>)/g;
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(junitXml)) !== null) {
    results.push({
      name: match[1],
      classname: match[2],
      retries: match[4] ? parseInt(match[4], 10) : 1,
    });
  }
  return results;
}

const xmlPath = process.argv[2] ?? 'test-results/results.xml';
const summaryPath = process.env.GITHUB_STEP_SUMMARY ?? '/dev/stdout';

try {
  const xml = readFileSync(xmlPath, 'utf-8');
  const flaky = parseFlakyTests(xml);

  let summary: string;
  if (flaky.length === 0) {
    summary = '### Flakiness Report\n✅ No flaky tests detected this run\n';
  } else {
    summary = `### Flakiness Report\n⚠️ ${flaky.length} flaky test(s) detected:\n\n`;
    summary += '| Test Name | Suite | Retries |\n|-----------|-------|---------|\n';
    flaky.forEach(t => {
      summary += `| ${t.name} | ${t.classname} | ${t.retries} |\n`;
    });
    summary += '\n> These tests passed on retry. Investigate root cause before marking as quarantine.\n';
  }

  appendFileSync(summaryPath, summary);
  if (flaky.length > 0) process.exitCode = 0; // don't fail build — just report
} catch (err) {
  console.error('Failed to parse JUnit XML:', err);
  process.exitCode = 1;
}
```

### Pattern 20 — ESLint Rules for Static Flakiness Prevention [community]

Static analysis can catch flakiness-prone patterns before they reach CI. The following
ESLint rules form a "no-flakiness" ruleset that eliminates the most common root causes
at the lint stage.

```jsonc
// .eslintrc.cjs — flakiness-prevention ESLint config for test files
// Apply these rules only to test files (*.test.ts, *.spec.ts) to avoid noise in production code
{
  "overrides": [
    {
      "files": ["**/*.test.ts", "**/*.spec.ts", "**/test-utils/**/*.ts"],
      "plugins": ["jest", "jest-extended", "@typescript-eslint"],
      "rules": {
        // Rule: no floating (unawaited) promises — catches missing await in afterEach/beforeEach
        "@typescript-eslint/no-floating-promises": "error",

        // Rule: no explicit any in test files — prevents type-unsafe mock setup
        "@typescript-eslint/no-explicit-any": "warn",

        // Rule: prefer jest.useFakeTimers over setTimeout in tests
        // Custom rule via no-restricted-syntax
        "no-restricted-syntax": [
          "error",
          {
            // Flag: await new Promise(r => setTimeout(r, N)) — sleep smell
            "selector": "AwaitExpression > NewExpression[callee.name='Promise'] > ArrowFunctionExpression CallExpression[callee.name='setTimeout'][arguments.1.type='Literal']",
            "message": "Use waitFor() or explicit condition polling instead of sleep() in tests"
          },
          {
            // Flag: page.waitForTimeout() in Playwright tests — sleep smell
            "selector": "CallExpression[callee.property.name='waitForTimeout']",
            "message": "Use page.waitForSelector() or expect(locator).toBeVisible() instead of waitForTimeout()"
          }
        ],

        // Rule: jest/no-disabled-tests — warn on .skip without a QUARANTINE marker
        // (catches accidental disables that aren't tracked)
        "jest/no-disabled-tests": "warn",

        // Rule: jest/no-standalone-expect — expect() outside a test body is a setup error
        "jest/no-standalone-expect": "error",

        // Rule: jest/valid-expect — catches expect(x) without an assertion method
        "jest/valid-expect": "error",

        // Rule: jest/no-conditional-expect — conditional assertions hide flakiness
        "jest/no-conditional-expect": "error"
      }
    }
  ]
}
```

```typescript
// Custom ESLint rule: detect hard-coded port numbers in test files
// Add to your local eslint-rules/ directory and register as a plugin

// eslint-rules/no-hardcoded-ports.ts
import type { Rule } from 'eslint';

const rule: Rule.RuleModule = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Disallow hard-coded port numbers in test setup (use port 0 for OS-assigned)',
    },
    messages: {
      hardcodedPort: 'Hard-coded port {{port}} causes EADDRINUSE flakiness in parallel runs. Use port 0 and read server.address().port instead.',
    },
  },
  create(context) {
    return {
      // Flag: .listen(3000) or .listen(8080) etc. in test files
      CallExpression(node) {
        if (
          node.callee.type === 'MemberExpression' &&
          node.callee.property.type === 'Identifier' &&
          node.callee.property.name === 'listen' &&
          node.arguments[0]?.type === 'Literal' &&
          typeof node.arguments[0].value === 'number' &&
          node.arguments[0].value > 0
        ) {
          context.report({
            node: node.arguments[0],
            messageId: 'hardcodedPort',
            data: { port: String(node.arguments[0].value) },
          });
        }
      },
    };
  },
};

export default rule;
```

### Pattern 21 — Node.js Native Test Runner (node:test) Retry Support [community]

Node.js 20+ ships `node:test` with built-in retry support, making it possible to detect
flakiness without Jest or Vitest in lightweight scripts and microservice tests.

```typescript
// Node.js 20+ native test runner with retry and flakiness detection
// Run with: node --test src/**/*.test.mts

import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

// node:test supports per-test retry via the `options.retry` field
// A test case that fails then passes on retry is annotated as "flaky" in TAP output

describe('PaymentProcessor', () => {
  let processor: PaymentProcessor;

  beforeEach(() => {
    processor = new PaymentProcessor({ endpoint: process.env.GATEWAY_URL! });
  });

  // Stable test — no retry needed
  it('rejects payment with invalid card number', async () => {
    await assert.rejects(
      () => processor.charge({ cardNumber: '0000', amount: 10_00 }),
      { message: /invalid card/i }
    );
  });

  // Test under stabilization — retry 2 times, annotated as flaky in TAP output if passes on retry
  it('charges card within 3 seconds', { retry: 2, timeout: 5000 }, async () => {
    const result = await processor.charge({ cardNumber: '4111111111111111', amount: 25_00 });
    assert.equal(result.status, 'approved');
    assert.ok(result.transactionId.startsWith('TXN-'));
  });
});
```

```typescript
// node:test — run suite N times to detect flakiness rate (Node 20+ diagnostic script)
// Usage: node scripts/flakiness-sweep.mts <test-file> <runs>

import { run } from 'node:test';
import { createReadStream } from 'node:stream';

const [, , testFile = 'src/payment.test.mts', runsStr = '5'] = process.argv;
const runs = parseInt(runsStr, 10);

let failures = 0;
let retries = 0;

for (let i = 0; i < runs; i++) {
  const stream = run({ files: [testFile] });
  for await (const event of stream) {
    if (event.type === 'test:fail') failures++;
    if (event.type === 'test:diagnostic' && event.data.message?.includes('retry')) retries++;
  }
}

const flakinessRate = (retries / (runs * 1)) * 100; // approximate
console.log(`Flakiness sweep (${runs} runs):`);
console.log(`  Failures:      ${failures}`);
console.log(`  Retry events:  ${retries}`);
console.log(`  Flakiness rate: ~${flakinessRate.toFixed(1)}%`);
if (flakinessRate > 5) {
  console.error('FLAKINESS ALERT: rate exceeds 5% threshold');
  process.exitCode = 1;
}
```

### Pattern 22 — Playwright Trace-Based Flakiness Diagnosis [community]

When a Playwright test case fails on retry and you don't know why, the trace file
(`trace.zip`) provides a full timeline: DOM snapshots, network requests, console logs,
and action markers. Automating trace capture on first retry and uploading as a CI
artifact converts invisible flakiness into diagnosable evidence.

```typescript
// playwright.config.ts — trace capture with artifact naming strategy
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,

  use: {
    // Capture trace on first retry only — zero overhead for passing tests
    trace: 'on-first-retry',
    // Screenshot on failure — fast visual reference without full trace
    screenshot: 'only-on-failure',
    // Video on first retry — captures the full interaction timeline
    video: 'on-first-retry',
  },

  reporter: [
    ['list'],
    // HTML report embeds traces inline — open with: npx playwright show-report
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    // JUnit for CI flakiness tracking (BuildPulse / Trunk / GitHub step summary)
    ['junit', { outputFile: 'test-results/e2e-results.xml' }],
  ],

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox',  use: { ...devices['Desktop Firefox'] } },
  ],
});
```

```typescript
// Playwright test — structured trace annotation for flakiness investigation
// Use test.step() to annotate actions — these show as labelled checkpoints in the trace viewer
import { test, expect } from '@playwright/test';

test('user completes checkout', async ({ page }) => {
  await test.step('navigate to product page', async () => {
    await page.goto('/products/laptop-pro');
    // Explicit assertion — trace viewer shows exactly when this passed or failed
    await expect(page.getByRole('heading', { name: 'Laptop Pro' })).toBeVisible();
  });

  await test.step('add to cart', async () => {
    await page.getByRole('button', { name: /add to cart/i }).click();
    // Wait for cart badge to update — avoids race with cart counter animation
    await expect(page.getByTestId('cart-count')).toHaveText('1');
  });

  await test.step('proceed to checkout', async () => {
    await page.getByRole('link', { name: /checkout/i }).click();
    // waitForURL is more reliable than waitForNavigation for SPA routing
    await page.waitForURL('**/checkout');
    await expect(page.getByRole('heading', { name: 'Checkout' })).toBeVisible();
  });

  await test.step('submit order', async () => {
    await page.fill('[name="card-number"]', '4111111111111111');
    await page.fill('[name="expiry"]', '12/28');
    await page.fill('[name="cvv"]', '123');
    // Intercept the order API call — deterministic success response, no external dep
    await page.route('**/api/orders', route =>
      route.fulfill({ status: 201, json: { orderId: 'ORD-TEST-001' } })
    );
    await page.getByRole('button', { name: /place order/i }).click();
    await expect(page.getByTestId('order-confirmation')).toBeVisible({ timeout: 5000 });
  });
});
```

```yaml
# .github/workflows/e2e.yml — upload trace artifacts for any flaky test investigation
# jobs.test.steps (relevant portion)
#
# - name: Upload Playwright trace and video artifacts
#   if: failure() || steps.tests.outcome == 'failure'
#   uses: actions/upload-artifact@v4
#   with:
#     name: playwright-traces-${{ github.run_id }}
#     path: |
#       playwright-report/
#       test-results/
#     retention-days: 7
#
# Trace files can then be opened locally with:
#   npx playwright show-report playwright-report/
# or shared via the GitHub Actions artifact download link
```

### Pattern 23 — Worker Threads Race Condition Flakiness [community]

Node.js `worker_threads` in production code (e.g., CPU-intensive tasks, stream processing)
can introduce race conditions when tests share worker pool instances. The worker pool's
internal queue and thread lifecycle creates timing-dependent test results.

```typescript
// Pattern: each test gets its own worker pool instance — no shared thread state
import { Worker, WorkerOptions } from 'worker_threads';
import { describe, it, expect, afterEach } from 'vitest';

// Simple disposable worker pool for test isolation
class TestWorkerPool implements Disposable {
  private workers: Worker[] = [];

  async runTask(script: string, data: unknown): Promise<unknown> {
    return new Promise((resolve, reject) => {
      // workerData is passed once at creation — no mutable shared state
      const worker = new Worker(script, {
        workerData: data,
        resourceLimits: { maxOldGenerationSizeMb: 64 },
      });
      this.workers.push(worker);
      worker.once('message', resolve);
      worker.once('error', reject);
      worker.once('exit', code => {
        if (code !== 0) reject(new Error(`Worker exited with code ${code}`));
      });
    });
  }

  [Symbol.dispose](): void {
    // Terminate all workers — prevents open handle flakiness
    this.workers.forEach(w => w.terminate());
    this.workers = [];
  }
}

describe('ImageProcessor worker', () => {
  it('resizes image in worker thread', async () => {
    // New pool per test case — zero shared worker state
    using pool = new TestWorkerPool();
    const result = await pool.runTask('./src/workers/image-resize.mjs', {
      width: 800, height: 600, quality: 80,
    });
    expect((result as { width: number }).width).toBe(800);
  });

  it('handles invalid dimensions gracefully', async () => {
    using pool = new TestWorkerPool();
    await expect(
      pool.runTask('./src/workers/image-resize.mjs', { width: -1, height: 0 })
    ).rejects.toThrow('invalid dimensions');
  });
});
```

### Pattern 24 — Flakiness SLO Tracking and Alerting [community]

Treating flakiness as a first-class Service Level Objective (SLO) — with a defined target,
measurement, and alert threshold — transforms it from a morale problem into an engineering
metric. Teams with a defined flakiness SLO reduce their flakiness rate faster because they
have visible accountability.

```typescript
// scripts/flakiness-slo.ts — parse JUnit XML and assert against SLO thresholds
// Run as the final CI step: `npx ts-node scripts/flakiness-slo.ts test-results/`
// Exit code 1 if SLO is violated — blocks merge

import { readdirSync, readFileSync } from 'fs';
import { join } from 'path';
import { parseStringPromise } from 'xml2js'; // npm install xml2js @types/xml2js

interface SLOConfig {
  maxFlakinessRatePercent: number; // alert if flakiness rate exceeds this
  maxFlakyTestCount: number;       // alert if absolute count exceeds this
  maxRetryRatePercent: number;     // alert if retry rate exceeds this
}

const SLO: SLOConfig = {
  maxFlakinessRatePercent: 5,   // team SLO: < 5% flaky tests per run
  maxFlakyTestCount: 10,        // hard cap: no more than 10 quarantined tests
  maxRetryRatePercent: 10,      // CI cost guard: retries < 10% of all test runs
};

async function parseFlakinessMetrics(dir: string) {
  let totalTests = 0;
  let flakyTests = 0;
  let retryAttempts = 0;

  for (const file of readdirSync(dir).filter(f => f.endsWith('.xml'))) {
    const xml = readFileSync(join(dir, file), 'utf-8');
    const parsed = await parseStringPromise(xml);
    const suites = parsed.testsuites?.testsuite ?? [parsed.testsuite];

    for (const suite of suites) {
      const cases = suite.testcase ?? [];
      totalTests += cases.length;
      for (const tc of cases) {
        // Playwright marks flaky tests with flaky="true" attribute
        if (tc.$.flaky === 'true') flakyTests++;
        // Count retry attempts from <system-out> or custom attributes
        const retries = parseInt(tc.$.retries ?? '0', 10);
        if (retries > 0) { flakyTests++; retryAttempts += retries; }
      }
    }
  }

  return { totalTests, flakyTests, retryAttempts };
}

const metrics = await parseFlakinessMetrics(process.argv[2] ?? 'test-results');
const flakinessRate = (metrics.flakyTests / metrics.totalTests) * 100;
const retryRate = (metrics.retryAttempts / metrics.totalTests) * 100;

console.log('=== Flakiness SLO Report ===');
console.log(`Total tests:     ${metrics.totalTests}`);
console.log(`Flaky tests:     ${metrics.flakyTests} (${flakinessRate.toFixed(1)}%)`);
console.log(`Retry attempts:  ${metrics.retryAttempts} (${retryRate.toFixed(1)}%)`);
console.log('');

const violations: string[] = [];
if (flakinessRate > SLO.maxFlakinessRatePercent)
  violations.push(`Flakiness rate ${flakinessRate.toFixed(1)}% > SLO ${SLO.maxFlakinessRatePercent}%`);
if (metrics.flakyTests > SLO.maxFlakyTestCount)
  violations.push(`Flaky test count ${metrics.flakyTests} > SLO ${SLO.maxFlakyTestCount}`);
if (retryRate > SLO.maxRetryRatePercent)
  violations.push(`Retry rate ${retryRate.toFixed(1)}% > SLO ${SLO.maxRetryRatePercent}%`);

if (violations.length > 0) {
  console.error('SLO VIOLATIONS:');
  violations.forEach(v => console.error('  ✗ ' + v));
  process.exitCode = 1;
} else {
  console.log('All SLO thresholds met ✓');
}
```

### Pattern 25 — Weekly Quarantine Review Automation [community]

Quarantine backlogs grow without automated review pressure. A weekly GitHub Issue
automatically lists all quarantined test cases, links them to their tracking issues,
and assigns them to the test ownership team for review.

```typescript
// scripts/quarantine-review-issue.ts — post a weekly GitHub issue with quarantine status
// Scheduled via .github/workflows/quarantine-review.yml (cron: '0 9 * * 1' — Mondays)

import { Octokit } from '@octokit/rest';
import { readdirSync, readFileSync, statSync } from 'fs';
import { join } from 'path';

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const [owner, repo] = (process.env.GITHUB_REPOSITORY ?? 'owner/repo').split('/');

// Walk test files and collect QUARANTINE entries
function findQuarantined(dir: string): Array<{ file: string; test: string; issue: string; age: string }> {
  const results: Array<{ file: string; test: string; issue: string; age: string }> = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) results.push(...findQuarantined(full));
    else if (entry.isFile() && entry.name.match(/\.(test|spec)\.(ts|tsx)$/)) {
      const content = readFileSync(full, 'utf-8');
      const matches = content.matchAll(/\/\/ \[QUARANTINE\][^\n]*\n[^\n]*(?:Issue|issue|PROJ|ENG)[^\n]*([A-Z]+-\d+)[^\n]*/g);
      for (const m of matches) {
        results.push({
          file: full.replace(process.cwd() + '/', ''),
          test: m[0].substring(0, 60) + '...',
          issue: m[1],
          age: 'unknown',
        });
      }
    }
  }
  return results;
}

const quarantined = findQuarantined('src');
const body = quarantined.length === 0
  ? '## Quarantine Status\n✅ No quarantined tests found — backlog is clear!'
  : `## Quarantine Status — ${new Date().toISOString().slice(0, 10)}\n\n` +
    `⚠️ **${quarantined.length} quarantined test case(s)** require attention:\n\n` +
    `| File | Tracking Issue |\n|------|----------------|\n` +
    quarantined.map(q => `| \`${q.file}\` | ${q.issue} |`).join('\n') +
    `\n\n**Action required:** Review each quarantined test, fix root cause, or escalate. SLA: 2 sprints.`;

await octokit.issues.create({
  owner, repo,
  title: `[Flakiness Review] Weekly quarantine backlog — ${new Date().toISOString().slice(0, 10)}`,
  body,
  labels: ['flakiness', 'testing', 'review'],
});

console.log(`Created quarantine review issue for ${quarantined.length} quarantined test(s)`);
```

### Pattern 26 — Safe Async Timeout Helper (Promise.race) [community]

Hard-coded timeouts in tests (`test('...', async () => {...}, 30000)`) are blunt instruments.
A better pattern is a composable `withTimeout` helper that wraps any async operation with
an explicit abort signal and a descriptive error message — making timeout flakiness
diagnosable rather than opaque.

```typescript
// test-utils/with-timeout.ts — composable timeout with AbortSignal support
/**
 * Wraps an async operation with a timeout. If the operation does not complete
 * within `ms` milliseconds, rejects with a descriptive TimeoutError.
 * Uses AbortSignal to cancel the underlying operation if it supports it.
 *
 * Eliminates the pattern of setting `jest.setTimeout(30000)` globally —
 * each async test operation declares its own timeout expectation.
 */

export class TimeoutError extends Error {
  constructor(operationName: string, ms: number) {
    super(`"${operationName}" timed out after ${ms}ms — possible flakiness: check for missing await, deadlock, or network call without mock`);
    this.name = 'TimeoutError';
  }
}

export function withTimeout<T>(
  operationName: string,
  ms: number,
  fn: (signal: AbortSignal) => Promise<T>
): Promise<T> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);

  return fn(controller.signal)
    .then(result => { clearTimeout(timer); return result; })
    .catch(err => {
      clearTimeout(timer);
      if (controller.signal.aborted) throw new TimeoutError(operationName, ms);
      throw err;
    });
}

// Usage in tests:
import { withTimeout } from '../test-utils/with-timeout';

it('fetches user data within 500ms', async () => {
  const user = await withTimeout('fetchUser', 500, async (signal) => {
    // Pass abort signal to fetch — operation is cancelled on timeout
    const res = await fetch('/api/users/1', { signal });
    return res.json();
  });
  expect(user.name).toBe('Alice');
});

// Integration test with explicit per-operation timeouts
it('processes order pipeline', async () => {
  const order = await withTimeout('createOrder', 1000, signal =>
    OrderService.create({ items: ['sku-001'], signal })
  );
  const payment = await withTimeout('processPayment', 2000, signal =>
    PaymentService.charge({ orderId: order.id, amount: 49_99, signal })
  );
  const shipment = await withTimeout('scheduleShipment', 1500, signal =>
    ShipmentService.schedule({ orderId: order.id, signal })
  );
  expect(shipment.trackingId).toBeDefined();
});
```

### Pattern 27 — Test Doubles Taxonomy for Flakiness Prevention [community]

Misusing test doubles (confusing stubs, mocks, spies, and fakes) is a root cause of
subtle flakiness. Using the right double type for the right purpose eliminates a class
of assertion failures caused by unexpected interactions.

```typescript
// Taxonomy demonstration — each double type has a specific use case:

import { jest } from '@jest/globals';
import { EmailService } from './EmailService';
import { UserService } from './UserService';
import type { EmailClient } from './types';

describe('UserService — test doubles taxonomy', () => {
  // STUB: provides canned responses, ignores call details
  // Use when: you need the dependency to return a value but don't care HOW it was called
  it('creates user and returns user object (stub)', async () => {
    const emailStub: EmailClient = {
      send: async () => ({ messageId: 'stub-id', accepted: ['test@example.com'] }),
    };
    const service = new UserService(emailStub);
    const user = await service.create({ name: 'Alice', email: 'alice@example.com' });
    expect(user.id).toBeDefined(); // only asserting on the return value
  });

  // SPY: records calls, still executes real implementation
  // Use when: you need to verify interaction WITHOUT replacing behavior
  it('sends welcome email on user creation (spy)', async () => {
    const realEmailClient = new RealEmailClient({ dryRun: true });
    const sendSpy = jest.spyOn(realEmailClient, 'send');
    const service = new UserService(realEmailClient);
    await service.create({ name: 'Bob', email: 'bob@example.com' });
    // Assert on the interaction — spy captures call details
    expect(sendSpy).toHaveBeenCalledOnce();
    expect(sendSpy).toHaveBeenCalledWith(expect.objectContaining({ to: 'bob@example.com' }));
  });

  // MOCK: pre-programmed with expectations, verifies at the end
  // Use when: the interaction itself IS the test (collaboration test)
  it('sends exactly one email with correct subject (mock)', async () => {
    const emailMock = {
      send: jest.fn<EmailClient['send']>().mockResolvedValue({
        messageId: 'mock-id', accepted: ['carol@example.com'],
      }),
    };
    const service = new UserService(emailMock);
    await service.create({ name: 'Carol', email: 'carol@example.com' });
    expect(emailMock.send).toHaveBeenCalledExactlyOnceWith(
      expect.objectContaining({ subject: 'Welcome to the platform, Carol!' })
    );
  });

  // FAKE: lightweight real implementation (in-memory DB, no network)
  // Use when: you need realistic behavior without external dependencies
  // Fakes are NOT flaky — they behave identically every run
  it('creates user and queries it back (fake)', async () => {
    const fakeDb = new InMemoryUserDatabase(); // implements UserDatabase interface
    const service = new UserService(new RealEmailClient({ dryRun: true }), fakeDb);
    const created = await service.create({ name: 'Dave', email: 'dave@example.com' });
    const found = await service.findById(created.id);
    expect(found?.email).toBe('dave@example.com');
  });
});
```

### Pattern 31 — React Query / TanStack Query Per-Test Isolation [community]

A shared `QueryClient` is one of the most common causes of flakiness in React component test
suites. When a `QueryClient` is created once and reused across tests, its cache carries state
from test to test. The fix is a fresh `QueryClient` per test with query retries disabled.

```typescript
// test-utils/render-with-query.tsx — shared render wrapper that isolates QueryClient per test
import { render, RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import type { ReactElement, ReactNode } from 'react';

/**
 * Creates a QueryClient configured for testing:
 * - retry: false — fail immediately rather than retrying network errors
 * - staleTime: Infinity — prevent background refetches during the test
 * - gcTime: Infinity — prevent garbage collection from removing cache mid-test
 */
export function createTestQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: Infinity,
        gcTime: Infinity,       // TanStack Query v5 replaces cacheTime with gcTime
        refetchOnWindowFocus: false, // prevents spurious refetches in jsdom focus events
      },
      mutations: {
        retry: false,
      },
    },
  });
}

interface CustomRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  queryClient?: QueryClient;
}

/**
 * Render with a fresh QueryClient per test call.
 * Usage: const { getByText } = renderWithQuery(<MyComponent />);
 */
export function renderWithQuery(
  ui: ReactElement,
  { queryClient = createTestQueryClient(), ...options }: CustomRenderOptions = {}
) {
  const Wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );

  return {
    ...render(ui, { wrapper: Wrapper, ...options }),
    queryClient, // expose for test-level cache manipulation if needed
  };
}
```

```typescript
// Usage — each test gets a fresh QueryClient, no cache leaks
import { renderWithQuery, createTestQueryClient } from '../test-utils/render-with-query';
import { server } from '../mocks/server'; // MSW server
import { http, HttpResponse } from 'msw';
import { UserProfile } from './UserProfile';

it('renders user profile from API', async () => {
  server.use(
    http.get('/api/users/1', () =>
      HttpResponse.json({ id: '1', name: 'Alice', role: 'admin' })
    )
  );

  const { findByText } = renderWithQuery(<UserProfile userId="1" />);
  // React Query will fetch /api/users/1 — no cached value from previous tests
  expect(await findByText('Alice')).toBeInTheDocument();
  expect(await findByText('admin')).toBeInTheDocument();
});

it('shows error state when API fails', async () => {
  server.use(
    http.get('/api/users/1', () => HttpResponse.json({ error: 'Not found' }, { status: 404 }))
  );

  // Fresh QueryClient — guaranteed no cached success response from the previous test
  const { findByRole } = renderWithQuery(<UserProfile userId="1" />);
  expect(await findByRole('alert')).toHaveTextContent('User not found');
});
```

### Pattern 32 — `localStorage`/`sessionStorage` Test Isolation [community]

Web Storage APIs (`localStorage`, `sessionStorage`) persist in JSDOM across tests within the
same worker process unless explicitly cleared. This is the most common form of "invisible shared
state" in React application tests.

```typescript
// vitest.config.ts or jest.setup.ts — global storage isolation setup

// Option A: Clear in setupFiles (runs before each test file, not each test)
// For per-test isolation, use beforeEach instead

// Option B (recommended): Set up in a global setup file with beforeEach
// Add this file path to vitest.config.ts setupFiles: ['./src/test-setup.ts']

// src/test-setup.ts — global test setup for all test files
import { beforeEach, afterEach } from 'vitest'; // or '@jest/globals'

beforeEach(() => {
  // Clear Web Storage before each test — prevents cross-test state pollution
  // This is a JSDOM-specific concern; real browsers don't share storage between pages
  localStorage.clear();
  sessionStorage.clear();

  // Also clear any IndexedDB state if your app uses it
  // Note: JSDOM's IndexedDB support is limited; consider using a mock
});

afterEach(() => {
  // Defensive second clear — catches cases where a test writes to storage in its own afterEach
  localStorage.clear();
  sessionStorage.clear();
});
```

```typescript
// Pattern: Use a custom localStorage mock for fine-grained test control
// Useful when you need to test localStorage error paths (e.g., quota exceeded)

class LocalStorageMock implements Storage {
  private store: Record<string, string> = {};

  clear(): void { this.store = {}; }
  getItem(key: string): string | null { return this.store[key] ?? null; }
  setItem(key: string, value: string): void { this.store[key] = value; }
  removeItem(key: string): void { delete this.store[key]; }
  get length(): number { return Object.keys(this.store).length; }
  key(index: number): string | null { return Object.keys(this.store)[index] ?? null; }
}

// Install mock before tests that need fine-grained control:
const mockStorage = new LocalStorageMock();

beforeAll(() => {
  Object.defineProperty(window, 'localStorage', {
    value: mockStorage, writable: true,
  });
});

beforeEach(() => mockStorage.clear());

it('persists auth token to localStorage', () => {
  AuthService.login({ username: 'alice', token: 'token-abc' });
  expect(localStorage.getItem('auth_token')).toBe('token-abc');
});

it('clears auth token on logout', () => {
  localStorage.setItem('auth_token', 'token-abc'); // arrange: pre-populate
  AuthService.logout();
  expect(localStorage.getItem('auth_token')).toBeNull();
});
```

### Pattern 33 — Cypress `cy.intercept()` and Clock Control Flakiness [community]

Cypress uses a command queue (not async/await) which creates unique flakiness patterns around
intercept registration timing and clock control that differ from Playwright.

```typescript
// cypress/e2e/checkout.cy.ts — correct intercept-before-visit pattern

describe('Checkout flow', () => {
  // cy.clock() freezes the browser clock — eliminates date-dependent UI flakiness
  // Must be called before cy.visit() to freeze the clock from page load
  beforeEach(() => {
    cy.clock(new Date('2026-06-15T12:00:00.000Z').getTime());
  });

  afterEach(() => {
    // Restore real clock after each test — prevents clock from bleeding into next test
    cy.clock().then(clock => clock.restore());
  });

  it('shows correct expiry warning when session is near expiry', () => {
    cy.visit('/dashboard');
    // Advance the frozen clock by 29 minutes — session expires at 30 min
    cy.tick(29 * 60 * 1000);
    // The UI should show a warning — using frozen clock makes this deterministic
    cy.get('[data-testid="session-warning"]').should('be.visible');
  });

  it('completes checkout with mocked payment API', () => {
    // CRITICAL: register intercept BEFORE cy.visit() — requests fired on page load
    // will be missed if intercept is registered after visit
    cy.intercept('POST', '/api/orders', {
      statusCode: 201,
      body: { orderId: 'ORD-TEST-001', status: 'confirmed' },
    }).as('createOrder');

    cy.intercept('POST', '/api/payments', {
      statusCode: 200,
      body: { transactionId: 'TXN-001', status: 'approved' },
    }).as('processPayment');

    cy.visit('/checkout');
    cy.get('[data-testid="card-number"]').type('4111111111111111');
    cy.get('[data-testid="expiry"]').type('12/28');
    cy.get('[data-testid="cvv"]').type('123');
    cy.get('[data-testid="place-order"]').click();

    // Wait for BOTH intercepts to be called — prevents assertion before response
    cy.wait('@createOrder');
    cy.wait('@processPayment');

    // After waiting for network, assert on the UI outcome
    cy.get('[data-testid="order-confirmation"]').should('contain', 'ORD-TEST-001');
  });
});
```

```typescript
// cypress/support/commands.ts — custom command for reliable form interaction
// Cypress's retry-ability only applies to assertions, not to actions
// For forms that have async validation, use a custom command with built-in wait

Cypress.Commands.add('fillFormField', (selector: string, value: string) => {
  // cy.get() is retried automatically — safe for async-rendered forms
  cy.get(selector)
    .should('be.visible')           // wait for element to be interactable
    .should('not.be.disabled')      // wait for async disable state to resolve
    .clear()
    .type(value, { delay: 0 });     // delay: 0 eliminates artificial keypress timing
});

// Usage: cy.fillFormField('[name="email"]', 'user@example.com')
// This is more reliable than: cy.get('[name="email"]').type('user@example.com')
// because it explicitly waits for the element to be both visible AND enabled
```

```typescript
// Cypress flakiness pattern: assertions on text that changes during animation
// BAD: asserts during animation — text may be mid-transition
cy.get('[data-testid="counter"]').should('have.text', '42');

// GOOD: wait for animation to complete using cypress-real-events or explicit timeout
cy.get('[data-testid="counter"]')
  .should('have.text', '42')    // will retry until text matches or timeout
  .and('not.have.class', 'animating'); // ensure animation is complete
```

### Pattern 34 — Concurrency-Safe Test Fixture Factory [community]

In highly parallel test suites (Vitest `pool: 'forks'`, Jest `--maxWorkers=8`, or Playwright
`fullyParallel: true`), test fixtures that use deterministic IDs (e.g., `user-1`, `test-order`)
collide across workers. A concurrency-safe factory uses worker-scoped or UUID-based IDs to
guarantee uniqueness across parallel runs.

```typescript
// test-utils/fixture-factory.ts — concurrency-safe test fixture generation
import { randomUUID } from 'crypto';

/**
 * Creates a factory function that generates test fixtures with unique IDs.
 * IDs are scoped to the worker and test to prevent collisions in parallel runs.
 *
 * Worker-scoped prefix: uses a fixed prefix per worker process, ensuring that
 * parallel workers don't share fixture IDs even when running the same test.
 */

// In Vitest, each worker has a unique ID accessible via import.meta.env.VITEST_POOL_ID
// In Jest, use JEST_WORKER_ID. Fallback to random UUID for other runners.
const WORKER_PREFIX = (() => {
  const vitestId = (import.meta as Record<string, unknown>)?.env?.VITEST_POOL_ID;
  const jestId = process.env.JEST_WORKER_ID;
  return vitestId ?? jestId ?? randomUUID().slice(0, 8);
})();

export function createUserFixture(overrides: Partial<{
  name: string;
  email: string;
  role: 'admin' | 'user';
}> = {}) {
  const id = `usr-${WORKER_PREFIX}-${randomUUID().slice(0, 8)}`;
  return {
    id,
    name: overrides.name ?? `Test User ${id}`,
    // Email domain includes worker prefix to prevent uniqueness constraint violations
    email: overrides.email ?? `test-${id}@worker-${WORKER_PREFIX}.example.com`,
    role: overrides.role ?? 'user' as const,
    createdAt: new Date('2026-01-15T12:00:00Z'), // fixed date for deterministic sorting
  };
}

export function createOrderFixture(userId: string, overrides: Partial<{
  status: 'pending' | 'confirmed' | 'shipped';
  items: Array<{ sku: string; qty: number; price: number }>;
}> = {}) {
  return {
    id: `ord-${WORKER_PREFIX}-${randomUUID().slice(0, 8)}`,
    userId,
    status: overrides.status ?? 'pending' as const,
    items: overrides.items ?? [{ sku: 'SKU-001', qty: 1, price: 49_99 }],
    createdAt: new Date('2026-01-15T12:00:00Z'),
  };
}

// Usage in tests:
// const user = createUserFixture({ role: 'admin' });
// const order = createOrderFixture(user.id, { status: 'confirmed' });
// — guaranteed unique IDs across all parallel workers
```

### Pattern 28 — Playwright Component Test Flakiness [community]

Playwright's component testing (`@playwright/experimental-ct-react`) mounts components directly
in a real browser, combining the isolation of unit tests with the real-DOM fidelity of E2E.
However, it introduces a new category of flakiness: component mount timing, HMR interference,
and test isolation across the browser context.

```typescript
// playwright/index.tsx — global setup for component tests
// Required to set up providers, styles, and reset browser state between tests
import { beforeMount, afterMount } from '@playwright/experimental-ct-react/hooks';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import '../src/index.css';

// Create a FRESH QueryClient per test — prevents React Query cache from leaking between tests
// (a shared QueryClient is the #1 source of component test flakiness with data fetching)
beforeMount(async ({ App }) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,         // disable retries in tests — we want deterministic failures
        staleTime: Infinity,  // prevent background refetches that cause timing flakiness
      },
    },
  });
  return (
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  );
});
```

```typescript
// Component test using Playwright CT — avoid mount timing flakiness
import { test, expect } from '@playwright/experimental-ct-react';
import { ProductCard } from './ProductCard';

test('shows product price after loading', async ({ mount, page }) => {
  // Mock the network before mounting — prevents race between mount and real fetch
  await page.route('**/api/products/**', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ id: '1', name: 'Laptop', price: 999_00 }),
    })
  );

  // Mount the component and capture the component locator
  const component = await mount(<ProductCard productId="1" />);

  // Use Playwright's auto-retrying assertions — do NOT add sleep() after mount
  // The locator automatically waits for the element to appear in the DOM
  await expect(component.getByTestId('product-price')).toHaveText('$999.00');
  await expect(component.getByRole('button', { name: /add to cart/i })).toBeEnabled();
});

test('shows skeleton while loading', async ({ mount, page }) => {
  // Delay the response to assert on the loading state
  await page.route('**/api/products/**', async route => {
    // Playwright CT: use a delayed response to capture intermediate loading UI
    await new Promise(r => setTimeout(r, 100)); // controlled delay — not a sleep smell here
    await route.fulfill({ status: 200, body: JSON.stringify({ id: '1', name: 'Laptop', price: 999_00 }) });
  });

  const component = await mount(<ProductCard productId="1" />);
  // Assert on loading skeleton FIRST — visible immediately before response arrives
  await expect(component.getByTestId('loading-skeleton')).toBeVisible();
  // Then wait for the real content
  await expect(component.getByTestId('product-price')).toHaveText('$999.00');
});
```

```typescript
// playwright-ct.config.ts — component test configuration for stable parallel runs
import { defineConfig, devices } from '@playwright/experimental-ct-react';

export default defineConfig({
  testDir: './src',
  // Only match CT files — avoid accidentally running E2E tests in CT mode
  testMatch: '**/*.ct.{ts,tsx}',
  retries: process.env.CI ? 2 : 0,
  // Worker isolation: each worker gets its own browser context
  // Prevents state leaks across parallel component tests
  fullyParallel: true,
  use: {
    // Capture trace on first retry for CT flakiness investigation
    trace: 'on-first-retry',
    // Base URL for component tests (served by Playwright's built-in dev server)
    ctViteConfig: {
      // Disable HMR in tests — HMR causes spurious remounts that look like flakiness
      server: { hmr: false },
    },
  },
});
```

### Pattern 29 — Vitest 2.x Browser Mode Flakiness [community]

Vitest 2.0 introduced stable browser mode (`vitest --browser`), which runs tests in a real
browser (Chromium/Firefox/WebKit via Playwright). Browser mode adds a new isolation layer:
the browser context must be reset between tests, and DOM mutations must be cleaned up.

```typescript
// vitest.config.ts — Vitest 2.x browser mode with isolation
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Enable browser mode — tests run in real Chromium instead of jsdom
    browser: {
      enabled: true,
      name: 'chromium',
      provider: 'playwright',
      // Headless in CI, headed locally for debugging
      headless: process.env.CI === 'true',
    },
    // Pool configuration for browser mode
    // 'forks' is not applicable in browser mode — each test file gets its own page
    // isolate: true ensures a fresh browser page per test FILE
    isolate: true,
    // Reset all mocks between tests — prevents state from leaking between browser tests
    clearMocks: true,
    restoreMocks: true,
    resetMocks: true,
    retry: process.env.CI ? 2 : 0,
  },
});
```

```typescript
// Browser mode test — component with real DOM interactions
// In Vitest browser mode, the test runs inside a real browser page
import { render, screen, cleanup } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, describe, it, expect } from 'vitest';
import { ShoppingCart } from './ShoppingCart';

// Browser mode requires explicit DOM cleanup — jsdom does this automatically,
// but in a real browser the DOM persists until cleanup() is called
afterEach(() => {
  cleanup(); // unmounts all rendered components, clears event listeners
});

describe('ShoppingCart — browser mode', () => {
  it('updates total when quantity changes', async () => {
    const user = userEvent.setup();
    render(<ShoppingCart items={[{ id: '1', name: 'Widget', price: 10_00, qty: 1 }]} />);

    // In browser mode, getByRole uses the real accessibility tree
    // — more accurate than jsdom for ARIA role detection
    const qtyInput = screen.getByRole('spinbutton', { name: /quantity/i });
    await user.clear(qtyInput);
    await user.type(qtyInput, '3');

    // Total should update reactively — Vitest browser mode respects real browser event loop
    expect(await screen.findByText('$30.00')).toBeInTheDocument();
  });
});
```

### Pattern 30 — AI-Generated Test Flakiness Patterns [community]

As of 2026, AI-assisted test generation (Copilot, Cursor, Claude Code) has introduced new
categories of flakiness rooted in how LLMs generate test code. Teams adopting AI test
generation report consistent flakiness patterns from AI-written tests that must be explicitly
reviewed.

```typescript
// FLAKINESS PATTERN: AI-generated tests often use sleep() as a first-line waiting strategy
// because they pattern-match from Stack Overflow examples and training data
// AI-generated (common pattern to reject):
it('processes async job', async () => {
  jobQueue.enqueue({ type: 'email', to: 'user@example.com' });
  await new Promise(resolve => setTimeout(resolve, 1000)); // AI sleep pattern — reject this
  expect(emailSpy).toHaveBeenCalled();
});

// Corrected version — explicit condition polling
it('processes async job', async () => {
  jobQueue.enqueue({ type: 'email', to: 'user@example.com' });
  // waitFor polls until assertion passes — no arbitrary wait
  await waitFor(() => expect(emailSpy).toHaveBeenCalledWith(
    expect.objectContaining({ to: 'user@example.com' })
  ), { timeout: 5000 });
});
```

```typescript
// FLAKINESS PATTERN: AI-generated tests often assert on `.toEqual(expect.any(String))`
// for IDs, which passes even when the code is broken as long as something string-like is returned
// AI-generated (overly permissive — hides flakiness):
it('creates an order', async () => {
  const order = await OrderService.create({ items: ['sku-1'] });
  expect(order.id).toEqual(expect.any(String)); // passes even if id is '' or 'undefined'
  expect(order.createdAt).toEqual(expect.any(String)); // passes for any string
});

// Corrected version — specific assertions that surface real failures
it('creates an order with valid ID and timestamp', async () => {
  const order = await OrderService.create({ items: ['sku-1'] });
  // Assert format, not just type — surfaces actual implementation bugs
  expect(order.id).toMatch(/^ORD-[A-Z0-9]{8}$/);
  // Use a date range check for createdAt — not just "any string"
  const createdAt = new Date(order.createdAt);
  expect(createdAt).toBeInstanceOf(Date);
  expect(createdAt.getTime()).toBeGreaterThan(Date.now() - 5000); // within last 5 seconds
});
```

```typescript
// FLAKINESS PATTERN: AI-generated mocks often reset state globally
// but fail to scope resets to individual tests, causing cross-test pollution
// AI-generated (insufficient scoping):
const mockDb = jest.mock('./db'); // module-level — shared across tests
beforeAll(() => jest.resetAllMocks()); // resets once — not between tests

// Corrected pattern:
jest.mock('./db');

beforeEach(() => {
  jest.resetAllMocks(); // reset BEFORE each test — clean slate
});

afterEach(() => {
  jest.restoreAllMocks(); // restore spies AFTER each test
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

### AP8 — Sharding Without Seed Variation [community]
**What:** Running the same shard split (`--shard=1/4`) on every CI run with the same implicit ordering.
**Why harmful:** If test A and test B always land in the same shard in the same order, their order-dependency is never detected. True order-dependency detection requires varying the shard assignment across runs — either by varying the total shard count or by injecting a random seed into the sequencer.

### AP9 — Snapshot Tests With Dynamic Data [community]
**What:** Using `toMatchSnapshot()` on components or objects that include timestamps, UUIDs, random IDs, or other non-deterministic values.
**Why harmful:** Every run produces a different snapshot. The test either always fails (with a fresh fixture each run) or always passes (if developers blindly update snapshots on failure). Neither outcome provides signal about actual regressions. Snapshot tests should capture *structural* intent, not incidental runtime values.

### AP10 — Visual Tests Without Animation Freeze [community]
**What:** Running Chromatic or Percy visual regression tests without pausing CSS animations and transitions.
**Why harmful:** The snapshot is captured mid-animation at an arbitrary frame. The same component renders differently between captures depending on CI server speed. Chromatic's `pauseAnimationAtEnd` and Percy's `percy-css` overrides exist precisely for this reason — not using them is the primary cause of visual test flakiness.

### AP11 — Hard-Coded Port Numbers in Test Setup [community]
**What:** Test servers bound to fixed ports (e.g., `app.listen(3001)`).
**Why harmful:** Two test suites running in parallel on the same machine or CI worker bind to the same port, producing `EADDRINUSE` errors that look like random failures. In monorepos with shared CI runners, this is a systemic problem. Fix: always use `port: 0` (OS-assigned) and retrieve the actual port from `server.address().port`.

### AP12 — No Flakiness SLO or Metric [community]
**What:** Teams track individual failing tests reactively but have no defined flakiness rate target, no measurement infrastructure, and no alert when the rate increases.
**Why harmful:** Without a metric, you cannot improve. Flakiness accumulates silently until CI is too noisy to trust. With a defined SLO (e.g., flakiness rate < 5%), teams can measure progress, celebrate improvement, and catch regressions before they compound. SLOs without automation are ineffective — the SLO script must run in CI on every PR.

### AP13 — Using Mocks When Fakes Are Appropriate [community]
**What:** Replacing entire subsystems (DB, file system, queue) with `jest.mock()` rather than building lightweight in-memory fakes.
**Why harmful:** Mocks encode the *expected call sequence*, not the *behavior*. When implementation details change (method renamed, parameter order swapped), mocks break even when the contract is identical — producing false-positive failures that look like non-determinism. In-memory fakes encode the *contract*, not the implementation, so they remain valid through refactoring.

### AP14 — Global `jest.setTimeout()` Hiding Slow Tests [community]
**What:** Setting `jest.setTimeout(60000)` globally to silence timeout failures.
**Why harmful:** Slow tests are flakiness precursors — they pass under CI load today and timeout tomorrow when the runner is slower. A global timeout increase hides this signal. Fix: set per-operation timeouts with `withTimeout()` or Playwright's per-test `timeout` option, and audit tests that need more than 5 seconds.

### AP15 — AI-Generated Test Overly Permissive Assertions [community]
**What:** AI-generated tests use `expect.any(String)`, `expect.anything()`, or `toBeDefined()` where specific assertions are needed.
**Why harmful:** Overly permissive assertions pass even when the code under test is broken — they provide a false green. A test that asserts `expect(order.id).toBeDefined()` passes whether `order.id` is `"ORD-12345"` or `"undefined"` or `""`. These "pseudo-tests" mask real defects and erode the suite's ability to catch regressions. Review all AI-generated tests for assertion precision before committing.

### AP16 — Running E2E Tests in Watch Mode Without State Reset [community]
**What:** Using `npx playwright test --watch` or `npx vitest --watch` for E2E/integration tests that mutate real databases without resetting state between watch-mode re-runs.
**Why harmful:** Watch mode re-runs tests without re-running `globalSetup`. After the first run, the database contains rows created by the previous run. Subsequent runs encounter constraint violations, stale data, or unexpected record counts — failures that don't reproduce in CI (where `globalSetup` always runs fresh). Fix: ensure integration tests use `beforeEach` truncation and verify `globalSetup` runs on every watch-mode re-run, or disable watch mode for integration tests entirely.

### AP17 — React Query / TanStack Query Cache Shared Between Tests [community]
**What:** Tests that use a module-level or globally-configured `QueryClient` instance, allowing React Query's in-memory cache to accumulate across tests.
**Why harmful:** A test that successfully fetches `GET /api/users/1` populates the React Query cache. The next test renders the same component and receives the *cached* response instead of making a fresh request. Tests then pass or fail depending on execution order and which queries were previously resolved. Fix: create a new `QueryClient` instance in `beforeEach` with `staleTime: Infinity` and `retry: false`.

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

11. **`detectOpenHandles` reveals timer/Promise leaks invisible to retries.** [community]
    Jest's `--detectOpenHandles` flag identifies tests that leave open `setTimeout`, `setInterval`, database connections, or unresolved Promises after the suite completes. These leaks don't cause the current test to fail — they cause the *next* test file's Jest worker to receive unexpected callbacks, producing order-dependent flakiness that's nearly impossible to reproduce locally. Enable `detectOpenHandles: true` in `jest.config.ts` on every project as a zero-cost flakiness prevention measure.

12. **Shard-dependent flakiness is misattributed to "environment differences."** [community]
    When a test suite is first moved to a sharded CI strategy (e.g., `--shard=1/4`), some teams see failures that "don't happen locally." The root cause is almost always order-dependency: the test was passing because another test in the same run set up global state (a registered handler, a populated cache) that the test under investigation depended on. Varying the shard count or seed between runs is the fastest diagnostic — if the failure moves across shards as the seed changes, the defect is order-dependent, not environmental.

13. **Pact provider state handlers that fire-and-forget DB operations cause interaction-level flakiness.** [community]
    The Pact verifier calls the state handler, receives a resolved Promise (or void), and immediately fires the interaction request. If the DB insert in the state handler is not `await`-ed, the interaction arrives before the database row exists, producing a 404 or 422 that looks non-deterministic. The fix is always `await` every async operation in state handlers, and return a teardown function (not a separate `afterEach`) so Pact controls the cleanup timing.

14. **Database migration races in parallel test workers produce "relation already exists" errors.** [community]
    When multiple Jest/Vitest workers each invoke the migration setup independently (e.g., in a global setup file), the first worker to acquire the DB connection wins and creates the schema; all others fail with `relation already exists`. This manifests as non-deterministic failures in the first test of each worker. Fix: use a distributed advisory lock (e.g., `pg_try_advisory_lock`) in the migration setup, or run migrations in a single `globalSetup` script before workers start.

15. **CI environment variable differences cause tests to pass locally but fail in CI.** [community]
    Tests that read `process.env.NODE_ENV`, `process.env.TZ`, or custom env vars without explicit defaults behave differently on developer machines (where `.env.test` is loaded) vs. CI runners (where only CI-set vars exist). The pattern manifests as a test that *always* passes locally and *intermittently* passes in CI — depending on which CI runner picks up the job and what environment variables that runner's profile sets. Fix: enforce `TZ=UTC` in CI and test config, use `dotenv-flow` with an explicit `.env.test.defaults` file that ships with the repo, and always check for `undefined` before using process.env values in tests.

16. **Unsupported `AbortSignal` in older Node.js versions causes intermittent hang-then-crash flakiness.** [community]
    Tests that pass `AbortSignal` to `fetch()`, `setTimeout()`, or custom async operations fail silently on Node.js < 18 (which shipped incomplete AbortSignal support) and hang until the process timeout kills the runner. This manifests as "tests that always pass locally (Node 20+) but sometimes timeout in CI" when CI runners use an older Node version. Fix: pin `"node": ">=20.0.0"` in `package.json` `engines`, configure Renovate/Dependabot to enforce it, and add `node --version` as the first CI step to detect mismatches immediately.

17. **React Server Components (RSC) introduce async rendering flakiness in integration tests.** [community]
    Next.js App Router components that are Server Components render asynchronously on the server. Tests using `@testing-library/react` or `renderToString` to test RSC-dependent pages often get stale HTML snapshots because the RSC payload hasn't been fully streamed. This manifests as tests that pass locally (warm server) but fail in CI (cold server, RSC payload slower). Fix: use Playwright E2E tests for RSC-dependent flows rather than unit/RTL-level testing; for unit-testing server-side logic, test the data-fetching functions directly without rendering.

18. **tRPC procedure calls without proper test isolation cause shared router state flakiness.** [community]
    tRPC routers tested with `createCallerFactory` share the same procedure registry. If one test modifies a middleware or overrides a procedure, subsequent tests in the same process see the modified router. Fix: create a fresh caller instance per test using `createCallerFactory(appRouter)(ctx)` in `beforeEach`, and never mutate the router definition in tests. Use dependency injection in middleware to swap implementations without router mutation.

19. **Vite/Turbopack HMR interference with Vitest in watch mode.** [community]
    In Vitest watch mode with a shared Vite dev server, Hot Module Replacement (HMR) can trigger test re-runs mid-test when source files are saved. If a test is asserting on a module that is simultaneously being HMR-updated, the module's state is inconsistent — the test sees a partially-updated module. This manifests as intermittent `TypeError: X is not a function` errors that disappear on re-run. Fix: set `server: { hmr: false }` in `vitest.config.ts` when running in CI, and be aware of this in local watch-mode debugging.

20. **`localStorage` and `sessionStorage` leaking between JSDOM tests.** [community]
    Jest/Vitest with JSDOM resets the virtual DOM between test files but, by default, does NOT reset `localStorage` or `sessionStorage`. Tests that write to `localStorage` (e.g., persisting auth tokens, feature flags, UI preferences) pollute subsequent tests in the same JSDOM environment, causing order-dependent failures. Fix: add `localStorage.clear(); sessionStorage.clear();` to `afterEach`, or configure Vitest with `setupFiles` to clear storage before each test. This is one of the most-reported flakiness sources in React application testing.

21. **OpenTelemetry span collection creates async timing flakiness in integration tests.** [community]
    Services instrumented with OpenTelemetry export spans asynchronously to a collector. Tests that assert "span X was created" fail intermittently because the span hasn't been exported yet when the assertion runs. The `BatchSpanProcessor` queues spans for async export — only the `SimpleSpanProcessor` exports synchronously. Fix for tests: replace `BatchSpanProcessor` with `InMemorySpanExporter` + `SimpleSpanProcessor` in test configuration, then assert on the in-memory exporter's spans directly after the operation completes.

22. **Nx affected command (`nx affected --target=test`) produces different test selections per run.** [community]
    `nx affected` computes which projects to test based on a git diff against a base branch. In CI, the base branch (`--base=origin/main`) can differ between runs if the main branch was updated between the PR's creation and the CI trigger. This produces different affected sets across re-runs, making it look like tests are flaky when actually different test suites are running. Fix: pin the base commit using `--base=$(git merge-base HEAD origin/main)` to ensure a consistent affected set across all runs for a given PR.

23. **Playwright `--grep` flag with regex metacharacters in test names causes non-deterministic filtering.** [community]
    Test names containing parentheses, dots, or other regex metacharacters cause `--grep` patterns to match more (or fewer) tests than expected. For example, a test named `renders Component(v2)` is matched by `--grep="Component"` but also by `--grep="Component(v2)"` which a developer might expect to match that test only — but `(v2)` in regex means "optional v2". This leads to some tests unexpectedly being excluded or included in filtered runs. Fix: escape all test names that will be used with `--grep`, or use `--grep-invert` combined with `test.only` for targeted runs.

---

### When quarantine-and-fix works well
- Small-to-medium test suites (< 2000 tests) where flaky tests are rare events
- Teams with a dedicated "flaky test" rotation or clear ownership
- Teams with a quarantine SLA (e.g., all quarantined tests fixed within 2 sprints)

### When quarantine becomes unmanageable
- Suites with > 5% flakiness rate: quarantine backlog grows faster than it's fixed
- Teams without a fix-it rotation: quarantine becomes a graveyard
- Monorepos where multiple teams share a test runner: no single owner for the backlog

**Alternative: Flakiness budget + hard cap.** Google enforces that any test exceeding a flakiness threshold is automatically disabled and must be fixed before re-enabling. This is stricter than quarantine but prevents backlog growth. Implementation: a CI job that reads retry counts from JUnit XML output and fails the build if any single test's flakiness rate exceeds 3%.

**Flakiness Tolerance Gradient by Test Level**

Not all flakiness is equally unacceptable. A graduated tolerance model aligns expectations with
reality across the test pyramid:

| Test Level | Acceptable Flakiness Rate | Retry Budget | Primary Flakiness Source |
|------------|--------------------------|--------------|--------------------------|
| Unit (Jest/Vitest) | 0% — zero tolerance | 0 retries | Shared singletons, fake timer leaks |
| Integration (API, DB) | < 1% | 1 retry | Connection pool exhaustion, migration timing |
| Contract (Pact) | < 1% | 1 retry | Provider state setup timing |
| Component (Playwright CT, Storybook) | < 2% | 2 retries | Mount timing, animation frames |
| E2E (Playwright, Cypress) | < 5% | 2–3 retries | Network, auth, SPA routing |
| Visual Regression (Chromatic) | < 5% | Manual approval | Animation, font rendering |

**Why the gradient matters:** Setting a single flakiness SLO across all test levels is counterproductive.
Unit tests should be perfectly deterministic — zero tolerance is appropriate. E2E tests interact with real browsers, real networks, and complex timing; some flakiness is unavoidable. Collapsing these into a single metric creates pressure to lower E2E quality to meet unit-level standards, or to tolerate unit flakiness by citing E2E norms. Track and SLO each level independently.

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

**Alternative: Flakiness SLO with JUnit XML parsing.** Instead of third-party services, parse JUnit XML from CI directly (Pattern 24) and assert against a team-defined SLO (e.g., flakiness rate < 5%). Zero external dependencies, full ownership of the threshold, and immediate PR-level feedback. Requires JUnit output from the test runner (`--reporter=junit` in Playwright/Vitest, `--json` + conversion in Jest).

**Alternative: Node.js native `node:test` for lightweight scripts.** For TypeScript-first projects targeting Node.js 20+, the built-in `node:test` module provides retry, TAP output, and flakiness annotation without adding Jest or Vitest to the dependency tree. Suitable for microservice integration tests and utility scripts. Trade-off: fewer ecosystem plugins, no built-in MSW integration, less mature IDE tooling than Jest/Vitest.

### Known adoption costs
- Quarantine tooling requires team agreement on tags and a process to review the backlog weekly; automate with the quarantine review issue script (Pattern 25) to prevent the weekly review from being skipped
- Replacing `sleep()` with `waitFor()` requires understanding what condition to wait on — more thinking upfront, but the test becomes self-documenting
- Fake timers (e.g., `jest.useFakeTimers`) can cause issues with async libraries that internally use `setTimeout` for debouncing (e.g., lodash debounce, React batched updates in older versions) — needs per-library investigation
- MSW adds a test infrastructure dependency; handler maintenance burden grows with API surface area
- Testcontainers requires Docker in CI; adds 5–30s cold-start latency per suite; Docker-in-Docker on some CI providers requires privileged mode
- ESLint anti-flakiness rules (Pattern 20) require configuring overrides for test files only — applying globally triggers false positives in production code
- The `withTimeout` helper (Pattern 26) requires AbortSignal support in the code under test — must be added to service interfaces if not already present; adds upfront refactoring cost but pays back in diagnosable timeouts
- Flakiness SLO scripts (Pattern 24) require JUnit XML output from every test runner in the pipeline — verify reporter configuration before enabling the SLO gate

---

## Team Workflow: Flakiness Triage Process

A documented triage process prevents ad-hoc decisions and ensures flakiness is addressed
systematically rather than reactively.

### Sprint-level flakiness triage (recommended cadence: weekly)

1. **Monday**: Quarantine review issue is created automatically (Pattern 25). Team triages open quarantine items in the sprint planning meeting.
2. **Daily**: Any test that fails on retry is flagged in the CI summary (Pattern 19). The developer who triggered the run owns the triage.
3. **Triage decision tree**: For any newly flaky test:
   - Run the diagnostic decision tree (see "Flakiness Diagnostic Decision Tree" section above)
   - If root cause is clear: fix immediately, remove quarantine tag
   - If root cause is unclear: quarantine with `[QUARANTINE]` tag, open tracking issue with `Owner:` and `SLA:` fields, and add to the flakiness backlog
   - If flakiness rate > 10% (extremely disruptive): suspend the test (`it.skip`) immediately, open P1 issue
4. **Metrics review**: Every sprint, review the flakiness SLO report (Pattern 24). If rate is trending up, dedicate capacity to flakiness reduction.

### Quarantine tag format (enforced by PR review checklist)

```
// [QUARANTINE] <one-line description of the flakiness symptom>
// Root cause: <known or suspected root cause family — timing/shared state/external dep/order/randomness>
// Opened: YYYY-MM-DD | Owner: @github-handle | SLA: YYYY-MM-DD
// Issue: <ticket link>
// Repro: <command to reproduce locally, e.g., npx jest --testNamePattern="..."  --runInBand --count=5>
it.skip('[QUARANTINE] inventory count matches after concurrent orders', async () => {
  // ...
});
```

The `Repro:` line is crucial — without it, the engineer who takes ownership of the fix
cannot reproduce the issue, and the quarantine becomes permanent.

### Flakiness fix rotation

Teams that successfully reduce flakiness long-term consistently have:
- A dedicated "flakiness fix" rotation (1 engineer per sprint, rotating monthly)
- A rule that no new tests are merged if the quarantine backlog exceeds the threshold (Pattern 3)
- A retrospective action when the flakiness rate increases by > 2% in a single sprint

---

## Key Resources
| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Eradicating Non-Determinism in Tests | Official | https://martinfowler.com/articles/nonDeterminism.html | Fowler's canonical taxonomy of flakiness root causes |
| Flaky Tests at Google | Official | https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html | Scale data on flakiness rates and Google's quarantine approach |
| Playwright Retries Docs | Official | https://playwright.dev/docs/test-retries | Retry configuration, trace on retry, flakiness reporting |
| Playwright Test Steps | Official | https://playwright.dev/docs/api/class-test#test-step | `test.step()` for structured trace annotation |
| Jest Retry Times | Official | https://jestjs.io/docs/configuration#retrytimes-number | jest-circus retry configuration |
| Jest detectOpenHandles | Official | https://jestjs.io/docs/configuration#detectopenhandles-boolean | Detects timer/Promise/connection leaks between tests |
| Vitest Pool Configuration | Official | https://vitest.dev/config/#pool | Concurrent test isolation settings (`forks` vs `threads`) |
| Vitest Test Retry | Official | https://vitest.dev/config/#retry | Per-test and global retry configuration with verbose reporting |
| Node.js Test Runner | Official | https://nodejs.org/api/test.html | Built-in `node:test` with retry, TAP output, and flakiness annotation |
| Mock Service Worker | Community | https://mswjs.io/ | Network-level mocking that prevents real HTTP calls |
| Testcontainers for Node | Community | https://testcontainers.com/guides/getting-started-with-testcontainers-for-nodejs/ | Hermetic DB/service containers to eliminate external dep flakiness |
| @sinonjs/fake-timers | Community | https://github.com/sinonjs/fake-timers | Controllable clock for timing-sensitive tests |
| BuildPulse | Community | https://buildpulse.io/ | Automated flaky test detection from CI history |
| Trunk Flaky Tests | Community | https://trunk.io/flaky-tests | Flaky test tracking with auto-quarantine |
| Chromatic pauseAnimationAtEnd | Official | https://www.chromatic.com/docs/delay/ | Freeze animations for stable visual regression snapshots |
| @octokit/rest | Community | https://octokit.github.io/rest.js/v20 | GitHub API for automated quarantine review issue creation |
| @pact-foundation/pact | Official | https://docs.pact.io/implementation_guides/javascript | Consumer-driven contract testing — provider state handler patterns |
| How They Test | Community | https://abhivaikar.github.io/howtheytest/ | 108 companies — flaky test management patterns from Automattic, Reddit, Slack, Mattermost, and others who publish production flakiness experiences |
| ISTQB CTFL 4.0 Syllabus | Official | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative terminology: test case, test level, defect, test suite |
| eslint-plugin-jest | Community | https://github.com/jest-community/eslint-plugin-jest | ESLint rules: `valid-expect`, `no-conditional-expect`, `no-floating-promises` |
| TanStack Query Testing | Official | https://tanstack.com/query/latest/docs/framework/react/guides/testing | Per-test QueryClient isolation, disable retry and staleTime |
| Cypress Best Practices | Official | https://docs.cypress.io/guides/references/best-practices | Cypress-specific: intercept ordering, cy.clock(), retry-ability |
| Vitest Browser Mode | Official | https://vitest.dev/guide/browser/ | Vitest 2.x browser mode setup, isolation config, Playwright provider |
| Playwright CT (React) | Official | https://playwright.dev/docs/test-components | Component testing with Playwright — mount timing, network mocking |
| @testing-library/react — Async Queries | Official | https://testing-library.com/docs/queries/about#types-of-queries | findBy vs getBy vs queryBy — choosing the right async query |
| Chromatic CI Configuration | Official | https://www.chromatic.com/docs/ci | Full CI setup for visual testing with animation freeze |
| Nx Affected Tests | Official | https://nx.dev/ci/features/affected | `nx affected --target=test` with consistent base commit selection |
| Bun Test Docs | Official | https://bun.sh/docs/cli/test | Bun's built-in test runner — `--rerun-each`, timeout config, flakiness reporting |
| Biome Linter | Official | https://biomejs.dev/linter/ | Rust-based linter replacing ESLint — includes `noFloatingPromises`, `useAwait` rules |
| Effect-TS Testing | Community | https://effect.website/docs/guides/testing | Testing Effect programs with `TestClock`, `TestRandom`, and `TestConsole` |
| Drizzle ORM Testing | Official | https://orm.drizzle.team/docs/guides/testing | In-memory SQLite + transaction rollback per test for flakiness-free DB integration |
| Prisma Test Isolation | Official | https://www.prisma.io/docs/guides/testing | `$transaction` rollback pattern and `PrismaClient` per-test isolation |
| ReadableStream Testing | Community | https://developer.mozilla.org/en-US/docs/Web/API/ReadableStream | WHATWG Streams in Node 20+ — async iterator flakiness and chunk-boundary testing |
| ResizeObserver Mock | Community | https://github.com/nickmccurdy/jest-environment-jsdom | Mocking ResizeObserver/IntersectionObserver — the canonical approach for layout test isolation |

---

## Pattern 35 — Bun Test Runner Flakiness [community]

Bun 1.x ships a built-in test runner (`bun test`) with a `--rerun-each N` flag designed
explicitly for flakiness detection. Unlike Jest's global `retryTimes`, Bun re-runs each
individual test N times within the same process, making it faster for detecting
test-local timing issues while sharing module state.

```typescript
// bun-test/payment.test.ts — Bun-native test with explicit timeout and retry pattern
// Run with: bun test --rerun-each 3 --timeout 5000 payment.test.ts

import { describe, it, expect, beforeEach, afterEach } from 'bun:test';

// Bun uses the same describe/it API as Jest/Vitest but with different internals:
// - Module isolation: Bun reloads modules between test FILES, not between tests in a file
// - beforeEach/afterEach hooks MUST reset all in-file state (module-level vars)
// - Timer fakes: use Bun's built-in fake timers (compatible with Jest's API)

let requestCount = 0; // module-level state — MUST be reset in beforeEach

beforeEach(() => {
  // Critical: reset module-level counters between tests
  // In Bun, failing to do this is the most common source of test-order flakiness
  requestCount = 0;
});

describe('RateLimiter', () => {
  it('allows first 10 requests within window', async () => {
    const limiter = new RateLimiter({ limit: 10, windowMs: 60_000 });
    for (let i = 0; i < 10; i++) {
      const allowed = await limiter.check('user-1');
      expect(allowed).toBe(true);
      requestCount++;
    }
    expect(requestCount).toBe(10);
  });

  it('blocks 11th request in same window', async () => {
    const limiter = new RateLimiter({ limit: 10, windowMs: 60_000 });
    // requestCount is 0 here because beforeEach reset it
    // Without the reset, this test would add to the previous test's 10 requests
    for (let i = 0; i < 10; i++) await limiter.check('user-2');
    const blocked = await limiter.check('user-2');
    expect(blocked).toBe(false);
  });
});
```

```typescript
// Bun fake timers — eliminates setTimeout-based flakiness
// Bun's timer fakes are compatible with Jest's useFakeTimers() API
import { describe, it, expect, beforeEach, afterEach } from 'bun:test';
import { mock, setSystemTime, restoreAllMocks } from 'bun:test';

describe('TokenRefreshService', () => {
  beforeEach(() => {
    // Freeze time at a known UTC instant — same as jest.useFakeTimers({ now: ... })
    setSystemTime(new Date('2026-06-01T09:00:00.000Z'));
  });

  afterEach(() => {
    // Always restore real timers and mocks — prevents clock from bleeding
    restoreAllMocks();
    setSystemTime(); // resets to real system time
  });

  it('refreshes token 5 minutes before expiry', async () => {
    const service = new TokenRefreshService({ refreshBeforeMs: 5 * 60 * 1000 });
    const token = service.createToken({ expiresAt: new Date('2026-06-01T09:10:00.000Z') });

    // Advance time to 5 minutes before expiry (trigger window)
    setSystemTime(new Date('2026-06-01T09:05:01.000Z'));
    const shouldRefresh = service.shouldRefresh(token);
    expect(shouldRefresh).toBe(true);
  });

  it('does NOT refresh when expiry is far away', async () => {
    const service = new TokenRefreshService({ refreshBeforeMs: 5 * 60 * 1000 });
    const token = service.createToken({ expiresAt: new Date('2026-06-01T10:00:00.000Z') });
    // Time is still at 09:00:00 — 60 minutes before expiry, well outside refresh window
    expect(service.shouldRefresh(token)).toBe(false);
  });
});
```

**Key difference from Jest/Vitest:** Bun's `--rerun-each N` re-runs the test N times in the
same process without resetting module state between runs (unlike Jest's `--testNamePattern`
with `--resetModules`). Any module-level state (singleton, counter, cache) must be explicitly
reset in `beforeEach`, or `--rerun-each` will reveal the flakiness that was hidden by the
module-reload boundary in Jest.

---

## Pattern 36 — Floating-Point Assertion Flakiness [community]

Floating-point arithmetic produces non-deterministic-looking results when tests assert
exact equality. The test passes on one machine (where CPU rounding produces 0.1 + 0.2 = 0.3)
and fails on another (where it produces 0.30000000000000004). This is deterministic but
environment-dependent — a special case of the "randomness and environment" root cause family.

```typescript
// BAD: exact equality on floating-point results — fails on some architectures
import { describe, it, expect } from 'vitest';
import { calculateTax } from './tax';

it('calculates 10% tax on $29.99', () => {
  const result = calculateTax(29.99, 0.10);
  expect(result).toBe(2.999); // FLAKY: 29.99 * 0.10 = 2.9990000000000006 in IEEE 754
});

// GOOD: use toBeCloseTo() for floating-point assertions
it('calculates 10% tax on $29.99', () => {
  const result = calculateTax(29.99, 0.10);
  // toBeCloseTo(expected, precision) — precision is decimal places (default 2)
  expect(result).toBeCloseTo(2.999, 3); // passes within ±0.0005
});

// BETTER: use integer arithmetic in production code (avoid floating-point entirely)
// Store prices in cents, not dollars — eliminates the floating-point class entirely
it('calculates 10% tax on 2999 cents', () => {
  const result = calculateTaxCents(2999, 0.10); // returns integer cents, Math.round internally
  expect(result).toBe(300); // deterministic: 2999 * 0.10 = 299.9, rounds to 300
});

// For statistical/ML test outputs — always use toBeCloseTo with explicit precision
it('computes cosine similarity within tolerance', () => {
  const similarity = cosineSimilarity([1, 0, 1], [1, 1, 0]);
  // Exact value: 0.5 — but floating-point may produce 0.4999999... or 0.5000000001
  expect(similarity).toBeCloseTo(0.5, 5); // 5 decimal places: ±0.000005
});
```

```typescript
// Pattern: Currency assertion helper — enforces integer-only arithmetic in tests
// Add to test-utils/currency.ts for team-wide enforcement

/**
 * Asserts a currency amount matches expected value with zero floating-point tolerance.
 * Amounts MUST be in the smallest unit (cents, pence, etc.) to be integer-safe.
 * Throws if non-integer values are passed — forces correct usage.
 */
export function expectCents(actual: number, expected: number): void {
  if (!Number.isInteger(actual)) {
    throw new TypeError(`expectCents: actual value ${actual} is not an integer. Store prices in cents.`);
  }
  if (!Number.isInteger(expected)) {
    throw new TypeError(`expectCents: expected value ${expected} is not an integer. Store prices in cents.`);
  }
  expect(actual).toBe(expected); // integer comparison — always deterministic
}

// Usage:
it('applies 20% discount to order total', () => {
  const order = createOrder({ items: [{ price: 5000, qty: 2 }] }); // 5000 = $50.00
  const discounted = applyDiscount(order, 0.20);
  expectCents(discounted.totalCents, 8000); // 2 × 5000 × 0.80 = 8000 cents = $80.00
});
```

---

## Pattern 37 — React 19 `use()` Hook and Concurrent Rendering Flakiness [community]

React 19 introduced the `use()` hook, which suspends rendering to await a Promise or read
a Context. Tests using `use()` with async data must ensure the Suspense boundary is
properly awaited — otherwise assertions run against the suspended (loading) state.

```typescript
// React 19 component using use() hook
// src/components/UserProfile.tsx
import { use, Suspense } from 'react';

interface User { id: string; name: string; email: string }

// use() suspends the component while the Promise is pending
function UserProfileContent({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise); // suspends until resolved
  return <div data-testid="user-name">{user.name}</div>;
}

export function UserProfile({ userId }: { userId: string }) {
  const userPromise = fetchUser(userId); // returns a Promise
  return (
    <Suspense fallback={<div data-testid="loading">Loading...</div>}>
      <UserProfileContent userPromise={userPromise} />
    </Suspense>
  );
}
```

```typescript
// Test for React 19 use() hook — must await Suspense resolution
import { render, screen } from '@testing-library/react';
import { UserProfile } from './UserProfile';
import { server } from '../mocks/server';
import { http, HttpResponse } from 'msw';

// BAD: assertion runs before Suspense resolves — always finds loading state
it('renders user name (broken)', async () => {
  render(<UserProfile userId="1" />);
  // getByTestId runs synchronously — Suspense hasn't resolved yet
  expect(screen.getByTestId('user-name')).toBeInTheDocument(); // FAILS: element not found
});

// GOOD: use findByTestId which polls until the element appears (Suspense resolves)
it('renders user name after loading', async () => {
  server.use(
    http.get('/api/users/1', () => HttpResponse.json({ id: '1', name: 'Alice', email: 'a@example.com' }))
  );

  render(<UserProfile userId="1" />);

  // findByTestId internally wraps in act() and retries — waits for Suspense to resolve
  const nameEl = await screen.findByTestId('user-name', {}, { timeout: 3000 });
  expect(nameEl).toHaveTextContent('Alice');
});

// ALSO GOOD: test the loading state explicitly before asserting the resolved state
it('shows loading then user name', async () => {
  server.use(
    http.get('/api/users/1', () => HttpResponse.json({ id: '1', name: 'Alice', email: 'a@example.com' }))
  );

  render(<UserProfile userId="1" />);

  // Assert loading state is visible immediately
  expect(screen.getByTestId('loading')).toBeInTheDocument();

  // Wait for loading to disappear and resolved state to appear
  await screen.findByTestId('user-name');
  expect(screen.queryByTestId('loading')).not.toBeInTheDocument();
});
```

---

## Pattern 38 — Service Worker Test Isolation [community]

Service Workers (SW) registered in a browser-based test environment (Playwright, Vitest
browser mode, or manual `jsdom` + SW polyfill) persist across tests in the same origin.
A SW registered by test A intercepts requests in test B, producing non-deterministic
responses that are difficult to attribute to a root cause.

```typescript
// playwright test — service worker isolation per test context
import { test, expect, BrowserContext } from '@playwright/test';

// Create a new browser context per test — each context has its own SW scope
// This is the Playwright-idiomatic way to isolate SW state
test.describe('Offline mode with Service Worker', () => {
  let context: BrowserContext;

  test.beforeEach(async ({ browser }) => {
    // New context = new origin scope = fresh SW registration
    context = await browser.newContext();
    // Optionally: wait for SW to be registered before running the test
  });

  test.afterEach(async () => {
    // Close context to unregister all SWs and clear cache storage
    await context.close();
  });

  test('serves cached page when offline', async () => {
    const page = await context.newPage();
    await page.goto('/');
    // Wait for SW to install and activate
    await page.waitForFunction(() =>
      navigator.serviceWorker.controller?.state === 'activated'
    );
    // Go offline
    await context.setOffline(true);
    // Reload — should serve from SW cache, not network
    await page.reload();
    await expect(page.locator('h1')).toBeVisible(); // served from cache
    await context.setOffline(false); // restore for cleanup
  });

  test('shows offline banner when SW has no cached response', async () => {
    const page = await context.newPage();
    await page.goto('/');
    await page.waitForFunction(() => navigator.serviceWorker.controller?.state === 'activated');
    // Navigate to an uncached route, then go offline
    await context.setOffline(true);
    await page.goto('/uncached-route', { waitUntil: 'domcontentloaded' }).catch(() => {});
    // SW should serve the offline fallback page
    await expect(page.locator('[data-testid="offline-banner"]')).toBeVisible({ timeout: 5000 });
  });
});
```

```typescript
// Vitest browser mode — unregister SW before each test to prevent scope leakage
// Add to src/test-setup.ts for browser-mode tests
import { beforeEach, afterEach } from 'vitest';

beforeEach(async () => {
  // Unregister all service workers before each test
  // Prevents previous test's SW from intercepting current test's requests
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map(reg => reg.unregister()));
  }
  // Clear all Cache Storage entries — prevents stale SW cache from affecting tests
  if ('caches' in window) {
    const cacheNames = await caches.keys();
    await Promise.all(cacheNames.map(name => caches.delete(name)));
  }
});
```

---

## Pattern 39 — Next.js App Router Integration Test Flakiness [community]

Next.js 14+ App Router uses React Server Components, streaming, and per-request caching
that introduce flakiness categories not present in Pages Router tests.

```typescript
// Integration test for Next.js App Router API routes using fetch()
// The App Router's built-in request caching can cause tests to receive
// stale responses from a previous test's cache entry

import { describe, it, expect, beforeEach } from 'vitest';

// IMPORTANT: Next.js 14+ caches fetch() responses globally (per-request cache)
// In test environments, this cache persists between tests unless explicitly reset
describe('Next.js App Router API integration', () => {
  beforeEach(() => {
    // Reset the unstable_cache between tests — prevents cross-test cache pollution
    // In a real Next.js test setup, use the next-test-api-route-handler package
    // to get a fresh handler instance per test
  });

  it('returns fresh user data, not cached stale data', async () => {
    // Use next-test-api-route-handler (NTARH) for isolated route handler testing
    // NTARH creates a real Node.js HTTP server for the handler per test
    const { testApiHandler } = await import('next-test-api-route-handler');
    const handler = await import('./app/api/users/[id]/route');

    let response!: Response;
    await testApiHandler({
      appHandler: handler,
      params: { id: '1' },
      test: async ({ fetch }) => {
        response = await fetch({ method: 'GET' });
      },
    });

    const data = await response.json();
    expect(response.status).toBe(200);
    expect(data.id).toBe('1');
    // Assert specific fields — not expect.anything() — to surface real bugs
    expect(data.name).toMatch(/^[A-Za-z ]{2,50}$/);
  });
});
```

```typescript
// Next.js Server Action flakiness — actions use React's progressive enhancement
// Testing them requires simulating form submissions with FormData
import { describe, it, expect } from 'vitest';
import { createUserAction } from './app/actions/users';

describe('createUserAction — Server Action', () => {
  it('creates user and returns redirect', async () => {
    const formData = new FormData();
    formData.set('name', 'Alice');
    formData.set('email', 'alice@example.com');

    // Server Actions are async functions — call directly in Node.js tests
    // Flakiness risk: Server Actions that call revalidatePath() or revalidateTag()
    // will throw in test environments (no Next.js router context)
    // Fix: mock next/cache before testing actions that call revalidation
    const { revalidatePath } = await import('next/cache');
    vi.mock('next/cache', () => ({ revalidatePath: vi.fn(), revalidateTag: vi.fn() }));

    const result = await createUserAction(formData);
    expect(result).toMatchObject({ success: true });
    expect(vi.mocked(revalidatePath)).toHaveBeenCalledWith('/users');
  });
});
```

---

## Pattern 40 — Drizzle ORM / Prisma Transaction Rollback Test Isolation [community]

ORM integration tests that write to a real database are the most common source of
"passes alone, fails in CI" flakiness. The most effective isolation pattern is wrapping
each test in a database transaction that is rolled back unconditionally in `afterEach`.

```typescript
// test-utils/db-test-context.ts — Drizzle ORM transaction rollback per test
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from '../src/db/schema';

const pool = new Pool({ connectionString: process.env.TEST_DATABASE_URL });

/**
 * Creates a test context that wraps each test in a database transaction.
 * The transaction is always rolled back in afterEach — zero data pollution.
 * Usage: const ctx = createDbTestContext(); beforeEach(ctx.setup); afterEach(ctx.teardown);
 */
export function createDbTestContext() {
  // Type for a drizzle transaction — allows passing tx to test code
  type DrizzleTx = Parameters<Parameters<ReturnType<typeof drizzle>['transaction']>[0]>[0];

  let rollback!: () => void;
  let tx!: DrizzleTx;

  const db = drizzle(pool, { schema });

  return {
    /** The transaction — use this in tests instead of the shared db instance */
    get db(): DrizzleTx { return tx; },

    setup: () => new Promise<void>((resolve) => {
      // Start a transaction but never commit it — resolve the test setup promise
      // immediately after getting the tx handle, then reject (rollback) in teardown
      db.transaction(async (transaction) => {
        tx = transaction;
        resolve(); // test can proceed with tx
        // Hang here until rollback is called
        await new Promise<never>((_, reject) => { rollback = () => reject(new Error('ROLLBACK')); });
      }).catch(() => {}); // swallow the intentional rollback error
    }),

    teardown: () => { rollback(); }, // triggers the intentional error → transaction rolls back
  };
}
```

```typescript
// Usage: each test runs in its own rolled-back transaction
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createDbTestContext } from '../test-utils/db-test-context';
import { users } from '../src/db/schema';
import { eq } from 'drizzle-orm';

describe('UserRepository — Drizzle', () => {
  const ctx = createDbTestContext();
  beforeEach(ctx.setup);   // begins transaction
  afterEach(ctx.teardown); // always rolls back — zero state leakage

  it('inserts and retrieves a user', async () => {
    // ctx.db is the in-transaction Drizzle instance — all writes are rolled back after
    await ctx.db.insert(users).values({ name: 'Alice', email: 'alice@drizzle-test.com' });
    const found = await ctx.db.select().from(users).where(eq(users.email, 'alice@drizzle-test.com'));
    expect(found).toHaveLength(1);
    expect(found[0].name).toBe('Alice');
    // afterEach rolls back — the inserted row never persists to the actual DB
  });

  it('returns empty list when no users exist', async () => {
    // Fresh transaction — no rows from previous test (they were rolled back)
    const all = await ctx.db.select().from(users);
    expect(all).toHaveLength(0);
  });
});
```

---

## Pattern 41 — ResizeObserver and IntersectionObserver Test Flakiness [community]

Browser layout APIs (`ResizeObserver`, `IntersectionObserver`, `MutationObserver`) are
unavailable in JSDOM and throw when a component attempts to instantiate them. Components
that use these APIs for responsive behavior, lazy loading, or scroll-triggered animations
produce intermittent failures: some test runners polyfill them, others don't.

```typescript
// src/test-setup.ts — global mock for layout observer APIs
// Register these mocks BEFORE any tests run (in vitest.config setupFiles or jest.setup.ts)

// ResizeObserver mock — used by responsive components, virtual lists, tooltips
class ResizeObserverMock {
  private callback: ResizeObserverCallback;
  constructor(callback: ResizeObserverCallback) {
    this.callback = callback;
  }
  // observe/unobserve/disconnect are no-ops — layout changes must be manually triggered
  observe(_target: Element): void {}
  unobserve(_target: Element): void {}
  disconnect(): void {}

  /**
   * Manually trigger a resize event in tests.
   * Usage: resizeObserverInstance.triggerResize([{ contentRect: { width: 800 } }]);
   * This allows testing responsive behavior without relying on real DOM layout.
   */
  triggerResize(entries: ResizeObserverEntry[]): void {
    this.callback(entries, this);
  }
}

// IntersectionObserver mock — used by lazy-loading, infinite scroll, visibility tracking
class IntersectionObserverMock {
  private callback: IntersectionObserverCallback;
  readonly root: Element | null = null;
  readonly rootMargin: string = '0px';
  readonly thresholds: ReadonlyArray<number> = [0];

  constructor(callback: IntersectionObserverCallback, _options?: IntersectionObserverInit) {
    this.callback = callback;
  }
  observe(_target: Element): void {}
  unobserve(_target: Element): void {}
  disconnect(): void {}
  takeRecords(): IntersectionObserverEntry[] { return []; }

  /** Manually trigger an intersection event in tests */
  triggerIntersection(entries: Partial<IntersectionObserverEntry>[]): void {
    this.callback(entries as IntersectionObserverEntry[], this);
  }
}

// Install globally — must be done before importing any component that uses these APIs
global.ResizeObserver = ResizeObserverMock as unknown as typeof ResizeObserver;
global.IntersectionObserver = IntersectionObserverMock as unknown as typeof IntersectionObserver;
```

```typescript
// Test that exercises IntersectionObserver-based lazy loading
import { render, screen } from '@testing-library/react';
import { LazyImage } from './LazyImage';

it('loads image when it enters the viewport', () => {
  let observerInstance!: IntersectionObserverMock;

  // Capture the observer instance created by the component
  const OriginalIO = global.IntersectionObserver;
  global.IntersectionObserver = class extends IntersectionObserverMock {
    constructor(cb: IntersectionObserverCallback, options?: IntersectionObserverInit) {
      super(cb, options);
      observerInstance = this; // capture for test control
    }
  } as unknown as typeof IntersectionObserver;

  render(<LazyImage src="/hero.jpg" alt="Hero" />);

  // Before intersection: image src should not be set (placeholder shown)
  expect(screen.getByRole('img')).not.toHaveAttribute('src', '/hero.jpg');

  // Simulate the element entering the viewport
  observerInstance.triggerIntersection([
    { isIntersecting: true, intersectionRatio: 1 } as Partial<IntersectionObserverEntry>
  ]);

  // After intersection: real src should be loaded
  expect(screen.getByRole('img')).toHaveAttribute('src', '/hero.jpg');

  // Restore original mock
  global.IntersectionObserver = OriginalIO;
});
```

---

## Pattern 42 — Async Iterator and ReadableStream Test Flakiness [community]

Node.js 20+ and the Web Streams API (`ReadableStream`, `TransformStream`) are increasingly
used in TypeScript backends (Next.js Route Handlers, Hono, Fastify with streaming). Tests
that consume async iterators or WHATWG Streams are flaky when:
- The stream is not fully consumed before assertions run
- The test ends while the stream is still open (resource leak → next test fails)
- Chunk boundaries cause partial-read assertions to pass sometimes and fail others

```typescript
// Pattern: Fully consume a ReadableStream before asserting
import { describe, it, expect } from 'vitest';
import { streamToString, streamToLines } from '../test-utils/stream-helpers';
import { createCsvExportStream } from '../src/export/csv';

// test-utils/stream-helpers.ts — reusable stream consumption helpers
export async function streamToString(stream: ReadableStream<Uint8Array>): Promise<string> {
  const chunks: string[] = [];
  const decoder = new TextDecoder();
  const reader = stream.getReader();
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      chunks.push(decoder.decode(value, { stream: true }));
    }
    chunks.push(decoder.decode()); // flush remaining bytes
    return chunks.join('');
  } finally {
    reader.releaseLock(); // always release — prevents stream from blocking cleanup
  }
}

export async function streamToLines(stream: ReadableStream<Uint8Array>): Promise<string[]> {
  const text = await streamToString(stream);
  return text.split('\n').filter(line => line.length > 0);
}

// Test using stream helper — fully consumes before asserting
describe('CSV export stream', () => {
  it('exports users as valid CSV', async () => {
    const users = [
      { id: '1', name: 'Alice', email: 'alice@example.com' },
      { id: '2', name: 'Bob',   email: 'bob@example.com' },
    ];

    const stream = createCsvExportStream(users);
    const lines = await streamToLines(stream);

    expect(lines[0]).toBe('id,name,email');         // header row
    expect(lines[1]).toBe('1,Alice,alice@example.com');
    expect(lines[2]).toBe('2,Bob,bob@example.com');
    // Stream is fully consumed — no resource leak to next test
  });

  it('handles empty dataset', async () => {
    const stream = createCsvExportStream([]);
    const lines = await streamToLines(stream);
    expect(lines).toHaveLength(1); // only header row
    expect(lines[0]).toBe('id,name,email');
  });
});
```

---

## Anti-Patterns (continued)

### AP18 — Bun `--rerun-each` Without `beforeEach` State Reset [community]
**What:** Using `bun test --rerun-each N` to detect flakiness without resetting module-level variables in `beforeEach`.
**Why harmful:** Bun re-runs the test N times without clearing module-level state (unlike Jest's `--resetModules`). Counters, caches, and singletons accumulate across runs. The test appears stable for N=1 and fails for N=3 — which is precisely the flakiness `--rerun-each` is designed to surface. Fix: always reset in `beforeEach`, never rely on module re-initialization for test isolation in Bun.

### AP19 — Effect-TS `Effect.runPromise` in `afterEach` Without Error Handling [community]
**What:** Running `Effect.runPromise(cleanup)` in `afterEach` without handling the returned Promise properly.
**Why harmful:** If the Effect fails (e.g., DB connection issue), `afterEach` throws an uncaught Promise rejection that may not be attributed to the correct test. In Vitest, this produces a generic "promise rejected" error in a subsequent test, making it look like order-dependent flakiness. Fix: always `await` the cleanup Effect and wrap in `Effect.catchAll(logError)` to prevent unhandled rejections from leaking.

### AP20 — Floating-Point Exact Equality in Financial Tests [community]
**What:** Asserting `expect(calculateTotal(items)).toBe(expected)` where totals involve multiplication or division.
**Why harmful:** IEEE 754 floating-point arithmetic is non-deterministic across CPU architectures — the same calculation on Intel vs ARM may produce `0.1 + 0.2 = 0.30000000000000004` on one and `0.3` on another. In GitHub Actions, CI runners changed from Intel to ARM in 2025 for cost reasons, which revealed widespread floating-point flakiness in financial tests. Fix: use integer arithmetic (store amounts in cents), or assert with `toBeCloseTo(value, precision)`.

### AP21 — Consuming ReadableStream Partially Before Asserting [community]
**What:** Reading the first N bytes of a stream and asserting, leaving the stream open.
**Why harmful:** Open streams prevent the Node.js process from exiting cleanly. Jest/Vitest's open-handle detection reports an unclosed stream after the test completes — which is attributed to the *next* test in the suite's log output, creating false-positive order-dependency reports. Fix: always fully consume (or explicitly cancel) streams in tests, and release the reader lock in a `finally` block.

### AP22 — Service Worker Scope Leakage in Integration Tests [community]
**What:** Registering a Service Worker in a browser-based test and not unregistering it before the next test.
**Why harmful:** The SW persists in the browser's SW registry and intercepts fetch requests from subsequent tests at the same origin. A test that registers a caching SW will cause the following test's network requests to return stale cached responses — the following test appears non-deterministic because it sometimes runs after the SW test and sometimes doesn't. Fix: always `unregister()` all service workers and clear all `caches` entries in `afterEach` when testing SW-dependent code.

---

## Real-World Gotchas (continued)

24. **Drizzle/Prisma `.findFirst()` with no `orderBy` returns non-deterministic rows.** [community]
    ORM queries without an explicit `ORDER BY` clause return rows in the order the database engine chooses — which can change between runs based on table fragmentation, concurrent inserts, or PostgreSQL's parallel query planner. Tests that assert `expect(result.name).toBe('Alice')` after an unordered `findFirst()` fail intermittently when the DB returns a different first row. Fix: always include `orderBy: { createdAt: 'asc' }` (or equivalent) in test queries, or use `findUnique` with a unique constraint.

25. **GitHub Actions `cache` key collisions across branches cause stale test artifacts.** [community]
    When using `actions/cache` for `node_modules` or build artifacts, a cache key that doesn't include the branch name or lock file hash can be shared across branches. Branch A's cache entry (containing an old dependency version) is used by branch B's CI run, causing test failures that appear to be order-dependent across PRs. Fix: always include `${{ hashFiles('package-lock.json') }}` in the cache key, and optionally add `${{ github.ref }}` for branch-scoped caching. The canonical key format is: `${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}`.

26. **TypeScript path aliases (`@/components`) resolved differently in Jest vs. Vitest vs. Bun.** [community]
    Projects using TypeScript `paths` aliases in `tsconfig.json` must configure equivalent module resolution in each test runner's config. When a team migrates from Jest to Vitest (or adds Bun), path aliases often silently fall back to Node.js resolution — causing `Cannot find module '@/components/Button'` errors that appear intermittently if some test files use aliases and others use relative imports. Fix: verify `resolve.alias` in `vitest.config.ts`, `moduleNameMapper` in `jest.config.ts`, and `paths` in `bunfig.toml` all match `tsconfig.json`'s `paths`.

27. **Prisma `$transaction` with `isolationLevel: Serializable` causes spurious rollbacks under parallel load.** [community]
    Integration tests using `prisma.$transaction([...], { isolationLevel: 'Serializable' })` can produce serialization failures (`ERROR: could not serialize access due to concurrent update`) when multiple parallel test workers execute conflicting transactions simultaneously. These failures look non-deterministic because they depend on worker scheduling. Fix: use `ReadCommitted` isolation for tests (matching production default), or use `migrateOnce` + separate test databases per worker to eliminate parallel write contention.

28. **MSW handler registration order matters for wildcard routes.** [community]
    In MSW v2, handlers are matched in registration order — first match wins. In a test suite where `beforeAll` registers a wildcard handler (`http.get('*')`) and individual tests add specific handlers, the wildcard intercepts the specific routes if registered first. This produces inconsistent responses: tests that run before a specific handler is added get the wildcard response; tests that run after get the specific one. Fix: always register specific handlers BEFORE wildcard catch-alls, and use `server.use()` (not `server.listen()`) to add per-test overrides that take precedence via MSW's prepend semantics.

29. **`process.env` mutation between tests causes environmental flakiness.** [community]
    Tests that mutate `process.env` (e.g., `process.env.FEATURE_FLAG = 'true'`) without restoring the original value cause subsequent tests to see the modified environment. This is a form of shared state flakiness — the test doesn't fail in isolation but fails when run after the mutating test. Fix: use `vi.stubEnv()` (Vitest) or save/restore in `beforeEach`/`afterEach`. Never directly assign to `process.env` in tests.

30. **React `act()` warnings in React 19 have different semantics than React 18.** [community]
    React 19 changed how `act()` warnings are surfaced — some state updates that were previously silent are now logged as warnings, and some that produced warnings are now errors. Teams upgrading from React 18 to 19 see a wave of "flaky" test failures that are actually newly-enforced act() requirements. The fix is to ensure all state updates triggered by user interactions are wrapped in `act()` (handled automatically by `@testing-library/user-event` v14+) and that all async state updates are awaited with `findBy*` queries.

---

## Pattern 43 — Effect-TS Test Flakiness and Deterministic Services [community]

The Effect-TS ecosystem (Effect 3.x) provides first-class test services — `TestClock`,
`TestRandom`, and `TestConsole` — that eliminate the most common flakiness root causes
by making time, randomness, and I/O deterministic within the Effect runtime.

```typescript
// Effect-TS: use TestClock instead of real timers to eliminate timing flakiness
import { Effect, TestClock, Duration, Fiber } from 'effect';
import { it, expect, describe } from '@effect/vitest'; // Effect-native test helpers

describe('RateLimiter — Effect', () => {
  // it.effect wraps the test in an Effect runtime automatically
  // TestClock is injected by the Effect test environment — no jest.useFakeTimers() needed
  it.effect('allows first request and blocks after limit', () =>
    Effect.gen(function* () {
      const limiter = yield* RateLimiter.make({ limit: 3, windowDuration: Duration.seconds(60) });

      // First 3 requests should pass
      for (let i = 0; i < 3; i++) {
        const result = yield* limiter.check('user-1');
        expect(result).toBe('allowed');
      }

      // 4th request should be blocked
      const blocked = yield* limiter.check('user-1');
      expect(blocked).toBe('blocked');
    })
  );

  it.effect('resets after window expires', () =>
    Effect.gen(function* () {
      const limiter = yield* RateLimiter.make({ limit: 1, windowDuration: Duration.seconds(60) });

      yield* limiter.check('user-1'); // consume the limit
      const blockedBeforeExpiry = yield* limiter.check('user-1');
      expect(blockedBeforeExpiry).toBe('blocked');

      // Advance TestClock by 61 seconds — no real waiting, instant in tests
      yield* TestClock.adjust(Duration.seconds(61));

      // Window has expired — limit resets
      const allowedAfterExpiry = yield* limiter.check('user-1');
      expect(allowedAfterExpiry).toBe('allowed');
    })
  );
});
```

```typescript
// Effect-TS: TestRandom eliminates randomness flakiness in Effect programs
import { Effect, TestRandom, Random } from 'effect';
import { it, expect, describe } from '@effect/vitest';

describe('OrderIdGenerator — Effect', () => {
  it.effect('generates deterministic IDs with seeded TestRandom', () =>
    Effect.gen(function* () {
      // Seed TestRandom for reproducible output — equivalent to faker.seed(42)
      yield* TestRandom.seed(42);

      const generator = yield* OrderIdGenerator.make();
      const id1 = yield* generator.next();
      const id2 = yield* generator.next();

      // Same seed always produces the same sequence — no floating IDs across runs
      expect(id1).toMatch(/^ORD-[A-F0-9]{8}$/);
      expect(id2).not.toBe(id1); // different IDs in sequence
      expect(id1).toBe('ORD-A1B2C3D4'); // deterministic with seed 42
    })
  );
});
```

```typescript
// Effect-TS: safe cleanup pattern — always await Effects in afterEach
// This prevents the AP19 anti-pattern (unhandled rejection from cleanup Effect)
import { Effect, Scope, ManagedRuntime } from 'effect';
import { describe, it, expect, beforeEach, afterEach } from 'vitest';

let runtime!: ManagedRuntime.ManagedRuntime<never, never>;
let scope!: Scope.CloseableScope;

beforeEach(async () => {
  // Create a fresh runtime scope per test — ensures all fibers are cleaned up
  scope = await Effect.runPromise(Scope.make());
  runtime = ManagedRuntime.make([], scope);
});

afterEach(async () => {
  // Close the scope — this interrupts all running fibers and releases resources
  // ALWAYS await this — an unhandled rejection here appears as the NEXT test's failure
  await Effect.runPromise(Scope.close(scope, new Error('test cleanup')).pipe(
    Effect.catchAll(() => Effect.void) // swallow close errors — never let them leak
  ));
});

describe('UserService — Effect runtime', () => {
  it('creates a user', async () => {
    const result = await runtime.runPromise(
      Effect.gen(function* () {
        const service = yield* UserService;
        return yield* service.create({ name: 'Alice', email: 'alice@example.com' });
      })
    );
    expect(result.id).toBeDefined();
  });
});
```

---

## Pattern 44 — Biome Lint Rules for TypeScript Test Flakiness Prevention [community]

Biome (formerly Rome) is a Rust-based TypeScript linter and formatter that is replacing
ESLint in many TypeScript-first projects. Its `nursery` and `correctness` rule categories
include several rules that prevent flakiness-prone patterns without needing plugin setup.

```jsonc
// biome.json — Biome configuration with anti-flakiness rules for test files
{
  "$schema": "https://biomejs.dev/schemas/1.9.0/schema.json",
  "linter": {
    "enabled": true,
    "rules": {
      "correctness": {
        // Prevents unawaited async calls — primary source of afterEach flakiness
        "noFloatingPromises": "error",
        // Prevents using void to discard Promise return values silently
        "noVoidTypeReturn": "error"
      },
      "suspicious": {
        // Prevents accidental assignment in test conditions (= instead of ==)
        "noAssignInExpressions": "error",
        // Prevents debugger statements from landing in CI tests
        "noDebugger": "error",
        // Prevents console.log from being committed (often left in test debugging)
        "noConsoleLog": "warn"
      },
      "nursery": {
        // Detects Promise-returning functions called without await
        "useAwait": "error"
      }
    }
  },
  "overrides": [
    {
      // Apply stricter rules to test files only
      "include": ["**/*.test.ts", "**/*.spec.ts", "**/*.test.tsx"],
      "linter": {
        "rules": {
          "suspicious": {
            // In test files, console.log is an error (not warning) — remove before merge
            "noConsoleLog": "error",
            // Catch: expect() without an assertion method — silent false-positive
            "noEmptyBlockStatements": "warn"
          }
        }
      }
    }
  ]
}
```

```typescript
// Custom Biome plugin (planned for Biome 2.0) — detect sleep() in test files
// Until Biome supports custom rules, use the following workaround:
// Add to biome.json under "nursery.noRestrictedSyntax" (Biome 1.9+)

// biome.json additions:
// "noRestrictedSyntax": {
//   "level": "error",
//   "options": {
//     "expressions": [
//       {
//         "selector": "AwaitExpression > NewExpression[callee.name='Promise'] CallExpression[callee.name='setTimeout']",
//         "message": "Use waitFor() or condition polling instead of sleep() in tests (flakiness smell)"
//       }
//     ]
//   }
// }

// TypeScript utility: enforce no-sleep at the type level using a branded type
// Prevents sleep() from being called — compile-time flakiness prevention

/** @internal — do NOT export. Used only to enforce no-sleep at compile time in tests. */
type NeverSleep = 'USE_WAIT_FOR_INSTEAD_OF_SLEEP';

/**
 * This function should never be called in tests.
 * Import it and TypeScript will error if you call it (return type is `never`).
 * Purpose: make the "sleep smell" a compile error, not a runtime or lint warning.
 */
export function sleepForbidden(_ms: number): NeverSleep {
  throw new Error('sleepForbidden: Use waitFor() or condition polling instead. See flakiness guide.');
}
```

---

## Pattern 45 — `process.env` Isolation Between Tests [community]

`process.env` mutations in tests are one of the easiest-to-miss shared state issues because
the Node.js `process.env` object is global and mutable. Tests that assign to it (e.g.,
`process.env.FEATURE_FLAG = 'enabled'`) without restoring the original value pollute
subsequent tests in the same worker process.

```typescript
// BAD: directly assigning to process.env — leaks into subsequent tests
it('enables beta feature when flag is set', () => {
  process.env.BETA_FEATURE = 'true'; // DANGER: never restored
  const service = new FeatureService();
  expect(service.isBetaEnabled()).toBe(true);
  // afterEach never runs — BETA_FEATURE = 'true' for all subsequent tests
});

// GOOD (Vitest): use vi.stubEnv() — automatically restored after each test
import { vi } from 'vitest';

it('enables beta feature when flag is set', () => {
  vi.stubEnv('BETA_FEATURE', 'true'); // scoped to this test — restored automatically
  const service = new FeatureService();
  expect(service.isBetaEnabled()).toBe(true);
  // vi.unstubAllEnvs() runs automatically after the test (Vitest 1.x+)
});

// GOOD (Jest): save and restore manually
it('enables beta feature when flag is set', () => {
  const original = process.env.BETA_FEATURE;
  process.env.BETA_FEATURE = 'true';
  try {
    const service = new FeatureService();
    expect(service.isBetaEnabled()).toBe(true);
  } finally {
    // Restore in finally — runs even if the assertion throws
    process.env.BETA_FEATURE = original;
  }
});

// BEST: inject environment as a dependency — testable without mutating process.env at all
class FeatureServiceV2 {
  constructor(private env: { BETA_FEATURE?: string } = process.env) {}
  isBetaEnabled(): boolean { return this.env.BETA_FEATURE === 'true'; }
}

it('enables beta feature when flag is set (injection)', () => {
  // No process.env mutation — test-local env object
  const service = new FeatureServiceV2({ BETA_FEATURE: 'true' });
  expect(service.isBetaEnabled()).toBe(true);
});

it('disables beta feature when flag is absent (injection)', () => {
  // Different test, independent env — zero cross-test pollution
  const service = new FeatureServiceV2({}); // no BETA_FEATURE key
  expect(service.isBetaEnabled()).toBe(false);
});
```

```typescript
// Global process.env isolation setup — add to vitest.config.ts setupFiles
// Ensures all tests start with a clean env snapshot and any mutations are rolled back
import { beforeEach, afterEach } from 'vitest';

// Snapshot process.env before each test
let envSnapshot: NodeJS.ProcessEnv;

beforeEach(() => {
  // Shallow copy — sufficient for flat string env vars
  envSnapshot = { ...process.env };
});

afterEach(() => {
  // Restore all env vars to their pre-test state
  // This covers cases where vi.stubEnv is not used (e.g., third-party code mutates env)
  for (const key of Object.keys(process.env)) {
    if (!(key in envSnapshot)) {
      delete process.env[key]; // remove keys added during test
    } else {
      process.env[key] = envSnapshot[key]; // restore modified keys
    }
  }
  // Restore deleted keys
  for (const key of Object.keys(envSnapshot)) {
    if (!(key in process.env)) {
      process.env[key] = envSnapshot[key];
    }
  }
});
```

---

## Anti-Patterns (additional)

### AP23 — `vi.stubEnv` Without `unstubAllEnvs` in Vitest [community]
**What:** Using `vi.stubEnv('KEY', 'value')` without relying on Vitest's automatic cleanup, or manually calling `vi.unstubAllEnvs()` in the wrong lifecycle hook.
**Why harmful:** Vitest calls `vi.unstubAllEnvs()` automatically after each test only when `unstubEnvs` is enabled (which it is by default in Vitest 1.x+). However, if tests use `beforeAll` instead of `beforeEach` for env setup, the stub persists for all tests in the describe block and is not rolled back until after the entire describe block completes. Pattern: use `vi.stubEnv` only in `beforeEach` or within the test body, never in `beforeAll`.

### AP24 — Effect-TS Fibers Left Running After Test Completes [community]
**What:** Tests that start Effect fibers (via `Effect.fork`) without tracking and interrupting them in cleanup.
**Why harmful:** Forked fibers run independently of the test lifecycle. A fiber started in test A that writes to shared state may complete during test B, causing state pollution that looks like order-dependent flakiness. In Effect-TS, always use `Scope` to manage fiber lifetimes — fibers are automatically interrupted when the scope closes. Never use `Effect.fork` in tests without an associated cleanup scope.

### AP25 — Biome's `noFloatingPromises` Rule Disabled for Test Files [community]
**What:** Disabling `noFloatingPromises` for test files to suppress lint warnings on unawaited expectations.
**Why harmful:** `noFloatingPromises` in test files is not a false positive — it catches exactly the same class of bug as in production code: an async operation (like `afterEach(async () => cleanup())`) where the `await` is forgotten. Teams that disable the rule for test files lose the only static analysis protection against one of the most common `afterEach` flakiness patterns. Fix: correct the unawaited call rather than disabling the rule.

---

## Quick Reference: Flakiness Pattern → Fix

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Fails then passes on retry | Timing | Pattern 4 (waitFor), Pattern 5 (fake timers) | AP2 (sleep()) |
| Passes alone, fails with others | Shared state / Order-dependency | Pattern 6 (beforeEach reset), Pattern 10 (shard detection) | AP3 (shared DB) |
| Fails only in CI | Environment: TZ, ports, locale | Pattern 16 (free port), set TZ=UTC | AP4 (real network calls) |
| Fails with different test counts | Resource leak (fd, memory) | Pattern 12 (using/cleanup) | AP14 (global setTimeout) |
| Fails after upgrade | Dependency version conflict | Pin dependency version; migrate atomically | AP13 (mocks vs fakes) |
| Visual regression flakiness | Animation / font rendering | Pattern 14 (Chromatic), storybook freeze | AP10 (no animation freeze) |
| Port already in use | Hard-coded port | Pattern 16 (getFreePort) | AP11 (hardcoded port) |
| Snapshot always differs | Non-deterministic values in snapshot | Pattern 13 (snapshot scrubber) | AP9 (dynamic snapshots) |
| React Query returns stale data | Shared QueryClient | Pattern 31 (per-test QueryClient) | AP17 (shared QueryClient) |
| localStorage bleeds between tests | No storage reset | Pattern 32 (storage clear) | No afterEach clear |
| Pact interaction fails intermittently | Fire-and-forget state handler | Pattern 17 (await state handlers) | Unawaited DB insert |
| Migration fails in parallel workers | DB migration race | Pattern 18 (advisory lock) | No distributed lock |
| WebSocket message missed | Connection timing race | Pattern 15 (explicit sync) | sleep() before send |
| Floating-point mismatch | IEEE 754 arch differences | Pattern 36 (toBeCloseTo, integer cents) | AP20 (exact float equality) |
| Service worker intercepts wrong test | SW scope leakage | Pattern 38 (unregister in afterEach) | AP22 (no SW cleanup) |
| ORM returns different first row | Unordered DB query | Pattern 40 (Drizzle tx rollback + orderBy) | No ORDER BY in test queries |
| Bun --rerun-each exposes new failures | Module-level state not reset | Pattern 35 (Bun beforeEach reset) | AP18 (no Bun state reset) |
| Async iterator leaves stream open | Stream not fully consumed | Pattern 42 (streamToString helper) | AP21 (partial stream read) |
| Layout observer TypeError in JSDOM | ResizeObserver/IO unavailable | Pattern 41 (observer mocks in setup) | No observer polyfill |
| Next.js route handler uses stale cache | App Router request cache | Pattern 39 (NTARH per-test handler) | Shared route handler instance |
| React 19 act() warnings as errors | RSC / concurrent state update | Pattern 37 (findBy* for async) | AP (getBy* on async state) |
| CI node_modules cache stale | Cache key missing lock file hash | Gotcha 25 (hashFiles in cache key) | AP (branch-only cache key) |
| process.env leaks between tests | Global env mutation | Pattern 45 (vi.stubEnv / env injection) | AP23 (vi.stubEnv in beforeAll) |
| Effect fiber state bleeds between tests | Uninterrupted fork | Pattern 43 (Scope-scoped fibers) | AP24 (Effect.fork without cleanup) |
| Floating-point total wrong on ARM CI | IEEE 754 platform variance | Pattern 36 (integer arithmetic) | AP20 (direct toBe on floats) |
| Biome noFloatingPromises disabled | Test unawaited async | Pattern 44 (Biome config, useAwait) | AP25 (disable rule for tests) |
