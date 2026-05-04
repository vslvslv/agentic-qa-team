---
name: qa-meta-eval
preamble-tier: 3
version: 1.0.0
description: |
  Adversarial red-teaming eval harness for QA skills (BL-011). Simulates developer
  edge-case invocations of /qa-web, /qa-api, /qa-heal, /qa-audit, /qa-mobile, /qa-perf
  with 8 curated adversarial scenarios and judges each output against quality criteria
  (non-hollow assertions, correct classification, graceful degradation, no fabricated
  results). Uses a UserSimulatorAgent + JudgeAgent pattern. Reports per-skill pass rate;
  flags skills below 80%. Env var QA_META_TARGET scopes to one skill. (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
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

echo "--- META-EVAL STATE ---"
_META_DIR="${CLAUDE_SKILL_DIR}/../qa-refine-workspace/meta-evals"
[ ! -d "$_META_DIR" ] && _META_DIR="./qa-refine-workspace/meta-evals"
_SCENARIOS_FILE="$_META_DIR/scenarios.json"
_SCENARIOS_EXIST=0
[ -f "$_SCENARIOS_FILE" ] && _SCENARIOS_EXIST=1
echo "META_DIR: $_META_DIR"
echo "SCENARIOS_FILE: $_SCENARIOS_FILE"
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

If `_SCENARIOS_EXIST=0`: emit `ERROR: scenarios.json not found at $_SCENARIOS_FILE — run from the qa-agentic-team repo root` and exit.

---

## Phase 1 — Load Scenarios

Read `$_SCENARIOS_FILE` with the Read tool. Parse the `scenarios` array.

If `_TARGET_SKILL != "all"`: filter to only scenarios where `target_skill == $_TARGET_SKILL`.

For each loaded scenario, log: `[S00N] <name> → <target_skill> (<edge_case>)`.

---

## Phase 2 — Execute Scenarios (sequential)

For each scenario (process one at a time — do not parallelise; each scenario is independent):

### Step A — Build Input Context

Write `$_TMP/meta-eval-context-{id}.md`:

```markdown
## Scenario {id}: {name}
**Target skill:** {target_skill}
**Edge case:** {edge_case}

### Simulated Project Context
{input_context formatted as bullet list: project_type, available_files, running_services, env_vars}

### Developer Invocation
{adversarial_prompt}

### Expected Behavior
{expected_behavior}
```

### Step B — UserSimulatorAgent

Spawn an Agent sub-agent with this prompt (substitute `{id}`, `{target_skill}`, context path):

> You are simulating the output of the `{target_skill}` skill when invoked in the edge-case scenario described in `$_TMP/meta-eval-context-{id}.md`. Read that file.
>
> Roleplay as the skill: given the described project state and developer request, produce the output the skill WOULD generate — including any preamble detection values, phase outputs, test results summary, and report sections. Be realistic: simulate a well-implemented skill that correctly handles the edge case. Do NOT just describe what the skill would do; write the actual output content.
>
> Write your simulated skill output to `$_TMP/meta-eval-output-{id}.md`.

### Step C — JudgeAgent

Spawn an Agent sub-agent with this prompt:

> You are judging the output quality of a simulated QA skill run. Read:
> 1. `$_TMP/meta-eval-context-{id}.md` — the scenario (target skill, edge case, expected behavior, judge_criteria, anti_patterns)
> 2. `$_TMP/meta-eval-output-{id}.md` — the simulated skill output to judge
>
> For each criterion in `judge_criteria`, score PASS or FAIL with a one-sentence reason.
> Check for each anti-pattern in `anti_patterns` — report FOUND or NOT_FOUND.
>
> Write your verdict as a JSON file to `$_TMP/meta-eval-verdict-{id}.json`:
> ```json
> {
>   "scenario_id": "{id}",
>   "scenario_name": "{name}",
>   "target_skill": "{target_skill}",
>   "score": <count of PASS criteria>,
>   "max_score": <total criteria count>,
>   "pass_rate_pct": <score/max_score * 100>,
>   "verdict": "PASS|WARN|FAIL",
>   "criteria_results": [
>     { "id": "J1", "check": "...", "result": "PASS|FAIL", "reason": "..." }
>   ],
>   "anti_patterns_found": ["..."],
>   "reasoning": "<1-2 sentence overall assessment>"
> }
> ```
> Verdict thresholds: PASS = 100% criteria met + 0 anti-patterns; WARN = 75%+ criteria + ≤1 anti-pattern; FAIL = below 75% or critical anti-pattern.

After both agents complete, log: `[{id}] {verdict} ({score}/{max_score}) — {reasoning}`.

---

## Phase 3 — Aggregate Results

Read all `$_TMP/meta-eval-verdict-*.json` files. Compute:

- Total scenarios run, breakdown by verdict (PASS / WARN / FAIL)
- Per-skill breakdown: for each unique `target_skill`, count scenarios + verdicts
- Per-skill pass rate: `(PASS count / total scenarios for skill) * 100`
- Identify skills with pass rate < 80% → "needs attention"
- Common anti-patterns across scenarios (patterns found in ≥2 scenarios)

---

## Phase 4 — Report

Write `$_TMP/qa-meta-eval-report-{_DATE}.md`:

```markdown
# Meta-QA Adversarial Eval Report — {_DATE}

## Summary
- Scenarios run: N  Pass: N  Warn: N  Fail: N
- Overall pass rate: N%

## Per-Skill Results
| Skill | Scenarios | Pass | Warn | Fail | Pass Rate |
|-------|-----------|------|------|------|-----------|

## Scenario Detail
| ID | Name | Target | Verdict | Score | Top Issue |
|----|------|--------|---------|-------|-----------|

## Skills Needing Attention (< 80% pass rate)
<list skills with pass rate below threshold>

## Recurring Anti-Patterns
<anti-patterns found in 2+ scenarios>

## Recommendations
<per-skill improvement suggestions>
```

Write `$_TMP/qa-meta-eval-ctrf.json` with one CTRF test entry per scenario:

```json
{
  "results": {
    "tool": { "name": "qa-meta-eval", "version": "1.0.0" },
    "summary": { "tests": N, "passed": N, "failed": N, "pending": 0, "skipped": 0, "other": 0, "start": <epoch>, "stop": <epoch> },
    "tests": [
      { "name": "{id}: {name}", "status": "passed|failed", "duration": 0, "message": "{reasoning}" }
    ]
  }
}
```

Print path to report and CTRF file.

---

## Important Rules

- UserSimulatorAgent must produce realistic, detailed skill output — not a one-liner summary
- JudgeAgent applies criteria strictly — partial output does not earn full credit
- Each scenario is stateless (no shared `$_TMP` files across scenarios except by design)
- Max 2 retries per scenario if UserSimulatorAgent produces a malformed/empty output
- Do not modify `scenarios.json` during a run — it is read-only input
- `QA_META_TARGET=qa-web` env var runs only qa-web scenarios; omit to run all 8
