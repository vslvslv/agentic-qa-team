---
name: qa-test-docs
description: |
  Test documentation generator. Reads existing test files and generates human-readable
  Markdown documentation summarizing what each test suite covers, which business rules
  it guards, which edge cases are addressed, and notable gaps. Groups tests by feature
  domain. Output is suitable for compliance audits, sprint reviews, and onboarding.
  Env vars: TEST_DOCS_OUTPUT, TEST_DOCS_FORMAT.
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

_TEST_FILES=$(find . -type f \( \
  -name "*.test.ts" -o -name "*.spec.ts" \
  -o -name "*.test.js" -o -name "*.spec.js" \
  -o -name "*_test.py" -o -name "*_test.go" \
  -o -name "*Test.java" -o -name "*Spec.rb" \
\) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null)
_TEST_FILE_COUNT=$(echo "$_TEST_FILES" | grep -c . 2>/dev/null || echo 0)
echo "TEST_FILE_COUNT: $_TEST_FILE_COUNT"

_TEST_DOCS_OUTPUT="${TEST_DOCS_OUTPUT:-./test-docs}"
_TEST_DOCS_FORMAT="${TEST_DOCS_FORMAT:-markdown}"
echo "OUTPUT_DIR: $_TEST_DOCS_OUTPUT"
echo "FORMAT: $_TEST_DOCS_FORMAT"
echo "$_TEST_FILES" > "$_TMP/qa-docs-test-files.txt"
echo "--- DONE ---"
```

## Phase 1 — Cluster by Domain

Group test files by parent directory / feature name. Each cluster becomes one documentation page. Use LLM to infer the business domain from directory name + test file names.

## Phase 2 — Generate Per-Cluster Documentation

For each cluster, read all test files. Generate a Markdown doc containing:
- **What is tested**: one-line summaries of each describe/test block
- **Business rules guarded**: rules inferred from assertion names and test data
- **Edge cases covered**: boundary conditions, error paths, negative tests
- **Notable gaps**: business logic areas likely missing test coverage

## Phase 3 — Write Output Files

Write one `{domain}-tests.md` per cluster to `$_TEST_DOCS_OUTPUT/`. Write `$_TEST_DOCS_OUTPUT/index.md` with links to all cluster docs.

## Phase N — Report

Write `$_TMP/qa-test-docs-report-{_DATE}.md`: summary of clusters, file count per cluster, output paths.

Write `$_TMP/qa-test-docs-ctrf.json` (each cluster = one passed test; empty cluster = skipped).

## Important Rules

- Never modify test files — read-only documentation generation
- Use `TEST_DOCS_OUTPUT` to control output directory (default `./test-docs/`)
- Use `TEST_DOCS_FORMAT=confluence` for Confluence wiki markup output
- Gap analysis is LLM inference — label as "suggested" not "confirmed"
