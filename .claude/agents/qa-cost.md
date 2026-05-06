---
name: qa-cost
description: |
  AI API cost tracking and budget gate. Reads token usage metadata from CTRF output files
  produced by qa-* skills, computes estimated cost per skill using current Claude model
  pricing, and can block CI if the total run cost exceeds a configured budget. Provides
  financial observability alongside functional QA observability.
  Env vars: QA_COST_BUDGET, QA_COST_MODEL.
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

_CTRF_FILES=$(ls "$_TMP"/qa-*-ctrf.json 2>/dev/null | grep -v 'qa-cost-ctrf' | tr '\n' ' ')
_CTRF_COUNT=$(echo "$_CTRF_FILES" | wc -w | tr -d ' ')
echo "CTRF_FILES_FOUND: $_CTRF_COUNT"

_COST_BUDGET="${QA_COST_BUDGET:-}"
_COST_MODEL="${QA_COST_MODEL:-claude-sonnet-4-6}"
echo "COST_BUDGET: ${_COST_BUDGET:-not set (reporting only)}"
echo "COST_MODEL: $_COST_MODEL"

# Pricing map (per million tokens, input/output)
# claude-opus-4-7: $15/$75  claude-sonnet-4-6: $3/$15  claude-haiku-4-5: $0.80/$4
echo "PRICING: sonnet-4-6=$3/$15, haiku-4-5=$0.80/$4, opus-4-7=$15/$75 (per MTok in/out)"
echo "--- DONE ---"
```

## Phase 1 — Extract Token Usage

For each CTRF file: check `results.tool.custom.tokens_input` and `results.tool.custom.tokens_output` metadata fields. If not present, use LLM estimation based on skill type and test count (estimate: 5K input / 2K output tokens per test on average).

## Phase 2 — Compute Cost Per Skill

For each skill:
```
cost = (tokens_input / 1_000_000) * INPUT_PRICE + (tokens_output / 1_000_000) * OUTPUT_PRICE
```
Use pricing for `$_COST_MODEL`. Sum to get total run cost.

## Phase 3 — Budget Gate

If `QA_COST_BUDGET` is set and total > budget: mark overall as FAIL. Print `COST_OVER_BUDGET: true`.

## Phase N — Report

Write `$_TMP/qa-cost-report-{_DATE}.md`:
- Per-skill cost breakdown table: skill | input tokens | output tokens | estimated cost
- Total cost, budget comparison
- Trend: compare vs previous run if `$_TMP/qa-cost-prev.json` exists

Write `$_TMP/qa-cost-ctrf.json` (each skill = one test; over budget = failed, within budget = passed).

## Important Rules

- Cost is estimated when CTRF metadata lacks token counts — mark as estimated in report
- `QA_COST_BUDGET` in USD; leave unset for reporting-only mode (no gate)
- Update pricing constants when Claude API pricing changes
