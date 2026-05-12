# Test Pyramid — QA Methodology Guide
<!-- lang: TypeScript | topic: test-pyramid | iteration: 39 | score: 100/100 | date: 2026-05-12 -->
<!-- sources: training-knowledge synthesis + WebFetch: martinfowler.com (2026-05-03, 2026-05-12) | new: howtheytest (108 companies real-world test strategies) -->
<!-- official refs: martinfowler.com/bliki/TestPyramid.html, martinfowler.com/articles/practical-test-pyramid.html, martinfowler.com/articles/microservice-testing/ -->
<!-- community refs: kentcdodds.com/blog/write-tests, testing.googleblog.com, Spotify Engineering Blog, martinfowler.com/articles/2021-test-shapes.html -->
<!-- new (2026-05-12): Fowler 5-layer microservice strategy (component test level), Neon DB branch isolation, Vitest defineProject + extends API, Google "Construct with Collaborators" principle, "Fantastical Shapes" quality-over-ratio insight -->
<!-- new (2026-05-12 iter 33): Vitest 3.x inline workspace config, multi-browser instances API, Playwright 1.50+ Clock API + tsconfig option + Aria Snapshots, TypeScript 7.0 migration implications for test pipelines, Test Double taxonomy per pyramid level (Classical vs Mockist TDD), Fowler TestDouble taxonomy at pyramid layers -->
<!-- new (2026-05-12 iter 34): Vitest 4.0 (Oct 2025) + 4.1 (Mar 2026) — browser mode stable, toMatchScreenshot, expect.schemaMatching (Zod/Valibot), test tags with --tags-filter, aroundEach/aroundAll hooks, --detect-async-leaks, viteModuleRunner:false; Playwright v1.51-v1.60 — test.abort(), await using teardown, --only-changed, ARIA snapshot on page object, toContainClass(), testProject.teardown, locator.normalize(), page.pickLocator() -->
<!-- new (2026-05-12 iter 35): TypeScript 6.0 breaking default changes (types:[], strict:true, module:esnext, rootDir:.) — silent test pipeline breakage; Vitest 5.0.0-beta.2 (May 5, 2026) — inline expect, sequential removal, directory restructure; Playwright v1.60 HAR tracing API (tracing.startHar) + locator.drop() drag-and-drop; Google "The Way of TDD" (Mar 2026) blog post -->
<!-- new (2026-05-12 iter 36): Vitest 3.2 (Jun 2025) — Annotation API, Scoped Fixtures (scope:file|worker), explicit resource management (using vi.spyOn), Test Signal API (AbortSignal), multi-project sequence.groupOrder, watchTriggerPatterns, workspace→projects deprecation; TypeScript 5.8 — --module node18 stable, import with {type:"json"}, watch mode perf; Playwright v1.51 storageState({indexedDB:true}) for IndexedDB auth; Vitest 4.1.4+ browser locators exact option + Aria snapshots in browser mode -->
<!-- new (2026-05-12 iter 37): Playwright v1.56-v1.60 series — Agents (planner/generator/healer AI agents for e2e test creation/maintenance), v1.57 Speedboard HTML reporter tab + testConfig.webServer.wait named capture groups + Chrome for Testing + Service Worker BrowserContext routing, v1.59 page.screencast API + browser.bind(), v1.60 browser.on('context') + getByRole description option + toHaveCSS pseudo option + testInfoError.errorContext + webSocketRoute.protocols(); Vitest 4.1 — vi.defineHelper (custom assertion stack traces), coverage.changed (coverage only for changed files), page.mark()/locator.mark() trace annotations; TypeScript 6.0 — esModuleInterop always true (breaks import * as X patterns in test files), #/ subpath imports shorthand; new community gotchas: AI agent test generation pyramid governance, WebSocket testing at integration level, Service Worker test gaps, Playwright Agents healer loop gotcha -->
<!-- new (2026-05-12 iter 38): Node.js v22.18.0 (Jul 2025) — TypeScript type stripping on by default (no flag needed on Node 22.18+), run .ts test files with bare `node`; Node.js 24 test runner — auto-wait subtests (BREAKING: t.test() no longer returns Promise), global setup/teardown, per-test --test-timeout, JSON module mocking; Node.js native TS limitations for test files: no enums, no decorators, no parameter properties, no legacy namespaces; Vitest 4.1 — mockThrow/mockThrowOnce API, GitHub Actions Job Summary reporter with flaky-test highlighting + permalink URLs, agent reporter mode (AI coding agents), Vite 8 dependency deduplication, browser mode locator strict-mode enforcement; Vitest 5.0 beta additional: multi-environment merge reports (non-sharded), configDefaults.reporters, logger.formatError, JUnit jest-junit-compatible naming, locator-as-object representation; Vitest 3.2 — custom project name colors, locators.extend browser API, V8 AST-aware coverage remapping, watchTriggerPatterns for non-static file relationships; community gotchas: Node.js native TS execution fails for NestJS (decorators unsupported), Node.js 24 t.test() promise removal breaks existing pipelines, Vitest 4.1 strict browser locators catch multi-match bugs silently hidden before -->
<!-- new (2026-05-12 iter 39): Node.js 24.14.0 LTS (Mar 2026) — `expectFailure` test option for explicitly marking xfail test cases in the built-in test runner (analogous to pytest's @pytest.mark.xfail); `env` option on the `run()` function for per-invocation environment variables; community gotcha: `expectFailure` at the integration level — using `expectFailure` as a quarantine mechanism without fixing the root cause accumulates known failures that are never addressed -->

---

> **Quick reference:** Unit (fast, isolated, < 10 ms) → Integration (real I/O, no browser) → System/E2e (full stack, browser or API). Ratio heuristic: 70/20/10. Alternatives: Testing Trophy (Dodds) for React/TypeScript UI, Honeycomb (Spotify) for microservices, Google Small/Medium/Large for distributed systems. Top TypeScript anti-patterns: `vi.mock() as any`, skipping integration layer because "TypeScript caught it", ignoring path alias config in test runner, record-and-playback e2e generators, AI-generated unit suites without integration counterparts. New patterns (2026): Trace-based integration testing (OpenTelemetry + Tracetest), AI pyramid shape governance, container DB parity, Neon DB branch-per-test-run isolation, Fowler 5-layer microservice pyramid (adds component test level). New patterns (2026 iter 33): Test Double taxonomy by level (Classical=integration, Mockist=unit), Vitest 3.x inline workspace + multi-browser instances, Playwright 1.50+ Clock API + Aria Snapshots + tsconfig option, TypeScript 7.0 migration preparation (`--stableTypeOrdering`, deprecated option removal, native TS port 10-15x speedup). New patterns (2026 iter 34): Vitest 4.0 browser mode stable + `toMatchScreenshot` visual regression + `expect.schemaMatching` (Zod/Valibot) + test tags + `aroundEach` hooks; Playwright v1.60 `test.abort()` + ARIA snapshot on page + `await using` teardown + `--only-changed`. New patterns (2026 iter 35): TypeScript 6.0 silently breaks test `tsconfig.json` (`types` defaults to `[]`, `strict` defaults to `true`, `module` defaults to `esnext`, `rootDir` defaults to `.`) — most test configs need explicit opt-ins after upgrading; Vitest 5.0.0-beta.2 (May 5, 2026) in active development — inline expect package, `sequential` removal, `.vitest/` directory restructure; Playwright v1.60 adds `tracing.startHar()` first-class HAR API + `locator.drop()` for drag-and-drop e2e tests. New patterns (2026 iter 36): Vitest 3.2 — Annotation API (structured test metadata for JUnit/HTML reporters), Scoped Fixtures (`scope:'file'|'worker'` in `test.extend`), `using vi.spyOn()` automatic spy restore, Test Signal API (AbortSignal for timeout cleanup), `sequence.groupOrder` replaces `&&`-chained CI commands for fail-fast ordering; TypeScript 5.8 — `--module node18` stable, `import with {type:'json'}` replaces deprecated `assert`, faster watch mode; Vitest 3.2 `workspace` config key deprecated in favour of inline `test.projects`. Key 2026 insight (Justin Searls / Fowler): "People love debating test ratios, but it's a distraction. Nearly zero teams write expressive tests that establish clear boundaries, run quickly & reliably, and only fail for useful reasons." Quality of test cases > pyramid ratio compliance. ISTQB note: the four formal test levels are unit → integration → system → acceptance; the pyramid covers the first three; acceptance test level maps to UAT/stakeholder validation and is often outside CI. New patterns (2026 iter 37): Playwright Agents (v1.56 — planner/generator/healer AI agents for e2e test creation and maintenance; pyramid governance required), Playwright v1.57 Speedboard reporter tab for identifying slow e2e tests + testConfig.webServer.wait named capture groups + Chrome for Testing + Service Worker BrowserContext routing, Playwright v1.59 page.screencast API, Playwright v1.60 browser.on('context') + getByRole description option + toHaveCSS pseudo-element option + webSocketRoute.protocols() for WebSocket integration tests + testInfoError.errorContext improved failure diagnostics; Vitest 4.1 vi.defineHelper (clean stack traces in custom assertions) + coverage.changed (per-PR coverage delta without slowing CI) + page.mark()/locator.mark() trace annotations in browser mode; TypeScript 6.0 esModuleInterop always true breaks legacy `import * as X` in test files + #/ subpath import shorthand. New patterns (2026 iter 38): Node.js v22.18.0 (Jul 2025) — TypeScript type stripping on by default, run `.ts` unit test files with bare `node` (no transpiler); Node.js 24 test runner — auto-wait subtests (BREAKING: `t.test()` no longer returns Promise), global setup/teardown, per-test `--test-timeout`; Node.js native TS limitations: no enums, no decorators, no parameter properties — NestJS integration tests cannot use bare `node`; Vitest 4.1 — `mockThrow`/`mockThrowOnce` for cleaner unit error scenarios, GitHub Actions Job Summary reporter (flaky-test highlighting + permalink URLs), agent reporter mode (AI coding tools get minimal output); Vitest 5.0 beta — multi-environment merge reports (non-sharded), JUnit jest-junit naming, `configDefaults.reporters`; Vitest 3.2 — `locators.extend` browser API, V8 AST-aware coverage, `watchTriggerPatterns`. New patterns (2026 iter 39): Node.js 24.14.0 LTS (Mar 2026) — `expectFailure` option on test cases in `node:test` (xfail semantics; treat as time-boxed quarantine only, not permanent), `env` option on `run()` for per-invocation environment variables without mutating `process.env`; community gotcha: using `expectFailure` as permanent quarantine accumulates dead-weight integration test failures that never get fixed.

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

### Vitest `defineProject` with Type-Safe Workspace Configuration  [community]

Vitest's projects API (introduced as the successor to `defineWorkspace` in newer Vitest versions) provides `defineProject` for inline project configurations with TypeScript validation that rejects unsupported options at compile time. The `extends: true` option inherits root-level settings, preventing duplication. Use `--project` CLI flag to run individual levels in CI fail-fast order.

```typescript
// vitest.config.ts — root-level config using the projects API (Vitest 2.x+)
// Use defineProject for per-project type safety; extends: true inherits root settings
import { defineConfig, defineProject } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
    },
    projects: [
      defineProject({
        // Unit tests: pure logic, no I/O, fast
        extends: true,      // inherit root plugins (tsconfigPaths) and coverage config
        test: {
          name: 'unit',
          include: ['src/**/*.unit.test.ts'],
          environment: 'node',
          testTimeout: 5_000,
        },
      }),
      defineProject({
        // Integration tests: real DB/HTTP, isolated container or in-memory
        extends: true,
        test: {
          name: 'integration',
          include: ['src/**/*.integration.test.ts', 'tests/integration/**/*.test.ts'],
          environment: 'node',
          testTimeout: 60_000,
          pool: 'forks',    // separate process per file — prevents module-cache pollution
        },
      }),
      defineProject({
        // E2e tests: full stack via browser or HTTP; run last in CI
        extends: true,
        test: {
          name: 'e2e',
          include: ['e2e/**/*.e2e.test.ts'],
          environment: 'node',
          testTimeout: 120_000,
          bail: 1,          // stop after first failure — expensive to run all
        },
      }),
    ],
  },
});
```

CI fail-fast pipeline: `vitest run --project unit && vitest run --project integration && vitest run --project e2e`. The `defineProject` approach over inline objects catches configuration errors at TypeScript compile time — for example, attempting to set `coverage` inside a project config (which is root-only) will produce a compile error rather than a silent no-op. [official: vitest.dev/guide/projects]

---

### Fowler 5-Layer Microservice Test Strategy  [community]

Martin Fowler's *Testing Strategies in a Microservice Architecture* (Toby Clemson, 2014; indexed in learning-sources 2026-05-12) extends the three-layer pyramid to five layers for microservice architectures. The additional layers — **component tests** and **contract tests** — address the unique challenge that each microservice has both internal logic *and* external API contracts that must be tested independently.

The five layers from base to apex:

| Layer | Scope | Tool | TypeScript example |
|-------|-------|------|--------------------|
| Unit | Single class/function, all dependencies stubbed | Vitest | `*.unit.test.ts` |
| Integration | Real I/O to external stores (DB, cache, queue) | testcontainers + Vitest | `*.integration.test.ts` |
| Component | The service as a whole, with external dependencies stubbed at the network boundary | Supertest + MSW | `*.component.test.ts` |
| Contract | Provider/consumer API contract verification, decoupled from full service runtime | Pact | `*.pact.test.ts` |
| End-to-end | Multiple services running together, user journey validation | Playwright | `e2e/*.e2e.test.ts` |

The **component test level** is the key addition. It sits between integration and contract: the full service binary is exercised (DI container, middleware, routing, validation) but *all external network calls* are intercepted at the HTTP layer using MSW or Nock. This isolates the service's own behaviour from the availability or behaviour of its dependencies.

```typescript
// tests/component/orders.component.test.ts
// Component test: full Express app in-process, external services stubbed at HTTP boundary
// Uses supertest (exercises full routing stack) + MSW (stubs inventory-service HTTP calls)
import { beforeAll, afterAll, afterEach, it, expect } from 'vitest';
import request from 'supertest';
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';
import { buildApp } from '../../src/app.js';
import { createTestDb, type TestDb } from '../helpers/db.js';
import type { Express } from 'express';
import type { CreateOrderInput, OrderResponse } from '../../src/orders/types.js';

// Stub the external inventory-service dependency at the HTTP boundary
const mswServer = setupServer(
  http.get('http://inventory-service/items/:sku', ({ params }) => {
    return HttpResponse.json({ sku: params['sku'], available: true, stock: 100 });
  }),
);

let app: Express;
let db: TestDb;

beforeAll(async () => {
  mswServer.listen({ onUnhandledRequest: 'error' });
  db = await createTestDb();   // real DB (SQLite in-memory for component test speed)
  app = buildApp({ db });      // full DI container, middleware, and routes
});

afterAll(async () => {
  mswServer.close();
  await db.destroy();
});

afterEach(() => {
  mswServer.resetHandlers();
  db.truncate('orders');
});

it('POST /orders integrates routing, validation, DB, and external inventory stub', async () => {
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
  expect(body).toMatchObject<Partial<OrderResponse>>({ status: 'pending' });
});

it('returns 503 when inventory-service is unavailable', async () => {
  // Override the stub to simulate downstream failure
  mswServer.use(
    http.get('http://inventory-service/items/:sku', () => {
      return HttpResponse.error();
    }),
  );

  const res = await request(app)
    .post('/orders')
    .send({ customerId: 'c1', items: [{ sku: 'A1', qty: 1 }] });

  expect(res.status).toBe(503);
});
```

The component test level sits at the top of the automated test investment in a microservice: it catches the largest class of defects (routing, middleware, DI wiring, validation, serialisation) without the instability of a live external service. In a TypeScript NestJS service, the component test uses `@nestjs/testing`'s `TestingModule` with real TypeORM configuration (SQLite in-memory) and MSW interceptors for external HTTP dependencies. This closely mirrors the Honeycomb's "integrated test" concept but at the single-service boundary. [official: martinfowler.com/articles/microservice-testing/]

---

### Neon DB Branch-Per-Test-Run for Integration Test Isolation  [community]

For TypeScript services deployed to cloud-native environments (Vercel, Railway, Render), Neon's copy-on-write Postgres branching provides an alternative to testcontainers for the integration test DB layer. Instead of spinning up a container, each CI run branches from a known schema snapshot — the branch is instant (copy-on-write, no data copy unless mutated), and is deleted after the test run. This eliminates container start-up time while retaining real Postgres semantics.

```typescript
// tests/helpers/neon-branch.ts — branch lifecycle helper for Neon integration tests
// Requires: NEON_API_KEY, NEON_PROJECT_ID env vars (set in CI secrets)
// npm install @neondatabase/serverless
import { neon } from '@neondatabase/serverless';

export interface NeonTestBranch {
  branchId: string;
  connectionString: string;
  cleanup: () => Promise<void>;
}

export async function createTestBranch(branchName: string): Promise<NeonTestBranch> {
  const apiKey = process.env['NEON_API_KEY'];
  const projectId = process.env['NEON_PROJECT_ID'];

  if (!apiKey || !projectId) {
    throw new Error('NEON_API_KEY and NEON_PROJECT_ID must be set for integration tests');
  }

  // Create a branch via the Neon Management API
  const createRes = await fetch(
    `https://console.neon.tech/api/v2/projects/${projectId}/branches`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        endpoints: [{ type: 'read_write' }],
        branch: { name: branchName, parent_id: 'main' },
      }),
    },
  );

  if (!createRes.ok) {
    throw new Error(`Failed to create Neon branch: ${await createRes.text()}`);
  }

  const data = (await createRes.json()) as {
    branch: { id: string };
    endpoints: Array<{ host: string }>;
    connection_uris: Array<{ connection_uri: string }>;
  };

  const branchId = data.branch.id;
  const connectionString = data.connection_uris[0]!.connection_uri;

  const cleanup = async (): Promise<void> => {
    await fetch(
      `https://console.neon.tech/api/v2/projects/${projectId}/branches/${branchId}`,
      { method: 'DELETE', headers: { Authorization: `Bearer ${apiKey}` } },
    );
  };

  return { branchId, connectionString, cleanup };
}

// Usage in vitest integration test:
// import { createTestBranch } from '../helpers/neon-branch.js';
// let branch: NeonTestBranch;
// beforeAll(async () => {
//   branch = await createTestBranch(`test-run-${Date.now()}`);
//   // Use branch.connectionString as DATABASE_URL for the test
// }, 30_000);
// afterAll(() => branch.cleanup());
```

When to use Neon branching vs testcontainers:
- **Neon branching**: Cloud-native TypeScript projects already using Neon Postgres in production; want instant branch creation without Docker in CI; Vercel/Railway preview environments where Docker-in-Docker is unavailable.
- **testcontainers**: On-premise CI (Jenkins, self-hosted GitHub Actions); need exact Postgres version parity; prefer self-contained tests with no external service dependency.

The branch-per-CI-run pattern replaces the "container DB parity gap" anti-pattern (gotcha #20) — because the test branch is a real Neon Postgres instance (same engine, same constraints, same JSONB operators) at the exact schema state of the parent branch. [official: neon.com/docs/guides/branching-test-queries]

---

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

22. **Pyramid-ratio obsession crowds out test quality improvement** [community] — Teams that enforce 70/20/10 as a hard gate spend engineering cycles moving test cases between directories to hit the ratio, rather than improving the expressiveness, clarity, and reliability of the tests themselves. Justin Searls (2021, cited by Fowler in "On the Diverse And Fantastical Shapes of Testing") captures this: "People love debating what percentage of which type of tests to write, but it's a distraction. Nearly zero teams write expressive tests that establish clear boundaries, run quickly & reliably, and only fail for useful reasons." In TypeScript projects, ratio compliance with low-quality mocks (as any casts, brittle assertions on implementation details) provides less value than a smaller set of well-structured, expressive test cases. Fix: treat ratio metrics as a diagnostic signal (is the shape grotesquely inverted?) rather than a compliance target; invest the saved engineering time in test review and documentation. [community: martinfowler.com/articles/2021-test-shapes.html]

23. **Passing real collaborators at the wrong test level defeats isolation** [community] — Google Engineering (2026, "Construct with Collaborators, Call with Work") distinguishes between constructing objects with real collaborators (appropriate for integration and component test levels) vs. calling methods with real work (appropriate for unit tests where the work should be stubbed). Teams that violate this boundary — e.g., passing a live `OrdersService` with a real DB connection into a unit test — accidentally raise their unit tests to the integration test level, with all the attendant start-up cost and flakiness, without any of the explicit lifecycle management (beforeAll/afterAll, container cleanup) that integration tests require. Fix: in TypeScript, define collaborators as interfaces and inject real implementations at the integration test level; inject `vi.fn()` doubles at the unit test level. The structural signal: if your unit test's `beforeAll` connects to a database, it is an integration test and should be in `*.integration.test.ts`. [community: testing.googleblog.com — "Construct with Collaborators, Call with Work", May 2026]

24. **Classical vs Mockist TDD mismatch within a team causes test suite incoherence** [community] — Teams where some engineers apply Classical TDD (use real collaborators; prefer fakes) and others apply Mockist TDD (mock every collaborator) in the same test suite produce an incoherent pyramid: some files have real DB connections marked as unit tests (`*.unit.test.ts`), others have every dependency mocked marked as integration tests (`*.integration.test.ts`). The naming convention becomes meaningless, pyramid shape metrics are unreliable, and CI fail-fast ordering breaks. Fix: define an explicit team policy — Classical at integration level, Mockist at unit level — and add a lint rule or code review checklist item that flags unit test files importing `DataSource`, `Pool`, or network client constructors directly (a sign of Classical-style test in a Mockist-labelled file). [community: Fowler — Mocks Aren't Stubs; martinfowler.com/articles/mocksArentStubs.html]

25. **Vitest 3.x inline workspace config and legacy `vitest.workspace.ts` coexistence** [community] — Vitest 3.0 supports both the old `vitest.workspace.ts` file and the new inline `test.projects` array. Teams that have both simultaneously get surprising precedence behaviour: if both exist, Vitest 3.x prefers the `test.projects` inline config and silently ignores the workspace file — without a warning. Teams migrating incrementally may end up running a different set of test projects than expected. Fix: delete `vitest.workspace.ts` after migrating to inline `test.projects`; add a CI check that fails if both files exist (a simple `ls vitest.workspace.* 2>/dev/null | wc -l` check in `.github/workflows` suffices). [official: vitest.dev/guide/projects — "workspace file is no longer needed when using inline projects configuration"]

26. **TypeScript 7.0 `--stableTypeOrdering` adds 25% tsc overhead before it removes 90%** [community] — Teams enabling `--stableTypeOrdering` in tsconfig to prepare for TS 7.0's parallel checker find that the CI type-check step slows noticeably — the stable ordering trades a small overhead now for the performance leap of TS 7.0's native parallel checker later. If the team is not close to upgrading to TS 7.0, deferring this flag is reasonable. Add a TODO comment in `tsconfig.json` with the target TS 7.0 migration date so the flag is not forgotten. The performance impact varies: small codebases (<20k lines) may see no measurable difference; codebases >200k lines see the 25% increase most clearly. [official: typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html]

27. **`expect.schemaMatching` replaces parallel Zod unit tests at the integration layer** [community] — Teams running Vitest 4.x sometimes add unit test cases that only assert the shape of a Zod schema (e.g., `expect(CreateOrderSchema.parse({...})).toMatchObject(...)`) and then replicate the same assertion at the integration layer via `expect(res.body).toMatchObject({...})`. With `expect.schemaMatching`, the integration test case can assert schema compliance in-line (`expect(res.body).toEqual(expect.schemaMatching(CreateOrderSchema.partial()))`), eliminating the duplicate unit test. Apply the push-down principle: if schema compliance is already verified at the integration layer against a real HTTP response, delete the standalone unit schema test. [official: vitest.dev/blog/vitest-4.html]

28. **Vitest 4.x `--detect-async-leaks` exposes hidden inter-test pollution** [community] — After enabling `--detect-async-leaks` in Vitest 4.1, teams frequently discover that integration test cases involving NestJS `TestingModule` or typeorm `DataSource` were not properly closed in `afterAll`. The uncleaned handles caused non-deterministic failures in subsequent test files — previously misdiagnosed as "flaky tests." The fix is straightforward: ensure `module.close()` and `dataSource.destroy()` are awaited in `afterAll`. After fixing the leaks, many teams report a 20–40% reduction in their perceived flaky test count, because the flakiness was actually leak-induced pollution rather than true non-determinism. Enable `--detect-async-leaks` as a permanent CI flag at the unit and integration levels; disable it for the e2e level where Playwright manages its own browser lifecycle. [community: vitest.dev/blog/vitest-4-1.html]

29. **TypeScript 6.0 new defaults silently break test `tsconfig.json` configurations** [community] — TypeScript 6.0 changed four critical default values that most test configs relied on implicitly. Teams upgrading from TS 5.x find that `describe`, `it`, `expect`, and `process` are suddenly undefined in test files, because `types` now defaults to `[]` (previously all `@types/*` packages under `node_modules/@types` were auto-included). The three other breaking defaults: `strict` is now `true` (was `false`), `module` is now `esnext` (was derived from `target`), and `rootDir` is now `.` (was inferred from source structure). These changes require explicit opt-ins in every test `tsconfig.json`. The most common CI failure pattern: a greenfield project migrates to TS 6.0, the test suite compiles locally (IDE resolves types via project references), but CI fails with "Cannot find name 'describe'" because the bare `tsc --noEmit` invoked by CI uses the root `tsconfig.json` which now has `types: []`. Fix: update every test `tsconfig.json` or the root `tsconfig.json` (if tests share it) to include the required types explicitly:

```json
// tsconfig.json (or tsconfig.test.json) — explicit TypeScript 6.0 configuration
// Required after upgrading from TS 5.x — none of these were needed before TS 6.0
{
  "compilerOptions": {
    "strict": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "target": "es2025",
    "rootDir": "./src",
    // TS 6.0: types now defaults to [] — must list every @types/* package needed
    "types": ["node", "vitest/globals"],
    // If using Jest instead: "types": ["node", "jest"]
    // If using both: "types": ["node", "vitest/globals", "jest-extended"]
    "paths": {
      // TS 6.0: baseUrl is deprecated — use paths entries with explicit prefixes
      "@/*": ["./src/*"]
    }
  }
}
```

```json
// tsconfig.integration.json — separate config for integration test level
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    // Integration tests may need node16/nodenext for testcontainers ESM exports
    "moduleResolution": "node16",
    "types": ["node", "vitest/globals", "testcontainers"]
  },
  "include": ["src", "tests/integration", "tests/helpers"]
}
```

The `strict: true` default is usually harmless if the codebase already uses `"strict": true`, but teams that relied on the old `strict: false` default will suddenly see type errors in test files that use `any` implicitly — particularly in older test fixtures and mocks. The `rootDir: "."` default is the most structurally disruptive: if `tsconfig.json` sits at the repo root and `rootDir` previously inferred to `./src`, the new default includes `tests/` in the compilation root, which can break `outDir` paths and emit unexpected files. Fix: explicitly set `"rootDir": "./src"` and add `tests/` to `"include"` without it being part of `rootDir`. [official: typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html]

30. **Vitest 5.0 (beta) introduces breaking changes to test directory conventions and the `sequential` option** [community] — Vitest 5.0.0-beta.2 (released May 5, 2026) is the next major version. Teams maintaining custom CI scripts that interact with Vitest output artifacts should prepare now. Key breaking changes: (1) The default attachment directory has changed from `.vitest-attachements/` to `.vitest/attachments/` and the blob reporter now writes to `.vitest/blob/` — any CI script that reads these paths hardcoded will silently produce empty reports or fail. (2) The `sequential` option on `test` and `suite` has been removed in favour of `concurrent: false` — test files using `test.sequential(...)` or `suite.sequential(...)` will produce a runtime error after upgrading. (3) The `expect` package is now inlined into Vitest rather than a peer dependency — projects that imported `expect` from `'vitest/expect'` directly need to update to `'vitest'`. (4) V8 coverage now tracks `node:child_process` and `node:worker_threads` contexts — this may increase measured branch coverage for integration tests that use worker threads, which can shift coverage threshold pass/fail status. Do not upgrade to Vitest 5.0 stable in production test pipelines until the release is stable; monitor [vitest.dev/blog/vitest-5.html] for the stable announcement. Until then, pin to `vitest@^4.1` and add a TODO note to unpin when 5.0 stable lands. [community: github.com/vitest-dev/vitest/releases/tag/v5.0.0-beta.2]

31. **Vitest 3.2 `workspace` option deprecation silently changes project discovery** [community] — Vitest 3.2 deprecated the top-level `workspace` config key (which pointed to a `vitest.workspace.ts` file) to prevent naming conflicts with PNPM workspaces. Teams that have both `workspace: './vitest.workspace.ts'` in their `vitest.config.ts` *and* inline `test.projects: [...]` will find that Vitest silently prefers the inline `projects` array — the workspace file is ignored without a warning in Vitest 3.2 (a warning was added in 3.2.1). This creates a migration hazard: if the workspace file and the inline projects list differ (e.g., the workspace file includes a `components` project that wasn't yet migrated to inline), the components test suite stops running silently. Fix: after migrating to inline `test.projects`, delete `vitest.workspace.ts` *and* remove the `workspace:` key from `vitest.config.ts`. Add a CI lint step: `[ -f vitest.workspace.ts ] && echo "ERROR: stale workspace file" && exit 1`. [official: vitest.dev/blog/vitest-3-2.html — workspace deprecation note]

32. **TypeScript 5.8 `--module node18` and `import with` break legacy test setup files** [community] — TypeScript 5.8 stabilised `--module node18` (previously `--module node18` was a preview alias). For TypeScript test pipelines targeting Node.js 18+, `"module": "node18"` is now the recommended setting — it disallows `require()` of native ESM modules and enforces `with { type: "json" }` for JSON imports instead of the now-deprecated `assert { type: "json" }` form. Teams upgrading to `"module": "node18"` find two common breakages in test code: (1) test setup files that use `import config from './vitest.setup.json' assert { type: 'json' }` produce a TypeScript error — update to `with { type: 'json' }`; (2) `testcontainers` and other packages with dual CJS/ESM builds may emit `ERR_REQUIRE_ESM` under `node18` module resolution if the entry point is ESM-only. Fix for (2): use `"module": "nodenext"` instead of `"module": "node18"` in `tsconfig.integration.json` — `nodenext` allows `require()` of ESM under Node.js 22+ (which supports it via `require(esm)` stabilised in Node 22.12). Always have a separate `tsconfig.integration.json` with the integration-level module resolution rather than overriding the root `tsconfig.json`. [official: typescriptlang.org/docs/handbook/release-notes/typescript-5-8.html]

33. **TypeScript 6.0 `esModuleInterop` always true silently breaks `import * as X` patterns in test helpers** [community] — TypeScript 6.0 makes `esModuleInterop: true` the permanent, non-configurable default. Test helper files written during the `esModuleInterop: false` era (legacy Node.js boilerplate) that use `import * as path from 'path'` or `import * as supertest from 'supertest'` produce `TS2540` or `TS1202` errors after upgrading. The issue is silent in many IDEs because they apply project-level tsconfig settings correctly — the failure appears only when `tsc --noEmit` runs in CI against the root tsconfig. Teams that skip running `tsc --noEmit` before tests (relying on Vitest's esbuild transpile-only mode instead) may ship a TS-6.0-incompatible codebase without realising it. Fix: add `tsc --noEmit` as a pre-test CI step; update `import * as X from` patterns to `import X from` for CJS default exports. [official: typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html]

34. **Playwright Agents healer loop produces `sleep()`-based patches that re-introduce the `sleep()` anti-pattern** [community] — Playwright's healer agent (v1.56+) repairs failing test cases by replaying steps and suggesting patches. When a locator times out, the most common healer patch is adding a `waitForTimeout()` call — which is semantically identical to `sleep()`. Teams that auto-accept healer patches without review accumulate timing-based workarounds that mask real flakiness root causes. The anti-pattern is hard to detect after the fact because the test passes reliably on the healer's machine (which is the same machine where the timing issue occurred) but fails intermittently in CI. Fix: set a code review rule that rejects any healer patch containing `waitForTimeout()` without a comment explaining why a `waitFor*` condition-based assertion is insufficient. Prefer `waitForSelector`, `waitForURL`, `waitForResponse`, or `expect(...).toBeVisible()` with an explicit timeout over raw delay. [community: playwright.dev/docs/test-agents, Playwright Agents docs — healer section]

35. **Vitest `coverage.changed` hides integration-level coverage gaps on renamed files** [community] — The `coverage.changed` option compares changed files against the git baseline to restrict coverage reporting. When a TypeScript file is *renamed* (e.g., `order.repository.ts` → `orders.repository.ts`), git detects it as a deletion and addition rather than a modification. `coverage.changed` treats the new file as a changed file and reports its coverage, but the old file (now deleted) has its coverage history discarded. If the new file has lower coverage than the old one, the threshold check may still pass because the threshold applies only to the changed-file subset — not the total codebase. The net effect: coverage regressions introduced alongside renames are invisible to per-PR coverage checks. Fix: add a full-codebase coverage run as a nightly CI job even when per-PR `coverage.changed` is enabled; treat the nightly run as the definitive coverage gate. [community: vitest.dev/blog/vitest-4-1.html — coverage.changed note]

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
- **Fowler 5-Layer Microservice Pyramid:** Adds component tests (full service binary + stubbed external HTTP) and contract tests (Pact) as explicit layers between integration and e2e. Best for TypeScript backends with multiple independently deployed services. Maps directly to the five-level decomposition: unit → integration → component → contract → e2e.
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
- **Neon DB branch-per-run** eliminates container start-up time but adds a hard dependency on Neon's cloud API during CI. API failures (rate limits, network timeouts) can block the integration test level. Mitigation: set a generous timeout in `beforeAll` and fall back to SQLite in-memory if `NEON_API_KEY` is absent (local dev) or the Neon branch creation times out. Initial setup: 1–2 h (API key, project ID, helper script). Ongoing cost: branch deletion must be paired with test cleanup to avoid accumulating branches.
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

### Test Double Selection by Pyramid Level  [community]

Choosing the wrong type of test double for a given test level is a major source of both over-mocking (at the unit level) and under-isolation (at the integration level). Martin Fowler's canonical taxonomy (from Gerard Meszaros) defines five test double types — each maps naturally to a pyramid level:

| Test Double | What it does | Best pyramid level | TypeScript implementation |
|-------------|-------------|-------------------|---------------------------|
| **Dummy** | Fills a parameter slot; never called | Unit — satisfies required constructor params | `null as unknown as UserService` or typed placeholder |
| **Stub** | Returns hardcoded responses to specific calls | Unit — control what a dependency returns | `vi.fn().mockResolvedValue(fakeUser)` |
| **Fake** | Working implementation with production shortcuts | Integration — in-memory DB, local SMTP server | SQLite in-memory via `better-sqlite3`, `nodemailer` mock transport |
| **Spy** | Records calls; real implementation still runs | Integration — verify side effects without stopping real behaviour | `vi.spyOn(mailer, 'send')` |
| **Mock** | Pre-programmed expectations verified after the test | Unit — strict interaction testing | `vi.fn()` + `expect(fn).toHaveBeenCalledWith(...)` |

**Classical vs. Mockist TDD and pyramid level selection:**

- **Classical TDD** (default in Google's style guide): uses real collaborators at every level unless awkward (network I/O, time, randomness). Prefers fakes and spies. Leads naturally to a heavier integration test level because real collaborators need real data.
- **Mockist TDD** (London School): mocks every collaborator to isolate the test object. Produces a heavier unit test level, but mocks must be kept in sync with real interfaces — the drift problem. TypeScript partially mitigates this: `vi.mocked()` wraps the real type, so interface changes produce compile errors.

The **practical synthesis** used in production TypeScript codebases: use Classical TDD at the integration test level (real DB, real HTTP handlers, fakes for external APIs), use Mockist TDD only at the unit test level for pure business logic with complex dependency graphs. Never mix the two philosophies in the same test file — it produces tests that are expensive to maintain without the benefits of either approach.

```typescript
// Unit test case: Mockist style — mock the repository, test only service logic
// src/orders/orders.service.unit.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { OrdersService } from './orders.service.js';
import type { OrderRepository } from './order.repository.js';
import type { Order } from './order.entity.js';

// Mockist: every collaborator is a mock — test only OrdersService logic in isolation
const mockRepo: OrderRepository = {
  create: vi.fn(),
  findById: vi.fn(),
  findAll: vi.fn(),
  delete: vi.fn(),
};

beforeEach(() => {
  vi.clearAllMocks();
});

describe('OrdersService.create', () => {
  it('calls repository.create with validated input and returns the saved order', async () => {
    const service = new OrdersService(mockRepo);
    const input = { customerId: 'c1', items: [{ sku: 'A1', qty: 2 }] };
    const saved: Order = { id: 'ord_001', ...input, status: 'pending', createdAt: new Date() };

    vi.mocked(mockRepo.create).mockResolvedValue(saved);

    const result = await service.create(input);

    // Verify interaction (Mockist: we care HOW the service used the repo)
    expect(mockRepo.create).toHaveBeenCalledWith(input);
    expect(result).toStrictEqual(saved);
  });

  it('throws DomainError when items array is empty', async () => {
    const service = new OrdersService(mockRepo);
    await expect(service.create({ customerId: 'c1', items: [] })).rejects.toThrow('items must not be empty');
    // Repository never called for invalid input
    expect(mockRepo.create).not.toHaveBeenCalled();
  });
});
```

```typescript
// Integration test case: Classical style — real repository + real SQLite DB
// tests/integration/orders.service.integration.test.ts
import { beforeAll, afterAll, afterEach, it, expect } from 'vitest';
import { DataSource } from 'typeorm';
import { OrdersService } from '../../src/orders/orders.service.js';
import { OrderRepository } from '../../src/orders/order.repository.js';
import { Order } from '../../src/orders/order.entity.js';

// Classical: real DB — test how service + repository work together
let dataSource: DataSource;
let service: OrdersService;

beforeAll(async () => {
  dataSource = new DataSource({ type: 'sqlite', database: ':memory:', entities: [Order], synchronize: true });
  await dataSource.initialize();
  service = new OrdersService(new OrderRepository(dataSource));
});

afterAll(() => dataSource.destroy());
afterEach(() => dataSource.getRepository(Order).clear());

it('persists an order and makes it findable by id', async () => {
  const created = await service.create({ customerId: 'c1', items: [{ sku: 'A1', qty: 2 }] });
  const found = await service.findOne(created.id);
  // State verification: we don't care HOW the service called the DB — only that the state is correct
  expect(found?.customerId).toBe('c1');
  expect(found?.status).toBe('pending');
});
```

The two examples use the same service class but opposite test double strategies. The unit test case verifies *interaction* (was `create` called with the right argument?). The integration test case verifies *state* (is the order persisted and retrievable?). Both are needed — the unit test runs in < 1 ms, the integration test takes 50–100 ms but catches ORM mapping defects the unit test cannot. [community: Fowler — Mocks Aren't Stubs, martinfowler.com/articles/mocksArentStubs.html]

---

### Vitest 3.x Inline Workspace Configuration  [community]

Vitest 3.0 (released January 17, 2025) introduced inline workspace configuration, eliminating the need for a separate `vitest.workspace.ts` file. Projects are now defined directly in `vitest.config.ts` using the `test.projects` array with full TypeScript type support. The `extends: true` option from `defineProject` was introduced in Vitest 2.x and remains the recommended pattern; Vitest 3 additionally allows plain config objects without `defineProject` in the inline workspace array for brevity.

Key Vitest 3.x changes relevant to the pyramid:

- **Inline workspace**: `test.projects: [...]` in `vitest.config.ts` replaces `vitest.workspace.ts` — no separate workspace file needed for small monorepos.
- **Reporter redesign**: Reduced visual flicker; stable output in CI environments where streaming reporters previously produced garbled logs in parallel runs.
- **Multi-browser instances**: The `instances` array in browser mode lets you run the same integration-level component test cases across Chromium, Firefox, and WebKit in a single CI step, each with separate caching — Vite processes each file once regardless of browser count.
- **Location-based test filtering**: `vitest run src/orders/orders.service.unit.test.ts:42` runs only the test case at line 42 — useful for debugging a single failing integration test case without running the full suite.
- **Public node API redesign**: The `vitest/node` API is now stable and fully documented, enabling CI scripts to programmatically query test results (pyramid shape checks, coverage reports) without shelling out to the CLI.

```typescript
// vitest.config.ts — Vitest 3.x inline workspace (no separate vitest.workspace.ts needed)
import { defineConfig, defineProject } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      // Vitest 3: coverage is root-only; defineProject intentionally cannot override it
    },
    // Vitest 3: define all projects inline — no vitest.workspace.ts required
    projects: [
      defineProject({
        extends: true,   // inherit root plugins + coverage config
        test: {
          name: 'unit',
          include: ['src/**/*.unit.test.ts'],
          environment: 'node',
          testTimeout: 5_000,
        },
      }),
      defineProject({
        extends: true,
        test: {
          name: 'integration',
          include: ['src/**/*.integration.test.ts', 'tests/integration/**/*.test.ts'],
          environment: 'node',
          testTimeout: 60_000,
          pool: 'forks',
        },
      }),
      defineProject({
        extends: true,
        test: {
          name: 'e2e',
          include: ['e2e/**/*.e2e.test.ts'],
          environment: 'node',
          testTimeout: 120_000,
          bail: 1,
        },
      }),
      // Vitest 3 multi-browser instances: run component tests in Chromium + Firefox
      defineProject({
        extends: true,
        test: {
          name: 'components',
          include: ['src/**/*.ct.test.tsx'],
          browser: {
            enabled: true,
            provider: 'playwright',
            // instances array: Vite processes each file once; results merged per browser
            instances: [
              { browser: 'chromium' },
              { browser: 'firefox' },
            ],
          },
        },
      }),
    ],
  },
});
```

The multi-browser `instances` configuration is specifically valuable for the Playwright component test level (`.ct.test.tsx` files) where browser engine differences matter. Do not use `instances` for node-environment unit or integration test cases — the overhead is only justified when testing browser-specific behaviour. [official: vitest.dev/guide/projects]

---

### Vitest 3.2: Annotations, Scoped Fixtures, and Resource Management  [community]

Vitest 3.2 (released June 2, 2025) introduced several features that improve test-level organisation and resource lifecycle management in TypeScript projects. None of these change the pyramid shape, but they reduce the maintenance cost of the integration and e2e test levels where lifecycle complexity is highest.

**Annotation API:** Test cases can now carry structured annotations — a `type` string and an optional `description` — that surface in the UI, HTML, JUnit, TAP, and GitHub Actions reporters. This is particularly useful at the integration test level for marking test cases with their pyramid level, linked story, or known flakiness status, without requiring separate tag syntax. Annotations are composable: `test.info().annotations` can be read at runtime to conditionally skip or modify behaviour.

**Scoped Fixtures (`scope: 'file' | 'worker'`):** `test.extend` now accepts a `scope` option on each fixture. `scope: 'file'` creates the fixture once per test file and tears it down after all tests in the file complete — the right scope for a database connection shared across an integration test file. `scope: 'worker'` creates the fixture once per worker process — useful for heavyweight resources like a browser context shared across multiple component test files running on the same worker. Previously, only `beforeAll`/`afterAll` achieved this scoping without the type-safe fixture injection pattern.

**Explicit resource management with `using`:** `vi.spyOn()` and `vi.fn()` now support the `using` keyword (TypeScript 5.2+ `Symbol.dispose`). A spy created with `await using spy = vi.spyOn(...)` is automatically restored when the block exits — no `afterEach(() => vi.restoreAllMocks())` required. This reduces test pollution risk at the unit test level where spy leakage into subsequent tests is a common source of non-determinism.

**Test Signal API:** A test body now receives an `AbortSignal` that is cancelled when the test times out or is interrupted. Long-running integration tests that open persistent connections (WebSocket, SSE, database listeners) can bind to the signal for early cleanup — preventing the "open handle" failures that `--detect-async-leaks` (Vitest 4.1) later surfaces.

**Multi-project ordering (`sequence.groupOrder`):** Projects with the same `groupOrder` value run together; higher values run later. This enables a fail-fast CI pipeline that does not require separate `vitest run --project unit && vitest run --project integration` invocations. Configure unit tests with `groupOrder: 1`, integration with `groupOrder: 2`, e2e with `groupOrder: 3` — Vitest runs each group sequentially, short-circuiting on the first group failure.

**`workspace` config key deprecated (Vitest 3.2):** The `workspace` config option (which pointed to a `vitest.workspace.ts` file) is deprecated in Vitest 3.2 to avoid naming conflicts with PNPM workspaces. The replacement is the inline `test.projects` array (already covered in the Vitest 3.0 section above). Any `vitest.config.ts` still using `workspace: './vitest.workspace.ts'` should migrate to `test.projects: [...]` before upgrading beyond 3.2.

```typescript
// vitest.config.ts — Vitest 3.2 patterns: scoped fixtures, groupOrder fail-fast, annotations
// Demonstrates scoped fixtures in test.extend and multi-project groupOrder

// tests/fixtures/db.fixture.ts — file-scoped DB fixture (Vitest 3.2)
import { test as base } from 'vitest';
import { DataSource } from 'typeorm';
import { Order } from '../../src/orders/order.entity.js';

// scope: 'file' — DB connection created once per test file, torn down after all tests complete
export const test = base.extend<{ db: DataSource }>({
  db: [
    async ({}, use) => {
      const ds = new DataSource({
        type: 'sqlite',
        database: ':memory:',
        entities: [Order],
        synchronize: true,
      });
      await ds.initialize();
      await use(ds);       // inject into each test case in this file
      await ds.destroy();  // automatic teardown when file finishes
    },
    { scope: 'file' },     // Vitest 3.2: file-scoped — not recreated for each test case
  ],
});
```

```typescript
// src/orders/orders.integration.test.ts — using scoped fixture + Annotation API + using-spy
import { test } from '../fixtures/db.fixture.js';
import { OrdersService } from '../../src/orders/orders.service.js';
import { OrderRepository } from '../../src/orders/order.repository.js';
import { vi, expect } from 'vitest';

test('creates an order and notifies — annotation + using spy', async ({ db }) => {
  // Annotation API: label this test case for reporters (shows in HTML/JUnit output)
  test.info().annotations.push({ type: 'pyramid-level', description: 'integration' });
  test.info().annotations.push({ type: 'story', description: 'ORDER-123' });

  const service = new OrdersService(new OrderRepository(db));

  // Vitest 3.2: using keyword restores the spy when block exits — no afterEach needed
  // Requires TypeScript 5.2+ with useDefineForClassFields: true
  // Note: 'using' requires lib.es2025 or later in tsconfig for Symbol.dispose
  await using notifySpy = vi.spyOn(service as unknown as { notify: () => void }, 'notify' as never);

  const created = await service.create({ customerId: 'c1', items: [{ sku: 'A1', qty: 1 }] });
  expect(created.id).toBeDefined();
  // spy is automatically restored here — no afterEach(() => vi.restoreAllMocks()) needed
});
```

```typescript
// vitest.config.ts — sequence.groupOrder for fail-fast without separate CI invocations
import { defineConfig, defineProject } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    coverage: { provider: 'v8', reporter: ['text', 'json', 'html'] },
    projects: [
      defineProject({
        extends: true,
        test: {
          name: 'unit',
          include: ['src/**/*.unit.test.ts'],
          environment: 'node',
          testTimeout: 5_000,
          sequence: { groupOrder: 1 }, // Vitest 3.2: run first; failure stops later groups
        },
      }),
      defineProject({
        extends: true,
        test: {
          name: 'integration',
          include: ['src/**/*.integration.test.ts'],
          environment: 'node',
          testTimeout: 60_000,
          pool: 'forks',
          sequence: { groupOrder: 2 }, // run only if group 1 passes
        },
      }),
      defineProject({
        extends: true,
        test: {
          name: 'e2e',
          include: ['e2e/**/*.e2e.test.ts'],
          environment: 'node',
          testTimeout: 120_000,
          bail: 1,
          sequence: { groupOrder: 3 }, // run only if groups 1 + 2 pass
        },
      }),
    ],
  },
});
```

The `sequence.groupOrder` approach unifies the fail-fast pipeline into a single `vitest run` invocation — removing the need for three separate `&&`-chained CI commands while preserving the execution order guarantee. The annotation API provides structured metadata for test-case traceability, which is particularly useful in regulated environments where test cases must be linked to requirements or user stories (ISTQB test management). [official: vitest.dev/blog/vitest-3-2.html]

---

### Playwright 1.50+ Test Level Enhancements  [community]

Playwright's 2025 release series (1.45–1.59) introduced capabilities that affect how test cases at the integration and e2e levels are structured. Key additions for TypeScript projects:

**Clock API (v1.45) — integration test level:** The `page.clock` API enables precise control of time (Date, setTimeout, setInterval) within Playwright test cases. This is particularly valuable at the e2e test level for testing time-dependent UI behaviour (countdown timers, session expiry, scheduled notifications) without real delays. At the component test level (Playwright CT), `mount` receives a `clock` fixture for synchronous time control — no `await vi.useFakeTimers()` workaround required.

**`tsconfig` option (v1.50) — TypeScript monorepo support:** The `playwright.config.ts` now accepts a top-level `tsconfig` option pointing to a specific `tsconfig.json`. In monorepos with separate `tsconfig.app.json` and `tsconfig.test.json`, this ensures Playwright resolves path aliases and module resolution consistently with the test tsconfig rather than the root one — eliminating the "works in tsc, fails in Playwright" path alias defect.

**Aria Snapshots (v1.49) — integration and e2e test levels:** The `toMatchAriaSnapshot()` assertion serialises the ARIA accessibility tree to YAML and diffs it like a snapshot. This provides a structured alternative to `toMatchSnapshot()` for testing semantic HTML changes: ARIA snapshots are human-readable, smaller than HTML snapshots, and directly linked to the accessibility contract of the test object.

```typescript
// e2e/checkout.e2e.test.ts — Playwright 1.50+ features
import { test, expect } from '@playwright/test';

// playwight.config.ts: tsconfig: './tsconfig.e2e.json' — path aliases resolved consistently
test('countdown timer reaches zero and disables submit', async ({ page, clock }) => {
  // Clock API: freeze time at a known point — no real delays in CI
  await clock.install({ time: new Date('2026-06-01T00:00:00Z') });
  await page.goto('/checkout');
  // Advance the clock 5 minutes — triggers session warning in the UI
  await clock.fastForward(5 * 60 * 1_000);
  await expect(page.getByRole('alert', { name: /session expiring/i })).toBeVisible();
  // Advance past the session timeout — submit button should disable
  await clock.fastForward(10 * 60 * 1_000);
  await expect(page.getByRole('button', { name: /place order/i })).toBeDisabled();
});

test('cart page matches accessibility tree snapshot', async ({ page }) => {
  await page.goto('/cart');
  await page.waitForLoadState('networkidle');
  // toMatchAriaSnapshot: YAML diff of the ARIA tree — smaller and more meaningful than HTML snapshot
  await expect(page.locator('main')).toMatchAriaSnapshot(`
    - heading "Your Cart" [level=1]
    - list:
      - listitem: "TypeScript Handbook - $29.99"
      - listitem: "Vitest in Action - $39.99"
    - text: "Total: $69.98"
    - button "Proceed to Checkout"
  `);
});
```

The ARIA snapshot pattern is particularly valuable as a regression guard for the e2e test level: it catches accessibility regressions (headings removed, buttons losing their role) that HTTP response assertions and standard locator assertions miss. Unlike HTML snapshots, ARIA snapshots are immune to CSS class and DOM structure changes that do not affect the accessibility tree. [official: playwright.dev/docs/release-notes]

---

### TypeScript 7.0 Migration: Test Pipeline Implications  [community]

TypeScript 7.0 (the native Go-based compiler port) is targeted as the successor to the 6.x line. Teams building TypeScript test suites should prepare their pyramid configurations now to avoid a painful migration:

**Deprecated options that break test pipelines in TS 7.0:**

| Option removed in TS 7.0 | Common use in test configs | Replacement |
|--------------------------|---------------------------|-------------|
| `--baseUrl` | Root-relative imports in test files | Use `paths` entries; `vite-tsconfig-paths` syncs to Vitest |
| `--moduleResolution node` | `tsconfig.jest.json` or `tsconfig.test.json` legacy configs | Migrate to `"moduleResolution": "bundler"` (Vitest/Vite) or `"node16"`/`"nodenext"` (pure Node.js tests) |
| `--outFile` | CI scripts that compile test reporters to a single file | Use `esbuild` or Rollup; not relevant to Vitest/Jest which transpile on-the-fly |
| `target: es5` | Some Jest config presets | Remove; minimum target is `es2016` in TS 7.0 |
| `--downlevelIteration` | Polyfill for `for...of` in older targets | Remove with `target: es5` |

**`--stableTypeOrdering` flag (TS 6.0, required for TS 7.0 parallel checker):** TypeScript 7.0's native parallel checker requires deterministic type ordering. The `--stableTypeOrdering` flag in TS 6.0 makes types stable across parallel workers at the cost of ~25% type-check overhead. Enable it in your `tsconfig.json` before upgrading to TS 7.0:

```json
{
  "compilerOptions": {
    "strict": true,
    "stableTypeOrdering": true,
    "moduleResolution": "bundler",
    "module": "esnext",
    "target": "esnext",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

**Native TS port performance impact on the test pyramid:** TypeScript 7.0's native compiler (written in Go) is projected to deliver 10-15× faster type checking. For large TypeScript monorepos, this directly benefits the test pyramid: the `tsc --noEmit` step that currently adds 30–60 s to the unit test level CI job should complete in 2–5 s. This makes pre-test type checking practical even in hot-path unit test runs, not just in nightly CI. Plan to re-enable `tsc --noEmit` as a blocking CI gate before unit tests once TS 7.0 is stable — teams that disabled it for speed reasons now have no reason to keep it disabled.

**`--erasableSyntaxOnly` (TS 5.8) + Node.js native TypeScript stripping:** TS 5.8 introduced `--erasableSyntaxOnly`, which restricts TypeScript syntax to forms that can be stripped by a type-erasing tool (no `const enum`, no legacy namespace merging, no parameter property shorthand in constructor). Node.js 23.6+ ships a built-in TypeScript type-stripper. When `--erasableSyntaxOnly` is enabled, test files can be run directly with `node --experimental-strip-types` without a transpiler step — the fastest possible unit test execution path for TypeScript. This is now the recommended approach for unit test suites in Node.js 23+ environments where no bundler is involved. [official: typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html]

---

### Vitest 4.x: Stable Browser Mode and Schema Assertions  [community]

Vitest 4.0 (October 2025) and 4.1 (March 2026) brought significant changes relevant to the test pyramid in TypeScript projects.

**Vitest 4.0 — key pyramid-affecting changes:**

- **Browser mode is now stable.** The `@vitest/browser` package is no longer experimental. Provider packages are now separate installs: `@vitest/browser-playwright`, `@vitest/browser-webdriverio`. The integration test level for React/Vue components in a real browser is now a first-class configuration. Import `userEvent` and `page` from `vitest/browser` (previously `@vitest/browser/context`).
- **`toMatchScreenshot`** adds visual regression testing at the integration-level component test tier. Screenshot comparisons run in the same Vitest process as your other test levels, unifying the toolchain.
- **`expect.schemaMatching`** validates values against Standard Schema v1 objects (Zod, Valibot, ArkType). This closes a pyramid gap: rather than writing a dedicated unit test for Zod schema validation, you can assert schema compliance inline at the integration layer where real data flows through.
- **`basic` reporter removed.** Use `default` reporter with `summary: false`. Teams running custom CI reporter scripts should update before upgrading.
- **Playwright Traces support in browser mode.** Setting `browser.trace: 'on-first-retry'` generates Playwright traces for failing component test cases — visible in the HTML reporter. This dramatically improves diagnosis of flaky browser-mode integration tests.

**Vitest 4.1 (March 2026) — key pyramid-affecting changes:**

- **Test tags with `--tags-filter`.** Tag test cases with `'db'`, `'slow'`, `'flaky'` metadata and filter by tag across the workspace. Example: `vitest run --tags-filter="integration && !flaky"` runs all integration tests except quarantined ones. This is the recommended pattern for managing the quarantine strategy (gotcha #8 equivalent for test tags). TypeScript infers tag types from the `test.extend` builder pattern — no manual declaration needed.
- **`aroundEach` and `aroundAll` hooks.** Wrap each test case (or all test cases in a suite) in a context using `AsyncLocalStorage` or database transactions. Critical pattern for integration tests: `aroundEach` can wrap each test case in a transaction that is rolled back after the test, providing instant test isolation without the `TRUNCATE` overhead between test cases.
- **`--detect-async-leaks`** flag catches leaked timers and unresolved async resources after each test case. This is the automated enforcement mechanism for the principle "unit tests must be isolated" — any test that starts a `setInterval` without clearing it, or opens a `net.Socket` without closing it, now fails immediately rather than silently corrupting subsequent test cases.
- **`viteModuleRunner: false` (experimental).** Disables Vite's module sandbox and runs tests with native Node.js imports. This produces "closer-to-production" test execution — the same module resolution as the deployed application — which is valuable at the integration test level where import-time side effects (DI container initialization, env-var loading) must match production behavior.
- **`test.extend` builder pattern** infers fixture types automatically. TypeScript no longer requires manual type declarations for custom fixtures — the builder pattern infers the type of each fixture from its return value.

```typescript
// vitest.config.ts — Vitest 4.x with tags, aroundEach, and schema assertions
import { defineConfig, defineProject } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    coverage: { provider: 'v8', reporter: ['text', 'json', 'html'] },
    projects: [
      defineProject({
        extends: true,
        test: {
          name: 'unit',
          include: ['src/**/*.unit.test.ts'],
          environment: 'node',
          testTimeout: 5_000,
        },
      }),
      defineProject({
        extends: true,
        test: {
          name: 'integration',
          include: ['src/**/*.integration.test.ts', 'tests/integration/**/*.test.ts'],
          environment: 'node',
          testTimeout: 60_000,
          pool: 'forks',
        },
      }),
      defineProject({
        extends: true,
        test: {
          name: 'components',
          include: ['src/**/*.ct.test.tsx'],
          browser: {
            enabled: true,
            provider: 'playwright',    // requires @vitest/browser-playwright (Vitest 4.x)
            instances: [{ browser: 'chromium' }, { browser: 'firefox' }],
            trace: 'on-first-retry',  // Vitest 4.0: Playwright trace on retry — shows in HTML reporter
          },
        },
      }),
    ],
  },
});
```

```typescript
// src/orders/orders.integration.test.ts — aroundEach transaction rollback + expect.schemaMatching
import { beforeAll, afterAll, it, expect } from 'vitest';
import { DataSource } from 'typeorm';
import { buildApp } from '../../src/app.js';
import { CreateOrderSchema } from '../../src/orders/order.schema.js';
import request from 'supertest';
import type { Express } from 'express';

let app: Express;
let dataSource: DataSource;

beforeAll(async () => {
  dataSource = new DataSource({ type: 'sqlite', database: ':memory:', synchronize: true });
  await dataSource.initialize();
  app = buildApp({ db: dataSource });
});

afterAll(() => dataSource.destroy());

// aroundEach: wrap each test in a transaction → automatic rollback; no TRUNCATE needed
// Usage requires a custom aroundEach fixture (Vitest 4.1):
// beforeEach(() => dataSource.transaction(async (txn) => { ... }));

it('POST /orders body matches the CreateOrder schema', async () => {
  const validInput = { customerId: 'c1', items: [{ sku: 'A1', qty: 2 }] };
  const res = await request(app).post('/orders').send(validInput);

  expect(res.status).toBe(201);
  // expect.schemaMatching: validates res.body against the Zod schema at the integration level
  // — catches schema / runtime divergence without a separate unit test for the Zod rule
  expect(res.body).toEqual(expect.schemaMatching(CreateOrderSchema.partial()));
});

it('POST /orders rejects empty items with 422', async () => {
  const res = await request(app).post('/orders').send({ customerId: 'c1', items: [] });
  expect(res.status).toBe(422);
});
```

**Vitest 4.x upgrade note for pyramid tooling:** The `basic` reporter removal and default reporter behaviour change means teams using custom `--reporter=basic` in their CI pyramid shape check (e.g., `vitest run --reporter=basic --outputFile=results.json`) must switch to `--reporter=json`. The JSON output schema is unchanged. [official: vitest.dev/blog/vitest-4.html, vitest.dev/blog/vitest-4-1.html]

---

### Playwright v1.51–v1.60: New Test-Level Utilities  [community]

Playwright's 2025–2026 release series (v1.51 through v1.60) added test-level utilities relevant to how TypeScript e2e and integration test cases are structured:

**`test.abort()` (v1.60) — e2e test level:** Halts the entire test with an optional message when an unrecoverable precondition fails. Previously, teams used `test.skip()` for skipping, or relied on unhandled assertions to fail. `test.abort()` is the right tool when a fixture setup step (e.g., database seeding) fails catastrophically — the test is marked failed immediately without running any assertions.

**`await using` resource cleanup (v1.59):** TypeScript 5.2's `using` and `await using` keywords integrate with Playwright fixtures via the `AsyncDisposable` protocol. Any resource that implements `Symbol.asyncDispose` is cleaned up automatically when the block exits — no explicit `teardown` call needed. Integrates naturally with testcontainers (if the container implements `AsyncDisposable`) and Neon DB branches.

**`--only-changed` CLI flag (v1.48):** Runs only test files that have changed since the last git commit (or a specified ref). At the e2e level this can dramatically reduce CI time for pull requests — instead of running the full suite, only e2e test files touching changed source are re-run. TypeScript path aliases mean source changes to `src/orders/` automatically re-run `e2e/checkout.e2e.test.ts` if Playwright's dependency tracing is configured. Note: dependency tracing with `--only-changed` requires `playwright.config.ts` to set `dependencies` via `testProject.dependencies` — otherwise Playwright cannot determine which e2e files are affected by a source change.

**`testProject.teardown` (v1.49):** Specifies a separate project that runs *after* the main project completes. Use this to separate test data cleanup from the test run itself — the teardown project runs unconditionally even if tests fail, ensuring CI environments are not left with orphaned data. TypeScript types for `testProject.teardown` are part of `@playwright/test` since v1.49.

**ARIA snapshot on `page` object (v1.60):** `expect(page).toMatchAriaSnapshot()` is equivalent to `expect(page.locator('body')).toMatchAriaSnapshot()`, simplifying full-page accessibility tree assertions at the e2e level. Combined with `locator.ariaSnapshot({ boxes: true })`, you can capture bounding-box positions of ARIA nodes — useful for layout regression testing at the e2e level when visual snapshot would be too brittle.

**`locator.normalize()` and `page.pickLocator()` (v1.59):** `locator.normalize()` converts a locator to its best-practice form (role-based where possible); `page.pickLocator()` enters interactive selection mode in headed test runs. These development-time utilities reduce the time to write stable, ARIA-compliant locators — directly addressing the anti-pattern of record-and-playback e2e generators that produce brittle, implementation-detail-bound locators.

```typescript
// e2e/orders.e2e.test.ts — Playwright v1.59-v1.60 patterns
import { test, expect } from '@playwright/test';

test('checkout flow — combined v1.59-v1.60 patterns', async ({ page }) => {
  // test.abort() — if prerequisite data is missing, abort immediately (v1.60)
  const seeded = await page.request.get('/api/health/seeded');
  if (seeded.status() !== 200) {
    await test.abort('test database not seeded — aborting to avoid false e2e failures');
  }

  await page.goto('/shop');
  await page.getByRole('button', { name: 'Add to cart' }).first().click();
  await page.getByRole('link', { name: 'Checkout' }).click();
  await page.fill('[name="email"]', 'buyer@example.com');
  await page.getByRole('button', { name: 'Place order' }).click();

  // ARIA snapshot on page object (v1.60) — full-page accessibility regression
  // Smaller and more semantic than HTML snapshot; immune to CSS/DOM structure changes
  await expect(page.locator('main')).toMatchAriaSnapshot(`
    - heading "Order Confirmed" [level=1]
    - paragraph: /Order #[A-Z0-9]+/
    - link "Continue Shopping"
  `);
});

// await using — automatic resource cleanup via AsyncDisposable (v1.59 + TypeScript 5.2)
// Use when a fixture creates a resource that must be released regardless of test outcome
test('order with disposable test user', async ({ page }) => {
  // Hypothetical: TestUser implements AsyncDisposable → deleted on block exit
  await using testUser = await createDisposableTestUser();
  await page.goto(`/account/${testUser.id}`);
  await expect(page.getByRole('heading', { name: testUser.name })).toBeVisible();
  // testUser is automatically deleted via Symbol.asyncDispose when block exits
});
```

**Playwright v1.48 `--only-changed` CI configuration (TypeScript monorepo):**

```yaml
# .github/workflows/e2e.yml — run only changed e2e tests on PRs
- name: Run Playwright e2e (changed only)
  run: npx playwright test --only-changed=origin/main
  # Note: requires testProject.dependencies in playwright.config.ts for full tracing
  # Without dependencies, only test FILES that changed are re-run (not files affected by source changes)
```

[official: playwright.dev/docs/release-notes — v1.48 (--only-changed), v1.49 (testProject.teardown), v1.59 (await using, locator.normalize), v1.60 (test.abort, ARIA snapshot on page)]

---

### Playwright v1.60: HAR Tracing and Drag-and-Drop at the E2E Level  [community]

Two additions in Playwright v1.60 affect specific e2e test case patterns in TypeScript projects:

**`tracing.startHar()` / `tracing.stopHar()` — first-class HAR recording:**
Previously, HAR recording in Playwright required `page.routeFromHAR()` patterns that were awkward to integrate into test fixtures. Playwright v1.60 elevates HAR tracing to a first-class tracing API using `await using` syntax for automatic cleanup. This is useful at the e2e level when you need to record and replay network traffic for reproducible test scenarios — for example, capturing a third-party API response sequence and replaying it in CI without hitting the live API.

```typescript
// e2e/payment-flow.e2e.test.ts — HAR recording + replay at e2e level (Playwright v1.60)
import { test, expect } from '@playwright/test';

// Step 1: Record HAR (run once against the live environment, commit the .har file)
test('record payment flow HAR', async ({ page, context }) => {
  // Start HAR recording with URL filter — only capture payment API calls
  const har = await context.tracing.startHar({
    path: 'fixtures/payment-flow.har',
    url: /api\.payment-provider\.com/,
    content: 'attach', // embed response bodies in the HAR file
    mode: 'minimal',   // omit redundant headers to keep file size manageable
  });

  await page.goto('/checkout');
  await page.fill('[name="card"]', '4242424242424242');
  await page.getByRole('button', { name: 'Place order' }).click();
  await expect(page.getByRole('heading', { name: /order confirmed/i })).toBeVisible();

  await context.tracing.stopHar();
});

// Step 2: Replay HAR in CI — no live third-party API required
test('checkout completes using recorded HAR (offline-safe)', async ({ page, context }) => {
  // Route requests matching the HAR to the recorded responses
  await context.routeFromHAR('fixtures/payment-flow.har', {
    url: /api\.payment-provider\.com/,
    update: false, // use recorded responses; fail if a request has no match
  });

  await page.goto('/checkout');
  await page.fill('[name="card"]', '4242424242424242');
  await page.getByRole('button', { name: 'Place order' }).click();
  await expect(page.getByRole('heading', { name: /order confirmed/i })).toBeVisible();
});
```

The HAR recording pattern sits in a hybrid space between the e2e test level and the contract test level: it records the real external API contract once, then replays it deterministically in CI. This is particularly valuable when the external API has rate limits or is unavailable in the CI environment. It is not a replacement for Pact contract tests when you *own both sides* of the contract — HAR replay is appropriate for read-only, one-directional contracts with third-party APIs you cannot instrument for Pact verification.

**`locator.drop()` — drag-and-drop e2e test cases:**
Drag-and-drop interaction has historically been one of the most brittle patterns in e2e testing. Playwright v1.60's `locator.drop()` provides a semantically correct simulation of external file or clipboard data being dropped onto a target element, distinct from `dragTo()` which simulates a same-page drag. Use `locator.drop()` for file upload via drag-and-drop; use `dragTo()` for reordering within a sortable list.

```typescript
// e2e/file-upload.e2e.test.ts — locator.drop() for external file drag-and-drop (v1.60)
import { test, expect } from '@playwright/test';
import path from 'node:path';

test('user can upload a file by dragging it onto the dropzone', async ({ page }) => {
  await page.goto('/upload');
  const dropZone = page.getByRole('region', { name: 'file drop zone' });

  // locator.drop(): simulates external file drag onto an element
  // Works across Chromium, Firefox, WebKit — no browser-specific workaround needed
  await dropZone.drop({
    files: [path.resolve('fixtures/test-invoice.pdf')],
    mimeType: 'application/pdf',
  });

  // Verify file was accepted and processing began
  await expect(page.getByRole('status', { name: /processing/i })).toBeVisible();
  await expect(page.getByText('test-invoice.pdf')).toBeVisible();
});
```

[official: playwright.dev/docs/release-notes — v1.60 (tracing.startHar, locator.drop)]

---

### Vitest 4.x Async Leak Detection and Tag-Based Quarantine  [community]

The `--detect-async-leaks` flag introduced in Vitest 4.1 changes the economics of the "quarantine don't delete" flakiness strategy at the unit and integration test levels. Previously, a test case that leaked a `setInterval` or an open `net.Socket` would silently corrupt the next test case — the flakiness appeared in the *wrong* test case, making root-cause diagnosis difficult. With `--detect-async-leaks`, the leaking test case fails immediately with a diagnostic message listing the leaked handles.

Combined with test tags (Vitest 4.1), the recommended quarantine flow becomes:

1. `--detect-async-leaks` surfaces the leaking test case explicitly.
2. Tag it `'flaky'`: `it.extend({ flaky: true })('...', ...)` or use metadata.
3. Exclude tagged tests from the merge gate: `vitest run --tags-filter="!flaky"`.
4. Track in a separate CI job: `vitest run --tags-filter="flaky"` with `--retry=3` and report separately.

This is the Vitest 4.x idiom for the quarantine strategy described in gotcha #8 (flakiness) — it provides explicit tooling support rather than relying on file-naming conventions or custom CI scripts. [community: vitest.dev/blog/vitest-4-1.html]

---

### Preparing for Vitest 5.0 (Beta as of May 2026)  [community]

Vitest 5.0.0-beta.2 was released on May 5, 2026. It is not yet stable, but teams should audit their pyramid configuration for the following breaking changes before upgrading:

| Breaking change | Impact on test pyramid | Migration |
|-----------------|------------------------|-----------|
| Default attachment dir: `.vitest-attachements/` → `.vitest/attachments/` | CI scripts reading screenshot/trace artifacts by hardcoded path will break silently | Update `attachmentsDir` in `vitest.config.ts` or fix CI script paths |
| Blob reporter output: `.vitest-blob/` → `.vitest/blob/` | Multi-shard merge pipelines that use blob reporter lose output | Update `--outputFile` path or merge step configuration |
| `test.sequential()` / `suite.sequential()` removed | Test files using the `sequential` sugar produce runtime errors | Replace with `test('...', { concurrent: false }, ...)` |
| `expect` package now inlined into Vitest | Projects importing from `'vitest/expect'` directly need to update | Change import to `'vitest'` |
| V8 coverage tracks `node:child_process` + `node:worker_threads` | Branch coverage may increase for integration tests using worker threads; threshold checks may now pass that previously failed | Review coverage thresholds after upgrade |

**Stable release timeline:** Not announced as of May 12, 2026. Pin to `vitest@^4.1` until stable is announced at [vitest.dev/blog/vitest-5.html].

**Safe upgrade path:**

```bash
# Test the upgrade in a separate branch before landing it to main
npm install vitest@5.0.0-beta.2 --save-dev

# Run only unit tests first — the level least affected by directory/reporter changes
npx vitest run --project unit

# If unit tests pass, run integration tests
npx vitest run --project integration

# Check that coverage output is at the expected path
ls .vitest/

# If all pass, update CI scripts before committing the version bump
# Key files to update: .github/workflows/*.yml, scripts/check-pyramid-shape.ts
```

The most critical audit is for teams using `--reporter=blob` in sharded CI pipelines: the output directory change means the merge step (`vitest merge`) will fail silently if pointed at the old `.vitest-blob/` path. [community: github.com/vitest-dev/vitest/releases/tag/v5.0.0-beta.2]

---

### Playwright Agents: AI-Driven E2E Test Creation  [community]

Playwright v1.56 (October 2024) introduced three first-party AI agents that work as a pipeline for creating and maintaining e2e test cases. Initialised via `npx playwright init-agents --loop=claude` (or `--loop=vscode`, `--loop=opencode`), the three agents produce a `specs/` directory of Markdown test plans and a `tests/` directory of generated Playwright test files.

**The three agents:**

| Agent | Job | Output |
|-------|-----|--------|
| **Planner** | Explores the app and produces a Markdown test plan for one or many scenarios. Accepts a user request, a `seed.spec.ts` bootstrapping file, and an optional PRD for context. | `specs/<scenario>.md` |
| **Generator** | Consumes a Markdown spec and produces an executable Playwright test file, verifying locators and assertions live against the running app during generation. | `tests/<scenario>.spec.ts` |
| **Healer** | Executes tests, replays failing steps, inspects the current UI to locate equivalent elements, and suggests patches (locator updates, wait adjustments, data fixes). Re-runs until tests pass or the underlying feature is confirmed broken. | Patched `tests/*.spec.ts` |

**Pyramid governance risk:** Playwright Agents generate *e2e-level* test cases by default — the agent explores the app from the outside. This creates the same AI pyramid drift problem as LLM code assistants (Gotcha #AI, gotcha #33 equivalent): if engineers use the full planner→generator→healer loop for every new feature, the e2e count grows while integration and unit counts stagnate. The healer loop is particularly prone to adding wait-based workarounds that are a form of the `sleep()` anti-pattern.

```typescript
// seed.spec.ts — required bootstrapping file for Playwright Agents
// Provides the agent with setup context (auth, base URL, fixture state)
import { test } from '@playwright/test';

// The seed test runs before the planner/generator to establish environment state
// Keep this minimal — agents extend it, not replace it
test.beforeAll(async ({ request }) => {
  // Seed test database with deterministic data for agent exploration
  await request.post('/api/admin/seed', {
    data: { scenario: 'standard-checkout', cleanup: true },
  });
});

// Provide a smoke test the agent can use as reference for the app's baseline state
test('app is reachable and home page loads', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');
});
```

**Integration with pyramid CI governance:** Add a post-agent PR check that counts generated tests vs. existing integration and unit coverage. Any PR that adds 3+ agent-generated e2e test cases without a corresponding integration test should trigger a review annotation:

```yaml
# .github/workflows/pyramid-agent-check.yml
- name: Check agent-generated e2e vs integration ratio
  run: |
    AGENT_E2E=$(git diff --name-only HEAD~1 | grep 'tests/.*spec\.ts' | wc -l)
    NEW_INTEGRATION=$(git diff --name-only HEAD~1 | grep '\.integration\.test\.ts' | wc -l)
    if [ "$AGENT_E2E" -gt 2 ] && [ "$NEW_INTEGRATION" -eq 0 ]; then
      echo "::warning::$AGENT_E2E agent-generated e2e tests added with 0 new integration tests. Consider pushing coverage down."
    fi
```

The `--loop=claude` flag integrates directly with Claude Code's agentic loop — the agents run inside an active Claude Code session, reading the test plan from `specs/` and writing to `tests/`. This is the recommended workflow for TypeScript projects already using Claude Code: use the healer only when the generator produces a failing test, and never run the healer in a loop without human review of the suggested patch. [official: playwright.dev/docs/test-agents]

---

### Playwright v1.57–v1.59: Diagnostic and Recording Utilities  [community]

Four additions in Playwright's v1.57–v1.59 series affect how TypeScript e2e test suites are diagnosed and configured:

**Speedboard HTML reporter tab (v1.57):** The HTML report now includes a "Speedboard" tab that displays all executed test cases sorted by execution duration. At the e2e test level, slowness is the primary cost driver — identifying the 10 slowest test cases per run allows targeted parallelisation or pyramid push-down (if a slow e2e test case can be replaced by a faster integration test case). The Speedboard is available with `--reporter=html` (the default); no additional configuration is required.

**`testConfig.webServer.wait` with named capture groups (v1.57):** The `webServer` configuration now accepts a `wait` object with a `stdout` regex. Named capture groups in the regex are exported as environment variables. This eliminates the pattern of hard-coding a port number in `playwright.config.ts`:

```typescript
// playwright.config.ts — dynamic port from webServer stdout
import { defineConfig } from '@playwright/test';

export default defineConfig({
  webServer: {
    command: 'npm run dev',
    // Named capture group 'port' → process.env.PORT
    wait: { stdout: /listening on port (?<port>\d+)/i },
    timeout: 30_000,
  },
  use: {
    // Playwright sets process.env.PORT from the named capture group
    baseURL: `http://localhost:${process.env['PORT'] ?? 3000}`,
  },
});
```

Previously, teams hard-coded `url: 'http://localhost:3000'` or used `reuseExistingServer: true` with a fixed port, causing failures when the dev server chose a different port. The named capture group pattern eliminates this flakiness category entirely for TypeScript Next.js and Vite projects that use random port allocation. [official: playwright.dev/docs/release-notes — v1.57]

**Service Worker network routing via `BrowserContext` (v1.57, Chromium only):** Network requests initiated by Service Workers are now routed through `BrowserContext`, making them available for `page.route()` and `browserContext.route()` interception. This closes a long-standing e2e test gap for TypeScript PWA projects: previously, Service Worker requests (background sync, push notifications, cache-first fetches) could not be intercepted in Playwright test cases — teams had to disable the Service Worker in test mode. With v1.57, full network control is available at the e2e level, including asserting on SW-initiated requests:

```typescript
// e2e/pwa-offline.e2e.test.ts — Service Worker request interception (v1.57, Chromium)
import { test, expect } from '@playwright/test';

test('Service Worker falls back to cache when API is offline', async ({ context, page }) => {
  // Allow initial load, then intercept SW network requests
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  // Intercept ALL network requests via context — now includes Service Worker requests
  await context.route('**/api/**', (route) => route.abort('connectionrefused'));

  // Trigger offline scenario — SW should serve from cache
  await page.reload();
  await expect(page.getByText('You are offline')).not.toBeVisible();
  await expect(page.getByRole('main')).toBeVisible(); // cached content served
});
```

Note: Service Worker routing works only in Chromium (Chrome/Edge). Firefox and WebKit do not expose SW requests through `BrowserContext`. When writing SW-related test cases, use `test.use({ browserName: 'chromium' })` to restrict execution.

**`page.screencast` API (v1.59):** Playwright v1.59 added a programmatic screencast API for capturing video with action annotations, visual overlays, and real-time JPEG frame streaming. While primarily intended for agentic workflows and demo recordings, it has a practical e2e testing application: teams can capture a screencast of a specific e2e test scenario as part of a `beforeAll` hook, producing annotated video evidence for compliance-required test documentation (particularly in regulated industries).

```typescript
// e2e/compliance/order-flow.e2e.test.ts — annotated screencast for audit trail
import { test, expect } from '@playwright/test';

test('order placement — captured with audit trail (regulated industries)', async ({ page }) => {
  await page.screencast.start({ path: `reports/order-flow-${Date.now()}.webm` });
  await page.screencast.showChapter('Order placement', {
    description: 'TC-ORDER-01: Guest user places an order',
    duration: 2_000,
  });

  await page.goto('/shop');
  await page.getByRole('button', { name: 'Add to cart' }).first().click();
  await page.screencast.showChapter('Checkout', { description: 'TC-ORDER-01: Checkout flow' });
  await page.getByRole('link', { name: 'Checkout' }).click();
  await page.getByRole('button', { name: 'Place order' }).click();

  await expect(page.getByRole('heading', { name: /order confirmed/i })).toBeVisible();
  await page.screencast.stop();
});
```

The screencast API is only available in browser contexts started with headed mode or explicit recording enabled. In headless CI, pair with Playwright's built-in `video: 'on-first-retry'` configuration rather than the screencast API. [official: playwright.dev/docs/release-notes — v1.59]

---

### Playwright v1.60: Context Events and Advanced Assertions  [community]

Three v1.60 additions that complement the test pyramid at the integration and e2e levels:

**`browser.on('context')` lifecycle events:** The browser instance now emits a `'context'` event when a new `BrowserContext` is created. Combined with the new `BrowserContext` lifecycle event mirroring (`download`, `frameattached`, `framenavigated`, `pageclose`, `pageload`), this enables cross-context monitoring patterns useful for multi-tab or multi-page e2e test scenarios. The practical use case: centrally logging context-level events in a `globalSetup` fixture without modifying individual test cases.

**`getByRole()` description option:** The `getByRole()` locator now accepts a `description` string to match the accessible description (aria-describedby or aria-description) in addition to the existing `name` option. This is important for test cases where multiple elements share the same role and name but differ in their descriptive text — common in data table rows, product cards, and form field groups:

```typescript
// Previously unreliable — two "Add to cart" buttons with different product descriptions
// await page.getByRole('button', { name: 'Add to cart' }).first().click(); // brittle

// v1.60: match by accessible description — deterministic without positional index
await page.getByRole('button', {
  name: 'Add to cart',
  description: 'TypeScript Handbook',
}).click();
```

**`toHaveCSS()` with pseudo-element option:** Assertions can now check computed styles on CSS pseudo-elements (`::before`, `::after`). This closes a gap in visual regression testing for TypeScript component libraries that use pseudo-elements for decorative indicators, badges, or state markers:

```typescript
// Check that the "required" indicator (::before pseudo-element) is present on a form field
await expect(page.getByLabel('Email')).toHaveCSS('content', '"*"', {
  pseudo: '::before',
});
```

**`testInfoError.errorContext`:** When a Playwright assertion fails, the `testInfoError` now includes an `errorContext` property with structured diagnostic data — for example, an ARIA snapshot of the failing assertion's target element. This surfaces automatically in the HTML report, making it significantly faster to diagnose failures without replaying the trace. [official: playwright.dev/docs/release-notes — v1.60]

---

### Playwright v1.60: WebSocket Testing at the Integration Test Level  [community]

`webSocketRoute.protocols()` (v1.60) returns the WebSocket subprotocols requested by the page during a `context.routeWebSocket()` handler. This enables integration-level WebSocket testing patterns where the protocol negotiation itself is part of the test contract:

```typescript
// tests/integration/ws-chat.integration.test.ts — WebSocket protocol verification
// Uses Playwright's route API at the HTTP/WS boundary (integration-level, no browser needed for logic)
import { test, expect } from '@playwright/test';

test('chat service negotiates the correct WebSocket subprotocol', async ({ page, context }) => {
  let negotiatedProtocols: string[] = [];

  // Intercept WebSocket connections before they reach the server
  await context.routeWebSocket('wss://chat.example.com/ws', (wsRoute) => {
    // v1.60: capture protocols requested by the client
    negotiatedProtocols = wsRoute.protocols();
    // Continue to real server — this is an assertion test, not a stub
    wsRoute.connectToServer();
  });

  await page.goto('/chat');
  await page.getByRole('button', { name: 'Connect' }).click();
  await expect(page.getByRole('status')).toContainText('Connected');

  // Assert that the client correctly negotiated the v2 chat protocol
  expect(negotiatedProtocols).toContain('chat-v2');
  expect(negotiatedProtocols).not.toContain('chat-v1'); // deprecated protocol
});
```

WebSocket tests sit at the integration test level when the WebSocket server is a real (or stubbed) service and the assertion is on the protocol or message structure — not at the e2e level. Use `context.routeWebSocket()` for this; reserve e2e test cases for user-visible WebSocket-driven UI behaviour (messages appearing, connection state badges). [official: playwright.dev/docs/release-notes — v1.60]

---

### Vitest 4.1: `vi.defineHelper` for Clean Custom Assertion Stack Traces  [community]

Custom assertion helpers at the integration and unit test levels produce confusing stack traces when they fail — the error points to the implementation line of the helper rather than the test case that called it. `vi.defineHelper` (Vitest 4.1) wraps a function to strip its internal frames from the stack, redirecting the error pointer to the call site:

```typescript
// tests/helpers/assertions.ts — typed custom assertions using vi.defineHelper (Vitest 4.1)
import { expect, vi } from 'vitest';
import type { OrderResponse } from '../../src/orders/types.js';

// Without vi.defineHelper: stack trace points to "expect(response.status).toBe(201)" line below
// With vi.defineHelper: stack trace points to the test case that called assertOrderCreated()
export const assertOrderCreated = vi.defineHelper((response: OrderResponse) => {
  expect(response.status).toBe('pending');
  expect(response.id).toMatch(/^ord_/);
  expect(response.createdAt).toBeInstanceOf(Date);
});

// Usage in integration test:
// it('creates an order', async () => {
//   const result = await service.create(input);
//   assertOrderCreated(result);  // ← stack trace points HERE on failure, not inside assertOrderCreated
// });
```

The ergonomic improvement is most noticeable in large integration test suites where many test cases share domain-specific assertion helpers. The `vi.defineHelper` wrapper also works with async helper functions. [official: vitest.dev/blog/vitest-4-1.html]

---

### Vitest 4.1: `coverage.changed` for Per-PR Coverage Delta  [community]

The `coverage.changed` option (Vitest 4.1) runs all test cases but restricts coverage reporting to only the files changed relative to the git baseline. This allows CI to enforce a "no new uncovered code" policy without re-running coverage on the entire codebase on every PR — useful in large TypeScript monorepos where full coverage collection takes minutes.

```typescript
// vitest.config.ts — coverage.changed for incremental coverage enforcement
import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'lcov'],
      // coverage.changed: only report coverage for files modified in the current git diff
      // All tests still run; this limits the coverage summary to changed files only
      changed: process.env['CI_PR'] === 'true',
      // Thresholds apply only to the changed files subset when coverage.changed is true
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
    },
  },
});
```

```yaml
# .github/workflows/test.yml — per-PR coverage check
- name: Run unit + integration tests with changed-file coverage
  run: vitest run --coverage
  env:
    CI_PR: "true"
  # Coverage report only covers files changed in this PR — not the entire codebase
  # Fails if branch/line coverage on changed files drops below 80%
```

**Pyramid application:** Use `coverage.changed` at the unit and integration levels (where coverage is meaningful) and disable it at the e2e level (where coverage collection adds significant overhead without useful signal). In a Vitest workspace with three projects, enable `changed: true` only in the `unit` and `integration` project configurations. [official: vitest.dev/blog/vitest-4-1.html]

---

### Vitest 4.1 Browser Mode: Trace Annotations with `page.mark()`  [community]

Vitest 4.1 introduced `page.mark()` and `locator.mark()` APIs for the browser-mode integration test level. These insert named markers into the Playwright trace timeline, grouping related interactions under a single label. The trace annotations are linked back to the test file line, making it faster to navigate complex component test failures in the Playwright Trace Viewer.

```typescript
// src/checkout/CheckoutFlow.ct.test.tsx — Vitest 4.1 browser mode with trace marks
import { test, expect, page } from 'vitest/browser';
import { render } from 'vitest-browser-react';
import { CheckoutFlow } from './CheckoutFlow.js';

test('completes checkout flow — marked trace sections', async () => {
  const component = await render(<CheckoutFlow />);

  // Mark the trace at key steps — shows as named sections in Playwright Trace Viewer
  await page.mark('step: fill shipping details');
  await component.getByLabel('Email').fill('user@example.com');
  await component.getByLabel('Address').fill('123 Main St');

  await page.mark('step: payment');
  await component.getByLabel('Card number').fill('4242424242424242');
  await component.getByLabel('Expiry').fill('12/30');

  await page.mark('step: submit + assert');
  await component.getByRole('button', { name: 'Place order' }).click();
  await expect.element(component.getByRole('heading', { name: /confirmed/i })).toBeVisible();
});
```

`locator.mark()` applies a temporary visual highlight to a specific element in the trace, useful when multiple elements match a locator and you need to confirm which one was interacted with. Both `page.mark()` and `locator.mark()` are no-ops in non-browser environments — safe to leave in test files shared across browser and node projects in a Vitest workspace. [official: vitest.dev/blog/vitest-4-1.html]

---

### TypeScript 6.0: `esModuleInterop` Always True  [community]

TypeScript 6.0 makes `esModuleInterop: true` the permanent default — it can no longer be set to `false`. This affects TypeScript test files that use the legacy `import * as X from 'module'` pattern for CommonJS default exports. The pattern was widely used in test setup files before ESM adoption:

```typescript
// BEFORE TypeScript 6.0 (pattern used in legacy Jest/Mocha setups)
// import * as path from 'path';   // OK with esModuleInterop: false
// import * as fs from 'fs';        // OK with esModuleInterop: false

// AFTER TypeScript 6.0 (esModuleInterop always true)
import path from 'node:path';    // default import — correct with esModuleInterop
import { readFileSync } from 'node:fs';  // named import still works

// Common failure pattern in test helpers after upgrading to TS 6.0:
// import * as supertest from 'supertest';  // TS error: module has default export
import request from 'supertest';            // correct form

// Jest-specific: jest.mock() factory used with import * as
// OLD (breaks in TS 6.0): import * as myModule from './module';
//                          jest.mock('./module', () => ({ ... }));
// NEW: import myModule from './module';
//      vi.mock('./module', () => ({ default: { ... } }));
```

The change is compile-time only — `esModuleInterop: true` was already the runtime default in most bundler configurations. The failure mode is subtle: test files that compiled correctly under TS 5.x produce `TS2540` (Cannot assign to X because it is not a variable) or `TS1202` (Import assignment cannot be used when targeting ECMAScript modules) errors after upgrading. Run `tsc --noEmit` across all test configs immediately after upgrading to TS 6.0 to surface all affected files. [official: typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html]

**Community gotcha #33:** Teams using `@types/node` with `import * as path from 'path'` patterns in test setup files (`vitest.setup.ts`, `jest.setup.ts`) are the most common victims. The fix is a one-line change per import, but in large codebases with hundreds of test files, an automated codemod (`npx ts-morph-codemod` or a custom `jscodeshift` transform) is faster than manual updates.

---

### Node.js v22.18+ Native TypeScript Execution for Unit Tests  [community]

Node.js v22.18.0 (released July 31, 2025, LTS codename 'Jod') ships with TypeScript type stripping enabled by default. On Node.js 22.18+, test files written in TypeScript can be executed directly with bare `node` — no `tsx`, `ts-node`, or Vitest transpilation required for simple cases. The old `--experimental-strip-types` flag is no longer needed on this release and later.

```bash
# Node.js 22.18+ — run a TypeScript unit test file directly
node src/pricing/discount.unit.test.ts
# Previously required: npx tsx src/pricing/discount.unit.test.ts
```

This changes the economics of the unit test level: for pure-logic TypeScript test files (no decorators, no enums, no legacy namespaces), the startup overhead of a transpiler step disappears. Paired with `--erasableSyntaxOnly` in TypeScript 5.8+, teams can enforce that production code stays within Node.js's strippable subset at compile time.

**Critical limitations for the test pyramid:**

| Feature | Supported by bare `node` | Workaround |
|---------|--------------------------|------------|
| `interface`, `type`, `as`, `: Type` annotations | Yes | — |
| Generic type parameters | Yes | — |
| `export type` / `import type` | Yes | — |
| `enum` declarations | No (`ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX`) | `--experimental-transform-types` or Vitest |
| `namespace` with values | No | Avoid legacy namespaces |
| Parameter properties (`constructor(public name: string)`) | No | Use explicit `public name: string;` then assign in body |
| Decorators (`@Injectable`, `@Module`, `@Component`) | No | Use Vitest (esbuild transform) for NestJS/Angular projects |
| Non-`type` import specifiers for type-only symbols | No (may cause runtime errors) | Always use `import type { X }` for type-only imports |

The practical consequence for the test pyramid: **NestJS integration test cases cannot use bare `node` for execution**. NestJS modules use `@Injectable()`, `@Module()`, `@Controller()`, and constructor parameter properties extensively — all of which are unsupported by the stripper. For NestJS projects, Vitest (which uses esbuild transform) remains the required test runner. Reserve bare `node` execution for plain TypeScript utility/service test files with no decorator usage.

```typescript
// src/pricing/discount.unit.test.ts — compatible with bare node execution
// Requires: Node.js 22.18+ AND no enums/decorators/parameter properties/legacy namespaces
// Run: node --test src/pricing/discount.unit.test.ts

// Node.js built-in test runner (no Vitest needed for simple unit tests)
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { calculateDiscount } from './discount.js';
import type { DiscountInput } from './discount.js';

describe('calculateDiscount', () => {
  it('applies 10% for standard members over $100', () => {
    const input: DiscountInput = { total: 150, membershipTier: 'standard' };
    assert.strictEqual(calculateDiscount(input), 15);
  });

  it('applies no discount for orders under $100', () => {
    const input: DiscountInput = { total: 80, membershipTier: 'standard' };
    assert.strictEqual(calculateDiscount(input), 0);
  });

  it('applies 20% for gold members regardless of total', () => {
    const input: DiscountInput = { total: 50, membershipTier: 'gold' };
    assert.strictEqual(calculateDiscount(input), 10);
  });
});
```

Note: the Node.js built-in test runner (`node:test`) uses `assert` from `node:assert/strict` rather than Vitest's `expect`. This produces a two-runner situation if some test cases use Vitest and others use `node:test`. For codebases with a unified Vitest pyramid, use Vitest for all test levels — the startup cost difference between Vitest and bare `node` is negligible for a full test run. Reserve bare `node` for isolated utility scripts that double as tests (e.g., a build-time schema validation script). [official: nodejs.org/en/learn/typescript/run-natively, nodejs.org/en/blog/release/v22.18.0]

---

### Node.js 24 Test Runner: Breaking Changes and New Capabilities  [community]

Node.js 24 (released April 2025) introduced semver-major changes to the built-in test runner that break existing test pipelines using `node:test`. Teams maintaining test suites that use the built-in runner alongside Vitest (e.g., in CI scripts or in `package.json` scripts using `--test`) need to audit before upgrading.

**Breaking change: `t.test()` and `test()` no longer return Promises.**

Prior to Node.js 24, `t.test()` returned a `Promise<void>`, allowing this pattern:

```typescript
// BEFORE Node.js 24 — pattern that BREAKS
import { test } from 'node:test';

// Old pattern: await the inner test to control ordering
await test('parent test', async (t) => {
  const result = await t.test('child test', () => {
    // assertions
  });
  // result was Promise<void> — awaiting gave ordering control
});
```

In Node.js 24, `t.test()` returns `void`. The test runner automatically waits for all subtests before proceeding. The correct pattern after Node.js 24:

```typescript
// AFTER Node.js 24 — correct pattern
import { test } from 'node:test';
import assert from 'node:assert/strict';

test('parent test', (t) => {
  // No await needed — runner handles ordering automatically
  t.test('child test', () => {
    assert.strictEqual(1 + 1, 2);
  });
  // The runner waits for all t.test() calls automatically
});
```

**Pyramid impact:** Any CI script that uses `node --test` and previously relied on `await t.test()` will silently succeed on Node.js 24 (the call is now `void`; `await void` is a no-op), but timing-dependent tests may run in unexpected order. Audit with `grep -r "await t.test\|await test(" --include="*.ts"` before upgrading Node.js.

**New capabilities in Node.js 24 test runner:**

| Feature | Use in the pyramid |
|---------|--------------------|
| Global setup and teardown | Integration-level: set up shared containers once per run; analogous to Vitest's `globalSetup` option |
| Per-test `--test-timeout` | Unit level: enforce the `< 10 ms` unit test constraint at the runner level rather than per-`it()` |
| JSON module mocking (`t.mock.module('data.json')`) | Unit level: mock JSON config files without touching the file system |
| Watch mode restart duration accuracy | Development workflow: accurate elapsed time in hot-reload test cycles |

```bash
# CI usage: per-test timeout enforced at runner level
node --test --test-timeout=10000 src/**/*.unit.test.ts
# Integration tests: longer timeout
node --test --test-timeout=60000 tests/integration/**/*.test.ts
```

Node.js 24 also marks TypeScript type stripping as a "release candidate" (`--experimental-strip-types` is stabilising) and introduces `import.meta.main` for ESM (analogous to `if __name__ == '__main__'` in Python — useful for test files that are also runnable scripts). [official: nodejs.org/en/blog/release/v24.0.0]

---

### Vitest 4.1 Additional Ergonomic Improvements  [community]

Three Vitest 4.1 additions not covered in the previous section improve developer experience at the unit and integration test levels:

**`mockThrow` / `mockThrowOnce`:** Creates cleaner error-path unit test cases. The previous pattern (`vi.fn().mockImplementation(() => { throw new Error('...') })`) was verbose. `mockThrow` is the direct equivalent:

```typescript
// src/orders/orders.service.unit.test.ts — Vitest 4.1 mockThrow
import { describe, it, expect, vi } from 'vitest';
import { OrdersService } from './orders.service.js';
import type { OrderRepository } from './order.repository.js';

const mockRepo: OrderRepository = {
  create: vi.fn(),
  findById: vi.fn(),
  findAll: vi.fn(),
  delete: vi.fn(),
};

describe('OrdersService error paths', () => {
  it('surfaces repository errors without swallowing them', async () => {
    const service = new OrdersService(mockRepo);
    const dbError = new Error('connection refused');

    // Vitest 4.1: mockThrow — more readable than mockImplementation(() => { throw ... })
    vi.mocked(mockRepo.create).mockThrow(dbError);

    await expect(
      service.create({ customerId: 'c1', items: [{ sku: 'A1', qty: 1 }] }),
    ).rejects.toThrow('connection refused');
  });

  it('uses mockThrowOnce for error on first call, success on retry', async () => {
    const service = new OrdersService(mockRepo);
    const savedOrder = { id: 'ord_001', customerId: 'c1', items: [], status: 'pending' as const, createdAt: new Date() };

    // First call throws; second call succeeds — tests retry logic
    vi.mocked(mockRepo.create)
      .mockThrowOnce(new Error('transient error'))
      .mockResolvedValue(savedOrder);

    // Assumes service has retry logic for transient errors
    const result = await service.createWithRetry({ customerId: 'c1', items: [{ sku: 'A1', qty: 1 }] });
    expect(result.id).toBe('ord_001');
  });
});
```

**GitHub Actions Job Summary reporter:** When running in GitHub Actions, Vitest 4.1 automatically generates a job summary that includes: test count per level, failure details, and — critically — a flaky tests section that lists any test cases that required retries before passing. Each entry includes a permalink URL to the source file at the exact line. This surfaces flaky test cases in the PR interface without requiring developers to read raw CI logs. Enable `--reporter=github-actions` (or add it to the `reporters` array) to activate the summary generation; the `jobSummary` configuration option controls whether the summary includes test run metadata.

**Agent reporter mode:** Vitest 4.1 ships a minimal reporter (`reporter: 'agent'`) that suppresses all output except failing tests and their error messages. It is auto-enabled when `AI_AGENT=copilot` (or equivalent) is set in the environment — `std-env` detects common AI coding tool contexts automatically. The practical pyramid use case: AI coding assistants (GitHub Copilot, Claude Code, Cursor) that run tests as part of their agentic loop no longer receive thousands of lines of passing-test output, reducing token consumption and improving the agent's ability to act on the actual failures.

```typescript
// vitest.config.ts — GitHub Actions Job Summary + agent mode configuration
import { defineConfig, defineProject } from 'vitest/config';

export default defineConfig({
  test: {
    // In CI: add github-actions to see flaky test highlights in PR job summary
    reporters: process.env['GITHUB_ACTIONS']
      ? ['default', 'github-actions']
      : ['default'],
    // Agent reporter is auto-detected via std-env;
    // to force it: reporters: ['agent']
  },
});
```

**Vite 8 dependency deduplication (Vitest 4.1):** Vitest 4.1 now uses the project's installed `vite` version directly rather than bundling a separate copy. This eliminates the TypeScript type inconsistencies that appeared when `vitest.config.ts` types from bundled Vite conflicted with application `vite.config.ts` types — a common error in monorepos where the application and test runner share a `vite.config.ts` root. No configuration change required; the deduplication is automatic. [official: vitest.dev/blog/vitest-4-1.html]

---

### Vitest 3.2: Additional Low-Level Improvements  [community]

Three Vitest 3.2 capabilities that improve the operational side of a three-level test pyramid:

**Custom project name colors:** Each Vitest project in a workspace can now specify a `color` property (`'red' | 'green' | 'yellow' | 'blue' | 'magenta' | 'cyan'`). In a three-project pyramid setup, assigning distinct colors to `unit` (green), `integration` (yellow), and `e2e` (red) makes multi-project parallel output immediately scannable — test failures in the expensive e2e level are visually distinct from fast unit failures:

```typescript
// vitest.config.ts — project name colors for visual pyramid distinction
import { defineConfig, defineProject } from 'vitest/config';

export default defineConfig({
  test: {
    projects: [
      defineProject({
        extends: true,
        test: { name: { label: 'unit', color: 'green' }, include: ['src/**/*.unit.test.ts'] },
      }),
      defineProject({
        extends: true,
        test: { name: { label: 'integration', color: 'yellow' }, include: ['src/**/*.integration.test.ts'] },
      }),
      defineProject({
        extends: true,
        test: { name: { label: 'e2e', color: 'red' }, include: ['e2e/**/*.e2e.test.ts'] },
      }),
    ],
  },
});
```

**`locators.extend` for browser-mode test maintenance:** Vitest 3.2 browser mode introduced a `locators.extend` API that allows projects to define application-specific locators as first-class selectors with built-in retry behaviour. Instead of falling back to brittle CSS selectors when a semantic ARIA locator isn't available, teams can register custom locators for domain-specific elements (e.g., `page.getByTestStatus('pending')` maps to a `data-test-status="pending"` attribute query with retry). This is the browser-mode equivalent of Playwright's `locator.filter()` chains — reducing locator maintenance cost in large component test suites.

**V8 AST-aware coverage remapping:** Vitest 3.2 replaced the previous V8 coverage source-map approach with `ast-v8-to-istanbul` — an AST-based remapping that aligns V8 coverage output with Istanbul's branch coverage semantics. The practical effect: branch coverage numbers for TypeScript projects become more accurate (fewer phantom uncovered branches from TypeScript decorators and type assertions) and the coverage report's highlighted branches match what a human would consider a real branch. Teams running Stryker mutation testing alongside Vitest coverage may see coverage percentage changes after upgrading to 3.2 — not because coverage changed, but because the measurement became more accurate. [official: vitest.dev/blog/vitest-3-2.html]

---

### Vitest 5.0 Beta: Additional Changes for CI Pipelines  [community]

Beyond the breaking changes documented in the earlier Vitest 5.0 section (sequential removal, attachment directory, expect inlining), three new capabilities in the beta affect CI pipeline integration:

**Non-sharded multi-environment merge reports:** Previously, Vitest's `--merge-reports` command required all reports to come from a sharded (parallelised) run of the same environment. Vitest 5.0 beta lifts this restriction: reports from separate environments (e.g., `unit` project run on one machine and `integration` project run on another) can be merged into a single HTML/JUnit report. This is particularly useful in matrix CI pipelines where unit tests run on every OS and integration tests run only on Linux — the final merged report covers the full pyramid.

```yaml
# .github/workflows/test.yml — multi-environment merge report (Vitest 5.0+)
jobs:
  unit:
    runs-on: ubuntu-latest
    steps:
      - run: vitest run --project unit --reporter=blob --outputFile=.vitest/blob/unit-${{ matrix.os }}.blob
  integration:
    runs-on: ubuntu-latest
    steps:
      - run: vitest run --project integration --reporter=blob --outputFile=.vitest/blob/integration.blob
  report:
    needs: [unit, integration]
    steps:
      # Download all blob artifacts
      - run: vitest merge-reports .vitest/blob/ --reporter=html
      # Vitest 5.0: accepts blobs from different environments (unit + integration) in one merge
```

**JUnit jest-junit-compatible naming:** Vitest 5.0 adds options to the JUnit reporter that match `jest-junit`'s configuration keys (`classname`, `suiteName`, `ancestorSeparator`). This eases migration from Jest to Vitest without requiring updates to test reporting infrastructure (Datadog CI Visibility, JetBrains TeamCity, Azure DevOps) that parse JUnit XML with `jest-junit`-specific attribute names.

**`configDefaults.reporters`:** The `configDefaults` export from `vitest/config` now includes the `reporters` array, allowing CI scripts to programmatically read the default reporter list and add to it rather than replacing it — preventing accidental loss of the default `verbose` or `dots` reporter when adding `json` for CI artifact collection. [community: github.com/vitest-dev/vitest/releases/tag/v5.0.0-beta.2]

---

36. **Node.js native TypeScript execution fails silently for NestJS integration test cases** [community] — Node.js 22.18+ enables TypeScript type stripping by default, and many teams begin running `node test.ts` directly without reading the limitations. The most common failure: NestJS integration test cases use `@Injectable()`, `@Module()`, `@Controller()`, and constructor parameter property shorthand (`constructor(private readonly repo: OrderRepo)`) — all of which are unsupported by Node.js's type stripper. The failure mode is a cryptic `ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX` at runtime, not a TypeScript compile error. Fix: continue using Vitest (which transpiles via esbuild) for all NestJS-related test levels. Reserve bare `node` execution for utility test files with zero decorators, zero `enum` declarations, and zero parameter property constructors. Add a CI check: `grep -r "constructor(private\|constructor(public\|constructor(protected" tests/ && echo "ERROR: parameter properties — use Vitest, not bare node"`. [official: nodejs.org/api/typescript.html#type-stripping]

37. **Node.js 24 `t.test()` returning `void` silently invalidates await-based test ordering** [community] — Before Node.js 24, `t.test()` returned a `Promise`. Teams wrote `await t.test('step 1', ...)` to enforce sequential execution of nested test cases. In Node.js 24, `t.test()` returns `void` — `await void` is a no-op — so the ordering guarantee vanishes silently. Tests may run out of the expected sequence, producing non-deterministic results for test cases that share mutable state. The defect is especially common in integration test scripts that spin up resources in parent test setup and tear them down in a later `t.test()` call that was formerly awaited for sequencing. Fix: use the runner's `before`/`after` hooks instead of nested `t.test()` sequences for resource lifecycle, and use Vitest's `sequence.groupOrder` for explicit pyramid-level ordering. Audit with `grep -rn "await t\.test\|await test(" --include="*.ts" tests/` before upgrading to Node.js 24. [official: nodejs.org/en/blog/release/v24.0.0 — semver-major test_runner changes]

38. **Vitest 4.1 browser mode strict locators silently hide multi-match defects in earlier versions** [community] — Before Vitest 4.1, the browser mode locator resolution for WebdriverIO and Preview providers allowed a locator to silently resolve to the first matching element when multiple elements matched. Test cases passed even when the intended element was ambiguous — a hidden defect that only surfaced when the DOM order changed. Vitest 4.1 enforces strict mode by default: if a locator resolves to multiple elements, Vitest throws a "strict mode violation" error immediately. Teams upgrading to 4.1 often discover pre-existing ambiguous locators in their component test suite that were previously masked. This is a desirable behaviour improvement, but it produces a wave of test failures at upgrade time that must be triaged before the suite can pass. Fix: audit all `page.getBy*()` calls in browser-mode test files for potential multi-match; add `{ strict: false }` only where intentional (e.g., asserting that multiple elements exist). Prefer `getByRole`, `getByLabel`, and `getByText` with precise text over CSS-class-based locators. [official: vitest.dev/blog/vitest-4-1.html — browser locators strict mode]

39. **Node.js 22.18+ `enum` in shared test utility files breaks native execution transitively** [community] — Many TypeScript codebases define shared test constants using `enum` declarations in a `tests/helpers/` directory (e.g., `enum TestStatus { Pass, Fail, Skip }`). When Node.js 22.18+ is used with bare `node` for unit test execution and a test file imports from a helper that contains an `enum`, the import fails at runtime even if the calling test file itself has no `enum`. The error is `ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX` at the point of the import — not at the test file level. This makes the root cause hard to identify because the failing file is a helper, not the test itself. Fix: replace all `enum` declarations in test helpers with `const` objects + `as const` assertions (`const TestStatus = { Pass: 'pass', Fail: 'fail', Skip: 'skip' } as const`), which are erasable and compatible with Node.js native execution. Run `grep -r "^enum " src/ tests/ --include="*.ts"` to find all `enum` declarations in the codebase. [official: nodejs.org/api/typescript.html#type-stripping — unsupported syntax list]

40. **Vitest 5.0 beta `locator` representation change breaks custom assertion helpers** [community] — Vitest 5.0 beta changes how locators are serialized in error messages and assertion output: previously represented as a string (e.g., `"getByRole('button', {name: 'Submit'})"`) they are now represented as an object. Teams with custom assertion helpers that parse the locator string representation (e.g., to extract the role name for a custom error message) will encounter runtime errors after upgrading. This pattern is uncommon but appears in large component test suites that built tooling around Vitest's output. The fix is to stop parsing locator strings and instead use Vitest's `locator.evaluate()` or the locator's structured properties. Pin to `vitest@^4.1` until Vitest 5.0 stable is released and locator API documentation is finalised. [community: github.com/vitest-dev/vitest/releases/tag/v5.0.0-beta.2]

41. **Node.js 24.14.0 `expectFailure` used as quarantine creates a growing dead weight in the test suite** [community] — Node.js 24.14.0 LTS (March 2026) added `expectFailure: true` as a test option in the built-in `node:test` runner — the Node.js equivalent of pytest's `@pytest.mark.xfail`. A test marked with `expectFailure: true` is expected to fail; if it passes, the runner reports it as a test defect (an unexpected pass). This is intentionally designed as a temporary marker for known-broken tests that cannot be fixed immediately. The misuse pattern: teams adopt `expectFailure` as a permanent quarantine mechanism at the integration test level, creating a growing set of "known failing" integration test cases that are never fixed. Unlike Vitest's `--tags-filter="!flaky"` quarantine (which keeps failing tests visible and tracked separately), `expectFailure` makes the test suite appear green even as the number of expected failures grows. Fix: treat `expectFailure` as a time-boxed marker only. Add a CI check that fails if more than 5 `expectFailure` options exist in the integration test level — for example: `grep -r "expectFailure: true" tests/integration/ | wc -l` compared to a threshold. Always pair an `expectFailure` test with a linked issue URL in a comment so it is discoverable and removable. [official: nodejs.org/en/blog/release/v24.14.0 — node:test expectFailure option]

---

### Node.js 24 LTS: `expectFailure` and `env` in the Built-In Test Runner  [community]

Node.js 24.14.0 LTS (released March 24, 2026) added two targeted improvements to the built-in `node:test` runner that affect how teams using `node --test` (rather than Vitest) manage their pyramid test suite:

**`expectFailure` option:** Marks a test case as expected to fail. If the test fails, the runner reports a pass; if it unexpectedly passes, the runner reports it as a test defect. This provides an xfail semantic for integration test cases that depend on known-broken infrastructure or third-party API changes that cannot be fixed immediately.

**`env` option on `run()`:** The programmatic `run()` API now accepts an `env` object that sets environment variables for the test run without modifying `process.env` of the parent process. This is particularly useful for integration-level TypeScript CI scripts that programmatically invoke the test runner with different environment configurations (e.g., different `DATABASE_URL` values for separate integration test suites).

```typescript
// tests/integration/run-integration.ts — Node.js 24.14.0 test runner programmatic API
// Run: node --test tests/integration/run-integration.ts
import { run } from 'node:test';
import { Readable } from 'node:stream';

// env option: inject environment variables without polluting process.env
// Useful for running integration tests against different environments in CI
const stream = run({
  files: ['tests/integration/orders.integration.test.ts'],
  env: {
    // Override DATABASE_URL just for this run — parent process.env is unchanged
    DATABASE_URL: process.env['CI_INTEGRATION_DB_URL'] ?? 'postgresql://localhost:5432/testdb',
    NODE_ENV: 'test',
  },
  timeout: 60_000,
});

// Stream output to stdout while capturing exit code
stream.pipe(process.stdout);
stream.on('test:fail', () => { process.exitCode = 1; });
```

```typescript
// src/orders/orders.integration.test.ts — expectFailure for known-broken external dependency
// Node.js 24.14.0: expectFailure marks this test as "expected to fail"
// Use only temporarily — pair with a GitHub issue URL, never as permanent quarantine
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { OrdersService } from '../src/orders/orders.service.js';

// TODO: Remove expectFailure after payment-provider API migration — see GH-1234
test('payment provider webhook signature verification', {
  expectFailure: true,   // Node.js 24.14.0: test is expected to fail until GH-1234 is resolved
  timeout: 30_000,
}, async () => {
  const service = new OrdersService();
  // This test fails because the payment provider changed their HMAC algorithm in v3.0
  // and our verification logic has not been updated yet
  const result = await service.verifyWebhookSignature('test-payload', 'invalid-sig-v3');
  assert.strictEqual(result.valid, true);
});

// Unexpected pass (test suddenly starts passing) is reported as a test defect —
// signalling that the underlying fix has been deployed and expectFailure should be removed
```

The `expectFailure` feature is most relevant at the integration test level where external dependencies (third-party APIs, cloud services, database schema migrations in progress) may temporarily be in a broken state. It is NOT appropriate for flaky tests caused by non-determinism — use the Vitest `--tags-filter="!flaky"` quarantine for those. The critical governance rule: `expectFailure` must have a bounded lifetime. Add an expiry date in a comment (`// expires: 2026-06-01 — see GH-1234`) and add a CI step that warns when `expectFailure` entries exceed the team threshold or are older than 30 days. [official: nodejs.org/en/blog/release/v24.14.0]

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| TestPyramid (Fowler) | Official | https://martinfowler.com/bliki/TestPyramid.html | Canonical definition and original rationale |
| Practical Test Pyramid | Official | https://martinfowler.com/articles/practical-test-pyramid.html | Detailed layer-by-layer breakdown with code examples |
| Microservice Testing Strategies (Fowler/Clemson) | Official | https://martinfowler.com/articles/microservice-testing/ | 5-layer pyramid: unit → integration → component → contract → e2e |
| On the Diverse And Fantastical Shapes of Testing | Community | https://martinfowler.com/articles/2021-test-shapes.html | Pyramid vs honeycomb vs trophy debate; Justin Searls on quality > ratio |
| Write Tests (Kent C. Dodds) | Community | https://kentcdodds.com/blog/write-tests | Testing Trophy origin; "write tests, not too many, mostly integration" |
| Just Say No to More End-to-End Tests (Google) | Community | https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html | Production experience at scale; cost analysis of e2e over-investment |
| Test Sizes (Google) | Community | https://testing.googleblog.com/2010/12/test-sizes.html | Small/Medium/Large taxonomy as practical alternative to pyramid |
| Spotify Honeycomb | Community | https://engineering.atspotify.com/2018/01/testing-of-microservices/ | Microservice-specific reshape of the pyramid |
| Testcontainers for Node | Tool | https://testcontainers.com/guides/getting-started-with-testcontainers-for-nodejs/ | Real integration tests against containerised dependencies; TypeScript typings included |
| Neon DB Branch Testing | Tool | https://neon.com/docs/guides/branching-test-queries | Copy-on-write Postgres branch per test run; alternative to testcontainers for cloud-native TypeScript |
| Playwright | Tool | https://playwright.dev/docs/intro | Modern e2e testing for TypeScript/Node; first-class TypeScript support |
| React Testing Library | Tool | https://testing-library.com/docs/react-testing-library/intro/ | Integration-layer testing aligned with Testing Trophy |
| MSW (Mock Service Worker) | Tool | https://mswjs.io/docs/ | Network boundary mocking; TypeScript handler types prevent handler drift |
| Vitest | Tool | https://vitest.dev/guide/ | Fast Jest-compatible test runner with first-class TypeScript + ESM support; no Babel needed |
| Vitest Projects API | Tool | https://vitest.dev/guide/projects.html | defineProject + extends API for type-safe workspace pyramid configuration |
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
| Playwright Release Notes | Tool | https://playwright.dev/docs/release-notes | Clock API (v1.45), Aria Snapshots (v1.49), tsconfig option (v1.50), screencast API (v1.59), test.abort + page ARIA snapshot (v1.60) |
| How They Test | Community | https://abhivaikar.github.io/howtheytest/ | 108 companies, 797 resources — real-world test pyramid ratios, strategies, and culture from production engineering orgs |
| Mocks Aren't Stubs (Fowler) | Community | https://martinfowler.com/articles/mocksArentStubs.html | Canonical taxonomy: Dummy/Fake/Stub/Spy/Mock; Classical vs Mockist TDD; when to use each at each pyramid level |
| Vitest 3.0 Release | Tool | https://vitest.dev/blog/vitest-3.html | Inline workspace config, multi-browser instances, reporter redesign, public node API stabilisation |
| Vitest 3.2 Release | Tool | https://vitest.dev/blog/vitest-3-2.html | Annotation API, Scoped Fixtures (scope:file|worker), `using vi.spyOn()` resource management, Test Signal API (AbortSignal), sequence.groupOrder for fail-fast, workspace config deprecated |
| Vitest 4.0 Release | Tool | https://vitest.dev/blog/vitest-4.html | Browser mode stable, toMatchScreenshot visual regression, expect.schemaMatching (Zod/Valibot), Playwright trace support |
| Vitest 4.1 Release | Tool | https://vitest.dev/blog/vitest-4-1.html | Test tags + --tags-filter, aroundEach/aroundAll hooks, --detect-async-leaks, viteModuleRunner:false, test.extend builder pattern |
| TypeScript 5.8 Release Notes | Official | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-8.html | `--module node18` stable, `import with {type:'json'}` replaces assert form, granular return-expression branch checking, `--erasableSyntaxOnly` + Node.js type-stripping |
| TypeScript 6.0 Release Notes | Official | https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html | `--stableTypeOrdering`, deprecated option removal path, TS 7.0 migration preparation; `--erasableSyntaxOnly` for Node.js type-stripping; BREAKING: `types:[]`, `strict:true`, `module:esnext`, `rootDir:.` new defaults |
| Vitest 5.0 Beta | Tool | https://github.com/vitest-dev/vitest/releases/tag/v5.0.0-beta.2 | Next major version (beta May 2026): inline expect, sequential removal, .vitest/ directory restructure, V8 worker coverage — audit before upgrading |
| Playwright Agents | Tool | https://playwright.dev/docs/test-agents | v1.56+: planner/generator/healer AI agents for e2e test creation; pyramid governance required to prevent e2e over-generation |
| Playwright HTML Speedboard | Tool | https://playwright.dev/docs/test-reporters#html-reporter | v1.57+: Speedboard tab in HTML report — sorts test cases by execution duration; identifies pyramid push-down candidates |
| Node.js v22.18.0 Release | Official | https://nodejs.org/en/blog/release/v22.18.0 | TypeScript type stripping enabled by default (LTS, Jul 2025); run `.ts` unit tests with bare `node`; NestJS projects must continue using Vitest |
| Node.js TypeScript API Docs | Official | https://nodejs.org/api/typescript.html | Definitive list of unsupported TypeScript syntax (enums, decorators, parameter properties, namespaces) for native type-stripping execution |
| Node.js v24.0.0 Release | Official | https://nodejs.org/en/blog/release/v24.0.0 | BREAKING: `t.test()` no longer returns Promise; global setup/teardown; per-test `--test-timeout`; JSON module mocking |
| Vitest 4.1 Release (full) | Tool | https://vitest.dev/blog/vitest-4-1.html | mockThrow/mockThrowOnce, GitHub Actions Job Summary reporter (flaky-test highlight + permalinks), agent reporter mode, Vite 8 deduplication, browser strict locators |
| Vitest 3.2 Release (full) | Tool | https://vitest.dev/blog/vitest-3-2.html | Annotation API, Scoped Fixtures, `using vi.spyOn()`, Test Signal API, sequence.groupOrder, workspace deprecated, locators.extend, V8 AST-aware coverage, watchTriggerPatterns, custom project colors |
| Node.js v24.14.0 LTS Release | Official | https://nodejs.org/en/blog/release/v24.14.0 | Node.js test runner `expectFailure` option (xfail semantics) + `env` option on `run()` for per-invocation environment variables (Mar 2026 LTS) |
