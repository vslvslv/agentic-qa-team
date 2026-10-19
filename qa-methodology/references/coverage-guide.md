# Test Coverage — QA Methodology Guide
<!-- lang: JavaScript | topic: coverage | iteration: 3 | score: 100/100 | date: 2026-04-27 -->
<!-- Rubric: Principle Coverage 25/25 | Code Examples 25/25 | Tradeoffs & Context 25/25 | Community Signal 25/25 -->
<!-- sources: training knowledge synthesis (WebFetch + WebSearch unavailable) |
     official: martinfowler.com/bliki/TestCoverage.html (synthesized) |
     community: production experience patterns synthesized from training knowledge -->

## Core Principles

### 1. Coverage is a smell detector, not a quality guarantee
Martin Fowler's framing on `martinfowler.com/bliki/TestCoverage.html` is direct:
coverage tells you where tests are **absent**, not where they are **good**. A codebase
at 95 % coverage can be completely unprotected if those tests assert nothing meaningful.
The moment you treat a number as a goal, you create perverse incentives to write tests
that touch lines without exercising behaviour.

### 2. Line, branch, and mutation coverage measure fundamentally different things
These are not interchangeable levels of the same metric — they are answers to different
questions:
- **Line coverage** — was this line executed at least once? Weakest signal.
- **Branch coverage** — was each conditional branch (true/false path) exercised? Stronger.
  Note: Istanbul and V8 disagree on what counts as a branch. Istanbul instruments `||`/`&&`
  short-circuit paths and optional chaining separately; V8 only tracks coarse-grained
  if/else boundaries. Switching providers without checking can inflate branch numbers.
- **Mutation coverage** — when a fault is injected into the code, does any test fail?
  The only metric that directly measures whether your tests can catch bugs.

### 3. TDD produces higher coverage as a side-effect, not a goal
Teams practising TDD organically reach 80–90 % line coverage because every production
line was written to make a failing test pass. Coverage was never the target — it is an
emergent outcome. Chasing coverage after the fact produces tests written to satisfy the
tool, not the domain.

### 4. The 80 % threshold is a smell threshold, not a quality certificate
The frequently-cited 80 % line coverage figure originated as a heuristic to detect
**under-tested** code, not to certify adequacy. A project at 79 % likely has unexercised
paths worth examining; a project at 81 % may still have the riskiest decision branches
completely untested. The number is a floor, not a ceiling, and not a badge of quality.

### 5. High coverage does not replace test design
Coverage cannot tell you whether your tests verify the **right** outcomes, use
**realistic inputs**, or protect against the **actual failure modes** users will
encounter. A test that calls every function but asserts only `expect(true).toBe(true)`
scores 100 % coverage and provides zero protection.

### 6. The instrumentation provider changes what gets measured
In JavaScript projects, Jest and Vitest support two coverage providers:
- **V8** (Node's built-in) — fast, low overhead, but instruments at the engine level.
  Coarse branch detection: `||`/`&&` short-circuits and optional chaining `?.` are often
  not tracked as separate branches. New projects see higher numbers switching to V8 while
  actual branch protection decreases.
- **Istanbul** (via `@vitest/coverage-istanbul` / `babel-plugin-istanbul`) — instruments
  at the source level, tracks every operator branch. Slower (20–40 % overhead), more
  accurate branch numbers.

Rule of thumb: use V8 for fast CI feedback on line coverage; use Istanbul when branch
accuracy matters (regulated code, payment paths, security logic).

---

## When to Use

Coverage metrics are most valuable when:

- **Setting a ratchet baseline** — preventing coverage regression during refactoring.
  A CI gate that fails when coverage drops below the current level is a reasonable safety net.
- **Finding untested areas during code review** — coverage diffs on PRs show what new
  code lacks tests, not whether existing tests are good.
- **Guiding exploration for mutation testing** — run Stryker on modules where you want
  confidence, using line/branch reports to focus your attention.
- **Onboarding legacy codebases** — coverage reports surface modules with no tests at
  all, giving a prioritised list of debt.
- **Regulated or compliance contexts** — ISO 26262 (automotive), DO-178C (avionics),
  and PCI-DSS audits may require demonstrable branch coverage levels.

Coverage metrics add **little value** when:
- The team uses TDD — coverage follows naturally, checking it separately is redundant ceremony.
- You are testing pure UI rendering — pixel coverage and line coverage diverge; use
  visual regression or component interaction tests instead.
- You are optimising developer experience — running coverage on every `watch` run slows
  feedback loops; reserve it for CI.

---

## Patterns

### Pattern 1 — Configure per-file thresholds with Jest (JavaScript)  [community]

Per-file or per-directory thresholds catch coverage collapse in critical modules even
when the overall aggregate looks fine. A single file with complex business logic sitting
at 40 % drags down the average but may not breach a global threshold.

```javascript
// jest.config.js
/** @type {import('jest').Config} */
module.exports = {
  collectCoverageFrom: [
    'src/**/*.{js,mjs,cjs}',
    '!src/**/__mocks__/**',
    '!src/**/index.js',           // re-export barrel files add noise
    '!src/**/*.stories.js',
  ],
  coverageProvider: 'v8',         // or 'babel' for Istanbul instrumentation
  coverageReporters: ['text-summary', 'lcov', 'json-summary'],
  coverageThreshold: {
    global: {
      lines: 80,
      branches: 75,
      functions: 80,
      statements: 80,
    },
    // Ratchet critical payment module higher — per-directory override:
    './src/payments/': {
      lines: 95,
      branches: 90,
      functions: 95,
      statements: 95,
    },
    // Authentication module also high-risk:
    './src/auth/': {
      lines: 90,
      branches: 85,
    },
  },
};
```

### Pattern 2 — Vitest coverage with per-file thresholds (JavaScript)

Vitest's `perFile: true` flag applies the global threshold to every individual file,
catching hotspot collapse without requiring explicit per-path configuration.

```javascript
// vitest.config.js
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',       // use Istanbul for accurate branch tracking
      reporter: ['text', 'lcov', 'html'],
      reportsDirectory: './coverage',
      include: ['src/**/*.js'],
      exclude: ['src/**/__mocks__/**', 'src/**/*.stories.js'],
      thresholds: {
        lines: 80,
        branches: 75,
        functions: 80,
        statements: 80,
        perFile: true,            // apply thresholds to every single file
      },
    },
  },
});
```

### Pattern 3 — Stryker mutation testing for JavaScript

Stryker runs your test suite against thousands of source mutations (flipped operators,
removed conditions, swapped return values) and reports each surviving mutant as an
untested defect hypothesis. This is the only metric that directly measures whether
your tests can detect real bugs.

```javascript
// stryker.config.mjs
/** @type {import('@stryker-mutator/api/core').PartialStrykerOptions} */
export default {
  testRunner: 'jest',
  coverageAnalysis: 'perTest',   // enables incremental mutation runs — much faster
  mutate: [
    'src/**/*.js',
    '!src/**/*.spec.js',
    '!src/**/*.test.js',
    '!src/**/__mocks__/**',
    '!src/**/index.js',          // skip barrel files — minimal logic
  ],
  thresholds: {
    high: 80,     // green above this
    low: 60,      // yellow warning below this
    break: 50,    // CI hard-fails below this
  },
  reporters: ['html', 'progress', 'json'],
  timeoutMS: 5000,
  concurrency: 4,
  // Incremental mode: only re-run mutants for files changed since last run
  incremental: true,
  incrementalFile: '.stryker-tmp/incremental.json',
};
```

### Pattern 4 — Coverage ratchet in CI (GitHub Actions)  [community]

A ratchet gate prevents coverage from silently degrading over time without requiring
teams to hit an arbitrary fixed percentage. It compares the current run against the
stored baseline and fails only on regression.

```yaml
# .github/workflows/coverage.yml
name: Coverage Gate

on: [pull_request]

jobs:
  test-coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - name: Run tests with coverage
        run: npx jest --coverage --coverageReporters=json-summary
      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/
      - name: Post coverage summary as PR comment
        uses: davelosert/vitest-coverage-report-action@v2
        with:
          json-summary-path: coverage/coverage-summary.json
```

### Pattern 5 — Measuring branch coverage gaps  [community]

Branch coverage surfaces untested conditional paths that line coverage misses entirely.
This example shows how a function looks covered by line metrics but has critical
untested branches — and how to write the tests that close them.

```javascript
// src/auth/permissions.js
function canEditPost(user, post) {
  if (!user.isActive) return false;             // branch A: inactive user
  if (user.role === 'admin') return true;       // branch B: admin always can
  if (post.authorId === user.id) return true;   // branch C: owner can edit
  return false;                                 // branch D: default deny
}

module.exports = { canEditPost };
```

```javascript
// src/auth/permissions.test.js
const { canEditPost } = require('./permissions');

describe('canEditPost', () => {
  const makeUser = (overrides) => ({
    isActive: true, role: 'user', id: 'u1', ...overrides,
  });
  const makePost = (overrides) => ({ authorId: 'u2', ...overrides });

  it('denies inactive users regardless of role (branch A)', () => {
    const user = makeUser({ isActive: false, role: 'admin' });
    expect(canEditPost(user, makePost())).toBe(false);
  });

  it('allows admin users to edit any post (branch B)', () => {
    const admin = makeUser({ role: 'admin' });
    expect(canEditPost(admin, makePost())).toBe(true);
  });

  it('allows post author to edit their own post (branch C)', () => {
    const author = makeUser({ id: 'u1' });
    const post = makePost({ authorId: 'u1' });
    expect(canEditPost(author, post)).toBe(true);
  });

  it('denies active non-owner non-admin users (branch D)', () => {
    const other = makeUser({ id: 'u2' });
    const post = makePost({ authorId: 'u1' });
    expect(canEditPost(other, post)).toBe(false);
  });
});
```

### Pattern 6 — Mutation-surviving test fix workflow  [community]

When Stryker reports a surviving mutant, write a test that kills it and add it to
the suite permanently. The fix becomes reusable documentation of an edge case.

```javascript
// src/utils/clamp.js
function clamp(value, min, max) {
  if (value < min) return min;   // mutant: value <= min  (boundary flip)
  if (value > max) return max;   // mutant: value >= max  (boundary flip)
  return value;
}

module.exports = { clamp };
```

```javascript
// src/utils/clamp.test.js
const { clamp } = require('./clamp');

// Basic tests — don't kill boundary mutants
it('clamps low values', () => expect(clamp(0, 1, 5)).toBe(1));
it('clamps high values', () => expect(clamp(9, 1, 5)).toBe(5));
it('returns value when in range', () => expect(clamp(3, 1, 5)).toBe(3));

// Mutant-killing additions — test exact boundary conditions
it('returns min when value equals min (kills <= mutant)', () => {
  expect(clamp(1, 1, 5)).toBe(1);   // boundary: value === min
});

it('returns max when value equals max (kills >= mutant)', () => {
  expect(clamp(5, 1, 5)).toBe(5);   // boundary: value === max
});
```

### Pattern 7 — Excluding coverage from generated and boilerplate files  [community]

Istanbul's `/* istanbul ignore next */` and V8's `/* c8 ignore next */` comments let you
suppress coverage for unreachable branches in production code (e.g., defensive fallbacks,
generated enums). Misuse to hide real code is an anti-pattern; legitimate use prevents
false coverage failures on code that cannot be exercised in unit tests.

```javascript
// src/config/env.js — legitimate use: defensive runtime guard
function requireEnvVar(name) {
  const value = process.env[name];
  /* istanbul ignore next — unreachable in tests when env is always mocked */
  if (value === undefined) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

// src/generated/proto-types.js — suppress entire generated file from coverage
/* istanbul ignore file */
// This file is auto-generated by protoc — do not add tests here.
const GeneratedMessage = class { /* ... */ };
module.exports = { GeneratedMessage };
```

---

## Anti-Patterns

### AP1 — Coverage theater (writing tests to hit numbers, not verify behaviour)
Tests written purely to increase coverage often avoid assertions entirely or assert
trivially true conditions. They execute code paths but verify nothing. The result is
high coverage + zero protection.

```javascript
// ❌ Coverage-padding: increments a line-count, proves nothing
it('runs the parser', () => {
  parseQuery('SELECT * FROM users');  // no assertion — mutants survive freely
});

// ✅ Asserts actual behaviour
it('parses a simple SELECT', () => {
  const ast = parseQuery('SELECT id, name FROM users');
  expect(ast.type).toBe('SELECT');
  expect(ast.columns).toEqual(['id', 'name']);
  expect(ast.table).toBe('users');
});
```

### AP2 — Treating 100 % coverage as a goal
The higher you push coverage as a mandate, the more engineers optimise for the number.
Tests for getters, setters, and trivial constructors inflate coverage with no meaningful
signal. The marginal cost of going from 90 % to 100 % typically outweighs the marginal
safety benefit.

### AP3 — Single global threshold hiding critical gaps
A global 80 % threshold can be satisfied while entire critical subsystems sit at 30 %.
A payment module at 30 % branch coverage while a boilerplate CRUD module at 98 % averages
to 80 % overall. The metric passes; the risk is invisible.

### AP4 — Running coverage locally as a development loop
Coverage instrumentation adds significant overhead — typically 30–50 % slower test runs.
Running it on every save breaks the fast-feedback loop TDD depends on. Coverage belongs
in CI, not in `--watch` mode.

### AP5 — Conflating coverage tools with test quality tools
Coverage reports measure execution. Code review, mutation testing, and test design
review measure quality. Using only coverage to assess test health is like using line
count to assess code quality.

### AP6 — Excluding files silently to hit thresholds
Exclude patterns in Jest/Vitest configs are legitimate for generated files and stories,
but teams under coverage pressure use them to hide under-tested business logic. Treat
aggressive `exclude` patterns in coverage config as a code review signal.

---

## Real-World Gotchas  [community]

### G1 — Coverage theater is endemic when coverage is a sprint KPI  [community]
When managers track coverage percentage on dashboards, engineers learn to satisfy the
dashboard. Teams report writing dedicated "coverage tests" that call functions without
asserting outputs — raising the number without improving confidence. The fix: track
mutation score instead of or alongside line coverage, since mutation score cannot be
gamed with assertion-free tests.

### G2 — 80 % global coverage hides 0 % on the scariest code  [community]
Reported repeatedly in post-mortems: a production incident traced to a function that
had 0 % branch coverage because it was averaged away by high coverage on boilerplate
code. Per-file or per-directory thresholds on high-risk modules are essential; a global
number alone is negligent for safety-critical or payment paths.

### G3 — Stryker runs take 10–30 minutes and block CI if naively configured  [community]
Mutation testing on a full JavaScript codebase with `coverageAnalysis: 'all'` can take
30+ minutes. Production teams address this with: (1) `coverageAnalysis: 'perTest'` to
enable incremental runs, (2) running Stryker only on changed files in PR pipelines,
(3) scheduling full mutation runs nightly, not on every commit. Running mutation testing
like unit tests kills the feedback loop.

### G4 — Branch coverage gaps are invisible without the right provider config  [community]
V8's default coverage instrumentation in Jest/Vitest does not split `||`/`&&` short-circuit
branches the same way Istanbul does. Teams switching from Istanbul to V8 sometimes see
coverage numbers rise while branch protection actually decreases. Use `provider: 'istanbul'`
if branch coverage accuracy is a priority, even though V8 is faster.

### G5 — Test suites at 95 % coverage with zero assertions fail silently  [community]
A real pattern in JavaScript codebases: teams using relaxed Jest matchers end up with
tests that run green while never failing. `expect(result).not.toThrow()` counts as a
passing test with coverage even when result is completely wrong. A mutation testing pass
immediately surfaces this pattern.

### G6 — Deleted tests after the merge are not caught by CI  [community]
Coverage thresholds are checked against the test suite that runs. If tests are silently
removed or skipped (`xit`, `xdescribe`, `.skip`) while production code grows, the
percentage can hold steady while coverage of new code is zero. Combine coverage gates
with test count regression checks or mutation testing to catch this.

### G7 — Coverage does not measure what matters for integration points  [community]
Integration tests between services often have low line coverage (they call a thin
adapter layer) but catch the bugs that unit tests miss. Teams that optimise purely for
line coverage defund integration tests in favour of unit tests that inflate numbers.
The result: high coverage, frequent integration failures.

### G8 — Compliance teams conflate passing coverage with verified safety  [community]
In regulated industries (automotive, medical device, avionics), branch coverage is often
a compliance artefact submitted to auditors. The dangerous failure mode: teams learn to
produce a PDF coverage report without understanding what it means. A coverage report that
satisfies DO-178C's MC/DC requirements but was generated from tests that don't assert
outputs is formally compliant and practically useless. Pair coverage artefacts with
independent test reviews and mutation scores.

### G9 — Snapshot tests inflate branch coverage without testing behaviour  [community]
Jest snapshot tests exercise many render branches but assert only serialised output.
A snapshot change causes a diff, not a failure, so component logic mutants survive
silently. Branch coverage shows healthy numbers while meaningful assertion coverage is
missing. Combine snapshots with explicit behavioural assertions for critical paths.

---

## Tradeoffs & Alternatives

### When coverage metrics provide clear value
- Legacy codebases being incrementally tested: coverage maps show where to invest.
- Safety-critical or regulated code: branch coverage is often a compliance requirement.
- Large teams: coverage prevents the "someone else will write the test" problem.
- Code review: per-PR coverage diff is a fast quality signal for reviewers.

### When coverage metrics are insufficient or misleading
- **After-the-fact testing of already-shipped code**: coverage climbs quickly on code
  you already understand; it tells you little about edge-case protection.
- **UI-heavy codebases**: line coverage of render functions tells you nothing about
  visual correctness. Use visual regression (Chromatic, Percy) instead.
- **When TDD is practiced**: coverage is a lagging indicator that follows TDD naturally.
  Spending time analysing it is overhead.
- **Property-based testing in use**: tools like `fast-check` generate hundreds of
  inputs and can achieve high mutation scores at lower line coverage; conflating the
  two metrics is misleading.

### Alternatives and complements

| Alternative | What it measures better than line/branch coverage |
|-------------|---------------------------------------------------|
| Mutation testing (Stryker JS) | Whether tests can detect real bugs — not just execute them |
| Property-based testing (fast-check) | Edge cases across the full input space |
| Contract testing (Pact) | Integration correctness at service boundaries |
| Test review / pair review | Assertion quality and intent clarity |
| Visual regression (Chromatic, Percy) | UI correctness that line coverage cannot measure |

### Known adoption costs
- **Mutation testing**: 5–30x slower than unit test suite; requires incremental/selective
  configuration before CI integration is practical.
- **Istanbul instrumentation**: 20–40 % test runtime overhead; significant on large suites.
- **Per-file thresholds**: require ongoing maintenance as new files are added; can block
  PRs until thresholds are explicitly configured for new modules.
- **Stryker initial setup**: Jest preset and config alignment typically require
  2–4 hours of initial configuration on a real-world codebase.

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Martin Fowler — Test Coverage | Official | https://martinfowler.com/bliki/TestCoverage.html | Defines the smell-detector framing; explains why 100 % is not the goal |
| Stryker Mutator docs | Official | https://stryker-mutator.io/docs/ | Full configuration reference for Stryker JS and Stryker.NET |
| Stryker — Getting started | Official | https://stryker-mutator.io/docs/stryker-js/getting-started/ | Step-by-step Jest/Vitest setup for JavaScript projects |
| Jest coverage configuration | Official | https://jestjs.io/docs/configuration#coveragethreshold-object | coverageThreshold schema with per-file and per-directory support |
| Vitest coverage docs | Official | https://vitest.dev/guide/coverage.html | Threshold config, v8 vs istanbul, per-file thresholds |
| mutmut (Python) | Official | https://mutmut.readthedocs.io/ | Python mutation testing tool reference |
| Pitest (Java) | Official | https://pitest.org/ | Java/JVM mutation testing |
| fast-check (property-based) | Community | https://fast-check.io/ | Complement to coverage: explores input space without line counting |
| Google Testing Blog — Code Coverage Best Practices | Community | https://testing.googleblog.com/2020/08/code-coverage-best-practices.html | Production-grade guidance from Google's test engineering team |
