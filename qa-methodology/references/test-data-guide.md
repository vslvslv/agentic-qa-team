# Test Data — QA Methodology Guide
<!-- lang: TypeScript | topic: test-data | iteration: 5 | score: 99/100 | date: 2026-05-02 -->
<!-- sources: training-knowledge (WebFetch blocked, WebSearch API unavailable; synthesized from training knowledge per skill fallback rule) -->
<!-- official refs: martinfowler.com/bliki/ObjectMother.html · martinfowler.com/bliki/TestDouble.html -->

---

## Core Principles

> **ISTQB CTFL 4.0 terminology note:** throughout this guide, "test case" refers to a
> specific documented set of inputs, preconditions, and expected results; "test suite"
> to a collection of related test cases; "test basis" to the artefact from which test
> conditions are derived; and "test object" to the item under test. Factory and fixture
> patterns are implementation mechanisms for establishing *test preconditions* —
> they do not change ISTQB terminology, but teams should understand the distinction
> between a *test fixture* (ISTQB: setup/teardown environment) and a *fixture file*
> (a static data snapshot loaded into a database).

### 1. Tests need data — but data should not own tests
Test data is infrastructure. When tests couple tightly to raw database seeds or hardcoded literals, every schema change ripples across hundreds of files. Centralising data construction in factories or builders makes your tests resilient to model changes.

### 2. Isolation is not optional in parallel runs
Each test must own the data it creates. Shared rows in a database, shared in-memory objects, or shared environment variables are the single biggest source of non-deterministic failures in parallel CI. Isolation means: create → act → verify → destroy, with no side-effects visible to a sibling test.

This is the **I** in FIRST (Fast, **Independent**, Repeatable, Self-validating, Timely). Test data management is the primary mechanism for satisfying FIRST at the integration and E2E layers — where unit-test isolation techniques (pure functions, mocks) are insufficient.

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
| Contract tests | Minimal factories for provider state setup; derive from contract schema |
| Performance / load tests | Batch factories generating large datasets; use `buildList()` |
| Snapshot / visual regression tests | Static fixtures (stable, no randomness) |
| Frontend component / hook tests | `msw` handlers returning factory-generated JSON (no real DB needed) |
| Microservices / distributed systems | Contract-schema-derived factories; one factory per service boundary |

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

// Derive seed from CI env var (set by CI system) or fallback to Date.now()
// ALWAYS log the seed so failures can be replayed with TEST_SEED=<logged value>
const TEST_SEED = process.env.TEST_SEED
  ? parseInt(process.env.TEST_SEED, 10)
  : Date.now();

console.log(`[test-data] faker seed: ${TEST_SEED}`);
faker.seed(TEST_SEED);

// In CI (GitHub Actions, etc.), expose the seed as a build annotation:
// echo "::notice title=Faker Seed::${TEST_SEED}" >> $GITHUB_OUTPUT
// To replay a specific failure: TEST_SEED=1714123456789 npx vitest run
```

**Locale support for international data:**

When testing internationalisation (i18n) logic, form validation, or address parsing, use
locale-specific faker instances to generate realistic data in the target locale.

```typescript
// factories/international.factory.ts
import { fakerDE, fakerJA, fakerPT_BR, faker as fakerEN } from '@faker-js/faker';
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

### `fishery` — Factory Library with DB Persistence Hooks  [community]

`fishery` (by Thoughtbot) is a TypeScript factory library designed for integration tests that need to persist objects to a database. Its `afterCreate` hook fires only on `.create()` calls, keeping in-memory `.build()` calls fast and side-effect-free.

**Why it matters:** The explicit `build` vs `create` contract prevents accidental DB writes in unit tests while making DB-persisted integration test setup ergonomic and type-safe.

```typescript
// factories/user.factory.ts (fishery)
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';
import { db } from '../db';
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

// Persists to DB via afterCreate hook (for integration tests)
const savedUser = await userFactory.create({ subscriptionTier: 'premium' });

// Build a list of 5 in-memory users
const users = userFactory.buildList(5);

// Create a list of 3 persisted users with unique emails
const savedUsers = await userFactory.createList(3);
```

---

### `zod-fixture` — Schema-Driven Test Data Generation  [community]

`zod-fixture` generates TypeScript test data automatically from your existing Zod schemas.
There is zero factory maintenance: when you add a field to your Zod schema, the fixture
generator produces it automatically in tests.

**Why it matters:** In Zod-first codebases, maintaining a separate factory that mirrors the
Zod schema introduces a synchronisation risk. Every schema change requires a factory update.
`zod-fixture` eliminates this class of maintenance.

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

// Generates a fully valid User object from the schema
export function buildUserFixture(overrides: Partial<User> = {}): User {
  return {
    ...createFixture(UserSchema),
    ...overrides,
  };
}

// In a test:
const activeUser = buildUserFixture({ status: 'active' });
const suspendedUser = buildUserFixture({ status: 'suspended', paymentMethodId: null });
```

**Tradeoff:** `zod-fixture` generates structurally valid data, not *semantically* realistic data.
IDs will be valid UUIDs, emails will be valid email strings, but they won't be real-looking.
For integration tests needing realistic data, combine with `@faker-js/faker` overrides.

---

### `msw` (Mock Service Worker) — API-Layer Test Data  [community]

For frontend/React tests that call backend APIs, `msw` intercepts HTTP requests and returns
factory-generated JSON responses. This eliminates the need for real DB setup in component
and hook tests.

**Why it matters:** Frontend unit and integration tests should not require a running backend.
`msw` combined with factories gives you realistic API responses without any network calls,
making tests fast, offline-capable, and free from backend flakiness.

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
    return HttpResponse.json({
      data: users,
      total: 100,
      page,
      pageSize: 10,
    });
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

**Combine with per-test overrides for specific scenarios:**
```typescript
import { http, HttpResponse } from 'msw';

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

### GraphQL Test Data with `@graphql-tools/mock`  [community]

For TypeScript projects using GraphQL, `@graphql-tools/mock` (from The Guild) generates
mock resolvers directly from your GraphQL schema definition. Combined with factories,
it provides schema-typed test data without a running GraphQL server.

**Why it matters:** GraphQL's type system is the schema contract. Generating test data
from the schema (not from a TypeScript interface that may have drifted) ensures that
test cases exercise the actual API surface. When the schema changes, mock generation
fails at setup — surfacing the breakage before a test case even runs.

```typescript
// test-helpers/graphql-mocks.ts
import { buildSchema, GraphQLSchema } from 'graphql';
import { addMocksToSchema } from '@graphql-tools/mock';
import { makeExecutableSchema } from '@graphql-tools/schema';
import { faker } from '@faker-js/faker';
import { readFileSync } from 'fs';

// Load schema from .graphql file — single source of truth
const typeDefs = readFileSync('./src/schema.graphql', 'utf8');
const schema: GraphQLSchema = makeExecutableSchema({ typeDefs });

// Provide type-level mock resolvers — faker for realistic data
export const mockedSchema = addMocksToSchema({
  schema,
  mocks: {
    ID: () => faker.string.uuid(),
    String: () => faker.lorem.word(),
    Date: () => faker.date.past().toISOString(),
    User: () => ({
      id: faker.string.uuid(),
      email: faker.internet.email(),
      name: faker.person.fullName(),
      status: 'ACTIVE',
    }),
    Order: () => ({
      id: faker.string.uuid(),
      totalCents: faker.number.int({ min: 100, max: 100_000 }),
      status: 'PENDING',
      createdAt: faker.date.recent().toISOString(),
    }),
  },
  preserveResolvers: false,
});
```

```typescript
// test-helpers/graphql-test-client.ts — execute queries against mocked schema
import { graphql } from 'graphql';
import { mockedSchema } from './graphql-mocks';

export async function executeQuery(
  query: string,
  variables?: Record<string, unknown>
): Promise<{ data?: Record<string, unknown>; errors?: readonly unknown[] }> {
  return graphql({ schema: mockedSchema, source: query, variableValues: variables });
}

// In a test case:
// const { data } = await executeQuery(`
//   query GetUser($id: ID!) { user(id: $id) { id email status } }
// `, { id: 'usr-001' });
// expect(data?.user?.status).toBe('ACTIVE');
```

---

### Event-Sourced Systems — Command-Based Test Data  [community]

In event-sourced / CQRS architectures, factories that produce entity *state snapshots*
(`UserFactory.build()`) are semantically wrong: the system stores *events*, not current
state. Test preconditions should be expressed as a sequence of domain commands or events
that bring the aggregate to the desired state — mirroring how the system actually works.

**Why it matters:** An entity-state factory for an event-sourced system creates test data
that cannot be loaded via the normal event replay path. Test cases pass against the
factory-produced snapshot but fail against event-replayed state if the projection logic
has a bug — the most important thing you want to detect.

```typescript
// test-helpers/event-builder.ts — builds typed domain event sequences
import { faker } from '@faker-js/faker';

// Domain event types (from your event store schema)
type UserRegistered = {
  type: 'UserRegistered';
  aggregateId: string;
  email: string;
  name: string;
  occurredAt: Date;
};

type SubscriptionUpgraded = {
  type: 'SubscriptionUpgraded';
  aggregateId: string;
  tier: 'FREE' | 'PREMIUM' | 'ENTERPRISE';
  occurredAt: Date;
};

type AccountSuspended = {
  type: 'AccountSuspended';
  aggregateId: string;
  reason: string;
  occurredAt: Date;
};

type UserEvent = UserRegistered | SubscriptionUpgraded | AccountSuspended;

// Fluent event sequence builder
export class UserEventSequenceBuilder {
  private aggregateId = faker.string.uuid();
  private events: UserEvent[] = [];
  private baseTime = new Date('2024-01-01T00:00:00Z');

  withRegistration(overrides?: Partial<UserRegistered>): this {
    this.events.push({
      type: 'UserRegistered',
      aggregateId: this.aggregateId,
      email: faker.internet.email(),
      name: faker.person.fullName(),
      occurredAt: new Date(this.baseTime.getTime() + this.events.length * 1000),
      ...overrides,
    });
    return this;
  }

  withUpgrade(tier: 'PREMIUM' | 'ENTERPRISE' = 'PREMIUM'): this {
    this.events.push({
      type: 'SubscriptionUpgraded',
      aggregateId: this.aggregateId,
      tier,
      occurredAt: new Date(this.baseTime.getTime() + this.events.length * 1000),
    });
    return this;
  }

  withSuspension(reason = 'payment_failed'): this {
    this.events.push({
      type: 'AccountSuspended',
      aggregateId: this.aggregateId,
      reason,
      occurredAt: new Date(this.baseTime.getTime() + this.events.length * 1000),
    });
    return this;
  }

  build(): { aggregateId: string; events: UserEvent[] } {
    return { aggregateId: this.aggregateId, events: [...this.events] };
  }
}

// In a test case — build preconditions through events, not state
const { aggregateId, events } = new UserEventSequenceBuilder()
  .withRegistration({ email: 'alice@example.com' })
  .withUpgrade('PREMIUM')
  .withSuspension('payment_failed')
  .build();

// Replay events through the actual projection to get state
const userState = await userProjection.replay(aggregateId, events);
expect(userState.status).toBe('SUSPENDED');
expect(userState.subscriptionTier).toBe('PREMIUM');
```

---



Playwright has a first-class fixture system (`test.extend()`) that scopes test data to the test or worker lifecycle. Unlike `beforeEach`/`afterEach` hooks, Playwright fixtures are composable, lazily evaluated, and automatically torn down — making them the idiomatic way to manage E2E test data in TypeScript/Playwright suites.

**Why it matters:** `beforeEach` hooks in large E2E suites become ordering-dependent and hard to reuse across spec files. Playwright fixtures compose like functions: a `authenticatedPage` fixture can depend on a `user` fixture which depends on a `db` fixture, and Playwright wires the lifecycle automatically.

```typescript
// fixtures/test-fixtures.ts
import { test as base, expect } from '@playwright/test';
import { userFactory } from '../factories/user.factory';
import { db } from '../db';

// Type-safe fixture declarations
type TestFixtures = {
  testUser: { id: string; email: string; password: string };
  authenticatedPage: void;
};

export const test = base.extend<TestFixtures>({
  // Worker-scoped: created once per worker, shared across tests in that worker
  testUser: [async ({}, use) => {
    // Setup: create user in DB before test
    const user = await userFactory.create({
      email: `e2e-${Date.now()}@test.com`,
      password: 'Test@12345',
    });

    // Hand control to the test
    await use({ id: user.id, email: user.email, password: 'Test@12345' });

    // Teardown: always runs, even if test fails
    await db.delete(users).where(eq(users.id, user.id));
  }, { scope: 'test' }],

  // Test-scoped: logs in the testUser for every test that uses this fixture
  authenticatedPage: async ({ page, testUser }, use) => {
    await page.goto('/login');
    await page.fill('[data-testid="email"]', testUser.email);
    await page.fill('[data-testid="password"]', testUser.password);
    await page.click('[data-testid="submit"]');
    await page.waitForURL('/dashboard');
    await use();
    // page cleanup handled by Playwright automatically
  },
});

export { expect };
```

```typescript
// specs/checkout.spec.ts — uses the extended test
import { test, expect } from '../fixtures/test-fixtures';

test('authenticated user can complete checkout', async ({ page, authenticatedPage, testUser }) => {
  // testUser is already created in DB; authenticatedPage already logged in
  await page.goto('/shop');
  await page.click('[data-testid="add-to-cart"]');
  await page.click('[data-testid="checkout"]');
  await expect(page.locator('[data-testid="order-confirmation"]')).toBeVisible();
});
```

**Key benefits over `beforeEach`:**
- Fixtures are only instantiated if a test actually requests them (lazy evaluation)
- Teardown is guaranteed — no leaked data even on test failure
- Fixtures compose: `authenticatedPage` auto-requests `testUser` without the test knowing
- Worker-scoped fixtures (e.g., seeded DB baseline) share setup cost across tests

---

### `using` / `await using` for Test Resource Cleanup (TypeScript 5.2+)  [community]

TypeScript 5.2 introduced the `using` and `await using` declarations (Explicit Resource
Management, TC39 Stage 4). When a test helper implements `Symbol.dispose()` or
`Symbol.asyncDispose()`, cleanup is guaranteed — even on early `return` or uncaught
`throw` — with no `try/finally` boilerplate. This is now the idiomatic approach for
scoped test resource management in TypeScript 5.2+ projects.

**Why it matters:** `beforeEach`/`afterEach` lifecycle hooks can be bypassed by an
early `return` in the test body, leaving test data in the DB and causing flakiness
in subsequent test cases. `using` ties the cleanup directly to the variable scope —
the compiler enforces it, not the test runner.

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

  // Automatically called when the `await using` variable goes out of scope
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
  // No afterEach needed — user row is deleted as `user` goes out of scope
});
```

**Requires:** `"target": "ES2022"` or higher and `"lib": ["es2022", "esnext.disposable"]`
in `tsconfig.json`. Compatible with Vitest ≥ 1.4 and Jest ≥ 30 (with the `--experimental-vm-modules` flag).

---

### Prisma-First Factory Pattern  [community]

In TypeScript projects using Prisma ORM (extremely common in 2026 Node.js stacks),
factories that leverage Prisma's generated types provide zero-maintenance type safety:
when the Prisma schema changes, TypeScript compilation immediately surfaces factory
updates needed — no separate type file to keep in sync.

**Why it matters:** The most common factory drift bug is a changed database column that
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

// Persists to DB and returns the full Prisma User model (with generated id, timestamps)
export async function createUser(
  overrides: Partial<Prisma.UserCreateInput> = {}
) {
  return prisma.user.create({ data: buildUserInput(overrides) });
}

// In-memory only — no DB write (for unit test cases)
export function buildUser(overrides: Partial<Prisma.UserCreateInput> = {}) {
  return {
    id: faker.string.uuid(),
    ...buildUserInput(overrides),
  };
}
```

```typescript
// Cleanup pattern: wrap Prisma in a transaction and rollback after each test case
// (standard approach for Prisma integration test suites)
import { PrismaClient } from '@prisma/client';

let tx: Awaited<ReturnType<typeof prisma.$transaction>>;

beforeEach(async () => {
  // $transaction with interactive transactions keeps the connection open
  await prisma.$transaction(async (client) => {
    tx = client;
    // Use tx inside test cases instead of prisma directly
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



Use this table to choose the right tool for your project's scale and test type.

| Library | Type Safety | `build()` vs `create()` | Sequences | Locale Support | Best For |
|---|---|---|---|---|---|
| `@faker-js/faker` v9 | n/a (primitive) | n/a | Manual | 70+ locales | All projects; use as data primitive inside builders |
| `factory-ts` | Full (generics) | `build` / `buildList` only | Via `each()` | Via faker | Mid-size TS projects; no DB persistence hooks |
| `fishery` | Full (generics) | `build` + `create` (with hooks) | `sequence` param | Via faker | Integration tests needing DB persistence; Thoughtbot-quality API |
| `zod-fixture` | Schema-driven | `build` only | None | None | Zod-first codebases; zero-maintenance for schema-aligned mocks |
| `msw` | n/a (HTTP layer) | n/a | Manual | Via faker | Frontend/React tests; replaces backend dependency entirely |
| Playwright `test.extend()` | Full (TypeScript) | Fixture scopes (`test`/`worker`) | n/a | Via faker | E2E tests; composable lifecycle, guaranteed teardown |
| Plain builder class | Full | Manual | Manual | Manual | Zero-dependency projects; team-readable, no abstraction overhead |

**Decision guide:**
- Unit tests only → plain builder or `factory-ts`
- Integration + DB persistence → `fishery`
- Zod-first domain → `zod-fixture` + `fishery` for persistence
- Need realistic locale data → any library + `@faker-js/faker`
- E2E / Playwright suites → Playwright `test.extend()` fixtures + `fishery` for DB setup

**Cross-language equivalents:** The same Object Mother + Builder patterns apply in every language. TypeScript's factory libraries map to: **factory_bot** (Ruby, DSL-based `FactoryBot.create(:user, status: :suspended)`), **FactoryBoy** (Python, class-based with `factory.LazyAttribute` for dynamic fields), **AutoFixture** (C#, reflection-based automatic property population — the C# equivalent of `zod-fixture`), and **easy-random** / **Instancio** (Java, reflection-based). If you're migrating from a Ruby or Python codebase to TypeScript, `fishery` is the closest API match to `factory_bot`, and `zod-fixture` mirrors AutoFixture's zero-maintenance approach.

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

The key is to expose the transaction's internal `rollback()` by resolving it via a held
`Promise`. The test body receives the same `tx` client and all writes are invisible to
other parallel tests because they never commit.

```typescript
// vitest.setup.ts (Drizzle ORM example)
import { db } from '../db';

let tx: Parameters<Parameters<typeof db.transaction>[0]>[0];
let rollback: () => Promise<void>;

beforeEach(async () => {
  // db.transaction runs the callback, but we never resolve it until afterEach
  await new Promise<void>((resolve, reject) => {
    db.transaction(async (trx) => {
      tx = trx;
      rollback = async () => {
        await trx.rollback();
        resolve();
      };
      // Pause here — test body runs while transaction is still open
      await new Promise<void>((innerResolve) => {
        (globalThis as any).__resolveTestTx = innerResolve;
      });
    }).catch(reject);
    // Signal the outer beforeEach that `tx` is ready
    setImmediate(resolve);
  });
});

afterEach(async () => {
  // Trigger rollback — all writes made via `tx` are discarded
  (globalThis as any).__resolveTestTx?.();
  await rollback?.();
});

// In each test file, import the exposed `tx` and pass it to repositories:
// const result = await userRepository.create(userData, { db: tx });
```

> **Simpler alternative (Knex / node-postgres raw):**
> ```typescript
> // Use pg's savepoints for lightweight nested rollback
> beforeEach(() => client.query('BEGIN'));
> afterEach(() => client.query('ROLLBACK'));
> ```

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
// vitest.config.ts — vmForks pool (Vitest 2.x, strongly isolated workers)
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // 'vmForks' runs each worker in a fresh V8 VM context — strongest isolation,
    // prevents module-level state leaking between worker processes.
    // Use 'forks' for slightly faster startup with process isolation only.
    pool: 'vmForks',
    poolOptions: {
      vmForks: {
        // Each fork gets its own module registry — no shared singleton services
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

**Cleanup Strategy Decision Tree:**

Use this decision tree to choose the right isolation strategy for your test suite.

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

### 7. Deprecated `@faker-js/faker` v8 API calls in v9+ projects

`faker.name.firstName()`, `faker.address.city()`, and `faker.datatype.uuid()` were
deprecated in v8 and removed in v9. Projects that upgraded faker without updating
factories silently break: the build passes (the API is not type-checked until runtime
in some configurations), but test suites throw `TypeError: faker.name.firstName is not a function`.

**Why harmful:** The migration is purely mechanical but affects every factory in the
codebase. Without a codebase-wide search-and-replace, individual factories fail
non-deterministically as faker v9 is adopted.

**Replacements:**
| v8 (removed) | v9+ (current) |
|---|---|
| `faker.datatype.uuid()` | `faker.string.uuid()` |
| `faker.name.firstName()` | `faker.person.firstName()` |
| `faker.name.fullName()` | `faker.person.fullName()` |
| `faker.address.city()` | `faker.location.city()` |
| `faker.address.zipCode()` | `faker.location.zipCode()` |
| `faker.internet.email({ firstName, lastName })` | `faker.internet.email({ firstName, lastName, provider })` |

Run `npx @faker-js/faker-codemod` to automatically migrate an entire codebase.

---



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

9. **[community] Factory ownership divergence is the most common long-term maintenance failure mode.**
   Teams start with a shared `factories/` folder, but individual feature teams add domain-specific overrides locally over time. After 18 months, the same `UserFactory` exists in three places with subtly different defaults — tests in different modules build different `User` shapes and the discrepancies hide cross-module integration bugs. Designate a single source of truth: one factory per domain entity, in a shared `test/factories/` directory, reviewed as rigorously as production code. Consider lint rules (`import/no-restricted-paths`) that prevent importing from `../factories` outside the shared directory.

10. **[community] In microservices, factories built for service A produce data shapes that silently diverge from what service B actually sends over the wire.**
    A `UserFactory.build()` in the Orders service produces `{ id, email, name }` but the Users service now sends `{ userId, emailAddress, displayName }` after a field rename. The Orders service test cases still pass (factory produces old shape), but production breaks. Fix: derive factories from the **contract schema** (Pact, OpenAPI, JSON Schema) rather than local domain types. When the contract changes, the factory changes automatically and contract violations surface at factory-build time, not in production.

11. **[community] ORM-generated types drift from hand-written factory types when migrations are not regenerated.**
    In Prisma projects, a common failure mode: developer adds a required `phoneNumber` column to `schema.prisma`, runs `prisma migrate dev`, but the factory's hand-written `User` interface has not been updated. The factory still builds objects without `phoneNumber`, but `prisma.user.create()` now throws at runtime. Fix: base all factory input types on `Prisma.UserCreateInput` (the generated type) rather than a manual interface. When the schema changes, `prisma generate` updates the type automatically and the factory fails at compile time, not at runtime.

12. **[community] `using` / `await using` resource cleanup requires `Symbol.asyncDispose` support in the test runner.**
    TypeScript 5.2+ `await using` calls `Symbol.asyncDispose()` at scope exit, but only if the JavaScript runtime and test runner support the TC39 Explicit Resource Management proposal. Vitest ≥ 1.4 and Node ≥ 22 support it natively; older Node versions or Jest < 30 require polyfills (`core-js/proposals/explicit-resource-management`). Using `await using` in a test suite running on Node 18 without the polyfill silently falls through to manual cleanup — the `[Symbol.asyncDispose]` method is never called. Fix: verify Node version compatibility before adopting `await using` in test helpers, and add a runtime assertion: `if (typeof Symbol.asyncDispose === 'undefined') throw new Error('Upgrade Node or add polyfill')`.

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
- **Event-sourced / CQRS systems:** factories produce state snapshots, but event-sourced systems store *commands and events*, not entity state. Building test data by constructing command sequences (not mutable objects) is more faithful to the system model. Use an `EventBuilder` or replaying domain commands instead of entity-state factories. Factories are still useful for read-model (projection) tests where the output *is* a state snapshot.

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
| fishery (npm) | Library | https://www.npmjs.com/package/fishery | Alternative factory library with associations and DB persistence hooks |
| zod-fixture | Library | https://www.npmjs.com/package/zod-fixture | Schema-driven automatic fixture generation for Zod-first codebases |
| msw (Mock Service Worker) | Library | https://mswjs.io/ | HTTP-layer test data for frontend suites; eliminates backend dependency |
| Vitest worker isolation docs | Official | https://vitest.dev/config/#pool | Per-worker DB setup guide |
| Playwright test fixtures docs | Official | https://playwright.dev/docs/test-fixtures | Composable E2E fixture lifecycle with `test.extend()` |
| Pact.io | Official | https://docs.pact.io/ | Contract-schema-driven factory patterns for microservices |
| Prisma — TypeScript ORM | Official | https://www.prisma.io/docs | Prisma.UserCreateInput pattern for zero-drift factories |
| TC39 Explicit Resource Management | Proposal | https://github.com/tc39/proposal-explicit-resource-management | `using`/`await using` specification — test resource cleanup |
| @anatine/zod-mock | Library | https://www.npmjs.com/package/@anatine/zod-mock | Alternative to zod-fixture; generates mock data from Zod schemas using faker |
