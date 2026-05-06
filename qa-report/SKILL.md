---
name: qa-report
preamble-tier: 3
version: 1.0.0
description: |
  Unified QA dashboard and sprint report. Aggregates CTRF output files from all qa-* skills run in a CI pipeline or sprint, producing a single executive Markdown or HTML report: pass/fail trend by skill, flakiness index from qa-flaky-registry.json, coverage delta if available, performance budget adherence, and an LLM-generated top-3 risk areas narrative. Env vars: REPORT_FORMAT, REPORT_PERIOD, REPORT_OUTPUT. (qa-agentic-team)
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

# Discover CTRF output files from other qa-* skills (exclude qa-report itself)
_CTRF_FILES=$(ls $_TMP/qa-*-ctrf.json 2>/dev/null | grep -v "qa-report")
_CTRF_COUNT=$(echo "$_CTRF_FILES" | grep -c . 2>/dev/null || echo 0)
echo "CTRF_FILES_FOUND: $_CTRF_COUNT"
echo "$_CTRF_FILES"

# Report configuration from env vars
_REPORT_FORMAT="${REPORT_FORMAT:-markdown}"
_REPORT_PERIOD="${REPORT_PERIOD:-pr}"
_REPORT_OUTPUT="${REPORT_OUTPUT:-$_TMP/qa-report-$_DATE.md}"
echo "REPORT_FORMAT: $_REPORT_FORMAT"
echo "REPORT_PERIOD: $_REPORT_PERIOD"
echo "REPORT_OUTPUT: $_REPORT_OUTPUT"

# Check for flaky registry in CWD or tmp
_FLAKY_REGISTRY=""
[ -f "./qa-flaky-registry.json" ] && _FLAKY_REGISTRY="./qa-flaky-registry.json"
echo "FLAKY_REGISTRY_FOUND: ${_FLAKY_REGISTRY:-none}"
```

If `_CTRF_COUNT` is `0`: emit the following guidance and exit gracefully:

> "No CTRF output files found in `$_TMP/qa-*-ctrf.json`. Run one or more qa-* skills first (e.g. /qa-web, /qa-api, /qa-a11y, /qa-perf) and then re-run /qa-report to aggregate results."

Write `$_TMP/qa-report-ctrf.json` with a single `skipped` test named `"No CTRF input files found"` and exit cleanly (do not error).

---

## Phase 1 — Load & Aggregate CTRF Files

For each file in `$_CTRF_FILES`, parse its JSON and extract:
- `skill_name`: from `results.tool.name`
- `tests`, `passed`, `failed`, `skipped`, `pending`: from `results.summary`
- `duration_s`: compute from `(results.summary.stop - results.summary.start) / 1000`
- `pass_rate`: `passed / tests * 100` (0 if tests=0)
- `failed_tests[]`: up to 10 entries with `name` + `message` from tests where status="failed"

```bash
for _f in $_CTRF_FILES; do
  echo "=== PARSING: $(basename $_f) ==="
  python3 - "$_f" << 'PYEOF'
import json, sys
try:
    data = json.load(open(sys.argv[1], encoding='utf-8', errors='replace'))
    r = data.get('results', {})
    tool = r.get('tool', {}).get('name', 'unknown')
    s = r.get('summary', {})
    tests_list = r.get('tests', [])
    t = s.get('tests', 0); p = s.get('passed', 0); f = s.get('failed', 0)
    sk = s.get('skipped', 0)
    start = s.get('start', 0); stop = s.get('stop', 0)
    dur = round((stop - start) / 1000, 1) if stop and start else 0
    rate = round(p / t * 100, 1) if t else 0
    print(f"SKILL={tool} tests={t} passed={p} failed={f} skipped={sk} duration={dur}s pass_rate={rate}%")
    for ft in [x for x in tests_list if x.get('status') == 'failed'][:10]:
        print(f"  FAIL: {ft.get('name','?')} — {str(ft.get('message',''))[:120]}")
except Exception as e:
    print(f"ERROR: {e}")
PYEOF
done
```

Build an in-memory aggregate across all skills:
- `overall_tests`, `overall_passed`, `overall_failed`, `overall_pass_rate`
- Per-skill summary map: `{skill: {tests, passed, failed, skipped, duration_s, pass_rate, failed_tests[]}}`

---

## Phase 2 — Flakiness & Supplementary Signals

### Flakiness Index

If `_FLAKY_REGISTRY` is set, read `qa-flaky-registry.json` and join on test names:

```bash
if [ -n "$_FLAKY_REGISTRY" ]; then
  python3 - "$_FLAKY_REGISTRY" << 'PYEOF'
import json, sys
try:
    reg = json.load(open(sys.argv[1], encoding='utf-8', errors='replace'))
    tests = reg if isinstance(reg, list) else reg.get('tests', [])
    flaky = [t for t in tests if float(t.get('flake_rate', 0)) > 0]
    print(f"FLAKY_TESTS_TOTAL: {len(flaky)}")
    for t in sorted(flaky, key=lambda x: -float(x.get('flake_rate', 0)))[:10]:
        print(f"  {t.get('name','?')}: flake_rate={float(t.get('flake_rate',0)):.1%}  skill={t.get('skill','?')}")
except Exception as e:
    print(f"FLAKY_REGISTRY_ERROR: {e}")
PYEOF
fi
```

Incorporate flake rates into the per-skill rows of the report table. Compute a per-skill flaky count for tests with `flake_rate > 0` that appeared in this run.

### Coverage Delta

If `$_TMP/qa-coverage-gate-ctrf.json` exists: parse and extract `custom.coverage_delta` or `custom.coverage_pct` from the tool metadata section. Include as "Coverage" line in the Supplementary Signals section.

### Performance Budget

If `$_TMP/qa-perf-ctrf.json` exists: count failed tests (each = one threshold violation). Report as "Perf Budget: X violations".

### Accessibility

If `$_TMP/qa-a11y-ctrf.json` exists: count failed tests (each = one new violation). Report as "A11y: X new violations".

---

## Phase 3 — LLM Narrative

Using the aggregated data from Phases 1 and 2, generate three narrative sections:

**Top 3 Risk Areas** — 2–3 sentences each, grounded in actual data:
1. **Highest-failure skill**: Name the skill, cite its failure count and pass rate, explain what the failure pattern suggests (e.g., auth dependency, data setup issue, environment instability)
2. **Most flaky area**: Name the top flaky tests and their `flake_rate`, hypothesize root cause (race condition, timing, external service dependency)
3. **Threshold or coverage breach**: Name any perf/coverage/a11y threshold that was violated, state the gap, and explain the user-facing impact

**Executive Summary** — one paragraph (4–6 sentences) covering: overall pass rate, number of skills run, key wins (skills at 100%), key concerns (skills with failures), and one concrete recommended immediate action.

**Recommended Next Actions** — a prioritized bullet list of 3–5 actions, each phrased as an actionable imperative (e.g., "Fix 3 critical failures in qa-api before merging PR #42", "Add retry logic to flaky login test — 40% flake rate suggests auth token race condition").

---

## Phase 4 — Write Report

### Markdown Structure

Write `$_REPORT_OUTPUT`:

```markdown
# QA Report — <_DATE> — <_REPORT_PERIOD>

## Executive Summary

<LLM-generated executive summary paragraph>

## Pass/Fail by Skill

| Skill | Tests | Passed | Failed | Skipped | Flaky | Pass Rate | Duration |
|-------|-------|--------|--------|---------|-------|-----------|----------|
| qa-web | N | N | N | N | N | NN% | Ns |
| **TOTAL** | **N** | **N** | **N** | **N** | | **NN%** | |

## Top 3 Risk Areas

### 1. <Risk Title>
<2–3 sentence description>

### 2. <Risk Title>
<2–3 sentence description>

### 3. <Risk Title>
<2–3 sentence description>

## Detailed Failures

### <skill-name>
- **<test name>**: <message>

## Supplementary Signals

- Coverage delta: <value or "N/A — no coverage CTRF found">
- Performance budget: <X violations or "N/A — no perf CTRF found">
- Accessibility: <X new violations or "N/A — no a11y CTRF found">

## Recommendations

<Prioritized bullet list from LLM>
```

### HTML Variant

If `_REPORT_FORMAT=html`: change `_REPORT_OUTPUT` extension to `.html` and wrap the same content in:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>QA Report — <date></title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 960px; margin: 2rem auto; color: #1a1a1a; }
    table { border-collapse: collapse; width: 100%; margin: 1rem 0; }
    th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
    th { background: #f5f5f5; font-weight: 600; }
    tr:nth-child(even) { background: #fafafa; }
    .pass { color: #16a34a; } .fail { color: #dc2626; } .warn { color: #d97706; }
    h1 { border-bottom: 2px solid #e5e7eb; padding-bottom: 0.5rem; }
  </style>
</head>
<body>
<!-- report content as HTML — convert markdown table/heading syntax to HTML tags -->
</body>
</html>
```

### Summary CTRF

Write `$_TMP/qa-report-ctrf.json`. Each skill from the aggregate = one CTRF test case:
- `name`: skill name (e.g., `"qa-web"`)
- `status`: `"passed"` if `failed==0`, else `"failed"`
- `message`: `"pass_rate=NN% tests=N failed=N"`
- `suite`: `"qa-report"`

```bash
python3 - << 'PYEOF'
import json, os, time, glob as glob_mod

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'

tests = []
total = passed_total = failed_total = skipped_total = 0

for f in sorted(glob_mod.glob(os.path.join(tmp, 'qa-*-ctrf.json'))):
    if f.endswith('qa-report-ctrf.json'):
        continue
    try:
        data = json.load(open(f, encoding='utf-8', errors='replace'))
        r = data.get('results', {})
        skill = r.get('tool', {}).get('name', os.path.basename(f).replace('-ctrf.json', ''))
        s = r.get('summary', {})
        t = s.get('tests', 0); p = s.get('passed', 0); f_c = s.get('failed', 0); sk = s.get('skipped', 0)
        total += t; passed_total += p; failed_total += f_c; skipped_total += sk
        rate = round(p / t * 100, 1) if t else 0
        tests.append({
            'name': skill,
            'status': 'passed' if f_c == 0 else 'failed',
            'duration': 0,
            'suite': 'qa-report',
            'message': f'pass_rate={rate}% tests={t} failed={f_c}',
        })
    except Exception:
        pass

now_ms = int(time.time() * 1000)
p_count = sum(1 for t in tests if t['status'] == 'passed')
f_count = sum(1 for t in tests if t['status'] == 'failed')

ctrf = {
    'results': {
        'tool': {'name': 'qa-report'},
        'summary': {
            'tests': len(tests), 'passed': p_count, 'failed': f_count,
            'pending': 0, 'skipped': 0, 'other': 0,
            'start': now_ms - 10000, 'stop': now_ms,
        },
        'tests': tests,
        'environment': {
            'reportName': 'qa-report',
            'period': os.environ.get('_REPORT_PERIOD', 'pr'),
            'aggregated_tests': total,
            'aggregated_passed': passed_total,
            'aggregated_failed': failed_total,
        },
    }
}

out = os.path.join(tmp, 'qa-report-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  skills={len(tests)} passed={p_count} failed={f_count}')
print(f'  aggregated: tests={total} passed={passed_total} failed={failed_total}')
PYEOF
```

---

## Important Rules

- **Run AFTER other qa-* skills** — this skill aggregates output; it provides no value if run first
- **Read-only aggregator** — never re-run other skills, never modify source CTRF files
- **Graceful no-input handling** — if no CTRF files exist, emit guidance and exit with a skipped CTRF (non-blocking)
- **HTML output** — `REPORT_FORMAT=html` wraps the same content in styled HTML; narrative logic is identical, only the wrapper changes
- **Flakiness is advisory** — flaky test data enriches the report but never causes a CTRF failure on its own
- **LLM narrative accuracy** — only cite data present in the CTRF files; never invent failure details

## Agent Memory

After each run, update `.claude/agent-memory/qa-report/MEMORY.md` (create if absent). Record:
- Which qa-* skills produced CTRF files in the last run
- Whether a flaky registry was found and its path
- Recurring top-failure areas across runs
- Any supplementary signals (coverage/perf/a11y) consistently available
