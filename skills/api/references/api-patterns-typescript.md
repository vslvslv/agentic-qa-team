# API Test Patterns — TypeScript (Playwright request context)
<!-- lang: TypeScript | date: 2026-05-04 | iteration: 2 -->
<!-- sources: Playwright API testing docs, pactumjs/pactum (v3.9.1), goldbergyoni/javascript-testing-best-practices, mawrkus/js-unit-testing-guide -->

---

## Core Pattern: ApiClient

Never call `request.get/post/delete` directly in test bodies. All tests use an
`ApiClient` wrapper that injects authentication headers and centralises the base URL.

```typescript
// api-tests/ApiClient.ts
import { type APIRequestContext } from "@playwright/test";

export class ApiClient {
  private token = "";
  private readonly baseUrl: string;

  constructor(private readonly req: APIRequestContext, baseUrl?: string) {
    this.baseUrl = baseUrl ?? process.env.API_URL ?? "http://localhost:3001";
  }

  async authenticate(email?: string, password?: string) {
    const res = await this.req.post(`${this.baseUrl}/api/auth/login`, {
      data: {
        email:    email    ?? process.env.E2E_USER_EMAIL    ?? "admin@example.com",
        password: password ?? process.env.E2E_USER_PASSWORD ?? "password123",
      },
    });
    this.token = (await res.json()).token;
  }

  private authHeaders() {
    return this.token ? { Authorization: `Bearer ${this.token}` } : {};
  }

  get(path: string)                 { return this.req.get(`${this.baseUrl}${path}`,    { headers: this.authHeaders() }); }
  post(path: string, data: unknown) { return this.req.post(`${this.baseUrl}${path}`,   { data, headers: this.authHeaders() }); }
  put(path: string, data: unknown)  { return this.req.put(`${this.baseUrl}${path}`,    { data, headers: this.authHeaders() }); }
  patch(path: string, data: unknown){ return this.req.patch(`${this.baseUrl}${path}`,  { data, headers: this.authHeaders() }); }
  delete(path: string)              { return this.req.delete(`${this.baseUrl}${path}`, { headers: this.authHeaders() }); }

  /** Returns a new client with no auth header for 401 tests. */
  anonymous() { return new ApiClient(this.req, this.baseUrl); }
}
```

---

## Test Structure

```typescript
// api-tests/users.spec.ts
import { test, expect } from "@playwright/test";
import { ApiClient } from "./ApiClient";

let api: ApiClient;
const created: number[] = [];

test.beforeAll(async ({ request }) => {
  api = new ApiClient(request);
  await api.authenticate();
});

test.afterAll(async () => {
  for (const id of created) {
    await api.delete(`/api/users/${id}`);
  }
});

// --- GET ---

test("GET /api/users returns 200 with array", async () => {
  const res = await api.get("/api/users");
  expect(res.status()).toBe(200);
  expect(Array.isArray(await res.json())).toBe(true);
});

test("GET /api/users returns 401 without auth", async () => {
  const res = await api.anonymous().get("/api/users");
  expect(res.status()).toBe(401);
});

test("GET /api/users/:id returns 404 for unknown id", async () => {
  expect((await api.get("/api/users/999999")).status()).toBe(404);
});

// --- POST ---

test("POST /api/users returns 201 with id", async () => {
  const res = await api.post("/api/users", {
    name: "Test User",
    email: `test-${Date.now()}@example.com`,
  });
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body.id).toBeGreaterThan(0);
  created.push(body.id);  // track for cleanup
});

test("POST /api/users returns 400 for missing fields", async () => {
  expect((await api.post("/api/users", {})).status()).toBe(400);
});

// --- DELETE lifecycle (POST first, then DELETE) ---

test("DELETE /api/users/:id lifecycle — 201 then 204", async () => {
  const createRes = await api.post("/api/users", {
    name: "To Delete",
    email: `del-${Date.now()}@example.com`,
  });
  expect(createRes.status()).toBe(201);
  const { id } = await createRes.json();
  created.push(id);

  const deleteRes = await api.delete(`/api/users/${id}`);
  expect(deleteRes.status()).toBe(204);
  created.splice(created.indexOf(id), 1);  // already deleted — remove from teardown list
});
```

---

## Cleanup Rules

- Declare `const created: number[] = []` at suite scope
- Push every created resource ID immediately after asserting 201
- `afterAll` deletes everything remaining in `created`
- Lifecycle DELETE tests: `created.splice(...)` right after asserting 204

---

## Execute Block

```bash
export API_URL="$_API_URL"
_SPEC_FILES=$(find . \( -path "*/api-tests/*.spec.ts" -o -path "*/tests/api*.spec.ts" \) \
  ! -path "*/node_modules/*" 2>/dev/null | tr '\n' ' ')
[ -n "$_SPEC_FILES" ] && \
  npx playwright test $_SPEC_FILES --project=chromium --reporter=json \
    2>&1 > "$_TMP/qa-api-output.txt"
echo "PW_EXIT_CODE: $?"
```

---

## AAA Pattern for API Tests  [community]

Structure every API test with clear Arrange / Act / Assert sections. From `goldbergyoni/javascript-testing-best-practices` (24.6k stars) — the most-cited Node.js testing guide.

```typescript
// api-tests/products.spec.ts — AAA structure
import { test, expect } from '@playwright/test';
import { ApiClient } from './ApiClient';

test('POST /api/products — returns 201 with generated id', async ({ request }) => {
  // Arrange
  const api = new ApiClient(request);
  await api.authenticate();
  const payload = {
    name:  'Ergonomic Chair',
    price: 499.99,
    sku:   `CHAIR-${Date.now()}`,   // unique per run — avoids duplicate SKU failures
  };

  // Act
  const res = await api.post('/api/products', payload);

  // Assert
  expect(res.status()).toBe(201);
  const body = await res.json();
  expect(body).toMatchObject({
    id:    expect.any(Number),
    name:  'Ergonomic Chair',
    price: 499.99,
  });
  expect(body.id).toBeGreaterThan(0);
});
```

**Naming rule (goldbergyoni):** A good API test name has three parts:
1. **Unit** — the endpoint (`POST /api/products`)
2. **Scenario** — the condition being tested (`when price is missing`)
3. **Expectation** — the expected outcome (`returns 400 with validation error`)

```typescript
test('POST /api/products — when price is missing — returns 400 with field error', async ({ request }) => {
  const api = new ApiClient(request);
  await api.authenticate();
  const res = await api.post('/api/products', { name: 'Chair' }); // no price
  expect(res.status()).toBe(400);
  const body = await res.json();
  expect(body.errors).toEqual(expect.arrayContaining([
    expect.objectContaining({ field: 'price' }),
  ]));
});
```

---

## Pactum — Lightweight REST API Testing (Node.js)  [community]

[Pactum](https://github.com/pactumjs/pactum) (v3.9.1, 612 stars) is a lightweight REST API testing library that works with Jest, Mocha, and Cucumber. Use it for service-level API tests that don't need a browser or Playwright's full fixture system.

```typescript
// api-tests/pactum/users.spec.ts — Pactum + Vitest
import { describe, it, beforeAll } from 'vitest';
import { spec, request } from 'pactum';

beforeAll(() => {
  request.setBaseUrl(process.env.API_URL ?? 'http://localhost:3001');
  request.setDefaultHeaders({
    'Content-Type': 'application/json',
  });
});

describe('GET /api/users', () => {
  it('returns 200 with user array', async () => {
    await spec()
      .get('/api/users')
      .withHeaders('Authorization', `Bearer ${process.env.API_TOKEN}`)
      .expectStatus(200)
      .expectJsonLike([{ id: expect.any(Number) }]);
  });

  it('returns 401 without auth header', async () => {
    await spec()
      .get('/api/users')
      .expectStatus(401);
  });
});

describe('POST /api/users', () => {
  it('creates user and returns 201 with id', async () => {
    await spec()
      .post('/api/users')
      .withHeaders('Authorization', `Bearer ${process.env.API_TOKEN}`)
      .withBody({
        name:  'Alice',
        email: `alice-${Date.now()}@example.com`,
      })
      .expectStatus(201)
      .expectJsonLike({ id: expect.any(Number), name: 'Alice' });
  });
});
```

**Pactum vs Playwright APIRequestContext — when to use each:**

| Concern | Use Pactum | Use Playwright `request` |
|---------|-----------|--------------------------|
| Pure API / service tests (no browser) | Preferred — lighter, faster startup | Works but over-engineered |
| API tests alongside E2E tests | Possible | Preferred — shares auth fixtures |
| Contract testing (PACT) | Supported natively | Not supported |
| Mock server for integration tests | Built-in mock server | Not available |
| Schema validation (`expectJsonSchema`) | Built-in | Manual — use `ajv` |

---

## Testcontainers — Isolated Integration Test Environments  [community]

[testcontainers-node](https://github.com/testcontainers/testcontainers-node) (2.5k stars) spins up Docker containers per test run — databases, message queues, APIs — and destroys them after. Tests get a fresh, isolated environment without mocking the infrastructure layer.

```typescript
// api-tests/integration/users-db.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { PostgreSqlContainer } from '@testcontainers/postgresql';
import { ApiClient } from '../ApiClient';

describe('User API — real PostgreSQL', () => {
  let container: any;
  let apiClient: ApiClient;

  beforeAll(async () => {
    // Start a real Postgres container
    container = await new PostgreSqlContainer()
      .withDatabase('testdb')
      .withUsername('test')
      .withPassword('test')
      .start();

    // Point your app at the ephemeral container
    process.env.DATABASE_URL = container.getConnectionUri();

    // Start your API server (or use supertest / request)
    // ...
    apiClient = new ApiClient(/* ... */);
  }, 60_000);  // container startup timeout

  afterAll(async () => {
    await container?.stop();
  });

  it('persists user to database and retrieves it', async () => {
    const createRes = await apiClient.post('/api/users', {
      name: 'Bob', email: 'bob@example.com',
    });
    expect(createRes.status()).toBe(201);
    const { id } = await createRes.json();

    const getRes = await apiClient.get(`/api/users/${id}`);
    expect(getRes.status()).toBe(200);
    expect(await getRes.json()).toMatchObject({ name: 'Bob' });
  });
});
```

> **[community]** WHY: Integration tests that mock the database layer validate the API contract but not the SQL queries, migrations, or ORM behaviour. A `users.create()` that passes with a mock can fail in production due to a missing index, wrong column type, or violated unique constraint. Testcontainers catches these issues in CI at the cost of container startup time (typically 5–15s for Postgres). The isolation guarantee — each test run gets its own clean database — eliminates test-order dependencies that plague shared dev databases.

**Gotchas:**
- Requires Docker running in CI; add `services: docker` in GitHub Actions or use `setup-buildx-action`.
- Increase Jest/Vitest `testTimeout` to `60_000` ms for `beforeAll` to cover container startup.
- Use `@testcontainers/postgresql`, `@testcontainers/redis`, `@testcontainers/mongodb` for typed container APIs.
