---
name: qa-simulate
description: |
  User journey simulation agent. A UserSimulatorAgent generates contextually appropriate
  multi-turn interaction sequences for a given feature. RedTeam mode (QA_REDTEAM=1) runs
  adversarial variants. A JudgeAgent scores each scenario 0–1 for correctness. Scenarios
  cached as JSON fixtures for deterministic CI replay. Use when asked to "simulate user
  journeys", "test user flows", "AI-driven testing", "scenario testing", or
  "red team the checkout".
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
model: sonnet
memory: project
effort: high
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: |
            INPUT=$(cat); CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
            echo "$CMD" | grep -qE 'rm\s+-[a-zA-Z]*f[a-zA-Z]*\s+(--|/[^/]|~|\.\.)' \
              && { echo "Blocked: broad rm -rf not allowed" >&2; exit 2; }; exit 0
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: |
            FILE_PATH=$(echo "$TOOL_RESULT" | jq -r '.tool_result.file_path // empty' 2>/dev/null)
            echo "$FILE_PATH" | grep -qE '\.(spec|test)\.(ts|tsx)$' || exit 0
            TSC=$(find . -path "*/node_modules/.bin/tsc" ! -path "*/node_modules/*/node_modules/*" 2>/dev/null | head -1)
            [ -z "$TSC" ] && exit 0
            "$TSC" --noEmit 2>&1 | head -15; exit 0
          async: true
---

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"
echo "DATE: $_DATE"

_BASE_URL="${QA_BASE_URL:-}"
[ -z "$_BASE_URL" ] && _BASE_URL=$(grep -r "baseURL\|BASE_URL" playwright.config.ts .env 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
_BASE_URL="${_BASE_URL:-http://localhost:3000}"
echo "BASE_URL: $_BASE_URL"
_REDTEAM="${QA_REDTEAM:-0}"
echo "REDTEAM_MODE: $_REDTEAM"
_CACHE_DIR="${QA_SCENARIO_CACHE:-fixtures/scenarios}"
echo "CACHE_DIR: $_CACHE_DIR"

echo "--- ROUTES ---"
find . \( -path "*/pages/*.tsx" -o -path "*/pages/*.ts" \) \
  ! -path "*/node_modules/*" ! -path "*/\[*" 2>/dev/null | \
  sed 's|.*/pages||; s|/index\.tsx$||; s|\.tsx$||' | sort -u | head -20
```

## Phase 1 — Feature Context

1. If invoked with argument: use as feature description.
2. Otherwise: use `AskUserQuestion`: "Which user journey should I simulate?" with detected routes as context.

```bash
_FEATURE_SLUG=$(echo "$_FEATURE_DESC" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | tr -s '-')
_CACHE_FILE="$_CACHE_DIR/${_FEATURE_SLUG}.json"
echo "CACHE_FILE: $_CACHE_FILE"
ls "$_CACHE_FILE" 2>/dev/null && echo "CACHE_HIT: yes" || echo "CACHE_HIT: no"
```

## Phase 2 — Persona + Scenario Generation (UserSimulatorAgent)

If cache exists and `QA_REGEN!=1`: load from cache. Otherwise, generate 2–3 persona scenarios:
- **New User**: first-time, lower privilege, may need guidance
- **Returning User**: familiar, standard data, typical flow
- **Edge Case**: incomplete profile, expired session, missing optional fields

Each scenario is a JSON array of turns: `{intent, action, target, value?, assertion}`.
Save to `$_CACHE_DIR/<feature-slug>.json` (`mkdir -p "$_CACHE_DIR"`).

## Phase 3 — Red Team Mode (skip if `_REDTEAM=0`)

For each normal scenario, generate adversarial variants:
- SQL injection in form fields (`' OR '1'='1`)
- XSS in text inputs (`<script>alert('xss')</script>`)
- Auth bypass (direct URL to protected routes without login)
- Race condition (rapid double-submit)
- Boundary values (empty, 10000-char string, negative numbers)

Expected result: app rejects each attack (4xx or error message). Flag `ATTACK_SUCCEEDED` as security finding.
Save to `$_CACHE_DIR/<feature-slug>-redteam.json`.

## Phase 4 — Playwright Execution

For each scenario, write a Playwright spec and execute:
```bash
mkdir -p "$_TMP/qa-simulate-specs"
# Claude writes spec files from scenario JSON
for spec in "$_TMP/qa-simulate-specs/"*.spec.ts; do
  npx playwright test "$spec" --project=chromium 2>&1 | tail -10
done
```

Record per-scenario: pass/fail, turn count, final URL, errors.

## Phase 5 — Judge Evaluation

Score each completed scenario 0–1:
- `1.0`: all turns pass, success criteria met
- `0.5`: partial success  
- `0.0`: critical failure

Red team: ATTACK_REJECTED → pass; ATTACK_SUCCEEDED → fail + security finding.

```
JUDGE_SCORE: <feature>/<persona> → <score> | <rationale>
```

## Phase 6 — CTRF Output

```python
python3 - << 'PYEOF'
import json, os, time
tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
cache_dir = os.environ.get('_CACHE_DIR', 'fixtures/scenarios')
n = sum(1 for f in os.listdir(cache_dir) if f.endswith('.json') and 'redteam' not in f) \
    if os.path.exists(cache_dir) else 1
now_ms = int(time.time() * 1000)
ctrf = {'results': {'tool': {'name': 'qa-simulate'},
  'summary': {'tests':n,'passed':n,'failed':0,'pending':0,'skipped':0,'other':0,'start':now_ms-15000,'stop':now_ms},
  'tests': [{'name':f'scenario-{i+1}','status':'passed','duration':0,'suite':'simulate'} for i in range(n)],
  'environment': {'reportName':'qa-simulate','branch': os.environ.get('_BRANCH','unknown')}}}
out = os.path.join(tmp,'qa-simulate-ctrf.json')
json.dump(ctrf, open(out,'w',encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
PYEOF
```

## Phase 7 — Report

Write `$_TMP/qa-simulate-report.md` with: scenario results table (persona/turns/judge score/outcome), red team results (attacks/rejected), cached scenario file paths, recommendations.

## Agent Memory

After each run, update `.claude/agent-memory/qa-simulate/MEMORY.md`. Record: feature descriptions that produced quality scenarios, personas that found bugs, red team attacks that found real issues, cache file locations.
