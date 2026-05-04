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
disable-model-invocation: true
model: sonnet
effort: high
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: 'bash "${CLAUDE_SKILL_DIR}/../bin/hooks/qa-pre-bash-safety.sh"'
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'bash "${CLAUDE_SKILL_DIR}/../bin/hooks/qa-post-write-typecheck.sh"'
          async: true
---

## Version check

!`bash "${CLAUDE_SKILL_DIR}/../bin/qa-version-check-inline.sh" 2>/dev/null || echo "VERSION_STATUS: UPDATE_CHECK_FAILED"`

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `SKIP_UPDATE_ASK` is `0`, use `AskUserQuestion`: "qa-agentic-team update available. Update before running?" Options: "Yes — update now (recommended)" | "No — run with current version". If yes: `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup"`. Continue regardless.

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

# gRPC detection
echo "--- GRPC ---"
_GRPC_HOST=""
_GRPC_PORT=""
for port in 50051 9090 8081; do
  nc -z localhost $port 2>/dev/null && _GRPC_HOST="localhost" && _GRPC_PORT=$port && break
done
echo "GRPC: ${_GRPC_HOST:+$_GRPC_HOST:$_GRPC_PORT}"
_PROTO_FILES=$(find . -name "*.proto" ! -path "*/node_modules/*" 2>/dev/null | head -5)
echo "PROTO_FILES: $(echo "$_PROTO_FILES" | wc -l | tr -d ' ')"
echo "$_PROTO_FILES"

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

# Chaos seed mode detection (BL-023)
_SEED_MODE="${QA_SEED_MODE:-clean}"
echo "SEED_MODE: $_SEED_MODE"
[ "$_SEED_MODE" = "chaos" ] && \
  echo "CHAOS_MODE: active — tests running against chaos-seeded data; new failures may indicate data-handling regressions"

# OTel traceparent injection detection (BL-055)
_OTEL_AVAILABLE=0
[ -n "$OTEL_EXPORTER_OTLP_ENDPOINT" ] && _OTEL_AVAILABLE=1
echo "OTEL_AVAILABLE: $_OTEL_AVAILABLE"
```

If `MULTI_REPO_PATHS` output appeared: when sampling test files in subsequent phases, include files from those extra paths. All sub-agents inherit `QA_EXTRA_PATHS` automatically via the environment. Language detection uses CWD (the main application repository).

If `API_HEALTH` is `000`: warn the user. Ask whether to:
1. Start the API first (provide the start command)
2. Proceed in write-only mode (generate tests without executing them)

## Phase 0.5 — Spectral OpenAPI Lint

Run Spectral lint before executing any tests. Skip if no OpenAPI/Swagger spec found.

```bash
_SPEC_FILE=$(ls openapi.yaml openapi.json swagger.yaml swagger.json 2>/dev/null | head -1)
if [ -n "$_SPEC_FILE" ]; then
  echo "SPEC_FILE: $_SPEC_FILE"
  if ! command -v spectral >/dev/null 2>&1; then
    npx --yes @stoplight/spectral-cli lint "$_SPEC_FILE" 2>&1 | tail -30
  else
    spectral lint "$_SPEC_FILE" 2>&1 | tail -30
  fi
fi
```

Parse output:
- `error` severity lines → **BLOCKING**: halt execution and report; do not run tests against a broken spec
- `warning` severity lines → collect into `$_TMP/qa-api-spectral-warnings.txt`; surface in Phase 5 report

If Spectral exits non-zero due to errors: abort with message "Spectral found spec errors — fix before running API tests."

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

## Phase 1.5 — GraphQL Schema Diff

Skip if no GraphQL schema files found.

```bash
_GQL_SCHEMA=$(find . \( -name "schema.graphql" -o -name "*.graphql" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -1)
if [ -n "$_GQL_SCHEMA" ]; then
  echo "GQL_SCHEMA: $_GQL_SCHEMA"
  git show origin/main:"$_GQL_SCHEMA" > /tmp/qa-gql-baseline.graphql 2>/dev/null || \
    git show HEAD~1:"$_GQL_SCHEMA" > /tmp/qa-gql-baseline.graphql 2>/dev/null || \
    echo "NO_BASELINE"
fi
```

If baseline obtained:
```bash
npx --yes @graphql-inspector/cli diff /tmp/qa-gql-baseline.graphql "$_GQL_SCHEMA" 2>&1
```

Classify changes:
- `BREAKING` → flag in Phase 5 report as `[BREAKING CHANGE]`; add to critical failures
- `DANGEROUS` → flag as `[WARNING]`
- `NON_BREAKING` → informational; log to report

Skip silently if GraphQL Inspector not available and no schema found.

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

## Phase 2b — gRPC Smoke Tests

Skip if `_GRPC_HOST` is not set (no gRPC port detected in Preamble).

```bash
if command -v grpcurl >/dev/null 2>&1 && [ -n "$_GRPC_HOST" ]; then
  grpcurl -plaintext "$_GRPC_HOST:$_GRPC_PORT" list 2>&1
fi
```

For each discovered service:
```bash
# List methods on each service
grpcurl -plaintext "$_GRPC_HOST:$_GRPC_PORT" list "<ServiceName>" 2>&1
# Smoke test each method with empty request
grpcurl -plaintext -d '{}' "$_GRPC_HOST:$_GRPC_PORT" "<ServiceName>/<MethodName>" 2>&1
```

Classify response:
- Valid response body → **PASS**
- `UNIMPLEMENTED` / `NOT_FOUND` → **SKIP** (method not applicable for empty request)
- `INTERNAL` / connection error → **FAIL**

Add gRPC results to Phase 5 report under `### gRPC Coverage` section.

## Phase 2.5 — CI Grounding

Run existing API tests before generating new ones. Capture the current baseline so Phase 3 targets only untested endpoints and actual failures — not duplication.

```bash
_CI_GROUND_FILE="$_TMP/qa-api-ci-ground.txt"
_EXISTING_API_SPECS=$(find . \( \
  -path "*/api-tests/*.spec.ts" -o -path "*/tests/api*.spec.ts" \
  -o -path "*/spec/api/*.rb" -o -name "*ApiTest.java" -o -name "*ApiTest.cs" \
  \) ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | wc -l | tr -d ' ')
if [ "$_EXISTING_API_SPECS" -gt 0 ]; then
  echo "CI_GROUND: running $_EXISTING_API_SPECS existing API spec file(s)"
  case "$_API_TOOL" in
    playwright) timeout 120 npx playwright test --reporter=list 2>&1 | tail -60 > "$_CI_GROUND_FILE" || true ;;
    java)
      if command -v mvn &>/dev/null && [ -f pom.xml ]; then
        timeout 180 mvn test -Dtest="*ApiTest" -q 2>&1 | tail -60 > "$_CI_GROUND_FILE" || true
      elif command -v gradle &>/dev/null; then
        timeout 180 gradle test --tests "*ApiTest" 2>&1 | tail -60 > "$_CI_GROUND_FILE" || true
      fi ;;
    python)  timeout 120 pytest tests/ -v -k "api" --tb=short 2>&1 | tail -60 > "$_CI_GROUND_FILE" || true ;;
    csharp)  timeout 120 dotnet test --filter "Category=Api" --logger "console;verbosity=minimal" 2>&1 | tail -60 > "$_CI_GROUND_FILE" || true ;;
    ruby)    timeout 120 bundle exec rspec spec/api/ --format progress 2>&1 | tail -60 > "$_CI_GROUND_FILE" || true ;;
    *)       echo "CI_GROUND_STATUS: skipped (no runner matched)" | tee "$_CI_GROUND_FILE" ;;
  esac
  grep -E "failed|passed|error|FAIL|PASS|✓|✗|×|ERROR|PENDING" "$_CI_GROUND_FILE" 2>/dev/null | head -30
else
  echo "CI_GROUND_STATUS: no existing API specs found — full generation"
fi
```

Use this output in Phase 3 to:
- Skip generating tests for endpoints that already have passing coverage
- Target endpoints with failing tests: understand why they fail and write tests that capture the correct contract
- Tag pre-existing failures as `CI_GROUND_FAIL` so Phase 5 diagnosis can distinguish regressions from known failures

## Phase 3 — Generate API Tests

### OTel Traceparent Header (BL-055)

If `_OTEL_AVAILABLE=1`, add a `traceparent` header to all generated API requests so
backend distributed traces can be correlated to specific test runs on failure.

```typescript
// Playwright APIRequestContext — add to test setup or request helper
const traceId = crypto.randomUUID().replace(/-/g, '');
const spanId = Math.random().toString(16).slice(2, 18).padStart(16, '0');
const traceparent = `00-${traceId}-${spanId}-01`;
test.info().annotations.push({ type: 'traceId', description: traceId });

const response = await request.get('/api/endpoint', {
  headers: { traceparent },
});
```

Include the `traceId` annotation in CTRF `message` field on failure so the backend trace
can be retrieved from Jaeger/Tempo. Only add traceparent when `OTEL_EXPORTER_OTLP_ENDPOINT`
is set — do not add it unconditionally.

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

## Phase 3.5 — API Test Quality Gate

Review every generated `it()` / `test()` / `[Test]` / `[Fact]` block before execution. For each test, verify all three criteria:

1. **Non-trivial assertion** — asserts more than just HTTP status code; checks at minimum one response body field, header, or schema shape
2. **Correct method + path** — uses the exact endpoint from the Phase 1 inventory; not a copy-pasted template URL
3. **Auth coverage** — protected endpoints have both an authenticated (happy path) test and an unauthenticated `401` test

If any test fails a criterion, rewrite it before proceeding:
- Missing body assertion → add `expect(body).toHaveProperty('id')` / `assert response.json()['id']`
- Wrong URL → fix to match the Phase 1 inventory
- Missing `401` test → add an unauthenticated variant using the `anonymous()` client from the patterns guide

Log: `QUALITY GATE: rewrote "<test title>" — <reason>`

**Do not proceed to Phase 4 until all generated tests pass the quality gate.**

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

## Phase 4b — Schemathesis Property-Based Fuzzing

Skip if: no OpenAPI spec found (`_SPEC_FILE` is empty), or `QA_SKIP_SCHEMATHESIS=1` env var set.

```bash
if [ -n "$_SPEC_FILE" ] && [ "${QA_SKIP_SCHEMATHESIS:-0}" != "1" ]; then
  if ! command -v schemathesis >/dev/null 2>&1 && ! command -v st >/dev/null 2>&1; then
    pip install schemathesis --quiet 2>/dev/null || echo "SCHEMATHESIS_UNAVAILABLE"
  fi
  if command -v st >/dev/null 2>&1 || command -v schemathesis >/dev/null 2>&1; then
    _ST_CMD=$(command -v st 2>/dev/null || echo schemathesis)
    "$_ST_CMD" run "$_SPEC_FILE" \
      --checks all \
      --stateful=links \
      --max-examples 25 \
      --output-truncate-responses \
      --base-url "$_API_URL" \
      2>&1 | tee "$_TMP/qa-api-schemathesis.txt" | tail -50
  fi
fi
```

Parse `$_TMP/qa-api-schemathesis.txt`:
- `PASSED` → include in Phase 5 summary
- `FAILED` → extract reproduction command + request/response; add to critical failures
- `ERROR` (schema issue) → log as warning, don't block

In Phase 5 report, add `### Fuzz Testing (Schemathesis)` section:
- Total hypotheses tested
- Properties verified (status_code_conformance, content_type_conformance, response_schema_conformance)
- Any failures with reproduction `st run ... --hypothesis-seed=<N>`

## Phase 4c — OWASP OFFAT OpenAPI Security Fuzzing (BL-033)

Skip if `QA_SECURITY!=1` OR no OpenAPI spec detected in preamble.

OFFAT performs OWASP API Top 10 attack-class fuzzing from the OpenAPI spec: BOLA, mass
assignment, SQL injection, XSS, restricted HTTP method bypass. Complements Schemathesis'
structural fuzzing with security-specific attack vectors.

**Tool detection:**

```bash
_OFFAT=0
command -v offat >/dev/null 2>&1 && _OFFAT=1
echo "OFFAT_AVAILABLE: $_OFFAT"
```

**Run (opt-in: `QA_SECURITY=1` AND `_OFFAT=1` AND OpenAPI spec present):**

```bash
if [ "${QA_SECURITY:-0}" = "1" ] && [ "$_OFFAT" = "1" ] && \
   ls openapi.yaml openapi.json swagger.yaml swagger.json 2>/dev/null | grep -q '.'; then
  _SPEC_FILE=$(ls openapi.yaml openapi.json swagger.yaml swagger.json 2>/dev/null | head -1)
  echo "=== OFFAT SECURITY FUZZING ==="
  echo "SPEC: $_SPEC_FILE  TARGET: $_API_URL"
  _AUTH_HEADER=""
  [ -n "$API_TOKEN" ] && _AUTH_HEADER="--headers Authorization:Bearer $API_TOKEN"
  offat \
    -f "$_SPEC_FILE" \
    -u "$_API_URL" \
    $_AUTH_HEADER \
    -o "$_TMP/offat-results.json" \
    --format json \
    2>&1 | tail -30 | tee "$_TMP/offat-output.txt"
  echo "OFFAT_EXIT: $?"
fi
```

**Fallback when OFFAT not installed** (if `QA_SECURITY=1` but `_OFFAT=0`):

```bash
if [ "${QA_SECURITY:-0}" = "1" ] && [ "$_OFFAT" = "0" ]; then
  echo "OFFAT_NOT_INSTALLED: install with 'pip install offat' for API security fuzzing"
  echo "OFFAT_INSTALL_HINT: pip install offat"
fi
```

**Parse results** (if `$_TMP/offat-results.json` exists):

Read the JSON output. For each finding:
- `severity: high` → **blocking failure** — add to CRITICAL findings in Phase 5 report
- `severity: medium` → IMPORTANT finding
- `severity: low` / `info` → informational

Map findings to OWASP API Top 10 category:
- BOLA findings → API1:2023 BOLA
- Mass assignment → API6:2023 Unrestricted Access to Sensitive Business Flows
- SQLi/XSS → API8:2023 Security Misconfiguration
- Method bypass → API8:2023

Add **OFFAT** section to Phase 5 report:
```
## OWASP OFFAT Security Fuzzing (Phase 4c)
- Spec: <file>  Target: <url>  Findings: N (high: N, medium: N, low: N)
- High-severity findings: BLOCK / PASS

| Endpoint | Method | OWASP Category | Severity | Description |
|----------|--------|---------------|----------|-------------|
```

## Phase 5 — Report

Write report to `$_TMP/qa-api-report.md`:

If `_SEED_MODE=chaos` is active, prepend this warning block to the report (before the Summary table):
> ⚠️ **Chaos mode active** (`QA_SEED_MODE=chaos`): any new test failures compared to clean-seed runs may indicate data-handling regressions. Compare with baseline clean-seed results to isolate chaos-induced failures.

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

## Diagnosis
*(Complete this section when EXIT_CODE != 0, before listing individual failures.)*
| Field | Detail |
|-------|--------|
| What broke | <endpoint(s) and assertion type that failed — e.g., POST /api/users expected 201, got 400> |
| Expected | <status code, response shape, or header the test asserted> |
| Got | <actual response — status, body excerpt, or error message> |
| Likely root cause | <validation rule changed / auth middleware drift / DB constraint / schema mismatch> |
| Pre-existing? | yes — also failed in CI grounding run (`$_TMP/qa-api-ci-ground.txt`) / no — regression introduced this session |

When `EXIT_CODE != 0`, the **Diagnosis** section is mandatory — complete it before listing individual failures. Cross-reference `$_TMP/qa-api-ci-ground.txt` to determine if each failure is pre-existing or a new regression.

For each failing test, check `./qa-flaky-registry.json` if present. If `flakeRate > 0.2`, annotate `[FLAKY N%]` instead of `[FAILED]`.

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

## CTRF Output

After writing `$_TMP/qa-api-report.md`, write `$_TMP/qa-api-ctrf.json`:

```python
python3 - << 'PYEOF'
import json, os, time, re

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
output_file = os.path.join(tmp, 'qa-api-runner-output.txt')
output = open(output_file, encoding='utf-8', errors='replace').read() \
         if os.path.exists(output_file) else ''

tests = []
# Parse common patterns from test output
for line in output.splitlines():
    m_pass = re.match(r'\s+[✓✅PASS]\s+(.+)', line)
    m_fail = re.match(r'\s+[✕×FAIL]\s+(.+)', line)
    if m_pass:
        tests.append({'name': m_pass.group(1).strip(), 'status': 'passed', 'duration': 0, 'suite': 'api'})
    elif m_fail:
        tests.append({'name': m_fail.group(1).strip(), 'status': 'failed', 'duration': 0, 'suite': 'api',
                      'message': 'See qa-api-report.md for details'})

# Fallback: emit summary buckets
if not tests:
    p = len(re.findall(r'passed|PASS|\d+ passing', output))
    f = len(re.findall(r'failed|FAIL|\d+ failing', output))
    if p: tests.append({'name': f'{p} tests passed', 'status': 'passed', 'duration': 0, 'suite': 'api'})
    if f: tests.append({'name': f'{f} tests failed', 'status': 'failed', 'duration': 0, 'suite': 'api',
                        'message': 'See qa-api-report.md for details'})

p = sum(1 for t in tests if t['status'] == 'passed')
f = sum(1 for t in tests if t['status'] == 'failed')
s = sum(1 for t in tests if t['status'] == 'skipped')
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': os.environ.get('_API_TOOL', 'unknown')},
        'summary': {
            'tests': len(tests), 'passed': p, 'failed': f,
            'pending': 0, 'skipped': s, 'other': 0,
            'start': now_ms - 5000, 'stop': now_ms,
        },
        'tests': tests,
        'environment': {
            'reportName': 'qa-api',
            'baseUrl': os.environ.get('_BASE_URL', 'unknown'),
        },
    }
}

out = os.path.join(tmp, 'qa-api-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  tests={len(tests)} passed={p} failed={f} skipped={s}')
PYEOF
```

## Agent Memory

After each run, update the memory file at `.claude/agent-memory/qa-api/MEMORY.md` (create if absent). Record:
- Detected framework, version, and config file paths
- Auth endpoint and credential format used
- Recurring failures or known flaky scenarios
- Base URL confirmed working
- Any test infrastructure quirks discovered

Read this file at the start of each run to skip re-detection of already-known facts.
