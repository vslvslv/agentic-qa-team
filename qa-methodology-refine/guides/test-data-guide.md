# Test Data Strategy — QA Methodology Guide
<!-- lang: TypeScript | topic: test-data | iteration: 3 | score: 100/100 | date: 2026-04-30 -->
<!-- sources: training-knowledge (WebFetch blocked, WebSearch API unavailable; synthesized from training knowledge per skill fallback rule) -->
<!-- official refs: martinfowler.com/bliki/ObjectMother.html · martinfowler.com/bliki/TestDouble.html · fakerjs.dev -->

---

> **ISTQB CTFL 4.0 terminology note:** throughout this guide, "test case" refers to a
> specific documented set of inputs, preconditions, and expected results; "test suite"
> to a collection of related test cases; "test basis" to the artefact from which test
> conditions are derived; and "test object" to the item under test. Factory and fixture
> patterns are implementation mechanisms for establishing *test preconditions* —
> they do not change ISTQB terminology, but teams should understand the distinction
> between a *test fixture* (ISTQB: setup/teardown environment) and a *fixture file*
> (a static data snapshot loaded into a database).

## Core Principles

### 1. Tests need data — but data should not own tests
Test data is infrastructure. When test cases couple tightly to raw database seeds or
hardcoded literals, every schema change ripples across hundreds of files. Centralising
data construction in factories or builders makes your test suite resilient to model
changes and keeps the *test basis* stable even as the domain evolves.

### 2. Isolation is not optional in parallel runs
Each test case must own the data it creates. Shared rows in a database, shared in-memory
objects, or shared environment variables are the single biggest source of non-deterministic
failures in parallel CI pipelines. Isolation means: create → act → verify → destroy, with
no side-effects visible to a sibling test case.

This is the **I** in FIRST (Fast, **Independent**, Repeatable, Self-validating, Timely).
Test data management is the primary mechanism for satisfying FIRST at the integration and
E2E test levels — where unit-test isolation techniques (pure functions, mocks) are
insufficient.

### 3. Realistic data catches realistic defects
Minimal mocks (`{ id: 1, name: "test" }`) miss entire classes of defects: unicode edge
cases, boundary values, null propagation, and business rules that only activate on
real-looking records. Factories that optionally use random realistic data (via
`@faker-js/faker`) surface these defects at authoring time rather than in production.

### 4. Factories model your domain; fixtures model your database
A factory is a function or class that creates a valid domain object on demand, with
overrides. A fixture is a static snapshot of the database state. Both have a place — but
they serve different test objects: factories serve unit and integration test cases;
fixtures serve UI smoke tests that need a known, stable baseline.

### 5. Readable test data tells the story of the test case
A test case should read as a narrative: "Given a suspended user with no payment method,
when checkout is attempted, then …". Builder and Object Mother patterns push you towards
expressive, self-documenting data construction rather than noise-heavy inline literals.

---

## When to Use

| Context | Recommendation |
|---------|---------------|
| Unit tests for service logic | Factory functions with minimal overrides |
| Integration tests with a real DB | Factory + DB cleanup strategy (transaction rollback or truncation) |
| E2E / Playwright / Cypress runs | Fixture-seeded DB baseline + per-test factory top-up |
| Contract tests | Minimal factories for provider state setup; derive from contract schema |
| Performance / load tests | Batch factories generating large datasets; use `buildList()` |
| Snapshot / visual regression tests | Static fixtures (stable, no randomness) |
| Frontend component / hook tests | `msw` handlers returning factory-generated JSON (no real DB needed) |
| Microservices / distributed systems | Contract-schema-derived factories; one factory per service boundary |

---

## Patterns

### Object Mother

The Object Mother (coined at ThoughtWorks, documented by Martin Fowler) is a class that
provides named, semantically meaningful pre-configured objects. Each static method returns
a well-known variant of the domain entity.

**Why it matters:** When 30 test cases all need "a suspended user", they should all call
`UserMother.suspended()`. When the domain definition of "suspended" changes, you fix one place.

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
    return { ...UserMother.default(), id: 'usr-002', status: 'suspended' };
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

**Usage in a test case:**
```typescript
import { UserMother } from './user.mother';

it('blocks checkout for suspended users', () => {
  const user = UserMother.suspended();
  const result = checkoutService.initiate(user, cart);
  expect(result.status).toBe('blocked');
  expect(result.reason).toBe('account_suspended');
});
```

**Tradeoff:** Object Mothers grow large. Once you have 40+ named variants, they become as
hard to maintain as the test cases they serve. Switch to the Builder pattern when variants
multiply.

---

### Test Data Builder  [community]

The Test Data Builder (from "Growing Object-Oriented Software, Guided by Tests" by Freeman
& Pryce) uses the fluent builder pattern to construct objects with named, readable overrides.
Each `with*` method returns `this`, enabling method chaining.

**Why it matters:** Unlike Object Mother, the builder handles *combinatorial* variants
without an exponential number of named methods. A test case describes exactly the fields
that matter to *that* test — making intent immediately visible.

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

  withId(id: string): this { this.data = { ...this.data, id }; return this; }
  withEmail(email: string): this { this.data = { ...this.data, email }; return this; }
  withStatus(status: User['status']): this { this.data = { ...this.data, status }; return this; }
  withSubscriptionTier(tier: User['subscriptionTier']): this {
    this.data = { ...this.data, subscriptionTier: tier }; return this;
  }
  withPaymentMethod(paymentMethodId: string): this {
    this.data = { ...this.data, paymentMethodId }; return this;
  }

  build(): User { return { ...this.data }; }
}
```

**Usage in a test case:**
```typescript
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
Object Mother methods returning a Builder combines named semantic variants with ad-hoc
overrides — the most pragmatic production pattern.

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

// In a test case — named variant + ad-hoc override:
const user = UserMother.suspended().withEmail('special@test.com').build();
```

---

### Factory Functions with `@faker-js/faker`  [community]

For large test suites that need high-volume realistic data, a functional factory approach
using `@faker-js/faker` generates diverse, realistic values by default while still accepting
per-field overrides.

**Why it matters:** Static hardcoded emails like `"test@example.com"` appear in every test
case and cause unique-constraint collisions in DB integration tests. Faker generates unique,
realistic values per call, while overrides let individual test cases pin specific values.

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

// Derive seed from CI env var or fallback to Date.now()
// ALWAYS log the seed so failures can be replayed with TEST_SEED=<value>
const TEST_SEED = process.env.TEST_SEED
  ? parseInt(process.env.TEST_SEED, 10)
  : Date.now();

console.log(`[test-data] faker seed: ${TEST_SEED}`);
faker.seed(TEST_SEED);
// In CI (GitHub Actions): echo "::notice title=Faker Seed::${TEST_SEED}" >> $GITHUB_OUTPUT
// To replay a specific failure: TEST_SEED=1714123456789 npx vitest run
```

**Locale support for international data:**

When testing internationalisation (i18n) logic, form validation, or address parsing, use
locale-specific faker instances to generate realistic data in the target locale.

```typescript
// factories/international.factory.ts
import { fakerDE, fakerJA, faker as fakerEN } from '@faker-js/faker';
import { Address } from '../domain/address';

// Each locale instance is fully independent — no global locale mutation
export function buildGermanAddress(overrides: Partial<Address> = {}): Address {
  return {
    id: fakerDE.string.uuid(),
    street: fakerDE.location.streetAddress(),
    city: fakerDE.location.city(),
    postalCode: fakerDE.location.zipCode(),   // German PLZ format: 5 digits
    country: 'DE',
    phoneNumber: fakerDE.phone.number(),
    ...overrides,
  };
}

export function buildJapaneseAddress(overrides: Partial<Address> = {}): Address {
  return {
    id: fakerJA.string.uuid(),
    street: fakerJA.location.streetAddress(),
    city: fakerJA.location.city(),
    postalCode: fakerJA.location.zipCode(),   // Japanese 〒 format: NNN-NNNN
    country: 'JP',
    phoneNumber: fakerJA.phone.number(),
    ...overrides,
  };
}
```

---

### `fishery` — Factory Library with DB Persistence Hooks  [community]

`fishery` (by Thoughtbot) is a TypeScript factory library designed for integration test
cases that need to persist objects to a database. Its `afterCreate` hook fires only on
`.create()` calls, keeping in-memory `.build()` calls fast and side-effect-free.

```typescript
// factories/user.factory.ts (fishery)
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';
import { User } from '../domain/user';

export const userFactory = Factory.define<User>(({ sequence }) => ({
  id: faker.string.uuid(),
  // sequence guarantees uniqueness even without faker
  email: `user-${sequence}@${faker.internet.domainName()}`,
  name: faker.person.fullName(),
  status: 'active' as const,
  subscriptionTier: 'free' as const,
  createdAt: new Date(),
  paymentMethodId: null,
}));

// In-memory only — no DB side-effects (safe for unit tests)
const user = userFactory.build({ status: 'suspended' });

// Persists to DB (for integration tests)
const savedUser = await userFactory.create({ subscriptionTier: 'premium' });

// Build / create lists
const users = userFactory.buildList(5);
const savedUsers = await userFactory.createList(3);
```

The explicit `build` vs `create` contract prevents accidental DB writes in unit tests while
making DB-persisted integration test setup ergonomic and type-safe.

---

### `factory-ts` — TypeScript-First Factory Library  [community]

`factory-ts` provides a type-safe factory API specifically for TypeScript. It infers types
from your domain model and enforces that factories produce complete, valid objects.

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

// In test cases:
const order = OrderFactory.build();
const paidOrder = OrderFactory.build({ status: 'paid', totalCents: 4999 });
const orders = OrderFactory.buildList(5, { userId: 'usr-fixed-id' });
```

**Critical:** Every dynamic field MUST use `each()`. Writing `id: faker.string.uuid()`
without `each()` generates one UUID at module load time shared across every factory call —
a silent defect that produces identical IDs across all test cases.

---

### `zod-fixture` — Schema-Driven Test Data Generation  [community]

`zod-fixture` generates TypeScript test data automatically from your existing Zod schemas.
Zero factory maintenance: when you add a field to your Zod schema, the fixture generator
produces it automatically.

```typescript
// schemas/user.schema.ts
import { z } from 'zod';

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1),
  status: z.enum(['active', 'suspended', 'pending']),
  subscriptionTier: z.enum(['free', 'premium', 'enterprise']),
  createdAt: z.date(),
  paymentMethodId: z.string().nullable(),
});

export type User = z.infer<typeof UserSchema>;
```

```typescript
// factories/user.fixture.ts (zod-fixture)
import { createFixture } from 'zod-fixture';
import { UserSchema, User } from '../schemas/user.schema';

export function buildUserFixture(overrides: Partial<User> = {}): User {
  return { ...createFixture(UserSchema), ...overrides };
}

// In a test case:
const activeUser = buildUserFixture({ status: 'active' });
const suspendedUser = buildUserFixture({ status: 'suspended', paymentMethodId: null });
```

**Tradeoff:** `zod-fixture` generates structurally valid data, not *semantically* realistic
data. For integration test cases needing realistic data, combine with `@faker-js/faker`
overrides.

---

### Playwright `test.extend()` — Composable E2E Test Data  [community]

Playwright's fixture system (`test.extend()`) scopes test data to the test or worker
lifecycle. Unlike `beforeEach`/`afterEach` hooks, Playwright fixtures are composable,
lazily evaluated, and automatically torn down.

```typescript
// fixtures/test-fixtures.ts
import { test as base, expect } from '@playwright/test';
import { userFactory } from '../factories/user.factory';
import { db } from '../db';

type TestFixtures = {
  testUser: { id: string; email: string; password: string };
  authenticatedPage: void;
};

export const test = base.extend<TestFixtures>({
  testUser: [async ({}, use) => {
    const user = await userFactory.create({
      email: `e2e-${Date.now()}@test.com`,
      password: 'Test@12345',
    });
    await use({ id: user.id, email: user.email, password: 'Test@12345' });
    // Teardown: always runs even if the test case fails
    await db.delete(users).where(eq(users.id, user.id));
  }, { scope: 'test' }],

  authenticatedPage: async ({ page, testUser }, use) => {
    await page.goto('/login');
    await page.fill('[data-testid="email"]', testUser.email);
    await page.fill('[data-testid="password"]', testUser.password);
    await page.click('[data-testid="submit"]');
    await page.waitForURL('/dashboard');
    await use();
  },
});

export { expect };
```

```typescript
// specs/checkout.spec.ts
import { test, expect } from '../fixtures/test-fixtures';

test('authenticated user can complete checkout', async ({ page, authenticatedPage }) => {
  await page.goto('/shop');
  await page.click('[data-testid="add-to-cart"]');
  await page.click('[data-testid="checkout"]');
  await expect(page.locator('[data-testid="order-confirmation"]')).toBeVisible();
});
```

---

### `msw` (Mock Service Worker) — API-Layer Test Data  [community]

For frontend/React test cases that call backend APIs, `msw` intercepts HTTP requests and
returns factory-generated JSON responses. This eliminates the need for real DB setup in
component and hook tests.

**Why it matters:** Frontend unit and integration test cases should not require a running
backend. `msw` combined with factories gives you realistic API responses without any network
calls, making test cases fast, offline-capable, and free from backend flakiness.

```typescript
// mocks/handlers.ts (msw v2)
import { http, HttpResponse } from 'msw';
import { buildUser, buildUserList } from '../factories/user.factory';

export const handlers = [
  // Return a single user by ID
  http.get('/api/users/:id', ({ params }) => {
    const user = buildUser({ id: params.id as string });
    return HttpResponse.json(user);
  }),

  // Return a paginated list of users
  http.get('/api/users', ({ request }) => {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') ?? '1', 10);
    const users = buildUserList(10, {});
    return HttpResponse.json({ data: users, total: 100, page, pageSize: 10 });
  }),

  // Simulate a 403 for suspended users
  http.post('/api/checkout', async ({ request }) => {
    const body = await request.json() as { userId: string };
    if (body.userId === 'usr-suspended') {
      return HttpResponse.json({ error: 'account_suspended' }, { status: 403 });
    }
    return HttpResponse.json({ status: 'success', orderId: 'ord-001' });
  }),
];
```

```typescript
// vitest.setup.ts — activate msw server
import { setupServer } from 'msw/node';
import { handlers } from './mocks/handlers';

const server = setupServer(...handlers);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

Per-test-case overrides for specific scenarios:
```typescript
it('shows error banner when API returns 500', async () => {
  server.use(
    http.get('/api/users', () =>
      HttpResponse.json({ error: 'Internal Server Error' }, { status: 500 })
    )
  );
  // render component and assert error state...
});
```

---

### `using` / `await using` for Test Resource Cleanup (TypeScript 5.2+)  [community]

TypeScript 5.2 introduced the `using` and `await using` declarations (Explicit Resource
Management, TC39 Stage 4). When a test helper implements `Symbol.asyncDispose()`, cleanup
is guaranteed — even on early `return` or uncaught `throw` — with no `try/finally`
boilerplate.

**Why it matters:** `beforeEach`/`afterEach` lifecycle hooks can be bypassed by an early
`return` in the test body, leaving test data in the DB and causing flakiness in subsequent
test cases. `using` ties the cleanup directly to the variable scope — the compiler enforces
it, not the test runner.

```typescript
// test-helpers/disposable-user.ts
import { db, users } from '../db';
import { userFactory } from '../factories/user.factory';
import { eq } from 'drizzle-orm';

export class DisposableUser implements AsyncDisposable {
  constructor(
    public readonly id: string,
    public readonly email: string,
  ) {}

  // Automatically called when `await using` variable goes out of scope
  async [Symbol.asyncDispose](): Promise<void> {
    await db.delete(users).where(eq(users.id, this.id));
  }
}

export async function createDisposableUser(
  overrides?: Partial<{ email: string; subscriptionTier: string }>
): Promise<DisposableUser> {
  const created = await userFactory.create(overrides);
  return new DisposableUser(created.id, created.email);
}
```

```typescript
// specs/checkout.test.ts — cleanup is guaranteed even on early return
import { test, expect } from 'vitest';
import { createDisposableUser } from '../test-helpers/disposable-user';

test('blocked checkout returns account_suspended', async () => {
  // Cleanup fires automatically when the test function returns (or throws)
  await using user = await createDisposableUser({ status: 'suspended' });

  const result = await checkoutService.initiate(user.id, cart);
  expect(result.status).toBe('blocked');
  expect(result.reason).toBe('account_suspended');
  // No afterEach needed — user row deleted as `user` goes out of scope
});
```

**Requires:** `"target": "ES2022"` or higher and `"lib": ["es2022", "esnext.disposable"]`
in `tsconfig.json`. Compatible with Vitest ≥ 1.4 and Node ≥ 22.

---

### Data Isolation for Parallel Test Runs  [community]

When test cases run in parallel, shared data is the #1 source of flakiness. Key strategies:

**Strategy 1 — Transaction rollback (per-test case):**
```typescript
// vitest.setup.ts (Drizzle ORM example)
import { db } from '../db';

let rollback: () => Promise<void>;

beforeEach(async () => {
  await new Promise<void>((resolve, reject) => {
    db.transaction(async (trx) => {
      rollback = async () => { await trx.rollback(); };
      await new Promise<void>((innerResolve) => {
        (globalThis as any).__resolveTestTx = innerResolve;
      });
    }).catch(reject);
    setImmediate(resolve);
  });
});

afterEach(async () => {
  (globalThis as any).__resolveTestTx?.();
  await rollback?.();
});
```

**Strategy 2 — Unique namespace prefixing:**
```typescript
const TEST_RUN_ID = process.env.TEST_RUN_ID ?? `run-${Date.now()}`;

export function buildUser(overrides: Partial<User> = {}): User {
  return {
    id: `${TEST_RUN_ID}-${faker.string.uuid()}`,
    email: `${TEST_RUN_ID}-${faker.internet.email()}`,
    ...overrides,
  };
}
```

**Strategy 3 — Per-worker DB (Vitest):**
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    pool: 'vmForks',
    poolOptions: { vmForks: { singleFork: false } },
    globalSetup: './src/test/global-setup.ts',
  },
});
```

**Cleanup Strategy Decision Tree:**

```
Test type?
├─ Unit tests (no DB)           → No cleanup needed; factories produce in-memory objects
├─ Integration tests (real DB)
│   ├─ Sequential runs?         → Transaction rollback (simplest; BEGIN/ROLLBACK per test)
│   ├─ Parallel runs?
│   │   ├─ ORM supports tx?     → Transaction rollback with worker-scoped connection pool
│   │   ├─ Can provision DBs?   → Per-worker database (strongest isolation; ~30–60s setup cost)
│   │   └─ Can't provision DBs? → ID/email namespace prefixing (weakest; verify no FK issues)
│   └─ Shared staging DB?       → Read-only tests only; never write with factories
└─ E2E / Playwright tests       → Fixture seed at suite start + factory top-up per test
                                   Teardown: truncate tables in FK-dependency order after suite
```

---

### Prisma-First Factory Pattern  [community]

In TypeScript projects using Prisma ORM, factories that leverage Prisma's generated types
provide zero-maintenance type safety: when the Prisma schema changes, TypeScript compilation
immediately surfaces factory updates needed — no separate type file to keep in sync.

**Why it matters:** The most common factory drift defect is a changed database column that
is reflected in `prisma/schema.prisma` but not in the hand-written `User` interface used
by the factory. Basing factories on `Prisma.UserCreateInput` eliminates this class of
divergence entirely.

```typescript
// factories/user.factory.ts (Prisma-native)
import { Prisma, PrismaClient } from '@prisma/client';
import { faker } from '@faker-js/faker';

const prisma = new PrismaClient();

// Type is derived from Prisma's generated schema — zero manual maintenance
export function buildUserInput(
  overrides: Partial<Prisma.UserCreateInput> = {}
): Prisma.UserCreateInput {
  return {
    email: faker.internet.email(),
    name: faker.person.fullName(),
    status: 'ACTIVE',
    subscriptionTier: 'FREE',
    createdAt: new Date(),
    ...overrides,
  };
}

// Persists to DB and returns the full Prisma User model
export async function createUser(
  overrides: Partial<Prisma.UserCreateInput> = {}
) {
  return prisma.user.create({ data: buildUserInput(overrides) });
}

// In-memory only — no DB write (for unit test cases)
export function buildUser(overrides: Partial<Prisma.UserCreateInput> = {}) {
  return { id: faker.string.uuid(), ...buildUserInput(overrides) };
}
```

```typescript
// Wrap in a transaction and rollback after each integration test case
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

beforeEach(async () => {
  // Use $transaction with a held Promise to keep the connection open
  await prisma.$transaction(async (client) => {
    (globalThis as any).__testPrisma = client;
    await new Promise<void>((resolve) => {
      (globalThis as any).__resolveTx = resolve;
    });
  }).catch(() => { /* rollback is expected */ });
});

afterEach(() => {
  (globalThis as any).__resolveTx?.();
});
```

---

### Cross-Language Equivalents  [community]

The same patterns apply across languages. TypeScript's factory libraries map to:

| TypeScript | Ruby | Python | C# | Java |
|---|---|---|---|---|
| `fishery` | `factory_bot` | `FactoryBoy` | `AutoFixture` | `Instancio` / `easy-random` |
| `factory-ts` | `factory_bot` (DSL) | `FactoryBoy` (class-based) | `AutoFixture` (reflection) | `Instancio` (reflection) |
| `zod-fixture` | — | — | `AutoFixture` | `Instancio` |
| `@faker-js/faker` | `Faker` gem | `Faker` library | `Bogus` / `AutoBogus` | `JavaFaker` |

**`factory_bot` (Ruby)** — DSL-based with `FactoryBot.create(:user, status: :suspended)`.
Traits map directly to Object Mother named variants. Previously known as `factory_girl`
(renamed in v5 for inclusivity; older codebases may reference it under the old name).
`factory_girl` and `factory_bot` share the same API — any legacy guide referencing
`factory_girl` applies directly.

**`FactoryBoy` (Python)** — class-based with `factory.LazyAttribute` for dynamic fields:
```python
import factory
from factory.faker import Faker

class UserFactory(factory.Factory):
    class Meta:
        model = User

    id = factory.LazyFunction(lambda: str(uuid.uuid4()))
    email = Faker('email')
    name = Faker('name')
    status = 'active'
```

**`AutoFixture` (C#)** — reflection-based automatic property population (equivalent to
`zod-fixture`'s zero-maintenance approach). Creates fully populated objects without manual
field specification:
```csharp
var fixture = new Fixture();
var user = fixture.Create<User>();
var suspendedUser = fixture.Build<User>()
    .With(u => u.Status, UserStatus.Suspended)
    .Create();
```

---

### Fixture-Based Seeding  [community]

Fixtures are static datasets loaded before a test suite runs. They excel at providing a
known, stable baseline for E2E test cases.

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

// db.seed.ts — loads fixtures before E2E test suite
import { db } from '../db';
import { userFixtures } from './fixtures/users.fixture';

export async function seedFixtures(): Promise<void> {
  await db.delete(users); // truncate first
  await db.insert(users).values(userFixtures);
}
```

---

## Anti-Patterns

### 1. Giant fixture files
One `seeds.sql` file with 5,000 rows for every test module. **Why harmful:** Test cases
develop invisible dependencies on specific row IDs. Changing a row number breaks unrelated
test cases three files away. Schema changes require full manual fixture rewrites.

### 2. Hardcoded duplicate data across test cases
Every test file defines its own `const user = { id: 1, email: "test@example.com" }`.
**Why harmful:** When the `User` type gains a required field, the build breaks in 200 files
simultaneously.

### 3. Test cases that rely on insertion order
`getById(1)` assumes ID 1 exists and is the right user. **Why harmful:** Auto-increment IDs
are non-deterministic in parallel runs and change with every seed order. Use factories that
return the created entity's actual ID.

### 4. Factories with no type constraints
JavaScript-only factories that accept `any` and return `any` give zero build-time safety.
**Why harmful:** When the domain model changes, the factory silently produces the old shape.
Use TypeScript + `Partial<T>` overrides to surface these defects at compile time.

### 5. Faker without seeding in CI
Random data in CI with no fixed seed makes failures non-reproducible. **Why harmful:** The
defect only manifests with specific data combinations. Without a logged seed value, you
cannot replay the exact failure. Always log and set `faker.seed()` in CI.

### 6. Sharing builder instances between test cases  [community]
```typescript
// WRONG — shared mutable builder
const baseUser = new UserBuilder().withStatus('active');
it('test A', () => baseUser.withEmail('a@test.com').build()); // mutates shared state
it('test B', () => baseUser.withEmail('b@test.com').build()); // order-dependent
```
**Why harmful:** If `withEmail` mutates `this.data` in place, test-case ordering determines
the result. Always use `{ ...this.data }` in builder methods, or create a fresh builder per
test case.

### 7. Deprecated `@faker-js/faker` v8 API in v9+ projects  [community]
`faker.name.firstName()`, `faker.address.city()`, `faker.datatype.uuid()` were removed in
v9. Factories that upgrade faker without updating calls silently break. Run
`npx @faker-js/faker-codemod` to migrate automatically.

| v8 (removed) | v9+ (current) |
|---|---|
| `faker.datatype.uuid()` | `faker.string.uuid()` |
| `faker.name.firstName()` | `faker.person.firstName()` |
| `faker.address.city()` | `faker.location.city()` |

---

## Real-World Gotchas  [community]

1. **[community] Faker's `email()` generates collisions in uniqueness-constrained tables.**
   `faker.internet.email()` has a finite pool. In a large test suite with 10,000+ test
   runs, duplicate emails hit unique DB constraints. Fix: prefix with `faker.string.uuid()`
   or use the `sequence` parameter from `fishery`.

2. **[community] Object Mother static methods sharing object references corrupt multiple test cases.**
   If `UserMother.default()` returns a reference to a module-level `defaultUser` object
   (not a new object each call), test cases that mutate the returned value corrupt the next
   caller. Always return a new object: `return { ...defaultUser }` or use
   `structuredClone()` for deep cloning.

3. **[community] `factory-ts` `each()` calls evaluated at definition time when misconfigured.**
   Writing `id: faker.string.uuid()` instead of `id: each(() => faker.string.uuid())`
   generates one UUID at module load shared across every factory call — all built objects
   have identical IDs. Every dynamic field must use `each()`.

4. **[community] Fixture loading order matters with foreign key constraints.**
   Loading `orders` before `users` in a seeder with FK constraints causes silent truncation
   or hard errors. Use deferred FK constraints or a dependency-ordered seed runner.

5. **[community] Test cases that "clean up" by deleting specific rows fail in parallel runs.**
   `afterEach(() => db.delete(users).where(eq(users.email, 'test@example.com')))` deletes
   rows created by *other* parallel test cases. Use transaction rollback, per-worker DBs,
   or ID-prefixed namespacing instead of targeted deletions.

6. **[community] Factory ownership divergence is the most common long-term maintenance failure mode.**
   After 18 months, the same `UserFactory` exists in three places with subtly different
   defaults — test cases in different modules build different `User` shapes, hiding
   cross-module integration defects. Designate a single source of truth: one factory per
   domain entity in a shared `test/factories/` directory, reviewed as rigorously as
   production code.

7. **[community] In microservices, factories produce data shapes that silently diverge from
   what partner services send over the wire.**
   A `UserFactory.build()` in the Orders service produces `{ id, email, name }` but the
   Users service now sends `{ userId, emailAddress, displayName }` after a field rename.
   Orders service test cases still pass; production breaks. Fix: derive factories from the
   **contract schema** (Pact, OpenAPI, JSON Schema) rather than local domain types.

8. **[community] ORM-generated types drift from hand-written factory types when migrations
   are not regenerated.**
   In Prisma projects: developer adds a required `phoneNumber` column, runs migrations, but
   the hand-written `User` interface in the factory is not updated. The factory builds
   objects without `phoneNumber`; `prisma.user.create()` throws at runtime. Fix: base
   factory types on `Prisma.UserCreateInput` (the generated type) rather than a manual
   interface.

9. **[community] `using` / `await using` resource cleanup silently no-ops on Node < 22 without a polyfill.**
   TypeScript 5.2+ `await using` calls `Symbol.asyncDispose()` at scope exit, but only if
   the runtime supports the TC39 Explicit Resource Management proposal. On Node 18 without
   `core-js/proposals/explicit-resource-management`, the `[Symbol.asyncDispose]` method is
   never called — test data leaks silently. Add a startup assertion:
   `if (typeof Symbol.asyncDispose === 'undefined') throw new Error('Upgrade Node or add polyfill')`.

10. **[community] Builder `build()` called multiple times returns the same reference when
    `this.data` is not cloned.**
    A TypeScript gotcha: if `build()` returns `this.data` directly (not a copy), calling
    `builder.build()` twice and mutating one result corrupts the other. Ensure `build()`
    returns `{ ...this.data }` or `structuredClone(this.data)` for nested objects.

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

- **Tiny projects with < 20 test files:** plain `buildUser()` functions in a single
  `test-helpers.ts` are sufficient. `factory-ts` or `fishery` add onboarding overhead not
  justified at this scale.
- **Read-only integration tests against a shared staging DB:** factories are irrelevant;
  you are reading existing data.
- **Snapshot / VCR test cases:** require stable, unchanging data. Factories with randomness
  break snapshot comparison.
- **Event-sourced / CQRS systems:** factories produce state snapshots, but event-sourced
  systems store *commands and events*, not entity state. Use an `EventBuilder` or replaying
  domain commands instead of entity-state factories.

### Known adoption costs

- **Faker adds ~200 KB to test bundles.** Acceptable for Node test runs; avoid importing
  faker in browser production bundles.
- **Builder pattern requires discipline.** A team without code review guidelines will write
  Object Mother methods that call builders poorly — converging on neither pattern properly.
- **Per-worker DB provisioning in CI adds ~30–60 seconds** to pipeline setup time. Weigh
  against the reliability gains from true isolation.

### Lighter alternatives

- **`ts-mockito`** — when you need type-safe mock objects (method stubs), not real domain
  data.
- **`zod-fixture`** — generates test data from Zod schemas automatically; zero factory
  maintenance if your domain is Zod-first.
- **`msw` (Mock Service Worker)** — for API-layer test data, MSW intercepts HTTP and
  returns factory-generated responses; avoids DB setup entirely for frontend tests.

### Library Comparison

| Library | Type Safety | `build()` vs `create()` | Best For |
|---|---|---|---|
| `@faker-js/faker` v9 | n/a (primitive) | n/a | Data primitive inside builders |
| `factory-ts` | Full (generics) | `build` only | Mid-size TS projects; no DB persistence |
| `fishery` | Full (generics) | `build` + `create` (DB hooks) | Integration tests needing DB persistence |
| `zod-fixture` | Schema-driven | `build` only | Zod-first codebases |
| Plain builder class | Full | Manual | Zero-dependency projects |

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Object Mother (Fowler) | Official | https://martinfowler.com/bliki/ObjectMother.html | Canonical definition and origin |
| Test Double (Fowler) | Official | https://martinfowler.com/bliki/TestDouble.html | Vocabulary for mocks, stubs, fakes |
| Growing Object-Oriented Software | Book | https://www.goodreads.com/book/show/4268826 | Origin of Test Data Builder pattern |
| @faker-js/faker docs | Official | https://fakerjs.dev/api/ | Full API reference for TypeScript |
| factory-ts (npm) | Library | https://www.npmjs.com/package/factory-ts | TypeScript-first factory library |
| fishery (npm) | Library | https://www.npmjs.com/package/fishery | Factory with DB persistence hooks |
| zod-fixture | Library | https://www.npmjs.com/package/zod-fixture | Schema-driven fixture generation |
| msw (Mock Service Worker) | Library | https://mswjs.io/ | HTTP-layer test data for frontend |
| Playwright test fixtures | Official | https://playwright.dev/docs/test-fixtures | Composable E2E fixture lifecycle |
| TC39 Explicit Resource Management | Proposal | https://github.com/tc39/proposal-explicit-resource-management | `using`/`await using` — scoped test resource cleanup |
| Pact.io | Official | https://docs.pact.io/ | Contract-schema-driven factories for microservices |
| Prisma ORM | Official | https://www.prisma.io/docs | `Prisma.UserCreateInput` for zero-drift factories |
| FactoryBoy (Python) | Library | https://factoryboy.readthedocs.io/ | Python equivalent of fishery |
| factory_bot (Ruby) | Library | https://github.com/thoughtbot/factory_bot | Ruby DSL-based factory library |
| AutoFixture (C#) | Library | https://github.com/AutoFixture/AutoFixture | C# reflection-based auto-fixture |
