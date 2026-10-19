---
name: team
version: 1.0.0
description: |
  Agentic QA orchestrator. Analyzes the current project, determines which testing
  domains apply (web, API, mobile, performance, visual, security, ...), asks once for
  approval of any risky actions, then dispatches the qa-* subagents in capped parallel
  waves. Aggregates all results into a unified quality report.
when_to_use: |
  Use when asked to "run qa", "qa team", "full test suite", "test everything",
  "qa the app", or "run all agents".

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
---


> **Shell state does not persist between Bash tool calls.** The Preamble writes every
> signal to `$_TMP/qa-team-signals.env`; every later bash block recomputes `_TMP` and
> sources that file. Never rely on a variable set in an earlier block.

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
touch "$_TMP/qa-team-run.start"   # reports older than this marker are ignored in Phase 3
echo "BRANCH: $_BRANCH"
echo "DATE: $_DATE"
echo "TMP: $_TMP"

# Detect project type signals
echo "--- PROJECT SIGNALS ---"
ls package.json pyproject.toml go.mod Cargo.toml pom.xml build.gradle Gemfile 2>/dev/null | head -6
ls *.csproj *.sln global.json Directory.Build.props nuget.config 2>/dev/null | head -4
ls android/ ios/ app.json 2>/dev/null | head -3
ls openapi.yaml openapi.json swagger.yaml swagger.json 2>/dev/null | head -2

# Package manifest (drives qa:sca)
_MANIFEST_TYPE="unknown"
[ -f "package.json" ]     && _MANIFEST_TYPE="npm"
[ -f "go.mod" ]           && _MANIFEST_TYPE="go"
{ [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; } && _MANIFEST_TYPE="python"
{ [ -f "pom.xml" ] || [ -f "build.gradle" ]; } && _MANIFEST_TYPE="jvm"
[ -f "Cargo.toml" ]       && _MANIFEST_TYPE="cargo"
[ -f "Gemfile" ]          && _MANIFEST_TYPE="ruby"
find . -maxdepth 3 -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | grep -q . && _MANIFEST_TYPE="nuget"
echo "MANIFEST_TYPE: $_MANIFEST_TYPE"

# Web E2E tool detection
echo "--- WEB TOOLS ---"
_WEB_TOOL=""
ls playwright.config.ts playwright.config.js playwright.config.mts 2>/dev/null && _WEB_TOOL="playwright"
{ ls cypress.config.ts cypress.config.js cypress.config.mjs 2>/dev/null || [ -d cypress ]; } && \
  grep -q '"cypress"' package.json 2>/dev/null && _WEB_TOOL="${_WEB_TOOL:+$_WEB_TOOL,}cypress"
grep -q '"selenium-webdriver"\|"@seleniumhq"' package.json 2>/dev/null && \
  _WEB_TOOL="${_WEB_TOOL:+$_WEB_TOOL,}selenium"
# C# / .NET web E2E detection
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -l "Microsoft\.Playwright" 2>/dev/null | grep -q '.' && \
  _WEB_TOOL="${_WEB_TOOL:+$_WEB_TOOL,}playwright-dotnet"
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -l "Selenium\.WebDriver" 2>/dev/null | grep -q '.' && \
  _WEB_TOOL="${_WEB_TOOL:+$_WEB_TOOL,}selenium-dotnet"
echo "WEB_TOOL: ${_WEB_TOOL:-none}"

# Performance tool detection
echo "--- PERF TOOLS ---"
_PERF_TOOL=""
{ ls k6/ load-tests/ 2>/dev/null | grep -q '.' || \
  find . \( -path "*/k6/*.js" -o -path "*/k6/*.ts" \) ! -path "*/node_modules/*" 2>/dev/null | grep -q .; } && \
  _PERF_TOOL="k6"
find . -name "*.jmx" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && \
  _PERF_TOOL="${_PERF_TOOL:+$_PERF_TOOL,}jmeter"
{ ls locustfile.py 2>/dev/null || find . -name "locust*.py" ! -path "*/node_modules/*" 2>/dev/null | grep -q .; } && \
  _PERF_TOOL="${_PERF_TOOL:+$_PERF_TOOL,}locust"
echo "PERF_TOOL: ${_PERF_TOOL:-none}"

# Mobile tool detection
echo "--- MOBILE TOOLS ---"
_MOB_TOOL=""
grep -q '"detox"' package.json 2>/dev/null && _MOB_TOOL="detox"
grep -q '"appium"\|"@wdio"' package.json 2>/dev/null && \
  _MOB_TOOL="${_MOB_TOOL:+$_MOB_TOOL,}appium"
{ [ -d ".maestro" ] || which maestro > /dev/null 2>&1; } && \
  _MOB_TOOL="${_MOB_TOOL:+$_MOB_TOOL,}maestro"
echo "MOB_TOOL: ${_MOB_TOOL:-none}"

# Running services = candidate TARGET URLs (confirmed by the user before any agent probes one)
echo "--- RUNNING SERVICES ---"
_RUNNING_URLS=""
for port in 3000 3001 4000 4001 5000 5001 8000 8080; do
  _st=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://localhost:$port" 2>/dev/null)
  case "$_st" in ""|000*) continue ;; esac   # curl prints 000 when nothing listens
  echo "PORT $port: $_st" && _RUNNING_URLS="$_RUNNING_URLS http://localhost:$port"
done
for v in WEB_URL BASE_URL; do
  eval "_u=\${$v:-}"; [ -n "$_u" ] && echo "ENV $v: $_u" && _RUNNING_URLS="$_RUNNING_URLS $_u"
done
_RUNNING_URLS="${_RUNNING_URLS# }"
echo "CANDIDATE_TARGETS: ${_RUNNING_URLS:-none}"

# Security tool detection
echo "--- SECURITY TOOLS ---"
_SEC_TOOL=""
command -v zap.sh >/dev/null 2>&1 && _SEC_TOOL="zap"
docker image inspect softwaresecurityproject/zap-stable >/dev/null 2>&1 && \
  _SEC_TOOL="${_SEC_TOOL:+$_SEC_TOOL,}zap-docker"
command -v nuclei >/dev/null 2>&1 && _SEC_TOOL="${_SEC_TOOL:+$_SEC_TOOL,}nuclei"
[ -z "$_SEC_TOOL" ] && _SEC_TOOL="probe-only"
echo "SEC_TOOL: $_SEC_TOOL"

# Seed schema detection (qa:seed is only ever proposed with TEST_DATABASE_URL, never DATABASE_URL)
echo "--- SEED SCHEMA ---"
_SEED_SCHEMA="none"
ls prisma/schema.prisma 2>/dev/null && _SEED_SCHEMA="prisma"
find . -name "*.sql" -path "*/migrations/*" ! -path "*/node_modules/*" 2>/dev/null | \
  grep -q '.' && [ "$_SEED_SCHEMA" = "none" ] && _SEED_SCHEMA="sql-migrations"
find . \( -name "*.entity.ts" -o -name "*.entity.js" \) ! -path "*/node_modules/*" 2>/dev/null | \
  grep -q '.' && [ "$_SEED_SCHEMA" = "none" ] && _SEED_SCHEMA="typeorm"
_TEST_DB_SET=0; [ -n "${TEST_DATABASE_URL:-}" ] && _TEST_DB_SET=1
echo "SEED_SCHEMA: $_SEED_SCHEMA  TEST_DATABASE_URL_SET: $_TEST_DB_SET"

# Component testing tools
echo "--- COMPONENT TOOLS ---"
_COMP_TOOL=""
find . \( -name "main.js" -o -name "main.ts" -o -name "main.mjs" \) \
  -path "*/.storybook/*" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && \
  _COMP_TOOL="storybook"
grep -qE '"fast-check"|"@fast-check/' package.json 2>/dev/null && \
  _COMP_TOOL="${_COMP_TOOL:+$_COMP_TOOL,}fast-check"
echo "COMP_TOOL: ${_COMP_TOOL:-none}"

# Methodology: detect whether the project has any test files
echo "--- TEST FILES ---"
_HAS_TESTS=0
find . \( \
  -name "*.spec.ts" -o -name "*.spec.js" \
  -o -name "*.test.ts" -o -name "*.test.js" \
  -o -name "*_test.py" -o -name "test_*.py" \
  -o -name "*Test.java" -o -name "*_spec.rb" \
  -o -name "*Tests.cs" -o -name "*Test.cs" -o -name "*Spec.cs" \
  \) ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | grep -q '.' && _HAS_TESTS=1
echo "HAS_TESTS: $_HAS_TESTS"

# Cheap preconditions for the static extras (proposed in the plan when present)
echo "--- STATIC EXTRAS ---"
_ENV_FILES=$(ls .env .env.local .env.development .env.staging .env.production .env.test 2>/dev/null | wc -l | tr -d ' ')
_COVERAGE_DATA=0
ls coverage/lcov.info coverage/coverage-final.json coverage.xml coverage.out .coverage 2>/dev/null | grep -q . && _COVERAGE_DATA=1
find . -maxdepth 4 -name "coverage.cobertura.xml" ! -path "*/node_modules/*" 2>/dev/null | grep -q . && _COVERAGE_DATA=1
_ATTESTATIONS=0
grep -rlqE "attest-build-provenance|slsa-github-generator|slsa-framework" .github/workflows 2>/dev/null && _ATTESTATIONS=1
find . -maxdepth 3 -name "*.intoto.jsonl" 2>/dev/null | grep -q . && _ATTESTATIONS=1
_COMPOSE_FILE=""
for f in test-env.yml docker-compose.test.yml compose.test.yml docker-compose.yml compose.yml; do
  [ -f "$f" ] && _COMPOSE_FILE="$f" && break
done
command -v docker >/dev/null 2>&1 && _DOCKER_AVAILABLE=1 || _DOCKER_AVAILABLE=0
echo "ENV_FILES: $_ENV_FILES  COVERAGE_DATA: $_COVERAGE_DATA  ATTESTATIONS: $_ATTESTATIONS"
echo "COMPOSE_FILE: ${_COMPOSE_FILE:-none}  DOCKER_AVAILABLE: $_DOCKER_AVAILABLE"

# On-request triggers (reported in the plan; never auto-run)
echo "--- ON-REQUEST TRIGGERS ---"
ls -d evals tests/evals 2>/dev/null | head -1 | sed 's/^/EVALS_DIR: /'
find . -maxdepth 3 -name "*.intent.yaml" ! -path "*/node_modules/*" 2>/dev/null | head -1 | sed 's/^/INTENT_YAML: /'
find . -maxdepth 2 \( -name "PRD*.md" -o -name "SPEC*.md" -o -type d -name specs \) ! -path "*/node_modules/*" 2>/dev/null | head -1 | sed 's/^/SPEC_DOCS: /'
[ -n "${OTEL_EXPORTER_OTLP_ENDPOINT:-}${LOKI_URL:-}${JAEGER_URL:-}${TEMPO_URL:-}" ] && echo "OBSERVABILITY_STACK: set"
[ -n "${BUILDEVENTS_APIKEY:-}${HONEYCOMB_DATASET:-}" ] && echo "CI_TRACE_BACKEND: set"
[ -n "${JIRA_URL:-}" ] && echo "JIRA_URL: set"

# CI status (drives the qa:heal proposal)
_CI_FAILING=0
if command -v gh >/dev/null 2>&1; then
  gh pr view --json statusCheckRollup -q '.statusCheckRollup[].conclusion' 2>/dev/null | \
    grep -qE "FAILURE|TIMED_OUT|CANCELLED" && _CI_FAILING=1
fi
echo "CI_FAILING: $_CI_FAILING"

# Complexity scoring signals (for hardness-aware routing)
echo "--- COMPLEXITY SIGNALS ---"
_ROUTE_COUNT=$(find . \( -path "*/routes/*.ts" -o -path "*/routes/*.js" \
  -o -path "*/controllers/*.ts" -o -path "*/controllers/*.js" \
  -o -path "*/pages/*.tsx" -o -path "*/app/**/*.tsx" \
  \) ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
echo "ROUTE_COUNT: $_ROUTE_COUNT"

_HAS_AUTH=0
grep -rl "auth\|jwt\|session\|passport\|oauth\|bearer" \
  --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
  . 2>/dev/null | grep -qiE "middleware|guard|auth" && _HAS_AUTH=1
echo "HAS_AUTH: $_HAS_AUTH"

_DOMAIN_COUNT=0
[ -n "$_WEB_TOOL" ] && _DOMAIN_COUNT=$((_DOMAIN_COUNT+1))
[ -n "$_PERF_TOOL" ] && _DOMAIN_COUNT=$((_DOMAIN_COUNT+1))
[ -n "$_MOB_TOOL" ] && _DOMAIN_COUNT=$((_DOMAIN_COUNT+1))
[ "$_HAS_TESTS" = "1" ] && _DOMAIN_COUNT=$((_DOMAIN_COUNT+1))
echo "DOMAIN_COUNT: $_DOMAIN_COUNT"

_LOC=$(find . \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
  -o -name "*.py" -o -name "*.java" -o -name "*.cs" \) \
  ! -path "*/node_modules/*" ! -path "*/obj/*" ! -name "*.spec.*" ! -name "*.test.*" \
  2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
_LOC=${_LOC:-0}
echo "LOC: $_LOC"

# --- MULTI-REPO SUPPORT ---
# Set QA_EXTRA_PATHS (space-separated absolute paths) to scan tests in other repos
# e.g.: export QA_EXTRA_PATHS="/path/to/e2e-repo /path/to/api-tests-repo"
if [ -n "$QA_EXTRA_PATHS" ]; then
  echo "MULTI_REPO_PATHS: $QA_EXTRA_PATHS"
  for _qr in $QA_EXTRA_PATHS; do
    _extra=$(find "$_qr" \( \
      -name "*.spec.ts" -o -name "*.spec.js" -o -name "*.test.ts" -o -name "*.test.js" \
      -o -name "*_test.py" -o -name "test_*.py" -o -name "*Test.java" \
      -o -name "*Tests.cs" -o -name "*_spec.rb" -o -name "*.yaml" \) \
      ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | wc -l | tr -d ' ')
    echo "EXTRA_REPO $(basename "$_qr"): $_extra test files — $_qr"
  done
fi

# aimock detection (BL-025)
_AIMOCK_AVAILABLE=0; command -v aimock >/dev/null 2>&1 && _AIMOCK_AVAILABLE=1
_AIMOCK_FIXTURES=0; find fixtures -maxdepth 1 -name "*.json" 2>/dev/null | grep -q '.' && _AIMOCK_FIXTURES=1
echo "AIMOCK_AVAILABLE: $_AIMOCK_AVAILABLE  AIMOCK_FIXTURES: $_AIMOCK_FIXTURES"

# Persist every signal for later bash blocks
cat > "$_TMP/qa-team-signals.env" <<EOF
_DATE='$_DATE'
_BRANCH='$_BRANCH'
_MANIFEST_TYPE='$_MANIFEST_TYPE'
_WEB_TOOL='$_WEB_TOOL'
_PERF_TOOL='$_PERF_TOOL'
_MOB_TOOL='$_MOB_TOOL'
_RUNNING_URLS='$_RUNNING_URLS'
_SEC_TOOL='$_SEC_TOOL'
_SEED_SCHEMA='$_SEED_SCHEMA'
_TEST_DB_SET='$_TEST_DB_SET'
_COMP_TOOL='$_COMP_TOOL'
_HAS_TESTS='$_HAS_TESTS'
_ENV_FILES='$_ENV_FILES'
_COVERAGE_DATA='$_COVERAGE_DATA'
_ATTESTATIONS='$_ATTESTATIONS'
_COMPOSE_FILE='$_COMPOSE_FILE'
_DOCKER_AVAILABLE='$_DOCKER_AVAILABLE'
_CI_FAILING='$_CI_FAILING'
_ROUTE_COUNT='${_ROUTE_COUNT:-0}'
_HAS_AUTH='$_HAS_AUTH'
_DOMAIN_COUNT='$_DOMAIN_COUNT'
_LOC='$_LOC'
_AIMOCK_AVAILABLE='$_AIMOCK_AVAILABLE'
_AIMOCK_FIXTURES='$_AIMOCK_FIXTURES'
EOF
echo "SIGNALS: $_TMP/qa-team-signals.env"
echo "--- DONE ---"
```

If `MULTI_REPO_PATHS` output appeared: when sampling test files in subsequent phases, include files from those extra paths, and put `QA_EXTRA_PATHS=<paths>` in every brief's `NOTES:`. Language detection uses CWD (the main application repository).

## Phase 0 — Candidate Agents

Build the candidate plan from the signals. Nothing runs yet; the plan is confirmed once in Phase 1.5.

**Core** (detected domain; works offline unless given `TARGET`, sends state-changing requests to it — e.g. qa:api's Dredd run — only with `ALLOW_FORM_SUBMIT`, installs tools only with `ALLOW_INSTALL`):
- `playwright.config.*` / `e2e/` / `cypress.config.*` / `cypress/` / `selenium-webdriver` in package.json, or `Microsoft.Playwright` / `Selenium.WebDriver` in a `.csproj` → **qa:web**
- `openapi.*` / `swagger.*` / `api/` routes → **qa:api**
- `android/` / `ios/` / `app.json` (Expo) / `.maestro/` → **qa:mobile**
- `k6/` / `locustfile.py` / `load-tests/` / `*.jmx` → **qa:perf**
- `playwright.config.*` + a `screenshots/` or `visual/` dir → **qa:visual**
- `HAS_TESTS=1` → **qa:audit**
- `WEB_TOOL` non-empty → **qa:a11y**
- `COMP_TOOL` contains `storybook` → **qa:component**
- always → **qa:secrets** (skips gracefully if trufflehog is absent)
- `MANIFEST_TYPE != unknown` → **qa:sca**

**Proposed** (shown in the plan with why; risky parts governed by approvals):
- **qa:security** — web or API detected. Passive probes against `TARGET` only; active scanning needs `ALLOW_ACTIVE_SCAN`. Without a `TARGET` it is left out.
- **qa:explore** — a candidate target exists and `QA_SKIP_EXPLORE` is not set. Navigation-only against `TARGET`; submitting forms or sending POST/PUT/PATCH/DELETE needs `ALLOW_FORM_SUBMIT`. Without a `TARGET` it is left out.
- **qa:seed** — `SEED_SCHEMA != none`. Generates seed files only; writing to a database needs `ALLOW_DB_WRITE` **and** `TEST_DATABASE_URL` set. Never offer or pass `DATABASE_URL`.
- **qa:heal** — `CI_FAILING=1`, or the test waves report failures. Runs alone after the test waves (Phase 2.5). Edits spec files in the working tree; committing needs `ALLOW_COMMIT`, a PR needs `ALLOW_PR`, an issue needs `ALLOW_ISSUE`.
- **qa:geo** — `WEB_TOOL` non-empty and a candidate target exists (needs `TARGET`).
- **qa:deps** — Docker available and a *test* compose file (`test-env.yml`, `docker-compose.test.yml`, `compose.test.yml`). It runs `docker compose up` / `down` on that file. With only a general `docker-compose.yml`/`compose.yml`, list it as on-request instead (it would stop that stack).
- **qa:test-lint** — `HAS_TESTS=1` (static).
- **qa:env-parity** — `ENV_FILES >= 2` (static).
- **qa:coverage-gate** — `COVERAGE_DATA=1`.
- **qa:slsa** — `ATTESTATIONS=1`.
- **qa:simulate** — only when `QA_SIMULATE=1` or the user asks (needs `TARGET`; forms need `ALLOW_FORM_SUBMIT`).
- **qa:deeplinks** — only when `QA_DEEPLINKS=1` or the user asks.

**Available on request** (listed in the plan with their trigger; added only if the user names them):

| Agent | Trigger / when it is worth running |
|---|---|
| qa:test-order | order-dependent or flaky tests suspected (re-runs the suite several times — slow) |
| qa:test-docs | documentation of what the suite covers is wanted |
| qa:spec-to-test | `SPEC_DOCS` found and tests should be derived from PRD/spec markdown |
| qa:manager | `JIRA_URL` set; tests from a JIRA epic / Figma frames |
| qa:eval-gate | `EVALS_DIR` found (AI features; calls an LLM API) |
| qa:intent-assert | `INTENT_YAML` found (LLM judge) |
| qa:observability | critical failures and `OBSERVABILITY_STACK: set` — run after Phase 3 |
| qa:ci-trace | `CI_TRACE_BACKEND: set` |
| qa:cost | AI spend for this run is wanted (`QA_COST_BUDGET`) — run after Phase 3 |
| qa:report | a multi-run / sprint dashboard is wanted (this skill already writes the run report) |
| qa:meta-eval | evaluating the QA agents themselves |

`learning-sources-refinement` is a repository-maintenance agent; never dispatch it.

## Phase 0.5 — Test Impact Analysis

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_CHANGED=$(git diff --name-only origin/main 2>/dev/null \
  || git diff --name-only HEAD~1 2>/dev/null || echo "")
_CHANGED_COUNT=$(printf '%s\n' "$_CHANGED" | grep -c '.' 2>/dev/null)
_INFRA_CHANGED=$(printf '%s\n' "$_CHANGED" | grep -cE 'config\.|tsconfig|package\.json|package-lock|migrations/' 2>/dev/null)
_IMPACT_MODE="full"
[ "${_CHANGED_COUNT:-0}" -gt 0 ] && [ "${_CHANGED_COUNT:-0}" -le 5 ] && [ "${_INFRA_CHANGED:-0}" -eq 0 ] && _IMPACT_MODE="fast"
printf '%s\n' "$_CHANGED" > "$_TMP/qa-team-changed.txt"
echo "_IMPACT_MODE='$_IMPACT_MODE'" >> "$_TMP/qa-team-signals.env"
echo "IMPACT_MODE: $_IMPACT_MODE  CHANGED_COUNT: ${_CHANGED_COUNT:-0}  INFRA_CHANGED: ${_INFRA_CHANGED:-0}"
head -20 "$_TMP/qa-team-changed.txt"
```

If nothing changed: FULL-PATH. **Impact mapping heuristics** — map changed files to affected domains:
- `src/auth/**`, `auth.*`, `*middleware*` → web + api
- `src/api/**`, `routes/**`, `controllers/**` → api
- `*.config.*`, `tsconfig.*`, `package.json`, `package-lock.json` → all domains (config change)
- `migrations/**`, `prisma/**`, `schema.*`, `*.sql` → api
- `src/components/**`, `pages/**`, `views/**`, `screens/**` → web
- `android/**`, `ios/**` → mobile
- `k6/**`, `load-tests/**`, `locust*.py` → perf

In FAST-PATH, put the relevant changed files in the brief's `IMPACT:` line for the flagged agents. Report the scoping decision at the top of Phase 1 output.

## Phase 0.8 — Hardness-Aware Routing (BL-012)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
. "$_TMP/qa-team-signals.env"
_HARDNESS=0
[ "${_ROUTE_COUNT:-0}" -gt 20 ] && _HARDNESS=$((_HARDNESS+1))
[ "${_ROUTE_COUNT:-0}" -gt 50 ] && _HARDNESS=$((_HARDNESS+1))
[ "${_HAS_AUTH:-0}" = "1" ] && _HARDNESS=$((_HARDNESS+1))
[ "${_DOMAIN_COUNT:-0}" -ge 3 ] && _HARDNESS=$((_HARDNESS+1))
[ "${_DOMAIN_COUNT:-0}" -ge 5 ] && _HARDNESS=$((_HARDNESS+1))
[ "${_LOC:-0}" -gt 5000 ] && _HARDNESS=$((_HARDNESS+1))
[ "${_LOC:-0}" -gt 20000 ] && _HARDNESS=$((_HARDNESS+1))
_COMPLEXITY_TIER="complex"
[ "$_HARDNESS" -lt 3 ] && _COMPLEXITY_TIER="simple"
[ "$_HARDNESS" -ge 6 ] && _COMPLEXITY_TIER="very-complex"
printf "_HARDNESS='%s'\n_COMPLEXITY_TIER='%s'\n" "$_HARDNESS" "$_COMPLEXITY_TIER" >> "$_TMP/qa-team-signals.env"
echo "HARDNESS_SCORE: $_HARDNESS  COMPLEXITY_TIER: $_COMPLEXITY_TIER"
echo "REASON: routes=$_ROUTE_COUNT auth=$_HAS_AUTH domains=$_DOMAIN_COUNT LOC=$_LOC"
```

Tier behavior when building the plan:
- **SIMPLE** (`< 3`): core agents only, plus the static extras (qa:test-lint, qa:env-parity). qa:web gets `MODE: fast` (no POM, no auth setup, ~5 critical-path smoke tests). Do not add qa:audit or qa:explore unless detected/asked.
- **COMPLEX** (3–5): normal plan.
- **VERY-COMPLEX** (`>= 6`): add qa:audit (unless `QA_SKIP_AUDIT=1`) and propose qa:explore (unless `QA_SKIP_EXPLORE=1`). Deep mode is **not** automatic: briefs get `MODE: deep` only if `QA_DEEP_MODE=1` is set or the user picks the deep-mode option in Phase 1.5.

## Phase 1 — Project Analysis

Read enough context so each subagent is briefed correctly:

```bash
# Tech stack
cat package.json 2>/dev/null | grep -E '"name"|"version"|"dependencies"' | head -30
cat README.md 2>/dev/null | head -50

# Entry points
find . -maxdepth 3 \( -name "*.config.ts" -o -name "*.config.js" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -10

# API routes (common patterns)
find . \( -path "*/routes/*.ts" -o -path "*/routes/*.js" -o -path "*/controllers/*.ts" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -20

# Web pages / screens
find . \( -path "*/pages/*.tsx" -o -path "*/screens/*.tsx" -o -path "*/views/*.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -20

# C# / .NET project discovery
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | head -10
find . \( -path "*/Controllers/*.cs" -o -path "*/Pages/*.cs" -o -path "*/Views/*.cs" \) \
  ! -path "*/obj/*" 2>/dev/null | head -20
```

Summarize findings:
- App name and version
- Framework (Next.js, Express, FastAPI, React Native, etc.)
- Base URL candidates (from `CANDIDATE_TARGETS`; not yet approved)
- List of key pages / endpoints / screens
- Auth mechanism (JWT, session, OAuth)
- Detected tools per domain (`WEB_TOOL`, `PERF_TOOL`, `MOB_TOOL`, `SEC_TOOL`, `COMP_TOOL`)

Save the summary to `$_TMP/qa-team-context.md` for subagents to read. Never copy credentials, tokens or connection strings into it.

## Phase 1.5 — Plan and Approvals (the one approval step)

This is the **only** question to the user before dispatch. Subagents cannot ask anything later, so everything risky is decided here. Every risky key defaults to **not granted**.

1. Print the plan as text: **Core**, **Proposed** (each with the reason it was detected and what it does without approvals), **Available on request** (with trigger), the wave layout (Phase 2), and the complexity tier.
2. Make **one** `AskUserQuestion` call with only the questions that apply (max 4; omit a question, or an option, when no planned agent needs it):

   - **Q1 Target** (when any planned agent runs against a live app — qa:web, qa:api, qa:perf, qa:visual, qa:a11y, qa:geo, qa:explore, qa:security, qa:simulate, qa:deeplinks): "Which URL may the agents actively test?" Options: each entry of `CANDIDATE_TARGETS` (max 3) | "No target — offline/static only". The user may type another URL via Other. The chosen URL becomes `TARGET=<url>`; agents that need a target and get none either work offline (write/review tests, no execution) or are dropped (qa:explore, qa:security, qa:geo, qa:simulate). Never pick a production URL on the user's behalf.
   - **Q2 Test-environment actions** (multiSelect): `ALLOW_ACTIVE_SCAN` — "qa:security may run active/intrusive scans against TARGET" | `ALLOW_FORM_SUBMIT` — "agents may submit forms or send state-changing requests (POST/PUT/PATCH/DELETE) to TARGET (qa:api contract runs, qa:explore, qa:simulate)" | `ALLOW_DB_WRITE` — "qa:seed may write to TEST_DATABASE_URL (<host>/<db>)" — offer only when `TEST_DATABASE_URL_SET=1`, and show host/db name only, never the full URL | "Start test services (`docker compose -f <COMPOSE_FILE> up -d --wait`)" — offer only for a *test* compose file.
   - **Q3 Install / repository / GitHub actions** (multiSelect): `ALLOW_INSTALL` — "agents may install packages/tools into the project or environment (npm install --save-dev, pip install, npx --yes); without it they report what is missing" | `ALLOW_COMMIT` — "qa:heal may commit its fixes on a new branch (never main/master)" | `ALLOW_PR` — "push that branch and open a PR" | `ALLOW_ISSUE` — "file issues for low-confidence heals and post the QA summary as a PR comment". Offer the last three only if qa:heal is planned or `gh pr view` succeeds.
   - **Q4 Plan**: "Run this plan?" Options: "Core + proposed (Recommended)" | "Core + proposed, deep mode" | "Core only". Other = free-text edits (e.g. "drop qa:perf, add qa:test-order").

3. Record the decision (substitute the real answers):

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
cat > "$_TMP/qa-team-plan.md" <<'EOF'
SELECTED: qa:web qa:api qa:a11y qa:secrets qa:sca      # adjust to the confirmed plan
POST_WAVE: qa:heal                                     # or empty
TARGET: http://localhost:3000                          # or none
GRANTED: ALLOW_FORM_SUBMIT                             # space-separated keys, or none
MODE: standard                                         # standard | deep
START_TEST_SERVICES: no                                # yes | no
EOF
cat "$_TMP/qa-team-plan.md"
```

## Phase 1.8 — Test Services + Offline Prep (BL-024 + BL-025)

Run only what Phase 1.5 approved.

**Test services** (only if "Start test services" was chosen): start the test stack once so agents share a known environment, and pass the service URLs in each brief's `NOTES:`. Do not also schedule qa:deps in this run (it would tear the stack down).

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"; . "$_TMP/qa-team-signals.env"
if [ "$_DOCKER_AVAILABLE" = "1" ] && [ -n "$_COMPOSE_FILE" ]; then
  timeout 120 docker compose -f "$_COMPOSE_FILE" up -d --wait 2>&1 | tail -20
  docker compose -f "$_COMPOSE_FILE" ps 2>&1
fi
```

**aimock replay** (when `AIMOCK_FIXTURES=1` and `AIMOCK_AVAILABLE=1`): serve external calls (LLM, third-party APIs) from fixtures.

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"; . "$_TMP/qa-team-signals.env"
if [ "$_AIMOCK_FIXTURES" = "1" ] && [ "$_AIMOCK_AVAILABLE" = "1" ]; then
  nohup aimock --replay fixtures/ > "$_TMP/qa-team-aimock.log" 2>&1 &
  echo $! > "$_TMP/qa-team-aimock.pid"
  echo "AIMOCK_REPLAY_PID: $(cat "$_TMP/qa-team-aimock.pid")"
fi
```

## Phase 2 — Dispatch Subagents (capped parallel waves)

The `/qa:<domain>` skills cannot be invoked from here (`disable-model-invocation: true`). Dispatch each agent with the **Agent tool**, `subagent_type: "qa:<domain>"` (the qa plugin's agents, e.g. `qa:web`, `qa:api`). If the Agent tool reports an unknown subagent type, stop and tell the user to enable or update the qa plugin (`/plugin`), then run `/reload-plugins`.

Subagents **cannot spawn further agents** and **cannot ask the user** — the brief is all they get. Each one skips any gated step whose key is missing from its `APPROVALS:` line and lists it under **Needs a decision**.

**Brief format** — one per agent; substitute real values (absolute paths, no shell variables):

```
QA-TEAM BRIEF
AGENT: qa:<domain>
WORKDIR: <absolute project path>
PROJECT_CONTEXT: <absolute $_TMP>/qa-team-context.md   (read this first)
DETECTED_TOOL: <tool for this domain, or none>   (if set, skip the tool-selection gate and use it)
IMPACT: full | fast: <changed files relevant to this agent>
MODE: standard | fast | deep
APPROVALS: <space-separated keys granted to THIS agent, e.g. TARGET=http://localhost:3000 ALLOW_FORM_SUBMIT — or: none>
REPORT: <absolute $_TMP>/qa-<domain>-report.md
CTRF: <absolute $_TMP>/qa-<domain>-ctrf.json
NOTES: <service URLs from Phase 1.8, QA_EXTRA_PATHS, failure list for qa:heal — or: none>

Write your report to REPORT exactly (no dated filename) and your CTRF to CTRF. Do not ask
questions and do not start other agents. End your reply with the report path, a one-line
status, and the "Needs a decision" list (or "none").
```

Rules for the brief:
- **Least privilege:** give each agent only the keys that apply to it. `TARGET=` only to agents that run against the app; `ALLOW_ACTIVE_SCAN` only to qa:security, qa:api (OFFAT fuzzing), qa:perf (chaos experiments) and qa:simulate (red-team turns); `ALLOW_FORM_SUBMIT` only to agents that send requests to `TARGET` (qa:api, qa:perf, qa:explore, qa:simulate, and qa-web/qa-geo when their flows submit forms); `ALLOW_DB_WRITE` only to qa:seed; `ALLOW_INSTALL` to every agent when granted; `ALLOW_COMMIT` / `ALLOW_PR` / `ALLOW_ISSUE` only to qa:heal.
- **qa:seed:** add the line `TEST_DATABASE_URL: from environment` only when `ALLOW_DB_WRITE` was granted; the agent reads `$TEST_DATABASE_URL` itself. Never put the URL (it carries credentials) in a brief, report or plan file, and never pass `DATABASE_URL`.
- **MODE:** `fast` only for qa:web in the SIMPLE tier; `deep` only when opted in (Phase 0.8); otherwise `standard`.

**Waves** — at most **4** agents run concurrently: send up to 4 Agent calls in one message, wait for all of them, then send the next wave.
1. If qa:seed has `ALLOW_DB_WRITE`, run it first, alone, so the test agents see the seeded data.
2. Test-writing and scanning agents (web, api, mobile, visual, a11y, component, geo, explore, security, simulate, deeplinks, deps, and the static ones: audit, secrets, sca, test-lint, env-parity, coverage-gate, slsa), 4 per wave. Put the static agents alongside the heavier ones to balance waves. Two agents in the same wave must not write the same files; when unsure, put them in different waves.
3. qa:perf runs in its own wave when it will execute load against `TARGET` (load skews the other agents' results, and theirs skew it).

## Phase 2.5 — qa:heal (after the test waves, never concurrently)

qa:heal reads failures and may modify spec files, so it runs only after every test-writing wave has finished, alone, in the same working tree. Run it if it was approved in the plan and either `CI_FAILING=1` or any wave report lists failed tests. Its `NOTES:` lists the reports/CTRF files with failures and says: "commit only files you changed". It gets `ALLOW_COMMIT` / `ALLOW_PR` / `ALLOW_ISSUE` only as granted.

**Teardown** after Phase 2.5:

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"; . "$_TMP/qa-team-signals.env"
[ -f "$_TMP/qa-team-aimock.pid" ] && kill "$(cat "$_TMP/qa-team-aimock.pid")" 2>/dev/null; rm -f "$_TMP/qa-team-aimock.pid"
# only if this run started the test services in Phase 1.8:
# docker compose -f "$_COMPOSE_FILE" down 2>&1 | tail -5
```

## Phase 3 — Aggregate Results

Read every report written during this run — the brief's path first, then dated names (`qa-<domain>-report-<date>.md`) in `$_TMP`, the project root or `reports/`, in case an agent used its own naming:

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
find "$_TMP" . reports -maxdepth 1 -name 'qa-*-report*.md' -newer "$_TMP/qa-team-run.start" 2>/dev/null | sort -u | \
while read -r f; do
  echo "=== $(basename "$f") ==="; cat "$f"
done
```

Any planned agent with no report → "not run / no report" in the summary.

Compute aggregates:
- Total tests: sum across all domains
- Passed / Failed / Skipped counts
- Critical failures (tests marked `[CRITICAL]` in reports)
- Coverage gaps (pages/endpoints/screens with no tests)
- **Needs a decision**: every gated step agents skipped, grouped by approval key

## Phase 3.5 — Flaky Registry Update

Merge all CTRF files from this run and update `./qa-flaky-registry.json`:

```python
python3 - << 'PYEOF'
import json, glob, os
from datetime import date

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
ctrf_files = glob.glob(os.path.join(tmp, 'qa-*-ctrf.json'))

merged_tests = []
for f in ctrf_files:
    try:
        d = json.load(open(f, encoding='utf-8'))
        domain = d['results']['environment'].get('reportName', 'unknown')
        for t in d['results'].get('tests', []):
            t['_domain'] = domain
            merged_tests.append(t)
    except Exception as e:
        print(f"WARN: could not parse {f}: {e}")

print(f"MERGED_CTRF_FILES: {len(ctrf_files)}")
print(f"MERGED_TESTS: {len(merged_tests)}")

# Load or create registry
registry_path = 'qa-flaky-registry.json'
registry = {'tests': {}}
if os.path.exists(registry_path):
    try:
        registry = json.load(open(registry_path, encoding='utf-8'))
    except:
        pass

today = str(date.today())
for t in merged_tests:
    domain = t.get('_domain', 'unknown')
    suite = t.get('suite', '')
    name = t.get('name', '')
    key = f'{domain}::{suite}::{name}'
    status = t.get('status', 'other')

    if key not in registry['tests']:
        registry['tests'][key] = {'results': [], 'flakeRate': 0.0, 'lastUpdated': today, 'classification': 'suspected'}

    entry = registry['tests'][key]
    entry['results'].append(status)
    entry['results'] = entry['results'][-20:]  # keep last 20
    entry['lastUpdated'] = today

    non_skipped = [r for r in entry['results'] if r != 'skipped']
    if non_skipped:
        entry['flakeRate'] = round(non_skipped.count('failed') / len(non_skipped), 3)

json.dump(registry, open(registry_path, 'w', encoding='utf-8'), indent=2)
print(f"REGISTRY_WRITTEN: {registry_path}")

# Report flaky tests above 20%
flaky = [(k, v) for k, v in registry['tests'].items() if v.get('flakeRate', 0) > 0.2]
print(f"FLAKY_TESTS (>20%): {len(flaky)}")
for k, v in sorted(flaky, key=lambda x: -x[1]['flakeRate'])[:10]:
    print(f"  {v['flakeRate']:.0%} — {k}")
PYEOF
```

In Phase 4 unified report:
- Tests with `flakeRate > 0.2` → annotate `[FLAKY N%]` rather than `[FAILED]`
- Tests with `flakeRate > 0.5` currently failing → downgrade from BLOCKING to WARNING

## Phase 4 — Unified Quality Report

Write `qa-report-<date>.md` to the project root (or `reports/` if it exists):

```markdown
# QA Team Report — <date> — <branch>

## Executive Summary
- **Overall Status**: ✅ Pass / ⚠️ Partial / ❌ Fail
- **Total Tests**: N (passed: N, failed: N, skipped: N)
- **Agents Run**: <list>
- **Tools Used**: <e.g. Playwright · REST Assured · Detox · k6>
- **Target**: <TARGET or "offline">  **Approvals granted**: <keys or none>

## Routing
- Complexity tier: simple / complex / very-complex (score N/7)
- Reason: routes=N, auth=yes/no, domains=N, LOC=N
- Waves: <wave 1: ...; wave 2: ...; post-wave: qa:heal>

## Domain Results
### <Agent> (<detected tool>)
<one section per agent that ran: its summary, or "no report">

## Critical Failures
<list only failed tests, with error snippet>

## Coverage Gaps
<pages / endpoints / screens that had no test coverage>

## Needs a Decision
<gated steps the agents skipped, grouped by approval key — re-run with that approval to execute them>

## Recommended Next Steps
<top 3 actions based on failures and gaps; mention on-request agents whose trigger was detected>
```

Print the report path and overall pass/fail status.

If there are critical failures: "Found N critical failures. Run /qa:observability to root-cause them, or /qa:heal if they look like broken selectors?"

## Optional: GitHub PR Comment

Merge all per-domain CTRF files into `$_TMP/qa-team-ctrf.json` (for CI dashboards):

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_BRANCH=$(git branch --show-current 2>/dev/null || echo unknown) python3 - << 'PYEOF'
import json, glob, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
ctrf_files = [f for f in glob.glob(os.path.join(tmp, 'qa-*-ctrf.json')) if not f.endswith('qa-team-ctrf.json')]

all_tests = []
for f in ctrf_files:
    try:
        d = json.load(open(f, encoding='utf-8'))
        all_tests.extend(d['results'].get('tests', []))
    except:
        pass

p = sum(1 for t in all_tests if t['status'] == 'passed')
f_ = sum(1 for t in all_tests if t['status'] == 'failed')
s = sum(1 for t in all_tests if t['status'] == 'skipped')
now_ms = int(time.time() * 1000)

merged = {
    'results': {
        'tool': {'name': 'qa-team'},
        'summary': {
            'tests': len(all_tests), 'passed': p, 'failed': f_, 'pending': 0,
            'skipped': s, 'other': 0, 'start': now_ms - 60000, 'stop': now_ms,
        },
        'tests': all_tests,
        'environment': {'reportName': 'qa-team', 'branch': os.environ.get('_BRANCH', 'unknown')},
    }
}

out = os.path.join(tmp, 'qa-team-ctrf.json')
json.dump(merged, open(out, 'w', encoding='utf-8'), indent=2)
print(f'MERGED_CTRF: {out}  tests={len(all_tests)} passed={p} failed={f_} skipped={s}')
PYEOF
```

Post a PR comment **only if `ALLOW_ISSUE` was granted in Phase 1.5**; otherwise list "post QA summary to PR" under Needs a Decision. Write the Executive Summary + Critical Failures (no secrets, no internal URLs beyond TARGET) to `$_TMP/qa-team-pr-comment.md`, then:

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
command -v gh >/dev/null 2>&1 && gh pr view >/dev/null 2>&1 && \
  gh pr comment --body-file "$_TMP/qa-team-pr-comment.md" || echo "PR_COMMENT: skipped (no gh or no open PR)"
```

Do not install packages to post the comment.

## Important Rules

- **One approval step** — risky actions happen only with the keys granted in Phase 1.5; the default for every key is not granted
- **Never use `DATABASE_URL`** — database writes go only to `TEST_DATABASE_URL`, and only with `ALLOW_DB_WRITE`
- **Probe only `TARGET`** — no agent tests a URL the user did not confirm
- **No installs without `ALLOW_INSTALL`** — otherwise agents report what is missing
- **Skip domains with insufficient signals** — don't force a mobile agent on a web-only project
- **Subagents are independent** — they share only the context file and their brief; qa:heal never runs concurrently with test-writing agents
- **Report even if tests fail** — always produce the aggregated report regardless of exit codes
- **Idempotent** — safe to re-run; overwrites `$_TMP/qa-*-report.md` and the root report
