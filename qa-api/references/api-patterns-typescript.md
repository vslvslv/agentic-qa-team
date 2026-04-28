# API Test Patterns — TypeScript (Playwright request context)
<!-- lang: TypeScript | date: 2026-04-28 -->

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
