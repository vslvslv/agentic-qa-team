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
_QA_VER=$( [ -n "$_QA_ROOT" ] && bash "$_QA_ROOT/bin/qa-team-update-check" 2>/dev/null \
  || echo "UPDATE_CHECK_FAILED: not found" )
echo "VERSION_STATUS: $_QA_VER"
_QA_ASK_COOLDOWN="$_TMP/.qa-update-asked"
_QA_SKIP_ASK=0
if [ -f "$_QA_ASK_COOLDOWN" ]; then
  _qa_age=$(( $(date +%s) - $(cat "$_QA_ASK_COOLDOWN" | tr -d ' ') ))
  [ "$_qa_age" -lt 600 ] && _QA_SKIP_ASK=1
fi
```

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `_QA_SKIP_ASK` is `0`, use `AskUserQuestion`:
- Question: "qa-agentic-team update available (read vCURRENT → vNEW from VERSION_STATUS output). Update before running?"
- Options: "Yes — update now (recommended)" | "No — run with current version"
- Run `echo "$(date +%s)" > "$_QA_ASK_COOLDOWN"` to set a 10-minute cooldown (prevents repeated prompts in parallel sub-agents).
- If user selects "Yes": `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup" && echo "Updated successfully."`
- Continue regardless of choice.

---

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"

# Detect API base URL (JS/TS envs first, then .NET sources)
_API_URL=$(grep -r "API_URL\|apiUrl\|baseURL\|BASE_URL" .env .env.local .env.test 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
# .NET: launchSettings.json applicationUrl
[ -z "$_API_URL" ] && _API_URL=$(
  find . -name "launchSettings.json" ! -path "*/obj/*" 2>/dev/null | head -1 | \
  xargs grep -o '"applicationUrl"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | \
  grep -o 'http[s]*://[^;",]*' | head -1)
# .NET: appsettings.json BaseUrl / ApiUrl key
[ -z "$_API_URL" ] && _API_URL=$(
  find . \( -name "appsettings.json" -o -name "appsettings.Development.json" \) \
  ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -oi '"[Aa]pi[Uu]rl\|[Bb]ase[Uu]rl"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | \
  grep -o 'http[s]*://[^"]*' | head -1)
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
  -o -path "*/api/src/**/*.ts" \
  -o -path "*/Controllers/*.cs" \) \
  ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | head -20

# Detect project language → API tool
echo "--- LANGUAGE DETECTION ---"
_API_TOOL="playwright"  # default for JS/TS
[ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ] && _API_TOOL="java"
[ -f "requirements.txt" ] || [ -f "conftest.py" ] || [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] && _API_TOOL="python"
[ -n "$(find . -maxdepth 3 \( -name '*.csproj' -o -name '*.sln' \) ! -path '*/obj/*' 2>/dev/null | head -1)" ] && _API_TOOL="csharp"
[ -f "Gemfile" ] && _API_TOOL="ruby"
echo "API_TOOL: $_API_TOOL"

# C# test framework detection (nunit / mstest / xunit)
_CS_TEST_FW="nunit"
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -il "xunit" 2>/dev/null | grep -q '.' && _CS_TEST_FW="xunit"
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -il "MSTest\|Microsoft\.VisualStudio\.TestTools" 2>/dev/null | grep -q '.' && \
  _CS_TEST_FW="mstest"
echo "CS_TEST_FW: $_CS_TEST_FW"

# C# HTTP client detection (RestSharp preferred when present, HttpClient otherwise)
_CS_RESTSHARP=0
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -il "RestSharp" 2>/dev/null | grep -q '.' && _CS_RESTSHARP=1
echo "CS_RESTSHARP: $_CS_RESTSHARP"

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

# --- MULTI-REPO SUPPORT ---
# Set QA_EXTRA_PATHS (space-separated absolute paths) to scan tests in other repos
# e.g.: export QA_EXTRA_PATHS="/path/to/api-tests-repo /path/to/integration-tests"
if [ -n "$QA_EXTRA_PATHS" ]; then
  echo "MULTI_REPO_PATHS: $QA_EXTRA_PATHS"
  for _qr in $QA_EXTRA_PATHS; do
    _extra=$(find "$_qr" \( \
      -name "*.spec.ts" -o -name "*.spec.js" -o -name "*.test.ts" -o -name "*.test.js" \
      -o -name "*_test.py" -o -name "test_*.py" -o -name "*Test.java" \
      -o -name "*Tests.cs" -o -name "*_spec.rb" \) \
      ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | wc -l | tr -d ' ')
    echo "EXTRA_REPO $(basename "$_qr"): $_extra test files — $_qr"
  done
fi
```

If `MULTI_REPO_PATHS` output appeared: when sampling test files in subsequent phases, include files from those extra paths. All sub-agents inherit `QA_EXTRA_PATHS` automatically via the environment. Language detection uses CWD (the main application repository).

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

# Strategy 2: Grep route files (JS/TS)
grep -r "router\.\(get\|post\|put\|patch\|delete\)\|app\.\(get\|post\|put\|patch\|delete\)" \
  --include="*.ts" --include="*.js" ! -path "*/node_modules/*" 2>/dev/null | \
  grep -o '"[/][^"]*"' | sort -u | head -40

# Strategy 2b: C# Controllers — extract routes from attributes
find . -path "*/Controllers/*.cs" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -h "\[Route\]\|\[HttpGet\]\|\[HttpPost\]\|\[HttpPut\]\|\[HttpPatch\]\|\[HttpDelete\]" \
  2>/dev/null | grep -o '"[^"]*"' | sort -u | head -40

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

### DELETE endpoint policy (read before writing any test)

**Never generate a bare `DELETE /api/*` test.** Calling delete on a resource that was
not created by this test run may corrupt shared test data.

Allowed patterns — only generate DELETE tests when the test itself:
1. **POST first** — create the resource with a unique payload (e.g. email with timestamp)
2. **Verify creation** — assert 201 and capture the returned ID
3. **DELETE** — call the endpoint, assert 204 / 200
4. This is a lifecycle test, not a standalone delete test.

If you cannot safely create the resource first (no POST endpoint, write access not
available), **skip the DELETE test entirely** and log it as a coverage gap.

### Cleanup obligations (read before writing any test)

Every test that creates data **must** clean it up:
- Track all created resource IDs in a shared list during the test run
- Delete tracked resources in the suite's teardown (`@AfterAll` / `OneTimeTearDown` /
  `session`-scope fixture / `afterAll`)
- If a test asserts the DELETE itself (lifecycle test), remove the ID from the tracking
  list immediately after so teardown does not double-delete
- If cleanup fails or is skipped, mark the test `[Explicit]` / `@pytest.mark.explicit`
  with a comment explaining the manual cleanup needed

### Load language patterns file

Select and read the language-appropriate reference guide for `_API_TOOL`:

**TypeScript (Playwright request context)**:
> Reference: [API patterns — TypeScript](references/api-patterns-typescript.md)
> Key patterns: `ApiClient` wrapping Playwright `APIRequestContext` · `anonymous()` for 401 tests · `afterAll` cleanup tracking · lifecycle DELETE (POST → assert 201 → DELETE → assert 204)

**Java (REST Assured)**:
> Reference: [API patterns — Java](references/api-patterns-java.md)
> Key patterns: `ApiClient` wrapping REST Assured · `@AfterAll` teardown with `created` list · `anon()` spec for 401 tests · lifecycle DELETE pattern

**Python (pytest + requests)**:
> Reference: [API patterns — Python](references/api-patterns-python.md)
> Key patterns: `ApiClient` wrapping `requests.Session` · `anonymous()` client for 401 tests · session-scoped `autouse` fixture cleanup · lifecycle DELETE pattern

**C# (RestSharp or HttpClient + NUnit / MSTest / xUnit)**:
> Reference: [API patterns — C#](references/api-patterns-csharp.md)
> Key patterns: `ApiClient` wrapping RestSharp `RestClient` (when `CS_RESTSHARP=1`) or `HttpClient` (fallback) · `Anonymous()` for 401 tests · `_created` list + `OneTimeTearDown`/`ClassCleanup`/`DisposeAsync` teardown · NUnit / MSTest / xUnit sections
> Use the **RestSharp section** when `CS_RESTSHARP=1`; use the **HttpClient section** otherwise.
> Focus on the sub-section matching `CS_TEST_FW` (`nunit`, `mstest`, or `xunit`).

**Ruby (RSpec + Faraday)**:
> Reference: [API patterns — Ruby](references/api-patterns-ruby.md)
> Key patterns: `ApiClient` wrapping Faraday · `after(:all)` teardown with `created_ids` list · `anonymous` client for 401 tests · lifecycle DELETE pattern

For `_API_TOOL=csharp`, also note `CS_TEST_FW` and `CS_RESTSHARP` — use the RestSharp section of the patterns file when `CS_RESTSHARP=1`, otherwise use the HttpClient section; within each HTTP-client section, focus on the sub-section matching `CS_TEST_FW`.

Follow the patterns in that file to generate tests. Read existing test files before
writing — append missing test blocks, never overwrite existing ones.

**Coverage targets per endpoint:**
1. Happy path — expected status code + response shape
2. Auth enforcement — `401` without token, `403` for insufficient permissions
3. Validation — `400` / `422` for invalid/missing required fields
4. Not found — `404` for non-existent resource IDs
5. Lifecycle (POST → DELETE) — only when the create endpoint is available

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
```

## Important Rules

- **Language-native by default** — use the idiomatic tool for the stack; avoid cross-language deps
- **Shared ApiClient** — always use the `ApiClient` class from the patterns reference; never instantiate `HttpClient` / `requests.Session` / Faraday per test class
- **Auth first** — always obtain a token in suite setup; never hard-code tokens in test bodies
- **Test the contract, not the implementation** — assert on status codes + response schema
- **No bare DELETE tests** — never call `DELETE /api/*` on a resource that this test did not create; only generate DELETE tests as lifecycle tests (POST → verify → DELETE)
- **Cleanup everything you create** — track IDs of all created resources and delete them in suite teardown; lifecycle tests that exercise DELETE must remove their ID from the tracking list immediately after asserting the delete, so teardown does not double-delete
- **Idempotent test data** — use unique, timestamped values (e.g. `test-{timestamp}@example.com`) so parallel runs do not collide
- **Report even if execution fails** — always write the report regardless of exit code
