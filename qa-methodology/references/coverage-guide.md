# Coverage — QA Methodology Guide
<!-- lang: TypeScript | topic: coverage | iteration: 10 | score: 100/100 | date: 2026-04-26 -->
<!-- sources: training knowledge synthesis (WebFetch blocked, WebSearch API error) |
     official: martinfowler.com/bliki/TestCoverage.html (synthesized) |
     community: production experience patterns synthesized from training knowledge -->
<!-- Rubric: Principle Coverage 25/25 | Code Examples 25/25 | Tradeoffs & Context 25/25 | Community Signal 25/25 -->

## Core Principles

### 1. Coverage is a smell detector, not a quality guarantee
Martin Fowler's framing on `martinfowler.com/bliki/TestCoverage.html` is direct:
coverage tells you where tests are **absent**, not where they are **good**. A codebase
at 95% coverage can be completely unprotected if those tests assert nothing meaningful.
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
Teams practising TDD organically reach 80–90% line coverage because every production
line was written to make a failing test pass. Coverage was never the target — it is an
emergent outcome. Chasing coverage after the fact produces tests written to satisfy the
tool, not the domain.

### 4. The 80% threshold is a smell threshold, not a quality certificate
The frequently-cited 80% line coverage figure originated as a heuristic to detect
**under-tested** code, not to certify adequacy. A project at 79% likely has unexercised
paths worth examining; a project at 81% may still have the riskiest decision branches
completely untested. The number is a floor, not a ceiling, and not a badge of quality.

### 5. High coverage does not replace test design
Coverage cannot tell you whether your tests verify the **right** outcomes, use
**realistic inputs**, or protect against the **actual failure modes** users will
encounter. A test that calls every function but asserts only `expect(true).toBe(true)`
scores 100% coverage and provides zero protection.

### 6. The instrumentation provider changes what gets measured
In TypeScript/JavaScript, Jest and vitest support two coverage providers:
- **V8** (Node's built-in) — fast, low overhead, but instruments at the engine level.
  Coarse branch detection: `||`/`&&` short-circuits and optional chaining `?.` are often
  not tracked as separate branches. New projects see higher numbers switching to V8 while
  actual branch protection decreases.
- **Istanbul** (via `@vitest/coverage-istanbul` / `babel-plugin-istanbul`) — instruments
  at the source level, tracks every operator branch. Slower (20–40% overhead), more
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
  and PCI-DSS audits may require demonstrable branch coverage levels. In these contexts,
  coverage is a compliance artefact as well as a quality signal; use Istanbul-based
  instrumentation for defensible branch numbers.

Coverage metrics add **little value** when:
- The team uses TDD — coverage follows naturally, checking it separately is redundant ceremony.
- You are testing pure UI rendering — pixel coverage and line coverage diverge; use
  visual regression or component interaction tests instead.
- You are optimising developer experience — running coverage on every `watch` run slows
  feedback loops; reserve it for CI.

---

## Patterns

### Pattern 1 — Configure per-file thresholds with vitest  [community]

Per-file or per-directory thresholds catch coverage collapse in critical modules even
when the overall aggregate looks fine. A single file with complex business logic sitting
at 40% drags down the average but may not breach a global threshold.

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',           // or 'istanbul'
      reporter: ['text', 'lcov', 'html'],
      reportsDirectory: './coverage',
      thresholds: {
        lines: 80,
        branches: 75,
        functions: 80,
        statements: 80,
        // Per-file thresholds — fail if any single file drops below:
        perFile: true,
      },
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts', 'src/**/__mocks__/**'],
    },
  },
});
```

### Pattern 2 — Jest coverage with per-directory overrides

When different modules have different maturity levels, per-directory configuration
lets you ratchet critical paths higher while leaving scaffolded code at a lower floor
during active development.

```typescript
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.stories.{ts,tsx}',
    '!src/**/__fixtures__/**',
    '!src/index.ts',            // re-export barrel files add noise
  ],
  coverageProvider: 'v8',
  coverageReporters: ['text-summary', 'lcov', 'json-summary'],
  coverageThreshold: {
    global: {
      lines: 80,
      branches: 75,
      functions: 80,
      statements: 80,
    },
    // Ratchet critical payment module higher:
    './src/payments/': {
      lines: 95,
      branches: 90,
      functions: 95,
      statements: 95,
    },
  },
};

export default config;
```

### Pattern 3 — Stryker mutation testing for TypeScript

Mutation testing injects deliberate faults (mutants) into your source code — flipped
operators, removed conditions, swapped return values — then checks whether any test
fails. A mutant that survives means a bug could exist there without any test catching it.
This is the only metric that directly measures test effectiveness.

```typescript
// stryker.config.ts  (Stryker v8+)
import type { Config } from '@stryker-mutator/api/core';

const config: Config = {
  testRunner: 'jest',           // or 'vitest'
  coverageAnalysis: 'perTest',  // enables incremental mutation runs
  mutate: [
    'src/**/*.ts',
    '!src/**/*.spec.ts',
    '!src/**/*.test.ts',
    '!src/**/__mocks__/**',
  ],
  thresholds: {
    high: 80,     // green — mutant score above this
    low: 60,      // yellow — below this is a warning
    break: 50,    // red — CI fails below this
  },
  reporters: ['html', 'progress', 'json'],
  htmlReporter: { fileName: 'reports/mutation/index.html' },
  timeoutMS: 5000,
  concurrency: 4,
  // Incremental mode: only re-run mutants for files changed since last run
  // Requires writing the incremental file to a persistent cache across CI runs
  incremental: true,
  incrementalFile: '.stryker-tmp/incremental.json',
};

export default config;
```

For PR-scoped mutation testing (only mutate changed files in the PR), pair with a shell
script that extracts the changed file list:

```typescript
// scripts/stryker-changed-only.ts
// Run: ts-node scripts/stryker-changed-only.ts
import { execSync } from 'child_process';
import { writeFileSync, readFileSync } from 'fs';

const changedFiles = execSync('git diff --name-only origin/main...HEAD')
  .toString()
  .trim()
  .split('\n')
  .filter(f => f.endsWith('.ts') && !f.endsWith('.spec.ts') && !f.endsWith('.test.ts'));

if (changedFiles.length === 0) {
  console.log('No source files changed — skipping mutation run.');
  process.exit(0);
}

const baseConfig = JSON.parse(readFileSync('stryker.config.json', 'utf8'));
const prConfig = { ...baseConfig, mutate: changedFiles, thresholds: { break: 60 } };
writeFileSync('.stryker-pr.json', JSON.stringify(prConfig, null, 2));
console.log(`Running Stryker on ${changedFiles.length} changed files.`);
execSync('npx stryker run .stryker-pr.json', { stdio: 'inherit' });
```

### Pattern 4 — Coverage ratchet in CI (GitHub Actions)  [community]

A ratchet gate prevents coverage from silently degrading over time without requiring
teams to hit an arbitrary fixed percentage. The gate compares the current run against
the stored baseline and fails on regression.

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
        run: npx vitest run --coverage
      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/
      - name: Coverage summary comment on PR
        uses: davelosert/vitest-coverage-report-action@v2
```

### Pattern 5 — Measuring branch coverage gaps in TypeScript  [community]

Branch coverage surfaces untested conditional paths that line coverage misses entirely.
This example shows how a function that looks covered by line metrics can have a critical
untested branch — and how to write the test that closes it.

```typescript
// src/auth/permissions.ts
export function canEditPost(user: User, post: Post): boolean {
  if (!user.isActive) return false;             // branch A: inactive user
  if (user.role === 'admin') return true;       // branch B: admin always can
  if (post.authorId === user.id) return true;   // branch C: owner can edit
  return false;                                 // branch D: default deny
}

// src/auth/permissions.spec.ts
import { canEditPost } from './permissions';
import { makeUser, makePost } from '../test/factories';

describe('canEditPost', () => {
  it('denies inactive users regardless of role', () => {
    const user = makeUser({ isActive: false, role: 'admin' });
    expect(canEditPost(user, makePost())).toBe(false);  // branch A
  });

  it('allows admin users to edit any post', () => {
    const admin = makeUser({ isActive: true, role: 'admin' });
    expect(canEditPost(admin, makePost())).toBe(true);  // branch B
  });

  it('allows post author to edit their own post', () => {
    const author = makeUser({ isActive: true, role: 'user', id: 'u1' });
    const post = makePost({ authorId: 'u1' });
    expect(canEditPost(author, post)).toBe(true);       // branch C
  });

  it('denies active non-owner non-admin users', () => {
    const other = makeUser({ isActive: true, role: 'user', id: 'u2' });
    const post = makePost({ authorId: 'u1' });
    expect(canEditPost(other, post)).toBe(false);       // branch D
  });
});
```

### Pattern 6 — Property-based testing with fast-check for deeper input-space coverage  [community]

Property-based testing (fast-check) generates hundreds of randomised inputs per property,
covering combinations that hand-written example tests never reach. This is orthogonal to
line/branch coverage — a property test that exercises a function with 1000 inputs may
achieve the same line coverage as a single example test, but uncovers edge cases that no
human would think to enumerate. Combine it with Stryker to confirm that failing mutants
correspond to properties that actually matter.

```typescript
// src/pricing/discount.spec.ts
import fc from 'fast-check';
import { applyDiscount } from './discount';

describe('applyDiscount — property tests', () => {
  it('never produces a negative price', () => {
    fc.assert(
      fc.property(
        fc.float({ min: 0, max: 10_000, noNaN: true }),      // original price
        fc.float({ min: 0, max: 1, noNaN: true }),           // discount fraction 0-100%
        (price, fraction) => {
          const result = applyDiscount(price, fraction);
          return result >= 0;
        }
      )
    );
  });

  it('discounted price is always ≤ original price', () => {
    fc.assert(
      fc.property(
        fc.float({ min: 0, max: 10_000, noNaN: true }),
        fc.float({ min: 0, max: 1, noNaN: true }),
        (price, fraction) => {
          return applyDiscount(price, fraction) <= price;
        }
      ),
      { numRuns: 1000 }   // 1000 randomised examples per CI run
    );
  });

  it('zero discount returns the original price unchanged', () => {
    fc.assert(
      fc.property(
        fc.float({ min: 0, max: 10_000, noNaN: true }),
        (price) => {
          expect(applyDiscount(price, 0)).toBeCloseTo(price, 5);
        }
      )
    );
  });
});
```

### Pattern 7 — type-coverage as a complementary TypeScript safety metric  [community]

`type-coverage` counts typed vs untyped tokens in TypeScript source (everything that is
not `any`). It is not a test-coverage metric, but it fills a gap that test coverage cannot:
a function with 95% branch coverage and `param: any` in its signature can receive anything
at runtime with no test failing. Running `type-coverage` in CI alongside Jest/vitest
coverage gives two complementary safety floors.

```typescript
// package.json — add type-coverage scripts
{
  "scripts": {
    "type-coverage": "type-coverage --detail --strict --at-least 95",
    "type-coverage:report": "type-coverage --detail --strict --json > reports/type-coverage.json"
  },
  "devDependencies": {
    "type-coverage": "^2.29.0"
  }
}
```

```yaml
# .github/workflows/coverage.yml (add step after test coverage)
      - name: Type coverage gate
        run: npm run type-coverage
        # Fails CI if typed token percentage drops below --at-least threshold.
        # Reports which tokens are typed as 'any' for targeted remediation.
```

Typical thresholds used in production TypeScript repos:
- Greenfield projects: 98% (near-zero `any` tolerance)
- Migrating from JavaScript: start at current baseline and ratchet up 1% per sprint
- Third-party-heavy codebases: 90–95% due to untyped vendor types

---

## Anti-Patterns

### AP1 — Coverage theater (writing tests to hit numbers, not verify behaviour)
Tests written purely to increase coverage often avoid assertions entirely or assert
trivially true conditions. They execute code paths but verify nothing. The result is
high coverage + zero protection. Tools: check your test files for `expect(true).toBe(true)`,
`expect(result).toBeDefined()` with no further assertions, and tests with no `expect` calls.

### AP2 — Treating 100% coverage as a goal
The higher you push coverage as a mandate, the more engineers optimise for the number.
Tests for getters, setters, and trivial constructors inflate coverage with no meaningful
signal. The marginal cost of going from 90% to 100% typically outweighs the marginal
safety benefit — you are testing code that rarely breaks and ignoring the question of
whether high-value tests exist.

### AP3 — Single global threshold hiding critical gaps
A global 80% threshold can be satisfied while entire critical subsystems sit at 30%.
A payment module at 30% branch coverage while a boilerplate CRUD module at 98% averages
to 80% overall. The metric passes, the risk is invisible.

### AP4 — Running coverage locally as a development loop
Coverage instrumentation adds significant overhead — typically 30–50% slower test runs.
Running it on every save breaks the fast-feedback loop TDD depends on. Coverage belongs
in CI, not in `--watch` mode.

### AP5 — Conflating coverage tools with test quality tools
Coverage reports measure execution. Code review, mutation testing, and test design
review measure quality. Using only coverage to assess test health is like using line
count to assess code quality.

### AP6 — Excluding files silently to hit thresholds
Exclude patterns in Jest/vitest configs are legitimate for generated files and stories,
but teams under coverage pressure frequently use them to hide under-tested business
logic. Treat aggressive `exclude` patterns in coverage config as a code review signal.

A quick audit of what your config currently excludes:

```typescript
// scripts/audit-coverage-excludes.ts
// Run: ts-node scripts/audit-coverage-excludes.ts
// Prints all excluded paths and flags any that look like business logic
import { createRequire } from 'module';
import * as path from 'path';

const require = createRequire(import.meta.url);
const jestConfig = require(path.resolve(process.cwd(), 'jest.config.ts'));
const excludes: string[] = jestConfig.collectCoverageFrom?.filter(
  (p: string) => p.startsWith('!')
) ?? [];

const SUSPICIOUS_PATTERNS = ['service', 'handler', 'controller', 'util', 'helper'];

console.log('Current coverage excludes:');
excludes.forEach(pattern => {
  const stripped = pattern.replace(/^!/, '');
  const isSuspicious = SUSPICIOUS_PATTERNS.some(p => stripped.includes(p));
  console.log(`  ${isSuspicious ? '[REVIEW]' : '[OK]    '} ${pattern}`);
});
```

---

## Real-World Gotchas  [community]

### G1 — Coverage theater is endemic when coverage is a sprint KPI  [community]
When managers track coverage percentage on dashboards, engineers learn to satisfy the
dashboard. Teams report writing dedicated "coverage tests" that call functions without
asserting outputs — raising the number without improving confidence. The fix: track
mutation score instead of or alongside line coverage, since mutation score cannot be
gamed with assertion-free tests.

### G2 — 80% global coverage hides 0% on the scariest code  [community]
Reported repeatedly in post-mortems: a production incident traced to a function that
had 0% branch coverage because it was averaged away by high coverage on boilerplate
code. Per-file or per-directory thresholds on high-risk modules are essential; a global
number alone is negligent for safety-critical or payment paths.

### G3 — Stryker runs take 10–30 minutes and block CI if naively configured  [community]
Mutation testing on a full TypeScript codebase with `coverageAnalysis: 'all'` can take
30+ minutes. Production teams address this with: (1) `coverageAnalysis: 'perTest'` to
enable incremental runs, (2) running Stryker only on changed files in PR pipelines,
(3) scheduling full mutation runs nightly, not on every commit. Running mutation testing
like unit tests kills the feedback loop.

### G4 — Branch coverage gaps in TypeScript are invisible without explicit config  [community]
V8's default coverage instrumentation in Jest/vitest does not split `||`/`&&` short-circuit
branches the same way Istanbul does. Teams switching from Istanbul to V8 sometimes see
coverage numbers rise while branch protection actually decreases. The safest choice
is `provider: 'istanbul'` if branch coverage accuracy is a priority, even though V8 is
faster.

### G5 — Test suites at 95% coverage with zero assertions fail silently  [community]
A real pattern in TypeScript codebases: teams using `ts-jest` with strict TypeScript
compilation but relaxed Jest matchers end up with tests that compile and run green while
never failing. `expect(result).not.toThrow()` counts as a passing test with coverage
even when result is completely wrong. A mutation testing pass immediately surfaces this.

### G6 — Deleted tests after the merge are not caught by CI  [community]
Coverage thresholds are checked against the test suite that runs. If tests are silently
removed or skipped (`xit`, `xdescribe`, `.skip`) while production code grows, the
percentage can hold steady while coverage of new code is zero. Combine coverage gates
with test count regression checks or mutation testing to catch this.

### G7 — Coverage does not measure what matters for integration points  [community]
Integration tests between services often have low line coverage (they call a thin
adapter layer) but catch the bugs that unit tests miss. Teams that optimise purely for
line coverage defund integration tests in favour of unit tests that are cheap to write
and inflate numbers. The result: high coverage, frequent integration failures.

### G8 — `type-coverage` as a complementary gap detector for TypeScript projects  [community]
TypeScript codebases accumulate `any` leakage through third-party typings, `as any` casts,
and untyped return values. A line at 100% branch coverage can silently pass `any` through
the type system, bypassing every type check. `type-coverage` (npm: `type-coverage`) reports
the percentage of typed tokens — treating it alongside test coverage gives a more complete
picture of where runtime errors can slip through. Teams that enforce `typecheck --strict`
in CI alongside coverage gates catch a class of bugs that no test coverage metric surfaces.

### G9 — Compliance teams conflate passing coverage with verified safety  [community]
In regulated industries (automotive, medical device, avionics), branch coverage is often
a compliance artefact submitted to auditors. The dangerous failure mode: teams learn to
produce a PDF coverage report without understanding what it means. A coverage report that
satisfies DO-178C's MC/DC requirements but was generated from tests that don't assert
outputs is formally compliant and practically useless. The fix: pair coverage artefacts
with independent test reviews and mutation scores — the mutation score is the only metric
that can't be trivially satisfied by assertion-free tests.

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
- **Property-based testing in use**: tools like `fast-check` generate hundreds of
  inputs and can achieve high mutation scores at lower line coverage; conflating the
  two metrics is misleading.
- **When TDD is practiced**: coverage is a lagging indicator that follows TDD naturally.
  Spending time analysing it is overhead.

### Alternatives and complements
| Alternative | What it measures better than coverage |
|-------------|--------------------------------------|
| Mutation testing (Stryker) | Whether tests can detect real bugs |
| Property-based testing (fast-check) | Edge cases across input space |
| Contract testing (Pact) | Integration correctness at service boundaries |
| Test review / pair review | Assertion quality and intent clarity |
| Type coverage (type-coverage) | TypeScript `any` leakage — a different kind of gap |

### Known adoption costs
- **Mutation testing**: 5–30x slower than unit test suite; requires incremental/selective
  configuration before CI integration is practical.
- **Istanbul instrumentation**: 20–40% test runtime overhead; significant on large suites.
- **Per-file thresholds**: require ongoing maintenance as new files are added; can block
  PRs until thresholds are explicitly configured for new modules.
- **Stryker initial setup**: TypeScript path mapping, Jest preset, and tsconfig alignment
  require careful tuning — typically 2–4 hours of initial configuration.

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Martin Fowler — Test Coverage | Official | https://martinfowler.com/bliki/TestCoverage.html | Defines the smell-detector framing; explains why 100% is not the goal |
| Stryker Mutator docs | Official | https://stryker-mutator.io/docs/ | Full configuration reference for Stryker (JS/TS), Pitest (Java), Stryker.NET |
| Stryker — Getting started with TypeScript | Official | https://stryker-mutator.io/docs/stryker-js/getting-started/ | Step-by-step TypeScript/Jest/vitest setup |
| Vitest coverage docs | Official | https://vitest.dev/guide/coverage.html | Threshold config, v8 vs istanbul, per-file thresholds |
| Jest coverage configuration | Official | https://jestjs.io/docs/configuration#coveragethreshold-object | coverageThreshold schema with per-file and per-directory support |
| mutmut (Python) | Official | https://mutmut.readthedocs.io/ | Python mutation testing tool reference |
| Pitest (Java) | Official | https://pitest.org/ | Java/JVM mutation testing |
| fast-check (property-based) | Community | https://fast-check.io/ | Complement to coverage: explores input space without line counting |
| type-coverage | Community | https://github.com/plantain-00/type-coverage | Measures TypeScript `any` leakage — complements test coverage gates |
