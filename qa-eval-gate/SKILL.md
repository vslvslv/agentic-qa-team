---
name: qa-eval-gate
preamble-tier: 3
version: 1.0.0
description: |
  Eval-driven CI gate for AI features. Enforces that every AI feature shipped has a passing evaluation harness before the PR merges. Discovers eval files in evals/ or tests/evals/ directories, runs them with the detected eval runner, scores results, and blocks CI if the aggregate pass-rate drops below a configurable threshold. Env vars: EVAL_PASS_THRESHOLD, EVAL_FAIL_FAST, ANTHROPIC_API_KEY. (qa-agentic-team)
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

# Discover eval directories
_EVAL_DIRS=$(find . -type d \( -name "evals" -o -name "eval" \) ! -path "*/node_modules/*" 2>/dev/null)
echo "EVAL_DIR_FOUND: ${_EVAL_DIRS:-none}"

# Discover eval files across all supported formats
_EVAL_FILES=$(find . -type f \( -name "*.eval.ts" -o -name "*.eval.py" -o -name "*.eval.yaml" -o -name "*.eval.json" \) ! -path "*/node_modules/*" 2>/dev/null)
_EVAL_FILE_COUNT=$(echo "$_EVAL_FILES" | grep -c . 2>/dev/null || echo 0)
echo "EVAL_FILE_COUNT: $_EVAL_FILE_COUNT"
echo "$_EVAL_FILES" | head -20

# Gate configuration
_EVAL_THRESHOLD="${EVAL_PASS_THRESHOLD:-0.8}"
_EVAL_FAIL_FAST="${EVAL_FAIL_FAST:-0}"
echo "EVAL_THRESHOLD: $_EVAL_THRESHOLD"
echo "EVAL_FAIL_FAST: $_EVAL_FAIL_FAST"

# API key check
_API_KEY_SET=0
[ -n "${ANTHROPIC_API_KEY:-}" ] && _API_KEY_SET=1
echo "API_KEY_SET: $_API_KEY_SET"

# Detect eval runners
echo "--- RUNNER DETECTION ---"
_RUNNER="none"
pip show deepeval >/dev/null 2>&1 && { echo "RUNNER_DEEPEVAL: available"; _RUNNER="deepeval"; }
npx promptfoo --version >/dev/null 2>&1 && { echo "RUNNER_PROMPTFOO: available"; _RUNNER="promptfoo"; }
pip show braintrust >/dev/null 2>&1 && { echo "RUNNER_BRAINTRUST: available"; _RUNNER="braintrust"; }
_CUSTOM_EVAL_SCRIPT=$(node -e "try{const p=require('./package.json');const s=Object.keys(p.scripts||{}).filter(k=>k.includes('eval'));console.log(s.join(','))}catch(e){}" 2>/dev/null || true)
[ -n "$_CUSTOM_EVAL_SCRIPT" ] && { echo "RUNNER_CUSTOM_SCRIPTS: $_CUSTOM_EVAL_SCRIPT"; _RUNNER="custom"; }
echo "EVAL_RUNNER: $_RUNNER"
echo "--- DONE ---"
```

If `_EVAL_FILE_COUNT` is `0`: emit `WARN: No eval files found. Add *.eval.ts/py/yaml to evals/ to enable this gate.` Write `$_TMP/qa-eval-gate-ctrf.json` with a single `skipped` test and exit cleanly (non-blocking).

## Phase 1 — Discover & Classify Evals

For each eval file in `$_EVAL_FILES`, detect its type:
- `*.eval.yaml` → promptfoo YAML config (providers, tests, assertions)
- `*.eval.py` with `from deepeval` import → deepeval Python test
- `*.eval.py` with `from braintrust` import → braintrust Python test
- `*.eval.ts` / `*.eval.js` → vitest-based or custom TS eval harness
- `*.eval.json` → JSON config format

Build a task list: `{file, type, estimated_test_count}`.

## Phase 2 — Run Evals

Execute each eval using the appropriate runner. Collect per-eval: `name`, `pass_count`, `fail_count`, `score (0–1)`.

### promptfoo YAML

```bash
for _yf in $(echo "$_EVAL_FILES" | grep "\.eval\.yaml$"); do
  _eval_name=$(basename "$_yf" .eval.yaml)
  echo "=== RUNNING promptfoo: $_eval_name ==="
  npx promptfoo eval --config "$_yf" \
    --output "$_TMP/qa-eval-${_eval_name}.json" \
    --no-cache \
    2>&1 | tail -30
  echo "PROMPTFOO_EXIT: $?"
done
```

Parse output JSON: `results.results[]` — count entries where `success=true` vs `success=false`. Score = pass/(pass+fail).

### deepeval Python

```bash
for _pyf in $(echo "$_EVAL_FILES" | grep "\.eval\.py$"); do
  _eval_name=$(basename "$_pyf" .eval.py)
  echo "=== RUNNING deepeval: $_eval_name ==="
  python -m pytest "$_pyf" -v --tb=short 2>&1 | tee "$_TMP/qa-eval-${_eval_name}.txt"
  echo "PYTEST_EXIT: $?"
  [ "$_EVAL_FAIL_FAST" = "1" ] && grep -q "FAILED" "$_TMP/qa-eval-${_eval_name}.txt" && break
done
```

Parse text: count `PASSED` and `FAILED` lines. Score = PASSED/(PASSED+FAILED).

### custom/vitest TS evals

```bash
for _tsf in $(echo "$_EVAL_FILES" | grep "\.eval\.ts$\|\.eval\.js$"); do
  _eval_name=$(basename "$_tsf" | sed 's/\.eval\.[tj]s$//')
  echo "=== RUNNING vitest: $_eval_name ==="
  npx vitest run "$_tsf" --reporter=json \
    > "$_TMP/qa-eval-${_eval_name}-vitest.json" 2>&1
  echo "VITEST_EXIT: $?"
  [ "$_EVAL_FAIL_FAST" = "1" ] && grep -q '"numFailedTests":[^0]' "$_TMP/qa-eval-${_eval_name}-vitest.json" && break
done
```

Parse vitest JSON: `numPassedTests`, `numFailedTests`. Score = numPassedTests/(numPassedTests+numFailedTests).

## Phase 3 — Score & Gate

```python
python3 - << 'PYEOF'
import json, os, sys

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
threshold = float(os.environ.get('EVAL_PASS_THRESHOLD', '0.8'))
results_file = os.path.join(tmp, 'qa-eval-results.json')

eval_results = []

# Try to parse promptfoo output first
if os.path.exists(results_file):
    try:
        data = json.load(open(results_file, encoding='utf-8', errors='replace'))
        for result in data.get('results', {}).get('testResults', []):
            name = result.get('description', 'unnamed')
            passed = result.get('pass', False)
            eval_results.append({'name': name, 'passed': passed, 'score': 1.0 if passed else 0.0})
    except Exception as e:
        print(f'PROMPTFOO_PARSE_ERROR: {e}')

total = len(eval_results)
passed_count = sum(1 for r in eval_results if r['passed'])
overall_rate = (passed_count / total) if total > 0 else 0.0
gate_pass = overall_rate >= threshold

print(f'EVAL_TOTAL: {total}')
print(f'EVAL_PASSED: {passed_count}')
print(f'EVAL_PASS_RATE: {overall_rate:.2f}')
print(f'EVAL_THRESHOLD: {threshold}')
print(f'EVAL_GATE: {"PASS" if gate_pass else "FAIL"}')

failing = [r for r in eval_results if not r['passed']]
if failing:
    print('FAILING_EVALS:')
    for r in failing:
        print(f'  - {r["name"]} (score={r["score"]:.2f})')
PYEOF
```

- Overall gate: PASS if aggregate pass rate >= `$_EVAL_PASS_THRESHOLD`
- List failing evals with their individual scores — not just aggregate

## Phase 4 — Report + CTRF

Write `$_TMP/qa-eval-gate-report-$_DATE.md`:

```markdown
# QA Eval Gate Report — <date> (<branch>)

## Summary
- Eval directory: <_EVAL_DIR>
- Threshold: <_EVAL_PASS_THRESHOLD>
- Pass rate: <X.XX> (<n>/<total> evals passing)
- Gate: PASS / FAIL / WARN (no evals)

## Eval Results

| Eval File | Type | Pass Count | Fail Count | Score | Status |
|-----------|------|-----------|-----------|-------|--------|

## Failing Assertions

<For each failing eval: eval name, specific assertion that failed, score>

## Recommendations

<Suggestions for improving failing evals>
```

Write `$_TMP/qa-eval-gate-ctrf.json`:
- Each eval file = one CTRF test case
- Evals at or above their threshold = `passed`; below = `failed`
- Overall gate: aggregate status = `passed` if overall rate >= threshold, else `failed`

```python
python3 - << 'PYEOF'
import json, os, time, glob as glob_mod

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
threshold = float(os.environ.get('EVAL_PASS_THRESHOLD', '0.8'))
results_file = os.path.join(tmp, 'qa-eval-results.json')
date = os.environ.get('_DATE', 'unknown')

eval_tests = []

if os.path.exists(results_file):
    try:
        data = json.load(open(results_file, encoding='utf-8', errors='replace'))
        for result in data.get('results', {}).get('testResults', []):
            name = result.get('description', 'unnamed-eval')
            passed = result.get('pass', False)
            eval_tests.append({
                'name': name, 'status': 'passed' if passed else 'failed',
                'duration': 0, 'suite': 'qa-eval-gate',
                'message': '' if passed else f'Eval assertion failed (score below threshold {threshold})',
            })
    except Exception:
        pass

if not eval_tests:
    eval_tests.append({
        'name': 'eval-gate', 'status': 'skipped', 'duration': 0,
        'suite': 'qa-eval-gate', 'message': 'No eval results found',
    })

p = sum(1 for t in eval_tests if t['status'] == 'passed')
f = sum(1 for t in eval_tests if t['status'] == 'failed')
s = sum(1 for t in eval_tests if t['status'] == 'skipped')
total = len(eval_tests)
rate = (p / (p + f)) if (p + f) > 0 else 0.0
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-eval-gate'},
        'summary': {
            'tests': total, 'passed': p, 'failed': f,
            'pending': 0, 'skipped': s, 'other': 0,
            'start': now_ms - 10000, 'stop': now_ms,
            'pass_rate': round(rate, 3), 'threshold': threshold,
        },
        'tests': eval_tests,
    }
}
out = os.path.join(tmp, 'qa-eval-gate-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  pass_rate={rate:.2f}  threshold={threshold}  gate={"PASS" if rate >= threshold else "FAIL"}')
PYEOF
```

## Important Rules

- **No evals directory = WARN not FAIL** — teams adopting eval-driven development incrementally should not be blocked
- **Eval files are run as-is** — never modify eval definitions, prompts, or expected outputs
- **Report specific failures** — always name which assertions failed and their score, not just the aggregate
- **EVAL_FAIL_FAST=0 by default** — run all evals even if early ones fail, to provide complete picture
- **Threshold applies per-run** — if an eval file declares its own `expected_pass_rate`, prefer that over the global threshold

## Agent Memory

After each run, update `.claude/agent-memory/qa-eval-gate/MEMORY.md` (create if absent). Record:
- Eval directory location and file formats found
- Which evals are consistently failing across runs (candidates for fix or de-flaking)
- Threshold settings in use per project
