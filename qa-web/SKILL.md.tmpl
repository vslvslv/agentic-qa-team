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

# Chaos seed mode detection (BL-023)
_SEED_MODE="${QA_SEED_MODE:-clean}"
echo "SEED_MODE: $_SEED_MODE"
[ "$_SEED_MODE" = "chaos" ] && \
  echo "CHAOS_MODE: active — E2E tests running against chaos-seeded data; new failures may indicate data-handling regressions"

# Shortest NL mode detection (BL-049)
_SHORTEST_AVAILABLE=0
command -v shortest >/dev/null 2>&1 && _SHORTEST_AVAILABLE=1
grep -q '"shortest"' package.json 2>/dev/null && _SHORTEST_AVAILABLE=1
_NL_TESTS_EXIST=0
[ -f "tests.nl.md" ] && _NL_TESTS_EXIST=1
echo "SHORTEST_AVAILABLE: $_SHORTEST_AVAILABLE"
echo "NL_TESTS_EXIST: $_NL_TESTS_EXIST"

# OTel traceparent injection detection (BL-055)
_OTEL_AVAILABLE=0
[ -n "$OTEL_EXPORTER_OTLP_ENDPOINT" ] && _OTEL_AVAILABLE=1
echo "OTEL_AVAILABLE: $_OTEL_AVAILABLE"
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

## Phase 1.5 — CI Grounding

Before generating new tests, capture the current state of the existing suite so generation targets real gaps and failing paths — not scenarios that already pass.

```bash
_CI_GROUND_FILE="$_TMP/qa-web-ci-ground.txt"
echo "--- CI GROUNDING ---"

_EXISTING_SPECS=$(find . \( \
  -path "*/e2e/*.spec.ts" -o -path "*/tests/*.spec.ts" \
  -o -path "*/cypress/**/*.cy.ts" -o -path "*/cypress/**/*.cy.js" \
  -o -name "*Tests.cs" -o -name "*Test.cs" -o -name "*Spec.cs" \
  \) ! -path "*/node_modules/*" ! -path "*/obj/*" 2>/dev/null | wc -l | tr -d ' ')
echo "EXISTING_SPECS: $_EXISTING_SPECS"

if [ "$_EXISTING_SPECS" -gt 0 ] && [ "$_STATUS" = "200" ]; then
  case "$_WEB_TOOL" in
    playwright)
      timeout 120 npx playwright test --reporter=list 2>&1 | tail -60 > "$_CI_GROUND_FILE" || true
      ;;
    playwright-dotnet|selenium-dotnet)
      timeout 120 dotnet test --logger "console;verbosity=minimal" 2>&1 | tail -60 > "$_CI_GROUND_FILE" || true
      ;;
    cypress)
      timeout 120 npx cypress run --headless --reporter list 2>&1 | tail -60 > "$_CI_GROUND_FILE" || true
      ;;
    *)
      echo "CI_GROUND_STATUS: skipped (no runner matched)" | tee "$_CI_GROUND_FILE"
      ;;
  esac
  echo "CI_GROUND_STATUS: captured"
  grep -E "failed|passed|error|FAIL|PASS|✓|✗|×" "$_CI_GROUND_FILE" | head -30
else
  echo "CI_GROUND_STATUS: skipped (no existing specs or app not running)" | tee "$_CI_GROUND_FILE"
fi
```

Use the CI grounding output when generating tests in Phase 2:
- **Failures found** → generate tests that reproduce or specifically cover the failing paths first
- **All passing** → focus generation on uncovered pages/flows from the Phase 1 inventory
- **No existing specs** → generate a full baseline test suite

---

## Phase 2 — Load Tool Patterns & Generate Tests

Read the tool-specific patterns file for the selected `_WEB_TOOL`:

```
Read qa-web/tools/<_WEB_TOOL>.md
```

### Multi-Browser Configuration

Default to 3-browser matrix unless `QA_BROWSERS` env var overrides:

```bash
_QA_BROWSERS="${QA_BROWSERS:-chromium,firefox,webkit}"
echo "QA_BROWSERS: $_QA_BROWSERS"
```

When generating `playwright.config.ts` (if it does not already have a `projects` array), include:

```typescript
projects: [
  // Conditionally include each browser based on QA_BROWSERS env var
  ...(!(process.env.QA_BROWSERS) || process.env.QA_BROWSERS.includes('chromium') ? [{
    name: 'chromium', use: { ...devices['Desktop Chrome'] }
  }] : []),
  ...(!(process.env.QA_BROWSERS) || process.env.QA_BROWSERS.includes('firefox') ? [{
    name: 'firefox', use: { ...devices['Desktop Firefox'] }
  }] : []),
  ...(!(process.env.QA_BROWSERS) || process.env.QA_BROWSERS.includes('webkit') ? [{
    name: 'webkit', use: { ...devices['Desktop Safari'] }
  }] : []),
],
```

If existing config already has a `projects` array: do NOT override it — just note which browsers are configured.

### OTel Traceparent Injection (BL-055)

If `_OTEL_AVAILABLE=1` (`OTEL_EXPORTER_OTLP_ENDPOINT` is set), add traceparent injection to
the generated Playwright config and spec fixtures so every test-driven HTTP request carries a
known trace ID — enabling correlation to backend Jaeger/Tempo traces on failure.

Add to generated `playwright.config.ts` (near the top, before `export default`):

```typescript
// OTel SDK init — only when OTEL endpoint configured
import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { Resource } from '@opentelemetry/resources';
if (process.env.OTEL_EXPORTER_OTLP_ENDPOINT) {
  new NodeSDK({
    resource: new Resource({ 'service.name': 'playwright-tests' }),
    traceExporter: new OTLPTraceExporter(),
  }).start();
}
```

Add to generated spec files in the `test.beforeEach` block:

```typescript
test.beforeEach(async ({ page }) => {
  if (process.env.OTEL_EXPORTER_OTLP_ENDPOINT) {
    const traceId = crypto.randomUUID().replace(/-/g, '');
    const spanId = Math.random().toString(16).slice(2, 18).padStart(16, '0');
    const traceparent = `00-${traceId}-${spanId}-01`;
    // Annotate test with trace ID for correlation on failure
    test.info().annotations.push({ type: 'traceId', description: traceId });
    await page.route('**/*', (route) =>
      route.continue({ headers: { ...route.request().headers(), traceparent } })
    );
  }
});
```

On test failure, include the `traceId` annotation in the Phase 4 report so the backend
distributed trace can be retrieved from Jaeger/Tempo for root-cause analysis.

### Natural Language Mode (BL-049)

If `_SHORTEST_AVAILABLE=1` or `_NL_TESTS_EXIST=1`, generate a `<feature>.shortest.ts`
file alongside standard Playwright specs. NL test descriptions are interpreted at runtime
by Claude — no selector code is maintained by hand.

**When to use:** tests authored in TCMS as acceptance criteria bullets, or when `tests.nl.md`
exists with plain-English descriptions.

```typescript
// e2e/login.shortest.ts
import { shortest } from '@antiwork/shortest';

shortest('User can log in with valid credentials and reach the dashboard');
shortest('User sees an error message with wrong password');
shortest('User can log out and is redirected to the login page');
```

**Run**: `npx shortest` (interprets each string via Claude → Playwright execution → pass/fail).

If `tests.nl.md` exists: parse each line as a `shortest()` call and generate the file.
On failure: Claude receives the failing sentence + DOM snapshot → rewrite the intent
description rather than a CSS selector.

Note: `shortest` requires `ANTHROPIC_API_KEY` set in the environment.

Then select and read the language-appropriate reference guide based on `_WEB_TOOL` and `_TARGET_LANG`:

**Playwright — TypeScript** (when `_TARGET_LANG` is not `csharp`):
> Reference: [Playwright patterns guide (TypeScript)](references/playwright-patterns.md)
> Key patterns: POM + fixture injection · storageState auth (single/multi-role/API-based/worker-scoped) · IndexedDB in storageState (v1.51+) · OAuth + MFA + magic link auth · locator rank · web-first assertions · soft assertions · network mocking + HAR recording + network-cache · test sharding · visual regression · `expect.poll`/`toPass` · accessibility with axe-core · aria snapshots (`toMatchAriaSnapshot` + `locator.ariaSnapshot()` + `mode: 'ai'`) · test annotations/tagging · global setup via project deps · custom reporters (HTML `title` v1.53+) · multi-environment projects · custom matchers · keyboard/focus testing · browser storage manipulation · performance timing · mobile emulation · clock mocking · geolocation · test attachments · debug workflow · TypeScript config + ESLint · typed POM factory · WebSocket testing + `routeWebSocket` · pure API test suites · `addLocatorHandler` overlay dismissal · post-facto inspection APIs (`consoleMessages`/`pageErrors`/`requests`) · `locator.normalize()` · `locator.describe()` · Screencast API + `showActions()` · Docker deployment · auto-fixture suite scaling · `browser.bind()` multi-client · Playwright Test Agents (Planner/Generator/Healer v1.56+) · `launchPersistentContext` session reuse · `maxRedirects` APIRequestContext · `snapshotPath({ kind })` · cloud scaling (Currents/Moon/remote server) · breaking changes reference (v1.45–v1.59) · `pressSequentially()` for autocomplete/OTP · `locator.all()` + `allTextContents()` · `filter({ hasNot, hasNotText })` exclusion · `toHaveCSS()` computed style assertions · `toBeInViewport({ ratio })` scroll visibility · `page.pdf()` PDF generation testing
> Breaking changes: `page.accessibility` removed (v1.57) → use `toMatchAriaSnapshot` / axe-core · Chrome for Testing replaces Chromium builds (v1.57) · React 16/17 CT support removed (v1.57) · `@playwright/experimental-ct-svelte` removed (v1.59) · macOS 14 WebKit dropped (v1.59)

**Playwright — C#** (when `_TARGET_LANG=csharp`):
> Reference: [Playwright patterns guide (C#)](references/playwright-patterns-csharp.md)
> Key patterns: PageTest base class (NUnit/MSTest/xUnit) · IPage/ILocator · C# POM · StorageStateAsync auth · selector strategy · web-first assertions via `Expect()` · network mocking · `.runsettings` config · `dotnet test` execution
> Focus on the section matching `CS_TEST_FW` (`nunit`, `mstest`, or `xunit`).

**Cypress**:
> Reference: [Cypress patterns guide](references/cypress-patterns.md)
> Key patterns: cy.session() auth (role-keyed validate callback) · cy.intercept() routeMatcher object form + RouteHandler (spy/modify/delay/req.alias dynamic aliasing) · cy.intercept() times option · data-cy selectors + typed selector maps (as const) · custom commands + Commands.overwrite() + Commands.addQuery() · cy.request() seeding + form/multipart · cy.spy() + sinon.match · Component Testing (React Context + Redux providers) · cy.fixture() with TypeScript generics · test isolation · cy.origin() OAuth/SSO · cy.task() typed with generics · cy.within() scoping · cy.selectFile() file uploads · cy.clock()/cy.tick() timer control · cy.exec() shell commands · cy.all() v13.4+ parallel assertions · CDP network throttling (Cypress.automation) · Shadow DOM (includeShadowDom + .shadow()) · iframe testing (cypress-iframe) · chai-subset API assertions · download testing (readFile + downloadsFolder) · localStorage (getAllLocalStorage/onBeforeLoad) · cy.focused() accessibility · cookie management · GraphQL intercept by operationName · multi-alias cy.wait([]) · spec-level config overrides · multi-step wizard pattern · conditional testing anti-pattern · experimentalWebKitSupport · experimentalModifyObstructiveThirdPartyCode · Cypress Cloud Smart Orchestration · Module API programmatic runs · CI parallelization + Cypress Cloud flaky detection · a11y (cypress-axe) · visual regression (@percy/cypress) · test tagging with @cypress/grep

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

## Phase 2.5 — Spec Quality Gate

Review every generated `it()` / `test()` / `[Test]` / `[Fact]` block before proceeding to execution. For each test, verify all three criteria:

1. **Non-trivial assertion** — the test asserts something meaningful (a specific value, a visible element, a text match). Reject tests that only assert `expect(true).toBe(true)` or assert page loaded without verifying any content.
2. **Real interaction coverage** — the test exercises an actual user action (form submit, button click, navigation, input). Reject tests that navigate to a URL but never interact with or assert on its content.
3. **Failure sensitivity** — ask: "If this feature broke, would this test catch it?" If no, rewrite.

For each test block that **fails the gate**:
- Identify which criterion it fails
- Rewrite to add a meaningful assertion or interaction step
- Log: `QUALITY GATE: rewrote "<test title>" — <reason>`

**Do not proceed to Phase 3 until all generated tests pass the quality gate.**

Bad (fails gate — no assertion on content):
```typescript
it("renders the dashboard", async () => {
  await page.goto("/dashboard"); // would pass even if page returns 500
});
```

Good (passes gate):
```typescript
it("renders the dashboard", async () => {
  await page.goto("/dashboard");
  await expect(page.getByRole("heading", { name: "Dashboard" })).toBeVisible();
  await expect(page.getByTestId("stats-panel")).toBeVisible();
});
```

## Phase 2.6 — Cross-Browser Locator Audit

Runs only when multi-browser projects are configured (`_QA_BROWSERS` contains more than one browser, or config has multiple projects).

Collect potentially fragile locators from spec files:

```bash
grep -rE '\.(locator|getBy[A-Z])\(' e2e/ tests/ --include="*.spec.ts" --include="*.spec.js" \
  ! -path "*/node_modules/*" 2>/dev/null | grep -oE '"[^"]+"' | sort -u | head -50
```

Flag locators containing CSS classes (`.class-name`) or XPath patterns (`//div/span`) — these are cross-browser fragile.

For each flagged locator pattern:
- Suggest rewrite to stable selector: `getByRole` > `getByLabel` > `getByTestId`
- Apply fix via Edit tool if fix confidence is high (unambiguous role or label available)
- Flag for review if ambiguous

Add `### Cross-Browser Locator Audit` section to Phase 4 report:
| Locator | Issue | Suggested Fix | Applied |
|---------|-------|---------------|---------|

---

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
npx playwright test $_SPEC_FILES --reporter=json \
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

If `_SEED_MODE=chaos` is active, prepend this warning block to the report (before the Summary table):
> ⚠️ **Chaos mode active** (`QA_SEED_MODE=chaos`): any new test failures compared to clean-seed runs may indicate data-handling regressions. Compare with baseline clean-seed results to isolate chaos-induced failures.

```markdown
# QA Web Report — <date>

## Summary
- **Status**: ✅ / ❌
- Passed: N · Failed: N · Skipped: N
- Framework: Playwright / Cypress / Selenium
- Base URL: <url>

## Diagnosis
*(Complete this section when EXIT_CODE != 0, before listing individual failures.)*
| Field | Detail |
|-------|--------|
| What broke | <test name(s) and assertion type that failed> |
| Expected | <what the test asserted — e.g., element visible, status 200, text present> |
| Got | <what was actually returned or rendered> |
| Likely root cause | <selector changed / API contract drift / timing / env config mismatch> |
| Pre-existing? | yes — also failed in CI grounding run / no — regression introduced this session |

## Test Results
| Test | Status | Duration |
|------|--------|----------|

## Failures
<list each failure with title + first 200 chars of error>

## Coverage Map
| Page/Flow | Tests | Status |
|-----------|-------|--------|

## Browser Matrix
| Browser | Tests Run | Passed | Failed | Skipped |
|---------|-----------|--------|--------|---------|
| Chromium | N | N | N | N |
| Firefox | N | N | N | N |
| WebKit | N | N | N | N |

Note: Opt out of a browser with `QA_BROWSERS=chromium,firefox` (omit webkit).
```

When `EXIT_CODE != 0`, the **Diagnosis** section is mandatory — complete it before listing individual failures. Cross-reference `$_TMP/qa-web-ci-ground.txt` to determine if each failure is pre-existing or a new regression. Never skip straight to listing failures.

For each failing test, check `./qa-flaky-registry.json` if present. If `flakeRate > 0.2`, annotate `[FLAKY N%]` instead of `[FAILED]` in the report.

Print report path. If failures exist: "Found N failing web tests. Run /investigate to diagnose?"

## CTRF Output

After writing `$_TMP/qa-web-report.md`, write `$_TMP/qa-web-ctrf.json`:

```python
python3 - << 'PYEOF'
import json, os, time, re

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
pw_output = open(os.path.join(tmp, 'qa-web-pw-output.txt'), encoding='utf-8', errors='replace').read() \
            if os.path.exists(os.path.join(tmp, 'qa-web-pw-output.txt')) else ''

tests = []
# Try to parse test names and results from Playwright JSON output or text output
passed_count = len(re.findall(r'✓|passed', pw_output))
failed_count = len(re.findall(r'✕|failed', pw_output))
skipped_count = len(re.findall(r'skipped|pending', pw_output))

# Build synthetic test entries from output lines if no JSON reporter
lines = pw_output.splitlines()
for line in lines:
    m_pass = re.match(r'\s+✓\s+(.+)', line)
    m_fail = re.match(r'\s+[✕×]\s+(.+)', line)
    if m_pass:
        tests.append({'name': m_pass.group(1).strip(), 'status': 'passed', 'duration': 0, 'suite': 'e2e'})
    elif m_fail:
        tests.append({'name': m_fail.group(1).strip(), 'status': 'failed', 'duration': 0, 'suite': 'e2e',
                      'message': 'See qa-web-report.md for details'})

# If no granular tests parsed, emit summary buckets
if not tests:
    if passed_count:
        tests.append({'name': f'{passed_count} tests passed', 'status': 'passed', 'duration': 0, 'suite': 'e2e'})
    if failed_count:
        tests.append({'name': f'{failed_count} tests failed', 'status': 'failed', 'duration': 0, 'suite': 'e2e',
                      'message': 'See qa-web-report.md for details'})
    if skipped_count:
        tests.append({'name': f'{skipped_count} tests skipped', 'status': 'skipped', 'duration': 0, 'suite': 'e2e'})

p = sum(1 for t in tests if t['status'] == 'passed')
f = sum(1 for t in tests if t['status'] == 'failed')
s = sum(1 for t in tests if t['status'] == 'skipped')
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': os.environ.get('_WEB_TOOL', 'playwright')},
        'summary': {
            'tests': len(tests), 'passed': p, 'failed': f,
            'pending': 0, 'skipped': s, 'other': 0,
            'start': now_ms - 5000, 'stop': now_ms,
        },
        'tests': tests,
        'environment': {
            'reportName': 'qa-web',
            'baseUrl': os.environ.get('_BASE_URL', 'unknown'),
        },
    }
}

out = os.path.join(tmp, 'qa-web-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  tests={len(tests)} passed={p} failed={f} skipped={s}')
PYEOF
```

## Important Rules

- **Never delete existing specs** — only add new describe/test blocks
- **Stable selectors only** — role, label, testid, data-cy — never raw CSS classes
- **Report even if execution fails** — always write the report file regardless of outcome
- **Auth setup is a prerequisite** — create it before running protected tests

## Agent Memory

After each run, update the memory file at `.claude/agent-memory/qa-web/MEMORY.md` (create if absent). Record:
- Detected framework, version, and config file paths
- Auth endpoint and credential format used
- Recurring failures or known flaky scenarios
- Base URL confirmed working
- Any test infrastructure quirks discovered

Read this file at the start of each run to skip re-detection of already-known facts.
