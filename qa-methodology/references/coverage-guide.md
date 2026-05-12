# Coverage — QA Methodology Guide
<!-- lang: TypeScript | topic: coverage | iteration: 43 | score: 100/100 | date: 2026-05-12 -->
<!-- Rubric: Principle Coverage 25/25 | Code Examples 25/25 | Tradeoffs & Context 25/25 | Community Signal 25/25 -->
<!-- sources: training knowledge synthesis |
     official: martinfowler.com/bliki/TestCoverage.html (synthesized) |
     stryker-mutator.io/docs (synthesized) |
     stryker-mutator.io/releases (fetched 2026-05-12: v9.4–9.6 new features; v9.6.1 Vitest 4.1 hitcount fix) |
     vitest.dev/blog/vitest-4.html (fetched 2026-05-12: Vitest 4 coverage API changes) |
     vitest.dev/blog/vitest-4-1 (fetched 2026-05-12: coverage.changed, agent reporter, htmlDir) |
     vitest.dev/config/coverage (fetched 2026-05-12: full config reference — autoUpdate, excludeAfterRemap, instrumenter, ignoreClassMethods, watermarks) |
     vitest.dev/config/coverage (re-fetched 2026-05-12: reportOnFailure, processingConcurrency, watermarks, thresholds.100, allowExternal, cleanOnRerun — fill in config reference gaps) |
     github.com/vitest-dev/vitest/releases (fetched 2026-05-12: v4.1.4–v4.1.6 + v5.0.0-beta.2; V8 child_process/worker_threads coverage, Istanbul instrumenter option, agent skipFull, blob dir change) |
     stryker-mutator.io/docs/stryker-js/configuration/ (re-fetched 2026-05-12: allowEmpty option, incremental.force flag, disableTypeChecks v7.0 default change) |
     stryker-mutator.io/blog/vscode-plugin (fetched 2026-05-12: VS Code plugin features, MSP protocol, inline mutant visualization) |
     vitest.dev/guide/coverage#coverage-ignore-hints (fetched 2026-05-12: start/stop ignore directives for v8+istanbul; -- @preserve suffix format; v8 ignore if/else branch-selective directives) |
     github.com/AriPerkkio/ast-v8-to-istanbul (fetched 2026-05-12: v8 ignore if / v8 ignore else branch-selective directives; full V8 ignore directive reference) |
     github.com/vitest-dev/vitest/pull/9818 (fetched 2026-05-12: Vitest 5 coverage include/exclude glob pattern breaking change — "too eager" fix) |
     stryker-mutator.io/blog (fetched 2026-05-12: Stryker.NET 4.13 MTP runner preview — keep-alive across mutations, YAML config) |
     github.com/Codium-ai/cover-agent (fetched 2026-05-12: Qodo Cover archived June 2025 — no longer maintained) |
     typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html (fetched 2026-05-12: TS 6.0 default changes — module/target/types/rootDir/strict; removed options: outFile, classic moduleResolution; ignoreDeprecations bridge flag) |
     vitest.dev/config/coverage (re-fetched 2026-05-12: coverage.thresholds[glob-pattern] per-pattern syntax, global threshold still applies to pattern-matched files — differs from Jest; htmlDir option for custom reporters and Vitest UI; html-spa reporter for single-file output) |
     vitest.dev/guide/migration (fetched 2026-05-12: Vitest 4 migration — coverage.all removed, coverage.extensions removed, coverage.ignoreEmptyLines removed, experimentalAstAwareRemapping removed; ignoreClassMethods now works with V8 provider) |
     github.com/vitest-dev/vitest/releases (re-fetched 2026-05-12: v4.1.6 latest stable; v5.0.0-beta.2 worker_threads coverage; @fast-check/vitest beforeEach/afterEach Vitest 4.1+ integration) |
     github.com/dubzzz/fast-check/releases (fetched 2026-05-12: fast-check v4.8.0 chainUntil; @fast-check/vitest dedicated Vitest integration with fc.test, beforeEach/afterEach support) |
     nodejs.org/blog/release/v24.0.0 (fetched 2026-05-12: Node 24 --experimental-strip-types still RC; test runner auto-awaits subtests; Node 24 global setup/teardown hooks) |
     jestjs.io/docs/configuration (fetched 2026-05-12: Jest 30 defineConfig/mergeConfig helpers v30.3+; jest.config.mts v30.4+; global coverageThreshold applies only to unmatched files; Babel .mts/.cts coverage v30.4+) |
     github.com/jestjs/jest/blob/main/CHANGELOG.md (fetched 2026-05-12: Jest 30.3 defineConfig/mergeConfig; Jest 30.4 jest.config.mts, Babel .mts/.cts coverage, global threshold unmatched-files fix, projects coverage accuracy fix) |
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
  **Vitest 3.2+ update**: Vitest 3.2.0 introduced **AST-based coverage remapping for V8**
  that produces identical coverage reports to Istanbul. If using Vitest 3.2+, the
  historical accuracy gap between V8 and Istanbul is closed — V8 now gives Istanbul-quality
  branch detection at V8 speed. This is a significant change from prior Vitest versions
  where Istanbul was always preferred for accurate branch tracking.
- **Istanbul** (via `@vitest/coverage-istanbul` / `babel-plugin-istanbul`) — instruments
  at the source level, tracks every operator branch. Slower (20–40 % overhead), more
  accurate branch numbers. Still required for Jest projects and Vitest versions < 3.2.

Rule of thumb: for **Vitest 3.2+**, use V8 (now AST-remapped — equivalent accuracy to Istanbul
at faster speed). For **Jest** or **Vitest < 3.2**, use Istanbul when branch accuracy matters
(regulated code, payment paths, security logic).

**esbuild + coverage ignore directives**: when using TypeScript with esbuild as the
transpiler (Vitest's default), esbuild strips JavaScript comments during transpilation.
Coverage ignore directives like `/* istanbul ignore next */` are removed before Istanbul
sees them. Fix: append `-- @preserve` to keep them (official Vitest docs format):
`/* istanbul ignore next -- @preserve */`. An older prefix form `/* @preserve istanbul ignore next */`
also works in many Vitest versions, but the `-- @preserve` suffix is the documented standard.
Without either form, all ignore directives in esbuild-transpiled TypeScript are silently
dropped — coverage will report branches that you intended to suppress.

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
- **Stryker** — JavaScript/TypeScript (Jest, Vitest, Karma); also has .NET variant.
  Incremental mode via `incremental: true` + `incrementalFile`; use `--since` for PR-scoped runs.
- **Pitest** — Java/JVM; integrates with Maven and Gradle; widely used in enterprise Java.
  Operates on **bytecode** (not source), which provides speed advantages but means mutation
  descriptions reference compiled constructs. Supports incremental analysis via
  `--historyInputLocation` / `--historyOutputLocation` — store history between runs in CI to
  avoid full re-mutation on unchanged classes. Use `--threads` for parallel mutation; use
  `--excludedClasses` and `--excludedMethods` to scope mutations away from generated code.
- **mutmut** — Python; minimal setup, integrates with pytest; readable diff-style output.
  Does not have native incremental mode — teams scope runs using `mutmut run <file>` on
  changed files only.

All three follow the same principle: inject small source mutations, run the test suite,
count surviving mutants. A surviving mutant = a fault your tests cannot detect.

### 13. Mutation-guided LLM test synthesis: a 2025 production pattern
Meta's ACH system (arXiv:2501.12862, January 2025) demonstrated a selective mutation
approach for LLM-guided test generation at production scale: rather than generating
all possible mutants, ACH generates only **domain-specific** mutants (e.g., mutations
likely to introduce privacy vulnerabilities) and feeds surviving mutants to an LLM to
synthesise targeted tests. Applied to 10,795 Android Kotlin classes at Meta, engineers
accepted 73 % of ACH-generated tests in test-a-thons, with 36 % directly addressing
privacy concerns.

Key insight for TypeScript teams using AI-assisted development: LLM-generated tests
(GitHub Copilot, Cursor, Claude) often achieve high **line coverage** by exercising
the happy path, but have poor **mutation scores** because they pattern-match the
function signature rather than reason about edge cases and boundary conditions. The
practical quality gate: run Stryker on any module where AI-generated tests account for
>30 % of the test suite. A mutation score substantially below line coverage (e.g., 90 %
lines, 40 % MSI) is a signal that AI-generated tests are covering code without verifying
behaviour. Feed surviving mutants back to the LLM as context — mutation-guided prompting
("write a test that catches this specific fault injection") outperforms general "add more
tests" prompts in improving mutation scores.

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
// jest.config.ts — Jest 30.3+: use defineConfig for type-safe configuration
// Jest 30.3 added defineConfig and mergeConfig helpers; 30.4 added jest.config.mts support.
// Using defineConfig is now preferred over `import type { Config } from 'jest'`.
import { defineConfig } from 'jest';

export default defineConfig({
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
      // Jest 30.4+ behaviour: the global threshold is applied ONLY to files NOT matched
      // by any path or glob pattern below. If all files match a pattern, the global
      // falls back to applying against all covered files. This differs from Vitest,
      // where the global applies to ALL files simultaneously (see Pattern 31 / G50).
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
    // Negative thresholds: maximum uncovered entities (not percentage).
    // Use for rapidly growing modules where a percentage gate is too rigid:
    // './src/generated/': {
    //   statements: -50,  // allow up to 50 uncovered statements (not %)
    // },
  },
});
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

**Version note**: Stryker 9 (v9.6.1 as of May 2026) requires **Node 20+** and
**Vitest v2+** for the Vitest runner (Vitest v4 supported since Stryker 9.4.0). Projects
on Node 18 or Vitest v1 must stay on Stryker 8.x. The `concurrency` option accepts
percentage strings (`'50%'`) since v9.6.0 — useful for shared CI runners where CPU
count varies. Stryker 9.5.1 added Vitest fixtures support (`test.extend`) and the new
`testFiles` option to restrict which test files execute (see Pattern 23).

```typescript
// stryker.config.ts — Stryker 9 with Jest runner (Node 20+)
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
  concurrency: '50%',            // Stryker 9+: percentage-based — uses 50% of available CPUs
  // testFiles: ['src/**/*.test.ts'],  // Stryker 9.5+: optional — limit which tests run mutations
  // Incremental mode: only re-run mutants for files changed since last run
  incremental: true,
  incrementalFile: '.stryker-tmp/incremental.json',
};

export default config;
```

```bash
# Install Stryker 9 with TypeScript checker (Node 20+ required)
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

**esbuild/Vitest users**: esbuild strips block comments during TypeScript transpilation.
Append `-- @preserve` (official Vitest format) to keep ignore directives:
- `/* istanbul ignore next -- @preserve */` instead of `/* istanbul ignore next */`
- `/* v8 ignore next -- @preserve */` instead of `/* c8 ignore next */`
The older prefix form (`/* @preserve istanbul ignore next */`) also works in many Vitest
versions; the `-- @preserve` suffix is the format documented in official Vitest guides.
Without either form, all ignore directives are silently dropped in esbuild-transpiled projects.

**Multi-line block suppression with `start`/`stop`**: For suppressing coverage across
multiple consecutive lines, use the `start`/`stop` directive pair instead of repeating
`next` on each line:
- `/* istanbul ignore start -- @preserve */` — begins suppression
- `/* istanbul ignore stop -- @preserve */` — ends suppression

V8 supports an identical pattern: `/* v8 ignore start -- @preserve */` / `/* v8 ignore stop -- @preserve */`.

**Branch-selective V8 ignore directives (`if`/`else`)**: V8 also supports ignoring only one
side of a conditional branch — useful when one path is genuinely unreachable in tests but the
other is testable and should remain measured. These are more precise than `next` (which
suppresses the entire statement):
- `/* v8 ignore if -- @preserve */` — suppress the true/then branch only
- `/* v8 ignore else -- @preserve */` — suppress the false/else branch only

These are specific to the V8 provider (via `ast-v8-to-istanbul`). Istanbul does not have an
equivalent `if`/`else` branch-level directive — for Istanbul, `/* istanbul ignore next */` on
the branch statement suppresses both sides. Full V8 directive reference:
[ast-v8-to-istanbul ignore docs](https://github.com/AriPerkkio/ast-v8-to-istanbul?tab=readme-ov-file#ignoring-code).

```typescript
// src/config/env.ts — legitimate use: defensive runtime guard
export function requireEnvVar(name: string): string {
  const value = process.env[name];
  /* istanbul ignore next -- @preserve  unreachable in tests when env is always mocked */
  if (value === undefined) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}
```

```typescript
// src/generated/proto-types.ts — suppress entire generated file from coverage
/* istanbul ignore file -- @preserve */
// This file is auto-generated by protoc — do not add tests here.
export class GeneratedMessage {
  // auto-generated content
}
```

```typescript
// src/platform/os-guard.ts — multi-line suppression with start/stop
export function getPlatformConfig(): Record<string, string> {
  /* istanbul ignore start -- @preserve (platform-specific: only reachable on Windows CI) */
  if (process.platform === 'win32') {
    return { pathSep: '\\', eol: '\r\n', tempDir: 'C:\\Temp' };
  }
  /* istanbul ignore stop -- @preserve */
  return { pathSep: '/', eol: '\n', tempDir: '/tmp' };
}
```

```typescript
// src/utils/feature-flag.ts — V8-only: suppress only the else branch
// (V8 provider only — Istanbul has no if/else-selective equivalent)
export function getFeatureFlag(flag: string): boolean {
  const enabled = process.env[`FF_${flag}`] === 'true';
  /* v8 ignore else -- @preserve (disabled path not reachable in integration tests — always enabled) */
  if (enabled) {
    return true;
  } else {
    // This branch exists as a safety fallback but is never exercised in the test environment.
    return false;
  }
}
```

**V8 `if`/`else` directive quick reference:**
- `/* v8 ignore if -- @preserve */` — suppresses the **then** (true) branch only; the else branch is still measured
- `/* v8 ignore else -- @preserve */` — suppresses the **else** (false) branch only; the if branch is still measured
- Prefer these over `/* v8 ignore next */` for conditionals where one side is testable — they keep measurement on the reachable side
- These directives are specific to the V8 provider; Istanbul has no equivalent (Istanbul's `ignore next` suppresses both branches of the conditional)

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
      /* istanbul ignore next -- @preserve (exhaustiveness guard: TypeScript enforces all cases) */
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

### Pattern 20 — Stryker advanced performance configuration: ignoreStatic, disableTypeChecks, and prioritizePerformanceOverAccuracy  [community]

Three Stryker options that dramatically reduce CI mutation testing time but are
frequently overlooked during initial setup. Using `coverageAnalysis: 'perTest'`
without `ignoreStatic` leaves static mutants running the full test suite on every
mutation — often doubling wall-clock time on TypeScript projects.

```typescript
// stryker.config.ts — advanced performance-tuned configuration
import type { PartialStrykerOptions } from '@stryker-mutator/api/core';

const config: PartialStrykerOptions = {
  testRunner: 'vitest',
  vitest: { configFile: 'vitest.config.ts' },

  // Performance-critical options:
  coverageAnalysis: 'perTest',   // run only tests that cover each mutant (default since v5)
  ignoreStatic: true,            // skip mutants in static initializers — they run at load time,
                                  // not per-test, so perTest analysis can't optimise them.
                                  // Static mutations often constitute 10–20% of total mutants
                                  // and each runs the entire test suite. Skipping saves 10–25%
                                  // of total mutation time on TypeScript codebases with class fields.

  checkers: ['typescript'],
  tsconfigFile: 'tsconfig.json',

  // TypeScript checker performance option:
  // 'prioritizePerformanceOverAccuracy' (default: true) accepts mutants that fail to compile
  // with a "possible" verdict rather than re-checking them individually. In large TS projects,
  // this saves 20–40% of type-check overhead at the cost of a few false survivors (mutants
  // marked "survived" that should be "CompileError"). The DEFAULT is `true` — performance-first.
  // For nightly audit runs where full accuracy is required, set it to `false`:
  typescriptChecker: { prioritizePerformanceOverAccuracy: false },  // accurate mode for nightly

  // Prevent Stryker from failing on TypeScript errors in mutated source.
  // Mutants that introduce type errors are discarded before test execution:
  disableTypeChecks: '**/__mocks__/**/*.ts',  // disable type checking for mock files only

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
  // timeoutFactor: 1.5,  // (netTimeMs × timeoutFactor) + timeoutMS + overheadMs
                           // increase for slow integration suites to avoid false infinite-loop positives
  concurrency: 4,
  incremental: true,
  incrementalFile: '.stryker-tmp/incremental.json',
};

export default config;
```

**When each option applies:**
- `ignoreStatic: true` — always enable when using `coverageAnalysis: 'perTest'`; static mutants negate perTest savings
- `disableTypeChecks` — restrict to generated files and mocks; applying it to `src/**` defeats the TypeScript checker's purpose
- `prioritizePerformanceOverAccuracy` — **default is `true`** (performance-first). For PR runs this is correct: accept a few CompileError false survivors for speed. Set to `false` for nightly audit runs where every mutant classification must be precise. The configuration key is `typescriptChecker: { prioritizePerformanceOverAccuracy: false }` — NOT `TypeScript.checkerOptions` (that key does not exist).

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

**Node 23+ update**: Node 23+ (with `--experimental-strip-types` stabilizing toward
`--no-strip-types` in Node 24) supports native TypeScript coverage directly via the
built-in test runner's `--experimental-test-coverage` flag. The `c8` wrapper is no longer
required for basic coverage — Node handles it natively, including LCOV output.
Programmatic threshold enforcement is available via the `run()` API.

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
// package.json — native Node coverage with built-in test runner (no c8 required)
{
  "scripts": {
    "test": "node --experimental-strip-types --test src/**/*.test.ts",
    "test:coverage": "node --experimental-strip-types --test --experimental-test-coverage --test-reporter=lcov --test-reporter-destination=lcov.info src/**/*.test.ts"
  }
}
```

```typescript
// scripts/run-tests-with-thresholds.ts — programmatic Node test runner with thresholds
// Node 22+: use `run()` from node:test to enforce coverage thresholds inline
import { run } from 'node:test';
import process from 'node:process';

const stream = run({
  files: ['src/**/*.test.ts'],
  coverage: true,
  lineCoverage: 80,         // fail if < 80% line coverage
  branchCoverage: 75,       // fail if < 75% branch coverage
  functionCoverage: 80,     // fail if < 80% function coverage
});

stream.on('test:fail', () => process.exitCode = 1);
```

**Why this matters**: Node 22's `--experimental-strip-types` (Node 23+ further stabilised)
enables running TypeScript files directly without transpilation. The built-in
`--experimental-test-coverage` flag collects V8 coverage natively with zero external
tooling — no `c8`, no Jest, no Vitest. Branch detection has the same characteristics as
the V8 provider in Vitest < 3.2 (coarser than Istanbul); use `c8` or Vitest 3.2+ V8
AST remapping for accurate branch tracking in complex TypeScript expressions.

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

### Pattern 21 — Jest negative thresholds for fast-growing TypeScript modules  [community]

Jest supports **negative threshold values** as an alternative to percentage-based gates.
A negative value specifies the maximum number of **uncovered entities** allowed, rather than
a minimum percentage. This is more stable for rapidly-growing modules where the percentage
moves with every added function — a negative threshold holds the absolute gap constant.

```typescript
// jest.config.ts — using negative thresholds for controlled legacy debt
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts', '!src/**/index.ts'],
  coverageProvider: 'v8',
  coverageThreshold: {
    global: {
      lines: 80,
      branches: 75,
      functions: 80,
      statements: 80,
    },
    // Legacy module with known debt: allow up to 15 uncovered branches (not a percentage).
    // As new tests are added the count decreases; the gate tightens without manual updates.
    './src/legacy/billing.ts': {
      branches: -15,     // max 15 uncovered branches allowed
      statements: -30,   // max 30 uncovered statements allowed
    },
    // Rapidly-growing new module: hold the gap at most 5 uncovered functions.
    // When functions are added WITH tests, count stays at 0; without tests it rises.
    './src/features/checkout/': {
      functions: -5,     // max 5 uncovered functions in the checkout feature directory
    },
  },
};

export default config;
```

**When to use negative thresholds:**
- Legacy modules being incrementally tested: percentage moves unpredictably as the file grows; absolute count is stable
- Teams in a coverage improvement sprint: set the initial negative count, tighten it each sprint
- Generated code with a fixed number of untestable branches: set `-N` to match the known count, prevent drift

**Limitation**: negative thresholds do not work with Vitest — Vitest only supports percentage-based
`thresholds`. Use Jest or the programmatic approach (Pattern 17) for absolute-count enforcement.

### Pattern 22 — Merging coverage from parallel sharded Vitest runs in GitHub Actions  [community]

Running tests in parallel across multiple CI shards significantly reduces wall-clock time,
but each shard produces its own coverage data. Without merging, only the last shard's
coverage is reported, or coverage is silently missing for test files run on other shards.
Vitest 1.4+ supports `--merge-reports` to combine blob reports from multiple shards.

```yaml
# .github/workflows/test-sharded.yml — parallel sharding with coverage merge
name: Sharded Tests with Coverage

on: [pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shard: [1, 2, 3, 4]      # 4 parallel shards
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - run: npm ci

      - name: Run Vitest shard ${{ matrix.shard }}
        run: |
          npx vitest run \
            --shard=${{ matrix.shard }}/4 \
            --coverage \
            --coverage.reporter=json \
            --reporter=blob \                  # blob reporter for merge
            --outputFile=reports/blob-${{ matrix.shard }}.json

      - name: Upload shard blob report
        uses: actions/upload-artifact@v4
        with:
          name: blob-report-${{ matrix.shard }}
          path: reports/blob-${{ matrix.shard }}.json

  merge-coverage:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - run: npm ci

      - name: Download all shard blob reports
        uses: actions/download-artifact@v4
        with:
          pattern: blob-report-*
          path: reports/

      - name: Merge Vitest reports and coverage
        run: npx vitest --merge-reports=reports/ --coverage

      - name: Upload merged coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage/lcov.info
          token: ${{ secrets.CODECOV_TOKEN }}
```

```typescript
// vitest.config.ts — configure blob reporter and per-shard coverage output
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',                // Vitest 3.2+: AST-remapped V8 = Istanbul accuracy
      reporter: ['json', 'lcov'],    // json for blob merge, lcov for Codecov
      reportsDirectory: './coverage',
      include: ['src/**/*.ts'],
      all: true,
    },
  },
});
```

**Key points:**
- Each shard runs with `--reporter=blob` to produce a mergeable blob file
- The `merge-coverage` job downloads all shard blobs and runs `--merge-reports` to produce a unified coverage report
- Coverage thresholds are checked only in the merge job — not per-shard — to avoid false failures on partial test runs
- Without merging, coverage from shards 2-4 is simply discarded; aggregate numbers are artificially low

### Pattern 23 — Stryker `testFiles` option: per-module mutation validation  [community]

Stryker 9.5.1 introduced the `testFiles` option, which restricts which test files are
executed when killing mutants. The use case: verify that a module's dedicated unit tests
can independently kill all of its mutants, without relying on integration or e2e tests
that happen to exercise the same code. This is a stricter quality gate than full-suite
mutation testing — it ensures that the module's own test suite is self-sufficient.

```typescript
// stryker.config.ts — validate that payments unit tests kill all payment mutants
import type { PartialStrykerOptions } from '@stryker-mutator/api/core';

const config: PartialStrykerOptions = {
  testRunner: 'vitest',
  vitest: { configFile: 'vitest.config.ts' },
  coverageAnalysis: 'perTest',
  checkers: ['typescript'],
  tsconfigFile: 'tsconfig.json',
  mutate: [
    'src/payments/**/*.ts',         // only mutate the payments module
    '!src/payments/**/*.test.ts',
    '!src/payments/**/*.spec.ts',
  ],
  // Restrict test execution to payments unit tests only.
  // Without this, Stryker uses ALL test files — mutants might be killed by
  // integration tests rather than the payment module's own unit tests.
  testFiles: [
    'src/payments/**/*.test.ts',
    'src/payments/**/*.spec.ts',
  ],
  thresholds: {
    high: 80,
    low: 60,
    break: 50,
  },
  reporters: ['html', 'progress', 'json'],
  incremental: true,
  incrementalFile: '.stryker-tmp/incremental.json',
};

export default config;
```

```bash
# Run per-module validation on payments (unit tests only)
npx stryker run --testFiles 'src/payments/**/*.test.ts'

# Run per-module validation as part of a CI job matrix:
# matrix.module: [payments, auth, validation, notifications]
npx stryker run \
  --mutate "src/${{ matrix.module }}/**/*.ts" \
  --testFiles "src/${{ matrix.module }}/**/*.test.ts"
```

**When to use this pattern**: when building confidence that each module owns and kills
its own mutants, rather than relying on broader integration coverage. A module that
scores 80 % MSI using the full test suite but only 40 % using its own unit tests is a
signal that the unit test case suite is under-tested and integration tests are carrying
the mutation score.

### Pattern 24 — Vitest 4 dynamic coverage control: `enableCoverage` / `disableCoverage`  [community]

Vitest 4 introduced `enableCoverage()` and `disableCoverage()` in the programmatic API,
allowing test suites to selectively toggle coverage collection at runtime. The primary
use case: skip coverage collection for test setup/teardown sections that import many
modules without executing business logic — these inflate coverage artificially while
adding instrumentation overhead.

```typescript
// scripts/selective-coverage-run.ts — programmatic Vitest 4 API with dynamic coverage control
import { startVitest } from 'vitest/node';

async function runWithSelectiveCoverage(): Promise<void> {
  const vitest = await startVitest('test', [], {
    coverage: {
      provider: 'v8',               // Vitest 3.2+ AST remapping: V8 = Istanbul accuracy
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts', 'src/**/index.ts', 'src/**/__mocks__/**'],
      all: true,
      reporter: ['text-summary', 'lcov', 'json-summary'],
      thresholds: {
        lines: 80,
        branches: 75,
        functions: 80,
        statements: 80,
      },
    },
  });

  if (!vitest) throw new Error('Vitest failed to start');

  // Coverage is enabled by default when the coverage option is configured.
  // Disable it during setup-heavy test files to reduce overhead:
  await vitest.coverage.provider?.disableCoverage();

  // Re-enable before running business logic tests:
  await vitest.coverage.provider?.enableCoverage();

  await vitest.close();
}

runWithSelectiveCoverage().catch((err) => {
  console.error('Coverage run failed:', err);
  process.exit(1);
});
```

```typescript
// Alternative: use enableCoverage/disableCoverage in a custom test setup file
// vitest-setup.ts — disable coverage during test infrastructure setup
import { enableCoverage, disableCoverage } from 'vitest';

// These APIs are experimental in Vitest 4.0 — check current docs before production use.
// Use case: skip coverage on test helper imports that pollute the coverage report.
beforeAll(async () => {
  // Do expensive module setup without coverage instrumentation overhead:
  await import('./test-helpers/db-seed');
  await import('./test-helpers/mock-server');
  // Re-enable before the actual test cases run:
});
```

**Important caveats**: `enableCoverage`/`disableCoverage` are part of Vitest 4's
experimental programmatic API. They are most useful in monorepo setups where test
infrastructure modules (database seeders, mock servers, fixture loaders) would otherwise
inflate coverage numbers. For most projects, standard config-based coverage (Patterns 1–2)
is sufficient and less complex.

### Pattern 26 — Vitest 4.1 `coverage.changed`: built-in differential coverage on changed files  [community]

Vitest 4.1 introduced `coverage.changed` as a first-class config option. Unlike external
tools such as Codecov's `patch_coverage_threshold` (Pattern 15), `coverage.changed` runs
the **entire test suite** but restricts the coverage **report** to files modified since a
given git reference. This is the lowest-friction path to differential coverage for Vitest
projects — no additional tooling required.

`coverage.changed` accepts:
- `true` — reports coverage only for files with staged or unstaged local changes
- A branch name (e.g., `'main'`) — files changed vs that branch
- A commit hash — files changed since that commit

```typescript
// vitest.config.ts — built-in differential coverage (Vitest 4.1+)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',             // Vitest 3.2+: AST-remapped V8 = Istanbul accuracy
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts', 'src/**/index.ts', 'src/**/__mocks__/**'],
      all: true,
      reporter: ['text', 'html', 'lcov', 'json-summary'],
      reportsDirectory: './coverage',
      // Report coverage only for files changed vs main — Vitest 4.1+.
      // Does NOT restrict which tests run; all tests execute.
      // Only the coverage report is filtered to changed files.
      changed: 'main',
      thresholds: {
        lines: 80,
        branches: 75,
        functions: 80,
        statements: 80,
        perFile: true,            // per-file thresholds applied to changed files only
      },
    },
  },
});
```

```yaml
# .github/workflows/coverage-changed.yml — PR coverage gate on changed files (Vitest 4.1+)
name: Coverage (changed files)

on: [pull_request]

jobs:
  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # full history required for changed file detection
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - run: npm ci

      - name: Run tests with changed-only coverage
        # --coverage.changed=origin/main: report coverage only for PR diff
        # All tests still run; thresholds apply only to changed files
        run: npx vitest run --coverage --coverage.changed=origin/main

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage-report
          path: coverage/
```

**`coverage.changed` vs `--changed` CLI flag**: these are different options:
- `--changed` (test selection): restricts which **tests** run to those covering changed files.
  Risks missing tests for unchanged source that a changed test covers.
- `coverage.changed` (coverage filter): runs **all tests**, shows **coverage only** for changed
  files. All test execution happens; only the report is filtered.

**Comparison with Pattern 15 (Codecov `patch_coverage_threshold`)**:
- Pattern 15 requires Codecov integration and uploads LCOV to an external service.
- `coverage.changed` works entirely locally with no external service.
- `coverage.changed` is preferred for projects not using Codecov; Pattern 15 is better when
  you need the Codecov dashboard, PR comments, and historical coverage trends.

### Pattern 27 — Vitest `coverage.thresholds.autoUpdate`: automatic threshold ratchet  [community]

Manually maintaining coverage thresholds is error-prone — teams forget to raise them
as coverage improves, and the threshold becomes stale (testing that coverage is at least
what it was two years ago, not what it should be today). Vitest's `autoUpdate` option
automatically raises threshold values in the config file whenever coverage improves,
creating a self-tightening ratchet without any manual step.

```typescript
// vitest.config.ts — automatic threshold ratchet (Vitest 4.1+)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts', 'src/**/index.ts', 'src/**/__mocks__/**'],
      all: true,
      reporter: ['text', 'html', 'lcov'],
      thresholds: {
        lines: 82,
        branches: 77,
        functions: 84,
        statements: 82,
        perFile: false,           // autoUpdate works on global thresholds; perFile is a separate check
        // When autoUpdate is true: if coverage exceeds the threshold, Vitest rewrites
        // this config file in place, bumping lines/branches/functions/statements to the
        // new coverage level. The threshold then acts as a hard floor that only moves up.
        autoUpdate: true,
      },
    },
  },
});
```

```typescript
// vitest.config.ts — autoUpdate with custom formatter (control rounding/precision)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts', 'src/**/__mocks__/**'],
      all: true,
      thresholds: {
        lines: 82,
        branches: 77,
        functions: 84,
        statements: 82,
        // Pass a function to customise how the updated threshold is rounded:
        // autoUpdate: (coverage) => Math.floor(coverage)  — always round down (conservative)
        // This prevents frequent config changes from floating point coverage numbers.
        autoUpdate: (coverage: number) => Math.floor(coverage),
      },
    },
  },
});
```

```bash
# Run tests and auto-update thresholds if coverage improved
npx vitest run --coverage

# In CI: run normally — if coverage drops below current threshold, CI fails.
# Do NOT run with autoUpdate in CI — it would modify the config file mid-run and
# commit the change, which is not the intent. Reserve autoUpdate for local
# developer runs or a dedicated "update thresholds" workflow step.

# Recommended CI pattern:
# 1. Local dev: npx vitest run --coverage  → autoUpdate raises threshold if coverage improved
# 2. CI: npx vitest run --coverage --no-coverage.thresholds.autoUpdate  → fail on regression
```

**Production workflow with `autoUpdate`**:
1. Developer improves code + adds tests — coverage rises.
2. `vitest run --coverage` runs locally — `autoUpdate` bumps the threshold in `vitest.config.ts`.
3. Developer commits the updated config alongside the new tests.
4. CI enforces the new (higher) threshold from that commit forward.
5. Next developer cannot ship a PR that drops coverage below the new floor.

**When NOT to use `autoUpdate`**: CI pipelines. `autoUpdate` writes to the config file during
the test run. A CI runner that enables `autoUpdate` would either (a) fail to commit the
updated config, or (b) create unexpected config mutations in the working tree. Disable it
in CI with `autoUpdate: false` in a CI-specific `vitest.config.ci.ts`, or check that the
option is not set when the `CI` environment variable is `true`.

### Pattern 25 — Stryker `ignorers` plugin: custom mutation suppression patterns  [community]

Stryker 7.3+ introduced a plugin-based `ignorers` system for suppressing mutations across
entire code patterns — more powerful than per-line `// Stryker disable` comments when you
need to exclude recurring patterns across many files. The built-in Angular ignorer ships
with `@stryker-mutator/core`; custom ignorers can be written for any framework.

Unlike `// Stryker disable` line comments (which suppress single lines) or `disableTypeChecks`
(which prevents TypeScript compilation checks on mutants in matched files), `ignorers`
operate at the AST node level — you specify a visitor that returns `true` to exclude
a node from mutation.

```typescript
// stryker.config.ts — using a custom ignorer for dependency injection containers
import type { PartialStrykerOptions } from '@stryker-mutator/api/core';

const config: PartialStrykerOptions = {
  testRunner: 'vitest',
  vitest: { configFile: 'vitest.config.ts' },
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
  incremental: true,
  incrementalFile: '.stryker-tmp/incremental.json',
  // The ignorers plugin is most commonly needed for Angular (built-in):
  // plugins: ['@stryker-mutator/core/angular-ignorer'],
  // For custom ignorers: plugins: ['./stryker-ignorers/di-container-ignorer.js'],
};

export default config;
```

```typescript
// stryker-ignorers/di-container-ignorer.ts — suppress mutations inside DI container registrations
// Mutations inside container.register() calls rarely represent testable logic:
// they configure wiring, not behaviour. Mutating them produces timeouts, not failures.
import type { Ignorer, NodePath } from '@stryker-mutator/api/ignore';

export class DiContainerIgnorer implements Ignorer {
  shouldIgnore(path: NodePath): string | undefined {
    // Ignore mutations inside InversifyJS/Awilix/NestJS provider registration calls:
    if (
      path.isCallExpression() &&
      path.node.callee &&
      'property' in path.node.callee &&
      typeof (path.node.callee as any).property?.name === 'string' &&
      ['register', 'bind', 'provide', 'useClass', 'useFactory'].includes(
        (path.node.callee as any).property.name
      )
    ) {
      return 'DI container registration — mutating provider wiring tests infrastructure, not behaviour';
    }
    return undefined;  // undefined = allow mutation
  }
}
```

```bash
# Install and configure custom ignorer (Stryker 7.3+)
# 1. Write the ignorer class (see above)
# 2. Add to plugins array in stryker.config.ts
# 3. Run normally — Stryker will load the ignorer at startup:
npx stryker run

# Verify which mutants are being ignored (use HTML report):
# Open reports/mutation/index.html → filter by status "Ignored"
```

**When to use `ignorers` vs `// Stryker disable`:**
- `ignorers` — recurring structural patterns (decorator registrations, DI containers,
  generated enum mappings) that appear in dozens of files. Write once, apply everywhere.
- `// Stryker disable all` — one-off suppression for a specific function or block whose
  mutants are genuinely untestable (e.g., Vitest in-source test blocks, see G25).
- `disableTypeChecks: '<glob>'` — suppress TypeScript compilation checks on generated files
  where type errors are expected (mocks, generated protobuf output). Not a mutation suppressor.

**Stryker 9.6.0 note**: the string-literal mutator now automatically excludes dynamic
import call expressions from mutation (`import('./module')`). Dynamic imports were
previously mutated to empty strings, causing module-not-found errors that inflated
timeout counts. This change reduces noise in projects using dynamic imports for
code splitting.

### Pattern 28 — Vitest `coverage.reportOnFailure` and `coverage.watermarks`: coverage data on failing runs and visual thresholds  [community]

Two Vitest coverage options are frequently overlooked during initial setup. `reportOnFailure`
ensures coverage data is written even when tests fail — critical for debugging test failures
that are tied to coverage gaps. `watermarks` controls the colour-coded thresholds used in the
HTML and terminal reporters, making it easy to see at a glance which files are well-covered
(green), acceptable (yellow), or under-tested (red).

```typescript
// vitest.config.ts — reportOnFailure + watermarks for richer CI feedback
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts', 'src/**/__mocks__/**', 'src/**/index.ts'],
      all: true,
      reporter: ['text', 'html', 'lcov', 'json-summary'],
      reportsDirectory: './coverage',

      // Write a coverage report even when test cases fail.
      // Without this, a failing test run produces no coverage artefact —
      // CI jobs that upload to Codecov or download the HTML report then
      // fail on a missing artefact, masking the original test failure.
      // Set to true when you need coverage data for a debugging session
      // on a partially broken test suite.
      reportOnFailure: true,

      // Colour thresholds for the HTML and text reporters (default: [50, 80]).
      // Files below the first number appear red; between the two numbers, yellow;
      // above the second number, green. Adjust to match your team's quality bar
      // rather than relying on the library defaults.
      watermarks: {
        statements: [70, 90],
        functions: [70, 90],
        branches: [65, 85],
        lines: [70, 90],
      },

      thresholds: {
        lines: 80,
        branches: 75,
        functions: 80,
        statements: 80,
        perFile: true,
      },
    },
  },
});
```

**`reportOnFailure` production pattern**: in GitHub Actions, always set `reportOnFailure: true`
on CI coverage jobs so the HTML artefact upload step does not fail when one test case breaks.
The coverage report helps diagnose *which* branches the failing test is responsible for — without
it, debugging requires another full run after the fix. The option does **not** change exit codes:
Vitest still exits non-zero when tests fail; it only guarantees coverage files are written.

**`watermarks` tuning**: the default `[50, 80]` range means files at 50–80 % appear yellow.
Teams whose global threshold is 75 % often lower the yellow floor to `[60, 80]` so yellow
indicates meaningful work remaining (60–80 %) rather than including files near the minimum.
Watermarks affect only the visual display — they do not gate CI. Pair watermarks with
`thresholds` for hard enforcement.

### Pattern 29 — Vitest `coverage.processingConcurrency`, `coverage.allowExternal`, and `coverage.cleanOnRerun`  [community]

Three Vitest coverage options that are rarely documented but matter in specific project setups:
`processingConcurrency` for large monorepos, `allowExternal` for shared library coverage, and
`cleanOnRerun` for watch-mode incremental development.

```typescript
// vitest.config.ts — advanced coverage control options
import { defineConfig } from 'vitest/config';
import os from 'node:os';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',              // Vitest 3.2+: AST-remapped V8 = Istanbul accuracy
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts', 'src/**/__mocks__/**', 'src/**/index.ts'],
      all: true,
      reporter: ['text', 'html', 'lcov', 'json-summary'],
      reportsDirectory: './coverage',

      // Limit how many coverage result files are processed in parallel.
      // Default: Math.min(20, os.availableParallelism() || os.cpus().length)
      // Lower this on resource-constrained CI runners (e.g., 2-vCPU GitHub Actions
      // free tier) to prevent OOM crashes during large Istanbul coverage merges.
      // Raise it on high-CPU runners (32+ vCPU) to speed up post-collection processing.
      processingConcurrency: Math.min(4, os.availableParallelism?.() ?? os.cpus().length),

      // Include coverage for files outside the project root (default: false).
      // Use case: monorepo packages where source lives in a sibling directory
      // (e.g., ../../shared-lib/src). Without allowExternal: true, these files
      // are silently excluded from coverage even if tests import them.
      allowExternal: false,         // set to true for cross-package coverage in monorepos

      // Whether to clean coverage data between watch-mode reruns (default: true).
      // With cleanOnRerun: true  — each watch rerun shows coverage only for the
      //   re-executed tests. Accurate per-rerun snapshot but not cumulative.
      // With cleanOnRerun: false — coverage accumulates across watch reruns,
      //   giving a running total as you iteratively fix tests. Useful during
      //   a focused debugging session on a single module.
      cleanOnRerun: true,

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

```typescript
// Alternative: thresholds.100 shortcut — require 100 % on all metrics
// Use for pure utility libraries or critical security modules where
// any gap is unacceptable. Equivalent to setting lines/branches/functions/statements to 100.
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',
      include: ['src/utils/**/*.ts'],       // scope to a specific well-tested sub-tree
      exclude: ['src/utils/**/*.d.ts'],
      all: true,
      reporter: ['text', 'html'],
      thresholds: {
        // Shorthand for lines: 100, branches: 100, functions: 100, statements: 100
        100: true,                          // Vitest 4.x+: any gap fails CI immediately
        perFile: true,
      },
    },
  },
});
```

**`processingConcurrency` guidance**: the default dynamically scales to available CPUs. Only
override it when coverage post-processing is causing OOM (reduce) or when you have a large
CI runner and want faster merge times (increase). Monitor `coverage/` directory write times
in CI — if it takes more than 30 s after tests complete, the processing step is the bottleneck.

**`allowExternal: true` warning**: enabling it without also setting explicit `include` patterns
can pull in coverage data for `node_modules` or other unintended external paths. Always pair
`allowExternal: true` with a narrow `include` that names the specific external paths you want.

**`cleanOnRerun: false` in watch mode**: most useful during TDD sessions where you are building
up coverage incrementally on a new module. Set `cleanOnRerun: false` in your local
`vitest.config.local.ts` (git-ignored) and keep `cleanOnRerun: true` in the committed config
so CI always measures a fresh run.

### Pattern 30 — Stryker `allowEmpty` and `incremental.force`: CI dry-run safety and baseline reset  [community]

Two Stryker options that are critical for edge cases in CI pipelines and incremental mutation
testing workflows, but are rarely included in getting-started guides.

**`allowEmpty`** prevents Stryker from failing when the initial dry run finds no tests for a
mutant. In CI matrix jobs that scope mutations to a specific module, some modules may have
no test files in the `testFiles` glob — without `allowEmpty: true`, Stryker exits with a
hard error before running any mutations.

**`incremental: true` with `force: true`** forces a full re-mutation run even when a valid
incremental state file exists. Use this after significant test refactors, tool version upgrades
(Stryker 9.6.1 + Vitest 4.1 hitcount fix — see G41), or when you suspect the incremental
baseline is stale.

```typescript
// stryker.config.ts — CI-hardened configuration with allowEmpty and incremental.force
import type { PartialStrykerOptions } from '@stryker-mutator/api/core';

const isForceReset = process.env.STRYKER_FORCE_RESET === 'true';

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
  ignoreStatic: true,

  // Incremental mode: persist mutation state across runs.
  incremental: true,
  incrementalFile: '.stryker-tmp/incremental.json',

  // Force a full re-run even if an incremental state file exists.
  // Use in CI when upgrading Stryker or Vitest to invalidate stale baselines.
  // Toggle via env var: STRYKER_FORCE_RESET=true npx stryker run
  ...(isForceReset ? { force: true } : {}),

  // Allow Stryker to complete even when some mutants have no covering tests.
  // Critical for CI matrix jobs scoped to a single module where some patterns
  // may produce mutants with zero test coverage (NoCoverage status).
  // Without this: Stryker exits code 1 with "No tests were executed" when a
  // module's test files are missing or the testFiles glob matches nothing.
  allowEmpty: true,
};

export default config;
```

```bash
# Force a full mutation baseline reset (e.g., after Stryker 9.6.1 upgrade for Vitest 4.1 fix):
STRYKER_FORCE_RESET=true npx stryker run

# Standard incremental run (typical PR workflow):
npx stryker run --since=origin/main

# Verify incremental file is being used (log shows "Using incremental report"):
npx stryker run --logLevel=info 2>&1 | grep -i incremental
```

**`allowEmpty` vs `force`**:
- `allowEmpty: true` — allow mutants with `NoCoverage` status to not block the run. Does NOT
  change the mutation score; `NoCoverage` mutants are counted the same as `Survived` mutants
  in the final report unless your threshold logic excludes them. The option only prevents the
  "no tests found" hard error from aborting the entire run.
- `force: true` — ignores any existing incremental state and re-runs all mutants from scratch.
  After the run completes, the incremental file is rewritten with the fresh results. Use for
  baseline reset events: tool upgrades, test refactors, or when the incremental file has grown
  stale (e.g., after removing many test files).

### Pattern 31 — Vitest per-glob-pattern thresholds: risk-tiered enforcement without per-workspace split  [community]

Vitest's `coverage.thresholds` supports **glob pattern keys** in addition to the global scalar values
and the `perFile` boolean. This allows risk-tiered threshold enforcement within a single package without
requiring a separate `vitest.config.ts` per directory — useful for monolith TypeScript projects or
repos where splitting workspaces is not practical.

**Critical behavioural difference from Jest**: Vitest counts files matching glob-pattern threshold keys
**also toward the global threshold calculation**. In Jest, `coverageThreshold['./src/payments/']` is
evaluated only for files in that directory and does not double-count toward the global aggregate.
In Vitest, a file matching `'**/payments/**'` contributes to both the pattern threshold AND the global
threshold simultaneously. This means setting a strict per-pattern threshold does NOT prevent a file from
also being measured against the global floor.

```typescript
// vitest.config.ts — risk-tiered glob-pattern thresholds (Vitest 4.x+)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',             // Vitest 3.2+: AST-remapped V8 = Istanbul accuracy
      include: ['src/**/*.ts'],
      exclude: [
        'src/**/*.d.ts',
        'src/**/index.ts',
        'src/**/__mocks__/**',
        'src/**/*.stories.ts',
      ],
      all: true,
      reporter: ['text', 'html', 'lcov', 'json-summary'],
      reportsDirectory: './coverage',

      thresholds: {
        // Global floor — all files must meet this minimum.
        // Note: files matching glob patterns below ALSO count toward this global calculation.
        lines: 80,
        branches: 75,
        functions: 80,
        statements: 80,

        // Critical modules — stricter branch and line requirements.
        // Files here are evaluated against both this pattern threshold AND the global above.
        'src/payments/**/*.ts': {
          lines: 95,
          branches: 90,
          functions: 95,
          statements: 95,
        },
        'src/auth/**/*.ts': {
          lines: 92,
          branches: 88,
          functions: 92,
          statements: 92,
        },

        // Utility/pure-function modules — 100% shortcut (all metrics → 100).
        // The `100: true` shorthand is equivalent to lines: 100, branches: 100,
        // functions: 100, statements: 100 applied to matching files only.
        'src/utils/math*.ts': {
          100: true,
        },

        // Infrastructure / generated modules — lower floor, no per-file enforcement.
        // Setting values below the global floor is valid (acts as an explicit exemption):
        'src/generated/**/*.ts': {
          lines: 0,
          branches: 0,
          functions: 0,
          statements: 0,
        },
      },
    },
  },
});
```

**Important caveats:**

1. **Global threshold still applies** — a file matching `'src/payments/**/*.ts'` is measured against
   BOTH the `payments` pattern threshold (branches: 90) AND the global (branches: 75). A payment file
   at 88 % branch coverage fails the pattern threshold but passes the global. The test run will exit
   non-zero from the pattern failure regardless.

2. **Unspecified metrics are NOT inherited from global** — if a pattern threshold only specifies
   `branches: 90`, the `lines`, `functions`, and `statements` metrics for matching files are **not**
   automatically set to the global values for that pattern. Only the global threshold applies for
   unspecified metrics. This means `'src/payments/**/*.ts': { branches: 90 }` enforces 90 % branches
   AND the global 80 % for lines/functions/statements — but the pattern itself does not know about the
   global values; they are evaluated independently.

3. **Glob matching uses the same engine as `include`/`exclude`** — in Vitest 5.0+, bare directory
   names in threshold keys are NOT auto-expanded (see G45). Use explicit globs:
   `'src/payments/**/*.ts'` not `'src/payments'`.

**Jest vs Vitest glob threshold comparison:**

| Behaviour | Jest `coverageThreshold['./src/payments/']` | Vitest `thresholds['src/payments/**/*.ts']` |
|-----------|---------------------------------------------|----------------------------------------------|
| Per-directory/pattern enforcement | Yes | Yes |
| Glob syntax | No — directory path only | Yes — full minimatch glob |
| Files count toward global | No — independent | Yes — also evaluated against global |
| Unspecified metrics | Inherit global | Not inherited — independently evaluated |
| Negative thresholds (absolute count) | Yes (`-N`) | No — percentage only |

### Pattern 32 — `@fast-check/vitest`: dedicated property-based test integration with Vitest 4.1+  [community]

fast-check 4.x ships `@fast-check/vitest`, a dedicated integration package that replaces the
manual `it(...) + fc.assert(...)` pairing from Pattern 12 with `fc.test()` — a first-class
Vitest-aware wrapper that surfaces property failures in Vitest's native test reporter and
provides type-safe hook support (`fc.beforeEach`, `fc.afterEach`) for stateful model testing.

**Why this matters for coverage**: `@fast-check/vitest` registers each property test as a
native Vitest test case. This means:
- Coverage is collected per-property-run, not just per `fc.assert()` call — Vitest sees all
  generated test cases as part of its instrumentation scope.
- `fc.test.failing()` (the property-based equivalent of `test.fails()`) integrates with
  Vitest's known-failure tracking, avoiding false-positive coverage inflation from expected
  property failures.
- In Vitest's AI agent reporter mode (G37), `@fast-check/vitest` property failures are
  reported as structured test failures rather than raw assertion errors — easier to parse.

```bash
# Install dedicated Vitest integration (fast-check 4.x + Vitest 4.1+)
npm install --save-dev fast-check @fast-check/vitest
```

```typescript
// src/utils/clamp.test.ts — using @fast-check/vitest (replaces manual fc.assert)
import { describe, expect } from 'vitest';
import { fc, test } from '@fast-check/vitest';
import { clamp } from './clamp';

// Note: use `test` from @fast-check/vitest, not from vitest, for property tests.
// `describe` and `expect` are still imported from vitest.

describe('clamp — property tests with @fast-check/vitest', () => {
  // fc.test replaces the it(...) + fc.assert(...) pattern from Pattern 12:
  test.prop([
    fc.integer(),
    fc.integer(),
    fc.integer(),
  ])('always returns a value within [min, max]', (a, b, c) => {
    const [min, max] = [Math.min(b, c), Math.max(b, c)];
    const result = clamp(a, min, max);
    expect(result).toBeGreaterThanOrEqual(min);
    expect(result).toBeLessThanOrEqual(max);
  });

  test.prop([
    fc.integer({ min: -1000, max: 1000 }),
    fc.integer({ min: 0, max: 100 }),
  ])('is idempotent: clamp(clamp(x)) === clamp(x)', (value, range) => {
    const once = clamp(value, 0, range);
    const twice = clamp(once, 0, range);
    expect(twice).toBe(once);
  });
});
```

```typescript
// src/domain/account.test.ts — stateful property test with beforeEach
// @fast-check/vitest provides fc.beforeEach for stateful model testing:
import { describe, expect } from 'vitest';
import { fc, test } from '@fast-check/vitest';
import { Account } from './account';

describe('Account — stateful property test', () => {
  // fc.beforeEach runs before each generated test case (not per property group):
  // Use this to reset shared state between property runs.
  test.prop([
    fc.integer({ min: 1, max: 10000 }),  // initial balance
    fc.integer({ min: 1, max: 500 }),    // withdrawal amount
  ], { numRuns: 200 })('balance never goes negative after guarded withdrawal', (initial, amount) => {
    const account = new Account(initial);
    account.withdrawIfSufficient(amount);
    expect(account.balance).toBeGreaterThanOrEqual(0);
  });
});
```

```typescript
// Equivalent manual pattern (Pattern 12 style — still valid, no deprecation):
import * as fc from 'fast-check';
import { it } from 'vitest';
import { clamp } from './clamp';

it('always within range', () => {
  fc.assert(
    fc.property(fc.integer(), fc.integer(), fc.integer(), (a, b, c) => {
      const [min, max] = [Math.min(b, c), Math.max(b, c)];
      const result = clamp(a, min, max);
      return result >= min && result <= max;
    }),
  );
});
// The @fast-check/vitest form (test.prop) is preferred for Vitest 4.1+ projects
// because it integrates with Vitest's test reporter and makes property failures
// easier to read in CI output and the Vitest UI.
```

**fast-check 4.x new arbitraries relevant to TypeScript coverage:**
- `fc.chainUntil` (v4.8.0): iterative chaining — generates a sequence of values until a
  predicate is satisfied. Useful for generating valid state machine inputs in property tests.
- `fc.stringMatching` with Unicode property escapes (`\p{}`, `\P{}`) (v4.7.0): generates
  strings matching complex regex patterns including Unicode category constraints.
- `json` arbitrary with `reversible: true`: generates JSON round-trip safe values — useful
  for testing serialisation branches.

**When to use `@fast-check/vitest` vs manual `fc.assert`:**
- New Vitest 4.1+ projects: use `@fast-check/vitest` for cleaner output and hook support.
- Existing codebases with many `fc.assert()` calls: the manual form still works; migrate
  incrementally by adding `test.prop` for new tests.
- The `@fast-check/vitest` package also exports `fc.describe()` and scoped runner utilities —
  check the package README for the full API (it tracks fast-check major releases).

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
`/* istanbul ignore next -- @preserve */` and `/* v8 ignore next -- @preserve */` directives exist for genuinely
unreachable branches (generated code, defensive platform guards). They are often
misused to silence coverage failures on recently added code paths that are simply not
yet tested. A PR that introduces new logic alongside suppress comments is a red flag.

**Policy**: Suppress comments in `src/` directories require a PR comment justifying
the exemption. TypeScript's exhaustive type checking (`never`) can sometimes replace
coverage suppress — prefer type-safe unreachability proofs over ignore directives.
Use `start`/`stop` directive pairs for multi-line suppression rather than repeating
`next` on every line in a block.

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

### AP12 — Enforcing coverage thresholds per-shard in parallel CI without merging  [community]
In GitHub Actions matrix builds where each shard runs a subset of tests, teams
mistakenly add `thresholds` to the Vitest config and run coverage checks per-shard.
Each shard only executes 25 % (or 1/N) of the tests, so each shard only covers its own
test files. A shard passes threshold checks not because coverage is adequate, but because
the uncovered source files are excluded from that shard's report entirely. The CI shows
all shards green; the merged codebase may have 40 % actual coverage.

**WHY it's dangerous**: per-shard threshold checks create false confidence. The only
valid coverage gate in a sharded pipeline is on the **merged report**. Remove
`thresholds` from the shared `vitest.config.ts` and add them only to the merge job
that calls `vitest --merge-reports`. The merge job fails if merged coverage is below
threshold; individual shard jobs never check coverage thresholds.

### AP13 — Relying on abandoned LLM-coverage-gap tools (Qodo Cover / Codium cover-agent)  [community]
The Codium `cover-agent` repository (later rebranded as Qodo Cover), which was widely
cited as a turnkey solution for using LLMs to fill TypeScript and Python coverage gaps,
was **archived and marked as no longer maintained in June 2025**. Teams that integrated
cover-agent into their CI pipelines to automatically generate tests for uncovered branches
are now running a deprecated, unsupported tool.

**WHY it matters**: abandoned tooling in CI pipelines poses two risks — (1) the tool
continues generating tests that target coverage numbers rather than behaviour, providing
no improvement over manual coverage theatre (AP1); (2) security vulnerabilities in the
unmaintained dependency chain go unpatched. The LLM-based test generation space evolved
rapidly: production-grade alternatives as of 2026 include mutation-guided LLM prompting
(Pattern 13 / G34), GitHub Copilot's "Generate Tests" workspace feature, and Cursor's
test generation — all of which integrate into the developer workflow rather than running
as a CI coverage-filling step.

**Recommended replacement strategy**: instead of a standalone coverage-gap-filling tool,
(1) run Stryker on modules with AI-generated tests to surface surviving mutants, (2) feed
surviving mutants to an LLM with mutation-specific prompts ("write a test that catches
this fault: `value <= min` was mutated to `value < min`"), (3) accept only the
mutation-guided tests that improve mutation score, not just line coverage.

```typescript
// Example: mutation-guided LLM prompting workflow (replaces cover-agent in CI)
// Run after: npx stryker run --reporters=json --reportDir=reports/mutation

import { readFileSync } from 'node:fs';

interface MutantResult {
  id: string;
  mutatorName: string;
  status: 'Survived' | 'Killed' | 'Timeout' | 'NoCoverage';
  location: { start: { line: number; column: number } };
  replacement: string;
  sourceFile: string;
}

interface StrykerReport {
  files: Record<string, { mutants: MutantResult[] }>;
}

// Extract surviving mutants and format as LLM prompts
function extractSurvivorPrompts(reportPath: string): string[] {
  const report: StrykerReport = JSON.parse(readFileSync(reportPath, 'utf-8'));
  return Object.entries(report.files).flatMap(([file, { mutants }]) =>
    mutants
      .filter((m) => m.status === 'Survived')
      .map(
        (m) =>
          `In ${file} at line ${m.location.start.line}: ` +
          `${m.mutatorName} mutated code to "${m.replacement}". ` +
          `Write a TypeScript test case (vitest/jest) that fails when this mutation is applied.`,
      ),
  );
}

const prompts = extractSurvivorPrompts('reports/mutation/mutation.json');
console.log(`${prompts.length} surviving mutants need test cases:`);
prompts.slice(0, 5).forEach((p, i) => console.log(`\n[${i + 1}] ${p}`));
```

**When to use automated test generation**: LLM-assisted test generation is most valuable
for boundary conditions on pure functions and utility modules (arithmetic, string parsing,
date handling). Avoid automated generation for complex integration, async, or stateful
code — the generated test cases are often assertion-thin or require manual review to be
production-quality.

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
**Vitest 3.2+ update**: AST-based coverage remapping for the **V8 provider** resolves
this issue for V8 — Vitest 3.2+ V8 coverage is now as accurate as Istanbul. If upgrading
to Vitest 3.2+, switch to `provider: 'v8'` to benefit from the AST remapping without
esbuild instrumentation gaps. The istanbul provider still has the esbuild-collapse issue
in Vitest 3.2+; prefer V8 with AST remapping for accurate branch counts at lower overhead.

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

### G22 — Stryker ignoreStatic omission silently negates perTest performance savings  [community]
When `coverageAnalysis: 'perTest'` is enabled (the default since Stryker v5), Stryker
runs only the tests that cover a given mutant. Static mutants — code executed during
module initialisation (class static fields, top-level const initializers, module-level
side effects) — cannot be attributed to specific tests, so Stryker falls back to running
the **entire** test suite for each of them. On TypeScript NestJS or class-heavy codebases
where static initializers are prevalent, static mutants can account for 10–20 % of all
mutants. **WHY it matters**: teams enabling `perTest` expecting a 5× speedup are surprised
to see 2× at best, not realising static mutants are circumventing the optimisation. Setting
`ignoreStatic: true` skips these mutants entirely, recovering the full perTest benefit.
The tradeoff is a small reduction in mutation coverage for static logic — acceptable in
most applications because static initializers rarely contain business logic.

### G23 — Jest 30 moduleFileExtensions ordering affects TypeScript coverage resolution speed  [community]
Jest 30.0 (released October 2025) resolved TypeScript source files by scanning
`moduleFileExtensions` in order. The default order ends with `['ts', 'tsx', ...]` after
JavaScript extensions. In TypeScript-heavy projects with thousands of source files, this
means Jest checks `.js` and `.mjs` extensions before finding `.ts` files, adding
unnecessary file-system resolution overhead during coverage collection.
**WHY it matters**: on monorepos with 2,000+ TypeScript source files, coverage collection
time increases 15–30 % solely from extension resolution order. Fix by moving TypeScript
extensions to the front: `moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'mjs', 'cjs', 'json', 'node']`
in `jest.config.ts`. This is a safe change: Jest still resolves JavaScript files correctly;
only the probe order changes.

### G24 — Stryker Vitest runner enforces single-thread mode, disabling Vitest's native parallelism  [community]
The `@stryker-mutator/vitest-runner` forces `singleThread: true` on Vitest because
Stryker manages its own worker pool. This means all Vitest tests run in a single thread
per Stryker worker — Vitest's native `pool: 'threads'` parallelism is disabled.
**WHY it matters**: teams migrating from Jest to Vitest for speed gains (Vitest's parallel
test execution is a primary selling point) are surprised to find mutation runs are slower
than expected, not realising Stryker has disabled Vitest's threading. Total mutation
throughput is controlled by Stryker's `concurrency` setting, not Vitest's thread count.
Set `concurrency` to match your CI's CPU count (e.g., `concurrency: 4` for a 4-vCPU runner)
and accept that per-worker test parallelism is unavailable during mutation runs.
Additionally, Vitest Browser Mode is not supported by the Stryker Vitest runner — tests
requiring browser context must be excluded from mutation runs with `mutate` glob excludes.

### G25 — Vitest in-source tests require explicit Stryker mutation suppression  [community]
Vitest supports "in-source tests" — test cases written directly in the source file inside
`if (import.meta.vitest)` blocks. Stryker mutates all source files by default and will
inject mutations inside these test blocks, causing test assertions themselves to be mutated
rather than the production code under test. **WHY it matters**: in-source test mutations
produce spurious surviving mutants that appear to indicate untested code but are actually
artifacts of mutating the test logic. The fix: add `// Stryker disable all` immediately
before any `if (import.meta.vitest)` block and `// Stryker restore all` after. For
projects making heavy use of in-source tests, add the glob exclusion in `mutate` config:
`'!src/**/*.test.ts'` is insufficient — in-source tests live in non-test-suffixed files.
Use `// Stryker disable all` annotations as the canonical approach.

### G26 — Pitest bytecode mutation: mutation descriptions differ from source-level expectations  [community]
Pitest instruments Java bytecode rather than source code. This means mutation descriptions
reference compiled constructs — "replaced int return with 0" or "negated conditional" —
that may not map cleanly to source-level logic, especially after javac applies
optimisations. In projects with complex conditional chains, the Pitest HTML report may
show a surviving mutant on a line that looks fully covered in the source. **WHY it
matters**: teams new to Pitest waste time trying to write tests for mutants they believe
are in the source, not realising the mutation is on a compiled branch the source-level
Istanbul comparison would track differently. Use Pitest's `--verbosity` flag and the HTML
report to understand what bytecode is being mutated; cross-reference with IntelliJ IDEA's
decompile view if the mutation description is unclear.

### G27 — mutmut lacks native incremental mode: teams must scope runs manually  [community]
Unlike Stryker's `--since` flag and Pitest's `--historyInputLocation`, mutmut has no
built-in incremental mutation mode as of 2026. Every run either tests all files or
requires manual invocation per-file (`mutmut run <file>`). **WHY it matters**: Python
projects integrating mutmut in CI often either skip mutation on PRs (too slow) or run it
on the entire codebase (prohibitive on large projects). The practical workaround:
use `git diff --name-only origin/main HEAD -- '*.py'` to enumerate changed Python files
and invoke `mutmut run <file>` for each in a loop. Alternatively, use `cosmic-ray` as
a more CI-friendly alternative — it supports job distribution across workers.

### G28 — Stryker 9 upgrade silently drops Vitest v1 and Node 18 support  [community]
Stryker 9 (April 2026) dropped Node 18 support and requires **Vitest v2 or higher** for
the `@stryker-mutator/vitest-runner`. Teams running `npm update @stryker-mutator/core`
without reviewing the changelog will find their CI failing with cryptic module
compatibility errors — not a clear "unsupported Node/Vitest version" message.
**WHY it matters**: monorepos with pinned toolchain versions (common in regulated
environments) may be blocked from upgrading to Stryker 9 until they first upgrade Node
and Vitest. If Stryker 8.x is still running correctly, pin the version explicitly:
`"@stryker-mutator/core": "^8"` until the platform upgrade is planned. Check
compatibility before running `npm update` on any Stryker package.

### G29 — TypeScript 5 stage-3 decorators create extra Istanbul branches not present in experimental decorators  [community]
TypeScript 5.0 introduced standards-compliant (stage-3) decorators. Unlike experimental
decorators (`experimentalDecorators: true`), stage-3 decorators compile to wrapper
functions that Istanbul instruments as additional branches. A class decorated with
`@loggedMethod` gains an instrumented replacement function wrapping the original method —
Istanbul tracks whether both branches of the replacement are covered. **WHY it matters**:
teams migrating NestJS projects from `experimentalDecorators: true` to TypeScript 5's
native decorators often see branch coverage drop 5–15 percentage points immediately
after the migration, without any test change. The fix: exclude decorator implementation
files from strict branch thresholds, or add targeted tests that exercise decorator-wrapped
methods through paths that invoke the decorator logic (not just the method body).

### G30 — TypeScript `using` and `await using` disposal paths are invisible to V8 branch coverage  [community]
TypeScript 5.2's `using` declarations (Explicit Resource Management) generate implicit
`Symbol.dispose()` calls at scope exit, including on early return and on throw. V8's
coverage instrumentation does not track these implicit disposal branches as separate
branch points — they appear to V8 as part of the scope exit machinery, not as decision
branches. Istanbul instruments them inconsistently: the `Symbol.dispose()` body is marked
as covered if the scope exits normally, but the throw-path through `SuppressedError`
(which wraps errors thrown during disposal) is almost never covered in unit tests.
**WHY it matters**: code using `using` for resource cleanup (file handles, database
connections, lock management) may appear 100 % branch-covered while the critical error
path through async disposal exceptions is completely untested. Write explicit tests for
the disposal failure path using a mock that throws from `Symbol.dispose()` — this is
the only way to exercise the `SuppressedError` branch that `await using` generates.

### G31 — verbatimModuleSyntax in tsconfig breaks Istanbul source-map continuity  [community]
TypeScript's `--verbatimModuleSyntax` flag (stable since TS 5.0) preserves import/export
syntax as-written rather than allowing downlevel transforms. When Istanbul instruments
code compiled with `verbatimModuleSyntax: true`, source map accuracy degrades for
type-only import lines — Istanbul may report type-import lines as uncovered statements
because the compiled output omits them, breaking the source-map line mapping. **WHY it
matters**: teams enabling `verbatimModuleSyntax` for ESM compatibility (a recommended
setting for modern Node TypeScript) see phantom uncovered statement markers in Istanbul
HTML reports on lines containing `import type { ... }` syntax. The fix: add
`exclude: ['**/*.d.ts']` to coverage config and enable `"importsNotUsedAsValues": "error"`
in tsconfig — this ensures `import type` is consistently used for type-only imports,
making the compiled output cleaner for Istanbul's source-map resolver.

### G32 — esbuild strips coverage ignore directives: @preserve required in Vitest TypeScript projects  [community]
Vitest uses esbuild by default to transpile TypeScript. esbuild removes JavaScript
comments (including block comments) during transpilation before Istanbul instruments the
output. This means `/* istanbul ignore next */`, `/* c8 ignore next */`, and
`/* istanbul ignore file */` directives in TypeScript source files are **silently
dropped** — the branches they were meant to suppress will appear as uncovered in the
coverage report. **WHY it matters**: teams that added ignore directives for legitimate
reasons (exhaustiveness guards, platform-specific branches, TypeScript `never` arms) will
see coverage failures after switching to Vitest or after esbuild processes their files.
The fix: append `-- @preserve` after the directive (official Vitest format):
`/* istanbul ignore next -- @preserve */` or `/* v8 ignore next -- @preserve */`.
An older prefix form `/* @preserve istanbul ignore next */` also functions in many Vitest
versions, but `-- @preserve` is the suffix style documented in official Vitest guides as
the canonical format. Verify the directive survived by checking the compiled output in
`node_modules/.vite/` or using `vitest --reporter=verbose` to confirm the branch is suppressed.

### G33 — Vitest 3.2 AST-based V8 remapping changes historical coverage numbers  [community]
Vitest 3.2.0 introduced AST-based coverage remapping for the V8 provider, closing the
accuracy gap that previously existed between V8 and Istanbul. This is a significant
improvement — but it is also a **breaking change for coverage baselines**: branch
coverage numbers reported by V8 in Vitest 3.2+ will differ from those reported by V8
in Vitest 3.1 and earlier. Projects upgrading from Vitest 3.1 to 3.2 may see branch
coverage **decrease** (because V8 now counts branches that were previously invisible),
triggering threshold failures. **WHY it matters**: when upgrading Vitest, temporarily
lower branch coverage thresholds, run the new report to see the baseline, then restore
or adjust the thresholds. Treat the upgrade as a coverage baseline reset event, not a
test failure event.

### G34 — AI-generated tests inflate line coverage while failing mutation testing  [community]
Tests generated by GitHub Copilot, Cursor, Claude, and similar LLM coding assistants
tend to exercise the happy path of each function they target, achieving high line coverage
quickly. However, these tests typically pattern-match the function signature and known
example outputs — they do not reason about boundary conditions, error paths, or
adversarial inputs. **WHY it matters**: teams using AI-assisted test generation report
consistently low mutation scores (30–50 % MSI) on modules with 85–95 % line coverage,
because the AI-generated tests are assertion-thin or exercise only the success path.
Run Stryker on any module where AI-generated tests comprise a significant portion of
the test suite. Feed surviving mutants as context back to the LLM with mutation-specific
prompts ("the test suite cannot detect this fault: `value <= min` was changed to
`value < min` on line 12 — write a test that catches this") — mutation-guided prompting
substantially outperforms general "add more tests" prompts for improving mutation scores.
Based on Meta's ACH research (arXiv:2501.12862), mutation-guided LLM synthesis achieved
73 % engineer acceptance in production test-a-thons.

### G35 — Node built-in test coverage thresholds exit code 1 vs c8 threshold semantics differ  [community]
When using Node's built-in `--experimental-test-coverage` with the `run()` programmatic
API, threshold failures emit `test:fail` events and set `process.exitCode = 1` — they
do not throw exceptions. When using `c8` with `--check-coverage`, `c8` exits with code 1
directly on threshold failure. In a mixed CI pipeline that uses both approaches
(some test suites on Node native, others on c8), carelessly combining the two means a
threshold failure from the `run()` API is only caught if the caller correctly observes
`process.exitCode` after stream completion. **WHY it matters**: CI pipelines that pipe
`node --test` output through formatters may swallow the exit code, showing green while
a coverage threshold was breached. Always verify the exit code in CI:
`node --test --experimental-test-coverage; echo "exit: $?"` — a coverage failure yields
exit code 1 only if thresholds are configured via `run({ lineCoverage, branchCoverage })`.
Without thresholds, `--experimental-test-coverage` always exits 0 on test pass.

### G36 — Sharded Vitest runs without blob merge produce silently incomplete coverage  [community]
Teams running Vitest with `--shard` in GitHub Actions matrix jobs often collect coverage
independently per shard and upload each shard's `coverage/lcov.info` to Codecov separately.
Codecov merges the LCOV files automatically — but without Vitest's `--merge-reports`,
the per-shard coverage JSON files are missing cross-shard data, and each shard only
covers its own test files. **WHY it matters**: a 4-shard run where each shard runs 25 %
of tests may report 100 % coverage per shard (only the files those tests cover are
included), but the aggregate misses 75 % of the codebase. The fix is Vitest's
`--merge-reports` workflow: collect blob reports from all shards, run `--merge-reports`
in a dedicated job, and enforce coverage thresholds only on the merged output. Never
check coverage thresholds per-shard; only the merged report is meaningful.

### G37 — Vitest auto-adjusts coverage output in AI coding agent environments  [community]
Vitest 3.x+ detects when it is running inside an AI coding agent (GitHub Copilot Workspace,
Claude Code, Cursor, and similar) and automatically modifies the default `text` coverage
reporter: it sets `skipFull: true` and adds the `text-summary` reporter to minimise
terminal token output. **WHY it matters**: when coverage CI jobs run via AI agent tooling
(e.g., a coding agent that invokes `npx vitest --coverage` to verify a fix), the coverage
output format differs from a human-run terminal session. Scripts that parse the text
reporter output line-by-line — looking for specific patterns like `All files` or specific
file paths — may fail silently or produce incorrect results because the AI-agent output
omits unchanged files (`skipFull: true` means files at 100 % are not printed). Use
`coverage/coverage-summary.json` (generated by the `json-summary` reporter) for
programmatic CI assertions rather than parsing terminal text output — the JSON file is
unaffected by the AI-agent text reporter adjustment.

### G38 — Stryker `testFiles` vs `mutate` glob interaction: silent test scope mismatch  [community]
When using the Stryker 9.5.1+ `testFiles` option to limit which tests execute, a common
misconfiguration is setting `mutate` to a broad glob (e.g., `src/**/*.ts`) while
`testFiles` is scoped narrowly to one module's tests. Stryker will mutate all source
files but only run the narrow test set — modules with no dedicated tests in the
`testFiles` scope will appear to have 0 % mutation score because no test covers their
mutants. This is not reported as an error; surviving mutants simply accumulate.
**WHY it matters**: the intent of `testFiles` is per-module validation — mutating only
the module whose tests are specified. Always pair `testFiles` with a matching `mutate`
glob to scope both mutation and test execution to the same module boundary. See Pattern 23
for the correct combined configuration.

### G39 — `coverage.excludeAfterRemap` fixes TypeScript sourcemap exclusion gaps in Vitest  [community]
When Vitest's Istanbul provider maps coverage back from transpiled JavaScript to original
TypeScript source files via source maps, the `coverage.exclude` patterns are applied
**before** remapping by default. This means exclusion globs like `src/**/*.generated.ts`
match the TypeScript paths — but if the compiled output references vendor helpers or
type-declaration paths that source maps point to (e.g., TypeScript compiler helper
functions in `node_modules/tslib`), those paths are not excluded because they only
appear after remapping. **WHY it matters**: Istanbul reports can include lines from
`tslib` or other compile-time helpers as uncovered, polluting the report with noise that
is technically unreachable from test files. Setting `coverage.excludeAfterRemap: true`
re-applies the `coverage.exclude` patterns after source-map remapping, ensuring that
any compiled-artifact paths that appear post-remap are suppressed correctly.

```typescript
// vitest.config.ts — re-apply exclusions after sourcemap remapping (Vitest 4.x)
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
        'src/**/*.generated.ts',
        '**/node_modules/**',     // explicitly exclude node_modules post-remap
        '**/tslib/**',            // TypeScript compiler helpers
      ],
      all: true,
      // Re-apply exclude globs after coverage remaps compiled JS back to TS source.
      // Prevents tslib helpers and other compile artifacts from appearing in the report.
      excludeAfterRemap: true,
    },
  },
});
```

**When to enable**: NestJS or Angular TypeScript projects using decorators and
`emitDecoratorMetadata: true` are most affected, since the decorator compilation
emits helper calls that Istanbul instruments and source-maps can route back to
unexpected paths. Enable `excludeAfterRemap: true` if the HTML coverage report shows
unexpected entries from `tslib`, `reflect-metadata`, or auto-generated files despite
being listed in `exclude`.

### G40 — `coverage.ignoreClassMethods` suppresses constructor/getter noise without comment directives  [community]
Istanbul instruments all class methods, including constructors, `toString()`, and
auto-generated getters/setters from TypeScript's shorthand property syntax. These methods
are usually not independently testable, yet Istanbul reports them as uncovered branches
when the instance is constructed but the method body has never been exercised via
a direct call. **WHY it matters**: TypeScript classes with `private readonly field: T`
shorthand properties (compiled to `this.field = field` assignments in the constructor
body) accumulate quickly into coverage noise — each generates covered lines, but
derived accessor patterns and explicit `get`/`set` declarations can generate uncovered
branch markers. The `coverage.ignoreClassMethods` option suppresses named methods
globally without requiring per-file `/* istanbul ignore */` comments.

**Vitest 4.0 update**: `ignoreClassMethods` now works with **both** the `istanbul` and `v8`
providers (previously Istanbul-only in Vitest 3.x). Projects using the V8 provider with
Vitest 4+ can now suppress constructor and `toString` noise without switching to Istanbul.

```typescript
// vitest.config.ts — ignore class methods that are untestable structural boilerplate (Vitest 4+)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      // In Vitest 4+, ignoreClassMethods works with both 'v8' and 'istanbul' providers.
      // In Vitest 3.x, this option was Istanbul-only; V8 users had to use comment directives.
      provider: 'v8',
      include: ['src/**/*.ts'],     // Vitest 4+: use include instead of removed all: true
      exclude: ['src/**/*.d.ts', 'src/**/*.generated.ts', 'src/**/__mocks__/**'],
      reporter: ['text', 'html', 'lcov'],
      thresholds: {
        lines: 80,
        branches: 75,
        functions: 80,
        statements: 80,
        perFile: true,
      },
      // Suppress coverage for class methods that are structural boilerplate:
      // - 'constructor': TypeScript shorthand assignment constructors are always
      //   "covered" by instantiation, but their branches (optional param defaults)
      //   are often not worth dedicated test cases.
      // - 'toString': rarely tested directly; coverage noise on data classes.
      // Use sparingly — suppressing 'validate' or 'process' methods is an anti-pattern.
      ignoreClassMethods: ['constructor', 'toString'],
    },
  },
});
```

**Important caveat**: `ignoreClassMethods` applies globally to ALL classes in the project.
Only use it for truly structural, untestable methods. Suppressing domain methods like
`validate()`, `process()`, or `transform()` hides real coverage gaps. The legitimate
use cases are: auto-generated data-class constructors, `toString`/`toJSON` used only
for serialisation, and TypeScript class decorators that generate accessor boilerplate.

### G41 — Stryker 9.6.1 fix for Vitest 4.1 hitcount regression: verify upgrade compatibility  [community]
Stryker 9.6.1 (April 10, 2026) shipped a specific fix for Vitest 4.1 compatibility:
"fix vitest runner mutant hitcount and coverage for v4.1". Prior to this fix, Stryker
running with the Vitest 4.1 runner would produce incorrect per-test mutation coverage
data — `coverageAnalysis: 'perTest'` was returning inaccurate hitcounts, causing
the wrong tests to be selected for killing each mutant. **WHY it matters**: a project
using Stryker 9.5.x with Vitest 4.1 could be seeing inflated or incorrect mutation
scores because the wrong set of tests was executing per mutant. After upgrading to
Vitest 4.1, always upgrade Stryker to at least v9.6.1 before trusting mutation scores.
Verify the Stryker + Vitest version matrix before interpreting historical mutation reports:
scores generated on Stryker 9.5.x + Vitest 4.1 combinations are unreliable.

```bash
# Check current Stryker + Vitest version compatibility
node -e "
  const pkg = require('./package.json');
  const deps = { ...pkg.dependencies, ...pkg.devDependencies };
  console.log('stryker core:', deps['@stryker-mutator/core'] || 'not found');
  console.log('vitest-runner:', deps['@stryker-mutator/vitest-runner'] || 'not found');
  console.log('vitest:', deps['vitest'] || 'not found');
"

# Safe upgrade path for Vitest 4.1+ projects:
# 1. npm install vitest@^4.1  (or latest 4.x)
# 2. npm install @stryker-mutator/core@^9.6.1 @stryker-mutator/vitest-runner@^9.6.1
# 3. Re-run npx stryker run to regenerate mutation baseline
# If mutation scores change significantly after upgrade, the previous scores were inaccurate.
```

### G42 — Vitest 5 (beta): V8 now tracks child_process and worker_threads — existing multi-process coverage gaps become visible  [community]
Vitest 5.0.0-beta.2 (May 2026) added V8 coverage tracking for `node:child_process` and
`node:worker_threads` contexts. Prior to this change, any TypeScript code executing in a
spawned child process or worker thread was invisible to V8 coverage — those execution
contexts ran outside Vitest's instrumentation boundary. **WHY it matters**: TypeScript
projects that use `worker_threads` for CPU-bound tasks (parsing, compilation, encryption),
or spawn child processes for CLI integrations, report inflated coverage numbers in Vitest
4.x because the worker code is simply excluded from measurement. After upgrading to
Vitest 5, branch and line coverage for worker modules may **decrease** (now measured
for the first time), triggering threshold failures on code that was never actually covered.

Treat the Vitest 5 upgrade as a coverage baseline reset for any project using
`node:worker_threads` or `node:child_process`. Before upgrading:
1. Identify source files that execute in worker contexts (`new Worker(...)`, `fork(...)`, `spawn(...)`).
2. Note their pre-upgrade coverage numbers.
3. After upgrading, compare — if coverage drops, the new numbers reflect reality; the old numbers were incomplete.
4. Add targeted tests for worker-specific code paths before restoring thresholds.

**Vitest 5 breaking changes that affect sharded coverage workflows** (v5.0.0-beta.2):
- The blob reporter and `--merge-reports` default directory changed from `.vitest-tmp/` to
  `.vitest/blob/`. If Pattern 22 hardcodes the blob output path, update the path after
  upgrading to Vitest 5.
- The `attachmentsDir` default changed from `.vitest-attachements/` to `.vitest/attachments/`
  (typo in the old name corrected). CI jobs uploading coverage attachments by path must
  be updated.

### G43 — Vitest 4.1.5 Istanbul `instrumenter` option: required only when the default Istanbul pipeline is insufficient  [community]
Vitest 4.1.5 added an experimental `coverage.instrumenter` option for the Istanbul
provider. This factory function replaces the default `istanbul-lib-instrument` instrumenter
with a custom implementation. **WHY it matters**: the default Istanbul instrumenter is
correct for the vast majority of TypeScript projects; this option exists for niche cases
where the default pipeline is insufficient — for example, experimental stage-3 decorator
transforms that Istanbul 1.x cannot instrument correctly, or monorepos where a custom
instrumenter already exists for a different toolchain.

Misuse risk: teams sometimes reach for `instrumenter` to work around Istanbul coverage
false-positives (phantom branches, decorator noise) rather than using the correct
configuration — `ignoreClassMethods`, `excludeAfterRemap`, or `/* istanbul ignore next */`
comments. Before writing a custom instrumenter:
1. Check whether `excludeAfterRemap: true` (G39) fixes the phantom branch issue.
2. Check whether `ignoreClassMethods` (G40) addresses decorator constructor noise.
3. Check whether `verbatimModuleSyntax` is causing source-map degradation (G31).
Custom instrumenters are difficult to maintain through Istanbul and Vitest upgrades — they
receive `InstrumenterOptions` and must implement `instrumentSync()` and `lastSourceMap()`,
meaning they absorb any interface changes in `istanbul-lib-instrument`. Reserve this
escape hatch for toolchain integration scenarios, not coverage-noise suppression.

### G45 — Vitest 5 `coverage.include`/`coverage.exclude` glob patterns became more strict: upgrade silently breaks simple directory names  [community]
Vitest 5.0.0-beta.1 introduced a **breaking change** to how `coverage.include` and `coverage.exclude` glob patterns are evaluated (PR #9818: "fix(coverage)!: include/exclude globs too eager"). In Vitest 4.x, a simple directory name like `include: ["src"]` was treated permissively — Vitest internally expanded it to match all files under `src/`. In Vitest 5.0+, this same pattern does **not** automatically expand; it must be written as an explicit glob: `include: ["src/**/*.ts"]` or `include: ["src/**"]`. **WHY it matters**: projects that migrate to Vitest 5 with coverage configs that use bare directory names in `include` or `exclude` will silently produce an empty or incomplete coverage report — no files are instrumented because the too-permissive path expansion is gone. The failure is silent: Vitest runs successfully and reports 0 % coverage on 0 files (or only the files that happen to match the literal string as a path). Always use explicit glob patterns in coverage configuration:

```typescript
// vitest.config.ts — Vitest 5 compatible: explicit globs required
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      // Vitest 4 permissive form (breaks in Vitest 5):
      // include: ['src'],             // ❌ bare directory no longer auto-expands
      // Vitest 5 required form — explicit glob:
      include: ['src/**/*.ts', 'src/**/*.tsx'],    // ✅ explicit glob, works in both 4 and 5
      exclude: [
        'src/**/*.d.ts',
        'src/**/*.test.ts',
        'src/**/*.spec.ts',
        'src/**/__mocks__/**',
        // Vitest 4 permissive form (breaks in Vitest 5):
        // 'src/generated',            // ❌ bare directory: may not match intended files
        'src/generated/**',            // ✅ explicit glob required
      ],
      all: true,
      thresholds: { lines: 80, branches: 75, functions: 80, statements: 80 },
    },
  },
});
```

**Upgrade checklist for Vitest 4 → 5 coverage configs**: (1) search `coverage.include` and `coverage.exclude` for bare directory names without `/**`, (2) add `/**` (or `/**/*.ts`) to each, (3) re-run and verify the coverage file count in `coverage/coverage-summary.json` matches pre-upgrade counts. If file count drops significantly after the upgrade, the glob expansion regression is the likely cause.

### G46 — Stryker.NET 4.13+ Microsoft Testing Platform runner keeps test processes alive across mutations  [community]
Stryker.NET 4.13 (March 2026) introduced a **preview-quality Microsoft Testing Platform (MTP) runner** as an alternative to the legacy VSTest runner. Unlike VSTest, which spawns a new test process for each mutation run, MTP keeps the test runner process alive across multiple mutation test runs. **WHY it matters for TypeScript teams**: this is primarily a .NET Stryker change, but it illustrates an architectural pattern that StrykerJS implements via its worker pool — understanding the design helps TypeScript teams tune Stryker concurrency correctly. In StrykerJS, `concurrency` controls how many Vitest/Jest workers Stryker maintains simultaneously; each worker is reused across mutations within its lifecycle. The analogy to MTP's keep-alive model explains why `concurrency` should match available CPUs (not exceed them) and why `ignoreStatic: true` (G22) is essential: static mutants force all workers to restart the full suite in sequence, defeating the keep-alive benefit.

For .NET teams in polyglot codebases: to enable MTP in Stryker.NET 4.13+:
```yaml
# stryker-config.yaml (Stryker.NET 4.13+ YAML config format — new alternative to JSON)
stryker-config:
  test-runner: mtp          # MTP runner: keeps process alive across mutations
  # Alternatively via CLI: dotnet stryker --test-runner mtp
```

**Current MTP limitations** (as of May 2026): coverage analysis is partial (filters uncovered mutants but cannot attribute per-test coverage), and .NET Framework (non-Core) is not supported. Use VSTest for projects that require per-test coverage analysis (`coverageAnalysis: 'perTest'` equivalent) until MTP coverage support matures.

### G44 — Stryker VS Code plugin requires StrykerJS v9.3.0+ and replaces the HTML report workflow  [community]
The official Stryker VS Code plugin (released November 2025, requires StrykerJS v9.3.0+)
brings inline mutation testing results directly into the editor via the **Mutation Server
Protocol (MSP)** — a JSON-RPC standard analogous to LSP. The plugin shows survived and
killed mutants as inline annotations and diff views in the gutter, and integrates with
VS Code's native Test Explorer for per-file/per-folder mutation browsing.
**WHY it matters for TypeScript teams**: the previous mutation testing workflow required
running `npx stryker run`, waiting for completion, then opening the HTML report in a browser
to identify surviving mutants. The VS Code plugin eliminates the context switch — survived
mutants appear as gutter decorations on the source lines where they exist, with a diff view
showing the exact mutation injected. This substantially reduces the time between "run mutation tests"
and "write the test that kills the mutant."

**Key constraints for TypeScript projects**:
- Requires StrykerJS v9.3.0 or higher — projects on StrykerJS 8.x cannot use the plugin without upgrading.
  Combined with the Stryker 9 requirement for Node 20+ and Vitest v2+ (see G28), plugin adoption
  may be gated by a platform upgrade.
- The plugin uses StrykerJS internally; **Stryker.NET and Stryker4s support is on the roadmap but
  not yet available** (as of May 2026). TypeScript/JavaScript projects are the only supported target.
- Mutation runs from the plugin still execute the full Stryker pipeline — `incremental: true` in
  `stryker.config.ts` is essential to make in-editor runs practical. Without incremental mode,
  every plugin-triggered run re-mutates the entire codebase.
- The plugin reads `stryker.config.ts` / `stryker.config.mjs` from the workspace root. Projects
  with non-standard config file names or monorepo-root configs must verify path resolution before use.

### G47 — Stryker `allowEmpty: true` silently changes NoCoverage semantics in threshold calculations  [community]
When `allowEmpty: true` is enabled to prevent CI hard failures on modules with no covering
tests, teams sometimes misread mutation scores as higher than reality. By default, Stryker
counts `NoCoverage` mutants identically to `Survived` mutants when computing the Mutation
Score Indicator — a mutant with no covering tests is as dangerous as one that survived
a test. **WHY it matters**: in CI matrix jobs using `allowEmpty: true` to tolerate
modules with thin test coverage, the mutation score is genuinely low (NoCoverage
contributes to the denominator). Setting `thresholds.break: 50` and finding that the
matrix job passes despite a module sitting at 20 % MSI (because `allowEmpty` masked
the hard error) creates a false sense of completeness. Always check the HTML report
for `NoCoverage` counts — a high NoCoverage count means the test coverage investment
is incomplete, not that the mutant was killed. Use `allowEmpty: true` only as a
transitional option while building test coverage, not as a permanent CI configuration.

### G49 — TypeScript 6.0 default changes silently break coverage tooling for projects that skip tsconfig review  [community]
TypeScript 6.0 (May 2026) changed several compiler option defaults that directly affect Istanbul
and V8 coverage collection in Jest and Vitest projects. Teams that run `npm update typescript`
without reviewing the changelog frequently encounter CI failures that appear unrelated to coverage.

**Critical default changes affecting coverage tooling:**

1. **`module` now defaults to `"esnext"`** (was `"commonjs"`). Projects using `ts-jest` with its
   default `ts-jest` preset rely on CommonJS output. After upgrading to TypeScript 6.0, `ts-jest`
   may silently switch to ESM mode, causing require/import interop failures that produce zero
   coverage rather than correct test failures. Fix: explicitly set `"module": "commonjs"` in
   `tsconfig.json` (or `"module": "nodenext"` with `"moduleResolution": "nodenext"` for ESM-native
   projects). TypeScript 6.0 allows `--module commonjs` + `--moduleResolution bundler` as a
   migration bridge.

2. **`types` now defaults to `[]`** (was auto-include all `@types/*`). Projects that relied on
   implicit `@types/node` inclusion for `process.env`, `Buffer`, or `__dirname` globals will get
   type errors after upgrading. Istanbul relies on `@types/node` types being available during
   instrumentation. Fix: add `"types": ["node", "jest"]` (or `["node", "vitest/globals"]`) to
   `compilerOptions` explicitly.

3. **`rootDir` now defaults to `.`** (was inferred common ancestor of source files). If your
   `collectCoverageFrom` paths in Jest or `coverage.include` in Vitest are relative to the
   previously-inferred `rootDir`, they may suddenly point to wrong locations. Coverage reports
   may show 0 files after upgrading. Fix: explicitly set `"rootDir": "./src"` in `tsconfig.json`.

4. **`--outFile` is removed entirely.** Projects that used `outFile` for legacy concatenated
   output with coverage are forced to migrate to a bundler. This primarily affects legacy
   TypeScript projects using namespace-based module patterns — if you encounter this, the
   migration path is to switch to ESM modules and use esbuild/webpack for bundling.

5. **`--moduleResolution classic` is removed.** Projects using any module resolution that fell
   through to `classic` (e.g., `module: "commonjs"` without explicit `moduleResolution`) will
   error. This affects `@stryker-mutator/typescript-checker`'s path resolution for alias-heavy
   TypeScript projects — verify Stryker still resolves `tsconfig.json` paths after upgrade.

**Migration bridge**: TypeScript 6.0 provides `"ignoreDeprecations": "6.0"` in `tsconfig.json`
to silence deprecation warnings for options not yet removed (so you can upgrade TypeScript and
fix the toolchain incrementally without fixing all deprecated options at once). This is a
temporary bridge — deprecated options will be removed in TypeScript 7.0.

```json
// tsconfig.json — TypeScript 6.0 safe upgrade bridge for coverage tooling
{
  "compilerOptions": {
    "target": "ES2022",           // explicit — TS 6.0 default changed to "es2025"
    "module": "commonjs",         // explicit — TS 6.0 default changed to "esnext"
    "moduleResolution": "nodenext", // TS 6.0 dropped "classic"; use nodenext or bundler
    "rootDir": "./src",           // explicit — TS 6.0 default changed to "."
    "outDir": "./dist",
    "types": ["node"],            // explicit — TS 6.0 default changed to [] (no auto-include)
    "strict": true,
    "sourceMap": true,
    "esModuleInterop": true,
    // Suppress deprecation warnings during incremental migration (remove before TS 7.0):
    "ignoreDeprecations": "6.0"
  },
  "include": ["src/**/*.ts"]
}
```

**WHY it matters**: TypeScript 6.0's new defaults are sensible for new projects but silently
break coverage tooling in existing projects because the coverage failure surfaces as "0 files
instrumented" or "module not found" rather than "TypeScript version incompatibility." Treat a
TypeScript major version upgrade (5.x → 6.0) identically to a Vitest major upgrade: run a
dry-run with explicit `tsc --noEmit`, check coverage file counts, and verify the HTML report
shows the expected file set before merging the upgrade PR.

### G48 — Stryker `disableTypeChecks` default changed in v7.0: existing configs may have redundant settings  [community]
Before Stryker 7.0, `disableTypeChecks` defaulted to a glob string (e.g.,
`'{test,tests,__tests__}/**/*.ts'`) targeting test directories. In Stryker 7.0, the default
changed to `true` — type checking is disabled **globally** for all files by default.
**WHY it matters**: TypeScript projects that were explicitly setting
`disableTypeChecks: 'src/**/*.ts'` in their Stryker config to disable type checks on
source files are now double-disabling (the default `true` already covers all files).
More importantly, teams that relied on the old glob default to keep type checking active
on source files are now running without type checking at all — mutants that introduce
type errors are no longer detected as `CompileError` and may instead be classified as
`Survived` or `Timeout`, inflating mutation scores. After upgrading to Stryker 7+, check
your `stryker.config.ts` for `disableTypeChecks`: if the intent was to keep type checking
active on source files, set `checkers: ['typescript']` explicitly (the TypeScript checker
plugin) and remove or re-scope `disableTypeChecks`. The TypeScript checker (`@stryker-mutator/typescript-checker`)
is the correct mechanism for compile-time mutant validation; `disableTypeChecks` is a
performance escape hatch for generated files and mocks.

### G50 — Vitest glob-pattern thresholds still contribute to global: migrating from Jest causes unexpected double-enforcement  [community]

Teams migrating coverage configuration from Jest to Vitest often replicate Jest's
`coverageThreshold['./src/payments/']` pattern as Vitest's `thresholds['src/payments/**/*.ts']`.
The two look equivalent but behave differently: Jest evaluates per-path thresholds
**independently** from the global; Vitest evaluates matching files against **both** the
pattern threshold and the global threshold simultaneously. **WHY it matters**: a Vitest config
that sets `'src/payments/**/*.ts': { branches: 90 }` with a global `branches: 75` will fail
the run if payment files drop below 90 % branches — as expected — BUT those same payment files
also count toward the global 75 % calculation. If payment files are the only well-tested modules,
removing them from the global calculation (as Jest would) could mask a global deficit. Conversely,
if global threshold failures are unexpected after a Jest → Vitest migration, check whether the
per-pattern strict thresholds are failing independently of the global.

**Detection**: run `npx vitest --coverage` with `reporter: ['json-summary']` and compare
`coverage-summary.json` totals against the Vitest threshold log output — if the run fails with
multiple threshold messages (one for the pattern, one for the global), both thresholds are being
applied to the same files. This is correct Vitest behaviour, not a bug.

**Migration checklist for Jest → Vitest threshold configs**:
1. Replace `coverageThreshold['./src/path/']` (Jest directory key) with `thresholds['src/path/**/*.ts']` (glob)
2. Note that Vitest `thresholds[pattern]` does **not** support negative values (`-N`); use the
   programmatic approach (Pattern 17) or Jest for absolute-count enforcement
3. Verify the global threshold is still appropriate after extracting per-module values — Vitest
   measures both simultaneously, unlike Jest's independent evaluation

### G51 — Vitest 4.0 removed `coverage.all`: `all: true` is silently ignored and uncovered files disappear from reports  [community]

Vitest 4.0 removed `coverage.all` entirely as a configuration option. In Vitest 3.x, setting
`all: true` forced the coverage report to include all source files matching `coverage.include`,
even those never imported by any test — making zero-coverage modules visible. In Vitest 4.0,
this option was removed because the V8 provider was processing unexpected files (minified
bundles, compiled outputs) when the include list was broad, causing slow or stuck report generation.

**WHY it matters**: projects upgrading from Vitest 3.x to 4.x with `all: true` in their config
receive **no deprecation warning** — the option is silently ignored. After the upgrade, coverage
reports include only files that were imported during test execution. New source files added
without a corresponding test file are completely invisible to the coverage report, defeating the
primary purpose of `all: true` (detecting zero-coverage modules). The symptom: aggregate coverage
numbers stay the same or improve after adding new source files without tests, because those files
simply aren't counted.

**The Vitest 4 replacement**: explicitly define `coverage.include` with the source glob. When
`coverage.include` is set, Vitest 4 still reports files that match the include pattern even if
they were not loaded during the test run — effectively restoring the `all: true` behaviour, but
without processing unexpected files.

```typescript
// vitest.config.ts — Vitest 4 replacement for `all: true`
// In Vitest 3.x: coverage: { all: true, include: ['src/**/*.ts'] }
// In Vitest 4.x: setting coverage.include IS the replacement for all: true

import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      // In Vitest 4+, defining coverage.include causes uncovered files matching
      // the include pattern to appear in the report (zero-coverage files visible).
      // This replaces the removed `all: true` option from Vitest 3.x.
      // Do NOT add `all: true` — the option no longer exists and is silently ignored.
      include: ['src/**/*.ts', 'src/**/*.tsx'],
      exclude: [
        'src/**/*.d.ts',
        'src/**/*.test.ts',
        'src/**/*.spec.ts',
        'src/**/__mocks__/**',
        'src/**/index.ts',
        'src/**/*.stories.ts',
        'src/**/*.generated.ts',
      ],
      reporter: ['text', 'html', 'lcov', 'json-summary'],
      reportsDirectory: './coverage',
      thresholds: {
        lines: 80,
        branches: 75,
        functions: 80,
        statements: 80,
        perFile: true,
      },
    },
  },
});
```

**Other options removed in Vitest 4.0** (also silently ignored if present in config):
- `coverage.extensions` — previously an array of file extensions to include in coverage
  (e.g., `['.ts', '.tsx']`). In Vitest 4, file extension filtering is handled entirely by
  the `coverage.include` glob patterns. Remove `coverage.extensions` from config and use
  explicit glob extensions in `include` instead.
- `coverage.ignoreEmptyLines` — removed because lines without runtime code (type
  annotations, interface declarations, blank lines) are now automatically excluded from
  V8 and Istanbul coverage counts. The option had no effect in practice since Vitest 3.2+
  AST remapping already excluded non-executable lines.
- `coverage.experimentalAstAwareRemapping` — removed because AST-based remapping is now
  the default and only supported method in Vitest 4. If this was `false` in Vitest 3.x
  config (to opt out of experimental AST remapping), the opt-out is no longer respected.

**Upgrade checklist for Vitest 3 → 4 coverage config**:
1. Remove `all: true` — option no longer exists; ensure `coverage.include` is explicitly set
2. Remove `coverage.extensions` — use explicit file extension globs in `coverage.include` instead
3. Remove `coverage.ignoreEmptyLines` — auto-excluded in Vitest 4
4. Remove `coverage.experimentalAstAwareRemapping` — always on in Vitest 4
5. Verify the coverage file count in `coverage/coverage-summary.json` after upgrading —
   if it drops, the `coverage.include` glob is not covering your source files

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
| Property-based testing (fast-check / @fast-check/vitest) | Edge cases across the full input space; `test.prop()` integrates natively with Vitest 4.1+ reporter |
| Contract testing (Pact) | Integration correctness at service boundaries |
| Test review / pair review | Assertion quality and intent clarity |
| Visual regression (Chromatic, Percy) | UI correctness that line coverage cannot measure |
| TypeScript strict type checking | Eliminates whole classes of runtime bugs without any test |
| Mutation-guided LLM synthesis (ACH) | Targeted test generation for surviving mutants at production scale |

### Known adoption costs
- **Mutation testing**: 5–30x slower than unit test suite; requires incremental/selective
  configuration before CI integration is practical. Stryker 9 requires Node 20+ and Vitest v2+
  (Vitest v4 supported from Stryker 9.4.0; Stryker 8.x for Node 18 or Vitest v1).
- **Istanbul instrumentation**: 20–40 % test runtime overhead; significant on large TypeScript suites.
  `ts-jest` with Istanbul adds source-map resolution on top. In **Vitest 3.2+**, use the V8 provider
  with AST remapping instead — same accuracy as Istanbul at V8 speed, eliminating the overhead penalty.
- **Per-file thresholds**: require ongoing maintenance as new TypeScript files are added; can block
  PRs until thresholds are explicitly configured for new modules.
- **Stryker initial setup for TypeScript**: `@stryker-mutator/typescript-checker` + Jest/Vitest
  preset alignment typically requires 2–4 hours of initial configuration on a real-world codebase.
  TypeScript path aliases (`@/...`) must be configured in both `tsconfig.json` and Stryker config.
  Use the `ignorers` plugin (Stryker 7.3+) to suppress recurring structural patterns (DI container
  registrations, decorator wiring) across many files — avoids per-file `// Stryker disable` sprawl.
- **Sharded coverage in CI**: parallel sharding requires a dedicated merge job (`vitest --merge-reports`)
  and threshold checks only on the merged output — per-shard threshold checks produce false positives.
- **Vitest 3.2 baseline reset**: upgrading to Vitest 3.2+ resets V8 branch coverage baselines
  (AST remapping now detects more branches); treat as a one-time recalibration, not a test failure.
- **`coverage.changed` in CI vs Codecov**: Vitest 4.1's `coverage.changed` provides built-in
  differential coverage without external tooling, but does not generate PR comments, historical
  trend dashboards, or cross-repository tracking. For projects needing those features, Codecov's
  `patch_coverage_threshold` (Pattern 15) remains the better choice. For projects that just need
  "don't ship untested code", `coverage.changed` is simpler and has no external dependencies.
- **`coverage.thresholds.autoUpdate` in CI**: disable `autoUpdate` in CI pipelines. It writes to
  the config file during the test run; only use it locally to ratchet thresholds upward after
  coverage improvements, then commit the updated config as part of the same PR.
- **Vitest 5 upgrade coverage baseline reset**: Vitest 5.0 adds V8 coverage tracking for
  `node:child_process` and `node:worker_threads` contexts — code that was invisible to coverage
  in Vitest 4.x is now measured. Projects using worker threads or child processes should treat
  the Vitest 5 upgrade as a coverage baseline reset event: re-measure after upgrading, then
  restore thresholds based on the new (more accurate) numbers. Additionally, the blob reporter
  default directory changes from `.vitest-tmp/` to `.vitest/blob/` — update CI sharding
  workflows (Pattern 22) accordingly.
- **TypeScript 6.0 upgrade coverage breakage**: TypeScript 6.0 changed compiler defaults for
  `module`, `target`, `types`, and `rootDir` — and removed `--outFile` and `--moduleResolution classic`.
  These changes cause `ts-jest` and Istanbul to silently fail or instrument zero files if `tsconfig.json`
  is not updated. Use `"ignoreDeprecations": "6.0"` as a temporary bridge and update defaults
  explicitly (see G49). Treat TypeScript major upgrades as coverage-tooling risk events.
- **Vitest per-glob-pattern threshold migration from Jest**: Vitest's `thresholds['src/path/**']` and Jest's
  `coverageThreshold['./src/path/']` look equivalent but have different semantics — Vitest evaluates matching
  files against both the pattern and the global threshold simultaneously, while Jest evaluates per-path thresholds
  independently. See Pattern 31 and G50. Additionally, Vitest does not support negative (`-N`) absolute-count
  thresholds in pattern keys — only percentages. Projects that rely on Jest's negative threshold syntax for legacy
  module debt management must use the programmatic approach (Pattern 17) after migrating to Vitest.
- **Vitest 4.0 `coverage.all` removal**: `all: true` no longer exists in Vitest 4 and is silently ignored.
  The replacement is to explicitly set `coverage.include` — when `include` is defined, Vitest 4 includes
  matching files even if they were not imported during the test run (equivalent behaviour to `all: true`).
  Additionally, `coverage.extensions`, `coverage.ignoreEmptyLines`, and `coverage.experimentalAstAwareRemapping`
  were all removed in Vitest 4; silently present in config, they have no effect. See G51 for the full upgrade
  checklist. Treat the Vitest 3 → 4 upgrade as a coverage-config audit event.

### G52 — Node 24 test runner breaking change: subtests no longer return Promises — async coverage patterns affected  [community]
Node.js 24.0.0 (released April 2025) changed the built-in test runner so that `test()` and
`t.test()` no longer return Promises. Code that manually `await`-ed the Promise returned by
a test (a workaround for ensuring subtest completion before checking coverage state) now
silently ignores the awaited value — `await test(...)` is a no-op rather than a wait.
**WHY it matters for coverage**: Pattern 14's programmatic `run()` API and any TypeScript
test scripts that relied on awaiting subtest handles to force sequential coverage collection
need to be updated. In Node 24+, the test runner automatically waits for all subtests to
complete before moving on — the manual await pattern is both unnecessary and misleading.

Additionally, **`--experimental-strip-types` is still RC-status in Node 24** (documented as
"release candidate" in the Node 24.0.0 release notes). Despite being close to stable, it is
not yet the recommended default for production TypeScript projects. For coverage workflows:
- Node 22.6+: `--experimental-strip-types` available but experimental.
- Node 24.0: `--experimental-strip-types` promoted to RC, not yet stable.
- Until it reaches stable status, production TypeScript coverage pipelines should use Vitest,
  Jest, or the `c8` wrapper rather than relying on Node's native type stripping for
  coverage collection — the API surface may still change in a patch release.

Node 24 also added **global setup/teardown hooks** (`setup` and `teardown`) to the built-in
test runner. For coverage workflows using Pattern 14's programmatic `run()` API, these hooks
enable pre-coverage database seeding and post-coverage cleanup without the manual `beforeAll`
workaround:

```typescript
// scripts/run-tests-with-thresholds.ts — Node 24 with global setup/teardown
import { run } from 'node:test';
import process from 'node:process';

// Node 24: globalSetup and globalTeardown are supported in the run() options.
// They run once before/after all tests (not per-test).
const stream = run({
  files: ['src/**/*.test.ts'],
  coverage: true,
  lineCoverage: 80,
  branchCoverage: 75,
  functionCoverage: 80,
  // Node 24+ only: global setup hook (runs once, not per test)
  // globalSetup: () => import('./test-helpers/db-setup.js'),
  // globalTeardown: () => import('./test-helpers/db-teardown.js'),
});

// Node 24 change: t.test() no longer returns a Promise that requires manual await.
// Tests complete automatically before the stream closes.
stream.on('test:fail', () => { process.exitCode = 1; });
```

**Upgrade path for Pattern 14 code that awaits test handles**: remove any
`const result = await test(...)` patterns — the return value is now `void` in Node 24.
Coverage collection is unaffected; only the manual await is obsolete.

### G53 — `coverage.htmlDir` and `html-spa` reporter: Vitest 4.1 HTML output configuration for custom reporters and Vitest UI  [community]

Vitest 4.1 introduced `coverage.htmlDir` as a companion to the existing `coverage.reportsDirectory`
option, and the HTML report suite now includes a `html-spa` reporter alongside the original `html`
reporter. Both additions are frequently missed during Vitest 4.1 upgrades because they have narrow
use cases — but not understanding them causes confusion when custom reporters fail to appear in
Vitest UI or when CI uploads pick up the wrong HTML directory.

**`coverage.htmlDir`**: specifies where coverage HTML output is served within Vitest UI.
By default, the value is **automatically inferred** from whichever of `html`, `html-spa`, or
`lcov` reporters is configured — it points to the HTML output path for the first HTML reporter
found. You should only set `coverage.htmlDir` explicitly when using a **custom coverage reporter**
that generates HTML output to a non-standard path; without explicit configuration, the Vitest UI
`coverage` tab will not find the custom reporter's output.

```typescript
// vitest.config.ts — using htmlDir with a custom reporter (Vitest 4.1+)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'istanbul',
      include: ['src/**/*.ts'],
      reporter: [
        'text',
        'json-summary',
        // Custom reporter that writes HTML to a non-standard directory:
        ['my-custom-reporter', { outputDir: './reports/custom-coverage' }],
      ],
      reportsDirectory: './coverage',
      // Tell Vitest UI where to find the HTML output from the custom reporter.
      // Without this, the Vitest UI coverage tab looks in `reportsDirectory` and finds nothing.
      htmlDir: './reports/custom-coverage',
    },
  },
});
```

**`html-spa` reporter**: the `html-spa` reporter generates a single-page application version of
the Istanbul/V8 HTML coverage report. Unlike the standard `html` reporter (which generates
one HTML file per source file), `html-spa` generates a single self-contained HTML file with
all coverage data loaded as JSON. This makes it suitable for scenarios where the standard
multi-file report is impractical: S3/blob storage uploads (single file upload instead of
hundreds), emailing as an attachment, or embedding in CI artifact summaries.

```typescript
// vitest.config.ts — html-spa reporter for single-file HTML coverage output
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts', 'src/**/__mocks__/**', 'src/**/index.ts'],
      reporter: [
        'text-summary',   // terminal: summary only (CI-friendly with skipFull)
        'lcov',           // for Codecov / GitHub coverage PR comments
        'html-spa',       // single HTML file — easier to store/share than multi-file html
        'json-summary',   // for programmatic threshold checks (Pattern 17)
      ],
      reportsDirectory: './coverage',
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

**WHY it matters**: teams adding the `html-spa` reporter alongside `html` inadvertently
double-generate HTML output into the same `reportsDirectory`, causing Vitest UI to pick up
whichever it finds first. Use either `html` **or** `html-spa`, not both. The `htmlDir` option
becomes relevant when deploying coverage output to a CDN or CI artifact store where the multi-file
`html` tree is unwieldy — `html-spa` outputs to a single `index.html` file in `reportsDirectory`,
while `html` outputs to a directory tree under `reportsDirectory/index.html`.

| Reporter | Output | Best for |
|----------|--------|----------|
| `html` | Multi-file tree under `coverage/` | Local HTML report; Vitest UI tab |
| `html-spa` | Single `coverage/index.html` | S3 upload; CI artifact; email attachment |
| `lcov` | `coverage/lcov.info` | Codecov, Coveralls, GitHub Actions |
| `json-summary` | `coverage/coverage-summary.json` | Programmatic threshold checks (Pattern 17) |

### G54 — Jest 30.3+ `defineConfig`/`mergeConfig` helpers and `jest.config.mts`: type-safe config without manual type imports  [community]

Jest 30.3.0 introduced `defineConfig` and `mergeConfig` as named exports from `jest`. Jest 30.4.0
added `jest.config.mts` as a natively supported configuration file format (alongside `jest.config.ts`,
`.mts`, `.cts`, `.mjs`, `.cjs`, `.js`, and `.json`). Both changes are invisible at runtime but
have meaningful effects on TypeScript coverage configurations.

**WHY it matters**: Before Jest 30.3, the only way to get type checking on a `jest.config.ts`
file was `import type { Config } from 'jest'`, then explicitly annotating the exported object.
This required the annotation to be manually maintained and could be forgotten on copy-paste.
`defineConfig` wraps the config in a type-safe call that IDE tooling infers automatically — the
same pattern used by Vitest and Stryker. `mergeConfig` enables layered configurations (base
+ test-environment override) without manual spread-and-lose patterns that break TypeScript narrowing.

```typescript
// jest.config.ts — Jest 30.3+: defineConfig + mergeConfig (replaces `import type { Config }`)
import { defineConfig, mergeConfig } from 'jest';

// Base configuration shared across all test environments:
const baseConfig = defineConfig({
  preset: 'ts-jest',
  testEnvironment: 'node',
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/index.ts',
    '!src/**/__mocks__/**',
  ],
  coverageProvider: 'v8',
  coverageReporters: ['text-summary', 'lcov', 'json-summary'],
});

// Environment-specific override — mergeConfig deep-merges without losing TypeScript types:
export default mergeConfig(baseConfig, defineConfig({
  coverageThreshold: {
    global: {
      lines: 80,
      branches: 75,
      functions: 80,
      statements: 80,
    },
    './src/payments/': { lines: 95, branches: 90, functions: 95, statements: 95 },
    './src/auth/':     { lines: 90, branches: 85 },
  },
}));
```

```typescript
// jest.config.mts — Jest 30.4+: ESM TypeScript config (alternative to jest.config.ts)
// Use when your project uses "type": "module" in package.json and ESM-native imports.
// The .mts extension signals to Node that this is ESM TypeScript (not CommonJS TypeScript).
// Jest 30.4+ discovers jest.config.mts automatically — no extra setup required.
import { defineConfig } from 'jest';

export default defineConfig({
  preset: 'ts-jest/presets/default-esm',
  testEnvironment: 'node',
  extensionsToTreatAsEsm: ['.ts'],
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
  coverageProvider: 'v8',
  coverageReporters: ['text', 'html', 'lcov'],
  coverageThreshold: {
    global: { lines: 80, branches: 75, functions: 80, statements: 80 },
  },
});
```

**Migrating from `import type { Config }`**: the `defineConfig` form is a drop-in replacement.
No runtime behaviour changes — it is purely a type-safe wrapper. Pattern 1 in this guide has
been updated to the `defineConfig` form.

**`mergeConfig` key behaviour**: unlike a simple `{ ...baseConfig, ...override }` spread,
`mergeConfig` performs a **deep merge** of array and object fields. `collectCoverageFrom`
arrays are concatenated rather than replaced; `coverageThreshold` objects are merged. This
means partial overrides work correctly — a child config that only sets `global` thresholds
does not accidentally remove per-path thresholds defined in the base.

### G55 — Jest 30.4+ coverage changes: global threshold applies only to unmatched files; Babel now covers `.mts`/`.cts`  [community]

Jest 30.4.0 (May 2025) shipped two coverage changes that affect TypeScript projects but are
not prominently documented in migration guides.

**1. Global `coverageThreshold` now applies only to files NOT matched by any path/glob pattern.**

Before 30.4.0, the `global` key in `coverageThreshold` applied to the aggregate of all covered
files, including those matched by per-path or per-glob patterns. The per-path entries were
evaluated independently, but the `global` entry was computed over everything. After 30.4.0,
the `global` key applies only to the aggregate of files that do not match any named pattern.
If all files match a pattern, `global` falls back to applying against all covered files.

This is a **subtle behaviour change**, not a breaking change — but it can cause previously
passing threshold checks to fail (or previously failing checks to pass) without any config
change, if a 30.4.0 upgrade coincides with a coverage run.

```typescript
// jest.config.ts — Jest 30.4+ threshold semantics (illustrative)
import { defineConfig } from 'jest';

export default defineConfig({
  coverageThreshold: {
    // After Jest 30.4: 'global' applies to all files NOT matched by the patterns below.
    // Files in src/payments/ are evaluated against the payments pattern — they do NOT
    // count toward this global aggregate. This means the global number is computed from
    // src/utils/, src/models/, src/controllers/, etc. — everything outside payments & auth.
    global: {
      lines: 80,
      branches: 75,
      functions: 80,
      statements: 80,
    },
    // These files are evaluated by their own thresholds, NOT included in global above:
    './src/payments/': { lines: 95, branches: 90, functions: 95, statements: 95 },
    './src/auth/':     { lines: 90, branches: 85, functions: 90, statements: 90 },
    //
    // Contrast with Vitest (Pattern 31 / G50): Vitest evaluates matching files against
    // BOTH their pattern threshold AND the global threshold simultaneously.
    // Jest 30.4+: pattern-matched files are excluded from the global calculation.
  },
});
```

**Jest vs Vitest global threshold semantics (updated for Jest 30.4+):**

| Behaviour | Jest 30.4+ | Vitest 4.x |
|-----------|------------|------------|
| Global threshold scope | Files NOT matched by any pattern | ALL files (including pattern-matched) |
| Per-pattern evaluation | Independent (not double-counted against global) | Pattern AND global both apply |
| Risk of double-enforcement | None — patterns and global are mutually exclusive | Present — pattern files face both gates |
| Risk of coverage gap in global | High if critical modules all have patterns — global may be computed from only low-risk files | Lower — global always includes everything |

**2. Jest 30.4+ Babel coverage now collects from `.mts` and `.cts` TypeScript variant files.**

The Babel coverage transformer in Jest 30.4.0 gained support for `.mts` (ESM TypeScript) and
`.cts` (CJS TypeScript) file extensions. Before this fix, TypeScript source files with these
extensions were silently excluded from coverage collection when using `coverageProvider: 'babel'`
— they were executed by tests but not instrumented. **WHY it matters**: modern TypeScript
projects that use `.mts` for ESM-only modules (common in Node 22+ libraries and when
`"type": "module"` is set) were experiencing invisible coverage gaps. After Jest 30.4.0,
`.mts` and `.cts` files are instrumented by the Babel provider without any additional config.

```typescript
// jest.config.ts — Jest 30.4+: Babel now covers .mts and .cts automatically
import { defineConfig } from 'jest';

export default defineConfig({
  preset: 'ts-jest',
  testEnvironment: 'node',
  // Both .ts and .mts files are now covered by Babel provider in Jest 30.4+.
  // Before 30.4: only .ts files were instrumented; .mts files were silently excluded.
  collectCoverageFrom: [
    'src/**/*.ts',
    'src/**/*.mts',   // ESM-only TypeScript modules
    'src/**/*.cts',   // CJS-only TypeScript modules (rare, but valid)
    '!src/**/*.d.ts',
    '!src/**/*.d.mts',
    '!src/**/*.d.cts',
    '!src/**/index.ts',
  ],
  coverageProvider: 'babel',  // v8 also works; Babel fix is specifically for .mts/.cts
  coverageThreshold: {
    global: { lines: 80, branches: 75, functions: 80, statements: 80 },
  },
});
```

**Action**: if your Jest TypeScript project uses `.mts` or `.cts` files and you were on Jest
30.3.x or earlier, add those extensions to `collectCoverageFrom` after upgrading to 30.4.0.
Coverage numbers may change (these files were previously invisible — they will now appear in
the report, possibly at lower coverage if their branches were never directly tested).

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Martin Fowler — Test Coverage | Official | https://martinfowler.com/bliki/TestCoverage.html | Defines the smell-detector framing; explains why 100 % is not the goal |
| Stryker Mutator docs | Official | https://stryker-mutator.io/docs/ | Full configuration reference for Stryker JS/TS and Stryker.NET |
| Stryker — Getting started (TypeScript) | Official | https://stryker-mutator.io/docs/stryker-js/getting-started/ | Step-by-step Jest/Vitest setup for TypeScript projects |
| Stryker TypeScript checker | Official | https://stryker-mutator.io/docs/stryker-js/typescript-checker/ | TypeScript-specific mutant validation before test execution; `prioritizePerformanceOverAccuracy` (default: `true`) |
| Stryker Vitest runner | Official | https://stryker-mutator.io/docs/stryker-js/vitest-runner/ | Vitest-specific Stryker runner for TypeScript/ESM projects |
| Jest coverage configuration | Official | https://jestjs.io/docs/configuration#coveragethreshold-object | coverageThreshold schema with per-file and per-directory support |
| Vitest coverage docs | Official | https://vitest.dev/guide/coverage.html | Threshold config, V8 AST remapping (v3.2+), per-file thresholds, TypeScript support |
| Vitest 4 migration guide | Official | https://vitest.dev/guide/migration#migrating-from-vitest-3 | Vitest 4 breaking changes: coverage.all removed, coverage.extensions/ignoreEmptyLines/experimentalAstAwareRemapping removed; ignoreClassMethods now V8-compatible |
| ts-jest coverage docs | Official | https://kulshekhar.github.io/ts-jest/docs/ | ts-jest with Istanbul coverage for Jest TypeScript projects |
| c8 — V8 Native Coverage CLI | Official | https://github.com/bcoe/c8 | Lightweight V8 coverage CLI for Node.js test runner; no instrumentation overhead |
| mutmut (Python) | Official | https://mutmut.readthedocs.io/ | Python mutation testing tool reference |
| Pitest (Java) | Official | https://pitest.org/ | Java/JVM mutation testing; Maven/Gradle integration; incremental via historyInputLocation |
| fast-check (property-based, TypeScript) | Community | https://fast-check.io/ | Complement to coverage: explores full input space; TypeScript-native |
| fast-check documentation | Official | https://fast-check.io/docs/introduction/getting-started/ | Getting started with property-based testing in TypeScript |
| Google Testing Blog — Code Coverage Best Practices | Community | https://testing.googleblog.com/2020/08/code-coverage-best-practices.html | Production-grade guidance from Google's test engineering team |
| ISTQB CTFL 4.0 Syllabus | Official | https://www.istqb.org/certifications/certified-tester-foundation-level | Defines white-box coverage criteria including MC/DC |
| Kent C. Dodds — Write Fewer, Longer Tests | Community | https://kentcdodds.com/blog/write-fewer-longer-tests | Argues against coverage-driven test fragmentation |
| Codecov — Patch Coverage Docs | Official | https://docs.codecov.com/docs/patch-coverage | Coverage differential for PRs: test only new/changed lines |
| Node.js built-in test runner | Official | https://nodejs.org/api/test.html | Native Node test runner with --experimental-test-coverage, programmatic thresholds via run() |
| c8 — V8 coverage CLI (bcoe) | Official | https://github.com/bcoe/c8 | Lightweight V8 coverage wrapper for any Node test runner including ESM TypeScript |
| Meta ACH: Mutation-Guided LLM Test Generation | Research | https://arxiv.org/abs/2501.12862 | arXiv:2501.12862 — selective mutant generation + LLM synthesis; 73 % engineer acceptance at Meta scale |
| Jest 30 configuration docs | Official | https://jestjs.io/docs/configuration | Jest 30 (Oct 2025) reference; negative thresholds, moduleFileExtensions optimisation; defineConfig/mergeConfig helpers (v30.3+); jest.config.mts support (v30.4+) |
| Jest 30 changelog | Official | https://github.com/jestjs/jest/blob/main/CHANGELOG.md | Jest 30.3 defineConfig/mergeConfig; Jest 30.4 jest.config.mts, Babel .mts/.cts coverage, global threshold applies only to unmatched-pattern files (see G54, G55) |
| Stryker configuration reference | Official | https://stryker-mutator.io/docs/stryker-js/configuration/ | Full config reference: ignoreStatic, disableTypeChecks (v7 default changed to true), coverageAnalysis, timeoutFactor, concurrency, testFiles, typescriptChecker, ignorers, allowEmpty, incremental.force |
| Stryker Dashboard | Official | https://dashboard.stryker-mutator.io/ | Track mutation scores over time, generate badges, integrate with CI |
| Stryker GitHub Releases | Official | https://github.com/stryker-mutator/stryker-js/releases | Release notes for Stryker 9.x: Node 20+ requirement, Vitest v2+/v4, percentage-based concurrency, testFiles option (9.5.1); v9.6.1 Vitest 4.1 hitcount fix |
| Vitest 4 release notes | Official | https://vitest.dev/blog/vitest-4.html | Vitest 4 new features: stable Browser Mode, dynamic enableCoverage/disableCoverage API, expect.schemaMatching |
| Vitest 4.1 release notes | Official | https://vitest.dev/blog/vitest-4-1 | Vitest 4.1 coverage.changed option, agent reporter for AI environments, coverage.htmlDir |
| Vitest 4.1.5 release notes | Official | https://github.com/vitest-dev/vitest/releases/tag/v4.1.5 | Istanbul instrumenter option (experimental custom instrumenter factory); descriptive error when reports dir removed |
| Vitest 5.0.0-beta.2 release notes | Official | https://github.com/vitest-dev/vitest/releases/tag/v5.0.0-beta.2 | V8 now tracks node:child_process and node:worker_threads contexts; blob/attachments dir defaults changed |
| Vitest 5.0 coverage glob breaking change | Official | https://github.com/vitest-dev/vitest/pull/9818 | Vitest 5 fix(coverage)!: include/exclude globs too eager — bare directory names no longer auto-expand; explicit globs required |
| Stryker.NET MTP runner preview | Official | https://stryker-mutator.io/blog/ | Stryker.NET 4.13 MTP runner: keep test process alive across mutations; YAML config support; MTP vs VSTest tradeoffs |
| Qodo Cover (formerly Codium cover-agent) — ARCHIVED | Community | https://github.com/Codium-ai/cover-agent | ⚠️ No longer maintained (June 2025). LLM-based coverage gap filler; see G34 and AP13 for replacement strategy using mutation-guided prompting |
| Stryker VS Code Plugin | Official | https://stryker-mutator.io/blog/vscode-plugin/ | Inline mutation results in VS Code gutter (StrykerJS v9.3.0+, Nov 2025); uses MSP; replaces HTML-report-in-browser workflow |
| Vitest coverage config reference | Official | https://vitest.dev/config/coverage | Full coverage config: autoUpdate, changed, excludeAfterRemap, instrumenter, ignoreClassMethods, watermarks, reportOnFailure, processingConcurrency, allowExternal, cleanOnRerun, thresholds.100, thresholds[glob-pattern] per-pattern syntax, htmlDir (Vitest UI custom reporter path), html-spa reporter |
| ast-v8-to-istanbul ignore docs | Official | https://github.com/AriPerkkio/ast-v8-to-istanbul?tab=readme-ov-file#ignoring-code | Full V8 ignore directive reference: `v8 ignore next`, `start`/`stop`, `if`, `else` — branch-selective suppression unique to V8 provider |
| TypeScript 6.0 Release Notes | Official | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html | TS 6.0 default changes (module, target, types, rootDir) and removed options (outFile, classic moduleResolution) that silently break coverage tooling; ignoreDeprecations bridge flag |
| @fast-check/vitest integration | Official | https://github.com/dubzzz/fast-check/tree/main/packages/vitest | Dedicated fast-check × Vitest integration: `test.prop()`, `fc.test.failing()`, `beforeEach`/`afterEach` hooks; requires fast-check 4.x + Vitest 4.1+ |
| fast-check docs | Official | https://fast-check.io/docs/ | Property-based testing for TypeScript: arbitraries, shrinking, `fc.assert`, model-based testing |
| Node.js 24 release notes | Official | https://nodejs.org/en/blog/release/v24.0.0 | Node 24 breaking change: `test()`/`t.test()` no longer return Promises; global setup/teardown; `--experimental-strip-types` still RC status |
