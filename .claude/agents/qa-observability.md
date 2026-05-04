---
name: qa-observability
description: |
  Observability-driven failure RCA agent (BL-057). Runs a HolmesGPT-style root
  cause analysis loop when any QA skill reports a failure: fetches OTel traces
  from Jaeger/Tempo, queries Loki logs for the 30s failure window, synthesizes
  a root cause statement, and appends FAILURE_REASON to the test report.
  Only activates when OTEL_EXPORTER_OTLP_ENDPOINT, JAEGER_URL, TEMPO_URL,
  or LOKI_URL is configured. Input env vars: FAILING_TEST_NAME, TRACE_ID,
  FAILURE_TIMESTAMP (unix seconds), FAILURE_MESSAGE, FAILING_REPORT_PATH.
model: sonnet
memory: project
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
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

echo "--- FAILURE CONTEXT ---"
echo "FAILING_TEST: ${FAILING_TEST_NAME:-not provided}"
echo "TRACE_ID: ${TRACE_ID:-not provided}"
echo "FAILURE_TIMESTAMP: ${FAILURE_TIMESTAMP:-not provided}"
echo "FAILURE_MESSAGE: ${FAILURE_MESSAGE:-not provided}"
echo "--- DONE ---"
```

If `_OBS_AVAILABLE=0`: emit `FAILURE_REASON: observability stack not configured — manual investigation required` and exit.

## Phase 1 — Acquire Trace and Logs

Fetch distributed trace from Jaeger or Tempo using `TRACE_ID`. Query Loki for logs in the ±30s window around `FAILURE_TIMESTAMP`.

## Phase 2 — Analyze Trace

Parse span tree from fetched trace JSON. Identify: root span, first error span, slow spans (>100ms), DB spans. Use Python script to extract span summary.

## Phase 3 — Synthesize Root Cause

Compose `FAILURE_REASON` block:
- Root span, first error span, slow spans, log evidence
- 1-sentence root cause synthesis
- Confidence: HIGH (trace + logs), MEDIUM (one source), LOW (message only)
- Recommended next action

## Phase 4 — Append to Report

Write `FAILURE_REASON` block to `$FAILING_REPORT_PATH` (or `$_TMP/qa-obs-rca.md`).
Write `$_TMP/qa-obs-ctrf.json` with one CTRF test: status=passed if HIGH/MEDIUM, failed if LOW.

## Important Rules

- Never expose secrets from traces/logs
- 30s log window only — don't pull full run logs
- Graceful degradation when observability stack unreachable
- One RCA per invocation — loop callers invoke once per test
- No code remediation — report causes only; remediation is `qa-heal`'s job
