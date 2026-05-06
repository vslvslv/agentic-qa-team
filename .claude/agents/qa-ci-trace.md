---
name: qa-ci-trace
description: |
  CI build intelligence from OTel traces. Analyzes build trace data emitted by Honeycomb
  buildevents or an OTLP backend to identify the slowest test stages, flappy infrastructure
  steps, parallelism opportunities, and recurring failure patterns across recent runs.
  Produces an actionable CI optimization report.
  Env vars: BUILDEVENTS_APIKEY, CI_TRACE_LOOKBACK, HONEYCOMB_DATASET.
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
  - WebFetch
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
echo "--- DETECTION ---"

_LOOKBACK="${CI_TRACE_LOOKBACK:-10}"
[ -n "$BUILDEVENTS_APIKEY" ] && echo "HONEYCOMB_AVAILABLE: 1" || echo "HONEYCOMB_AVAILABLE: 0"
[ -n "$OTEL_EXPORTER_OTLP_ENDPOINT" ] && echo "OTLP_ENDPOINT: $OTEL_EXPORTER_OTLP_ENDPOINT" || echo "OTLP_ENDPOINT: (not set)"
[ -n "$GITHUB_RUN_ID" ] && echo "CI_PROVIDER: github-actions" || true
[ -n "$BUILDKITE_BUILD_ID" ] && echo "CI_PROVIDER: buildkite" || true
_LOCAL_TRACES=$(find . -name "*.otlp.json" -o -name "buildevents-*.json" -o -name "trace-*.json" 2>/dev/null | head -5 | tr '\n' ' ')
echo "LOCAL_TRACE_FILES: ${_LOCAL_TRACES:-(none)}"
echo "CI_TRACE_LOOKBACK: $_LOOKBACK runs"
echo "--- DONE ---"
```

If no trace backend and no local files: use AskUserQuestion to explain requirements.

## Phase 1 — Fetch Build Traces

**Honeycomb**: WebFetch Honeycomb API for last `$_LOOKBACK` builds from `$HONEYCOMB_DATASET`.
**GitHub Actions**: `gh run list --limit $_LOOKBACK --json databaseId,name,conclusion,startedAt,updatedAt`
**Local files**: Read each `$_LOCAL_TRACES` file; extract span names, durations, status, parent IDs.

Save normalized trace data to `$_TMP/qa-ci-traces-normalized.json`.

## Phase 2 — LLM Analysis

Analyze normalized traces for:
1. **Slowest steps (P95)**: steps > 2 minutes; rank by p95 duration
2. **High-failure-rate steps**: failing > 20% of runs; categorize by cause
3. **Sequential bottlenecks**: spans always sequential but parallelizable (no data dependency)
4. **Cache inefficiency**: dependency download steps despite unchanged lockfiles

## Phase N — Report

Write `$_TMP/qa-ci-trace-report-{_DATE}.md`:
- Executive summary: CI time trend, top 3 bottlenecks
- Ranked recommendations table: Rank | Step | Issue | Est. Savings | Fix
- Full step timing breakdown (p50/p95/p99)

Write `$_TMP/qa-ci-trace-ctrf.json` (each recommendation = one test; critical = failed, suggestion = passed).

## Important Rules

- All findings are advisory — CTRF tests are passed (no hard gate)
- Use `CI_TRACE_LOOKBACK=20` for higher confidence p95 analysis
- Never suggest removing required build steps — only suggest parallelization and caching
