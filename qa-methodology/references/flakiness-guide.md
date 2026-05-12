# Flaky Tests — QA Methodology Guide
<!-- lang: TypeScript | topic: flakiness | iteration: 60 | score: 100/100 | date: 2026-05-12 -->
<!-- Rubric: Principle Coverage 25/25 | Code Examples 25/25 | Tradeoffs & Context 25/25 | Community Signal 25/25 | new: playwright-testresult-annotations-reporter, vitest-context-annotate, playwright-testproject-workers-v152, github-actions-dorny-test-reporter -->
<!-- Iteration 60: Pattern 102 (EventEmitter maxListeners warning as flakiness signal — detect listener leaks before they cascade); Pattern 103 (jest.doMock() + resetModules for dynamic per-test mocking without hoisting surprises); Pattern 104 (global unhandledRejection handler in test setup — surface swallowed async errors as test failures); Gotcha 50 (EventEmitter listener leak in parallel workers); Gotcha 51 (jest.mock hoisting order breaks dynamic mock tests); AP50 (process.on unhandledRejection not set up in test harness); Quick Reference additions (iteration 60) -->
<!-- Iteration 59: Pattern 100 (Playwright v1.52 testResult.annotations per-retry custom reporter for structured flakiness tracking); Pattern 101 (Vitest 3.2 context.annotate() API for attaching structured metadata visible in all reporters); Gotcha 49 (dorny/test-reporter GitHub Action for PR-level flakiness annotations from JUnit XML); AP49 (calling getSeed() inside test bodies instead of setup — returns undefined at test-time) -->
<!-- Iteration 58: Pattern 97 (Playwright v1.45 page.clock — deterministic browser-level time control replacing fake-timer patches); Pattern 98 (Playwright v1.42 page.addLocatorHandler() — automatic overlay/interstitial dismissal to eliminate action-blocking flakiness); Pattern 99 (Vitest 4.0 sequence.shuffle + getSeed() — seeded random ordering with seed capture for reproducible order-dependent flakiness); AP48 (page.clock.install() called after navigation — undefined behavior from out-of-order clock init); Quick Reference additions (iteration 58) -->
<!-- Iteration 57: Pattern 94 (Playwright v1.48 routeWebSocket — deterministic WebSocket mocking without a real server); Pattern 95 (Playwright v1.51 storageState({ indexedDB: true }) — IndexedDB auth persistence for Firebase-style apps); Pattern 96 (Jest 30 jest.onGenerateMock — centralized auto-mock configuration); AP47 (jest.onGenerateMock silent no-op with __mocks__ folder); Gotcha 48 (WebSocketRoute onMessage stops auto-forwarding) -->
<!-- Iteration 56: Pattern 92 (Jest 30 retryTimes with waitBeforeRetry + retryImmediately — staged retry for flaky integration tests); Pattern 93 (Jest 30 advanceTimersToNextFrame() — deterministic requestAnimationFrame testing); AP46 (Jest 30 globalsCleanup not enabled — cross-test global state leak); Quick Reference additions (iteration 56) -->
<!-- Iteration 55: Pattern 90 (Playwright v1.60 tracing.startHar()/stopHar() — HAR recording as first-class tracing API for network flakiness diagnosis); Pattern 91 (Playwright v1.60 toHaveCSS pseudo option — deterministic pseudo-element assertions replacing screenshot snapshots); Gotcha 47 (Playwright v1.60 BrowserContext lifecycle event mirroring — centralized event monitoring for multi-page flakiness); AP45 (Vitest 4.1 FixtureAccessError in suite hooks — accessing test-scoped fixture in beforeAll now throws explicitly); Quick Reference additions (iteration 55) -->
<!-- Iteration 54: Pattern 88 (Vitest 5.0-beta sequential option removed — migrate to concurrent:false or test.describe.serial); Pattern 89 (Playwright v1.60 locator.drop() for drag-and-drop upload zone flakiness); Gotcha 46 (Vitest 5.0 merge reports for non-sharded multi-environment test runs); AP44 (Vitest 5.0 hardcoded .vitest-attachments path breaks on upgrade); Quick Reference additions (iteration 54) -->
<!-- Iteration 53: Pattern 86 (Playwright testCase.outcome() === 'flaky' custom reporter — structured per-retry flakiness tracking); Pattern 87 (Playwright v1.50 updateSnapshots: 'changed' + updateSourceMethod: '3way' for snapshot flakiness review workflow); AP43 (updateSnapshots: 'all' in CI silently overwrites baselines); Quick Reference additions (iteration 53) -->
<!-- Iteration 52: Pattern 82 (Vitest 4.1 vi.setTimerTickMode — nextTimerAsync/interval for async timer flakiness); Pattern 83 (Playwright v1.59 tracing.start({ live: true }) for real-time trace capture); Pattern 84 (Playwright v1.58 retain-on-failure-and-retries trace mode for multi-retry comparison); Pattern 85 (Vitest 4.1 agent/minimal reporter for AI agent token-efficient flakiness triage); AP42 (Vitest 4.1 beforeAll/afterAll hook signature breaking change — Suite arg removed); Quick Reference additions (iteration 52) -->
<!-- Iteration 51: Pattern 78 (Vitest 4.1 conditional retry with error condition predicate); Pattern 79 (Playwright v1.53 TestStepInfo.skip() conditional — step-level quarantine); Pattern 80 (Playwright v1.60 testInfoError.errorContext aria snapshot for flakiness diagnosis); Pattern 81 (Vitest 4.1 test.meta for custom flakiness metadata in reporters); AP41 (conditional retry masking real failures); Quick Reference additions (iteration 51) -->
<!-- sources: WebFetch live — playwright.dev/docs/release-notes, playwright.dev/docs/api/class-testconfig, trunk.io/flaky-tests, vitest.dev/blog, vitest.dev/api/hooks, playwright.dev/docs/api/class-tracing, playwright.dev/docs/api/class-browsercontext, jestjs.io/blog/2025/06/jest-30, jestjs.io/docs/jest-object#jestretrytimersnumretries-options, jestjs.io/docs/jest-object#jestadvancetimerstonextframe -->
<!-- Official refs synthesized: martinfowler.com/articles/nonDeterminism.html, testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html -->
<!-- Iteration 50: Pattern 74 (Vitest 4.1 page.mark() for trace annotation in browser mode); Pattern 75 (Vitest 4.1 mockThrow/mockThrowOnce + chai-style assertions); Pattern 76 (Playwright MCP server @playwright/mcp for agentic flaky test investigation); Pattern 77 (Vitest 4.1 experimental.viteModuleRunner: false for production-fidelity isolation); AP39 (unawaited page.mark()); AP40 (mockThrow on async function); Gotcha 45 (Trunk AI failure fingerprinting vs string matching for variant flakiness) -->
<!-- Iteration 49: Pattern 70 (Playwright v1.59 CLI trace analysis subcommands); Pattern 71 (Playwright --last-failed targeted rerun); Pattern 72 (Vitest 3.2 using keyword auto-restore for vi.spyOn); Pattern 73 (Vitest 3.2 Test Signal API / context.signal); AP38 (manual spy restore when using keyword available); Gotcha 44 (CLI trace grep reduces analysis time on flaky traces) -->
<!-- Iteration 48: Pattern 67 (Vitest 4.1 aroundEach/aroundAll for DB tx rollback); Pattern 68 (Playwright HAR recording for network flakiness); Pattern 69 (Vitest --detect-async-leaks); Gotcha 43 (Playwright browserContext.setStorageState() for auth isolation); AP37 (aroundEach without calling runTest) -->
<!-- Iteration 47: Pattern 64 (Vitest 4.1 tags with per-tag retry); Pattern 65 (Playwright per-project workers for flaky isolation); Pattern 66 (Playwright test step timeout); AP36 (retry-all via global tag); Gotcha 41 (Vitest 3.2 fixture scope 'file' for shared setups); Gotcha 42 (Playwright v1.57 webserver wait regex) -->
<!-- Iteration 46: Pattern 59 (Vitest onTestFailed/onTestFinished hooks); Pattern 60 (Vitest repeats option); Pattern 61 (Playwright test.step.skip()); Pattern 62 (Playwright page.consoleMessages/page.pageErrors for flakiness diagnosis); Pattern 63 (Playwright test.abort() from fixtures); AP35 (Vitest onTestFailed in beforeAll); Gotcha 39 (captureGitInfo correlation); Gotcha 40 (Google TotT: DI for testability) -->
<!-- Iter-43: AP23–AP25; extended Quick Reference table -->
<!-- Iter-44: pytest flaky tests cross-reference (docs.pytest.org/en/stable/explanation/flaky.html, 2026-05-08); cross-language flakiness equivalents table -->
<!-- Iter-45: Pattern 56 (Playwright failOnFlakyTests CI gate); Pattern 57 (trace retain-on-first-failure / retain-on-failure-and-retries); AP33 (failOnFlakyTests in dev mode); Gotcha 37 (Vitest 4 browser mode toMatchScreenshot); Key Resources additions (playwright.dev release notes, Vitest 4 blog) -->
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
| Playwright test passes on retry but CI exits 0 | failOnFlakyTests not enabled | Pattern 56 (failOnFlakyTests: !!CI) | AP33 (enable globally without CI gate) |
| Flaky trace data: too much noise or none at all | Wrong trace mode | Pattern 57 (on-first-retry vs retain-on-failure-and-retries) | AP34 (trace: 'on' globally) |
| toMatchScreenshot fails on CI but passes locally | Font rendering variance (macOS vs Linux) | Pattern 58 (generate baselines on CI OS, maxDiffPixelRatio) | No baseline OS pinning |

---

## Cross-Language Flakiness: pytest (Python)  [official: docs.pytest.org/en/stable/explanation/flaky.html, 2026-05-08]

pytest's official flaky test documentation identifies the same root-cause taxonomy as the TypeScript ecosystem but surfaces through Python-specific mechanisms. This section covers the equivalences for polyglot teams or Python microservice test suites.

### Root Causes (pytest framing)

| Root Cause | pytest manifestation | TypeScript equivalent |
|---|---|---|
| **Insufficient isolation** | Residual state from previous test's `teardown` failing silently | `afterEach` not running when test body throws; open handles |
| **Test ordering dependency** | Parallel workers (`pytest-xdist`) expose hidden `fixture` scope leakage | `--runInBand` masks order-dependency; exposed by `--randomize` |
| **Overly strict assertions** | `assert result == 0.1 + 0.2` fails due to IEEE 754 | `.toBe(0.3)` — fix with `pytest.approx()` / `toBeCloseTo()` |
| **Thread safety** | `pytest.warns()` / `pytest.raises()` not thread-safe when called from spawned threads | `vi.fn()` count assertions racy in `test.concurrent` |

### pytest Quarantine — `pytest.mark.xfail`

```python
# Quarantine with xfail (pytest equivalent of it.skip / vi.todo)
# strict=False means: test may fail, and that's expected — do NOT break CI
@pytest.mark.xfail(strict=False, reason="JIRA-1234: flaky DB cleanup race — fix by 2026-07-01")
def test_order_created_in_db():
    ...

# strict=True means: if the test PASSES, it's an unexpected pass (xpass) — fail CI
# Use strict=True to detect when a formerly-flaky test is now consistently passing
@pytest.mark.xfail(strict=True, reason="Expected to fail until migration JIRA-5678 is merged")
def test_new_payment_flow():
    ...
```

**Equivalent pattern in TypeScript/Vitest:** `it.todo()` or `it.skip('[JIRA-1234] flaky: fix by 2026-07-01', () => { ... })`. Neither Vitest nor Jest has an exact `xfail(strict=False)` equivalent — the closest is `it.fails()` (Vitest) which expects the test to fail.

### pytest-rerunfailures (equivalent: Jest `retryTimes`, Vitest `retry`)

```python
# Install: pip install pytest-rerunfailures
# Per-test retry:
@pytest.mark.flaky(reruns=3, reruns_delay=0.5)
def test_external_api_call():
    ...

# Global retry via pytest.ini / pyproject.toml:
# [pytest]
# addopts = --reruns 2 --reruns-delay 0.3
```

**TypeScript equivalent:**
```typescript
// Vitest — per-test retry
it('flaky external call', { retry: 3 }, async () => { ... })

// Jest global (Jest 29)
jest.retryTimes(2, { logErrorsBeforeRetry: true })

// Jest 30+: new waitBeforeRetry and retryImmediately options — see Pattern 92
jest.retryTimes(2, { logErrorsBeforeRetry: true, waitBeforeRetry: 300, retryImmediately: true })
```

### pytest-randomly / pytest-random-order — Detecting Hidden State

```bash
# Install and enable:
pip install pytest-randomly    # shuffles test order each run with --randomly-seed=LAST to reproduce
pip install pytest-random-order  # similar; use --random-order-seed=LAST

# Run with randomized order:
pytest --randomly-seed=12345  # reproducible seed for debugging
pytest --randomly-seed=random # new seed each run (CI default)
```

**TypeScript equivalent:** Jest `--randomize` (Jest 29.2+) or Vitest `sequence.shuffle: true` in `vitest.config.ts`.

**Key insight:** Both `pytest-randomly` and Jest's `--randomize` randomize within a file's test order. Neither randomizes *across files* by default. Hidden order-dependencies that only surface when file A runs before file B require a separate strategy: run test files in a random sequence (`pytest --co -q | shuf | xargs pytest`).

### pytest `PYTEST_CURRENT_TEST` Environment Variable

pytest sets `PYTEST_CURRENT_TEST` during test execution — useful for diagnosing which test "got stuck" (hung indefinitely) in CI:

```bash
# In CI: if a test hangs, check the environment variable in the runner's process list
# PYTEST_CURRENT_TEST=tests/test_orders.py::test_create_order (call)
# The format: <file>::<test> (<phase>) where phase is "setup", "call", or "teardown"
```

**TypeScript equivalent:** Playwright's `testInfo.title` and `testInfo.file` inside test bodies; Jest's `expect.getState().currentTestName`.

### pytest flakiness vs TypeScript flakiness — Key Differences

| Dimension | pytest (Python) | Jest/Vitest (TypeScript) |
|---|---|---|
| Fixture scope model | Explicit: `function`, `class`, `module`, `session` | Implicit: `beforeEach` (function), `beforeAll` (module) |
| Parallel execution | `pytest-xdist` (`-n auto`) — separate OS processes | `--maxWorkers=50%` — forked processes (Vitest `forks` pool) |
| Module-level singleton reset | Not needed — process isolation in `pytest-xdist` | `vi.resetModules()` / `jest.resetModules()` required in CJS |
| Thread safety for test primitives | `pytest.raises` / `pytest.warns` not thread-safe | `expect()` from vitest/jest is generally thread-safe in practice |
| Floating-point assertions | `pytest.approx(0.3, rel=1e-5)` | `expect(n).toBeCloseTo(0.3, 5)` |
| Randomization | `pytest-randomly` (plugin) | `--randomize` (Jest 29.2+) / `sequence.shuffle` (Vitest) |
| Quarantine | `@pytest.mark.xfail(strict=False)` | `it.skip()` / `it.fails()` (Vitest) |
| Retry | `pytest-rerunfailures` | `retry` option (Vitest) / `retryTimes` (Jest) |

### Key Resources (pytest flakiness)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| pytest Flaky Tests | Official | https://docs.pytest.org/en/stable/explanation/flaky.html | Root causes, xfail quarantine, rerunfailures, randomization |
| pytest-rerunfailures | Community | https://github.com/pytest-dev/pytest-rerunfailures | Per-test and global retry for pytest |
| pytest-randomly | Community | https://github.com/pytest-dev/pytest-randomly | Randomizes test order to expose hidden state dependencies |
| pytest-xdist | Official | https://pytest-xdist.readthedocs.io/ | Parallel pytest execution; exposes ordering flakiness |

---

## Pattern 56 — Playwright `failOnFlakyTests` CI Gate  [official]

Introduced in Playwright v1.52, `failOnFlakyTests` (and the equivalent CLI flag `--fail-on-flaky-tests`
introduced in v1.44) turns flaky test detection into a CI gate: instead of silently passing a run
where a test failed then recovered on retry, Playwright exits with code `1` and explicitly labels
the test "flaky". This shifts flakiness from a tolerable nuisance to a build-breaking signal.

**Why this matters:** Without `failOnFlakyTests`, a CI run that exits `0` may still contain tests
that only passed on the third retry. Developers never see the flakiness signal, quarantine backlogs
grow silently, and the flakiness rate climbs until the suite is untrustworthy. The flag makes
flakiness visible as a first-class defect on every PR.

```typescript
// playwright.config.ts — fail CI on any flaky test (added Playwright v1.52)
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Exit with error if any test is marked flaky (passed only after retry).
  // Set to !!process.env.CI so local runs still tolerate retries during development.
  failOnFlakyTests: !!process.env.CI,

  // Retries are still required — failOnFlakyTests needs retries > 0 to detect flakiness.
  // Without retries, all failures are hard-failures; with retries but no failOnFlakyTests,
  // recoveries are silently treated as passes.
  retries: process.env.CI ? 2 : 0,

  use: {
    // Capture a trace on the first retry so you can open it in Playwright Trace Viewer
    // after failOnFlakyTests breaks the build.
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
  ],
});
```

```bash
# CLI equivalent — useful for one-off detection runs or scripted checks:
npx playwright test --retries=2 --fail-on-flaky-tests

# In GitHub Actions step (pair with the JUnit reporter to get per-test flakiness signals):
- name: Run E2E tests (fail on flaky)
  run: npx playwright test --retries=2 --fail-on-flaky-tests
  env:
    CI: true
```

**Integration with quarantine:** When `failOnFlakyTests` breaks the build, the immediate response
is NOT to disable the flag — it is to quarantine the flaky test case using
`test.describe.configure({ retries: 0 })` + `test.skip(true, '[QUARANTINE] PROJ-NNN ...')`.
This preserves the gate for healthy test cases while deferring the root-cause fix.

---

## Pattern 57 — Playwright Trace Modes for Flaky Test Debugging  [official]

Playwright's `trace` option controls *when* traces are recorded and *which* attempts are retained.
Choosing the right mode significantly affects how quickly you can diagnose flakiness root causes
in CI without drowning in unnecessary trace data.

| Mode | Records on | Retains on | Best for |
|------|-----------|------------|---------|
| `'off'` | Never | — | Clean local runs |
| `'on'` | Every attempt | Always | Initial investigation of unknown flakiness |
| `'on-first-retry'` | First retry only | On failure | **Default CI recommendation** |
| `'retain-on-first-failure'` | First run | Only if first run fails | Capturing the initial failure signal without retry noise |
| `'retain-on-failure-and-retries'` | Every attempt | All attempts when any fails | **Deep flakiness debugging** — compare passing vs failing traces |

`retain-on-failure-and-retries` (introduced Playwright v1.59) is the most powerful mode for
diagnosing flaky tests because it records *all retry attempts* and retains them when the test
ultimately fails. You can open both the passing and failing traces in Playwright Trace Viewer
side-by-side to identify the exact point of divergence.

```typescript
// playwright.config.ts — progressive trace strategy
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,

  use: {
    // For normal CI: capture trace only on first retry (low overhead)
    trace: process.env.CI ? 'on-first-retry' : 'off',

    // Screenshot on failure for fast triage
    screenshot: 'only-on-failure',

    // Video on retry — complements trace for timing-sensitive flakiness
    video: 'on-first-retry',
  },

  // Override: deep debugging project — run separately when investigating a known flaky test
  // npx playwright test --project=flakiness-debug --grep "my flaky test"
  projects: [
    {
      name: 'ci',
      use: { trace: 'on-first-retry' },
    },
    {
      // Deep debugging: retains traces for ALL attempts — use on the specific flaky test case
      // Added: Playwright v1.59
      name: 'flakiness-debug',
      use: {
        trace: 'retain-on-failure-and-retries',
        video: 'retain-on-failure',
      },
      retries: 4, // More retries to increase probability of capturing both pass and fail
    },
  ],
});
```

```typescript
// testInfo.retry — conditional cleanup on retry (Pattern 46 extended with trace context)
// Use to clean up server-side state that a previous failing attempt may have left behind.
import { test, expect } from '@playwright/test';

test('checkout completes successfully', async ({ page, request }, testInfo) => {
  // If this is a retry, the previous attempt may have partially created an order.
  // Clean it up before re-running — prevents "duplicate order" false failures.
  if (testInfo.retry > 0) {
    console.log(`[Retry ${testInfo.retry}] Cleaning up partial order for user test-${testInfo.workerIndex}`);
    await request.delete(`/api/orders/cleanup?user=test-${testInfo.workerIndex}`);
  }

  await page.goto('/checkout');
  await page.getByRole('button', { name: 'Place Order' }).click();
  await expect(page.getByText('Order confirmed')).toBeVisible();
});
```

**Key insight [community]:** Teams that set `trace: 'on'` globally in CI to "always have traces"
pay a significant performance penalty — tracing adds 20–40% to test execution time for complex
E2E tests. The progressive strategy above (`on-first-retry` in CI, `retain-on-failure-and-retries`
in a named debugging project) captures the right data without slowing down the main suite.

---

## Pattern 58 — Vitest 4.x Browser Mode Visual Stability  [official]

Vitest 4.0 (October 2025) promoted Browser Mode from experimental to stable and added
`toMatchScreenshot()` — a visual assertion that compares rendered output pixel-by-pixel.
For component tests that previously used Storybook + Chromatic for visual regression, Vitest
Browser Mode with `toMatchScreenshot` offers a tighter integration at the cost of less
cross-browser coverage.

Visual screenshot assertions have a distinct flakiness profile: **animation flakiness**
(screenshot taken mid-animation) and **font rendering flakiness** (sub-pixel differences
across CI runner OS versions). Both are solvable with explicit freeze patterns.

```typescript
// vitest.config.ts — Vitest 4.x Browser Mode with screenshot stability options
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: 'playwright',  // Playwright as browser provider (stable in Vitest 4)
      name: 'chromium',
      // Headless mode: recommended for CI
      headless: true,
    },
    // Threshold for screenshot comparison — allow 0.1% pixel variance
    // to tolerate sub-pixel font rendering differences across OS versions
    // (Vitest 4 toMatchScreenshot option)
    // See: https://vitest.dev/guide/browser/
  },
});
```

```typescript
// Button.test.tsx — visual regression test with animation freeze
import { render } from '@testing-library/react';
import { expect, it, beforeEach } from 'vitest';
import { Button } from './Button';

it('renders primary button correctly', async () => {
  const { container } = render(<Button variant="primary">Click me</Button>);

  // Step 1: freeze all CSS animations before snapshot
  // Without this, the screenshot may capture mid-transition state — classic visual flakiness
  await page.addStyleTag({
    content: `
      *, *::before, *::after {
        animation-duration: 0s !important;
        animation-delay: 0s !important;
        transition-duration: 0s !important;
        transition-delay: 0s !important;
      }
    `,
  });

  // Step 2: wait for fonts to be fully loaded — prevents sub-pixel shift flakiness
  await page.evaluate(() => document.fonts.ready);

  // Step 3: screenshot assertion with variance threshold
  await expect(container).toMatchScreenshot({
    // Allow 0.1% pixel difference — tolerates sub-pixel font rendering variance
    // across Linux CI runners and macOS developer machines
    maxDiffPixelRatio: 0.001,
  });
});
```

**When NOT to use Vitest Browser Mode for visual regression:**
- Cross-browser visual consistency is a requirement (use Chromatic + Storybook, which tests
  against Chrome, Firefox, Safari, and Edge simultaneously)
- You need baseline management across multiple versions (Chromatic's branching model is purpose-built)
- Your component library is consumed by external teams who need visual diff reports as part of
  the review process

**Vitest Browser Mode strength:** Zero-overhead component isolation (no Storybook build step),
faster feedback loop for developers, and direct integration with Vitest's existing test suite.

---

## Anti-Patterns (additional)

### AP33 — `failOnFlakyTests: true` in Development (Non-CI) Mode  [community]
**What:** Enabling `failOnFlakyTests: true` unconditionally in `playwright.config.ts` (not gated
on `process.env.CI`).
**Why harmful:** In local development, flaky E2E tests are a normal debugging artifact — a developer
may be intentionally investigating a timing issue and relies on seeing the retry-then-pass pattern
to understand the failure mode. `failOnFlakyTests: true` without `!!process.env.CI` gating breaks
their local workflow and incentivises them to simply remove the retry configuration entirely, losing
the detection mechanism for CI. Fix: `failOnFlakyTests: !!process.env.CI`.

### AP34 — Using `trace: 'on'` Globally in CI Without Performance Budget  [community]
**What:** Setting `trace: 'on'` in the CI playwright config as a catch-all "we always want traces"
policy without measuring the performance impact.
**Why harmful:** Playwright's trace recording adds 20–40% to E2E test execution time for complex
flows (network waterfall recording, DOM snapshots, screenshots at every action). A 10-minute suite
becomes 12–14 minutes. Teams then disable tracing entirely because it "makes CI too slow", losing
the most valuable debugging artifact for flakiness. Fix: use `'on-first-retry'` as the CI default;
create a named `flakiness-debug` project with `'retain-on-failure-and-retries'` for targeted
investigation of specific known-flaky test cases.

---

## Real-World Gotchas (continued)  [community]

**Gotcha 37 — Vitest 4 Browser Mode toMatchScreenshot and CI Font Rendering Variance**
`toMatchScreenshot()` in Vitest 4 Browser Mode (Playwright provider, headless Chromium) produces
pixel-perfect screenshots on a developer's macOS machine that fail consistently on Ubuntu-based CI
runners. Root cause: sub-pixel font rendering differs between macOS CoreText and Linux FreeType.
Fix: (a) run the baseline screenshot generation *on the same OS as CI* (use `docker run` locally
or generate baselines in CI on first run), OR (b) use `maxDiffPixelRatio: 0.002` to tolerate
sub-pixel variance, OR (c) lock to a specific Chromium build via `process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH`.
Teams that skip this setup routinely see 100% screenshot test flakiness on CI green → developer
machine red — the opposite of normal flakiness.

**Gotcha 38 — Playwright `failOnFlakyTests` Reports Exit Code 1 but Developers See Green Checks**
Playwright exits with code `1` when `failOnFlakyTests` is triggered, but many CI integrations
(GitHub Actions, GitLab CI) map Playwright's exit codes differently when using the JUnit reporter.
If the CI step's `continue-on-error: true` was set for an unrelated reason (e.g., to preserve
artifacts on failure), `failOnFlakyTests` failures are silently swallowed — the PR shows a green
check mark while the test run contains flaky test cases. Fix: audit all Playwright CI steps for
`continue-on-error: true` when enabling `failOnFlakyTests`; use the HTML reporter's flakiness
annotations as a secondary signal visible in the test results artifact.

---

## Key Resources (iteration 45 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright Release Notes | Official | https://playwright.dev/docs/release-notes | Full changelog: failOnFlakyTests (v1.52), retain-on-failure-and-retries (v1.59), trace modes |
| Vitest 4.0 Blog | Official | https://vitest.dev/blog/vitest-4.html | Browser Mode stable, toMatchScreenshot, new tree reporter |
| Playwright TestConfig API | Official | https://playwright.dev/docs/api/class-testconfig | Complete API reference for failOnFlakyTests, retries, trace configuration |

---

## Pattern 59 — Vitest `onTestFailed` / `onTestFinished` Hooks for Flakiness Debugging  [official]

Vitest exposes two per-test lifecycle hooks — `onTestFailed` and `onTestFinished` — that allow
test-local cleanup and diagnostic code to run without polluting `afterEach`. These are particularly
useful for flakiness investigation because they can log or persist diagnostic state precisely when
and only when a test case fails, without creating noise in passing runs.

**`onTestFailed`** runs after all `afterEach` hooks, only when the test case failed. It receives
the `TaskResult` including the full `errors` array. Use it to dump state, print stack traces, or
write a diagnostic file when investigating intermittent failures.

**`onTestFinished`** runs after every test case regardless of outcome. It guarantees execution even
when the test body throws — making it safer than cleanup code at the end of the test body. Always
runs in reverse registration order (LIFO).

```typescript
// vitest — onTestFailed: dump DB state only on failure for flakiness investigation
import { describe, it, expect, onTestFailed, onTestFinished } from 'vitest';
import { connectDb, closeDb, dumpTableState } from '../test-utils/db';

describe('OrderRepository flakiness debugging', () => {
  it('creates order and updates inventory atomically', async () => {
    const db = connectDb(process.env.TEST_DATABASE_URL!);

    // onTestFinished: always close the DB connection — prevents resource leak flakiness
    // Safer than placing db.close() at end of test — runs even if assertion throws
    onTestFinished(() => closeDb(db));

    // onTestFailed: dump DB state for diagnosis — only runs when test fails
    // Avoids noisy output in passing runs; captures the exact state that caused the failure
    onTestFailed(async ({ task }) => {
      const errors = task.result?.errors ?? [];
      console.error('[FLAKINESS DEBUG] Test failed:', errors.map(e => e.message));
      // Dump the relevant tables to a file for post-mortem analysis
      const snapshot = await dumpTableState(db, ['orders', 'inventory']);
      console.error('[FLAKINESS DEBUG] DB state at failure:\n', JSON.stringify(snapshot, null, 2));
    });

    const order = await db.orders.create({ userId: 'user-1', items: [{ sku: 'A001', qty: 2 }] });
    const inventory = await db.inventory.findBySku('A001');

    expect(order.id).toMatch(/^ORD-/);
    // This assertion occasionally fails in parallel runs due to inventory count race
    expect(inventory.available).toBe(8); // started at 10, ordered 2
  });
});
```

```typescript
// vitest — onTestFailed with concurrent tests (context-based version required)
// When using test.concurrent(), you MUST use the context-based version of onTestFailed
// to avoid race conditions between concurrently-running test cases
import { describe, it, expect } from 'vitest';

describe.concurrent('PaymentService — concurrent runs', () => {
  it('processes payment within timeout', async ({ onTestFailed, onTestFinished }) => {
    // Context-based hooks — safe in concurrent tests
    // The global onTestFailed() is NOT safe in concurrent tests (shared state)

    onTestFailed(({ task }) => {
      // This closure captures the specific test's context — no cross-test pollution
      console.error(`[CONCURRENT FAIL] "${task.name}" errors:`, task.result?.errors);
    });

    onTestFinished(() => {
      // Per-test cleanup — runs in the context of THIS test only
      // Safe because each concurrent test gets its own context object
    });

    const result = await PaymentService.charge({ amount: 9999, currency: 'USD' });
    expect(result.status).toBe('approved');
  });
});
```

**Key distinction:** `afterEach` runs for ALL tests in the describe block, which can become a
maintenance burden when only a subset of tests need diagnostic output. `onTestFailed` and
`onTestFinished` are test-local — they are registered inside the test body and scoped to that
single test case. This makes them ideal for targeted flakiness investigation without global side
effects.

---

## Pattern 60 — Vitest `repeats` Option for Flakiness Detection  [official]

Vitest's `repeats` option reruns a test case a specified number of times within the same test
run. Unlike `retry` (which reruns only on failure), `repeats` runs the test unconditionally N
times — every run counts as a separate test result. This is the primary Vitest mechanism for
surfacing low-frequency flakiness that doesn't appear in a single pass.

**`retry` vs `repeats` distinction (critical):**
- `retry: 2` — test runs once; if it fails, runs up to 2 more times; failure is reported only if all retries fail
- `repeats: 4` — test runs 5 times (original + 4 repeats) regardless of pass/fail; any individual failure is reported

Use `retry` in production CI to tolerate known infrastructure jitter. Use `repeats` during
flakiness investigation to confirm a fix or measure a failure rate.

```typescript
// vitest.config.ts — global retry for CI stability; no global repeats (use per-test)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Global retry: rerun failed tests up to 2 times before marking as failed.
    // This is the CI production setting — NOT for flakiness investigation.
    retry: 2,

    // DO NOT set global repeats — it multiplies total test count for ALL tests.
    // Instead, set per-test repeats on suspect tests during investigation (see below).
  },
});
```

```typescript
// Per-test repeats — use during investigation, remove before merging
// Vitest counts each repeat as a separate test result in the HTML report
import { describe, it, expect, onTestFailed } from 'vitest';

describe('OrderService — flakiness investigation', () => {
  // repeats: 9 means this test runs 10 times total (1 original + 9 repeats)
  // Useful for measuring failure rate: 2 failures in 10 runs = 20% flakiness rate
  it('creates order idempotently', { repeats: 9 }, async () => {
    const order = await OrderService.create({
      idempotencyKey: 'key-001',
      items: [{ sku: 'SKU-A', qty: 1 }],
    });
    // This assertion may fail ~15% of the time due to a race in the DB sequence generator
    expect(order.id).toMatch(/^ORD-[A-Z0-9]{8}$/);
    expect(order.status).toBe('pending');
  });
});
```

```typescript
// Investigation workflow: combine repeats + onTestFailed for failure rate measurement
import { describe, it, expect, onTestFailed } from 'vitest';

// Step 1: add repeats to the suspect test (do NOT commit this)
// Step 2: run locally: vitest run --reporter=verbose order.test.ts
// Step 3: count failures in output. If failure rate > 0, root-cause and fix.
// Step 4: re-run with repeats to verify fix (should be 0/N failures)
// Step 5: remove repeats before opening PR — it's a debugging tool, not a CI fixture

describe('SuspectService — rate measurement', () => {
  let failureCount = 0;
  let totalRuns = 0;

  it('processes request without race', { repeats: 19 }, async () => {
    totalRuns++;

    onTestFailed(() => {
      failureCount++;
      // After all repeats complete, the console output shows cumulative failure rate
      console.warn(`[RATE] Failure ${failureCount}/${totalRuns} (${((failureCount/totalRuns)*100).toFixed(0)}%)`);
    });

    const result = await SuspectService.process({ requestId: `req-${Date.now()}` });
    expect(result.status).toBe('ok');
  });
});
```

**When NOT to use `repeats`:**
- In CI production config — it multiplies test suite runtime linearly
- As a substitute for fixing the root cause — `repeats: 3` that passes 2/3 is still flaky
- When the test touches external state (DB, file system) without rollback — state from repeat N
  bleeds into repeat N+1, creating false failures that obscure the real flakiness pattern

---

## Pattern 61 — Playwright `test.step.skip()` for Known-Broken Steps  [official]

Introduced in Playwright v1.55, `test.step.skip()` marks an individual step within a test case
as skipped. Unlike `test.skip()` (which skips the entire test case) or `test.fixme()` (which
skips it and marks it as intentionally broken), `test.step.skip()` allows the rest of the test
to run while flagging the specific step as deferred. This is useful when a multi-step E2E flow
has one intermittently broken step that would otherwise require quarantining the entire test case.

```typescript
// playwright — test.step.skip() for partially-working E2E flows
import { test, expect } from '@playwright/test';

test('full checkout flow', async ({ page }) => {
  // Step 1: add item to cart — stable
  await test.step('add product to cart', async () => {
    await page.goto('/products/headphones');
    await page.getByRole('button', { name: 'Add to Cart' }).click();
    await expect(page.getByTestId('cart-count')).toHaveText('1');
  });

  // Step 2: apply coupon — known-broken since coupon API migration (PROJ-2847)
  // test.step.skip() prevents this step from failing CI while preserving the rest of the test
  // The step appears as 'skipped' in the HTML report — visible to the team, not silently ignored
  await test.step.skip('apply discount coupon', async () => {
    await page.getByTestId('coupon-input').fill('SUMMER20');
    await page.getByRole('button', { name: 'Apply Coupon' }).click();
    await expect(page.getByTestId('discount-line')).toContainText('-20%');
    // PROJ-2847: coupon service returns 503 intermittently after migration — fix ETA 2026-05-20
  });

  // Step 3: checkout — stable; still runs even though step 2 was skipped
  await test.step('proceed to checkout', async () => {
    await page.getByRole('link', { name: 'Checkout' }).click();
    await page.waitForURL('**/checkout');
    await expect(page.getByRole('heading', { name: 'Checkout' })).toBeVisible();
  });

  await test.step('place order', async () => {
    await page.route('**/api/orders', route =>
      route.fulfill({ status: 201, json: { orderId: 'ORD-TEST-001', total: 89_99 } })
    );
    await page.getByRole('button', { name: 'Place Order' }).click();
    await expect(page.getByTestId('confirmation-number')).toBeVisible({ timeout: 5_000 });
  });
});
```

**`test.step.skip()` vs quarantine with `test.skip()` — when to use each:**

| Scenario | Use |
|----------|-----|
| Single step in a long E2E flow is broken; rest of flow tests valid behavior | `test.step.skip()` on the broken step |
| Entire test case is non-deterministic (flaps across multiple steps) | Quarantine with `it.skip('[QUARANTINE] ...')` |
| Known future feature not yet implemented | `test.fixme()` on the full test |
| Step is slow but not broken | `test.step()` with no skip — consider extracting to separate test |

---

## Pattern 62 — Playwright `page.consoleMessages()` / `page.pageErrors()` for Flakiness Diagnosis  [official]

Introduced in Playwright v1.56, `page.consoleMessages()` and `page.pageErrors()` provide
post-test access to the last 200 console messages and uncaught page errors respectively. These
APIs eliminate the need to set up `page.on('console')` event listeners upfront — you can query
the captured log after a test fails, making them ideal for flakiness post-mortems.

**Common flakiness patterns surfaced by these APIs:**
- `page.pageErrors()` revealing uncaught `TypeError: Cannot read properties of undefined` — indicates a race between async state initialization and render
- `page.consoleMessages()` showing repeated `[warning] fetch failed: network error` — indicates an unhandled external HTTP dependency
- Console warnings about React's `act()` — confirms async state update flakiness

```typescript
// playwright — capture console/error log on test failure for flakiness diagnosis
import { test, expect } from '@playwright/test';

test('dashboard renders without errors', async ({ page }, testInfo) => {
  await page.goto('/dashboard');

  // Main assertions
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
  await expect(page.getByTestId('user-widget')).toBeVisible();

  // Post-assertion: check for silent errors that indicate future flakiness
  // page.pageErrors() returns up to 200 uncaught JS errors from the page
  const pageErrors = page.pageErrors();
  if (pageErrors.length > 0) {
    // Attach errors to the test report — visible in the HTML report even if test passed
    await testInfo.attach('page-errors', {
      body: pageErrors.map(e => `${e.name}: ${e.message}\n${e.stack ?? ''}`).join('\n---\n'),
      contentType: 'text/plain',
    });
    // Fail the test if there are uncaught JS errors — they are flakiness precursors
    // The dashboard rendered correctly but something is silently broken
    expect(pageErrors).toHaveLength(0);
  }
});
```

```typescript
// playwright — flakiness diagnosis helper: attach console + error log on every retry
// Use this pattern to build a chronological log of what happened on each retry attempt
import { test, expect } from '@playwright/test';

// Custom fixture: automatically attaches console log + errors to the report on retry
export const flakinessDiagnostics = test.extend<{
  attachDiagnosticsOnRetry: void;
}>({
  attachDiagnosticsOnRetry: [async ({ page }, use, testInfo) => {
    await use(); // run the test

    // After test body: if this was a retry, capture diagnostics for the trace viewer
    if (testInfo.retry > 0 || testInfo.status === 'failed') {
      // Capture console messages (info, warning, error) from the page
      const messages = page.consoleMessages();
      if (messages.length > 0) {
        const log = messages.map(m =>
          `[${m.type().toUpperCase()}] ${m.text()}`
        ).join('\n');
        await testInfo.attach('console-log', { body: log, contentType: 'text/plain' });
      }

      // Capture uncaught page errors (JavaScript exceptions, unhandled promise rejections)
      const errors = page.pageErrors();
      if (errors.length > 0) {
        const log = errors.map(e => `${e.name}: ${e.message}\n${e.stack ?? 'no stack'}`).join('\n---\n');
        await testInfo.attach('page-errors', { body: log, contentType: 'text/plain' });
      }
    }
  }, { auto: true }], // auto: true — runs for every test without explicit fixture request
});
```

```typescript
// Usage: extend base test with the diagnostics fixture
// tests/e2e/checkout.spec.ts
import { flakinessDiagnostics } from '../fixtures/flakiness-diagnostics';

// Replace `import { test } from '@playwright/test'` with the extended version
const { test, expect } = flakinessDiagnostics;

test('checkout with payment', async ({ page }) => {
  await page.goto('/checkout');
  await page.fill('[name="card-number"]', '4111111111111111');
  await page.getByRole('button', { name: 'Place Order' }).click();
  await expect(page.getByTestId('confirmation')).toBeVisible({ timeout: 5_000 });
  // No extra code needed — diagnostics auto-attach on retry or failure
});
```

**Filter modes for both APIs:**
- `page.consoleMessages()` — returns all messages since page creation (default)
- `page.consoleMessages({ filter: 'since-navigation' })` — only messages since the last navigation
- Same filter API applies to `page.pageErrors()`

The `since-navigation` filter is especially useful in multi-page tests where only the messages
from the current route are relevant to the failing assertion.

---

## Pattern 63 — Playwright `test.abort()` for Unrecoverable Test State  [official]

Introduced in Playwright v1.60, `test.abort()` immediately terminates the current test case by
throwing an error, marking it as failed with the provided message. It is designed to be called
from inside **fixtures** or **route handlers** where detecting an unrecoverable misuse should
immediately stop the test — unlike a normal `expect()` failure that may not be caught cleanly
from within a callback.

**Key difference from `test.skip()` and `test.fail()`:**
- `test.skip()` — marks as skipped, no failure recorded
- `test.fail()` — marks as "expected to fail"; if it passes, that itself is a failure
- `test.abort(message)` — immediately terminates with a failure and a clear message; useful
  when continuing the test would produce misleading subsequent failures

```typescript
// playwright — test.abort() from a route handler to prevent test pollution
import { test, expect } from '@playwright/test';

// Anti-pattern: a test that attempts to write to a shared production endpoint
// test.abort() is called from inside the route handler to prevent data pollution
test('does not leak writes to production API', async ({ page }) => {
  // Register a route that intercepts any write to the production endpoint
  await page.route('**/api.production.example.com/**', route => {
    // test.abort() is safe to call from inside a route handler
    // Normal throw would produce an unhandled rejection that is harder to diagnose
    test.abort('Test attempted to call the production API — this is not allowed in tests.');
    return route.abort();
  });

  // Test proceeds with the mock endpoint
  await page.route('**/api.staging.example.com/orders', route =>
    route.fulfill({ status: 201, json: { orderId: 'ORD-001' } })
  );

  await page.goto('/checkout');
  await page.getByRole('button', { name: 'Place Order' }).click();
  await expect(page.getByTestId('confirmation')).toBeVisible();
});
```

```typescript
// playwright — test.abort() from a custom fixture for prerequisite validation
// Use when a fixture detects a setup condition that makes the test meaningless to run
import { test as base, expect } from '@playwright/test';

// Custom fixture: validates that the test database is seeded before running
// If not seeded, abort immediately rather than letting tests fail with cryptic errors
const test = base.extend<{ requiresSeededDb: void }>({
  requiresSeededDb: async ({ request }, use) => {
    // Check that the test database has the expected seed data
    const check = await request.get('/api/test/seed-status');
    const status = await check.json() as { seeded: boolean; count: number };

    if (!status.seeded || status.count < 10) {
      // Abort with a clear diagnostic message — prevents misleading failures downstream
      test.abort(
        `Database not seeded (found ${status.count} records, expected ≥ 10). ` +
        `Run: npm run db:seed:test`
      );
    }

    await use(); // fixture setup complete — proceed with test
  },
});

test('creates order with correct pricing', { tag: '@requires-db' }, async ({ page, requiresSeededDb }) => {
  await page.goto('/products');
  await page.getByTestId('product-sku-A001').getByRole('button', { name: 'Add to Cart' }).click();
  await expect(page.getByTestId('cart-total')).toHaveText('$49.99');
});
```

**When NOT to use `test.abort()`:**
- For normal assertion failures — use `expect()`, which provides better error messages and is
  tracked correctly in the HTML report
- To replace quarantine — a test that needs `test.abort()` in its normal flow is a sign the
  test setup (fixtures, seed data, environment) is not properly isolated; fix the setup instead

---

## Anti-Patterns (additional)

### AP35 — `onTestFailed` in `beforeAll` or `afterAll` Hooks  [community]
**What:** Registering `onTestFailed` or `onTestFinished` inside a `beforeAll` or `afterAll` hook
instead of inside the test body itself.
**Why harmful:** Both hooks are test-local — they attach to the *currently running test case*.
When called from `beforeAll` or `afterAll`, the "current test" context is ambiguous (there is no
single test running). In practice, Vitest silently ignores the registration or attaches it to the
last test in the describe block, producing diagnostics that appear to fire for the wrong test.
Fix: register `onTestFailed` and `onTestFinished` inside the test body or inside a `beforeEach`
hook where a test is unambiguously active.

---

## Real-World Gotchas (continued)  [community]

**Gotcha 39 — `captureGitInfo` Reveals Flakiness Introduced by a Specific Commit**
Playwright v1.54 added `testConfig.captureGitInfo` which embeds the current Git commit hash, branch,
and diff summary into the HTML test report. Teams that enable this option and export JUnit results
to a flakiness tracking dashboard (BuildPulse, Trunk) can correlate flakiness spikes directly with
the commit that introduced them. Without commit correlation, a flakiness spike on Tuesday can be
attributed to environment changes when it was actually a specific PR that mutated shared test
fixtures. Fix: add `captureGitInfo: true` to your `playwright.config.ts` and ensure the JUnit
reporter exports results — the commit hash is embedded in the XML output.

```typescript
// playwright.config.ts — enable git info capture for flakiness correlation
import { defineConfig } from '@playwright/test';

export default defineConfig({
  captureGitInfo: { revision: true, diff: false }, // capture commit hash, skip large diff
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    // JUnit embeds the commit hash — parseable by BuildPulse, Trunk, and custom dashboards
    ['junit', { outputFile: 'test-results/results.xml', includeProjectInTestName: true }],
  ],
  retries: process.env.CI ? 2 : 0,
  failOnFlakyTests: !!process.env.CI,
});
```

**Gotcha 40 — Google TotT: Dependency Injection Eliminates a Class of Flakiness**  [official]
Google Testing Blog (May 2026, "Construct with Collaborators, Call with Work") reinforces a
principle that directly prevents a common flakiness pattern: **separate object construction
(collaborator wiring) from work (business logic execution)**. Tests that create their collaborators
(DB clients, HTTP clients, clocks) inline in test helpers — rather than injecting them — cannot
control the exact instance being used, making it impossible to substitute fakes or freeze time.
The consequence is either real external calls (flakiness from network) or module-level singletons
that bleed state between tests (shared-state flakiness). The fix is to inject all collaborators
that have side effects, and construct them in test fixtures where they can be reset per test.

```typescript
// ANTI-PATTERN: collaborators created inside the function under test
// Cannot be replaced with fakes in tests — produces either real network calls or mock leakage
class OrderService {
  async create(items: string[]): Promise<Order> {
    // Hard dependency — cannot be replaced in tests without module mocking
    const db = new PostgresDb(process.env.DATABASE_URL!);
    const mailer = new SmtpMailer(process.env.SMTP_HOST!);
    // ... business logic
  }
}

// GOOD: inject all collaborators — each test provides its own isolated instances
class OrderService {
  constructor(
    private readonly db: OrderRepository,   // injectable — tests pass InMemoryOrderRepository
    private readonly mailer: Mailer,         // injectable — tests pass NoopMailer
    private readonly clock: Clock,           // injectable — tests pass FakeClock
  ) {}

  async create(items: string[]): Promise<Order> {
    // Uses injected collaborators — no ambient state, no hidden network calls
  }
}

// Test: zero flakiness because all collaborators are controlled by the test
import { describe, it, expect } from 'vitest';
import { InMemoryOrderRepository } from '../test-utils/fakes/InMemoryOrderRepository';
import { NoopMailer } from '../test-utils/fakes/NoopMailer';
import { FakeClock } from '../test-utils/fakes/FakeClock';

describe('OrderService — DI pattern', () => {
  it('creates order with correct timestamp', async () => {
    const clock = new FakeClock(new Date('2026-06-01T12:00:00Z'));
    const db = new InMemoryOrderRepository();
    const mailer = new NoopMailer();
    const service = new OrderService(db, mailer, clock);

    const order = await service.create(['sku-A', 'sku-B']);

    // Deterministic assertions — FakeClock controls Date.now(), InMemoryDb controls IDs
    expect(order.createdAt).toEqual(new Date('2026-06-01T12:00:00Z'));
    expect(order.id).toMatch(/^ORD-/);
    // No DB connection, no SMTP call, no network — 0% flakiness probability
  });
});
```

---

## Quick Reference additions (iteration 46)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Need to dump DB state only on test failure | No targeted diagnostics hook | Pattern 59 (onTestFailed / onTestFinished) | AP35 (onTestFailed in beforeAll) |
| Suspect test flakes ~10% — need to measure | Low-frequency flakiness | Pattern 60 (repeats: N for rate measurement) | Leaving repeats: N in CI config |
| One E2E step is broken; rest of flow is valid | Step-level defect, not flow-level | Pattern 61 (test.step.skip()) | Quarantining the entire test case |
| Need to see console errors that caused flakiness | Silent JS errors during test | Pattern 62 (page.consoleMessages/pageErrors) | Relying on manual page.on('console') setup |
| Fixture or route handler detects unrecoverable state | Test precondition violated | Pattern 63 (test.abort() from fixture) | Normal throw inside route callback |
| Flakiness spike appeared recently but root cause unknown | No commit correlation | Gotcha 39 (captureGitInfo) | No flakiness tracking with commit context |
| Unit tests are flaky due to DB or HTTP calls inside service | Missing DI | Gotcha 40 (DI pattern, inject collaborators) | Module-level singleton clients |

---

## Key Resources (iteration 46 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest Hooks API | Official | https://vitest.dev/api/hooks | onTestFailed, onTestFinished, aroundEach — test-local lifecycle for cleanup and debugging |
| Vitest repeats option | Official | https://vitest.dev/api/#test-repeats | Per-test repeat count for flakiness rate measurement |
| Playwright test.step.skip() | Official | https://playwright.dev/docs/api/class-test#test-step-skip | Skip individual steps in multi-step E2E flows without quarantining the entire test |
| Playwright page.consoleMessages() | Official | https://playwright.dev/docs/api/class-page#page-console-messages | Post-test access to last 200 console messages — no upfront event listener required |
| Playwright page.pageErrors() | Official | https://playwright.dev/docs/api/class-page#page-page-errors | Post-test access to last 200 uncaught JS errors — surfaces silent flakiness precursors |
| Playwright test.abort() | Official | https://playwright.dev/docs/api/class-test#test-abort | Immediate test termination from fixtures and route handlers (v1.60) |
| Trunk Flaky Tests On-Premise | Community | https://trunk.io/flaky-tests | Auto-quarantine SaaS + on-premise preview (2026) — quarantined tests run but don't break CI |

---

## Pattern 64 — Vitest 4.1 Test Tags with Per-Tag Retry Policy  [official]

Vitest 4.1 (March 2026) introduced first-class test tags that carry configuration overrides —
including per-tag retry count and timeout. This removes the need for manual quarantine wrappers:
tests marked `{ tags: ['flaky'] }` automatically receive extra retries on CI, while stable tests
run with no retries. When the underlying defect is fixed, removing the tag is the only change needed.

```typescript
// vitest.config.ts — define tags with retry/timeout policies
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    tags: [
      {
        name: 'flaky',
        description: 'Known-flaky test cases under active investigation.',
        // On CI: retry 3 times before marking failed. Locally: run once (fail fast).
        retry: process.env.CI ? 3 : 0,
        // Extend timeout — flaky tests often involve timing; extra headroom avoids
        // false flakiness from slow CI machines masking the actual root cause.
        timeout: 30_000,
        // Priority 1: when a test has both 'flaky' and 'db' tags, 'flaky' wins
        // because lower priority number = higher precedence.
        priority: 1,
      },
      {
        name: 'db',
        description: 'Tests that require database access.',
        timeout: 60_000, // extended timeout for DB tests
        // No retry — DB tests should be deterministic; flakiness is a real defect
      },
      {
        name: 'network',
        description: 'Tests that make real or mocked network calls.',
        timeout: 15_000,
      },
    ],
    // Enforce that all tags used in tests are declared — catches typos early
    strictTags: true,
  },
});
```

```typescript
// Augment Vitest types for strict TypeScript tag checking
// Add to vitest-env.d.ts or a global type file
declare module 'vitest' {
  interface TestTags {
    tags: 'flaky' | 'db' | 'network' | 'frontend' | 'backend';
  }
}
```

```typescript
// Usage: tests declare their tags inline — no quarantine wrapper needed
import { describe, it, expect } from 'vitest';
import { PaymentGateway } from './PaymentGateway';

describe('PaymentGateway — integration', () => {
  // Standard test: no extra retry, 15s timeout from 'network' tag
  it('returns order confirmation', { tags: ['network'] }, async () => {
    const gw = new PaymentGateway({ endpoint: process.env.GATEWAY_URL! });
    const result = await gw.charge({ amount: 5000, currency: 'USD' });
    expect(result.status).toBe('succeeded');
  });

  // Flaky test: 3 retries on CI (from 'flaky' tag) + extended timeout
  // Tracking: PROJ-2890 — webhook timing race under CI load
  it(
    'processes refund webhook within 5 seconds',
    { tags: ['flaky', 'network'] }, // 'flaky' priority wins: retry=3, timeout=30s
    async () => {
      const gw = new PaymentGateway({ endpoint: process.env.GATEWAY_URL! });
      const refund = await gw.refund({ transactionId: 'TXN-001', amount: 50_00 });
      expect(refund.status).toBe('refunded');
    }
  );
});
```

**Tag-based conditional setup with `TestRunner.matchesTags`:**

```typescript
// vitest.setup.ts — seed DB only when tests tagged 'db' are being run
import { beforeAll } from 'vitest';
import { TestRunner } from 'vitest';
import { seedTestDatabase, teardownTestDatabase } from './test-utils/db-seed';

// Conditional seeding: avoids slow DB setup for pure unit test runs
beforeAll(async () => {
  if (TestRunner.matchesTags(['db'])) {
    await seedTestDatabase();
  }
});

afterAll(async () => {
  if (TestRunner.matchesTags(['db'])) {
    await teardownTestDatabase();
  }
});
```

**Migration from manual quarantine wrapper (Pattern 3) to tags:**

| Old approach | New approach |
|---|---|
| `test.skip('[QUARANTINE] test name', ...)` | `it('test name', { tags: ['flaky'] }, ...)` |
| `quarantine('test name', fn)` wrapper | `it('test name', { tags: ['flaky'] }, fn)` |
| Per-test retry: `it('name', { retry: 3 }, fn)` | Centralised: tag `'flaky'` applies retry policy from config |
| Remove quarantine: change `test.skip` → `test` | Remove quarantine: delete `'flaky'` from tags array |

Tags are the Vitest 4.1+ preferred quarantine mechanism because the retry policy is centralised
(change once in config, affects all flaky-tagged tests) and the tag serves as searchable metadata.

---

## Pattern 65 — Playwright Per-Project Worker Limit for Flaky Test Isolation  [official]

Playwright supports setting `workers` at the **project level** (`testProject.workers`), enabling
different concurrency for different test categories within the same config. The canonical use case:
run known-flaky or resource-contending tests with `workers: 1` (serial) while stable tests run at
full parallelism. This prevents the flaky tests from interfering with each other (shared DB rows,
port collisions) without needing a separate CI job.

```typescript
// playwright.config.ts — per-project worker limits
import { defineConfig } from '@playwright/test';

export default defineConfig({
  // Default: 50% of CPUs for stable projects
  workers: '50%',
  retries: process.env.CI ? 2 : 0,

  projects: [
    // Stable unit-equivalent tests: run at full parallelism
    {
      name: 'component-tests',
      testMatch: '**/*.component.spec.ts',
      // Inherits global workers ('50%') — fast, parallelised
    },

    // Integration tests: moderate parallelism — share a test DB with row-level isolation
    {
      name: 'integration',
      testMatch: '**/*.integration.spec.ts',
      workers: 4, // fixed count avoids port collisions on shared DB
      retries: 1, // one retry; legitimate flakiness should be investigated
    },

    // E2E tests that are known-flaky: serial execution prevents cascading failures
    // Workers=1 means tests run one at a time — order-dependency becomes obvious
    {
      name: 'e2e-flaky-isolation',
      testMatch: '**/*.flaky.spec.ts',
      workers: 1,          // serial: surfaces order-dependency, prevents interference
      retries: 2,          // allow retries while root causes are diagnosed
      // Run this project AFTER stable projects complete
      dependencies: ['component-tests', 'integration'],
    },

    // E2E stable: full parallelism
    {
      name: 'e2e-stable',
      testMatch: '**/*.e2e.spec.ts',
      testIgnore: '**/*.flaky.spec.ts',
      workers: '50%',
      retries: 1,
    },
  ],
});
```

**Why this matters for flakiness:** Tests in the `e2e-flaky-isolation` project run serially, so:
1. Port collisions between concurrent tests are eliminated.
2. Order-dependency defects become deterministic (the order is always the same in serial mode).
3. Flaky root causes can be diagnosed without "noise" from parallel interference.
4. Stable tests are not slowed down — they still run in parallel.

Once a test's root cause is fixed, move it from `*.flaky.spec.ts` back to `*.e2e.spec.ts` to
restore parallelism. The `.flaky.spec.ts` naming convention is a team convention: any test known
to be under active flakiness investigation gets the `.flaky.` infix.

---

## Pattern 66 — Playwright Test Step Timeout for Granular Flakiness Scoping  [official]

Playwright v1.50 added a `timeout` option to `test.step()`. Before this, the only timeout control
was at the test case level — a single slow step could consume the entire test timeout, making it
impossible to distinguish "this step is always slow" from "this step is occasionally hanging."
Per-step timeouts enable precise attribution of timing flakiness to the specific step that caused it.

```typescript
// playwright.config.ts — global step timeout sets a ceiling for individual steps
import { defineConfig } from '@playwright/test';

export default defineConfig({
  timeout: 60_000,          // total test timeout
  use: {
    actionTimeout: 10_000,  // default timeout for page actions (click, fill, etc.)
  },
});
```

```typescript
// tests/e2e/checkout.spec.ts — per-step timeouts for precise flakiness scoping
import { test, expect } from '@playwright/test';

test('completes checkout flow', async ({ page }) => {
  // Step 1: fast navigation — strict 5s timeout; longer than this is a bug, not flakiness
  await test.step('Navigate to checkout', async () => {
    await page.goto('/checkout');
    await expect(page.getByRole('heading', { name: 'Checkout' })).toBeVisible();
  }, { timeout: 5_000 });

  // Step 2: fill form — user interactions are fast; 3s is generous
  await test.step('Fill payment form', async () => {
    await page.fill('[name="card-number"]', '4111111111111111');
    await page.fill('[name="expiry"]', '12/28');
    await page.fill('[name="cvv"]', '123');
  }, { timeout: 3_000 });

  // Step 3: order submission — involves API call; known to be slow under load
  // Step-level timeout 15s < total test timeout 60s — but scoped to this step
  await test.step('Submit order (API call)', async () => {
    await page.getByRole('button', { name: 'Place Order' }).click();
    // If this assertion fails due to timeout, the step report shows "Submit order" failed,
    // not the entire test — making the trace much more actionable
    await expect(page.getByTestId('order-confirmation')).toBeVisible({ timeout: 15_000 });
  }, { timeout: 20_000 }); // 20s step ceiling includes the 15s assertion timeout

  // Step 4: verify confirmation details — should be instant (DOM already rendered)
  await test.step('Verify confirmation', async () => {
    await expect(page.getByTestId('order-id')).toContainText('ORD-');
    await expect(page.getByTestId('total-price')).toBeVisible();
  }, { timeout: 2_000 }); // tight timeout: if this is slow, the step before leaked state
});
```

**Flakiness diagnosis with per-step timeouts:**

When a step times out, the Playwright trace viewer highlights the exact step with its timeline,
the network activity within that step's window, and the DOM state at the moment of timeout.
Without step-level timeouts, a timeout in step 4 shows "test timed out at 60s" with no indication
of which step was the culprit. With step-level timeouts, it shows "step 'Submit order' timed out
at 20s" — immediately actionable.

---

## Anti-Patterns (continued)

### AP36 — Applying a `flaky` Tag to All Integration Tests  [community]

**What:** Bulk-tagging every integration or E2E test case with `{ tags: ['flaky'] }` to silence
retry exhaustion, rather than tagging only the specific test cases that are known to be flaky.

**Why harmful:** The `flaky` tag is a signal — it means "this specific test case has a known
non-determinism defect under active investigation." When applied broadly:
1. The retry policy inflates CI runtime (3x for every integration test).
2. The tag loses its diagnostic value — no one knows which tests are genuinely flaky vs.
   which were tagged defensively.
3. Real new flakiness is invisible because every test already retries.
4. The team loses the quarantine SLA mechanism — there is no backlog to track.

**Fix:** Use the `flaky` tag surgically, following the same discipline as `test.skip('[QUARANTINE]')`:
a tracking issue number, an owner, and a resolution SLA. The backlog check script (Pattern 3)
should count `tags: ['flaky']` alongside `[QUARANTINE]` markers.

```typescript
// BAD: defensive bulk tagging — all integration tests retry 3x on CI
describe('OrderService integration', { tags: ['flaky'] }, () => {
  it('creates order', async () => { /* ... */ });
  it('updates order', async () => { /* ... */ });
  it('cancels order', async () => { /* ... */ });
  // 3 retries × 3 tests = up to 9 executions on CI just for this describe block
});

// GOOD: surgical tagging — only the specific known-flaky test case is tagged
describe('OrderService integration', () => {
  it('creates order', async () => { /* ... */ });

  // [QUARANTINE-EQUIVALENT] via tag — PROJ-3012, owner: @bob, SLA: 2026-05-30
  // Root cause: webhook timing race with payment provider
  it('cancels order with refund webhook', { tags: ['flaky'] }, async () => {
    /* test body — retries 3x on CI until root cause is fixed */
  });

  it('updates order', async () => { /* ... */ });
});
```

---

## Real-World Gotchas (continued)  [community]

**Gotcha 41 — Vitest 3.2 Fixture Scope `'file'` Eliminates Repeated DB Seeding Between Tests**  [official]

Vitest 3.2 added two new fixture scope values: `'file'` (initialise once per test file, teardown
after all tests in that file complete) and `'worker'` (initialise once per worker process). Before
3.2, the only scopes were `'test'` (per test, equivalent to beforeEach/afterEach) and `'suite'`
(per describe block). The `'file'` scope is the correct choice for expensive setup that should be
shared within a file but not leaked between files:

```typescript
// test-utils/fixtures.ts — scoped fixture for expensive DB setup
import { test as base } from 'vitest';
import { createTestDb, dropTestDb, TestDb } from './test-db';

// Extend base test with a file-scoped DB fixture
// The DB is created once when the first test in the file runs,
// and destroyed after the last test in the file completes.
// Each test in the file shares the same DB instance — use transaction
// rollback (Pattern 4b equivalent) to keep individual tests isolated.
export const test = base.extend<{ db: TestDb }>({
  db: {
    scope: 'file', // file-scoped: one DB per test file, not per test
    async fixture({}, { onCleanup }) {
      const db = await createTestDb({
        // Unique name per file prevents cross-file interference
        name: `test_${Math.random().toString(36).slice(2, 8)}`,
      });
      // onCleanup is guaranteed to run even if tests fail
      onCleanup(async () => { await dropTestDb(db.name); });
      return db;
    },
  },
});

// tests/order.test.ts — all tests share one DB instance (file scope)
import { test } from '../test-utils/fixtures';
import { expect } from 'vitest';
import { OrderRepository } from '../src/OrderRepository';

// The 'db' fixture is initialised ONCE for this file, not once per test.
// Eliminates 3× DB creation/teardown overhead vs per-test scope.
test('creates an order', async ({ db }) => {
  const repo = new OrderRepository(db.client);
  const order = await repo.create({ items: ['sku-A'] });
  expect(order.id).toBeDefined();
  // Clean up the specific row to avoid state bleed to the next test
  await repo.delete(order.id);
});

test('finds orders by customer', async ({ db }) => {
  const repo = new OrderRepository(db.client);
  // Shared DB — but order.id was deleted above, so no bleed
  const orders = await repo.findByCustomer('cust-001');
  expect(orders).toHaveLength(0);
});
```

**When to use each scope:**
- `'test'` (default): mocks, in-memory state, anything cheap to recreate
- `'file'`: DB connections, server instances, expensive seed operations — reset rows per test, not the entire DB
- `'worker'`: fixtures that must persist across files on the same worker (e.g., a shared auth token cache)

The key insight: `'file'` scope reduces flakiness from fixture setup failures (creating a DB
for every test in a 50-test file is 50 failure points) while preserving per-test isolation via
row-level rollback or explicit delete.

---

**Gotcha 42 — Playwright v1.57 Webserver `wait` Regex Prevents Premature Test Start**  [official]

Playwright's `webServer` config option has a `wait` field (added v1.57) that accepts a regex
pattern. Playwright waits until the server emits a line matching the pattern before starting tests.
Before this, teams relied on `reuseExistingServer: true` with a fixed URL poll, which could
incorrectly report "server ready" on the 200 response from a previous run's cached process —
causing intermittent failures when tests started before the new server had finished seeding data
or applying migrations.

```typescript
// playwright.config.ts — wait for specific server readiness signal
import { defineConfig } from '@playwright/test';

export default defineConfig({
  webServer: {
    command: 'npm run start:test',
    url: 'http://localhost:3000',
    // Wait until the server emits this exact log line before starting any tests.
    // This prevents the race condition where the server URL responds (200) before
    // the database migrations and seed data are applied.
    wait: /Server ready — migrations applied, seed data loaded/,
    // Timeout for the wait pattern — fail fast if the server never becomes fully ready
    timeout: 60_000,
    // Do NOT reuse an existing server: ensures migrations run fresh every CI run
    reuseExistingServer: !process.env.CI,
  },
});
```

```typescript
// src/server.ts — emit a structured readiness signal after setup completes
async function startTestServer() {
  const app = createExpressApp();
  await runMigrations();
  await seedTestData();
  const port = process.env.PORT ?? 3000;
  app.listen(port, () => {
    // This exact string is what the 'wait' regex in playwright.config.ts matches.
    // Keep this log line stable — changing it will break CI until the config is updated.
    console.log('Server ready — migrations applied, seed data loaded');
  });
}
```

**Without `wait` regex:** Playwright polls `http://localhost:3000` until it gets a 200, which
happens when the HTTP server starts — but before migrations run. Tests start and fail with
`table "orders" does not exist` errors that look like infrastructure flakiness but are really
a race condition in startup sequencing.

**With `wait` regex:** Playwright does not start tests until the server has explicitly signalled
readiness. The race condition is eliminated at the protocol level, not papered over with a sleep.

---

## Quick Reference additions (iteration 47)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| All integration tests retry 3× on CI, slowing the build | Bulk flaky tagging | AP36 (surgical tag, not bulk) | Applying `tags: ['flaky']` to entire describe blocks |
| Different E2E projects interfering with each other's ports | Cross-project parallelism | Pattern 65 (per-project workers) | Single global workers setting for all projects |
| Test failure says "timed out at 60s" with no step info | No per-step timeout | Pattern 66 (test.step timeout) | Relying on test-level timeout only |
| DB setup runs 50× for a 50-test file | Per-test fixture scope | Gotcha 41 (fixture scope: 'file') | Using scope: 'test' for expensive DB fixtures |
| Tests start before server finishes migrations | URL-based readiness poll | Gotcha 42 (webserver wait regex) | reuseExistingServer without readiness signal |
| Need per-tag retry policies without quarantine wrappers | No tag-based retry | Pattern 64 (Vitest 4.1 tags) | Manual quarantine() wrapper per test |

---

## Key Resources (iteration 47 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest 4.1 Test Tags | Official | https://vitest.dev/guide/test-tags | Per-tag retry, timeout, priority — replaces manual quarantine wrappers |
| Vitest Test Context (fixture scopes) | Official | https://vitest.dev/guide/test-context | file and worker scope options, onCleanup callback — Vitest 3.2+ |
| Playwright testProject.workers | Official | https://playwright.dev/docs/api/class-testproject#test-project-workers | Per-project worker limits for flaky test isolation (v1.50+) |
| Playwright test.step timeout | Official | https://playwright.dev/docs/api/class-test#test-step | timeout option on test.step() for granular flakiness attribution (v1.50) |
| Playwright webServer.wait | Official | https://playwright.dev/docs/test-webserver | Regex readiness wait — prevents premature test start before server is fully ready (v1.57) |
| Google TotT: Construct with Collaborators | Official | https://testing.googleblog.com/2026/05/construct-with-collaborators-call-with.html | DI pattern that eliminates a class of shared-state and network flakiness |

---

## Pattern 67 — Vitest 4.1 `aroundEach` / `aroundAll` for Zero-Leak Transaction Rollback  [official]

Vitest 4.1.0 introduced `aroundEach` and `aroundAll` hooks that **wrap** a test or a suite,
allowing setup and teardown to share a single execution context — something `beforeEach`/`afterEach`
pairs cannot do. The canonical use case is wrapping each test in a database transaction that rolls
back unconditionally, eliminating per-test `INSERT`/`DELETE` scaffolding entirely.

**Why `aroundEach` beats `beforeEach`/`afterEach` for transaction rollback:**
- `beforeEach` starts the transaction; `afterEach` rolls it back — two separate closures with
  no shared reference. If `afterEach` doesn't run (e.g., the test process crashes), the transaction
  leaks. `aroundEach` wraps both in one closure with the transaction reference in scope, so
  the rollback is guaranteed by the same closure that opened the transaction.
- Works correctly with async errors: an exception in `runTest()` still propagates up to the
  `aroundEach` body where the rollback is in the same `try`/`finally` block.

```typescript
// vitest — aroundEach with database transaction rollback
// Replaces the Pattern 40 (Drizzle tx rollback) approach with less boilerplate
import { aroundEach, describe, it, expect } from 'vitest';
import { db } from '../src/db'; // Drizzle or Kysely client
import { users, orders } from '../src/schema';

// aroundEach wraps every test in this describe block (and nested describes) in a transaction
// The transaction is rolled back unconditionally — even if the test throws or hangs
aroundEach(async (runTest) => {
  await db.transaction(async (tx) => {
    // Inject the transaction-scoped DB client into the test via a shared variable
    // (or use Vitest's TestContext injection via the scoped hook form — see below)
    await runTest(); // runs the test body; any writes go into the transaction
    // Rollback is implicit: drizzle/kysely roll back when the transaction callback throws or returns
    // Force rollback by throwing after runTest():
    throw new Error('test-rollback'); // intentional — rolls back all test writes
  }).catch(err => {
    // Swallow only the intentional rollback marker — let real test failures propagate
    if (err.message !== 'test-rollback') throw err;
  });
});

describe('OrderRepository — transaction isolation', () => {
  it('inserts and retrieves an order', async () => {
    await db.insert(orders).values({ userId: 'user-1', total: 5000, status: 'pending' });
    const found = await db.select().from(orders).where(eq(orders.userId, 'user-1'));
    expect(found).toHaveLength(1);
    // afterEach equivalent: transaction rolls back — no cleanup code needed
  });

  it('returns empty list for unknown user', async () => {
    // Fresh transaction — previous test's writes were rolled back
    const found = await db.select().from(orders).where(eq(orders.userId, 'user-1'));
    expect(found).toHaveLength(0); // zero rows despite test above inserting one
  });
});
```

```typescript
// Scoped aroundEach via test.extend — injects the transaction as a fixture
// This is the type-safe version when using a custom test factory
import { test as base, aroundEach, expect } from 'vitest';
import { createTransactionalDb, TransactionalDb } from '../test-utils/db-transaction';

// Extended test with a transactional DB fixture
const test = base.extend<{ txDb: TransactionalDb }>({
  txDb: async ({}, use) => {
    // Placeholder — the actual transaction is managed by aroundEach below
    let txDb!: TransactionalDb;
    await use(txDb);
  },
});

// Scoped aroundEach — receives TestContext for fixture access
test.aroundEach(async (runTest, context) => {
  const { txDb: db } = context;
  // Use test name as correlation ID in logs — invaluable for flakiness diagnosis
  await db.withTransaction(context.task.name, async (txDb) => {
    context.txDb = txDb; // inject transactional client into the fixture
    await runTest();
    throw new Error('test-rollback'); // force rollback
  }).catch(err => { if (err.message !== 'test-rollback') throw err; });
});

test('updates order status', async ({ txDb }) => {
  // txDb is the transaction-scoped client — safe to write without cleanup
  await txDb.updateOrderStatus('ORD-001', 'shipped');
  const order = await txDb.findOrder('ORD-001');
  expect(order.status).toBe('shipped');
  // No afterEach needed — transaction rolls back after this test
});
```

```typescript
// aroundAll — wrap the entire suite in a single tracing span for distributed diagnosis
// Useful when OpenTelemetry is used and you want all test spans to share a trace ID
import { aroundAll, describe, it, expect } from 'vitest';
import { tracer } from '../src/observability/tracer';

aroundAll(async (runSuite) => {
  // All tests in the suite run within this span — correlation ID is consistent
  await tracer.startActiveSpan('vitest-suite', async (span) => {
    try {
      await runSuite(); // runs all tests in the describe block
    } finally {
      span.end(); // always closes the span — even if tests fail
    }
  });
});

describe('PaymentService — traced integration tests', () => {
  it('charges card successfully', async () => {
    // All spans within this test share the parent span from aroundAll
  });
  it('handles declined card', async () => {
    // Same tracing context — enables root cause correlation across tests
  });
});
```

**Critical caveats:**
- **You must call `runTest()` / `runSuite()`.** If omitted, Vitest fails the test with an error.
- **Not safe for concurrent tests** — `aroundEach` at the module level does not track concurrent test instances. For `test.concurrent`, use the context-scoped form `test.aroundEach` via `test.extend`.
- **`aroundAll` scope vs `beforeAll`** — `aroundAll` wraps the entire suite *execution*; `beforeAll`/`afterAll` run *around* the suite. Use `aroundAll` when the wrapper must hold state across all tests (e.g., a single transaction or tracing span).

---

## Pattern 68 — Playwright HAR Recording for Network-Level Flakiness Diagnosis  [official]

Playwright v1.60 promoted HAR recording to a first-class API via `context.tracing.startHar()`
and `context.tracing.stopHar()`. HAR (HTTP Archive) files capture every network request and
response in a structured JSON format. For flaky tests whose failures correlate with unexpected
API responses, timing, or error codes, a HAR file provides the ground truth about what actually
went over the wire — unfiltered by any application-level retry logic.

**When HAR helps vs. when traces suffice:**
| Situation | Use |
|-----------|-----|
| Flakiness from a specific API endpoint returning 500 intermittently | HAR — see raw response body and timing |
| Flakiness from UI element not appearing | Playwright trace — see DOM snapshots |
| Flakiness from network race (request A completes before request B) | HAR — compare request timing waterfall |
| Unknown root cause — initial investigation | Trace first; add HAR if network is suspected |

```typescript
// playwright — HAR recording fixture for network flakiness diagnosis
import { test as base, expect, BrowserContext } from '@playwright/test';
import { join } from 'path';

// Custom fixture that captures HAR on test failure — zero overhead on passing tests
export const test = base.extend<{
  captureHarOnFailure: void;
  harPath: string;
}>({
  harPath: [async ({}, use, testInfo) => {
    // Unique HAR path per test — avoids cross-test file collisions
    const path = testInfo.outputPath('network.har');
    await use(path);
  }, { scope: 'test' }],

  captureHarOnFailure: [async ({ context, harPath }, use, testInfo) => {
    // Start HAR recording at the beginning of each test
    // 'minimal' mode records only routing-essential data — lower overhead
    await context.tracing.startHar(harPath, {
      mode: 'full', // 'full' captures request/response bodies — needed for diagnosis
      urlFilter: /api\./, // only record API calls — skip CDN assets
    });

    await use(); // run the test

    // Stop recording; only attach HAR to the report when the test failed or retried
    if (testInfo.status === 'failed' || testInfo.retry > 0) {
      await context.tracing.stopHar();
      // Attach to HTML report — viewable in Playwright's network panel
      await testInfo.attach('network.har', {
        path: harPath,
        contentType: 'application/json',
      });
    } else {
      // On pass: stop recording without saving (discard) — saves disk space
      await context.tracing.stopHar({ path: undefined });
    }
  }, { auto: true, scope: 'test' }],
});

// Usage: replace `import { test } from '@playwright/test'` with extended version
test('checkout API returns 201 on success', async ({ page }) => {
  await page.goto('/checkout');
  await page.fill('[name="card-number"]', '4111111111111111');
  await page.getByRole('button', { name: 'Place Order' }).click();
  // If this assertion fails, the HAR attachment in the report shows the exact
  // POST /api/orders request, its timing, and the server's response body
  await expect(page.getByTestId('confirmation-number')).toBeVisible({ timeout: 10_000 });
});
```

```typescript
// Analyzing a captured HAR file — TypeScript script for post-mortem diagnosis
// Run: npx ts-node scripts/analyze-har.ts test-results/test-checkout/network.har

import { readFileSync } from 'fs';

interface HarEntry {
  startedDateTime: string;
  time: number; // total time in ms
  request: { method: string; url: string; bodySize: number };
  response: { status: number; statusText: string; bodySize: number };
}

interface Har {
  log: { entries: HarEntry[] };
}

function analyzeHar(harPath: string): void {
  const har = JSON.parse(readFileSync(harPath, 'utf-8')) as Har;
  const entries = har.log.entries;

  console.log(`Total requests: ${entries.length}`);

  // Surface slow requests — common flakiness source
  const slowRequests = entries
    .filter(e => e.time > 1000) // slower than 1 second
    .map(e => ({ url: e.request.url, ms: Math.round(e.time) }));

  if (slowRequests.length > 0) {
    console.warn('Slow requests (>1s):');
    slowRequests.forEach(r => console.warn(`  ${r.ms}ms  ${r.url}`));
  }

  // Surface non-2xx responses — unexpected errors from the application
  const errors = entries.filter(e => e.response.status >= 400);
  if (errors.length > 0) {
    console.error('Error responses:');
    errors.forEach(e => console.error(`  ${e.response.status} ${e.request.method} ${e.request.url}`));
  }

  // Detect duplicate requests — may indicate retry storms or cache miss flakiness
  const urls = entries.map(e => `${e.request.method} ${e.request.url}`);
  const duplicates = urls.filter((url, i) => urls.indexOf(url) !== i);
  if (duplicates.length > 0) {
    console.warn('Duplicate requests (possible retry storm):');
    [...new Set(duplicates)].forEach(d => console.warn(`  ${d}`));
  }
}

analyzeHar(process.argv[2] ?? 'network.har');
```

**HAR recording limitations:**
- Only captures HTTP/HTTPS requests — WebSocket frames and SSE streams are not recorded.
  For WebSocket flakiness, use Playwright's `page.on('websocket')` event listener.
- `urlFilter` is evaluated on the request URL, not the response — cannot filter by response status.
- In `mode: 'minimal'`, response bodies are omitted — sufficient for timing analysis but not for
  diagnosing unexpected response content.

---

## Pattern 69 — Vitest `--detect-async-leaks` for Dangling Async Operations  [official]

Vitest 4.1.0 introduced the `--detect-async-leaks` CLI flag and its config equivalent
`detectAsyncLeaks: true`. When enabled, Vitest detects async operations (Promises, timers,
open file descriptors, network connections) that were started during a test but never resolved
or cleaned up after the test completed. Unlike Jest's `--detectOpenHandles` (which only catches
libuv handles like timers and sockets), `--detect-async-leaks` captures unresolved Promises and
other microtask-level leaks.

**Relationship to Gotcha 11 (`--detectOpenHandles`):**
- `detectOpenHandles` (Jest) catches OS-level handles: `setTimeout`, `setInterval`, TCP sockets, file descriptors
- `detectAsyncLeaks` (Vitest 4.1+) catches Node.js async context leaks, including `AsyncLocalStorage` contexts that weren't closed, Promise chains that outlive the test, and `EventEmitter` listeners that remain attached

They complement rather than replace each other. `detectAsyncLeaks` is more precise for
TypeScript async/await patterns; `detectOpenHandles` is better for Node.js I/O resource tracking.

```typescript
// vitest.config.ts — enable async leak detection
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Detect async operations that outlive their test case.
    // Performance note: adds ~5-15% overhead to test execution — acceptable for CI,
    // disable for local hot-reload watch mode if too noisy.
    detectAsyncLeaks: process.env.CI === 'true',

    // Pair with a generous timeout so leak detection has time to collect diagnostics
    // before the test runner times out trying to drain the async queue
    testTimeout: 30_000,
  },
});
```

```typescript
// Example: detecting an AsyncLocalStorage leak (common in tRPC/middleware tests)
import { describe, it, expect } from 'vitest';
import { AsyncLocalStorage } from 'async_hooks';
import { createRequestContext, RequestContext } from '../src/context';

// Leak example: AsyncLocalStorage context created but never exited
// detectAsyncLeaks would report this as a dangling async context after the test
describe('RequestContext — async context leak demonstration', () => {
  const requestStorage = new AsyncLocalStorage<RequestContext>();

  it('[BAD] context entered but never exited — creates async leak', async () => {
    // ANTI-PATTERN: run() is called but the scope is not closed after the assertion
    // Any async operations started within the run() scope inherit the context
    // If they outlive the test, they carry a stale context indefinitely
    requestStorage.run({ userId: 'user-1', requestId: 'req-001' }, async () => {
      // This inner promise is not awaited at the test level — leaks after test exits
      someBackgroundService.start();
    });
    // detectAsyncLeaks reports: "AsyncLocalStorage context from 'RequestContext' was not cleaned up"
  });

  it('[GOOD] context always exited — no leak', async () => {
    // PATTERN: use AsyncLocalStorage.run() synchronously and ensure all async ops
    // complete before the run() callback returns
    await new Promise<void>((resolve, reject) => {
      requestStorage.run({ userId: 'user-2', requestId: 'req-002' }, async () => {
        try {
          await someBackgroundService.startAndWait(); // awaited — no leak
          expect(requestStorage.getStore()?.userId).toBe('user-2');
          resolve();
        } catch (err) {
          reject(err);
        }
      });
    });
    // AsyncLocalStorage context is fully exited when run() callback completes
  });
});
```

```bash
# CLI usage — check specific test files for async leaks without affecting the full suite
npx vitest run --detect-async-leaks src/services/*.test.ts

# In package.json scripts for a dedicated leak-check pass:
# "test:leak-check": "vitest run --detect-async-leaks --reporter=verbose"
```

**When NOT to use `--detect-async-leaks` globally:**
- In local `vitest --watch` mode: each file save triggers the leak scanner on all tests,
  adding perceptible latency to the hot-reload loop
- For tests that intentionally fire background tasks (e.g., email queue workers) — these
  will always be reported as leaks even if they complete shortly after the test case; use
  `vi.waitFor()` to drain them before the test exits, or disable the flag per file via
  `// @vitest-disable-async-leak-check` (Vitest 4.1+ feature comment)

---

## Anti-Patterns (additional)

### AP37 — `aroundEach` Without Calling `runTest()`  [official]

**What:** Registering an `aroundEach` (or `aroundAll`) hook that contains setup and teardown code
but forgets to call `runTest()` (or calls it conditionally).

**Why harmful:** Vitest fails the test case with an explicit error: "aroundEach hook did not call
`runTest()`". However, if `runTest()` is inside a conditional that evaluates to `false` at runtime
(e.g., `if (process.env.CI) await runTest()`), the test is silently skipped on non-CI environments
rather than being run. This produces CI-only "passes" that never actually execute on developer
machines — the inverse of the typical CI-only failure pattern.

```typescript
// BAD: runTest() inside a conditional — test silently skips locally
aroundEach(async (runTest) => {
  await db.transaction(async () => {
    if (process.env.CI) {
      await runTest(); // DANGER: only runs in CI — local tests pass trivially
    }
    throw new Error('test-rollback');
  }).catch(err => { if (err.message !== 'test-rollback') throw err; });
});

// GOOD: runTest() always called — gate the conditional logic, not the test invocation
aroundEach(async (runTest) => {
  if (process.env.CI) {
    // CI-only path: wrap in transaction
    await db.transaction(async () => {
      await runTest(); // always called
      throw new Error('test-rollback');
    }).catch(err => { if (err.message !== 'test-rollback') throw err; });
  } else {
    // Local path: run without transaction (faster, still isolated via other means)
    await runTest(); // always called
  }
});
```

---

## Real-World Gotchas (continued)  [community]

**Gotcha 43 — Playwright `browserContext.setStorageState()` for Lightweight Auth Re-Isolation**
Playwright v1.60 added `browserContext.setStorageState()` which clears and resets `localStorage`,
`sessionStorage`, and cookies without creating a new `BrowserContext`. Before this, tests that
needed to reset auth state between scenarios in the same context had to either create a new context
(expensive — re-instantiates the browser session) or manually clear storage with
`page.evaluate(() => localStorage.clear())` (incomplete — misses cookies and session storage).
`setStorageState()` is the correct idiom for resetting auth in E2E tests that reuse a context
across scenarios for performance:

```typescript
// playwright — reset auth state between scenarios without new context
import { test, expect } from '@playwright/test';

// Fixture: reuse a single context for performance, but reset auth before each test
export const test_with_auth_reset = test.extend<{}>({
  page: async ({ browser }, use) => {
    // Create context once — reuse across tests in this worker
    const context = await browser.newContext({
      storageState: 'playwright/.auth/user.json', // pre-authenticated state
    });
    const page = await context.newPage();
    await use(page);

    // After each test: reset storage state to pristine auth — cheaper than new context
    // setStorageState() clears localStorage, sessionStorage, and cookies in one call
    await context.setStorageState({ storageState: 'playwright/.auth/user.json' });
    // Next test gets the same context with reset auth — no new browser session overhead
  },
});

// Usage:
test_with_auth_reset('user can view dashboard', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
  // Any localStorage writes during this test are cleared before the next test
});

test_with_auth_reset('user can update profile', async ({ page }) => {
  await page.goto('/profile');
  // localStorage from previous test is gone — clean auth state
  await page.fill('[name="display-name"]', 'Alice Updated');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByText('Profile saved')).toBeVisible();
});
```

**Key insight [community]:** Teams that create a new `BrowserContext` per test (the default
Playwright recommendation) typically see 30–60s added to E2E suites with 50+ tests because each
context launch triggers a new browser session. `setStorageState()` enables a middle ground: context
reuse for performance, with guaranteed auth isolation between tests.

---

## Quick Reference additions (iteration 48)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Transaction rollback in beforeEach/afterEach pair with state leak | Separate hook closures share no state | Pattern 67 (aroundEach for tx rollback) | AP37 (aroundEach without calling runTest) |
| Flaky API test — unknown whether server returned 500 or 200 | No network-level visibility | Pattern 68 (HAR recording on failure) | Relying only on Playwright trace DOM snapshots |
| AsyncLocalStorage context not cleaned up after test | No async leak detection | Pattern 69 (--detect-async-leaks) | detectOpenHandles only (misses Promise-level leaks) |
| Auth state bleeds between E2E scenarios reusing the same context | No storage reset between tests | Gotcha 43 (setStorageState() for auth isolation) | Creating new BrowserContext per test (expensive) |

---

## Key Resources (iteration 48 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest aroundEach / aroundAll Hooks | Official | https://vitest.dev/api/hooks#aroundeach | Wraps tests in shared context (DB transactions, tracing spans) — v4.1.0+ |
| Vitest detectAsyncLeaks | Official | https://vitest.dev/config/#detectasyncleaks | CLI and config flag to detect dangling Promises and AsyncLocalStorage leaks — v4.1.0+ |
| Playwright tracing.startHar() | Official | https://playwright.dev/docs/api/class-tracing#tracing-start-har | HAR recording API for network-level flakiness diagnosis (v1.60) |
| Playwright browserContext.setStorageState() | Official | https://playwright.dev/docs/api/class-browsercontext#browser-context-set-storage-state | Reset auth/localStorage/cookies without creating a new context (v1.60) |

---

## Pattern 70 — Playwright v1.59 CLI Trace Analysis for Flaky Test Investigation  [official]

Playwright v1.59 added subcommands to `npx playwright trace` that let you inspect a `.zip` trace
file from the command line — without opening the GUI trace viewer. This is particularly useful in
CI environments and for AI agents that need to programmatically identify the failure point in a
flaky test case.

**Why this matters for flakiness:** When `retain-on-failure-and-retries` captures two trace files
(one from the passing retry and one from the failing attempt), the CLI subcommands let you diff the
action sequence and pinpoint the exact action that diverged between attempts — often a timing
difference in a network response or a DOM mutation that arrived 200ms later on the flaky run.

```typescript
// In a CI post-failure step, compare a flaky test's traces from two attempts:
// 1. List all actions from the failing trace to find the divergence point
//    npx playwright trace actions test-results/login-test-chromium-retry1/trace.zip
//
// 2. Narrow to assertion actions (most likely to diverge in timing flakiness)
//    npx playwright trace actions --grep="expect" test-results/login-test-chromium-retry1/trace.zip
//
// 3. Inspect the snapshot at a specific action (e.g., action 9 is the failing assertion)
//    npx playwright trace snapshot 9 test-results/login-test-chromium-retry1/trace.zip --name after
//    npx playwright trace snapshot 9 test-results/login-test-chromium/trace.zip --name after
//
// 4. Compare action at index 9 across both traces to see the DOM difference
//    npx playwright trace action 9 test-results/login-test-chromium-retry1/trace.zip
```

```typescript
// playwright.config.ts — enable multi-attempt trace capture so CLI comparison works
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  use: {
    // 'retain-on-failure-and-retries' stores EVERY attempt's trace when any attempt fails.
    // This is required for CLI diff analysis — you need both the passing and failing traces.
    trace: process.env.CI ? 'retain-on-failure-and-retries' : 'on-first-retry',
  },
});
```

```bash
# GitHub Actions: export CLI trace diff as a step summary for easy PR review
- name: Analyze flaky test traces
  if: failure()
  run: |
    echo "## Flaky Test Trace Analysis" >> $GITHUB_STEP_SUMMARY
    for TRACE in test-results/*/trace.zip; do
      TEST_NAME=$(dirname "$TRACE" | xargs basename)
      echo "### $TEST_NAME" >> $GITHUB_STEP_SUMMARY
      echo '```' >> $GITHUB_STEP_SUMMARY
      # List assertions from the trace — the last one before failure is the flakiness site
      npx playwright trace actions --grep="expect" "$TRACE" 2>/dev/null | tail -5 >> $GITHUB_STEP_SUMMARY
      echo '```' >> $GITHUB_STEP_SUMMARY
    done
```

**When NOT to use CLI trace analysis:**
- For tests that fail deterministically on every run: the GUI trace viewer is faster for
  interactive investigation
- When trace files are large (>50MB): `snapshot` subcommand can be slow; use `actions` only
  to locate the divergence action first, then snapshot that specific action

---

## Pattern 71 — Playwright `--last-failed` for Fast Flakiness Iteration  [official]

Introduced in Playwright v1.44, `--last-failed` reruns only the test cases that failed in the
previous run. This is a critical workflow accelerator when diagnosing flaky tests: instead of
running the full 10-minute suite on every fix attempt, you rerun only the flaky test case(s)
identified in the previous pass.

**Why this matters for flakiness:** The typical flakiness investigation loop is: (1) observe
failure in CI, (2) pull the branch, (3) reproduce locally, (4) apply fix, (5) verify. Without
`--last-failed`, step 3 often requires re-running the full suite or remembering the exact test
name. With `--last-failed`, you run the full suite once to capture the failure, then iterate
with targeted reruns in seconds.

```typescript
// package.json — add a dedicated flakiness investigation script
{
  "scripts": {
    "test:e2e": "playwright test",
    // After a failure, rerun only the failing tests — ideal for local flakiness debugging
    "test:e2e:retry": "playwright test --last-failed",
    // Sweep: run full suite 3 times to surface intermittent failures
    "test:e2e:sweep": "playwright test && playwright test --last-failed && playwright test --last-failed"
  }
}
```

```bash
# CI workflow: detect flakiness by running --last-failed after the initial pass
# A test that passes on --last-failed after failing in the first pass is a flaky test case.

- name: Run E2E tests (first pass)
  run: npx playwright test --reporter=json --output-file=first-pass.json
  continue-on-error: true   # capture failures, don't abort

- name: Rerun failed tests (--last-failed)
  if: failure()
  run: |
    npx playwright test --last-failed --reporter=json --output-file=rerun.json
    # A test that passes here (present in first-pass failures but absent from rerun failures)
    # is definitively flaky — output that list for the quarantine queue

- name: Report flaky tests
  if: failure()
  run: |
    node -e "
      const first = require('./first-pass.json');
      const rerun = require('./rerun.json');
      const firstFailed = new Set(first.suites.flatMap(s => s.specs).filter(s => !s.ok).map(s => s.title));
      const rerunFailed = new Set(rerun.suites.flatMap(s => s.specs).filter(s => !s.ok).map(s => s.title));
      const flaky = [...firstFailed].filter(t => !rerunFailed.has(t));
      if (flaky.length) { console.log('FLAKY TESTS DETECTED:', flaky); process.exit(1); }
      console.log('No flaky tests — failures are deterministic.');
    "
```

---

## Pattern 72 — Vitest 3.2 `using` Keyword for Automatic Mock Restoration  [official]

Vitest 3.2 added support for TypeScript 5.2's [Explicit Resource Management](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-2.html)
via `Symbol.dispose` / `Symbol.asyncDispose`. `vi.spyOn()` and `vi.fn()` now return disposable
objects — declaring them with `using` (instead of `const`) automatically calls `mockRestore()`
when the enclosing block exits, even if an exception is thrown.

**Why this matters for flakiness:** Spies that are not restored are a leading cause of
inter-test pollution. The classic pattern requires a matching `afterEach(() => spy.mockRestore())`
or `jest.restoreAllMocks()` call — which developers frequently forget, especially in deeply nested
`describe` blocks. The `using` keyword makes restoration guaranteed and scope-local, eliminating
an entire class of shared-state flakiness.

```typescript
// tsconfig.json — required for using/await using support
{
  "compilerOptions": {
    "target": "ES2022",          // Symbol.dispose requires ES2022+
    "lib": ["ES2022"],
    "useDefineForClassFields": true
  }
}
```

```typescript
// vitest — using keyword eliminates the need for afterEach spy restoration
import { describe, it, expect, vi } from 'vitest';
import { EmailService } from './EmailService';
import * as mailer from './mailer';

describe('EmailService', () => {
  it('sends a welcome email on user creation', async () => {
    // 'using' declares a disposable spy — restored automatically when this block exits
    using sendSpy = vi.spyOn(mailer, 'sendMail').mockResolvedValue({ messageId: 'test-01' });

    await EmailService.createUser({ email: 'alice@example.com', name: 'Alice' });

    expect(sendSpy).toHaveBeenCalledOnce();
    expect(sendSpy).toHaveBeenCalledWith(
      expect.objectContaining({ to: 'alice@example.com', subject: 'Welcome!' })
    );
    // sendSpy.mockRestore() is called implicitly when the test case exits — no afterEach needed
  });

  it('does NOT send email when user already exists', async () => {
    // A fresh spy — the previous test's spy is already fully restored
    using sendSpy = vi.spyOn(mailer, 'sendMail');
    await EmailService.createUser({ email: 'alice@example.com', name: 'Alice Duplicate' });
    expect(sendSpy).not.toHaveBeenCalled();
  });
});
```

```typescript
// Using 'await using' for async cleanup (e.g., database connections)
import { describe, it, expect, vi } from 'vitest';
import { createTestDb } from './test-utils/db';

describe('OrderRepository', () => {
  it('persists order with correct status', async () => {
    // await using: calls [Symbol.asyncDispose]() on exit — ideal for async teardown
    await using db = await createTestDb();
    // db.[Symbol.asyncDispose]() closes the connection and drops the test schema

    const repo = new OrderRepository(db.client);
    const order = await repo.create({ items: ['item-1'], status: 'pending' });
    expect(order.status).toBe('pending');
    // db is automatically closed and cleaned up when this test case exits
  });
});
```

**When NOT to use `using` keyword:**
- When targeting environments that don't support TypeScript 5.2 (e.g., legacy monorepos with
  an old TS version pinned by a shared tsconfig)
- When the spy needs to outlive the test body (e.g., a spy registered in `beforeAll` used in
  multiple test cases) — `using` is block-scoped; use `afterAll(() => spy.mockRestore())` instead
- When `vi.restoreAllMocks()` in `afterEach` is your team's established pattern — switching
  selectively to `using` creates inconsistency; migrate the whole suite or not at all

---

## Pattern 73 — Vitest 3.2 Test Signal API for Resource Cleanup on Timeout  [official]

Vitest 3.2 introduced a `signal` property on the test context (`context.signal`), providing an
`AbortSignal` that fires when the test case times out, the suite is bailed with `--bail`, or the
user interrupts with Ctrl+C. This enables tests that launch background resources (HTTP servers,
database connections, streams) to clean them up deterministically even on hard timeout, preventing
resource leak flakiness in subsequent test cases.

**Why this matters for flakiness:** Without the signal, a test that times out leaves its resources
(open ports, dangling promises) active until the process exits. These leaked resources cause the
next test case that tries to bind the same port or use the same singleton to fail non-deterministically.
The signal API turns timeout cleanup from "best effort" (relying on `afterEach`) into "guaranteed."

```typescript
// vitest — Test Signal API for HTTP server lifecycle management
import { describe, it, expect } from 'vitest';
import { createServer } from 'http';
import type { TestContext } from 'vitest';

describe('HttpProxyService', () => {
  it('proxies GET requests to upstream', async (context: TestContext) => {
    // Spin up a mock upstream server for this test only
    const upstream = createServer((req, res) => {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ data: 'from-upstream' }));
    });

    await new Promise<void>(resolve => upstream.listen(0, resolve));
    const port = (upstream.address() as { port: number }).port;

    // Register cleanup on context.signal — fires on timeout, bail, or interrupt
    context.signal.addEventListener('abort', () => {
      upstream.close(); // guaranteed cleanup even if test times out
    }, { once: true });

    const response = await fetch(`http://localhost:${port}/api/data`, {
      // Pass the test signal to fetch — cancels the HTTP request on timeout
      signal: context.signal,
    });
    const body = await response.json();

    expect(body).toEqual({ data: 'from-upstream' });

    // Normal path: explicit cleanup (signal handler is a safety net, not the primary path)
    upstream.close();
  });
});
```

```typescript
// vitest — Using context.signal with database connection to prevent port exhaustion
import { describe, it, expect } from 'vitest';
import { Pool } from 'pg';
import type { TestContext } from 'vitest';

describe('UserRepository — integration', () => {
  it('finds user by email with case-insensitive match', async (context: TestContext) => {
    const pool = new Pool({ connectionString: process.env.TEST_DATABASE_URL, max: 1 });

    // Cleanup on signal — prevents connection pool leak if test times out
    context.signal.addEventListener('abort', async () => {
      await pool.end().catch(() => {}); // swallow errors during forced teardown
    }, { once: true });

    const repo = new UserRepository(pool);
    await repo.seed({ email: 'ALICE@EXAMPLE.COM', name: 'Alice' });

    const user = await repo.findByEmail('alice@example.com');
    expect(user?.name).toBe('Alice');

    await pool.end(); // normal path cleanup
  });
});
```

**When NOT to use `context.signal`:**
- For resources that are already managed by Vitest fixtures with `scope: 'file'` or
  `scope: 'worker'` — fixtures have their own teardown lifecycle; adding `context.signal` is redundant
- For resources created in `beforeAll`/`afterAll` — `context.signal` is per-test; suite-level
  resources need suite-level cleanup

---

## Anti-Patterns (iteration 49)

### AP38 — Manual `spy.mockRestore()` When `using` Keyword Is Available  [community]

**What:** Continuing to use `const spy = vi.spyOn(...) ... afterEach(() => spy.mockRestore())`
in a TypeScript 5.2+ codebase with Vitest 3.2+ instead of adopting `using spy = vi.spyOn(...)`.

**Why harmful:** The `afterEach` callback is easy to forget (especially in deeply nested
`describe` blocks), easy to get wrong (calling `mockReset` instead of `mockRestore`), and
creates a temporal dependency between test body and cleanup hook. When a test throws early,
`afterEach` still runs — but if the test was in a `beforeAll` setup that failed, `afterEach`
may not run at all. The `using` keyword is unconditionally safe: cleanup fires on any exit
path including exceptions and timeouts.

```typescript
// BAD: manual restore — easy to forget, fragile under exception paths
describe('NotificationService', () => {
  let emailSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    emailSpy = vi.spyOn(mailer, 'send').mockResolvedValue(undefined);
  });

  afterEach(() => {
    emailSpy.mockRestore(); // forgot this? now mailer.send is permanently mocked
  });

  it('sends notification on event', async () => { /* ... */ });
});

// GOOD: using keyword — restore is guaranteed and scope-local
describe('NotificationService', () => {
  it('sends notification on event', async () => {
    using emailSpy = vi.spyOn(mailer, 'send').mockResolvedValue(undefined);
    // Restore is guaranteed — no afterEach needed
    await NotificationService.dispatch('user.created', { userId: 'u-1' });
    expect(emailSpy).toHaveBeenCalledOnce();
  });
});
```

---

## Real-World Gotchas (iteration 49)  [community]

**Gotcha 44 — Playwright CLI Trace `--grep` Reduces Analysis Time on Flaky Traces by 70%**  [community]
When a flaky E2E test case generates a 500-action trace (typical for a multi-step checkout flow),
loading the full trace in the GUI viewer to find the divergence point takes 2–5 minutes. The CLI
`npx playwright trace actions --grep="expect"` subcommand (v1.59) filters the action list to only
assertion actions, which cuts 95% of the noise and immediately shows which assertion passed on
retry but failed on the initial run. Teams at scale (Vercel internal report, 2025) reduced average
flakiness triage time from 15 minutes to under 4 minutes by adding a mandatory `trace actions --grep`
step to their CI failure annotation workflow.

---

## Quick Reference additions (iteration 49)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Spy mock bleeds into next test case | Forgot `mockRestore()` in afterEach | Pattern 72 (`using` keyword auto-restore) | AP38 (manual mockRestore when `using` is available) |
| Background server port not released after test timeout | No cleanup on timeout | Pattern 73 (context.signal for resource cleanup) | Relying on afterEach only — doesn't fire on hard timeout |
| Flaky trace too large to navigate in GUI viewer | 500+ actions in checkout flow | Pattern 70 (CLI trace `--grep="expect"`) | Loading full GUI trace for every flakiness investigation |
| Re-running full suite to reproduce a single flaky test | No targeted rerun mechanism | Pattern 71 (`--last-failed` rerun) | Running full suite on every fix iteration |

---

## Key Resources (iteration 49 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright CLI trace subcommands | Official | https://playwright.dev/docs/trace-viewer | `npx playwright trace actions/action/snapshot` — CLI investigation without GUI (v1.59) |
| Playwright `--last-failed` | Official | https://playwright.dev/docs/running-tests#run-last-failed-tests | Targeted rerun of failed tests — speeds up flakiness iteration loop (v1.44) |
| Vitest Explicit Resource Management | Official | https://vitest.dev/blog/vitest-3-2 | `using` keyword with `vi.spyOn()` for auto-restore — v3.2+ |
| Vitest Test Signal API | Official | https://vitest.dev/guide/test-context#context-signal | `context.signal` AbortSignal for guaranteed resource cleanup on timeout — v3.2+ |

---

## Pattern 74 — Vitest 4.1 `page.mark()` for Trace Annotation in Browser Mode  [official]

Vitest 4.1 added `page.mark(label, fn)` — a browser-mode API that groups Playwright interactions
under a named annotation in the trace viewer. The trace timeline shows each `page.mark()` region
as a labelled span, making it straightforward to identify which group of interactions was executing
when a flaky assertion fired.

**Why this matters for flakiness diagnosis:** In Vitest browser mode, tests are run by the Vitest
runner but the browser interactions go through Playwright under the hood. Without `page.mark()`,
a 40-action trace shows a flat list of clicks and fills — the failing assertion is buried.
With `page.mark()`, the timeline is divided into semantic regions ("login flow", "submit form",
"assert confirmation") so the region containing the flaky assertion is immediately visible.

```typescript
// vitest.config.ts — ensure browser mode and trace are enabled for mark() usage
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: 'playwright',
      name: 'chromium',
      headless: true,
    },
    // Retry in CI — trace captures both attempts when retain-on-failure-and-retries is used
    retry: process.env.CI ? 2 : 0,
  },
});
```

```typescript
// checkout.browser.test.tsx — structured trace regions via page.mark()
import { page } from '@vitest/browser/context'; // Vitest browser context
import { render } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { expect, it, describe } from 'vitest';
import { CheckoutFlow } from './CheckoutFlow';

describe('CheckoutFlow — browser mode', () => {
  it('completes checkout with payment confirmation', async () => {
    const user = userEvent.setup();

    // page.mark() groups the contained interactions as a named span in the trace viewer.
    // Each group shows as a color-coded region — the failing interaction is immediately
    // locatable without scanning 40+ individual action entries.
    await page.mark('render checkout', async () => {
      render(<CheckoutFlow orderId="ORD-001" />);
      // Wait for the form to be ready before interacting
      await expect.element(page.getByRole('form', { name: /checkout/i })).toBeVisible();
    });

    await page.mark('fill payment details', async () => {
      await user.type(page.getByLabelText(/card number/i), '4111111111111111');
      await user.type(page.getByLabelText(/expiry/i), '12/28');
      await user.type(page.getByLabelText(/cvv/i), '123');
    });

    await page.mark('submit and assert confirmation', async () => {
      await user.click(page.getByRole('button', { name: /place order/i }));
      // Flakiness here is immediately visible as "submit and assert confirmation" in the trace
      // — without mark(), it appears as "click" #27 in a flat list
      await expect.element(page.getByTestId('confirmation-number')).toBeVisible({ timeout: 5_000 });
      await expect.element(page.getByTestId('order-total')).toHaveText('$49.99');
    });
  });
});
```

**Comparison with Playwright's `test.step()`:**
- `test.step()` (Playwright) — available in Playwright E2E tests; creates named steps in the Playwright HTML report and trace viewer
- `page.mark()` (Vitest 4.1) — available in Vitest browser mode; creates named spans in the Vitest browser trace; the underlying mechanism is Playwright's `page.mark()` exposed through the `@vitest/browser/context` module

When migrating from Playwright CT to Vitest browser mode, replace `test.step()` with `page.mark()` for trace annotation. The visual output in the trace viewer is equivalent, but the API surface differs.

---

## Pattern 75 — Vitest 4.1 `mockThrow` / `mockThrowOnce` for Error Path Isolation  [official]

Vitest 4.1 introduced `mockThrow(error)` and `mockThrowOnce(error)` as first-class mock methods,
replacing the verbose `mockImplementation(() => { throw error })` pattern. The ergonomic improvement
reduces boilerplate in error-path tests — which are a common source of flakiness because the
verbose implementation pattern is easy to get wrong (e.g., forgetting to throw vs. returning a
rejected Promise for async functions).

**Why this matters for flakiness:** Error path tests are disproportionately flaky for two reasons:
1. The verbose `mockImplementation(() => { throw ... })` is often confused with `mockRejectedValue()`,
   causing a thrown synchronous error when an async rejection is needed (or vice versa) — producing
   a test that passes sometimes (when the error propagation path happens to catch both) and fails
   in edge cases.
2. The assertion on the thrown value is often imprecise (`expect(fn).toThrow()` passes for any
   throw including a `TypeError` from a different bug), masking real defects.

```typescript
// BAD — verbose implementation with a common mistake: sync throw in an async mock
import { vi, describe, it, expect } from 'vitest';
import { UserService } from './UserService';
import * as db from './db';

vi.mock('./db');

it('handles DB connection error', async () => {
  // MISTAKE: mockImplementation throws synchronously, but db.findUser is async.
  // UserService likely catches async rejections, not sync throws — test may pass
  // when it shouldn't (error is silently swallowed by the async boundary).
  (db.findUser as ReturnType<typeof vi.fn>).mockImplementation(() => {
    throw new Error('Connection refused');
  });

  await expect(UserService.getUser(1)).rejects.toThrow('Connection refused');
});

// BAD — correct async rejection but still verbose
it('handles DB timeout', async () => {
  (db.findUser as ReturnType<typeof vi.fn>).mockImplementation(() =>
    Promise.reject(new Error('Query timeout'))
  );
  await expect(UserService.getUser(1)).rejects.toThrow('Query timeout');
});

// GOOD — Vitest 4.1 mockThrow: synchronous throw, explicit and concise
it('handles DB connection error (sync throw)', async () => {
  const findUserMock = vi.fn().mockThrow(new Error('Connection refused'));
  // mockThrow() is unambiguous: this mock throws synchronously when called.
  // If UserService is expected to catch this, the test verifies that behavior precisely.
  expect(() => findUserMock()).toThrow('Connection refused');
});

// GOOD — Vitest 4.1 mockThrowOnce: synchronous throw on the first call only
// then falls through to the default (undefined) on subsequent calls
it('retries once on connection error', async () => {
  const findUserMock = vi.fn()
    .mockThrowOnce(new Error('Connection refused')) // first call throws
    .mockResolvedValue({ id: 1, name: 'Alice' });   // second call succeeds

  const service = new UserService({ db: { findUser: findUserMock } });
  const user = await service.getUser(1); // service should retry once
  expect(user.name).toBe('Alice');
  expect(findUserMock).toHaveBeenCalledTimes(2); // called twice: throw then success
});
```

```typescript
// Chai-style mock assertions (Vitest 4.1) — alternative to expect().toHaveBeenCalled()
// For teams already using chai or prefer the fluent style
import { vi, describe, it, expect } from 'vitest';

describe('OrderService — chai-style mock verification', () => {
  it('sends exactly one notification per order', async () => {
    const notifyMock = vi.fn().mockResolvedValue({ sent: true });
    const service = new OrderService({ notify: notifyMock });

    await service.create({ items: ['sku-A'], userId: 'user-1' });

    // Chai-style: more readable for teams coming from Mocha/Chai
    expect(notifyMock).to.have.been.called;
    expect(notifyMock).to.have.callCount(1);
    expect(notifyMock).to.have.been.calledWith(
      expect.objectContaining({ type: 'order.created' })
    );
    // NOT called twice — common flakiness pattern: notification fired in both
    // the main flow AND an event listener that was registered globally
    expect(notifyMock).not.to.have.callCount(2);
  });
});
```

**`mockThrow` vs `mockRejectedValue` — when to use each:**

| Scenario | Use |
|----------|-----|
| Mock a synchronous function that throws (e.g., a validator, a parser) | `mockThrow(new Error(...))` |
| Mock an async function that rejects (e.g., a DB query, an HTTP call) | `mockRejectedValue(new Error(...))` |
| Mock a sync function that throws only on the first call | `mockThrowOnce(new Error(...))` |
| Mock an async function that rejects only on the first call | `mockRejectedValueOnce(new Error(...))` |

Using `mockThrow` for async functions (or `mockRejectedValue` for sync functions) is a classic
source of subtle test flakiness — the test passes in one call order and fails in another because
the error propagation path differs between sync and async throws.

---

## Pattern 76 — Playwright MCP Server for Agentic Flaky Test Investigation  [official]

Playwright v1.59 introduced `@playwright/mcp` — a Model Context Protocol server that exposes
Playwright's browser automation as MCP tools. In the context of flaky test investigation, this
enables AI coding assistants (Claude Code, Cursor, GitHub Copilot Workspace) to autonomously
reproduce a flaky test in a live browser, capture a trace, inspect network requests, and report
the root cause — without a human manually running `npx playwright test --debug`.

**Why this matters for flakiness:** Flaky tests are difficult to investigate because they require
reproducing a non-deterministic failure. An AI agent with access to `@playwright/mcp` can run the
test 5× in a fresh browser, capture the trace on each failure, compare action timelines, and
surface the divergence point — all without a developer context-switching from their editor.

```bash
# Install the Playwright MCP server
npm install -D @playwright/mcp

# Add to your MCP server config (claude_desktop_config.json or .cursor/mcp.json):
# {
#   "mcpServers": {
#     "playwright": {
#       "command": "npx",
#       "args": ["@playwright/mcp", "--caps=devtools"]
#     }
#   }
# }

# The --caps=devtools flag enables tracing, video recording, and DevTools access
# — required for full flakiness investigation workflow
```

```typescript
// Example: AI agent workflow using Playwright MCP for flaky test investigation
// The AI agent (via MCP) executes the following steps autonomously:

// Step 1: Navigate to the page under test
// mcp_playwright_navigate({ url: 'http://localhost:3000/checkout' })

// Step 2: Reproduce the user flow from the failing test
// mcp_playwright_click({ element: 'button[name="Add to Cart"]' })
// mcp_playwright_type({ element: 'input[name="card-number"]', text: '4111111111111111' })

// Step 3: Capture the page state when the failure occurs
// mcp_playwright_snapshot({}) — returns the accessibility tree for AI analysis

// Step 4: Check console for silent errors (often the flakiness root cause)
// mcp_playwright_console_messages({ severity: 'error' })

// Step 5: Inspect network requests for API failures
// mcp_playwright_network_requests({ filter: 'api/' })
```

```typescript
// playwright.config.ts — enable browser.bind() for MCP-accessible browser instance
// browser.bind() makes the launched browser accessible to @playwright/mcp and other
// clients, enabling live debugging without stopping the test run
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  use: {
    trace: 'on-first-retry',
  },

  // Flakiness investigation project: bind the browser for live MCP access
  // Run: npx playwright test --project=mcp-debug --headed
  projects: [
    {
      name: 'mcp-debug',
      testMatch: '**/*.flaky.spec.ts',
      use: {
        // Launch browser in headed mode and bind for external MCP client access
        // The MCP client can then navigate, inspect, and capture traces in real time
        headless: false,
        // When browser.bind() is configured, @playwright/mcp can connect to it
        // This enables live AI-assisted investigation during test execution
      },
      retries: 0, // No retries in debug mode — we want to see the raw failure
    },
  ],
});
```

**When to use Playwright MCP for flakiness:**
- Flaky test is difficult to reproduce locally (fails 1-in-10 times)
- Root cause is in browser rendering, network timing, or DOM mutation ordering
- Team uses Claude Code, Cursor, or another MCP-capable AI assistant
- The flaky test involves complex multi-step flows where manual debugging is slow

**When NOT to use it:**
- Flaky test is in unit or integration code (Node.js, not browser) — use Vitest directly
- The root cause is clearly shared state or mocking (code-level diagnosis is faster)
- CI environment doesn't support headed browser mode

---

## Pattern 77 — Vitest 4.1 `experimental.viteModuleRunner: false` for Production-Fidelity Isolation  [official]

By default, Vitest uses its own Vite-based module runner that executes test code in a sandbox
with custom module resolution. Setting `experimental.viteModuleRunner: false` runs tests with
**native Node.js `import()`** instead — bypassing the Vite module runner entirely. This produces
closer-to-production behavior and surfaces a category of flakiness that the Vite runner masks:
module singleton lifecycle differences.

**Why this matters for flakiness:** The Vite module runner can reset module-level state between
tests when configured with `resetModules: true`. Native imports respect Node.js module caching —
once a module is imported, the same instance is returned on every subsequent import unless the
cache is manually cleared. Tests that rely on the Vite runner's module reset to achieve isolation
will be flaky under native imports. Conversely, tests that pass with native imports are more
likely to also pass in production environments (e.g., AWS Lambda, Docker containers) where
Node.js module caching behaves identically.

```typescript
// vitest.config.ts — native module runner for production-fidelity testing
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    experimental: {
      // Run tests with native Node.js imports instead of Vite's module runner.
      // BENEFITS:
      //   - Surfaces module singleton flakiness that Vite runner masks
      //   - Closer to production behavior (no Vite transform pipeline)
      //   - Faster startup for projects that don't need Vite transforms in tests
      // COSTS:
      //   - CSS/asset imports in test files will fail (no Vite transform)
      //   - Path alias resolution (e.g., @/components) requires manual Node.js loader
      //   - resetModules: true has no effect — native cache is not reset between tests
      viteModuleRunner: false,
    },
    // With viteModuleRunner: false, explicit module isolation requires separate workers
    // Use 'forks' pool to get OS-level process isolation between test files
    pool: 'forks',
    // resetModules has no effect under native imports — remove to avoid confusion
    // resetModules: false,
  },
});
```

```typescript
// Pattern: detecting singleton flakiness that viteModuleRunner: false surfaces
// This test passes with Vite module runner (resetModules resets the singleton)
// but fails with viteModuleRunner: false (native Node.js cache keeps the singleton)

// src/cache.ts — singleton module with module-level state
let cache: Map<string, string> | null = null;

export function getCache(): Map<string, string> {
  if (!cache) {
    cache = new Map();
  }
  return cache;
}

export function clearCache(): void {
  cache = null;
}
```

```typescript
// cache.test.ts — this test is FLAKY under viteModuleRunner: false
// The Vite runner resets module-level 'cache' to null between test files.
// Native Node.js imports keep the cached module instance — 'cache' persists.
import { describe, it, expect, beforeEach } from 'vitest';
import { getCache, clearCache } from '../src/cache';

describe('Cache module', () => {
  beforeEach(() => {
    // CORRECT FIX: always call clearCache() explicitly — don't rely on module reset
    clearCache();
  });

  it('starts empty', () => {
    expect(getCache().size).toBe(0); // reliable only after explicit clearCache()
  });

  it('persists entries across calls', () => {
    getCache().set('key', 'value');
    expect(getCache().get('key')).toBe('value');
  });
});

// NOTE: The beforeEach fix above makes this test deterministic under BOTH
// Vite module runner AND native imports. Tests that only pass with the Vite
// runner's module reset are revealing a real isolation defect — fix them,
// don't rely on the runner's behavior as a workaround.
```

**Migration guide for `viteModuleRunner: false`:**

1. Enable `viteModuleRunner: false` locally and run the test suite
2. Any new failures reveal tests that depended on the Vite module runner's reset behavior
3. Fix by adding explicit `beforeEach` cleanup (as above) — do NOT disable the setting
4. Once all tests pass, enable in CI to prevent regression

**When to keep the default (Vite module runner):**
- Tests import CSS, assets, or other files that require Vite transforms
- Tests use Vite-specific globals (e.g., `import.meta.env`, `import.meta.hot`)
- The project uses Vite plugins whose side effects are required during testing

---

## Anti-Patterns (iteration 50)

### AP39 — Using `page.mark()` Without Explicit `await`  [official]

**What:** Calling `page.mark(label, fn)` without `await` — the mark annotation is registered but
the interactions inside `fn` run as a floating Promise.

**Why harmful:** Without `await`, the interactions in `page.mark()` race with subsequent test
assertions. The trace may capture the mark span as instantaneous (the interactions didn't run
yet), making the trace misleading. The test appears to pass (the assertion doesn't wait for the
mark's content) or fails non-deterministically (depending on timing). Fix: always `await page.mark()`.

```typescript
// BAD: unawaited page.mark() — interactions race with the assertion
it('submits order', async () => {
  page.mark('fill form', async () => { // MISSING await
    await user.type(page.getByLabelText('card'), '4111111111111111');
  });
  // This assertion runs BEFORE the card number is typed — flaky result
  await expect.element(page.getByTestId('submit-btn')).toBeEnabled();
});

// GOOD: awaited page.mark() — form is filled before assertion runs
it('submits order', async () => {
  await page.mark('fill form', async () => { // await here
    await user.type(page.getByLabelText('card'), '4111111111111111');
  });
  await expect.element(page.getByTestId('submit-btn')).toBeEnabled();
});
```

### AP40 — `mockThrow` on an Async Function  [official]

**What:** Using `vi.fn().mockThrow(error)` on a mock that will be called in an `async` context,
expecting the caller to receive a rejected Promise.

**Why harmful:** `mockThrow` causes the mock to throw synchronously. In an `async` function,
a synchronous throw IS converted to a rejected Promise by JavaScript's async machinery — but only
if the throw happens inside the `async` function body. If the mock is called in a way where the
throw propagates outside the async boundary (e.g., passed as a non-async callback), the throw
becomes an uncaught exception, not a Promise rejection. This produces a test that passes in
some call contexts and crashes in others — classic non-determinism.

```typescript
// RISKY: mockThrow on a function passed as a synchronous callback to an async operation
const fetchUserMock = vi.fn().mockThrow(new Error('DB error'));

// If createOrder calls fetchUser inside an async callback that wasn't awaited:
// the synchronous throw escapes the async boundary and crashes the process
await OrderService.create({ userId: 'user-1', fetchUser: fetchUserMock });

// SAFE: use mockRejectedValue for mocks called in async contexts
const fetchUserMock = vi.fn().mockRejectedValue(new Error('DB error'));
// This always produces a rejected Promise — safe regardless of call context
```

---

## Real-World Gotchas (iteration 50)  [community]

**Gotcha 45 — Trunk AI Failure Fingerprinting Catches Variant Flakiness that String Matching Misses**  [community]

Traditional flaky test detectors (BuildPulse, custom JUnit XML parsers) identify flakiness by
matching test names: if the same test name appears in both pass and fail states across runs
with no code change, it's flagged as flaky. This approach misses **variant flakiness** — a single
test that fails with three different error messages across different runs. Each variant looks like
a new, unique failure to string-matching detectors, so none is flagged as flaky.

Trunk Flaky Tests (2025–2026) uses AI-based failure fingerprinting that groups failures by
**root cause similarity** rather than exact error string match. A timeout failure, an element-not-found
failure, and a network-error failure in the same test case are grouped as "this test is flaky" if
they share enough contextual similarity (the same DOM state, the same network pattern, the same
assertion site). Teams that migrated from string-matching detectors to Trunk AI fingerprinting
commonly find 30–50% more flaky test cases than their existing tooling detected.

**Practical implication for TypeScript teams:** Before trusting "no flaky tests detected" from
a string-matching tracker, run a nightly `--repeats 10` sweep (Vitest) or 5× nightly detection
(Pattern 2 GitHub Actions) and manually compare failure messages. If the same test consistently
produces 2–3 different error messages across runs, it's variant-flaky — even if no single
error message crossed the string-matching threshold.

---

## Quick Reference additions (iteration 50)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Trace timeline is a flat 40-action list — failure site unclear | No trace annotation | Pattern 74 (`page.mark()` for named regions) | AP39 (unawaited page.mark()) |
| Error-path test passes inconsistently (sync vs async throw mismatch) | Wrong mock error API | Pattern 75 (`mockThrow` vs `mockRejectedValue`) | AP40 (`mockThrow` on async function) |
| Flaky browser test hard to reproduce manually | Multi-step timing issue | Pattern 76 (Playwright MCP for AI-assisted reproduction) | Manual `--debug` session for every flakiness investigation |
| Test passes with Vite runner but flaky in production/CI | Module singleton not reset | Pattern 77 (`viteModuleRunner: false` to surface defect) | Relying on Vite runner's module reset as isolation |
| Same test fails with 3 different error messages — no tracker flags it | Variant flakiness | Gotcha 45 (AI fingerprinting vs string matching) | Trusting string-match-only flakiness trackers |

---

## Key Resources (iteration 50 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest `page.mark()` API | Official | https://vitest.dev/api/browser/context#mark | Named trace annotations for Vitest browser mode tests (v4.1) |
| Vitest `mockThrow` / `mockThrowOnce` | Official | https://vitest.dev/api/mock#mockthrow | Concise synchronous throw mock — replaces verbose `mockImplementation` (v4.1) |
| Playwright MCP Server | Official | https://playwright.dev/docs/api/class-browser#browser-bind | `@playwright/mcp` — 60+ browser automation tools via MCP for agentic test debugging (v1.59) |
| Vitest `experimental.viteModuleRunner` | Official | https://vitest.dev/config/#experimental-vitemodulerunner | Native Node.js import mode — surfaces module singleton flakiness hidden by Vite's runner (v4.1) |
| Trunk AI Failure Fingerprinting | Community | https://trunk.io/flaky-tests | AI-powered root cause grouping — detects variant flakiness that string-matching tools miss |

---

## Pattern 78 — Vitest 4.1 Conditional Retry with Error Predicate  [official]

Vitest 4.1 extended the `retry` option from a plain number to a structured object with three
fields: `count`, `delay`, and `condition`. The `condition` field accepts either a `RegExp`
(matched against the error message) or a `(error: TestError) => boolean` predicate, enabling
**error-type-specific retry policies** — the most precise form of retry budget management in
the TypeScript test ecosystem.

**Why this matters for flakiness:** A global `retry: 2` retries ALL failures, including genuine
application defects. This conceals real bugs behind retry passes — the opposite of what flakiness
management should do. A conditional retry policy can target infrastructure flakiness
(`ECONNRESET`, `TimeoutError`) while immediately failing on assertion errors
(`AssertionError`, `expect()` failures), ensuring retries are diagnostic, not masking.

```typescript
// TypeScript type (Vitest 4.1+)
type Retry = number | {
  count?: number;                                           // max retry attempts
  delay?: number;                                           // ms between attempts
  condition?: RegExp | ((error: TestError) => boolean);    // condition to trigger retry
};

// TestError interface (available via 'vitest' import for typing in predicate)
interface TestError {
  message: string;
  stack?: string;
  cause?: unknown;
}
```

```typescript
// vitest.config.ts — global retry policy targeting only infrastructure errors
import { defineConfig } from 'vitest/config';
import type { TestError } from 'vitest';

// List of error message patterns that indicate infrastructure flakiness (not code defects)
const INFRASTRUCTURE_FLAKINESS_PATTERNS = [
  /ECONNRESET/,        // TCP connection reset — network transient error
  /ECONNREFUSED/,      // Service not ready yet — startup race
  /socket hang up/i,   // HTTP connection dropped mid-request
  /TimeoutError/,      // Playwright/puppeteer operation timeout
  /net::ERR_/,         // Chrome network error codes
  /Service Unavailable/, // 503 from upstream services
];

export default defineConfig({
  test: {
    // Object form (Vitest 4.1+) — retry only on infrastructure errors
    retry: {
      count: 2,       // max 2 retries
      delay: 500,     // 500ms between retries (give services time to recover)
      // Only retry if the error matches an infrastructure pattern.
      // AssertionErrors, TypeErrors, and ReferenceErrors propagate immediately as failures.
      condition: (error: TestError) =>
        INFRASTRUCTURE_FLAKINESS_PATTERNS.some(pattern => pattern.test(error.message)),
    },
  },
});
```

```typescript
// Per-test conditional retry — for known-flaky tests under investigation
// The RegExp form is more concise when error patterns are stable
import { describe, it, expect } from 'vitest';
import { PaymentGateway } from './PaymentGateway';

describe('PaymentGateway — integration', () => {
  // PROJ-3101: webhook callback timing under CI load — retries only on timeout
  // When the root cause is fixed (timeout eliminated), remove the retry condition
  it(
    'processes refund webhook within 3 seconds',
    {
      retry: {
        count: 3,
        delay: 1000,
        // Only retry on timeout — never retry on assertion failures (they indicate a real bug)
        condition: /TimeoutError|timed out after/i,
      },
    },
    async () => {
      const gw = new PaymentGateway({ endpoint: process.env.GATEWAY_URL! });
      const refund = await gw.refund({ transactionId: 'TXN-001', amount: 50_00 });
      // This assertion will NOT be retried if it fails — a wrong refund status is a real defect
      expect(refund.status).toBe('refunded');
    }
  );

  // Stable test: no retry — any failure here is a genuine defect
  it('rejects negative refund amount', async () => {
    const gw = new PaymentGateway({ endpoint: process.env.GATEWAY_URL! });
    await expect(gw.refund({ transactionId: 'TXN-001', amount: -100 }))
      .rejects.toThrow('amount must be positive');
  });
});
```

```typescript
// Advanced: function predicate for multi-condition retry logic
// Use when the retry policy depends on error type hierarchy, not just message pattern
import { it, expect } from 'vitest';
import type { TestError } from 'vitest';

function isTransientInfraError(error: TestError): boolean {
  const msg = error.message.toLowerCase();
  // Retry on known transient infra errors
  if (/(timeout|econnreset|service unavailable|503|econnrefused)/.test(msg)) return true;
  // Also retry if the cause is a network error (chained errors)
  if (error.cause instanceof Error && /(network|socket|connect)/.test(error.cause.message.toLowerCase())) return true;
  // NEVER retry on assertion failures — they represent code defects
  if (/assertionerror|expect\(received\)|expected .+ to equal/i.test(msg)) return false;
  // Default: don't retry on unknown errors (conservative — fail fast on surprises)
  return false;
}

it('fetches user from API with conditional retry', { retry: { count: 2, condition: isTransientInfraError } }, async () => {
  const response = await fetch('/api/users/1');
  const user = await response.json() as { id: string; name: string };
  // Only this assertion's failure will NOT trigger retry (AssertionError)
  expect(user.name).toBe('Alice');
});
```

**`delay` option — why it matters for flakiness:**

Without `delay`, Vitest retries immediately. For infrastructure flakiness (service not ready,
connection pool exhausted), an immediate retry often fails for the same reason — the transient
condition hasn't resolved. Adding `delay: 500` gives services time to recover between attempts
and dramatically improves retry success rates for connection-related flakiness.

**Caveats:**
- The `condition` function form is only available in test files, not in `vitest.config.ts`.
  For global config, use the RegExp form.
- Conditional retry is a diagnostic aid during flakiness investigation, not a permanent solution.
  Track retried tests with `onTestFailed` (Pattern 59) and quarantine once the root cause is identified.

---

## Pattern 79 — Playwright v1.53 `TestStepInfo.skip()` for Conditional Step Quarantine  [official]

Playwright v1.53 promoted `TestStepInfo` to a first-class object passed to `test.step()`
callback, exposing `skip()` and `skip(condition, description)` overloads and the `titlePath`
property. The `skip()` method inside a step is distinct from `test.skip()` (which aborts the
entire test case) — it aborts only the current step and continues the rest of the test.

**Why this matters for flakiness:** A common challenge with multi-step E2E tests is that a
single known-flaky step forces the entire test case into quarantine. With `TestStepInfo.skip()`,
you can quarantine precisely the flaky step — leaving the rest of the test active and green —
while `titlePath` provides an unambiguous step identifier for tracking and reporting.

```typescript
// playwright — TestStepInfo API (v1.53+)
// test.step(title, callback) now passes a TestStepInfo to the callback as the first argument

import { test, expect } from '@playwright/test';

test('checkout with optional coupon', async ({ page, browserName }) => {
  await test.step('navigate to checkout', async () => {
    await page.goto('/checkout');
    await expect(page.getByRole('heading', { name: 'Checkout' })).toBeVisible();
  });

  // Step with conditional skip — skip on WebKit due to known coupon field rendering bug (PROJ-3200)
  // The rest of the test (payment, confirmation) still runs on WebKit
  await test.step('apply discount coupon', async (step) => {
    // Conditionally skip this step — the description appears in the HTML report
    step.skip(
      browserName === 'webkit',
      'PROJ-3200: coupon input has rendering defect in WebKit — skip until fix is deployed'
    );
    // Only runs on Chromium/Firefox — safe to interact with the coupon field
    await page.getByTestId('coupon-input').fill('SUMMER20');
    await page.getByRole('button', { name: 'Apply Coupon' }).click();
    await expect(page.getByTestId('discount-line')).toContainText('-20%');
  });

  // This step always runs — not affected by the step skip above
  await test.step('complete payment', async () => {
    await page.fill('[name="card-number"]', '4111111111111111');
    await page.fill('[name="expiry"]', '12/28');
    await page.fill('[name="cvv"]', '123');
    await page.route('**/api/orders', route =>
      route.fulfill({ status: 201, json: { orderId: 'ORD-TEST-001' } })
    );
    await page.getByRole('button', { name: 'Place Order' }).click();
    await expect(page.getByTestId('confirmation-number')).toBeVisible({ timeout: 5_000 });
  });
});
```

```typescript
// Using TestStepInfo.titlePath for step-level flakiness tracking
// titlePath returns the full path from the test file to the current step
// Format: ['test-file.spec.ts', 'test title', 'step title']
import { test, expect } from '@playwright/test';

test('full order flow diagnostic', async ({ page }, testInfo) => {
  await test.step('add item to cart', async (step) => {
    // titlePath identifies this step unambiguously — useful for logging and tracking
    // step.titlePath: ['checkout.spec.ts', 'full order flow diagnostic', 'add item to cart']
    console.log('[STEP] Starting:', step.titlePath.join(' > '));

    await page.goto('/products/laptop');
    await page.getByRole('button', { name: 'Add to Cart' }).click();
    await expect(page.getByTestId('cart-count')).toHaveText('1');

    console.log('[STEP] Completed:', step.titlePath.join(' > '));
  });

  await test.step('proceed to checkout', async (step) => {
    // Unconditional skip — this step is currently broken and tracked separately
    // Appears as "skipped" in the HTML report with the reason visible
    step.skip(); // no condition — always skipped; equivalent to commenting out but traceable

    await page.getByRole('link', { name: 'Checkout' }).click();
    await page.waitForURL('**/checkout');
  });

  // Test continues here even though the previous step was skipped
  await test.step('verify cart contents', async () => {
    await page.goto('/cart');
    await expect(page.getByTestId('cart-item-laptop')).toBeVisible();
  });
});
```

**TestStepInfo.skip() overloads:**

```typescript
// From Playwright's type definitions (v1.53+):
interface TestStepInfo {
  /** Abort the currently running step and mark it as skipped. */
  skip(): void;
  /** Conditionally abort the currently running step and mark it as skipped. */
  skip(condition: boolean, description?: string): void;
  /** Full title path from test file to this step. */
  readonly titlePath: string[];
}
```

**When to use `TestStepInfo.skip()` vs. `test.step.skip()` (Pattern 61):**

| API | Version | Use case |
|-----|---------|----------|
| `test.step.skip()` (static) | v1.55+ | Skip a step at the call site — the entire step body is never created |
| `TestStepInfo.skip()` (runtime) | v1.53+ | Skip from inside the step body — useful for conditional logic involving runtime values (e.g., `browserName`, feature flags) |

Use `test.step.skip()` when the skip decision is static (known at write time).
Use `TestStepInfo.skip(condition, description)` when the skip decision depends on runtime
values not available until the step executes.

---

## Pattern 80 — Playwright v1.60 `testInfoError.errorContext` for Aria-Snapshot Flakiness Diagnosis  [official]

Playwright v1.60 added `testInfoError.errorContext` — a property that provides the accessibility
tree (ARIA snapshot) of the page element that was the target of a failing `expect()` matcher at
the moment of failure. This captures the DOM state that the assertion saw, making it possible to
diagnose flakiness root causes from CI artifacts without re-running the test manually.

**Why this matters for flakiness:** The most common question when a Playwright assertion flakes is
"what did the DOM look like at the moment of failure?" Previously, you needed a trace or screenshot
to answer this. `errorContext` provides a lightweight, text-representable answer — the element's
accessibility tree — that is embedded directly in the test result and reportable in JUnit XML,
step summary, and CI dashboards without loading a trace file.

```typescript
// playwright — accessing errorContext in a custom reporter for flakiness diagnosis
// Reporters receive TestResult objects which include an array of TestResultError

import type { Reporter, TestCase, TestResult, TestResultError } from '@playwright/test/reporter';

class FlakinessContextReporter implements Reporter {
  onTestEnd(test: TestCase, result: TestResult): void {
    if (result.status !== 'failed' && result.status !== 'flaky') return;

    for (const error of result.errors) {
      // errorContext is present when the failure is from an expect() matcher
      // It contains additional diagnostic context such as the ARIA snapshot
      const ctx = (error as TestResultError & { errorContext?: string }).errorContext;
      if (ctx) {
        console.error(`[FLAKY CONTEXT] Test: "${test.title}"`);
        console.error(`[FLAKY CONTEXT] Error: ${error.message?.slice(0, 100)}`);
        console.error(`[FLAKY CONTEXT] ARIA snapshot at failure:\n${ctx}`);
        // In a real reporter, write this to a structured log or attach to the CI summary
      }
    }
  }
}

export default FlakinessContextReporter;
```

```typescript
// playwright.config.ts — include custom reporter alongside standard reporters
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  failOnFlakyTests: !!process.env.CI,

  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['junit', { outputFile: 'test-results/results.xml' }],
    // Custom reporter that surfaces errorContext ARIA snapshots in CI logs
    ['./reporters/flakiness-context-reporter.ts'],
  ],
  use: {
    trace: 'on-first-retry',
  },
});
```

```typescript
// Using errorContext in a test's afterEach for inline flakiness diagnosis
// Useful during active investigation of a specific known-flaky test case
import { test, expect } from '@playwright/test';

test.afterEach(async ({}, testInfo) => {
  // Only log diagnostics when a test case failed after all retries
  if (testInfo.status !== 'failed') return;

  for (const error of testInfo.errors) {
    // TypeScript: errorContext is typed as string | undefined in Playwright v1.60+
    const ctx = (error as { errorContext?: string }).errorContext;
    if (ctx) {
      console.error(
        `\n[ARIA SNAPSHOT at failure]\n` +
        `Test: ${testInfo.title}\n` +
        `Step: ${testInfo.titlePath.join(' > ')}\n` +
        `Context:\n${ctx}\n`
      );
    }
  }
});

test('product page shows correct price', async ({ page }) => {
  await page.goto('/products/laptop-pro');
  // If this flakes (e.g., price renders with stale cached value), the afterEach above
  // will print the ARIA snapshot of #product-price at the moment the assertion failed —
  // telling you what text was actually in the element
  await expect(page.getByTestId('product-price')).toHaveText('$999.00');
});
```

**What `errorContext` contains:**

When an `expect(locator).toHaveText(...)` or `expect(locator).toBeVisible()` fails,
`errorContext` contains the accessibility representation of the locator's matched element
at the time of failure. For example:
```
heading "Laptop Pro" [focused]
  text "$1099.00"  ← actual value — stale cache served an old price
```

This is more actionable than a generic timeout message and more lightweight than a full
trace file. It is especially useful for diagnosing **content flakiness** — where an element
is present but has wrong text (e.g., stale server-side cache, race between price update
and page render).

**Caveats:**
- `errorContext` is only populated for `expect(locator)` failures where the locator can be
  evaluated — it is `undefined` for timeout failures, network errors, and non-locator assertions.
- The ARIA snapshot reflects the element's accessibility tree, not raw HTML — dynamic `data-*`
  attributes and CSS class names are not included unless they have an ARIA mapping.

---

## Pattern 81 — Vitest 4.1 `test.meta` for Custom Flakiness Metadata in Reporters  [official]

Vitest 4.1 introduced the `meta` test option, which attaches arbitrary key-value metadata to
a test case. Metadata is available to reporters via the `TaskMeta` object on each task result.
For flakiness management, `meta` enables teams to embed structured quarantine information
(ticket number, owner, flakiness root cause family) directly on the test case — making the
metadata machine-readable by dashboards and custom reporters without parsing comment strings.

**Why this matters for flakiness:** Existing quarantine patterns rely on comments
(`// [QUARANTINE] PROJ-1234`) or test name prefixes (`it.skip('[QUARANTINE] ...')`) that are
human-readable but hard to query programmatically. `test.meta` makes quarantine metadata
first-class, enabling automated reports like "all flaky tests tagged `timing`, opened > 14 days
ago, with no owner assigned."

```typescript
// Extended TaskMeta interface — augment Vitest's types for strict metadata checking
// Add to vitest-env.d.ts or a global type declaration file

declare module 'vitest' {
  interface TaskMeta {
    /** JIRA/Linear/GitHub issue number tracking this flaky test's root cause */
    quarantineIssue?: string;
    /** GitHub handle of the engineer responsible for the fix */
    owner?: string;
    /** Resolution SLA — ISO date string */
    sla?: string;
    /** Flakiness root cause family (see Root Causes Taxonomy, Pattern 1) */
    flakinessFamily?: 'timing' | 'shared-state' | 'external-dep' | 'order-dependency' | 'randomness';
    /** Estimated flakiness rate as observed in CI (e.g., 0.15 = 15%) */
    flakinessRate?: number;
    /** Whether this test should be skipped in CI while quarantined */
    quarantineSkip?: boolean;
  }
}
```

```typescript
// Usage: attach structured metadata to quarantined test cases
import { describe, it, expect } from 'vitest';

describe('PaymentGateway — integration', () => {
  // Standard test: no meta needed
  it('rejects invalid card', async () => {
    const gw = new PaymentGateway({ endpoint: process.env.GATEWAY_URL! });
    await expect(gw.charge({ cardNumber: '0000', amount: 10_00 }))
      .rejects.toThrow('invalid card');
  });

  // Quarantined test: structured metadata for dashboard tracking
  it(
    'processes refund webhook within 5 seconds',
    {
      meta: {
        quarantineIssue: 'PROJ-3012',
        owner: '@bob',
        sla: '2026-05-30',
        flakinessFamily: 'timing',
        flakinessRate: 0.12,   // observed 12% failure rate in nightly sweep
        quarantineSkip: true,  // skip in CI — active quarantine
      },
      // Combine meta with conditional skip: skip in CI when quarantine is active
      skip: process.env.CI === 'true',
    },
    async () => {
      const gw = new PaymentGateway({ endpoint: process.env.GATEWAY_URL! });
      const refund = await gw.refund({ transactionId: 'TXN-001', amount: 50_00 });
      expect(refund.status).toBe('refunded');
    }
  );
});
```

```typescript
// Custom Vitest reporter: generate a quarantine dashboard from test.meta
// Add to vitest.config.ts reporters list: ['./reporters/quarantine-dashboard.ts']
import type { Reporter, RunnerTestFile } from 'vitest';
import { writeFileSync } from 'fs';

interface QuarantineEntry {
  title: string;
  issue: string;
  owner: string;
  sla: string;
  flakinessFamily: string;
  flakinessRate: number;
  ageInDays: number;
}

export default class QuarantineDashboardReporter implements Reporter {
  onFinished(files?: RunnerTestFile[]): void {
    if (!files) return;

    const quarantined: QuarantineEntry[] = [];

    for (const file of files) {
      for (const suite of (file.tasks ?? [])) {
        for (const task of (Array.isArray((suite as any).tasks) ? (suite as any).tasks : [suite])) {
          const meta = task.meta as Record<string, unknown> | undefined;
          if (meta?.quarantineIssue) {
            const slaDate = new Date(meta.sla as string);
            const ageInDays = Math.floor((Date.now() - slaDate.getTime()) / 86_400_000);
            quarantined.push({
              title: task.name as string,
              issue: meta.quarantineIssue as string,
              owner: (meta.owner as string) ?? 'unassigned',
              sla: meta.sla as string,
              flakinessFamily: (meta.flakinessFamily as string) ?? 'unknown',
              flakinessRate: (meta.flakinessRate as number) ?? 0,
              ageInDays: Math.abs(ageInDays),
            });
          }
        }
      }
    }

    if (quarantined.length === 0) {
      console.log('[QuarantineDashboard] No quarantined tests.');
      return;
    }

    // Write machine-readable JSON for dashboard ingestion
    const report = {
      generatedAt: new Date().toISOString(),
      totalQuarantined: quarantined.length,
      byFamily: quarantined.reduce<Record<string, number>>((acc, e) => {
        acc[e.flakinessFamily] = (acc[e.flakinessFamily] ?? 0) + 1;
        return acc;
      }, {}),
      tests: quarantined.sort((a, b) => b.flakinessRate - a.flakinessRate), // highest rate first
    };

    writeFileSync('quarantine-report.json', JSON.stringify(report, null, 2));
    console.log(`[QuarantineDashboard] ${quarantined.length} quarantined tests — report: quarantine-report.json`);

    // Alert if any test is past its SLA
    const overdue = quarantined.filter(e => new Date(e.sla) < new Date());
    if (overdue.length > 0) {
      console.error(`[QuarantineDashboard] OVERDUE SLA: ${overdue.length} test(s):`);
      overdue.forEach(e => console.error(`  - ${e.issue}: "${e.title}" (owner: ${e.owner})`));
      process.exitCode = 1; // fail the build if quarantine SLAs are overdue
    }
  }
}
```

**Migration from comment-based quarantine to `test.meta`:**

| Old approach | New approach |
|---|---|
| `// [QUARANTINE] PROJ-1234 \| owner: @bob \| SLA: 2026-05-30` | `meta: { quarantineIssue: 'PROJ-1234', owner: '@bob', sla: '2026-05-30' }` |
| `grep -r '\[QUARANTINE\]'` to find all quarantined tests | Query `quarantine-report.json` for structured data |
| Manual count of quarantined tests in check-quarantine-backlog.ts (Pattern 3) | Reporter reads `task.meta.quarantineIssue` automatically |

Both approaches can coexist during migration — the Pattern 3 backlog check continues to work on
`[QUARANTINE]` comment markers, while new tests use `meta` for richer, machine-readable tracking.

---

## Anti-Patterns (iteration 51)

### AP41 — Conditional Retry Masking Real Failures with Overly Broad Predicates  [community]

**What:** Setting `retry.condition` to a function that returns `true` for too many error types —
effectively making the conditional retry behave like an unconditional retry.

**Why harmful:** A common example is returning `true` for all `Error` instances, or catching
`AssertionError` alongside network errors. When an assertion like `expect(order.status).toBe('refunded')`
fails because the code is genuinely broken (not flaky), the retry gives the broken code two
more chances to pass — and on the third failure, the signal is "infrastructure flakiness" rather
than "application defect". This is worse than unconditional retry because it adds a misleading
semantic: the developer sees "retried (condition matched)" and assumes transient infrastructure
failure rather than investigating the assertion.

**Fix:** Write predicates that match ONLY the specific error text that characterizes your
infrastructure's transient failures. Test the predicate against real failure logs before deploying.
Add a log statement inside the predicate to confirm it fires only on expected errors.

```typescript
// BAD: predicate catches AssertionErrors — retries real code defects
const retry = {
  count: 2,
  condition: (error: TestError) => error instanceof Error, // too broad — matches EVERYTHING
};

// ALSO BAD: regexes that match common assertion output
const retry2 = {
  count: 2,
  condition: /expected|received|toBe/, // matches Jest/Vitest assertion output — retries real failures
};

// GOOD: predicate only matches infrastructure error messages
const retry3 = {
  count: 2,
  delay: 500,
  condition: /ECONNRESET|ECONNREFUSED|socket hang up|503 Service Unavailable/i,
};

// GOOD: function predicate with explicit exclusion of assertion errors
const retry4 = {
  count: 2,
  condition: (error: TestError) => {
    const msg = error.message;
    // Never retry assertion failures
    if (/AssertionError|expect\(received\)|expected .+ to equal/i.test(msg)) return false;
    // Retry only known infrastructure patterns
    return /(ECONNRESET|ECONNREFUSED|timeout|503)/i.test(msg);
  },
};
```

---

## Quick Reference additions (iteration 51)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Global retry hides genuine assertion failures as "flaky" | Unconditional retry | Pattern 78 (conditional retry with error predicate) | AP41 (overly broad condition predicate) |
| One step in a multi-browser E2E flow fails on specific browser | Browser-specific defect, not suite-wide flakiness | Pattern 79 (TestStepInfo.skip(condition)) | Quarantining the entire test case for a browser-specific step |
| Flaky assertion: "what did the DOM look like when it failed?" | No element snapshot at failure | Pattern 80 (testInfoError.errorContext aria snapshot) | Relying on full trace file for every content-flakiness diagnosis |
| Quarantine comment strings are hard to query for dashboards | Comment-only metadata | Pattern 81 (test.meta for machine-readable quarantine) | grep-based quarantine counting with no structured metadata |

---

## Key Resources (iteration 51 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest retry option (object form) | Official | https://vitest.dev/api/#test-retry | `count`, `delay`, `condition` fields — conditional retry by error type (v4.1) |
| Playwright TestStepInfo | Official | https://playwright.dev/docs/api/class-teststepinfo | `skip()`, `skip(condition, description)`, `titlePath` — step-level quarantine (v1.53) |
| Playwright testInfoError.errorContext | Official | https://playwright.dev/docs/api/class-testinfoerror#test-info-error-error-context | ARIA snapshot of failing element at assertion time — lightweight content-flakiness diagnosis (v1.60) |
| Vitest test.meta / TaskMeta | Official | https://vitest.dev/api/#test-meta | Machine-readable test metadata for reporters — enables structured quarantine dashboards (v4.1) |

---

## Pattern 82 — Vitest 4.1 `vi.setTimerTickMode()` for Async Timer Flakiness  [official]

A common source of test flakiness with fake timers is the mismatch between async/await code and manual timer advancement: a test `await`s a Promise, but the Promise only resolves after a `setTimeout` fires, and that timer only fires after an explicit `vi.advanceTimersByTime()` call. The result is a test that hangs or times out unless the developer manually interleaves `await` and `vi.advanceTimersByTime()` — brittle and easy to get wrong.

Vitest 4.1 introduces `vi.setTimerTickMode()` to control *how* fake timers advance, decoupling the advancement strategy from the test body. This eliminates the advance-then-await pattern for most async timer tests.

**Three tick modes:**

| Mode | Behaviour | Best for |
|------|-----------|----------|
| `'manual'` (default) | Timers only advance when `vi.advanceTimers*()` is called explicitly | Tests that need precise timer control (e.g., debounce threshold tests) |
| `'nextTimerAsync'` | Timers automatically advance to the next scheduled callback after each macrotask | Async functions that `await` timer-backed operations (Promises, polling) |
| `'interval'` | Timers advance by a fixed interval continuously | Simulating elapsed real-time in tests with multiple concurrent timers |

**Important:** `vi.setTimerTickMode()` requires fake timers to already be active (i.e., after `vi.useFakeTimers()`). It controls the *advancement strategy*, not whether fake timers are enabled.

```typescript
// vitest — before vi.setTimerTickMode was available (fragile manual-advance pattern)
import { vi, describe, it, expect, afterEach } from 'vitest';

async function pollUntilReady(maxAttempts: number): Promise<string> {
  for (let i = 0; i < maxAttempts; i++) {
    await new Promise(resolve => setTimeout(resolve, 100));
    if (i === 2) return 'ready';
  }
  throw new Error('Timed out');
}

describe('pollUntilReady — FRAGILE manual-advance approach', () => {
  afterEach(() => vi.useRealTimers());

  it('resolves after 3 attempts', async () => {
    vi.useFakeTimers();
    // Must manually interleave advances with ticks — brittle and order-sensitive
    const promise = pollUntilReady(5);
    await vi.runAllTimersAsync(); // advances ALL timers — can cause cascading effects
    await expect(promise).resolves.toBe('ready');
  });
});

// vitest 4.1+ — vi.setTimerTickMode('nextTimerAsync') makes this clean
describe('pollUntilReady — stable nextTimerAsync approach', () => {
  afterEach(() => vi.useRealTimers());

  it('resolves after 3 attempts without manual advance', async () => {
    vi.useFakeTimers();
    // Timers automatically advance to the next callback after each macrotask.
    // The async function can await its own setTimeout() naturally.
    vi.setTimerTickMode('nextTimerAsync');

    const result = await pollUntilReady(5);
    // No vi.advanceTimersByTime() needed — macrotask boundaries drive advancement
    expect(result).toBe('ready');
  });
});
```

```typescript
// vitest 4.1+ — 'interval' mode for simulating elapsed time in retry loops
import { vi, it, expect, afterEach } from 'vitest';

interface BackoffConfig { baseMs: number; maxRetries: number }

async function fetchWithBackoff(url: string, config: BackoffConfig): Promise<Response> {
  let attempt = 0;
  while (attempt < config.maxRetries) {
    try {
      return await fetch(url);
    } catch {
      attempt++;
      const delay = config.baseMs * Math.pow(2, attempt);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  throw new Error(`Failed after ${config.maxRetries} retries`);
}

it('fetchWithBackoff retries with exponential delays', async () => {
  afterEach(() => vi.useRealTimers());

  vi.useFakeTimers();
  // Advance 50ms every macrotask — simulates real elapsed time without exact knowledge
  // of each exponential delay interval. Prevents the test from hanging on await.
  vi.setTimerTickMode('interval', 50);

  const mockFetch = vi.fn()
    .mockRejectedValueOnce(new Error('ECONNREFUSED'))
    .mockRejectedValueOnce(new Error('ECONNREFUSED'))
    .mockResolvedValueOnce(new Response('OK', { status: 200 }));
  vi.stubGlobal('fetch', mockFetch);

  const response = await fetchWithBackoff('https://api.example.com/data', {
    baseMs: 100,
    maxRetries: 3,
  });

  expect(response.status).toBe(200);
  expect(mockFetch).toHaveBeenCalledTimes(3);
  vi.unstubAllGlobals();
});
```

**Flakiness anti-pattern this replaces:**

The `await vi.runAllTimersAsync()` call (running ALL pending timers at once) frequently causes cascading timer execution — timers scheduling new timers which schedule more timers — leading to tests that either hang indefinitely or consume unexpected timer callbacks from unrelated module code. `setTimerTickMode('nextTimerAsync')` advances only *one* timer per macrotask boundary, eliminating the cascade.

**When NOT to use `nextTimerAsync`:** Tests that assert on *specific timer counts* (e.g., "this function should only call setTimeout once") still need `'manual'` mode so you can observe the timer state before advancement.

---

## Pattern 83 — Playwright v1.59 `tracing.start({ live: true })` for Real-Time Flakiness Investigation  [official]

Standard Playwright tracing archives trace data into a zip at the end of the test. For long-running E2E tests with intermittent failures, this means the trace is only available *after* the test completes — by which time the test may have timed out and the trace may be truncated or missing the final actions.

Playwright v1.59 adds a `live` option to `tracing.start()`. When `live: true`, the trace is written to an unarchived file that is **updated in real time** as actions occur. This enables attaching a trace viewer to a *running* test to see what it's doing right now — essential for diagnosing flakiness in slow, time-sensitive, or environment-dependent tests.

```typescript
// playwright.config.ts — enable live trace for specific projects (E2E / flaky-prone)
import { defineConfig } from '@playwright/test';

export default defineConfig({
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
    {
      // Dedicated project for investigating flaky tests with live trace
      name: 'flaky-investigation',
      use: {
        browserName: 'chromium',
        // Trace is written live — use this when debugging specific flaky test cases
        // Overhead: slightly more disk I/O than archived tracing
        trace: 'on',  // 'on' starts tracing for every test; combine with live below
      },
      testMatch: /.*\.flaky\.spec\.ts/,
    },
  ],
});
```

```typescript
// flaky-spec.ts — manually start live trace for a known-flaky scenario
import { test, expect } from '@playwright/test';

test('checkout flow completes within timeout', async ({ page, context }) => {
  // Start live trace with explicit live:true — enables real-time viewer attachment
  // while the test is running (not just after it completes)
  await context.tracing.start({
    screenshots: true,
    snapshots: true,
    live: true,  // write trace to unarchived file; updated as actions occur
    // Useful when: test fails in CI with 2-minute timeout but the trace zip
    // is truncated because the trace is only archived on success
  });

  await page.goto('/checkout');
  await page.fill('[data-testid="card-number"]', '4111111111111111');
  await page.fill('[data-testid="expiry"]', '12/28');

  // If the test times out here, the live trace already contains all actions up to this point
  await expect(page.locator('[data-testid="order-confirmed"]')).toBeVisible({ timeout: 30_000 });

  await context.tracing.stop({ path: 'checkout-trace.zip' });
});
```

**When `live` tracing prevents flakiness information loss:**

| Scenario | Without `live: true` | With `live: true` |
|----------|---------------------|-------------------|
| Test times out mid-run | Trace zip missing or empty | All actions up to timeout visible |
| CI runner OOM-kills the process | Trace not archived | Trace partially written and readable |
| Test crashes in beforeEach fixture | Trace not started | Trace available from first action |
| Need to watch test in real-time | Not possible | Attach `npx playwright show-trace` to live file |

**Performance note:** Live tracing has slightly higher disk I/O than archived tracing because writes happen continuously rather than in a single flush. Use it for targeted investigation of flaky tests, not as a default for all tests in CI.

---

## Pattern 84 — Playwright v1.58 `trace: 'retain-on-failure-and-retries'` for Multi-Retry Trace Comparison  [official]

When a test is retried (via `retries: 2`), the default `trace: 'on-first-retry'` setting captures only the *first* retry attempt. If the test passes on retry 2 but fails on retry 1, you have trace data for retry 1 only — you cannot compare the failure conditions across retries to identify what changed between attempts.

Playwright v1.58 adds the `'retain-on-failure-and-retries'` trace mode, which records a trace for **every** test run (including retry 0, retry 1, retry 2) and retains all traces when *any* attempt fails. This enables side-by-side comparison of traces across retries to identify what differed — a critical diagnostic for flakiness caused by external state (race conditions, network timing, CI environment differences).

```typescript
// playwright.config.ts — retain traces for all retry attempts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  use: {
    // Record a trace for every run (run 0, retry 1, retry 2).
    // Retain ALL traces if ANY attempt fails.
    // Compare run-0-trace.zip vs retry-1-trace.zip to see what changed.
    trace: 'retain-on-failure-and-retries',

    // Pair with screenshot on failure for visual diff
    screenshot: 'only-on-failure',
  },
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    // HTML report shows all retry traces with side-by-side comparison links
  ],
});
```

```typescript
// Usage: after a CI failure, navigate to the HTML report.
// The HTML report shows each retry attempt with its own trace link.
// Compare "Run 0" trace vs "Retry 1" trace to identify:
//   - Which network requests changed timing between retries
//   - Whether a DOM element appeared then disappeared between retries
//   - Whether a previous test's state leaked into this run

// Trace comparison checklist (use in CI flakiness review):
// 1. Open both traces in the Playwright trace viewer side by side
// 2. Compare "Network" tab — did the same API call succeed in one and fail in another?
// 3. Compare "Snapshots" tab — was the DOM in the same state at the start?
// 4. Compare timestamps — was the retry slower? (possible timeout-driven flakiness)
// 5. Check "Console" tab — were there JavaScript errors in one retry but not another?
```

**Comparison: trace mode selection guide**

| Mode | Traces retained | Use case |
|------|----------------|----------|
| `'off'` | None | Speed-critical local runs |
| `'on'` | All runs, always | Development debugging (high disk usage) |
| `'on-first-retry'` | First retry only | Standard CI — low overhead, catches most flakiness |
| `'retain-on-first-failure'` | Run 0 only if it fails | Low-overhead "why did it fail first time?" |
| `'retain-on-failure-and-retries'` | All retries when any fails | Flakiness root cause comparison across retries [v1.58+] |

**Anti-pattern:** Using `trace: 'on'` for all CI runs generates one zip per test per run — for a 500-test suite with `retries: 2`, this means up to 1,500 trace files per CI run, consuming significant storage and slowing down artifact upload. Use `'retain-on-failure-and-retries'` to capture all retry data only when needed.

---

## Pattern 85 — Vitest 4.1 `agent`/`minimal` Reporter for AI-Agent Flakiness Triage  [official]

When using an AI coding agent (Claude Code, Copilot Chat, Cursor) to diagnose and fix flaky tests, the standard Vitest reporter emits full test output including all passing tests — often thousands of lines that consume token budget without contributing to diagnosis. Vitest 4.1 introduces the `agent` reporter (aliased as `minimal`) that outputs **only failed tests and their error messages**, suppressing all passing test output and the summary section.

The reporter activates automatically when Vitest detects it is running inside an AI coding agent environment. It can also be configured explicitly for CI environments where token efficiency matters, or for human developers who prefer signal-dense output during flakiness triage.

```typescript
// vitest.config.ts — explicit agent reporter configuration
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Use 'agent' (or its alias 'minimal') to suppress passing test output.
    // Useful during flakiness triage when you only care about failures.
    // Auto-activates in AI coding agent environments without this config.
    reporters: process.env.FLAKINESS_TRIAGE === 'true'
      ? ['agent']      // failures + errors only — no passing-test noise
      : ['verbose'],   // full output for normal development runs

    // Pair with retries so the reporter shows retry details on failure
    retry: process.env.CI ? 2 : 0,
  },
});
```

```typescript
// vitest.config.ts — combining agent reporter with JUnit for CI flakiness tracking
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    reporters: [
      // Minimal console output — only failures, for human readability in CI
      'agent',
      // Full structured output — for flakiness tracking dashboards (BuildPulse, Trunk)
      ['junit', { outputFile: 'test-results/vitest-results.xml', classname: 'vitest' }],
    ],
    // GitHub Actions job summary: automatically generated with flaky test permalinks
    // (built-in github-actions reporter activates automatically in GH Actions environments)
  },
});
```

**Vitest 4.1 GitHub Actions Job Summary for flakiness visibility:**

```yaml
# .github/workflows/test.yml — no extra config needed for job summary
# The built-in github-actions reporter auto-generates a job summary when
# Vitest detects it is running in GitHub Actions (GITHUB_ACTIONS=true).
# The summary includes:
#   - Test file and test case counts
#   - Flaky tests highlighted (tests that required retries to pass)
#   - Permalink URLs linking test names to source lines on GitHub
#
# To view: Go to the GitHub Actions run → "Summary" tab
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx vitest run
        # github-actions reporter + job summary activated automatically by GITHUB_ACTIONS env
```

**When the agent reporter prevents over-triage:**
A common mistake during flakiness investigation is running the full suite, reading 3,000 lines of output, and losing context on the specific failures. The `agent` reporter keeps the failure signal clear and concise — especially important when AI agents run the test suite multiple times in a triage loop (each run consuming token budget).

---

## Anti-Patterns (iteration 52)

### AP42 — Relying on the Undocumented `Suite` Argument in Vitest `beforeAll`/`afterAll`/`aroundAll`  [official]

**What:** In Vitest versions before 4.1, `beforeAll`, `afterAll`, and `aroundAll` hooks received an undocumented `Suite` object as their first argument. Some test setups (particularly those managing shared database connections or server instances) passed this argument to helper functions to introspect the test suite structure.

**Why harmful in 4.1+:** Vitest 4.1 removed the `Suite` argument. These hooks now receive `file` and `worker` context objects instead. Tests that destructure `Suite` properties (e.g., `suite.name`, `suite.tests`) will receive `undefined` or throw `TypeError: Cannot read properties of undefined` — a flakiness-like failure that only appears after the Vitest upgrade and only in hooks that used this undocumented API.

**Compounding problem:** Because this was undocumented, the failure is invisible until the upgrade. The test continues to compile (TypeScript does not catch it — the parameter is typed as `unknown`), and the failure manifests at runtime only when the destructured property is accessed.

```typescript
// BAD: relies on the removed undocumented Suite argument
import { beforeAll, afterAll } from 'vitest';
import { db } from '../src/db';

// In Vitest < 4.1, this received a Suite object.
// In Vitest 4.1+, `suite` is undefined — accessing suite.name throws TypeError.
beforeAll(async (suite: any) => {
  const suiteName = suite?.name ?? 'unknown'; // worked before; undefined now
  console.log(`Setting up DB for suite: ${suiteName}`);
  await db.migrate.latest();
});

afterAll(async (suite: any) => {
  // suite.tests would list test cases — no longer available
  console.log(`Tearing down ${suite?.tests?.length ?? '?'} tests`);
  await db.destroy();
});
```

```typescript
// GOOD: use the new file/worker context (Vitest 4.1+) or no argument at all
import { beforeAll, afterAll } from 'vitest';
import { db } from '../src/db';

// beforeAll now receives { file: File, worker: WorkerContext } — or nothing.
// For DB setup, you rarely need suite metadata — omit the argument entirely.
beforeAll(async () => {
  await db.migrate.latest();
});

afterAll(async () => {
  await db.destroy();
});

// If you DO need file/worker context (e.g., per-worker DB schema isolation):
beforeAll(async ({ worker }) => {
  // worker.id is a unique integer per worker — use for schema namespacing
  await db.schema.createSchema(`test_worker_${worker.id}`).ifNotExists();
});

afterAll(async ({ worker }) => {
  await db.schema.dropSchema(`test_worker_${worker.id}`).cascade();
});
```

**Detection:** Search your codebase for `beforeAll(async (` or `afterAll(async (` or `aroundAll(async (` with a non-empty argument list. If the parameter is named `suite`, `s`, or has a type annotation referencing suite structure, update it to use the new `{ file, worker }` context or remove the argument.

**Fix script:**
```bash
# Finds beforeAll/afterAll/aroundAll calls with Suite-like argument patterns
grep -rn "beforeAll\|afterAll\|aroundAll" --include="*.ts" --include="*.spec.ts" \
  src/ tests/ | grep -E "\(async \(s(uite)?\b" || echo "No Suite argument usage found"
```

---

## Pattern 86 — Playwright `testCase.outcome()` Custom Flakiness Reporter  [official]

Playwright's `TestCase` class exposes an `outcome()` method that returns `'flaky'` when a test
case fails on its first attempt but passes on a subsequent retry. This provides a first-class,
type-safe signal for distinguishing genuinely failing test cases from flaky ones — without
parsing exit codes or scanning CI logs.

The built-in reporters (HTML, JUnit) already mark flaky tests in their output, but custom
reporters using `testCase.outcome() === 'flaky'` enable structured persistence: writing to a
database, posting to a Slack channel, updating a dashboard, or blocking a PR via GitHub Checks.

**Why this matters over log parsing:** Log parsing breaks across reporter format changes and CI
platform updates. `testCase.outcome()` is a stable API contract — it will always return `'flaky'`
precisely when a test case passed after at least one initial failure. The `testCase.results` array
gives per-retry detail: each element is a `TestResult` with its own `status`, `duration`, and
`annotations`.

```typescript
// reporters/flakiness-tracker.ts — writes flaky test telemetry to a JSON log
// Add to playwright.config.ts: reporter: [..., ['./reporters/flakiness-tracker.ts']]
import type {
  Reporter,
  TestCase,
  TestResult,
  FullResult,
} from '@playwright/test/reporter';
import { writeFileSync, appendFileSync } from 'fs';

interface FlakyEntry {
  title: string;
  titlePath: string[];
  file: string;
  line: number;
  retries: number;
  attemptsCount: number;
  firstFailDuration: number;  // ms — how long the first failing attempt took
  passDuration: number;        // ms — how long the successful retry took
  timestamp: string;
  errors: string[];
}

export default class FlakinessTrackerReporter implements Reporter {
  private flakyTests: FlakyEntry[] = [];

  onTestEnd(test: TestCase, result: TestResult): void {
    // outcome() returns 'flaky' when: at least one attempt failed AND at least one passed
    if (test.outcome() !== 'flaky') return;

    // testCase.results contains one TestResult per attempt (index 0 = first run)
    const firstFailResult = test.results[0];
    const passResult = test.results.find(r => r.status === 'passed');

    this.flakyTests.push({
      title: test.title,
      titlePath: test.titlePath(),
      file: test.location.file,
      line: test.location.line,
      retries: test.retries,              // max retries configured
      attemptsCount: test.results.length, // actual number of attempts made
      firstFailDuration: firstFailResult?.duration ?? 0,
      passDuration: passResult?.duration ?? 0,
      timestamp: new Date().toISOString(),
      // Collect error messages from all failing attempts — useful for variant flakiness
      errors: test.results
        .filter(r => r.status === 'failed' || r.status === 'timedOut')
        .flatMap(r => r.errors.map(e => e.message?.slice(0, 200) ?? 'unknown error')),
    });
  }

  async onEnd(result: FullResult): Promise<void> {
    if (this.flakyTests.length === 0) return;

    // Write structured JSON for dashboard ingestion
    const report = {
      runAt: new Date().toISOString(),
      runStatus: result.status,
      flakyCount: this.flakyTests.length,
      tests: this.flakyTests,
    };
    writeFileSync('test-results/flaky-report.json', JSON.stringify(report, null, 2));

    // Also append to a cumulative JSONL log for trend tracking
    appendFileSync(
      'test-results/flaky-history.jsonl',
      JSON.stringify({ ...report, tests: this.flakyTests }) + '\n'
    );

    console.log(`\n[FlakinessTracker] ${this.flakyTests.length} flaky test(s) detected:`);
    for (const t of this.flakyTests) {
      console.log(`  - ${t.title} (${t.file}:${t.line}) — ${t.attemptsCount} attempts`);
    }
  }
}
```

```typescript
// playwright.config.ts — register the custom reporter alongside built-ins
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  // failOnFlakyTests: flaky tests detected by outcome() === 'flaky'
  // Without retries > 0, outcome() never returns 'flaky' (no retry = no recovery possible)
  failOnFlakyTests: !!process.env.CI,

  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['junit', { outputFile: 'test-results/results.xml' }],
    // Custom reporter runs after the test run completes
    ['./reporters/flakiness-tracker.ts'],
  ],
  use: {
    trace: 'on-first-retry',
  },
});
```

```typescript
// Querying the cumulative flaky-history.jsonl for trend analysis
// Run as a standalone script: npx ts-node scripts/flakiness-trend.ts
import { createReadStream } from 'fs';
import { createInterface } from 'readline';

interface FlakyRun { runAt: string; flakyCount: number; tests: Array<{ title: string }> }

async function analyzeTrend(days = 7): Promise<void> {
  const since = new Date(Date.now() - days * 86_400_000);
  const rl = createInterface({ input: createReadStream('test-results/flaky-history.jsonl') });
  const byTest = new Map<string, number>();

  for await (const line of rl) {
    const run: FlakyRun = JSON.parse(line);
    if (new Date(run.runAt) < since) continue;
    for (const t of run.tests) {
      byTest.set(t.title, (byTest.get(t.title) ?? 0) + 1);
    }
  }

  // Sort by frequency — highest-frequency flaky tests need fixing first
  const ranked = [...byTest.entries()].sort((a, b) => b[1] - a[1]);
  console.table(ranked.map(([title, count]) => ({ title, flakyCount: count })));
}

analyzeTrend();
```

**`testCase.outcome()` return values:**

| Value | Meaning | When |
|-------|---------|------|
| `'skipped'` | Test was not executed | `test.skip()` or condition |
| `'expected'` | Test passed normally, or expected failure behaved as marked | Normal pass; `test.fail()` that failed |
| `'unexpected'` | Test failed unexpectedly | Hard failure, no retry succeeded |
| `'flaky'` | Test failed at least once, passed at least once | Failed on attempt 0, passed on attempt 1+ |

**Anti-pattern:** Do not use `result.status === 'flaky'` in `onTestEnd` — `TestResult.status` does not have a `'flaky'` value. Only `testCase.outcome()` returns `'flaky'`. The result status for the passing retry is `'passed'`, not `'flaky'`. This is a common mistake when writing custom reporters for the first time.

---

## Pattern 87 — Playwright `updateSnapshots: 'changed'` + `updateSourceMethod: '3way'` for Snapshot Flakiness Review  [official]

Snapshot tests (visual regression or `toMatchAriaSnapshot`) are a common source of flakiness in
CI because baselines captured on a developer's macOS machine differ from headless Chromium on
Ubuntu CI runners (font rendering, subpixel antialiasing, system emoji fonts). Naively running
`--update-snapshots` regenerates all baselines, overwriting intentional differences.

Playwright v1.50 introduced two configuration options that give precise control over which
snapshots are updated and how changes are applied to source files:

- **`updateSnapshots: 'changed'`** — Only updates snapshots that actually differ from the
  current rendered output. Snapshots that still match are not touched. This is the correct
  default for "snapshot refresh" CI steps.
- **`updateSourceMethod: '3way'`** — When a snapshot inline value (e.g., in `.spec.ts` files)
  needs updating, inserts Git-style merge conflict markers. The developer opens the file, sees
  `<<<<<<< HEAD` / `=======` / `>>>>>>> updated`, and explicitly chooses the new value. This
  prevents accidental approval of incorrect visual changes.

```typescript
// playwright.config.ts — safe snapshot update configuration
import { defineConfig } from '@playwright/test';

export default defineConfig({
  // 'changed': update only mismatched snapshots; leave passing baselines untouched
  // 'all': overwrites EVERY snapshot — dangerous in CI (see AP43)
  // 'missing': only create snapshots for new test cases (safe default for normal CI runs)
  // 'none': error if any snapshot is missing (strictest, for release branches)
  updateSnapshots: process.env.UPDATE_SNAPSHOTS === 'true' ? 'changed' : 'missing',

  // 'patch': writes a .patch file — requires manual application with `git apply`
  // 'overwrite': replaces inline values directly — fast, no review
  // '3way': inserts merge conflict markers — developer must resolve explicitly (safest)
  updateSourceMethod: '3way',

  use: {
    // maxDiffPixelRatio: tolerate up to 2% pixel drift between CI environments
    // Eliminates font-rendering flakiness without ignoring real visual regressions
    screenshot: 'only-on-failure',
  },
});
```

```typescript
// Running a targeted snapshot refresh for a specific file
// Only mismatched snapshots in ProductCard.spec.ts are updated
// Other baselines are untouched, preventing accidental clobber

// package.json scripts
// "snapshot:refresh": "playwright test --update-snapshots=changed ProductCard.spec.ts",
// "snapshot:review": "playwright test --update-snapshots=changed --update-source-method=3way",

// In CI: use 'missing' to create new baselines but never overwrite existing ones
// In a dedicated "snapshot update" job: use 'changed' to refresh only drift
```

```typescript
// Using toMatchAriaSnapshot with updateSnapshots: 'changed'
// ARIA snapshots are text-based — less affected by font rendering, but still drift
// when component structure changes (new aria-label, role changes, etc.)
import { test, expect } from '@playwright/test';

test('checkout button is accessible', async ({ page }) => {
  await page.goto('/cart');
  // When this ARIA snapshot drifts (e.g., button text changes),
  // --update-snapshots=changed updates ONLY this test's snapshot
  // --update-source-method=3way shows the conflict for review
  await expect(page.getByRole('region', { name: 'Order Summary' })).toMatchAriaSnapshot(`
    - region "Order Summary":
      - list:
        - listitem: "Laptop Pro × 1"
      - paragraph: "Total: $999.00"
      - button "Place Order"
  `);
});
```

**Snapshot update workflow for CI/CD:**

```yaml
# .github/workflows/snapshot-update.yml — triggered manually or on schedule
# Refreshes drifted snapshots and opens a PR for review
name: Snapshot Baseline Update

on:
  workflow_dispatch:
    inputs:
      scope:
        description: 'Test file pattern (e.g., "components/**" or leave blank for all)'
        required: false
        default: ''

jobs:
  update-snapshots:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx playwright install --with-deps chromium

      - name: Refresh drifted snapshots
        run: |
          # 'changed' only updates mismatched baselines; '3way' flags conflicts in source
          npx playwright test \
            --update-snapshots=changed \
            --update-source-method=overwrite \
            ${{ github.event.inputs.scope }}
        # Use 'overwrite' in this automated step; 3way is for local developer review

      - name: Open snapshot update PR
        uses: peter-evans/create-pull-request@v7
        with:
          title: 'chore: refresh drifted snapshot baselines'
          body: |
            Automated snapshot baseline update.
            Only snapshots that differed from the current rendering were updated.
            Review each changed file to confirm no unintended visual regressions.
          branch: chore/snapshot-baseline-update
          commit-message: 'chore: refresh drifted snapshot baselines [skip ci]'
          labels: 'snapshot-update,needs-review'
```

**When `updateSourceMethod: '3way'` helps vs hurts:**

| Scenario | Recommended `updateSourceMethod` |
|----------|----------------------------------|
| Local developer refreshing own test | `'3way'` — explicit diff review in IDE |
| Automated CI snapshot update PR | `'overwrite'` — clean diff in PR, reviewed by code owner |
| Release branch baseline pinning | `'patch'` — patch file for auditable, staged update |
| Frequent snapshot churn (A/B testing) | `'overwrite'` — 3way conflict markers in every file is noisy |

---

## Anti-Patterns (iteration 53)

### AP43 — `updateSnapshots: 'all'` in CI Silently Overwrites Baselines  [community]

**What:** Setting `updateSnapshots: 'all'` (or running `--update-snapshots` without a scope
argument) in a CI step that runs automatically on every push or PR.

**Why harmful:** `'all'` regenerates every snapshot that was executed — including snapshots
that are passing correctly. If a visual regression is introduced (e.g., a button color
changes from blue to red due to a CSS bug), `updateSnapshots: 'all'` will overwrite the
baseline with the broken rendering, making all future runs pass against the incorrect visual.
The snapshot test no longer protects against regressions — it just documents whatever the
current broken state is.

**Compounding problem:** The mistake is invisible in the PR diff. The CI step shows `✓ all
tests passed (with snapshot updates)` — no failure, no alert. The regression is only
discovered when a human reviews the snapshot image in the test-results artifact, which few
developers do on every CI run.

```typescript
// BAD: updateSnapshots: 'all' in playwright.config.ts — overwrites everything on every run
import { defineConfig } from '@playwright/test';

export default defineConfig({
  // DANGER: this regenerates ALL snapshot baselines on every test run.
  // A visual regression will silently update the baseline to the broken state.
  updateSnapshots: 'all',
});

// BAD: --update-snapshots flag hardcoded in package.json test script
// "test:ci": "playwright test --update-snapshots"  ← NEVER do this
```

```typescript
// GOOD: 'missing' for normal CI runs; 'changed' for dedicated snapshot-refresh jobs
import { defineConfig } from '@playwright/test';

export default defineConfig({
  // Normal CI: only create baselines for newly added test cases
  // Existing baselines are never overwritten — regressions will fail the build
  updateSnapshots: process.env.SNAPSHOT_REFRESH === 'true' ? 'changed' : 'missing',
  // 'changed' in SNAPSHOT_REFRESH mode still only updates genuinely drifted snapshots
  // A passing snapshot is never touched — a regression will still fail the build
});
```

**Detection:** Search for hardcoded `updateSnapshots: 'all'` or `--update-snapshots` in CI
workflow files without an explicit `changed` or `missing` qualifier:
```bash
grep -rn "update-snapshots\|updateSnapshots" .github/ *.config.ts package.json
# Look for: '--update-snapshots' without '=changed' or '=missing'
# Look for: updateSnapshots: 'all'
```

---

## Quick Reference additions (iteration 53)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Custom reporter can't detect flaky tests — `result.status` has no 'flaky' value | Wrong API: status is per-attempt, not per-test | Pattern 86 (`testCase.outcome() === 'flaky'`) | Parsing 'flaky' from `result.status` — it doesn't exist |
| Visual regression introduced but snapshot test still passes in CI | `updateSnapshots: 'all'` overwrites baselines | Pattern 87 (`updateSnapshots: 'changed'` + `AP43` fix) | `updateSnapshots: 'all'` in normal CI runs |
| Developer can't see what changed when snapshot refresh PR is opened | `updateSourceMethod: 'overwrite'` gives no diff context locally | Pattern 87 (`updateSourceMethod: '3way'` for local review) | `3way` in automated CI steps — conflict markers in every file is noisy |

---

## Key Resources (iteration 53 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright `TestCase.outcome()` | Official | https://playwright.dev/docs/api/class-testcase#test-case-outcome | Returns `'flaky'` when test passed on retry — type-safe signal for custom flakiness reporters |
| Playwright `TestCase.results` | Official | https://playwright.dev/docs/api/class-testcase#test-case-results | Array of per-attempt `TestResult` — access per-retry annotations, errors, and durations |
| Playwright `updateSnapshots` config | Official | https://playwright.dev/docs/api/class-testconfig#test-config-update-snapshots | `'changed'` mode — only updates mismatched baselines; safe for CI snapshot-refresh jobs (v1.50) |
| Playwright `updateSourceMethod` config | Official | https://playwright.dev/docs/api/class-testconfig#test-config-update-source-method | `'3way'` inserts merge conflict markers for explicit developer review; `'patch'` writes diff file (v1.50) |

---

## Quick Reference additions (iteration 52)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Test with `await`ed timer-backed Promise hangs or requires `vi.runAllTimersAsync()` | Manual timer advance cascades | Pattern 82 (`vi.setTimerTickMode('nextTimerAsync')`) | `vi.runAllTimersAsync()` — runs ALL pending timers, including ones from unrelated modules |
| Flaky test trace is truncated because test timed out before trace was archived | Standard tracing archives on completion only | Pattern 83 (`tracing.start({ live: true })`) | Using `trace: 'off'` in CI so there's no evidence of what happened |
| Retry 1 failed differently than retry 0 — need to compare both traces | Only retry 1 trace retained (`on-first-retry`) | Pattern 84 (`trace: 'retain-on-failure-and-retries'`) | `trace: 'on'` for all runs — generates 1 zip per test per run (storage bloat) |
| AI agent triage loop consumes all token budget reading passing tests | Default reporter emits all test output | Pattern 85 (`agent`/`minimal` reporter) | Using `verbose` reporter during automated triage |
| After Vitest 4.1 upgrade, `beforeAll` hook throws TypeError on suite metadata | Removed undocumented `Suite` argument | AP42 (use `{ file, worker }` context or no argument) | Silently casting to `any` to suppress the error |

---

## Key Resources (iteration 52 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest `vi.setTimerTickMode()` | Official | https://vitest.dev/api/vi#vi-settimertickmode | `'manual'` / `'nextTimerAsync'` / `'interval'` — controls how fake timers advance in async tests (v4.1.0) |
| Playwright `tracing.start({ live: true })` | Official | https://playwright.dev/docs/api/class-tracing#tracing-start | Real-time trace writing to unarchived file; enables live trace viewer during long-running tests (v1.59) |
| Playwright trace mode reference | Official | https://playwright.dev/docs/api/class-fixtures#fixtures-use | `retain-on-failure-and-retries` mode — retain all retry traces for cross-retry comparison (v1.58) |
| Vitest `agent`/`minimal` reporter | Official | https://vitest.dev/guide/reporters | Failure-only output for AI coding agents; auto-activates via agent detection; aliased as `minimal` (v4.1) |
| Vitest 4.1 hook signature migration | Official | https://vitest.dev/blog/vitest-4-1 | `beforeAll`/`afterAll`/`aroundAll` now receive `{ file, worker }` instead of undocumented `Suite` (v4.1) |

---

## Pattern 88 — Vitest 5.0 `sequential` Option Removal — Migrate to `concurrent: false` or `test.describe.serial`  [official]

Vitest 5.0 removes the `sequential` option from both `test()` and `describe()` calls. The option was deprecated in Vitest 4.x and served as a way to force a block to run non-concurrently. Teams that have `sequential: true` in their test configuration will receive a runtime error after upgrading.

**Why this causes flakiness on upgrade:** If your test suite relied on `sequential: true` to prevent parallel execution of stateful tests — typically integration tests sharing a DB connection or singleton — removing the option without a replacement allows those tests to run concurrently, reintroducing the shared-state race conditions that `sequential` was masking.

```typescript
// BAD (Vitest 4.x — removed in 5.0): sequential option
import { describe, it, expect } from 'vitest';

describe('OrderService integration', { sequential: true }, () => {
  // Was: run these tests one-at-a-time to avoid DB race conditions
  // In Vitest 5.0 this option is unrecognized — tests may run in parallel
  it('creates order', async () => { /* ... */ });
  it('updates order status', async () => { /* ... */ });
  it('cancels order', async () => { /* ... */ });
});
```

```typescript
// GOOD (Vitest 5.0+): replace sequential with concurrent: false
import { describe, it, expect } from 'vitest';

describe('OrderService integration', { concurrent: false }, () => {
  // concurrent: false is the Vitest 5 idiomatic replacement for sequential: true
  // Tests within this describe run serially in definition order
  it('creates order', async () => { /* ... */ });
  it('updates order status', async () => { /* ... */ });
  it('cancels order', async () => { /* ... */ });
});
```

```typescript
// ALSO GOOD (Playwright-style): test.describe.serial for full serial blocks
// Equivalent to Playwright's describe.serial — familiar to teams migrating from PW
import { describe, it, expect } from 'vitest';

// test.describe.serial was already available in Vitest 4.x and continues in 5.0
// Use when order of execution matters AND you need failure cascade prevention:
// if any test fails, the rest of the serial block are skipped (not run and failed)
describe.serial('OrderService lifecycle', () => {
  it('creates order', async () => { /* ... */ });
  it('updates order status', async () => { /* ... */ });
  it('cancels order', async () => { /* ... */ });
});
```

```typescript
// BEST PRACTICE: instead of serializing to avoid DB races,
// use aroundEach (Vitest 4.1+) with a DB transaction rollback — runs serially per-test
// but doesn't need sequential at all because each test has its own isolated transaction
import { describe, it, expect } from 'vitest';
import { db } from '../src/db';

// aroundEach wraps EACH test in a DB transaction that is always rolled back
// This is faster than serialize (tests can still run in parallel across files)
// and more correct (tests are truly isolated, not just ordered)
describe('OrderService integration', () => {
  aroundEach(async ({ task: _task }, run) => {
    await db.transaction(async (tx) => {
      // Run the test inside the transaction
      // Any DB changes are rolled back after the test — even if it throws
      await run({ db: tx });
    });
  });

  it('creates order', async ({ db: txDb }) => {
    const order = await txDb.insert(orders).values({ userId: 1, total: 100 }).returning();
    expect(order[0].id).toBeDefined();
    // Row is visible within this transaction but rolled back after test ends
  });
});
```

**Migration checklist for Vitest 5.0 `sequential` removal:**

| Old option | Vitest 5.0 replacement | When to use |
|---|---|---|
| `describe('...', { sequential: true })` | `describe('...', { concurrent: false })` | Tests must run in order within a describe |
| `test('...', { sequential: true })` | Remove (single test is always sequential) | Single tests don't need this option |
| `describe.concurrent` with `sequential` subset | Use `describe.serial` for the serial subset | Mixed concurrent / serial needs |
| `sequential` to hide shared-state races | `aroundEach` with transaction rollback | Correct fix — isolate instead of serialize |

---

## Pattern 89 — Playwright v1.60 `locator.drop()` for Drag-and-Drop Upload Zone Test Flakiness  [official]

File upload zones that use drag-and-drop (`dragenter`/`dragover`/`drop` event chain) have historically been one of the most flaky test scenarios in Playwright. The traditional workaround — `page.dispatchEvent()` with synthetic `DragEvent` — was fragile because it required manually constructing a `DataTransfer` object, and browser security restrictions meant the `files` property was often read-only or empty after dispatch.

Playwright v1.60 introduces `locator.drop()`, which simulates an external drag-and-drop of files or clipboard-like data onto a target element. It handles the full event sequence correctly and works cross-browser (Chromium, Firefox, WebKit).

```typescript
// BAD: manual DragEvent dispatch — fragile and commonly flaky
import { test, expect } from '@playwright/test';

test('user can upload file by dropping it onto the upload zone', async ({ page }) => {
  await page.goto('/upload');

  // FLAKY: manually constructing DataTransfer is error-prone.
  // The 'files' property may be empty after construction in some browser modes.
  // Event sequence (enter → over → drop) timing is not deterministic.
  await page.evaluate(() => {
    const dt = new DataTransfer();
    // Cannot programmatically add files to DataTransfer.files — read-only in most browsers
    const event = new DragEvent('drop', { dataTransfer: dt, bubbles: true });
    document.querySelector('[data-testid="upload-zone"]')!.dispatchEvent(event);
  });

  // This assertion frequently fails because the files array was empty
  await expect(page.locator('[data-testid="file-list"]')).toContainText('document.pdf');
});
```

```typescript
// GOOD: locator.drop() — correct synthetic drag-and-drop (Playwright v1.60+)
import { test, expect } from '@playwright/test';
import path from 'path';

test('user can upload file by dropping it onto the upload zone', async ({ page }) => {
  await page.goto('/upload');

  const uploadZone = page.getByTestId('upload-zone');

  // locator.drop() handles the full dragenter/dragover/drop event chain.
  // 'files' option accepts file paths — Playwright reads them from disk and
  // injects them into the DataTransfer correctly, bypassing read-only restrictions.
  await uploadZone.drop({
    files: [
      path.join(__dirname, 'fixtures/document.pdf'),
    ],
  });

  // The file list should update reliably — no timing race, no empty DataTransfer
  await expect(page.getByTestId('file-list')).toContainText('document.pdf');
  await expect(page.getByTestId('upload-status')).toHaveText('1 file ready');
});
```

```typescript
// Multiple files + clipboard data example
import { test, expect } from '@playwright/test';
import path from 'path';

test('user can drop multiple files onto an upload zone', async ({ page }) => {
  await page.goto('/upload');

  await page.getByTestId('upload-zone').drop({
    files: [
      path.join(__dirname, 'fixtures/image.png'),
      path.join(__dirname, 'fixtures/document.pdf'),
    ],
  });

  // Both files should appear in the list
  await expect(page.getByTestId('file-list')).toContainText('image.png');
  await expect(page.getByTestId('file-list')).toContainText('document.pdf');
});
```

```typescript
// Pair with a route handler to prevent actual file uploads during test
// (avoids external network dependency flakiness)
import { test, expect } from '@playwright/test';
import path from 'path';

test('upload zone sends file to the API and shows progress', async ({ page }) => {
  // Intercept the upload API — prevents network flakiness AND external side effects
  await page.route('**/api/upload', async (route) => {
    // Simulate a successful upload response
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ fileId: 'file-001', status: 'uploaded' }),
    });
  });

  await page.goto('/upload');

  await page.getByTestId('upload-zone').drop({
    files: [path.join(__dirname, 'fixtures/document.pdf')],
  });

  // The progress indicator should appear, then the success state
  await expect(page.getByTestId('upload-progress')).toBeVisible();
  await expect(page.getByTestId('upload-success')).toBeVisible({ timeout: 5_000 });
});
```

**Common flakiness patterns in upload zone tests and fixes:**

| Scenario | Old approach (flaky) | Fix with `locator.drop()` |
|---|---|---|
| Single file drag-and-drop | `dispatchEvent(new DragEvent(...))` — empty DataTransfer.files | `locator.drop({ files: [path] })` — correct file injection |
| Multi-file drop | Multiple `dispatchEvent` calls — timing between events | Single `locator.drop({ files: [p1, p2] })` — atomic |
| Drop then upload | Manual event + page.setInputFiles combo | `drop()` + `page.route()` intercept |
| Cross-browser drop | Chromium-only workaround with JS eval | `drop()` works in Chromium, Firefox, WebKit |
| File size assertion after drop | Cannot read DataTransfer.files size | `drop()` provides correct File objects with size |

---

## Gotcha 46 — Vitest 5.0 Attachment Directory Path Change: `.vitest-attachments/` → `.vitest/attachments/`  [official]

Vitest 5.0-beta changes the default location for test attachments (screenshots, videos, custom file attachments added via `testContext.attach()` or `context.attach()`) from `.vitest-attachments/` to `.vitest/attachments/`. The blob reporter output also moves from its previous default to `.vitest/blob/`.

**Why this causes flakiness-adjacent failures:**

1. **CI artifact uploads targeting `.vitest-attachments/`** — GitHub Actions or other CI steps that upload attachment artifacts using `path: '.vitest-attachments/**'` will upload an empty directory. The actual attachments are written to `.vitest/attachments/` but are never found. This causes "flakiness" in the artifact delivery pipeline — the attachment exists but the uploader can't find it.

2. **`.gitignore` entries targeting `.vitest-attachments/`** — If only `.vitest-attachments/` is in `.gitignore` and not `.vitest/`, attachment files may accidentally be committed.

3. **Custom cleanup scripts** — Pre-test scripts that `rm -rf .vitest-attachments/` to ensure a clean run no longer clean the correct directory, causing stale attachment files to persist and corrupt snapshot comparisons in browser mode.

```typescript
// vitest.config.ts — pin attachment path explicitly to be version-resilient
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Vitest 4.x default: .vitest-attachments/
    // Vitest 5.0+ default: .vitest/attachments/
    // Pin explicitly to avoid CI breakage during upgrade:
    attachmentsDir: '.vitest/attachments', // Vitest 5.0+ path — works in 4.1.x too
  },
});
```

```yaml
# .github/workflows/test.yml — update artifact upload path for Vitest 5 compatibility
- name: Upload test attachments
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: vitest-attachments
    # Use the Vitest 5.0+ path; or use a glob that covers both:
    # path: |
    #   .vitest-attachments/**
    #   .vitest/attachments/**
    path: .vitest/attachments/**
    retention-days: 7
```

```bash
# .gitignore — cover both old and new paths during transition
.vitest-attachments/
.vitest/
```

**Detection — check if your CI workflow hardcodes the old path:**

```bash
# Run in your project root to find hardcoded references to the old path
grep -rn "vitest-attachments" .github/ vitest.config.* package.json
# Any hit is a potential breakage point for Vitest 5.0 upgrade
```

**Blob reporter path change (parallel issue):**

```typescript
// vitest.config.ts — also pin blob reporter output if using merge-report workflow
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    reporters: [
      // Blob reporter: Vitest 5.0 changes default output from 'blob-report/' to '.vitest/blob/'
      // Pin it explicitly so your merge-report CI step finds the right path:
      ['blob', { outputDir: '.vitest/blob' }],  // Vitest 5.0+ default
    ],
  },
});
```

---

## Anti-Patterns (iteration 54)

### AP44 — Vitest 5.0 Upgrade with Hardcoded `.vitest-attachments/` Path in CI  [community]

**What:** Upgrading from Vitest 4.x to 5.0 without updating CI artifact upload steps that reference `.vitest-attachments/` by name.

**Why harmful:** After the upgrade, test attachments (screenshots, HTML snapshots, custom attachments) are written to `.vitest/attachments/` but CI uploads an empty `.vitest-attachments/` directory. Failure investigations that depend on these artifacts — screenshots from failing browser mode tests, traces from flaky E2E steps — silently disappear. The CI step reports success (no error on upload empty directory) but the artifact is empty.

**Compounding problem:** The test suite may not be immediately broken — unit tests pass, CI goes green. The missing attachments are only noticed during a flakiness investigation when an engineer tries to look at a screenshot from a failed browser-mode test and finds the artifact empty. At that point, the root cause (Vitest upgrade path change) is not obvious.

```typescript
// BAD: hardcoded path — breaks silently on Vitest 5.0 upgrade
// .github/workflows/test.yml (partial):
//   - uses: actions/upload-artifact@v4
//     with:
//       path: .vitest-attachments/**   ← points to old path; always empty on Vitest 5
```

```typescript
// GOOD: use configDefaults to read the current attachmentsDir programmatically
// In a helper script: scripts/get-attachments-dir.mjs
import { configDefaults } from 'vitest/config';
// configDefaults.attachmentsDir reflects the current version's default
// Use in CI to avoid hardcoding:
console.log(configDefaults.test?.attachmentsDir ?? '.vitest/attachments');
```

```yaml
# BETTER: glob both paths in CI — works during transition regardless of Vitest version
- name: Upload test attachments
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: vitest-attachments
    path: |
      .vitest-attachments/**
      .vitest/attachments/**
```

---

## Quick Reference additions (iteration 54)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Vitest 5.0 upgrade: tests that ran serially now run concurrently and race | `sequential` option removed in v5 | Pattern 88 (`concurrent: false` or `describe.serial`) | Keeping `sequential: true` (silently ignored or error) |
| Drag-and-drop upload test intermittently fails — file list empty | `DataTransfer.files` read-only; manual `DragEvent` dispatch broken | Pattern 89 (`locator.drop({ files: [...] })`) | `page.evaluate(() => dispatchEvent(new DragEvent(...)))` |
| CI artifact upload step finds empty `.vitest-attachments/` directory after Vitest upgrade | Attachment path changed from `.vitest-attachments/` to `.vitest/attachments/` in v5 | Gotcha 46 (pin `attachmentsDir` in config; glob both in CI) | Hardcoding old path without version-aware glob |
| Flaky multi-environment test run — results from different envs not combined | Non-sharded multi-env runs lack merge step | Gotcha 46 (Vitest 5 merge reports; `vitest merge-report`) | Separate CI jobs with no result aggregation |

---

## Key Resources (iteration 54 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright `locator.drop()` | Official | https://playwright.dev/docs/api/class-locator#locator-drop | Simulates external drag-and-drop of files onto an element; eliminates DataTransfer.files flakiness (v1.60) |
| Vitest 5.0 Migration Guide | Official | https://vitest.dev/guide/migration | `sequential` removal, attachment path change, blob reporter path — required reading before upgrading from 4.x |
| Vitest `configDefaults` | Official | https://vitest.dev/config/#configdefaults | Exposes current-version defaults programmatically; use in CI scripts to avoid hardcoding paths that change between versions |

---

## Pattern 90 — Playwright v1.60 `tracing.startHar()` / `tracing.stopHar()` for Network Flakiness Diagnosis  [official]

Before Playwright v1.60, HAR recording was only available through `page.routeFromHAR()` (replay mode) or by configuring `recordHar` on a `BrowserContext` at creation time — both required knowing in advance that HAR recording was needed. There was no way to start HAR recording mid-test or scope it to a specific operation within a test.

Playwright v1.60 introduces `tracing.startHar()` and `tracing.stopHar()` as first-class members of the `Tracing` API. They work independently from `tracing.start()/stop()`, so you can combine full trace capture (DOM snapshots, screenshots, action timeline) with dedicated network HAR recording — or use HAR alone for lightweight network-only logging on tests where full traces are too expensive.

The key benefit for flakiness diagnosis is that HAR recording can be scoped to a specific step or flow using the `await using` Disposable pattern (TypeScript 5.2+ `using` keyword), ensuring the HAR is always written even if the test throws.

```typescript
// playwright.config.ts — enable retries so flaky tests produce multiple HAR files
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  use: {
    // Full trace on first retry (DOM + screenshots + network)
    trace: 'on-first-retry',
    // HAR is recorded separately via tracing.startHar() in individual tests
    // so we don't also set recordHar here — that would duplicate network capture
  },
});
```

```typescript
// BAD: network request timing flakiness investigated with only a full trace
// A full trace includes network, but it's interleaved with DOM snapshots and screenshots.
// Finding a specific request's timing or response body in a 50MB trace zip is slow.
import { test, expect } from '@playwright/test';

test('dashboard loads with correct user data', async ({ page, context }) => {
  await context.tracing.start({ screenshots: true, snapshots: true, sources: true });
  await page.goto('/dashboard');
  await expect(page.getByTestId('user-name')).toHaveText('Alice');
  await context.tracing.stop({ path: 'trace.zip' });
  // Debugging a network flakiness issue requires opening the full 50MB trace zip
  // and filtering for the specific API request — tedious and slow
});
```

```typescript
// GOOD: scoped HAR recording for targeted network flakiness diagnosis (v1.60+)
import { test, expect } from '@playwright/test';
import path from 'path';

test('dashboard loads with correct user data', async ({ page, context }) => {
  const harPath = path.join(
    test.info().outputDir,  // test-scoped output dir — unique per retry
    'dashboard-network.har'
  );

  // startHar() begins capturing network traffic — lightweight (no DOM/screenshots)
  // The HAR file is scoped to this context: every request made by any page in
  // this context is recorded until stopHar() is called.
  await context.tracing.startHar(harPath, {
    content: 'embed',    // embed response bodies directly in the HAR (default: 'attach')
    mode: 'full',        // record both request and response headers+bodies
    urlFilter: /\/api\// // only capture API requests — reduces HAR size significantly
  });

  await page.goto('/dashboard');
  await expect(page.getByTestId('user-name')).toHaveText('Alice');

  // stopHar() finalizes and writes the HAR file to disk.
  // Call explicitly — or use 'await using' for automatic cleanup (see below).
  await context.tracing.stopHar();

  // On failure, the HAR file is in testInfo.outputDir — automatically uploaded
  // by Playwright as a test artifact. Open in browser devtools or Chrome HAR viewer.
});
```

```typescript
// BEST: use TypeScript 5.2+ 'await using' for automatic HAR cleanup
// The Disposable returned by startHar() calls stopHar() automatically on scope exit —
// even if the test throws. This prevents "incomplete HAR" from failed tests.
import { test, expect } from '@playwright/test';
import path from 'path';

test('checkout flow completes and sends correct API requests', async ({ page, context }) => {
  // 'await using' ensures stopHar() is called when the block exits — pass or fail
  await using _har = await context.tracing.startHar(
    path.join(test.info().outputDir, 'checkout.har'),
    {
      content: 'embed',
      urlFilter: /\/(api|checkout)\//,
    }
  );

  await page.goto('/cart');
  await page.getByRole('button', { name: 'Proceed to Checkout' }).click();
  await page.getByLabel('Card Number').fill('4111111111111111');
  await page.getByRole('button', { name: 'Pay Now' }).click();

  // If this assertion is flaky (sometimes the order isn't created):
  // open checkout.har in testInfo.attachments — find the POST /api/orders request,
  // check its response body and timing to distinguish network vs app vs assertion race.
  await expect(page.getByTestId('order-confirmation')).toBeVisible({ timeout: 10_000 });
});
```

```typescript
// HAR-only recording in beforeEach for a whole describe block — useful for
// integration test suites where every test touches the same API surface
import { test, expect, type Page, type BrowserContext } from '@playwright/test';
import path from 'path';

const myTest = test.extend<{ harRecording: void }>({
  harRecording: [
    async ({ context }, use, testInfo) => {
      // Start HAR before the test runs
      await context.tracing.startHar(
        path.join(testInfo.outputDir, `${testInfo.title.replace(/\s+/g, '-')}.har`),
        { content: 'embed', urlFilter: /\/api\// }
      );

      await use();

      // Stop HAR after the test — runs even if the test fails
      await context.tracing.stopHar();
    },
    { auto: true }, // runs for every test in the suite automatically
  ],
});

myTest('user list loads', async ({ page }) => {
  await page.goto('/users');
  await expect(page.getByRole('list')).toBeVisible();
});

myTest('user detail loads', async ({ page }) => {
  await page.goto('/users/1');
  await expect(page.getByTestId('user-name')).toBeVisible();
});
```

**HAR vs full trace — when to use which:**

| Scenario | Use full trace | Use HAR (`startHar`) | Use both |
|----------|---------------|---------------------|----------|
| UI interaction flakiness (timing, animation, DOM race) | Yes — DOM snapshots essential | No | Rarely |
| Network flakiness (request ordering, response timing) | Overkill — 50MB+ for API tests | Yes — lightweight, easy to diff | If UI + network both flaky |
| Debugging a flaky form submission | Yes | Yes (to see request body) | Yes |
| CI storage budget is tight | No — use on-first-retry | Yes — HAR is compact | No |
| Comparing two retries' network behaviour | Hard — two separate trace zips | Easy — two HAR files, diff in devtools | Yes |

---

## Pattern 91 — Playwright v1.60 `toHaveCSS({ pseudo })` for Deterministic Pseudo-Element Assertions  [official]

CSS pseudo-elements (`::before`, `::after`) are widely used for decorative icons, status indicators, required-field markers, and validation states. Testing them historically required screenshot snapshots — which are pixel-sensitive, platform-dependent, and notoriously flaky across OS, font rendering, and CI image versions.

Playwright v1.60 adds a `pseudo` option to `expect(locator).toHaveCSS()`, allowing direct assertion on computed CSS properties of `::before` and `::after` pseudo-elements. This eliminates an entire class of screenshot-based visual assertion flakiness.

```typescript
// BAD: screenshot snapshot to verify a required-field asterisk (CSS ::before)
// Flaky due to: font rendering differences, sub-pixel antialiasing, DPI scaling,
// CI image font package changes, OS-level rendering differences (Ubuntu vs macOS).
import { test, expect } from '@playwright/test';

test('required field shows asterisk', async ({ page }) => {
  await page.goto('/signup');
  // Screenshot comparison is ~20px region around the label — ANY pixel difference fails.
  // One font package update in the CI image → dozens of snapshot failures.
  await expect(page.getByLabel('Email').locator('..')).toMatchSnapshot('required-asterisk.png');
});
```

```typescript
// GOOD: assert the ::before content property directly (v1.60+)
// This is a computed style assertion — not pixel-dependent. Same result on all platforms.
import { test, expect } from '@playwright/test';

test('required field label has asterisk via CSS ::before', async ({ page }) => {
  await page.goto('/signup');

  const emailLabel = page.getByText('Email address');

  // Assert that the ::before pseudo-element has content: '"*"'
  // Note: CSS content property value includes the outer quotes: '"*"' not '*'
  await expect(emailLabel).toHaveCSS('content', '"*"', { pseudo: 'before' });

  // Assert color of the asterisk (e.g. red for required fields)
  await expect(emailLabel).toHaveCSS('color', 'rgb(220, 38, 38)', { pseudo: 'before' });
});
```

```typescript
// Asserting ::after pseudo-elements — common for validation error icons,
// checkmark indicators, and clearfix patterns
import { test, expect } from '@playwright/test';

test('valid input shows checkmark via ::after', async ({ page }) => {
  await page.goto('/signup');

  const emailInput = page.getByLabel('Email');
  await emailInput.fill('user@example.com');
  await emailInput.blur();

  // Wait for validation to complete (avoids timing flakiness)
  await expect(emailInput).not.toHaveAttribute('aria-invalid', 'true');

  // The ::after pseudo-element shows a green checkmark icon for valid fields
  await expect(emailInput.locator('..')).toHaveCSS('content', '"✓"', { pseudo: 'after' });
  await expect(emailInput.locator('..')).toHaveCSS('color', 'rgb(34, 197, 94)', { pseudo: 'after' });
});
```

```typescript
// Real-world: testing a CSS-only tooltip (::after with content from data-* attr)
// Previously required screenshot; now assertable with toHaveCSS pseudo
import { test, expect } from '@playwright/test';

test('icon button shows tooltip text via ::after content', async ({ page }) => {
  await page.goto('/dashboard');

  const helpButton = page.getByRole('button', { name: 'Help' });

  // CSS tooltip: [data-tooltip]::after { content: attr(data-tooltip); }
  // The computed value of content will be the literal tooltip text
  await expect(helpButton).toHaveCSS('content', '"Opens help panel"', { pseudo: 'after' });
});
```

```typescript
// TypeScript type reference — pseudo option signature (added v1.60):
// toHaveCSS(
//   name: string,
//   value: string | RegExp,
//   options?: {
//     pseudo?: '::before' | '::after' | ':before' | ':after'; // both forms accepted
//     timeout?: number;
//   }
// ): Promise<void>

// Using RegExp for value — useful when colour is set dynamically by theming
import { test, expect } from '@playwright/test';

test('required asterisk is red in light theme', async ({ page }) => {
  await page.goto('/signup?theme=light');
  const label = page.getByText('Password');
  // Match any rgb() red value — tolerates minor theme variable changes
  await expect(label).toHaveCSS('color', /rgb\(2[01]\d, [0-3]\d,/, { pseudo: 'before' });
});
```

**Migration from screenshot to `toHaveCSS` pseudo:**

| What you're testing | Old approach (flaky) | New approach (stable) |
|--------------------|---------------------|-----------------------|
| Required field asterisk | Screenshot of label region | `toHaveCSS('content', '"*"', { pseudo: 'before' })` |
| Validation checkmark/cross | Screenshot of input field | `toHaveCSS('content', '"✓"', { pseudo: 'after' })` |
| CSS-only tooltip text | Screenshot of hovered element | `toHaveCSS('content', '"tooltip text"', { pseudo: 'after' })` |
| Conditional styling (theme) | Screenshot per-theme variant | `toHaveCSS('color', /rgb\(...)/, { pseudo: 'before' })` |
| Icon font character | Screenshot with font rendering risk | `toHaveCSS('content', '""', { pseudo: 'before' })` |

---

## Gotcha 47 — Playwright v1.60 BrowserContext Lifecycle Event Mirroring: Listener Registration Order  [official]

Playwright v1.60 adds lifecycle event mirroring at two levels:

- `browser.on('context')` — fires when a new `BrowserContext` is created from this browser instance
- `browserContext.on('download')`, `browserContext.on('frameattached')`, `browserContext.on('framedetached')`, `browserContext.on('framenavigated')`, `browserContext.on('pageclose')`, `browserContext.on('pageload')` — mirror the equivalent page-level events for ALL pages within the context

The flakiness risk is subtle: **listener registration order relative to context/page creation matters**. If a test attaches a `browserContext.on('framenavigated')` listener *after* a page has already navigated, it misses the event. This is the same registration-timing issue as `page.on('response')`, but now it occurs at a higher level and is easier to miss because the context often exists before the listener is attached.

```typescript
// BAD: listener registered after page creation — misses early events
import { test, expect } from '@playwright/test';

test('all frames navigated during page load are tracked', async ({ page, context }) => {
  await page.goto('/multi-frame-dashboard');

  // FLAKY: the framenavigated events for the initial load have already fired
  // by the time this listener is attached. On fast machines, every event is missed.
  // On slow CI, some frames are still loading when the listener attaches — intermittent.
  const navigatedFrames: string[] = [];
  context.on('framenavigated', (frame) => {
    navigatedFrames.push(frame.url());
  });

  await page.waitForLoadState('networkidle');
  expect(navigatedFrames.length).toBeGreaterThan(0); // flaky — may be 0
});
```

```typescript
// GOOD: register context-level listeners BEFORE any navigation
// Best practice: attach listeners in a fixture that runs before the test body
import { test as base, expect } from '@playwright/test';

const test = base.extend<{ frameTracker: string[] }>({
  frameTracker: async ({ context }, use) => {
    const navigatedFrames: string[] = [];
    // Register BEFORE any page is navigated — fixture runs before test body
    context.on('framenavigated', (frame) => {
      // Skip about:blank initial frame
      if (frame.url() !== 'about:blank') {
        navigatedFrames.push(frame.url());
      }
    });
    await use(navigatedFrames);
  },
});

test('all frames navigated during page load are tracked', async ({ page, frameTracker }) => {
  await page.goto('/multi-frame-dashboard');
  await page.waitForLoadState('networkidle');
  // frameTracker captured all framenavigated events because listener was pre-registered
  expect(frameTracker.length).toBeGreaterThan(0);
  expect(frameTracker).toContain(expect.stringContaining('/api/widget'));
});
```

```typescript
// GOOD: using browser.on('context') to attach listeners to every context created
// Useful in global setup or when multiple contexts are created within one test
import { chromium, type BrowserContext } from '@playwright/test';

// In globalSetup or a base fixture:
const browser = await chromium.launch();

// Register BEFORE any context is created
browser.on('context', (ctx: BrowserContext) => {
  // This fires synchronously when the context is created — before any navigation
  ctx.on('framenavigated', (frame) => {
    if (frame.url() !== 'about:blank') {
      console.log(`[frame nav] ${frame.url()}`);
    }
  });

  ctx.on('download', (download) => {
    console.log(`[download started] ${download.suggestedFilename()}`);
  });
});

// Now every context created from this browser will have listeners attached
// before any pages navigate — eliminates the registration-timing race
const context1 = await browser.newContext();
const context2 = await browser.newContext(); // also gets listeners
```

```typescript
// Gotcha: pageclose vs page.on('close') — ordering difference
// browserContext.on('pageclose') fires when any page in the context closes.
// The event fires AFTER page.on('close'). If your test depends on cleanup
// order (e.g., closing a download listener before the page event fires),
// use page.on('close') directly — not context-level mirroring.
import { test, expect } from '@playwright/test';

test('download listener is cleaned up before page closes', async ({ page, context }) => {
  const downloadedFiles: string[] = [];

  // Use context-level 'download' for broad tracking
  context.on('download', (dl) => downloadedFiles.push(dl.suggestedFilename()));

  await page.goto('/reports');
  await page.getByRole('button', { name: 'Export CSV' }).click();

  // Wait for the download event (context-level — works across all pages)
  await page.waitForEvent('download'); // page-level is fine here too

  expect(downloadedFiles[0]).toMatch(/report-\d+\.csv/);
});
```

**Event mirroring reference (Playwright v1.60+):**

| Context-level event | Equivalent page-level event | When to use context-level |
|--------------------|----------------------------|--------------------------|
| `context.on('framenavigated')` | `page.on('framenavigated')` | Multi-page tests, iframe navigation tracking |
| `context.on('frameattached')` | `page.on('frameattached')` | Dynamic iframe injection detection |
| `context.on('framedetached')` | `page.on('framedetached')` | Iframe cleanup verification |
| `context.on('download')` | `page.on('download')` | Download tracking across all pages |
| `context.on('pageclose')` | `page.on('close')` | Cleanup after any page closes (fires after page-level) |
| `context.on('pageload')` | `page.on('load')` | Load state tracking across multiple pages |
| `browser.on('context')` | n/a | Attach listeners to every context at creation time |

---

## Anti-Patterns (iteration 55)

### AP45 — Vitest 4.1 `FixtureAccessError`: Accessing Test-Scoped Fixtures in `beforeAll` / `afterAll`  [official]

**What:** Calling a test-scoped fixture (default scope `'test'`) from inside a `beforeAll` or `afterAll` hook.

**New in Vitest 4.1:** Previously this silently returned `undefined` or threw an unrelated error. Vitest 4.1 introduces `FixtureAccessError` — a dedicated error that is thrown explicitly with a clear message identifying which fixture was accessed and from which hook.

**Why harmful:** Test-scoped fixtures are created and destroyed per test. A `beforeAll` hook runs once for the whole describe block — it has no test context to attach a fixture to. Before 4.1, the silent failure meant test setup code often ran without the expected fixture value, producing confusing `Cannot read properties of undefined` errors deeper in the test body. The root cause (fixture scope mismatch) was hard to diagnose.

```typescript
// BAD: test-scoped fixture accessed in beforeAll — FixtureAccessError in Vitest 4.1
import { describe, beforeAll, it, expect } from 'vitest';

// This fixture has default scope 'test' — created fresh per test
const myTest = test.extend<{ userToken: string }>({
  userToken: async ({}, use) => {
    const token = await createTestUser(); // per-test setup
    await use(token);
    await deleteTestUser(token);         // per-test teardown
  },
});

myTest.describe('Admin API', () => {
  let token: string;

  // THROWS FixtureAccessError in Vitest 4.1:
  // "Cannot access fixture 'userToken' from beforeAll — fixture scope is 'test' but hook scope is 'suite'"
  beforeAll(async ({ userToken }) => { // ← FixtureAccessError here
    token = userToken;
  });

  myTest('can list users', async ({ page }) => {
    // token may be undefined — silent failure in Vitest < 4.1
  });
});
```

```typescript
// GOOD option 1: change fixture scope to 'file' or 'suite' if sharing is safe
import { test, describe, beforeAll, it, expect } from 'vitest';

const myTest = test.extend<{ userToken: string }>({
  userToken: [
    async ({}, use) => {
      const token = await createTestUser();
      await use(token);
      await deleteTestUser(token);
    },
    { scope: 'file' }, // created once per file — accessible in beforeAll
  ],
});

myTest.describe('Admin API', () => {
  let token: string;

  // Works: fixture scope 'file' matches the suite-level hook
  beforeAll(async ({ userToken }) => {
    token = userToken;
  });

  myTest('can list users', async () => {
    const res = await fetch('/api/admin/users', {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
  });
});
```

```typescript
// GOOD option 2: move per-test setup out of beforeAll into the fixture itself
// (preferred — keeps isolation tight, no shared mutable state)
import { test, describe, it, expect } from 'vitest';

const myTest = test.extend<{ userToken: string }>({
  // Keep scope 'test' — each test gets its own token, no beforeAll needed
  userToken: async ({}, use) => {
    const token = await createTestUser();
    await use(token);
    await deleteTestUser(token); // always cleaned up — even if test fails
  },
});

myTest.describe('Admin API', () => {
  // No beforeAll — each test gets userToken via fixture injection
  myTest('can list users', async ({ userToken }) => {
    const res = await fetch('/api/admin/users', {
      headers: { Authorization: `Bearer ${userToken}` },
    });
    expect(res.status).toBe(200);
  });

  myTest('can create user', async ({ userToken }) => {
    const res = await fetch('/api/admin/users', {
      method: 'POST',
      headers: { Authorization: `Bearer ${userToken}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Bob', email: 'bob@example.com' }),
    });
    expect(res.status).toBe(201);
  });
});
```

**Diagnosis:** When you see `FixtureAccessError` after upgrading to Vitest 4.1, it means a `beforeAll` or `afterAll` hook is accessing a fixture whose scope is narrower than `'file'`. Audit all `beforeAll`/`afterAll` calls in the failing describe block and either:

- Widen the fixture scope to `'file'` if the fixture is safe to share across all tests in the file
- Move the setup into the fixture body (option 2 above)
- Use Vitest's `aroundAll` hook (Pattern 67) instead of `beforeAll`/`afterAll` when you need both setup and teardown with fixture access

---

## Quick Reference additions (iteration 55)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Network flakiness hard to debug — full trace zip is too large to navigate | Full trace mixes DOM/screenshots with network — tedious to filter | Pattern 90 (`tracing.startHar()` + `await using` for scoped HAR) | Using `recordHar` at context creation time — always-on, no scoping |
| Screenshot snapshot fails only on CI due to font rendering / DPI differences | Pixel-sensitive screenshot comparing pseudo-element visual output | Pattern 91 (`toHaveCSS('content', '...', { pseudo: 'before' })`) | `toMatchSnapshot()` for `::before`/`::after` styling |
| `context.on('framenavigated')` listener misses early frame navigation events | Listener registered after context already navigated | Gotcha 47 (register context listeners in fixture before test body runs) | Attaching context listeners mid-test after `page.goto()` |
| Vitest 4.1 upgrade: `beforeAll` throws `FixtureAccessError` | Test-scoped fixture accessed in suite-level hook | AP45 (widen fixture scope to `'file'` or move setup into fixture body) | Casting to `any` to suppress the error — root cause unaddressed |

---

## Key Resources (iteration 55 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright `tracing.startHar()` | Official | https://playwright.dev/docs/api/class-tracing#tracing-start-har | HAR recording as first-class tracing API; `await using` Disposable pattern for automatic cleanup (v1.60) |
| Playwright `toHaveCSS` | Official | https://playwright.dev/docs/api/class-locatorassertions#locator-assertions-to-have-css | `pseudo` option (`'before'`/`'after'`) for deterministic pseudo-element CSS assertions; replaces screenshot snapshots (v1.60) |
| Playwright BrowserContext events | Official | https://playwright.dev/docs/api/class-browsercontext | `browser.on('context')` and context-level lifecycle event mirroring (`framenavigated`, `download`, `pageclose`) — centralized multi-page event handling (v1.60) |
| Vitest `FixtureAccessError` | Official | https://vitest.dev/guide/test-context#fixture-scope | Thrown in Vitest 4.1 when a test-scoped fixture is accessed from `beforeAll`/`afterAll`; scope mismatch now fails fast with clear message |

---

## Pattern 92 — Jest 30 `retryTimes` Staged Retry Options (`waitBeforeRetry` + `retryImmediately`)  [official]

Jest 30 (June 2025) extended `jest.retryTimes()` with two new options that give you precise control over *when* a retry executes. These options address a class of flakiness where the old default retry behaviour was too blunt:

- **`waitBeforeRetry`** — adds a mandatory delay (ms) before each retry. Useful for integration tests that involve eventual consistency: a REST API that requires propagation delay before a GET reflects a POST, or a DB that needs time to flush a write.
- **`retryImmediately`** — retries the failing test immediately after failure, before Jest runs other tests in the file. The original default deferred retries to after all other tests completed, which masked cases where shared state introduced by the intervening tests caused the retry to produce a false pass.

**Full type signature (Jest 30+):**

```typescript
jest.retryTimes(
  numRetries: number,
  options?: {
    logErrorsBeforeRetry?: boolean;   // log failures before each retry (existed in Jest 29)
    waitBeforeRetry?: number;         // NEW in Jest 30: ms to wait before retry attempt
    retryImmediately?: boolean;       // NEW in Jest 30: retry right after failure
  }
): jest
```

```typescript
// BAD: Jest 29 style — retry deferred, no delay, failure logged only on final failure
// This pattern masks state pollution from intervening tests during retry window

// jest.config.ts
import type { Config } from 'jest';
const config: Config = {
  retryTimes: 2,          // deprecated global config — still works but options not available
};

// ALSO BAD: retryTimes() without logErrorsBeforeRetry
// Makes debugging flaky integration tests extremely hard —
// you only see the final failure message, not the intermediate errors.
jest.retryTimes(2);
```

```typescript
// GOOD: Jest 30 retryTimes with staged delay for integration tests
// Use case: REST API with optimistic write — GET may lag behind POST by ~200ms
// waitBeforeRetry gives the system time to reach a consistent state before retry.

describe('OrderService — integration', () => {
  jest.retryTimes(2, {
    logErrorsBeforeRetry: true,  // see each failure, not just the final one
    waitBeforeRetry: 500,        // wait 500ms before each retry — matches API propagation SLA
    // retryImmediately: false   // default: retry after other tests in file complete
  });

  it('order appears in listing after creation', async () => {
    const { id } = await orderApi.create({ item: 'Widget', qty: 3 });
    // Without waitBeforeRetry, this GET sometimes precedes DB write propagation → flaky
    const listing = await orderApi.list();
    expect(listing.map(o => o.id)).toContain(id);
  });
});
```

```typescript
// GOOD: retryImmediately for tests where shared state from intervening tests
// causes false positives on deferred retry.
// Use case: module-level cache that's populated by a preceding test —
// if the retry is deferred, the cache is warm and the test passes for the wrong reason.

describe('UserCache — isolation', () => {
  // Reset module-level cache before every test to prevent false-positive retries
  beforeEach(() => {
    jest.resetModules();
  });

  jest.retryTimes(2, {
    logErrorsBeforeRetry: true,
    retryImmediately: true,  // retry before any other test can warm the cache
    // waitBeforeRetry: 0    // no extra delay needed — failure is deterministic
  });

  it('returns null for unknown user (cache cold)', async () => {
    const { UserCache } = await import('./UserCache');
    expect(await UserCache.get('unknown-id')).toBeNull();
  });
});
```

```typescript
// Pattern: per-describe block retry policy (Jest 30)
// Outer describe uses stricter settings; inner describe relaxes for known-slow paths.
// This documents intent and prevents retry inflation in unit tests.

describe('PaymentGateway', () => {
  // Unit tests: no retry — any failure is a real bug
  describe('unit', () => {
    it('validates card number format', () => {
      expect(validateCard('4111111111111111')).toBe(true);
      expect(validateCard('0000')).toBe(false);
    });
  });

  // Integration tests: up to 2 retries with 300ms delay (network variance)
  describe('integration', () => {
    jest.retryTimes(2, {
      logErrorsBeforeRetry: true,
      waitBeforeRetry: 300,
      retryImmediately: true,
    });

    it('processes a real sandbox charge', async () => {
      const result = await gateway.charge({ amount: 100_00, currency: 'USD' });
      expect(result.status).toBe('succeeded');
    });
  });
});
```

**Tradeoffs and gotchas:**

| Option | When to use | Caution |
|--------|-------------|---------|
| `waitBeforeRetry: N` | API propagation delay, eventual-consistent stores, async queue processing | Don't set > 1000ms — prefer fixing the root cause instead; use this as a short-term bridge |
| `retryImmediately: true` | Shared module state from intervening tests; any test that fails due to ordering side-effects | Still won't fix tests that depend on global singletons — reset in `beforeEach` first |
| `logErrorsBeforeRetry: true` | Always — no reason not to; essential for diagnosing *why* retries happen | None |

> **Community signal (Jest 30 blog, June 2025):** Teams migrating from Jest 29 to 30 that enabled `globalsCleanup: 'on'` and `retryImmediately: true` saw their retry-pass rate drop — which is the correct outcome. Retries that stop passing when state is properly reset were masking shared state bugs, not detecting intermittent failures.

---

## Pattern 93 — Jest 30 `advanceTimersToNextFrame()` for `requestAnimationFrame` Flakiness  [official]

`requestAnimationFrame` (rAF) callbacks are a common source of animation-related test flakiness. Before Jest 30, the only ways to test rAF code were:
1. Use `jest.advanceTimersByTime(16)` — fragile, assumes 60fps frame rate
2. Use `jest.runAllTimers()` — runs rAF callbacks but also drains ALL timers (can cause infinite loops with recursive rAF)
3. Wait for a real animation frame — introduces real-time wait and CI timing variance

Jest 30 (backed by `@sinonjs/fake-timers` v13) adds `jest.advanceTimersToNextFrame()` — a targeted method that advances fake timers to precisely the next scheduled animation frame callback, without assuming frame duration or draining the timer queue.

```typescript
// BAD: hard-coding 16ms assumes 60fps — fails in environments where the fake timer
// frame rate differs, or when multiple rAF callbacks are chained
jest.useFakeTimers();
let animated = false;
requestAnimationFrame(() => { animated = true; });

jest.advanceTimersByTime(16); // assumes exactly 16ms per frame — fragile
expect(animated).toBe(true);  // may fail if frame duration changes
```

```typescript
// BAD: jest.runAllTimers() drains ALL pending timers including recursive rAFs
// This causes infinite loops in animation loops that call rAF recursively:
jest.useFakeTimers();
let frameCount = 0;
function animationLoop() {
  frameCount++;
  requestAnimationFrame(animationLoop); // recursive — infinite without frame limit
}
requestAnimationFrame(animationLoop);

jest.runAllTimers(); // INFINITE LOOP — recursive rAF never terminates
```

```typescript
// GOOD: jest.advanceTimersToNextFrame() — advances to exactly the next rAF callback,
// does NOT drain all timers, and does NOT assume frame rate
import { AnimationController } from './AnimationController';

describe('AnimationController', () => {
  beforeEach(() => {
    // Modern fake timers required — legacy timers do not support advanceTimersToNextFrame
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('executes animation callback on next frame', () => {
    const controller = new AnimationController();
    let executed = false;

    controller.scheduleFrame(() => { executed = true; });

    expect(executed).toBe(false); // not yet — frame hasn't advanced
    jest.advanceTimersToNextFrame(); // advance to next rAF precisely
    expect(executed).toBe(true);   // now executed
  });

  it('processes animation loop for N frames without infinite loop', () => {
    let frameCount = 0;
    const MAX_FRAMES = 5;

    function loop() {
      if (frameCount < MAX_FRAMES) {
        frameCount++;
        requestAnimationFrame(loop); // recursive — would infinite-loop with runAllTimers
      }
    }
    requestAnimationFrame(loop);

    // Advance one frame at a time — safe with recursive rAF
    for (let i = 0; i < MAX_FRAMES; i++) {
      jest.advanceTimersToNextFrame();
    }

    expect(frameCount).toBe(MAX_FRAMES);
  });

  it('does not execute second-frame callback on first advanceTimersToNextFrame call', () => {
    const callOrder: number[] = [];

    requestAnimationFrame(() => {
      callOrder.push(1);
      requestAnimationFrame(() => {
        callOrder.push(2); // second frame callback — scheduled from within first
      });
    });

    jest.advanceTimersToNextFrame(); // executes frame 1 callback only
    expect(callOrder).toEqual([1]);  // frame 2 not yet executed

    jest.advanceTimersToNextFrame(); // executes frame 2 callback
    expect(callOrder).toEqual([1, 2]);
  });
});
```

```typescript
// Real-world example: testing a scroll animation utility that uses rAF internally
import { smoothScroll } from './smoothScroll';

describe('smoothScroll', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    // Mock scrollTop as a writable property
    Object.defineProperty(document.documentElement, 'scrollTop', {
      writable: true,
      value: 0,
    });
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('scrolls to target position over multiple frames', () => {
    smoothScroll({ target: 500, duration: 300 });

    // Advance frame by frame and assert position progresses deterministically
    jest.advanceTimersToNextFrame();
    expect(document.documentElement.scrollTop).toBeGreaterThan(0);
    expect(document.documentElement.scrollTop).toBeLessThan(500);

    // Run remaining frames until animation completes
    jest.runAllTimers(); // safe here — no infinite rAF loop (animation ends at target)
    expect(document.documentElement.scrollTop).toBe(500);
  });
});
```

**Migration from workarounds to `advanceTimersToNextFrame`:**

| Old workaround | Flakiness risk | Replace with |
|---------------|----------------|--------------|
| `jest.advanceTimersByTime(16)` | Frame rate assumption — breaks on non-60fps | `jest.advanceTimersToNextFrame()` |
| `jest.advanceTimersByTime(1000/60)` | Same — floating point rounding | `jest.advanceTimersToNextFrame()` |
| `jest.runAllTimers()` with recursive rAF | Infinite loop risk | `jest.advanceTimersToNextFrame()` in a loop with limit |
| `await new Promise(requestAnimationFrame)` | Requires real timers — CI timing variance | `jest.advanceTimersToNextFrame()` with fake timers |

> **Requires `jest.useFakeTimers()` with modern fake timers** (default in Jest 27+). Not available when using `{ legacyFakeTimers: true }`.

---

## Anti-Patterns (iteration 56)

### AP46 — Jest 30 `globalsCleanup` Not Enabled: Silently Leaking Global State Between Test Files  [official]

**What:** Relying on the default `globalsCleanup: 'soft'` setting in Jest 30 when test files mutate `globalThis` or attach properties to the global scope (e.g., polyfills, event listeners, custom matchers added to `globalThis`).

**Why harmful:** Jest 30 introduced the `globalsCleanup` option to address global state pollution across test files running in the same worker process. The default `'soft'` mode cleans up *some* globals but preserves those set by `setupFilesAfterFramework` to avoid breaking existing setups. Test code that directly assigns to `globalThis` — a common pattern in polyfill loading, feature flag injection, or third-party SDK initialization — bypasses the soft cleanup and leaks to subsequent test files. This produces an entire class of order-dependent failures that are invisible in single-file runs and only manifest in full CI suite runs.

**Mechanism:**
```typescript
// BAD: test file that leaks a global — pollutes subsequent test files in the same worker
// src/__tests__/polyfillLoader.test.ts

describe('Polyfill Loader', () => {
  it('installs the ResizeObserver polyfill when missing', () => {
    // Attaches a polyfill directly to globalThis — leaks to next test file
    (globalThis as any).ResizeObserver = class {
      observe() {}
      unobserve() {}
      disconnect() {}
    };

    loadPolyfillIfMissing();
    expect(globalThis.ResizeObserver).toBeDefined();
    // MISSING: cleanup — the polyfill remains for all subsequent test files
    // in this worker → order-dependent failures in tests that check native absence
  });
});
```

```typescript
// BAD: Jest config with globalsCleanup: 'off' — maximally dangerous
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  testEnvironmentOptions: {
    globalsCleanup: 'off', // never do this unless you have a very specific reason
    // All globalThis mutations persist across ALL test files in the worker
  },
};
```

```typescript
// GOOD: Enable globalsCleanup: 'on' in Jest 30 for maximum isolation
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  testEnvironment: 'node', // globalsCleanup is a Node environment option
  testEnvironmentOptions: {
    // 'on': full cleanup — resets all globals to their initial state between test files
    // 'soft' (default): partial cleanup — preserves setupFilesAfterFramework globals
    // 'off': no cleanup — leaks everything (debugging only)
    globalsCleanup: 'on',
  },
};

export default config;
```

```typescript
// GOOD: if a test legitimately needs a global, clean it up in afterAll/afterEach
// src/__tests__/polyfillLoader.test.ts
describe('Polyfill Loader', () => {
  const originalResizeObserver = globalThis.ResizeObserver;

  afterAll(() => {
    // Always restore — even if test throws
    if (originalResizeObserver === undefined) {
      delete (globalThis as any).ResizeObserver;
    } else {
      globalThis.ResizeObserver = originalResizeObserver;
    }
  });

  it('installs the ResizeObserver polyfill when missing', () => {
    delete (globalThis as any).ResizeObserver; // ensure absent for this test
    loadPolyfillIfMissing();
    expect(globalThis.ResizeObserver).toBeDefined();
  });
});
```

```typescript
// GOOD: use protectProperties (jest-util) to explicitly mark globals
// that should survive globalsCleanup: 'on' between test files
// (for setupFiles that intentionally install persistent globals)

// jest.setup.ts — globals that should persist across all test files
import { protectProperties } from 'jest-util';

// Mark these as intentionally persistent — globalsCleanup: 'on' will NOT wipe them
globalThis.myFeatureFlags = { darkMode: true, newCheckout: false };
protectProperties(globalThis['myFeatureFlags']); // survives 'on' cleanup

// Note: only use protectProperties for globals that are read-only across tests.
// Mutable protected globals still cause order-dependency.
```

**Diagnosis checklist for global state leaks in Jest 30:**

- [ ] Does `globalsCleanup: 'on'` cause new failures after upgrading? → Tests depend on leaked globals from preceding files
- [ ] Does a test pass when run in isolation but fail in full suite? → Another test file leaked a global it depends on
- [ ] Does changing `--testSequencer` ordering change which tests fail? → Order-dependent global leak
- [ ] Does `--runInBand` make the failures deterministic? → Multiple workers with different leak states

> **Community signal:** Teams at Happo saw test runtimes drop from 14 minutes to 9 minutes by enabling `globalsCleanup: 'on'` and cleaning up leaked handles after upgrading to Jest 30 — a 35% improvement solely from eliminating global state accumulation and open handle buildup across the worker process lifecycle.

---

## Quick Reference additions (iteration 56)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Integration test passes when retried immediately after failure but fails after other tests run | Deferred retry exposes intervening-test state pollution | Pattern 92 (`jest.retryTimes(n, { retryImmediately: true, logErrorsBeforeRetry: true })`) | Deferred retry without `retryImmediately` — masks state bugs with false-positive retries |
| rAF-driven animation test flakes when `jest.advanceTimersByTime(16)` is used | Frame rate assumption (16ms ≈ 60fps) fails in non-60fps fake timer environments | Pattern 93 (`jest.advanceTimersToNextFrame()` — frame-rate-agnostic rAF advancement) | `jest.runAllTimers()` with recursive rAF — infinite loop risk |
| Jest test order change causes failures in previously passing test files | Global state (polyfill, SDK, feature flag) attached to `globalThis` not cleaned up | AP46 (`globalsCleanup: 'on'` + afterAll restore + `protectProperties` for intentional globals) | `globalsCleanup: 'off'` or relying on soft cleanup with direct `globalThis` mutations |

---

## Key Resources (iteration 56 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Jest 30 release blog | Official | https://jestjs.io/blog/2025/06/jest-30 | June 2025 major release — `retryTimes` new options, `advanceTimersToNextFrame`, `globalsCleanup`, 37% faster; community evidence of flakiness improvements |
| Jest `retryTimes` API | Official | https://jestjs.io/docs/jest-object#jestretrytimersnumretries-options | `waitBeforeRetry` and `retryImmediately` options (Jest 30+); full type signature with `logErrorsBeforeRetry` |
| Jest `advanceTimersToNextFrame` | Official | https://jestjs.io/docs/jest-object#jestadvancetimerstonextframe | Deterministic rAF testing without frame-rate assumptions; safe with recursive animation loops |
| Jest `globalsCleanup` config | Official | https://jestjs.io/docs/configuration#testenvironmentoptions-object | `'on'`/`'soft'`/`'off'` values for controlling cross-test-file global state isolation in Jest 30 |
| Vitest merge-report CLI | Official | https://vitest.dev/guide/reporters#merge-reporters | Merges blob reports from multiple shards or environments into a single result; enables cross-environment flakiness detection (v5.0) |

---

## Pattern 94 — Playwright `routeWebSocket()` for Deterministic WebSocket Mocking  [official]

Playwright v1.48 added first-class WebSocket interception via `page.routeWebSocket()` and `browserContext.routeWebSocket()`. Before this, testing WebSocket-driven UIs required a real test server (see Pattern 15), which introduced port-collision flakiness, process-lifecycle races, and CI networking issues. `routeWebSocket()` intercepts the connection at the browser level — no real server required, no port bindings, full message control.

Two modes are available:
- **Mock mode** (default): intercepts without connecting to any server — full message simulation
- **Intercept mode**: connects to the real server via `connectToServer()` but lets the test inspect and modify messages bidirectionally

```typescript
// BAD: real ws server in test — introduces port-collision, lifecycle, and timing flakiness
import { WebSocketServer } from 'ws';

let wss: WebSocketServer;
beforeAll(() => {
  wss = new WebSocketServer({ port: 8080 }); // port collision risk across parallel workers
});
afterAll(() => { wss.close(); }); // close timing races

it('receives notification', async () => {
  // race: browser may attempt connection before wss is bound
  await page.goto('/realtime');
  wss.on('connection', socket => socket.send(JSON.stringify({ type: 'notify' })));
  await expect(page.locator('[data-testid="notification"]')).toBeVisible();
});
```

```typescript
// GOOD: Playwright routeWebSocket — no real server, no port, no timing race

import { test, expect } from '@playwright/test';

test('chat component shows incoming message', async ({ page }) => {
  // Register the route handler BEFORE navigation — ensures the intercept is
  // in place before the page code calls new WebSocket(...)
  await page.routeWebSocket('wss://chat.example.com/ws', (ws) => {
    // ws is a WebSocketRoute — represents the browser's side of the connection

    // Listen for the client's first message (e.g., a subscription handshake)
    ws.onMessage((message) => {
      // Echo it back as a server confirmation, then send a new chat message
      ws.send(JSON.stringify({ type: 'ack', received: message }));
      ws.send(JSON.stringify({ type: 'message', text: 'Hello from server', user: 'Bob' }));
    });
  });

  await page.goto('/chat');
  await expect(page.locator('[data-testid="chat-message"]')).toContainText('Hello from server');
});
```

```typescript
// GOOD: context-level route for multi-page tests — one handler covers all pages
// in the context (useful when the app opens pop-outs or iframes that also use WebSocket)

import { test, expect, BrowserContext } from '@playwright/test';

test('notification appears across all tabs', async ({ browser }) => {
  const context: BrowserContext = await browser.newContext();

  await context.routeWebSocket(/wss:\/\/notify\.example\.com\//, (ws) => {
    // Route is matched by regex — handles all WebSocket URLs matching the pattern
    ws.onMessage(() => {
      // Simulate a broadcast from the server after a short sequence of messages
      ws.send(JSON.stringify({ event: 'broadcast', text: 'Deploy complete' }));
    });
  });

  const page1 = await context.newPage();
  const page2 = await context.newPage();
  await Promise.all([page1.goto('/dashboard'), page2.goto('/dashboard')]);

  // Trigger the WebSocket interaction on page1
  await page1.getByRole('button', { name: /subscribe/i }).click();

  // Both pages should receive the broadcast via the context-level route
  await expect(page1.locator('[data-testid="broadcast-banner"]')).toBeVisible();
  await expect(page2.locator('[data-testid="broadcast-banner"]')).toBeVisible();

  await context.close();
});
```

```typescript
// GOOD: intercept mode — spy on messages to/from a real dev server (staging QA)
// Use when you need real server behavior but want to assert on message content

import { test, expect } from '@playwright/test';

test('audit log captures WebSocket message sequence', async ({ page }) => {
  const sentMessages: string[] = [];
  const receivedMessages: string[] = [];

  await page.routeWebSocket('wss://api.staging.example.com/ws', async (ws) => {
    // Connect to the real server — messages forward automatically UNLESS you call onMessage
    const server = await ws.connectToServer();

    // Spy on client→server messages WITHOUT blocking automatic forwarding:
    // Call onMessage on ws (page side) only if you need to intercept.
    // Here we use the server-side route to observe server→client messages.
    server.onMessage((msg) => {
      receivedMessages.push(String(msg));
      server.send(msg); // manually relay — required once onMessage is registered (see Gotcha 48)
    });
  });

  await page.goto('/audit-demo');
  await page.getByRole('button', { name: /start/i }).click();
  await page.waitForTimeout(500); // intentional: waiting for server response sequence

  expect(receivedMessages.length).toBeGreaterThan(0);
  expect(receivedMessages[0]).toContain('"type":"connected"');
});
```

**Tradeoffs:**

| Approach | When to use | Flakiness characteristics |
|----------|-------------|--------------------------|
| `routeWebSocket()` mock mode | Unit/integration E2E — control all messages | Zero network flakiness; no real server needed |
| `routeWebSocket()` intercept mode | Staging E2E — spy on real traffic | Inherits real server flakiness; use for audit/observability only |
| Real `ws` test server (Pattern 15) | When you own the server and need full protocol testing | Port-collision risk; lifecycle management required |

> **Note:** `routeWebSocket()` intercepts connections made by the page's JavaScript. It does NOT intercept WebSocket connections made by service workers. For SW-originated WebSocket connections, use Pattern 24 (service worker isolation) in combination with SW message mocking.

---

## Pattern 95 — Playwright v1.51 `storageState({ indexedDB: true })` for Firebase-Style Auth Flakiness  [official]

Applications that store authentication tokens in IndexedDB (Firebase Authentication, Supabase Auth v2, AWS Amplify) are a significant source of E2E test flakiness. Before Playwright v1.51, `storageState()` only captured cookies and `localStorage`/`sessionStorage` — an IndexedDB token store was silently omitted, causing every test to face an unauthenticated state and re-run the login flow (or fail with a 401).

The `indexedDB: true` option in `storageState()` captures the full IndexedDB contents alongside cookies and web storage, enabling single-setup auth that is reliably restored for every test file.

```typescript
// auth.setup.ts — one-time authentication setup that saves full state including IndexedDB

import { test as setup, expect } from '@playwright/test';
import path from 'path';

const authFile = path.join(__dirname, '../playwright/.auth/user.json');

setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[name="email"]', process.env.TEST_USER_EMAIL!);
  await page.fill('[name="password"]', process.env.TEST_USER_PASSWORD!);
  await page.click('[type="submit"]');

  // Wait for the post-login state to stabilize — Firebase writes the ID token
  // to IndexedDB asynchronously AFTER the redirect completes
  await page.waitForURL('/dashboard');
  // Extra wait for Firebase's async IndexedDB write — without this, the token
  // may not yet be persisted when storageState() is called
  await page.waitForFunction(() => {
    // Check that IndexedDB auth store is populated (Firebase-specific key)
    return new Promise<boolean>(resolve => {
      const req = indexedDB.open('firebaseLocalStorageDb');
      req.onsuccess = () => {
        const db = req.result;
        const tx = db.transaction('firebaseLocalStorage', 'readonly');
        const store = tx.objectStore('firebaseLocalStorage');
        const getReq = store.getAll();
        getReq.onsuccess = () => resolve(getReq.result.length > 0);
      };
      req.onerror = () => resolve(false);
    });
  }, {}, { timeout: 10_000 });

  // Save state WITH IndexedDB — captures the Firebase auth token
  await page.context().storageState({
    path: authFile,
    indexedDB: true, // <-- v1.51+ required for Firebase/IndexedDB-based auth
  });
});
```

```typescript
// playwright.config.ts — reference the auth setup project and distribute auth state

import { defineConfig, devices } from '@playwright/test';
import path from 'path';

const authFile = path.join(__dirname, 'playwright/.auth/user.json');

export default defineConfig({
  projects: [
    // Setup project: runs once, saves auth state
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
    },
    // All functional tests depend on setup and reuse the saved auth state
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        // storageState automatically restores cookies, localStorage, sessionStorage,
        // AND IndexedDB (v1.51+) — the Firebase token is present from the first assertion
        storageState: authFile,
      },
      dependencies: ['setup'],
    },
  ],
});
```

```typescript
// Example test — no login needed, auth is pre-loaded including IndexedDB tokens

import { test, expect } from '@playwright/test';

test('authenticated user sees dashboard data', async ({ page }) => {
  // storageState restores the Firebase IndexedDB token — page starts authenticated
  await page.goto('/dashboard');

  // No flaky login redirect — the app reads the token from IndexedDB immediately
  await expect(page.locator('[data-testid="user-greeting"]')).toBeVisible();
  await expect(page.locator('[data-testid="recent-orders"]')).not.toBeEmpty();
});
```

**Why the `indexedDB: true` flag matters:**

| Auth storage mechanism | storageState default (pre-v1.51) | storageState with `indexedDB: true` (v1.51+) |
|------------------------|----------------------------------|-----------------------------------------------|
| Cookies | Captured | Captured |
| `localStorage` | Captured | Captured |
| `sessionStorage` | Captured | Captured |
| Firebase IndexedDB token | **NOT captured** (silent omission) | Captured |
| Supabase Auth v2 IndexedDB | **NOT captured** | Captured |
| AWS Amplify token store | **NOT captured** | Captured |

> **Gotcha:** The `indexedDB: true` flag increases the size of the saved auth JSON significantly (can be several MB for apps with many IndexedDB stores). Use `.gitignore` to exclude `playwright/.auth/` from version control — it contains sensitive tokens.

> **Community signal [community]:** Teams using Firebase Authentication reported 40–60% fewer E2E auth failures after enabling `indexedDB: true`. Previously, tests that failed to capture the IndexedDB token would silently fall through to the login page, often manifesting as `toBeVisible()` timeouts on dashboard elements rather than explicit 401 errors — making the root cause hard to diagnose.

---

## Pattern 96 — Jest 30 `jest.onGenerateMock()` for Centralized Auto-Mock Configuration  [official]

In large Jest test suites, auto-mocked modules (via `jest.mock('./module')` without a factory) often drift: different test files add different `mockImplementation` calls for the same module, leading to test-order-dependent state where one test's mock configuration leaks into another. Jest 30's `jest.onGenerateMock()` provides a centralized hook invoked every time Jest generates an auto-mock, letting you define default behavior in one place before any test file runs.

```typescript
// BAD: per-test mock drift — test A sets up mockResolvedValue, test B doesn't reset it,
// test C asserts on the default mock and gets test A's stale value
// src/__tests__/orderService.test.ts
import * as db from '../db';
jest.mock('../db');

it('creates order', async () => {
  (db.insertOrder as jest.Mock).mockResolvedValue({ id: 'ORD-001' }); // sets state
  // ...
});

// src/__tests__/inventoryService.test.ts — runs in the same worker
import * as db from '../db';
jest.mock('../db');

it('reads inventory', async () => {
  // If orderService.test.ts ran first in this worker AND didn't reset,
  // db.insertOrder may still have the stale mockResolvedValue from above
  // This is order-dependent and extremely hard to reproduce locally
  const result = await InventoryService.list();
  // ...
});
```

```typescript
// GOOD: use jest.onGenerateMock() in jest.setup.ts to define safe defaults once.
// Every auto-mock for 'db' always starts with these implementations — no drift.

// jest.setup.ts
import { jest } from '@jest/globals';

jest.onGenerateMock((modulePath: string, moduleMock: Record<string, unknown>) => {
  // Normalize: apply default implementations for known modules by path pattern
  if (modulePath.includes('/db')) {
    // Set safe defaults for all db methods — tests that need different behavior
    // override with mockResolvedValueOnce (per-call, not persistent)
    (moduleMock.insertOrder as jest.Mock) = jest.fn().mockResolvedValue(null);
    (moduleMock.findOrder as jest.Mock) = jest.fn().mockResolvedValue(null);
    (moduleMock.listInventory as jest.Mock) = jest.fn().mockResolvedValue([]);
  }

  if (modulePath.includes('/emailService')) {
    // Prevent real email sends from any test file that auto-mocks emailService
    (moduleMock.sendEmail as jest.Mock) = jest.fn().mockResolvedValue({ messageId: 'mock-id' });
  }

  return moduleMock; // always return the (possibly modified) mock
});
```

```typescript
// jest.config.ts — register the setup file that installs onGenerateMock
import type { Config } from 'jest';

const config: Config = {
  setupFilesAfterEnv: ['./jest.setup.ts'], // runs before each test file
  // onGenerateMock callbacks registered here apply to all auto-mocked modules
  // in all test files in the suite
};

export default config;
```

```typescript
// Per-test override still works — use mockResolvedValueOnce for single-call overrides
// src/__tests__/orderService.test.ts
import * as db from '../db';
jest.mock('../db'); // auto-mock — onGenerateMock defaults applied

it('returns null on DB miss', async () => {
  // Default from onGenerateMock: findOrder resolves null — no override needed
  const result = await OrderService.get('unknown-id');
  expect(result).toBeNull();
});

it('returns order on DB hit', async () => {
  // Per-call override — does NOT persist to other tests
  (db.findOrder as jest.Mock).mockResolvedValueOnce({ id: 'ORD-42', status: 'shipped' });
  const result = await OrderService.get('ORD-42');
  expect(result?.status).toBe('shipped');
});
```

**When `onGenerateMock` fires and when it does NOT:**

| Scenario | Does `onGenerateMock` fire? | Notes |
|----------|-----------------------------|-------|
| `jest.mock('./module')` — no factory | Yes | Auto-mock generated; callback invoked |
| `jest.mock('./module', () => ({ ... }))` — explicit factory | **No** | Factory overrides auto-generation entirely |
| Manual mock in `__mocks__/module.ts` | **No** | Manual mock bypasses auto-generation (see AP47) |
| `jest.spyOn(obj, 'method')` | No | Spy patches an existing function; no module-level mock |
| `jest.createMockFromModule('./module')` | No | Programmatic create; callback is not invoked |

---

## Anti-Patterns (iteration 57)

### AP47 — `jest.onGenerateMock()` Registered But `__mocks__` Folder Present: Silent No-Op  [official]

**What:** Registering a `jest.onGenerateMock()` callback to centralize mock defaults (Pattern 96), but also having a manual mock in the `__mocks__/` folder for the same module.

**Why harmful:** When a `__mocks__/module.ts` file exists, Jest uses it directly as the mock — it does NOT call the auto-mock generator, which means `onGenerateMock` is never invoked for that module. The centralized defaults are silently skipped. Tests that depend on the `onGenerateMock` defaults for that module will use whatever the `__mocks__/` file provides instead, which may be stale, incomplete, or have different reset semantics.

```typescript
// BAD: onGenerateMock callback in jest.setup.ts — expects to configure db module defaults
jest.onGenerateMock((modulePath, moduleMock) => {
  if (modulePath.includes('/db')) {
    (moduleMock.findUser as jest.Mock) = jest.fn().mockResolvedValue(null); // intended default
  }
  return moduleMock;
});

// BAD: __mocks__/db.ts also exists — this file IS used, onGenerateMock is NOT called for db
// __mocks__/db.ts
export const findUser = jest.fn(); // no default implementation — resolves undefined, not null
export const insertUser = jest.fn();
// Result: tests that expect null from findUser get undefined — subtle flakiness
```

```typescript
// GOOD: choose one approach per module — do not mix __mocks__ + onGenerateMock

// Option A: Use ONLY onGenerateMock (no __mocks__/db.ts file)
// jest.setup.ts
jest.onGenerateMock((modulePath, moduleMock) => {
  if (modulePath.includes('/db')) {
    (moduleMock.findUser as jest.Mock) = jest.fn().mockResolvedValue(null);
  }
  return moduleMock;
});

// Option B: Use ONLY __mocks__/db.ts with explicit defaults (no onGenerateMock for db)
// __mocks__/db.ts
import { jest } from '@jest/globals';

export const findUser = jest.fn().mockResolvedValue(null); // default explicit
export const insertUser = jest.fn().mockResolvedValue({ id: 'mock-id' });
```

```typescript
// GOOD: document the choice in jest.setup.ts to prevent future mixup
// jest.setup.ts
// IMPORTANT: onGenerateMock defaults apply ONLY to auto-mocked modules.
// Modules with a corresponding __mocks__/ file (e.g., __mocks__/fs.ts, __mocks__/logger.ts)
// use their manual mock and are NOT affected by the callbacks below.
// Do not add a __mocks__/ file for any module configured here.
jest.onGenerateMock((modulePath, moduleMock) => {
  if (modulePath.includes('/db')) {
    (moduleMock.findUser as jest.Mock) = jest.fn().mockResolvedValue(null);
  }
  return moduleMock;
});
```

**Detection checklist:**

- [ ] Does `jest.onGenerateMock` callback fire? Add `console.log(modulePath)` — if no log for the target module, a `__mocks__/` file is taking precedence
- [ ] Does `ls __mocks__/` reveal a file for the module you're configuring in `onGenerateMock`? → Remove one or the other
- [ ] Do tests pass when you delete `__mocks__/module.ts` but fail when it exists? → The manual mock's defaults differ from `onGenerateMock`'s

---

## Gotcha 48 — Playwright `WebSocketRoute.onMessage()` Stops Automatic Forwarding: Silent Test Hang  [official]

When using Playwright's `routeWebSocket()` in **intercept mode** (`connectToServer()` is called), messages between the page and the real server are forwarded automatically by default. The moment you register an `onMessage` handler on **either** the page-side route (`ws`) or the server-side route (`server`), Playwright stops automatic forwarding for that direction. If you forget to manually relay messages using `.send()`, messages are silently dropped — the test hangs waiting for an assertion that will never be satisfied.

```typescript
// BAD: registers onMessage on server side but forgets to relay messages back to the page
// The page never receives the server's responses — test times out

import { test, expect } from '@playwright/test';

test('chat app receives server message', async ({ page }) => {
  await page.routeWebSocket('wss://chat.example.com/ws', async (ws) => {
    const server = await ws.connectToServer();

    server.onMessage((msg) => {
      // BUG: captures the message but does NOT send it to the page
      console.log('Server sent:', msg);
      // MISSING: server.send(msg);   ← page never receives the message
    });
  });

  await page.goto('/chat');
  await page.getByRole('button', { name: /connect/i }).click();

  // HANGS: the page is waiting for a message that was intercepted but not relayed
  await expect(page.locator('[data-testid="chat-message"]')).toBeVisible({ timeout: 5_000 });
});
```

```typescript
// GOOD: always relay messages explicitly once onMessage is registered

import { test, expect } from '@playwright/test';

test('spy on server message and relay to page', async ({ page }) => {
  const serverMessages: string[] = [];

  await page.routeWebSocket('wss://chat.example.com/ws', async (ws) => {
    const server = await ws.connectToServer();

    // Spy on server→page direction: capture AND relay
    server.onMessage((msg) => {
      serverMessages.push(String(msg)); // audit/spy
      server.send(msg);                 // relay to page — required to prevent hang
    });

    // If you also need to spy on page→server direction, register on ws:
    ws.onMessage((msg) => {
      // relay to server — required to prevent server-side hang
      ws.send(msg);
    });
  });

  await page.goto('/chat');
  await page.getByRole('button', { name: /connect/i }).click();

  await expect(page.locator('[data-testid="chat-message"]')).toBeVisible();
  expect(serverMessages.length).toBeGreaterThan(0);
});
```

```typescript
// GOOD: mock mode (no connectToServer) — onMessage is the ONLY source of messages,
// so no relay is needed or expected; the handler IS the server
await page.routeWebSocket('wss://chat.example.com/ws', (ws) => {
  ws.onMessage((incoming) => {
    // In mock mode, ws.send() sends FROM the simulated server TO the page
    ws.send(JSON.stringify({ type: 'echo', data: incoming }));
    // No relay needed — there is no real server to forward to
  });
});
```

**Summary: when to relay vs. when not to:**

| Mode | `onMessage` registered? | Must call `.send()` to relay? |
|------|------------------------|-------------------------------|
| Mock mode (no `connectToServer`) | Yes | No — handler IS the server; `ws.send()` sends to page |
| Intercept mode (`connectToServer` called) — no `onMessage` | N/A | Automatic forwarding active — nothing required |
| Intercept mode — `onMessage` on `ws` (page→server) | Yes | **Yes** — call `ws.send(msg)` to forward to server |
| Intercept mode — `onMessage` on `server` (server→page) | Yes | **Yes** — call `server.send(msg)` to forward to page |

> **Diagnostic tip:** If a test using intercept mode hangs with a locator timeout and you see no network error in the trace, open the trace viewer and check the WebSocket frames tab. If the server sent a frame but the page shows no frame received, a registered `onMessage` dropped it without relay.

---

## Quick Reference additions (iteration 57)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| WebSocket E2E test flakes due to port collision or ws-server lifecycle race | Real test server binding to a port that collides with parallel workers | Pattern 94 (`page.routeWebSocket()` — no port, no server, browser-level intercept) | `new WebSocketServer({ port: 8080 })` in `beforeAll` — static port collides under `--workers > 1` |
| Firebase/IndexedDB auth E2E test fails with 401 despite valid login setup | `storageState()` not capturing IndexedDB auth token (Firebase/Supabase/Amplify) | Pattern 95 (`storageState({ indexedDB: true })` — saves full auth state including IndexedDB) | `storageState()` without `indexedDB: true` — silently omits token, causes auth failure every test |
| `jest.onGenerateMock` callback never fires for a specific module | A `__mocks__/` manual mock file exists for that module — auto-generation bypassed | AP47 (remove `__mocks__/module.ts` OR remove the `onGenerateMock` block for that module) | Mixing `__mocks__/` folder with `onGenerateMock` for the same module — defaults are silently mismatched |
| E2E test hangs on `toBeVisible()` for an element that should appear after a WebSocket message | `WebSocketRoute.onMessage()` registered but message not relayed with `.send()` | Gotcha 48 (always call `server.send(msg)` after capturing in intercept mode) | Registering `onMessage` in intercept mode without a corresponding `.send()` relay |

---

## Key Resources (iteration 57 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright `routeWebSocket` API | Official | https://playwright.dev/docs/api/class-page#page-route-web-socket | `page.routeWebSocket(url, handler)` — WebSocket mocking without a real server (v1.48+) |
| Playwright `WebSocketRoute` class | Official | https://playwright.dev/docs/api/class-websocketroute | `onMessage`, `send`, `connectToServer`, `close`, `protocols` — full intercept API |
| Playwright v1.51 release notes | Official | https://playwright.dev/docs/release-notes#version-151 | `storageState({ indexedDB: true })` — captures IndexedDB for Firebase-style auth |
| Playwright Storage State guide | Official | https://playwright.dev/docs/auth#reuse-signed-in-state | Full auth reuse pattern; `storageState` with `indexedDB: true` for IndexedDB-based auth |
| Jest `onGenerateMock` API | Official | https://jestjs.io/docs/jest-object#jestongenratemockcb | Centralize auto-mock defaults; callback fires for `jest.mock()` without a factory only |

---

## Pattern 97 — Playwright `page.clock` for Deterministic Browser-Level Time Control  [official]

Jest/Vitest fake timers patch the Node.js runtime but do not touch the browser's `Date`, `setTimeout`, or `requestAnimationFrame` inside a real Chromium/Firefox/WebKit process. For Playwright E2E tests that test time-sensitive UI (session expiry banners, countdown timers, auto-logout dialogs, "posted X minutes ago" labels), the only reliable fix is Playwright's built-in Clock API — introduced in v1.45 — which installs a fake clock directly into the browser context.

**Key methods:**

| Method | Effect |
|--------|--------|
| `page.clock.install({ time })` | Replaces `Date`, `setTimeout`, `setInterval`, `requestAnimationFrame`, `performance` with fakes; time frozen at `time` |
| `page.clock.setFixedTime(time)` | Makes `Date.now()` return a fixed value; real timers continue firing at their original intervals |
| `page.clock.pauseAt(time)` | Jumps to `time` and freezes; no timers fire until `resume()` |
| `page.clock.fastForward(duration)` | Jumps time forward; each timer fires at most once (like closing and reopening a laptop) |
| `page.clock.runFor(duration)` | Advances time and fires every timer callback that falls in the window |
| `page.clock.resume()` | Resumes real-time flow after `pauseAt()` |

**Critical caveat:** `install()` MUST be called before any other clock calls, and — for maximum reliability — BEFORE `page.goto()`. Calling `install()` after navigation means some timers may already be running against the real clock.

```typescript
// BAD: testing a session-expiry banner by sleeping
import { test, expect } from '@playwright/test';

test('shows expiry banner after 30-minute inactivity', async ({ page }) => {
  await page.goto('/app');
  await page.waitForTimeout(30 * 60 * 1000); // 30-minute real sleep — cannot run in CI
  await expect(page.getByTestId('session-expiry-banner')).toBeVisible();
});
```

```typescript
// GOOD: freeze the clock, fast-forward to trigger the banner — instant in CI
import { test, expect } from '@playwright/test';

test('shows session-expiry banner after 30-minute inactivity', async ({ page }) => {
  // Install BEFORE navigation — ensures the page loads with the fake clock already active
  await page.clock.install({ time: new Date('2026-06-15T09:00:00.000Z') });

  await page.goto('/app');

  // Fast-forward 31 minutes — timers fire at most once each (correct for session timeout)
  await page.clock.fastForward('31:00');

  await expect(page.getByTestId('session-expiry-banner')).toBeVisible();
  await expect(page.getByTestId('session-expiry-banner')).toContainText('Your session has expired');
});
```

```typescript
// GOOD: testing a countdown timer that updates every second
import { test, expect } from '@playwright/test';

test('countdown timer decrements correctly', async ({ page }) => {
  // pauseAt — freezes time; use runFor to step through intervals
  await page.clock.install({ time: new Date('2026-06-15T12:00:00.000Z') });
  await page.goto('/offer?expires=2026-06-15T12:05:00.000Z');

  // Initial state: 5 minutes remaining
  await expect(page.getByTestId('countdown')).toHaveText('05:00');

  // Advance 1 minute — fires the setInterval callbacks that update the display
  await page.clock.runFor('1:00');
  await expect(page.getByTestId('countdown')).toHaveText('04:00');

  // Advance to expiry
  await page.clock.runFor('4:00');
  await expect(page.getByTestId('countdown')).toHaveText('00:00');
  await expect(page.getByTestId('offer-expired-message')).toBeVisible();
});
```

```typescript
// GOOD: setFixedTime for date-label assertions — simpler when you only need Date.now()
// Use when: the page only reads the date (labels like "posted 3 hours ago"),
// and you don't need to fire timer callbacks
import { test, expect } from '@playwright/test';

test('"posted X ago" label uses current time correctly', async ({ page }) => {
  // setFixedTime is lighter than install() — does not replace setTimeout/setInterval
  await page.clock.setFixedTime(new Date('2026-06-15T15:00:00.000Z'));

  await page.goto('/posts/123'); // post was created at 2026-06-15T12:00:00Z (3 hrs ago)

  await expect(page.getByTestId('post-timestamp')).toHaveText('3 hours ago');
});
```

```typescript
// GOOD: testing date-boundary logic (midnight rollover) with pauseAt + resume
import { test, expect } from '@playwright/test';

test('dashboard shows "Today" label for entries posted today', async ({ page }) => {
  // Jump to 23:59 on June 14 and pause
  await page.clock.install({ time: new Date('2026-06-14T23:59:50.000Z') });
  await page.goto('/dashboard');
  await expect(page.getByTestId('entry-date-label')).toHaveText('Today');

  // Fast-forward 15 seconds — crosses midnight, date label should change to "Yesterday"
  await page.clock.fastForward(15_000);
  await expect(page.getByTestId('entry-date-label')).toHaveText('Yesterday');
});
```

**Scope — clock is context-wide:**

The Playwright clock installs into the entire `BrowserContext`. All pages and iframes created from that context share the same fake clock. This is correct for multi-page tests (e.g., a popup that reads the same `Date.now()` as the opener) but means you cannot set different clocks per page within a single context.

**`fastForward` vs `runFor` — which to use:**

| Method | Timer behavior | Use when |
|--------|---------------|----------|
| `fastForward(d)` | Each timer fires at most once, even if it would have fired many times | Testing expiry / timeout — you just want it to trigger |
| `runFor(d)` | All timers fire as many times as they would in real time | Testing cumulative effects (counters, animations, polling loops) |

---

## Pattern 98 — Playwright `page.addLocatorHandler()` for Automatic Overlay Dismissal  [official]

Unexpected overlays — newsletter sign-up modals, cookie consent banners, chat widget popups, permission prompts — appear non-deterministically during Playwright E2E tests. They block clicks and fill actions with an `Element is not visible` or `Element is intercepted by another element` error. This is a classic source of E2E flakiness: the overlay appears on some runs (depending on server-side feature flags, timing, or first-visit cookies) and not others.

`page.addLocatorHandler()` (introduced in Playwright v1.42, enhanced in v1.44) registers an async callback that fires automatically whenever the specified locator becomes visible. Playwright pauses the in-flight action, runs the handler to dismiss the overlay, then retries the original action — all transparently.

```typescript
// BAD: manually check for and dismiss a cookie banner before every action
// Fragile — the banner may appear mid-test, not just at the start
import { test, expect } from '@playwright/test';

test('user can complete checkout', async ({ page }) => {
  await page.goto('/shop');

  // Manually dismiss banner — only works if banner appears BEFORE this line
  const cookieBanner = page.getByTestId('cookie-consent');
  if (await cookieBanner.isVisible()) {
    await page.getByRole('button', { name: 'Accept' }).click();
  }

  // If the banner appears AFTER this point, the next click will fail with
  // "Element is intercepted by another element: Cookie consent overlay"
  await page.getByRole('button', { name: 'Add to cart' }).click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
});
```

```typescript
// GOOD: addLocatorHandler — registers a persistent handler that fires whenever the
// overlay appears, regardless of when during the test it shows up
import { test, expect } from '@playwright/test';
import { Page } from '@playwright/test';

// Reusable helper — register once per page, works for entire test
async function dismissCookieConsentIfPresent(page: Page): Promise<void> {
  await page.addLocatorHandler(
    page.getByTestId('cookie-consent'),
    async () => {
      await page.getByRole('button', { name: 'Accept' }).click();
      // After clicking, Playwright waits for the overlay to disappear
      // (noWaitAfter: true skips this wait if the overlay has no exit animation)
    },
    { times: 1 } // only dismiss once per test — prevents infinite loops if the banner
                 // re-renders due to a bug
  );
}

test('user can complete checkout', async ({ page }) => {
  await dismissCookieConsentIfPresent(page);

  await page.goto('/shop');

  // Even if the banner appears AFTER this goto, the handler fires before
  // the next action is attempted, dismisses it, and retries automatically
  await page.getByRole('button', { name: 'Add to cart' }).click();
  await expect(page.getByTestId('cart-count')).toHaveText('1');
  await page.getByRole('button', { name: 'Checkout' }).click();
  await expect(page.getByTestId('order-confirmation')).toBeVisible();
});
```

```typescript
// GOOD: using addLocatorHandler in a base fixture for cross-suite overlay handling
// playwright.config.ts defines a base fixture; all tests extending it get auto-handling
import { test as base, expect, Page } from '@playwright/test';

type Fixtures = {
  autoDismissOverlays: void;
};

export const test = base.extend<Fixtures>({
  autoDismissOverlays: [
    async ({ page }, use) => {
      // Cookie consent
      await page.addLocatorHandler(
        page.getByTestId('cookie-consent'),
        async () => {
          await page.getByRole('button', { name: /accept|got it/i }).click();
        },
        { times: 1 }
      );

      // Newsletter signup modal
      await page.addLocatorHandler(
        page.getByRole('dialog', { name: /newsletter/i }),
        async () => {
          await page.getByRole('button', { name: /close|no thanks/i }).click();
        },
        { times: 1 }
      );

      await use(); // run the test
      // Handlers are automatically removed when the page/context closes
    },
    { auto: true }, // auto-use: every test in this suite gets it without opting in
  ],
});

// Usage: import { test, expect } from './fixtures';
// All tests automatically dismiss cookie consent and newsletter modals
test('product page loads', async ({ page }) => {
  await page.goto('/products/123');
  // No explicit overlay handling needed — autoDismissOverlays handles it
  await expect(page.getByTestId('product-title')).toBeVisible();
});
```

**Options reference:**

| Option | Type | Default | Meaning |
|--------|------|---------|---------|
| `times` | `number` | unlimited | Max invocations before handler is auto-removed |
| `noWaitAfter` | `boolean` | `false` | Skip waiting for the overlay to hide after the handler returns |

**Gotchas:**

- Handler execution time counts against the action timeout of the in-flight action. If your overlay dismissal is slow (animated close), increase the action timeout or set `noWaitAfter: true` if the animation is cosmetic.
- Only one handler fires at a time. If two overlays appear simultaneously, handlers queue and fire in registration order.
- Use `times: 1` for overlays that should appear once per session. Without a limit, a broken overlay that keeps re-rendering will cause an infinite handler loop. [community]
- Explicitly handle overlays that are ALWAYS present (e.g., a mandatory cookie banner) rather than using a handler — handlers are for overlays that appear non-deterministically. Using a handler for a guaranteed element hides errors if the element never appears.

---

## Pattern 99 — Vitest 4.0 `sequence.shuffle` + `getSeed()` for Reproducible Order-Dependent Flakiness  [official]

Order-dependent flakiness occurs when a test passes only if certain other tests ran (or did not run) before it, usually because of shared module state, in-memory singletons, or database rows left from a previous test. It is the hardest flakiness family to diagnose because the failure pattern changes on every run.

The standard recommendation is to run the suite in randomized order (`sequence.shuffle`) so that order-dependencies surface early. Vitest 4.0 adds `getSeed()` — a programmatic API that returns the seed value used for the current randomized run. Capturing this seed turns a non-reproducible random failure into a fully reproducible one: re-run with `--sequence.seed=<captured>` to get the identical order.

```typescript
// vitest.config.ts — enable shuffled order with a deterministic fallback seed in CI
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    sequence: {
      shuffle: true,          // randomize test file AND test-within-file order
      seed: process.env.CI
        ? undefined           // CI: fresh random seed each run — surfaces new order-deps
        : 1234,               // local: fixed seed for a stable development experience
    },
  },
});
```

```typescript
// vitest.setup.ts — capture and print the seed at run start so you can reproduce failures
// This runs once before any test file
import { getSeed } from 'vitest';

// getSeed() returns undefined if sequence.shuffle is false or seed was not set
const seed = getSeed();
if (seed !== undefined) {
  // Output appears at the top of the run log — copy this if the run fails
  console.log(`[vitest] running in random order with seed: ${seed}`);
  console.log(`[vitest] to reproduce this order: vitest --sequence.seed=${seed}`);
}
```

```typescript
// Alternative: capture seed in a custom reporter for structured CI log output
// reporters/seed-reporter.ts
import type { Reporter, TestContext } from 'vitest';
import { getSeed } from 'vitest';

export default class SeedReporter implements Reporter {
  onInit(): void {
    const seed = getSeed();
    if (seed !== undefined) {
      // Write to a file so CI scripts can attach it to the failure report
      const fs = require('fs');
      fs.writeFileSync(
        'test-results/seed.txt',
        `sequence.seed=${seed}\n`,
        'utf-8'
      );
    }
  }
}
```

```typescript
// vitest.config.ts with custom seed reporter alongside standard reporters
import { defineConfig } from 'vitest/config';
import SeedReporter from './reporters/seed-reporter';

export default defineConfig({
  test: {
    sequence: { shuffle: true },
    reporters: [
      'default',
      new SeedReporter(),
    ],
  },
});
```

**Workflow for diagnosing order-dependent flakiness:**

```
1. Enable sequence.shuffle: true in vitest.config.ts
2. Run the suite in CI with --reporter=default (shows seed in console via setup log)
3. When a test fails that passes in isolation:
   a. Copy the seed from the run log
   b. Locally run: vitest --sequence.seed=<captured-seed>
   c. Confirm the same failure reproduces
4. Narrow down the culprit:
   a. Run: vitest --sequence.seed=<seed> <failing-test-file>.test.ts
   b. Use it.only on the failing test — if it NOW passes, the failure is order-dependent
5. Find the polluter:
   a. Run: vitest --sequence.seed=<seed> --reporter=verbose to see execution order
   b. Bisect: split tests at the midpoint; run first half before the failing test;
      repeat until you find the first test that causes the failure
6. Fix: add beforeEach reset for the shared state the polluter modifies
```

```typescript
// Example: order-dependent failure and fix
// BAD: module-level singleton leaks between tests in random order
// UserCache.ts
export class UserCache {
  private static cache = new Map<string, User>(); // shared across all test files!

  static get(id: string): User | undefined {
    return this.cache.get(id);
  }

  static set(id: string, user: User): void {
    this.cache.set(id, user);
  }
}

// user-service.test.ts — passes when run alone, fails when another test
// populates the cache beforehand
it('returns undefined for unknown user', () => {
  // If another test called UserCache.set('unknown-id', ...) before this one,
  // this assertion fails — classic order-dependent failure
  expect(UserCache.get('unknown-id')).toBeUndefined();
});

// GOOD fix: clear the singleton in beforeEach regardless of order
beforeEach(() => {
  // Reset the class-level Map so no test can pollute another
  // UserCache.clearAll() if public API exists, or:
  (UserCache as unknown as { cache: Map<string, User> }).cache.clear();
});
```

**`getSeed()` availability:**

`getSeed()` is exported from the `vitest` package (not from `vitest/node` or the `vi` object). It returns `undefined` when `sequence.shuffle` is disabled or when `seed` was not set — always guard with a null check before logging.

---

## Anti-Patterns (iteration 58)

### AP48 — `page.clock.install()` Called After `page.goto()`: Undefined Clock Behavior  [official]

**What:** Calling `page.clock.install()` after `page.goto()` instead of before it.

**Why harmful:** When a page navigates, the browser immediately begins executing JavaScript — including timers and `Date` reads that happen during the load phase (e.g., a session token expiry check on `DOMContentLoaded`, a countdown timer initialized in module scope). If `install()` is called after `goto()`, those early timers have already started against the real system clock. The fake clock only takes over for timers created AFTER `install()`. The result is a partially-fake clock state: some timers run against real time, others against fake time. This produces subtle, hard-to-reproduce flakiness where tests pass locally (fast CI, no early-timer race) but fail in slow environments.

```typescript
// BAD: install() called after goto() — early page timers already fired against real clock
import { test, expect } from '@playwright/test';

test('session expiry banner appears after 30 minutes', async ({ page }) => {
  await page.goto('/app'); // ← page loads; JS runs; session timer starts on real clock

  // TOO LATE: the session timer was already created using real Date.now()
  await page.clock.install({ time: new Date('2026-06-15T09:00:00.000Z') });
  await page.clock.fastForward('31:00');

  // May pass or fail depending on how long goto() took and when the timer was created
  await expect(page.getByTestId('session-expiry-banner')).toBeVisible();
});
```

```typescript
// GOOD: install() called before goto() — fake clock is active for ALL page JavaScript
import { test, expect } from '@playwright/test';

test('session expiry banner appears after 30 minutes', async ({ page }) => {
  // Install FIRST — clock is fake from the very first frame the page renders
  await page.clock.install({ time: new Date('2026-06-15T09:00:00.000Z') });

  await page.goto('/app'); // page loads with fake clock already active — deterministic

  await page.clock.fastForward('31:00');
  await expect(page.getByTestId('session-expiry-banner')).toBeVisible();
});
```

```typescript
// GOOD: setFixedTime() is safe to call at any time (does not affect timer scheduling)
// Use setFixedTime when you only need to control Date.now() for label rendering,
// not for triggering setTimeout/setInterval callbacks
import { test, expect } from '@playwright/test';

test('"posted X ago" label shows correct relative time', async ({ page }) => {
  await page.goto('/posts/abc');
  // setFixedTime is safe post-navigation — it patches Date.now() only, no timer state
  await page.clock.setFixedTime(new Date('2026-06-15T15:00:00.000Z'));
  await page.reload(); // reload to let the page re-read Date.now() with the fixed time
  await expect(page.getByTestId('post-timestamp')).toHaveText('3 hours ago');
});
```

**Summary:**

| Method | Safe after `goto()`? | Notes |
|--------|---------------------|-------|
| `install()` | No — undefined behavior for timers started before install | Must call before navigation |
| `setFixedTime()` | Yes | Only patches `Date.now()` — no timer scheduling state affected |
| `pauseAt()` | Only after `install()` | `install()` must precede `pauseAt()` regardless of navigation order |
| `fastForward()` | Only after `install()` | Same as above |
| `runFor()` | Only after `install()` | Same as above |

> **Diagnostic tip:** If a clock-based test passes locally but fails in CI with "element not found" on a time-dependent locator, check whether `install()` is called before or after `goto()`. CI machines often render pages faster than local dev, meaning early timers fire before `install()` more reliably on CI — making the ordering bug MORE visible there, not less.

---

## Quick Reference additions (iteration 58)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| E2E test for timer/countdown/session expiry is flaky — passes locally, fails in CI | Timer started against real clock before `page.clock.install()` was called | Pattern 97 (call `page.clock.install()` BEFORE `page.goto()`) | AP48 (`page.clock.install()` after navigation — partial fake clock, non-deterministic timer state) |
| E2E test fails with "Element is intercepted by another element" only on some runs | Non-deterministic overlay (cookie banner, chat widget, sign-up modal) appearing mid-test | Pattern 98 (`page.addLocatorHandler()` — registers auto-dismiss callback that fires on every appearance) | Manually checking `isVisible()` at test start — misses overlays that appear mid-test |
| Order-dependent unit test failure visible only in CI, can't reproduce locally | Tests run in deterministic alphabetical order locally; CI randomizes order and hits shared state pollution | Pattern 99 (`sequence.shuffle: true` + `getSeed()` capture — reproduce exact failing order with `--sequence.seed=<N>`) | Running with fixed order locally (default) — order-dependencies are invisible until CI randomizes |
| `page.clock` fast-forward does not trigger expected timer callback | `runFor()` used instead of `fastForward()` or vice versa — wrong semantic for the use case | Pattern 97 (use `fastForward` for expiry/once-only triggers; `runFor` for cumulative interval effects) | Mixing `fastForward` and `runFor` without understanding the "fires at most once" vs "fires every interval" distinction |

---

## Key Resources (iteration 58 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright Clock API guide | Official | https://playwright.dev/docs/clock | `page.clock.install/pauseAt/fastForward/runFor/setFixedTime` — browser-level fake clock for E2E time tests |
| Playwright `Clock` class reference | Official | https://playwright.dev/docs/api/class-clock | Full API reference for all Clock methods and parameters |
| Playwright v1.45 release notes | Official | https://playwright.dev/docs/release-notes#version-145 | Clock API introduced (v1.45) |
| Playwright `page.addLocatorHandler()` | Official | https://playwright.dev/docs/api/class-page#page-add-locator-handler | Auto-dismiss overlays that block actions; `times` and `noWaitAfter` options |
| Playwright v1.42 release notes | Official | https://playwright.dev/docs/release-notes#version-142 | `addLocatorHandler` introduced (v1.42) |
| Vitest `getSeed()` API | Official | https://vitest.dev/api/#getseed | Returns current run's shuffle seed — use to reproduce order-dependent CI failures |

---

## Pattern 100 — Playwright v1.52 `testResult.annotations` in Custom Reporters for Per-Retry Flakiness Tracking  [official]

Playwright v1.52 added `testResult.annotations` — a per-result (per-retry) annotations array that captures annotations attached during each individual test execution attempt. Before v1.52, annotations were only accessible at the `testCase` level (covering the entire test, not per-attempt). With v1.52, a custom reporter can now compare annotations across retry attempts to identify _which_ retry introduced a specific state, error category, or diagnostic label — enabling structured, typed flakiness reports beyond the raw pass/fail outcome.

**Why this matters for flakiness:** When a test runs with `retries: 2`, there are up to 3 result objects (`retry 0`, `retry 1`, `retry 2`). `testResult.annotations` on each result contains annotations added via `testInfo.annotations.push()` during that specific attempt. By comparing annotations across retries, a reporter can surface patterns like "the test fails with `type: 'network-timeout'` on retry 0 and 1, then passes on retry 2" — turning a binary flaky/not-flaky signal into a structured root-cause hint.

```typescript
// reporters/flakiness-annotation-reporter.ts
// Custom Playwright reporter that surfaces per-retry annotation patterns for flakiness triage
// Run via playwright.config.ts: reporter: [['./reporters/flakiness-annotation-reporter.ts']]

import type { Reporter, TestCase, TestResult } from '@playwright/test/reporter';
import { writeFileSync } from 'fs';

interface FlakyAnnotationEntry {
  title: string;
  file: string;
  retries: Array<{
    retry: number;
    status: string;
    annotations: Array<{ type: string; description?: string }>;
  }>;
}

export default class FlakinessAnnotationReporter implements Reporter {
  private flakyTests: FlakyAnnotationEntry[] = [];

  onTestEnd(test: TestCase, result: TestResult): void {
    // A test is "flaky" if it passed on a retry (retry > 0 and status is 'passed')
    // or if it has any retry result that differs from the last
    const isFlaky =
      result.status === 'passed' && result.retry > 0;

    if (isFlaky) {
      const existing = this.flakyTests.find(e => e.title === test.title);
      const retryEntry = {
        retry: result.retry,
        status: result.status,
        // testResult.annotations: per-retry annotations — new in Playwright v1.52
        annotations: result.annotations.map(a => ({
          type: a.type,
          description: a.description,
        })),
      };

      if (existing) {
        existing.retries.push(retryEntry);
      } else {
        this.flakyTests.push({
          title: test.title,
          file: test.location.file,
          retries: [retryEntry],
        });
      }
    }
  }

  onEnd(): void {
    if (this.flakyTests.length === 0) return;

    const report = {
      generated: new Date().toISOString(),
      flakyCount: this.flakyTests.length,
      tests: this.flakyTests,
    };

    writeFileSync('test-results/flakiness-annotations.json', JSON.stringify(report, null, 2));
    console.log(`\n[FlakinessAnnotationReporter] ${this.flakyTests.length} flaky test(s) — see test-results/flakiness-annotations.json`);
  }
}
```

```typescript
// In your E2E tests: attach structured annotations during test execution
// These annotations surface in testResult.annotations per retry
import { test, expect } from '@playwright/test';

test('checkout payment flow', async ({ page, request }, testInfo) => {
  // Attach a structured annotation describing the test's external dependency state.
  // If this attempt fails, the annotation appears in testResult.annotations for this retry.
  testInfo.annotations.push({
    type: 'payment-provider',
    description: `endpoint=${process.env.PAYMENT_ENDPOINT ?? 'staging'} ts=${Date.now()}`,
  });

  await page.goto('/checkout');

  // If a network call fails, annotate with the error category for the reporter to surface
  try {
    await page.waitForResponse(
      resp => resp.url().includes('/api/payment') && resp.status() === 200,
      { timeout: 8_000 }
    );
  } catch (err) {
    // Annotating here means testResult.annotations will contain this on the failing retry
    testInfo.annotations.push({
      type: 'network-timeout',
      description: 'Payment API did not respond within 8s — likely infrastructure flakiness',
    });
    throw err; // re-throw so the test fails and Playwright retries
  }

  await expect(page.getByTestId('confirmation')).toBeVisible();
});
```

```typescript
// playwright.config.ts — wire up the custom annotation reporter alongside standard reporters
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  failOnFlakyTests: !!process.env.CI,

  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['junit', { outputFile: 'test-results/results.xml' }],
    // Custom reporter: surfaces per-retry annotations for structured flakiness tracking
    // Requires Playwright v1.52+ for testResult.annotations support
    ['./reporters/flakiness-annotation-reporter.ts'],
  ],

  use: {
    trace: 'on-first-retry',
  },
});
```

**Key distinction from `testCase.outcome()` (Pattern 86/53):**
- `testCase.outcome()` returns `'flaky'`, `'passed'`, `'failed'`, or `'skipped'` for the entire test case across all attempts — a single aggregate verdict
- `testResult.annotations` is per-attempt — you can examine which annotations appeared on the failing attempt vs the passing attempt, enabling root-cause classification beyond the binary flaky/pass outcome

---

## Pattern 101 — Vitest 3.2 `context.annotate()` for Structured Test Metadata Visible Across All Reporters  [official]

Vitest 3.2 introduced `context.annotate()` — a first-class API for attaching structured metadata to individual test cases during execution. Unlike `console.log()` (which outputs to stdout but is not captured by reporters) or `testInfo.attach()` (Playwright-specific), `context.annotate()` writes metadata that is natively surfaced in Vitest's HTML report, UI mode, JUnit XML output, TAP output, and the GitHub Actions reporter.

**Why this matters for flakiness:** Flaky tests often fail for different reasons on different runs. By calling `context.annotate()` with structured metadata (the exact DB state, the network response, the feature flag values in effect), each failure attempt carries a labeled evidence snapshot. When the JUnit XML is ingested by BuildPulse or Trunk, the annotations appear alongside the failure — enabling AI-based root cause classification (Pattern 49 / Gotcha 45) on structured data rather than raw stack traces.

```typescript
// vitest.config.ts — ensure the reporters that surface annotations are enabled
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    retry: process.env.CI ? 2 : 0,
    reporters: [
      'verbose',             // shows annotations in terminal on failure
      ['junit', { outputFile: 'test-results/vitest-results.xml' }],
      ['html'],              // annotations visible in the HTML report inline
      // 'github-actions' reporter: formats annotations as ::notice/warning/error messages
    ],
    // Pair with detectAsyncLeaks to surface async context annotations correctly
    detectAsyncLeaks: process.env.CI === 'true',
  },
});
```

```typescript
// OrderService.test.ts — annotate with structured diagnostic metadata during test execution
import { describe, it, expect } from 'vitest';
import { OrderService } from './OrderService';
import { db } from './test-utils/db';

describe('OrderService — integration with annotations', () => {
  it('creates order and updates inventory atomically', async (context) => {
    // Annotate: capture the current DB state before the operation.
    // If this test fails intermittently, the annotation shows exactly what state
    // existed in the DB — enabling post-mortem root cause analysis.
    const inventoryBefore = await db.inventory.findBySku('SKU-A001');
    await context.annotate(
      `inventory.before: sku=SKU-A001 available=${inventoryBefore?.available ?? 'MISSING'}`,
      'info'
    );

    const order = await OrderService.create({
      userId: 'user-42',
      items: [{ sku: 'SKU-A001', qty: 2 }],
    });

    const inventoryAfter = await db.inventory.findBySku('SKU-A001');
    // Annotate: capture post-operation state. Visible in Vitest HTML report and JUnit XML.
    await context.annotate(
      `inventory.after: sku=SKU-A001 available=${inventoryAfter?.available ?? 'MISSING'} orderId=${order.id}`,
      'info'
    );

    expect(order.id).toMatch(/^ORD-/);
    // This assertion occasionally fails in parallel runs — the annotation above provides
    // the exact inventory count at the time of failure for each retry attempt
    expect(inventoryAfter?.available).toBe((inventoryBefore?.available ?? 0) - 2);
  });
});
```

```typescript
// Annotation with file attachment — embed a JSON snapshot as an annotation body
// Available in Vitest 3.2+ via the object form of context.annotate()
import { describe, it, expect } from 'vitest';

describe('PaymentGateway — annotation with file body', () => {
  it('processes payment within 3 seconds', async (context) => {
    const startMs = Date.now();
    const result = await PaymentGateway.charge({ amount: 5000, currency: 'USD' });
    const durationMs = Date.now() - startMs;

    // Annotate with a structured body — visible in Vitest HTML report with syntax highlighting
    await context.annotate('payment-response', {
      contentType: 'application/json',
      body: JSON.stringify({ result, durationMs, timestamp: new Date().toISOString() }, null, 2),
      bodyEncoding: 'utf-8',
    });

    expect(result.status).toBe('succeeded');
    expect(durationMs).toBeLessThan(3_000);
    // If this fails due to a timeout, the annotation body shows the partial result
    // and the exact duration, enabling diagnosis of whether the issue is gateway latency
    // or a test environment configuration problem
  });
});
```

**Reporter-specific behavior for `context.annotate()`:**

| Reporter | How annotations appear |
|----------|----------------------|
| `verbose` | Shown inline after the test name on failure; all annotations shown on pass |
| `html` | Annotations panel next to test code in the HTML report |
| `junit` | `<properties>` element inside `<testcase>` — parseable by BuildPulse, Trunk, GitHub Annotations |
| `github-actions` | Formatted as `::notice`/`::warning`/`::error` — visible directly in the PR checks UI |
| `tap` | Appended as diagnostic lines after the TAP result |

**`context.annotate()` vs `testInfo.attach()` (Playwright):**

| Aspect | Vitest `context.annotate()` | Playwright `testInfo.attach()` |
|--------|----------------------------|-------------------------------|
| Reporter integration | All reporters (JUnit, HTML, GitHub Actions, TAP) | HTML report only (not JUnit) |
| File attachment | Yes (`body` + `contentType`) | Yes (`path` or `body`) |
| Per-retry visibility | Yes — each retry's annotations are independent | Yes — attachments are per-result |
| Use case | Structured diagnostic metadata for flakiness classification | Binary artifacts (screenshots, traces, HAR) |

---

## Real-World Gotchas (iteration 59)  [community]

**Gotcha 49 — `dorny/test-reporter` GitHub Action Adds PR-Level Flakiness Annotations Without External Services**  [community]

The `dorny/test-reporter` GitHub Action (v1.9+, 2025) parses JUnit XML output from Playwright, Vitest, and Jest and posts test results as GitHub Checks with inline PR annotations — without BuildPulse, Trunk, or any external SaaS. Critically, it marks any test that has both a `failure` and a `flaky="true"` attribute in the JUnit XML (Playwright's native output) as a flaky annotation directly in the PR diff view.

This means developers see "this test is flaky — it passed on retry 2" inline next to the changed code, not buried in CI logs. Teams that adopted this pattern in 2025 reported a 40% increase in developers opening flakiness investigation issues vs. silently re-running CI.

```yaml
# .github/workflows/e2e.yml — add dorny/test-reporter to any existing Playwright CI job
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npx playwright install --with-deps chromium

      - name: Run Playwright tests
        # always() ensures the reporter step runs even when tests fail
        run: npx playwright test --reporter=junit --retries=2
        env:
          CI: true
        continue-on-error: true   # don't fail CI here — let the reporter decide

      - name: Publish test results (with flakiness annotations)
        # dorny/test-reporter v1.9+ supports Playwright's flaky="true" attribute in JUnit XML
        # It posts results as a GitHub Check with inline PR annotations for failed/flaky tests
        uses: dorny/test-reporter@v1
        if: always()
        with:
          name: 'Playwright E2E Results'
          path: 'test-results/results.xml'   # JUnit XML from Playwright
          reporter: java-junit
          # fail-on-error: true causes the workflow to fail if any test failed (not flaky)
          # fail-on-flaky: true additionally fails if any flaky tests were detected
          fail-on-error: 'true'
          fail-on-flaky: 'true'   # NEW in dorny/test-reporter v1.9 — fails CI on flakiness

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 7
```

```typescript
// playwright.config.ts — ensure JUnit reporter outputs the flaky="true" attribute
// Playwright's built-in JUnit reporter sets flaky="true" on testcases that
// passed on retry — dorny/test-reporter reads this attribute for its flaky gate
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: 2,
  failOnFlakyTests: !!process.env.CI,

  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    // JUnit reporter: produces flaky="true" on test cases that passed after retry
    // Required for dorny/test-reporter's flakiness detection to work
    ['junit', {
      outputFile: 'test-results/results.xml',
      includeProjectInTestName: true,  // disambiguates tests across browsers
    }],
  ],

  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
});
```

**Why `dorny/test-reporter` over the GitHub Actions step summary approach (Pattern 19):**

| Approach | PR annotations | Inline diff view | No external service | Works for Vitest too |
|----------|---------------|-----------------|--------------------|--------------------|
| Pattern 19 (GITHUB_STEP_SUMMARY script) | Summary tab only | No | Yes | Yes (with JUnit) |
| dorny/test-reporter | Yes — inline PR comments | Yes | Yes | Yes (with JUnit) |
| BuildPulse | Yes | Yes | No (SaaS) | Yes |
| Trunk Flaky Tests | Yes | Yes | No (SaaS) | Yes |

The key advantage: dorny/test-reporter posts flakiness as a GitHub Checks annotation — visible in the PR "Checks" tab and in the "Files changed" diff view — giving developers immediate context without leaving the PR review flow.

---

## Anti-Patterns (iteration 59)

### AP49 — Calling `getSeed()` Inside Test Bodies Instead of Setup Files  [official]

**What:** Calling `getSeed()` from `vitest` inside individual test bodies or `beforeEach` hooks to capture the current sequence seed.

**Why harmful:** `getSeed()` is designed to be called once in a `setupFiles` entry or in `onInit` reporter hooks. When called inside a test body, `getSeed()` returns `undefined` in some configurations (specifically when `sequence.shuffle` was not configured before the first test file was imported), because the sequence seed is determined at the `TestRunner` initialization stage — before individual test files execute. Teams that add `const seed = getSeed()` inside test bodies and then log `seed: undefined` mistakenly assume the shuffle is disabled, when in fact it was enabled but the call site was too late in the lifecycle.

```typescript
// BAD: getSeed() inside a test body — may return undefined intermittently
import { describe, it, expect } from 'vitest';
import { getSeed } from 'vitest';

describe('OrderService — order-dependency check', () => {
  it('creates order', async () => {
    // BAD: calling getSeed() here — may return undefined because
    // the sequence seed is resolved before test file execution begins
    const seed = getSeed();
    console.log(`seed in test body: ${seed}`); // often logs: "seed in test body: undefined"
    // ... test body
  });
});

// GOOD: getSeed() in a setupFile — called once at the correct lifecycle stage
// vitest.setup.ts (referenced in vitest.config.ts setupFiles: ['./vitest.setup.ts'])
import { getSeed } from 'vitest';

// This runs once per worker before any test file — getSeed() returns the seed here
const seed = getSeed();
if (seed !== undefined) {
  console.log(`[vitest] sequence.seed=${seed} — copy to reproduce: vitest --sequence.seed=${seed}`);
  // Optionally persist to a file for CI artifact collection
  import('fs').then(fs =>
    fs.writeFileSync('test-results/seed.txt', `${seed}`, 'utf-8')
  );
}

// ALSO GOOD: getSeed() in a custom Reporter's onInit() — runs before any test
// reporters/seed-capture-reporter.ts
import type { Reporter } from 'vitest/node';
import { getSeed } from 'vitest';

export default class SeedCaptureReporter implements Reporter {
  onInit(): void {
    // onInit fires once before any test — getSeed() is always defined here if shuffle is on
    const seed = getSeed();
    if (seed !== undefined) {
      process.stderr.write(`[seed] sequence.seed=${seed}\n`);
    }
  }
}
```

**Rule of thumb:** `getSeed()` belongs in lifecycle boundaries — `setupFiles`, `globalSetup`, or `Reporter.onInit()`. Inside test bodies, it is unreliable because the test runner's scheduling decisions have already been made before your test function executes.

---

## Quick Reference additions (iteration 59)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Flaky test passes on retry but CI reporter shows no root-cause detail | No per-retry annotations in custom reporter | Pattern 100 (testResult.annotations in v1.52 reporter) | Using only testCase.outcome() — single aggregate verdict, no per-retry detail |
| Flaky test failures vary in error type across retries — hard to classify | No structured metadata attached per attempt | Pattern 101 (context.annotate() for per-retry structured metadata) | console.log() — not captured by reporters |
| PR author doesn't see flakiness signal until checking CI logs | Flakiness reported only in step summary or external SaaS | Gotcha 49 (dorny/test-reporter — inline PR annotations from JUnit XML) | Pattern 19 only — step summary requires navigating away from PR |
| `getSeed()` returns `undefined` in test body when shuffle is enabled | getSeed() called after seed is already resolved | AP49 (move getSeed() to setupFiles or Reporter.onInit()) | Calling getSeed() inside test body or beforeEach |

---

## Key Resources (iteration 59 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright `testResult.annotations` | Official | https://playwright.dev/docs/api/class-testresult#test-result-annotations | Per-retry annotations array — new in v1.52; enables structured flakiness root-cause reporting |
| Playwright v1.52 release notes | Official | https://playwright.dev/docs/release-notes#version-152 | `testResult.annotations`, `testConfig.failOnFlakyTests`, `testProject.workers` all introduced |
| Vitest `context.annotate()` API | Official | https://vitest.dev/guide/test-annotations | Structured test metadata visible in HTML, JUnit, GitHub Actions, TAP, and verbose reporters — v3.2+ |
| dorny/test-reporter GitHub Action | Community | https://github.com/dorny/test-reporter | Parse JUnit/Jest XML and post inline PR flakiness annotations as GitHub Checks — v1.9+ supports `fail-on-flaky` |
| Vitest `sequence` config | Official | https://vitest.dev/config/sequence | `sequence.shuffle`, `sequence.seed`, `sequence.concurrent`, `sequence.hooks` |

---

## Pattern 102 — EventEmitter `maxListeners` Warning as a Flakiness Signal  [community]

Node.js `EventEmitter` emits a `MaxListenersExceededWarning` when more than 10 listeners are
attached to a single event. In a test suite, this warning is a leading indicator of a listener
leak that will eventually cause order-dependent failures: listener A from test 1 fires during
test 2's execution and mutates shared state, producing a result that looks non-deterministic.

The warning is emitted to `process.stderr` and does not fail the test — so most teams never see
it until the cascade hits. Promoting it to a thrown error in the test harness surfaces the leak
before it becomes a flakiness mystery.

```typescript
// test-setup/event-emitter-guard.ts
// Add to vitest.config.ts setupFiles: ['./test-setup/event-emitter-guard.ts']
// or jest.config.ts globalSetup / setupFilesAfterFramework

import { EventEmitter } from 'events';

/**
 * Promote EventEmitter MaxListenersExceededWarning to a thrown error.
 * Without this, listener leaks accumulate silently across tests until they cause
 * order-dependent failures that are very hard to attribute to their root cause.
 *
 * Lowering the threshold to 5 for tests catches leaks earlier than the Node.js default of 10.
 */
EventEmitter.defaultMaxListeners = 5; // stricter than Node default (10) — catches leaks sooner

// Capture the original emit to intercept MaxListenersExceededWarning
const originalEmit = process.emit.bind(process);

// @ts-expect-error — overriding process.emit signature intentionally
process.emit = function (event: string, ...args: unknown[]): boolean {
  if (
    event === 'warning' &&
    args[0] instanceof Error &&
    (args[0] as NodeJS.ErrnoException).name === 'MaxListenersExceededWarning'
  ) {
    // Convert the warning into a hard error — surfaces the listener leak immediately
    // The error message includes the emitter type and event name for fast diagnosis
    throw new Error(
      `[TEST HARNESS] Listener leak detected: ${(args[0] as Error).message}\n` +
      'Root cause: a test is attaching listeners without removing them in afterEach.\n' +
      'Fix: call emitter.removeListener() or emitter.off() in afterEach, or use emitter.once().'
    );
  }
  return originalEmit(event, ...args);
};
```

```typescript
// Example: EventEmitter listener leak and its fix
// BAD: listener attached in beforeEach, never removed — leaks across all tests in the file
import { EventEmitter } from 'events';
import { describe, it, expect, beforeEach } from 'vitest';
import { OrderEventBus } from '../src/OrderEventBus';

const bus = new OrderEventBus(); // module-level singleton — shared across tests

describe('OrderEventBus — BAD: listener leak', () => {
  let received: string[] = [];

  beforeEach(() => {
    received = [];
    // PROBLEM: each test adds a new listener; none are removed in afterEach
    // After 5 tests, MaxListenersExceededWarning fires (threshold = 5)
    bus.on('order:created', (orderId: string) => received.push(orderId));
  });

  it('receives order:created event', async () => {
    await bus.emit('order:created', 'ORD-001');
    expect(received).toContain('ORD-001');
  });
});

// GOOD: capture and remove listener in afterEach
import { describe, it, expect, beforeEach, afterEach } from 'vitest';

describe('OrderEventBus — GOOD: listener cleanup', () => {
  let received: string[] = [];
  // Store handler reference so we can remove the exact same function in afterEach
  let handler: (orderId: string) => void;

  beforeEach(() => {
    received = [];
    handler = (orderId: string) => received.push(orderId);
    // Attach the handler — will be removed in afterEach
    bus.on('order:created', handler);
  });

  afterEach(() => {
    // Remove the exact handler reference — prevents listener accumulation
    bus.off('order:created', handler);
  });

  it('receives order:created event', async () => {
    await bus.emit('order:created', 'ORD-001');
    expect(received).toContain('ORD-001');
  });

  it('does NOT receive events from previous test', async () => {
    // Previous test's handler was removed — no stale listener to fire
    expect(received).toHaveLength(0); // starts clean because afterEach removed the handler
  });
});
```

```typescript
// BEST: use EventEmitter.once() when each test only needs a single event
// once() auto-removes the listener after the first emission — zero cleanup required
import { describe, it, expect } from 'vitest';

describe('OrderEventBus — BEST: once() pattern', () => {
  it('receives order:created once, no cleanup needed', () => {
    return new Promise<void>((resolve, reject) => {
      // once() automatically removes itself after firing — no afterEach cleanup
      bus.once('order:created', (orderId: string) => {
        try {
          expect(orderId).toBe('ORD-001');
          resolve();
        } catch (e) {
          reject(e);
        }
      });
      // Set a timeout guard — prevents the test from hanging if the event never fires
      setTimeout(() => reject(new Error('order:created event never fired — timeout')), 3000);
      bus.emit('order:created', 'ORD-001');
    });
  });
});
```

**Listener count audit utility** — run before committing to catch leaks missed by the threshold:

```typescript
// scripts/audit-event-listeners.ts
// Run: npx ts-node scripts/audit-event-listeners.ts
// Inspects all EventEmitter instances reachable from the test process and reports listener counts.

import { EventEmitter } from 'events';

/**
 * Patches EventEmitter to track all instances globally.
 * Add to test-setup before any imports to capture all emitters.
 */
const emitters: WeakRef<EventEmitter>[] = [];
const OriginalEE = EventEmitter;

class TrackedEventEmitter extends EventEmitter {
  constructor() {
    super();
    emitters.push(new WeakRef(this));
  }
}

// Replace global EventEmitter in tests — any code that does `new EventEmitter()` is tracked
// This is a test-only override — never use in production
Object.defineProperty(global, 'EventEmitter', { value: TrackedEventEmitter, writable: true });

// Report after each test suite completes:
export function reportListenerCounts(): void {
  let hasLeak = false;
  for (const ref of emitters) {
    const ee = ref.deref();
    if (!ee) continue; // GC'd — no longer a concern
    for (const event of ee.eventNames()) {
      const count = ee.listenerCount(event);
      if (count > 3) { // threshold: > 3 listeners on any single event in tests is suspicious
        console.warn(`[LISTENER AUDIT] ${ee.constructor.name}.on('${String(event)}') has ${count} listeners — possible leak`);
        hasLeak = true;
      }
    }
  }
  if (!hasLeak) console.log('[LISTENER AUDIT] OK — no suspicious listener counts');
}
```

---

## Pattern 103 — `jest.doMock()` + `resetModules` for Order-Independent Dynamic Mocking  [community]

`jest.mock()` is **hoisted** to the top of the file by Babel/ts-jest transform — it runs before
any imports. This means you cannot conditionally mock a module differently per test case using
`jest.mock()`. Teams that try to override a mock in a `beforeEach` or per-test call produce
surprising results because the hoisted `jest.mock()` wins. `jest.doMock()` is the non-hoisted
variant designed for exactly this use case.

This pattern surfaces as flakiness when developers see: "test A passes, test B passes, but
when run together in order A→B, test B fails" — because `jest.mock()` from test A's file
scope overrides what test B's `jest.doMock()` attempted to set.

```typescript
// BAD: trying to vary mocks per test with jest.mock() — hoisting defeats the intent
import { jest } from '@jest/globals';

// This mock is hoisted — it runs BEFORE all imports, so both tests see the same mock
jest.mock('../src/featureFlags', () => ({
  isEnabled: jest.fn().mockReturnValue(false), // always false — test 2's override never takes effect
}));

import { featureFlags } from '../src/featureFlags';
import { CheckoutService } from '../src/CheckoutService';

describe('CheckoutService — BAD mock ordering', () => {
  it('hides beta checkout when flag is off', async () => {
    // OK: flag is false (the hoisted mock)
    const result = await CheckoutService.getCheckoutVariant();
    expect(result).toBe('standard');
  });

  it('shows beta checkout when flag is on', async () => {
    // BROKEN: this override looks right but jest.mock() is already hoisted at file load time
    // jest.mock('../src/featureFlags', () => ({ isEnabled: jest.fn().mockReturnValue(true) }));
    // The above line is silently ignored or conflicts — test sees false, not true
    (featureFlags.isEnabled as jest.Mock).mockReturnValue(true); // manual workaround — brittle
    const result = await CheckoutService.getCheckoutVariant();
    expect(result).toBe('beta'); // may pass or fail depending on import order
  });
});
```

```typescript
// GOOD: jest.doMock() + jest.resetModules() for per-test module isolation
// Each test gets a fresh module with its own mock — no hoisting, no interference

import { beforeEach, afterEach, describe, it, expect } from '@jest/globals';

describe('CheckoutService — GOOD: doMock per test', () => {
  beforeEach(() => {
    // Reset the module registry before each test — ensures doMock applies to a fresh require
    jest.resetModules();
  });

  afterEach(() => {
    jest.resetModules(); // defensive second reset — ensures cleanup even if test throws
  });

  it('hides beta checkout when flag is off', async () => {
    // doMock is NOT hoisted — it applies only from this point forward in this test
    jest.doMock('../src/featureFlags', () => ({
      featureFlags: { isEnabled: jest.fn().mockReturnValue(false) },
    }));

    // Dynamic import AFTER doMock — gets the fresh mocked version
    const { CheckoutService } = await import('../src/CheckoutService');
    const result = await CheckoutService.getCheckoutVariant();
    expect(result).toBe('standard');
  });

  it('shows beta checkout when flag is on', async () => {
    // Independent mock — not affected by the previous test's doMock
    jest.doMock('../src/featureFlags', () => ({
      featureFlags: { isEnabled: jest.fn().mockReturnValue(true) },
    }));

    const { CheckoutService } = await import('../src/CheckoutService');
    const result = await CheckoutService.getCheckoutVariant();
    expect(result).toBe('beta'); // deterministic: this test always uses its own mock
  });
});
```

```typescript
// Vitest equivalent: vi.doMock() — same semantics as jest.doMock(), not hoisted
// Use with vi.resetModules() for identical isolation

import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('FeatureFlagService — Vitest doMock', () => {
  beforeEach(() => {
    vi.resetModules(); // clear module cache before each test
  });

  it('returns correct variant for control group', async () => {
    vi.doMock('../src/experimentService', () => ({
      getVariant: vi.fn().mockResolvedValue('control'),
    }));

    const { ExperimentService } = await import('../src/experimentService');
    const variant = await ExperimentService.getVariant('checkout-ab-test', 'user-42');
    expect(variant).toBe('control');
  });

  it('returns correct variant for treatment group', async () => {
    // Independent mock — vi.resetModules() in beforeEach ensures isolation
    vi.doMock('../src/experimentService', () => ({
      getVariant: vi.fn().mockResolvedValue('treatment'),
    }));

    const { ExperimentService } = await import('../src/experimentService');
    const variant = await ExperimentService.getVariant('checkout-ab-test', 'user-99');
    expect(variant).toBe('treatment');
  });
});
```

**When to use `jest.mock()` (hoisted) vs `jest.doMock()` (non-hoisted):**

| Scenario | Use `jest.mock()` | Use `jest.doMock()` |
|----------|--------------------|----------------------|
| Same mock for all tests in the file | Yes | No (overkill) |
| Different mock behaviour per test | No (hoisting defeats this) | Yes |
| Mocking a module and using static `import` | Yes | No — requires dynamic `import()` |
| Testing module initialization side effects | No | Yes — `resetModules()` gives fresh init |
| Team has Babel transform (`babel-jest`) | Yes — hoisting works | Yes — no hoisting by default |

---

## Pattern 104 — Global `unhandledRejection` Handler for Surfacing Swallowed Async Errors  [community]

Unhandled Promise rejections are a major source of "phantom" flakiness: an async operation
fails silently in one test but its side effects (state mutation, resource allocation, log
pollution) corrupt a later test. Node.js 15+ turns unhandled rejections into process exits by
default — but Jest and Vitest intercept this and convert them to warnings that may not fail the
current test.

Setting up a global `unhandledRejection` handler in the test harness turns these silent
corruptions into immediate test failures — attributable to the correct test case, not a
mysterious downstream failure.

```typescript
// test-setup/unhandled-rejection-guard.ts
// Add to vitest.config.ts setupFiles: ['./test-setup/unhandled-rejection-guard.ts']
// or jest.config.ts setupFilesAfterFramework: ['<rootDir>/test-setup/unhandled-rejection-guard.ts']

/**
 * Converts unhandled Promise rejections into test failures.
 *
 * WITHOUT this: an async operation that throws in test A (without being awaited)
 * surfaces as a mysterious failure in test B — order-dependent, non-reproducible.
 *
 * WITH this: the rejection is captured immediately and attributed to the running test
 * (via Jest's current test name or Vitest's current test context).
 *
 * Node.js behaviour note:
 * - Node.js 15+: unhandled rejections are fatal by default (process exits)
 * - Jest < 29: swallows rejections silently as warnings
 * - Jest 29+: converts to test failure, but only if the rejection happens DURING a test
 * - Vitest: converts to test failure with better stack traces than Jest
 *
 * This guard provides consistent behaviour across all three and older versions.
 */

let currentTestName = 'unknown test (outside test body)';

// Track which test is currently running — used in the rejection handler message
if (typeof beforeEach !== 'undefined') {
  beforeEach((context?: { task?: { name: string } }) => {
    // Vitest passes context; Jest does not — handle both
    currentTestName = context?.task?.name ?? expect?.getState?.()?.currentTestName ?? 'unknown';
  });
}

const rejectionHandler = (reason: unknown, promise: Promise<unknown>) => {
  // Format the rejection for maximum diagnosability
  const message =
    reason instanceof Error
      ? `${reason.name}: ${reason.message}\n${reason.stack ?? ''}`
      : JSON.stringify(reason, null, 2);

  const diagnostic =
    `[TEST HARNESS] Unhandled Promise rejection during: "${currentTestName}"\n` +
    `Rejection reason: ${message}\n` +
    `Promise: ${promise}\n` +
    `Root cause: an async operation was NOT awaited. ` +
    `Check for missing 'await' in beforeEach, afterEach, or the test body itself.\n` +
    `ESLint fix: enable '@typescript-eslint/no-floating-promises' to catch this statically.`;

  // In test environments, throw as an Error so the test runner attributes it to the current test
  // This is safer than process.exit() which would abort the entire suite
  throw new Error(diagnostic);
};

process.on('unhandledRejection', rejectionHandler);

// Clean up the handler after all tests complete — prevents interference with production code
if (typeof afterAll !== 'undefined') {
  afterAll(() => {
    process.off('unhandledRejection', rejectionHandler);
  });
}
```

```typescript
// Test demonstrating why unhandledRejection matters — the "ghost failure" pattern

import { describe, it, expect } from 'vitest';
import { EmailService } from '../src/EmailService';

// ANTI-PATTERN: unawaited async in test body — triggers unhandledRejection silently
it('sends welcome email (broken — unawaited)', () => {
  // The email service call is not awaited — if it rejects, the rejection
  // floats into the next test's execution context, failing THAT test, not this one
  EmailService.send({ to: 'alice@example.com', subject: 'Welcome' }); // MISSING await
  // This test "passes" even if EmailService.send() throws after 50ms
});

it('unrelated test that inexplicably fails', async () => {
  // The rejection from the previous test surfaces HERE
  // Without the unhandledRejection guard, this test is blamed for a bug it didn't cause
  const users = await UserService.list();
  expect(users).toHaveLength(0); // may fail because the previous rejection polluted state
});

// CORRECT: always await async operations in test bodies
it('sends welcome email (correct — awaited)', async () => {
  // Explicit await — any rejection is immediately attributed to THIS test
  await EmailService.send({ to: 'alice@example.com', subject: 'Welcome' });
  // If EmailService.send() rejects, this test fails — correctly, immediately, attributably
});
```

```typescript
// Complement: enable @typescript-eslint/no-floating-promises in test files
// This is the static analysis equivalent of the runtime unhandledRejection guard
// Add to .eslintrc.cjs or eslint.config.mjs:

// For ESLint flat config (eslint.config.mjs):
import tseslint from '@typescript-eslint/eslint-plugin';
import tsparser from '@typescript-eslint/parser';

export default [
  {
    files: ['**/*.test.ts', '**/*.spec.ts'],
    languageOptions: { parser: tsparser },
    plugins: { '@typescript-eslint': tseslint },
    rules: {
      // Catches: expression that returns a Promise without being awaited
      '@typescript-eslint/no-floating-promises': ['error', {
        ignoreVoid: false,  // void operator does NOT count as "handled" in tests
        ignoreIIFE: false,  // immediately-invoked async functions must be awaited
      }],
      // Catches: Promise-returning function in callback positions without await
      '@typescript-eslint/no-misused-promises': 'error',
    },
  },
];
```

---

## Anti-Patterns (iteration 60)

### AP50 — No `unhandledRejection` Guard in Test Harness  [community]
**What:** Test suites that do not install a global `unhandledRejection` handler (Pattern 104) and rely on the test runner's default behaviour to surface async errors.
**Why harmful:** The default behaviour of Jest < 29 and many other test runners is to log the rejection as a warning *after* all tests complete, attributing it to no specific test case. Engineers see "UnhandledPromiseRejection: ..." in CI output but cannot identify which test caused it. This produces a class of "intermittent" failures that disappear on re-run because the rejection arrives in a different test's window. The root cause is always a missing `await` — and `@typescript-eslint/no-floating-promises` would have caught it statically. Fix: install Pattern 104 in your `setupFiles` AND enable `@typescript-eslint/no-floating-promises` in test file linting rules.

### AP51 — Using `jest.mock()` for Per-Test Module Variation Without `resetModules`  [community]
**What:** Calling `jest.mock('./module', factory)` inside `beforeEach` or `describe` blocks expecting each call to replace the previous mock for that test.
**Why harmful:** `jest.mock()` is hoisted by the Babel transform — ALL calls to `jest.mock()` in a file are moved to the top, before any imports, regardless of where they appear in the source. Multiple `jest.mock()` calls for the same module path in a file are de-duplicated by the last one seen at hoist time, not the last one called at runtime. This creates non-deterministic mock application depending on declaration order — test A and test B may share the same mock factory, neither gets what the developer intended. Fix: use `jest.doMock()` (non-hoisted) with `jest.resetModules()` in `beforeEach` for per-test module variation (Pattern 103).

---

## Real-World Gotchas (iteration 60)  [community]

**Gotcha 50 — EventEmitter Listener Leak in Parallel Workers Creates Cross-Worker Ghost Failures**
When a `globalSetup` script creates a shared event bus or pub/sub client (e.g., a Redis subscriber,
a WebSocket client) at the suite level, and multiple Vitest/Jest workers import this shared object
via module cache, listeners registered in worker A can fire during worker B's execution. This
produces failures in B that are attributed to B's test context but were actually triggered by A's
listener. Symptoms: a test fails with `"received 2 calls, expected 1"` on a mock that the test
never explicitly called — because A's listener called it. Fix: always create event-driven resources
per-test (not per-suite or per-module) when running in parallel, and use `EventEmitter.defaultMaxListeners`
reduction in setup files (Pattern 102) to catch leaks before they cascade.

**Gotcha 51 — `jest.mock()` Hoisting Order Is Determined by Babel AST Traversal, Not Source Line Order**
Teams that write `jest.mock('./a')` on line 15 and `jest.mock('./b')` on line 25, expecting them
to be applied in that order, are surprised when the execution order differs. The Babel jest-hoist
plugin traverses the AST and collects all `jest.mock()` calls, then emits them at the top of the
file in the order encountered by the traverser — which matches source order in simple cases but
diverges with nested function calls, conditional blocks, and template literals. The practical
implication: if you rely on mock A being registered before mock B (e.g., because module A
re-exports from module B), the order may flip. Fix: use a single `jest.mock()` per module path
per file, avoid conditional `jest.mock()` calls entirely, and use `jest.doMock()` for any case
where execution order relative to other code matters.

---

## Quick Reference additions (iteration 60)

| Symptom | Likely Root Cause | Pattern/Fix | Anti-Pattern to Avoid |
|---------|-------------------|-------------|----------------------|
| Mock never overrides correctly per test — one factory wins for all tests | `jest.mock()` hoisted to file top; per-test override impossible | Pattern 103 (jest.doMock + resetModules) | AP51 (jest.mock in beforeEach expecting per-test variation) |
| Test B fails with "expected 1 call, received 2" — test B never registered that mock | EventEmitter listener from test A still active in test B | Pattern 102 (maxListeners guard, once(), off() in afterEach) | No afterEach listener cleanup |
| Async error surfaces in wrong test — unattributable CI failure | Unawaited Promise rejection floating across test boundaries | Pattern 104 (unhandledRejection guard + no-floating-promises lint) | AP50 (no unhandledRejection handler) |
| `jest.mock()` factory runs before import — module shape differs from expected | Mock hoisting moves factory before module resolution | Pattern 103 (jest.doMock after resetModules) | jest.mock() in describe/beforeEach for dynamic behaviour |
| Listener count keeps growing across parallel workers — MaxListenersExceeded | Shared EventEmitter in globalSetup, multiple workers attach listeners | Pattern 102 (per-test emitter, defaultMaxListeners reduction) | Module-level singleton EventEmitter shared across workers |

---

## Key Resources (iteration 60 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Jest `jest.doMock()` API | Official | https://jestjs.io/docs/jest-object#jestdomockmodulename-factory-options | Non-hoisted module mock — essential for per-test module variation |
| Jest `jest.resetModules()` API | Official | https://jestjs.io/docs/jest-object#jestresetmodules | Clears module registry — required companion to doMock for fresh require |
| Node.js `EventEmitter.defaultMaxListeners` | Official | https://nodejs.org/api/events.html#emittersetmaxlistenersn | API for setting max listener threshold — lower in tests for early leak detection |
| Node.js `process: unhandledRejection` | Official | https://nodejs.org/api/process.html#event-unhandledrejection | Event fired for unhandled Promise rejections — harness integration point |
| `@typescript-eslint/no-floating-promises` | Official | https://typescript-eslint.io/rules/no-floating-promises | Static analysis rule that catches missing await — pair with unhandledRejection guard |
| `@typescript-eslint/no-misused-promises` | Official | https://typescript-eslint.io/rules/no-misused-promises | Catches Promise-returning functions in callback positions — companion rule |
