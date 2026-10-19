---
name: qa-perf
version: 1.0.0
description: |
  Performance test agent. Identifies critical user journeys and API endpoints,
  generates load test scripts for the detected tool (k6, JMeter, or Locust),
  executes them, and analyzes throughput, latency percentiles, and error rates.
  Works standalone or as a sub-agent of /qa-team
when_to_use: |
  Use when asked to "qa performance",
  "load test", "stress test", "performance testing", "k6", "jmeter", "locust",
  "benchmark the api", or "perf test agent".
paths:
  - "**/k6/**"
  - "**/jmeter/**"
  - "**/locust/**"
  - "**/load-test*/**"
  - "*.k6.js"
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
          command: 'bash "$HOME/.claude/qa-agentic-team/bin/hooks/qa-pre-bash-safety.sh"'
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'bash "$HOME/.claude/qa-agentic-team/bin/hooks/qa-post-write-typecheck.sh"'
          async: true
---

## Version check

!`bash "${CLAUDE_SKILL_DIR}/../bin/qa-version-check-inline.sh" 2>/dev/null || echo "VERSION_STATUS: UPDATE_CHECK_FAILED"`

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `SKIP_UPDATE_ASK` is `0`, use `AskUserQuestion`: "qa-agentic-team update available. Update before running?" Options: "Yes — update now (recommended)" | "No — run with current version". If yes: first show what would change with `git -C "$HOME/.claude/qa-agentic-team" fetch -q && git -C "$HOME/.claude/qa-agentic-team" log --oneline HEAD..@{u} | head -20`, then run `git -C "$HOME/.claude/qa-agentic-team" pull --ff-only && bash "$HOME/.claude/qa-agentic-team/bin/setup" --no-hook`. Continue regardless.

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

```bash
# LitmusChaos detection (BL-039)
_LITMUS_AVAILABLE=0
command -v litmusctl >/dev/null 2>&1 && _LITMUS_AVAILABLE=1
kubectl get namespace litmus >/dev/null 2>&1 && _LITMUS_AVAILABLE=1
echo "LITMUS_AVAILABLE: $_LITMUS_AVAILABLE"

# Bencher detection (BL-040)
_BENCHER_AVAILABLE=0
command -v bencher >/dev/null 2>&1 && _BENCHER_AVAILABLE=1
[ -n "$BENCHER_API_TOKEN" ] && _BENCHER_AVAILABLE=1
echo "BENCHER_AVAILABLE: $_BENCHER_AVAILABLE"

# GoReplay detection (BL-041)
_GOREPLAY_AVAILABLE=0
command -v gor >/dev/null 2>&1 && _GOREPLAY_AVAILABLE=1
[ -f "requests.gor" ] && _GOREPLAY_REPLAY_READY=1 || _GOREPLAY_REPLAY_READY=0
echo "GOREPLAY_AVAILABLE: $_GOREPLAY_AVAILABLE"
echo "GOREPLAY_REPLAY_READY: $_GOREPLAY_REPLAY_READY"
```

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

Read the tool-specific patterns file for the selected `_PERF_TOOL` (short, read it whole):

```
Read ${CLAUDE_SKILL_DIR}/tools/<_PERF_TOOL>.md
```

Also consult the detailed reference guide for the tool (listed below). Guides are long (up to
~3,000 lines) — do NOT read a whole guide. First list its section headings, then Read only the
sections relevant to the test types and protocols in scope (for example executors, thresholds, auth,
WebSocket/gRPC), using the Read tool's `offset`/`limit` taken from the heading line numbers:

```bash
_GUIDE="${CLAUDE_SKILL_DIR}/references/<guide-file>.md"   # <guide-file> = file named in the Reference link
ls "$_GUIDE" && grep -nE '^#{2,3} ' "$_GUIDE"            # prints the absolute path to pass to Read, then the headings
```

If the guide is missing, continue with the key patterns listed below.

**k6**:
> Reference: [k6 patterns guide](references/k6-patterns.md)
> Key patterns: test type taxonomy · scenarios/executors (`ramping-vus`, `constant-arrival-rate`, `ramping-arrival-rate`) · thresholds + `abortOnFail` · `check()` · `setup()`/`teardown()` auth · custom metrics (Trend/Rate/Counter/Gauge) · `handleSummary` (JUnit/JSON/HTML) · `http.batch()` · `group()` · browser module · gRPC · WebSocket · GraphQL (200-response error detection) · SharedArray · CSV data · per-environment thresholds · `http.setResponseCallback` for custom failure definitions · secrets via environment, never hard-coded

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
These phases send real load: run the target classification and **TARGET gate from Phase 3** first.

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

Before any load leaves the machine, classify the target host (the URL the scripts hit —
`$_API_URL`, or `$_WEB_URL` for browser-module scenarios):

```bash
_PERF_TARGET="$_API_URL"   # or "$_WEB_URL" when the scripts drive the web app
_PERF_HOST=$(echo "$_PERF_TARGET" | sed -E 's#^[a-zA-Z]+://(\[[^]]+\]|[^/:]+).*#\1#')
case "$_PERF_HOST" in
  localhost|127.0.0.1|0.0.0.0|"[::1]"|host.docker.internal) _TARGET_IS_LOCAL=1 ;;
  *) _TARGET_IS_LOCAL=0 ;;
esac
echo "PERF_TARGET: $_PERF_TARGET  TARGET_IS_LOCAL: $_TARGET_IS_LOCAL"
```

**Gate (TARGET=$_PERF_TARGET)** — applies when `TARGET_IS_LOCAL=0`: a load test against a remote
host can degrade or take down a shared environment. Interactive: confirm with `AskUserQuestion` —
"Load-test `$_PERF_TARGET` (peak N VUs, duration D)? Never production." Options: "Yes — this is a
staging/dev target I may load" | "No — enter a different target / cancel"; proceed only on yes. As a
subagent: proceed only if the brief's `APPROVALS:` line contains `TARGET=$_PERF_TARGET` (exact
match); otherwise do not execute — keep the generated scripts, and list the target under "Needs a
decision". Scenarios that send POST/PUT/PATCH/DELETE to a remote target additionally need
`ALLOW_FORM_SUBMIT` (same ask/APPROVALS rule); without it, run only the read-only scenarios.
Local targets (`TARGET_IS_LOCAL=1`) run without this gate.

Dispatch to the correct runner based on `_PERF_TOOL` — the execute block is in
`${CLAUDE_SKILL_DIR}/tools/<_PERF_TOOL>.md`. Run it now.

## Phase 3.5 — Chaos Resilience (BL-039) + Production Traffic Replay (BL-041)

### LitmusChaos Concurrent Resilience Testing (BL-039)

Skip if `QA_CHAOS!=1` OR `_LITMUS_AVAILABLE=0`.

**Gate (ALLOW_ACTIVE_SCAN):** the experiment deletes pods in a live Kubernetes cluster. Before
asking, show the target: `kubectl config current-context`, and the ChaosEngine's `appns` and
`applabel` (fill both from the detected k8s labels — never leave the `default` placeholder). It must
be a disposable dev/staging cluster, never production. Interactive: ask with `AskUserQuestion` —
"Run pod-delete chaos in context `<context>`, namespace `<appns>`, label `<applabel>`?" Options:
"Yes — disposable cluster" | "No — skip chaos"; proceed only on yes. As a subagent: proceed only if
the brief's `APPROVALS:` line contains `ALLOW_ACTIVE_SCAN` (in addition to `QA_CHAOS=1`); otherwise
skip this section and list it — with the context/namespace — under "Needs a decision". The
concurrent load run is also subject to the Phase 3 TARGET gate.

```bash
if [ "${QA_CHAOS:-0}" = "1" ] && [ "$_LITMUS_AVAILABLE" = "1" ]; then
  # Claude auto-generates ChaosEngine YAML from k6 thresholds
  _K6_THRESHOLDS=$(grep -r "thresholds:" --include="*.js" --include="*.ts" \
    ! -path "*/node_modules/*" 2>/dev/null | head -5)
  echo "CHAOS_HYPOTHESIS: derived from thresholds: $_K6_THRESHOLDS"
fi
```

**ChaosEngine template** (generated from k6 thresholds):
```yaml
# generated: qa-perf/litmus-chaos-engine.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: qa-perf-chaos
spec:
  appinfo:
    appns: default
    applabel: "app=<detected from k8s labels>"
  engineState: active
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: CHAOS_INTERVAL
              value: "10"
            - name: FORCE
              value: "false"
```

**Concurrent execution**: run LitmusChaos experiment AND k6 load test simultaneously:
1. `litmusctl run chaosengine -f qa-perf/litmus-chaos-engine.yaml &`
2. `k6 run <test-script.js>` (with same thresholds as baseline run)
3. Compare: did system hold SLO thresholds during chaos?

**Report**: boundary thresholds for each fault type, e.g.
"p99 held at 30% pod kill (494ms vs 450ms baseline), breached at 50% pod kill (820ms)."

### GoReplay Production Traffic Replay (BL-041)

Skip if `QA_REPLAY_MODE!=1`.

**Capture** records real production traffic (it may contain personal data and credentials) on the
host it runs on. Interactive only: ask with `AskUserQuestion` before starting it. As a subagent: never
capture — list it under "Needs a decision".

**Gate (TARGET=$_API_URL) for replay:** replay sends the recorded production requests, writes
included, to `$_API_URL` — staging/dev only, never production. Interactive: confirm the exact URL with
`AskUserQuestion` — "Replay `requests.gor` against `$_API_URL`? Recorded writes (POST/PUT/PATCH/DELETE)
will be re-sent." Options: "Yes — staging/dev target" | "No — cancel"; proceed only on yes. As a
subagent: proceed only if the brief's `APPROVALS:` line contains `TARGET=$_API_URL` (exact match) and
`ALLOW_FORM_SUBMIT`; otherwise skip replay and list it under "Needs a decision".

**Capture mode** (run once on production):
```bash
if [ "${QA_REPLAY_MODE:-0}" = "1" ] && [ "$_GOREPLAY_AVAILABLE" = "1" ]; then
  if [ "${QA_GOREPLAY_CAPTURE:-0}" = "1" ]; then
    echo "GOREPLAY_CAPTURE: capturing traffic from $_API_URL"
    gor --input-raw ":80" --output-file requests.gor --exit-after 60s &
    echo "GOREPLAY_CAPTURE_PID: $!"
  elif [ "$_GOREPLAY_REPLAY_READY" = "1" ]; then
    echo "GOREPLAY_REPLAY: replaying requests.gor against $_API_URL"
    gor --input-file requests.gor --output-http "$_API_URL" \
      --stats --output-http-stats \
      2>&1 | tee "$_TMP/qa-perf-goreplay.txt"
    echo "GOREPLAY_EXIT: $?"
  fi
fi
```

**Analysis** (after replay): compare baseline vs replay per endpoint:
- Claude prompt: "Compare baseline vs replay results from `$_TMP/qa-perf-goreplay.txt`.
  Identify endpoints with p95 regression >10%. Summarize likely root causes."

In Phase 4 report, add `### Production Traffic Replay (GoReplay)` section:
```
| Endpoint | Baseline p99 | Replay p99 | Delta | Verdict |
|----------|-------------|------------|-------|---------|
```

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

- **Never run against production** — always target localhost/staging; remote targets go through the Phase 3 TARGET gate
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

## Phase 4.6 — Bencher Continuous Benchmarking (BL-040)

Skip if `_BENCHER_AVAILABLE=0`. Pushes k6 summary to Bencher's trend store and generates
a narrative from the historical data.

```bash
if [ "$_BENCHER_AVAILABLE" = "1" ]; then
  _K6_SUMMARY=$(ls "$_TMP"/qa-perf-*.json 2>/dev/null | head -1)
  if [ -n "$_K6_SUMMARY" ] && [ -n "$BENCHER_API_TOKEN" ]; then
    bencher run \
      --project "${BENCHER_PROJECT:-qa-perf}" \
      --token "$BENCHER_API_TOKEN" \
      --adapter json \
      --file "$_K6_SUMMARY" \
      2>&1 | tee "$_TMP/qa-perf-bencher.txt"
    echo "BENCHER_EXIT: $?"
    # Fetch trend history for narrative
    bencher metric list \
      --project "${BENCHER_PROJECT:-qa-perf}" \
      --token "$BENCHER_API_TOKEN" \
      --per-page 30 \
      2>&1 | tee "$_TMP/qa-perf-bencher-history.txt"
  fi
fi
```

If `$_TMP/qa-perf-bencher-history.txt` obtained, generate a trend narrative:
- Claude prompt: "Here is 30 runs of performance data for this project. Write a 1-paragraph
  narrative identifying: (1) which endpoint's p95 has the largest drift over time, (2) whether
  the regression is gradual or spike-shaped, (3) which git SHA was the inflection point if visible,
  (4) what profiling step would you recommend next."

In Phase 4 report, add `### Bencher Trend Analysis` section with the narrative paragraph and a
threshold violation summary table:
```
| Metric | Baseline (run 1) | Current | Drift | Trend |
|--------|-----------------|---------|-------|-------|
| p95 GET /api/checkout | 120ms | 164ms | +37% | ↑ gradual |
```

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
