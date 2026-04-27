# Test Isolation — QA Methodology Guide
<!-- lang: TypeScript | topic: test-isolation | iteration: 4 | score: 100/100 | date: 2026-04-26 -->
<!-- Sources: synthesized from training knowledge (WebFetch blocked, WebSearch unavailable) -->
<!-- Primary references: martinfowler.com/bliki/UnitTest.html, xunitpatterns.com/Four Phase Test, -->
<!--                     Google Testing Blog, Jest/Vitest docs, community production experience   -->

---

## Core Principles

### 1. FIRST: The five properties every isolated test must have

**F — Fast.** Tests should execute in milliseconds. Slow tests discourage frequent runs, which delays
feedback. A suite of 10,000 unit tests should complete in under 30 seconds. If a test is slow, it
usually means it is touching real I/O, a database, or a network — a sign of broken isolation.

**I — Independent.** No test should depend on the outcome or side-effects of another test. Tests
must be runnable in any order and in parallel without changing results. Order-dependency is the most
insidious form of hidden shared state.

**R — Repeatable.** The same test run on the same code must always produce the same result,
regardless of time, environment, operating system, timezone, or run order. Non-repeatability is the
definition of a flaky test and the primary reason CI pipelines lose team trust.

**S — Self-validating.** Each test must produce a binary pass/fail result that requires no human
interpretation. A test that requires you to read a log file to decide whether it passed has failed
this criterion.

**T — Timely.** Tests should be written at the same time as (or before) the production code they
cover. Tests written months after the fact often miss edge cases and reflect assumptions baked into
the implementation rather than the original specification.

### 2. Arrange-Act-Assert (AAA)

The AAA pattern structures every test into three distinct, non-interleaved phases:

- **Arrange** — set up the system under test (SUT), its dependencies, and any preconditions.
- **Act** — invoke exactly one behavior on the SUT.
- **Assert** — verify the outcome. A single logical assertion per test makes failure diagnosis fast.

Mixing phases (e.g., acting inside arrange, or asserting inside teardown) obscures the intent and
makes failing tests harder to debug.

### 3. Test fixture setup and teardown

A *test fixture* is the set of preconditions under which a test runs. Proper fixture management
means every test starts from a known-good state and cleans up after itself — not relying on the
previous test having run (or not having run). In Jest/Vitest: `beforeEach`/`afterEach` for per-test
fixtures, `beforeAll`/`afterAll` for expensive setup shared within a describe block (use sparingly).

### 4. Shared mutable state as the root cause of flakiness

The single most common cause of flaky tests is **shared mutable state**: module-level singletons,
global variables, static properties, shared database rows, shared in-memory caches, or environment
variables mutated by one test and read by another. Flakiness caused by shared state is particularly
dangerous because it often only surfaces under parallel execution or after suite restructuring.

### 5. Test doubles and dependency injection as isolation enablers

Replacing real collaborators (databases, HTTP clients, clocks, random number generators) with
controlled fakes, stubs, or mocks is the mechanical mechanism that makes FIRST achievable. Dependency
injection — passing collaborators in rather than importing singletons — is the design pattern that
makes test doubles practical.

### 6. Solitary vs. sociable unit tests — choosing the isolation boundary

Martin Fowler distinguishes two styles of unit tests:

- **Solitary** — replaces all collaborators with test doubles. The SUT runs in complete isolation.
  Maximum determinism; any failure points directly to the SUT. Trades off fidelity: the doubles may
  not accurately model real collaborator behavior.
- **Sociable** — lets the SUT exercise real collaborators (e.g., pure helper functions, value
  objects, data-transformation utilities). No test doubles for internal collaborators; only external
  I/O (DB, HTTP, clock) is replaced.

Neither style is universally better. Solitary tests are preferred for stateful, side-effectful, or
externally-coupled code. Sociable tests are preferred for pure-logic chains where the real
collaborators are fast, deterministic, and free of external I/O. The key: choose one style
*deliberately* per test, not by accident.

---

## When to Use

**Always:** Every project with automated tests benefits from these principles. Test isolation is not
optional — it is the foundation that makes the entire test suite trustworthy.

**Especially critical when:**
- Running tests in CI with parallelism or sharding (order-dependency and shared state fail loudly)
- Multiple engineers contribute tests to the same suite (naming collisions, fixture contamination)
- The test suite has grown beyond ~500 tests and flakiness is already appearing
- Using Jest's `--runInBand` is the only way to make the suite pass (red flag: hidden shared state)

**Maturity level:** Applicable from day 1 of a project. No prior testing maturity required.

---

## Patterns

### Pattern 1: Arrange-Act-Assert with explicit phases

Each phase is separated by a blank line and never interleaved. The Act phase contains exactly one
call. The Assert phase verifies the outcome of that single call.

```typescript
import { calculateDiscount } from './pricing';

describe('calculateDiscount', () => {
  it('applies 20% discount when customer is premium and cart exceeds $100', () => {
    // Arrange
    const customer = { tier: 'premium' };
    const cartTotal = 150.00;

    // Act
    const discounted = calculateDiscount(customer, cartTotal);

    // Assert
    expect(discounted).toBeCloseTo(120.00, 2);
  });

  it('applies no discount when customer is standard regardless of cart size', () => {
    // Arrange
    const customer = { tier: 'standard' };
    const cartTotal = 500.00;

    // Act
    const discounted = calculateDiscount(customer, cartTotal);

    // Assert
    expect(discounted).toBe(500.00);
  });
});
```

### Pattern 2: beforeEach fixture reset — eliminating shared mutable state  [community]

Never share a mutable object across tests inside a `describe` block. Declare the reference in
`describe` scope but re-initialize it inside `beforeEach`. This pattern is the most impactful
single change teams make when eliminating flakiness from an existing suite.

```typescript
import { ShoppingCart } from './ShoppingCart';
import { Product } from './Product';

describe('ShoppingCart', () => {
  // Declared at describe scope — but reset every test
  let cart: ShoppingCart;

  beforeEach(() => {
    // Fresh instance per test: no leftover items from a previous test
    cart = new ShoppingCart();
  });

  it('starts empty', () => {
    expect(cart.itemCount()).toBe(0);
  });

  it('adds a product and increases item count', () => {
    const product: Product = { id: 'p1', name: 'Widget', price: 9.99 };

    cart.add(product);

    expect(cart.itemCount()).toBe(1);
  });

  it('removes a product by id', () => {
    const product: Product = { id: 'p2', name: 'Gadget', price: 19.99 };
    cart.add(product);

    cart.remove('p2');

    expect(cart.itemCount()).toBe(0);
  });
});
```

### Pattern 3: Dependency injection + Jest mock for time-dependent behavior  [community]

Clock-dependent code (`Date.now()`, `new Date()`, `setTimeout`) is a classic source of
non-repeatable tests. Inject a clock abstraction and provide a controlled fake in tests. Using
`jest.useFakeTimers()` as a per-test setup (with `afterEach(() => jest.useRealTimers())`) isolates
timer state between tests.

```typescript
// production code — clock injected, not imported
export interface Clock {
  now(): number;
}

export function isWithinBusinessHours(clock: Clock): boolean {
  const hour = new Date(clock.now()).getHours();
  return hour >= 9 && hour < 17;
}

// test — controlled clock, no wall-clock dependency
import { isWithinBusinessHours, Clock } from './businessHours';

describe('isWithinBusinessHours', () => {
  const makeClockAt = (isoString: string): Clock => ({
    now: () => new Date(isoString).getTime(),
  });

  it('returns true at 10:00 AM on a weekday', () => {
    const clock = makeClockAt('2026-04-26T10:00:00.000Z');
    expect(isWithinBusinessHours(clock)).toBe(true);
  });

  it('returns false at 8:59 AM', () => {
    const clock = makeClockAt('2026-04-26T08:59:00.000Z');
    expect(isWithinBusinessHours(clock)).toBe(false);
  });
});
```

### Pattern 4: afterEach teardown — environment variable isolation  [community]

Tests that set environment variables must restore them. Failing to do so is a classic source of
order-dependent failures that only appear in CI (where test files run in a different order than
locally). The `afterEach` restore pattern is mandatory when mutating `process.env`.

```typescript
describe('config loader', () => {
  const originalEnv = { ...process.env };

  afterEach(() => {
    // Restore environment state regardless of test pass/fail
    process.env = { ...originalEnv };
  });

  it('uses LOG_LEVEL=debug when set in environment', () => {
    process.env.LOG_LEVEL = 'debug';
    const config = loadConfig();
    expect(config.logLevel).toBe('debug');
  });

  it('defaults to LOG_LEVEL=info when not set', () => {
    delete process.env.LOG_LEVEL;
    const config = loadConfig();
    expect(config.logLevel).toBe('info');
  });
});
```

### Pattern 5: Module-level singleton isolation with jest.resetModules()  [community]

When the code under test uses a module-level singleton (e.g., a cache, connection pool, or
registry), `jest.resetModules()` in `beforeEach` ensures each test gets a fresh module instance.
This is necessary when the singleton is initialized at import time. Use dynamic `import()` (not
`require()`) for proper TypeScript ESM compatibility.

```typescript
describe('userRegistry (module singleton)', () => {
  // Type reference only — actual import happens inside beforeEach
  let userRegistry: typeof import('./userRegistry');

  beforeEach(async () => {
    // Clear module cache so the singleton reinitializes on next import
    jest.resetModules();
    // Dynamic import re-evaluates the module fresh each test
    userRegistry = await import('./userRegistry');
  });

  it('starts with an empty registry', () => {
    expect(userRegistry.count()).toBe(0);
  });

  it('registers a user and increments count without leaking to next test', () => {
    userRegistry.register({ id: 'u1', name: 'Alice' });
    expect(userRegistry.count()).toBe(1);
    // After this test, beforeEach resets the module — next test sees count 0
  });

  it('is still empty because previous test state was wiped', () => {
    expect(userRegistry.count()).toBe(0);
  });
});
```

### Pattern 6: Database transaction rollback for integration test isolation  [community]

Integration tests that hit a real database need data isolation too. The transaction rollback
pattern wraps each test in a database transaction that is rolled back in `afterEach`, leaving the
database in exactly the state it was in before the test ran. This is faster than truncating tables
and avoids needing test-specific seed data cleanup logic.

```typescript
import { DataSource, QueryRunner } from 'typeorm';
import { dataSource } from '../src/db/dataSource';

describe('UserRepository integration', () => {
  let queryRunner: QueryRunner;

  beforeAll(async () => {
    await dataSource.initialize();
  });

  beforeEach(async () => {
    // Open a transaction — all DB writes during this test happen inside it
    queryRunner = dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();
  });

  afterEach(async () => {
    // Roll back regardless of test pass/fail — DB state is pristine for next test
    await queryRunner.rollbackTransaction();
    await queryRunner.release();
  });

  afterAll(async () => {
    await dataSource.destroy();
  });

  it('creates and retrieves a user within the same transaction', async () => {
    // Arrange
    const repo = queryRunner.manager.getRepository(User);
    const input = { name: 'Alice', email: 'alice@example.com' };

    // Act
    const created = await repo.save(repo.create(input));
    const found = await repo.findOneBy({ id: created.id });

    // Assert
    expect(found?.name).toBe('Alice');
    // Rolled back in afterEach — no cleanup code needed
  });
});
```

### Pattern 7: HTTP server isolation — dynamic port binding to prevent port conflicts  [community]

When integration tests spin up an Express/Fastify/Hapi server, binding to a fixed port (e.g., 3000)
causes `EADDRINUSE` errors when tests run in parallel (multiple Jest workers) or when the developer's
local dev server is already running on that port. The fix: bind on port `0` to let the OS choose a
free port, then read the assigned port from the listening handle.

```typescript
import express from 'express';
import type { Server } from 'http';
import supertest from 'supertest';
import { createRouter } from '../src/routes';

describe('API integration — server on dynamic port', () => {
  let server: Server;
  let request: ReturnType<typeof supertest>;

  beforeAll((done) => {
    const app = express();
    app.use(express.json());
    app.use('/api', createRouter());

    // Port 0: OS assigns a free port → no collision across parallel workers
    server = app.listen(0, () => {
      request = supertest(server);
      done();
    });
  });

  afterAll((done) => {
    server.close(done);
  });

  it('GET /api/users returns 200 and empty array initially', async () => {
    const response = await request.get('/api/users');
    expect(response.status).toBe(200);
    expect(response.body).toEqual([]);
  });

  it('POST /api/users creates a user and returns 201', async () => {
    const response = await request
      .post('/api/users')
      .send({ name: 'Bob', email: 'bob@example.com' });
    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('id');
  });
});
```

---

## Anti-Patterns

### 1. Shared mutable object declared and initialized at describe scope
```typescript
// BAD — cart is shared across all tests; second test sees leftover state from first
const cart = new ShoppingCart();
it('adds item', () => { cart.add(item); expect(cart.itemCount()).toBe(1); });
it('is empty', () => { expect(cart.itemCount()).toBe(0); }); // FAILS if run after first
```
**Why harmful:** Passes when run alone, fails when run in suite order — or vice versa. The suite
becomes brittle to reordering, parallelism, or new tests being added.

### 2. Test-to-test data handoff via module-level variables
Storing the output of one test (`const result = null; it('creates user', () => { result = ... })`)
and reading it in a later test violates the Independent property and makes the suite order-dependent.

### 3. Missing teardown for external resources
Opening a database connection, starting a server, or writing a temp file without a corresponding
`afterEach`/`afterAll` cleanup leaks resources across tests. Under Jest's parallel worker model
this can exhaust file descriptors or cause port conflicts.

### 4. `beforeAll` for mutable setup shared across tests
`beforeAll` is appropriate only for truly immutable setup (e.g., spawning a read-only test server).
Using it to initialize a mutable object shared by multiple tests reintroduces shared state; tests
that modify the shared object contaminate later tests in the same block.

### 5. Asserting inside `afterEach`
Placing `expect()` calls inside `afterEach` means a test can appear to pass (no assertion failure
in the test body) yet trigger an error in teardown that is attributed to the *next* test. Keep all
assertions inside the test body's Assert phase.

### 6. Testing multiple behaviors in a single test ("mega-test")
A test that creates a user, updates it, verifies the update, deletes it, and verifies deletion in
one test body violates both the AAA pattern and Self-validating. When it fails, you don't know
which step broke without reading through the whole test.

### 7. Relying on test file execution order in CI
Configuring CI to run test files in a specific order (e.g., `jest auth.test.ts db.test.ts app.test.ts`)
and having later files depend on side effects from earlier files creates a hidden order dependency at
the file level. Jest's `--testSequencer`, `--randomize`, or shard-based parallelism will break this.
Each test file must be fully self-contained from setup to teardown.

---

## Real-World Gotchas  [community]

1. **`jest --runInBand` as a crutch.** [community] Teams often add `--runInBand` to fix flaky CI runs
   without investigating why the suite fails under parallel execution. This masks shared-state bugs
   and slows the suite; the correct fix is to find and eliminate the shared state.

2. **`afterAll` cleanup not running on test failure.** [community] If `beforeAll` throws, Jest skips
   both the tests and the `afterAll`. Prefer `afterEach` for cleanup that must always run; use
   `try/finally` patterns in `beforeAll` for expensive resource setup that needs guaranteed cleanup.

3. **`jest.mock()` hoisting surprises.** [community] Jest hoists `jest.mock()` calls to the top of the
   file at compile time. A mock set up in one `describe` block is visible in all blocks in the same
   file unless explicitly reset. Use `jest.resetAllMocks()` or `clearMocks: true` in Jest config to
   prevent mock state leaking between tests.

4. **Environment variables in CI differ from local.** [community] Tests that pass locally but fail in CI
   are frequently caused by environment variables set in the developer's shell that are not set in
   the CI worker. Explicitly set all required env vars in `beforeEach` and restore in `afterEach`
   rather than assuming ambient environment state.

5. **Snapshot tests as hidden shared state.** [community] Jest snapshot files checked into version
   control are shared state at the file level. When a snapshot is updated by one developer but not
   rebased, the next CI run sees a stale snapshot. Treat snapshots as a tradeoff: useful for UI
   regression but require discipline to keep current; inline snapshots reduce the drift problem.

6. **Timer leakage between tests when using `jest.useFakeTimers()`.** [community] Calling
   `jest.useFakeTimers()` in a `beforeEach` without a corresponding `jest.useRealTimers()` in
   `afterEach` leaks fake timer state into subsequent tests — including tests in other files that
   run in the same worker. This causes subtle timing failures that only appear under certain
   parallelism configurations.

7. **Vitest's `vi.spyOn` auto-restoration vs. Jest's manual reset.** [community] Vitest restores
   spies automatically when `restoreMocks: true` is set in `vite.config.ts`. Teams migrating from
   Jest to Vitest often forget to add this config flag, recreating the mock-leak problem in a new
   framework.

8. **Jest worker isolation boundary is the *file*, not the `describe` block.** [community] Jest runs
   each test *file* in a separate worker process by default. Shared state within a file is shared
   across all tests in that file regardless of `describe` nesting. Teams sometimes expect
   `describe`-scoped `beforeAll` to be isolated from sibling `describe` blocks — it is not. The
   isolation boundary is the file. Splitting logically unrelated tests into separate files is the
   correct fix, not adding more `beforeEach` resets.

9. **Database transaction rollback is faster than truncate-and-seed but fails with auto-commit
   drivers.** [community] Some database clients (e.g., certain Prisma configurations, connection
   pool implementations) use auto-commit mode or open a new connection per query, making the
   transaction rollback pattern ineffective. Always verify that all DB operations inside a test
   use the *same* `QueryRunner` / transaction handle, not the global data source — or the rollback
   silently has no effect and tests contaminate each other.

10. **Using `jest --randomize` to detect hidden order dependencies.** [community] Jest 29.2+ added
    `--randomize` (or `--testSequencer` with a custom shuffler) to run tests within each file in
    random order. Running the suite with `--randomize` periodically is the most reliable way to
    surface hidden order dependencies without having to read test code. Many teams only discover
    order-dependent failures after a CI framework upgrade that changes worker scheduling — adding
    a weekly `--randomize` run to CI catches this earlier.

---

## Tradeoffs & Alternatives

### When test isolation is deliberately relaxed

**Integration tests by design** test the collaboration between real components (e.g., service +
repository + database). These tests intentionally do not mock collaborators. Isolation still applies
at the *test data* level: each test should own its data via transactions rolled back in teardown, or
by inserting and deleting rows with unique keys per test run. The transaction rollback pattern
(Pattern 6) is the preferred approach — it is faster than truncate/seed and leaves no orphaned rows,
but it requires that all test DB operations share a single transaction handle.

**End-to-end tests** operate against a full stack and cannot isolate individual units. Apply
isolation at the scenario level: each E2E scenario should set up its own preconditions via API calls
and clean up after itself. Shared test accounts or shared database state in E2E suites is the
primary source of E2E flakiness.

### Known adoption costs

- **Dependency injection adds boilerplate.** Refactoring existing code to accept injected
  collaborators requires touching call sites. The benefit (testability, isolation) outweighs the
  cost in medium-to-large codebases, but teams should expect an upfront refactoring phase.

- **`jest.resetModules()` is slow.** Resetting the module registry per test forces re-evaluation of
  all `require`/`import` chains and is significantly slower than per-instance reset. Use only when
  the singleton-at-import-time pattern cannot be refactored away.

- **Strict isolation can make tests verbose.** Fully isolated tests with complete `beforeEach`
  setup can be long. The Arrange-Act-Assert pattern helps, but teams sometimes push back on the
  verbosity. Shared *immutable* fixtures (defined once in `beforeAll` or as module-level `const`)
  are an acceptable tradeoff when the object is never mutated by tests.

### Lighter alternatives for small projects

- **Test-scoped state with `describe` + `let` + `beforeEach`** (already covered above) is the
  minimum viable isolation for most projects.
- **Functional pure functions** eliminate the need for test doubles entirely — if the SUT has no
  side effects and no dependencies, it is isolated by construction.

### Named alternatives to Jest/Vitest isolation features

| Problem | Jest mechanism | Vitest equivalent |
|---------|---------------|-------------------|
| Mock reset between tests | `clearMocks: true` in `jest.config` | `clearMocks: true` in `vite.config` |
| Spy auto-restore | `restoreMocks: true` | `restoreMocks: true` |
| Timer isolation | `jest.useFakeTimers()` / `jest.useRealTimers()` | `vi.useFakeTimers()` / `vi.useRealTimers()` |
| Module singleton reset | `jest.resetModules()` | `vi.resetModules()` |
| Per-test module isolation | `jest.isolateModules()` | `vi.isolateModules()` |

### Recommended Jest config baseline for maximum isolation

Enabling these three config flags at the project level ensures isolation-safe defaults without
requiring per-test manual resets. `clearMocks` resets call counts; `resetMocks` removes
implementations; `restoreMocks` restores all spied-on originals. Teams typically choose `clearMocks`
+ `restoreMocks` (preserving manual mock implementations) or `resetMocks` + `restoreMocks`
(full reset every test).

```typescript
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  // Reset mock call history and instances between every test
  clearMocks: true,
  // Restore all spied-on originals after each test (prevents spy leaks)
  restoreMocks: true,
  // Do NOT set resetMocks: true alongside restoreMocks — resetMocks removes
  // manual mock implementations, which often breaks jest.mock() factory mocks.
  // Choose: clearMocks (safe default) or resetMocks (aggressive, verify first).

  // Run tests in random order within files to expose order dependencies
  // Uncomment for periodic CI runs (not every run — flakiness diagnostics only)
  // randomize: true,

  // Limit workers to avoid port collisions in integration suites
  maxWorkers: '50%',
};

export default config;
```

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Martin Fowler — Unit Test | Official | https://martinfowler.com/bliki/UnitTest.html | Defines solitary vs sociable tests; the canonical reference for what "unit" means |
| xUnit Patterns — Four Phase Test | Official | http://xunitpatterns.com/Four%20Phase%20Test.html | Defines Arrange-Act-Assert (as Setup/Exercise/Verify/Teardown); the pattern's original source |
| Google Testing Blog — Test Flakiness | Community | https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html | Production-scale data on flakiness causes and quarantine strategy from Google's CI |
| Jest Docs — Timer Mocks | Official | https://jestjs.io/docs/timer-mocks | Authoritative reference for `useFakeTimers` isolation in Jest |
| Vitest Docs — Mocking | Official | https://vitest.dev/guide/mocking | Vitest equivalents for Jest isolation APIs |
| Martin Fowler — Non-Determinism in Tests | Official | https://martinfowler.com/articles/nonDeterminism.html | Deep analysis of why tests become non-deterministic; covers shared state as root cause |
| Jest Docs — Configuration Reference | Official | https://jestjs.io/docs/configuration | Authoritative reference for `clearMocks`, `restoreMocks`, `resetMocks`, `randomize` options |
| Supertest — HTTP assertion library | Community | https://github.com/ladjs/supertest | Standard TypeScript library for integration-testing Express/Fastify servers without binding a port |
