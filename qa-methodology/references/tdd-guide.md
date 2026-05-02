# TDD — QA Methodology Guide
<!-- lang: TypeScript | topic: tdd | iteration: 4 | score: 100/100 | date: 2026-05-02 -->
<!-- sources: training-knowledge (WebSearch/WebFetch unavailable) | ISTQB CTFL 4.0 terminology applied -->

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
