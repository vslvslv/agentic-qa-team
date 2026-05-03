# Test Isolation — QA Methodology Guide
<!-- lang: TypeScript | topic: test-isolation | iteration: 8 | score: 100/100 | date: 2026-05-03 -->
<!-- Rubric: Principle Coverage 25/25 | Code Examples 25/25 | Tradeoffs & Context 25/25 | Community Signal 25/25 -->
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

A *test fixture* is the set of preconditions under which a test runs (ISTQB CTFL 4.0 term). Proper
fixture management means every test starts from a known-good state and cleans up after itself — not
relying on the previous test having run (or not having run). In Jest/Vitest with TypeScript:
`beforeEach`/`afterEach` for per-test fixtures, `beforeAll`/`afterAll` for expensive setup shared
within a `describe` block (use sparingly).

### 4. Shared mutable state as the root cause of flakiness

The single most common cause of flaky tests is **shared mutable state**: module-level singletons,
global variables, static properties, shared database rows, shared in-memory caches, or environment
variables mutated by one test and read by another. Flakiness caused by shared state is particularly
dangerous because it often only surfaces under parallel execution or after suite restructuring.

### 5. Test doubles and dependency injection as isolation enablers

Replacing real collaborators (databases, HTTP clients, clocks, random number generators) with
controlled fakes, stubs, or mocks is the mechanical mechanism that makes FIRST achievable. In
TypeScript, dependency injection is enabled by interfaces and constructor injection — passing
collaborators typed as interfaces rather than importing concrete singletons. TypeScript's type system
enforces that test doubles conform to the real interface.

**Test doubles taxonomy** (Meszaros, xUnit Test Patterns):

| Double type | Description | TypeScript mechanism |
|-------------|-------------|---------------------|
| **Dummy** | Passed but never used; fills a required parameter | `{} as SomeInterface` |
| **Stub** | Returns canned values; no behavior verification | `jest.fn().mockReturnValue(...)` |
| **Fake** | Simplified working implementation (e.g., in-memory DB) | Class implementing the interface |
| **Spy** | Records calls for later verification; delegates to real | `jest.spyOn(obj, 'method')` |
| **Mock** | Pre-programmed with expectations; verified on teardown | `jest.fn()` with `toHaveBeenCalledWith` |

Using the wrong double type is an isolation anti-pattern. A **mock** verified in `afterEach` (not
in the test body) violates the Self-validating property because the assertion is outside the AAA
pattern. Prefer asserting mock calls inside the test body's Assert phase.

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
collaborators are fast, deterministic, and free of external I/O. In TypeScript, the choice is often
clearer because typed interfaces make the boundary explicit.

---

## When to Use

**Always:** Every project with automated tests benefits from these principles. Test isolation is not
optional — it is the foundation that makes the entire test suite trustworthy.

**Especially critical when:**
- Running tests in CI with parallelism or sharding (order-dependency and shared state fail loudly)
- Multiple engineers contribute tests to the same suite (naming collisions, fixture contamination)
- The test suite has grown beyond ~500 tests and flakiness is already appearing
- Using Jest's `--runInBand` is the only way to make the suite pass (red flag: hidden shared state)

**When NOT to use strict unit-level isolation:**
- End-to-end smoke tests intentionally exercise the full stack — apply isolation at *scenario* level
- Contract tests verify real integration points — use transaction rollback for data isolation, not mocks
- Performance benchmarks need real I/O; isolation would invalidate the measurement

**Maturity level:** Applicable from day 1 of a project. No prior testing maturity required.

---

## Patterns

### Pattern 1: Arrange-Act-Assert with explicit phases (TypeScript)

Each phase is separated by a blank line and never interleaved. The Act phase contains exactly one
call. The Assert phase verifies the outcome of that single call.

```typescript
import { calculateDiscount } from './pricing';
import type { Customer } from './types';

describe('calculateDiscount', () => {
  it('applies 20% discount when customer is premium and cart exceeds $100', () => {
    // Arrange
    const customer: Customer = { id: 'c1', tier: 'premium' };
    const cartTotal = 150.00;

    // Act
    const discounted = calculateDiscount(customer, cartTotal);

    // Assert
    expect(discounted).toBeCloseTo(120.00, 2);
  });

  it('applies no discount when customer is standard regardless of cart size', () => {
    // Arrange
    const customer: Customer = { id: 'c2', tier: 'standard' };
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
`describe` scope but re-initialize it inside `beforeEach`. This is the most impactful single change
teams make when eliminating flakiness from an existing suite.

```typescript
import { ShoppingCart } from './ShoppingCart';
import type { Product } from './types';

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

### Pattern 3: Interface-based dependency injection + fake clock (TypeScript)  [community]

TypeScript interfaces enable strongly-typed test doubles without a mocking library. Define a `Clock`
interface; production code depends on the interface, tests provide a controlled implementation.

```typescript
// production code — typed interface injection, not hardcoded Date
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

  it('returns false at 8:59 AM (before business hours)', () => {
    const clock = makeClockAt('2026-04-26T08:59:00.000Z');

    expect(isWithinBusinessHours(clock)).toBe(false);
  });

  it('returns false at exactly 5:00 PM (boundary exclusive)', () => {
    const clock = makeClockAt('2026-04-26T17:00:00.000Z');

    expect(isWithinBusinessHours(clock)).toBe(false);
  });
});
```

### Pattern 4: jest.useFakeTimers() for setTimeout/setInterval isolation  [community]

When testing code that uses `setTimeout`, `setInterval`, or `Date.now()` directly, use
`jest.useFakeTimers()` to control the timer system. Always pair with `jest.useRealTimers()` in
`afterEach` to prevent timer state from leaking across tests.

```typescript
import { PollingNotifier } from './pollingNotifier';

describe('PollingNotifier', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    // CRITICAL: restore real timers — failure leaks state into subsequent tests
    jest.useRealTimers();
  });

  it('does not fire callback before the interval elapses', () => {
    const callback = jest.fn();
    const notifier = new PollingNotifier(callback, 5000);

    notifier.start();
    jest.advanceTimersByTime(4999);

    expect(callback).not.toHaveBeenCalled();
    notifier.stop();
  });

  it('fires callback exactly once when the first interval elapses', () => {
    const callback = jest.fn();
    const notifier = new PollingNotifier(callback, 5000);

    notifier.start();
    jest.advanceTimersByTime(5000);

    expect(callback).toHaveBeenCalledTimes(1);
    notifier.stop();
  });

  it('fires callback multiple times across multiple intervals', () => {
    const callback = jest.fn();
    const notifier = new PollingNotifier(callback, 1000);

    notifier.start();
    jest.advanceTimersByTime(3500); // 3 full intervals

    expect(callback).toHaveBeenCalledTimes(3);
    notifier.stop();
  });
});
```

### Pattern 5: afterEach teardown — environment variable isolation  [community]

Tests that set environment variables must restore them. Failing to do so is a classic source of
order-dependent failures that only appear in CI (where test files run in a different order than
locally).

```typescript
import { loadConfig } from './config';

describe('config loader', () => {
  const originalEnv = Object.assign({}, process.env);

  afterEach(() => {
    // Restore environment state regardless of test pass/fail
    Object.keys(process.env).forEach((key) => delete process.env[key]);
    Object.assign(process.env, originalEnv);
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

### Pattern 6: jest.resetModules() for module-level singleton isolation  [community]

When TypeScript code uses a module-level singleton (cache, registry, connection pool), reset the
module registry in `beforeEach` to ensure each test gets a fresh module instance.

```typescript
describe('userRegistry (module singleton)', () => {
  let userRegistry: typeof import('./userRegistry');

  beforeEach(() => {
    // Clear module cache so singleton reinitializes on next require
    jest.resetModules();
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    userRegistry = require('./userRegistry');
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

### Pattern 7: Database transaction rollback for integration test isolation  [community]

Integration tests that hit a real database need data isolation too. Wrap each test in a DB
transaction rolled back in `afterEach`, leaving the database in exactly its pre-test state.

```typescript
import { dataSource } from '../src/db/dataSource';
import { QueryRunner } from 'typeorm';

describe('UserRepository integration', () => {
  let queryRunner: QueryRunner;

  beforeAll(async () => {
    await dataSource.initialize();
  });

  beforeEach(async () => {
    queryRunner = dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();
  });

  afterEach(async () => {
    // Roll back regardless of pass/fail — DB state is pristine for next test
    await queryRunner.rollbackTransaction();
    await queryRunner.release();
  });

  afterAll(async () => {
    await dataSource.destroy();
  });

  it('creates and retrieves a user within the same transaction', async () => {
    const repo = queryRunner.manager.getRepository('User');
    const input = { name: 'Alice', email: 'alice@example.com' };

    const created = await repo.save(repo.create(input));
    const found = await repo.findOneBy({ id: created.id });

    expect(found?.name).toBe('Alice');
  });
});
```

### Pattern 8: Jest config baseline for maximum isolation  [community]

```typescript
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  // Reset mock call history and instances between every test
  clearMocks: true,
  // Restore all spied-on originals after each test (prevents spy leaks)
  restoreMocks: true,
  // Use TypeScript transform
  preset: 'ts-jest',
  testEnvironment: 'node',
  // Limit workers to avoid port collisions in integration suites
  maxWorkers: '50%',
};

export default config;
```

### Pattern 9: Type-safe mocks with `jest.mocked()` — preventing interface drift  [community]

In TypeScript, `jest.mock()` with a factory function produces an untyped result by default.
Wrapping the import with `jest.mocked()` preserves full TypeScript type-checking on mock
assertions, ensuring test doubles stay in sync with the real interface whenever the production
code changes. This is the primary mechanism for catching isolation failures at compile time
rather than at runtime.

```typescript
// types.ts
export interface EmailService {
  send(to: string, subject: string, body: string): Promise<void>;
  getLastDeliveredTo(): string | null;
}

// userService.ts
import type { EmailService } from './types';

export class UserService {
  constructor(private readonly emailService: EmailService) {}

  async registerUser(email: string, name: string): Promise<{ id: string }> {
    const user = { id: `user-${Date.now()}`, email, name };
    // Persist user... (omitted for brevity)
    await this.emailService.send(
      email,
      'Welcome!',
      `Hi ${name}, your account is ready.`,
    );
    return user;
  }
}

// userService.test.ts
import { UserService } from './userService';
import type { EmailService } from './types';

describe('UserService.registerUser', () => {
  let emailService: jest.Mocked<EmailService>;
  let service: UserService;

  beforeEach(() => {
    // jest.Mocked<T> gives full TypeScript type-checking on .mockResolvedValue etc.
    emailService = {
      send: jest.fn().mockResolvedValue(undefined),
      getLastDeliveredTo: jest.fn().mockReturnValue(null),
    };
    // Fresh service instance per test — no shared state across tests
    service = new UserService(emailService);
  });

  it('sends a welcome email to the registered address', async () => {
    await service.registerUser('alice@example.com', 'Alice');

    // TypeScript knows emailService.send is jest.Mock — .toHaveBeenCalledWith is type-safe
    expect(emailService.send).toHaveBeenCalledWith(
      'alice@example.com',
      'Welcome!',
      expect.stringContaining('Alice'),
    );
  });

  it('returns the created user with an id', async () => {
    const result = await service.registerUser('bob@example.com', 'Bob');

    expect(result).toHaveProperty('id');
    expect(result.id).toMatch(/^user-/);
  });
});
```

### Pattern 10: HTTP server isolation — dynamic port binding (TypeScript + supertest)  [community]

When integration tests spin up an Express/Fastify server, binding to a fixed port causes
`EADDRINUSE` errors when tests run in parallel (multiple Jest workers) or when a local dev server
is already running. Binding on port `0` lets the OS assign a free port per worker.

```typescript
import express, { Application } from 'express';
import supertest, { SuperTest, Test } from 'supertest';
import http from 'http';
import { createUserRouter } from '../src/routes/userRouter';

describe('UserRouter — HTTP integration (dynamic port)', () => {
  let app: Application;
  let server: http.Server;
  let request: SuperTest<Test>;

  beforeAll((done) => {
    app = express();
    app.use(express.json());
    app.use('/api/users', createUserRouter());

    // Port 0: OS assigns a free port — no collision across parallel Jest workers
    server = app.listen(0, () => {
      request = supertest(server);
      done();
    });
  });

  afterAll((done) => {
    server.close(done);
  });

  it('GET /api/users returns 200 and an array', async () => {
    const response = await request.get('/api/users');

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  it('POST /api/users creates a user and returns 201 with an id', async () => {
    const payload = { name: 'Carol', email: 'carol@example.com' };

    const response = await request.post('/api/users').send(payload);

    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({ name: 'Carol', email: 'carol@example.com' });
    expect(response.body).toHaveProperty('id');
  });

  it('POST /api/users returns 400 when email is missing', async () => {
    const response = await request.post('/api/users').send({ name: 'Dave' });

    expect(response.status).toBe(400);
  });
});
```

---

## Anti-Patterns

### 1. Shared mutable object declared and initialized at describe scope
```typescript
// BAD — cart is shared across all tests; second test sees leftover state
const cart = new ShoppingCart(); // initialized ONCE at describe scope
it('adds item', () => { cart.add(item); expect(cart.itemCount()).toBe(1); });
it('is empty', () => { expect(cart.itemCount()).toBe(0); }); // FAILS after first test
```
**Why harmful:** Passes when run alone, fails when run in suite order — or vice versa. The suite
becomes brittle to reordering, parallelism, or new tests being added.

### 2. Test-to-test data handoff via module-level variables
Storing the output of one test (`let result: User | null = null; it('creates user', () => { result = ... })`)
and reading it in a later test violates the Independent property and makes the suite order-dependent.

### 3. Missing teardown for external resources
Opening a database connection, starting a server, or writing a temp file without a corresponding
`afterEach`/`afterAll` cleanup leaks resources. Under Jest's parallel worker model this can exhaust
file descriptors or cause `EADDRINUSE` port conflicts.

### 4. `beforeAll` for mutable setup shared across tests
`beforeAll` is appropriate only for truly immutable setup (e.g., spawning a read-only test server).
Using it to initialize a mutable object shared by multiple tests reintroduces shared state; tests
that modify the shared object contaminate later tests in the same block.

### 5. Asserting inside `afterEach`
Placing `expect()` calls inside `afterEach` means a test can appear to pass yet trigger an error in
teardown attributed to the *next* test. Keep all assertions inside the test body's Assert phase.

### 6. Testing multiple behaviors in a single test ("mega-test")
A test that creates a user, updates it, verifies the update, deletes it, and verifies deletion in
one test body violates both the AAA pattern and Self-validating. When it fails, you don't know
which step broke without reading the whole test.

### 7. Relying on test file execution order in CI
Configuring CI to run test files in a specific order and having later files depend on side effects
from earlier files creates a hidden order dependency at the file level. Each test file must be fully
self-contained from setup to teardown.

### 8. Using `as unknown as MockType` to bypass TypeScript type checking on mocks
```typescript
// BAD — casting destroys all type-safety on the mock
const emailService = { send: jest.fn() } as unknown as EmailService;
```
**Why harmful:** TypeScript will not flag when `EmailService` gains a new required method and
the mock is not updated. The test compiles but the mock no longer matches the real interface.
Use `jest.Mocked<EmailService>` (Pattern 9) instead — TypeScript will error if the shape drifts.

### 9. `jest.fn()` calls in `describe` scope (not `beforeEach`)
```typescript
// BAD — mock created once, call count accumulates across tests
const mockSend = jest.fn();
it('sends email on register', async () => { ... expect(mockSend).toHaveBeenCalledTimes(1); });
it('does not send email on login', async () => { ... expect(mockSend).not.toHaveBeenCalled(); }); // FAILS
```
**Why harmful:** Even with `clearMocks: true` in config, this pattern is brittle because it
relies on Jest internals. The intent is clearer and more robust when the mock is recreated in
`beforeEach` alongside all other arrange state.

---

## Real-World Gotchas  [community]

1. **`jest --runInBand` as a crutch.** [community] Teams often add `--runInBand` to fix flaky CI runs
   without investigating why the suite fails under parallel execution. This masks shared-state bugs
   and slows the suite; the correct fix is to find and eliminate the shared state.

2. **`afterAll` cleanup not running on test failure.** [community] If `beforeAll` throws, Jest skips
   both the tests and the `afterAll`. Prefer `afterEach` for cleanup that must always run; use
   `try/finally` patterns in `beforeAll` for expensive resource setup that needs guaranteed cleanup.

3. **`jest.mock()` hoisting surprises.** [community] Jest hoists `jest.mock()` calls to the top of
   the file at compile time (via Babel/ts-jest). A mock set up in one `describe` block is visible
   in all blocks in the same file unless explicitly reset. Use `clearMocks: true` in Jest config.

4. **Environment variables in CI differ from local.** [community] Tests that pass locally but fail
   in CI are frequently caused by environment variables set in the developer's shell that are not
   set in the CI worker. Explicitly set all required env vars in `beforeEach` and restore in
   `afterEach` rather than assuming ambient environment state.

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
   spies automatically when `restoreMocks: true` is set in `vitest.config.ts`. Teams migrating from
   Jest to Vitest often forget to add this config flag, recreating the mock-leak problem.

8. **Jest worker isolation boundary is the *file*, not the `describe` block.** [community] Jest runs
   each test *file* in a separate worker process by default. Shared state within a file is shared
   across all tests in that file regardless of `describe` nesting. The isolation boundary is the
   file. Splitting logically unrelated tests into separate files is the correct fix.

9. **TypeScript `jest.mock()` with factory functions requires type assertions.** [community]
   When using `jest.mock('./module', () => ({ fn: jest.fn() }))` in TypeScript, the mocked module
   type is `unknown` unless you add `jest.mocked()` wrapper or type assertion. Skipping this leads
   to `any` types spreading throughout tests and losing TypeScript's help in catching mock
   mismatches with real implementations.

10. **`jest --randomize` to detect hidden order dependencies.** [community] Jest 29.2+ added
    `--randomize` to run tests within each file in random order. Running the suite with
    `--randomize` periodically is the most reliable way to surface hidden order dependencies.
    Many teams only discover order-dependent failures after a CI framework upgrade that changes
    worker scheduling.

11. **`require()` caching causes singleton leakage in Jest CJS projects.** [community] Node's module
    cache means that once a CJS module is loaded, all subsequent `require()` calls return the cached
    version. In a Jest/TypeScript test suite (compiled to CJS), if two test files load the same
    singleton module without `jest.resetModules()`, they share the same instance. The symptom is
    tests that pass individually but fail when run together.

12. **ESM modules are not resetable with `jest.resetModules()` in native ESM mode.** [community]
    When using Jest with `--experimental-vm-modules` (native ESM TypeScript), `jest.resetModules()`
    does not work as it does in CJS mode. ESM modules are cached by the JavaScript engine itself.
    The workaround is to use dynamic `import()` with cache-busting query parameters or convert
    singletons to explicitly reset factory functions.

13. **`test.concurrent` in Vitest does not serialize `beforeEach`/`afterEach`.** [community]
    Vitest's `test.concurrent` runs tests in the same describe block in parallel. This violates
    the Independent property if the tests share any mutable state in the describe scope — even
    a `let` variable reset in `beforeEach` is unsafe because concurrent tests race on the reset.
    Only use `test.concurrent` with tests that are fully self-contained.

14. **TypeScript strict null checks expose isolation failures at compile time.** [community]
    Enabling `strictNullChecks` in `tsconfig.json` for test files catches cases where a `let`
    variable (e.g., `let cart: ShoppingCart`) is used in a test before `beforeEach` initializes it.
    TypeScript reports "variable 'cart' is used before being assigned" — a free lint for
    isolation anti-pattern #1. Teams that disable `strictNullChecks` in test files lose this benefit.

15. **Database auto-commit drivers silently break transaction rollback.** [community]
    Some database clients (e.g., certain Prisma configurations, connection pool implementations)
    use auto-commit mode or open a new connection per query, making the transaction rollback pattern
    ineffective. The symptom: data written in one test persists into subsequent tests, causing
    cascading failures. Verify that all DB operations inside a test use the *same* `QueryRunner` /
    transaction handle, not the global data source. With Prisma, use `$transaction()` with the test
    client instance and roll back with `$executeRaw('ROLLBACK')`.

16. **`jest.spyOn()` on TypeScript getters requires different syntax.** [community]
    `jest.spyOn(obj, 'property')` works for methods but not for TypeScript getter properties.
    For getters, use `jest.spyOn(obj, 'property', 'get').mockReturnValue(...)`. Failing to
    use the third argument causes the spy to be set up on the wrong descriptor, silently failing
    to intercept the call — a class of isolation bug unique to TypeScript's getter pattern that
    has no compile-time warning.

17. **`ts-jest` `diagnostics` option can mask type errors in test files.** [community]
    When `diagnostics: false` is set in `ts-jest` config to speed up test compilation, TypeScript
    type errors in test files are silently suppressed. Teams commonly use this for performance,
    but it means that a test double with the wrong shape (missing a required method) will compile
    and run without error — only the runtime behavior will be wrong. The better tradeoff is
    `diagnostics: { warnOnly: true }` during migration, then re-enable `diagnostics: true`.

18. **Shared `supertest` agent across tests retains cookie session state.** [community]
    When using `supertest.agent(app)` (with `.agent()`, not the plain `supertest(app)`) across
    multiple tests, the agent maintains cookie jar state between requests. If one test logs in,
    subsequent tests run as the authenticated user — even if they never call a login endpoint.
    The correct approach: create a new agent in `beforeEach`, or use the stateless `supertest(server)`
    form for tests that should be unauthenticated. WHY: supertest agent is designed for multi-step
    authenticated flows within a single test; it should not cross test boundaries.

19. **NestJS `@Module` providers are singletons by default — test isolation requires `TestingModule.close()`.** [community]
    NestJS's dependency injection creates module-scoped singletons. When creating a `TestingModule`
    in `beforeAll`, services and repositories are shared across all tests in the file. Tests that
    modify service state (e.g., calling `cache.set()`) will leak into subsequent tests. The fix:
    either call `module.close()` in `afterAll` and recreate in `beforeEach`, or reset all
    module-level state explicitly. WHY: the NestJS DI container does not reset between tests unless
    explicitly re-instantiated, which surprises teams migrating from plain Jest tests.

20. **`jest.mock()` applied to a re-exported symbol from an index barrel file mocks the barrel, not the source.** [community]
    When production code imports `{ UserService } from '../services'` (a barrel re-export from
    `index.ts`), calling `jest.mock('../services')` in a test mocks the entire barrel — including
    other services you did not intend to mock. This causes unexpected undefined-method errors in
    tests that share the same file's mock scope. The fix: import directly from the source file
    (`'../services/UserService'`) in both production code and tests, or use
    `jest.mock('../services', () => ({ UserService: jest.fn() }))` with an explicit factory.

---

## Tradeoffs & Alternatives

### When test isolation is deliberately relaxed

**Integration tests by design** test the collaboration between real components (e.g., service +
repository + database). Isolation applies at the *test data* level via transaction rollback
(Pattern 7). The transaction rollback pattern is faster than truncating tables and leaves no
orphaned rows, but requires all test DB operations share a single transaction handle.

**End-to-end tests** operate against a full stack and cannot isolate individual units. Apply
isolation at the scenario level: each E2E scenario should set up its own preconditions via API calls
and clean up after itself. In Playwright with TypeScript, use `test.use({ storageState })` to give
each worker its own browser storage (cookies, localStorage) and avoid session contamination across
parallel workers.

### Named alternatives to test isolation techniques

| Problem | Isolated approach | Alternative | Tradeoff |
|---------|------------------|-------------|----------|
| External service dependency | Mock/stub (test double) | Contract test (Pact) | Mock: fast but drifts; Contract: verified but needs provider |
| Shared DB state | Transaction rollback | Test containers (fresh DB per run) | Rollback: fast, same DB; Containers: slower, higher fidelity |
| Singleton modules | `jest.resetModules()` | Refactor to DI | Reset: quick fix, slow; DI: upfront cost, permanent fix |
| Time-dependent code | `jest.useFakeTimers()` | Inject `Clock` interface | FakeTimers: zero refactor; Interface: better design |

### Known adoption costs

- **Dependency injection adds boilerplate.** Refactoring existing TypeScript code to accept
  injected collaborators (typed as interfaces) requires touching call sites. The benefit outweighs
  the cost in medium-to-large codebases, but teams should expect an upfront refactoring phase.

- **`jest.resetModules()` is slow.** Resetting the module registry per test forces re-evaluation
  of all `import` chains and is significantly slower than per-instance reset. Use only when the
  singleton-at-import-time pattern cannot be refactored away.

- **Strict isolation can make tests verbose.** Fully isolated tests with complete `beforeEach`
  setup can be long. Shared *immutable* fixtures (defined once in `beforeAll` or as module-level
  `const`) are an acceptable tradeoff when the object is never mutated by tests.

### ISTQB CTFL 4.0 terminology alignment

| Common informal term | ISTQB CTFL 4.0 preferred term | Notes |
|---------------------|------------------------------|-------|
| "test" (individual) | **test case** | Has explicit inputs, preconditions, expected results, postconditions |
| "test set" / "spec file" | **test suite** | A collection of test cases grouped for execution |
| "thing under test" | **test object** (or SUT) | The component, system, or item being tested |
| "test scenario" | **test condition** | A testable aspect or situation derived from the test basis |
| "bug" / "error" | **defect** | Prefer "defect" in formal reports |
| "test layer" | **test level** | Unit test level, integration test level, system test level |
| "setup/teardown" | **test fixture** | The fixed state or context used to run a test case |

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Martin Fowler — Unit Test | Official | https://martinfowler.com/bliki/UnitTest.html | Defines solitary vs sociable tests; canonical reference for what "unit" means |
| xUnit Patterns — Four Phase Test | Official | http://xunitpatterns.com/Four%20Phase%20Test.html | Defines AAA (as Setup/Exercise/Verify/Teardown); the pattern's original source |
| Google Testing Blog — Test Flakiness | Community | https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html | Production-scale data on flakiness causes from Google's CI |
| Jest Docs — Timer Mocks | Official | https://jestjs.io/docs/timer-mocks | Authoritative reference for `useFakeTimers` isolation in Jest |
| Vitest Docs — Mocking | Official | https://vitest.dev/guide/mocking | Vitest equivalents for Jest isolation APIs |
| Martin Fowler — Non-Determinism in Tests | Official | https://martinfowler.com/articles/nonDeterminism.html | Deep analysis of why tests become non-deterministic |
| Jest Docs — Configuration Reference | Official | https://jestjs.io/docs/configuration | Authoritative reference for `clearMocks`, `restoreMocks`, `resetMocks`, `randomize` |
| ts-jest Docs | Official | https://kulshekhar.github.io/ts-jest/ | TypeScript transformer for Jest; covers ESM/CJS isolation tradeoffs |
| Playwright — Authentication & Storage State | Official | https://playwright.dev/docs/auth | Per-worker browser storage isolation for E2E test suites |
| ISTQB CTFL 4.0 Syllabus | Standard | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative source for standardized testing terminology |

---

## Quick Reference — Isolation Mechanisms by Problem Type

| Problem | Symptom | TypeScript/Jest Solution | Vitest equivalent |
|---------|---------|--------------------------|-------------------|
| Shared mutable object | Test B fails after Test A mutates shared var | `let x: T; beforeEach(() => { x = new T(); })` | Same |
| Spy leaks between tests | Mock call count accumulates across tests | `restoreMocks: true` in `jest.config.ts` | `restoreMocks: true` in `vitest.config.ts` |
| Module singleton reset | Singleton state persists across test files | `jest.resetModules()` in `beforeEach` | `vi.resetModules()` in `beforeEach` |
| Timer/Date non-determinism | Tests fail at midnight, DST transitions | `jest.useFakeTimers()` + `jest.useRealTimers()` | `vi.useFakeTimers()` + `vi.useRealTimers()` |
| Environment variable leak | CI passes, local fails (or vice versa) | Save/restore `process.env` in `afterEach` | Same |
| Port collision in parallel tests | `EADDRINUSE` in CI with multiple workers | Bind server on port `0` | Same |
| DB state contamination | Integration tests fail in non-deterministic order | Transaction rollback pattern (Pattern 7) | Same |
| Mock type drift | Mock added method X but interface changed | `jest.Mocked<T>` with `beforeEach` recreation | `vi.Mocked<T>` |
| Barrel mock blast radius | Unintended mocks of sibling exports | Mock source file directly, not barrel | Same |
| Concurrent test race | `test.concurrent` + shared `let` = race | Avoid `test.concurrent` for stateful tests | Same |
| File system contamination | Tests share temp files, leave artifacts | `tmp` directory per test with `afterEach` cleanup | Same |
| Redis/cache state leak | Tests read stale cached data from prior test | Flush or key-namespace per test with `afterEach` | Same |
| React component state leak | Component state from one test affects next | Unmount via `cleanup()` (RTL) or recreate in `beforeEach` | Same |

---

## Extended Patterns

### Pattern 11: File-system isolation with `tmp` directory per test (TypeScript)  [community]

Tests that write to the file system must use a unique temporary directory per test and delete it
in `afterEach`. Reusing a shared directory (or the OS `/tmp` without a per-test subdirectory) causes
cross-test contamination when tests write files with the same names.

```typescript
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { exportReportToFile } from './reportExporter';

describe('reportExporter', () => {
  let tmpDir: string;

  beforeEach(() => {
    // Unique directory per test — avoids filename collisions across parallel runs
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'report-test-'));
  });

  afterEach(() => {
    // Remove the entire temp directory and all files created during the test
    fs.rmSync(tmpDir, { recursive: true, force: true });
  });

  it('writes a JSON report file with the correct structure', async () => {
    const data = { userId: 'u1', actions: ['login', 'view'] };
    const outPath = path.join(tmpDir, 'report.json');

    await exportReportToFile(data, outPath);

    const raw = fs.readFileSync(outPath, 'utf-8');
    const parsed = JSON.parse(raw);
    expect(parsed).toMatchObject({ userId: 'u1' });
    expect(parsed.actions).toHaveLength(2);
  });

  it('creates the output directory if it does not exist', async () => {
    const nestedDir = path.join(tmpDir, 'nested', 'output');
    const outPath = path.join(nestedDir, 'report.json');

    await exportReportToFile({ userId: 'u2', actions: [] }, outPath);

    expect(fs.existsSync(outPath)).toBe(true);
  });

  it('overwrites an existing file without error', async () => {
    const outPath = path.join(tmpDir, 'report.json');
    fs.writeFileSync(outPath, '{"old": true}');

    await exportReportToFile({ userId: 'u3', actions: ['logout'] }, outPath);

    const raw = fs.readFileSync(outPath, 'utf-8');
    expect(JSON.parse(raw)).not.toHaveProperty('old');
  });
});
```

### Pattern 12: React Testing Library isolation — `cleanup()` and per-test renders  [community]

React Testing Library (RTL) automatically calls `cleanup()` after each test when used with a Jest
environment that supports `afterEach`. However, in custom setups (Vitest with manual lifecycle,
or globally-disabled auto-cleanup), you must call it explicitly. Additionally, never share a
`render` result across tests — each test must render independently.

```typescript
import { render, screen, cleanup } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Counter } from './Counter';

// In most Jest/RTL setups this is automatic, but explicit for clarity in Vitest custom configs
afterEach(() => {
  cleanup(); // Unmounts React trees and clears the document body
});

describe('Counter', () => {
  it('renders with initial count of zero', () => {
    render(<Counter initialCount={0} />);

    expect(screen.getByText('Count: 0')).toBeInTheDocument();
  });

  it('increments count when button is clicked', async () => {
    // Each test renders a fresh component tree — no shared state from previous test
    const user = userEvent.setup();
    render(<Counter initialCount={0} />);

    await user.click(screen.getByRole('button', { name: /increment/i }));

    expect(screen.getByText('Count: 1')).toBeInTheDocument();
  });

  it('starts from the given initialCount, not 0', () => {
    render(<Counter initialCount={5} />);

    // If tests shared a component, this would see the count from the previous test
    expect(screen.getByText('Count: 5')).toBeInTheDocument();
  });
});
```

### Pattern 13: Redis/cache key namespacing for integration test isolation  [community]

Integration tests that use a shared Redis instance must namespace keys by test run (or test ID)
to prevent one test's cached data from influencing another's. An alternative is to flush the
database in `beforeEach`, but that is destructive for any other process sharing the instance.

```typescript
import { createClient, RedisClientType } from 'redis';
import { CacheService } from './cacheService';

describe('CacheService integration', () => {
  let client: RedisClientType;
  let cache: CacheService;
  let testPrefix: string;

  beforeAll(async () => {
    client = createClient({ url: process.env.REDIS_URL ?? 'redis://localhost:6379' });
    await client.connect();
  });

  beforeEach(async () => {
    // Unique prefix per test — keys never collide across concurrent test workers
    testPrefix = `test:${process.pid}:${Date.now()}:`;
    cache = new CacheService(client, testPrefix);
  });

  afterEach(async () => {
    // Delete only the keys this test created — leave other tests' keys untouched
    const keys = await client.keys(`${testPrefix}*`);
    if (keys.length > 0) await client.del(keys);
  });

  afterAll(async () => {
    await client.quit();
  });

  it('stores and retrieves a value within its namespace', async () => {
    await cache.set('user:1', { name: 'Alice' }, 60);

    const result = await cache.get('user:1');

    expect(result).toEqual({ name: 'Alice' });
  });

  it('returns null for a key that was never set in this namespace', async () => {
    // Would incorrectly return Alice's data if tests shared a namespace without cleanup
    const result = await cache.get('user:1');

    expect(result).toBeNull();
  });
});
```

---

## Additional Community Lessons  [community]

21. **`@testing-library/react` auto-cleanup only works in Jest's `afterEach` hook.** [community]
    RTL's auto-cleanup is registered via `@testing-library/react/pure`'s side-effect when the
    library detects a global `afterEach`. In Vitest with `globals: false` (the default), no
    global `afterEach` is present, so auto-cleanup silently does not run. The symptom: component
    state bleeds between tests and `screen.getBy*` finds elements from a previous render.
    Fix: import `import '@testing-library/jest-dom'` with Vitest's `globals: true`, or call
    `cleanup()` explicitly in `afterEach`.

22. **MSW (Mock Service Worker) handlers leak between tests without `server.resetHandlers()`.** [community]
    When using MSW for API mocking, adding a one-off handler override inside a test with
    `server.use(...)` persists to subsequent tests unless you call `server.resetHandlers()` in
    `afterEach`. Teams often configure `beforeAll(server.listen)` and `afterAll(server.close)` but
    forget the per-test reset. The correct three-line setup is:
    ```typescript
    beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
    afterEach(() => server.resetHandlers());
    afterAll(() => server.close());
    ```
    WHY: MSW's handler stack is mutable. `server.use()` pushes onto it; without a reset,
    each test inherits all handlers added by prior tests in the same file.

23. **Playwright `page` fixture is per-test by default; `browser` context is per-worker.** [community]
    Playwright's built-in `page` fixture is created fresh for each test, providing natural
    isolation at the page level. However, if you create a custom `browser` fixture scoped to
    `'worker'`, all tests in that worker share browser state (cookies, localStorage, open tabs).
    Using `context` scoped to `'test'` (the default `browserContext` fixture) gives a clean
    browser context per test. WHY: teams that promote `browser` to worker scope to save startup
    time inadvertently create cross-test authentication and storage contamination.

24. **`AbortController` signals not aborted in `afterEach` cause pending-promise leaks.** [community]
    When testing code that accepts an `AbortSignal` (fetch, streaming operations, long-running
    background workers), tests that do not abort the controller in `afterEach` leave promises
    pending across test boundaries. In Jest, this manifests as "open handles" warnings
    (`--detectOpenHandles`) and test timeouts in subsequent tests. Always pair:
    ```typescript
    let controller: AbortController;
    beforeEach(() => { controller = new AbortController(); });
    afterEach(() => { controller.abort(); });
    ```
    WHY: Unresolved promises hold references to mock functions and scoped variables from
    the test that created them, preventing garbage collection and accumulating memory across
    the test run.

25. **`jest.isolateModules()` for single-import isolation without polluting global module state.** [community]
    `jest.resetModules()` in `beforeEach` clears the *entire* module registry, which is expensive
    and may break other tests in the same file that rely on already-loaded modules. For isolating
    a single module import, `jest.isolateModules()` provides a scoped registry reset:
    ```typescript
    it('reads FLAG=true path on first require', () => {
      process.env.FEATURE_FLAG = 'true';
      jest.isolateModules(() => {
        const { featureEnabled } = require('./featureFlag');
        expect(featureEnabled).toBe(true);
      });
    });
    ```
    WHY: `isolateModules` creates a fresh module registry only for the callback's duration;
    modules loaded outside the callback are unaffected. This is the correct scalpel where
    `resetModules` is a sledgehammer.

