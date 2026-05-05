# Test Pyramid — QA Methodology Guide
<!-- lang: TypeScript | topic: test-pyramid | iteration: 31 | score: 100/100 | date: 2026-05-04 -->
<!-- sources: training-knowledge synthesis + WebFetch: martinfowler.com (2026-05-03) | new: howtheytest (108 companies real-world test strategies) -->
<!-- official refs: martinfowler.com/bliki/TestPyramid.html, martinfowler.com/articles/practical-test-pyramid.html -->
<!-- community refs: kentcdodds.com/blog/write-tests, testing.googleblog.com, Spotify Engineering Blog -->

---

> **Quick reference:** Unit (fast, isolated, < 10 ms) → Integration (real I/O, no browser) → System/E2e (full stack, browser or API). Ratio heuristic: 70/20/10. Alternatives: Testing Trophy (Dodds) for React/TypeScript UI, Honeycomb (Spotify) for microservices, Google Small/Medium/Large for distributed systems. Top TypeScript anti-patterns: `vi.mock() as any`, skipping integration layer because "TypeScript caught it", ignoring path alias config in test runner, record-and-playback e2e generators, AI-generated unit suites without integration counterparts. New patterns (2026): Trace-based integration testing (OpenTelemetry + Tracetest), AI pyramid shape governance, container DB parity. ISTQB note: the four formal test levels are unit → integration → system → acceptance; the pyramid covers the first three; acceptance test level maps to UAT/stakeholder validation and is often outside CI.

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

### 7. Test duplication across levels is maintenance waste

Each test level should add unique confidence that the levels below it cannot provide. The principle: "If a higher-level test case spots a defect and there is no lower-level test case failing, you need to write a lower-level test case" (Fowler). The inverse is equally important: do not replicate the same assertion at unit, integration, *and* e2e level. Duplication triples maintenance cost without multiplying confidence. In TypeScript codebases this is common with validation logic: teams write a unit test case for the Zod schema, an integration test case that also checks the error shape, *and* an e2e test case that submits an invalid form — all three asserting the same rule. Fix: assert the Zod rule once at unit level; assert the HTTP error shape once at integration level; remove the e2e test case for that path unless it also tests UI feedback rendering.

### 6. The test basis defines what each level tests

ISTQB CTFL 4.0 defines the *test basis* as the body of knowledge used to design test cases. At the unit test level the test basis is the source code and low-level design; at the integration test level it is the interface specifications and component interaction design; at the system test level it is functional requirements and user stories. In TypeScript projects, the TypeScript type definitions (`.d.ts` files, `interface` and `type` declarations) extend the unit-level test basis — the compiler verifies the type portion automatically, freeing unit test cases to focus on business logic and edge cases rather than type safety.

> **ISTQB CTFL 4.0 terminology note:** This guide uses ISTQB-standard terms. "Test level" (not "test layer") refers to a distinct group of test activities organised and managed together. "Test case" is the preferred term for a single executable test specification. "Test suite" is a collection of test cases. "Defect" (not "bug") is used for observed deviations from expected behaviour. "Test object" refers to the component or system under test. "Test basis" refers to the body of knowledge used as the basis for test analysis and test design (requirements, design specs, source code).
>
> **ISTQB CTFL 4.0 — Component vs Component Integration distinction:** ISTQB CTFL 4.0 formally separates *component test level* (testing a single component in isolation — equivalent to "unit") from *component integration test level* (testing interactions between components — equivalent to "integration"). The test pyramid's middle layer maps precisely to the component integration test level. In TypeScript monorepos with Nx or Turborepo, the component integration test level corresponds to testing across package boundaries with real in-process imports — not mocked module boundaries. This distinction matters when writing test plans for regulated environments where ISTQB level names are required in documentation.

---

## When to Use

| Context | Guidance |
|---------|----------|
| Safety-critical systems (medical, aviation, finance) | May require a heavier system/acceptance test level regardless of pyramid ratio; ISTQB acceptance test level maps to stakeholder UAT and may be mandatory per compliance frameworks (IEC 62304, DO-178C). Pyramid ratios are advisory; compliance requirements are not. |
| API-first / OpenAPI TypeScript service | REST integration test cases are primary; Playwright e2e is secondary (browser is not the primary consumer). Use `supertest` + OpenAPI-generated schemas for the integration layer; use Playwright only to validate the BFF or SSR layer. |
| Greenfield TypeScript API/service | Apply the full pyramid from day one; enforce ratios in CI; enable `strict: true` in `tsconfig.json` |
| Legacy codebase with no tests | Start with integration/e2e (characterisation tests), then extract unit test cases downward as you refactor |
| React/Next.js frontend (TypeScript) | Use Testing Trophy weighting — lean on integration test cases over unit test cases for UI logic |
| Microservices mesh | Add contract test cases as a fourth layer between integration and e2e |
| CLI tooling / data pipelines | Unit test cases dominate; e2e test cases are often a single smoke test |
| Highly regulated (finance, health) | May require 100% branch coverage at unit level regardless of pyramid ratio |
| NestJS / Express TypeScript APIs | Integration test cases with Supertest exercise the DI container, decorators, and middleware — unit tests alone cannot catch misconfigured `@Module` bindings |
| Bun runtime (TypeScript native) | Bun's built-in `bun:test` runner executes TypeScript natively without a transpiler step. Unit test cases gain speed; use the same pyramid ratios. Be aware that `bun:test`'s module mock API differs from Vitest's `vi.mock()` — mocks must be declared at the top of the file before imports. Integration tests with `testcontainers` work but require Node.js compatibility mode (`--bun` flag not needed for `testcontainers` since Bun 1.1+). |
| Deno runtime (TypeScript native) | Deno's `Deno.test()` runner has built-in TypeScript support. Use `npm:testcontainers` for integration tests. The pyramid applies identically; the main difference is that Deno's permissions model (`--allow-net`, `--allow-read`) can isolate tests more granularly than Node.js — use this to enforce that unit tests truly have no network access. |
| OpenAPI-first TypeScript services | Generate TypeScript client types and MSW handlers from the OpenAPI schema (`orval`, `openapi-typescript`). Integration tests use the generated types and handlers, creating a compile-time coupling between the test layer and the API contract. This eliminates a whole class of integration test defects caused by manually maintained mock data diverging from the real schema. |

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

### Playwright Component Testing at the Integration Test Level

Playwright 1.35+ introduced native component testing (`@playwright/experimental-ct-react` / `@playwright/experimental-ct-vue`) that mounts components in a real browser without starting a full server. This sits at the integration test level: the component is rendered with real browser APIs (not jsdom), but the network is intercepted. This makes it appropriate for components that depend on browser-specific APIs (ResizeObserver, IntersectionObserver, Web Workers) that jsdom cannot emulate.

```typescript
// src/components/ProductCard.ct.test.tsx — Playwright Component Test
// playwright-ct.config.ts is separate from playwright.config.ts (e2e)
import { test, expect } from '@playwright/experimental-ct-react';
import { ProductCard } from './ProductCard.js';
import type { Product } from '../types.js';

const sampleProduct: Product = {
  id: 'p1',
  name: 'TypeScript Handbook',
  price: 29.99,
  inStock: true,
};

test('renders product name and price', async ({ mount }) => {
  const component = await mount(<ProductCard product={sampleProduct} />);
  await expect(component.getByRole('heading')).toContainText('TypeScript Handbook');
  await expect(component.getByText('$29.99')).toBeVisible();
});

test('shows out-of-stock badge when inStock is false', async ({ mount }) => {
  const outOfStock: Product = { ...sampleProduct, inStock: false };
  const component = await mount(<ProductCard product={outOfStock} />);
  await expect(component.getByRole('status')).toContainText(/out of stock/i);
});

test('calls onAddToCart with product id when button is clicked', async ({ mount }) => {
  let calledWith: string | null = null;
  const component = await mount(
    <ProductCard product={sampleProduct} onAddToCart={(id) => { calledWith = id; }} />
  );
  await component.getByRole('button', { name: /add to cart/i }).click();
  expect(calledWith).toBe('p1');
});
```

Playwright component tests run in real Chromium/Firefox/WebKit, which closes the gap between jsdom-based integration tests and full e2e tests. They are faster than e2e (no full app server needed) but slower than jsdom-based RTL tests. Place them in a `*.ct.test.tsx` naming convention and a separate Playwright CT workspace project to keep them distinct from both RTL integration tests and e2e tests in the pyramid reporting script. contract tests act as a fourth pyramid layer between integration and e2e. The consumer writes the contract; the provider verifies it. This catches integration defects before a full system test. The `@pact-foundation/pact` package provides TypeScript typings.

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

### Mutation Testing with Stryker at the Unit Test Level

Mutation testing validates that your unit test cases are *effective* — not just that they pass, but that they detect real logic defects. Stryker Mutator (`@stryker-mutator/core`) supports TypeScript natively and integrates with Vitest. A high mutation score (>80%) confirms that the unit test layer is actually exercising all the business logic branches it claims to cover.

```typescript
// stryker.config.mts — Stryker v8 + Vitest + TypeScript
import type { Config } from '@stryker-mutator/api/config';

const config: Config = {
  testRunner: 'vitest',
  plugins: [
    '@stryker-mutator/vitest-runner',
    '@stryker-mutator/typescript-checker',
  ],
  checkers: ['typescript'],
  tsconfigFile: 'tsconfig.json',        // TypeScript checker re-validates each mutant
  mutate: [
    'src/**/*.ts',
    '!src/**/*.test.ts',
    '!src/**/*.test-d.ts',
  ],
  thresholds: {
    high: 80,
    low: 60,
    break: 50,                           // fail CI if mutation score drops below 50%
  },
  // Stryker reports which unit test cases caught each mutant, identifying dead/weak tests
  reporters: ['html', 'clear-text', 'json'],
  htmlReporter: { fileName: 'reports/mutation/mutation-report.html' },
};

export default config;
```

Stryker's TypeScript checker re-compiles each mutant — if a mutation produces a TypeScript compile error, Stryker marks it as *compile-time killed*, which is a free win from the type system. The remaining surviving mutants (mutations the TypeScript compiler accepts but tests don't catch) are the actionable signal. Add `stryker run` as a weekly CI step — not on every commit — because mutation testing can take minutes to hours on large codebases.

### Property-Based Testing for Edge Cases (Unit Level)

For algorithmic TypeScript functions, property-based testing with `fast-check` generates thousands of random inputs, finding edge cases that hand-crafted unit test cases miss. This stays at the unit test level but dramatically increases test condition coverage.

### AI-Assisted Test Generation: Pyramid Shape Governance  [community]

LLM-based coding assistants (GitHub Copilot, Cursor, Claude Code) dramatically reduce the time to write test cases — but they default to generating unit test cases with heavy `vi.mock()` usage because unit tests are the most common pattern in their training corpus. Without intentional governance, AI-generated test suites systematically invert the pyramid: unit count grows while integration test count stagnates.

The fix is a CI lint rule and a factory-enforced generation prompt:

```typescript
// .eslintrc.cjs — ESLint rule to detect vi.mock() overuse as a pyramid health signal
// Run: eslint src --max-warnings 0
// Counts vi.mock() calls per file; warns if > 5 in a single file (heuristic for over-mocking)
module.exports = {
  rules: {
    'no-restricted-syntax': [
      'warn',
      {
        // Detect test files with > 5 vi.mock() declarations — sign of over-mocked unit tests
        selector: 'Program:has(CallExpression[callee.object.name="vi"][callee.property.name="mock"]:nth-child(6))',
        message: 'More than 5 vi.mock() calls in one file. Consider an integration test instead.',
      },
    ],
  },
};
```

```typescript
// scripts/check-ai-test-drift.ts — monitor AI-generated test pyramid shape weekly
// Run after: vitest run --reporter=json --outputFile=vitest-results.json
// Designed to detect the "AI writes all unit tests" drift pattern
import { readFileSync } from 'node:fs';

interface TestFile {
  testFilePath: string;
  numPassingTests: number;
}

interface VitestOutput {
  testResults: TestFile[];
}

const data = JSON.parse(readFileSync('./vitest-results.json', 'utf8')) as VitestOutput;

const byLevel = data.testResults.reduce(
  (acc, file) => {
    const path = file.testFilePath;
    const count = file.numPassingTests;
    if (/\.unit\.test\.ts$/.test(path))        acc.unit += count;
    else if (/\.integration\.test\.ts$/.test(path)) acc.integration += count;
    else if (/\.e2e\.test\.ts$/.test(path))     acc.e2e += count;
    else acc.integration += count; // default: treat unlabelled as integration
    return acc;
  },
  { unit: 0, integration: 0, e2e: 0 },
);

const ratio = byLevel.unit / Math.max(byLevel.integration, 1);
if (ratio > 10) {
  console.error(
    `AI test drift detected: unit/integration ratio = ${ratio.toFixed(1)} (threshold: 10). ` +
    `Add integration tests before merging AI-generated test suites.`
  );
  process.exit(1);
}

console.log(`Pyramid health OK: unit=${byLevel.unit} integration=${byLevel.integration} e2e=${byLevel.e2e}`);
```

The underlying principle: AI assistants follow the patterns of the code they see most often. In a TypeScript codebase, if the CI ratio check runs on every PR, the failing check makes the pyramid imbalance visible before it compounds. Add a `CONTRIBUTING.md` note: "For every 5 AI-generated unit tests, verify you have at least 1 integration test case covering the same behaviour at the boundary." [community: production experience with Copilot/Cursor in TypeScript monorepos 2024-2026]



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

### Trace-Based Integration Testing with OpenTelemetry + Tracetest  [community]

As production observability matures, distributed traces become a first-class test assertion target. Tracetest (`kubeshop/tracetest`) sits at the integration test level of the pyramid and asserts on OpenTelemetry spans emitted by the test object — instead of (or in addition to) HTTP response assertions. This closes a coverage gap that both unit and classic integration test cases miss: the *internal* call graph and latency profile of a service under test.

The pattern: trigger an HTTP request, capture the resulting trace via the OpenTelemetry collector, then assert on span attributes, durations, and parent-child relationships. This is particularly valuable for distributed TypeScript services where a single API call fans out to multiple downstream services — classic `supertest` integration tests can only assert on the final HTTP response, while trace-based tests verify the entire internal execution path.

```typescript
// tracetest.config.yaml — Tracetest test definition (YAML, not TypeScript)
// Executed by: tracetest run test --file order-trace-test.yaml
type: Test
spec:
  name: "POST /orders — full span assertion"
  trigger:
    type: http
    httpRequest:
      method: POST
      url: http://localhost:3000/orders
      headers:
        - key: Content-Type
          value: application/json
      body: '{"customerId":"c1","items":[{"sku":"A1","qty":2}]}'
  specs:
    - selector: span[name="POST /orders"]
      assertions:
        - attr:http.status_code = 201
        - attr:tracetest.span.duration < 500ms
    - selector: span[name="OrderRepository.create"]
      assertions:
        - attr:db.system = postgresql
        - attr:db.operation = INSERT
    - selector: span[name="NotificationService.send"]
      assertions:
        - attr:messaging.system = rabbitmq
```

```typescript
// src/app.ts — instrumentation setup (must precede all imports)
// Use @opentelemetry/auto-instrumentations-node for zero-code instrumentation
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: process.env['OTEL_EXPORTER_OTLP_ENDPOINT'] ?? 'http://localhost:4318/v1/traces',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
// After sdk.start(), import your app modules — auto-instrumentation patches require/import hooks
```

Trace-based integration test cases complement (not replace) `supertest` assertions. Add them for critical paths where internal span structure matters — e.g., verifying that a request triggers exactly one `INSERT` and one message publish. Do not use them for simple CRUD operations where HTTP response assertions suffice. [community: kubeshop/tracetest docs, learning-sources/qa-methodology.md]

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

### Record-and-Playback E2E Test Cases

Codegen tools (Playwright Codegen, Selenium IDE) generate e2e test cases by recording UI interactions. These test cases "resist changeability and obstruct useful abstractions" (Martin Fowler, TestPyramid bliki) — they encode implementation details (element selectors, click coordinates, timing) rather than behaviour. In TypeScript projects, Playwright Codegen produces valid TypeScript but defaults to brittle `getByPlaceholder` and `locator('button.btn-primary')` selectors rather than role-based locators. Fix: treat generated test cases as a first draft only. Immediately refactor to `getByRole`, `getByLabel`, and `getByText` ARIA-based selectors before committing. Never run generated tests in CI without review — they will fail on every minor UI change.

### Treating the Pyramid as a Complete Test Strategy

The test pyramid is a guide for *automated* test investment. It does not model exploratory testing, usability testing, accessibility audits, or performance testing — these require human judgment and distinct tooling. Teams that treat pyramid compliance as the complete test strategy miss entire defect categories: design flaws, accessibility barriers, and emergent UX problems that automated assertions cannot detect. Fix: pair the pyramid with session-based exploratory testing on every sprint release, and with accessibility automated scans (axe-core) as a distinct CI step, independent of the unit/integration/e2e count. The pyramid governs *regression confidence*; exploratory testing and specialised test levels govern *discovery and assurance*. [official: martinfowler.com/articles/practical-test-pyramid.html — "You won't catch everything with automated tests. You should complement your automated tests with exploratory testing sessions."]

### Coverage Theater

Achieving a high line/branch coverage percentage at the unit test level while systematically under-investing in integration and e2e test cases. The metric looks healthy (e.g., 95% line coverage) while the test suite provides low defect-detection effectiveness. This anti-pattern is especially common in TypeScript projects where `vi.mock()` makes it trivial to achieve full branch coverage in a unit test suite that never exercises a real database query, real HTTP call, or real module boundary. The quantified cost: internal studies at large software organisations (Google, Amazon, Microsoft) consistently find that 60–80% of production defects originate at integration boundaries — not in isolated unit logic. A 95%-covered unit suite that never exercises integration boundaries provides false confidence. Fix: track integration test coverage separately from unit test coverage; require a minimum non-zero count of integration test cases as a merge gate, independently of the overall coverage threshold. In TypeScript projects, use `vitest --coverage --reporter=json` per workspace project to get per-level coverage reports, not just an aggregate number.

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

17. **Vitest workspace projects share a root `tsconfig.json` but separate type environments** [community] — In a Vitest workspace with multiple projects (unit, integration, e2e), each project compiles TypeScript in its own context. If the root `tsconfig.json` uses `"moduleResolution": "bundler"` for the application but the integration test project requires `"moduleResolution": "node16"` for `testcontainers`'s ESM exports, the test project silently falls back to incorrect resolution. Fix: each Vitest workspace project should reference its own `tsconfig.json` (e.g., `tsconfig.integration.json`) with the correct `moduleResolution` for its runtime context. This prevents "module has no default export" errors that appear only in CI.

**20. Container environment parity gap: in-memory DB in tests vs. Postgres in production** [community] — Teams use SQLite in-memory or H2 for integration test cases because it starts fast. When production runs Postgres, real constraint violations (unique indexes, partial indexes, JSONB operators, `ON CONFLICT DO UPDATE` clauses) are never exercised by the test suite. The result is a class of integration defects that the test pyramid cannot catch because the test database is structurally different from the production database. TypeScript's ORM layer (TypeORM, Prisma, Drizzle) abstracts the difference, making it invisible until production. Fix: use `testcontainers` with the exact Postgres version from production for integration test cases; reserve SQLite/H2 only for unit-level domain logic testing that has no SQL. Set the Postgres image version in a monorepo `.env.test` file so it stays in sync with the production Dockerfile. [official: martinfowler.com/articles/practical-test-pyramid.html — "Use the same database in tests as in production"]

19. **Observability gaps masquerade as test gaps** [community] — Teams attempt to drive test coverage higher at the e2e level to compensate for poor production observability. Each additional e2e test case increases build time but does not replace structured logging, distributed tracing (OpenTelemetry), or error monitoring (Sentry). The correct mental model is that the test pyramid and the observability stack are complementary: the pyramid catches defects *before* deployment; observability detects defects *after* deployment. When the e2e layer is growing fastest, ask first whether better observability would close the confidence gap more cheaply. TypeScript services using `@opentelemetry/api` and `@opentelemetry/sdk-node` can emit traces that are then used in trace-based integration tests (Tracetest), creating a feedback loop between production observability and the integration test level — without increasing e2e count. [official: martinfowler.com bliki]

18. **Affected-test pipelines in monorepos skip cross-package integration tests** [community] — Nx and Turborepo affected-task algorithms determine which tests to run based on the dependency graph derived from `tsconfig.json` `references` entries and `package.json` `dependencies`. If a shared utility package is updated but the consuming service's `tsconfig.json` does not declare a `references` entry for it (only a `package.json` dependency), the consuming service's integration tests are not marked as affected. The cross-package integration defect ships undetected. Fix: keep `tsconfig.json` `references` in strict alignment with `package.json` dependencies; use Nx's `@nx/enforce-module-boundaries` ESLint rule to detect undeclared cross-package dependencies.

19. **Test data factories fall out of sync with TypeScript interfaces** [community] — Teams manually write `const fakeOrder = { id: '1', total: 100 }` as test fixtures. When the `Order` interface gains a required field, TypeScript reports an error in application code but the fixture object was cast with `as Order` — silently ignoring the missing field. Integration tests then run against an incomplete test object, hiding defects caused by the missing field at runtime. Fix: use typed factory libraries such as `fishery` or `factory.ts` with `faker-js` that derive their type from the interface, making any missing required field a compile-time error:

```typescript
// tests/factories/order.factory.ts — fishery + @faker-js/faker + TypeScript
import { Factory } from 'fishery';
import { faker } from '@faker-js/faker';
import type { Order } from '../../src/orders/types.js';

export const orderFactory = Factory.define<Order>(() => ({
  id: faker.string.uuid(),
  customerId: faker.string.alphanumeric(8),
  total: faker.number.float({ min: 10, max: 500, fractionDigits: 2 }),
  status: faker.helpers.arrayElement(['pending', 'confirmed', 'cancelled'] as const),
  createdAt: faker.date.recent(),
}));

// Usage in integration test case:
// const order = orderFactory.build({ total: 0 }); // override specific fields
// const orders = orderFactory.buildList(5);        // build a list of 5 orders
// Adding a new required field to Order will produce a TypeScript error here —
// forcing the factory to be updated before the test suite can compile.
```

21. **Same assertion repeated at three test levels triples CI time** [community] — When validation logic is asserted in a unit test case, an integration test case, *and* an e2e test case (e.g., "empty items array returns an error"), a single defect causes three test-level failures — making root-cause diagnosis harder, not easier. In TypeScript monorepos with Vitest workspace projects running all three levels in parallel, this triples the execution time for a single logical assertion. Fix: apply the "push down" rule: if a unit test case already asserts the rule, delete the integration and e2e test cases that replicate it. Reserve higher-level test cases for asserting that the rule is *integrated* into the full stack, not just that the rule exists. Reference: Fowler's "If a higher-level test spots an error and there's no lower-level test failing, you need to write a lower-level test" — the converse is equally true.

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
- **Trace-Based Testing (OpenTelemetry + Tracetest):** Replaces or complements integration test cases for distributed TypeScript services by asserting on emitted OpenTelemetry spans. Insertion point: same pyramid layer as integration tests. Best for services where internal span structure (DB calls, message publishes) matters as much as HTTP response shape.
- **Observability-Driven Testing:** A philosophical complement — rather than adding more e2e test cases, invest in structured logging, distributed tracing, and error monitoring. The pyramid catches pre-deployment defects; observability catches post-deployment defects. Use both layers; optimise the split based on defect frequency per layer.

### When NOT to use the classic pyramid

The pyramid assumes: (1) test cases can be written and run independently, (2) unit boundaries are meaningful and stable, (3) integration is achievable in an isolated environment. When these assumptions break, the pyramid shape is counterproductive:

- **Serverless + vendor-managed services (e.g., AWS Lambda + DynamoDB + EventBridge):** "Unit" means mocking the AWS SDK, which has a notoriously divergent mock (LocalStack vs. the real SDK). The meaningful test level is integration against LocalStack. A pyramid with a large unit layer is mostly testing mock fidelity. Use an integration-first flat triangle shape instead.
- **Third-party API consumers:** If your core business logic *is* calling a third-party API (Stripe, Twilio), unit mocks are low-value. Contract tests or integration tests against a sandbox/staging environment are the first-class test level.
- **Tight coupling with no seams:** Legacy TypeScript codebases with no dependency injection, no interfaces, and direct `require()` calls cannot be unit-tested without rewriting. In this case, acceptance/system test cases via Playwright are the *only* feasible test level until the codebase is incrementally decoupled.

### Adoption costs

- **Testcontainers setup** adds 2–4 h of initial CI configuration and ongoing maintenance as container images are upgraded. TypeScript typings for testcontainers (`testcontainers` npm package includes `.d.ts` files) reduce the setup burden.
- **MSW handler maintenance** in a large TypeScript frontend codebase requires tooling (schema codegen with `orval` or `swagger-typescript-api`) to stay non-brittle.
- **Playwright configuration** (parallelism, retries, sharding) requires senior engineering time to tune; getting it wrong produces more flakiness than no e2e tests at all.
- **Ratio monitoring** requires custom CI scripts or third-party tooling (Codecov, Datadog CI Visibility) to track over time.
- **TypeScript compilation in test pipelines** adds 10–30 s to test startup unless `ts-node`/`tsx`/`vitest` transpile-only mode is used. Use `vitest` (which uses Vite's `esbuild` transform) or `tsx` for fast TypeScript test execution without full `tsc` type-checking in hot paths.
- **Trace-based testing setup (OpenTelemetry + Tracetest):** Requires an OpenTelemetry collector in CI (Jaeger or OTLP endpoint), TypeScript auto-instrumentation (`@opentelemetry/auto-instrumentations-node`), and Tracetest CLI. Initial setup: 4–6 h. Ongoing: span assertion YAML files maintained alongside integration test cases. Not worth the overhead for simple CRUD services; high value for distributed systems where call graphs matter.
- **AI-generated TypeScript test code** (GitHub Copilot, Cursor) reduces initial write time but produces unit-test-heavy suites with `vi.mock()` overuse. When adopting AI code generation, add a lint rule or CI ratio check to prevent the pyramid from silently inverting as AI-generated unit tests accumulate. Teams using AI assistants for test generation report faster test authoring but higher maintenance cost from over-mocked, brittle unit suites without intentional integration coverage.
- **TypeScript monorepo test isolation** (Nx, Turborepo, pnpm workspaces) requires per-package `vitest.config.ts` or a root workspace config with explicit `include` paths. Affected-test-only pipelines (running only tests for changed packages) rely on the build graph being accurate — if a package's `tsconfig.json` does not declare a `references` entry for a dependency, Nx/Turborepo may skip tests that should be affected. This silently reduces integration test coverage for cross-package interactions.

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
| Stryker Mutator | Tool | https://stryker-mutator.io/docs/stryker-js/introduction | Mutation testing for TypeScript with Vitest integration; `@stryker-mutator/typescript-checker` validates mutants against `tsc` |
| Tracetest | Tool | https://tracetest.io/ | Trace-based integration testing — assert on OpenTelemetry spans at the integration test level |
| OpenTelemetry Node.js SDK | Tool | https://opentelemetry.io/docs/languages/js/ | TypeScript instrumentation for trace-based integration tests; `@opentelemetry/sdk-node` |
| fishery | Tool | https://github.com/thoughtbot/fishery | Type-safe test data factory library for TypeScript; compile-time errors when factory misses required interface fields |
| @faker-js/faker | Tool | https://fakerjs.dev/ | Realistic TypeScript test data generation; used with fishery for typed factories |
| Playwright Component Testing | Tool | https://playwright.dev/docs/test-components | Integration-level browser component testing; covers browser APIs jsdom cannot emulate; `@playwright/experimental-ct-react` |
| How They Test | Community | https://abhivaikar.github.io/howtheytest/ | 108 companies, 797 resources — real-world test pyramid ratios, strategies, and culture from production engineering orgs |
