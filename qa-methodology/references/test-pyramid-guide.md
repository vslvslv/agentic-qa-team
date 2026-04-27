# Test Pyramid — QA Methodology Guide
<!-- lang: TypeScript | topic: test-pyramid | iteration: 3 | score: 100/100 | date: 2026-04-26 -->
<!-- sources: training-knowledge synthesis (WebFetch blocked, WebSearch unavailable) -->
<!-- official refs: martinfowler.com/bliki/TestPyramid.html, martinfowler.com/articles/practical-test-pyramid.html -->
<!-- community refs: kentcdodds.com/blog/write-tests, testing.googleblog.com, Spotify Engineering Blog -->

---

## Core Principles

### 1. Feedback speed determines where bugs get caught

The pyramid's layers are ordered by execution speed and isolation level. Unit tests run in milliseconds; end-to-end tests run in minutes. The higher the layer, the more expensive a failure is to diagnose. The fundamental goal is to catch each bug at the cheapest layer capable of detecting it.

### 2. Confidence scales with integration scope, not test count

A single well-scoped integration test that exercises a real database query buys more confidence than ten unit tests mocking the ORM. The pyramid is a *ratio heuristic*, not a hard rule — the shape emerges from maximising confidence per unit of feedback-loop cost.

### 3. Test boundaries should match deployment boundaries

In a microservice or serverless architecture, "unit" and "integration" shift meaning. What counts as a unit test in a monolith may require network I/O in a distributed system. The principle stays constant: test as close to the code under concern as isolation allows.

### 4. Maintenance cost is proportional to test brittleness

Tests that break when implementation details change — not behaviour — are maintenance tax. Structure tests around observable outputs and public contracts, not internal wiring. This is the single largest driver of test-suite rot in real codebases.

### 5. The pyramid is a guide for investment, not a mandate for structure

No codebase naturally has exactly 70 % unit tests. Use ratio targets as a diagnostic lens: if your suite is 80 % e2e, you have an anti-pattern to fix; if you have zero integration tests, you have a coverage blind spot.

---

## When to Use

| Context | Guidance |
|---------|----------|
| Greenfield TypeScript API/service | Apply the full pyramid from day one; enforce ratios in CI |
| Legacy codebase with no tests | Start with integration/e2e (characterisation tests), then extract unit tests downward as you refactor |
| React/Node frontend | Use Testing Trophy weighting — lean on integration tests over unit tests for UI logic |
| Microservices mesh | Add contract tests as a fourth layer between integration and e2e |
| CLI tooling / data pipelines | Unit tests dominate; e2e tests are often a single smoke test |
| Highly regulated (finance, health) | May require 100 % branch coverage at unit level regardless of pyramid ratio |

---

## Patterns

### The Classic Pyramid (Martin Fowler)

The original framing defines three layers:

- **Unit** — tests a single function/class in isolation; dependencies stubbed or mocked; runs in < 10 ms per test.
- **Integration** (Service) — tests how multiple units cooperate, including real I/O to a database, file system, or in-process HTTP handler; no browser.
- **End-to-End (UI/System)** — drives the full system through its real UI or external API surface; validates user journeys.

Typical ratio target: **70 % unit / 20 % integration / 10 % e2e**.

```typescript
// Unit test — isolated, no I/O (Jest + TypeScript)
import { calculateDiscount } from './discount';

describe('calculateDiscount', () => {
  it('applies 10% for orders over $100', () => {
    const result = calculateDiscount({ total: 150, membershipTier: 'standard' });
    expect(result).toBe(15);
  });

  it('applies no discount for orders under $100', () => {
    const result = calculateDiscount({ total: 80, membershipTier: 'standard' });
    expect(result).toBe(0);
  });

  it('applies 20% for gold members regardless of total', () => {
    const result = calculateDiscount({ total: 50, membershipTier: 'gold' });
    expect(result).toBe(10);
  });
});
```

### Integration Test with Real Database  [community]

Integration tests should exercise the real storage layer — not a mocked repository — to catch ORM quirks, constraint violations, and query N+1 problems that unit tests cannot see.

```typescript
// Integration test — real Postgres via testcontainers (Jest + TypeScript)
import { GenericContainer, StartedTestContainer } from 'testcontainers';
import { DataSource } from 'typeorm';
import { OrderRepository } from './order.repository';
import { Order } from './order.entity';

let container: StartedTestContainer;
let dataSource: DataSource;

beforeAll(async () => {
  container = await new GenericContainer('postgres:15')
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
  expect(fetched?.total).toBe(120.0);
});
```

### End-to-End Test for a Critical User Journey

E2e tests are expensive — reserve them for the paths that, if broken, would immediately stop revenue or access.

```typescript
// E2e test — Playwright + TypeScript
import { test, expect } from '@playwright/test';

test('user can place an order and see confirmation', async ({ page }) => {
  await page.goto('/shop');
  await page.getByRole('button', { name: 'Add to cart' }).first().click();
  await page.getByRole('link', { name: 'Checkout' }).click();
  await page.fill('[name="email"]', 'buyer@example.com');
  await page.fill('[name="card"]', '4242424242424242');
  await page.fill('[name="expiry"]', '12/30');
  await page.fill('[name="cvc"]', '123');
  await page.getByRole('button', { name: 'Place order' }).click();
  await expect(page.getByRole('heading', { name: /order confirmed/i })).toBeVisible();
});
```

### Testing Trophy (Kent C. Dodds)  [community]

Kent C. Dodds observed that for UI-heavy React applications, the classic pyramid under-weights integration tests. In his *Testing Trophy* model the largest layer is **integration** — components rendered against their real hooks and context, with mocked network only at the boundary.

The four layers from bottom to top:
1. **Static analysis** (TypeScript, ESLint) — free confidence, no runtime needed.
2. **Unit tests** — pure logic, selector functions, reducers.
3. **Integration tests** (largest) — full component trees, React Testing Library, MSW for network.
4. **E2e tests** (small) — critical paths only.

```typescript
// Integration test (Testing Trophy) — React Testing Library v14 + MSW v2 + userEvent v14
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';           // separate package
import { http, HttpResponse } from 'msw';                      // MSW v2 API
import { setupServer } from 'msw/node';
import { CheckoutForm } from './CheckoutForm';

const server = setupServer(
  http.post('/api/orders', () =>
    HttpResponse.json({ id: 'ord_001', status: 'confirmed' })
  )
);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

it('submits the form and shows confirmation message', async () => {
  const user = userEvent.setup();                              // v14: call setup() first
  render(<CheckoutForm />);
  await user.type(screen.getByLabelText('Email'), 'user@example.com');
  await user.click(screen.getByRole('button', { name: /place order/i }));
  expect(await screen.findByText(/order confirmed/i)).toBeInTheDocument();
});
```

### Spotify Honeycomb  [community]

Spotify Engineering (2018) challenged the pyramid for microservice meshes. Because each service is small, "unit tests" often test implementation details, while the valuable confidence comes from testing a service against its real dependencies — but in an isolated, containerised environment.

The Honeycomb proposes:
- **Integrated tests** (largest) — a service plus its immediate real dependencies (DB, cache), containerised.
- **Integration contract tests** — verify a service honours the contract of *one* dependency at a time.
- **E2e tests** (smallest) — only the business-critical multi-service journeys.

Unit tests are not absent, but they are reserved for genuinely complex logic — not for every class. [community] The key Spotify insight: _testing in isolation against real infrastructure breeds more confidence than testing against mocks that may silently drift from reality._

```typescript
// Honeycomb "integrated" test — real service + real Postgres + real Redis, no e2e browser
// tests/integrated/recommendations.integrated.test.ts
import { createApp } from '../../src/app';
import { TestEnvironment } from '../helpers/TestEnvironment';
import request from 'supertest';

let env: TestEnvironment;

beforeAll(async () => {
  // Start real Postgres and Redis containers; apply migrations
  env = await TestEnvironment.start({ services: ['postgres:16', 'redis:7'] });
  await env.runMigrations();
}, 90_000);

afterAll(() => env.stop());

beforeEach(() => env.resetData()); // truncate tables between tests

test('GET /recommendations returns personalised items from real DB + cache', async () => {
  // Seed directly into the real DB — no mocks
  await env.db.query(
    `INSERT INTO user_preferences (user_id, genre) VALUES ('u1', 'sci-fi'), ('u1', 'thriller')`
  );

  const app = createApp({ db: env.db, redis: env.redis });
  const res = await request(app).get('/recommendations').set('x-user-id', 'u1');

  expect(res.status).toBe(200);
  expect(res.body.items.length).toBeGreaterThan(0);
  // Second call should come from Redis cache — verify via cache key
  const cached = await env.redis.get('recs:u1');
  expect(cached).not.toBeNull();
});
```

---

## Anti-Patterns

### Inverted Pyramid (Ice Cream Cone)

The most destructive anti-pattern: the suite has far more e2e tests than unit or integration tests. Symptoms:
- CI takes 30–90 minutes.
- Failures give no diagnostic information — "the login test failed" means anything.
- Developers skip running the suite locally.

Why it happens: teams write e2e tests first because they feel like "real" tests. The fix is to identify every e2e test that could be expressed as an integration test and push it down.

### Over-Mocking (Solitary Unit Tests for Everything)

Going too far the other direction: mocking every dependency so that no real I/O ever runs. The result is tests that pass even when the ORM query is wrong, the SQL constraint is missing, or the HTTP client constructs the wrong URL. [community] The unit test suite becomes a specification of the mocks, not the software.

### Testing Implementation Details

Writing assertions on private methods, internal state, or component instance variables. These tests break on every refactor even when the behaviour is unchanged. [community] Signal: you are asserting on `component.state.isLoading` instead of `screen.getByRole('status')`.

### Skipping the Integration Layer Entirely

Teams that go unit → e2e with nothing in between produce the worst of both worlds: unit tests that don't detect real integration bugs, and e2e tests that are slow and fragile. The integration layer is where the majority of real production bugs live (data mapping, validation, auth middleware, serialisation).

### Ratio Cargo-Culting

Enforcing "70/20/10" as a hard CI gate is counterproductive. [community] A CLI tool that does pure data transformation may legitimately have 95 % unit tests. A data-pipeline that moves bytes between services may have 70 % integration tests. Use ratios to diagnose imbalance, not as compliance checkboxes.

---

## Real-World Gotchas  [community]

1. **Testcontainers start-up time blows integration test budgets** [community] — Teams discover that spinning up Postgres + Redis per test file takes 2–3 minutes. Fix: use a shared container per test suite (`beforeAll` not `beforeEach`), or use a persistent local dev container and skip container creation in CI by pointing at a pre-provisioned service.

2. **MSW (Mock Service Worker) and Playwright interact badly** [community] — Using MSW in integration tests and Playwright in e2e against the same codebase requires keeping handler definitions in sync. When the real API changes, MSW handlers silently diverge. Fix: generate MSW handlers from OpenAPI schemas (e.g. `orval` or `msw-auto-mock`), so drift is a build-time error.

3. **Jest module mocking poisons adjacent tests** [community] — `jest.mock()` at the module level with `jest.resetModules()` omitted causes test order–dependent failures. In a monorepo with thousands of tests, this is the single most common source of "passes locally, fails in CI" bugs. Fix: prefer dependency injection over `jest.mock()` for stateful modules.

4. **100 % unit coverage hides zero integration confidence** [community] — A service can have 100 % line coverage on its unit tests and completely fail at runtime because every dependency is mocked. Teams misread green coverage as "ship it". Fix: require a non-zero integration test count in CI merge gates, separately from coverage thresholds.

5. **Playwright test parallelism shares browser state** [community] — Running Playwright workers in parallel against a shared test database produces intermittent failures. Each worker must own its data or use tenant-level isolation. Fix: use `test.use({ storageState })` per worker and seed isolated data per test, or run e2e tests serially with a single seeded database snapshot.

6. **Snapshot tests become trust-no-one tests** [community] — React component snapshot tests that are updated automatically (`jest --updateSnapshot`) degrade into rubber-stamp assertions. Developers update them to pass CI without reading the diff. Fix: treat snapshot updates as code review items; set a policy that reviewers must approve any snapshot diff.

7. **TypeScript types do not replace runtime validation tests** [community] — A typed service that receives data from an external API without a runtime schema (e.g. `zod`) will fail at runtime when the API changes shape, even if all type-checked tests pass. The type system cannot test external contract compliance.

---

## Tradeoffs & Alternatives

### When the pyramid does not apply

| Scenario | Better shape |
|----------|-------------|
| Microservices with independent deployments | Honeycomb (Spotify) — emphasise integrated service tests + contract tests |
| React/Next.js UI-heavy app | Testing Trophy (Dodds) — emphasise integration over unit |
| Data-science / ML notebooks | Property-based testing + characterisation tests; pyramid ratios irrelevant |
| Legacy monolith with no tests | Work top-down: add e2e first for safety net, then push coverage downward as you refactor |
| Browser extensions / mobile native | E2e proportion increases; device/OS matrix is a unique dimension |

### Adoption costs

- **Testcontainers setup** adds 2–4 h of initial CI configuration and ongoing maintenance as container images are upgraded.
- **MSW handler maintenance** in a large frontend codebase requires tooling (schema codegen) to stay non-brittle.
- **Playwright configuration** (parallelism, retries, sharding) requires senior engineering time to tune; getting it wrong produces more flakiness than no e2e tests at all.
- **Ratio monitoring** requires custom CI scripts or third-party tooling (Codecov, Datadog CI Visibility) to track over time.

### Lighter alternatives

- **No integration layer yet?** Start with a single "smoke" integration test per service boundary. One test is better than zero.
- **Can't afford Playwright?** Cypress is more beginner-friendly; even basic `cy.visit` + form-submit coverage on two critical journeys is enough to catch regressions.
- **No testcontainers budget?** SQLite in-memory as a test database is inferior but far better than mocking the entire ORM.

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
| Testcontainers for Node | Tool | https://testcontainers.com/guides/getting-started-with-testcontainers-for-nodejs/ | Real integration tests against containerised dependencies |
| Playwright | Tool | https://playwright.dev/docs/intro | Modern e2e testing for TypeScript |
| React Testing Library | Tool | https://testing-library.com/docs/react-testing-library/intro/ | Integration-layer testing aligned with Testing Trophy |
| MSW (Mock Service Worker) | Tool | https://mswjs.io/docs/ | Network boundary mocking without intercepting implementation |
