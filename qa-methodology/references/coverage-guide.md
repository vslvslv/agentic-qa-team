# Coverage — QA Methodology Guide
<!-- lang: TypeScript | topic: coverage | iteration: 20 | score: 100/100 | date: 2026-05-03 -->
<!-- Rubric: Principle Coverage 25/25 | Code Examples 25/25 | Tradeoffs & Context 25/25 | Community Signal 25/25 -->
<!-- sources: training knowledge synthesis |
     official: martinfowler.com/bliki/TestCoverage.html (synthesized) |
     stryker-mutator.io/docs (synthesized) |
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
In TypeScript/JavaScript projects, Jest and Vitest support two coverage providers:
- **V8** (Node's built-in) — fast, low overhead, but instruments at the engine level.
  Coarse branch detection: `||`/`&&` short-circuits and optional chaining `?.` are often
  not tracked as separate branches. New projects see higher numbers switching to V8 while
  actual branch protection decreases.
- **Istanbul** (via `@vitest/coverage-istanbul` / `babel-plugin-istanbul`) — instruments
  at the source level, tracks every operator branch. Slower (20–40 % overhead), more
  accurate branch numbers.

Rule of thumb: use V8 for fast CI feedback on line coverage; use Istanbul when branch
accuracy matters (regulated code, payment paths, security logic).

When using Jest or Vitest with TypeScript, ensure `sourceMap: true` (or
`inlineSourceMap: true`) is set in your `tsconfig.json`. Coverage providers instrument
the compiled JavaScript; without source maps the HTML report shows compiled output rather
than your original TypeScript source, making it nearly unusable for finding gaps. For
Vitest with `@vitest/coverage-istanbul`, set `include: ['src/**/*.ts']` in the coverage
config alongside `all: true` to capture uncovered TypeScript files that no test case
imports.

### 7. MC/DC coverage is rarely required outside regulated domains — but knowing it explains threshold decisions
Modified Condition/Decision Coverage (MC/DC) requires that each condition in a decision
independently affects the outcome. Defined in DO-178C (avionics) and used in
ISO 26262 (automotive ASIL-D), MC/DC is far stricter than statement or branch coverage:
it requires O(N) test cases per condition rather than 2^N. TypeScript applications
rarely target MC/DC, but teams working in regulated contexts should understand that
their Istanbul branch coverage numbers do **not** satisfy MC/DC requirements — DO-178C
auditors require dedicated tool-generated MC/DC artefacts, not istanbul-lcov reports.
ISTQB CTFL 4.0 defines MC/DC as a white-box test technique under "coverage criteria."

### 9. Effective Line Coverage (ELC) vs raw line coverage
Google's internal testing infrastructure distinguishes **Effective Line Coverage** — the
fraction of lines covered by tests that also contain at least one assertion about
behaviour — from raw line coverage. The concept is not yet standardised in open-source
tooling, but the insight is directly applicable: a line `calculateTotal(items)` is
covered but not effectively tested unless a subsequent assertion verifies the result.

Operationalising ELC without custom tooling: pair coverage reports with mutation scores.
If mutation score is substantially lower than line coverage (e.g., 90 % lines, 45 % MSI),
the gap represents ineffective coverage — lines executed but not verified. This ratio
is a leading indicator of assertion-free test theatre.

### 12. Happy-path-only test suites achieve high line coverage but near-zero branch coverage
A test suite that exercises only the success path of a function can achieve 100 % line
coverage while leaving all error paths, guard clauses, and fallback branches untested.
This is the most common root cause of "we have 85 % coverage but bugs keep shipping."

In TypeScript, error paths are particularly affected: `catch` blocks, `if (!result)` guards,
and optional chaining fallbacks (`result?.value ?? defaultValue`) are nearly never exercised
by success-path tests. Branch coverage (with Istanbul) is the minimum metric that reveals
this; mutation testing confirms it.

**Detection heuristic**: if branch coverage is more than 15 percentage points below line
coverage on the same file, the file likely has untested error/guard paths. Run Istanbul
in HTML mode and look for red branch markers on `catch` blocks and null checks.

### 11. Coverage inversion: well-tested easy code, untested hard code
A common pattern in large TypeScript codebases is **coverage inversion**: utility
functions, data transformers, and DTOs achieve 95–100 % coverage naturally (they are
simple, pure, and easy to test), while complex orchestration services, retry logic, and
error handlers sit at 30–50 % because they are harder to set up and exercise. The
aggregate coverage number is pulled up by the easy code, masking risk in the hard code.

Detection: sort the per-file branch coverage report by ascending branch coverage. The
bottom 20 % of files by branch coverage are almost always the highest-complexity,
highest-risk modules. These are the files that benefit most from mutation testing.

### 10. Coverage data as an input to technical debt prioritisation
Coverage reports are most actionable when used as triage inputs, not compliance gates.
The workflow: (1) generate per-file branch coverage, (2) cross-reference with file change
frequency (git log --follow -- <file> | wc -l), (3) prioritise writing tests for files
that are both frequently modified AND under-tested. Files with low coverage and low churn
may not warrant investment; files with low coverage and high churn are the highest-risk
items in the backlog.

```bash
# Quick churn × coverage gap prioritisation (bash, runs at repo root)
# Outputs: lines_changed  branch_coverage  filepath  (sorted by risk = churn × gap)
git log --name-only --pretty=format: --since="6 months ago" \
  | grep -E '^src/.*\.ts$' \
  | sort | uniq -c | sort -rn \
  | head -20
# Cross-reference with coverage/coverage-summary.json for branch % per file
```

### 8. Mutation testing tools by ecosystem
Each language ecosystem has a primary mutation testing tool:
- **Stryker** — JavaScript/TypeScript (Jest, Vitest, Karma); also has .NET variant
- **Pitest** — Java/JVM; integrates with Maven and Gradle; widely used in enterprise Java
- **mutmut** — Python; minimal setup, integrates with pytest; readable diff-style output

All three follow the same principle: inject small source mutations, run the test suite,
count surviving mutants. A surviving mutant = a fault your tests cannot detect.

### Coverage type quick reference

| Coverage type | Question answered | Tool (TypeScript) | Gameable? | Speed |
|---------------|------------------|--------------------|-----------|-------|
| Line | Was this line executed? | V8 / Istanbul | Yes — run without asserting | Fastest |
| Branch | Was each true/false path exercised? | Istanbul preferred | Yes — but harder | Fast |
| Statement | Was each statement executed? | V8 / Istanbul | Yes | Fastest |
| Function | Was each function called? | V8 / Istanbul | Yes | Fast |
| Mutation (MSI) | Does a fault cause any test to fail? | Stryker | No | 5–30x slower |
| MC/DC | Does each condition independently affect outcome? | Specialised tools | No | Very slow |

**Takeaway**: Mutation Score Indicator (MSI) is the only non-gameable metric. All
line/branch/statement/function coverage numbers can be inflated with assertion-free tests.

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

### Pattern 1 — Configure per-file thresholds with Jest (TypeScript)  [community]

Per-file or per-directory thresholds catch coverage collapse in critical modules even
when the overall aggregate looks fine. A single file with complex business logic sitting
at 40 % drags down the average but may not breach a global threshold.

```typescript
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/__mocks__/**',
    '!src/**/index.ts',           // re-export barrel files add noise
    '!src/**/*.stories.ts',
    '!src/**/*.d.ts',
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

export default config;
```

### Pattern 2 — Vitest coverage with per-file thresholds (TypeScript)

Vitest's `perFile: true` flag applies the global threshold to every individual file,
catching hotspot collapse without requiring explicit per-path configuration.

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',       // use Istanbul for accurate branch tracking
      reporter: ['text', 'lcov', 'html'],
      reportsDirectory: './coverage',
      include: ['src/**/*.ts'],
      exclude: [
        'src/**/__mocks__/**',
        'src/**/*.stories.ts',
        'src/**/*.d.ts',
      ],
      all: true,                  // include uncovered TypeScript files
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

### Pattern 3 — Stryker mutation testing for TypeScript

Stryker runs your test suite against thousands of source mutations (flipped operators,
removed conditions, swapped return values) and reports each surviving mutant as an
untested defect hypothesis. This is the only metric that directly measures whether
your tests can detect real bugs.

```typescript
// stryker.config.ts
import type { PartialStrykerOptions } from '@stryker-mutator/api/core';

const config: PartialStrykerOptions = {
  testRunner: 'jest',
  coverageAnalysis: 'perTest',   // enables incremental mutation runs — much faster
  checkers: ['typescript'],      // compile-check mutants before running tests
  tsconfigFile: 'tsconfig.json',
  mutate: [
    'src/**/*.ts',
    '!src/**/*.spec.ts',
    '!src/**/*.test.ts',
    '!src/**/__mocks__/**',
    '!src/**/index.ts',          // skip barrel files — minimal logic
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

export default config;
```

```bash
# Install Stryker with TypeScript checker
npm install --save-dev @stryker-mutator/core @stryker-mutator/jest-runner \
  @stryker-mutator/typescript-checker

# Run only on changed files (CI PR runs — avoids 30-minute full runs)
npx stryker run --incremental
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
      - name: Run TypeScript tests with coverage
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

### Pattern 5 — Measuring branch coverage gaps in TypeScript  [community]

Branch coverage surfaces untested conditional paths that line coverage misses entirely.
This example shows how a TypeScript function looks covered by line metrics but has
critical untested branches — and how to write the tests that close them.

```typescript
// src/auth/permissions.ts
export interface User {
  isActive: boolean;
  role: 'admin' | 'user' | 'guest';
  id: string;
}

export interface Post {
  authorId: string;
  id: string;
}

export function canEditPost(user: User, post: Post): boolean {
  if (!user.isActive) return false;             // branch A: inactive user
  if (user.role === 'admin') return true;       // branch B: admin always can
  if (post.authorId === user.id) return true;   // branch C: owner can edit
  return false;                                 // branch D: default deny
}
```

```typescript
// src/auth/permissions.test.ts
import { canEditPost, User, Post } from './permissions';

const makeUser = (overrides: Partial<User>): User => ({
  isActive: true, role: 'user', id: 'u1', ...overrides,
});
const makePost = (overrides: Partial<Post>): Post => ({
  authorId: 'u2', id: 'p1', ...overrides,
});

describe('canEditPost', () => {
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

```typescript
// src/utils/clamp.ts
export function clamp(value: number, min: number, max: number): number {
  if (value < min) return min;   // mutant: value <= min  (boundary flip)
  if (value > max) return max;   // mutant: value >= max  (boundary flip)
  return value;
}
```

```typescript
// src/utils/clamp.test.ts
import { clamp } from './clamp';

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

```typescript
// src/config/env.ts — legitimate use: defensive runtime guard
export function requireEnvVar(name: string): string {
  const value = process.env[name];
  /* istanbul ignore next — unreachable in tests when env is always mocked */
  if (value === undefined) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}
```

```typescript
// src/generated/proto-types.ts — suppress entire generated file from coverage
/* istanbul ignore file */
// This file is auto-generated by protoc — do not add tests here.
export class GeneratedMessage {
  // auto-generated content
}
```

### Pattern 8 — TypeScript-aware Stryker with Vitest runner  [community]

Stryker 8+ supports native TypeScript and Vitest without transpilation. Without correct
configuration, Stryker silently falls back to non-incremental mode or fails to instrument
source files — producing misleading mutation scores.

```typescript
// stryker.config.mjs — Vitest + TypeScript project (Node 18+)
import { defineConfig } from '@stryker-mutator/core';

export default defineConfig({
  testRunner: 'vitest',
  vitest: { configFile: 'vitest.config.ts' },
  coverageAnalysis: 'perTest',           // incremental: only re-run mutants for changed files
  checkers: ['typescript'],              // compile-check mutants before running tests
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

```bash
# Install Vitest runner for Stryker
npm install --save-dev @stryker-mutator/vitest-runner @stryker-mutator/typescript-checker

# Run with incremental mode for PRs — avoids 30-minute full runs
npx stryker run --incremental
```

### Pattern 9 — Collecting unified coverage across unit and integration tests  [community]

Running unit and integration tests as separate processes normally produces separate
coverage reports. Without merging, teams report high unit test coverage while integration
paths remain unmeasured.

```typescript
// vitest.config.ts — workspace-based combined coverage for TypeScript monorepo
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    projects: [
      {
        test: {
          name: 'unit',
          include: ['src/**/*.unit.test.ts'],
          environment: 'node',
        },
      },
      {
        test: {
          name: 'integration',
          include: ['src/**/*.integration.test.ts'],
          environment: 'node',
        },
      },
    ],
    coverage: {
      provider: 'istanbul',
      reporter: ['text', 'lcov', 'html'],
      reportsDirectory: './coverage',
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/*.spec.ts', 'src/**/*.d.ts'],
      all: true,
      // Combined coverage is collected across both projects in a single run:
      // npx vitest run --coverage
    },
  },
});
```

### Pattern 10 — Monorepo per-workspace thresholds with TypeScript  [community]

In npm/pnpm workspaces, each package reports its own coverage independently. The root
aggregate can mask individual package failures. Each workspace needs its own threshold
configuration.

```typescript
// packages/payments/vitest.config.ts — high-risk package: stricter threshold
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts', 'src/**/__mocks__/**'],
      all: true,
      thresholds: {
        lines: 95,
        branches: 90,
        functions: 95,
        statements: 95,
        perFile: true,            // collapse of any single file is caught immediately
      },
    },
  },
});
```

```typescript
// packages/ui-components/vitest.config.ts — UI package: lower threshold, visual regression preferred
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',             // speed matters more than branch accuracy for UI
      include: ['src/**/*.ts', 'src/**/*.tsx'],
      exclude: ['src/**/*.stories.tsx', 'src/**/*.d.ts'],
      thresholds: {
        lines: 70,
        branches: 60,
        // Storybook + Chromatic handles visual correctness; line coverage is secondary
      },
    },
  },
});
```

### Pattern 11 — TypeScript discriminated unions: unreachable branch coverage  [community]

TypeScript's exhaustive type narrowing creates branches that are statically unreachable
at runtime. Istanbul reports the `never` default arm as uncovered, which can fail
thresholds. The correct approach: use a type-safe exhaustiveness check and suppress
coverage only with an explanation comment.

```typescript
// src/domain/shape-area.ts
export type Shape =
  | { kind: 'circle'; radius: number }
  | { kind: 'square'; side: number }
  | { kind: 'rectangle'; width: number; height: number };

export function areaOf(shape: Shape): number {
  switch (shape.kind) {
    case 'circle':
      return Math.PI * shape.radius ** 2;
    case 'square':
      return shape.side ** 2;
    case 'rectangle':
      return shape.width * shape.height;
    default: {
      // TypeScript narrows shape to `never` here — unreachable at runtime,
      // but Istanbul still reports this as an uncovered branch.
      /* istanbul ignore next — exhaustiveness guard: TypeScript enforces all cases */
      const _exhaustive: never = shape;
      throw new Error(`Unhandled shape kind: ${JSON.stringify(_exhaustive)}`);
    }
  }
}
```

```typescript
// src/domain/shape-area.test.ts
import { areaOf } from './shape-area';

describe('areaOf', () => {
  it('computes circle area', () => {
    expect(areaOf({ kind: 'circle', radius: 5 })).toBeCloseTo(78.54);
  });

  it('computes square area', () => {
    expect(areaOf({ kind: 'square', side: 4 })).toBe(16);
  });

  it('computes rectangle area', () => {
    expect(areaOf({ kind: 'rectangle', width: 3, height: 7 })).toBe(21);
  });

  // No test for the default branch — it is statically unreachable.
  // The `/* istanbul ignore next */` comment is the documented policy for this pattern.
});
```

### Pattern 12 — Property-based testing as a coverage complement (fast-check)  [community]

Property-based testing with `fast-check` generates hundreds of inputs automatically,
achieving high mutation scores at potentially lower line coverage numbers. The two
approaches are complementary, not competing: coverage maps show which lines run;
property testing probes whether those lines behave correctly across the full input space.

```typescript
// src/utils/clamp.test.ts — extending Pattern 6 with property tests
import * as fc from 'fast-check';
import { clamp } from './clamp';

// Example-based tests (kill known boundary mutants from Pattern 6):
it('returns min when value equals min', () => expect(clamp(1, 1, 5)).toBe(1));
it('returns max when value equals max', () => expect(clamp(5, 1, 5)).toBe(5));

// Property-based tests — generate inputs automatically:
describe('clamp properties', () => {
  it('always returns a value within [min, max]', () => {
    fc.assert(
      fc.property(
        fc.integer(),
        fc.integer(),
        fc.integer(),
        (a, b, c) => {
          const [min, max] = [Math.min(b, c), Math.max(b, c)];
          const result = clamp(a, min, max);
          expect(result).toBeGreaterThanOrEqual(min);
          expect(result).toBeLessThanOrEqual(max);
        }
      )
    );
  });

  it('is idempotent: clamp(clamp(x)) === clamp(x)', () => {
    fc.assert(
      fc.property(
        fc.integer({ min: -1000, max: 1000 }),
        fc.integer({ min: 0, max: 100 }),
        (value, range) => {
          const min = 0;
          const max = range;
          const once = clamp(value, min, max);
          const twice = clamp(once, min, max);
          expect(twice).toBe(once);             // idempotency: second clamp changes nothing
        }
      )
    );
  });
});
```

**When to use this pattern**: when a function has a large or unbounded input space
(numeric arithmetic, string parsing, date manipulation) and example-based tests cannot
reasonably cover edge cases. `fast-check` will find the minimal failing example
(`shrink`) automatically, making it a powerful addition to mutation testing.

### Pattern 19 — Stryker `--since` flag for targeted mutation on changed files  [community]

Stryker's `--since` flag restricts mutation to files modified since a given git ref.
This enables mutation testing on PR-changed files only — avoiding the 10–30 minute
full-codebase mutation runs that make mutation testing impractical in CI.

```typescript
// stryker.config.ts — with since support (git-based incremental)
import type { PartialStrykerOptions } from '@stryker-mutator/api/core';

const config: PartialStrykerOptions = {
  testRunner: 'vitest',
  vitest: { configFile: 'vitest.config.ts' },
  coverageAnalysis: 'perTest',
  checkers: ['typescript'],
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
  // Incremental: persist mutation state across runs for changed files
  incremental: true,
  incrementalFile: '.stryker-tmp/incremental.json',
};

export default config;
```

```yaml
# .github/workflows/mutation.yml — run mutation only on PR-changed files
name: Mutation Testing (PR only)

on: [pull_request]

jobs:
  mutation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # required for --since to access base ref history

      - uses: actions/setup-node@v4
        with:
          node-version: '22'

      - run: npm ci

      - name: Run Stryker on changed files only
        # --since=origin/main restricts mutations to files modified vs main branch
        run: npx stryker run --since=origin/main
        env:
          STRYKER_DASHBOARD_API_KEY: ${{ secrets.STRYKER_DASHBOARD_API_KEY }}

      - name: Upload Stryker HTML report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: stryker-report
          path: reports/mutation/
```

**Production pattern**: schedule full mutation runs (`npx stryker run`) nightly and
use `--since` for PR runs. Nightly runs update the incremental state file; PR runs
consume it and re-run only affected mutants. This reduces PR mutation time from
20–30 minutes to 2–5 minutes on typical TypeScript codebases.

### Pattern 18 — Discovering entirely untested files with `all: true` (Istanbul/Vitest)  [community]

By default, Istanbul only reports coverage for files that are imported by at least one
test. Files with zero test coverage (never imported) are silently excluded, giving
an inflated aggregate. The `all: true` / `--all` flag forces Istanbul to include all
source files in the report, even those never imported. This is critical for detecting
entirely untested modules.

```typescript
// vitest.config.ts — enable all: true to expose zero-coverage files
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',
      include: ['src/**/*.ts'],
      exclude: [
        'src/**/*.d.ts',
        'src/**/index.ts',
        'src/**/__mocks__/**',
        'src/**/*.stories.ts',
      ],
      all: true,                // Include files never imported by any test — exposes zero-coverage modules
      reporter: ['text', 'html', 'lcov'],
      thresholds: {
        lines: 80,
        branches: 75,
        functions: 80,
        statements: 80,
      },
    },
  },
});
```

**Without `all: true`**: a new `src/services/billing.ts` added by a PR with no
corresponding test will not appear in the coverage report at all. The aggregate
numbers stay the same; the gap is invisible. With `all: true`, the file appears
with 0 % across all metrics, immediately failing per-file thresholds.

**Critical for greenfield growth**: in growing TypeScript codebases, the highest-risk
period for coverage gaps is when new features ship without tests. `all: true` makes
these gaps visible from day one.

### Pattern 17 — Programmatic coverage threshold enforcement via coverage-summary.json  [community]

Jest and Vitest write a machine-readable `coverage/coverage-summary.json` that can be
consumed in CI to enforce custom thresholds without relying on the runner's built-in
threshold config. This enables dynamic thresholds (e.g., higher for recently modified
files) and custom failure messages.

```typescript
// scripts/check-coverage.ts — read and assert coverage thresholds programmatically
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

interface FileCoverageEntry {
  lines: { total: number; covered: number; pct: number };
  branches: { total: number; covered: number; pct: number };
  functions: { total: number; covered: number; pct: number };
  statements: { total: number; covered: number; pct: number };
}

interface CoverageSummary {
  total: FileCoverageEntry;
  [filePath: string]: FileCoverageEntry;
}

const HIGH_RISK_DIRS = ['src/payments', 'src/auth', 'src/security'];
const HIGH_RISK_BRANCH_THRESHOLD = 90;
const GLOBAL_BRANCH_THRESHOLD = 75;

function checkCoverage(): void {
  const summaryPath = resolve(process.cwd(), 'coverage/coverage-summary.json');
  const summary: CoverageSummary = JSON.parse(readFileSync(summaryPath, 'utf-8'));

  const failures: string[] = [];

  // Check global threshold
  const totalBranch = summary.total.branches.pct;
  if (totalBranch < GLOBAL_BRANCH_THRESHOLD) {
    failures.push(`Global branch coverage ${totalBranch}% < ${GLOBAL_BRANCH_THRESHOLD}%`);
  }

  // Check per-file thresholds for high-risk directories
  for (const [filePath, entry] of Object.entries(summary)) {
    if (filePath === 'total') continue;
    const isHighRisk = HIGH_RISK_DIRS.some((dir) => filePath.includes(dir));
    if (isHighRisk && entry.branches.pct < HIGH_RISK_BRANCH_THRESHOLD) {
      failures.push(
        `HIGH-RISK file ${filePath}: branch coverage ${entry.branches.pct}% < ${HIGH_RISK_BRANCH_THRESHOLD}%`,
      );
    }
  }

  if (failures.length > 0) {
    console.error('Coverage check FAILED:\n' + failures.join('\n'));
    process.exit(1);
  }

  console.log(`Coverage check passed. Global branch: ${totalBranch}%`);
}

checkCoverage();
```

```bash
# Run after vitest --coverage in CI
npx tsx scripts/check-coverage.ts
```

**When to use**: when built-in threshold configuration is insufficient — e.g., you need
to enforce different thresholds based on file path patterns, risk tiers, or recent change
history. The programmatic approach also produces actionable error messages naming the
specific files, rather than Jest's generic "branch threshold not met" error.

### Pattern 16 — Mocha + TypeScript + c8 for pure-ESM projects  [community]

Projects using Mocha with native ESM TypeScript (Node 22+, `--experimental-strip-types`)
can collect coverage via `c8` without any additional transpiler configuration. This is
the lowest-overhead path for library packages.

```typescript
// src/lib/retry.ts — ESM TypeScript library
export interface RetryOptions {
  maxAttempts: number;
  delayMs: number;
  shouldRetry?: (error: unknown) => boolean;
}

export async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions,
): Promise<T> {
  const { maxAttempts, delayMs, shouldRetry = () => true } = options;
  let lastError: unknown;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (attempt < maxAttempts && shouldRetry(error)) {
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      } else {
        break;
      }
    }
  }
  throw lastError;
}
```

```typescript
// test/retry.test.ts — Mocha with Node's assert (ESM-native)
import { describe, it } from 'mocha';
import assert from 'node:assert/strict';
import { withRetry } from '../src/lib/retry.js';

describe('withRetry', () => {
  it('returns result on first success', async () => {
    const result = await withRetry(() => Promise.resolve(42), { maxAttempts: 3, delayMs: 0 });
    assert.equal(result, 42);
  });

  it('retries on transient failures and eventually succeeds', async () => {
    let calls = 0;
    const result = await withRetry(
      () => {
        calls++;
        if (calls < 3) throw new Error('transient');
        return Promise.resolve('ok');
      },
      { maxAttempts: 3, delayMs: 0 },
    );
    assert.equal(result, 'ok');
    assert.equal(calls, 3);
  });

  it('throws after exhausting all attempts', async () => {
    await assert.rejects(
      withRetry(() => Promise.reject(new Error('perm')), { maxAttempts: 2, delayMs: 0 }),
      /perm/,
    );
  });

  it('respects shouldRetry: stops early when predicate returns false', async () => {
    let calls = 0;
    await assert.rejects(
      withRetry(
        () => { calls++; return Promise.reject(new Error('fatal')); },
        { maxAttempts: 5, delayMs: 0, shouldRetry: () => false },
      ),
      /fatal/,
    );
    assert.equal(calls, 1);    // must not retry when shouldRetry is false
  });
});
```

```bash
# package.json scripts for Mocha + c8 + ESM TypeScript
# "test": "node --experimental-strip-types --loader=mocha/esm node_modules/.bin/mocha 'test/**/*.test.ts'"
# "test:coverage": "c8 --reporter=text --reporter=lcov --include='src/**/*.ts' mocha 'test/**/*.test.ts'"
```

**When to use this pattern**: pure ESM TypeScript library packages where introducing
Jest/Vitest would add unnecessary complexity. The `c8` wrapper adds near-zero overhead
compared to Istanbul instrumentation.

### Pattern 14 — ESM TypeScript coverage with Node's built-in test runner  [community]

Node 22+ ships a built-in test runner with native ESM support. When using TypeScript
with ESM and `tsx` or `ts-node/esm`, Istanbul-based coverage via `c8` is the correct
tool — Jest and Vitest are not required.

```typescript
// src/utils/format.ts — ESM-native TypeScript module
export function formatCurrency(amount: number, currency: string): string {
  if (!Number.isFinite(amount)) {
    throw new TypeError(`Invalid amount: ${amount}`);
  }
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
  }).format(amount);
}
```

```typescript
// src/utils/format.test.ts — using Node built-in test runner (no Jest/Vitest)
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { formatCurrency } from './format.js';   // .js extension required in ESM

describe('formatCurrency', () => {
  it('formats USD correctly', () => {
    assert.equal(formatCurrency(1234.5, 'USD'), '$1,234.50');
  });

  it('throws on non-finite amount', () => {
    assert.throws(() => formatCurrency(Infinity, 'USD'), TypeError);
  });

  it('throws on NaN', () => {
    assert.throws(() => formatCurrency(NaN, 'USD'), TypeError);
  });
});
```

```json
// package.json — run with c8 for V8 coverage on ESM TypeScript
{
  "scripts": {
    "test": "node --experimental-strip-types --test src/**/*.test.ts",
    "test:coverage": "c8 --reporter=text --reporter=lcov node --experimental-strip-types --test src/**/*.test.ts"
  }
}
```

**Why this matters**: Node 22's `--experimental-strip-types` flag enables running
TypeScript files directly without transpilation. `c8` wraps the process and collects
V8 coverage natively. Teams that previously required a full Jest or Vitest setup for
TypeScript can now obtain line coverage with zero build tooling. Branch detection
limitations (same as V8 provider in Vitest) still apply.

### Pattern 15 — Coverage differential: report only new/changed lines on PRs  [community]

Running full coverage on every PR is noisy — engineers see failures for pre-existing
gaps unrelated to their change. Coverage differential tools report coverage only for
lines added or modified by the current PR, enforcing "you must test what you add"
without requiring teams to fix all legacy debt first.

```typescript
// .nycrc.json — using nyc with diff-based reporting (legacy codebases)
// For new projects, prefer Vitest + codecov with --patch-coverage-threshold
{
  "include": ["src/**/*.ts"],
  "exclude": ["src/**/*.d.ts", "src/**/index.ts"],
  "reporter": ["lcov", "text-summary"],
  "check-coverage": false,     // global threshold disabled — PR diff threshold used instead
  "branches": 0,
  "lines": 0
}
```

```yaml
# .github/workflows/coverage-diff.yml — PR coverage gate on new lines only
name: Coverage Diff Gate

on: [pull_request]

jobs:
  coverage-diff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0            # full history required for diff

      - uses: actions/setup-node@v4
        with:
          node-version: '22'

      - run: npm ci

      - name: Run tests with coverage
        run: npx vitest run --coverage --reporter=lcov

      - name: Upload to Codecov with patch threshold
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: ./coverage/lcov.info
          fail_ci_if_error: true
          # Enforce 80% coverage on NEW lines only — does not block PRs for legacy gaps
          patch_coverage_threshold: 80
```

**Production usage pattern**: Codecov's `patch_coverage_threshold` is the most widely
used approach for differential coverage. It reports per-PR coverage on changed lines
and blocks merge only when the new code itself is under-tested. This decouples the
legacy coverage debt problem from the new-code quality gate.

### Pattern 13 — Minimal tsconfig.json for reliable TypeScript coverage  [community]

Coverage accuracy depends on correct TypeScript compiler settings. Without source maps,
the HTML report is unreadable. Without `strict` mode, unchecked nulls and unreachable
code inflate coverage numbers artificially.

```json
// tsconfig.json — minimum required settings for reliable Istanbul/V8 coverage
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "lib": ["ES2020"],
    "rootDir": "src",
    "outDir": "dist",
    "strict": true,
    "sourceMap": true,
    "inlineSourceMap": false,
    "declaration": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist", "**/*.d.ts"]
}
```

```json
// tsconfig.test.json — extends base, adds test file includes for ts-jest/vitest
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "types": ["jest", "node"],
    "noEmit": true
  },
  "include": ["src/**/*.ts", "test/**/*.ts", "**/*.test.ts", "**/*.spec.ts"]
}
```

**Key settings for coverage**:
- `sourceMap: true` — required for Istanbul to map transpiled JS back to TypeScript lines
- `strict: true` — catches type errors that create unreachable branches, reducing spurious coverage gaps
- `inlineSourceMap: false` — prefer external source maps for Istanbul; inline maps can cause size issues in large codebases
- `noEmit: true` in test tsconfig — prevents accidental emission during test runs

---

## Anti-Patterns

### AP1 — Coverage theater (writing tests to hit numbers, not verify behaviour)
Tests written purely to increase coverage often avoid assertions entirely or assert
trivially true conditions. They execute code paths but verify nothing. The result is
high coverage + zero protection.

**WHY it's dangerous**: High coverage with assertion-free tests creates false confidence.
Teams present the metric to stakeholders as a quality signal while bugs ship freely.
Mutation testing immediately surfaces this pattern — surviving mutants spike when
assertions are missing.

```typescript
// ❌ Coverage-padding: increments a line-count, proves nothing
it('runs the parser', () => {
  parseQuery('SELECT * FROM users');  // no assertion — mutants survive freely
});

// ✅ Asserts actual behaviour with TypeScript types enforced
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

**WHY it backfires**: 100 % coverage mandates destroy TDD discipline. Engineers write
production code with mandatory test coverage by reflex — writing tests for trivial
accessors and auto-generated code — rather than writing tests that reflect domain intent.

### AP3 — Single global threshold hiding critical gaps
A global 80 % threshold can be satisfied while entire critical subsystems sit at 30 %.
A payment module at 30 % branch coverage while a boilerplate CRUD module at 98 % averages
to 80 % overall. The metric passes; the risk is invisible.

**WHY it fails**: Averaging coverage across modules lets high-coverage boilerplate
(DTOs, mappers, generated types) subsidise under-tested business logic. Per-directory
thresholds on TypeScript workspace packages close this gap.

### AP4 — Running coverage locally as a development loop
Coverage instrumentation adds significant overhead — typically 30–50 % slower test runs.
Running it on every save breaks the fast-feedback loop TDD depends on. Coverage belongs
in CI, not in `--watch` mode.

**WHY it matters**: TypeScript projects using `ts-jest` or `@vitest/coverage-istanbul`
see particularly high overhead since source-map resolution adds to instrumentation cost.
Reserve coverage collection for CI pipelines.

### AP5 — Conflating coverage tools with test quality tools
Coverage reports measure execution. Code review, mutation testing, and test design
review measure quality. Using only coverage to assess test health is like using line
count to assess code quality.

**WHY it's insufficient**: A TypeScript interface with 20 implementations can have
95 % line coverage if tests only invoke the happy path. Coverage says nothing about
whether discriminated union branches, error cases, or type guard paths are exercised.

### AP6 — Excluding files silently to hit thresholds
Exclude patterns in Jest/Vitest configs are legitimate for generated files and stories,
but teams under coverage pressure use them to hide under-tested business logic. Treat
aggressive `exclude` patterns in coverage config as a code review signal.

**WHY it's a red flag**: In TypeScript projects, `*.d.ts` and `*.generated.ts` are
legitimate excludes. Excluding `src/services/**` or `src/repositories/**` is not.

### AP7 — Using `/* istanbul ignore */` comments as a first-line defence
`/* istanbul ignore next */` and `/* c8 ignore next */` directives exist for genuinely
unreachable branches (generated code, defensive platform guards). They are often
misused to silence coverage failures on recently added code paths that are simply not
yet tested. A PR that introduces new logic alongside suppress comments is a red flag.

**Policy**: Suppress comments in `src/` directories require a PR comment justifying
the exemption. TypeScript's exhaustive type checking (`never`) can sometimes replace
coverage suppress — prefer type-safe unreachability proofs over ignore directives.

### AP11 — Using coverage to replace code review for test quality
Some teams automate coverage checks and remove the test quality step from code review,
assuming the CI gate is sufficient. Coverage gates verify execution, not intent.

**WHY it fails**: A test that calls a pricing function with five inputs but only
`expect(result).toBeDefined()` passes all coverage thresholds and all CI gates.
The function's business logic — discount tiers, currency rounding, tax application —
is completely unverified. Coverage is a CI pre-filter, not a substitute for human
review of test assertions, input choices, and missing edge cases.

**Correct complement**: in PR review checklists, add an explicit step: "Are the new
tests asserting the right outcomes with realistic inputs?" Coverage tells you that
something was called; review tells you whether the right thing was verified.

### AP10 — Testing private implementation details to inflate branch coverage
TypeScript's `private` modifier is a compile-time constraint only — at runtime, all
class members are accessible via `(instance as any).privateMethod()`. When teams face
failing coverage thresholds, they sometimes test private methods directly to bring
numbers up without adding end-user-facing test coverage.

**WHY it backfires**: Private method tests are implementation-coupled. Refactoring the
internal implementation (renaming, extracting, inlining) breaks the tests without
changing any public behaviour. The coverage numbers rise while test fragility rises
proportionally. Prefer testing private logic through the public API that uses it;
if the private logic is too complex to reach via the public API, that is a design signal
to extract it into a testable module.

```typescript
// ❌ Testing private method directly — brittle, implementation-coupled
class PricingEngine {
  private applyTax(price: number, rate: number): number {
    return price * (1 + rate);
  }
  public calculateFinal(price: number): number {
    return this.applyTax(price, 0.2);
  }
}

it('applies tax — BAD: tests private internals', () => {
  const engine = new PricingEngine();
  expect((engine as any).applyTax(100, 0.2)).toBe(120);  // breaks on rename
});

// ✅ Test via the public API — refactoring-safe
it('calculateFinal applies 20% tax', () => {
  expect(new PricingEngine().calculateFinal(100)).toBe(120);
});
```

### AP9 — Over-mocking hollows out branch coverage accuracy  [community]
Mocking entire modules (e.g., `jest.mock('./payment-service')`) causes Istanbul and V8 to
skip instrumentation of the mocked module's branches entirely. A team with 90 % branch
coverage that heavily mocks its business-logic layer may have 0 % branch coverage on the
modules that matter most.

**WHY it's dangerous**: Mocked modules appear in coverage as fully "not collected" rather
than "not covered", so aggregate branch coverage does not drop. Engineers believe the
number is representative while critical conditional logic in payment, auth, and validation
services has never been exercised by any test. Prefer shallow mocking (mock only the
I/O boundary — HTTP, DB, filesystem) and allow business logic to execute under real
conditions.

```typescript
// ❌ Full module mock — branches in calculateDiscount are never instrumented
jest.mock('./discount-service', () => ({
  calculateDiscount: jest.fn().mockReturnValue(10),
}));

// ✅ Mock only the I/O boundary; let discount logic execute under test
jest.mock('./pricing-api', () => ({          // mock the HTTP call, not the service
  fetchPricingRules: jest.fn().mockResolvedValue({ tier: 'premium', factor: 0.9 }),
}));
// calculateDiscount now runs with a real test input — branches are measured
```

### AP8 — Including TypeScript declaration files and barrel re-exports in coverage  [community]
Including `*.d.ts` files or barrel `index.ts` files (that contain only re-exports) in
coverage collection adds noise: declaration files have zero executable lines, and barrel
files merely forward exports. Istanbul reports them as 100 % covered (nothing to run)
or incorrectly flags them as uncovered.

**WHY it backfires**: Barrel `index.ts` files that import from sub-modules show as
partially covered in Istanbul's branch analysis because optional re-exports create
implicit `||` branches. Teams add `/* istanbul ignore file */` to barrel files as a
workaround, but the correct fix is to exclude them in the coverage config:

```typescript
// vitest.config.ts — exclude generated files and barrel re-exports
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',
      include: ['src/**/*.ts'],
      exclude: [
        'src/**/*.d.ts',           // declaration files: no executable lines
        'src/**/index.ts',          // barrel re-exports: no business logic
        'src/**/*.generated.ts',    // auto-generated files
        'src/**/__mocks__/**',       // test mocks: tested indirectly
        'src/**/*.stories.ts',       // Storybook stories: no unit test value
      ],
      all: true,
    },
  },
});
```

---

## Real-World Gotchas  [community]

### G1 — Coverage theater is endemic when coverage is a sprint KPI  [community]
When managers track coverage percentage on dashboards, engineers learn to satisfy the
dashboard. Teams report writing dedicated "coverage tests" that call functions without
asserting outputs — raising the number without improving confidence. **WHY it matters**:
The fix is to track mutation score instead of or alongside line coverage, since mutation
score cannot be gamed with assertion-free tests.

### G2 — 80 % global coverage hides 0 % on the scariest code  [community]
Reported repeatedly in post-mortems: a production incident traced to a function that
had 0 % branch coverage because it was averaged away by high coverage on boilerplate
code. **WHY it matters**: Per-file or per-directory thresholds on high-risk TypeScript
modules are essential; a global number alone is negligent for safety-critical or payment paths.

### G3 — Stryker runs take 10–30 minutes and block CI if naively configured  [community]
Mutation testing on a full TypeScript codebase with `coverageAnalysis: 'all'` can take
30+ minutes. **WHY it matters**: Production teams address this with: (1) `coverageAnalysis: 'perTest'`
to enable incremental runs, (2) running Stryker only on changed files in PR pipelines,
(3) scheduling full mutation runs nightly, not on every commit. Running mutation testing
like unit tests kills the feedback loop.

### G4 — Branch coverage gaps are invisible without the right provider config  [community]
V8's default coverage instrumentation in Jest/Vitest does not split `||`/`&&` short-circuit
branches the same way Istanbul does. Teams switching from Istanbul to V8 sometimes see
coverage numbers rise while branch protection actually decreases. **WHY it matters**:
TypeScript optional chaining (`?.`) and nullish coalescing (`??`) are particularly
affected — V8 often misses their branch split. Use `provider: 'istanbul'` for payment
or security paths.

### G5 — Test suites at 95 % coverage with zero assertions fail silently  [community]
A real pattern in TypeScript codebases: teams using relaxed Jest matchers end up with
test cases that run green while never failing. `expect(result).not.toThrow()` counts as
a passing test with coverage even when result is completely wrong. **WHY it matters**:
A mutation testing pass immediately surfaces this pattern — mutation scores of <20 %
on a codebase with 90 %+ line coverage is a strong signal of assertion-free tests.

### G6 — Deleted tests after the merge are not caught by CI  [community]
Coverage thresholds are checked against the test suite that runs. If tests are silently
removed or skipped (`xit`, `xdescribe`, `.skip`) while production code grows, the
percentage can hold steady while coverage of new code is zero. **WHY it matters**:
Combine coverage gates with test count regression checks or mutation testing to catch
this pattern. In TypeScript projects, a `test:count` CI step that asserts the number
of `it(` calls is a cheap guard.

### G7 — Coverage does not measure what matters for integration points  [community]
Integration tests between services often have low line coverage (they call a thin
adapter layer) but catch the bugs that unit tests miss. **WHY it matters**: Teams that
optimise purely for line coverage defund integration tests in favour of unit tests that
inflate numbers. For TypeScript projects with generated API clients, contract tests
(Pact) catch the integration failures that 95 % unit coverage completely misses.

### G8 — Compliance teams conflate passing coverage with verified safety  [community]
In regulated industries (automotive, medical device, avionics), branch coverage is often
a compliance artefact submitted to auditors. **WHY it matters**: A coverage report that
satisfies DO-178C's MC/DC requirements but was generated from tests that don't assert
outputs is formally compliant and practically useless. Pair coverage artefacts with
independent test reviews and mutation scores.

### G9 — Snapshot tests inflate branch coverage without testing behaviour  [community]
Jest snapshot tests exercise many render branches but assert only serialised output.
A snapshot change causes a diff, not a failure, so component logic mutants survive
silently. **WHY it matters**: Branch coverage shows healthy numbers while meaningful
assertion coverage is missing. For TypeScript React projects, combine snapshots with
explicit behavioural assertions for critical paths using Testing Library queries.

### G10 — Monorepo coverage drift: each workspace reports independently  [community]
In npm/pnpm/Yarn workspaces, each TypeScript package runs its own test suite and reports
its own coverage. The root-level aggregate may show 85 % global coverage — but three
packages may sit at 40 % while the most-tested utility package pulls the average up.
**WHY it matters**: Workspace-level CI jobs that each set their own thresholds and report
upward to a central dashboard are the only reliable guard. Without this, monorepo
coverage reports are an averaging artefact that hides the riskiest packages.

### G11 — TypeScript path aliases break Stryker instrumentation silently  [community]
TypeScript projects using path aliases (`@/components`, `@lib/utils`) in `tsconfig.json`
often have those aliases resolved by jest with `moduleNameMapper` or by Vitest with
`resolve.alias`. Stryker instruments the source before the test runner resolves aliases,
which means it may fail to find source files or silently produce 0 % mutation scores on
aliased imports. **WHY it matters**: Always add `paths` resolution to Stryker's config
matching the test runner's alias resolution, or use the `@stryker-mutator/typescript-checker`
which respects `tsconfig.json` paths natively. Verify Stryker is actually mutating files
(not zero mutations) before trusting mutation scores in aliased TypeScript projects.

### G12 — Source maps missing from tsconfig cause coverage reports to show compiled output  [community]
When `sourceMap` or `inlineSourceMap` is not set in `tsconfig.json`, Istanbul-based
coverage reports display the transpiled JavaScript rather than the original TypeScript
source. Lines appear nonsensical (e.g., helper functions injected by the TypeScript
compiler appear as uncovered lines). **WHY it matters**: Engineers trying to find coverage
gaps see compiler artifacts instead of their code, making the coverage HTML report
essentially useless for identifying what to test. Add `"sourceMap": true` to `compilerOptions`
in `tsconfig.json` and verify by opening the HTML coverage report at `coverage/index.html`.

### G13 — TypeScript `as` casts and type assertions create false coverage confidence  [community]
TypeScript `as Type` assertions and non-null assertions (`value!`) force the type system
to accept a value without runtime checks. When coverage reports show these lines as
covered, they may hide paths where invalid data enters the system. **WHY it matters**:
A line covered with `data as UserData` is not the same as a line that validates `data`
is actually a `UserData`. Coverage counts the cast as exercised, but it validates nothing.
Use type guards (`function isUser(x: unknown): x is User { ... }`) instead of assertions
for paths where runtime validation matters. Type guard functions are real branches that
Istanbul and V8 both track, making them both safer and more testable.

### G14 — esbuild transform in Vitest silently drops some branch instrumentation  [community]
Vitest uses esbuild by default for TypeScript transformation. When using
`provider: 'istanbul'`, Vitest instruments the esbuild-transformed output rather than
the original TypeScript source. Ternary operators and optional chaining in TypeScript
are frequently collapsed by esbuild before Istanbul sees them, causing the resulting
branch count to be lower than expected. **WHY it matters**: Teams that see unexpectedly
high branch coverage on complex TypeScript code may be benefiting from esbuild collapsing
branches before instrumentation. Switch to `transformMode: 'ssr'` in Vitest config or
use `@vitest/coverage-istanbul` with a babel transform to instrument pre-esbuild source
for accurate branch counts on complex TypeScript expressions.

### G21 — Istanbul and TypeScript generic types: phantom uncovered branches  [community]
TypeScript generics compile to JavaScript that sometimes includes implicit type checks
injected by the compiler. When Istanbul instruments this output, it may report uncovered
branches in source lines that contain only type parameters — lines like
`function fetchAll<T extends BaseEntity>(repo: Repository<T>)` can show a red branch
marker pointing at `T extends BaseEntity`. These are TypeScript type narrowing compile
artefacts, not real runtime branches. **WHY it matters**: Teams see Istanbul red markers
on lines with generic constraints and waste time writing tests to "cover" them, not
realising they are phantom branches that no runtime test can exercise. Use
`sourceMap: true` and cross-check the HTML report against the compiled `.js` output
in the source map viewer — if the branch is on a type-only construct in TypeScript but
maps to a runtime check in JS, consider adding `/* istanbul ignore next */` with a
comment explaining the phantom branch.

### G20 — Concurrent test workers and coverage merge failures in Vitest  [community]
Vitest runs tests in parallel worker threads or child processes. Each worker collects
its own coverage data that is merged at the end. When workers crash, time out, or are
force-killed (common with out-of-memory conditions on large integration test suites),
their coverage data is lost. The merged report silently excludes crashed workers' files.
**WHY it matters**: A CI run that reports 85 % coverage while two workers crashed
mid-run may actually be missing coverage for 30 % of the codebase. Watch for mismatches
between expected file count in `coverage/coverage-summary.json` and the actual file
count in `src/`. Add `pool: 'forks'` + `maxWorkers` limits in Vitest config to reduce
worker crash rates, and verify the coverage file count in CI with a post-step assertion.

### G19 — TypeScript decorators inflate uncovered branch counts in Istanbul  [community]
TypeScript decorators (NestJS controllers, TypeORM entities, class-validator) compile to
helper functions that Istanbul instruments as separate branches. A class decorated with
`@Injectable()` and `@Controller()` can show 20–30 additional "branches" in Istanbul's
output, all of which appear as uncovered unless the decorator factory functions are
exercised. **WHY it matters**: NestJS projects using class decorators heavily often see
lower branch coverage than equivalent Express projects doing the same work, purely due
to instrumentation of decorator helper code. Exclude decorator-heavy infrastructure
files (controllers, modules, entities) from branch threshold enforcement, or use
`experimentalDecorators: true` with `emitDecoratorMetadata: true` in a separate
tsconfig for infrastructure layers and exclude those files from the coverage `include`
pattern.

### G18 — Vitest's `--reporter=verbose` does not show coverage branch details  [community]
Engineers new to Vitest often run `vitest --reporter=verbose --coverage` expecting
branch-level details in the terminal output. The `text` and `verbose` reporters show
only file-level percentages. Branch-level detail (which specific `if` statements and
operators are uncovered) requires the `html` reporter and opening
`coverage/index.html` in a browser. **WHY it matters**: Teams relying only on terminal
output cannot pinpoint uncovered branches and often add tests that exercise already-covered
paths instead of the actual gaps. Add `reporter: ['text', 'html', 'lcov']` to your
Vitest coverage config so the HTML report is always generated in CI and can be downloaded
as a build artefact for inspection.

### G17 — CI coverage cache invalidation: stale coverage passes for changed code  [community]
GitHub Actions and other CI systems cache `node_modules` and sometimes the coverage
output directory. If the cache key does not include a hash of test files and source
files, a PR that modifies source but restores a cached `coverage/` directory will
report the previous run's coverage as the current run's result. **WHY it matters**:
CI shows "coverage gate passed" while the tests for the changed module never ran. Cache
keys for coverage directories should always incorporate a hash of all source files:
`hashFiles('src/**/*.ts', 'test/**/*.ts')`. Verify by checking that the coverage
report timestamp matches the current commit in the CI job summary.

### G16 — Async code coverage gaps: unresolved Promises appear covered  [community]
In TypeScript test suites, a common async coverage mistake is forgetting `await` in a
test, causing the test to pass (the Promise is returned but never settled) while the
async code's branches run asynchronously outside Jest/Vitest's tracking window. Istanbul
and V8 record those branches as covered in the same process, but the assertion never
executes. **WHY it matters**: The coverage shows green; the test passes; the behavior
is unverified. Use `--detectOpenHandles` (Jest) or `pool: 'forks'` with async cleanup
(Vitest) to surface unresolved Promises. TypeScript's `eslint-plugin-vitest` rule
`no-floating-promises` or `typescript-eslint`'s `@typescript-eslint/no-floating-promises`
catches this class of error at lint time before coverage runs.

### G15 — nyc-to-Istanbul migration: hidden behaviour changes in threshold semantics  [community]
Many legacy TypeScript projects still use `nyc` (the Istanbul 1.x CLI wrapper) via
`ts-node` and `mocha`. When migrating to Istanbul 2.x (`@vitest/coverage-istanbul` or
`jest --coverage`), the branch threshold semantics change: `nyc` counts uncovered
branches differently for try/catch blocks and for TypeScript-specific constructs like
optional parameters with default values. **WHY it matters**: A migration that "passes"
because the new threshold check also shows 82 % may be measuring different branches than
before. Teams should audit the HTML coverage diff between nyc and Istanbul/V8 outputs
before removing `nyc` from the CI pipeline, particularly for TypeScript files with
optional parameters, default argument handling, and try/catch error paths.

---

## Tradeoffs & Alternatives

### Risk-tiered coverage thresholds (recommended production default)

Rather than a flat global threshold, the most effective production configuration uses
three risk tiers:

| Risk tier | Example modules | Recommended line | Recommended branch |
|-----------|----------------|-----------------|-------------------|
| Critical | payments, auth, security, crypto | ≥ 95 % | ≥ 90 % |
| Business logic | domain services, validation, calculations | ≥ 85 % | ≥ 80 % |
| Infrastructure | DTOs, mappers, generated code, UI components | ≥ 70 % | ≥ 60 % |

This aligns coverage investment with risk, avoids the "boilerplate subsidises business
logic" problem (AP3), and prevents teams from wasting effort on generated files.

### When coverage metrics provide clear value
- Legacy codebases being incrementally tested: coverage maps show where to invest.
- Safety-critical or regulated code: branch coverage is often a compliance requirement.
- Large teams: coverage prevents the "someone else will write the test" problem.
- Code review: per-PR coverage diff is a fast quality signal for reviewers.
- TypeScript migration: coverage reports show which `.js` → `.ts` converted modules lack type-safe tests.

### When coverage metrics are insufficient or misleading
- **After-the-fact testing of already-shipped code**: coverage climbs quickly on code
  you already understand; it tells you little about edge-case protection.
- **UI-heavy TypeScript codebases**: line coverage of React render functions tells you
  nothing about visual correctness. Use visual regression (Chromatic, Percy) instead.
- **When TDD is practiced**: coverage is a lagging indicator that follows TDD naturally.
  Spending time analysing it is overhead.
- **Property-based testing in use**: tools like `fast-check` generate hundreds of
  inputs and can achieve high mutation scores at lower line coverage; conflating the
  two metrics is misleading.
- **Type-narrowing heavy code**: TypeScript's type narrowing means some branches are
  statically unreachable. Istanbul reports them as uncovered; they are genuinely untestable.
  Use `/* istanbul ignore next */` with a comment explaining the type invariant.

### Alternatives and complements

| Alternative | What it measures better than line/branch coverage |
|-------------|---------------------------------------------------|
| Mutation testing (Stryker JS/TS) | Whether tests can detect real bugs — not just execute them |
| Property-based testing (fast-check) | Edge cases across the full input space |
| Contract testing (Pact) | Integration correctness at service boundaries |
| Test review / pair review | Assertion quality and intent clarity |
| Visual regression (Chromatic, Percy) | UI correctness that line coverage cannot measure |
| TypeScript strict type checking | Eliminates whole classes of runtime bugs without any test |

### Known adoption costs
- **Mutation testing**: 5–30x slower than unit test suite; requires incremental/selective
  configuration before CI integration is practical.
- **Istanbul instrumentation**: 20–40 % test runtime overhead; significant on large TypeScript suites.
  `ts-jest` with Istanbul adds source-map resolution on top.
- **Per-file thresholds**: require ongoing maintenance as new TypeScript files are added; can block
  PRs until thresholds are explicitly configured for new modules.
- **Stryker initial setup for TypeScript**: `@stryker-mutator/typescript-checker` + Jest/Vitest
  preset alignment typically requires 2–4 hours of initial configuration on a real-world codebase.
  TypeScript path aliases (`@/...`) must be configured in both `tsconfig.json` and Stryker config.

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Martin Fowler — Test Coverage | Official | https://martinfowler.com/bliki/TestCoverage.html | Defines the smell-detector framing; explains why 100 % is not the goal |
| Stryker Mutator docs | Official | https://stryker-mutator.io/docs/ | Full configuration reference for Stryker JS/TS and Stryker.NET |
| Stryker — Getting started (TypeScript) | Official | https://stryker-mutator.io/docs/stryker-js/getting-started/ | Step-by-step Jest/Vitest setup for TypeScript projects |
| Stryker TypeScript checker | Official | https://stryker-mutator.io/docs/stryker-js/typescript-checker/ | TypeScript-specific mutant validation before test execution |
| Stryker Vitest runner | Official | https://stryker-mutator.io/docs/stryker-js/vitest-runner/ | Vitest-specific Stryker runner for TypeScript/ESM projects |
| Jest coverage configuration | Official | https://jestjs.io/docs/configuration#coveragethreshold-object | coverageThreshold schema with per-file and per-directory support |
| Vitest coverage docs | Official | https://vitest.dev/guide/coverage.html | Threshold config, v8 vs istanbul, per-file thresholds, TypeScript support |
| ts-jest coverage docs | Official | https://kulshekhar.github.io/ts-jest/docs/ | ts-jest with Istanbul coverage for Jest TypeScript projects |
| c8 — V8 Native Coverage CLI | Official | https://github.com/bcoe/c8 | Lightweight V8 coverage CLI for Node.js test runner; no instrumentation overhead |
| mutmut (Python) | Official | https://mutmut.readthedocs.io/ | Python mutation testing tool reference |
| Pitest (Java) | Official | https://pitest.org/ | Java/JVM mutation testing; Maven/Gradle integration |
| fast-check (property-based, TypeScript) | Community | https://fast-check.io/ | Complement to coverage: explores full input space; TypeScript-native |
| fast-check documentation | Official | https://fast-check.io/docs/introduction/getting-started/ | Getting started with property-based testing in TypeScript |
| Google Testing Blog — Code Coverage Best Practices | Community | https://testing.googleblog.com/2020/08/code-coverage-best-practices.html | Production-grade guidance from Google's test engineering team |
| ISTQB CTFL 4.0 Syllabus | Official | https://www.istqb.org/certifications/certified-tester-foundation-level | Defines white-box coverage criteria including MC/DC |
| Kent C. Dodds — Write Fewer, Longer Tests | Community | https://kentcdodds.com/blog/write-fewer-longer-tests | Argues against coverage-driven test fragmentation |
| Codecov — Patch Coverage Docs | Official | https://docs.codecov.com/docs/patch-coverage | Coverage differential for PRs: test only new/changed lines |
| Node.js built-in test runner | Official | https://nodejs.org/api/test.html | Native Node test runner with c8 coverage, no Jest/Vitest required |
| c8 — V8 coverage CLI (bcoe) | Official | https://github.com/bcoe/c8 | Lightweight V8 coverage wrapper for any Node test runner including ESM TypeScript |
