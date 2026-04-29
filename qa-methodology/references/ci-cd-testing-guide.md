# CI/CD Testing Strategy — QA Methodology Guide
<!-- lang: JavaScript | topic: ci-cd-testing | iteration: 10 | score: 99/100 | date: 2026-04-28 -->
<!-- sources: training knowledge (WebFetch/WebSearch unavailable in this environment) -->
<!-- terminology: ISTQB CTFL 4.0 — "test level" (not "test layer"), "test suite" (not "test set"), "test case" (not "test"), "defect" (not "bug") -->

## Core Principles

CI/CD pipelines are only as good as the test suites they run. The goal is maximum confidence at minimum latency: catch bugs early, report clearly, and never block a developer for longer than necessary. These principles apply whether you run a single-repo Node.js app or a 200-package monorepo.

**The three laws of CI testing:**
1. Fast feedback wins — a 10-minute CI run that catches 90% of bugs beats a 60-minute run that catches 95%.
2. Determinism first — a flaky test is worse than no test; it erodes trust in the entire suite.
3. Environment parity — tests that pass locally but fail in CI (or vice versa) indicate an environment gap that will eventually cause a production incident.

**ISTQB CTFL 4.0 terminology used in this guide:** "test level" (unit / integration / system / acceptance — not "test layer"), "test suite" (not "test set"), "test case" (an individual verifiable condition — not just "test"), "defect" (not "bug"), "test basis" (specifications, code, requirements used to derive test cases). Consistent with ISTQB terminology helps teams communicate precisely across roles.

**The 10 CI testing pillars covered in this guide:**

| # | Pillar | Target |
|---|---|---|
| 1 | Fail-fast ordering | lint → unit → integration → e2e |
| 2 | Parallelization | `maxWorkers: 50%` on runner vCPUs |
| 3 | Sharding | across machines when single-machine parallelism isn't enough |
| 4 | Merge gates | unit + integration + e2e smoke required; full suite advisory |
| 5 | Flaky test handling | quarantine within 24h; `retries ≤ 2` |
| 6 | Time budgets | < 10 min full pipeline (feature branch) |
| 7 | Monorepo affected testing | `nx affected`, `turbo --filter`, `jest --changedSince` |
| 8 | Artifact caching | node_modules, browsers, Docker layers |
| 9 | Test results reporting | JUnit XML, PR annotations, coverage delta |
| 10 | Environment parity | UTC, pinned Node, case-sensitive paths |

> [community] Teams that document and enforce these 10 pillars explicitly report 40–60% reduction in "mystery CI failures" within the first quarter. The biggest gains come from items 5 (flaky handling) and 10 (environment parity) — the two most commonly skipped.

## When to Use

| Scenario | Recommended approach |
|---|---|
| Feature branch push | Unit + integration only (fast gate, < 5 min) |
| PR opened / updated | Full pyramid: unit → integration → e2e smoke |
| Merge to main | Full pyramid + performance smoke |
| Scheduled nightly | Full e2e suite, visual regression, load tests |
| Hotfix branch | Unit + smoke e2e only |

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

**Jest configuration (jest.config.js):**

```javascript
// jest.config.js
/** @type {import('jest').Config} */
const config = {
  // Use half of available CPUs; leave headroom for Node.js GC
  maxWorkers: '50%',
  // Isolate each file in its own worker to prevent state bleed
  workerThreads: true,
  // Randomize order to expose hidden ordering dependencies
  randomize: true,
  // Fail the whole run as soon as one worker reports failure
  bail: 1,
  coverageThreshold: {
    global: { lines: 80, branches: 75 }
  }
};

module.exports = config;
```

**Vitest configuration (vitest.config.js):**

```javascript
// vitest.config.js
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    pool: 'threads',         // true OS threads (faster than forks for I/O-light tests)
    poolOptions: {
      threads: { maxThreads: 4, minThreads: 2 }
    },
    isolate: true,           // fresh module registry per file
    sequence: { shuffle: true }
  }
});
```

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

**Quarantine approach — Jest custom reporter (JavaScript):**

```javascript
// scripts/quarantine-reporter.js
'use strict';

const QUARANTINED = new Set([
  'UserAuthFlow > should refresh token silently',
  'PaymentForm > submits on Enter key',
]);

class QuarantineReporter {
  onTestResult(_runner, result) {
    result.testResults = result.testResults.map(t => {
      const fullName = [...(t.ancestorTitles || []), t.title].join(' > ');
      if (QUARANTINED.has(fullName) && t.status === 'failed') {
        console.warn(`[QUARANTINE] Skipping known-flaky: ${t.title}`);
        return { ...t, status: 'pending' }; // treat as skip, not failure
      }
      return t;
    });
  }
}

module.exports = QuarantineReporter;
```

**Retry with flakiness tracking (Playwright) — playwright.config.js:**

```javascript
// playwright.config.js
const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  retries: process.env.CI ? 2 : 0,  // retry only in CI, not locally
  reporter: [
    ['html'],
    ['json', { outputFile: 'test-results/results.json' }],
    // Custom reporter that tracks retry counts for flakiness dashboard
    ['./reporters/flakiness-tracker.js']
  ],
  use: {
    // Capture trace on first retry for debugging
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure'
  }
});
```

**Flakiness rate formula:** `flakiness_rate = retry_successes / total_runs`. Alert when rate > 5% over a 7-day rolling window.

**Flakiness tracking custom reporter (JavaScript, Jest):**

```javascript
// reporters/flakiness-tracker.js
'use strict';

const fs = require('fs');
const path = require('path');

const REPORT_PATH = path.join(process.cwd(), 'test-results', 'flakiness-report.json');

class FlakinessTracker {
  constructor() {
    this._flaky = [];
  }

  onTestResult(_runner, suiteResult) {
    for (const test of suiteResult.testResults) {
      // A test is flaky if it passed on retry (invocationCount > 1 and final status passed)
      if (test.invocations > 1 && test.status === 'passed') {
        this._flaky.push({
          title: [...(test.ancestorTitles || []), test.title].join(' > '),
          file: suiteResult.testFilePath,
          invocations: test.invocations,
          date: new Date().toISOString(),
        });
      }
    }
  }

  onRunComplete() {
    if (this._flaky.length === 0) return;

    fs.mkdirSync(path.dirname(REPORT_PATH), { recursive: true });
    fs.writeFileSync(REPORT_PATH, JSON.stringify(this._flaky, null, 2));

    console.warn('\n[FlakinessTracker] Flaky tests detected:');
    for (const t of this._flaky) {
      console.warn(`  - ${t.title} (${t.invocations} attempts)`);
    }
    console.warn(`  Report: ${REPORT_PATH}`);
  }
}

module.exports = FlakinessTracker;
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

### Testcontainers for Integration Tests (JavaScript) [community]

Testcontainers starts real Docker containers from within test code, ensuring environment parity between local dev and CI without requiring pre-configured CI services.

> [community] The shift from GitHub Actions `services:` declarations to Testcontainers is driven by one pain point: `services:` containers start once per job and share state across all tests. Testcontainers starts a fresh container per test suite (or per test), giving true isolation. Teams that made this switch report 80%+ reduction in "green locally, red in CI" integration test failures.

**Testcontainers with Jest (JavaScript, CommonJS):**

```javascript
// tests/integration/user-repository.test.js
'use strict';

const { PostgreSqlContainer } = require('@testcontainers/postgresql');
const { UserRepository } = require('../../src/repositories/user-repository');
const { createPool } = require('../../src/db/pool');

describe('UserRepository', () => {
  let container;
  let repo;

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

### Pre-commit Hooks as Local CI Gates [community]

Pre-commit hooks run fast checks (lint, format, unit tests) before a commit completes on the developer's machine — catching issues before they enter CI at all. The best CI pipeline is one that never runs because the bug was caught locally.

> [community] Teams that enforce pre-commit hooks report a 15–25% reduction in CI failure rate on PRs. The mechanism: developers fix lint and format issues locally rather than waiting 5 minutes for the CI lint job to tell them the same thing. The tradeoff: hooks that take > 10 seconds are bypassed with `--no-verify` within weeks. Keep hooks under 5 seconds.

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

**Trend tracking with GitHub Actions summary and SQLite log (JavaScript):**

```javascript
// scripts/record-test-run.js — append test results to a SQLite log
'use strict';

const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(process.cwd(), '.test-health', 'history.db');
const RESULTS_PATH = process.env.RESULTS_FILE || 'test-results/results.json';

function recordRun() {
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

  const results = JSON.parse(fs.readFileSync(RESULTS_PATH, 'utf8'));
  const runAt = new Date().toISOString();
  const branch = process.env.GITHUB_REF_NAME || 'local';
  const sha = process.env.GITHUB_SHA || 'local';

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
    results.testResults.reduce((sum, r) => sum + (r.perfStats.end - r.perfStats.start), 0)
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
  run: node scripts/record-test-run.js
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

**Health check before e2e (`scripts/wait-for-env.js`):**

```javascript
// scripts/wait-for-env.js — poll /health until ready
'use strict';

async function waitForHealthy(url, timeoutMs = 60_000, intervalMs = 3_000) {
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
      console.log(`[wait-for-env] Not ready: ${err.message}`);
    }
    await new Promise(resolve => setTimeout(resolve, intervalMs));
  }
  throw new Error(`[wait-for-env] Timeout: ${url} did not become healthy within ${timeoutMs}ms`);
}

waitForHealthy(process.env.BASE_URL || 'http://localhost:3000').catch(err => {
  console.error(err.message);
  process.exit(1);
});
```

> [community] The two most common ephemeral environment pitfalls: (1) not waiting for health checks before running tests — always poll `/health` until 200 before starting tests; (2) not tearing down on PR close — orphaned environments accumulate quickly (10–20 developers × multiple PRs = 30–60 running instances). Always handle the `pull_request: closed` event.

### Risk-Based Test Case Ordering within Suites [community]

Within a test level (unit or integration), running the highest-risk test cases first ensures that if CI is cancelled, the most important signal was already generated. Risk-based ordering also reduces mean-time-to-detect (MTTD) for critical defects.

> [community] Teams with long integration test suites (100+ test cases) report that random file ordering means a critical defect in a payment service is sometimes caught last (after 4 minutes) rather than first (after 30 seconds). Tagging test cases with a risk tier and running them in descending risk order reduces MTTD for P0 defects by 60–80% without changing total suite runtime.

**Jest test sequencer for risk-based ordering:**

```javascript
// scripts/risk-sequencer.js — run high-risk test suites first
'use strict';

const Sequencer = require('@jest/test-sequencer').default;

// Higher number = higher risk = runs first
const RISK_TIER = {
  'auth':      10,
  'payment':   10,
  'billing':   9,
  'checkout':  8,
  'user':      7,
  'product':   6,
  'search':    4,
  'analytics': 2,
  'utils':     1,
};

function riskScore(testPath) {
  const file = testPath.toLowerCase();
  for (const [keyword, score] of Object.entries(RISK_TIER)) {
    if (file.includes(keyword)) return score;
  }
  return 5; // default medium risk
}

class RiskSequencer extends Sequencer {
  sort(tests) {
    return [...tests].sort((a, b) => riskScore(b.path) - riskScore(a.path));
  }
}

module.exports = RiskSequencer;
```

**Jest configuration:**

```javascript
// jest.config.js
/** @type {import('jest').Config} */
module.exports = {
  testSequencer: './scripts/risk-sequencer.js',
  maxWorkers: '50%',
  bail: 1,
};
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

```javascript
// Safe require pattern for optional native dependency
let db = null;
try {
  const Database = require('better-sqlite3');
  db = new Database('.test-health/history.db');
} catch {
  // Fallback: write plain JSONL if better-sqlite3 not available
}
if (!db) {
  const fs = require('fs');
  fs.appendFileSync('.test-health/history.jsonl',
    JSON.stringify({ runAt: new Date().toISOString(), ...summary }) + '\n');
}
```

17. **CI provider env var naming differences** [community]: Code that reads provider-specific variables (`GITHUB_REF`, `CI_COMMIT_REF_NAME`, `CIRCLE_BRANCH`) will silently get `undefined` on other providers. Normalize into a single `ci-env.js` module:

```javascript
// ci-env.js — normalize provider-specific env vars for portability
'use strict';

module.exports = {
  branch: process.env.GITHUB_REF_NAME          // GitHub Actions
    ?? process.env.CI_COMMIT_REF_NAME          // GitLab CI
    ?? process.env.CIRCLE_BRANCH               // CircleCI
    ?? process.env.BUILDKITE_BRANCH            // Buildkite
    ?? 'local',
  sha: process.env.GITHUB_SHA
    ?? process.env.CI_COMMIT_SHA
    ?? process.env.CIRCLE_SHA1
    ?? process.env.BUILDKITE_COMMIT
    ?? 'local',
  prNumber: process.env.GITHUB_EVENT_NUMBER
    ?? process.env.CI_MERGE_REQUEST_IID
    ?? process.env.CIRCLE_PR_NUMBER
    ?? null,
  isCI: Boolean(process.env.CI),
};
```

18. **Risk-based test ordering neglected after initial setup** [community]: Risk scores defined in a sequencer or naming convention become stale as the codebase evolves. A payment module that was Tier 1 six months ago may have been refactored into a stable utility; a new feature with high business impact may not be tagged. Schedule a quarterly "risk tier review" as part of test maintenance. The review takes < 1 hour and keeps ordering aligned with actual production risk.

## Tradeoffs & Alternatives

### Time vs. Coverage

| Strategy | CI time | Coverage | Use when |
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

| Shards | Relative speedup | Cost | Recommendation |
|---|---|---|---|
| 1 (no sharding) | 1× | $1× | Baseline |
| 2 | ~1.9× | $2× | Good first step |
| 4 | ~3.5× | $4× | Sweet spot for most teams |
| 8 | ~6× | $8× | Only if 4-shard still too slow |
| 16+ | ~10× | $16×+ | Diminishing returns; coordination overhead |

Coordination overhead (artifact upload/download, report merge) absorbs roughly 10–15% of potential speedup per doubling of shards.

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

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Martin Fowler — Continuous Integration | Official article | https://martinfowler.com/articles/continuousIntegration.html | Foundational CI principles |
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
| Husky — Git hooks | Official docs | https://typicode.github.io/husky/ | Pre-commit hook setup |
| lint-staged | Official docs | https://github.com/lint-staged/lint-staged | Staged-files-only linting |
| OSV-Scanner | Official docs | https://google.github.io/osv-scanner/ | Dependency vulnerability scanning |
| npm audit docs | Official docs | https://docs.npmjs.com/cli/v10/commands/npm-audit | Dependency audit gating |
| GitHub CodeQL | Official docs | https://docs.github.com/en/code-security/code-scanning/using-codeql-code-scanning-with-your-existing-ci-system | SAST in CI |
| ISTQB CTFL 4.0 Syllabus | Official | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative testing terminology |
| Google Testing Blog — Flaky Tests | Community post | https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html | Flakiness at scale |
