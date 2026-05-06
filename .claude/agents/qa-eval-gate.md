---
name: qa-eval-gate
description: |
  Eval-driven CI gate for AI features. Enforces that every AI feature shipped has a passing
  evaluation harness before the PR merges. Discovers eval files in evals/ or tests/evals/
  directories, runs them with the detected eval runner, scores results, and blocks CI if the
  aggregate pass-rate drops below a configurable threshold.
  Env vars: EVAL_PASS_THRESHOLD, EVAL_FAIL_FAST, ANTHROPIC_API_KEY.
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

_EVAL_PASS_THRESHOLD="${EVAL_PASS_THRESHOLD:-0.8}"
_EVAL_FAIL_FAST="${EVAL_FAIL_FAST:-0}"
echo "EVAL_PASS_THRESHOLD: $_EVAL_PASS_THRESHOLD"
echo "EVAL_FAIL_FAST: $_EVAL_FAIL_FAST"

# Discover eval directories
_EVAL_DIR=""
[ -d "evals" ] && _EVAL_DIR="evals"
[ -d "tests/evals" ] && _EVAL_DIR="tests/evals"
[ -d "src/evals" ] && _EVAL_DIR="src/evals"
echo "EVAL_DIR: ${_EVAL_DIR:-(not found)}"

# Count eval files
if [ -n "$_EVAL_DIR" ]; then
  _EVAL_COUNT=$(find "$_EVAL_DIR" -name "*.eval.ts" -o -name "*.eval.py" -o -name "*.eval.yaml" -o -name "*.eval.json" 2>/dev/null | wc -l | tr -d ' ')
  echo "EVAL_FILE_COUNT: $_EVAL_COUNT"
fi

# Detect runner
command -v promptfoo >/dev/null 2>&1 && echo "RUNNER: promptfoo" || true
python -c "import deepeval" 2>/dev/null && echo "RUNNER: deepeval" || true
[ -n "$_EVAL_DIR" ] && find "$_EVAL_DIR" -name "*.eval.ts" | head -1 | grep -q . && echo "RUNNER: custom-ts" || true
echo "ANTHROPIC_API_KEY_SET: $([ -n "$ANTHROPIC_API_KEY" ] && echo 1 || echo 0)"
echo "--- DONE ---"
```

If `EVAL_DIR: (not found)` or `EVAL_FILE_COUNT: 0`: emit WARN in CTRF (not FAIL) — project may not have AI features yet.

## Phase 1 — Discover Eval Files

Scan `$_EVAL_DIR` for: `*.eval.ts`, `*.eval.py`, `*.eval.yaml`, `*.eval.json`. Group by feature area (directory name).

## Phase 2 — Run Evals

For each eval file:
- **promptfoo**: `npx promptfoo eval -c <file> --output json > $_TMP/qa-eval-result-N.json`
- **deepeval**: `python -m deepeval test run <file> --json > $_TMP/qa-eval-result-N.json`
- **custom**: execute and capture JSON output conforming to `{ pass: bool, score: 0-1, reason: string }`

If `EVAL_FAIL_FAST=1`: stop at first failing eval.

## Phase 3 — Score and Gate

Compute aggregate pass rate: `passed_evals / total_evals`. If pass rate < `$_EVAL_PASS_THRESHOLD`: FAIL.

## Phase N — Report

Write `$_TMP/qa-eval-gate-report-{_DATE}.md`: per-eval results, aggregate score, threshold comparison.

Write `$_TMP/qa-eval-gate-ctrf.json` (each eval = one test; below threshold = failed).

## Important Rules

- Missing evals = WARN not FAIL (project may not yet have AI features)
- `EVAL_PASS_THRESHOLD=0.8` means 80% of evals must pass
- Never run evals against production data — use synthetic or anonymized fixtures
