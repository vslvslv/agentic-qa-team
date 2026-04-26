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
ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null | head -5
ls playwright.config.ts playwright.config.js 2>/dev/null | head -2
ls e2e/ tests/ spec/ cypress/ 2>/dev/null | head -5
ls android/ ios/ app.json 2>/dev/null | head -3
ls k6/ locustfile.py load-tests/ 2>/dev/null | head -3
ls openapi.yaml openapi.json swagger.yaml swagger.json 2>/dev/null | head -2

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

**Auto-detection rules:**
- `playwright.config.*` or `e2e/` → include **qa-web**
- `openapi.*` or `swagger.*` or `api/` routes → include **qa-api**
- `android/` or `ios/` or `app.json` (Expo) → include **qa-mobile**
- `k6/` or `locustfile.py` or `load-tests/` → include **qa-perf**
- `playwright.config.*` + any `screenshots/` or `visual/` dir → include **qa-visual**

Present detected domains and ask for confirmation. Allow overriding.

Record selected domains:

```bash
echo "SELECTED_DOMAINS: web api mobile perf visual"  # adjust to confirmed selection
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

Save summary to `$_TMP/qa-team-context.md` for sub-agents to reference.

## Phase 2 — Spawn Sub-Agents (Parallel)

Spawn one Agent per selected domain. Pass the project context summary as part of each sub-agent's prompt. Sub-agents run concurrently.

**Template for each sub-agent call:**

```
Project context: <contents of $_TMP/qa-team-context.md>
Target: <web | api | mobile | perf | visual>
Working directory: <cwd>
Base URL: <detected base URL>
Report output: $_TMP/qa-<domain>-report.md

Run /qa-<domain> with the above context. Write the final report to the output path above.
```

Sub-agents to spawn (skip domains not in Phase 0 selection):
- `/qa-web`   → `$_TMP/qa-web-report.md`
- `/qa-api`   → `$_TMP/qa-api-report.md`
- `/qa-mobile` → `$_TMP/qa-mobile-report.md`
- `/qa-perf`  → `$_TMP/qa-perf-report.md`
- `/qa-visual` → `$_TMP/qa-visual-report.md`

Wait for all sub-agents to complete before proceeding.

## Phase 3 — Aggregate Results

Read each sub-agent's report and merge into a single quality scorecard:

```bash
for domain in web api mobile perf visual; do
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
- **Domains Tested**: web · api · mobile · perf · visual

## Domain Results

### Web (Playwright)
<paste qa-web summary>

### API
<paste qa-api summary>

### Mobile
<paste qa-mobile summary>

### Performance
<paste qa-perf summary>

### Visual
<paste qa-visual summary>

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
