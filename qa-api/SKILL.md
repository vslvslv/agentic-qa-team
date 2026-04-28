---
name: qa-api
preamble-tier: 3
version: 1.0.0
description: |
  API test agent. Discovers REST and GraphQL endpoints from OpenAPI specs, route
  files, or live introspection. Generates and executes HTTP-level tests covering
  status codes, schema validation, auth enforcement, and error handling. Uses the
  idiomatic testing tool for the project's language: Playwright request context
  (JS/TS), REST Assured (Java), pytest+requests (Python), HttpClient+NUnit (C#),
  or RSpec+Faraday (Ruby). Works standalone or as a sub-agent of /qa-team. Use
  when asked to "qa api", "test the api", "api tests", "contract testing",
  "test endpoints", or "rest/graphql testing". (qa-agentic-team)
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

## Version check

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_QA_ROOT=$(dirname "$(readlink ~/.claude/skills/qa-api 2>/dev/null)" 2>/dev/null) || true
[ ! -f "${_QA_ROOT:-x}/VERSION" ] && \
  _QA_ROOT="$(readlink ~/.claude/skills/qa-agentic-team 2>/dev/null)" || true
bash "$_QA_ROOT/bin/qa-team-precheck"
```

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `SKIP_UPDATE_PROMPT` is `0`, use `AskUserQuestion`:
- Question: "qa-agentic-team update available (read vCURRENT → vNEW from VERSION_STATUS output). Update before running?"
- Options: "Yes — update now (recommended)" | "No — run with current version"
- Run `echo "$(date +%s)" > "$_TMP/.qa-update-asked"` to set a 10-minute cooldown (prevents repeated prompts in parallel sub-agents).
- If user selects "Yes": `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup" && echo "Updated successfully."`
- Continue regardless of choice.

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
  -o -path "*/controllers/*.ts" -o -path "*/controllers/*.java" \
  -o -path "*/api/src/**/*.ts" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -20

# Detect project language → API tool
echo "--- LANGUAGE DETECTION ---"
_API_TOOL="playwright"  # default for JS/TS
[ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ] && _API_TOOL="java"
[ -f "requirements.txt" ] || [ -f "conftest.py" ] || [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] && _API_TOOL="python"
[ -n "$(find . -maxdepth 3 \( -name '*.csproj' -o -name '*.sln' \) 2>/dev/null | head -1)" ] && _API_TOOL="csharp"
[ -f "Gemfile" ] && _API_TOOL="ruby"
echo "API_TOOL: $_API_TOOL"

# Detect test runner (JS/TS)
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
grep -r "login\|signin\|auth/token\|auth/login" --include="*.ts" --include="*.java" \
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

Use `_API_TOOL` to select the test template. Read existing test files before writing —
append missing test blocks, never overwrite existing ones.

**TypeScript / JavaScript — Playwright request context:**

```typescript
// api-tests/endpoints.spec.ts
import { test, expect } from "@playwright/test";

const BASE = process.env.API_URL || "http://localhost:3001";
let token: string;

test.beforeAll(async ({ request }) => {
  const res = await request.post(`${BASE}/api/auth/login`, {
    data: { email: process.env.E2E_USER_EMAIL || "admin@example.com",
            password: process.env.E2E_USER_PASSWORD || "password123" },
  });
  token = (await res.json()).token;
});

test.describe("GET /api/users", () => {
  test("returns 200 with array", async ({ request }) => {
    const res = await request.get(`${BASE}/api/users`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    expect(Array.isArray(await res.json())).toBe(true);
  });
  test("returns 401 without auth", async ({ request }) => {
    expect((await request.get(`${BASE}/api/users`)).status()).toBe(401);
  });
});
```

**Java — REST Assured:**

```java
// src/test/java/api/UsersApiTest.java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.*;
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class UsersApiTest {
    static String token;

    @BeforeAll static void setup() {
        RestAssured.baseURI = System.getenv().getOrDefault("API_URL", "http://localhost:3001");
        token = given().contentType(ContentType.JSON)
            .body("{\"email\":\"admin@example.com\",\"password\":\"password123\"}")
            .post("/api/auth/login")
            .then().statusCode(200)
            .extract().path("token");
    }

    @Test void getUsers_returns200WithList() {
        given().header("Authorization", "Bearer " + token)
            .get("/api/users")
            .then().statusCode(200).body("$", instanceOf(java.util.List.class));
    }

    @Test void getUsers_returns401WithoutAuth() {
        get("/api/users").then().statusCode(401);
    }
}
```

**Python — pytest + requests:**

```python
# tests/test_users_api.py
import os, pytest, requests

BASE = os.getenv("API_URL", "http://localhost:3001")

@pytest.fixture(scope="session")
def token():
    r = requests.post(f"{BASE}/api/auth/login", json={
        "email": os.getenv("E2E_USER_EMAIL", "admin@example.com"),
        "password": os.getenv("E2E_USER_PASSWORD", "password123"),
    })
    r.raise_for_status()
    return r.json()["token"]

def test_get_users_returns_200(token):
    r = requests.get(f"{BASE}/api/users", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert isinstance(r.json(), list)

def test_get_users_401_without_auth():
    assert requests.get(f"{BASE}/api/users").status_code == 401
```

**C# — HttpClient + NUnit:**

```csharp
// ApiTests/UsersApiTests.cs
using NUnit.Framework;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

[TestFixture]
public class UsersApiTests {
    static HttpClient _client = new HttpClient {
        BaseAddress = new Uri(Environment.GetEnvironmentVariable("API_URL") ?? "http://localhost:3001")
    };
    static string _token = "";

    [OneTimeSetUp] public async Task Setup() {
        var res = await _client.PostAsJsonAsync("/api/auth/login",
            new { email = "admin@example.com", password = "password123" });
        var body = await res.Content.ReadFromJsonAsync<LoginResponse>();
        _token = body?.Token ?? "";
        _client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _token);
    }

    [Test] public async Task GetUsers_Returns200() {
        var res = await _client.GetAsync("/api/users");
        Assert.That((int)res.StatusCode, Is.EqualTo(200));
    }

    [Test] public async Task GetUsers_Returns401WithoutAuth() {
        using var anon = new HttpClient { BaseAddress = _client.BaseAddress };
        Assert.That((int)(await anon.GetAsync("/api/users")).StatusCode, Is.EqualTo(401));
    }

    record LoginResponse(string Token);
}
```

**Ruby — RSpec + Faraday:**

```ruby
# spec/api/users_spec.rb
require 'faraday'
require 'json'

BASE = ENV.fetch('API_URL', 'http://localhost:3001')

RSpec.describe 'Users API' do
  let(:conn) { Faraday.new(url: BASE) }
  let(:token) do
    res = conn.post('/api/auth/login') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = JSON.dump(email: 'admin@example.com', password: 'password123')
    end
    JSON.parse(res.body)['token']
  end

  it 'GET /api/users returns 200 with array' do
    res = conn.get('/api/users') { |r| r.headers['Authorization'] = "Bearer #{token}" }
    expect(res.status).to eq(200)
    expect(JSON.parse(res.body)).to be_a(Array)
  end

  it 'GET /api/users returns 401 without auth' do
    expect(conn.get('/api/users').status).to eq(401)
  end
end
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

**Type-check after writing (JS/TS only):**

```bash
_TSC=$(find . -path "*/node_modules/.bin/tsc" ! -path "*/node_modules/*/node_modules/*" | head -1)
[ -n "$_TSC" ] && "$_TSC" --noEmit 2>&1 | grep -E "\.(spec|test)\." | head -20 || echo "tsc not found"
```

## Phase 4 — Execute Tests

Dispatch to the correct runner based on `_API_TOOL`:

**playwright (JS/TS):**
```bash
export API_URL="$_API_URL"
_SPEC_FILES=$(find . \( -path "*/api-tests/*.spec.ts" -o -path "*/tests/api*.spec.ts" \) \
  ! -path "*/node_modules/*" 2>/dev/null | tr '\n' ' ')
[ -n "$_SPEC_FILES" ] && \
  npx playwright test $_SPEC_FILES --project=chromium --reporter=json \
    2>&1 > "$_TMP/qa-api-output.txt" && \
  echo "PW_EXIT_CODE: $?" || echo "No API spec files found — generation only mode"
```

**java:**
```bash
# Maven
command -v mvn &>/dev/null && [ -f pom.xml ] && \
  mvn test -pl . -Dtest="*ApiTest" 2>&1 | tee "$_TMP/qa-api-output.txt" && \
  echo "MAVEN_EXIT_CODE: $?"
# Gradle
command -v gradle &>/dev/null && [ -f build.gradle ] && \
  gradle test --tests "*ApiTest" 2>&1 | tee "$_TMP/qa-api-output.txt" && \
  echo "GRADLE_EXIT_CODE: $?"
```

**python:**
```bash
export API_URL="$_API_URL"
command -v pytest &>/dev/null && \
  pytest tests/ -v -k "api" 2>&1 | tee "$_TMP/qa-api-output.txt" && \
  echo "PYTEST_EXIT_CODE: $?"
```

**csharp:**
```bash
command -v dotnet &>/dev/null && \
  dotnet test --filter "Category=Api" 2>&1 | tee "$_TMP/qa-api-output.txt" && \
  echo "DOTNET_EXIT_CODE: $?"
```

**ruby:**
```bash
command -v rspec &>/dev/null && \
  bundle exec rspec spec/api/ 2>&1 | tee "$_TMP/qa-api-output.txt" && \
  echo "RSPEC_EXIT_CODE: $?"
```

## Phase 5 — Report

Write report to `$_TMP/qa-api-report.md`:

```markdown
# QA API Report — <date>

## Summary
- **Status**: ✅ / ❌
- Passed: N · Failed: N · Skipped: N
- Endpoints tested: N
- Language / Tool: <playwright | REST Assured | pytest | HttpClient | RSpec>
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

## After this run
- For methodology issues (pyramid, isolation, naming): → `/qa-audit`
- For up-to-date tooling patterns (HTTP clients, schema libs, mocking): → `/qa-refine`
- After applying fixes: re-run `/qa-api` (or `/qa-team`) to measure delta — score history at `<repo>/.qa-team/qa-api-*.json`
```

## Phase 5b — Machine-Readable Sidecar

After the markdown report, also write `$_TMP/qa-api-score.json` with the same numbers
in a parseable shape. Shares the envelope schema with `qa-audit-score.json` so hooks
and CI can consume both uniformly.

```bash
_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "uncommitted")
_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

cat > "$_TMP/qa-api-score.json" <<JSON
{
  "schema_version": "1.0",
  "skill": "qa-api",
  "skill_version": "<read from $_QA_ROOT/VERSION>",
  "branch": "$_BRANCH",
  "commit": "$_COMMIT",
  "timestamp": "$_TIMESTAMP",
  "status": "<pass | warn | fail>",
  "tool": "<playwright | rest_assured | pytest | httpclient | rspec>",
  "auth": "<jwt | session | apikey | none>",
  "counts": {
    "passed": <N>,
    "failed": <N>,
    "skipped": <N>,
    "total": <N>
  },
  "endpoints": {
    "discovered": <N>,
    "tested": <N>,
    "missing": <N>
  },
  "schema_gaps_count": <N>,
  "report_md_path": "$_TMP/qa-api-report.md"
}
JSON
```

Validate it parses (`jq . "$_TMP/qa-api-score.json" >/dev/null`). Replace every `<...>`
with the actual computed value. If `jq` reports invalid JSON, fix and rewrite.

## Phase 5c — Persist to Project History

```bash
bash "$_QA_ROOT/bin/qa-team-persist-history" "qa-api"
```

## Important Rules

- **Language-native by default** — use the idiomatic tool for the stack; avoid cross-language deps
- **Auth first** — always obtain a token in setup; never hard-code tokens in test bodies
- **Test the contract, not the implementation** — assert on status codes + response schema
- **Idempotent tests** — use unique IDs for created resources; clean up in teardown
- **Report even if execution fails** — always write the report regardless of exit code
- **No destructive operations** — skip `DELETE /api/*` tests unless cleanup-only; flag them explicitly
- **JSON contract is load-bearing** — `qa-api-score.json` is consumed by `qa-team`'s verify-after-fixes phase, by `bin/qa-team-history`, and by CI hooks. Field renames or removals require bumping `schema_version` and updating consumers.

## Telemetry (run last)

```bash
# Per-run cost log (consumed by bin/qa-team-cost). Status is derived from the
# just-written JSON sidecar — single source of truth. Falls back to "warn" if
# jq is missing or the sidecar wasn't written. Valid: pass | warn | fail.
_QA_STATUS=$(jq -r '.status // "warn"' "$_TMP/qa-api-score.json" 2>/dev/null || echo "warn")
case "$_QA_STATUS" in
  pass|warn|fail) ;;
  *) _QA_STATUS="warn" ;;
esac
bash "$_QA_ROOT/bin/qa-team-cost-log" "qa-api" "$_QA_STATUS" 2>/dev/null || true
```
