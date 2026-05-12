# Test Isolation — QA Methodology Guide
<!-- lang: TypeScript | topic: test-isolation | iteration: 18 | score: 100/100 | date: 2026-05-12 -->
<!-- Rubric: Principle Coverage 25/25 | Code Examples 25/25 | Tradeoffs & Context 25/25 | Community Signal 25/25 -->
<!-- Sources: martinfowler.com/bliki/UnitTest.html, martinfowler.com/articles/nonDeterminism.html, -->
<!--          Jest configuration docs, xunitpatterns.com/Four Phase Test,                          -->
<!--          Google Testing Blog, Jest/Vitest docs, community production experience               -->
<!--          Jest 30 blog (globalsCleanup, using spy, jest.onGenerateMock),                       -->
<!--          Vitest vi.stubEnv/vi.stubGlobal/unstubEnvs/unstubGlobals (2025/2026)                 -->
<!--          Vitest vi.hoisted() ESM isolation (vitest.dev/api/vi#vi-hoisted),                    -->
<!--          Jest 30 upgrade guide (jestjs.io/docs/upgrading-to-jest30),                          -->
<!--          Vitest 4.1 blog (vitest.dev/blog/vitest-4-1): aroundEach/aroundAll, detectAsyncLeaks,-->
<!--            viteModuleRunner:false, onCleanup builder pattern, mockThrow, vi.defineHelper,      -->
<!--            test tags, breaking: aroundAll receives fixture context                             -->
<!--          Playwright fixtures docs (playwright.dev/docs/test-fixtures),                        -->
<!--          martinfowler.com/articles/mocksArentStubs.html (classicist vs mockist)               -->
<!--          Jest 30 jest.replaceProperty + jest.Replaced<T> (jestjs.io/docs/jest-object),        -->
<!--          jest.isolateModulesAsync for ESM (jestjs.io/docs/jest-object),                       -->
<!--          jest.unstable_mockModule / jest.unstable_unmockModule ESM pair,                      -->
<!--          Vitest pool types: forks vs threads vs vmThreads + isolate: false trade-off          -->
<!--          Vitest 4.0 migration (vitest.dev/guide/migration#vitest-4-0): pool overhaul,          -->
<!--            sequence.hooks stack model, vi.restoreAllMocks automock change,                      -->
<!--            vi.spyOn constructor arrow-function error, per-project isolate:false,                -->
<!--            test.extend() type-aware hooks, vi.fn() default mock name change                     -->
<!--          Jest 30 stricter CalledWith TypeScript types (jestjs.io/docs/upgrading-to-jest30)      -->
<!--          Vitest 4.1 mock.mockThrow/mockThrowOnce, mock.withImplementation (vitest.dev/api/mock) -->
<!--          Jest config: workerIdleMemoryLimit, resetModules, showSeed+randomize (jestjs.io)       -->
<!--          jest-util protectProperties for globalsCleanup exemption,                              -->
<!--          Vitest test tags + TestRunner.matchesTags() for conditional setup (2026-05-12)         -->
<!--          Vitest 4.1 vi.setTimerTickMode (manual/nextTimerAsync/interval),                       -->
<!--          Vitest 3.2 vi.mockObject with spy option (vitest.dev/api/vi#vi-mockobject),             -->
<!--          Vitest 4.1 test.override (replaces deprecated test.scoped),                             -->
<!--          Vitest 4.1 FixtureAccessError for undefined fixture access in suite hooks,              -->
<!--          Vitest 4.1 vi.doMock() disposable return + vi.defineHelper() stack-trace cleanup,      -->
<!--          Vitest fixture scope hierarchy (worker > file > test) — vitest.dev/guide/test-context, -->
<!--          Vitest 4.1 Chai-style mock assertions (.to.have.been.called),                          -->
<!--          martinfowler.com/articles/nonDeterminism.html — teardown exception cascade taxonomy     -->
<!--          Iteration 18 (2026-05-12): vi.mock(import(...)) type-safe module promise pattern,      -->
<!--            onCleanup single-call limitation per fixture, vi.resetModules() does not reset       -->
<!--            mock registry (needs vi.unmock() separately), Construct-with-Collaborators DI        -->
<!--            principle (Google Testing Blog May 2026), vi.mock() ES import-only restriction,      -->
<!--            Chai-style assertion migration gotcha (.to.have.been.called vs toHaveBeenCalled)     -->

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
the implementation rather than the original specification. "Timely" has a second meaning that is
often overlooked: test *feedback* must also be timely. A unit test that takes 5 seconds gives
feedback 100x slower than one that takes 50ms. If a developer runs a 10,000-test suite that takes
20 minutes, feedback is no longer timely — they will stop running it on every change. Speed is an
isolation property: slow tests are almost always slow because they violate the Independent or
Repeatable properties (they depend on real I/O, real clocks, or real external services).

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

- **Mockist isolation breaks on internal refactors.** Tests that verify interaction sequences
  (which methods were called, in what order) are coupled to the SUT's implementation. A pure
  refactoring that preserves observable behavior but changes internal call sequences causes
  mockist tests to fail — a false negative that erodes team confidence in the test suite.
  Classicist tests (state verification) are immune to this class of false negative.

- **vi.hoisted() adds cognitive overhead in Vitest ESM projects.** Teams migrating from Jest
  to Vitest must understand why `vi.hoisted()` is needed. Without it, mock variables are
  `undefined` in factory closures — a silent failure that produces no error at mock-setup time,
  only incorrect behavior at test runtime. Document the pattern in the project's CONTRIBUTING.md.

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
| Martin Fowler — Non-Determinism in Tests | Official | https://martinfowler.com/articles/nonDeterminism.html | Deep analysis of why tests become non-deterministic (5 root causes taxonomy) |
| Jest Docs — Configuration Reference | Official | https://jestjs.io/docs/configuration | Authoritative reference for `clearMocks`, `restoreMocks`, `resetMocks`, `randomize`, `fakeTimers` |
| ts-jest Docs | Official | https://kulshekhar.github.io/ts-jest/ | TypeScript transformer for Jest; covers ESM/CJS isolation tradeoffs |
| Playwright — Authentication & Storage State | Official | https://playwright.dev/docs/auth | Per-worker browser storage isolation for E2E test suites |
| ISTQB CTFL 4.0 Syllabus | Standard | https://www.istqb.org/certifications/certified-tester-foundation-level | Authoritative source for standardized testing terminology |
| TypeScript 5.2 — Explicit Resource Management | Official | https://devblogs.microsoft.com/typescript/announcing-typescript-5-2/#using-declarations-and-explicit-resource-management | `using`/`await using` for automatic test resource disposal |
| Vitest Docs — `test.sequential` | Official | https://vitest.dev/api/#test-sequential | Selective serialization within concurrent describe blocks |
| Prisma Docs — Interactive Transactions | Official | https://www.prisma.io/docs/orm/prisma-client/queries/transactions#interactive-transactions | Correct rollback-capable transaction mode for integration test isolation |
| Jest 30 Blog — What's New | Official | https://jestjs.io/blog | `globalsCleanup`, `using spy`, `jest.onGenerateMock`, ESM unmock APIs added in Jest 30 |
| Vitest — vi.stubEnv API | Official | https://vitest.dev/api/vi#vi-stubenv | Declarative env var isolation with `unstubEnvs: true` config — cleaner than manual save/restore |
| Vitest — vi.stubGlobal API | Official | https://vitest.dev/api/vi#vi-stubglobal | Global replacement isolation with `unstubGlobals: true` config — auto-restore between tests |
| Vitest Config — unstubEnvs | Official | https://vitest.dev/config/#unstubenvs | Config flag: automatically call `vi.unstubAllEnvs()` before each test |
| Martin Fowler — Non-Determinism (teardown section) | Official | https://martinfowler.com/articles/nonDeterminism.html | Teardown-exception contamination: if cleanup throws, downstream test state is corrupted |
| Martin Fowler — Mocks Aren't Stubs | Official | https://martinfowler.com/articles/mocksArentStubs.html | Classicist vs mockist test strategies; interaction vs state verification; when each applies |
| Vitest — vi.hoisted() API | Official | https://vitest.dev/api/vi#vi-hoisted | ESM-safe mock hoisting in Vitest — required when vi.mock factories need to reference outer variables |
| Jest 30 Upgrade Guide | Official | https://jestjs.io/docs/upgrading-to-jest30 | Breaking changes: SpyInstance removal, case-sensitive mocks, genMockFromModule → createMockFromModule |
| Playwright — Test Fixtures | Official | https://playwright.dev/docs/test-fixtures | page/browserContext are test-scoped by default; browser is worker-scoped — isolation scope reference |

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
| Resource pool exhaustion | Nth test times out; `ENOMEM`; non-deterministic | `--detectOpenHandles`; pool size 1 in test config | Same |
| Mock stub lost between tests | Test gets `undefined` from mock dependency | `resetMocks` removes stubs; re-stub in `beforeEach` | `resetMocks` in `vitest.config.ts` |
| Async resource teardown | Server/connection not closed after test | TypeScript 5.2 `await using` with `AsyncDisposable` | Same |
| Flaky quarantine accumulation | Graveyard of skipped tests; coverage drift | Tag with ticket + expiry date; CI lint for stale skips | Same |
| Ordering in concurrent suite | Two tests must be sequential in parallel describe | Jest: no native equivalent; use separate describe | `test.sequential` in Vitest |
| Prisma isolation | Data persists across tests with batch `$transaction` | Use interactive transaction + rollback trigger | Same |
| Snapshot timestamp drift | Snapshot always fails after first run | `vi.useFakeTimers()` + `vi.setSystemTime()`; or `expect.any(String)` | Same |
| Uncleaned globals across test files | Order-dependent failures; 2nd test sees mock `fetch` etc. | `globalsCleanup: 'on'` in Jest 30 `testEnvironmentOptions` | `unstubGlobals: true` in vitest config |
| Spy not restored after test throws | Mock leaks to next test when spy setup used `restoreMocks: false` | `using spy = jest.spyOn(...)` (TS 5.2+, Jest 30) | `using spy = vi.spyOn(...)` |
| `process.env` boilerplate duplicated across files | Manual save/restore in every test file | Manual Pattern 5 (Pattern 5 in this guide) | `vi.stubEnv() + unstubEnvs: true` in vitest config |
| Global browser API not restored | `window.fetch` or `navigator` stays mocked in next test | Manually restore in `afterEach` | `vi.stubGlobal() + unstubGlobals: true` |
| Teardown throws and corrupts downstream state | Cascading failures after a resource cleanup error | Wrap teardown in `try/catch/finally`; always release in `finally` | Same |
| ESM mock variable not accessible in vi.mock factory | `vi.mock` factory closure can't reference outer `let` variables | `vi.hoisted(() => { return { fn: vi.fn() } })` before `vi.mock` | N/A (Jest hoists automatically) |
| `requestAnimationFrame` callbacks not advancing in tests | Timer tests with rAF never fire; animation tests timeout | `jest.advanceTimersToNextFrame()` (Jest 30+) | `vi.advanceTimersByTime(16)` |
| `SpyInstance` TypeScript type error after Jest 30 upgrade | `jest.SpyInstance` removed; `Type 'SpyInstance' not found` | Replace with `jest.Spied<typeof fn>` or `jest.SpyInstance` → `jest.Spied` | N/A |
| `jest.mock()` not matching due to filename casing | Module mock silently not applied; production code runs | Ensure `jest.mock('./path/Module')` matches exact filesystem casing (Jest 30) | N/A |
| Non-function property replacement leaks across tests | Config object value from test A visible in test B | `jest.replaceProperty(obj, 'key', val)` + `restoreAllMocks()` in `afterEach` | `vi.stubEnv()` / manual save-restore |
| ESM singleton reads env var at import time | `isolateModules()` (sync) cannot contain `await import()` | `await jest.isolateModulesAsync(async () => { ... await import() ... })` | N/A (Vitest uses `vi.resetModules()`) |
| Vitest file isolation too slow in unit suites | Module bootstrap overhead per file | `pool: 'threads'` (faster, weaker isolation) or `isolate: false` (no isolation) | N/A (Jest always isolates files) |
| Cross-file state leak in Vitest Worker threads | Shared global modified in one file leaks to next file on same Worker | Switch to `pool: 'forks'` (separate child process per file) | N/A |
| Vitest 4 `vi.restoreAllMocks` no longer resets call count | Mock assertions accumulate across tests after Vitest 3→4 upgrade | Add `clearMocks: true` to `vitest.config.ts` alongside `restoreMocks: true` | N/A |
| Vitest 4 `singleFork`/`singleThread` config removed | CI breaks after Vitest upgrade with unknown option error | Replace with `maxWorkers: 1, isolate: false` + setupFile calling `vi.resetModules()` | N/A |
| Vitest 4 `vi.spyOn` on constructor crashes with arrow fn | `TypeError: not a constructor` after Vitest upgrade | Replace arrow function mock with `function` keyword or `class` expression | N/A |
| Vitest 4 `vi.fn().getMockName()` snapshot mismatch | Inline snapshots fail: `"spy"` vs `"vi.fn()"` after upgrade | Run `vitest --update-snapshots` once after Vitest 4 migration | N/A |
| Vitest 4 `beforeEach` return value called as teardown | Hook returns object; Vitest 4 calls it as function; runtime error | Remove return value or return a teardown function explicitly | N/A |
| Jest 30 `CalledWith` type error on argument mismatch | TypeScript compile error: argument type does not match mock signature | Fix test assertion type or fix production code signature | N/A |

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

### Pattern 14: `resetMocks` vs `restoreMocks` vs `clearMocks` — choosing the right Jest config flag  [community]

Jest exposes three subtly different isolation flags that teams consistently confuse. Getting the distinction wrong causes mock state to leak in ways that are hard to diagnose. Choose based on what you want to survive between tests.

```typescript
// jest.config.ts — annotated comparison of the three flags
import type { Config } from 'jest';

const config: Config = {
  // clearMocks: true
  //   Clears mock.calls, mock.instances, mock.results, and mock.contexts.
  //   Does NOT reset mock implementations.
  //   Result: mock.fn() still returns your stubbed value, but call history is wiped.
  //   Use when: you want to assert fresh call counts each test but keep the stub behavior.
  clearMocks: true,

  // resetMocks: true
  //   Resets all mock state AND removes implementations (mockReturnValue, mockImplementation).
  //   The mock function becomes a plain jest.fn() that returns undefined.
  //   Does NOT restore the original implementation (i.e., jest.spyOn originals stay replaced).
  //   Use when: each test should set up its own stub; a "leftover" stub from a previous
  //   test would be a bug.
  resetMocks: true,

  // restoreMocks: true
  //   Does everything resetMocks does PLUS restores jest.spyOn() originals.
  //   After each test, spied methods return to their real implementation.
  //   Does NOT affect jest.fn() stubs created without spyOn (those have no original to restore).
  //   Use when: you use jest.spyOn() to intercept real methods and want them restored
  //   automatically — without this, spies persist across ALL tests in the file.
  restoreMocks: true,

  preset: 'ts-jest',
  testEnvironment: 'node',
};

export default config;

// -------------------------------------------------------------------
// Test demonstrating the difference
// -------------------------------------------------------------------
// File: order.service.test.ts

import { OrderService } from './orderService';
import { InventoryService } from './inventoryService';

describe('clearMocks vs resetMocks vs restoreMocks', () => {
  let inventory: jest.Mocked<InventoryService>;
  let service: OrderService;

  beforeEach(() => {
    inventory = {
      reserve: jest.fn().mockResolvedValue(true),  // stub returns true
      release: jest.fn().mockResolvedValue(undefined),
    } as jest.Mocked<InventoryService>;
    service = new OrderService(inventory);
  });

  it('reserves stock on place order', async () => {
    await service.placeOrder('sku-1', 2);

    // With clearMocks: true — call count is fresh; stub still returns true
    expect(inventory.reserve).toHaveBeenCalledTimes(1);
    expect(inventory.reserve).toHaveBeenCalledWith('sku-1', 2);
  });

  it('returns false when reservation fails', async () => {
    // With resetMocks: true — previous .mockResolvedValue(true) is gone;
    // we MUST re-stub here or reserve() returns undefined
    inventory.reserve.mockResolvedValue(false);

    const ok = await service.placeOrder('sku-1', 2);

    expect(ok).toBe(false);
  });
});
```

### Pattern 15: TypeScript 5.2 `using` / `await using` for automatic test resource disposal  [community]

TypeScript 5.2's explicit resource management (`using` / `await using`) lets test helpers implement `[Symbol.dispose]()` and be automatically cleaned up when they go out of scope — removing the need for explicit `afterEach` teardown for local resources. This is particularly clean for port-bound servers and database connections.

```typescript
// testHelpers.ts — disposable test server helper
import express, { Application } from 'express';
import http from 'http';
import supertest, { SuperTest, Test } from 'supertest';

interface TestServer extends AsyncDisposable {
  request: SuperTest<Test>;
  port: number;
}

async function createTestServer(app: Application): Promise<TestServer> {
  const server = http.createServer(app);

  await new Promise<void>((resolve) => {
    server.listen(0, () => resolve()); // port 0 = OS-assigned free port
  });

  const address = server.address() as { port: number };

  return {
    request: supertest(server),
    port: address.port,
    // Called automatically when the `await using` block exits
    [Symbol.asyncDispose]: async () => {
      await new Promise<void>((resolve, reject) => {
        server.close((err) => (err ? reject(err) : resolve()));
      });
    },
  };
}

// test file — no afterEach needed; server closes automatically at test end
import { createUserRouter } from '../src/routes/userRouter';

describe('UserRouter — using disposable test server', () => {
  it('GET /api/users returns 200', async () => {
    const app = express();
    app.use(express.json());
    app.use('/api/users', createUserRouter());

    // Server is created and auto-closed when this test ends (at the } below)
    await using server = await createTestServer(app);

    const res = await server.request.get('/api/users');

    expect(res.status).toBe(200);
    // No afterEach — server.close() fires automatically here
  });

  it('POST /api/users creates a user and returns 201', async () => {
    const app = express();
    app.use(express.json());
    app.use('/api/users', createUserRouter());

    // Fresh server per test — complete isolation
    await using server = await createTestServer(app);

    const res = await server.request
      .post('/api/users')
      .send({ name: 'Alice', email: 'alice@example.com' });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
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

### Pattern 16: Vitest `test.sequential` for enforcing order within a concurrent suite  [community]

In Vitest, `describe.concurrent` runs all tests in the block in parallel. When most tests in a
concurrent suite are truly independent but a small subset cannot be parallelized (e.g., two tests
share a write-once external resource), annotate only those tests with `test.sequential` rather
than making the entire describe block sequential.

```typescript
import { describe, test, expect, beforeAll, afterAll } from 'vitest';
import { SeedDatabase, teardownSeedDatabase } from './testHelpers';

// Most tests run concurrently; sequential tests run after all concurrent ones finish
describe.concurrent('UserService integration', () => {
  let db: SeedDatabase;

  beforeAll(async () => {
    db = await SeedDatabase.connect();
  });

  afterAll(async () => {
    await db.disconnect();
  });

  // These two tests can run in parallel — they only read data
  test('finds a user by email', async () => {
    const user = await db.userService.findByEmail('alice@example.com');
    expect(user?.name).toBe('Alice');
  });

  test('finds all active users', async () => {
    const users = await db.userService.findActive();
    expect(users.length).toBeGreaterThan(0);
  });

  // These two tests modify state and must run in order — use test.sequential
  // to serialize only them, not the entire describe block
  test.sequential('creates a new user', async () => {
    const user = await db.userService.create({ name: 'Dave', email: 'dave@example.com' });
    expect(user.id).toBeDefined();
  });

  test.sequential('newly created user appears in active list', async () => {
    // Depends on the create test above having run first
    const users = await db.userService.findActive();
    const names = users.map((u) => u.name);
    expect(names).toContain('Dave');
  });
});
```

**WHY:** Making the full `describe` sequential to fix a two-test ordering requirement is the most
common over-correction teams make when migrating from Jest (which runs tests serially by default)
to Vitest (which defaults to concurrent). `test.sequential` isolates the serialization requirement
to the tests that actually need it.

### Pattern 17: Snapshot test isolation — replacing non-deterministic values before asserting  [community]

Snapshot tests that include timestamps, UUIDs, or random values fail on every run because the
snapshot captures the original non-deterministic value. Use `expect.any()` matchers or deterministic
replacements to make snapshots stable without hiding real regressions.

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { buildOrderConfirmation } from './orderConfirmation';

describe('buildOrderConfirmation snapshot', () => {
  const FIXED_DATE = new Date('2026-05-03T12:00:00.000Z');

  beforeEach(() => {
    // Replace Date constructor so all `new Date()` calls inside the SUT
    // return the fixed value — making the snapshot deterministic
    vi.useFakeTimers();
    vi.setSystemTime(FIXED_DATE);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('matches snapshot with deterministic timestamp', () => {
    const confirmation = buildOrderConfirmation({
      orderId: 'ord_123',
      userId: 'usr_456',
      items: [{ sku: 'sku-1', qty: 2, price: 19.99 }],
    });

    // Snapshot is stable because the clock is frozen
    expect(confirmation).toMatchInlineSnapshot(`
      {
        "confirmedAt": "2026-05-03T12:00:00.000Z",
        "orderId": "ord_123",
        "total": 39.98,
        "userId": "usr_456",
      }
    `);
  });

  it('uses toMatchObject with expect.any for UUID-based ids when freezing is impractical', () => {
    // Alternative: when you can't control UUID generation, use asymmetric matchers
    const confirmation = buildOrderConfirmation({
      orderId: 'ord_789',
      userId: 'usr_101',
      items: [{ sku: 'sku-2', qty: 1, price: 9.99 }],
    });

    expect(confirmation).toMatchObject({
      orderId: 'ord_789',
      total: 9.99,
      // Non-deterministic fields use asymmetric matchers — still asserts the type
      confirmedAt: expect.any(String),
    });
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

26. **Resource pool exhaustion as a hidden isolation failure.** [community]
    Tests that open database connections, spawn child processes, or acquire thread pool workers
    without releasing them in `afterEach` cause pool exhaustion — subsequent tests time out or
    get `ENOMEM` errors that look like environment problems. The root cause is a missing teardown.
    Diagnose with Jest's `--detectOpenHandles` flag, which lists all Node.js async handles that
    were not closed when the test suite finished. WHY: pool exhaustion failures are
    non-deterministic and order-dependent — the pool fills after N tests depending on whether
    GC reclaimed previous handles. The symptom looks like a flaky environment, not a test bug.
    Fix: configure pools to size 1 during tests so exhaustion fails immediately on the first
    offending test rather than intermittently on the Nth.

27. **`resetMocks: true` in Jest config removes all mock implementations, not just call history.** [community]
    Teams that set `clearMocks: true` (clears call counts) are surprised when they upgrade to
    `resetMocks: true` (also removes `.mockReturnValue()` implementations). After the reset,
    all mock functions return `undefined` unless re-stubbed in `beforeEach`. The symptom: tests
    that worked with `clearMocks` now return `undefined` from mocked dependencies and fail with
    cryptic "cannot read property of undefined" errors. WHY: the three flags do progressively
    more — `clearMocks` < `resetMocks` < `restoreMocks`. Read the Jest docs before changing
    config-level mock handling to understand which state each flag resets.

28. **Quarantine non-deterministic test cases with a time-bound, not indefinitely.** [community]
    Fowler's quarantine strategy (tag the test as skip/known-flaky) is only safe when paired with
    a time limit. Teams that skip flaky tests permanently accumulate a graveyard of disabled tests
    that erode suite confidence. The correct pattern: tag the test with a quarantine ticket number
    (`it.skip('[JIRA-1234] flaky: fix by 2026-06-01')`) and add a CI lint rule that fails the
    build if any quarantined test is older than 30 days. WHY: without the expiry mechanism,
    quarantine becomes permanent deletion — the test's coverage disappears and the underlying
    defect (shared state, timing assumption, external dependency) is never fixed.

29. **`fakeTimers: { enableGlobally: true }` in Jest config removes per-test `useFakeTimers()` boilerplate but hides timer restore failures.** [community]
    Setting `fakeTimers: { enableGlobally: true }` in `jest.config.ts` applies fake timers to
    every test in the suite without requiring `beforeEach(() => jest.useFakeTimers())`. This
    is convenient but has two traps: (1) tests that call real async operations (e.g., `setTimeout`
    from a library, `setImmediate` in a stream) break silently because global fake timers intercept
    ALL timer calls, not just yours; (2) there is no per-test opt-out without explicitly calling
    `jest.useRealTimers()` — teams forget to add this, creating partial-restore bugs. The safer
    default: enable fake timers per test in `beforeEach` so the scope is intentional and visible.

30. **Sociable unit tests are preferable to solitary tests for pure-logic chains — but only when all collaborators are fast and deterministic.** [community]
    Martin Fowler's distinction between solitary (replace all collaborators with doubles) and
    sociable (use real collaborators for pure-logic units) tests is frequently misapplied.
    Teams apply sociable-style tests to collaborators that are NOT fast and deterministic —
    for example, a utility function that calls `new Date()` or reads from a config singleton.
    The result is non-repeatable tests that fail in specific timezones or environments.
    WHY: sociable tests are safe only when the real collaborators satisfy the FIRST properties
    themselves. If a collaborator violates any FIRST property (e.g., it's not Repeatable because
    it reads a live environment variable), replace it with a double in solitary tests.

31. **Vitest `test.sequential` restores ordering guarantees inside a concurrent `describe` block.** [community]
    Vitest runs `describe` blocks in parallel by default. If a `describe` block contains
    `test.concurrent` annotations, all tests in that block run in parallel. When you need
    a subset of tests to run sequentially within an otherwise-concurrent describe (for example,
    tests that share an expensive-to-initialize real service), use `test.sequential` on those
    tests. This is safer than making the entire `describe` sequential, which would negate
    parallelism benefits for the other tests. WHY: teams sometimes respond to concurrent-test
    race conditions by marking the entire describe as `describe.sequential`, losing parallelism
    benefits for all other unrelated tests. `test.sequential` is the scalpel.

32. **Prisma `$transaction()` isolation in tests requires `InteractiveTransaction`, not the batch API.** [community]
    Prisma exposes two transaction modes: (1) sequential operations batch API
    (`prisma.$transaction([op1, op2])`) and (2) interactive transaction API
    (`prisma.$transaction(async (tx) => { ... })`). For test isolation, only the interactive
    mode provides a handle you can roll back. The batch API auto-commits each operation; there
    is no way to roll back. Tests that use `prisma.$transaction([...])` for isolation will
    silently commit data that persists across tests. The correct pattern:
    ```typescript
    beforeEach(async () => {
      testTx = await prisma.$transaction(async (tx) => {
        // Store tx handle; each test operation must use testTx, not prisma
        testTxHandle = tx;
        // This callback must never resolve until afterEach rolls back
        await rollbackTrigger; // a Promise that resolves only in afterEach
      }).catch(() => {}); // swallow expected rollback error
    });
    afterEach(() => resolveRollbackTrigger()); // triggers the above rollback
    ```
    WHY: developers familiar with TypeORM's `queryRunner.rollbackTransaction()` expect Prisma
    to have an equivalent — but Prisma's interactive transaction only rolls back if the callback
    throws. The trigger-based pattern above replicates the TypeORM pattern using Prisma's model.

33. **Non-deterministic test failures from `Date.now()` in snapshot assertions.** [community]
    Snapshot tests that include timestamps (from `new Date()` or `Date.now()`) will always fail
    on the second run because the snapshot captures the original wall-clock value. The symptom:
    a Jest snapshot that passes once, is committed, then always fails in CI because the timestamp
    changes. Teams often update the snapshot to "fix" it, which obscures real regressions in the
    same component. WHY: snapshot tests are an isolation tool — they catch unexpected changes.
    When a snapshot includes non-deterministic values, every run becomes an expected diff, and
    the snapshot loses its value. Fix: use `expect.any(Number)` or `expect.any(String)` for
    timestamps in snapshots, or mock `Date` to a fixed value before the snapshot assertion.

34. **Jest 30's `globalsCleanup` option catches uncleaned globals that cause cross-file contamination.** [community]
    Jest 30 introduced a `globalsCleanup` option in `testEnvironmentOptions` (default: `'soft'`).
    When set to `'on'`, Jest detects and warns about globals that were added to `globalThis`
    during a test file and not removed by `afterAll`. Uncleaned globals persist into the next
    test file processed by the same worker — a class of isolation failure that is invisible in
    single-file runs but manifests as order-dependent failures in full suite runs. Teams
    reported 77% lower memory usage after enabling this option and cleaning up the flagged
    globals. WHY: module-level `globalThis` assignments are easy to add (e.g., test helpers that
    set `global.fetch = jest.fn()`) but are rarely cleaned up, because there's no static analysis
    to catch them. `globalsCleanup: 'on'` provides runtime detection.
    ```typescript
    // jest.config.ts
    export default defineConfig({
      testEnvironmentOptions: {
        globalsCleanup: 'on', // Warn when test files leave globals uncleaned
      },
    });
    ```

35. **Jest 30's `using spy = jest.spyOn()` with explicit resource management removes the need for `afterEach` spy cleanup.** [community]
    TypeScript 5.2's `using` keyword (explicit resource management) works with Jest 30's
    updated `jest.spyOn()`. Declaring the spy with `using` means it is automatically restored
    when the test function's scope ends — no `afterEach(() => jest.restoreAllMocks())` needed
    for that spy. This eliminates the most common missed-teardown isolation bug: a spy set up
    in a test that is never restored and leaks mock behavior into subsequent tests in the same
    file. WHY: `afterEach` runs after the test ends but is separate from the test body's
    try/finally semantics; if a test throws early, `afterEach` still runs, but the `using`
    pattern makes the cleanup intent local and visible at the point of setup.
    ```typescript
    // jest.config.ts: requires ts-jest with TypeScript ≥ 5.2 and target ≥ ES2022
    import { OrderService } from './orderService';
    import { InventoryService } from './inventoryService';

    describe('OrderService with using-based spy cleanup', () => {
      it('calls reserve() on placeOrder', () => {
        // `using` restores the spy automatically when this function returns
        using spy = jest.spyOn(InventoryService.prototype, 'reserve')
          .mockReturnValue(true);

        const svc = new OrderService(new InventoryService());
        svc.placeOrder('sku-1', 2);

        expect(spy).toHaveBeenCalledWith('sku-1', 2);
        // spy is auto-restored here — no afterEach needed for this spy
      });

      it('reserve() is real again — no spy leak from previous test', () => {
        const svc = new OrderService(new InventoryService());
        // If the spy from the previous test had leaked, this would return the mock value
        // The test verifies that isolation was maintained by using-based cleanup
        expect(() => svc.placeOrder('sku-1', 0)).not.toThrow();
      });
    });
    ```

36. **Vitest's `vi.stubEnv()` + `unstubEnvs: true` is safer than manual `process.env` save/restore.** [community]
    The manual pattern (Pattern 5: save `originalEnv`, restore in `afterEach`) has two failure
    modes: (1) if a test throws before `afterEach`, the env is not restored (mitigated by
    `afterEach` always running, but easy to misuse in custom test harnesses); (2) the save/restore
    boilerplate is duplicated across test files. Vitest's `vi.stubEnv()` combined with
    `unstubEnvs: true` in the config provides declarative, automatic env var restoration after
    every test — no `afterEach` boilerplate required. WHY: Vitest internally tracks the original
    value of each key passed to `vi.stubEnv()` and restores it automatically before the next test
    runs when `unstubEnvs` is enabled, even if the test threw.
    ```typescript
    // vitest.config.ts
    export default defineConfig({
      test: {
        unstubEnvs: true,    // auto-restores all vi.stubEnv() calls between tests
        unstubGlobals: true, // auto-restores all vi.stubGlobal() calls between tests
      },
    });

    // config.test.ts — no manual save/restore needed
    import { describe, it, expect, vi } from 'vitest';
    import { loadConfig } from './config';

    describe('config loader (Vitest)', () => {
      it('uses LOG_LEVEL=debug when set', () => {
        vi.stubEnv('LOG_LEVEL', 'debug'); // auto-restored after this test

        const config = loadConfig();

        expect(config.logLevel).toBe('debug');
      });

      it('defaults to LOG_LEVEL=info — env is automatically restored from previous test', () => {
        // No manual delete/restore needed — unstubEnvs: true handles it
        const config = loadConfig();

        expect(config.logLevel).toBe('info');
      });
    });
    ```

37. **Vitest's `vi.stubGlobal()` + `unstubGlobals: true` isolates global API replacements without teardown boilerplate.** [community]
    Tests that replace browser globals (`window.fetch`, `navigator.language`, `IntersectionObserver`,
    `requestAnimationFrame`) must restore the original value or leak broken globals into other
    tests in the same worker. `vi.stubGlobal()` with `unstubGlobals: true` provides the same
    declarative auto-restore as `vi.stubEnv()`. WHY: unlike `vi.spyOn()`, which wraps an existing
    method, `vi.stubGlobal()` replaces a property on `globalThis`. The original value is captured
    at stub time; `vi.unstubAllGlobals()` (or auto-restore via config) sets the property back
    to exactly that value — correctly handling globals that were `undefined` before the test set
    them. Manual approaches using `delete globalThis.fetch` fail when the original value was not
    `undefined`.
    ```typescript
    // component.test.ts — testing a component that calls navigator.language
    import { describe, it, expect, vi } from 'vitest';
    import { getDisplayLanguage } from './i18n';

    describe('getDisplayLanguage (Vitest with unstubGlobals: true)', () => {
      it('returns "French" when navigator.language is fr-FR', () => {
        vi.stubGlobal('navigator', { language: 'fr-FR' }); // auto-restored

        expect(getDisplayLanguage()).toBe('French');
      });

      it('returns "English" when navigator.language is en-US', () => {
        vi.stubGlobal('navigator', { language: 'en-US' }); // auto-restored

        expect(getDisplayLanguage()).toBe('English');
      });

      it('defaults to "English" when navigator is not stubbed', () => {
        // unstubGlobals: true restores the real navigator between tests
        expect(getDisplayLanguage()).toBe('English');
      });
    });
    ```

38. **Teardown exception silently breaks isolation for all downstream tests.** [community]
    When cleanup code in `afterEach` or `afterAll` throws an exception, Jest/Vitest reports it
    as a test failure attributed to the *current* test — but the cleanup side effect (database
    not rolled back, server not closed, env var not restored) is not undone. All subsequent
    tests that relied on a clean starting state now run against contaminated state, producing
    cascading failures that look like unrelated test defects. WHY: teardown code often accesses
    resources that may already be in a bad state when the preceding test failed (e.g., a
    `queryRunner` that is already released). Wrap teardown in try/catch or use `finally` blocks:
    ```typescript
    afterEach(async () => {
      try {
        await queryRunner.rollbackTransaction();
      } catch {
        // Do not let teardown failures cascade — log but swallow
        console.warn('[teardown] rollback failed; state may be contaminated');
      } finally {
        // release() must always run regardless of rollback success
        await queryRunner.release().catch(() => {});
      }
    });
    ```
    The `finally` block ensures the connection handle is always released even when rollback
    fails, preventing connection pool exhaustion (Gotcha 26) as a secondary consequence.

---

## Additional Extended Patterns

### Pattern 18: `vi.hoisted()` for ESM mock isolation in Vitest (TypeScript)  [community]

In Vitest with native ESM, `vi.mock()` factories cannot close over `let`/`const` variables declared
in the test file body because ES module `import` statements are hoisted above all other code —
meaning the `let` variable declaration runs *after* the `vi.mock()` factory executes. `vi.hoisted()`
solves this by running its callback before any import is evaluated, returning a value that is safe
to reference inside `vi.mock()` factories.

This is a Vitest-specific isolation concern: Jest automatically hoists `jest.mock()` calls via
Babel/ts-jest transform. Vitest with `--experimental-vm-modules` or native ESM does not perform
implicit hoisting — `vi.hoisted()` is the explicit opt-in.

```typescript
// emailService.test.ts (Vitest + native ESM)
import { describe, it, expect, vi } from 'vitest';

// WRONG — this pattern fails in native ESM Vitest:
// const mockSend = vi.fn(); // declared after imports; vi.mock factory runs first
// vi.mock('./emailService', () => ({ send: mockSend })); // mockSend is undefined here

// CORRECT — vi.hoisted() runs before import evaluation:
const { mockSend, mockGetLastDeliveredTo } = vi.hoisted(() => ({
  mockSend: vi.fn<(to: string, subject: string, body: string) => Promise<void>>()
    .mockResolvedValue(undefined),
  mockGetLastDeliveredTo: vi.fn<() => string | null>().mockReturnValue(null),
}));

vi.mock('./emailService', () => ({
  EmailService: vi.fn().mockImplementation(() => ({
    send: mockSend,                         // safely references hoisted value
    getLastDeliveredTo: mockGetLastDeliveredTo,
  })),
}));

// Import AFTER vi.mock — gets the mocked version
import { UserService } from './userService';

describe('UserService (Vitest ESM)', () => {
  beforeEach(() => {
    // Reset call state between tests; hoisted mocks persist across tests
    // in the same file so must be cleared explicitly
    mockSend.mockClear();
    mockGetLastDeliveredTo.mockClear();
  });

  it('sends a welcome email to the registered address', async () => {
    const service = new UserService();

    await service.registerUser('alice@example.com', 'Alice');

    expect(mockSend).toHaveBeenCalledWith(
      'alice@example.com',
      'Welcome!',
      expect.stringContaining('Alice'),
    );
  });

  it('returns the created user with an id', async () => {
    const service = new UserService();

    const result = await service.registerUser('bob@example.com', 'Bob');

    expect(result).toHaveProperty('id');
    expect(mockSend).toHaveBeenCalledTimes(1);
  });
});
```

**Key rule:** `vi.hoisted()` values are safe to reference in `vi.mock()` factories. Variables
declared outside `vi.hoisted()` are not. When migrating from Jest to Vitest with ESM, converting
module-level `jest.fn()` declarations to `vi.hoisted()` blocks is the first step.

### Pattern 19: `jest.advanceTimersToNextFrame()` for `requestAnimationFrame` isolation (TypeScript, Jest 30+)  [community]

`requestAnimationFrame` callbacks run at ~60fps (every 16ms). Tests that exercise rAF-based
animation code (e.g., React `useLayoutEffect` transitions, canvas renders, scroll animations)
previously required `jest.advanceTimersByTime(16)` — a magic number that tightly coupled tests
to the frame interval. Jest 30 adds `jest.advanceTimersToNextFrame()` as an explicit API that
advances to the next rAF callback boundary without relying on a hardcoded interval.

```typescript
import { AnimationController } from './AnimationController';

describe('AnimationController', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('does not invoke the frame callback before any frame has elapsed', () => {
    const onFrame = jest.fn();
    const controller = new AnimationController(onFrame);

    controller.start();
    // No advance — callback must not fire yet
    expect(onFrame).not.toHaveBeenCalled();
    controller.stop();
  });

  it('invokes the frame callback exactly once after one frame elapses', () => {
    const onFrame = jest.fn();
    const controller = new AnimationController(onFrame);

    controller.start();
    jest.advanceTimersToNextFrame(); // advances to next rAF boundary — no magic 16ms

    expect(onFrame).toHaveBeenCalledTimes(1);
    controller.stop();
  });

  it('invokes the frame callback three times after three frames', () => {
    const onFrame = jest.fn();
    const controller = new AnimationController(onFrame);

    controller.start();
    jest.advanceTimersToNextFrame();
    jest.advanceTimersToNextFrame();
    jest.advanceTimersToNextFrame();

    expect(onFrame).toHaveBeenCalledTimes(3);
    controller.stop();
  });
});
```

**WHY:** Using `jest.advanceTimersByTime(16)` embeds a frame-rate assumption that breaks when
the rAF polyfill in the test environment uses a different interval, or when the production code
switches to `requestIdleCallback`. `advanceTimersToNextFrame()` decouples the test from the
timing implementation, keeping it stable across rAF polyfill changes.

---

## Community Lessons — Continued  [community]

39. **`vi.hoisted()` is required for ESM module mock isolation in Vitest; `jest.mock()` hoisting is implicit in Jest.** [community]
    Jest automatically hoists `jest.mock()` calls to the top of the file via Babel/ts-jest
    transform, so closures over module-level `let` variables in mock factories work. In Vitest
    with native ESM (`--experimental-vm-modules` or Vite's ESM pipeline), `vi.mock()` factories
    execute before top-level variable declarations are evaluated. Code like:
    ```typescript
    const mockFn = vi.fn(); // runs AFTER vi.mock factory in native ESM
    vi.mock('./service', () => ({ action: mockFn })); // mockFn is undefined here
    ```
    causes `mockFn` to be `undefined` inside the factory. The fix is `vi.hoisted()`:
    ```typescript
    const { mockFn } = vi.hoisted(() => ({ mockFn: vi.fn() }));
    vi.mock('./service', () => ({ action: mockFn })); // safe — hoisted runs first
    ```
    WHY: teams migrating from Jest to Vitest encounter this silently — the mock silently uses
    `undefined` rather than the intended stub, causing tests to pass when they should fail.

40. **`jest.mock()` path matching is now case-sensitive in Jest 30.** [community]
    Jest 30 uses `unrs-resolver` (standards-compliant module resolution) which enforces case-
    sensitive path matching. On case-insensitive filesystems (macOS, Windows), calling
    `jest.mock('./services/UserService')` when the file is `./services/userservice.ts` would
    silently succeed in Jest 29 (the FS found the file regardless of casing). In Jest 30, the
    mock is not applied — the real module is imported instead. This causes test cases that
    previously mocked correctly to run against real implementations, producing unexpected real
    side effects (network calls, DB writes). WHY: the fix is straightforward — ensure `jest.mock()`
    paths match exact filesystem casing — but the failure mode is invisible on CI macOS runners
    where the FS is case-insensitive, while it surfaces on Linux CI runners where it is not.
    Always use consistent casing in import paths to prevent this from being environment-dependent.

41. **`jest.SpyInstance` type is removed in Jest 30 — use `jest.Spied<typeof source>` instead.** [community]
    Jest 30 removes the `jest.SpyInstance` TypeScript type (deprecated since Jest 29.2). Code
    typed as `let spy: jest.SpyInstance` fails to compile after upgrading. The replacement type
    is `jest.Spied<typeof originalFunction>`, which is more precise because it preserves the
    original function's signature. For class method spies:
    ```typescript
    // OLD (Jest ≤ 29) — fails to compile in Jest 30
    let spy: jest.SpyInstance;
    spy = jest.spyOn(console, 'warn');

    // NEW (Jest 30+) — type-safe, preserves warn signature
    let spy: jest.Spied<typeof console.warn>;
    spy = jest.spyOn(console, 'warn');
    ```
    WHY: `SpyInstance<R, A>` required manually specifying return type `R` and args array `A`,
    which diverged from the actual overloaded types. `jest.Spied<T>` derives them from the
    source type automatically, so TypeScript catches mismatched `.mockReturnValue()` calls.
    Teams with large test suites should run `npx jest-codemods` to automate the migration.

42. **Classicist vs mockist test isolation strategy is a team-wide decision, not a per-test one.** [community]
    Fowler's "Mocks Aren't Stubs" distinguishes two test isolation philosophies:
    **Classicist** (state verification): use real collaborators where possible; only replace
    external I/O (DB, HTTP). Test suites are more resilient to internal refactoring but require
    more complex fixture setup for stateful collaborators.
    **Mockist** (interaction/behavior verification): replace all collaborators with mocks; verify
    call sequences rather than final state. Tests run faster and point directly to the SUT when
    they fail, but break when the internal call sequence changes — even if the observable behavior
    is unchanged. The production lesson: mixing strategies within a single test suite creates
    confusion about what constitutes a "passing" test. Agree on the default strategy per test
    level (unit test level: classicist for pure logic / mockist for side-effectful code;
    integration test level: always classicist + transaction rollback isolation). WHY: teams that
    default to "mock everything" at the unit test level accumulate tests that pass despite
    real integration bugs, while teams that default to "use real objects everywhere" suffer slow
    suites and complex fixtures. The correct answer is contextual and should be documented in
    the project's testing guidelines.

---

## Community Lessons — Iteration 13  [community]

43. **`jest.replaceProperty()` is the correct API for non-function property isolation — not `Object.defineProperty` or direct assignment.** [community]
    Jest 30 added `jest.replaceProperty(object, propertyKey, value)` as the idiomatic way to replace
    non-function properties on objects for a test. It captures the original value and automatically
    restores it when `jest.restoreAllMocks()` is called in `afterEach`. The common alternative —
    directly assigning `process.env.FEATURE_FLAG = 'true'` and forgetting to restore — is the
    root cause of numerous environment-variable isolation failures. The TypeScript utility type
    `jest.Replaced<Source>` preserves type-checking on the replaced value.
    ```typescript
    const utils = {
      isLocalhost: () => process.env.HOSTNAME === 'localhost',
    };

    afterEach(() => {
      // Restores both jest.spyOn() mocks AND jest.replaceProperty() replacements
      jest.restoreAllMocks();
    });

    it('isLocalhost returns true when HOSTNAME is localhost', () => {
      jest.replaceProperty(process, 'env', { HOSTNAME: 'localhost' });
      expect(utils.isLocalhost()).toBe(true);
    });

    it('isLocalhost returns false for other hostnames', () => {
      jest.replaceProperty(process, 'env', { HOSTNAME: 'prod-host' });
      expect(utils.isLocalhost()).toBe(false);
    });
    ```
    **When to use vs. alternatives:** Use `jest.replaceProperty()` for plain data properties on
    objects. Use `jest.spyOn(obj, 'prop', 'get')` for getter properties. Use `vi.stubEnv()` in
    Vitest (Gotcha 36). WHY: direct property assignment without capture/restore is the most
    common source of environment-variable order-dependent failures in CJS Jest projects.

44. **`jest.isolateModulesAsync()` is required when isolating ESM modules loaded via dynamic `import()`.** [community]
    `jest.isolateModules()` is synchronous and cannot await dynamic `import()` calls inside its
    callback. When test code needs to load a module under a specific environment condition (e.g.,
    a feature flag set in `process.env`) using native ESM `import()`, `jest.isolateModulesAsync()`
    creates an async sandbox registry. Without the async version, the `import()` resolves outside
    the isolated registry boundary, defeating the isolation.
    ```typescript
    it('featureEnabled is true when FEATURE_FLAG=true', async () => {
      process.env.FEATURE_FLAG = 'true';
      let featureEnabled: boolean;

      // isolateModulesAsync creates a fresh module registry for the async callback
      await jest.isolateModulesAsync(async () => {
        const mod = await import('./featureFlag');
        featureEnabled = mod.featureEnabled;
      });

      expect(featureEnabled!).toBe(true);
      delete process.env.FEATURE_FLAG;
    });
    ```
    WHY: teams that use `jest.isolateModules()` with ESM `import()` (the synchronous form) find
    that the `import()` completes after the isolation scope ends — the module loads from the global
    cache, not the isolated registry. The symptom is that `process.env` changes have no effect on
    the module, producing a silent false negative.

45. **`jest.unstable_mockModule()` + `jest.unstable_unmockModule()` is the ESM-native isolation pair; `jest.mock()` does not hoist in native ESM.** [community]
    In Jest projects running native ESM (`--experimental-vm-modules`, no Babel/ts-jest transform),
    `jest.mock()` hoisting is not performed by the JS engine itself. The ESM-native API is
    `jest.unstable_mockModule()` paired with a dynamic `import()` after mock registration. Its
    complement, `jest.unstable_unmockModule()`, restores the real module within the same test —
    enabling mock/unmock cycles without `resetModules()` for the entire registry.
    ```typescript
    import { jest, test, expect } from '@jest/globals';

    test('can switch between mock and real module in the same test', async () => {
      // Register mock before dynamic import
      jest.unstable_mockModule('./analytics', () => ({
        track: jest.fn(),
      }));
      const { track } = await import('./analytics');
      expect(typeof track).toBe('function'); // mock

      // Restore real module
      jest.unstable_unmockModule('./analytics');
      const realModule = await import('./analytics');
      // realModule.track is the real implementation
      expect(realModule.track).not.toBe(track);
    });
    ```
    **Caveats:** (1) Re-mocking after `unstable_unmockModule()` reverts to the first mock factory —
    it does not apply a new factory. (2) The "unstable_" prefix signals the API may change; avoid
    depending on it in test utilities that must survive major Jest upgrades.

46. **Vitest pool type determines the isolation boundary for module state; `forks` (the default) provides the strongest isolation.** [community]
    Vitest offers four pool types with different isolation guarantees:
    - **`forks`** (default since Vitest 2): runs each test file in a separate child process (`child_process.fork`). Strongest isolation — Node.js module cache, global state, and memory are fully separate per file. Slower startup than threads.
    - **`threads`**: runs each test file in a Node.js Worker thread. Faster than forks, but Workers share the V8 heap with the host process. Shared `SharedArrayBuffer` or global singletons can bleed across files.
    - **`vmThreads`**: runs each test file in a separate VM context within a Worker thread. Module isolation within the context, but not as strong as a separate process; rare internal V8 issues can cause hangs.
    - **`vmForks`**: runs each test file in a VM context within a forked child process. Combines the isolation of `forks` with the module-registry reset of `vmThreads`.

    The `isolate: false` config flag (or `--no-isolate` CLI) disables file-level isolation entirely
    for a significant performance gain — all test files share one process and one module cache.
    Only safe when all test files are fully self-contained and import no singletons with persistent state.
    ```
    # vitest.config.ts — pool selection by isolation need
    export default defineConfig({
      test: {
        pool: 'forks',     // strongest isolation (default); use for integration suites
        // pool: 'threads', // faster; use for pure-unit suites with no shared globals
        // pool: 'vmThreads', // VM isolation; use when module reset per file is needed but forks is too slow
        // isolate: false,  // DISABLE only if every test file is fully self-contained
      },
    });
    ```
    WHY: teams that switch from `forks` to `threads` for speed sometimes encounter non-deterministic
    failures caused by Worker-shared globals (e.g., `global.fetch = vi.fn()` set in one file's
    `beforeAll` but not cleaned up, leaking into the next file assigned to the same Worker thread).
    Diagnose with `--reporter=verbose` and `--no-isolate=false` to confirm per-file isolation
    eliminates the failure.

---

## Extended Patterns — Iteration 13

### Pattern 20: `jest.replaceProperty()` for typed property isolation (TypeScript, Jest 30+)  [community]

`jest.replaceProperty()` provides a type-safe, auto-restorable way to replace non-function object
properties for the duration of a test. Unlike direct assignment (`process.env.X = 'y'`) or
`Object.assign`, it records the original value and restores it via `jest.restoreAllMocks()`.
The `jest.Replaced<T>` utility type preserves the TypeScript shape of the replaced property.

```typescript
// config.ts
export const appConfig = {
  maxRetries: 3,
  timeout: 5000,
  environment: process.env.NODE_ENV ?? 'development',
};

// config.test.ts
import { appConfig } from './config';

describe('appConfig property isolation (jest.replaceProperty)', () => {
  afterEach(() => {
    // Restores all jest.spyOn() mocks AND jest.replaceProperty() replacements
    jest.restoreAllMocks();
  });

  it('maxRetries can be overridden for a single test without leaking', () => {
    // Arrange — replace a non-function property with auto-restore
    jest.replaceProperty(appConfig, 'maxRetries', 1);

    // Act — code under test reads the overridden value
    const result = appConfig.maxRetries;

    // Assert
    expect(result).toBe(1);
    // After afterEach, appConfig.maxRetries is 3 again — no manual restore needed
  });

  it('environment override does not affect adjacent tests', () => {
    jest.replaceProperty(process, 'env', {
      ...process.env,
      NODE_ENV: 'production',
    });

    // Re-evaluate the property that reads from process.env
    const env = process.env.NODE_ENV;

    expect(env).toBe('production');
    // Restored automatically in afterEach
  });

  it('maxRetries is back to the original value — no state leak', () => {
    // Previous test's replaceProperty has been restored by restoreAllMocks
    expect(appConfig.maxRetries).toBe(3);
  });
});
```

**When to prefer over alternatives:**
- Over `vi.stubEnv()`: when replacing arbitrary object properties (not just `process.env` keys)
- Over `jest.spyOn(obj, 'prop', 'get')`: when the property is a plain data property (not a getter)
- Over `Object.assign({}, ...)` save/restore: when you want `restoreAllMocks()` to handle cleanup automatically

### Pattern 21: `jest.isolateModulesAsync()` for ESM singleton isolation (TypeScript)  [community]

When a TypeScript module exports a value that is computed at import time (a configuration object,
a singleton built from `process.env`, or a flag read at load time), testing different configurations
requires loading a fresh copy of the module. For native ESM modules, `jest.isolateModulesAsync()`
provides a scoped async module registry where `import()` loads a fresh copy.

```typescript
// featureFlags.ts — value computed at module load time
export const featureFlags = {
  newCheckout: process.env.FEATURE_NEW_CHECKOUT === 'true',
  analyticsV2: process.env.FEATURE_ANALYTICS_V2 === 'true',
};

// featureFlags.test.ts
import { jest, describe, it, expect, afterEach } from '@jest/globals';

describe('featureFlags (ESM singleton — isolated per test)', () => {
  afterEach(() => {
    // Clean up env vars set during tests
    delete process.env.FEATURE_NEW_CHECKOUT;
    delete process.env.FEATURE_ANALYTICS_V2;
  });

  it('newCheckout is true when env var is set before module load', async () => {
    process.env.FEATURE_NEW_CHECKOUT = 'true';

    let flags: typeof import('./featureFlags');
    // isolateModulesAsync creates an isolated registry for the async callback
    await jest.isolateModulesAsync(async () => {
      flags = await import('./featureFlags');
    });

    expect(flags!.featureFlags.newCheckout).toBe(true);
  });

  it('newCheckout is false when env var is absent', async () => {
    // No env var set — fresh module load sees it as absent
    let flags: typeof import('./featureFlags');
    await jest.isolateModulesAsync(async () => {
      flags = await import('./featureFlags');
    });

    expect(flags!.featureFlags.newCheckout).toBe(false);
  });

  it('multiple flags can be independently controlled per test', async () => {
    process.env.FEATURE_ANALYTICS_V2 = 'true';

    let flags: typeof import('./featureFlags');
    await jest.isolateModulesAsync(async () => {
      flags = await import('./featureFlags');
    });

    expect(flags!.featureFlags.newCheckout).toBe(false);
    expect(flags!.featureFlags.analyticsV2).toBe(true);
  });
});
```

**Key rule:** `jest.isolateModules()` (synchronous) cannot host a `await import()` inside its
callback — the `import()` resolves after the isolation scope has closed. Always use the `Async`
variant for ESM `import()`.

---

## Key Resources — Iteration 13 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Jest Docs — `jest.replaceProperty` | Official | https://jestjs.io/docs/jest-object#jestreplacepropertyobject-propertykey-value | Auto-restorable non-function property replacement; `jest.Replaced<T>` type |
| Jest Docs — `jest.isolateModulesAsync` | Official | https://jestjs.io/docs/jest-object#jestisolatemodulesasyncfn | Async scoped module registry for ESM `import()` isolation |
| Jest Docs — ESM Module Mocking | Official | https://jestjs.io/docs/ecmascript-modules | `jest.unstable_mockModule` + `jest.unstable_unmockModule` — ESM-native mock/unmock pair |
| Vitest Docs — Pool Configuration | Official | https://vitest.dev/guide/improving-performance#pool | `forks` vs `threads` vs `vmThreads` isolation guarantees and performance tradeoffs |
| Vitest Config — `isolate` | Official | https://vitest.dev/config/#isolate | `isolate: false` / `--no-isolate` flag — when safe to disable file-level isolation for speed |

---

## Community Lessons — Iteration 14  [community]

47. **Vitest 4.0 changed `vi.restoreAllMocks()` — it no longer resets spy state, only restores.** [community]
    In Vitest ≤ 3, `vi.restoreAllMocks()` both restored the original implementation *and* reset call
    history (equivalent to calling `.mockRestore()` on each spy). In Vitest 4.0, `vi.restoreAllMocks()`
    only restores spies created manually via `vi.spyOn()` — it does not reset automock state, and it
    does not call `.mockReset()`. Teams migrating from Vitest 3 to 4 that relied on a single
    `afterEach(() => vi.restoreAllMocks())` to handle both restoration and call-count reset will find
    their call-count assertions now bleed across tests. The fix: pair `restoreMocks: true` in
    `vitest.config.ts` (for automatic restoration) with `clearMocks: true` (for call-count and
    return-value reset). WHY: the separation of concerns lets you restore originals without losing
    spy call history — but the default expectation of most teams is full reset, so `clearMocks: true`
    must be added explicitly after a Vitest 3 → 4 upgrade.

48. **Vitest 4.0 hook execution is stack-based by default — hooks that return functions have teardown semantics.** [community]
    In Jest, hooks execute sequentially. In Vitest 4.0, the default `sequence.hooks` mode is
    `'stack'` — `afterEach` hooks for inner `describe` blocks run before outer ones, mirroring a call
    stack unwind. A new behavior: if a `beforeEach` returns a function, Vitest 4.0 automatically
    calls that returned function as teardown after the test completes. Teams that return non-void
    values from `beforeEach` (e.g., a connection object for reuse) must rewrite those hooks, as
    Vitest 4.0 will *call* the returned value as a teardown function. Restore Jest-compatible
    sequential mode with `sequence: { hooks: 'list' }` in `vitest.config.ts`. WHY: the stack model
    enables cleaner teardown pairing without a separate `afterEach`, but it is a silent behavioral
    change for existing test suites that return non-function values from `beforeEach` hooks.

49. **Vitest 4.0 `singleThread`/`singleFork` removed — `maxWorkers: 1, isolate: false` requires explicit `vi.resetModules()`.** [community]
    Vitest 3 accepted `singleThread: true` / `singleFork: true` with per-file module isolation still
    active. Vitest 4.0 removes these in favor of `maxWorkers: 1, isolate: false`. The critical
    difference: `isolate: false` means the Node.js module registry is NOT reset between test files —
    singletons from file A remain visible in file B. Add a setupFile that restores per-file resets:
    ```typescript
    // vitest.setup.ts — add to `setupFiles` in vitest.config.ts
    import { vi, beforeAll } from 'vitest';
    beforeAll(() => { vi.resetModules(); });
    ```
    WHY: migrating from `singleFork: true` to `maxWorkers: 1, isolate: false` without the setupFile
    causes hard-to-diagnose order-dependent failures that only surface when all test files run
    together in the same process.

50. **Vitest 4.0 `vi.spyOn` on constructors fails with arrow function implementations.** [community]
    Vitest 4.0 properly validates constructor targets and throws `"not a constructor"` when an
    arrow function is provided as the mock implementation. Use `function` or `class` keywords:
    ```typescript
    // BROKEN in Vitest 4.0 — arrow function cannot be a constructor
    vi.spyOn(SomeClass, 'create').mockImplementation(() => ({ id: 1 })); // TypeError

    // CORRECT — function keyword supports new
    vi.spyOn(SomeClass, 'create').mockImplementation(function() { return { id: 1 }; });
    // OR
    vi.spyOn(SomeClass, 'create').mockImplementation(class { id = 1; });
    ```
    WHY: the previous permissive behavior masked real bugs — code calling `new` on a mocked
    constructor would silently invoke the arrow function rather than throwing, creating false passes
    for test cases that should have caught the `new` invocation.

51. **Vitest 4.0 `vi.fn().getMockName()` returns `"vi.fn()"` not `"spy"` — update inline snapshots after migration.** [community]
    In Vitest ≤ 3, `vi.fn()` mocks returned `"spy"` from `getMockName()`. Vitest 4.0 changes the
    default to `"vi.fn()"`. Test suites using `toMatchSnapshot()` or inline snapshots on error
    messages that include the mock name will see snapshot mismatches after the upgrade. Run
    `vitest --update-snapshots` once post-migration. WHY: `"vi.fn()"` is unambiguous in stack
    traces; `"spy"` was ambiguous for tooling that needed to distinguish mock type from `vi.spyOn`.

52. **Vitest 4.0 `test.extend()` type-aware hooks eliminate the shared-`let` anti-pattern.** [community]
    Vitest 4.0 allows `test.beforeEach` and `test.afterEach` defined on an extended test instance
    to receive full type inference of the fixture context. This eliminates both the module-level
    `let db` mutable variable anti-pattern and the need for a separate `afterEach` to clean up
    fixtures. The fixture's `use()` callback guarantees teardown even if the test throws — a
    stronger isolation contract than `afterEach` alone (which is skipped if `beforeEach` throws,
    see Gotcha 2). See Pattern 22 below. WHY: teams migrating from Playwright to Vitest unit tests
    should adopt this pattern immediately rather than recreating the `beforeEach`/`afterEach` pair.

53. **Jest 30 `CalledWith` matchers now enforce TypeScript argument types — false-positive tests surface.** [community]
    In Jest ≤ 29, `expect(fn).toHaveBeenCalledWith('string')` on a `jest.fn((n: number) => {})`
    produced no TypeScript error. In Jest 30, the `CalledWith` matchers apply stricter type
    inference — passing a wrong-type value is now a compile error:
    ```typescript
    const fn = jest.fn((num: number) => num * 2);
    expect(fn).toHaveBeenCalledWith('not-a-number'); // TypeScript error in Jest 30
    expect(fn).toHaveBeenCalledWith(42);               // correct
    expect(fn).toHaveBeenCalledWith(expect.any(Number)); // partial match OK
    ```
    WHY: this catches false-positive test cases where mock assertions compiled despite wrong
    argument types at production call sites. The fix usually reveals a real bug in either the
    test or the production code.

---

## Extended Patterns — Iteration 14

### Pattern 22: Vitest 4.0 `test.extend()` fixture with type-aware lifecycle hooks (TypeScript)  [community]

The Vitest 4.0 fixture model combines setup, teardown, and type safety into a single declaration.
The fixture's `use()` callback makes isolation explicit: code before `use()` is setup; code after
is guaranteed teardown that runs even if the test body throws — a stronger guarantee than `afterEach`.

```typescript
import { test as baseTest, expect, vi } from 'vitest';
import type { MockInstance } from 'vitest';

interface TimerFixture {
  advanceMs: (ms: number) => void;
}
interface SpyFixture {
  consoleSpy: MockInstance;
}

const test = baseTest.extend<TimerFixture & SpyFixture>({
  // Timer fixture: fake timers set up before use(), restored after regardless of test outcome
  advanceMs: async ({}, use) => {
    vi.useFakeTimers();
    await use((ms: number) => vi.advanceTimersByTime(ms));
    vi.useRealTimers(); // runs even if the test throws
  },

  // Spy fixture: per-test fresh spy, auto-restored after use()
  consoleSpy: async ({}, use) => {
    const spy = vi.spyOn(console, 'warn').mockImplementation(() => {});
    await use(spy);
    spy.mockRestore();
  },
});

test('retryAfter warns and retries after 2 seconds', async ({ advanceMs, consoleSpy }) => {
  // Arrange — both fixtures initialized above; no shared let variables
  const { retryAfter } = await import('./retryAfter');

  // Act
  const promise = retryAfter(() => Promise.reject(new Error('temporary')), 2000);
  advanceMs(2000);
  await promise;

  // Assert
  expect(consoleSpy).toHaveBeenCalledWith(
    expect.stringContaining('Retrying after 2000ms'),
  );
});

test('retryAfter does not warn when succeeds immediately', async ({ consoleSpy }) => {
  const { retryAfter } = await import('./retryAfter');

  const result = await retryAfter(() => Promise.resolve('ok'), 2000);

  expect(result).toBe('ok');
  // consoleSpy is a fresh MockInstance — no accumulated calls from the previous test case
  expect(consoleSpy).not.toHaveBeenCalled();
});
```

**Key advantage over `beforeEach`/`afterEach` pair:** If setup throws inside `beforeEach`, Jest and
Vitest both skip `afterEach` — the resource leaks. A fixture's post-`use()` teardown is guaranteed
by the framework regardless of whether setup completes cleanly, because the `use()` continuation
is modeled as an async generator boundary.

### Pattern 23: Vitest 4.0 per-project isolation configuration (TypeScript)  [community]

Vitest 4.0's `projects` field (replacing `workspace`) enables different isolation levels per test
suite. Unit tests can use `isolate: false` for speed; integration tests use `forks` for correctness.

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    projects: [
      {
        test: {
          name: 'unit',
          include: ['src/**/*.unit.test.ts'],
          pool: 'threads',
          isolate: false,           // Shared module registry — ~2x faster for pure unit suites
          setupFiles: ['./vitest.unit.setup.ts'], // REQUIRED: explicit per-file module reset
        },
      },
      {
        test: {
          name: 'integration',
          include: ['src/**/*.integration.test.ts'],
          pool: 'forks',            // Separate child process per file — strongest isolation
          isolate: true,            // Module registry reset per file (default; explicit here)
          fileParallelism: false,   // Sequential execution — prevents DB port conflicts
        },
      },
    ],
  },
});
```

```typescript
// vitest.unit.setup.ts — required companion when isolate: false is set
import { vi, beforeAll } from 'vitest';

beforeAll(() => {
  // Explicit per-file module reset when file-level isolation is disabled for speed
  vi.resetModules();
});
```

**Safety rule:** Never apply `isolate: false` to a project whose tests set module-level global state
(`global.fetch = vi.fn()`) without a corresponding `unstubGlobals: true` or manual cleanup —
this state poisons every subsequent test file assigned to the same Worker thread.

---

## Key Resources — Iteration 14 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest 4.0 Migration Guide | Official | https://vitest.dev/guide/migration.html#vitest-4-0 | Pool overhaul, hook execution model, vi.restoreAllMocks change, per-project isolation |
| Vitest 4.0 Blog — What's New | Official | https://vitest.dev/blog/vitest-4.html | type-aware `test.extend()` hooks, `toMatchScreenshot`, Browser Mode stable |
| Vitest Config — `sequence.hooks` | Official | https://vitest.dev/config/#sequence-hooks | `'stack'` (default Vitest 4) vs `'list'` (Jest-compatible sequential) hook execution order |
| Vitest Config — `projects` | Official | https://vitest.dev/config/#projects | Per-project isolation configuration; replaces `workspace` field in Vitest 4.0 |
| Vitest API — `test.extend` | Official | https://vitest.dev/api/#test-extend | Type-aware fixture definitions with guaranteed `use()`-based teardown |
| Jest 30 Upgrade Guide (stricter types) | Official | https://jestjs.io/docs/upgrading-to-jest30 | Stricter `CalledWith` TypeScript types, `genMockFromModule` removal, `SpyInstance` removal |

---

## Community Lessons — Iteration 15  [community]

54. **Vitest 4.1 `aroundEach` is the right tool for database transaction rollback in fixtures — not `beforeEach`/`afterEach` pairs.** [community]
    Vitest 4.1 introduces `test.aroundEach` and `test.aroundAll` hooks that wrap each test in a
    context. The `runTest` function receives control at the exact moment the test body executes —
    making it ideal for database transaction wrapping. Unlike the `beforeEach`/`afterEach` pair,
    `aroundEach` guarantees rollback even if `beforeEach` throws after the transaction starts,
    because the transaction boundary and the test execution are coupled in a single closure.
    ```typescript
    import { test, expect } from 'vitest';
    import { db } from './db';

    const isolatedTest = test.extend({});

    isolatedTest.aroundEach(async (runTest) => {
      await db.transaction(async (tx) => {
        // runTest runs inside the transaction; rollback happens when the
        // wrapping transaction resolves (or the test throws)
        await runTest({ tx });
        // throw here to rollback — Vitest calls this regardless of test outcome
        throw new Error('rollback'); // intentional rollback
      }).catch(() => {}); // swallow expected rollback error
    });

    isolatedTest('creates a user inside a rolled-back transaction', async ({ tx }) => {
      await tx.user.create({ data: { name: 'Alice', email: 'alice@example.com' } });

      const found = await tx.user.findFirst({ where: { name: 'Alice' } });
      expect(found?.name).toBe('Alice');
      // After this test ends, aroundEach triggers rollback — DB is clean for the next test
    });
    ```
    WHY: the `beforeEach`/`afterEach` pair has a gap: if `beforeEach` throws after opening a
    transaction but before completing setup, `afterEach` still runs — but the `afterEach` rollback
    code may reference state that was never initialized (e.g., a `queryRunner` that is `undefined`).
    `aroundEach` collapses setup and teardown into a single async function, eliminating the gap.

55. **Vitest 4.1 `detectAsyncLeaks` flag surfaces resource leaks that cause intermittent CI failures.** [community]
    Vitest 4.1 adds a `--detect-async-leaks` CLI flag that uses Node.js `async_hooks` to track
    timers, TCP handles, file descriptors, and unresolved promise chains that are still alive after
    a test suite completes. Unlike Jest's `--detectOpenHandles` (which only lists Node.js async
    handles at process exit), `detectAsyncLeaks` reports per-test leak attribution — you see exactly
    which test case created the un-closed handle.
    ```bash
    # Run with async leak detection — reports leaking tests by name
    vitest --detect-async-leaks

    # Alternatively, enable per test project:
    # vitest.config.ts → test: { detectAsyncLeaks: true }
    ```
    WHY: resource leaks are the second most common cause of flaky CI failures (after shared mutable
    state). They are non-deterministic: a test suite may pass 9 out of 10 runs until GC lag causes
    a handle from test N to still be alive when test N+20 runs, producing an `EADDRINUSE` or
    `ETIMEDOUT` error that looks like an environment problem. `detectAsyncLeaks` converts this
    non-deterministic failure into a deterministic, attributable error on the offending test.

56. **Vitest 4.1's `onCleanup` builder pattern replaces `use()` boilerplate for simple value fixtures.** [community]
    The Vitest 4.0 fixture pattern required calling `use()` to yield a value and placing teardown
    code after the `await use(...)` call. Vitest 4.1 introduces an alternative "builder pattern"
    where the fixture function *returns* a value directly, and registers cleanup with an `onCleanup`
    callback — TypeScript infers the fixture type from the return value automatically.
    ```typescript
    import { test as baseTest, expect } from 'vitest';
    import * as fs from 'fs/promises';
    import * as os from 'os';
    import * as path from 'path';

    const test = baseTest.extend({
      // Builder pattern: return the fixture value; use onCleanup for teardown
      tmpDir: async ({}, { onCleanup }) => {
        const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'vitest-'));
        // Cleanup registered declaratively — runs after test even if test throws
        onCleanup(() => fs.rm(dir, { recursive: true, force: true }));
        // TypeScript infers the fixture type as `string` from the return value
        return dir;
      },
    });

    test('writes a temp file and reads it back', async ({ tmpDir }) => {
      const filePath = path.join(tmpDir, 'data.json');
      await fs.writeFile(filePath, JSON.stringify({ ok: true }));

      const content = JSON.parse(await fs.readFile(filePath, 'utf-8'));

      expect(content.ok).toBe(true);
      // tmpDir is automatically removed after this test — no afterEach needed
    });

    test('each test gets a fresh tmpDir — no cross-test contamination', async ({ tmpDir }) => {
      // Different tmpDir per test; previous test's directory is already deleted
      const entries = await fs.readdir(tmpDir);
      expect(entries).toHaveLength(0); // fresh empty directory
    });
    ```
    WHY: the `use()` pattern can be confusing — code after `await use(value)` looks like normal
    sequential code but executes in teardown. The `onCleanup` builder pattern makes the lifecycle
    explicit: "here is the value; here is what cleans up after it." Teams onboarding to Vitest
    fixtures report faster comprehension of the builder pattern vs. the `use()` continuation.

57. **Vitest 4.1 `viteModuleRunner: false` enables native Node.js execution — but breaks Vite-specific test helpers.** [community]
    By default, Vitest runs test code inside Vite's module runner (a sandbox that applies Vite
    plugins, aliases, and transforms). Vitest 4.1 adds an experimental `viteModuleRunner: false`
    option that disables the Vite sandbox and runs tests with native Node.js `import`. This gives
    stronger isolation from Vite's transform pipeline and catches production-vs-test mismatches
    (e.g., a missing export that Vite's permissive resolver silently allowed in the sandbox).
    **Requires Node.js 22.18+ or 23.6+ for native TypeScript type stripping.**
    ```typescript
    // vitest.config.ts — experimental native execution
    import { defineConfig } from 'vitest/config';

    export default defineConfig({
      test: {
        experimental: {
          viteModuleRunner: false, // native Node.js import — no Vite sandbox
        },
      },
    });
    ```
    **What is NOT available in this mode:**
    - `import.meta.env` (Vite-injected environment variables)
    - Vite plugins and custom transformers
    - Path aliases defined in `vite.config.ts`
    - Istanbul coverage provider (use V8 coverage instead)

    WHY: teams that use Vite aliases heavily in production code (e.g., `@/` path alias) cannot
    use this mode without replacing aliases with `tsconfig` path mapping. The mode is most valuable
    for pure Node.js backend tests where Vite's sandbox adds no value and where catching
    non-existent-export errors is more important than alias support.

58. **`jest.onGenerateMock()` is a centralized mock factory hook — not a per-test reset mechanism.** [community]
    Jest 30 added `jest.onGenerateMock(callback)` to allow customization of auto-generated mocks
    before they are returned to the test environment. The callback is registered globally in the
    test file and applies to all subsequent `jest.mock()` calls without an explicit factory. A
    common misuse: teams call `jest.onGenerateMock()` inside `beforeEach` expecting it to reset
    the mock for each test — but it registers a *new* callback on every call without removing
    previous ones. Callbacks accumulate and execute in registration order on each mock generation.
    ```typescript
    // CORRECT — register once at file scope; applies to all jest.mock() calls in the file
    jest.onGenerateMock((modulePath, moduleMock) => {
      if (modulePath.includes('/analytics/')) {
        // Enforce all analytics events go through a mock — can't be forgotten per-test
        (moduleMock as { track: jest.Mock }).track = jest.fn();
      }
      return moduleMock;
    });

    jest.mock('./analytics/tracker'); // onGenerateMock callback runs here

    // DO NOT call jest.onGenerateMock() inside beforeEach — callbacks accumulate
    ```
    WHY: `jest.onGenerateMock()` is intended for project-wide mock shape enforcement (e.g., a
    `jest.setup.ts` file that ensures all database module mocks include a `.disconnect()` mock).
    It is not a replacement for `beforeEach` mock reset — for per-test stub setup, always
    recreate mocks in `beforeEach`.

59. **`jest.retryTimes` with `retryImmediately: true` breaks test ordering guarantees — use cautiously.** [community]
    Jest 30 adds `retryImmediately: true` to `jest.retryTimes()`. Without this option, failed
    tests are retried *after all other tests in the file finish*. With `retryImmediately: true`,
    the failed test retries immediately before the next test runs — which can cause retry
    side effects to contaminate the subsequent test if shared state was not properly cleaned up
    by the failing test's `afterEach`.
    ```typescript
    // Use case: retry a flaky network test without delaying other tests
    jest.retryTimes(2, {
      retryImmediately: true,    // retry before next test — reduces total suite time
      waitBeforeRetry: 500,      // 500ms delay between retries for transient network issues
      logErrorsBeforeRetry: true // log failure reason before each retry for debugging
    });
    ```
    **When to use:** network-dependent tests with transient failures (rate limits, cold starts).
    **When NOT to use:** tests with shared state — a retry after partial mutation may leave
    the state in an inconsistent condition that causes the retry itself to fail for a different
    reason than the original failure. Always ensure `afterEach` is idempotent before enabling
    retry. WHY: `retryImmediately` is the right tool for flaky *infrastructure* tests, not for
    flaky *isolation* failures. If a test is flaky because of shared state (the most common cause),
    retrying immediately will mask the root cause and introduce new false negatives.

60. **Vitest 4.1 breaking change: `aroundAll` hook now receives fixture context — not the `Suite` object.** [community]
    In Vitest ≤ 4.0, the undocumented first argument to `beforeAll`/`afterAll` hooks was a
    `Suite` object from Vitest internals. Vitest 4.1 formalizes `aroundAll` as a lifecycle hook
    that receives the *fixture context* — the same typed context object available in tests and
    `aroundEach`. Code that accidentally relied on the `Suite` shape in `beforeAll`/`afterAll` will
    break after upgrading:
    ```typescript
    // BROKEN after Vitest 4.1 upgrade — Suite object no longer passed
    beforeAll((suite: any) => {
      console.log(suite.name); // was the suite name; now receives fixture context
    });

    // CORRECT — use vitest's task API for suite metadata
    import { getCurrentSuite } from 'vitest';
    beforeAll(() => {
      console.log(getCurrentSuite().name); // explicit API for suite metadata
    });
    ```
    WHY: the implicit `Suite` argument was never documented and was an implementation leak.
    The migration is low-risk because code relying on the `Suite` object is uncommon, but
    teams using `beforeAll` hooks in test helpers that inspect suite structure must audit
    their helpers after upgrading to Vitest 4.1.

---

## Extended Patterns — Iteration 15

### Pattern 24: Vitest 4.1 `aroundEach` for guaranteed database transaction rollback (TypeScript)  [community]

Vitest 4.1's `aroundEach` hook wraps each test in a surrounding async context. The `runTest`
callback is called at the exact point the test body executes, enabling teardown-as-closing-brace
semantics. For database integration tests, this is the cleanest way to guarantee rollback even
when the test body throws.

```typescript
import { test as baseTest, expect } from 'vitest';
import { PrismaClient } from '@prisma/client';

// Create an isolated Prisma client for the test suite
const prisma = new PrismaClient();

interface DbFixture {
  // The test receives a transaction-bound client — not the global prisma instance
  db: Omit<PrismaClient, '$connect' | '$disconnect' | '$on' | '$transaction' | '$use' | '$extends'>;
}

// Build an extended test with a DB fixture using aroundEach for rollback
const test = baseTest.extend<DbFixture>({
  db: async ({}, use) => {
    // This fixture is provided via use() so it can participate in aroundEach lifecycle
    // The actual transaction wrapping is in aroundEach below
    await use(prisma as unknown as DbFixture['db']);
  },
});

// aroundEach wraps every test — receives the same fixture context as the test
test.aroundEach(async (runTest) => {
  // Open a transaction before the test runs
  let rollback!: () => void;
  const rollbackPromise = new Promise<void>((resolve) => { rollback = resolve; });

  const txPromise = prisma.$transaction(async (tx) => {
    // Run the test with the transaction-bound client
    // (In a full implementation, inject tx into the fixture context)
    await runTest();
    // Wait for rollback signal from afterTest; this keeps the transaction open
    await rollbackPromise;
  }).catch(() => {}); // swallow rollback-by-rejection

  // Signal rollback after the test completes (runTest has returned)
  rollback();
  await txPromise;
});

test('creates a user that is visible within the transaction', async () => {
  // Database operations here run inside the transaction; rolled back after test
  const created = await prisma.user.create({
    data: { name: 'Alice', email: `alice-${Date.now()}@example.com` },
  });

  const found = await prisma.user.findUnique({ where: { id: created.id } });
  expect(found?.name).toBe('Alice');
  // After test: aroundEach triggers rollback → Alice never committed to the real DB
});

test('database is clean — Alice from previous test was rolled back', async () => {
  const allUsers = await prisma.user.findMany({ where: { name: 'Alice' } });
  // Relies on aroundEach rollback — would accumulate if using beforeEach/afterEach pair
  expect(allUsers).toHaveLength(0);
});
```

**Key advantage over `beforeEach`/`afterEach`:** The transaction open and the test execution are
in the same async scope — there is no gap where the transaction could be open but teardown code
is not reachable. The `aroundEach` pattern is also more readable: the setup/run/teardown lifecycle
is visible as a single code block rather than spread across three separate hook calls.

### Pattern 25: Vitest 4.1 `onCleanup` builder pattern for file-system isolation (TypeScript)  [community]

The `onCleanup` fixture builder pattern (Vitest 4.1) is the idiomatic replacement for the
`await use(value)` + post-`use()` teardown pattern when the fixture is a simple value with a
cleanup callback. TypeScript infers the fixture type from the return value, eliminating the need
for explicit type parameters.

```typescript
import { test as baseTest, expect } from 'vitest';
import * as fs from 'fs/promises';
import * as os from 'os';
import * as path from 'path';

// --- Fixture definition ---

const test = baseTest.extend({
  // onCleanup builder: return the value; cleanup registered separately
  tmpDir: async ({}, { onCleanup }) => {
    const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'vitest-iso-'));
    // onCleanup runs after test completes — even if test throws
    // This is equivalent to placing code after `await use(dir)` but more readable
    onCleanup(async () => {
      await fs.rm(dir, { recursive: true, force: true });
    });
    // TypeScript infers the fixture type as `string` from this return value
    return dir;
  },

  // Composable: tempFile depends on tmpDir — Vitest resolves the dependency graph
  tempFile: async ({ tmpDir }: { tmpDir: string }, { onCleanup }) => {
    const filePath = path.join(tmpDir, `file-${Date.now()}.txt`);
    await fs.writeFile(filePath, '');
    // File cleanup is handled by tmpDir's onCleanup (rm -rf); this is illustrative
    onCleanup(() => fs.unlink(filePath).catch(() => {}));
    return filePath;
  },
});

// --- Tests ---

test('writes data to temp file', async ({ tempFile }) => {
  // Arrange: tempFile is a fresh, empty file in a fresh tmpDir
  await fs.writeFile(tempFile, JSON.stringify({ event: 'login', userId: 'u1' }));

  // Act
  const raw = await fs.readFile(tempFile, 'utf-8');
  const parsed = JSON.parse(raw);

  // Assert
  expect(parsed.event).toBe('login');
  // tempFile and tmpDir cleaned up automatically after this test
});

test('each test gets a separate tmpDir — no cross-test file contamination', async ({ tmpDir }) => {
  const entries = await fs.readdir(tmpDir);
  // Previous test's file is not here — it was in a different tmpDir that was already deleted
  expect(entries).toHaveLength(0);
});
```

**Comparison with `use()` pattern (Vitest ≤ 4.0):**
```typescript
// Vitest 4.0 style — use() continuation
tmpDir: async ({}, use) => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'vitest-'));
  await use(dir);  // <- code after this line is teardown; not obvious to newcomers
  await fs.rm(dir, { recursive: true, force: true }); // teardown
},

// Vitest 4.1 style — onCleanup builder (clearer intent)
tmpDir: async ({}, { onCleanup }) => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'vitest-'));
  onCleanup(() => fs.rm(dir, { recursive: true, force: true }));
  return dir; // <- clearly the fixture value
},
```

---

## Quick Reference Additions — Iteration 15

| Problem | Symptom | Vitest 4.1 Solution | Jest equivalent |
|---------|---------|---------------------|-----------------|
| DB transaction isolation in fixtures | Rollback not guaranteed if test throws | `test.aroundEach(async (runTest) => { ... await runTest(); ... })` | No equivalent; use `beforeEach`/`afterEach` + try/finally |
| Async resource leak (timers, handles) | Flaky CI; non-deterministic timeouts | `--detect-async-leaks` flag or `detectAsyncLeaks: true` in config | `--detectOpenHandles` (process-level only) |
| Fixture teardown intent unclear | Confusion about code after `await use()` | `onCleanup(() => ...)` builder pattern + `return value` | N/A (Jest fixtures follow `beforeEach` model) |
| Vite sandbox hides missing exports | Test passes but production build fails | `experimental: { viteModuleRunner: false }` (Node 22.18+) | N/A |
| `aroundAll` `Suite` arg dependency | Runtime error after Vitest 4.1 upgrade | Replace `suite.name` with `getCurrentSuite().name` | N/A |

---

## Key Resources — Iteration 15 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest 4.1 Blog — What's New | Official | https://vitest.dev/blog/vitest-4-1.html | `aroundEach`/`aroundAll`, `detectAsyncLeaks`, `onCleanup` builder, `mockThrow`, `vi.defineHelper` |
| Vitest API — `aroundEach` / `aroundAll` | Official | https://vitest.dev/api/#test-aroundeach | Wraps each test/suite in a closure; guarantees teardown even if test throws |
| Vitest Config — `detectAsyncLeaks` | Official | https://vitest.dev/config/#detectasyncleaks | Per-test async resource leak attribution using Node.js `async_hooks` |
| Vitest API — `onCleanup` (fixture builder) | Official | https://vitest.dev/api/#oncleanup | Declarative fixture cleanup without `use()` continuation semantics |
| Jest 30 — `jest.onGenerateMock` | Official | https://jestjs.io/docs/jest-object#jestonGeneratemock | Global mock shape enforcement hook — file-scoped, applies to all `jest.mock()` calls |
| Jest 30 — `jest.retryTimes` options | Official | https://jestjs.io/docs/jest-object#jestretrytimesnumretries-options | `waitBeforeRetry`, `retryImmediately`, `logErrorsBeforeRetry` — flakiness mitigation options |

---

## Community Lessons — Iteration 16  [community]

61. **`vi.mockThrow()` / `mockThrowOnce()` (Vitest 4.1) replaces verbose `mockImplementation(() => { throw ... })` for error-path isolation.** [community]
    Vitest 4.1 adds `mockThrow(value)` and `mockThrowOnce(value)` as first-class mock methods, replacing the common boilerplate `mockImplementation(() => { throw new Error('...') })`. The key isolation benefit: `mockThrowOnce()` can be chained with `mockReturnValue()` to test that a service recovers correctly after a transient failure — without needing a stateful counter inside `mockImplementation`. WHY: the `mockImplementation(() => { throw ... })` pattern requires a closure that must be re-set in `beforeEach`; `mockThrowOnce()` makes error injection declarative and composable within the test body, reducing beforeEach coupling.
    ```typescript
    import { describe, it, expect, vi, beforeEach } from 'vitest';
    import { PaymentGateway } from './paymentGateway';
    import { OrderService } from './orderService';

    describe('OrderService — error recovery isolation (vi.mockThrow)', () => {
      let gateway: ReturnType<typeof vi.fn>;
      let service: OrderService;

      beforeEach(() => {
        // Fresh mock per test — no shared error state
        gateway = vi.fn<() => Promise<{ transactionId: string }>>();
        service = new OrderService(gateway as unknown as PaymentGateway);
      });

      it('retries once and succeeds when gateway throws transiently', async () => {
        // First call throws; second call returns success
        gateway
          .mockThrowOnce(new Error('GATEWAY_TIMEOUT'))
          .mockResolvedValue({ transactionId: 'tx-42' });

        const result = await service.placeOrder('sku-1', 1);

        expect(result.transactionId).toBe('tx-42');
        expect(gateway).toHaveBeenCalledTimes(2); // called once, threw, retried
      });

      it('throws when gateway fails on every attempt', async () => {
        // mockThrow (not Once) — throws on every subsequent call
        gateway.mockThrow(new Error('GATEWAY_DOWN'));

        await expect(service.placeOrder('sku-1', 1)).rejects.toThrow('GATEWAY_DOWN');
      });

      it('handles mixed throw/success sequence correctly', async () => {
        gateway
          .mockThrowOnce(new Error('first-fail'))
          .mockThrowOnce(new Error('second-fail'))
          .mockResolvedValue({ transactionId: 'tx-ok' }); // 3rd call succeeds

        const result = await service.placeOrder('sku-1', 1);

        expect(result.transactionId).toBe('tx-ok');
        expect(gateway).toHaveBeenCalledTimes(3);
      });
    });
    ```

62. **`mock.withImplementation()` provides scoped mock override without polluting `beforeEach` setup.** [community]
    Vitest's `mock.withImplementation(impl, callback)` temporarily overrides a mock's implementation for the duration of a synchronous or asynchronous callback, then automatically restores the previous implementation. This is the right tool when a single test needs a different stub behavior than the rest of the suite — without requiring a `beforeEach` restructure or a manual save/restore around the assertion. WHY: teams that override mock behavior inside a single test with `mockReturnValueOnce()` can accidentally leave residual mock state if the test asserts before consuming the override. `withImplementation` scopes the override to a function boundary, making it impossible to leak.
    ```typescript
    import { describe, it, expect, vi, beforeEach } from 'vitest';
    import { NotificationService } from './notificationService';
    import { AlertService } from './alertService';

    describe('AlertService — scoped mock override', () => {
      let notifications: ReturnType<typeof vi.fn>;
      let alerts: AlertService;

      beforeEach(() => {
        notifications = vi.fn<(msg: string) => void>();
        alerts = new AlertService(notifications as unknown as NotificationService);
      });

      it('sends the default notification text', () => {
        // Most tests use the default no-op mock from beforeEach
        alerts.sendAlert('system-down');
        expect(notifications).toHaveBeenCalledWith(expect.stringContaining('ALERT: system-down'));
      });

      it('uses a scoped implementation to simulate slow notification channel', async () => {
        let notifTime = 0;

        // withImplementation replaces the mock only for the duration of the callback
        await notifications.withImplementation(
          async (msg: string) => {
            notifTime = Date.now();
            return Promise.resolve();
          },
          async () => {
            await alerts.sendAlertAsync('system-slow');
          },
        );

        // Outside the callback, the original no-op implementation is restored
        expect(notifTime).toBeGreaterThan(0);
        // If we call the mock again here, it uses the original beforeEach stub
        alerts.sendAlert('check');
        expect(notifications).toHaveBeenLastCalledWith(expect.stringContaining('ALERT: check'));
      });
    });
    ```

63. **Jest `workerIdleMemoryLimit` prevents test-suite-level memory contamination from worker heap accumulation.** [community]
    Jest workers are long-lived Node.js processes that accumulate garbage from all test files they execute. In large suites with heavy mocking (e.g., jest.mock on large dependency trees) or snapshot serialization, worker heap usage grows monotonically within a session. When a worker exceeds `workerIdleMemoryLimit`, Jest recycles it — guaranteeing a fresh process for the next file assignment. This is a form of isolation: it prevents heap state from an earlier test file from influencing a later file that runs on the same worker. WHY: memory-related non-determinism is difficult to diagnose — it manifests as random failures or slowdowns that disappear when `--runInBand` is used (which uses a single process with GC between files). `workerIdleMemoryLimit` applies the same GC boundary in parallel mode.
    ```typescript
    // jest.config.ts
    import type { Config } from 'jest';

    const config: Config = {
      // Recycle workers when they exceed 512 MB heap usage.
      // Prevents heap accumulation from large mock registries or snapshot
      // serialization caches contaminating subsequent test files in the same worker.
      workerIdleMemoryLimit: '512MB',

      // Use with maxWorkers to bound total memory across all workers
      maxWorkers: '25%',

      preset: 'ts-jest',
      testEnvironment: 'node',
      clearMocks: true,
      restoreMocks: true,
    };

    export default config;
    ```
    **When to use:** Suites with > 200 test files, heavy use of `jest.mock()` on large modules, or any suite where you observe increasing test runtimes across the session. `workerIdleMemoryLimit: '512MB'` is a practical starting point; monitor with `--verbose` and reduce if workers are recycled too often (recycling has ~1-2s overhead per file).

64. **Jest `resetModules: true` config flag resets the entire module registry before *every* test — not just before every file.** [community]
    `jest.resetModules()` in `beforeEach` (Pattern 6) resets the registry before each test within a single file. The global config flag `resetModules: true` extends this behavior to the entire suite without requiring per-file `beforeEach` boilerplate. The critical distinction: the config flag resets modules before *every* test, not just between files. This is the strongest isolation level for module singletons — and also the most expensive. WHY: teams that need singleton re-initialization for every test (e.g., testing configuration modules that read `process.env` at import time) currently scatter `jest.resetModules()` calls across files. Centralizing this in config eliminates the per-file boilerplate, but teams must be aware of the performance cost: module re-evaluation on every test adds significant overhead in large suites. Benchmark with `--verbose` before committing to this config flag globally; consider scoping it to a specific project via a `projects` config entry instead.
    ```typescript
    // jest.config.ts — global module reset before every test (use with caution in large suites)
    import type { Config } from 'jest';

    const config: Config = {
      // Equivalent to calling jest.resetModules() before every single test.
      // Strong isolation for singletons computed at import time;
      // significant performance cost for suites with > 100 test files.
      resetModules: true,

      preset: 'ts-jest',
      testEnvironment: 'node',
    };

    export default config;
    // For selective use, prefer jest.resetModules() in beforeEach only where needed (Pattern 6),
    // or scope to a specific project entry in a Jest projects config.
    ```

65. **`jest.showSeed` + `jest.randomize` enables *reproducible* random order for diagnosing order-dependent failures.** [community]
    Gotcha 10 recommends `--randomize` to surface order-dependent failures. The missing piece: without `showSeed: true`, you cannot reproduce the exact execution order that triggered the failure. When `showSeed: true` is set in `jest.config.ts`, Jest prints the seed used for randomization in the test report. Re-running with `--seed=<printed-value>` replays the exact same order — allowing you to reproduce and bisect order-dependent failures deterministically. WHY: most teams only add `--randomize` without `showSeed`, so when a random order exposes a failure in CI, the failure cannot be reproduced locally because the seed is unknown. The CI logs do not contain the seed unless `showSeed` is explicitly configured.
    ```typescript
    // jest.config.ts
    import type { Config } from 'jest';

    const config: Config = {
      // Randomize test execution order within each file to surface order-dependencies
      randomize: true,

      // Print the random seed to stdout so CI failures can be reproduced with
      // `jest --seed=<PRINTED_SEED>` — essential for diagnosing order-dependent failures
      showSeed: true,

      preset: 'ts-jest',
      testEnvironment: 'node',
    };

    export default config;

    // To reproduce a specific CI failure:
    // jest --seed=1234567890 --testPathPattern="path/to/failing.test.ts"
    ```

66. **Vitest test tags + `TestRunner.matchesTags()` enable conditional expensive setup — avoiding isolation overhead for unrelated tests.** [community]
    Vitest 4.1 test tags solve an isolation anti-pattern: expensive setup (database seeding, spinning up an HTTP server) in `beforeAll` that runs for *all* tests in the suite, even tests that don't need it. With `TestRunner.matchesTags()`, setup logic can be gated behind a tag check — the expensive setup only runs when tests tagged `'db'` or `'integration'` are included in the current run. WHY: teams that add `beforeAll(seedDatabase)` to a `vitest.unit.setup.ts` file cause every unit test run to incur database seeding overhead — defeating the purpose of running unit tests quickly. Tag-gated setup keeps the fast-feedback loop intact.
    ```typescript
    // vitest.config.ts
    import { defineConfig } from 'vitest/config';

    export default defineConfig({
      test: {
        tags: {
          db: { timeout: 30000, retry: 1 },       // DB tests get longer timeout + 1 retry
          integration: { timeout: 15000 },
          unit: { timeout: 5000 },
        },
        setupFiles: ['./vitest.setup.ts'],
      },
    });

    // vitest.setup.ts
    import { TestRunner } from 'vitest';
    import { seedDatabase, teardownDatabase } from './testHelpers/db';

    // Only seed the database when DB-tagged tests are actually in the current run.
    // `vitest --tags-filter="unit"` skips this setup entirely — unit tests stay fast.
    if (TestRunner.matchesTags(['db', 'integration'])) {
      beforeAll(async () => {
        await seedDatabase();
      });

      afterAll(async () => {
        await teardownDatabase();
      });
    }

    // user.integration.test.ts — annotated with tag to opt in to DB setup
    import { describe, test, expect } from 'vitest';
    import { userRepository } from './repositories/userRepository';

    describe('UserRepository', { tags: ['db', 'integration'] }, () => {
      test('finds a seeded user by email', async () => {
        const user = await userRepository.findByEmail('alice@example.com');
        expect(user?.name).toBe('Alice');
      });
    });

    // unit.test.ts — no tags → matchesTags returns false → no DB setup → fast
    import { describe, test, expect } from 'vitest';
    import { formatUserName } from './utils/formatUserName';

    describe('formatUserName', { tags: ['unit'] }, () => {
      test('capitalizes first letter', () => {
        expect(formatUserName('alice')).toBe('Alice');
      });
    });
    ```

67. **`jest.protectProperties(key)` from `jest-util` prevents specific globals from being wiped by `globalsCleanup: 'on'`.** [community]
    Jest 30's `globalsCleanup: 'on'` (Gotcha 34) wipes all globals added to `globalThis` by a test file. The escape hatch: `protectProperties(globalThis['key'])` from `jest-util` marks a specific global as exempt from the cleanup sweep. This is the right tool for test helpers that legitimately set a global once (e.g., polyfills, shared test matchers) and must persist across test files in the same worker. Without this escape hatch, teams must either: (a) switch to `globalsCleanup: 'soft'` (which ignores the cleanup for all globals) or (b) re-register the global in every test file — both worse options. WHY: the `protectProperties` API is not widely documented and is often missed by teams that enable `globalsCleanup: 'on'` and then find their shared test infrastructure breaking.
    ```typescript
    // jest.setup.ts — called from setupFilesAfterFramework in jest.config.ts
    import { protectProperties } from 'jest-util';

    // Register a custom matcher for all tests — must survive globalsCleanup: 'on'
    expect.extend({
      toBeValidUUID(received: unknown) {
        const pass = typeof received === 'string' &&
          /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(received);
        return {
          pass,
          message: () => `expected ${received} ${pass ? 'not ' : ''}to be a valid UUID`,
        };
      },
    });

    // Protect this custom matcher from being wiped between files by globalsCleanup: 'on'
    // Without this, every test file that uses toBeValidUUID would need to re-register it
    protectProperties(globalThis['expect']);

    // jest.config.ts companion
    // testEnvironmentOptions: { globalsCleanup: 'on' }  — enabled for maximum cleanliness
    // setupFilesAfterFramework: ['./jest.setup.ts']
    ```

---

## Extended Patterns — Iteration 16

### Pattern 26: `vi.mockThrow()` chaining for resilience test isolation (TypeScript, Vitest 4.1+)  [community]

The `mockThrow()` / `mockThrowOnce()` API enables declarative error injection without stateful mock implementation closures. This pattern tests that a service is resilient to transient failures — the most common error-path isolation scenario — using pure declarative mock composition in the test body.

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { StorageService } from './storageService';
import { UploadService } from './uploadService';

describe('UploadService — transient error resilience', () => {
  let storage: vi.Mocked<StorageService>;
  let uploader: UploadService;

  beforeEach(() => {
    // Fresh typed mock per test — no accumulated throw state
    storage = {
      upload: vi.fn<(key: string, data: Uint8Array) => Promise<string>>(),
      delete: vi.fn<(key: string) => Promise<void>>(),
    };
    uploader = new UploadService(storage);
  });

  it('succeeds on first attempt when storage is healthy', async () => {
    storage.upload.mockResolvedValue('https://cdn.example.com/file-1');

    const url = await uploader.upload('file-1', new Uint8Array([1, 2, 3]));

    expect(url).toBe('https://cdn.example.com/file-1');
    expect(storage.upload).toHaveBeenCalledTimes(1);
  });

  it('retries once and succeeds on transient 503', async () => {
    // First call throws; second returns success — declarative, no closure state
    storage.upload
      .mockThrowOnce(Object.assign(new Error('Service Unavailable'), { status: 503 }))
      .mockResolvedValue('https://cdn.example.com/file-2');

    const url = await uploader.upload('file-2', new Uint8Array([4, 5, 6]));

    expect(url).toBe('https://cdn.example.com/file-2');
    expect(storage.upload).toHaveBeenCalledTimes(2);
  });

  it('gives up after max retries and propagates the error', async () => {
    // mockThrow (not Once) — throws on every call indefinitely
    storage.upload.mockThrow(new Error('DISK_FULL'));

    await expect(
      uploader.upload('file-3', new Uint8Array([7, 8, 9])),
    ).rejects.toThrow('DISK_FULL');

    // Verify max retry count by checking call count
    expect(storage.upload).toHaveBeenCalledTimes(3); // configurable via UploadService constructor
  });

  it('cleans up the partial upload key when all retries fail', async () => {
    storage.upload.mockThrow(new Error('NETWORK_ERROR'));
    storage.delete.mockResolvedValue(undefined);

    await expect(uploader.upload('file-4', new Uint8Array())).rejects.toThrow();

    // Error-path cleanup — delete must be called with the attempted key
    expect(storage.delete).toHaveBeenCalledWith('file-4');
  });
});
```

**Key rule:** Use `mockThrowOnce()` for transient errors (Nth call succeeds). Use `mockThrow()` for permanent errors (all calls fail). Avoid `mockImplementation(() => { throw ... })` — it requires a closure and is harder to compose with `mockResolvedValue` / `mockReturnValue` in the same chain.

### Pattern 27: `mock.withImplementation()` for per-assertion mock overrides (TypeScript, Vitest)  [community]

`mock.withImplementation(fn, callback)` is the correct tool when a single assertion within a test requires a different mock behavior than the default — without restructuring the test or touching `beforeEach`. The previous implementation is automatically restored when the callback returns, including when it throws. This is stronger than `mockReturnValueOnce()` because the scope is explicit and enforced by a function boundary.

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AuditLogger } from './auditLogger';
import { AuditService } from './auditService';

describe('AuditService — scoped implementation overrides', () => {
  let logger: vi.Mocked<AuditLogger>;
  let service: AuditService;

  beforeEach(() => {
    logger = {
      log: vi.fn<(entry: string) => void>(),
      flush: vi.fn<() => Promise<void>>().mockResolvedValue(undefined),
    };
    service = new AuditService(logger);
  });

  it('logs all events in the default (no-op) mode', () => {
    service.record('login', 'user-1');
    service.record('logout', 'user-1');

    expect(logger.log).toHaveBeenCalledTimes(2);
  });

  it('captures the exact log format when formatter is overridden', async () => {
    const captured: string[] = [];

    // withImplementation overrides logger.log only inside the callback
    await logger.log.withImplementation(
      (entry: string) => { captured.push(entry); },
      async () => {
        service.record('purchase', 'user-2');
        service.record('refund', 'user-2');
      },
    );

    // Outside the callback, logger.log is back to the no-op mock from beforeEach
    expect(captured).toHaveLength(2);
    expect(captured[0]).toMatch(/purchase.*user-2/);
    expect(captured[1]).toMatch(/refund.*user-2/);

    // Verify the override was genuinely scoped: calling record again uses the original mock
    service.record('view', 'user-2');
    expect(captured).toHaveLength(2); // NOT 3 — scoped implementation no longer active
  });

  it('restores the default implementation even when the callback throws', async () => {
    const call = logger.log.withImplementation(
      () => { throw new Error('logger-broken'); },
      () => {
        service.record('event', 'user-3'); // this will throw via the implementation
      },
    );

    await expect(call).rejects.toThrow('logger-broken');

    // Implementation is restored despite the throw — no leaked broken state
    service.record('recovery-event', 'user-4');
    expect(logger.log).toHaveBeenLastCalledWith(expect.stringContaining('recovery-event'));
  });
});
```

**When to prefer over `mockReturnValueOnce()`:** Use `withImplementation` when the override applies to *all* calls within a code block (not just the next one). Use `mockReturnValueOnce()` / `mockThrowOnce()` when you need to control behavior for specific call N in a sequence. `withImplementation` is the better choice for callback-scoped behavior changes; `*Once()` is better for sequence-based isolation.

---

## Quick Reference Additions — Iteration 16

| Problem | Symptom | TypeScript/Jest Solution | Vitest equivalent |
|---------|---------|--------------------------|-------------------|
| Error injection boilerplate (`mockImplementation(() => { throw ... })`) | Long closures; difficult to chain with return values | No Jest equivalent for `mockThrow` | `vi.fn().mockThrow(error)` / `mockThrowOnce(error)` (Vitest 4.1+) |
| Single-assertion mock override without `beforeEach` restructure | Mock behavior needs to differ for one sub-case | `jest.fn().mockReturnValueOnce() + manual restore` | `mock.withImplementation(fn, callback)` — auto-restore |
| Worker heap accumulation causing non-deterministic slowdowns | Tests slow down as suite runs longer; `--runInBand` "fixes" it | `workerIdleMemoryLimit: '512MB'` in `jest.config.ts` | N/A |
| Cannot reproduce CI order-dependent failures locally | Randomized order differs between CI and local run | `showSeed: true` in config + re-run with `--seed=<N>` | `sequence.seed` in `vitest.config.ts` |
| Expensive setup (DB seeding) runs even in unit-only runs | Unit test suites slow because `beforeAll` always seeds DB | N/A | `TestRunner.matchesTags(['db'])` in `vitest.setup.ts` |
| Custom global (`expect.extend`) wiped by `globalsCleanup: 'on'` | Custom matchers disappear after first test file runs | `protectProperties(globalThis['expect'])` from `jest-util` | N/A (Vitest handles matcher registration differently) |
| Module-level singleton reset for entire suite without per-file boilerplate | Every test file needs `beforeEach(() => jest.resetModules())` | `resetModules: true` in `jest.config.ts` (global, expensive) | `vi.resetModules()` in `setupFiles` + `isolate: true` |

---

## Key Resources — Iteration 16 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest API — `mock.mockThrow` / `mockThrowOnce` | Official | https://vitest.dev/api/mock#mockthrow | v4.1.0+ error injection without closure-based `mockImplementation` |
| Vitest API — `mock.withImplementation` | Official | https://vitest.dev/api/mock#mockwithimplementation | Scoped temporary mock override auto-restored after callback |
| Jest Config — `workerIdleMemoryLimit` | Official | https://jestjs.io/docs/configuration#workeridlememorylimit-numberstring | Worker recycling threshold — isolates heap state accumulation in long suite runs |
| Jest Config — `resetModules` | Official | https://jestjs.io/docs/configuration#resetmodules-boolean | Global module registry reset before every test — strongest singleton isolation, highest cost |
| Jest Config — `showSeed` + `randomize` | Official | https://jestjs.io/docs/configuration#showseed-boolean | Prints randomization seed to reproduce order-dependent failures with `--seed=<N>` |
| Vitest Guide — Test Tags | Official | https://vitest.dev/guide/test-tags.html | Tag-based test categorization; `TestRunner.matchesTags()` for conditional expensive setup |
| `jest-util` — `protectProperties` | Official | https://jestjs.io/docs/configuration#testEnvironmentOptions | Exempts specific globals from `globalsCleanup: 'on'` sweep |

---

## Community Lessons — Iteration 17  [community]

68. **`vi.setTimerTickMode('nextTimerAsync')` eliminates manual `advanceTimersByTime()` boilerplate in promise-heavy async tests.** [community]
    Vitest 4.1 adds `vi.setTimerTickMode()` with three modes: `'manual'` (default), `'nextTimerAsync'`, and `'interval'`. The `nextTimerAsync` mode automatically advances fake timers to the next pending callback after each macrotask resolves — eliminating the need to manually call `vi.advanceTimersByTime()` for every `await` in async code. Teams testing code with interleaved `setTimeout`/`setInterval` and Promise chains frequently discover that `advanceTimersByTime()` fires callbacks in the wrong phase because the awaited microtask queue has not yet drained. `nextTimerAsync` solves this by synchronizing timer advancement with the microtask boundary. WHY: `advanceTimersByTime` is a synchronous operation that fires pending timers immediately, but async code expects timers to fire *after* awaited Promises resolve. The mismatch causes tests where `await somePromise()` never resolves because the timer that resolves it was already consumed.
    ```typescript
    // vitest: nextTimerAsync mode — automatic timer advancement between awaits
    import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
    import { RetryQueue } from './retryQueue';

    describe('RetryQueue — nextTimerAsync mode', () => {
      beforeEach(() => {
        vi.useFakeTimers();
        vi.setTimerTickMode('nextTimerAsync'); // automatically advance between awaits
      });

      afterEach(() => {
        vi.useRealTimers();
      });

      it('retries with exponential backoff and eventually resolves', async () => {
        const handler = vi.fn<() => Promise<string>>()
          .mockRejectedValueOnce(new Error('transient'))
          .mockResolvedValue('success');

        const queue = new RetryQueue(handler, { baseDelay: 1000, maxRetries: 3 });

        // With nextTimerAsync, awaiting the result auto-advances through each retry delay
        // No manual advanceTimersByTime(1000) calls needed between retries
        const result = await queue.enqueue('job-1');

        expect(result).toBe('success');
        expect(handler).toHaveBeenCalledTimes(2); // 1 fail + 1 success
      });

      it('rejects after max retries are exhausted', async () => {
        const handler = vi.fn<() => Promise<string>>()
          .mockRejectedValue(new Error('permanent'));

        const queue = new RetryQueue(handler, { baseDelay: 500, maxRetries: 2 });

        await expect(queue.enqueue('job-2')).rejects.toThrow('permanent');
        expect(handler).toHaveBeenCalledTimes(3); // initial + 2 retries
      });
    });
    ```
    **When NOT to use:** `nextTimerAsync` mode can cause unexpected timer advancement if test code contains `await Promise.resolve()` gaps that you intended to use as checkpoints. Use `'manual'` mode when you need precise control over which timer fires and when — for example, when asserting intermediate states between timer ticks.

69. **`vi.mockObject({ spy: true })` enables call verification without replacing implementations — the isolation-preserving spy alternative to `vi.mock()`.** [community]
    `vi.mockObject(obj, { spy: true })` (Vitest 3.2+) deeply wraps an object's methods with spy instrumentation while preserving the original implementation. This is the idiomatic choice when you need to verify that a real collaborator was called correctly without replacing its behavior — as opposed to `vi.mock()` which replaces the entire module with stubs. The key isolation advantage: `{ spy: true }` preserves production behavior for happy-path tests while still tracking calls, removing the need for a separate integration test just to verify "was the method actually called." WHY: teams that reach for `vi.mock()` as a default to verify call counts pay the price of maintaining stub implementations that drift from the real interface. `vi.mockObject({ spy: true })` stays in sync automatically because the real implementation remains active.
    ```typescript
    import { describe, it, expect, vi, afterEach } from 'vitest';
    import { EmailValidator } from './emailValidator';
    import { UserRegistrationService } from './userRegistrationService';

    describe('UserRegistrationService — spy without stub', () => {
      // Spy on the real EmailValidator — real validation logic runs, but calls are tracked
      const validator = vi.mockObject(new EmailValidator(), { spy: true });
      const service = new UserRegistrationService(validator);

      afterEach(() => {
        // Reset call history; real implementation remains unchanged
        vi.clearAllMocks();
      });

      it('validates the email address before persisting the user', async () => {
        await service.register({ email: 'alice@example.com', name: 'Alice' });

        // Verify the real validator was called — no stub needed, real logic ran
        expect(validator.validate).toHaveBeenCalledWith('alice@example.com');
        expect(validator.validate).toHaveBeenCalledTimes(1);
      });

      it('rejects invalid email addresses using real validation logic', async () => {
        // The real validator actually runs — this is NOT a stub returning a canned value
        await expect(
          service.register({ email: 'not-an-email', name: 'Bob' }),
        ).rejects.toThrow(/invalid email/i);
      });
    });
    ```
    **When to prefer over `jest.Mocked<T>` / `vi.mocked()`:** Use `{ spy: true }` when the collaborator's real logic matters for the test (e.g., format validation, calculations). Use full mocking when you need to control return values or simulate failures the real object cannot produce.

70. **`test.override()` (Vitest 4.1) replaces deprecated `test.scoped` — use it to apply fixture overrides to a suite without a wrapper `test.extend()`.** [community]
    `test.override(fixtureName, value)` overrides a named fixture for all tests within the current `describe` block and its nested suites. It is the successor to the deprecated `test.scoped` API, which had implicit scoping semantics. The key isolation benefit: suites testing different configuration variants (e.g., prod vs staging, auth vs unauth) can override a `config` fixture locally without affecting other test suites. Without `test.override`, teams resort to either (a) a wrapper `test.extend()` that creates a new `test` object per describe block, or (b) mutating module-level variables in `beforeEach` — both worse options. WHY: the fixture override is scoped to the `describe` block's lifetime by the Vitest framework, ensuring it cannot leak into sibling or parent suites — unlike `beforeEach` mutation which requires manual restore.
    ```typescript
    import { test as baseTest, describe, expect } from 'vitest';
    import type { AppConfig } from './config';

    // Base fixture providing default config
    const test = baseTest.extend<{ config: AppConfig }>({
      config: async ({}, use) => {
        await use({ environment: 'development', apiUrl: 'http://localhost:3000', timeout: 5000 });
      },
    });

    // Default suite — uses config from the fixture as-is
    describe('UserService — development', () => {
      test('uses the development API URL', ({ config }) => {
        expect(config.apiUrl).toBe('http://localhost:3000');
      });
    });

    // Production suite — overrides config fixture; sibling describe is unaffected
    describe('UserService — production', () => {
      // test.override replaces the fixture value for ALL tests in this describe block
      test.override('config', { environment: 'production', apiUrl: 'https://api.example.com', timeout: 30000 });

      test('uses the production API URL', ({ config }) => {
        expect(config.apiUrl).toBe('https://api.example.com');
        expect(config.timeout).toBe(30000);
      });

      test('has the production environment label', ({ config }) => {
        expect(config.environment).toBe('production');
      });
    });

    // This suite is unaffected — fixture value is back to development defaults
    describe('UserService — staging', () => {
      test.override('config', { environment: 'staging', apiUrl: 'https://staging.api.example.com', timeout: 10000 });

      test('uses the staging API URL', ({ config }) => {
        expect(config.apiUrl).toBe('https://staging.api.example.com');
      });
    });
    ```
    **Migration from `test.scoped`:** Replace `test.scoped({ fixtureName: value })` with `test.override(fixtureName, value)`. The semantics are the same; `test.scoped` was deprecated in Vitest 4.1 and will be removed in a future major version.

71. **`FixtureAccessError` in Vitest 4.1 surfaces the root cause of a common suite-level hook isolation bug.** [community]
    Vitest 4.1 throws a `FixtureAccessError` when a suite-level hook (`beforeAll` / `afterAll`) tries to access a test-scoped fixture — a fixture that has no value outside an individual test body. Before 4.1, the undefined fixture would be silently passed as `undefined`, causing confusing `TypeError: Cannot read properties of undefined` failures attributed to unrelated test code. WHY: test-scoped fixtures are created fresh per test and destroyed after the test ends. They are meaningless at the `beforeAll` level (before any test runs) or `afterAll` level (after all tests have run). The correct fix is to either: (a) use `test.beforeAll` (which receives the fixture context only if the suite's `test.extend` provides it) or (b) upgrade the fixture's scope from `'test'` (default) to `'file'` or `'worker'` if it should survive multiple tests.
    ```typescript
    import { test as baseTest, describe, expect, beforeAll } from 'vitest';
    import { createDbConnection, closeDbConnection } from './db';

    const test = baseTest.extend<{ db: ReturnType<typeof createDbConnection> }>({
      // Default scope is 'test' — a fresh db per test
      db: async ({}, use) => {
        const conn = await createDbConnection();
        await use(conn);
        await closeDbConnection(conn);
      },
    });

    describe('DataService', () => {
      // BROKEN in Vitest 4.1 — throws FixtureAccessError because `db` is test-scoped
      // beforeAll(({ db }) => { db.seed(); }); // FixtureAccessError!

      // CORRECT — use test.beforeAll to access fixture context
      test.beforeAll(async ({ db }) => {
        // test.beforeAll receives the fixture context from test.extend
        await db.seed();
      });

      test('reads a seeded record', async ({ db }) => {
        const record = await db.findById('seed-1');
        expect(record).toBeDefined();
      });
    });

    // ALTERNATIVE — upgrade scope to 'file' if the db should be shared across tests
    const sharedTest = baseTest.extend<{ db: ReturnType<typeof createDbConnection> }>({
      db: {
        scope: 'file', // One db connection per file — accessible in beforeAll/afterAll
        async fixture({}, use) {
          const conn = await createDbConnection();
          await use(conn);
          await closeDbConnection(conn);
        },
      },
    });
    ```

72. **`vi.doMock()` now returns a disposable (Vitest 4.1) — enabling `using`-based mock cleanup without `vi.doUnmock()`.** [community]
    `vi.doMock()` (the non-hoisted counterpart to `vi.mock()`) now returns a `Disposable` object in Vitest 4.1. Combined with TypeScript 5.2's `using` keyword, this allows mock registration and cleanup to be co-located in the test body — the mock is automatically unregistered when the block scope exits. This solves the primary ordering problem with `vi.doMock()`: teams previously needed to remember to call `vi.doUnmock()` in `afterEach`, and forgetting it caused the mock to persist into subsequent tests. WHY: `vi.mock()` is hoisted (runs before module imports), which is correct for most module mocks. `vi.doMock()` is called at runtime (inside the test body), which is needed when the mock factory depends on runtime values. The disposable pattern eliminates the cleanup burden for the runtime-mock use case.
    ```typescript
    import { describe, it, expect, vi } from 'vitest';

    describe('feature flag module isolation (vi.doMock disposable)', () => {
      it('uses the real analytics module when flag is off', async () => {
        // doMock returns a Disposable — using ensures cleanup when this test ends
        using _mock = vi.doMock('./analytics', () => ({
          track: vi.fn().mockResolvedValue(undefined),
        }));

        // Dynamic import picks up the mock registered above
        const { track } = await import('./analytics');

        track('event', { userId: 'u1' });

        expect(track).toHaveBeenCalledWith('event', { userId: 'u1' });
        // When this test ends, _mock[Symbol.dispose]() is called — vi.doUnmock('./analytics') fires
        // The next test that imports './analytics' gets the real module
      });

      it('real analytics module is restored — no mock leak', async () => {
        // This test sees the real module because the previous test's `using` disposed the mock
        const { track } = await import('./analytics');
        // track is the real implementation — calling it does not use a mock
        expect(vi.isMockFunction(track)).toBe(false);
      });
    });
    ```
    **When to prefer over `vi.mock()`:** Use `vi.doMock()` with `using` when the mock factory depends on a runtime variable (e.g., a test-specific configuration value) that is not available at module-parse time. Use `vi.mock()` when the mock is the same for all tests in the file and can be declared at file scope.

73. **`vi.defineHelper()` isolates assertion helper internals from test stack traces — critical for diagnosing isolation failures in shared helper libraries.** [community]
    Vitest 4.1's `vi.defineHelper(fn)` wraps a function so that when an assertion inside the helper fails, the stack trace points to the *call site* (where the helper was invoked in the test) rather than the assertion line inside the helper. Without this, shared test assertion helpers produce stack traces that look like: `AssertionError at helper.ts:42` — making it impossible to quickly identify which test triggered the failure. WHY: in test suites that share assertion helpers for common domain checks (e.g., `expectValidApiResponse(res)`, `expectIsolatedDatabase(conn)`), the assertion point is meaningless without call-site attribution. `vi.defineHelper` is the Vitest analogue of `expect.extend` (which does the same for custom matchers) but for arbitrary helper functions.
    ```typescript
    import { expect, vi } from 'vitest';
    import type { HttpResponse } from '../src/types';

    // WITHOUT vi.defineHelper — stack trace points to line 9 (inside the helper), not the call site
    export function expectValidApiResponse(res: HttpResponse): void {
      expect(res.status).toBeGreaterThanOrEqual(200);
      expect(res.status).toBeLessThan(300);
      expect(res.body).toBeDefined();
      expect(res.headers['content-type']).toMatch(/application\/json/);
    }

    // WITH vi.defineHelper — stack trace points to where expectValidApiResponse() was called
    export const expectValidApiResponseSafe = vi.defineHelper(
      function expectValidApiResponse(res: HttpResponse): void {
        expect(res.status).toBeGreaterThanOrEqual(200);
        expect(res.status).toBeLessThan(300);
        expect(res.body).toBeDefined();
        expect(res.headers['content-type']).toMatch(/application\/json/);
      }
    );

    // In tests — when the second version fails, you see WHICH test called it, not WHERE inside the helper
    import { test, expect } from 'vitest';
    import { expectValidApiResponseSafe } from './testHelpers';

    test('GET /users returns a valid JSON response', async () => {
      const res = await fetch('http://localhost:3000/users').then(r =>
        r.json().then(body => ({ status: r.status, body, headers: Object.fromEntries(r.headers) }))
      );

      // If this fails, stack trace shows THIS LINE — not line 9 in testHelpers.ts
      expectValidApiResponseSafe(res);
    });
    ```
    **Isolation relevance:** When an isolation helper (`expectIsolatedDatabase`, `expectCleanEnvironment`) fails and the stack trace points into the helper, teams waste time investigating the helper code rather than the test that triggered the contamination. `vi.defineHelper` makes isolation failures immediately attributable.

74. **Vitest fixture scope hierarchy (worker > file > test) determines the isolation boundary — mismatched scopes are a silent source of cross-test contamination.** [community]
    Vitest's `test.extend()` fixtures have four scopes: `'test'` (default, fresh per test), `'file'` (shared across all tests in one file), `'worker'` (shared across all files processed by the same worker process), and `'suite'` (shared within a describe block). Choosing the wrong scope is one of the most common fixture-related isolation bugs, because the framework does not warn when a test-scoped fixture depends on a file-scoped one that has already been torn down. The scope contract: a fixture can only use fixtures with equal or longer-lived scope (worker ≥ file ≥ suite ≥ test). Violating this causes `FixtureAccessError` in Vitest 4.1 (Gotcha 71) — but in earlier versions, it produced silent `undefined` dependencies. WHY: teams building test frameworks on top of Vitest often start with file-scoped shared databases, then discover that tests that write data corrupt subsequent tests in the same file because the teardown only runs at end-of-file, not between tests. The fix is either transaction rollback within each test (using `aroundEach`, Pattern 24) or downgrading the database fixture to test scope with a fresh connection per test.
    ```typescript
    import { test as baseTest } from 'vitest';
    import { seedData } from './testHelpers/seed';
    import { createConnection, closeConnection } from './db';

    // Scope hierarchy example — matching fixture lifetime to test requirements
    const test = baseTest.extend({
      // Worker-scoped: loaded ONCE across all files on this worker — only for read-only config
      appConfig: {
        scope: 'worker',
        async fixture({}, use) {
          const config = await loadConfig(); // expensive — do once per worker
          await use(config);
          // No teardown needed — config is read-only
        },
      },

      // File-scoped: one connection per test FILE — read-only seed data
      readonlyDb: {
        scope: 'file',
        async fixture({ appConfig }, use) {
          const conn = await createConnection(appConfig.dbUrl);
          await seedData(conn); // seed once for all tests in this file
          await use(conn);
          await closeConnection(conn); // runs after all tests in the file complete
        },
      },

      // Test-scoped (default): fresh writable connection per test — for mutation tests
      writableDb: async ({ appConfig }, use) => {
        const conn = await createConnection(appConfig.dbUrl);
        await use(conn);
        await conn.query('TRUNCATE test_mutations'); // clean up mutations
        await closeConnection(conn);
      },
    });

    // Rule: never use writableDb in beforeAll/afterAll — those run at file scope
    // Use test.beforeAll to access readonlyDb; use test body for writableDb
    ```
    **Anti-pattern to avoid:** Using a `'file'`-scoped mutable database and trying to reset it between tests in `beforeEach` — the reset is a test-level operation but the fixture is file-scoped, creating an asymmetric cleanup that leaves uncommitted transactions or orphaned rows when tests run concurrently.

---

## Extended Patterns — Iteration 17

### Pattern 28: `vi.setTimerTickMode('nextTimerAsync')` for async retry loop isolation (TypeScript, Vitest 4.1+)  [community]

`nextTimerAsync` mode removes the manual timer-advancement boilerplate from tests that interleave Promises and timers. The mode automatically fires the next pending timer callback after each macrotask completes, keeping fake timers and async code synchronized without `advanceTimersByTime()` calls between every `await`.

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { ExponentialBackoff } from './exponentialBackoff';

describe('ExponentialBackoff (nextTimerAsync mode)', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    // nextTimerAsync: timers fire automatically after each awaited Promise resolves
    vi.setTimerTickMode('nextTimerAsync');
  });

  afterEach(() => {
    vi.useRealTimers(); // always restore — timer mode leaks if not reset
  });

  it('resolves on second attempt after first transient failure', async () => {
    const operation = vi.fn<() => Promise<string>>()
      .mockRejectedValueOnce(new Error('503 Service Unavailable'))
      .mockResolvedValue('data-payload');

    const backoff = new ExponentialBackoff(operation, {
      initialDelay: 1000,
      multiplier: 2,
      maxAttempts: 3,
    });

    // No manual vi.advanceTimersByTime() needed — nextTimerAsync handles the 1000ms delay
    const result = await backoff.run();

    expect(result).toBe('data-payload');
    expect(operation).toHaveBeenCalledTimes(2);
  });

  it('throws after all attempts are exhausted', async () => {
    const operation = vi.fn<() => Promise<string>>()
      .mockRejectedValue(new Error('permanent failure'));

    const backoff = new ExponentialBackoff(operation, {
      initialDelay: 500,
      multiplier: 2,
      maxAttempts: 3,
    });

    await expect(backoff.run()).rejects.toThrow('permanent failure');
    // 3 attempts: initial + 500ms delay + 1000ms delay
    expect(operation).toHaveBeenCalledTimes(3);
  });

  it('manual mode: delays are not automatically advanced', async () => {
    // Switch to manual to verify that WITHOUT nextTimerAsync, you'd need explicit advancement
    vi.setTimerTickMode('manual');

    const operation = vi.fn<() => Promise<string>>()
      .mockRejectedValueOnce(new Error('transient'))
      .mockResolvedValue('ok');

    const backoff = new ExponentialBackoff(operation, { initialDelay: 200, maxAttempts: 2 });

    const runPromise = backoff.run();
    // Promise is pending — backoff is waiting for the 200ms timer
    expect(operation).toHaveBeenCalledTimes(1); // only first attempt fired

    vi.advanceTimersByTime(200); // manually fire the delay
    const result = await runPromise;

    expect(result).toBe('ok');
    expect(operation).toHaveBeenCalledTimes(2);
  });
});
```

**Key rule:** Always pair `vi.setTimerTickMode()` with `vi.useRealTimers()` in `afterEach`. The timer tick mode is part of the fake timer state — it is NOT automatically reset between tests even with `clearMocks: true` in config. Failing to reset causes subsequent tests that expect manual mode to fire timers automatically.

### Pattern 29: `vi.mockObject({ spy: true })` for classicist-style call verification (TypeScript, Vitest 3.2+)  [community]

`vi.mockObject(realInstance, { spy: true })` is the classicist's alternative to full object mocking. It wraps every method with a spy while executing the real implementation — enabling call-count assertions without sacrificing the real behavior. This is the correct tool for the common pattern: "I want to verify this method was called, but I also need the real logic to run for the assertion to be meaningful."

```typescript
import { describe, it, expect, vi, afterEach } from 'vitest';
import { PricingCalculator } from './pricingCalculator';
import { OrderService } from './orderService';

describe('OrderService — call verification with real pricing logic', () => {
  // Real PricingCalculator — real logic runs, calls are tracked
  const calculator = vi.mockObject(new PricingCalculator({ vatRate: 0.2 }), { spy: true });
  const service = new OrderService(calculator);

  afterEach(() => {
    // Clear call history between tests; real implementation is unchanged
    vi.clearAllMocks();
  });

  it('calls calculateLineTotal once per order item', async () => {
    const order = {
      items: [
        { sku: 'sku-1', qty: 2, unitPrice: 10.00 },
        { sku: 'sku-2', qty: 1, unitPrice: 25.00 },
      ],
    };

    const total = await service.processOrder(order);

    // Real calculator ran: (2 * 10 * 1.2) + (1 * 25 * 1.2) = 24 + 30 = 54
    expect(total).toBeCloseTo(54.00, 2);

    // Call verification: method was called once per item
    expect(calculator.calculateLineTotal).toHaveBeenCalledTimes(2);
    expect(calculator.calculateLineTotal).toHaveBeenNthCalledWith(1, { sku: 'sku-1', qty: 2, unitPrice: 10.00 });
    expect(calculator.calculateLineTotal).toHaveBeenNthCalledWith(2, { sku: 'sku-2', qty: 1, unitPrice: 25.00 });
  });

  it('applies VAT via the real calculateVat method — not a stub', async () => {
    const lineTotal = 100.00;

    // Real vatRate (0.2) is used — verifies real behavior, not a canned value
    const withVat = calculator.applyVat(lineTotal);

    expect(withVat).toBeCloseTo(120.00, 2);
    expect(calculator.applyVat).toHaveBeenCalledWith(100.00);
  });
});
```

**When NOT to use:** Do not use `{ spy: true }` when the real collaborator makes network calls, writes to a database, or reads from the file system — the real implementation would execute and introduce side effects. Use full mocking (`vi.mock()` or `jest.Mocked<T>`) for I/O-bound collaborators.

### Pattern 30: `test.override()` for environment-variant test suites (TypeScript, Vitest 4.1+)  [community]

`test.override(fixtureName, value)` overrides a fixture value for an entire `describe` block without creating a new `test` variable. This is the correct tool for multi-environment test suites where each `describe` block represents a different configuration variant.

```typescript
import { test as baseTest, describe, expect, beforeAll } from 'vitest';
import type { ServiceConfig } from './config';
import { createApiClient } from './apiClient';

interface ApiFixture {
  client: ReturnType<typeof createApiClient>;
  config: ServiceConfig;
}

const test = baseTest.extend<ApiFixture>({
  config: async ({}, use) => {
    // Default config — development environment
    await use({
      baseUrl: 'http://localhost:3000',
      timeout: 5000,
      retries: 1,
      environment: 'development',
    });
  },
  // `client` depends on `config` — picks up the overridden value automatically
  client: async ({ config }, use) => {
    const c = createApiClient(config);
    await use(c);
    c.destroy();
  },
});

// Default suite — uses development config
describe('ApiClient — development', () => {
  test('sends requests to the development endpoint', ({ config, client }) => {
    expect(config.baseUrl).toBe('http://localhost:3000');
    expect(client.baseUrl).toBe('http://localhost:3000');
  });
});

// Production variant — overrides config; client fixture is re-initialized with overridden config
describe('ApiClient — production', () => {
  test.override('config', {
    baseUrl: 'https://api.example.com',
    timeout: 30000,
    retries: 3,
    environment: 'production',
  });

  test('sends requests to the production endpoint', ({ config, client }) => {
    expect(config.baseUrl).toBe('https://api.example.com');
    expect(config.retries).toBe(3);
    expect(client.baseUrl).toBe('https://api.example.com'); // client re-initialized
  });

  test('uses the production timeout', ({ config }) => {
    expect(config.timeout).toBe(30000);
  });
});

// Staging variant — independent override; production suite is unaffected
describe('ApiClient — staging', () => {
  test.override('config', {
    baseUrl: 'https://staging.api.example.com',
    timeout: 15000,
    retries: 2,
    environment: 'staging',
  });

  test('uses the staging endpoint and retries', ({ config }) => {
    expect(config.environment).toBe('staging');
    expect(config.retries).toBe(2);
  });
});
```

**Key advantage over `beforeEach` mutation:** With `beforeEach` mutation, restoring the original config value requires a manual save/restore pattern (anti-pattern in Pattern 5 of this guide). `test.override` handles restoration automatically — when the `describe` block exits, the fixture reverts to its pre-override value without any teardown code.

---

## Quick Reference Additions — Iteration 17

| Problem | Symptom | Vitest 4.1+ Solution | Jest equivalent |
|---------|---------|---------------------|-----------------|
| Manual `advanceTimersByTime` between every `await` | Test has 10+ `vi.advanceTimersByTime()` calls; breaks with timing changes | `vi.setTimerTickMode('nextTimerAsync')` — auto-advance between awaits | No equivalent; manual advance required |
| Real implementation + call verification | Must choose: stub OR real behavior — not both | `vi.mockObject(instance, { spy: true })` — real logic + call tracking | `jest.spyOn(instance, 'method')` per method (no bulk option) |
| Per-suite fixture override without a new `test` variable | `beforeEach` mutation with manual save/restore | `test.override('fixtureName', value)` inside `describe` | No equivalent; create new `test = baseTest.extend(...)` |
| Undefined fixture in `beforeAll` | Silently receives `undefined`; confusing `TypeError` in test body | `FixtureAccessError` thrown immediately (Vitest 4.1) → fix scope | No equivalent; no error at hook registration time |
| `vi.doMock()` cleanup forgotten in `afterEach` | Mock persists across tests; next test sees unexpected stub | `using _mock = vi.doMock(...)` — auto-disposes when test ends | No equivalent for `jest.doMock` cleanup |
| Assertion helper stack trace points into helper code | Cannot tell which test triggered isolation failure | `vi.defineHelper(fn)` — stack trace redirects to call site | `expect.extend()` for custom matchers only |
| Wrong fixture scope causes cross-test contamination | Tests pass individually, fail in suite; order-dependent | Explicit `scope: 'file'` or `scope: 'worker'`; use `aroundEach` for transaction rollback | N/A — Jest has no fixture scope system |

---

## Key Resources — Iteration 17 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest API — `vi.setTimerTickMode` | Official | https://vitest.dev/api/vi#vi-settimertickmode | Three timer advancement modes: manual, nextTimerAsync, interval — eliminates advanceTimersByTime boilerplate |
| Vitest API — `vi.mockObject` | Official | https://vitest.dev/api/vi#vi-mockobject | Deep object spy/mock with `{ spy: true }` option for classicist call verification |
| Vitest API — `test.override` | Official | https://vitest.dev/api/#test-override | Suite-scoped fixture override; replaces deprecated `test.scoped` |
| Vitest Guide — Test Context & Fixture Scopes | Official | https://vitest.dev/guide/test-context | Fixture scope hierarchy (worker/file/suite/test) and lifetime contracts |
| Vitest API — `vi.defineHelper` | Official | https://vitest.dev/api/vi#vi-definehelper | Call-site stack trace attribution for shared assertion helper functions |
| Vitest 4.1 Blog — What's New | Official | https://vitest.dev/blog/vitest-4-1.html | `aroundEach`/`aroundAll`, `detectAsyncLeaks`, `onCleanup` builder, `mockThrow`, `vi.defineHelper`, test tags, `viteModuleRunner: false` |

---

## Community Lessons — Iteration 18  [community]

75. **`vi.mock(import('./path'), factory)` — the module promise syntax gives TypeScript-safe factory return types and prevents silent mock shape drift.** [community]
    Vitest 4.1 supports `vi.mock()` with a module promise as the first argument (instead of a string path):
    ```typescript
    vi.mock(import('./emailService'), async (importOriginal) => {
      const actual = await importOriginal(); // preserves real non-mocked exports
      return {
        ...actual,
        send: vi.fn().mockResolvedValue(undefined),
      };
    });
    ```
    The key isolation benefit: TypeScript infers the factory's return type from the actual module shape. If `emailService` gains a new required export and the factory omits it, TypeScript reports a compile error — the mock is always structurally consistent with the real module. The string path version (`vi.mock('./emailService', () => ({ ... }))`) returns `unknown` from the factory and provides no type checking on what is being mocked. WHY: teams that use string-path `vi.mock()` factories without explicit type assertions accumulate mocks that silently diverge from the real interface after interface changes — the tests continue to pass while the production code compiles with errors that the tests cannot catch. The module promise syntax catches these at compile time.

76. **`onCleanup` can only be called once per fixture — combining multiple cleanups into one callback is the correct pattern.** [community]
    Vitest's fixture builder pattern (introduced in 4.1) provides an `onCleanup` parameter for registering teardown logic when returning a value from a fixture function. A critical, non-obvious constraint: `onCleanup` may only be called **once** per fixture invocation. Calling it multiple times (e.g., once for a database connection and again for a temp directory created within the same fixture) results in only the **last** registration being honored — earlier registrations are silently dropped. The correct pattern is to combine all cleanup into a single `onCleanup` call using a sequential teardown function:
    ```typescript
    const test = baseTest.extend({
      environment: async ({}, { onCleanup }) => {
        const conn = await createDbConnection();
        const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'env-'));

        // WRONG — calling onCleanup twice: only the second registration runs
        // onCleanup(() => closeDbConnection(conn));
        // onCleanup(() => fs.rm(dir, { recursive: true, force: true }));

        // CORRECT — single onCleanup that handles both resources sequentially
        onCleanup(async () => {
          await closeDbConnection(conn);
          await fs.rm(dir, { recursive: true, force: true });
        });

        return { conn, dir };
      },
    });
    ```
    WHY: the single-call restriction is documented but easily overlooked because `onCleanup` does not throw when called multiple times — it silently ignores subsequent calls. The failure mode is resource leaks (unclosed database connections or orphaned temp directories) that only appear as test hangs or `ENOMEM` errors in later test files. The correct mental model is: treat `onCleanup` like a `finally` block — write one function that cleans everything up in the right order.

77. **`vi.resetModules()` clears the module cache but does NOT reset the mock registry — `vi.unmock()` must be called separately for complete isolation.** [community]
    Teams that use `vi.resetModules()` to re-load a module under a fresh environment (e.g., to pick up different `process.env` values) often assume this also clears the mock registry. It does not. If `vi.mock('./service')` was called earlier in the test file or in a `setupFile`, the mock registration persists even after `vi.resetModules()`. The dynamically imported module will load a fresh instance — but that instance will still be mocked. The full teardown sequence for complete isolation requires both steps:
    ```typescript
    afterEach(() => {
      vi.resetModules();      // Clears module cache — next import re-evaluates the file
      vi.unmock('./service'); // Removes mock registry entry — next import gets the real module
    });
    ```
    Alternatively, use `vi.doMock()` with the `using` disposable (Pattern from iteration 17) for scoped mocking that handles both concerns automatically. WHY: `vi.resetModules()` and `vi.unmock()` operate on two independent registries — the loaded module instances cache and the mock factory registry. They are not transactively linked. Teams that reset one and not the other encounter tests where the module re-evaluates correctly (fresh env var, fresh singleton) but runs mocked code because the registry was never cleared — producing false passes where the real module behavior is never exercised.

78. **"Construct with Collaborators, Call with Work" — Google's 2026 DI principle: inject dependencies at construction time, pass work items at call time.** [community]
    Google Testing Blog (May 2026, author Shahar Roth) codifies a dependency injection principle directly relevant to test isolation: a class should receive its *collaborators* (services, repositories, clocks, loggers) in its constructor, and receive its *work data* (the payload, the user input, the parameters) in method call arguments. This split makes the class trivially testable: the test controls collaborators at construction time (via test doubles) and exercises logic by calling methods with controlled inputs.
    ```typescript
    // WRONG — work data injected at construction; hard to test different inputs
    class OrderProcessor {
      constructor(
        private readonly order: Order,  // work data — should be a method param
        private readonly inventory: InventoryService,  // collaborator — OK here
      ) {}
      process(): boolean {
        return this.inventory.reserve(this.order.skuId, this.order.qty);
      }
    }
    // Testing requires constructing a new OrderProcessor for each input variant — expensive

    // CORRECT — collaborators at constructor; work data at call time
    class OrderProcessor {
      constructor(
        private readonly inventory: InventoryService,  // collaborator only
      ) {}
      process(order: Order): boolean {  // work data as method argument
        return this.inventory.reserve(order.skuId, order.qty);
      }
    }

    // Test: one constructed instance, multiple work variants — clean isolation
    describe('OrderProcessor', () => {
      let inventory: jest.Mocked<InventoryService>;
      let processor: OrderProcessor;

      beforeEach(() => {
        inventory = { reserve: jest.fn().mockReturnValue(true) } as jest.Mocked<InventoryService>;
        processor = new OrderProcessor(inventory); // collaborator injected once
      });

      it('reserves the correct sku and quantity', () => {
        processor.process({ skuId: 'sku-1', qty: 3 }); // work data at call time

        expect(inventory.reserve).toHaveBeenCalledWith('sku-1', 3);
      });

      it('returns false when reservation is rejected', () => {
        inventory.reserve.mockReturnValue(false);

        const result = processor.process({ skuId: 'sku-2', qty: 1 }); // same instance, different work

        expect(result).toBe(false);
      });
    });
    ```
    WHY: when work data is injected at construction time, each test variant requires constructing a new object — and `beforeEach` setup complexity grows with each new test case. When work data is a method argument, the same constructed instance (with its injected doubles) can test unlimited input variants. This pattern is also the structural reason why `beforeEach` fixture reset is the right tool for collaborators but not for input data: collaborators belong in `beforeEach`; work data belongs in the test body's Arrange phase.

79. **Chai-style mock assertions (`.to.have.been.called`) are available in Vitest 4.1 but cause snapshot mismatches during migration from Jest.** [community]
    Vitest 4.1 added sinon-chai-style assertions (`expect(spy).to.have.been.called`, `expect(spy).to.have.callCount(2)`) as an alternative to Jest-style assertions (`expect(spy).toHaveBeenCalled()`). Both styles operate on the same underlying mock state — there is no isolation difference between them. The migration gotcha: teams that copy-paste assertion libraries or test helpers from a Sinon/Chai codebase into Vitest may mix styles within the same test file. This is syntactically valid but creates maintenance confusion because the two styles are not aliases of each other in terms of TypeScript autocomplete — `to.have.been.called` is a property chain (no parentheses on `called`), while `toHaveBeenCalled()` requires parentheses. Mismatching produces runtime errors that look like assertion failures:
    ```typescript
    // WRONG — forgetting that Chai style is property access, not a function call
    expect(spy).to.have.been.called();  // TypeError: called() is not a function in sinon-chai

    // CORRECT — Chai style: property access
    expect(spy).to.have.been.called;

    // CORRECT — Jest style: method call
    expect(spy).toHaveBeenCalled();
    ```
    Team decision: pick one assertion style per project and enforce it via ESLint rules (`eslint-plugin-vitest` supports `prefer-to-have-been-called-with` to standardize). WHY: mixing assertion styles in the same test file makes code review harder — reviewers must mentally parse two syntaxes to verify that assertions are correct. Since both styles test the same mock state, the only benefit to standardizing is readability and linting uniformity.

---

## Extended Patterns — Iteration 18

### Pattern 31: `vi.mock(import(...))` type-safe module promise syntax (TypeScript, Vitest 4.1+)  [community]

The module promise syntax for `vi.mock()` makes mock factories type-checked by TypeScript — the factory must return an object structurally compatible with the real module's exports. Unlike the string-path variant, it uses `importOriginal()` to safely mix real and mocked exports without needing explicit type assertions.

```typescript
// emailService.ts
export interface EmailPayload {
  to: string;
  subject: string;
  body: string;
}

export async function send(payload: EmailPayload): Promise<void> {
  // real SMTP call
}

export function getTransportName(): string {
  return 'smtp';
}

// userRegistration.test.ts — type-safe vi.mock with module promise syntax
import { describe, it, expect, vi, beforeEach } from 'vitest';

// Module promise syntax: TypeScript infers return type from emailService's actual exports
// Factory must return the correct shape — compile error if send or getTransportName are missing or wrong type
vi.mock(import('./emailService'), async (importOriginal) => {
  const actual = await importOriginal(); // real exports — preserves getTransportName() unchanged
  return {
    ...actual,                                  // keep real exports that we don't need to stub
    send: vi.fn<typeof actual.send>().mockResolvedValue(undefined), // only stub what we need
  };
});

// Import AFTER vi.mock — gets the mocked module
import { send } from './emailService';
import { registerUser } from './userRegistration';

describe('registerUser (vi.mock module promise)', () => {
  beforeEach(() => {
    // clear call history between tests; the mock stub itself persists (declared at file scope)
    vi.mocked(send).mockClear();
  });

  it('sends a welcome email after registering a user', async () => {
    await registerUser({ name: 'Alice', email: 'alice@example.com' });

    // TypeScript knows send is vi.Mock<typeof actual.send> — assertion is type-checked
    expect(send).toHaveBeenCalledWith({
      to: 'alice@example.com',
      subject: 'Welcome!',
      body: expect.stringContaining('Alice'),
    });
  });

  it('does not send email when registration validation fails', async () => {
    await expect(
      registerUser({ name: '', email: 'not-an-email' }), // invalid input
    ).rejects.toThrow(/validation/i);

    expect(send).not.toHaveBeenCalled();
  });
});
```

**Key advantages over string-path `vi.mock('./emailService', () => ({ ... }))`:**
- TypeScript enforces the factory's return type against the real module's exports
- `importOriginal()` lets you selectively stub only the exports you need — the rest are real
- If `emailService` gains a new required export, TypeScript reports a compile error at the factory, not a silent runtime failure
- Path aliases are resolved the same way as regular imports — no need to manually convert `@/services/email` to relative paths in the mock path string

**When to prefer string-path mock:** Only when the factory must execute before the module is available to TypeScript (e.g., in a test helper's `setupFile` where the module does not yet exist). In all other cases, the module promise syntax is strictly safer.

---

## Quick Reference Additions — Iteration 18

| Problem | Symptom | Vitest 4.1+ Solution | Jest equivalent |
|---------|---------|---------------------|-----------------|
| Mock factory type drift from real module | Mock compiles but has wrong shape; runtime error | `vi.mock(import('./module'), async (importOriginal) => { ... })` — factory return type is enforced by TypeScript | No equivalent; use `jest.Mocked<T>` for partial type safety |
| Multiple `onCleanup` calls in one fixture | Second resource leaks silently — only last cleanup runs | Combine into single `onCleanup(async () => { cleanup1(); cleanup2(); })` | N/A (Jest beforeEach/afterEach pairs handle multiple resources independently) |
| `vi.resetModules()` still returns mocked module | Re-imported module is real (re-evaluated) but still mocked; test sees stubbed behavior | Call `vi.unmock('./module')` alongside `vi.resetModules()`, or use `using _m = vi.doMock(...)` | `jest.resetModules()` + `jest.unmock('./module')` — same two-step requirement |
| Work data in constructor blocks per-test input variation | Each test requires a new constructed object in `beforeEach` | Refactor to "Construct with Collaborators, Call with Work" — constructor for services, method args for data | Same pattern; applies universally |
| Mixed Chai and Jest assertion styles in one file | Runtime `TypeError: called() is not a function` or linting inconsistency | Standardize on one style; enforce with `eslint-plugin-vitest` rule | Jest-style only in Jest projects |

---

## Key Resources — Iteration 18 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest API — `vi.mock` with module promise | Official | https://vitest.dev/api/vi#vi-mock | Module promise syntax: `vi.mock(import('./path'), factory)` for type-safe mock factories |
| Vitest Guide — `onCleanup` (single call constraint) | Official | https://vitest.dev/guide/test-context | Documents the `onCleanup` single-registration constraint; combine multiple teardowns into one call |
| Vitest API — `vi.resetModules` + `vi.unmock` distinction | Official | https://vitest.dev/api/vi#vi-resetmodules | `resetModules` clears load cache only; mock registry is separate — `vi.unmock()` needed for full reset |
| Google Testing Blog — Construct with Collaborators, Call with Work | Community | https://testing.googleblog.com/ | May 2026 TotT: DI principle — collaborators at constructor, work data at call time; enables single-instance multi-test pattern |
| Vitest API — Chai-style mock assertions | Official | https://vitest.dev/api/expect#to-have-been-called | `.to.have.been.called` property chain (sinon-chai style); no parentheses on `called` — distinct from `toHaveBeenCalled()` |
