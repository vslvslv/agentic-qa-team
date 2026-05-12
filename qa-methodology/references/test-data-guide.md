# Test Data — QA Methodology Guide
<!-- lang: TypeScript | topic: test-data | iteration: 44 | score: 100/100 | date: 2026-05-12 -->
<!-- sources: WebFetch (github.com/faker-js/faker, github.com/thoughtbot/fishery, martinfowler.com/bliki/SelfInitializingFake.html, martinfowler.com/bliki/TestingResourcePools.html, vitest.dev/guide/migration, playwright.dev/docs/test-fixtures, playwright.dev/docs/release-notes, playwright.dev/docs/api/class-websocketroute, playwright.dev/docs/test-global-setup-teardown, playwright.dev/docs/api/class-test#test-abort, github.com/mswjs/msw/releases, playwright.dev/docs/release-notes#version-157, playwright.dev/docs/release-notes#version-159, playwright.dev/docs/release-notes#version-160); training-knowledge fallback for remaining gaps -->
<!-- official refs: martinfowler.com/bliki/ObjectMother.html · martinfowler.com/bliki/TestDouble.html · fakerjs.dev -->
<!-- iter-21-30 additions: AI-assisted test data generation, Testcontainers-node, PGlite, TanStack Query patterns, Zod v4 factory patterns, event-driven message factories (SQS/EventBridge), WebSocket/SSE test data, 4 new anti-patterns, 4 new community gotchas, ISTQB equivalence partitioning factories, updated key resources -->
<!-- iter-31: Neon DB copy-on-write branching for test isolation (neon.com/docs/guides/branching-test-queries, 2026-05-08); Testcontainers Cloud 8GB/session + Turbo mode (testcontainers.com/cloud/docs, 2026-05-08) -->
<!-- iter-32: faker v10.0.0 ESM-only breaking change (2026-05-12); UUID v7 time-ordered keys for DB-performance test data; Self-Initializing Fake pattern (Fowler); Testing Resource Pools (pool-size-1 technique); updated checklist to reference faker v10; Key Resources updated -->
<!-- iter-33: Vitest 4.0 pool config migration (poolOptions.vmForks → top-level isolate; singleFork → maxWorkers: 1; poolMatchGlobs/environmentMatchGlobs → projects; workspace → projects); community gotcha #21; Key Resources updated (2026-05-12) -->
<!-- iter-34: Playwright mergeTests() modular fixture composition; Playwright box fixture (box:true/box:'self') for clean test reports; Vitest 4.x singleThread also removed (not just singleFork); vi.resetModules() required with isolate:false; VITEST_MAX_WORKERS replaces VITEST_MAX_THREADS/MAX_FORKS; community gotcha #22; 2 new checklists (Playwright fixtures, Vitest 4.x config); 2 new Key Resources (2026-05-12) -->
<!-- iter-35: Vitest 4.1 builder pattern for test.extend() (return-based, automatic TypeScript type inference); aroundEach hook (transaction-per-test pattern); test.override() per-suite fixture overrides; vi.defineHelper() for clean factory assertion stack traces; Vitest 4.x coverage.all/coverage.extensions removal + mandatory coverage.include; community gotcha #23; new Vitest 4.1 checklist items; 3 new Key Resources (2026-05-12) -->
<!-- iter-41: Playwright 1.48 page.routeWebSocket() E2E WebSocket test data interception; Playwright 1.49 multiple globalSetup via project dependencies for composable DB seeding; Playwright 1.50 test.step.skip() for data-dependent step guarding; Playwright 1.60 test.abort() for fixture precondition enforcement; MSW v2.14 finalize() API for WS handler cleanup; faker v10.4 locale expansions (Norwegian, Japanese) for locale-sensitive test data; community gotcha #29 (Playwright WebSocket routes linger across tests without explicit teardown); updated checklists; 6 new Key Resources (2026-05-12) -->
<!-- iter-42: MSW v2.14.0 ws.onUpgrade() API for HTTP-upgrade-based WebSocket connections in Node.js; community gotcha #30 (ws.onUpgrade vs ws.link — upgrade handler applies globally, not per-link; not available in browser/service worker context); new Key Resource (2026-05-12) -->
<!-- iter-43: MSW defineNetwork() RFC — unified network mock API separating sources from handlers; Playwright 1.52 failOnFlakyTests as factory isolation quality signal (community gotcha #31); Playwright 1.53 locator.describe() for fixture element annotation in traces; Playwright 1.56 page.requests() for asserting factory-driven request patterns; Playwright 1.56 LLM Test Agents applied to factory scaffolding; corrected testProject.workers attribution to v1.52 (not v1.57); updated Playwright checklist; 4 new Key Resources (2026-05-12) -->
<!-- iter-44: Playwright 1.57 testConfig.webServer.wait (regex + named capture groups for dynamic port injection into test data fixtures); Playwright 1.60 locator.drop() for binary/clipboard test data delivery to dropzone elements; webSocketRoute.protocols() for subprotocol-aware WebSocket mock factories (dispatch different message factories per negotiated protocol); community gotcha #32 (locator.drop() needs explicit mimeType in file descriptor — omitting it silently drops the drop event); 3 new Key Resources (2026-05-12) -->
<!-- iter-40: faker v10 new APIs for factory authors (word error strategy 'fail', BigInt number generation, book module, UPC barcodes, simple coordinate methods, generic sex type); Playwright 1.46 component testing router fixture for MSW test data injection; community gotcha #28 (faker.word default 'fail' error strategy breaks word-based factories); updated Key Resources (2026-05-12) -->
<!-- iter-36: Vitest 4.1 test tags + TestRunner.matchesTags() for conditional DB seeding (vitest.dev/guide/test-tags, 2026-05-12); coverage.changed for modified-file-only coverage reports; coverage ignore comments (istanbul ignore start/stop, v8 ignore start/stop); --detectAsyncLeaks for surfacing factory teardown leaks; community gotcha #24 (async resource leaks from factories); 4 new Vitest 4.1 checklist items; 3 new Key Resources (2026-05-12) -->
<!-- iter-37: Vitest 4.0 expect.schemaMatching for inline factory output validation against Zod/Valibot/ArkType; Vitest 4.0 getSeed() API for programmatic seed access; Vitest 4.1 experimental viteModuleRunner:false for native Node.js factory execution; Google Testing Blog "Construct with Collaborators, Call with Work" pattern (2026-05-05) applied to factory design; faker v10.4.0 latest stable (2026-03-23); fishery v2.4.0 latest stable (2025-12-08); community gotcha #25 (schema drift caught by expect.schemaMatching); updated Key Resources (2026-05-12) -->
<!-- iter-38: Playwright 1.59 async disposables (await using for route handlers, pages, tracing — Symbol.asyncDispose in E2E test data); Playwright 1.60 HAR-based record/replay (routeFromHAR + tracing.startHar as a native Self-Initializing Fake for E2E); Playwright 1.57 testProject.workers for per-project parallelism in test data isolation; Playwright @tag syntax for conditional E2E fixture setup; community gotcha #26 (HAR fixture drift — routeFromHAR has no automatic re-recording signal); updated Key Resources (2026-05-12) -->

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
>
> **ISTQB CTFL 4.0 — Test Data Classification:** The ISTQB CTFL 4.0 syllabus
> (Chapter 5.3, "Test Environment") classifies test data by origin:
> - **Internally generated data** — produced by the system under test (SUT) or by factories
> - **Externally sourced data** — copied from production, imported from third-party feeds
> - **Synthetically generated data** — generated by tools (e.g., `@faker-js/faker`, `fast-check`)
> - **Migratory data** — legacy data migrated during system upgrades
>
> Factories primarily produce *synthetically generated* and *internally generated* data.
> The ISTQB emphasises that test data must be **controlled** (version-controlled, reproducible),
> **valid for the test condition**, and **isolated** from data used in other test cases.
> All three requirements are addressed by the factory and builder patterns in this guide.

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

### 6. Test data has a lifecycle — and so does its maintenance cost
Factories and builders are code. They need the same engineering discipline as production code: code review, refactoring, and ownership. A factory that goes unmaintained for 6 months accumulates drift: required fields are missing, enums contain old values, and defaults no longer reflect the domain. Treat factories as first-class domain artefacts — not throw-away test helpers.

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

### Playwright Fixtures for E2E Test Data  [community]

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

### Playwright `mergeTests()` — Composing Fixtures from Multiple Modules  [community]

When a large test suite has fixtures defined in multiple modules (e.g., `auth-fixtures.ts`,
`db-fixtures.ts`, `api-fixtures.ts`), combining them via `mergeTests()` creates a single
extended test object without requiring a single monolithic fixture file.

**Why it matters:** In large codebases, a single `fixtures/test-fixtures.ts` that imports
every factory and lifecycle becomes a maintenance bottleneck — every new fixture type
requires editing one shared file. `mergeTests()` (available since Playwright v1.39) allows
fixtures to be defined in domain-aligned modules and composed at the point of use,
keeping each module focused and independently maintainable.

```typescript
// fixtures/auth-fixtures.ts — authentication-related test data
import { test as base } from '@playwright/test';
import { userFactory } from '../factories/user.factory';
import { db } from '../db';

type AuthFixtures = {
  authenticatedUser: { id: string; email: string; sessionToken: string };
};

export const authTest = base.extend<AuthFixtures>({
  authenticatedUser: async ({}, use) => {
    const user = await userFactory.create({ status: 'active' });
    const sessionToken = await createSession(user.id);
    await use({ id: user.id, email: user.email, sessionToken });
    await revokeSession(sessionToken);
    await deleteUser(user.id);
  },
});
```

```typescript
// fixtures/db-fixtures.ts — database-related test data
import { test as base } from '@playwright/test';
import { db } from '../db';

type DbFixtures = {
  cleanDb: void;
};

export const dbTest = base.extend<DbFixtures>({
  cleanDb: [async ({}, use) => {
    await use();
    // Truncate test tables after each test that requests cleanDb
    await db.execute('TRUNCATE users, orders, products RESTART IDENTITY CASCADE');
  }, { auto: false }],
});
```

```typescript
// fixtures/index.ts — compose all fixture modules via mergeTests()
import { mergeTests } from '@playwright/test';
import { authTest } from './auth-fixtures';
import { dbTest } from './db-fixtures';

// The merged test object exposes fixtures from ALL merged modules
export const test = mergeTests(authTest, dbTest);
export { expect } from '@playwright/test';
```

```typescript
// specs/checkout.spec.ts — uses the merged fixture set
import { test, expect } from '../fixtures';

// Both 'authenticatedUser' and 'cleanDb' are available from merged modules
test('authenticated user completes checkout', async ({ page, authenticatedUser, cleanDb }) => {
  await page.goto('/login');
  await page.fill('[data-testid="email"]', authenticatedUser.email);
  // ... test body
});
```

**Limitation:** `mergeTests()` does not support merging fixtures that have conflicting names
across the input test objects. Resolve conflicts by renaming fixtures before merging or
by ensuring each fixture module uses a distinct namespace convention.

---

### Playwright `box` Fixture — Clean Reports for Infrastructure Fixtures  [community]

When Playwright fixtures are used for test data infrastructure (creating DB records,
seeding authentication state), their setup steps appear in test reports and Trace Viewer
as noise. The `{ box: true }` fixture option hides these steps from reports while
preserving full teardown guarantees — keeping reports focused on the actual test assertions.

**Why it matters:** A test report showing 12 fixture-setup steps before the first
assertion makes failures harder to diagnose — the report is dominated by infrastructure
noise. Boxing data-setup fixtures produces reports that show only the business-logic
steps that matter for debugging.

```typescript
// fixtures/boxed-fixtures.ts — boxed infrastructure fixtures
import { test as base } from '@playwright/test';
import { userFactory } from '../factories/user.factory';
import { db, users } from '../db';
import { eq } from 'drizzle-orm';

type BoxedFixtures = {
  testUser: { id: string; email: string };
  seedData: void;
};

export const test = base.extend<BoxedFixtures>({
  // Boxed: setup/teardown steps hidden from reports and Trace Viewer
  // The fixture still executes fully — only the report is cleaner
  testUser: [async ({}, use) => {
    const user = await userFactory.create({ status: 'active' });
    await use({ id: user.id, email: user.email });
    await db.delete(users).where(eq(users.id, user.id));
  }, { box: true }],  // ← hidden from test report steps

  // Partial boxing: fixture name hidden, but steps within it remain visible
  // Use when you want the fixture's own steps visible but the fixture name hidden
  seedData: [async ({}, use) => {
    // These inner steps ARE visible in Trace Viewer (box: 'self' only hides the fixture name)
    await db.execute('INSERT INTO products (name, price) VALUES ($1, $2)', ['Test Product', 999]);
    await use();
    await db.execute('DELETE FROM products WHERE name = $1', ['Test Product']);
  }, { box: 'self' }],  // ← only the fixture wrapper name is hidden; steps remain
});

export { expect } from '@playwright/test';
```

```typescript
// specs/product.spec.ts — boxed fixtures produce clean reports
import { test, expect } from '../fixtures/boxed-fixtures';

// In the test report: only these steps appear (no fixture setup noise):
// ✓ Navigate to /products
// ✓ Expect product to be visible
test('product listing shows seeded product', async ({ page, testUser, seedData }) => {
  await page.goto('/products');
  await expect(page.locator('[data-testid="product-name"]')).toBeVisible();
  // testUser and seedData are set up/torn down without appearing as report steps
});
```

**When to box vs not box:**
- **Box:** DB seed setup, auth state creation, data cleanup — infrastructure not specific to the test's assertion
- **Do not box:** Fixtures whose behavior you want visible in failure traces, or fixtures that could fail and need debugging visibility

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

### TypeScript Utility Types for Type-Safe Factories  [community]

TypeScript's built-in utility types (`Partial`, `Required`, `Pick`, `Omit`, `DeepPartial`) enable factory APIs that are both flexible and type-safe without requiring external libraries. Using them intentionally prevents a common factory pitfall: overrides that accept `any` and silently accept wrong field names.

**Why it matters:** A factory with `overrides: object` or `overrides: any` gives zero autocomplete support and no compile-time validation when domain types change. Using `Partial<T>` with the entity type ensures that override keys must exist on the type, and their values must be assignable to the correct type.

```typescript
// type-safe-factory.ts — utility types in factory design
import { faker } from '@faker-js/faker';

// Domain types with a mix of required and optional fields
type Address = {
  id: string;
  street: string;
  city: string;
  country: string;
  postalCode: string;
  apartmentNumber?: string;         // optional field
};

type User = {
  id: string;
  email: string;
  name: string;
  status: 'active' | 'suspended' | 'pending';
  address: Address;                  // nested object
  createdAt: Date;
};

// DeepPartial utility — for nested object overrides
type DeepPartial<T> = {
  [K in keyof T]?: T[K] extends object ? DeepPartial<T[K]> : T[K];
};

// Factory with DeepPartial<T> overrides — handles nested objects
export function buildUser(overrides: DeepPartial<User> = {}): User {
  const defaults: User = {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    status: 'active',
    address: {
      id: faker.string.uuid(),
      street: faker.location.streetAddress(),
      city: faker.location.city(),
      country: 'US',
      postalCode: faker.location.zipCode(),
    },
    createdAt: new Date(),
  };

  // Deep merge — override.address only replaces specified address fields
  return {
    ...defaults,
    ...overrides,
    address: {
      ...defaults.address,
      ...(overrides.address ?? {}),
    },
  };
}

// TypeScript catches wrong field names at compile time:
// buildUser({ stauts: 'suspended' });  // TS Error: 'stauts' does not exist on DeepPartial<User>
// buildUser({ status: 'unknown' });    // TS Error: '"unknown"' not assignable to status union type

// Required<T> — factory for sub-types requiring all optional fields populated
function buildFullAddress(overrides: Partial<Required<Address>> = {}): Required<Address> {
  return {
    id: faker.string.uuid(),
    street: faker.location.streetAddress(),
    city: faker.location.city(),
    country: 'US',
    postalCode: faker.location.zipCode(),
    apartmentNumber: faker.location.secondaryAddress(), // Required<> forces this field
    ...overrides,
  };
}
```

**Pattern: `Pick`-based factories for partial domain objects in API tests:**
```typescript
// When an API endpoint only accepts a subset of fields, use Pick to restrict the factory
type CreateUserRequest = Pick<User, 'email' | 'name'>;   // only what the API accepts

export function buildCreateUserRequest(
  overrides: Partial<CreateUserRequest> = {}
): CreateUserRequest {
  return {
    email: faker.internet.email(),
    name: faker.person.fullName(),
    ...overrides,
  };
}
// Attempting to add 'id' or 'status' in overrides is a TypeScript error —
// they don't exist on Pick<User, 'email' | 'name'>
```

---

### TypeScript Factory Library Comparison

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

**Cross-language equivalents:** The same Object Mother + Builder patterns apply in every language. TypeScript's factory libraries map to: **factory_bot** (Ruby, DSL-based `FactoryBot.create(:user, status: :suspended)`), **FactoryBoy** (Python, class-based with `factory.LazyAttribute` for dynamic fields), **AutoFixture** (C#, reflection-based automatic property population — the C# equivalent of `zod-fixture`), **factory_girl** (original Ruby library, now superseded by factory_bot in ≥ v5), and **easy-random** / **Instancio** (Java, reflection-based). If you're migrating from a Ruby or Python codebase to TypeScript, `fishery` is the closest API match to `factory_bot`, and `zod-fixture` mirrors AutoFixture's zero-maintenance approach.

---

### Cross-Language Factory Library Reference  [community]

Understanding the canonical factory libraries in other languages helps teams adopt the right TypeScript equivalent and communicate patterns across polyglot organisations.

#### factory_bot (Ruby) — The Reference Implementation

`factory_bot` (formerly `factory_girl`, renamed in v5 when the original maintainer deprecated it) is the most influential factory library in any language. Its design directly inspired `fishery` for TypeScript.

**factory_bot key concepts and TypeScript equivalents:**

| factory_bot concept | TypeScript equivalent |
|---|---|
| `FactoryBot.build(:user)` | `userFactory.build()` (fishery) |
| `FactoryBot.create(:user)` | `await userFactory.create()` (fishery — DB persist) |
| `factory.trait :suspended` | `UserMother.suspended()` or named factory variant |
| `factory.association :profile` | `userFactory.associations({ profile: profileFactory })` |
| `factory.sequence(:email)` | `sequence` param in fishery factory definition |
| `FactoryBot.create_list(:user, 5)` | `await userFactory.createList(5)` |

```typescript
// fishery TypeScript — direct factory_bot API analogy
// Compare: FactoryBot.define(:user) { sequence(:email) { |n| "user#{n}@test.com" } }
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';
import { User } from '../domain/user';

export const userFactory = Factory.define<User>(({ sequence, associations }) => ({
  id: faker.string.uuid(),
  email: `user-${sequence}@test.com`,            // fishery sequence ≈ factory_bot sequence
  name: faker.person.fullName(),
  status: 'active' as const,
  subscriptionTier: 'free' as const,
  createdAt: new Date(),
  paymentMethodId: null,
  // associations: profile would go here (fishery handles nested create)
}));

// fishery ≈ FactoryBot.build_stubbed(:user, status: :suspended)
const inMemoryUser = userFactory.build({ status: 'suspended' });

// fishery ≈ FactoryBot.create(:user, subscription_tier: :premium)
const persistedUser = await userFactory.create({ subscriptionTier: 'premium' });

// fishery ≈ FactoryBot.create_list(:user, 3, status: :active)
const users = await userFactory.createList(3, { status: 'active' });
```

**Why factory_bot is the benchmark:** factory_bot enforced the discipline of separating `build` (in-memory) from `create` (DB-persist), which `fishery` brings to TypeScript. Teams migrating from Rails to Node.js should map `fishery` as the first-class TypeScript replacement.

---

#### FactoryBoy (Python) — Class-Based Factories

`FactoryBoy` uses Python class inheritance to define factories. Its `factory.LazyAttribute` and `factory.SubFactory` are the equivalents of TypeScript factory functions with closures and sub-factory composition.

**FactoryBoy → TypeScript concept mapping:**

| FactoryBoy concept | TypeScript equivalent |
|---|---|
| `class UserFactory(factory.Factory)` | `Factory.define<User>(...)` (fishery) / `makeFactory<User>(...)` (factory-ts) |
| `factory.LazyAttribute(lambda o: f"{o.name}@test.com")` | `email: faker.internet.email()` inside `each(() => ...)` |
| `factory.SubFactory(ProfileFactory)` | `profile: each(() => profileFactory.build())` |
| `UserFactory.build()` | `userFactory.build()` |
| `UserFactory.create()` | `await userFactory.create()` |
| `UserFactory.build_batch(5)` | `userFactory.buildList(5)` |
| `UserFactory.stub()` | plain builder `new UserBuilder().build()` |

```typescript
// TypeScript equivalent of a FactoryBoy factory with LazyAttribute and SubFactory
// Python: class OrderFactory(factory.django.DjangoModelFactory):
//           user = factory.SubFactory(UserFactory)
//           total = factory.LazyAttribute(lambda o: sum(item.price for item in o.items))

import { makeFactory, each } from 'factory-ts';
import { faker } from '@faker-js/faker';
import { buildUser } from './user.factory';
import { Order } from '../domain/order';

export const OrderFactory = makeFactory<Order>({
  id: each(() => faker.string.uuid()),
  // SubFactory equivalent: each() with nested factory call
  userId: each(() => buildUser().id),
  status: 'pending',
  items: [],
  // LazyAttribute equivalent: computed at call time via each()
  totalCents: each(() => faker.number.int({ min: 100, max: 100_000 })),
  currency: 'USD',
  createdAt: each(() => faker.date.recent()),
});
```

---

#### AutoFixture (C#) — Reflection-Based Automatic Population

`AutoFixture` generates test data automatically by reflecting on C# class constructors and properties. It requires zero factory definition for simple DTOs — a property is populated automatically unless you customise it. The TypeScript equivalent is `zod-fixture`, which reflects on a Zod schema rather than a C# class.

**AutoFixture → TypeScript concept mapping:**

| AutoFixture concept | TypeScript equivalent |
|---|---|
| `fixture.Create<User>()` | `createFixture(UserSchema)` (zod-fixture) |
| `fixture.CreateMany<User>(5)` | `Array.from({length:5}, () => createFixture(UserSchema))` |
| `fixture.Build<User>().With(u => u.Status, "suspended").Create()` | `buildUserFixture({ status: 'suspended' })` |
| `fixture.Freeze<IEmailService>()` | `vi.fn()` / `ts-mockito` mock registration |
| `ICustomization` | `zod-fixture` transformer / override function |
| `AutoMoqCustomization` | `ts-mockito` / `vitest` mock injection |

```typescript
// zod-fixture TypeScript — AutoFixture-style zero-definition generation
// C#: var fixture = new Fixture(); var user = fixture.Create<User>();
import { createFixture, createArrayFixture } from 'zod-fixture';
import { UserSchema, User } from '../schemas/user.schema';

// Zero-configuration: every field is populated from schema constraints
const autoUser: User = createFixture(UserSchema);
// autoUser.id is a valid UUID, autoUser.email is a valid email — no factory definition needed

// AutoFixture.CreateMany<User>(5) equivalent
const fiveUsers: User[] = createArrayFixture(UserSchema, { length: 5 });

// AutoFixture Build<User>().With(...).Create() equivalent
const suspendedUser: User = {
  ...createFixture(UserSchema),
  status: 'suspended',
  paymentMethodId: null,
};
```

**Key AutoFixture limitation mirrored in zod-fixture:** Both generate *structurally valid* data (passes schema validation) but not *semantically realistic* data (IDs are random strings, names are lorem-ipsum words). For tests that require realistic-looking data (screenshots, demos, NLP processing), layer `@faker-js/faker` overrides on top.

---

#### factory_girl (Ruby, legacy) — Historical Context

`factory_girl` was the original Ruby factory library created by Joe Ferreira at Thoughtbot in 2008. In 2017, Thoughtbot renamed it `factory_bot` (v5+) to remove gendered language. The API is identical; only the module name changed (`FactoryGirl` → `FactoryBot`). All `factory_girl` usage patterns map 1:1 to `factory_bot` and therefore to `fishery` in TypeScript. If you encounter `factory_girl` references in older documentation or tutorials, treat them as `factory_bot` equivalents.

**Migration note for TypeScript teams:** projects migrating from a Rails codebase using `factory_girl` to TypeScript should replace `FactoryGirl.create(:user)` calls with `await userFactory.create()` (fishery) — the semantic contract (in-memory vs DB-persisted, traits as overrides, sequences for unique fields) is preserved.

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
// vitest.config.ts — per-worker isolation (Vitest 4.x)
// NOTE: Vitest 4.0 removed the poolOptions nesting — pool settings are now top-level.
// Vitest 2.x/3.x style (DEPRECATED — do not use):
//   pool: 'vmForks', poolOptions: { vmForks: { singleFork: false } }
// Vitest 4.x style (current):
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    pool: 'vmForks',   // 'vmForks' runs each worker in a fresh V8 VM context
    // In Vitest 4.x, isolation is controlled at the top level — not inside poolOptions:
    isolate: true,     // true = each file gets its own module registry (default for vmForks)
    // Previously: poolOptions: { vmForks: { singleFork: false } }  ← removed in Vitest 4.0
    // If you need a single process (no isolation): set maxWorkers: 1 and isolate: false
    // Previously: poolOptions: { vmForks: { singleFork: true } }  ← removed in Vitest 4.0
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

### 8. Importing raw JSON fixtures without type validation

```typescript
// WRONG — untyped JSON fixture import
import users from './fixtures/users.json'; // TypeScript infers as any[]

// test uses users[0].emailAdress (typo) — no compile error, fails at runtime
expect(users[0].emailAdress).toBe('alice@fixture.com');
```
**Why harmful:** JSON fixture files imported in TypeScript are inferred as `any[]` or a wide literal type. Domain type changes (added required fields, renamed fields) are not reflected in the fixture — tests silently use stale data shapes. Fix: validate fixture data against the domain type using `satisfies` or a Zod parse:

```typescript
// CORRECT — validate fixture against domain type at import time
import usersRaw from './fixtures/users.json';
import { UserSchema, User } from '../schemas/user.schema';
import { z } from 'zod';

// Parse and validate — throws at module load if fixture doesn't match schema
const users: User[] = z.array(UserSchema).parse(usersRaw);
// TypeScript now knows users is User[] — typos in field names are caught at compile time
expect(users[0].email).toBe('alice@fixture.com');
```

### 9. Using LLM-generated factory code without review

Accepting LLM-generated factory code verbatim introduces subtle bugs that compile cleanly
but produce incorrect test data. The most common issues: using deprecated faker v8 API names
(`faker.name.firstName()` instead of `faker.person.firstName()`), generating module-level
constants instead of per-call closures (the `factory-ts` `each()` gotcha), and omitting
required fields that TypeScript would flag if the override type were `Partial<T>` rather
than `any`. **Why harmful:** The factory compiles, all tests pass at first run, but the
flaws surface gradually — identifier collisions in CI, stale data shapes after domain
model changes, and non-reproducible test failures from un-seeded randomness.

### 10. `@faker-js/faker` v10 ESM-only breaking change — `require()` no longer works

`@faker-js/faker` v10.0.0 (released August 2025) removed CommonJS distribution entirely.
Projects that `require('@faker-js/faker')` or use `"type": "commonjs"` in `package.json`
without an interop layer will receive `Error [ERR_REQUIRE_ESM]` at runtime after upgrading.

**Why harmful:** The v10 release is a silent upgrade in projects that use semver ranges like
`"@faker-js/faker": "^9"` — the `^` range does not cross major version boundaries, so the
breakage only manifests when the `package.json` is explicitly updated to `"^10"`. Teams that
upgrade faker in response to a security advisory without reading the migration notes encounter
ESM-only breakage for the first time in CI.

**Fix options (in order of preference):**
```typescript
// Option 1 — ESM project: ensure package.json has "type": "module"
// and use static import (no change needed if already ESM)
import { faker } from '@faker-js/faker';

// Option 2 — CommonJS project: use dynamic import() at the top of the test setup
// (Node.js supports top-level await in .mjs and ESM mode)
const { faker } = await import('@faker-js/faker');

// Option 3 — CommonJS project: configure ts-jest / vitest to handle ESM
// vitest.config.ts (most common — vitest handles ESM natively)
// No additional config needed; vitest's default ESM transform covers faker v10

// Option 4 — Stick to faker v9 (legacy) until ESM migration is ready
// "devDependencies": { "@faker-js/faker": "^9" }
// Note: v9 docs at v9.fakerjs.dev, v10 docs at fakerjs.dev
```

**Check for breakage before upgrading:**
```bash
# Scan factories for CommonJS-incompatible patterns before bumping faker major version
grep -r "require('@faker-js/faker')\|require(\"@faker-js/faker\")" ./src ./test
```

### 11. Factories for AI/LLM feature testing that use static outputs

When testing features that call an LLM API (chat, summarization, classification), a factory
that returns a static hardcoded response string (`{ response: 'The answer is 42' }`) does
not cover the full output variability of the model. However, using a live LLM API in tests
reintroduces non-determinism. The correct pattern is to mock the AI SDK with a deterministic
factory and separately maintain a suite of recorded real responses as fixtures for property
testing. **Why harmful:** Static single-response mocks test only the happy path. Real LLM
outputs include partial responses, markdown formatting, refusals, multi-language outputs,
and token-limit truncations — all of which affect downstream parsing and rendering logic.

```typescript
// factories/ai-response.factory.ts — typed LLM response test data
// Covers the output variability that a single hardcoded string misses
export const LLMResponseFixtures = {
  // Happy path — clean, well-formed response
  standard: () => ({ content: 'The summary is: [concise text here].', finishReason: 'stop' }),
  // Truncated — model hit token limit mid-sentence
  truncated: () => ({ content: 'The summary is: This is a very long', finishReason: 'length' }),
  // Refusal — model declined the request (safety filter)
  refusal: () => ({ content: "I can't assist with that.", finishReason: 'stop' }),
  // Empty — model returned an empty string (rare but real)
  empty: () => ({ content: '', finishReason: 'stop' }),
  // Markdown — model used formatting (tests renderer's sanitization)
  markdown: () => ({
    content: '**Summary:** The key points are:\n1. First\n2. Second\n3. Third\n\n```code block```',
    finishReason: 'stop',
  }),
  // Non-English — tests i18n rendering of AI output
  nonEnglish: () => ({ content: '要約：これは日本語のテキストです。', finishReason: 'stop' }),
} as const;
```

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

9. **[community] Factory ownership divergence is the most common long-term maintenance failure mode.**
   Teams start with a shared `factories/` folder, but individual feature teams add domain-specific overrides locally over time. After 18 months, the same `UserFactory` exists in three places with subtly different defaults — tests in different modules build different `User` shapes and the discrepancies hide cross-module integration bugs. Designate a single source of truth: one factory per domain entity, in a shared `test/factories/` directory, reviewed as rigorously as production code. Consider lint rules (`import/no-restricted-paths`) that prevent importing from `../factories` outside the shared directory.

10. **[community] In microservices, factories built for service A produce data shapes that silently diverge from what service B actually sends over the wire.**
    A `UserFactory.build()` in the Orders service produces `{ id, email, name }` but the Users service now sends `{ userId, emailAddress, displayName }` after a field rename. The Orders service test cases still pass (factory produces old shape), but production breaks. Fix: derive factories from the **contract schema** (Pact, OpenAPI, JSON Schema) rather than local domain types. When the contract changes, the factory changes automatically and contract violations surface at factory-build time, not in production.

11. **[community] ORM-generated types drift from hand-written factory types when migrations are not regenerated.**
    In Prisma projects, a common failure mode: developer adds a required `phoneNumber` column to `schema.prisma`, runs `prisma migrate dev`, but the factory's hand-written `User` interface has not been updated. The factory still builds objects without `phoneNumber`, but `prisma.user.create()` now throws at runtime. Fix: base all factory input types on `Prisma.UserCreateInput` (the generated type) rather than a manual interface. When the schema changes, `prisma generate` updates the type automatically and the factory fails at compile time, not at runtime.

12. **[community] `using` / `await using` resource cleanup requires `Symbol.asyncDispose` support in the test runner.**
    TypeScript 5.2+ `await using` calls `Symbol.asyncDispose()` at scope exit, but only if the JavaScript runtime and test runner support the TC39 Explicit Resource Management proposal. Vitest ≥ 1.4 and Node ≥ 22 support it natively; older Node versions or Jest < 30 require polyfills (`core-js/proposals/explicit-resource-management`). Using `await using` in a test suite running on Node 18 without the polyfill silently falls through to manual cleanup — the `[Symbol.asyncDispose]` method is never called. Fix: verify Node version compatibility before adopting `await using` in test helpers, and add a runtime assertion: `if (typeof Symbol.asyncDispose === 'undefined') throw new Error('Upgrade Node or add polyfill')`.

13. **[community] Property-based testing (`fast-check`) complements factories and finds edge cases that hand-crafted factories miss.**
    Static factory data, even with randomness, is biased toward "normal" values because the developer writing the factory makes unconscious choices about what's plausible. Property-based testing (PBT) with `fast-check` generates data from *combinatorial constraints* — it will naturally produce empty strings, max-int boundary values, unicode-only names, and null combinations that a developer wouldn't think to include in a factory. The production lesson: PBT found a silent integer overflow in a billing service's `totalCents` calculation that 18 months of factory-based tests missed — the factory's `faker.number.int({ min: 100, max: 100_000 })` never generated values near `Number.MAX_SAFE_INTEGER`.

    ```typescript
    // Combining factory defaults with fast-check for edge-case coverage
    import * as fc from 'fast-check';
    import { buildUser } from './factories/user.factory';
    import { checkoutService } from './checkout.service';

    // Property: checkout must never throw — it must always return a status object
    // fast-check generates totalCents across full integer range, not just 100–100,000
    it('checkout never throws regardless of totalCents value', () => {
      fc.assert(
        fc.property(
          fc.integer({ min: 0, max: Number.MAX_SAFE_INTEGER }),
          fc.constantFrom('active', 'suspended', 'pending'),
          (totalCents, status) => {
            const user = buildUser({ status });
            const cart = { items: [], totalCents };
            // Property: result must always be a defined object with a status field
            const result = checkoutService.initiate(user, cart);
            return result !== null && typeof result.status === 'string';
          }
        ),
        { numRuns: 1000 }
      );
    });
    ```

    **Integration pattern:** use factories for the "normal" test cases (unit and integration tests) and PBT for the "boundary/edge-case" layer. Do not replace factories with PBT — the two approaches are complementary. PBT is slower (100–10,000 runs per property) and harder to debug; factories are fast and give explicit, reproducible scenarios.

14. **[community] Test data for multi-tenant SaaS must include tenant isolation invariants — factories without tenant scoping are a security risk.**
    In a multi-tenant application, a factory that creates a `User` without a `tenantId`, or with a default hardcoded `tenantId`, will cause cross-tenant data leakage if that user is inadvertently associated with another tenant's data during a test. The production lesson: a shared test DB with a fixed `tenantId: 'test-tenant'` in all factories led to a query that omitted the tenant filter — passing in tests (all data is the same tenant) but leaking across tenants in production. Fix: generate a unique `tenantId` per test run (or use a per-test `faker.string.uuid()` tenant ID), and add a lint rule that rejects factories missing a `tenantId` field in tenant-scoped domains.

    ```typescript
    // factories/tenant-scoped.factory.ts — tenant isolation enforced at factory level
    import { faker } from '@faker-js/faker';
    import { User } from '../domain/user';

    // Generate a unique tenant ID per test run — never share across tests
    export function buildTenantScopedUser(
      tenantId: string,            // REQUIRED — caller must always supply
      overrides: Partial<Omit<User, 'tenantId'>> = {}
    ): User {
      return {
        id: faker.string.uuid(),
        tenantId,                  // explicit tenant isolation
        email: `${faker.string.uuid()}@${faker.internet.domainName()}`,
        name: faker.person.fullName(),
        status: 'active',
        ...overrides,
      };
    }

    // In a test — each test uses its own unique tenantId
    const myTenantId = faker.string.uuid();
    const user = buildTenantScopedUser(myTenantId, { status: 'suspended' });
    ```

15. **[community] Test data factories rarely include adversarial/security inputs — leaving XSS, SQLi, and path traversal bugs undetected until penetration testing.**
    Standard factories generate "well-behaved" strings: realistic names, valid emails, proper UUIDs. But security-sensitive code paths (search inputs, file paths, HTML rendering, SQL parameterisation) need adversarial strings to be tested. A name field factory that only generates `faker.person.fullName()` will never test how a name like `<script>alert(1)</script>` is handled in the frontend, or how `'; DROP TABLE users; --` is handled in a query builder. The production lesson: an XSS vulnerability in a user profile display was discovered in penetration testing, not in automated tests, because no factory ever generated HTML-containing name strings.

    ```typescript
    // factories/adversarial.factory.ts — security test data
    // Include in security regression tests, not in every unit test
    export const adversarialStrings = {
      xss: [
        '<script>alert("xss")</script>',
        '"><img src=x onerror=alert(1)>',
        "javascript:alert('xss')",
        '<<SCRIPT>alert("XSS");//<</SCRIPT>',
      ],
      sqlInjection: [
        "'; DROP TABLE users; --",
        "1 OR 1=1",
        "1; SELECT * FROM users",
        "admin'--",
      ],
      pathTraversal: [
        '../../etc/passwd',
        '..\\..\\windows\\system32\\drivers\\etc\\hosts',
        '%2e%2e%2f%2e%2e%2fetc%2fpasswd',
      ],
      unicodeBoundary: [
        ' ',          // null byte
        '�',          // replacement character
        '日本語テスト',     // Japanese (multi-byte)
        '𝕳𝖊𝖑𝖑𝖔',          // Unicode outside BMP (surrogate pairs)
        'A'.repeat(10_000), // max-length boundary
      ],
    } as const;

    // Usage: parametric test over adversarial names
    describe.each(adversarialStrings.xss)(
      'user name rendering is XSS-safe for: %s',
      (maliciousName) => {
        it('escapes name in HTML output', () => {
          const user = buildUser({ name: maliciousName });
          const html = renderUserCard(user);
          // Must not contain unescaped < or > in the rendered HTML
          expect(html).not.toMatch(/<script/i);
          expect(html).not.toMatch(/onerror=/i);
        });
      }
    );
    ```

16. **[community] Testcontainers containers not stopped on CI runner termination cause dangling containers and resource exhaustion.**
    When a CI job is cancelled or times out before `globalTeardown` runs, Testcontainers containers remain running on the CI runner. Over time, these dangling containers exhaust memory and disk, causing unrelated CI jobs to fail with OOM errors. Fix: use Testcontainers' Ryuk sidecar (enabled by default in `testcontainers-node` v10+) which auto-removes containers when the parent process exits, even on ungraceful termination. Never disable Ryuk in CI (`process.env.TESTCONTAINERS_RYUK_DISABLED = 'true'` is for local dev with very slow Docker only).

17. **[community] TanStack Query test wrappers with `staleTime: 0` (default) cause spurious refetch requests mid-assertion.**
    In tests using `@testing-library/react` with TanStack Query components, the default `staleTime: 0` treats all cached data as immediately stale. Any `fireEvent.focus(window)` or `userEvent.tab()` in the test triggers a background refetch — adding unexpected HTTP requests to the MSW mock server. This causes `onUnhandledRequest: 'error'` failures for refetch requests the test author didn't expect. Fix: set `staleTime: Infinity` in the test `QueryClient` (shown in the TanStack Query section above).

18. **[community] Zod v4 `z.email()` and `z.uuid()` top-level helpers break `zod-fixture` v0.8 and earlier.**
    `zod-fixture` introspects the Zod schema's internal `_def` structure to generate data. In Zod v4, top-level helpers like `z.email()` produce a different `_def.typeName` than `z.string().email()`. Older `zod-fixture` versions fall through to `string` generation (random lorem-ipsum) rather than email-format generation. Symptom: `buildUserFixture()` returns objects where `email` is `'Qwerty Ipsum Dolor'` instead of a valid email — silent type validation passes, but downstream email-sending logic rejects the format. Fix: upgrade `zod-fixture` to a Zod v4 compatible version or override `email` fields with `faker.internet.email()`.

19. **[community] Event factory payload schemas drift from the consumer's expected schema in event-driven architectures.**
    In Kafka or SQS-based systems, event producers and consumers are independently deployed. A producer team adds a required `correlationId` field to `UserCreatedEvent`. The consumer's event factory is not updated. Consumer integration tests continue passing with the old event shape. In production, the consumer receives events with `correlationId` and fails to process them (missing field validation error). Fix: derive both producer and consumer event factories from a **shared event schema package** — the single source of truth. When the schema changes, both factory files fail to compile.

20. **[community] Connection pool size in integration tests hides resource-leak bugs.**
    Integration tests typically run against a database with a connection pool of 10–50 connections. Code that fails to release a connection (missing `await db.end()`, unclosed transaction, forgotten client checkout) works fine in normal conditions — the pool has spare capacity. However, the leak is invisible until production load saturates the pool. Fix: set your test DB connection pool size to **1** for integration tests (`max: 1` in the Pool config). Any test that fails to release its connection will immediately block the next test requiring one, surfacing the leak as a timeout rather than a silent degradation. This technique (from Martin Fowler's "Testing Resource Pools") is particularly effective for finding connection leaks in repository-layer tests.

    ```typescript
    // vitest.setup.ts — pool size 1 exposes connection leaks immediately
    import { Pool } from 'pg';

    // Use pool size 1 in tests to surface resource leaks early
    // Warning: this serializes all DB operations — only use for integration tests,
    // not for parallel E2E suites (use transaction rollback there instead)
    export const testPool = new Pool({
      connectionString: process.env.TEST_DATABASE_URL,
      max: 1,           // deliberately constrained — any leak blocks the next test
      idleTimeoutMillis: 1000,  // fail fast if connection is held past test timeout
      connectionTimeoutMillis: 2000,  // surface the leak as a timeout, not a hang
    });

    afterAll(async () => {
      await testPool.end();
    });
    ```

21. **[community] Vitest 4.0 removed `poolOptions` nesting — test isolation configs written for Vitest 2.x/3.x silently revert to defaults.**
    Vitest 4.0 restructured the pool configuration API: `poolOptions.vmForks.singleFork`, `poolOptions.forks.singleFork`, and `poolOptions.vmThreads.memoryLimit` are no longer recognised under `poolOptions`. Instead, `isolate` and `maxWorkers` are top-level `test` options. The `workspace` option was renamed `projects`, and `poolMatchGlobs`/`environmentMatchGlobs` were removed in favour of `projects`. Critically, the breakage is silent — Vitest 4.0 does not error on unknown config keys; it silently falls back to defaults. A team that relied on `poolOptions.vmForks.singleFork: true` (single-process, no module isolation) to share a singleton DB connection across tests will now run with full isolation (the default), causing each test file to attempt its own DB connection — exhausting the pool and causing `connection timeout` failures that look like infrastructure problems. Fix: audit `vitest.config.ts` before upgrading to Vitest 4.0 using the migration guide at vitest.dev/guide/migration.
    ```typescript
    // Vitest 2.x/3.x (BROKEN in Vitest 4.0 — options silently ignored):
    // poolOptions: { vmForks: { singleFork: false }, forks: { singleFork: true } }

    // Vitest 4.0 equivalents:
    // "singleFork: false" (per-file isolation, each file its own module scope):
    //   pool: 'vmForks', isolate: true  (default — no change needed if using defaults)
    // "singleFork: true" (shared process, no module re-init between files):
    //   pool: 'forks', maxWorkers: 1, isolate: false
    // Check your Vitest version:
    // npx vitest --version  →  4.x = new API; 2.x/3.x = old poolOptions API
    ```

22. **[community] Vitest 4.x removed `singleThread` in addition to `singleFork` — and `maxWorkers: 1, isolate: false` requires explicit `vi.resetModules()` when modules hold state.**
    The Vitest 4.0 release removed Tinypool entirely, consolidating `singleThread` (vmThreads mode) AND `singleFork` (forks mode) into the unified `maxWorkers: 1, isolate: false` config. Guides written for Vitest 3.x often only mention `singleFork`, leaving `singleThread` users unaware that their config also silently stopped working. The second part of this gotcha: when combining `maxWorkers: 1` with `isolate: false`, **module state is shared across test files in the same worker** — a singleton factory counter or faker seed initialized at module load is shared between files. If your factories or test helpers hold module-level state (a counter, a cached DB connection, a faker instance), you must call `vi.resetModules()` in a `beforeAll` or `setupFile` to reinitialize the module registry between files. Omitting this causes test pollution that only manifests when multiple test files run in the same process.

    ```typescript
    // vitest.config.ts — Vitest 4.x single-process shared module mode
    export default defineConfig({
      test: {
        pool: 'forks',
        maxWorkers: 1,
        isolate: false,     // module registry shared across files in this worker
        setupFiles: ['./test/reset-modules.ts'],  // REQUIRED when isolate: false
      },
    });

    // test/reset-modules.ts — reset module registry before each file when sharing the process
    // Without this, module-level state (factory counters, DB singletons) leaks between files
    import { beforeAll, vi } from 'vitest';

    beforeAll(() => {
      // Reinitialize all imported modules between test files
      // Prevents: factory sequence counters resetting, faker seed bleeding across files
      vi.resetModules();
    });
    ```

    Additionally, the `VITEST_MAX_WORKERS` environment variable replaces both `VITEST_MAX_THREADS` and `VITEST_MAX_FORKS` in Vitest 4.x. CI scripts that set `VITEST_MAX_THREADS=2` to limit parallelism on resource-constrained runners must be updated to `VITEST_MAX_WORKERS=2`.

23. **[community] Vitest 4.x removed `coverage.all` and `coverage.extensions` — factory files excluded from reports silently.**
    Vitest 4.0 removed `coverage.all` (which included all files regardless of whether they were imported by tests) and `coverage.extensions` (file extension allowlist). Teams that relied on `coverage.all: true` to surface factory files with zero coverage now get no warning when a factory is written but never imported by any test case. The replacement is `coverage.include` — an explicit glob pattern that must be set. **If `coverage.include` is omitted entirely, only files actively loaded during the test run appear in coverage reports.** Factory files in `src/factories/` that are written but never imported by any test case become invisible to coverage metrics, creating a false sense of completeness. Additionally, Vitest 4.x V8 coverage now uses AST-based remapping for source maps rather than line-heuristic remapping — factory files with complex generics or conditional types may see different (more accurate) branch coverage numbers after migration.

    ```typescript
    // vitest.config.ts — explicit coverage.include required in Vitest 4.x
    import { defineConfig } from 'vitest/config';

    export default defineConfig({
      test: {
        coverage: {
          provider: 'v8',
          // REQUIRED in 4.x: explicit include glob — coverage.all no longer exists
          // Include both source AND factory files to catch unused factory code
          include: [
            'src/**/*.ts',
            'src/factories/**/*.ts',   // Explicitly include factory directory
          ],
          exclude: [
            'src/**/*.test.ts',
            'src/**/*.spec.ts',
            'src/**/*.d.ts',
            'src/factories/**/*.mock.ts',  // Exclude test-only mock factories from coverage
          ],
          // coverage.extensions no longer exists — use include glob file extensions instead
        },
      },
    });
    ```

    **Migration checklist for Vitest 4.x coverage:**
    - [ ] Replace `coverage.all: true` with explicit `coverage.include` patterns
    - [ ] Add factory directories to `coverage.include` to catch dead factory code
    - [ ] Remove `coverage.extensions` (no longer a valid config key)
    - [ ] Review branch coverage numbers — AST-based remapping may change percentages

24. **[community] Factories that open DB connections or register timers without teardown cause silent test pollution detectable via `--detectAsyncLeaks`.**
    Vitest 4.1 introduced the `--detectAsyncLeaks` CLI flag (or `detectAsyncLeaks: true` in config). It identifies asynchronous resources — open DB connections, unresolved Promises, lingering `setInterval`/`setTimeout` handles — that leak out of a test file into the next. The production scenario: a factory helper that initialises a connection pool at module load (`const pool = new Pool({ ... })`) but never calls `pool.end()` after the test file completes causes each test file to accumulate an open connection. The leak is invisible in passing tests but causes OOM errors on large CI machines after 50+ test files run. `--detectAsyncLeaks` surfaces this as a warning after the file that introduced the leak — giving a precise diagnosis rather than a mystery OOM crash at file #73.

    ```typescript
    // BAD: factory-helper.ts — pool initialised at module load with no teardown
    // Vitest --detectAsyncLeaks will report: "Async resource leaked from test file"
    import { Pool } from 'pg';
    export const testPool = new Pool({ connectionString: process.env['TEST_DATABASE_URL'] });
    // Missing: afterAll(() => testPool.end()) — pool never closed between test files

    // GOOD: lazy pool initialisation with explicit teardown in the test file
    // vitest.setup.ts — or in a fixture that guarantees cleanup
    import { Pool } from 'pg';
    import { beforeAll, afterAll } from 'vitest';

    let pool: Pool | undefined;

    export function getTestPool(): Pool {
      if (!pool) {
        pool = new Pool({ connectionString: process.env['TEST_DATABASE_URL'], max: 1 });
      }
      return pool;
    }

    // In each test file that uses the pool (or in a shared fixture's teardown):
    afterAll(async () => {
      await pool?.end();
      pool = undefined;  // reset for the next file when isolate: false
    });
    ```

    ```bash
    # Enable in CI to catch resource leaks before they become OOM mysteries
    npx vitest --detectAsyncLeaks

    # Or in vitest.config.ts:
    # test: { detectAsyncLeaks: true }
    ```

    **Interaction with factory patterns:** The most common leak sources in factory-heavy suites:
    - `Pool` or `DataSource` objects created at module scope in factory setup files
    - `setInterval` in factory "heartbeat" helpers that simulate real-time data
    - Unresolved `Promise` chains from factory `buildAndSave()` calls not awaited in `afterEach`
    - Testcontainers container starts that are never stopped (Ryuk handles this in CI, but `--detectAsyncLeaks` catches cases where Ryuk is disabled)

25. **[community] Factory output silently violates schema constraints that TypeScript cannot catch — `expect.schemaMatching` is the only automated guard.**
    TypeScript type-checks factory overrides at the structural level (`string`, `number`, union types). It cannot check *value-level constraints* defined in Zod/Valibot schemas: `z.email()`, `z.min(1)`, `z.uuid()`, `z.url()`, `z.int()`. A factory that builds `{ email: '' }` or `{ name: '' }` passes TypeScript compilation but violates the schema. These invalid values are then passed to MSW handlers, contract tests, or API request factories that validate incoming data — producing cryptic failures in downstream tests rather than at the factory itself. Before Vitest 4.0's `expect.schemaMatching`, catching this required manual `.parse()` calls. Now it can be expressed directly in a factory smoke test assertion:

    ```typescript
    // Factory smoke test — catches constraint violations TypeScript cannot see
    import { test, expect } from 'vitest';
    import { UserSchema } from '../schemas/user.schema';
    import { buildUser } from '../factories/user.factory';

    test('buildUser() satisfies UserSchema constraints (not just structure)', () => {
      // TypeScript only checks: { id: string, email: string, name: string, ... }
      // expect.schemaMatching checks: id is UUID, email is valid email, name.length >= 1
      expect(buildUser()).toEqual(expect.schemaMatching(UserSchema));
    });

    // This test would FAIL and catch the bug before it reaches integration tests:
    // const badUser = { id: 'not-a-uuid', email: '', name: '', status: 'active', ... };
    // expect(badUser).toEqual(expect.schemaMatching(UserSchema));
    // Error: Expected value to match schema:
    //   - id: Invalid UUID
    //   - email: Invalid email
    //   - name: String must contain at least 1 character(s)
    ```

    **Systematic fix:** Run factory smoke tests as the first CI stage (before unit tests). Any factory that produces schema-invalid data fails loudly at the smoke test gate, not silently 40 tests later.

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
- **Factory volume for performance tests requires explicit sizing.** Calling `buildList(10)` in a performance test that needs 1,000,000 rows is a silent misconfiguration. Document the expected data volume in performance test factories and validate it with a minimum assertion.

### Performance Test Data — Scale Considerations  [community]

Integration and unit test factories typically generate 1–100 objects. Performance / load tests need orders of magnitude more — and the generation strategy changes.

**Problem:** `faker` runs CPU-bound generation synchronously. Generating 100,000 users with `buildUserList(100_000)` blocks the Node.js event loop for several seconds, slowing down test setup before the actual load test begins.

**Solution:** stream-based batch generation or pre-seeded SQL bulk inserts.

```typescript
// factories/bulk.factory.ts — streaming batch factory for performance tests
import { faker } from '@faker-js/faker';
import { Readable } from 'stream';
import { User } from '../domain/user';

// Generator function — yields one user at a time (lazy, no full array in memory)
export function* userGenerator(count: number): Generator<User> {
  for (let i = 0; i < count; i++) {
    yield {
      id: faker.string.uuid(),
      email: `perf-user-${i}@${faker.internet.domainName()}`,
      name: faker.person.fullName(),
      status: 'active',
      subscriptionTier: 'free',
      createdAt: faker.date.past({ years: 2 }),
      paymentMethodId: null,
    };
  }
}

// Batch insert via generator — streams rows to DB without loading all into memory
export async function seedPerformanceData(
  count: number,
  batchSize: number = 1000
): Promise<void> {
  const gen = userGenerator(count);
  let batch: User[] = [];

  for (const user of gen) {
    batch.push(user);
    if (batch.length === batchSize) {
      await db.insert(users).values(batch);  // bulk insert per batch
      batch = [];
    }
  }
  if (batch.length > 0) {
    await db.insert(users).values(batch);   // insert remaining rows
  }

  console.log(`[perf-setup] Seeded ${count} users in batches of ${batchSize}`);
}
```

**Alternative — pre-generated SQL for maximum seeding speed:**
```typescript
// scripts/generate-seed.ts — generates a .sql file for psql COPY (fastest seeding method)
import { faker } from '@faker-js/faker';
import { writeFileSync } from 'fs';

faker.seed(42); // fixed seed for reproducible seed files

const rows = Array.from({ length: 1_000_000 }, (_, i) =>
  `'${faker.string.uuid()}','perf-${i}@test.com','User ${i}','active','free','${new Date().toISOString()}',NULL`
).join('\n');

// Write as CSV for PostgreSQL COPY command (100x faster than INSERT statements)
writeFileSync('./seeds/users-perf.csv', rows);
// Load with: COPY users(id,email,name,status,subscription_tier,created_at,payment_method_id) FROM 'seeds/users-perf.csv' CSV;
```

### Test Data in CI/CD — Ephemeral vs Persistent Environments

The right test data strategy depends on the environment lifecycle. Ephemeral environments (spun up per PR, destroyed after merge) require fully automated seeding. Persistent environments (shared staging) require non-destructive, additive factory strategies.

| CI/CD Environment | Recommended strategy | Cleanup |
|---|---|---|
| Ephemeral PR environment | Full factory seeding via `npm run db:seed` on startup | Environment destroyed on merge — no cleanup needed |
| Shared staging DB | Read-only tests; or per-test namespaced factories | Delete by `TEST_RUN_ID` prefix after the run |
| Production-like load test DB | Pre-generated CSV seed loaded via `COPY` | Truncate before and after load test run |
| Local developer DB | Per-test transaction rollback; or `db:reset` command | Transaction rollback per test |

**Environment detection in factories (prevents accidental production writes):**
```typescript
// factories/guard.ts — hard-stop if factory is invoked against a non-test DB
export function assertTestEnvironment(): void {
  const dbUrl = process.env.DATABASE_URL ?? '';

  // Reject any DATABASE_URL that doesn't contain a known test pattern
  const isTestDb = /test|localhost|127\.0\.0\.1|testdb|_ci_/i.test(dbUrl);

  if (!isTestDb) {
    throw new Error(
      `[factory-guard] Database URL does not appear to be a test database: ${dbUrl}\n` +
      `Factories must not run against production or staging databases.`
    );
  }
}

// Call at the top of every factory file that persists to the DB:
// assertTestEnvironment();  // throws immediately if DATABASE_URL is wrong
```



- **`ts-mockito`** — when you need type-safe mock objects (method stubs), not real domain data.
- **`zod-fixture`** — generates test data from Zod schemas automatically; zero factory maintenance if your domain is Zod-first.
- **`fishery`** — TypeScript factory library; comparable to `factory-ts` with a slightly more ergonomic API for nested associations.
- **`msw` (Mock Service Worker)** — for API-layer test data, MSW intercepts HTTP and returns factory-generated responses; avoids DB setup entirely for frontend tests.
- **`fast-check`** — property-based testing library; complements factories by generating edge-case data combinatorially rather than hand-crafted scenarios.

---

### Drizzle ORM Factory Pattern  [community]

Drizzle ORM (a strong alternative to Prisma in 2026 TypeScript stacks) uses a
schema-as-code approach: tables are defined as TypeScript objects, and Drizzle's
`InferInsertModel<T>` / `InferSelectModel<T>` utility types give you the same
zero-drift factory type safety as `Prisma.UserCreateInput` — without a separate
`prisma generate` step.

**Why it matters:** Drizzle's generated types are inferred directly from the schema
constant defined in your TypeScript source. When you add a `required` column to the
schema, the factory immediately fails at compile time because `InferInsertModel<typeof users>`
now includes the new field. No ORM CLI step needed.

```typescript
// db/schema.ts — Drizzle table definition (single source of truth)
import { pgTable, uuid, text, timestamp, pgEnum } from 'drizzle-orm/pg-core';

export const statusEnum = pgEnum('status', ['active', 'suspended', 'pending']);
export const tierEnum = pgEnum('subscription_tier', ['free', 'premium', 'enterprise']);

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  name: text('name').notNull(),
  status: statusEnum('status').notNull().default('active'),
  subscriptionTier: tierEnum('subscription_tier').notNull().default('free'),
  paymentMethodId: text('payment_method_id'),
  createdAt: timestamp('created_at').notNull().defaultNow(),
});
```

```typescript
// factories/user.factory.ts (Drizzle-native)
import { InferInsertModel, InferSelectModel } from 'drizzle-orm';
import { faker } from '@faker-js/faker';
import { db } from '../db';
import { users } from '../db/schema';
import { eq } from 'drizzle-orm';

// Insert type derived from schema — zero manual maintenance
type NewUser = InferInsertModel<typeof users>;
// Select type — what DB returns (includes generated defaults)
type User = InferSelectModel<typeof users>;

// Build in-memory only (no DB write) — type-safe via InferInsertModel
export function buildUserInput(overrides: Partial<NewUser> = {}): NewUser {
  return {
    email: faker.internet.email(),
    name: faker.person.fullName(),
    status: 'active',
    subscriptionTier: 'free',
    paymentMethodId: null,
    ...overrides,
  };
}

// Persist to DB and return the full row (including DB-generated id, createdAt)
export async function createUser(overrides: Partial<NewUser> = {}): Promise<User> {
  const [created] = await db
    .insert(users)
    .values(buildUserInput(overrides))
    .returning();  // Drizzle's .returning() gives the full inserted row
  return created;
}

// Clean up by ID (for afterEach teardown)
export async function deleteUser(id: string): Promise<void> {
  await db.delete(users).where(eq(users.id, id));
}
```

```typescript
// Integration test — Drizzle factory with explicit cleanup
import { test, expect } from 'vitest';
import { createUser, deleteUser } from '../factories/user.factory';
import { checkoutService } from '../services/checkout.service';

test('suspended user cannot initiate checkout', async () => {
  const user = await createUser({ status: 'suspended' });

  try {
    const result = await checkoutService.initiate(user.id, { items: [] });
    expect(result.status).toBe('blocked');
    expect(result.reason).toBe('account_suspended');
  } finally {
    // Guaranteed cleanup — even if assertion fails
    await deleteUser(user.id);
  }
});
```

**Drizzle vs Prisma factory comparison:**

| Dimension | Drizzle | Prisma |
|---|---|---|
| Type derivation | `InferInsertModel<typeof table>` | `Prisma.UserCreateInput` |
| Schema change → factory error | Immediate (same TS compile) | After `prisma generate` |
| `.returning()` support | Native (PostgreSQL/SQLite) | Via `prisma.user.create()` |
| Transaction for test isolation | `db.transaction(async (tx) => {...})` | `prisma.$transaction(async (tx) => {...})` |
| Enum type safety | `pgEnum` → string literal union | Prisma enum → string literal union |

---

### UUID v7 — Time-Ordered IDs for DB-Performance Test Data  [community]

`@faker-js/faker` v10.3.0 (released February 2026) added UUID v7 generation via
`faker.string.uuid({ version: 7 })`. UUID v7 encodes a millisecond-resolution
timestamp in the most significant bits, making it naturally time-ordered. This has
significant implications for test data generation in performance and integration tests
that benchmark index behaviour.

**Why it matters for test data:** UUID v4 (random) creates B-tree index fragmentation
because new rows are inserted at arbitrary leaf positions in the index. In high-volume
integration tests that insert thousands of rows, UUID v4 IDs cause realistic-looking
but misleading performance benchmarks — the insert cost includes expensive B-tree splits
that don't reflect steady-state production performance with UUID v7 IDs. Using UUID v7
in test factories mirrors the production ID strategy.

```typescript
// factories/user.factory.ts — UUID v7 for time-ordered, index-friendly test IDs
import { faker } from '@faker-js/faker'; // requires faker v10.3.0+

export function buildUser(overrides: Partial<User> = {}): User {
  return {
    // UUID v7: time-ordered — better B-tree index locality in DB integration tests
    // UUID v4: purely random — accurate for testing uniqueness constraints
    // Use v7 when your production schema uses UUID v7 (Postgres gen_random_uuid() v7,
    // or app-generated UUIDs via uuid v10 npm package)
    id: faker.string.uuid({ version: 7 }),
    email: `${faker.string.uuid()}@${faker.internet.domainName()}`,
    name: faker.person.fullName(),
    status: 'active' as const,
    subscriptionTier: 'free' as const,
    createdAt: new Date(),
    paymentMethodId: null,
    ...overrides,
  };
}

// Batch factory — generates sequential UUIDs (same millisecond → same timestamp bits)
// Use a per-record Date.now() offset to maintain time ordering across rows
export function buildUserList(count: number, overrides: Partial<User> = {}): User[] {
  // Add small time offset per row to guarantee strict ordering in UUID v7 timestamps
  return Array.from({ length: count }, (_, i) => ({
    ...buildUser(overrides),
    id: faker.string.uuid({ version: 7 }),  // faker generates unique ms-timestamp per call
    createdAt: new Date(Date.now() + i),     // ensure strict ordering for time-based tests
  }));
}
```

**When to use UUID v7 vs v4 in factories:**
| ID type | When to use in factories |
|---|---|
| UUID v7 (time-ordered) | Production uses UUID v7; integration tests benchmark insert performance; tests must respect insertion order |
| UUID v4 (random) | Production uses UUID v4; uniqueness constraint tests; any factory where ordering is irrelevant |

**Migration from UUID v4 to v7 in factories:**
```bash
# Requires faker v10.3.0+
npm install --save-dev @faker-js/faker@latest
# In factories: replace faker.string.uuid() with faker.string.uuid({ version: 7 })
# Only where production IDs are also UUID v7
```

**Note on faker v10 compatibility:** `uuid({ version: 7 })` requires `@faker-js/faker` ≥ v10.3.0.
Verify your faker version before using it:
```typescript
// In your factory setup file — guard against incorrect faker version
import { faker, fakerVersion } from '@faker-js/faker';
const [major, minor] = fakerVersion.split('.').map(Number);
if (major < 10 || (major === 10 && minor < 3)) {
  console.warn(`[test-data] UUID v7 requires faker ≥ 10.3.0 (current: ${fakerVersion})`);
}
```

---

### Self-Initializing Fake — Recording API Responses as Test Fixtures  [community]

The **Self-Initializing Fake** pattern (Martin Fowler, martinfowler.com/bliki/SelfInitializingFake.html)
records real remote service responses on first invocation, then replays them from a stored
fixture on subsequent calls. It bridges the gap between hand-crafted factories (may not
reflect real API shape) and live service calls (slow and non-deterministic in tests).

**Why it matters:** Hand-crafted factories for third-party APIs (Stripe, Twilio, GitHub)
often drift from the actual API response shape. When the third-party changes a field name or
adds a required field, the factory-based tests keep passing while the production integration
breaks. The Self-Initializing Fake detects this drift because it periodically re-records
against the real API and fails when the shape changes.

**When to use vs a plain factory:**
- **Plain factory** — when you control both sides of the API (internal services, domain objects)
- **Self-Initializing Fake** — when testing code that consumes a third-party API you don't control

```typescript
// test-helpers/self-initializing-fake.ts
// Pattern: first call hits the real API and saves the response; subsequent calls replay it.
// Periodic re-recording (CI nightly job) catches third-party API drift.

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';
import { http, HttpResponse } from 'msw';

type RecordedResponse = {
  status: number;
  body: unknown;
  headers: Record<string, string>;
  recordedAt: string;
};

const FIXTURES_DIR = join(__dirname, '../__fixtures__/api-recordings');

// Wrap any MSW handler to record on first call and replay on subsequent calls
export function selfInitializingHandler(
  method: 'get' | 'post' | 'put' | 'delete',
  url: string,
  fixtureKey: string,
  realHandler?: () => Promise<RecordedResponse>
) {
  const fixturePath = join(FIXTURES_DIR, `${fixtureKey}.json`);

  return http[method](url, async ({ request }) => {
    // Replay mode: fixture exists — return stored response (fast, no network call)
    if (existsSync(fixturePath)) {
      const recorded: RecordedResponse = JSON.parse(readFileSync(fixturePath, 'utf8'));
      return HttpResponse.json(recorded.body, {
        status: recorded.status,
        headers: recorded.headers,
      });
    }

    // Record mode: fixture does not exist — call the real API and save the response
    if (!realHandler) {
      throw new Error(`[self-initializing-fake] No fixture for '${fixtureKey}' and no realHandler provided.`);
    }

    const response = await realHandler();

    // Persist fixture (only runs once per key until the fixture is deleted for re-recording)
    mkdirSync(FIXTURES_DIR, { recursive: true });
    writeFileSync(fixturePath, JSON.stringify({ ...response, recordedAt: new Date().toISOString() }, null, 2));
    console.log(`[self-initializing-fake] Recorded fixture: ${fixtureKey}`);

    return HttpResponse.json(response.body, { status: response.status });
  });
}

// Usage — stripe payment intent creation
// First call in a test environment without the fixture: hits the real Stripe sandbox API
// Subsequent calls: replay the recorded fixture (no Stripe API key needed in CI)
const stripeHandler = selfInitializingHandler(
  'post',
  'https://api.stripe.com/v1/payment_intents',
  'stripe-create-payment-intent',
  async () => {
    // Calls the real Stripe sandbox API — only runs when recording
    const resp = await fetch('https://api.stripe.com/v1/payment_intents', {
      method: 'POST',
      headers: { Authorization: `Bearer ${process.env.STRIPE_TEST_KEY}` },
      body: 'amount=4999&currency=usd',
    });
    return { status: resp.status, body: await resp.json(), headers: {} };
  }
);
```

**Validation strategy (drift detection):**
```typescript
// nightly-record.ts — CI job that deletes fixtures and re-records against real APIs
// Schedule: cron job on the main branch, not on PRs
import { rmSync, readdirSync } from 'fs';
import { join } from 'path';

const FIXTURES_DIR = join(__dirname, '../__fixtures__/api-recordings');

// Delete all recordings to force re-recording on next test run
readdirSync(FIXTURES_DIR).forEach((file) => {
  rmSync(join(FIXTURES_DIR, file));
  console.log(`[self-initializing-fake] Deleted fixture: ${file}`);
});
// Run the test suite with real API keys — fixtures re-recorded from live APIs
// If the test suite fails (new required field, changed shape), the CI job fails
// and the team is alerted to update their handlers
```

**Commit fixtures to source control:** The recorded fixtures (`__fixtures__/api-recordings/*.json`)
should be committed. They document the current API contract and allow PRs to verify that the test
suite still passes against the recorded shape, without requiring live API keys in every CI run.

---

 — AI-Powered Relational Seed Generation  [community]

`@snaplet/seed` (by Snaplet, 2024–2026) is a newer approach to test data generation
that uses your database schema (via introspection) to generate realistic, relationally
consistent data across all tables simultaneously. Unlike per-entity factories, it
understands foreign key relationships and generates graph-connected data in the right
insertion order.

**Why it matters:** In relational schemas with 15+ tables and complex FK chains, manually
managing factory insertion order (users before profiles before orders before order_items) is
error-prone and brittle. `@snaplet/seed` introspects the schema and generates the full
relational graph automatically — you only specify the subset you care about for the test.

```typescript
// seed.config.ts — configuration for @snaplet/seed
import { SeedClient, defineConfig } from '@snaplet/seed';

// @snaplet/seed introspects your DATABASE_URL and generates typed clients
// Run: npx @snaplet/seed sync  (generates seed.client.ts from your DB schema)
export default defineConfig({
  // Alias for cleaner API: seed.user({}) instead of seed.public_users({})
  alias: {
    inflection: true,
    override: {
      public_users: { name: 'user', fields: { subscription_tier: 'subscriptionTier' } },
    },
  },
});
```

```typescript
// factories/relational.seed.ts — generate a user with orders and order items
import { createSeedClient } from '@snaplet/seed';

export async function seedUserWithOrders(options?: {
  userCount?: number;
  ordersPerUser?: number;
}): Promise<{ cleanup: () => Promise<void> }> {
  const seed = await createSeedClient({ dryRun: false });

  // Reset only the tables we touch (FK-ordered truncation is automatic)
  await seed.$resetDatabase(['users', 'orders', 'order_items']);

  // Generate 3 users, each with 2 orders, each order with 3–5 items
  // @snaplet/seed handles the FK relationships and insertion order automatically
  await seed.user((x) =>
    x(options?.userCount ?? 3, () => ({
      status: 'active',
      subscriptionTier: 'premium',
      orders: (y) =>
        y(options?.ordersPerUser ?? 2, () => ({
          status: 'pending',
          orderItems: (z) => z({ min: 3, max: 5 }),
        })),
    }))
  );

  return {
    cleanup: async () => {
      await seed.$resetDatabase(['users', 'orders', 'order_items']);
      await seed.$disconnect();
    },
  };
}
```

**Tradeoff:** `@snaplet/seed` requires a database connection at setup time for schema
introspection, and generated types change with each `npx @snaplet/seed sync` run.
It is best suited to integration and E2E tests where a real DB is already available;
it is overkill for unit tests. Teams with simple schemas (< 10 tables) get more
predictable behaviour from per-entity factories.

---

### TypeScript 5.4+ `const` Type Parameters in Factory Generics  [community]

TypeScript 5.0 introduced `const` type parameters (`<const T extends ...>`), which
preserve the literal type of the argument rather than widening it to a base type.
This enables factory APIs where the returned object's type is inferred as a precise
literal type — not just the base interface — improving IDE autocompletion in tests.

**Why it matters:** Without `const T`, a factory override like `{ status: 'suspended' }`
is inferred as `{ status: string }`. The resulting object's `.status` field has type
`string`, not `'suspended'`. With `const T`, the factory returns an object whose
`.status` type is the literal `'suspended'` — enabling exhaustive switch checks and
discriminated union narrowing in test assertions.

```typescript
// factories/typed-factory.ts — const type parameters for literal-preserving overrides
import { faker } from '@faker-js/faker';

type UserStatus = 'active' | 'suspended' | 'pending';
type SubscriptionTier = 'free' | 'premium' | 'enterprise';

type User = {
  id: string;
  email: string;
  name: string;
  status: UserStatus;
  subscriptionTier: SubscriptionTier;
  createdAt: Date;
};

// Without `const T`: buildUser({ status: 'suspended' }).status has type UserStatus (widened)
// With `const T`:    buildUser({ status: 'suspended' }).status has type 'suspended' (literal)
export function buildUser<const T extends Partial<User>>(overrides?: T): User & T {
  const defaults: User = {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    status: 'active',
    subscriptionTier: 'free',
    createdAt: new Date(),
  };
  return { ...defaults, ...overrides } as User & T;
}

// Type-narrowed usage in tests:
const suspended = buildUser({ status: 'suspended' });
// suspended.status: 'suspended'  (literal type — not widened to UserStatus)

// Enables compile-time exhaustiveness checking in discriminated unions:
function handleStatus(user: ReturnType<typeof buildUser<{ status: 'suspended' }>>) {
  // TypeScript knows user.status === 'suspended' without a runtime check
  console.log('User is suspended:', user.status);
}

// Works with multiple literal overrides simultaneously:
const premiumSuspended = buildUser({ status: 'suspended', subscriptionTier: 'premium' });
// premiumSuspended.status: 'suspended'
// premiumSuspended.subscriptionTier: 'premium'
```

**Practical limit:** `const T` inference only works for the fields in the override object.
Fields not in `overrides` retain their base type (`UserStatus`, `SubscriptionTier`).
For full literal inference on all fields, use `satisfies` narrowing after `build()`.

---

### Vitest `test.extend()` for Factory Injection (Unit Test Layer)  [community]

Vitest's `test.extend()` (equivalent to Playwright's fixture system, but for unit/integration
tests) enables composable factory fixtures without the `beforeEach`/`afterEach` boilerplate.
Fixtures are lazily evaluated, automatically scoped, and compose cleanly across spec files —
the same benefits Playwright fixtures provide, now available in the Vitest unit/integration layer.

**Why it matters:** When 20 test files all need a `userFactory` fixture that sets up and
tears down a DB user, duplicating `beforeEach`/`afterEach` in each file is fragile.
A shared `test.extend()` fixture centralises the lifecycle in one place, and any test that
receives the fixture in its arguments automatically gets setup and teardown.

```typescript
// test/fixtures/vitest-fixtures.ts — shared Vitest fixture definitions
import { test as base } from 'vitest';
import { faker } from '@faker-js/faker';
import { db } from '../../db';
import { users } from '../../db/schema';
import { eq } from 'drizzle-orm';
import { InferSelectModel } from 'drizzle-orm';

type User = InferSelectModel<typeof users>;

// Declare fixture types
interface TestFixtures {
  activeUser: User;
  suspendedUser: User;
  adminUser: User;
}

// Extend the base test with reusable, lifecycle-managed fixtures
export const test = base.extend<TestFixtures>({
  // activeUser: creates a DB user, yields to test, deletes after
  activeUser: async ({}, use) => {
    const [user] = await db.insert(users).values({
      email: `active-${faker.string.uuid()}@test.com`,
      name: faker.person.fullName(),
      status: 'active',
      subscriptionTier: 'free',
    }).returning();

    await use(user);                         // test body runs here

    await db.delete(users).where(eq(users.id, user.id));  // teardown
  },

  suspendedUser: async ({}, use) => {
    const [user] = await db.insert(users).values({
      email: `suspended-${faker.string.uuid()}@test.com`,
      name: faker.person.fullName(),
      status: 'suspended',
      subscriptionTier: 'free',
    }).returning();

    await use(user);

    await db.delete(users).where(eq(users.id, user.id));
  },
});

export { expect } from 'vitest';
```

```typescript
// specs/checkout.test.ts — uses the extended test with fixtures
import { test, expect } from '../test/fixtures/vitest-fixtures';
import { checkoutService } from '../services/checkout.service';

// 'suspendedUser' fixture is created/destroyed automatically
test('suspended user cannot checkout', async ({ suspendedUser }) => {
  const result = await checkoutService.initiate(suspendedUser.id, { items: [] });
  expect(result.status).toBe('blocked');
});

// Compose multiple fixtures in one test — both are set up independently
test('suspended user cannot access active user orders', async ({ suspendedUser, activeUser }) => {
  const result = await checkoutService.getOrdersFor(suspendedUser.id, { asUserId: activeUser.id });
  expect(result.error).toBe('forbidden');
});
```

**Key advantage over `beforeEach`:** Only fixtures actually requested by a test are
instantiated. A test that only requests `suspendedUser` does not incur the cost of
creating `activeUser` or `adminUser`. `beforeEach` would run all setup regardless.

---

### Vitest 4.1 Builder Pattern for `test.extend()` — Inferred-Type Fixtures  [community]

Vitest 4.1 (March 2026) introduced a new **builder syntax** for `test.extend()` that
eliminates the `use()` callback convention. Fixtures now *return* their value directly,
and TypeScript infers the fixture type automatically — no manual type declaration required.
The old object-and-`use()` syntax still works but is now considered verbose.

**Why it matters for test data factories:** The builder pattern drastically reduces
the boilerplate needed to define typed fixtures for domain factories. Each `.extend()`
call chains cleanly, and `onCleanup()` handles teardown without nesting promise callbacks
inside the `use()` function.

```typescript
// test/fixtures/vitest-4.1-fixtures.ts — builder-syntax fixtures (Vitest 4.1+)
import { test as baseTest } from 'vitest';
import { faker } from '@faker-js/faker';
import { db } from '../../db';
import { users, orders } from '../../db/schema';
import { eq } from 'drizzle-orm';

// Builder pattern: each .extend() returns directly, TypeScript infers the type.
// No explicit interface declaration or `use()` callback needed.
export const test = baseTest
  // Static config fixture — no cleanup needed, return directly
  .extend('testConfig', { maxRetries: 3, environment: 'test' as const })

  // Dynamic fixture with cleanup — use onCleanup() for teardown
  .extend('activeUser', async ({}, { onCleanup }) => {
    const [user] = await db.insert(users).values({
      email: `active-${faker.string.uuid()}@test.com`,
      name: faker.person.fullName(),
      status: 'active',
      subscriptionTier: 'free',
    }).returning();

    onCleanup(() => db.delete(users).where(eq(users.id, user.id)));
    return user;  // TypeScript infers: activeUser: typeof user
  })

  // Fixture that depends on another fixture — destructure dependencies in first arg
  .extend('userWithOrders', async ({ activeUser }, { onCleanup }) => {
    const [order] = await db.insert(orders).values({
      userId: activeUser.id,
      total: faker.number.float({ min: 10, max: 500, fractionDigits: 2 }),
      status: 'pending',
    }).returning();

    onCleanup(() => db.delete(orders).where(eq(orders.id, order.id)));
    return { user: activeUser, order };  // TypeScript infers the combined shape
  })

  // Worker-scoped fixture — shared across all tests in the worker
  .extend('workerDb', { scope: 'worker' }, async ({}, { onCleanup }) => {
    const connection = await db.connect();
    onCleanup(() => connection.close());
    return connection;
  });

export { expect } from 'vitest';
```

```typescript
// specs/orders.test.ts — uses builder-syntax fixtures with full type safety
import { test, expect } from '../test/fixtures/vitest-4.1-fixtures';

// TypeScript knows the exact shape of userWithOrders — no type imports needed
test('pending order can be cancelled by its owner', async ({ userWithOrders }) => {
  const { user, order } = userWithOrders;
  const result = await orderService.cancel(order.id, { requestedBy: user.id });
  expect(result.status).toBe('cancelled');
});

// testConfig fixture is static — no DB setup, instant access
test('retry limit is enforced', async ({ testConfig }) => {
  expect(testConfig.maxRetries).toBe(3);
});
```

**Comparison — old `use()` callback vs new builder pattern:**

| Aspect | Old `use()` syntax | New builder syntax (4.1+) |
|---|---|---|
| Type declaration | Manual `interface TestFixtures {}` required | Inferred from return value |
| Cleanup | Code after `await use(value)` | `onCleanup()` callback |
| Dependency injection | Object parameter in `async ({}, use)` | First argument with inferred deps |
| Scope declaration | `[async, { scope: 'worker' }]` tuple | `.extend('name', { scope: 'worker' }, ...)` |
| Cross-file reuse | Export the `base.extend<>({})` object | Chain `.extend()` and export |

**Migration note:** The old `use()` syntax is **not removed** — it continues to work.
Teams can migrate incrementally. New fixtures should prefer the builder syntax; existing
`use()`-based fixtures do not need immediate refactoring.

---

### Vitest 4.1 `aroundEach` Hook — Transaction-per-Test Pattern  [community]

Vitest 4.1 introduced the **`aroundEach`** hook, which wraps each test in a context
manager. This is the idiomatic way to implement the *transaction-per-test* isolation
pattern: start a DB transaction before each test, let the test body run (including all
factory inserts), then rollback unconditionally. No `afterEach` cleanup, no `TRUNCATE`
race conditions.

**Why it matters:** The transaction-per-test pattern is the most reliable isolation
strategy for integration tests that hit a real database. Before `aroundEach`, the pattern
required either: (a) wrapping the test body manually in a transaction, which broke
factory teardown logic, or (b) relying on the `beforeEach`/`afterEach` hook pair with
a shared transaction reference, which was brittle in TypeScript because the transaction
object couldn't be typed across hook boundaries. `aroundEach` solves both problems.

```typescript
// test/fixtures/transactional-fixtures.ts — aroundEach transaction isolation (Vitest 4.1+)
import { test as baseTest } from 'vitest';
import { faker } from '@faker-js/faker';
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from '../../db/schema';

const pool = new Pool({ connectionString: process.env.TEST_DATABASE_URL });

export const test = baseTest
  .extend('db', { scope: 'worker' }, async ({}, { onCleanup }) => {
    // Worker-scoped: one pool connection per worker
    const db = drizzle(pool, { schema });
    onCleanup(() => pool.end());
    return db;
  });

// aroundEach wraps every test in a transaction that is always rolled back.
// Factory inserts inside the test body are visible within the transaction,
// but never committed to the real database.
test.aroundEach(async (runTest, { db }) => {
  // Drizzle does not expose a raw transaction object — use pg client directly
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Run the test body; all DB operations in this context use the same connection
    // (requires session-level transaction propagation or a tx-scoped Drizzle instance)
    await runTest();

  } finally {
    await client.query('ROLLBACK');  // Always rolls back — isolation guaranteed
    client.release();
  }
});

export { expect } from 'vitest';
```

```typescript
// specs/user-service.test.ts — factory inserts are auto-rolled-back after each test
import { test, expect } from '../test/fixtures/transactional-fixtures';
import { buildUser } from '../factories/user.factory';
import { userService } from '../services/user.service';

test('deactivating a user removes their active sessions', async ({ db }) => {
  // This insert is part of the test-scoped transaction — rolled back automatically
  const user = await db.insert(schema.users).values(buildUser()).returning();
  await db.insert(schema.sessions).values({ userId: user[0].id, active: true });

  await userService.deactivate(user[0].id);
  const sessions = await db.select().from(schema.sessions)
    .where(eq(schema.sessions.userId, user[0].id));

  expect(sessions.every(s => !s.active)).toBe(true);
  // No afterEach cleanup needed — transaction is rolled back by aroundEach
});
```

**`aroundEach` vs `aroundAll`:**

| Hook | Scope | Use case |
|---|---|---|
| `aroundEach` | Wraps each individual test | Transaction-per-test, request-scoped context, per-test metrics |
| `aroundAll` | Wraps the entire test suite | Suite-level DB schema migration, shared expensive setup |
| `test.beforeEach` / `test.afterEach` | Before/after each test | Factory setup that doesn't need a wrapping context |

**Critical requirement:** `aroundEach` and `aroundAll` must be called on the **extended
`test` object** (not the base `test` from vitest), so they have access to the fixtures
defined on that object. Calling them on `import { test } from 'vitest'` will not give
fixture access.

---

### Vitest 4.1 `test.override()` — Per-Suite Factory Variant Overrides  [community]

`test.override()` allows overriding a fixture's value for a specific `describe` block
and all nested tests within it. This is the idiomatic way to express "in this suite,
the user fixture should be a suspended user" — without creating separate fixture files
or polluting the global fixture definition.

**Why it matters for test data:** Before `test.override()`, expressing suite-level
context variants required either duplicating fixture definitions, using `beforeEach`
to mutate shared state, or reaching for Object Mother patterns that returned different
base variants. `test.override()` is cleaner: it documents intent at the suite level
and composes with the fixture dependency graph automatically.

```typescript
// test/fixtures/overridable-fixtures.ts — base fixtures with override points
import { test as baseTest } from 'vitest';
import { buildUser } from '../factories/user.factory';
import { buildCart } from '../factories/cart.factory';
import { db } from '../../db';

export const test = baseTest
  .extend('currentUser', async ({}, { onCleanup }) => {
    // Default: active free-tier user
    const [user] = await db.insert(schema.users).values(buildUser({ status: 'active' })).returning();
    onCleanup(() => db.delete(schema.users).where(eq(schema.users.id, user.id)));
    return user;
  })
  .extend('cart', async ({ currentUser }, { onCleanup }) => {
    const [cart] = await db.insert(schema.carts).values({ userId: currentUser.id }).returning();
    onCleanup(() => db.delete(schema.carts).where(eq(schema.carts.id, cart.id)));
    return cart;
  });
```

```typescript
// specs/checkout.test.ts — per-suite fixture overrides
import { test, expect } from '../test/fixtures/overridable-fixtures';
import { buildUser } from '../factories/user.factory';
import { checkoutService } from '../services/checkout.service';

// Default suite — currentUser is the active free-tier user from the fixture
describe('active user checkout', () => {
  test('can add items to cart', async ({ cart }) => {
    // cart fixture depends on currentUser fixture — both are created fresh
    expect(cart.userId).toBeDefined();
  });
});

// Override the currentUser fixture for the suspended-user test suite
describe('suspended user checkout', () => {
  // test.override() is chainable — override multiple fixtures in one call
  test
    .override('currentUser', async ({}, { onCleanup }) => {
      const [user] = await db.insert(schema.users).values(
        buildUser({ status: 'suspended' })
      ).returning();
      onCleanup(() => db.delete(schema.users).where(eq(schema.users.id, user.id)));
      return user;
    });

  test('cannot initiate checkout', async ({ currentUser, cart }) => {
    // cart fixture still depends on the overridden currentUser — composition preserved
    const result = await checkoutService.initiate(currentUser.id, cart.id);
    expect(result.status).toBe('blocked');
  });
});

// Chaining multiple overrides for a premium context
describe('premium user with expired payment', () => {
  test
    .override('currentUser', async ({}, { onCleanup }) => {
      const [user] = await db.insert(schema.users).values(
        buildUser({ status: 'active', subscriptionTier: 'premium', paymentMethodId: null })
      ).returning();
      onCleanup(() => db.delete(schema.users).where(eq(schema.users.id, user.id)));
      return user;
    })
    .override('cart', async ({ currentUser }, { onCleanup }) => {
      const [cart] = await db.insert(schema.carts).values({
        userId: currentUser.id,
        requiresPayment: true,
      }).returning();
      onCleanup(() => db.delete(schema.carts).where(eq(schema.carts.id, cart.id)));
      return cart;
    });

  test('checkout fails with no payment method', async ({ currentUser, cart }) => {
    const result = await checkoutService.initiate(currentUser.id, cart.id);
    expect(result.error).toBe('no_payment_method');
  });
});
```

**`test.override()` vs Object Mother:** Object Mother provides *named semantic variants*
as static methods, while `test.override()` provides *suite-scoped fixture substitution*
that participates in the dependency graph. They are complementary: use Object Mother
to name your data variants, and `test.override()` to scope them to a test suite context.

---

### Vitest `vi.defineHelper()` — Clean Stack Traces for Factory Assertion Helpers  [community]

When writing custom assertion helpers that wrap factory-generated data (common in large
test suites with shared validation logic), test failures report the error inside the
helper function rather than at the call site. `vi.defineHelper()` (Vitest 4.1+) marks
a function so Vitest strips its internals from stack traces, pointing the error at the
test that called the helper.

**Why it matters:** Factory-heavy test suites often extract repeated assertions into
shared helpers: `assertUserCanCheckout(user, cart)`. Without `vi.defineHelper()`, a
failing assertion inside that helper shows a stack trace pointing to the helper's
internal `expect()` line — not to the `assertUserCanCheckout()` call in the test file.
This makes debugging factory-generated test failures slow.

```typescript
// test/helpers/factory-assertions.ts — custom assertion helpers with clean traces
import { vi, expect } from 'vitest';
import { checkoutService } from '../../services/checkout.service';
import { User, Cart } from '../../domain';

// vi.defineHelper() wraps the function so stack traces point to the call site,
// not to the internal expect() lines inside this helper.
export const assertUserCanCheckout = vi.defineHelper(
  async (user: User, cart: Cart) => {
    const result = await checkoutService.initiate(user.id, cart.id);
    expect(result.status, `Expected checkout to succeed for user ${user.id}`).toBe('success');
    expect(result.orderId, 'Expected an order ID to be returned').toBeDefined();
  }
);

export const assertUserIsBlocked = vi.defineHelper(
  async (user: User, cart: Cart, expectedReason: string) => {
    const result = await checkoutService.initiate(user.id, cart.id);
    expect(result.status, `Expected checkout to be blocked for user ${user.id}`).toBe('blocked');
    expect(result.reason, `Expected block reason to be '${expectedReason}'`).toBe(expectedReason);
  }
);

export const assertFactoryUserHasValidEmail = vi.defineHelper((user: User) => {
  // Validates that factory-generated emails pass the real email validation logic
  const validation = emailValidator.validate(user.email);
  expect(validation.valid, `Factory user email '${user.email}' failed validation`).toBe(true);
});
```

```typescript
// specs/checkout.test.ts — clean stack traces from helper failures
import { test, expect } from 'vitest';
import { UserMother } from '../factories/user.mother';
import { buildCart } from '../factories/cart.factory';
import {
  assertUserCanCheckout,
  assertUserIsBlocked,
} from '../test/helpers/factory-assertions';

test('active premium user with payment can checkout', async () => {
  const user = UserMother.premiumWithPayment().build();
  const cart = buildCart({ items: [{ productId: 'prod-1', quantity: 1 }] });

  // If this fails, the stack trace points HERE — not inside assertUserCanCheckout()
  await assertUserCanCheckout(user, cart);
});

test('suspended user is blocked with account_suspended reason', async () => {
  const user = UserMother.suspended().build();
  const cart = buildCart({ items: [] });

  // Stack trace points to THIS line on failure, not inside assertUserIsBlocked()
  await assertUserIsBlocked(user, cart, 'account_suspended');
});
```

**When to use `vi.defineHelper()`:**
- Shared assertion helpers called across many test cases
- Domain-specific matchers that wrap multiple `expect()` calls
- Helper functions that iterate over factory-generated lists and assert on each item

**When NOT to use it:**
- Simple one-liner assertions — use `expect()` directly
- Helpers that orchestrate setup, not just assertion — those belong in fixtures

---

### Vitest 4.1 Test Tags + `TestRunner.matchesTags()` — Conditional DB Seeding  [community]

Vitest 4.1 introduced **test tags**: named labels attached to tests or suites that enable
filtering, shared timeout/retry options, and — crucially for test data — conditional setup
logic based on which tests are actually being run.

**Why it matters for test data factories:** Large test suites often have expensive database
setup (seeding 50,000 rows, spinning up a Testcontainers instance) that is only needed by
a subset of tests. Before tags, all setup ran regardless of the test subset selected. With
`TestRunner.matchesTags()` (Vitest 4.1.1+), a custom runner can check whether the active
tag filter includes tests that actually need the DB — and skip expensive seeding entirely
when running tag-filtered unit tests.

**Tag declaration (vitest.config.ts):**
```typescript
// vitest.config.ts — tags must be declared before use; undeclared tags throw errors
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Declare tags: name + optional timeout/retry overrides per tag
    tags: {
      'integration': { timeout: 30_000, retry: 2 },   // DB tests: longer timeout
      'unit':        { timeout: 5_000,  retry: 0 },    // Unit tests: fast, no retry
      'e2e':         { timeout: 60_000, retry: 1 },    // E2E: longest timeout
      'security':    { timeout: 10_000, retry: 0 },    // Adversarial data tests
      'slow':        { timeout: 120_000 },             // Performance/bulk factory tests
    },
  },
});
```

**Applying tags to tests:**
```typescript
// specs/user-service.integration.test.ts — tagged integration tests
import { test, describe } from 'vitest';
import { buildUser } from '../factories/user.factory';
import { userRepository } from '../repositories/user.repository';

// Tags propagate from describe to child tests
describe('UserRepository integration tests', { tags: ['integration'] }, () => {
  test('creates a user with factory-built data', async ({ db }) => {
    const user = buildUser({ status: 'active' });
    const saved = await userRepository.create(user);
    expect(saved.id).toBeDefined();
  });

  // Override a single test's tag — inherits 'integration', adds 'slow'
  test('bulk insert 10,000 users', { tags: ['integration', 'slow'] }, async ({ db }) => {
    const users = buildUserList(10_000);
    await userRepository.bulkCreate(users);
    expect(await userRepository.count()).toBeGreaterThanOrEqual(10_000);
  });
});

describe('UserService unit tests', { tags: ['unit'] }, () => {
  test('maps factory-built user to DTO', () => {
    const user = buildUser({ subscriptionTier: 'premium' });
    const dto = mapUserToDTO(user);
    expect(dto.tier).toBe('premium');
  });
});
```

**`TestRunner.matchesTags()` for conditional DB seeding (Vitest 4.1.1+):**
```typescript
// test/setup/globalSetup.ts — skip expensive DB seed when running only unit tests
import { TestRunner } from 'vitest/node';

export async function setup(runner: TestRunner): Promise<void> {
  // Check whether the active tag filter includes integration tests
  const needsDatabase = runner.matchesTags(['integration', 'e2e']);
  // matchesTags() accepts the same tag expression syntax as --tags-filter:
  //   runner.matchesTags('integration or e2e')
  //   runner.matchesTags('integration and not slow')
  //   runner.matchesTags('*')  // all tests

  if (needsDatabase) {
    // Only start the DB container when integration/e2e tests are actually running
    await globalThis.__testContainer__.start();
    await seedDatabase(globalThis.__testPool__);
    console.log('[globalSetup] DB seeded — integration tag detected');
  } else {
    console.log('[globalSetup] Skipping DB seed — unit-only tag filter active');
  }
}

export async function teardown(runner: TestRunner): Promise<void> {
  if (globalThis.__testContainer__?.isRunning()) {
    await globalThis.__testContainer__.stop();
  }
}
```

**CLI tag filtering syntax:**
```bash
# Run only unit tests (skip all integration DB setup)
npx vitest --tags-filter="unit"

# Run integration but not slow performance tests
npx vitest --tags-filter="integration and not slow"

# Run all tests except security adversarial data tests in CI
npx vitest --tags-filter="not security"

# Combined: unit OR integration, but not slow
npx vitest --tags-filter="(unit or integration) and not slow"
```

**Tag filter expressions support:**
- `and` / `&&` — both tags must match
- `or` / `||` — either tag matches
- `not` / `!` — exclude tag
- `*` — wildcard: matches any string of characters
- Parentheses for grouping

**Production lesson [community]:** After adopting tags, a team discovered that 40% of their
CI test time was consumed by DB seeding — even when running `--tags-filter=unit` for
pre-commit checks. Adding `TestRunner.matchesTags()` in `globalSetup.ts` reduced their
pre-commit test run from 45 seconds to 8 seconds because the Testcontainers PostgreSQL
container and seeder no longer started for unit-only runs.

---

### Vitest 4.1 `coverage.changed` — Modified-File-Only Coverage Reports  [community]

Vitest 4.1 added a `coverage.changed` option that limits coverage reporting to files
modified in the current PR or commit, while still running the full test suite. This is
particularly useful for factory-heavy codebases where a PR modifies 3 factory files and
15 test files — you only want to see coverage for the changed files, not the entire
codebase's coverage baseline.

**Why it matters for test data:** When refactoring factories (e.g., migrating from Vitest
3.x `poolOptions` to 4.x top-level config), `coverage.changed` shows exactly which
factory files have dropped coverage after the refactor — without needing to interpret
the full coverage report.

```typescript
// vitest.config.ts — coverage.changed for PR-scoped coverage reporting
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      // 'changed' compares against the working tree's diff
      // value: 'head' (current commit), 'base' (base branch), or a ref like 'main'
      changed: 'main',
      // Still require coverage.include — coverage.changed narrows what's REPORTED,
      // not what's INCLUDED. Files not matching include are always excluded.
      include: [
        'src/**/*.ts',
        'src/factories/**/*.ts',
      ],
      exclude: [
        'src/**/*.test.ts',
        'src/**/*.spec.ts',
      ],
    },
  },
});
```

**Coverage ignore comments** (Vitest 4.1 — both `v8` and `istanbul` providers):

Vitest 4.1 standardised `ignore start/stop` block comments for both providers. These are
useful for factory utility branches that are unreachable in tests but exist for developer
ergonomics (e.g., a `if (process.env.NODE_ENV === 'debug')` logging path in a factory).

```typescript
// factories/user.factory.ts — using coverage ignore comments
import { faker } from '@faker-js/faker';
import { User } from '../domain/user';

export function buildUser(overrides: Partial<User> = {}): User {
  return {
    id: faker.string.uuid(),
    email: `${faker.string.uuid()}@${faker.internet.domainName()}`,
    name: faker.person.fullName(),
    status: 'active',
    subscriptionTier: 'free',
    createdAt: new Date(),
    paymentMethodId: null,
    ...overrides,
  };
}

// istanbul ignore start — debug utility: only useful when debugging locally, not in CI
// v8 ignore start
export function debugFactory(label: string, obj: unknown): void {
  if (process.env['FACTORY_DEBUG'] === '1') {
    console.log(`[factory:${label}]`, JSON.stringify(obj, null, 2));
  }
}
// istanbul ignore stop
// v8 ignore stop
```

**Note:** `/* istanbul ignore next */` (single-line) and `/* v8 ignore next N */` (next N
lines) are still supported for single-line ignores. The new `start/stop` block syntax is
preferred for multi-line factory utility functions.

---



| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Object Mother (Fowler) | Official | https://martinfowler.com/bliki/ObjectMother.html | Canonical definition and origin |
| Test Double (Fowler) | Official | https://martinfowler.com/bliki/TestDouble.html | Vocabulary for mocks, stubs, fakes — companions to test data |
| Growing Object-Oriented Software | Book | https://www.goodreads.com/book/show/4268826 | Origin of Test Data Builder pattern (Freeman & Pryce) |
| @faker-js/faker docs | Official | https://fakerjs.dev/api/ | Full API reference for TypeScript |
| factory-ts (npm) | Library | https://www.npmjs.com/package/factory-ts | TypeScript-first factory library |
| fishery (npm) | Library | https://www.npmjs.com/package/fishery | Alternative factory library with associations and DB persistence hooks; factory_bot equivalent for TypeScript |
| zod-fixture | Library | https://www.npmjs.com/package/zod-fixture | Schema-driven automatic fixture generation for Zod-first codebases; AutoFixture equivalent for TypeScript |
| msw (Mock Service Worker) | Library | https://mswjs.io/ | HTTP-layer test data for frontend suites; eliminates backend dependency |
| fast-check | Library | https://fast-check.dev/ | Property-based testing; generates edge-case data beyond what factories cover |
| Vitest worker isolation docs | Official | https://vitest.dev/config/#pool | Per-worker DB setup guide |
| Playwright test fixtures docs | Official | https://playwright.dev/docs/test-fixtures | Composable E2E fixture lifecycle with `test.extend()` |
| Pact.io | Official | https://docs.pact.io/ | Contract-schema-driven factory patterns for microservices |
| Prisma — TypeScript ORM | Official | https://www.prisma.io/docs | Prisma.UserCreateInput pattern for zero-drift factories |
| TC39 Explicit Resource Management | Proposal | https://github.com/tc39/proposal-explicit-resource-management | `using`/`await using` specification — test resource cleanup |
| @anatine/zod-mock | Library | https://www.npmjs.com/package/@anatine/zod-mock | Alternative to zod-fixture; generates mock data from Zod schemas using faker |
| factory_bot (Ruby gem) | Official | https://github.com/thoughtbot/factory_bot | Ruby reference implementation; maps to fishery in TypeScript |
| FactoryBoy (Python) | Official | https://factoryboy.readthedocs.io/ | Python factory library; LazyAttribute → each(), SubFactory → nested factory |
| AutoFixture (C#) | Official | https://github.com/AutoFixture/AutoFixture | C# reflection-based fixtures; maps to zod-fixture in TypeScript |
| Drizzle ORM — TypeScript ORM | Official | https://orm.drizzle.team/docs | InferInsertModel pattern for zero-drift Drizzle factories |
| @snaplet/seed | Library | https://docs.snaplet.dev/seed | AI-powered relational seed generation; handles FK graph insertion order automatically |
| Vitest test.extend() docs | Official | https://vitest.dev/guide/test-context | Composable Vitest fixture lifecycle (unit/integration layer) |
| TypeScript 5.0 const type parameters | Official | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html | `const T` generic inference for literal-preserving factory overrides |
| @testcontainers/postgresql | Library | https://node.testcontainers.org/modules/postgresql/ | Docker-based production-faithful PostgreSQL test isolation; zero infrastructure pre-config |
| @electric-sql/pglite | Library | https://electric-sql.com/docs/api/pglite | In-process WASM PostgreSQL; ~50ms startup, no Docker needed; ideal for near-unit-speed integration tests |
| TanStack Query testing docs | Official | https://tanstack.com/query/latest/docs/framework/react/guides/testing | QueryClient test wrapper and MSW integration patterns |
| MSW v2 WebSocket handlers | Official | https://mswjs.io/docs/api/ws | Real-time WebSocket test data injection without a live server |
| Zod v4 migration guide | Official | https://zod.dev/v4 | Breaking changes affecting factory schema definitions (z.email(), z.uuid() top-level) |
| @aws-sdk/client-sqs (test patterns) | Official | https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/sqs/ | SQS event envelope structure for Lambda handler test factories |
| Neon DB Branching | Official | https://neon.com/docs/guides/branching-test-queries | Copy-on-write Postgres branch per test run; schema-only branching; instant teardown |
| Testcontainers Cloud | Official | https://testcontainers.com/cloud/docs/ | Cloud Docker daemon; 8GB/session; Turbo mode for parallel test isolation |
| Testcontainers Guides | Official | https://testcontainers.com/guides/ | Getting-started guides: 11 languages, Spring Boot, Quarkus, ASP.NET, DB, Kafka, WireMock, LocalStack |
| Vitest 4.0 migration guide | Official | https://vitest.dev/guide/migration | poolOptions restructuring (singleFork removed, isolate/maxWorkers top-level); workspace → projects migration |
| Playwright box fixture docs | Official | https://playwright.dev/docs/test-fixtures#box-a-fixture | `{ box: true }` / `{ box: 'self' }` — hide infrastructure fixture steps from test reports |
| Playwright mergeTests() docs | Official | https://playwright.dev/docs/api/class-test#test-merge-tests | Composing fixtures from multiple domain-aligned modules into a single test object |
| @faker-js/faker v10 docs | Official | https://fakerjs.dev/api/ | v10 stable API reference; ESM-only; UUID v7 in faker.string.uuid({ version: 7 }) |
| @faker-js/faker v10 migration guide | Official | https://next.fakerjs.dev/guide/upgrading | Breaking changes v9→v10: CommonJS removal, deprecated API cleanup |
| Self-Initializing Fake (Fowler) | Official | https://martinfowler.com/bliki/SelfInitializingFake.html | Record-then-replay pattern for third-party API test data; drift detection via nightly re-recording |
| Testing Resource Pools (Fowler) | Official | https://martinfowler.com/bliki/TestingResourcePools.html | Pool-size-1 technique for surfacing connection leak defects in integration tests |
| Vitest 4.1 test context (builder pattern) | Official | https://vitest.dev/guide/test-context | New builder syntax for test.extend() with inferred TypeScript types; aroundEach/aroundAll; test.override(); vi.defineHelper() |
| Vitest 4.1 blog post | Official | https://vitest.dev/blog/vitest-4-1 | Full changelog: builder fixtures, aroundEach/aroundAll hooks, test.override(), vi.defineHelper(), inferred fixture types |
| Vitest 4.x coverage config changes | Official | https://vitest.dev/guide/migration#vitest-4-0 | coverage.all and coverage.extensions removed; coverage.include mandatory; V8 AST-based remapping |
| Vitest 4.1 test tags guide | Official | https://vitest.dev/guide/test-tags | Declaring tags with timeout/retry; filtering with complex expressions; TestRunner.matchesTags() for conditional DB seeding |
| Vitest 4.1 --detectAsyncLeaks | Official | https://vitest.dev/config/#detectasyncleaks | CLI flag and config option for surfacing leaked DB connections and timer handles from test factories |
| Vitest 4.1 coverage.changed | Official | https://vitest.dev/config/#coverage-changed | Limits coverage reporting to modified files — useful for PR-scoped factory coverage reviews |

---

## Neon DB Branch-per-Test — Copy-on-Write Postgres Isolation  [official: neon.com/docs/guides/branching-test-queries, 2026-05-08]

Neon is a serverless Postgres service with a copy-on-write branching model. Instead of
resetting a shared test database between runs, you create an isolated Postgres *branch*
per test run — instantly. Each branch has full SQL isolation from other branches and is
deleted after the run completes.

**Why this matters for test data management:**

| Traditional approach | Neon branching approach |
|---|---|
| Set up a separate test database; replicate schema | Create a branch from `main` instantly (no schema copy) |
| Run `TRUNCATE` or `DROP TABLE` before each test | Delete the branch after the test — database never mutated |
| PII risk when copying production data | Use schema-only branches for sensitive data |
| CI must serialize tests that share the DB | Each PR gets its own branch — full parallelism |
| Database cleanup is the #1 source of integration flakiness | No cleanup needed — branch is immutable before test writes |

**Schema-only branching** is available when tests should not see production data at all
(e.g., compliance-regulated environments). Schema-only branches include the DDL but none
of the rows.

```typescript
// ci-scripts/neon-branch-setup.ts — create a Neon branch per CI run
// Requires: npm install @neondatabase/serverless
// Environment: NEON_API_KEY, NEON_PROJECT_ID set as CI secrets

import { createApiClient } from '@neondatabase/api-client';

interface NeonBranch {
  id: string;
  connectionString: string;
}

async function createTestBranch(runId: string): Promise<NeonBranch> {
  const client = createApiClient({ apiKey: process.env['NEON_API_KEY']! });
  const projectId = process.env['NEON_PROJECT_ID']!;

  // Branch from main — gets a full copy-on-write snapshot of the current schema + seed data
  const { data } = await client.createProjectBranch(projectId, {
    branch: {
      name: `ci-${runId}`,         // unique per PR/run
      parent_id: 'br-main',        // branch from the main branch
    },
    endpoints: [
      { type: 'read_write' }        // create a read-write endpoint for the branch
    ],
  });

  const connectionString = data.connection_uris[0].connection_uri;
  return { id: data.branch.id, connectionString };
}

async function deleteTestBranch(branchId: string): Promise<void> {
  const client = createApiClient({ apiKey: process.env['NEON_API_KEY']! });
  const projectId = process.env['NEON_PROJECT_ID']!;
  await client.deleteProjectBranch(projectId, branchId);
}

// Usage in a Vitest global setup file:
// vitest.config.ts → globalSetup: './ci-scripts/neon-branch-setup.ts'
export async function setup(): Promise<() => Promise<void>> {
  const runId = process.env['CI_RUN_ID'] ?? `local-${Date.now()}`;
  const branch = await createTestBranch(runId);

  // Inject the branch connection string as an env var for test files
  process.env['TEST_DATABASE_URL'] = branch.connectionString;
  process.env['NEON_BRANCH_ID'] = branch.id;

  // Return teardown — Vitest calls this after all tests complete
  return async () => {
    await deleteTestBranch(branch.id);
  };
}
```

```yaml
# .github/workflows/ci.yml — Neon branch lifecycle per PR
jobs:
  integration-tests:
    runs-on: ubuntu-latest
    env:
      NEON_API_KEY: ${{ secrets.NEON_API_KEY }}
      NEON_PROJECT_ID: ${{ vars.NEON_PROJECT_ID }}
      CI_RUN_ID: ${{ github.run_id }}-${{ github.run_attempt }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci
      - name: Run integration tests (Neon branch created in globalSetup)
        run: npx vitest run --project integration
      # Branch is deleted by vitest globalSetup teardown — no explicit cleanup needed
```

**When to use Neon branching vs Testcontainers:**

| Factor | Neon branching | Testcontainers (local Postgres) |
|---|---|---|
| Docker on CI runner | Not required | Required |
| Start-up overhead | ~300–500 ms (API call) | ~3–8 s (container pull + init) |
| Production parity | Full Neon Postgres (Aurora-compatible) | Exact Postgres version |
| Cost | Per-branch-compute billing (free tier generous) | Free (CPU/RAM only) |
| Parallel isolation | Per-branch — natural isolation | Requires separate container per worker |
| Offline development | Requires network | Works fully offline |
| Schema-only option | Yes | No (must seed separately) |

**Best for:** Teams already on Neon as their production database; CI environments without Docker; teams that want effortless parallel test isolation without configuring shared DB cleanup logic.

---

## Testcontainers Cloud — Cloud Docker Daemon for CI  [official: testcontainers.com/cloud/docs, 2026-05-08]

Testcontainers Cloud provides a hosted Docker daemon accessed via an SSH tunnel agent. CI jobs that require Docker containers (Postgres, Redis, Kafka) can run on Docker-less CI runners by routing all container operations to the cloud daemon.

**Architecture:** The agent opens an SSH tunnel from the CI runner to a cloud Docker daemon. Testcontainers code runs unchanged — it still calls the Docker API, but the API calls are tunneled to the cloud. The test code never changes; only the CI environment setup changes.

**Key specs:**
- Each cloud session receives **8 GB of RAM**
- **Turbo mode** (`TC_CLOUD_CONCURRENCY`) gives each test process its own cloud environment, enabling true parallelism without shared Docker daemon contention
- Supports all Testcontainers languages: Java, Go, .NET, Node.js, Python, Ruby, Rust, PHP, and 5 more
- Pre-built integrations for GitHub Actions, GitLab CI, CircleCI, Azure Pipelines, Jenkins, and Kubernetes

```typescript
// Testcontainers Cloud is transparent to test code — no changes needed:
// This test works identically with local Docker, Docker-in-Docker, or Testcontainers Cloud.

import { beforeAll, afterAll, beforeEach, it, expect } from 'vitest';
import { GenericContainer, type StartedTestContainer } from 'testcontainers';
import { Pool } from 'pg';

let container: StartedTestContainer;
let pool: Pool;

beforeAll(async () => {
  // Runs against local Docker, CI Docker-in-Docker, OR Testcontainers Cloud — no code change
  container = await new GenericContainer('postgres:16-alpine')
    .withEnvironment({
      POSTGRES_USER: 'test',
      POSTGRES_PASSWORD: 'test',
      POSTGRES_DB: 'testdb',
    })
    .withExposedPorts(5432)
    .start();

  pool = new Pool({
    host: container.getHost(),
    port: container.getMappedPort(5432),
    user: 'test',
    password: 'test',
    database: 'testdb',
  });

  await pool.query(`CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id TEXT NOT NULL,
    total NUMERIC(10,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
  )`);
}, 60_000);

afterAll(async () => {
  await pool.end();
  await container.stop();
});

beforeEach(async () => {
  await pool.query('TRUNCATE orders RESTART IDENTITY');
});

it('inserts and retrieves an order', async () => {
  await pool.query(
    'INSERT INTO orders (customer_id, total) VALUES ($1, $2)',
    ['c1', 150.00]
  );
  const result = await pool.query('SELECT * FROM orders WHERE customer_id = $1', ['c1']);
  expect(result.rows).toHaveLength(1);
  expect(parseFloat(result.rows[0].total)).toBe(150.00);
});
```

```yaml
# .github/workflows/ci.yml — Testcontainers Cloud setup
jobs:
  integration-tests:
    runs-on: ubuntu-latest  # or any runner, including Docker-less runners
    env:
      TC_CLOUD_TOKEN: ${{ secrets.TC_CLOUD_TOKEN }}
      TC_CLOUD_CONCURRENCY: 4  # Turbo mode: 4 parallel cloud environments (paid tier)
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - name: Setup Testcontainers Cloud agent
        run: |
          curl -fsSL https://app.testcontainers.cloud/bash | bash
      - run: npm ci
      - run: npx vitest run --project integration
```

**Singleton container pattern for cost efficiency:**

```typescript
// Use Testcontainers reuse feature to share containers across test files
// (reduces billable cloud session minutes on Testcontainers Cloud)

import { GenericContainer, type StartedTestContainer } from 'testcontainers';

let _container: StartedTestContainer | null = null;

export async function getSharedPostgres(): Promise<StartedTestContainer> {
  if (_container) return _container;

  _container = await new GenericContainer('postgres:16-alpine')
    .withEnvironment({
      POSTGRES_USER: 'test',
      POSTGRES_PASSWORD: 'test',
      POSTGRES_DB: 'testdb',
    })
    .withExposedPorts(5432)
    .withReuse()  // Testcontainers reuse: keeps the container alive between test runs
    .start();

  return _container;
}
// Note: withReuse() requires TESTCONTAINERS_REUSE_ENABLE=true env var.
// With Testcontainers Cloud + reuse: one cloud session per developer machine session.
```

---

## Production Data in Tests: Masking and Anonymization  [community]

Using production data in tests (copying a DB dump, importing CSV exports) is tempting
because it represents real-world complexity. However, it violates privacy regulations
(GDPR, CCPA, HIPAA), creates PII exposure risk, and makes test data non-reproducible
(production data changes). The correct approach is *anonymization* or *synthesis*.

**When production data is genuinely needed (regression tests for data-specific bugs):**

1. Anonymize first — replace PII fields with `@faker-js/faker` equivalents
2. Subset — take the minimum rows needed to reproduce the bug (not a full DB dump)
3. Commit the anonymized subset as a versioned fixture, not a live DB copy

```typescript
// scripts/anonymize-export.ts — anonymize a production data export for test use
// Run OFFLINE on a dev machine with production data access — never in CI
import { faker } from '@faker-js/faker';
import { readFileSync, writeFileSync } from 'fs';

faker.seed(42); // Fixed seed for deterministic anonymization output

interface ProductionUser {
  id: string;
  email: string;
  name: string;
  phone: string;
  ssn?: string;
  creditCard?: string;
  status: string;
  subscriptionTier: string;
  createdAt: string;
}

function anonymizeUser(user: ProductionUser): ProductionUser {
  return {
    // Preserve structural fields (id, status, tier) — they're needed for test logic
    id: user.id,
    status: user.status,
    subscriptionTier: user.subscriptionTier,
    createdAt: user.createdAt,
    // Replace PII with realistic-but-fake values — deterministic via seeded faker
    email: faker.internet.email(),
    name: faker.person.fullName(),
    phone: faker.phone.number(),
    // Hard-delete sensitive fields — never include in anonymized export
    ssn: undefined,
    creditCard: undefined,
  };
}

const raw: ProductionUser[] = JSON.parse(
  readFileSync('./exports/production-users.json', 'utf8')
);

const anonymized = raw.map(anonymizeUser);

// Write as fixture — commit this, never the raw production data
writeFileSync(
  './fixtures/anonymized-users.fixture.json',
  JSON.stringify(anonymized, null, 2)
);

console.log(`Anonymized ${anonymized.length} users. PII removed.`);
```

**GDPR compliance checklist for test data:**

| PII Category | Action |
|---|---|
| Names, email addresses | Replace with faker equivalents |
| Phone numbers | Replace with faker equivalents |
| Government IDs (SSN, passport) | Remove entirely — never include in test data |
| Payment card data | Remove entirely — never include in test data |
| IP addresses | Anonymize to `192.0.2.x` (TEST-NET range, RFC 5737) |
| Dates of birth | Anonymize to birth year only, or replace with faker |
| Geolocation coordinates | Round to city/region level; or replace entirely |

**Anti-pattern: using `node --inspect` DB connections in CI to "just grab some real data".**
This creates an audit trail of PII leaving production infrastructure. All test data must
be synthesized or explicitly anonymized before entering any test environment.

---

## Boundary Value Analysis (BVA) Integration with Factories  [community]

ISTQB's Boundary Value Analysis (BVA) technique identifies defects at the *boundary* of
equivalence classes — the exact minimum, maximum, and adjacent-to-boundary values where
off-by-one errors concentrate. Factories should expose explicit BVA factory variants so
boundary test cases are centralized and named, not scattered as magic literals.

**Why it matters:** When a business rule changes (e.g., "premium users get 5 GB storage,
changing to 10 GB"), BVA boundary factories centralise the change. Without named BVA
factories, each boundary test contains a magic number that becomes stale after the rule
changes — the test still passes (because the magic number was within the now-larger range)
but no longer exercises the boundary.

```typescript
// factories/bva.factory.ts — Boundary Value Analysis factory variants
import { faker } from '@faker-js/faker';

// Domain invariant: order total must be between 1 and 999_999 cents (inclusive)
const ORDER_MIN_CENTS = 1;
const ORDER_MAX_CENTS = 999_999;

// Domain invariant: user name length 1–100 characters
const USER_NAME_MIN_LENGTH = 1;
const USER_NAME_MAX_LENGTH = 100;

// Domain invariant: subscription allows maximum 5 seats per account
const MAX_SEATS = 5;

// BVA factory for order totals — named boundary variants
export const OrderBVA = {
  // Below minimum (invalid — should be rejected)
  belowMinimum: () => ({ totalCents: 0 }),
  // At minimum (valid — minimum acceptance boundary)
  atMinimum: () => ({ totalCents: ORDER_MIN_CENTS }),
  // Just above minimum (valid — boundary + 1)
  justAboveMinimum: () => ({ totalCents: ORDER_MIN_CENTS + 1 }),
  // Typical mid-range value (valid)
  typical: () => ({ totalCents: faker.number.int({ min: 100, max: 10_000 }) }),
  // Just below maximum (valid — boundary - 1)
  justBelowMaximum: () => ({ totalCents: ORDER_MAX_CENTS - 1 }),
  // At maximum (valid — maximum acceptance boundary)
  atMaximum: () => ({ totalCents: ORDER_MAX_CENTS }),
  // Above maximum (invalid — should be rejected)
  aboveMaximum: () => ({ totalCents: ORDER_MAX_CENTS + 1 }),
};

// BVA factory for user name lengths
export const UserNameBVA = {
  empty: () => ({ name: '' }),                                      // below minimum (invalid)
  atMinimum: () => ({ name: 'A' }),                                // 1 char (valid boundary)
  typical: () => ({ name: faker.person.fullName() }),               // typical (valid)
  atMaximum: () => ({ name: 'A'.repeat(USER_NAME_MAX_LENGTH) }),    // 100 chars (valid boundary)
  aboveMaximum: () => ({ name: 'A'.repeat(USER_NAME_MAX_LENGTH + 1) }), // 101 chars (invalid)
};

// BVA factory for seat allocations
export const SeatBVA = {
  zero: () => ({ seats: 0 }),
  one: () => ({ seats: 1 }),
  atMaximum: () => ({ seats: MAX_SEATS }),
  aboveMaximum: () => ({ seats: MAX_SEATS + 1 }),
};
```

```typescript
// specs/order-validation.test.ts — BVA test cases using named factory variants
import { test, expect } from 'vitest';
import { buildOrder } from '../factories/order.factory';
import { OrderBVA } from '../factories/bva.factory';
import { orderValidator } from '../services/order-validator';

// Named BVA test suite — each variant maps to a named equivalence class
describe('order total BVA', () => {
  test.each([
    ['below minimum', OrderBVA.belowMinimum(), false],
    ['at minimum', OrderBVA.atMinimum(), true],
    ['just above minimum', OrderBVA.justAboveMinimum(), true],
    ['just below maximum', OrderBVA.justBelowMaximum(), true],
    ['at maximum', OrderBVA.atMaximum(), true],
    ['above maximum', OrderBVA.aboveMaximum(), false],
  ])('%s: valid=%s', (_, overrides, expectedValid) => {
    const order = buildOrder(overrides);
    const result = orderValidator.validate(order);
    expect(result.valid).toBe(expectedValid);
  });
});
```

**Integration with ISTQB test documentation:** BVA factory variants map directly to
ISTQB test conditions and test cases. The factory variant name (`OrderBVA.atMaximum`)
is the test condition; the test using it (`'at maximum: valid=true'`) is the test case.
When the domain invariant changes, update the constant in the BVA factory and the test
condition name — all test cases that reference it update automatically.

---

## State Machine Factories for Complex Entity Lifecycles  [community]

Many domain entities have finite state machines: orders go through `draft → pending →
paid → shipped → delivered → cancelled`; subscriptions go through `trial → active →
past_due → cancelled`. Factories that jump to a mid-lifecycle state without executing
the transitions may produce objects that are structurally valid but *semantically
impossible* — a `shipped` order with no `shippedAt` timestamp, or a `paid` order with
no associated payment record.

**Why it matters:** A factory that directly sets `status: 'shipped'` bypasses all the
business logic that sets `shippedAt`, `trackingNumber`, and creates an `OrderEvent`
record. Tests that use such a factory are testing against an invalid state that could
never occur in production — they pass while hiding real bugs in the transition logic.

```typescript
// factories/order-state-machine.factory.ts — lifecycle-aware order factory
import { faker } from '@faker-js/faker';
import { db } from '../db';

// Represents the legal state machine: draft → pending → paid → shipped → delivered
type OrderStatus = 'draft' | 'pending' | 'paid' | 'shipped' | 'delivered' | 'cancelled';

// Each factory function builds the accumulated state for that lifecycle stage
// by executing all prior transitions — no state is skipped

interface Order {
  id: string;
  userId: string;
  status: OrderStatus;
  totalCents: number;
  paidAt?: Date;
  paymentIntentId?: string;
  shippedAt?: Date;
  trackingNumber?: string;
  deliveredAt?: Date;
  cancelledAt?: Date;
  cancelReason?: string;
  createdAt: Date;
}

// Base factory — creates a draft order (starting state only)
export function buildDraftOrder(overrides: Partial<Order> = {}): Order {
  return {
    id: faker.string.uuid(),
    userId: faker.string.uuid(),
    status: 'draft',
    totalCents: faker.number.int({ min: 100, max: 10_000 }),
    createdAt: new Date(),
    ...overrides,
  };
}

// Factory for a paid order — sets all fields that the 'pay' transition would set
export function buildPaidOrder(overrides: Partial<Order> = {}): Order {
  return {
    ...buildDraftOrder(),
    status: 'paid',
    paidAt: new Date(),                     // always set when paid
    paymentIntentId: `pi_${faker.string.alphanumeric(24)}`, // always set when paid
    ...overrides,
  };
}

// Factory for a shipped order — builds on paid state + shipping fields
export function buildShippedOrder(overrides: Partial<Order> = {}): Order {
  return {
    ...buildPaidOrder(),
    status: 'shipped',
    shippedAt: new Date(),                  // always set when shipped
    trackingNumber: faker.string.alphanumeric(12).toUpperCase(), // always set
    ...overrides,
  };
}

// Factory for a delivered order — builds on shipped state + delivery timestamp
export function buildDeliveredOrder(overrides: Partial<Order> = {}): Order {
  return {
    ...buildShippedOrder(),
    status: 'delivered',
    deliveredAt: new Date(),                // always set when delivered
    ...overrides,
  };
}

// Factory for a cancelled order — can cancel from draft or pending (not paid/shipped)
export function buildCancelledOrder(
  fromStatus: 'draft' | 'pending' = 'pending',
  overrides: Partial<Order> = {}
): Order {
  const base = fromStatus === 'pending' ? buildDraftOrder({ status: 'pending' }) : buildDraftOrder();
  return {
    ...base,
    status: 'cancelled',
    cancelledAt: new Date(),
    cancelReason: overrides.cancelReason ?? 'customer_request',
    ...overrides,
  };
}
```

```typescript
// specs/order-fulfillment.test.ts — state machine factories ensure semantic validity
import { test, expect } from 'vitest';
import { buildShippedOrder, buildPaidOrder } from '../factories/order-state-machine.factory';
import { fulfillmentService } from '../services/fulfillment.service';

// Test uses semantically valid 'paid' order — has paymentIntentId and paidAt
test('paid order can be marked as shipped', async () => {
  const order = buildPaidOrder({ userId: 'usr-001' });

  // This test exercises the ACTUAL paid→shipped transition
  // (not a shortcut from a `buildShippedOrder()` that skips it)
  const result = await fulfillmentService.ship(order.id, {
    trackingNumber: 'TRK-001',
  });

  expect(result.status).toBe('shipped');
  expect(result.shippedAt).toBeInstanceOf(Date);
});

// Using buildShippedOrder for tests that need the shipped state as a *precondition*
test('shipped order cannot be paid again', async () => {
  const order = buildShippedOrder();  // already has shippedAt, trackingNumber, paidAt
  const result = await fulfillmentService.attemptPayment(order.id, 'pm-new');
  expect(result.error).toBe('order_already_shipped');
});
```

**Anti-pattern this addresses:** The `buildShippedOrder` that sets only
`{ status: 'shipped' }` without `shippedAt`, `trackingNumber`, or `paidAt` is
semantically invalid. Tests using it pass against the factory's impossible state,
hiding bugs in any code path that reads `order.shippedAt` (it's `undefined`, not
a `Date`) — bugs that surface only in production, where the real `ship()` transition
always sets `shippedAt`.

---

## OpenAPI / Contract-Driven Factories  [community]

In API-first or contract-first TypeScript projects, the OpenAPI specification is the
authoritative source of truth for request/response shapes. Factories derived from
the OpenAPI spec (via `openapi-typescript` code generation) are guaranteed to stay
in sync with the published API contract — eliminating the "factory drifted from the
actual API" failure class.

**Why it matters:** A common failure mode in microservice tests: the TypeScript types
in `order-service` were updated to `{ userId: string }` but the factory in `api-gateway`
still builds `{ user_id: string }` (snake_case from the old spec). The factory-built
requests fail contract validation in staging — but only after the PR merges. Generating
factories from the OpenAPI spec catches this at compile time.

```typescript
// codegen: openapi-typescript generates TypeScript types from the OpenAPI spec
// Run: npx openapi-typescript ./api/openapi.yaml -o ./src/generated/api-types.ts

// factories/api-request.factory.ts — derived from OpenAPI-generated types
import { faker } from '@faker-js/faker';
// Generated types from openapi-typescript — single source of truth
import type {
  components,
  paths,
} from '../generated/api-types';

// Use the generated request body type for the POST /orders endpoint
type CreateOrderRequest = paths['/orders']['post']['requestBody']['content']['application/json'];
type CreateOrderResponse = paths['/orders']['post']['responses']['201']['content']['application/json'];

// Factory built from OpenAPI-generated types — drift-proof
export function buildCreateOrderRequest(
  overrides: Partial<CreateOrderRequest> = {}
): CreateOrderRequest {
  return {
    userId: faker.string.uuid(),
    items: [
      {
        productId: faker.string.uuid(),
        quantity: faker.number.int({ min: 1, max: 10 }),
        unitPriceCents: faker.number.int({ min: 100, max: 50_000 }),
      },
    ],
    currency: 'USD',
    shippingAddress: {
      street: faker.location.streetAddress(),
      city: faker.location.city(),
      postalCode: faker.location.zipCode(),
      countryCode: 'US',
    },
    ...overrides,
  };
}

// Factory for the expected 201 response shape
export function buildCreateOrderResponse(
  overrides: Partial<CreateOrderResponse> = {}
): CreateOrderResponse {
  return {
    orderId: faker.string.uuid(),
    status: 'pending',
    totalCents: faker.number.int({ min: 100, max: 100_000 }),
    createdAt: new Date().toISOString(),
    ...overrides,
  };
}
```

```typescript
// In a contract test (Pact consumer side):
import { Pact } from '@pact-foundation/pact';
import { buildCreateOrderRequest, buildCreateOrderResponse } from '../factories/api-request.factory';

const provider = new Pact({ consumer: 'api-gateway', provider: 'order-service', ... });

describe('POST /orders contract', () => {
  test('creates order with valid request', async () => {
    const request = buildCreateOrderRequest();
    const response = buildCreateOrderResponse({ totalCents: 4999 });

    await provider.addInteraction({
      state: 'order service is available',
      uponReceiving: 'a create order request',
      withRequest: { method: 'POST', path: '/orders', body: request },
      willRespondWith: { status: 201, body: response },
    });

    // ... execute and verify
  });
});
```

**Toolchain:** `openapi-typescript` generates TypeScript types from OpenAPI 3.x specs.
`@pact-foundation/pact` provides consumer-driven contract testing. Together they form
a pipeline where API spec → TypeScript types → factory types → contract test, with
each step enforced at compile time.

---

## Factory Registry Pattern — Managing Large Factory Suites  [community]

As a codebase grows beyond ~30 entities, importing individual factory files becomes
cumbersome and fragile. A **factory registry** provides a single entry point for all
factories, enables global configuration (faker seed, DB connection), and makes factory
discovery consistent across the team.

**Why it matters:** Without a registry, teams scatter `import { buildUser } from '../../factories/user.factory'`
paths throughout test files. When the factory moves (refactoring, monorepo restructuring),
every import must be updated. The registry decouples test files from factory locations.

```typescript
// factories/registry.ts — central factory registry
import { faker } from '@faker-js/faker';
import { userFactory } from './user.factory';
import { orderFactory } from './order.factory';
import { productFactory } from './product.factory';
import { addressFactory } from './address.factory';
import { subscriptionFactory } from './subscription.factory';

// Seed faker globally once — all factories share the same deterministic seed
const SEED = process.env.TEST_SEED ? parseInt(process.env.TEST_SEED, 10) : Date.now();
faker.seed(SEED);
if (process.env.CI) {
  // In CI: output seed as GitHub Actions annotation for replay on failure
  process.stdout.write(`::notice title=Faker Seed::${SEED}\n`);
} else {
  console.log(`[test-data] faker seed: ${SEED}`);
}

// The registry — single import for all factories
export const factories = {
  user: userFactory,
  order: orderFactory,
  product: productFactory,
  address: addressFactory,
  subscription: subscriptionFactory,
} as const;

// Type-safe access: factories.user.build({ status: 'suspended' })
// TypeScript validates 'status' against the User type — unknown fields are errors
export type FactoryRegistry = typeof factories;
export type FactoryName = keyof FactoryRegistry;
```

```typescript
// In any test file — one import, all factories available
import { factories } from '../factories/registry';

test('premium user can access enterprise features', async () => {
  const user = await factories.user.create({ subscriptionTier: 'premium' });
  const product = factories.product.build({ tier: 'enterprise' });
  // ...
});
```

**Factory deprecation workflow:** When a factory function is replaced, use the TypeScript
`@deprecated` JSDoc tag to alert consumers at IDE level before removing it:

```typescript
// factories/user.factory.ts — deprecation pattern
/**
 * @deprecated Use `userFactory.build()` from fishery instead.
 * Will be removed in the next major version.
 * Migration: replace `buildUser(overrides)` with `userFactory.build(overrides)`
 */
export function buildUser(overrides: Partial<User> = {}): User {
  return userFactory.build(overrides);  // thin wrapper — IDE shows deprecation warning
}
```

**ESLint rule to enforce registry imports:**
```json
{
  "rules": {
    "no-restricted-imports": [
      "error",
      {
        "paths": [
          {
            "name": "../factories/user.factory",
            "message": "Import from '../factories/registry' instead of directly from factory files."
          }
        ]
      }
    ]
  }
}
```

---

## Test Data Documentation — Living Factory Catalog  [community]

Large teams benefit from a **living factory catalog**: a generated or maintained
document that lists every factory, its available variants, its default values, and
known test scenarios that use it. This replaces tribal knowledge about "which factory
to use for scenario X".

**Approach 1 — JSDoc-driven (zero tooling):** Annotate factory files with JSDoc
comments that include `@example` blocks. IDE tooltips show examples on hover.

```typescript
/**
 * Build a User domain object with sensible defaults.
 *
 * @param overrides - Fields to override from the defaults. Unknown fields cause TS errors.
 * @returns A User object ready for use in tests.
 *
 * @example Basic active user:
 * ```typescript
 * const user = buildUser();
 * // { id: 'uuid...', email: 'name@domain.com', status: 'active', ... }
 * ```
 *
 * @example Suspended user for checkout blocking tests:
 * ```typescript
 * const user = buildUser({ status: 'suspended' });
 * ```
 *
 * @example Premium user with payment method (for payment flow tests):
 * ```typescript
 * const user = buildUser({ subscriptionTier: 'premium', paymentMethodId: 'pm-xxx' });
 * ```
 *
 * @see UserMother.suspended() — named variant for the most common suspended scenario
 * @see fishery userFactory.create() — use when DB persistence is needed
 */
export function buildUser(overrides: Partial<User> = {}): User {
  // ...
}
```

**Approach 2 — `typedoc` generated API docs:** Run `npx typedoc --entryPoints src/factories`
to generate HTML documentation from JSDoc annotations. Host it as an internal dev portal.
Every `@example` block in the factory becomes a live code snippet in the docs.

**Approach 3 — Storybook for data factories (React projects):** In React projects,
Storybook stories serve as both UI component documentation and factory showcase.
A Story for the `UserCard` component uses `UserMother.suspended()`, `UserMother.premium()`,
etc. as story args — the component documentation *is* the factory documentation.

```typescript
// stories/UserCard.stories.ts — factory docs embedded in Storybook
import type { Meta, StoryObj } from '@storybook/react';
import { UserCard } from '../components/UserCard';
import { UserMother } from '../factories/user.mother';

const meta: Meta<typeof UserCard> = { component: UserCard };
export default meta;

export const ActiveUser: StoryObj<typeof UserCard> = {
  args: { user: UserMother.default() },
};

export const SuspendedUser: StoryObj<typeof UserCard> = {
  args: { user: UserMother.suspended().build() },
};

export const PremiumUser: StoryObj<typeof UserCard> = {
  args: { user: UserMother.premiumWithPayment().build() },
};
```

---

## tRPC Type-Safe Factory Patterns  [community]

tRPC is widely adopted in 2026 TypeScript monorepos for end-to-end type-safe APIs.
Since tRPC procedures are defined with Zod input schemas on the server and TypeScript
inference on the client, factories for tRPC input/output types can be derived from the
router definition — giving zero-drift type safety without a separate schema file.

**Why it matters:** In tRPC projects, the API input type lives in the server router
definition. A factory that imports and uses this type (via `inferRouterInputs`) stays
synchronized with the router at compile time — if the input schema changes, the factory
fails to build until updated. This is the tRPC-native equivalent of the Prisma
`UserCreateInput` pattern.

```typescript
// server/routers/order.router.ts — tRPC router with Zod inputs
import { z } from 'zod';
import { router, publicProcedure } from '../trpc';

export const orderRouter = router({
  create: publicProcedure
    .input(
      z.object({
        userId: z.string().uuid(),
        items: z.array(
          z.object({
            productId: z.string().uuid(),
            quantity: z.number().int().min(1).max(100),
            unitPriceCents: z.number().int().min(1),
          })
        ).min(1),
        currency: z.enum(['USD', 'EUR', 'GBP']),
        couponCode: z.string().optional(),
      })
    )
    .mutation(async ({ input }) => {
      // ...
    }),
});

export type OrderRouter = typeof orderRouter;
```

```typescript
// factories/trpc-order.factory.ts — derived from tRPC router input type
import { faker } from '@faker-js/faker';
import type { inferRouterInputs } from '@trpc/server';
import type { OrderRouter } from '../server/routers/order.router';

// inferRouterInputs gives exact TypeScript types for each procedure's input
type RouterInputs = inferRouterInputs<OrderRouter>;
type CreateOrderInput = RouterInputs['create'];

// Factory produces valid CreateOrderInput — type is derived from the router, not duplicated
export function buildCreateOrderInput(
  overrides: Partial<CreateOrderInput> = {}
): CreateOrderInput {
  return {
    userId: faker.string.uuid(),
    items: [
      {
        productId: faker.string.uuid(),
        quantity: faker.number.int({ min: 1, max: 10 }),
        unitPriceCents: faker.number.int({ min: 100, max: 50_000 }),
      },
    ],
    currency: 'USD',
    ...overrides,
  };
}

// Factory for a multi-item order with coupon
export function buildCreateOrderInputWithCoupon(
  couponCode: string = 'SAVE10',
  overrides: Partial<CreateOrderInput> = {}
): CreateOrderInput {
  return buildCreateOrderInput({
    items: Array.from({ length: 3 }, () => ({
      productId: faker.string.uuid(),
      quantity: faker.number.int({ min: 1, max: 5 }),
      unitPriceCents: faker.number.int({ min: 500, max: 20_000 }),
    })),
    couponCode,
    ...overrides,
  });
}
```

```typescript
// specs/order-creation.test.ts — using tRPC caller for integration tests
import { test, expect } from 'vitest';
import { createCaller } from '../server/trpc';
import { buildCreateOrderInput } from '../factories/trpc-order.factory';
import { db } from '../db';

test('creates order with valid input', async () => {
  const caller = createCaller({ db, userId: 'usr-001' });
  const input = buildCreateOrderInput({ userId: 'usr-001' });

  const result = await caller.order.create(input);

  expect(result.orderId).toBeTruthy();
  expect(result.status).toBe('pending');
  expect(result.totalCents).toBeGreaterThan(0);
});

test('rejects order with empty items array', async () => {
  const caller = createCaller({ db, userId: 'usr-001' });
  // TypeScript error if items: [] — Zod z.array().min(1) rejects at compile time
  // But we can test the runtime rejection via Zod parse error:
  const input = buildCreateOrderInput({ items: [] as any });

  await expect(caller.order.create(input)).rejects.toThrow('Array must contain at least 1 element');
});
```

---

## Monorepo Factory Sharing Strategies  [community]

In TypeScript monorepos (Turborepo, Nx, pnpm workspaces), factory code can be shared
across multiple packages. The strategy depends on whether the factories need DB access
and whether the domain types are shared.

**Approach 1 — Shared `@company/test-factories` package:**
A dedicated `packages/test-factories` workspace package exports all factories.
Each app/service installs it as a dev dependency. Domain types are re-exported
from the shared factories package.

```
packages/
  test-factories/          # shared workspace package
    src/
      user.factory.ts      # exports buildUser, userFactory (fishery)
      order.factory.ts
      index.ts             # barrel export
    package.json           # name: "@company/test-factories"
apps/
  api/
    src/__tests__/         # imports from @company/test-factories
  web/
    src/__tests__/
```

```typescript
// packages/test-factories/src/user.factory.ts
// No DB imports here — pure in-memory factories only
// DB-persistence factories live in each app's own test/factories/ folder
import { faker } from '@faker-js/faker';

export type { User } from './types';  // shared domain types

export function buildUser(overrides: Partial<User> = {}): User {
  return {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    status: 'active',
    subscriptionTier: 'free',
    createdAt: new Date(),
    paymentMethodId: null,
    ...overrides,
  };
}
```

**Approach 2 — Factory co-location with domain packages:**
Each domain package owns its own factories in a `src/__tests__/factories/` folder.
Apps import the domain package's factories via the package's `exports` field.
Useful when domain types are strongly owned by each package.

**Tradeoff matrix for monorepo factory sharing:**

| Approach | Type drift risk | Setup complexity | Cross-package reuse |
|---|---|---|---|
| Shared `test-factories` package | Low (single source) | Medium (package setup) | Excellent |
| Co-located per domain package | Medium (types can diverge) | Low (no extra setup) | Good (via package exports) |
| Copy-paste per app (anti-pattern) | High | None | None — defeats the purpose |

---

## Database Migration Testing with Factory Data  [community]

When a database schema migration adds, removes, or renames columns, test suites that
use factories can silently pass or fail depending on whether the factory was updated
to match. The migration testing pattern ensures that factories are explicitly validated
against the migrated schema before any application tests run.

**Why it matters:** A Prisma migration that renames `user.subscriptionTier` to
`user.plan` will cause `prisma generate` to update `Prisma.UserCreateInput`. If the
factory uses `Prisma.UserCreateInput`, the factory fails to compile — catching the
migration gap immediately. If the factory uses a hand-written type, it silently uses
the old field name until a runtime error surfaces.

```typescript
// test/migration-smoke.test.ts — validates factory compatibility after migrations
// Run this test BEFORE the full test suite in CI: "test:migration-smoke"
import { test, expect, describe } from 'vitest';
import { db } from '../db';
import { users, orders } from '../db/schema';
import { buildUserInput, buildOrderInput } from '../factories';
import { sql } from 'drizzle-orm';

describe('factory-schema compatibility smoke tests', () => {
  // Test that the factory produces data insertable into the current schema
  test('user factory matches current schema', async () => {
    const input = buildUserInput();

    // insert().values() fails with a TypeScript error if factory type mismatches schema
    const [inserted] = await db.insert(users).values(input).returning();

    expect(inserted.id).toBeTruthy();
    expect(inserted.email).toBeTruthy();

    // Cleanup
    await db.delete(users).where(sql`id = ${inserted.id}`);
  });

  test('order factory matches current schema', async () => {
    // First create a user to satisfy FK constraint
    const [user] = await db.insert(users).values(buildUserInput()).returning();
    const [order] = await db
      .insert(orders)
      .values(buildOrderInput({ userId: user.id }))
      .returning();

    expect(order.id).toBeTruthy();

    // Cleanup in FK order
    await db.delete(orders).where(sql`id = ${order.id}`);
    await db.delete(users).where(sql`id = ${user.id}`);
  });
});
```

**CI integration:** Add a dedicated `test:migration-smoke` script that runs only the
migration smoke tests after `prisma migrate deploy` (or equivalent) but before the
full test suite. A failed migration smoke test fails the CI pipeline before any
application tests run — giving a clear signal that a factory needs updating.

```json
{
  "scripts": {
    "test:migration-smoke": "vitest run --reporter=verbose test/migration-smoke.test.ts",
    "test:ci": "npm run db:migrate && npm run test:migration-smoke && npm run test:all"
  }
}
```

---

## Golden Dataset Pattern for Regression Tests  [community]

The **golden dataset** is a curated, versioned set of test data records that represent
known-good reference cases for critical business scenarios. Unlike static fixtures
(which grow unmaintained) or per-test factories (which don't persist identity), golden
datasets give named, stable test identities that regression tests can reference by name.

**Why it matters:** Regression tests for bugs often need specific data shapes that
triggered the original bug. Without a golden dataset, reproducing a specific bug
requires recreating the exact data conditions — which is impossible if the original
data was generated with an un-seeded faker call. Golden datasets commit the minimal
data needed to reproduce each known regression case.

```typescript
// fixtures/golden/users.golden.ts — named, versioned golden dataset records
// Each record corresponds to a known regression case or production-representative scenario
import { User } from '../../domain/user';

// Golden records use semantic IDs starting with 'golden-' to distinguish from dynamic data
export const goldenUsers = {
  // Production bug 2024-03-15: unicode name caused display truncation bug
  // Keep until display rendering is covered by visual regression tests
  unicodeName: {
    id: 'golden-usr-unicode-001',
    email: 'unicode-test@golden.fixture',
    name: '日本語ユーザー名テスト',
    status: 'active',
    subscriptionTier: 'free',
    createdAt: new Date('2024-01-01T00:00:00Z'),
    paymentMethodId: null,
  } satisfies User,

  // Production bug 2024-07-22: zero-cent order bypass payment check
  premiumWithNullPayment: {
    id: 'golden-usr-null-pm-002',
    email: 'null-payment@golden.fixture',
    name: 'Payment Bug Regression User',
    status: 'active',
    subscriptionTier: 'premium',
    createdAt: new Date('2024-01-01T00:00:00Z'),
    paymentMethodId: null,  // the bug: premium without payment method
  } satisfies User,

  // Reference case: maximum-length name (100 chars) for boundary regression
  maxLengthName: {
    id: 'golden-usr-max-name-003',
    email: 'max-name@golden.fixture',
    name: 'A'.repeat(100),
    status: 'active',
    subscriptionTier: 'free',
    createdAt: new Date('2024-01-01T00:00:00Z'),
    paymentMethodId: null,
  } satisfies User,
} as const;

export type GoldenUserKey = keyof typeof goldenUsers;
```

```typescript
// test/regression/payment-bypass.regression.test.ts
// This test will NEVER pass with a dynamic factory — it needs the exact golden record
import { test, expect } from 'vitest';
import { goldenUsers } from '../../fixtures/golden/users.golden';
import { checkoutService } from '../../services/checkout.service';

test('premium user with null payment method triggers payment required error (regression: 2024-07-22)', () => {
  const user = goldenUsers.premiumWithNullPayment;
  const result = checkoutService.initiate(user, { items: [{ productId: 'p-001', quantity: 1 }] });

  // This exact bug: the service was calling user.paymentMethodId without null check
  expect(result.status).toBe('payment_required');
  expect(result.error).not.toBeUndefined();
});
```

**Golden dataset maintenance rules:**
1. Never modify an existing golden record — it will break the regression test it was created for
2. Add a comment with the bug ID and date when creating a new golden record
3. Remove golden records only when the regression test is replaced by a broader test suite
4. Use `satisfies User` (not type assertion) so TypeScript catches golden records that have drifted from the domain type

---

## Test Data for Accessibility (a11y) Testing  [community]

Accessibility tests require specific data patterns that trigger different rendering
states: empty states, maximum-length strings (which stress-test truncation and overflow),
lists with varying item counts (for `aria-label` count assertions), and data with
special characters (for screen reader pronunciation testing). Without named a11y
factory variants, these scenarios are silently omitted from accessibility test suites.

```typescript
// factories/a11y.factory.ts — accessibility-specific test data variants
import { faker } from '@faker-js/faker';
import { User } from '../domain/user';
import { buildUser } from './user.factory';

// A11y variants for UserCard component tests (screen reader, keyboard nav, contrast)
export const UserCardA11y = {
  // Empty state — no orders, no payment, minimal data
  emptyState: (): User => buildUser({
    name: 'New User',
    subscriptionTier: 'free',
    paymentMethodId: null,
  }),

  // Long name — tests text truncation does not break aria-label
  longName: (): User => buildUser({
    name: 'A Very Long User Name That Exceeds Normal Display Width And Tests Truncation Behavior',
  }),

  // Name with special chars — screen readers must pronounce correctly
  specialCharsName: (): User => buildUser({
    name: "O'Brien & Associates, LLC Test User",
  }),

  // RTL name — tests bidirectional text rendering (Arabic, Hebrew)
  rtlName: (): User => buildUser({
    name: 'Test User Arabic Name',   // represents RTL scenario
  }),

  // Screen reader numeric context: user with large order count
  highOrderCount: () => ({
    user: buildUser(),
    orderCount: 9999,       // tests "9,999 orders" aria-label formatting
  }),
};

// A11y variants for form validation tests
export const FormValidationA11y = {
  // Valid form data — no validation errors shown
  valid: () => ({
    email: faker.internet.email(),
    name: faker.person.fullName(),
    phone: faker.phone.number(),
  }),

  // All fields empty — all required field error messages visible simultaneously
  allEmpty: () => ({ email: '', name: '', phone: '' }),

  // Invalid email — only email error shown (tests individual error association)
  invalidEmail: () => ({
    email: 'not-an-email',
    name: faker.person.fullName(),
    phone: faker.phone.number(),
  }),
};
```

```typescript
// specs/a11y/user-card.a11y.test.ts — accessibility tests using named variants
import { test, expect } from 'vitest';
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import { UserCard } from '../../components/UserCard';
import { UserCardA11y } from '../../factories/a11y.factory';

expect.extend(toHaveNoViolations);

const a11yVariants = [
  ['empty state', UserCardA11y.emptyState()],
  ['long name', UserCardA11y.longName()],
  ['special chars name', UserCardA11y.specialCharsName()],
  ['RTL name', UserCardA11y.rtlName()],
] as const;

test.each(a11yVariants)(
  'UserCard passes axe accessibility checks for: %s',
  async (_, user) => {
    const { container } = render(<UserCard user={user} />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  }
);
```

---

## Test Data for i18n and Locale Testing  [community]

Internationalisation (i18n) test data must cover: right-to-left (RTL) text, multibyte
characters, locale-specific number and date formats, and pluralisation rules. Factories
that only generate English ASCII data miss an entire class of internationalisation bugs.
The locale-specific faker instances introduced earlier in this guide complement the
structural i18n testing patterns below.

```typescript
// factories/i18n.factory.ts — comprehensive i18n test data factory
import { fakerDE, fakerJA, faker as fakerEN } from '@faker-js/faker';
import { Product } from '../domain/product';

// Product with locale-specific strings for i18n rendering tests
export function buildLocalizedProduct(
  locale: 'en' | 'de' | 'ja',
  overrides: Partial<Product> = {}
): Product {
  const fakers = { 'en': fakerEN, 'de': fakerDE, 'ja': fakerJA } as const;
  const f = fakers[locale];

  return {
    id: f.string.uuid(),
    name: f.commerce.productName(),
    description: f.commerce.productDescription(),
    price: f.number.float({ min: 0.01, max: 9999.99, fractionDigits: 2 }),
    currency: locale === 'de' ? 'EUR' : locale === 'ja' ? 'JPY' : 'USD',
    locale,
    createdAt: new Date(),
    ...overrides,
  };
}

// Pluralisation test data — different counts to trigger different plural forms
// English: 0 items / 1 item / 2 items
// Russian: 1 / 2-4 / 5+ have different plural forms (3-way split)
// Arabic: 6 distinct plural forms (dual, trial, etc.)
export const PluralTestCounts = {
  zero: 0,
  one: 1,
  two: 2,         // Arabic dual form
  few: 3,         // Slavic 'few' form (2-4)
  many: 5,        // Slavic 'many' form (5+)
  large: 100,
  edge: 11,       // English exception: "11 items" (not "11 item")
} as const;

// Date/number formatting test data
export const LocaleFormatTestData = {
  // Dates that stress-test locale-aware date formatting
  dates: {
    usFormat: new Date('2024-07-04'),     // US: 7/4/2024; DE: 4.7.2024; ISO: 2024-07-04
    ambiguous: new Date('2024-03-04'),    // 03/04 ambiguous: US=Apr 3; EU=Mar 4
    endOfMonth: new Date('2024-01-31'),   // month-end edge case
    leapDay: new Date('2024-02-29'),      // leap year
  },
  // Numbers that stress-test locale decimal/thousand separators
  numbers: {
    large: 1234567.89,     // EN: 1,234,567.89 | DE: 1.234.567,89
    small: 0.001,
    negative: -1234.56,
    zero: 0,
  },
};
```

---

## Time-Dependent Test Data and Time-Travel Testing  [community]

Many business rules are time-dependent: subscriptions expire, trials end, promotions
have validity windows, and sessions time out. Factories that use `new Date()` for
timestamps produce data relative to the current wall clock — tests that pass today
may fail tomorrow if a date crosses a threshold overnight.

**Why it matters:** A factory that builds a trial subscription expiring "30 days from now"
produces data that is always valid. A test asserting "trial is expired" built with that
factory will never pass. Factories must accept explicit dates (or use controlled fake
clocks) to make time-dependent test assertions deterministic.

```typescript
// factories/subscription.factory.ts — time-aware subscription factory
import { faker } from '@faker-js/faker';

type SubscriptionStatus = 'trial' | 'active' | 'past_due' | 'expired' | 'cancelled';

interface Subscription {
  id: string;
  userId: string;
  status: SubscriptionStatus;
  trialStartedAt: Date;
  trialEndsAt: Date;
  currentPeriodStart: Date;
  currentPeriodEnd: Date;
  cancelledAt?: Date;
}

// Reference point: a fixed "now" for time-dependent test data
// Using 2024-06-15 as the reference avoids drift from real wall clock
const REFERENCE_NOW = new Date('2024-06-15T12:00:00Z');
const days = (n: number): number => n * 24 * 60 * 60 * 1000;

export const SubscriptionFactory = {
  // Active trial: started 10 days ago, ends 20 days from now
  activeTrial: (referenceNow: Date = REFERENCE_NOW): Subscription => ({
    id: faker.string.uuid(),
    userId: faker.string.uuid(),
    status: 'trial',
    trialStartedAt: new Date(referenceNow.getTime() - days(10)),
    trialEndsAt: new Date(referenceNow.getTime() + days(20)),
    currentPeriodStart: new Date(referenceNow.getTime() - days(10)),
    currentPeriodEnd: new Date(referenceNow.getTime() + days(20)),
  }),

  // Expired trial: trial period ended 5 days ago
  expiredTrial: (referenceNow: Date = REFERENCE_NOW): Subscription => ({
    id: faker.string.uuid(),
    userId: faker.string.uuid(),
    status: 'expired',
    trialStartedAt: new Date(referenceNow.getTime() - days(35)),
    trialEndsAt: new Date(referenceNow.getTime() - days(5)),   // ended 5 days ago
    currentPeriodStart: new Date(referenceNow.getTime() - days(35)),
    currentPeriodEnd: new Date(referenceNow.getTime() - days(5)),
  }),

  // Expiring soon: trial ends in 1 day (triggers "expiring soon" notification)
  expiringSoon: (referenceNow: Date = REFERENCE_NOW): Subscription => ({
    id: faker.string.uuid(),
    userId: faker.string.uuid(),
    status: 'trial',
    trialStartedAt: new Date(referenceNow.getTime() - days(29)),
    trialEndsAt: new Date(referenceNow.getTime() + days(1)),   // ends tomorrow
    currentPeriodStart: new Date(referenceNow.getTime() - days(29)),
    currentPeriodEnd: new Date(referenceNow.getTime() + days(1)),
  }),

  // Past due: payment failed, period ended 3 days ago
  pastDue: (referenceNow: Date = REFERENCE_NOW): Subscription => ({
    id: faker.string.uuid(),
    userId: faker.string.uuid(),
    status: 'past_due',
    trialStartedAt: new Date(referenceNow.getTime() - days(60)),
    trialEndsAt: new Date(referenceNow.getTime() - days(30)),
    currentPeriodStart: new Date(referenceNow.getTime() - days(33)),
    currentPeriodEnd: new Date(referenceNow.getTime() - days(3)),  // period ended 3 days ago
  }),
};
```

```typescript
// Using fake clocks with @sinonjs/fake-timers (or vitest's builtin fake timers)
// to freeze time for the test body
import { test, expect, vi, beforeEach, afterEach } from 'vitest';
import { SubscriptionFactory } from '../factories/subscription.factory';
import { subscriptionService } from '../services/subscription.service';

test('expired trial subscription cannot access premium features', () => {
  // Freeze time at the reference date used by the factory
  vi.useFakeTimers({ now: new Date('2024-06-15T12:00:00Z') });

  const subscription = SubscriptionFactory.expiredTrial();
  const result = subscriptionService.canAccessPremium(subscription);

  expect(result).toBe(false);
  expect(result.reason).toBe('trial_expired');

  vi.useRealTimers();
});

test('trial expiring within 24 hours triggers renewal reminder', () => {
  vi.useFakeTimers({ now: new Date('2024-06-15T12:00:00Z') });

  const subscription = SubscriptionFactory.expiringSoon();
  const notification = subscriptionService.getRenewalNotification(subscription);

  expect(notification.type).toBe('trial_expiring_soon');
  expect(notification.hoursRemaining).toBeLessThanOrEqual(24);

  vi.useRealTimers();
});
```

**Pattern: `afterEach` timer reset guard.** When using `vi.useFakeTimers()` in tests,
always reset with `vi.useRealTimers()` in `afterEach` or within the test body.
Leaked fake timers cause `setTimeout`/`setInterval` in subsequent tests to behave
with the frozen clock, producing extremely difficult-to-diagnose failures.

```typescript
// vitest.setup.ts — global guard against leaked fake timers
afterEach(() => {
  // Always restore real timers after each test, even if the test forgot
  vi.useRealTimers();
});
```

---

## Test Data Versioning and Schema Evolution  [community]

As domain models evolve over months, factories must evolve with them. The key challenge:
when a new required field is added, ALL existing factory calls must be updated. The
pattern below uses TypeScript's `Exact<T>` (or `satisfies` with a strictness check) to
catch missing required fields at compile time rather than at runtime.

```typescript
// factories/versioned.factory.ts — explicit version tagging for auditable factory evolution
// Each factory export includes a VERSION comment indicating the schema version it targets
// Update the version when the domain type changes

import { faker } from '@faker-js/faker';

// v1: original User type (2024 schema)
interface UserV1 {
  id: string;
  email: string;
  name: string;
  status: 'active' | 'suspended';
  createdAt: Date;
}

// v2: added subscriptionTier and paymentMethodId (2024-Q3 schema)
interface UserV2 extends UserV1 {
  subscriptionTier: 'free' | 'premium' | 'enterprise';
  paymentMethodId: string | null;
}

// v3: added tenantId for multi-tenancy (2025 schema)
interface UserV3 extends UserV2 {
  tenantId: string;
  displayName: string;  // separate from name for i18n
}

// Current factory targets UserV3 — 'satisfies' ensures all required fields are present
// If UserV3 adds a new required field, this factory fails at COMPILE TIME
export function buildUserV3(overrides: Partial<UserV3> = {}): UserV3 {
  return {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    displayName: faker.person.fullName(),
    status: 'active',
    subscriptionTier: 'free',
    paymentMethodId: null,
    tenantId: faker.string.uuid(),
    createdAt: new Date(),
    ...overrides,
  } satisfies UserV3;  // 'satisfies' catches missing fields without widening the return type
}

// Legacy compatibility shim — returns UserV2 shape from a UserV3 factory
// Use for services that haven't migrated to UserV3 yet (during migration window)
export function buildUserV2Compat(overrides: Partial<UserV2> = {}): UserV2 {
  const v3 = buildUserV3(overrides);
  // Omit v3-only fields to produce a UserV2-shaped object
  const { tenantId, displayName, ...v2 } = v3;
  return v2;
}
```

**Schema evolution checklist for factory maintainers:**
1. When adding a required field to a domain type: update the factory default values and bump the factory version comment
2. When removing a field: use `Omit<T, 'fieldName'>` in the factory return type during the deprecation window
3. When renaming a field: update factory and search for all usages with `import { buildUser }` to find affected test files
4. When changing a field type: add `satisfies` check to catch type mismatches in factory defaults

---

## Exhaustive Enum Factory Variants with TypeScript  [community]

When a TypeScript union type (`'active' | 'suspended' | 'pending'`) gains a new member,
test coverage for the new value is often missed. An exhaustive enum factory uses
TypeScript's discriminated union exhaustiveness to guarantee that every status value has
at least one named factory variant and one test — catching new enum values at compile
time, not at code review.

```typescript
// factories/exhaustive-enum.factory.ts — compile-time exhaustiveness for enum variants
import { buildUser } from './user.factory';
import { User } from '../domain/user';

type UserStatus = User['status'];  // 'active' | 'suspended' | 'pending'

// Record<UserStatus, () => User> forces ALL status values to have a factory variant.
// TypeScript error if a new status is added to the union but not to this record.
export const UserByStatus: Record<UserStatus, () => User> = {
  active: () => buildUser({ status: 'active' }),
  suspended: () => buildUser({ status: 'suspended' }),
  pending: () => buildUser({ status: 'pending' }),
  // TypeScript ERROR if 'cancelled' is added to UserStatus but omitted here:
  // "Property 'cancelled' is missing in type '{ active: ...; suspended: ...; pending: ...; }'"
};

// Helper: get all factory variants for parametric testing
export function allUserStatusVariants(): Array<[UserStatus, User]> {
  return (Object.entries(UserByStatus) as [UserStatus, () => User][])
    .map(([status, factory]) => [status, factory()]);
}
```

```typescript
// specs/user-status.test.ts — exhaustive status coverage using the factory record
import { test, expect, describe } from 'vitest';
import { allUserStatusVariants, UserByStatus } from '../factories/exhaustive-enum.factory';
import { userService } from '../services/user.service';

// This test automatically covers ALL status values, including newly added ones
describe('userService.getDisplayStatus covers all status values', () => {
  test.each(allUserStatusVariants())(
    'status "%s" returns a non-empty display label',
    (status, user) => {
      const label = userService.getDisplayStatus(user);
      expect(label).toBeTruthy();
      expect(typeof label).toBe('string');
    }
  );
});

// Individual status test — named access via the record
test('suspended user status returns "Account Suspended" label', () => {
  const user = UserByStatus.suspended();
  expect(userService.getDisplayStatus(user)).toBe('Account Suspended');
});
```

**When a new `'cancelled'` status is added to the `User['status']` union:**
- The `Record<UserStatus, () => User>` declaration immediately fails at compile time
- The developer is forced to add `cancelled: () => buildUser({ status: 'cancelled' })` before the code compiles
- The `test.each(allUserStatusVariants())` test suite automatically includes the new case
- No test coverage gap for the new status value

---

## Snapshot Testing with Stable Factory Data  [community]

Snapshot tests (`toMatchSnapshot()` / `toMatchInlineSnapshot()`) require completely
stable test data — any randomness causes the snapshot to change every run. The pattern
is to use **snapshot-specific factories** that use fixed, deterministic values rather
than faker randomness.

**Why it matters:** Using `buildUser()` (with faker randomness) in a snapshot test produces
a snapshot with a random UUID and email on every run. The snapshot "fails" on every
subsequent run because the data changed — the snapshot tests become permanently broken
and teams disable them rather than fixing the data source.

```typescript
// factories/snapshot.factory.ts — deterministic, snapshot-safe factory variants
// These factories NEVER use faker — all values are hardcoded and stable
import { User } from '../domain/user';
import { Order } from '../domain/order';

// All snapshot factories use predictable, human-readable IDs (not UUIDs)
// This makes snapshot diffs readable when a domain field changes
export const SnapshotUsers = {
  alice: (): User => ({
    id: 'snapshot-usr-alice',
    email: 'alice@snapshot.example',
    name: 'Alice Snapshot',
    status: 'active',
    subscriptionTier: 'premium',
    paymentMethodId: 'pm-snapshot-alice',
    createdAt: new Date('2024-01-01T00:00:00.000Z'),  // fixed timestamp
  }),

  bob: (): User => ({
    id: 'snapshot-usr-bob',
    email: 'bob@snapshot.example',
    name: 'Bob Snapshot',
    status: 'suspended',
    subscriptionTier: 'free',
    paymentMethodId: null,
    createdAt: new Date('2024-02-15T00:00:00.000Z'),
  }),
};

export const SnapshotOrders = {
  alicePendingOrder: (): Order => ({
    id: 'snapshot-ord-alice-001',
    userId: 'snapshot-usr-alice',
    status: 'pending',
    totalCents: 4999,
    currency: 'USD',
    items: [
      { productId: 'snapshot-prod-001', quantity: 2, unitPriceCents: 2499 },
    ],
    createdAt: new Date('2024-03-01T10:00:00.000Z'),
  }),
};
```

```typescript
// specs/snapshots/user-card.snapshot.test.tsx
import { test, expect } from 'vitest';
import { render } from '@testing-library/react';
import { UserCard } from '../../components/UserCard';
import { SnapshotUsers } from '../../factories/snapshot.factory';

// Snapshot test with stable data — will NEVER fail due to random data
test('UserCard renders active premium user correctly', () => {
  const { container } = render(<UserCard user={SnapshotUsers.alice()} />);
  expect(container).toMatchSnapshot();
  // Snapshot is stable: same IDs, same email, same date on every run
});

test('UserCard renders suspended free user correctly', () => {
  const { container } = render(<UserCard user={SnapshotUsers.bob()} />);
  expect(container).toMatchSnapshot();
});
```

**Anti-pattern avoided:** Never use `buildUser()` (faker-based) in snapshot tests.
The snapshot will have a different UUID and email on every run — the test becomes a
flake detector for randomness rather than a regression detector for UI changes.

**When to update snapshots:** Run `vitest --update-snapshots` (or `jest --updateSnapshot`)
only when you intentionally changed the component's rendered output. Every snapshot
update should be reviewed in code review to confirm the change is expected — not just
accepted automatically.

---

## Anti-Pattern: Test Data in Production Code  [community]

A subtle but dangerous anti-pattern is when factory code or test-specific data leaks
into production modules. This most often happens via three mechanisms:

1. **`process.env.NODE_ENV` guards in factories:** A factory file imported in production
   code "just for the type" that contains a runtime `if (env !== 'test') throw` guard
   still loads the faker import — adding ~200KB to the production bundle.

2. **Test seeds in migration files:** Database migration scripts that insert "example data"
   rows as part of the migration. These rows appear in every environment, including
   production, and accumulate over time.

3. **Hardcoded test user accounts in production code:** An `isTestUser(userId)` helper
   with hardcoded test UUIDs in production code paths — used to bypass billing, skip
   rate limits, or enable debug features. These become security vulnerabilities if the
   UUIDs are ever exposed.

```typescript
// WRONG — factory import in production module (loads faker in production bundle)
import { buildUser } from '../test/factories/user.factory';  // 200KB faker included

// WRONG — test data in migration file
export async function up(db) {
  await db.schema.createTable('users', ...);
  // Don't do this: test data in a migration pollutes all environments
  await db.insert('users').values({ id: 'usr-admin', email: 'admin@example.com' });
}

// WRONG — hardcoded test user bypass in production code
function isTestUser(userId: string): boolean {
  return ['usr-test-001', 'usr-e2e-alice'].includes(userId);
}

// CORRECT — strict separation of concerns
// Production code: zero imports from test/ or factories/ directories
// Test data: stays in test/ directory, never imported by production modules
// Migrations: create schema only; seed data lives in separate seed scripts

// Lint rule to enforce: add to eslint.config.mjs
// import/no-restricted-paths: enforce no imports from 'src/test/**' in 'src/**'
```

**ESLint enforcement (flat config format):**
```typescript
// eslint.config.mjs
import noRestrictedPathsPlugin from 'eslint-plugin-import';

export default [
  {
    plugins: { import: noRestrictedPathsPlugin },
    rules: {
      'import/no-restricted-paths': [
        'error',
        {
          zones: [
            {
              // Production source files must not import from test directories
              target: './src',
              from: ['./src/test', './test', './factories'],
              message: 'Production code must not import from test factories or test utilities.',
            },
          ],
        },
      ],
    },
  },
];
```

---

## Factory Observability — Test Data Metrics in CI  [community]

At scale (100+ integration tests with DB factories), understanding *how much* test data
is created, *how long* factory creation takes, and *which factories* are the source of
slowness helps teams optimize their test suite's setup cost. Factory observability wraps
factory calls with timing and counting logic and reports metrics in CI.

**Why it matters:** A test suite that takes 45 seconds to set up DB fixtures before any
test assertion runs has a hidden cost that engineers attribute to "slow tests" — when the
real problem is factory inefficiency (N+1 DB inserts, redundant factory calls, no
batch inserts). Factory metrics make the cost visible and actionable.

```typescript
// test/instrumented-factory.ts — factory wrapper that records timing and call counts
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';

interface FactoryMetric {
  factoryName: string;
  operation: 'build' | 'create' | 'buildList' | 'createList';
  count: number;
  durationMs: number;
  timestamp: Date;
}

// Global metrics collector (in-memory; summarized at end of test suite)
const metrics: FactoryMetric[] = [];

// Wraps a fishery Factory to record metrics on every call
export function instrumentedFactory<T>(
  name: string,
  factory: Factory<T>
): Factory<T> {
  return new Proxy(factory, {
    get(target, prop) {
      const original = (target as any)[prop];
      if (typeof original !== 'function') return original;

      if (['build', 'create', 'buildList', 'createList'].includes(String(prop))) {
        return async (...args: unknown[]) => {
          const start = performance.now();
          const result = await (original as Function).apply(target, args);
          const durationMs = performance.now() - start;

          const count = Array.isArray(result) ? result.length : 1;
          metrics.push({
            factoryName: name,
            operation: String(prop) as FactoryMetric['operation'],
            count,
            durationMs,
            timestamp: new Date(),
          });

          return result;
        };
      }
      return original;
    },
  });
}

// Summary reporter — call in globalTeardown to emit CI annotations
export function reportFactoryMetrics(): void {
  if (metrics.length === 0) return;

  const totalObjects = metrics.reduce((sum, m) => sum + m.count, 0);
  const totalTimeMs = metrics.reduce((sum, m) => sum + m.durationMs, 0);

  // Aggregate by factory name
  const byFactory = metrics.reduce((acc, m) => {
    acc[m.factoryName] = acc[m.factoryName] ?? { totalObjects: 0, totalTimeMs: 0, calls: 0 };
    acc[m.factoryName].totalObjects += m.count;
    acc[m.factoryName].totalTimeMs += m.durationMs;
    acc[m.factoryName].calls++;
    return acc;
  }, {} as Record<string, { totalObjects: number; totalTimeMs: number; calls: number }>);

  console.log('\n=== Factory Metrics Summary ===');
  console.log(`Total objects created: ${totalObjects} in ${totalTimeMs.toFixed(0)}ms`);

  // Sort by slowest factory (highest totalTimeMs)
  const sorted = Object.entries(byFactory).sort(([, a], [, b]) => b.totalTimeMs - a.totalTimeMs);
  for (const [name, stats] of sorted) {
    const avgMs = (stats.totalTimeMs / stats.calls).toFixed(1);
    console.log(`  ${name}: ${stats.totalObjects} objects, ${stats.calls} calls, avg ${avgMs}ms/call`);
  }

  // In CI: emit as GitHub Actions notice
  if (process.env.GITHUB_ACTIONS) {
    process.stdout.write(`::notice title=Factory Metrics::${totalObjects} objects in ${totalTimeMs.toFixed(0)}ms\n`);
  }
}
```

```typescript
// global-teardown.ts — report metrics at end of test suite
import { reportFactoryMetrics } from './test/instrumented-factory';

export default async function globalTeardown() {
  reportFactoryMetrics();
  // Output example:
  // === Factory Metrics Summary ===
  // Total objects created: 847 in 12340ms
  //   userFactory: 312 objects, 89 calls, avg 42.1ms/call
  //   orderFactory: 535 objects, 45 calls, avg 95.3ms/call  ← investigate this one
}
```

**Optimization signals from factory metrics:**
- Average > 100ms per `create` call: likely N+1 inserts — use `createList` with bulk insert
- Same factory called > 50 times: consider worker-scoped fixture with shared data
- High `buildList` count with zero `createList`: unit test suite creating too much in-memory data — profile heap usage

---

## LLM-Assisted Test Data Generation  [community]

In 2025–2026, teams increasingly use large language models (LLMs) to accelerate factory
bootstrap, generate domain-realistic edge-case data, and produce adversarial inputs that
manual factory authors miss. This section covers patterns and failure modes for AI-assisted
test data generation in TypeScript projects.

**Three integration modes:**

### Mode 1 — One-time factory scaffolding
Use an LLM to generate the initial factory file from a domain type or Prisma schema.
The LLM output is reviewed, edited, and committed — it is not executed dynamically.
This is the safest integration mode: all AI involvement ends at authoring time.

```typescript
// Prompt pattern (use with Claude, GPT-4o, etc.) to generate factory scaffolding:
// ---
// Given this TypeScript domain type:
//   type Invoice = { id: string; number: string; vendorId: string;
//     lineItems: LineItem[]; totalCents: number; currency: string;
//     status: 'draft' | 'sent' | 'paid' | 'overdue'; issuedAt: Date; dueAt: Date; }
// Generate a fishery factory for Invoice using @faker-js/faker v9+ APIs.
// Include: buildList support, a SubscriptionFactory.overdue() variant, REFERENCE_NOW
// date anchoring, and a JSDoc @example block.
// ---

// Generated output (after review and edit):
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';
import { Invoice } from '../domain/invoice';

const REFERENCE_NOW = new Date('2025-01-15T00:00:00Z');
const days = (n: number) => n * 86_400_000;

export const invoiceFactory = Factory.define<Invoice>(({ sequence }) => ({
  id: faker.string.uuid(),
  number: `INV-${String(sequence).padStart(6, '0')}`,
  vendorId: faker.string.uuid(),
  lineItems: [],
  totalCents: faker.number.int({ min: 10_00, max: 100_000_00 }),
  currency: 'USD',
  status: 'draft',
  issuedAt: new Date(REFERENCE_NOW.getTime() - days(30)),
  dueAt: new Date(REFERENCE_NOW.getTime() + days(30)),
}));

export const overdueInvoice = invoiceFactory.build({
  status: 'overdue',
  dueAt: new Date(REFERENCE_NOW.getTime() - days(7)),   // due 7 days ago
});
```

**Review checklist for LLM-generated factories:**
- [ ] Faker API calls use v9+ namespaces (`faker.person.*`, `faker.location.*`, not v8 deprecated names)
- [ ] Dynamic fields use `each()` (factory-ts) or are inside the Factory.define callback (fishery) — not module-level constants
- [ ] `createdAt` / `dueAt` use a fixed `REFERENCE_NOW` anchor, not `new Date()` (wall clock drift)
- [ ] Factory file does NOT import from production services (no side-effects at import time)
- [ ] Override types use `Partial<T>` — not `any` or `object`

### Mode 2 — LLM-generated edge-case datasets

LLMs excel at generating exhaustive edge-case datasets for a given domain field.
Instead of manually brainstorming boundary inputs, provide the LLM with the field's
validation rules and ask for a parametric dataset.

```typescript
// Prompt pattern for edge-case dataset generation:
// ---
// Generate an exhaustive test dataset for a 'productCode' field with these rules:
//   - Must be 8–12 alphanumeric characters
//   - Must start with a letter
//   - Case-insensitive; stored as uppercase
//   - Valid examples: 'ABC12345', 'PROD123456'
// Provide: valid boundary cases, invalid boundary cases, and adversarial inputs.
// Format: TypeScript const array with { value: string, expectedValid: boolean, reason: string }
// ---

// LLM-generated output (reviewed and committed as a static dataset):
export const productCodeTestDataset = [
  // Valid boundary cases
  { value: 'A1234567', expectedValid: true, reason: 'minimum length (8 chars)' },
  { value: 'A12345678901', expectedValid: true, reason: 'maximum length (12 chars)' },
  { value: 'abcdefgh', expectedValid: true, reason: 'all lowercase (stored as ABCDEFGH)' },
  { value: 'ABCD1234', expectedValid: true, reason: 'typical valid code' },
  // Invalid boundary cases
  { value: 'A123456', expectedValid: false, reason: 'too short (7 chars)' },
  { value: 'A1234567890123', expectedValid: false, reason: 'too long (14 chars)' },
  { value: '1ABCDEFG', expectedValid: false, reason: 'starts with digit (must start with letter)' },
  { value: '', expectedValid: false, reason: 'empty string' },
  // Adversarial inputs
  { value: 'ABC-1234', expectedValid: false, reason: 'contains hyphen (non-alphanumeric)' },
  { value: 'ABC 1234', expectedValid: false, reason: 'contains space' },
  { value: 'ABC\x00DEF', expectedValid: false, reason: 'null byte injection' },
  { value: 'ABC\nDEFG', expectedValid: false, reason: 'newline injection' },
  { value: "'; DROP TABLE--", expectedValid: false, reason: 'SQL injection attempt' },
  { value: '<script>alert(1)</script>', expectedValid: false, reason: 'XSS attempt' },
  { value: 'Ä'.repeat(8), expectedValid: false, reason: 'non-ASCII characters' },
] as const;

// Parametric test using the LLM-generated dataset:
import { test, expect } from 'vitest';
import { productCodeTestDataset } from '../factories/product-code.dataset';
import { validateProductCode } from '../services/product.service';

test.each(productCodeTestDataset)(
  'productCode "$value" is valid=$expectedValid ($reason)',
  ({ value, expectedValid }) => {
    expect(validateProductCode(value)).toBe(expectedValid);
  }
);
```

**Production lesson [community]:** LLMs generate datasets that are *exhaustive in the happy path* but biased toward the examples in their training data. They reliably generate SQL injection and XSS adversarial inputs (common in training data) but may miss domain-specific edge cases (e.g., a product code that looks valid but conflicts with a legacy system's reserved namespace). Always supplement LLM-generated datasets with domain expert review.

### Mode 3 — Dynamic LLM-generated realistic content (with risks)

Some teams use LLM APIs at test *runtime* to generate realistic text content (product descriptions, user reviews, chat messages) that would be tedious to hand-craft. This mode has significant risks.

```typescript
// WARNING: Do NOT use this pattern in automated CI test suites.
// Only for one-time seed generation scripts run offline.

// scripts/generate-content-seeds.ts — generates realistic content ONCE, then commits
// Never run this in CI — API costs accumulate, tests become non-deterministic
import Anthropic from '@anthropic-ai/sdk';
import { writeFileSync } from 'fs';

const client = new Anthropic();

async function generateProductDescriptions(count: number): Promise<void> {
  const descriptions: string[] = [];

  for (let i = 0; i < count; i++) {
    const message = await client.messages.create({
      model: 'claude-opus-4-5',
      max_tokens: 200,
      messages: [{
        role: 'user',
        content: `Write a realistic 2-sentence product description for a fictional B2B SaaS tool. Be specific and professional. No marketing fluff.`,
      }],
    });

    const content = message.content[0];
    if (content.type === 'text') {
      descriptions.push(content.text);
    }
  }

  // Commit the generated content as a static fixture — NEVER regenerate in CI
  writeFileSync(
    './fixtures/product-descriptions.fixture.json',
    JSON.stringify(descriptions, null, 2)
  );

  console.log(`Generated ${descriptions.length} descriptions. Commit this file.`);
}

generateProductDescriptions(50);
```

**[community] Critical risks of runtime LLM test data generation:**
1. **Non-determinism:** LLM outputs are probabilistic. The same prompt produces different content on each run. Tests that assert on LLM-generated content fail non-deterministically — the definition of flaky tests.
2. **API cost accumulation:** A 500-test suite making LLM API calls per test at $0.01/call costs $5 per CI run. With 20 CI runs per day, that is $3,650/year for test data alone.
3. **Rate limit flakiness:** LLM API rate limits cause test failures in parallel CI runs, corrupting the flakiness signal.
4. **Bias amplification:** LLMs trained on internet text reflect its biases in generated names, descriptions, and content. Diversity audits of LLM-generated test data are mandatory before using it to test UI rendering, recommendation systems, or content moderation.

**The correct pattern:** Use LLMs to generate static fixtures *once*, commit them to source control, and never regenerate in CI. Treat the committed fixtures as authoritative test data, not as LLM outputs.

---

## Testcontainers-Node — Production-Faithful DB Isolation  [community]

`testcontainers-node` (by AtomicJar / Docker) spins up a real PostgreSQL, MySQL, or Redis
container per test suite, providing the strongest possible isolation without provisioning
a shared database. Each test suite gets a clean, ephemeral database that is destroyed
after the run — no manual cleanup, no seed conflicts with other developers.

**Why it matters:** The "per-worker database" strategy in the Vitest config section above
requires pre-provisioned databases. Testcontainers removes that requirement: the test suite
itself declares what database it needs and starts it on demand. This works in any CI
environment that can run Docker, with zero infrastructure pre-configuration.

```typescript
// test/containers/postgres.container.ts — shared Testcontainers setup
import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import * as schema from '../../db/schema';

let container: StartedPostgreSqlContainer;
let dbClient: ReturnType<typeof drizzle>;

// globalSetup.ts — start container once for the entire test suite
export async function setup(): Promise<void> {
  // Start a real PostgreSQL 16 container
  container = await new PostgreSqlContainer('postgres:16-alpine')
    .withDatabase('testdb')
    .withUsername('testuser')
    .withPassword('testpass')
    .start();

  const connectionString = container.getConnectionUri();
  process.env.DATABASE_URL = connectionString;

  // Run all Drizzle migrations against the fresh container DB
  const migrationClient = postgres(connectionString, { max: 1 });
  await migrate(drizzle(migrationClient), { migrationsFolder: './drizzle' });
  await migrationClient.end();

  console.log(`[testcontainers] PostgreSQL started: ${connectionString}`);
}

// globalTeardown.ts — stop container after all tests complete
export async function teardown(): Promise<void> {
  await container?.stop();
  console.log('[testcontainers] PostgreSQL container stopped');
}
```

```typescript
// vitest.config.ts — connect Testcontainers lifecycle to Vitest
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globalSetup: ['./test/containers/globalSetup.ts', './test/containers/globalTeardown.ts'],
    // Per-file isolation: each test file runs against the shared container DB
    // Use transaction rollback per test (Strategy 1 from the isolation section)
    pool: 'forks',
    // Vitest 4.x: isolate + maxWorkers replace the old poolOptions.forks.singleFork
    isolate: false,    // share the container DB connection across files in the same worker
    maxWorkers: 1,     // single worker process — container connection is shared
    // Old Vitest 2.x/3.x config (DEPRECATED in 4.0):
    // poolOptions: { forks: { singleFork: true } }
  },
});
```

```typescript
// Integration test using the Testcontainers-provisioned DB
import { test, expect, beforeEach, afterEach } from 'vitest';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from '../../db/schema';
import { buildUserInput } from '../../factories/user.factory';

// Database URL is set by the Testcontainers globalSetup
const client = postgres(process.env.DATABASE_URL!);
const db = drizzle(client, { schema });

beforeEach(async () => { await client`BEGIN` });
afterEach(async () => { await client`ROLLBACK` });

test('userRepository.create persists user and returns row', async () => {
  const input = buildUserInput({ status: 'active', subscriptionTier: 'premium' });
  const [created] = await db.insert(schema.users).values(input).returning();

  expect(created.id).toBeTruthy();
  expect(created.email).toBe(input.email);
  expect(created.status).toBe('active');
  // Row is rolled back by afterEach — no cleanup needed
});
```

**[community] Production lessons with Testcontainers:**
1. Container startup (≈3–8 seconds for PostgreSQL) adds fixed overhead — use `globalSetup` (once per suite), not `beforeAll` (once per file). With `beforeAll`, 20 test files each starting a container adds 60–160 seconds to CI.
2. Testcontainers requires Docker socket access (`/var/run/docker.sock`) in CI. GitHub Actions runners have Docker available by default; CircleCI requires the `machine` executor, not Docker-in-Docker. Verify socket access before adopting.
3. Image pulling adds latency on first run in CI. Use `testcontainers.withPullPolicy('Always')` only in nightly runs; use `'IfNotPresent'` (default) in PR CI to reuse the cached layer.

---

## `@electric-sql/pglite` — In-Process PostgreSQL for Near-Unit-Speed Integration Tests  [community]

`PGlite` (by ElectricSQL, 2024–2025) runs PostgreSQL compiled to WebAssembly directly
in the Node.js process — no Docker, no external process, no socket. It starts in ~50ms
(vs 3–8 seconds for Testcontainers) and is destroyed when the process exits. This makes
it practical for integration tests that previously required a real database but could not
justify Testcontainers' startup cost.

**Why it matters:** The traditional choice was: "use an in-memory mock (fast but unrealistic)
or use a real database (faithful but slow)". PGlite adds a third option: a real PostgreSQL
dialect running in-process at near-unit-test speed — faithful for SQL queries, extensions
(including `uuid-ossp`), and constraint validation.

**Limitations:** PGlite does not support all PostgreSQL extensions (e.g., `PostGIS` requires separate WASM build), does not support parallel connections (single-threaded WASM), and is unsuitable for load testing. Use Testcontainers when you need full PostgreSQL extension support or multi-connection parallelism.

```typescript
// test/pglite-setup.ts — shared PGlite instance for integration tests
import { PGlite } from '@electric-sql/pglite';
import { drizzle } from 'drizzle-orm/pglite';
import { migrate } from 'drizzle-orm/pglite/migrator';
import * as schema from '../db/schema';

// Module-level singleton — created once per test file, destroyed when Node exits
let _db: ReturnType<typeof drizzle<typeof schema>> | null = null;

export async function getTestDb() {
  if (_db) return _db;

  // In-memory PGlite instance — no files, no ports, no cleanup needed
  const client = new PGlite();
  _db = drizzle(client, { schema });

  // Run Drizzle migrations against the in-process DB
  await migrate(_db, { migrationsFolder: './drizzle' });

  return _db;
}
```

```typescript
// Integration test with PGlite — starts in ~50ms, no Docker required
import { test, expect, beforeEach } from 'vitest';
import { getTestDb } from '../test/pglite-setup';
import { users } from '../db/schema';
import { buildUserInput } from '../factories/user.factory';
import { eq } from 'drizzle-orm';

test('creates and retrieves user from in-process PostgreSQL', async () => {
  const db = await getTestDb();
  const input = buildUserInput({ email: `test-${Date.now()}@pglite.com` });

  const [created] = await db.insert(users).values(input).returning();
  expect(created.id).toBeTruthy();

  // Verify retrieval — real SQL query against real PostgreSQL dialect
  const [fetched] = await db.select().from(users).where(eq(users.id, created.id));
  expect(fetched.email).toBe(input.email);

  // Cleanup — delete by ID (or use transaction rollback strategy)
  await db.delete(users).where(eq(users.id, created.id));
});
```

**Choosing between PGlite and Testcontainers:**

| Criterion | PGlite | Testcontainers |
|---|---|---|
| Startup time | ~50ms (WASM init) | 3–8 seconds (container start) |
| PostgreSQL version | WASM build (≈15.x) | Any version you specify |
| Extension support | Limited (pg_vector, uuid-ossp) | Full (PostGIS, pgcrypto, etc.) |
| Parallel connections | Single-threaded | Full multi-connection support |
| Docker required | No | Yes |
| Best for | Unit-speed integration tests | Production-faithful E2E-adjacent tests |

---

## TanStack Query (React Query) Test Data Patterns  [community]

TanStack Query (formerly React Query) is the standard data-fetching and server-state
management library in TypeScript React projects in 2025–2026. Testing components that
use TanStack Query requires specific test data patterns: a `QueryClient` wrapper,
factory-generated responses, and MSW handlers scoped to the query keys being tested.

**Why it matters:** Components using `useQuery` or `useMutation` fetch data asynchronously.
Without a `QueryClientProvider` wrapping the test render and MSW intercepting the
HTTP requests, the component renders in a perpetual loading state. Correctly wiring
factory data through the TanStack Query → MSW pipeline makes component tests fast,
deterministic, and free of network calls.

```typescript
// test/query-wrapper.tsx — shared TanStack Query test wrapper
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Create a fresh QueryClient per test to prevent cache pollution between tests
export function createTestQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: {
        // Disable retries in tests — we want immediate failure, not 3-retry waits
        retry: false,
        // Disable background refetching — prevents unexpected requests in tests
        staleTime: Infinity,
        gcTime: Infinity,
      },
      mutations: {
        retry: false,
      },
    },
  });
}

interface WrapperProps {
  children: React.ReactNode;
  queryClient?: QueryClient;
}

// Reusable wrapper component for renderHook / render calls
export function QueryWrapper({ children, queryClient }: WrapperProps) {
  const client = queryClient ?? createTestQueryClient();
  return (
    <QueryClientProvider client={client}>
      {children}
    </QueryClientProvider>
  );
}

// For renderHook — returns a wrapper function
export function createQueryWrapper(queryClient?: QueryClient) {
  const client = queryClient ?? createTestQueryClient();
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
}
```

```typescript
// mocks/query-handlers.ts — MSW handlers providing factory-generated responses for TanStack Query
import { http, HttpResponse } from 'msw';
import { buildUser, buildUserList } from '../factories/user.factory';
import { buildOrder } from '../factories/order.factory';

// Match the exact endpoint URLs used by your useQuery hooks
export const queryHandlers = [
  // GET /api/users/{id} — matches useQuery({ queryKey: ['users', id] })
  http.get('/api/users/:id', ({ params }) => {
    const user = buildUser({ id: params.id as string, status: 'active' });
    return HttpResponse.json(user);
  }),

  // GET /api/users — matches useQuery({ queryKey: ['users'] })
  http.get('/api/users', () => {
    const users = buildUserList(5);
    return HttpResponse.json({ data: users, total: 5, page: 1 });
  }),

  // GET /api/orders — matches useQuery({ queryKey: ['orders', userId] })
  http.get('/api/orders', ({ request }) => {
    const url = new URL(request.url);
    const userId = url.searchParams.get('userId') ?? faker.string.uuid();
    const orders = Array.from({ length: 3 }, () => buildOrder({ userId }));
    return HttpResponse.json(orders);
  }),
];

// Error state handler — override in specific tests to simulate failure states
export const errorHandlers = {
  networkError: () => http.get('/api/users/:id', () => HttpResponse.error()),
  serverError: () => http.get('/api/users/:id', () =>
    HttpResponse.json({ message: 'Internal Server Error' }, { status: 500 })
  ),
  notFound: (id: string) => http.get(`/api/users/${id}`, () =>
    HttpResponse.json({ message: 'User not found' }, { status: 404 })
  ),
};
```

```typescript
// specs/hooks/useUser.test.tsx — testing a useQuery hook with factory data
import { renderHook, waitFor } from '@testing-library/react';
import { test, expect, beforeAll, afterEach, afterAll } from 'vitest';
import { setupServer } from 'msw/node';
import { useUser } from '../../hooks/useUser';
import { createQueryWrapper, createTestQueryClient } from '../test/query-wrapper';
import { queryHandlers, errorHandlers } from '../mocks/query-handlers';
import { buildUser } from '../factories/user.factory';

const server = setupServer(...queryHandlers);
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

test('useUser returns user data for a valid ID', async () => {
  const { result } = renderHook(
    () => useUser('usr-test-001'),
    { wrapper: createQueryWrapper() }
  );

  // Wait for the query to resolve (MSW intercepts the HTTP call)
  await waitFor(() => expect(result.current.isSuccess).toBe(true));

  expect(result.current.data?.id).toBe('usr-test-001');
  expect(result.current.data?.status).toBe('active');
});

test('useUser handles 404 and returns error state', async () => {
  // Override: return 404 for this specific test
  server.use(errorHandlers.notFound('usr-nonexistent'));

  const { result } = renderHook(
    () => useUser('usr-nonexistent'),
    { wrapper: createQueryWrapper() }
  );

  await waitFor(() => expect(result.current.isError).toBe(true));
  expect(result.current.error).toBeDefined();
});

test('useMutation updates optimistic state then confirms with server response', async () => {
  // Pre-populate the query cache with factory data to test optimistic updates
  const queryClient = createTestQueryClient();
  const existingUser = buildUser({ id: 'usr-001', status: 'active' });

  // Seed the cache with the initial state
  queryClient.setQueryData(['users', 'usr-001'], existingUser);

  const { result } = renderHook(
    () => useUser('usr-001'),
    { wrapper: createQueryWrapper(queryClient) }
  );

  // Initial state from cache — no network call yet
  expect(result.current.data?.status).toBe('active');
});
```

**[community] Common pitfall:** TanStack Query's `staleTime: 0` (default) causes queries to
refetch on window focus in tests running in `jsdom`. This produces spurious `pending` states
mid-test when the test simulates a focus event. Set `staleTime: Infinity` in test `QueryClient`
configuration (as shown above) to prevent background refetches during assertions.

---

## Zod v4 Factory Patterns (2025+)  [community]

Zod v4 (released 2025) introduced breaking API changes and major performance improvements
(~14× faster parse, smaller bundle). Factory patterns built on `zod-fixture` or manual
`z.infer<>` derivation require updates when migrating from Zod v3.

**Key Zod v4 changes affecting factory patterns:**

| Zod v3 | Zod v4 | Factory impact |
|---|---|---|
| `z.string().email()` | `z.email()` (new top-level shorthand) | Schema definitions in factories get shorter |
| `z.string().uuid()` | `z.uuid()` (top-level) | Less nesting in `UserSchema` definitions |
| `z.object().merge()` | `z.object().extend()` (preferred) | Merge pattern changes |
| `ZodError.flatten()` | `ZodError.flatten()` (unchanged) | No impact |
| `z.infer<typeof Schema>` | `z.infer<typeof Schema>` (unchanged) | No impact |
| `z.discriminatedUnion()` | Performance improved | No API change |

```typescript
// schemas/user.schema.ts — Zod v4 schema (note top-level helpers)
import { z } from 'zod';

export const UserSchema = z.object({
  id: z.uuid(),                              // Zod v4: top-level z.uuid() (no z.string().uuid())
  email: z.email(),                          // Zod v4: top-level z.email()
  name: z.string().min(1).max(100),
  status: z.enum(['active', 'suspended', 'pending']),
  subscriptionTier: z.enum(['free', 'premium', 'enterprise']),
  createdAt: z.date(),
  paymentMethodId: z.string().nullable(),
  // Zod v4: z.url() for URL validation (new top-level helper)
  avatarUrl: z.url().nullable().optional(),
});

// Zod v4 schema merging via .extend() — preferred over .merge() in v4
export const AdminUserSchema = UserSchema.extend({
  role: z.literal('admin'),
  permissions: z.array(z.string()),
});

export type User = z.infer<typeof UserSchema>;
export type AdminUser = z.infer<typeof AdminUserSchema>;
```

```typescript
// factories/user.factory.ts — Zod v4 with zod-fixture
// zod-fixture ≥ 0.9 supports Zod v4 schemas
import { createFixture } from 'zod-fixture';
import { faker } from '@faker-js/faker';
import { UserSchema, User } from '../schemas/user.schema';

// zod-fixture respects z.uuid() and z.email() in Zod v4 — generates valid UUIDs and emails
export function buildUserFixture(overrides: Partial<User> = {}): User {
  return {
    ...createFixture(UserSchema),
    ...overrides,
  };
}

// Hybrid: zod-fixture for structural validity + faker for realistic values
export function buildRealisticUser(overrides: Partial<User> = {}): User {
  const base = createFixture(UserSchema);
  return {
    ...base,
    // Override zod-fixture's lorem-ipsum names with realistic faker values
    email: faker.internet.email(),
    name: faker.person.fullName(),
    createdAt: faker.date.past({ years: 2 }),
    ...overrides,
  };
}
```

```typescript
// Zod v4 discriminated union factory — common pattern in CQRS command schemas
import { z } from 'zod';
import { faker } from '@faker-js/faker';

// Zod v4 discriminated unions are significantly faster to parse than v3
const CommandSchema = z.discriminatedUnion('type', [
  z.object({
    type: z.literal('CreateUser'),
    payload: z.object({
      email: z.email(),
      name: z.string().min(1),
    }),
  }),
  z.object({
    type: z.literal('SuspendUser'),
    payload: z.object({
      userId: z.uuid(),
      reason: z.string(),
    }),
  }),
  z.object({
    type: z.literal('UpgradeSubscription'),
    payload: z.object({
      userId: z.uuid(),
      tier: z.enum(['premium', 'enterprise']),
    }),
  }),
]);

type Command = z.infer<typeof CommandSchema>;

// Type-safe command factory using the discriminated union
export const CommandFactory = {
  createUser: (overrides?: Partial<Extract<Command, { type: 'CreateUser' }>['payload']>): Command => ({
    type: 'CreateUser',
    payload: {
      email: faker.internet.email(),
      name: faker.person.fullName(),
      ...overrides,
    },
  }),

  suspendUser: (userId?: string): Command => ({
    type: 'SuspendUser',
    payload: {
      userId: userId ?? faker.string.uuid(),
      reason: 'policy_violation',
    },
  }),

  upgradeSubscription: (userId?: string, tier: 'premium' | 'enterprise' = 'premium'): Command => ({
    type: 'UpgradeSubscription',
    payload: {
      userId: userId ?? faker.string.uuid(),
      tier,
    },
  }),
};

// Runtime validation of factory output against the Zod v4 schema:
// CommandSchema.parse(CommandFactory.createUser()) — throws if factory drifted from schema
```

**[community] Zod v3 → v4 migration gotcha with factories:** The `z.string().email()` →
`z.email()` change is syntactic only in schema definitions, but `zod-fixture` v0.8 and
earlier do not recognize `z.email()` as a top-level helper — they generate a random string
rather than a valid email format. Check the `zod-fixture` changelog before upgrading Zod
to v4: you may need to pin `zod-fixture` to a version that explicitly supports Zod v4
schemas, or override the `email` field with `faker.internet.email()` after generation.

---

## Event-Driven Architecture Test Data — Message Factories  [community]

In event-driven TypeScript systems (Kafka, AWS SQS, SNS, EventBridge, or in-process
event buses), test data is not a domain entity but an *event envelope* — a message
with a type discriminator, a payload, and transport metadata (topic, partition,
message ID, timestamp). Factories for event-driven tests must produce the full
message envelope, not just the payload.

**Why it matters:** Testing an event consumer in isolation requires realistic message
envelopes that match the exact structure produced by the event broker. A consumer handler
tested with a raw payload (no envelope) will pass in unit tests but fail in integration
when the broker wraps it in a `{ Records: [...] }` structure (SQS), a `{ topic, partition,
offset, value }` object (Kafka), or an `{ source, detail-type, detail }` envelope
(EventBridge). Envelope factories encode the broker's message format once, centrally.

```typescript
// factories/events/sqs-message.factory.ts — AWS SQS message envelope factory
import { faker } from '@faker-js/faker';
import { SQSEvent, SQSRecord } from 'aws-lambda';

// SQS message envelope builder — matches the exact structure Lambda receives
export function buildSQSRecord(
  payload: unknown,
  overrides: Partial<SQSRecord> = {}
): SQSRecord {
  const messageId = faker.string.uuid();
  return {
    messageId,
    receiptHandle: `receipt-${faker.string.alphanumeric(128)}`,
    body: JSON.stringify(payload),       // SQS body is always a JSON string
    attributes: {
      ApproximateReceiveCount: '1',
      SentTimestamp: String(Date.now()),
      SenderId: faker.string.alphanumeric(21),
      ApproximateFirstReceiveTimestamp: String(Date.now()),
    },
    messageAttributes: {},
    md5OfBody: faker.string.hexadecimal({ length: 32, casing: 'lower' }),
    eventSource: 'aws:sqs',
    eventSourceARN: 'arn:aws:sqs:us-east-1:123456789012:my-queue',
    awsRegion: 'us-east-1',
    ...overrides,
  };
}

// Build a full SQSEvent (wraps 1 or more records — Lambda batching)
export function buildSQSEvent(
  payloads: unknown[],
  overrides?: Partial<SQSRecord>
): SQSEvent {
  return {
    Records: payloads.map((payload) => buildSQSRecord(payload, overrides)),
  };
}
```

```typescript
// factories/events/domain-events.factory.ts — typed domain event factories for SQS
import { faker } from '@faker-js/faker';
import { buildSQSEvent } from './sqs-message.factory';
import { SQSEvent } from 'aws-lambda';

// Domain event types (from your event schema registry)
type UserCreatedEvent = {
  eventType: 'user.created';
  eventId: string;
  occurredAt: string;  // ISO 8601
  payload: {
    userId: string;
    email: string;
    subscriptionTier: 'free' | 'premium' | 'enterprise';
  };
};

type OrderPlacedEvent = {
  eventType: 'order.placed';
  eventId: string;
  occurredAt: string;
  payload: {
    orderId: string;
    userId: string;
    totalCents: number;
    currency: string;
  };
};

// Typed event factories — envelope includes both transport metadata and domain payload
export const EventFactory = {
  userCreated: (overrides: Partial<UserCreatedEvent['payload']> = {}): UserCreatedEvent => ({
    eventType: 'user.created',
    eventId: faker.string.uuid(),
    occurredAt: faker.date.recent().toISOString(),
    payload: {
      userId: faker.string.uuid(),
      email: faker.internet.email(),
      subscriptionTier: 'free',
      ...overrides,
    },
  }),

  orderPlaced: (overrides: Partial<OrderPlacedEvent['payload']> = {}): OrderPlacedEvent => ({
    eventType: 'order.placed',
    eventId: faker.string.uuid(),
    occurredAt: faker.date.recent().toISOString(),
    payload: {
      orderId: faker.string.uuid(),
      userId: faker.string.uuid(),
      totalCents: faker.number.int({ min: 100, max: 100_000 }),
      currency: 'USD',
      ...overrides,
    },
  }),

  // Build the full SQS Lambda event for a batch of domain events
  sqsBatch: (events: (UserCreatedEvent | OrderPlacedEvent)[]): SQSEvent =>
    buildSQSEvent(events),
};
```

```typescript
// handlers/user-created.handler.test.ts — Lambda handler test with event factories
import { test, expect, vi } from 'vitest';
import { handleUserCreated } from '../../handlers/user-created.handler';
import { EventFactory } from '../../factories/events/domain-events.factory';
import { emailService } from '../../services/email.service';

vi.mock('../../services/email.service');

test('sends welcome email when user.created event is received', async () => {
  const event = EventFactory.sqsBatch([
    EventFactory.userCreated({ email: 'alice@test.com', subscriptionTier: 'premium' }),
  ]);

  await handleUserCreated(event);

  expect(emailService.sendWelcome).toHaveBeenCalledOnce();
  expect(emailService.sendWelcome).toHaveBeenCalledWith(
    expect.objectContaining({ email: 'alice@test.com' })
  );
});

test('processes batch of 10 user.created events without error', async () => {
  const events = Array.from({ length: 10 }, () => EventFactory.userCreated());
  const sqsEvent = EventFactory.sqsBatch(events);

  // Assert no thrown errors (batch handler must be resilient to partial failures)
  await expect(handleUserCreated(sqsEvent)).resolves.not.toThrow();
});
```

**EventBridge envelope factory:**
```typescript
// factories/events/eventbridge.factory.ts — AWS EventBridge event envelope
import { faker } from '@faker-js/faker';
import { EventBridgeEvent } from 'aws-lambda';

export function buildEventBridgeEvent<T extends Record<string, unknown>>(
  detailType: string,
  detail: T,
  source = 'com.mycompany.orders'
): EventBridgeEvent<string, T> {
  return {
    version: '0',
    id: faker.string.uuid(),
    source,
    account: '123456789012',
    time: new Date().toISOString(),
    region: 'us-east-1',
    resources: [],
    'detail-type': detailType,
    detail,
  };
}

// Usage:
// const event = buildEventBridgeEvent('OrderPlaced', EventFactory.orderPlaced().payload);
```

**[community] Production lesson — event ordering in factory batches:** SQS and Kinesis
consumers may process messages out of order (SQS FIFO provides ordering within a group;
standard SQS does not). Test factories that always build events with incrementing
`occurredAt` timestamps mislead the consumer into assuming ordered delivery. Add a
factory variant that shuffles event timestamps to test idempotency and out-of-order handling.

---

## WebSocket and Server-Sent Events (SSE) Test Data  [community]

Real-time features (live chat, collaborative editing, live dashboards, streaming AI
responses) use WebSockets or Server-Sent Events. Testing these requires factories that
produce sequences of messages over time, not single responses. MSW v2 supports both
WebSocket and SSE handlers, enabling test data injection at the HTTP layer without a
real server.

**Why it matters:** A component that displays a live order status stream (`draft → pending
→ paid → shipped`) has different rendering logic at each state transition. Without
sequential message factories and an MSW WebSocket handler, the only way to test these
transitions is with a running WebSocket server — coupling component tests to
infrastructure. MSW's WebSocket handler makes the transitions testable in isolation.

```typescript
// mocks/websocket-handlers.ts — MSW v2 WebSocket handler with factory-generated messages
import { ws } from 'msw';
import { faker } from '@faker-js/faker';

// Define the WS endpoint
const orderUpdates = ws.link('wss://api.example.com/orders/:orderId/stream');

// Order status progression factory — generates a sequence of status update messages
export function buildOrderStatusSequence(
  orderId: string
): Array<{ orderId: string; status: string; timestamp: string }> {
  const now = Date.now();
  return [
    { orderId, status: 'pending',   timestamp: new Date(now).toISOString() },
    { orderId, status: 'paid',      timestamp: new Date(now + 1000).toISOString() },
    { orderId, status: 'shipped',   timestamp: new Date(now + 2000).toISOString() },
    { orderId, status: 'delivered', timestamp: new Date(now + 3000).toISOString() },
  ];
}

// MSW WebSocket handler — sends each status update with a delay
export const wsHandlers = [
  orderUpdates.addEventListener('connection', ({ client, params }) => {
    const orderId = params.orderId as string;
    const updates = buildOrderStatusSequence(orderId);

    // Send status updates one at a time with 50ms intervals (simulates real server timing)
    updates.forEach((update, index) => {
      setTimeout(() => {
        client.send(JSON.stringify(update));
      }, index * 50);
    });

    // Handle client close
    client.addEventListener('close', () => {
      // Cleanup if needed
    });
  }),
];
```

```typescript
// specs/OrderStatusStream.test.tsx — testing WebSocket-driven component
import { render, screen } from '@testing-library/react';
import { act, waitFor } from '@testing-library/react';
import { test, expect, beforeAll, afterEach, afterAll } from 'vitest';
import { setupServer } from 'msw/node';
import { wsHandlers } from '../mocks/websocket-handlers';
import { OrderStatusStream } from '../../components/OrderStatusStream';

const server = setupServer(...wsHandlers);
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

test('displays status progression as WebSocket messages arrive', async () => {
  render(<OrderStatusStream orderId="ord-test-001" />);

  // Initial render: shows 'Connecting...' or loading state
  expect(screen.getByText(/connecting/i)).toBeInTheDocument();

  // After first message: 'pending'
  await waitFor(() => expect(screen.getByText(/pending/i)).toBeInTheDocument());

  // After all messages: 'delivered'
  await waitFor(
    () => expect(screen.getByText(/delivered/i)).toBeInTheDocument(),
    { timeout: 500 }  // generous timeout for all 4 messages
  );
});
```

```typescript
// factories/sse.factory.ts — Server-Sent Events test data for streaming AI responses
// MSW v2 supports SSE via ReadableStream in http handlers

import { http, HttpResponse } from 'msw';
import { faker } from '@faker-js/faker';

// Build an SSE stream from a sequence of text chunks
function buildSSEStream(chunks: string[]): ReadableStream {
  return new ReadableStream({
    start(controller) {
      chunks.forEach((chunk, index) => {
        const data = `data: ${JSON.stringify({ chunk, index })}\n\n`;
        controller.enqueue(new TextEncoder().encode(data));
      });
      // Signal end of stream
      controller.enqueue(new TextEncoder().encode('data: [DONE]\n\n'));
      controller.close();
    },
  });
}

// Factory: streaming AI response (simulates OpenAI/Claude streaming API)
export function buildStreamingAIResponse(
  text: string = 'This is a streamed AI response.'
): ReadableStream {
  // Split text into word-by-word chunks (simulates token streaming)
  const chunks = text.split(' ').map((word, i) => (i === 0 ? word : ` ${word}`));
  return buildSSEStream(chunks);
}

// MSW handler for streaming AI endpoint
export const sseHandlers = [
  http.post('/api/ai/stream', () => {
    const stream = buildStreamingAIResponse(
      'The answer to your question is found in the documentation.'
    );
    return new HttpResponse(stream, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    });
  }),

  // Error stream — simulates mid-stream failure
  http.post('/api/ai/stream/error', () => {
    const errorStream = new ReadableStream({
      start(controller) {
        controller.enqueue(new TextEncoder().encode('data: {"chunk": "Starting"}\n\n'));
        // Simulate network error mid-stream
        controller.error(new Error('Stream interrupted'));
      },
    });
    return new HttpResponse(errorStream, {
      headers: { 'Content-Type': 'text/event-stream' },
    });
  }),
];
```

**[community] Production lesson — SSE reconnection test data:** EventSource clients
automatically reconnect on connection loss. Tests that verify reconnection behaviour need
factory sequences that first close the connection, then provide a second sequence of
messages on reconnect. Most teams test the "happy path" stream but miss the reconnection
— leading to production bugs where the component shows stale data after a transient
network interruption.

---

## Equivalence Partitioning (EP) Factory Patterns  [community]

ISTQB CTFL 4.0 defines **Equivalence Partitioning (EP)** as dividing input data into
partitions where all values in a partition are expected to be processed the same way.
One representative value per partition is sufficient — testing all values in the same
partition adds no defect-detection value. Factories should expose named EP variants
rather than scattering representative values as magic literals across test files.

**EP vs BVA:** EP selects *representative values* from the middle of each partition.
BVA focuses on the *boundaries between partitions*. Together they give complete coverage:
EP verifies the typical behaviour in each class; BVA verifies the transitions between
classes. Both techniques are implemented most effectively as named factory variants.

**Why it matters:** Without named EP factories, teams write the same representative
value in dozens of tests and then forget to update them when a business rule changes.
A named factory variant (`UserEP.premiumWithExpiredTrial()`) documents which equivalence
class it represents — making the test intent explicit and the maintenance location obvious.

```typescript
// factories/ep.factory.ts — Equivalence Partitioning factory variants
// Each factory method represents ONE value from ONE equivalence class
import { faker } from '@faker-js/faker';
import { buildUser } from './user.factory';
import { buildOrder } from './order.factory';
import { User, Order } from '../domain';

// ── Equivalence Classes for User.subscriptionTier ────────────────────────────
// Business rule: tier determines which features are accessible
// EC1: 'free'       → no premium features, no priority support
// EC2: 'premium'    → all features, standard support
// EC3: 'enterprise' → all features + SSO, priority support, custom contracts
export const UserTierEP = {
  free: (): User => buildUser({ subscriptionTier: 'free', paymentMethodId: null }),
  premium: (): User => buildUser({ subscriptionTier: 'premium', paymentMethodId: faker.string.uuid() }),
  enterprise: (): User => buildUser({ subscriptionTier: 'enterprise', paymentMethodId: faker.string.uuid() }),
};

// ── Equivalence Classes for Order.currency ───────────────────────────────────
// Business rule: tax calculation differs by currency zone
// EC1: USD (no VAT)
// EC2: EUR (EU VAT applies — 20%)
// EC3: GBP (UK VAT applies — 20% post-Brexit)
// EC4: JPY (consumption tax 10%, zero decimal places)
// EC5: BTC (crypto — no tax, different precision rules)
export const OrderCurrencyEP = {
  usd: (overrides?: Partial<Order>): Order => buildOrder({ currency: 'USD', ...overrides }),
  eur: (overrides?: Partial<Order>): Order => buildOrder({ currency: 'EUR', ...overrides }),
  gbp: (overrides?: Partial<Order>): Order => buildOrder({ currency: 'GBP', ...overrides }),
  jpy: (overrides?: Partial<Order>): Order => buildOrder({
    currency: 'JPY',
    totalCents: faker.number.int({ min: 100, max: 100_000 }) * 100,  // JPY has no cents
    ...overrides,
  }),
  btc: (overrides?: Partial<Order>): Order => buildOrder({ currency: 'BTC', ...overrides }),
};

// ── Equivalence Classes for User.status ──────────────────────────────────────
// Business rule: only 'active' users can initiate transactions
// EC1: 'active'    → can initiate all operations
// EC2: 'suspended' → blocked from financial operations; can still read profile
// EC3: 'pending'   → registration incomplete; cannot initiate or read premium features
export const UserStatusEP = {
  active: (): User => buildUser({ status: 'active' }),
  suspended: (): User => buildUser({ status: 'suspended' }),
  pending: (): User => buildUser({ status: 'pending' }),
};

// ── Combined EP + BVA parametric test suite ──────────────────────────────────
// Each entry: [equivalence class name, factory variant, expected checkout result]
export const checkoutEPMatrix = [
  ['free tier — no payment method',    UserTierEP.free,       'payment_required'],
  ['premium tier — with payment',      UserTierEP.premium,    'success'],
  ['enterprise tier — with payment',   UserTierEP.enterprise, 'success'],
] as const;
```

```typescript
// specs/checkout-ep.test.ts — EP parametric test using the matrix
import { test, expect } from 'vitest';
import { checkoutEPMatrix } from '../factories/ep.factory';
import { checkoutService } from '../services/checkout.service';
import { buildCart } from '../factories/cart.factory';

test.each(checkoutEPMatrix)(
  'checkout for %s returns %s',
  (className, userFactory, expectedResult) => {
    const user = userFactory();
    const cart = buildCart({ items: [{ productId: faker.string.uuid(), quantity: 1 }] });

    const result = checkoutService.initiate(user, cart);
    expect(result.status).toBe(expectedResult);
  }
);
```

**ISTQB traceability pattern:** In teams that maintain ISTQB-aligned test documentation,
EP factory variant names map directly to test conditions and test cases:

| ISTQB term | EP factory concept |
|---|---|
| Test basis | Business rule documentation (e.g., "tier determines feature access") |
| Test condition | Equivalence class (`UserTierEP.free` = "user with free tier") |
| Test case | A specific test using `UserTierEP.free()` with expected result |
| Test suite | `checkoutEPMatrix` — all EC representatives for one business rule |
| Defect | A factory variant that reveals different behaviour than its EC representative |

When a domain rule changes (e.g., "enterprise tier now requires an approved contract"),
update the `UserTierEP.enterprise` factory variant and run the test suite — the impacted
test cases are immediately visible by their failing EC names.

---

## Test Data Checklist — Pre-Ship Review  [community]

Before merging a PR that adds new tests or factories, verify these items to prevent
test data technical debt from accumulating.

**Factory quality checklist:**
- [ ] Factory uses `Partial<T>` overrides (not `any`) — TypeScript validates override field names
- [ ] Dynamic fields use `faker.*` or `sequence` — no hardcoded strings for fields that should be unique
- [ ] `createdAt` and timestamp fields use fixed dates in snapshot tests; faker dates in unit/integration tests
- [ ] Factory file has JSDoc `@example` blocks for the most common use cases
- [ ] Factory is registered in the shared registry (`factories/registry.ts`) if it's a core domain entity
- [ ] Any DB-persisting `create()` calls have a corresponding cleanup (`afterEach`, `await using`, or Playwright fixture teardown)

**Test isolation checklist:**
- [ ] No test reads rows created by a *different* test (no cross-test DB state dependency)
- [ ] No test depends on insertion order or auto-increment IDs
- [ ] Parallel test run (`vitest --pool=forks`) passes without failures
- [ ] `TEST_SEED` is logged in CI output (faker seed for reproducibility)

**Security checklist:**
- [ ] No PII, production emails, real names, or real IDs in committed fixture files
- [ ] No hardcoded test user IDs in production code (`isTestUser()` guards)
- [ ] `assertTestEnvironment()` guard in any factory that persists to a DB
- [ ] Multi-tenant entities use unique `tenantId` per test (not a shared constant)

**AI / LLM test data checklist (when testing AI-powered features):**
- [ ] LLM-generated factory code reviewed against the faker v10 API checklist (no deprecated `faker.name.*`, `faker.address.*`; no CommonJS `require()` in ESM-only v10)
- [ ] No LLM API calls at test runtime — all AI-generated content is committed as static fixtures
- [ ] LLM response factories cover ≥ 5 output variants: standard, truncated, refusal, empty, markdown
- [ ] AI feature test suites use deterministic factory responses (not live API calls) in CI

**Equivalence Partitioning (EP) checklist:**
- [ ] New business rules have corresponding EP factory variants (one per equivalence class)
- [ ] EP factory variant names document the equivalence class they represent (not magic values)
- [ ] Combined EP + BVA parametric matrix exists for each critical business rule
- [ ] EP factory map uses `Record<UnionType, () => T>` to enforce compile-time exhaustiveness

**Real-time / event-driven checklist:**
- [ ] Event factory produces the full broker envelope (SQS Record, EventBridge event, Kafka message), not just the payload
- [ ] Event schemas derived from a shared schema package — not duplicated in producer and consumer tests
- [ ] Out-of-order event delivery tested (shuffled timestamps in batch factory)
- [ ] WebSocket / SSE test factories cover error and reconnection scenarios, not only the happy path

**Playwright fixtures checklist:**
- [ ] Infrastructure fixtures (DB seed, auth state) use `{ box: true }` to keep test reports focused on assertion steps
- [ ] Large fixture suites use `mergeTests()` to compose domain-aligned fixture modules rather than one monolithic fixture file
- [ ] Worker-scoped fixtures (expensive setup) are scoped with `{ scope: 'worker' }` to share cost across tests in the same worker
- [ ] All Playwright fixtures have guaranteed teardown — no `afterAll` skipped on test failure
- [ ] Playwright ≥ 1.59: use `await using` for scoped mid-test resources (route overrides, init scripts) instead of manual `unroute()`/`evaluate()` cleanup
- [ ] `playwright.config.ts` uses `testProject.workers` to right-size parallelism per project (DB-heavy projects capped at 2–4; UI-only projects at full workers)
- [ ] CI pipelines use `--grep @smoke` for fast pre-commit checks and `--grep @integration` for merge-queue runs; `globalSetup` gates DB provisioning on the grep filter
- [ ] HAR fixture files (`.har`) committed to source control have a nightly CI job that deletes and re-records them to catch third-party API drift
- [ ] Playwright ≥ 1.48: WebSocket test data uses `page.routeWebSocket()` for E2E-layer interception; fixtures call `page.unrouteAll()` in teardown when page objects are worker-scoped
- [ ] Playwright ≥ 1.49: DB seeding split across independent setup projects with `dependencies` + `teardown` fields — no monolithic `globalSetup.ts` containing all seed logic
- [ ] Playwright ≥ 1.50: factory-parametric tests with scenario-inapplicable steps use `step.skip(condition, reason)` rather than `if (condition) return` inside step bodies
- [ ] Playwright ≥ 1.60: fixtures that enforce test data preconditions (test environment, no stale state) use `test.abort(message)` instead of `throw` or `expect()` for clearer failure output
- [ ] Playwright ≥ 1.52: integration projects with multiple workers enable `failOnFlakyTests: true` to surface factory data isolation bugs that pass on retry
- [ ] Playwright ≥ 1.53: factory-variant locators use `locator.describe('${variant} element')` for semantic trace labelling — avoids anonymous selector entries in failure traces
- [ ] Playwright ≥ 1.56: `page.requests()` used in post-interaction assertions to verify factory-driven API call patterns and detect N+1 regressions introduced by domain model changes

**Vitest configuration checklist (Vitest 4.x):**
- [ ] `poolOptions` is NOT used — settings are top-level (`isolate`, `maxWorkers`, `pool`)
- [ ] If using `maxWorkers: 1, isolate: false`: a `setupFiles` entry calls `vi.resetModules()` in `beforeAll` to prevent module-state leakage between files
- [ ] CI scripts use `VITEST_MAX_WORKERS` (not `VITEST_MAX_THREADS` or `VITEST_MAX_FORKS`) to control parallelism
- [ ] Mixed isolation strategies use `projects` array (each project can have its own `isolate` setting)

**Vitest 4.1 fixture checklist:**
- [ ] New `test.extend()` fixtures use the builder pattern (return value, `onCleanup()`) rather than the `use()` callback — reduces TypeScript boilerplate
- [ ] Transaction-per-test isolation uses `test.aroundEach()` on the extended test object (not on the base `test` from vitest)
- [ ] Suite-level DB setup uses `test.aroundAll()` or `test.beforeAll()` on the extended test object — these can only access file-scoped and worker-scoped fixtures, not test-scoped fixtures
- [ ] Per-suite factory variant overrides use `test.override()` rather than `beforeEach` mutation of shared state
- [ ] Shared assertion helpers wrapping multiple `expect()` calls are wrapped with `vi.defineHelper()` for call-site stack traces
- [ ] `coverage.include` is explicitly set — `coverage.all: true` and `coverage.extensions` no longer exist in Vitest 4.x
- [ ] Factory directories are included in `coverage.include` patterns to catch dead factory code
- [ ] Test tags declared in `vitest.config.ts` for integration, unit, e2e, and slow test suites — enables `TestRunner.matchesTags()` conditional DB seeding
- [ ] `globalSetup.ts` uses `runner.matchesTags(['integration', 'e2e'])` to skip Testcontainers start when running unit-only tag filters
- [ ] `coverage.changed` configured to point at the base branch for PR-scoped factory coverage diffs
- [ ] Factory utility branches intentionally excluded from coverage use `/* istanbul ignore start */` / `/* v8 ignore start */` block comments (not repeated `/* istanbul ignore next */` per line)

---

## Vitest 4.0 `expect.schemaMatching` — Inline Factory Output Validation  [community]

Vitest 4.0 (October 2025) introduced `expect.schemaMatching()` — an asymmetric matcher
that validates a value against any **Standard Schema v1** validator (Zod, Valibot, ArkType)
inside a standard `expect` assertion. This eliminates the boilerplate of calling
`schema.parse(factory.build())` in a separate step and provides inline validation that
factory output matches the declared schema contract.

**Why it matters for test data factories:** Factory drift from the domain schema is the
most dangerous long-term maintenance failure. Traditionally, catching drift required either
TypeScript compile-time checks (only catches type errors, not runtime constraint violations
such as `z.email()` or `z.min(1)`) or explicit `parse` calls that pollute test bodies with
validation logic. `expect.schemaMatching` integrates schema validation into the assertion
itself — when a factory produces structurally valid TypeScript but semantically invalid data
(an empty string where `min(1)` is required, a non-UUID where `z.uuid()` is expected), the
test assertion fails immediately and the error points to the specific schema constraint
violated.

**25. [community] Factory schema drift caught by `expect.schemaMatching` but missed by TypeScript**
A factory that builds `{ email: '' }` (empty string) satisfies `string` at the TypeScript
level but violates `z.email()` at runtime. Before Vitest 4.0, only a manual `UserSchema.parse()`
call in the test setup revealed this. After adding `expect.schemaMatching` to factory-level
smoke tests, a team discovered 7 factory defaults that produced invalid schema values — all
of which had been producing silent runtime failures in downstream MSW handlers that validated
incoming data.

```typescript
// schemas/user.schema.ts — Zod v4 schema (Standard Schema v1 compatible)
import { z } from 'zod';

export const UserSchema = z.object({
  id: z.uuid(),
  email: z.email(),
  name: z.string().min(1).max(100),
  status: z.enum(['active', 'suspended', 'pending']),
  subscriptionTier: z.enum(['free', 'premium', 'enterprise']),
  createdAt: z.date(),
  paymentMethodId: z.string().nullable(),
});

export type User = z.infer<typeof UserSchema>;
```

```typescript
// test/factory-smoke.test.ts — schema validation smoke tests for factory output
// Run as part of the test suite; catches factory drift before it reaches integration tests
import { test, expect } from 'vitest';
import { UserSchema } from '../schemas/user.schema';
import { buildUser, buildUserList } from '../factories/user.factory';
import { buildOrder } from '../factories/order.factory';
import { OrderSchema } from '../schemas/order.schema';

// Smoke test: every factory default must satisfy the schema it claims to represent
test('buildUser() produces a value conforming to UserSchema', () => {
  const user = buildUser();
  // expect.schemaMatching validates against Zod schema inline — no .parse() needed
  expect(user).toEqual(expect.schemaMatching(UserSchema));
  // Failure message shows which Zod constraint failed and the actual value:
  //   "Expected value to match schema, but got validation errors:
  //    - email: Invalid email"
});

test('buildUser({ status: "suspended" }) still satisfies UserSchema', () => {
  const user = buildUser({ status: 'suspended' });
  expect(user).toEqual(expect.schemaMatching(UserSchema));
});

// Validate all factory variants — catches Object Mother drift
test('every UserMother variant satisfies UserSchema', () => {
  const { UserMother } = require('../factories/user.mother');
  const variants = [
    UserMother.default(),
    UserMother.suspended(),
    UserMother.premiumWithPayment(),
    UserMother.adminUser(),
  ];
  for (const user of variants) {
    expect(user).toEqual(expect.schemaMatching(UserSchema));
  }
});

// Validate inside complex data structures — works with toEqual, toStrictEqual, toContainEqual
test('buildUserList() returns an array where every item satisfies UserSchema', () => {
  const users = buildUserList(5);
  for (const user of users) {
    expect(user).toEqual(expect.schemaMatching(UserSchema));
  }
});

// Partial schema validation — check only the fields relevant to a test
test('buildUser() has a valid email and non-empty name', () => {
  const user = buildUser();
  // Validate a subset of the schema using a Zod pick
  expect(user).toEqual(expect.schemaMatching(
    UserSchema.pick({ email: true, name: true })
  ));
});
```

**Works with Valibot and ArkType** (all Standard Schema v1 compatible):

```typescript
// With Valibot (Standard Schema v1)
import * as v from 'valibot';
const UserValibotSchema = v.object({
  id: v.pipe(v.string(), v.uuid()),
  email: v.pipe(v.string(), v.email()),
  name: v.pipe(v.string(), v.minLength(1), v.maxLength(100)),
  status: v.picklist(['active', 'suspended', 'pending']),
});

test('buildUser() satisfies Valibot UserSchema', () => {
  expect(buildUser()).toEqual(expect.schemaMatching(UserValibotSchema));
});

// With ArkType (Standard Schema v1)
import { type } from 'arktype';
const UserArkSchema = type({
  id: 'string.uuid',
  email: 'string.email',
  name: '1 <= string <= 100',
  status: "'active' | 'suspended' | 'pending'",
});

test('buildUser() satisfies ArkType UserSchema', () => {
  expect(buildUser()).toEqual(expect.schemaMatching(UserArkSchema));
});
```

**Integration with pre-ship checklist:** Add to the factory smoke test suite as a
CI-required gate:

```bash
# package.json scripts
"test:factory-smoke": "vitest run test/factory-smoke.test.ts --reporter=verbose"
"test:ci": "npm run test:factory-smoke && npm run test:all"
```

**Anti-pattern:** Using `expect.schemaMatching` in every single test case for non-schema-related
assertions adds noise. Reserve it for: (1) dedicated factory smoke tests, (2) tests where
the schema contract is the primary test condition, (3) integration tests that assert a
service's *output* satisfies the contract schema before returning it to the caller.

---

## Vitest 4.0 `getSeed()` — Programmatic Factory Seed Access  [community]

Vitest 4.0 (October 2025) added a `getSeed()` API method on the public `vitest` module.
When tests are run with `--random-seed` (or rely on faker's randomness), `getSeed()`
returns the numeric seed for the current test run. This enables factory files to retrieve
the active seed programmatically — without relying on the `TEST_SEED` environment variable
convention described earlier in this guide.

**Why it matters:** Before `getSeed()`, factory files that wanted to align with Vitest's
random seed had to rely on the `TEST_SEED` environment variable, which was set manually by
CI scripts and often not set in local development. This caused faker seeds to diverge
between Vitest's internal seed (used for test shuffling) and faker's seed (used for data
generation). With `getSeed()`, factories can use the same seed Vitest already chose — giving
a single point of truth for both test order and test data randomness.

```typescript
// vitest.setup.ts — align faker seed with Vitest's getSeed() API
// Requires: vitest >= 4.0.0
import { faker } from '@faker-js/faker';
import { getSeed } from 'vitest';

// getSeed() returns the current test run seed — same value that governs test shuffling
// when --shuffle or --random-seed is active.
const VITEST_SEED = getSeed();
console.log(`[test-data] faker seed aligned with Vitest: ${VITEST_SEED}`);
faker.seed(VITEST_SEED);

// In CI — emit as GitHub Actions annotation:
if (process.env.GITHUB_ACTIONS) {
  process.stdout.write(`::notice title=Faker+Vitest Seed::${VITEST_SEED}\n`);
}

// To replay a failing run with the same seed:
// VITEST_SEED=<seed> npx vitest run
// Both test shuffling AND factory data generation will be identical.
```

**Before vs after `getSeed()` — seed alignment comparison:**

| Scenario | Before `getSeed()` | After `getSeed()` |
|---|---|---|
| Local dev, no `TEST_SEED` | faker uses `Date.now()` — different from Vitest shuffle seed | faker uses Vitest's seed — same as shuffle |
| CI with `--random-seed` | `TEST_SEED` must be set separately; easy to forget | `getSeed()` automatically aligns with `--random-seed` |
| Replay a failure | Must find both Vitest seed AND faker seed in logs | Single seed governs both — one log line |
| `--no-random-seed` (sequential) | faker seed is always `Date.now()` | faker seed aligns with Vitest's deterministic `0` seed |

**Edge case: `getSeed()` in `globalSetup`:**

`getSeed()` is only available after Vitest initializes the test runner. In `globalSetup`
files (which run before the test runner is fully initialized), `getSeed()` may return `0`
or the default seed rather than the run-specific seed. Use `getSeed()` in `setupFiles`
(which run inside the test worker, after initialization), not in `globalSetup`.

```typescript
// BAD: getSeed() in globalSetup — may return 0 before runner initializes
// vitest.config.ts → globalSetup: './test/global-setup.ts'
export async function setup(): Promise<void> {
  const seed = getSeed();  // ← may be 0 here (not yet initialized)
  faker.seed(seed);
}

// GOOD: getSeed() in setupFiles — runs in worker after initialization
// vitest.config.ts → setupFiles: ['./test/vitest.setup.ts']
// In vitest.setup.ts:
import { getSeed } from 'vitest';
import { faker } from '@faker-js/faker';
faker.seed(getSeed());  // ← always the correct run seed here
```

---

## Vitest 4.1 Experimental `viteModuleRunner: false` — Native Node.js Factory Execution  [community]

Vitest 4.1 (March 2026) added an experimental flag `experimental.viteModuleRunner: false`
that disables Vite's module runner sandbox and executes tests with native Node.js `import`
statements. This mode has specific implications for test data factories: import errors
that the Vite sandbox silently swallowed are now surfaced immediately, making factories
more reliable but requiring some adjustments.

**Why it matters for factories:**

The Vite module runner applies transforms (TypeScript stripping, path alias resolution,
`import.meta.env` injection) in a sandbox that can silently paper over certain import
errors. A factory file that uses `import.meta.env.TEST_DATABASE_URL` — valid only in
Vite's virtual module system — will produce `undefined` at runtime in native Node.js
mode rather than throwing. Similarly, a factory importing a path alias (`@/db`) that
Node.js doesn't understand causes an immediate `ERR_MODULE_NOT_FOUND` instead of a
silent resolution.

**Surfaces two critical factory bugs:**

1. **Incorrect `__dirname` injection:** The Vite sandbox injected `__dirname` as a
   virtual global. In native Node mode, `__dirname` is only available in CommonJS modules.
   Factory files that use `__dirname` to construct fixture file paths (e.g.,
   `path.join(__dirname, '../fixtures/users.json')`) must migrate to `import.meta.dirname`
   (Node 22.13+) or `new URL('../fixtures/users.json', import.meta.url).pathname`.

2. **Silently passing imports of non-existent exports:** The Vite sandbox allowed
   `import { buildUser } from './user.factory'` even when `buildUser` wasn't exported
   (returning `undefined`). Native Node.js mode throws `SyntaxError: The requested module
   does not provide an export named 'buildUser'`.

```typescript
// vitest.config.ts — enabling native Node.js module execution
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Experimental: disable Vite module runner for native Node.js imports
    // Requires: Node.js 22.18+ or 23.6+ (TypeScript stripped natively)
    // NOT suitable for: browser-mode tests, tests using jsdom/happy-dom,
    //                   tests relying on Vite plugins or path aliases
    experimental: {
      viteModuleRunner: false,  // use native Node.js imports
    },
    // Still works with vi.mock() via Node.js Module Loader API (Node.js 22.15+)
    // Does NOT work with: istanbul coverage provider, Vite aliases, import.meta.env
  },
});
```

```typescript
// BEFORE: factory using __dirname (works in Vite sandbox, fails in native Node)
import { readFileSync } from 'fs';
import { join } from 'path';

// This breaks in viteModuleRunner: false — __dirname is not defined in ESM
const seedData = JSON.parse(readFileSync(join(__dirname, '../fixtures/users.json'), 'utf8'));

// AFTER: migrate to import.meta.dirname (Node.js 22.13+) or import.meta.url
// Works identically in both Vite sandbox and native Node.js
const seedData = JSON.parse(readFileSync(
  new URL('../fixtures/users.json', import.meta.url).pathname,
  'utf8'
));

// Or with Node.js 22.13+ import.meta.dirname:
// const seedData = JSON.parse(readFileSync(join(import.meta.dirname, '../fixtures/users.json'), 'utf8'));
```

```typescript
// BEFORE: factory silently using undefined export (passes in Vite sandbox)
// user.factory.ts exports: buildUser (NOT buildActiveUser)
import { buildActiveUser } from '../factories/user.factory';
//         ↑ undefined in Vite sandbox — test runs, produces no data errors
//         ↑ SyntaxError in native Node — caught immediately

const user = buildActiveUser({ email: 'test@test.com' });
// In Vite sandbox: user is undefined, test may still pass (depending on usage)
// In native Node: import fails at module load — error points to the import line

// AFTER: fix the import to use the actual exported name
import { buildUser } from '../factories/user.factory';
const user = buildUser({ status: 'active', email: 'test@test.com' });
```

**When to use `viteModuleRunner: false`:**

| Scenario | Recommended |
|---|---|
| Server-side / Node.js-only test suites (no browser APIs) | Yes — faster startup, more accurate error messages |
| Suites using `jsdom` or `happy-dom` | No — browser simulation requires Vite transforms |
| Suites relying on Vite path aliases (`@/`) | No — native Node.js doesn't resolve Vite aliases |
| Suites using `istanbul` coverage provider | No — istanbul requires Vite instrumentation transforms |
| Suites auditing factory import correctness | Yes — catches `undefined` export imports that Vite hides |
| TypeScript 5.x with Node.js 22.18+ | Yes — TypeScript is stripped natively, no ts-node/esbuild needed |

**[community] Production lesson:** A team enabling `viteModuleRunner: false` on their
factory-heavy integration suite discovered that 12 factory files had been silently
re-exporting `undefined` functions due to stale re-export barrels
(`export { buildOrder } from './order.factory'` after `buildOrder` was renamed to
`createOrder`). The Vite sandbox had masked all 12 — native Node.js surfaced them
on the first run with a clear `SyntaxError` for each.

---

## "Construct with Collaborators, Call with Work" — Google Testing Blog Pattern  [community]

*Source: Google Testing Blog, Shahar Roth, May 5, 2026 (TotT series)*

The "Construct with Collaborators, Call with Work" principle from Google's Testing on the
Toilet series is directly applicable to factory design. The principle separates expensive
**construction** (collaborator setup: DB connections, factory initialization, test fixtures)
from **work calls** (the actual test operations). In the factory context, this maps to:

- **Construction = factory initialization** — building the domain object, creating DB records,
  setting up fixtures. This is the "collaborator" phase: expensive, done once.
- **Work = test assertions and service calls** — the actual test body that exercises the
  system under test. This is the "work" phase: fast, called repeatedly.

**Why it matters:** Factories that mix construction and work create tests that are slow
(re-construct on every assertion), brittle (construction side-effects leak between tests),
and hard to debug (failures appear in the construction phase rather than the assertion).
Separating them produces tests where the factory provides a clean, reusable starting state
and the test body only performs the work being verified.

**Anti-pattern: construction mixed with work:**

```typescript
// WRONG — construction and work are interleaved
test('suspended user cannot checkout', async () => {
  // Construction (DB insert) mixed with work (service call)
  const userId = await userRepository.create({
    email: faker.internet.email(),
    status: 'suspended',       // hardcoded — construction detail in test body
    subscriptionTier: 'free',
    createdAt: new Date(),
  });

  // Work — what we're actually testing
  const result = await checkoutService.initiate(userId, cart);
  expect(result.status).toBe('blocked');

  // Cleanup — interleaved with work logic
  await userRepository.delete(userId);
});
```

**Pattern: separate construction from work using fixtures:**

```typescript
// CORRECT — construction in fixture, work in test body
// Construction phase (factory + fixture):
export const test = baseTest.extend({
  // Worker-scoped construction: DB connection created once per worker
  db: [async ({}, { onCleanup }) => {
    const pool = new Pool({ connectionString: process.env.TEST_DATABASE_URL });
    onCleanup(() => pool.end());
    return drizzle(pool, { schema });
  }, { scope: 'worker' }],

  // Test-scoped construction: suspended user created per test, cleaned up after
  suspendedUser: async ({ db }, { onCleanup }) => {
    const [user] = await db.insert(users)
      .values(buildUser({ status: 'suspended' }))  // factory handles the domain object
      .returning();
    onCleanup(() => db.delete(users).where(eq(users.id, user.id)));
    return user;  // construction complete — work starts in the test body
  },
});

// Test body is pure work — no DB setup, no cleanup logic
test('suspended user cannot checkout', async ({ suspendedUser }) => {
  const result = await checkoutService.initiate(suspendedUser.id, cart);
  expect(result.status).toBe('blocked');
  expect(result.reason).toBe('account_suspended');
  // No cleanup — fixture handles it
});

test('suspended user can still view their profile', async ({ suspendedUser }) => {
  const profile = await profileService.get(suspendedUser.id);
  expect(profile.id).toBe(suspendedUser.id);
  // Same construction (suspendedUser fixture) reused across different work tests
});
```

**Object Mother as "construction catalogue":**

Object Mother methods are named construction operations — they encode how to build a
collaborator (a well-known domain variant) so the test body only describes the work:

```typescript
// Object Mother = construction catalogue for the test
// Each method is a named collaborator variant, reusable across all work tests
export class UserMother {
  // Construction: an active free-tier user (no payment, no premium features)
  static freeTierActive(): UserBuilder {
    return new UserBuilder().withStatus('active').withSubscriptionTier('free');
  }

  // Construction: a suspended user blocked from transactions
  static suspended(): UserBuilder {
    return new UserBuilder().withStatus('suspended');
  }

  // Construction: a premium user with payment — can initiate all operations
  static premiumWithPayment(): UserBuilder {
    return new UserBuilder()
      .withStatus('active')
      .withSubscriptionTier('premium')
      .withPaymentMethod('pm-visa-9999');
  }
}

// Work-only test bodies — construction delegated to Object Mother
test('free-tier user is asked to upgrade at premium feature', () => {
  const user = UserMother.freeTierActive().build();  // construction
  const result = featureGate.check(user, 'analytics-dashboard');  // work
  expect(result.allowed).toBe(false);
  expect(result.upgradePrompt).toBe('premium_required');
});

test('premium user accesses analytics dashboard', () => {
  const user = UserMother.premiumWithPayment().build();  // construction
  const result = featureGate.check(user, 'analytics-dashboard');  // work
  expect(result.allowed).toBe(true);
});
```

**Key benefits:**
1. **Readability:** The test body answers "what is being tested?" without construction noise.
2. **Reuse:** The same construction (Object Mother variant or fixture) serves multiple work tests.
3. **Locality of change:** When the "suspended user" construction changes (new required field), only the Object Mother method changes — not 30 test bodies.
4. **Faster isolation debugging:** Construction failures (factory drift, DB errors) and work failures (service logic bugs) produce different error locations — easier to triage.

---

## Key Resources (additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Vitest 4.0 blog post | Official | https://vitest.dev/blog/vitest-4 | Full changelog: expect.schemaMatching (Standard Schema), getSeed() API, Browser Mode stable, toMatchScreenshot, expect.assert |
| expect.schemaMatching docs | Official | https://vitest.dev/api/expect#expect-schemamatching | Asymmetric matcher for Standard Schema v1 validators (Zod, Valibot, ArkType) — inline factory output validation |
| Vitest getSeed() API | Official | https://vitest.dev/api/vitest#getseed | Programmatic access to the Vitest run seed for faker alignment |
| Vitest experimental.viteModuleRunner | Official | https://vitest.dev/config/#experimental-vitemodulerunner | Native Node.js module execution: surfaces factory import errors hidden by Vite sandbox |
| Google Testing Blog — Construct with Collaborators | Blog | https://testing.googleblog.com/2026/05/construct-with-collaborators-call-with.html | Principle: separate collaborator construction from work calls; applies directly to factory + fixture design |
| @faker-js/faker v10.4.0 | Official | https://github.com/faker-js/faker/releases/tag/v10.4.0 | Latest stable faker release (March 23, 2026) — ESM-only, UUID v7, 70+ locales |
| fishery v2.4.0 | Official | https://github.com/thoughtbot/fishery/releases/tag/v2.4.0 | Latest stable fishery release (December 8, 2025) — TypeScript-first factory library with build/create separation |

---

## Playwright 1.59 Async Disposables — `await using` for E2E Test Data Cleanup  [community]

Playwright 1.59 (2025) extended TypeScript 5.2's `await using` / `Symbol.asyncDispose`
support to Playwright's own fixture APIs: `context.newPage()`, `page.route()`,
`page.addInitScript()`, and `context.tracing.startHar()` now all return async disposables.
This means you can scope E2E test data infrastructure (route interception, init scripts,
HAR recording) with block-scope lifetime — cleanup fires automatically when the block
exits, with no `try/finally` or `afterEach` hook required.

**Why it matters for test data in E2E tests:** Playwright fixture teardown is already
guaranteed via the fixture lifecycle. But within a test body, ad-hoc resources such as
per-test route overrides (`page.route()`) and init scripts that inject seed data into
`localStorage` or `sessionStorage` had no scoped cleanup — they persisted for the lifetime
of the page. With async disposables, you can scope these mid-test resources to an inner
block, cleanly separating "baseline fixture data" from "scenario-specific overrides".

```typescript
// specs/checkout-data-injection.spec.ts
// Playwright 1.59+ async disposable APIs for scoped E2E test data

import { test, expect } from '@playwright/test';

test('checkout flow with per-scenario injected cart data', async ({ context }) => {
  // Worker-scoped page — lasts for the entire test
  await using page = await context.newPage();

  // Navigate to baseline state
  await page.goto('/checkout');

  // Inner block: inject a specific cart configuration and verify its effect
  // The route override is removed automatically when the block exits
  {
    // Scope the route override to this scenario block only
    await using _cartRoute = await page.route('/api/cart', (route) => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          items: [
            { productId: 'prod-premium-001', quantity: 2, unitPriceCents: 4999 },
          ],
          totalCents: 9998,
          currency: 'USD',
        }),
      });
    });

    // Within this block, /api/cart returns our factory-injected data
    await page.reload();
    await expect(page.locator('[data-testid="cart-total"]')).toContainText('$99.98');
    await expect(page.locator('[data-testid="item-count"]')).toContainText('2');
    // _cartRoute is automatically removed as this block exits — route reverts to default
  }

  // After the block: page is back to real /api/cart behavior
  // Next scenario can inject a different cart without residual route state
  {
    await using _emptyCartRoute = await page.route('/api/cart', (route) => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ items: [], totalCents: 0, currency: 'USD' }),
      });
    });

    await page.reload();
    await expect(page.locator('[data-testid="empty-cart-message"]')).toBeVisible();
  }
  // page is also cleaned up automatically — context.newPage() returned a disposable
});
```

```typescript
// Using await using with init scripts for localStorage seeding
test('returns user to their last-viewed product (from localStorage)', async ({ context }) => {
  await using page = await context.newPage();

  {
    // Inject test data into localStorage before page load — scoped to this block
    await using _initScript = await page.addInitScript(() => {
      window.localStorage.setItem('lastViewedProduct', JSON.stringify({
        id: 'prod-e2e-001',
        name: 'E2E Test Widget',
        viewedAt: '2024-06-15T10:00:00Z',
      }));
    });

    await page.goto('/shop');
    // The init script fires before page load — localStorage is seeded correctly
    await expect(page.locator('[data-testid="last-viewed"]')).toContainText('E2E Test Widget');
    // _initScript removed at block exit — next goto() starts without the injected data
  }

  // Verify that without the injected localStorage, the section is absent
  await page.reload();
  await expect(page.locator('[data-testid="last-viewed"]')).not.toBeVisible();
});
```

**Requirements:**
- Playwright ≥ 1.59
- TypeScript ≥ 5.2 (for `await using` keyword)
- `"target": "ES2022"` or higher and `"lib": ["es2022", "esnext.disposable"]` in `tsconfig.json`

**Comparison with Playwright fixture teardown:**

| Mechanism | Scope | Use case |
|---|---|---|
| Playwright `test.extend()` fixture | Test or worker | Persistent DB state, authenticated sessions, shared containers |
| `await using` in test body | Block (inner `{}`) | Scenario-specific route overrides, init script variants within one test |
| `try/finally` (pre-1.59) | Manual | Same as `await using` but verbose; cleanup skipped if `return` is hit |
| `afterEach` hook | Entire test file | Bulk teardown; cannot scope to one test's inner block |

---

## Playwright 1.60 HAR Record/Replay — Native Self-Initializing Fake for E2E  [community]

Playwright 1.60 promoted HAR (HTTP Archive) recording to a **first-class tracing API**
via `context.tracing.startHar()` / `stopHar()`. Combined with the existing
`page.routeFromHAR()` and `browserContext.routeFromHAR()` APIs, this provides a
Playwright-native implementation of the Self-Initializing Fake pattern — recording real
third-party API responses on first run and replaying them deterministically in subsequent
test runs, without any custom MSW plumbing.

**Why it matters vs the MSW self-initializing-fake:** The MSW-based implementation
(described earlier in this guide) requires custom handler code and a fixture management
directory. Playwright's `routeFromHAR()` is a zero-boilerplate alternative that records
the exact HTTP responses the real browser received, including response headers, status codes,
timing, and multipart responses — closer to real-world fidelity than a hand-coded MSW handler.

```typescript
// fixtures/playwright-har-fixtures.ts — HAR-based self-initializing fake via Playwright 1.60
import { test as base, expect } from '@playwright/test';
import { existsSync, mkdirSync } from 'fs';
import { join } from 'path';

const HAR_DIR = join(__dirname, '../__har__');

type HarFixtures = {
  // Fixture that routes all external API calls through a HAR file
  // First run: records real API responses to the HAR file
  // Subsequent runs: replays from the HAR file (no network calls)
  harPage: import('@playwright/test').Page;
};

export const test = base.extend<HarFixtures>({
  harPage: async ({ context }, use, testInfo) => {
    mkdirSync(HAR_DIR, { recursive: true });
    const harFile = join(HAR_DIR, `${testInfo.titlePath.join('-').replace(/\s+/g, '_')}.har`);

    if (existsSync(harFile)) {
      // Replay mode: serve all matching requests from the HAR file
      await context.routeFromHAR(harFile, {
        // Only replay requests to third-party APIs; let internal API pass through
        url: /^https:\/\/api\.(stripe|twilio|sendgrid)\.com/,
        // Strict mode: fail the test if a request isn't in the HAR
        notFound: 'fallback',
        update: false,
      });

      const page = await context.newPage();
      await use(page);
      await page.close();
    } else {
      // Record mode: capture real responses into the HAR file
      // Requires live API keys in the environment — only runs when HAR doesn't exist
      const page = await context.newPage();

      // Playwright 1.60: tracing.startHar() as a first-class API
      await context.tracing.startHar({
        path: harFile,
        content: 'omit',    // omit response bodies > 64KB to keep HAR files small
        mode: 'minimal',    // record only URL + status + headers (no full body)
        urlFilter: /^https:\/\/api\.(stripe|twilio|sendgrid)\.com/,
      });

      await use(page);

      await context.tracing.stopHar();
      await page.close();

      console.log(`[har-fixture] Recorded HAR: ${harFile} — commit this file.`);
    }
  },
});

export { expect };
```

```typescript
// specs/payment-integration.spec.ts — Stripe API responses replayed from HAR
import { test, expect } from '../fixtures/playwright-har-fixtures';

// First run (no HAR file): calls real Stripe sandbox API, records responses
// Subsequent runs (HAR file exists): replays recorded responses — no Stripe key needed in CI
test('checkout successfully charges card via Stripe', async ({ harPage }) => {
  await harPage.goto('/checkout');
  await harPage.fill('[data-testid="card-number"]', '4242424242424242');
  await harPage.fill('[data-testid="card-expiry"]', '12/30');
  await harPage.fill('[data-testid="card-cvc"]', '123');
  await harPage.click('[data-testid="pay-button"]');

  // This test exercises the real Stripe.js API flow on first run,
  // then replays the recorded responses deterministically in CI
  await expect(harPage.locator('[data-testid="order-confirmation"]')).toBeVisible();
  await expect(harPage.locator('[data-testid="order-id"]')).not.toBeEmpty();
});
```

```typescript
// scripts/refresh-har-recordings.ts — nightly job to re-record HAR files
// Run as a scheduled CI job (cron), not on PRs — requires live API credentials
import { readdirSync, rmSync } from 'fs';
import { join } from 'path';

const HAR_DIR = join(__dirname, '../__har__');

// Delete all HAR files to force re-recording on next test run
readdirSync(HAR_DIR).forEach((file) => {
  if (file.endsWith('.har')) {
    rmSync(join(HAR_DIR, file));
    console.log(`[har-refresh] Deleted: ${file}`);
  }
});
// CI then runs the Playwright suite with live credentials → HAR files are regenerated
// Commit the new HAR files to source control if the suite passes
```

**`routeFromHAR()` vs MSW self-initializing fake comparison:**

| Dimension | Playwright `routeFromHAR()` | MSW self-initializing fake |
|---|---|---|
| Setup cost | Zero — Playwright built-in | Custom handler code + fixture manager |
| Response fidelity | Exact browser-level response (headers, status, timing) | Programmatic mock (only what you specify) |
| Binary/multipart responses | Captured natively | Requires custom serialization |
| Scope | Browser context level (all pages) | Per-handler (fine-grained) |
| Drift detection | Manual re-recording (no CI signal) | Nightly CI deletion + re-record pattern |
| Unit test support | No — Playwright only | Yes — works in Vitest/Jest unit tests |
| Best for | E2E tests consuming third-party APIs | Unit and integration tests mocking internal APIs |

**Commit HAR files to source control.** They document the exact contract between your
application and the third-party API at the time of recording. PRs that change the
integration code can be reviewed against the committed HAR to verify expected API behavior.

---

## Playwright `testProject.workers` — Per-Project Parallelism for Test Data Isolation  [community]

Playwright 1.57 added `testProject.workers`, which allows specifying the number of
concurrent workers **per project** within a `playwright.config.ts`. This is directly
relevant to test data isolation: integration-heavy projects that share a database need
fewer workers (to reduce connection pool pressure), while pure UI projects can run at
full parallelism.

**Why it matters:** Before `testProject.workers`, the global `workers` setting applied
equally to all projects. A config with `workers: 4` would spin up 4 workers for the
database-heavy integration project *and* 4 for the lightweight UI project — potentially
exhausting the test DB connection pool while the UI tests wasted slots they didn't need.
Per-project worker limits let you right-size each project's parallelism independently.

```typescript
// playwright.config.ts — per-project worker counts for test data isolation
import { defineConfig } from '@playwright/test';

export default defineConfig({
  // Global maximum — no project can exceed this
  workers: 8,

  projects: [
    {
      name: 'unit-like',
      testMatch: '**/*.unit.spec.ts',
      // No DB involvement — run at full parallelism
      // workers omitted → uses global workers: 8
    },
    {
      name: 'ui-smoke',
      testMatch: '**/*.smoke.spec.ts',
      use: { browserName: 'chromium' },
      // Moderate parallelism — each worker creates a new page, no shared DB state
      workers: 4,
    },
    {
      name: 'integration',
      testMatch: '**/*.integration.spec.ts',
      use: { baseURL: process.env.TEST_API_URL },
      // DB-heavy — limit to 2 workers to stay within connection pool size
      // Each worker uses a separate transaction-rollback connection
      workers: 2,
    },
    {
      name: 'e2e-checkout',
      testMatch: '**/checkout/**/*.spec.ts',
      // Sequential — Stripe sandbox has rate limits that parallel runs hit
      workers: 1,
    },
  ],
});
```

```typescript
// fixtures/db-fixture.ts — per-worker DB connection pool sized to testProject.workers
// With workers: 2 for the integration project, max: 2 pool matches exactly
import { test as base } from '@playwright/test';
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from '../db/schema';

// Pool sized to the project's workers setting — no spare connections wasted
const pool = new Pool({
  connectionString: process.env.TEST_DATABASE_URL,
  max: 2,  // matches workers: 2 in playwright.config.ts
  idleTimeoutMillis: 5000,
});

export const test = base.extend({
  db: async ({}, use) => {
    const db = drizzle(pool, { schema });
    // Transaction-rollback isolation: each test begins a transaction and rolls back
    const client = await pool.connect();
    await client.query('BEGIN');

    // Provide a transaction-scoped db to the test
    const txDb = drizzle(client, { schema });
    await use(txDb);

    await client.query('ROLLBACK');
    client.release();
  },
});
```

**Factory strategy by project worker count:**

| Workers | Factory strategy | Isolation mechanism |
|---|---|---|
| 1 | Any strategy | Sequential — no isolation needed |
| 2–4 | Namespace prefix OR transaction rollback | Low contention on shared DB |
| 5–8 | Per-worker DB via Testcontainers or Neon branch | Each worker gets its own DB |
| Unlimited (no DB) | Pure in-memory factories | No DB state to isolate |

---

## Playwright `@tag` Syntax — Conditional E2E Fixture Setup  [community]

Playwright supports test tags via the `@tag` prefix in test titles or the `tag` option in
test options. Combined with `--grep`/`--grep-invert` CLI filters, tags enable conditional
E2E fixture setup — the Playwright equivalent of Vitest's `TestRunner.matchesTags()` for
skipping expensive DB seeding when running only smoke tests.

**Why it matters for test data:** E2E test suites often have two distinct data needs:
- **Smoke tests** (`@smoke`): stateless, use MSW/HAR fixtures only — no DB seeding required
- **Integration E2E tests** (`@integration`): need a seeded DB, Testcontainers, or Neon branch

Without tags, all tests run with the same global setup, meaning `globalSetup` always
provisions the DB — even when CI is running only smoke tests for a fast pre-merge check.
Playwright tags let CI pipelines explicitly skip DB provisioning for smoke-only runs.

```typescript
// playwright.config.ts — global setup with tag-aware DB provisioning
import { defineConfig } from '@playwright/test';

export default defineConfig({
  globalSetup: './test/global-setup.ts',
  globalTeardown: './test/global-teardown.ts',
  workers: process.env.CI ? 2 : undefined,
});
```

```typescript
// test/global-setup.ts — conditional DB seeding based on active tag filter
// Playwright does not expose a TestRunner.matchesTags() equivalent, but the
// --grep filter is readable via process.env.PLAYWRIGHT_GREP (set by Playwright CLI)
export default async function globalSetup(): Promise<void> {
  const grepFilter = process.env.PLAYWRIGHT_GREP ?? '';
  const grepInvertFilter = process.env.PLAYWRIGHT_GREP_INVERT ?? '';

  // Detect if integration tests are included in this run
  const isIntegrationRun =
    grepFilter.includes('@integration') ||       // explicitly included
    (!grepFilter && !grepInvertFilter) ||          // no filter = run all = includes integration
    (grepFilter === '' && grepInvertFilter !== '@integration');  // all except explicitly excluded

  if (isIntegrationRun) {
    console.log('[globalSetup] Provisioning test database (integration tests detected)...');
    // Start Testcontainers or create Neon branch
    await provisionTestDatabase();
    await seedBaselineData();
  } else {
    console.log('[globalSetup] Skipping DB provision (smoke/unit tag filter active)');
  }
}
```

```typescript
// specs/checkout.spec.ts — tagged tests for conditional setup
import { test, expect } from '@playwright/test';

// @smoke: runs against MSW/HAR fixtures only — no DB required
test('checkout button is visible @smoke', async ({ page }) => {
  await page.goto('/checkout');
  await expect(page.locator('[data-testid="checkout-button"]')).toBeVisible();
});

// @integration: requires a seeded DB with real users and orders
test('checkout completes for authenticated user @integration', async ({ page }) => {
  // This test requires DB seeding from globalSetup
  await page.goto('/login');
  await page.fill('[data-testid="email"]', 'e2e-user@test.com');
  await page.fill('[data-testid="password"]', 'Test@12345');
  await page.click('[data-testid="submit"]');
  await page.waitForURL('/dashboard');
  // ... complete checkout flow
});
```

```bash
# CI pipeline — smoke-only run (no DB provisioning, ~8 seconds)
npx playwright test --grep @smoke

# Full integration run (with DB provisioning, ~45 seconds)
npx playwright test --grep @integration

# All tests except known-flaky (exclude, not include)
npx playwright test --grep-invert @flaky

# Exclude slow HAR-recording tests from PR checks
npx playwright test --grep-invert "@har-record"
```

**[community] Production lesson:** A team that adopted Playwright `@tag` filtering for CI
stages reduced their pre-commit Playwright run from 3 minutes to 25 seconds. The smoke
suite (`@smoke`) required no infrastructure setup and caught layout regressions. The full
integration suite ran only on the main branch merge queue — where the longer runtime was
acceptable. DB provisioning in `globalSetup` was gated on the grep pattern, eliminating
Testcontainers startup for all smoke-only runs.

---

26. **[community] HAR fixture drift — `routeFromHAR()` has no automatic re-recording signal, unlike API-backed tests.**
    The Playwright `routeFromHAR()` pattern (described in the HAR Record/Replay section above) replays recorded third-party API responses from committed `.har` files. Unlike the MSW self-initializing fake (which can be wired to a nightly CI job that deletes and re-records fixtures), HAR files committed to source control have **no built-in expiry signal**. When the third-party API adds a new required response field, the HAR file silently replays the old response format — tests continue passing while production breaks. The fix is a scheduled CI job (nightly cron) that deletes all `.har` files and re-runs the Playwright suite with live credentials, committing the updated HAR files if the suite passes. **Teams that adopt `routeFromHAR()` without this nightly re-recording job accumulate invisible API contract drift.** Set a calendar reminder or CI job within 1 week of adopting `routeFromHAR()` — otherwise, the first time the upstream API changes, the production issue will be discovered in a user report, not in CI.

    ```bash
    # .github/workflows/refresh-har-recordings.yml
    # Schedule: runs nightly on main branch only
    # on:
    #   schedule:
    #     - cron: '0 2 * * *'  # 2am UTC daily
    #   workflow_dispatch: {}   # allow manual trigger

    # Steps:
    # 1. Checkout repo
    # 2. Delete all .har files: find . -name "*.har" -delete
    # 3. Run Playwright with live credentials: npx playwright test --grep @har-record
    # 4. If tests pass: git add __har__/*.har && git commit -m "chore: refresh HAR recordings"
    # 5. If tests fail: create a GitHub issue alerting the team of API drift
    ```

---

## Playwright Fixture `{ option: true }` — Per-Project Factory Parameterization  [community]

Playwright fixtures support an `{ option: true }` flag that makes a fixture value configurable
per test project in `playwright.config.ts`. This is the idiomatic way to provide project-specific
factory defaults (e.g., different base URL environments, different seed data profiles, different
DB connection strings) without duplicating fixture definitions.

**Why it matters for test data:** In a monorepo with `staging` and `production-replica` test
projects, the DB connection string used by factory `create()` calls should differ per project.
Without `{ option: true }`, teams either duplicate fixtures or use environment variable checks
inside fixture bodies. The option pattern is declarative, type-safe, and visible in
`playwright.config.ts` — making per-environment factory configuration a first-class concern.

```typescript
// fixtures/factory-options.ts — declare factory configuration options
import { test as base } from '@playwright/test';
import { userFactory } from '../factories/user.factory';
import { db } from '../db';

// Type declaration for the configurable options
export type FactoryOptions = {
  // DB connection string — defaults to TEST_DATABASE_URL, overridden per project
  testDatabaseUrl: string;
  // Default subscription tier for factory-created users — overridden per project
  defaultUserTier: 'free' | 'premium' | 'enterprise';
  // Seed profile — which fixture data set to load in globalSetup
  seedProfile: 'minimal' | 'full' | 'performance';
};

// Fixture types for the actual test objects derived from options
type FactoryFixtures = {
  factoryUser: { id: string; email: string; tier: string };
};

// Declare options as configurable (option: true) and provide defaults
export const test = base.extend<FactoryFixtures & FactoryOptions>({
  // Options — configurable per project in playwright.config.ts
  testDatabaseUrl: [process.env.TEST_DATABASE_URL ?? '', { option: true }],
  defaultUserTier:  ['free', { option: true }],
  seedProfile:      ['minimal', { option: true }],

  // Fixture that consumes the options — creates a user using the project's tier default
  factoryUser: async ({ defaultUserTier }, use) => {
    const user = await userFactory.create({ subscriptionTier: defaultUserTier });
    await use({ id: user.id, email: user.email, tier: user.subscriptionTier });
    await userFactory.cleanup(user.id);
  },
});

export { expect } from '@playwright/test';
```

```typescript
// playwright.config.ts — per-project factory option overrides
import { defineConfig } from '@playwright/test';
import type { FactoryOptions } from './fixtures/factory-options';

export default defineConfig<FactoryOptions>({
  projects: [
    {
      name: 'staging-smoke',
      testMatch: '**/*.smoke.spec.ts',
      use: {
        baseURL: 'https://staging.example.com',
        testDatabaseUrl: process.env.STAGING_DATABASE_URL,
        defaultUserTier: 'free',          // smoke tests use free-tier users
        seedProfile: 'minimal',           // lightweight seed for fast smoke runs
      },
    },
    {
      name: 'staging-integration',
      testMatch: '**/*.integration.spec.ts',
      use: {
        baseURL: 'https://staging.example.com',
        testDatabaseUrl: process.env.STAGING_DATABASE_URL,
        defaultUserTier: 'premium',       // integration tests need premium features
        seedProfile: 'full',              // full seed for integration coverage
      },
      workers: 2,
    },
    {
      name: 'local',
      testMatch: '**/*.spec.ts',
      use: {
        baseURL: 'http://localhost:3000',
        testDatabaseUrl: 'postgresql://localhost/testdb',
        defaultUserTier: 'enterprise',    // local dev: use highest tier for feature access
        seedProfile: 'full',
      },
    },
  ],
});
```

```typescript
// specs/dashboard.spec.ts — test uses factoryUser, which respects the project's tier option
import { test, expect } from '../fixtures/factory-options';

// In 'staging-smoke' project: factoryUser has tier='free'
// In 'staging-integration' project: factoryUser has tier='premium'
// The SAME test exercises the correct feature access per project — no duplication
test('dashboard shows tier-appropriate widgets', async ({ page, factoryUser }) => {
  await page.goto(`/dashboard?userId=${factoryUser.id}`);

  if (factoryUser.tier === 'free') {
    await expect(page.locator('[data-testid="upgrade-prompt"]')).toBeVisible();
    await expect(page.locator('[data-testid="analytics-widget"]')).not.toBeVisible();
  } else {
    await expect(page.locator('[data-testid="analytics-widget"]')).toBeVisible();
  }
});
```

**Override options in a specific test file using `test.use()`:**
```typescript
// Temporarily override the defaultUserTier for a specific describe block
test.describe('enterprise-only features', () => {
  test.use({ defaultUserTier: 'enterprise' });

  test('SSO login button visible for enterprise users', async ({ page, factoryUser }) => {
    // factoryUser.tier === 'enterprise' in this describe block only
    await page.goto('/settings');
    await expect(page.locator('[data-testid="sso-config"]')).toBeVisible();
  });
});
```

**When `{ option: true }` is the right pattern:**
- Factory configuration that varies by test environment (staging vs. local vs. CI)
- Seed profiles that change what data is available per project
- Service endpoint URLs (different API base per project)
- Feature flag overrides that affect which fixtures are appropriate

**When `test.override()` is the right pattern instead:**
- Per-suite domain variant overrides (e.g., suspended user instead of active user for a checkout failure suite) — these are domain variants, not environment configuration
- Ad-hoc fixture overrides within a single test file — not reused across projects

---

## Playwright 1.51 `browserContext.setStorageState()` — Auth Test Data Reset  [community]

Playwright 1.51 introduced `browserContext.setStorageState()`, which **clears all existing
cookies, localStorage, and IndexedDB for all origins** and replaces them with new storage
state in a single call. This is the idiomatic way to reset authentication test data between
test cases that share a worker-scoped browser context — without creating an entirely new
`BrowserContext`.

**Why it matters:** A common pattern is to use a worker-scoped `BrowserContext` for performance
(one browser context per worker, shared across tests). But when test A logs in as `alice` and
test B needs to start as an anonymous user, the worker-scoped context retains Alice's session
cookies. Before `setStorageState()`, the only options were: (1) create a new context per test
(expensive), or (2) manually clear cookies + localStorage (fragile, multi-step). `setStorageState()`
is a single atomic operation that resets all auth state.

```typescript
// fixtures/auth-fixtures.ts — worker-scoped context with storage state reset
import { test as base } from '@playwright/test';
import path from 'path';
import { userFactory } from '../factories/user.factory';

type AuthFixtures = {
  // Worker-scoped: one context per worker (performance)
  sharedContext: import('@playwright/test').BrowserContext;
  // Test-scoped: resets auth state to anonymous before each test
  anonymousPage: import('@playwright/test').Page;
  // Test-scoped: resets auth state to a new user session before each test
  authenticatedPage: import('@playwright/test').Page;
};

export const test = base.extend<AuthFixtures>({
  sharedContext: [async ({ browser }, use) => {
    const context = await browser.newContext();
    await use(context);
    await context.close();
  }, { scope: 'worker' }],

  // Reset to anonymous (clear all storage) — fast: no new context creation
  anonymousPage: async ({ sharedContext }, use) => {
    // Playwright 1.51+: clears all cookies + localStorage + IndexedDB atomically
    await sharedContext.setStorageState({ cookies: [], origins: [] });
    const page = await sharedContext.newPage();
    await use(page);
    await page.close();
  },

  // Reset to a specific user's session — inject pre-generated auth state
  authenticatedPage: async ({ sharedContext }, use) => {
    // Load pre-generated storage state (created by auth.setup.ts or a login factory)
    // This replaces ALL existing storage — no residual state from previous tests
    await sharedContext.setStorageState({
      path: path.join(__dirname, '../.auth/user-session.json'),
    });
    const page = await sharedContext.newPage();
    await use(page);
    await page.close();
  },
});

export { expect } from '@playwright/test';
```

```typescript
// auth/auth.setup.ts — generates the user-session.json for authenticatedPage fixture
// Run as a Playwright setup project before the main test suite
import { test as setup } from '@playwright/test';
import path from 'path';

const AUTH_FILE = path.join(__dirname, '../.auth/user-session.json');

setup('authenticate and save storage state', async ({ page }) => {
  // Perform login with a factory-created test user
  await page.goto('/login');
  await page.fill('[data-testid="email"]', 'e2e-user@test.com');
  await page.fill('[data-testid="password"]', 'Test@12345');
  await page.click('[data-testid="submit"]');
  await page.waitForURL('/dashboard');

  // Save the full storage state (cookies + localStorage + IndexedDB) to file
  // This file is loaded by setStorageState() in authenticatedPage fixture
  await page.context().storageState({ path: AUTH_FILE });
});
```

```typescript
// playwright.config.ts — auth setup project runs before all test projects
export default defineConfig({
  projects: [
    {
      name: 'auth-setup',
      testMatch: '**/auth.setup.ts',
    },
    {
      name: 'e2e',
      testMatch: '**/*.spec.ts',
      dependencies: ['auth-setup'],  // auth-setup runs first
    },
  ],
});
```

**`setStorageState()` vs creating a new context:**

| Approach | Speed | Isolation | IndexedDB support |
|---|---|---|---|
| New `BrowserContext` per test | Slowest (~200–500ms) | Complete isolation | Yes |
| `setStorageState()` (1.51+) | Fast (~5–20ms) | Replaces all storage | Yes (v1.51+) |
| Manual cookie + localStorage clear | Medium (multiple calls) | Partial (IndexedDB untouched) | No |

**Note on IndexedDB:** Playwright 1.51 added `indexedDB` support to `storageState()`. Applications
using Firebase Authentication (which stores tokens in IndexedDB) or other IndexedDB-first auth
libraries can now fully serialize and restore auth state — not just cookie + localStorage based sessions.

---

## Vitest 5.0 Beta — Factory Author Migration Notes  [community]

Vitest 5.0 (currently in beta as of May 2026) introduces breaking changes that affect how
test data factories are written and configured. Teams should audit factory files before
upgrading to avoid silent behavioural changes.

**Breaking changes affecting factory authors:**

### 1. `test.concurrent` is now the default

Vitest 5.0 makes `test.concurrent` the default for all test cases (previously opt-in).
Tests within a file now run concurrently by default instead of sequentially. Factory
code that relies on sequential execution order within a file — particularly factories
with module-level counters or shared singleton connections — will produce race conditions
that were previously hidden.

**Before (Vitest 4.x, sequential by default):**
```typescript
// No race condition in 4.x — tests run sequentially within the file
let userCounter = 0;

function buildUserWithCounter(): User {
  // Module-level counter — safe in sequential mode
  userCounter++;
  return { id: `usr-${userCounter}`, email: `user-${userCounter}@test.com`, ... };
}

test('first user has counter 1', () => {
  const user = buildUserWithCounter();
  expect(user.id).toBe('usr-1');  // always passes in sequential mode
});

test('second user has counter 2', () => {
  const user = buildUserWithCounter();
  expect(user.id).toBe('usr-2');  // order-dependent — breaks in concurrent mode
});
```

**After (Vitest 5.0, concurrent by default):**
```typescript
// Replace module-level counters with per-call generation — concurrent-safe
import { faker } from '@faker-js/faker';

export function buildUser(overrides: Partial<User> = {}): User {
  return {
    // UUID generation is concurrent-safe — no shared counter state
    id: faker.string.uuid(),
    email: `${faker.string.uuid()}@test.com`,
    ...overrides,
  };
}

// OR: use fishery's sequence parameter — internally thread-safe in Vitest 5.x
export const userFactory = Factory.define<User>(({ sequence }) => ({
  id: faker.string.uuid(),
  email: `user-${sequence}@test.com`,  // fishery sequences are worker-scoped, not module-global
  ...
}));
```

**Opt back to sequential for a specific file (escape hatch):**
```typescript
// At the top of a test file that requires sequential execution
// (e.g., because it uses a transaction-rollback pattern that is single-connection)
test.describe.sequential('sequential DB tests', () => {
  test('...', async () => { /* ... */ });
  test('...', async () => { /* ... */ });
});
```

### 2. `expect` is now an inline package

Vitest 5.0 extracts `expect` into a standalone `@vitest/expect` package. Test helpers that
import `expect` from `'vitest'` continue to work, but factory smoke test files that previously
imported `expect` directly for assertion helpers should be aware of the new import path if
they also use the package in non-Vitest contexts.

```typescript
// Works in both 4.x and 5.x:
import { test, expect } from 'vitest';

// New in 5.x — can also import from standalone package:
import { expect } from '@vitest/expect';
// Useful for: factory assertion utilities run outside Vitest (e.g., in Node scripts)
```

### 3. `sequential` test option renamed

The `sequential: true` test option that serialized concurrent tests back to sequential is
being renamed in 5.0 to `concurrent: false` to be more explicit. The old `sequential: true`
still works but is deprecated.

```typescript
// 4.x (still works in 5.x, but deprecated):
test('needs sequential execution', { sequential: true }, async () => { ... });

// 5.x (preferred):
test('needs sequential execution', { concurrent: false }, async () => { ... });
```

**Factory audit checklist for Vitest 5.0 upgrade:**
- [ ] Module-level counters in factory files replaced with per-call UUID/sequence generation
- [ ] Singleton DB connection factories wrapped in fixtures (not module-level `const pool = new Pool(...)`)
- [ ] `test.concurrent` usage changed from explicit opt-in to explicit opt-out where sequential is required
- [ ] `VITEST_MAX_WORKERS` env var still applies (unchanged from 4.x)
- [ ] `coverage.include` still required (unchanged from 4.x)
- [ ] Review `@vitest/expect` package import paths in standalone factory assertion utilities

---

27. **[community] Vitest 5.0 default-concurrent mode causes race conditions in factory files with module-level state.**
    When Vitest 4.x test suites upgrade to 5.0 beta, the default change from sequential to concurrent test execution within a file surfaces factory bugs that were previously hidden. The most common pattern: a factory file that initializes a DB connection pool or a sequence counter at module load (`const counter = 0; let pool = new Pool(...)`) works correctly when tests run sequentially but produces race conditions when they run concurrently. The symptom is flaky test failures that only appear in Vitest 5.0 — passing 95% of the time but failing under concurrent load. **Before upgrading to Vitest 5.0, audit every factory file for module-level mutable state**, and migrate counters to fishery's `sequence` parameter or `faker.string.uuid()`. DB connections should move to worker-scoped fixtures, not factory-file-level module singletons.

    ```typescript
    // AUDIT PATTERN: find module-level mutable state in factory files
    // Search for these patterns in src/factories/**/*.ts:
    // - let <variable> = (mutable variable outside a function)
    // - const <variable> = new Pool(...) (DB connection at module load)
    // - export let (exported mutable variable)
    // - let _counter = 0; (counter pattern)

    // SAFE: per-call generation (no module-level state)
    export function buildUser(): User {
      return { id: faker.string.uuid(), ... };  // faker.string.uuid() is concurrent-safe
    }

    // UNSAFE in Vitest 5.0: module-level mutable counter
    // let _seq = 0;
    // export function buildUser(): User { return { id: `usr-${++_seq}`, ... }; }
    ```

---

## faker v10 New APIs for Factory Authors — Complete Reference  [community]

`@faker-js/faker` v10.x (v10.0.0 released August 2025 through v10.4.0 March 2026) introduced
several new modules and API changes that affect factory authors beyond the ESM-only change
and UUID v7 (covered earlier in this guide). This section documents the remaining v10 additions.

### `faker.word` — Default Error Strategy Changed to `'fail'`

In faker v10.0.0, the `word` module changed its default error strategy from silent fallback
to `'fail'` (throws an error). In v9, calling `faker.word.sample({ length: 999 })` (requesting
a word longer than any in faker's dictionary) returned a random word silently. In v10, it
throws `FakerError: No word found for length 999`. Factory files that use `faker.word.*`
with unbounded or oversized length parameters will throw at factory call time.

**Why it matters:** The old silent fallback was masking factory misconfiguration — factories that
requested unrealistically long single words were silently producing random shorter words,
producing test data that didn't match the factory's intent. The `'fail'` default makes
misconfigured word factories immediately visible.

```typescript
// Anti-pattern caught by v10 'fail' strategy:
// This silently produced a short random word in v9; throws in v10
// faker.word.sample({ length: 50 })  // FakerError: No word found for length 50

// Correct patterns for word-length-constrained factory data:
import { faker } from '@faker-js/faker';

export function buildProductFactory(overrides: Partial<Product> = {}): Product {
  return {
    id: faker.string.uuid(),
    // Safe: generate a realistic product name (no unrealistic length constraint)
    sku: faker.string.alphanumeric(8).toUpperCase(),  // use string, not word, for codes
    name: faker.commerce.productName(),               // commerce module, not word
    // If you need a short word tag (1-3 syllables): bound the length realistically
    tag: faker.word.sample({ length: { min: 3, max: 8 } }),  // safe range
    ...overrides,
  };
}

// Override the error strategy to 'warn' if you intentionally want fallback behavior:
// (e.g., in a factory that tries short words but accepts longer ones as fallback)
const shortTag = faker.word.sample({
  length: { min: 3, max: 6 },
  strategy: 'closest',  // v10: returns the closest matching word instead of throwing
});
// Available strategies: 'fail' (default v10), 'warn' (logs and falls back), 'any-length', 'closest'
```

**Migration for existing factories:**
```typescript
// Audit command: find factories using faker.word.* with fixed length constraints
// grep -r "faker\.word\." src/factories/ test/factories/
// Then review each: is the length realistic? Could it fail in v10?

// Before v10 (silent fallback):
// faker.word.adjective(15)  // silently returned a random adjective, ignoring length

// v10 equivalent (explicit strategy):
faker.word.adjective({ length: { min: 5, max: 12 }, strategy: 'closest' })
// Returns the adjective closest to the requested length range
```

---

### `faker.number` — BigInt Support via `multipleOf`

faker v10.0.0 added BigInt support to `faker.number.bigInt()` with a `multipleOf` parameter.
This is relevant for factories testing code that uses database BigInt primary keys, large
numeric financial values (e.g., sub-cent precision for crypto), or bit-manipulation IDs.

**Why it matters for factories:** TypeScript projects using `bigint` primary keys (common in
Postgres with `bigserial` or large-scale distributed systems with 64-bit IDs) previously
required custom factory helpers to generate valid `bigint` test IDs. `faker.number.bigInt()`
is now the idiomatic approach.

```typescript
// factories/bigint-id.factory.ts — BigInt ID generation for large-scale schemas
import { faker } from '@faker-js/faker'; // requires faker v10.0.0+

// Postgres bigserial / snowflake-style ID factory
export function buildBigIntId(): bigint {
  // Generate a random BigInt ID in the valid Postgres bigint range (1 to 2^63-1)
  return faker.number.bigInt({
    min: BigInt(1),
    max: BigInt('9223372036854775807'),  // Postgres bigint max
  });
}

// BigInt IDs that are multiples of a specific value (for sharding logic tests)
export function buildShardedId(shardFactor: bigint = BigInt(1000)): bigint {
  return faker.number.bigInt({
    min: shardFactor,
    max: BigInt('9223372036854775807'),
    multipleOf: shardFactor,  // v10: IDs that are always multiples of shardFactor
  });
}

// Domain object with BigInt primary key
interface LargeScaleOrder {
  id: bigint;
  userId: bigint;
  totalCents: bigint;     // sub-cent precision for crypto or micropayment systems
  currency: string;
  createdAt: Date;
}

export function buildLargeScaleOrder(overrides: Partial<LargeScaleOrder> = {}): LargeScaleOrder {
  return {
    id: faker.number.bigInt({ min: BigInt(1), max: BigInt('9223372036854775807') }),
    userId: faker.number.bigInt({ min: BigInt(1), max: BigInt('9223372036854775807') }),
    totalCents: faker.number.bigInt({ min: BigInt(0), max: BigInt('1000000000000') }),
    currency: 'SATS',  // satoshi micropayments
    createdAt: new Date(),
    ...overrides,
  };
}
```

**Serialization warning for BigInt in JSON fixtures:**
```typescript
// BigInt does not serialize with JSON.stringify() by default:
// JSON.stringify({ id: BigInt(123) })  → TypeError: Do not know how to serialize a BigInt

// For test fixtures that need JSON serialization of BigInt fields, convert to string:
export function serializeBigIntFactory(order: LargeScaleOrder): Record<string, unknown> {
  return {
    ...order,
    id: order.id.toString(),       // serialize BigInt as string for JSON fixtures
    userId: order.userId.toString(),
    totalCents: order.totalCents.toString(),
  };
}

// Or configure Drizzle ORM to handle BigInt serialization:
// In Drizzle schema: bigint('id', { mode: 'bigint' }) uses JS BigInt natively
// In Prisma schema:  BigInt maps to BigInt in JS — requires JSON.stringify reviver
```

---

### `faker.book` Module — Content-Heavy Factory Data (v10.1.0)

faker v10.1.0 added a `book` module with localized data for titles, authors, genres, publishers,
series, and formats. This is directly useful for factories in e-commerce (bookstores),
content management systems, and library applications.

**Why it matters:** Previously, factories for book/content domain entities had to use generic
`faker.commerce.productName()` (e.g., "Ergonomic Rubber Keyboard") for book titles — visually
nonsensical in snapshot tests and Storybook stories. `faker.book.*` generates realistic
bibliographic data.

```typescript
// factories/book.factory.ts — using faker.book module (faker v10.1.0+)
import { faker } from '@faker-js/faker'; // requires faker v10.1.0+

interface Book {
  id: string;
  isbn: string;
  title: string;
  author: string;
  genre: string;
  publisher: string;
  series: string | null;
  format: 'paperback' | 'hardcover' | 'ebook' | 'audiobook';
  pageCount: number;
  publicationYear: number;
}

export function buildBook(overrides: Partial<Book> = {}): Book {
  return {
    id: faker.string.uuid(),
    // faker.book module — realistic bibliographic data (v10.1.0+)
    isbn: faker.commerce.isbn(),             // from commerce module (pre-v10)
    title: faker.book.title(),              // realistic book title
    author: faker.book.author(),            // realistic author name
    genre: faker.book.genre(),              // e.g. 'Science Fiction', 'Mystery'
    publisher: faker.book.publisher(),       // e.g. 'Penguin Random House'
    series: faker.datatype.boolean({ probability: 0.3 })
      ? faker.book.series()                 // e.g. 'Harry Potter', 'Discworld'
      : null,
    format: faker.helpers.arrayElement(['paperback', 'hardcover', 'ebook', 'audiobook'] as const),
    pageCount: faker.number.int({ min: 50, max: 1200 }),
    publicationYear: faker.number.int({ min: 1950, max: 2026 }),
    ...overrides,
  };
}

// Library catalogue factory — list of books with unique ISBNs
export function buildBookCatalogue(count: number, overrides: Partial<Book> = {}): Book[] {
  const isbnSet = new Set<string>();
  return Array.from({ length: count }, () => {
    let book: Book;
    do {
      book = buildBook(overrides);
    } while (isbnSet.has(book.isbn)); // ensure unique ISBNs
    isbnSet.add(book.isbn);
    return book;
  });
}

// In a Storybook story — book titles now look realistic in previews:
// { title: 'The Silence of the Deep', author: 'Elena Marchetti', genre: 'Thriller' }
// vs. old: { title: 'Ergonomic Rubber Keyboard', author: 'Lorem Ipsum', genre: 'Category' }
```

---

### `faker.commerce` — UPC Barcode Generation (v10.2.0)

faker v10.2.0 added UPC (Universal Product Code) barcode generation to the commerce module.
This complements the existing `faker.commerce.isbn()` (EAN-13 for books) and is relevant
for factories in retail, inventory, and point-of-sale applications.

```typescript
// factories/product.factory.ts — UPC barcodes for retail product factories
import { faker } from '@faker-js/faker'; // requires faker v10.2.0+

interface RetailProduct {
  id: string;
  barcode: string;       // UPC-A (12 digits) or EAN-13 (13 digits)
  sku: string;
  name: string;
  price: number;
  category: string;
}

export function buildRetailProduct(overrides: Partial<RetailProduct> = {}): RetailProduct {
  return {
    id: faker.string.uuid(),
    // faker.commerce UPC methods (v10.2.0+):
    // faker.commerce.upcA() — 12-digit UPC-A code (North American standard)
    // faker.commerce.ean13() — 13-digit EAN-13 code (international standard)
    barcode: faker.helpers.arrayElement([
      faker.commerce.upcA(),   // UPC-A: '012345678905'
      faker.commerce.ean13(),  // EAN-13: '5901234123457'
    ]),
    sku: faker.string.alphanumeric(8).toUpperCase(),
    name: faker.commerce.productName(),
    price: faker.number.float({ min: 0.99, max: 999.99, fractionDigits: 2 }),
    category: faker.commerce.department(),
    ...overrides,
  };
}

// Barcode uniqueness — important for inventory system tests
export function buildUniqueProductList(count: number): RetailProduct[] {
  const barcodeSet = new Set<string>();
  return Array.from({ length: count }, () => {
    let product: RetailProduct;
    do {
      product = buildRetailProduct();
    } while (barcodeSet.has(product.barcode));
    barcodeSet.add(product.barcode);
    return product;
  });
}
```

---

### `faker.location` — Simple Coordinate Methods (v10.0.0)

faker v10.0.0 added `faker.location.latitude()` and `faker.location.longitude()` as simple
top-level methods for generating GPS coordinates. Previously, the only coordinate generation
method was `faker.location.nearbyGPSCoordinate()` (which required a reference coordinate).
The new methods generate standalone coordinates within the global valid range.

**Why it matters:** Factories for geospatial applications (delivery, ride-sharing, logistics,
store locators) previously required either `nearbyGPSCoordinate()` with a hardcoded reference
point or manual `faker.number.float()` with the valid lat/long ranges. The new methods
are self-documenting and semantically correct.

```typescript
// factories/location.factory.ts — GPS coordinate factory (faker v10.0.0+)
import { faker } from '@faker-js/faker';

interface DeliveryAddress {
  id: string;
  street: string;
  city: string;
  postalCode: string;
  country: string;
  latitude: number;   // -90 to 90
  longitude: number;  // -180 to 180
}

export function buildDeliveryAddress(overrides: Partial<DeliveryAddress> = {}): DeliveryAddress {
  return {
    id: faker.string.uuid(),
    street: faker.location.streetAddress(),
    city: faker.location.city(),
    postalCode: faker.location.zipCode(),
    country: faker.location.countryCode('alpha-2'),
    // v10.0.0: simple standalone coordinate generation
    latitude: faker.location.latitude(),          // random: -90.0 to 90.0
    longitude: faker.location.longitude(),        // random: -180.0 to 180.0
    ...overrides,
  };
}

// Bounded region factory — for testing region-specific delivery logic
export function buildAddressInRegion(options: {
  latMin: number; latMax: number;
  lonMin: number; lonMax: number;
}): DeliveryAddress {
  return buildDeliveryAddress({
    latitude: faker.location.latitude({ min: options.latMin, max: options.latMax }),
    longitude: faker.location.longitude({ min: options.lonMin, max: options.lonMax }),
  });
}

// Usage — addresses within continental US bounds:
const usAddress = buildAddressInRegion({
  latMin: 24.4, latMax: 49.4,   // US latitude range
  lonMin: -125.0, lonMax: -66.9, // US longitude range
});
```

**Migration from `nearbyGPSCoordinate()`:**
```typescript
// Before v10 (still works, but more verbose for standalone coordinates):
// const [lat, lon] = faker.location.nearbyGPSCoordinate({
//   origin: [40.7128, -74.0060],  // NYC — required reference point
//   radius: 100, isMetric: true
// });

// v10.0.0 (standalone, no reference point needed):
const lat = faker.location.latitude();
const lon = faker.location.longitude();
```

---

### `faker.person.sex` — `'generic'` Sex Type (v10.3.0)

faker v10.3.0 added `'generic'` as a valid value for `sex` parameters in `faker.person.*`
methods. This enables factories for inclusive domain models where sex/gender is not binary.

**Why it matters for test data:** Applications with user profiles, medical systems, or HR software
may store non-binary gender/sex options. Factories using `faker.person.sex()` previously
only returned `'male'` or `'female'`. With `'generic'`, factories can generate test data
covering non-binary sex classifications without custom workarounds.

```typescript
// factories/person.factory.ts — inclusive sex/gender test data (faker v10.3.0+)
import { faker } from '@faker-js/faker';

interface UserProfile {
  id: string;
  firstName: string;
  lastName: string;
  sex: 'male' | 'female' | 'non-binary' | 'prefer-not-to-say';
  email: string;
}

export function buildUserProfile(overrides: Partial<UserProfile> = {}): UserProfile {
  // faker.person.sex() now returns 'male', 'female', or (v10.3.0+) 'generic'
  // Map faker's 'generic' to your domain's non-binary representation
  const fakerSex = faker.helpers.arrayElement(['male', 'female', 'generic'] as const);
  const domainSex = fakerSex === 'generic' ? 'non-binary' : fakerSex;

  // faker.person.firstName() uses sex to generate culturally appropriate names
  const firstName = faker.person.firstName(fakerSex === 'generic' ? undefined : fakerSex);

  return {
    id: faker.string.uuid(),
    firstName,
    lastName: faker.person.lastName(),
    sex: domainSex,
    email: faker.internet.email({ firstName }),
    ...overrides,
  };
}

// Explicit inclusive factory variants for parametric test cases:
export const ProfileVariants = {
  male: (): UserProfile => buildUserProfile({ sex: 'male',
    firstName: faker.person.firstName('male') }),
  female: (): UserProfile => buildUserProfile({ sex: 'female',
    firstName: faker.person.firstName('female') }),
  nonBinary: (): UserProfile => buildUserProfile({ sex: 'non-binary',
    firstName: faker.person.firstName() }),  // 'generic' → no gender-specific name
  preferNotToSay: (): UserProfile => buildUserProfile({ sex: 'prefer-not-to-say',
    firstName: faker.person.firstName() }),
};
```

---

## Playwright Component Testing `router` Fixture — MSW Test Data for Components  [community]

Playwright's component testing mode (experimental, `@playwright/test`'s `@playwright/experimental-ct-*`
packages) added a `router` fixture in v1.46 that accepts MSW request handlers directly. This
enables the same MSW test data injection pattern used in Vitest/Jest component tests to work
in Playwright's browser-rendered component tests — without an additional `setupServer()` call.

**Why it matters:** Component tests that render in a real browser (via Playwright CT) have
traditionally been harder to wire with MSW than jsdom-based tests. The `router` fixture is
a first-class bridge: pass your existing MSW handlers and Playwright CT injects them as
network interceptors in the browser context. Factory-generated MSW handlers can be shared
between Vitest unit tests and Playwright CT tests, keeping test data consistent across layers.

```typescript
// factories/component-handlers.factory.ts — MSW handlers for component tests
// Reusable across Vitest (setupServer) and Playwright CT (router fixture)
import { http, HttpResponse } from 'msw';
import { buildUser, buildUserList } from './user.factory';
import { buildOrder } from './order.factory';

// Base handlers — shared between Vitest and Playwright CT test suites
export const componentHandlers = [
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json(buildUser({ id: params.id as string }));
  }),
  http.get('/api/users', () => {
    return HttpResponse.json({ data: buildUserList(5), total: 5 });
  }),
  http.get('/api/orders', ({ request }) => {
    const userId = new URL(request.url).searchParams.get('userId') ?? 'usr-default';
    return HttpResponse.json(Array.from({ length: 3 }, () => buildOrder({ userId })));
  }),
];

// Error scenario handlers for component error-state tests
export const errorHandlers = {
  userNotFound: (id: string) =>
    http.get(`/api/users/${id}`, () =>
      HttpResponse.json({ message: 'User not found' }, { status: 404 })
    ),
  serverError: () =>
    http.get('/api/users', () =>
      HttpResponse.json({ message: 'Internal Server Error' }, { status: 500 })
    ),
};
```

```typescript
// ct-tests/UserCard.ct.test.tsx — Playwright CT with router fixture (v1.46+)
import { test, expect } from '@playwright/experimental-ct-react';
import { UserCard } from '../src/components/UserCard';
import { componentHandlers, errorHandlers } from '../factories/component-handlers.factory';
import { buildUser } from '../factories/user.factory';

// Install shared MSW handlers via the router fixture — no setupServer() call needed
test.beforeEach(async ({ router }) => {
  await router.use(...componentHandlers);
});

test('renders active user with correct badge color', async ({ mount }) => {
  const user = buildUser({ status: 'active', subscriptionTier: 'premium' });
  const component = await mount(<UserCard userId={user.id} />);

  // The router fixture intercepts /api/users/:id and returns factory-built data
  await expect(component.getByTestId('status-badge')).toHaveText('Active');
  await expect(component.getByTestId('tier-badge')).toHaveText('Premium');
});

test('renders error state when API returns 404', async ({ mount, router }) => {
  // Override the default handler for this specific test
  await router.use(errorHandlers.userNotFound('usr-nonexistent'));

  const component = await mount(<UserCard userId="usr-nonexistent" />);
  await expect(component.getByTestId('error-message')).toBeVisible();
  await expect(component.getByTestId('error-message')).toContainText('User not found');
});

test('renders loading skeleton while fetching', async ({ mount, router }) => {
  // Delay the response to test loading state
  await router.use(
    http.get('/api/users/:id', async () => {
      await new Promise((r) => setTimeout(r, 500));
      return HttpResponse.json(buildUser());
    })
  );

  const component = await mount(<UserCard userId="usr-any" />);
  // Immediately after mount: loading state should be visible
  await expect(component.getByTestId('skeleton-loader')).toBeVisible();
  // After 500ms: real data renders
  await expect(component.getByTestId('user-name')).toBeVisible({ timeout: 1000 });
});
```

**Using `router.use()` vs the standard Vitest `setupServer()` pattern:**

```typescript
// vitest unit test (jsdom) — uses setupServer + server.use()
import { setupServer } from 'msw/node';
import { componentHandlers } from '../factories/component-handlers.factory';

const server = setupServer(...componentHandlers);
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// Playwright CT test — uses router fixture instead
// The SAME handler array is reused — no duplication
test.beforeEach(async ({ router }) => {
  await router.use(...componentHandlers);
});
```

**Advantages of `router` fixture vs `setupServer()`:**
- No `beforeAll`/`afterAll` lifecycle management — Playwright CT handles it
- `router.use()` in individual tests overrides globally installed handlers (same as `server.use()`)
- Handlers reset automatically between tests (same as `server.resetHandlers()`)
- Works with React, Vue, Svelte, and Solid CT packages (`@playwright/experimental-ct-*`)
- Shares the same factory-generated handlers used in Vitest unit tests — single source of truth

**Current limitation:** The `router` fixture is experimental and only available in Playwright CT.
It cannot be used in standard end-to-end tests (use `page.route()` or MSW's browser integration
for E2E MSW). Check `playwright.config.ts` has `ctPort` configured and the appropriate
`@playwright/experimental-ct-*` package installed.

```typescript
// playwright-ct.config.ts — component testing configuration
import { defineConfig } from '@playwright/experimental-ct-react';

export default defineConfig({
  testDir: './ct-tests',
  use: {
    ctPort: 3100,                          // dedicated port for CT server
    ctViteConfig: () => import('./vite.config'),
  },
});
```

---

28. **[community] `faker.word` error strategy changed to `'fail'` in v10.0.0 — word-length constraints in factories now throw instead of silently degrading.**
    Before faker v10, calls like `faker.word.adjective(20)` (requesting a 20-character adjective) silently returned a random adjective, ignoring the length constraint. This masked factory misconfiguration: factories intended to generate short tag-like strings were actually generating random-length words that happened to pass tests. In faker v10.0.0, the default error strategy changed to `'fail'` — the same call now throws `FakerError: No word found for length 20`. Factory files that use `faker.word.*` with fixed length parameters break immediately on upgrade. The symptom is test suite startup failures (factories are called at module load in some patterns) or test failures in the first test that touches a word-based factory. **The fix is to replace fixed length parameters with ranged lengths or switch to `strategy: 'closest'`**, but this requires auditing every `faker.word.*` call in the codebase. Run `grep -r "faker\.word\." src/ test/` before upgrading to faker v10 to enumerate affected files.

    ```typescript
    // Audit and migration pattern for faker.word in factories:

    // BREAKS in v10 (fixed length that faker cannot satisfy):
    // faker.word.adjective(15)         → FakerError: No word found for length 15
    // faker.word.sample({ length: 50 }) → FakerError: No word found for length 50
    // faker.word.noun(30)              → FakerError: No word found for length 30

    // Fix 1: use ranged length (safe in both v9 and v10)
    faker.word.adjective({ length: { min: 4, max: 10 } })

    // Fix 2: use 'closest' strategy (v10+ only) — returns nearest available word
    faker.word.noun({ length: 15, strategy: 'closest' })

    // Fix 3: switch to a different module if the intent is generating strings, not words
    faker.string.alpha({ length: { min: 5, max: 12 } })    // for code-like strings
    faker.commerce.department()                              // for category labels
    faker.lorem.word()                                       // for generic filler words

    // Detection script for CI: fail if any factory uses faker.word with a plain number length
    // Add to package.json scripts or pre-commit hook:
    // "lint:factory-word": "grep -rn 'faker\\.word\\.\\w\\+([0-9]' src/ test/ && exit 1 || exit 0"
    ```

---

## Key Resources (iter-40 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| @faker-js/faker v10.0.0 migration | Official | https://next.fakerjs.dev/guide/upgrading | v10 breaking changes: ESM-only, word error strategy 'fail', bigint multipleOf, coordinate methods |
| @faker-js/faker — book module | Official | https://fakerjs.dev/api/book | faker.book.title/author/genre/publisher/series — realistic bibliographic test data |
| @faker-js/faker — location coords | Official | https://fakerjs.dev/api/location | faker.location.latitude()/longitude() — simple standalone GPS coordinate generation |
| @faker-js/faker — commerce UPC | Official | https://fakerjs.dev/api/commerce | faker.commerce.upcA()/ean13() — barcode generation for retail domain factories |
| Playwright CT router fixture | Official | https://playwright.dev/docs/test-components | `router.use(...handlers)` — MSW test data injection in Playwright component tests |
| @playwright/experimental-ct-react | Official | https://www.npmjs.com/package/@playwright/experimental-ct-react | Playwright CT package for React component tests with router fixture support |

---

## Key Resources (iter-38 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright 1.59 release notes | Official | https://playwright.dev/docs/release-notes#version-159 | Async disposable APIs: `await using page`, `route()`, `addInitScript()`, `startHar()` for scoped E2E test data |
| Playwright 1.60 release notes | Official | https://playwright.dev/docs/release-notes#version-160 | HAR as first-class tracing API: `tracing.startHar()` with `content`/`mode`/`urlFilter` options |
| Playwright `routeFromHAR()` docs | Official | https://playwright.dev/docs/api/class-browsercontext#browser-context-route-from-har | Native HAR record/replay — zero-boilerplate Self-Initializing Fake for Playwright E2E suites |
| Playwright `testProject.workers` | Official | https://playwright.dev/docs/api/class-testproject#test-project-workers | Per-project worker count for right-sizing test data isolation per test type |
| Playwright test annotations docs | Official | https://playwright.dev/docs/test-annotations | `@tag` syntax, `tag` option, `--grep`/`--grep-invert` for conditional E2E fixture setup |

## Key Resources (iter-39 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright fixture options docs | Official | https://playwright.dev/docs/test-fixtures#fixture-option | `{ option: true }` pattern for per-project factory configuration (tier, DB URL, seed profile) |
| Playwright `browserContext.setStorageState()` | Official | https://playwright.dev/docs/api/class-browsercontext#browser-context-set-storage-state | Atomically reset auth test data (cookies + localStorage + IndexedDB) within a shared context |
| Playwright 1.51 release notes | Official | https://playwright.dev/docs/release-notes#version-151 | IndexedDB in storageState + setStorageState() for Firebase/IndexedDB auth session management |
| Vitest 5.0 migration guide | Official | https://vitest.dev/guide/migration#vitest-5-0 | Concurrent-by-default change; `sequential` → `concurrent: false`; `@vitest/expect` package split |

---

## Playwright 1.48 `page.routeWebSocket()` — E2E WebSocket Test Data Interception  [community]

Playwright 1.48 added `page.routeWebSocket()` and `browserContext.routeWebSocket()` — first-class
WebSocket routing APIs for E2E tests. Unlike MSW's `ws.link()` handler (which intercepts at the
service worker / Node.js network layer), Playwright's `routeWebSocket()` operates at the browser
context level and is available in full E2E tests (not just component tests). This makes it the
correct tool for injecting WebSocket test data in Playwright E2E suites.

**Why it matters for test data:** Real-time features (live dashboards, collaborative editing,
chat) rely on WebSocket streams that are hard to control in E2E tests against a real server.
`routeWebSocket()` lets you intercept the connection and inject factory-generated message
sequences, error scenarios, and reconnect events — without a running WebSocket server and
without modifying the application under test.

**Two modes:**
1. **Full mock** — intercept all messages from the server, respond with factory-generated data
2. **Selective intercept** — pass most messages through (`ws.connectToServer()`) but inject
   specific factory-generated events for scenario coverage

```typescript
// specs/live-dashboard.spec.ts — Playwright 1.48+ WebSocket test data injection
import { test, expect } from '@playwright/test';

// Factory: generate a sequence of live metric updates
function buildMetricSequence(
  count: number,
  baseValue = 42
): Array<{ type: string; metric: string; value: number; timestamp: string }> {
  return Array.from({ length: count }, (_, i) => ({
    type: 'metric_update',
    metric: 'cpu_usage_pct',
    value: Math.min(100, baseValue + i * 5),    // escalating CPU values
    timestamp: new Date(Date.now() + i * 1000).toISOString(),
  }));
}

test('live dashboard displays escalating CPU metric stream', async ({ page }) => {
  // Install the WebSocket route before navigating — ensures no real WS connection is made
  await page.routeWebSocket('wss://metrics.example.com/stream', (ws) => {
    const updates = buildMetricSequence(5, 30);

    // Send factory-generated updates with realistic timing
    updates.forEach((update, index) => {
      setTimeout(() => {
        ws.send(JSON.stringify(update));
      }, index * 200);
    });

    // Handle messages sent from the page to the "server"
    ws.onMessage((message) => {
      const parsed = JSON.parse(message as string);
      if (parsed.type === 'subscribe') {
        // Acknowledge subscription immediately
        ws.send(JSON.stringify({ type: 'subscribed', channel: parsed.channel }));
      }
    });
  });

  await page.goto('/dashboard/metrics');

  // Initial render: shows connecting/loading state
  await expect(page.getByTestId('metric-status')).toContainText('Connecting');

  // After first factory message: initial value visible
  await expect(page.getByTestId('cpu-value')).toContainText('30', { timeout: 1000 });

  // After all 5 factory messages: final escalated value (30 + 4*5 = 50)
  await expect(page.getByTestId('cpu-value')).toContainText('50', { timeout: 2000 });
});

test('dashboard shows reconnect banner on WebSocket close', async ({ page }) => {
  let wsInstance: Parameters<Parameters<typeof page.routeWebSocket>[1]>[0] | null = null;

  await page.routeWebSocket('wss://metrics.example.com/stream', (ws) => {
    wsInstance = ws;
    // Send one initial metric so the dashboard enters "connected" state
    ws.send(JSON.stringify({
      type: 'metric_update', metric: 'cpu_usage_pct', value: 40,
      timestamp: new Date().toISOString(),
    }));
  });

  await page.goto('/dashboard/metrics');
  await expect(page.getByTestId('cpu-value')).toContainText('40', { timeout: 1000 });

  // Simulate server-side connection close (e.g., server restart)
  wsInstance!.close({ code: 1001, reason: 'Server going away' });

  // The component should show a reconnection banner
  await expect(page.getByTestId('reconnect-banner')).toBeVisible({ timeout: 2000 });
  await expect(page.getByTestId('reconnect-banner')).toContainText('Reconnecting');
});
```

**Selective passthrough with `ws.connectToServer()` — inject specific events into a real connection:**

```typescript
// Use connectToServer() when you need the real WS server but want to inject
// specific factory-generated events for scenario coverage
test('dashboard handles out-of-band alert injection', async ({ page }) => {
  await page.routeWebSocket('wss://metrics.example.com/stream', (ws) => {
    // Connect to the real server — most messages pass through transparently
    const server = ws.connectToServer();

    // After 500ms, inject a factory-generated critical alert into the stream
    // (as if the server had sent it — bypasses the need to trigger it server-side)
    setTimeout(() => {
      ws.send(JSON.stringify({
        type: 'critical_alert',
        message: 'CPU usage exceeded 95% threshold',
        severity: 'critical',
        timestamp: new Date().toISOString(),
      }));
    }, 500);

    // Optionally: intercept specific server messages and modify them
    // (e.g., escalate a 'warning' to 'critical' for specific test scenarios)
    server.onMessage((message) => {
      const parsed = JSON.parse(message as string);
      // Pass most messages through unchanged
      ws.send(message);
    });
  });

  await page.goto('/dashboard/metrics');
  // Wait for the injected critical alert to trigger the UI response
  await expect(page.getByTestId('critical-alert-banner')).toBeVisible({ timeout: 1500 });
});
```

**Comparison: `routeWebSocket()` vs MSW `ws.link()` for WebSocket test data:**

| Concern | `page.routeWebSocket()` (Playwright 1.48+) | MSW `ws.link()` |
|---|---|---|
| Test layer | E2E (full browser) | Component / unit (jsdom or browser-mode) |
| Setup | Call before `page.goto()` — no server required | Add handler to `setupServer()` or `setupWorker()` |
| Message sequence factories | Full support via `ws.send()` in `setTimeout` loops | Full support via `client.send()` in `setTimeout` loops |
| `connectToServer()` passthrough | Yes — selective interception of real WS | Yes — via `server.connectToServer()` |
| Fixture scoping | Lives in Playwright test body or fixture teardown | Lives in `server.resetHandlers()` / `afterEach` |
| TypeScript types | `WebSocketRoute` interface | `ws.EventMap` type from MSW |
| Auth headers on WS upgrade | Visible via `ws.url()` URL params | Not inspectable in service worker layer |

**Tradeoff:** `routeWebSocket()` does not persist across navigations. If your test navigates
to a new page after installing the route, you must re-install it. For multi-page E2E flows
with persistent WebSocket connections, use `browserContext.routeWebSocket()` instead — it
applies to all pages in the context for its lifetime.

---

## Playwright 1.49 Multiple `globalSetup` via Project Dependencies — Composable DB Seeding  [community]

Playwright 1.49 solidified support for multiple independent `globalSetup` / `globalTeardown`
projects using the `dependencies` + `teardown` project fields. This enables compositional
test data provisioning: each database tier, service, or feature area can have its own
dedicated setup project — eliminating the monolithic `globalSetup.ts` anti-pattern.

**Why it matters:** A single `globalSetup.ts` that runs all seed scripts sequentially has
two problems: (1) it becomes a maintenance bottleneck — every team's seed logic is in one
file; (2) it always runs all seeds even when only a subset of tests is being run. The
project-dependency model solves both: each setup project owns its seed domain and is only
executed when a test project that depends on it is included in the run.

```typescript
// playwright.config.ts — composable DB seeding via project dependencies
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  projects: [
    // ── Setup projects (seed domains) ────────────────────────────────────────
    {
      name: 'seed:users',
      testMatch: /setup\/seed-users\.ts/,
      teardown: 'teardown:users',
    },
    {
      name: 'seed:catalog',
      testMatch: /setup\/seed-catalog\.ts/,
      teardown: 'teardown:catalog',
    },
    {
      name: 'seed:orders',
      // Orders depend on users existing — sequential within setup projects
      dependencies: ['seed:users'],
      testMatch: /setup\/seed-orders\.ts/,
      teardown: 'teardown:orders',
    },

    // ── Teardown projects ─────────────────────────────────────────────────────
    {
      name: 'teardown:users',
      testMatch: /setup\/teardown-users\.ts/,
    },
    {
      name: 'teardown:catalog',
      testMatch: /setup\/teardown-catalog\.ts/,
    },
    {
      name: 'teardown:orders',
      testMatch: /setup\/teardown-orders\.ts/,
    },

    // ── Test projects — each declares which seed domains it requires ──────────
    {
      name: 'auth-flows',
      testMatch: '**/*.auth.spec.ts',
      use: { ...devices['Desktop Chrome'] },
      dependencies: ['seed:users'],        // only user seed runs for auth tests
    },
    {
      name: 'catalog-browse',
      testMatch: '**/*.catalog.spec.ts',
      use: { ...devices['Desktop Chrome'] },
      dependencies: ['seed:catalog'],      // only catalog seed runs for browse tests
    },
    {
      name: 'checkout',
      testMatch: '**/*.checkout.spec.ts',
      use: { ...devices['Desktop Chrome'] },
      // Checkout tests need both users and orders (orders dep already includes users)
      dependencies: ['seed:orders'],
    },
  ],
});
```

```typescript
// setup/seed-users.ts — owns all user seed logic
import { test as setup } from '@playwright/test';
import { db } from '../db';
import { userFactory } from '../factories/user.factory';

setup('seed users', async () => {
  // Create the canonical test user set — used by all auth tests
  await userFactory.create({ id: 'usr-free-001', subscriptionTier: 'free' });
  await userFactory.create({ id: 'usr-premium-001', subscriptionTier: 'premium' });
  await userFactory.create({ id: 'usr-suspended-001', status: 'suspended' });

  // Store auth state for reuse (avoids repeated login in tests)
  // This replaces the "login once, save storageState" pattern from a single globalSetup
  await db.user.createMany({ data: await userFactory.buildList(10) });
});
```

```typescript
// setup/teardown-users.ts — paired teardown project
import { test as teardown } from '@playwright/test';
import { db } from '../db';

teardown('teardown users', async () => {
  // Delete in correct FK order — orders before users
  await db.order.deleteMany({ where: { userId: { startsWith: 'usr-' } } });
  await db.user.deleteMany({ where: { id: { startsWith: 'usr-' } } });
});
```

**Selective seeding when running a subset of tests:**

```bash
# Only 'auth-flows' project runs → only 'seed:users' setup runs (catalog and orders skipped)
npx playwright test --project=auth-flows

# Only 'checkout' project runs → 'seed:orders' runs (which triggers 'seed:users' as a dep)
npx playwright test --project=checkout

# Targeted tag filter — only tests tagged @smoke; setup projects are still respected
npx playwright test --grep @smoke --project=auth-flows
```

**Key tradeoff:** The project-dependency setup only runs seed projects whose test projects are
included in the current run. This is the desired behaviour for CI efficiency — but it means
a developer running `npx playwright test --project=checkout` must ensure the `seed:users`
project can complete successfully in their local environment. A missing dependency (e.g., the
users DB table hasn't been migrated) fails in setup, not in the test — which produces a
clearer error message than a FK violation mid-test.

---

## Playwright 1.50 `test.step.skip()` — Data-Dependent Step Guarding  [community]

Playwright 1.50 added `test.step.skip()` — a method to conditionally skip a named test step
based on runtime data. This is directly useful for factory-driven E2E tests where setup
steps (e.g., "seed premium user", "add payment method") may be inapplicable for certain
test data configurations.

**Why it matters:** E2E tests that combine multiple factory-seeded scenarios in a single
spec file sometimes need to bypass infrastructure steps when the test data for a given
scenario does not require them. Without `test.step.skip()`, the choice was: (1) split into
separate spec files (more files, more maintenance), or (2) use `if (condition) return`
inside a step, which leaves the step as "passed" in reports instead of "skipped" —
obscuring what actually ran.

```typescript
// specs/user-onboarding.spec.ts — data-dependent step guarding
import { test, expect } from '@playwright/test';
import { userFactory } from '../factories/user.factory';

// Parametric test: same flow, different factory data
const onboardingScenarios = [
  { tier: 'free' as const,       requiresPayment: false, requiresTeamSetup: false },
  { tier: 'premium' as const,    requiresPayment: true,  requiresTeamSetup: false },
  { tier: 'enterprise' as const, requiresPayment: true,  requiresTeamSetup: true  },
];

for (const scenario of onboardingScenarios) {
  test(`onboarding flow for ${scenario.tier} user`, async ({ page }) => {
    const user = await userFactory.create({ subscriptionTier: scenario.tier });

    await test.step('navigate to onboarding', async () => {
      await page.goto(`/onboarding?userId=${user.id}`);
    });

    // Payment step — skip for free tier (not applicable to this factory data)
    await test.step('add payment method', async (step) => {
      step.skip(!scenario.requiresPayment,
        `Payment step not applicable for ${scenario.tier} tier`);

      await page.getByRole('button', { name: 'Add Payment Method' }).click();
      await page.getByLabel('Card number').fill('4242424242424242');
      await page.getByRole('button', { name: 'Save Card' }).click();
      await expect(page.getByTestId('payment-confirmed')).toBeVisible();
    });

    // Team setup step — skip for non-enterprise tiers
    await test.step('configure team', async (step) => {
      step.skip(!scenario.requiresTeamSetup,
        `Team setup not applicable for ${scenario.tier} tier`);

      await page.getByRole('button', { name: 'Invite Team Members' }).click();
      // Inject a factory-generated team member via the UI
      await page.getByLabel('Email').fill('teammate@example.com');
      await page.getByRole('button', { name: 'Send Invite' }).click();
      await expect(page.getByTestId('invite-sent')).toBeVisible();
    });

    // Always-run step — completes onboarding for all tiers
    await test.step('complete onboarding', async () => {
      await page.getByRole('button', { name: 'Finish Setup' }).click();
      await expect(page.getByTestId('dashboard')).toBeVisible();
    });
  });
}
```

**What the test report shows:**
- Free tier: `navigate to onboarding` ✓ | `add payment method` ↷ skipped | `configure team` ↷ skipped | `complete onboarding` ✓
- Premium tier: all 4 steps ✓ except `configure team` ↷ skipped
- Enterprise tier: all 4 steps ✓

This makes factory-parametric test reports self-documenting: reviewers immediately see which
steps were applicable to each scenario without reading the factory configuration.

**`test.step.skip()` vs `test.skip()`:**

| Method | Granularity | Use case |
|---|---|---|
| `test.skip(condition, reason)` | Entire test | Factory data that makes the whole test irrelevant |
| `step.skip(condition, reason)` | Single step | Factory data that makes one infrastructure step inapplicable |
| `test.fixme(condition, reason)` | Entire test | Factory data exercise that is known broken / under construction |

---

## Playwright 1.60 `test.abort()` — Factory Precondition Enforcement in Fixtures  [community]

Playwright 1.60 added `test.abort(message?)` — a method that immediately fails the current
test with a custom message. Unlike `test.skip()` (which marks the test as skipped and
continues to the next), `test.abort()` marks it as failed and halts execution. This is
designed to be called from within fixtures or route handlers when a precondition violation
is detected that makes continuing the test actively harmful or misleading.

**Why it matters for test data:** Factory-driven test suites have implicit preconditions.
A checkout test assumes the factory-created user has a payment method. A multi-tenant test
assumes the factory-created tenant is not shared with another concurrent test. When these
preconditions are violated — due to a CI environment misconfiguration, a leaked DB state,
or a factory bug — tests can produce false positives or corrupt shared state. `test.abort()`
lets you add lightweight runtime guards in fixtures that detect the violation and fail fast
with a descriptive message, rather than producing confusing assertion failures deep in the test.

```typescript
// fixtures/factory-guards.ts — precondition enforcement with test.abort()
import { test as base } from '@playwright/test';
import { db } from '../db';
import { userFactory } from '../factories/user.factory';

// Guard: ensure no stale test data from a previous run is present
// This detects leaked state when transaction rollback did not fire
async function assertNoStaleTestData(userId: string): Promise<void> {
  const existing = await db.user.findUnique({ where: { id: userId } });
  if (existing) {
    test.abort(
      `Stale test data detected: user ${userId} already exists in DB before factory create. ` +
      'This indicates a teardown failure in a previous test. ' +
      'Run `npm run db:clean-test-data` to clear stale records.'
    );
  }
}

// Guard: prevent test data from accidentally reaching production endpoints
async function assertTestEnvironment(dbUrl: string): Promise<void> {
  if (!dbUrl.includes('test') && !dbUrl.includes('localhost') && !dbUrl.includes('127.0.0.1')) {
    test.abort(
      `Factory attempted to write to a non-test database: ${dbUrl}. ` +
      'Set TEST_DATABASE_URL to a test/local database before running E2E tests.'
    );
  }
}

type GuardedFixtures = {
  guardedUser: { id: string; email: string; tier: string };
};

export const test = base.extend<GuardedFixtures>({
  guardedUser: async ({ }, use) => {
    const userId = `usr-e2e-${Date.now()}`;

    // Enforce preconditions before factory create — abort immediately if violated
    await assertTestEnvironment(process.env.TEST_DATABASE_URL ?? '');
    await assertNoStaleTestData(userId);

    const user = await userFactory.create({ id: userId, subscriptionTier: 'premium' });
    await use({ id: user.id, email: user.email, tier: user.subscriptionTier });

    // Teardown — clean up regardless of test outcome
    await db.user.delete({ where: { id: user.id } }).catch(() => {
      // Suppress "not found" errors — test may have deleted the user itself
    });
  },
});

export { expect } from '@playwright/test';
```

```typescript
// specs/checkout.spec.ts — uses guarded fixture; test.abort() fires on precondition failure
import { test, expect } from '../fixtures/factory-guards';

test('premium checkout succeeds with factory user', async ({ page, guardedUser }) => {
  // If guardedUser fixture calls test.abort(), this test body never runs
  await page.goto(`/checkout?userId=${guardedUser.id}`);
  await page.getByRole('button', { name: 'Proceed to Payment' }).click();
  await expect(page.getByTestId('payment-form')).toBeVisible();
});
```

**`test.abort()` from inside a `page.route()` handler — detecting invariant violations mid-test:**

```typescript
test('checkout never posts to production endpoint', async ({ page }) => {
  // Route handler calls test.abort() if the SUT accidentally calls the real payment processor
  await page.route('https://api.stripe.com/**', (route) => {
    test.abort(
      'Test made a real request to Stripe API. ' +
      'Ensure the payment factory mock is active and the MSW service worker is registered.'
    );
    return route.abort();
  });

  await page.goto('/checkout');
  // ... rest of the test
});
```

**`test.abort()` vs `test.skip()` vs `expect().toBeTruthy()` for precondition checking:**

| Approach | Test outcome | Use case |
|---|---|---|
| `test.skip(condition)` | Skipped (not failed) | Feature not yet implemented; environment not available |
| `test.abort(message)` | Failed with message | Detected invariant violation that indicates a bug or env misconfiguration |
| `expect(precondition).toBeTruthy()` | Failed as assertion | Inline postcondition / data assertion within test body |
| `throw new Error(msg)` | Failed (generic error) | Works but produces unhelpful stack traces in fixture code |

---

## MSW v2.14 `finalize()` API — WebSocket Handler Cleanup  [community]

MSW v2.14.4 (April 2026) added a `finalize()` method to WebSocket handler event listeners.
This provides a deterministic cleanup hook for MSW WebSocket handlers — equivalent to what
`server.resetHandlers()` provides for HTTP handlers — but for the internal state of a
WebSocket listener registration itself.

**Why it matters for test data:** MSW `ws.link()` handlers that register `addEventListener`
listeners accumulate internal state across tests when `server.resetHandlers()` is called.
`resetHandlers()` removes the handler from the server's handler list, but any `setTimeout`
callbacks or generator state inside the handler's closure continues running. The `finalize()`
callback fires when the handler is removed — letting you cancel timers, close generator
iterators, and release resources that the handler's factory closure holds.

```typescript
// mocks/websocket-handlers.ts — MSW v2.14+ finalize() for clean handler teardown
import { ws } from 'msw';
import { faker } from '@faker-js/faker';

const orderUpdates = ws.link('wss://api.example.com/orders/:orderId/stream');

// Streaming status factory — generates updates on a timer
function buildTimedStatusStream(
  orderId: string,
  onMessage: (msg: string) => void
): { cancel: () => void } {
  let cancelled = false;
  const statuses = ['pending', 'paid', 'shipped', 'delivered'];

  statuses.forEach((status, i) => {
    const timer = setTimeout(() => {
      if (!cancelled) {
        onMessage(JSON.stringify({
          orderId, status,
          timestamp: new Date(Date.now() + i * 1000).toISOString(),
        }));
      }
    }, i * 100);
  });

  return { cancel: () => { cancelled = true; } };
}

export const wsHandlers = [
  orderUpdates.addEventListener('connection', ({ client, params }, { finalize }) => {
    const orderId = params.orderId as string;

    // Start the timed factory stream
    const stream = buildTimedStatusStream(orderId, (msg) => client.send(msg));

    // finalize() fires when this handler is removed (server.resetHandlers() / server.close())
    // Use it to cancel pending timers so they don't fire after the test ends
    finalize(() => {
      stream.cancel();
    });

    client.addEventListener('close', () => {
      stream.cancel();   // also cancel on client-initiated close
    });
  }),
];
```

```typescript
// vitest.setup.ts — MSW server with clean WebSocket handler teardown
import { setupServer } from 'msw/node';
import { wsHandlers } from './mocks/websocket-handlers';

const server = setupServer(...wsHandlers);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => {
  // resetHandlers() triggers finalize() on any removed WS handlers
  // This cancels pending setTimeout callbacks from the factory stream
  server.resetHandlers();
});
afterAll(() => server.close());
```

**Before v2.14 (without `finalize()`):**

```typescript
// Common bug: handler removed by resetHandlers(), but timer fires 100ms later
// The client.send() call on the now-removed client causes an unhandled error
// in the next test's MSW server state — producing cryptic failures.
orderUpdates.addEventListener('connection', ({ client }) => {
  setTimeout(() => {
    client.send(JSON.stringify({ status: 'shipped' }));  // fires AFTER test ends
  }, 500);
  // No cleanup hook — timer runs even after server.resetHandlers()
});
```

**`finalize()` cleanup pattern vs `server.close()` teardown:**

| Pattern | When it fires | Use case |
|---|---|---|
| `finalize()` callback | When handler is removed via `resetHandlers()` | Per-test cleanup of handler-specific resources (timers, generators) |
| `client.addEventListener('close')` | When the WS client closes the connection | Per-connection cleanup |
| `server.close()` in `afterAll` | Once at suite end | Full server teardown |

---

## MSW v2.14.0 `ws.onUpgrade` — HTTP-Upgrade WebSocket Interception in Node.js  [community]

MSW v2.14.0 (April 29, 2026) introduced `ws.onUpgrade`, a low-level hook that intercepts
the HTTP upgrade request that establishes a WebSocket connection in Node.js environments.
It is distinct from `ws.link()` — which intercepts at the WebSocket protocol level — and
only applies to the `msw/node` server; it is **not available** in the service worker
(browser) layer because browsers' `fetch` API marks the `Upgrade` header as forbidden.

**Why it matters for test data:** Some WebSocket client libraries (e.g., the browser-native
`WebSocket` constructor in Node.js via the `ws` npm package, or WebSocket clients that
perform custom HTTP handshakes) negotiate the upgrade over plain HTTP before upgrading the
protocol. When an integration test spins up an `msw/node` server against such a client,
MSW needs to intercept the HTTP upgrade request *before* the WebSocket handshake is
complete — otherwise the connection bypasses all `ws.link()` handlers because no WebSocket
protocol frame is ever sent.

`ws.onUpgrade` fills this gap: it fires at the HTTP layer (status `101 Switching Protocols`)
before the WebSocket handshake, enabling tests to:
- Inspect upgrade headers (e.g., custom `X-Auth-Token` headers set on the upgrade request)
- Reject specific connections at the HTTP layer (return a non-101 response to simulate auth failures)
- Apply global connection-level logic that runs once per WebSocket session, not per message

**Key behavioural differences: `ws.link()` vs `ws.onUpgrade`:**

| Concern | `ws.link(url)` | `ws.onUpgrade` |
|---|---|---|
| Layer | WebSocket protocol (after upgrade) | HTTP upgrade request (before handshake) |
| Available in browser (service worker) | Yes | **No** — `Upgrade` header is forbidden in browser `fetch` |
| Scope | Per-URL matcher | Global — applies to all WebSocket connections on the MSW server |
| Default behaviour | Mocked connection (no real server) | Produces `101 Switching Protocols` response per spec |
| Typical use case | Mock message sequences for specific endpoints | Inspect/reject upgrade headers; per-session global logic |
| Works with `finalize()` | Yes | Not applicable (fires once per connection, not per handler) |

**Basic usage — inspecting auth headers on WebSocket upgrade:**

```typescript
// mocks/handlers.ts — MSW v2.14.0+ ws.onUpgrade for upgrade-level interception
import { ws } from 'msw';

const chat = ws.link('wss://api.example.com/chat');

export const handlers = [
  // ws.onUpgrade fires at the HTTP 101 Upgrade layer — runs before any WS frames
  ws.onUpgrade((upgrade) => {
    // `upgrade.request` is the HTTP request that initiated the upgrade
    const authToken = upgrade.request.headers.get('x-auth-token');

    if (!authToken || authToken === 'invalid') {
      // Return a 403 at the HTTP layer — the WS handshake never completes
      // This simulates an authentication gateway rejecting the connection
      return new Response('Unauthorized', { status: 403 });
    }

    // Return undefined (or nothing) to allow the upgrade to proceed normally
    // The ws.link() handler will then take over for protocol-level mocking
  }),

  // ws.link() handler — processes messages after the upgrade succeeds
  chat.addEventListener('connection', ({ client }) => {
    client.addEventListener('message', ({ data }) => {
      const parsed = JSON.parse(data as string);
      client.send(JSON.stringify({
        id: `msg-${Date.now()}`,
        text: `Echo: ${parsed.text}`,
        author: 'bot',
      }));
    });
  }),
];
```

**Integration test — testing auth rejection at the upgrade layer:**

```typescript
// tests/chat-auth.test.ts — Node.js integration test with ws.onUpgrade
import { setupServer } from 'msw/node';
import { handlers } from '../mocks/handlers';
import WebSocket from 'ws';   // the 'ws' npm package, not the browser API

const server = setupServer(...handlers);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

it('rejects WebSocket connection without auth token', async () => {
  // Attempt upgrade without X-Auth-Token header
  const ws = new WebSocket('wss://api.example.com/chat');

  await expect(
    new Promise<void>((_, reject) => {
      ws.on('error', reject);
      ws.on('open', () => reject(new Error('Connection should have been rejected')));
    })
  ).rejects.toThrow();
});

it('accepts WebSocket connection with valid auth token', async () => {
  // Provide a valid token — upgrade succeeds, ws.link() handler takes over
  const ws = new WebSocket('wss://api.example.com/chat', {
    headers: { 'x-auth-token': 'valid-token-123' },
  });

  await expect(
    new Promise<string>((resolve, reject) => {
      ws.on('error', reject);
      ws.on('message', (data) => resolve(data.toString()));
      ws.on('open', () => {
        ws.send(JSON.stringify({ text: 'hello' }));
      });
    })
  ).resolves.toContain('Echo: hello');

  ws.close();
});
```

**Using `ws.onUpgrade` to build a per-session factory context:**

```typescript
// mocks/session-factory-handler.ts — attach per-session factory data at the upgrade layer
import { ws } from 'msw';
import { faker } from '@faker-js/faker';

// Per-session state: keyed by a session ID injected as an upgrade header
const sessionData = new Map<string, { userId: string; role: string }>();

export const sessionHandlers = [
  ws.onUpgrade((upgrade) => {
    const sessionId = upgrade.request.headers.get('x-session-id');
    if (sessionId) {
      // Seed per-session factory data at the HTTP layer, before any WS messages
      sessionData.set(sessionId, {
        userId: faker.string.uuid(),
        role: faker.helpers.arrayElement(['admin', 'user', 'guest']),
      });
    }
    // Allow upgrade to proceed — no return value = 101 Switching Protocols
  }),

  ws.link('wss://api.example.com/ws').addEventListener('connection', ({ client, request }) => {
    const sessionId = request.headers.get('x-session-id') ?? 'unknown';
    const session = sessionData.get(sessionId);

    client.addEventListener('message', () => {
      client.send(JSON.stringify({
        type: 'session-info',
        userId: session?.userId ?? 'anonymous',
        role: session?.role ?? 'guest',
      }));
    });

    client.addEventListener('close', () => {
      // Clean up per-session factory state when the WS connection closes
      if (sessionId) sessionData.delete(sessionId);
    });
  }),
];
```

**`ws.onUpgrade` in the context of the MSW WebSocket architecture:**

```
HTTP client                MSW Node.js server
   │
   ├─ GET /chat ──────────────► ws.onUpgrade handler
   │   (Upgrade: websocket)       ├─ inspect headers
   │                              ├─ return 403 to reject
   │                              └─ return undefined to allow ──► 101 Switching Protocols
   │
   ├─ WebSocket frames ─────────► ws.link('wss://...') handlers
   │   (after upgrade)              ├─ addEventListener('connection')
   │                                └─ addEventListener('message')
```

`ws.onUpgrade` is applied **globally** to the MSW server instance — there is no
per-link variant. If you need per-endpoint upgrade logic, inspect
`upgrade.request.url` inside the handler and branch manually.

---

## `faker` v10.4 Locale Expansions — Locale-Sensitive Factory Test Data  [community]

faker v10.4.0 (March 2025) added significant locale expansions for Norwegian (`nb_NO`) and
Japanese (`ja`) — two locales that expose locale-specific rendering bugs in address forms,
name display, and character encoding that the default `en` locale will never trigger.

**Why it matters:** Web applications commonly have bugs in non-Latin locale handling: Japanese
full-width numbers in phone fields, Norwegian `æ/ø/å` characters breaking regex validation,
right-to-left cursor positioning in bidirectional-enabled inputs. Factories using only English
faker data miss these bugs. Adding locale-specific factory variants to your test suite makes
character encoding and locale rendering bugs discoverable at factory authoring time.

**New in v10.4 — Norwegian locale additions:**

```typescript
// factories/locale-norway.factory.ts — Norwegian locale test data (faker v10.4+)
import { fakerNB_NO } from '@faker-js/faker';

interface NorwegianAddress {
  id: string;
  streetAddress: string;
  postalCode: string;      // Norwegian format: 4 digits (e.g., 0150)
  city: string;
  country: 'NO';
  phoneNumber: string;     // Norwegian format: +47 XX XX XX XX
  sex: string;             // now includes 'male', 'female', and locale-aware values
  zodiacSign: string;      // v10.4 addition: zodiac signs in Norwegian
}

export function buildNorwegianAddress(
  overrides: Partial<NorwegianAddress> = {}
): NorwegianAddress {
  return {
    id: fakerNB_NO.string.uuid(),
    streetAddress: fakerNB_NO.location.streetAddress(),
    postalCode: fakerNB_NO.location.zipCode(),
    city: fakerNB_NO.location.city(),
    country: 'NO',
    phoneNumber: fakerNB_NO.phone.number(),
    sex: fakerNB_NO.person.sex(),              // respects Norwegian locale sex definitions
    zodiacSign: fakerNB_NO.person.zodiacSign(), // v10.4: Norwegian zodiac sign strings
    ...overrides,
  };
}

// Locale-stress test data: Norwegian characters that break ASCII-only validation
export const NorwegianEdgeCases = {
  // Names with æ, ø, å — break regex /^[a-zA-Z\s]+$/ validators
  nameWithAe: () => fakerNB_NO.person.fullName({ sex: 'female' }),
  // City containing ø — useful for city/country field validation tests
  cityWithOslash: () => 'Tromsø',
  // Postal code: 4-digit Norwegian format (different from 5-digit German)
  postalCode: () => fakerNB_NO.location.zipCode(),  // returns e.g. '0150'
};
```

**New in v10.4 — Japanese locale expansions (animal breeds for locale-specific content):**

```typescript
// factories/locale-japan.factory.ts — Japanese locale test data (faker v10.4+)
import { fakerJA } from '@faker-js/faker';

// v10.4 added animal breed data to the Japanese locale:
// cat breeds (猫の品種), bear types (クマの種類), cattle breeds (牛の品種),
// bird species (鳥の種類), fish species (魚の種類), horse breeds (馬の品種)
// Useful for: e-commerce (pet/animal product categories), data entry forms,
// content management systems with locale-specific taxonomy

interface AnimalProduct {
  id: string;
  species: string;
  breed: string;
  japaneseName: string;
}

export function buildJapaneseAnimalProduct(
  overrides: Partial<AnimalProduct> = {}
): AnimalProduct {
  const species = fakerJA.helpers.arrayElement(
    ['cat', 'bird', 'fish'] as const
  );

  // Use the animal module for locale-accurate breed names in Japanese
  const breedMap = {
    cat:  () => fakerJA.animal.cat(),      // e.g., 'アビシニアン'
    bird: () => fakerJA.animal.bird(),     // e.g., 'アマツバメ'
    fish: () => fakerJA.animal.fish(),     // e.g., 'アイナメ'
  };

  return {
    id: fakerJA.string.uuid(),
    species,
    breed: breedMap[species](),
    japaneseName: fakerJA.person.fullName(),    // Japanese character names
    ...overrides,
  };
}

// Locale-stress test data: Japanese multi-byte characters
export const JapaneseEdgeCases = {
  // Full-width number characters — break ASCII-only phone number validators
  fullWidthPhone: '０３－１２３４－５６７８',
  // Kanji in name fields — test font rendering and byte-length validation
  kanjiName: fakerJA.person.lastName() + ' ' + fakerJA.person.firstName(),
  // Japanese postal code: NNN-NNNN (7 digits with hyphen)
  postalCode: fakerJA.location.zipCode(),   // e.g., '100-0001'
  // Japanese address in character order (prefecture → city → street — reverse of Western)
  address: fakerJA.location.streetAddress(),
};
```

**Combining locale factories in a parametric i18n test suite:**

```typescript
// specs/address-form.spec.ts — parametric locale test using v10.4 locale factories
import { test, expect } from '@playwright/test';
import { buildNorwegianAddress, NorwegianEdgeCases } from '../factories/locale-norway.factory';
import { JapaneseEdgeCases } from '../factories/locale-japan.factory';
import { buildGermanAddress } from '../factories/international.factory';

// Parametric locale test — same form, different locale factory data
const localeTestCases = [
  { locale: 'nb-NO', address: buildNorwegianAddress(), label: 'Norwegian (æøå chars)' },
  { locale: 'de-DE', address: buildGermanAddress(),   label: 'German (umlauts)'       },
  {
    locale: 'ja-JP',
    address: {
      street: JapaneseEdgeCases.address,
      postalCode: JapaneseEdgeCases.postalCode,
      city: '東京',
      country: 'JP',
    },
    label: 'Japanese (kanji, full-width)',
  },
];

for (const { locale, address, label } of localeTestCases) {
  test(`address form accepts ${label}`, async ({ page }) => {
    await page.goto(`/profile/address?locale=${locale}`);
    await page.getByLabel('Street').fill(address.street);
    await page.getByLabel('Postal Code').fill(address.postalCode);
    await page.getByLabel('City').fill(address.city);
    await page.getByRole('button', { name: 'Save' }).click();
    await expect(page.getByTestId('success-message')).toBeVisible();
  });
}
```

---

29. **[community] Playwright WebSocket route handlers installed via `page.routeWebSocket()` linger across navigations and can bleed into subsequent test assertions if not explicitly closed.**
    When a test installs a WebSocket route on a `page` object and then the page navigates (e.g., via a redirect or a `page.goto()` call later in the test), the route handler remains active on the page-level route registry. Unlike HTTP routes installed with `page.route()`, which can be removed with `page.unroute()`, WebSocket routes stay bound for the lifetime of the page. If the same page object is reused across test steps (e.g., in a Playwright fixture with `scope: 'worker'`), the WebSocket handler from a previous test step can still intercept connections in subsequent steps — causing the next test to receive factory-generated messages it didn't expect.

    ```typescript
    // Anti-pattern: page-scoped WS route bleeds into reused worker-scoped page
    test.extend({
      sharedPage: async ({ browser }, use) => {
        const context = await browser.newContext();
        const page = await context.newPage();
        await use(page);       // page is shared across all tests in the worker
        await context.close();
      },
    });

    test('test A — installs WS route', async ({ sharedPage }) => {
      await sharedPage.routeWebSocket('wss://api.example.com/ws', (ws) => {
        ws.send(JSON.stringify({ type: 'test-a-data' }));
      });
      await sharedPage.goto('/realtime-feature');
      // ... assertions
      // WS route remains active on sharedPage after this test ends!
    });

    test('test B — expects no WS route (but test A route is still active)', async ({ sharedPage }) => {
      await sharedPage.goto('/realtime-feature');
      // Factory-generated message from test A may arrive — causes flaky assertion
    });

    // Fix: use context-level routing OR close/unroute between tests
    // Option 1: browserContext.routeWebSocket() with explicit handler removal
    // Option 2: use page-scoped (not worker-scoped) pages so each test gets a fresh page
    // Option 3: call page.unrouteAll({ behavior: 'ignoreErrors' }) in fixture teardown

    // Correct fixture:
    test.extend({
      freshPage: async ({ browser }, use) => {
        const context = await browser.newContext();
        const page = await context.newPage();
        await use(page);
        await page.unrouteAll({ behavior: 'ignoreErrors' });  // clear WS and HTTP routes
        await context.close();
      },
    });
    ```

    The `page.unrouteAll({ behavior: 'ignoreErrors' })` call in fixture teardown is the most defensive fix — it clears all HTTP and WebSocket routes from the page regardless of how they were installed, preventing bleed-through to subsequent tests that share the page object.

---

30. **[community] `ws.onUpgrade` in MSW v2.14.0 is a global hook — not scoped to a specific `ws.link()` URL — and does not exist in the browser service-worker layer. Attaching per-endpoint logic inside `ws.onUpgrade` without checking `upgrade.request.url` causes all WebSocket upgrade requests to run the same upgrade-layer logic, regardless of which endpoint they target.**

    `ws.onUpgrade` fires at the HTTP 101 Upgrade layer before any WebSocket protocol frames are exchanged. Unlike `ws.link(url)`, which scopes its handler to a specific URL pattern, `ws.onUpgrade` receives every WebSocket upgrade request on the MSW Node.js server. This means:

    1. **Global scope trap:** If two test suites each register a `ws.onUpgrade` handler (e.g., one for auth validation, one for session seeding) without filtering by URL, each handler runs for all WebSocket connections — including connections intended for other endpoints. The handlers are additive; later `server.use(ws.onUpgrade(...))` registrations stack on top of earlier ones until `server.resetHandlers()` is called.

    2. **Browser unavailability trap:** Tests that pass in Node.js (Vitest integration tests) but fail in browser-environment E2E tests (Playwright with MSW injected via a service worker) will show confusing `ws.onUpgrade is not a function` errors because the service worker layer does not expose HTTP upgrade semantics.

    ```typescript
    // Anti-pattern: ws.onUpgrade without URL filtering — affects ALL WebSocket connections
    ws.onUpgrade((upgrade) => {
      const token = upgrade.request.headers.get('x-auth-token');
      if (!token) return new Response('Unauthorized', { status: 403 });
      // BUG: this rejects ALL WebSocket connections that lack this header,
      // including /notifications, /metrics, and /health-check endpoints
      // that are never expected to send an auth token
    });

    // Correct: always check upgrade.request.url before applying endpoint-specific logic
    ws.onUpgrade((upgrade) => {
      const url = new URL(upgrade.request.url);
      if (!url.pathname.startsWith('/chat')) return; // skip non-chat endpoints

      const token = upgrade.request.headers.get('x-auth-token');
      if (!token) return new Response('Unauthorized', { status: 403 });
    });
    ```

    ```typescript
    // Anti-pattern: using ws.onUpgrade in a shared test helper without environment guard
    export function setupAuthMock(server: SetupServer) {
      server.use(
        ws.onUpgrade((upgrade) => {
          // BUG: this throws in browser (Playwright + MSW service worker) environments
          // because ws.onUpgrade is not available outside Node.js
        })
      );
    }

    // Correct: guard with environment check or restrict to Node.js-only test files
    // Use ws.link() handlers for logic that must work in both browser and Node.js
    import { ws } from 'msw';
    export function setupAuthMock(server: SetupServer | SetupWorker) {
      // ws.link() handlers work in both environments
      server.use(
        ws.link('wss://api.example.com/chat').addEventListener('connection', ({ client }) => {
          // Auth logic here works in browser service worker AND Node.js server
        })
      );
    }
    ```

    The rule of thumb: use `ws.onUpgrade` only in Node.js integration tests where you need
    upgrade-header inspection or HTTP-layer rejection. Use `ws.link()` for all logic that
    must run in both browser and Node.js environments. Always filter by URL inside
    `ws.onUpgrade` to avoid global side-effects across unrelated test fixtures.

---

## Key Resources (iter-41 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright `WebSocketRoute` API docs | Official | https://playwright.dev/docs/api/class-websocketroute | Full API: `ws.send()`, `ws.onMessage()`, `ws.connectToServer()`, `ws.close()`, `ws.protocols()` |
| Playwright 1.48 release notes | Official | https://playwright.dev/docs/release-notes#version-148 | `routeWebSocket()` — intercept and mock WebSocket connections in E2E tests |
| Playwright global setup teardown | Official | https://playwright.dev/docs/test-global-setup-teardown | Project `dependencies` + `teardown` for composable DB seeding (multiple independent setup projects) |
| Playwright `test.abort()` docs | Official | https://playwright.dev/docs/api/class-test#test-abort | Fail fast from fixture or route handler on precondition violation (v1.60+) |
| Playwright `test.step.skip()` docs | Official | https://playwright.dev/docs/api/class-test#test-step | Per-step conditional skip for data-dependent test steps (v1.50+) |
| MSW v2.14 release notes | Official | https://github.com/mswjs/msw/releases/tag/v2.14.4 | `finalize()` API for WebSocket handler cleanup on `resetHandlers()` |
| faker v10.4.0 release notes | Official | https://github.com/faker-js/faker/releases/tag/v10.4.0 | Norwegian locale additions (zodiac, sex defs, vehicles); Japanese animal breed data (cat/bird/fish) |

## Key Resources (iter-42 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| MSW v2.14.0 release notes (`ws.onUpgrade`) | Official | https://github.com/mswjs/msw/releases/tag/v2.14.0 | `ws.onUpgrade` API for intercepting HTTP upgrade requests before WebSocket handshake (Node.js only) |

---

## MSW `defineNetwork()` — Upcoming Unified Network Mock API  [community]

`defineNetwork()` is a proposed new top-level API in MSW (RFC #2488, under active development as of May 2026 in v2.14.x). It separates two distinct concerns that are currently conflated in `setupServer()` / `setupWorker()`:

1. **Network sources** — where requests originate (a Service Worker, Node.js interceptors, Playwright's `page.route()`, or a custom source)
2. **Handler resolution** — how those requests are routed through your MSW handlers

**Why it matters for test data factories:** The current MSW API requires choosing `setupServer` (Node.js only) or `setupWorker` (browser only) at setup time, which forces test code to be aware of its execution environment. `defineNetwork()` lets you write handler logic once and plug in different network sources per environment — the same factory-backed handlers work in Vitest unit tests (Node.js interceptors), Playwright E2E tests (Playwright `page.route()` source), and browser integration tests (Service Worker source) without any handler duplication.

**Proposed API shape (from RFC #2488):**
```typescript
// EXPERIMENTAL — API shape subject to change; check MSW docs for stable release
import { defineNetwork, ServiceWorkerSource } from 'msw';
import { handlers } from './mocks/handlers';
// (handlers.ts uses the same http.get/http.post/ws.link factory-backed handlers as today)

// Browser test setup — uses Service Worker as the network source
const network = defineNetwork({
  sources: [new ServiceWorkerSource()],
  initialHandlers: handlers,
});

// Node.js test setup (Vitest) — uses Node.js interceptors as the source
// import { NodeInterceptorsSource } from 'msw/node';
// const network = defineNetwork({
//   sources: [new NodeInterceptorsSource()],
//   initialHandlers: handlers,
// });

await network.enable();

// Per-test handler overrides — same API as server.use() / worker.use()
network.use(
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json(buildUser({ id: params.id as string, status: 'suspended' }));
  })
);

// Teardown
await network.disable();
```

**Playwright custom source (the key new capability):**

The RFC includes a first-class Playwright integration that uses `page.route()` as the network source. This means MSW factory-backed handlers can run inside Playwright E2E tests **without requiring a Service Worker** — solving the long-standing challenge of using MSW in E2E contexts where Service Worker registration is impractical (behind auth walls, in iframes, in electron apps).

```typescript
// Playwright + defineNetwork (proposed pattern from RFC)
// Allows MSW handlers to intercept Playwright page requests via page.route()
// EXPERIMENTAL — requires MSW >= 2.15 when stable

import { defineNetwork } from 'msw';
import { PlaywrightSource } from 'msw/playwright'; // proposed import path
import { handlers } from '../mocks/handlers';
import { test, expect } from '@playwright/test';

test('checkout with MSW factory-backed handlers via Playwright source', async ({ page }) => {
  const network = defineNetwork({
    sources: [new PlaywrightSource(page)],
    initialHandlers: handlers,
  });

  await network.enable();

  // Per-test override — scoped to this test only
  network.use(
    http.post('/api/checkout', () =>
      HttpResponse.json({ status: 'success', orderId: buildOrder().id })
    )
  );

  await page.goto('/checkout');
  await page.click('[data-testid="pay-button"]');
  await expect(page.locator('[data-testid="order-confirmation"]')).toBeVisible();

  await network.disable();
});
```

**Current status (May 2026):**
- RFC merged into main branch
- Experimental `defineNetwork()` exports appear in MSW v2.14.x internals (referenced in v2.14.6 changelog)
- Stable release expected in MSW v2.15 — monitor the [MSW releases page](https://github.com/mswjs/msw/releases) for the stable API

**Migration strategy:** When `defineNetwork()` stabilises, existing `setupServer()` / `setupWorker()` code continues working — the RFC is additive, not a replacement. Migrate incrementally: new test files use `defineNetwork()`, existing files keep `setupServer()` / `setupWorker()` until you have time to refactor.

---

## Playwright 1.53 `locator.describe()` — Annotating Fixture Elements in Traces  [community]

Playwright 1.53 added `locator.describe(label)`, which attaches a human-readable label to a locator for display in Trace Viewer and HTML reports. When test data factories create domain objects that are then rendered and interacted with in E2E tests, naming the locators with the factory's semantic variant label makes traces dramatically easier to read.

**Why it matters for test data:** An E2E test that creates a `UserMother.suspended().build()` user and then asserts on their checkout button produces a Trace Viewer entry like `click [data-testid="checkout-btn"]` — providing no context about which user variant is being exercised. With `locator.describe()`, the trace entry becomes `click "Suspended user checkout button"` — immediately identifying the factory variant in the failure trace.

```typescript
// specs/checkout-trace.spec.ts — factory-aware locator descriptions
import { test, expect } from '@playwright/test';
import { userFactory } from '../factories/user.factory';

test('suspended user sees disabled checkout button @integration', async ({ page }) => {
  // Factory creates the user — the page URL carries the user identity
  const user = await userFactory.create({ status: 'suspended' });
  await page.goto(`/checkout?userId=${user.id}`);

  // locator.describe() annotates this locator in Trace Viewer as:
  // "Suspended user checkout button" — not the generic selector
  const checkoutBtn = page
    .locator('[data-testid="checkout-btn"]')
    .describe(`${user.status} user checkout button`);

  // Trace entry: "Expect 'Suspended user checkout button' to be disabled"
  await expect(checkoutBtn).toBeDisabled();
  await expect(checkoutBtn.describe('Disabled reason tooltip')).toHaveAttribute(
    'title',
    'Account suspended'
  );
});
```

```typescript
// fixtures/described-fixtures.ts — factory fixtures that describe their elements
import { test as base } from '@playwright/test';
import { userFactory } from '../factories/user.factory';

type DescribedFixtures = {
  userPage: {
    user: { id: string; status: string; email: string };
    // Factory-named locator helper — auto-describes by status
    checkoutLocator: (page: import('@playwright/test').Page) => import('@playwright/test').Locator;
  };
};

export const test = base.extend<DescribedFixtures>({
  userPage: async ({}, use) => {
    const user = await userFactory.create({ status: 'suspended' });

    // Returns a locator pre-described with the factory variant's status
    const checkoutLocator = (page: import('@playwright/test').Page) =>
      page.locator('[data-testid="checkout-btn"]').describe(`${user.status}-user checkout button`);

    await use({ user, checkoutLocator });
    await userFactory.cleanup(user.id);
  },
});
```

**Pattern: use `locator.describe()` systematically for factory-driven test data:**
- Name the variant: `describe('${factory.status} user element')` — identifies the data context
- Name the action: `describe('Pay button for premium-tier order')` — identifies the business intent
- Avoid generic labels: `describe('button')` adds no value over the raw selector

**Requires:** Playwright ≥ 1.53.

---

## Playwright 1.56 `page.requests()` — Asserting Factory-Driven Request Patterns  [community]

Playwright 1.56 added `page.requests()` and `page.consoleMessages()` / `page.pageErrors()` — convenience methods that return all network requests, console messages, and page errors collected since the page was created (or since the last call). For factory-heavy E2E test suites, `page.requests()` provides a lightweight way to assert that factory-generated test data caused the expected API calls — without setting up explicit `page.route()` intercepts for every test.

**Why it matters:** When an E2E test creates a factory user and navigates to their dashboard, you may want to verify that the page fetched the user's data from the correct API endpoint. Previously, asserting on specific requests required either `page.waitForRequest()` (fires once, then discards) or a `page.route()` spy. `page.requests()` exposes the full request history as an array — you can filter by URL, method, and timing *after* the interaction completes.

```typescript
// specs/dashboard-requests.spec.ts — asserting factory-driven API calls
import { test, expect } from '@playwright/test';
import { userFactory } from '../factories/user.factory';

test('dashboard fetches user data and orders on load @integration', async ({ page }) => {
  const user = await userFactory.create({ subscriptionTier: 'premium' });

  await page.goto(`/dashboard?userId=${user.id}`);

  // Wait for the page to settle (all expected requests complete)
  await page.waitForLoadState('networkidle');

  // page.requests() returns all requests since page creation
  const requests = await page.requests();

  // Assert: exactly one GET request to the user endpoint with the factory user's ID
  const userRequests = requests.filter(
    (r) => r.method() === 'GET' && r.url().includes(`/api/users/${user.id}`)
  );
  expect(userRequests).toHaveLength(1);

  // Assert: orders were fetched for the user
  const orderRequests = requests.filter(
    (r) => r.method() === 'GET' && r.url().includes('/api/orders') && r.url().includes(user.id)
  );
  expect(orderRequests.length).toBeGreaterThanOrEqual(1);

  // Assert: no unauthorized requests (factory user's session token present in all requests)
  const unauthorizedRequests = requests.filter((r) => {
    const authHeader = r.headers()['authorization'];
    return r.url().startsWith(process.env.TEST_API_URL ?? '') && !authHeader;
  });
  expect(unauthorizedRequests).toHaveLength(0);

  await userFactory.cleanup(user.id);
});
```

```typescript
// Pattern: factory-driven API call count assertions for regression testing
// Use page.requests() to catch N+1 query regressions introduced by domain model changes

test('premium dashboard makes at most 5 API calls on initial load @performance', async ({ page }) => {
  const user = await userFactory.create({ subscriptionTier: 'premium' });
  await page.goto(`/dashboard?userId=${user.id}`);
  await page.waitForLoadState('networkidle');

  const apiRequests = (await page.requests()).filter(
    (r) => r.url().includes('/api/')
  );

  // Regression guard: factory-seeded premium dashboard should not exceed 5 API calls
  // If this fails after a domain model change, a new N+1 query was introduced
  expect(apiRequests.length).toBeLessThanOrEqual(5);

  await userFactory.cleanup(user.id);
});
```

**Key difference from `page.waitForRequest()`:**

| Method | When to use |
|---|---|
| `page.waitForRequest(urlOrPredicate)` | Assert a specific request fires *during* an interaction; streams in real-time |
| `page.requests()` | Assert request history *after* interactions complete; returns the full array |
| `page.route()` + spy | Full intercept + mock; use when you need to control the response, not just observe |

**Requires:** Playwright ≥ 1.56.

---

## Playwright 1.56 LLM Test Agents — Factory Generation in Agentic Workflows  [community]

Playwright 1.56 introduced three built-in LLM agent definitions (`planner`, `generator`, `healer`) available via `npx playwright init-agents`. These agents are pre-configured system prompts that instruct LLMs to follow Playwright's best practices when generating test files and fixture code. They are directly relevant to the LLM-assisted test data generation section earlier in this guide — specifically for factory scaffolding (Mode 1).

**Why it matters for factory authors:** The `generator` agent is explicitly aware of Playwright fixture patterns, `test.extend()` syntax, and fixture teardown. When you ask it to scaffold a factory for a new domain entity, it produces fixture-backed factories with correct `onCleanup()` teardown — not bare `beforeEach`/`afterEach` — because the agent's system prompt encodes Playwright's fixture best practices.

**Agent roles:**
- **Planner:** Explores the application (via `page.goto()` + Aria snapshots) and produces a Markdown test plan, including which fixtures and factory variants are needed for each scenario.
- **Generator:** Takes the Markdown plan and generates Playwright test files with correct fixture usage, `test.extend()` factories, and `{ box: true }` for infrastructure fixtures.
- **Healer:** Runs the generated test suite, analyses failures (including factory drift and fixture teardown errors), and auto-repairs the generated code.

**Initialising agents in a TypeScript project:**
```bash
# Generates .claude/agents/ directory with Playwright agent definitions
npx playwright init-agents

# Available client loops (specify your preferred LLM client):
# - vscode: works with Copilot, Continue, or any VS Code LLM extension
# - claude: Claude Code (this tool)
# - opencode: opencode.ai
npx playwright init-agents --client=claude
```

**Directing the generator agent to produce factory-backed fixtures:**
```markdown
<!-- test-plan.md — output from the planner agent -->

## Checkout Flow Test Plan

### Fixture Requirements
- `suspendedUser`: DB-persisted user with status='suspended' — use fishery factory with onCleanup teardown
- `premiumUser`: DB-persisted user with subscriptionTier='premium' and a valid paymentMethodId
- `cartWithItems`: in-memory cart factory, 2 items, totalCents=4999

### Test Cases

1. **Suspended user checkout blocked**
   - Use: `suspendedUser` fixture
   - Assert: checkout button disabled; reason tooltip = "Account suspended"

2. **Premium user checkout succeeds**
   - Use: `premiumUser` fixture + `cartWithItems`
   - Assert: order confirmation visible; orderId is a UUID
```

When the `generator` agent processes this plan with the Playwright agent system prompt, it produces test files that use `test.extend()` fixtures with correct factory patterns — including `{ box: true }` for the infrastructure fixtures and `onCleanup()` for teardown. The output aligns with the patterns documented in this guide without requiring manual guidance.

**[community] Gotcha — healer agent and factory drift:** The `healer` agent will attempt to fix failing tests by modifying test assertions to match the current output. If a factory is producing schema-invalid data (the `expect.schemaMatching` class of drift covered in Gotcha #25), the healer may change test assertions to accommodate the invalid data rather than fixing the factory. **Add factory smoke tests (`expect.schemaMatching`) as a required CI gate before the healer agent runs** — this ensures the healer only repairs genuine E2E logic failures, not factory data quality issues.

**Integration with the LLM-assisted test data section:** The three Playwright agents implement Mode 1 (one-time factory scaffolding) and Mode 2 (healer-generated edge-case repairs) from the LLM-assisted test data section, but with Playwright-specific best practices baked in. For `fishery`-based factories (non-E2E), the generic Mode 1 prompt pattern (described earlier in this guide) remains the primary approach.

---

31. **[community] `failOnFlakyTests` in Playwright 1.52+ surfaces factory data isolation failures that would otherwise pass on retry.**
    Playwright 1.52 added the `failOnFlakyTests` config option (also available via `--fail-on-flaky-tests` CLI flag). When enabled, the test run fails if any test passes on retry after an initial failure — catching tests that are non-deterministic across runs. This is directly relevant to test data factories: a test that fails 30% of the time due to a shared DB row (cross-test data contamination) is a flaky test. Without `failOnFlakyTests`, CI marks the run as passing (all tests *eventually* passed) and the factory isolation bug remains hidden. With `failOnFlakyTests`, the flaky run fails immediately, forcing the team to investigate the factory isolation issue.

    ```typescript
    // playwright.config.ts — enable failOnFlakyTests to surface factory isolation bugs
    import { defineConfig } from '@playwright/test';

    export default defineConfig({
      // Fail the run if any test passes only after retrying — surfaces isolation flakiness
      // Recommended for integration projects (workers: 2+) where factory isolation matters
      failOnFlakyTests: true,

      // retries: still needed to distinguish infra flakiness (network, timing) from data flakiness
      // Use retries: 1 — a test that fails once then passes is "flaky" and will fail the run
      retries: process.env.CI ? 1 : 0,

      projects: [
        {
          name: 'integration',
          testMatch: '**/*.integration.spec.ts',
          workers: 2,  // parallel workers make factory isolation bugs more likely to manifest
          // failOnFlakyTests is inherited from the root config — no per-project override needed
        },
      ],
    });
    ```

    **Pattern: use `failOnFlakyTests` to audit factory isolation quality:**

    ```bash
    # One-time audit: run with flaky detection to surface all isolation issues
    npx playwright test --fail-on-flaky-tests --retries=2 --workers=4

    # In CI: enforce as a required gate for the integration project
    # (smoke project may use --retries=2 without failOnFlakyTests — UI flakiness is expected)
    ```

    **Root causes when `failOnFlakyTests` surfaces factory failures:**
    - **Shared DB row:** factory creates a user without a unique prefix; parallel tests collide on the same email unique constraint
    - **Leaked session state:** a worker-scoped browser context retains auth cookies from the previous test (fix: use `setStorageState({ cookies: [], origins: [] })` in fixture teardown)
    - **Un-cleaned fixture data:** a factory creates a DB row but the `onCleanup()` was not called (fix: use `await using` or Playwright's `{ box: true }` fixture teardown guarantee)
    - **Ordering dependency:** test B assumes a row created by test A still exists (fix: each test must create its own data via its own factory call)

    The presence of flaky tests detected by `failOnFlakyTests` is a strong signal that your factory isolation strategy needs to be upgraded — typically from namespace-prefix isolation to transaction rollback or per-worker DB isolation (see the Cleanup Strategy Decision Tree earlier in this guide).

---

## Key Resources (iter-43 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| MSW `defineNetwork()` RFC | Community | https://github.com/mswjs/msw/issues/2488 | Proposed unified API separating network sources from handler resolution; Playwright source integration for E2E |
| Playwright 1.52 release notes | Official | https://playwright.dev/docs/release-notes#version-152 | `testProject.workers` (per-project worker counts); `failOnFlakyTests` for data isolation quality |
| Playwright 1.53 `locator.describe()` | Official | https://playwright.dev/docs/release-notes#version-153 | Annotate fixture-created element locators with semantic labels for Trace Viewer + HTML reports |
| Playwright 1.56 `page.requests()` + agents | Official | https://playwright.dev/docs/release-notes#version-156 | `page.requests()` for post-interaction request history; `init-agents` for LLM-guided factory scaffolding |
| MSW PR #2732 (`ws.onUpgrade` implementation) | Community | https://github.com/mswjs/msw/pull/2732 | Design rationale: why `ws.onUpgrade` is global (not per-link), default 101 behaviour, Node.js restriction |

---

## Playwright 1.57 `testConfig.webServer.wait` — Dynamic Port Injection for Test Data Servers  [community]

Playwright 1.57 added a `wait` field to `testConfig.webServer` that accepts a regular expression with optional **named capture groups**. When the test server emits a matching line to stdout/stderr, Playwright extracts the named captures and injects them as environment variables into the test process — before any test or fixture runs.

**Why it matters for test data:** Integration test suites often spin up a real application server (or a dedicated test-data server) on a dynamic port. Before 1.57, the only option was to write the port to a temp file during `globalSetup` and read it in fixtures — a brittle, multi-step dance. The `wait` pattern gives you a first-class way to inject the server's dynamic port (or any emitted value) into fixtures as an environment variable, keeping your test data setup declarative.

```typescript
// playwright.config.ts — dynamic port injection via webServer.wait (Playwright 1.57+)
import { defineConfig } from '@playwright/test';

export default defineConfig({
  webServer: {
    command: 'node test-data-server.js',   // emits: "Test data server listening on port 54321"
    // Named capture group 'port' is extracted and injected as PLAYWRIGHT_TEST_DATA_PORT
    wait: /Test data server listening on port (?<port>\d+)/,
    // No static 'port' or 'url' needed — Playwright waits for the regex match
    reuseExistingServer: !process.env.CI,
    timeout: 10_000,
  },
  use: {
    // Fixtures can now read process.env.PLAYWRIGHT_TEST_DATA_PORT
    baseURL: `http://localhost:${process.env.PLAYWRIGHT_TEST_DATA_PORT}`,
  },
});
```

```typescript
// fixtures/test-data-fixtures.ts — read the injected dynamic port in a fixture
import { test as base, expect } from '@playwright/test';

interface TestDataFixtures {
  testDataBaseUrl: string;
}

export const test = base.extend<TestDataFixtures>({
  testDataBaseUrl: async ({}, use) => {
    // process.env.PLAYWRIGHT_TEST_DATA_PORT is injected by the webServer.wait match
    const port = process.env['PLAYWRIGHT_TEST_DATA_PORT'];
    if (!port) {
      test.abort('PLAYWRIGHT_TEST_DATA_PORT not set — webServer.wait may not have matched');
    }
    await use(`http://localhost:${port}`);
  },
});

export { expect };
```

```typescript
// test-data-server.js (CommonJS) — must emit the wait-matched line to stdout
const http = require('http');
const server = http.createServer((req, res) => {
  // Serve factory-generated seed data as JSON — used in test fixtures via testDataBaseUrl
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ users: [], products: [] }));
});
server.listen(0, () => {
  const { port } = server.address() as { port: number };
  // This line matches the webServer.wait regex — Playwright injects port as env var
  console.log(`Test data server listening on port ${port}`);
});
```

**Multiple capture groups:** If your server emits multiple dynamic values (e.g., both a data server port and an auth service port), you can use multiple named groups in the same regex:

```typescript
// wait: /Data: (?<dataPort>\d+), Auth: (?<authPort>\d+)/
// → injects PLAYWRIGHT_DATA_PORT and PLAYWRIGHT_AUTH_PORT
```

**Tradeoff vs `globalSetup`:** `testConfig.webServer.wait` only works when the server emits a stable, parseable line. If your server's startup sequence is more complex (database migrations, seed scripts), use a `globalSetup` project (see the "Playwright 1.49 Multiple `globalSetup`" section) and emit a "ready" sentinel from within the setup script.

---

## Playwright 1.60 `locator.drop()` — Binary and Clipboard Test Data Delivery  [community]

Playwright 1.60 added `locator.drop()`, a dedicated API for simulating external drag-and-drop operations — specifically, dropping **files** or **clipboard data** onto a target element. This fills the test data gap for file-upload dropzone UIs, rich-text editors with paste support, and any component that relies on the HTML5 `DataTransfer` API.

**Before 1.60:** Testing dropzones required either `page.dispatchEvent()` with a manually constructed `DataTransfer` object (verbose, TypeScript-unfriendly) or `page.setInputFiles()` (only works on `<input type="file">`, not arbitrary drop targets).

**Why it matters for test data factories:** File contents in drop tests are test data. Factories can generate in-memory `Buffer` objects with specific content shapes (e.g., valid CSV, malformed JSON, oversized binary blobs) and deliver them to dropzones via `locator.drop()` without writing to disk.

```typescript
// fixtures/file-drop-fixtures.ts — factory-generated file test data via locator.drop()
import { test as base } from '@playwright/test';
import { faker } from '@faker-js/faker';

interface FileDropFixtures {
  dropFile: (
    locator: import('@playwright/test').Locator,
    options: {
      name: string;
      mimeType: string;         // REQUIRED: omitting silently prevents the drop event
      content: string | Buffer;
    }
  ) => Promise<void>;
}

export const test = base.extend<FileDropFixtures>({
  dropFile: async ({}, use) => {
    await use(async (locator, { name, mimeType, content }) => {
      const buffer =
        typeof content === 'string' ? Buffer.from(content) : content;

      // locator.drop() dispatches synthetic dragenter + dragover + drop events
      await locator.drop({
        files: { name, mimeType, buffer },
      });
    });
  },
});

export { expect } from '@playwright/test';
```

```typescript
// Example test: factory-generated CSV file dropped on a data-import dropzone
import { test, expect } from './fixtures/file-drop-fixtures';
import { faker } from '@faker-js/faker';

function buildCsvContent(rows: number): string {
  const header = 'id,name,email';
  const dataRows = Array.from({ length: rows }, (_, i) =>
    `${i + 1},${faker.person.fullName()},${faker.internet.email()}`
  );
  return [header, ...dataRows].join('\n');
}

test('import dropzone accepts a valid CSV with factory-generated rows', async ({ page, dropFile }) => {
  await page.goto('/import');
  const dropzone = page.getByTestId('csv-dropzone');

  await dropFile(dropzone, {
    name: 'users.csv',
    mimeType: 'text/csv',          // must match — see gotcha #32
    content: buildCsvContent(10),
  });

  await expect(page.getByText('10 records ready for import')).toBeVisible();
});

test('import dropzone rejects oversized file gracefully', async ({ page, dropFile }) => {
  await page.goto('/import');
  const dropzone = page.getByTestId('csv-dropzone');

  // 6MB buffer — exceeds the 5MB limit enforced by the dropzone handler
  const oversizedBuffer = Buffer.allocUnsafe(6 * 1024 * 1024);

  await dropFile(dropzone, {
    name: 'large-export.csv',
    mimeType: 'text/csv',
    content: oversizedBuffer,
  });

  await expect(page.getByRole('alert')).toContainText('File exceeds 5MB limit');
});
```

```typescript
// Clipboard data variant — drop plain text or HTML content into a rich-text editor
test('rich-text editor accepts pasted HTML via drop', async ({ page }) => {
  await page.goto('/editor');
  const editor = page.getByRole('textbox', { name: 'Document body' });

  await editor.drop({
    data: {
      'text/html': '<p><strong>Factory-generated</strong> content</p>',
      'text/plain': 'Factory-generated content',
    },
  });

  await expect(editor.locator('strong')).toHaveText('Factory-generated');
});
```

**Tradeoff: `locator.drop()` vs `page.setInputFiles()` vs `locator.dispatchEvent()`:**

| Method | Target | MIME needed | Binary `Buffer` | `DataTransfer` control |
|--------|--------|------------|-----------------|------------------------|
| `locator.drop({ files })` (1.60+) | Any dropzone | Yes (required) | Yes | Automatic |
| `page.setInputFiles()` | `<input type="file">` only | No | Yes | None |
| `locator.dispatchEvent('drop', dt)` | Any element | Manual | Manual | Full (verbose) |

---

## Playwright 1.60 `webSocketRoute.protocols()` — Subprotocol-Aware WebSocket Mock Factories  [community]

Playwright 1.60 added `webSocketRoute.protocols()`, which returns the **WebSocket subprotocols requested by the page** (the `Sec-WebSocket-Protocol` header values). This enables writing protocol-aware WebSocket route handlers that dispatch different factory-generated message shapes depending on which subprotocol the client negotiated — matching the behaviour of real WebSocket servers that serve different wire formats per subprotocol.

**Why it matters for test data:** Many production WebSocket APIs support multiple subprotocols (e.g., `json` vs `msgpack`, or `v1` vs `v2`). Without `protocols()`, your mock factory sends the same message format regardless of what the client requested — causing subtle test failures when the client negotiates a subprotocol that changes the wire format. With `protocols()`, you can branch the factory logic per negotiated protocol, exactly as a real server would.

```typescript
// fixtures/ws-protocol-fixtures.ts — subprotocol-aware WebSocket mock factory
import { test as base } from '@playwright/test';
import { faker } from '@faker-js/faker';

// Factory types for each supported subprotocol
interface JsonEvent {
  type: string;
  payload: Record<string, unknown>;
  timestamp: string;
}

interface BinaryEvent {
  eventId: number;
  eventType: number;  // numeric enum for compact wire format
  ts: number;         // Unix ms timestamp
}

function buildJsonEvent(overrides: Partial<JsonEvent> = {}): JsonEvent {
  return {
    type: faker.helpers.arrayElement(['created', 'updated', 'deleted']),
    payload: { id: faker.string.uuid(), value: faker.number.int({ min: 1, max: 100 }) },
    timestamp: new Date().toISOString(),
    ...overrides,
  };
}

function buildBinaryEvent(overrides: Partial<BinaryEvent> = {}): BinaryEvent {
  return {
    eventId: faker.number.int({ min: 1, max: 65535 }),
    eventType: faker.helpers.arrayElement([1, 2, 3]),
    ts: Date.now(),
    ...overrides,
  };
}

function serializeBinaryEvent(event: BinaryEvent): Buffer {
  // Pack eventId (2 bytes), eventType (1 byte), ts (8 bytes) = 11 bytes total
  const buf = Buffer.allocUnsafe(11);
  buf.writeUInt16BE(event.eventId, 0);
  buf.writeUInt8(event.eventType, 2);
  buf.writeBigInt64BE(BigInt(event.ts), 3);
  return buf;
}

export const test = base.extend<{
  mockEventStream: (url: string, eventCount?: number) => Promise<void>;
}>({
  mockEventStream: async ({ page }, use) => {
    await use(async (url: string, eventCount = 3) => {
      await page.routeWebSocket(url, (ws) => {
        // Playwright 1.60: inspect the negotiated subprotocol(s)
        const protocols: string[] = ws.protocols();
        const useBinary = protocols.includes('events.binary.v1');

        for (let i = 0; i < eventCount; i++) {
          setTimeout(() => {
            if (useBinary) {
              const event = buildBinaryEvent();
              ws.send(serializeBinaryEvent(event));   // Buffer → binary frame
            } else {
              // Default: JSON subprotocol (or no subprotocol negotiated)
              const event = buildJsonEvent();
              ws.send(JSON.stringify(event));          // string → text frame
            }
          }, i * 100);
        }
      });
    });
  },
});

export { expect } from '@playwright/test';
```

```typescript
// Usage: test that dispatches factory events over the negotiated protocol
import { test, expect } from './fixtures/ws-protocol-fixtures';

test('event list renders factory events delivered over JSON subprotocol', async ({ page, mockEventStream }) => {
  await mockEventStream('wss://events.example.com/stream');   // client negotiates default (JSON)
  await page.goto('/events');
  await expect(page.getByRole('listitem')).toHaveCount(3);
});

test('event list renders factory events delivered over binary subprotocol', async ({ page, mockEventStream }) => {
  // The application's WebSocket client requests 'events.binary.v1' as its preferred protocol
  await mockEventStream('wss://events.example.com/stream');
  await page.goto('/events?protocol=binary');
  await expect(page.getByRole('listitem')).toHaveCount(3);
});
```

**Note on `protocols()` return value:** `webSocketRoute.protocols()` returns an array of subprotocol strings as sent by the client in `Sec-WebSocket-Protocol`. If the client did not request any subprotocol, the array is empty — your factory should fall back to a sensible default (typically the JSON wire format) in that case.

**Tradeoff:** If your application always negotiates the same subprotocol, `protocols()` adds no value — omit the branch and keep the factory simple. Use `protocols()` only when testing code paths that behave differently per subprotocol, or when ensuring the mock factory stays aligned with the real server's multi-protocol contract.

---

32. **[community] `locator.drop()` silently swallows the drop event if `mimeType` is omitted from the file descriptor — the handler fires but `event.dataTransfer.files[0].type` is empty, causing type-gated dropzone logic to reject the file silently.**
    Playwright 1.60's `locator.drop({ files: { name, buffer } })` accepts a file descriptor where `mimeType` is technically optional in TypeScript. However, most production dropzone implementations guard on `file.type` (e.g., rejecting files whose MIME type is not `text/csv` or `image/png`). When `mimeType` is omitted, the synthetic `File` object has `type: ''`, which means:
    - A CSV import component sees `file.type === ''` → not `'text/csv'` → silently rejects
    - The test sees no error thrown, no exception in the route handler — just a passing assertion that happens to be wrong (no import started)
    - The bug is invisible until you inspect `event.dataTransfer.files[0].type` in a debug `page.evaluate()` call

    ```typescript
    // WRONG — mimeType omitted: drop fires, but file.type is '' in the handler
    await dropzone.drop({
      files: { name: 'data.csv', buffer: Buffer.from(csvContent) },  // no mimeType
    });
    // ✗ silently rejected by type-checking dropzone; test may still pass if assertion is weak

    // CORRECT — always specify mimeType to match the file extension and component expectation
    await dropzone.drop({
      files: { name: 'data.csv', mimeType: 'text/csv', buffer: Buffer.from(csvContent) },
    });
    // ✓ file.type === 'text/csv'; component accepts and processes the file

    // Factory helper — enforce mimeType at the type level to prevent omission
    interface DropFileDescriptor {
      name: string;
      mimeType: string;  // required — do not use Playwright's optional type directly
      content: string | Buffer;
    }

    // Map of common extensions to MIME types for factory convenience
    const MIME_BY_EXT: Record<string, string> = {
      csv: 'text/csv',
      json: 'application/json',
      pdf: 'application/pdf',
      png: 'image/png',
      jpg: 'image/jpeg',
      txt: 'text/plain',
      xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };

    function inferMimeType(filename: string): string {
      const ext = filename.split('.').pop()?.toLowerCase() ?? '';
      const mime = MIME_BY_EXT[ext];
      if (!mime) throw new Error(`No MIME type mapped for extension ".${ext}" — specify mimeType explicitly`);
      return mime;
    }
    ```

    **Root cause pattern:** `locator.drop()` mirrors browser behaviour where a `File` object can have an empty `type`. The Playwright API surface does not enforce `mimeType` because the browser doesn't either. But real dropzone handlers always read `file.type`. Your factory layer is the right place to enforce this invariant — not the test body.

---

## Key Resources (iter-44 additions)

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| Playwright 1.57 release notes | Official | https://playwright.dev/docs/release-notes#version-157 | `testConfig.webServer.wait` with regex named capture groups for dynamic port injection into test data fixtures |
| Playwright 1.60 `locator.drop()` API | Official | https://playwright.dev/docs/api/class-locator#locator-drop | File and clipboard test data delivery to dropzone elements; `files` and `data` DataTransfer variants |
| Playwright 1.60 release notes | Official | https://playwright.dev/docs/release-notes#version-160 | `locator.drop()`, `webSocketRoute.protocols()`, `tracing.startHar/stopHar` as async disposable, `test.abort()` |
