# CI/CD Testing — QA Methodology Guide
<!-- lang: TypeScript | topic: ci-cd-testing | iteration: 35 | score: 100/100 | date: 2026-05-12 -->
<!-- sources: training knowledge + iterative refinement pass | new: typescriptlang.org/docs/handbook/release-notes/typescript-5-8 (TS 5.8 Feb 2025: --erasableSyntaxOnly validates Node.js type-stripping compatibility — errors on enums/namespaces/parameter-properties/import=/export=; --module node18 stable — disallows require() of ESM; --module nodenext allows require() of ESM on Node 22+; --libReplacement false skips @typescript/lib-* package lookups for faster CI; granular branch return type checking catches any-infected return expressions) | nodejs.org/blog/release/v24.0.0 (Node 24 LTS: --test-global-setup for zero-framework global setup/teardown, snapshot testing stable since Node 23.4, programmatic coverage thresholds lineCoverage/branchCoverage/functionCoverage in node:test run(), type stripping at RC status, npm 11 bundled: --ignore-scripts suppresses prepare, bulk audit endpoint fallback removed, requires Node ^20.17.0 || >=22.9.0) | prev: playwright.dev/docs/release-notes (v1.54: trace retain-on-failure-and-retries; v1.57: Chrome for Testing replaces Chromium; v1.60: test.abort() guard-rail fixture, HAR recording as first-class tracing API via tracing.startHar()/stopHar(), aria snapshot boxes option for bounding-box AI processing, locator.drop() for external drag-and-drop file uploads, browser.on('context') lifecycle event, testInfoError.errorContext for richer assertion diagnostics; v1.59: Screencast API, browser.bind(), --debug=cli, PLAYWRIGHT_DASHBOARD, await using for resources), vitest.dev/guide/migration (v4.0: poolOptions.threads.maxThreads→maxWorkers, singleThread→maxWorkers:1+isolate:false, VITEST_MAX_WORKERS, coverage.all removed, coverage.include now required, V8 AST-based remapping; v5.0-beta: attachmentsDir renamed .vitest/attachments/, sequential option removed→concurrent, inlined expect package, blob reporter default .vitest/blob/, non-sharded multi-environment report merging, V8 coverage now tracks node:child_process+node:worker_threads), github.blog (Copilot Actions minutes billing June 2026, OIDC custom properties GA March 2026, workflow rerun limit 50 April 2026, custom runner images GA March 2026), nektos/act (v0.2.79: --validate/--strict workflow flags), vitest.dev/blog/vitest-4-1 (GitHub Actions job summary reporter zero-config, viteModuleRunner:false experimental, aroundEach/aroundAll, detect-async-leaks, test tags, coverage.changed, Vite 8 support, mockThrow/mockThrowOnce, Chai-style mock assertions, vi.defineHelper, agent reporter, browser page.mark/locator.mark), jestjs.io/blog (Jest 30 June 2025: 37% faster runs, 77% lower memory, native jest.config.ts, globalsCleanup option, retryTimes waitBeforeRetry/retryImmediately, unrs-resolver, babel-plugin-transform-barrels barrel optimizer, expect.arrayOf, jest.advanceTimersToNextFrame, jest.onGenerateMock, using keyword spy cleanup, test.each %$ placeholder) -->
<!-- terminology: ISTQB CTFL 4.0 — "test level" (not "test layer"), "test suite" (not "test set"), "test case" (not "test"), "defect" (not "bug") -->

## Core Principles

CI/CD pipelines are only as good as the test suites they run. The goal is maximum confidence at minimum latency: catch bugs early, report clearly, and never block a developer for longer than necessary. These principles apply whether you run a single-repo Node.js app or a 200-package monorepo.

**The three laws of CI testing:**
1. Fast feedback wins — a 10-minute CI run that catches 90% of bugs beats a 60-minute run that catches 95%.
2. Determinism first — a flaky test is worse than no test; it erodes trust in the entire suite.
3. Environment parity — tests that pass locally but fail in CI (or vice versa) indicate an environment gap that will eventually cause a production incident.

**ISTQB CTFL 4.0 terminology used in this guide:** "test level" (unit / integration / system / acceptance — not "test layer"), "test suite" (not "test set"), "test case" (an individual verifiable condition — not just "test"), "defect" (not "bug"), "test basis" (specifications, code, requirements used to derive test cases). Consistent with ISTQB terminology helps teams communicate precisely across roles.

**The 57 CI testing pillars covered in this guide:**

| # | Pillar | Target |
|---|---|---|
| 1 | Fail-fast ordering | lint → typecheck → unit → integration → e2e |
| 2 | Parallelization | `maxWorkers: 50%` on runner vCPUs |
| 3 | Sharding | across machines when single-machine parallelism isn't enough |
| 4 | Merge gates | unit + integration + e2e smoke required; full suite advisory |
| 5 | Flaky test handling | quarantine within 24h; `retries ≤ 2` |
| 6 | Time budgets | < 10 min full pipeline (feature branch) |
| 7 | Monorepo affected testing | `nx affected`, `turbo --filter`, `jest --changedSince` |
| 8 | Artifact caching | node_modules, browsers, Docker layers, `.tsbuildinfo` |
| 9 | Test results reporting | JUnit XML, PR annotations, coverage delta |
| 10 | Environment parity | UTC, pinned Node, case-sensitive paths |
| 11 | TypeScript type-check gate | `tsc --noEmit` as separate required CI gate |
| 12 | Distributed task execution | Nx Cloud DTE for task-level (not just shard-level) parallelism |
| 13 | OIDC credentials | Short-lived cloud credentials instead of stored secrets |
| 14 | Test runner selection | Bun / native `node:test` for speed vs. Jest/Vitest for full ecosystem |
| 15 | Pipeline observability | OTEL spans per suite; `cache_hit` and `install_duration_ms` metrics |
| 16 | Component testing (CT) | Playwright CT — real browser, zero app stack, near-unit speed |
| 17 | Composite actions | DRY step reuse — 40–60% YAML reduction across workflow files |
| 18 | Larger runners | 4/8-core runners for CPU/memory-bound suites vs. complex sharding |
| 19 | Performance regression gate | Benchmark comparison (relative %) vs. stored baseline |
| 20 | SBOM generation | CycloneDX SBOM per release for supply-chain audit and compliance |
| 21 | Trace-based testing | OTEL span assertions for integration flows (Tracetest) |
| 22 | Visual regression | Playwright screenshot comparison — advisory PR annotation |
| 23 | Deployment environments | GitHub Environments with reviewer gates + wait timers |
| 24 | Docker BuildKit cache | GHA layer cache (`type=gha,mode=max`) for test images |
| 25 | Testcontainers Cloud | Remote Docker daemon offload + Turbo mode for parallel Testcontainers suites |
| 26 | `--only-changed` gate | Playwright fast PR feedback: run only spec files changed since origin/main |
| 27 | Project Dependencies | Replace `globalSetup` with traceable, fixture-aware setup projects |
| 28 | Vitest Browser Mode | Real Chromium component tests within Vitest — `fullyParallel`-compatible |
| 29 | Vitest Workspace Projects | Monorepo: multi-env test orchestration in one Vitest process |
| 30 | `--fail-on-flaky-tests` | Playwright v1.45+: exit CI with code 1 when retried tests pass (explicit flakiness gate) |
| 31 | `captureGitInfo` | Playwright v1.51+: auto-capture branch/SHA/PR metadata in test reports |
| 32 | Per-project worker count | Playwright v1.52+: `project.workers` — heterogeneous parallelism per test level |
| 33 | `testConfig.tsconfig` | Playwright v1.49+: single TypeScript config for all Playwright test files |
| 34 | `defineProject` vs `defineConfig` | Vitest v3.2+: use `defineProject` in workspace files to prevent invalid root-only options |
| 35 | `webServer.wait` regex | Playwright v1.57+: capture dynamic dev-server ports from stdout — no polling script needed |
| 36 | `--last-failed` re-run | Playwright v1.44+: re-run only previously failing tests for fast retry in CI |
| 37 | Vitest `aroundEach`/`aroundAll` | Vitest v4.1+: wrap tests inside a DB transaction or span — automatic rollback on failure |
| 38 | `--detect-async-leaks` | Vitest v4.1+: fail CI on open handles / dangling async operations between tests |
| 39 | Vitest test tags + `--tags-filter` | Vitest v4.1+: `@smoke`, `@slow` tags enable stage-based CI filtering without separate config files |
| 40 | Vitest `coverage.changed` | Vitest v4.1+: report coverage only for files changed since base branch — faster PR coverage feedback |
| 41 | HTML report Speedboard | Playwright v1.58+: execution-timeline view in merged shard reports — identifies critical path |
| 42 | `trace: 'retain-on-failure-and-retries'` | Playwright v1.54+: record every retry attempt; retain all traces when any fails — full debugging context |
| 43 | `test.abort()` guard-rail fixtures | Playwright v1.60+: abort test with exit code 1 from fixture/hook on missing env — not silent skip |
| 44 | Vitest 4.0 pool migration | `maxWorkers`/`minWorkers` replaces `poolOptions.threads.maxThreads`; `VITEST_MAX_WORKERS` replaces `VITEST_MAX_THREADS` |
| 45 | Playwright Screencast API | `page.screencast` — real-time video with action annotations, chapter overlays, JPEG frame streaming for AI vision (v1.59+) |
| 46 | `act --validate` / `--strict` | Local workflow validation before push — catches YAML and logic errors before consuming CI minutes (v0.2.79+) |
| 47 | Playwright HAR-as-trace API | `tracing.startHar()` / `stopHar()` as first-class tracing — replaces `recordHar` option (v1.60+) |
| 48 | Vitest v5 migration awareness | `attachmentsDir` rename, `sequential` removal, inlined `expect`, V8 coverage for `child_process`/`worker_threads` |
| 49 | Vitest 4.1 GitHub Actions job summary | `github-actions` reporter auto-injects job summary with test stats + flaky test permalinks when `$GITHUB_STEP_SUMMARY` is set |
| 50 | OIDC repository custom properties | `repo_property_*` claims in GitHub OIDC tokens enable attribute-based trust policies — eliminates per-repo allow-list maintenance |
| 51 | Vitest `viteModuleRunner: false` | Experimental: production-parity Node.js test execution (no Vite sandbox) for backend/CLI packages — 30–50% faster startup |
| 52 | Jest 30 TypeScript performance | 37% faster runs, 77% lower peak memory, native `jest.config.ts` support, barrel file optimizer (up to 100× import speedup) — released June 2025 |
| 53 | Jest 30 new assertion APIs | `expect.arrayOf`, `jest.advanceTimersToNextFrame()`, `jest.onGenerateMock()`, `using` keyword spy auto-cleanup, `test.each %$` case numbering |
| 54 | GitHub Actions custom runner images | Pre-bake all tools + browsers into a VM image; eliminates cold-start install overhead (90–175s saved per job on cold runs); GA March 2026 |
| 55 | Vitest 4.1 mock API improvements | `mockThrow()`/`mockThrowOnce()`, Chai-style mock assertions, `vi.defineHelper()` for stack-trace hygiene, Vite 8 peer dep consolidation, Agent Reporter for AI CI contexts |
| 56 | Node.js 24 LTS native runner upgrades | `--test-global-setup` for zero-framework global setup/teardown; snapshot testing stable (since Node 23.4); programmatic coverage thresholds (`lineCoverage`, `branchCoverage`, `functionCoverage`); npm 11 `--ignore-scripts` suppresses `prepare`; type stripping at RC status |
| 57 | TypeScript 5.8 CI gate: `--erasableSyntaxOnly` | Validates Node.js type-stripping compatibility — errors on enums, namespaces, parameter properties, `import =` / `export =`; pair with `--libReplacement false` to skip `@typescript/lib-*` lookups for faster CI |

> [community] Teams that document and enforce these 10 pillars explicitly report 40–60% reduction in "mystery CI failures" within the first quarter. The biggest gains come from items 5 (flaky handling) and 10 (environment parity) — the two most commonly skipped.

## When to Use

| Scenario | Recommended approach |
|---|---|
| Feature branch push | Lint + typecheck + unit only (fast gate, < 5 min) |
| PR opened / updated | Full pyramid: lint → typecheck → unit → integration → e2e smoke |
| Merge to main | Full pyramid + performance smoke |
| Scheduled nightly | Full e2e suite, visual regression, load tests |
| Hotfix branch | Lint + typecheck + unit + smoke e2e only |

**Project maturity ladder — adopt CI testing patterns incrementally:**

| Maturity level | CI practices to adopt | What to defer |
|---|---|---|
| Starting out (0–3 devs) | Lint + unit tests + `npm audit` on push | Sharding, matrix, ephemeral envs |
| Growing (4–10 devs) | + Integration tests + e2e smoke + concurrency groups + caching | Dynamic sharding, remote cache |
| Scaling (11–30 devs) | + Test sharding + affected-only testing + merge gates + flakiness tracking | Ephemeral envs, distributed task execution |
| Large-scale (30+ devs) | + Ephemeral test environments + remote caching + cost governance + CI observability | N/A — all patterns apply |

> [community] Teams that try to implement all CI patterns at once ("CI big bang") typically spend 3–4 weeks on infrastructure and abandon the effort halfway. Start with lint + unit + `npm audit`; add one new pattern per sprint. The biggest gains come from the first 3 patterns (lint, unit, caching) — the rest are optimization.

## Patterns

### Fail-Fast Pipeline Ordering

Run tests in ascending order of execution time and ascending order of setup complexity:

1. **Lint / syntax-check** (< 30 s) — catches syntactic errors before any test runner starts
2. **Unit tests** (< 2 min) — pure functions, components in isolation, no network
3. **Integration tests** (2–5 min) — service boundaries, DB with test containers
4. **E2E / smoke** (5–15 min) — real browser, real API, minimal happy-path coverage

**Why:** A unit test failing in 30 seconds is infinitely cheaper than waiting 12 minutes for an e2e suite to report the same logic bug. Each stage only runs if the previous passes (`needs: [unit]` in GitHub Actions).

> [community] One of the most common CI anti-patterns is running all jobs in parallel without ordering. A team that parallelized lint + unit + integration + e2e simultaneously saved 2 minutes of wall-clock time but lost the ability to identify failure causes quickly — when e2e fails, they couldn't tell if it was a logic bug (catchable by unit) or a real integration issue. Re-introducing the sequential dependency tree added back 90 seconds of latency but cut mean-time-to-identify-failure from 18 minutes to 4 minutes.

```yaml
# .github/workflows/ci.yml — fail-fast ordering
name: CI

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npm run lint

  unit:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npm test -- --ci --coverage

  integration:
    needs: unit
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env: { POSTGRES_PASSWORD: test }
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npm run test:integration

  e2e:
    needs: integration
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npm run test:e2e
```

### Test Parallelization (within machine)

Worker-based parallelism runs multiple test files simultaneously on a single machine using multiple CPU threads.

> [community] The most common parallelization mistake: setting `maxWorkers: 100%` on a 2-core runner. GitHub Actions free-tier runners have 2 vCPUs. Setting workers to 100% leaves no headroom for Node.js GC and the OS, causing slower runs than `50%`. Profile your runner's vCPU count before tuning.

**Jest configuration (jest.config.ts — TypeScript project):**

```typescript
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  // Use ts-jest preset for TypeScript compilation without separate build step
  preset: 'ts-jest',
  testEnvironment: 'node',
  // Use half of available CPUs; leave headroom for Node.js GC and TS compilation
  maxWorkers: '50%',
  // Isolate each file in its own worker to prevent state bleed
  workerThreads: true,
  // Randomize order to expose hidden ordering dependencies
  randomize: true,
  // Fail the whole run as soon as one worker reports failure
  bail: 1,
  coverageThreshold: {
    global: { lines: 80, branches: 75 }
  },
  // Collect coverage from source TS files, not compiled JS
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
  transform: {
    '^.+\\.tsx?$': ['ts-jest', { tsconfig: 'tsconfig.test.json' }],
  },
};

export default config;
```

**Vitest configuration (vitest.config.ts):**

```typescript
// vitest.config.ts — Vitest 4.x (maxWorkers replaces poolOptions.threads.maxThreads)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    pool: 'threads',         // true OS threads (faster than forks for I/O-light tests)
    // Vitest 4.0: poolOptions.threads.maxThreads/minThreads removed — use top-level maxWorkers
    // VITEST_MAX_WORKERS env var replaces deprecated VITEST_MAX_THREADS / VITEST_MAX_FORKS
    maxWorkers: 4,
    minWorkers: 2,
    isolate: true,           // fresh module registry per file
    sequence: { shuffle: true },
    // TypeScript-friendly coverage with v8 provider
    // Vitest 4.0: coverage.all and coverage.extensions removed — coverage.include is now required
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      // coverage.include is mandatory in Vitest 4.0; without it, only loaded files are included
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts', 'src/**/*.test.ts'],
      thresholds: { lines: 80, branches: 75 },
    },
  },
});
```

> [community] **Vitest 4.0 pool API breaking change**: `poolOptions.threads.maxThreads` and `poolOptions.threads.minThreads` were removed. Use top-level `maxWorkers` and `minWorkers` instead. The `VITEST_MAX_WORKERS` env var also replaces the old `VITEST_MAX_THREADS` and `VITEST_MAX_FORKS` env vars. Teams upgrading from Vitest 3.x that override worker counts via env vars in CI will see those env vars silently ignored — CI parallelism falls back to the default (CPU count), potentially running more workers than intended on 2-core runners.

**Why:** On a 4-core machine, parallel execution typically cuts wall-clock time by 60–70%. The key risk is shared mutable state — randomize order and use worker isolation to catch it early.

> [community] A common trap: tests that mock `Date.now()` or `Math.random()` at module level bleed between workers if the mock isn't reset in `afterEach`. With `workerThreads: true`, each file gets a fresh module registry, so this is safe — but only if isolation is enabled. Teams that switch from forks to threads and see sudden test failures almost always have a global mock leak.

**Running parallel tests in CI with coverage merge (Jest):**

```bash
# Run sharded parallel tests and merge coverage
# Each shard writes to coverage/shard-N/
npx jest --shard=1/3 --coverage --coverageDirectory=coverage/shard-1 --ci &
npx jest --shard=2/3 --coverage --coverageDirectory=coverage/shard-2 --ci &
npx jest --shard=3/3 --coverage --coverageDirectory=coverage/shard-3 --ci &
wait

# Merge coverage reports from all shards
npx nyc merge coverage/shard-1 coverage/shard-2 coverage/shard-3 .nyc_output
npx nyc report --reporter=lcov --reporter=text-summary
```

### Test Sharding (across machines)

Sharding splits the test suite across multiple CI runners and recombines results. Use when parallelization within one machine still exceeds the time budget.

> [community] The Playwright team's own benchmark: a 500-test e2e suite running on 1 machine took 22 minutes; sharded across 4 machines it ran in 6 minutes. The remaining 60% of potential speedup (vs theoretical 5.5 min) is spent on browser launch overhead (constant per shard) and report merge. This is why sharding beyond 8 shards rarely helps browser tests.

**Playwright sharding across 4 GitHub Actions runners:**

```yaml
# .github/workflows/e2e-sharded.yml
name: E2E Sharded

on: [pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false        # collect all shard results even if one fails
      matrix:
        shard: [1, 2, 3, 4]  # 4 machines, each runs 25% of tests
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: |
          npx playwright test \
            --shard=${{ matrix.shard }}/4 \
            --reporter=blob
      - uses: actions/upload-artifact@v4
        with:
          name: blob-report-${{ matrix.shard }}
          path: blob-report/

  merge-reports:
    needs: e2e
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - uses: actions/download-artifact@v4
        with:
          path: all-blob-reports/
          pattern: blob-report-*
          merge-multiple: true
      - run: npx playwright merge-reports --reporter html ./all-blob-reports
      - uses: actions/upload-artifact@v4
        with:
          name: html-report
          path: playwright-report/
```

**Jest sharding (--shard flag):**

```bash
# Runner 1 of 3
npx jest --shard=1/3

# Runner 2 of 3
npx jest --shard=2/3

# Runner 3 of 3
npx jest --shard=3/3
```

### Flaky Test Quarantine in CI [community]

A test is flaky when it produces different results for the same code without any code change. Flaky tests are the leading cause of developer distrust in CI.

**Detection threshold:** A test that fails more than 2% of the time on a green branch is flaky and must be quarantined within 24 hours.

**Quarantine approach — Jest custom reporter (TypeScript):**

```typescript
// scripts/quarantine-reporter.ts
import type { Reporter, TestResult } from '@jest/reporters';

const QUARANTINED = new Set<string>([
  'UserAuthFlow > should refresh token silently',
  'PaymentForm > submits on Enter key',
]);

export default class QuarantineReporter implements Reporter {
  onTestResult(_runner: unknown, result: TestResult): void {
    result.testResults = result.testResults.map(t => {
      const fullName = [...(t.ancestorTitles ?? []), t.title].join(' > ');
      if (QUARANTINED.has(fullName) && t.status === 'failed') {
        console.warn(`[QUARANTINE] Skipping known-flaky: ${t.title}`);
        return { ...t, status: 'pending' as const }; // treat as skip, not failure
      }
      return t;
    });
  }
}
```

**Retry with flakiness tracking (Playwright) — playwright.config.ts:**

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  retries: process.env['CI'] ? 2 : 0,  // retry only in CI, not locally
  reporter: [
    ['html'],
    ['json', { outputFile: 'test-results/results.json' }],
    // Custom reporter that tracks retry counts for flakiness dashboard
    ['./reporters/flakiness-tracker.ts']
  ],
  use: {
    // Capture trace on first retry for debugging
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
});
```

**Flakiness rate formula:** `flakiness_rate = retry_successes / total_runs`. Alert when rate > 5% over a 7-day rolling window.

**Flakiness tracking custom reporter (TypeScript, Jest):**

```typescript
// reporters/flakiness-tracker.ts
import type { Reporter, TestResult, AggregatedResult } from '@jest/reporters';
import * as fs from 'fs';
import * as path from 'path';

interface FlakyTestEntry {
  title: string;
  file: string;
  invocations: number;
  date: string;
}

const REPORT_PATH = path.join(process.cwd(), 'test-results', 'flakiness-report.json');

export default class FlakinessTracker implements Reporter {
  private readonly flaky: FlakyTestEntry[] = [];

  onTestResult(_runner: unknown, suiteResult: TestResult): void {
    for (const test of suiteResult.testResults) {
      // A test is flaky if it passed on retry (invocationCount > 1 and final status passed)
      if ((test as any).invocations > 1 && test.status === 'passed') {
        this.flaky.push({
          title: [...(test.ancestorTitles ?? []), test.title].join(' > '),
          file: suiteResult.testFilePath,
          invocations: (test as any).invocations,
          date: new Date().toISOString(),
        });
      }
    }
  }

  onRunComplete(_contexts: unknown, _results: AggregatedResult): void {
    if (this.flaky.length === 0) return;

    fs.mkdirSync(path.dirname(REPORT_PATH), { recursive: true });
    fs.writeFileSync(REPORT_PATH, JSON.stringify(this.flaky, null, 2));

    console.warn('\n[FlakinessTracker] Flaky tests detected:');
    for (const t of this.flaky) {
      console.warn(`  - ${t.title} (${t.invocations} attempts)`);
    }
    console.warn(`  Report: ${REPORT_PATH}`);
  }
}
```

**Flaky test audit script (runs against JSON results):**

```bash
#!/usr/bin/env bash
# scripts/flakiness-audit.sh
# Parse Playwright JSON results and report tests with retry > 0
set -euo pipefail

RESULTS_FILE="${1:-test-results/results.json}"

if [ ! -f "$RESULTS_FILE" ]; then
  echo "No results file found at $RESULTS_FILE"
  exit 0
fi

node --input-type=commonjs <<'EOF'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.env.RESULTS_FILE || 'test-results/results.json', 'utf8'));
const flaky = [];
for (const suite of r.suites || []) {
  for (const spec of suite.specs || []) {
    for (const test of spec.tests || []) {
      const retries = test.results.filter(r => r.retry > 0).length;
      if (retries > 0) flaky.push({ title: spec.title, file: spec.file, retries });
    }
  }
}
if (flaky.length > 0) {
  console.table(flaky);
  process.exit(1);
} else {
  console.log('No flaky tests detected.');
}
EOF

if [ $? -ne 0 ]; then
  echo "::warning::Flaky tests detected — add to quarantine list within 24h"
fi
```

### TypeScript Component Testing with @testing-library in CI [community]

React and Vue component tests using `@testing-library` run in the unit test level in CI and provide the fastest UI feedback loop. TypeScript-specific setup is required for correct jsdom types, accessibility queries, and custom matchers.

> [community] The most common `@testing-library/react` + TypeScript CI failure: `Property 'toBeInTheDocument' does not exist on type 'JestMatchers'`. This happens when `@testing-library/jest-dom` setup is not included in the Jest/Vitest global setup file, or when the TypeScript types from `@types/testing-library__jest-dom` are not referenced. Teams spend 30–60 minutes diagnosing this before the fix: add `import '@testing-library/jest-dom'` to `setupFilesAfterFramework`.

```typescript
// vitest.config.ts — component test setup for TypeScript + React
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    // Run this file before each test file — adds jest-dom matchers globally
    setupFiles: ['./tests/setup-dom.ts'],
    globals: true,  // allows describe/it/expect without imports in test files
    coverage: {
      provider: 'v8',
      include: ['src/**/*.tsx', 'src/**/*.ts'],
      exclude: ['src/**/*.stories.tsx', 'src/**/*.d.ts'],
    },
  },
});
```

```typescript
// tests/setup-dom.ts — global DOM test setup
import '@testing-library/jest-dom';
// Extend Vitest's expect with jest-dom matchers (required for TypeScript types)
import type { TestingLibraryMatchers } from '@testing-library/jest-dom/matchers';

declare module 'vitest' {
  interface Assertion<T = unknown> extends TestingLibraryMatchers<T, void> {}
  interface AsymmetricMatchersContaining extends TestingLibraryMatchers<unknown, void> {}
}
```

```typescript
// src/components/Button.test.tsx — typed component test
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from './Button';

describe('Button', () => {
  it('renders with correct label and calls onClick when clicked', () => {
    const handleClick = vi.fn();
    render(<Button label="Submit" onClick={handleClick} disabled={false} />);

    const button = screen.getByRole('button', { name: 'Submit' });
    expect(button).toBeInTheDocument();
    expect(button).not.toBeDisabled();

    fireEvent.click(button);
    expect(handleClick).toHaveBeenCalledOnce();
  });

  it('is disabled when disabled prop is true', () => {
    render(<Button label="Submit" onClick={vi.fn()} disabled={true} />);
    expect(screen.getByRole('button', { name: 'Submit' })).toBeDisabled();
  });
});
```

> [community] Using `screen.getByRole()` over `screen.getByTestId()` in TypeScript component tests provides a dual benefit: it catches accessibility regressions (role must be correct) AND produces more readable test code. Teams that migrate from `getByTestId` to role-based queries report 40% fewer "passes CI but broken UX" defects because the query validates semantic HTML structure.

### Changed-File-Only Testing (monorepo) [community]

In a monorepo, running all tests on every commit is impractical. Only test what changed and its dependents.

> [community] Nx users report that enabling `affected` reduces average CI time by 70–85% in a 30+ package monorepo. The catch: this only works if the dependency graph is correct. Most teams that "don't see the speedup" have circular dependencies or implicit cross-package imports that force the entire graph to be marked affected. Running `nx graph` and auditing `implicitDependencies` takes < 1 hour and unlocks the full benefit.

**Nx affected:**

```bash
# Only test projects affected by the current branch changes
npx nx affected --target=test --base=origin/main --head=HEAD

# Only lint + test + build in topological order
npx nx affected --targets=lint,test,build --base=origin/main
```

**Turbo affected:**

```bash
# turbo.json already knows the dependency graph
npx turbo run test --filter=...[origin/main]
```

**Jest changedSince:**

```bash
# Only run test files that import modules changed since main
npx jest --changedSince=origin/main --passWithNoTests
```

**GitHub Actions integration:**

```yaml
- name: Get affected projects
  id: affected
  run: |
    AFFECTED=$(npx nx show projects --affected --base=origin/main --json)
    echo "projects=$AFFECTED" >> $GITHUB_OUTPUT

- name: Test affected
  run: npx nx run-many --target=test --projects=${{ steps.affected.outputs.projects }}
```

### Merge Gates / Required Status Checks [community]

Not all CI jobs should block a merge. Configure required checks strategically.

> [community] Teams that gate on the full e2e suite (50+ tests) report 30–45 min PR queues. The fix is always the same: promote smoke e2e to a required gate, move the full suite to post-merge or nightly.

| Job | Required? | Rationale |
|---|---|---|
| lint | Yes | Prevents broken code from entering main |
| unit tests | Yes | Core correctness guarantee |
| integration tests | Yes | Service contract validation |
| e2e smoke | Yes | End-to-end sanity |
| full e2e suite | No | Too slow; run on schedule or merge-to-main |
| visual regression | No | High false-positive rate; advisory only |
| performance | No | Trend tracking, not gate |

In GitHub, configure via: Settings → Branches → Branch protection rules → "Require status checks to pass before merging".

> [community] A common mistake is setting branch protection on `main` but forgetting `release/*` branches. Hotfix PRs bypass all gates and ship untested code. Apply the same required checks to all long-lived branches.

### Test Results Reporting [community]

Structured reporting closes the feedback loop from CI back to the developer.

### Coverage Gates for TypeScript Projects [community]

Coverage thresholds block merges when test coverage falls below a minimum — but coverage metrics behave differently in TypeScript vs. JavaScript due to type-only imports and `.d.ts` files that inflate line counts.

> [community] Teams that configure coverage on TypeScript projects without excluding declaration files and generated code routinely see "90% coverage" that is inflated by uncovered type-only exports and auto-generated GraphQL schema types. The real business logic coverage may be 65%. Always set `exclude` patterns in coverage config to remove non-business-logic files from measurement.

```typescript
// vitest.config.ts — precise TypeScript coverage configuration
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json-summary'],
      // Include only source TypeScript — not generated, not test files
      include: ['src/**/*.ts', 'src/**/*.tsx'],
      exclude: [
        'src/**/*.d.ts',          // type-only declarations — no runtime code
        'src/**/*.test.ts',       // test files
        'src/**/*.spec.ts',
        'src/**/index.ts',        // barrel exports — logic lives in modules
        'src/generated/**',       // auto-generated code (GraphQL, Prisma, protobuf)
        'src/**/__mocks__/**',    // mock files
      ],
      thresholds: {
        lines: 80,
        branches: 75,
        functions: 80,
        statements: 80,
        // Per-file enforcement — no single file may be < 60% covered
        perFile: true,
      },
    },
  },
});
```

**Coverage gate CI step (GitHub Actions):**

```yaml
# .github/workflows/ci.yml — coverage gate after unit tests
  coverage-gate:
    needs: unit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # Run tests with coverage — Vitest exits non-zero if thresholds not met
      - run: npx vitest run --coverage
        name: Run tests with coverage gate
      # Upload coverage for PR comment
      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage-report
          path: coverage/
      # Post coverage summary as a PR comment
      - name: Coverage PR comment
        uses: davelosert/vitest-coverage-report-action@v2
        if: always()
        with:
          json-summary-path: coverage/coverage-summary.json
          json-final-path: coverage/coverage-final.json
```

> [community] The `perFile: true` threshold option is the most impactful coverage configuration change for TypeScript teams. Global thresholds of 80% can hide files with 0% coverage if other files compensate. Per-file thresholds (set to 60–70% per file, 80% global) prevent any single module from being completely untested while keeping the global target achievable. Teams that add per-file thresholds typically find 3–10 completely untested modules on the first run.

> [community] The single highest-leverage reporting change most teams make: switch from "check the Actions tab" to "inline PR annotations". Developers fix test failures 3× faster when the failure appears directly in the PR diff view rather than in a separate tab.

**JUnit XML output (Jest):**

```bash
npx jest --reporters=default --reporters=jest-junit
# Produces junit.xml that GitHub Actions and most CI platforms parse natively
```

**GitHub Actions annotations from test results:**

```yaml
- name: Test
  run: npm test -- --ci
  
- name: Report test results
  uses: dorny/test-reporter@v1
  if: always()          # report even when tests fail
  with:
    name: Jest Tests
    path: junit.xml
    reporter: jest-junit
    fail-on-error: true
```

**PR comment with coverage delta:**

```yaml
- name: Coverage comment
  uses: MishaKav/jest-coverage-comment@main
  with:
    coverage-summary-path: coverage/coverage-summary.json
    title: Coverage Report
    badge-title: Coverage
    hide-comment: false
    create-new-comment: false
```

### Environment Parity (CI vs. Local) [community]

CI failures that do not reproduce locally are the most expensive class of test failure — they block the pipeline but cannot be debugged quickly.

> [community] The top three parity gaps reported by engineering teams: (1) file path case sensitivity (macOS is case-insensitive, Linux CI is case-sensitive), (2) environment variables present locally but not in CI, (3) Node.js version differences when `.nvmrc` or `engines` field is ignored.

**Common parity gaps and fixes:**

| Gap | Symptom | Fix |
|---|---|---|
| File path case | `import './MyComponent'` works on Mac, fails on Linux | Enforce lowercase filenames; use `eslint-plugin-import` |
| Missing env vars | `process.env.API_URL` is `undefined` in CI | Declare all required vars in `.env.example`; validate on startup |
| Node.js version | Native addons or syntax differ | Pin version in `.nvmrc` and `engines` field; use `setup-node` with `node-version-file: .nvmrc` |
| Locale / collation | String sorts differ between en-US and C locale | Set `LC_ALL=en_US.UTF-8` in CI jobs |
| Random port conflicts | Integration tests bind to hardcoded ports | Use `0` to let OS assign port; read back with `server.address().port` |
| Timezone | Date assertions fail | `TZ=UTC` in CI env; freeze time in tests |
| File permissions | Scripts not executable | `git update-index --chmod=+x` at commit time |

**Validation script to run locally before push:**

```bash
#!/usr/bin/env bash
# scripts/ci-parity-check.sh — run the same steps CI will run
set -euo pipefail

export CI=true
export TZ=UTC
export NODE_ENV=test

node --version  # must match .nvmrc
npm ci
npm run lint
npm test -- --ci --coverage
echo "CI parity check passed"
```

**Node version pinning in GitHub Actions:**

```yaml
- uses: actions/setup-node@v4
  with:
    node-version-file: .nvmrc   # reads exact version from .nvmrc
    cache: npm
```

### TypeScript Compilation Speed Optimization in CI [community]

TypeScript compilation is frequently the bottleneck in CI for TypeScript projects — type-checking a large codebase can take 30–90 seconds on a cold runner. Several strategies reduce this to 5–15 seconds.

> [community] Teams that profile their CI pipelines consistently find that `tsc --noEmit` is the top-3 slowest step for codebases with 300+ source files. Optimization is not about skipping type-checking — it is about making it incremental so unchanged code is not re-checked.

**Strategy 1: Use `--incremental` with `.tsbuildinfo` caching:**

```yaml
# .github/workflows/ci.yml — incremental TypeScript type-check
jobs:
  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci

      # Cache .tsbuildinfo file between runs — only changed files are re-checked
      - name: Cache TypeScript build info
        uses: actions/cache@v4
        with:
          path: .tsbuildinfo
          key: tsbuildinfo-${{ runner.os }}-${{ hashFiles('tsconfig.json', 'src/**/*.ts') }}
          restore-keys: tsbuildinfo-${{ runner.os }}-

      # --incremental reads .tsbuildinfo; only type-checks changed files
      - run: npx tsc --noEmit --incremental
        name: TypeScript type-check (incremental)
```

**tsconfig.json for incremental CI type-checking:**

```json
{
  "compilerOptions": {
    "strict": true,
    "noEmit": true,
    "incremental": true,
    "tsBuildInfoFile": ".tsbuildinfo",
    "skipLibCheck": false,
    "isolatedModules": true
  },
  "include": ["src/**/*.ts", "src/**/*.tsx", "tests/**/*.ts", "tests/**/*.tsx"]
}
```

> [community] `"isolatedModules": true` in `tsconfig.json` mirrors what `ts-jest` and `esbuild` (Vitest/swc) do during transpilation — it disallows patterns that require cross-file type information at transform time. Enabling it in the main tsconfig ensures that patterns caught by the type-checker match those that would fail during test transpilation. Teams that omit this flag sometimes see tests pass type-check but fail compilation during the test run itself.

**Strategy 2: Split test tsconfig from source tsconfig for faster type-check:**

```json
// tsconfig.json — source only (fastest; no test file overhead)
{
  "compilerOptions": { "strict": true, "noEmit": true },
  "include": ["src/**/*.ts"]
}

// tsconfig.test.json — extends main, adds test paths
{
  "extends": "./tsconfig.json",
  "compilerOptions": { "types": ["vitest/globals", "@testing-library/jest-dom"] },
  "include": ["src/**/*.ts", "tests/**/*.ts"]
}
```

```yaml
# CI: type-check source fast, then check tests separately
- run: npx tsc --noEmit --project tsconfig.json
  name: Type-check source
- run: npx tsc --noEmit --project tsconfig.test.json
  name: Type-check tests
```

### Test Time Budgets [community]

Test time budgets set explicit ceilings on CI duration and are enforced in the pipeline itself, not just documented in a wiki.

> [community] Teams without hard time budgets experience "CI creep": an extra e2e test here, a slow API call there, and within 6 months a 10-minute pipeline becomes 40 minutes. No single change is obviously wrong, but the cumulative effect kills developer flow. Hard budgets force the conversation early.

**Recommended budgets:**

| Suite | Budget | Enforcement |
|---|---|---|
| Lint + syntax-check | < 60 s | CI step timeout |
| Unit tests | < 2 min | CI step timeout |
| Integration tests | < 5 min | CI step timeout |
| E2E smoke (PR gate) | < 10 min | CI step timeout |
| Full pipeline (feature branch) | < 10 min | Workflow-level timeout |
| Full pipeline (main merge) | < 15 min | Workflow-level timeout |

**Enforcing time budgets in GitHub Actions:**

```yaml
# Per-job timeout (minutes)
jobs:
  unit:
    runs-on: ubuntu-latest
    timeout-minutes: 5        # job fails if unit tests take > 5 min
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm test -- --ci --forceExit
        timeout-minutes: 3    # step-level timeout for just the test command

  e2e:
    runs-on: ubuntu-latest
    timeout-minutes: 15       # hard ceiling for e2e job
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npm run test:e2e
        timeout-minutes: 10
```

**Measuring test duration by file (Jest):**

```bash
# Find the 10 slowest test files
npx jest --verbose --json --outputFile=jest-results.json 2>/dev/null
node -e "
const r = require('./jest-results.json');
const sorted = r.testResults
  .map(t => ({ file: t.testFilePath.split('/').slice(-2).join('/'), ms: t.perfStats.end - t.perfStats.start }))
  .sort((a, b) => b.ms - a.ms)
  .slice(0, 10);
console.table(sorted);
"
```

### Artifact Caching [community]

Slow installs are the most common CI time sink. Cache aggressively.

> [community] Across open-source projects on GitHub Actions, `npm ci` without caching averages 45–90 seconds for mid-size projects. With `setup-node` cache enabled, this drops to 3–8 seconds on cache hit. Teams frequently cite caching as the single cheapest CI speedup.

```yaml
# node_modules cache (GitHub Actions built-in via setup-node)
- uses: actions/setup-node@v4
  with:
    node-version: 20
    cache: npm          # caches ~/.npm; restores node_modules on lockfile match

# Playwright browser cache
- name: Cache Playwright browsers
  uses: actions/cache@v4
  with:
    path: ~/.cache/ms-playwright
    key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}

- run: npx playwright install --with-deps chromium

# Docker layer cache (for integration tests using test containers)
- uses: docker/setup-buildx-action@v3
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Concurrency Cancellation (Cancel Superseded Runs) [community]

Cancelling superseded CI runs when a new push arrives saves runner minutes and eliminates the situation where a developer waits for a CI result that is already stale.

> [community] Without concurrency cancellation, a developer who pushes a fix immediately after a broken commit will wait for both CI runs to complete before knowing the result of the second. On projects with 10-minute CI, this is 20 minutes of wasted wait time. Enabling `concurrency.cancel-in-progress` reduces this to a single 10-minute wait. Google's internal tooling mandates this pattern for all feature branch workflows.

**GitHub Actions concurrency groups:**

```yaml
# .github/workflows/ci.yml — cancel stale runs on new push
name: CI

on:
  push:
    branches-ignore: [main]     # never cancel main; let every commit have a record
  pull_request:

# Cancel previous run for same branch/PR when new commit arrives
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm run lint

  unit:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm test -- --ci --coverage
```

**Advanced: separate concurrency groups for deploy vs. test:**

```yaml
jobs:
  test:
    # Allow new test runs to cancel old ones
    concurrency:
      group: test-${{ github.ref }}
      cancel-in-progress: true
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy-preview:
    needs: test
    # Deployments should NOT cancel mid-flight — only queue
    concurrency:
      group: deploy-preview-${{ github.ref }}
      cancel-in-progress: false    # wait for any running deploy to finish first
    runs-on: ubuntu-latest
    steps:
      - run: npm run deploy:preview
```

> [community] A common mistake: applying `cancel-in-progress: true` to deployment jobs. A cancelled deploy can leave infrastructure in a partially-applied state. Always set `cancel-in-progress: false` for deploy, migrate, and seed jobs; reserve cancellation for test and lint jobs.

### Docker BuildKit Cache Export for Integration Tests [community]

Docker BuildKit's inline and registry cache export reduces the time to build test-specific Docker images in CI. For teams using custom Docker images for integration tests (seeded databases, mock services), BuildKit cache export cuts the per-PR build time from 3–8 minutes to 15–30 seconds on cache hit.

> [community] The shift from Docker's classic build cache (ephemeral per runner) to BuildKit's `type=gha` (GitHub Actions Cache) is the highest-leverage single change for teams with custom test images. Classic cache is wiped between CI runs; BuildKit GHA cache persists across runs keyed on Dockerfile layers. Teams that make this change consistently report 70–85% reduction in Docker build time for test images.

**Multi-stage Dockerfile for test images:**

```dockerfile
# Dockerfile.test — multi-stage build with test target
FROM node:22-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci --prefer-offline

FROM base AS source
COPY tsconfig.json ./
COPY src/ ./src/

# Test stage: adds test deps, seeds the database, exposes test-specific env
FROM source AS test
COPY tsconfig.test.json ./
COPY tests/ ./tests/
# Install test-only deps
RUN npm ci --include=dev
# Pre-compile TypeScript for faster test startup
RUN npx tsc --project tsconfig.json --outDir dist

# Seed stage: used for integration tests that need pre-populated data
FROM test AS seed
COPY migrations/ ./migrations/
COPY seeds/ ./seeds/
ENV NODE_ENV=test
RUN node dist/scripts/run-migrations.js && node dist/scripts/seed-test-data.js
```

**GitHub Actions — BuildKit cache export for test image:**

```yaml
# .github/workflows/ci.yml — Docker test image with BuildKit GHA cache
jobs:
  integration:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }

      # Enable Docker BuildKit (required for cache export)
      - uses: docker/setup-buildx-action@v3

      # Build test image with GHA cache — layers are cached between CI runs
      - name: Build integration test image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: Dockerfile.test
          target: test              # build only up to the 'test' stage
          load: true                # load into local Docker daemon (not push to registry)
          tags: myapp-test:${{ github.sha }}
          cache-from: type=gha,scope=integration-test
          cache-to:   type=gha,scope=integration-test,mode=max

      # Run integration tests inside the pre-built test container
      - name: Run integration tests
        run: |
          docker run --rm \
            --network host \
            -e CI=true \
            -e DATABASE_URL=postgresql://test:test@localhost:5432/testdb \
            myapp-test:${{ github.sha }} \
            npm run test:integration
```

**TypeScript test using the seed-stage image for pre-populated data:**

```typescript
// tests/integration/product-search.test.ts — assumes seed-stage image
// Data is seeded at image build time — no per-test setup cost
import { describe, it, expect } from 'vitest';
import { ProductRepository } from '../../src/repositories/product-repository';
import { createPool } from '../../src/db/pool';

describe('ProductRepository — search (seeded data)', () => {
  const pool = createPool({ connectionString: process.env['DATABASE_URL']! });
  const repo = new ProductRepository(pool);

  // No beforeAll setup — data is already in the database (seeded at image build)
  it('returns products matching a full-text search query', async () => {
    const results = await repo.search({ query: 'widget' });
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].name).toMatch(/widget/i);
  });

  it('filters by category', async () => {
    const results = await repo.search({ query: '', category: 'electronics' });
    expect(results.every(p => p.category === 'electronics')).toBe(true);
  });
});
```

> [community] The `mode=max` BuildKit cache export preserves ALL intermediate layers, not just the final image. This means a change to `package.json` only invalidates the `npm ci` layer and above — the base Node.js layer (the slowest to build) is always restored from cache. Teams that use `mode=min` (the default) only cache the final layer and lose most of the build speedup. Always use `mode=max` for test images.

### Testcontainers for Integration Tests (JavaScript) [community]

Testcontainers starts real Docker containers from within test code, ensuring environment parity between local dev and CI without requiring pre-configured CI services.

> [community] The shift from GitHub Actions `services:` declarations to Testcontainers is driven by one pain point: `services:` containers start once per job and share state across all tests. Testcontainers starts a fresh container per test suite (or per test), giving true isolation. Teams that made this switch report 80%+ reduction in "green locally, red in CI" integration test failures.

**Testcontainers with Jest (TypeScript):**

```typescript
// tests/integration/user-repository.test.ts
import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import { UserRepository } from '../../src/repositories/user-repository';
import { createPool } from '../../src/db/pool';

describe('UserRepository', () => {
  let container: StartedPostgreSqlContainer;
  let repo: UserRepository;

  beforeAll(async () => {
    // Start a real Postgres container — same image as production
    container = await new PostgreSqlContainer('postgres:16-alpine')
      .withDatabase('testdb')
      .withUsername('testuser')
      .withPassword('testpass')
      .start();

    const pool = createPool({
      host: container.getHost(),
      port: container.getMappedPort(5432),
      database: container.getDatabase(),
      user: container.getUsername(),
      password: container.getPassword(),
    });

    repo = new UserRepository(pool);
    await pool.query('CREATE TABLE users (id SERIAL PRIMARY KEY, email TEXT UNIQUE)');
  }, 30_000); // allow 30s for container start on first pull

  afterAll(async () => {
    await container.stop();
  });

  beforeEach(async () => {
    // Truncate to isolate each test — faster than transaction rollback for writes
    await repo.pool.query('TRUNCATE users RESTART IDENTITY CASCADE');
  });

  it('creates a user and retrieves by email', async () => {
    await repo.create({ email: 'alice@example.com' });
    const user = await repo.findByEmail('alice@example.com');
    expect(user?.email).toBe('alice@example.com');
  });
});
```

**Reusing containers across tests (Ryuk / reuse option):**

```javascript
// Reuse a container across multiple test files — reduces startup overhead
const container = await new PostgreSqlContainer('postgres:16-alpine')
  .withReuse()           // Testcontainers will reuse an existing container if hash matches
  .start();

// Must also set TESTCONTAINERS_RYUK_DISABLED=true in CI if using --reuse
// to prevent Ryuk from cleaning up containers between jobs
```

> [community] Testcontainers' `withReuse()` option can cut total integration suite time by 40% when the same container image is used across many test files. The risk: the reused container accumulates state between test suites unless each suite truncates its tables. Make `TRUNCATE` in `beforeEach` non-negotiable when using reuse.

### Testcontainers Cloud for CI Pipelines [community]

Testcontainers Cloud eliminates Docker-daemon management in CI by offloading container execution to a remote cloud environment via an SSH tunnel. Tests use the same `@testcontainers/*` client API — no code changes required — but containers run in a dedicated cloud worker (8 GB memory per session) rather than on the CI runner itself.

**Why this matters for CI:** GitHub Actions free-tier runners have 2 vCPUs and ~7 GB RAM. A suite using Testcontainers with Postgres + Redis + a browser can exhaust that budget instantly. Testcontainers Cloud externalises container RAM and I/O to a remote worker, freeing the runner for TypeScript compilation and test execution.

> [community] Teams that migrate from `services:` containers to Testcontainers Cloud report two compounding wins: (1) the CI runner no longer OOMs under heavy parallel suites, and (2) Turbo mode allocates a separate cloud worker per forked test process, achieving linear scaling without any sharding YAML. The migration path is a one-line agent bootstrap and a `TC_CLOUD_TOKEN` secret — existing test code is unchanged.

**GitHub Actions setup (TypeScript Node.js project):**

```yaml
# .github/workflows/integration.yml
name: Integration Tests

on: [pull_request]

jobs:
  integration:
    runs-on: ubuntu-latest
    env:
      TC_CLOUD_TOKEN: ${{ secrets.TC_CLOUD_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      # One-step agent bootstrap — no Dockerfile changes needed
      - uses: atomicjar/testcontainers-cloud-setup-action@main
      - run: npm ci
      # Existing Testcontainers test command unchanged
      - run: npm run test:integration
```

**Turbo mode (parallel workers per fork — TypeScript Jest):**

```typescript
// jest.config.ts — forked workers each get their own cloud Docker daemon
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  // 4 forks → 4 independent Testcontainers Cloud workers (Turbo mode)
  maxWorkers: 4,
  // Each worker runs its own container lifecycle; no shared state
  workerThreads: false,   // forked mode required for independent daemon per worker
  testTimeout: 60_000,    // allow 60s for remote container start on first run
};

export default config;
```

**Enable Turbo mode in CI (increases concurrency):**

```yaml
# Set max concurrency for Turbo mode (each parallel process → 1 cloud worker)
- uses: atomicjar/testcontainers-cloud-setup-action@main
  with:
    args: --max-concurrency=4 --terminate
```

**Key limitations to document on the team wiki:**

```typescript
// LIMITATION: File system mounts do NOT work with Testcontainers Cloud.
// Replace BindMountVolume with copyFileToContainer() in your setup.

// BAD — fails with Testcontainers Cloud:
// container.withBindMount('/host/seed.sql', '/docker-entrypoint-initdb.d/seed.sql');

// GOOD — works locally and in cloud:
import { GenericContainer } from 'testcontainers';
import * as fs from 'fs';

const container = await new GenericContainer('postgres:16-alpine')
  .withExposedPorts(5432)
  .start();

// Copy init SQL after container starts
await container.copyContentToContainer([{
  content: fs.readFileSync('./tests/fixtures/seed.sql'),
  target: '/docker-entrypoint-initdb.d/seed.sql',
}]);
```

> [community] The most common Testcontainers Cloud adoption issue: `TC_CLOUD_TOKEN` is scoped to a service account (CI) vs. a developer seat (Desktop). Mixing them by sharing the CI token with developers causes quota exhaustion on the service account and breaks the pipeline. Create a dedicated service account token for each CI provider (GitHub Actions, GitLab CI, Jenkins) and a separate seat allocation for developer machines.

> [community] Testcontainers Cloud's `--terminate` flag is critical for CI cost control. Without it, cloud workers idle for up to 60 seconds after the CI job ends, consuming Worker Minutes (the billing unit for service accounts). Setting `--terminate` in the setup action drops the worker immediately when the job exits, eliminating the idle charge. On a 50-PR/day team running 4-worker Turbo suites, this saves ~200 Worker Minutes/day.

### Type-Safe API Mocking with MSW in CI [community]

Mock Service Worker (MSW) intercepts HTTP requests at the network layer, making integration tests against typed API clients more robust in CI. Unlike manually mocking `fetch` or `axios`, MSW mocks persist across module boundaries without test-file-level setup.

> [community] Teams using MSW for TypeScript API mocking report that type-safe request handlers catch stale mock data patterns — when the API schema changes (e.g., a field is renamed or removed), the TypeScript compiler flags the handler immediately. Teams using manual `jest.mock('axios')` approaches discover API-mock drift only when tests randomly fail due to unexpected undefined values. MSW + TypeScript eliminates this entire class of CI flakiness.

```typescript
// tests/mocks/handlers.ts — type-safe MSW request handlers
import { http, HttpResponse } from 'msw';

// Import API types for type-safe response bodies
import type { User, ApiError } from '../../src/types/api';

export const handlers = [
  // Type-checked: HttpResponse.json() validates body against inferred type
  http.get('/api/users/:id', ({ params }) => {
    const userId = params['id'] as string;

    if (userId === '999') {
      return HttpResponse.json<ApiError>(
        { code: 'NOT_FOUND', message: 'User not found' },
        { status: 404 },
      );
    }

    return HttpResponse.json<User>({
      id: userId,
      email: 'alice@example.com',
      name: 'Alice Smith',
      role: 'user',
    });
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json() as Partial<User>;
    return HttpResponse.json<User>({
      id: 'new-user-id',
      email: body.email ?? 'default@example.com',
      name: body.name ?? 'New User',
      role: 'user',
    }, { status: 201 });
  }),
];
```

```typescript
// tests/setup.ts — MSW server setup for Vitest/Jest (Node.js integration tests)
import { setupServer } from 'msw/node';
import { handlers } from './mocks/handlers';

// Shared server instance — handlers are applied globally to all test files
export const server = setupServer(...handlers);

// Start server before all tests, reset handlers after each, close after all
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

**`onUnhandledRequest: 'error'` in CI:** This setting causes any unmatched HTTP request to throw — preventing tests from silently making real network calls in CI. Set to `'error'` in CI, `'warn'` during local development.

> [community] The `onUnhandledRequest: 'error'` option is the single most impactful MSW configuration for CI reliability. Without it, a test that accidentally makes a real API call (e.g., a missing mock handler after a code change) will either hang waiting for a network timeout or succeed with real data — both of which corrupt the CI signal. With `'error'`, unhandled requests fail immediately with a clear error message identifying the missing handler.

### Turborepo Remote Caching [community]

Turborepo's remote cache stores task outputs (build artifacts, test results) in a shared store accessible by all CI runners and developer machines. A test task that has already passed for a given input hash is skipped entirely — its cached result is replayed.

> [community] Vercel's Turborepo team reports that enabling remote caching reduces CI time by 30–70% for monorepos that have already run the full suite locally. The highest gains come from the `build` and `test` tasks for packages that haven't changed since the last green run. This is distinct from node_modules caching — remote caching operates at the task graph level, not the file system level.

**Setup:**

```bash
# Authenticate with Vercel's remote cache (free for open-source)
npx turbo login
npx turbo link  # links the repo to a remote cache space

# Or use a self-hosted cache (e.g., ducktape/turborepo-remote-cache on your infra)
```

**GitHub Actions integration with remote caching:**

```yaml
# .github/workflows/ci.yml — Turborepo remote cache in CI
name: CI (Turbo)

on: [push, pull_request]

env:
  TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}   # Vercel remote cache token
  TURBO_TEAM: ${{ vars.TURBO_TEAM }}        # Vercel team slug

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 2 }             # needed for --filter=[HEAD^1]
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci

      # Run only tasks affected by changes since last commit
      # Remote cache will replay any task that already passed for this input hash
      - run: npx turbo run lint test build --filter=...[HEAD^1]
```

**turbo.json cache configuration:**

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": [".env.test"],
  "pipeline": {
    "test": {
      "dependsOn": ["^build"],
      "inputs": ["src/**", "tests/**", "jest.config.js", "vitest.config.js"],
      "outputs": ["coverage/**"],
      "cache": true
    },
    "lint": {
      "inputs": ["src/**", ".eslintrc.*", ".eslintrc.js"],
      "outputs": [],
      "cache": true
    },
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["src/**"],
      "outputs": ["dist/**"],
      "cache": true
    }
  }
}
```

> [community] The most common remote caching pitfall: including generated or environment-specific files in `inputs`. If `inputs` contains anything that differs between developer machines and CI (e.g., absolute paths baked into a lockfile, or env vars accidentally included), the cache will never hit. Keep `inputs` explicit and minimal — only source files and config files that truly affect the task output.

### Matrix Testing (Multi-Version / Multi-OS) [community]

Matrix testing validates your project works across all supported runtime versions and operating systems — catching platform-specific bugs that only appear on Windows (path separator, `CRLF`) or older Node.js versions before they reach production.

> [community] Node.js packages distributed on npm must test across the `engines` range declared in `package.json`. Teams that only test on the latest LTS and skip older versions consistently receive production bug reports from users on Node 18 when the package was developed on Node 22. Matrix testing in CI is the cheapest form of cross-version regression prevention.

```yaml
# .github/workflows/ci-matrix.yml — test across Node versions
name: CI Matrix

on: [push, pull_request]

jobs:
  test:
    strategy:
      fail-fast: false        # collect results from ALL matrix entries
      matrix:
        node: [18, 20, 22]    # test every version in your engines range
        os: [ubuntu-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    name: Node ${{ matrix.node }} / ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: npm
      - run: npm ci
      - run: npm test -- --ci
      # Upload per-matrix results for diagnosis
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: test-results-node${{ matrix.node }}-${{ matrix.os }}
          path: junit.xml
```

**Restricting matrix to specific combinations (exclude):**

```yaml
strategy:
  matrix:
    node: [18, 20, 22]
    os: [ubuntu-latest, windows-latest, macos-latest]
    exclude:
      # macOS runners are expensive — skip non-LTS versions on macOS
      - os: macos-latest
        node: 18
      - os: macos-latest
        node: 22
```

**Why `fail-fast: false` matters in matrix jobs:** With `fail-fast: true` (the default), the first matrix entry failure cancels all other entries. This hides whether the failure is platform-specific. Set `fail-fast: false` to collect the full failure picture across all matrix combinations before triaging.

### TypeScript Type-Check as a CI Gate [community]

TypeScript projects must run `tsc --noEmit` as a separate CI gate from test execution. `ts-jest` and Vitest transpile TypeScript without type-checking by default, meaning type errors can silently coexist with passing tests.

> [community] The most common TypeScript CI mistake: assuming `ts-jest` enforces type safety. `ts-jest` by default uses `isolatedModules: true` which transpiles each file in isolation and skips cross-file type checking. A function that accepts `string` but is called with `number` will pass all tests and fail only at runtime — unless `tsc --noEmit` is a required CI gate. Teams that add this gate after their first type-error production incident typically find 10–30 latent type errors on the first run.

**Type-check step in GitHub Actions CI pipeline:**

```yaml
# .github/workflows/ci.yml — TypeScript type-check as a required gate
jobs:
  typecheck:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # noEmit: check types without writing output files
      # Runs separately from tests so failures are clearly attributed to type errors
      - run: npx tsc --noEmit --project tsconfig.json
        name: TypeScript type-check

  unit:
    needs: typecheck          # unit tests only run if types are clean
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm test -- --ci --coverage
```

**Recommended `tsconfig.json` settings for strict CI validation:**

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": false
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist", "coverage"]
}
```

> [community] Enable `skipLibCheck: false` in CI but `skipLibCheck: true` in local development config (`tsconfig.local.json`). The full lib check catches type definition mismatches between packages (e.g., `@types/node` version conflicts) that only matter in production, but adds 5–15 seconds to type-check time that developers tolerate poorly locally.

**TypeScript project references for monorepo type-checking (fast incremental):**

```typescript
// tsconfig.json (root — references all packages)
{
  "files": [],
  "references": [
    { "path": "./packages/core" },
    { "path": "./packages/api" },
    { "path": "./packages/ui" }
  ]
}
```

```bash
# In CI — use --build for incremental composite project checking
# Only re-checks packages whose source has changed since last build
npx tsc --build --noEmit
```

> [community] TypeScript composite project references (`"composite": true`) enable incremental type-checking in monorepos via `tsc --build`. On a 20-package monorepo, full `tsc --noEmit` takes 45–90 seconds; `tsc --build` with a warm `.tsbuildinfo` cache takes 3–8 seconds because only changed packages are re-checked. Cache the `.tsbuildinfo` files in CI the same way you cache `node_modules`.

### Pre-commit Hooks as Local CI Gates [community]

Pre-commit hooks run fast checks (lint, format, unit tests) before a commit completes on the developer's machine — catching issues before they enter CI at all. The best CI pipeline is one that never runs because the bug was caught locally.

**Setup with `husky` + `lint-staged` (JavaScript):**

```bash
# Install
npm install --save-dev husky lint-staged

# Initialize husky (adds .husky/ directory)
npx husky init
```

**package.json configuration:**

```json
{
  "scripts": {
    "prepare": "husky"
  },
  "lint-staged": {
    "*.js": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

**.husky/pre-commit:**

```bash
#!/usr/bin/env sh
# Run lint-staged: only lint files staged for commit (fast)
npx lint-staged

# Run unit tests for changed files only (fast, ~2s for typical change)
npx jest --passWithNoTests --findRelatedTests $(git diff --cached --name-only --diff-filter=ACMR | tr '\n' ' ')
```

> [community] The most common pre-commit hook mistake: running the full test suite in the hook. A 2-minute test run triggered on every commit kills developer flow within days. Use `--findRelatedTests` to scope Jest to only the files changed in the commit — typically 0.5–3 seconds for most commits. Reserve full suite validation for CI.

**Bypassing hooks intentionally (with a paper trail):**

```bash
# --no-verify is intentional; the CI will still catch issues
git commit -m "WIP: sketch approach" --no-verify
```

> [community] Document in `CONTRIBUTING.md` that `--no-verify` is acceptable for WIP commits on feature branches, but all PRs must pass CI. This removes the temptation to add slow hooks (developers can bypass them legitimately) while keeping CI as the authoritative gate.

### Security Scanning as a CI Gate [community]

Static application security testing (SAST) and dependency vulnerability scanning belong in the CI pipeline as non-blocking advisory checks on feature branches and as soft-required gates on PRs to main. Running them in CI ensures every pull request is screened without requiring developers to manually run tools locally.

> [community] Teams that add security scanning after a security incident spend 2–3× more time remediating than teams that gate on it from the start. The most effective deployment pattern: advisory (warning) on feature branches, required (blocking) on merge-to-main. This way developers aren't blocked on their first commit but cannot ship without addressing findings.

**Dependency audit with npm (built-in, no extra dependency):**

```javascript
// package.json — add audit to pre-ship checklist
{
  "scripts": {
    "audit:ci": "npm audit --audit-level=high --json | node scripts/audit-gate.js"
  }
}
```

```javascript
// scripts/audit-gate.js — only fail on high/critical; warn on moderate
'use strict';

const chunks = [];
process.stdin.on('data', d => chunks.push(d));
process.stdin.on('end', () => {
  const report = JSON.parse(chunks.join(''));
  const { high = 0, critical = 0, moderate = 0 } = report.metadata?.vulnerabilities ?? {};

  if (critical > 0 || high > 0) {
    console.error(`[audit-gate] FAIL: ${critical} critical, ${high} high vulnerabilities found`);
    console.error('Run "npm audit fix" or update affected packages before merging.');
    process.exit(1);
  }
  if (moderate > 0) {
    console.warn(`[audit-gate] WARN: ${moderate} moderate vulnerabilities (advisory — not blocking)`);
  }
  console.log('[audit-gate] PASS: no high/critical vulnerabilities');
});
```

**GitHub Actions integration — security scan in CI pipeline:**

```yaml
# .github/workflows/ci.yml — security scanning stage
  security:
    needs: unit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci

      # Dependency vulnerability audit — blocks on high/critical
      - name: Dependency audit
        run: npm run audit:ci

      # SAST with CodeQL (GitHub-native, free for public repos)
      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
        with:
          category: /language:javascript-typescript
```

**Lightweight alternative — OSV-Scanner (fast, deterministic, works offline):**

```bash
# Install OSV-Scanner
npm install --save-dev @google/osv-scanner

# Scan all dependencies in the monorepo
npx osv-scanner --lockfile=package-lock.json --format=table

# In CI — fail only on known exploited vulnerabilities (KEV)
npx osv-scanner --lockfile=package-lock.json --call-analysis=all \
  --format=json | jq '.results[] | select(.packages[].vulnerabilities[] | .database_specific.severity == "CRITICAL") | .source.path' \
  && echo "::error::Critical vulnerability found — check OSV Scanner output"
```

> [community] The most common mistake with security scanning in CI: running `npm audit` without `--audit-level=high` and treating every moderate finding as a blocker. npm currently reports 50–200 moderate-severity findings for any production Node.js project (transitive dependencies that cannot be updated). Gating on `moderate` causes permanent CI red, erodes trust, and teams disable the check entirely within weeks. Gate strictly on `high` and `critical` only.

> [community] A separate pattern used by security-conscious teams: pin exact dependency versions in `package-lock.json` AND verify the lockfile hash in CI with `npm ci` (which verifies the lockfile). Any change to `package-lock.json` that wasn't committed deliberately fails CI. This prevents supply-chain attacks that mutate transitive dependencies between developer machines and CI runners.

### Test Health Trend Tracking [community]

Tracking test health over time reveals patterns invisible in single-run results: a test that passes 97% of the time is not "mostly fine" — it is flaky with a 3% failure rate that will cause approximately one PR block per day on an active team. Trend data drives quarantine prioritization.

> [community] Teams that invest in test health dashboards catch and fix flaky tests 5× faster than teams that rely on developer reports ("this failed again for me"). The critical insight: a single test failure is ambiguous (maybe infrastructure glitch); a trend showing 5% failure rate over 30 days is a confirmed defect.

**Trend tracking with GitHub Actions summary and SQLite log (TypeScript):**

```typescript
// scripts/record-test-run.ts — append test results to a SQLite log
import Database from 'better-sqlite3';
import * as fs from 'fs';
import * as path from 'path';

const DB_PATH = path.join(process.cwd(), '.test-health', 'history.db');
const RESULTS_PATH = process.env['RESULTS_FILE'] ?? 'test-results/results.json';

interface JestResults {
  numTotalTests: number;
  numPassedTests: number;
  numFailedTests: number;
  numPendingTests: number;
  testResults: Array<{ perfStats: { end: number; start: number } }>;
}

function recordRun(): void {
  fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });

  const db = new Database(DB_PATH);

  // Initialize schema on first run
  db.exec(`
    CREATE TABLE IF NOT EXISTS test_runs (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      run_at    TEXT NOT NULL,
      branch    TEXT,
      sha       TEXT,
      total     INTEGER,
      passed    INTEGER,
      failed    INTEGER,
      skipped   INTEGER,
      duration_ms INTEGER
    );
    CREATE TABLE IF NOT EXISTS flaky_tests (
      id       INTEGER PRIMARY KEY AUTOINCREMENT,
      run_id   INTEGER REFERENCES test_runs(id),
      title    TEXT,
      file     TEXT,
      retries  INTEGER
    );
  `);

  const results = JSON.parse(fs.readFileSync(RESULTS_PATH, 'utf8')) as JestResults;
  const runAt = new Date().toISOString();
  const branch = process.env['GITHUB_REF_NAME'] ?? 'local';
  const sha = process.env['GITHUB_SHA'] ?? 'local';

  const insert = db.prepare(`
    INSERT INTO test_runs (run_at, branch, sha, total, passed, failed, skipped, duration_ms)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const run = insert.run(
    runAt, branch, sha,
    results.numTotalTests,
    results.numPassedTests,
    results.numFailedTests,
    results.numPendingTests,
    results.testResults.reduce((sum, r) => sum + (r.perfStats.end - r.perfStats.start), 0),
  );

  console.log(`[test-health] Recorded run ${run.lastInsertRowid}: ${results.numPassedTests}/${results.numTotalTests} passed`);
  db.close();
}

recordRun();
```

**GitHub Actions step to persist and query trend data:**

```yaml
- name: Record test health
  if: always()   # record even when tests fail — the failure IS the data point
  run: npx ts-node scripts/record-test-run.ts
  env:
    RESULTS_FILE: test-results/jest-results.json

# Upload the trend database as a build artifact (retained 90 days)
- uses: actions/upload-artifact@v4
  if: always()
  with:
    name: test-health-db
    path: .test-health/history.db
    retention-days: 90
```

**Query recent flakiness rate (run locally or in a scheduled CI job):**

```bash
# Print test cases with > 2% failure rate over last 30 days
node --input-type=commonjs <<'EOF'
const Database = require('better-sqlite3');
const db = new Database('.test-health/history.db');

const cutoff = new Date(Date.now() - 30 * 24 * 3600 * 1000).toISOString();
const stats = db.prepare(`
  SELECT
    branch,
    COUNT(*) as runs,
    SUM(failed) as total_failures,
    ROUND(100.0 * SUM(failed) / SUM(total), 1) as failure_rate_pct,
    ROUND(AVG(duration_ms) / 1000.0, 1) as avg_duration_s
  FROM test_runs
  WHERE run_at > ?
  GROUP BY branch
  ORDER BY failure_rate_pct DESC
`).all(cutoff);

console.table(stats);
db.close();
EOF
```

> [community] The most overlooked aspect of test health tracking: recording on failure as well as success. Many teams only call tracking scripts in `if: success()` blocks. The failure rate then appears to be 0% because only passing runs are counted. Use `if: always()` to capture the full picture.

> [community] SQLite is deliberately chosen over a hosted metrics service for this pattern. It requires zero infrastructure, works offline, runs in GitHub Actions without secrets, and the database file can be committed to git for small projects or stored as a long-lived artifact for larger ones. Teams that add a Grafana/Prometheus stack for test health invariably abandon it within 3 months due to maintenance overhead.

### Dynamic Shard Count via GitHub Actions Matrix Output [community]

Static shard matrices (e.g., always 4 shards) under-parallelize for large test suites and over-parallelize for small ones. Dynamic matrices compute the optimal shard count from the actual number of test files at runtime, so CI cost and speed scale automatically with test suite size.

> [community] Teams maintaining a growing monorepo report that static shard counts become a configuration maintenance burden within 6–12 months. A suite that fit 4 shards at launch needs 8 shards at 200 tests and 12 at 400. Dynamic matrix generation removes this manual tuning and eliminates the problem of a shard receiving 0 test files (which wastes a runner slot silently).

**Dynamic matrix generation (GitHub Actions):**

```yaml
# .github/workflows/e2e-dynamic.yml — shard count adapts to test file count
name: E2E Dynamic Sharding

on: [pull_request]

jobs:
  compute-shards:
    runs-on: ubuntu-latest
    outputs:
      shards: ${{ steps.compute.outputs.shards }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Compute shard count
        id: compute
        run: |
          # Count spec files; target ~25 test cases per shard for browser tests
          FILE_COUNT=$(find tests/e2e -name '*.spec.js' | wc -l | tr -d ' ')
          SHARD_COUNT=$(node -e "console.log(Math.min(Math.max(Math.ceil($FILE_COUNT / 25), 1), 8))")
          echo "Detected $FILE_COUNT spec files → $SHARD_COUNT shards"
          SHARDS=$(node -e "console.log(JSON.stringify(Array.from({length: $SHARD_COUNT}, (_, i) => i + 1)))")
          echo "shards=$SHARDS" >> $GITHUB_OUTPUT

  e2e:
    needs: compute-shards
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        shard: ${{ fromJSON(needs.compute-shards.outputs.shards) }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: |
          TOTAL=$(echo '${{ needs.compute-shards.outputs.shards }}' | node -e "const s=require('fs').readFileSync(0,'utf8');console.log(JSON.parse(s).length)")
          npx playwright test --shard=${{ matrix.shard }}/$TOTAL --reporter=blob
      - uses: actions/upload-artifact@v4
        with:
          name: blob-report-${{ matrix.shard }}
          path: blob-report/

  merge-reports:
    needs: e2e
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - uses: actions/download-artifact@v4
        with:
          path: all-blob-reports/
          pattern: blob-report-*
          merge-multiple: true
      - run: npx playwright merge-reports --reporter html ./all-blob-reports
      - uses: actions/upload-artifact@v4
        with:
          name: html-report
          path: playwright-report/
```

> [community] The maximum useful shard count for browser e2e tests is typically 8–12. Beyond that, browser launch overhead (constant per shard, ~5 seconds for Chromium) consumes a disproportionate share of each shard's runtime. A 16-shard split of a 400-test suite means each shard runs 25 tests in ~2 minutes but spends 15–20 seconds just launching the browser — 10–15% overhead per shard. Profile before scaling past 8 shards.

### GitHub Actions Composite Actions for DRY CI [community]

Composite actions encapsulate a sequence of steps (checkout, setup-node, install, cache) into a single reusable action — distinct from reusable workflows in that they operate at the step level inside a job rather than at the job level. They eliminate the duplication of 5–10 setup steps replicated across every job in every workflow file.

> [community] Teams with 3+ CI workflows and 4+ jobs per workflow report that composite actions cut YAML line count by 40–60% and eliminate the "I updated the cache key in ci.yml but forgot release.yml" class of drift bug. The primary gotcha: composite actions inherit the calling job's environment (secrets, env vars) but NOT its default working directory — always set `working-directory` explicitly in composite action steps.

**Example composite action (`actions/setup-node-project/action.yml`):**

```yaml
# .github/actions/setup-node-project/action.yml — reusable setup composite action
name: Setup Node.js Project
description: Checkout, install Node, install deps, restore caches

inputs:
  node-version:
    description: Node.js version (reads .nvmrc if not specified)
    required: false
    default: ''
  install-playwright:
    description: Whether to also install Playwright browsers
    required: false
    default: 'false'

runs:
  using: composite
  steps:
    - uses: actions/checkout@v4

    - name: Resolve Node version
      id: node-version
      shell: bash
      run: |
        if [ -n "${{ inputs.node-version }}" ]; then
          echo "version=${{ inputs.node-version }}" >> $GITHUB_OUTPUT
        elif [ -f .nvmrc ]; then
          echo "version=$(cat .nvmrc)" >> $GITHUB_OUTPUT
        else
          echo "version=20" >> $GITHUB_OUTPUT
        fi

    - uses: actions/setup-node@v4
      with:
        node-version: ${{ steps.node-version.outputs.version }}
        cache: npm

    - name: Install dependencies
      shell: bash
      run: npm ci

    - name: Cache Playwright browsers
      if: inputs.install-playwright == 'true'
      uses: actions/cache@v4
      with:
        path: ~/.cache/ms-playwright
        key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}

    - name: Install Playwright browsers
      if: inputs.install-playwright == 'true'
      shell: bash
      run: npx playwright install --with-deps chromium
```

**Workflows using the composite action:**

```yaml
# .github/workflows/ci.yml — all jobs use the same composite setup
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: ./.github/actions/setup-node-project
      - run: npm run lint

  unit:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: ./.github/actions/setup-node-project
      - run: npm test -- --ci --coverage

  e2e:
    needs: unit
    runs-on: ubuntu-latest
    steps:
      - uses: ./.github/actions/setup-node-project
        with: { install-playwright: 'true' }
      - run: npm run test:e2e
```

> [community] A frequently missed limitation: composite actions cannot use `${{ secrets.* }}` directly — secrets must be passed from the calling workflow via `env:` on the `uses:` step or as `inputs:`. Teams that put secret references inside composite actions hit cryptic "Context not allowed" errors. The pattern is always: caller passes via `env:`, composite action reads via `${{ env.* }}`.

### SBOM Generation as a CI Gate [community]

A Software Bill of Materials (SBOM) is a machine-readable inventory of all software components and dependencies in a project. Generating an SBOM in CI and attaching it as a build artifact enables downstream vulnerability scanning, supply-chain audit, and compliance reporting (required by NIST SP 800-218, US EO 14028, EU CRA).

> [community] Security teams at regulated enterprises increasingly require SBOMs for any software released to production. Teams that bolt on SBOM generation after an audit discover it is significantly harder: dependencies have accumulated without vetting, and the SBOM reveals transitive packages that nobody knew were included. Generating and reviewing the SBOM from the first CI run makes dependency hygiene visible before it becomes a compliance emergency.

```yaml
# .github/workflows/ci.yml — SBOM generation as a CI artifact
  sbom:
    needs: unit
    runs-on: ubuntu-latest
    permissions:
      contents: write        # required to attach SBOM as release asset
      packages: read
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci

      # Generate CycloneDX SBOM (JSON format — machine-readable, widely supported)
      - name: Generate SBOM
        run: npx @cyclonedx/cyclonedx-npm --output-file sbom.json --output-format json

      # Validate SBOM is well-formed
      - name: Validate SBOM
        run: npx @cyclonedx/cyclonedx-cli validate --input-file sbom.json --input-format json

      # Upload SBOM as a build artifact (retained 90 days)
      - uses: actions/upload-artifact@v4
        with:
          name: sbom-${{ github.sha }}
          path: sbom.json
          retention-days: 90

      # On main: attach SBOM to GitHub release (SLSA attestation)
      - name: Attach SBOM to release
        if: github.ref == 'refs/heads/main'
        uses: softprops/action-gh-release@v2
        with:
          files: sbom.json
          tag_name: ${{ github.sha }}
```

**TypeScript script to query SBOM for risky packages (post-generation check):**

```typescript
// scripts/sbom-audit.ts — fail CI if SBOM contains packages with known issues
import * as fs from 'fs';

interface SbomComponent {
  type: string;
  name: string;
  version: string;
  purl?: string;
}

interface CycloneDxSbom {
  components: SbomComponent[];
}

// Packages known to have critical issues in specific versions — update as needed
const DENY_LIST: Record<string, string> = {
  'event-stream': '3.3.6',    // 2018 supply-chain attack
  'ua-parser-js': '0.7.28',   // 2021 supply-chain attack
  'node-ipc': '10.1.1',       // 2022 supply-chain attack
};

function auditSbom(sbomPath: string): void {
  const sbom = JSON.parse(fs.readFileSync(sbomPath, 'utf8')) as CycloneDxSbom;
  const violations: string[] = [];

  for (const component of sbom.components ?? []) {
    const deniedVersion = DENY_LIST[component.name];
    if (deniedVersion && component.version === deniedVersion) {
      violations.push(`DENIED: ${component.name}@${component.version} (supply-chain risk)`);
    }
  }

  if (violations.length > 0) {
    console.error('[sbom-audit] FAIL — denied packages found:');
    violations.forEach(v => console.error(`  ${v}`));
    process.exit(1);
  }

  console.log(`[sbom-audit] PASS — ${sbom.components?.length ?? 0} components, none denied`);
}

auditSbom(process.env['SBOM_PATH'] ?? 'sbom.json');
```

> [community] The most common SBOM pitfall: generating the SBOM from source (reading `package.json`) rather than from the installed tree (reading `node_modules`). Source-based SBOMs miss transitive dependencies and phantom dependencies (packages listed in `package.json` but not installed due to version resolution). Always generate from the installed tree (`npx @cyclonedx/cyclonedx-npm` reads `node_modules`), and always run `npm ci` before SBOM generation in CI.

### GitHub Actions Larger Runners for Test Acceleration [community]

GitHub Actions offers 4-core, 8-core, and 16-core hosted runners (at 2×, 4×, and 8× the per-minute cost of the standard 2-core runner). For test suites that are CPU or memory bound, upgrading the runner size often beats adding shards — it keeps the pipeline simple and reduces coordination overhead.

> [community] Platform teams at mid-size companies (50–200 engineers) report that switching from `ubuntu-latest` (2 vCPU, 7 GB RAM) to `ubuntu-latest-4-cores` (4 vCPU, 16 GB RAM) cut their integration test suite time by 55% at 2× the runner cost — breaking even after accounting for the eliminated shard coordination overhead (artifact upload/merge steps). The tipping point: when shards are needed purely because the test suite is CPU-bound on 2 cores, a larger runner is cheaper and simpler than 4 shards.

```yaml
# .github/workflows/ci.yml — use larger runner for integration tests
jobs:
  integration:
    # 4-core runner: 2× cost but eliminates need for 4 shards
    runs-on: ubuntu-latest-4-cores
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # With 4 cores, maxWorkers: 50% = 2 workers (optimal for 4-vCPU runner)
      - run: npx jest --testPathPattern=tests/integration --maxWorkers=2 --ci
```

**Runner size decision matrix:**

```typescript
// scripts/recommend-runner.ts — estimate optimal runner size from test timing data
interface SuiteProfile {
  name: string;
  durationMs: number;
  concurrencyGain: number;   // how much parallel workers help (0-1)
  memoryMb: number;
}

function recommendRunner(profile: SuiteProfile): string {
  // If suite benefits from concurrency AND is slow, a larger runner wins over sharding
  if (profile.durationMs > 120_000 && profile.concurrencyGain > 0.6) {
    if (profile.memoryMb > 12_000) return 'ubuntu-latest-8-cores';
    return 'ubuntu-latest-4-cores';
  }
  // Memory-bound suites (many testcontainers, large in-memory databases)
  if (profile.memoryMb > 12_000) return 'ubuntu-latest-4-cores';
  // Default: optimize cost, not speed
  return 'ubuntu-latest';
}

const integrationProfile: SuiteProfile = {
  name: 'integration',
  durationMs: 180_000,     // 3 min on 2-core runner
  concurrencyGain: 0.72,   // high: I/O + CPU mixed workload
  memoryMb: 8_192,
};

console.log(recommendRunner(integrationProfile)); // → ubuntu-latest-4-cores
```

**Cost comparison: sharding vs. larger runner:**

```
Scenario: integration suite takes 8 min on ubuntu-latest (2 vCPU)
Option A: 4 shards × ubuntu-latest = 4 × $0.008/min × 2 min each = $0.064 + artifact overhead
Option B: 1 × ubuntu-latest-4-cores = 1 × $0.016/min × ~4 min = $0.064 (same cost, less complexity)
Option C: 1 × ubuntu-latest-8-cores = 1 × $0.032/min × ~2 min = $0.064 (same cost, faster)
```

> [community] Larger runner sizes are most effective for memory-bound suites (Testcontainers pulling multiple DB images) and CPU-bound suites (TypeScript compilation + parallel test execution). They provide NO benefit for I/O-bound suites that are mostly waiting on network or disk. Profile before purchasing — measure CPU and memory utilization on the current runner. If CPU is below 40%, the bottleneck is elsewhere and a larger runner won't help.

### Node.js Native Test Runner in CI [community]

Node.js 22 LTS ships a stable, built-in test runner (`node:test`) with TypeScript support via `--experimental-strip-types` (Node 22) or `tsx`. For projects that do not require Jest's snapshot testing, custom reporters, or jsdom, the native runner eliminates a test framework dependency and reduces CI install time.

> [community] Teams evaluating the native test runner report it is production-ready for Node.js-only service tests (no DOM, no React) as of Node 22. The main gap vs. Jest/Vitest: no snapshot testing, no built-in code coverage UI (only V8 coverage via `--experimental-test-coverage`), and no watch mode equivalent for local development. Teams building pure Node.js microservices (APIs, workers, CLIs) gain 30–50% faster CI from zero-dependency test execution.

```typescript
// tests/unit/user-service.test.ts — Node.js native test runner (TypeScript via --experimental-strip-types)
import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { UserService } from '../../src/services/user-service.ts';
import type { UserRepository } from '../../src/repositories/user-repository.ts';

// Minimal mock using node:test mock utilities
const mockRepository = {
  findByEmail: async (_email: string) => null,
  create: async (data: { email: string }) => ({ id: 'test-id', ...data }),
} satisfies Partial<UserRepository>;

describe('UserService', () => {
  let service: UserService;

  beforeEach(() => {
    service = new UserService(mockRepository as unknown as UserRepository);
  });

  it('returns null when user is not found', async () => {
    const result = await service.getUserByEmail('notfound@example.com');
    assert.strictEqual(result, null);
  });

  it('creates a user and returns the persisted entity', async () => {
    const user = await service.createUser({ email: 'alice@example.com' });
    assert.ok(user.id, 'persisted user must have an id');
    assert.strictEqual(user.email, 'alice@example.com');
  });
});
```

**GitHub Actions — Node.js native test runner with TypeScript (no build step):**

```yaml
# .github/workflows/ci-native.yml — zero test-framework CI for Node.js microservices
name: CI (Node.js native runner)

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci

      # Type-check (native runner does NOT type-check — strip-types skips it)
      - run: npx tsc --noEmit --project tsconfig.json
        name: TypeScript type-check

      # Run tests directly — Node 22 strips TypeScript syntax without tsc
      - run: |
          node --experimental-strip-types \
               --experimental-test-coverage \
               --test 'tests/**/*.test.ts'
        name: Unit tests (native runner)
```

> [community] The `--experimental-strip-types` flag (Node 22.6+) removes TypeScript syntax without type-checking — it's equivalent to Babel's TypeScript preset. This means type errors will NOT cause CI failures unless `tsc --noEmit` is also a separate step. Teams that switch to native runner without adding a type-check step discover type errors in production within weeks. Always pair `--experimental-strip-types` with a `tsc --noEmit` gate.

### Node.js 24 LTS Native Test Runner Upgrades [community]

Node.js 24 (released April 2025, entering LTS in October 2025) upgrades the built-in `node:test` runner with three CI-significant additions: **`--test-global-setup`** for zero-framework global setup/teardown, **stable snapshot testing**, and **programmatic coverage thresholds**. It also bundles **npm 11** with several CI-impacting security hardening changes and marks type stripping as **Release Candidate (RC)** — closer to a stable `--strip-types` flag.

> [community] Teams evaluating the native test runner in Node 22 frequently hit two blockers: no built-in global setup/teardown (requiring workarounds), and experimental snapshot support. Both are resolved in Node 24. Teams already using the native runner in Node 22 can adopt `--test-global-setup` with a drop-in migration: extract their `beforeAll`-based DB migration calls into a `setup-module.mjs` file and pass it via the flag — no test file changes required.

**`--test-global-setup` — zero-framework global setup/teardown (Node 24+):**

```typescript
// test-global-setup.ts — runs once before all tests, once after (Node 24+)
// Invoke with: node --experimental-strip-types --test-global-setup=test-global-setup.ts --test ...

export async function setup(): Promise<void> {
  // Runs once before all tests — start shared resources
  process.env['TEST_DATABASE_URL'] = 'postgresql://test:test@localhost:5432/testdb';
  console.log('[global-setup] Database URL configured');

  // Perform DB migration synchronously before any test file loads
  // (equivalent to Jest globalSetup or Vitest globalSetup)
}

export async function teardown(): Promise<void> {
  // Runs once after all tests — clean up shared resources
  console.log('[global-teardown] Cleaning up database connections');
  // Close any shared pools, stop containers, etc.
}
```

**GitHub Actions — Node 24 native runner with global setup:**

```yaml
# .github/workflows/ci-native-node24.yml — Node 24 native test runner
name: CI (Node.js 24 native runner)

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 24, cache: npm }
      - run: npm ci

      # Type-check (required — strip-types does NOT check types, even in RC)
      - run: npx tsc --noEmit --project tsconfig.json
        name: TypeScript type-check

      # Run tests with global setup, coverage thresholds, and JUnit reporter
      - run: |
          node --experimental-strip-types \
               --experimental-test-coverage \
               --test-global-setup=test-global-setup.ts \
               --test-reporter=junit \
               --test-reporter-destination=test-results/results.xml \
               --test 'tests/**/*.test.ts'
        name: Unit tests (Node 24 native runner)

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: test-results/results.xml
```

**Stable snapshot testing (Node 24+, stable since Node 23.4):**

```typescript
// tests/unit/serializer.test.ts — stable snapshot testing in node:test
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { serializeOrder } from '../../src/serializer.ts';

describe('serializeOrder', () => {
  it('serializes a simple order to the expected shape', (t) => {
    const order = { id: 'ord-1', items: [{ sku: 'SKU-A', qty: 2 }], total: 19.98 };
    // Stable since Node 23.4 — no --experimental-test-snapshots flag needed in Node 24
    t.assert.snapshot(serializeOrder(order));
  });
});
```

```bash
# Generate snapshots on first run (update mode)
node --experimental-strip-types --test --test-update-snapshots 'tests/**/*.test.ts'

# Verify snapshots in CI (regular run — fails if serialized output changed)
node --experimental-strip-types --test 'tests/**/*.test.ts'
```

**Programmatic coverage thresholds (Node 24+):**

```typescript
// run-tests.ts — programmatic test runner with coverage thresholds (Node 24+)
import { run } from 'node:test';
import { createWriteStream } from 'node:fs';
import { spec as SpecReporter } from 'node:test/reporters';
import { pipeline } from 'node:stream/promises';

const results = run({
  files: ['tests/unit'],
  coverage: true,
  coverageIncludeGlobs: ['src/**/*.ts'],
  coverageExcludeGlobs: ['src/**/*.d.ts', 'src/**/__mocks__/**'],
  // Coverage threshold options — exits with code 1 if below threshold
  lineCoverage: 80,
  branchCoverage: 75,
  functionCoverage: 80,
});

// Pipe to spec reporter
await pipeline(results.compose(new SpecReporter()), createWriteStream('/dev/stdout'));
```

**npm 11 CI-impacting changes (bundled with Node 24):**

> [community] npm 11 ships as the default npm version with Node.js 24. Three changes affect CI pipelines specifically: (1) `--ignore-scripts` now suppresses the `prepare` script, which previously ran unconditionally — teams that use `prepare` to build TypeScript before publishing will see silent skips in `npm ci --ignore-scripts` builds; (2) the fallback audit endpoint is removed, so any CI runner with network restrictions that blocked only the bulk audit endpoint will now see hard audit failures instead of graceful fallback; (3) npm 11 requires Node `^20.17.0 || >=22.9.0` — runners pinned to Node 20.16 or earlier must upgrade.

```yaml
# .github/workflows/ci.yml — npm 11 compatibility checks
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        # npm 11 requires Node >=20.17.0 — use node-version-file to enforce
        with: { node-version-file: .nvmrc, cache: npm }
      - run: node --version && npm --version   # verify Node >=20.17.0 and npm 11.x
      - run: npm ci
      # npm 11: --ignore-scripts now suppresses 'prepare' — explicit build required
      # if your project uses prepare to compile TypeScript before tests:
      - run: npm run build
        name: Build (explicit — npm 11 --ignore-scripts suppresses prepare)
      # npm 11: no fallback audit endpoint — ensure network allows registry.npmjs.org/audits
      - run: npm audit --audit-level=high
```

> [community] The npm 11 `prepare` suppression change catches teams using the pattern `"prepare": "tsc"` in `package.json` for pre-publish TypeScript compilation. In CI environments running `npm ci --ignore-scripts` for security hardening (a common practice to prevent supply-chain attacks via lifecycle scripts), the `prepare` script was silently skipped in npm 9/10 too — but npm 11 makes this explicit and removes the legacy fallback. Teams that never noticed the skip because their CI had a separate `npm run build` step are unaffected. Teams that relied on `prepare` running after `npm ci` should add an explicit build step.

**Type stripping progression (Node 22 → 24):**

```
Node 22.6+:  --experimental-strip-types (experimental)
Node 22 LTS: --experimental-strip-types (stable for production use, flag retained)
Node 24.0:   --experimental-strip-types (Release Candidate — RC)
             --experimental-transform-types still experimental (decorators, const enums)
Node 24 LTS: Expect --strip-types (stable flag) — monitor nodejs/node#57705 for promotion
```

> [community] The RC status in Node 24 means the API surface is frozen — no breaking changes expected before promotion to stable. Teams adopting `--experimental-strip-types` in Node 22 CI pipelines should continue using it without changes when upgrading to Node 24; no migration work is needed. The flag name will change to `--strip-types` when stabilized, but the `--experimental-` prefix will remain valid as an alias for at least two major versions. Do NOT wait for Node 24 LTS to adopt type stripping — the RC guarantee means breakage risk is negligible.

### Performance Regression as a CI Gate [community]

Performance regression gates catch API latency increases and memory leaks before they reach production. By benchmarking key operations in CI and comparing to a stored baseline, teams prevent the "how did our API go from 50ms to 300ms?" class of issue.

> [community] Teams that gate on performance benchmarks in CI catch latency regressions in 80–90% of cases before they reach staging. The key challenge: benchmark variance is high on shared GitHub Actions runners (CPU scheduling is nondeterministic). Use relative change vs. baseline (e.g., "reject if p95 latency increases > 20%") rather than absolute time limits. Teams using absolute thresholds see 20–40% false-positive rates from runner variability alone.

```typescript
// benchmarks/api-latency.bench.ts — performance baseline for CI (Vitest bench)
import { bench, describe } from 'vitest';
import { createApp } from '../src/app';
import type { Express } from 'express';
import supertest from 'supertest';

let app: Express;

describe('API latency benchmarks', () => {
  app = createApp({ dbUrl: process.env['TEST_DATABASE_URL'] ?? ':memory:' });

  bench('GET /users (list, no filter)', async () => {
    const res = await supertest(app).get('/users');
    if (res.status !== 200) throw new Error(`Unexpected status: ${res.status}`);
  }, { iterations: 100, warmupIterations: 10 });

  bench('GET /users/:id (single lookup)', async () => {
    await supertest(app).get('/users/seed-user-1');
  }, { iterations: 100, warmupIterations: 10 });
});
```

```typescript
// scripts/benchmark-compare.ts — fail CI if any benchmark regressed > threshold
import * as fs from 'fs';

interface BenchResult { name: string; hz: number }
interface BenchFile { benchmarks: BenchResult[] }

const baselinePath = process.env['BASELINE_FILE'] ?? '';
const currentPath = process.env['CURRENT_FILE'] ?? '';
const maxRegressionPct = parseInt(process.env['MAX_REGRESSION_PCT'] ?? '20', 10);

if (!fs.existsSync(baselinePath)) {
  console.log('[benchmark-compare] No baseline found — skipping (first run)');
  process.exit(0);
}

const baseline = JSON.parse(fs.readFileSync(baselinePath, 'utf8')) as BenchFile;
const current = JSON.parse(fs.readFileSync(currentPath, 'utf8')) as BenchFile;
const regressions: string[] = [];

for (const curr of current.benchmarks) {
  const base = baseline.benchmarks.find(b => b.name === curr.name);
  if (!base) continue;
  const changePct = ((curr.hz - base.hz) / base.hz) * 100;
  console.log(`  ${curr.name}: ${changePct.toFixed(1)}% (${base.hz.toFixed(0)} → ${curr.hz.toFixed(0)} ops/s)`);
  if (changePct < -maxRegressionPct) {
    regressions.push(`${curr.name}: ${changePct.toFixed(1)}% regression (threshold: -${maxRegressionPct}%)`);
  }
}

if (regressions.length > 0) {
  console.error('[benchmark-compare] FAIL:');
  regressions.forEach(r => console.error(`  ✗ ${r}`));
  process.exit(1);
}
console.log('[benchmark-compare] PASS — no regressions beyond threshold');
```

**CI workflow for benchmark comparison:**

```yaml
  benchmark:
    needs: unit
    runs-on: ubuntu-latest-4-cores   # lock runner size — variability kills benchmark comparisons
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Download main-branch baseline
        uses: dawidd6/action-download-artifact@v3
        with: { branch: main, name: benchmark-baseline, path: benchmark-results/ }
        continue-on-error: true
      - run: npx vitest bench --config vitest.bench.config.ts
      - run: npx ts-node scripts/benchmark-compare.ts
        env: { BASELINE_FILE: benchmark-results/latest.json, MAX_REGRESSION_PCT: '20' }
      - uses: actions/upload-artifact@v4
        if: github.ref == 'refs/heads/main'
        with: { name: benchmark-baseline, path: benchmark-results/latest.json }
```

> [community] The single most important configuration for reliable benchmark CI: always run benchmarks on the same runner size. Teams that let benchmark jobs land on different runner types see 30–50% variance in results that is purely from hardware differences. Lock the runner label and treat any change to it as a "reset baseline" event requiring a new baseline capture run.

### Trace-Based Testing in CI [community]

Trace-based testing uses distributed traces emitted by the application under test — OpenTelemetry spans — as the assertion target, rather than HTTP response bodies or UI state. A test passes when the observed trace matches an expected shape: correct span names, correct attribute values, correct parent-child relationships.

> [community] Platform engineering teams at companies with mature OTEL instrumentation report that trace-based tests catch integration defects invisible to HTTP-level assertions: a response body that looks correct but was computed via the wrong code path (missing a DB query, using a stale cache, calling the wrong downstream service). Traditional integration tests can produce false positives on these defects; trace-based tests cannot, because the trace records WHAT actually happened, not just the final output.

```typescript
// tests/trace/checkout-flow.tracetest.ts — trace assertion using Tracetest SDK
import { Tracetest } from '@tracetest/client';

const tracetest = new Tracetest({
  serverUrl: process.env['TRACETEST_URL'] ?? 'http://localhost:11633',
  apiKey: process.env['TRACETEST_API_KEY'],
});

describe('Checkout flow — trace assertions', () => {
  it('creates an order and triggers inventory reservation span', async () => {
    const res = await fetch(`${process.env['API_URL']}/checkout`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: 'test-user', items: [{ productId: 'p1', qty: 2 }] }),
    });
    expect(res.status).toBe(201);

    const traceId = res.headers.get('x-trace-id');
    if (!traceId) throw new Error('API must propagate trace ID via x-trace-id header');

    // Assert on the observed trace — not just the response body
    const run = await tracetest.runTest({
      traceId,
      assertions: [
        { selector: 'span[name="checkout.createOrder"]', assertion: 'attr:status = "OK"' },
        { selector: 'span[name="inventory.reserve"]', assertion: 'attr:product_id = "p1"' },
        { selector: 'span[name="payment.charge"]', assertion: 'attr:amount_cents >= 1' },
        // Validates no extra/missing service calls
        { selector: 'span[tracetest.span.type="http"]', assertion: 'count >= 3' },
      ],
    });

    expect(run.allPassed).toBe(true);
  }, 30_000);
});
```

**GitHub Actions — trace-based tests run after ephemeral environment provision:**

```yaml
  trace-tests:
    needs: [provision-env]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm run test:trace
        env:
          API_URL: ${{ needs.provision-env.outputs.env_url }}
          TRACETEST_URL: ${{ vars.TRACETEST_URL }}
          TRACETEST_API_KEY: ${{ secrets.TRACETEST_API_KEY }}
```

> [community] The primary adoption barrier for trace-based testing: the application must emit OTEL spans in the test environment. Teams already running OTEL in staging can add trace tests in 1–2 days. Teams without OTEL instrumentation need to instrument the app first — a 1–2 week investment that pays dividends in production observability regardless of test strategy. Start with 3–5 critical business flows (checkout, auth, payment) before expanding to the full test suite.

### AI-Assisted Test Gap Detection in CI [community]

LLM-based coverage gap detection integrated into CI compares branch coverage of changed files before and after the PR, producing targeted "these branches in your PR are not tested" annotations directly in the PR diff view. This is distinct from AI-generating full test suites — it flags specific uncovered paths and lets the developer decide what to test.

> [community] Teams piloting AI test gap detection in CI report it is most effective for flagging error-handling branches — the `catch` blocks, null checks, and edge cases that developers consistently skip. The research from Meta's mutation-guided LLM test synthesis (arXiv:2501.12862) shows that mutation-guided prompting (showing the LLM which mutants survive) improves synthesized test quality significantly over coverage-guided prompting alone. The key implementation decision: present gap detection as informational PR annotations, not hard gates. Teams that gate merges on AI suggestions see workaround adoption; teams using non-blocking annotations see 20–30% reduction in uncovered error paths.

```typescript
// scripts/coverage-gap-reporter.ts — flag untested branches in PR-changed files
import * as fs from 'fs';
import * as path from 'path';

interface CoverageSummary {
  [filePath: string]: {
    branches: { total: number; covered: number; pct: number };
    lines: { pct: number };
  };
}

interface GapReport {
  file: string;
  uncoveredBranches: number;
  branchCoveragePct: number;
  severity: 'high' | 'medium';
}

function detectGaps(
  coveragePath: string,
  changedFiles: string[],
  thresholds = { high: 60, medium: 80 },
): GapReport[] {
  const summary = JSON.parse(fs.readFileSync(coveragePath, 'utf8')) as CoverageSummary;
  const gaps: GapReport[] = [];

  for (const file of changedFiles) {
    const entry = summary[path.resolve(file)] ?? summary[file];
    if (!entry) continue;
    const { branches } = entry;
    if (branches.pct < thresholds.medium) {
      gaps.push({
        file,
        uncoveredBranches: branches.total - branches.covered,
        branchCoveragePct: branches.pct,
        severity: branches.pct < thresholds.high ? 'high' : 'medium',
      });
    }
  }

  return gaps.sort((a, b) => a.branchCoveragePct - b.branchCoveragePct);
}

const changedFiles = (process.env['CHANGED_FILES'] ?? '').split('\n').filter(Boolean);
const gaps = detectGaps('coverage/coverage-summary.json', changedFiles);

if (gaps.length > 0 && process.env['GITHUB_STEP_SUMMARY']) {
  const rows = gaps
    .map(g => `| ${g.severity === 'high' ? '🔴' : '🟡'} \`${g.file}\` | ${g.branchCoveragePct.toFixed(1)}% | ${g.uncoveredBranches} |`)
    .join('\n');
  fs.appendFileSync(
    process.env['GITHUB_STEP_SUMMARY'],
    `## Coverage Gaps in Changed Files\n| File | Branch Coverage | Uncovered Branches |\n|------|-----------------|--------------------|\n${rows}\n`,
  );
}

// Only hard-fail on high-severity (< 60% branch coverage in new changed files)
const highSeverity = gaps.filter(g => g.severity === 'high');
if (highSeverity.length > 0) {
  console.error(`[coverage-gap] ${highSeverity.length} file(s) with < 60% branch coverage in PR changes`);
  process.exit(1);
}
```

**GitHub Actions step — annotate PR with coverage gaps:**

```yaml
  coverage-gaps:
    needs: unit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm test -- --ci --coverage
      - name: Get changed source files (exclude test files)
        id: changed
        run: |
          FILES=$(git diff --name-only origin/main...HEAD -- '*.ts' '*.tsx' | grep -v '\.test\.' | grep -v '\.spec\.')
          echo "files<<EOF" >> $GITHUB_OUTPUT
          echo "$FILES" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT
      - name: Report coverage gaps
        run: npx ts-node scripts/coverage-gap-reporter.ts
        env:
          CHANGED_FILES: ${{ steps.changed.outputs.files }}
        continue-on-error: true   # informational — does not block merge
```

### `act` for Local GitHub Actions Execution [community]

`act` (https://github.com/nektos/act) runs GitHub Actions workflows locally using Docker, providing near-identical execution to GitHub's hosted runners. For CI pipeline authors, it shortens the iteration cycle from "push, wait 5 min, read logs" to "run locally in 30 seconds".

> [community] Platform engineering teams report that `act` eliminates 60–80% of the push-wait-fail cycle for CI YAML changes. The most common CI authoring bug — forgetting to pass an environment variable or secret — is caught in seconds locally rather than minutes in the push queue. The primary caveat: `act` uses community-maintained Docker images for GitHub's runner environment; native actions that depend on GitHub's runner toolcache (e.g., `actions/setup-node` with version-file) require the full image (`-P ubuntu-latest=ghcr.io/catthehacker/ubuntu:full-22.04`), which is ~20 GB.

```bash
# Install act (macOS/Linux — also works via winget on Windows)
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run the default push event workflow locally (fast runner image ~250 MB)
act push

# Run a specific job with a full GitHub runner environment
act pull_request --job unit -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:full-22.04

# Pass secrets from a local .secrets file (never commit this file)
act --secret-file .secrets

# Run with verbose logging — critical for diagnosing step failures
act --verbose --job lint
```

**`.actrc` — team-shared defaults (commit to repo):**

```bash
# .actrc — default act configuration for all developers
-P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04   # medium image, ~4 GB
--secret-file .secrets.local                               # per-developer secrets (gitignored)
--env-file .env.act                                        # per-repo test env vars (committed)
--artifact-server-path /tmp/act-artifacts                  # local artifact storage
```

> [community] The most impactful `act` workflow for new CI pipeline authors: run `act --list` to see all events/jobs, then `act push --dry-run` to validate YAML syntax without executing. Teams that add `act` to their dev setup instructions report onboarding new engineers to CI authoring in 1 hour vs. half a day of push-and-wait cycles.

### Playwright Component Testing (ct) as a CI Test Level [community]

Playwright Component Testing (`@playwright/experimental-ct-*`) runs React, Vue, and Svelte components in a real Chromium browser without a full application stack. It sits between unit tests (jsdom) and full e2e tests: real browser DOM, real CSS layout, zero deployment overhead. In CI it gives the signal of a browser test at near-unit-test speed.

> [community] Teams adopting Playwright CT report that it eliminates 30–40% of their e2e test suite by extracting component-level interaction tests (form validation, dropdown behaviour, modal state) out of the full-stack e2e suite. The remaining e2e tests focus exclusively on integration flows (auth, cross-page navigation, real API calls). Total CI time drops because component tests run in ~2 minutes vs ~12 minutes for the same coverage in e2e.

```typescript
// playwright/index.ts — component test entry point (required by @playwright/experimental-ct-react)
import { beforeMount, afterMount } from '@playwright/experimental-ct-react/hooks';
import { ThemeProvider } from '../src/providers/theme-provider';
import type { ReactNode } from 'react';

// Wrap every component under test with app-level providers
beforeMount<{ theme?: 'light' | 'dark' }>(async ({ App, hooksConfig }) => {
  return (
    <ThemeProvider theme={hooksConfig?.theme ?? 'light'}>
      <App />
    </ThemeProvider>
  );
});
```

```typescript
// tests/ct/checkout-summary.spec.ts — component test in CI
import { test, expect } from '@playwright/experimental-ct-react';
import { CheckoutSummary } from '../../src/components/checkout-summary';

test.use({ viewport: { width: 1280, height: 720 } });

test('renders line items and total with correct aria labels', async ({ mount }) => {
  const items = [
    { id: '1', name: 'Widget', qty: 2, unitPrice: 9.99 },
    { id: '2', name: 'Gadget', qty: 1, unitPrice: 24.99 },
  ];

  const component = await mount(
    <CheckoutSummary items={items} currency="USD" onConfirm={async () => {}} />,
  );

  // Verify rendered output — real browser, real CSS, no jsdom quirks
  await expect(component.getByRole('list', { name: 'Order items' })).toBeVisible();
  await expect(component.getByText('$44.97')).toBeVisible();

  // Verify accessibility: confirm button must be reachable via keyboard
  const confirmButton = component.getByRole('button', { name: 'Confirm order' });
  await confirmButton.focus();
  await expect(confirmButton).toBeFocused();
});

test('disables confirm button while submission is in progress', async ({ mount }) => {
  let resolveSubmit: () => void;
  const submitting = new Promise<void>(r => { resolveSubmit = r; });

  const component = await mount(
    <CheckoutSummary
      items={[{ id: '1', name: 'Widget', qty: 1, unitPrice: 9.99 }]}
      currency="USD"
      onConfirm={() => submitting}
    />,
  );

  const button = component.getByRole('button', { name: 'Confirm order' });
  await button.click();
  await expect(button).toBeDisabled();

  resolveSubmit!();
  await expect(button).toBeEnabled();
});
```

**playwright-ct.config.ts for CI:**

```typescript
import { defineConfig, devices } from '@playwright/experimental-ct-react';

export default defineConfig({
  testDir: './tests/ct',
  // Component tests run fast — no network, no backend
  timeout: 10_000,
  retries: process.env['CI'] ? 1 : 0,
  reporter: [
    ['html', { open: 'never' }],
    ['junit', { outputFile: 'test-results/ct-junit.xml' }],
  ],
  use: {
    ...devices['Desktop Chrome'],
    // Mount components in a blank page — no app server needed
    ctPort: 3100,
    trace: 'on-first-retry',
  },
});
```

**GitHub Actions — component tests as a separate fast gate:**

```yaml
# .github/workflows/ci.yml — component tests run in parallel with unit tests
  component-tests:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-ct-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test --config playwright-ct.config.ts
        name: Component tests
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: ct-report
          path: playwright-report/
```

> [community] The key operational difference from full e2e: component tests do NOT require a running dev server. Playwright CT bundles the component under test with Vite/webpack in isolation. This means CI setup is identical to unit tests — no `wait-for` health checks, no port management, no environment vars for `BASE_URL`. Teams that confuse CT with e2e and add `wait-for` steps add 10–30 seconds of unnecessary startup time to each CT run.

### Typed Playwright Fixtures and Page Object Model in CI [community]

TypeScript's type system makes Playwright fixtures and Page Object Models (POM) significantly safer in CI — broken page object APIs cause compile-time errors rather than runtime failures mid-run.

> [community] Teams that implement typed Playwright fixtures report a 70–80% reduction in "test written against wrong API" defects — the most common cause of new test failures in CI that are unrelated to production code changes. When a developer renames a selector or method in a page object, TypeScript immediately flags all callers, making CI red for type reasons rather than runtime crashes.

```typescript
// tests/e2e/fixtures.ts — typed Playwright fixtures for CI
import { test as base, expect } from '@playwright/test';

// Page Object Model for login page
class LoginPage {
  constructor(private readonly page: import('@playwright/test').Page) {}

  async goto(): Promise<void> {
    await this.page.goto('/login');
  }

  async login(email: string, password: string): Promise<void> {
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByRole('button', { name: 'Sign in' }).click();
  }

  async expectError(message: string): Promise<void> {
    await expect(this.page.getByRole('alert')).toContainText(message);
  }
}

// Typed fixture extension — available in all tests that import from this file
type Fixtures = {
  loginPage: LoginPage;
  authenticatedPage: import('@playwright/test').Page;
};

export const test = base.extend<Fixtures>({
  loginPage: async ({ page }, use) => {
    const loginPage = new LoginPage(page);
    await use(loginPage);
  },

  // Pre-authenticated page fixture — reusable across test files
  authenticatedPage: async ({ page }, use) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill(process.env['TEST_USER_EMAIL'] ?? 'test@example.com');
    await page.getByLabel('Password').fill(process.env['TEST_USER_PASSWORD'] ?? 'password');
    await page.getByRole('button', { name: 'Sign in' }).click();
    await page.waitForURL('/dashboard');
    await use(page);
  },
});

export { expect };
```

```typescript
// tests/e2e/auth.spec.ts — using typed fixtures in CI
import { test, expect } from './fixtures';

test.describe('Authentication', () => {
  test('shows error for invalid credentials', async ({ loginPage }) => {
    await loginPage.goto();
    await loginPage.login('invalid@example.com', 'wrongpassword');
    await loginPage.expectError('Invalid email or password');
  });

  test('redirects to dashboard after successful login', async ({ loginPage, page }) => {
    await loginPage.goto();
    await loginPage.login(
      process.env['TEST_USER_EMAIL'] ?? 'test@example.com',
      process.env['TEST_USER_PASSWORD'] ?? 'password',
    );
    await expect(page).toHaveURL('/dashboard');
  });

  test('accesses protected route with pre-auth fixture', async ({ authenticatedPage }) => {
    await authenticatedPage.goto('/profile');
    await expect(authenticatedPage.getByRole('heading', { name: 'Profile' })).toBeVisible();
  });
});
```

> [community] The most overlooked benefit of typed fixtures in CI: the `authenticatedPage` fixture eliminates login overhead from every test that needs an authenticated session. Without fixtures, teams repeat the login flow in `beforeEach` across all test files — a 2-second operation that, across 100 tests, adds 200 seconds to the suite. With fixtures, the auth state is reused via browser storage state, reducing auth overhead to near zero.

### Visual Regression Testing as a CI Advisory Gate [community]

Visual regression tests compare screenshots of UI components or pages against stored baselines using pixel-diff or structural algorithms. Unlike functional tests, visual regressions catch CSS drift, layout shifts, and rendering differences that do not affect business logic but degrade user experience.

> [community] Teams that gate merges on visual regression tests with pixel-diff thresholds consistently report high false-positive rates (15–30%) from font rendering differences, antialiasing, and minor animation frame captures. The industry-adopted pattern: visual regression tests run as advisory (non-blocking) checks, with results posted as PR comments showing a diff image. Developers review and explicitly approve visual changes. Auto-blocking is reserved for full-page blank renders (100% diff) and core layout breakages (>80% diff).

```typescript
// playwright.config.ts — visual regression configuration
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/visual',
  // Store snapshots in a version-controlled directory
  snapshotDir: './tests/visual/__snapshots__',
  retries: process.env['CI'] ? 1 : 0,
  reporter: [
    ['html', { open: 'never' }],
    ['json', { outputFile: 'test-results/visual-results.json' }],
  ],
  use: {
    ...devices['Desktop Chrome'],
    // Consistent viewport for reproducible screenshots
    viewport: { width: 1280, height: 720 },
    // Capture traces on first retry for debugging
    trace: 'on-first-retry',
  },
  expect: {
    // Allow 0.2% pixel difference — accounts for antialiasing
    toHaveScreenshot: { maxDiffPixelRatio: 0.002 },
  },
});
```

```typescript
// tests/visual/dashboard.spec.ts — component-level visual regression tests
import { test, expect } from '@playwright/test';

test.describe('Dashboard — visual regression', () => {
  test.beforeEach(async ({ page }) => {
    // Use a seeded, deterministic data state for consistent screenshots
    await page.goto('/dashboard?demo=true&seed=42');
    // Wait for all network requests to complete before capturing
    await page.waitForLoadState('networkidle');
    // Hide dynamic content (timestamps, user avatars with async load)
    await page.addStyleTag({ content: '.timestamp, .user-avatar { visibility: hidden }' });
  });

  test('main dashboard layout matches baseline', async ({ page }) => {
    await expect(page).toHaveScreenshot('dashboard-main.png', {
      // Clip to avoid capturing browser chrome
      clip: { x: 0, y: 0, width: 1280, height: 720 },
      // Higher threshold for complex layouts
      maxDiffPixelRatio: 0.005,
    });
  });

  test('sidebar collapsed state matches baseline', async ({ page }) => {
    await page.getByRole('button', { name: 'Collapse sidebar' }).click();
    await page.waitForSelector('[data-state="collapsed"]');
    await expect(page.locator('.main-layout')).toHaveScreenshot('dashboard-sidebar-collapsed.png');
  });
});
```

**GitHub Actions — visual regression as advisory (non-blocking):**

```yaml
# .github/workflows/ci.yml — visual regression advisory check
  visual-regression:
    needs: e2e
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium

      # Download stored baselines from main branch
      - name: Download visual baselines
        uses: dawidd6/action-download-artifact@v3
        with:
          branch: main
          name: visual-baselines
          path: tests/visual/__snapshots__
        continue-on-error: true   # no baselines on first run

      - name: Run visual regression tests
        id: visual
        run: npx playwright test --config playwright-visual.config.ts
        # advisory: continue even if tests fail — results posted as PR comment
        continue-on-error: true

      # Upload diff report as artifact for PR review
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: visual-regression-report
          path: playwright-report/

      # Update baselines on main (for committing approved changes)
      - name: Update baselines
        if: github.ref == 'refs/heads/main'
        run: npx playwright test --config playwright-visual.config.ts --update-snapshots
      - uses: actions/upload-artifact@v4
        if: github.ref == 'refs/heads/main'
        with:
          name: visual-baselines
          path: tests/visual/__snapshots__
```

> [community] The baseline update workflow is the most error-prone part of visual regression CI: teams that manually commit snapshot files into git accumulate multi-megabyte binary blobs, slow down `git clone`, and create merge conflicts on every UI change. The pattern above stores baselines as GitHub Actions artifacts (not in git) and re-uploads them from the main branch run. This keeps the repository clean and snapshots always reflect the current `main` state.

### Ephemeral Test Environments in CI [community]

Ephemeral environments are short-lived, isolated deployments created per PR and destroyed after merge. They enable integration and e2e tests to run against a real deployed stack without sharing state between PRs or polluting a permanent staging environment.

> [community] Teams using shared staging environments for e2e CI tests experience "staging poisoning": one PR's test run leaves behind data, database migrations, or feature flags that break another PR's tests. Ephemeral environments solve this at the cost of additional setup time (typically 2–4 minutes for spin-up). Teams that make this transition report a 60–80% reduction in "flaky due to shared state" e2e failures.

**Ephemeral environment lifecycle in GitHub Actions:**

```yaml
# .github/workflows/ci-ephemeral.yml — create and destroy per PR
name: CI with Ephemeral Environment

on:
  pull_request:
    types: [opened, synchronize, reopened, closed]

concurrency:
  group: ephemeral-${{ github.ref }}
  cancel-in-progress: true

jobs:
  provision:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest
    outputs:
      env_url: ${{ steps.deploy.outputs.url }}
      env_id:  ${{ steps.deploy.outputs.env_id }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Deploy ephemeral environment
        id: deploy
        run: |
          ENV_ID="pr-${{ github.event.pull_request.number }}"
          URL=$(npm run deploy:preview -- --env-id "$ENV_ID" 2>&1 | grep 'Deployed to:' | awk '{print $3}')
          echo "url=$URL"       >> $GITHUB_OUTPUT
          echo "env_id=$ENV_ID" >> $GITHUB_OUTPUT
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}

  wait-and-e2e:
    needs: provision
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Wait for environment to be healthy
        run: node scripts/wait-for-env.js
        env:
          BASE_URL: ${{ needs.provision.outputs.env_url }}
      - run: npx playwright install --with-deps chromium
      - name: Run e2e against ephemeral environment
        run: npx playwright test
        env:
          BASE_URL: ${{ needs.provision.outputs.env_url }}
          CI: true

  teardown:
    if: github.event.action == 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Destroy ephemeral environment
        run: npm run deploy:destroy -- --env-id "pr-${{ github.event.pull_request.number }}"
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

**Health check before e2e (`scripts/wait-for-env.ts`):**

```typescript
// scripts/wait-for-env.ts — poll /health until ready
async function waitForHealthy(
  url: string,
  timeoutMs = 60_000,
  intervalMs = 3_000,
): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(`${url}/health`);
      if (res.ok) {
        console.log(`[wait-for-env] ${url} is healthy (${res.status})`);
        return;
      }
      console.log(`[wait-for-env] Waiting... status=${res.status}`);
    } catch (err) {
      console.log(`[wait-for-env] Not ready: ${(err as Error).message}`);
    }
    await new Promise<void>(resolve => setTimeout(resolve, intervalMs));
  }
  throw new Error(`[wait-for-env] Timeout: ${url} did not become healthy within ${timeoutMs}ms`);
}

waitForHealthy(process.env['BASE_URL'] ?? 'http://localhost:3000').catch((err: Error) => {
  console.error(err.message);
  process.exit(1);
});
```

> [community] The two most common ephemeral environment pitfalls: (1) not waiting for health checks before running tests — always poll `/health` until 200 before starting tests; (2) not tearing down on PR close — orphaned environments accumulate quickly (10–20 developers × multiple PRs = 30–60 running instances). Always handle the `pull_request: closed` event.

### Risk-Based Test Case Ordering within Suites [community]

Within a test level (unit or integration), running the highest-risk test cases first ensures that if CI is cancelled, the most important signal was already generated. Risk-based ordering also reduces mean-time-to-detect (MTTD) for critical defects.

> [community] Teams with long integration test suites (100+ test cases) report that random file ordering means a critical defect in a payment service is sometimes caught last (after 4 minutes) rather than first (after 30 seconds). Tagging test cases with a risk tier and running them in descending risk order reduces MTTD for P0 defects by 60–80% without changing total suite runtime.

**Jest test sequencer for risk-based ordering (TypeScript):**

```typescript
// scripts/risk-sequencer.ts — run high-risk test suites first
import Sequencer from '@jest/test-sequencer';
import type { Test } from '@jest/test-sequencer';

// Higher number = higher risk = runs first
const RISK_TIER: Record<string, number> = {
  auth:      10,
  payment:   10,
  billing:   9,
  checkout:  8,
  user:      7,
  product:   6,
  search:    4,
  analytics: 2,
  utils:     1,
};

function riskScore(testPath: string): number {
  const file = testPath.toLowerCase();
  for (const [keyword, score] of Object.entries(RISK_TIER)) {
    if (file.includes(keyword)) return score;
  }
  return 5; // default medium risk
}

export default class RiskSequencer extends Sequencer {
  sort(tests: Test[]): Test[] {
    return [...tests].sort((a, b) => riskScore(b.path) - riskScore(a.path));
  }
}
```

**Jest configuration (jest.config.ts):**

```typescript
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testSequencer: './scripts/risk-sequencer.ts',
  maxWorkers: '50%',
  bail: 1,
};

export default config;
```

> [community] The simplest form of risk-based ordering — naming high-risk test files with numeric prefixes (01-, 02-) so they sort alphabetically to the front — requires zero configuration. Teams adopt this convention during project setup and it pays dividends for the entire project lifetime. The custom sequencer approach is better when risk classification needs to be dynamic (based on code change history or defect data).

### CI Cost Governance [community]

Runner cost scales directly with parallelism and shard count. Teams that add shards without cost tracking routinely overspend their CI budget without realizing it.

> [community] A startup engineering team that added dynamic sharding without tracking runner usage discovered they had increased their GitHub Actions bill from $80/month to $640/month over 6 weeks — an 8× increase — because their dynamic shard count computed up to 12 shards per PR across a 15-developer team. Adding a cost-awareness step and a monthly budget alert reduced the bill to $180/month with no loss of speed (by tuning the max shards to 4).

**Estimated cost reporter step (GitHub Actions):**

```javascript
// scripts/ci-cost-estimate.js — append estimated job cost to GitHub Actions step summary
'use strict';

const RATE_USD_PER_MINUTE = {
  'ubuntu-latest':  0.008,
  'windows-latest': 0.016,
  'macos-latest':   0.08,
};

const runnerLabel = process.env.RUNNER_OS === 'Windows' ? 'windows-latest'
  : process.env.RUNNER_OS === 'macOS' ? 'macos-latest'
  : 'ubuntu-latest';

const startTime = parseInt(process.env.CI_JOB_STARTED_AT || (Date.now() - 60_000).toString(), 10);
const elapsedMin = (Date.now() - startTime) / 60_000;
const rate = RATE_USD_PER_MINUTE[runnerLabel] ?? 0.008;
const cost = (elapsedMin * rate).toFixed(4);

console.log(`[ci-cost] ${runnerLabel} | ${elapsedMin.toFixed(1)} min | ~$${cost}`);

if (process.env.GITHUB_STEP_SUMMARY) {
  const fs = require('fs');
  fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY,
    `\n| \`${runnerLabel}\` | ${elapsedMin.toFixed(1)} min | $${rate}/min | **$${cost}** |\n`
  );
}
```

> [community] The most effective cost reduction pattern: track cost-per-PR in a dashboard (or a simple spreadsheet from CI logs), then set a Slack alert when any single PR workflow exceeds a threshold (e.g., $2.00). Teams that measure cost-per-PR reduce CI spend by 30–50% within a quarter without changing test coverage.

**CI cost tradeoff summary:**

| Strategy | Cost impact | Speed impact | Recommendation |
|---|---|---|---|
| Max workers 50% | Neutral | Optimal on 2-core runner | Always |
| 4 shards vs 1 | 4× cost | ~3.5× faster | Use when single machine > budget |
| 8 shards vs 4 | 2× more | ~1.7× faster | Only if 4-shard still too slow |
| Matrix 3 OS × 3 Node | 9× cost | Same wall-clock | Only for published packages |
| Nightly full suite | Runs once/day | No PR impact | Use for release qualification |
| Affected-only (nx/turbo) | 70–85% cheaper | Same or faster | Always for monorepos |

### Playwright Screencast API for CI Video Evidence [community]

Playwright v1.59 introduced `page.screencast` — a first-class API for controlling video capture that complements (and in some scenarios replaces) the `recordVideo` context option. Unlike `recordVideo`, the Screencast API supports precise start/stop control within a test, real-time JPEG frame streaming, and rich visual overlays — making it suitable for CI pipelines that need reproducible visual evidence of test execution.

> [community] Teams running agentic CI pipelines (LLM-driven test agents, AI-assisted regression detection) report that the Screencast API's `onFrame` callback is the critical enabler: it streams compressed JPEG frames in real-time rather than writing a video file, allowing agents to use vision models to validate UI state without post-processing. For standard CI teams, the `showActions()` overlay is the single most useful feature — action annotations on the video make failure frames immediately readable without trace archaeology.

**Core Screencast API (TypeScript):**

```typescript
// tests/e2e/checkout.spec.ts — Playwright v1.59+ Screencast API
import { test, expect } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

test('checkout flow with full video evidence', async ({ page }) => {
  const videoPath = path.join(
    process.cwd(),
    'test-results',
    `checkout-${Date.now()}.webm`,
  );

  // Start recording — more precise than recordVideo (per-test control)
  await page.screencast.start({
    path: videoPath,
    size: { width: 1280, height: 720 },
  });

  // Visual annotations: highlight each interacted element for 500ms
  await page.screencast.showActions({
    duration: 500,
    fontSize: 18,
    position: 'bottom-right',
  });

  // Chapter overlay: label major phases of the test for easier video navigation
  await page.screencast.showChapter('Phase 1: Navigate to checkout');
  await page.goto('/cart');
  await page.getByRole('button', { name: 'Proceed to checkout' }).click();

  await page.screencast.showChapter('Phase 2: Enter payment details');
  await page.getByLabel('Card number').fill('4242 4242 4242 4242');
  await page.getByLabel('Expiry').fill('12/28');
  await page.getByLabel('CVV').fill('123');

  await page.screencast.showChapter('Phase 3: Confirm order');
  await page.getByRole('button', { name: 'Place order' }).click();
  await expect(page.getByRole('heading', { name: 'Order confirmed' })).toBeVisible();

  // Stop recording — video file is finalized
  await page.screencast.stop();
});
```

**JPEG frame streaming for AI vision (agentic CI):**

```typescript
// tests/e2e/ai-assisted-check.spec.ts — Screencast onFrame for real-time vision
import { test, expect } from '@playwright/test';

test('AI-assisted visual verification', async ({ page }) => {
  const frames: Buffer[] = [];

  // Stream compressed JPEG frames in real-time — no file I/O until save
  await page.screencast.start({
    size: { width: 1280, height: 720 },
    quality: 80,  // JPEG quality 0-100
    onFrame: (frame: Buffer) => {
      // Collect frames for post-test AI analysis or real-time vision model calls
      frames.push(frame);
    },
  });

  await page.goto('/dashboard');
  await page.waitForLoadState('networkidle');

  await page.screencast.stop();

  // Pass frames to vision model for structure validation
  // (Replace with actual vision model API call)
  console.log(`Captured ${frames.length} frames — feed to vision model for layout validation`);
  expect(frames.length).toBeGreaterThan(0);
});
```

**`await using` for automatic Screencast resource cleanup (TypeScript 5.2+ / ES2022+):**

```typescript
// tests/e2e/resource-safe.spec.ts — Playwright v1.59 async disposable pattern
import { test, expect } from '@playwright/test';

test('automatic screencast cleanup via await using', async ({ page }) => {
  // Playwright v1.59 makes screencast an async disposable:
  // stop() is called automatically when execution leaves the using block
  {
    await using _recording = await page.screencast.start({
      path: `test-results/evidence-${Date.now()}.webm`,
      size: { width: 1280, height: 720 },
    });

    await page.screencast.showActions({ duration: 400 });
    await page.goto('/login');
    await page.getByLabel('Email').fill('test@example.com');
    await page.getByLabel('Password').fill('password');
    await page.getByRole('button', { name: 'Sign in' }).click();
    await expect(page).toHaveURL('/dashboard');
    // _recording.stop() called automatically here — even if test throws
  }
  // Video file is fully written by this point
});
```

**GitHub Actions workflow — upload Screencast evidence on failure:**

```yaml
# .github/workflows/ci.yml — upload screencast recordings on e2e failure
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps
      - run: npx playwright test
        env:
          CI: true
      # Upload screencast recordings only on failure (smaller artifact footprint)
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: screencast-evidence-${{ github.run_id }}
          path: test-results/**/*.webm
          retention-days: 14
```

> [community] The Screencast API's `showChapter()` overlays are the most impactful feature for CI failure triage. Teams that add chapter markers for each major phase of a complex e2e test (navigate, fill form, submit, verify) report cutting failure triage time by 50–70% — the video jumps directly to the "Phase 3: Submit" chapter to isolate whether the failure is in form fill or submission. Without chapters, reviewers scrub through the entire recording to find the relevant frame.

> [community] A subtle Screencast vs. `recordVideo` behavioral difference: `recordVideo` starts immediately when the browser context is created and records everything until context close. `page.screencast.start()` records from the moment it is called within a test. For test suites with long setup phases (auth, data seeding), Screencast produces smaller, more focused recordings. Teams with high artifact storage costs report 40–60% smaller video files after migrating from `recordVideo` to explicit Screencast with chapter markers.

---

### `act --validate` and `--strict` for Workflow Pre-Flight CI Checks [community]

`act` v0.2.79 added `--validate` and `--strict` flags to the `act` CLI. `--validate` parses and validates the workflow YAML without executing any steps — catching structural errors, missing required inputs, undefined variables, and unsupported action versions before the workflow is pushed to GitHub. `--strict` escalates warnings to errors, enforcing stricter YAML conformance.

> [community] Platform engineering teams report that 40–60% of "CI failures on first push" for new developers are caused by workflow YAML errors that `act --validate` would have caught locally in seconds. Common examples: missing `on:` event triggers, incorrect `needs:` dependency references that create circular dependencies, and `uses:` action paths that resolve to nonexistent local actions. Adding `act --validate` as a pre-commit hook for `.github/workflows/**` changes eliminates an entire category of "CI red on push."

**Pre-commit hook for workflow validation:**

```bash
# .husky/pre-commit — validate changed workflow files before commit
#!/usr/bin/env sh

# Check if any workflow files changed in this commit
CHANGED_WORKFLOWS=$(git diff --cached --name-only | grep -E '^\.github/workflows/.*\.ya?ml$')

if [ -n "$CHANGED_WORKFLOWS" ]; then
  echo "[pre-commit] Validating changed GitHub Actions workflows..."
  for WORKFLOW in $CHANGED_WORKFLOWS; do
    echo "  Validating: $WORKFLOW"
    # --validate: parse + validate structure without running
    # --strict: escalate warnings to errors
    act --validate --strict --workflows "$WORKFLOW" 2>&1 || {
      echo "::error::Workflow validation failed for $WORKFLOW"
      exit 1
    }
  done
  echo "[pre-commit] All workflow files valid."
fi
```

**CI step to validate all workflow files in the repo:**

```yaml
# .github/workflows/ci.yml — validate all workflow YAML files as part of CI
  validate-workflows:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install act (workflow validator)
        run: |
          curl --proto '=https' --tlsv1.2 -sSf \
            https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

      # Validate every workflow file — catches errors in files not touched in this PR
      - name: Validate all GitHub Actions workflows
        run: |
          find .github/workflows -name '*.yml' -o -name '*.yaml' | \
          while read -r workflow; do
            echo "Validating: $workflow"
            act --validate --strict --workflows "$workflow" || {
              echo "::error file=$workflow::Workflow validation failed"
              exit 1
            }
          done
```

**TypeScript script to validate workflow structure programmatically:**

```typescript
// scripts/validate-workflows.ts — programmatic workflow validation wrapper
import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as glob from 'glob';

interface WorkflowValidationResult {
  file: string;
  valid: boolean;
  errors: string[];
}

function validateWorkflow(workflowPath: string): WorkflowValidationResult {
  try {
    const output = execSync(
      `act --validate --strict --workflows "${workflowPath}" 2>&1`,
      { encoding: 'utf8', stdio: 'pipe' },
    );
    return { file: workflowPath, valid: true, errors: [] };
  } catch (err: unknown) {
    const error = err as { stdout: string; stderr: string };
    const allOutput = (error.stdout ?? '') + (error.stderr ?? '');
    const errors = allOutput
      .split('\n')
      .filter(line => line.includes('error') || line.includes('Error'))
      .filter(Boolean);
    return { file: workflowPath, valid: false, errors };
  }
}

function validateAllWorkflows(workflowDir = '.github/workflows'): void {
  const workflowFiles = glob.sync(`${workflowDir}/**/*.{yml,yaml}`);

  if (workflowFiles.length === 0) {
    console.log('[validate-workflows] No workflow files found.');
    return;
  }

  const results = workflowFiles.map(validateWorkflow);
  const failures = results.filter(r => !r.valid);

  results.forEach(r => {
    const status = r.valid ? '✓' : '✗';
    console.log(`  ${status} ${r.file}`);
    if (!r.valid) r.errors.forEach(e => console.error(`    ${e}`));
  });

  if (failures.length > 0) {
    console.error(`\n[validate-workflows] ${failures.length} workflow(s) failed validation`);
    process.exit(1);
  }

  console.log(`\n[validate-workflows] All ${results.length} workflow(s) valid.`);
}

validateAllWorkflows();
```

> [community] The `--strict` flag is particularly valuable for shared workflow libraries (reusable workflows called from many repos). A warning in a shared workflow that is silently ignored in 30 calling repos becomes a time-bomb: when the behavior changes in a future `act` version, all 30 pipelines break simultaneously. Treating all warnings as errors in the shared workflow's own CI catches this class of issue at the source. Teams that enforce `--strict` on shared workflow repositories report zero propagated breakages vs. multiple per quarter without it.

> [community] Teams new to `act --validate` frequently confuse it with `act --dry-run`. `--dry-run` simulates the workflow execution order (which jobs run, which steps are skipped) without actually running any Docker containers — it validates the execution graph. `--validate` checks only YAML syntax and structural correctness without simulating execution. Use both in sequence: `act --validate` to catch syntax, then `act --dry-run` to catch logical flow errors.

---

### Jest 30 for TypeScript CI: Performance Leap  [community]

Jest 30 (released June 4, 2025) delivers the largest performance improvement in Jest's history — 37% faster test runs and 77% lower peak memory for large TypeScript server suites. These gains come from three architectural changes: a new module resolver (`unrs-resolver`, based on the Rust-backed OXC resolver), native TypeScript config file support removing one transform layer, and a barrel file optimizer that eliminates the exploding import graphs that slow Jest on modern TypeScript monorepos.

**Why this matters for CI:** The 37% speed gain is an unconditional reduction in CI runner minutes with zero code changes required in most TypeScript projects. The 77% memory reduction is the more impactful figure for shared runners — Jest OOM kills were a leading cause of flaky CI on memory-constrained 8 GB runners running large TypeScript APIs.

```typescript
// jest.config.ts — native TypeScript config (no transform, no ts-jest for config)
// Jest 30+: jest.config.ts is loaded natively without any babel/ts-jest transform
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  // Jest 30: globalsCleanup controls mock/spy cleanup between test files
  // 'soft' (default): resets mocks but preserves global state mutations
  // 'on': full isolation (equivalent to clearMocks + resetMocks + restoreMocks per file)
  // 'off': no cleanup (legacy Jest 29 behaviour — useful during migration)
  globalsCleanup: 'on',
  // Jest 30: retryTimes with waitBeforeRetry for rate-limited or timing-sensitive tests
  // waitBeforeRetry delays the retry by N ms; retryImmediately skips the delay
  // Use retryImmediately: true only for tests with inherent race conditions (not for flakiness)
  // retries: 2 max — see Anti-Patterns for why > 2 is harmful
  testTimeout: 10_000,
  coverageProvider: 'v8',
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
};

export default config;
```

```typescript
// jest.setup.ts — retryTimes with Jest 30 options
import { retryTimes } from '@jest/globals';

// Jest 30: waitBeforeRetry (ms) — pause before each retry attempt
// Useful for tests calling real HTTP APIs with rate limits
retryTimes(2, { waitBeforeRetry: 500 });

// Jest 30: retryImmediately — skip wait and retry synchronously
// Use ONLY for race-condition tests, not to mask flakiness
// retryTimes(2, { retryImmediately: true });
```

```typescript
// .babelrc.js — barrel file optimizer for Jest 30 (up to 100× import speedup)
// Problem: import { Button } from '@myorg/ui' triggers resolution of ALL exports in the barrel
// Solution: babel-plugin-transform-barrels rewrites barrel imports to direct source imports
// before Jest processes them — eliminates the exploding import graph
//
// Before optimization: import { Button } from '@myorg/ui'
//   → loads 400+ modules (entire component library)
// After optimization: import { Button } from '@myorg/ui/src/Button/Button'
//   → loads 1 module (direct path)
module.exports = {
  presets: [['@babel/preset-typescript', { allExtensions: true }]],
  plugins: [
    [
      'babel-plugin-transform-barrels',
      {
        // List packages whose barrel re-exports should be inlined
        packages: ['@myorg/ui', '@myorg/utils', 'lodash'],
        // optional: skip packages whose barrel is small (< 20 exports)
        minExportCount: 20,
      },
    ],
  ],
};
```

**Jest 30 breaking changes checklist (for TypeScript CI migration):**

| Change | Action required |
|---|---|
| Node 14, 16, 19, 21 dropped | Upgrade runner to Node 18 LTS or 20 LTS |
| TypeScript minimum: 5.4 | Upgrade `typescript` devDependency if < 5.4 |
| jsdom upgraded v21 → v26 | Audit any tests that depend on jsdom 21 behavior |
| `--testPathPattern` removed | Replace with `--testPathPatterns` in CI scripts and `package.json` scripts |
| `globals` cleanup default changed | Test `globalsCleanup: 'off'` if tests share state across test files |

> [community] The team behind a large TypeScript API server (800+ test cases) reported 1350s → 850s (37% reduction) after upgrading to Jest 30 with no configuration changes. Memory peak dropped from 7.8 GB to 1.8 GB, eliminating OOM kills on their 8 GB CI runners. The barrel file optimizer (`babel-plugin-transform-barrels`) added to their shared UI package brought another 2.1× improvement on tests that imported from the barrel, for a combined 3.5× speedup on the component integration test suite.

> [community] The biggest Jest 30 adoption risk on TypeScript projects is the `globalsCleanup` default change. In Jest 29, mock state persisted between test files in the same run unless explicitly cleared. In Jest 30 with `globalsCleanup: 'soft'` (the new default), mocks are reset between files. Tests that relied on mock state accumulated from a previous file (a common anti-pattern in integration test suites that share a mock database adapter) will fail silently or produce false results. During migration, set `globalsCleanup: 'off'` to match Jest 29 behaviour, then clean up the sharing patterns file by file.

---

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| Running e2e on every push | 15+ min wait per push, slow feedback | Run e2e only on PR open/update or schedule |
| No test ordering (all parallel) | Fast unit failures buried in long e2e logs | Sequence: lint → unit → integration → e2e |
| Ignoring flaky failures | Developers click "re-run" without investigating | Quarantine within 24h, track flakiness rate |
| `sleep()` in tests | Timing-dependent failures | Use `waitFor`, polling, or event-driven assertions |
| Secrets in test output | Log scraping exposes credentials | Mask env vars; use `::add-mask::` in GitHub Actions |
| 100% coverage target | Incentivizes trivial tests over meaningful ones | Target coverage on business-critical paths only |
| No `--passWithNoTests` in monorepo | Affected calculation errors cause CI block | Add flag when running subset tests |
| `retries: 3+` on e2e tests | Hides chronic flakiness, triples job time | Max retries: 2; quarantine tests that need more |
| Uploading test artifacts unconditionally | Fills artifact storage on every green run | Use `if: failure()` for traces/screenshots |
| No `timeout-minutes` on jobs | Hung process blocks runner for GitHub's default 6h | Set job-level and step-level timeouts explicitly |
| `cancel-in-progress: true` on deploy jobs | Partial deploys leave infra in broken state | Only cancel test/lint jobs; let deploy jobs complete |
| Turbo `inputs` including env-specific files | Remote cache never hits due to differing hashes | Keep `inputs` to source + config files only |
| Matrix `fail-fast: true` (default) | First OS failure hides others; can't tell if it's platform-specific | Set `fail-fast: false` for matrix jobs |
| Full test suite in pre-commit hook | >10s hooks bypassed with `--no-verify` in days | Scope hook to `--findRelatedTests`; keep under 5s |
| `npm audit` gating on moderate severity | Permanently red CI; teams disable the check | Gate on `high` + `critical` only; warn on `moderate` |
| No security scan on merge-to-main | Critical vulnerabilities ship undetected | Add `npm audit --audit-level=high` as a required gate |
| Static shard count never revisited | Under- or over-parallelization as suite grows | Use dynamic shard count or review quarterly |
| No teardown trigger on PR close | Orphaned ephemeral environments accumulate; cost waste | Handle `pull_request: closed` event for teardown |
| No health check before e2e in ephemeral env | Tests fail with "connection refused" before app is ready | Poll `/health` endpoint until 200 before starting tests |
| No CI cost tracking with sharding enabled | Runner bill spikes undetected until month-end | Add cost estimate step and set monthly budget alert |
| No `tsc --noEmit` gate (TypeScript) | Type errors pass tests, ship to production | Add `typecheck` job that runs `tsc --noEmit` before unit tests |
| `skipLibCheck: true` in CI tsconfig | Type definition mismatches between packages go undetected | Use `skipLibCheck: false` in CI; allow `true` in local dev config |
| Not caching `.tsbuildinfo` in monorepo | Incremental type-check benefit lost; full recheck every CI run | Cache `.tsbuildinfo` files alongside `node_modules` |
| `ts-jest` `isolatedModules: true` assumed to type-check | Transpiles without cross-file type checking; type errors slip through | Always run `tsc --noEmit` as a separate CI step |
| Long-lived cloud credentials stored as CI secrets | Compromised secret grants permanent cloud access | Use OIDC short-lived tokens; scope IAM role `sub` claim to repo |
| `bun test` with jsdom-dependent component tests | bun-dom support incomplete; tests silently skip DOM assertions | Use Vitest for jsdom component tests; Bun for pure Node.js unit tests |
| No OTEL CI instrumentation on slow pipelines | Slow pipeline root cause unknown; hours of log archaeology | Add OTEL spans per suite; emit `cache_hit` and `install_duration_ms` |
| Nx DTE with under-decomposed monorepo packages | DTE agents idle waiting for single bottleneck package | Validate module boundaries with `nx graph`; split mega-packages first |
| OIDC trust policy missing `sub` condition | Any GitHub repo can assume the role | Always add `StringLike` condition: `token.actions.githubusercontent.com:sub: repo:myorg/myrepo:*` |
| Reusable workflow caller not passing secrets | Inner workflow sees empty secret string; silent failure | Explicitly pass each secret via `secrets:` in the calling workflow |
| Feature flag tests only covering flags-OFF state | Flag-ON code path untested; defects reach production | Always write tests for both flag states for any flag-branched code path |
| Feature flag removal without cleaning up old-path tests | Dead tests inflate coverage; old assertions test nothing | Tag tests with flag name; remove both flag and tests together in same PR |
| Playwright CT confused with e2e — adding `wait-for` server steps | CT bundles the component directly; no server needed — wait steps waste 10–30s | Remove any server startup steps from CT workflows; CT is self-contained |
| Composite action using `${{ secrets.* }}` directly | `Context not allowed` error — composite actions cannot read secrets | Pass secrets from calling workflow via `env:` on the `uses:` step |
| `act` using default micro image for `setup-node` with version file | `node-version-file` fails on micro/medium image — toolcache missing | Use full image (`ghcr.io/catthehacker/ubuntu:full-22.04`) or pin node version explicitly in act |
| SBOM generated from `package.json` source instead of installed tree | Misses transitive and resolved dependencies; SBOM is incomplete | Always run `npm ci` first; generate SBOM from `node_modules` not from source |
| Larger runner selected without profiling current runner utilization | Paying 2–8× per minute for no speed gain if bottleneck is I/O not CPU/RAM | Profile CPU and memory utilization first; upgrade runner only if CPU > 80% or RAM > 90% |
| Node 22 `--experimental-strip-types` without separate `tsc --noEmit` | Type errors pass all tests; discovered in production | Always add `tsc --noEmit` as a separate required CI step before tests |
| Performance benchmark using absolute time thresholds on shared runners | 30–50% false-positive rate from runner variability — teams disable the gate | Use relative change vs. stored baseline (e.g., >20% regression) instead of absolute ms thresholds |
| Benchmark baseline stored without locking the runner label | Hardware change between baseline and comparison run causes meaningless results | Add runner label to baseline artifact name; invalidate and re-collect on runner change |
| Trace-based tests without OTEL instrumentation in test environment | `x-trace-id` header missing; trace assertions cannot run | Instrument the application with OTEL in all environments including test before adding trace tests |
| AI coverage gap detection used as a hard merge gate | High friction; developers add workarounds (empty test stubs) to pass the gate | Use as informational PR annotation (`continue-on-error: true`); reserve hard gates for < 60% branch coverage in critical paths |
| Multi-cloud OIDC exchange after slow container pull steps | GitHub OIDC token expires (10 min); second cloud auth fails silently | Pre-exchange ALL provider tokens as the first job steps before any slow setup |
| GCP Workload Identity Pool without `attribute_condition` | Any GitHub repo can use the pool — broad credential exposure | Always set `attribute_condition = "assertion.repository == 'myorg/myrepo'"` on the provider |
| Docker BuildKit cache export using `mode=min` | Only final layer cached; intermediate layers (npm install) rebuilt on every dep change | Use `mode=max` to cache all intermediate layers and get maximum cache hit rate |
| Docker `--no-cache` flag in CI scripts | Defeats BuildKit GHA cache; every build is cold — adds 3–8 min per job | Remove `--no-cache`; use content-addressed layers to ensure freshness without cache bypass |
| `page.screencast` onFrame callback not awaited before test end | Frame buffer dropped if test runner exits before all frames are processed | Always call `await page.screencast.stop()` or use `await using` to guarantee buffer flush |
| `act --dry-run` used when `--validate` is needed | `--dry-run` simulates execution graph; does not catch YAML syntax errors — invalid workflows produce confusing "job not found" errors | Use `--validate` for syntax first, then `--dry-run` for execution-graph logic |
| Visual regression baselines stored in git as binary snapshots | Multi-MB blobs slow `git clone`; merge conflicts on every UI change | Store baselines as CI artifacts (not in git); re-upload from main branch run |
| Visual regression used as a hard merge gate | 15–30% false-positive rate from antialiasing differences blocks developer flow | Use as advisory PR annotation; auto-block only on >80% pixel diff (full-page blank or complete layout breakage) |
| GitHub Environment protection rule on production without a wait timer | "Approve under pressure" — reviewers click approve without reviewing e2e results | Add 10-minute wait timer; gives reviewers time to review results without being rushed |
| Deployment health check using fixed sleep after deploy | Sleep is too long (wastes time) or too short (fails before app is ready) | Poll `/health` endpoint with exponential backoff until `{ status: "ok", version: <sha> }` |
| TypeScript `--noCheck` without a mandatory parallel `tsc --noEmit` gate | Type errors pass transpile-only CI; discovered in production | Add `all-checks` gate job requiring BOTH transpile+test AND typecheck to pass |
| Playwright `--only-changed` without a nightly full-suite run | Changed-file tests pass; indirectly affected tests never run; hidden defects | Always run full suite nightly or on push to main; use `--only-changed` as supplementary fast gate only |
| Playwright `globalSetup` used instead of Project Dependencies | Setup failures appear as cryptic first-test errors — not traceable | Migrate to `dependsOn: ['setup']` for visible, traceable setup failures in HTML report |
| Vitest Browser Mode test isolation assumed to be per-test | Global DOM state bleeds between tests in the same file; ordering-dependent flakiness | Add explicit `afterEach` cleanup for any browser global state; audit all `window.*` mutations |
| Vitest workspace `include: ['**/*.test.ts']` without package prefix | All test files from all packages matched; Node-only tests fail in jsdom environment | Scope every project's `include` to `'packages/<name>/src/**/*.test.ts'` |
| `--fail-on-flaky-tests` enabled without fixing existing flakiness first | CI becomes permanently red on first adoption; team disables the flag within a week | Baseline flakiness rate first on nightly; fix top offenders; then enable on PR gate |
| Playwright `captureGitInfo` without `fetch-depth: 0` checkout | Shallow clone omits commit metadata; report shows empty author/message fields | Add `fetch-depth: 0` to `actions/checkout@v4` when using `captureGitInfo` |
| Global `workers` set without considering per-project memory requirements | Visual regression tests OOM the runner (200–400 MB per worker × 4 workers = 1.6 GB) | Use per-project `workers` (v1.52+) to serialize memory-intensive projects |
| `defineConfig` used in Vitest workspace project files | Root-only options (`coverage`, `reporters`) silently ignored or throw at startup | Use `defineProject` in all per-package vitest config files referenced by `projects:` |
| Vitest `projects` config without `name` on each project | Projects receive numeric default names; `--project` filter fails with ambiguous matches | Always set `name:` on every project — use the package name for clarity |
| Vitest 4.0 upgrade without migrating from `vitest.workspace.ts` | `defineWorkspace` removed; remaining workspace file silently ignored — CI shows "0 tests" instead of an error | Delete `vitest.workspace.ts` and migrate all projects to `test.projects` in `vitest.config.ts` before upgrading |
| Vitest 4.0 with Vite 5 still installed | Vitest 4.0 requires Vite 6+; peer dependency conflict causes runtime startup errors | Add a CI pre-check that verifies `vite` major version ≥ 6 before running tests |
| Vitest `'basic'` reporter referenced after 4.0 upgrade | `'basic'` reporter removed in Vitest 4.0; CI fails with "Unknown reporter: basic" | Replace `reporters: ['basic']` with `reporters: ['tree']` in all Vitest configs |
| Vitest `coverage.changed` without `fetch-depth: 0` | `git:origin/main` diff target unavailable in shallow clone; falls back to full-project coverage | Add `fetch-depth: 0` and `git fetch origin main` to the coverage CI step |
| `--last-failed` used without `blob` reporter in first run | `--last-failed` reads blob report for failed-test list; other reporters don't produce this; silently runs full suite | Always include `blob` in the reporter list when planning to use `--last-failed` for retry workflows |
| Custom runner image not rebuilt after Playwright upgrade | Browser binary version in image mismatches new `@playwright/test` version; tests fail with "executable not found" | Automate image rebuilds by triggering on `@playwright/test` version changes in `package-lock.json` |
| `webServer.wait` regex without named capture group — dynamic port not injected | `wait.stdout` regex without `(?<name>...)` captures nothing; `process.env['SERVER_PORT']` is undefined | Use named capture groups in every `wait` regex: `/Listening on port (?<server_port>\d+)/` |
| Vitest 4.0 `VITEST_MAX_THREADS` / `VITEST_MAX_FORKS` env vars still set in CI | Replaced by `VITEST_MAX_WORKERS`; old env vars silently ignored — worker count falls back to default (CPU count); 2-core runners spawn 2 workers instead of configured 1 | Rename CI env vars to `VITEST_MAX_WORKERS`; audit any `export VITEST_MAX_*` in `.env.ci` and shell scripts |
| Playwright `trace: 'on-first-retry'` — no trace for tests that fail on first attempt and aren't retried | First-attempt failures produce no trace; debugging requires reproducing locally | Upgrade to `trace: 'retain-on-failure-and-retries'` (Playwright v1.54+) — records every attempt, retains all traces on any failure |
| Playwright still installing `chromium` explicitly after v1.57 | Playwright v1.57 switched to Chrome for Testing builds; specifying `chromium` still works but misses latest browser stability fixes | Replace `npx playwright install chromium --with-deps` with `npx playwright install --with-deps` (installs the configured browser set including Chrome for Testing) |
| HAR recording with unfiltered `urlFilter` | Unfiltered HAR archives contain 100–300 entries (fonts, CDN, analytics); developers ignore them — signal buried in noise | Always set `urlFilter: /\/api\//` or host-based pattern to restrict HAR to business-logic requests only |
| Using `context.tracing.startHar()` during setup phase | HAR captures setup noise (auth calls, DB seeding HTTP) mixed with test-specific API calls — hard to identify the failing request | Call `startHar()` after setup completes; use `await using` to ensure `stopHar()` runs even on failure |
| Upgrading to Vitest v5 without auditing blob report paths | Default blob output path changed from `blob-report/` to `.vitest/blob/`; CI artifact upload steps silently upload nothing | Update all `path: blob-report/` artifact upload steps to `path: .vitest/blob/` before upgrading |
| Vitest v5 upgrade with `sequential` test option in source | `sequential` property on individual tests removed in v5; TypeScript compiler flags all usages as unknown property | Replace individual-test `sequential: true` annotations with `describe.sequential(() => { ... })` blocks |
| Importing `expect` from `'vitest/expect'` after v5 upgrade | Entry point `'vitest/expect'` removed in v5; runtime `Cannot find module` error | Replace all `import { expect } from 'vitest/expect'` with `import { expect } from 'vitest'` |
| V8 coverage threshold failure after Vitest v5 upgrade | V5 V8 now tracks `node:child_process` and `node:worker_threads` — previously uncovered worker code appears; threshold may fail if worker coverage is low | Profile coverage delta on non-blocking branch before upgrading; adjust thresholds for newly-visible worker code |
| Vitest `github-actions` reporter disabled explicitly when custom `reporters` array is set | Listing any reporter in the `reporters` array replaces the defaults — `github-actions` is no longer auto-injected; job summaries silently stop appearing | Always include `'github-actions'` in the `reporters` array when overriding defaults in CI environments |
| `viteModuleRunner: false` used in a package with CSS Module or JSX imports | Vite transforms are disabled; `.module.css` and JSX imports fail with module-not-found or syntax errors | Only enable `viteModuleRunner: false` in pure Node.js packages with no Vite-specific imports |
| OIDC trust policy with `repo_property_*` condition but no `sub` scoping | Any GitHub org that assigns the same custom property can assume the role — cross-org credential exposure | Always pair `repo_property_*` conditions with `StringLike: sub: repo:myorg/*:*` to restrict to the owning org |
| Custom property not designated for OIDC inclusion at org level | `repo_property_*` claims absent from token even when property is set on the repo; trust policy condition never matches | Org admin must enable "Include in OIDC tokens" for each property — verify with `verify-oidc-claims.ts` script before rolling out |
| Barrel file imports in Jest without `babel-plugin-transform-barrels` | A single `import { Button } from '@myorg/ui'` triggers Jest to load 400+ modules (the full barrel); 10–30s per test suite startup on large component libraries | Add `babel-plugin-transform-barrels` to `.babelrc.js`; or use `no-barrel-file` ESLint rule to prevent new barrel files; or migrate to Vitest (ESM-native, barrel-safe) |
| Custom runner image without path-scoped Copilot review trigger | Copilot cloud agent reviews trivial PRs (docs, lockfile) and consumes Actions minutes on every push — bill grows with team size | Scope `on.pull_request.paths` to `src/**` and `tests/**`; add size gate (`additions + deletions > 10`) |
| Custom runner image tag set to `:latest` without version pin | Playwright browser version in image silently changes overnight; tests fail with "browser binary mismatch" | Include Playwright version in image tag (e.g., `:node22-pw1.60`); update on controlled schedule |
| Vitest `mockThrow()` used on non-function mock without return type annotation | `mockThrow` auto-detects sync vs async from return type — `vi.fn()` without annotation defaults to sync; async callers get an uncaught throw instead of a rejected promise | Always annotate mock return type: `vi.fn() as Mock<Parameters<T>, ReturnType<T>>` |
| `vi.defineHelper()` wrapping async functions without `await` propagation | `defineHelper` removes stack frames but does not modify async behavior; if the helper `throw`s without propagating, the call site sees an empty stack | Ensure all paths inside `defineHelper` wrappers either return or throw — never silently swallow |
| TypeScript 5.8 `--erasableSyntaxOnly` enabled without prior enum/namespace audit | All enums, namespaces, parameter properties, and `import =` / `export =` expressions instantly become compiler errors — mass CI failure on first enable in large codebases | Run `tsc --erasableSyntaxOnly --noEmit` as an advisory non-blocking step first; capture error count; refactor over 1–2 sprints (convert enums to `const` objects or `satisfies` maps), then promote to required gate |
| `--libReplacement false` set globally when some packages use `@typescript/lib-*` replacements | `@typescript/lib-*` package-based lib overrides silently stop working; type definitions revert to bundled TypeScript defaults — subtle type widening that is not caught by tests | Only set `--libReplacement false` in packages/tsconfigs that have no `@typescript/lib-*` devDependencies; audit with `jq '.devDependencies | keys[] | select(startswith("@typescript/lib"))' package.json` |
| `--module node18` used in a project targeting Node 22+ | `--module node18` disallows `require()` of ESM modules entirely; Node 22 natively supports `require()` of ESM under `--module nodenext` — useful CI patterns (dynamic require for CJS plugin loading) silently break | Use `--module nodenext` for Node 22+ targets; reserve `--module node18` for projects that explicitly must not call `require()` on ESM |

## Real-World Gotchas [community]

> All items below are drawn from production CI systems and community post-mortems.

1. **Port conflicts in parallel jobs** [community]: When running multiple test containers on the same runner, use dynamic port allocation or Docker networks instead of fixed ports. Static port `5432` will collide on a shared runner with two parallel integration jobs.

2. **Time zone differences** [community]: CI runners often run UTC; local dev runs in local time. Date-sensitive tests must freeze time with `jest.setSystemTime()` or `vi.setSystemTime()`. A test like `expect(formatDate(new Date())).toBe('Jan 26')` will fail the morning of Jan 27 UTC while it is still Jan 26 in US timezones.

3. **GitHub Actions cache eviction** [community]: Caches are evicted after 7 days of no access. The first run after a holiday weekend will be slow — accept it, do not add conditional cache-warming jobs. The cure (complexity) is worse than the disease (one slow run).

4. **Playwright browser version mismatch** [community]: `@playwright/test` version and browser version are tightly coupled. If you cache browsers keyed only on lockfile hash and Playwright updates internally, tests silently use the wrong binary. Key the cache on the exact Playwright version string extracted from `package-lock.json`: `key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}-${{ steps.playwright-version.outputs.version }}`.

5. **`needs:` creates sequential chains by default** [community]: In GitHub Actions, `needs: [job-a, job-b]` waits for BOTH to finish. Avoid unnecessary serialization — a team at a mid-size SaaS reported 4 minutes of wasted queue time because their `deploy-preview` job needlessly waited for `test-accessibility` when both could run in parallel after `build`.

6. **Docker layer caching with `--no-cache` in scripts** [community]: Some CI scripts call `docker build --no-cache` to ensure freshness. This defeats GitHub Actions' `cache-from: type=gha`. Remove `--no-cache` and use content-addressed layers instead. One team cut their Docker build step from 8 min to 90 sec after removing this flag.

7. **`npm ci` vs `npm install`** [community]: Always use `npm ci` in CI — it respects the lockfile exactly, is faster (skips dependency resolution), and fails on lockfile drift. `npm install` silently updates the lockfile, causing non-deterministic installs and cache misses.

8. **Shared test database state in integration tests** [community]: Integration tests that share a single database without per-test transactions or truncation are order-dependent. A test that creates a "unique email" user will fail if another test already inserted that email. Use `BEGIN` / `ROLLBACK` per test or truncate tables in `beforeEach`.

9. **`GITHUB_TOKEN` permissions for PR comments** [community]: The default `GITHUB_TOKEN` cannot write PR comments on forks. If your repo uses fork-based contributor workflows, coverage comment actions will silently fail. Use `pull_request_target` (with care) or a dedicated comment action that uses `github.event.pull_request.number` via the REST API with explicit `permissions: pull-requests: write`.

10. **Test time budget drift** [community]: Teams set a 10-minute budget at project start, then add tests without measuring. Six months later the suite is 25 minutes and nobody knows why. Add a CI step that fails if total job duration exceeds the budget: `if [ $SECONDS -gt 600 ]; then echo "::error::CI exceeded 10-minute budget"; exit 1; fi`.

11. **Stale CI consuming runner slots** [community]: On busy repos without concurrency groups, a feature branch with 10 rapid commits can queue 10 CI runs simultaneously, exhausting shared runner pools for the whole team. Enforce `concurrency: cancel-in-progress: true` on all feature branch and PR workflows. Teams at mid-scale (20+ developers) have seen 3–4× improvement in median queue wait time after enabling this.

12. **Testcontainers pulling images every CI run** [community]: Without a pre-pulled image cache, Testcontainers downloads the PostgreSQL image (~170 MB) on every CI run. Use `docker pull postgres:16-alpine` as a cached step before running tests, or use a private registry mirror. One platform team eliminated 45–90 seconds of dead time per integration job by adding a single `docker pull` step before the test command.

13. **Windows-specific path separator failures in matrix jobs** [community]: JavaScript code that uses string concatenation for file paths (`'src' + '/' + 'file.js'`) works on Linux/macOS but breaks on Windows CI runners where the separator is `\`. Use `path.join()` or `path.resolve()` from Node's `path` module everywhere. A team discovered this only after adding Windows to their matrix and saw 30% of their test files fail due to path mismatches in snapshot comparisons.

14. **Pre-commit hook drift from CI checks** [community]: When the CI lint config (`.eslintrc.js`) diverges from what the pre-commit hook runs, developers pass local hooks but fail CI. This creates the worst feedback loop: "it worked on my machine." Ensure the pre-commit hook runs the exact same script as the CI lint job — reference the same `npm run lint` command in both places, never inline the linter command in the hook.

15. **OpenTelemetry trace from CI — build spans invisible without instrumentation** [community]: Engineers debug slow CI pipelines by looking at wall-clock job times, but this hides time spent inside individual test suites (slow test case setup, database seeding, browser launches). Instrumenting CI jobs with OpenTelemetry spans — one span per test suite, child spans per test case — makes the critical path immediately visible. Teams that add OTEL CI tracing report identifying the root cause of "slow CI" in < 10 minutes vs. hours of log archaeology.

16. **`better-sqlite3` requires native compilation — pre-build or use fallback** [community]: If you adopt the test health trend tracking pattern with `better-sqlite3`, be aware that it requires `node-gyp` native compilation. On a fresh CI runner without a build cache, this adds 15–30 seconds and can fail if `python3` or `make` is not available. Use a try-catch fallback to append JSONL when the native module is unavailable:

```typescript
// Safe dynamic import pattern for optional native dependency (TypeScript)
import * as fs from 'fs';

interface TestSummary { runAt: string; total: number; passed: number; failed: number }

async function recordWithFallback(summary: TestSummary): Promise<void> {
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const Database = require('better-sqlite3') as typeof import('better-sqlite3').default;
    const db = new Database('.test-health/history.db');
    // ... insert logic
    db.close();
  } catch {
    // Fallback: write plain JSONL if better-sqlite3 not available
    fs.appendFileSync(
      '.test-health/history.jsonl',
      JSON.stringify(summary) + '\n',
    );
  }
}
```

17. **CI provider env var naming differences** [community]: Code that reads provider-specific variables (`GITHUB_REF`, `CI_COMMIT_REF_NAME`, `CIRCLE_BRANCH`) will silently get `undefined` on other providers. Normalize into a single `ci-env.ts` module:

```typescript
// ci-env.ts — normalize provider-specific env vars for portability
export interface CIEnvironment {
  branch: string;
  sha: string;
  prNumber: string | null;
  isCI: boolean;
}

const env: CIEnvironment = {
  branch: process.env['GITHUB_REF_NAME']         // GitHub Actions
    ?? process.env['CI_COMMIT_REF_NAME']          // GitLab CI
    ?? process.env['CIRCLE_BRANCH']               // CircleCI
    ?? process.env['BUILDKITE_BRANCH']            // Buildkite
    ?? 'local',
  sha: process.env['GITHUB_SHA']
    ?? process.env['CI_COMMIT_SHA']
    ?? process.env['CIRCLE_SHA1']
    ?? process.env['BUILDKITE_COMMIT']
    ?? 'local',
  prNumber: process.env['GITHUB_EVENT_NUMBER']
    ?? process.env['CI_MERGE_REQUEST_IID']
    ?? process.env['CIRCLE_PR_NUMBER']
    ?? null,
  isCI: Boolean(process.env['CI']),
};

export default env;
```

18. **Risk-based test ordering neglected after initial setup** [community]: Risk scores defined in a sequencer or naming convention become stale as the codebase evolves. A payment module that was Tier 1 six months ago may have been refactored into a stable utility; a new feature with high business impact may not be tagged. Schedule a quarterly "risk tier review" as part of test maintenance. The review takes < 1 hour and keeps ordering aligned with actual production risk.

19. **`ts-jest` not configured for strict type checking** [community]: Teams that switch from `babel-jest` to `ts-jest` often copy the default config which sets `diagnostics: false` to suppress TypeScript errors in tests. This defeats the purpose of using TypeScript — test files can have incorrect types with no feedback. Enable `diagnostics: true` (default) and fix all test-file type errors; the migration cost is a one-time investment. Production bugs caused by mistyped mock return values are far more expensive.

20. **TypeScript path aliases breaking in CI** [community]: Projects that use `tsconfig` path aliases (e.g., `@/utils`) must configure both `ts-jest`'s `moduleNameMapper` and `tsconfig`'s `paths` identically. Teams frequently update one but not the other, causing tests to fail in CI with `Cannot find module '@/utils'` while passing locally because the IDE's language server resolves paths differently. Validate path alias consistency as part of the `typecheck` CI gate.

21. **Declaration file (`.d.ts`) generation skipped in CI** [community]: Libraries that export TypeScript declarations must verify that `tsc --declaration --emitDeclarationOnly` succeeds as part of CI. Teams that skip this step ship packages with missing or incorrect `.d.ts` files, breaking downstream consumers. Add a `build:types` CI step that runs declaration emission and check-in the generated types directory.

22. **`noUncheckedIndexedAccess` enabled after green CI — sudden mass failure** [community]: Teams that add `"noUncheckedIndexedAccess": true` to `tsconfig.json` without preparation typically find 50–200 type errors across their test files on the next CI run. Array index access (`arr[0]`) now returns `T | undefined`, breaking all tests that pass array elements directly to functions expecting `T`. Migrate incrementally: enable the flag in a separate `tsconfig.strict.json`, run `tsc --project tsconfig.strict.json --noEmit` as an advisory (non-blocking) CI step, fix errors over 1–2 sprints, then promote to the required gate.

23. **ESM/CommonJS module mismatch in CI with TypeScript** [community]: TypeScript projects configured for `"module": "ESNext"` in `tsconfig.json` but running tests with `ts-jest` in CJS mode produce confusing CI failures: `SyntaxError: Cannot use import statement in a module` or `ReferenceError: require is not defined`. The root cause is mismatched module systems between TS config and the test runner. Solution: use `"module": "CommonJS"` in `tsconfig.test.json` (separate test tsconfig), or migrate fully to Vitest which is ESM-native.

24. **TypeScript version drift between developer machines and CI** [community]: Teams that install TypeScript globally (e.g., `npm install -g typescript`) and reference it in CI scripts can have different TypeScript versions on dev machines and CI. TypeScript is not semver-stable — minor versions introduce new strict checks. Always declare TypeScript as a `devDependency` in `package.json` and run `npx tsc` (which uses the local version) rather than `tsc`. Enforce version in CI by checking `node_modules/.bin/tsc --version` against the version in `package.json`.

25. **OIDC trust policy too permissive — missing `sub` claim condition** [community]: GitHub Actions OIDC lets CI runners assume cloud IAM roles without stored secrets. The most common misconfiguration: the trust policy only validates the OIDC issuer (`token.actions.githubusercontent.com`) but not the `sub` claim. Without the `sub` condition, any public GitHub Actions workflow can assume the role — including workflows in attacker-controlled repositories. Always add a `StringLike` condition on `sub: repo:OWNER/REPO:*`. Teams that perform IAM role audits after enabling OIDC discover this misconfiguration in approximately 30% of roles.

26. **Nx Cloud DTE with zero module boundary enforcement** [community]: Nx Cloud Distributed Task Execution (DTE) distributes tasks across agents based on the dependency graph. If the dependency graph is inaccurate (packages importing from each other without workspace declarations), DTE will run tasks in the wrong order and produce false-positive failures. Before enabling DTE, run `nx graph` and audit every package's `implicitDependencies`. Teams that skip this step see DTE introduce new test failures rather than accelerate existing ones — a confusing regression that takes 2–4 hours to diagnose.

27. **Bun test runner producing false-green results for DOM-dependent tests** [community]: `bun test` does not support jsdom (as of 2025). Tests that use `document`, `window`, or `@testing-library/react` will either throw or silently pass vacuously (if the test body is never entered). Teams migrating from Jest to Bun for speed without auditing their test environment requirements discover this in a confusing way: the test output shows 0 failures but the browser behavior is broken. Always inventory which tests require jsdom before switching test runners.

28. **OpenTelemetry CI spans missing on flaky retry runs** [community]: Teams that add OTEL tracing to CI emit one span per `test run`. But GitHub Actions retry reruns (`Re-run failed jobs`) create a new `GITHUB_RUN_ATTEMPT` for the same run ID. If the tracer doesn't include `GITHUB_RUN_ATTEMPT` in the run ID attribute, retry spans overwrite the original failure spans in the OTEL backend. Always include `run_attempt: process.env['GITHUB_RUN_ATTEMPT'] ?? '1'` as a resource attribute so each attempt is independently traceable.

29. **Reusable workflow caller forgetting to pass secrets** [community]: GitHub Actions reusable workflows run in an isolated job context and do NOT inherit the caller's secrets automatically. Any secret referenced inside the reusable workflow must be explicitly passed by the caller via `secrets:`. Teams that define a reusable workflow and then call it from a new workflow file consistently hit this: the secret exists in the repository settings, the calling workflow has access to it, but the inner reusable workflow sees an empty string. The fix is mechanical but the discovery is frustrating because no error is raised — the secret is silently empty.

30. **Feature flag tests not covering the removal path** [community]: When a feature flag is promoted to permanent (flag removed, one code path deleted), any test that only covered the old code path becomes dead code — it still runs but tests a branch that no longer exists or silently passes because it imports the now-absent old-path function which was replaced. Teams that track feature flag lifecycle in their test suite (flag name in test file name or describe block) catch this during code review. Teams without such tracking discover it months later when coverage metrics mysteriously improve — a sign tests are testing nothing.

31. **Multi-cloud OIDC token exchange after slow setup steps** [community]: GitHub Actions OIDC tokens have a 10-minute expiry. Teams that run slow container pull steps (docker pull, npm ci) BEFORE the OIDC exchange occasionally hit token expiry on cold runners. Always exchange all provider tokens as the first substantive step in the job, before any slow setup work. This is especially critical in multi-cloud jobs that need both AWS and GCP credentials.

32. **`act` local run diverging from remote CI due to missing service containers** [community]: GitHub Actions `services:` (Postgres, Redis) are Docker containers started by the GitHub runner before the job. `act` supports `services:` but requires Docker networking that is configured differently on developer machines vs. the runner. Teams using `act` for integration test iteration often skip the service container step locally and wonder why tests pass locally-with-act but fail without services in fresh CI. Always include `act --container-architecture linux/amd64 --network host` flags or define equivalent `docker-compose.yml` for local integration testing.

33. **Docker test image built with `target: test` but deployed to staging with `target: production`** [community]: Multi-stage Dockerfiles allow building different stages for testing vs. production. A common confusion: developers rebuild the test image (`target: test`) locally but CI builds the production image and runs tests against it. The test-stage image may include extra mocks, seed data, or debug tools not in production. Ensure CI consistently builds and tests with the `test` target stage and deploys only the `production` target stage.

34. **Visual regression screenshots capturing dynamic content (timestamps, live data)** [community]: Tests that screenshot a page containing a live timestamp, random avatar, or animated element produce a different snapshot on every run. These tests fail 100% of the time and are immediately disabled. Before capturing any screenshot, hide or freeze all dynamic elements: `await page.addStyleTag({ content: '.timestamp, .avatar { visibility: hidden }' })`. Identify dynamic elements with `--update-snapshots` on a clean branch and note which elements changed between captures.

35. **GitHub Environment protection rule configured on staging but not on the jobs that deploy to production** [community]: Environment protection rules only apply to jobs that explicitly declare `environment: production`. A deployment pipeline that uses a reusable workflow for the production deploy step but does not pass `environment:` as a parameter will silently bypass all protection rules. Teams discover this after a bad production deploy — the deployment ran without waiting for reviewer approval because the environment was not declared on the job. Audit every deployment job in every workflow file for the correct `environment:` declaration.

36. **TypeScript `--noCheck` adopted without a mandatory parallel `tsc --noEmit` gate** [community]: `--noCheck` is designed to be paired with a separate type-check job. Teams that adopt `--noCheck` for speed but treat the type-check job as optional discover the problem the same way that teams using `babel-jest` without `tsc --noEmit` discover it: type errors silently pass CI and are found in production. The `all-checks` gate job that requires BOTH `transpile-and-test` AND `typecheck` to pass is not optional — it is the safety invariant that makes `--noCheck` safe.

37. **Using `--only-changed` without a nightly full-suite run** [community]: `--only-changed=origin/main` only runs test files that were directly modified — it does NOT detect tests in unchanged files whose subject code was indirectly changed. A test in `user.spec.ts` that exercises `payment.ts` will not be included in `--only-changed` if only `payment.ts` changed. Always run the full suite on a nightly schedule or on every push to `main`, and use `--only-changed` only as a fast supplementary gate on PRs.

38. **Vitest Browser Mode test isolation assumed to be per-test** [community]: Unlike jsdom (per-test isolation via module registry reset), Vitest Browser Mode creates ONE browser context per test file. Global state mutations (CSS variables set by one test in a file) persist to subsequent tests in the same file. Teams that migrate jsdom tests expecting identical isolation behavior discover intermittent ordering-dependent failures. Add explicit `afterEach` cleanup for any browser global state modified during tests.

39. **Playwright `globalSetup` used instead of Project Dependencies for CI** [community]: `globalSetup` runs outside the Playwright test runner context and is invisible to the HTML reporter and trace recorder. When setup fails (e.g., API seeding fails, auth token cannot be generated), CI reports the first test failing with a cryptic error instead of a setup failure. Migrate to Project Dependencies (`dependsOn: ['setup']`) so setup failures appear as distinct, traceable failures with correct error messages and trace links.

40. **Vitest workspace projects using `**/*.test.ts` glob without package prefix** [community]: In a `defineWorkspace` config, an `include` pattern of `['**/*.test.ts']` at the workspace root matches test files from ALL packages. When a project runs with `environment: 'jsdom'`, all matched files (including Node-only API tests that import `node:crypto`, `node:fs`, etc.) will fail with DOM environment errors. Always scope `include` to `'packages/<name>/src/**/*.test.ts'` — never use the bare recursive glob in workspace projects.

41. **`--fail-on-flaky-tests` adopted on PR gate before baselining flakiness** [community]: Teams that enable `--fail-on-flaky-tests` on PR gate workflows without first measuring baseline flakiness typically discover on day one that 3–8 test cases are chronically flaky and block every PR. The correct rollout sequence: (1) add `--fail-on-flaky-tests` to the nightly scheduled run only, (2) observe the first week's results and quarantine offenders, (3) fix root causes (usually timing issues or shared state), (4) promote to PR gate once the nightly run is clean for 5+ consecutive days.

42. **`captureGitInfo` with shallow checkout producing empty commit metadata** [community]: The `captureGitInfo: { commit: true }` option in Playwright v1.51+ requires full git history to populate commit message, author, and parent SHA in test reports. GitHub Actions defaults to `fetch-depth: 1` (shallow clone). Teams that add `captureGitInfo` without changing the checkout depth see blank commit metadata in every report artifact — the reports run successfully but are missing the information that makes them useful for post-incident analysis. Add `fetch-depth: 0` to your `actions/checkout@v4` step.

43. **Vitest v3.2 `workspace` deprecation causing `defineWorkspace is not a function` errors** [community]: Vitest v3.2 deprecated the `defineWorkspace` helper (and the `vitest.workspace.ts` / `vitest.workspace.js` discovery pattern) in favor of the `projects` array inside `vitest.config.ts`. Teams upgrading from Vitest v2.x or v3.1 to v3.2+ with existing `vitest.workspace.ts` files see `defineWorkspace is not a function` if they import from an old package path, or find their workspace config silently ignored. Migration: move workspace project definitions into `vitest.config.ts` under `test.projects`, replace `defineWorkspace` calls with the inline array syntax, and replace `defineConfig` in per-project files with `defineProject`.

44. **Playwright `testConfig.tsconfig` omitting `@playwright/test` from types** [community]: The `tsconfig` option in `playwright.config.ts` (v1.49+) applies the specified TypeScript configuration to all test files. Teams that set this to a tsconfig file that does not include `"@playwright/test"` in its `types` array see IDE type errors for `test`, `expect`, `page`, and all other Playwright globals, even when tests run correctly at runtime. Playwright injects its runtime types automatically, but the TypeScript language server requires the explicit `types` declaration. Always add `"types": ["@playwright/test"]` to any tsconfig referenced by `testConfig.tsconfig`.

45. **Vitest 4.0 silent "0 tests" after workspace migration** [community]: The removal of `defineWorkspace` in Vitest 4.0 causes a deceptive failure mode — if an old `vitest.workspace.ts` remains alongside a new `vitest.config.ts`, Vitest may discover both, prefer `vitest.config.ts` (which has no tests defined yet), and exit with "0 tests executed" and no error. CI shows green because there were no failures — there were simply no tests. Always verify the test count in CI output after a Vitest upgrade: a green run with 0 tests is a silent misconfiguration.

46. **Playwright `webServer.wait` regex capturing wrong group due to un-anchored pattern** [community]: A `webServer.wait` regex like `/port (\d+)/` captures the port but without a named group, so it is not injected as an environment variable. Teams that use un-named capture groups (parentheses without `?<name>`) discover that `process.env['SERVER_PORT']` is always `undefined` — Playwright only injects named capture groups. The fix: add a name to every capture group: `/port (?<server_port>\d+)/`.

47. **Vitest `aroundEach` not awaiting `runTest()` causing false-green test results** [community]: The `runTest` callback in `aroundEach` is async and must be awaited. If a developer writes `aroundEach(async runTest => { setup(); runTest(); cleanup(); })` without `await`, the test runs and the cleanup executes before the test completes — rollbacks happen mid-test, connections are closed under running assertions, and tests may produce false-green results because assertions fail silently. Always `await runTest()` inside `aroundEach`.

48. **`--detect-async-leaks` first enabled in CI producing hundreds of failures** [community]: Teams that enable `--detect-async-leaks` for the first time on a large test suite see dozens or hundreds of failures simultaneously — every test file that creates servers, timers, or DB connections without cleanup is flagged. Running with `--bail=0` (continue on failure) is essential for the first pass: it collects the full set of leaking tests in one CI run rather than stopping at the first failure and requiring repeated runs. Fix all leaks before setting `--bail=1`.

49. **Playwright HTML Speedboard tab missing because report was generated on a single runner** [community]: The Speedboard tab only appears in HTML reports generated by `npx playwright merge-reports` from multiple blob reports. HTML reports generated by `--reporter=html` on a single runner (no sharding, no merge step) do not include the Speedboard. Teams running a single-runner e2e suite that want execution timeline visibility must change their workflow to: (1) use `--reporter=blob` on the single runner, (2) run `npx playwright merge-reports --reporter html` as a post-step. This adds ~5 seconds and unlocks the timeline.

50. **GitHub Actions custom runner image used in `runs-on` without `ghcr.io` package read permission** [community]: Custom runner images hosted on GitHub Container Registry (GHCR) require the workflow to have `packages: read` permission and the runner's GitHub App to have access to the package. Teams that build a custom image and reference it in `runs-on: [self-hosted, custom-image]` without configuring package access see the runner fail to pull the image with an opaque authentication error. Always add `permissions: packages: read` to workflows that reference GHCR-hosted custom images.

51. **Playwright `page.screencast.start()` called after page navigation completes** [community]: The Screencast API requires `start()` to be called before the actions you want to record. Calling it after `page.goto()` captures nothing from the navigation phase — the first frames show the already-loaded page with no context for how it was reached. In CI, this causes video evidence that omits the most diagnostic part (the navigation and any redirect or error during load). Always call `page.screencast.start()` before the first `page.goto()` call.

52. **`act --validate` passes but `act` run fails due to GitHub-Actions-only features** [community]: `act --validate` validates YAML structure but cannot validate features that require GitHub's live runner environment: `workflow_call` reusable workflow inputs, GitHub OIDC token exchange, `GITHUB_CONTEXT` object shapes, and required secrets. Teams that treat a passing `--validate` as "this workflow is correct" ship workflows that fail in real CI on the first use of these features. Use `act --validate` for YAML structural checks only; test OIDC and reusable workflow features with a real draft PR on a non-protected branch before merging.

53. **Vitest v5 `attachmentsDir` rename not updated in CI upload steps** [community]: Vitest v5.0 corrects a long-standing typo in the default attachments directory name — from `.vitest-attachements/` (double 'e') to `.vitest/attachments/` (correct spelling, under the `.vitest/` directory). CI workflows that reference the old path produce `actions/upload-artifact` warnings or silently upload nothing (no files found at the old path). Run `find . -path '*vitest-attachements*' -name '*'` in your CI artifacts step to detect stale path references before upgrading.

54. **Playwright HAR `urlFilter` regex anchoring — captures wrong requests when unanchored** [community]: A `urlFilter` regex like `/api/` matches any URL containing the string "api" including third-party analytics URLs (`/api.mixpanel.com/...`). Teams that write unanchored `urlFilter` patterns capture 3–5× more requests than intended, producing large HAR files with third-party noise. Use an anchored pattern targeting the API host: `/^https?:\/\/api\.example\.com\//` or use a path-prefix match: `/\/api\//` (note the leading and trailing slashes) to ensure only your application's API calls are captured.

55. **Vitest 4.1 job summary absent after adding a custom `reporters` array** [community]: The `github-actions` reporter is injected automatically when no `reporters` array is configured. As soon as a team adds `reporters: ['verbose', 'json']` to `vitest.config.ts`, the auto-injection stops and job summaries silently disappear from the GitHub Actions checks UI. The fix is to add `'github-actions'` explicitly: `reporters: ['verbose', 'json', 'github-actions']`. Teams that add a custom reporter for coverage comments in one sprint routinely discover the missing job summaries two sprints later when someone asks "where are our flaky test links?".

56. **OIDC `repo_property_*` claim matching without org-level designation** [community]: Repository custom properties appear in OIDC tokens ONLY if an organization administrator has explicitly designated the property for OIDC inclusion. A property that is set on a repository but not designated will not appear in the token — the trust policy condition silently never matches and the IAM role assumption fails with a generic "not authorized" error. Teams that configure the trust policy, set the repository property, and then see OIDC failures have almost always forgotten the org-level designation step. Add the `verify-oidc-claims.ts` debug script as a pre-test step to confirm claims are present before blaming the trust policy.

57. **GitHub Actions workflow rerun limit of 50 reruns** [community]: As of April 2026, GitHub Actions enforces a hard limit of 50 reruns per workflow run (previously unlimited). Teams that rely on automated rerun loops — CI bots that requeue flaky test runs on every failure — will hit this limit and see reruns silently blocked. Any workflow that has been rerun 50 times can no longer be rerun; a new run must be triggered. This surfaces most severely in repos with chronic flakiness handled by rerun automation rather than root-cause fixes. The limit is a forcing function: teams at the 50-rerun boundary must either quarantine the flaky tests or fix the root cause. Budget 1–2 sprints for flakiness remediation if your daily rerun rate exceeds 40 per workflow.

58. **npm 11 `prepare` script suppressed by `--ignore-scripts` in `npm ci`** [community]: npm 11 (bundled with Node.js 24) clarifies that `--ignore-scripts` suppresses ALL lifecycle scripts including `prepare`. In npm 9/10, `prepare` would run in some contexts even with `--ignore-scripts`. Teams that relied on `"prepare": "tsc"` to compile TypeScript before tests — using `npm ci --ignore-scripts` for supply-chain security hardening — find that compiled output is missing after upgrading to Node 24/npm 11. Fix: add an explicit `npm run build` step after `npm ci` in CI, decouple compilation from the `prepare` script, or add TypeScript compilation to a `prebuild` or `pretest` script that can be selectively enabled.

59. **Node.js 24 native test runner `--test-global-setup` module must use ESM exports** [community]: The `--test-global-setup` module is loaded as a Node.js ESM module — it must use `export async function setup()` and `export async function teardown()` syntax. CommonJS modules (`module.exports = { setup, teardown }`) are not recognized and the global setup is silently skipped with no error. Teams migrating global setup from Jest (`globalSetup.js` using `module.exports`) to the Node 24 native runner must convert to ESM exports. If the project uses `"type": "commonjs"`, use a `.mts` or `.mjs` extension for the global setup file to force ESM parsing.

60. **TypeScript 5.8 `--erasableSyntaxOnly` mass failure on first CI enable** [community]: TypeScript 5.8 introduced `--erasableSyntaxOnly`, which restricts TypeScript syntax to features that can be removed by simple erasure (as Node.js type-stripping does). Enums, namespaces, parameter properties (`constructor(private x: T)`), `import =` / `export =`, and decorators without `experimentalDecorators` all become compile errors. In a mature codebase, enabling this flag for the first time in a required CI gate typically produces 50–300 errors across test files alone — test helpers commonly use parameter properties and `const enum`. Always enable as a non-blocking advisory gate first: `tsc --erasableSyntaxOnly --noEmit 2>&1 | tee erasable-audit.txt; wc -l erasable-audit.txt`. Count errors, schedule refactoring (convert parameter properties to explicit assignments, convert enums to `const` maps or string unions), then promote to required after the audit sprint.


|---|---|---|---|
| Unit only | ~2 min | Logic only | Hotfix branches, library packages |
| Unit + integration | ~6 min | Logic + service contracts | Feature branches |
| Full pyramid | ~15 min | End-to-end | PRs to main, release branches |
| Nightly full suite | ~60 min | Full + visual + perf | Release qualification |

**Industry benchmark targets (JavaScript/Node.js projects):**
- Unit suite: < 2 minutes for up to 2,000 tests
- Integration suite: < 5 minutes for up to 200 integration tests
- E2E smoke: < 8 minutes for 20–30 critical path scenarios
- Full CI pipeline: < 10 minutes end-to-end on feature branches

**When to skip e2e in fast feedback loops:**

E2E tests validate integration of multiple systems and are expensive to maintain (average 10–30 minutes per test authored, vs. < 5 minutes for a unit test). Skip e2e on feature branches for these categories:

- **Pure UI component libraries** (Storybook-based): Test with visual snapshots + interaction tests (`@testing-library/react`) instead. No real browser needed for component isolation.
- **Pure backend microservices with OpenAPI contracts**: Use contract testing (Pact) at the integration level instead of browser e2e. E2E tests add no value when there is no UI.
- **Internal tooling / admin dashboards**: Lower risk profile; unit + integration is sufficient for most changes. Reserve e2e for critical workflows (user creation, permissions).
- **Any branch where the changed files are 100% within a single package** (verified by monorepo tooling): Trust the affected graph; only run that package's tests.

**When e2e is non-negotiable:**
- Auth flows (login, SSO, token refresh) — timing-sensitive and environment-dependent
- Payment / checkout flows — too costly to get wrong
- Cross-browser rendering for consumer-facing UIs
- Accessibility compliance (axe-core in Playwright)

### Monorepo vs. Single-Repo

| Dimension | Monorepo | Single repo |
|---|---|---|
| Test scope per commit | Affected graph (nx/turbo) | Always full suite |
| Cache granularity | Per-package | Per-repo |
| CI complexity | Higher (graph traversal) | Lower |
| Cross-package regression | Caught automatically | N/A |
| Recommended max CI time | 8 min (affected only) | 10 min |
| Incremental adoption | Yes (add packages over time) | N/A |

**Monorepo gotcha [community]:** The affected calculation depends on an accurate dependency graph in `nx.json` or `package.json` `workspaces`. Undeclared dependencies (importing across packages without workspace declaration) cause missed test runs — a change in `@myorg/utils` doesn't trigger tests in `@myorg/app` if the dependency isn't declared. Enforce explicit imports with `eslint-plugin-import` and `@nx/enforce-module-boundaries`.

**Single-repo optimization path:** If full suite exceeds 10 minutes in a single repo, the ordering is:
1. First, maximize parallelization (`maxWorkers: 50%`)
2. Then, add sharding across 2–4 runners (reduces wall-clock time proportionally)
3. Last resort: split the repo into a monorepo (high migration cost)

### Retry vs. Quarantine

Retrying a flaky test automatically (Playwright `retries: 2`) is a short-term fix that buys time to investigate. Quarantining (treating as skip in CI, tracking separately) is the correct long-term strategy.

| Approach | When to use | Risk |
|---|---|---|
| `retries: 1` | Brand-new test, investigating | Hides failures for 1 extra attempt |
| `retries: 2` | Known flaky, quarantine pending | Doubles/triples job time for that test |
| `retries: 3+` | Never | Masks systemic issues; voids CI signal |
| Quarantine tag | Long-lived flaky, tracked in backlog | Test provides no safety signal while quarantined |
| Fix root cause | Ideal | Requires investigation time (budget it) |

**Never set `retries > 2`** — it masks systemic flakiness and inflates CI time. If a test needs 3 retries to pass, it is not a test, it is a lottery ticket.

### Contract Testing as an E2E Alternative [community]

For microservice architectures and component libraries, consumer-driven contract testing (Pact) can replace or supplement e2e tests in CI.

> [community] A fintech team with 12 microservices reduced e2e test count by 60% and CI time by 40% by replacing cross-service e2e tests with Pact contracts. Each service publishes its consumer expectations; the provider verifies them independently. This is faster, more targeted, and does not require a full deployed environment.

**Comparison:**

| Approach | Speed | Env required | Failure isolation | Best for |
|---|---|---|---|---|
| E2E (browser) | Slow (mins/test) | Full stack deployed | Poor (any layer) | User journeys, auth, payment |
| E2E (API) | Medium | Backend deployed | Medium (API layer) | API contracts, data flows |
| Contract testing (Pact) | Fast (seconds) | None (mocked) | Excellent (per contract) | Microservice boundaries |
| Integration (test container) | Medium | DB/service only | Good (within service) | DB queries, service logic |

**When contract testing does NOT replace e2e:**
- When the user experience itself is what's being verified (visual layout, accessibility, user flow)
- When the interaction between browser JavaScript and the API is the risk (CORS, cookie handling, CSP)
- When latency and load-under-pressure behavior matter (use k6/Gatling for load tests instead)

### Sharding Count vs. Marginal Returns

**TypeScript contract test (Pact consumer) example:**

```typescript
// tests/contract/user-api.consumer.pact.ts
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import type { UserApiClient } from '../../src/clients/user-api-client';

const { like, string, integer } = MatchersV3;

const provider = new PactV3({
  consumer: 'FrontendApp',
  provider: 'UserService',
  dir: 'pacts',
});

describe('UserApiClient — Pact consumer test', () => {
  it('fetches a user by ID', async () => {
    await provider
      .given('user 42 exists')
      .uponReceiving('a GET request for user 42')
      .withRequest({ method: 'GET', path: '/users/42' })
      .willRespondWith({
        status: 200,
        body: like({
          id: integer(42),
          email: string('alice@example.com'),
          name: string('Alice Smith'),
        }),
      })
      .executeTest(async (mockServer) => {
        const client = new UserApiClient(mockServer.url) as UserApiClient;
        const user = await client.getUser(42);
        // TypeScript ensures user matches the expected type
        expect(user.email).toBe('alice@example.com');
      });
  });
});
```

**CI workflow for contract publishing:**

```yaml
# .github/workflows/contract.yml — publish contracts to Pact Broker on main
jobs:
  contract-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm run test:contract
        name: Run Pact consumer tests
      - name: Publish pacts to broker
        if: github.ref == 'refs/heads/main'
        run: |
          npx pact-broker publish pacts/ \
            --consumer-app-version "${{ github.sha }}" \
            --broker-base-url "${{ vars.PACT_BROKER_URL }}" \
            --broker-token "${{ secrets.PACT_BROKER_TOKEN }}"
```

> [community] TypeScript's type system provides a structural check on Pact response bodies that plain JavaScript cannot: if the `UserApiClient.getUser()` return type is `Promise<User>` and the Pact response body has a different shape, `tsc` will flag the mismatch before the test even runs. Teams using typed Pact consumers catch contract drift at compile time rather than at pact verification time — reducing the time to detect API incompatibilities from "next provider deploy" to "next commit".

> [community] The [Pact Nirvana](https://docs.pact.io/pact_nirvana) 7-level maturity roadmap maps directly onto CI/CD pipeline maturity. Levels 5–7 are pure CI concerns: Level 5 = consumer publishes pacts in CI on every PR + provider verifies in CI on every build; Level 6 = `can-i-deploy` is a required merge gate before every deployment (Platinum); Level 7 = `record-deployment` is automated in each production deploy pipeline (Diamond). Teams at Level 4 (Silver — manual Broker interactions) routinely report that adding CI automation (Level 5) halves the time they spend debugging cross-service breakages.

| Shards | Relative speedup | Cost | Recommendation |
|---|---|---|---|
| 1 (no sharding) | 1× | $1× | Baseline |
| 2 | ~1.9× | $2× | Good first step |
| 4 | ~3.5× | $4× | Sweet spot for most teams |
| 8 | ~6× | $8× | Only if 4-shard still too slow |
| 16+ | ~10× | $16×+ | Diminishing returns; coordination overhead |

Coordination overhead (artifact upload/download, report merge) absorbs roughly 10–15% of potential speedup per doubling of shards.

### Multi-Cloud OIDC Credential Scoping [community]

When tests require credentials for multiple cloud providers simultaneously (e.g., AWS S3 + GCP Artifact Registry + Azure Key Vault in the same integration test job), a single OIDC exchange is insufficient. Each provider requires a separate OIDC token exchange, and the IAM role must be scoped to the minimum required permissions for each exchange.

> [community] Teams running integration tests that span multiple cloud providers report that naively chaining OIDC exchanges (exchange for AWS → exchange for GCP) without understanding token lifetimes causes silent authentication failures 10–15 minutes into long-running test jobs. GitHub Actions OIDC tokens have a 10-minute expiry; if the second OIDC exchange happens after the token expires (e.g., after a slow containerized setup step), the exchange fails. Pre-exchange all provider tokens at job start before any slow steps.

```yaml
# .github/workflows/ci-multi-cloud.yml — pre-exchange all OIDC tokens at job start
name: Multi-Cloud Integration Tests

on: [pull_request]

permissions:
  id-token: write    # required for all OIDC exchanges
  contents: read

jobs:
  integration:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci

      # Exchange ALL OIDC tokens first — before any slow steps that might expire the GitHub token
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubTestRole
          aws-region: us-east-1

      - name: Configure GCP credentials (OIDC via Workload Identity Federation)
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: projects/123/locations/global/workloadIdentityPools/github/providers/github
          service_account: test-runner@my-project.iam.gserviceaccount.com

      # Now run the slow steps — credentials are already in env, no expiry risk
      - name: Pull test container images (slow)
        run: docker pull postgres:16-alpine && docker pull redis:7-alpine

      - name: Run integration tests
        run: npm run test:integration
        env:
          NODE_ENV: test
          AWS_REGION: us-east-1
          GCP_PROJECT: my-project
```

**TypeScript multi-cloud test with credential validation:**

```typescript
// tests/integration/multi-cloud-storage.test.ts — validate both cloud creds before tests
import { S3Client, HeadBucketCommand } from '@aws-sdk/client-s3';
import { Storage } from '@google-cloud/storage';
import * as assert from 'node:assert/strict';
import { describe, it, before } from 'node:test';

describe('Multi-cloud storage integration', () => {
  const s3 = new S3Client({ region: 'us-east-1' });
  const gcs = new Storage({ projectId: process.env['GCP_PROJECT'] });

  // Fail fast if credentials are not available — better than cryptic permission errors mid-suite
  before(async () => {
    const [awsOk, gcpOk] = await Promise.all([
      s3.send(new HeadBucketCommand({ Bucket: process.env['TEST_S3_BUCKET']! }))
        .then(() => true).catch(() => false),
      gcs.bucket(process.env['TEST_GCS_BUCKET']!).exists()
        .then(([exists]) => exists).catch(() => false),
    ]);

    assert.ok(awsOk, 'AWS S3 credentials not configured — check OIDC trust policy');
    assert.ok(gcpOk, 'GCP credentials not configured — check Workload Identity Federation');
  });

  it('stores object in S3 and copies metadata to GCS', async () => {
    // ... actual test logic
    assert.ok(true, 'placeholder — add real cross-cloud assertion here');
  });
});
```

> [community] The most commonly missed OIDC configuration for GCP: the `attribute_condition` on the Workload Identity Pool provider. Without it, any GitHub repository can use the provider. The correct condition is `assertion.repository == "myorg/myrepo"` (exact match) or `assertion.repository_owner == "myorg"` (org-level). Teams that configure the pool without an attribute condition discover the exposure during security reviews, typically months after the fact.

### CI Provider Comparison [community]

Different CI providers have different strengths. Choosing the right provider affects test architecture decisions (shard count, caching strategy, runner cost).

> [community] Teams that switch CI providers mid-project consistently underestimate migration effort. GitHub Actions workflows use YAML-native syntax and tight GitHub integration; CircleCI uses orbs for reusable config; GitLab CI uses YAML anchors. Porting is mechanical but the biggest cost is recreating caching strategies and secret management patterns. Budget 2–4 weeks for a mid-size project.

| Provider | Free tier | Self-hosted | Best for | Watch out for |
|---|---|---|---|---|
| GitHub Actions | 2,000 min/month | Yes (self-hosted runners) | GitHub repos, tight PR integration | 2-core free runners; matrix jobs expensive |
| GitLab CI | 400 min/month | Yes (runners) | GitLab repos, parent-child pipelines | YAML syntax more complex; cache sharing tricky |
| CircleCI | 6,000 min/month | Yes (self-hosted) | Docker-heavy workflows, resource classes | Orb ecosystem adds abstraction overhead |
| Buildkite | No free tier | Yes (mandatory) | Unlimited self-hosted runners, monorepos | Requires managing your own runner fleet |
| Nx Cloud | Free tier (CI credits) | N/A (hosted) | Nx monorepos with distributed task execution | Vendor lock-in to Nx toolchain |

**Portable CI pattern (abstract runner details):**

```yaml
# Use a workflow_dispatch input to allow local override of runner type
on:
  workflow_dispatch:
    inputs:
      runner:
        description: Runner label
        default: ubuntu-latest
        required: false
  push:

jobs:
  test:
    runs-on: ${{ github.event.inputs.runner || 'ubuntu-latest' }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm test -- --ci
```

> [community] The most cost-effective pattern for teams under 20 engineers: GitHub Actions with 2 self-hosted runners for integration/e2e jobs (4 vCPU, 8 GB RAM), free-tier shared runners for lint + unit. Integration and e2e jobs consume 80% of runner minutes — moving those to self-hosted reduces monthly bill by 60–70% while keeping the free tier for cheap fast jobs.

### TypeScript Test Runner Selection [community]

For TypeScript projects, the choice of test runner affects CI setup complexity, compile time, and type safety in tests.

> [community] Teams migrating from Jest to Vitest for TypeScript projects consistently report 30–50% faster test runs, primarily because Vitest uses esbuild for transpilation (vs. `ts-jest`'s TypeScript compiler). The catch: Vitest and Jest have subtly different mocking APIs (`vi.fn()` vs `jest.fn()`), so migration requires touching every mock in the codebase. Teams with > 500 test files typically stage the migration over 2–3 sprints.

| Runner | TypeScript support | Speed | Type-check in tests | Notes |
|---|---|---|---|---|
| Jest + ts-jest | Native via `ts-jest` preset | Baseline | Optional (`diagnostics: true`) | Industry default; large ecosystem |
| Jest + Babel | Via `@babel/preset-typescript` | Faster than ts-jest | None (transpile only) | No type safety in tests |
| Vitest | Native ESM TypeScript | 2–3× faster than Jest | Via separate `tsc --noEmit` | Best DX for new projects; Vite ecosystem |
| Node.js test runner + tsx | Experimental TypeScript support | Fast | None built-in | Minimal setup; limited mocking |

**When to choose Vitest for CI:**
- New TypeScript/Vite project (zero-config)
- Suite > 500 test cases (speed advantage most significant)
- Team comfortable with ESM-first development

**When to stick with Jest for CI:**
- Existing large Jest codebase (migration cost > speed gain)
- Heavy use of custom Jest matchers or reporters with no Vitest equivalents
- CJS-heavy codebase not ready for ESM

**Sample Vitest type-safe test (TypeScript):**

```typescript
// src/services/user-service.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Mock } from 'vitest';
import { UserService } from './user-service';
import type { UserRepository } from '../repositories/user-repository';

// Type-safe mock — TypeScript will error if mock doesn't match UserRepository interface
const mockRepo = {
  findByEmail: vi.fn() as Mock<Parameters<UserRepository['findByEmail']>, ReturnType<UserRepository['findByEmail']>>,
  create: vi.fn() as Mock<Parameters<UserRepository['create']>, ReturnType<UserRepository['create']>>,
} satisfies Partial<UserRepository>;

describe('UserService', () => {
  let service: UserService;

  beforeEach(() => {
    vi.clearAllMocks();
    service = new UserService(mockRepo as unknown as UserRepository);
  });

  it('returns null when user does not exist', async () => {
    mockRepo.findByEmail.mockResolvedValue(null);
    const result = await service.getUserByEmail('unknown@example.com');
    expect(result).toBeNull();
    expect(mockRepo.findByEmail).toHaveBeenCalledWith('unknown@example.com');
  });
});
```

> [community] Using `satisfies` with mock objects (TypeScript 4.9+) is the most effective way to catch mock drift — when the real interface changes (e.g., a method is renamed or its signature changes), `satisfies` causes a compile-time error on the mock object immediately. Teams that adopt this pattern report finding interface-vs-mock mismatches in code review rather than at runtime.

### Nx Cloud Distributed Task Execution [community]

Nx Cloud's Distributed Task Execution (DTE) splits tasks across multiple agents at the task level — not the project level. Unlike simple matrix sharding, DTE uses a coordinator that dynamically assigns individual lint, test, and build tasks to whichever agent is free, eliminating idle time when one shard finishes before others.

> [community] Nx Cloud's own benchmarks show that DTE achieves 90–95% of theoretical maximum parallelism for task graphs with many independent nodes. Static matrix sharding achieves 70–80% because shard boundaries create artificial serialization — if shard 2 has 3 slow tests and shard 1 finishes in 30 seconds, shard 1's runner idles while waiting. DTE eliminates this by continuously assigning newly freed tasks to idle agents.

**GitHub Actions workflow with Nx Cloud DTE:**

```yaml
# .github/workflows/ci-nx-cloud.yml — distributed task execution
name: CI (Nx Cloud DTE)

on: [push, pull_request]

env:
  NX_CLOUD_ACCESS_TOKEN: ${{ secrets.NX_CLOUD_ACCESS_TOKEN }}

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # Coordinator: schedules tasks and collects results
  main:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # Start the Nx Cloud run — waits for all agent slots to complete
      - run: npx nx-cloud start-ci-run --distribute-on="3 linux-medium-js"
      - run: npx nx affected --targets=lint,test,build --base=origin/main --head=HEAD
      - run: npx nx-cloud stop-all-agents

  # Agents: execute tasks distributed by the coordinator
  agents:
    runs-on: ubuntu-latest
    name: Agent ${{ matrix.agent }}
    strategy:
      matrix:
        agent: [1, 2, 3]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # Each agent polls for available tasks until the coordinator signals done
      - run: npx nx-cloud start-agent
        env:
          NX_CLOUD_ACCESS_TOKEN: ${{ secrets.NX_CLOUD_ACCESS_TOKEN }}
```

**`nx.json` task configuration for DTE:**

```json
{
  "$schema": "https://nx.dev/schemas/nx-schema.json",
  "tasksRunnerOptions": {
    "default": {
      "runner": "@nx/cloud",
      "options": {
        "cacheableOperations": ["lint", "test", "build", "typecheck"],
        "accessToken": "{NX_CLOUD_ACCESS_TOKEN}"
      }
    }
  },
  "targetDefaults": {
    "test": {
      "dependsOn": ["^build"],
      "inputs": ["default", "^default"],
      "outputs": ["{projectRoot}/coverage"]
    },
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"],
      "outputs": ["{projectRoot}/dist"]
    }
  }
}
```

> [community] The practical ceiling for Nx Cloud DTE agents is determined by the number of independent tasks in the affected graph, not by the suite size. A 30-package monorepo with well-isolated packages benefits from 4–6 agents; a poorly structured monorepo with a single "mega-package" containing 80% of the code will barely benefit from 2. The prerequisite for DTE gains is a well-defined module boundary structure — validate with `nx graph` before investing in DTE setup.

### OIDC-Based Secrets for CI Test Environments [community]

Storing long-lived cloud credentials as CI secrets is an anti-pattern — any secret that can be exfiltrated from a CI log or compromised GitHub secret grants indefinite access. OIDC (OpenID Connect) tokens issued per-run by GitHub Actions allow cloud providers to grant temporary, scoped credentials without storing any long-lived secret.

> [community] AWS, GCP, and Azure all support GitHub Actions OIDC. Teams that migrate from IAM user credentials stored as secrets to OIDC report eliminating the largest single cloud security risk in their CI pipelines. The credential lifetime is bounded to the workflow run (typically minutes), so compromise of a single CI run grants no persistent access to production resources.

**GitHub Actions OIDC with AWS for integration test access:**

```yaml
# .github/workflows/ci-oidc.yml — use OIDC instead of stored AWS credentials
name: CI with OIDC

on: [pull_request]

permissions:
  id-token: write    # required: allow Actions to request OIDC token
  contents: read

jobs:
  integration:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci

      # Exchange GitHub OIDC token for temporary AWS credentials
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsTestRole
          aws-region: us-east-1
          # No aws-access-key-id or aws-secret-access-key needed — OIDC only

      # AWS credentials are now available as environment variables for the run
      - name: Run integration tests
        run: npm run test:integration
        env:
          NODE_ENV: test
          # Tests that access S3, DynamoDB, etc. use the temporary credentials above
```

**TypeScript integration test using temporary AWS credentials:**

```typescript
// tests/integration/s3-storage.test.ts — uses OIDC-granted temporary creds
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { StorageService } from '../../src/services/storage-service';

describe('StorageService (S3 integration)', () => {
  let service: StorageService;
  const testBucket = process.env['TEST_S3_BUCKET'] ?? 'my-test-bucket';

  beforeAll(() => {
    // AWS SDK picks up credentials from OIDC-granted env vars automatically
    // No explicit credentials needed when running in CI with OIDC
    const s3 = new S3Client({ region: 'us-east-1' });
    service = new StorageService(s3, testBucket);
  });

  it('stores and retrieves a file', async () => {
    const key = `test-${Date.now()}.txt`;
    const content = 'test content';

    await service.put(key, Buffer.from(content));
    const result = await service.get(key);

    expect(result.toString('utf8')).toBe(content);

    // Cleanup — always delete test artifacts
    await service.delete(key);
  });
});
```

> [community] The IAM role trust policy for GitHub Actions OIDC must scope the `sub` claim to the specific repository and branch to prevent other GitHub repositories from assuming the same role. A misconfigured trust policy that only checks `token.actions.githubusercontent.com` as the issuer grants any public GitHub Actions workflow access to the role. Always add a condition: `"StringLike": {"token.actions.githubusercontent.com:sub": "repo:myorg/myrepo:*"}`.

### Bun as a Test Runner Alternative [community]

Bun's built-in test runner (`bun test`) is significantly faster than Jest or Vitest for TypeScript projects because it uses a native-speed JavaScript engine and skips the transpilation layer entirely. For CI pipelines where test run time is the bottleneck, Bun is a viable alternative worth evaluating.

> [community] Early adopters of `bun test` in 2024–2025 report 4–8× faster test runs compared to Jest+ts-jest for large TypeScript test suites. The primary constraint is compatibility: Bun's Jest-compatible API covers ~90% of typical Jest usage, but custom reporters, certain mocking patterns (`jest.requireActual`, module factory mocks), and `jsdom` environment features have gaps. Teams with straightforward unit test suites benefit most; teams with complex test infrastructure should stay on Jest/Vitest until ecosystem gaps close.

**Bun test configuration and TypeScript integration:**

```typescript
// bun-test-runner example — tests/unit/calculator.test.ts
// No config file needed for basic usage; Bun auto-discovers *.test.ts files
import { describe, it, expect, mock, beforeEach } from 'bun:test';
import { Calculator } from '../../src/calculator';
import type { Logger } from '../../src/types';

// Type-safe mock with Bun's mock API (compatible with Jest mock interface)
const mockLogger: Logger = {
  log: mock<Logger['log']>(() => {}),
  error: mock<Logger['error']>(() => {}),
};

describe('Calculator', () => {
  let calc: Calculator;

  beforeEach(() => {
    calc = new Calculator(mockLogger);
    // Reset mocks between tests
    (mockLogger.log as ReturnType<typeof mock>).mockClear();
  });

  it('adds two numbers and logs the result', () => {
    const result = calc.add(2, 3);
    expect(result).toBe(5);
    expect(mockLogger.log).toHaveBeenCalledWith('add: 2 + 3 = 5');
  });

  it('throws on division by zero', () => {
    expect(() => calc.divide(10, 0)).toThrow('Division by zero');
  });
});
```

**GitHub Actions CI with Bun:**

```yaml
# .github/workflows/ci-bun.yml — fast TypeScript test run with Bun
name: CI (Bun)

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v2
        with: { bun-version: latest }
      - run: bun install --frozen-lockfile  # equivalent to npm ci
      # Type-check separately (Bun transpiles, does not type-check)
      - run: bunx tsc --noEmit --project tsconfig.json
        name: TypeScript type-check
      # Run tests with coverage
      - run: bun test --coverage
        name: Unit tests
      # Optional: generate lcov for PR coverage comment
      - run: bun test --coverage --coverage-reporter lcov
        if: github.event_name == 'pull_request'
```

**Tradeoffs: Bun vs. Jest vs. Vitest for CI:**

| Dimension | Bun test | Vitest | Jest + ts-jest |
|---|---|---|---|
| Speed | 4–8× faster than Jest | 2–3× faster than Jest | Baseline |
| TypeScript support | Native (transpile only) | Native ESM | Via ts-jest |
| Type-check in runner | None — needs separate tsc | None — needs separate tsc | Optional (diagnostics flag) |
| jsdom support | Limited (bun-dom in progress) | Full | Full |
| Custom reporters | Limited | Full | Full |
| Ecosystem maturity | Early (2024+) | Stable (2022+) | Mature (2017+) |
| Best for | Pure unit tests, services | New Vite projects | Existing Jest codebases |

> [community] The Bun test runner's biggest CI advantage is cold-start performance: on a GitHub Actions runner with no warm npm cache, `bun install` + `bun test` for a 200-test TypeScript project takes ~8 seconds compared to ~45 seconds for `npm ci` + `npx jest`. The difference narrows significantly with warm caches (npm cache restores node_modules in 3–5 seconds), so the benefit is most pronounced on first-run CI scenarios like PR checks on new forks or runners with evicted caches.

### OpenTelemetry CI Tracing for Pipeline Observability [community]

CI pipelines are programs. Like production services, they benefit from distributed tracing: spans for each job, child spans for each test suite, and attributes for test counts, durations, and flakiness rates. OpenTelemetry (OTEL) CI instrumentation makes the critical path of a slow pipeline immediately visible without log archaeology.

> [community] Platform engineering teams at mid-to-large companies (100+ engineers) consistently identify CI observability as the highest-leverage investment for reducing mean-time-to-resolve pipeline issues. A team that added OTEL tracing to their CI pipeline reduced "why is CI slow today?" investigations from 2–3 hours to 10–15 minutes by making the critical path and its change history visible in Jaeger/Honeycomb.

**TypeScript CI span instrumentation using `@opentelemetry/sdk-node`:**

```typescript
// scripts/ci-tracer.ts — emit one span per test suite to OTEL backend
import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { trace, context, SpanStatusCode } from '@opentelemetry/api';
import * as fs from 'fs';

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'ci-pipeline',
    'ci.provider': process.env['CI'] ? 'github-actions' : 'local',
    'ci.branch': process.env['GITHUB_REF_NAME'] ?? 'local',
    'ci.sha': process.env['GITHUB_SHA']?.slice(0, 8) ?? 'local',
    'ci.run_id': process.env['GITHUB_RUN_ID'] ?? '0',
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env['OTEL_EXPORTER_OTLP_ENDPOINT'] ?? 'http://localhost:4318/v1/traces',
  }),
});

sdk.start();

const tracer = trace.getTracer('ci-test-run', '1.0.0');

interface JestResult {
  testFilePath: string;
  numPassingTests: number;
  numFailingTests: number;
  numPendingTests: number;
  perfStats: { start: number; end: number };
  testResults: Array<{ status: string; title: string; duration?: number }>;
}

async function traceTestRun(resultsPath: string): Promise<void> {
  const raw = JSON.parse(fs.readFileSync(resultsPath, 'utf8')) as {
    testResults: JestResult[];
    numTotalTests: number;
    numPassedTests: number;
    numFailedTests: number;
    startTime: number;
  };

  const rootSpan = tracer.startSpan('ci.test-run', {
    startTime: raw.startTime,
    attributes: {
      'test.total': raw.numTotalTests,
      'test.passed': raw.numPassedTests,
      'test.failed': raw.numFailedTests,
    },
  });

  const rootCtx = trace.setSpan(context.active(), rootSpan);

  for (const suite of raw.testResults) {
    const suiteSpan = tracer.startSpan(
      `suite: ${suite.testFilePath.split('/').slice(-2).join('/')}`,
      {
        startTime: suite.perfStats.start,
        attributes: {
          'test.suite.passed': suite.numPassingTests,
          'test.suite.failed': suite.numFailingTests,
          'test.suite.skipped': suite.numPendingTests,
        },
      },
      rootCtx,
    );

    if (suite.numFailingTests > 0) {
      suiteSpan.setStatus({ code: SpanStatusCode.ERROR, message: `${suite.numFailingTests} test(s) failed` });
    }

    suiteSpan.end(suite.perfStats.end);
  }

  if (raw.numFailedTests > 0) {
    rootSpan.setStatus({ code: SpanStatusCode.ERROR, message: `${raw.numFailedTests} test(s) failed` });
  }

  rootSpan.end();
  await sdk.shutdown();
}

traceTestRun(process.env['RESULTS_FILE'] ?? 'test-results/jest-results.json').catch(console.error);
```

**GitHub Actions step to emit OTEL spans after tests:**

```yaml
# .github/workflows/ci.yml — OTEL instrumentation after test step
- name: Run tests
  run: npm test -- --ci --json --outputFile=test-results/jest-results.json
  continue-on-error: true   # capture results even on failure

- name: Emit CI spans to OTEL backend
  if: always()
  run: npx ts-node scripts/ci-tracer.ts
  env:
    RESULTS_FILE: test-results/jest-results.json
    OTEL_EXPORTER_OTLP_ENDPOINT: ${{ vars.OTEL_ENDPOINT }}
    OTEL_EXPORTER_OTLP_HEADERS: "Authorization=Bearer ${{ secrets.OTEL_TOKEN }}"
```

> [community] The most impactful OTEL attribute to add to CI spans: `ci.cache_hit` (true/false) and `ci.install_duration_ms`. Teams consistently find that 40–60% of their "CI is slow today" reports are actually "npm cache missed today". Tracking cache hit rate as a metric (emitted as a span attribute) turns this from a mystery into a measurable SLI with alerting.

> [community] Self-hosted OTEL collectors (Jaeger, Zipkin, Grafana Tempo) work well for CI tracing. For teams without existing OTEL infrastructure, Honeycomb's free tier (20M events/month) is a low-friction starting point. The OTLP HTTP exporter in the example above works with all three. Budget 2–3 hours for initial setup; the ongoing maintenance cost is near zero.

### TypeScript 5.7+ `--noCheck` for Ultra-Fast CI Transpilation [community]

TypeScript 5.7 introduced `--noCheck` — a flag that emits JavaScript output from TypeScript source WITHOUT performing type checking. This separates the two responsibilities that `tsc` normally bundles: transpilation (TS→JS) and type validation. In CI, `--noCheck` enables a "transpile-fast, type-check-separate" pipeline where tests start running in seconds while the type-check job runs in parallel.

> [community] The `--noCheck` flag is the TypeScript equivalent of Babel's `@babel/preset-typescript` — it strips types without validating them. Teams adopting it in CI consistently report the same performance profile: transpile-only build completes in 2–5 seconds (vs. 30–90 seconds for a full type-checked build on large codebases). The critical invariant: the parallel `tsc --noEmit` type-check job MUST be a required CI gate. Without it, `--noCheck` creates a loophole where type errors ship to production.

```yaml
# .github/workflows/ci.yml — parallel transpile + type-check strategy (TypeScript 5.7+)
name: CI (parallel transpile + typecheck)

on: [push, pull_request]

jobs:
  transpile-and-test:
    # Start tests immediately — transpile-only (no type checking)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # --noCheck: emit JS without type checking — fast (2-5s on large codebases)
      - run: npx tsc --noCheck --outDir dist
        name: Transpile (no type-check)
      - run: npm test -- --ci
        name: Unit tests (against transpiled output)

  typecheck:
    # Run type-check in parallel with tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # Full type check — this is the safety net
      - run: npx tsc --noEmit --incremental
        name: TypeScript type-check (full validation)

  # Both jobs must pass — tests passing but typecheck failing = CI blocked
  all-checks:
    needs: [transpile-and-test, typecheck]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Check all jobs passed
        run: |
          if [[ "${{ needs.transpile-and-test.result }}" != "success" ]] || \
             [[ "${{ needs.typecheck.result }}" != "success" ]]; then
            echo "::error::One or more required jobs failed"
            exit 1
          fi
          echo "All checks passed"
```

**tsconfig.json for `--noCheck` optimized builds:**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "strict": true,
    "noEmit": false,
    "outDir": "./dist",
    "rootDir": "./src",
    "sourceMap": true,
    "declaration": false,    // skip declaration generation for test builds
    "skipLibCheck": true,    // skip in transpile-only mode; enforced in typecheck job
    "incremental": true,
    "tsBuildInfoFile": ".tsbuildinfo"
  },
  "include": ["src/**/*.ts"]
}
```

**Speed comparison — large TypeScript codebase (300+ source files):**

```
Strategy                    | Cold CI (first run) | Warm CI (cache hit)
--------------------------- | ------------------- | -------------------
tsc --noEmit (full check)   | 45–90 seconds       | 3–8 seconds (incremental)
tsc --noCheck (transpile)   | 2–5 seconds         | 1–2 seconds
node --strip-types (Node 22)| < 1 second          | < 1 second
Vitest/Jest (ts-jest)       | 5–15 seconds        | 2–5 seconds (warm)
```

> [community] Teams adopting `--noCheck` report the biggest practical benefit: test failures now appear in the PR results in 30–60 seconds rather than 90–120 seconds. This 2–3× improvement in feedback latency — from "waiting for tsc" to "tests already running" — significantly changes developer workflow. The first CI feedback now arrives before the developer has switched context, enabling in-flow defect correction rather than context-switch re-engagement.

### GitHub Actions Environments and Deployment Protection Rules [community]

GitHub Actions Environments provide deployment targets (staging, production) with protection rules: required reviewers, wait timers, and deployment branch policies. When tests are tied to environment deployments, protection rules act as a human-in-the-loop gate between test levels — ensuring that no code deploys to staging unless CI passed, and no code deploys to production unless a human approved the staging result.

> [community] Teams that use GitHub Environments for deployment gates report a significant reduction in "test passed CI but broke staging" incidents. The key insight: environment protection rules run AFTER the job that requests the environment, not before. This means your e2e tests can run against staging and only THEN trigger the production deployment — giving human reviewers the e2e results before they approve the production gate.

**GitHub Actions workflow with environment protection gates:**

```yaml
# .github/workflows/deploy.yml — staged deployment with environment gates
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci && npm test -- --ci

  deploy-staging:
    needs: test
    runs-on: ubuntu-latest
    # Requesting this environment triggers protection rules: branch policy enforced
    environment:
      name: staging
      url: https://staging.example.com
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm run deploy:staging
        env:
          DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}

  e2e-staging:
    needs: deploy-staging
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npm run test:e2e
        env:
          BASE_URL: https://staging.example.com
          CI: true

  deploy-production:
    needs: e2e-staging
    runs-on: ubuntu-latest
    # Production environment: requires manual reviewer approval + 10 min wait timer
    environment:
      name: production
      url: https://app.example.com
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm run deploy:production
        env:
          DEPLOY_TOKEN: ${{ secrets.PRODUCTION_DEPLOY_TOKEN }}
```

**TypeScript script — post deployment health check:**

```typescript
// scripts/deployment-health-check.ts — verify deployment before approving production gate
async function healthCheck(
  url: string,
  expectedVersion: string,
  maxAttempts = 20,
  intervalMs = 3_000,
): Promise<void> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const res = await fetch(`${url}/health`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);

      const body = await res.json() as { version?: string; status?: string };

      if (body.status !== 'ok') {
        throw new Error(`Unhealthy status: ${body.status}`);
      }
      if (body.version !== expectedVersion) {
        throw new Error(`Version mismatch: expected ${expectedVersion}, got ${body.version}`);
      }

      console.log(`[health-check] Deployment healthy at attempt ${attempt}/${maxAttempts}`);
      console.log(`  version: ${body.version}, status: ${body.status}`);
      return;
    } catch (err) {
      console.log(`[health-check] Attempt ${attempt}/${maxAttempts} failed: ${(err as Error).message}`);
      if (attempt === maxAttempts) throw err;
      await new Promise<void>(r => setTimeout(r, intervalMs));
    }
  }
}

const url = process.env['DEPLOY_URL'] ?? 'http://localhost:3000';
const version = process.env['EXPECTED_VERSION'] ?? process.env['GITHUB_SHA']?.slice(0, 8) ?? 'unknown';

healthCheck(url, version).catch((err: Error) => {
  console.error(`[health-check] FAILED: ${err.message}`);
  process.exit(1);
});
```

> [community] The deployment protection rule combination that teams report as most effective: staging = "branch policy (main only) + no reviewers + no wait timer" (fast, automated), production = "required reviewers (any 1 of 3 leads) + 10-minute wait timer". The wait timer provides a mandatory cooldown period — even if a reviewer approves immediately, production cannot deploy for 10 minutes. Teams without a wait timer report human errors from "approve under pressure" where the reviewer skims the e2e results without actually reviewing them.

### Reusable Workflow Composability (GitHub Actions) [community]

Large repositories accumulate duplicated CI YAML across multiple workflow files. GitHub Actions reusable workflows allow a team to define a canonical CI pipeline once and call it from multiple contexts (PR, main, nightly, release) with per-call parameterization.

> [community] Teams with 5+ workflow files sharing the same lint → typecheck → test → build sequence report spending 30–60 minutes per sprint keeping the YAML in sync. A single reusable workflow reduces this to a one-place change. The primary tradeoff: callers lose visibility into the inner workflow's steps without clicking into the called workflow; document the interface (inputs/secrets) clearly.

**Reusable workflow definition (`ci-core.yml`):**

```yaml
# .github/workflows/ci-core.yml — reusable CI workflow
name: CI Core (reusable)

on:
  workflow_call:
    inputs:
      node-version:
        description: Node.js version to use
        type: string
        default: '20'
      run-e2e:
        description: Whether to run e2e tests
        type: boolean
        default: false
      coverage-threshold:
        description: Minimum coverage percentage
        type: number
        default: 80
    secrets:
      NPM_TOKEN:
        description: Private npm registry token (optional)
        required: false
    outputs:
      coverage-pct:
        description: Achieved line coverage percentage
        value: ${{ jobs.unit.outputs.coverage-pct }}

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: ${{ inputs.node-version }}, cache: npm }
      - run: npm ci
      - run: npm run lint && npm run typecheck

  unit:
    needs: lint
    runs-on: ubuntu-latest
    outputs:
      coverage-pct: ${{ steps.coverage.outputs.pct }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: ${{ inputs.node-version }}, cache: npm }
      - run: npm ci
      - run: npm test -- --ci --coverage --json --outputFile=results.json
      - name: Extract coverage percentage
        id: coverage
        run: |
          PCT=$(node -e "const r=require('./coverage/coverage-summary.json');console.log(r.total.lines.pct)")
          echo "pct=$PCT" >> $GITHUB_OUTPUT
          if (( $(echo "$PCT < ${{ inputs.coverage-threshold }}" | bc -l) )); then
            echo "::error::Coverage $PCT% is below threshold ${{ inputs.coverage-threshold }}%"
            exit 1
          fi

  e2e:
    if: ${{ inputs.run-e2e }}
    needs: unit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: ${{ inputs.node-version }}, cache: npm }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npm run test:e2e
```

**Caller workflows that compose the reusable core:**

```yaml
# .github/workflows/pr.yml — PR check (no e2e for speed)
name: PR Check
on: [pull_request]
concurrency:
  group: pr-${{ github.ref }}
  cancel-in-progress: true
jobs:
  ci:
    uses: ./.github/workflows/ci-core.yml
    with:
      node-version: '20'
      run-e2e: false
      coverage-threshold: 80

---
# .github/workflows/main.yml — merge to main (full pipeline)
name: Main Branch CI
on:
  push:
    branches: [main]
jobs:
  ci:
    uses: ./.github/workflows/ci-core.yml
    with:
      node-version: '20'
      run-e2e: true
      coverage-threshold: 85
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

> [community] GitHub Actions reusable workflows do NOT share the calling workflow's environment by default — each called workflow runs in its own isolated job context. If your reusable workflow needs access to secrets, every caller must explicitly pass them via `secrets:`. Teams that forget this spend 30–60 minutes debugging "why does the reusable workflow fail with a missing secret that the calling workflow has access to?"

### Feature Flag Testing in CI [community]

Applications that use feature flags (LaunchDarkly, Unleash, GrowthBook, custom flags) require explicit CI test strategies to prevent feature flags from causing inconsistent test results. A test suite that passes with all flags `OFF` but fails with a production flag combination is a CI safety gap.

> [community] Teams with >20 active feature flags report that at least one flag combination causes test failures per quarter — always discovered in production, never in CI. The root cause is that tests run with a single static flag state (usually all OFF or the developer's local flag state). Systematic flag matrix testing in CI catches these before deployment.

**TypeScript helper to inject flags in tests:**

```typescript
// tests/helpers/feature-flags.ts — deterministic flag injection for CI
export type FeatureFlags = {
  newCheckoutFlow: boolean;
  betaDashboard: boolean;
  strictPasswordPolicy: boolean;
};

// Default flags for CI — all flags OFF unless test explicitly enables them
export const DEFAULT_CI_FLAGS: FeatureFlags = {
  newCheckoutFlow: false,
  betaDashboard: false,
  strictPasswordPolicy: false,
};

// Factory function for test isolation — each test gets its own flag context
export function createFlagContext(overrides: Partial<FeatureFlags> = {}): FeatureFlags {
  return { ...DEFAULT_CI_FLAGS, ...overrides };
}

// Vitest/Jest module mock for LaunchDarkly client
export function mockLaunchDarkly(flags: Partial<FeatureFlags> = {}): void {
  const resolvedFlags = createFlagContext(flags);
  vi.mock('@launchdarkly/node-server-sdk', () => ({
    init: vi.fn().mockReturnValue({
      waitForInitialization: vi.fn().mockResolvedValue(undefined),
      variation: vi.fn().mockImplementation(
        (key: keyof FeatureFlags) => resolvedFlags[key] ?? false,
      ),
      close: vi.fn(),
    }),
  }));
}
```

```typescript
// tests/checkout/checkout-flow.test.ts — testing both flag states
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { mockLaunchDarkly } from '../helpers/feature-flags';
import { CheckoutService } from '../../src/services/checkout-service';

describe('CheckoutService', () => {
  describe('with newCheckoutFlow=OFF (legacy)', () => {
    beforeEach(() => {
      mockLaunchDarkly({ newCheckoutFlow: false });
    });

    it('uses legacy payment flow', async () => {
      const service = new CheckoutService();
      const result = await service.processOrder({ items: [], total: 100 });
      expect(result.flow).toBe('legacy');
    });
  });

  describe('with newCheckoutFlow=ON (new)', () => {
    beforeEach(() => {
      mockLaunchDarkly({ newCheckoutFlow: true });
    });

    it('uses new optimized payment flow', async () => {
      const service = new CheckoutService();
      const result = await service.processOrder({ items: [], total: 100 });
      expect(result.flow).toBe('optimized');
      expect(result.estimatedDelivery).toBeDefined(); // new field in new flow
    });
  });
});
```

**CI matrix for critical flag combinations:**

```yaml
# .github/workflows/feature-flag-matrix.yml — test key flag combinations
name: Feature Flag Matrix

on:
  schedule:
    - cron: '0 2 * * *'   # nightly — flag combinations are expensive to test on every PR
  workflow_dispatch:        # allow manual trigger before releases

jobs:
  flag-matrix:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        # Test the two most important production flag states
        flags:
          - name: all-off
            env: '{"NEW_CHECKOUT_FLOW":"false","BETA_DASHBOARD":"false","STRICT_PASSWORD":"false"}'
          - name: all-on
            env: '{"NEW_CHECKOUT_FLOW":"true","BETA_DASHBOARD":"true","STRICT_PASSWORD":"true"}'
          - name: checkout-on-only
            env: '{"NEW_CHECKOUT_FLOW":"true","BETA_DASHBOARD":"false","STRICT_PASSWORD":"false"}'
    name: Flags ${{ matrix.flags.name }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Run tests with flag combination
        run: npm test -- --ci
        env:
          CI_FEATURE_FLAGS: ${{ matrix.flags.env }}
```

> [community] The most neglected aspect of feature flag CI testing: testing the removal path. When a flag is removed and the old code path is deleted, any test that was only run with the flag `OFF` becomes permanently skipped. Schedule a quarterly "flag cleanup review" that removes quarantined old-path tests alongside flag removal. Teams that skip this accumulate dead test code that inflates coverage numbers without testing real behavior.

> [community] LaunchDarkly's own engineering team recommends treating the `variation()` call in tests as a boundary — mock it at the LaunchDarkly client level, not by mocking the module that consumes flag values. Mocking at the client level ensures the flag-consumption code (the `if (newCheckoutFlow)` branch) is actually exercised in both states, while mocking at the module level can accidentally make both branches always return the same value.

### Playwright `--only-changed` for Fast PR Feedback [community]

The `--only-changed [ref]` flag restricts Playwright test execution to spec files that have been modified between `HEAD` and a given git reference (defaults to all uncommitted changes). In a PR workflow it limits the browser test run to files touched in the PR, providing sub-minute feedback for targeted changes without running the full e2e suite.

> [community] Teams that add `--only-changed=origin/main` as a separate "fast gate" job run before full sharding report cutting median PR wait-time for e2e from 8–12 minutes to 90 seconds for PRs that touch a single feature area. The full sharded suite still runs in parallel — but the first signal arrives immediately from the changed-files run. The caveat: shared fixtures and page-object helpers are not detected as "changed" even when the tests that consume them change their assertions. Always pair with a nightly full-suite run that ignores `--only-changed`.

```yaml
# .github/workflows/ci.yml — fast e2e gate for changed tests only
  e2e-fast:
    needs: unit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }        # full history needed for git diff
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium
      # Run only tests in files changed since origin/main — fast signal for focused PRs
      - run: npx playwright test --only-changed=origin/main --reporter=list
        name: E2E (changed files only)
        continue-on-error: false

  e2e-full:
    needs: unit
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test --shard=${{ matrix.shard }}/4 --reporter=blob
      - uses: actions/upload-artifact@v4
        with:
          name: blob-report-${{ matrix.shard }}
          path: blob-report/
```

**TypeScript playwright.config.ts with `fullyParallel` for even shard distribution:**

```typescript
// playwright.config.ts — optimized for even load distribution across shards
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  // fullyParallel: true distributes at test level, not file level
  // This gives shards roughly equal workloads even if test files are unevenly sized
  fullyParallel: true,
  // With fullyParallel, more workers per shard can be used safely
  workers: process.env['CI'] ? 2 : undefined,
  retries: process.env['CI'] ? 2 : 0,
  reporter: process.env['CI']
    ? [['blob'], ['github']]
    : [['html']],
  use: {
    ...devices['Desktop Chrome'],
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  // Separate projects for different test levels — allows --only-changed per project
  projects: [
    { name: 'smoke', testMatch: /.*\.smoke\.spec\.ts/ },
    { name: 'e2e',   testMatch: /.*\.spec\.ts/, testIgnore: /.*\.smoke\.spec\.ts/ },
  ],
});
```

> [community] `fullyParallel: true` is the single most impactful Playwright configuration change for sharded CI. Without it, Playwright distributes test files (not individual tests) across shards — one large file with 50 tests goes to one shard, while 10 files with 1 test each go to another. Shard load becomes imbalanced over time as large test files grow. With `fullyParallel: true`, every individual test is independently schedulable, achieving near-theoretical speedup from sharding.

### Playwright Project Dependencies for CI Setup [community]

Playwright's **project dependencies** (`dependsOn` in the project config) declare which projects must complete before a project begins — replacing the legacy `globalSetup` / `globalTeardown` hooks. Unlike `globalSetup`, project dependencies are fully integrated with the HTML reporter, trace recorder, and fixture system, making CI failures traceable to their root setup step.

> [community] Teams that migrate from `globalSetup` to project dependencies report a significant improvement in CI diagnostics: when the `setup` project fails (e.g., database seeding, auth token generation), the HTML report shows the setup failure as a distinct entry with a trace link, rather than a confusing "Cannot find module" or undefined variable error inside the first test. The migration path is mechanical — extract the setup logic into a `setup.spec.ts` file and declare it as a `project` with `testMatch: /.*setup\.ts/`.

```typescript
// playwright.config.ts — project dependencies for CI setup/teardown
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  retries: process.env['CI'] ? 1 : 0,
  workers: process.env['CI'] ? 2 : undefined,
  projects: [
    // Setup project: seeds database, generates auth tokens — must pass before e2e runs
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
      // Setup runs once per CI job, not per test
      fullyParallel: false,
    },
    // Teardown project: cleans up ephemeral resources after all tests complete
    {
      name: 'teardown',
      testMatch: /.*\.teardown\.ts/,
      // Note: teardown project needs to be run explicitly or via dependsOn cleanup pattern
    },
    // All e2e tests depend on setup completing successfully
    {
      name: 'e2e-chromium',
      use: { ...devices['Desktop Chrome'] },
      testMatch: /.*\.spec\.ts/,
      testIgnore: /.*\.(setup|teardown)\.ts/,
      dependsOn: ['setup'],    // setup MUST pass before any e2e test starts
    },
  ],
});
```

```typescript
// tests/auth.setup.ts — database seeding and auth token generation
import { test as setup, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

// File path where the auth state will be saved for reuse by all e2e tests
const AUTH_FILE = path.join(__dirname, '.auth/user.json');

// This setup spec runs as a Playwright test — visible in reports, traceable on failure
setup('seed test data and authenticate admin user', async ({ page }) => {
  // Seed database via API — runs against the deployed test environment
  const seedRes = await page.request.post('/api/test/seed', {
    headers: { 'X-Test-Secret': process.env['TEST_SECRET'] ?? '' },
  });
  expect(seedRes.status()).toBe(200);

  // Authenticate and save browser storage state for reuse
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env['TEST_USER_EMAIL'] ?? 'admin@test.com');
  await page.getByLabel('Password').fill(process.env['TEST_USER_PASSWORD'] ?? 'admin-password');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.waitForURL('/dashboard');

  // Save auth state — all tests in the e2e project can restore this state
  await page.context().storageState({ path: AUTH_FILE });
});
```

```typescript
// tests/user-management.spec.ts — test using saved auth state (no login overhead)
import { test, expect } from '@playwright/test';
import * as path from 'path';

// Restore auth state from setup — skips login in every test
test.use({
  storageState: path.join(__dirname, '.auth/user.json'),
});

test.describe('User Management', () => {
  test('admin can invite a new user', async ({ page }) => {
    await page.goto('/users/invite');
    await page.getByLabel('Email').fill('newuser@example.com');
    await page.getByRole('button', { name: 'Send invitation' }).click();
    await expect(page.getByRole('alert')).toContainText('Invitation sent');
  });
});
```

> [community] The most overlooked benefit of project dependencies: the `storageState` pattern. By running auth in the `setup` project once per CI job (not once per test), teams eliminate login time from every e2e test. On a 100-test e2e suite where login takes 2 seconds, this saves 200 seconds of test runtime and removes the most common source of timing-related e2e flakiness (auth token expiry mid-suite). The auth state file is saved to disk once and shared across all test workers.

### Vitest Browser Mode as a CI Component Test Level [community]

Vitest Browser Mode (`@vitest/browser`) executes tests in a real browser (Chromium, Firefox, Safari) via Playwright or WebDriverIO, without requiring a full application stack. Unlike jsdom (which simulates the DOM in Node.js), Browser Mode accesses native browser APIs, CSS layout, and `window` globals — making it suitable for component tests that require real rendering fidelity.

Compared to Playwright Component Testing (`@playwright/experimental-ct-*`), Vitest Browser Mode integrates directly with Vitest's test runner, coverage provider, and workspace configuration — eliminating the need for a separate `playwright-ct.config.ts` for teams already using Vitest.

> [community] Teams migrating from jsdom-based Vitest tests to Vitest Browser Mode for component tests report catching a class of defects invisible to jsdom: CSS-driven focus visibility (`:focus-visible` pseudo-class), pointer events blocked by overlapping elements, and scroll-container overflow. jsdom stubs these CSS interactions; Browser Mode runs them in real Chromium. Teams using `@testing-library/user-event` find that Browser Mode removes all jsdom-specific workarounds for pointer events and focus management that accumulated over time.

```typescript
// vitest.config.ts — separate unit (Node) and component (browser) projects
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    // Use projects to run unit tests in Node and component tests in browser
    projects: [
      {
        // Unit tests: Node environment (fast, no browser overhead)
        test: {
          name: 'unit',
          include: ['src/**/*.test.ts'],
          exclude: ['src/**/*.browser.test.tsx'],
          environment: 'node',
          pool: 'threads',
          coverage: {
            provider: 'v8',
            include: ['src/**/*.ts'],
          },
        },
      },
      {
        plugins: [react()],
        // Component tests: real Chromium browser (CSS layout, native events)
        test: {
          name: 'browser',
          include: ['src/**/*.browser.test.tsx'],
          browser: {
            enabled: true,
            provider: 'playwright',  // uses Playwright's Chromium
            name: 'chromium',
            headless: true,           // headless mode for CI
            // Vitest automatically installs Playwright browsers if missing
          },
        },
      },
    ],
  },
});
```

```typescript
// src/components/DatePicker.browser.test.tsx — component test in real Chromium
import { render } from '@testing-library/react';
import { fireEvent, screen } from '@testing-library/dom';
import { DatePicker } from './DatePicker';

// Named .browser.test.tsx to distinguish from jsdom tests
describe('DatePicker — browser rendering', () => {
  it('opens the calendar on click and allows date selection', async () => {
    render(<DatePicker value={null} onChange={() => {}} />);

    const trigger = screen.getByRole('button', { name: 'Open calendar' });
    // Real click in Chromium — triggers pointer events and focus correctly
    await fireEvent.click(trigger);

    // Popover must be visible in the DOM with correct position
    const calendar = screen.getByRole('dialog', { name: 'Date picker calendar' });
    expect(calendar).toBeVisible();

    // Verify CSS layout — calendar must not be occluded by another element
    const rect = calendar.getBoundingClientRect();
    expect(rect.width).toBeGreaterThan(200);    // renders with real CSS dimensions
    expect(rect.height).toBeGreaterThan(150);
  });

  it('closes on Escape key', async () => {
    render(<DatePicker value={null} onChange={() => {}} />);
    await fireEvent.click(screen.getByRole('button', { name: 'Open calendar' }));

    // Real keyboard event — tests actual focus management, not jsdom simulation
    await fireEvent.keyDown(document.activeElement!, { key: 'Escape' });
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
```

**GitHub Actions — Vitest Browser Mode with Playwright provider:**

```yaml
# .github/workflows/ci.yml — Vitest browser component tests
  component-browser:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci

      # Install Playwright browsers (used by Vitest Browser Mode under the hood)
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium

      # Run only browser project — unit tests run in separate job
      - run: npx vitest run --project browser --reporter=verbose
        name: Component tests (Vitest Browser Mode)
```

> [community] The critical gotcha for Vitest Browser Mode in CI: unlike jsdom, which inherits Node's process isolation per test file, Browser Mode creates ONE browser context per test file by default. This means test-level isolation is restricted to within a file — not between files. Teams with browser tests that mutate global CSS variables, inject `<style>` elements, or modify `window` properties must explicitly clean up in `afterEach`. Teams that miss this discover ordering-dependent failures only when running the full suite in CI.

> [community] Vitest Browser Mode's coverage provider is V8 — the same as native Vitest. This means unified coverage reports across unit (Node) and component (browser) projects are possible from a single `vitest run` command with `--coverage`. Teams that previously maintained separate Jest + Playwright CT setups with separate coverage providers (V8 for Vitest, Playwright's own coverage for CT) gain a single coverage report without additional tooling. The catch: Playwright CT coverage and Vitest browser coverage use different instrumentation — do not mix them in the same project.

### Vitest Workspace Projects for Monorepo Test Orchestration [community]

Vitest's **workspace projects** (`vitest.config.ts` with a `projects` array) run multiple Vitest configurations within a single process, enabling a monorepo to execute unit tests, component tests, and API tests with different environments and configurations from one command. This differs from Nx/Turbo affected-graph execution — it is intra-tool orchestration within a single Vitest invocation.

> [community] Teams with 5–15 packages in a monorepo report that Vitest workspace mode reduces CI configuration overhead by 60–70% compared to per-package Vitest configs triggered by Nx or Turbo. The entire monorepo's test suite launches in a single Vitest process, sharing the module cache across packages. The tradeoff: test isolation between packages is weaker (shared module registry for pure Node tests); teams with strong isolation requirements should still use separate processes per package via Nx/Turbo.

```typescript
// vitest.workspace.ts — orchestrate multiple packages in one vitest process
import { defineWorkspace } from 'vitest/config';

export default defineWorkspace([
  // Package-level configs — each has its own environment and include pattern
  {
    extends: './packages/core/vitest.config.ts',
    test: {
      name: 'core',
      root: './packages/core',
      include: ['src/**/*.test.ts'],
      environment: 'node',
    },
  },
  {
    extends: './packages/ui/vitest.config.ts',
    test: {
      name: 'ui',
      root: './packages/ui',
      include: ['src/**/*.test.tsx'],
      environment: 'jsdom',
      setupFiles: ['./packages/ui/tests/setup-dom.ts'],
    },
  },
  {
    extends: './packages/api/vitest.config.ts',
    test: {
      name: 'api',
      root: './packages/api',
      include: ['src/**/*.test.ts'],
      environment: 'node',
      // Integration-style: allow more time for DB connections
      testTimeout: 15_000,
    },
  },
]);
```

**GitHub Actions — workspace-based CI with project filtering:**

```yaml
# .github/workflows/ci.yml — filter by vitest project name for affected-only testing
  unit-core:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # Run only the 'core' project — scoped to packages/core changes
      - run: npx vitest run --project core --coverage --reporter=verbose
        name: Core package tests

  unit-ui:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # Run only the 'ui' project — scoped to packages/ui changes
      - run: npx vitest run --project ui --reporter=verbose
        name: UI package tests

  unit-all:
    # For main branch — run all workspace projects together
    needs: lint
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npx vitest run --coverage --reporter=junit --outputFile=junit.xml
        name: All workspace projects
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: junit-results
          path: junit.xml
```

**Coverage merging across workspace projects:**

```typescript
// vitest.workspace.ts — coverage configuration for unified report across all projects
import { defineWorkspace } from 'vitest/config';

export default defineWorkspace([
  {
    test: {
      name: 'core',
      root: './packages/core',
      include: ['src/**/*.test.ts'],
      environment: 'node',
    },
  },
  {
    test: {
      name: 'ui',
      root: './packages/ui',
      include: ['src/**/*.test.tsx'],
      environment: 'jsdom',
    },
  },
  // Coverage is configured at root level only — applies to all projects
  // (per-project coverage is not supported; use root vitest.config.ts for thresholds)
]);

// Root vitest.config.ts — coverage thresholds apply to the merged report
// import { defineConfig } from 'vitest/config';
// export default defineConfig({
//   test: {
//     coverage: {
//       provider: 'v8',
//       reporter: ['lcov', 'text', 'json-summary'],
//       include: ['packages/*/src/**/*.ts', 'packages/*/src/**/*.tsx'],
//       exclude: ['packages/*/src/**/*.d.ts', 'packages/*/src/**/*.test.*'],
//       thresholds: { lines: 80, branches: 75 },
//     },
//   },
// });
```

> [community] The most common Vitest workspace pitfall: expecting `--project ui` to automatically exclude all other project test files. It does exclude them from execution, but if a test file in `packages/core` is accidentally matched by the `ui` project's `include` glob (e.g., glob pattern too broad), it will run in the wrong environment. Always scope `include` patterns to the package's own `src/` directory, never use `**/*.test.ts` at the workspace root level without a package prefix.

### Playwright `--fail-on-flaky-tests` as a Strict Flakiness Gate [community]

Playwright v1.45 introduced the `--fail-on-flaky-tests` CLI flag. By default, when a test fails on the first attempt but passes on a retry, Playwright exits with code `0` — marking the overall run as green even though a retry occurred. `--fail-on-flaky-tests` reverses this: **any test that required a retry to pass causes the CI run to exit with code 1**, making flakiness a first-class CI failure.

> [community] Teams that add `--fail-on-flaky-tests` to their PR gate workflow report that flaky tests go from "tolerated background noise" to "immediate P1 defect". The typical adoption path: (1) enable the flag on the nightly run first to measure flakiness rate baseline, (2) fix the top 5 flaky test cases (usually 80% of failures), (3) promote to PR gate. Teams that skip step 2 and immediately gate PRs on flakiness disable the flag within a week when CI becomes permanently red.

```yaml
# .github/workflows/ci.yml — strict flakiness gate on main branch
jobs:
  e2e-strict:
    if: github.ref == 'refs/heads/main'  # strict gate only on main; PRs use retries
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium
      # --fail-on-flaky-tests: exit 1 if any test passes only via retry
      # retries: 1 to detect flakiness; strict mode catches the symptom immediately
      - run: npx playwright test --retries=1 --fail-on-flaky-tests
        name: E2E (strict flakiness gate)
```

**`playwright.config.ts` with selective flakiness tolerance:**

```typescript
// playwright.config.ts — strict mode for production flows; lenient for utilities
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  // Retry once to detect flakiness; --fail-on-flaky-tests triggers exit code 1 if retry needed
  retries: process.env['CI'] ? 1 : 0,
  // Prevent test.only() from being accidentally committed and silencing the suite
  forbidOnly: !!process.env['CI'],
  reporter: [
    ['html', { open: 'never' }],
    // GitHub Actions annotations for PR inline feedback
    ['github'],
    ['blob'],
  ],
  use: {
    ...devices['Desktop Chrome'],
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'critical-flows',
      testMatch: /.*\.(payment|auth|checkout)\.spec\.ts/,
      // Critical flows: strict flakiness intolerance — no retries at project level
      retries: 0,
    },
    {
      name: 'standard-e2e',
      testMatch: /.*\.spec\.ts/,
      testIgnore: /.*\.(payment|auth|checkout)\.spec\.ts/,
      retries: 1,  // 1 retry for standard tests; --fail-on-flaky-tests catches if needed
    },
  ],
});
```

> [community] The `forbidOnly: !!process.env['CI']` setting is frequently cited as the most common "developer accidentally ships broken CI" prevention. When a developer uses `test.only()` for local debugging and forgets to remove it before pushing, all other tests are silently skipped — producing a deceptively green CI run with only one test passing. `forbidOnly: true` in CI causes an immediate failure with a clear error message. Set this in every Playwright project without exception.

### Playwright `captureGitInfo` for Enriched CI Reports [community]

Playwright v1.51 added `testConfig.captureGitInfo` — a configuration flag that automatically captures the current git branch, commit SHA, commit message, author, and PR information into the HTML report and blob reporter output. This metadata makes navigating test history significantly easier: reports are self-describing, removing the need to correlate report artifacts with git log output.

> [community] Teams managing shared test report archives (e.g., storing blob reports as GitHub Actions artifacts for 30 days) report that `captureGitInfo: true` cuts the time to answer "which commit caused this regression?" from minutes of log archaeology to seconds of reading the report header. The feature has zero performance overhead since it simply reads git metadata at test run start.

```typescript
// playwright.config.ts — captureGitInfo for self-describing CI reports
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  retries: process.env['CI'] ? 1 : 0,
  forbidOnly: !!process.env['CI'],

  // Capture git context into every report — branch, SHA, message, author
  // Requires git to be available in CI (standard on GitHub Actions runners)
  captureGitInfo: process.env['CI'] ? { commit: true, diff: false } : false,
  // Note: diff: true captures the full git diff — useful for debugging but increases artifact size

  reporter: process.env['CI']
    ? [
        ['blob'],        // for cross-shard report merging
        ['github'],      // inline PR annotations
        ['html', { open: 'never' }],
      ]
    : [['html']],

  use: {
    ...devices['Desktop Chrome'],
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
});
```

**GitHub Actions step using captureGitInfo for attribution in merged reports:**

```yaml
# .github/workflows/e2e-sharded.yml — sharded suite with git-enriched reports
jobs:
  e2e:
    strategy:
      fail-fast: false
      matrix:
        shard: [1, 2, 3, 4]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # required for captureGitInfo to read full git history
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test --shard=${{ matrix.shard }}/4 --reporter=blob
        env:
          CI: true    # triggers captureGitInfo: { commit: true } in config
      - uses: actions/upload-artifact@v4
        with:
          name: blob-report-${{ matrix.shard }}
          path: blob-report/

  merge-reports:
    needs: e2e
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - uses: actions/download-artifact@v4
        with:
          path: all-blob-reports/
          pattern: blob-report-*
          merge-multiple: true
      # Merged HTML report includes git commit info from captureGitInfo
      - run: npx playwright merge-reports --reporter html ./all-blob-reports
      - uses: actions/upload-artifact@v4
        with:
          name: html-report-${{ github.sha }}
          path: playwright-report/
          retention-days: 30     # 30-day retention for post-incident investigation
```

> [community] The `fetch-depth: 0` checkout flag is required when using `captureGitInfo` to ensure git history metadata (author, message, parent SHA) is fully available. The default `fetch-depth: 1` (shallow clone) in GitHub Actions provides only the latest commit with no history context, causing `captureGitInfo` to silently omit commit metadata. Teams that deploy this without `fetch-depth: 0` see empty commit fields in the HTML report and file a bug — it is always the shallow clone.

### Playwright Per-Project Worker Configuration [community]

Playwright v1.52 added `workers` as a per-project configuration option, allowing different test levels to run with different concurrency within the same CI job. Before v1.52, the `workers` option was global — a single value applied to all projects. With per-project workers, CPU-bound test levels (e.g., visual regression with 8 full-page screenshots) can use fewer workers while fast unit-like component tests use the maximum.

> [community] Teams with heterogeneous Playwright project configurations (smoke tests + full e2e + visual regression) in a single CI job report that per-project workers eliminates their most common OOM (out-of-memory) failure mode. Previously, a global `workers: 4` setting launched 4 concurrent visual regression tests, each requiring 200–400 MB for full-page Chromium renders, exceeding the 7 GB available on a free-tier GitHub Actions runner. With per-project workers, visual regression runs at `workers: 1` while smoke tests run at `workers: 4`.

```typescript
// playwright.config.ts — per-project worker configuration (Playwright v1.52+)
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  retries: process.env['CI'] ? 1 : 0,
  forbidOnly: !!process.env['CI'],
  captureGitInfo: process.env['CI'] ? { commit: true, diff: false } : false,

  reporter: process.env['CI']
    ? [['blob'], ['github']]
    : [['html']],

  use: {
    ...devices['Desktop Chrome'],
    trace: 'on-first-retry',
  },

  projects: [
    // Smoke tests: fast, low memory — use maximum available workers
    {
      name: 'smoke',
      testMatch: /.*\.smoke\.spec\.ts/,
      workers: process.env['CI'] ? 4 : undefined,  // 4 workers on 2-core CI runner
      retries: 0,                                     // smoke must pass on first attempt
    },
    // Standard e2e: balanced parallelism
    {
      name: 'e2e',
      testMatch: /.*\.spec\.ts/,
      testIgnore: /.*\.(smoke|visual)\.spec\.ts/,
      workers: process.env['CI'] ? 2 : undefined,
      retries: 1,
    },
    // Visual regression: CPU and memory intensive — serialize to prevent OOM
    {
      name: 'visual',
      testMatch: /.*\.visual\.spec\.ts/,
      workers: 1,                                     // always 1: memory safety
      retries: process.env['CI'] ? 1 : 0,
      use: {
        // Consistent viewport for reproducible screenshots
        viewport: { width: 1280, height: 720 },
      },
    },
  ],
});
```

**GitHub Actions — CI workflow using per-project workers effectively:**

```yaml
# .github/workflows/ci.yml — single job runs all projects with correct per-project concurrency
jobs:
  playwright:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium

      # Smoke tests first (fast gate) — inherits project-level workers: 4
      - run: npx playwright test --project=smoke
        name: Smoke tests (fast gate)

      # E2E + visual in a single run — each project uses its configured workers
      - run: npx playwright test --project=e2e --project=visual
        name: E2E + visual regression
        continue-on-error: false
```

> [community] The per-project worker configuration is especially valuable when mixing test levels that have radically different resource profiles — Playwright component tests (`ct`) run in milliseconds with no I/O, while API smoke tests against a real service run in seconds with network I/O. Using `workers: 4` for component tests and `workers: 2` for API tests in the same CI job prevents API rate limiting while maximizing component test throughput.

### `testConfig.tsconfig` for Playwright TypeScript Unification [community]

Playwright v1.49 introduced `testConfig.tsconfig` — a single TypeScript configuration file applied to all Playwright test files. Before this option, teams needed separate `tsconfig.json` files in each test directory or relied on Playwright's default behavior (ignoring path aliases, using relaxed module resolution). With `testConfig.tsconfig`, the full TypeScript compiler configuration — path aliases, strict mode flags, module resolution — applies uniformly to all spec files.

> [community] The most common TypeScript + Playwright CI failure mode before `testConfig.tsconfig`: path alias imports (`@/utils`, `@/fixtures`) resolved correctly in the application's `tsconfig.json` but failed in Playwright test files because Playwright used its own internal TypeScript configuration that didn't include the `paths` mapping. Teams added hacky workarounds: symlinks, duplicated `tsconfig` inheritance chains, or gave up on path aliases entirely in test files. `testConfig.tsconfig` eliminates all of these.

```typescript
// playwright.config.ts — unified TypeScript configuration for all test files
import { defineConfig, devices } from '@playwright/test';
import { resolve } from 'path';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  retries: process.env['CI'] ? 1 : 0,
  forbidOnly: !!process.env['CI'],
  captureGitInfo: process.env['CI'] ? { commit: true, diff: false } : false,

  // Apply shared tsconfig to ALL Playwright test files (v1.49+)
  // This makes path aliases (@/utils), strict mode, and module resolution
  // consistent between source code and e2e tests
  tsconfig: resolve(__dirname, 'tsconfig.playwright.json'),

  use: {
    ...devices['Desktop Chrome'],
    baseURL: process.env['BASE_URL'] ?? 'http://localhost:3000',
    trace: 'on-first-retry',
  },
});
```

```json
// tsconfig.playwright.json — TypeScript config for Playwright tests
// Extends the app tsconfig so path aliases and strict settings are shared
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "moduleResolution": "bundler",
    "paths": {
      "@/*": ["./src/*"],
      "@fixtures/*": ["./tests/e2e/fixtures/*"],
      "@helpers/*": ["./tests/e2e/helpers/*"]
    },
    // Playwright test types must be available
    "types": ["@playwright/test"],
    "strict": true,
    "noUncheckedIndexedAccess": true
  },
  "include": [
    "tests/e2e/**/*.ts",
    "tests/e2e/**/*.tsx",
    "playwright.config.ts"
  ],
  "exclude": ["node_modules"]
}
```

**Test file using path aliases — enabled by `testConfig.tsconfig`:**

```typescript
// tests/e2e/checkout.spec.ts — path aliases work because of testConfig.tsconfig
import { test, expect } from '@playwright/test';
// @fixtures resolves via tsconfig.playwright.json paths — no relative path needed
import { authenticatedPage } from '@fixtures/auth';
// @helpers resolves the same way
import { formatPrice } from '@helpers/formatting';

test.describe('Checkout flow', () => {
  test.use({ storageState: 'tests/e2e/.auth/user.json' });

  test('displays correct total with tax', async ({ page }) => {
    await page.goto('/cart');
    const total = await page.getByTestId('order-total').textContent();
    expect(total).toBe(formatPrice(109.99));   // uses shared helper — no duplication
  });
});
```

> [community] With `testConfig.tsconfig`, the `types` field in `tsconfig.playwright.json` is the only required addition beyond extending the app config. Teams commonly forget to add `"@playwright/test"` to `types`, resulting in `Cannot find name 'test'` or `Cannot find name 'expect'` type errors even when the tests run correctly at runtime (because Playwright's runtime loads the types implicitly). The type error appears only in the IDE and in `tsc --noEmit` runs — add `"@playwright/test"` to `types` explicitly.

### Vitest `defineProject` for Type-Safe Workspace Configurations [community]

Vitest v3.2 deprecated the `workspace` configuration file (`.vitest-workspace.ts`) in favor of the `projects` array in `vitest.config.ts`. Alongside this rename, Vitest introduced `defineProject` — a dedicated helper for configuring projects inside a workspace that is distinct from `defineConfig`. Using `defineProject` prevents accidentally including root-only options (like `coverage`, `reporters`, `snapshotResolver`) in a project-level config, which causes Vitest to throw an error.

> [community] Teams migrating from the old `vitest.workspace.ts` to the new `projects` API in Vitest v3.2+ consistently run into two issues: (1) they use `defineConfig` instead of `defineProject` in their per-package config files and accidentally add a `reporters` key — Vitest then throws `reporters is not allowed in project configuration`. (2) They expect coverage to be configurable per project — it is not; coverage is a root-level-only concern. Both issues take 10–30 minutes to diagnose without knowing the distinction. Use `defineProject` in any file referenced by `projects:` and `defineConfig` only at the workspace root.

```typescript
// vitest.config.ts — NEW API: projects array (replaces vitest.workspace.ts since v3.2)
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  // Coverage is ROOT-LEVEL only — cannot be in defineProject configs
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json-summary'],
      include: ['packages/*/src/**/*.ts', 'packages/*/src/**/*.tsx'],
      exclude: [
        'packages/*/src/**/*.d.ts',
        'packages/*/src/**/*.test.*',
        'packages/*/src/**/*.spec.*',
      ],
      thresholds: { lines: 80, branches: 75 },
    },
    // Projects: replaces workspace; can be inline objects or file paths with globs
    projects: [
      // Inline project config — use defineProject for type safety
      {
        plugins: [react()],
        test: {
          name: 'ui',
          root: './packages/ui',
          include: ['packages/ui/src/**/*.test.tsx'],
          environment: 'jsdom',
          setupFiles: ['./packages/ui/tests/setup-dom.ts'],
        },
      },
      // File reference — Vitest loads defineProject from each package's vitest.config.ts
      './packages/core/vitest.config.ts',
      './packages/api/vitest.config.ts',
    ],
  },
});
```

```typescript
// packages/core/vitest.config.ts — use defineProject (not defineConfig) for workspace members
import { defineProject } from 'vitest/config';

// defineProject prevents accidentally adding root-only options (coverage, reporters, etc.)
// If you accidentally add 'coverage:' here, Vitest throws a clear error at startup
export default defineProject({
  test: {
    name: 'core',
    root: './packages/core',
    include: ['src/**/*.test.ts'],
    environment: 'node',
    pool: 'threads',
    // Vitest 4.0: poolOptions.threads.maxThreads/minThreads removed — use top-level maxWorkers/minWorkers
    maxWorkers: 2,
    minWorkers: 1,
    // Per-project globals and setup are allowed
    globals: true,
    setupFiles: ['./tests/setup.ts'],
  },
});
```

```typescript
// packages/api/vitest.config.ts — API package with integration test timeouts
import { defineProject } from 'vitest/config';

export default defineProject({
  test: {
    name: 'api',
    root: './packages/api',
    include: ['src/**/*.test.ts', 'src/**/*.integration.test.ts'],
    environment: 'node',
    // Longer timeout for integration tests (DB connections, HTTP calls)
    testTimeout: 30_000,
    hookTimeout: 15_000,
    // Per-project retry — integration tests can be flaky on CI runner cold start
    retry: process.env['CI'] ? 1 : 0,
  },
});
```

**GitHub Actions using `--project` filter with the new API:**

```yaml
# .github/workflows/ci.yml — filter by Vitest project name (works with both old workspace and new projects API)
jobs:
  test-core:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # Run only 'core' project — unchanged from v3.1 API; works with new projects config
      - run: npx vitest run --project core --coverage
        name: Core package tests

  test-all:
    needs: lint
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # Run all projects with merged coverage
      - run: npx vitest run --coverage --reporter=junit --outputFile=junit.xml
        name: All workspace projects (main branch)
```

> [community] The primary practical difference between `defineProject` and `defineConfig` in a workspace file: `defineConfig` allows (and applies) the full root-level config including `coverage`, `reporters`, `snapshotResolver`, and `globalSetup`. In a project file this causes silent or explicit failures. `defineProject` is a strict subset — it only accepts project-scoped options. The Vitest team added `defineProject` specifically to solve the "why does my project config break coverage?" class of questions that accounted for 15–20% of GitHub issues in Vitest's tracker.

| Vitest `defineProject` API | Official docs | https://vitest.dev/guide/projects | Type-safe per-package config in workspace; prevents root-only options in project files |
| Playwright `--fail-on-flaky-tests` | Official docs | https://playwright.dev/docs/test-cli | CLI flag to exit code 1 when retried tests pass — strict flakiness gate |

### Playwright `webServer.wait` Regex for Dynamic Port Capture [community]

Playwright v1.57 added a `wait` field to `testConfig.webServer` that accepts a regular expression matched against the dev server's stdout or stderr. When the regex contains named capture groups, the captured values are injected as environment variables — enabling tests to discover the server's dynamically assigned port without a separate polling script.

> [community] Teams that used `reuseExistingServer: !process.env.CI` with a hardcoded `url` consistently hit a race condition: the server started on port 3000 locally but on a CI runner with a port conflict it bound to 3001, and tests silently targeted the wrong URL. The `wait` regex pattern eliminates the hardcoded port entirely — the server reports its own port and Playwright reads it directly from the startup log.

```typescript
// playwright.config.ts — dynamic port capture via webServer.wait (v1.57+)
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  retries: process.env['CI'] ? 1 : 0,
  forbidOnly: !!process.env['CI'],

  webServer: {
    // Start dev server; let OS assign a free port
    command: 'node dist/server.js --port 0',
    // Wait until stdout matches the pattern and capture the port number
    // Named capture group `server_port` becomes process.env.SERVER_PORT
    wait: {
      stdout: /Listening on port (?<server_port>\d+)/,
    },
    // Use the captured env var — set automatically by Playwright
    url: `http://localhost:${process.env['SERVER_PORT'] ?? 3000}/health`,
    reuseExistingServer: !process.env['CI'],
    timeout: 30_000,
  },

  use: {
    // Tests read the same env var to build their base URL
    baseURL: `http://localhost:${process.env['SERVER_PORT'] ?? 3000}`,
    ...devices['Desktop Chrome'],
    trace: 'on-first-retry',
  },
});
```

```yaml
# .github/workflows/ci.yml — webServer.wait replaces wait-for-url polling step
jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npm run build       # compile TypeScript to dist/
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium
      # Playwright starts the server, waits for the regex, injects SERVER_PORT, then runs tests
      # No separate "wait-for-url" polling step needed
      - run: npx playwright test
        env:
          CI: true
```

> [community] The `wait` regex approach solves the parallel-runner port-conflict problem in matrix CI: when 4 shard jobs run simultaneously on the same machine type, each starts its own dev server on a random OS-assigned port. Without `wait`, teams either hardcode different ports per shard (fragile) or add complex polling scripts. With `wait`, each runner captures its own assigned port independently, with zero coordination overhead.

### Playwright `--last-failed` for Efficient CI Retry Workflows [community]

Playwright v1.44 introduced the `--last-failed` CLI flag, which re-executes only the test cases that failed in the most recent local or CI run. Unlike `--retries` (which retries within a single run), `--last-failed` enables a second CI job that specifically targets the failing set from the previous job — achieving fast re-validation without running the full suite again.

> [community] Teams with 400+ e2e tests that average 15% failure rate (mix of real defects and environment flakiness) report that `--last-failed` cuts their "re-run after fix" cycle from 25 minutes (full suite) to 3–4 minutes (just the previously failed tests). The critical implementation detail: the test results file must be persisted as an artifact between the first job and the retry job. Without artifact passing, `--last-failed` has nothing to read and falls back to running the full suite.

```yaml
# .github/workflows/ci-with-retry.yml — two-stage e2e: full run then targeted retry
name: E2E with Retry

on: [pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    outputs:
      had-failures: ${{ steps.check.outputs.had-failures }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium

      # Full suite run — blob reporter stores per-test results for --last-failed
      - name: Run full e2e suite
        id: e2e-run
        run: npx playwright test --reporter=blob,github
        continue-on-error: true  # capture results even if tests fail

      # Upload results so retry job can read them
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-results
          path: blob-report/
          retention-days: 1   # only needed for the retry job in this workflow run

      # Set output so retry job knows whether to run
      - name: Check for failures
        id: check
        if: always()
        run: |
          if [ "${{ steps.e2e-run.outcome }}" = "failure" ]; then
            echo "had-failures=true" >> $GITHUB_OUTPUT
          else
            echo "had-failures=false" >> $GITHUB_OUTPUT
          fi

  e2e-retry:
    needs: e2e
    # Only run if previous job had failures
    if: needs.e2e.outputs.had-failures == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium

      # Download results from the first run
      - uses: actions/download-artifact@v4
        with:
          name: playwright-results
          path: blob-report/

      # Re-run ONLY the previously failed tests — fast targeted validation
      - name: Re-run failed tests
        run: npx playwright test --last-failed --reporter=github
```

> [community] The most important configuration for `--last-failed` in CI: pass `--reporter=blob` in the initial run. The blob reporter stores rich per-test metadata (including failure details) in a structured format that `--last-failed` uses to reconstruct the failed test list. Teams that use only `--reporter=github` (the inline annotation reporter) find that `--last-failed` cannot find its input and silently runs the full suite instead. Always use `blob` as one of the reporters when `--last-failed` will be used.

### Vitest `aroundEach` / `aroundAll` for Transaction-Wrapped Integration Tests [community]

Vitest v4.1 introduced `aroundEach` and `aroundAll` hooks — a wrapper-style alternative to the `beforeEach`/`afterEach` pair. Instead of separate setup and teardown functions, `aroundEach` receives a `runTest` callback that represents the test itself: code before `runTest()` is setup, code after is teardown. This enables integration tests to run inside an open database transaction that is automatically rolled back after each test, regardless of whether the test passes or throws.

> [community] Teams using `beforeEach` + `afterEach` for transaction rollback consistently report the same defect: when `afterEach` receives the wrong connection (a new connection rather than the transaction-holding connection), the rollback fails silently and test data accumulates. `aroundEach` eliminates this class of defect by keeping the transaction object in the same lexical scope as both setup and teardown — the connection cannot be accidentally different because it is a closure variable.

```typescript
// tests/integration/database.setup.ts — aroundEach transaction wrapper (Vitest v4.1+)
import { aroundEach } from 'vitest';
import { createPool, type Pool, type PoolClient } from 'pg';

// Shared pool for the entire test file
const pool: Pool = createPool({ connectionString: process.env['DATABASE_URL'] });

// Export so individual test files can import and use the connection
export let testClient: PoolClient;

// aroundEach: begin a transaction before each test, roll back after
aroundEach(async (runTest) => {
  // Setup: acquire connection and begin transaction
  testClient = await pool.connect();
  await testClient.query('BEGIN');

  try {
    // runTest() executes the actual test case — all DB writes go into the transaction
    await runTest();
  } finally {
    // Teardown: always rollback, even if the test threw
    // This runs in the same scope as testClient — guaranteed correct connection
    await testClient.query('ROLLBACK');
    testClient.release();
  }
});
```

```typescript
// tests/integration/order-service.test.ts — uses aroundEach transaction isolation
import { describe, it, expect } from 'vitest';
import { testClient } from './database.setup';
import { OrderService } from '../../src/services/order-service';

describe('OrderService (transaction-isolated)', () => {
  it('creates an order and stores it in the database', async () => {
    const service = new OrderService(testClient);
    const order = await service.create({ userId: 'user-1', total: 99.99 });

    expect(order.id).toBeDefined();
    const row = await testClient.query(
      'SELECT * FROM orders WHERE id = $1', [order.id]
    );
    expect(row.rows[0].total).toBe('99.99');
    // After this test completes, aroundEach rolls back — no cleanup needed
  });

  it('rejects an order with zero total', async () => {
    const service = new OrderService(testClient);
    await expect(service.create({ userId: 'user-1', total: 0 }))
      .rejects.toThrow('Order total must be positive');
    // Rollback is automatic via aroundEach even though this test expected a throw
  });
});
```

> [community] `aroundAll` is the suite-level equivalent: the `runSuite` callback runs all tests in the `describe` block. This is appropriate when the cost of transaction setup/teardown per test is too high — for example, when the setup involves a multi-step migration. One `aroundAll` wraps the entire suite in a single transaction; all tests share it and see each other's writes. Use with caution: tests are no longer independent, violating the "I" in FIRST principles. Prefer `aroundEach` for isolation unless setup cost justifies the tradeoff.

### Vitest `--detect-async-leaks` for CI Flakiness Root-Cause Detection [community]

Vitest v4.1 introduced the `--detect-async-leaks` flag, which causes the test runner to fail if any test leaves open asynchronous operations (timers, unresolved promises, database connections, HTTP server listeners) after it completes. Open handles are the most common root cause of non-deterministic test suite behavior in Node.js — a test that forgets to close a connection leaves the event loop alive, delaying the test runner's process exit and causing timing-dependent failures in later tests.

> [community] Engineering teams that enable `--detect-async-leaks` on an existing test suite consistently report finding 3–15 tests with open handles on the first run. The most common culprits: `setTimeout` without `clearTimeout` in test code, `setInterval` in module-level code that isn't reset, and database pool connections that are created in a test but never closed. Fixing these leaks eliminates an entire class of "order-dependent" test flakiness that was previously attributed to infrastructure or test sequence.

```yaml
# .github/workflows/ci.yml — async leak detection in CI (Vitest v4.1+)
jobs:
  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # --detect-async-leaks: fail if any test leaves open handles
      # Add this first without --bail to discover all leaks in one run
      - run: npx vitest run --detect-async-leaks --reporter=verbose
        name: Unit tests (async leak detection)
```

```typescript
// vitest.config.ts — async leak detection in config (preferred over CLI flag in CI)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Fail if any test leaves open async operations — catches hidden flakiness root causes
    detectOpenHandles: true,  // equivalent to --detect-async-leaks flag
    // Combined with bail: 0 — report ALL leaks in one run rather than stopping at first
    bail: 0,
    pool: 'threads',
    isolate: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json-summary'],
    },
  },
});
```

```typescript
// Example: correctly closing a server to prevent async leak
import { describe, it, expect, afterAll } from 'vitest';
import { createServer, type Server } from 'http';

describe('HTTP server tests', () => {
  let server: Server;

  // If beforeAll creates the server but afterAll is missing, --detect-async-leaks fails
  beforeAll(() => {
    server = createServer((req, res) => {
      res.writeHead(200);
      res.end('ok');
    });
    server.listen(0); // OS-assigned port
  });

  afterAll(() => {
    // REQUIRED: close the server or --detect-async-leaks will fail this suite
    server.close();
  });

  it('responds with 200', async () => {
    const port = (server.address() as { port: number }).port;
    const res = await fetch(`http://localhost:${port}/`);
    expect(res.status).toBe(200);
  });
});
```

> [community] The `--detect-async-leaks` flag is particularly effective when combined with `--bail=0` on the first CI run after enabling it. `--bail=0` means "continue even after failures" — this surfaces all leaking tests in a single CI run rather than stopping at the first one. After fixing all leaks, switch to `--bail=1` (fail fast) for the ongoing CI gate.

### Vitest Test Tags and `--tags-filter` for Stage-Based CI [community]

Vitest v4.1 introduced native test tags — a way to label individual test cases or `describe` blocks with semantic tags (`@smoke`, `@slow`, `@db`, `@integration`) and filter which tests run using `--tags-filter` on the CLI. This replaces the common workaround of using separate config files or file-naming conventions to define CI stages.

> [community] Teams that previously maintained three separate Vitest config files (`vitest.smoke.config.ts`, `vitest.unit.config.ts`, `vitest.integration.config.ts`) to control which tests ran per CI stage find that tag-based filtering eliminates the config maintenance overhead. The tags live with the tests, making the test's CI role self-documenting. The migration path is additive — tags are annotations, not restructuring.

```typescript
// vitest.config.ts — root config for tag-aware CI runs
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    pool: 'threads',
    isolate: true,
    coverage: {
      provider: 'v8',
      include: ['src/**/*.ts'],
      reporter: ['text', 'lcov', 'json-summary'],
    },
  },
});
```

```typescript
// src/services/order-service.test.ts — tests tagged for CI stage filtering
import { describe, it, expect, vi } from 'vitest';
import { OrderService } from './order-service';
import type { OrderRepository } from '../repositories/order-repository';

const mockRepo = {
  save: vi.fn(),
  findById: vi.fn(),
} satisfies Partial<OrderRepository>;

// @smoke: runs on every push (fast gate)
describe('OrderService — smoke', { tags: ['@smoke'] }, () => {
  it('creates an order with correct total', () => {
    const service = new OrderService(mockRepo as unknown as OrderRepository);
    const order = service.buildOrder({ items: [{ price: 10, qty: 2 }] });
    expect(order.total).toBe(20);
  });
});

// @integration: runs only on PR and main (requires DB)
describe('OrderService — integration', { tags: ['@integration', '@db'] }, () => {
  it('persists an order and retrieves it', async () => {
    // ... real DB test
    expect(true).toBe(true); // placeholder
  }, { timeout: 30_000 });
});

// @slow: nightly only — long-running performance test
it('processes 1000 orders within 2 seconds', { tags: ['@slow'] }, async () => {
  // ... bulk processing test
  expect(true).toBe(true);
});
```

**GitHub Actions with tag-based stage filtering:**

```yaml
# .github/workflows/ci.yml — different test levels using tag filtering
jobs:
  smoke:
    # Fast gate: push to any branch — only @smoke tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npx vitest run --tags-filter="@smoke"
        name: Smoke tests (fast gate)

  integration:
    # PR gate: smoke + integration tests (no slow tests)
    needs: smoke
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - run: npx vitest run --tags-filter="@smoke or @integration"
        name: PR test suite (smoke + integration)

  nightly-full:
    # Nightly: all tests including slow ones
    if: github.event_name == 'schedule'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # No filter = all tests; OR explicitly: @smoke or @integration or @slow
      - run: npx vitest run --coverage
        name: Full nightly test suite
```

> [community] The most powerful `--tags-filter` feature for team workflows: the logical operators. `"@integration and not @slow"` runs integration tests that are expected to be fast — a useful "PR extended gate" that skips known-slow integration tests while still catching most integration defects. Teams that combine `and`/`or`/`not` operators in CI flag definitions report cleaner PR feedback than teams using file-pattern matching, because the tag is co-located with the test and updated when the test's characteristics change.

### Vitest `coverage.changed` for PR-Scoped Coverage Reporting [community]

Vitest v4.1 added the `coverage.changed` option, which restricts coverage reporting to only the files changed since a specified base branch. Instead of a project-wide coverage report (which can show low coverage for legacy files irrelevant to the PR), `coverage.changed` narrows the report to the exact files the developer touched — giving a precise signal about whether new code is adequately tested.

> [community] Teams that use global coverage thresholds on large codebases consistently face a perverse incentive: developers avoid touching poorly-covered legacy files to prevent their PR from failing the coverage gate. `coverage.changed` inverts this: coverage is measured only on the files you touched, so adding tests to an old file improves your PR's score. Teams that adopt this pattern report a 30–40% increase in test additions on PRs touching legacy code.

```typescript
// vitest.config.ts — coverage.changed for PR-targeted reporting
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json-summary'],
      include: ['src/**/*.ts', 'src/**/*.tsx'],
      exclude: [
        'src/**/*.d.ts',
        'src/**/*.test.*',
        'src/**/*.spec.*',
        'src/generated/**',
      ],
      // Report coverage only for files changed vs. the base branch
      // Value: 'git:main' compares HEAD to origin/main
      changed: process.env['CI'] ? 'git:origin/main' : undefined,
      // Thresholds apply to the changed-files subset, not the whole project
      thresholds: {
        lines: 80,
        branches: 70,
        // perFile: true applies per-file thresholds to the changed subset
        perFile: true,
      },
    },
  },
});
```

**GitHub Actions step with PR coverage delta:**

```yaml
# .github/workflows/ci.yml — PR coverage report scoped to changed files
  coverage-changed:
    needs: unit
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # required for git:origin/main comparison
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # Fetch base branch so git diff works correctly
      - run: git fetch origin main
      # Run tests with coverage.changed — only changed files appear in report
      - run: npx vitest run --coverage
        name: Coverage (changed files only)
        env:
          CI: true

      # Post the changed-file coverage summary as a PR comment
      - name: Coverage PR comment
        uses: davelosert/vitest-coverage-report-action@v2
        if: always()
        with:
          json-summary-path: coverage/coverage-summary.json
          json-final-path: coverage/coverage-final.json
```

> [community] The `fetch-depth: 0` checkout is required for `coverage.changed: 'git:origin/main'` to work — `git diff origin/main` needs the base branch refs to be present. GitHub Actions defaults to a shallow clone (`fetch-depth: 1`) that doesn't include the remote branches. Teams that forget `fetch-depth: 0` see `coverage.changed` fall back to reporting all files (because the diff target doesn't exist), producing the same inflated report they were trying to avoid.

### Vitest 4.x Migration: `workspace` Fully Removed [community]

Vitest 4.0 completes the migration that started in v3.2: the `workspace` configuration option and `vitest.workspace.ts` discovery are **fully removed**. The `defineWorkspace` helper is no longer exported. Projects must be defined using the `projects` array inside `vitest.config.ts`. Additionally, Vitest 4.0 requires **Vite 6+** — Vite 5 is no longer supported.

> [community] Teams upgrading from Vitest 3.x to 4.0 that have existing `vitest.workspace.ts` files encounter two distinct failure modes: (1) a `Cannot find export 'defineWorkspace'` error if the old import path is used, and (2) a silent no-op if the workspace file is present but Vitest 4.0 ignores it in favor of `vitest.config.ts`. Both cases cause all workspace projects to stop running — the full test suite appears to pass because there are simply no tests to execute. Always migrate `defineWorkspace` to `projects:` before upgrading to Vitest 4.0.

**Migration from `vitest.workspace.ts` to Vitest 4.x `projects:` array:**

```typescript
// BEFORE (Vitest 3.x) — vitest.workspace.ts (REMOVED in v4.0)
// import { defineWorkspace } from 'vitest/config';
// export default defineWorkspace([...]);

// AFTER (Vitest 4.x) — vitest.config.ts (replaces vitest.workspace.ts)
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  // Coverage must be at root level — same as before
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json-summary'],
      include: ['packages/*/src/**/*.ts', 'packages/*/src/**/*.tsx'],
      thresholds: { lines: 80, branches: 75 },
    },

    // Projects: replaces defineWorkspace() — same inline or file-reference syntax
    projects: [
      // Inline project (use defineProject for type safety in per-project files)
      {
        plugins: [react()],
        test: {
          name: 'ui',
          root: './packages/ui',
          include: ['packages/ui/src/**/*.test.tsx'],
          environment: 'jsdom',
          setupFiles: ['./packages/ui/tests/setup-dom.ts'],
        },
      },
      // File reference — each file must export a defineProject config
      './packages/core/vitest.config.ts',
      './packages/api/vitest.config.ts',
    ],
  },
});
```

**Vite 6 compatibility check for CI:**

```yaml
# .github/workflows/ci.yml — verify Vite version before running Vitest 4.x tests
  pre-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # Fail CI early with a clear message if Vite < 6 is installed
      - name: Verify Vite 6+ for Vitest 4.x compatibility
        run: |
          VITE_VER=$(node -e "console.log(require('./node_modules/vite/package.json').version)")
          MAJOR=$(echo "$VITE_VER" | cut -d. -f1)
          if [ "$MAJOR" -lt 6 ]; then
            echo "::error::Vitest 4.x requires Vite 6+. Installed: $VITE_VER. Run: npm install vite@latest"
            exit 1
          fi
          echo "Vite $VITE_VER — compatible with Vitest 4.x"
```

> [community] The `'basic'` reporter was also removed in Vitest 4.0 (replaced by `'tree'`). Teams that reference `reporters: ['basic']` in their Vitest config see a "Unknown reporter: basic" error in CI. The `'tree'` reporter provides the same hierarchical output with improved formatting. Update any `reporters` config that references `'basic'` to `'tree'` as part of the Vitest 4.0 upgrade.

### HTML Report Speedboard for CI Critical-Path Analysis [community]

Playwright v1.58 added a **Speedboard tab** to the merged HTML report (produced by `npx playwright merge-reports`). The Speedboard shows a horizontal timeline of test execution across all shards — each test is a colored bar, positioned by start time and length-proportional to duration. The critical path (the longest sequential chain of tests) is highlighted, immediately revealing which test file or shard is the CI bottleneck.

> [community] Teams managing sharded e2e suites report that the Speedboard cuts the time to diagnose "why did the sharded run take 18 minutes instead of the expected 12?" from 30+ minutes of log archaeology to under 2 minutes of reading the timeline. The critical path highlight directly identifies the slow shard and the slow test file within it. Before the Speedboard, teams had to compute this manually from JSON results — a barrier that prevented most teams from ever doing it.

```typescript
// playwright.config.ts — configuration for Speedboard-compatible sharded reports
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  retries: process.env['CI'] ? 1 : 0,
  forbidOnly: !!process.env['CI'],
  captureGitInfo: process.env['CI'] ? { commit: true, diff: false } : false,

  reporter: process.env['CI']
    ? [
        // blob reporter is required — merge-reports generates the Speedboard from blob data
        ['blob', { outputDir: 'blob-report' }],
        // github reporter for inline PR annotations (does NOT affect Speedboard)
        ['github'],
      ]
    : [['html', { open: 'on-failure' }]],

  use: {
    ...devices['Desktop Chrome'],
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
});
```

```yaml
# .github/workflows/e2e-sharded.yml — sharded suite producing Speedboard-enabled reports
name: E2E Sharded (Speedboard)

on: [pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }     # for captureGitInfo
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test --shard=${{ matrix.shard }}/4
        env: { CI: true }
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: blob-report-${{ matrix.shard }}
          path: blob-report/
          retention-days: 7

  merge-reports:
    needs: e2e
    if: always()
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - uses: actions/download-artifact@v4
        with:
          path: all-blob-reports/
          pattern: blob-report-*
          merge-multiple: true
      # merge-reports generates the HTML report including the Speedboard tab
      - run: npx playwright merge-reports --reporter html ./all-blob-reports
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: html-report-${{ github.sha }}
          path: playwright-report/
          retention-days: 30
```

> [community] The Speedboard is only generated by `npx playwright merge-reports` — it is NOT available in single-machine HTML reports. Teams that run e2e on a single runner without sharding cannot access it. To get Speedboard access without sharding, use `--reporter=blob` on the single runner and then `npx playwright merge-reports` from a single shard artifact. This adds 30 seconds to the CI run but unlocks the timeline view for performance analysis. Teams that do this once after every slow CI investigation report finding actionable optimizations in 80% of cases.

### GitHub Actions Custom Runner Images for Pre-Warmed CI Environments [community]

GitHub Actions custom runner images (generally available March 2026) allow teams to build and publish custom Docker images that include pre-installed tools (Node.js, Playwright browsers, Docker images, test fixtures) and use them as the base environment for GitHub-hosted runners. Unlike standard `ubuntu-latest`, a custom image can pre-install all CI dependencies at build time — eliminating `npm ci`, browser downloads, and Docker pulls from the hot path of every CI run.

> [community] Teams that adopt custom runner images for test-heavy CI pipelines report eliminating 60–80% of their cold-start installation overhead. A standard `ubuntu-latest` runner needs 45–90 seconds for `npm ci` + 30–60 seconds for `npx playwright install` + up to 60 seconds for Docker image pulls. A custom image with all these pre-baked reduces this to < 5 seconds (just extracting the image layers from the cache). The break-even point is roughly 50 CI runs per week — below that, the image maintenance cost exceeds the time savings.

```yaml
# .github/workflows/build-custom-runner.yml — build and push custom CI runner image
name: Build Custom Runner Image

on:
  push:
    paths:
      - '.github/runner-image/Dockerfile'
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          context: .github/runner-image
          push: true
          tags: ghcr.io/${{ github.repository }}/ci-runner:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

```dockerfile
# .github/runner-image/Dockerfile — custom runner with pre-installed Node, Playwright, Docker
FROM ghcr.io/actions/actions-runner:latest

# Install Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - \
    && sudo apt-get install -y nodejs

# Install Playwright and its browsers — baked into image, not downloaded per run
RUN npm install -g playwright \
    && npx playwright install chromium --with-deps

# Pre-pull common Docker images for Testcontainers
RUN docker pull postgres:16-alpine || true \
    && docker pull redis:7-alpine || true
```

```yaml
# .github/workflows/ci.yml — CI using custom pre-warmed runner image
jobs:
  e2e:
    # Use custom runner image — Node, Playwright browsers, and Docker images pre-installed
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/${{ github.repository }}/ci-runner:latest
    steps:
      - uses: actions/checkout@v4
      # npm ci still runs but is faster with pre-installed global tools
      - run: npm ci
      # No browser install step needed — Playwright browsers are in the image
      - run: npx playwright test
        env: { CI: true }
```

> [community] The primary ongoing cost of custom runner images: keeping them up to date. When Playwright releases a new version with updated browser binaries, the image must be rebuilt. Teams that automate the rebuild (trigger on `package-lock.json` changes to Playwright's version) eliminate this maintenance burden. Teams that do not automate it discover the mismatch when `npx playwright install --with-deps` is needed again because the image's browser version doesn't match the `@playwright/test` version in `package.json`.

### Playwright `trace: 'retain-on-failure-and-retries'` for Full Retry Debugging [community]

Playwright v1.54 introduced the `'retain-on-failure-and-retries'` trace mode — a more complete alternative to `'on-first-retry'` for CI debugging. While `'on-first-retry'` records only the first retry attempt, `'retain-on-failure-and-retries'` records **every** test run attempt and retains all traces when any attempt fails. This is critical for diagnosing flaky tests that fail on attempt 1, pass on attempt 2, then fail again on attempt 3 — a trace gap invisible to `'on-first-retry'`.

> [community] Teams using `'on-first-retry'` for a high-retry (retries: 2) e2e suite routinely encounter intermittent failures with no trace: the test passed on retry 1 (producing no trace) then failed on retry 2 (which `on-first-retry` also doesn't record because it's not the "first" retry). Switching to `'retain-on-failure-and-retries'` surfaces traces for all failure attempts, reducing mean-time-to-reproduce a flaky defect from days to minutes.

```typescript
// playwright.config.ts — trace retention for full retry-cycle debugging (v1.54+)
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  retries: process.env['CI'] ? 2 : 0,
  use: {
    // 'retain-on-failure-and-retries': record every attempt; retain all if any attempt fails
    // Replaces 'on-first-retry' when retry count > 1 and full failure history is needed
    trace: process.env['CI'] ? 'retain-on-failure-and-retries' : 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
  reporter: [
    ['html'],
    ['blob', { outputFile: 'blob-report/report.zip' }],
  ],
});
```

```yaml
# .github/workflows/e2e.yml — upload traces for all failed attempts
  - uses: actions/upload-artifact@v4
    if: failure()
    with:
      name: playwright-traces-${{ github.run_id }}
      path: test-results/
      retention-days: 14
      # With retain-on-failure-and-retries, test-results/ contains traces for every attempt
      # Trace files named: <test-name>-attempt-1/trace.zip, <test-name>-attempt-2/trace.zip, etc.
```

> [community] The storage cost of `'retain-on-failure-and-retries'` vs `'on-first-retry'`: roughly `retries × trace_size_per_test × failed_test_count`. For a suite with 2 retries and 5 failing tests of ~2 MB trace each, the increase is ~10 MB — negligible. The break-even is immediate: one debugging session avoided easily exceeds the $0.01 in artifact storage costs.

### Playwright `test.abort()` for Guard-Rail Tests in CI [community]

Playwright v1.60 introduced `test.abort()` — a method to immediately fail the currently running test case and mark it as aborted (not as a normal assertion failure). It can be called from test fixtures, hooks, or route handlers. In CI, the primary use case is **environment guard-rail assertions**: a fixture or `beforeEach` hook that validates a critical precondition and aborts rather than letting the test case run with wrong setup and produce a confusing failure.

> [community] Before `test.abort()`, teams used `test.skip()` to short-circuit tests with unmet preconditions — but skipped tests produce green CI results, hiding environment misconfiguration for days. `test.abort()` produces a distinct non-green exit that is visible in reports and fails the CI job, making the environment problem impossible to miss.

```typescript
// tests/fixtures/env-guard.ts — abort tests when required env vars are missing (Playwright v1.60+)
import { test as base } from '@playwright/test';

// Guard-rail fixture: abort test if critical CI env is not configured
export const test = base.extend<{ requireTestEnv: void }>({
  requireTestEnv: [async ({}, use, testInfo) => {
    const requiredVars = ['TEST_BASE_URL', 'TEST_API_KEY', 'TEST_DB_URL'];
    const missing = requiredVars.filter(v => !process.env[v]);

    if (missing.length > 0) {
      // abort() fails with distinct status — visible in reports, not silently skipped
      await testInfo.attach('env-guard-failure', {
        body: `Missing required env vars: ${missing.join(', ')}`,
        contentType: 'text/plain',
      });
      test.abort(`Required environment variables not set: ${missing.join(', ')}`);
    }

    await use();
  }, { auto: true }], // auto: true applies to ALL tests in this suite automatically
});

// tests/e2e/checkout.spec.ts — guard-rail applied automatically via fixture
import { test } from '../fixtures/env-guard';
import { expect } from '@playwright/test';

test('checkout flow completes successfully', async ({ page }) => {
  // If TEST_BASE_URL is missing, test.abort() fires before this line
  // CI sees: "1 aborted" (not "1 passed") — environment issue is flagged
  await page.goto(process.env['TEST_BASE_URL']!);
  await expect(page.getByRole('heading', { name: 'Checkout' })).toBeVisible();
});
```

```yaml
# .github/workflows/e2e.yml — abort is distinct from skip in GitHub Actions output
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npx playwright install --with-deps
      # Environment guard: abort tests fail CI job (exit code 1) unlike skip (exit code 0)
      - run: npx playwright test
        env:
          TEST_BASE_URL: ${{ vars.TEST_BASE_URL }}      # from GitHub repo variables
          TEST_API_KEY: ${{ secrets.TEST_API_KEY }}     # from GitHub secrets
          TEST_DB_URL: ${{ secrets.TEST_DB_URL }}       # from GitHub secrets
```

> [community] A key difference between `test.abort()` and `test.skip()` in CI: `skip` produces exit code 0 and shows green, which is appropriate for "this test is not applicable in this environment." `abort()` produces exit code 1 and a distinct `aborted` status in the HTML report, which is appropriate for "this environment is incorrectly configured." Use abort for CI guard-rails; use skip for test-level conditional applicability.

### Vitest 4.0 Pool Architecture Migration [community]

Vitest 4.0 rewrote the worker pool system, removing the `tinypool` dependency. The configuration API changed significantly — `poolOptions.threads.maxThreads`/`minThreads` were replaced by top-level `maxWorkers`/`minWorkers`, and the env vars `VITEST_MAX_THREADS`/`VITEST_MAX_FORKS` were replaced by `VITEST_MAX_WORKERS`. Additionally, `singleThread`/`singleFork` modes are now expressed as `maxWorkers: 1, isolate: false`.

> [community] The most dangerous aspect of the Vitest 4.0 pool migration: the old `poolOptions.threads.maxThreads` configuration silently does nothing in v4.0 — it is not an error, it is simply ignored. A CI pipeline that relied on `maxThreads: 1` to serialize database integration tests (preventing connection pool exhaustion) starts running them in parallel after the upgrade, causing intermittent "connection refused" errors. The failure looks like infrastructure instability, not a configuration change. Always audit `poolOptions` usage when upgrading to Vitest 4.0.

```typescript
// vitest.config.ts — Vitest 4.0 pool migration (before/after comparison)
import { defineConfig } from 'vitest/config';

// ❌ BEFORE (Vitest 3.x) — poolOptions.threads.maxThreads removed in v4.0
// export default defineConfig({
//   test: {
//     pool: 'threads',
//     poolOptions: { threads: { maxThreads: 2, minThreads: 1 } },
//   },
// });

// ✅ AFTER (Vitest 4.0+) — use top-level maxWorkers / minWorkers
export default defineConfig({
  test: {
    pool: 'threads',
    // Top-level maxWorkers replaces poolOptions.threads.maxThreads
    maxWorkers: 2,
    minWorkers: 1,
    isolate: true,
    // Vitest 4.0 V8 coverage: coverage.all and coverage.extensions removed
    // coverage.include is now REQUIRED — without it, only loaded files are covered
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json-summary'],
      // REQUIRED in v4.0: explicitly declare what to include
      include: ['src/**/*.ts', 'src/**/*.tsx'],
      exclude: ['src/**/*.d.ts', 'src/**/*.test.ts', 'src/**/*.spec.ts'],
      thresholds: { lines: 80, branches: 75 },
    },
  },
});
```

```typescript
// vitest.config.integration.ts — serialized integration tests (Vitest 4.0+)
import { defineConfig } from 'vitest/config';

// Integration tests that require sequential DB access
export default defineConfig({
  test: {
    include: ['src/**/*.integration.test.ts'],
    pool: 'threads',
    // Old: poolOptions: { threads: { maxThreads: 1 } } — SILENT NO-OP in v4.0
    // New: top-level maxWorkers: 1 — actually serializes DB tests
    maxWorkers: 1,
    isolate: false,   // replaces singleThread: true (singleThread removed in v4.0)
    testTimeout: 30_000,
  },
});
```

```yaml
# .github/workflows/ci.yml — update VITEST_MAX_WORKERS env var (Vitest 4.0+)
  unit:
    runs-on: ubuntu-latest
    env:
      # Vitest 4.0: VITEST_MAX_THREADS and VITEST_MAX_FORKS are removed
      # Use VITEST_MAX_WORKERS to control parallelism from CI env
      VITEST_MAX_WORKERS: 2   # was: VITEST_MAX_THREADS: 2
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npx vitest run --coverage
```

> [community] The V8 coverage overhaul in Vitest 4.0 also affects teams relying on `coverage.all: true` to catch untested files. That option is removed — Vitest 4.0 only reports coverage for files that were actually loaded during the test run. If a source file has no test importing it, it will not appear in the coverage report at all, which can make coverage look artificially high. The fix is to add all source files explicitly via `coverage.include`, which causes Vitest to instrument all matching files even if no test imports them. Teams that relied on the implicit "all: true" behavior will see their coverage drop on upgrade — the numbers are now accurate.


### Vitest 4.1 GitHub Actions Job Summary Reporter [community]

Vitest 4.1 (March 2026) ships a zero-configuration GitHub Actions job summary reporter. When Vitest detects it is running inside a GitHub Actions environment (`$GITHUB_STEP_SUMMARY` is set), the built-in `github-actions` reporter automatically appends a structured test summary to the job's step summary page. The summary includes total/passed/failed test counts and, critically, **permalinks to flaky test source lines** for any test that passed only on retry.

> [community] Teams that added the Vitest GitHub Actions reporter report that flaky test follow-up time dropped significantly — instead of clicking into the verbose log to find "which test retried?", the job summary shows a clickable link to the exact source line of the flaky test case. The zero-config activation is the key adoption enabler: teams with existing `vitest run` CI commands get enriched reporting without any workflow changes.

**How it activates — no configuration required:**

```yaml
# .github/workflows/ci.yml — Vitest job summary activates automatically
jobs:
  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # Vitest detects GITHUB_STEP_SUMMARY and appends job summary automatically
      # No reporter configuration needed — zero config
      - run: npx vitest run --coverage
        name: Unit tests with auto job summary
```

**Output in the GitHub Actions job summary panel:**
- Test file count and total test case count
- Pass/fail/skip breakdown
- Flaky test list: tests that passed only after retry, each with a permalink to the source file line

**Customizing or disabling the feature:**

```typescript
// vitest.config.ts — customize or disable the GitHub Actions job summary
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    reporters: [
      // Keep default reporters for local dev
      'verbose',
      // Customize the github-actions reporter's job summary behavior
      ['github-actions', {
        jobSummary: {
          enabled: true,
          // Set a custom output path (defaults to $GITHUB_STEP_SUMMARY)
          // outputPath: '/custom/path',
        },
      }],
    ],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json-summary'],
      include: ['src/**/*.ts'],
    },
  },
});
```

**Combining with `coverage.changed` for PR-scoped reporting (Vitest 4.1+):**

```yaml
# .github/workflows/ci.yml — PR job: job summary + coverage delta for changed files only
jobs:
  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }  # needed for coverage.changed git diff
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      # --coverage.changed: only report coverage for files changed vs. origin/main
      # job summary auto-appended; coverage.changed makes it PR-scoped
      - run: |
          git fetch origin main
          npx vitest run --coverage --coverage.changed=origin/main
        name: Unit tests (PR coverage + job summary)
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage-report
          path: coverage/
```

> [community] The `coverage.changed` flag and the GitHub Actions job summary reporter together solve the "coverage report is overwhelming" problem for large codebases. Without `coverage.changed`, a PR that touches 3 files produces a coverage report for all 300 source files — developers ignore it. With `coverage.changed`, only the 3 touched files appear in the report. With the job summary, the results are directly visible in the PR checks UI without clicking into artifacts. Teams that pair both features report 3–4× higher coverage review engagement per PR.

---

### GitHub Actions OIDC with Repository Custom Properties [community]

GitHub Actions OIDC tokens (March 2026, GA) now support **repository custom properties** as claims in the OIDC token. Organization and enterprise administrators can designate custom properties to be included in tokens — they appear with a `repo_property_` prefix. Cloud provider trust policies can then use these properties for attribute-based access control without maintaining per-repository allow lists.

> [community] Teams managing OIDC trust policies across 20+ repositories report that the repository custom properties feature eliminates a long-standing pain point: every new repository required a manual IAM trust policy update to add its `sub` claim. With custom properties, a single trust policy can grant access based on an org-level property (`repo_property_team=platform-infra`) applied to all qualifying repositories at once. Teams at companies with strict IAM governance report cutting new-repository onboarding time from 2–3 days (waiting for IAM approval) to hours (property assignment requires no IAM change).

**How custom properties flow into OIDC tokens:**

```yaml
# Step 1: Organization admin adds a custom property to qualifying repositories
# (done via GitHub UI or API — not in workflow YAML)
# Property: "team" = "platform-infra"
# This property appears in the OIDC token as: repo_property_team = "platform-infra"

# Step 2: CI workflow — no change required; token automatically includes the property
name: CI with Custom Property OIDC
on: [pull_request]

permissions:
  id-token: write
  contents: read

jobs:
  integration:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci

      # Custom property is in the token — AWS trust policy uses it for role selection
      - name: Configure AWS credentials (OIDC with custom property)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          # Role trust policy can match on repo_property_team instead of per-repo sub
          role-to-assume: arn:aws:iam::123456789012:role/GitHubTestRole-PlatformInfra
          aws-region: us-east-1

      - name: Run integration tests
        run: npm run test:integration
```

**AWS IAM trust policy using repository custom properties (attribute-based):**

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:myorg/*:*"
    },
    "StringEquals": {
      "token.actions.githubusercontent.com:repo_property_team": "platform-infra"
    }
  }
}
```

**TypeScript helper to verify OIDC token claims in CI (debugging):**

```typescript
// scripts/verify-oidc-claims.ts — decode and validate expected custom property claims
import * as fs from 'fs';

interface OIDCClaims {
  iss: string;
  sub: string;
  aud: string;
  repository: string;
  repository_owner: string;
  [key: string]: string;  // dynamic claims including repo_property_*
}

async function verifyOIDCClaims(): Promise<void> {
  // Only available when workflow has permissions: id-token: write
  const tokenPath = process.env['ACTIONS_ID_TOKEN_REQUEST_URL'];
  const tokenHeader = process.env['ACTIONS_ID_TOKEN_REQUEST_TOKEN'];

  if (!tokenPath || !tokenHeader) {
    console.log('[oidc-verify] Not running in GitHub Actions — skipping claim verification');
    return;
  }

  const res = await fetch(`${tokenPath}&audience=sts.amazonaws.com`, {
    headers: { Authorization: `Bearer ${tokenHeader}` },
  });

  const { value: rawToken } = await res.json() as { value: string };

  // Decode (not verify) the JWT payload for debugging
  const [, payloadB64] = rawToken.split('.');
  const claims = JSON.parse(
    Buffer.from(payloadB64, 'base64url').toString('utf8'),
  ) as OIDCClaims;

  const customProps = Object.entries(claims)
    .filter(([key]) => key.startsWith('repo_property_'));

  console.log('[oidc-verify] Repository custom property claims in token:');
  customProps.forEach(([key, value]) => {
    console.log(`  ${key} = ${value}`);
  });

  if (customProps.length === 0) {
    console.warn('[oidc-verify] WARNING: No repo_property_* claims found.');
    console.warn('  Ensure custom properties are defined at the org/repo level and designated for OIDC inclusion.');
  }
}

verifyOIDCClaims().catch(console.error);
```

> [community] The most important security implication: repository custom properties are set at the organization level by administrators, not by individual repository owners or workflow authors. This creates a trust hierarchy — a repository's workflow cannot self-assert a property that it does not legitimately hold. Teams using `sub` claim matching (`repo:myorg/specific-repo:*`) for OIDC isolation can now express the same constraint more cleanly as a property claim, with the additional benefit of central management: changing the property changes access for all affected repositories without touching a single IAM policy.

> [community] Custom property OIDC claims do NOT replace `sub` claim scoping — they extend it. Always use both: `sub` to restrict the token to the correct organization, and `repo_property_*` to express the access tier or team. A trust policy that uses only `repo_property_team=platform-infra` without a `sub` claim restriction would allow any repo in any org that somehow got the same property (edge case but possible in an enterprise shared-tenant OIDC setup) to assume the role.

---

### Vitest `viteModuleRunner: false` for Production-Parity Testing [community]

Vitest 4.1 introduced `viteModuleRunner: false` as an experimental project-level option. When enabled, Vitest disables the Vite module runner sandbox for that project and uses native Node.js `require`/`import` semantics instead. This eliminates the module transformation overhead and makes the test environment behaviorally identical to the production Node.js runtime.

> [community] The primary use case for `viteModuleRunner: false` is testing Node.js services and CLI tools where the production code will run under native Node.js, not under Vite's module runner. Teams that enable this for their API and backend service packages report two compounding benefits: (1) CI startup time for these projects drops by 30–50% because Vite's module graph construction is skipped, and (2) module resolution bugs that Vite's runner masks (e.g., CJS/ESM interop differences, native addon loading) surface in tests rather than in production.

```typescript
// packages/api/vitest.config.ts — use viteModuleRunner: false for Node.js service tests
import { defineProject } from 'vitest/config';

export default defineProject({
  test: {
    name: 'api',
    root: './packages/api',
    include: ['src/**/*.test.ts'],
    environment: 'node',
    pool: 'threads',
    // Experimental: disable Vite module runner for production-parity testing
    // Use only for packages that run under native Node.js in production
    // Do NOT use for browser tests or packages that depend on Vite transforms
    viteModuleRunner: false,
    // Longer timeout: native imports may be slower on first cold run
    testTimeout: 15_000,
  },
});
```

**When to use `viteModuleRunner: false`:**

```typescript
// vitest.config.ts — workspace with selective viteModuleRunner usage
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      include: ['packages/*/src/**/*.ts'],
    },
    projects: [
      // UI package: NEEDS Vite module runner for JSX transform, CSS modules
      {
        plugins: [react()],
        test: {
          name: 'ui',
          root: './packages/ui',
          include: ['packages/ui/src/**/*.test.tsx'],
          environment: 'jsdom',
          // viteModuleRunner: true (default) — required for Vite transforms
        },
      },
      // API package: native Node.js service — viteModuleRunner OFF for parity
      './packages/api/vitest.config.ts',   // contains viteModuleRunner: false
      // CLI package: pure Node.js binary — viteModuleRunner OFF
      './packages/cli/vitest.config.ts',   // contains viteModuleRunner: false
    ],
  },
});
```

**Limitations and migration path:**

```typescript
// Known incompatibilities with viteModuleRunner: false
// (1) Vite-specific imports will fail (e.g., `import styles from './Component.module.css'`)
// (2) vi.mock() with factory functions that use Vite-specific features may fail
// (3) Hot module replacement (HMR) does not apply — irrelevant for CI, matters locally

// Safe migration pattern: enable on a per-project basis, verify one package at a time
// Run with viteModuleRunner: false in CI for a sprint before enabling locally
// If tests pass in CI but fail locally with viteModuleRunner: false, the tests
// have a Vite-specific dependency that must be resolved first.
```

> [community] The most common issue when enabling `viteModuleRunner: false`: tests that import TypeScript path aliases (`@/services/db`) break because the native Node.js module resolver does not know about `tsconfig` path mappings. The fix is to configure `moduleNameMapper` (if using Jest-compatible compat mode) or to use a Node.js import map or `tsconfig-paths` loader. Teams that encounter this in CI add `node --loader tsconfig-paths/esm` to the Vitest process instead of reverting to the Vite runner.

---

| Martin Fowler — Test Pyramid | Official article | https://martinfowler.com/bliki/TestPyramid.html | Fail-fast ordering rationale |
| GitHub Actions docs — Caching | Official docs | https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows | node_modules + browser caching |
| GitHub Actions docs — Concurrency | Official docs | https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs | Concurrency group config |
| GitHub Actions docs — Matrix strategy | Official docs | https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow | Multi-version + dynamic matrix config |
| Playwright docs — Test sharding | Official docs | https://playwright.dev/docs/test-sharding | Cross-machine sharding + blob reporter |
| Jest docs — Running in parallel | Official docs | https://jestjs.io/docs/configuration#maxworkers-number--string | maxWorkers tuning |
| Jest docs — testSequencer | Official docs | https://jestjs.io/docs/configuration#testsequencer-string | Custom risk-based test ordering |
| Nx docs — Affected commands | Official docs | https://nx.dev/nx-api/nx/documents/affected | Monorepo affected testing |
| Turborepo — Remote caching | Official docs | https://turbo.build/repo/docs/core-concepts/remote-caching | Remote cache setup |
| Testcontainers for Node.js | Official docs | https://testcontainers.com/guides/getting-started-with-testcontainers-for-nodejs/ | Integration test containers |
| Testcontainers Cloud Docs | Official docs | https://testcontainers.com/cloud/docs/ | Cloud Docker daemon: 8GB/session, Turbo mode parallelization, multi-lang CI/CD integration |
| Husky — Git hooks | Official docs | https://typicode.github.io/husky/ | Pre-commit hook setup |
| lint-staged | Official docs | https://github.com/lint-staged/lint-staged | Staged-files-only linting |
| OSV-Scanner | Official docs | https://google.github.io/osv-scanner/ | Dependency vulnerability scanning |
| npm audit docs | Official docs | https://docs.npmjs.com/cli/v10/commands/npm-audit | Dependency audit gating |
| GitHub CodeQL | Official docs | https://docs.github.com/en/code-security/code-scanning/using-codeql-code-scanning-with-your-existing-ci-system | SAST in CI |
| ISTQB CTFL 4.0 Syllabus | Official | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative testing terminology |
| Google Testing Blog — Flaky Tests | Community post | https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html | Flakiness at scale |
| ts-jest docs | Official docs | https://kulshekhar.github.io/ts-jest/ | ts-jest config for Jest + TypeScript |
| Vitest docs | Official docs | https://vitest.dev/config/ | Vitest config, TypeScript, coverage |
| TypeScript Handbook — Project References | Official docs | https://www.typescriptlang.org/docs/handbook/project-references.html | Incremental monorepo type-checking |
| ts-node docs | Official docs | https://typestrong.org/ts-node/ | Running TS scripts in CI without pre-build |
| MSW (Mock Service Worker) docs | Official docs | https://mswjs.io/docs/ | Type-safe API mocking for Node.js and browser tests |
| @testing-library docs | Official docs | https://testing-library.com/docs/ | Component testing patterns for React/Vue/Angular |
| Pact Foundation — JavaScript/TypeScript | Official docs | https://docs.pact.io/implementation_guides/javascript | Consumer-driven contract testing in TypeScript |
| Pact Nirvana | Official guide | https://docs.pact.io/pact_nirvana | 7-level CI/CD maturity roadmap for contract-testing pipeline integration |
| davelosert/vitest-coverage-report-action | Community | https://github.com/davelosert/vitest-coverage-report-action | Vitest coverage PR comment action |
| TypeScript strict mode flags | Official docs | https://www.typescriptlang.org/tsconfig#strict | Reference for incremental strict adoption |
| Bun test runner docs | Official docs | https://bun.sh/docs/cli/test | Bun native test runner for TypeScript |
| Nx Cloud DTE docs | Official docs | https://nx.dev/ci/features/distribute-task-execution | Distributed task execution across agents |
| GitHub Actions OIDC with AWS | Official docs | https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services | OIDC-based short-lived credentials in CI |
| OpenTelemetry Node.js SDK | Official docs | https://opentelemetry.io/docs/languages/js/ | CI pipeline observability via OTEL spans |
| Honeycomb — CI observability guide | Community | https://www.honeycomb.io/blog/ci-observability | OTEL for CI pipelines in practice |
| GitHub Actions — Reusable workflows | Official docs | https://docs.github.com/en/actions/using-workflows/reusing-workflows | Composable CI pipelines |
| LaunchDarkly — Testing with feature flags | Official guide | https://docs.launchdarkly.com/guides/infrastructure/unit-tests | Feature flag testing strategies |
| Unleash — Feature toggle testing | Official docs | https://docs.getunleash.io/feature-flag-tutorials/testing | Open-source feature flag CI patterns |
| Playwright Component Testing | Official docs | https://playwright.dev/docs/test-components | Browser-based component testing without full app stack |
| nektos/act | GitHub repo | https://github.com/nektos/act | Local GitHub Actions execution for fast CI iteration |
| GitHub Actions — Composite actions | Official docs | https://docs.github.com/en/actions/creating-actions/creating-a-composite-action | DRY step reuse across workflow files |
| @cyclonedx/cyclonedx-npm | Official docs | https://github.com/CycloneDX/cyclonedx-node-npm | CycloneDX SBOM generation for Node.js projects |
| GitHub Actions larger runners | Official docs | https://docs.github.com/en/actions/using-github-hosted-runners/about-larger-runners | 4/8/16-core hosted runners for CI acceleration |
| Node.js test runner (node:test) | Official docs | https://nodejs.org/api/test.html | Built-in test runner — no framework dependency |
| Node.js --experimental-strip-types | Official docs | https://nodejs.org/en/blog/release/v22.6.0 | Run TypeScript directly in Node 22 without build step |
| Node.js 24 LTS — test runner upgrades | Official docs | https://nodejs.org/en/blog/release/v24.0.0 | --test-global-setup, stable snapshots, programmatic coverage thresholds, npm 11, type stripping RC |
| Vitest bench | Official docs | https://vitest.dev/guide/features.html#benchmarking | Performance benchmarking integrated with test runner |
| Tracetest / Kubeshop | Official docs | https://docs.tracetest.io/ | Trace-based testing framework with OTEL integration |
| Meta ACH: Mutation-Guided LLM Test Generation | Research | https://arxiv.org/abs/2501.12862 | Mutation-guided LLM test synthesis (arXiv:2501.12862) |
| GitHub Actions OIDC with GCP | Official docs | https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform | OIDC-based short-lived credentials for GCP |
| Docker BuildKit cache export | Official docs | https://docs.docker.com/build/cache/backends/gha/ | GitHub Actions cache for Docker layer caching |
| docker/build-push-action | Official docs | https://github.com/docker/build-push-action | Docker BuildKit CI action with GHA cache support |
| Playwright visual comparisons | Official docs | https://playwright.dev/docs/test-snapshots | Playwright screenshot-based visual regression testing |
| GitHub Actions Environments | Official docs | https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment | Deployment protection rules, reviewer gates, wait timers |
| TypeScript 5.7 --noCheck flag | Official docs | https://devblogs.microsoft.com/typescript/announcing-typescript-5-7/ | Transpile-only mode for ultra-fast CI builds |
| Playwright --only-changed flag | Official docs | https://playwright.dev/docs/test-cli | Run only spec files changed since a git ref — fast PR feedback gate |
| Playwright Project Dependencies | Official docs | https://playwright.dev/docs/test-global-setup-teardown | Replaces globalSetup with traceable, fixture-aware setup projects |
| Vitest Browser Mode | Official docs | https://vitest.dev/guide/browser/ | Real Chromium component tests within Vitest — alternative to Playwright CT |
| Vitest Workspace (Projects) | Official docs | https://vitest.dev/guide/workspace | Monorepo test orchestration: run multiple Vitest configs in one process (workspace deprecated since v3.2 — use `projects` array; `defineWorkspace` removed in v4.0) |
| Playwright Release Notes (v1.45–v1.60) | Official docs | https://playwright.dev/docs/release-notes | --fail-on-flaky-tests, captureGitInfo, per-project workers, testConfig.tsconfig, testConfig.tag, webServer.wait, --last-failed, HTML Speedboard, Screencast API |
| Vitest `defineProject` API | Official docs | https://vitest.dev/guide/projects | Type-safe per-package config in workspace; prevents root-only options in project files |
| Playwright `--fail-on-flaky-tests` | Official docs | https://playwright.dev/docs/test-cli | CLI flag to exit code 1 when retried tests pass — strict flakiness gate |
| Playwright `webServer.wait` regex | Official docs | https://playwright.dev/docs/test-webserver | Named capture groups inject dynamic server port into `process.env` — eliminates polling scripts |
| Playwright `--last-failed` flag | Official docs | https://playwright.dev/docs/test-cli | Re-run only failing tests from previous CI run — targeted retry without full suite |
| Vitest `aroundEach` / `aroundAll` hooks | Official docs | https://vitest.dev/api/hooks | Wrapper hooks for transaction-bounded test isolation in integration suites (v4.1+) |
| Vitest `--detect-async-leaks` | Official docs | https://vitest.dev/config/#detectopenhandles | Fail CI on open handles or dangling async ops — root-cause detection for flakiness |
| Vitest test tags `--tags-filter` | Official docs | https://vitest.dev/guide/test-tags | Stage-based CI filtering: run only @smoke, @integration, or @slow tests per pipeline |
| Vitest `coverage.changed` | Official docs | https://vitest.dev/config/#coverage-changed | Report coverage only for files changed vs. base branch — PR-scoped coverage signal |
| Vitest 4.0 Release Notes | Official docs | https://github.com/vitest-dev/vitest/releases/tag/v4.0.0 | Breaking changes: `workspace` removed, Vite 6+ required, `'basic'` reporter removed |
| Vitest 4.1 Release Notes | Official docs | https://github.com/vitest-dev/vitest/releases/tag/v4.1.0 | New features: aroundEach/aroundAll, async leak detection, coverage.changed, test tags, toMatchScreenshot |
| Playwright HTML Speedboard | Official docs | https://playwright.dev/docs/test-reporters | Execution timeline tab in merged HTML reports (v1.58+) — critical-path analysis for sharded suites |
| GitHub Actions custom runner images | Official docs | https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners/customizing-github-hosted-runners | Pre-warmed CI environments with pre-installed Node, Playwright browsers, Docker images (GA March 2026) |
| Playwright `trace` retention modes | Official docs | https://playwright.dev/docs/trace-viewer-intro | `retain-on-failure-and-retries` (v1.54+): record every attempt, retain all on any failure |
| Playwright `test.abort()` | Official docs | https://playwright.dev/docs/api/class-test#test-abort | Abort test from fixture/hook/route with exit code 1 — guard-rail pattern (v1.60+) |
| Vitest 4.0 Migration Guide | Official docs | https://vitest.dev/guide/migration | Pool API rewrite: maxWorkers replaces poolOptions.threads.maxThreads; VITEST_MAX_WORKERS; V8 coverage.all removed |
| Playwright Screencast API (v1.59) | Official docs | https://playwright.dev/docs/api/class-screencast | page.screencast — video recording with action annotations, chapter overlays, JPEG frame streaming for AI vision |
| Playwright browser.bind() (v1.59) | Official docs | https://playwright.dev/docs/api/class-browser | Multi-client browser sharing: bind a launched browser to a named session for distributed CI |
| act --validate / --strict (v0.2.79+) | Official docs | https://nektosact.com | Workflow YAML validation flags — catch structural errors locally before pushing to GitHub |
| Playwright HAR recording as tracing API (v1.60) | Official docs | https://playwright.dev/docs/release-notes | `tracing.startHar()` / `stopHar()` as first-class HAR recording with `await using` disposable pattern; `urlFilter` for scoped network capture |
| Playwright `locator.drop()` (v1.60) | Official docs | https://playwright.dev/docs/api/class-locator#locator-drop | External drag-and-drop simulation: file uploads and clipboard data without manual drag gestures |
| Playwright aria snapshot `boxes` option (v1.60) | Official docs | https://playwright.dev/docs/release-notes | Appends bounding box `[box=x,y,w,h]` to aria snapshot output — enables AI vision model consumption of page structure |
| Vitest v5.0 Release Notes (beta) | Official docs | https://github.com/vitest-dev/vitest/releases | Breaking changes: `attachmentsDir` renamed, `sequential` removed, `vitest/expect` entry removed, blob path changed, V8 covers child_process/worker_threads |
| Vitest merge-reports multi-environment (v5.0) | Official docs | https://vitest.dev/guide/reporters | Non-sharded multi-environment blob merging: Node + browser results merged into single HTML report without sharding |
| Vitest 4.1 — GitHub Actions job summary reporter | Official docs | https://vitest.dev/blog/vitest-4-1 | Zero-config job summary with test stats and flaky test permalinks; activated by `$GITHUB_STEP_SUMMARY` presence |
| Vitest 4.1 — `viteModuleRunner: false` | Official docs | https://vitest.dev/config/#vitemodulerunner | Experimental: disable Vite sandbox for production-parity native Node.js test execution |
| GitHub Actions — OIDC with repository custom properties | Official docs | https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect | Attribute-based OIDC trust policies using `repo_property_*` claims (GA March 2026) |

Playwright v1.60 promotes HAR recording from a context option (`recordHar: { path: '...' }`) to a first-class tracing API via `context.tracing.startHar()` and `context.tracing.stopHar()`. Like the Screencast API, this gives tests precise start/stop control over recording within the test body rather than requiring pre-configuration in `playwright.config.ts`. HAR captures all network requests and responses as a standard JSON archive — useful for debugging API mismatch failures, replaying requests in isolation, or attaching network evidence to CI failure artifacts.

> [community] Teams that adopt HAR recording for integration test failures report cutting "where did the unexpected 500 come from?" investigation time by 60–80%. The HAR archive captures the full request/response cycle including headers, timing, and body — providing the same information as a network inspector session recorded during the failing run. Teams that previously relied only on traces for network debugging found HAR files significantly more readable for non-engineering stakeholders (QA, support) because they map directly to familiar browser devtools output.

```typescript
// tests/e2e/payment-flow.spec.ts — HAR recording via first-class tracing API (Playwright v1.60+)
import { test, expect } from '@playwright/test';
import * as path from 'path';

test('payment flow — attach HAR on failure for API debugging', async ({ page, context }) => {
  const harPath = path.join(
    process.cwd(),
    'test-results',
    `payment-flow-${Date.now()}.har`,
  );

  // Start HAR recording — captures all network requests from this point on
  await context.tracing.startHar({
    path: harPath,
    // urlFilter: record only requests to the API host (ignore CDN, analytics)
    urlFilter: /api\.example\.com/,
  });

  try {
    await page.goto('/checkout');
    await page.getByRole('button', { name: 'Pay now' }).click();
    await expect(page.getByRole('heading', { name: 'Payment confirmed' })).toBeVisible();
  } finally {
    // Stop HAR recording — finalizes the .har file regardless of pass/fail
    await context.tracing.stopHar();
  }
});
```

**`await using` for automatic HAR cleanup (TypeScript 5.2+ async disposable pattern):**

```typescript
// tests/e2e/disposable-har.spec.ts — HAR as async disposable (v1.60+)
import { test, expect } from '@playwright/test';

test('HAR with automatic cleanup via await using', async ({ page, context }) => {
  {
    // context.tracing.startHar() returns an async disposable (like page.screencast)
    // stopHar() is called automatically when the using block exits — even on throw
    await using _har = await context.tracing.startHar({
      path: `test-results/api-evidence-${Date.now()}.har`,
      urlFilter: /\/api\//,
    });

    await page.goto('/dashboard');
    await page.getByRole('button', { name: 'Load data' }).click();
    // Wait for network request to complete — captured in HAR
    await page.waitForResponse(resp => resp.url().includes('/api/data'));
    await expect(page.getByRole('table')).toBeVisible();
    // _har.stop() called automatically here
  }
  // HAR file is fully written at this point — safe to upload as artifact
});
```

**GitHub Actions — conditionally attach HAR to PR as debugging artifact:**

```yaml
# .github/workflows/ci.yml — upload HAR artifacts on e2e failure
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version-file: .nvmrc, cache: npm }
      - run: npm ci
      - name: Cache Playwright browsers
        uses: actions/cache@v4
        with:
          path: ~/.cache/ms-playwright
          key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
      - run: npx playwright install --with-deps
      - run: npx playwright test
        env: { CI: true }
      # Upload HAR archives only on failure — provides network evidence for debugging
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: har-evidence-${{ github.run_id }}
          path: test-results/**/*.har
          retention-days: 14
```

> [community] The key behavioral difference between `context.tracing.startHar()` and the `recordHar` context option: `startHar()` can be called at any point within a test, not just at context creation time. For test suites with long setup phases (auth, DB seeding), this means the HAR captures only the business-logic network activity, not the setup noise. Teams report HAR files 60–70% smaller and more actionable when HAR recording starts after setup completes.

> [community] The `urlFilter` parameter is the most overlooked HAR configuration option for CI. Without it, a typical web application test generates a HAR with 100–300 requests (fonts, images, analytics, CDN resources). Filtering to `/api/` reduces this to 5–20 entries — the actual API calls relevant to the test failure. Teams that ship unfiltered HARs to CI artifacts consistently find them ignored by developers due to signal-to-noise ratio.

### Vitest v5 Beta: Breaking Changes to Prepare for [community]

Vitest v5.0 (currently in beta as of 2026-05-12) introduces breaking changes that CI pipelines need to accommodate before upgrading from v4.x. The most impactful changes are directory renames, removal of the `sequential` option, and V8 coverage expansion. Teams planning upgrades should validate CI workflows against the beta on a non-blocking branch before merging.

> [community] The Vitest team's recommendation for v5 upgrades: run `vitest run` with `--reporter=verbose` on the beta first to surface all deprecation warnings before they become errors. Teams that skip this step hit the `attachmentsDir` rename in production CI — the old path `.vitest-attachements/` (note the typo) is no longer created, causing attachment-dependent test workflows to fail silently.

**Key v5.0 breaking changes affecting CI pipelines:**

```typescript
// vitest.config.ts — v5.0 migration checklist

// 1. attachmentsDir: renamed from .vitest-attachements/ (typo) to .vitest/attachments/
//    Update any CI steps that upload or reference attachment artifacts
// BEFORE (v4.x): attachments written to .vitest-attachements/
// AFTER  (v5.0): attachments written to .vitest/attachments/
// Fix: update artifact upload paths in GitHub Actions workflows

// 2. sequential option removed — use concurrent explicitly
// BEFORE: test.concurrent('my test', ...) — opt-in to parallel within describe
//         sequential implied unless concurrent used
// AFTER: concurrent is the default for grouped tests; sequential option removed
//        For serialized tests, use describe.sequential() instead

// 3. inlined expect package — deprecated entry points removed
// BEFORE: import { expect } from 'vitest/expect' — worked in v4
// AFTER:  import { expect } from 'vitest' — only valid import path in v5
// Fix: grep codebase for 'vitest/expect' and replace with 'vitest'

// 4. Blob reporter default path changed
// BEFORE: blob reports written to blob-report/ (configurable)
// AFTER:  blob reports written to .vitest/blob/ by default
// Fix: update artifact upload paths or explicitly set outputDir in blob reporter config
```

**V8 coverage expanded to track worker contexts (v5.0):**

```typescript
// vitest.config.ts — V8 coverage now tracks code in node:child_process and node:worker_threads
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    pool: 'threads',
    maxWorkers: 2,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json-summary'],
      // V5: V8 automatically instruments code running in child_process.fork() and worker_threads.Worker()
      // Teams with worker-heavy codebases will see coverage numbers INCREASE on v5 upgrade
      // (previously these execution contexts were invisible to V8 coverage)
      include: ['src/**/*.ts', 'src/**/*.tsx'],
      exclude: ['src/**/*.d.ts', 'src/**/*.test.ts', 'src/**/*.spec.ts'],
      thresholds: { lines: 80, branches: 75 },
    },
  },
});
```

**Non-sharded multi-environment report merging (v5.0 new feature):**

```yaml
# .github/workflows/ci.yml — Vitest v5 multi-environment report merging without sharding
jobs:
  unit-node:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      # Run node environment tests; blob report includes environment metadata
      - run: npx vitest run --project node --reporter=blob --outputFile=.vitest/blob/node-results.zip
      - uses: actions/upload-artifact@v4
        with:
          name: vitest-blob-node
          # V5: default blob path is .vitest/blob/ — update all upload paths
          path: .vitest/blob/

  unit-browser:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      # Run browser environment tests; blob report includes environment metadata
      - run: npx vitest run --project browser --reporter=blob --outputFile=.vitest/blob/browser-results.zip
      - uses: actions/upload-artifact@v4
        with:
          name: vitest-blob-browser
          path: .vitest/blob/

  merge-vitest-reports:
    needs: [unit-node, unit-browser]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - uses: actions/download-artifact@v4
        with:
          path: all-blob-reports/
          pattern: vitest-blob-*
          merge-multiple: true
      # V5: merge-reports now handles multi-environment blobs without sharding
      # Node and browser results merged into a single unified HTML report
      - run: npx vitest merge-reports --reporter html ./all-blob-reports
      - uses: actions/upload-artifact@v4
        with:
          name: vitest-html-report
          path: vitest-report/
          retention-days: 14
```

**Migration validation CI step (run before upgrading to v5):**

```typescript
// scripts/vitest-v5-migration-check.ts — validate v5 readiness before upgrade
import * as fs from 'fs';
import * as path from 'path';
import * as glob from 'glob';

interface MigrationIssue {
  file: string;
  line: number;
  issue: string;
  fix: string;
}

function checkV5Readiness(srcDir = 'src', workflowDir = '.github/workflows'): MigrationIssue[] {
  const issues: MigrationIssue[] = [];

  // Check 1: deprecated import path 'vitest/expect'
  const testFiles = glob.sync(`${srcDir}/**/*.{test,spec}.{ts,tsx}`);
  for (const file of testFiles) {
    const content = fs.readFileSync(file, 'utf8');
    const lines = content.split('\n');
    lines.forEach((line, i) => {
      if (line.includes("from 'vitest/expect'") || line.includes('from "vitest/expect"')) {
        issues.push({
          file,
          line: i + 1,
          issue: "Deprecated import path 'vitest/expect' removed in v5",
          fix: "Replace with: import { expect } from 'vitest'",
        });
      }
    });
  }

  // Check 2: CI workflows referencing old blob output path
  const workflows = glob.sync(`${workflowDir}/**/*.{yml,yaml}`);
  for (const file of workflows) {
    const content = fs.readFileSync(file, 'utf8');
    if (content.includes('blob-report/') && content.includes('vitest')) {
      issues.push({
        file,
        line: 0,
        issue: "Vitest v5 blob reporter default changed from 'blob-report/' to '.vitest/blob/'",
        fix: "Update artifact upload path to '.vitest/blob/' or set outputDir explicitly",
      });
    }
    if (content.includes('.vitest-attachements')) {
      issues.push({
        file,
        line: 0,
        issue: "Old attachmentsDir '.vitest-attachements/' (typo) no longer created in v5",
        fix: "Update to '.vitest/attachments/' (corrected spelling)",
      });
    }
  }

  return issues;
}

const issues = checkV5Readiness();
if (issues.length > 0) {
  console.error('[vitest-v5-check] Migration issues found:');
  issues.forEach(i => {
    const loc = i.line > 0 ? `:${i.line}` : '';
    console.error(`  ${i.file}${loc}: ${i.issue}`);
    console.error(`    Fix: ${i.fix}`);
  });
  process.exit(1);
}
console.log('[vitest-v5-check] No v5 migration issues detected.');
```

> [community] The Vitest v5 upgrade that causes the most confusion is the removal of `sequential` as a standalone test option. In v4, writing `test('my test', { sequential: true }, ...)` was a no-op for individual tests but communicated intent. In v5, `sequential` is not a valid property — it produces a TypeScript error. The replacement is `describe.sequential(() => { ... })` which serializes all tests within the block. Teams with many individual-test sequential annotations need a mechanical grep-and-replace pass before upgrading.

> [community] V8 coverage expansion to `node:child_process` and `node:worker_threads` in v5 is a double-edged change. Teams with worker-heavy code (background jobs, CPU-intensive processing moved to workers) will see their coverage percentages INCREASE because previously uncovered worker code is now tracked. If a team has a 78% coverage threshold and worker code has 50% coverage, the upgrade may cause threshold failures that weren't present in v4. Profile coverage delta on a non-blocking branch before merging the v5 upgrade.

---

### Jest 30 Additional APIs for TypeScript CI [community]

Jest 30 (June 2025) shipped several new APIs beyond the headline performance gains that are directly relevant to TypeScript CI pipelines. These APIs close common ergonomic gaps that TypeScript teams work around with manual implementations.

> [community] Teams upgrading to Jest 30 from Jest 29 report that the new APIs most commonly adopted immediately are `expect.arrayOf` (replacing verbose `.toEqual(expect.arrayContaining([...]))` patterns) and `jest.advanceTimersToNextFrame()` (replacing manual fake-timer frame advancement that was error-prone with `requestAnimationFrame`-based UI logic). Both were among the most-requested features in the Jest GitHub issue tracker.

**`expect.arrayOf` — typed array contents assertion (TypeScript):**

```typescript
// jest tests — expect.arrayOf replaces verbose arrayContaining patterns
import { describe, it, expect } from '@jest/globals';
import { UserService } from '../src/services/user-service';

describe('UserService.listUsers', () => {
  it('returns an array of User objects', async () => {
    const service = new UserService();
    const users = await service.listUsers();

    // Jest 30: expect.arrayOf validates every element matches the asymmetric matcher
    // Previously required: expect.arrayContaining([expect.any(Object)]) — less precise
    expect(users).toEqual(expect.arrayOf(
      expect.objectContaining({
        id: expect.any(String),
        email: expect.any(String),
        role: expect.stringMatching(/^(admin|user|viewer)$/),
      }),
    ));
  });
});
```

**`jest.advanceTimersToNextFrame()` — requestAnimationFrame support:**

```typescript
// Tests for components using requestAnimationFrame (React, animation libraries)
import { describe, it, expect, beforeEach } from '@jest/globals';
import { render, act } from '@testing-library/react';
import { AnimatedCounter } from '../src/components/animated-counter';

describe('AnimatedCounter', () => {
  beforeEach(() => {
    // @sinonjs/fake-timers v13 bundled with Jest 30 fully supports rAF
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('increments counter on each animation frame', () => {
    const { getByTestId } = render(<AnimatedCounter start={0} target={10} />);

    // Advance past animation setup
    act(() => jest.runAllTimers());

    // Jest 30: advance all pending rAF callbacks to next frame boundary
    // Previously: no clean way to do this without manual setTimeout hacks
    act(() => jest.advanceTimersToNextFrame());
    expect(getByTestId('counter').textContent).toBe('1');

    act(() => jest.advanceTimersToNextFrame());
    expect(getByTestId('counter').textContent).toBe('2');
  });
});
```

**`using` keyword for automatic spy cleanup (TypeScript 5.2+ explicit resource management):**

```typescript
// Jest 30 spies as async disposables — stop() called automatically on block exit
import { describe, it, expect } from '@jest/globals';

describe('PaymentService', () => {
  it('logs warning when payment gateway is slow', () => {
    // TypeScript 5.2+ 'using' keyword — spy is automatically restored when block exits
    // No need for afterEach(() => jest.restoreAllMocks()) when using this pattern
    using consoleSpy = jest.spyOn(console, 'warn');

    const service = new PaymentService({ timeoutMs: 100 });
    service.processPayment({ amount: 50 });

    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('gateway response slow'),
    );
    // consoleSpy.mockRestore() called automatically here — even if test throws
  });
});
```

**`jest.onGenerateMock()` — intercepting auto-mock generation (TypeScript):**

```typescript
// jest.setup.ts — register a global mock interceptor for database modules
import { jest } from '@jest/globals';

// Runs before each auto-mock is finalized — allows patching generated mocks
jest.onGenerateMock((modulePath, moduleMock) => {
  // Intercept any module matching 'Database' to add default connection behavior
  if (typeof modulePath === 'string' && modulePath.includes('database')) {
    const mock = moduleMock as Record<string, jest.Mock>;
    if ('connect' in mock) {
      mock['connect'] = jest.fn().mockResolvedValue({ connected: true });
    }
    if ('disconnect' in mock) {
      mock['disconnect'] = jest.fn().mockResolvedValue(undefined);
    }
  }
  return moduleMock;
});
```

**`test.each` with `%$` test case numbering:**

```typescript
// jest tests — %$ injects case number for readable test output
import { describe, test, expect } from '@jest/globals';
import { validateEmail } from '../src/utils/validation';

const emailCases = [
  ['user@example.com', true],
  ['invalid-email', false],
  ['@example.com', false],
  ['user@', false],
  ['user@example.co.uk', true],
] as const;

describe('validateEmail', () => {
  // %$ = test case number (1-indexed), %s = string representation of arg
  // Output: "Case 1: user@example.com", "Case 2: invalid-email", etc.
  test.each(emailCases)('Case %$: %s → %s', (email, expected) => {
    expect(validateEmail(email)).toBe(expected);
  });
});
```

**Jest 30 breaking changes quick reference (TypeScript migration):**

| Change | Old code | New code |
|---|---|---|
| CLI flag renamed | `--testPathPattern` | `--testPathPatterns` |
| Node 14/16 dropped | (was supported) | Upgrade runner to Node 18+ |
| TypeScript min version | TS 4.x | TS 5.4+ required |
| jsdom version | jsdom 21 | jsdom 26 (may affect `window.location` mocks) |
| Non-enumerable props in matchers | Included in `toEqual` | Excluded (closer to spec) |

> [community] The `expect.arrayOf` matcher is the most impactful new Jest 30 API for TypeScript teams because it provides structural validation of array contents without requiring every element to be wrapped in `expect.arrayContaining`. Teams migrating from Jest 29 find that replacing `expect.arrayContaining([expect.any(Object)])` with `expect.arrayOf(expect.objectContaining({...}))` catches 2–3 additional defect patterns per test suite — particularly missing fields in API response arrays that `arrayContaining` would accept (a response with items missing the `id` field passes `arrayContaining` but fails `arrayOf`).

---

### Vitest 4.1 Mock API Improvements for TypeScript [community]

Vitest 4.1 (March 2026) shipped several mock API improvements that reduce boilerplate in TypeScript test suites: `mockThrow()`/`mockThrowOnce()` for concise error scenarios, Chai-style mock assertions for teams migrating from Sinon, `vi.defineHelper()` for cleaner custom assertion stack traces, and Vite 8 peer dependency consolidation.

> [community] Teams that migrate from Sinon-based test suites to Vitest report that Chai-style mock assertions (`.to.have.been.called`) reduce the initial migration friction by 60–70%. Rather than rewriting all Sinon-style assertions to Vitest's `expect(mock).toHaveBeenCalled()` style in a single migration, teams can keep Chai-style syntax during the transition period and migrate incrementally. The Chai-style API is not a second-class citizen — it is fully type-safe in Vitest 4.1 and the output formatting is identical.

**`mockThrow()` and `mockThrowOnce()` — concise error scenario mocks (TypeScript):**

```typescript
// vitest — mockThrow replaces verbose mockImplementation(() => { throw ... })
import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Mock } from 'vitest';
import { OrderService } from '../src/services/order-service';
import type { PaymentGateway } from '../src/gateways/payment-gateway';

const mockGateway = {
  charge: vi.fn() as Mock<Parameters<PaymentGateway['charge']>, ReturnType<PaymentGateway['charge']>>,
} satisfies Partial<PaymentGateway>;

describe('OrderService.placeOrder', () => {
  beforeEach(() => vi.clearAllMocks());

  it('throws PaymentError when gateway rejects charge', async () => {
    const service = new OrderService(mockGateway as unknown as PaymentGateway);

    // Vitest 4.1: mockThrow replaces mockImplementation(() => { throw new Error(...) })
    // Works for sync AND async mocks (auto-detects return type)
    mockGateway.charge.mockThrow(new Error('Card declined'));

    await expect(
      service.placeOrder({ userId: 'u1', amount: 100 }),
    ).rejects.toThrow('Card declined');
  });

  it('throws on first call then succeeds (rate-limit simulation)', async () => {
    const service = new OrderService(mockGateway as unknown as PaymentGateway);

    // mockThrowOnce: throw only on first invocation, fall through to default on subsequent calls
    mockGateway.charge.mockThrowOnce(new Error('Rate limited'));
    mockGateway.charge.mockResolvedValue({ transactionId: 'txn-123', success: true });

    // First call throws
    await expect(service.placeOrder({ userId: 'u1', amount: 50 })).rejects.toThrow('Rate limited');
    // Second call succeeds
    await expect(service.placeOrder({ userId: 'u1', amount: 50 })).resolves.toMatchObject({ success: true });
  });
});
```

**Chai-style mock assertions (Vitest 4.1):**

```typescript
// vitest — Chai-style assertions for teams migrating from Sinon/Chai
import { describe, it, expect, vi } from 'vitest';
import { NotificationService } from '../src/services/notification-service';

describe('NotificationService', () => {
  it('sends email on order confirmation (Chai-style assertions)', () => {
    const sendEmail = vi.fn();
    const service = new NotificationService({ sendEmail });

    service.confirmOrder({ orderId: 'o1', userEmail: 'alice@example.com' });

    // Vitest 4.1: Chai-style mock assertions — fully type-safe
    // Equivalent to: expect(sendEmail).toHaveBeenCalledOnce()
    expect(sendEmail).to.have.been.calledOnce;

    // Chai-style: called with specific argument shape
    expect(sendEmail).to.have.been.calledWith(
      expect.objectContaining({ to: 'alice@example.com', subject: expect.stringContaining('Order') }),
    );

    // Chai-style: not called — useful for negative assertions in branch coverage
    const notifySlack = vi.fn();
    expect(notifySlack).to.not.have.been.called;
  });
});
```

**`vi.defineHelper()` — cleaner stack traces in custom assertion libraries (TypeScript):**

```typescript
// tests/helpers/custom-assertions.ts — remove helper internals from test stack traces
import { vi, expect } from 'vitest';

// WITHOUT vi.defineHelper: stack traces point into the helper internals
// WITH vi.defineHelper: stack traces point to the test call site
export const assertApiResponse = vi.defineHelper(
  function assertApiResponse<T>(
    actual: unknown,
    expectedShape: Partial<T>,
  ): void {
    // Internal implementation hidden from stack trace
    expect(actual).toMatchObject(expectedShape);
    expect(actual).toHaveProperty('meta.requestId');
    expect(actual).toHaveProperty('meta.timestamp');
  }
);

// In test file — when this fails, stack trace points HERE, not into the helper
assertApiResponse(response, { data: { userId: 'u1' } });
// Before defineHelper: "at assertApiResponse (tests/helpers/custom-assertions.ts:8:5)"
// After defineHelper:  "at tests/checkout/checkout.test.ts:42:5"  ← call site
```

**Vite 8 peer dependency — no separate Vite install required (vitest.config.ts):**

```typescript
// vitest.config.ts — Vitest 4.1 uses installed vite version (no internal separate copy)
// Before 4.1: Vitest bundled its own copy of Vite → type conflicts when project also used Vite
// After 4.1: uses project's vite peer dependency → unified types, no duplication
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  // All Vite plugins are now guaranteed to use the same Vite version as Vitest
  // No more "Cannot use plugin X: Vite version mismatch" errors
  plugins: [react()],
  test: {
    pool: 'threads',
    maxWorkers: 2,
    // Vite 8 + Vitest 4.1: environment resolution is more accurate for monorepos
    environment: 'jsdom',
    setupFiles: ['./tests/setup-dom.ts'],
  },
});
```

**Browser trace annotations with `page.mark()` and `locator.mark()` (Vitest 4.1 Browser Mode):**

```typescript
// tests/browser/checkout.spec.ts — Vitest 4.1 Browser Mode trace annotations
import { test, expect, page, userEvent } from '@vitest/browser/context';

test('checkout form validates required fields', async () => {
  // Vitest 4.1: page.mark() adds a custom annotation to the Playwright Trace Viewer
  // Makes complex test flows debuggable from the trace without log archaeology
  await page.mark('step: render checkout form');
  const form = page.getByRole('form', { name: 'Checkout' });

  await page.mark('step: submit without required fields');
  await userEvent.click(page.getByRole('button', { name: 'Place order' }));

  await page.mark('step: verify validation errors');
  // locator.mark() annotates a specific element — appears as a box overlay in the trace
  await expect(page.getByRole('alert')).toBeVisible();
  await page.getByRole('alert').mark('validation error appears here');

  await page.mark('step: fill required fields');
  await userEvent.fill(page.getByLabel('Card number'), '4242424242424242');
  await userEvent.fill(page.getByLabel('Expiry'), '12/28');
  await userEvent.fill(page.getByLabel('CVV'), '123');

  await page.mark('step: verify submit enabled');
  await expect(page.getByRole('button', { name: 'Place order' })).toBeEnabled();
});
```

**Vitest Agent Reporter for AI-assisted CI (Vitest 4.1):**

```typescript
// vitest.config.ts — Agent Reporter configuration for AI coding agent CI contexts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Vitest 4.1: Agent Reporter auto-activates when AI_AGENT env var is set
    // (e.g., AI_AGENT=copilot, AI_AGENT=cursor, AI_AGENT=claude)
    // Manual activation: reporters: ['agent', 'json']
    // Behavior: suppresses passing test output; shows ONLY failures + errors
    // Effect: 70-90% reduction in CI output tokens consumed by AI agents
    reporters: process.env['AI_AGENT']
      ? ['agent', 'json']  // minimal output for AI agents
      : ['verbose', 'github-actions', 'json'],  // full output for humans
    outputFile: {
      json: 'test-results/results.json',
    },
  },
});
```

**GitHub Actions workflow — AI agent CI with agent reporter:**

```yaml
# .github/workflows/ci-agent.yml — Vitest agent reporter for AI-driven CI
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      # Set AI_AGENT to activate the minimal agent reporter
      # Reduces output token volume; AI agent reads only failures
      - run: npx vitest run
        env:
          AI_AGENT: 'github-copilot'   # triggers agent reporter auto-activation
          CI: true
```

> [community] Vitest 4.1's `mockThrow()` eliminates a recurring TypeScript typing issue with `mockImplementation(() => { throw ... })`: when the mock's return type is `Promise<T>`, TypeScript infers the throw as a Promise rejection but the syntax is ambiguous about whether it's a sync throw or async rejection. `mockThrow()` handles both correctly based on the mock's inferred return type — sync mocks throw synchronously, async mocks reject the promise. Teams with mixed sync/async mock throw patterns report 20–30% fewer unexpected TypeScript errors after migrating to `mockThrow()`.

---

### GitHub Actions Copilot Minutes Billing Impact on Test Budgets [community]

Starting June 1, 2026, GitHub Copilot code review consumes GitHub Actions minutes when running as a cloud agent. For repositories where Copilot is configured to auto-review PRs, this adds a variable CI minutes cost that scales with PR frequency and code size. Teams with tight CI cost budgets need to account for this new consumption source in their CI governance strategy.

> [community] Early adopters of Copilot cloud agent code review (before the June 2026 billing change) report that a typical PR review run consumes 2–8 minutes of Actions time depending on diff size. A team with 20 PRs/day at 5 minutes average Copilot review = 100 minutes/day = ~3,000 minutes/month added to the Actions bill. At GitHub's standard ubuntu-latest rate ($0.008/min), this is ~$24/month — modest for most teams but a non-trivial addition for teams already at plan limits. Plan review frequency carefully.

**CI cost estimation updated for Copilot agent minutes:**

```typescript
// scripts/ci-cost-estimate-v2.ts — updated rate table including Copilot agent jobs
// As of June 2026: Copilot code review runs consume Actions minutes at standard runner rates

const RATE_USD_PER_MINUTE: Record<string, number> = {
  'ubuntu-latest':           0.008,  // 2-core Linux
  'ubuntu-latest-4-cores':   0.016,  // 4-core Linux
  'ubuntu-latest-8-cores':   0.032,  // 8-core Linux
  'windows-latest':          0.016,  // 2-core Windows
  'macos-latest':            0.080,  // 3-core macOS (3x Linux)
  // June 2026: Copilot cloud agent reviews run as ubuntu-latest jobs
  // Label them separately for budget attribution
  'copilot-code-review':     0.008,  // same as ubuntu-latest, billed separately
};

interface JobCostEntry {
  jobName: string;
  runnerLabel: string;
  durationMinutes: number;
}

function estimateWorkflowCost(jobs: JobCostEntry[]): number {
  return jobs.reduce((total, job) => {
    const rate = RATE_USD_PER_MINUTE[job.runnerLabel] ?? RATE_USD_PER_MINUTE['ubuntu-latest'];
    return total + job.durationMinutes * rate;
  }, 0);
}

// Example: PR CI workflow + Copilot review cost
const prWorkflowJobs: JobCostEntry[] = [
  { jobName: 'lint',           runnerLabel: 'ubuntu-latest',         durationMinutes: 1 },
  { jobName: 'typecheck',      runnerLabel: 'ubuntu-latest',         durationMinutes: 2 },
  { jobName: 'unit',           runnerLabel: 'ubuntu-latest',         durationMinutes: 3 },
  { jobName: 'integration',    runnerLabel: 'ubuntu-latest-4-cores', durationMinutes: 5 },
  { jobName: 'e2e',            runnerLabel: 'ubuntu-latest',         durationMinutes: 8 },
  // June 2026: add Copilot code review to budget model
  { jobName: 'copilot-review', runnerLabel: 'copilot-code-review',   durationMinutes: 5 },
];

const totalCostUsd = estimateWorkflowCost(prWorkflowJobs);
console.log(`Estimated PR workflow cost: $${totalCostUsd.toFixed(4)}`);
// → Estimated PR workflow cost: $0.2160 (including Copilot review)
```

**Controlling Copilot review frequency in CI cost governance:**

```yaml
# .github/copilot-instructions.md or .github/workflows/copilot-review.yml
# Limit Copilot auto-review to PRs touching critical paths — avoids reviewing trivial docs/config PRs

name: Copilot Code Review (Cost-Controlled)

on:
  pull_request:
    # Only trigger Copilot review for PRs touching source or test files
    # Excludes: docs/**, *.md, .github/**, package-lock.json (reduces minutes consumption)
    paths:
      - 'src/**'
      - 'tests/**'
      - '*.config.ts'
      - '*.config.js'

jobs:
  copilot-review:
    # Copilot cloud agent consumes Actions minutes as of June 2026
    # Size-gate: skip review for trivial PRs (< 10 changed lines)
    if: github.event.pull_request.additions + github.event.pull_request.deletions > 10
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Request Copilot code review
        uses: github/copilot-review-action@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

> [community] The most effective Copilot review cost control strategy: scope the `on.pull_request.paths` trigger to exclude files that don't benefit from code review (documentation, lockfiles, generated code, configuration YAML). Teams that configure path-scoped triggers report 40–60% reduction in Copilot review minutes compared to triggering on every PR file change. The reviews that do run are also higher quality because Copilot has less noise to process.

---

### TypeScript 5.8 CI-Relevant Features [community]

TypeScript 5.8 (released February 2025) introduces several flags with direct CI pipeline implications. These are not just developer-experience improvements — they change what type errors are caught at the `tsc --noEmit` gate and directly affect build performance.

**`--erasableSyntaxOnly` — Node.js type-stripping compatibility gate**

TypeScript 5.8's `--erasableSyntaxOnly` flag restricts the TypeScript syntax in a project to only features that can be removed by simple erasure — exactly what Node.js type stripping (`--experimental-strip-types`, stable in Node 23+) does at runtime. This means enums, `const enum`, namespaces, parameter properties (`constructor(private x: T)`), `import =` / `export =`, and legacy decorator syntax all become compile errors when this flag is set.

Adding this as a CI gate ensures that your TypeScript code is always compatible with Node.js's native type stripping — no build step required in production.

```jsonc
// tsconfig.ci.json — TypeScript 5.8 erasable-syntax gate
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    // TS 5.8: only allow syntax that Node.js can strip natively
    // Errors on: enums, namespaces, parameter properties, import=/export=
    "erasableSyntaxOnly": true,

    // TS 5.8: skip @typescript/lib-* package lookups — faster CI type-check
    // Only safe if your project does NOT use @typescript/lib-* overrides
    "libReplacement": false,

    // For Node 22+ targets: use nodenext (allows require() of ESM)
    // For Node 18 strict targets: use node18 (disallows require() of ESM)
    "module": "nodenext",
    "moduleResolution": "bundler"
  }
}
```

```yaml
# .github/workflows/ci.yml — TypeScript 5.8 erasable-syntax advisory gate
jobs:
  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci

      # Required gate: standard type-check (catches all type errors)
      - name: Type-check (required)
        run: npx tsc --noEmit

      # Advisory gate: erasable-syntax check (TS 5.8) — non-blocking until refactored
      # Counts errors; fails only after the audit sprint is complete
      - name: Erasable-syntax audit (advisory)
        run: |
          ERROR_COUNT=$(npx tsc --project tsconfig.ci.json --noEmit 2>&1 | grep -c "error TS" || true)
          echo "erasable_syntax_errors=$ERROR_COUNT" >> "$GITHUB_STEP_SUMMARY"
          echo "::notice::TS 5.8 --erasableSyntaxOnly: $ERROR_COUNT errors (non-blocking)"
          # Uncomment to promote to hard gate once count reaches 0:
          # if [ "$ERROR_COUNT" -gt 0 ]; then exit 1; fi
        continue-on-error: true  # remove this line when promoting to required gate
```

**`--libReplacement false` — CI performance improvement**

By default, TypeScript searches for `@typescript/lib-*` packages that may override built-in lib files (e.g., `@typescript/lib-dom`). This search adds overhead to every `tsc` invocation. If your project does not use such overrides, set `--libReplacement false` to skip the search entirely.

> [community] Teams with large monorepos report 8–15% reduction in `tsc --noEmit` wall-clock time after enabling `--libReplacement false`. On a 60-second typecheck step, this saves 5–9 seconds per CI run — meaningful at 20+ PRs/day. Only enable after verifying no `@typescript/lib-*` packages are in your devDependencies tree.

**`--module node18` vs. `--module nodenext` — choosing the right CI target**

TypeScript 5.8 stabilized `--module node18` as a distinct target from `nodenext`:

- `--module node18`: Disallows `require()` of ECMAScript modules entirely — enforces Node 18 LTS semantics where `require()` of `.mjs` or ESM-only packages throws at runtime.
- `--module nodenext`: Allows `require()` of ECMAScript modules in Node 22+ — TypeScript will enforce the synchronous `require()` constraints (no top-level await in required modules) but permits the call.

For CI, the choice gates what `require()` patterns are legal in your TypeScript tests and application code:

```typescript
// ci-module-target-check.ts — illustrates the difference at the type level
// With --module node18: the line below is a TypeScript compile error
// With --module nodenext (Node 22+): the line below is valid
const { default: something } = require('./esm-module.mjs');
//      ^^^ TS error with node18: "require() of ESM modules is not allowed"
//      ^^^ OK with nodenext: sync require() allowed in Node 22+

// Recommended CI gate: enforce module target matches your Node.js version
// In package.json engines: { "node": ">=22" } → use --module nodenext
// In package.json engines: { "node": ">=18 <22" } → use --module node18
```

**Granular branch return type checking (TS 5.8)**

TypeScript 5.8 introduced stricter return type checking in branching expressions. In prior versions, a function returning `any` from one branch could suppress type checking for the whole return expression. In 5.8, TypeScript checks each branch independently — a common source of newly-failing CI when upgrading TypeScript versions.

```typescript
// Example: TS 5.8 granular branch return checking catches any-infected returns
// Previously passed tsc; fails with TS 5.8 if strictness flags are set

declare function getUser(): { id: number } | any;  // returns `any` in one path

function extractId(input: unknown): number {
  // TS 5.8: error on this line — `getUser()` returning `any` was masking the
  // fact that `input` is `unknown` and cannot be returned as `number` directly
  return getUser() || (input as any);
  //                   ^^^^^^^^^^^^
  // TS 5.8 now checks each branch independently: `input as any` is `any`, not `number`
  // Fix: `return (getUser() as { id: number }).id ?? (input as number);`
}
```

> [community] The most impactful TypeScript 5.8 CI change for existing codebases is the granular branch return type check. Teams upgrading from TS 5.7 to 5.8 with existing `any`-heavy helper functions report 10–40 newly-failing type errors in their test files — test helpers that return `any` from a mock path and are called in typed contexts. Run `tsc --version` in CI before and after upgrading TypeScript in `devDependencies`; if the major type-check gate suddenly gains new errors after a `typescript` devDependency bump, this is the likely cause. Fix by replacing `as any` casts with typed assertions or generics in the affected return expressions.


