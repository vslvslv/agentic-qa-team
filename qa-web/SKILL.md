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

# Detect base URL
_BASE_URL=$(grep -r "baseURL\|BASE_URL" playwright.config.ts playwright.config.js cypress.config.ts .env .env.local 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
_BASE_URL="${_BASE_URL:-http://localhost:3000}"
echo "BASE_URL: $_BASE_URL"

# Check if app is running
_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$_BASE_URL" 2>/dev/null || echo "000")
echo "APP_STATUS: $_STATUS"

# Existing test specs
echo "--- EXISTING SPECS ---"
find . \( -path "*/e2e/*.spec.ts" -o -path "*/tests/*.spec.ts" \
  -o -path "*/cypress/**/*.cy.ts" -o -path "*/cypress/**/*.cy.js" \
  -o -path "*/test/*.test.ts" -o -path "*/test/*.test.js" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -20

# Pages / routes
echo "--- APP ROUTES ---"
find . \( -path "*/pages/*.tsx" -o -path "*/pages/*.jsx" -o -path "*/app/**/*.tsx" \
  -o -path "*/views/*.tsx" -o -path "*/routes/*.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -30
```

### Tool Selection Gate

Count detected tools from `PLAYWRIGHT_PRESENT`, `CYPRESS_PRESENT`, `SELENIUM_PRESENT`.

**Exactly one detected** → use that tool automatically. Set `_WEB_TOOL` to `playwright`,
`cypress`, or `selenium`.

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

Then for each **critical** and **important** page from Phase 1, generate test specs
following the patterns in that file. Also check the qa-refine reference guide if it
exists:

- Playwright: `qa-web/references/playwright-patterns.md`
- Cypress: `qa-web/references/cypress-patterns.md`
- Selenium: `qa-web/references/selenium-patterns.md`

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
