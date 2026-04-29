---
name: qa-web
preamble-tier: 3
version: 1.0.0
description: |
  Web E2E test agent. Discovers the web app's pages and user flows, generates
  test specs for the detected framework (Playwright, Cypress, or Selenium WebDriver),
  executes them, and produces a structured report. Works standalone or as a sub-agent
  of /qa-team. Use when asked to "qa web", "test the UI", "write e2e tests",
  "run playwright", "run cypress", "run selenium", or "web test agent". (qa-agentic-team)
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
_QA_ROOT=$(dirname "$(readlink ~/.claude/skills/qa-web 2>/dev/null)" 2>/dev/null) || true
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

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"

# --- WEB TOOL DETECTION ---
echo "--- PLAYWRIGHT ---"
_PW=0
ls playwright.config.ts playwright.config.js playwright.config.mts 2>/dev/null && _PW=1
echo "PLAYWRIGHT_PRESENT: $_PW"

echo "--- CYPRESS ---"
_CY=0
ls cypress.config.ts cypress.config.js cypress.config.mjs 2>/dev/null && _CY=1
[ -d cypress ] && _CY=1
grep -q '"cypress"' package.json 2>/dev/null && _CY=1
echo "CYPRESS_PRESENT: $_CY"

echo "--- SELENIUM ---"
_SE=0
grep -q '"selenium-webdriver"\|"@seleniumhq/selenium"' package.json 2>/dev/null && _SE=1
grep -q 'selenium' pom.xml 2>/dev/null && _SE=1
grep -q 'selenium' requirements.txt 2>/dev/null && _SE=1
echo "SELENIUM_PRESENT: $_SE"

# C# / .NET web E2E detection
echo "--- DOTNET ---"
_PW_DOTNET=0; _SE_DOTNET=0
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -l "Microsoft\.Playwright" 2>/dev/null | grep -q '.' && _PW_DOTNET=1
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -l "Selenium\.WebDriver" 2>/dev/null | grep -q '.' && _SE_DOTNET=1
echo "PLAYWRIGHT_DOTNET: $_PW_DOTNET"
echo "SELENIUM_DOTNET: $_SE_DOTNET"

# Target language detection
_TARGET_LANG="typescript"
find . -name "pom.xml" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && _TARGET_LANG="java"
find . \( -name "requirements.txt" -o -name "pyproject.toml" \) \
  ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && _TARGET_LANG="python"
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | grep -q '.' && _TARGET_LANG="csharp"
echo "TARGET_LANG: $_TARGET_LANG"

# C# test framework detection (nunit / mstest / xunit)
_CS_TEST_FW="nunit"
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -il "xunit" 2>/dev/null | grep -q '.' && _CS_TEST_FW="xunit"
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -il "MSTest\|Microsoft\.VisualStudio\.TestTools" 2>/dev/null | grep -q '.' && \
  _CS_TEST_FW="mstest"
echo "CS_TEST_FW: $_CS_TEST_FW"

# Detect base URL
_BASE_URL=$(grep -r "baseURL\|BASE_URL" playwright.config.ts playwright.config.js \
  cypress.config.ts .env .env.local 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
# .NET: launchSettings.json (applicationUrl may be semicolon-separated — take first)
[ -z "$_BASE_URL" ] && _BASE_URL=$(
  find . -name "launchSettings.json" ! -path "*/obj/*" 2>/dev/null | head -1 | \
  xargs grep -o '"applicationUrl"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | \
  grep -o 'http[s]*://[^;",]*' | head -1)
# .NET: appsettings.json BaseUrl key
[ -z "$_BASE_URL" ] && _BASE_URL=$(
  find . \( -name "appsettings.json" -o -name "appsettings.Development.json" \) \
  ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -oi '"[Bb]ase[Uu]rl"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | \
  grep -o 'http[s]*://[^"]*' | head -1)
_BASE_URL="${_BASE_URL:-http://localhost:3000}"
echo "BASE_URL: $_BASE_URL"

# Check if app is running
_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$_BASE_URL" 2>/dev/null || echo "000")
echo "APP_STATUS: $_STATUS"

# Existing test specs
echo "--- EXISTING SPECS ---"
find . \( -path "*/e2e/*.spec.ts" -o -path "*/tests/*.spec.ts" \
  -o -path "*/cypress/**/*.cy.ts" -o -path "*/cypress/**/*.cy.js" \
  -o -path "*/test/*.test.ts" -o -path "*/test/*.test.js" \
  -o -name "*Tests.cs" -o -name "*Test.cs" -o -name "*Spec.cs" \
  \) ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | head -20

# Pages / routes
echo "--- APP ROUTES ---"
find . \( -path "*/pages/*.tsx" -o -path "*/pages/*.jsx" -o -path "*/app/**/*.tsx" \
  -o -path "*/views/*.tsx" -o -path "*/routes/*.tsx" \
  -o -path "*/Controllers/*.cs" -o -path "*/Pages/*.cs" -o -path "*/Views/*.cs" \
  \) ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | head -30

# --- MULTI-REPO SUPPORT ---
# Set QA_EXTRA_PATHS (space-separated absolute paths) to scan tests in other repos
# e.g.: export QA_EXTRA_PATHS="/path/to/e2e-repo /path/to/api-tests-repo"
if [ -n "$QA_EXTRA_PATHS" ]; then
  echo "MULTI_REPO_PATHS: $QA_EXTRA_PATHS"
  for _qr in $QA_EXTRA_PATHS; do
    _extra=$(find "$_qr" \( \
      -name "*.spec.ts" -o -name "*.spec.js" -o -name "*.test.ts" -o -name "*.test.js" \
      -o -name "*.cy.ts" -o -name "*.cy.js" -o -name "*Tests.cs" -o -name "*Test.cs" \) \
      ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | wc -l | tr -d ' ')
    echo "EXTRA_REPO $(basename "$_qr"): $_extra test files — $_qr"
  done
fi
```

If `MULTI_REPO_PATHS` output appeared: when sampling test files in subsequent phases, include files from those extra paths. All sub-agents inherit `QA_EXTRA_PATHS` automatically via the environment. Language detection uses CWD (the main application repository).

### Tool Selection Gate

Count detected tools from `PLAYWRIGHT_PRESENT`, `CYPRESS_PRESENT`, `SELENIUM_PRESENT`,
`PLAYWRIGHT_DOTNET`, and `SELENIUM_DOTNET`. Treat `PLAYWRIGHT_DOTNET=1` as a Playwright
signal and `SELENIUM_DOTNET=1` as a Selenium signal. `_TARGET_LANG` already carries the
resolved language (`typescript`, `csharp`, `java`, `python`).

**Exactly one detected** → use that tool automatically. Set `_WEB_TOOL` to `playwright`,
`cypress`, or `selenium`. If the signal came from `PLAYWRIGHT_DOTNET` or `SELENIUM_DOTNET`,
the tool name is the same but `_TARGET_LANG` will be `csharp` — Phase 2 will load the
C#-specific patterns and Phase 3 will execute `dotnet test`.

**Zero detected** → ask:
> "No web testing framework detected. Which would you like to use?
> 1. **Playwright** (recommended — fast, built-in assertions, storageState auth)
> 2. **Cypress** (great for component + E2E combo in JS/TS projects)
> 3. **Selenium WebDriver** (required for Java/Python/C# teams or legacy CI)
>
> Recommendation: Playwright for new JS/TS projects; Selenium for Java/Python/C# stacks."

**Two or more detected** → list which configs were found, ask which to use for this run.
Note the other tool(s) can be run separately.

If `APP_STATUS` is `000` or not `200`: warn the user. Ask whether to start the app first
or proceed in write-only mode (generate specs without executing them).

## Phase 1 — Discover App Structure

Read key files to understand pages, flows, and auth:

```bash
find . \( -name "routes.ts" -o -name "routes.tsx" -o -name "router.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | xargs cat 2>/dev/null | head -60

grep -r "href=\|to=\|path=" --include="*.tsx" --include="*.jsx" -l \
  ! -path "*/node_modules/*" 2>/dev/null | head -5 | xargs cat 2>/dev/null | \
  grep -o '"[/][^"]*"' | sort -u | head -30

grep -r "login\|signin\|auth\|token\|localStorage" --include="*.tsx" -l \
  ! -path "*/node_modules/*" 2>/dev/null | head -10

# C# / .NET routes
find . -path "*/Controllers/*.cs" ! -path "*/obj/*" 2>/dev/null | \
  xargs grep -h "\[Route\]\|\[HttpGet\]\|\[HttpPost\]\|ActionResult" 2>/dev/null | head -40
find . -path "*/Pages/*.cshtml" -o -path "*/Views/*.cshtml" 2>/dev/null | head -20
```

From analysis, build a **page inventory**:
- Route path
- Page purpose (one sentence)
- Key interactions (forms, tables, modals, buttons)
- Auth required (yes/no)
- Priority: `critical` | `important` | `nice-to-have`

## Phase 2 — Load Tool Patterns & Generate Tests

Read the tool-specific patterns file for the selected `_WEB_TOOL`:

```
Read qa-web/tools/<_WEB_TOOL>.md
```

Then select and read the language-appropriate reference guide based on `_WEB_TOOL` and `_TARGET_LANG`:

**Playwright — TypeScript** (when `_TARGET_LANG` is not `csharp`):
> Reference: [Playwright patterns guide (TypeScript)](references/playwright-patterns.md)
> Key patterns: POM + fixture injection · storageState auth (single/multi-role/API-based/worker-scoped) · OAuth + MFA + magic link auth · locator rank · web-first assertions · soft assertions · network mocking + HAR recording + network-cache · test sharding · visual regression · `expect.poll`/`toPass` · accessibility with axe-core · aria snapshots · test annotations/tagging · global setup via project deps · custom reporters · multi-environment projects · custom matchers · keyboard/focus testing · browser storage manipulation · performance timing · mobile emulation · clock mocking · geolocation · test attachments · debug workflow · TypeScript config + ESLint · typed POM factory · WebSocket testing · pure API test suites · `addLocatorHandler` overlay dismissal · post-facto inspection APIs · `locator.normalize()` · Screencast API · Docker deployment · auto-fixture suite scaling

**Playwright — C#** (when `_TARGET_LANG=csharp`):
> Reference: [Playwright patterns guide (C#)](references/playwright-patterns-csharp.md)
> Key patterns: PageTest base class (NUnit/MSTest/xUnit) · IPage/ILocator · C# POM · StorageStateAsync auth · selector strategy · web-first assertions via `Expect()` · network mocking · `.runsettings` config · `dotnet test` execution
> Focus on the section matching `CS_TEST_FW` (`nunit`, `mstest`, or `xunit`).

**Cypress**:
> Reference: [Cypress patterns guide](references/cypress-patterns.md)
> Key patterns: cy.session() auth (validate callback) · cy.intercept() RouteHandler (spy/modify/delay) · data-cy selectors · custom commands + Commands.overwrite() + Commands.addQuery() · cy.request() seeding · cy.spy() · Component Testing (React + Vue 3) · cy.fixture() with TypeScript generics · test isolation · cy.origin() OAuth/SSO · cy.task() for DB ops · cy.within() scoping · Module API programmatic runs · CI parallelization + Cypress Cloud flaky detection · a11y (cypress-axe) · visual regression (@percy/cypress) · test tagging with @cypress/grep

**Selenium**:
> Reference: [Selenium patterns guide](references/selenium-patterns.md)
> Key patterns: explicit waits (WebDriverWait) · selector hierarchy (id > data-testid > name > link text > xpath) · Page Object Model · auth via cookie save/restore · headless mode · screenshot on failure · multi-language support (Java / Python / C# / Ruby / JS)

**Test coverage targets per page:**
1. Page loads without error (smoke test)
2. Primary user action (form submit, row click, search, filter)
3. Empty/error state (no data, validation failure) — mock the API response
4. Auth guard (redirect to login if unauthenticated) — only for protected pages

Read existing spec files first — append new test blocks, never delete existing ones.

**Type-check after writing (JS/TS only):**

```bash
_TSC=$(find . -path "*/node_modules/.bin/tsc" ! -path "*/node_modules/*/node_modules/*" | head -1)
[ -n "$_TSC" ] && "$_TSC" --noEmit 2>&1 | grep -E "\.(spec|test|cy)\." | head -20 || echo "tsc not found"
```

## Phase 3 — Execute Tests

Dispatch to the correct runner based on `_WEB_TOOL`:

**Playwright:**
```bash
export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"
[ ! -f "e2e/.auth/user.json" ] && \
  npx playwright test e2e/auth.setup.ts --project=setup 2>/dev/null || true
_SPEC_FILES=$(find . \( -path "*/e2e/specs/*.spec.ts" -o -path "*/e2e/*.spec.ts" \) \
  ! -path "*/node_modules/*" 2>/dev/null | tr '\n' ' ')
npx playwright test $_SPEC_FILES --project=chromium --reporter=json \
  2>&1 > "$_TMP/qa-web-output.txt"
echo "EXIT_CODE: $?"
```

**Cypress:**
```bash
export CYPRESS_E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export CYPRESS_E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"
npx cypress run --headless --browser chrome \
  --reporter json --reporter-options "output=$_TMP/qa-web-cypress-results.json" \
  2>&1 | tee "$_TMP/qa-web-output.txt"
echo "EXIT_CODE: $?"
```

**Selenium (JS/TS):**
```bash
npx jest --testPathPattern="(test|e2e)/.*\\.(test|spec)\\.(ts|js)$" --forceExit \
  2>&1 | tee "$_TMP/qa-web-output.txt"
echo "EXIT_CODE: $?"
# Java: mvn test | Python: pytest tests/ | C#: dotnet test
```

**Playwright (.NET) / Selenium (.NET)** (when `_TARGET_LANG=csharp`):
```bash
export BASE_URL="${BASE_URL:-$_BASE_URL}"
export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"
_RUNSETTINGS=""
[ -f "playwright.runsettings" ] && _RUNSETTINGS="--settings playwright.runsettings"
dotnet test $_RUNSETTINGS \
  --logger "json;LogFileName=$_TMP/qa-web-dotnet-results.json" \
  2>&1 | tee "$_TMP/qa-web-output.txt"
echo "EXIT_CODE: $?"
```

Parse Playwright JSON results (if applicable):

```bash
python3 - << 'PYEOF'
import json, os
tmp = os.environ.get("TEMP") or os.environ.get("TMP") or "/tmp"
for fname in [f"{tmp}/qa-web-results.json", f"{tmp}/qa-web-cypress-results.json"]:
    if not os.path.exists(fname): continue
    data = json.load(open(fname))
    stats = {"passed": 0, "failed": 0, "skipped": 0, "failures": []}
    def walk(suites):
        for s in suites:
            for t in s.get("tests", []):
                r = (t.get("results") or [{}])[-1]
                st = r.get("status", "failed")
                if st == "passed": stats["passed"] += 1
                elif st in ("skipped","pending"): stats["skipped"] += 1
                else:
                    stats["failed"] += 1
                    for e in r.get("errors", []):
                        stats["failures"].append({"title": t.get("title"), "error": e.get("message","")[:200]})
            walk(s.get("suites", []))
    walk(data.get("suites", []))
    print(json.dumps(stats, indent=2))
    break
PYEOF
```

## Phase 4 — Report

Write report to `$_TMP/qa-web-report.md`:

```markdown
# QA Web Report — <date>

## Summary
- **Status**: ✅ / ❌
- Passed: N · Failed: N · Skipped: N
- Framework: Playwright / Cypress / Selenium
- Base URL: <url>

## Test Results
| Test | Status | Duration |
|------|--------|----------|

## Failures
<list each failure with title + first 200 chars of error>

## Coverage Map
| Page/Flow | Tests | Status |
|-----------|-------|--------|
```

Print report path. If failures exist: "Found N failing web tests. Run /investigate to diagnose?"

## Important Rules

- **Never delete existing specs** — only add new describe/test blocks
- **Stable selectors only** — role, label, testid, data-cy — never raw CSS classes
- **Report even if execution fails** — always write the report file regardless of outcome
- **Auth setup is a prerequisite** — create it before running protected tests
