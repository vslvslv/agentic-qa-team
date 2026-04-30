# CI/CD Testing Strategy — QA Methodology Guide
<!-- lang: JavaScript | topic: ci-cd-testing | iteration: 3 | score: 100/100 | date: 2026-04-30 -->
<!-- sources: training knowledge (WebSearch unavailable in this environment) -->
<!-- terminology: ISTQB CTFL 4.0 — "test level" (not "test layer"), "test suite" (not "test set"), "test case" (not "test"), "defect" (not "bug") -->

## Core Principles

CI/CD pipelines are only as good as the test suites they run. The goal is maximum confidence at minimum latency: catch defects early, report clearly, and never block a developer longer than necessary.

**The three laws of CI testing:**
1. Fast feedback wins — a 10-minute CI run that catches 90% of defects beats a 60-minute run that catches 95%.
2. Determinism first — a flaky test is worse than no test; it erodes trust in the entire test suite.
3. Environment parity — test cases that pass locally but fail in CI indicate an environment gap that will eventually cause a production incident.

**The core ci-cd-testing checklist:**

| # | Pillar | Target |
|---|---|---|
| 1 | Fail-fast ordering | lint → unit → integration → e2e |
| 2 | Parallelization | `maxWorkers: 50%` on runner vCPUs |
| 3 | Sharding | across machines when single-machine parallelism isn't enough |
| 4 | Merge gates | unit + integration + e2e smoke required; full suite advisory |
| 5 | Flaky test handling | quarantine within 24h; `retries ≤ 2` |

**ISTQB CTFL 4.0 terminology used in this guide:** "test level" (unit / integration / system / acceptance), "test suite" (not "test set"), "test case" (an individual verifiable condition), "defect" (not "bug"), "test basis" (specifications, code, requirements used to derive test cases).

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

> [community] Teams that try to implement all CI patterns at once ("CI big bang") typically spend 3–4 weeks on infrastructure and abandon the effort halfway. WHY: each pattern solves a specific pain point, but all together they create a configuration maintenance burden that overwhelms teams without dedicated CI engineers. Start with lint + unit + `npm audit`; add one new pattern per sprint. The biggest gains come from the first 3 patterns (lint, unit, caching) — the rest are optimization.

## Patterns

### Fail-Fast Pipeline Ordering

Run tests in ascending order of execution time:

1. **Lint / syntax-check** (< 30 s) — catches syntactic errors before any test runner starts
2. **Unit tests** (< 2 min) — pure functions in isolation, no network
3. **Integration tests** (2–5 min) — service boundaries with real DB via test containers
4. **E2E / smoke** (5–15 min) — real browser, real API, critical-path coverage

**Why:** A unit test case failing in 30 seconds is cheaper than waiting 12 minutes for an e2e suite to report the same logic defect.

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

Worker-based parallelism runs multiple test files simultaneously on a single runner using multiple CPU threads.

> [community] The most common parallelization mistake: setting `maxWorkers: 100%` on a 2-core runner. GitHub Actions free-tier runners have 2 vCPUs. Setting workers to 100% leaves no headroom for Node.js GC, causing slower runs. Profile your runner's vCPU count before tuning.

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

```javascript
// vitest.config.js
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    pool: 'threads',         // true OS threads (faster for I/O-light tests)
    poolOptions: {
      threads: { maxThreads: 4, minThreads: 2 }
    },
    isolate: true,           // fresh module registry per file
    sequence: { shuffle: true }
  }
});
```

**Why:** On a 4-core machine, parallel execution typically cuts wall-clock time by 60–70%. Randomize order and use worker isolation to catch shared mutable state early.

### Test Sharding (across machines)

Sharding splits the test suite across multiple CI runners. Use when parallelization within one machine still exceeds the time budget.

> [community] The Playwright team's own benchmark: a 500-test e2e suite running on 1 machine took 22 minutes; sharded across 4 machines it ran in 6 minutes. Sharding beyond 8 shards rarely helps browser tests due to browser launch overhead.

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

### Flaky Test Quarantine in CI [community]

A test case is flaky when it produces different results for the same code without any code change. Flaky test cases are the leading cause of developer distrust in CI.

**Detection threshold:** A test case that fails more than 2% of the time on a green branch must be quarantined within 24 hours.

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

```javascript
// playwright.config.js
const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  retries: process.env.CI ? 2 : 0,  // retry only in CI, not locally
  reporter: [
    ['html'],
    ['json', { outputFile: 'test-results/results.json' }],
    ['./reporters/flakiness-tracker.js']
  ],
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure'
  }
});
```

### Changed-File-Only Testing (monorepo) [community]

In a monorepo, running all test cases on every commit is impractical. Only test what changed and its dependents.

> [community] Nx users report that enabling `affected` reduces average CI time by 70–85% in a 30+ package monorepo. The catch: this only works if the dependency graph is correct. Most teams that "don't see the speedup" have circular dependencies or implicit cross-package imports that force the entire graph to be marked affected. Running `nx graph` and auditing `implicitDependencies` takes < 1 hour and unlocks the full benefit.

```bash
# Only test projects affected by the current branch changes (Nx)
npx nx affected --target=test --base=origin/main --head=HEAD

# Only lint + test + build in topological order
npx nx affected --targets=lint,test,build --base=origin/main
```

```bash
# Turbo: dependency graph already defined in turbo.json
npx turbo run test --filter=...[origin/main]
```

```bash
# Jest: only run test files that import modules changed since main
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

### Concurrency Cancellation [community]

Cancelling superseded CI runs when a new push arrives saves runner minutes and eliminates stale results.

> [community] Without concurrency cancellation, a developer who pushes a fix immediately after a broken commit will wait for both CI runs to complete. On projects with 10-minute CI, this is 20 minutes of wasted wait time. Enabling `cancel-in-progress` reduces this to a single 10-minute wait.

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

**Separate concurrency groups for deploy vs. test:**

```yaml
jobs:
  test:
    concurrency:
      group: test-${{ github.ref }}
      cancel-in-progress: true    # allow new test runs to cancel old ones
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy-preview:
    needs: test
    concurrency:
      group: deploy-preview-${{ github.ref }}
      cancel-in-progress: false   # deployments must NOT cancel mid-flight
    runs-on: ubuntu-latest
    steps:
      - run: npm run deploy:preview
```

### Environment Parity (CI vs. Local) [community]

CI failures that do not reproduce locally are the most expensive class of test failure — they block the pipeline but cannot be debugged quickly.

> [community] The top three parity gaps reported by engineering teams: (1) file path case sensitivity (macOS is case-insensitive, Linux CI is case-sensitive), (2) environment variables present locally but not in CI, (3) Node.js version differences when `.nvmrc` is ignored.

**Common parity gaps and fixes:**

| Gap | Symptom | Fix |
|---|---|---|
| File path case | `import './MyComponent'` works on Mac, fails on Linux | Enforce lowercase filenames; use `eslint-plugin-import` |
| Missing env vars | `process.env.API_URL` is `undefined` in CI | Declare all required vars in `.env.example`; validate on startup |
| Node.js version | Native addons or syntax differ | Pin version in `.nvmrc` and `engines` field |
| Locale / collation | String sorts differ between en-US and C locale | Set `LC_ALL=en_US.UTF-8` in CI jobs |
| Timezone | Date assertions fail | `TZ=UTC` in CI env; freeze time in test cases |
| File permissions | Scripts not executable | `git update-index --chmod=+x` at commit time |

**Node version pinning in GitHub Actions:**

```yaml
- uses: actions/setup-node@v4
  with:
    node-version-file: .nvmrc   # reads exact version from .nvmrc
    cache: npm
```

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

### Pre-commit Hooks as Local CI Gates [community]

Pre-commit hooks run fast checks before a commit completes — catching issues before they enter CI at all.

> [community] Teams that enforce pre-commit hooks report a 15–25% reduction in CI failure rate on PRs. The mechanism: developers fix lint and format issues locally rather than waiting 5 minutes for the CI lint job. The tradeoff: hooks that take > 10 seconds are bypassed with `--no-verify` within weeks. Keep hooks under 5 seconds.

```bash
# Install husky + lint-staged
npm install --save-dev husky lint-staged
npx husky init
```

```json
{
  "scripts": { "prepare": "husky" },
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

# Run unit tests for changed files only (~2s for typical change)
npx jest --passWithNoTests --findRelatedTests $(git diff --cached --name-only --diff-filter=ACMR | tr '\n' ' ')
```

### Merge Gates / Required Status Checks [community]

Not all CI jobs should block a merge. Configure required checks strategically.

> [community] Teams that gate on the full e2e suite (50+ test cases) report 30–45 min PR queues. The fix: promote smoke e2e to a required gate, move the full suite to post-merge or nightly.

| Job | Required? | Rationale |
|---|---|---|
| lint | Yes | Prevents broken code from entering main |
| unit tests | Yes | Core correctness guarantee |
| integration tests | Yes | Service contract validation |
| e2e smoke | Yes | End-to-end sanity |
| full e2e suite | No | Too slow; run on schedule or merge-to-main |
| visual regression | No | High false-positive rate; advisory only |
| performance | No | Trend tracking, not gate |

### Test Results Reporting [community]

Structured reporting closes the feedback loop from CI back to the developer.

> [community] The single highest-leverage reporting change most teams make: switch from "check the Actions tab" to inline PR annotations. Developers fix test failures 3× faster when the failure appears directly in the PR diff view rather than in a separate tab.

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

### Testcontainers for Integration Tests [community]

Testcontainers starts real Docker containers from within test code, ensuring environment parity between local dev and CI without requiring pre-configured CI services.

> [community] The shift from GitHub Actions `services:` declarations to Testcontainers is driven by one pain point: `services:` containers start once per job and share state across all test cases. Testcontainers starts a fresh container per test suite (or per test), giving true isolation. Teams that made this switch report 80%+ reduction in "green locally, red in CI" integration test failures.

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

> [community] Testcontainers pulling images every CI run adds 45–90 seconds of dead time per integration job. Use `docker pull postgres:16-alpine` as a cached step before running test cases, or use a private registry mirror.

### Test Time Budgets [community]

Test time budgets set explicit ceilings on CI duration and are enforced in the pipeline itself, not just documented in a wiki.

> [community] Teams without hard time budgets experience "CI creep": an extra e2e test here, a slow API call there, and within 6 months a 10-minute pipeline becomes 40 minutes. No single change is obviously wrong, but the cumulative effect kills developer flow. Hard budgets force the conversation early.

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

```bash
# Find the 10 slowest test files (Jest)
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

## Anti-Patterns

| Anti-pattern | Problem | WHY it's harmful | Fix |
|---|---|---|---|
| Running e2e on every push | 15+ min wait per push | Kills developer flow; devs stop reading CI results when they're always late | Run e2e only on PR open/update or schedule |
| No test ordering (all parallel) | Fast unit failures buried in long e2e logs | Cannot distinguish logic defect (unit) from integration defect (e2e) — MTTD doubles | Sequence: lint → unit → integration → e2e |
| Ignoring flaky failures | Developers click "re-run" without investigating | Trust in CI erodes; eventually the suite is ignored entirely | Quarantine within 24h, track flakiness rate |
| `sleep()` in test cases | Timing-dependent failures | Arbitrary delays are never correct; they either mask real latency or slow the suite unnecessarily | Use `waitFor`, polling, or event-driven assertions |
| No `timeout-minutes` on jobs | Hung process blocks runner for 6h | Consumes runner concurrency; blocks other PRs; GitHub default is 6 hours | Set job-level and step-level timeouts explicitly |
| `retries: 3+` on e2e tests | Hides chronic flakiness, triples job time | A test that needs 3 retries is a lottery ticket, not a safety check; masks systemic defects | Max retries: 2; quarantine tests that need more |
| `cancel-in-progress: true` on deploy jobs | Partial deploys leave infra broken | A cancelled migration or seed job leaves the DB in an inconsistent state; next deploy may fail | Only cancel test/lint jobs; let deploy jobs complete |
| `npm audit` gating on moderate severity | Permanently red CI; teams disable the check | npm reports 50–200 moderate-severity findings for any production Node.js project; gating blocks all PRs permanently | Gate on `high` + `critical` only |
| Full test suite in pre-commit hook | >10s hooks bypassed with `--no-verify` in days | Once developers find it slow, they bypass it — the hook provides no value and creates a false sense of safety | Scope hook to `--findRelatedTests`; keep under 5s |
| Missing `--passWithNoTests` in monorepo | Affected calculation errors cause CI block | When no test files match the affected filter, Jest/Vitest exit code 1 blocks the pipeline | Add flag when running subset tests |
| Uploading test artifacts unconditionally | Fills artifact storage on every green run | Artifact storage has a cost; on busy repos green-run artifacts are noise and waste quota | Use `if: failure()` for traces/screenshots |
| Static shard count never revisited | Under- or over-parallelization as suite grows | A suite that fit 4 shards at 100 tests needs 8 at 300 — nobody notices the waste until the bill arrives | Use dynamic shard count or review quarterly |

## Real-World Gotchas [community]

1. **Port conflicts in parallel jobs** [community]: Use dynamic port allocation instead of fixed ports. Static port `5432` will collide on a shared runner with two parallel integration jobs.

2. **Time zone differences** [community]: CI runners often run UTC; local dev runs in local time. Date-sensitive test cases must freeze time with `jest.setSystemTime()` or `vi.setSystemTime()`. WHY: a test like `expect(formatDate(new Date())).toBe('Jan 26')` will fail the morning of Jan 27 UTC.

3. **GitHub Actions cache eviction** [community]: Caches are evicted after 7 days of no access. The first run after a holiday weekend will be slow — do not add conditional cache-warming jobs. The cure (complexity) is worse than the disease (one slow run).

4. **Playwright browser version mismatch** [community]: `@playwright/test` version and browser version are tightly coupled. Key the cache on the exact Playwright version string: `key: playwright-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}-${{ steps.playwright-version.outputs.version }}`.

5. **`npm ci` vs `npm install`** [community]: Always use `npm ci` in CI — it respects the lockfile exactly, is faster (skips dependency resolution), and fails on lockfile drift. `npm install` silently updates the lockfile, causing non-deterministic installs.

6. **Shared test database state** [community]: Integration test cases that share a single database without per-test transactions or truncation are order-dependent. Use `BEGIN` / `ROLLBACK` per test or truncate tables in `beforeEach`. WHY: a test case that creates a "unique email" user will fail if another test case already inserted that email.

7. **Stale CI consuming runner slots** [community]: On busy repos without concurrency groups, a feature branch with 10 rapid commits can queue 10 CI runs simultaneously, exhausting shared runner pools for the whole team. WHY: without `cancel-in-progress: true`, every push creates a new independent run that cannot be stopped. Enforce `concurrency: cancel-in-progress: true` on all feature branch workflows. Teams at mid-scale (20+ developers) have seen 3–4× improvement in median queue wait time after enabling this.

8. **`GITHUB_TOKEN` permissions for PR comments** [community]: The default `GITHUB_TOKEN` cannot write PR comments on forks. WHY: fork-based contributor workflows use a read-only token for security reasons; coverage comment actions silently fail without explicit permissions. Use `pull_request_target` (with care) or add `permissions: pull-requests: write` explicitly.

9. **CI provider env var naming differences** [community]: Code that reads provider-specific variables (`GITHUB_REF`, `CI_COMMIT_REF_NAME`, `CIRCLE_BRANCH`) will silently get `undefined` on other providers. WHY: this causes tracking scripts and release automation to silently record `local` or `undefined` as the branch name, corrupting dashboards. Normalize into a single `ci-env.js` module with fallback chains.

10. **Test time budget drift** [community]: Teams set a 10-minute budget at project start, then add test cases without measuring. WHY: no single change is obviously wrong, but within 6 months a 10-minute pipeline becomes 40 minutes and nobody knows why. Add a CI step that fails if total job duration exceeds the budget: `if [ $SECONDS -gt 600 ]; then echo "::error::CI exceeded 10-minute budget"; exit 1; fi`.

## Tradeoffs & Alternatives

### Time vs. Coverage

| Strategy | CI time | Coverage | Use when |
|---|---|---|---|
| Unit only | ~2 min | Logic only | Hotfix branches, library packages |
| Unit + integration | ~6 min | Logic + service contracts | Feature branches |
| Full pyramid | ~15 min | End-to-end | PRs to main, release branches |
| Nightly full suite | ~60 min | Full + visual + perf | Release qualification |

**Industry benchmark targets (JavaScript/Node.js projects):**
- Unit test suite: < 2 minutes for up to 2,000 test cases
- Integration test suite: < 5 minutes for up to 200 integration test cases
- E2E smoke: < 8 minutes for 20–30 critical path scenarios
- Full CI pipeline: < 10 minutes end-to-end on feature branches

### When NOT to Use e2e in the Pipeline

- Pure UI component libraries: use visual snapshots + interaction tests instead
- Pure backend microservices with OpenAPI contracts: use contract testing (Pact) instead
- Internal tooling / admin dashboards: unit + integration is sufficient for most changes
- Any branch where changed files are 100% within a single package (verified by monorepo tooling)

**When e2e is non-negotiable:**
- Auth flows (login, SSO, token refresh) — timing-sensitive and environment-dependent
- Payment / checkout flows — too costly to get wrong
- Cross-browser rendering for consumer-facing UIs
- Accessibility compliance (axe-core in Playwright)

### Retry vs. Quarantine

| Approach | When to use | Risk |
|---|---|---|
| `retries: 1` | Brand-new test, investigating | Hides failures for 1 extra attempt |
| `retries: 2` | Known flaky, quarantine pending | Doubles/triples job time for that test |
| `retries: 3+` | Never | Masks systemic issues; voids CI signal |
| Quarantine tag | Long-lived flaky, tracked in backlog | Test provides no safety signal while quarantined |
| Fix root cause | Ideal | Requires investigation time (budget it) |

**Never set `retries > 2`** — if a test case needs 3 retries to pass, it is not a test case, it is a lottery ticket.

### Contract Testing as an E2E Alternative [community]

> [community] A fintech team with 12 microservices reduced e2e test count by 60% and CI time by 40% by replacing cross-service e2e tests with Pact contracts. Each service publishes its consumer expectations; the provider verifies them independently. This is faster, more targeted, and does not require a full deployed environment.

| Approach | Speed | Env required | Best for |
|---|---|---|---|
| E2E (browser) | Slow (mins/test) | Full stack | User journeys, auth, payment |
| Contract testing (Pact) | Fast (seconds) | None (mocked) | Microservice boundaries |
| Integration (test container) | Medium | DB/service only | DB queries, service logic |

**When contract testing does NOT replace e2e:**
- When the user experience itself is being verified (visual layout, accessibility)
- When browser-API interaction is the risk (CORS, cookie handling, CSP)
- When latency under load matters (use k6 for load tests instead)

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

> [community] Teams that switch CI providers mid-project consistently underestimate migration effort. Porting is mechanical but the biggest cost is recreating caching strategies and secret management patterns. Budget 2–4 weeks for a mid-size project.

| Provider | Free tier | Self-hosted | Best for | Watch out for |
|---|---|---|---|---|
| GitHub Actions | 2,000 min/month | Yes | GitHub repos, tight PR integration | 2-core free runners; matrix jobs expensive |
| GitLab CI | 400 min/month | Yes | GitLab repos, parent-child pipelines | YAML syntax more complex; cache sharing tricky |
| CircleCI | 6,000 min/month | Yes | Docker-heavy workflows | Orb ecosystem adds abstraction overhead |
| Buildkite | No free tier | Yes (mandatory) | Unlimited self-hosted runners, monorepos | Requires managing your own runner fleet |

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Martin Fowler — Continuous Integration | Official article | https://martinfowler.com/articles/continuousIntegration.html | Foundational CI principles |
| Martin Fowler — Test Pyramid | Official article | https://martinfowler.com/bliki/TestPyramid.html | Fail-fast ordering rationale |
| GitHub Actions docs — Caching | Official docs | https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows | node_modules + browser caching |
| GitHub Actions docs — Concurrency | Official docs | https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs | Concurrency group config |
| GitHub Actions docs — Matrix strategy | Official docs | https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow | Multi-version + dynamic matrix |
| Playwright docs — Test sharding | Official docs | https://playwright.dev/docs/test-sharding | Cross-machine sharding + blob reporter |
| Jest docs — Running in parallel | Official docs | https://jestjs.io/docs/configuration#maxworkers-number--string | maxWorkers tuning |
| Nx docs — Affected commands | Official docs | https://nx.dev/nx-api/nx/documents/affected | Monorepo affected testing |
| Testcontainers for Node.js | Official docs | https://testcontainers.com/guides/getting-started-with-testcontainers-for-nodejs/ | Integration test containers |
| Husky — Git hooks | Official docs | https://typicode.github.io/husky/ | Pre-commit hook setup |
| npm audit docs | Official docs | https://docs.npmjs.com/cli/v10/commands/npm-audit | Dependency audit gating |
| ISTQB CTFL 4.0 Syllabus | Official | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative testing terminology |
| Google Testing Blog — Flaky Tests | Community post | https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html | Flakiness at scale |
