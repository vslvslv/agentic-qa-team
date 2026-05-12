# TDD — QA Methodology Guide
<!-- lang: TypeScript | topic: tdd | iteration: 16 | score: 100/100 | date: 2026-05-12 -->
<!-- sources: training-knowledge + martinfowler.com (WebFetch) + typescript-patterns.md + is-tdd-dead-debate (WebFetch 2026-05-12) + google-testing-blog-2026 + typescript-5.6-5.8-5.9 (WebFetch 2026-05-12) + typescript-6.0 (WebFetch 2026-05-12) + vitest-4.0 (WebFetch 2026-05-12) + vitest-4.0-verbose-reporter (WebFetch 2026-05-12) | ISTQB CTFL 4.0 terminology applied -->
<!-- correction 2026-05-12: noUncheckedSideEffectImports was introduced in TypeScript 5.6 (not 5.9); TypeScript 6.0 added as new section -->

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

// Extend Vitest's Matchers interface for TypeScript type safety
declare module 'vitest' {
  interface Assertion<R = unknown> {
    toBeSuccessResult(): R;
    toBeFailureResult(expectedError?: string): R;
    toBeWithinCents(expected: number, toleranceCents?: number): R;
  }
}

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

**`noUncheckedSideEffectImports` (TypeScript 5.6, not 5.9):** This compiler option (introduced in TypeScript 5.6, available but off by default) flags imports that are only used for their side effects (e.g., `import './polyfill.js'`) when the module does not exist. Without it, TypeScript silently ignores missing side-effect-only imports. In TDD, enabling this catches test setup files that accidentally import a path that was renamed or deleted — a category of defect that previously produced silent test isolation failures. **Note:** This option is opt-in. Enable it in `tsconfig.json` explicitly: `"noUncheckedSideEffectImports": true`.

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

**[community] The `types: []` default change is the highest-impact TDD gotcha in TypeScript 6.0.** Teams that rely on globally available `describe`/`it`/`expect` from Vitest globals will see immediate compile errors after upgrading without adding `"types": ["vitest/globals"]`. The fix is one line, but it will block CI if the upgrade happens without reading the migration guide first.

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
