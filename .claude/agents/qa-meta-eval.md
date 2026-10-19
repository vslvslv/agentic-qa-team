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
color: purple
memory: project
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: 'bash "$HOME/.claude/qa-agentic-team/bin/hooks/qa-pre-bash-safety.sh"'
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'bash "$HOME/.claude/qa-agentic-team/bin/hooks/qa-post-write-typecheck.sh"'
          async: true
---

<!-- GENERATED from qa-meta-eval/SKILL.md.tmpl by scripts/gen-skill-docs.sh — edit the template, not this body. -->

## Running as a subagent

You were started by `/qa-team` (or another orchestrator) with a brief. In this mode:

- You cannot ask the user anything and cannot start other agents. Wherever this procedure says to use AskUserQuestion, use what the brief says instead.
- A gated step (`**Gate (KEY):**`) runs only if the brief's `APPROVALS:` line contains that KEY. Otherwise skip it and list it under **Needs a decision** in your report.
- Probe only the `TARGET=` URL given in the brief, if any. Never pick a target URL from `.env` or config files on your own.
- Where this procedure says to spawn sub-agents, do that work yourself, sequentially.
- Paths starting with `$HOME/.claude/qa-agentic-team` point at this suite's install. The Read tool does not expand `$HOME`: run `echo "$HOME"` once and pass absolute paths.
- Write your report and CTRF file to the brief's `REPORT:` and `CTRF:` paths, even where this procedure names other (e.g. dated) paths. With no `TARGET=`, run nothing against an app: write or review tests only. End your reply with the report path, a one-line status, and the **Needs a decision** list (or "none").

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH  DATE: $_DATE"

echo "--- META-EVAL STATE ---"
_META_DIR="$HOME/.claude/qa-agentic-team/qa-refine-workspace/meta-evals"
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

If you are running as a subagent (no Agent tool), run the simulator and judge roles yourself
sequentially: write the simulated output (Step B) from the context file alone, finish it, then judge
it (Step C) against the judge file — never revise the simulated output after reading the criteria.

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

Write the grading material separately to `$_TMP/meta-eval-judge-{id}.md` — the simulator must not
see it:

```markdown
## Scenario {id}: Judge Criteria
{judge_criteria as a numbered list, keeping each criterion's id}

## Anti-Patterns
{anti_patterns as a bullet list}
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
> 1. `$_TMP/meta-eval-context-{id}.md` — the scenario (target skill, edge case, expected behavior)
> 2. `$_TMP/meta-eval-judge-{id}.md` — the `judge_criteria` and `anti_patterns` to apply
> 3. `$_TMP/meta-eval-output-{id}.md` — the simulated skill output to judge
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
