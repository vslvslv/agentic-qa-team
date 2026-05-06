---
name: qa-test-order
description: |
  Test order dependency detector. Runs the test suite multiple times with different
  randomized orderings (using jest --randomize, pytest-randomly, or go test -shuffle)
  to identify tests that only pass when run after specific other tests — a sign of
  shared global state leakage. Generates an isolation dependency graph and recommends
  beforeEach/afterEach fixes. Env vars: TEST_ORDER_RUNS, TEST_ORDER_TIMEOUT.
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

_TEST_RUNNER="unknown"
if [ -f "package.json" ]; then
  grep -q '"jest"' package.json 2>/dev/null && _TEST_RUNNER="jest"
  grep -q '"vitest"' package.json 2>/dev/null && _TEST_RUNNER="vitest"
fi
{ [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; } && \
  grep -q "pytest" pyproject.toml 2>/dev/null && _TEST_RUNNER="pytest"
[ -f "go.mod" ] && _TEST_RUNNER="go"
echo "TEST_RUNNER: $_TEST_RUNNER"

_ORDER_RUNS="${TEST_ORDER_RUNS:-3}"
_ORDER_TIMEOUT="${TEST_ORDER_TIMEOUT:-300}"
echo "ORDER_RUNS: $_ORDER_RUNS"
echo "ORDER_TIMEOUT: ${_ORDER_TIMEOUT}s"
echo "--- DONE ---"
```

If `TEST_RUNNER: unknown`, use AskUserQuestion to ask which test runner to use.

## Phase 1 — Baseline Run

Run the full test suite once without randomization. Capture pass/fail per test. Save to `$_TMP/qa-order-baseline.json`.

## Phase 2 — Randomized Runs

Run `$_ORDER_RUNS` times with different random seeds:

**Jest**: `npx jest --randomize --randomizeOrderSeed=$SEED --json > $_TMP/qa-order-run-N.json`
**Vitest**: `npx vitest run --sequence.shuffle --sequence.seed=$SEED --reporter=json > $_TMP/qa-order-run-N.json`
**Pytest**: `python -m pytest -p randomly --randomly-seed=$SEED --tb=no -q --json-report > $_TMP/qa-order-run-N.json`
**Go**: `go test ./... -shuffle=on -shuffleseed=$SEED -json > $_TMP/qa-order-run-N.json`

Use seeds: 42, 1337, 99999 (or generate via `$RANDOM`).

## Phase 3 — Analyze Order Dependencies

Compare results across all runs. Identify tests that:
- Pass in baseline but fail in some randomized orderings
- Consistently fail only after specific other tests (state leak)
- Show inconsistent pass/fail without obvious cause (timing)

For each order-dependent test: analyze what shared state could cause the dependency (global variables, database state, environment vars, module singletons, file system). Suggest `beforeEach`/`afterEach` isolation fixes.

## Phase N — Report

Write `$_TMP/qa-test-order-report-{_DATE}.md`:
- Order-dependent tests table: test name, fail rate (N/M runs), suspected state leak, fix suggestion
- Isolation dependency graph (text representation)

Write `$_TMP/qa-test-order-ctrf.json` (order-dependent tests = failed; stable tests = passed).

## Important Rules

- Each order-dependent test = one CTRF failed case; stable tests omitted from report
- Use `TEST_ORDER_RUNS=5` for higher confidence (more seeds)
- Use `TEST_ORDER_TIMEOUT` to bound total runtime per run
- If baseline fails: fix baseline failures before running order analysis
