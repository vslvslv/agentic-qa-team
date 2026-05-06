---
name: qa-report
description: |
  Unified QA dashboard and sprint report. Aggregates CTRF output files from all qa-* skills
  run in a CI pipeline or sprint, producing a single executive Markdown or HTML report:
  pass/fail trend by skill, flakiness index from qa-flaky-registry.json, coverage delta if
  available, performance budget adherence, and an LLM-generated top-3 risk areas narrative.
  Env vars: REPORT_FORMAT, REPORT_PERIOD, REPORT_OUTPUT.
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
echo "--- DETECTION ---"

_CTRF_FILES=$(ls "$_TMP"/qa-*-ctrf.json 2>/dev/null | tr '\n' ' ')
_CTRF_COUNT=$(echo "$_CTRF_FILES" | wc -w | tr -d ' ')
echo "CTRF_FILES_FOUND: $_CTRF_COUNT"
[ -n "$_CTRF_FILES" ] && echo "FILES: $_CTRF_FILES" || echo "WARN: no CTRF files found in $_TMP"

[ -f "$_TMP/qa-flaky-registry.json" ] && echo "FLAKY_REGISTRY: present" || echo "FLAKY_REGISTRY: absent"
[ -f "$_TMP/qa-coverage-gate-ctrf.json" ] && echo "COVERAGE_DATA: present" || echo "COVERAGE_DATA: absent"

_REPORT_FORMAT="${REPORT_FORMAT:-markdown}"
_REPORT_PERIOD="${REPORT_PERIOD:-pr}"
_REPORT_OUTPUT="${REPORT_OUTPUT:-$_TMP/qa-report-$_DATE.md}"
echo "REPORT_FORMAT: $_REPORT_FORMAT  PERIOD: $_REPORT_PERIOD"
echo "--- DONE ---"
```

If `CTRF_FILES_FOUND: 0`, use AskUserQuestion to ask the user to run individual qa-* skills first, or point to a directory containing CTRF files.

## Phase 1 — Aggregate CTRF Data

Load all CTRF JSON files. For each skill: extract tool name, summary counts (tests/passed/failed/skipped), and individual test results. Build a unified results map keyed by skill name.

## Phase 2 — Enrich with Auxiliary Data

- Load flaky registry: annotate tests matching known flaky tests with `[FLAKY]` marker
- Load coverage delta: extract per-file pass/fail counts
- Load perf CTRF: extract budget adherence metrics

## Phase 3 — LLM Risk Narrative

Analyze the aggregated data. Generate a "Top 3 Risk Areas" narrative:
- Identify the skill with the highest failure rate
- Identify any new failures vs. previous run (if prior report exists)
- Identify coverage gaps in recently changed files
- Suggest which areas need immediate attention vs. monitoring

## Phase N — Write Report

Write unified Markdown report to `$_REPORT_OUTPUT` with:
- Header: branch, date, period, total pass rate
- Skill-by-skill summary table
- Top 3 risk narrative
- Flaky test registry summary (if available)

Write `$_TMP/qa-report-ctrf.json` summarizing the meta-report itself.

## Important Rules

- This skill aggregates — it never runs other skills; point it at a `$_TMP` dir with existing CTRF files
- Use `REPORT_PERIOD=sprint` to aggregate over multiple days of runs
- Flaky tests are annotated but not counted as failures in the unified report
