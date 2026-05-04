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

# Detect base URLs
_API_URL=$(grep -r "API_URL\|apiUrl\|BASE_URL" .env .env.local .env.test 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
# .NET: launchSettings.json / appsettings.json
[ -z "$_API_URL" ] && _API_URL=$(
  find . -name "launchSettings.json" ! -path "*/obj/*" 2>/dev/null | head -1 | \
  xargs grep -o '"applicationUrl"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | \
  grep -o 'http[s]*://[^;",]*' | head -1)
_API_URL="${_API_URL:-http://localhost:3001}"
_WEB_URL="${WEB_URL:-http://localhost:3000}"
echo "API_URL: $_API_URL"
echo "WEB_URL: $_WEB_URL"

# Check API/web liveness
for url in "$_API_URL" "$_WEB_URL"; do
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
  echo "HEALTH $url: $status"
done

# Target language detection
_TARGET_LANG="typescript"
find . -name "pom.xml" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && _TARGET_LANG="java"
find . \( -name "requirements.txt" -o -name "pyproject.toml" \) \
  ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && _TARGET_LANG="python"
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | grep -q '.' && _TARGET_LANG="csharp"
echo "TARGET_LANG: $_TARGET_LANG"

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

echo "--- NBOMBER ---"
_NBOMBER=0
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -il "NBomber" 2>/dev/null | grep -q '.' && _NBOMBER=1
echo "NBOMBER_PRESENT: $_NBOMBER"

echo "--- ARTILLERY ---"
_ARTILLERY=0
{ ls artillery.yml artillery.yaml 2>/dev/null | grep -q '.' || \
  find . \( -name "*.artillery.yml" -o -name "*.artillery.yaml" \) \
    ! -path "*/node_modules/*" 2>/dev/null | grep -q .; } && \
  grep -q '"artillery"' package.json 2>/dev/null && _ARTILLERY=1
echo "ARTILLERY_PRESENT: $_ARTILLERY"

# Existing perf test files
echo "--- EXISTING PERF TESTS ---"
find . \( -name "*.k6.js" -o -name "*.k6.ts" -o -name "load-test*.js" \
  -o -name "locustfile.py" -o -name "*.jmx" -o -name "*perf*.spec.ts" \
  -o -name "*LoadTest*.cs" -o -name "*PerfTest*.cs" \) \
  ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | head -10

# Detect route files to identify endpoints
echo "--- ENDPOINTS SAMPLE ---"
grep -r "router\.\(get\|post\|put\|patch\|delete\)" --include="*.ts" --include="*.js" \
  ! -path "*/node_modules/*" 2>/dev/null | grep -o '"[/][^"]*"' | sort -u | head -20
# C# Controllers
find . -path "*/Controllers/*.cs" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -h "\[HttpGet\]\|\[HttpPost\]\|\[Route\]" 2>/dev/null | \
  grep -o '"[^"]*"' | sort -u | head -20

# --- MULTI-REPO SUPPORT ---
# Set QA_EXTRA_PATHS (space-separated absolute paths) to scan perf tests in other repos
# e.g.: export QA_EXTRA_PATHS="/path/to/perf-tests-repo"
if [ -n "$QA_EXTRA_PATHS" ]; then
  echo "MULTI_REPO_PATHS: $QA_EXTRA_PATHS"
  for _qr in $QA_EXTRA_PATHS; do
    _extra=$(find "$_qr" \( \
      -name "*.k6.js" -o -name "*.k6.ts" -o -name "*.jmx" \
      -o -name "locustfile.py" -o -name "*LoadTest*.cs" -o -name "*PerfTest*.cs" \) \
      ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | wc -l | tr -d ' ')
    echo "EXTRA_REPO $(basename "$_qr"): $_extra perf test files — $_qr"
  done
fi
```

If `MULTI_REPO_PATHS` output appeared: when sampling test files in subsequent phases, include files from those extra paths. All sub-agents inherit `QA_EXTRA_PATHS` automatically via the environment. Language detection uses CWD (the main application repository).

### Tool Selection Gate

Count detected tools from `K6_PRESENT`, `JMETER_PRESENT`, `LOCUST_PRESENT`, `NBOMBER_PRESENT`, `ARTILLERY_PRESENT`.

**Exactly one detected** → use that tool automatically. Set `_PERF_TOOL` to `k6`,
`jmeter`, `locust`, `nbomber`, or `artillery`.

**Zero detected** → if `_TARGET_LANG=csharp`, recommend NBomber first; otherwise ask:
> "No performance testing tool detected. Which would you like to use?
> 1. **k6** (recommended for JS/TS — CI-friendly, Grafana ecosystem, fast feedback)
> 2. **NBomber** (recommended for C# — native .NET, integrates with NUnit/xUnit, fluent API) ← suggest first if `_TARGET_LANG=csharp`
> 3. **Artillery** (JS/YAML-based, good for progressive load profiles and HTTP/WebSocket)
> 4. **JMeter** (best if you have existing .jmx plans or need a Java/GUI-based workflow)
> 5. **Locust** (ideal for Python teams — readable Python DSL, easy to extend)
>
> Recommendation: k6 for JS/TS stacks; NBomber for .NET/C# stacks; Artillery for JS teams wanting YAML configs; JMeter if .jmx files exist or Java CI is required; Locust for Python-heavy stacks."

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

Also check the detailed reference guide:

**k6**:
> Reference: [k6 patterns guide](references/k6-patterns.md)
> Key patterns: test type taxonomy · scenarios/executors (`ramping-vus`, `constant-arrival-rate`, `ramping-arrival-rate`) · thresholds + `abortOnFail` · `check()` · `setup()`/`teardown()` auth · custom metrics (Trend/Rate/Counter/Gauge) · `handleSummary` (JUnit/JSON/HTML) · `http.batch()` · `group()` · browser module (getBy* locators, CPU/network throttling, `waitForEvent`, locator filtering, `page.on('requestfailed'/'requestfinished')` sub-resource events) · gRPC (unary + streaming + metadata Bearer auth + connection reuse) · WebSocket (stable `k6/websockets` module, multiple concurrent connections per VU) · GraphQL (200-response error detection) · HMAC signing (`k6/crypto` deprecated → use `crypto.subtle` WebCrypto + PBKDF2) · secrets management (`k6/secrets`, `K6_SECRET_SOURCE` env var) · MFA/TOTP auth · distributed tracing (`http-instrumentation-tempo`) · SharedArray · CSV data with papaparse · per-environment thresholds · `http.setResponseCallback` for custom failure definitions · error codes (1000-1699 ranges) · `exec.vu.metrics.tags` for dynamic per-VU tagging · `K6_WEB_DASHBOARD` built-in real-time UI · `K6_DEPENDENCY_MANIFEST` for extension version pinning · `--new-machine-readable-summary` flag · `xk6-kv` for cross-VU shared mutable state · `k6 x mcp` AI-assisted script writing · `options.dns` / `K6_DNS` for load-balanced backend DNS · `K6_LOG_OUTPUT` Loki log routing · `K6_NO_THRESHOLDS` dry runs · GitLab CI + Docker k6 patterns · `summaryTrendStats` + `K6_COMPATIBILITY_MODE` · OS tuning (Linux + macOS) · k6 v2.0.0 migration (removed: `externally-controlled`, `--no-summary`, `options.ext.loadimpact`, `browser_web_vital_fid`; `--stack` now mandatory for cloud; new exit code 97 for cloud aborts)
> See also: `qa-perf/references/k6-patterns-baseline.md` (original baseline for comparison)

**NBomber** (C# native — use when `_TARGET_LANG=csharp`):
> Reference: [NBomber patterns guide (C#)](references/nbomber-patterns.md)
> Key patterns: `Scenario.Create` + `Http.CreateRequest` · `LoadSimulations` (`RampingInject`, `Inject`, `KeepConstant`, `RampingVUsers`) · `WithWarmUpDuration` · `WithThresholds` (fail on p95/error-rate) · `NBomberRunner` + `WithReportFolder` (HTML/CSV/JSON) · auth token in scenario init · `DataFeed` for parameterized data · `IStepContext` custom logging · NUnit/xUnit integration via `NBomberRunner.Run()`

**JMeter**:
> Reference: [JMeter patterns guide](references/jmeter-patterns.md)
> Key patterns: Thread Group · HTTP Request Sampler · CSV Data Set Config · Response Assertion · Constant Timer · non-GUI mode (`-n`) · parameterization · CI integration

**Locust**:
> Reference: [Locust patterns guide](references/locust-patterns.md)
> Key patterns: `HttpUser` · task weights · `@task` decorator · wait time strategies · `on_start` auth · environment params · headless CI mode · custom stats

Generate scripts covering all **critical** endpoints from Phase 1.
Read existing perf test files first — append missing scenarios, never overwrite.

## Phase 2.5 — Artillery Adaptive Phase Sequencing

Only runs when Artillery is detected (`_PERF_TOOL` contains `artillery`). Skip otherwise.
Uses 3-phase escalating approach: smoke → baseline → soak.
Each phase only runs if the previous phase passes all thresholds.

**Phase A — Smoke (10 arrivals, 30s)**

```bash
_ART_CONFIG=$(ls artillery.yml artillery.yaml 2>/dev/null | head -1)
if [ -n "$_ART_CONFIG" ] && echo "$_PERF_TOOL" | grep -q "artillery"; then
  npx artillery run "$_ART_CONFIG" \
    --overrides '{"config":{"phases":[{"duration":30,"arrivalCount":10}]}}' \
    --output "$_TMP/artillery-smoke.json" 2>&1 | tail -20
fi
```

Parse `$_TMP/artillery-smoke.json`: if p99 > 2000ms or error rate > 1% → **STOP, report smoke failure**.

**Phase B — Baseline (target concurrency, 2 min)**

```bash
if [ -n "$_ART_CONFIG" ] && echo "$_PERF_TOOL" | grep -q "artillery"; then
  npx artillery run "$_ART_CONFIG" \
    --output "$_TMP/artillery-baseline.json" 2>&1 | tail -30
fi
```

Parse `$_TMP/artillery-baseline.json`: if p99 > 4× smoke p99 or error rate > 5% → **STOP, report regression**.

**Phase C — Soak (target concurrency, 10 min)** — only if `QA_SOAK=1` env var set

```bash
if [ -n "$_ART_CONFIG" ] && echo "$_PERF_TOOL" | grep -q "artillery" && [ "${QA_SOAK:-0}" = "1" ]; then
  npx artillery run "$_ART_CONFIG" \
    --overrides '{"config":{"phases":[{"duration":600,"arrivalRate":10}]}}' \
    --output "$_TMP/artillery-soak.json" 2>&1 | tail -30
fi
```

Check for memory leak signal: p99 at minute 9 > 2× p99 at minute 1 → flag `[MEMORY LEAK SUSPECTED]`.

Collect all phase results for Phase 4 report under `### Artillery Phase Results` section.

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

## Diagnosis
*(Complete this section when any threshold is violated, before listing individual violations.)*
| Field | Detail |
|-------|--------|
| What violated | <metric name(s) and threshold(s) exceeded — e.g., p95 > 200ms on GET /api/users> |
| Observed value | <actual p95/p99/error-rate measured during the run> |
| Load at violation | <VUs / RPS at the moment the threshold was crossed> |
| Likely root cause | <DB query slow / N+1 / missing index / connection pool exhausted / GC pause / cold start> |
| Pre-existing? | yes — baseline run showed same violation / no — regression introduced this session |

When any threshold violation exists, the **Diagnosis** section is mandatory — complete it before listing individual violations. Never skip straight to the violation list.

## Threshold Violations
<list any metrics that exceeded SLA thresholds>

## Recommendations
<top bottlenecks + suggested optimizations>

### SLO Compliance

If k6 `thresholds` block found, generate Sloth-compatible SLO YAML:

```bash
_K6_THRESHOLDS=$(grep -A 20 'thresholds:' k6/ -r 2>/dev/null | head -30)
```

For each threshold (e.g., `http_req_duration: ['p(99)<500']`):
- Map to SLO: `objective: 99.9`, `description: "p99 latency < 500ms"`
- Compute error budget burn rate from observed error rate in test run
- Write `$_TMP/qa-slo.yaml` in Sloth format

| SLO | Objective | Observed | Status | Error Budget Remaining |
|-----|-----------|----------|--------|----------------------|
```

## Important Rules

- **Never run against production** — always target localhost/staging; confirm URL before executing
- **Ramp-up before full load** — always use staged load profiles (ramp-up → sustain → ramp-down)
- **Auth in setup, not per iteration** — obtain tokens once to avoid auth endpoint overload
- **Conservative defaults** — default to 50 VUs/threads max; ask user before going above 200
- **Report even without execution** — if the tool is missing, document installation steps + the generated scripts
- **Cleanup after writes** — if any POST creates resources, add teardown logic to delete them

## Phase 4.5 — Pyroscope Flamegraph Diff

Skip if `PYROSCOPE_URL` env var is not set.

```bash
if [ -n "$PYROSCOPE_URL" ]; then
  _NOW=$(date +%s)
  _ONE_HOUR_AGO=$((_NOW - 3600))
  curl -s "${PYROSCOPE_URL}/render?query=process_cpu:cpu:nanoseconds:cpu:nanoseconds\
&from=${_ONE_HOUR_AGO}&until=${_NOW}&format=json" \
    -o "$_TMP/pyroscope-profile.json" 2>/dev/null || echo "PYROSCOPE_UNAVAILABLE"
fi
```

If `$_TMP/pyroscope-profile.json` obtained, analyze it and generate 3-bullet insight to add to Phase 4 report under `### Flamegraph Insights`:
1. **Hottest function**: name and % CPU time during load
2. **Regression vs idle**: functions consuming >3× more CPU under load vs idle
3. **Recommendation**: specific optimization suggestion (e.g., "add DB connection pooling", "cache result of X")

## CTRF Output

After writing the report, write `$_TMP/qa-perf-ctrf.json`. Each configured threshold = one CTRF test
(passed if met, failed if violated):

```python
python3 - << 'PYEOF'
import json, os, time, re

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
report_path = os.path.join(tmp, 'qa-perf-report.md')
output_file = os.path.join(tmp, 'qa-perf-runner-output.txt')

report = open(report_path, encoding='utf-8', errors='replace').read() \
         if os.path.exists(report_path) else ''
output = open(output_file, encoding='utf-8', errors='replace').read() \
         if os.path.exists(output_file) else ''

tests = []

# Parse threshold results from report or output
# k6 threshold lines look like:  ✓ http_req_duration............: avg=145ms p95<500ms
# Or: ✗ http_req_failed..............: 2.30% > 0%
for line in (report + output).splitlines():
    m_pass = re.match(r'\s*[✓✅]\s+(.+?)\s*[:=]', line)
    m_fail = re.match(r'\s*[✗✕×❌]\s+(.+?)\s*[:=]', line)
    if m_pass:
        tests.append({'name': m_pass.group(1).strip(), 'status': 'passed', 'duration': 0, 'suite': 'performance'})
    elif m_fail:
        tests.append({'name': m_fail.group(1).strip(), 'status': 'failed', 'duration': 0, 'suite': 'performance',
                      'message': f'Threshold violated — see qa-perf-report.md'})

# Fallback if no threshold lines found
if not tests:
    violations = len(re.findall(r'THRESHOLD.*FAILED|exceeded|violated', output, re.IGNORECASE))
    status = 'failed' if violations else 'passed'
    tests.append({'name': 'performance thresholds', 'status': status, 'duration': 0, 'suite': 'performance',
                  'message': f'{violations} threshold violation(s)' if violations else ''})

p = sum(1 for t in tests if t['status'] == 'passed')
f = sum(1 for t in tests if t['status'] == 'failed')
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': os.environ.get('_PERF_TOOL', 'k6')},
        'summary': {
            'tests': len(tests), 'passed': p, 'failed': f,
            'pending': 0, 'skipped': 0, 'other': 0,
            'start': now_ms - 30000, 'stop': now_ms,
        },
        'tests': tests,
        'environment': {
            'reportName': 'qa-perf',
            'baseUrl': os.environ.get('_BASE_URL', 'unknown'),
        },
    }
}

out = os.path.join(tmp, 'qa-perf-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  tests={len(tests)} passed={p} failed={f}')
PYEOF
```

## Agent Memory

After each run, update the memory file at `.claude/agent-memory/qa-perf/MEMORY.md` (create if absent). Record:
- Detected framework, version, and config file paths
- Auth endpoint and credential format used
- Recurring failures or known flaky scenarios
- Base URL confirmed working
- Any test infrastructure quirks discovered

Read this file at the start of each run to skip re-detection of already-known facts.
