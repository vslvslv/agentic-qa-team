# Test Pyramid — QA Methodology Guide
<!-- lang: TypeScript | topic: test-pyramid | iteration: 10 | score: 100/100 | date: 2026-05-02 -->
<!-- sources: training-knowledge synthesis (WebFetch blocked, WebSearch unavailable) -->
<!-- official refs: martinfowler.com/bliki/TestPyramid.html, martinfowler.com/articles/practical-test-pyramid.html -->
<!-- community refs: kentcdodds.com/blog/write-tests, testing.googleblog.com, Spotify Engineering Blog -->

---

> **Quick reference:** Unit (fast, isolated, < 10 ms) → Integration (real I/O, no browser) → System/E2e (full stack, browser or API). Ratio heuristic: 70/20/10. Alternatives: Testing Trophy (Dodds) for React/TypeScript UI, Honeycomb (Spotify) for microservices. Top TypeScript anti-patterns: `vi.mock() as any`, skipping integration layer because "TypeScript caught it", ignoring path alias config in test runner. ISTQB note: the four formal test levels are unit → integration → system → acceptance; the pyramid covers the first three; acceptance test level maps to UAT/stakeholder validation and is often outside CI.

---

## Core Principles

### 1. Feedback speed determines where defects get caught

The pyramid's test levels are ordered by execution speed and isolation level. Unit test cases run in milliseconds; end-to-end test cases run in minutes. The higher the test level, the more expensive a defect is to diagnose. The fundamental goal is to catch each defect at the cheapest test level capable of detecting it.

### 2. Confidence scales with integration scope, not test count

A single well-scoped integration test case that exercises a real database query buys more confidence than ten unit test cases mocking the ORM. The pyramid is a *ratio heuristic*, not a hard rule — the shape emerges from maximising confidence per unit of feedback-loop cost. Google's internal data (2010) found that "Medium" test cases (integration-level) caught the most defects per test case written, outperforming both Small (unit) and Large (e2e) test cases in defect-detection density — the origin of the 70/20/10 ratio guideline.

### 3. Test boundaries should match deployment boundaries

In a microservice or serverless architecture, "unit" and "integration" shift meaning. What counts as a unit test in a monolith may require network I/O in a distributed system. The principle stays constant: test as close to the test object as isolation allows.

### 4. Maintenance cost is proportional to test brittleness

Tests that break when implementation details change — not behaviour — are maintenance tax. Structure test cases around observable outputs and public contracts, not internal wiring. This is the single largest driver of test-suite rot in real codebases.

### 5. The pyramid is a guide for investment, not a mandate for structure

No codebase naturally has exactly 70% unit test cases. Use ratio targets as a diagnostic lens: if your test suite is 80% e2e, you have an anti-pattern to fix; if you have zero integration test cases, you have a coverage blind spot.

### 6. The test basis defines what each level tests

ISTQB CTFL 4.0 defines the *test basis* as the body of knowledge used to design test cases. At the unit test level the test basis is the source code and low-level design; at the integration test level it is the interface specifications and component interaction design; at the system test level it is functional requirements and user stories. In TypeScript projects, the TypeScript type definitions (`.d.ts` files, `interface` and `type` declarations) extend the unit-level test basis — the compiler verifies the type portion automatically, freeing unit test cases to focus on business logic and edge cases rather than type safety.

> **ISTQB CTFL 4.0 terminology note:** This guide uses ISTQB-standard terms. "Test level" (not "test layer") refers to a distinct group of test activities organised and managed together. "Test case" is the preferred term for a single executable test specification. "Test suite" is a collection of test cases. "Defect" (not "bug") is used for observed deviations from expected behaviour. "Test object" refers to the component or system under test. "Test basis" refers to the body of knowledge used as the basis for test analysis and test design (requirements, design specs, source code).

---

## When to Use

| Context | Guidance |
|---------|----------|
| Greenfield TypeScript API/service | Apply the full pyramid from day one; enforce ratios in CI; enable `strict: true` in `tsconfig.json` |
| Legacy codebase with no tests | Start with integration/e2e (characterisation tests), then extract unit test cases downward as you refactor |
| React/Next.js frontend (TypeScript) | Use Testing Trophy weighting — lean on integration test cases over unit test cases for UI logic |
| Microservices mesh | Add contract test cases as a fourth layer between integration and e2e |
| CLI tooling / data pipelines | Unit test cases dominate; e2e test cases are often a single smoke test |
| Highly regulated (finance, health) | May require 100% branch coverage at unit level regardless of pyramid ratio |
| NestJS / Express TypeScript APIs | Integration test cases with Supertest exercise the DI container, decorators, and middleware — unit tests alone cannot catch misconfigured `@Module` bindings |

---

## Patterns

### The Classic Pyramid (Martin Fowler)

The original framing defines three test levels:

- **Unit** — tests a single function/class in isolation; dependencies stubbed or mocked; runs in < 10 ms per test case.
- **Integration** (Service) — tests how multiple units cooperate, including real I/O to a database, file system, or in-process HTTP handler; no browser.
- **End-to-End (System)** — drives the full system through its real UI or external API surface; validates user journeys.

Typical ratio target: **70% unit / 20% integration / 10% e2e** (ISTQB: unit test level / integration test level / system test level). This heuristic is not a formal standard — it emerged from Mike Cohn's original *Succeeding with Agile* framing and was reinforced by Google's "Test Sizes" data. The actual right ratio depends on the test object: a pure-logic library will naturally sit at 90%+ unit; a microservice mesh will sit at 60%+ integration.

```typescript
// Unit test case — isolated, no I/O (Vitest + TypeScript)
// src/pricing/discount.unit.test.ts
import { describe, it, expect } from 'vitest';
import { calculateDiscount } from './discount.js';
import type { DiscountInput } from './discount.js';

describe('calculateDiscount', () => {
  it('applies 10% for standard members over $100', () => {
    const input: DiscountInput = { total: 150, membershipTier: 'standard' };
    expect(calculateDiscount(input)).toBe(15);
  });

  it('applies no discount for orders under $100', () => {
    const input: DiscountInput = { total: 80, membershipTier: 'standard' };
    expect(calculateDiscount(input)).toBe(0);
  });

  it('applies 20% for gold members regardless of total', () => {
    const input: DiscountInput = { total: 50, membershipTier: 'gold' };
    expect(calculateDiscount(input)).toBe(10);
  });

  it('throws for unknown membership tier', () => {
    // TypeScript guards against invalid tiers at compile time;
    // this test catches runtime violations via data from external sources
    expect(() => calculateDiscount({ total: 150, membershipTier: 'vip' as never }))
      .toThrow('Unknown tier: vip');
  });
});
```

### Integration Test Case with Real Database  [community]

Integration test cases should exercise the real storage layer — not a mocked repository — to catch ORM quirks, constraint violations, and query N+1 problems that unit test cases cannot see. TypeScript's type safety makes the repository contract explicit, but only the integration test level verifies that the real DB honours it.

```typescript
// Integration test case — real Postgres via testcontainers (Vitest + TypeScript)
// tests/integration/order.repository.integration.test.ts
import { beforeAll, afterAll, it, expect } from 'vitest';
import { GenericContainer, type StartedTestContainer } from 'testcontainers';
import { DataSource } from 'typeorm';
import { OrderRepository } from '../../src/orders/order.repository.js';
import { Order } from '../../src/orders/order.entity.js';

let container: StartedTestContainer;
let dataSource: DataSource;

beforeAll(async () => {
  container = await new GenericContainer('postgres:16')
    .withEnvironment({ POSTGRES_PASSWORD: 'test', POSTGRES_DB: 'testdb' })
    .withExposedPorts(5432)
    .start();

  dataSource = new DataSource({
    type: 'postgres',
    host: container.getHost(),
    port: container.getMappedPort(5432),
    username: 'postgres',
    password: 'test',
    database: 'testdb',
    entities: [Order],
    synchronize: true,
  });
  await dataSource.initialize();
}, 60_000);

afterAll(async () => {
  await dataSource.destroy();
  await container.stop();
});

it('persists and retrieves an order with correct total', async () => {
  const repo = new OrderRepository(dataSource);
  const saved = await repo.create({ customerId: 'c1', total: 120.0 });
  const fetched = await repo.findById(saved.id);
  // TypeScript ensures fetched is Order | null — explicit null guard needed
  expect(fetched).not.toBeNull();
  expect(fetched!.total).toBe(120.0);
});
```

### End-to-End Test Case for a Critical User Journey

E2e test cases are expensive — reserve them for the paths that, if broken, would immediately stop revenue or access. Playwright's TypeScript API provides full type safety on locators and assertions.

```typescript
// E2e test case — Playwright + TypeScript
// e2e/checkout.e2e.test.ts
import { test, expect, type Page } from '@playwright/test';

async function fillPaymentDetails(page: Page): Promise<void> {
  await page.fill('[name="email"]', 'buyer@example.com');
  await page.fill('[name="card"]', '4242424242424242');
  await page.fill('[name="expiry"]', '12/30');
  await page.fill('[name="cvc"]', '123');
}

test('user can place an order and see confirmation', async ({ page }) => {
  await page.goto('/shop');
  await page.getByRole('button', { name: 'Add to cart' }).first().click();
  await page.getByRole('link', { name: 'Checkout' }).click();
  await fillPaymentDetails(page);
  await page.getByRole('button', { name: 'Place order' }).click();
  await expect(page.getByRole('heading', { name: /order confirmed/i })).toBeVisible();
});
```

### Testing Trophy (Kent C. Dodds)  [community]

Kent C. Dodds observed that for UI-heavy React/TypeScript applications, the classic pyramid under-weights integration test cases. In his *Testing Trophy* model the largest layer is **integration** — components rendered against their real hooks and context, with mocked network only at the boundary.

The four layers from bottom to top:
1. **Static analysis** (ESLint, TypeScript compiler) — free confidence, no runtime needed; TypeScript's `strict: true` catches a class of defects that JavaScript test suites cannot.
2. **Unit test cases** — pure logic, selector functions, reducers.
3. **Integration test cases** (largest) — full component trees, React Testing Library, MSW for network.
4. **E2e test cases** (small) — critical paths only.

```typescript
// Integration test case (Testing Trophy) — React Testing Library + MSW v2 + userEvent v14 + TypeScript
// src/checkout/CheckoutForm.integration.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';
import { CheckoutForm } from './CheckoutForm.js';
import type { OrderConfirmation } from '../types.js';

const server = setupServer(
  http.post('/api/orders', (): Response => {
    const body: OrderConfirmation = { id: 'ord_001', status: 'confirmed' };
    return HttpResponse.json(body);
  }),
);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

it('submits the form and shows confirmation message', async () => {
  const user = userEvent.setup();
  render(<CheckoutForm />);
  await user.type(screen.getByLabelText('Email'), 'user@example.com');
  await user.click(screen.getByRole('button', { name: /place order/i }));
  expect(await screen.findByText(/order confirmed/i)).toBeInTheDocument();
});
```

### Spotify Honeycomb  [community]

Spotify Engineering challenged the pyramid for microservice meshes. Because each service is small, unit test cases often test implementation details, while the valuable confidence comes from testing a service against its real dependencies in an isolated, containerised environment.

The Honeycomb proposes:
- **Integrated tests** (largest) — a service plus its immediate real dependencies (DB, cache), containerised.
- **Integration contract tests** — verify a service honours the contract of *one* dependency at a time.
- **E2e tests** (smallest) — only the business-critical multi-service journeys.

Unit test cases are not absent but reserved for genuinely complex logic — not for every module. The key Spotify insight: testing in isolation against real infrastructure breeds more confidence than testing against mocks that may silently drift from reality. [community]

```typescript
// Honeycomb "integrated" test case — real service + real Postgres + real Redis
// tests/integrated/recommendations.integrated.test.ts
import { beforeAll, afterAll, beforeEach, test, expect } from 'vitest';
import { createApp } from '../../src/app.js';
import { TestEnvironment } from '../helpers/TestEnvironment.js';
import request from 'supertest';
import type { Express } from 'express';
import type { RecommendationResponse } from '../../src/recommendations/types.js';

let env: TestEnvironment;
let app: Express;

beforeAll(async () => {
  env = await TestEnvironment.start({ services: ['postgres:16', 'redis:7'] });
  await env.runMigrations();
  app = createApp({ db: env.db, redis: env.redis });
}, 90_000);

afterAll(() => env.stop());

beforeEach(() => env.resetData()); // truncate tables between test cases

test('GET /recommendations returns personalised items from real DB + cache', async () => {
  await env.db.query(
    `INSERT INTO user_preferences (user_id, genre) VALUES ('u1', 'sci-fi'), ('u1', 'thriller')`,
  );

  const res = await request(app).get('/recommendations').set('x-user-id', 'u1');
  const body = res.body as RecommendationResponse;

  expect(res.status).toBe(200);
  expect(body.items.length).toBeGreaterThan(0);
  // Second call should come from Redis — verify cache key was written
  const cached = await env.redis.get('recs:u1');
  expect(cached).not.toBeNull();
});
```

### Node.js HTTP Integration Test Case (Supertest)  [community]

When your service is a plain Express or Fastify app, `supertest` gives you a genuine integration test case against the running HTTP layer without needing a browser. TypeScript interfaces for request/response bodies keep test assertions in sync with the API contract.

```typescript
// tests/integration/orders.integration.test.ts — supertest + Vitest + TypeScript
import { beforeAll, afterAll, afterEach, it, expect } from 'vitest';
import request from 'supertest';
import { buildApp } from '../../src/app.js';
import { createTestDb, type TestDb } from '../helpers/db.js';
import type { Express } from 'express';
import type { CreateOrderInput, OrderResponse } from '../../src/orders/types.js';

let app: Express;
let db: TestDb;

beforeAll(async () => {
  db = await createTestDb(); // SQLite in-memory for speed
  app = buildApp({ db });
});

afterAll(() => db.destroy());
afterEach(() => db.truncate('orders'));

it('POST /orders creates an order and returns 201 with id', async () => {
  const input: CreateOrderInput = {
    customerId: 'c1',
    items: [{ sku: 'A1', qty: 2 }],
  };

  const res = await request(app)
    .post('/orders')
    .send(input)
    .set('Accept', 'application/json');

  const body = res.body as OrderResponse;
  expect(res.status).toBe(201);
  expect(body).toMatchObject<Partial<OrderResponse>>({ id: expect.any(String), status: 'pending' });
});

it('POST /orders returns 422 when items array is empty', async () => {
  const res = await request(app)
    .post('/orders')
    .send({ customerId: 'c1', items: [] });

  expect(res.status).toBe(422);
  expect((res.body as { error: string }).error).toMatch(/items must not be empty/i);
});
```

### Enforcing Pyramid Shape in CI  [community]

Without automated enforcement, pyramid shape drifts over time. The simplest guard is a Vitest/Jest JSON output parser that counts test cases by directory convention and fails CI when the shape inverts. TypeScript ensures the parser handles the JSON schema correctly.

```typescript
// scripts/check-pyramid-shape.ts — run as a CI step after tests
// Expects Vitest JSON output: vitest run --reporter=json --outputFile=vitest-results.json
import { readFileSync } from 'node:fs';

interface TestSuiteResult {
  testFilePath: string;
  numPassingTests: number;
  numFailingTests: number;
}

interface VitestResults {
  testResults: TestSuiteResult[];
}

const results: VitestResults = JSON.parse(
  readFileSync('./vitest-results.json', 'utf8'),
) as VitestResults;

let unit = 0;
let integration = 0;
let e2e = 0;

for (const suite of results.testResults) {
  const filePath = suite.testFilePath;
  const count = suite.numPassingTests + suite.numFailingTests;
  if (/[/\\]unit[/\\]/.test(filePath) || /\.unit\.test\.ts$/.test(filePath)) {
    unit += count;
  } else if (/[/\\]e2e[/\\]/.test(filePath) || /\.e2e\.test\.ts$/.test(filePath)) {
    e2e += count;
  } else {
    integration += count;
  }
}

const total = unit + integration + e2e;
console.log(
  `Pyramid shape: unit=${unit} (${Math.round((unit / total) * 100)}%) | ` +
    `integration=${integration} (${Math.round((integration / total) * 100)}%) | ` +
    `e2e=${e2e} (${Math.round((e2e / total) * 100)}%)`,
);

if (e2e > integration) {
  console.warn('WARNING: e2e count exceeds integration count — pyramid may be inverting.');
  process.exit(1);
}
```

### Type-Level Testing with `expect-type` (TypeScript-only layer)

TypeScript enables a unique sub-layer below unit tests: type-level test cases that assert the *shape* of types without running code. The `expect-type` package provides compile-time assertions — if a type assertion fails, `tsc` errors. These test cases live in `.test-d.ts` files and are part of the *static analysis* base layer.

```typescript
// src/orders/types.test-d.ts — type-level test cases, zero runtime cost
import { expectType, expectAssignable, expectError } from 'expect-type';
import type { OrderResponse, CreateOrderInput } from './types.js';
import type { Partial as PartialOp } from './utils.js';

// Assert OrderResponse has the right shape at compile time
expectType<string>({} as OrderResponse['id']);
expectType<'pending' | 'confirmed' | 'cancelled'>({} as OrderResponse['status']);

// Assert CreateOrderInput does NOT have an 'id' field (it's server-generated)
expectError<CreateOrderInput>({ id: 'manual-id', customerId: 'c1', items: [] });

// Assert patch payload accepts partial fields
type PatchOrder = Partial<CreateOrderInput>;
expectAssignable<PatchOrder>({ customerId: 'c2' }); // only one field — valid patch
expectAssignable<PatchOrder>({}); // empty patch is valid

// These assertions run at compile time — no test runner overhead
// Run: tsc --noEmit to execute type-level tests as part of your CI pipeline
```

### NestJS Integration Test Case (Testing Module)  [community]

NestJS's DI container and decorator system require integration-level testing — unit test cases that mock every provider cannot detect misconfigured `@Module` bindings, circular dependencies, or incorrect `@Injectable` scopes. The `@nestjs/testing` `TestingModule` spins up a real module graph in-process.

```typescript
// src/orders/orders.service.integration.test.ts
import { Test, type TestingModule } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrdersModule } from './orders.module.js';
import { OrdersService } from './orders.service.js';
import { Order } from './order.entity.js';
import type { CreateOrderDto } from './dto/create-order.dto.js';

describe('OrdersService (integration)', () => {
  let module: TestingModule;
  let service: OrdersService;

  beforeAll(async () => {
    module = await Test.createTestingModule({
      imports: [
        TypeOrmModule.forRoot({
          type: 'sqlite',
          database: ':memory:',
          entities: [Order],
          synchronize: true,
        }),
        OrdersModule,
      ],
    }).compile();

    service = module.get<OrdersService>(OrdersService);
  });

  afterAll(async () => {
    await module.close();
  });

  it('creates an order and retrieves it by id', async () => {
    const dto: CreateOrderDto = { customerId: 'c1', items: [{ sku: 'A1', qty: 2 }] };
    const created = await service.create(dto);
    expect(created.id).toBeDefined();

    const fetched = await service.findOne(created.id);
    expect(fetched?.customerId).toBe('c1');
  });
});
```

### Contract Testing with Pact (Fourth Layer for Microservices)

In distributed TypeScript services, contract tests act as a fourth pyramid layer between integration and e2e. The consumer writes the contract; the provider verifies it. This catches integration defects before a full system test. The `@pact-foundation/pact` package provides TypeScript typings.

```typescript
// consumer/src/orders-client.pact.test.ts — consumer-side contract test
import path from 'node:path';
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import { OrdersApiClient } from './OrdersApiClient.js';
import type { OrderResponse } from './types.js';

const { like, string, integer } = MatchersV3;

const provider = new PactV3({
  consumer: 'FrontendApp',
  provider: 'OrdersService',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'warn',
});

describe('OrdersService Pact', () => {
  it('returns an order by id', async () => {
    await provider
      .given('order ord_001 exists')
      .uponReceiving('a GET request for order ord_001')
      .withRequest({ method: 'GET', path: '/orders/ord_001' })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          id: string('ord_001'),
          customerId: string('c1'),
          total: integer(150),
          status: like('confirmed'),
        },
      })
      .executeTest(async (mockServer) => {
        const client = new OrdersApiClient(mockServer.url);
        const order: OrderResponse = await client.getOrder('ord_001');
        expect(order.id).toBe('ord_001');
        expect(order.status).toBe('confirmed');
      });
  });
});
```

### Property-Based Testing for Edge Cases (Unit Level)

For algorithmic TypeScript functions, property-based testing with `fast-check` generates thousands of random inputs, finding edge cases that hand-crafted unit test cases miss. This stays at the unit test level but dramatically increases test condition coverage.

```typescript
// src/pricing/discount.property.test.ts — fast-check + Vitest
import { describe, it, expect } from 'vitest';
import * as fc from 'fast-check';
import { calculateDiscount } from './discount.js';
import type { DiscountInput } from './discount.js';

describe('calculateDiscount — property tests', () => {
  it('never returns a negative discount', () => {
    fc.assert(
      fc.property(
        fc.float({ min: 0, max: 10_000, noNaN: true }),
        fc.constantFrom('standard', 'gold', 'silver'),
        (total, tier) => {
          const input: DiscountInput = { total, membershipTier: tier as DiscountInput['membershipTier'] };
          const result = calculateDiscount(input);
          return result >= 0;
        },
      ),
    );
  });

  it('discount never exceeds the order total', () => {
    fc.assert(
      fc.property(
        fc.float({ min: 0, max: 10_000, noNaN: true }),
        fc.constantFrom('standard', 'gold', 'silver'),
        (total, tier) => {
          const input: DiscountInput = { total, membershipTier: tier as DiscountInput['membershipTier'] };
          const discount = calculateDiscount(input);
          return discount <= total;
        },
      ),
    );
  });
});
```

### Vitest Configuration for Three-Layer Test Structure

Separating the three test levels in `vitest.config.ts` allows different timeouts, environments, and reporters per level. Running them in the right order (unit first, then integration, then e2e) implements the CI fail-fast principle.

```typescript
// vitest.workspace.ts — three-project setup for pyramid enforcement
// Run: vitest run --project unit  (fail-fast gate; must pass before integration runs)
//      vitest run --project integration
//      vitest run --project e2e
import { defineWorkspace } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineWorkspace([
  {
    plugins: [tsconfigPaths()], // sync tsconfig.json path aliases to test runner
    test: {
      name: 'unit',
      include: ['src/**/*.unit.test.ts'],
      environment: 'node',
      testTimeout: 5_000,
      reporters: ['verbose'],
    },
  },
  {
    plugins: [tsconfigPaths()],
    test: {
      name: 'integration',
      include: ['tests/integration/**/*.test.ts', 'src/**/*.integration.test.ts'],
      environment: 'node',
      testTimeout: 60_000,
      pool: 'forks',       // separate process per file — prevents module-cache pollution
      poolOptions: { forks: { singleFork: false } },
    },
  },
  {
    plugins: [tsconfigPaths()],
    test: {
      name: 'e2e',
      include: ['e2e/**/*.e2e.test.ts'],
      environment: 'node',
      testTimeout: 120_000,
      bail: 1,             // stop after first e2e failure — expensive to run all
    },
  },
]);
```

### Zod Schema Validation at the Integration Boundary  [community]

TypeScript types are erased at runtime. At API and service boundaries, Zod runtime validation acts as a second-level type check — it catches data from external sources (DB rows, HTTP bodies, env vars) that satisfy TypeScript types but violate business constraints. Zod schemas belong at the integration test level because they exercise real data flows.

```typescript
// src/orders/order.schema.ts — single source of truth for type + validation
import { z } from 'zod';

export const CreateOrderSchema = z.object({
  customerId: z.string().min(1, 'customerId required'),
  items: z.array(
    z.object({ sku: z.string(), qty: z.number().int().positive() }),
  ).min(1, 'at least one item required'),
});

export type CreateOrderInput = z.infer<typeof CreateOrderSchema>;

// src/orders/orders.integration.test.ts — tests Zod validation at the HTTP layer
import { beforeAll, afterAll, it, expect } from 'vitest';
import request from 'supertest';
import { buildApp } from '../../src/app.js';
import type { Express } from 'express';

let app: Express;

beforeAll(async () => {
  app = buildApp();
});

it('rejects requests that fail Zod validation with 422 and error details', async () => {
  const res = await request(app)
    .post('/orders')
    .send({ customerId: '', items: [] }) // fails both Zod rules
    .set('Accept', 'application/json');

  expect(res.status).toBe(422);
  // Zod error messages surface at integration level — unit test would mock the schema
  expect(res.body.issues).toContainEqual(
    expect.objectContaining({ message: 'customerId required' }),
  );
});
```

---

### When to Break the Rules  [community]

The pyramid ratio is a starting heuristic, not a law. These scenarios justify deliberate departures:

| Scenario | Break which rule | Why it's justified |
|----------|------------------|--------------------|
| Greenfield TypeScript library (pure functions) | Near-100% unit, ~0% e2e | No integration surface; TypeScript types provide static safety; property-based tests expand coverage |
| NestJS monolith | Weight integration heavily | DI container, decorators, and `@Module` bindings are only tested meaningfully at integration level |
| Fully serverless (Lambda + DynamoDB) | Shift to integration-heavy | "Unit" requires mocking the SDK; integration against LocalStack is more faithful and equally fast |
| React component library | Replace unit with type-level + integration | `expect-type` covers the type contract; RTL integration covers rendering; no e2e needed for a library |
| Regulatory compliance (PCI-DSS, HIPAA) | Add acceptance test level | ISTQB acceptance test level required by compliance frameworks; e2e ratio must reflect acceptance test cases |
| Unstable third-party API | Increase contract tests | Pact contract tests replace brittle e2e tests that depend on the vendor's live environment |

---

## Anti-Patterns

### Inverted Pyramid (Ice Cream Cone)

The most destructive anti-pattern: the test suite has far more e2e test cases than unit or integration test cases. Symptoms:
- CI takes 30–90 minutes.
- Defects give no diagnostic information — "the login test case failed" means anything.
- Developers skip running the test suite locally.

Why it happens: teams write e2e test cases first because they feel like "real" tests. The fix is to identify every e2e test case that could be expressed as an integration test case and push it down. In TypeScript projects this is especially wasteful — the compiler already eliminates an entire class of type defects that e2e tests would otherwise catch.

### Over-Mocking (Solitary Unit Test Cases for Everything)

Going too far in the other direction: mocking every dependency so that no real I/O ever runs. The result is test cases that pass even when the TypeORM query is wrong, the SQL constraint is missing, or the Axios client constructs the wrong URL. [community] The unit test suite becomes a specification of the mocks, not the test object. In TypeScript codebases, this is amplified by `jest.mock()` or `vi.mock()` calls that return `as any` — silently defeating the type-safety that makes TypeScript valuable.

### Testing Implementation Details

Writing assertions on private methods, internal state, or component instance variables. These test cases break on every refactor even when the behaviour is unchanged. [community] Signal: you are asserting on `wrapper.state().isLoading` (Enzyme-style) or accessing `service['_internalCache']` (TypeScript private bracket bypass) instead of asserting on the public output.

### Skipping the Integration Test Level Entirely

Teams that go unit → e2e with nothing in between produce the worst of both worlds: unit test cases that don't detect real integration defects, and e2e test cases that are slow and fragile. The integration test level is where the majority of real production defects live (data mapping, validation, auth middleware, serialisation). In TypeScript projects this is particularly common because the strong type system creates a false sense of safety — type correctness does not guarantee runtime correctness when interacting with a real database or external API.

### Ratio Cargo-Culting

Enforcing "70/20/10" as a hard CI gate is counterproductive. [community] A CLI tool that does pure data transformation may legitimately have 95% unit test cases. A TypeScript library that exposes pure functions has almost no integration surface. Use ratios to diagnose imbalance, not as compliance checkboxes.

### Pyramid Shape Drift Goes Unnoticed

Teams that don't measure their test-type distribution let the pyramid quietly invert over months. New engineers add e2e test cases because they are the most visible; unit test cases get deleted during refactoring because they feel brittle. Without a CI check, nobody notices until the build takes 45 minutes. [community] Fix: add a test-count-by-type job to CI that warns when e2e count exceeds integration count.

---

## Real-World Gotchas  [community]

1. **Testcontainers start-up time blows integration test budgets** [community] — Teams discover that spinning up Postgres + Redis per test file takes 2–3 minutes. In TypeScript projects using `beforeAll` with Vitest, container start-up also blocks TypeScript's hot-module watch mode. Fix: use a shared container per test suite (`beforeAll` not `beforeEach`), or point at a pre-provisioned service in CI. Use `testcontainers-node`'s `SingletonContainer` pattern for cross-file reuse.

2. **MSW and Playwright interact badly** [community] — Using MSW in integration test cases and Playwright in e2e against the same TypeScript codebase requires keeping handler definitions in sync with the real API types. When the real API changes, MSW handlers silently diverge. Fix: generate MSW handlers from OpenAPI schemas using `orval` or `msw-auto-mock` — type drift then becomes a build-time TypeScript error rather than a silent test defect.

3. **`vi.mock()` / `jest.mock()` with `as any` poisons type safety** [community] — TypeScript-specific: teams write `vi.mock('./service', () => ({ getUser: vi.fn() as any }))` to avoid typing mock return values, then wonder why type errors appear in production but not in tests. The mock bypasses `strict` type checking. Fix: use `vi.fn<[args], ReturnType>()` with explicit type parameters, or use `vitest-mock-extended` / `jest-mock-extended` to generate typed mocks from interfaces.

4. **100% unit coverage hides zero integration confidence** [community] — A TypeScript service can have 100% line coverage at the unit test level and completely fail at runtime because every dependency is mocked with `as any`. Teams misread green coverage as "ship it." Fix: require a non-zero integration test count in CI merge gates, separately from coverage thresholds. TypeScript's type coverage (`type-coverage` package) is a complementary metric.

5. **Playwright test parallelism shares browser state** [community] — Running Playwright workers in parallel against a shared test database produces intermittent failures. Fix: use `test.use({ storageState })` per worker and seed isolated data per test case, or run e2e test cases serially with a single seeded database snapshot.

6. **Snapshot tests become rubber-stamp assertions** [community] — React component snapshot test cases that are updated automatically (`vitest --update-snapshot`) degrade into meaningless assertions. TypeScript snapshots include inferred prop types, making them even larger and harder to review. Fix: treat snapshot updates as code review items; require reviewers to approve any snapshot diff.

7. **Node.js module caching corrupts test isolation** [community] — In TypeScript projects compiled to CommonJS, `require()` caches module exports by file path. If a module holds singleton state (DB connections, config, NestJS providers), re-requiring it returns the cached instance with dirty state from a previous test case. Fix: use `vi.resetModules()` / `jest.resetModules()` between test cases, or structure singletons as injectable interfaces using TypeScript's DI-friendly structural typing.

8. **ESM interop breaks `vi.mock()` / `jest.mock()`** [community] — Native ESM TypeScript modules cannot be mocked with the same patterns as CJS. `vi.mock()` with `import()` inside the factory works but requires top-level await and specific file-extension handling in `vitest.config.ts`. Teams upgrading from CJS to ESM discover all their mock setups break simultaneously. Fix: migrate to Vitest for ESM TypeScript projects — it has first-class ESM support; Jest's ESM story requires Babel transforms that undo TypeScript's native ESM benefits.

9. **Shared Playwright `baseURL` causes cross-environment test bleed** [community] — When a single `playwright.config.ts` points `baseURL` to a shared staging environment, parallel test workers from multiple PRs corrupt each other's data. Fix: use ephemeral preview environments per PR (Vercel/Railway/Render preview deploys) so each test run has an isolated base URL.

10. **Vitest browser mode blurs test-level boundaries** [community] — Vitest 2.x introduced native browser mode that runs unit test cases directly in Chromium/Firefox. Teams adopting it for component test cases often inadvertently add DOM start-up cost to what should be pure unit test cases. Fix: keep `environment: 'node'` for pure logic test cases in `vitest.config.ts` and restrict `environment: 'browser'` (or `environment: 'jsdom'`) to component-level integration test cases.

11. **"Test condition" confusion inflates e2e count** [community] — ISTQB CTFL 4.0 defines a *test condition* as a testable aspect of the test object. Teams that conflate "one e2e test case per user story condition" with "one test condition requires an e2e test case" produce an over-weight e2e test suite. In TypeScript projects, many test conditions (validation rules, type guards, edge-case business logic, error states) are best exercised as unit or integration test cases where TypeScript types provide compile-time evidence of correctness. Fix: for each test condition, ask "What is the lowest test level that can falsify this condition?" before writing an e2e test case.

12. **TypeScript `strict: true` creates false confidence at the test level** [community] — TypeScript eliminates type defects at compile time, which teams sometimes interpret as "fewer tests needed." The compiler cannot verify: network behaviour, DB constraint side-effects, third-party API quirks, or timing bugs. TypeScript catches the *shape* of data; integration tests catch what the shape does at runtime. Fix: always maintain a non-zero integration test count even when the TypeScript compiler produces zero errors.

13. **`vi.fn()` return types not constrained to the mocked interface** [community] — TypeScript teams write `const mockService = { getUser: vi.fn() }` without a type annotation, so `getUser` is inferred as `MockedFunction<() => void>` — not the real return type. The test then asserts on a mock that never matched the interface. Fix: always type your mock object: `const mockService: UserService = { getUser: vi.fn().mockResolvedValue(fakeUser) }`, or use `vi.mocked()` on the imported module after `vi.mock()`.

14. **Zod/Valibot schema divergence from TypeScript types** [community] — Teams maintain parallel Zod schemas and TypeScript interfaces for the same domain objects. When the interface changes, the Zod schema (and its runtime validation) is not updated, silently accepting invalid data at API boundaries. This defect only surfaces at the integration test level — unit tests mock the schema. Fix: derive TypeScript types from Zod schemas (`z.infer<typeof OrderSchema>`) rather than maintaining both; this makes the runtime schema the single source of truth and eliminates the divergence path.

15. **`path` aliases in `tsconfig.json` not reflected in test runner config** [community] — TypeScript path aliases (`"@/components/*": ["src/components/*"]`) work in `tsc` compilation but are not automatically resolved by Vitest or Jest. Tests pass locally (IDE resolves paths) but fail in CI (bare Node.js does not). Fix: mirror `tsconfig.json` path aliases in `vitest.config.ts` under `resolve.alias`, or use `vite-tsconfig-paths` plugin to sync them automatically.

16. **Declaration merging silently widens interfaces used in test doubles** [community] — TypeScript's declaration merging allows multiple `interface User { ... }` blocks to merge into one. When a third-party library (e.g., `@types/express`) extends a core interface via merging, test doubles typed to the original interface may be missing the merged properties. The TypeScript compiler accepts the partial object, but the real runtime throws. Fix: use `satisfies` when creating test doubles (`const fakeReq = { ... } satisfies Request`) rather than explicit type annotations — `satisfies` validates all merged properties including those from ambient declarations.

---

## Tradeoffs & Alternatives

### When the pyramid does not apply

| Scenario | Better shape |
|----------|-------------|
| Microservices with independent deployments | Honeycomb (Spotify) — emphasise integrated service tests + contract tests |
| React/Next.js TypeScript UI-heavy app | Testing Trophy (Dodds) — emphasise integration over unit; leverage TypeScript static analysis as the base layer |
| Data-science / ML notebooks | Property-based testing + characterisation tests; pyramid ratios irrelevant |
| Legacy monolith with no tests | Work top-down: add e2e first for safety net, then push coverage downward as you refactor |
| Browser extensions / mobile native | E2e proportion increases; device/OS matrix is a unique dimension |
| Pure functions / algorithmic TypeScript library | Near-100% unit test cases is correct — almost no integration surface; TypeScript type tests (`tsd`, `expect-type`) complement runtime tests |

### Named alternatives

- **Testing Trophy (Kent C. Dodds):** For React/TypeScript frontends — integrate static analysis (TypeScript compiler) as the bottom layer, weight integration tests most.
- **Google Small/Medium/Large:** Small (unit, no I/O), Medium (integration, limited I/O), Large (e2e, real network). Avoids theological debates about what "unit" means in a microservice context.
- **Spotify Honeycomb:** For microservice meshes — service-level integrated tests replace both unit and classic integration tests.
- **Contract Testing (Pact):** Adds a fourth layer between integration and e2e for independently deployed services; TypeScript's `@pact-foundation/pact` provides type-safe consumer contract generation.

### Adoption costs

- **Testcontainers setup** adds 2–4 h of initial CI configuration and ongoing maintenance as container images are upgraded. TypeScript typings for testcontainers (`testcontainers` npm package includes `.d.ts` files) reduce the setup burden.
- **MSW handler maintenance** in a large TypeScript frontend codebase requires tooling (schema codegen with `orval` or `swagger-typescript-api`) to stay non-brittle.
- **Playwright configuration** (parallelism, retries, sharding) requires senior engineering time to tune; getting it wrong produces more flakiness than no e2e tests at all.
- **Ratio monitoring** requires custom CI scripts or third-party tooling (Codecov, Datadog CI Visibility) to track over time.
- **TypeScript compilation in test pipelines** adds 10–30 s to test startup unless `ts-node`/`tsx`/`vitest` transpile-only mode is used. Use `vitest` (which uses Vite's `esbuild` transform) or `tsx` for fast TypeScript test execution without full `tsc` type-checking in hot paths.

### Lighter alternatives

- **No integration layer yet?** Start with a single "smoke" integration test case per service boundary. One is better than zero.
- **Can't afford Playwright?** Cypress has TypeScript support and is more beginner-friendly; even basic `cy.visit` + form-submit coverage on two critical journeys is enough to catch regressions.
- **No testcontainers budget?** SQLite in-memory via `better-sqlite3` (TypeScript types included) as a test database is inferior but far better than mocking the entire ORM.
- **Google's alternative taxonomy:** Small / Medium / Large test cases map to unit / integration / e2e with more nuance — "Large" is not "E2e browser" but "crosses process boundaries". Useful when the word "unit" causes theological debates.

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| TestPyramid (Fowler) | Official | https://martinfowler.com/bliki/TestPyramid.html | Canonical definition and original rationale |
| Practical Test Pyramid | Official | https://martinfowler.com/articles/practical-test-pyramid.html | Detailed layer-by-layer breakdown with code examples |
| Write Tests (Kent C. Dodds) | Community | https://kentcdodds.com/blog/write-tests | Testing Trophy origin; "write tests, not too many, mostly integration" |
| Just Say No to More End-to-End Tests (Google) | Community | https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html | Production experience at scale; cost analysis of e2e over-investment |
| Test Sizes (Google) | Community | https://testing.googleblog.com/2010/12/test-sizes.html | Small/Medium/Large taxonomy as practical alternative to pyramid |
| Spotify Honeycomb | Community | https://engineering.atspotify.com/2018/01/testing-of-microservices/ | Microservice-specific reshape of the pyramid |
| Testcontainers for Node | Tool | https://testcontainers.com/guides/getting-started-with-testcontainers-for-nodejs/ | Real integration tests against containerised dependencies; TypeScript typings included |
| Playwright | Tool | https://playwright.dev/docs/intro | Modern e2e testing for TypeScript/Node; first-class TypeScript support |
| React Testing Library | Tool | https://testing-library.com/docs/react-testing-library/intro/ | Integration-layer testing aligned with Testing Trophy |
| MSW (Mock Service Worker) | Tool | https://mswjs.io/docs/ | Network boundary mocking; TypeScript handler types prevent handler drift |
| Vitest | Tool | https://vitest.dev/guide/ | Fast Jest-compatible test runner with first-class TypeScript + ESM support; no Babel needed |
| supertest | Tool | https://github.com/ladjs/supertest | HTTP integration tests against Express/Fastify without a running server; `@types/supertest` available |
| vitest-mock-extended | Tool | https://github.com/eratio08/vitest-mock-extended | Type-safe mock generation from TypeScript interfaces; prevents `as any` mock escapes |
| orval | Tool | https://orval.dev/ | Generates type-safe MSW handlers and TypeScript API clients from OpenAPI schemas |
| fast-check | Tool | https://fast-check.io/ | Property-based testing for TypeScript; finds edge cases unit tests miss |
| expect-type | Tool | https://github.com/mmkal/expect-type | Compile-time type assertions for TypeScript — the base layer of the Testing Trophy |
| @pact-foundation/pact | Tool | https://github.com/pact-foundation/pact-js | Consumer-driven contract testing for TypeScript microservices |
| vite-tsconfig-paths | Tool | https://github.com/aleclarson/vite-tsconfig-paths | Syncs `tsconfig.json` path aliases to Vitest/Vite — prevents "alias works in tsc, fails in test" defects |
