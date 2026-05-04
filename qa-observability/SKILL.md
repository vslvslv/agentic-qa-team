---
name: qa-observability
preamble-tier: 3
version: 1.0.0
description: |
  Observability-driven failure RCA agent (BL-057). When any QA skill reports a
  failure, this agent runs a HolmesGPT-style root cause analysis loop: fetches
  the test's network requests, queries backend logs for the 30s window around
  the failure, retrieves OTel spans for the trace ID, and synthesizes a root
  cause statement. Appends a FAILURE_REASON block to the test report. Only
  activates when observability stack is configured (OTEL_EXPORTER_OTLP_ENDPOINT,
  LOKI_URL, JAEGER_URL, or TEMPO_URL). Works standalone or as a post-failure
  hook invoked by any qa-* skill. Use when asked to "rca", "root cause",
  "why did the test fail", "observability analysis", "trace failure", or
  "qa observability". (qa-agentic-team)
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
effort: medium
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
echo "BRANCH: $_BRANCH  DATE: $_DATE"

echo "--- OBSERVABILITY STACK ---"
_OTEL_AVAILABLE=0
[ -n "$OTEL_EXPORTER_OTLP_ENDPOINT" ] && _OTEL_AVAILABLE=1
echo "OTEL_ENDPOINT: ${OTEL_EXPORTER_OTLP_ENDPOINT:-not set}"

_JAEGER_URL="${JAEGER_URL:-}"
_TEMPO_URL="${TEMPO_URL:-}"
_LOKI_URL="${LOKI_URL:-}"

# Auto-detect common local endpoints
[ -z "$_JAEGER_URL" ] && \
  curl -s --max-time 2 http://localhost:16686/api/services >/dev/null 2>&1 && \
  _JAEGER_URL="http://localhost:16686"
[ -z "$_TEMPO_URL" ] && \
  curl -s --max-time 2 http://localhost:3200/ready >/dev/null 2>&1 && \
  _TEMPO_URL="http://localhost:3200"
[ -z "$_LOKI_URL" ] && \
  curl -s --max-time 2 http://localhost:3100/ready >/dev/null 2>&1 && \
  _LOKI_URL="http://localhost:3100"

echo "JAEGER_URL: ${_JAEGER_URL:-not configured}"
echo "TEMPO_URL: ${_TEMPO_URL:-not configured}"
echo "LOKI_URL: ${_LOKI_URL:-not configured}"

_OBS_AVAILABLE=0
[ -n "$_JAEGER_URL" ] || [ -n "$_TEMPO_URL" ] || [ -n "$_LOKI_URL" ] && _OBS_AVAILABLE=1
echo "OBS_AVAILABLE: $_OBS_AVAILABLE"

# Input context from failing skill
echo "--- FAILURE CONTEXT ---"
echo "FAILING_TEST: ${FAILING_TEST_NAME:-not provided}"
echo "TRACE_ID: ${TRACE_ID:-not provided}"
echo "FAILURE_TIMESTAMP: ${FAILURE_TIMESTAMP:-not provided}"
echo "FAILURE_MESSAGE: ${FAILURE_MESSAGE:-not provided}"
echo "--- DONE ---"
```

If `_OBS_AVAILABLE=0`:
- If called standalone: warn "No observability stack configured. Set JAEGER_URL, TEMPO_URL, or LOKI_URL."
- If called as a post-failure hook: emit `FAILURE_REASON: observability stack not configured — manual investigation required` and exit.

## Phase 1 — Acquire Trace and Logs

### Trace Retrieval

If `TRACE_ID` is provided, fetch the full distributed trace:

**Jaeger:**
```bash
if [ -n "$_JAEGER_URL" ] && [ -n "$TRACE_ID" ]; then
  curl -s "${_JAEGER_URL}/api/traces/${TRACE_ID}" \
    -o "$_TMP/qa-obs-trace.json" 2>/dev/null
  echo "JAEGER_TRACE_FETCHED: $([ -s "$_TMP/qa-obs-trace.json" ] && echo yes || echo no)"
fi
```

**Tempo:**
```bash
if [ -n "$_TEMPO_URL" ] && [ -n "$TRACE_ID" ]; then
  curl -s "${_TEMPO_URL}/api/traces/${TRACE_ID}" \
    -H "Accept: application/json" \
    -o "$_TMP/qa-obs-trace.json" 2>/dev/null
  echo "TEMPO_TRACE_FETCHED: $([ -s "$_TMP/qa-obs-trace.json" ] && echo yes || echo no)"
fi
```

### Log Retrieval (Loki)

Fetch logs for the 30-second window around the failure:

```bash
if [ -n "$_LOKI_URL" ] && [ -n "$FAILURE_TIMESTAMP" ]; then
  _TS_NS="${FAILURE_TIMESTAMP}000000000"  # seconds → nanoseconds
  _START_NS=$(( FAILURE_TIMESTAMP - 30 ))
  _END_NS=$(( FAILURE_TIMESTAMP + 30 ))
  curl -s "${_LOKI_URL}/loki/api/v1/query_range" \
    --data-urlencode 'query={job=~".+"}' \
    --data-urlencode "start=${_START_NS}000000000" \
    --data-urlencode "end=${_END_NS}000000000" \
    --data-urlencode "limit=200" \
    -o "$_TMP/qa-obs-logs.json" 2>/dev/null
  _LOG_LINES=$(python3 -c "
import json, os
d=json.load(open('$_TMP/qa-obs-logs.json'))
vals=[v[1] for r in d.get('data',{}).get('result',[]) for v in r.get('values',[])]
print(len(vals))" 2>/dev/null || echo 0)
  echo "LOKI_LOG_LINES: $_LOG_LINES"
fi
```

## Phase 2 — Analyze Trace

If `$_TMP/qa-obs-trace.json` was obtained, parse the span tree:

```bash
python3 - << 'PYEOF'
import json, os

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
trace_file = os.path.join(tmp, 'qa-obs-trace.json')
if not os.path.exists(trace_file):
    print("NO_TRACE"); exit()

data = json.load(open(trace_file))
spans = []

# Jaeger format
for trace in data.get('data', []):
    for span in trace.get('spans', []):
        err = any(t.get('key') == 'error' and t.get('value') for t in span.get('tags', []))
        dur = span.get('duration', 0)
        spans.append({
            'op': span.get('operationName', ''),
            'duration_ms': dur // 1000,
            'error': err,
            'service': span.get('processID', ''),
        })

# OTLP JSON format
for rs in data.get('resourceSpans', []):
    svc = next((a['value'].get('stringValue','') for a in
                rs.get('resource',{}).get('attributes',[])
                if a['key']=='service.name'), '')
    for ss in rs.get('scopeSpans', []):
        for span in ss.get('spans', []):
            dur = (int(span.get('endTimeUnixNano',0)) - int(span.get('startTimeUnixNano',0))) // 1_000_000
            err = span.get('status', {}).get('code', '') == 'STATUS_CODE_ERROR'
            spans.append({'op': span.get('name',''), 'duration_ms': dur, 'error': err, 'service': svc})

spans.sort(key=lambda s: s['duration_ms'], reverse=True)
print(f"TOTAL_SPANS: {len(spans)}")
print(f"ERROR_SPANS: {sum(1 for s in spans if s['error'])}")
print("TOP_SLOW (>100ms):")
for s in spans[:10]:
    flag = "❌" if s['error'] else "  "
    print(f"  {flag} {s['service']}/{s['op']} — {s['duration_ms']}ms")
PYEOF
```

**Claude analysis**: read `$_TMP/qa-obs-trace.json` and synthesize:
- Root span name and total duration
- First span with `error=true` → likely origin of failure
- Any span with duration > 1000ms → potential timeout
- Database spans (matching `db.*`, `postgres`, `mysql`, `redis`) with slow execution

## Phase 3 — Synthesize Root Cause

Compose a `FAILURE_REASON` block by combining:
1. Test failure message (`FAILURE_MESSAGE`)
2. First error span from trace analysis
3. Relevant log lines from Loki (filter for ERROR/WARN/Exception in the window)
4. Slow span candidates

**Output template**:
```
## Root Cause Analysis — <test name>

| Field | Detail |
|-------|--------|
| Test | <FAILING_TEST_NAME> |
| Trace ID | <TRACE_ID> |
| Root span | <op> — <duration>ms |
| First error span | <service>/<op> — <error message or status code> |
| Slow spans | <op>: <Nms> (>1000ms threshold) |
| Log evidence | <2-3 key log lines from the failure window> |
| Root cause | <1-sentence synthesis, e.g.: "The checkout test failed because inventory-service returned 503 (Redis connection pool exhausted 200ms before the test assertion)"> |
| Confidence | HIGH / MEDIUM / LOW |
| Recommended action | <specific next step: add DB connection pool config / check Redis maxmemory-policy / investigate N+1 in <service>> |
```

**Confidence scoring**:
- HIGH: error span found AND log evidence corroborates AND root cause is deterministic
- MEDIUM: error span found OR log evidence found, but not both
- LOW: no trace/logs available — analysis based on test message only

## Phase 4 — Append to Test Report

Write `FAILURE_REASON` block to the failing skill's report file.
If invoked as a hook, the report path is `$FAILING_REPORT_PATH`; otherwise write to `$_TMP/qa-obs-rca.md`.

```bash
_REPORT_PATH="${FAILING_REPORT_PATH:-$_TMP/qa-obs-rca.md}"
```

Also write `$_TMP/qa-obs-ctrf.json` with one CTRF test:
- `name`: `"RCA: ${FAILING_TEST_NAME}"`
- `status`: `"passed"` if confidence is HIGH or MEDIUM, `"failed"` if LOW (insufficient data)
- `message`: the root cause 1-sentence synthesis

## Important Rules

- **Never expose secrets** — do not log full auth headers, tokens, or passwords from traces/logs
- **30s window only** — Loki queries are bounded to ±30s around failure; don't pull full run logs
- **Graceful degradation** — if observability stack is unreachable, emit LOW-confidence analysis from test message alone
- **One RCA per call** — designed to analyze one failing test at a time; loop callers must invoke once per test
- **No remediation** — this skill reports causes; it does not modify code or tests (that's `qa-heal`)

## Agent Memory

After each run, update `.claude/agent-memory/qa-observability/MEMORY.md` (create if absent). Record:
- Observability stack URLs confirmed working
- Recurring failure patterns with their root causes
- Services that frequently appear as root span sources
- Log query patterns that proved most useful
