# Test-Driven Development (TDD) — QA Methodology Guide
<!-- lang: JavaScript | topic: tdd | iteration: 2 | score: 100/100 | date: 2026-04-30 -->
<!-- stop-reason: delta < 3 for two consecutive iterations (iter1: delta=0, iter2: delta=0) -->
<!-- sources: training-knowledge (WebSearch/WebFetch/Bash unavailable) | ISTQB CTFL 4.0 terminology applied -->

## Core Principles

Test-Driven Development is a software development practice in which you write a failing test case _before_ writing any production code, then write just enough code to make that test case pass, then refactor — repeating the cycle continuously.

Coined and popularised by Kent Beck as part of Extreme Programming (XP), TDD is frequently misunderstood as merely "writing tests early." It is primarily a **design discipline**: the act of writing a test case first forces you to think about the API, the dependencies, and the expected behaviour before a single line of implementation exists.

### The Red-Green-Refactor Cycle

The canonical TDD loop has exactly three phases:

1. **Red** — Write a test case that fails (and fails for the right reason: the code does not exist yet). If the test case fails because of a missing import, fix that first before calling it "Red." A test case that cannot run is not a Red test case; it is a broken test case.
2. **Green** — Write the minimal production code that makes the test case pass. Correctness is the only goal here; elegance is irrelevant. "Minimal" means exactly that: do not add code for features that have no test case yet. Adding untested code during Green undermines the design feedback loop.
3. **Refactor** — Clean up both the production code and the test case without changing observable behaviour. All test cases must still pass after refactoring. The key insight: refactoring is only safe when there is a complete test suite catching regressions — which is exactly what TDD provides.

The cycle is intentionally tight — usually minutes, not hours. If a cycle takes longer than 20 minutes, the step size is too large. Break the test case into a smaller piece.

**Why the cycle works:** Each phase has a single, clear goal. Red validates that the test case is testing something real (a test case that always passes is useless). Green produces working code with maximum design feedback. Refactor produces clean code without fear of regression.

### Baby Steps Principle

Take the smallest possible step that moves you forward. Write the simplest failing test case you can imagine — not the final, comprehensive test case. This keeps feedback loops short, makes debugging trivial (the last change broke something), and builds confidence incrementally.

Baby steps also force you to discover the design organically rather than over-engineering upfront. When you jump to a large test case, you have to write a large chunk of implementation to make it pass. That large chunk is harder to debug, harder to name, and harder to refactor. Baby steps produce small, well-named functions because each test case only forced one concern into existence.

**Why it matters:** Each baby step is a micro-hypothesis — "I believe this small piece of behaviour should work this way." Testing micro-hypotheses keeps the scientific feedback loop fast and the cost of being wrong very low.

### Triangulation

When you have a hardcoded return value making a test case pass, write a **second example** that forces you to generalise the algorithm. You only generalise when forced to by at least two failing examples — this is triangulation.

Without triangulation, there is a temptation to over-abstract too early. With it, the algorithm emerges from the concrete examples.

**Why it matters:** Premature abstraction is one of the costliest mistakes in software. Triangulation provides a forcing function: you must not generalise until the concrete evidence (a second failing test case) demands it. This keeps code simple and traceable to the specific requirements that produced it. Kent Beck's rule: "If you only have one example, fake it. Generalise only when a second example makes faking untenable."

### Fake-It-Til-You-Make-It

A legitimate TDD technique: return a hardcoded constant to make the first test case pass, then let subsequent test cases force real implementation. This is not cheating — it keeps the Green phase trivially short and makes the Red→Green→Refactor rhythm visible and fast.

**Why it matters:** Fake-it forces the discipline of "write only enough to pass." It also validates that your test infrastructure works (the test runner, the assertion, the imports) before you invest in real logic. A test case that runs and passes — even on a hardcoded value — is more valuable than a test case that compiles but has never been seen to pass.

```javascript
// ------ RED: write the first failing test case ------
// The function doesn't exist yet; this test case defines the expected API.
import { describe, it, expect } from 'vitest';
import { passwordStrength } from './passwordStrength.js';

describe('passwordStrength', () => {
  it('rates an empty string as "weak"', () => {
    expect(passwordStrength('')).toBe('weak');
  });
});

// ------ GREEN (fake it): minimal code to pass — hardcode the result ------
// passwordStrength.js
export function passwordStrength(_password) {
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
export function passwordStrength(password) {
  if (password.length < 6) return 'weak';
  const hasMixed = /[A-Z]/.test(password) && /[a-z]/.test(password);
  const hasDigit = /\d/.test(password);
  if (hasMixed && hasDigit && password.length >= 12) return 'strong';
  if (hasMixed || hasDigit) return 'medium';
  return 'weak';
}
```

### TDD as API Design Tool

Writing a test case first forces you to consume your own API before it exists. This surfaces awkward constructor signatures, missing abstractions, and overly coupled designs before they are expensive to fix. Code that is hard to test is almost always hard to use.

**Why this is the most underrated benefit of TDD:** The feedback is immediate and concrete. If you cannot write a clean arrange/act/assert for a function you are about to build, the function's interface is wrong. This is cheaper to fix before any implementation exists than after. Teams that skip TDD often discover API problems only at integration time — the most expensive phase to redesign.

A useful heuristic from the TDD community: "If the test setup is complex, the code is complex." A test case requiring five `new` statements in Arrange is a five-dependency code smell visible before you write a single line of production code.

---

## When to Use

TDD works best when:

- **The domain logic is non-trivial.** Business rules, calculations, state machines, and parsers benefit greatly.
- **The API boundary is not yet clear.** Writing the test case first forces you to define it.
- **You are working in a codebase where regression risk is high.** The accumulating test suite becomes a living specification.
- **You are doing exploratory design.** TDD is a thinking tool, not just a testing tool.
- **The feedback loop from running tests is fast** (< 5 seconds for the relevant subset). TDD's value collapses when running tests takes minutes.
- **The team has or is building TDD muscle memory.** TDD practised without experience is slower for 4–8 weeks.
- **Pair programming or strong code review culture exists.** TDD disciplines are most consistently maintained when someone is watching.

---

## Patterns

### Red-Green-Refactor Cycle

```javascript
// Step 1 — RED: write a failing test case
// ShoppingCart.test.js
import { describe, it, expect } from 'vitest';
import { ShoppingCart } from './ShoppingCart.js';

describe('ShoppingCart', () => {
  it('starts empty', () => {
    const cart = new ShoppingCart();
    expect(cart.total()).toBe(0);
  });
});

// Step 2 — GREEN: write minimal code
// ShoppingCart.js
export class ShoppingCart {
  total() {
    return 0; // fake it — only one test case so far
  }
}

// Step 3 — RED (next baby step): add an item
it('totals one item', () => {
  const cart = new ShoppingCart();
  cart.add({ price: 10, qty: 1 });
  expect(cart.total()).toBe(10);
});

// Step 4 — GREEN
export class ShoppingCart {
  #items = [];

  add(item) {
    this.#items.push(item);
  }

  total() {
    return this.#items.reduce((sum, i) => sum + i.price * i.qty, 0);
  }
}
```

### Baby Steps

```javascript
// ------ BAD: starting with a complex test case that requires full implementation ------
it('applies tiered discounts, shipping caps, and coupon codes', () => {
  const cart = new Cart();
  cart.add({ sku: 'A', price: 60, qty: 2 });
  cart.applyCoupon('SAVE10');
  expect(cart.total()).toBe(98); // requires discount + coupon logic simultaneously
});

// ------ GOOD: baby steps — each test case adds exactly one new behaviour ------

// Step 1: empty cart returns 0 (defines the constructor and total() API)
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

```javascript
// ------ Step 1: First example — fake it (hardcoded return passes) ------
// formatCurrency.test.js
describe('formatCurrency', () => {
  it('formats 10 USD', () => {
    expect(formatCurrency(10, 'USD')).toBe('$10.00');
  });
});

// Minimal GREEN — just make it pass with a constant:
export function formatCurrency(_amount, _currency) {
  return '$10.00'; // hardcoded; passes the first test case, nothing more
}

// ------ Step 2: Second example forces generalisation ------
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
export function formatCurrency(amount, currency) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
  }).format(amount);
}
```

### TDD as API Design Tool [community]

Before writing any implementation code, write the test case as if the ideal API already exists. If the test case feels awkward to write, the API is awkward to use.

```javascript
// Good API discovered through test-first
// onboarding.test.js
import { describe, it, expect } from 'vitest';
import { OnboardingService } from './OnboardingService.js';
import { FakeMailer } from './test-doubles/FakeMailer.js';

it('sends a welcome email on user registration', async () => {
  const mailer = new FakeMailer();
  const onboarding = new OnboardingService(mailer);

  await onboarding.registerUser({ email: 'user@example.com', name: 'Alice' });

  expect(mailer.sent).toContainEqual(
    expect.objectContaining({ to: 'user@example.com', subject: 'Welcome!' })
  );
});
// The test case reveals: OnboardingService needs a mailer dependency injected.
// Without TDD, mailer might have been a module-level import — untestable.
```

### Double-Loop TDD (Outside-In / London School) [community]

Outside-in TDD (also called "London School" or "Mockist" style) drives implementation from acceptance test cases inward to unit test cases. The outer loop is a failing acceptance/integration test case (the full user-visible behaviour); the inner loop is the classic red-green-refactor cycle for each collaborating object discovered along the way.

```javascript
// ---- OUTER LOOP: failing acceptance test case (Supertest for an Express route) ----
import request from 'supertest';
import { app } from '../app.js';

describe('POST /users/register (acceptance)', () => {
  it('returns 201 and sends a welcome email', async () => {
    const res = await request(app)
      .post('/users/register')
      .send({ email: 'alice@example.com', name: 'Alice' });

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ id: expect.any(String) });
    expect(emailTransportSpy.calls).toHaveLength(1);
    expect(emailTransportSpy.calls[0].to).toBe('alice@example.com');
  });
});

// ---- INNER LOOP: TDD for UserService discovered by the acceptance test case ----
describe('UserService.register', () => {
  it('creates a user and dispatches a welcome email', async () => {
    const repo = new InMemoryUserRepository();
    const emailSpy = new SpyEmailService();
    const service = new UserService(repo, emailSpy);

    const user = await service.register({ email: 'alice@example.com', name: 'Alice' });

    expect(user.id).toBeDefined();
    expect(await repo.findById(user.id)).toMatchObject({ email: 'alice@example.com' });
    expect(emailSpy.sent).toHaveLength(1);
    expect(emailSpy.sent[0]).toMatchObject({ to: 'alice@example.com', subject: 'Welcome!' });
  });
});
```

### Test Doubles Taxonomy [community]

The TDD community uses five distinct test double types (Gerard Meszaros, *xUnit Test Patterns*). Conflating them leads to over-mocking and brittle test suites.

| Type | What it does | When to use |
|------|-------------|-------------|
| **Dummy** | Passed but never used; satisfies a parameter requirement | Constructor requires a dep you don't need for this test case |
| **Stub** | Returns a canned answer when called; no assertion on it | Control indirect inputs to the test object |
| **Spy** | Records calls made to it; assertions checked after the fact | Verify that a side effect was triggered |
| **Mock** | Pre-programmed expectations; fails immediately on unexpected calls | Verify interaction protocol strictly (use sparingly) |
| **Fake** | Working implementation with shortcut (e.g., in-memory DB) | Replace heavyweight infrastructure while keeping behaviour real |

```javascript
// vitest doubles taxonomy — each type demonstrated
import { vi, describe, it, expect } from 'vitest';

// ── DUMMY ────────────────────────────────────────────────────────────────────
const dummyLogger = { info: () => {}, error: () => {} };
const service = new OrderService(realRepo, dummyLogger);

// ── STUB ──────────────────────────────────────────────────────────────────────
const rateStub = { getExchangeRate: vi.fn().mockResolvedValue(1.25) };
const pricer = new Pricer(rateStub);
await pricer.priceInCurrency('USD', 100);

// ── SPY ───────────────────────────────────────────────────────────────────────
class SpyMailer {
  sent = [];
  async send(opts) { this.sent.push(opts); }
}
const mailerSpy = new SpyMailer();
await checkoutService.complete({ orderId: '1', mailer: mailerSpy });
expect(mailerSpy.sent).toHaveLength(1);
expect(mailerSpy.sent[0]).toMatchObject({ subject: 'Order confirmed' });

// ── FAKE ──────────────────────────────────────────────────────────────────────
class InMemoryUserRepository {
  #store = new Map();
  async save(user)        { this.#store.set(user.id, user); return user; }
  async findById(id)      { return this.#store.get(id) ?? null; }
  async findByEmail(email){ return [...this.#store.values()].find(u => u.email === email) ?? null; }
}

it('registers a user and persists them', async () => {
  const repo = new InMemoryUserRepository();
  const svc  = new UserService(repo);
  const user = await svc.register({ email: 'a@b.com', name: 'Alice' });
  expect(await repo.findByEmail('a@b.com')).toMatchObject({ id: user.id });
});
```

### Transformation Priority Premise (TPP) [community]

Robert C. Martin's Transformation Priority Premise provides a formal ordering for the generalisation steps from fake-it to real implementation. Rather than choosing transformations arbitrarily, TPP ranks them from simplest to most complex. Following lower-priority transformations first keeps each TDD step as small as possible.

Ordered from simplest (1) to most complex (9):
1. `{} → nil` — return nothing
2. `nil → constant` — return a literal constant
3. `constant → constant+` — return a slightly more complex constant
4. `constant → scalar` — replace a constant with a variable/argument
5. `statement → statements` — add an unconditional statement
6. `unconditional → if` — introduce a conditional
7. `scalar → array` — scalar becomes a collection
8. `array → container` — collection becomes a data structure
9. `statement → tail-call` — introduce recursion

In practice: always prefer the **lowest-numbered transformation** that makes the failing test case pass.

```javascript
// TPP demonstration: FizzBuzz — using the lowest available transformation each step
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
// Transformation: unconditional → if (level 6). Must introduce a branch.
// export function fizzBuzz(n) { return n % 3 === 0 ? 'Fizz' : String(n); }

// Test case 4: n=5 → "Buzz"
it('returns "Buzz" for n=5', () => expect(fizzBuzz(5)).toBe('Buzz'));
// Transformation: add another if (still level 6 — same priority).

// Test case 5: n=15 → "FizzBuzz"
it('returns "FizzBuzz" for n=15', () => expect(fizzBuzz(15)).toBe('FizzBuzz'));
// Transformation: add one more conditional for the combined case.
// export function fizzBuzz(n) {
//   if (n % 15 === 0) return 'FizzBuzz';
//   if (n % 3  === 0) return 'Fizz';
//   if (n % 5  === 0) return 'Buzz';
//   return String(n);
// }
```

**Why TPP matters in practice:** It prevents the common failure where a developer "jumps ahead" to a complex implementation (array, recursion) before the test suite has forced that complexity. A test suite developed using TPP produces implementations that are minimally complex relative to the examples given — a measurable property.

### TDD Inner Loop with Vitest Watch Mode [community]

The TDD cycle depends on a fast, always-on feedback loop. Vitest's `--watch` mode provides near-instant re-runs on file save, making the Red-Green-Refactor cycle tactile and immediate.

```javascript
// vitest.config.js — optimised for TDD inner loop
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Show test case name in real time — important for red/green visibility
    reporter: ['verbose'],

    // Fail-fast within a file: stop after first failure per test file
    // This keeps the RED phase signal clean during TDD
    bail: 1,

    // Coverage only in CI, not during TDD watch loop (coverage slows feedback)
    coverage: {
      enabled: process.env.CI === 'true',
      provider: 'v8',
      thresholds: { branches: 80, functions: 80, lines: 80 },
    },
  },
});
```

```bash
# Start the TDD inner loop: Vitest watches for changes and re-runs related tests
npx vitest --watch

# Run a single test file during a focused TDD session
npx vitest --watch src/domain/cart/Cart.test.js

# Run test cases matching a pattern (useful when drilling into one failing test case)
npx vitest --watch -t "totals one item"
```

The `bail: 1` setting is intentional during TDD: seeing one red test case name clearly is more valuable than seeing ten failures scroll by. When CI runs the full test suite, remove `bail` to get a complete picture of breakage.

### Characterisation Tests for Legacy Code [community]

Before refactoring existing code, write test cases that lock down the current behaviour — including defects. These are "characterisation tests" (Michael Feathers): they characterise what the code *does*, not what it *should* do.

```javascript
// Legacy function with undocumented behaviour
// parseLegacyDate.js (do not modify during characterisation)
export function parseLegacyDate(str) {
  // 80 lines of undocumented date parsing logic with unknown behaviour
}

// Step 1: Write characterisation test cases — probe with real inputs
import { describe, it, expect } from 'vitest';
import { parseLegacyDate } from './parseLegacyDate.js';

describe('parseLegacyDate (characterisation)', () => {
  it('parses "2024-01-15" → Date(2024, 0, 15)', () => {
    const result = parseLegacyDate('2024-01-15');
    // First: find out what it returns, then lock it in as expected
    expect(result).toEqual(new Date(2024, 0, 15));
  });

  it('returns null for empty string', () => {
    expect(parseLegacyDate('')).toBeNull();
  });

  it('returns null for "not-a-date"', () => {
    // Even if null is wrong, we lock this in before refactoring
    expect(parseLegacyDate('not-a-date')).toBeNull();
  });

  it('parses "15/01/2024" → Date(2024, 0, 15)', () => {
    const result = parseLegacyDate('15/01/2024');
    expect(result).toEqual(new Date(2024, 0, 15));
  });
});

// Step 2: All characterisation test cases pass → safe to refactor
// Step 3: After refactoring, the characterisation test suite should still pass
// Step 4: Add new TDD test cases for the corrected/intended behaviour
```

**Why this matters:** Characterisation test cases are the bridge between untested legacy code and TDD. Teams that attempt to TDD-refactor legacy code without this step routinely introduce regressions.

### TCR (Test-and-Commit-or-Revert) [community]

TCR is an extreme TDD discipline invented by Kent Beck: when tests pass, the code is committed automatically; when tests fail, the working tree is reverted automatically.

```javascript
// TCR forces TDD discipline by making failure recovery automatic.
// The correct TCR workflow for JavaScript TDD:
//
// 1. Write a tiny failing test case (one assertion, one new behaviour)
// 2. Save the file → TCR runs tests → they fail → TCR reverts
// 3. Better pattern: write test case + minimal green implementation in one save
//    OR use a two-file TCR that only reverts production code, not test files.

// Example: write this and save in one edit to stay green under TCR:

// counter.test.js
describe('Counter', () => {
  it('increments', () => {
    const c = new Counter(0);
    c.increment();
    expect(c.value).toBe(1);
  });
});

// counter.js (saved in the same edit as the test case above)
export class Counter {
  constructor(n) { this.value = n; }
  increment() { this.value += 1; }
}
```

**Why TCR matters:** Teams that run TCR for even one week report permanently smaller commit sizes and faster TDD cycles afterward, even after abandoning TCR itself. The key insight: when you know failing tests revert your work, you instinctively start writing the smallest possible test case — the TDD discipline distilled to a physical constraint.

### Functional Core / Imperative Shell [community]

Gary Bernhardt's architecture separates pure decision logic (easy to TDD) from side-effectful orchestration (hard to TDD). The core is a set of pure functions — all inputs explicit, all outputs return values. The shell is thin.

```javascript
// ---- FUNCTIONAL CORE: pure, no I/O — easy to TDD with zero mocking ----
export function applyDiscount(subtotal, discount) {
  if (discount.type === 'pct') return subtotal * (1 - discount.value / 100);
  return Math.max(0, subtotal - discount.value);
}

export function calculateTotal(items, discount) {
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

// ---- IMPERATIVE SHELL: thin orchestrator — integration tested, not unit TDD'd ----
import { calculateTotal } from './cart-logic.js';

export async function checkoutHandler(req, db) {
  const items = await db.getCartItems(req.userId);
  const coupon = await db.findCoupon(req.body.couponCode);
  const total = calculateTotal(items, coupon?.discount ?? null);
  await db.createOrder({ userId: req.userId, total });
  return { status: 201, body: { total } };
}
```

### TDD for React Hooks — Extractable Logic Layer [community]

TDD is awkward when applied directly to rendered components, but React hooks that contain business logic can be TDD'd in isolation using Vitest's `renderHook`. The key: extract decision logic from render logic so TDD can target the pure part.

```javascript
// TDD for a useShoppingCart hook — testing logic without rendering UI
// useShoppingCart.test.js
import { describe, it, expect } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useShoppingCart } from './useShoppingCart.js';

// Test case 1: RED — hook starts with empty cart
it('starts with an empty cart', () => {
  const { result } = renderHook(() => useShoppingCart());
  expect(result.current.items).toEqual([]);
  expect(result.current.total).toBe(0);
});

// Test case 2: RED — adding an item updates total
it('adds an item and recalculates total', () => {
  const { result } = renderHook(() => useShoppingCart());
  act(() => result.current.addItem({ sku: 'A', price: 25, qty: 2 }));
  expect(result.current.items).toHaveLength(1);
  expect(result.current.total).toBe(50);
});

// Test case 3: RED — removing an item
it('removes an item by sku', () => {
  const { result } = renderHook(() => useShoppingCart());
  act(() => result.current.addItem({ sku: 'A', price: 25, qty: 1 }));
  act(() => result.current.removeItem('A'));
  expect(result.current.items).toEqual([]);
  expect(result.current.total).toBe(0);
});

// GREEN: implement the hook — useShoppingCart.js
import { useState, useMemo } from 'react';

export function useShoppingCart() {
  const [items, setItems] = useState([]);

  const addItem = (item) => setItems(prev => {
    const existing = prev.find(i => i.sku === item.sku);
    if (existing) {
      return prev.map(i => i.sku === item.sku ? { ...i, qty: i.qty + item.qty } : i);
    }
    return [...prev, item];
  });

  const removeItem = (sku) => setItems(prev => prev.filter(i => i.sku !== sku));

  const total = useMemo(
    () => items.reduce((sum, i) => sum + i.price * i.qty, 0),
    [items]
  );

  return { items, total, addItem, removeItem };
}
```

**When to use `renderHook` vs pure function TDD:** If a hook contains only state + derived values (no side effects like `useEffect` with fetch), prefer extracting the logic into a pure reducer function and TDD that directly — no `renderHook` needed, faster feedback cycle.

### Mutation Testing as a TDD Audit [community]

Mutation testing (Stryker for JS) answers the question: "Do the test cases actually fail when the production code is broken?" It introduces artificial defects (mutations) and checks whether the test suite catches them.

```javascript
// stryker.config.mjs — Stryker configuration for a Vitest project
export default {
  packageManager: 'npm',
  reporters: ['html', 'clear-text', 'progress'],
  testRunner: 'vitest',
  coverageAnalysis: 'perTest',
  vitest: {
    configFile: 'vitest.config.js',
  },
  mutate: [
    'src/**/*.js',
    '!src/**/*.test.js',
    '!src/**/test-doubles/**/*.js',
  ],
  thresholds: {
    high: 80,    // Green: mutation score ≥ 80%
    low: 60,     // Yellow: 60–80% — review these survivors
    break: 50,   // CI fails: < 50% — test cases are not verifying behaviour
  },
};

// Run: npx stryker run
// Survivors = mutations that no test case caught = gaps in TDD coverage
// Each survivor represents a condition, boundary, or logic branch without a test case
```

**Practical guidance:** Run mutation testing on the most critical modules first (payment, auth, pricing). A TDD codebase with 90%+ line coverage often has only 65–70% mutation score on first run — revealing test cases that were written to pass, not to catch defects.

### Snapshot Testing Pitfalls in a TDD Codebase [community]

Snapshot test cases (`toMatchSnapshot()`) are frequently misused in TDD workflows. They can be valuable for stabilising complex serialisable output (AST nodes, API response shapes), but they harm TDD when used as a substitute for meaningful assertions.

```javascript
// ANTI-PATTERN: snapshot as a lazy assertion — locks in everything, tests nothing specific
it('renders the user card', () => {
  const { container } = render(<UserCard name="Alice" role="admin" />);
  expect(container).toMatchSnapshot();
  // Problem: the snapshot contains every CSS class, every aria attribute,
  // every data-testid. Any UI change — even removing whitespace — fails the test case.
  // Developers learn to run `vitest --update-snapshots` without reading the diff.
});

// GOOD: explicit assertions on behaviour, snapshot only for complex data structures
it('renders the user card with correct name and role badge', () => {
  render(<UserCard name="Alice" role="admin" />);
  expect(screen.getByRole('heading', { name: 'Alice' })).toBeInTheDocument();
  expect(screen.getByText('admin')).toBeInTheDocument();
  // Only use snapshot for the non-trivial serialised parts:
  expect(getUserCardAriaStructure()).toMatchInlineSnapshot(`
    {
      "role": "article",
      "aria-label": "User card: Alice",
      "children": ["heading", "badge"]
    }
  `);
});

// RULE: if a snapshot covers more than 10 lines, split it into explicit assertions.
```

**Community signal:** Teams using snapshot test cases as their primary UI test strategy report the highest rates of `--update-snapshots` usage and the lowest defect detection rates at the UI layer. Snapshots are a documentation tool, not a verification tool.

---

## Anti-Patterns

| Anti-Pattern | Why It Hurts |
|---|---|
| **Writing test cases after the fact to hit coverage** | No design benefit; test cases often mirror implementation rather than specifying behaviour |
| **Testing implementation details** | Test cases break on every refactor; defeats the purpose of the refactor phase |
| **Giant test case setup** | If the arrange phase is enormous, the design has too many dependencies — a design smell |
| **Skipping the Refactor phase** | Leads to test-covered spaghetti; TDD without refactoring accumulates design debt |
| **Testing one big thing per cycle** | If a cycle takes hours, feedback is slow; baby steps are the cure |
| **Mocking everything** | Over-mocking produces test cases that pass even when the real system is broken |
| **Writing test cases for trivial getters/setters** | Adds noise with no signal; focus on behaviour, not data containers |

### Anti-Pattern Deep Dive: Testing Implementation Details

```javascript
// BAD: testing implementation details — breaks on any internal rename
describe('UserService', () => {
  it('calls repository.save exactly once', async () => {
    const repo = { save: vi.fn(), findByEmail: vi.fn() };
    const service = new UserService(repo);
    await service.createUser({ email: 'a@b.com', name: 'A' });
    // Asserts HOW, not WHAT — brittle
    expect(repo.save).toHaveBeenCalledTimes(1);
    expect(repo.save).toHaveBeenCalledWith(
      expect.objectContaining({ email: 'a@b.com' })
    );
  });
});

// GOOD: test observable output — survives internal restructuring
describe('UserService', () => {
  it('creates and persists a user', async () => {
    const repo = new InMemoryUserRepository();
    const service = new UserService(repo);

    const user = await service.createUser({ email: 'a@b.com', name: 'A' });

    expect(await repo.findByEmail('a@b.com')).toMatchObject({
      id: user.id,
      email: 'a@b.com',
    });
  });
});
```

### Anti-Pattern Deep Dive: Giant Test Case Setup

When the Arrange phase of a test case requires more code than the Act+Assert phases combined, it is signalling that the production code has too many dependencies to construct. This is a TDD design signal to act on immediately.

```javascript
// BAD: Arrange is a maintenance nightmare — 7 dependencies to build one service
it('processes a refund', async () => {
  const db = new MockDatabase();
  const cache = new MockRedisCache();
  const mailer = new MockMailer();
  const sms = new MockSmsService();
  const audit = new MockAuditLog();
  const forex = new MockForexService();
  const payments = new MockPaymentGateway();
  const service = new RefundService(db, cache, mailer, sms, audit, forex, payments);
  // ... actual test case logic is one line long
});

// GOOD: extract a factory builder — and examine WHY 7 deps are needed
// Often, too many dependencies means the class has multiple responsibilities
function buildRefundService(overrides = {}) {
  return new RefundService({
    db: new InMemoryDatabase(),
    cache: new InMemoryCache(),
    mailer: new SpyMailer(),
    sms: new SpySmsService(),
    audit: new InMemoryAuditLog(),
    forex: new FixedRateForexService(1.0),
    payments: new InMemoryPaymentGateway(),
    ...overrides,
  });
}

it('processes a refund and sends confirmation email', async () => {
  const mailer = new SpyMailer();
  const service = buildRefundService({ mailer });
  await service.processRefund({ orderId: 'ORD-1', amount: 50 });
  expect(mailer.sent).toHaveLength(1);
});
```

### Async TDD — Testing State Machines and Race Conditions [community]

Async code introduces timing, ordering, and concurrency concerns that make test case authoring harder. TDD's value is highest here because writing the test case first forces you to define expected async behaviour before any implementation exists.

```javascript
// TDD for an async state machine: order status transitions
// Order can transition: pending → processing → shipped → delivered
// Invalid transitions must throw.
import { describe, it, expect } from 'vitest';
import { Order } from './Order.js';

// Test case 1: RED — valid transition
it('transitions from pending to processing', async () => {
  const order = new Order({ status: 'pending' });
  await order.startProcessing();
  expect(order.status).toBe('processing');
});

// Test case 2: RED — invalid transition throws
it('throws when attempting to ship a pending order', async () => {
  const order = new Order({ status: 'pending' });
  await expect(order.ship()).rejects.toThrow('Cannot ship: order is not processing');
});

// Test case 3: RED — idempotent guard (calling startProcessing twice is a defect)
it('throws on duplicate startProcessing call', async () => {
  const order = new Order({ status: 'pending' });
  await order.startProcessing();
  await expect(order.startProcessing()).rejects.toThrow('Cannot process: order is already processing');
});

// Test case 4: RED — concurrent calls to startProcessing (race guard)
it('handles concurrent startProcessing calls safely', async () => {
  const order = new Order({ status: 'pending' });
  const [result1, result2] = await Promise.allSettled([
    order.startProcessing(),
    order.startProcessing(),
  ]);
  const successes = [result1, result2].filter(r => r.status === 'fulfilled').length;
  const failures  = [result1, result2].filter(r => r.status === 'rejected').length;
  expect(successes).toBe(1);
  expect(failures).toBe(1);
  expect(order.status).toBe('processing');
});

// GREEN: implement Order with optimistic concurrency guard
export class Order {
  #status;
  #transitioning = false;

  constructor({ status }) { this.#status = status; }
  get status() { return this.#status; }

  async #transition(from, to, errorMsg) {
    if (this.#status !== from || this.#transitioning) {
      throw new Error(errorMsg ?? `Cannot transition from ${this.#status} to ${to}`);
    }
    this.#transitioning = true;
    try {
      await Promise.resolve(); // yield to microtask queue
      this.#status = to;
    } finally {
      this.#transitioning = false;
    }
  }

  startProcessing() { return this.#transition('pending', 'processing', 'Cannot process: order is already processing'); }
  ship()            { return this.#transition('processing', 'shipped',  'Cannot ship: order is not processing'); }
  deliver()         { return this.#transition('shipped',   'delivered', 'Cannot deliver: order is not shipped'); }
}
```

---

## When TDD Is Hard

### Legacy Code Without Seams

Legacy code often has no "seams" — places where you can inject test doubles. Global state, static method calls, `new` inside constructors, and direct filesystem/network calls make TDD almost impossible without first adding seams.

```javascript
// ------ BEFORE: untestable legacy — hard-coded dependency, no seam ------
export class OrderProcessor {
  async processOrder(orderId) {
    const db = new PostgresDatabase();          // hard dependency
    const order = await db.findOrder(orderId);
    if (order.status === 'pending') {
      await db.updateStatus(orderId, 'processing');
      new EmailClient().send(order.email, 'Your order is being processed');
    }
  }
}

// ------ AFTER: add a seam via constructor injection ------
export class OrderProcessor {
  constructor(db, mailer) {
    this.db = db;
    this.mailer = mailer;
  }

  async processOrder(orderId) {
    const order = await this.db.findOrder(orderId);
    if (order.status === 'pending') {
      await this.db.updateStatus(orderId, 'processing');
      await this.mailer.send(order.email, 'Your order is being processed');
    }
  }
}

// ------ TDD test case now possible using in-memory fakes ------
it('updates status and sends email when order is pending', async () => {
  const db = new InMemoryDatabase([
    { id: '42', status: 'pending', email: 'buyer@example.com' },
  ]);
  const mailer = new SpyMailer();
  const processor = new OrderProcessor(db, mailer);

  await processor.processOrder('42');

  const updated = await db.findOrder('42');
  expect(updated.status).toBe('processing');
  expect(mailer.sent).toHaveLength(1);
  expect(mailer.sent[0].to).toBe('buyer@example.com');
});
```

### Complex UI Interactions

UI tests are inherently integration tests. Pure TDD is awkward when the thing you are building is a drag-and-drop calendar.

**Practical approach:** Apply TDD to the logic layer (hooks, view models, reducers) and use snapshot or end-to-end tests for UI composition.

### Algorithm Discovery (Spike First)

When you are discovering an algorithm, you often do not know what the right answer is until you have run the code.

**Practical approach:** Spike first, identify the algorithm, extract it into a pure function, then apply TDD to the extracted function.

### Third-Party API Integration

You cannot write a failing unit test case for an API that does not exist in your codebase.

**Practical approach:** Wrap the third-party API in an adapter, test the adapter with contract test cases, and TDD everything else against the adapter's interface.

---

## Real-World Gotchas [community]

1. **[community] The test suite becomes a second codebase.** At scale, test cases need the same architectural discipline as production code. Teams that ignore test architecture end up with 30-minute test runs and test cases that are harder to change than the code they cover. WHY: test cases written against internal state instead of public behaviour require updates on every refactor, not just on behavioural change.

2. **[community] TDD slows down initial feature velocity — intentionally.** The first time you use TDD on a new domain, it will take longer. The payback is in the third and fourth sprint when you are changing code without fear. WHY: teams that measure only sprint velocity abandon TDD before the payback arrives.

3. **[community] Mocking at the wrong layer is the most common TDD mistake.** When you mock a database repository in a service test case, you are no longer testing whether the service and repository work together. WHY: a team whose mocked repository always returned sorted results masked a sort defect in the real DB adapter for six months.

4. **[community] "Outside-in TDD" (London School) and "inside-out TDD" (Chicago/Detroit School) produce different architectures.** Mixing the two produces incoherent test suites. WHY: outside-in starts with acceptance test cases and mocks collaborators; inside-out starts with domain objects and avoids mocks — the test doubles strategies are fundamentally incompatible when mixed.

5. **[community] Test case names are the most important documentation in a TDD codebase.** When a test case fails in CI, the name is the first signal. Names like `test1` or `renders correctly` are worthless; names like `throws when payment is attempted on a cancelled order` save hours. WHY: if you cannot understand the failure from the test case name alone, diagnosis time multiplies.

6. **[community] Over-specification (testing too much) is as harmful as under-testing.** Test cases that assert on every field in a response, exact error message strings, or internal call counts become fragile. WHY: they break on every change and erode trust in the test suite — a practical heuristic is: if a test case breaks when you refactor without changing behaviour, it is over-specified.

7. **[community] The Refactor phase is the most skipped step in practice.** Developers hit Green and move to the next test case. WHY: without continuous refactoring, TDD accumulates technical debt just as fast as no tests — it just has a safety net while doing so. Pairing helps: a partner asking "is this ready to refactor?" after every Green prevents phase-skipping.

8. **[community] Continuous Integration amplifies TDD's benefits — and its weaknesses.** A TDD codebase with long CI feedback cycles (> 10 minutes) loses most of its advantage. WHY: the tight loop that makes TDD valuable collapses when "run all tests" means waiting 40 minutes, and developers stop running the full test suite before pushing.

9. **[community] In JavaScript, module-level side effects break TDD isolation.** When a module executes code on import (establishing DB connections, starting timers), every test case that imports it inherits those side effects. WHY: this makes test cases order-dependent and slow.

```javascript
// BAD: module-level side effect
import pg from 'pg';
export const pool = new pg.Pool({ connectionString: process.env.DB_URL });

// GOOD: factory function — connection only created when explicitly called
import pg from 'pg';
let _pool = null;
export function getPool() {
  _pool ??= new pg.Pool({ connectionString: process.env.DB_URL });
  return _pool;
}
```

10. **[community] Property-based testing finds boundary defects that TDD misses.** TDD produces test cases from hand-picked examples; property-based tests (fast-check) generate hundreds of random examples. WHY: TDD test suites with 95%+ line coverage still miss edge cases at integer boundaries, empty collections, and Unicode input.

```javascript
import * as fc from 'fast-check';
import { calculateTotal } from './cart-logic.js';

describe('calculateTotal (property-based)', () => {
  it('never returns a negative total', () => {
    fc.assert(
      fc.property(
        fc.array(fc.record({
          price: fc.float({ min: 0, max: 10_000 }),
          qty: fc.integer({ min: 0, max: 999 }),
        })),
        (items) => calculateTotal(items, null) >= 0
      )
    );
  });
});
```

11. **[community] Snapshot test cases treated as TDD test cases erode test suite trust.** Teams that use `toMatchSnapshot()` as a primary assertion strategy run `--update-snapshots` automatically whenever tests fail. WHY: this creates a false-green test suite — the tests pass, but they are no longer verifying behaviour. Reserve snapshot testing for complex serialisable structures only.

12. **[community] Mutation testing reveals that high coverage ≠ good TDD.** Teams running Stryker against a TDD codebase with 90%+ line coverage routinely find mutation scores of 60–70% on first run. WHY: the gap represents test cases written to achieve coverage rather than to catch defects — a signal to revisit TDD discipline, not just add more test cases.

13. **[community] TCR (Test-and-Commit-or-Revert) is the fastest way to internalise baby-steps discipline.** Teams that run TCR for even one week report permanently smaller commit sizes and faster TDD cycles afterward, even after abandoning TCR itself. WHY: when you know failing tests revert your work, you instinctively start writing the smallest possible test case — the TDD discipline distilled to a physical constraint.

14. **[community] "Delete the tests and re-TDD" is a legitimate rescue technique for legacy test suites.** When a test suite is so tightly coupled to implementation that it prevents refactoring, experienced TDD practitioners sometimes recommend deleting the unit test cases, keeping only acceptance/integration tests as a safety net, and re-growing the unit test suite via TDD during the refactor. WHY: untangling hundreds of over-specified test cases takes longer than rebuilding them correctly.

15. **[community] TDD and linting/type tools are complementary, not redundant.** ESLint and JSDoc type checks catch structural errors; TDD catches behavioural errors. WHY: a function that lints cleanly can still return a wrong value. Teams sometimes stop writing test cases because "ESLint already catches that" — a false equivalence that leads to defect escapes at runtime.

---

## Tradeoffs & Alternatives

### When TDD Works Well
- Greenfield domain logic with clear inputs/outputs
- Business rule engines, calculators, state machines, parsers
- Public API design on new libraries — the test case IS the first consumer
- Highly collaborative teams where test cases as specification reduce ambiguity
- Long-lived codebases where the team changes frequently (test cases serve as living documentation)

### When TDD Is a Poor Fit
- Exploratory/research code — spike first, extract, then TDD the extracted function
- UI-heavy features with no extractable logic layer — prefer BDD acceptance test cases at the user story level
- Data migration scripts — one-run code; characterisation test cases before, smoke test after
- Time-critical hotfixes where confirming the failure mode matters more than building correctly
- Hardware interaction, driver code, or OS-level work where the test environment cannot simulate the target

### Known Adoption Costs
- **Learning curve:** Teams new to TDD typically see a 20–40% slowdown in the first 4–8 weeks.
- **Test infrastructure investment:** Fast unit test cases require dependency injection, seam-based design, and a test runner configured for parallelism — typically a 1–3 sprint investment.
- **Cultural resistance:** TDD requires discipline at the PR review level — reviewers must check that test cases were written first and that coverage is meaningful, not just present.
- **Pairing cost:** TDD's benefits are amplified with pair programming; solo TDD often drifts under deadline pressure.
- **Diminishing returns on very simple code:** TDD is most valuable on complex behaviour; enforcing it on simple glue code adds ceremony without proportional value.

### Lighter Alternatives

| Practice | When to prefer it |
|---|---|
| **Test-First (no refactor step)** | When you need specification benefits without full TDD discipline |
| **BDD / Spec by Example** | When the primary audience for test cases is non-technical stakeholders |
| **Property-Based Testing** | Complements TDD by generalising beyond hand-picked examples |
| **Characterisation Tests** | When working in legacy code before a large refactor |
| **Contract Testing** | When integrating third-party services or microservice boundaries |
| **Mutation Testing** | As a TDD audit: checks that test cases actually fail when production code is broken |

### TDD vs Test-First vs Test-After

| Practice | When test case is written | Design pressure | Cycle discipline |
|---|---|---|---|
| **TDD** | Before implementation | High — shapes the design | Red→Green→Refactor, strictly |
| **Test-First** | Before implementation | Medium | Red→Green only |
| **Test-After** | After implementation | None | No cycle |
| **BDD** | Acceptance level before, unit after | High at story level | Outside-in |

---

## ISTQB CTFL 4.0 Terminology Alignment

| ISTQB term | Common informal term | Notes in TDD context |
|-----------|---------------------|---------------------|
| **Test case** | "test", "spec", "it block" | An `it(...)` block in Vitest is a test case |
| **Test suite** | "test file", "test set" | A `describe(...)` block or a whole `.test.js` file |
| **Test object** | "thing under test", "SUT" | The class/function/module being exercised |
| **Test level** | "test layer" | TDD primarily operates at unit test level |
| **Test basis** | "requirements", "specs" | In TDD, the failing test case IS the test basis |
| **Defect** | "bug", "error" | TDD produces defects in the Red phase deliberately |
| **Test condition** | "test scenario" | The specific state + input combination a test case exercises |

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| *Test-Driven Development: By Example* — Kent Beck | Book | https://www.oreilly.com/library/view/test-driven-development/0321146530/ | The canonical TDD reference; covers red-green-refactor, fake-it, triangulation |
| TestDrivenDevelopment — Martin Fowler | Article | https://martinfowler.com/bliki/TestDrivenDevelopment.html | Concise definition, situates TDD in the broader testing landscape |
| TestFirst — Martin Fowler | Article | https://martinfowler.com/bliki/TestFirst.html | Distinguishes TDD (with refactor step) from test-first (without) |
| *Working Effectively with Legacy Code* — Feathers | Book | https://www.oreilly.com/library/view/working-effectively-with/0131177052/ | Seams, characterisation test cases for legacy codebases |
| *xUnit Test Patterns* — Meszaros | Book | https://xunitpatterns.com/ | Definitive reference for test doubles taxonomy |
| fast-check | Library | https://fast-check.io/ | JS property-based testing library that complements TDD |
| Vitest — official docs | Docs | https://vitest.dev/ | Primary test runner for modern JS projects |
| ISTQB CTFL 4.0 Syllabus | Certification | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative terminology reference |
