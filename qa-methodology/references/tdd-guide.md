# TDD — QA Methodology Guide
<!-- lang: TypeScript | topic: tdd | iteration: 26 | score: 97/100 | date: 2026-05-12 -->
<!-- sources: training-knowledge + martinfowler.com (WebFetch) + typescript-patterns.md + is-tdd-dead-debate (WebFetch 2026-05-12) + google-testing-blog-2026 + typescript-5.6-5.8-5.9 (WebFetch 2026-05-12) + typescript-6.0 (WebFetch 2026-05-12) + vitest-4.0 (WebFetch 2026-05-12) + vitest-4.0-verbose-reporter (WebFetch 2026-05-12) + google-tott-one-map-key-one-lookup-2026-04 + google-tott-set-safe-defaults-flags-2026-03 + tcr-kent-beck-typescript + zod-v4-tdd-patterns + using-await-using-ts52 + neon-db-branching + promise-try-es2025 + vitest-4.1 (WebFetch 2026-05-12) + vitest-4.1-aria-snapshots (WebFetch 2026-05-12) + vitest-type-testing (WebFetch 2026-05-12) + typescript-6.0-baseurl-deprecation (WebFetch 2026-05-12) + typescript-6.0-subpath-imports (WebFetch 2026-05-12) + vitest-4.1-coverage-ignore-comments (WebFetch 2026-05-12) + vitest-3.2-scoped-fixtures (WebFetch 2026-05-12) + vitest-3.2-using-spyon (WebFetch 2026-05-12) + vitest-3.2-matchers-type (WebFetch 2026-05-12) + google-tott-2025-functional-core + google-tott-2025-arrange-data-flow + typescript-6.0-temporal-api (WebFetch 2026-05-12) + vitest-3.2-abortsignal + ts5to6-codemod + vitest-4.1-builder-pattern (WebFetch 2026-05-12) + vitest-3.2-annotate-api (WebFetch 2026-05-12) + vitest-3.2-sequence-grouporder | ISTQB CTFL 4.0 terminology applied -->
<!-- correction 2026-05-12: noUncheckedSideEffectImports was introduced in TypeScript 5.6 (not 5.9); TypeScript 6.0 added as new section -->
<!-- extension 2026-05-12: iter 17 — added TDD for Feature Flags (safe defaults pattern); One Map Key One Lookup for test doubles; TCR TypeScript script; gotchas #24–#26 -->
<!-- extension 2026-05-12: iter 18 — added Zod v4 TDD patterns (schemaMatching with v4 APIs, z.input/z.output for test data, migration pitfall); `using`/`await using` for TDD resource teardown; Neon DB branching for database-level TDD isolation; `Promise.try` for sync-to-async TDD wrappers; gotchas #27–#29 -->
<!-- extension 2026-05-12: iter 19 — added Vitest 4.1 TDD-relevant features: --detect-async-leaks, vi.defineHelper(), mockThrow()/mockThrowOnce(), aroundEach/aroundAll hooks, test.extend() builder, coverage.changed, test tags, GitHub Actions reporter, agent reporter; gotchas #30–#32 -->
<!-- extension 2026-05-12: iter 20 — added "The Way of TDD" (Google TotT, March 2026) pattern synthesis; Vitest 4.1 experimental native Node.js execution for ultra-fast TDD loops; Browser Mode aroundEach tracing with page.mark(); TDD discipline checklist from The Way of TDD; gotchas #33–#35 -->
<!-- extension 2026-05-12: iter 21 — added Vitest 4.1 viteModuleRunner:false (production-closer execution mode vs runner:node); Vitest 4.1 onCleanup() fixture teardown callback; Vitest 4.1 Chai-style mock assertions; TypeScript 6.0 this-less function context-sensitivity improvement; TypeScript 5.9 --module node20 vs nodenext distinction; TypeScript 7.0 preparation with --stableTypeOrdering; gotchas #36–#37 -->
<!-- extension 2026-05-12: iter 22 — added Vitest 4.1 ARIA snapshot TDD for accessibility contracts (toMatchAriaSnapshot/toMatchAriaInlineSnapshot); Type-Level TDD with Vitest expectTypeOf and *.test-d.ts files; gotchas #38–#39 -->
<!-- extension 2026-05-12: iter 23 — added TypeScript 6.0 baseUrl deprecation → paths migration for test aliases; #/ subpath import syntax alternative to @/ aliases; noUncheckedSideEffectImports now on-by-default in TS 6.0 (correction to earlier "opt-in" description); --moduleResolution bundler + --module commonjs valid combo; Vitest 4.1 coverage ignore comments with @preserve flag for esbuild; gotchas #40–#42 -->
<!-- extension 2026-05-12: iter 24 — added Vitest 3.2 native vi.spyOn/vi.fn Disposable support (direct using, no wrapper needed); Vitest 3.2 scoped fixtures (scope:'file'|'worker' in test.extend); Vitest 3.2 unified Matchers type (replaces older Assertion<R> per-context pattern); Google TotT 2025 posts (Functional Core Oct 2025, Arrange Data Flow Jan 2025) added to Key Resources; gotchas #43–#45 -->
<!-- extension 2026-05-12: iter 25 — added Temporal API TDD patterns (TypeScript 6.0 built-in types, ClockService interface injection, vi.setSystemTime for Temporal.Now); Vitest 3.2 AbortSignal per-test-case for timeout-aware TDD; ts5to6 codemod reference in TS 6.0 migration section; gotchas #46–#47 -->
<!-- extension 2026-05-12: iter 26 — added test.extend() builder pattern (Vitest 4.1, chained type-inferred fixtures); context.annotate() API (Vitest 3.2, attach diagnostic messages/files to test cases); sequence.groupOrder for multi-project test ordering; gotchas #48–#49 -->

## Core Principles

Test-Driven Development is a software development practice where you write a failing test _before_ writing any production code, then write just enough code to make it pass, then refactor — repeating the cycle continuously.

Coined and popularised by Kent Beck as part of Extreme Programming (XP), TDD is often misunderstood as merely "writing tests early." It is primarily a **design discipline**: the act of writing a test first forces you to think about the API, the dependencies, and the expected behaviour before a single line of implementation exists.

In TypeScript projects, TDD has an additional benefit: the test case drives not only behavioural specification but also type-level contract design. Writing the test first surfaces overly complex type signatures before they are baked into the implementation.

### The Red-Green-Refactor Cycle

The canonical TDD loop has exactly three phases:

1. **Red** — Write a test that fails (and fails for the right reason: the code does not exist yet). If the test fails because of a missing import or a TypeScript compilation error, fix that first before calling it "Red." A test that cannot compile is not a Red test; it is a broken test.
2. **Green** — Write the minimal production code that makes the test pass. Correctness is the only goal here; elegance is irrelevant. "Minimal" means exactly that: do not add code for features that have no test yet. Adding untested code during Green undermines the design feedback loop.
3. **Refactor** — Clean up both the production code and the test without changing observable behaviour. All tests must still pass after refactoring. The key insight: refactoring is only safe when there is a complete test suite catching regressions — which is exactly what TDD provides.

The cycle is intentionally tight — usually minutes, not hours. If a cycle takes longer than 20 minutes, the step size is too large. Break the test into a smaller piece.

**Why the cycle works:** Each phase has a single, clear goal. Red validates that the test is testing something real (a test that always passes is useless). Green produces working code with maximum design feedback. Refactor produces clean code without fear of regression.

### Baby Steps Principle

Take the smallest possible step that moves you forward. Write the simplest failing test you can imagine — not the final, comprehensive test. This keeps feedback loops short, makes debugging trivial (the last change broke something), and builds confidence incrementally.

Baby steps also force you to discover the design organically rather than over-engineering upfront. When you jump to a large test, you have to write a large chunk of implementation to make it pass. That large chunk is harder to debug, harder to name, and harder to refactor. Baby steps produce small, well-named functions because each test only forced one concern into existence.

**Why it matters:** Each baby step is a micro-hypothesis — "I believe this small piece of behaviour should work this way." Testing micro-hypotheses keeps the scientific feedback loop fast and the cost of being wrong very low.

### Triangulation

When you have a hardcoded return value making a test pass, write a **second example** that forces you to generalise the algorithm. You only generalise when forced to by at least two failing examples — this is triangulation.

Without triangulation, there is a temptation to over-abstract too early. With it, the algorithm emerges from the concrete examples.

**Why it matters:** Premature abstraction is one of the costliest mistakes in software. Triangulation provides a forcing function: you must not generalise until the concrete evidence (a second failing test) demands it. This keeps code simple and traceable to the specific requirements that produced it. Kent Beck's rule: "If you only have one example, fake it. Generalise only when a second example makes faking untenable."

### Fake-It-Til-You-Make-It

A legitimate TDD technique: return a hardcoded constant to make the first test pass, then let subsequent tests force real implementation. This is not cheating — it keeps the Green phase trivially short and makes the Red→Green→Refactor rhythm visible and fast.

**Why it matters:** Fake-it forces the discipline of "write only enough to pass." It also validates that your test infrastructure works (the test runner, the assertion, the TypeScript config, the imports) before you invest in real logic.

```typescript
// ------ RED: write the first failing test ------
// The function doesn't exist yet; this test defines the expected API and return type.
import { describe, it, expect } from 'vitest';
import { passwordStrength } from './passwordStrength.js';

type StrengthRating = 'weak' | 'medium' | 'strong';

describe('passwordStrength', () => {
  it('rates an empty string as "weak"', () => {
    const result: StrengthRating = passwordStrength('');
    expect(result).toBe('weak');
  });
});

// ------ GREEN (fake it): minimal TypeScript to pass — hardcode the result ------
// passwordStrength.ts
export type StrengthRating = 'weak' | 'medium' | 'strong';

export function passwordStrength(_password: string): StrengthRating {
  return 'weak'; // hardcoded; passes the single test case, nothing more
}

// ------ RED: triangulate — add a second example ------
it('rates a short password as "weak"', () => {
  expect(passwordStrength('abc')).toBe('weak');
  // Still 'weak', so faked value still passes — no generalisation needed yet
});

// ------ RED: third example forces a real branch ------
it('rates an 8-char mixed-case password as "medium"', () => {
  expect(passwordStrength('Abcde123')).toBe('medium');
  // 'weak' no longer passes — fake must be replaced
});

// ------ GREEN (real logic, generalised by triangulation): ------
export function passwordStrength(password: string): StrengthRating {
  if (password.length < 6) return 'weak';
  const hasMixed = /[A-Z]/.test(password) && /[a-z]/.test(password);
  const hasDigit = /\d/.test(password);
  if (hasMixed && hasDigit && password.length >= 12) return 'strong';
  if (hasMixed || hasDigit) return 'medium';
  return 'weak';
}
```

### TDD as API and Type Contract Design Tool

Writing a test first forces you to consume your own API before it exists. In TypeScript, this also means designing the type contract first. A test that is hard to type-annotate indicates that the types are wrong — not just the implementation.

**Why this is the most underrated benefit of TDD in TypeScript:** If you cannot write clean `Arrange` code without casting (`as unknown as X`), the type design is broken. TypeScript errors during test authoring are free design consultations. Code that is hard to test is almost always hard to use, and in TypeScript this manifests as awkward generics, over-wide `any` types, or missing discriminated unions.

A useful heuristic: "If the test requires a type cast to compile, the types are lying." Type casts in test code are a smell, not a workaround.

### TDD vs Test-First vs Test-After

| Practice | When test is written | Design pressure | Refactoring safety net | Cycle discipline |
|---|---|---|---|---|
| **TDD** | Before implementation | High — shapes the design and types | Yes — tests already exist | Red→Green→Refactor, strictly |
| **Test-First** | Before implementation | Medium — specifies behaviour | Yes | Red→Green only (no mandatory refactor) |
| **Test-After** | After implementation | None — tests conform to the code | Yes, but late | No cycle; tests written post-facto |
| **BDD** | Acceptance level before, unit after | High at story level | Yes | Outside-in, from acceptance to unit |

---

## When to Use

TDD works best when:

- **The domain logic is non-trivial.** Business rules, calculations, state machines, and parsers benefit greatly. The more complex the logic, the more the design feedback from writing tests first pays off.
- **The type contract is not yet clear.** Writing the test first forces you to define the TypeScript interfaces and discriminated unions — TDD is the cheapest type-contract review tool available.
- **The API boundary is not yet clear.** Writing the test first forces you to define it — TDD is the cheapest API review tool available.
- **You are working in a codebase where regression risk is high.** The accumulating test suite becomes a living specification. Teams maintaining long-lived codebases (3+ years) consistently cite TDD's regression safety as its primary value.
- **You are doing exploratory design.** TDD is a thinking tool, not just a testing tool. The act of writing a test for code that doesn't exist yet forces design decisions that would otherwise be deferred.
- **The feedback loop from running tests is fast** (< 5 seconds for the relevant subset). TDD's value collapses when running tests takes minutes — invest in test parallelisation before adopting TDD on a slow suite.
- **The team has or is building TDD muscle memory.** TDD practised without experience is slower for 4–8 weeks. It pays back in reduced debugging time and confident refactoring. Teams without TDD experience benefit from kata practice before applying it to production code.
- **Pair programming or strong code review culture exists.** TDD disciplines (especially the refactor step) are most consistently maintained when someone is watching. Solo TDD frequently drifts into test-after under deadline pressure.

---

## Patterns

### Red-Green-Refactor Cycle

```typescript
// Step 1 — RED: write a failing test case
// ShoppingCart.test.ts
import { describe, it, expect } from 'vitest';
import { ShoppingCart } from './ShoppingCart.js';

describe('ShoppingCart', () => {
  it('starts empty', () => {
    const cart = new ShoppingCart();
    expect(cart.total()).toBe(0);
  });
});

// Step 2 — GREEN: write minimal TypeScript code
// ShoppingCart.ts
export class ShoppingCart {
  total(): number {
    return 0; // fake it — only one test case so far
  }
}

// Step 3 — RED (next baby step): add an item
interface CartItem {
  price: number;
  qty: number;
}

it('totals one item', () => {
  const cart = new ShoppingCart();
  cart.add({ price: 10, qty: 1 });
  expect(cart.total()).toBe(10);
});

// Step 4 — GREEN: generalise with proper TypeScript types
export class ShoppingCart {
  readonly #items: CartItem[] = [];

  add(item: CartItem): void {
    this.#items.push(item);
  }

  total(): number {
    return this.#items.reduce((sum, i) => sum + i.price * i.qty, 0);
  }
}
```

### Baby Steps

```typescript
// ------ BAD: starting with a complex test case that requires full implementation ------
it('applies tiered discounts, shipping caps, and coupon codes', () => {
  const cart = new Cart();
  cart.add({ sku: 'A', price: 60, qty: 2 });
  cart.applyCoupon('SAVE10');
  expect(cart.total()).toBe(98); // requires discount + coupon logic simultaneously
});

// ------ GOOD: baby steps — each test case adds exactly one new behaviour ------

interface CartItem {
  sku: string;
  price: number;
  qty: number;
}

// Step 1: empty cart returns 0 (defines the constructor and total() API and return type)
it('returns 0 for an empty cart', () => {
  const cart = new Cart();
  expect(cart.total()).toBe(0);
});

// Step 2: single item (forces add() and total() to work together)
it('totals a single item', () => {
  const cart = new Cart();
  cart.add({ sku: 'A', price: 50, qty: 1 });
  expect(cart.total()).toBe(50);
});

// Step 3: quantity (forces price × qty)
it('multiplies price by quantity', () => {
  const cart = new Cart();
  cart.add({ sku: 'A', price: 10, qty: 3 });
  expect(cart.total()).toBe(30);
});

// Step 4: now discount logic can be added safely
it('applies 10% discount when subtotal exceeds 100', () => {
  const cart = new Cart();
  cart.add({ sku: 'A', price: 110, qty: 1 });
  expect(cart.total()).toBe(99);
});
```

### Triangulation

```typescript
// ------ Step 1: First example — fake it (hardcoded return passes) ------
// formatCurrency.test.ts
describe('formatCurrency', () => {
  it('formats 10 USD', () => {
    expect(formatCurrency(10, 'USD')).toBe('$10.00');
  });
});

// Minimal GREEN — just make it pass with a constant:
// formatCurrency.ts
export function formatCurrency(_amount: number, _currency: string): string {
  return '$10.00'; // hardcoded; passes the first test case, nothing more
}

// ------ Step 2: Second example forces us to generalise ------
it('formats 25.50 USD', () => {
  expect(formatCurrency(25.5, 'USD')).toBe('$25.50');
  // '$10.00' no longer passes — hardcode broken by triangulation
});

// ------ Step 3: Third example triangulates currency symbol ------
it('formats 5 EUR', () => {
  expect(formatCurrency(5, 'EUR')).toBe('€5.00');
  // Forces us to handle the currency parameter, not just the amount
});

// GREEN (real, general implementation forced by 3 examples):
export function formatCurrency(amount: number, currency: string): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
  }).format(amount);
}
```

### Fake-It-Til-You-Make-It

See the `passwordStrength` example in the **Core Principles → Fake-It-Til-You-Make-It** section above, which walks through each Red/Green step showing a hardcoded return evolving into a real implementation through triangulation.

### TDD as API Design Tool [community]

Before writing any implementation code, write the test as if the ideal API already exists. If the test feels awkward to write — or requires `as any` casts — the API or type design is wrong. This is a signal to redesign.

```typescript
// Good API and type contract discovered through test-first
// onboarding.test.ts
import { describe, it, expect } from 'vitest';
import { OnboardingService } from './OnboardingService.js';
import { FakeMailer } from './test-doubles/FakeMailer.js';

interface RegistrationInput {
  email: string;
  name: string;
}

interface SentEmail {
  to: string;
  subject: string;
}

it('sends a welcome email on user registration', async () => {
  const mailer = new FakeMailer();
  const onboarding = new OnboardingService(mailer);

  await onboarding.registerUser({ email: 'user@example.com', name: 'Alice' });

  expect(mailer.sent).toContainEqual(
    expect.objectContaining<Partial<SentEmail>>({ to: 'user@example.com', subject: 'Welcome!' })
  );
});
// The test reveals: OnboardingService needs a mailer dependency injected.
// Without TDD, mailer might have been a module-level import — untestable.
// The TypeScript interfaces SentEmail and RegistrationInput emerge from writing the test.
```

### Double-Loop TDD (Outside-In / London School) [community]

Outside-in TDD (also called the "London School" or "Mockist" style) drives implementation from acceptance tests inward to unit tests. The outer loop is a failing acceptance/integration test (the full user-visible behaviour); the inner loop is the classic red-green-refactor cycle for each collaborating object discovered along the way.

```typescript
// ---- OUTER LOOP: failing acceptance test (Supertest for an Express route) ----
// This test case stays RED until the entire feature is implemented.
import request from 'supertest';
import { app } from '../app.js';

interface RegisterResponse {
  id: string;
}

describe('POST /users/register (acceptance)', () => {
  it('returns 201 and sends a welcome email', async () => {
    const res = await request(app)
      .post('/users/register')
      .send({ email: 'alice@example.com', name: 'Alice' });

    expect(res.status).toBe(201);
    expect(res.body as RegisterResponse).toMatchObject({ id: expect.any(String) });
    expect(emailTransportSpy.calls).toHaveLength(1);
    expect(emailTransportSpy.calls[0].to).toBe('alice@example.com');
  });
});

// ---- INNER LOOP: TDD for UserService discovered by the acceptance test ----
// Each collaborator (UserService, UserRepository, EmailService) is TDD'd separately.
interface User {
  id: string;
  email: string;
  name: string;
}

describe('UserService.register', () => {
  it('creates a user and dispatches a welcome email', async () => {
    const repo = new InMemoryUserRepository();
    const emailSpy = new SpyEmailService();
    const service = new UserService(repo, emailSpy);

    const user = await service.register({ email: 'alice@example.com', name: 'Alice' });

    expect(user.id).toBeDefined();
    expect(await repo.findById(user.id)).toMatchObject<Partial<User>>({ email: 'alice@example.com' });
    expect(emailSpy.sent).toHaveLength(1);
    expect(emailSpy.sent[0]).toMatchObject({ to: 'alice@example.com', subject: 'Welcome!' });
  });
});
```

### TDD Inner Loop with Vitest Watch Mode (TypeScript)

The TDD cycle depends on a fast, always-on test feedback loop. Vitest's `--watch` mode with TypeScript provides near-instant re-runs on file save.

```typescript
// vitest.config.ts — optimised for TDD inner loop with TypeScript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Show test name in real time — important for red/green visibility
    reporter: ['verbose'],

    // Fail-fast within a file: stop after first failure per test file
    // This keeps the RED phase signal clean during TDD
    bail: 1,

    // TypeScript coverage with v8 — only in CI, not during TDD watch loop
    coverage: {
      enabled: process.env.CI === 'true',
      provider: 'v8',
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/test-doubles/**/*.ts'],
      thresholds: { branches: 80, functions: 80, lines: 80 },
    },
  },
});
```

```bash
# Start the TDD inner loop: Vitest watches for changes and re-runs related tests
npx vitest --watch

# Run a single test file during a focused TDD session
npx vitest --watch src/domain/cart/Cart.test.ts

# Run test cases matching a pattern (useful when drilling into one failing test case)
npx vitest --watch -t "totals one item"
```

### TypeScript Project Setup for TDD

A correctly configured TypeScript project dramatically improves TDD ergonomics. The following setup targets Vitest with ESM modules — the most common setup for new TypeScript projects in 2025–2026.

```jsonc
// tsconfig.json — production TypeScript config (TDD-friendly)
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,                    // Required: makes type contracts in tests precise
    "exactOptionalPropertyTypes": true, // Prevents optional fields from accepting undefined
    "noUncheckedIndexedAccess": true,  // Array[n] returns T | undefined — forces null checks
    "noImplicitOverride": true,         // Prevents accidental overrides of inherited methods
    "useUnknownInCatchVariables": true, // catch(e) typed as unknown, not any
    "outDir": "./dist",
    "rootDir": "./src",
    "paths": {
      "@domain/*": ["./src/domain/*"],
      "@test-doubles/*": ["./src/test-doubles/*"]
    }
  },
  "include": ["src/**/*.ts"],
  "exclude": ["src/**/*.test.ts"]
}
```

```typescript
// vitest.config.ts — optimised for TypeScript TDD inner loop
import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths'; // resolve path aliases in tests

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    // Use the same tsconfig as production — no lax test-only tsconfig
    // This ensures test types are as strict as production types
    typecheck: {
      tsconfig: './tsconfig.json',
    },
    include: ['src/**/*.test.ts'],
    reporter: ['verbose'],
    bail: 1,          // TDD: stop at first failure for clear Red signal
    globals: false,   // Explicit imports preferred in TypeScript (aids type inference)
    coverage: {
      enabled: process.env.CI === 'true',
      provider: 'v8',
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/test-doubles/**/*.ts', 'src/**/*.d.ts'],
      thresholds: { branches: 80, functions: 80, lines: 80, statements: 80 },
    },
  },
});
```

**Why this configuration matters for TDD:**
- `strict: true` + `noUncheckedIndexedAccess` in the production `tsconfig` means tests must handle `T | undefined` from array access — which surfaces defensive-coding needs during the Red phase, before implementation.
- `vite-tsconfig-paths` lets test imports use `@domain/Cart` instead of `../../../domain/Cart`, keeping test code readable and reducing refactor churn when files move.
- Using the same `tsconfig.json` for tests and production (via `typecheck.tsconfig`) ensures type errors caught by tsc in production are also caught in tests.

### Custom Matchers for Domain Types [community]

TypeScript's type system allows creating type-safe custom Vitest matchers that make TDD test cases read like domain language. This reduces test boilerplate and makes the Red phase failure messages meaningful.

```typescript
// test-doubles/matchers.ts — domain-specific Vitest matchers
import { expect } from 'vitest';

// Vitest 3.2+ unified Matchers type — works across expect().to*, expect.to*, and all assertion contexts
// This replaces the older per-context `interface Assertion<R>` pattern which required separate
// declarations for regular assertions, async assertions, and negated assertions.
declare module 'vitest' {
  interface Matchers<T = any> {
    toBeSuccessResult(): T;
    toBeFailureResult(expectedError?: string): T;
    toBeWithinCents(expected: number, toleranceCents?: number): T;
  }
}

// Note: for projects still on Vitest < 3.2, use the older pattern:
// declare module 'vitest' {
//   interface Assertion<R = unknown> {
//     toBeSuccessResult(): R;
//     toBeFailureResult(expectedError?: string): R;
//     toBeWithinCents(expected: number, toleranceCents?: number): R;
//   }
// }

expect.extend({
  toBeSuccessResult(received: unknown) {
    const pass = typeof received === 'object' && received !== null
      && 'success' in received && received.success === true;
    return {
      pass,
      message: () => pass
        ? `Expected result NOT to be successful, but got: ${JSON.stringify(received)}`
        : `Expected a successful Result, but got: ${JSON.stringify(received)}`,
    };
  },

  toBeFailureResult(received: unknown, expectedError?: string) {
    const isFailure = typeof received === 'object' && received !== null
      && 'success' in received && received.success === false;
    const hasCorrectError = !expectedError || (
      'error' in (received as object)
      && String((received as { error: unknown }).error) === expectedError
    );
    const pass = isFailure && hasCorrectError;
    return {
      pass,
      message: () => pass
        ? `Expected result NOT to be a failure`
        : `Expected Result.failure${expectedError ? ` with error "${expectedError}"` : ''}, got: ${JSON.stringify(received)}`,
    };
  },

  toBeWithinCents(received: number, expected: number, toleranceCents = 1) {
    const diff = Math.abs(Math.round(received * 100) - Math.round(expected * 100));
    const pass = diff <= toleranceCents;
    return {
      pass,
      message: () => pass
        ? `Expected ${received} NOT to be within ${toleranceCents} cent(s) of ${expected}`
        : `Expected ${received} to be within ${toleranceCents} cent(s) of ${expected}, but diff was ${diff} cent(s)`,
    };
  },
});

// Usage in TDD test cases — reads like domain language:
// priceCalculator.test.ts
import { describe, it, expect } from 'vitest';
import '../test-doubles/matchers.js'; // import for side effects (extend)
import { calculatePrice } from './priceCalculator.js';

describe('calculatePrice', () => {
  it('returns a successful result for a valid price', () => {
    const result = calculatePrice({ basePrice: 100, vatRate: 0.2 });
    expect(result).toBeSuccessResult();
  });

  it('returns failure for a negative price', () => {
    const result = calculatePrice({ basePrice: -1, vatRate: 0.2 });
    expect(result).toBeFailureResult('Price must be non-negative');
  });

  it('calculates price within floating-point tolerance', () => {
    const result = calculatePrice({ basePrice: 10.1, vatRate: 0.1 });
    if (result.success) {
      expect(result.value.total).toBeWithinCents(11.11);
    }
  });
});
```

**Why custom matchers improve TDD:** Test failure messages from custom matchers use domain language ("Expected a successful Result") rather than generic assertion messages ("expected false to equal true"). This makes the Red phase diagnostic immediately actionable — the failing test case tells you what domain invariant was violated, not just which primitive value was wrong.

### Transformation Priority Premise (TPP) [community]

Robert C. Martin's Transformation Priority Premise provides a formal ordering for the generalisation steps from fake-it to real implementation. Following lower-priority transformations first keeps each TDD step as small as possible.

Ordered from simplest (1) to most complex (9):
1. `{} → nil` — return nothing
2. `nil → constant` — return a literal constant
3. `constant → constant+` — return a slightly more complex constant
4. `constant → scalar` — replace a constant with a variable/argument
5. `statement → statements` — add an unconditional statement
6. `unconditional → if` — introduce a conditional
7. `scalar → array` — scalar becomes a collection
8. `array → container` — collection becomes a data structure
9. `statement → tail-call` → introduce recursion

```typescript
// TPP demonstration: FizzBuzz red-green steps using lowest available transformation
import { describe, it, expect } from 'vitest';
import { fizzBuzz } from './fizzBuzz.js';

// Test case 1: n=1 → "1"
it('returns "1" for n=1', () => expect(fizzBuzz(1)).toBe('1'));
// Transformation: {} → constant (cheapest). GREEN with: return '1';

// Test case 2: n=2 → "2"
it('returns "2" for n=2', () => expect(fizzBuzz(2)).toBe('2'));
// Transformation: constant → scalar. GREEN with: return String(n);

// Test case 3: n=3 → "Fizz"
it('returns "Fizz" for n=3', () => expect(fizzBuzz(3)).toBe('Fizz'));
// GREEN: export function fizzBuzz(n: number): string {
//   return n % 3 === 0 ? 'Fizz' : String(n);
// }

// Test case 4: n=5 → "Buzz"
it('returns "Buzz" for n=5', () => expect(fizzBuzz(5)).toBe('Buzz'));

// Test case 5: n=15 → "FizzBuzz"
it('returns "FizzBuzz" for n=15', () => expect(fizzBuzz(15)).toBe('FizzBuzz'));

// Final GREEN — minimal TypeScript, shaped by TPP:
export function fizzBuzz(n: number): string {
  if (n % 15 === 0) return 'FizzBuzz';
  if (n % 3 === 0) return 'Fizz';
  if (n % 5 === 0) return 'Buzz';
  return String(n);
}
```

### Test Doubles Taxonomy [community]

The TDD community uses five distinct test double types (Gerard Meszaros, *xUnit Test Patterns*). Conflating them leads to over-mocking and brittle test suites.

| Type | What it does | When to use |
|------|-------------|-------------|
| **Dummy** | Passed but never used; satisfies a parameter requirement | Constructor requires a dep you don't need for this test case |
| **Stub** | Returns a canned answer when called; no assertion on it | Control indirect inputs to the test object |
| **Spy** | Records calls made to it; assertions checked after the fact | Verify that a side effect was triggered, without hard coupling |
| **Mock** | Pre-programmed expectations; fails immediately on unexpected calls | Verify interaction protocol strictly (use sparingly) |
| **Fake** | Working implementation with shortcut (e.g., in-memory DB) | Replace heavyweight infrastructure while keeping behaviour real |

```typescript
// vitest doubles taxonomy — each type demonstrated with TypeScript interfaces
import { vi, describe, it, expect } from 'vitest';

// Define interfaces for the doubles — TypeScript forces explicit contracts
interface Logger { info(msg: string): void; error(msg: string): void; }
interface ExchangeRateService { getExchangeRate(from: string, to: string): Promise<number>; }
interface MailSendOptions { to: string; subject: string; body?: string; }
interface Mailer { send(opts: MailSendOptions): Promise<void>; }

// ── DUMMY ────────────────────────────────────────────────────────────────────
const dummyLogger: Logger = { info: () => {}, error: () => {} };
const service = new OrderService(realRepo, dummyLogger);

// ── STUB ──────────────────────────────────────────────────────────────────────
const rateStub: ExchangeRateService = {
  getExchangeRate: vi.fn<[string, string], Promise<number>>().mockResolvedValue(1.25)
};
const pricer = new Pricer(rateStub);

// ── SPY ───────────────────────────────────────────────────────────────────────
class SpyMailer implements Mailer {
  readonly sent: MailSendOptions[] = [];
  async send(opts: MailSendOptions): Promise<void> { this.sent.push(opts); }
}
const mailerSpy = new SpyMailer();
await checkoutService.complete({ orderId: '1', mailer: mailerSpy });
expect(mailerSpy.sent).toHaveLength(1);
expect(mailerSpy.sent[0]).toMatchObject<Partial<MailSendOptions>>({ subject: 'Order confirmed' });

// ── FAKE ──────────────────────────────────────────────────────────────────────
// In-memory repository typed against an interface — behaves like the real DB
interface UserRepository {
  save(user: User): Promise<User>;
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
}

class InMemoryUserRepository implements UserRepository {
  readonly #store = new Map<string, User>();
  async save(user: User): Promise<User>          { this.#store.set(user.id, user); return user; }
  async findById(id: string): Promise<User | null>      { return this.#store.get(id) ?? null; }
  async findByEmail(email: string): Promise<User | null> {
    return [...this.#store.values()].find(u => u.email === email) ?? null;
  }
}
```

**Community signal:** The most common TDD mistake in TypeScript is using `vi.fn()` mocks typed with `any` for everything. Typing test doubles against interfaces (as above) means TypeScript will tell you if the interface changes but your double does not — preventing silent divergence.

### Async TDD — Testing State Machines with Discriminated Unions [community]

TypeScript's discriminated unions are ideal for modelling state machines. TDD drives the type design first.

```typescript
// TDD for a typed order state machine using discriminated union
// The test cases define the valid transitions before any implementation

type OrderStatus = 'pending' | 'processing' | 'shipped' | 'delivered';

interface OrderState {
  status: OrderStatus;
  orderId: string;
}

// Test case 1: RED — valid transition
it('transitions from pending to processing', async () => {
  const order = new Order({ orderId: 'ORD-1', status: 'pending' });
  await order.startProcessing();
  expect(order.status).toBe<OrderStatus>('processing');
});

// Test case 2: RED — invalid transition throws
it('throws when attempting to ship a pending order', async () => {
  const order = new Order({ orderId: 'ORD-1', status: 'pending' });
  await expect(order.ship()).rejects.toThrow('Cannot ship: order is not processing');
});

// Test case 3: RED — concurrent calls race guard
it('handles concurrent startProcessing calls safely', async () => {
  const order = new Order({ orderId: 'ORD-1', status: 'pending' });
  const [result1, result2] = await Promise.allSettled([
    order.startProcessing(),
    order.startProcessing(),
  ]);
  const successes = [result1, result2].filter(r => r.status === 'fulfilled').length;
  const failures  = [result1, result2].filter(r => r.status === 'rejected').length;
  expect(successes).toBe(1);
  expect(failures).toBe(1);
  expect(order.status).toBe<OrderStatus>('processing');
});

// GREEN: typed implementation driven by the test cases above
export class Order {
  #status: OrderStatus;
  readonly #orderId: string;
  #transitioning = false;

  constructor({ orderId, status }: OrderState) {
    this.#orderId = orderId;
    this.#status = status;
  }

  get status(): OrderStatus { return this.#status; }
  get orderId(): string { return this.#orderId; }

  async #transition(from: OrderStatus, to: OrderStatus, errorMsg: string): Promise<void> {
    if (this.#status !== from || this.#transitioning) {
      throw new Error(errorMsg);
    }
    this.#transitioning = true;
    try {
      await Promise.resolve();
      this.#status = to;
    } finally {
      this.#transitioning = false;
    }
  }

  startProcessing(): Promise<void> {
    return this.#transition('pending', 'processing', 'Cannot process: order is already processing');
  }
  ship(): Promise<void> {
    return this.#transition('processing', 'shipped', 'Cannot ship: order is not processing');
  }
  deliver(): Promise<void> {
    return this.#transition('shipped', 'delivered', 'Cannot deliver: order is not shipped');
  }
}
```

### Characterisation Tests for Legacy TypeScript Code [community]

Before refactoring existing TypeScript code, write test cases that lock down the current behaviour. These are "characterisation tests" (Michael Feathers).

```typescript
// Legacy function with undocumented TypeScript behaviour — characterise before refactoring
// parseLegacyDate.ts (do not modify during characterisation phase)
export function parseLegacyDate(str: string): Date | null {
  // 80 lines of undocumented date parsing logic
  // return type annotation may not match actual runtime returns
}

// Step 1: Write characterisation test cases — probe with real inputs
import { describe, it, expect } from 'vitest';
import { parseLegacyDate } from './parseLegacyDate.js';

describe('parseLegacyDate (characterisation)', () => {
  it('parses "2024-01-15" → Date(2024, 0, 15)', () => {
    const result = parseLegacyDate('2024-01-15');
    expect(result).toEqual(new Date(2024, 0, 15));
  });

  it('returns null for empty string', () => {
    expect(parseLegacyDate('')).toBeNull();
  });

  it('returns null for "not-a-date"', () => {
    expect(parseLegacyDate('not-a-date')).toBeNull();
  });

  it('parses "15/01/2024" in DD/MM/YYYY format', () => {
    const result = parseLegacyDate('15/01/2024');
    expect(result).toEqual(new Date(2024, 0, 15));
  });
});
// Step 2: All characterisation test cases pass → safe to refactor
// Step 3: Add new TDD test cases for the corrected/intended behaviour
```

### Functional Core / Imperative Shell (TDD-Friendly Architecture) [community]

Gary Bernhardt's "Functional Core, Imperative Shell" architecture separates pure typed decision logic (easy to TDD) from side-effectful orchestration (hard to TDD).

```typescript
// ---- FUNCTIONAL CORE: pure TypeScript functions — easy to TDD with zero mocking ----
// cart-logic.ts

export type DiscountType = 'pct' | 'flat';

export interface Discount {
  type: DiscountType;
  value: number;
}

export interface CartItem {
  sku: string;
  price: number;
  qty: number;
}

export function applyDiscount(subtotal: number, discount: Discount): number {
  if (discount.type === 'pct') return subtotal * (1 - discount.value / 100);
  return Math.max(0, subtotal - discount.value);
}

export function calculateTotal(items: CartItem[], discount: Discount | null): number {
  const subtotal = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  return discount ? applyDiscount(subtotal, discount) : subtotal;
}

// TDD test cases for the pure core — no mocks, no async, no setup boilerplate
describe('calculateTotal', () => {
  it('sums item totals', () => {
    expect(calculateTotal([{ sku: 'A', price: 10, qty: 2 }], null)).toBe(20);
  });
  it('applies percentage discount', () => {
    expect(calculateTotal(
      [{ sku: 'A', price: 100, qty: 1 }],
      { type: 'pct', value: 10 }
    )).toBe(90);
  });
  it('applies flat discount without going below zero', () => {
    expect(calculateTotal(
      [{ sku: 'A', price: 5, qty: 1 }],
      { type: 'flat', value: 10 }
    )).toBe(0);
  });
});

// ---- IMPERATIVE SHELL: thin typed orchestrator — integration tested, not unit TDD'd ----
// checkout-handler.ts
import { calculateTotal, CartItem, Discount } from './cart-logic.js';

interface CheckoutRequest { userId: string; couponCode?: string; }
interface CheckoutResponse { status: number; body: { total: number }; }

export async function checkoutHandler(
  req: CheckoutRequest,
  db: Database
): Promise<CheckoutResponse> {
  const items: CartItem[] = await db.getCartItems(req.userId);
  const coupon = req.couponCode ? await db.findCoupon(req.couponCode) : null;
  const discount: Discount | null = coupon?.discount ?? null;
  const total = calculateTotal(items, discount);
  await db.createOrder({ userId: req.userId, total });
  return { status: 201, body: { total } };
}
```

### TDD for React Hooks — Extractable Logic Layer [community]

TDD is awkward when applied directly to rendered components, but React hooks with business logic can be TDD'd in isolation using Vitest's `renderHook`.

```typescript
// TDD for a useShoppingCart hook with TypeScript types
// useShoppingCart.test.ts
import { describe, it, expect } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useShoppingCart, CartItem } from './useShoppingCart.js';

// Test case 1: RED — hook starts with empty cart
it('starts with an empty cart', () => {
  const { result } = renderHook(() => useShoppingCart());
  expect(result.current.items).toEqual<CartItem[]>([]);
  expect(result.current.total).toBe(0);
});

// Test case 2: RED — adding an item updates total
it('adds an item and recalculates total', () => {
  const { result } = renderHook(() => useShoppingCart());
  act(() => result.current.addItem({ sku: 'A', price: 25, qty: 2 }));
  expect(result.current.items).toHaveLength(1);
  expect(result.current.total).toBe(50);
});

// Test case 3: RED — merges duplicate sku quantities
it('merges quantities when the same sku is added twice', () => {
  const { result } = renderHook(() => useShoppingCart());
  act(() => result.current.addItem({ sku: 'A', price: 10, qty: 1 }));
  act(() => result.current.addItem({ sku: 'A', price: 10, qty: 3 }));
  expect(result.current.items[0].qty).toBe(4);
  expect(result.current.total).toBe(40);
});

// GREEN: implement the typed hook
// useShoppingCart.ts
import { useState, useMemo } from 'react';

export interface CartItem { sku: string; price: number; qty: number; }

interface ShoppingCartHook {
  items: CartItem[];
  total: number;
  addItem(item: CartItem): void;
  removeItem(sku: string): void;
}

export function useShoppingCart(): ShoppingCartHook {
  const [items, setItems] = useState<CartItem[]>([]);

  const addItem = (item: CartItem): void =>
    setItems(prev => {
      const existing = prev.find(i => i.sku === item.sku);
      if (existing) {
        return prev.map(i => i.sku === item.sku ? { ...i, qty: i.qty + item.qty } : i);
      }
      return [...prev, item];
    });

  const removeItem = (sku: string): void =>
    setItems(prev => prev.filter(i => i.sku !== sku));

  const total = useMemo(
    () => items.reduce((sum, i) => sum + i.price * i.qty, 0),
    [items]
  );

  return { items, total, addItem, removeItem };
}
```

### TDD with Generics and Utility Types [community]

TypeScript generics allow TDD to drive the design of reusable typed containers. Writing the test case first forces you to define the generic constraints before any implementation, preventing the common mistake of over-widening type parameters to `any` or `unknown` just to compile.

```typescript
// TDD for a generic Result type — common in TypeScript domain-driven design
// result.test.ts
import { describe, it, expect } from 'vitest';
import { Result, ok, err } from './result.js';

// Test case 1: RED — ok() wraps a success value
it('ok() creates a successful result', () => {
  const result: Result<number, string> = ok(42);
  expect(result.success).toBe(true);
  if (result.success) {
    expect(result.value).toBe(42);
  }
});

// Test case 2: RED — err() wraps a failure value
it('err() creates a failure result', () => {
  const result: Result<number, string> = err('not found');
  expect(result.success).toBe(false);
  if (!result.success) {
    expect(result.error).toBe('not found');
  }
});

// Test case 3: RED — map() transforms the success value, leaves error unchanged
it('map() applies transform to success value', () => {
  const result = ok(21).map((n: number) => n * 2);
  expect(result.success).toBe(true);
  if (result.success) {
    expect(result.value).toBe(42);
  }
});

it('map() is a no-op on an error result', () => {
  const result = err<number, string>('fail').map((n: number) => n * 2);
  expect(result.success).toBe(false);
});

// Test case 4: RED — flatMap() chains Result-returning operations
it('flatMap() chains successful results', () => {
  const parseId = (s: string): Result<number, string> =>
    Number.isNaN(Number(s)) ? err('not a number') : ok(Number(s));

  const result = ok('42').flatMap(parseId);
  expect(result.success).toBe(true);
  if (result.success) {
    expect(result.value).toBe(42);
  }
});

// GREEN: implement the generic Result type driven by test cases
// result.ts
export type Result<T, E> =
  | { success: true;  value: T; map<U>(f: (v: T) => U): Result<U, E>; flatMap<U>(f: (v: T) => Result<U, E>): Result<U, E> }
  | { success: false; error: E; map<U>(f: (v: T) => U): Result<U, E>; flatMap<U>(f: (v: T) => Result<U, E>): Result<U, E> };

class OkResult<T, E> implements Extract<Result<T, E>, { success: true }> {
  readonly success = true as const;
  constructor(readonly value: T) {}
  map<U>(f: (v: T) => U): Result<U, E>              { return new OkResult<U, E>(f(this.value)); }
  flatMap<U>(f: (v: T) => Result<U, E>): Result<U, E> { return f(this.value); }
}

class ErrResult<T, E> implements Extract<Result<T, E>, { success: false }> {
  readonly success = false as const;
  constructor(readonly error: E) {}
  map<U>(_f: (v: T) => U): Result<U, E>              { return new ErrResult<U, E>(this.error); }
  flatMap<U>(_f: (v: T) => Result<U, E>): Result<U, E> { return new ErrResult<U, E>(this.error); }
}

export function ok<T, E = never>(value: T): Result<T, E>  { return new OkResult<T, E>(value); }
export function err<T = never, E = unknown>(error: E): Result<T, E> { return new ErrResult<T, E>(error); }
```

**Why TDD with generics matters:** When you write the test case first using `Result<number, string>`, TypeScript's type checker immediately validates that the generic constraint is correct. If you had started with implementation and written `Result<any, any>`, the test cases would compile with no safety. TDD drives precise generic constraints from the consumer's perspective.

### Mutation Testing as a TDD Audit [community]

Mutation testing (Stryker for TypeScript) answers the question: "Do the test cases actually fail when the production code is broken?"

```typescript
// stryker.config.mjs — Stryker configuration for a Vitest + TypeScript project
export default {
  packageManager: 'npm',
  reporters: ['html', 'clear-text', 'progress'],
  testRunner: 'vitest',
  coverageAnalysis: 'perTest',
  vitest: {
    configFile: 'vitest.config.ts',
  },
  mutate: [
    'src/**/*.ts',
    '!src/**/*.test.ts',
    '!src/**/test-doubles/**/*.ts',
  ],
  thresholds: {
    high: 80,    // Green: mutation score ≥ 80%
    low: 60,     // Yellow: 60–80% — review these survivors
    break: 50,   // CI fails: < 50% — test cases are not verifying behaviour
  },
};
```

**Practical guidance:** A TypeScript TDD codebase with 90%+ line coverage often has only 65–70% mutation score on first run — revealing test cases that were written to pass, not to catch defects. Run Stryker monthly on critical modules (payment, auth, pricing).

---

## Anti-Patterns

| Anti-Pattern | Why It Hurts |
|---|---|
| **Writing tests after the fact to hit coverage** | No design benefit; tests often mirror implementation rather than specifying behaviour |
| **Testing implementation details** | Tests break on every refactor; defeats the purpose of the refactor phase |
| **Giant test setup** | If arrange phase is enormous, the design has too many dependencies — a design smell |
| **Skipping the Refactor phase** | Leads to test-covered spaghetti; TDD without refactoring accumulates design debt |
| **Testing one big thing per cycle** | If a cycle takes hours, feedback is slow; baby steps are the cure |
| **Mocking everything with `vi.fn<any>()`** | Over-mocking produces tests that pass even when the real system is broken; `any` type loses TypeScript safety |
| **Using `as any` casts in test code** | Type casts in tests hide design problems; if you need `as any`, the types are wrong |
| **Writing tests for trivial getters/setters** | Adds noise with no signal; focus on behaviour, not data containers |

### Anti-Pattern Deep Dive: Testing Implementation Details

```typescript
// BAD: testing implementation details — breaks on any internal rename
describe('UserService', () => {
  it('calls repository.save exactly once', async () => {
    const repo = { save: vi.fn<[User], Promise<User>>(), findByEmail: vi.fn() };
    const service = new UserService(repo);
    await service.createUser({ email: 'a@b.com', name: 'A' });
    // This asserts HOW, not WHAT — brittle
    expect(repo.save).toHaveBeenCalledTimes(1);
  });
});

// GOOD: test observable output using a typed fake — survives internal restructuring
describe('UserService', () => {
  it('creates and persists a user', async () => {
    const repo = new InMemoryUserRepository(); // typed, real fake — not a mock
    const service = new UserService(repo);

    const user = await service.createUser({ email: 'a@b.com', name: 'A' });

    // Assert WHAT, not HOW: the user exists in the store
    const found = await repo.findByEmail('a@b.com');
    expect(found).toMatchObject<Partial<User>>({ id: user.id, email: 'a@b.com' });
  });
});
```

### Anti-Pattern Deep Dive: Using `as any` in Test Doubles

```typescript
// BAD: type cast hides interface mismatch — TypeScript can't help you
const fakeRepo = {
  save: vi.fn(),
  findById: vi.fn(),
} as any; // loses all TypeScript checking

// GOOD: implement the interface — TypeScript will catch divergence
class InMemoryUserRepository implements UserRepository {
  readonly #store = new Map<string, User>();
  async save(user: User): Promise<User>         { this.#store.set(user.id, user); return user; }
  async findById(id: string): Promise<User | null>     { return this.#store.get(id) ?? null; }
  async findByEmail(email: string): Promise<User | null> {
    return [...this.#store.values()].find(u => u.email === email) ?? null;
  }
}
// When UserRepository interface changes, TypeScript errors immediately in the fake —
// forcing you to update the fake before the tests silently diverge.
```

---

## When TDD Is Hard

### Legacy Code Without Seams

Legacy code that was not written test-first often has no "seams." Global state, static method calls, `new` inside constructors, and direct filesystem/network calls make TDD almost impossible without first adding seams (Extract Interface, Parameterise Constructor, Wrap and Inject). TypeScript's `interface` keyword is ideal for introducing seams without changing runtime behaviour.

```typescript
// ------ BEFORE: untestable legacy — hard-coded dependency, no seam ------
// order-processor.ts
import { PostgresDatabase } from './db/postgres.js';
import { EmailClient } from './email/client.js';

export class OrderProcessor {
  async processOrder(orderId: string): Promise<void> {
    const db = new PostgresDatabase();          // hard dependency, cannot swap
    const order = await db.findOrder(orderId);
    if (order.status === 'pending') {
      await db.updateStatus(orderId, 'processing');
      new EmailClient().send(order.email, 'Your order is being processed');
    }
  }
}

// ------ AFTER: add seams via TypeScript interfaces and constructor injection ------
interface OrderDatabase {
  findOrder(id: string): Promise<{ status: string; email: string }>;
  updateStatus(id: string, status: string): Promise<void>;
}

interface OrderMailer {
  send(to: string, message: string): Promise<void>;
}

export class OrderProcessor {
  constructor(
    private readonly db: OrderDatabase,
    private readonly mailer: OrderMailer
  ) {}

  async processOrder(orderId: string): Promise<void> {
    const order = await this.db.findOrder(orderId);
    if (order.status === 'pending') {
      await this.db.updateStatus(orderId, 'processing');
      await this.mailer.send(order.email, 'Your order is being processed');
    }
  }
}

// TDD test case now possible using typed fakes
it('updates status and sends email when order is pending', async () => {
  const db: OrderDatabase = new InMemoryOrderDatabase([
    { id: '42', status: 'pending', email: 'buyer@example.com' }
  ]);
  const mailer = new SpyMailer();
  const processor = new OrderProcessor(db, mailer);

  await processor.processOrder('42');

  expect(mailer.sent[0].to).toBe('buyer@example.com');
});
```

### Complex UI Interactions

Pure TDD (tiny failing unit test first) is awkward when the thing you are building is a drag-and-drop calendar. **Practical approach:** Apply TDD to the logic layer (hooks, view models, reducers) and use snapshot or end-to-end tests for UI composition.

### Algorithm Discovery (Spike First)

When you are discovering an algorithm, you often do not know what the right answer is until you have run the code. **Practical approach:** Spike first, identify the algorithm, extract it into a pure TypeScript function with explicit types, then apply TDD to the extracted function.

### Third-Party API Integration

**Practical approach:** Wrap the third-party API in a typed adapter interface, test the adapter with contract tests, and TDD everything else against the adapter's interface. The TypeScript interface becomes the contract.

---

## Real-World Gotchas [community]

1. **[community] The test suite becomes a second codebase.** At scale, tests need the same architectural discipline as production code. A recurring pattern in TypeScript projects: a 5-year-old TDD project where renaming a domain type requires changing 400 test files because tests were written against internal state instead of public behaviour. TypeScript makes this worse if tests use `as any` casts that hide real interface contracts.

2. **[community] TDD slows down initial feature velocity — intentionally.** The first time you use TDD on a new domain, it will take longer. The payback is in the third and fourth sprint when you are changing code without fear. Teams that measure only sprint velocity abandon TDD before the payback arrives.

3. **[community] Mocking at the wrong layer is the most common TDD mistake.** When you mock a database repository in a service test, you are no longer testing whether the service and repository work together. Prefer typed in-memory fakes for persistence. Production example: a team whose mocked repository always returned sorted results, masking a sort bug in the real DB adapter for six months.

4. **[community] "Outside-in TDD" (London School) and "inside-out TDD" (Chicago/Detroit School) produce different architectures.** Outside-in starts with acceptance tests and mocks collaborators; inside-out starts with domain objects and avoids mocks. Mixing the two produces incoherent test suites. Teams must align on one school before starting a project — retrofitting is expensive.

5. **[community] Test names are the most important documentation in a TDD codebase.** When a test fails in CI, the name is the first signal. Names like `test1` or `renders correctly` are worthless; names like `throws when payment is attempted on a cancelled order` save hours. A good rule: if you cannot understand the failure from the test name alone, rename it before fixing it.

6. **[community] TypeScript's `strictNullChecks` reveals TDD coverage gaps.** Enabling `strict: true` in `tsconfig.json` in a project that was TDD'd under loose settings often reveals test cases that passed only because `null` and `undefined` were silently coerced. Teams enabling strict mode mid-project often find 15–30 latent defects in their TDD-covered code. Enable strict mode from day one — it makes TDD's behavioural specifications more precise.

7. **[community] The refactor phase is the most skipped step in practice.** Developers hit Green and move to the next test. Without continuous refactoring, TDD accumulates technical debt just as fast as no tests — it just has a safety net while doing so. In TypeScript, the refactor phase is also where you should tighten types (replace `string` with a string literal union, add `readonly`, remove unnecessary `?`).

8. **[community] `vi.fn()` typed with `any` or untyped produces false-safe tests.** In TypeScript projects, `vi.fn()` without a generic type parameter infers `any` for arguments and return value. When the real interface changes, the mock does not fail TypeScript checks. Always type mocks: `vi.fn<[string], Promise<User>>()` or use an `interface` implementation.

9. **[community] Continuous Integration amplifies TDD's benefits — but TypeScript compile time can erode the feedback loop.** A TDD codebase with long CI feedback cycles (>10 minutes) loses most of its advantage. TypeScript's `tsc` compilation adds latency; use Vitest with `esbuild` (default) to skip full type-checking during the TDD watch loop. Run `tsc --noEmit` separately in CI as a type-safety gate.

10. **[community] "Delete the tests and re-TDD" is a legitimate rescue technique for legacy test suites.** When a test suite is so tightly coupled to implementation that it prevents refactoring, experienced TDD practitioners sometimes recommend deleting the unit tests, keeping only acceptance/integration tests as a safety net, and re-growing the unit test suite via TDD. In TypeScript, this approach also provides an opportunity to replace `any`-typed test doubles with properly typed fakes.

11. **[community] Module-level side effects break TDD isolation in TypeScript too.** When a module executes code on import (establishing DB connections, starting timers), every test that imports it inherits those side effects.

```typescript
// BAD: module-level side effect — executes on every import in every test
// db.ts
import { Pool } from 'pg';
export const pool = new Pool({ connectionString: process.env.DB_URL });
// Every test that transitively imports db.ts opens a real connection.

// GOOD: factory function with lazy init
// db.ts
import { Pool } from 'pg';
let _pool: Pool | null = null;
export function getPool(): Pool {
  _pool ??= new Pool({ connectionString: process.env.DB_URL });
  return _pool;
}
// Tests inject InMemoryDatabase; real pool never created during test suite run.
```

12. **[community] Property-based testing finds boundary defects that TDD misses.** TDD produces test cases from hand-picked examples; property-based tests (fast-check) generate hundreds of random examples. In TypeScript projects, `fc.record()` with type-safe property generators finds edge cases at integer boundaries, empty arrays, and Unicode strings that hand-crafted test cases miss.

```typescript
// Property-based test complementing the TDD test suite for calculateTotal
import { describe, it } from 'vitest';
import * as fc from 'fast-check';
import { calculateTotal, CartItem } from './cart-logic.js';

describe('calculateTotal (property-based)', () => {
  it('never returns a negative total', () => {
    fc.assert(
      fc.property(
        fc.array(fc.record<CartItem>({
          sku: fc.string(),
          price: fc.float({ min: 0, max: 10_000, noNaN: true }),
          qty: fc.integer({ min: 0, max: 999 }),
        })),
        (items: CartItem[]) => calculateTotal(items, null) >= 0
      )
    );
  });

  it('total with no discount equals sum of price × qty', () => {
    fc.assert(
      fc.property(
        fc.array(fc.record<CartItem>({
          sku: fc.string(),
          price: fc.float({ min: 0, max: 100, noNaN: true }),
          qty: fc.integer({ min: 0, max: 100 }),
        })),
        (items: CartItem[]) => {
          const expected = items.reduce((s, i) => s + i.price * i.qty, 0);
          return Math.abs(calculateTotal(items, null) - expected) < 0.001;
        }
      )
    );
  });
});
```

13. **[community] TCR (Test-and-Commit-or-Revert) is the fastest way to internalise baby-steps discipline.** Teams that run TCR for even one week report permanently smaller commit sizes and faster TDD cycles afterward. In TypeScript projects, TCR scripts should run `npx vitest run` (which uses esbuild, not tsc) to keep the revert loop fast.

14. **[community] Snapshot tests treated as TDD test cases erode test suite trust.** Teams that use `toMatchSnapshot()` as a primary assertion strategy run `--update-snapshots` automatically whenever tests fail, creating a false-green suite. Snapshots should document complex serialisable structures (API response shapes, AST nodes), not replace explicit behavioural assertions.

15. **[community] Mutation testing reveals that high coverage ≠ good TDD.** TypeScript teams running Stryker against a TDD codebase with 90%+ line coverage routinely find mutation scores of 60–70% on first run. The gap represents test cases written to achieve coverage rather than to catch defects.

16. **[community] TypeScript `strict` mode mismatches between test and source `tsconfig` cause silent false greens.** In monorepos, it is common for `tsconfig.json` (production) to use `strict: true` while `tsconfig.test.json` inherits from a more permissive base. Tests then compile and pass on code that would fail type-checking in production. The fix: ensure test `tsconfig` extends the same strictness settings as production, or use a single shared `tsconfig.base.json` with `strict: true`.

17. **[community] Overloaded function signatures require multiple test cases per overload.** TypeScript function overloads are a common source of under-tested code. If a function has three overload signatures, each overload is a separate test condition requiring its own test case. Teams that write one test case per function often miss the boundary between overload resolution paths. In TDD, each overload should be a separate Red test case — the overload definition emerges from the test cases, not the other way around.

18. **[community] "Test Cancer" — the test suite grows unmaintainable and resists change.** Martin Fowler identifies "Test Cancer" as a production failure mode where a test suite becomes so rigid and tightly coupled to implementation details that it prevents refactoring instead of enabling it. The symptoms: every rename requires dozens of test updates; test code is longer and more complex than production code; developers fear changing tests more than they fear changing implementation. The root cause is writing test cases that assert _how_ rather than _what_ — checking method call counts on mocks instead of observable domain outcomes. Prevention: use typed in-memory fakes instead of mocks, assert on state not interactions, and treat the refactor phase as mandatory (not optional) at each TDD cycle. When Test Cancer is diagnosed, the most effective treatment is deleting mock-heavy unit test suites and re-growing them via TDD with fakes, using only acceptance tests as the safety net during the transition.

19. **[community] `--noCheck` in TDD CI pipelines decouples type safety from test speed.** TypeScript 5.7's `--noCheck` flag enables separating the CI "type-check" job from the "build + test" job. TDD teams benefit by running the fast Vitest unit test suite (via esbuild, no full tsc compile) in parallel with `tsc --noEmit` for type checking. Neither job blocks the other, and the TDD feedback loop stays sub-60s even in large monorepos. Warning: using `--noCheck` in local development defeats TypeScript's purpose — restrict it to CI parallelisation only.

20. **[community] DHH's "design damage" critique applies to TypeScript TDD too.** David Heinemeier Hansson's objection — that heavy isolation testing requires excessive interface indirection — is relevant in TypeScript projects where every collaborator gets an `interface`, an in-memory fake, and constructor injection. For simple CRUD services, this is genuine overhead. The practical resolution: apply full DI + typed fakes at the domain layer (business rules, pricing, state machines) where behaviour complexity justifies it, and use integration test cases with real infrastructure for thin persistence adapters where the "seam" adds more complexity than it removes.

21. **[community] The "Is TDD Dead?" debate produced a durable framework for evaluating any testing approach.** Kent Beck's four dimensions — Frequency (how often tests run), Fidelity (how accurately they represent production), Overhead (time/complexity cost), and Lifespan (cost over the software's life) — apply to every testing decision, not just TDD. In TypeScript projects: unit test cases with fakes score high on Frequency and Lifespan but lower on Fidelity (the fake diverges from the real DB); integration test cases score high on Fidelity but lower on Frequency (slow). The framework prevents religious debates ("unit tests are always better") by making the tradeoff explicit. Apply it when choosing between TDD'd unit test cases and Testcontainers-based integration tests for a given TypeScript module.

22. **[community] "Construct with Collaborators, Call with Work" — a precise design rule for TDD-driven injection.** The Google Testing Blog (May 2026) articulates a principle that resolves the most common TDD design question: what goes in a constructor vs. what goes in a method parameter? The answer: **collaborators** (services, repositories, mailers — objects the class works _with_) belong in constructors; **work** (data, request inputs, commands — what the method acts _on_) belongs in method parameters. This is not merely style — it has a direct TDD implication: test cases that construct objects with all collaborators injected, then call methods with the work, produce the clearest, most reusable typed fakes. Violations of this rule (passing work through constructors, or injecting all inputs as services) make test cases harder to write — which is the TDD signal that the design is wrong.

```typescript
// ❌ WRONG: passing work (request data) in the constructor
class OrderService {
  constructor(
    private readonly orderId: string,    // ← work, not a collaborator
    private readonly userId: string,     // ← work, not a collaborator
    private readonly repo: OrderRepository  // ← collaborator (correct)
  ) {}
  async process(): Promise<void> { /* ... */ }
}
// Problem: every test case must create a new OrderService per request — no reuse.
// The repo (collaborator) should outlive the request; orderId/userId (work) should not.

// ✅ CORRECT: collaborators in constructor, work in method parameters
class OrderService {
  constructor(
    private readonly repo: OrderRepository,  // ← collaborator
    private readonly mailer: Mailer,          // ← collaborator
  ) {}

  async processOrder(orderId: string, userId: string): Promise<void> {
    // orderId and userId are work — they change per call
    const order = await this.repo.findById(orderId);
    await this.mailer.send({ to: userId, subject: `Order ${orderId} confirmed` });
  }
}

// TDD test case — one OrderService instance, multiple test cases with different work:
describe('OrderService', () => {
  const repo = new InMemoryOrderRepository();
  const mailer = new SpyMailer();
  const service = new OrderService(repo, mailer); // ← constructed once, used across test cases

  it('sends confirmation for a valid order', async () => {
    await repo.save({ id: 'ORD-1', status: 'pending', userId: 'user@example.com' });
    await service.processOrder('ORD-1', 'user@example.com');  // ← work passed per call
    expect(mailer.sent[0].subject).toContain('ORD-1');
  });
});
```

23. **[community] TypeScript 6.0 upgrade will silently break TDD test suites that rely on auto-discovered `@types`.** TypeScript 6.0 (May 2026) changed the `types` default from auto-discovering all installed `@types/*` packages to an empty array `[]`. Teams upgrading from TypeScript 5.x will find their TDD test files immediately failing to compile with "Cannot find name 'describe'" and "Cannot find name 'expect'" errors — even though nothing in the test code changed. The fix is one line (`"types": ["vitest/globals"]` or `"jest"`), but without foreknowledge this error is confusing because it looks like the test runner is broken, not the TypeScript config. Add the `types` field to `tsconfig.json` explicitly **before** upgrading to TypeScript 6.0.

24. **[community] Feature flags without TDD test cases for the disabled state are a hidden regression time-bomb.** When a feature flag is introduced, teams typically write test cases only for the flag-enabled path — because that is what is being built. The disabled state (which is the production default and the rollback path) goes untested. When the flag is rolled back under load, the untested code path executes in production for the first time. The TDD discipline: write the disabled-state test case first (it IS the safe default), then write the enabled-state test case. Use a `FakeFlagReader` that defaults all flags to disabled — this mirrors the production safe default and makes the disabled-state test case the baseline.

25. **[community] The double-lookup anti-pattern in in-memory fakes introduces subtle consistency bugs.** TypeScript test doubles written with `Map.has(key)` + `Map.get(key)!` perform two separate lookups. Between these two calls, another operation on the fake could mutate the map. The `!` non-null assertion is itself a signal: TypeScript knows `Map.get` returns `T | undefined`, and the `!` is suppressing that information. The fix: one lookup, store the result, check for `undefined` explicitly. With `noUncheckedIndexedAccess: true` in `tsconfig.json`, TypeScript makes the double-lookup smell visible — `Map.get` returns `T | undefined` and the `!` operator required to dismiss that signal is the code review red flag. Eliminate `!` from fakes by adopting the one-lookup pattern.

26. **[community] TCR (test && commit || revert) without a TypeScript compile-error gate lets broken types persist.** Kent Beck's TCR workflow (gotcha #13) is most commonly implemented as `npx vitest run && git commit || git checkout -- .`. In TypeScript projects, this only reverts when tests fail — not when TypeScript compilation fails. A compile error does not run any tests and therefore does not trigger the revert. TypeScript errors accumulate silently across TCR cycles. The fix: add `npx tsc --noEmit` as the first step in the TCR script. If `tsc` fails, revert immediately — TypeScript compile errors are treated as test failures in the TDD discipline.

27. **[community] Zod v4 `z.input<T>` vs `z.output<T>` reveals TDD test data typed against the wrong shape.** A common pattern in test suites: arrange steps build fixtures using the `z.infer<typeof Schema>` type (the output type), even when the handler under test accepts raw input strings. The test case passes because the output type is a valid superset of what `.parse()` accepts — but the coercion path (string → Date, string → number) is never exercised. With Zod v4's explicit `z.input<T>` type, annotating test fixtures as `OrderInput` rather than `OrderOutput` forces the test case to use the types that real API consumers send, surfacing coercion defects before production.

28. **[community] `using` and `await using` in test cases eliminate the "spy survived the test" class of flakiness.** The most subtle TDD isolation defect in TypeScript/Vitest projects is a spy registered in one test case and accidentally active in the next, because `afterEach(() => spy.mockRestore())` was not called (test threw before registration, or the scope was wrong). `using spy = useSpy(...)` disposes the spy when the test function's scope exits — regardless of exceptions, early returns, or generator yields. Teams migrating from `afterEach` to `using` report near-elimination of "spy leaked into next test" incidents, which previously manifested as order-dependent test failures.

29. **[community] `Promise.try` exposes a hidden async/sync inconsistency class in TypeScript domain functions.** Functions that throw synchronously for validation errors but return promises for I/O errors create two assertion patterns in test suites (`toThrow` vs `rejects.toThrow`). When the code under test is refactored from sync to async (or vice versa), test cases break in non-obvious ways — not because the behaviour changed, but because the error delivery mechanism changed. `Promise.try` in the test suite normalises both paths: whether the function throws or rejects, the assertion is `expect(Promise.try(() => fn(...))).rejects.toThrow(...)`. Teams that standardise on this pattern report more stable test cases during async refactors.

---

## Tradeoffs & Alternatives

### When TDD Works Well
- Greenfield domain logic with clear inputs/outputs and well-defined TypeScript types
- Business rule engines, calculators, state machines, parsers
- Public API design on new libraries — the test IS the first consumer and the first type-check
- Highly collaborative teams where specs-as-tests reduce ambiguity
- Long-lived codebases where the team changes frequently (tests serve as living documentation)
- Safety-critical systems where regression risk is existential

### When TDD is a Poor Fit
- Exploratory/research code — you cannot write a failing test for a technique you have not discovered yet (spike first, extract, then TDD the extracted typed function)
- UI-heavy features with no extractable logic layer — prefer BDD acceptance tests at the user story level
- Data migration scripts — one-run code; characterisation tests before, smoke test after
- Time-critical hotfixes where confirming the failure mode matters more than building correctly
- Hardware interaction, driver code, or OS-level work where the test environment cannot simulate the target
- Designing complex type-level generics — TypeScript's type system errors are themselves "tests"; adding runtime test cases for type inference edge cases rarely adds value

### Known Adoption Costs
- **Learning curve:** Teams new to TDD typically see a 20–40% slowdown in the first 4–8 weeks. The slowdown reflects learning to write testable code, not fundamental TDD overhead.
- **TypeScript setup cost:** Fast unit tests require a `tsconfig.json` configured with path aliases, proper module resolution, and a Vitest config that handles TypeScript without full `tsc` compilation during the watch loop. This is typically a 1–2 day investment.
- **Test infrastructure investment:** Dependency injection, seam-based design, typed interfaces for all collaborators. In TypeScript, interfaces are zero-cost abstractions — but writing them requires discipline.
- **Cultural resistance:** TDD requires discipline at the PR review level — reviewers must check that tests were written first and that coverage is meaningful, not just present.
- **Diminishing returns on very simple code:** TDD is most valuable on complex behaviour. Enforcing it on simple typed DTOs or configuration loaders adds ceremony without proportional value.

### Lighter Alternatives
| Practice | When to prefer it |
|---|---|
| **Test-First (no refactor step)** | When you need specification benefits without full TDD discipline |
| **BDD / Spec by Example** | When the primary audience for tests is non-technical stakeholders |
| **Property-Based Testing** | When you want to generalise beyond hand-picked examples (complements TDD) |
| **Characterisation Tests** | When working in legacy code before a large refactor — capture current behaviour |
| **Contract Testing** | When integrating third-party services or microservice boundaries |
| **Mutation Testing** | As a TDD audit: checks that tests actually fail when production code is broken |

### TDD Adoption Strategies That Work
- **Kata practice first:** Have the team practice TDD on coding katas (FizzBuzz, Roman Numerals, Bowling) in TypeScript before applying it to production code.
- **Greenfield-first adoption:** Start TDD on new TypeScript services/modules, not on existing legacy code.
- **Test-after as a bridge:** For teams struggling with strict TDD, test-after with mandatory refactoring is a useful intermediate step.
- **Enable `strict: true` from day one:** TypeScript's strict mode makes TDD test cases more precise by eliminating implicit `null`/`undefined` in type contracts.

---

## ISTQB CTFL 4.0 Terminology Alignment

The ISTQB Certified Tester Foundation Level 4.0 syllabus defines standardised terms used throughout this guide.

| ISTQB term | Common informal term | Notes in TDD context |
|-----------|---------------------|---------------------|
| **Test case** | "test", "spec", "it block" | An `it(...)` block in Vitest is a test case. Avoid calling it just "a test." |
| **Test suite** | "test file", "test set" | A `describe(...)` block or a whole `.test.ts` file constitutes a test suite. |
| **Test object** | "thing under test", "SUT" | The class/function/module being exercised by the test case. |
| **Test level** | "test layer" | TDD primarily operates at unit test level; double-loop TDD adds the acceptance test level. |
| **Test basis** | "requirements", "specs" | In TDD, the failing test case IS the test basis before implementation exists. |
| **Defect** | "bug", "error" | TDD produces defects in the Red phase deliberately — this is intentional defect-first development. |
| **Test condition** | "test scenario", "test idea" | The specific state + input combination a test case exercises (e.g., "empty cart"). |
| **Test harness** | "test runner setup", "test infrastructure" | Vitest + typed in-memory fakes + TypeScript config = the test harness for a TDD project. |

---

## Advanced Patterns (Iteration 5–10 Extensions)

### TDD for Error Handling with Exhaustive Discriminated Unions [community]

TypeScript's exhaustive switch with `never` is a powerful TDD target: the test cases define every valid error variant before the implementation, and the compiler enforces that all branches are covered.

```typescript
// error-types.ts — TDD drives the discriminated union design
// RED: Write tests for each error variant first — this forces the union definition

import { describe, it, expect } from 'vitest';
import { parseUserId, UserIdError } from './parseUserId.js';

// Test case 1: RED — define what a valid ID looks like
describe('parseUserId', () => {
  it('returns ok for a UUID-format string', () => {
    const result = parseUserId('550e8400-e29b-41d4-a716-446655440000');
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.value).toBe('550e8400-e29b-41d4-a716-446655440000');
    }
  });

  // Test case 2: RED — empty string is a distinct error type
  it('returns empty-string error for ""', () => {
    const result = parseUserId('');
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.kind).toBe('empty');
    }
  });

  // Test case 3: RED — wrong format is a distinct error type
  it('returns invalid-format error for non-UUID strings', () => {
    const result = parseUserId('not-a-uuid');
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.kind).toBe('invalid-format');
    }
  });

  // Test case 4: RED — too long is a distinct error type
  it('returns too-long error for strings exceeding 36 chars', () => {
    const result = parseUserId('a'.repeat(37));
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.kind).toBe('too-long');
    }
  });
});

// GREEN: discriminated union forced into existence by test cases
// parseUserId.ts
type UserIdErrorKind = 'empty' | 'invalid-format' | 'too-long';

export interface UserIdError {
  kind: UserIdErrorKind;
  message: string;
}

type ParseResult =
  | { success: true;  value: string }
  | { success: false; error: UserIdError };

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function parseUserId(raw: string): ParseResult {
  if (raw.length === 0) {
    return { success: false, error: { kind: 'empty', message: 'User ID must not be empty' } };
  }
  if (raw.length > 36) {
    return { success: false, error: { kind: 'too-long', message: `User ID must be ≤ 36 chars, got ${raw.length}` } };
  }
  if (!UUID_RE.test(raw)) {
    return { success: false, error: { kind: 'invalid-format', message: 'User ID must be a valid UUID' } };
  }
  return { success: true, value: raw };
}

// REFACTOR: add exhaustive type guard — compiler enforces all error kinds are handled
function assertNever(x: never): never {
  throw new Error(`Unhandled error kind: ${JSON.stringify(x)}`);
}

export function formatUserIdError(error: UserIdError): string {
  switch (error.kind) {
    case 'empty':          return 'Please provide a user ID.';
    case 'invalid-format': return 'User ID must be a valid UUID (e.g. 550e8400-...).';
    case 'too-long':       return `User ID is too long (${error.message}).`;
    default:               return assertNever(error.kind);
    // If a new kind is added to UserIdErrorKind, TypeScript errors here immediately.
  }
}
```

**Why TDD drives better error type design:** Without TDD, error types are often defined as `Error | string | null` — the laziest union. Writing test cases first forces you to enumerate every error variant your callers need to handle, producing tight discriminated unions that TypeScript can exhaustively check.

---

### TDD for Event-Driven Systems (Pub/Sub, EventEmitter) [community]

Event-driven TypeScript code is notoriously hard to test after the fact. TDD forces the event contract — event names, payload types — into existence before the emit code is written.

```typescript
// domain-events.ts — TDD drives the typed event bus design
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { TypedEventBus } from './TypedEventBus.js';

// Define event payload map — test cases force this interface into existence
interface AppEvents {
  'user:registered':  { userId: string; email: string; };
  'order:placed':     { orderId: string; total: number; };
  'order:cancelled':  { orderId: string; reason: string; };
}

let bus: TypedEventBus<AppEvents>;

beforeEach(() => { bus = new TypedEventBus<AppEvents>(); });

// Test case 1: RED — subscriber receives event payload
it('delivers user:registered payload to subscribers', () => {
  const handler = vi.fn<[AppEvents['user:registered']], void>();
  bus.on('user:registered', handler);
  bus.emit('user:registered', { userId: 'u1', email: 'alice@example.com' });
  expect(handler).toHaveBeenCalledOnce();
  expect(handler).toHaveBeenCalledWith<[AppEvents['user:registered']]>({
    userId: 'u1',
    email: 'alice@example.com',
  });
});

// Test case 2: RED — multiple subscribers all receive the event
it('notifies all subscribers for the same event', () => {
  const h1 = vi.fn<[AppEvents['order:placed']], void>();
  const h2 = vi.fn<[AppEvents['order:placed']], void>();
  bus.on('order:placed', h1);
  bus.on('order:placed', h2);
  bus.emit('order:placed', { orderId: 'ORD-1', total: 99.99 });
  expect(h1).toHaveBeenCalledOnce();
  expect(h2).toHaveBeenCalledOnce();
});

// Test case 3: RED — off() removes subscriber
it('stops delivering events after off()', () => {
  const handler = vi.fn<[AppEvents['order:cancelled']], void>();
  bus.on('order:cancelled', handler);
  bus.off('order:cancelled', handler);
  bus.emit('order:cancelled', { orderId: 'ORD-2', reason: 'customer request' });
  expect(handler).not.toHaveBeenCalled();
});

// GREEN: typed event bus implementation
// TypedEventBus.ts
type Handler<T> = (payload: T) => void;

export class TypedEventBus<Events extends Record<string, unknown>> {
  readonly #handlers = new Map<keyof Events, Set<Handler<unknown>>>();

  on<K extends keyof Events>(event: K, handler: Handler<Events[K]>): void {
    if (!this.#handlers.has(event)) this.#handlers.set(event, new Set());
    this.#handlers.get(event)!.add(handler as Handler<unknown>);
  }

  off<K extends keyof Events>(event: K, handler: Handler<Events[K]>): void {
    this.#handlers.get(event)?.delete(handler as Handler<unknown>);
  }

  emit<K extends keyof Events>(event: K, payload: Events[K]): void {
    this.#handlers.get(event)?.forEach(h => h(payload));
  }
}
```

**Community signal:** Teams using untyped `EventEmitter` in Node.js often discover type mismatches between emitter and listener only at runtime. TDD-driven typed event buses surface payload mismatches at compile time — the test case `vi.fn<[AppEvents['order:placed']], void>()` will fail TypeScript if the payload shape changes.

---

### TDD for CLI Tools (Node.js / TypeScript) [community]

CLI tools are often untested because developers treat them as "glue code." TDD applied to CLI logic extracts argument parsing and command execution into testable units.

```typescript
// cli-parser.test.ts — TDD for a typed CLI argument parser
import { describe, it, expect } from 'vitest';
import { parseCLIArgs, CLIArgs, CLIParseError } from './cli-parser.js';

// Test case 1: RED — happy path: required args present
describe('parseCLIArgs', () => {
  it('parses --output and --format flags', () => {
    const result = parseCLIArgs(['--output', 'dist/', '--format', 'json']);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.value).toMatchObject<Partial<CLIArgs>>({
        output: 'dist/',
        format: 'json',
      });
    }
  });

  // Test case 2: RED — missing required arg produces typed error
  it('returns error when --output is missing', () => {
    const result = parseCLIArgs(['--format', 'json']);
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.kind).toBe('missing-required');
      expect(result.error.flag).toBe('output');
    }
  });

  // Test case 3: RED — invalid format value produces typed error
  it('returns error for unknown --format value', () => {
    const result = parseCLIArgs(['--output', 'dist/', '--format', 'xml']);
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.kind).toBe('invalid-value');
      expect(result.error.flag).toBe('format');
    }
  });

  // Test case 4: RED — default value applied when optional flag absent
  it('defaults --verbose to false when not provided', () => {
    const result = parseCLIArgs(['--output', 'out/', '--format', 'json']);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.value.verbose).toBe(false);
    }
  });
});

// GREEN: typed CLI parser — shape driven entirely by the test cases above
// cli-parser.ts
const VALID_FORMATS = ['json', 'csv', 'text'] as const;
type OutputFormat = typeof VALID_FORMATS[number];

export interface CLIArgs {
  output: string;
  format: OutputFormat;
  verbose: boolean;
}

export type CLIParseError =
  | { kind: 'missing-required'; flag: string }
  | { kind: 'invalid-value';    flag: string; received: string; expected: readonly string[] };

type CLIParseResult =
  | { success: true;  value: CLIArgs }
  | { success: false; error: CLIParseError };

export function parseCLIArgs(argv: string[]): CLIParseResult {
  const flags = new Map<string, string>();
  for (let i = 0; i < argv.length - 1; i += 2) {
    if (argv[i].startsWith('--')) flags.set(argv[i].slice(2), argv[i + 1]);
  }

  const output = flags.get('output');
  if (!output) return { success: false, error: { kind: 'missing-required', flag: 'output' } };

  const rawFormat = flags.get('format');
  if (!rawFormat) return { success: false, error: { kind: 'missing-required', flag: 'format' } };
  if (!(VALID_FORMATS as readonly string[]).includes(rawFormat)) {
    return { success: false, error: { kind: 'invalid-value', flag: 'format', received: rawFormat, expected: VALID_FORMATS } };
  }

  return {
    success: true,
    value: { output, format: rawFormat as OutputFormat, verbose: flags.has('verbose') },
  };
}
```

---

### TDD for Concurrency: Race Conditions and Idempotency [community]

Race conditions are discovered in production, not in test suites, because most TDD test cases assume sequential execution. TypeScript async test cases with `Promise.allSettled` and `Promise.race` can TDD concurrent invariants.

```typescript
// idempotent-service.test.ts
import { describe, it, expect } from 'vitest';
import { IdempotentJobRunner } from './IdempotentJobRunner.js';

describe('IdempotentJobRunner', () => {
  // Test case 1: RED — sequential execution produces one result
  it('executes a job exactly once for a given idempotency key', async () => {
    const runner = new IdempotentJobRunner();
    const results: string[] = [];

    await runner.run('job-key-1', async () => { results.push('executed'); return 'done'; });
    expect(results).toHaveLength(1);
  });

  // Test case 2: RED — concurrent calls with same key execute exactly once
  it('deduplicates concurrent runs with the same idempotency key', async () => {
    const runner = new IdempotentJobRunner();
    let executionCount = 0;

    const job = async (): Promise<string> => {
      executionCount++;
      await new Promise(r => setTimeout(r, 10)); // simulate async work
      return 'result';
    };

    const [r1, r2, r3] = await Promise.all([
      runner.run('concurrent-key', job),
      runner.run('concurrent-key', job),
      runner.run('concurrent-key', job),
    ]);

    // All three callers get the same result
    expect(r1).toBe('result');
    expect(r2).toBe('result');
    expect(r3).toBe('result');
    // But the job body executed exactly once
    expect(executionCount).toBe(1);
  });

  // Test case 3: RED — different keys execute independently
  it('runs jobs independently for different idempotency keys', async () => {
    const runner = new IdempotentJobRunner();
    let count = 0;
    const job = async () => { count++; return count; };

    const [r1, r2] = await Promise.all([
      runner.run('key-A', job),
      runner.run('key-B', job),
    ]);

    expect(count).toBe(2);
    expect(r1).not.toBe(r2);
  });
});

// GREEN: idempotent runner — driven entirely by the concurrent test cases
// IdempotentJobRunner.ts
export class IdempotentJobRunner {
  readonly #inFlight = new Map<string, Promise<unknown>>();

  run<T>(key: string, job: () => Promise<T>): Promise<T> {
    const existing = this.#inFlight.get(key);
    if (existing) return existing as Promise<T>;

    const promise = job().finally(() => this.#inFlight.delete(key));
    this.#inFlight.set(key, promise);
    return promise;
  }
}
```

**Why this matters for TDD:** Most developers do not write test cases for concurrent invariants until production incidents occur. Writing the concurrent test case first (as above) reveals whether the implementation needs a deduplication layer — before any production load.

---

### TDD Maturity Model — Team Adoption Roadmap [community]

Teams adopting TDD rarely succeed by trying to apply all principles simultaneously. A staged maturity model helps teams advance sustainably.

| Level | Characteristic | TypeScript Indicators |
|-------|---------------|----------------------|
| **0 — No TDD** | Tests written never or after features ship | No test files; or only smoke tests |
| **1 — Test-After** | Tests written after implementation; low coverage | `*.test.ts` present but imports match implementation exactly |
| **2 — Test-First** | Tests written before implementation; no refactor step | Red→Green only; test files created before `.ts` files |
| **3 — TDD (basic)** | Red→Green→Refactor cycle; some fakes; some baby steps | Typed fakes present; `vi.fn()` calls have type params |
| **4 — TDD (consistent)** | Cycle practiced consistently; typed interfaces everywhere; mutation tested | No `as any` in tests; Stryker configured; TPP applied |
| **5 — TDD (team standard)** | TDD required in PR review; outside-in on features; property tests on core logic | PR template checks for test-first; mutation score in CI; fast-check in use |

**Progression guidance:**
- Moving from Level 0→1: Instrument coverage gates at 40%; mandate test files in PRs.
- Moving from Level 1→2: Practice 3 katas as a team; require test file committed before implementation.
- Moving from Level 2→3: Add a refactor phase to the PR checklist; introduce typed in-memory fakes.
- Moving from Level 3→4: Run Stryker monthly on critical modules; eliminate `as any` in test doubles.
- Moving from Level 4→5: Configure double-loop TDD for new features; add `fast-check` to payment/pricing logic.

**[community] The single most impactful level transition is 1→2 (test-after to test-first).** Teams that commit to writing the test file before the implementation file — even without strict TDD discipline — report significantly better API design and 40% fewer "this is untestable" incidents during code review.

---

### TDD for Database Access Layers — Repository Pattern [community]

The Repository pattern is the canonical seam for database TDD. Writing the repository interface first (as a test case target) produces a clean domain/persistence boundary.

```typescript
// user-repository-tdd.test.ts
// Step 1: TDD drives the interface design before any DB code is written
import { describe, it, expect, beforeEach } from 'vitest';
import { InMemoryUserRepository } from './test-doubles/InMemoryUserRepository.js';
import { UserRepository, CreateUserInput, User } from './UserRepository.js';

// The test cases define the UserRepository contract — not the Postgres implementation.
// Any concrete repository (Postgres, SQLite, in-memory) must satisfy this suite.

let repo: UserRepository;

beforeEach(() => {
  repo = new InMemoryUserRepository(); // swap for PostgresUserRepository in integration tests
});

describe('UserRepository contract', () => {
  // Test case 1: create and retrieve
  it('saves a user and retrieves by id', async () => {
    const input: CreateUserInput = { email: 'alice@example.com', name: 'Alice', role: 'member' };
    const saved = await repo.create(input);

    expect(saved.id).toMatch(/^[0-9a-f-]{36}$/); // UUID format
    const found = await repo.findById(saved.id);
    expect(found).toMatchObject<Partial<User>>({ email: 'alice@example.com', name: 'Alice' });
  });

  // Test case 2: email uniqueness constraint
  it('throws DuplicateEmailError when email already exists', async () => {
    await repo.create({ email: 'dup@example.com', name: 'First', role: 'member' });
    await expect(
      repo.create({ email: 'dup@example.com', name: 'Second', role: 'member' })
    ).rejects.toMatchObject({ code: 'DUPLICATE_EMAIL' });
  });

  // Test case 3: findByEmail returns null for unknown email
  it('returns null for an unknown email', async () => {
    const result = await repo.findByEmail('unknown@example.com');
    expect(result).toBeNull();
  });

  // Test case 4: update modifies only specified fields
  it('updates a user without clobbering unrelated fields', async () => {
    const user = await repo.create({ email: 'bob@example.com', name: 'Bob', role: 'member' });
    await repo.update(user.id, { name: 'Robert' });
    const updated = await repo.findById(user.id);
    expect(updated?.name).toBe('Robert');
    expect(updated?.email).toBe('bob@example.com'); // unchanged
  });
});

// This test suite acts as a contract test — run it with both InMemoryUserRepository
// (unit tests, fast) and PostgresUserRepository (integration tests, slower) to
// verify that both implementations satisfy the same behavioural contract.
```

**[community] Repository contract tests are the single most effective technique for preventing ORM-specific logic from leaking into domain code.** When a PostgreSQL-specific quirk (case-sensitive collation, JSONB indexing) causes tests to pass against the in-memory fake but fail in production, the contract test immediately identifies the implementation divergence.

---

### TDD with AI-Assisted Code Generation [community]

AI code assistants (GitHub Copilot, Cursor, Claude) change TDD workflows in 2025–2026. Several production patterns have emerged:

**[community] Test-first remains the correct discipline even with AI-generated implementations.** The failure mode of "paste AI code then write tests" is the same as test-after: tests conform to implementation. The correct pattern is: write the test case, let AI generate the Green implementation, then review it critically before committing.

**[community] AI-generated implementations frequently skip the Refactor phase.** AI tools optimise for making tests pass, not for clean design. Teams using AI assistants for TDD must explicitly request the refactor pass: "the tests now pass — refactor this without changing observable behaviour."

**[community] AI tools generate over-mocked tests.** When asked to "write tests for this class," AI assistants tend to generate `vi.fn()` mocks for every dependency, producing brittle test suites. The correct TDD prompt is: "write a failing test case that specifies this one behaviour — use a typed in-memory fake, not a mock." The test output is significantly better.

```typescript
// Pattern: AI-assisted TDD cycle with explicit prompting strategy
// Step 1: Write the test case yourself (do not delegate this to AI)
// reason: the test case IS the design decision — AI cannot know your domain requirements

// Step 2: Request AI to generate only the Green implementation
// Prompt: "Make this test case pass with minimal TypeScript code.
//          Use typed interfaces. Do not add untested behaviour."

// Step 3: Review AI output against the TPP (Transformation Priority Premise)
// Check: did AI jump to a complex implementation when a simpler one would pass?
// If yes: revert and ask AI to use the simplest passing transformation.

// Step 4: Request the refactor explicitly
// Prompt: "All tests pass. Now refactor for readability — tighten types,
//          extract helper functions, add inline documentation. Do not change behaviour."

// Step 5: Re-run tests — all must still pass
// Commit only when Red→Green→Refactor cycle is complete.
```

**[community] One team's production finding (2025):** After adopting AI-assisted TDD on a TypeScript monorepo, they measured that AI-generated implementations had a 23% higher mutation-survival rate than human-written implementations on the first Green pass. The root cause: AI implementations often return early with hardcoded paths when the test cases do not triangulate all branches. The fix: add triangulating test cases before asking AI for the implementation.

---

### TDD for Parsing and Validation Pipelines [community]

Input validation pipelines are ideal TDD targets: the test cases enumerate the acceptance criteria directly, and the pipeline shape (chain of validators) emerges naturally from the failing test cases.

```typescript
// validation-pipeline.test.ts — TDD drives a composable validation pipeline
import { describe, it, expect } from 'vitest';
import { validate, required, minLength, matches, maxLength } from './validators.js';

interface RegistrationForm {
  username: string;
  password: string;
  email:    string;
}

// Test case 1: RED — valid input passes all validators
describe('registration form validation', () => {
  it('accepts a valid registration', () => {
    const result = validate<RegistrationForm>({
      username: 'alice_99',
      password: 'Secure!Pass1',
      email:    'alice@example.com',
    }, {
      username: [required(), minLength(3), maxLength(20), matches(/^[a-z0-9_]+$/)],
      password: [required(), minLength(8)],
      email:    [required(), matches(/^[^@]+@[^@]+\.[^@]+$/)],
    });
    expect(result.valid).toBe(true);
  });

  // Test case 2: RED — missing required field
  it('reports error for empty username', () => {
    const result = validate<RegistrationForm>(
      { username: '', password: 'pass', email: 'e@e.com' },
      { username: [required()], password: [], email: [] }
    );
    expect(result.valid).toBe(false);
    expect(result.errors.username).toContain('required');
  });

  // Test case 3: RED — multiple errors on same field
  it('collects all errors on a field, not just the first', () => {
    const result = validate<RegistrationForm>(
      { username: 'a!', password: 'x', email: 'e@e.com' },
      { username: [minLength(3), matches(/^[a-z0-9_]+$/)], password: [], email: [] }
    );
    expect(result.errors.username).toHaveLength(2);
  });
});

// GREEN: composable validator pipeline
// validators.ts
type ValidatorFn<T> = (value: T) => string | null; // null = valid, string = error message

export interface ValidationRule<T> { validate: ValidatorFn<T>; }

export const required   = (): ValidationRule<string> => ({ validate: v => v.trim() ? null : 'required' });
export const minLength  = (n: number): ValidationRule<string> => ({ validate: v => v.length >= n ? null : `min length ${n}` });
export const maxLength  = (n: number): ValidationRule<string> => ({ validate: v => v.length <= n ? null : `max length ${n}` });
export const matches    = (re: RegExp): ValidationRule<string> => ({ validate: v => re.test(v) ? null : `must match ${re}` });

type FieldRules<T> = { [K in keyof T]?: ValidationRule<T[K]>[] };
type FieldErrors<T> = { [K in keyof T]?: string[] };

interface ValidationResult<T> {
  valid: boolean;
  errors: FieldErrors<T>;
}

export function validate<T extends Record<string, unknown>>(
  data: T,
  rules: FieldRules<T>
): ValidationResult<T> {
  const errors: FieldErrors<T> = {};
  let valid = true;

  for (const key of Object.keys(rules) as (keyof T)[]) {
    const fieldRules = rules[key] ?? [];
    const fieldErrors = fieldRules
      .map(r => r.validate(data[key] as never))
      .filter((e): e is string => e !== null);
    if (fieldErrors.length > 0) {
      errors[key] = fieldErrors;
      valid = false;
    }
  }

  return { valid, errors };
}
```

---

### TDD with Inferred Type Predicates (TypeScript 5.5+) [community]

TypeScript 5.5 automatically infers type predicates for simple filtering functions, removing the need for manual `value is T` annotations on filter callbacks and single-return boolean helpers. TDD can drive the design of these predicates: write the test case first to define the expected narrowing behavior, then let TypeScript 5.5 infer the predicate.

```typescript
// TDD-driven design of a domain filter — TypeScript 5.5+ infers the predicate
// domain-filters.test.ts
import { describe, it, expect } from 'vitest';
import { isPaidOrder, isActiveUser } from './domain-filters.js';

interface Order { id: string; status: 'pending' | 'paid' | 'cancelled'; total: number; }
interface User  { id: string; active: boolean; role: 'admin' | 'member'; }

// Test case 1: RED — isPaidOrder narrows Order[] to paid orders only
describe('isPaidOrder', () => {
  it('includes only paid orders', () => {
    const orders: Order[] = [
      { id: 'o1', status: 'paid',      total: 100 },
      { id: 'o2', status: 'pending',   total:  50 },
      { id: 'o3', status: 'cancelled', total:   0 },
    ];
    const paid = orders.filter(isPaidOrder);
    expect(paid).toHaveLength(1);
    expect(paid[0].id).toBe('o1');
    // TypeScript 5.5 infers: paid is Order[] (narrowed to status === 'paid')
  });
});

// Test case 2: RED — isActiveUser narrows User[] to active users
describe('isActiveUser', () => {
  it('excludes inactive users', () => {
    const users: User[] = [
      { id: 'u1', active: true,  role: 'admin' },
      { id: 'u2', active: false, role: 'member' },
    ];
    const active = users.filter(isActiveUser);
    expect(active).toHaveLength(1);
    expect(active[0].id).toBe('u1');
  });
});

// GREEN: functions typed against domain interfaces — TS 5.5 infers predicates automatically
// domain-filters.ts
export const isPaidOrder   = (o: Order) => o.status === 'paid';
export const isActiveUser  = (u: User)  => u.active === true;
// TypeScript 5.5 infers:
//   isPaidOrder:  (o: Order) => o is Order & { status: 'paid' }
//   isActiveUser: (u: User)  => u is User  & { active: true }
// No manual `: o is X` annotation needed — test case forces the correct predicate shape.

// REFACTOR: document the inference explicitly for IDEs and code reviewers
// who may not be on TypeScript 5.5+:
export type PaidOrder   = Order & { status: 'paid' };
export type ActiveUser  = User  & { active: true };

// Usage in domain logic — narrowed type flows through:
function processPayments(orders: Order[]): PaidOrder[] {
  return orders.filter(isPaidOrder);
  // Without TS 5.5, this would return Order[] — losing the status narrowing.
}
```

**Why this matters for TDD:** Before TypeScript 5.5, writing a test case that asserted `paid[0].status === 'paid'` required either a manual type predicate annotation or an `as` cast. TypeScript 5.5's inferred predicates mean that TDD-driven filter functions automatically produce narrowed types at the call site — the test case defines the filter behaviour, and TypeScript generates the type-level guarantee for free.

**[community] Projects still on TypeScript 4.x lose inferred predicates — the test case `expect(paid[0].status).toBe('paid')` still passes, but `paid` remains typed as `Order[]`, not `PaidOrder[]`. The TDD test case should include an explicit TypeScript typecheck to catch this: `const _typed: PaidOrder[] = orders.filter(isPaidOrder);` — this line fails to compile on TypeScript 4.x without a manual predicate annotation, making the TypeScript version requirement explicit.

### TDD with the `satisfies` Operator — Shape Validation in Test Assertions [community]

TypeScript 4.9's `satisfies` operator validates an expression against a type without widening it. In TDD test cases, `satisfies` provides a sharper assertion pattern than `as` casts or explicit type annotations: it proves the test object matches the interface while preserving literal types for further assertions.

```typescript
// TDD test case using satisfies for typed fixture construction
// order-service.test.ts
import { describe, it, expect } from 'vitest';
import { OrderService } from './OrderService.js';
import { InMemoryOrderRepository } from './test-doubles/InMemoryOrderRepository.js';

// satisfies validates the fixture satisfies the interface — no widening, no cast needed
const testOrder = {
  id: 'ORD-001',
  status: 'pending',
  items: [{ sku: 'WIDGET-A', price: 49.99, qty: 2 }],
  customerId: 'CUST-123',
} satisfies Parameters<typeof InMemoryOrderRepository.prototype.save>[0];
// TypeScript: testOrder.status is 'pending' (literal), not string (widened)
// If the Order interface changes (e.g., adds required `currency` field),
// TypeScript errors here at the fixture definition — not at a test assertion buried deep.

describe('OrderService.calculateTotal', () => {
  // Test case 1: RED — total is sum of price × qty
  it('returns sum of all item totals', async () => {
    const repo = new InMemoryOrderRepository([testOrder]);
    const service = new OrderService(repo);

    const total = await service.calculateTotal('ORD-001');

    expect(total).toBe(99.98); // 49.99 × 2
  });

  // Test case 2: RED — satisfies preserves literal status for domain assertions
  it('throws when order is not pending', async () => {
    const cancelledOrder = { ...testOrder, id: 'ORD-002', status: 'cancelled' as const }
      satisfies typeof testOrder;
    const repo = new InMemoryOrderRepository([cancelledOrder]);
    const service = new OrderService(repo);

    await expect(service.calculateTotal('ORD-002')).rejects.toThrow('Order is not pending');
  });
});
```

**Why `satisfies` improves TDD fixtures:** When fixtures are created with `const fixture: SomeType = {...}`, TypeScript widens literal values to their base types (`status: 'pending'` becomes `string`). This means assertions like `expect(result.status).toBe('pending')` lose type precision — TypeScript treats `result.status` as `string`, not `'pending'`. With `satisfies`, the literal types are preserved, making conditional assertions after narrowing (e.g., `if (result.status === 'pending')`) type-safe without casts.

**[community] Test fixture drift is a silent TDD maintenance cost.** When a domain interface gains a required field, fixtures declared as `const f: Interface = {...}` immediately error — which is the correct behavior. However, teams that use `as Interface` casts for fixtures silently accept incomplete objects, and the test cases pass while the production type contract is violated. Using `satisfies` instead of `as` on fixtures provides the same shape validation as an explicit type annotation, without allowing `as`-style escape hatching.

### TDD with Iterator Helpers (TypeScript 5.6+) — Lazy Pipelines in Domain Logic [community]

TypeScript 5.6 added built-in types for ECMAScript iterator helpers (`map`, `filter`, `take`, `flatMap`, `reduce` on `Iterator<T>`). TDD drives the design of lazy pipelines by specifying the expected output of each pipeline step before the implementation exists.

```typescript
// TDD for a lazy report pipeline using iterator helpers
// report-pipeline.test.ts
import { describe, it, expect } from 'vitest';
import { buildRevenueReport } from './report-pipeline.js';

interface Transaction { id: string; amount: number; status: 'settled' | 'pending' | 'failed'; }

// Test data — inline, no fixture file needed (small, self-documenting)
const transactions: Transaction[] = [
  { id: 't1', amount: 100, status: 'settled' },
  { id: 't2', amount:  50, status: 'pending' },
  { id: 't3', amount: 200, status: 'settled' },
  { id: 't4', amount:  75, status: 'failed'  },
  { id: 't5', amount: 150, status: 'settled' },
];

// Test case 1: RED — settled transactions are included, others excluded
describe('buildRevenueReport', () => {
  it('sums settled transactions only', () => {
    const report = buildRevenueReport(transactions);
    expect(report.total).toBe(450); // 100 + 200 + 150
    expect(report.count).toBe(3);
  });

  // Test case 2: RED — pipeline is lazy (does not materialise all items)
  it('handles a very large iterable without allocating an intermediate array', () => {
    function* largeSource(): Generator<Transaction> {
      for (let i = 0; i < 1_000_000; i++) {
        yield { id: `t${i}`, amount: i % 100, status: i % 3 === 0 ? 'settled' : 'pending' };
      }
    }
    // If this crashes with OOM, the implementation materialises eagerly — TDD catches it
    const report = buildRevenueReport(largeSource());
    expect(report.total).toBeGreaterThan(0);
    expect(report.count).toBeGreaterThan(0);
  });
});

// GREEN: iterator helpers produce a lazy pipeline — no intermediate array
// report-pipeline.ts (requires Node 22+ or modern browser runtime)
interface RevenueReport { total: number; count: number; }

export function buildRevenueReport(source: Iterable<Transaction>): RevenueReport {
  return Iterator.from(source)
    .filter((t: Transaction) => t.status === 'settled')
    .reduce<RevenueReport>(
      (acc, t) => ({ total: acc.total + t.amount, count: acc.count + 1 }),
      { total: 0, count: 0 }
    );
}
// Requires lib: ["ES2025"] or "esnext" in tsconfig.json
// The test case for the large source proves laziness — no intermediate array allocated.
```

**[community] Iterator helpers require Node 22+ or a polyfill.** Teams adopting TypeScript 5.6 iterator helper types should verify their Node.js version in CI (`engines` field in `package.json`). A TDD test case that exercises a large lazy source (`1_000_000` items) will crash with `Iterator.from is not a function` on Node < 22 — this is a useful runtime compatibility signal to catch early in the TDD cycle.

### TDD Pacing Metrics and CI Integration [community]

Tracking TDD health over time requires instrumenting the test suite with pacing metrics. Without measurement, TDD discipline erodes silently.

```typescript
// vitest.config.ts — production-grade TDD CI configuration
import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    reporter: process.env.CI
      ? ['verbose', 'junit']  // JUnit for CI test result upload
      : ['verbose'],
    outputFile: process.env.CI ? './test-results/junit.xml' : undefined,

    // TDD pacing: bail on first failure in watch mode for clean Red signal
    bail: process.env.CI ? 0 : 1,

    // Fast TypeScript via esbuild — keeps TDD watch loop under 500ms
    // Full type-checking runs separately as `tsc --noEmit` in CI
    typecheck: {
      enabled: process.env.CI === 'true',
      tsconfig: './tsconfig.json',
    },

    coverage: {
      enabled: process.env.CI === 'true',
      provider: 'v8',
      reporter: ['lcov', 'text-summary', 'json-summary'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/test-doubles/**'],
      thresholds: {
        // These are TDD health gates — if TDD is practiced consistently,
        // they should be exceeded naturally, not chased as targets.
        branches:   80,
        functions:  85,
        lines:      85,
        statements: 85,
        // Optionally add per-file thresholds for critical modules:
        // 'src/domain/pricing/**': { branches: 95, functions: 95 }
      },
    },
  },
});
```

```yaml
# .github/workflows/tdd-ci.yml — CI pipeline designed for TDD cadence feedback
name: TDD CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci

      # 1. Fast type-check (separate from test execution — faster feedback)
      - name: TypeScript type check
        run: npx tsc --noEmit

      # 2. Unit tests with coverage (esbuild-fast)
      - name: Unit tests + coverage
        run: npx vitest run --coverage
        env: { CI: 'true' }

      # 3. Upload coverage to PR (optional — surfaces TDD regression)
      - uses: codecov/codecov-action@v4
        with: { files: ./coverage/lcov.info }

      # 4. Monthly mutation testing (scheduled separately — expensive)
      # Triggered by: workflow_dispatch or schedule: cron '0 2 1 * *'
```

**[community] CI pipeline design signals TDD culture.** Teams that run type-check separately from tests (step 1 above) get 30–60 second faster feedback during TDD watch loops. Teams that upload coverage to every PR create social accountability — coverage drops become visible in code review, not just in dashboards.

**[community] Per-file coverage thresholds prevent coverage debt accumulation in critical modules.** Setting global 80% thresholds allows new files with 0% coverage to silently dilute the aggregate. Per-file thresholds on `src/domain/pricing/**` and `src/domain/auth/**` enforce TDD discipline precisely where it matters most.

### TDD Test Investment Framework — Frequency, Fidelity, Overhead, Lifespan [community]

The "Is TDD Dead?" video series (Kent Beck, Martin Fowler, DHH — 2014, still the most cited TDD debate) produced a practical four-dimension framework for evaluating whether to TDD a given module. The framework prevents ideological arguments and grounds decisions in measurable costs.

| Dimension | Question | TypeScript TDD lever |
|-----------|----------|---------------------|
| **Frequency** | How often will this test case run and give feedback? | Unit test cases via Vitest (< 1s) vs integration with Testcontainers (30–60s) |
| **Fidelity** | How accurately does the test case represent the production failure? | Typed in-memory fakes: high for domain logic, lower for DB-specific behaviour |
| **Overhead** | What is the time and complexity cost to write and maintain? | DI + interfaces + fakes: justified for complex domain, excessive for thin adapters |
| **Lifespan** | Over the software's life, does this test case pay back its cost? | Domain rule tests: long lifespan. Integration scaffolding: shorter, higher churn |

**Applying the framework in TypeScript:**

```typescript
// Decision example: Should I TDD this with unit test cases or integration test cases?

// MODULE A: PricingEngine — complex domain logic
// Frequency: HIGH (run on every file save, < 100ms)
// Fidelity: HIGH (pure function, no infrastructure dependency)
// Overhead: LOW (no DI needed — pure function takes typed input)
// Lifespan: HIGH (pricing rules change slowly; test cases remain valid for years)
// → DECISION: TDD with unit test cases — all four dimensions strongly favour it.

// pricing-engine.test.ts
import { describe, it, expect } from 'vitest';
import { applyTieredDiscount, PricingInput, PricingResult } from './pricing-engine.js';

describe('applyTieredDiscount', () => {
  it('applies 5% for subtotal 50–99', () => {
    const input: PricingInput = { subtotal: 75, customerTier: 'standard' };
    const result: PricingResult = applyTieredDiscount(input);
    expect(result.discount).toBeCloseTo(3.75); // 5% of 75
    expect(result.total).toBeCloseTo(71.25);
  });

  it('applies 10% for subtotal ≥ 100 on standard tier', () => {
    const input: PricingInput = { subtotal: 150, customerTier: 'standard' };
    const result = applyTieredDiscount(input);
    expect(result.discount).toBeCloseTo(15);
    expect(result.total).toBeCloseTo(135);
  });

  it('applies 15% for premium tier regardless of subtotal', () => {
    const input: PricingInput = { subtotal: 40, customerTier: 'premium' };
    const result = applyTieredDiscount(input);
    expect(result.discount).toBeCloseTo(6);
  });
});

// MODULE B: UserRepository (Postgres implementation)
// Frequency: LOW (requires DB container — minutes to spin up in CI)
// Fidelity: HIGH (tests real SQL, real indexes, real constraint behaviour)
// Overhead: MEDIUM (Testcontainers setup, but shared across the test suite)
// Lifespan: MEDIUM (SQL changes when schema evolves, but not on every refactor)
// → DECISION: TDD the UserRepository *interface* with a typed fake (unit level),
//   then write integration test cases against the PostgresUserRepository
//   (contract tests). Do NOT try to TDD the SQL implementation line by line.
```

**Community signal:** The Beck/DHH/Fowler debate concluded that the methodology (TDD vs test-after) matters less than the outcome (self-testing code). Teams obsessing over TDD purity while neglecting integration fidelity — running only in-memory fakes, never testing against a real database — discover defects in production that a single Testcontainers-based integration test case would have caught in CI. Balance the four dimensions, not the ideological purity of the approach.

---

### Self-Testing Code — The Goal Behind TDD [community]

Martin Fowler's "Self-Testing Code" principle is the reason TDD exists: if you can run a comprehensive automated test suite after any change and be confident the software works, you can refactor, upgrade dependencies, and ship with low risk. TDD is one technique for achieving this goal — but it is not the only one.

**Why this matters:** Teams that abandon TDD often abandon self-testing code entirely, which is the real regression. The goal is a suite of test cases that gives fast, high-fidelity confidence after every change — whether those test cases were written test-first or test-after is secondary.

```typescript
// The self-testing code checklist — applicable to any TypeScript project
// Each item can be achieved via TDD or other means; TDD makes most of them easier.

// 1. Every business rule has at least one test case that fails when the rule is violated:
it('rejects orders with negative quantities', () => {
  const result = createOrder({ items: [{ sku: 'A', qty: -1, price: 10 }] });
  expect(result.success).toBe(false);
  expect(result.error).toMatch(/quantity/i);
});

// 2. Refactoring does not require test suite changes (tests on behaviour, not implementation):
// BEFORE refactor: Cart.total() computed inline
// AFTER refactor: Cart.total() delegates to CartCalculator
// → No test cases need to change if they test cart.total() output, not internals.

// 3. CI gate: suite must pass before merge — non-negotiable:
// .github/workflows/ci.yml extract:
// jobs:
//   test:
//     steps:
//       - run: npx vitest run --coverage
//       - run: npx tsc --noEmit
// No merge without green.

// 4. Test cases run in < 60 seconds for the unit suite:
// If suite exceeds 60s, TDD's feedback loop breaks down.
// Remedies: Vitest parallelisation, esbuild (not tsc), exclude slow integration tests from watch mode.
```

**[community] The most durable finding from the "Is TDD Dead?" debate:** All three participants agreed that self-testing code — whatever technique produces it — is the most impactful software quality practice available to a development team. DHH's objection was never to automated testing; it was to the specific ceremony of red-green-refactor being applied rigidly where it didn't fit. Teams that internalise the goal (self-testing code) over the method (strict TDD) build more pragmatic, sustainable test cultures.

---

### TypeScript 5.8 + 5.9 — TDD-Relevant Compiler Improvements [community]

TypeScript 5.8 and 5.9 (released 2025–2026) each include changes that affect TDD workflows directly.

#### TypeScript 5.8: Granular Return Branch Checks and `--erasableSyntaxOnly`

**Granular return expression branch checks (TS 5.8):** TypeScript now checks each branch of a conditional `return` expression independently against the declared return type, instead of widening the union first. This catches bugs that previously hid behind `any`.

```typescript
// BEFORE TypeScript 5.8: silent bug — union of `any | string` widened to `any`
declare const cache: Map<any, any>;

function resolveUser(id: string): User {
  return cache.has(id)
    ? cache.get(id)  // any — escapes the return type check
    : id;            // string — type error silently hidden by any branch
}

// AFTER TypeScript 5.8: each branch checked against User
function resolveUser(id: string): User {
  return cache.has(id)
    ? cache.get(id)  // still any — but the string branch now errors:
    : id;
  //  ~~
  // error! Type 'string' is not assignable to type 'User'.
}
```

**Why this matters for TDD:** The Red phase now catches more type-level defects during test authoring. In TDD, writing the test case first forces you to annotate return types precisely; TypeScript 5.8's stricter branch checking makes those annotations trustworthy — conditional return paths that would have silently returned `any` now produce a Red (compile-time) signal immediately.

**`--erasableSyntaxOnly` and Node.js native type-stripping (TS 5.8):** Node.js 23.6+ supports running `.ts` files directly via `--experimental-strip-types`. This requires all TypeScript syntax to be _erasable_ — removable without runtime consequence. TypeScript 5.8's `--erasableSyntaxOnly` flag enforces this at compile time.

```typescript
// tsconfig.json additions for Node.js-native type-stripping workflows
{
  "compilerOptions": {
    "erasableSyntaxOnly": true,   // Block non-erasable TypeScript syntax
    "verbatimModuleSyntax": true  // Required alongside --erasableSyntaxOnly

    // ❌ Non-erasable constructs now rejected at compile time:
    // - enum declarations (emit runtime JS)
    // - namespace with runtime code
    // - parameter properties: constructor(public x: number)
    // - import = and export = syntax
  }
}

// ❌ Blocked by erasableSyntaxOnly
enum Direction { Up, Down, Left, Right }

class Point {
  constructor(public x: number, public y: number) {}
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // error! Parameter properties are not allowed with erasableSyntaxOnly
}

// ✅ TDD-friendly alternative — explicit class fields (erasable)
class Point {
  x: number;
  y: number;
  constructor(x: number, y: number) { this.x = x; this.y = y; }
}
```

**TDD impact of type-stripping:** TDD watch loops that run test files directly via `node --experimental-strip-types` bypass the TypeScript compilation step entirely, delivering sub-100ms Red→Green feedback on file save — faster than even esbuild-based Vitest runs. The tradeoff: no full type-checking during the watch loop; run `tsc --noEmit` separately in CI.

```bash
# TDD watch loop via Node.js native type stripping (Node 23.6+, TS 5.8+)
# Fastest possible feedback — no compilation, no esbuild, raw JS execution
node --experimental-strip-types --watch src/domain/cart/Cart.test.ts

# Separate type-check job in CI (does not block test execution)
npx tsc --noEmit --erasableSyntaxOnly
```

**[community] Teams adopting `--erasableSyntaxOnly` report that refactoring away from `enum` and parameter properties, while initially painful, produces cleaner TypeScript: plain const objects replace enums (preserving tree-shakability), and explicit constructor body assignment replaces parameter properties (making the assignment visible and debuggable). The TDD test suite catches any regressions during the migration.**

#### TypeScript 5.9: TDD-Friendly `tsc --init` Defaults

TypeScript 5.9 updated `tsc --init` to generate a prescriptive minimal `tsconfig.json` that matches modern TDD best practices out of the box:

```jsonc
// tsconfig.json generated by `tsc --init` in TypeScript 5.9+
// (Accurate as of TypeScript 5.9 release — subsequently superseded by TypeScript 6.0 defaults)
{
  "compilerOptions": {
    "strict": true,                         // ← previously off by default; now on
    "noUncheckedIndexedAccess": true,       // ← new in 5.9 baseline
    "exactOptionalPropertyTypes": true,     // ← new in 5.9 baseline
    "noUncheckedSideEffectImports": true,   // ← available since 5.6, now part of 5.9 default scaffold
    "isolatedModules": true,                // ← new in 5.9 baseline; required for esbuild/SWC
    "moduleDetection": "force",             // ← prevents accidental global scripts
    "module": "nodenext",                   // ← ESM-first
    "target": "esnext"
  }
}
```

**Why TDD benefits from the 5.9 baseline:** New projects initialized with `tsc --init` now start with the same strict settings that this guide has recommended since the first iteration. Teams no longer need to manually add `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` — the default scaffold enforces TDD-quality type precision from the first test case.

**`noUncheckedSideEffectImports` (TypeScript 5.6, opt-in; TypeScript 6.0, on by default):** This compiler option (introduced in TypeScript 5.6, previously off by default) flags imports that are only used for their side effects (e.g., `import './polyfill.js'`) when the module does not exist. **As of TypeScript 6.0, this option defaults to `true` and no longer needs to be set explicitly.** Without it, TypeScript silently ignores missing side-effect-only imports. In TDD, this catches test setup files that accidentally import a path that was renamed or deleted — a category of defect that previously produced silent test isolation failures. If you are still on TypeScript 5.x, enable it explicitly: `"noUncheckedSideEffectImports": true`.

```typescript
// Before TypeScript 5.9 noUncheckedSideEffectImports:
// This compiles with no error even if './matchers.js' does not exist:
import './test-doubles/matchers.js'; // side-effect import — registers custom matchers

// With noUncheckedSideEffectImports: true in tsconfig.json,
// TypeScript errors if './test-doubles/matchers.js' cannot be resolved.
// TDD benefit: a deleted or renamed matcher file now produces a Red
// compile-time signal immediately, rather than a silent false-green test run
// where custom matchers were never registered.
```

**`isolatedModules: true`:** Required when using esbuild (Vitest's default transpiler) or SWC — both transpile files in isolation without full type context. Enabling it in `tsconfig.json` catches TypeScript patterns that esbuild cannot handle (e.g., `const enum`, ambient `declare const`, re-exports of types without the `type` keyword). In TDD, `isolatedModules: true` prevents a class of "works locally but fails in CI" defects that arise when `tsc --noEmit` and esbuild disagree on valid syntax.

**`import defer` (TypeScript 5.9):** Lazy module evaluation defers a module's side effects until first use. In TDD, this reduces test isolation failures caused by module-level side effects (e.g., database connections opened on import):

```typescript
// import defer: module is evaluated lazily — no side effects at import time
import defer * as db from './db.js';

// Only when db.query() is first called does db.ts execute its module-level code.
// TDD benefit: test files that import this module do NOT open a DB connection
// unless the specific test case that calls db.query() runs.
// Compare with the eager-import problem documented in gotcha #11 above.
```

**[community] `import defer` is not yet widely supported at runtime (requires Node.js with `--experimental-vm-modules` or a compatible bundler). Treat it as a future-proof design signal rather than an immediate production tool in 2026. The TDD test suite remains the safety net when adopting it.**

---

### Vitest 4.0 — New Matchers and TDD-Relevant Changes [community]

Vitest 4.0 (released 2025–2026) brings several new features that improve TDD workflows in TypeScript projects.

**Requirements:** Vitest 4.0 requires Vite ≥ 6.0 and Node.js ≥ 20.

#### `expect.schemaMatching` — Schema-Validated TDD Test Cases

Vitest 4.0 adds `expect.schemaMatching`, an asymmetric matcher that validates a value against a Standard Schema v1-compatible schema (Zod, Valibot, ArkType). This enables TDD test cases that specify both the _shape_ and the _validation rules_ of a response in a single assertion.

```typescript
// vitest 4.0 — schema-validated TDD test case
import { describe, it, expect } from 'vitest';
import { z } from 'zod';
import { createUserHandler } from './createUserHandler.js';

// Step 1: RED — define the schema first (this IS the test basis / specification)
const UserResponseSchema = z.object({
  id:        z.string().uuid(),
  email:     z.string().email(),
  createdAt: z.string().datetime(),
  role:      z.enum(['admin', 'member', 'viewer']),
});

type UserResponse = z.infer<typeof UserResponseSchema>;

describe('createUserHandler', () => {
  it('returns a valid user response shape', async () => {
    const res = await createUserHandler({
      email: 'alice@example.com',
      role:  'member',
    });

    // expect.schemaMatching validates against the Zod schema — no manual field assertions
    expect(res).toMatchObject(expect.schemaMatching(UserResponseSchema));
  });

  it('generates a UUID id', async () => {
    const res = await createUserHandler({ email: 'bob@example.com', role: 'admin' });
    // Combine schemaMatching with explicit field checks for precision
    expect(res).toEqual(expect.schemaMatching(UserResponseSchema));
    expect(res.id).toMatch(/^[0-9a-f-]{36}$/);
  });
});
```

**Why `expect.schemaMatching` improves TDD:** In traditional TDD, specifying a complex response shape requires many individual `expect(res.field).toBe(...)` assertions. With schema-first TDD, the Zod schema IS the failing test specification — you write the schema, run the test (Red), implement the handler (Green), and the schema serves as both a runtime validator and a Vitest assertion. The test case is shorter and the specification is machine-verifiable.

#### `expect.assert` — Type-Narrowing in TDD Test Cases

`expect.assert` provides direct access to Chai's assertion interface when Vitest's `expect.to*` matchers do not produce the right TypeScript narrowing:

```typescript
import { describe, it, expect } from 'vitest';
import { parseOrderId } from './parseOrderId.js';

describe('parseOrderId', () => {
  it('narrows the result type with expect.assert', () => {
    const result = parseOrderId('ORD-001');

    // Traditional approach — no TypeScript narrowing after expect()
    expect(result.success).toBe(true);
    // result.value is still Result<string, Error> — TypeScript doesn't narrow here

    // Vitest 4.0 — expect.assert provides Chai assertion that narrows in TypeScript
    expect.assert(result.success === true);
    // TypeScript now knows result is { success: true; value: string }
    expect(result.value).toBe('ORD-001'); // ← TypeScript-safe after narrowing
  });
});
```

#### `spyOn` Constructor Support

Vitest 4.0 allows `vi.spyOn` to intercept class constructor calls. In TDD, this enables test cases that verify a collaborator is instantiated with the correct arguments — useful when refactoring legacy code that uses `new` internally before dependency injection is in place:

```typescript
import { vi, describe, it, expect } from 'vitest';
import { ReportService } from './ReportService.js';
import { PdfRenderer } from './PdfRenderer.js';

describe('ReportService', () => {
  it('constructs a PdfRenderer with the correct paper size', () => {
    // Vitest 4.0: spy on the PdfRenderer constructor
    const constructorSpy = vi.spyOn(PdfRenderer, 'constructor' as 'prototype');

    const service = new ReportService({ format: 'A4' });
    service.generate();

    // Verify the constructor was called with the correct config
    expect(constructorSpy).toHaveBeenCalledWith(
      expect.objectContaining({ paperSize: 'A4' })
    );

    constructorSpy.mockRestore();
  });
});

// Note: constructor spying is a stepping stone — the end goal is still
// to refactor toward dependency injection and replace the spy with a typed fake.
// Use constructor spying when working with legacy code, not new TDD'd code.
```

**[community] Vitest 4.0's `spyOn` constructor support bridges the gap between legacy TypeScript code that uses `new` internally and the TDD ideal of dependency injection. Teams using constructor spies should treat each spy as a TODO: "refactor to inject this dependency." Track these as technical debt items.**

#### Visual Regression TDD with `toMatchScreenshot`

Vitest 4.0 Browser Mode (now stable, no longer experimental) adds `toMatchScreenshot` for visual regression test cases. In TDD, this supports a visual-first Red step for UI components:

```typescript
// vitest.config.ts — Browser Mode with visual regression
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: { name: 'playwright' }, // Now an object, not a string (Vitest 4.0)
      name: 'chromium',
    },
  },
});

// button.browser.test.ts — visual TDD test case
import { page } from '@vitest/browser/context';
import { describe, it, expect } from 'vitest';

describe('Button component (visual TDD)', () => {
  it('matches the approved visual design for primary variant', async () => {
    await page.goto('/components/button?variant=primary');
    const button = page.locator('[data-testid="primary-button"]');

    // RED: first run creates the baseline screenshot
    // GREEN: implementation matches the screenshot
    // REFACTOR: update screenshot when design intentionally changes
    await expect(button).toMatchScreenshot('button-primary.png');
  });

  it('button is visible in viewport on initial render', async () => {
    await page.goto('/components/button');
    const button = page.locator('[data-testid="primary-button"]');

    // Vitest 4.0 new matcher: toBeInViewport
    await expect(button).toBeInViewport();
  });
});
```

**[community] Visual TDD with `toMatchScreenshot` works best when combined with component-level acceptance criteria: write the screenshot test case before implementing the component (Red = no screenshot exists yet), implement the component (Green = screenshot generated and matches), then lock in the baseline. Teams using Storybook can point Vitest Browser Mode at Storybook story URLs for consistent isolation.**

#### `verbose` Reporter — Sequential Output Change [community]

In Vitest 4.0, the `verbose` reporter was changed to **always** print test cases sequentially, even in non-CI (local watch) mode. Previous versions printed output in completion order, which mixed test case results from parallel files and made local TDD debugging harder.

**TDD impact:** The sequential output aligns with the TDD inner loop: when a test case goes Red, the failure message appears immediately in context with the surrounding test suite output, rather than being interspersed with results from other files. If your `vitest.config.ts` conditionally enabled `verbose` only in CI, review this setting — sequential output is now beneficial during local TDD sessions too.

```typescript
// vitest.config.ts — updated for Vitest 4.0 verbose reporter behaviour
export default defineConfig({
  test: {
    // Vitest 4.0: verbose is now sequential everywhere — no need to conditionalize
    reporter: ['verbose'],
    // If you preferred parallel output locally (higher throughput, less readable):
    // reporter: process.env.CI ? ['verbose'] : ['default'],
  },
});
```

#### `test.extend()` — Type-Safe Fixture Context in Lifecycle Hooks [community]

Vitest 4.0 extends `test.extend()` so that fixture data is type-safe inside `beforeEach`/`afterEach` hooks defined within the extended test context. Previously, accessing fixture values in lifecycle hooks required unsafe casts because the type information was not propagated.

```typescript
// vitest 4.0 — typed fixture context in lifecycle hooks
import { test, expect } from 'vitest';
import { InMemoryUserRepository } from './test-doubles/InMemoryUserRepository.js';
import { UserRepository } from './UserRepository.js';

// Define a typed fixture providing a fresh repository per test case
const userTest = test.extend<{ repo: UserRepository }>({
  repo: async ({}, use) => {
    const repo = new InMemoryUserRepository();
    await use(repo);
    // teardown: repo is reset automatically — no shared state between test cases
  },
});

// In Vitest 4.0: lifecycle hooks receive the same typed context as the test body
userTest.beforeEach(async ({ repo }) => {
  // `repo` is typed as UserRepository — no cast needed
  // This is the change: previously this context was `unknown` in beforeEach
  await repo.create({ email: 'seed@example.com', name: 'Seed User', role: 'member' });
});

userTest('finds the seeded user by email', async ({ repo }) => {
  const found = await repo.findByEmail('seed@example.com');
  expect(found?.name).toBe('Seed User');
});

userTest('returns null for unknown email', async ({ repo }) => {
  const result = await repo.findByEmail('nobody@example.com');
  expect(result).toBeNull();
});
```

**Why this matters for TDD:** Typed fixture contexts eliminate `as UserRepository` casts in `beforeEach` setup — a common source of silent interface drift in TDD test suites. When the `UserRepository` interface changes, TypeScript now errors in `beforeEach` hook bodies, not just in the test body itself.

---

### TypeScript 6.0 — Breaking Changes Affecting TDD Workflows [community]

TypeScript 6.0 was released May 2026. It is a **transition release** with significant default changes. TDD test suites on TypeScript 5.x will need targeted updates before upgrading.

#### The Most Impactful Change: `types` Defaults to `[]`

In TypeScript 6.0, `"types"` in `compilerOptions` now defaults to an empty array instead of auto-discovering all installed `@types/*` packages. This means Vitest/Jest/Mocha global functions (`describe`, `it`, `expect`, `test`) are no longer automatically recognised without an explicit `types` declaration.

```typescript
// ❌ After TypeScript 6.0 upgrade without config update — TDD test files immediately error:
// Cannot find name 'describe'. Do you need to install type definitions?
// Cannot find name 'it'.
// Cannot find name 'expect'.
describe('ShoppingCart', () => {   // ← TypeScript error in TS 6.0 without types config
  it('starts empty', () => { ... });
});

// ✅ Fix: add explicit types to tsconfig.json or tsconfig.test.json
```

```jsonc
// tsconfig.json — TypeScript 6.0 compatible TDD configuration
{
  "compilerOptions": {
    "target": "es2025",           // ← TS 6.0 new default; check Node.js version compatibility
    "module": "esnext",           // ← TS 6.0 new default
    "strict": true,               // ← TS 6.0 new default (previously false)
    "rootDir": "./src",           // ← Must be explicit now; TS 6.0 defaults to tsconfig dir
    "types": ["node", "vitest/globals"],  // ← REQUIRED in TS 6.0 — no more auto-discovery

    // Options REMOVED in TypeScript 6.0 — delete from existing configs:
    // ❌ "moduleResolution": "node"   → use "bundler" or "nodenext"
    // ❌ "module": "commonjs"         → use "esnext" or "nodenext"
    // ❌ "esModuleInterop": false      → removed (true is now always assumed)
    // ❌ "target": "es5"              → removed

    // TDD-relevant options — remain valid and recommended:
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noUncheckedSideEffectImports": true,  // opt-in since TS 5.6
    "isolatedModules": true
  }
}
```

**New features in TypeScript 6.0 useful for TDD:**

- **ES2025 `RegExp.escape()` and `Temporal` API types:** Test cases for date/time logic can now use the `Temporal` API without a polyfill type definition.
- **`Map.prototype.getOrInsert()` / `getOrInsertComputed()`:** Useful in typed in-memory fakes (reduces boilerplate for test double stores).
- **`--stableTypeOrdering` flag:** Produces deterministic type union ordering — important for TDD test cases that `toMatchObject` complex unions, which previously could have non-deterministic TypeScript error messages in CI.
- **DOM library consolidation:** `dom.iterable` and `dom.asynciterable` are now included by default in the `dom` lib — test cases using async iterators no longer need `"lib": ["es2023", "dom", "dom.iterable"]` boilerplate.

```typescript
// TypeScript 6.0 TDD: Map.getOrInsert in typed in-memory fakes
// InMemoryOrderRepository.ts — cleaner factory logic with getOrInsert
class InMemoryOrderRepository implements OrderRepository {
  readonly #store = new Map<string, Order>();
  readonly #byCustomer = new Map<string, Set<string>>();  // customerId → orderIds

  async save(order: Order): Promise<Order> {
    this.#store.set(order.id, order);
    // TypeScript 6.0: getOrInsert removes the boilerplate Map.has + Map.set pattern
    this.#byCustomer
      .getOrInsert(order.customerId, new Set<string>())
      .add(order.id);
    return order;
  }

  async findByCustomer(customerId: string): Promise<Order[]> {
    return [...(this.#byCustomer.get(customerId) ?? [])]
      .map(id => this.#store.get(id))
      .filter((o): o is Order => o !== undefined);
  }
}

// TDD test case — unchanged by TS 6.0; the fake's internals changed but the interface did not
it('retrieves orders by customer id', async () => {
  const repo = new InMemoryOrderRepository();
  const order = await repo.save({ id: 'ORD-1', customerId: 'CUST-1', total: 50 });
  const found = await repo.findByCustomer('CUST-1');
  expect(found).toHaveLength(1);
  expect(found[0].id).toBe('ORD-1');
});
```

**[community] TypeScript 6.0 migration checklist for TDD projects:**

1. Add `"types": ["node", "vitest/globals"]` (or `"jest"` / `"mocha"`) to `tsconfig.json` **before** upgrading.
2. Remove deprecated options: `moduleResolution: "node"`, `module: "commonjs"`, `esModuleInterop: false`, `target: "es5"`.
3. Set `"rootDir"` explicitly — the inference changed.
4. Run `tsc --noEmit` after upgrading — expect 20–100 new errors on a 50k-line codebase; most are `types` configuration errors and removed-option errors.
5. Use `"ignoreDeprecations": "6.0"` as a temporary escape hatch during migration — it will not work in TypeScript 7.0.
6. Use the **`ts5to6` automated codemod** ([github.com/andrewbranch/ts5to6](https://github.com/andrewbranch/ts5to6)) to mechanically migrate `baseUrl`-relative `paths`, remove deprecated `module`/`target` options, and update `rootDir` inferences. Run it before upgrading the `typescript` package version to get a clean diff of the configuration changes needed.

**[community] The `types: []` default change is the highest-impact TDD gotcha in TypeScript 6.0.** Teams that rely on globally available `describe`/`it`/`expect` from Vitest globals will see immediate compile errors after upgrading without adding `"types": ["vitest/globals"]`. The fix is one line, but it will block CI if the upgrade happens without reading the migration guide first.

---

### TDD for Feature Flags — Safe Defaults Pattern [community]

Feature flags (also called feature toggles) are a common cause of invisible TDD gaps. When a flag is introduced without corresponding test cases for both the enabled and disabled states, the disabled state becomes untested code that lives in production. The "Set Safe Defaults for Flags" principle (Google Testing Blog TotT, March 2026) articulates a direct TDD corollary: **write the test case for the default (disabled) state first**, because the default is the state that ships until the flag is deliberately turned on.

The TDD implication: treat each feature flag as a test condition with at least two test cases — one for the flag enabled, one for the flag disabled. The disabled state is the safe default and must not break existing behaviour.

```typescript
// feature-flags.ts — typed feature flag registry
export type FeatureFlag =
  | 'new-checkout-flow'
  | 'enhanced-search'
  | 'experimental-pricing';

export interface FlagReader {
  isEnabled(flag: FeatureFlag): boolean;
}

// test-doubles/FakeFlagReader.ts — controllable flag state in test cases
export class FakeFlagReader implements FlagReader {
  readonly #flags = new Map<FeatureFlag, boolean>();

  enable(flag: FeatureFlag): void  { this.#flags.set(flag, true); }
  disable(flag: FeatureFlag): void { this.#flags.set(flag, false); }
  isEnabled(flag: FeatureFlag): boolean { return this.#flags.get(flag) ?? false; }
  // Default: all flags disabled — "safe default" mirrors production default
}

// checkout-service.test.ts — TDD test cases for both flag states
import { describe, it, expect, beforeEach } from 'vitest';
import { CheckoutService } from './CheckoutService.js';
import { FakeFlagReader } from './test-doubles/FakeFlagReader.js';
import { InMemoryOrderRepository } from './test-doubles/InMemoryOrderRepository.js';

describe('CheckoutService with new-checkout-flow flag', () => {
  let flags: FakeFlagReader;
  let service: CheckoutService;

  beforeEach(() => {
    flags = new FakeFlagReader(); // all flags disabled by default
    service = new CheckoutService(new InMemoryOrderRepository(), flags);
  });

  // Test case 1: RED — safe default (flag OFF) uses legacy checkout path
  it('uses legacy checkout flow when flag is disabled (safe default)', async () => {
    // flags.isEnabled('new-checkout-flow') → false (default)
    const result = await service.checkout({ userId: 'u1', cartId: 'c1' });
    expect(result.flowVersion).toBe('legacy');
  });

  // Test case 2: RED — flag ON triggers new checkout path
  it('uses new checkout flow when flag is enabled', async () => {
    flags.enable('new-checkout-flow');
    const result = await service.checkout({ userId: 'u1', cartId: 'c1' });
    expect(result.flowVersion).toBe('v2');
  });

  // Test case 3: RED — flag OFF never calls new-flow-specific logic
  it('does not call v2 order processor when flag is disabled', async () => {
    const v2Calls: string[] = [];
    const serviceWithSpy = new CheckoutService(
      new InMemoryOrderRepository(),
      flags,
      { onV2Flow: (cartId: string) => v2Calls.push(cartId) }
    );
    await serviceWithSpy.checkout({ userId: 'u1', cartId: 'c1' });
    expect(v2Calls).toHaveLength(0); // safe default: v2 never invoked
  });
});
```

**Why the safe-default pattern matters in TDD:** In TypeScript monorepos, feature flags are often added as environment variables or remote config reads — without anyone writing test cases for the disabled state. When the flag is eventually turned off (rollback, dark launch), the disabled code path is exercised in production for the first time. TDD prevents this by forcing the disabled-state test case to be written first. The `FakeFlagReader` starting with all flags disabled enforces the safe default at the test level.

**[community] Feature flag TDD anti-pattern: "I'll add tests when the flag is permanently on."** Teams that defer testing the disabled state until the flag is scheduled for removal consistently discover latent defects when rolling back the flag under production load. The cost of writing one additional test case at flag-introduction time is trivial compared to the cost of an untested rollback path.

---

### One Map Key, One Lookup — Test Double Efficiency [community]

The "One Map Key, One Lookup" principle (Google Testing Blog TotT, April 2026) applies to test doubles: **never perform two separate map lookups where one lookup with a stored result would suffice**. In typed in-memory fakes, the double-lookup anti-pattern produces subtle consistency bugs when state changes between the two reads, and adds unnecessary branching complexity to test infrastructure.

The principle is: retrieve the value once, store it in a typed constant, then use the constant. This applies to both production code and test doubles — but the impact on test doubles is higher because fakes are mutated frequently during test setup.

```typescript
// ❌ ANTI-PATTERN: double lookup — inconsistent if state changes between reads
class InMemoryCartRepository implements CartRepository {
  readonly #carts = new Map<string, Cart>();

  async updateItem(cartId: string, sku: string, qty: number): Promise<Cart> {
    if (!this.#carts.has(cartId)) {           // ← lookup 1
      throw new Error(`Cart ${cartId} not found`);
    }
    const cart = this.#carts.get(cartId)!;    // ← lookup 2 — redundant; ! needed to suppress undefined
    return this.#mutateCart(cart, sku, qty);
  }
}

// ✅ ONE LOOKUP: fetch once, handle undefined explicitly
class InMemoryCartRepository implements CartRepository {
  readonly #carts = new Map<string, Cart>();

  async updateItem(cartId: string, sku: string, qty: number): Promise<Cart> {
    const cart = this.#carts.get(cartId);     // ← single lookup
    if (cart === undefined) {
      throw new CartNotFoundError(cartId);    // typed error — no ! assertion needed
    }
    return this.#mutateCart(cart, sku, qty);  // cart is Cart (narrowed), not Cart | undefined
  }
}

// TypeScript benefit: `noUncheckedIndexedAccess` in tsconfig.json forces the pattern.
// With noUncheckedIndexedAccess: true, Map.get() returns T | undefined — the undefined
// case cannot be silently ignored. One-lookup + explicit undefined check is the idiomatic fix.
```

**Why this matters for TDD:** In-memory fakes that use the double-lookup pattern accumulate `!` non-null assertions throughout their implementation. Each `!` is a place where TypeScript's type safety has been bypassed — meaning TypeScript cannot protect you when the fake's state diverges from expectations. The one-lookup pattern eliminates these assertions, keeping fake implementations fully type-safe and consistent with `strictNullChecks`.

```typescript
// ✅ TypeScript 6.0 version: Map.getOrInsertComputed for computed defaults
// Useful in fakes that accumulate secondary indexes during save operations
class InMemoryOrderRepository implements OrderRepository {
  readonly #store      = new Map<string, Order>();
  readonly #byCustomer = new Map<string, Set<string>>();

  async save(order: Order): Promise<Order> {
    this.#store.set(order.id, order);

    // One lookup + computed insert: no double Map.has + Map.set
    // Map.getOrInsertComputed is available in TypeScript 6.0+ (ES2025)
    this.#byCustomer
      .getOrInsertComputed(order.customerId, () => new Set<string>())
      .add(order.id);

    return order;
  }

  async findByCustomer(customerId: string): Promise<Order[]> {
    // One lookup — result is Set<string> | undefined; handle both cases:
    const orderIds = this.#byCustomer.get(customerId);
    if (orderIds === undefined) return [];
    return [...orderIds]
      .map(id => this.#store.get(id))
      .filter((o): o is Order => o !== undefined);
  }
}
```

**[community] The `!` non-null assertion operator is a map-double-lookup smell.** Every `this.#store.get(id)!` in a TypeScript fake is evidence of a missing one-lookup-with-narrowing pattern. A TDD code review checklist should flag `!` in fake implementations as a defect: replace with a single lookup, explicit undefined check, and typed error or early return.

---

### TCR — Test && Commit || Revert in TypeScript [community]

TCR (Test && Commit || Revert), introduced by Kent Beck, enforces baby-steps discipline through automation: if the tests pass, the change is committed; if they fail, the change is reverted. This removes the option of accumulating a large failing state during the TDD cycle.

TCR is the fastest way to internalise baby-steps discipline (gotcha #13 above). Here is a production-ready TCR script for TypeScript/Vitest projects:

```bash
#!/usr/bin/env bash
# tcr.sh — Test && Commit || Revert for TypeScript/Vitest projects
# Usage: ./tcr.sh [test-pattern]
#   e.g.: ./tcr.sh "src/domain/cart/Cart.test.ts"
#         ./tcr.sh                  (runs all tests)

set -euo pipefail

TEST_PATTERN="${1:-}"
COMMIT_MSG="${TCR_COMMIT_MSG:-chore: tcr step}"

# Run Vitest (esbuild — fast; no full tsc compile)
if [ -n "$TEST_PATTERN" ]; then
  npx vitest run "$TEST_PATTERN" --reporter=verbose
else
  npx vitest run --reporter=verbose
fi

# Tests passed — stage all and commit
git add -A
git commit -m "$COMMIT_MSG ($(date +%H:%M:%S))" --quiet
echo "✓ TCR: tests passed — committed"
```

```bash
# tcr-watch.sh — file-watcher variant (restarts TCR loop on file change)
# Requires: entr (brew install entr / apt-get install entr)
#!/usr/bin/env bash
while true; do
  find src -name '*.ts' | entr -d ./tcr.sh
done
```

```typescript
// vitest.config.ts — optimised for TCR loop
// Key: bail: 1 ensures the first failure reverts quickly, not after running the full suite
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    bail: 1,          // Stop at first failure — TCR revert signal should be fast
    reporter: ['verbose'],
    // Do NOT enable coverage in TCR mode — it doubles execution time
    // Run coverage separately in CI
    coverage: { enabled: process.env.CI === 'true', provider: 'v8' },
  },
});
```

**[community] TCR revert policy differences across teams:** Some teams configure TCR to revert only uncommitted changes (`git checkout -- .`); others revert all working-tree changes including untracked files. For TypeScript projects, the recommended policy is `git checkout -- src/` (revert source only) to preserve generated files and `node_modules`. Do not use `git reset --hard` in TCR — it can discard work that is genuinely in-progress.

**[community] TCR with TypeScript compile errors:** If a TypeScript file fails to compile (not just fails tests), TCR should also revert. The recommended approach is to run `npx tsc --noEmit` as a pre-test step in the TCR script — compile errors are treated the same as test failures (revert). Without this, a TDD cycle that produces a compile error instead of a test failure escapes the TCR discipline.

```bash
# tcr-strict.sh — TCR with type-checking gate
#!/usr/bin/env bash
set -euo pipefail

# Step 1: Type-check first (fast fail for compile errors)
npx tsc --noEmit --incremental --tsBuildInfoFile .tsbuildinfo-tcr || {
  echo "✗ TCR: TypeScript compile error — reverting"
  git checkout -- src/
  exit 1
}

# Step 2: Run tests
TEST_PATTERN="${1:-}"
if [ -n "$TEST_PATTERN" ]; then
  npx vitest run "$TEST_PATTERN" --reporter=verbose || {
    echo "✗ TCR: tests failed — reverting"
    git checkout -- src/
    exit 1
  }
else
  npx vitest run --reporter=verbose || {
    echo "✗ TCR: tests failed — reverting"
    git checkout -- src/
    exit 1
  }
fi

git add -A
git commit -m "chore: tcr ($(date +%H:%M:%S))" --quiet
echo "✓ TCR: passed — committed"
```

---

### Zod v4 — TDD-Relevant Changes [community]

Zod v4 (released 2025) introduced several features that change how TDD test cases interact with schema validation in TypeScript projects. Teams running `expect.schemaMatching` (Vitest 4.0) against Zod schemas should be aware of the v4 API surface.

#### `z.input<T>` / `z.output<T>` — Separate Input and Output Types for Test Data

In Zod v3, `z.infer<T>` returned a single type that blurred the distinction between the _incoming_ shape (before coercion) and the _outgoing_ shape (after parsing). Zod v4 adds `z.input<T>` and `z.output<T>` as first-class utilities. In TDD, this matters when constructing test data: the test case arrange step must use the **input** type (what the user/API sends), while assertions check the **output** type (what the domain model receives after parsing).

```typescript
// zod-v4-tdd.test.ts — z.input vs z.output in TDD test cases
import { describe, it, expect } from 'vitest';
import { z } from 'zod'; // Zod v4
import { createOrder } from './createOrder.js';

// Domain schema: accepts flexible date input, always produces Date objects
const OrderSchema = z.object({
  id:         z.string().uuid(),
  total:      z.number().positive(),
  createdAt:  z.coerce.date(),   // accepts string | number | Date input → produces Date
  status:     z.enum(['pending', 'processing', 'shipped', 'delivered']),
});

// Zod v4 types — explicit separation of raw and parsed shapes
type OrderInput  = z.input<typeof OrderSchema>;   // { id: string; total: number; createdAt: string | number | Date; status: ... }
type OrderOutput = z.output<typeof OrderSchema>;  // { id: string; total: number; createdAt: Date; status: ... }

// ---- RED: write test data using the INPUT type (as-received from HTTP/queue) ----
const rawOrderInput: OrderInput = {
  id:        '550e8400-e29b-41d4-a716-446655440000',
  total:     99.99,
  createdAt: '2026-05-12T10:00:00Z',  // ← string, not Date — correct for input type
  status:    'pending',
};

describe('createOrder', () => {
  it('accepts a valid raw order and returns a parsed domain object', async () => {
    const order = await createOrder(rawOrderInput);

    // Assert on OUTPUT type — createdAt must be a real Date after parsing
    const expected: Partial<OrderOutput> = {
      id:     '550e8400-e29b-41d4-a716-446655440000',
      total:  99.99,
      status: 'pending',
    };
    expect(order).toMatchObject(expected);
    expect(order.createdAt).toBeInstanceOf(Date);  // coercion happened — string → Date
  });

  it('rejects an order with negative total', async () => {
    const invalid: OrderInput = { ...rawOrderInput, total: -1 };
    await expect(createOrder(invalid)).rejects.toThrow();
  });
});

// ---- GREEN: createOrder calls OrderSchema.parse() internally ----
// createOrder.ts
import { OrderSchema } from './order-schema.js';
import type { OrderOutput } from './order-schema.js';

export async function createOrder(raw: unknown): Promise<OrderOutput> {
  return OrderSchema.parse(raw); // throws ZodError on invalid input
}
```

**Why the input/output distinction matters for TDD:** Before Zod v4, teams often wrote test data as the _output_ type — using `new Date(...)` directly in test fixtures even though the API receives ISO strings. The tests passed, but they never exercised the coercion path. With `z.input<T>`, the test arrange step is typed to the actual incoming shape, forcing the test case to cover the coercion logic. **Any test that constructs input data using `OrderOutput` types instead of `OrderInput` types is exercising the wrong path.**

#### `expect.schemaMatching` with Zod v4 API Changes

The `expect.schemaMatching` matcher in Vitest 4.0 is Standard Schema v1-compatible. Zod v4 is also Standard Schema v1-compatible, so the integration is seamless — but two Zod v4 API changes affect test cases:

```typescript
// ---- Updated expect.schemaMatching test cases for Zod v4 ----
import { describe, it, expect } from 'vitest';
import { z } from 'zod'; // Zod v4
import { getUserHandler } from './getUserHandler.js';

// CHANGE 1: z.string().url() → z.string().httpUrl() in Zod v4
// Old test case (Zod v3) — still compiles but .url() is deprecated in v4:
const OldUserSchema = z.object({
  id:       z.string().uuid(),
  website:  z.string().url(),  // ← Zod v3 — accepts malformed URLs; deprecated in v4
});

// Updated test case (Zod v4):
const UserSchema = z.object({
  id:       z.string().uuid(),
  email:    z.string().email(),
  website:  z.string().httpUrl().optional(),  // ← Zod v4 — rejects 'https:/example.com'
  role:     z.enum(['admin', 'member']),
});

describe('getUserHandler', () => {
  it('returns a valid user shape (schema-validated)', async () => {
    const user = await getUserHandler({ userId: '550e8400-e29b-41d4-a716-446655440000' });

    // Standard Schema v1 integration — Zod v4 schema used directly as matcher spec
    expect(user).toMatchObject(expect.schemaMatching(UserSchema));
  });
});

// CHANGE 2: z.toJSONSchema() replaces the third-party zod-to-json-schema package
// TDD test case: verify the schema produces the expected JSON Schema shape
it('generates correct JSON Schema for API documentation', () => {
  const jsonSchema = z.toJSONSchema(UserSchema);  // built-in in Zod v4 — no extra package
  expect(jsonSchema).toMatchObject({
    type: 'object',
    required: expect.arrayContaining(['id', 'email', 'role']),
    properties: expect.objectContaining({
      id:   { type: 'string', format: 'uuid' },
      role: { enum: ['admin', 'member'] },
    }),
  });
});
```

**[community] Zod v4 upgrade gotcha in test suites:** Upgrading from Zod v3 to v4 with a passing TypeScript build does NOT guarantee a passing test suite. Zod v4's stricter runtime validators — `.httpUrl()` rejects `'https:/example.com'`, `.base64()` rejects whitespace — can cause test cases that used relaxed input strings to fail at parse time. **Run the full test suite immediately after upgrading; do not assume compile-success = runtime-safe.** Audit every test fixture that contains URL or base64 strings against the v4 validation rules before merging the upgrade PR.

---

### TDD Resource Management — `using` and `await using` (TypeScript 5.2) [community]

TypeScript 5.2 added the `using` and `await using` keywords from the ECMAScript Explicit Resource Management proposal. In TDD, this provides a typed, compiler-enforced pattern for test resource teardown — replacing fragile `afterEach` cleanup with guaranteed disposal scoped to the test case body.

Without `using`, test resource cleanup relies on `afterEach` hooks that run after the test case, regardless of whether the cleanup was registered for that specific resource. When test cases conditionally create resources (in branches), the `afterEach` often over-cleans (disposes resources that were never created) or under-cleans (misses resources created inside conditional paths).

```typescript
// test-doubles/disposable.ts — disposable resource wrappers for TDD
// Typed helper to create IDisposable in-memory fakes
import { vi } from 'vitest';

// Define a typed disposable wrapper for any resource
export interface Disposable {
  [Symbol.dispose](): void;
}

export interface AsyncDisposable {
  [Symbol.asyncDispose](): Promise<void>;
}

// Wraps a Vitest spy module to auto-restore after the test case
export function useSpy<T extends object, K extends keyof T>(
  obj: T,
  method: K
): ReturnType<typeof vi.spyOn<T, K>> & Disposable {
  const spy = vi.spyOn(obj, method);
  return Object.assign(spy, {
    [Symbol.dispose]() { spy.mockRestore(); }
  });
}

// Disposable in-memory database connection — auto-closes after test case
export class InMemoryDatabase implements AsyncDisposable {
  readonly #records = new Map<string, unknown>();
  #closed = false;

  save<T>(id: string, record: T): void {
    if (this.#closed) throw new Error('Database already disposed');
    this.#records.set(id, record);
  }

  find<T>(id: string): T | undefined {
    return this.#records.get(id) as T | undefined;
  }

  async [Symbol.asyncDispose](): Promise<void> {
    // Simulate async teardown (e.g., closing a real DB connection pool)
    this.#records.clear();
    this.#closed = true;
  }
}

// service-tests.test.ts — using/await using for TDD resource lifecycle
import { describe, it, expect } from 'vitest';
import { UserService } from './UserService.js';
import { InMemoryDatabase, useSpy } from './test-doubles/disposable.js';
import * as mailerModule from './mailer.js';

describe('UserService', () => {
  // Test case 1: await using guarantees teardown even if the test throws
  it('saves a user to the database', async () => {
    await using db = new InMemoryDatabase();  // ← auto-disposed when scope exits
    const service = new UserService(db);

    await service.createUser({ id: 'u1', email: 'alice@example.com' });

    expect(db.find('u1')).toMatchObject({ email: 'alice@example.com' });
    // db[Symbol.asyncDispose]() called automatically — no afterEach needed
  });

  // Test case 2: using for synchronous spy — auto-restores when test case exits
  it('sends a welcome email on registration', async () => {
    using spy = useSpy(mailerModule, 'send');  // ← spy auto-restored when scope exits
    spy.mockResolvedValue(undefined);

    await using db = new InMemoryDatabase();
    const service = new UserService(db);
    await service.createUser({ id: 'u2', email: 'bob@example.com' });

    expect(spy).toHaveBeenCalledWith(
      expect.objectContaining({ to: 'bob@example.com', subject: 'Welcome!' })
    );
    // spy.mockRestore() and db[Symbol.asyncDispose]() called in reverse scope order
  });
});
```

**Why `using`/`await using` improves TDD teardown reliability:**

1. **Scope-bound teardown:** Resources are disposed when the `using` block's scope exits — whether by normal completion, thrown exception, or early return. No `afterEach` timing issues.
2. **Deterministic disposal order:** Multiple `using` declarations in the same scope are disposed in reverse declaration order — matching stack semantics. Predictable in test cases.
3. **TypeScript-enforced contract:** The `[Symbol.dispose]()` method is typed — TypeScript errors if a resource is declared with `using` but the object does not implement the disposal symbol. The compiler catches missing teardown implementations at test authoring time.
4. **Conditional resource safety:** Unlike `afterEach` where you must guard conditionally-created resources, `using` in a branch only disposes if the branch executed and the resource was assigned.

**[community] `using` with Vitest `vi.spyOn` eliminates the most common spy cleanup bug.** Starting with Vitest 3.2, `vi.spyOn()` and `vi.fn()` directly return objects that implement `Symbol.dispose`, so you can use `using` without any wrapper:

```typescript
// Vitest 3.2+ — vi.spyOn and vi.fn natively support using (no wrapper needed)
it('intercepts console.error during the test case only', () => {
  using spy = vi.spyOn(console, 'error').mockImplementation(() => {});
  runCodeThatMightLogErrors();
  expect(spy).toHaveBeenCalled();
  // console.error is automatically restored here when the scope exits
  // — even if the expect() assertion above throws
});

// Multiple spies in one test: reversed disposal order is deterministic
it('layers multiple spies safely', () => {
  using dateSpy = vi.spyOn(Date, 'now').mockReturnValue(1_000_000_000_000);
  using mathSpy = vi.spyOn(Math, 'random').mockReturnValue(0.5);
  // mathSpy disposed first, then dateSpy — reverse declaration order
  const token = generateToken(); // uses both Date.now and Math.random
  expect(token).toMatchSnapshot();
});
```

The canonical TDD spy pattern — `const spy = vi.spyOn(...); afterEach(() => spy.mockRestore())` — silently fails when a test case throws before the spy is registered in `afterEach`. With `using spy = vi.spyOn(...)` (Vitest 3.2+), restoration is guaranteed by the disposal scope. Teams that adopted this pattern report eliminating an entire class of "spy leaked between test cases" flakiness incidents.

---

### Database-Level TDD Isolation — Neon DB Branching [community]

Traditional TDD database strategies use in-memory fakes or transaction rollbacks for isolation. Neon DB's copy-on-write branching model offers a third option: a real Postgres branch per test run (or per test case), instantly created and disposed, with full SQL fidelity and no shared state between runs.

This is particularly valuable for TDD of SQL-specific behaviour — JSONB queries, partial indexes, window functions — that in-memory fakes cannot replicate.

```typescript
// neon-tdd-setup.ts — Neon DB branching for per-test Postgres isolation
// Requires: @neondatabase/serverless, neonctl CLI configured with API key

import { neon } from '@neondatabase/serverless';

interface NeonBranch {
  branchId: string;
  connectionString: string;
}

// Creates a Neon DB branch from the schema-only base branch
// Returns a connection string for the isolated test database
async function createTestBranch(baseBranchId: string): Promise<NeonBranch> {
  const { execSync } = await import('child_process');
  const output = execSync(
    `neonctl branches create --parent ${baseBranchId} --no-autosuspend --output json`,
    { encoding: 'utf-8' }
  );
  const branch = JSON.parse(output) as { id: string; connection_string: string };
  return { branchId: branch.id, connectionString: branch.connection_string };
}

async function deleteTestBranch(branchId: string): Promise<void> {
  const { execSync } = await import('child_process');
  execSync(`neonctl branches delete ${branchId}`, { encoding: 'utf-8' });
}

// AsyncDisposable Neon branch — auto-deleted when test scope exits
class TestNeonBranch implements AsyncDisposable {
  readonly #branchId: string;
  readonly #sql: ReturnType<typeof neon>;

  constructor(branchId: string, connectionString: string) {
    this.#branchId = branchId;
    this.#sql = neon(connectionString);
  }

  get sql(): ReturnType<typeof neon> { return this.#sql; }

  async [Symbol.asyncDispose](): Promise<void> {
    await deleteTestBranch(this.#branchId);
  }
}

// Factory: create a disposable Neon branch for a single test or test suite
export async function useDatabaseBranch(
  baseBranchId = process.env.NEON_BASE_BRANCH_ID ?? 'main'
): Promise<TestNeonBranch> {
  const branch = await createTestBranch(baseBranchId);
  return new TestNeonBranch(branch.branchId, branch.connectionString);
}

// --- TDD test case using a real Postgres branch ---
// user-repository.integration.test.ts
import { describe, it, expect } from 'vitest';
import { useDatabaseBranch } from './neon-tdd-setup.js';
import { PostgresUserRepository } from './PostgresUserRepository.js';

describe('PostgresUserRepository (real DB, isolated branch)', () => {
  it('saves and retrieves a user with correct SQL types', async () => {
    await using branch = await useDatabaseBranch();  // own branch, deleted on scope exit
    const repo = new PostgresUserRepository(branch.sql);

    const saved = await repo.create({ email: 'alice@example.com', name: 'Alice', role: 'member' });

    expect(saved.id).toMatch(/^[0-9a-f-]{36}$/);  // UUID — real DB generates it
    const found = await repo.findById(saved.id);
    expect(found?.email).toBe('alice@example.com');
  });

  it('enforces the unique email constraint at the SQL level', async () => {
    await using branch = await useDatabaseBranch();  // separate branch from test above
    const repo = new PostgresUserRepository(branch.sql);

    await repo.create({ email: 'dup@example.com', name: 'First', role: 'member' });
    await expect(
      repo.create({ email: 'dup@example.com', name: 'Second', role: 'member' })
    ).rejects.toMatchObject({ code: 'DUPLICATE_EMAIL' });
  });
});
```

**Tradeoffs vs in-memory fakes:**

| Approach | Frequency | Fidelity | Overhead | Lifespan |
|----------|-----------|----------|----------|----------|
| In-memory fake | High (< 1ms) | Low (SQL quirks not tested) | Low (no infra) | High |
| Transaction rollback | Medium (10–100ms) | High (real SQL) | Medium (requires live DB) | High |
| Neon DB branch | Low (2–5s branch create) | Very High (real Postgres, own schema) | High (Neon account, CI costs) | Medium |

**[community] Neon DB branching is not a replacement for in-memory fakes in the TDD inner loop.** Branch creation takes 2–5 seconds — too slow for the red-green-refactor watch cycle. The correct pattern: use in-memory fakes for all unit-level TDD cycles, and use Neon branches for the integration test suite that runs in CI. This gives the TDD feedback loop at the unit level while catching SQL-specific defects that in-memory fakes cannot detect. **Do not run Neon-branch test cases in the Vitest watch loop — add them to a separate `integration` workspace in `vitest.config.ts` that runs only in CI.**

**[community] Neon's schema-only base branch prevents data contamination between branches.** If the base branch contains seed data, every derived test branch starts with that data — which can make test cases order-dependent. The recommended TDD setup: use a `schema-only` base branch (Neon's built-in option) so that each test branch starts empty. Each test case is responsible for creating its own test data in the arrange step. This mirrors the FIRST principle (Independent, Repeatable) at the integration test level.

---

### `Promise.try` (TypeScript 6.0 / ES2025) — TDD for Sync-to-Async Wrappers [community]

`Promise.try(fn)` executes a synchronous function and wraps any thrown exception into a rejected promise, returning the result as a promise regardless. In TDD, this eliminates a category of test case that was previously awkward: testing functions that _may_ throw synchronously or return a promise, depending on the input.

Before `Promise.try`, wrapping sync-throw functions for async chains required try/catch boilerplate or `new Promise(...)` constructors — both hard to test precisely. `Promise.try` makes the sync-throw path visible as a rejected promise, which `expect(...).rejects.toThrow()` can assert cleanly.

```typescript
// TDD for a pipeline step that may throw synchronously or resolve asynchronously
// pipeline-step.test.ts
import { describe, it, expect } from 'vitest';
import { parsePipelineInput, PipelineInput } from './parsePipelineInput.js';

// Test case 1: RED — valid input resolves normally
describe('parsePipelineInput', () => {
  it('resolves with parsed input for valid data', async () => {
    const result = await Promise.try(() =>
      parsePipelineInput({ command: 'process', payload: { id: 'x1' } })
    );
    expect(result.command).toBe('process');
  });

  // Test case 2: RED — invalid input rejects (sync throw → rejected promise)
  it('rejects when command is missing', async () => {
    await expect(
      Promise.try(() => parsePipelineInput({ payload: { id: 'x1' } } as unknown as PipelineInput))
    ).rejects.toThrow(/command.*required/i);
  });

  // Test case 3: RED — async function inside Promise.try can also reject
  it('rejects when payload ID is not found (async lookup)', async () => {
    await expect(
      Promise.try(async () => {
        const parsed = parsePipelineInput({ command: 'process', payload: { id: 'unknown' } });
        await verifyIdExists(parsed.payload.id); // async check — throws if not found
      })
    ).rejects.toThrow(/id.*not found/i);
  });
});

// GREEN: synchronous parser — throws directly (no promise wrapping needed)
// parsePipelineInput.ts
export interface PipelineInput {
  command: string;
  payload: { id: string };
}

export function parsePipelineInput(raw: unknown): PipelineInput {
  if (typeof raw !== 'object' || raw === null) {
    throw new TypeError('Pipeline input must be an object');
  }
  const input = raw as Record<string, unknown>;
  if (typeof input.command !== 'string' || !input.command) {
    throw new TypeError('command is required');
  }
  if (typeof input.payload !== 'object' || input.payload === null) {
    throw new TypeError('payload is required');
  }
  return raw as PipelineInput;
}

// The function throws synchronously. Without Promise.try, callers that want a
// rejected promise must manually wrap: new Promise((_, reject) => { try { ... } catch(e) { reject(e); } })
// With Promise.try, the async pipeline step is a one-liner and the TDD test case
// is uniform — both sync throws and async rejects use expect(...).rejects.toThrow().
```

**Why `Promise.try` improves TDD test cases:**

1. **Uniform assertion API:** Both synchronous throws (from validation) and asynchronous rejects (from I/O) surface as `rejects.toThrow()` — one assertion pattern covers both code paths.
2. **Eliminates try/catch boilerplate in tests:** Without `Promise.try`, test cases that exercise sync-throw paths need `expect(() => fn()).toThrow()` (sync) or `expect(fn()).rejects.toThrow()` (async) — different matchers for the same conceptual failure. `Promise.try` unifies them.
3. **Forces the pipeline author to decide:** If a pipeline step _sometimes_ throws and _sometimes_ rejects, `Promise.try` makes that behaviour explicit in both the production code and the test case. TDD-driven refactoring usually leads to consistent error handling (always reject, never throw) which makes callers simpler.

**[community] `Promise.try` requires Node.js 22+ and TypeScript 6.0 (with `"lib": ["ES2025"]` or `"esnext"`).** Check the `engines` field in `package.json` before adding `Promise.try` to production code. A TDD test case that exercises `Promise.try` will fail at runtime on Node < 22 with `Promise.try is not a function` — use a `skipIf` guard during migration:

```typescript
import { describe, it, expect, skipIf } from 'vitest';

const promiseTryAvailable = typeof Promise.try === 'function';

describe.skipIf(!promiseTryAvailable)('Promise.try-based pipeline', () => {
  it('rejects on sync throw', async () => {
    await expect(
      Promise.try(() => { throw new Error('sync fail'); })
    ).rejects.toThrow('sync fail');
  });
});
```

---

### Vitest 4.1 — TDD-Relevant Changes [community]

Vitest 4.1 (released 2026) adds several features that directly improve TDD workflows in TypeScript projects, building on Vitest 4.0.

#### `--detect-async-leaks` — Catching Leaked Timers in TDD Test Cases

A new `--detect-async-leaks` flag detects leaked timers and handles that survive beyond a test case's lifecycle. In TDD, leaked timers are a common cause of false-green test cases: an async operation fires _after_ the assertion, the test case passes, but the leaked timer causes the next test case to behave unpredictably.

```typescript
// Run Vitest with async leak detection enabled (recommended for TDD watch loop)
// vitest --detect-async-leaks

// Example of a leaking timer caught by --detect-async-leaks:
// order-poller.test.ts
import { describe, it, expect, vi } from 'vitest';
import { OrderPoller } from './OrderPoller.js';

describe('OrderPoller', () => {
  it('polls for order status every 5 seconds', async () => {
    vi.useFakeTimers();
    const poller = new OrderPoller({ intervalMs: 5000 });
    const statuses: string[] = [];

    poller.start((status) => statuses.push(status));
    vi.advanceTimersByTime(10_000); // advance 10 seconds

    expect(statuses).toHaveLength(2);
    // ❌ BUG: poller.stop() not called — timer leaks into the next test case
    // --detect-async-leaks will report: "Detected 1 leaked timer in 'polls for order status'"
  });

  it('stops polling when stop() is called', async () => {
    vi.useFakeTimers();
    const poller = new OrderPoller({ intervalMs: 5000 });
    const statuses: string[] = [];

    poller.start((status) => statuses.push(status));
    vi.advanceTimersByTime(5_000);
    poller.stop(); // ✅ clean teardown — no timer leak
    vi.advanceTimersByTime(5_000); // advancing time after stop should not produce more calls

    expect(statuses).toHaveLength(1);
    // --detect-async-leaks: no leak reported — the timer was properly cleared
  });
});
```

**TDD discipline with `--detect-async-leaks`:** Enabling this flag in the TDD watch loop catches missing `stop()`/`clear()` calls during the Refactor phase — before they become CI-only failures. The flag produces warnings (not failures by default), but pairing it with `--reporter=verbose` makes leak reports visible inline with test output. Add it to the `vitest.config.ts` `test.detectLeaks` option to enable permanently.

```typescript
// vitest.config.ts — enable leak detection as a permanent TDD health gate
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    detectLeaks: true,    // Vitest 4.1: equivalent to --detect-async-leaks
    reporter: ['verbose'],
    bail: 1,
  },
});
```

#### `vi.defineHelper()` — Type-Safe Custom Assertion Stack Traces

`vi.defineHelper()` marks a function as a test helper, causing Vitest to point stack traces to the _call site_ rather than to the helper internals. In TDD, custom helpers improve test case readability but obscure failure locations — `vi.defineHelper()` resolves this without sacrificing the helper abstraction.

```typescript
// test-doubles/helpers.ts — custom assertions with correct stack trace attribution
import { expect, vi } from 'vitest';

// ❌ WITHOUT vi.defineHelper(): stack trace points to `assertOrderCreated` line,
//    not the test case line that called it
export function assertOrderCreated(spy: ReturnType<typeof vi.fn>, orderId: string) {
  expect(spy).toHaveBeenCalledOnce();
  expect(spy).toHaveBeenCalledWith(expect.objectContaining({ orderId }));
}

// ✅ WITH vi.defineHelper(): stack trace points to the line in the test case
//    that called assertOrderCreated — TDD failure is immediately locatable
export const assertOrderCreated = vi.defineHelper(
  function assertOrderCreated(spy: ReturnType<typeof vi.fn>, orderId: string) {
    expect(spy).toHaveBeenCalledOnce();
    expect(spy).toHaveBeenCalledWith(expect.objectContaining({ orderId }));
  }
);

// Usage in a TDD test case:
// order-service.test.ts
import { describe, it, vi } from 'vitest';
import { assertOrderCreated } from './test-doubles/helpers.js';
import { OrderService } from './OrderService.js';
import { FakeOrderRepository } from './test-doubles/FakeOrderRepository.js';

describe('OrderService.create', () => {
  it('persists a new order and emits a creation event', async () => {
    const repo = new FakeOrderRepository();
    const emitSpy = vi.fn<[{ orderId: string }], void>();
    const service = new OrderService(repo, emitSpy);

    await service.create({ userId: 'u1', items: [{ sku: 'A', qty: 1 }] });

    // When this fails, the stack trace points HERE — not inside assertOrderCreated
    assertOrderCreated(emitSpy, expect.any(String));
  });
});
```

#### `mockThrow()` and `mockThrowOnce()` — Explicit Error Injection in TDD

Vitest 4.1 adds `mockThrow(error)` and `mockThrowOnce(error)` as first-class methods on mock functions, replacing the `mockImplementation(() => { throw error })` boilerplate. In TDD, these make the _error injection_ step in test case Arrange phases explicit and readable.

```typescript
// Vitest 4.1: mockThrow/mockThrowOnce for error path TDD
import { describe, it, expect, vi } from 'vitest';
import { PaymentService } from './PaymentService.js';

interface PaymentGateway {
  charge(amount: number): Promise<{ transactionId: string }>;
}

describe('PaymentService error handling', () => {
  // Test case: RED — what happens when the gateway throws?
  it('retries once on PaymentGatewayError', async () => {
    const gatewayMock = {
      charge: vi.fn<[number], Promise<{ transactionId: string }>>()
        .mockThrowOnce(new Error('Gateway timeout'))  // ← Vitest 4.1: explicit throw injection
        .mockResolvedValueOnce({ transactionId: 'txn-123' }), // ← second call succeeds
    };
    const service = new PaymentService(gatewayMock);

    const result = await service.charge(50);

    expect(result.transactionId).toBe('txn-123');
    expect(gatewayMock.charge).toHaveBeenCalledTimes(2); // retry happened
  });

  // Test case: RED — exhausted retries propagate the error
  it('throws PaymentGatewayError after exhausting retries', async () => {
    const gatewayMock = {
      charge: vi.fn<[number], Promise<{ transactionId: string }>>()
        .mockThrow(new Error('Gateway unavailable')), // ← always throws (not just once)
    };
    const service = new PaymentService(gatewayMock);

    await expect(service.charge(50)).rejects.toThrow('Gateway unavailable');
    expect(gatewayMock.charge).toHaveBeenCalledTimes(3); // max retries exhausted
  });
});
```

**Why `mockThrow` improves TDD readability:** The Arrange phase intent is immediately clear — "this dependency will throw" — without reading through a `mockImplementation` body. `mockThrowOnce` precisely models the common production scenario where a third-party call fails transiently (network blip) and then succeeds.

#### `aroundEach` and `aroundAll` Hooks — Generator-Based Test Lifecycle [community]

Vitest 4.1 introduces `aroundEach` and `aroundAll` hooks that use generator syntax to wrap test case execution. Unlike `beforeEach`/`afterEach` pairs, the generator approach keeps setup and teardown co-located in a single function — eliminating the coordination bugs that arise when `afterEach` references variables that were not assigned when `beforeEach` threw.

```typescript
// vitest 4.1: aroundEach for co-located setup/teardown
import { describe, it, expect } from 'vitest';
import { InMemoryDatabase } from './test-doubles/InMemoryDatabase.js';
import { UserRepository } from './UserRepository.js';

describe('UserRepository', () => {
  // aroundEach wraps every test case — setup before yield, teardown after yield
  aroundEach(async function* ({ task }) {
    // Setup: create a fresh isolated database for each test case
    const db = new InMemoryDatabase();
    await db.seed([
      { id: 'seed-1', email: 'seeded@example.com', name: 'Seed User' }
    ]);

    // Inject the db into the test case via task context
    task.context.db = db;

    yield; // ← test case runs here

    // Teardown: guaranteed even if the test case throws
    await db.dispose();
  });

  it('finds a user by email', async ({ db }: { db: InMemoryDatabase }) => {
    const repo = new UserRepository(db);
    const user = await repo.findByEmail('seeded@example.com');
    expect(user?.name).toBe('Seed User');
  });

  it('returns null for unknown email', async ({ db }: { db: InMemoryDatabase }) => {
    const repo = new UserRepository(db);
    const result = await repo.findByEmail('nobody@example.com');
    expect(result).toBeNull();
  });
});
```

**Why `aroundEach` improves TDD over separate `beforeEach`/`afterEach`:**

1. **Co-location:** Setup and teardown are in one function — easier to reason about what each test case receives and what gets cleaned up.
2. **Guaranteed teardown:** The `finally` equivalent is implicit — teardown after `yield` runs regardless of whether the test case throws.
3. **No `let` hoisting for shared variables:** Traditional `beforeEach`/`afterEach` requires `let db: InMemoryDatabase` hoisted outside both hooks. `aroundEach` eliminates the hoisted `let` that TypeScript cannot initialise-check across hook boundaries.

#### Test Tags — Categorising TDD Test Suites [community]

Vitest 4.1 introduces a tagging system that lets test cases be labelled and filtered. In TDD, this provides a disciplined way to separate the fast TDD inner loop (unit test cases, < 1s) from slower integration test cases and scheduled mutation tests — without maintaining separate config files.

```typescript
// vitest 4.1 test tags — categorise by execution speed and scope
import { describe, it, expect } from 'vitest';
import { PricingEngine } from './PricingEngine.js';
import { PostgresPricingRepository } from './PostgresPricingRepository.js';

// Unit test cases: tagged 'unit' — run in TDD watch loop
describe('PricingEngine', { tags: ['unit'] }, () => {
  it('applies 10% discount for premium tier', () => {
    const engine = new PricingEngine();
    const result = engine.calculate({ subtotal: 100, tier: 'premium' });
    expect(result.discount).toBe(10);
  });
});

// Integration test cases: tagged 'integration' — run only in CI
describe('PostgresPricingRepository', { tags: ['integration', 'database'] }, () => {
  it('fetches pricing rules from the live database', async () => {
    const repo = new PostgresPricingRepository(process.env.DATABASE_URL!);
    const rules = await repo.getAllRules();
    expect(rules.length).toBeGreaterThan(0);
  });
});

// Slow test cases: tagged 'slow' — excluded from TDD watch loop
it.tags(['slow', 'mutation'])('mutation test: all branches covered', () => {
  // placeholder — Stryker runs this externally, tag used for filtering only
});
```

```bash
# TDD watch loop: run only fast unit test cases
npx vitest --watch --project.include-tags unit

# CI full run: run everything
npx vitest run

# CI integration only: run tagged integration tests
npx vitest run --project.include-tags integration

# Exclude slow tests from watch loop
npx vitest --watch --project.exclude-tags slow,mutation
```

**Tag filtering syntax supports `and`, `or`, `not`, and wildcards:**

```bash
# Run test cases tagged 'unit' AND 'pricing' (both tags required)
npx vitest --watch --project.include-tags "unit and pricing"

# Exclude test cases tagged 'database' OR 'slow'
npx vitest --watch --project.exclude-tags "database or slow"
```

#### `coverage.changed` — Scoped Coverage for TDD Increments [community]

Vitest 4.1's `coverage.changed` option limits coverage reporting to files that were modified relative to the current git branch. In TDD, this surfaces the coverage of the specific module you are developing without being diluted by the existing test suite.

```typescript
// vitest.config.ts — coverage.changed for TDD incremental sessions
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      enabled: true,
      provider: 'v8',
      // coverage.changed: only report coverage for files modified since the branch base
      // Useful in TDD sessions where you want to verify the new module is fully covered
      changed: process.env.TDD_SESSION === 'true',

      // Full coverage still runs in CI (changed not set)
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/test-doubles/**'],
      thresholds: {
        branches: 80,
        functions: 85,
        lines: 85,
      },
    },
  },
});
```

```bash
# TDD session: see coverage only for files you've changed in this branch
TDD_SESSION=true npx vitest run --coverage

# Coverage output scoped to modified files — easier to spot uncovered branches in new code
# Example output:
# src/domain/pricing/PricingEngine.ts  |  100% |   95% |  100% |  100% |
# (only shows the file you've been TDD'ing, not 200 other files)
```

#### GitHub Actions Reporter and `agent` Reporter [community]

Vitest 4.1 adds a GitHub Actions reporter that generates a Job Summary with test statistics and — critically — flaky test permalinks. This makes TDD-detected intermittent failures visible in the PR review without digging through raw CI logs.

```typescript
// vitest.config.ts — GitHub Actions reporter for TDD PR visibility
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    reporter: process.env.GITHUB_ACTIONS === 'true'
      ? ['verbose', 'github-actions']  // Vitest 4.1 — generates Job Summary in GitHub Actions
      : ['verbose'],
  },
});
```

The `agent` reporter (also new in 4.1) minimises token usage for AI coding agents running test cases. In AI-assisted TDD workflows (where Claude or Copilot runs tests in a loop), this reporter suppresses verbose output and emits only structured pass/fail data — reducing inference costs and noise.

```typescript
// vitest.config.ts — agent reporter for AI-assisted TDD loops
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    reporter: process.env.AI_AGENT === 'true'
      ? ['agent']      // Vitest 4.1: minimal output for AI coding agents
      : ['verbose'],   // Human TDD session: full output
  },
});
```

---

### Real-World Gotchas [community] — Additions (iter 19)

30. **[community] Leaked timers are the second most common cause of order-dependent test failures in Vitest TypeScript projects.** After spy leakage (addressed by `using` in gotcha #28), the next most common isolation defect is a timer started in one test case that fires during a later unrelated test case. Without `detectLeaks: true`, the symptom is intermittent — the failure manifests only when test cases run in a specific order or at a specific speed. Teams enabling `detectLeaks: true` in Vitest 4.1 consistently report finding 3–8 latent timer leaks on first run across a large test suite. Fix: always call `vi.clearAllTimers()` in `afterEach` when using `vi.useFakeTimers()`, or use `aroundEach` to co-locate timer setup and teardown.

31. **[community] `vi.defineHelper()` is the most impactful Vitest 4.1 change for teams with shared TDD helper libraries.** When a shared assertion helper fails, the stack trace without `vi.defineHelper()` points into the helper internals — a TypeScript file that test engineers did not write and are not familiar with. The reported line number is useless for diagnosing the failing test case. With `vi.defineHelper()`, the stack trace points to the specific `it(...)` block in the test file. The fix is wrapping existing helpers with `vi.defineHelper(function namedHelper(...) {...})` — the function must be named (not anonymous) for the stack trace attribution to work correctly.

32. **[community] Vitest 4.1's `aroundEach` generator pattern does not replace `test.extend()` — it complements it.** A common confusion after upgrading to Vitest 4.1: `aroundEach` is suite-scoped (applies to all test cases in a `describe` block), while `test.extend()` fixtures are test-runner-scoped (injected per test case via the test function signature). For TDD test suites that need both suite-level resource management (database per describe block) and per-test-case fixture injection (typed repository per test), use `test.extend()` for the per-test-case concerns and `aroundAll` (not `aroundEach`) for the expensive suite-level setup like spinning up a container or seeding a schema.

---

### "The Way of TDD" — Google TotT March 2026 Discipline Checklist [community]

Google Testing Blog's TotT post "The Way of TDD" by Bartosz Papis (March 2026) synthesises TDD as a discipline rather than a procedure — emphasising that the value of TDD comes from the habit, not the acts. The post identifies six discipline commitments that separate practitioners who benefit from TDD from those who experience it as overhead.

**The six commitments (synthesised from the TotT):**

1. **Write the test before the code.** Not "roughly before" — strictly before. The test must exist and fail before a single production line is written. If you find yourself writing code without a failing test, the TDD discipline has lapsed.

2. **Each test case verifies exactly one thing.** A test case that asserts three unrelated properties is three tests in one — any one of them might be wrong, and the failure message will be ambiguous. One failing reason, one assertion group.

3. **The Refactor phase is mandatory, not optional.** "Green and done" is test-first, not TDD. The refactor phase is where the design debt from the Green phase is paid. Skipping it accumulates compound interest: each skipped refactor makes the next Green phase harder.

4. **Baby steps are not timid steps.** A baby step is the smallest step that tests exactly one new behaviour. It is not a sign of low confidence; it is a sign of precise thinking. Each step is a falsifiable hypothesis. Teams that view baby steps as slow are measuring the wrong metric — they should measure time-to-confidence, not lines-per-hour.

5. **Red is information, not failure.** A failing test case is not a problem to eliminate as fast as possible — it is a precise specification of what must be built next. Developers who treat Red as an uncomfortable state rush to Green without understanding the failure. The correct posture: read the failure message carefully, confirm it fails for the right reason, then and only then write the Green implementation.

6. **TDD without pair programming or code review degrades into test-after within months.** The refactor step and baby-steps discipline erode under deadline pressure when no one is watching. TDD is best maintained as a social practice.

```typescript
// "The Way of TDD" checklist applied to a TypeScript feature development session
// This comment block serves as a discipline contract in team agreements

/*
  TDD DISCIPLINE CHECKLIST (per test case):
  
  ☐ Test file exists and imports the function/class (which may not yet exist)
  ☐ Test case fails for the RIGHT reason (missing impl, not compile/import error)
  ☐ Test name reads as a complete sentence: "<unit> <action> <expected outcome>"
  ☐ Arrange section is ≤ 5 lines (if longer, the design has too many dependencies)
  ☐ Act section is exactly 1 line
  ☐ Assert section tests one observable outcome (not implementation internals)
  ☐ Refactor phase completed before next test case is written
  ☐ TypeScript types are tighter after Refactor than before Green
*/

// Applied example: TDD for a rate-limiter with the checklist enforced
// rateLimiter.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { RateLimiter } from './rateLimiter.js';

// Discipline: one test case → one reason to fail → one commit
describe('RateLimiter', () => {
  let clock: ReturnType<typeof vi.useFakeTimers>;

  beforeEach(() => {
    clock = vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  // Test 1: RED — limiter allows first request
  // Name reads: "RateLimiter allows the first request within the window"
  it('allows the first request within the window', () => {
    const limiter = new RateLimiter({ maxRequests: 3, windowMs: 1000 });
    expect(limiter.tryAcquire()).toBe(true);
  });

  // Test 2: RED — consecutive requests up to limit succeed
  it('allows up to maxRequests requests in a single window', () => {
    const limiter = new RateLimiter({ maxRequests: 3, windowMs: 1000 });
    limiter.tryAcquire(); // 1
    limiter.tryAcquire(); // 2
    expect(limiter.tryAcquire()).toBe(true); // 3 — still within limit
  });

  // Test 3: RED — request exceeding limit is denied
  it('denies the request that exceeds maxRequests', () => {
    const limiter = new RateLimiter({ maxRequests: 3, windowMs: 1000 });
    limiter.tryAcquire(); limiter.tryAcquire(); limiter.tryAcquire();
    expect(limiter.tryAcquire()).toBe(false); // 4th — over limit
  });

  // Test 4: RED — window expiry resets the counter
  it('resets the counter after the window expires', () => {
    const limiter = new RateLimiter({ maxRequests: 3, windowMs: 1000 });
    limiter.tryAcquire(); limiter.tryAcquire(); limiter.tryAcquire();
    expect(limiter.tryAcquire()).toBe(false); // denied

    clock.advanceTimersByTime(1001); // window expires

    expect(limiter.tryAcquire()).toBe(true); // allowed again
  });
});

// GREEN (minimal implementation driven by the four test cases):
// rateLimiter.ts
export interface RateLimiterOptions {
  maxRequests: number;
  windowMs: number;
}

export class RateLimiter {
  readonly #maxRequests: number;
  readonly #windowMs: number;
  #count = 0;
  #windowStart: number;

  constructor({ maxRequests, windowMs }: RateLimiterOptions) {
    this.#maxRequests = maxRequests;
    this.#windowMs = windowMs;
    this.#windowStart = Date.now();
  }

  tryAcquire(): boolean {
    const now = Date.now();
    if (now - this.#windowStart >= this.#windowMs) {
      this.#count = 0;
      this.#windowStart = now;
    }
    if (this.#count >= this.#maxRequests) return false;
    this.#count++;
    return true;
  }
}

// REFACTOR (after all 4 tests pass):
// — extract the window-reset check into a private method
// — make #windowStart typed as a readonly tick reference
// — verify TypeScript types: RateLimiterOptions is exported with readonly fields
```

**Why "The Way of TDD" matters as a discipline document:** The checklist form is intentional. TDD's failure mode is not "developers who tried it and it didn't work" — it is "developers who thought they were doing TDD but had drifted to test-first or test-after over months." The discipline checklist makes the drift visible and measurable in PR reviews.

---

### Vitest 4.1 — Experimental Native Node.js Execution [community]

Vitest 4.1 adds an experimental mode where test files are executed directly with Node.js's native runtime — no Vite module transforms, no esbuild. This is enabled per-project with `runner: 'node'` and requires TypeScript files to use Node.js's native type-stripping (Node 23.6+ `--experimental-strip-types`).

For TDD workflows, this produces the fastest possible Red→Green feedback: sub-50ms test runs for small domain modules, because there is no bundler or transpilation overhead.

```typescript
// vitest.config.ts — native Node.js execution for ultra-fast TDD inner loop
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // NOTE: experimental — only for test files that use erasable TypeScript syntax
    // Requires Node.js 23.6+ with --experimental-strip-types
    runner: 'node',           // Skip Vite transforms entirely

    // Required: Vitest must know Node handles the transforms
    // All test files must comply with --erasableSyntaxOnly:
    // - No `enum` declarations
    // - No parameter properties (constructor(public x: T))
    // - No `namespace` with runtime code
    // - No `import =` / `export =` syntax

    include: ['src/domain/**/*.test.ts'],   // Domain unit tests — pure TS, no bundler deps
    exclude: ['src/ui/**', 'src/**/*.browser.test.ts'],  // Browser tests need Vite

    reporter: ['verbose'],
    bail: 1,    // TDD: stop at first failure for clean Red signal
    detectLeaks: true,
  },
});
```

```bash
# Start native-mode TDD watch loop — fastest possible Red→Green cycle
# Requires Node 23.6+ and TypeScript compiled with erasableSyntaxOnly
node --experimental-strip-types \
  node_modules/.bin/vitest --watch \
  --config vitest.native.config.ts \
  src/domain/cart/Cart.test.ts

# Benchmark: compare native vs standard esbuild mode
time npx vitest run --reporter=silent src/domain/cart/Cart.test.ts
# Standard (esbuild): ~300ms on cold start
# Native (node):       ~50ms on cold start — 6x faster for tight TDD loops
```

**Tradeoffs of native Node.js execution in TDD:**

| Aspect | Native `runner: 'node'` | Standard (esbuild) |
|--------|------------------------|-------------------|
| Cold start | ~50ms | ~300ms |
| TypeScript support | Erasable syntax only | Full TypeScript |
| Path aliases | Not supported | Supported via tsconfigPaths |
| Source maps | Native (no transform) | esbuild maps |
| Maturity | Experimental (4.1) | Stable |
| Recommended for | Domain unit TDD loops | All other tests |

**[community] Native execution is not a replacement for standard Vitest — it is a fast lane for the innermost TDD loop.** Use it only for pure domain modules (no React, no Vite-specific imports, no path aliases). Keep the standard esbuild config for integration and UI tests. A `vitest.config.ts` with two projects (one `runner: 'node'` for domain, one standard for UI) lets both modes coexist.

```typescript
// vitest.config.ts — two-project config for TDD speed tiers
import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    projects: [
      {
        // Fast lane: native Node.js execution for pure domain unit tests
        name: 'domain-native',
        runner: 'node',       // Experimental — no Vite
        include: ['src/domain/**/*.test.ts'],
        tags: ['unit', 'domain'],
        testTimeout: 5000,
      },
      {
        // Standard lane: esbuild for everything else
        name: 'standard',
        include: [
          'src/infrastructure/**/*.test.ts',
          'src/ui/**/*.test.ts',
          'src/**/*.integration.test.ts',
        ],
        tags: ['integration', 'ui'],
      },
    ],
    reporter: ['verbose'],
    bail: process.env.CI ? 0 : 1,
    detectLeaks: true,
  },
});
```

**[community] Teams that adopted native Node.js execution for domain unit tests report that the 50ms feedback loop eliminates the "I'll run tests in a batch" habit — the sub-second cycle makes running tests after every small change feel natural rather than disruptive. This is the single largest ergonomic improvement to TDD feedback loops in 2026.**

---

### Vitest Browser Mode — TDD with `page.mark()` Trace Annotations [community]

Vitest 4.1 Browser Mode adds `page.mark()`, a Playwright-compatible API for inserting custom annotations into browser traces. In TDD for UI components, this enables a form of visual Red-Green traceability: each test assertion step can be annotated in the Playwright trace timeline, making the TDD cycle visible as a recorded artifact.

```typescript
// button.browser.test.ts — TDD with trace annotations via page.mark()
import { page } from '@vitest/browser/context';
import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { Button } from './Button.js';

describe('Button component — TDD trace-annotated', () => {
  // Test case 1: RED — button renders with accessible label
  it('renders with the correct accessible label', async () => {
    await page.mark('ARRANGE: render primary button'); // ← trace annotation
    render(<Button variant="primary" label="Submit order" />);

    await page.mark('ACT: locate button by role');     // ← trace annotation
    const btn = page.getByRole('button', { name: 'Submit order' });

    await page.mark('ASSERT: accessible name present');
    await expect.element(btn).toBeInTheDocument();
    await expect.element(btn).toHaveAccessibleName('Submit order');
  });

  // Test case 2: RED — disabled state is keyboard-navigable but inert
  it('is keyboard-navigable when disabled', async () => {
    await page.mark('ARRANGE: render disabled button');
    render(<Button variant="primary" label="Submit" disabled />);

    const btn = page.getByRole('button', { name: 'Submit' });

    await page.mark('ASSERT: aria-disabled, not aria-hidden');
    // Disabled but visible — must be aria-disabled, not removed from tab order
    await expect.element(btn).toHaveAttribute('aria-disabled', 'true');
    await expect.element(btn).not.toHaveAttribute('aria-hidden');
  });
});
```

**Why `page.mark()` improves UI TDD:** In traditional UI TDD, a failing visual test tells you which assertion failed but not which part of the component lifecycle produced the failure. Playwright traces with `page.mark()` annotations show exactly when in the timeline each Arrange/Act/Assert step occurred — making debugging faster and the TDD cycle more transparent in recorded trace reviews.

**[community] `page.mark()` is most valuable for TDD sessions shared across teams.** When a test case fails in CI and a team member needs to diagnose the issue, a Playwright trace with explicit `page.mark('ARRANGE: ...')` / `page.mark('ASSERT: ...')` annotations communicates the TDD intent directly in the trace timeline — no need to cross-reference test code and trace events manually.

---

### Vitest 4.1 Browser Mode — ARIA Snapshot TDD for Accessibility Contracts [community]

Vitest 4.1 adds ARIA snapshot testing to Browser Mode — `toMatchAriaSnapshot()` and `toMatchAriaInlineSnapshot()`. These matchers assert against the **accessibility tree** (what screen readers see), not the DOM or visual output. In TDD, this enables an entirely new Red test category: the failing test case specifies the required accessibility contract of a component _before_ the component exists.

ARIA snapshots are particularly powerful for TypeScript component libraries where the accessibility contract is part of the public API specification. The test case defines the expected tree structure (roles, labels, states), the component must satisfy it to go Green, and any accessibility regression breaks the contract test during Refactor.

```typescript
// vitest.config.ts — Browser Mode with ARIA snapshot support (Vitest 4.1)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      provider: { name: 'playwright' },
      name: 'chromium',
    },
  },
});
```

```typescript
// navigation.browser.test.ts — ARIA snapshot TDD for a navigation component
import { page } from '@vitest/browser/context';
import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { SiteNav } from './SiteNav.js';

// ---- RED: write the accessibility contract before any implementation ----
// The inline snapshot is the specification — it will fail because SiteNav does not exist yet.
describe('SiteNav accessibility contract', () => {
  it('exposes the expected landmark structure to screen readers', async () => {
    render(<SiteNav links={[
      { label: 'Home',    href: '/' },
      { label: 'About',  href: '/about' },
      { label: 'Contact', href: '/contact' },
    ]} />);

    // toMatchAriaInlineSnapshot: snapshot stored inline (great for TDD — spec is right next to the test)
    await expect.element(page.getByRole('navigation')).toMatchAriaInlineSnapshot(`
      - navigation "Site navigation":
        - link "Home"
        - link "About"
        - link "Contact"
    `);
    // RED: fails because SiteNav doesn't exist yet.
    // GREEN: implement SiteNav with a <nav aria-label="Site navigation"> and proper link elements.
    // The snapshot IS the accessibility specification.
  });

  // Test case 2: RED — active link communicates state to screen readers
  it('marks the current page link with aria-current', async () => {
    render(<SiteNav
      links={[
        { label: 'Home',  href: '/' },
        { label: 'About', href: '/about' },
      ]}
      currentPath="/about"
    />);

    await expect.element(page.getByRole('navigation')).toMatchAriaInlineSnapshot(`
      - navigation "Site navigation":
        - link "Home"
        - link "About" [aria-current=page]
    `);
    // RED: forces implementation to set aria-current="page" on the active link.
    // Without TDD, aria-current is the first thing skipped under deadline pressure.
  });
});
```

```typescript
// form.browser.test.ts — toMatchAriaSnapshot with file-based snapshots
// Use toMatchAriaSnapshot (not Inline) for complex forms — file-based snapshots
// are easier to review in PRs and can be updated with --update-snapshots.
import { page } from '@vitest/browser/context';
import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { RegistrationForm } from './RegistrationForm.js';

describe('RegistrationForm accessibility', () => {
  it('has a complete and labelled form structure', async () => {
    render(<RegistrationForm />);

    const form = page.getByRole('form', { name: 'Create account' });
    // Snapshot stored in __snapshots__/form.browser.test.ts.snap
    await expect.element(form).toMatchAriaSnapshot();
    // First run: creates the snapshot (Red → Green automatically).
    // Subsequent runs: fails if accessibility structure regresses.
    // Update with: npx vitest --browser --update-snapshots
  });

  // Test case: verify error states are accessible
  it('announces field validation errors to screen readers', async () => {
    const { getByRole } = render(<RegistrationForm />);
    // Trigger validation by submitting empty form
    getByRole('button', { name: 'Submit' }).click();

    // Inline snapshot specifying the error-state accessibility tree
    await expect.element(page.getByRole('form')).toMatchAriaInlineSnapshot(`
      - form "Create account":
        - textbox "Email" [invalid]:
          - "Email is required" [role=alert]
        - textbox "Password" [invalid]:
          - "Password is required" [role=alert]
        - button "Submit"
    `);
    // RED: forces the implementation to:
    // 1. Use aria-invalid on invalid fields
    // 2. Render role=alert error messages associated with their inputs
    // Without TDD, alert associations are the first omission in form implementations.
  });
});
```

**Why ARIA snapshot TDD matters for TypeScript component libraries:**

1. **Accessibility as a first-class contract:** The ARIA snapshot IS the failing test specification — not a documentation comment, not a linting rule, but a failing Red test that forces accessibility implementation before the component can go Green.
2. **Regression detection at the contract level:** Visual regression tests (`toMatchScreenshot`) catch pixel-level changes; ARIA snapshot tests catch semantic regressions — a button that becomes a div, a label that loses its association, a live region that stops being announced.
3. **TypeScript prop contract alignment:** When a TypeScript prop `currentPath?: string` is added, a new ARIA snapshot test case should be written first that specifies how the accessibility tree changes when `currentPath` is set. The type change and the accessibility contract change are driven by the same TDD cycle.

**Inline vs. file-based ARIA snapshots — TDD guidance:**

| Approach | When to use | TDD phase | 
|----------|-------------|-----------|
| `toMatchAriaInlineSnapshot(...)` | New components, specifying contract upfront | Write the snapshot as the Red specification |
| `toMatchAriaInlineSnapshot()` (empty) | Discovering the accessibility tree of existing code | Run once to generate, then review and commit |
| `toMatchAriaSnapshot()` (file-based) | Complex components with large trees, updated via `--update-snapshots` | Red = first run creates baseline; regression = any change to the tree |

**[community] ARIA snapshot TDD surfaces accessibility defects that linting tools miss.** Axe and accessibility linters check rule compliance; ARIA snapshots check _structural contract_ — whether the semantic relationships between elements match the intended user experience. A missing `aria-label` on a navigation landmark, an icon button without a name, or a missing `aria-describedby` link between an error and its field are all caught by the ARIA snapshot but not necessarily by Axe alone.

---

### Type-Level TDD with `expectTypeOf` and `*.test-d.ts` Files [community]

TypeScript's type system is itself a specification layer. Type-Level TDD applies the Red→Green→Refactor cycle to type contracts: you write a failing _type-level_ test case that specifies how a function's types should behave, then implement the types to make it pass. Vitest provides `expectTypeOf` for this purpose in dedicated `*.test-d.ts` files.

This is distinct from runtime TDD: type-level test cases run at compile time only (no JavaScript execution), and their "Red" phase is a TypeScript compile error, not a test assertion failure. Vitest integrates `*.test-d.ts` files into the standard `vitest typecheck` pipeline, producing type errors as test failures in the same output as runtime test cases.

**When to apply type-level TDD:**
- Designing generic utility types (`Result<T, E>`, `DeepPartial<T>`, `Prettify<T>`)
- Specifying discriminated union narrowing behaviour
- Verifying that forbidden type combinations are rejected at compile time
- TDD'ing TypeScript declaration files (`.d.ts`) for published libraries

```typescript
// result.test-d.ts — type-level TDD for the Result<T, E> generic type
// Run with: npx vitest typecheck --watch
import { expectTypeOf, describe, it } from 'vitest';
import { ok, err, Result } from './result.js';

describe('Result<T, E> type contract', () => {
  // ---- RED (type-level): ok() must return Result<T, never> when E is not provided ----
  it('infers the success type from the ok() argument', () => {
    const result = ok(42);
    // Type-level assertion: result must be typed as Result<number, never>
    expectTypeOf(result).toEqualTypeOf<Result<number, never>>();
    // RED: fails if ok() infers Result<unknown, unknown> or widens to Result<any, any>
  });

  // ---- RED (type-level): err() must narrow the error type ----
  it('infers the error type from the err() argument', () => {
    const result = err('validation-failed');
    expectTypeOf(result).toEqualTypeOf<Result<never, string>>();
  });

  // ---- RED (type-level): .map() must preserve the error type ----
  it('.map() transforms the value type while preserving the error type', () => {
    const result: Result<number, string> = ok(21);
    const mapped = result.map(n => n * 2);
    // map() must produce Result<number, string> — not Result<number, unknown>
    expectTypeOf(mapped).toEqualTypeOf<Result<number, string>>();
  });

  // ---- RED (type-level): narrowing after success check must reveal .value ----
  it('narrows to { success: true; value: T } inside a success guard', () => {
    const result: Result<string, Error> = ok('hello');
    if (result.success) {
      // Inside the guard, .value must be string (not string | undefined)
      expectTypeOf(result.value).toEqualTypeOf<string>();
      // .error must not exist on the success branch
      expectTypeOf(result).not.toHaveProperty('error');
    }
  });

  // ---- RED (type-level): forbidden usage — accessing .value on unnarrowed result ----
  it('does NOT expose .value on an unnarrowed Result', () => {
    const result: Result<string, Error> = ok('hello');
    // This must be a compile error — .value is only safe after narrowing
    // @ts-expect-error — accessing .value without checking .success first
    const _unsafe = result.value;
    // If @ts-expect-error is NOT triggered, the type is too permissive (a compile error here = Red)
    // If @ts-expect-error IS triggered, the type correctly blocks unsafe access (Green)
  });
});
```

**How `@ts-expect-error` enables Red type-level tests:**

`@ts-expect-error` is the type-level equivalent of a Red test: it asserts that the next line _must_ produce a TypeScript error. If the line does NOT produce an error (because the type is too permissive), TypeScript reports `"Unused '@ts-expect-error' directive"` — which Vitest typecheck treats as a failing test case. This is the type-level Red signal.

```typescript
// type-guards.test-d.ts — testing that forbidden combinations are rejected
import { expectTypeOf, it } from 'vitest';
import { parseTemperature, TemperatureUnit } from './temperature.js';

it('rejects invalid temperature units at the type level', () => {
  // ---- RED (type-level): 'kelvin' should NOT be a valid TemperatureUnit ----
  // @ts-expect-error — 'kelvin' is not assignable to TemperatureUnit
  parseTemperature(100, 'kelvin');
  // If this @ts-expect-error is NOT triggered, TemperatureUnit is too wide (e.g., string).
  // GREEN: TemperatureUnit = 'celsius' | 'fahrenheit' narrows the type correctly.
});

it('accepts valid temperature units at the type level', () => {
  // ---- These must NOT produce TypeScript errors ----
  const celsius = parseTemperature(100, 'celsius');
  const fahrenheit = parseTemperature(212, 'fahrenheit');
  expectTypeOf(celsius).toEqualTypeOf<number>();
  expectTypeOf(fahrenheit).toEqualTypeOf<number>();
});
```

```typescript
// generic-constraints.test-d.ts — type-level TDD for generic utility types

// RED: specify the DeepReadonly<T> type contract before implementation
import { expectTypeOf, describe, it } from 'vitest';
import { DeepReadonly } from './types.js';

interface MutableCart {
  items:  Array<{ sku: string; qty: number }>;
  total:  number;
  meta:   { createdAt: Date };
}

describe('DeepReadonly<T>', () => {
  it('makes top-level properties readonly', () => {
    type ReadonlyCart = DeepReadonly<MutableCart>;
    // top-level: total must be readonly
    expectTypeOf<ReadonlyCart['total']>().toEqualTypeOf<number>();
    // The property itself must not be assignable — verified with @ts-expect-error:
    type _Test = { readonly x: DeepReadonly<MutableCart>['total'] };
    // TypeScript enforces readonly at the property level, not the value type level.
    // Use type-level assignment tests for full coverage.
  });

  it('makes nested properties readonly', () => {
    type ReadonlyCart = DeepReadonly<MutableCart>;
    // Nested: items elements must also be readonly
    expectTypeOf<ReadonlyCart['items'][number]['sku']>().toEqualTypeOf<string>();
    // The key test: the element type must be Readonly (no mutation allowed)
    type ReadonlyItem = ReadonlyCart['items'][number];
    // @ts-expect-error — sku is deeply readonly; assignment must be rejected
    const _: { sku: string } = {} as ReadonlyItem & { sku: string };
  });
});
```

**Vitest configuration for type-level TDD:**

```typescript
// vitest.config.ts — enable typecheck for *.test-d.ts files
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    typecheck: {
      enabled: true,
      tsconfig: './tsconfig.json',   // Same strict tsconfig as production
      include: ['src/**/*.test-d.ts'],
      // Run tsc separately — typecheck: true adds overhead to the watch loop
      // Recommendation: enable in CI, run manually locally with `vitest typecheck`
    },

    // Runtime test cases (separate from type tests)
    include: ['src/**/*.test.ts'],
  },
});
```

```bash
# Type-level TDD watch loop (separate from runtime tests)
# Fastest: only type-check the specific .test-d.ts file being developed
npx vitest typecheck --watch src/domain/result/result.test-d.ts

# Full typecheck pass (CI)
npx vitest typecheck run

# Combined: type tests + runtime tests (recommended for CI)
npx vitest run && npx vitest typecheck run
```

**Type-Level TDD vs. `tsc --noEmit`:**

| Approach | What it catches | When to use |
|----------|----------------|-------------|
| `tsc --noEmit` | Any compile error in any `.ts` file | CI gate: all files must compile |
| `vitest typecheck` on `*.test-d.ts` | Specific type contract violations | TDD cycle for generic types and discriminated union APIs |
| `@ts-expect-error` in test files | Types that _must_ be rejected | Specifying forbidden type combinations as Red tests |
| `expectTypeOf(...).toEqualTypeOf<T>()` | Exact type shape assertions | Specifying the exact inferred type of a function result |

**[community] Type-level TDD is most valuable when publishing TypeScript libraries.** For libraries where the TypeScript API surface IS the product — `Result<T, E>`, `EventBus<Events>`, `Repository<T>` — type-level test cases in `*.test-d.ts` files are the TDD test cases for the library's public contract. A type regression (widening `Result<T, never>` to `Result<T, unknown>`) is caught by the Red type test before a consuming team discovers it at runtime.

**[community] `expectTypeOf` is stricter than `satisfies`.** Where `satisfies` validates that a value conforms to a shape, `expectTypeOf().toEqualTypeOf<T>()` requires the types to be structurally identical — no widening, no extra properties. This matters in TDD because `satisfies` passes when a type is a subtype of `T`, while `toEqualTypeOf` catches when a function returns `string | number` when you specified `string`. Use `toEqualTypeOf` for contract-level type precision and `satisfies` for fixture construction.

---

### Real-World Gotchas [community] — Additions (iter 20)

33. **[community] Native Node.js type-stripping (`--experimental-strip-types`) breaks tests that use `const enum`.** TypeScript's `const enum` declarations are not erasable — they emit JavaScript at compile time. When tests run via Node.js native stripping (Vitest 4.1 `runner: 'node'` or direct `--experimental-strip-types`), any file that imports a `const enum` (directly or transitively) will fail at runtime with `Cannot find name 'MyEnum'`. This is not a TDD principle violation but a sharp migration edge. The TDD test suite will catch this instantly — on the first Red→Green cycle using native execution mode, `const enum` usages will throw. The fix: replace `const enum` with `as const` objects (`export const Direction = { Up: 'Up', Down: 'Down' } as const`), which are erasable. If `const enum` is in a third-party library, enable `verbatimModuleSyntax` and use type-only imports from that library. Enabling `erasableSyntaxOnly: true` in `tsconfig.json` will surface these issues at compile time before runtime — making the Red phase (compile error) come first, as TDD requires.

34. **[community] "The Way of TDD" reveals that most teams practise test-first, not TDD.** The critical distinction — verified through team assessment exercises at Google — is the Refactor phase. When teams are asked to show their last 10 TDD commits, teams practising genuine TDD show a commit pattern of small Green commits followed by Refactor commits that change no observable behaviour. Teams practising test-first (calling it TDD) show only Green commits — the Refactor is either absent or bundled into the next feature. The diagnostic is simple: check git log for commits that contain only test rewrites or type tightening with no new test cases. If those commits are missing, the team is doing test-first, not TDD. Neither is wrong — but knowing the difference prevents false conclusions about "TDD not working" when it was never being practised.

35. **[community] Browser Mode TDD test cases that skip `await` on `expect.element()` assertions produce silent false greens in Vitest 4.1.** Vitest Browser Mode uses Playwright's auto-wait mechanics: `expect.element(locator).toBeVisible()` waits for the element to appear before asserting. When developers omit `await` — writing `expect.element(btn).toBeVisible()` instead of `await expect.element(btn).toBeVisible()` — the assertion returns a Promise that is never awaited. The test case passes immediately (the Promise is truthy), regardless of whether the element is actually visible. Vitest 4.1's TypeScript types return `Promise<void>` from Browser Mode assertions, but `noFloatingPromises` from `typescript-eslint` does not run inside `.test.ts` files by default. The fix: add `"@typescript-eslint/no-floating-promises": "error"` to the ESLint config applied to test files. Vitest 4.1's `--detect-async-leaks` will not catch this — unawaited `expect.element()` does not leave a timer; it leaves a silently-resolved Promise. Only `no-floating-promises` lint rule catches it at authoring time.

---

---

### Vitest 4.1 — `viteModuleRunner: false` and Production-Closer Test Execution [community]

Vitest 4.1 introduces an experimental `viteModuleRunner: false` option (distinct from the `runner: 'node'` approach documented above) that disables Vite's module runner sandbox entirely, running tests with native Node.js module imports. Where `runner: 'node'` uses Vitest's own lightweight runner, `viteModuleRunner: false` uses the full Node.js Module Loader API for `vi.mock` and `vi.hoisted` support — meaning mocking still works without needing to rebuild mock infrastructure.

**Key distinction from `runner: 'node'`:**

| Aspect | `runner: 'node'` (Experimental) | `viteModuleRunner: false` (Experimental) |
|--------|----------------------------------|------------------------------------------|
| Vite module transforms | Bypassed | Bypassed |
| `vi.mock()` support | Limited | Yes (Node 22.15+ Module Loader API) |
| `vi.hoisted()` support | Limited | Yes |
| Path aliases (`@domain/*`) | Not supported | Not supported |
| `import.meta.env` | Not supported | Not supported |
| Istanbul coverage | Not supported | Not supported |
| Minimum Node.js version | 23.6+ | 22.15+ |
| TypeScript syntax | Erasable only | Erasable only |
| Recommended for | Pure domain modules | Domain + mocked-dependency modules |

```typescript
// vitest.config.ts — viteModuleRunner: false for production-closer test execution
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Disables Vite module runner sandbox — tests run with native Node.js imports.
    // Requires Node.js 22.15+ for vi.mock/vi.hoisted via Module Loader API.
    // TypeScript files must use erasable syntax (no enum, no parameter properties).
    viteModuleRunner: false,

    // viteModuleRunner: false is best scoped to domain modules via projects config:
    projects: [
      {
        name: 'domain-native',
        viteModuleRunner: false,
        include: ['src/domain/**/*.test.ts'],
        reporter: ['verbose'],
        bail: 1,
      },
      {
        name: 'standard',
        include: [
          'src/ui/**/*.test.ts',
          'src/infrastructure/**/*.test.ts',
        ],
        // Standard Vite module runner for Vite-dependent code
      },
    ],
  },
});
```

```typescript
// With viteModuleRunner: false, vi.mock() works via Node's Module Loader API:
// order-service.test.ts
import { describe, it, expect, vi } from 'vitest';
import { OrderService } from './OrderService.js';

// vi.mock still works under viteModuleRunner: false (Node 22.15+)
vi.mock('./mailer.js', () => ({
  send: vi.fn<[{ to: string; subject: string }], Promise<void>>(),
}));

import * as mailer from './mailer.js';

describe('OrderService', () => {
  it('sends a confirmation email on order creation', async () => {
    const service = new OrderService();
    await service.createOrder({ userId: 'u1', items: [] });

    expect(vi.mocked(mailer.send)).toHaveBeenCalledWith(
      expect.objectContaining({ subject: expect.stringContaining('confirmed') })
    );
  });
});
```

**TDD impact of `viteModuleRunner: false`:** Tests run in an environment that more closely matches the production Node.js runtime, surfacing environment-specific defects (module evaluation order, side effects on import, `require()` vs ESM behaviour differences) during the TDD cycle rather than after deployment. The tradeoff is losing Vite plugins, path aliases, and `import.meta.env` — making it most suitable for pure domain modules without build-time transforms.

**[community] `viteModuleRunner: false` catches a production class of defect that standard Vitest cannot.** Teams that migrated to this mode found test cases that passed under Vite's module runner but failed at runtime because Vite was silently resolving circular module dependencies in a different order than Node.js. These circular dependency defects were invisible until the first production deployment.

---

### Vitest 4.1 — `onCleanup()` Fixture Teardown Callback [community]

Vitest 4.1 extends `test.extend()` with an `onCleanup()` callback inside fixture definitions. Unlike the generator-based teardown (code after `await use(value)`) or `afterEach` hooks, `onCleanup()` allows registering teardown logic at any point during fixture setup — including conditionally, based on what resources were actually created.

This is particularly valuable for typed TDD fixtures that conditionally establish connections or start services: with `onCleanup()`, cleanup is co-located with the allocation decision, not separated into a yield-continuation.

```typescript
// typed-fixtures.ts — Vitest 4.1 onCleanup() for conditional resource management
import { test, expect } from 'vitest';
import { InMemoryDatabase } from './test-doubles/InMemoryDatabase.js';
import { NotificationService } from './NotificationService.js';
import { SpyNotificationService } from './test-doubles/SpyNotificationService.js';

interface TestContext {
  db: InMemoryDatabase;
  notifier: SpyNotificationService;
}

// Vitest 4.1: onCleanup() registers teardown at allocation time, not at yield
const domainTest = test.extend<TestContext>({
  db: async ({}, use, onCleanup) => {
    const db = new InMemoryDatabase();
    await db.connect();

    // Register cleanup immediately after allocation — guaranteed to run even if
    // subsequent setup steps throw (unlike yield-based teardown which only runs
    // if the yield point is reached)
    onCleanup(async () => {
      await db.dispose();
    });

    await use(db);
    // No teardown code needed here — onCleanup handles it
  },

  notifier: async ({}, use, onCleanup) => {
    const spy = new SpyNotificationService();

    // Conditional cleanup: only restore if spy was configured
    if (process.env.NOTIFY_SPY_MODE === 'strict') {
      onCleanup(() => {
        // Verify no unexpected notifications were sent during the test case
        spy.assertNoUnexpectedCalls();
        spy.reset();
      });
    } else {
      onCleanup(() => spy.reset());
    }

    await use(spy);
  },
});

// Test cases receive fully managed fixtures — cleanup is guaranteed
domainTest('creates an order and notifies the user', async ({ db, notifier }) => {
  const service = new OrderService(db, notifier);

  await service.createOrder({ userId: 'u1', items: [{ sku: 'A', qty: 1 }] });

  expect(notifier.sent).toHaveLength(1);
  expect(notifier.sent[0].userId).toBe('u1');
  // db.dispose() and notifier.reset() called automatically via onCleanup
});

domainTest('returns null for an order that does not exist', async ({ db }) => {
  const service = new OrderService(db);
  const result = await service.findOrder('nonexistent');
  expect(result).toBeNull();
  // db.dispose() called — even though this test case never wrote to db
});
```

**Why `onCleanup()` improves TDD fixture reliability:**

1. **Allocation-site co-location:** Cleanup is registered where the resource is created, not in a separate `afterEach` or yield continuation. Code reviewers see the cleanup when they review the allocation.

2. **Multi-step fixture safety:** In generator-based fixtures (`async function*`), if an intermediate setup step throws before the `yield`, teardown code after the `yield` never runs. With `onCleanup()`, each allocation registers its own cleanup independently — even if the fixture partially fails, already-registered cleanups still run.

3. **Conditional cleanup:** Resources conditionally created (based on test configuration or test mode) can register cleanup only when they are actually created — preventing "cleanup ran but resource was never created" errors.

**[community] `onCleanup()` is the recommended teardown pattern when a fixture creates multiple resources in sequence.** If `resource B` depends on `resource A` and creation of `B` fails, generator-based teardown skips the code after `yield` — meaning `A` is leaked. With `onCleanup()`, `A` registers its cleanup immediately after creation, so even if `B` throws, `A` is properly disposed.

---

### Vitest 4.1 — Chai-Style Mock Assertions [community]

Vitest 4.1 adds Chai-style fluent assertions for mock functions, complementing the existing `expect(mock).toHaveBeenCalled()` style. In TDD test cases, the Chai-style reads more naturally in assertion chains and is familiar to developers who have used Sinon.js or older Chai/Sinon setups.

```typescript
// Vitest 4.1: Chai-style mock assertions in TDD test cases
import { describe, it, expect, vi } from 'vitest';
import { OrderService } from './OrderService.js';

interface PaymentGateway {
  charge(amount: number, currency: string): Promise<{ transactionId: string }>;
  refund(transactionId: string): Promise<void>;
}

describe('OrderService.checkout', () => {
  it('charges the payment gateway for the order total', async () => {
    const gateway: PaymentGateway = {
      charge: vi.fn<[number, string], Promise<{ transactionId: string }>>()
        .mockResolvedValue({ transactionId: 'txn-001' }),
      refund: vi.fn<[string], Promise<void>>().mockResolvedValue(undefined),
    };
    const service = new OrderService(gateway);

    await service.checkout({ orderId: 'ORD-1', total: 75.00, currency: 'USD' });

    // Vitest 4.1 Chai-style — reads fluently in a TDD assertion chain
    expect(gateway.charge).to.have.been.calledOnce();
    expect(gateway.charge).to.have.been.calledWith(75.00, 'USD');
    expect(gateway.refund).to.not.have.been.called();
  });

  it('refunds when order is cancelled after charge', async () => {
    const gateway: PaymentGateway = {
      charge: vi.fn<[number, string], Promise<{ transactionId: string }>>()
        .mockResolvedValue({ transactionId: 'txn-002' }),
      refund: vi.fn<[string], Promise<void>>().mockResolvedValue(undefined),
    };
    const service = new OrderService(gateway);

    await service.checkout({ orderId: 'ORD-2', total: 50.00, currency: 'EUR' });
    await service.cancelOrder('ORD-2');

    // Chai-style callCount assertion
    expect(gateway.charge).to.have.callCount(1);
    expect(gateway.refund).to.have.been.calledWith('txn-002');

    // Equivalent Vitest-style assertions — both syntaxes are valid in Vitest 4.1:
    // expect(gateway.charge).toHaveBeenCalledOnce();
    // expect(gateway.refund).toHaveBeenCalledWith('txn-002');
  });
});
```

**Available Chai-style mock assertions (Vitest 4.1):**

| Chai style | Vitest equivalent | Notes |
|-----------|-------------------|-------|
| `.to.have.been.called()` | `.toHaveBeenCalled()` | Any call, any args |
| `.to.have.been.calledOnce()` | `.toHaveBeenCalledOnce()` | Exactly once |
| `.to.have.been.calledWith(...)` | `.toHaveBeenCalledWith(...)` | With specific args |
| `.to.have.callCount(n)` | `.toHaveBeenCalledTimes(n)` | Exactly n times |
| `.to.have.returned` | `.toHaveReturned()` | Returned without throwing |
| `.not.to.have.been.called()` | `.not.toHaveBeenCalled()` | Was never called |

**[community] Chai-style assertions are most useful when onboarding test-after developers into TDD.** Teams migrating from Mocha/Chai setups often resist Vitest specifically because of unfamiliar assertion syntax. Vitest 4.1's Chai-style assertions remove this friction — developers familiar with `.to.have.been.calledOnce()` from Sinon+Chai can read and write TDD test cases without relearning the assertion vocabulary. Long-term, standardising on one style per codebase (either Chai or Vitest-style, not both) prevents readability confusion.

---

### TypeScript 6.0 — Improved `this`-less Function Context-Sensitivity [community]

TypeScript 6.0 reduces context-sensitivity on functions that do not use `this`. Previously, a method-syntax function in an object literal was context-sensitive — TypeScript deferred its type inference based on the surrounding object type, even if `this` was never used. In TypeScript 6.0, method-syntax functions without `this` are treated like arrow functions for inference purposes.

**TDD impact:** Object literals used as test doubles (typed stubs, inline fakes) now infer parameter types more reliably from the surrounding interface, reducing the need for explicit type annotations in test code.

```typescript
// TypeScript 5.x: context-sensitivity required explicit type annotation
interface Processor {
  process(items: string[]): Promise<number[]>;
  validate(item: string, index: number): boolean;
}

// BEFORE TypeScript 6.0: parameter types not inferred from interface
const stubProcessor = {
  process: async (items) => items.map(Number),   // ❌ items: any — not inferred
  validate: (item, index) => item.length > 0,    // ❌ item: any — not inferred
} satisfies Processor;

// AFTER TypeScript 6.0: context-sensitivity reduced — types inferred from satisfies
const stubProcessor = {
  process: async (items) => items.map(Number),   // ✅ items: string[] — inferred
  validate: (item, index) => item.length > 0,    // ✅ item: string, index: number — inferred
} satisfies Processor;
```

```typescript
// TDD test case — TypeScript 6.0 reduces annotation noise in inline test doubles
import { describe, it, expect } from 'vitest';
import { ReportBuilder } from './ReportBuilder.js';

interface DataSource {
  fetchRows(query: string): Promise<Record<string, unknown>[]>;
  close(): Promise<void>;
}

describe('ReportBuilder', () => {
  it('builds a report from fetched rows', async () => {
    // TypeScript 6.0: parameter types inferred from DataSource interface
    // No explicit `: string` or `: Promise<...>` needed on the method params
    const stubSource = {
      fetchRows: async (query) => [          // query: string — inferred
        { id: '1', value: 'alpha' },
        { id: '2', value: 'beta' },
      ],
      close: async () => {},                 // return type Promise<void> — inferred
    } satisfies DataSource;

    const builder = new ReportBuilder(stubSource);
    const report = await builder.build('SELECT * FROM items');

    expect(report.rowCount).toBe(2);
    expect(report.rows[0].value).toBe('alpha');
  });
});
```

**Why this matters for TDD:** In TypeScript 5.x, creating inline test stubs often required explicitly annotating callback parameters to avoid `any` inference. With TypeScript 6.0, using `satisfies Interface` on an inline object now infers all method parameter types from the interface. This reduces annotation boilerplate in test Arrange phases, keeping the test case body focused on the behaviour specification rather than type scaffolding.

**[community] TypeScript 6.0 `this`-less inference improvement most benefits teams that use `satisfies` for typed inline fakes.** If your test doubles are written as `const fake = { ... } satisfies MyInterface`, upgrading to TypeScript 6.0 will silently fix inferred `any` parameters in those fakes — which previously required explicit annotations. After upgrading, run `tsc --noEmit` and look for newly surfaced errors: they represent places where the previously-`any`-typed parameter was receiving wrong-shaped data that TypeScript now catches correctly.

---

### TypeScript 5.9 `--module node20` — Stable Node.js 20 Module Semantics [community]

TypeScript 5.9 introduced `--module node20` as a stable alternative to `--module nodenext`. The key distinction for TDD projects:

- `--module nodenext` tracks the latest Node.js module semantics and may receive new behaviors as Node.js evolves. It implies `--target esnext`.
- `--module node20` is frozen to Node.js 20 module semantics and will not receive new behaviors. It implies `--target es2023`.

For TDD projects with Node.js 20.x LTS targets, `--module node20` provides a stable compilation target that will not silently change behavior when new Node.js module features are added to `nodenext`.

```jsonc
// tsconfig.json — using node20 for a Node.js 20 LTS project
{
  "compilerOptions": {
    "module": "node20",        // ← frozen to Node.js 20 semantics; implies target es2023
    "moduleResolution": "node20",
    "strict": true,
    "types": ["node", "vitest/globals"],  // Required in TS 6.0+
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "isolatedModules": true
  }
}
```

**TDD benefit:** Teams running Node.js 20 LTS in production can use `--module node20` and be confident that the TypeScript module semantics match the production runtime exactly — eliminating a category of "works in tests, fails in production" module resolution discrepancy. Vitest uses esbuild by default, which respects the `module` option for type-checking; using `node20` prevents accidental use of module features only available in Node.js 22+.

**When to use `nodenext` vs `node20`:**

| Use `node20` | Use `nodenext` |
|---|---|
| Production target is Node.js 20.x LTS | Always targeting the latest Node.js |
| Stable semantics required; no surprise changes | OK accepting new Node.js module features automatically |
| Team wants explicit LTS version contract | Using Node.js canary/nightly |
| `--target es2023` is acceptable | Need `--target esnext` |

**[community] Many TypeScript projects use `nodenext` by default without realising it tracks the moving target of the latest Node.js module features.** For production systems that pin to Node.js 20 LTS, `--module node20` is the semantically correct choice. A TDD test suite compiled with `nodenext` may exercise module patterns that resolve differently on the Node.js 20 LTS runtime in production — `--module node20` closes this gap.

---

### TypeScript 7.0 Preparation — `--stableTypeOrdering` as a TDD Migration Tool [community]

TypeScript 6.0 introduced `--stableTypeOrdering`, a migration diagnostic flag that makes union type ordering deterministic, matching the behavior planned for TypeScript 7.0. Teams can enable it today to surface type ordering regressions that will become permanent errors in 7.0.

**Why it matters for TDD:** TDD test cases that use `toMatchObject` or `toEqual` with complex union types may have been relying on non-deterministic type ordering — producing test failures that appear intermittently in CI, not in local runs. `--stableTypeOrdering` makes these ordering issues visible at compile time, before they become runtime test instability.

```typescript
// Example of type ordering issue caught by --stableTypeOrdering
// Before TS 7.0: union ordering is non-deterministic
type ApiResponse = 
  | { status: 'success'; data: User[] }
  | { status: 'error'; code: number }
  | { status: 'pending' };

// TDD test case that may produce non-deterministic CI failures:
it('returns success response with users', async () => {
  const response = await getUsersApi();
  // toMatchObject with a union type — union ordering affected TypeScript's
  // error messages and, in some edge cases, type narrowing for discriminated unions
  expect(response).toMatchObject({ status: 'success' });
  if (response.status === 'success') {
    expect(response.data).toHaveLength(2);
  }
});
```

```jsonc
// tsconfig.json — enable stableTypeOrdering to detect TS 7.0 regressions now
{
  "compilerOptions": {
    "stableTypeOrdering": true,
    // WARNING: may add up to 25% compiler overhead — use as diagnostic tool,
    // not in CI on every build. Enable locally before TS 7.0 upgrade.
    
    // All other TDD-recommended options:
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "types": ["node", "vitest/globals"]
  }
}
```

**TDD preparation checklist for TypeScript 7.0:**

1. Enable `--stableTypeOrdering` locally and run `tsc --noEmit` — fix any new errors.
2. Run the full test suite with `--stableTypeOrdering` enabled — non-deterministic test failures will now be consistent, making them diagnosable.
3. Review any test cases that assert on TypeScript error messages or type shapes from `tsd` or `expect-type` — they may have relied on union ordering.
4. Migrate away from deprecated TypeScript 6.0 options (`baseUrl`, `moduleResolution: "node"`) — TypeScript 7.0 removes them entirely.
5. Use `"ignoreDeprecations": "6.0"` as a temporary escape hatch during migration to TypeScript 7.0, not as a permanent solution.

**[community] Teams that run type-level tests (`tsd`, `expect-type`, or `dtslint`) are most exposed to `--stableTypeOrdering` breakage.** Union type ordering changes can alter the selected overload in overloaded functions and the displayed type in type-level assertions. Running `--stableTypeOrdering` before the TypeScript 7.0 release gives teams months to find and fix these before they become mandatory breaking changes.

---

### Real-World Gotchas [community] — Additions (iter 21)

36. **[community] Vitest 4.1 broke `beforeAll`/`afterAll`/`aroundAll` hooks that relied on the first argument being `Suite`.** In previous Vitest versions, the `beforeAll` and `afterAll` hooks received an undocumented `Suite` object as their first argument. In Vitest 4.1, these hooks now receive the fixture context instead. Any hook that destructured the first argument expecting `Suite` properties (e.g., `.tasks`, `.name`) will silently receive an empty fixture context object instead — not throwing an error, but silently ignoring the hook's logic. This is a breaking change with no TypeScript compile-time signal: the first argument is typed as an empty generic context, and the `Suite` properties were never in the type definition. The fix: remove any `Suite`-dependent logic from `beforeAll`/`afterAll` hooks. Use `describe.each` or `test.extend()` fixture contexts for suite-level shared state instead.

37. **[community] `viteModuleRunner: false` with `vi.mock()` requires Node.js 22.15+, not just 22.x.** Teams upgrading to use `viteModuleRunner: false` in Vitest 4.1 and running `vi.mock()` calls may encounter `vi.mock is not supported in this context` errors when running on Node.js 22.0–22.14. The Module Loader API required for `vi.mock()` interception under `viteModuleRunner: false` was backported to Node.js 22.15.0 LTS. Projects pinned to Node.js 22.x without a patch-level minimum will silently fail in some CI environments that run on earlier 22.x patch versions. The fix: pin `"node": ">=22.15"` in `package.json`'s `engines` field and update CI `setup-node@v4` to `node-version: '22.15'` or newer. A TDD test case that runs `vi.mock()` under `viteModuleRunner: false` on Node 22.0 will throw at setup time, not at the assertion — making the failure message look like a Vitest configuration error rather than a Node.js version issue.

---

### Real-World Gotchas [community] — Additions (iter 22)

38. **[community] ARIA snapshot tests break when updated via `--update-snapshots` without a design review.** Vitest's ARIA snapshot workflow (`toMatchAriaSnapshot`) uses the same `--update-snapshots` flag as visual snapshots and jest snapshots. Teams that run `--update-snapshots` reflexively when any snapshot test fails will silently accept accessibility regressions — a missing `aria-label`, a demoted heading level, a live region that no longer fires. The TDD discipline for ARIA snapshots: treat them as accessibility contracts, not disposable baselines. Update them only when the accessibility structure is intentionally redesigned — the same threshold you would apply to a breaking interface change. Before running `--update-snapshots` on an ARIA snapshot, review the diff: does the tree change represent an intentional accessibility improvement, or does it represent a regression being silently accepted?

39. **[community] `expectTypeOf(...).toEqualTypeOf<T>()` in `*.test-d.ts` files fails silently on TypeScript type cache mismatches.** When running `vitest typecheck --watch`, TypeScript's incremental compilation cache sometimes serves stale type information — causing a type test to report Green even though the type has regressed. The symptom: a `*.test-d.ts` test case passes locally but fails in CI (which runs without the incremental cache). The root cause is `tsBuildInfoFile` incremental caching not invalidating correctly when a dependent file changes. The fix: for `vitest typecheck` in CI, always pass `--force` to disable incremental compilation: `npx vitest typecheck run --typecheck.ignoreSourceErrors`. For local TDD sessions, this is generally not an issue — but teams should be aware that type-level TDD has a different cache invalidation surface than runtime TDD, and a Green type test in a stale watch session is not a guarantee. Run `npx tsc --noEmit --incremental false` as a CI gate alongside `vitest typecheck`.

---

### TypeScript 6.0 — `baseUrl` Deprecation and `#/` Subpath Imports for TDD Path Aliases [community]

TypeScript 6.0 deprecates `baseUrl` as a module resolution root and introduces `#/` subpath import syntax. Both changes affect how TDD projects configure path aliases for clean test imports (e.g., `@domain/Cart` instead of `../../../domain/Cart`).

#### `baseUrl` is Deprecated — Migrate Test Path Aliases to `paths`

The `baseUrl` option in `compilerOptions` was widely used to enable bare-specifier imports like `import { Cart } from 'domain/Cart'`. In TypeScript 6.0, `baseUrl` no longer serves as a module resolution root and is fully removed in TypeScript 7.0. Teams that relied on `baseUrl` for test imports must migrate to explicit `paths` mappings.

```jsonc
// ❌ DEPRECATED in TypeScript 6.0 — baseUrl-relative imports fail in TS 7.0
{
  "compilerOptions": {
    "baseUrl": "./src",         // ← deprecated; no longer a resolution root in TS 6.0
    "paths": {
      "@domain/*": ["domain/*"],  // ← relative to baseUrl — will break in TS 7.0
      "@test-doubles/*": ["test-doubles/*"]
    }
  }
}

// ✅ CORRECT in TypeScript 6.0+ — all paths relative to tsconfig directory
{
  "compilerOptions": {
    // No baseUrl — paths use full relative paths from tsconfig location
    "paths": {
      "@domain/*":        ["./src/domain/*"],
      "@test-doubles/*":  ["./src/test-doubles/*"],
      "@fixtures/*":      ["./src/__fixtures__/*"]
    }
  }
}
```

**TDD impact of `baseUrl` deprecation:** Most TDD guides (including earlier iterations of this document) showed `paths` entries relative to a `baseUrl`. Teams using these examples must update their `tsconfig.json` **before** upgrading to TypeScript 6.0. The failure mode after upgrading without this fix: `Cannot find module '@domain/Cart'` errors in every test file that uses path aliases — not a TypeScript compile error (because `paths` still works), but a runtime `Cannot find module` error from the module resolver when `baseUrl`-relative paths no longer resolve.

**Migration one-liner:** In the `paths` object, prepend `./src/` to every right-hand side entry that was previously relative to `baseUrl: "./src"`.

#### `#/` Subpath Import Syntax — Node.js-Native Alias Alternative

TypeScript 6.0 adds support for Node.js's `#/` subpath import syntax. Where `@/` path aliases require a bundler or `vite-tsconfig-paths`, the `#/` syntax is a Node.js-native standard — importable without any transpilation layer, making it ideal for Vitest's native Node.js execution mode (`runner: 'node'` or `viteModuleRunner: false`).

```json
// package.json — declare #/ subpath imports (no tsconfig paths needed)
{
  "name": "my-service",
  "type": "module",
  "imports": {
    "#domain/*": "./src/domain/*.js",
    "#test-doubles/*": "./src/test-doubles/*.js",
    "#fixtures/*": "./src/__fixtures__/*.js"
  }
}
```

```jsonc
// tsconfig.json — TypeScript 6.0 supports #/ resolution automatically
// No paths entry needed — TypeScript reads the "imports" field from package.json
{
  "compilerOptions": {
    "module": "nodenext",       // or "node20" — required for package.json imports support
    "moduleResolution": "nodenext"
  }
}
```

```typescript
// TDD test file — #/ imports resolved by Node.js natively, no bundler needed
import { ShoppingCart } from '#domain/ShoppingCart.js';
import { InMemoryCartRepository } from '#test-doubles/InMemoryCartRepository.js';

describe('ShoppingCart', () => {
  it('starts empty', () => {
    const repo = new InMemoryCartRepository();
    const cart = new ShoppingCart(repo);
    expect(cart.total()).toBe(0);
  });
});
```

**Why `#/` subpath imports improve TDD ergonomics with native Node.js execution:**

| Approach | Requires bundler/plugin | Works with `runner: 'node'` | Works with `viteModuleRunner: false` | TypeScript 6.0+ |
|---|---|---|---|---|
| `@/` via `vite-tsconfig-paths` | Yes (Vite plugin) | No | No | Yes |
| `paths` in tsconfig + tsconfigPaths | Yes (Vite plugin or `tsconfig-paths`) | No | No | Yes |
| `#/` via package.json `imports` | No | Yes | Yes | Yes (TS 6.0+) |

**[community] Teams migrating to Vitest `runner: 'node'` for ultra-fast TDD loops often discover that `@/` path aliases stop resolving** — because `vite-tsconfig-paths` only works when Vite is active. `#/` subpath imports solve this: they are resolved by Node.js's own module system, working identically in Vite-based tests, `runner: 'node'` tests, and direct `node --experimental-strip-types` execution.

**`--moduleResolution bundler` + `--module commonjs` (TypeScript 6.0):** Teams on CommonJS codebases that were blocked from using `--moduleResolution bundler` (which previously required ESM module syntax) can now combine `"module": "commonjs"` with `"moduleResolution": "bundler"` in TypeScript 6.0. This is the recommended migration path for CJS projects moving away from the deprecated `--moduleResolution node` (node10), and it removes a barrier for TDD teams using Vitest on CommonJS codebases who wanted bundler-style path resolution without switching to ESM.

---

### Vitest 4.1 — Coverage Ignore Comments with `@preserve` for esbuild [community]

Vitest 4.1 documents a critical requirement for coverage ignore comments when using esbuild as the TypeScript transpiler (the default in Vitest): the `@preserve` annotation must be included to prevent esbuild from stripping the comment before the coverage instrumentation reads it.

Without `@preserve`, coverage ignore directives silently fail — esbuild removes the comment during transpilation, the coverage instrumentation never sees the ignore directive, and the "ignored" code appears as uncovered in the report. This causes false TDD coverage gaps that mislead the team about untested branches.

```typescript
// ❌ WITHOUT @preserve — comment stripped by esbuild before coverage sees it
// These directives are silently ignored in Vitest's esbuild pipeline:
/* v8 ignore next */
/* istanbul ignore next */
/* v8 ignore start */
/* istanbul ignore start */

// ✅ WITH @preserve — esbuild retains the comment; coverage instrumentation reads it
/* v8 ignore next -- @preserve */
function unreachableErrorBranch(err: unknown): never {
  // This branch is intentionally untestable (defensive catch in a hot path)
  throw new Error(`Unexpected error: ${String(err)}`);
}

/* v8 ignore start -- @preserve */
// Entire block excluded from coverage (e.g., platform-specific boot code)
if (process.platform === 'win32' && process.env.NODE_ENV !== 'test') {
  setupWindowsSpecificHandlers();
}
/* v8 ignore stop -- @preserve */

// Multi-file exclusion: exclude an entire file from coverage reporting
/* v8 ignore file -- @preserve */
```

**Both v8 and Istanbul provider formats require `@preserve` in Vitest esbuild pipelines:**

```typescript
// vitest.coverage.ts — correct usage patterns for both providers
// v8 provider (default):
/* v8 ignore next -- @preserve */
/* v8 ignore start -- @preserve */
/* v8 ignore stop -- @preserve */
/* v8 ignore file -- @preserve */

// Istanbul provider:
/* istanbul ignore next -- @preserve */
/* istanbul ignore if -- @preserve */
/* istanbul ignore else -- @preserve */
/* istanbul ignore start -- @preserve */
/* istanbul ignore stop -- @preserve */
```

**TDD use cases for coverage ignore comments:**

1. **Defensive error branches:** Catch blocks that handle errors the test suite cannot reliably trigger (OS-level failures, hardware errors). Ignoring them prevents them from appearing as TDD coverage gaps when the branch is genuinely untestable.

2. **Platform-specific code:** `process.platform === 'win32'` branches that only run on Windows when tests run on Linux CI.

3. **Development-only stubs:** Code that only runs outside `NODE_ENV === 'test'` — using `/* v8 ignore file */` to exclude entire development scaffolding files from coverage reporting.

**[community] The most common TDD coverage ignore mistake is relying on bare `/* v8 ignore next */` without `@preserve` in a Vitest + esbuild project.** The directive appears to work locally if the developer uses `tsc` for a type check, but fails silently in the Vitest watch loop. The first signal is coverage reporting a lower-than-expected line count after "ignoring" a branch — the ignore had no effect. Add `@preserve` to all coverage ignore comments as a team-wide standard, regardless of whether esbuild is the current transpiler, because it is harmless when not needed and essential when it is.

---

### Real-World Gotchas [community] — Additions (iter 23)

40. **[community] TypeScript 6.0 `noUncheckedSideEffectImports` is now on by default — TDD test setup files that import non-existent matchers will immediately error after upgrading.** In TypeScript 5.x, this option was opt-in and most projects did not enable it. After upgrading to TypeScript 6.0, any test file with a side-effect import to a path that does not exist — `import './test-doubles/matchers.js'` when the file was renamed or deleted — immediately produces a compile error rather than silently running with the matcher extension missing. This is the correct behaviour (it was a defect before), but teams will encounter it as a surprising post-upgrade failure: the test suite was passing (because the unresolved import was silently skipped), and after the upgrade it now fails to compile. The fix is the same as before: correct the import path. Teams can temporarily opt out with `"noUncheckedSideEffectImports": false` in `tsconfig.json` during migration, but the correct long-term response is fixing the broken imports.

41. **[community] `baseUrl`-relative `paths` entries stop resolving after TypeScript 6.0 upgrade.** Teams whose `tsconfig.json` contains `"baseUrl": "./src"` and `paths` entries like `"@domain/*": ["domain/*"]` (relative to `baseUrl`) will find that all `@domain/*` imports fail to resolve after upgrading to TypeScript 6.0 — because `baseUrl` no longer serves as the resolution root. The TypeScript error is `Cannot find module '@domain/Cart' or its corresponding type declarations`, which appears in every test file that uses the alias. The fix is a mechanical one-line change per `paths` entry: replace relative-to-baseUrl paths with paths relative to the `tsconfig.json` directory. For a project with `baseUrl: "./src"` and a path entry `"@domain/*": ["domain/*"]`, the updated entry is `"@domain/*": ["./src/domain/*"]`. Run `tsc --noEmit` after the change to verify all imports resolve. A TDD test suite that exercises every module via its path alias will make this exhaustive immediately — every failing test case points to a broken alias entry.

42. **[community] Coverage ignore comments without `@preserve` create phantom TDD coverage gaps that misdirect refactoring effort.** A TypeScript team running Vitest with the default esbuild transpiler may add `/* v8 ignore next */` to a defensive error branch, expect it to disappear from the coverage report, and then observe that their coverage drops (because the ignore was silently discarded by esbuild). The team responds by writing an otherwise-unnecessary test case to cover the unreachable branch — adding test ceremony for code that was correctly identified as untestable. The root cause: missing `@preserve` in the ignore comment. The fix is trivial (`-- @preserve`), but the symptom — "my coverage ignore comments don't work" — is confusing enough that teams often write unnecessary tests rather than diagnose the comment stripping. Add `-- @preserve` to every coverage ignore comment and enforce it via a `grep` or custom ESLint rule in the CI pipeline.

---

### Vitest 3.2 — Scoped Fixtures for TDD Infrastructure [community]

Vitest 3.2 added `scope` support to `test.extend()` fixtures, allowing fixture teardown and initialisation to be tied to either the **file** (suite-level, equivalent to `beforeAll`/`afterAll`) or the **worker** (once per worker process, across all files). This solves a long-standing TDD infrastructure problem: the choice between recreating expensive shared resources per test case (slow) versus using global setup that is not type-safe (fragile).

Before scoped fixtures, TDD teams either paid the cost of re-establishing a database connection in each test case's fixture, or used `beforeAll`/`afterAll` directly — which is not type-safe and not tied to whether the fixture is actually used in a given test.

```typescript
// vitest.config.ts — configure pool threads for worker-scope fixtures
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Worker-scoped fixtures require pool: 'threads' and pool.useAtomics or similar
    // Each worker process sees its own instance of the worker-scoped fixture
    pool: 'threads',
    poolOptions: { threads: { isolate: false } }, // required for worker-scope to be meaningful
  },
});
```

```typescript
// fixtures/database.ts — scoped fixtures for TDD database infrastructure
import { test as baseTest } from 'vitest';
import type { TestDatabase } from '../test-doubles/TestDatabase.js';
import { createTestDatabase } from '../test-doubles/TestDatabase.js';

interface DatabaseFixtures {
  db: TestDatabase;
}

// File-scoped fixture: one DB instance shared across all test cases in a single file
// Initialises only if the fixture is actually used in that file
export const test = baseTest.extend<DatabaseFixtures>({
  db: [
    async ({}, use) => {
      // Runs once per file (like beforeAll) — but only if any test in the file uses `db`
      const database = await createTestDatabase();
      await database.migrate(); // run migrations once
      await use(database);
      await database.close(); // runs once per file (like afterAll)
    },
    { scope: 'file' }, // ← Vitest 3.2+: 'file' | 'worker'
  ],
});

// Worker-scoped fixture: one DB instance shared across all files on this worker thread
// Use this for very expensive initialisation (e.g., starting a Postgres container)
export const testWithWorkerDb = baseTest.extend<DatabaseFixtures>({
  db: [
    async ({}, use) => {
      // Runs once per worker — survives across multiple test files processed by the same worker
      const database = await createTestDatabase({ persistent: true });
      await use(database);
      await database.close();
    },
    { scope: 'worker' }, // ← Vitest 3.2+: shared across test files on the same worker
  ],
});
```

```typescript
// orderService.test.ts — TDD test cases using file-scoped db fixture
import { describe, expect } from 'vitest';
import { test } from '../fixtures/database.js'; // ← custom test with scoped fixtures

// `db` is initialised once per file, not once per test case
// Each test case starts with a fresh transaction (via beforeEach) but shares the connection

describe('OrderService', () => {
  test('creates an order in the database', async ({ db }) => {
    const service = new OrderService(db);
    const order = await service.createOrder({ userId: 'user-1', items: [] });
    expect(order.id).toBeDefined();
    const found = await db.findOrderById(order.id);
    expect(found).not.toBeNull();
  });

  test('throws for a non-existent user', async ({ db }) => {
    const service = new OrderService(db);
    await expect(service.createOrder({ userId: 'ghost', items: [] }))
      .rejects.toThrow('User not found');
  });
  // ← db.close() is called once after all tests in this file complete, not after each test
});
```

**When to use each scope for TDD:**

| Scope | Initialises | Disposes | Best for |
|-------|------------|----------|----------|
| *(default, per-test)* | Before each test case | After each test case | Small, fast fakes (in-memory repos, spy instances) |
| `scope: 'file'` | Once per file (if used) | After last test in file | DB connections, HTTP servers — shared per suite |
| `scope: 'worker'` | Once per worker | When worker exits | Postgres containers, expensive services — shared across files |

**TDD implication:** File-scoped fixtures produce the same isolation characteristics as `beforeAll`/`afterAll`, but with a critical advantage: the fixture only runs if a test in the file actually requests it. Teams that moved from `beforeAll` to `scope: 'file'` fixtures reported a measurable reduction in cold-start times for test files that do not need a database connection — because the DB was no longer initialised just because it was in the `beforeAll` of a shared setup file.

---

### Real-World Gotchas [community] — Additions (iter 24)

43. **[community] Vitest `Assertion<R>` module augmentation breaks in Vitest 3.2+ when using `expect.to*` (static-style) assertions.** The older pattern for typing custom matchers — `declare module 'vitest' { interface Assertion<R = unknown> { ... } }` — only covers `expect(value).toXxx()` (instance-style assertions). In Vitest 3.2, `expect.toXxx(value)` (static-style assertions, sometimes used in pipeline-style fluent APIs or for type-narrowing contexts) requires the `Matchers` interface. If your team adopts both assertion styles and only augments `Assertion<R>`, the static-style calls will silently fall back to `any`, losing type safety. The fix: migrate to the unified `Matchers<T>` declaration (introduced in Vitest 3.2) which covers both styles in a single interface extension. In TDD test suites, this surface matters most in custom test utilities that call `expect.toBeSuccessResult(result)` directly rather than chaining — a pattern that becomes more common as teams extract fluent assertion helpers.

44. **[community] Worker-scoped fixtures with `isolate: false` break per-test state isolation — causing TDD test case ordering dependencies.** When using `scope: 'worker'` fixtures with `poolOptions: { threads: { isolate: false } }`, the fixture's in-memory state persists between test files processed by the same worker. If the fixture object (e.g., an in-memory database fake) carries mutable state across test files without an explicit reset, test cases in the second file may inherit state left by the first file's test cases. The TDD symptom: a test case passes in isolation but fails when the full suite runs — the classic ordering-dependent failure. The fix: ensure worker-scoped fixtures expose a `reset()` method and call it in a `beforeEach` hook, or use `scope: 'file'` instead of `scope: 'worker'` for any fixture that holds mutable TDD state. Reserve `scope: 'worker'` for truly stateless infrastructure (e.g., a read-only reference database, a compiled WASM module).

45. **[community] `vi.spyOn` with `using` in Vitest 3.2+ must not be mixed with `afterEach(() => vi.restoreAllMocks())` — double restoration silently fails.** When a team migrates from `afterEach(() => vi.restoreAllMocks())` to `using spy = vi.spyOn(...)`, leaving the old `afterEach` in place causes double restoration. The first disposal (the `using` scope exit) calls `mockRestore()`, resetting the spy. The second restoration (the `afterEach`) then attempts to restore an already-restored spy — which is a no-op in Vitest but can produce confusing state if the spy was on a prototype method that gets called between disposal and the `afterEach`. The correct migration: replace `afterEach(() => vi.restoreAllMocks())` with `using` declarations on individual spies, or keep the `afterEach` as a safety net but accept that it double-restores. Do not mix the two patterns in the same test file without being aware that `vi.restoreAllMocks()` is now a no-op for spies already cleaned up by `using`.

---

### TypeScript 6.0 — Temporal API TDD: Clock Injection Pattern [community]

TypeScript 6.0 ships built-in types for the stage-4 `Temporal` API (available via `--target esnext` or `"lib": ["esnext"]`). Teams migrating date/time logic from `new Date()` to `Temporal.Now.instant()` or `Temporal.Now.plainDateTimeISO()` encounter a new TDD challenge: `Temporal.Now` is a global singleton and cannot be spied on via `vi.spyOn` in the same way that `Date.now` can be faked with `vi.useFakeTimers()`. Vitest's fake timer support does not yet control `Temporal.Now` (as of Vitest 4.1).

The correct TDD approach is **Clock Injection**: define a `Clock` interface that abstracts over `Temporal.Now`, inject it into domain classes, and supply a `FakeClock` in test cases. This is the same pattern used for `Date` abstraction before `vi.useFakeTimers()` existed — and it produces cleaner domain code regardless of which time API is used.

```typescript
// clock.ts — Clock interface abstracting Temporal.Now (TypeScript 6.0 built-in types)
import type { Temporal } from 'temporal-polyfill'; // or '@js-temporal/polyfill' pre-TS 6.0 es2025

// In TypeScript 6.0 with "lib": ["esnext"], Temporal is globally available:
export interface Clock {
  now(): Temporal.Instant;
  today(): Temporal.PlainDate;
  nowInZone(timeZone: string): Temporal.ZonedDateTime;
}

// SystemClock.ts — production implementation wrapping Temporal.Now
export class SystemClock implements Clock {
  now(): Temporal.Instant {
    return Temporal.Now.instant();
  }

  today(): Temporal.PlainDate {
    return Temporal.Now.plainDateISO();
  }

  nowInZone(timeZone: string): Temporal.ZonedDateTime {
    return Temporal.Now.zonedDateTimeISO(timeZone);
  }
}

// FakeClock.ts — test double for TDD; controls the "current time"
export class FakeClock implements Clock {
  #instant: Temporal.Instant;

  constructor(isoString: string = '2026-01-15T10:00:00Z') {
    this.#instant = Temporal.Instant.from(isoString);
  }

  now(): Temporal.Instant {
    return this.#instant;
  }

  today(): Temporal.PlainDate {
    return this.#instant.toZonedDateTimeISO('UTC').toPlainDate();
  }

  nowInZone(timeZone: string): Temporal.ZonedDateTime {
    return this.#instant.toZonedDateTimeISO(timeZone);
  }

  /** TDD helper: advance the fake clock by a duration */
  advance(duration: Temporal.DurationLike): void {
    this.#instant = this.#instant.add(duration);
  }

  /** TDD helper: set an absolute point in time */
  setTo(isoString: string): void {
    this.#instant = Temporal.Instant.from(isoString);
  }
}
```

```typescript
// subscription-service.test.ts — TDD with FakeClock and Temporal types
import { describe, it, expect, beforeEach } from 'vitest';
import { SubscriptionService } from './SubscriptionService.js';
import { FakeClock } from '../test-doubles/FakeClock.js';

describe('SubscriptionService', () => {
  let clock: FakeClock;
  let service: SubscriptionService;

  beforeEach(() => {
    // RED: clock starts at a fixed point; test is deterministic regardless of wall time
    clock = new FakeClock('2026-01-15T00:00:00Z');
    service = new SubscriptionService(clock);
  });

  it('marks a subscription as expired when past the end date', () => {
    const sub = service.create({ startISO: '2026-01-01', durationDays: 30 });
    // Subscription expires on 2026-01-31

    clock.advance({ days: 31 }); // now = 2026-02-15
    expect(service.isExpired(sub.id)).toBe(true);
  });

  it('marks a subscription as active on the last day', () => {
    const sub = service.create({ startISO: '2026-01-01', durationDays: 30 });

    clock.advance({ days: 30 }); // now = 2026-02-14 — still within window
    expect(service.isExpired(sub.id)).toBe(false);
  });

  it('throws when a subscription start date is in the future', () => {
    // RED: drives the validation rule — future starts must be rejected
    expect(() => service.create({ startISO: '2026-12-01', durationDays: 30 }))
      .toThrow('Subscription start date cannot be in the future');
  });
});
```

```typescript
// SubscriptionService.ts — GREEN: injected Clock drives all temporal logic
import type { Clock } from './clock.js';
import type { Temporal } from 'temporal-polyfill';

interface Subscription {
  id: string;
  start: Temporal.PlainDate;
  end: Temporal.PlainDate;
}

export class SubscriptionService {
  readonly #clock: Clock;
  readonly #subs = new Map<string, Subscription>();

  constructor(clock: Clock) {
    this.#clock = clock;
  }

  create(input: { startISO: string; durationDays: number }): Subscription {
    const start = Temporal.PlainDate.from(input.startISO);
    const today = this.#clock.today();

    if (Temporal.PlainDate.compare(start, today) > 0) {
      throw new Error('Subscription start date cannot be in the future');
    }

    const end = start.add({ days: input.durationDays });
    const id = crypto.randomUUID();
    const sub: Subscription = { id, start, end };
    this.#subs.set(id, sub);
    return sub;
  }

  isExpired(id: string): boolean {
    const sub = this.#subs.get(id);
    if (!sub) throw new Error(`Unknown subscription: ${id}`);
    const today = this.#clock.today();
    return Temporal.PlainDate.compare(today, sub.end) > 0;
  }
}
```

**Why inject a `Clock` interface instead of using `vi.setSystemTime()` with `Temporal`:**

| Approach | Works with Temporal.Now | Type-safe | No Vitest internals | Design pressure |
|----------|------------------------|-----------|---------------------|-----------------|
| `vi.useFakeTimers()` | No (Vitest 4.1) | N/A | Yes | None |
| `vi.spyOn(Temporal.Now, 'instant')` | Possible but fragile | Yes | Yes | None |
| **Clock injection (recommended)** | Yes | Yes | Yes | Forces explicit dependency |

**[community] The most common Temporal TDD mistake is reaching for `vi.spyOn(Temporal.Now, 'instant')` as a shortcut.** While `vi.spyOn` can intercept `Temporal.Now.instant`, it creates a global mutation that leaks across tests unless carefully restored, and it does not cover every `Temporal.Now.*` method. The Clock interface injection approach is four extra lines of production code and produces universally testable, deterministic temporal logic — the correct TDD trade-off.

---

### Vitest 3.2 — Per-Test `AbortSignal` for Cancellation-Aware TDD [community]

Vitest 3.2 added an `AbortSignal` to each test case's context (`ctx.signal`). The signal is aborted when the test case times out or is cancelled (e.g., by `bail: 1` stopping the suite). This enables TDD for cancellation-aware code — domain logic that should react to in-flight request cancellation — without needing a separate fake signal factory.

```typescript
// order-search.test.ts — TDD for cancellation-aware domain logic
import { describe, it, expect } from 'vitest';
import { searchOrders } from './OrderSearch.js';
import { InMemoryOrderIndex } from '../test-doubles/InMemoryOrderIndex.js';

describe('OrderSearch', () => {
  it('returns results for a valid query', async (ctx) => {
    const index = new InMemoryOrderIndex([
      { id: 'ORD-1', description: 'blue widget' },
      { id: 'ORD-2', description: 'red gadget' },
    ]);

    // ctx.signal is live — not yet aborted at this point
    const results = await searchOrders('blue', index, ctx.signal);
    expect(results).toHaveLength(1);
    expect(results[0].id).toBe('ORD-1');
  });

  it('aborts the search when the signal fires', async (ctx) => {
    const index = new InMemoryOrderIndex([]);

    // Simulate cancellation by creating an already-aborted signal
    const controller = new AbortController();
    controller.abort(new DOMException('User cancelled', 'AbortError'));

    await expect(searchOrders('anything', index, controller.signal))
      .rejects.toThrow('User cancelled');
  });

  it('propagates the test timeout signal to long-running operations', async (ctx) => {
    // Use ctx.signal directly — it will be aborted if the test times out
    // This TDD pattern ensures the production code honours AbortSignal correctly
    const index = new SlowOrderIndex(delayMs: 100);
    const results = await searchOrders('widget', index, ctx.signal);
    expect(results.length).toBeGreaterThanOrEqual(0);
  }, { timeout: 500 }); // test-level timeout; ctx.signal fires if exceeded
});
```

```typescript
// OrderSearch.ts — GREEN: production code that honours AbortSignal
export async function searchOrders(
  query: string,
  index: OrderIndex,
  signal: AbortSignal
): Promise<Order[]> {
  signal.throwIfAborted(); // Temporal fast-fail at entry point
  const results = await index.search(query, { signal });
  signal.throwIfAborted(); // Check again after await — signal may have fired
  return results;
}
```

**TDD use cases for `ctx.signal`:**

1. **Cancellation-aware domain logic:** Pass `ctx.signal` directly to the function under test to verify it propagates the signal to collaborators — no need to create a separate `AbortController` in most test cases.

2. **Timeout-driven cancellation testing:** Set a short `timeout` on a test case and pass `ctx.signal` to the implementation. If the implementation does not honour the signal, the test harness times out rather than hanging indefinitely — surfacing the missing cancellation handling as a test failure rather than a CI timeout.

3. **Streaming / async iterator tests:** Pass `ctx.signal` to an async generator under test to verify it stops producing values on cancellation.

```typescript
// async-iterator TDD: verify generator respects cancellation
it('stops producing events when the signal is aborted', async (ctx) => {
  const emitter = new OrderEventEmitter();
  const events: string[] = [];
  const controller = new AbortController();

  // Start consuming; cancel after 3 events
  for await (const event of emitter.stream(controller.signal)) {
    events.push(event.type);
    if (events.length === 3) controller.abort();
  }

  expect(events).toHaveLength(3);
  // If stream() did not honour the signal, the loop would never exit
});
```

**[community] Before `ctx.signal` was available in Vitest 3.2, teams passed `new AbortController().signal` directly or used `vi.fn()` stubs for the signal parameter.** The `ctx.signal` approach is superior for timeout-driven cancellation tests because it is automatically wired to Vitest's internal test lifecycle: if the test times out, the signal fires, the test fails with a timeout error, and any outstanding async work can clean up via the signal. Teams using the old manual `AbortController` pattern had to manually synchronise the controller lifetime with the `afterEach` hook.

---

### Vitest 4.1 — `test.extend()` Builder Pattern for Type-Inferred Fixtures [community]

Vitest 4.1 introduces a chainable builder pattern for `test.extend()` that automatically infers fixture types from return values — eliminating the need to declare a generic type interface manually. In TDD, this reduces the annotation overhead in test setup code and keeps fixture types always in sync with their implementations.

**The previous object-syntax form** required manually declaring a generic interface:

```typescript
// ❌ Old object syntax — requires manual type declaration (verbose, can drift)
interface MyFixtures {
  repo: InMemoryUserRepository;
  service: UserService;
}

const userTest = test.extend<MyFixtures>({
  repo: async ({}, use) => {
    const r = new InMemoryUserRepository();
    await use(r);
  },
  service: async ({ repo }, use) => {
    await use(new UserService(repo));
  },
});
```

**The new builder pattern** chains `.extend()` calls and infers types automatically:

```typescript
// ✅ Vitest 4.1 builder pattern — types inferred, no manual interface needed
// fixtures.ts
import { test as baseTest } from 'vitest';
import { InMemoryUserRepository } from './test-doubles/InMemoryUserRepository.js';
import { InMemoryMailer } from './test-doubles/InMemoryMailer.js';
import { UserService } from './UserService.js';

export const userTest = baseTest
  // Fixture 1: inline value — type inferred as { maxPageSize: number }
  .extend('config', { maxPageSize: 20 })

  // Fixture 2: sync factory — type inferred as InMemoryUserRepository
  .extend('repo', () => new InMemoryUserRepository())

  // Fixture 3: async factory with cleanup — type inferred as InMemoryMailer
  .extend('mailer', { scope: 'file' }, async ({}, { onCleanup }) => {
    const m = new InMemoryMailer();
    onCleanup(() => m.reset());
    return m;
  })

  // Fixture 4: uses previous fixtures — type of repo/mailer inferred from above
  .extend('service', ({ repo, mailer }) => new UserService(repo, mailer));

// Usage: all fixture types are TypeScript-inferred — no interface required
// userTest.ts
userTest('creates a user and sends welcome email', async ({ service, mailer }) => {
  // `service` is UserService, `mailer` is InMemoryMailer — inferred, not declared
  await service.register({ email: 'alice@example.com', name: 'Alice' });

  expect(mailer.sent).toHaveLength(1);
  expect(mailer.sent[0]).toMatchObject({ to: 'alice@example.com', subject: 'Welcome!' });
});

userTest('uses config fixture for pagination', async ({ service, config }) => {
  // `config.maxPageSize` is number — inferred from the inline value above
  const page = await service.listUsers({ page: 1, pageSize: config.maxPageSize });
  expect(page.items.length).toBeLessThanOrEqual(config.maxPageSize);
});
```

**Builder pattern scope and cleanup options:**

```typescript
// Scoped and cleanup-aware fixtures in the builder chain
export const dbTest = baseTest
  // File-scoped: one DB connection per test file (like beforeAll/afterAll)
  .extend('db', { scope: 'file' }, async ({}, { onCleanup }) => {
    const db = await createTestDatabase();
    onCleanup(() => db.close());
    return db;
  })

  // Per-test transaction: each test case gets its own transaction, rolled back after
  .extend('tx', async ({ db }, { onCleanup }) => {
    const tx = await db.beginTransaction();
    onCleanup(() => tx.rollback());
    return tx;
  });

// Type-safe test case — `tx` is typed from the return value of db.beginTransaction()
dbTest('inserts a row and reads it back within a transaction', async ({ tx }) => {
  await tx.insert('orders', { id: 'ORD-1', status: 'pending' });
  const row = await tx.findById('orders', 'ORD-1');
  expect(row?.status).toBe('pending');
  // tx.rollback() called automatically — DB unchanged after test case
});
```

**Why the builder pattern improves TDD:** When using the object syntax, a TypeScript interface must be manually maintained alongside the fixture implementations. When a fixture's return type changes (e.g., a repository gains a new method), the interface must be updated separately — and TypeScript will not catch a divergence between the interface and the implementation. With the builder pattern, the type flows directly from the factory's return value: if `InMemoryUserRepository` gains a new method, the test fixture's type automatically includes it on the next TypeScript check. This closes the "type definition diverges from fake implementation" class of TDD drift.

**[community] The builder pattern is the recommended approach for new TDD test suites.** The object syntax remains supported for backward compatibility and for Playwright-compatible fixture patterns that require the `use()` callback form. For TypeScript-native Vitest projects, prefer the builder pattern: it eliminates the generic interface boilerplate that the object syntax requires, reducing the maintenance surface for test infrastructure.

---

### Vitest 3.2 — `context.annotate()` for Diagnostic Test Attachments [community]

Vitest 3.2 added `context.annotate()`, an API for attaching custom messages, links, and file attachments to test cases. In TDD, this provides a structured way to attach diagnostic information — API response bodies, DOM snapshots, log excerpts — to failing test cases without printing them to stdout, keeping the terminal output clean while preserving evidence in reporters (JUnit XML, HTML, GitHub Actions).

Unlike `console.log` or `console.error` which always print and pollute the TDD watch loop output, `context.annotate()` only surfaces in reporters when requested — making it a low-noise diagnostic tool compatible with the tight TDD feedback loop.

```typescript
// order-service.test.ts — annotate() for rich failure context
import { describe, it, expect } from 'vitest';
import { OrderService } from './OrderService.js';
import { InMemoryOrderRepository } from './test-doubles/InMemoryOrderRepository.js';

describe('OrderService.checkout', () => {
  // Test case: RED — annotate attaches response body on assertion failure
  it('returns a confirmed order response', async (ctx) => {
    const repo = new InMemoryOrderRepository();
    const service = new OrderService(repo);

    const result = await service.checkout({
      userId: 'u1',
      items: [{ sku: 'WIDGET-A', qty: 2, price: 49.99 }],
    });

    // Attach the full result for diagnostics — surfaced in CI reporter on failure
    // Does NOT print to terminal during normal TDD watch runs
    await ctx.annotate(`checkout result: ${JSON.stringify(result, null, 2)}`);

    expect(result.status).toBe('confirmed');
    expect(result.total).toBeCloseTo(99.98);
  });

  // Test case: attaching a warning-level annotation for known flakiness context
  it('handles concurrent checkouts without double-charging', async (ctx) => {
    const repo = new InMemoryOrderRepository();
    const service = new OrderService(repo);

    // Attach context about the concurrency scenario being tested
    await ctx.annotate(
      'Concurrent checkout test: two simultaneous requests for the same cart',
      'notice'
    );

    const [r1, r2] = await Promise.allSettled([
      service.checkout({ userId: 'u2', items: [{ sku: 'A', qty: 1, price: 10 }] }),
      service.checkout({ userId: 'u2', items: [{ sku: 'A', qty: 1, price: 10 }] }),
    ]);

    const successes = [r1, r2].filter(r => r.status === 'fulfilled').length;
    expect(successes).toBe(1); // exactly one checkout succeeds
  });
});
```

**Annotation types:**

| Type | When to use |
|------|-------------|
| *(default / no type)* | Informational — available in reports, silent during watch |
| `'notice'` | Contextual notes about the test case scenario |
| `'warning'` | Known flakiness, environment assumptions |
| `'error'` | Additional error context attached before a failing assertion |

**Attaching file content (e.g., HTML snapshots for UI tests):**

```typescript
// browser.test.ts — annotate with DOM snapshot on failure
import { describe, it, expect } from 'vitest';
import { page } from '@vitest/browser/context';

describe('CheckoutPage', () => {
  it('shows the order confirmation banner', async (ctx) => {
    await page.goto('/checkout/confirm?orderId=ORD-1');
    const banner = page.getByRole('status', { name: /confirmed/i });

    // Attach the page HTML for CI debugging — only visible in HTML/JUnit reports
    const html = await page.content();
    await ctx.annotate('page HTML at assertion time', {
      contentType: 'text/html',
      body: html,
      bodyEncoding: 'utf-8',
    });

    await expect.element(banner).toBeVisible();
  });
});
```

**`context.annotate()` in the Vitest report pipeline:**

Annotations flow into the `onTestAnnotate` reporter hook and appear in:
- **Vitest HTML reporter** — as expandable panels on test case results
- **JUnit XML reporter** — as `<properties>` elements on test cases (viewable in CI dashboards)
- **GitHub Actions reporter** — as step annotations in the PR checks UI
- **TAP reporter** — as YAML directives

**Why this matters for TDD:** During the Red phase, a failing test case often needs more context than the assertion failure message provides — particularly for integration test cases that produce complex responses. Adding `ctx.annotate()` at the Arrange→Act boundary (before the assertion) means that when the test goes Red in CI, the full response or diagnostic context is attached to the test result without bloating the terminal output during the local TDD watch loop.

**[community] `context.annotate()` resolves the "debug log hygiene" problem in TDD test suites.** Teams that use `console.log` for diagnostic output in tests must remember to remove those statements before committing — they pollute the TDD terminal output. `ctx.annotate()` is the structured alternative: diagnostic output that is always present in reports but invisible in the terminal watch output. This enables permanent diagnostic annotations in test cases without disrupting the TDD Red→Green feedback signal.

---

### Vitest 3.2 — `sequence.groupOrder` for Ordered Multi-Project TDD Pipelines [community]

Vitest 3.2 adds `sequence.groupOrder` to the project configuration, enabling multi-project test suites to define explicit execution groups that run sequentially. In TDD, this matters when a suite has multiple test layers — domain unit tests, integration tests, and E2E tests — that have ordering dependencies: integration tests should not run before domain tests have passed, and E2E tests should not run before integration tests are green.

Without `sequence.groupOrder`, multi-project Vitest configurations run all projects in parallel by default. This can produce misleading CI failures where E2E tests fail because the domain model is not correctly implemented yet — obscuring the real Red signal.

```typescript
// vitest.config.ts — sequence.groupOrder for TDD pipeline ordering
import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    projects: [
      {
        // Group 1: fast domain unit tests — run first, stop immediately on failure
        name: 'unit',
        include: ['src/domain/**/*.test.ts'],
        sequence: { groupOrder: 1 },  // ← Vitest 3.2+: runs before group 2 and 3
        bail: 1,
        reporter: ['verbose'],
        tags: ['unit'],
      },
      {
        // Group 2: integration tests — run only after unit group passes
        name: 'integration',
        include: ['src/**/*.integration.test.ts'],
        sequence: { groupOrder: 2 },  // ← runs after group 1 is complete
        bail: 0,  // integration: collect all failures for CI visibility
        tags: ['integration'],
      },
      {
        // Group 3: E2E tests — run only after integration group passes
        name: 'e2e',
        include: ['e2e/**/*.test.ts'],
        sequence: { groupOrder: 3 },  // ← runs after group 2 is complete
        browser: {
          enabled: true,
          provider: { name: 'playwright' },
          name: 'chromium',
        },
        tags: ['e2e'],
      },
    ],
    reporter: process.env.CI === 'true'
      ? ['verbose', 'github-actions', 'junit']
      : ['verbose'],
    outputFile: process.env.CI === 'true' ? './test-results/junit.xml' : undefined,
    coverage: {
      enabled: process.env.CI === 'true',
      provider: 'v8',
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/*.integration.test.ts', 'src/**/test-doubles/**'],
      thresholds: { branches: 80, functions: 85, lines: 85 },
    },
  },
});
```

**How `sequence.groupOrder` affects TDD CI flow:**

Without `groupOrder`: all three project groups run in parallel. A domain bug produces three simultaneous failure sets — unit, integration, and E2E — creating confusing CI output where the root cause (a failing domain test case) is buried under downstream failures.

With `groupOrder`: if the unit group (group 1) fails, groups 2 and 3 are skipped. The CI output shows exactly one failing layer, and the root-cause TDD test case is immediately visible.

```bash
# CI output with sequence.groupOrder — clean Red signal:
# ✓ Group 1 (unit): 47 passed
# ✓ Group 2 (integration): 12 passed
# ✗ Group 3 (e2e): 2 failed — checkout flow does not complete on Safari

# vs. without groupOrder — confusing parallel failures:
# ✗ unit: OrderService.checkout fails (root cause)
# ✗ integration: CheckoutAPI POST /checkout fails (downstream)
# ✗ e2e: checkout flow times out (downstream)
# → Real cause obscured by three simultaneous failure signals
```

**[community] `sequence.groupOrder` is most valuable for TDD teams practicing double-loop TDD** (outer acceptance test loop + inner unit test loop). Without group ordering, a failing outer acceptance test case in E2E runs simultaneously with the inner unit loop, making the Red signal ambiguous: is the outer test failing because the feature is not implemented, or because the unit-level code has a defect? With group 1 (unit) completing before group 3 (E2E), the failure is always attributed to the correct TDD layer.

---

### Real-World Gotchas [community] — Additions (iter 26)

48. **[community] The `test.extend()` builder pattern's return-value type inference does not work for fixtures that use the `use()` callback form.** The Vitest 4.1 builder pattern infers fixture types from the return value of factory functions. However, fixtures that need explicit async teardown — patterns like `async ({ dep }, use) => { const resource = ...; await use(resource); await resource.close(); }` — cannot use the builder pattern because the `use()` callback style does not produce a return value. TypeScript cannot infer the fixture type from `await use(resource)`. For teardown-requiring fixtures, use either the builder pattern with `onCleanup()` (which returns the resource and registers cleanup separately), or fall back to the object syntax with a manual type declaration. Mixing both patterns within a single `test.extend()` chain is supported: builder-pattern fixtures (with `onCleanup`) can be followed by object-syntax fixtures in the same `test` instance.

49. **[community] `ctx.annotate()` attached before the test assertion can mislead when the annotation itself is async and the test throws synchronously.** In Vitest, `annotate()` returns a `Promise<void>` and must be awaited. When a developer writes `ctx.annotate(message)` without `await` (forgetting the async nature), the annotation Promise is fire-and-forget — Vitest attempts to auto-await it before test completion, but if the test throws before that cleanup phase, the annotation may not be captured in the report. The TDD failure message then lacks the expected diagnostic context. The fix: always `await ctx.annotate(...)` immediately when called, regardless of whether it precedes or follows assertions. ESLint's `@typescript-eslint/no-floating-promises` rule will catch unawaited `annotate()` calls if test files are included in the ESLint project configuration.

---

 — the highest-impact TDD breakage must be fixed manually.** The `ts5to6` automated migration tool ([github.com/andrewbranch/ts5to6](https://github.com/andrewbranch/ts5to6)) handles `baseUrl` → `paths` migration, deprecated option removal, and `rootDir` inference fixes. However, it does not add `"types": ["vitest/globals"]` (or `"jest"` / `"mocha"`) to `tsconfig.json` — because it cannot know which test framework's globals your project uses. Teams that run the codemod and assume the migration is complete will still hit the `Cannot find name 'describe'` TypeScript error in every test file. The correct checklist: run `ts5to6` for mechanical config changes, then manually add the `types` array entry for the test runner, then run `tsc --noEmit` to catch any remaining issues. Do not use `ts5to6` as the sole migration step before upgrading `typescript`.

47. **[community] `ctx.signal` in Vitest 3.2 is not the same as an `AbortController` created in `beforeEach` — it fires on test _timeout_, not on `afterEach`.** Teams who read about `ctx.signal` and attempt to use it as a general teardown signal (e.g., for cleaning up background tasks in all test cases, not just timeout cases) will find it does not fire when a test case completes normally. `ctx.signal` is only aborted on timeout or external cancellation. For general cleanup of background async work, continue to use `using` (TypeScript 5.2 Explicit Resource Management) or `afterEach` hooks. The correct use of `ctx.signal` is narrowly scoped: pass it to production code that should be cancellation-aware, and verify it is honoured when the timeout fires. Mixing `ctx.signal` with `afterEach` teardown logic creates a race: the `afterEach` cleanup may run before the signal fires (normal completion), making the cleanup correct, but for a timeout case the signal fires during the test body before `afterEach` — a different execution path the cleanup code may not handle.

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| *Test-Driven Development: By Example* — Kent Beck | Book | https://www.oreilly.com/library/view/test-driven-development/0321146530/ | The canonical TDD reference; covers red-green-refactor, fake-it, triangulation |
| TestDrivenDevelopment — Martin Fowler | Article | https://martinfowler.com/bliki/TestDrivenDevelopment.html | Concise definition, situates TDD in the broader testing landscape |
| TestFirst — Martin Fowler | Article | https://martinfowler.com/bliki/TestFirst.html | Distinguishes TDD (with refactor step) from test-first (without) |
| *Working Effectively with Legacy Code* — Michael Feathers | Book | https://www.oreilly.com/library/view/working-effectively-with/0131177052/ | Essential for applying TDD to untestable legacy codebases; defines seams, characterisation tests |
| Contributing Tests Wiki — Test Double / Justin Searls | Wiki | https://github.com/testdouble/contributing-tests/wiki/Test-Driven-Development | Pragmatic TDD guidance; covers London vs Chicago schools and real adoption patterns |
| *Boundaries* talk — Gary Bernhardt | Conference talk | https://www.destroyallsoftware.com/talks/boundaries | Functional core / imperative shell architecture; explains how to structure code to minimise mocking need |
| *xUnit Test Patterns* — Gerard Meszaros | Book | https://xunitpatterns.com/ | Definitive reference for test doubles taxonomy (Dummy, Stub, Spy, Mock, Fake) |
| Transformation Priority Premise — Robert C. Martin | Blog | https://blog.cleancoder.com/uncle-bob/2013/05/27/TheTransformationPriorityPremise.html | Formal ordering of TDD generalisation steps; prevents over-engineering during Green phase |
| fast-check — property-based testing | Library | https://fast-check.io/ | TypeScript-native property-based testing library that complements TDD |
| ISTQB CTFL 4.0 Syllabus | Certification | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative terminology reference for test case, test suite, test level, defect, test basis |
| Vitest — official docs | Docs | https://vitest.dev/ | Primary Vite-native test runner for TypeScript projects; watch mode, coverage, snapshot support |
| Stryker Mutator | Docs | https://stryker-mutator.io/ | TypeScript mutation testing — measures TDD effectiveness beyond line coverage |
| Martin Fowler — Testing Guide | Article | https://martinfowler.com/testing/ | Production patterns, Test Cancer failure mode, self-testing code principles |
| TypeScript 5.5 Release Notes | Docs | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-5.html | Inferred type predicates — TDD-friendly filter functions with automatic narrowing |
| TypeScript 5.7 Release Notes | Docs | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-7.html | `--noCheck` flag for CI parallelisation of type-check vs test jobs |
| TypeScript 5.8 Release Notes | Docs | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-8.html | Granular return branch checks; `--erasableSyntaxOnly` for Node.js type-stripping TDD loops |
| TypeScript 5.9 Release Notes | Docs | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-9.html | TDD-friendly `tsc --init` defaults; `import defer` for lazy module evaluation; `noUncheckedSideEffectImports` (note: option introduced in TS 5.6) |
| TypeScript 6.0 Release Notes | Docs | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html | Major breaking changes: `types:[]` default breaks Vitest/Jest globals without explicit config; removed deprecated module options; ES2025 support; `Map.getOrInsert` in typed fakes |
| Vitest 4.0 Release Notes | Docs | https://vitest.dev/blog/vitest-4.html | Stable Browser Mode; `expect.schemaMatching` (Zod/Valibot/ArkType); `expect.assert` for type narrowing; `spyOn` constructor; `toMatchScreenshot`; typed `test.extend()` fixture context in hooks; sequential `verbose` reporter |
| "Is TDD Dead?" video series | Video series | https://martinfowler.com/articles/is-tdd-dead/ | Kent Beck, DHH, Fowler debate; introduces Frequency/Fidelity/Overhead/Lifespan framework |
| Self-Testing Code — Martin Fowler | Article | https://martinfowler.com/bliki/SelfTestingCode.html | The foundational goal behind TDD; explains why automated test suites matter more than methodology |
| Google Testing Blog — "The Way of TDD" | Blog post | https://testing.googleblog.com/2026/03/the-way-of-tdd.html | 2026 Google TotT post on TDD practice and discipline |
| Google Testing Blog — "Construct with Collaborators, Call with Work" | Blog post | https://testing.googleblog.com/2026/05/construct-with-collaborators-call-with.html | 2026 Google TotT post; articulates the design principle underlying constructor injection in TDD: collaborators (services, dependencies) belong in constructors, work (data, request inputs) belongs in method parameters |
| Google Testing Blog — "Set Safe Defaults for Flags" | Blog post | https://testing.googleblog.com/2026/03/set-safe-defaults-for-flags.html | 2026 Google TotT post; safe-default principle for feature flags — TDD implication: write the disabled-state test case first |
| Google Testing Blog — "One Map Key, One Lookup" | Blog post | https://testing.googleblog.com/2026/04/one-map-key-one-lookup.html | 2026 Google TotT post; one-lookup pattern for in-memory fakes — eliminates `!` non-null assertions and double-lookup bugs in TypeScript test doubles |
| TCR (Test && Commit \|\| Revert) — Kent Beck | Blog post | https://medium.com/@kentbeck_7670/test-commit-revert-870bbd756864 | Original TCR proposal; automates baby-steps discipline by reverting failed changes automatically |
| Zod v4 Release Notes | Docs | https://zod.dev/v4 | Major rewrite: z.input/z.output, z.toJSONSchema, z.interface, z.prefault, z.registry; breaking changes from v3 |
| TypeScript 5.2 — `using` and `await using` | Docs | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-2.html | Explicit Resource Management for TDD teardown; scope-bound spy cleanup and test database disposal |
| Neon DB — Test Branching | Docs | https://neon.com/docs/guides/branching-test-queries | Copy-on-write Postgres branch per test run; schema-only branching for sensitive data; instant teardown |
| ECMAScript `Promise.try` Proposal | Docs | https://github.com/tc39/proposal-promise-try | Wraps sync throws as rejected promises — unifies sync/async TDD error assertions; available in Node 22+ and TypeScript 6.0 |
| Vitest 4.1 Release Notes | Docs | https://vitest.dev/blog/vitest-4-1 | --detect-async-leaks for timer leak detection; vi.defineHelper() for correct stack trace attribution; mockThrow/mockThrowOnce; aroundEach/aroundAll; test tags; coverage.changed; GitHub Actions reporter; agent reporter for AI-assisted TDD; viteModuleRunner:false; onCleanup() fixture callback; Chai-style mock assertions |
| Vitest 4.1 Native Node Execution | Docs | https://vitest.dev/guide/projects.html | Experimental `runner: 'node'` for sub-50ms TDD feedback on pure domain modules; requires erasable TypeScript syntax and Node.js 23.6+ |
| Vitest 4.1 `viteModuleRunner: false` | Docs | https://vitest.dev/config/#viteModuleRunner | Disables Vite sandbox for production-closer test execution; supports vi.mock via Node 22.15+ Module Loader API; complements runner:node for different test isolation strategies |
| TypeScript 5.9 Release Notes | Docs | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-9.html | TDD-friendly `tsc --init` defaults; `import defer` for lazy module evaluation; `noUncheckedSideEffectImports`; `--module node20` for stable Node.js 20 semantics |
| TypeScript 6.0 Release Notes | Docs | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html | Major breaking changes: `types:[]` default breaks Vitest/Jest globals without explicit config; removed deprecated module options; ES2025 support; `Map.getOrInsert` in typed fakes; `this`-less function inference improvement; `--stableTypeOrdering` for TS 7.0 migration prep |
| Google Testing Blog — "The Way of TDD" | Blog post | https://testing.googleblog.com/2026/03/the-way-of-tdd.html | 2026 Google TotT post; six TDD discipline commitments; emphasises Refactor phase as mandatory, Red as information, and baby steps as precise thinking — not timid |
| Vitest 4.1 ARIA Snapshots Guide | Docs | https://vitest.dev/guide/browser/aria-snapshots | TDD for accessibility contracts: `toMatchAriaSnapshot` / `toMatchAriaInlineSnapshot` assert against the accessibility tree; catches semantic regressions that visual snapshots and Axe linting miss |
| Vitest Type Testing Guide | Docs | https://vitest.dev/guide/testing-types.html | Type-level TDD with `expectTypeOf` in `*.test-d.ts` files; `@ts-expect-error` as Red type tests; `toEqualTypeOf` for exact type contract assertions; `vitest typecheck` for CI integration |
| TypeScript 6.0 — Module Resolution Migration | Docs | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html | `baseUrl` fully deprecated in TS 6.0 (removed in 7.0); `paths` entries must use full relative paths; `#/` subpath imports as Node.js-native alias alternative; `--moduleResolution bundler` + `--module commonjs` now valid for CJS migrations |
| Vitest 3.2 Release Notes | Docs | https://vitest.dev/blog/vitest-3-2 | Scoped fixtures (`scope:'file'|'worker'` in `test.extend`); `using` keyword support for `vi.spyOn`/`vi.fn` (native Disposable); unified `Matchers` type replacing `Assertion<R>`; `watchTriggerPatterns`; `AbortSignal` per test case; `context.annotate()` for structured diagnostic attachments; `sequence.groupOrder` for ordered multi-project execution |
| Vitest 4.1 Test Context / Builder Pattern | Docs | https://vitest.dev/guide/test-context | Chainable `test.extend().extend()` builder pattern with automatic TypeScript type inference from fixture return values; eliminates manual `interface` declarations; `onCleanup()` for co-located teardown; scoped fixtures in builder chain |
| Google Testing Blog — "Simplify Your Code: Functional Core, Imperative Shell" | Blog post | https://testing.googleblog.com/2025/10/simplify-your-code-functional-core.html | 2025 Google TotT post; reinforces the Functional Core/Imperative Shell pattern as a testing simplification strategy — pure core is trivially unit-testable, imperative shell is integration-tested |
| Google Testing Blog — "Arrange Your Code to Communicate Data Flow" | Blog post | https://testing.googleblog.com/2025/01/arrange-your-code-to-communicate-data.html | 2025 Google TotT post; code arrangement to communicate data flow — directly applicable to TDD Arrange phase: ordering local variables to show data transformation chain makes test intent readable |
| Google Testing Blog — "Sort Lines in Source Code" | Blog post | https://testing.googleblog.com/2025/09/sort-lines-in-source-code.html | 2025 Google TotT post; consistent line ordering in test doubles and fixtures reduces merge conflicts and improves scanability during TDD refactor phase |
| Node.js Subpath Imports | Docs | https://nodejs.org/api/packages.html#subpath-imports | `package.json` `imports` field for `#/` subpath imports; works with Vitest `runner: 'node'` and `viteModuleRunner: false` without bundler plugins |
| Vitest 4.1 Coverage Ignore Comments | Docs | https://vitest.dev/guide/coverage | Coverage ignore comments require `@preserve` annotation in esbuild pipelines: `/* v8 ignore next -- @preserve */`; without `@preserve`, esbuild strips comments before coverage instrumentation |
| TypeScript 6.0 Temporal API | Docs | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html | Stage-4 Temporal API built-in types in TS 6.0 via `"lib": ["esnext"]`; use Clock interface injection (not vi.spyOn) for TDD against Temporal.Now |
| ts5to6 Migration Codemod | Tool | https://github.com/andrewbranch/ts5to6 | Automates mechanical TypeScript 6.0 migration: `baseUrl`→`paths`, deprecated options, `rootDir` inference; does NOT update `"types"` arrays (must be done manually for test runner globals) |
| Vitest 3.2 — AbortSignal per Test Case | Docs | https://vitest.dev/guide/test-context.html | `ctx.signal` fired on test timeout; enables TDD for cancellation-aware code; distinct from `afterEach` cleanup — fires only on timeout/cancellation, not normal test completion |
