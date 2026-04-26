---
name: qa-api
preamble-tier: 3
version: 1.0.0
description: |
  API test agent. Discovers REST and GraphQL endpoints from OpenAPI specs, route
  files, or live introspection. Generates and executes HTTP-level tests covering
  status codes, schema validation, auth enforcement, and error handling. Works
  standalone or as a sub-agent of /qa-team. Use when asked to "qa api",
  "test the api", "api tests", "contract testing", "test endpoints", or
  "rest/graphql testing". (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
---

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"

# Detect API base URL
_API_URL=$(grep -r "API_URL\|apiUrl\|baseURL\|BASE_URL" .env .env.local .env.test 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
_API_URL="${_API_URL:-http://localhost:3001}"
echo "API_URL: $_API_URL"

# Check API health
_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$_API_URL" 2>/dev/null || echo "000")
echo "API_HEALTH: $_HEALTH"

# Detect OpenAPI / Swagger spec
echo "--- OPENAPI ---"
ls openapi.yaml openapi.json swagger.yaml swagger.json \
  api/openapi.yaml api/openapi.json docs/openapi.yaml 2>/dev/null | head -5

# Detect route files
echo "--- ROUTE FILES ---"
find . \( -path "*/routes/*.ts" -o -path "*/routes/*.js" \
  -o -path "*/controllers/*.ts" -o -path "*/controllers/*.js" \
  -o -path "*/api/src/**/*.ts" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -20

# Detect test runner
echo "--- TEST RUNNER ---"
ls jest.config.ts jest.config.js vitest.config.ts vitest.config.js 2>/dev/null
grep -l "supertest\|axios\|node-fetch\|got" package.json 2>/dev/null | head -1

# Detect GraphQL
echo "--- GRAPHQL ---"
find . \( -name "schema.graphql" -o -name "*.graphql" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -5
grep -r "graphql\|ApolloServer\|type Query" --include="*.ts" -l \
  ! -path "*/node_modules/*" 2>/dev/null | head -5
```

If `API_HEALTH` is `000`: warn the user. Ask whether to:
1. Start the API first (provide the start command)
2. Proceed in write-only mode (generate tests without executing them)

## Phase 1 — Discover Endpoints

**Strategy (in priority order):**

1. **OpenAPI/Swagger spec** — parse if found
2. **Route files** — grep for `router.get|post|put|patch|delete` and `app.use`
3. **GraphQL schema** — introspect or parse schema file
4. **Live introspection** — hit `/docs`, `/swagger`, `/graphql` if the API is running

```bash
# Strategy 1: Parse OpenAPI spec
_SPEC=$(ls openapi.yaml openapi.json swagger.yaml swagger.json 2>/dev/null | head -1)
if [ -n "$_SPEC" ]; then
  echo "SPEC_FILE: $_SPEC"
  cat "$_SPEC" | grep -E "^\s*(get|post|put|patch|delete):" | head -40
fi

# Strategy 2: Grep route files
grep -r "router\.\(get\|post\|put\|patch\|delete\)\|app\.\(get\|post\|put\|patch\|delete\)" \
  --include="*.ts" --include="*.js" ! -path "*/node_modules/*" 2>/dev/null | \
  grep -o '"[/][^"]*"' | sort -u | head -40

# Strategy 3: GraphQL introspection
_GRAPHQL_URL="$_API_URL/graphql"
curl -s -X POST "$_GRAPHQL_URL" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { queryType { fields { name description } } mutationType { fields { name description } } } }"}' \
  2>/dev/null | python3 -c "
import sys, json
try:
  d = json.load(sys.stdin)
  schema = d.get('data',{}).get('__schema',{})
  for kind in ['queryType','mutationType']:
    t = schema.get(kind) or {}
    for f in (t.get('fields') or []):
      print(f\"{kind}: {f['name']} — {f.get('description','')}\")
except: pass
" 2>/dev/null | head -30

# Strategy 4: Live /docs
curl -s "$_API_URL/api-docs" -o "$_TMP/api-docs.html" 2>/dev/null && echo "DOCS: fetched" || true
curl -s "$_API_URL/swagger.json" 2>/dev/null | python3 -c "
import sys, json
try:
  d = json.load(sys.stdin)
  for path, methods in d.get('paths',{}).items():
    for method in methods:
      print(f\"{method.upper()} {path}\")
except: pass
" 2>/dev/null | head -40
```

Build an **endpoint inventory**:
- Method + path (e.g., `GET /api/users`)
- Description (from spec or inferred)
- Auth required: yes/no
- Request body schema (if POST/PUT/PATCH)
- Priority: `critical` | `important` | `nice-to-have`

## Phase 2 — Auth Detection

```bash
# Find JWT / session auth patterns
grep -r "Authorization\|Bearer\|jwt\|session" --include="*.ts" -l \
  ! -path "*/node_modules/*" 2>/dev/null | head -5

# Find login endpoint
grep -r "login\|signin\|auth/token\|auth/login" --include="*.ts" \
  ! -path "*/node_modules/*" 2>/dev/null | grep -o '"[/][^"]*"' | head -5

# Check for seeded credentials
grep -r "admin@\|password123\|seed\|fixture" --include="*.json" --include="*.ts" \
  ! -path "*/node_modules/*" 2>/dev/null | head -5
```

Acquire an auth token before running protected endpoint tests:

```bash
_AUTH_RESP=$(curl -s -X POST "$_API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${E2E_USER_EMAIL:-admin@example.com}\",\"password\":\"${E2E_USER_PASSWORD:-password123}\"}" \
  2>/dev/null || echo "{}")
_TOKEN=$(echo "$_AUTH_RESP" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
[ -n "$_TOKEN" ] && echo "AUTH: ok" || echo "AUTH: failed — proceeding with unauthenticated tests only"
```

## Phase 3 — Generate API Tests

**Test framework selection:**
- If `vitest` in `package.json` → use Vitest + `@vitest/browser` or inline `fetch`
- If `jest` in `package.json` → use Jest + `supertest`
- Otherwise → use Playwright's `request` context (no extra dep needed)

Prefer Playwright request context for portability:

```typescript
// api-tests/endpoints.spec.ts
import { test, expect } from "@playwright/test";

const BASE = process.env.API_URL || "http://localhost:3001";

let token: string;

test.beforeAll(async ({ request }) => {
  const res = await request.post(`${BASE}/api/auth/login`, {
    data: {
      email: process.env.E2E_USER_EMAIL || "admin@example.com",
      password: process.env.E2E_USER_PASSWORD || "password123",
    },
  });
  const body = await res.json();
  token = body.token;
});

// ── GET /api/users ────────────────────────────────────────────────────────────
test.describe("GET /api/users", () => {
  test("returns 200 with array", async ({ request }) => {
    const res = await request.get(`${BASE}/api/users`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(Array.isArray(body)).toBe(true);
  });

  test("returns 401 without auth", async ({ request }) => {
    const res = await request.get(`${BASE}/api/users`);
    expect(res.status()).toBe(401);
  });
});
```

**Coverage targets per endpoint:**
1. Happy path — expected status code + response shape
2. Auth enforcement — `401` without token, `403` for insufficient permissions
3. Validation — `400` / `422` for invalid/missing required fields
4. Not found — `404` for non-existent resource IDs

**GraphQL coverage:**
- Each query/mutation: success case
- Required field missing: error in `errors[]`
- Auth: unauthenticated → `UNAUTHENTICATED` error code

Read existing API test files before writing — append only missing test blocks.

**Type-check after writing:**

```bash
_TSC=$(find . -path "*/node_modules/.bin/tsc" ! -path "*/node_modules/*/node_modules/*" | head -1)
[ -n "$_TSC" ] && "$_TSC" --noEmit 2>&1 | grep -E "\.(spec|test)\." | head -20 || echo "tsc not found"
```

## Phase 4 — Execute Tests

```bash
export API_URL="$_API_URL"
export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"

_SPEC_FILES=$(find . \( -path "*/api-tests/*.spec.ts" \
  -o -path "*/tests/api*.spec.ts" -o -path "*/e2e/api*.spec.ts" \) \
  ! -path "*/node_modules/*" 2>/dev/null | tr '\n' ' ')

if [ -n "$_SPEC_FILES" ]; then
  _PW_JSON="$_TMP/qa-api-pw-results.json"
  npx playwright test $_SPEC_FILES \
    --project=chromium \
    --reporter=json \
    2>&1 > "$_TMP/qa-api-pw-output.txt"
  _EXIT_CODE=$?
  echo "PW_EXIT_CODE: $_EXIT_CODE"
  cat "$_TMP/qa-api-pw-output.txt" | tail -20
else
  echo "No API spec files found — generation only mode"
fi
```

Parse results using the same Python snippet as qa-web (adapt path to `qa-api-pw-results.json`).

## Phase 5 — Report

Write report to `$_TMP/qa-api-report.md`:

```markdown
# QA API Report — <date>

## Summary
- **Status**: ✅ / ❌
- Passed: N · Failed: N · Skipped: N
- Endpoints tested: N
- Auth: JWT / session / none

## Endpoint Coverage
| Endpoint | Tests | Auth | Status |
|----------|-------|------|--------|
| GET /api/users | 2 | ✅ | ✅ |
| POST /api/users | 3 | ✅ | ❌ |

## Failures
<list each failure with endpoint + error snippet>

## Missing Coverage
<endpoints with no tests>

## Schema Gaps
<fields or responses not validated>
```

## Important Rules

- **Portable by default** — use Playwright request context; avoid test runners that require setup
- **Auth first** — always obtain a token in `beforeAll`; never hard-code tokens
- **Test the contract, not the implementation** — assert on status codes + response schema, not internal state
- **Idempotent tests** — use unique IDs for created resources; clean up in `afterAll`
- **Report even if execution fails** — always write the report regardless of exit code
- **No destructive operations** — skip `DELETE /api/*` tests unless cleanup-only; flag them explicitly
