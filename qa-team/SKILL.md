---
name: qa-team
preamble-tier: 3
version: 1.0.0
description: |
  Agentic QA orchestrator. Analyzes the current project, determines which testing
  domains apply (web, API, mobile, performance, visual), and spawns specialized
  sub-agents for each. Aggregates all results into a unified quality report.
  Use when asked to "run qa", "qa team", "full test suite", "test everything",
  "qa the app", or "run all agents".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
---

## Version check

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_QA_ROOT=$(dirname "$(readlink ~/.claude/skills/qa-team 2>/dev/null)" 2>/dev/null) || true
[ ! -f "${_QA_ROOT:-x}/VERSION" ] && \
  _QA_ROOT="$(readlink ~/.claude/skills/qa-agentic-team 2>/dev/null)" || true
_QA_VER=$( [ -n "$_QA_ROOT" ] && bash "$_QA_ROOT/bin/qa-team-update-check" 2>/dev/null \
  || echo "UPDATE_CHECK_FAILED: not found" )
echo "VERSION_STATUS: $_QA_VER"
_QA_ASK_COOLDOWN="$_TMP/.qa-update-asked"
_QA_SKIP_ASK=0
if [ -f "$_QA_ASK_COOLDOWN" ]; then
  _qa_age=$(( $(date +%s) - $(cat "$_QA_ASK_COOLDOWN" | tr -d ' ') ))
  [ "$_qa_age" -lt 600 ] && _QA_SKIP_ASK=1
fi
```

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `_QA_SKIP_ASK` is `0`, use `AskUserQuestion`:
- Question: "qa-agentic-team update available (read vCURRENT → vNEW from VERSION_STATUS output). Update before running?"
- Options: "Yes — update now (recommended)" | "No — run with current version"
- Run `echo "$(date +%s)" > "$_QA_ASK_COOLDOWN"` to set a 10-minute cooldown (prevents repeated prompts in parallel sub-agents).
- If user selects "Yes": `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup" && echo "Updated successfully."`
- Continue regardless of choice.

---

## Preamble (run first)

### Skill arguments

If the user invoked this skill with `--since=<git-ref>`, set `_SINCE_REF` below to that
value. Otherwise leave it empty. `--since=<ref>` activates **delta mode**: each
sub-agent that supports it (currently only `qa-audit`) is invoked with the same
`--since=<ref>` so it scores only the changed-file subset. Useful for per-PR runs:
`/qa-team --since=main`.

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
_SINCE_REF=""           # ← if user passed --since=<ref>, set it here
echo "BRANCH: $_BRANCH"
echo "DATE: $_DATE"
echo "TMP: $_TMP"

# Validate --since up front so sub-agents can't be spawned with a bogus ref.
# Resolve to FULL hash (short hashes can collide on large repos); derive a short
# form separately for display.
_SINCE_SHA=""
_SINCE_SHA_SHORT=""
if [ -n "$_SINCE_REF" ]; then
  _SINCE_SHA=$(git rev-parse --verify "$_SINCE_REF^{commit}" 2>/dev/null || true)
  if [ -z "$_SINCE_SHA" ]; then
    echo "ERROR: --since=$_SINCE_REF does not resolve to a git commit. Aborting." >&2
    exit 1
  fi
  _SINCE_SHA_SHORT=$(git rev-parse --short "$_SINCE_SHA" 2>/dev/null || echo "$_SINCE_SHA")
  if ! git merge-base --is-ancestor "$_SINCE_SHA" HEAD 2>/dev/null; then
    echo "ERROR: --since=$_SINCE_REF ($_SINCE_SHA_SHORT) is not an ancestor of HEAD. Aborting." >&2
    exit 1
  fi
  echo "DELTA_MODE: enabled (since $_SINCE_REF → $_SINCE_SHA_SHORT)"
fi

# Detect project type signals
echo "--- PROJECT SIGNALS ---"
ls package.json pyproject.toml go.mod Cargo.toml pom.xml build.gradle Gemfile 2>/dev/null | head -6
ls android/ ios/ app.json 2>/dev/null | head -3
ls openapi.yaml openapi.json swagger.yaml swagger.json 2>/dev/null | head -2

# Web E2E tool detection
echo "--- WEB TOOLS ---"
_WEB_TOOL=""
ls playwright.config.ts playwright.config.js playwright.config.mts 2>/dev/null && _WEB_TOOL="playwright"
{ ls cypress.config.ts cypress.config.js cypress.config.mjs 2>/dev/null || [ -d cypress ]; } && \
  grep -q '"cypress"' package.json 2>/dev/null && _WEB_TOOL="${_WEB_TOOL:+$_WEB_TOOL,}cypress"
grep -q '"selenium-webdriver"\|"@seleniumhq"' package.json 2>/dev/null && \
  _WEB_TOOL="${_WEB_TOOL:+$_WEB_TOOL,}selenium"
echo "WEB_TOOL: ${_WEB_TOOL:-none}"

# Performance tool detection
echo "--- PERF TOOLS ---"
_PERF_TOOL=""
{ ls k6/ load-tests/ 2>/dev/null | grep -q '.' || \
  find . \( -path "*/k6/*.js" -o -path "*/k6/*.ts" \) ! -path "*/node_modules/*" 2>/dev/null | grep -q .; } && \
  _PERF_TOOL="k6"
find . -name "*.jmx" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && \
  _PERF_TOOL="${_PERF_TOOL:+$_PERF_TOOL,}jmeter"
{ ls locustfile.py 2>/dev/null || find . -name "locust*.py" ! -path "*/node_modules/*" 2>/dev/null | grep -q .; } && \
  _PERF_TOOL="${_PERF_TOOL:+$_PERF_TOOL,}locust"
echo "PERF_TOOL: ${_PERF_TOOL:-none}"

# Mobile tool detection
echo "--- MOBILE TOOLS ---"
_MOB_TOOL=""
grep -q '"detox"' package.json 2>/dev/null && _MOB_TOOL="detox"
grep -q '"appium"\|"@wdio"' package.json 2>/dev/null && \
  _MOB_TOOL="${_MOB_TOOL:+$_MOB_TOOL,}appium"
{ [ -d ".maestro" ] || which maestro > /dev/null 2>&1; } && \
  _MOB_TOOL="${_MOB_TOOL:+$_MOB_TOOL,}maestro"
echo "MOB_TOOL: ${_MOB_TOOL:-none}"

# Methodology: detect whether the project has any test files.
# Delegates to the canonical helper (single source of truth for what counts as
# a test file). $_QA_ROOT is set in the version-check block above.
echo "--- TEST FILES ---"
_HAS_TESTS=0
bash "$_QA_ROOT/bin/qa-team-test-files" --has-tests >/dev/null 2>&1 && _HAS_TESTS=1
echo "HAS_TESTS: $_HAS_TESTS"

# Detect running services
echo "--- RUNNING SERVICES ---"
for port in 3000 3001 4000 4001 5000 5001 8000 8080; do
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://localhost:$port" 2>/dev/null || echo "000")
  [ "$status" != "000" ] && echo "PORT $port: $status"
done

echo "--- DONE ---"
```

If no running services are found, warn the user and ask whether to proceed in offline mode (analyze only, no execution).

## Phase 0 — Scope Selection

Use `AskUserQuestion` to confirm which agents to run. Default to auto-detecting based on project signals.

### Sticky scope: load prior selection if present

```bash
_REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
_LAST_SCOPE=""
if [ -n "$_REPO_ROOT" ] && [ -f "$_REPO_ROOT/.qa-team/last-scope" ]; then
  _LAST_SCOPE=$(cat "$_REPO_ROOT/.qa-team/last-scope" | tr -d '[:space:]' | head -c 200)
fi
[ -n "$_LAST_SCOPE" ] && echo "STICKY_SCOPE: previous selection was '$_LAST_SCOPE'"
```

If `_LAST_SCOPE` is non-empty, it represents the user's last confirmed scope (e.g.
`api,audit,web,visual`). Make it the **first** option in the `AskUserQuestion` below
labelled "Re-run last scope ($_LAST_SCOPE) (Recommended)" — sticky scope eliminates the
need to re-select identical domains across runs on the same project.

**Auto-detection rules** (used when no sticky scope or user picks "Different scope"):
- `playwright.config.*` or `e2e/` or `cypress.config.*` or `cypress/` or `selenium-webdriver` in package.json → include **qa-web**
- `openapi.*` or `swagger.*` or `api/` routes → include **qa-api**
- `android/` or `ios/` or `app.json` (Expo) or `.maestro/` → include **qa-mobile**
- `k6/` or `locustfile.py` or `load-tests/` or `*.jmx` files → include **qa-perf**
- `playwright.config.*` + any `screenshots/` or `visual/` dir → include **qa-visual**
- any `*.spec.*`, `*.test.*`, `*_test.*`, `test_*.py`, `*Test.cs`/`*Tests.cs`, `*Test.java`/`*Tests.java`, `*_test.go`, or `*_spec.rb` files found → include **qa-audit** (driven by `_HAS_TESTS` from the Preamble — same glob set as the Phase 5 regex)

Present detected domains and ask for confirmation. Allow overriding.

### Persist selected scope (for next run)

After the user confirms, write the canonical scope back to disk so the next run can
offer it as the recommended default:

```bash
if [ -n "$_REPO_ROOT" ]; then
  mkdir -p "$_REPO_ROOT/.qa-team"
  printf '%s' "$_SELECTED_DOMAINS" > "$_REPO_ROOT/.qa-team/last-scope"
fi
```

Where `$_SELECTED_DOMAINS` is a comma-separated list of confirmed domains (e.g.
`api,audit,web`). Use a stable comma-separated form so the prompt label in subsequent
runs renders cleanly.

Record selected domains and detected tools:

```bash
echo "SELECTED_DOMAINS: $_SELECTED_DOMAINS"
echo "DETECTED: WEB=${_WEB_TOOL:-none} PERF=${_PERF_TOOL:-none} MOB=${_MOB_TOOL:-none} AUDIT=${_HAS_TESTS}"
```

## Phase 1 — Project Analysis

Read enough context so each sub-agent is briefed correctly:

```bash
# Tech stack
cat package.json 2>/dev/null | grep -E '"name"|"version"|"dependencies"' | head -30
cat README.md 2>/dev/null | head -50

# Entry points
find . -maxdepth 3 \( -name "*.config.ts" -o -name "*.config.js" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -10

# API routes (common patterns)
find . -path "*/routes/*.ts" -o -path "*/routes/*.js" -o -path "*/controllers/*.ts" \
  ! -path "*/node_modules/*" 2>/dev/null | head -20

# Web pages / screens
find . \( -path "*/pages/*.tsx" -o -path "*/screens/*.tsx" -o -path "*/views/*.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -20
```

Summarize findings:
- App name and version
- Framework (Next.js, Express, FastAPI, React Native, etc.)
- Base URL (from env or config)
- List of key pages / endpoints / screens
- Auth mechanism (JWT, session, OAuth)
- Detected tools per domain (from Preamble `_WEB_TOOL`, `_PERF_TOOL`, `_MOB_TOOL`)

Save summary to `$_TMP/qa-team-context.md` for sub-agents to reference.

## Phase 2 — Spawn Sub-Agents (Parallel)

Spawn one Agent per selected domain. Pass the project context summary and detected tool as part of each sub-agent's prompt. Sub-agents run concurrently.

**Template for each sub-agent call:**

```
Project context: <contents of $_TMP/qa-team-context.md>
Target: <web | api | mobile | perf | visual>
Working directory: <cwd>
Base URL: <detected base URL>
Detected tool: <value of _WEB_TOOL | _PERF_TOOL | _MOB_TOOL — skip if "none" or empty>
Delta mode: <if _SINCE_REF non-empty for qa-audit, include "--since=$_SINCE_REF"; otherwise omit>
Report output: $_TMP/qa-<domain>-report.md

Run /qa-<domain> with the above context. If "Detected tool" is provided, skip the
tool selection gate and use that tool directly. If "Delta mode" is set, pass it through
verbatim — qa-audit understands `--since=<ref>` and will scope its scoring accordingly.
Sub-agents that don't support delta mode should ignore the flag silently.
Write the final report to the output path.
```

> **Delta-mode propagation:** today only `/qa-audit` consumes `--since=<ref>`. Other
> sub-agents (`/qa-api`, `/qa-web`, `/qa-visual`, `/qa-perf`, `/qa-mobile`) ignore it
> harmlessly — their scoring is per-endpoint / per-page / per-screenshot, which is
> already incremental in nature. Future sub-agents may add their own delta mode.

Sub-agents to spawn (skip domains not in Phase 0 selection):
- `/qa-web`    → `$_TMP/qa-web-report.md`
- `/qa-api`    → `$_TMP/qa-api-report.md`
- `/qa-mobile` → `$_TMP/qa-mobile-report.md`
- `/qa-perf`   → `$_TMP/qa-perf-report.md`
- `/qa-visual` → `$_TMP/qa-visual-report.md`
- `/qa-audit`  → `$_TMP/qa-audit-report.md`

Wait for all sub-agents to complete before proceeding.

## Phase 3 — Aggregate Results

Read each sub-agent's report and merge into a single quality scorecard:

```bash
for domain in web api mobile perf visual audit; do
  f="$_TMP/qa-$domain-report.md"
  [ -f "$f" ] && echo "=== $domain ===" && cat "$f" || echo "=== $domain: not run ==="
done
```

Compute aggregates:
- Total tests: sum across all domains
- Passed / Failed / Skipped counts
- Critical failures (tests marked `[CRITICAL]` in sub-agent reports)
- Coverage gaps (pages/endpoints/screens with no tests)

## Phase 4 — Unified Quality Report

Write `qa-report-<date>.md` to the project root (or `reports/` if it exists):

```markdown
# QA Team Report — <date> — <branch>

## Executive Summary
- **Overall Status**: ✅ Pass / ⚠️ Partial / ❌ Fail
- **Total Tests**: N (passed: N, failed: N, skipped: N)
- **Domains Tested**: web · api · mobile · perf · visual · audit
- **Tools Used**: <e.g. Playwright · REST Assured · Detox · k6>

## Domain Results

### Web (<detected tool: Playwright / Cypress / Selenium>)
<paste qa-web summary>

### API (<detected language tool>)
<paste qa-api summary>

### Mobile (<detected tool: Detox / Appium / Maestro>)
<paste qa-mobile summary>

### Performance (<detected tool: k6 / JMeter / Locust>)
<paste qa-perf summary>

### Visual
<paste qa-visual summary>

### Methodology Audit
<paste qa-audit summary — score, pyramid balance, top recommendations>

## Critical Failures
<list only failed tests, with error snippet>

## Coverage Gaps
<pages / endpoints / screens that had no test coverage>

## Recommended Next Steps
<top 3 actions based on failures and gaps>
```

Print the report path and overall pass/fail status.

If there are critical failures: "Found N critical failures. Run /investigate to diagnose?"

## Phase 5 — Verify After Fixes (close the loop)

A QA report is only useful if the user re-runs it after applying fixes. Most users
(and most agents) forget. This phase makes re-runs the default expectation.

```bash
_REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
_HIST_DIR="${_REPO_ROOT:+$_REPO_ROOT/.qa-team}"
_PRIOR_AUDIT="${_HIST_DIR:+$_HIST_DIR/qa-audit-latest.json}"

_PRIOR_COMMIT=""
if [ -n "$_PRIOR_AUDIT" ] && [ -f "$_PRIOR_AUDIT" ]; then
  _PRIOR_COMMIT=$(jq -r '.commit // empty' "$_PRIOR_AUDIT" 2>/dev/null)
fi

# Compute scope of changes since the last recorded run.
# Delegates to the canonical helper (same script that qa-audit and the
# Stop-hook use — single source of truth).
_CHANGED_TEST_FILES=""
if [ -n "$_PRIOR_COMMIT" ] && [ "$_PRIOR_COMMIT" != "$(git rev-parse --short HEAD)" ]; then
  _CHANGED_TEST_FILES=$(bash "$_QA_ROOT/bin/qa-team-test-files" --since="$_PRIOR_COMMIT" 2>/dev/null | head -20 || true)
fi
```

**Decision tree:**

1. **No prior history** (`_PRIOR_AUDIT` missing): nothing to verify against. Skip Phase 5.
2. **Prior commit equals HEAD**: report was already against the current code. Skip Phase 5.
3. **Test files changed since last run**: this is the case that matters. Use `AskUserQuestion`:
   - Question: "You've changed N test files since the last QA report (commit `$_PRIOR_COMMIT`). Re-run sub-agents now to measure delta?"
   - Options:
     - "Yes — re-run `/qa-audit --since=$_PRIOR_COMMIT` (cheap, Recommended)" — spawns only `/qa-audit` in delta mode, scoping to the changed-file subset. Fastest option; ideal for per-PR verification.
     - "Yes — re-run affected sub-agents (full)" — re-spawns the sub-agents whose domain matches the changed files (e.g. `/qa-audit` and `/qa-api` if only test/api code changed), all in full-scan mode.
     - "Yes — re-run full /qa-team"
     - "No — skip verification"
   - If the user picks a re-run option, jump back to Phase 2 with the narrowed scope (and `--since` flag set when applicable) and complete the loop.
4. **No test files changed but production code did**: nudge gently — "Production code changed since last audit but no test files. Consider whether the changes need new test coverage."

**Score-delta hint**: if the re-run completes in **full** mode, read both the prior and
current `qa-audit-score.json`, compute `overall_delta = current - prior`, and surface it
in the new report's Executive Summary:

```
Audit score: 76 → 84 (+8 since 0939d0b)
```

If the re-run was in **delta** mode (`delta_mode.enabled == true` in the new JSON),
**do not** compare against the prior full-audit score — they are not comparable. Instead
surface the delta-scope finding directly:

```
Delta-scope audit (12 changed test files since 0939d0b): 88/100 — 0 critical issues
```

This is the closed-loop signal that turns the QA harness from one-shot triage into a
measurement instrument the user can trust.

## Important Rules

- **Never run destructive operations** — read-only analysis unless explicitly running test suites
- **Skip domains with insufficient signals** — don't force a mobile agent on a web-only project
- **Sub-agents are independent** — do not share state between them beyond the context summary
- **Report even if tests fail** — always produce the aggregated report regardless of exit codes
- **Idempotent** — safe to re-run; overwrites `$_TMP/qa-*-report.md` and the root report
- **Close the loop** — Phase 5 is the difference between triage and a measurement instrument. Do not skip it when there is prior history; ask the user explicitly via `AskUserQuestion` rather than assuming silence means "no"
- **Delta mode is for verification** — `--since=<ref>` is for cheap per-PR re-runs after fixes; never persist its score to `.qa-team/`. Full audits remain the canonical history.
- **Sticky scope is a default, not a lock** — always offer the prior scope as the recommended option, but never bypass `AskUserQuestion`. Project structure or user intent may have changed since the last run.

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-team","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true

# Per-run cost log (consumed by bin/qa-team-cost). Status reflects the
# aggregated outcome: pass = no critical failures across sub-agents, warn =
# partial issues, fail = at least one sub-agent reported critical failures.
bash "$_QA_ROOT/bin/qa-team-cost-log" "qa-team" "<pass|warn|fail>" 2>/dev/null || true
```
