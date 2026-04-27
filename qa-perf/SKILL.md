---
name: qa-perf
preamble-tier: 3
version: 1.0.0
description: |
  Performance test agent. Identifies critical user journeys and API endpoints,
  generates load test scripts for the detected tool (k6, JMeter, or Locust),
  executes them, and analyzes throughput, latency percentiles, and error rates.
  Works standalone or as a sub-agent of /qa-team. Use when asked to "qa performance",
  "load test", "stress test", "performance testing", "k6", "jmeter", "locust",
  "benchmark the api", or "perf test agent". (qa-agentic-team)
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
_QA_ROOT=$(dirname "$(readlink ~/.claude/skills/qa-perf 2>/dev/null)" 2>/dev/null) || true
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

# Detect base URLs
_API_URL=$(grep -r "API_URL\|apiUrl\|BASE_URL" .env .env.local .env.test 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
_API_URL="${_API_URL:-http://localhost:3001}"
_WEB_URL="${WEB_URL:-http://localhost:3000}"
echo "API_URL: $_API_URL"
echo "WEB_URL: $_WEB_URL"

# Check API/web liveness
for url in "$_API_URL" "$_WEB_URL"; do
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
  echo "HEALTH $url: $status"
done

# --- PERF TOOL DETECTION ---
echo "--- K6 ---"
_K6=0
which k6 2>/dev/null && _K6=1
find . \( -path "*/k6/*.js" -o -path "*/k6/*.ts" -o -path "*/load-tests/*.k6.js" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -5 | grep -q '.' && _K6=1
echo "K6_PRESENT: $_K6"

echo "--- JMETER ---"
_JMETER=0
which jmeter 2>/dev/null && _JMETER=1
_JMX_COUNT=$(find . -name "*.jmx" ! -path "*/node_modules/*" 2>/dev/null | wc -l)
[ "$_JMX_COUNT" -gt 0 ] && _JMETER=1
echo "JMETER_PRESENT: $_JMETER  JMX_FILES: $_JMX_COUNT"

echo "--- LOCUST ---"
_LOCUST=0
which locust 2>/dev/null && _LOCUST=1
find . -name "locustfile.py" -o -name "locust*.py" ! -path "*/node_modules/*" 2>/dev/null | head -3 | grep -q '.' && _LOCUST=1
echo "LOCUST_PRESENT: $_LOCUST"

# Existing perf test files
echo "--- EXISTING PERF TESTS ---"
find . \( -name "*.k6.js" -o -name "*.k6.ts" -o -name "load-test*.js" \
  -o -name "locustfile.py" -o -name "*.jmx" -o -name "*perf*.spec.ts" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -10

# Detect route files to identify endpoints
echo "--- ENDPOINTS SAMPLE ---"
grep -r "router\.\(get\|post\|put\|patch\|delete\)" --include="*.ts" --include="*.js" \
  ! -path "*/node_modules/*" 2>/dev/null | grep -o '"[/][^"]*"' | sort -u | head -20
```

### Tool Selection Gate

Count detected tools from `K6_PRESENT`, `JMETER_PRESENT`, `LOCUST_PRESENT`.

**Exactly one detected** → use that tool automatically. Set `_PERF_TOOL` to `k6`,
`jmeter`, or `locust`.

**Zero detected** → ask:
> "No performance testing tool detected. Which would you like to use?
> 1. **k6** (recommended — JS-native, CI-friendly, Grafana ecosystem, fast feedback)
> 2. **JMeter** (best if you have existing .jmx plans or need a Java/GUI-based workflow)
> 3. **Locust** (ideal for Python teams — readable Python DSL, easy to extend)
>
> Recommendation: k6 for new projects; JMeter if .jmx files exist or Java CI is required;
> Locust for Python-heavy stacks."

**Two or more detected** → list which were found, ask which to use for this run.

## Phase 1 — Identify Test Targets

```bash
# OpenAPI endpoints
_SPEC=$(ls openapi.yaml openapi.json swagger.yaml swagger.json 2>/dev/null | head -1)
[ -n "$_SPEC" ] && cat "$_SPEC" | grep -E "^\s*(get|post|put|patch|delete):|^\s+/[a-z]" | head -30

# Find any SLA docs
find . -name "*.md" ! -path "*/node_modules/*" 2>/dev/null | \
  xargs grep -l "SLA\|latency\|throughput\|p95\|p99" 2>/dev/null | head -3
```

Build target list:
- Endpoint/URL, Method, Expected load pattern (spike, sustained, ramp-up)
- SLA target (p95 < Xms) if documented, Auth required, Priority

Default SLA profiles if no docs exist:
- API reads (GET): p95 < 200ms under 50 concurrent users
- API writes (POST/PUT): p95 < 500ms under 20 concurrent users
- Web pages: LCP < 2.5s (Core Web Vitals good threshold)

## Phase 2 — Load Tool Patterns & Generate Scripts

Read the tool-specific patterns file for the selected `_PERF_TOOL`:

```
Read qa-perf/tools/<_PERF_TOOL>.md
```

Also check the qa-refine reference guide if it exists:
- k6: `qa-perf/references/k6-patterns.md`
  - Patterns: test type taxonomy, scenarios/executors, thresholds + abortOnFail, check(),
    setup/teardown auth, custom metrics (Trend/Rate/Counter/Gauge), handleSummary,
    http.batch(), group(), browser module, gRPC, cookie jar, SharedArray, per-environment thresholds
  - 14 [community] gotchas including: duplicate threshold keys, abortOnFail timing, fd limits,
    closed-model explosive load, dropped_iterations, discardResponseBodies at scale
  - See also: `qa-perf/references/k6-patterns-baseline.md` (original baseline for comparison)
- JMeter: `qa-perf/references/jmeter-patterns.md`
- Locust: `qa-perf/references/locust-patterns.md`

Generate scripts covering all **critical** endpoints from Phase 1.
Read existing perf test files first — append missing scenarios, never overwrite.

## Phase 3 — Execute Tests

Dispatch to the correct runner based on `_PERF_TOOL` — the execute block is in
`qa-perf/tools/<_PERF_TOOL>.md`. Run it now.

## Phase 4 — Report

Write report to `$_TMP/qa-perf-report.md`:

```markdown
# QA Performance Report — <date>

## Summary
- **Status**: ✅ / ⚠️ / ❌
- All thresholds met: yes / no
- Tool: k6 / JMeter / Locust
- Target URL: <url>

## Results
| Endpoint | p50 | p95 | p99 | req/s | Errors | Pass |
|----------|-----|-----|-----|-------|--------|------|

## Threshold Violations
<list any metrics that exceeded SLA thresholds>

## Recommendations
<top bottlenecks + suggested optimizations>
```

## Important Rules

- **Never run against production** — always target localhost/staging; confirm URL before executing
- **Ramp-up before full load** — always use staged load profiles (ramp-up → sustain → ramp-down)
- **Auth in setup, not per iteration** — obtain tokens once to avoid auth endpoint overload
- **Conservative defaults** — default to 50 VUs/threads max; ask user before going above 200
- **Report even without execution** — if the tool is missing, document installation steps + the generated scripts
- **Cleanup after writes** — if any POST creates resources, add teardown logic to delete them
