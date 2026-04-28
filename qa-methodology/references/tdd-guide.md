# Test-Driven Development (TDD) — QA Methodology Guide
<!-- lang: JavaScript | topic: tdd | iteration: 3 | score: 100/100 | date: 2026-04-27 -->

## Core Principles

Test-Driven Development is a software development practice where you write a failing test _before_ writing any production code, then write just enough code to make it pass, then refactor — repeating the cycle continuously.

Coined and popularised by Kent Beck as part of Extreme Programming (XP), TDD is often misunderstood as merely "writing tests early." It is primarily a **design discipline**: the act of writing a test first forces you to think about the API, the dependencies, and the expected behaviour before a single line of implementation exists.

### The Red-Green-Refactor Cycle

The canonical TDD loop has exactly three phases:

1. **Red** — Write a test that fails (and fails for the right reason: the code does not exist yet). If the test fails because of a missing import, fix that first before calling it "Red." A test that cannot run is not a Red test; it is a broken test.
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

**Why it matters:** Fake-it forces the discipline of "write only enough to pass." It also validates that your test infrastructure works (the test runner, the assertion, the imports) before you invest in real logic. A test that runs and passes — even on a hardcoded value — is more valuable than a test that compiles but has never been seen to pass.

```javascript
// ------ RED: write the first failing test ------
// The function doesn't exist yet; this test defines the expected API.
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
  return 'weak'; // hardcoded; passes the single test, nothing more
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

Writing a test first forces you to consume your own API before it exists. This surfaces awkward constructor signatures, missing abstractions, and overly coupled designs before they are expensive to fix. Code that is hard to test is almost always hard to use.

**Why this is the most underrated benefit of TDD:** The feedback is immediate and concrete. If you cannot write a clean arrange/act/assert for a function you are about to build, the function's interface is wrong. This is cheaper to fix before any implementation exists than after. Teams that skip TDD often discover API problems only at integration time — the most expensive phase to redesign.

A useful heuristic from the TDD community: "If the test setup is complex, the code is complex." A test requiring five `new` statements in Arrange is a five-dependency code smell visible before you write a single line of production code.

### TDD vs Test-First vs Test-After

| Practice | When test is written | Design pressure | Refactoring safety net | Cycle discipline |
|---|---|---|---|---|
| **TDD** | Before implementation | High — shapes the design | Yes — tests already exist | Red→Green→Refactor, strictly |
| **Test-First** | Before implementation | Medium — specifies behaviour | Yes | Red→Green only (no mandatory refactor) |
| **Test-After** | After implementation | None — tests conform to the code | Yes, but late | No cycle; tests written post-facto |
| **BDD** | Acceptance level before, unit after | High at story level | Yes | Outside-in, from acceptance to unit |

**Why these distinctions matter:**

- TDD without the Refactor step degrades into test-first: you get a safety net but not continuous design improvement.
- Test-after is not TDD: the code was designed without test pressure, so tests often must contort to reach internal state rather than testing public behaviour.
- BDD (Behaviour-Driven Development) extends TDD's design feedback to a higher level — acceptance criteria become the outermost failing "test" that drives TDD cycles down through the implementation stack (the "double loop" or "outside-in" approach).

---

## When to Use

TDD works best when:

- **The domain logic is non-trivial.** Business rules, calculations, state machines, and parsers benefit greatly. The more complex the logic, the more the design feedback from writing tests first pays off.
- **The API boundary is not yet clear.** Writing the test first forces you to define it — TDD is the cheapest API review tool available.
- **You are working in a codebase where regression risk is high.** The accumulating test suite becomes a living specification. Teams maintaining long-lived codebases (3+ years) consistently cite TDD's regression safety as its primary value.
- **You are doing exploratory design.** TDD is a thinking tool, not just a testing tool. The act of writing a test for code that doesn't exist yet forces design decisions that would otherwise be deferred.
- **The feedback loop from running tests is fast** (< 5 seconds for the relevant subset). TDD's value collapses when running tests takes minutes — invest in test parallelisation before adopting TDD on a slow suite.
- **The team has or is building TDD muscle memory.** TDD practised without experience is slower for 4–8 weeks. It pays back in reduced debugging time and confident refactoring. Teams without TDD experience benefit from kata practice before applying it to production code.
- **Pair programming or strong code review culture exists.** TDD disciplines (especially the refactor step) are most consistently maintained when someone is watching. Solo TDD frequently drifts into test-after under deadline pressure.

---

## Patterns

### Red-Green-Refactor Cycle

```javascript
// Step 1 — RED: write a failing test
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
    return 0; // fake it — only one test so far
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
// ------ BAD: starting with a complex test that requires full implementation ------
it('applies tiered discounts, shipping caps, and coupon codes', () => {
  const cart = new Cart();
  cart.add({ sku: 'A', price: 60, qty: 2 });
  cart.applyCoupon('SAVE10');
  expect(cart.total()).toBe(98); // requires discount + coupon logic simultaneously
});

// ------ GOOD: baby steps — each test adds exactly one new behaviour ------

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
// formatCurrency.js
export function formatCurrency(_amount, _currency) {
  return '$10.00'; // hardcoded; passes the first test, nothing more
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
export function formatCurrency(amount, currency) {
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

Before writing any implementation code, write the test as if the ideal API already exists. If the test feels awkward to write, the API is awkward to use. This is a signal to redesign.

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
// The test reveals: OnboardingService needs a mailer dependency injected.
// Without TDD, mailer might have been a module-level import — untestable.
```

### Double-Loop TDD (Outside-In / London School) [community]

Outside-in TDD (also called the "London School" or "Mockist" style) drives implementation from acceptance tests inward to unit tests. The outer loop is a failing acceptance/integration test (the full user-visible behaviour); the inner loop is the classic red-green-refactor cycle for each collaborating object discovered along the way.

This approach is favoured in teams doing BDD or building layered architectures (HTTP handler → service → repository) because it ensures every unit of code is created in response to a real user need, not speculated future need.

```javascript
// ---- OUTER LOOP: failing acceptance test (Supertest for an Express route) ----
// This test stays RED until the entire feature is implemented.
import request from 'supertest';
import { app } from '../app.js';

describe('POST /users/register (acceptance)', () => {
  it('returns 201 and sends a welcome email', async () => {
    const res = await request(app)
      .post('/users/register')
      .send({ email: 'alice@example.com', name: 'Alice' });

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ id: expect.any(String) });
    // Email assertion via a test spy on the transport layer
    expect(emailTransportSpy.calls).toHaveLength(1);
    expect(emailTransportSpy.calls[0].to).toBe('alice@example.com');
  });
});

// ---- INNER LOOP: TDD for UserService discovered by the acceptance test ----
// Each collaborator (UserService, UserRepository, EmailService) is TDD'd separately.
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

The outer acceptance test is only deleted when it passes — meaning all inner TDD cycles have completed and the feature works end-to-end. This prevents the common failure mode of "all unit tests pass but the feature is broken."

### TDD Inner Loop with Vitest Watch Mode (JavaScript)

The TDD cycle depends on a fast, always-on test feedback loop. In JavaScript projects using Vite or modern bundlers, Vitest's `--watch` mode provides near-instant re-runs on file save, making the Red-Green-Refactor cycle tactile and immediate.

```javascript
// vitest.config.js — optimised for TDD inner loop
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Run related tests immediately on file change (default in watch mode)
    watch: false, // use `vitest --watch` from CLI; false here for CI

    // Show test name in real time — important for red/green visibility
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

# Run tests matching a pattern (useful when drilling into one failing test)
npx vitest --watch -t "totals one item"
```

The `bail: 1` setting is intentional during TDD: seeing one red test name clearly is more valuable than seeing ten failures scroll by. When CI runs the full suite, remove `bail` to get a complete picture of breakage.

### Functional Core / Imperative Shell (TDD-Friendly Architecture) [community]

The hardest part of TDD is managing side effects (I/O, network, time). Gary Bernhardt's "Functional Core, Imperative Shell" architecture separates pure decision logic (easy to TDD) from side-effectful orchestration (hard to TDD). The core is a set of pure functions — all inputs explicit, all outputs return values. The shell is thin: it reads from the world, calls the core, writes results back.

```javascript
// ---- FUNCTIONAL CORE: pure, no I/O — easy to TDD with zero mocking ----
// cart-logic.js
// All business rules live here; this is where TDD provides maximum leverage.

export function applyDiscount(subtotal, discount) {
  if (discount.type === 'pct') return subtotal * (1 - discount.value / 100);
  return Math.max(0, subtotal - discount.value);
}

export function calculateTotal(items, discount) {
  const subtotal = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  return discount ? applyDiscount(subtotal, discount) : subtotal;
}

// TDD tests for the pure core — no mocks, no async, no setup boilerplate
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
// I/O lives here; it is tested at the HTTP/integration level, not unit-TDD'd.
// checkout-handler.js
import { calculateTotal } from './cart-logic.js';

export async function checkoutHandler(req, db) {
  const items = await db.getCartItems(req.userId);         // I/O
  const coupon = await db.findCoupon(req.body.couponCode); // I/O
  const total = calculateTotal(items, coupon?.discount ?? null); // pure core
  await db.createOrder({ userId: req.userId, total });     // I/O
  return { status: 201, body: { total } };
}
```

---

## Anti-Patterns

| Anti-Pattern | Why It Hurts |
|---|---|
| **Writing tests after the fact to hit coverage** | No design benefit; tests often mirror implementation rather than specifying behaviour |
| **Testing implementation details** | Tests break on every refactor; defeats the purpose of the refactor phase |
| **Giant test setup** | If arrange phase is enormous, the design has too many dependencies — a design smell |
| **Skipping the Refactor phase** | Leads to test-covered spaghetti; TDD without refactoring accumulates design debt |
| **Testing one big thing per cycle** | If a cycle takes hours, feedback is slow; baby steps are the cure |
| **Mocking everything** | Over-mocking produces tests that pass even when the real system is broken |
| **Writing tests for trivial getters/setters** | Adds noise with no signal; focus on behaviour, not data containers |

### Anti-Pattern Deep Dive: Testing Implementation Details

This is the most common reason TDD's "refactoring safety net" fails in practice. When tests assert on private fields, internal call sequences, or exact mock invocation counts rather than observable outputs, every internal rename or restructure breaks the tests — the opposite of what TDD promises.

```javascript
// BAD: testing implementation details — breaks on any internal rename
describe('UserService', () => {
  it('calls repository.save exactly once', async () => {
    const repo = { save: vi.fn(), findByEmail: vi.fn() };
    const service = new UserService(repo);
    await service.createUser({ email: 'a@b.com', name: 'A' });
    // This asserts HOW, not WHAT — brittle
    expect(repo.save).toHaveBeenCalledTimes(1);
    expect(repo.save).toHaveBeenCalledWith(
      expect.objectContaining({ email: 'a@b.com' })
    );
  });
});

// GOOD: test observable output — survives internal restructuring
describe('UserService', () => {
  it('creates and persists a user', async () => {
    const repo = new InMemoryUserRepository(); // real fake, not a mock
    const service = new UserService(repo);

    const user = await service.createUser({ email: 'a@b.com', name: 'A' });

    // Assert WHAT, not HOW: the user exists in the store
    expect(await repo.findByEmail('a@b.com')).toMatchObject({
      id: user.id,
      email: 'a@b.com',
    });
  });
});
```

### Anti-Pattern Deep Dive: Giant Test Setup

When the Arrange phase of a test requires more code than the Act+Assert phases combined, it is signalling that the production code has too many dependencies to construct. This is a TDD design signal to act on immediately.

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
  // ... actual test is one line long
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

---

## When TDD Is Hard

### Legacy Code Without Seams

Legacy code that was not written test-first often has no "seams" — places where you can inject test doubles. Global state, static method calls, `new` inside constructors, and direct filesystem/network calls make TDD almost impossible without first adding seams (Extract Interface, Parameterise Constructor, Wrap and Inject).

**Practical approach:** Use Michael Feathers' "characterisation tests" to capture existing behaviour before refactoring toward testability.

```javascript
// ------ BEFORE: untestable legacy — hard-coded dependency, no seam ------
// order-processor.js
import { PostgresDatabase } from './db/postgres.js';
import { EmailClient } from './email/client.js';

export class OrderProcessor {
  async processOrder(orderId) {
    const db = new PostgresDatabase();          // hard dependency, can't swap
    const order = await db.findOrder(orderId);  // real DB call in every test
    if (order.status === 'pending') {
      await db.updateStatus(orderId, 'processing');
      new EmailClient().send(order.email, 'Your order is being processed');
    }
  }
}

// ------ AFTER: add a seam via constructor injection ------
// The interfaces are now implicit (duck-typed) — both db and mailer are injected
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

// ------ TDD test now possible using in-memory fakes ------
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

UI tests are inherently integration tests. The render→interact→assert cycle is slower than unit tests and flaky at the edges. Pure TDD (tiny failing unit test first) is awkward when the thing you are building is a drag-and-drop calendar.

**Practical approach:** Apply TDD to the logic layer (hooks, view models, reducers) and use snapshot or end-to-end tests for UI composition, not pure TDD.

### Algorithm Discovery (Spike First)

When you are discovering an algorithm — numerical methods, novel data structure implementations — you often do not know what the right answer is until you have run the code. Writing a failing test first is impossible when you do not yet know what "passing" looks like.

**Practical approach:** Spike first (write exploratory code without tests), identify the algorithm, extract it into a pure function, then apply TDD to the extracted function.

### Third-Party API Integration

You cannot write a failing unit test for an API that does not exist in your codebase. The test would either hit the real service (slow, expensive, non-deterministic) or require a mock you build before you understand the API.

**Practical approach:** Wrap the third-party API in an adapter, test the adapter with contract tests, and TDD everything else against the adapter's interface.

---

## Real-World Gotchas [community]

1. **[community] The test suite becomes a second codebase.** At scale, tests need the same architectural discipline as production code. Teams that ignore test architecture end up with 30-minute test runs and tests that are harder to change than the code they cover. A recurring pattern: a 5-year-old TDD project where renaming a domain concept requires changing 400 test files because tests were written against internal state instead of public behaviour.

2. **[community] TDD slows down initial feature velocity — intentionally.** The first time you use TDD on a new domain, it will take longer. The payback is in the third and fourth sprint when you are changing code without fear. Teams that measure only sprint velocity abandon TDD before the payback arrives. A common failure mode: management sees a slowdown after two weeks and declares "TDD doesn't work here."

3. **[community] Mocking at the wrong layer is the most common TDD mistake.** When you mock a database repository in a service test, you are no longer testing whether the service and repository work together. Prefer in-memory fakes for persistence and use contract tests to validate the real adapter separately. Production example: a team whose mocked repository always returned sorted results, masking a sort bug in the real DB adapter for six months.

4. **[community] "Outside-in TDD" (London School) and "inside-out TDD" (Chicago/Detroit School) produce different architectures.** Outside-in starts with acceptance tests and mocks collaborators; inside-out starts with domain objects and avoids mocks. Mixing the two produces incoherent test suites. Teams must align on one school before starting a project — retrofitting is expensive.

5. **[community] Test names are the most important documentation in a TDD codebase.** When a test fails in CI, the name is the first signal. Names like `test1` or `renders correctly` are worthless; names like `throws when payment is attempted on a cancelled order` save hours. A good rule: if you cannot understand the failure from the test name alone, rename it before fixing it.

6. **[community] Over-specification (testing too much) is as harmful as under-testing.** Tests that assert on every field in a response, exact error message strings, or internal call counts become fragile. They break on every change and erode trust in the test suite. A practical heuristic: if a test breaks when you refactor without changing behaviour, it is over-specified.

7. **[community] The refactor phase is the most skipped step in practice.** Developers hit Green and move to the next test. Without continuous refactoring, TDD accumulates technical debt just as fast as no tests — it just has a safety net while doing so. Pairing helps: a partner asking "is this ready to refactor?" after every Green prevents phase-skipping.

8. **[community] Continuous Integration amplifies TDD's benefits.** A TDD codebase with long CI feedback cycles (>10 minutes) loses most of its advantage. The tight loop that makes TDD valuable collapses when "run all tests" means waiting 40 minutes. Teams that adopt TDD without also parallelising CI end up with developers not running the full suite before pushing.

9. **[community] TDD and linting/type tools are complementary, not redundant.** ESLint and JSDoc type checks catch structural errors; TDD catches behavioural errors. A function that lints cleanly can still return a wrong value. Teams sometimes stop writing tests because "ESLint already catches that" — a false equivalence. Lint narrows the solution space; tests pin specific expected behaviours.

10. **[community] "Delete the tests and re-TDD" is a legitimate rescue technique for legacy test suites.** When a test suite is so tightly coupled to implementation that it prevents refactoring, experienced TDD practitioners sometimes recommend deleting the unit tests, keeping only acceptance/integration tests as a safety net, and re-growing the unit test suite via TDD during the refactor. This is painful but faster than untangling hundreds of over-specified tests.

11. **[community] In JavaScript, module-level side effects break TDD isolation.** When a module executes code on import (establishing DB connections, starting timers, reading env vars), every test that imports it inherits those side effects. This makes tests order-dependent and slow. The fix: export factory functions instead of module-level singletons, and initialise lazily or via explicit `init()` calls.

```javascript
// BAD: module-level side effect — executes on every import in every test
// db.js
import pg from 'pg';
export const pool = new pg.Pool({ connectionString: process.env.DB_URL });
// Every test that imports anything that imports db.js opens a real connection.

// GOOD: factory function — connection only created when explicitly called
// db.js
import pg from 'pg';
let _pool = null;
export function getPool() {
  _pool ??= new pg.Pool({ connectionString: process.env.DB_URL });
  return _pool;
}
// Tests inject InMemoryDatabase instead; real pool never created during tests.
```

---

## Tradeoffs & Alternatives

### When TDD Works Well
- Greenfield domain logic with clear inputs/outputs
- Business rule engines, calculators, state machines, parsers
- Public API design on new libraries — the test IS the first consumer
- Highly collaborative teams where specs-as-tests reduce ambiguity
- Long-lived codebases where the team changes frequently (tests serve as living documentation)
- Safety-critical systems where regression risk is existential

### When TDD is a Poor Fit
- Exploratory/research code — you cannot write a failing test for a technique you have not discovered yet (spike first, extract, then TDD the extracted function)
- UI-heavy features with no extractable logic layer — prefer BDD acceptance tests at the user story level
- Data migration scripts — one-run code; characterisation tests before, smoke test after
- Time-critical hotfixes where confirming the failure mode matters more than building correctly (write the fix, write the regression test in the same commit)
- Hardware interaction, driver code, or OS-level work where the test environment cannot simulate the target

### Known Adoption Costs
- **Learning curve:** Teams new to TDD typically see a 20–40% slowdown in the first 4–8 weeks. The slowdown is not permanent; it reflects the time needed to learn to write testable code, not a fundamental overhead of TDD.
- **Test infrastructure investment:** Fast unit tests require dependency injection, seam-based design, and a test runner configured for parallelism. This is typically a 1–3 sprint investment at the start of a project.
- **Cultural resistance:** TDD requires discipline at the PR review level — reviewers must check that tests were written first and that coverage is meaningful, not just present. Coverage-as-a-metric without test-quality enforcement produces "test theatre."
- **Pairing cost:** TDD's benefits are amplified with pair programming. Teams that adopt TDD solo often drift from the discipline under deadline pressure. Pairing provides accountability for all three phases.
- **Diminishing returns on very simple code:** TDD is most valuable on complex behaviour. Enforcing it on simple glue code (framework adapters, DTOs, configuration loaders) adds ceremony without proportional value.

### Lighter Alternatives
| Practice | When to prefer it |
|---|---|
| **Test-First (no refactor step)** | When you need specification benefits without full TDD discipline |
| **BDD / Spec by Example** | When the primary audience for tests is non-technical stakeholders |
| **Property-Based Testing** | When you want to generalise beyond hand-picked examples (complements, not replaces, TDD) |
| **Characterisation Tests** | When working in legacy code before a large refactor — capture current behaviour |
| **Contract Testing** | When integrating third-party services or microservice boundaries |
| **Mutation Testing** | As a TDD audit: checks that tests actually fail when production code is broken |

### TDD Adoption Strategies That Work
- **Kata practice first:** Have the team practice TDD on coding katas (FizzBuzz, Roman Numerals, Bowling) before applying it to production code. This builds muscle memory in a low-stakes context.
- **Greenfield-first adoption:** Start TDD on new services/modules, not on existing legacy code. The early wins build confidence.
- **Test-after as a bridge:** For teams struggling with strict TDD, test-after with mandatory refactoring is a useful intermediate step. It builds the habit of having tests before shipping, then gradually moves the test earlier.
- **TCR (Test-and-Commit-or-Revert):** An extreme discipline where passing tests automatically commit, failing tests automatically revert. Forces extremely small steps; used by Kent Beck himself to build TDD discipline.

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| *Test-Driven Development: By Example* — Kent Beck | Book | https://www.oreilly.com/library/view/test-driven-development/0321146530/ | The canonical TDD reference; covers red-green-refactor, fake-it, triangulation with original Java examples |
| TestDrivenDevelopment — Martin Fowler | Article | https://martinfowler.com/bliki/TestDrivenDevelopment.html | Concise definition, situates TDD in the broader testing landscape |
| TestFirst — Martin Fowler | Article | https://martinfowler.com/bliki/TestFirst.html | Distinguishes TDD (with refactor step) from test-first (without); useful for precise team communication |
| *Working Effectively with Legacy Code* — Michael Feathers | Book | https://www.oreilly.com/library/view/working-effectively-with/0131177052/ | Essential for applying TDD to untestable legacy codebases; defines seams, characterisation tests |
| Contributing Tests Wiki — Test Double / Justin Searls | Wiki | https://github.com/testdouble/contributing-tests/wiki/Test-Driven-Development | Pragmatic TDD guidance in modern JS; covers London vs Chicago schools and real adoption patterns |
| *Clean Code* Ch. 9 — Robert C. Martin | Book chapter | https://www.oreilly.com/library/view/clean-code-a/9780136083238/ | Unit test guidelines, F.I.R.S.T. principles, keeping tests clean as production code |
| *Boundaries* talk — Gary Bernhardt | Conference talk | https://www.destroyallsoftware.com/talks/boundaries | Functional core / imperative shell architecture; explains how to structure code to minimize mocking need |
| Vitest — official docs | Docs | https://vitest.dev/ | Primary Vite-native test runner for modern JS projects; watch mode, coverage, snapshot support |
| Jest — official docs | Docs | https://jestjs.io/ | Widely-used JS test runner; batteries-included with mocking, coverage, and snapshot support |
