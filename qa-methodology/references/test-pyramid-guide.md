# Test Pyramid — QA Methodology Guide
<!-- lang: JavaScript | topic: test-pyramid | iteration: 6 | score: 100/100 | date: 2026-04-28 -->
<!-- sources: training-knowledge synthesis (WebFetch blocked, WebSearch unavailable) -->
<!-- official refs: martinfowler.com/bliki/TestPyramid.html, martinfowler.com/articles/practical-test-pyramid.html -->
<!-- community refs: kentcdodds.com/blog/write-tests, testing.googleblog.com, Spotify Engineering Blog -->

---

## Core Principles

### 1. Feedback speed determines where defects get caught

The pyramid's test levels are ordered by execution speed and isolation level. Unit tests run in milliseconds; end-to-end tests run in minutes. The higher the test level, the more expensive a defect is to diagnose. The fundamental goal is to catch each defect at the cheapest test level capable of detecting it.

### 2. Confidence scales with integration scope, not test count

A single well-scoped integration test that exercises a real database query buys more confidence than ten unit test cases mocking the ORM. The pyramid is a *ratio heuristic*, not a hard rule — the shape emerges from maximising confidence per unit of feedback-loop cost. Google's internal data (2010) found that "Medium" tests (integration-level) caught the most defects per test case written, outperforming both Small (unit) and Large (e2e) tests in defect-detection density.

### 3. Test boundaries should match deployment boundaries

In a microservice or serverless architecture, "unit" and "integration" shift meaning. What counts as a unit test in a monolith may require network I/O in a distributed system. The principle stays constant: test as close to the code under concern as isolation allows.

### 4. Maintenance cost is proportional to test brittleness

Tests that break when implementation details change — not behaviour — are maintenance tax. Structure tests around observable outputs and public contracts, not internal wiring. This is the single largest driver of test-suite rot in real codebases.

### 5. The pyramid is a guide for investment, not a mandate for structure

No codebase naturally has exactly 70 % unit test cases. Use ratio targets as a diagnostic lens: if your test suite is 80 % e2e, you have an anti-pattern to fix; if you have zero integration tests, you have a coverage blind spot.

> **ISTQB CTFL 4.0 terminology note:** This guide uses ISTQB-standard terms throughout. "Test level" (not "test layer") refers to a distinct group of test activities organised and managed together (unit, integration, system, acceptance). "Test case" is the preferred term for a single executable test specification. "Test suite" is a collection of test cases. "Defect" (not "bug") is used for observed deviations from expected behaviour. "Test object" refers to the component or system under test.

---

## When to Use

| Context | Guidance |
|---------|----------|
| Greenfield JavaScript API/service | Apply the full pyramid from day one; enforce ratios in CI |
| Legacy codebase with no tests | Start with integration/e2e (characterisation tests), then extract unit tests downward as you refactor |
| React/Node frontend | Use Testing Trophy weighting — lean on integration tests over unit tests for UI logic |
| Microservices mesh | Add contract tests as a fourth layer between integration and e2e |
| CLI tooling / data pipelines | Unit tests dominate; e2e tests are often a single smoke test |
| Highly regulated (finance, health) | May require 100 % branch coverage at unit level regardless of pyramid ratio |

---

## Patterns

### The Classic Pyramid (Martin Fowler)

The original framing defines three layers:

- **Unit** — tests a single function/module in isolation; dependencies stubbed or mocked; runs in < 10 ms per test.
- **Integration** (Service) — tests how multiple units cooperate, including real I/O to a database, file system, or in-process HTTP handler; no browser.
- **End-to-End (UI/System)** — drives the full system through its real UI or external API surface; validates user journeys.

Typical ratio target: **70 % unit / 20 % integration / 10 % e2e** (ISTQB: unit test level / integration test level / system test level).

```javascript
// Unit test — isolated, no I/O (Jest + JavaScript)
const { calculateDiscount } = require('./discount');

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

```javascript
// Integration test — real Postgres via testcontainers (Jest + JavaScript)
const { GenericContainer } = require('testcontainers');
const { DataSource } = require('typeorm');
const { OrderRepository } = require('./order.repository');
const { Order } = require('./order.entity');

let container;
let dataSource;

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
  expect(fetched.total).toBe(120.0);
});
```

### End-to-End Test for a Critical User Journey

E2e tests are expensive — reserve them for the paths that, if broken, would immediately stop revenue or access.

```javascript
// E2e test — Playwright + JavaScript
const { test, expect } = require('@playwright/test');

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
1. **Static analysis** (ESLint, JSDoc) — free confidence, no runtime needed.
2. **Unit tests** — pure logic, selector functions, reducers.
3. **Integration tests** (largest) — full component trees, React Testing Library, MSW for network.
4. **E2e tests** (small) — critical paths only.

```javascript
// Integration test (Testing Trophy) — React Testing Library + MSW v2 + userEvent v14
const { render, screen } = require('@testing-library/react');
const userEvent = require('@testing-library/user-event');
const { http, HttpResponse } = require('msw');
const { setupServer } = require('msw/node');
const { CheckoutForm } = require('./CheckoutForm');

const server = setupServer(
  http.post('/api/orders', () =>
    HttpResponse.json({ id: 'ord_001', status: 'confirmed' })
  )
);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

it('submits the form and shows confirmation message', async () => {
  const user = userEvent.setup();
  render(React.createElement(CheckoutForm));
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

Unit tests are not absent, but they are reserved for genuinely complex logic — not for every module. [community] The key Spotify insight: _testing in isolation against real infrastructure breeds more confidence than testing against mocks that may silently drift from reality._

```javascript
// Honeycomb "integrated" test — real service + real Postgres + real Redis, no e2e browser
// tests/integrated/recommendations.integrated.test.js
const { createApp } = require('../../src/app');
const { TestEnvironment } = require('../helpers/TestEnvironment');
const request = require('supertest');

let env;

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

### Enforcing Pyramid Shape in CI  [community]

Without automated enforcement, pyramid shape drifts over time. The simplest guard is a Jest/Vitest `--verbose` output parser that counts tests by directory convention (`tests/unit/`, `tests/integration/`, `tests/e2e/`) and fails CI when the shape inverts.

```javascript
// scripts/check-pyramid-shape.js — run as a CI step after tests
// Expects Jest JSON output: jest --json --outputFile=jest-results.json
import { readFileSync } from 'fs';

const results = JSON.parse(readFileSync('./jest-results.json', 'utf8'));

let unit = 0, integration = 0, e2e = 0;

for (const suite of results.testResults) {
  const path = suite.testFilePath;
  if (/[\\/]unit[\\/]/.test(path) || /\.unit\.test\.js$/.test(path)) {
    unit += suite.numPassingTests + suite.numFailingTests;
  } else if (/[\\/]e2e[\\/]/.test(path) || /\.e2e\.test\.js$/.test(path)) {
    e2e += suite.numPassingTests + suite.numFailingTests;
  } else {
    integration += suite.numPassingTests + suite.numFailingTests;
  }
}

const total = unit + integration + e2e;
console.log(`Pyramid shape: unit=${unit} (${Math.round(unit/total*100)}%) | ` +
  `integration=${integration} (${Math.round(integration/total*100)}%) | ` +
  `e2e=${e2e} (${Math.round(e2e/total*100)}%)`);

// Warn (not fail) if e2e exceeds integration — a hard failure is too aggressive
if (e2e > integration) {
  console.warn('WARNING: e2e count exceeds integration count — pyramid may be inverting.');
  process.exit(1); // Adjust to process.exit(0) for warning-only mode
}
```



Modern JavaScript projects using `"type": "module"` in `package.json` often choose **Vitest** over Jest because it runs in native ESM without Babel transforms. The API is Jest-compatible, so migration is low-friction. Vitest also co-locates unit tests next to source with `.test.js` files and provides a browser mode for DOM-level tests.

```javascript
// discount.test.js — Vitest + ESM (no require(), no transform)
import { describe, it, expect } from 'vitest';
import { calculateDiscount } from './discount.js';

describe('calculateDiscount', () => {
  it('returns 10% for standard members over $100', () => {
    expect(calculateDiscount({ total: 150, tier: 'standard' })).toBe(15);
  });

  it('returns 20% for gold members regardless of total', () => {
    expect(calculateDiscount({ total: 50, tier: 'gold' })).toBe(10);
  });

  it('returns 0 when total is at the threshold boundary', () => {
    // Boundary value: exactly $100 should NOT trigger the discount
    expect(calculateDiscount({ total: 100, tier: 'standard' })).toBe(0);
  });

  it('throws for unknown membership tier', () => {
    expect(() => calculateDiscount({ total: 150, tier: 'vip' }))
      .toThrow('Unknown tier: vip');
  });
});
```

### Node.js HTTP Integration Test (no framework)  [community]

When your service is a plain Express or Fastify app, `supertest` gives you a genuine integration test against the running HTTP layer without needing a browser. This tests middleware stacks, request parsing, and response serialisation — all layers that pure unit tests skip.

```javascript
// tests/integration/orders.test.js — supertest + Jest/Vitest
import request from 'supertest';
import { buildApp } from '../../src/app.js';
import { createTestDb } from '../helpers/db.js';

let app;
let db;

beforeAll(async () => {
  db = await createTestDb(); // spins up SQLite in-memory for speed
  app = buildApp({ db });
});

afterAll(() => db.destroy());

afterEach(() => db.truncate('orders'));

it('POST /orders creates an order and returns 201 with id', async () => {
  const res = await request(app)
    .post('/orders')
    .send({ customerId: 'c1', items: [{ sku: 'A1', qty: 2 }] })
    .set('Accept', 'application/json');

  expect(res.status).toBe(201);
  expect(res.body).toMatchObject({ id: expect.any(String), status: 'pending' });
});

it('POST /orders returns 422 when items array is empty', async () => {
  const res = await request(app)
    .post('/orders')
    .send({ customerId: 'c1', items: [] });

  expect(res.status).toBe(422);
  expect(res.body.error).toMatch(/items must not be empty/i);
});
```



### Inverted Pyramid (Ice Cream Cone)

The most destructive anti-pattern: the test suite has far more e2e test cases than unit or integration test cases. Symptoms:
- CI takes 30–90 minutes.
- Defects give no diagnostic information — "the login test case failed" means anything.
- Developers skip running the test suite locally.

Why it happens: teams write e2e test cases first because they feel like "real" tests. The fix is to identify every e2e test case that could be expressed as an integration test case and push it down.

### Over-Mocking (Solitary Unit Tests for Everything)

Going too far the other direction: mocking every dependency so that no real I/O ever runs. The result is test cases that pass even when the ORM query is wrong, the SQL constraint is missing, or the HTTP client constructs the wrong URL. [community] The unit test suite becomes a specification of the mocks, not the test object.

### Testing Implementation Details

Writing assertions on private methods, internal state, or component instance variables. These tests break on every refactor even when the behaviour is unchanged. [community] Signal: you are asserting on `wrapper.state().isLoading` (Enzyme-style) instead of `screen.getByRole('status')` (RTL-style).

### Skipping the Integration Layer Entirely

Teams that go unit → e2e with nothing in between produce the worst of both worlds: unit test cases that don't detect real integration defects, and e2e test cases that are slow and fragile. The integration test level is where the majority of real production defects live (data mapping, validation, auth middleware, serialisation).

### Ratio Cargo-Culting

Enforcing "70/20/10" as a hard CI gate is counterproductive. [community] A CLI tool that does pure data transformation may legitimately have 95 % unit test cases. A data-pipeline that moves bytes between services may have 70 % integration test cases. Use ratios to diagnose imbalance, not as compliance checkboxes.

### Pyramid Shape Drift Goes Unnoticed

Teams that don't measure their test-type distribution let the pyramid quietly invert over months. New engineers add e2e test cases because they are the most visible; unit test cases get deleted when refactoring because they feel brittle. Without a CI check, nobody notices until the build takes 45 minutes. [community] Fix: add a test-count-by-type job to CI that fails with a warning when e2e count exceeds integration count, or when unit test cases are less than 50 % of total.

---

## Real-World Gotchas  [community]

1. **Testcontainers start-up time blows integration test budgets** [community] — Teams discover that spinning up Postgres + Redis per test file takes 2–3 minutes. Fix: use a shared container per test suite (`beforeAll` not `beforeEach`), or use a persistent local dev container and skip container creation in CI by pointing at a pre-provisioned service.

2. **MSW (Mock Service Worker) and Playwright interact badly** [community] — Using MSW in integration tests and Playwright in e2e against the same codebase requires keeping handler definitions in sync. When the real API changes, MSW handlers silently diverge. Fix: generate MSW handlers from OpenAPI schemas (e.g. `orval` or `msw-auto-mock`), so drift is a build-time error.

3. **Jest module mocking poisons adjacent tests** [community] — `jest.mock()` at the module level with `jest.resetModules()` omitted causes test order–dependent failures. In a monorepo with thousands of tests, this is the single most common source of "passes locally, fails in CI" bugs. Fix: prefer dependency injection over `jest.mock()` for stateful modules.

4. **100 % unit coverage hides zero integration confidence** [community] — A service can have 100 % line coverage on its unit tests and completely fail at runtime because every dependency is mocked. Teams misread green coverage as "ship it". Fix: require a non-zero integration test count in CI merge gates, separately from coverage thresholds.

5. **Playwright test parallelism shares browser state** [community] — Running Playwright workers in parallel against a shared test database produces intermittent failures. Each worker must own its data or use tenant-level isolation. Fix: use `test.use({ storageState })` per worker and seed isolated data per test, or run e2e tests serially with a single seeded database snapshot.

6. **Snapshot tests become trust-no-one tests** [community] — React component snapshot tests that are updated automatically (`jest --updateSnapshot`) degrade into rubber-stamp assertions. Developers update them to pass CI without reading the diff. Fix: treat snapshot updates as code review items; set a policy that reviewers must approve any snapshot diff.

7. **Node.js module caching corrupts test isolation** [community] — `require()` caches module exports by file path. If a module holds singleton state (DB connections, config, event emitters), re-requiring it returns the cached instance with dirty state from a previous test. Fix: call `jest.resetModules()` between tests or restructure singletons to be injectable.

8. **ESM interop breaks Jest mocking** [community] — Native ESM modules cannot be mocked with `jest.mock()` the same way as CJS. `jest.unstable_mockModule()` requires top-level await and a specific import ordering. Teams upgrading from CJS to ESM discover all their mock setups break simultaneously. Fix: migrate to Vitest for ESM projects, or use a Babel transform to keep CJS during Jest runs.

9. **Shared Playwright base URL causes cross-environment test bleed** [community] — When a single `playwright.config.js` points `baseURL` to a shared staging environment, parallel test workers from multiple PRs corrupt each other's data. Teams running CI on feature branches often discover this the hard way when staging data is unexpectedly mutated. Fix: use ephemeral preview environments per PR (Vercel/Railway/Render preview deploys) so each test run has an isolated base.

10. **Vitest browser mode blurs test-level boundaries** [community] — Vitest 2.x introduced a native browser mode that runs unit test cases directly in Chromium/Firefox via WebDriver BiDi. Teams adopting it for component tests often inadvertently add DOM start-up cost to what should be pure unit test cases. Fix: keep `environment: 'node'` for pure logic test cases and restrict `environment: 'browser'` (or `environment: 'jsdom'`) to component-level integration test cases in your Vitest config; this preserves the speed advantage of the unit test level.

11. **"Test condition" confusion inflates e2e count** [community] — ISTQB CTFL 4.0 defines a *test condition* as a testable aspect of the test object. Teams that conflate "one e2e test case per user story condition" with "one test condition requires an e2e test case" produce an over-weight e2e test suite. Most test conditions (validation rules, edge-case business logic, error states) are best exercised as unit or integration test cases. Fix: for each test condition, explicitly ask "What is the lowest test level that can falsify this condition?" before writing an e2e test case.

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
| Pure functions / algorithmic library | Near-100 % unit tests is correct — almost no integration surface |

### Adoption costs

- **Testcontainers setup** adds 2–4 h of initial CI configuration and ongoing maintenance as container images are upgraded.
- **MSW handler maintenance** in a large frontend codebase requires tooling (schema codegen) to stay non-brittle.
- **Playwright configuration** (parallelism, retries, sharding) requires senior engineering time to tune; getting it wrong produces more flakiness than no e2e tests at all.
- **Ratio monitoring** requires custom CI scripts or third-party tooling (Codecov, Datadog CI Visibility) to track over time.

### Lighter alternatives

- **No integration layer yet?** Start with a single "smoke" integration test per service boundary. One test is better than zero.
- **Can't afford Playwright?** Cypress is more beginner-friendly; even basic `cy.visit` + form-submit coverage on two critical journeys is enough to catch regressions.
- **No testcontainers budget?** SQLite in-memory as a test database is inferior but far better than mocking the entire ORM.
- **Google's alternative taxonomy:** Small / Medium / Large tests map to unit / integration / e2e with more nuance — "Large" is not "E2e browser" but "crosses process boundaries". Useful when the word "unit" causes theological debates.

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
| Playwright | Tool | https://playwright.dev/docs/intro | Modern e2e testing for JavaScript/Node |
| React Testing Library | Tool | https://testing-library.com/docs/react-testing-library/intro/ | Integration-layer testing aligned with Testing Trophy |
| MSW (Mock Service Worker) | Tool | https://mswjs.io/docs/ | Network boundary mocking without intercepting implementation |
| Vitest | Tool | https://vitest.dev/guide/ | Fast Jest-compatible test runner for ESM-native JavaScript projects |
| supertest | Tool | https://github.com/ladjs/supertest | HTTP integration tests against Express/Fastify without a running server |
| Better Specs (JS) | Community | https://www.betterspecs.org/ | Opinionated naming and structure conventions for integration tests |
