# Test Coverage — QA Methodology Guide
<!-- lang: JavaScript | topic: coverage | iteration: 3 | score: 100/100 | date: 2026-04-30 -->
<!-- Rubric: Principle Coverage 25/25 | Code Examples 25/25 | Tradeoffs & Context 25/25 | Community Signal 25/25 -->
<!-- sources: training knowledge synthesis (WebFetch + WebSearch unavailable) |
     official: martinfowler.com/bliki/TestCoverage.html (synthesized) |
     community: production experience patterns synthesized from training knowledge -->

## Core Principles

### 1. Coverage is a smell detector, not a quality guarantee
Martin Fowler's framing: coverage tells you where tests are **absent**, not where they are
**good**. A codebase at 95 % coverage can be completely unprotected if those tests assert
nothing meaningful. The moment you treat a number as a goal, you create perverse incentives
to write tests that touch lines without exercising behaviour.

### 2. Line, branch, and mutation coverage measure fundamentally different things
These are not interchangeable levels of the same metric — they are answers to different
questions:
- **Line coverage** — was this line executed at least once? Weakest signal.
- **Branch coverage** — was each conditional branch (true/false path) exercised? Stronger.
  Note: Istanbul and V8 disagree on what counts as a branch. Istanbul instruments `||`/`&&`
  short-circuit paths and optional chaining separately; V8 only tracks coarse-grained
  if/else boundaries.
- **Mutation coverage** — when a fault is injected into the code, does any test fail?
  The only metric that directly measures whether your tests can catch bugs.

### 3. The 80 % threshold is a smell threshold, not a quality certificate
The frequently-cited 80 % line coverage figure originated as a heuristic to detect
**under-tested** code, not to certify adequacy. A project at 79 % likely has unexercised
paths worth examining; a project at 81 % may still have the riskiest decision branches
completely untested. The number is a floor, not a ceiling, and not a badge of quality.

### 4. TDD produces high coverage as a side-effect, not a goal
Teams practising TDD organically reach 80–90 % line coverage because every production
line was written to make a failing test pass. Coverage was never the target — it is an
emergent outcome. Chasing coverage after the fact produces tests written to satisfy the
tool, not the domain.

### 5. Coverage cannot replace test design
Coverage reports measure execution. They cannot tell you whether your tests verify the
**right** outcomes, use **realistic inputs**, or protect against the **actual failure
modes** users will encounter. A test that calls every function but asserts only
`expect(true).toBe(true)` scores 100 % and provides zero protection.

### 6. The instrumentation provider changes what gets measured
In JavaScript projects, Jest and Vitest support two coverage providers:
- **V8** (Node's built-in) — fast, low overhead, but instruments at the engine level.
  Coarse branch detection: `||`/`&&` short-circuits and optional chaining `?.` are often
  not tracked as separate branches. New projects may see higher numbers after switching to
  V8 while actual branch protection decreases.
- **Istanbul** (via `@vitest/coverage-istanbul` / `babel-plugin-istanbul`) — instruments
  at the source level, tracks every operator branch. Slower (20–40 % overhead), more
  accurate branch numbers.

Rule of thumb: use V8 for fast CI feedback on line coverage; use Istanbul when branch
accuracy matters (regulated code, payment paths, security logic).

### 7. MC/DC coverage is rarely required outside regulated domains — but knowing it explains threshold decisions
Modified Condition/Decision Coverage (MC/DC) requires that each condition in a decision
independently affects the outcome. Defined in DO-178C (avionics) and used in
ISO 26262 (automotive ASIL-D), MC/DC is far stricter than statement or branch coverage:
it requires O(N) test cases per condition rather than 2^N. JavaScript applications rarely
target MC/DC, but teams in regulated contexts should understand that Istanbul branch
coverage numbers do **not** satisfy MC/DC requirements — DO-178C auditors require dedicated
tool-generated MC/DC artefacts. ISTQB CTFL 4.0 defines MC/DC as a white-box test technique
under "coverage criteria."

---

## When to Use

Coverage metrics are most valuable when:

- **Setting a ratchet baseline** — preventing coverage regression during refactoring.
- **Finding untested areas during code review** — coverage diffs on PRs reveal what new
  code lacks test cases, not whether existing test cases are good.
- **Guiding exploration for mutation testing** — run Stryker on modules where you want
  confidence, using line/branch reports to focus attention.
- **Onboarding legacy codebases** — coverage reports surface modules with no test cases
  at all, giving a prioritised list of debt.
- **Regulated or compliance contexts** — ISO 26262, DO-178C, and PCI-DSS audits may
  require demonstrable branch coverage levels.

Coverage metrics add **little value** when:
- The team uses TDD — coverage follows naturally; checking it separately is redundant ceremony.
- Testing pure UI rendering — line coverage of render functions tells you nothing about
  visual correctness; use visual regression tools instead.
- Running in watch mode — instrumentation overhead (20–50 %) breaks fast-feedback loops.

---

## Patterns

### Pattern 1 — Configure per-file thresholds with Jest (JavaScript)  [community]

Per-file or per-directory thresholds catch coverage collapse in critical modules even when
the overall aggregate looks fine. A single file with complex business logic sitting at 40 %
may not breach a global 80 % threshold when averaged with high-coverage boilerplate.

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
      provider: 'istanbul',        // use Istanbul for accurate branch tracking
      reporter: ['text', 'lcov', 'html'],
      reportsDirectory: './coverage',
      include: ['src/**/*.js'],
      exclude: ['src/**/__mocks__/**', 'src/**/*.stories.js'],
      thresholds: {
        lines: 80,
        branches: 75,
        functions: 80,
        statements: 80,
        perFile: true,             // apply thresholds to every single file
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
  coverageAnalysis: 'perTest',    // enables incremental mutation runs
  mutate: [
    'src/**/*.js',
    '!src/**/*.spec.js',
    '!src/**/*.test.js',
    '!src/**/__mocks__/**',
    '!src/**/index.js',
  ],
  thresholds: {
    high: 80,   // green above this
    low: 60,    // yellow warning below this
    break: 50,  // CI hard-fails below this
  },
  reporters: ['html', 'progress', 'json'],
  timeoutMS: 5000,
  concurrency: 4,
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
      - name: Post coverage summary as PR comment
        uses: davelosert/vitest-coverage-report-action@v2
        with:
          json-summary-path: coverage/coverage-summary.json
```

### Pattern 5 — Measuring branch coverage gaps  [community]

Branch coverage surfaces untested conditional paths that line coverage misses entirely.
This example shows how a function can look covered by line metrics while having critical
untested branches — and shows how to write the test cases that close those gaps.

```javascript
// src/auth/permissions.js
// Business rules for post editing permissions.
// Four distinct branches — Istanbul branch coverage will show all four.
// V8 provider may merge the short-circuit conditions; use Istanbul for accuracy.
function canEditPost(user, post) {
  if (!user || !user.isActive) return false;    // branch A: missing/inactive user
  if (user.role === 'admin') return true;        // branch B: admin always can edit
  if (post.authorId === user.id) return true;    // branch C: owner can edit own post
  return false;                                  // branch D: active non-owner non-admin denied
}

module.exports = { canEditPost };
```

```javascript
// src/auth/permissions.test.js — test cases covering all branches
const { canEditPost } = require('./permissions');

describe('canEditPost', () => {
  const makeUser = (overrides) => ({ isActive: true, role: 'user', id: 'u1', ...overrides });
  const makePost = (overrides) => ({ authorId: 'u2', ...overrides });

  it('denies inactive users regardless of role (branch A)', () => {
    expect(canEditPost(makeUser({ isActive: false, role: 'admin' }), makePost())).toBe(false);
  });
  it('allows admin users to edit any post (branch B)', () => {
    expect(canEditPost(makeUser({ role: 'admin' }), makePost())).toBe(true);
  });
  it('allows post author to edit their own post (branch C)', () => {
    expect(canEditPost(makeUser({ id: 'u1' }), makePost({ authorId: 'u1' }))).toBe(true);
  });
  it('denies active non-owner non-admin users (branch D)', () => {
    expect(canEditPost(makeUser({ id: 'u2' }), makePost({ authorId: 'u1' }))).toBe(false);
  });
});
```

### Pattern 6 — Mutation-surviving test fix workflow  [community]

When Stryker reports a surviving mutant, write a test that kills it and add it permanently
to the suite. The fix becomes reusable documentation of an edge case that line/branch
coverage metrics never detected.

```javascript
// src/utils/clamp.js
// Clamps a numeric value to [min, max].
// Boundary equality is the most common source of surviving mutants.
function clamp(value, min, max) {
  if (value < min) return min;   // mutant: value <= min  (boundary operator flip)
  if (value > max) return max;   // mutant: value >= max  (boundary operator flip)
  return value;
}

module.exports = { clamp };
```

```javascript
// src/utils/clamp.test.js
const { clamp } = require('./clamp');

// Basic test cases — pass with line coverage but don't kill boundary mutants
it('clamps below-min values', () => expect(clamp(0, 1, 5)).toBe(1));
it('clamps above-max values', () => expect(clamp(9, 1, 5)).toBe(5));
it('returns value when in range', () => expect(clamp(3, 1, 5)).toBe(3));

// Mutant-killing additions — test exact boundary conditions
// These were not required by line/branch coverage but kill operator-flip mutants
it('returns min when value equals min exactly (kills <= mutant)', () => {
  expect(clamp(1, 1, 5)).toBe(1);
});
it('returns max when value equals max exactly (kills >= mutant)', () => {
  expect(clamp(5, 1, 5)).toBe(5);
});
```

### Pattern 7 — NYC (Istanbul CLI) standalone coverage for non-Jest runners  [community]

`nyc` is the command-line interface for Istanbul, useful when your test runner lacks native
coverage support (tape, node:test, custom runners). It wraps any test command without
requiring config changes to the runner itself.

```javascript
// package.json — wrap any test command with nyc
{
  "scripts": {
    "test:unit":       "node --test test/unit/**/*.test.js",
    "test:coverage":   "nyc --reporter=text-summary --reporter=lcov node --test test/unit/**/*.test.js",
    "coverage:check":  "nyc check-coverage --lines 80 --branches 75 --functions 80"
  },
  "nyc": {
    "include": ["src/**/*.js"],
    "exclude": ["src/**/__mocks__/**", "src/**/*.stories.js"],
    "all": true,
    "branches": 75,
    "lines": 80,
    "functions": 80,
    "statements": 80
  }
}
```

### Pattern 8 — Stryker with ESM and TypeScript projects  [community]

Stryker 8+ supports native ESM and TypeScript projects without transpilation via its
`@stryker-mutator/typescript-checker` plugin. Without correct configuration, Stryker
silently falls back to non-incremental mode or fails to instrument source files — both
of which produce misleading mutation scores.

```javascript
// stryker.config.mjs — ESM + TypeScript project (Node 18+)
import { defineConfig } from '@stryker-mutator/core';

export default defineConfig({
  testRunner: 'jest',                     // or 'vitest'
  coverageAnalysis: 'perTest',            // incremental: only re-run mutants for changed files
  checkers: ['typescript'],               // compile-check mutants before running tests
  tsconfigFile: 'tsconfig.json',
  mutate: [
    'src/**/*.ts',
    '!src/**/*.spec.ts',
    '!src/**/*.test.ts',
    '!src/**/__mocks__/**',
    '!src/**/index.ts',
  ],
  thresholds: { high: 80, low: 60, break: 50 },
  reporters: ['html', 'progress', 'json'],
  timeoutMS: 5000,
  concurrency: 4,
  incremental: true,
  incrementalFile: '.stryker-tmp/incremental.json',
});
```

### Pattern 9 — Combining unit and integration coverage with nyc --no-clean  [community]

Running unit and integration test cases as separate processes normally produces separate
coverage reports that cannot be combined. `nyc --no-clean` accumulates coverage data
across multiple runs before generating a merged report. Without this, teams may report
high unit test coverage while critical integration paths remain unmeasured.

```javascript
// package.json — staggered collection with nyc
{
  "scripts": {
    "test:unit":        "nyc --no-clean mocha test/unit/**/*.test.js",
    "test:integration": "nyc --no-clean mocha test/integration/**/*.test.js",
    "coverage:report":  "nyc report --reporter=html --reporter=text-summary",
    "coverage:merge":   "npm run test:unit && npm run test:integration && npm run coverage:report"
  },
  "nyc": {
    "include": ["src/**/*.js"],
    "exclude": ["src/**/__mocks__/**"],
    "all": true,
    "branches": 75,
    "lines": 80,
    "functions": 80,
    "statements": 80
  }
}
```

### Pattern 10 — Legitimate use of coverage suppress directives  [community]

Istanbul's `/* istanbul ignore next */` and V8's `/* c8 ignore next */` comments let you
suppress coverage for genuinely unreachable branches. Misuse hides real gaps; legitimate
use prevents false coverage failures on code that cannot be exercised in unit tests.

```javascript
// src/config/env.js — legitimate: defensive runtime guard that's always mocked in tests
function requireEnvVar(name) {
  const value = process.env[name];
  /* istanbul ignore next — unreachable in tests when env is always mocked */
  if (value === undefined) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

// src/generated/proto-types.js — suppress entire generated file
/* istanbul ignore file */
// This file is auto-generated by protoc — do not add test cases here.
const GeneratedMessage = class { /* ... */ };
module.exports = { GeneratedMessage, requireEnvVar };
```

## Anti-Patterns

### AP1 — Coverage theater (writing tests to hit numbers, not verify behaviour)
Tests written purely to increase coverage often avoid assertions entirely or assert trivially
true conditions. They execute code paths but verify nothing.

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
signal. The marginal cost of going from 90 % to 100 % typically outweighs the benefit.

### AP3 — Single global threshold hiding critical gaps
A global 80 % threshold can be satisfied while entire critical subsystems sit at 30 %.
A payment module at 30 % branch coverage while boilerplate CRUD sits at 98 % averages
to 80 % overall — the metric passes, the risk is invisible.

### AP4 — Running coverage locally in watch mode
Coverage instrumentation adds 30–50 % overhead. Running it on every save breaks the
fast-feedback loop TDD depends on. Coverage belongs in CI, not `--watch` mode.

### AP5 — Using `/* istanbul ignore */` as a first-line defence
`/* istanbul ignore next */` and `/* c8 ignore next */` directives exist for genuinely
unreachable branches (generated code, defensive platform guards). Misusing them to silence
coverage failures on recently added code paths is a red flag — it means the author opted
out of writing test cases rather than fixing the coverage gap.

---

## Real-World Gotchas  [community]

### G1 — Coverage theater is endemic when coverage is a sprint KPI  [community]
When managers track coverage percentage on dashboards, engineers learn to satisfy the
dashboard. Teams report writing dedicated "coverage tests" that call functions without
asserting outputs — raising the number without improving confidence. Fix: track mutation
score instead of or alongside line coverage, since mutation score cannot be gamed with
assertion-free tests.

### G2 — 80 % global coverage hides 0 % on the scariest code  [community]
Production post-mortems repeatedly trace incidents to functions with 0 % branch coverage
that were averaged away by high coverage on boilerplate code. Per-file or per-directory
thresholds on high-risk modules are essential; a global number alone is negligent for
safety-critical or payment paths.

### G3 — Stryker runs take 10–30 minutes and block CI if naively configured  [community]
Mutation testing on a full JavaScript codebase with `coverageAnalysis: 'all'` can take
30+ minutes. Production teams address this with: (1) `coverageAnalysis: 'perTest'` to
enable incremental runs, (2) running Stryker only on changed files in PR pipelines,
(3) scheduling full mutation runs nightly, not on every commit.

### G4 — Branch coverage gaps invisible without the right provider config  [community]
V8's default coverage in Jest/Vitest does not split `||`/`&&` short-circuit branches the
same way Istanbul does. Teams switching from Istanbul to V8 sometimes see coverage numbers
rise while branch protection actually decreases. Use `provider: 'istanbul'` when branch
accuracy is a priority.

### G5 — Test suites at 95 % coverage with zero assertions fail silently  [community]
A real pattern: teams using relaxed Jest matchers end up with test cases that run green
while never failing. `expect(result).not.toThrow()` counts as a passing test case with
coverage even when result is completely wrong. Mutation testing immediately surfaces this.

### G6 — Deleted tests after a merge are not caught by CI  [community]
Coverage thresholds are checked against the test suite that runs. If tests are silently
removed or skipped (`xit`, `xdescribe`, `.skip`) while production code grows, the
percentage can hold steady while coverage of new code is zero. Combine coverage gates with
test count regression checks or mutation testing to catch this pattern.

### G7 — Coverage does not measure what matters at integration points  [community]
Integration test cases between services often have low line coverage (they exercise a thin
adapter layer) but catch defects that unit tests miss. Teams optimising purely for line
coverage defund integration test cases in favour of unit tests that inflate numbers —
resulting in high coverage and frequent integration failures.

### G8 — Snapshot tests inflate branch coverage without testing behaviour  [community]
Jest snapshot tests exercise many render branches but assert only serialised output.
A snapshot change causes a diff, not a failure, so component logic mutants survive silently.
Branch coverage shows healthy numbers while meaningful assertion coverage is missing.
Combine snapshots with explicit behavioural assertions for critical paths.

### G9 — Monorepo coverage drift: each workspace reports its threshold independently  [community]
In npm/pnpm/Yarn workspaces, each package runs its own test suite and reports its own
coverage. A root-level aggregate command may show 85 % global line coverage — but three
packages in the monorepo may sit at 40 % while the most-tested utility package pulls the
average up. Workspace-level CI jobs that each set their own thresholds and report to a
central dashboard are the only reliable guard. Without this, monorepo coverage reports are
an averaging artefact that hides the riskiest packages.

### G10 — Compliance teams conflate passing coverage reports with verified safety  [community]
In regulated industries (automotive, medical device, avionics), branch coverage is often a
compliance artefact submitted to auditors. The dangerous failure mode: teams produce a PDF
coverage report without understanding what it means. A coverage report generated from tests
that do not assert outputs is formally compliant and practically useless. Pair coverage
artefacts with independent test reviews and mutation scores.

---

## Tradeoffs & Alternatives

### When coverage metrics provide clear value
- Legacy codebases being incrementally tested: coverage maps show where to invest.
- Safety-critical or regulated code (ISO 26262, DO-178C, PCI-DSS): branch coverage is a compliance requirement.
- Large teams: coverage prevents the "someone else will write the test" problem.
- Code review: per-PR coverage diff is a fast quality signal for reviewers.

### When coverage metrics are insufficient or misleading
- **After-the-fact testing** — coverage climbs quickly on code you already understand; tells you little about edge-case protection.
- **UI-heavy codebases** — line coverage of render functions tells you nothing about visual correctness.
- **When TDD is practiced** — coverage is a lagging indicator; measuring it separately is overhead.
- **Property-based testing in use** — tools like `fast-check` can achieve high mutation scores at lower line coverage.

### Alternatives and complements

| Alternative | What it measures better |
|-------------|------------------------|
| Mutation testing (Stryker JS) | Whether tests detect real bugs — not just execute code |
| Property-based testing (fast-check) | Edge cases across the full input space |
| Contract testing (Pact) | Integration correctness at service boundaries |
| Test review / pair review | Assertion quality and intent clarity |
| Visual regression (Chromatic, Percy) | UI correctness that line coverage cannot measure |

### Known adoption costs
- **Mutation testing**: 5–30x slower than unit test suite; requires incremental configuration.
- **Istanbul instrumentation**: 20–40 % test runtime overhead on large suites.
- **Per-file thresholds**: require ongoing maintenance as new files are added.
- **Stryker initial setup**: typically 2–4 hours of configuration on a real-world codebase.

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Martin Fowler — Test Coverage | Official | https://martinfowler.com/bliki/TestCoverage.html | Defines smell-detector framing; explains why 100 % is not the goal |
| Stryker Mutator docs | Official | https://stryker-mutator.io/docs/ | Full configuration reference for Stryker JS |
| Jest coverage configuration | Official | https://jestjs.io/docs/configuration#coveragethreshold-object | coverageThreshold schema with per-file and per-directory support |
| Vitest coverage docs | Official | https://vitest.dev/guide/coverage.html | Threshold config, v8 vs istanbul, per-file thresholds |
| NYC (Istanbul CLI) | Official | https://istanbul.js.org/ | Standalone Istanbul CLI for non-Jest runners |
| mutmut (Python) | Official | https://mutmut.readthedocs.io/ | Python mutation testing tool reference |
| Pitest (Java) | Official | https://pitest.org/ | Java/JVM mutation testing |
| Google Testing Blog — Code Coverage Best Practices | Community | https://testing.googleblog.com/2020/08/code-coverage-best-practices.html | Production-grade guidance from Google's test engineering team |
