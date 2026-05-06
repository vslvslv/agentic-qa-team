---
name: qa-test-order
preamble-tier: 3
version: 1.0.0
description: |
  Test order dependency detector. Runs the test suite multiple times with different
  randomized orderings (using jest --randomize, pytest-randomly, or go test -shuffle)
  to identify tests that only pass when run after specific other tests — a sign of
  shared global state leakage. Generates an isolation dependency graph and recommends
  beforeEach/afterEach fixes. Env vars: TEST_ORDER_RUNS, TEST_ORDER_TIMEOUT. (qa-agentic-team)
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

# Detect test runner
_TEST_RUNNER="unknown"
if [ -f "package.json" ]; then
  grep -q '"jest"' package.json 2>/dev/null && _TEST_RUNNER="jest"
  grep -q '"vitest"' package.json 2>/dev/null && _TEST_RUNNER="vitest"
  ls jest.config.* 2>/dev/null | head -1 | grep -q . && _TEST_RUNNER="jest"
  ls vitest.config.* 2>/dev/null | head -1 | grep -q . && _TEST_RUNNER="vitest"
fi
{ [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -f "setup.cfg" ]; } && \
  grep -q "pytest" pyproject.toml 2>/dev/null && _TEST_RUNNER="pytest"
[ -f "go.mod" ] && _TEST_RUNNER="go"
echo "TEST_RUNNER: $_TEST_RUNNER"

# Check randomization support
echo "--- RANDOMIZATION SUPPORT ---"
case "$_TEST_RUNNER" in
  jest)
    _JEST_VER=$(npx jest --version 2>/dev/null || echo "0.0.0")
    echo "JEST_VERSION: $_JEST_VER"
    # jest --randomize added in v29
    echo "$_JEST_VER" | awk -F. '{if ($1>=29) print "RANDOMIZE_SUPPORT: yes"; else print "RANDOMIZE_SUPPORT: no (upgrade to jest>=29)"}'
    ;;
  vitest)
    echo "RANDOMIZE_SUPPORT: yes (vitest supports sequence.shuffle)"
    ;;
  pytest)
    python -m pytest --fixtures 2>/dev/null | grep -q "randomly" && \
      echo "RANDOMIZE_SUPPORT: yes (pytest-randomly installed)" || \
      echo "RANDOMIZE_SUPPORT: no (pip install pytest-randomly)"
    ;;
  go)
    echo "RANDOMIZE_SUPPORT: yes (go test -shuffle=on -count=1)"
    ;;
  *)
    echo "RANDOMIZE_SUPPORT: unknown"
    ;;
esac

_TEST_ORDER_RUNS="${TEST_ORDER_RUNS:-3}"
_TEST_ORDER_TIMEOUT="${TEST_ORDER_TIMEOUT:-300}"
echo "ORDER_RUNS: $_TEST_ORDER_RUNS"
echo "ORDER_TIMEOUT: ${_TEST_ORDER_TIMEOUT}s per run"
```

If `_TEST_RUNNER=unknown`: use `AskUserQuestion`: "Could not auto-detect a test runner. Set TEST_RUNNER env var (jest, vitest, pytest, go) and re-run." Emit WARN CTRF and stop.

---

## Phase 1 — Baseline Run

Run the test suite once in default order and capture per-test pass/fail status.

```bash
echo "--- BASELINE RUN ---"
case "$_TEST_RUNNER" in
  jest)
    npx jest --json --outputFile="$_TMP/qa-order-baseline.json" 2>/dev/null || true
    ;;
  vitest)
    npx vitest run --reporter=json 2>&1 > "$_TMP/qa-order-baseline.json" || true
    ;;
  pytest)
    python -m pytest --tb=no -q 2>&1 | tee "$_TMP/qa-order-baseline.txt" || true
    ;;
  go)
    go test ./... -v 2>&1 | tee "$_TMP/qa-order-baseline.txt" || true
    ;;
esac
echo "BASELINE_RUN_DONE"
```

Parse baseline results to identify tests that fail in default order (these are pre-existing failures — exclude from analysis).

## Phase 2 — Randomized Runs

Run the test suite `$_TEST_ORDER_RUNS` times (default 3) with different random seeds.

```bash
for i in $(seq 1 "$_TEST_ORDER_RUNS"); do
  _SEED=$((RANDOM * RANDOM + i * 31337))
  echo "--- RANDOMIZED RUN $i (SEED: $_SEED) ---"
  case "$_TEST_RUNNER" in
    jest)
      timeout "$_TEST_ORDER_TIMEOUT" \
        npx jest --randomize --randomizeOrderSeed="$_SEED" --json \
        --outputFile="$_TMP/qa-order-run-$i.json" 2>&1 || true
      ;;
    vitest)
      timeout "$_TEST_ORDER_TIMEOUT" \
        npx vitest run --sequence.shuffle.tests=true --reporter=json \
        2>&1 > "$_TMP/qa-order-run-$i.json" || true
      ;;
    pytest)
      timeout "$_TEST_ORDER_TIMEOUT" \
        python -m pytest -p randomly --randomly-seed="$_SEED" --tb=no -q \
        2>&1 | tee "$_TMP/qa-order-run-$i.txt" || true
      ;;
    go)
      timeout "$_TEST_ORDER_TIMEOUT" \
        go test ./... -shuffle=on -count=1 \
        2>&1 | tee "$_TMP/qa-order-run-$i.txt" || true
      ;;
  esac
  echo "RUN $i DONE"
done
```

Parse per-test results from each run output file.

## Phase 3 — Dependency Analysis

Compare baseline vs randomized run results:

```bash
python3 - << 'PYEOF'
import json, os, re
from collections import defaultdict

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
runner = os.environ.get('_TEST_RUNNER', 'unknown')
num_runs = int(os.environ.get('_TEST_ORDER_RUNS', '3'))

def parse_jest_json(path):
    """Returns {test_name: 'passed'|'failed'} from jest --json output."""
    try:
        data = json.load(open(path, encoding='utf-8'))
        results = {}
        for suite in data.get('testResults', []):
            for t in suite.get('testResults', []):
                results[t.get('fullName', t.get('title', ''))] = (
                    'passed' if t.get('status') == 'passed' else 'failed'
                )
        return results
    except Exception:
        return {}

def parse_text(path):
    """Rough parse for pytest/go text output."""
    results = {}
    try:
        for line in open(path, encoding='utf-8', errors='replace'):
            # pytest: "PASSED src/test_foo.py::test_bar"
            m = re.search(r'(PASSED|FAILED)\s+(\S+)', line)
            if m:
                results[m.group(2)] = m.group(1).lower()
            # go: "--- PASS: TestFoo"
            m2 = re.search(r'--- (PASS|FAIL): (\S+)', line)
            if m2:
                results[m2.group(2)] = 'passed' if m2.group(1) == 'PASS' else 'failed'
    except Exception:
        pass
    return results

# Load baseline
baseline_path = os.path.join(tmp, 'qa-order-baseline.json')
text_path = os.path.join(tmp, 'qa-order-baseline.txt')
if os.path.exists(baseline_path) and runner in ('jest', 'vitest'):
    baseline = parse_jest_json(baseline_path)
elif os.path.exists(text_path):
    baseline = parse_text(text_path)
else:
    baseline = {}

# Tests that fail in baseline = pre-existing, not order issues
preexisting_failures = {k for k, v in baseline.items() if v == 'failed'}

# Load all randomized runs
run_results = []
for i in range(1, num_runs + 1):
    p = os.path.join(tmp, f'qa-order-run-{i}.json')
    t = os.path.join(tmp, f'qa-order-run-{i}.txt')
    if os.path.exists(p) and runner in ('jest', 'vitest'):
        run_results.append(parse_jest_json(p))
    elif os.path.exists(t):
        run_results.append(parse_text(t))

# Find order-dependent tests: pass in baseline but fail in some random run
order_dependent = {}
all_tests = set(baseline.keys())
for run in run_results:
    all_tests.update(run.keys())

for test in all_tests:
    if test in preexisting_failures:
        continue
    base_status = baseline.get(test, 'unknown')
    random_statuses = [r.get(test, 'unknown') for r in run_results]
    passes_in_some = any(s == 'passed' for s in [base_status] + random_statuses)
    fails_in_some = any(s == 'failed' for s in random_statuses)
    if passes_in_some and fails_in_some:
        order_dependent[test] = {
            'baseline': base_status,
            'random_results': random_statuses,
            'fail_count': sum(1 for s in random_statuses if s == 'failed'),
        }

summary = {
    'total_tests': len(all_tests),
    'preexisting_failures': len(preexisting_failures),
    'order_dependent': order_dependent,
    'stable_passing': len(all_tests) - len(preexisting_failures) - len(order_dependent),
}
out = os.path.join(tmp, 'qa-order-analysis.json')
json.dump(summary, open(out, 'w', encoding='utf-8'), indent=2)
print(f"TOTAL_TESTS: {summary['total_tests']}")
print(f"PREEXISTING_FAILURES: {summary['preexisting_failures']}")
print(f"ORDER_DEPENDENT: {len(order_dependent)}")
print(f"STABLE_PASSING: {summary['stable_passing']}")
print(f"ANALYSIS_WRITTEN: {out}")
PYEOF
```

For each order-dependent test, read its test file and perform LLM analysis:
- Identify shared module-level state: global variables, singleton instances, module-level DB connections, static class members
- Identify missing `afterEach` teardown paired with `beforeAll`/`beforeEach` setup
- Suggest concrete isolation fix:
  - Move shared setup from `beforeAll` to `beforeEach`
  - Add `afterEach(() => { resetState(); })` to tear down between tests
  - Replace shared singleton with a factory function: `const db = createTestDb()` per test
  - Use isolated database transactions: `await db.transaction(async (trx) => { ... })`

## Phase 4 — Report

```bash
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
date = os.environ.get('_DATE', 'unknown')
branch = os.environ.get('_BRANCH', 'unknown')
num_runs = os.environ.get('_TEST_ORDER_RUNS', '3')
runner = os.environ.get('_TEST_RUNNER', 'unknown')

try:
    analysis = json.load(open(os.path.join(tmp, 'qa-order-analysis.json'), encoding='utf-8'))
except Exception:
    analysis = {'total_tests': 0, 'preexisting_failures': 0, 'order_dependent': {}, 'stable_passing': 0}

od = analysis.get('order_dependent', {})
lines = [
    f"# QA Test Order Dependency Report — {date}",
    "",
    "## Summary",
    f"- Branch: {branch}",
    f"- Test runner: {runner}",
    f"- Randomized runs: {num_runs}",
    f"- Total tests: {analysis.get('total_tests', 0)}",
    f"- Order-dependent tests: {len(od)}",
    f"- Pre-existing failures (excluded): {analysis.get('preexisting_failures', 0)}",
    f"- Stable passing: {analysis.get('stable_passing', 0)}",
    "",
    "## Order-Dependent Tests",
    "",
    "| Test Name | Baseline | Fail Rate | Suspected Cause | Suggested Fix |",
    "|---|---|---|---|---|",
]

for test_name, info in od.items():
    fail_rate = f"{info['fail_count']}/{len(info['random_results'])}"
    lines.append(f"| `{test_name[:60]}` | {info['baseline']} | {fail_rate} | Shared state (see analysis) | Use beforeEach/afterEach isolation |")

if not od:
    lines.append("| — | — | — | No order dependencies detected | — |")

lines += [
    "",
    "## Pre-Existing Failures",
    "",
    "These tests fail in ALL orderings and are not order-related:",
    "_(See baseline run output for details)_",
    "",
    "## Recommended Fixes",
    "1. Audit `beforeAll` blocks — replace with `beforeEach` where state is mutated",
    "2. Add `afterEach` cleanup for any global/module-level state changes",
    "3. Use factory functions instead of shared object instances across tests",
    "4. For DB tests: use per-test transactions rolled back in `afterEach`",
]

report_path = os.path.join(tmp, f"qa-test-order-report-{date}.md")
open(report_path, 'w', encoding='utf-8').write('\n'.join(lines))
print(f"REPORT_WRITTEN: {report_path}")

# CTRF
tests = []
for test_name, info in od.items():
    tests.append({
        'name': test_name[:120],
        'status': 'failed',
        'duration': 0,
        'suite': 'test-order',
        'message': f"Fails in {info['fail_count']}/{len(info['random_results'])} random orderings",
    })

if not tests:
    tests.append({'name': 'test-order scan', 'status': 'passed', 'duration': 0,
                  'suite': 'test-order', 'message': 'No order dependencies detected'})

passed  = sum(1 for t in tests if t['status'] == 'passed')
failed  = sum(1 for t in tests if t['status'] == 'failed')
skipped = sum(1 for t in tests if t['status'] == 'skipped')
now_ms  = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-test-order'},
        'summary': {
            'tests': len(tests),
            'passed': passed,
            'failed': failed,
            'pending': 0,
            'skipped': skipped,
            'other': 0,
            'start': now_ms - 60000,
            'stop': now_ms,
        },
        'tests': tests,
        'environment': {
            'reportName': 'qa-test-order',
            'testRunner': runner,
            'orderRuns': num_runs,
        },
    }
}

ctrf_path = os.path.join(tmp, 'qa-test-order-ctrf.json')
json.dump(ctrf, open(ctrf_path, 'w', encoding='utf-8'), indent=2)
print(f"CTRF_WRITTEN: {ctrf_path}")
print(f"  tests={len(tests)} passed={passed} failed={failed} skipped={skipped}")
PYEOF
```

## Important Rules

- **If test suite has no randomization support**, document manual workaround (e.g., split test files and run in reverse) and emit WARN CTRF
- **Limit to 3 runs** to avoid excessive CI time; configurable via `TEST_ORDER_RUNS`
- **Tests failing in ALL orderings (including baseline) are pre-existing failures** — exclude from order-dependency analysis; list separately
- **Never auto-apply isolation fixes** — suggestions only
- **Respect `TEST_ORDER_TIMEOUT`** — skip remaining runs if a single run times out

## Agent Memory

After each run, update `.claude/agent-memory/qa-test-order/MEMORY.md` (create if absent). Record:
- Detected test runner and version
- Whether randomization support is available and which flags to use
- Tests known to be order-dependent (track if fixes are applied in future runs)
- Pre-existing failures (exclude from future analysis)

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-test-order","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
