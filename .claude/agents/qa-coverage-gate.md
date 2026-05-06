---
name: qa-coverage-gate
description: |
  Test coverage delta gate. Runs the project's coverage tooling, computes per-file
  coverage change between the current branch and the base branch, and blocks CI if
  changed files drop below a configurable threshold. For files below threshold,
  generates LLM-suggested test stubs targeting the specific uncovered lines.
  Env vars: COVERAGE_THRESHOLD, COVERAGE_COMPARE_BRANCH, COVERAGE_GENERATE_STUBS.
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

_COVERAGE_TOOL="unknown"
[ -f "package.json" ] && grep -q '"jest"' package.json 2>/dev/null && _COVERAGE_TOOL="jest"
[ -f "package.json" ] && grep -q '"vitest"' package.json 2>/dev/null && _COVERAGE_TOOL="vitest"
{ [ -f "pyproject.toml" ] && grep -q "pytest-cov" pyproject.toml 2>/dev/null; } && _COVERAGE_TOOL="pytest"
[ -f "go.mod" ] && _COVERAGE_TOOL="go"
echo "COVERAGE_TOOL: $_COVERAGE_TOOL"

_COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"
_COMPARE_BRANCH="${COVERAGE_COMPARE_BRANCH:-main}"
_GENERATE_STUBS="${COVERAGE_GENERATE_STUBS:-1}"
echo "COVERAGE_THRESHOLD: $_COVERAGE_THRESHOLD%"
echo "COMPARE_BRANCH: $_COMPARE_BRANCH"
echo "GENERATE_STUBS: $_GENERATE_STUBS"

_CHANGED_FILES=$(git diff --name-only "$_COMPARE_BRANCH"...HEAD 2>/dev/null \
  | grep -E '\.(ts|js|tsx|jsx|py|go|cs|java|rb)$' \
  | grep -v -E '\.(test|spec)\.' | grep -v -E '_(test|spec)\.' | grep -v -E 'Test\.|Spec\.')
_CHANGED_FILES_COUNT=$(echo "$_CHANGED_FILES" | grep -c . 2>/dev/null || echo 0)
echo "CHANGED_SOURCE_FILES: $_CHANGED_FILES_COUNT"
echo "--- DONE ---"
```

## Phase 1 — Run Coverage

Run coverage for the current branch:
- **Jest**: `npx jest --coverage --coverageReporters=json > /dev/null && cat coverage/coverage-summary.json`
- **Vitest**: `npx vitest run --coverage --coverage.reporter=json && cat coverage/coverage-summary.json`
- **Pytest**: `python -m pytest --cov=. --cov-report=json && cat coverage.json`
- **Go**: `go test ./... -coverprofile=$_TMP/qa-cov.out && go tool cover -func=$_TMP/qa-cov.out`

Save result to `$_TMP/qa-coverage-current.json`.

## Phase 2 — Compute Delta

For each changed source file: extract coverage percentage from current run. Compare against `$_COVERAGE_THRESHOLD`. Mark as `PASS` or `FAIL`. Identify specific uncovered line ranges for FAIL files.

## Phase 3 — Generate Stubs (if COVERAGE_GENERATE_STUBS=1)

For each file below threshold: read the file, identify uncovered lines, generate a test stub file with TODO comments pointing to the uncovered functions/branches. Write to `$_TMP/qa-cov-stubs-{filename}.ts`.

## Phase N — Report

Write `$_TMP/qa-coverage-gate-report-{_DATE}.md`: per-file coverage table, files below threshold, stub file locations.

Write `$_TMP/qa-coverage-gate-ctrf.json` (each changed file = one test; below threshold = failed).

## Important Rules

- Only gates on changed files (delta) — not the entire codebase
- `COVERAGE_THRESHOLD=80` (default) — set per project needs
- Stubs are suggestions only — never auto-commit generated test files
- If no coverage tool detected, use AskUserQuestion to clarify
