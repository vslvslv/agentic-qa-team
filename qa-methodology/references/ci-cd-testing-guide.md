# CI/CD Testing Strategy — QA Methodology Guide
<!-- lang: TypeScript | topic: ci-cd-testing | iteration: 8 | score: 100/100 | date: 2026-04-26 -->

## Core Principles

CI/CD pipelines are only as good as the test suites they run. The goal is maximum confidence at minimum latency: catch bugs early, report clearly, and never block a developer for longer than necessary. These principles apply whether you run a single-repo React app or a 200-package monorepo.

**The three laws of CI testing:**
1. Fast feedback wins — a 10-minute CI run that catches 90% of bugs beats a 60-minute run that catches 95%.
2. Determinism first — a flaky test is worse than no test; it erodes trust in the entire suite.
3. Environment parity — tests that pass locally but fail in CI (or vice versa) indicate an environment gap that will eventually cause a production incident.

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

## Patterns

### Fail-Fast Pipeline Ordering

Run tests in ascending order of execution time and ascending order of setup complexity:

1. **Lint / type-check** (< 30 s) — catches syntactic errors before any test runner starts
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
      - run: npm run type-check

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

**Jest configuration:**

```javascript
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
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

export default config;
```

**Vitest configuration:**

```typescript
// vitest.config.ts
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

**Quarantine approach — Jest custom reporter:**

```typescript
// scripts/quarantine-reporter.ts
import type { Reporter, TestResult } from '@jest/reporters';

const QUARANTINED = new Set([
  'UserAuthFlow > should refresh token silently',
  'PaymentForm > submits on Enter key',
]);

class QuarantineReporter implements Reporter {
  onTestResult(_: unknown, result: TestResult) {
    result.testResults = result.testResults.map(t => {
      if (QUARANTINED.has(`${t.ancestorTitles.join(' > ')} > ${t.title}`)) {
        if (t.status === 'failed') {
          console.warn(`[QUARANTINE] Skipping known-flaky: ${t.title}`);
          return { ...t, status: 'pending' };  // treat as skip, not failure
        }
      }
      return t;
    });
  }
}

module.exports = QuarantineReporter;
```

**Retry with flakiness tracking (Playwright):**

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  retries: process.env.CI ? 2 : 0,  // retry only in CI, not locally
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
    video: 'retain-on-failure'
  }
});
```

**Flakiness rate formula:** `flakiness_rate = retry_successes / total_runs`. Alert when rate > 5% over a 7-day rolling window.

**Flaky test audit script (bash, runs against JSON results):**

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

FLAKY=$(node -e "
const r = require('$RESULTS_FILE');
const flaky = [];
for (const suite of r.suites || []) {
  for (const spec of suite.specs || []) {
    for (const test of spec.tests || []) {
      const retries = test.results.filter(r => r.retry > 0).length;
      if (retries > 0) {
        flaky.push({ title: spec.title, file: spec.file, retries });
      }
    }
  }
}
if (flaky.length > 0) {
  console.table(flaky);
  process.exit(1);
} else {
  console.log('No flaky tests detected.');
}
")

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
npm run type-check
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
| Lint + type-check | < 60 s | CI step timeout |
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

## Tradeoffs & Alternatives

### Time vs. Coverage

| Strategy | CI time | Coverage | Use when |
|---|---|---|---|
| Unit only | ~2 min | Logic only | Hotfix branches, library packages |
| Unit + integration | ~6 min | Logic + service contracts | Feature branches |
| Full pyramid | ~15 min | End-to-end | PRs to main, release branches |
| Nightly full suite | ~60 min | Full + visual + perf | Release qualification |

**Industry benchmark targets (TypeScript/Node.js projects):**
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

## Key Resources

- Martin Fowler — Continuous Integration: https://martinfowler.com/articles/continuousIntegration.html
- Martin Fowler — Test Pyramid: https://martinfowler.com/bliki/TestPyramid.html
- GitHub Actions docs — Caching dependencies: https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows
- Playwright docs — Test sharding: https://playwright.dev/docs/test-sharding
- Jest docs — Running in parallel: https://jestjs.io/docs/configuration#maxworkers-number--string
- Nx docs — Affected commands: https://nx.dev/nx-api/nx/documents/affected
- Google Testing Blog — Flaky Tests: https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html
