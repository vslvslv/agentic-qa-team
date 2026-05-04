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

# Explore detection (running web app present?)
echo "--- EXPLORE ---"
_EXPLORE_READY=0
for port in 3000 3001 4000 4001 8000 8080; do
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://localhost:$port" 2>/dev/null || echo "000")
  [ "$status" != "000" ] && _EXPLORE_READY=1 && break
done
echo "EXPLORE_READY: $_EXPLORE_READY"

# Security tool detection
echo "--- SECURITY TOOLS ---"
_SEC_TOOL=""
command -v zap.sh >/dev/null 2>&1 && _SEC_TOOL="zap"
docker image inspect softwaresecurityproject/zap-stable >/dev/null 2>&1 && \
  _SEC_TOOL="${_SEC_TOOL:+$_SEC_TOOL,}zap-docker"
command -v nuclei >/dev/null 2>&1 && _SEC_TOOL="${_SEC_TOOL:+$_SEC_TOOL,}nuclei"
[ -z "$_SEC_TOOL" ] && _SEC_TOOL="probe-only"
echo "SEC_TOOL: $_SEC_TOOL"

# Seed schema detection
echo "--- SEED SCHEMA ---"
_SEED_SCHEMA="none"
ls prisma/schema.prisma 2>/dev/null && _SEED_SCHEMA="prisma"
find . -name "*.sql" -path "*/migrations/*" ! -path "*/node_modules/*" 2>/dev/null | \
  grep -q '.' && [ "$_SEED_SCHEMA" = "none" ] && _SEED_SCHEMA="sql-migrations"
find . \( -name "*.entity.ts" -o -name "*.entity.js" \) ! -path "*/node_modules/*" 2>/dev/null | \
  grep -q '.' && [ "$_SEED_SCHEMA" = "none" ] && _SEED_SCHEMA="typeorm"
echo "SEED_SCHEMA: $_SEED_SCHEMA"

# Component testing tools
echo "--- COMPONENT TOOLS ---"
_COMP_TOOL=""
find . \( -name "main.js" -o -name "main.ts" -o -name "main.mjs" \) \
  -path "*/.storybook/*" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && \
  _COMP_TOOL="storybook"
grep -qE '"fast-check"|"@fast-check/' package.json 2>/dev/null && \
  _COMP_TOOL="${_COMP_TOOL:+$_COMP_TOOL,}fast-check"
echo "COMP_TOOL: ${_COMP_TOOL:-none}"

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

# Complexity scoring signals (for hardness-aware routing)
echo "--- COMPLEXITY SIGNALS ---"
_ROUTE_COUNT=$(find . \( -path "*/routes/*.ts" -o -path "*/routes/*.js" \
  -o -path "*/controllers/*.ts" -o -path "*/controllers/*.js" \
  -o -path "*/pages/*.tsx" -o -path "*/app/**/*.tsx" \
  \) ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
echo "ROUTE_COUNT: $_ROUTE_COUNT"

_HAS_AUTH=0
grep -rl "auth\|jwt\|session\|passport\|oauth\|bearer" \
  --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
  . 2>/dev/null | grep -qiE "middleware|guard|auth" && _HAS_AUTH=1
echo "HAS_AUTH: $_HAS_AUTH"

_DOMAIN_COUNT=0
[ -n "$_WEB_TOOL" ] && [ "$_WEB_TOOL" != "none" ] && _DOMAIN_COUNT=$((_DOMAIN_COUNT+1))
[ -n "$_PERF_TOOL" ] && [ "$_PERF_TOOL" != "none" ] && _DOMAIN_COUNT=$((_DOMAIN_COUNT+1))
[ -n "$_MOB_TOOL" ] && [ "$_MOB_TOOL" != "none" ] && _DOMAIN_COUNT=$((_DOMAIN_COUNT+1))
[ "$_HAS_TESTS" = "1" ] && _DOMAIN_COUNT=$((_DOMAIN_COUNT+1))
echo "DOMAIN_COUNT: $_DOMAIN_COUNT"

_LOC=$(find . \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
  -o -name "*.py" -o -name "*.java" -o -name "*.cs" \) \
  ! -path "*/node_modules/*" ! -path "*/obj/*" ! -name "*.spec.*" ! -name "*.test.*" \
  2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo 0)
echo "LOC: $_LOC"

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
- **qa-a11y**: auto-include when `_WEB_TOOL != "none"` (web app detected with Playwright/Cypress/Selenium)
- **qa-heal**: auto-include when `gh pr view --json statusCheckRollup` shows any failing checks
- **qa-explore**: auto-include when `_EXPLORE_READY=1` AND `QA_SKIP_EXPLORE` not set (post-deploy smoke)
- **qa-security**: auto-include when `_WEB_TOOL != "none"` OR API detected (always has Mode B curl probes)
- **qa-seed**: auto-include when `_SEED_SCHEMA != "none"` AND `TEST_DATABASE_URL` or `DATABASE_URL` is set
- **qa-component**: auto-include when `_COMP_TOOL` contains `storybook`
- **qa-simulate**: not auto-included; requires explicit user selection or `QA_SIMULATE=1` env var

Present detected domains and ask for confirmation. Allow overriding.

Record selected domains and detected tools:

```bash
echo "SELECTED_DOMAINS: web api mobile perf visual audit"  # adjust to confirmed selection
echo "DETECTED: WEB=${_WEB_TOOL:-none} PERF=${_PERF_TOOL:-none} MOB=${_MOB_TOOL:-none} AUDIT=${_HAS_TESTS}"
```

## Phase 0.8 — Hardness-Aware Routing (BL-012)

```bash
_HARDNESS=0
[ "$_ROUTE_COUNT" -gt 20 ] && _HARDNESS=$((_HARDNESS+1))
[ "$_ROUTE_COUNT" -gt 50 ] && _HARDNESS=$((_HARDNESS+1))
[ "$_HAS_AUTH" = "1" ] && _HARDNESS=$((_HARDNESS+1))
[ "$_DOMAIN_COUNT" -ge 3 ] && _HARDNESS=$((_HARDNESS+1))
[ "$_DOMAIN_COUNT" -ge 5 ] && _HARDNESS=$((_HARDNESS+1))
[ "$_LOC" -gt 5000 ] && _HARDNESS=$((_HARDNESS+1))
[ "$_LOC" -gt 20000 ] && _HARDNESS=$((_HARDNESS+1))
echo "HARDNESS_SCORE: $_HARDNESS"

_COMPLEXITY_TIER="complex"
[ "$_HARDNESS" -lt 3 ] && _COMPLEXITY_TIER="simple"
[ "$_HARDNESS" -ge 6 ] && _COMPLEXITY_TIER="very-complex"
echo "COMPLEXITY_TIER: $_COMPLEXITY_TIER"
```

Apply tier behavior when spawning sub-agents in Phase 2:

**SIMPLE** (`_HARDNESS < 3`):
- Spawn only `qa-web` (plus any domains explicitly selected by user in Phase 0)
- Pass `QA_FAST_MODE=1` to `qa-web`: no POM, no auth setup, smoke tests only (5 critical paths)
- Do not force-add `qa-audit` or `qa-explore`

**COMPLEX** (`_HARDNESS` 3–5):
- Normal full parallel flow — no changes to existing behavior

**VERY-COMPLEX** (`_HARDNESS >= 6`):
- Full parallel flow + force-add `qa-audit` and `qa-explore` to selected domains (unless `QA_SKIP_AUDIT=1` / `QA_SKIP_EXPLORE=1`)
- Pass `QA_DEEP_MODE=1` to all sub-agents

Add **Routing** block to Phase 4 Executive Summary:
```
## Routing
- Complexity tier: simple / complex / very-complex (score N/7)
- Reason: routes=N, auth=yes/no, domains=N, LOC=N
- Agent fleet: <list of agents spawned>
```

---

## Phase 0.5 — Test Impact Analysis

```bash
_CHANGED=$(git diff --name-only origin/main 2>/dev/null \
  || git diff --name-only HEAD~1 2>/dev/null || echo "")
echo "CHANGED_FILES: $(echo "$_CHANGED" | wc -l | tr -d ' ')"
echo "$_CHANGED" | head -20
```

If `_CHANGED` is empty: skip (run all selected domains in FULL-PATH mode).

**Impact mapping heuristics** — map changed files to affected test domains:
- `src/auth/**`, `auth.*`, `*middleware*` → web + api flagged
- `src/api/**`, `routes/**`, `controllers/**` → api flagged
- `*.config.*`, `tsconfig.*`, `package.json`, `package-lock.json` → all domains (config change)
- `migrations/**`, `prisma/**`, `schema.*`, `*.sql` → api flagged
- `src/components/**`, `pages/**`, `views/**`, `screens/**` → web flagged
- `android/**`, `ios/**` → mobile flagged
- `k6/**`, `load-tests/**`, `locust*.py` → perf flagged

**Decision:**
- Changed files map to ≤5 test files AND no config/infra files changed → **FAST-PATH**
  Pass the specific file list to relevant sub-agents' prompts (e.g., `--spec <file>`)
- Otherwise → **FULL-PATH** (run all selected domains normally)

```bash
_IMPACT_MODE="full"
_CHANGED_COUNT=$(echo "$_CHANGED" | grep -c '.' 2>/dev/null || echo 0)
_INFRA_CHANGED=$(echo "$_CHANGED" | grep -E 'config\.|tsconfig|package\.json|package-lock|migrations/' | wc -l | tr -d ' ')
if [ "$_CHANGED_COUNT" -le 5 ] && [ "$_INFRA_CHANGED" -eq 0 ]; then
  _IMPACT_MODE="fast"
fi
echo "IMPACT_MODE: $_IMPACT_MODE"
echo "CHANGED_COUNT: $_CHANGED_COUNT  INFRA_CHANGED: $_INFRA_CHANGED"
```

Report scoping decision at top of Phase 1 output.

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
- `/qa-a11y`   → `$_TMP/qa-a11y-report.md`   (when web app detected)
- `/qa-heal`   → `$_TMP/qa-heal-report.md`    (when CI failures present)
- `/qa-explore`   → `$_TMP/qa-explore-report.md`   (when `_EXPLORE_READY=1` and not skipped)
- `/qa-security`  → `$_TMP/qa-security-report.md`  (when web/API app detected)
- `/qa-seed`      → `$_TMP/qa-seed-report.md`       (when `_SEED_SCHEMA != "none"` and DB_URL set)
- `/qa-component` → `$_TMP/qa-component-report.md`  (when `_COMP_TOOL` contains `storybook`)
- `/qa-simulate`  → `$_TMP/qa-simulate-report.md`   (when `QA_SIMULATE=1` or explicitly selected)

Wait for all sub-agents to complete before proceeding.

## Phase 3 — Aggregate Results

Read each sub-agent's report and merge into a single quality scorecard:

```bash
for domain in web api mobile perf visual audit a11y heal explore security seed component simulate; do
  f="$_TMP/qa-$domain-report.md"
  [ -f "$f" ] && echo "=== $domain ===" && cat "$f" || echo "=== $domain: not run ==="
done
```

Compute aggregates:
- Total tests: sum across all domains
- Passed / Failed / Skipped counts
- Critical failures (tests marked `[CRITICAL]` in sub-agent reports)
- Coverage gaps (pages/endpoints/screens with no tests)

## Phase 3.5 — Flaky Registry Update

Merge all CTRF files from this run and update `./qa-flaky-registry.json`:

```python
python3 - << 'PYEOF'
import json, glob, os
from datetime import date

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
ctrf_files = glob.glob(os.path.join(tmp, 'qa-*-ctrf.json'))

merged_tests = []
for f in ctrf_files:
    try:
        d = json.load(open(f, encoding='utf-8'))
        domain = d['results']['environment'].get('reportName', 'unknown')
        for t in d['results'].get('tests', []):
            t['_domain'] = domain
            merged_tests.append(t)
    except Exception as e:
        print(f"WARN: could not parse {f}: {e}")

print(f"MERGED_CTRF_FILES: {len(ctrf_files)}")
print(f"MERGED_TESTS: {len(merged_tests)}")

# Load or create registry
registry_path = 'qa-flaky-registry.json'
registry = {'tests': {}}
if os.path.exists(registry_path):
    try:
        registry = json.load(open(registry_path, encoding='utf-8'))
    except:
        pass

today = str(date.today())
for t in merged_tests:
    domain = t.get('_domain', 'unknown')
    suite = t.get('suite', '')
    name = t.get('name', '')
    key = f'{domain}::{suite}::{name}'
    status = t.get('status', 'other')

    if key not in registry['tests']:
        registry['tests'][key] = {'results': [], 'flakeRate': 0.0, 'lastUpdated': today, 'classification': 'suspected'}

    entry = registry['tests'][key]
    entry['results'].append(status)
    entry['results'] = entry['results'][-20:]  # keep last 20
    entry['lastUpdated'] = today

    non_skipped = [r for r in entry['results'] if r != 'skipped']
    if non_skipped:
        entry['flakeRate'] = round(non_skipped.count('failed') / len(non_skipped), 3)

json.dump(registry, open(registry_path, 'w', encoding='utf-8'), indent=2)
print(f"REGISTRY_WRITTEN: {registry_path}")

# Report flaky tests above 20%
flaky = [(k, v) for k, v in registry['tests'].items() if v.get('flakeRate', 0) > 0.2]
print(f"FLAKY_TESTS (>20%): {len(flaky)}")
for k, v in sorted(flaky, key=lambda x: -x[1]['flakeRate'])[:10]:
    print(f"  {v['flakeRate']:.0%} — {k}")
PYEOF
```

In Phase 4 unified report:
- Tests with `flakeRate > 0.2` → annotate `[FLAKY N%]` rather than `[FAILED]`
- Tests with `flakeRate > 0.5` currently failing → downgrade from BLOCKING to WARNING

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

### Accessibility
<paste qa-a11y summary — total violations, POUR breakdown, top 3 critical issues; or "not run">

### Self-Healing
<paste qa-heal summary — tests healed, confidence score, action taken; or "not run">

## Critical Failures
<list only failed tests, with error snippet>

## Coverage Gaps
<pages / endpoints / screens that had no test coverage>

## Recommended Next Steps
<top 3 actions based on failures and gaps>
```

Print the report path and overall pass/fail status.

If there are critical failures: "Found N critical failures. Run /investigate to diagnose?"

## Optional: GitHub PR Comment

Write `$_TMP/qa-team-ctrf.json` by merging all per-domain CTRF files:

```bash
python3 - << 'PYEOF'
import json, glob, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
ctrf_files = glob.glob(os.path.join(tmp, 'qa-*-ctrf.json'))

all_tests = []
for f in ctrf_files:
    try:
        d = json.load(open(f, encoding='utf-8'))
        all_tests.extend(d['results'].get('tests', []))
    except:
        pass

p = sum(1 for t in all_tests if t['status'] == 'passed')
f_ = sum(1 for t in all_tests if t['status'] == 'failed')
s = sum(1 for t in all_tests if t['status'] == 'skipped')
now_ms = int(time.time() * 1000)

merged = {
    'results': {
        'tool': {'name': 'qa-team'},
        'summary': {
            'tests': len(all_tests), 'passed': p, 'failed': f_, 'pending': 0,
            'skipped': s, 'other': 0, 'start': now_ms - 60000, 'stop': now_ms,
        },
        'tests': all_tests,
        'environment': {'reportName': 'qa-team', 'branch': os.environ.get('_BRANCH', 'unknown')},
    }
}

out = os.path.join(tmp, 'qa-team-ctrf.json')
json.dump(merged, open(out, 'w', encoding='utf-8'), indent=2)
print(f'MERGED_CTRF: {out}  tests={len(all_tests)} passed={p} failed={f_} skipped={s}')
PYEOF
```

Post to PR if `gh` is available:

```bash
if command -v gh >/dev/null 2>&1 && gh pr view >/dev/null 2>&1; then
  if command -v npx >/dev/null 2>&1; then
    npx --yes github-test-reporter "$_TMP/qa-team-ctrf.json" 2>/dev/null || \
      echo "PR_COMMENT: github-test-reporter not available or failed (non-fatal)"
  fi
fi
```

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
