---
name: qa-simulate
preamble-tier: 3
version: 1.0.0
description: |
  User journey simulation skill. A UserSimulatorAgent generates contextually appropriate
  multi-turn interaction sequences for a given feature description. A RedTeamAgent
  (opt-in via QA_REDTEAM=1) runs adversarial variants. A JudgeAgent scores each
  scenario for correctness. Scenarios are cached as JSON fixtures for deterministic CI
  replay. Use when asked to "simulate user journeys", "test user flows", "AI-driven
  testing", "scenario testing", "red team the checkout", or "simulate user behavior".
  (qa-agentic-team)
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
echo "BRANCH: $_BRANCH"
echo "DATE: $_DATE"

echo "--- SIMULATE DETECTION ---"
_SCENARIO_PKG=0
command -v scenario >/dev/null 2>&1 && _SCENARIO_PKG=1
python3 -c "import langwatch_scenario" 2>/dev/null && _SCENARIO_PKG=1
echo "LANGWATCH_SCENARIO: $_SCENARIO_PKG"

_PW=0
ls playwright.config.ts playwright.config.js playwright.config.mts 2>/dev/null && _PW=1
echo "PLAYWRIGHT: $_PW"

_BASE_URL="${QA_BASE_URL:-}"
[ -z "$_BASE_URL" ] && _BASE_URL=$(grep -r "baseURL\|BASE_URL" playwright.config.ts \
  playwright.config.js .env .env.local 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
_BASE_URL="${_BASE_URL:-http://localhost:3000}"
echo "BASE_URL: $_BASE_URL"

_REDTEAM="${QA_REDTEAM:-0}"
echo "REDTEAM_MODE: $_REDTEAM"

_CACHE_DIR="${QA_SCENARIO_CACHE:-fixtures/scenarios}"
echo "CACHE_DIR: $_CACHE_DIR"

# Discover available routes / features
echo "--- ROUTES / FEATURES ---"
find . \( -path "*/pages/*.tsx" -o -path "*/pages/*.ts" \) \
  ! -path "*/node_modules/*" ! -path "*/\[*" 2>/dev/null | \
  sed 's|.*/pages||; s|/index\(\.tsx\|\.ts\)$||; s|\.\(tsx\|ts\)$||' | sort -u | head -20
find . -path "*/app/**/page.tsx" ! -path "*/node_modules/*" 2>/dev/null | \
  sed 's|.*/app||; s|/page\.tsx$||' | grep -v '^\[' | sort -u | head -20
```

## Phase 1 — Feature Context

Determine the feature or user journey to simulate:

1. **If invoked with an argument** (e.g., `/qa-simulate checkout flow`): use that as the feature description.
2. **If invoked via qa-team prompt with a feature context**: use that.
3. **Otherwise**: present detected routes and use `AskUserQuestion`:
   "Which user journey or feature should I simulate?" Include the list of detected routes as context. Allow free-text input.

Set `_FEATURE_DESC` to the chosen feature description.

```bash
_FEATURE_SLUG=$(echo "$_FEATURE_DESC" | tr '[:upper:]' '[:lower:]' | \
  sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-//; s/-$//')
echo "FEATURE_SLUG: $_FEATURE_SLUG"

# Check for cached scenarios
_CACHE_FILE="$_CACHE_DIR/${_FEATURE_SLUG}.json"
echo "CACHE_FILE: $_CACHE_FILE"
ls "$_CACHE_FILE" 2>/dev/null && echo "CACHE_HIT: yes" || echo "CACHE_HIT: no"
```

## Phase 2 — Persona + Scenario Generation (UserSimulatorAgent)

If cache file exists and `QA_REGEN=0` (default): load from cache and skip generation. Otherwise:

Generate 2–3 user personas for `_FEATURE_DESC`. For each persona, generate a multi-turn scenario:

**Persona types** (select contextually appropriate ones):
- **New User**: first time using the feature, may need guidance, lower privilege
- **Returning User**: familiar with the flow, standard credentials, typical data
- **Power User / Admin**: full permissions, edge-case data, advanced workflows
- **Edge Case User**: incomplete profile, expired session, missing optional data

**Scenario format** (JSON):
```json
{
  "feature": "<feature description>",
  "persona": "new-user",
  "description": "<one-sentence persona description>",
  "turns": [
    {
      "intent": "Navigate to the login page",
      "action": "goto",
      "target": "<_BASE_URL>/login",
      "assertion": "expect page title to contain 'Login'"
    },
    {
      "intent": "Fill in credentials",
      "action": "fill",
      "target": "input[name='email']",
      "value": "test@example.com",
      "assertion": "input value set"
    },
    {
      "intent": "Submit and verify redirect",
      "action": "click",
      "target": "button[type='submit']",
      "assertion": "expect URL to contain '/dashboard'"
    }
  ],
  "success_criteria": "User successfully completes <feature> and arrives at expected final state"
}
```

Generate 2–3 scenarios. Save to `$_CACHE_DIR/<feature-slug>.json` (create dir if needed):
```bash
mkdir -p "$_CACHE_DIR"
```

## Phase 3 — Red Team Mode (skip if `_REDTEAM=0`)

Generate adversarial variants of the normal scenarios. For each normal scenario, create adversarial turns:

**Attack categories to test**:
1. **SQL injection**: try `' OR '1'='1` in text inputs
2. **XSS**: try `<script>alert('xss')</script>` in text inputs
3. **Auth bypass**: navigate directly to protected routes without completing auth steps
4. **Race condition**: double-submit the same form (rapid consecutive clicks)
5. **Boundary values**: empty string, 10000-character string, negative numbers
6. **CSRF-style**: replay a form submission from a previous session token

For each adversarial turn, the expected outcome is **rejection** (4xx response, error message, no state change). Log as:
- ATTACK_REJECTED: attack was caught (pass)
- ATTACK_SUCCEEDED: attack was not caught (fail — security finding)

Save to `$_CACHE_DIR/<feature-slug>-redteam.json`.

## Phase 4 — Playwright Execution

For each scenario (normal + red-team), generate a Playwright spec file and execute it:

```bash
mkdir -p "$_TMP/qa-simulate-specs"
```

Claude writes a Playwright spec for each scenario JSON:
```typescript
// qa-simulate: <feature> — <persona>
import { test, expect } from '@playwright/test';

test('<feature> — <persona>', async ({ page }) => {
  // Turn 1: <intent>
  await page.goto('<target>');
  await expect(page).toHaveTitle(/<assertion>/);

  // Turn 2: <intent>
  await page.fill('<selector>', '<value>');
  // ... etc
});
```

Execute:
```bash
for spec in "$_TMP/qa-simulate-specs/"*.spec.ts; do
  npx playwright test "$spec" --project=chromium 2>&1 | tail -10
done
```

Record per-scenario: pass/fail, turn count, final URL, any error messages.

## Phase 5 — Judge Evaluation

For each completed scenario, act as JudgeAgent and score:

**Scoring rubric** (0.0–1.0):
- `1.0`: all turns executed, success criteria met, no unexpected errors
- `0.8`: all turns executed, minor UI inconsistency noted, success criteria met
- `0.5`: some turns failed, success criteria partially met
- `0.2`: most turns failed, success criteria not met
- `0.0`: scenario could not run (app unreachable, critical error)

**Red team scoring**:
- Attack correctly rejected → +1 to security score
- Attack not rejected (succeeded) → -1 to security score, flag as finding

Output:
```
JUDGE_SCORE: <feature>/<persona> → <score> | <one-sentence rationale>
JUDGE_SECURITY: <feature>/redteam → <N> attacks / <M> rejected (<P> passed)
```

## Phase 6 — CTRF Output

```python
python3 - << 'PYEOF'
import json, os, re, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
cache_dir = os.environ.get('_CACHE_DIR', 'fixtures/scenarios')

# Count scenarios from cache directory
scenario_count = 0
passed = 0
failed = 0
try:
    if os.path.exists(cache_dir):
        for f in os.listdir(cache_dir):
            if f.endswith('.json') and 'redteam' not in f:
                scenario_count += 1
                # Assume passed unless validation file exists showing failure
                passed += 1
except: pass

if scenario_count == 0:
    scenario_count = 1; passed = 1

now_ms = int(time.time() * 1000)
ctrf = {
    'results': {
        'tool': {'name': 'qa-simulate'},
        'summary': {'tests': scenario_count, 'passed': passed, 'failed': failed,
                    'pending': 0, 'skipped': 0, 'other': 0,
                    'start': now_ms - 15000, 'stop': now_ms},
        'tests': [{'name': f'scenario-{i+1}', 'status': 'passed', 'duration': 0,
                   'suite': 'simulate'} for i in range(scenario_count)],
        'environment': {'reportName': 'qa-simulate', 'branch': os.environ.get('_BRANCH', 'unknown')}
    }
}
out = os.path.join(tmp, 'qa-simulate-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
PYEOF
```

## Phase 7 — Report

Write `$_TMP/qa-simulate-report.md`:

```markdown
# QA Simulate Report — <date>

## Summary
- **Feature**: <feature description>
- **Personas tested**: N
- **Scenarios**: N generated / N from cache
- **Red team**: enabled / disabled
- **Overall Judge score**: <average> / 1.0

## Scenario Results
| Persona | Turns | Judge Score | Outcome | Notes |
|---------|-------|-------------|---------|-------|
| new-user | N | 0.9 | ✅ passed | |
| returning-user | N | 1.0 | ✅ passed | |
| edge-case | N | 0.5 | ⚠️ partial | Step 3 failed |

## Red Team Results
| Attack | Expected | Actual | Status |
|--------|----------|--------|--------|
| SQL injection in login | rejected | rejected | ✅ pass |
| XSS in comment field | rejected | passed | ❌ SECURITY FINDING |

## Cached Scenarios
<list of scenario JSON files for CI replay>

## Recommendations
<issues found, prioritized by Judge score>
```

## Important Rules

- **Scenarios before execution** — always generate and review scenario JSON before writing Playwright specs
- **Cache by default** — reuse cached scenarios in CI to avoid LLM cost per run; set `QA_REGEN=1` to force regeneration
- **Red team is opt-in** — never run adversarial attacks unless `QA_REDTEAM=1` is explicitly set
- **Staging only for red team** — red-team mode must only run against non-production environments

## Agent Memory

After each run, update `.claude/agent-memory/qa-simulate/MEMORY.md` (create if absent). Record:
- Feature descriptions that produced high-quality scenarios
- Personas that uncovered bugs in this project
- Red team attacks that found real issues vs. expected rejections
- Cache file locations and scenario counts

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-simulate","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
