# Test-Driven Development (TDD) — QA Methodology Guide
<!-- lang: TypeScript | topic: tdd | iteration: 6 | score: 94/100 | date: 2026-04-26 -->

## Core Principles

Test-Driven Development is a software development practice where you write a failing test _before_ writing any production code, then write just enough code to make it pass, then refactor — repeating the cycle continuously.

Coined and popularised by Kent Beck as part of Extreme Programming (XP), TDD is often misunderstood as merely "writing tests early." It is primarily a **design discipline**: the act of writing a test first forces you to think about the API, the dependencies, and the expected behaviour before a single line of implementation exists.

### The Red-Green-Refactor Cycle

The canonical TDD loop has exactly three phases:

1. **Red** — Write a test that fails (and fails for the right reason: the code does not exist yet). If the test fails because of a compile error or a missing import, fix that first before calling it "Red." A test that cannot run is not a Red test; it is a broken test.
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

**Why it matters:** Fake-it forces the discipline of "write only enough to pass." It also validates that your test infrastructure works (the test runner, the assertion, the imports) before you invest in real logic. A test that runs and passes — even on a hardcoded value — is more valuable than a test that compiles but has never been seen to pass. Fake-it makes the Red→Green transition explicit and visible to a pair or reviewer.

```typescript
// ------ RED: write the first failing test ------
// The function doesn't exist yet; this test defines the expected API.
import { describe, it, expect } from 'vitest';
import { passwordStrength } from './passwordStrength';

describe('passwordStrength', () => {
  it('rates an empty string as "weak"', () => {
    expect(passwordStrength('')).toBe('weak');
  });
});

// ------ GREEN (fake it): minimal code to pass — hardcode the result ------
export function passwordStrength(_password: string): 'weak' | 'medium' | 'strong' {
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
export function passwordStrength(password: string): 'weak' | 'medium' | 'strong' {
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

- **The domain logic is non-trivial.** Business rules, calculations, state machines, and parsers benefit greatly.
- **The API boundary is not yet clear.** Writing the test first forces you to define it.
- **You are working in a codebase where regression risk is high.** The accumulating test suite becomes a living specification.
- **You are doing exploratory design.** TDD is a thinking tool, not just a testing tool.
- **The feedback loop from running tests is fast** (< 5 seconds for the relevant subset).

---

## Patterns

### Red-Green-Refactor Cycle

```typescript
// Step 1 — RED: write a failing test
import { describe, it, expect } from 'vitest';
import { ShoppingCart } from './ShoppingCart';

describe('ShoppingCart', () => {
  it('starts empty', () => {
    const cart = new ShoppingCart();
    expect(cart.total()).toBe(0);
  });
});

// Step 2 — GREEN: write minimal code
export class ShoppingCart {
  total(): number {
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
  private items: Array<{ price: number; qty: number }> = [];

  add(item: { price: number; qty: number }): void {
    this.items.push(item);
  }

  total(): number {
    return this.items.reduce((sum, i) => sum + i.price * i.qty, 0);
  }
}
```

### Baby Steps

```typescript
// ------ BAD: starting with a complex test that requires full implementation ------
it('applies tiered discounts, shipping caps, and coupon codes', () => {
  const cart = new Cart();
  cart.add({ sku: 'A', price: 60, qty: 2 });
  cart.applyCoupon('SAVE10');
  expect(cart.total()).toBe(98); // requires discount + coupon logic simultaneously
});

// ------ GOOD: baby steps — each test adds exactly one new behaviour ------

// Step 1: empty cart returns 0 (defines the type signature and constructor)
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
describe('formatCurrency', () => {
  it('formats 10 USD', () => {
    expect(formatCurrency(10, 'USD')).toBe('$10.00');
  });
});

// Minimal GREEN — just make it pass with a constant:
export function formatCurrency(_amount: number, _currency: string): string {
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

Before writing any implementation code, write the test as if the ideal API already exists. If the test feels awkward to write, the API is awkward to use. This is a signal to redesign.

```typescript
// Good API discovered through test-first
it('sends a welcome email', async () => {
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

---

## When TDD Is Hard

### Legacy Code Without Seams

Legacy code that was not written test-first often has no "seams" — places where you can inject test doubles. Global state, static method calls, `new` inside constructors, and direct filesystem/network calls make TDD almost impossible without first adding seams (Extract Interface, Parameterise Constructor, Wrap and Inject).

**Practical approach:** Use Michael Feathers' "characterisation tests" to capture existing behaviour before refactoring toward testability.

```typescript
// ------ BEFORE: untestable legacy — hard-coded dependency, no seam ------
class OrderProcessor {
  async processOrder(orderId: string): Promise<void> {
    const db = new PostgresDatabase();          // hard dependency, can't swap
    const order = await db.findOrder(orderId);  // real DB call in every test
    if (order.status === 'pending') {
      await db.updateStatus(orderId, 'processing');
      new EmailClient().send(order.email, 'Your order is being processed');
    }
  }
}

// ------ AFTER: add a seam via constructor injection ------
interface Database {
  findOrder(id: string): Promise<Order>;
  updateStatus(id: string, status: string): Promise<void>;
}
interface Mailer {
  send(to: string, body: string): Promise<void>;
}

class OrderProcessor {
  constructor(private db: Database, private mailer: Mailer) {}

  async processOrder(orderId: string): Promise<void> {
    const order = await this.db.findOrder(orderId);
    if (order.status === 'pending') {
      await this.db.updateStatus(orderId, 'processing');
      await this.mailer.send(order.email, 'Your order is being processed');
    }
  }
}

// ------ TDD test now possible using in-memory fakes ------
it('updates status and sends email when order is pending', async () => {
  const db: Database = new InMemoryDatabase([
    { id: '42', status: 'pending', email: 'buyer@example.com' },
  ]);
  const mailer: Mailer = new SpyMailer();
  const processor = new OrderProcessor(db, mailer);

  await processor.processOrder('42');

  expect(await db.findOrder('42')).toMatchObject({ status: 'processing' });
  expect((mailer as SpyMailer).sent).toHaveLength(1);
});
```

### Complex UI Interactions

UI tests are inherently integration tests. The render→interact→assert cycle is slower than unit tests and flaky at the edges. Pure TDD (tiny failing unit test first) is awkward when the thing you are building is a drag-and-drop calendar.

**Practical approach:** Apply TDD to the logic layer (hooks, view models, reducers) and use snapshot or end-to-end tests for UI composition, not pure TDD.

### Algorithm Discovery (Spike First)

When you are discovering an algorithm — numerical methods, machine learning pipelines, novel data structure implementations — you often do not know what the right answer is until you have run the code. Writing a failing test first is impossible when you do not yet know what "passing" looks like.

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

5. **[community] Test names are the most important documentation in a TDD codebase.** When a test fails in CI, the name is the first signal. Names like `test1` or `renders correctly` are worthless; names like `throws InvalidStateError when payment is attempted on a cancelled order` save hours. A good rule: if you cannot understand the failure from the test name alone, rename it before fixing it.

6. **[community] Over-specification (testing too much) is as harmful as under-testing.** Tests that assert on every field in a response, exact error message strings, or internal call counts become fragile. They break on every change and erode trust in the test suite. A practical heuristic: if a test breaks when you refactor without changing behaviour, it is over-specified.

7. **[community] The refactor phase is the most skipped step in practice.** Developers hit Green and move to the next test. Without continuous refactoring, TDD accumulates technical debt just as fast as no tests — it just has a safety net while doing so. Pairing helps: a partner asking "is this ready to refactor?" after every Green prevents phase-skipping.

8. **[community] Continuous Integration amplifies TDD's benefits.** A TDD codebase with long CI feedback cycles (>10 minutes) loses most of its advantage. The tight loop that makes TDD valuable collapses when "run all tests" means waiting 40 minutes. Teams that adopt TDD without also parallelising CI end up with developers not running the full suite before pushing.

9. **[community] TDD and type systems are complementary, not redundant.** TypeScript types catch structural errors; TDD catches behavioural errors. A function that type-checks perfectly can still return a wrong value. Teams sometimes stop writing tests because "TypeScript already catches that" — a false equivalence. Types narrow the solution space; tests pin specific expected behaviours.

10. **[community] "Delete the tests and re-TDD" is a legitimate rescue technique for legacy test suites.** When a test suite is so tightly coupled to implementation that it prevents refactoring, experienced TDD practitioners sometimes recommend deleting the unit tests, keeping only acceptance/integration tests as a safety net, and re-growing the unit test suite via TDD during the refactor. This is painful but faster than untangling hundreds of over-specified tests.

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

- Kent Beck, *Test-Driven Development: By Example* (2002) — the canonical reference
- Martin Fowler, [TestDrivenDevelopment](https://martinfowler.com/bliki/TestDrivenDevelopment.html) — concise definition and context
- Martin Fowler, [TestFirst](https://martinfowler.com/bliki/TestFirst.html) — TDD vs test-first distinction
- Michael Feathers, *Working Effectively with Legacy Code* (2004) — seams and characterisation tests
- Justin Searls / Test Double, [Contributing Tests Wiki](https://github.com/testdouble/contributing-tests/wiki/Test-Driven-Development) — pragmatic TDD in modern JS/TS
- Robert C. Martin, *Clean Code* Ch. 9 — unit test guidelines
- Gary Bernhardt, *Boundaries* (talk) — functional core / imperative shell, reduces mocking need
