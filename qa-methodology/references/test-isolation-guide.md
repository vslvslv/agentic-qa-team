# Test Isolation — QA Methodology Guide
<!-- lang: TypeScript | topic: test-isolation | iteration: 27 | score: 100/100 | date: 2026-05-12 -->
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
<!--          Iteration 19 (2026-05-12): Jest 30.3 jest.setTimerTickMode (object param, 3 modes:    -->
<!--            manual/nextAsync/interval; Jest uses {mode:'nextAsync'} vs Vitest's 'nextTimerAsync')-->
<!--            Jest 30.4 Temporal API fake timer support (Temporal.Instant/ZonedDateTime in         -->
<!--            setSystemTime + useFakeTimers({now}); Temporal.Now.* faked; Temporal.Now.timeZoneId -->
<!--            NOT faked); Jest 30.4 clearMocksOnScope(scope) on ModuleMocker; Vitest 5.0-beta      -->
<!--            deprecates test.sequential in favour of concurrent: false (Pattern 16 updated)       -->
<!--          Iteration 20 (2026-05-12): Jest 30 expect.arrayOf()/not.arrayOf() asymmetric matcher  -->
<!--            for type-uniform array assertions on mock return values (Pattern 34); Jest 30.4      -->
<!--            clearMocksOnScope(scope) on ModuleMocker for subsystem-scoped mock clearing          -->
<!--            (Gotcha 84); workerGracefulExitTimeout to prevent false-positive open-handle         -->
<!--            warnings from slow I/O teardown (Gotcha 85); Vitest 5.0-beta.2 confirms full        -->
<!--            removal of test.sequential + @vitest/expect inlined into vitest core (Gotcha 86);    -->
<!--            Jest 30.4 Temporal.Duration support in advanceTimersByTime() (Gotcha 87, Pattern 33  -->
<!--            extended) — self-documenting duration args, no millisecond arithmetic                -->
<!--          Iteration 21 (2026-05-12): Jest 30 SERIALIZABLE_PROPERTIES (jest-matcher-utils) for   -->
<!--            snapshot-safe custom class instances — controls which fields appear in error diffs   -->
<!--            and inline snapshots (Pattern 35, Gotcha 88); Jest 30 toEqual non-enumerable field   -->
<!--            exclusion breaking change — class instances / Proxy objects lose non-enumerable      -->
<!--            fields from equality assertions (Gotcha 89); Jest 30 defineConfig/mergeConfig        -->
<!--            helpers — type-safe config composition replacing `Config` import pattern (Pattern 8  -->
<!--            addendum); Jest 30.4 synchronous ESM evaluation on Node 24.9+ removes async         -->
<!--            isolateModulesAsync workaround for top-level-await-free ESM (Gotcha 90);             -->
<!--            Vitest 5.0 vi.spyOn private method types — TypeScript no longer requires casting to  -->
<!--            `any` to spy on #private fields (Gotcha 91)                                          -->
<!--          Iteration 22 (2026-05-12): Node.js `node:test` TestContext.mock auto-restore           -->
<!--            (Pattern 36, Gotcha 92); node:test `mock.module()` ESM module isolation without       -->
<!--            Jest (Gotcha 93); Node.js v24 AsyncLocalStorage AsyncContextFrame default —            -->
<!--            reliable per-test context propagation across setImmediate/nextTick (Gotcha 94);        -->
<!--            Playwright v1.59 `browserContext.setStorageState()` for zero-overhead in-test user     -->
<!--            switching (Pattern 37, Gotcha 95); Playwright v1.51 `storageState({ indexedDB: true })-->
<!--            for Firebase/Supabase IndexedDB-based auth token capture (Gotcha 96)                   -->
<!--          Iteration 23 (2026-05-12): Playwright v1.48 `page.routeWebSocket()` for WebSocket        -->
<!--            connection isolation — intercept/mock WS messages without a real server (Pattern 38,   -->
<!--            Gotcha 97); Playwright `mergeTests()`/`mergeExpects()` for compositional fixture        -->
<!--            isolation — combine DB + a11y + auth fixtures without coupling (Pattern 39, Gotcha 98);-->
<!--            Playwright v1.60 `test.abort()` for fail-fast from route handlers and fixtures —       -->
<!--            prevents test contamination when invariants are violated mid-test (Gotcha 99);          -->
<!--            Playwright v1.60 `tracing.startHar()` with `await using` disposable for scoped         -->
<!--            network recording without manual stopHar() teardown (Gotcha 100)                        -->
<!--          Iteration 24 (2026-05-12): Vitest 3.2 `test.signal` (AbortSignal) for cancelling        -->
<!--            in-flight async resources on timeout/bail/Ctrl-C without afterEach cleanup             -->
<!--            (Pattern 40, Gotcha 101); Playwright v1.59 `page.clearConsoleMessages()` /            -->
<!--            `page.clearPageErrors()` for intra-test diagnostic isolation in multi-phase            -->
<!--            workflows — prevent cross-phase console/error contamination (Pattern 41, Gotcha 102)   -->
<!--          Iteration 25 (2026-05-12): Node.js 24 `AsyncLocalStorage` `defaultValue` option for    -->
<!--            zero-undefined per-test context stores — eliminates non-null casts in TypeScript        -->
<!--            test utilities (Pattern 42, Gotcha 103); Vitest `aroundEach` + `AsyncLocalStorage.run` -->
<!--            composition for scoped per-test context propagation — extends Pattern 24's DB rollback  -->
<!--            to arbitrary context (Pattern 43); Node.js 24 `node:test` automatic subtest completion  -->
<!--            changes isolation timing — subtests awaited automatically but resources allocated       -->
<!--            inside them may outlive parent cleanup scope (Gotcha 104); Node.js 24                   -->
<!--            `--test-global-setup` runs in the same process as tests unlike Jest's subprocess model  -->
<!--            — singletons and module-level state from globalSetup are shared with all tests          -->
<!--            and cannot be cleared between tests (Gotcha 105)                                        -->

<!--          Iteration 26 (2026-05-12): Testcontainers PostgreSqlContainer per-suite lifecycle     -->
<!--            with Jest globalSetup/globalTeardown — hermetic Docker isolation (Pattern 44);        -->
<!--            MSW v2 `http.*` handler isolation with `server.resetHandlers()` in afterEach —        -->
<!--            `{ once: true }` does not auto-remove handler entry from stack (Pattern 45, Gotcha 106);-->
<!--            Jest `projects` for monorepo module-registry isolation — root setupFilesAfterFramework -->
<!--            runs in every project worker including jsdom (Pattern 46, Gotcha 107); EventEmitter    -->
<!--            listener leak detection via `listenerCount` assertion + captured ref in describe scope -->
<!--            (Pattern 47, Gotcha 108); Testcontainers teardown resilience against OOM crash        -->
<!--            (Gotcha 105)                                                                           -->

<!--          Iteration 27 (2026-05-12): ioredis-mock in-memory Redis isolation — jest.mock/          -->
<!--            moduleNameMapper swap + flushall vs port-based instance isolation (Pattern 48,         -->
<!--            Gotcha 109); memfs virtual filesystem via jest.mock('node:fs') — vol.fromJSON          -->
<!--            seeding, vol.reset() teardown, TypeScript path-alias caveat (Pattern 49, Gotcha 110);  -->
<!--            crypto.randomUUID / global.crypto isolation — jest.spyOn(globalThis.crypto) vs         -->
<!--            manual globalThis.crypto replacement + Vitest vi.stubGlobal pattern,                   -->
<!--            worker_threads workerData isolation for unit-testing Worker-spawning code               -->
<!--            (Pattern 50, Gotcha 111)                                                                -->

---

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

### Pattern 16: Vitest `test.sequential` / `concurrent: false` for enforcing order within a concurrent suite  [community]

**Note (Vitest 5.0):** `test.sequential` is deprecated in Vitest 5.0-beta in favour of the `concurrent: false` option.
Use `test('name', { concurrent: false }, () => { ... })` or the chained form `test.concurrent(false)('name', ...)` in
new code. For existing suites, `test.sequential` still works in Vitest 4.x. See migration note below the example.

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

**Vitest 5.0 migration:** Replace `test.sequential('name', fn)` with `test('name', { concurrent: false }, fn)`.
The `{ concurrent: false }` option is the idiomatic way to opt specific tests out of inherited concurrency.
It works inside both `describe.concurrent` and globally-concurrent suites. The deprecation aligns Vitest's
API surface with the `concurrent: true` option already available on individual tests — removing the asymmetric
`sequential` naming in favour of a single boolean dimension.

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

---

## Community Lessons — Iteration 19  [community]

80. **Jest 30.3 `jest.setTimerTickMode()` uses an object parameter with a `mode` key — distinct from Vitest's string argument.** [community]
    Jest 30.3 adds `jest.setTimerTickMode(config)` as a companion to Vitest's `vi.setTimerTickMode()`.
    The two APIs serve the same purpose — controlling how fake timers advance — but have different
    parameter shapes. Vitest accepts a **string** (`'manual'`, `'nextTimerAsync'`, `'interval'`);
    Jest accepts an **object** (`{mode: 'manual'}`, `{mode: 'nextAsync'}`, `{mode: 'interval', delta?: number}`).
    A critical naming difference: Jest's auto-advance-between-awaits mode is `'nextAsync'` (not `'nextTimerAsync'`
    as in Vitest). Teams sharing test-helper code across both frameworks must branch on the framework when
    calling this API.
    ```typescript
    // Jest 30.3+ — object parameter; mode name differs from Vitest
    jest.useFakeTimers();
    jest.setTimerTickMode({mode: 'nextAsync'});    // auto-advances between awaits (Jest)
    // vs Vitest: vi.setTimerTickMode('nextTimerAsync');
    jest.setTimerTickMode({mode: 'manual'});       // manual control (both frameworks)
    jest.setTimerTickMode({mode: 'interval', delta: 50}); // auto at 50ms intervals (Jest)
    // Note: requires modern fake timers — NOT compatible with {legacyFakeTimers: true}
    ```
    WHY: adopting `{mode: 'nextAsync'}` in Jest test suites eliminates the same problem as
    Vitest's `nextTimerAsync` mode — the need to manually call `jest.advanceTimersByTime()` between
    every `await` in async retry/backoff tests. Without it, awaited Promises can never resolve because
    the timer that unblocks them was never fired. After upgrading to Jest 30.3, teams should audit
    timer-heavy async tests and replace chains of `jest.advanceTimersByTime()` calls with a single
    `setTimerTickMode({mode: 'nextAsync'})` in `beforeEach`.

81. **Jest 30.4 fake timers now support the TC39 Temporal API — `Temporal.Instant`, `Temporal.ZonedDateTime`, and `Temporal.Now.*` are all fakeable.** [community]
    Jest 30.4 extends its fake timer system to handle the `Temporal` global (Node.js v26+, TC39 Stage 3+).
    Three isolation-relevant changes:
    - `jest.setSystemTime()` and `useFakeTimers({now})` accept `Temporal.Instant` and `Temporal.ZonedDateTime`
      in addition to `number` and `Date`. This means tests can anchor the fake clock to a precise timezone-aware
      instant without converting to a Unix timestamp.
    - `Temporal.Now.instant()`, `Temporal.Now.zonedDateTimeISO()`, and `Temporal.Now.plainDateTimeISO()`
      are automatically driven by the fake clock when `jest.useFakeTimers()` is active.
    - **Exception:** `Temporal.Now.timeZoneId()` is NOT faked — it always returns the real system timezone.
      Tests that call code reading `Temporal.Now.timeZoneId()` in combination with a faked `Temporal.Now.instant()`
      may see inconsistencies.
    ```typescript
    // jest.config.ts — ensure modern fake timers (legacy mode does not support Temporal)
    // jest.useFakeTimers() automatically fakes Temporal.Now.* on Node 26+

    import { Temporal } from 'temporal-polyfill'; // or native Node 26 global

    describe('InvoiceService — Temporal clock isolation', () => {
      beforeEach(() => {
        jest.useFakeTimers();
      });

      afterEach(() => {
        jest.useRealTimers();
      });

      it('marks invoice as overdue when Temporal.Now is past the due date', () => {
        // Set fake clock to a Temporal.Instant (timezone-aware)
        const fixedInstant = Temporal.Instant.from('2026-06-01T10:00:00Z');
        jest.setSystemTime(fixedInstant); // Temporal.Now.instant() returns this

        const invoice = {
          id: 'inv-1',
          dueDate: Temporal.PlainDate.from('2026-05-31'),
        };

        // InvoiceService.isOverdue() calls Temporal.Now.plainDateISO() internally
        expect(isOverdue(invoice)).toBe(true);
      });

      it('uses ZonedDateTime for timezone-sensitive billing cutoff', () => {
        const fixedZDT = Temporal.ZonedDateTime.from({
          timeZone: 'America/New_York',
          year: 2026, month: 5, day: 31, hour: 23, minute: 59,
        });
        jest.setSystemTime(fixedZDT);

        expect(isBillingCutoffReached(fixedZDT.toInstant())).toBe(true);
      });
    });
    ```
    WHY: code that uses `Temporal` instead of `Date` for timezone-aware date logic was previously
    untestable in isolation — there was no way to freeze `Temporal.Now.*` without a custom wrapper.
    Teams that migrated from `Date` to `Temporal` for correctness had to add a `Clock` interface
    abstraction (Pattern 3) just to regain testability. Jest 30.4 makes that abstraction optional
    for unit tests by providing first-class `Temporal.Now` faking.

82. **`test.sequential` is deprecated in Vitest 5.0-beta — replace with `{ concurrent: false }` option on individual tests.** [community]
    Vitest 5.0's concurrent-first model removes the `test.sequential` shorthand. The replacement is
    the `concurrent: false` option passed in the test's options object:
    ```typescript
    // Vitest ≤ 4.x (still works in 4.1) — deprecated in 5.0
    test.sequential('name', async () => { ... });

    // Vitest 5.0+ — idiomatic replacement
    test('name', { concurrent: false }, async () => { ... });
    ```
    The `{ concurrent: false }` option has the same effect: within a `describe.concurrent` block,
    the annotated test runs sequentially after all preceding concurrent tests complete. The key
    behavioral difference: in Vitest 5.0, tests default to **concurrent execution** by default
    (unless the suite is explicitly sequential), so `{ concurrent: false }` is now an opt-out
    rather than an opt-in. WHY: renaming `sequential` to `concurrent: false` creates a single
    boolean axis (`concurrent: true | false`) rather than two separate API surfaces
    (`test.concurrent` and `test.sequential`). Teams maintaining large test suites can use a
    codemod to replace `test.sequential(` with `test(` + `{ concurrent: false }` across all files.
    The deprecation is in the beta; `test.sequential` is still available in all 4.x stable releases.

---

## Extended Patterns — Iteration 19

### Pattern 32: Jest 30.3 `jest.setTimerTickMode()` for async retry loop isolation (TypeScript)  [community]

`jest.setTimerTickMode({mode: 'nextAsync'})` is the Jest 30.3+ equivalent of Vitest's
`vi.setTimerTickMode('nextTimerAsync')`. It eliminates manual `jest.advanceTimersByTime()`
boilerplate from tests that interleave Promises and fake timers. Note the parameter shape
difference: Jest uses an **object** with a `mode` key and an optional `delta`; Vitest uses a
**string**.

```typescript
import { describe, it, expect, jest, beforeEach, afterEach } from '@jest/globals';
import { ExponentialBackoff } from './exponentialBackoff';

describe('ExponentialBackoff (Jest 30.3 nextAsync mode)', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    // Jest 30.3+ — object parameter; mode is 'nextAsync' (NOT 'nextTimerAsync')
    jest.setTimerTickMode({ mode: 'nextAsync' });
  });

  afterEach(() => {
    // Always restore real timers — setTimerTickMode state is part of the fake timer state
    jest.useRealTimers();
  });

  it('resolves on second attempt after first transient failure', async () => {
    const operation = jest.fn<() => Promise<string>>()
      .mockRejectedValueOnce(new Error('503 Unavailable'))
      .mockResolvedValue('payload');

    const backoff = new ExponentialBackoff(operation, {
      initialDelay: 1000,
      multiplier: 2,
      maxAttempts: 3,
    });

    // With mode: 'nextAsync', awaiting the result auto-advances through each retry delay
    // No manual jest.advanceTimersByTime(1000) calls needed
    const result = await backoff.run();

    expect(result).toBe('payload');
    expect(operation).toHaveBeenCalledTimes(2); // 1 fail + 1 success
  });

  it('rejects after max retries with correct attempt count', async () => {
    const operation = jest.fn<() => Promise<string>>()
      .mockRejectedValue(new Error('permanent'));

    const backoff = new ExponentialBackoff(operation, {
      initialDelay: 500,
      multiplier: 2,
      maxAttempts: 3,
    });

    await expect(backoff.run()).rejects.toThrow('permanent');
    expect(operation).toHaveBeenCalledTimes(3); // initial + 2 retries
  });

  it('interval mode: timers fire automatically at a fixed delta', async () => {
    // Switch to interval mode for a polling test — timers advance every 20ms automatically
    jest.setTimerTickMode({ mode: 'interval', delta: 20 });

    const callback = jest.fn();
    const notifier = new PollingNotifier(callback, 100); // fires every 100ms
    notifier.start();

    // Advance time long enough for 3 polls to fire (3 × 100ms)
    await jest.advanceTimersByTimeAsync(310);

    expect(callback).toHaveBeenCalledTimes(3);
    notifier.stop();
  });
});
```

**Framework comparison table:**

| Feature | Jest 30.3+ | Vitest 4.1+ |
|---------|-----------|-------------|
| API | `jest.setTimerTickMode({mode: 'nextAsync'})` | `vi.setTimerTickMode('nextTimerAsync')` |
| Auto-advance mode name | `'nextAsync'` | `'nextTimerAsync'` |
| Manual mode | `{mode: 'manual'}` | `'manual'` |
| Interval mode | `{mode: 'interval', delta?: number}` | `'interval'` (no delta parameter) |
| Parameter type | **object** | **string** |
| Reset requirement | `jest.useRealTimers()` in `afterEach` | `vi.useRealTimers()` in `afterEach` |

**Key rule:** Always call `jest.useRealTimers()` in `afterEach` when using `setTimerTickMode`. The timer tick mode is part of the fake timer state and is **not** reset by `clearMocks: true` in jest config.

### Pattern 33: Jest 30.4 Temporal API fake clock for timezone-aware test isolation (TypeScript)  [community]

When TypeScript code uses the TC39 `Temporal` API (Node.js v26+) instead of `Date` for timezone-aware
date logic, Jest 30.4's extended `jest.useFakeTimers()` + `jest.setSystemTime()` supports
`Temporal.Instant` and `Temporal.ZonedDateTime` directly. `Temporal.Now.instant()`,
`Temporal.Now.zonedDateTimeISO()`, and `Temporal.Now.plainDateTimeISO()` are automatically driven
by the fake clock — no `Clock` interface abstraction needed for unit tests.

```typescript
// billingCutoff.ts — uses Temporal for timezone-correct billing logic
import { Temporal } from 'temporal-polyfill'; // or native Node.js v26 global

export function isBillingWindowOpen(timezone: string): boolean {
  // Business rule: billing window is Mon–Fri 08:00–18:00 in the given timezone
  const now = Temporal.Now.zonedDateTimeISO(timezone);
  const hour = now.hour;
  const dayOfWeek = now.dayOfWeek; // 1=Mon, 7=Sun (ISO 8601)
  return dayOfWeek >= 1 && dayOfWeek <= 5 && hour >= 8 && hour < 18;
}

// billingCutoff.test.ts — Jest 30.4 Temporal fake timer isolation
import type { Config } from 'jest';
// jest.config.ts: { preset: 'ts-jest', testEnvironment: 'node' } — no legacyFakeTimers

describe('isBillingWindowOpen — Temporal fake clock', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    // Requires Node.js v26+ or temporal-polyfill; modern fake timers mode only
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('returns true at 10:00 AM Wednesday in New York', () => {
    // ZonedDateTime gives precise timezone-aware control over the fake clock
    const fixedZDT = Temporal.ZonedDateTime.from(
      '2026-06-03T10:00:00[America/New_York]'
    );
    jest.setSystemTime(fixedZDT); // Temporal.Now.* driven by this value

    expect(isBillingWindowOpen('America/New_York')).toBe(true);
  });

  it('returns false at 07:59 AM (just before window opens)', () => {
    const fixedZDT = Temporal.ZonedDateTime.from(
      '2026-06-03T07:59:00[America/New_York]'
    );
    jest.setSystemTime(fixedZDT);

    expect(isBillingWindowOpen('America/New_York')).toBe(false);
  });

  it('returns false on Saturday regardless of hour', () => {
    // Saturday June 6 2026
    const fixedZDT = Temporal.ZonedDateTime.from(
      '2026-06-06T12:00:00[America/New_York]'
    );
    jest.setSystemTime(fixedZDT);

    expect(isBillingWindowOpen('America/New_York')).toBe(false);
  });

  it('useFakeTimers({now}) also accepts Temporal.Instant directly', () => {
    const instant = Temporal.Instant.from('2026-06-03T17:59:00Z');
    // Pass Temporal.Instant in the initial useFakeTimers config
    jest.useFakeTimers({ now: instant });

    // Temporal.Now.instant() returns the faked value
    const faked = Temporal.Now.instant();
    expect(faked.epochMilliseconds).toBe(instant.epochMilliseconds);
  });
});
```

**What IS and IS NOT faked:**

| Temporal API | Faked by Jest 30.4? |
|-------------|---------------------|
| `Temporal.Now.instant()` | Yes |
| `Temporal.Now.zonedDateTimeISO()` | Yes |
| `Temporal.Now.plainDateTimeISO()` | Yes |
| `Temporal.Now.plainDateISO()` | Yes |
| `Temporal.Now.plainTimeISO()` | Yes |
| `Temporal.Now.timeZoneId()` | **No** — always returns real system timezone |

**Isolation gotcha:** If production code uses `Temporal.Now.timeZoneId()` to get the timezone and
then passes it to `Temporal.Now.zonedDateTimeISO()`, the timezone will be real while the datetime
is faked — the combination is still deterministic as long as you pin the `ZonedDateTime` to the
correct timezone in `jest.setSystemTime()`. To bypass the gap, use the explicit `timezone` form:
`Temporal.Now.zonedDateTimeISO('America/New_York')` (ignores `timeZoneId`) rather than
`Temporal.Now.zonedDateTimeISO()` (which would use the real system timezone as the calendar).

---

## Quick Reference Additions — Iteration 19

| Problem | Symptom | Jest 30.3+ Solution | Vitest equivalent |
|---------|---------|---------------------|-----------------|
| Manual `advanceTimersByTime` between every `await` in Jest | Test has 10+ `jest.advanceTimersByTime()` calls | `jest.setTimerTickMode({mode: 'nextAsync'})` | `vi.setTimerTickMode('nextTimerAsync')` |
| Temporal.Now non-determinism in tests | Tests fail based on real system time (timezone/DST) | `jest.useFakeTimers()` + `jest.setSystemTime(Temporal.ZonedDateTime.from(...))` | `vi.useFakeTimers()` + `vi.setSystemTime(Temporal.ZonedDateTime.from(...))` |
| `test.sequential` compile warning after Vitest 5 upgrade | Deprecated API warning; will be removed in stable 5.0 | N/A | Replace `test.sequential('name', fn)` with `test('name', { concurrent: false }, fn)` |
| `Temporal.Now.timeZoneId()` returns real timezone despite fake clock | Tests pass locally (correct tz) but fail in CI (UTC) | Use explicit timezone arg: `Temporal.Now.zonedDateTimeISO('America/New_York')` | Same |

---

## Key Resources — Iteration 19 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Jest 30.3 Release Notes — `setTimerTickMode` | Official | https://github.com/jestjs/jest/releases/tag/v30.3.0 | Adds `setTimerTickMode({mode: 'manual'|'nextAsync'|'interval'})` — object param, 'nextAsync' not 'nextTimerAsync' |
| Jest 30.4 Release Notes — Temporal API | Official | https://github.com/jestjs/jest/releases/tag/v30.4.0 | Temporal.Instant/ZonedDateTime in `setSystemTime`; `Temporal.Now.*` faked; `timeZoneId` not faked |
| Jest Docs — `jest.setTimerTickMode` | Official | https://jestjs.io/docs/jest-object#jestsettimertickmodemode | Full parameter reference: mode types, delta for interval mode, compatibility requirements |
| Vitest 5.0-beta — `test.sequential` deprecation | Official | https://vitest.dev/api/#test-sequential | `concurrent: false` option replaces `test.sequential`; Vitest 5 concurrent-first model |
| TC39 Temporal Proposal | Standard | https://tc39.es/proposal-temporal/ | Authoritative reference for `Temporal.Now.*`, `Temporal.Instant`, `Temporal.ZonedDateTime` APIs |

---

## Community Lessons — Iteration 20  [community]

83. **`expect.arrayOf()` / `expect.not.arrayOf()` in Jest 30 enables type-uniform array assertions without manual `.every()` checks.** [community]
    Jest 30 introduces `expect.arrayOf(matcher)` as an asymmetric matcher that passes only when every element of the received array matches the given matcher (or value). This closes a common isolation gotcha: assertions on arrays returned from stubs previously required either `toHaveLength(N)` + per-element checks or a custom `expect.extend` matcher, both of which are fragile when the array grows. `expect.arrayOf` makes the assertion declarative and composable with other asymmetric matchers.
    ```typescript
    import { describe, it, expect, jest, beforeEach } from '@jest/globals';
    import { ReportService } from './reportService';
    import type { Report } from './types';

    describe('ReportService.listReports()', () => {
      let service: ReportService;

      beforeEach(() => {
        // Fresh instance — no accumulated call or return state from previous test
        service = new ReportService();
      });

      it('returns an array of report objects with required fields', async () => {
        const reports = await service.listReports();

        // expect.arrayOf — every element must match objectContaining
        // More robust than checking reports[0], reports[1] individually
        expect(reports).toEqual(
          expect.arrayOf(
            expect.objectContaining({
              id: expect.any(String),
              createdAt: expect.any(String),
              status: expect.stringMatching(/^(pending|complete|failed)$/),
            }),
          ),
        );
      });

      it('returns an empty array (not null/undefined) when no reports exist', async () => {
        jest.spyOn(service as any, 'fetchFromDB').mockResolvedValue([]);

        const reports = await service.listReports();

        // expect.arrayOf on an empty array always passes — verifies the type contract is upheld
        expect(reports).toEqual(expect.arrayOf(expect.any(Object)));
        expect(reports).toHaveLength(0);
      });

      it('expect.not.arrayOf detects a mixed-type array from a faulty stub', () => {
        // Useful in test helpers to assert that a stub is NOT returning the wrong shape
        const mixedArray = ['string', 42, { id: 'x' }];

        // every element is NOT a number — expect.not.arrayOf(Number) would pass
        expect(mixedArray).toEqual(expect.not.arrayOf(expect.any(Number)));
      });
    });
    ```
    **Isolation relevance:** Mock stubs that return array data (e.g., `mockResolvedValue([report1, report2])`) can silently drift from the real service's return type. Using `expect.arrayOf(expect.objectContaining({ ... }))` in the assertion phase catches shape drift at the assertion level — not just at the mock type level. Pair with `jest.Mocked<T>` on the mock type (Pattern 9) for compile-time + runtime coverage. WHY: the alternative — asserting each array element individually — is brittle and grows with test data. `expect.arrayOf` scales linearly and is automatically composable with `objectContaining`, `stringMatching`, etc.

84. **`jest.clearMocksOnScope(scope)` on `ModuleMocker` clears all mock functions exposed on a single scope object — useful for targeted cleanup in test helpers that register mocks on a shared context.** [community]
    Jest 30.4 adds `clearMocksOnScope(scope)` to `ModuleMocker`. Unlike `jest.clearAllMocks()` (which clears every mock in the entire test environment), `clearMocksOnScope` limits the clear operation to the mock functions hanging off a specific scope object. This enables test helpers or custom test runners that manage a subset of mocks on a dedicated context object — clearing only those mocks between tests without affecting mocks registered elsewhere.
    ```typescript
    import { ModuleMocker } from 'jest-mock';

    // A custom test context that collects module-level mocks for a single subsystem
    interface AnalyticsMockScope {
      track: jest.Mock;
      identify: jest.Mock;
      flush: jest.Mock;
    }

    describe('AnalyticsScope isolated mock cleanup (jest.clearMocksOnScope)', () => {
      let mocker: ModuleMocker;
      let analyticsScope: AnalyticsMockScope;

      beforeAll(() => {
        mocker = new ModuleMocker(global);
      });

      beforeEach(() => {
        // Mocks are created once and reused; call state is cleared per test by clearMocksOnScope
        analyticsScope = {
          track: jest.fn(),
          identify: jest.fn(),
          flush: jest.fn(),
        };
      });

      afterEach(() => {
        // Only clears mocks on analyticsScope — does not touch unrelated mocks in the same file
        mocker.clearMocksOnScope(analyticsScope);
      });

      it('track is called once during registration flow', () => {
        analyticsScope.track('page_view', { page: '/home' });
        analyticsScope.identify('user-1');

        expect(analyticsScope.track).toHaveBeenCalledTimes(1);
        expect(analyticsScope.identify).toHaveBeenCalledTimes(1);
        // After this test, clearMocksOnScope wipes call history on analyticsScope only
      });

      it('track and identify start fresh — previous test call counts are cleared', () => {
        // analyticsScope.track.mock.calls is empty — clearMocksOnScope ran in afterEach
        expect(analyticsScope.track).not.toHaveBeenCalled();
        expect(analyticsScope.identify).not.toHaveBeenCalled();
      });
    });
    ```
    **When to use over `jest.clearAllMocks()`:** Use `clearMocksOnScope` when your test setup creates a mock scope object for a subsystem (e.g., a `db`, `analytics`, or `mailer` context) and you need to reset only that subsystem's mocks between tests. The boundary ensures that mocks owned by other subsystems (set up in different `beforeEach` blocks or test utility files) are not inadvertently cleared. WHY: `jest.clearAllMocks()` is a sledgehammer — it clears every jest.fn() in the environment, which can break tests that rely on accumulated call state set up in a shared `beforeAll`.

85. **`workerGracefulExitTimeout` prevents false-positive "open handles" warnings that mask real isolation failures.** [community]
    Jest 30.4 added `workerGracefulExitTimeout` to control how long Jest waits for a worker process to exit gracefully (default: 500ms) before force-killing it. When workers hold resources that legitimately take longer than 500ms to release (e.g., a database connection pool shutdown, a Redis client `quit()` call that awaits pending commands), Jest prematurely force-kills the worker and reports spurious "open handles" warnings (`--detectOpenHandles`). These false positives are dangerous: they disguise real isolation failures (tests that genuinely leaked open handles) as noise, causing teams to disable `--detectOpenHandles` in CI — which then hides actual leaks.
    ```typescript
    // jest.config.ts — raise graceful exit timeout for suites with real I/O teardown
    import type { Config } from 'jest';

    const config: Config = {
      // Allow up to 3 seconds for workers to release database/Redis/HTTP connections
      // in afterAll hooks before force-kill. Default 500ms causes false-positive
      // "open handles" warnings when teardown involves real I/O.
      workerGracefulExitTimeout: 3000,

      // Combine with detectOpenHandles so real leaks still surface as errors
      // (workers that don't exit within 3s are genuine leaks, not slow teardown)
      // Run with: jest --detectOpenHandles
      testEnvironment: 'node',
      preset: 'ts-jest',
      clearMocks: true,
      restoreMocks: true,
    };

    export default config;
    ```
    **Diagnostic workflow:** Set `workerGracefulExitTimeout` to a value longer than your slowest `afterAll` teardown (measure with `--verbose`). If `--detectOpenHandles` still reports handles after raising the timeout, those are real leaks — not slow teardown. If raising the timeout silences the warning, the teardown was legitimate but slower than the default. WHY: the 500ms default was set when Jest workers rarely held long-lived connections; modern TypeScript backends commonly use database connection pools and Redis clients whose graceful shutdown takes 1-2 seconds. The mismatch produces noisy false positives that train teams to ignore legitimate open handle warnings.

86. **Vitest 5.0 removes the `sequential` option entirely (confirmed in beta.2) — `concurrent: false` is the only remaining opt-out from concurrency.** [community]
    The guide's Pattern 16 and Gotcha 82 documented `test.sequential` as deprecated in Vitest 5.0-beta. Vitest 5.0-beta.2 confirms the removal is complete — the `sequential` property on `TestOptions` and the `test.sequential` shorthand are no longer available. The `suite.sequential` flag on `describe` is also removed. Migration guide:
    ```typescript
    // Remove these patterns from all test files before upgrading to Vitest 5.0 stable:

    // OLD — removed in Vitest 5.0
    test.sequential('must run after the previous test', async () => { ... });
    describe.sequential('all tests in this block run sequentially', () => { ... });

    // NEW — idiomatic Vitest 5.0 replacements
    test('must run after the previous test', { concurrent: false }, async () => { ... });
    // For a whole describe block, pass the option to describe:
    describe('all tests in this block run sequentially', { concurrent: false }, () => { ... });
    ```
    **Additional 5.0 breaking change — `expect` inlined into Vitest core:** Vitest 5.0 inlines the `expect` package directly into `vitest/core`, removing the `@vitest/expect` re-export entry point. Projects that import `expect` from `@vitest/expect` (e.g., custom assertion libraries or Vitest plugins that extend `expect` outside of test files) must update their import:
    ```typescript
    // OLD — fails in Vitest 5.0
    import { expect } from '@vitest/expect';

    // NEW
    import { expect } from 'vitest';
    ```
    WHY: the `sequential` removal completes the concurrent-first model refactor. Keeping `sequential` alongside `concurrent` created an asymmetric API surface where opting out of the default (concurrent) required a different word than opting in. `concurrent: true | false` on both test and describe creates a single boolean dimension — consistent and lint-friendly (ESLint rules can now use `prefer-concurrent: false` over `test.sequential`).

87. **Jest 30.4 `Temporal.Duration` support in timer advancement methods — use `Temporal.Duration` instead of millisecond magic numbers for timer-advancing tests.** [community]
    Pattern 33 (Gotcha 81) covers `Temporal.ZonedDateTime` / `Temporal.Instant` in `jest.setSystemTime()`. A complementary addition in Jest 30.4: `jest.advanceTimersByTime()` and related advancement APIs now accept `Temporal.Duration` objects directly. This eliminates magic millisecond constants in timer tests — a common readability issue that can hide incorrect duration values.
    ```typescript
    import { Temporal } from 'temporal-polyfill'; // or native Node.js v26 global

    describe('SubscriptionRenewalJob — Temporal.Duration timer isolation (Jest 30.4+)', () => {
      beforeEach(() => {
        jest.useFakeTimers();
      });

      afterEach(() => {
        jest.useRealTimers();
      });

      it('does not renew subscription before 30 days have elapsed', () => {
        const onRenew = jest.fn();
        const job = new SubscriptionRenewalJob(onRenew, { periodDays: 30 });

        job.start();
        // Temporal.Duration makes the test intent self-documenting — no magic number 2592000000
        jest.advanceTimersByTime(Temporal.Duration.from({ days: 29 }));

        expect(onRenew).not.toHaveBeenCalled();
        job.stop();
      });

      it('renews subscription exactly when 30 days have elapsed', () => {
        const onRenew = jest.fn();
        const job = new SubscriptionRenewalJob(onRenew, { periodDays: 30 });

        job.start();
        jest.advanceTimersByTime(Temporal.Duration.from({ days: 30 }));

        expect(onRenew).toHaveBeenCalledTimes(1);
        job.stop();
      });

      it('advances by a mixed-unit duration without manual conversion', () => {
        const onRenew = jest.fn();
        const job = new SubscriptionRenewalJob(onRenew, { periodDays: 30 });

        job.start();
        // 30 days = 30 * 24 * 60 * 60 * 1000ms — Temporal computes this automatically
        jest.advanceTimersByTime(
          Temporal.Duration.from({ weeks: 4, days: 2 })  // 30 days total
        );

        expect(onRenew).toHaveBeenCalledTimes(1);
        job.stop();
      });
    });
    ```
    **Framework comparison:** Vitest's `vi.advanceTimersByTime()` does not yet accept `Temporal.Duration` — it still requires a numeric millisecond argument. When writing cross-framework test helpers, branch on `typeof duration === 'number'` vs `Temporal.Duration.prototype.isPrototypeOf(duration)`. WHY: millisecond magic numbers (`2592000000` for 30 days) are opaque and error-prone. A reviewer cannot instantly verify that `2592000000` equals 30 days without calculating. `Temporal.Duration.from({ days: 30 })` is self-documenting, reviewed at a glance, and immune to off-by-one errors from manual `days × 24 × 60 × 60 × 1000` arithmetic.

---

## Extended Patterns — Iteration 20

### Pattern 34: `expect.arrayOf()` for type-uniform array assertions on mock return values (TypeScript, Jest 30+)  [community]

`expect.arrayOf(matcher)` is the Jest 30 asymmetric matcher that passes when every element in the received array satisfies the given matcher. For mock stubs that return arrays, it provides a single-expression assertion that catches element-level shape drift without iterating over the array manually.

```typescript
// types.ts
export interface LineItem {
  sku: string;
  qty: number;
  unitPrice: number;
  discount?: number;
}

export interface CartSummary {
  items: LineItem[];
  subtotal: number;
  tax: number;
  total: number;
}

// cartService.test.ts
import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import type { CartRepository } from './cartRepository';
import { CartService } from './cartService';

describe('CartService.getSummary()', () => {
  let repo: jest.Mocked<CartRepository>;
  let service: CartService;

  beforeEach(() => {
    repo = {
      getItems: jest.fn().mockResolvedValue([
        { sku: 'sku-1', qty: 2, unitPrice: 15.00 },
        { sku: 'sku-2', qty: 1, unitPrice: 9.99, discount: 0.1 },
      ]),
      save: jest.fn().mockResolvedValue(undefined),
    } as jest.Mocked<CartRepository>;
    service = new CartService(repo);
  });

  it('returns a summary with correctly shaped LineItem objects', async () => {
    const summary = await service.getSummary('cart-1');

    // expect.arrayOf — every element must match the LineItem shape
    // Catches when a new required field is added to LineItem but the stub is not updated
    expect(summary.items).toEqual(
      expect.arrayOf(
        expect.objectContaining({
          sku: expect.any(String),
          qty: expect.any(Number),
          unitPrice: expect.any(Number),
        }),
      ),
    );
  });

  it('returns an empty items array (not null) when cart has no items', async () => {
    repo.getItems.mockResolvedValue([]);

    const summary = await service.getSummary('cart-empty');

    // expect.arrayOf on an empty array always passes — verifies array (not null/undefined) contract
    expect(summary.items).toEqual(expect.arrayOf(expect.any(Object)));
    expect(summary.items).toHaveLength(0);
  });

  it('all line items have non-negative quantities — business rule assertion', async () => {
    const summary = await service.getSummary('cart-1');

    // expect.arrayOf + custom matcher validates the business invariant across all items
    expect(summary.items).toEqual(
      expect.arrayOf(
        expect.objectContaining({
          qty: expect.toBeGreaterThanOrEqual(1),
        }),
      ),
    );
  });

  it('detects a faulty stub that mixes item types via expect.not.arrayOf', () => {
    // Validates that mock data is uniform — not accidentally mixed-type
    const items = [
      { sku: 'sku-1', qty: 2, unitPrice: 10 },
      'accidental-string', // wrong type — would cause a runtime error in real code
    ];

    // NOT all elements are objects — detects stub contamination
    expect(items).toEqual(expect.not.arrayOf(expect.any(Object)));
  });
});
```

**Key rule:** `expect.arrayOf(matcher)` passes on an empty array — every element of an empty array trivially satisfies any condition. If an empty array is invalid (e.g., a cart must have at least one item), assert `toHaveLength(n)` separately. The two assertions are complementary: `arrayOf` validates element shape; `toHaveLength` validates count.

---

## Quick Reference Additions — Iteration 20

| Problem | Symptom | TypeScript/Jest Solution | Vitest equivalent |
|---------|---------|--------------------------|-------------------|
| Per-element array assertions on mock return values | Verbose per-element `expect(arr[0]).toMatchObject(...)` chains | `expect(arr).toEqual(expect.arrayOf(expect.objectContaining({...})))` (Jest 30+) | No built-in `arrayOf`; use `arr.forEach(el => expect(el).toMatchObject({...}))` |
| Clear only a subset of mocks (one subsystem) without clearing all test mocks | `jest.clearAllMocks()` clears unrelated mocks and breaks other test setup | `mocker.clearMocksOnScope(scopeObj)` — clears only mocks on the scope object (Jest 30.4+, ModuleMocker) | `vi.clearAllMocks()` — no scope-limited equivalent; use `vi.clearMocks()` on individual mocks |
| Spurious "open handles" warnings masking real leaks | `--detectOpenHandles` always fires even for clean teardown; teams disable it | `workerGracefulExitTimeout: 3000` (or higher) in jest.config.ts — allows slow I/O teardown without false positives | `detectAsyncLeaks: true` in vitest.config.ts (finer-grained than Jest's approach) |
| Vitest 5.0 `test.sequential` / `describe.sequential` compile error | `Property 'sequential' does not exist on type 'TestAPI'` after upgrade | N/A (Jest uses `--runInBand` or `test.concurrent(false)` style in Jest 30) | Replace with `test('name', { concurrent: false }, fn)` and `describe('name', { concurrent: false }, fn)` |
| `@vitest/expect` import fails after Vitest 5.0 upgrade | Module not found: `@vitest/expect` | N/A | Replace `import { expect } from '@vitest/expect'` with `import { expect } from 'vitest'` |
| Magic millisecond numbers in timer tests | `jest.advanceTimersByTime(2592000000)` — reviewer cannot verify 30 days at a glance | `jest.advanceTimersByTime(Temporal.Duration.from({ days: 30 }))` (Jest 30.4+, Node 26) | Vitest does not yet accept `Temporal.Duration`; convert with `.total('milliseconds')` |

---

## Key Resources — Iteration 20 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Jest Docs — `expect.arrayOf` | Official | https://jestjs.io/docs/expect#expectarrayofvalue | New Jest 30 asymmetric matcher: every element matches — composable with `objectContaining`, `any`, etc. |
| Jest 30.4 Release Notes — `clearMocksOnScope` | Official | https://github.com/jestjs/jest/releases/tag/v30.4.0 | `ModuleMocker.clearMocksOnScope(scope)` — targeted mock clearing for subsystem scope objects |
| Jest Config — `workerGracefulExitTimeout` | Official | https://jestjs.io/docs/configuration#workergraceulexittimeout-number | Raise above 500ms default to prevent false-positive open-handle warnings from slow I/O teardown |
| Vitest 5.0-beta.2 Release Notes | Official | https://github.com/vitest-dev/vitest/releases/tag/v5.0.0-beta.2 | Confirms `sequential` option fully removed; `concurrent: false` is the only remaining opt-out; `@vitest/expect` inlined |
| Jest Docs — Temporal Duration in `advanceTimersByTime` | Official | https://jestjs.io/docs/jest-object#jestadvancetimersbytimemsecondstorun | Jest 30.4+: `Temporal.Duration` accepted directly — self-documenting duration arguments, no millisecond arithmetic |

---

## Community Lessons — Iteration 21  [community]

88. **Jest 30 `SERIALIZABLE_PROPERTIES` controls which fields appear in snapshot diffs — preventing getter errors and noisy diffs for complex class instances.** [community]
    Jest 30 introduces the `SERIALIZABLE_PROPERTIES` symbol (imported from `jest-matcher-utils`) that can be set on a class prototype to declare which property names should be included when Jest serializes the object for snapshot assertions and error messages. Without it, Jest serializes all enumerable properties — including any that are expensive getters or properties that produce non-deterministic output. Setting `SERIALIZABLE_PROPERTIES` on a domain model class is a snapshot isolation technique: it makes snapshot diffs deterministic even when the class has internal bookkeeping state that should not appear in assertions.

    ```typescript
    import { SERIALIZABLE_PROPERTIES } from 'jest-matcher-utils';

    // Domain model with internal tracking state that should not pollute snapshots
    class OrderSummary {
      constructor(
        public readonly id: string,
        public readonly items: Array<{ sku: string; qty: number; price: number }>,
        public readonly createdAt: string,
        // Internal tracking — should not appear in test diffs
        private _internalTrackingId: string = `track-${Math.random()}`,
        private _computedAt: number = Date.now(),
      ) {}

      get total(): number {
        return this.items.reduce((sum, item) => sum + item.qty * item.price, 0);
      }

      get formattedTotal(): string {
        return `$${this.total.toFixed(2)}`;
      }
    }

    // Declare which properties are "serializable" for snapshot/error output
    // Only id, items, createdAt, total — NOT _internalTrackingId, _computedAt (non-deterministic)
    OrderSummary.prototype[SERIALIZABLE_PROPERTIES] = ['id', 'items', 'createdAt', 'total'];

    // test file
    describe('OrderSummary snapshot isolation (SERIALIZABLE_PROPERTIES)', () => {
      const FIXED_DATE = '2026-05-12T10:00:00.000Z';

      it('matches snapshot with only the declared serializable properties', () => {
        const summary = new OrderSummary(
          'ord-1',
          [{ sku: 'sku-1', qty: 2, price: 15.00 }],
          FIXED_DATE,
        );

        // Snapshot only includes id, items, createdAt, total
        // _internalTrackingId and _computedAt (both non-deterministic) are excluded automatically
        expect(summary).toMatchInlineSnapshot(`
          OrderSummary {
            "createdAt": "2026-05-12T10:00:00.000Z",
            "id": "ord-1",
            "items": [
              {
                "price": 15,
                "qty": 2,
                "sku": "sku-1",
              },
            ],
            "total": 30,
          }
        `);
      });

      it('error message diff only shows declared properties — not internal noise', () => {
        const received = new OrderSummary('ord-1', [{ sku: 'sku-1', qty: 2, price: 15 }], FIXED_DATE);
        const expected = new OrderSummary('ord-1', [{ sku: 'sku-1', qty: 3, price: 15 }], FIXED_DATE);

        // The failure message shows ONLY id, items, createdAt, total — not _internalTrackingId
        // Without SERIALIZABLE_PROPERTIES, every test run shows a different _internalTrackingId in the diff
        expect(() => expect(received).toEqual(expected)).toThrow();
      });
    });
    ```

    **When to use:** Apply `SERIALIZABLE_PROPERTIES` to any class used in snapshot assertions that has: (1) non-deterministic internal state (random IDs, timestamps), (2) expensive computed getters that should not be serialized, or (3) internal bookkeeping fields irrelevant to the test's assertion. WHY: without this, every snapshot update that changes a non-deterministic internal field causes a false-positive snapshot failure that trains teams to `--updateSnapshot` without reading the diff carefully — defeating the purpose of snapshot testing as a regression guard.

89. **Jest 30 excludes non-enumerable properties from `toEqual` — existing assertions on class instances or Proxy objects may silently change behavior after upgrading.** [community]
    In Jest ≤ 29, `toEqual` performed deep equality including non-enumerable properties. Jest 30 changes this: non-enumerable properties are excluded from `toEqual` comparisons by default (aligning with the behavior of `JSON.stringify`). This is a silent breaking change for TypeScript projects where:
    - Class instances have methods or getters defined on the prototype (these are non-enumerable)
    - `Object.defineProperty` is used to create non-enumerable fields
    - Proxy objects intercept property enumeration

    ```typescript
    class Config {
      public endpoint: string;

      constructor(endpoint: string) {
        this.endpoint = endpoint;
        // Non-enumerable internal flag — was included in Jest 29 toEqual; excluded in Jest 30
        Object.defineProperty(this, '_validated', { value: true, enumerable: false });
      }
    }

    // Jest 29 behavior — toEqual included _validated (non-enumerable)
    // Both objects must have _validated === true for equality to pass
    // expect(new Config('a')).toEqual(new Config('a')); // passed OR failed depending on non-enum fields

    // Jest 30 behavior — toEqual ignores _validated
    // The assertion below passes in Jest 30 regardless of _validated's value
    expect(new Config('http://api.example.com')).toEqual(new Config('http://api.example.com')); // passes

    // Isolation implication: if test doubles were designed to match a class instance exactly
    // including non-enumerable fields, those assertions become less strict in Jest 30.
    // Tests that previously caught non-enumerable field drift now pass silently.
    // Fix: use jest.objectContaining() for precise field subset assertions,
    // or use SERIALIZABLE_PROPERTIES (Gotcha 88) to control what is compared.
    ```

    **Diagnostic:** After upgrading to Jest 30, run `jest --verbose` with `--ci` mode. If any assertions that previously failed now pass (a test that was failing before the upgrade and is now green), check whether the assertion was relying on non-enumerable property equality. WHY: the change aligns Jest's equality semantics with JavaScript's own structural equality model — but teams that relied on the old behavior for catching prototype-level state drift will need to add explicit assertions for those fields.

90. **Jest 30 `defineConfig` and `mergeConfig` helpers provide type-safe configuration — replace the `Config` import pattern.** [community]
    Pattern 8 of this guide uses `import type { Config } from 'jest'` to type the config object. Jest 30 introduces `defineConfig(config)` and `mergeConfig(base, override)` as the idiomatic type-safe alternatives. `defineConfig` validates the config object at TypeScript compile time; `mergeConfig` performs a deep merge with correct type inference — removing the common error of `Object.assign`-merging Jest configs incorrectly (e.g., overwriting `transform` arrays instead of merging them).

    ```typescript
    // jest.config.ts — Pattern 8 updated for Jest 30 (replaces `import type { Config }` pattern)
    import { defineConfig } from 'jest';

    export default defineConfig({
      // All options are type-checked — IDE autocomplete works without a separate Config import
      clearMocks: true,
      restoreMocks: true,
      preset: 'ts-jest',
      testEnvironment: 'node',
      maxWorkers: '50%',

      // Jest 30: workerGracefulExitTimeout for I/O-heavy suites (see Gotcha 85)
      workerGracefulExitTimeout: 3000,

      // Jest 30: globalsCleanup for cross-file global contamination detection (see Gotcha 34)
      testEnvironmentOptions: {
        globalsCleanup: 'on',
      },

      // Jest 30: showSeed for reproducible random order (see Gotcha 65)
      randomize: true,
      showSeed: true,
    });
    ```

    ```typescript
    // Multi-project config using mergeConfig — replaces manual Object.assign patterns
    import { defineConfig, mergeConfig } from 'jest';
    import baseConfig from './jest.config.base';

    // Integration test project — extends base config without manually merging arrays
    export default mergeConfig(
      baseConfig,
      defineConfig({
        testMatch: ['**/*.integration.test.ts'],
        maxWorkers: 1,             // sequential for DB tests
        testTimeout: 30000,        // longer timeout for I/O
        workerGracefulExitTimeout: 5000,
      }),
    );
    ```

    **Migration note:** The `Config` type import (`import type { Config } from 'jest'`) still works in Jest 30 — this is not a breaking change. `defineConfig` is additive. Teams should prefer `defineConfig` for new configs because it enables function-form configs (`defineConfig(() => ({ ... }))`) that can perform async initialization (e.g., reading env vars from a secrets manager before returning the config object).

91. **Vitest 5.0 `vi.spyOn` accepts TypeScript `#private` field names — no `as any` cast required.** [community]
    In Vitest ≤ 4.x, spying on a TypeScript class's JavaScript `#private` field required casting the instance to `any` to bypass TypeScript's type checker:
    ```typescript
    // Old pattern (Vitest ≤ 4.x) — TypeScript error without the cast
    const spy = vi.spyOn(instance as any, '#privateMethod'); // eslint-disable-line @typescript-eslint/no-explicit-any
    ```
    Vitest 5.0 updates `vi.spyOn`'s TypeScript overloads to accept `#private` field names directly on class instances that expose them via `PrivateName` union types. This removes the `as any` bypass — and with it, the risk of silently passing the wrong field name (which would compile but set up a spy on `undefined` instead of the intended method).

    ```typescript
    class PaymentProcessor {
      #retryCount = 0;

      async #attemptCharge(amount: number): Promise<boolean> {
        this.#retryCount++;
        // internal implementation
        return amount > 0;
      }

      async charge(amount: number): Promise<void> {
        const ok = await this.#attemptCharge(amount);
        if (!ok) throw new Error('Charge failed');
      }
    }

    // Vitest 5.0+ — no `as any` needed
    describe('PaymentProcessor — private method spy (Vitest 5.0+)', () => {
      it('calls #attemptCharge exactly once per charge() call', async () => {
        const processor = new PaymentProcessor();

        // TypeScript-safe spy on #private method — no cast required in Vitest 5.0
        const spy = vi.spyOn(processor, '#attemptCharge');
        spy.mockResolvedValue(true);

        await processor.charge(100);

        expect(spy).toHaveBeenCalledTimes(1);
        expect(spy).toHaveBeenCalledWith(100);
      });

      it('throws when #attemptCharge returns false', async () => {
        const processor = new PaymentProcessor();
        const spy = vi.spyOn(processor, '#attemptCharge');
        spy.mockResolvedValue(false);

        await expect(processor.charge(100)).rejects.toThrow('Charge failed');
      });
    });
    ```

    **Isolation relevance:** Spying on `#private` methods without a cast means TypeScript will error at compile time if the method name changes (e.g., `#attemptCharge` is renamed to `#tryCharge`). Previously, the `as any` cast bypassed this — the spy would be registered on `undefined` and silently do nothing, causing the test to pass while no longer exercising the intended isolation boundary. WHY: `#private` fields are part of a class's internal architecture. The ability to spy on them type-safely enables testing internal state transitions without exposing the field in the public API just to enable testability — a DI anti-pattern where classes add public accessors solely for test access.

---

## Extended Patterns — Iteration 21

### Pattern 35: `SERIALIZABLE_PROPERTIES` for deterministic snapshot diffs on domain model classes (TypeScript, Jest 30+)  [community]

When a TypeScript domain model has non-deterministic internal fields (generated IDs, timestamps, computation caches), snapshot tests that include the full object representation always produce diffs — rendering snapshots useless as regression guards. `SERIALIZABLE_PROPERTIES` from `jest-matcher-utils` pins the serialized representation to a fixed set of fields, making snapshots stable without wrapping every assertion in `expect.objectContaining(...)`.

```typescript
// order.ts — domain model with internal non-deterministic state
import { SERIALIZABLE_PROPERTIES } from 'jest-matcher-utils';

export interface OrderItem {
  sku: string;
  qty: number;
  unitPrice: number;
}

export class Order {
  public readonly id: string;
  public readonly items: OrderItem[];
  public readonly createdAt: string;

  // Internal bookkeeping — non-deterministic, must not appear in snapshots
  private readonly _internalRef: string;
  private readonly _snapshotToken: string;

  constructor(id: string, items: OrderItem[], createdAt: string) {
    this.id = id;
    this.items = items;
    this.createdAt = createdAt;
    this._internalRef = `ref-${Math.random().toString(36).slice(2)}`;
    this._snapshotToken = `snap-${Date.now()}`;
  }

  get subtotal(): number {
    return this.items.reduce((sum, item) => sum + item.qty * item.unitPrice, 0);
  }

  get itemCount(): number {
    return this.items.reduce((sum, item) => sum + item.qty, 0);
  }
}

// Declare serializable fields — ONLY these appear in snapshot diffs and error messages
// _internalRef and _snapshotToken are excluded (non-deterministic)
// subtotal and itemCount are included — derived but deterministic
Order.prototype[SERIALIZABLE_PROPERTIES] = ['id', 'items', 'createdAt', 'subtotal', 'itemCount'];

// order.test.ts
import { describe, it, expect } from '@jest/globals';
import { Order } from './order';

describe('Order snapshot stability', () => {
  const ITEMS: OrderItem[] = [
    { sku: 'sku-1', qty: 2, unitPrice: 15.00 },
    { sku: 'sku-2', qty: 1, unitPrice: 9.99 },
  ];
  const CREATED_AT = '2026-05-12T10:00:00.000Z';

  it('snapshot is stable across runs despite non-deterministic internal fields', () => {
    const order = new Order('ord-1', ITEMS, CREATED_AT);

    // Snapshot includes only the SERIALIZABLE_PROPERTIES fields — never changes between runs
    // Without SERIALIZABLE_PROPERTIES, _internalRef and _snapshotToken would appear and differ every run
    expect(order).toMatchInlineSnapshot(`
      Order {
        "createdAt": "2026-05-12T10:00:00.000Z",
        "id": "ord-1",
        "itemCount": 3,
        "items": [
          {
            "qty": 2,
            "sku": "sku-1",
            "unitPrice": 15,
          },
          {
            "qty": 1,
            "sku": "sku-2",
            "unitPrice": 9.99,
          },
        ],
        "subtotal": 39.99,
      }
    `);
  });

  it('toEqual is not affected — SERIALIZABLE_PROPERTIES only changes snapshot/error output', () => {
    const orderA = new Order('ord-1', ITEMS, CREATED_AT);
    const orderB = new Order('ord-1', ITEMS, CREATED_AT);

    // toEqual still compares enumerable properties (id, items, createdAt)
    // _internalRef and _snapshotToken are non-enumerable (private) — excluded in Jest 30 (Gotcha 89)
    // This assertion passes because both orders have the same public enumerable state
    expect(orderA).toEqual(orderB);
  });
});
```

**Comparison with alternatives:**

| Approach | When to use | Isolation tradeoff |
|----------|-------------|-------------------|
| `SERIALIZABLE_PROPERTIES` | Class instances with non-deterministic internal fields | Fields excluded from snapshot but still exist in memory |
| `expect.objectContaining({...})` | Inline, per-assertion exclusion | Verbose; must be repeated at every assertion site |
| `vi.useFakeTimers()` + `vi.setSystemTime()` | When the non-deterministic field is a timestamp | Only helps for Date/time fields; requires fake timer setup |
| Extract DTO before asserting | When you want the test to own the assertion shape | Requires a transform step; no class-level declaration |

**Key rule:** `SERIALIZABLE_PROPERTIES` only affects the Jest serializer — it changes what appears in snapshot output and `toEqual` error messages. It does NOT change what `toEqual` or `toMatchObject` actually compare. If you need to exclude a field from equality comparison, use `expect.objectContaining(...)` (which matches a subset of fields) or convert to a plain DTO before asserting.

---

## Quick Reference Additions — Iteration 21

| Problem | Symptom | TypeScript/Jest Solution | Vitest equivalent |
|---------|---------|--------------------------|-------------------|
| Non-deterministic internal fields in snapshot output | Snapshot fails on every run due to random IDs or timestamps in class instances | `SERIALIZABLE_PROPERTIES` on class prototype (jest-matcher-utils) — pin which fields appear in diffs | No built-in equivalent; use `vi.useFakeTimers()` for timestamps or extract a DTO before asserting |
| Non-enumerable property assertions break after Jest 30 upgrade | `toEqual` previously matched; now passes even when non-enumerable fields differ | Add explicit assertions for non-enumerable fields or use `Object.getOwnPropertyDescriptor` checks | `vi.toEqual` has same behavior change; same mitigation |
| Verbose `import type { Config } from 'jest'` config files | No IDE validation on unknown config keys; Object.assign merge errors | Replace with `defineConfig({...})` for single-file configs; `mergeConfig(base, defineConfig({...}))` for multi-project | `defineConfig` in `vitest/config` (already idiomatic in Vitest) |
| `as any` cast required to spy on TypeScript `#private` methods | TypeScript error on `vi.spyOn(instance, '#privateMethod')` in Vitest ≤ 4.x | N/A (Jest requires `as any` or `(instance as any)` for private fields) | Vitest 5.0+: `vi.spyOn(instance, '#privateMethod')` works without cast |

---

## Key Resources — Iteration 21 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Jest Docs — `SERIALIZABLE_PROPERTIES` | Official | https://jestjs.io/docs/expect#serializableproperties | Symbol for controlling which properties appear in snapshot diffs and error messages for custom class instances |
| Jest 30 Blog — Breaking Changes | Official | https://jestjs.io/blog/2025/06/04/jest-30 | Non-enumerable property exclusion from `toEqual`; `defineConfig`/`mergeConfig`; full breaking changes list |
| Jest API — `defineConfig` | Official | https://jestjs.io/docs/configuration#defineconfig | Type-safe Jest config helper; replaces `import type { Config }` pattern; supports function form for async config |
| Jest API — `mergeConfig` | Official | https://jestjs.io/docs/configuration#mergeconfig | Deep config merge with correct type inference; replaces `Object.assign` for multi-project config composition |
| Vitest 5.0-beta — Private method spy types | Official | https://github.com/vitest-dev/vitest/releases/tag/v5.0.0-beta.2 | `vi.spyOn` TypeScript overloads now accept `#private` field names — no `as any` cast required |

---

## Community Lessons — Iteration 22  [community]

92. **Node.js `node:test` `TestContext.mock` provides automatic-restoration mocking without Jest or Vitest — a zero-dependency isolation model.** [community]
    Node.js v18.13+ ships a built-in test runner (`node:test`) with a `TestContext` object whose `.mock` property tracks and auto-restores every mock registered within the test. Unlike `jest.restoreAllMocks()` (which must be called explicitly in `afterEach`), `TestContext`-based mocks are automatically restored when the test function returns — including if it throws. For TypeScript projects that want to avoid adding Jest or Vitest as dev dependencies (e.g., CLI tools, Node.js libraries, monorepo utility packages), this is a first-class isolation alternative. WHY: the auto-restore guarantee is the same as the `using spy = jest.spyOn()` pattern (Pattern 35) but without requiring TypeScript 5.2+ or a testing framework. Any test registered via `t.mock.method()`, `t.mock.fn()`, or `t.mock.getter()` is automatically unwound at test end regardless of how the test exits.
    ```typescript
    import { test, describe } from 'node:test';
    import assert from 'node:assert/strict';

    class UserService {
      async findUser(id: string): Promise<{ id: string; name: string } | null> {
        // real implementation makes a DB call
        return null;
      }
    }

    describe('UserService — node:test TestContext isolation', () => {
      // No beforeEach/afterEach needed for mock restoration —
      // TestContext.mock auto-restores when the test function returns
      test('findUser returns the user when found', async (t) => {
        const service = new UserService();

        // t.mock.method: spy on the method; auto-restored when test ends
        t.mock.method(service, 'findUser', async (_id: string) => {
          return { id: 'u1', name: 'Alice' };
        });

        const result = await service.findUser('u1');

        assert.strictEqual(result?.name, 'Alice');
        assert.strictEqual(service.findUser.mock.callCount(), 1);
        // At test exit: service.findUser is automatically restored to its real implementation
      });

      test('findUser is real again — no leak from previous test', async (t) => {
        const service = new UserService();

        // The previous test's mock was auto-restored — this calls the real implementation
        const result = await service.findUser('u2');
        assert.strictEqual(result, null); // real implementation returns null
      });
    });
    ```
    **Comparison with Jest/Vitest:** `t.mock.method()` is the exact counterpart to `jest.spyOn(obj, 'method')` with `restoreMocks: true`. The key difference: the auto-restore is unconditional and requires no config flag — it is the default behavior of `TestContext`. For projects that use `node:test` directly (no Jest/Vitest), this is the canonical isolation pattern.

93. **Node.js v24 `mock.module()` in `node:test` enables module-level isolation without Jest module registry resets — but requires `--experimental-require-module` or Node ≥ 24.9 for ESM.** [community]
    Node.js v24 stabilizes `mock.module(specifier, options)` in `node:test`. It intercepts imports of a module specifier and returns the mock object for the duration of the test. Unlike `jest.mock()` (which requires Babel/ts-jest hoisting) or Vitest's `vi.mock()` (which requires `vi.hoisted()` in ESM mode), `mock.module()` operates at the Node.js module loader level — no transform needed. The isolation model: the mock is scoped to the test file's module graph and is automatically removed when the test suite finishes. WHY: teams building Node.js libraries and testing them with the native test runner can now achieve module-level isolation that was previously only possible with Jest. The key gotcha: on Node.js < 24.9, mocking ESM modules requires `--experimental-require-module`; on Node.js ≥ 24.9, synchronous ESM evaluation makes `mock.module()` work for all ESM imports without any flags.
    ```typescript
    import { test, mock } from 'node:test';
    import assert from 'node:assert/strict';

    // Mock the analytics module before importing the module that uses it
    // On Node 24.9+, no experimental flag needed for ESM
    mock.module('./analytics.ts', {
      namedExports: {
        track: mock.fn(async (_event: string, _props: Record<string, unknown>) => {}),
      },
    });

    // Dynamic import picks up the mock (module.mock registered before import)
    const { registerUser } = await import('./userRegistration.ts');
    const { track } = await import('./analytics.ts');

    test('registerUser tracks a registration event', async () => {
      await registerUser({ email: 'alice@example.com', name: 'Alice' });

      assert.strictEqual(track.mock.callCount(), 1);
      assert.deepStrictEqual(track.mock.calls[0].arguments[0], 'user_registered');
    });

    test('track is called with user email in properties', async () => {
      track.mock.resetCalls(); // reset between tests

      await registerUser({ email: 'bob@example.com', name: 'Bob' });

      const [_event, props] = track.mock.calls[0].arguments;
      assert.strictEqual(props.email, 'bob@example.com');
    });
    ```
    **ESM isolation note:** `mock.module()` replaces the loaded module for the entire file's test run — it is not per-test scoped like `t.mock.method()`. Call `mock.module()` once at file scope, then use `mock.fn().resetCalls()` in between tests to isolate call state.

94. **Node.js v24 `AsyncLocalStorage` now uses `AsyncContextFrame` by default — this changes the isolation model for tests that store per-test context in `AsyncLocalStorage`.** [community]
    Node.js v24.0.0 (semver-major breaking change) switches `AsyncLocalStorage`'s underlying implementation from `AsyncResource`-based tracking to `AsyncContextFrame`, the same mechanism used by V8's built-in `structuredClone` and async hooks. For most tests this is invisible. The isolation-relevant case: tests that use `AsyncLocalStorage` to propagate per-test context (e.g., a database transaction handle, a request ID, or a logger with per-test metadata) may see changed propagation behavior through certain async primitives like `ReadableStream`, `setImmediate`, and `process.nextTick`. The change fixes a class of bugs where context was lost across certain async boundaries — but code that *relied* on the context leaking (e.g., sharing a context across streams) may break. WHY: test frameworks that build on `AsyncLocalStorage` for context propagation (e.g., custom Vitest reporter utilities, `@opentelemetry/api` context in integration tests) should audit their context propagation after upgrading to Node.js v24. The `AsyncContextFrame` model is strictly more correct, but the behavioral change can surface as tests where context is now correctly *not* propagated across boundaries that previously leaked it.
    ```typescript
    import { AsyncLocalStorage } from 'node:async_hooks';
    import { test } from 'node:test';
    import assert from 'node:assert/strict';

    // Per-test context store — isolates state across parallel tests
    const testContext = new AsyncLocalStorage<{
      testId: string;
      dbTransaction: unknown;
    }>();

    // Utility: run fn with isolated per-test context
    async function withTestContext<T>(
      testId: string,
      fn: () => Promise<T>,
    ): Promise<T> {
      return testContext.run({ testId, dbTransaction: null }, fn);
    }

    test('context is isolated per test in Node 24 AsyncContextFrame model', async () => {
      await withTestContext('test-1', async () => {
        const ctx = testContext.getStore();
        assert.strictEqual(ctx?.testId, 'test-1');

        // Node 24: context propagates correctly across setImmediate (previously could lose context)
        await new Promise<void>((resolve) => setImmediate(() => {
          const innerCtx = testContext.getStore();
          assert.strictEqual(innerCtx?.testId, 'test-1'); // ← now reliable in Node 24
          resolve();
        }));
      });
    });

    test('context does not leak between concurrent tests', async () => {
      // Run two contexts concurrently — they must not cross-contaminate
      await Promise.all([
        withTestContext('test-A', async () => {
          await new Promise<void>((r) => setTimeout(r, 10));
          assert.strictEqual(testContext.getStore()?.testId, 'test-A');
        }),
        withTestContext('test-B', async () => {
          await new Promise<void>((r) => setTimeout(r, 5));
          assert.strictEqual(testContext.getStore()?.testId, 'test-B');
        }),
      ]);
    });
    ```
    **Isolation implication:** The `AsyncContextFrame` model makes `AsyncLocalStorage` a more reliable per-test isolation mechanism. Teams that abandoned `AsyncLocalStorage` for test context propagation because it lost context across `setImmediate` or `process.nextTick` in older Node.js versions can revisit those patterns in Node.js v24.

95. **Playwright v1.59 `browserContext.setStorageState()` enables mid-session storage reset without context recreation — use for multi-user isolation within a single test.** [community]
    Playwright v1.59 adds `browserContext.setStorageState({ ... })` which clears all existing cookies, localStorage, and IndexedDB for all origins and atomically replaces them with the provided state — without creating a new browser context. Before this API, the only way to reset authentication state within a test was to: (a) close and recreate the context (expensive) or (b) manually clear each storage type individually (brittle and incomplete). The isolation use case: a single test that verifies a workflow as User A, then as User B, can call `setStorageState()` between the two user scenarios without the overhead of `page.context().newPage()` and without risking partial state leakage.
    ```typescript
    import { test, expect, BrowserContext } from '@playwright/test';

    // Fixture: pre-loaded storage states for two users
    interface MultiUserFixture {
      context: BrowserContext;
      userAState: object;
      userBState: object;
    }

    test.extend<MultiUserFixture>({
      // context: playwright's built-in fixture — test-scoped (fresh per test)
      userAState: async ({}, use) => {
        // Loaded from a JSON file created by setup project (playwright.config.ts storageState)
        await use(require('./fixtures/userA.storageState.json'));
      },
      userBState: async ({}, use) => {
        await use(require('./fixtures/userB.storageState.json'));
      },
    });

    test('transfer workflow: initiate as User A, approve as User B', async ({
      page, context, userAState, userBState,
    }) => {
      // Phase 1 — act as User A
      await context.setStorageState(userAState as Parameters<BrowserContext['setStorageState']>[0]);
      await page.goto('/transfers/new');
      await page.getByLabel('Amount').fill('500');
      await page.getByRole('button', { name: 'Submit for approval' }).click();
      await expect(page.getByText('Awaiting approval')).toBeVisible();

      // Phase 2 — switch to User B without recreating context
      // setStorageState clears User A's cookies/localStorage and loads User B's atomically
      await context.setStorageState(userBState as Parameters<BrowserContext['setStorageState']>[0]);
      await page.goto('/transfers/pending');
      await page.getByText('Approve').click();
      await expect(page.getByText('Approved')).toBeVisible();
    });
    ```
    **WHY:** Recreating the browser context between users in the same test (the previous approach) tears down active network connections and clears CDP sessions, adding ~100–300ms per user switch. `setStorageState()` performs an atomic in-context swap in <10ms. For tests that need to exercise multi-user approval flows, role switches, or permission escalations within a single scenario, this is significantly faster and avoids the `page.context().close()` / `browser.newContext()` pattern that can create fixture teardown ordering issues (see Gotcha 23 in this guide).

96. **Playwright v1.51 `browserContext.storageState({ indexedDB: true })` captures IndexedDB for auth token isolation — required for Firebase, Supabase, and IndexedDB-based auth libraries.** [community]
    Playwright's `browserContext.storageState()` previously captured only cookies and localStorage. Playwright v1.51 adds `{ indexedDB: true }` option to also capture IndexedDB contents. This is critical for applications that use Firebase Auth, Supabase Auth, or other auth libraries that store JWT/session tokens in IndexedDB rather than localStorage. Before v1.51, E2E tests for these applications could not use `storageState` for authentication isolation — each test had to sign in via the UI, making auth the slowest part of E2E suites. WHY: IndexedDB-based auth token storage became common because localStorage is accessible to XSS attacks while IndexedDB is sandboxed per-origin. But it created a Playwright isolation gap — the storage state saved and restored between tests was incomplete, causing random `"auth required"` failures when tests loaded the app and the auth library found no tokens in IndexedDB.
    ```typescript
    // playwright.config.ts — global setup to capture auth state including IndexedDB
    import { defineConfig } from '@playwright/test';

    export default defineConfig({
      projects: [
        {
          name: 'setup',
          testMatch: /global.setup\.ts/,
        },
        {
          name: 'e2e',
          use: {
            // Storage state file generated by setup project — now includes IndexedDB tokens
            storageState: 'playwright/.auth/user.json',
          },
          dependencies: ['setup'],
        },
      ],
    });

    // global.setup.ts — log in once, save state with IndexedDB
    import { test as setup } from '@playwright/test';

    setup('authenticate and save storage state', async ({ page }) => {
      await page.goto('/login');
      await page.getByLabel('Email').fill(process.env.TEST_USER_EMAIL!);
      await page.getByLabel('Password').fill(process.env.TEST_USER_PASSWORD!);
      await page.getByRole('button', { name: 'Sign in' }).click();
      await page.waitForURL('/dashboard');

      // Save storage state INCLUDING IndexedDB (Firebase/Supabase JWT tokens)
      await page.context().storageState({
        path: 'playwright/.auth/user.json',
        indexedDB: true,  // ← Playwright v1.51+ required for Firebase/Supabase auth
      });
    });
    ```
    **Isolation guarantee:** Each test worker loads the pre-saved storage state (with IndexedDB) in its worker-scoped browser context. Tests never need to perform a UI sign-in, removing the auth flow as a source of flakiness. The isolation contract: the storage state file is read-only during tests — no test modifies it — so all workers start from a deterministic authenticated state.

---

## Extended Patterns — Iteration 22

### Pattern 36: Node.js `node:test` `TestContext` mock isolation (TypeScript, Node.js ≥ 18.13)  [community]

The `TestContext.mock` API in Node.js's built-in test runner provides Jest-compatible mocking with zero-framework-dependency auto-restoration. Every mock registered via `t.mock.method()`, `t.mock.fn()`, or `t.mock.getter()` is automatically removed when the test function exits — no `afterEach` cleanup required.

```typescript
import { describe, test } from 'node:test';
import assert from 'node:assert/strict';

// Collaborator with real I/O that we want to replace in tests
class EmailSender {
  async send(to: string, subject: string): Promise<void> {
    // real SMTP send — never called in tests
    throw new Error('Real SMTP not available in tests');
  }
}

class UserRegistrationService {
  constructor(private readonly emailSender: EmailSender) {}

  async register(email: string, name: string): Promise<{ id: string }> {
    const user = { id: `user-${Date.now()}`, email, name };
    await this.emailSender.send(email, `Welcome, ${name}!`);
    return user;
  }
}

describe('UserRegistrationService', () => {
  // No module-level variables — all state is test-local
  test('sends a welcome email after registration', async (t) => {
    const sender = new EmailSender();

    // t.mock.method: wraps sender.send with a spy; auto-restored at test end
    // No afterEach, no restoreAllMocks — the TestContext handles it
    t.mock.method(sender, 'send', async (_to: string, _subject: string) => {
      // stub: do nothing (swallow the send)
    });

    const service = new UserRegistrationService(sender);

    const user = await service.register('alice@example.com', 'Alice');

    assert.ok(user.id.startsWith('user-'));
    assert.strictEqual(sender.send.mock.callCount(), 1);

    const call = sender.send.mock.calls[0];
    assert.strictEqual(call.arguments[0], 'alice@example.com');
    assert.match(call.arguments[1], /Alice/);
    // sender.send is automatically restored to real implementation here (test exit)
  });

  test('real send throws — confirms auto-restore from previous test', async (_t) => {
    // sender.send is the REAL implementation here — auto-restore worked
    const sender = new EmailSender();
    const service = new UserRegistrationService(sender);

    // Real send throws — confirms the spy was NOT leaked from the previous test
    await assert.rejects(
      () => service.register('bob@example.com', 'Bob'),
      /Real SMTP not available/,
    );
  });

  test('mock.getter() isolates a property accessor', (t) => {
    const config = {
      get maxRetries(): number {
        return 3; // real value
      },
    };

    // Mock the getter for this test only — auto-restored at exit
    t.mock.getter(config, 'maxRetries', () => 1);

    assert.strictEqual(config.maxRetries, 1); // stubbed
    // After test: config.maxRetries returns 3 again
  });
});
```

**When to use over Jest/Vitest:** Use `node:test` with `TestContext.mock` when: (1) you are building a Node.js library and want to avoid a testing-framework dependency, (2) you need to run tests without a build step on Node.js 24+ (native TypeScript type-stripping), or (3) you are in a monorepo where some packages use `node:test` and others use Jest/Vitest. The auto-restoration model is equivalent to `restoreMocks: true` in Jest config, but it is per-test and automatic — no configuration needed.

### Pattern 37: Playwright `setStorageState()` for multi-role E2E test isolation (TypeScript, Playwright v1.59+)  [community]

`browserContext.setStorageState()` enables in-test user switching — clearing all authentication state and loading a new user's cookies/localStorage/IndexedDB atomically. This is the correct isolation pattern for E2E tests that exercise multi-user workflows (approval flows, admin+user scenarios, reviewer+author patterns) within a single test body.

```typescript
import { test, expect } from '@playwright/test';
import path from 'path';

// Pre-load storage state files (generated by global setup)
const AUTH_DIR = path.join(__dirname, '../playwright/.auth');

test.use({
  storageState: path.join(AUTH_DIR, 'admin.json'), // default: tests start as admin
});

test('document review workflow: author submits, admin approves', async ({
  page,
  context,
}) => {
  // Load pre-saved author state (IndexedDB + cookies + localStorage)
  // Playwright 1.51+: storageState JSON was saved with { indexedDB: true }
  const authorState = require(path.join(AUTH_DIR, 'author.json'));

  // --- Phase 1: Act as Author ---
  await context.setStorageState(authorState); // atomic swap — ~5ms, no context recreation
  await page.goto('/documents/new');
  await page.getByLabel('Title').fill('Q2 Report');
  await page.getByRole('button', { name: 'Submit for review' }).click();

  const documentUrl = page.url(); // capture for admin to navigate to
  await expect(page.getByText('Submitted')).toBeVisible();

  // --- Phase 2: Act as Admin (default storageState) ---
  const adminState = require(path.join(AUTH_DIR, 'admin.json'));
  await context.setStorageState(adminState); // switch back to admin

  await page.goto(documentUrl); // same page, different user session
  await expect(page.getByText('Q2 Report')).toBeVisible();
  await page.getByRole('button', { name: 'Approve' }).click();
  await expect(page.getByText('Approved')).toBeVisible();
});

test('audit log shows both author submission and admin approval', async ({
  page,
  context,
}) => {
  // Each test starts fresh with admin state (set via test.use above)
  // The previous test's setStorageState changes do NOT persist — context is test-scoped
  await page.goto('/audit-log');
  // Assertions on the audit log...
});
```

**Key isolation guarantee:** `page` and `context` fixtures are test-scoped by default in Playwright — each test gets a fresh browser context. The `setStorageState()` calls within a test body only affect that test's context. This means `setStorageState()` mid-test does not contaminate the next test, which receives a clean context initialized from the project's default `storageState`.

---

## Quick Reference Additions — Iteration 22

| Problem | Symptom | Node.js native / Playwright solution | Jest/Vitest equivalent |
|---------|---------|--------------------------------------|------------------------|
| Spy auto-restore without a test framework | Must call `restoreAllMocks()` in `afterEach` to prevent leaks | `t.mock.method(obj, 'name', impl)` in `node:test` — auto-restored at test exit | `jest.spyOn()` + `restoreMocks: true` in config, or `using spy = jest.spyOn()` |
| Module mock in native `node:test` | No `jest.mock()` / `vi.mock()` available outside Jest/Vitest | `mock.module(specifier, { namedExports: { fn: mock.fn() } })` — works on Node 24.9+ for ESM without flags | `jest.mock()` + `jest.resetModules()`, or `vi.mock()` + `vi.hoisted()` |
| IndexedDB-based auth not captured in storageState | Firebase/Supabase tests fail: "auth required" despite storageState config | `page.context().storageState({ path, indexedDB: true })` in global setup (Playwright v1.51+) | N/A |
| In-test user switching without context recreation | `page.context().close()` + `browser.newContext()` adds 200ms+ per switch | `context.setStorageState(userState)` — atomic swap in <10ms (Playwright v1.59+) | N/A |
| `AsyncLocalStorage` context lost across `setImmediate` | Per-test context undefined inside deferred callbacks | Upgrade to Node.js v24 (`AsyncContextFrame` default) — context propagates reliably across all async primitives | Same fix: upgrade to Node.js v24 |

---

## Key Resources — Iteration 22 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Node.js Docs — `node:test` MockTracker | Official | https://nodejs.org/docs/latest-v24.x/api/test.html#class-mocktrackerclass | `TestContext.mock` API: auto-restore mocking, `mock.method()`, `mock.fn()`, `mock.getter()`, `mock.module()` |
| Node.js Docs — `mock.module()` | Official | https://nodejs.org/docs/latest-v24.x/api/test.html#mockmodulespecifier-options | Module-level mock for `node:test` — intercepts `import()` within test scope; ESM support on Node 24.9+ |
| Node.js v24 Release Notes — AsyncContextFrame | Official | https://nodejs.org/en/blog/release/v24.0.0 | `AsyncLocalStorage` defaults to `AsyncContextFrame` — more reliable context propagation across async primitives |
| Playwright v1.51 Release Notes — IndexedDB storageState | Official | https://playwright.dev/docs/release-notes#version-151 | `storageState({ indexedDB: true })` — captures Firebase/Supabase auth tokens stored in IndexedDB |
| Playwright v1.59 Release Notes — setStorageState | Official | https://playwright.dev/docs/release-notes#version-159 | `browserContext.setStorageState()` — atomic in-test user switching; no context recreation needed |
| Node.js v24 — Native TypeScript type stripping (RC) | Official | https://nodejs.org/en/blog/release/v24.0.0 | Run `.ts` test files directly on Node 24 without ts-jest/ts-node; enables zero-transform `node:test` suites |

---

## Extended Patterns — Iteration 23

### Pattern 38: Playwright `page.routeWebSocket()` for WebSocket connection isolation (TypeScript, Playwright v1.48+)  [community]

`page.routeWebSocket()` and `browserContext.routeWebSocket()` intercept WebSocket connections before they reach a real server, letting tests control exactly which messages are received and when. This is the correct isolation pattern for real-time features (chat, live dashboards, collaborative editing) that use WebSocket — replacing the need for a real WebSocket server in unit-level E2E tests.

```typescript
import { test, expect } from '@playwright/test';

test('live dashboard updates when server pushes a metric event', async ({ page }) => {
  // Intercept all WebSocket connections to /ws/metrics — no real server needed
  await page.routeWebSocket('/ws/metrics', (ws) => {
    // Immediately send a controlled metric event when the client connects
    ws.onopen = () => {
      ws.send(JSON.stringify({ type: 'metric', name: 'cpu', value: 82 }));
    };

    // Echo back any client keep-alive pings
    ws.onMessage((message) => {
      const parsed = JSON.parse(message as string) as { type: string };
      if (parsed.type === 'ping') {
        ws.send(JSON.stringify({ type: 'pong' }));
      }
    });
  });

  await page.goto('/dashboard');

  // Assert the UI reflects the injected metric without a real backend
  await expect(page.getByTestId('cpu-gauge')).toContainText('82%');
});

test('dashboard shows error state when server closes connection unexpectedly', async ({ page }) => {
  await page.routeWebSocket('/ws/metrics', (ws) => {
    ws.onopen = () => {
      // Simulate abrupt server disconnect immediately after connect
      ws.close(1011, 'server error');
    };
  });

  await page.goto('/dashboard');

  await expect(page.getByRole('alert')).toContainText('Connection lost');
});

test('context-level routing applies to all pages — use for multi-tab isolation', async ({
  page, context,
}) => {
  // browserContext.routeWebSocket: applies to every page in this context
  // Isolation: each test context gets its own route handler — no cross-test leakage
  await context.routeWebSocket('/ws/notifications', (ws) => {
    ws.onopen = () => {
      ws.send(JSON.stringify({ type: 'notification', text: 'You have 3 new messages' }));
    };
  });

  await page.goto('/inbox');
  await expect(page.getByTestId('notification-badge')).toContainText('3');
});
```

**Isolation guarantee:** `page.routeWebSocket()` handlers are scoped to the `page` fixture, which is test-scoped by default. Handlers registered in one test do not leak to the next test's page. Use `context.routeWebSocket()` when you need the same handler to apply to all pages within a single test's browser context (e.g., multi-tab tests), but not across tests.

**When to use over mocking the WebSocket constructor:** Use `routeWebSocket` for E2E tests where the real browser WebSocket API must be exercised. Use `vi.stubGlobal('WebSocket', MockWebSocket)` or `jest.fn()` for unit tests that test code which owns the WebSocket client directly.

### Pattern 39: `mergeTests()` for compositional fixture isolation across modules (TypeScript, Playwright v1.39+)  [community]

`mergeTests()` and `mergeExpects()` allow combining independent fixture sets from different modules into a single typed `test` object. This is the correct isolation pattern for monorepos or large test suites where database fixtures, accessibility fixtures, and authentication fixtures are maintained by different teams in separate utility packages.

```typescript
// fixtures/db.fixtures.ts — database transaction isolation fixture
import { test as base } from '@playwright/test';
import { Pool } from 'pg';

interface DbFixtures {
  db: Pool;
  resetDb: () => Promise<void>;
}

export const test = base.extend<DbFixtures>({
  db: async ({}, use) => {
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    await use(pool);
    await pool.end();
  },
  resetDb: async ({ db }, use) => {
    await use(async () => {
      await db.query('TRUNCATE users, orders RESTART IDENTITY CASCADE');
    });
  },
});

// fixtures/a11y.fixtures.ts — accessibility check fixture
import { test as base, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

interface A11yFixtures {
  checkA11y: () => Promise<void>;
}

export const test = base.extend<A11yFixtures>({
  checkA11y: async ({ page }, use) => {
    await use(async () => {
      const results = await new AxeBuilder({ page }).analyze();
      expect(results.violations).toEqual([]);
    });
  },
});

// fixtures/index.ts — compose both fixture sets without coupling them
import { mergeTests, mergeExpects } from '@playwright/test';
import { test as dbTest } from './db.fixtures';
import { test as a11yTest } from './a11y.fixtures';
import { expect as a11yExpect } from './a11y.fixtures';

export const test = mergeTests(dbTest, a11yTest);
export const expect = mergeExpects(a11yExpect);

// user-registration.spec.ts — uses all fixtures transparently
import { test, expect } from '../fixtures';

test.beforeEach(async ({ resetDb }) => {
  // DB isolation: each test starts from a clean slate
  await resetDb();
});

test('registration form is accessible and persists the user', async ({
  page,
  db,
  checkA11y,
}) => {
  await page.goto('/register');

  // a11y fixture — checks page-level accessibility violations
  await checkA11y();

  await page.getByLabel('Email').fill('alice@example.com');
  await page.getByLabel('Password').fill('s3cure!');
  await page.getByRole('button', { name: 'Create account' }).click();

  await expect(page.getByText('Welcome, alice@example.com')).toBeVisible();

  // DB fixture — verify persistence without relying only on UI state
  const result = await db.query<{ email: string }>(
    'SELECT email FROM users WHERE email = $1',
    ['alice@example.com'],
  );
  expect(result.rows).toHaveLength(1);
});
```

**WHY `mergeTests()` over manual fixture extension:** Extending fixtures with `base.extend()` in a single file couples all fixture concerns (database, accessibility, authentication) into one module. When those concerns evolve independently or are owned by different teams, coupling creates merge conflicts and makes it harder to audit which tests touch which infrastructure. `mergeTests()` keeps fixture modules independent — each can be tested, versioned, and documented separately — while giving individual test files a single import with all fixtures available.

**Isolation implication:** Each `extend()` call in a fixture module defines its own `beforeEach`/`afterEach` lifecycle. `mergeTests()` preserves these independent lifecycles, so the DB transaction fixture tears down correctly even when merged with unrelated fixtures that have their own teardown.

---

## Gotchas — Iteration 23

97. **`page.routeWebSocket()` route handlers are not automatically removed between tests — do not share a `page` across tests or you will accumulate route handlers.** [community]
    `page.routeWebSocket()` registers a persistent handler on the `page` object. Unlike `page.route()` (which can be unregistered with `page.unroute()`), WebSocket route handlers remain active for the lifetime of the `page`. This is only a problem if a `page` fixture is promoted to `worker` scope (see Gotcha 23), in which case handlers registered in test N are still active in test N+1 within the same worker. WHY: the default `page` fixture is test-scoped — each test receives a fresh page, so handlers from prior tests cannot accumulate. The trap appears when teams customize the `page` fixture to worker scope for startup speed.
    ```typescript
    // WRONG: worker-scoped page — route handlers accumulate across tests
    // fixtures/workerPage.ts
    import { test as base } from '@playwright/test';
    export const test = base.extend({
      page: [async ({ browser }, use) => {
        const page = await browser.newPage();
        await use(page);
        await page.close();
      }, { scope: 'worker' }],  // ← promotes page to worker scope
    });

    // test A registers a route handler — it persists for the worker lifetime
    test('test A', async ({ page }) => {
      await page.routeWebSocket('/ws', ws => ws.onMessage(() => ws.send('from-A')));
      // ...
    });

    // test B sees test A's handler because it's the same page object
    test('test B', async ({ page }) => {
      // SURPRISE: /ws route is still intercepted by test A's handler
    });

    // CORRECT: use default test-scoped page — fresh page per test, no handler accumulation
    ```
    **Fix:** Keep `page` at default test scope. If startup performance is critical, use worker-scoped `browser` and `browserContext` but let `page` remain test-scoped (the default Playwright behavior).

98. **`mergeTests()` fixture name collisions produce a compile-time TypeScript error but a silent runtime override — the last fixture definition wins.** [community]
    When two fixture modules passed to `mergeTests()` both define a fixture with the same name (e.g., both define a `db` fixture), TypeScript's intersection type will surface a type error only if the types differ. If the types happen to be compatible (both are `Pool`, both are `string`), TypeScript does not warn, and the second module's fixture silently overrides the first. WHY: `mergeTests()` merges fixture type intersections — same-name fixtures of the same type produce no compile-time warning, but the runtime behavior is that the rightmost module's fixture definition wins. Teams discovering this pattern late see fixture initialization order bugs: the DB connection from the first module is never created, yet no error is thrown.
    ```typescript
    import { mergeTests } from '@playwright/test';
    import { test as dbTest } from './db.fixtures';    // defines: db: Pool (primary DB)
    import { test as analyticsTest } from './analytics.fixtures'; // also defines: db: Pool (analytics DB)

    // TypeScript sees: db: Pool & Pool = Pool — no compile error
    // Runtime: analyticsTest's db fixture wins (rightmost wins)
    export const test = mergeTests(dbTest, analyticsTest);

    // Tests expecting the primary DB will silently get the analytics DB connection
    ```
    **Fix:** Use distinct, descriptive fixture names in each module (`primaryDb`, `analyticsDb`) rather than generic names. Treat fixture names as a public API contract for the module — document them explicitly to prevent collisions.

99. **Playwright v1.60 `test.abort()` is not the same as `test.fail()` — it stops test execution immediately without marking the test as an "expected failure".** [community]
    Playwright v1.60 introduces `test.abort(message?)`, which throws an internal error that immediately terminates the test with a failure. This is different from `test.fail()`, which marks a test as *expected to fail* and inverts the pass/fail result. WHY: `test.abort()` is designed for **invariant enforcement** inside route handlers and fixtures — if a test routes to `/publish` and the route handler detects that the test is about to publish to a shared staging environment (a corrupting action), calling `test.abort()` stops the test *before the damage is done* and marks it failed with a descriptive message. `test.fail()` cannot be called from inside a route handler callback.
    ```typescript
    import { test, expect } from '@playwright/test';

    // Isolation invariant: tests must never call the real /api/send-email endpoint.
    // If they do, it would send real emails and contaminate the shared test account.
    test('newsletter subscription flow', async ({ page }) => {
      await page.route('**/api/send-email', (route) => {
        // Abort instead of letting the real request go through
        // test.abort() is callable from route handlers (unlike test.fail())
        test.abort(
          'Test made a real /api/send-email call. Use the email mock fixture instead.'
        );
        return route.abort(); // also abort the network request
      });

      await page.goto('/newsletter');
      await page.getByLabel('Email').fill('user@example.com');
      await page.getByRole('button', { name: 'Subscribe' }).click();

      // If the route handler fires, test.abort() terminates before this assertion
      await expect(page.getByText('Subscribed!')).toBeVisible();
    });
    ```
    **Key distinction:**
    - `test.abort(msg)` — stops immediately, test is marked **FAILED** with `msg`; no result inversion
    - `test.fail()` — marks test as expecting failure; if the test passes, the test itself is marked failed
    - `test.skip()` — skips the test (not run at all)
    Use `test.abort()` when the test has taken an action that would contaminate shared state — the fail is the correct signal that isolation was violated.

100. **`tracing.startHar()` returns a disposable that does NOT auto-finalize — `await using` is required, or call `stopHar()` in `finally`.** [community]
    Playwright v1.60 introduces `context.tracing.startHar(path, options)` which begins recording an HTTP Archive (HAR) file for the browser context. It returns a `Disposable` object. The common misuse: calling `startHar()` and relying on the disposable being garbage-collected to finalize the file. The HAR file is only flushed and closed when `stopHar()` is called or the disposable is explicitly disposed. In tests that throw before `stopHar()`, the HAR file is incomplete or missing — making post-mortem network analysis impossible. WHY: this matters for isolation because HAR recording is typically used to capture the network state during a test for debugging; if the recording is not properly terminated in teardown, the next test's network activity can be appended to the same file, corrupting the isolation of the recorded evidence.
    ```typescript
    import { test, expect, BrowserContext, Tracing } from '@playwright/test';

    // WRONG: no cleanup — HAR file will be incomplete if test throws
    test('records network without cleanup (broken)', async ({ context, page }) => {
      await context.tracing.startHar('test-network.har');
      await page.goto('/api-heavy-page');
      // If this throws, HAR is never finalized
      await expect(page.getByText('Loaded')).toBeVisible({ timeout: 2000 });
      await context.tracing.stopHar(); // never reached on failure
    });

    // CORRECT option 1: await using (TypeScript 5.2+, Playwright v1.60+)
    // Requires: tsconfig.json "target": "ES2022" and "lib": ["ES2022", "dom"]
    test('records network with await using (auto-disposed)', async ({ context, page }) => {
      // disposable auto-calls dispose() at block exit — even if the test throws
      await using _har = await context.tracing.startHar('test-network.har');

      await page.goto('/api-heavy-page');
      await expect(page.getByText('Loaded')).toBeVisible({ timeout: 5000 });
      // HAR file finalized here via await using — no manual stopHar() needed
    });

    // CORRECT option 2: explicit finally block (works without TypeScript 5.2 target)
    test('records network with explicit teardown', async ({ context, page }) => {
      await context.tracing.startHar('test-network.har', {
        mode: 'minimal',           // omit response bodies for smaller files
        urlFilter: /\/api\//,      // only record API calls, not static assets
      });
      try {
        await page.goto('/api-heavy-page');
        await expect(page.getByText('Loaded')).toBeVisible({ timeout: 5000 });
      } finally {
        // stopHar runs regardless of pass/fail — HAR file is always complete
        await context.tracing.stopHar();
      }
    });
    ```
    **Isolation implication:** An incomplete HAR from test N (because `stopHar()` was skipped) does not contaminate test N+1 because browser contexts are test-scoped — each test gets a fresh context with its own HAR recording lifecycle. The contamination is in the *diagnostic artifact*, not in the test state itself. However, half-written HAR files from parallel workers writing to the same path cause file corruption. Always use per-test HAR file names (e.g., include `test.info().testId` in the path) when running with `--workers > 1`.

---

## Quick Reference Additions — Iteration 23

| Problem | Symptom | Playwright solution | Jest/Vitest equivalent |
|---------|---------|---------------------|------------------------|
| WebSocket server dependency in E2E tests | Tests require a running WS server; flaky under network conditions | `page.routeWebSocket('/ws', handler)` — intercept + mock WS messages in-test (v1.48+) | `vi.stubGlobal('WebSocket', MockWS)` for unit tests |
| Fixture coupling across teams | All fixture concerns in one file; merge conflicts; impossible to audit | `mergeTests(dbTest, a11yTest)` — compose independent fixture modules (v1.39+) | `vi.extend()` composition |
| Test continues after invariant violation inside route handler | Real email/publish call proceeds despite test intent | `test.abort(msg)` inside route handler — stops test immediately with failure (v1.60+) | N/A (framework-specific) |
| HAR file incomplete when test fails | Network debug archive missing — test threw before `stopHar()` | `await using _ = await context.tracing.startHar(path)` (v1.60+, TS 5.2+) | N/A |

---

## Key Resources — Iteration 23 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright v1.48 Release Notes — WebSocket routing | Official | https://playwright.dev/docs/release-notes#version-148 | `page.routeWebSocket()` + `context.routeWebSocket()` — isolate WS connections in E2E tests |
| Playwright Docs — WebSocketRoute API | Official | https://playwright.dev/docs/api/class-websocketroute | Full API reference for WebSocket route handlers: `onMessage`, `send`, `close` |
| Playwright v1.39 Release Notes — mergeTests | Official | https://playwright.dev/docs/release-notes#version-139 | `mergeTests()` + `mergeExpects()` — compose fixture modules without coupling |
| Playwright v1.60 Release Notes — test.abort | Official | https://playwright.dev/docs/release-notes#version-160 | `test.abort(message)` — fail-fast from route handlers + fixtures when isolation invariants are violated |
| Playwright Docs — Tracing API (startHar/stopHar) | Official | https://playwright.dev/docs/api/class-tracing | HAR recording API: `startHar`, `stopHar`; disposable-compatible for `await using` teardown |

---

### Pattern 40: Vitest `test.signal` for async resource cancellation on timeout or bail (TypeScript, Vitest 3.2+)  [community]

Long-running async operations started inside a test body — fetch requests, polling loops, streaming consumers — do not stop automatically when a test times out. They continue executing in the background, holding handles open and potentially contaminating the next test with their eventual resolution or rejection. Vitest 3.2 exposes `signal` as a built-in property on the test context (the argument to the test function). It is an `AbortSignal` that Vitest aborts as soon as any of the following occurs: the test's timeout fires, the user presses Ctrl+C, `vitest.cancelCurrentRun()` is called programmatically, or another test fails when the `bail` flag is non-zero. Passing this signal to any API that accepts `AbortSignal` — `fetch`, `ReadableStream`, custom async iterators, database cursors — gives those operations a guaranteed cancellation path.

```typescript
import { it, describe, expect } from 'vitest';

// Simulates a slow API that supports cancellation via AbortSignal
async function fetchWithAbort(url: string, signal: AbortSignal): Promise<string> {
  const response = await fetch(url, { signal });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.text();
}

// Simulates a polling loop that must stop when the test ends
async function pollUntilReady(
  url: string,
  signal: AbortSignal,
  intervalMs = 100,
): Promise<string> {
  while (!signal.aborted) {
    const result = await fetchWithAbort(url, signal);
    if (result !== 'pending') return result;
    await new Promise<void>((resolve) => setTimeout(resolve, intervalMs));
  }
  // signal was aborted — clean exit, no unhandled-rejection
  throw new DOMException('Polling aborted', 'AbortError');
}

describe('order processing service', () => {
  // WRONG: no signal — if this test times out at 2000 ms, the poll loop
  // continues running after the test ends, holds the worker open, and may
  // resolve against the *next* test's server state.
  it('processes order without cancellation (broken)', async () => {
    const status = await pollUntilReady('http://localhost:3000/order/42/status');
    expect(status).toBe('complete');
  }, 2000);

  // CORRECT: pass signal — Vitest aborts the signal on timeout, the poll loop
  // exits cleanly, and no handles remain open after the test ends.
  it('processes order with signal (safe)', async ({ signal }) => {
    const status = await pollUntilReady(
      'http://localhost:3000/order/42/status',
      signal,
    );
    expect(status).toBe('complete');
  }, 2000);
});

// Fixture that starts a streaming subscription and cancels it via signal
import { test as base } from 'vitest';

interface StreamFixtures {
  eventStream: ReadableStreamDefaultReader<string>;
}

const test = base.extend<StreamFixtures>({
  // signal is available on the fixture context — same abort triggers as in tests
  eventStream: async ({ signal }, use) => {
    const response = await fetch('http://localhost:3000/events', { signal });
    const reader = response.body!.getReader() as ReadableStreamDefaultReader<string>;
    await use(reader);
    // reader.cancel() is idempotent — safe even if test aborted cleanly
    await reader.cancel();
  },
});

test('receives first domain event', async ({ eventStream, signal }) => {
  const { value, done } = await eventStream.read();
  expect(done).toBe(false);
  expect(value).toContain('order.created');
});
```

**WHY the signal does not replace `onCleanup`:** `test.signal` and `onCleanup` serve different responsibilities. `signal` propagates cancellation *during* the test to in-flight async operations, while `onCleanup` / `afterEach` handles deterministic resource teardown *after* the test. For resources that cannot receive an `AbortSignal` (e.g., a database connection pool that must be explicitly `.end()`ed), `onCleanup` is still required. Use `signal` to cancel the operation and `onCleanup` to release the resource — the two compose cleanly.

**Scope restriction:** `signal` is a test-scoped context property. File-scoped and worker-scoped fixtures (`scope: 'file'` / `scope: 'worker'`) do not receive a per-test `signal` because they outlive individual tests. For those fixtures, rely on `onCleanup` registered at the appropriate scope.

---

### Pattern 41: Playwright `page.clearConsoleMessages()` / `page.clearPageErrors()` for intra-test diagnostic isolation (TypeScript, Playwright v1.59+)  [community]

Playwright stores up to 200 recent console messages and page errors per page, accessible via `page.consoleMessages()` and `page.pageErrors()`. These collections accumulate across the entire page lifetime — meaning messages emitted during the *setup* phase of a multi-phase test are still present when you assert on console output during the *action* phase. Assertions like `expect(page.consoleMessages()).toHaveLength(1)` become order-dependent and fragile when earlier test steps emit their own log output. Playwright v1.59 introduces `page.clearConsoleMessages()` and `page.clearPageErrors()` to reset these collections at any point, enabling fine-grained intra-test isolation of diagnostic state.

```typescript
import { test, expect } from '@playwright/test';

// WRONG: console messages accumulate from page.goto() onward.
// The assertion on page.consoleMessages().length is fragile because the
// page may have emitted info or warning messages during initial load.
test('checkout does not log errors (broken)', async ({ page }) => {
  await page.goto('/checkout');           // may emit "Initialized payment SDK" log
  await page.getByRole('button', { name: 'Pay now' }).click();

  // Could be 2+ if goto() emitted setup logs — assertion is flaky
  expect(page.consoleMessages()).toHaveLength(1); // ← brittle
  expect(page.consoleMessages()[0].type()).toBe('error');
});

// CORRECT: clear the diagnostic buffer before the action you are asserting on.
test('checkout does not log errors after payment attempt (correct)', async ({ page }) => {
  // Arrange: navigate and let any initialization logging complete
  await page.goto('/checkout');
  await page.waitForLoadState('networkidle');

  // Reset: discard all console messages emitted during page load/setup
  await page.clearConsoleMessages();
  await page.clearPageErrors();

  // Act: perform the action under test
  await page.getByRole('button', { name: 'Pay now' }).click();
  await page.waitForResponse('**/api/payment');

  // Assert: only messages emitted AFTER clearConsoleMessages() are present
  const messages = page.consoleMessages();
  const errorMessages = messages.filter((m) => m.type() === 'error');
  expect(errorMessages).toHaveLength(0);
});

// Multi-phase test: assert console state independently per phase
test('multi-phase form submission — isolated console assertions per phase', async ({ page }) => {
  await page.goto('/checkout');
  await page.waitForLoadState('networkidle');

  // Phase 1: validate address — assert no validation errors logged
  await page.clearConsoleMessages();
  await page.getByLabel('Address').fill('');
  await page.getByRole('button', { name: 'Next' }).click();
  const phase1Errors = page.consoleMessages().filter((m) => m.type() === 'error');
  expect(phase1Errors.map((m) => m.text())).toEqual(['Validation: address is required']);

  // Phase 2: fill address and proceed — assert only payment console output
  await page.clearConsoleMessages();
  await page.clearPageErrors();
  await page.getByLabel('Address').fill('123 Main St');
  await page.getByRole('button', { name: 'Next' }).click();

  const phase2Messages = page.consoleMessages();
  expect(phase2Messages.map((m) => m.text())).not.toContain('Validation: address is required');
});

// Fixture that resets console state before each test body runs
// (useful when page is promoted to file scope for performance)
import { test as base } from '@playwright/test';

export const test = base.extend({
  page: async ({ page }, use) => {
    // Clear any console/error state emitted during authentication or
    // other shared beforeAll setup before the test body starts.
    await page.clearConsoleMessages();
    await page.clearPageErrors();
    await use(page);
  },
});
```

**WHY this matters for isolation:** `page.consoleMessages()` and `page.pageErrors()` are not automatically reset between tests — they reset when a new page object is created. With the default test-scoped `page` fixture, this is automatic (each test gets a fresh page). The problem surfaces when `page` is promoted to `file` scope or `worker` scope for performance, or when a single test has multiple logical phases that must be asserted independently. In both cases, `clearConsoleMessages()` / `clearPageErrors()` provide the isolation boundary that would otherwise require creating and disposing a new page.

**The `filter` option is not a substitute:** `page.consoleMessages({ type: 'error' })` filters *by type* but does not isolate by *when* the message was emitted. If a phase-1 error and a phase-2 error have the same type, filtering cannot distinguish them. `clearConsoleMessages()` provides a true temporal boundary.

---

## Gotchas — Iteration 24

101. **Vitest `test.signal` is aborted for ALL bail/timeout/cancel conditions — do not use it to distinguish test failure from timeout; it fires on both.** [community]
    `test.signal` is aborted when (a) the test times out, (b) `vitest.cancelCurrentRun()` is called, (c) the user presses Ctrl+C, or (d) another test fails and `bail > 0` is configured. Teams that instrument long-running operations with `signal.aborted` to decide whether to emit a diagnostic error (e.g., "did the test fail or time out?") are surprised to discover that case (d) — a *different* test failing under `bail` — also fires the signal in the still-running test. WHY: Vitest's implementation aborts the global run signal and propagates it to all in-progress tests simultaneously when a bail condition is triggered. There is no per-cause discrimination on the signal. If your cleanup logic needs to distinguish "this test itself timed out" from "the run was cancelled externally", the only reliable source of that information is `onTestFailed()` for the former — the signal covers all cancellation causes without differentiation.
    ```typescript
    import { it, onTestFailed } from 'vitest';

    it('handles slow API with correct bail vs timeout distinction', async ({ signal }) => {
      let testBodyFailed = false;
      // Track whether THIS test's assertion failed (vs a different test failing + bail)
      onTestFailed(() => { testBodyFailed = true; });

      try {
        const result = await fetch('/slow-resource', { signal });
        // ... assertions
      } catch (err) {
        if (err instanceof DOMException && err.name === 'AbortError') {
          // signal was aborted — could be timeout, bail, or Ctrl+C
          // use testBodyFailed to narrow down if needed
          if (!testBodyFailed) {
            // cancelled externally (bail / Ctrl+C) — not a test logic failure
            return; // exit cleanly without re-throwing
          }
        }
        throw err;
      }
    }, 3000);
    ```
    **Key rule:** Use `test.signal` for *resource cancellation* (passing to fetch/stream/cursor). Do not use it as a diagnostic oracle for *why* the test ended — that is `onTestFailed()` / `onTestFinished()`'s role.

102. **`page.clearConsoleMessages()` and `page.clearPageErrors()` clear the Playwright-side buffer only — they do not affect `console.error` spy counts or browser-side listeners registered before the clear.** [community]
    `page.clearConsoleMessages()` resets the internal array returned by `page.consoleMessages()`. It does NOT: (1) affect any `page.on('console', ...)` event listener's accumulated call count, (2) clear spy wrappers on `console.error` in the page's JavaScript context, or (3) remove `page.on('pageerror', ...)` listener state. Teams that mix the `page.consoleMessages()` API with `page.on('console', handler)` pattern — for example, using both a listener that pushes to a custom array and then calling `clearConsoleMessages()` — discover that the custom array is untouched while Playwright's internal buffer is cleared, producing inconsistent assertion results depending on which collection they check. WHY: `page.consoleMessages()` is Playwright's internal store; the event listener model is separate. Choose one pattern per test, not both.
    ```typescript
    import { test, expect } from '@playwright/test';

    test('demonstrates the split between listener array and internal buffer', async ({ page }) => {
      const capturedByListener: string[] = [];

      // Custom listener accumulates ALL messages (independent of clearConsoleMessages())
      page.on('console', (msg) => capturedByListener.push(msg.text()));

      await page.goto('/dashboard');
      // page.consoleMessages() has, say, 3 items from load
      // capturedByListener also has 3 items

      // Clear the internal Playwright buffer only
      await page.clearConsoleMessages();

      // page.consoleMessages() → [] (cleared)
      // capturedByListener → still has 3 items (NOT cleared)
      await page.getByRole('button', { name: 'Load report' }).click();

      // page.consoleMessages() now has only the 1 new message from button click
      expect(page.consoleMessages()).toHaveLength(1);

      // capturedByListener has 4 items (3 from load + 1 from button) — NOT 1
      // Asserting capturedByListener.length === 1 would FAIL
    });

    // CORRECT: use only page.consoleMessages() for assertion + clearConsoleMessages() for reset
    // OR use only the custom listener array + manual reset (capturedByListener.length = 0)
    // Never mix the two for the same assertion.
    ```
    **Fix:** Pick a single collection strategy for each test file. For Playwright-native assertions, use `page.consoleMessages()` with `page.clearConsoleMessages()`. For custom accumulation (e.g., filtering by regex before storing), use a `page.on('console', ...)` listener with `capturedByListener.length = 0` for reset. Mixing both collections in the same assertion creates a confusing split-brain state.

---

## Quick Reference Additions — Iteration 24

| Problem | Symptom | Vitest solution | Playwright solution |
|---------|---------|-----------------|---------------------|
| Async operation continues after test timeout | Open handles warning; next test sees stale response | `async ({ signal }) => fetch(url, { signal })` — Vitest aborts signal on timeout/bail (v3.2+) | N/A (Playwright manages its own async lifecycle) |
| Console assertions flaky in multi-phase test | `expect(page.consoleMessages())` includes log output from earlier test phases | N/A | `await page.clearConsoleMessages()` between phases (v1.59+) |
| Page error assertions include pre-test errors | `page.pageErrors()` contains errors from navigation or fixture setup | N/A | `await page.clearPageErrors()` before the action under test (v1.59+) |
| Bail cancellation leaves resources open | Worker hangs after bail because async operations hold process open | Pass `signal` to all cancelable ops — Vitest aborts on bail | N/A |

---

## Key Resources — Iteration 24 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest 3.2 Blog — scoped fixtures + test.signal | Official | https://vitest.dev/blog/vitest-3-2 | Introduces `test.signal` (AbortSignal) and scoped fixtures (`scope: 'file'`/`'worker'`) |
| Vitest Docs — Test Context (signal) | Official | https://vitest.dev/guide/test-context#test-signal | `signal` property reference: abort conditions, usage with fetch, relationship to `bail` |
| Playwright v1.59 Release Notes — clearConsoleMessages | Official | https://playwright.dev/docs/release-notes#version-159 | `page.clearConsoleMessages()` + `page.clearPageErrors()` introduced; filter option on `consoleMessages()` |
| Playwright Docs — page.clearConsoleMessages | Official | https://playwright.dev/docs/api/class-page#page-clear-console-messages | API reference; confirms page-scoped only (no context-level equivalent) |

---

## Extended Patterns — Iteration 25

### Pattern 42: Node.js 24 `AsyncLocalStorage` `defaultValue` for null-safe per-test context stores (TypeScript, Node.js ≥ 24.0)  [community]

Node.js 24.0 added a `defaultValue` constructor option to `AsyncLocalStorage`. When a test (or test
utility) calls `getStore()` outside an active `run()` scope — for example in a module-level
initializer that runs before any test context is established — the call previously returned
`undefined`, forcing TypeScript callers to add non-null assertions (`!`) or null-checks throughout
every consumer. With `defaultValue`, the store always returns a value, making the TypeScript type
`T` instead of `T | undefined` and eliminating defensive null-checks in test helper code.

```typescript
import { AsyncLocalStorage } from 'node:async_hooks';
import { beforeEach, afterEach, test, expect } from 'vitest';

// BEFORE Node.js 24: getStore() typed as TestCtx | undefined — callers must null-check
// const testCtxStore = new AsyncLocalStorage<TestCtx>();
// const ctx = testCtxStore.getStore()!; // ← unsafe non-null assertion

interface TestCtx {
  testId: string;
  startedAt: number;
  logs: string[];
}

// AFTER Node.js 24: defaultValue gives a safe sentinel; getStore() typed as TestCtx
const testCtxStore = new AsyncLocalStorage<TestCtx>({
  // Returned by getStore() when called outside any run() — acts as a safe no-op sentinel
  defaultValue: { testId: 'NO_TEST', startedAt: 0, logs: [] },
  // name option: identifies this store in Node.js diagnostics / --inspect output
  name: 'testContext',
});

// Utility: pure function — never needs null-check on getStore()
function logTestEvent(event: string): void {
  // No null-check needed — defaultValue guarantees a non-null return
  testCtxStore.getStore().logs.push(event);
}

// Test lifecycle: establish a fresh context per test
beforeEach((ctx) => {
  // Attach a fresh TestCtx to this test's async execution context via run()
  // Note: aroundEach is preferred over beforeEach for this pattern (see Pattern 43)
  // This form is shown here to illustrate the defaultValue sentinel behavior
  testCtxStore.enterWith({ testId: ctx.task.id, startedAt: Date.now(), logs: [] });
});

test('logTestEvent captures events in per-test context', () => {
  logTestEvent('step-1');
  logTestEvent('step-2');

  const { logs } = testCtxStore.getStore();
  expect(logs).toEqual(['step-1', 'step-2']);
});

test('logs do not bleed between tests', () => {
  // Fresh context from beforeEach — previous test's logs are gone
  expect(testCtxStore.getStore().logs).toHaveLength(0);

  logTestEvent('only-this-test');

  expect(testCtxStore.getStore().logs).toEqual(['only-this-test']);
});

// Module-level call that runs before any test context — uses defaultValue, not undefined
const earlyLog = testCtxStore.getStore().logs; // ← safe; no crash; logs === []
```

**Why `enterWith` over `run()` in `beforeEach`:** `AsyncLocalStorage.run(value, fn)` scopes the
value to `fn`'s async execution tree. In `beforeEach`, the async execution tree includes the setup
callback but NOT the subsequent test body — the store reverts to `defaultValue` when the
`beforeEach` callback resolves. `enterWith(value)` sets the store for the remainder of the current
async execution context (Worker thread or main thread), which persists into the test body running
afterward. Use `enterWith` in `beforeEach`/`afterEach` pairs; use `run(value, runTest)` inside
`aroundEach` (Pattern 43) which wraps both setup and test body in one async scope.

---

### Pattern 43: Vitest `aroundEach` + `AsyncLocalStorage.run()` for scoped per-test context propagation (TypeScript, Vitest 4.1+)  [community]

Pattern 24 shows `aroundEach` for database transaction rollback. The same lifecycle hook composes
cleanly with `AsyncLocalStorage.run()` to propagate arbitrary per-test context — request IDs,
observability spans, feature flags, or test metadata — to every function called during the test
without any parameter threading. Unlike `enterWith` in `beforeEach` (which sets the store for the
current Worker thread but cannot scope teardown), `aroundEach` + `run()` guarantees the context is
active for *exactly* the duration of the test body and then reverts automatically.

```typescript
import { test as baseTest, expect, onTestFinished } from 'vitest';
import { AsyncLocalStorage } from 'node:async_hooks';

// Per-test observability context — available to any function called from within a test
interface TestSpanCtx {
  traceId: string;
  testName: string;
  events: Array<{ ts: number; msg: string }>;
}

export const spanStore = new AsyncLocalStorage<TestSpanCtx>({
  // Safe sentinel — getStore() never returns undefined outside a test scope
  defaultValue: { traceId: 'no-trace', testName: 'outside-test', events: [] },
  name: 'testSpanCtx',
});

// Utility callable from any production helper or shared fixture
export function recordEvent(msg: string): void {
  spanStore.getStore().events.push({ ts: Date.now(), msg });
}

// Build an extended `test` that wraps every test body in an ALS scope
const test = baseTest.extend({});

// aroundEach receives the current test's Task metadata — use it to populate the context
test.aroundEach(async (runTest, testTask) => {
  const traceId = `trace-${Math.random().toString(36).slice(2, 10)}`;
  const ctx: TestSpanCtx = {
    traceId,
    testName: testTask.name,
    events: [],
  };

  // run() wraps runTest — context is active for the entire test body
  await spanStore.run(ctx, async () => {
    await runTest();
    // Teardown runs INSIDE run() scope — context is still accessible here
    if (ctx.events.length > 0) {
      // Could flush to an observability backend, attach to test reporter, etc.
      onTestFinished(() => {
        // At this point ctx.events contains all events emitted during the test
        // and traceId ties them to this specific test invocation
      });
    }
  });
  // After run() exits, spanStore.getStore() returns defaultValue — no leakage
});

test('recordEvent captures events scoped to this test', () => {
  recordEvent('form-submitted');
  recordEvent('api-called');

  const { events, testName } = spanStore.getStore();
  expect(events.map((e) => e.msg)).toEqual(['form-submitted', 'api-called']);
  expect(testName).toBe('recordEvent captures events scoped to this test');
});

test('context is clean — previous test events not visible', () => {
  // aroundEach established a fresh ctx for this test via run()
  expect(spanStore.getStore().events).toHaveLength(0);

  recordEvent('only-in-this-test');
  expect(spanStore.getStore().events).toHaveLength(1);
});
```

**Contrast with `enterWith` in `beforeEach`:** `enterWith` mutates the current async context
permanently within a Worker — it does not revert after `afterEach` completes. With Vitest's `forks`
pool (one process per file), this is usually safe because the process exits after the file anyway.
With `threads` pool (shared Worker reuse), `enterWith` without a matching reset leaks the last
test's context into the next test file assigned to the same Worker. `aroundEach` + `run()` is
strictly scoped and safe regardless of pool type.

---

## Gotchas — Iteration 25

103. **Node.js 24 `node:test` automatic subtest completion silently swallows cleanup errors when the subtest allocates resources.** [community]
    Node.js 24.0 changes `t.test()` (subtests) so that the parent test automatically waits for all
    subtests to complete even without explicit `await` — matching the behavior developers expected.
    The isolation gotcha: teams that migrate existing Node.js 22/23 tests and remove manual `await`
    from subtest calls may find that resource teardown registered *outside* the subtest callback is
    now evaluated before the subtest has finished its own async teardown, because the parent
    continues to its own `afterEach` / `t.after()` while the subtest runner handles the
    sub-lifecycle internally. If a subtest opens a resource (e.g., a temporary file, a DB
    connection), clean it up *inside* the subtest callback or via `t.after(() => ...)` registered
    within the subtest — do not rely on the parent's teardown to clean up resources created inside
    a subtest.
    ```typescript
    import { test, describe } from 'node:test';
    import assert from 'node:assert/strict';
    import * as fs from 'node:fs/promises';
    import * as os from 'node:os';
    import * as path from 'node:path';

    // WRONG (Node.js 24): parent teardown runs before subtest fully finishes its async work
    test('parent manages resource allocated in subtest (broken pattern)', async (t) => {
      let tmpFile: string | undefined;

      // In Node 22, you'd await t.test(); in Node 24 it auto-completes
      t.test('creates temp file', async () => {
        tmpFile = path.join(os.tmpdir(), `test-${Date.now()}.txt`);
        await fs.writeFile(tmpFile, 'hello');
      });

      // t.after runs after the subtest — but cleanup is INSIDE the parent scope
      // If the subtest is slow, t.after may race with subtest completion
      t.after(async () => {
        if (tmpFile) await fs.unlink(tmpFile); // ← may execute before subtest finishes writing
      });
    });

    // CORRECT: register cleanup INSIDE the subtest callback
    test('parent manages resource allocated in subtest (correct)', async (t) => {
      t.test('creates and cleans up temp file', async (subT) => {
        const tmpFile = path.join(os.tmpdir(), `test-${Date.now()}.txt`);
        await fs.writeFile(tmpFile, 'hello');

        // Cleanup registered inside the subtest — guaranteed to run before subtest exits
        subT.after(async () => {
          await fs.unlink(tmpFile);
        });

        const content = await fs.readFile(tmpFile, 'utf-8');
        assert.strictEqual(content, 'hello');
      });
      // Parent's t.after() only needs to clean parent-owned resources
    });
    ```
    **Key rule:** In `node:test` with Node.js 24, treat each `t.test()` subtest as an independent
    isolation scope. Resources allocated inside a subtest must be cleaned up inside that subtest
    via `subT.after()` or `await using`. Do not hoist subtest resource cleanup into the parent
    `t.after()` — the execution ordering guarantee only applies within a single test scope.

104. **Node.js 24 `--test-global-setup` runs in the same process as the tests — singletons initialized in `globalSetup()` are shared with all test files and cannot be cleared between them.** [community]
    Jest's `globalSetup` runs in a separate, isolated process and communicates with test workers
    through serialized data (a return value written to a temp file). Node.js 24's
    `--test-global-setup` does not: the module is evaluated in the *same* Node.js process as the
    test runner and test files. This means any module-level singleton, open server handle, or
    in-memory cache that `globalSetup()` creates is shared across all test files for the entire run.
    Teams migrating Jest integration-test suites to `node:test --test-global-setup` are surprised
    when shared state set in `globalSetup()` accumulates mutations from one test file and leaks
    into the next — behavior that Jest's process isolation prevented automatically.
    ```typescript
    // global-setup.mts — runs in the same process as all tests on Node.js 24
    import { createServer, Server } from 'node:http';

    // Module-level variable — lives for the entire test run in the same process
    let server: Server;

    export async function globalSetup(): Promise<void> {
      // This server instance is reachable from ALL test files — not isolated per file
      server = createServer((req, res) => res.end('ok'));
      await new Promise<void>((resolve) => server.listen(0, resolve));
      const addr = server.address() as { port: number };
      // Pass port via env var — this IS safe, env is shared by design
      process.env.TEST_SERVER_PORT = String(addr.port);
    }

    export async function globalTeardown(): Promise<void> {
      await new Promise<void>((resolve) => server.close(() => resolve()));
    }

    // ---------------------------------------------------------------------------
    // ISOLATION HAZARD: if any test file adds a request listener to `server`
    // (e.g., by importing a module that references the same singleton), all
    // subsequent test files see the modified listener — there is no reset between files.
    //
    // SAFE PATTERN: expose only serializable primitives from globalSetup (port, URL,
    // temp dir path) via process.env. Do NOT export mutable objects or allow test
    // files to import the globalSetup module directly.
    // ---------------------------------------------------------------------------

    // package.json test script — correct invocation
    // "test": "node --test --test-global-setup=./global-setup.mts --require=tsx/cjs"
    ```
    **Contrast with Jest:** Jest's `globalSetup` return value is serialized with `JSON.stringify`
    before being passed to each worker — only JSON-serializable data can cross the boundary. This
    restriction is a feature: it prevents accidentally sharing live objects. In `node:test`, there
    is no such restriction (the process is shared), which makes it the developer's responsibility
    to avoid putting mutable shared state into `globalSetup()`. The safe contract: initialize
    *infrastructure* (servers, databases, temp directories) in `globalSetup()`, communicate results
    via `process.env` or files, and allocate *test-scoped* state in `beforeEach`/`t.before()`.

---

## Quick Reference Additions — Iteration 25

| Problem | Symptom | Node.js native / Vitest solution | Jest/Playwright equivalent |
|---------|---------|----------------------------------|----------------------------|
| `getStore()` returns `undefined` outside test scope | Non-null assertion crashes in module-level test helpers | `new AsyncLocalStorage({ defaultValue: sentinel })` (Node.js 24) | Jest/Vitest: same API — `AsyncLocalStorage` is a Node.js built-in |
| ALS context reverts to `undefined` after `beforeEach` resolves | Test body sees wrong or stale context when using `enterWith` in `beforeEach` | Vitest `aroundEach` + `ALS.run(ctx, runTest)` — wraps test body inside the `run()` scope | No direct Jest equivalent; use `enterWith` + `afterEach` reset with `threads` pool caution |
| Subtest resource cleanup races with parent teardown (Node.js 24) | Temp files / connections not fully closed before parent `t.after()` runs | Register cleanup via `subT.after()` inside the subtest callback | Jest/Vitest: resources in nested `describe` blocks are cleaned by the nearest `afterEach`/`afterAll` |
| globalSetup singleton state leaks between test files | Test files see server mutations from earlier files; state accumulates | Pass only serializable primitives (`process.env`, file paths) from `--test-global-setup` | Jest `globalSetup` is process-isolated; only JSON-serializable return values reach workers |

---

## Key Resources — Iteration 25 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Node.js 24 Release Notes — AsyncLocalStorage defaultValue | Official | https://nodejs.org/en/blog/release/v24.0.0 | `defaultValue` and `name` options added to `AsyncLocalStorage` constructor; eliminates `undefined` store in test utilities |
| Node.js Async Context Docs — AsyncLocalStorage | Official | https://nodejs.org/docs/latest-v24.x/api/async_context.html | Full API reference for `defaultValue`, `name`, `enterWith`, `run()` — Node.js 24 semantics |
| Node.js 24 — `--test-global-setup` flag | Official | https://nodejs.org/docs/latest-v24.x/api/test.html#--test-global-setup | Same-process global setup/teardown module; `globalSetup` + `globalTeardown` named exports |
| Node.js 24 — Automatic subtest completion (PR #56664) | Official | https://github.com/nodejs/node/pull/56664 | Removes need to `await t.test()` — changes subtest lifecycle and resource cleanup ordering |

---

## Extended Patterns — Iteration 26

### Pattern 44: Testcontainers PostgreSQL per-suite lifecycle with Jest `globalSetup` (TypeScript)  [community]

[Testcontainers](https://testcontainers.com/) spins up a real Docker container for each test
suite, giving every CI job a genuinely isolated database with no shared state concerns. The
container lifecycle belongs in Jest `globalSetup`/`globalTeardown` so it is started once for
the entire run and torn down cleanly after the last test. Within each test file, per-test
isolation is provided by the transaction-rollback pattern (Pattern 7).

```typescript
// jest.global-setup.ts
import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import * as os from 'node:os';

const STATE_FILE = path.join(os.tmpdir(), 'jest-tc-state.json');

export default async function globalSetup(): Promise<void> {
  const container: StartedPostgreSqlContainer = await new PostgreSqlContainer('postgres:16-alpine')
    .withDatabase('testdb')
    .withUsername('testuser')
    .withPassword('testpass')
    .start();

  // Write serializable primitives — never export the live container object
  await fs.writeFile(
    STATE_FILE,
    JSON.stringify({
      connectionUri: container.getConnectionUri(),
      containerId: container.getId(),
    }),
  );

  // Make URL available to test files via environment variable
  process.env.DATABASE_URL = container.getConnectionUri();
}

// jest.global-teardown.ts
import { GenericContainer } from 'testcontainers';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import * as os from 'node:os';

const STATE_FILE = path.join(os.tmpdir(), 'jest-tc-state.json');

export default async function globalTeardown(): Promise<void> {
  const raw = await fs.readFile(STATE_FILE, 'utf-8').catch(() => null);
  if (!raw) return;
  const { containerId } = JSON.parse(raw) as { containerId: string };
  // Stop the container by ID without re-importing the live object
  const container = await GenericContainer.fromExistingContainer(containerId);
  await container.stop();
  await fs.unlink(STATE_FILE).catch(() => {});
}
```

```typescript
// jest.config.ts
import { defineConfig } from 'jest';

export default defineConfig({
  globalSetup: './jest.global-setup.ts',
  globalTeardown: './jest.global-teardown.ts',
  testEnvironment: 'node',
  transform: { '^.+\\.tsx?$': ['ts-jest', { tsconfig: 'tsconfig.test.json' }] },
});
```

```typescript
// users.integration.test.ts — uses transaction rollback per test (Pattern 7)
import { Pool } from 'pg';
import { UserRepository } from '../src/UserRepository';

describe('UserRepository — Testcontainers integration', () => {
  let pool: Pool;

  beforeAll(async () => {
    // DATABASE_URL injected by globalSetup via process.env
    pool = new Pool({ connectionString: process.env.DATABASE_URL });
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        name  TEXT NOT NULL
      )
    `);
  });

  afterAll(async () => {
    await pool.end();
  });

  describe('per-test isolation via SAVEPOINT rollback', () => {
    let client: import('pg').PoolClient;

    beforeEach(async () => {
      client = await pool.connect();
      await client.query('BEGIN');
      await client.query('SAVEPOINT test_start');
    });

    afterEach(async () => {
      // Roll back to savepoint — leaves DB in pre-test state for next test
      await client.query('ROLLBACK TO SAVEPOINT test_start');
      await client.query('ROLLBACK');
      client.release();
    });

    it('inserts a user and retrieves it by email', async () => {
      const repo = new UserRepository(client);

      const user = await repo.create({ email: 'alice@example.com', name: 'Alice' });
      const found = await repo.findByEmail('alice@example.com');

      expect(found).toMatchObject({ id: user.id, name: 'Alice' });
    });

    it('returns null for an email that was not inserted in this test', async () => {
      // alice@example.com was rolled back — this test starts with an empty table
      const repo = new UserRepository(client);

      const found = await repo.findByEmail('alice@example.com');

      expect(found).toBeNull();
    });
  });
});
```

**Why Testcontainers over a shared dev database:** A shared dev database accumulates stale rows,
requires manual seeding coordination across team members, and makes parallel CI runs interfere
with each other. Testcontainers starts the container from a known-clean image, so the test run
is fully hermetic and can be reproduced exactly by any developer or CI agent with Docker installed.

---

### Pattern 45: MSW v2 handler isolation with `server.resetHandlers()` (TypeScript)  [community]

MSW v2 replaces the v1 `rest.*` namespace with `http.*` and `graphql.*` handlers. The isolation
contract is unchanged — `server.resetHandlers()` must be called in `afterEach` to discard any
per-test overrides registered with `server.use()`. Without the reset, handler overrides registered
inside a test accumulate on the handler stack and affect all subsequent tests in the file.

```typescript
// test-utils/msw-server.ts — shared server instance (module singleton)
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';

// Base handlers — apply to every test unless overridden
export const baseHandlers = [
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({ id: params['id'], name: 'Default User' });
  }),
  http.post('/api/users', async ({ request }) => {
    const body = await request.json() as { name: string };
    return HttpResponse.json({ id: '1', name: body.name }, { status: 201 });
  }),
];

export const server = setupServer(...baseHandlers);
```

```typescript
// vitest.setup.ts  (or jest.setup.ts)
import { server } from './test-utils/msw-server';
import { beforeAll, afterAll, afterEach } from 'vitest';

// Start the MSW intercept layer before any test file runs
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));

// CRITICAL: reset per-test overrides after every test
// Without this, server.use() inside a test leaks to subsequent tests
afterEach(() => server.resetHandlers());

// Tear down after the full suite
afterAll(() => server.close());
```

```typescript
// UserService.test.ts — per-test handler overrides without cross-test leakage
import { describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from './test-utils/msw-server';
import { UserService } from '../src/UserService';

const service = new UserService('http://localhost');

describe('UserService.getUser', () => {
  it('returns user data from the base handler', async () => {
    // Uses the base handler — no override needed
    const user = await service.getUser('42');

    expect(user).toEqual({ id: '42', name: 'Default User' });
  });

  it('surfaces a 404 response as a domain NotFoundError', async () => {
    // Per-test override: shadow the base handler for this test only
    server.use(
      http.get('/api/users/:id', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      ),
    );

    // After this test, afterEach calls server.resetHandlers() —
    // the next test sees the original base handler, not this 404 override
    await expect(service.getUser('99')).rejects.toThrow('NotFoundError');
  });

  it('next test still uses base handler — override was discarded by resetHandlers()', async () => {
    // Proves resetHandlers() works: no 404 override from the previous test
    const user = await service.getUser('1');

    expect(user.name).toBe('Default User');
  });
});
```

**MSW v2 isolation gotchas:**
- `server.use()` *prepends* handlers — it does NOT replace them. The first matching handler wins.
  If you use `server.use(http.get('/api/users/:id', ...))` twice without a reset in between,
  the second call adds another handler on top, making the stack grow indefinitely.
- `onUnhandledRequest: 'error'` in `server.listen()` is the recommended setting for test suites.
  It converts any request that reaches no handler into a test failure, surfacing accidental
  network calls that should have been mocked. Use `onUnhandledRequest: 'warn'` during initial
  migration to avoid hard failures before all handlers are defined.
- `server.resetHandlers(...newHandlers)` (with arguments) replaces the base handler list entirely.
  Call it without arguments (the common case) to only discard per-test overrides while preserving
  base handlers.

---

### Pattern 46: Jest `projects` for monorepo test isolation without cross-package state leakage (TypeScript)  [community]

In a monorepo with multiple packages sharing a root Jest config, each `project` entry runs in
its own module registry and environment. Without `projects`, Jest's module cache is shared across
all packages in `--runInBand` mode, causing singleton state from one package's tests to leak
into another package's tests when the module is `require()`d again.

```typescript
// jest.config.ts (monorepo root)
import { defineConfig } from 'jest';

export default defineConfig({
  // Each project gets its own module registry — equivalent to separate jest.config.ts per package
  projects: [
    {
      displayName: 'packages/api',
      testMatch: ['<rootDir>/packages/api/**/*.test.ts'],
      testEnvironment: 'node',
      transform: { '^.+\\.tsx?$': ['ts-jest', { tsconfig: '<rootDir>/packages/api/tsconfig.json' }] },
      // moduleNameMapper resolves workspace packages without hoisting side-effects
      moduleNameMapper: {
        '^@myorg/shared(.*)$': '<rootDir>/packages/shared/src$1',
      },
      // Project-level setupFilesAfterFramework — does not affect other projects
      setupFilesAfterFramework: ['<rootDir>/packages/api/jest.setup.ts'],
    },
    {
      displayName: 'packages/web',
      testMatch: ['<rootDir>/packages/web/**/*.test.tsx'],
      testEnvironment: 'jsdom',
      transform: { '^.+\\.tsx?$': ['ts-jest', { tsconfig: '<rootDir>/packages/web/tsconfig.json' }] },
      moduleNameMapper: {
        '^@myorg/shared(.*)$': '<rootDir>/packages/shared/src$1',
      },
      setupFilesAfterFramework: ['<rootDir>/packages/web/jest.setup.ts'],
    },
    {
      displayName: 'packages/shared',
      testMatch: ['<rootDir>/packages/shared/**/*.test.ts'],
      testEnvironment: 'node',
      transform: { '^.+\\.tsx?$': ['ts-jest', { tsconfig: '<rootDir>/packages/shared/tsconfig.json' }] },
    },
  ],
  // Global coverage collection — merged across all projects
  collectCoverageFrom: ['packages/*/src/**/*.ts', '!**/*.d.ts'],
});
```

```typescript
// packages/api/jest.setup.ts — runs ONLY for the api project
import { server } from './test-utils/msw-server';
import { beforeAll, afterAll, afterEach } from '@jest/globals';

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// This MSW server instance is fully isolated from packages/web's MSW server —
// they run in separate Jest workers with separate module registries
```

**Why `projects` matters for isolation:**
- Without `projects`, a module-level singleton (e.g., an event bus, connection pool, or service
  registry) imported by both `packages/api` and `packages/web` tests may be the *same instance*
  if Jest reuses the module cache. With `projects`, each project has a fully isolated module
  registry: the same module imported in two projects produces two independent instances.
- `setupFilesAfterFramework` at the project level applies *only* to that project's test files.
  Root-level `setupFilesAfterFramework` in the parent config applies to *all* projects. Mixing
  the two accidentally creates asymmetric setup state: one package's tests run with a mock that
  another package's tests do not have.

---

### Pattern 47: EventEmitter leak detection and per-test listener cleanup (TypeScript)  [community]

Node.js emits `MaxListenersExceededWarning` when more than 10 listeners are attached to the
same `EventEmitter`. In Jest/Vitest, this typically means a `beforeEach` adds a listener but
the corresponding `afterEach` removes it from the wrong reference or not at all. Left unchecked,
leaked listeners cause test-order-dependent behavior: the 11th test sees accumulated listener
state from the previous 10.

```typescript
import { EventEmitter } from 'node:events';
import { beforeEach, afterEach, it, expect, describe } from 'vitest';
import { OrderProcessor } from '../src/OrderProcessor';

// Intentionally lower limit to detect leaks early — default is 10
EventEmitter.defaultMaxListeners = 5;

describe('OrderProcessor event isolation', () => {
  let emitter: EventEmitter;
  let processor: OrderProcessor;

  // Listener reference captured so afterEach can remove the exact function
  let onOrderPlaced: (orderId: string) => void;
  const capturedOrders: string[] = [];

  beforeEach(() => {
    emitter = new EventEmitter();
    processor = new OrderProcessor(emitter);
    capturedOrders.length = 0; // reset accumulator

    onOrderPlaced = (orderId: string) => capturedOrders.push(orderId);
    emitter.on('order:placed', onOrderPlaced);
  });

  afterEach(() => {
    // Remove the exact listener reference — prevents MaxListenersExceededWarning
    emitter.off('order:placed', onOrderPlaced);
    // Verify no listeners were left attached by the SUT itself
    expect(emitter.listenerCount('order:placed')).toBe(0);
  });

  it('emits order:placed when an order is submitted', () => {
    processor.submit({ id: 'o1', items: ['item-a'] });

    expect(capturedOrders).toEqual(['o1']);
  });

  it('only captures events from this test — no contamination from previous test', () => {
    // If afterEach had not removed the listener, the previous test's listener
    // would still be attached to the same emitter reference, causing double-fire
    processor.submit({ id: 'o2', items: ['item-b'] });

    expect(capturedOrders).toHaveLength(1);
    expect(capturedOrders[0]).toBe('o2');
  });
});
```

**Anti-pattern — anonymous listener in `beforeEach` without matching `off`:**

```typescript
// WRONG: arrow function literal creates a new reference each time;
// emitter.off() cannot match it — listener accumulates across tests
beforeEach(() => {
  emitter.on('order:placed', (id) => capturedOrders.push(id));
  //          ^^^ new function reference every call — cannot be removed with off()
});
// Fix: capture the function in a variable in describe scope, as shown above
```

---

## Gotchas — Iteration 26

105. **Testcontainers `GenericContainer.fromExistingContainer()` requires the container to still be running — calling it in `globalTeardown` after a test-runner crash may throw.** [community]
    When a Jest worker crashes mid-run (OOM, SIGKILL), `globalTeardown` still runs — but the
    container may have already been stopped by Docker's `--rm` flag if the container was started
    with auto-remove. Calling `container.stop()` on an already-stopped container throws. The
    safe teardown pattern: write the container ID to a temp file in `globalSetup`, then in
    `globalTeardown` use the Docker CLI as a fallback if the Testcontainers SDK throws, or
    simply ignore `ENOENT` / "container not found" errors.
    ```typescript
    // jest.global-teardown.ts — defensive teardown
    import { GenericContainer } from 'testcontainers';
    import * as fs from 'node:fs/promises';
    import * as path from 'node:path';
    import * as os from 'node:os';
    import { execSync } from 'node:child_process';

    const STATE_FILE = path.join(os.tmpdir(), 'jest-tc-state.json');

    export default async function globalTeardown(): Promise<void> {
      const raw = await fs.readFile(STATE_FILE, 'utf-8').catch(() => null);
      if (!raw) return; // globalSetup never completed — nothing to tear down
      const { containerId } = JSON.parse(raw) as { containerId: string };
      try {
        const c = await GenericContainer.fromExistingContainer(containerId);
        await c.stop();
      } catch {
        // Container may already be stopped; fall back to docker CLI
        try { execSync(`docker rm -f ${containerId}`, { stdio: 'ignore' }); } catch { /* ignore */ }
      }
      await fs.unlink(STATE_FILE).catch(() => {});
    }
    ```

106. **MSW v2 `server.use()` with `{ once: true }` does not call `resetHandlers()` — the one-time handler is consumed but the handler stack entry is not removed.** [community]
    MSW v2 introduced `{ once: true }` on handler registration, which causes the handler to
    respond to only the first matching request and then fall through to the next handler. Teams
    mistake "one-time" for "auto-cleanup" — but the handler *entry* remains in the stack even
    after being consumed. If `resetHandlers()` is not called in `afterEach`, the consumed entry
    accumulates: after 100 tests each registering a one-time override, the handler stack has 100
    entries. This slows handler matching and can confuse debugging. The fix is unchanged:
    always call `server.resetHandlers()` in `afterEach`, regardless of whether you used
    `{ once: true }`. MSW's `resetHandlers()` removes ALL overrides added via `server.use()`,
    consumed or not.

107. **Jest `projects` with shared `setupFilesAfterFramework` in the root config runs the setup in every project's worker — including projects where the setup references services that are not configured for that project.** [community]
    A root-level `setupFilesAfterFramework: ['./jest.root-setup.ts']` entry in a monorepo
    `jest.config.ts` runs in the worker for *every* project — including `packages/web` (jsdom
    environment) and `packages/api` (node environment). If `jest.root-setup.ts` imports a
    Node.js-only module (e.g., `pg`, `ioredis`) without a guard, the jsdom-environment workers
    for `packages/web` throw `ReferenceError: require is not defined` or module resolution
    errors. The fix: move environment-specific setup to project-level `setupFilesAfterFramework`
    entries, and keep root-level setup to environment-neutral concerns only (global matchers,
    timezone, locale).
    ```typescript
    // jest.root-setup.ts — SAFE: environment-neutral only
    import { expect } from '@jest/globals';
    import { toMatchCloseTo } from './test-utils/custom-matchers';

    expect.extend({ toMatchCloseTo });
    // No Node.js-only imports — this runs in both jsdom and node workers
    ```

108. **`EventEmitter.removeAllListeners()` in `afterEach` removes listeners added by the SUT internally — causing false positives where the next test's SUT fires no events because its internal listeners were stripped.** [community]
    `emitter.removeAllListeners()` is a blunt instrument. If the system under test registers its
    own listeners on the emitter during construction or `start()`, calling `removeAllListeners()`
    in `afterEach` strips those too. The next `beforeEach` creates a new `OrderProcessor(emitter)`
    but the emitter's SUT-internal listeners are gone — causing tests to pass when events are
    not being processed at all. Always use `emitter.off(event, specificListener)` with the exact
    function reference captured in `beforeEach`. If you need to clean up SUT-internal listeners,
    expose a `destroy()` method on the SUT and call it in `afterEach`, then recreate the emitter
    fresh rather than reusing the same instance.

---

## Quick Reference Additions — Iteration 26

| Problem | Symptom | Solution | Framework |
|---------|---------|----------|-----------|
| CI database tests interfere across runs | Flaky failures when two branches run in same environment | Testcontainers `PostgreSqlContainer` per suite — full Docker isolation | Jest + Testcontainers |
| MSW handler override persists to next test | Second test gets 404 that was registered in previous test | `afterEach(() => server.resetHandlers())` in `vitest.setup.ts` | MSW v2 + Vitest/Jest |
| Same module singleton leaks between monorepo packages | `packages/api` tests affect `packages/web` singleton state | Jest `projects` — separate module registry per project | Jest monorepo |
| `MaxListenersExceededWarning` in CI only | Listener count grows with each test; fails after N tests | Capture listener ref in `describe` scope; `emitter.off(event, ref)` in `afterEach` | Vitest/Jest |
| Testcontainers teardown fails after CI OOM kill | `globalTeardown` throws "container not found" | Wrap `container.stop()` in try/catch; fall back to `docker rm -f` CLI | Jest globalTeardown |

---

## Key Resources — Iteration 26 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Testcontainers for Node.js | Official | https://node.testcontainers.org/ | Full API docs for `PostgreSqlContainer`, `GenericContainer`, lifecycle hooks, `fromExistingContainer` |
| Testcontainers Cloud Docs | Official | https://testcontainers.com/cloud/docs/ | Cloud Docker daemon — eliminates local Docker requirement in CI; Turbo mode for parallel container starts |
| MSW v2 — `http` namespace migration | Official | https://mswjs.io/docs/migrations/1.x-to-2.x | `rest.*` → `http.*` and `graphql.*`; `HttpResponse` API; `{ once: true }` handler option |
| MSW v2 — `server.resetHandlers()` | Official | https://mswjs.io/docs/api/setup-server/reset-handlers | Confirms reset discards ALL `server.use()` overrides including consumed `{ once: true }` handlers |
| Jest — `projects` configuration | Official | https://jestjs.io/docs/configuration#projects-arraystring--projectconfig | Per-project module registry isolation; `displayName`, `testMatch`, `setupFilesAfterFramework` scoping |
| Node.js EventEmitter — `listenerCount` | Official | https://nodejs.org/docs/latest-v24.x/api/events.html#emitterlistenercounteventname-listener | `listenerCount(event)` for post-`afterEach` leak assertion; `defaultMaxListeners` tuning |

---

## Patterns — Iteration 27

### Pattern 48: ioredis-mock in-memory Redis isolation for unit tests (TypeScript)  [community]

Pattern 13 covers isolation for tests that talk to a *real* Redis instance via key namespacing.
For **unit tests** — code paths that import an `ioredis` client but should never require a running
Redis server — swap the entire `ioredis` module with `ioredis-mock` via Jest's `moduleNameMapper`
or an explicit `jest.mock()` call. The mock emulates ioredis commands in-process with zero network
I/O: tests are fast, hermetic, and work offline.

**Key ioredis-mock v6 isolation rule:** instances sharing the same host+port share an in-memory
context (just like real Redis). To give each test a clean slate, either call `redis.flushall()` in
`afterEach` or create instances on different ports. Using a fixed port per `describe` block prevents
cross-suite data leakage while avoiding per-test `flushall` overhead when tests are read-heavy.

```typescript
// jest.config.ts — swap ioredis globally for ALL tests that import it
import { defineConfig } from 'jest';

export default defineConfig({
  preset: 'ts-jest',
  testEnvironment: 'node',
  moduleNameMapper: {
    // Any import of 'ioredis' resolves to the in-memory mock
    '^ioredis$': 'ioredis-mock',
  },
});
```

```typescript
// cacheService.ts — production code uses ioredis as normal
import Redis from 'ioredis';

export class CacheService {
  constructor(private readonly redis: Redis) {}

  async set(key: string, value: unknown, ttlSeconds: number): Promise<void> {
    await this.redis.set(key, JSON.stringify(value), 'EX', ttlSeconds);
  }

  async get<T>(key: string): Promise<T | null> {
    const raw = await this.redis.get(key);
    return raw === null ? null : (JSON.parse(raw) as T);
  }

  async del(key: string): Promise<void> {
    await this.redis.del(key);
  }
}
```

```typescript
// cacheService.test.ts — uses ioredis-mock transparently via moduleNameMapper
import Redis from 'ioredis'; // resolves to ioredis-mock in test context
import { CacheService } from './cacheService';

describe('CacheService (in-memory Redis)', () => {
  // Port 6380 creates an isolated mock context — does not share state with port 6379
  const redis = new Redis({ host: 'localhost', port: 6380 });
  const cache = new CacheService(redis);

  afterEach(async () => {
    // flushall resets ALL keys in this mock instance — safe because it is in-memory only
    await redis.flushall();
  });

  afterAll(async () => {
    await redis.quit();
  });

  it('stores a serialised object and retrieves it', async () => {
    await cache.set('user:1', { name: 'Alice', role: 'admin' }, 60);

    const result = await cache.get<{ name: string; role: string }>('user:1');

    expect(result).toEqual({ name: 'Alice', role: 'admin' });
  });

  it('returns null for a key that does not exist', async () => {
    const result = await cache.get<unknown>('missing:key');

    expect(result).toBeNull();
  });

  it('del removes the key so subsequent get returns null', async () => {
    await cache.set('session:xyz', { token: 'abc123' }, 300);
    await cache.del('session:xyz');

    const result = await cache.get<unknown>('session:xyz');

    expect(result).toBeNull();
  });

  it('flushall in afterEach prevents data leak to subsequent tests', async () => {
    // If flushall did not run after the previous test, 'user:1' would still exist here
    const leaked = await cache.get<unknown>('user:1');
    expect(leaked).toBeNull();
  });
});
```

**Per-file jest.mock() alternative** (when `moduleNameMapper` is too broad):

```typescript
// Only swap ioredis for this file — other files continue to use real ioredis
jest.mock('ioredis', () => {
  const { default: RedisMock } = jest.requireActual<typeof import('ioredis-mock')>('ioredis-mock');
  return { default: RedisMock, __esModule: true };
});
```

---

### Pattern 49: memfs virtual file system for disk-free file I/O isolation (TypeScript)  [community]

Pattern 11 covers isolation using real temp directories on disk. For **unit tests** where the system
under test uses `fs` or `node:fs` but should never touch the real disk, replace the `fs` module with
an in-memory volume using `memfs`. Benefits over temp directories: no `afterEach` cleanup, no
permission errors, no OS-specific path separators in assertions, and tests run 10-100× faster
because there is no disk I/O.

`memfs` exports `createFsFromVolume` and `Volume`. A `Volume` is an in-memory filesystem tree. You
create a volume, optionally seed it with `vol.fromJSON()`, pass it to `createFsFromVolume()` to get
a `fs`-compatible object, and then make Jest resolve `node:fs` to that object for your module under
test. Call `vol.reset()` in `afterEach` to wipe the in-memory tree.

```typescript
// Install: npm install --save-dev memfs
// reportExporter.ts — uses node:fs to write reports
import * as fs from 'node:fs';
import * as path from 'node:path';

export async function exportReportToFile(
  data: Record<string, unknown>,
  outPath: string,
): Promise<void> {
  const dir = path.dirname(outPath);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(outPath, JSON.stringify(data, null, 2), 'utf-8');
}
```

```typescript
// reportExporter.test.ts — no disk I/O; volume lives in process memory
import { jest, beforeEach, afterEach, it, expect, describe } from '@jest/globals';
import { Volume, createFsFromVolume } from 'memfs';
import * as path from 'node:path';

// Create a single volume shared across tests; reset it in afterEach
const vol = new Volume();

// Intercept 'node:fs' — all fs calls inside reportExporter go to the in-memory volume
jest.mock('node:fs', () => createFsFromVolume(vol));

// Import AFTER jest.mock so the mocked fs is in place
import { exportReportToFile } from './reportExporter';

describe('exportReportToFile (in-memory fs)', () => {
  afterEach(() => {
    // Wipe the entire in-memory tree — next test starts with an empty volume
    vol.reset();
  });

  it('creates the output file with serialised JSON content', async () => {
    const outPath = '/reports/run-1/output.json';

    await exportReportToFile({ userId: 'u1', actions: ['login'] }, outPath);

    const raw = vol.readFileSync(outPath, 'utf-8') as string;
    const parsed = JSON.parse(raw) as { userId: string; actions: string[] };
    expect(parsed.userId).toBe('u1');
    expect(parsed.actions).toHaveLength(1);
  });

  it('creates intermediate directories when they do not exist', async () => {
    const outPath = '/deep/nested/dir/report.json';

    await exportReportToFile({ userId: 'u2', actions: [] }, outPath);

    // vol.existsSync reflects the in-memory state — no real /deep/nested/dir was created
    expect(vol.existsSync('/deep/nested/dir')).toBe(true);
  });

  it('overwrites an existing file without error', async () => {
    const outPath = '/reports/report.json';
    // Seed the volume with an existing file to test overwrite behaviour
    vol.fromJSON({ [outPath]: '{"old":true}' });

    await exportReportToFile({ userId: 'u3', actions: ['logout'] }, outPath);

    const raw = vol.readFileSync(outPath, 'utf-8') as string;
    expect(JSON.parse(raw)).not.toHaveProperty('old');
  });

  it('vol.reset() in afterEach prevents data leak — volume is empty at test start', async () => {
    // If reset() had not run, the previous test's /reports/report.json would be visible
    expect(vol.existsSync('/reports/report.json')).toBe(false);
  });
});
```

**Vitest equivalent** — Vitest does not hoist `vi.mock()` to the top of the file in all cases with
ESM. Use the factory form explicitly:

```typescript
// vitest — memfs virtual fs
import { vi, beforeEach, afterEach, it, expect, describe } from 'vitest';
import { Volume, createFsFromVolume } from 'memfs';

const vol = new Volume();

vi.mock('node:fs', () => createFsFromVolume(vol));

import { exportReportToFile } from './reportExporter';

describe('exportReportToFile (Vitest + memfs)', () => {
  afterEach(() => vol.reset());

  it('writes JSON to the in-memory volume', async () => {
    await exportReportToFile({ score: 42 }, '/tmp/result.json');

    const content = vol.readFileSync('/tmp/result.json', 'utf-8') as string;
    expect(JSON.parse(content)).toEqual({ score: 42 });
  });
});
```

---

### Pattern 50: `crypto.randomUUID` / `global.crypto` isolation for deterministic IDs (TypeScript)  [community]

Code that calls `crypto.randomUUID()` (Node.js 14.17+, browsers) produces a different UUID on every
invocation, making assertions on generated IDs unreliable unless the test controls the source. The
solution is to mock `globalThis.crypto.randomUUID` via `jest.spyOn()` (or `vi.spyOn()` in Vitest),
providing a deterministic sequence of UUIDs for the test. Because `restoreMocks: true` in the Jest
config restores the original after each test, the mock is automatically cleaned up.

For code that accepts a `generateId` dependency via injection, prefer the DI approach (Pattern 3
style). Reserve `crypto.randomUUID` mocking for code where the ID generation is deeply embedded and
refactoring is impractical.

```typescript
// orderService.ts — uses crypto.randomUUID internally for order ID generation
export interface Order {
  id: string;
  customerId: string;
  totalCents: number;
  status: 'pending' | 'confirmed';
}

export function createOrder(customerId: string, totalCents: number): Order {
  return {
    id: crypto.randomUUID(),   // non-deterministic without a mock
    customerId,
    totalCents,
    status: 'pending',
  };
}
```

```typescript
// orderService.test.ts — Jest + TypeScript, restoreMocks: true in config
import { createOrder } from './orderService';

describe('createOrder', () => {
  it('assigns a stable UUID when crypto.randomUUID is mocked', () => {
    // Arrange — intercept globalThis.crypto.randomUUID before the Act phase
    const FIXED_UUID = '00000000-0000-0000-0000-000000000001';
    const spy = jest
      .spyOn(globalThis.crypto, 'randomUUID')
      .mockReturnValue(FIXED_UUID as ReturnType<typeof crypto.randomUUID>);

    // Act
    const order = createOrder('customer-42', 9999);

    // Assert
    expect(order.id).toBe(FIXED_UUID);
    expect(order.customerId).toBe('customer-42');
    expect(spy).toHaveBeenCalledTimes(1);
    // restoreMocks: true in jest.config.ts cleans up the spy automatically
  });

  it('produces unique IDs on consecutive real calls (no mock)', () => {
    // Arrange — no spy; real crypto.randomUUID runs
    const a = createOrder('c1', 100);
    const b = createOrder('c2', 200);

    // Assert
    expect(a.id).not.toBe(b.id);
    expect(a.id).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
    );
  });

  it('can provide a sequence of UUIDs via mockReturnValueOnce', () => {
    // Arrange — each call to randomUUID returns the next value in the sequence
    jest
      .spyOn(globalThis.crypto, 'randomUUID')
      .mockReturnValueOnce('aaaaaaaa-0000-0000-0000-000000000001' as `${string}-${string}-${string}-${string}-${string}`)
      .mockReturnValueOnce('bbbbbbbb-0000-0000-0000-000000000002' as `${string}-${string}-${string}-${string}-${string}`);

    const first = createOrder('c1', 100);
    const second = createOrder('c2', 200);

    expect(first.id).toBe('aaaaaaaa-0000-0000-0000-000000000001');
    expect(second.id).toBe('bbbbbbbb-0000-0000-0000-000000000002');
  });
});
```

**Vitest equivalent** using `vi.stubGlobal()` (preferred over `vi.spyOn` for global objects in Vitest
because `vi.spyOn(globalThis.crypto, 'randomUUID')` may not intercept calls made from within the
same V8 microtask context in `vmThreads` pool):

```typescript
// orderService.test.ts — Vitest
import { vi, afterEach, it, expect, describe } from 'vitest';
import { createOrder } from './orderService';

describe('createOrder (Vitest)', () => {
  afterEach(() => {
    // vi.unstubAllGlobals() restores all globals stubbed in this test
    vi.unstubAllGlobals();
  });

  it('uses a deterministic UUID when stubbed via vi.stubGlobal', () => {
    const FIXED_UUID = 'cccccccc-0000-0000-0000-000000000003';
    // Replace the entire crypto object with a partial stub — only randomUUID is overridden
    vi.stubGlobal('crypto', {
      ...globalThis.crypto,
      randomUUID: vi.fn().mockReturnValue(FIXED_UUID),
    });

    const order = createOrder('cust-1', 4999);

    expect(order.id).toBe(FIXED_UUID);
  });
});
```

---

## Gotchas — Iteration 27

109. **ioredis-mock v6+ instances on the same port share context — `new Redis()` in two separate test files can corrupt each other's data when Jest runs them in the same worker without `resetModules`.** [community]
    In ioredis-mock v6, the shared-context design means that if `packages/api/test/auth.test.ts`
    and `packages/api/test/session.test.ts` both `new Redis()` (default port 6379) and run in the
    same Jest worker (e.g. `--runInBand` or a low `maxWorkers` setting), a `SET` in one test file
    can be read by another. The fix: either call `await redis.flushall()` in every `afterEach` in
    every test file, or assign each test *file* a unique port:
    ```typescript
    // jest.setup.ts — derive an isolated port from the Jest worker ID (1-based, unique per worker)
    import Redis from 'ioredis'; // resolved to ioredis-mock via moduleNameMapper

    // workerIdToPort: worker 1 → 6401, worker 2 → 6402, …
    const WORKER_ID = Number(process.env.JEST_WORKER_ID ?? '1');
    export const testRedis = new Redis({ host: 'localhost', port: 6400 + WORKER_ID });
    ```
    WHY: ioredis-mock's shared context was designed to mirror real Redis pub/sub testing, but it
    means the "no real server" convenience comes with the same data-isolation responsibility that
    real Redis demands. Treat it like a real cache: always flush in `afterEach` or scope by port.

110. **`jest.mock('node:fs')` and `jest.mock('fs')` are two separate module entries — mocking only one leaves the other unmocked, so code using `import * as fs from 'fs'` bypasses the memfs volume.** [community]
    Node.js has two ways to import the file system module: `'fs'` and `'node:fs'`. They are the
    same underlying module but Jest treats them as separate entries in the module registry. If your
    production code uses `import * as fs from 'fs'` and your test mocks only `'node:fs'` (or vice
    versa), the mock is silently bypassed — real disk writes occur and your `vol.existsSync()` call
    returns `false` even though the file was written. The fix: mock both in the `jest.mock` factory,
    or use `moduleNameMapper` to alias both specifiers to `memfs`:
    ```typescript
    // jest.config.ts — map both module specifiers to memfs
    import { defineConfig } from 'jest';

    export default defineConfig({
      moduleNameMapper: {
        // Map both 'fs' and 'node:fs' to the same memfs union-fs adapter
        '^(node:)?fs$': '<rootDir>/test/__mocks__/memfs-adapter.ts',
        '^(node:)?fs/promises$': '<rootDir>/test/__mocks__/memfs-promises-adapter.ts',
      },
    });
    ```
    ```typescript
    // test/__mocks__/memfs-adapter.ts
    import { createFsFromVolume, Volume } from 'memfs';
    export const vol = new Volume();
    const fs = createFsFromVolume(vol);
    export default fs;
    export const { readFileSync, writeFileSync, mkdirSync, existsSync, rmSync } = fs;
    ```
    WHY: the `node:` prefix was introduced in Node.js 14.18 / 16.0 as an explicit built-in
    protocol. Both resolve to the same native module but Jest's module resolver treats them as
    distinct keys, so a mock on one key does not automatically apply to the other.

111. **`jest.spyOn(globalThis.crypto, 'randomUUID')` fails in Jest's default `node` test environment on Node.js < 19 because `globalThis.crypto` is `undefined` — the Web Crypto API was only added to the global scope in Node.js 19.** [community]
    On Node.js 18 (LTS), `globalThis.crypto` is undefined in the `node` Jest test environment by
    default. `jest.spyOn(globalThis.crypto, 'randomUUID')` throws `TypeError: Cannot read properties
    of undefined (reading 'randomUUID')`. Two fixes:
    1. **Polyfill in `setupFilesAfterEnv`**: assign `globalThis.crypto` before spying:
    ```typescript
    // jest.setup.ts (setupFilesAfterEnv)
    import { webcrypto } from 'node:crypto';
    // Make Web Crypto available as a global so jest.spyOn works on Node.js 18
    if (!globalThis.crypto) {
      Object.defineProperty(globalThis, 'crypto', {
        value: webcrypto,
        writable: true,
        configurable: true,
      });
    }
    ```
    2. **Use the `node:crypto` module directly** and inject via DI instead of using `globalThis.crypto`:
    ```typescript
    // production code — accepts a generate function as a parameter (DI approach)
    import { randomUUID } from 'node:crypto';

    export function createOrder(
      customerId: string,
      totalCents: number,
      generateId: () => string = randomUUID,
    ): Order {
      return { id: generateId(), customerId, totalCents, status: 'pending' };
    }
    // test — pass a deterministic function; no spy or global mutation needed
    const order = createOrder('c1', 100, () => 'fixed-uuid-123');
    expect(order.id).toBe('fixed-uuid-123');
    ```
    WHY: `globalThis.crypto` being undefined is a Node.js 18 vs 19+ behavioural difference that
    does not affect the browser test environment (`testEnvironment: 'jsdom'`). Teams on Node.js 18
    LTS (still in maintenance until April 2025) frequently hit this. The DI approach (Pattern 3
    style) is more portable and avoids the global mutation entirely.

---

## Quick Reference Additions — Iteration 27

| Problem | Symptom | Solution | Framework |
|---------|---------|----------|-----------|
| Unit tests require a running Redis server | `ECONNREFUSED` in CI without Redis | Replace `ioredis` with `ioredis-mock` via `moduleNameMapper` | Jest + ioredis-mock |
| ioredis-mock state leaks between test files | Test B reads data written by Test A in a different file | Use unique port per worker or call `flushall()` in every `afterEach` | Jest + ioredis-mock |
| File I/O tests leave temp dirs or fail on permission errors | CI cleanup fails; stale files cause false passes | Replace `node:fs` with `memfs` volume; `vol.reset()` in `afterEach` | Jest/Vitest + memfs |
| Both `'fs'` and `'node:fs'` need to be mocked | `vol.existsSync()` returns false despite writes | Map both specifiers in `moduleNameMapper` to the same memfs adapter | Jest config |
| `crypto.randomUUID()` produces non-deterministic IDs | Snapshot tests fail; assertions on generated IDs are brittle | `jest.spyOn(globalThis.crypto, 'randomUUID').mockReturnValue(FIXED_UUID)` | Jest + restoreMocks |
| `globalThis.crypto` undefined on Node.js 18 | `jest.spyOn(globalThis.crypto, ...)` throws TypeError | Polyfill `globalThis.crypto` from `node:crypto` in `setupFilesAfterEnv`, or use DI | Jest + Node.js 18 |

---

## Key Resources — Iteration 27 Additions

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| ioredis-mock | GitHub | https://github.com/stipsan/ioredis-mock | In-memory ioredis emulator; `moduleNameMapper` swap; v6 shared-context behaviour |
| memfs | GitHub | https://github.com/streamich/memfs | In-memory `fs` implementation; `vol.fromJSON()` seeding, `vol.reset()`, `createFsFromVolume` |
| Node.js — `crypto.randomUUID` | Official | https://nodejs.org/docs/latest-v24.x/api/crypto.html#cryptorandomuuidoptions | Available as `node:crypto` export since Node 14.17; added to `globalThis.crypto` in Node 19 |
| Vitest — `vi.stubGlobal` | Official | https://vitest.dev/api/vi.html#vi-stubglobal | Stub any global (including `crypto`) with auto-restore via `vi.unstubAllGlobals()` |
| Vitest 4.1 Blog — aroundEach / aroundAll | Official | https://vitest.dev/blog/vitest-4-1 | `aroundEach` + `aroundAll` hooks; composition with `AsyncLocalStorage.run()` for scoped per-test context |
