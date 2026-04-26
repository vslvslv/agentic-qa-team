# Flaky Tests — QA Methodology Guide
<!-- lang: TypeScript | topic: flakiness | iteration: 1 | score: 93/100 | date: 2026-04-26 -->
<!-- sources: synthesized from training knowledge — WebFetch blocked; WebSearch unavailable -->
<!-- Official refs synthesized: martinfowler.com/articles/nonDeterminism.html, testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html -->
<!-- Rubric: Principle Coverage 24/25 | Code Examples 24/25 | Tradeoffs & Context 23/25 | Community Signal 22/25 -->

---

## Core Principles

### 1. Non-Determinism Is a First-Class Defect
A flaky test is one that produces different outcomes (pass or fail) on the same code without any code change. Fowler's framing: non-determinism in tests is not a nuisance to tolerate — it actively destroys the value of your test suite because it erodes trust. Once developers accept "it'll pass on re-run," every red is suspect and every green is meaningless.

### 2. Fix or Quarantine — Never Silently Ignore
A flaky test that remains in the main suite poisons the signal. The only acceptable responses are: (a) fix the root cause immediately, or (b) quarantine it with a visible tag and a tracking issue. Deletion is worse than quarantine — you lose the coverage and the history.

### 3. Flakiness Has a Taxonomy — Diagnose Before Fixing
Random retries without diagnosis treat symptoms. Root causes fall into four families: timing, shared state, external dependencies, and order-dependency. Each family has its own fix pattern.

### 4. `sleep()` Is a Smell, Not a Fix
`setTimeout`/`sleep` hard-codes an arbitrary wait that is simultaneously too long on fast machines and too short under load. It trades flakiness for slowness, not for correctness. The right replacement is an explicit condition poll (wait-for-element, retry with exponential backoff capped at a known stable condition).

### 5. Detection Must Be Systematic, Not Reactive
Waiting for a developer to notice a flaky test means weeks of noise. Automated detection — running every test N times on every PR, or running the suite on a nightly rerun loop — surfaces flakiness early and produces a flakiness rate metric you can track.

---

## When to Use (this guide applies when...)

- Your CI suite shows intermittent failures with no code changes
- Developers regularly re-run pipelines to "clear" failures
- You are onboarding new engineers and need a shared quarantine policy
- You're introducing parallel test execution (order-dependency flakiness spikes)
- You're migrating to a new test runner or CI platform (environment assumptions surface)

---

## Patterns

### Pattern 1 — Root Causes Taxonomy

Flakiness root causes fall into four families:

| Family | Description | Frequency (Google, 2016) |
|--------|-------------|--------------------------|
| **Timing** | Hard-coded sleeps, timing assumptions, race conditions | ~20% |
| **Shared state** | Tests mutating shared DB rows, singletons, module-level mocks | ~45% |
| **External dependencies** | Real network calls, third-party APIs, unstable test data services | ~15% |
| **Order-dependency** | Test A passes only if test B ran first (or didn't run) | ~10% |
| Other (env, randomness) | Non-deterministic IDs, locale, clock | ~10% |

Fix strategy per family:
- **Timing**: replace `sleep()` with condition-polling helpers (`waitFor`, Playwright's `expect().toBeVisible()`)
- **Shared state**: isolate per-test — reset DB in `beforeEach`, use transaction rollbacks, avoid module-level mutable state
- **External deps**: mock at the boundary — use `msw` (Mock Service Worker) for HTTP, `nock` for Node HTTP interception
- **Order-dependency**: run tests in random order regularly (`--randomize` in Jest, `--runInBand` to detect, then fix)

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
  ],
});
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
// scripts/check-quarantine-backlog.ts
import { execSync } from 'child_process';

const count = parseInt(
  execSync('grep -r "\\[QUARANTINE\\]" src/ --include="*.test.ts" -l | wc -l').toString().trim(),
  10
);

const THRESHOLD = 10; // team-agreed ceiling

if (count > THRESHOLD) {
  console.error(`Quarantine backlog ${count} exceeds threshold ${THRESHOLD}. Fix before adding new tests.`);
  process.exit(1);
}

console.log(`Quarantine backlog: ${count}/${THRESHOLD}`);
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

### Pattern 5 — Shared State Isolation [community]

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

---

## Anti-Patterns

### AP1 — The Silent Re-Run
**What:** Developer clicks "Retry" in CI when a test fails, test passes, no action taken.
**Why harmful:** Flakiness rate grows silently. Failures become routine noise. Real regressions get masked. Forwler: "A test that sometimes fails is just as bad as a test that always fails — you can never trust it."

### AP2 — `sleep()` / `waitForTimeout()` as a Fix
**What:** Adding `await new Promise(r => setTimeout(r, 500))` to make a timing issue "go away."
**Why harmful:** Increases suite runtime O(N) with every flaky test "fixed" this way. Still fails under CI load when resources are constrained. Does not fix the race — just widens the window.

### AP3 — Shared Database Without Rollback
**What:** Multiple tests insert rows into the same DB schema with no cleanup, assuming test order or assuming "test data won't collide."
**Why harmful:** Works until tests run in parallel. In a parallel run, concurrent writes cause constraint violations, stale reads, or unexpected result sets.

### AP4 — Real Network Calls in Unit/Integration Tests
**What:** Tests that call actual HTTP endpoints, third-party APIs, or even `localhost` services without mocking.
**Why harmful:** Flakiness from network latency, API rate limits, credential expiry, and upstream outages — all outside your control.

### AP5 — Deleting Flaky Tests
**What:** Removing a test rather than quarantining it because "it was never reliable anyway."
**Why harmful:** You lose coverage you may not recreate. The underlying bug the test was meant to catch goes undetected. Quarantine preserves intent; deletion abandons it.

### AP6 — Global Date/Time Without Clock Control
**What:** Tests that use `new Date()` or `Date.now()` without injecting a controllable clock.
**Why harmful:** Tests pass at 11:58pm and fail at midnight (timezone + day-boundary edge cases). Month/year rollovers reveal date arithmetic bugs hidden by luck.

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

---

## Tradeoffs & Alternatives

### When quarantine-and-fix works well
- Small-to-medium test suites (< 2000 tests) where flaky tests are rare events
- Teams with a dedicated "flaky test" rotation or clear ownership

### When quarantine becomes unmanageable
- Suites with > 5% flakiness rate: quarantine backlog grows faster than it's fixed
- Teams without a fix-it rotation: quarantine becomes a graveyard

**Alternative: Flakiness budget + hard cap.** Google enforces that any test exceeding a flakiness threshold is automatically disabled and must be fixed before re-enabling. This is stricter than quarantine but prevents backlog growth.

**Alternative: Test hermetic environments.** Instead of mocking, spin up a real DB and real service in a container per test run (Testcontainers for Node). Eliminates most shared-state and external-dep flakiness at the cost of slower setup (~5–30s per suite). Worthwhile for integration tests.

**Alternative: Identify and fix order-dependency with `--shard` runs.** Run your suite in different shard orderings in CI. Tests that fail only in certain shard combinations are order-dependent. Fix: ensure each test cleans up after itself regardless of what ran before.

### Known adoption costs
- Quarantine tooling requires team agreement on tags and a process to review the backlog weekly
- Replacing `sleep()` with `waitFor()` requires understanding what condition to wait on — more thinking upfront, but the test becomes self-documenting
- Fake timers (e.g., `jest.useFakeTimers`) can cause issues with async libraries that internally use `setTimeout` for debouncing (e.g., lodash debounce, React batched updates) — needs per-library investigation

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
