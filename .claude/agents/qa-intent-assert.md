---
name: qa-intent-assert
description: |
  Natural-language code property assertions via LLM judge. Reads *.intent.yaml files from
  the project defining plain-English properties that code must satisfy, then evaluates each
  assertion against the target code using an LLM judge. Novel assertion paradigm that catches
  semantic intent violations that unit tests miss.
  Env vars: INTENT_STRICT, INTENT_DIR.
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

_INTENT_STRICT="${INTENT_STRICT:-0}"
_INTENT_DIR="${INTENT_DIR:-.}"
echo "INTENT_STRICT: $_INTENT_STRICT  (0=warn, 1=fail on violation)"
echo "INTENT_DIR: $_INTENT_DIR"

_INTENT_FILES=$(find "$_INTENT_DIR" -name "*.intent.yaml" -not -path "*/node_modules/*" 2>/dev/null | tr '\n' ' ')
_INTENT_COUNT=$(echo "$_INTENT_FILES" | wc -w | tr -d ' ')
echo "INTENT_FILES_FOUND: $_INTENT_COUNT"
echo "--- DONE ---"
```

If `INTENT_FILES_FOUND: 0`, emit WARN and exit gracefully — project may not use intent assertions yet.

## Intent File Format

```yaml
# example.intent.yaml
assertions:
  - id: "INT-001"
    assertion: "This function must never return a negative balance"
    target: "src/billing/calculateBalance.ts:calculateBalance"
    severity: "error"  # error | warning
  - id: "INT-002"
    assertion: "The user password must never appear in log output"
    target: "src/auth/login.ts"
    severity: "error"
```

## Phase 1 — Parse Intent Files

Read all `*.intent.yaml` files. Build assertion list with: id, assertion text, target file/function, severity.

## Phase 2 — LLM Judge Evaluation

For each assertion:
1. Read the target file/function (use grep + Read to extract the relevant code section)
2. Submit to LLM judge: "Given this code, does it satisfy this property: '{assertion}'? Reply with PASS, FAIL, or UNCERTAIN and a one-sentence rationale."
3. Record verdict and rationale

## Phase 3 — Apply Strict Mode

- `INTENT_STRICT=0`: FAIL verdicts become CTRF `skipped` (warnings)
- `INTENT_STRICT=1`: FAIL verdicts become CTRF `failed` (blocks CI)
- UNCERTAIN verdicts always become CTRF `skipped` regardless of strict mode

## Phase N — Report

Write `$_TMP/qa-intent-assert-report-{_DATE}.md`: per-assertion table with verdict, rationale, target code excerpt.

Write `$_TMP/qa-intent-assert-ctrf.json` (each assertion = one test).

## Important Rules

- UNCERTAIN verdict = judge could not determine from code alone; add context or rewrite assertion
- Keep assertions atomic and falsifiable — "never", "always", "must" are good signal words
- Use `INTENT_DIR=src/billing` to scope to a specific subsystem
