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
disable-model-invocation: true
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
echo "TMP: $_TMP"

# Detect project type signals
echo "--- PROJECT SIGNALS ---"
ls package.json pyproject.toml go.mod Cargo.toml pom.xml build.gradle Gemfile 2>/dev/null | head -6
ls *.csproj *.sln global.json Directory.Build.props nuget.config 2>/dev/null | head -4
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
# C# / .NET web E2E detection
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -l "Microsoft\.Playwright" 2>/dev/null | grep -q '.' && \
  _WEB_TOOL="${_WEB_TOOL:+$_WEB_TOOL,}playwright-dotnet"
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -l "Selenium\.WebDriver" 2>/dev/null | grep -q '.' && \
  _WEB_TOOL="${_WEB_TOOL:+$_WEB_TOOL,}selenium-dotnet"
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

# Methodology: detect whether the project has any test files
echo "--- TEST FILES ---"
_HAS_TESTS=0
find . \( \
  -name "*.spec.ts" -o -name "*.spec.js" \
  -o -name "*.test.ts" -o -name "*.test.js" \
  -o -name "*_test.py" -o -name "test_*.py" \
  -o -name "*Test.java" -o -name "*_spec.rb" \
  -o -name "*Tests.cs" -o -name "*Test.cs" -o -name "*Spec.cs" \
  \) ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | grep -q '.' && _HAS_TESTS=1
echo "HAS_TESTS: $_HAS_TESTS"

# Detect running services
echo "--- RUNNING SERVICES ---"
for port in 3000 3001 4000 4001 5000 5001 8000 8080; do
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://localhost:$port" 2>/dev/null || echo "000")
  [ "$status" != "000" ] && echo "PORT $port: $status"
done

# --- MULTI-REPO SUPPORT ---
# Set QA_EXTRA_PATHS (space-separated absolute paths) to scan tests in other repos
# e.g.: export QA_EXTRA_PATHS="/path/to/e2e-repo /path/to/api-tests-repo"
if [ -n "$QA_EXTRA_PATHS" ]; then
  echo "MULTI_REPO_PATHS: $QA_EXTRA_PATHS"
  for _qr in $QA_EXTRA_PATHS; do
    _extra=$(find "$_qr" \( \
      -name "*.spec.ts" -o -name "*.spec.js" -o -name "*.test.ts" -o -name "*.test.js" \
      -o -name "*_test.py" -o -name "test_*.py" -o -name "*Test.java" \
      -o -name "*Tests.cs" -o -name "*_spec.rb" -o -name "*.yaml" \) \
      ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | wc -l | tr -d ' ')
    echo "EXTRA_REPO $(basename "$_qr"): $_extra test files — $_qr"
  done
fi

echo "--- DONE ---"
```

If no running services are found, warn the user and ask whether to proceed in offline mode (analyze only, no execution).

If `MULTI_REPO_PATHS` output appeared: when sampling test files in subsequent phases, include files from those extra paths. All sub-agents inherit `QA_EXTRA_PATHS` automatically via the environment. Language detection uses CWD (the main application repository).

## Phase 0 — Scope Selection

Use `AskUserQuestion` to confirm which agents to run. Default to auto-detecting based on project signals.

**Auto-detection rules:**
- `playwright.config.*` or `e2e/` or `cypress.config.*` or `cypress/` or `selenium-webdriver` in package.json, or `Microsoft.Playwright`/`Selenium.WebDriver` in any `.csproj` → include **qa-web**
- `openapi.*` or `swagger.*` or `api/` routes → include **qa-api**
- `android/` or `ios/` or `app.json` (Expo) or `.maestro/` → include **qa-mobile**
- `k6/` or `locustfile.py` or `load-tests/` or `*.jmx` files → include **qa-perf**
- `playwright.config.*` + any `screenshots/` or `visual/` dir → include **qa-visual**
- any `*.spec.*`, `*.test.*`, `*_test.*`, or `*Test.java` files found → include **qa-audit**

Present detected domains and ask for confirmation. Allow overriding.

Record selected domains and detected tools:

```bash
echo "SELECTED_DOMAINS: web api mobile perf visual audit"  # adjust to confirmed selection
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

# C# / .NET project discovery
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | head -10
find . \( -path "*/Controllers/*.cs" -o -path "*/Pages/*.cs" -o -path "*/Views/*.cs" \) \
  ! -path "*/obj/*" 2>/dev/null | head -20
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
Report output: $_TMP/qa-<domain>-report.md

Run /qa-<domain> with the above context. If "Detected tool" is provided, skip the
tool selection gate and use that tool directly. Write the final report to the output path.
```

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

## Important Rules

- **Never run destructive operations** — read-only analysis unless explicitly running test suites
- **Skip domains with insufficient signals** — don't force a mobile agent on a web-only project
- **Sub-agents are independent** — do not share state between them beyond the context summary
- **Report even if tests fail** — always produce the aggregated report regardless of exit codes
- **Idempotent** — safe to re-run; overwrites `$_TMP/qa-*-report.md` and the root report

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-team","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
