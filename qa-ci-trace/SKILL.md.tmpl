---
name: qa-ci-trace
preamble-tier: 3
version: 1.0.0
description: |
  CI build intelligence from OTel traces. Analyzes build trace data emitted by Honeycomb buildevents
  or an OTLP backend to identify the slowest test stages, flappy infrastructure steps, parallelism
  opportunities, and recurring failure patterns across recent runs. Produces an actionable CI
  optimization report.
  Env vars: BUILDEVENTS_APIKEY, CI_TRACE_LOOKBACK, HONEYCOMB_DATASET. (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
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
echo "BRANCH: $_BRANCH  DATE: $_DATE"
echo "--- DETECTION ---"

# API keys and endpoint config
_BUILDEVENTS_KEY="${BUILDEVENTS_APIKEY:-}"
_OTEL_ENDPOINT="${OTEL_EXPORTER_OTLP_ENDPOINT:-}"
_HONEYCOMB_API="${HONEYCOMB_API_KEY:-$_BUILDEVENTS_KEY}"
_HONEYCOMB_DATASET="${HONEYCOMB_DATASET:-ci-builds}"
_TRACE_LOOKBACK="${CI_TRACE_LOOKBACK:-10}"
echo "HONEYCOMB_DATASET: $_HONEYCOMB_DATASET  TRACE_LOOKBACK: $_TRACE_LOOKBACK"
echo "OTEL_ENDPOINT: ${_OTEL_ENDPOINT:-unset}"

# Check Honeycomb access
_HONEYCOMB_AVAILABLE=0
if [ -n "$_HONEYCOMB_API" ]; then
  curl -sf -H "X-Honeycomb-Team: $_HONEYCOMB_API" \
    https://api.honeycomb.io/1/auth >/dev/null 2>&1 \
    && _HONEYCOMB_AVAILABLE=1
fi
echo "HONEYCOMB_AVAILABLE: $_HONEYCOMB_AVAILABLE"

# Check local trace files
_LOCAL_FILES=$(ls "$_TMP"/buildevents-*.json 2>/dev/null | head -5)
echo "LOCAL_TRACE_FILES: ${_LOCAL_FILES:-none}"

# Determine data source
_DATA_SOURCE="none"
[ "$_HONEYCOMB_AVAILABLE" = "1" ] && _DATA_SOURCE="honeycomb"
[ -z "$_LOCAL_FILES" ] || _DATA_SOURCE="local"
[ -n "$_OTEL_ENDPOINT" ] && _DATA_SOURCE="otlp"
echo "DATA_SOURCE: $_DATA_SOURCE"
```

If `_DATA_SOURCE` is `none`: emit the following and stop gracefully:
```
No CI trace data source found. To use qa-ci-trace, set one of:

Option A — Honeycomb buildevents:
  export BUILDEVENTS_APIKEY=<your-key>
  export HONEYCOMB_DATASET=ci-builds   # optional, default: ci-builds

Option B — Local trace files:
  Place buildevents JSON exports in: $TMP/buildevents-<run>.json

Option C — OTLP endpoint:
  export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

See: https://github.com/honeycombio/buildevents
```

## Phase 1 — Fetch Trace Data

Fetch trace data based on `_DATA_SOURCE`:

```bash
echo "--- FETCHING TRACE DATA ($DATA_SOURCE) ---"

if [ "$_DATA_SOURCE" = "honeycomb" ]; then
  # Query Honeycomb for top slow steps across last N builds
  curl -sf \
    -H "X-Honeycomb-Team: $_HONEYCOMB_API" \
    -H "Content-Type: application/json" \
    "https://api.honeycomb.io/1/query/$_HONEYCOMB_DATASET" \
    -d '{
      "calculations": [
        {"op": "AVG", "column": "duration_ms"},
        {"op": "P95", "column": "duration_ms"},
        {"op": "COUNT"},
        {"op": "COUNT_DISTINCT", "column": "trace.trace_id"}
      ],
      "filters": [{"column": "trace.span_id", "op": "exists"}],
      "breakdowns": ["name", "error"],
      "orders": [{"column": "duration_ms", "op": "P95", "order": "descending"}],
      "limit": 30,
      "time_range": 604800
    }' > "$_TMP/qa-ci-trace-raw.json" 2>&1
  echo "HONEYCOMB_QUERY_EXIT: $?"

elif [ "$_DATA_SOURCE" = "local" ]; then
  # Merge local files
  python3 -c "
import json, glob, os
tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
files = sorted(glob.glob(os.path.join(tmp, 'buildevents-*.json')))[:10]
all_spans = []
for f in files:
    try:
        data = json.load(open(f))
        if isinstance(data, list): all_spans.extend(data)
        elif isinstance(data, dict): all_spans.append(data)
    except: pass
json.dump({'source': 'local', 'spans': all_spans, 'files': files},
          open(os.path.join(tmp, 'qa-ci-trace-raw.json'), 'w'), indent=2)
print(f'MERGED: {len(all_spans)} spans from {len(files)} files')
"
fi

echo "RAW_DATA_SIZE: $(wc -c < "$_TMP/qa-ci-trace-raw.json" 2>/dev/null || echo 0) bytes"
```

## Phase 2 — LLM Analysis

Parse the collected trace data and analyze:

```python
python3 - << 'PYEOF'
import json, os

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
data_source = os.environ.get('_DATA_SOURCE', 'none')

try:
    raw = json.load(open(os.path.join(tmp, 'qa-ci-trace-raw.json'), encoding='utf-8'))
except Exception as e:
    print(f"PARSE_ERROR: {e}")
    raw = {}

# Extract spans/steps for analysis
steps = []

if data_source == 'honeycomb':
    series = raw.get('results', [])
    for row in series:
        data = row.get('data', {})
        steps.append({
            'name': data.get('name', 'unknown'),
            'avg_ms': data.get('AVG(duration_ms)', 0) or 0,
            'p95_ms': data.get('P95(duration_ms)', 0) or 0,
            'count': data.get('COUNT', 0) or 0,
            'error': data.get('error', False),
        })

elif data_source == 'local':
    spans = raw.get('spans', [])
    name_map = {}
    for span in spans:
        name = span.get('name', span.get('service.name', 'unknown'))
        dur = span.get('duration_ms', span.get('durationMs', 0)) or 0
        err = span.get('error', span.get('status.code', 0)) not in (0, None, False, '')
        if name not in name_map:
            name_map[name] = {'durations': [], 'errors': 0, 'count': 0}
        name_map[name]['durations'].append(dur)
        name_map[name]['errors'] += 1 if err else 0
        name_map[name]['count'] += 1
    for name, m in name_map.items():
        d = sorted(m['durations'])
        p95_idx = max(0, int(len(d) * 0.95) - 1)
        steps.append({
            'name': name,
            'avg_ms': int(sum(d) / len(d)) if d else 0,
            'p95_ms': d[p95_idx] if d else 0,
            'count': m['count'],
            'error_rate': m['errors'] / m['count'] if m['count'] else 0,
        })

# Sort by P95 descending
steps.sort(key=lambda s: s.get('p95_ms', 0), reverse=True)

# Identify issues
slowest = steps[:5]
flaky = [s for s in steps if s.get('error_rate', 0) > 0.2 or s.get('error', False)]
parallelism = []  # Steps with no apparent dependency (heuristic: similar names at same level)

# Build analysis summary
analysis = {
    'data_source': data_source,
    'total_steps': len(steps),
    'slowest_steps': slowest,
    'reliability_issues': flaky[:5],
    'all_steps': steps[:50],
}

out = os.path.join(tmp, 'qa-ci-trace-analysis.json')
json.dump(analysis, open(out, 'w', encoding='utf-8'), indent=2)
print(f"TOTAL_STEPS: {len(steps)}")
print(f"SLOWEST: {[(s['name'][:40], s.get('p95_ms',0)) for s in slowest[:3]]}")
print(f"FLAKY: {[s['name'][:40] for s in flaky[:3]]}")
print(f"ANALYSIS_WRITTEN: {out}")
PYEOF
```

Use your LLM capabilities to analyze `$_TMP/qa-ci-trace-analysis.json` and generate:
1. **Top 5 slowest CI steps** — with specific improvement suggestions (e.g., "cache npm dependencies", "parallelize test shards", "skip redundant linting in PR builds")
2. **Steps with >20% failure rate** — identify whether failures are flaky (non-deterministic) or systematic
3. **Parallelism opportunities** — sequential steps with no data dependency (e.g., unit tests and lint running serially)
4. **Recurring error patterns** — same error message across multiple build failures
5. **Trend assessment** — is build time stable, improving, or degrading across the analyzed window?

## Phase 3 — Report

```python
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
date = os.environ.get('_DATE', 'unknown')
lookback = os.environ.get('_TRACE_LOOKBACK', '10')
data_source = os.environ.get('_DATA_SOURCE', 'unknown')

try:
    analysis = json.load(open(os.path.join(tmp, 'qa-ci-trace-analysis.json'), encoding='utf-8'))
    slowest = analysis.get('slowest_steps', [])
    flaky = analysis.get('reliability_issues', [])
except Exception:
    analysis = {}; slowest = []; flaky = []

# Report will be filled with LLM-generated insights (see Phase 2 above)
# This writes the structure; LLM recommendations are injected inline
lines = [
    f'# CI Build Intelligence — {date}',
    f'',
    f'> Data source: {data_source} | Lookback: last {lookback} builds',
    f'',
    '## Build Time Trend',
    '',
    '_(Populated from LLM analysis in Phase 2)_',
    '',
    '## Top Slowest Steps',
    '',
    '| Step | P50 (ms) | P95 (ms) | Recommendation |',
    '|------|----------|----------|----------------|',
]

for s in slowest:
    p95 = s.get('p95_ms', 0)
    avg = s.get('avg_ms', 0)
    rec = '_(LLM recommendation)_'
    if p95 > 120000:
        rec = 'Consider caching dependencies or splitting into parallel jobs'
    elif p95 > 60000:
        rec = 'Review for redundant work; consider parallelization'
    lines.append(f'| {s["name"][:40]} | {avg:,} | {p95:,} | {rec} |')

lines += [
    '',
    '## Reliability Issues',
    '',
    '| Step | Failure Rate | Pattern | Fix Suggestion |',
    '|------|-------------|---------|----------------|',
]

for s in flaky:
    rate = s.get('error_rate', 0)
    rate_str = f'{rate:.0%}' if rate else 'errors detected'
    lines.append(f'| {s["name"][:40]} | {rate_str} | _(LLM analysis)_ | _(LLM suggestion)_ |')

lines += [
    '',
    '## Parallelism Opportunities',
    '',
    '_(LLM analysis: sequential steps identified as independent)_',
    '',
    '## Action Items',
    '',
    '_(Ranked by estimated impact — populated from LLM analysis)_',
    '',
    '1. _(highest impact recommendation)_',
    '2. _(second recommendation)_',
    '3. _(third recommendation)_',
    '',
    '---',
    '_This report is advisory. All recommendations should be validated against your specific CI configuration._',
]

report_path = os.path.join(tmp, f'qa-ci-trace-report-{date}.md')
open(report_path, 'w', encoding='utf-8').write('\n'.join(lines))
print(f'REPORT_WRITTEN: {report_path}')

# CTRF — each recommendation = one informational "passed" test case
ctrf_tests = []
for i, s in enumerate(slowest, 1):
    ctrf_tests.append({
        'name': f'slow-step: {s["name"][:60]}',
        'status': 'passed',
        'duration': s.get('p95_ms', 0),
        'suite': 'ci-intelligence',
        'message': f'P95={s.get("p95_ms",0)}ms — optimization recommended',
    })
for s in flaky:
    ctrf_tests.append({
        'name': f'flaky-step: {s["name"][:60]}',
        'status': 'passed',
        'duration': 0,
        'suite': 'ci-intelligence',
        'message': f'failure rate {s.get("error_rate",0):.0%} — investigation recommended',
    })

now_ms = int(time.time() * 1000)
ctrf = {
    'results': {
        'tool': {'name': 'qa-ci-trace'},
        'summary': {
            'tests': len(ctrf_tests), 'passed': len(ctrf_tests), 'failed': 0,
            'pending': 0, 'skipped': 0, 'other': 0,
            'start': now_ms - 5000, 'stop': now_ms,
        },
        'tests': ctrf_tests,
        'environment': {'reportName': 'qa-ci-trace', 'dataSource': data_source, 'date': date},
    }
}

out = os.path.join(tmp, 'qa-ci-trace-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  advisory tests={len(ctrf_tests)} (all passed — this skill is always advisory)')
PYEOF
```

## Important Rules

- **No data source = graceful stop** — emit setup instructions and exit; do not fabricate trace data
- **Recommendations must be specific** — "add caching for node_modules" not "make it faster"
- **This skill never fails CI** — all CTRF test cases are `passed`; findings are advisory
- **Honeycomb query uses 7-day window** — `time_range: 604800` seconds (1 week); adjust via `CI_TRACE_LOOKBACK`
- **LLM analysis is the core value** — Phase 2 produces raw data; your intelligence produces actionable insights

## Agent Memory

After each run, update `.claude/agent-memory/qa-ci-trace/MEMORY.md` (create if absent). Record:
- Data source used and whether authentication succeeded
- Consistently slow steps identified in this project
- Recurring flaky steps and their known root causes
- Last analyzed date range

Read this file at the start of each run to provide trend context.

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-ci-trace","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
