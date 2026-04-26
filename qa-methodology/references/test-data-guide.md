# Test Data — QA Methodology Guide
<!-- lang: TypeScript | topic: test-data | iteration: 0 | score: ?/100 | date: 2026-04-26 -->
<!-- sources: training-knowledge (WebFetch blocked, WebSearch API unavailable; synthesized from training knowledge per skill fallback rule) -->
<!-- official refs: martinfowler.com/bliki/ObjectMother.html · martinfowler.com/bliki/TestDouble.html -->

---

## Core Principles

### 1. Tests need data — but data should not own tests
Test data is infrastructure. When tests couple tightly to raw database seeds or hardcoded literals, every schema change ripples across hundreds of files. Centralising data construction in factories or builders makes your tests resilient to model changes.

### 2. Isolation is not optional in parallel runs
Each test must own the data it creates. Shared rows in a database, shared in-memory objects, or shared environment variables are the single biggest source of non-deterministic failures in parallel CI. Isolation means: create → act → verify → destroy, with no side-effects visible to a sibling test.

### 3. Realistic data catches realistic bugs
Minimal mocks (`{ id: 1, name: "test" }`) miss entire classes of bugs: unicode edge cases, boundary values, null propagation, and business rules that only activate on real-looking records. Factories that optionally use random realistic data (via `@faker-js/faker`) expose these bugs at authoring time rather than in production.

### 4. Factories model your domain; fixtures model your database
A factory is a function or class that creates a valid domain object on demand, with overrides. A fixture is a static snapshot of the database state. Both have a place — but they serve different masters: factories serve unit and integration tests, fixtures serve UI smoke tests that need a known baseline.

### 5. Readable test data tells the story of the test
A test should read as a narrative: "Given a suspended user with no payment method, when checkout is attempted, then …". Builder and Object Mother patterns push you towards expressive, self-documenting data construction rather than noise-heavy inline literals.

---

## When to Use

| Context | Recommendation |
|---------|---------------|
| Unit tests for service logic | Factory functions with minimal overrides |
| Integration tests with a real DB | Factory + DB cleanup strategy (transaction rollback or truncation) |
| E2E / Playwright / Cypress runs | Fixture-seeded DB baseline + per-test factory top-up |
| Contract tests | Minimal factories for provider state setup |
| Performance / load tests | Batch factories generating large datasets |
| Snapshot / visual regression tests | Static fixtures (stable, no randomness) |

---

## Patterns

### Object Mother

The Object Mother (coined at ThoughtWorks, documented by Martin Fowler) is a class that provides named, semantically meaningful pre-configured objects. Each static method returns a well-known variant of the domain entity.

**Why it matters:** When 30 tests all need "a suspended user", they should all call `UserMother.suspended()`. When the domain definition of "suspended" changes, you fix one place.

```typescript
// user.mother.ts
import { User } from '../domain/user';

export class UserMother {
  static default(): User {
    return {
      id: 'usr-001',
      email: 'alice@example.com',
      name: 'Alice Example',
      status: 'active',
      subscriptionTier: 'free',
      createdAt: new Date('2024-01-01T00:00:00Z'),
      paymentMethodId: null,
    };
  }

  static suspended(): User {
    return {
      ...UserMother.default(),
      id: 'usr-002',
      status: 'suspended',
    };
  }

  static premiumWithPayment(): User {
    return {
      ...UserMother.default(),
      id: 'usr-003',
      subscriptionTier: 'premium',
      paymentMethodId: 'pm-stripe-abc123',
    };
  }

  static adminUser(): User {
    return {
      ...UserMother.default(),
      id: 'usr-admin-001',
      email: 'admin@example.com',
      role: 'admin',
    };
  }
}
```

**Usage in a test:**
```typescript
import { UserMother } from './user.mother';

it('blocks checkout for suspended users', () => {
  const user = UserMother.suspended();
  const result = checkoutService.initiate(user, cart);
  expect(result.status).toBe('blocked');
  expect(result.reason).toBe('account_suspended');
});
```

**Tradeoff:** Object Mothers grow large. Once you have 40+ named variants, they become as hard to maintain as the tests they serve. Switch to the Builder pattern when variants multiply.

---

### Test Data Builder  [community]

The Test Data Builder (from "Growing Object-Oriented Software, Guided by Tests" by Freeman & Pryce) uses the fluent builder pattern to construct objects with named, readable overrides. Each `with*` method returns `this`, enabling chaining.

**Why it matters:** Unlike Object Mother, the builder handles *combinatorial* variants without an exponential number of named methods. A test describes exactly the fields that matter to *that* test — making intent immediately visible.

```typescript
// user.builder.ts
import { User } from '../domain/user';

export class UserBuilder {
  private data: User = {
    id: `usr-${Math.random().toString(36).slice(2, 9)}`,
    email: 'test@example.com',
    name: 'Test User',
    status: 'active',
    subscriptionTier: 'free',
    createdAt: new Date(),
    paymentMethodId: null,
  };

  withId(id: string): this {
    this.data = { ...this.data, id };
    return this;
  }

  withEmail(email: string): this {
    this.data = { ...this.data, email };
    return this;
  }

  withStatus(status: User['status']): this {
    this.data = { ...this.data, status };
    return this;
  }

  withSubscriptionTier(tier: User['subscriptionTier']): this {
    this.data = { ...this.data, subscriptionTier: tier };
    return this;
  }

  withPaymentMethod(paymentMethodId: string): this {
    this.data = { ...this.data, paymentMethodId };
    return this;
  }

  build(): User {
    return { ...this.data };
  }
}
```

**Usage in a test:**
```typescript
import { UserBuilder } from './user.builder';

it('allows premium checkout with a valid payment method', () => {
  const user = new UserBuilder()
    .withStatus('active')
    .withSubscriptionTier('premium')
    .withPaymentMethod('pm-visa-9999')
    .build();

  const result = checkoutService.initiate(user, cart);
  expect(result.status).toBe('success');
});
```

**Combining Mother + Builder:**  [community]
A pragmatic pattern in production codebases: Object Mother methods return a Builder, not a plain object. This combines named semantic variants with ad-hoc overrides.

```typescript
// user.mother.ts (returns builder for override flexibility)
export class UserMother {
  static suspended(): UserBuilder {
    return new UserBuilder().withStatus('suspended');
  }

  static premiumWithPayment(): UserBuilder {
    return new UserBuilder()
      .withSubscriptionTier('premium')
      .withPaymentMethod('pm-stripe-abc123');
  }
}

// in a test — named variant + ad-hoc override:
const user = UserMother.suspended().withEmail('special@test.com').build();
```

---

### Factory Functions with `@faker-js/faker`  [community]

For large suites that need high-volume realistic data, a functional factory approach using `@faker-js/faker` generates diverse, realistic values by default while still accepting per-field overrides.

**Why it matters:** Static hardcoded emails like `"test@example.com"` appear in every test and can cause unique-constraint collisions in DB integration tests. Faker generates unique, realistic values per call, while overrides let individual tests pin specific values.

```typescript
// factories/user.factory.ts
import { faker } from '@faker-js/faker';
import { User } from '../domain/user';

export function buildUser(overrides: Partial<User> = {}): User {
  return {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    status: 'active',
    subscriptionTier: 'free',
    createdAt: faker.date.past({ years: 2 }),
    paymentMethodId: null,
    ...overrides,
  };
}

export function buildUserList(count: number, overrides: Partial<User> = {}): User[] {
  return Array.from({ length: count }, () => buildUser(overrides));
}
```

**Seeded randomness for reproducibility:**
```typescript
// In test setup (e.g., vitest.setup.ts or jest.setup.ts)
import { faker } from '@faker-js/faker';

beforeEach(() => {
  // Seed with a fixed value to make faker deterministic per test run
  // Use Date.now() or process.env.TEST_SEED for reproducible CI failures
  faker.seed(12345);
});
```

**Locale support for international data:**
```typescript
import { fakerDE as faker } from '@faker-js/faker'; // German locale
// or
import { faker } from '@faker-js/faker';
faker.setLocale('ja'); // Japanese names/addresses
```

---

### `factory-ts` — TypeScript-first factory library  [community]

`factory-ts` is a small library that provides a type-safe factory API specifically for TypeScript. It infers types from your domain model and enforces that factories produce complete, valid objects.

```typescript
// factories/order.factory.ts
import { makeFactory, each } from 'factory-ts';
import { faker } from '@faker-js/faker';
import { Order } from '../domain/order';

export const OrderFactory = makeFactory<Order>({
  id: each(() => faker.string.uuid()),
  userId: each(() => faker.string.uuid()),
  status: 'pending',
  items: [],
  totalCents: each(() => faker.number.int({ min: 100, max: 100000 })),
  currency: 'USD',
  createdAt: each(() => faker.date.recent()),
});

// In tests:
const order = OrderFactory.build();
const paidOrder = OrderFactory.build({ status: 'paid', totalCents: 4999 });
const orders = OrderFactory.buildList(5, { userId: 'usr-fixed-id' });
```

**Sub-factory composition:**
```typescript
import { makeFactory, each } from 'factory-ts';
import { buildUser } from './user.factory';

export const OrderWithUserFactory = makeFactory({
  order: each(() => OrderFactory.build()),
  user: each(() => buildUser()),
});
```

---

### Fixture-Based Seeding  [community]

Fixtures are static JSON/SQL/YAML datasets loaded into the database before a test suite runs. They excel at providing a known, stable baseline for E2E tests that need full application state.

```typescript
// fixtures/users.fixture.ts — static, versioned, committed to source control
export const userFixtures = [
  {
    id: 'fixture-user-001',
    email: 'alice@fixture.com',
    name: 'Alice Fixture',
    status: 'active',
    subscriptionTier: 'premium',
    paymentMethodId: 'pm-fixture-001',
    createdAt: '2024-01-01T00:00:00Z',
  },
  {
    id: 'fixture-user-002',
    email: 'bob@fixture.com',
    name: 'Bob Fixture',
    status: 'suspended',
    subscriptionTier: 'free',
    paymentMethodId: null,
    createdAt: '2024-03-15T00:00:00Z',
  },
];

// db.seed.ts — loads fixtures before e2e suite
import { db } from '../db';
import { userFixtures } from './fixtures/users.fixture';

export async function seedFixtures(): Promise<void> {
  await db.delete(users); // truncate first
  await db.insert(users).values(userFixtures);
}
```

---

### Data Isolation for Parallel Test Runs  [community]

When tests run in parallel (Jest `--runInBand` disabled, Vitest workers, Playwright parallel shards), shared data is the #1 source of flakiness. Strategies:

**Strategy 1 — Transaction rollback (per-test):**
```typescript
// vitest.setup.ts
import { db } from '../db';
import { sql } from 'drizzle-orm';

let tx: Awaited<ReturnType<typeof db.transaction>>;

beforeEach(async () => {
  // Each test wraps all DB activity in a rolled-back transaction
  tx = await db.transaction(async (trx) => trx);
});

afterEach(async () => {
  await tx.rollback();
});
```

**Strategy 2 — Unique namespace prefixing (tenant isolation):**
```typescript
// factories/user.factory.ts — add test-run prefix to IDs/emails
const TEST_RUN_ID = process.env.TEST_RUN_ID ?? `run-${Date.now()}`;

export function buildUser(overrides: Partial<User> = {}): User {
  return {
    id: `${TEST_RUN_ID}-${faker.string.uuid()}`,
    email: `${TEST_RUN_ID}-${faker.internet.email()}`,
    ...overrides,
  };
}
```

**Strategy 3 — Separate DB per worker (Vitest):**
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    pool: 'forks',
    poolOptions: {
      forks: {
        singleFork: false,
      },
    },
    globalSetup: './src/test/global-setup.ts', // provisions per-worker DB
  },
});
```

```typescript
// global-setup.ts
import { execSync } from 'child_process';

export async function setup(): Promise<void> {
  const workerId = process.env.VITEST_WORKER_ID ?? '0';
  process.env.DATABASE_URL = `postgresql://localhost/testdb_worker_${workerId}`;
  execSync(`npx prisma migrate deploy`, { env: process.env });
}
```

---

## Anti-Patterns

### 1. Giant fixture files
One `seeds.sql` file with 5,000 rows for every test module. **Why harmful:** Tests develop invisible dependencies on specific row IDs. Changing a row number breaks unrelated tests three files away. Schema changes require full manual fixture rewrites.

### 2. Hardcoded duplicate data across tests
Every test file defines its own `const user = { id: 1, email: "test@example.com" }`. **Why harmful:** When the `User` type gains a required field, the build breaks in 200 files simultaneously.

### 3. Tests that rely on insertion order
`getById(1)` assumes ID 1 exists and is the right user. **Why harmful:** Auto-increment IDs are non-deterministic in parallel runs and change with every seed order. Use factories that return the created entity's actual ID.

### 4. Factories with no type constraints
JavaScript-only factories that accept `any` and return `any` give zero build-time safety. **Why harmful:** When the domain model changes, the factory silently produces the old shape. Tests pass at build time and fail at runtime. TypeScript + `Partial<T>` overrides eliminate this class of bugs.

### 5. Faker without seeding in CI
Random data in CI with no fixed seed makes failures non-reproducible. **Why harmful:** The bug only manifests with specific data combinations. Without a logged seed value, you cannot replay the exact failure. Always log and set `faker.seed()` in CI.

### 6. Sharing builder instances between tests  [community]
```typescript
// WRONG — shared mutable builder
const baseUser = new UserBuilder().withStatus('active');

it('test A', () => baseUser.withEmail('a@test.com').build()); // mutates shared state
it('test B', () => baseUser.withEmail('b@test.com').build()); // order-dependent
```
**Why harmful:** If `withEmail` mutates `this.data` in place, test ordering determines the result. Always use `{ ...this.data }` in builder methods, or create a fresh builder per test.

---

## Real-World Gotchas  [community]

1. **[community] Faker's `email()` generates collisions in uniqueness-constrained tables.**
   `faker.internet.email()` has a finite pool. In a large test suite with 10,000+ test runs, duplicate emails hit unique DB constraints. Fix: prefix with `faker.string.uuid()` or use `faker.internet.email({ provider: faker.string.uuid() + '.test' })`.

2. **[community] Object Mother static methods sharing object references corrupt multiple tests.**
   If `UserMother.default()` returns a reference to a module-level `defaultUser` object (not a new object each call), tests that mutate the returned value corrupt the next caller. Always return a new object: `return { ...defaultUser }` or use `structuredClone()` for deep cloning.

3. **[community] Builder pattern `build()` called multiple times returns the same reference.**
   A common TypeScript gotcha: if `build()` returns `this.data` directly (not a copy), calling `builder.build()` twice and then mutating one result corrupts the other. Ensure `build()` returns `{ ...this.data }` or `structuredClone(this.data)`.

4. **[community] `factory-ts` `each()` calls are evaluated at definition time, not call time, when misconfigured.**
   If you accidentally write `id: faker.string.uuid()` instead of `id: each(() => faker.string.uuid())`, the UUID is generated once at module load and shared across every factory call. This is a silent bug — all built objects have identical IDs. Every dynamic field must use `each()`.

5. **[community] Fixture loading order matters with foreign key constraints.**
   Loading `orders` before `users` in a seeder with FK constraints causes silent truncation or hard errors depending on the DB. Use `deferred` FK constraints or a dependency-ordered seed runner. With Prisma, use `prisma.$executeRaw('SET CONSTRAINTS ALL DEFERRED')` before bulk inserts.

6. **[community] Tests that "clean up" by deleting specific rows fail in parallel runs.**
   `afterEach(() => db.delete(users).where(eq(users.email, 'test@example.com')))` deletes rows created by *other* parallel tests. Use transaction rollback, per-worker DBs, or ID-prefixed namespacing instead of targeted deletions.

7. **[community] Builder inheritance in TypeScript breaks the fluent chain return type.**
   When a `PremiumUserBuilder extends UserBuilder` and calls a parent `with*` method, the return type is `UserBuilder`, not `PremiumUserBuilder`, breaking the chain. Fix: use generics (`withId<T extends this>(id: string): T`) or use composition over inheritance.

8. **[community] Factories that persist to the DB by default cause accidental production side-effects in integration tests.**
   Some teams build "auto-persisting" factories for convenience. If the test runner's environment detection fails (pointing at staging), the factory inserts data into a real DB. Prefer explicit `buildAndSave()` vs `build()` separation so persistence is always intentional.

---

## Tradeoffs & Alternatives

### Fixture vs Factory — Detailed Tradeoffs

| Dimension | Fixtures | Factories |
|-----------|----------|-----------|
| Setup time | Fast (bulk load) | Slower (per-test construction) |
| Parallelism safety | Risky (shared rows) | Safe (isolated by design) |
| Domain model changes | High maintenance cost | Low (one place to update) |
| Test readability | Low (magic IDs) | High (self-documenting) |
| E2E smoke tests | Excellent (stable baseline) | Overkill |
| Unit / integration tests | Poor | Excellent |
| Debugging failed CI | Hard (which seed state?) | Easy (logged factory calls) |

### When NOT to use a full factory library

- **Tiny projects with < 20 test files:** plain `buildUser()` functions in a single `test-helpers.ts` are sufficient. `factory-ts` or `fishery` add onboarding overhead not justified at this scale.
- **Read-only integration tests against a shared staging DB:** factories are irrelevant; you're reading existing data.
- **Snapshot / VCR tests:** require stable, unchanging data. Factories with randomness break snapshot comparison.

### Known adoption costs

- **Faker adds ~200 KB to test bundles.** Acceptable for Node test runs; avoid importing faker in browser production bundles.
- **Builder pattern requires discipline.** A team without code review guidelines will write Object Mother methods that call builders poorly — converging on neither pattern properly.
- **Per-worker DB provisioning in CI adds ~30–60 seconds** to pipeline setup time. Weigh against the reliability gains from true isolation.

### Lighter alternatives

- **`ts-mockito`** — when you need type-safe mock objects (method stubs), not real domain data.
- **`zod-fixture`** — generates test data from Zod schemas automatically; zero factory maintenance if your domain is Zod-first.
- **`fishery`** — TypeScript factory library; comparable to `factory-ts` with a slightly more ergonomic API for nested associations.
- **`msw` (Mock Service Worker)** — for API-layer test data, MSW intercepts HTTP and returns factory-generated responses; avoids DB setup entirely for frontend tests.

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Object Mother (Fowler) | Official | https://martinfowler.com/bliki/ObjectMother.html | Canonical definition and origin |
| Test Double (Fowler) | Official | https://martinfowler.com/bliki/TestDouble.html | Vocabulary for mocks, stubs, fakes — companions to test data |
| Growing Object-Oriented Software | Book | https://www.goodreads.com/book/show/4268826 | Origin of Test Data Builder pattern (Freeman & Pryce) |
| @faker-js/faker docs | Official | https://fakerjs.dev/api/ | Full API reference for TypeScript |
| factory-ts (npm) | Library | https://www.npmjs.com/package/factory-ts | TypeScript-first factory library |
| fishery (npm) | Library | https://www.npmjs.com/package/fishery | Alternative factory library with associations |
| zod-fixture | Library | https://www.npmjs.com/package/zod-fixture | Schema-driven automatic fixture generation |
| msw (Mock Service Worker) | Library | https://mswjs.io/ | HTTP-layer test data for frontend suites |
| Vitest worker isolation docs | Official | https://vitest.dev/config/#pool | Per-worker DB setup guide |
