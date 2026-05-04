---
name: qa-meta-eval
description: |
  Adversarial red-teaming eval harness for QA skills (BL-011). Executes 8 curated
  edge-case scenarios against the QA skill suite: no-test-files, no-OpenAPI-spec,
  broken-selector, hollow-tests, zero-a11y-elements, server-unreachable,
  high-complexity-routing, timing-flakiness. Uses UserSimulatorAgent + JudgeAgent
  pattern. Reports per-skill pass rate; flags skills below 80% pass rate with
  specific anti-pattern findings. Env var QA_META_TARGET=<skill-name> to scope to
  one skill. Input: qa-refine-workspace/meta-evals/scenarios.json.
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
  - Agent
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

echo "--- META-EVAL STATE ---"
_META_DIR="${CLAUDE_SKILL_DIR}/../qa-refine-workspace/meta-evals"
[ ! -d "$_META_DIR" ] && _META_DIR="./qa-refine-workspace/meta-evals"
_SCENARIOS_FILE="$_META_DIR/scenarios.json"
_SCENARIOS_EXIST=0
[ -f "$_SCENARIOS_FILE" ] && _SCENARIOS_EXIST=1
echo "META_DIR: $_META_DIR"
echo "SCENARIOS_EXIST: $_SCENARIOS_EXIST"
if [ "$_SCENARIOS_EXIST" = "1" ]; then
  _SCENARIO_COUNT=$(python3 -c \
    "import json; d=json.load(open('$_SCENARIOS_FILE')); print(len(d['scenarios']))" \
    2>/dev/null || echo "?")
  echo "SCENARIO_COUNT: $_SCENARIO_COUNT"
fi
_TARGET_SKILL="${QA_META_TARGET:-all}"
echo "TARGET_SKILL: $_TARGET_SKILL"
echo "--- DONE ---"
```

If `_SCENARIOS_EXIST=0`: emit error and stop.

## Phase 1 — Load Scenarios

Read `$_SCENARIOS_FILE`. Filter by `_TARGET_SKILL` if not "all". Log each loaded scenario.

## Phase 2 — Execute Scenarios

For each scenario (sequential):

**Step A:** Write `$_TMP/meta-eval-context-{id}.md` with input_context + adversarial_prompt + expected_behavior.

**Step B — UserSimulatorAgent:** Spawn Agent:
> Read `$_TMP/meta-eval-context-{id}.md`. Roleplay as the `{target_skill}` skill.
> Given the described project state and developer request, produce the realistic output
> the skill WOULD generate for this edge case — preamble detection values, phase outputs,
> test results, report sections. Write output to `$_TMP/meta-eval-output-{id}.md`.

**Step C — JudgeAgent:** Spawn Agent:
> Read `$_TMP/meta-eval-context-{id}.md` (criteria + anti-patterns) and
> `$_TMP/meta-eval-output-{id}.md` (skill output to judge).
> For each judge_criterion: score PASS or FAIL with one-sentence reason.
> For each anti_pattern: report FOUND or NOT_FOUND.
> Write verdict JSON to `$_TMP/meta-eval-verdict-{id}.json`:
> `{ scenario_id, scenario_name, target_skill, score, max_score, pass_rate_pct,
>   verdict (PASS=100%+0 anti-patterns / WARN=75%+≤1 / FAIL=below 75% or critical anti-pattern),
>   criteria_results, anti_patterns_found, reasoning }`

Log result: `[{id}] {verdict} ({score}/{max_score})`.

## Phase 3 — Aggregate

Read all verdict JSONs. Compute total/pass/warn/fail. Per-skill pass rate. Flag < 80%.

## Phase 4 — Report

Write `$_TMP/qa-meta-eval-report-{_DATE}.md`:

```
# Meta-QA Adversarial Eval Report — <date>
## Summary: N scenarios, N% pass rate
## Per-Skill Results (table: skill / scenarios / pass / warn / fail / rate)
## Scenario Detail (table: id / name / target / verdict / score / top issue)
## Skills Needing Attention (< 80%)
## Recurring Anti-Patterns
## Recommendations
```

Write `$_TMP/qa-meta-eval-ctrf.json` (one CTRF test entry per scenario: passed|failed).

## Important Rules

- UserSimulatorAgent produces realistic detailed output — not one-liner summaries
- JudgeAgent applies criteria strictly — partial output does not earn full credit
- Each scenario is independent (no shared state)
- Max 2 retries if UserSimulatorAgent output is malformed/empty
- Do not modify scenarios.json during a run
