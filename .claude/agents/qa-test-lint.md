---
name: qa-test-lint
description: |
  Test smell and anti-pattern linter. Statically scans test files for known quality issues:
  assertion-free tests, sleep() calls, magic numbers, permanently skipped tests, empty
  describe blocks, console.log leakage, and copy-paste test bodies. LLM categorizes each
  smell by type and severity and generates inline fix suggestions.
  Env vars: TEST_LINT_SEVERITY.
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
_LINT_SEVERITY="${TEST_LINT_SEVERITY:-warn}"
echo "TEST_LINT_SEVERITY: $_LINT_SEVERITY"

# Discover test files
_TEST_FILES=$(find . \( -name "*.test.ts" -o -name "*.test.js" -o -name "*.spec.ts" -o -name "*.spec.js" -o -name "*.test.py" -o -name "*_test.go" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -200)
_TEST_COUNT=$(echo "$_TEST_FILES" | grep -c '\.' 2>/dev/null || echo 0)
echo "TEST_FILES_FOUND: $_TEST_COUNT"
echo "--- DONE ---"
```

## Phase 1 — Static Smell Detection

For each discovered test file, scan for these smell patterns:

**Sleep/wait hardcoding**: `sleep(`, `setTimeout(`, `await new Promise(r => setTimeout`, `time.sleep(`
**Assertion-free tests**: test body with no `expect(`, `assert`, `should.`, `toBe`, `toEqual`, `assertEqual`
**Permanent skips**: `describe.skip(`, `it.skip(`, `test.skip(`, `xit(`, `xdescribe(`, `pytest.mark.skip`, `t.Skip(`
**Empty describe blocks**: `describe(` followed immediately by `})` with no `it`/`test` inside
**Console leakage**: `console.log(`, `console.error(`, `print(` in test files (outside setup/teardown)
**Magic numbers/strings**: hardcoded port numbers, UUIDs, long numeric literals not assigned to named constants
**Duplicate test bodies**: identical or near-identical test function bodies (copy-paste)
**Overly broad assertions**: `.toBe(true)`, `.toBeTruthy()` without more specific assertion available

For each finding record: file path, line number, smell type, code excerpt (1-3 lines).

## Phase 2 — LLM Categorization and Fix Suggestions

For each detected smell, generate:
- **Severity**: error (blocks CI) or warn — based on `TEST_LINT_SEVERITY` and smell type (sleep/assertion-free = error; skips/console = warn)
- **Category**: correctness | maintainability | reliability | readability
- **Fix suggestion**: one-line inline fix or refactoring note

Group findings by smell type for the report.

## Phase N — Report

Write `$_TMP/qa-test-lint-report-{_DATE}.md`:
- Summary counts: total smells by type and severity
- Table: file → smell type → line → severity → fix suggestion
- Top 5 files by smell density

Write `$_TMP/qa-test-lint-ctrf.json` (each smell instance = one CTRF test; error severity = failed, warn = passed with message).

## Important Rules

- Each smell instance = one CTRF test case
- `TEST_LINT_SEVERITY=error` treats all smells as failures; `warn` (default) only marks assertion-free and sleep() as errors
- Never auto-fix smells — only suggest; fixes require human review
- Ignore test helper/fixture files (files in `__fixtures__`, `__mocks__`, `helpers/`) from smell detection
- A test with `expect.assertions(N)` is not assertion-free even if no explicit expect() calls follow
