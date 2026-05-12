---
name: qa-refine
version: 1.3.0.0
description: |
  Iteratively researches QA tools used in this project (Playwright, Cypress, Selenium,
  k6, JMeter, Locust, Detox, Appium, WebDriverIO, Maestro) across official documentation
  AND community sources, then generates test code examples in the project's actual
  language (TypeScript, JavaScript, Java, Python, C#, Ruby, or any other). Runs an
  autoresearch-style loop scoring against a 4-dimension rubric (0–100) until score ≥ 80
  or 3 iterations. Also makes surgical updates to the corresponding SKILL.md.tmpl.

  Use this skill whenever the user asks to:
  - "research [tool] best practices / patterns / design"
  - "create a Page Object Model guide" or "set up POM for our tests"
  - "update qa-web / qa-perf / qa-mobile from the docs"
  - "improve our Playwright / Cypress / Selenium selectors or test structure"
  - "improve our k6 / JMeter / Locust load test scripts"
  - "improve our Detox / Appium / Maestro mobile tests"
  - "refresh QA skills from official documentation"
  - "what are the latest best practices for [any QA tool]?"
  Proactively suggest running this skill after any conversation where the user mentions
  struggling with selectors, flakiness, auth patterns, or load test structure.
allowed-tools:
  - WebFetch
  - WebSearch
  - Read
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---

## Preamble

You are a QA documentation researcher running an autoresearch-style refinement loop.
Your job is to synthesize knowledge from **official docs AND community sources**, generate
test examples in the **project's actual language**, and iteratively improve the result
until it scores ≥ 80/100 on the quality rubric below.

### Version Check

!`bash "${CLAUDE_SKILL_DIR}/../bin/qa-version-check-inline.sh" 2>/dev/null || echo "VERSION_STATUS: UPDATE_CHECK_FAILED"`

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `SKIP_UPDATE_ASK` is `0`, use `AskUserQuestion`: "qa-agentic-team update available. Update before running?" Options: "Yes — update now (recommended)" | "No — run with current version". If yes: `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup"`. Continue regardless.

### Step 0 — Detect target language

Before fetching any docs, determine which language to use for code examples:

1. **Scan for project signals** (use Glob/Bash, read only, do not modify anything):
   - `pom.xml` or `build.gradle` → **Java**
   - `requirements.txt`, `pytest.ini`, `conftest.py`, `pyproject.toml` → **Python**
   - `*.csproj` or `*.sln` → **C#**
   - `Gemfile` or `*.gemspec` → **Ruby**
   - `tsconfig.json` present, or `package.json` has `typescript`, `ts-jest`, or `@types/node`, or `.ts`/`.tsx` files found in `src/` → **TypeScript**
   - `package.json` without TypeScript signals → **JavaScript**

2. If the user explicitly names a language ("in Java", "Python examples"), use that.

3. If no signals found and none named, ask: "Which language should test examples use?
   (TypeScript / JavaScript / Java / Python / C# / Ruby / other)"

4. **Exceptions** — these tools are single-language regardless of project signals:
   - k6: always **JavaScript/TypeScript** (official docs use JS examples; TS supported via bundler)
   - Detox: always **JavaScript/TypeScript**
   - WebDriverIO: always **TypeScript/JavaScript**
   - Cypress: always **TypeScript/JavaScript**
   - Locust: always **Python**
   - Maestro: always **YAML** (no code language — skip TARGET_LANG detection, write flow files)

Store the detected language as `TARGET_LANG` and use it throughout.

---

**Quality rubric (0–100, four dimensions of 25 each):**

| Dimension | 0 | 12 | 25 | What earns full marks |
|-----------|---|----|----|----------------------|
| Pattern Coverage | No patterns | Some | All major patterns for this tool | Per-tool checklist below |
| Code Quality | No examples | Generic snippets | Copy-paste-ready, idiomatic for `TARGET_LANG` | Correct API names, real imports for the language, ≥ 3 runnable examples ≥ 5 lines |
| Depth | Surface only | Common cases | Edge cases + CI/flakiness + scale | CI quirks, auth/MFA, scaling, timeout tuning |
| Community Signal | None | Some warnings | Named real-world gotchas + WHY | ≥ 5 production pitfalls tagged `[community]` with one-sentence WHY each |

Target: **score ≥ 80** or **3 iterations** or **delta < 5** → stop.

**Tool → skill mapping + pattern checklist:**

| Tool | Skill dir(s) | Pattern checklist |
|------|-------------|-------------------|
| Playwright | qa-web, qa-visual, qa-api | POM, fixture-based auth (storageState + IndexedDB), locator rank, web-first assertions, API request context, network mocking, soft assertions, test sharding, component testing (--ct), aria snapshots (toMatchAriaSnapshot), locator.describe(), failOnFlakyTests, per-project workers, async disposables (await using), Shadow DOM traversal, visibility filter (filter({visible:true})), frame/frameLocator conversion (owner/contentFrame), mergeExpects, project teardown, webServer.wait (stdout capture), TLS client certificates, test data factory, network throttling (CDP + route delay), clipboard testing, print emulation, browser.bind() multi-client, component.update()/component.unmount() lifecycle, testStepInfo.titlePath (custom reporter breadcrumbs), sessionStorage addInitScript workaround (storageState limitation), APIRequestContext disposal guard (route.fetch() after context close), module-level mock isolation in CT (vi.mock/jest.mock browser boundary), toHaveAccessibleName/toHaveRole/toHaveAccessibleDescription (v1.44+), toBeChecked({indeterminate}) (v1.50+), --test-list/--test-list-invert CLI flags (v1.56+), context.clearCookies({filter}) (v1.43+), context.isClosed() guard (v1.59+), step.skip()/step.attach() inside test.step body (v1.51+), consoleMessage.timestamp() (v1.59+), Speedboard HTML reporter tab (v1.57+), popup first request interception (context.route vs page.route), page.requestGC() memory leak detection (Chromium-only v1.48+), tracing.group()/groupEnd() Trace Viewer grouping (v1.49+), ControlOrMeta cross-platform keyboard modifier (v1.45+), webServer.gracefulShutdown (v1.50+), test.fail.only() focused expected-failure (v1.49+), multiple globalSetup/globalTeardown array (v1.49+), screenshot 'on-first-failure' storage-efficient CI (v1.49+), updateSourceMethod patch/overwrite/3-way (v1.50+), dialog handler contract (accept/dismiss or hangs), page.evaluateHandle() multi-handle destructuring, deviceScaleFactor HiDPI/Retina emulation, testResult.annotations per-retry reporter access (v1.52+), npx playwright init-agents --loop=<vscode|claude|opencode> AI agent project bootstrap (v1.56+), worker.on('console') service worker message capture (v1.57+), page.emulateMedia({contrast}) prefers-contrast testing (v1.51+), expect(fn).toPass({intervals}) custom retry back-off (v1.44+), expect(page).toHaveURL(predicate) function-based URL assertion (v1.44+), expect(page).toMatchAriaSnapshot() full-page ARIA assertion (v1.60+), HTML reporter noSnippets option (v1.54+), page.close/context.close({reason}) diagnostic close (v1.40+) |
| Cypress | qa-web | cy.session() auth, cy.intercept() mocking (with times option + req.alias dynamic aliasing), data-cy selectors, custom commands (addQuery/overwrite), cy.request() API testing (form data/multipart), Component Testing (with providers: React Context/Redux), cy.fixture(), retry-ability, Page Object Model (TypeScript class-based), cy.selectFile() file uploads, typed selector maps (as const), typed cy.task() with generics, cy.location() URL assertions, responsive viewport testing, Shadow DOM traversal (includeShadowDom + .shadow()), iframe testing (cypress-iframe), cy.exec() shell commands, cy.its()/cy.invoke() property/method access, uncaught:exception handling, cy.all() parallel assertions (v13.4+), CDP network throttling (Cypress.automation), sinon.match matchers, cy.each() iteration, cy.focused() keyboard accessibility, cy.go()/cy.reload() navigation, chai-subset API assertions, cy.title()/cy.hash(), cy.window()/cy.document() state access, GraphQL intercept by operationName, multi-alias cy.wait([]), cookie management (getCookie/setCookie/clearCookie), cy.clock()/cy.tick() timer control, cy.intercept() times option, Cypress.config() runtime reading, download testing (readFile + downloadsFolder), conditional testing anti-pattern, .should(callback) complex assertions, .filter()/.not() collection narrowing, localStorage testing (getAllLocalStorage/onBeforeLoad), DOM traversal (find/closest/siblings/parent/children), Cypress._ Lodash utilities, spec-level config overrides, multi-step wizard pattern, keyboard shortcuts (type special keys), cy.check()/cy.uncheck()/cy.select(), window.open()/window.print() stubs, slow typing with delay option, experimentalWebKitSupport, experimentalModifyObstructiveThirdPartyCode, Cypress Cloud Smart Orchestration, React SSR hydration bootstrap script (data-cy-bootstrap Cy 15.11+), Cypress.ElementSelector.defaults() selectorPriority (Cy 15+), allowCypressEnv:false migration enforcement |
| Selenium | qa-web | By.* selector hierarchy, Page Object Model (language-specific), explicit waits (WebDriverWait + ExpectedConditions), fluent waits, headless mode, screenshot on failure, Actions class |
| k6 | qa-perf | Test type taxonomy, scenarios/executors, thresholds + abortOnFail, check() patterns, setup/teardown auth, custom metrics, handleSummary, secrets management (k6/secrets), MFA/TOTP auth, distributed tracing (http-instrumentation-tempo), browser module (getBy* locators + throttling), gRPC, WebSocket, GraphQL, HMAC signing, v2.0.0 migration, locator.filter()/all()/nth()/first()/last(), page.waitForRequest(), page.waitForEvent(), page.on(requestfailed/requestfinished), frameLocator(), page.goBack()/goForward(), locator.evaluate()/evaluateHandle(), locator.pressSequentially(), k6 deps CLI, --new-machine-readable-summary, page.unroute()/unrouteAll(), mcp-k6 AI integration, OpenTelemetry stable (v1.4+), PBKDF2 WebCrypto key derivation |
| JMeter | qa-perf | Thread Group (ramp-up, loop count), HTTP Request Sampler, CSV Data Set Config, Response Assertion, Summary/Aggregate Report, JMeter properties for CI, Dashboard generation, distributed testing, non-GUI mode |
| Locust | qa-perf | HttpUser vs FastHttpUser, @task with weight, on_start/on_stop, wait_time strategies, headless run flags, events hook for custom metrics, CSV output, environment parametrization |
| Detox | qa-mobile | Matcher priority (by.id/by.label/by.value/by.type/by.text/by.system/by.web), auto-sync/disableSynchronization (narrow scope with try/finally), waitFor idioms (toBeVisible/toHaveValue/toHaveLabel/toHaveToggleValue), beforeEach reset (newInstance/reloadReactNative/delete), CI animation disable, artifact collection, advanced gestures (adjustSliderToPosition/longPressAndDrag/tapAtPoint/multiTap/pinch), accessibility testing (toHaveLabel/toHaveToggleValue), TypeScript setup (e2e/tsconfig.json, ts-jest, built-in types), captureViewHierarchy for debugging, --debug-synchronization CLI flag, --reuse flag (local iteration only), testRunner.retries vs jest retryTimes, dark mode (device.setAppearance), sendUserActivity (Handoff/Spotlight), feature-flag variant testing, Bridgeless Mode (RN 0.74+ TurboModule launchArgs), multi-app install/uninstall, WebView testing (by.web() matchers + web element interactions), visual regression (device.takeScreenshot + pixelmatch), JUnit XML reporting (jest-junit shard-specific), device.resetContentAndSettings() deep simulator reset, by.system() full dialog workflow (permissions/alerts/sheets + locale-aware label map), device.openURL() deep link warm+cold start, parallel worker config (GitHub Actions matrix + JEST_WORKER_ID isolation), by.traits() iOS accessibility traits (button/selected/notEnabled/adjustable), element.getAttributes() extended inspection (frame/value/enabled/focused), device.shake() iOS Simulator shake with Android fallback |
| Appium / WebDriverIO | qa-mobile | Page Object pattern, accessibility-id selector (~), aria/ selector (WebView), mobile gestures (browser.swipe v9+, W3C pointer actions replaces touchAction), parallel device execution (wdaLocalPort iOS / systemPort Android), CI Appium server config (@wdio/appium-service v9 appiumArgs), biometric auth simulation, multi-app context switching, expect() matchers vs waitFor*(), browser.mock() network interception (WebView/CDP), mobile:pressButton (iOS: home/lock/volumeup/siri), Android mobile:deepLink vs intent, browser.deepLink() / browser.restartApp() native commands (v9.10), TypeScript 'using' keyword for resource management, browser.executeAsync() async script injection, appium:mjpegServerPort MJPEG streaming, @wdio/visual-service (addIOSBezelCorners/JSON reports), appium:newCommandTimeout session keepalive, Android AVD auto-launch (avdArgs: -no-audio/-no-window/-gpu swiftshader_indirect/-no-snapshot), browser.switchWindow() multi-tab WebView, browser.getPageSource() XML parsing, appium:autoAcceptAlerts vs manual, app lifecycle (activateApp vs launchApp deprecated vs terminateApp), W3C Actions API (tap/longPress/pinch-zoom), browser.swipe() v9, TypeScript ChainablePromiseElement null-safe patterns, driver.getDeviceTime() timezone testing, browser.waitUntil() exponential backoff, screen rotation (setOrientation), appium:chromedriverAutodownload, drag-and-drop (dragAndDrop/dragFromToForDuration), element.getComputedRole(), appium:noReset vs fullReset, @wdio/shared-store-service device pool, cookie injection WebView auth, element.getProperty() vs getAttribute(), file upload (pushFile + DataTransfer), TypeScript capability interface extension, Android disableWindowAnimation, app version management (installApp/removeApp/queryAppState), appium:webviewConnectRetries, WDIO specs/exclude/suite selective CI, eslint-plugin-wdio, WDIO v9 BiDi (Shadow DOM auto-pierce/fake timers), custom locator strategy, appium-installer, Allure v3 step API, CTRF reporting, Appium 3 protocol command renames (37 appium-prefixed commands + WDIO compatibility wrappers), screen recording API (startRecordingScreen/stopRecordingScreen iOS+Android), browser.on() event monitoring (request.performance/bidiCommand/bidiResult), browser.addInitScript() emit() BiDi DOM observer, TypeScript 7 erasableSyntaxOnly enum→const migration, disableElementImplicitWait v9.27.1 fix, Allure historyId capability-keyed fix (v9.27.1), defineConfig() typed config helper (v9.12), maskingPatterns sensitive data masking (v9.15), SoftAssertionService auto-include (v9.16), @wdio/xvfb Linux CI virtual display (v9.19), npx wdio inspector CLI Appium Inspector (v9.22), browser.url() enhanced headers/auth/onBeforeLoad options, browser.emulate() colorScheme/userAgent/onLine modes, toMatchSnapshot()/toMatchInlineSnapshot() native DOM snapshots |
| Maestro | qa-mobile | Flow YAML structure, appId, tapOn/inputText/assertVisible, runFlow (sub-flows), envFile for secrets, scroll/swipe, launchApp/stopApp, CI headless runner |

---

## Catalog Detection (run before Phase 1a)

```bash
# Learning sources catalog (catalog-first strategy)
echo "--- LEARNING SOURCES ---"
_LS_DIR="${CLAUDE_SKILL_DIR}/../learning-sources"
[ ! -d "$_LS_DIR" ] && _LS_DIR="./learning-sources"
_LS_AVAILABLE=0
[ -d "$_LS_DIR" ] && ls "$_LS_DIR"/*.md 2>/dev/null | grep -q '.' && _LS_AVAILABLE=1
echo "LEARNING_SOURCES_AVAILABLE: $_LS_AVAILABLE"
```

## Phase 1a — Official documentation

If `LEARNING_SOURCES_AVAILABLE=1`, read `$_LS_DIR/qa-tools.md` first. Filter to entries
matching `_TOPIC` (the current tool, e.g., `Playwright`, `k6`, `Cypress`). Use those URLs
as the primary source list. Supplement with the hardcoded fallback URLs below for any
tool version or language variant not covered in the catalog.

Fetch all official pages for the target tool **in parallel**. Prompt for every WebFetch:
> "Extract: (1) best practices as bullet points, (2) design patterns with code examples
> in `TARGET_LANG`, (3) recommended APIs with one-line descriptions, (4) anti-patterns
> and WHY they're harmful."

**If WebFetch is unavailable**, use Bash as a fallback. Node 18+ (required by this repo)
has built-in `fetch()` which can retrieve and strip HTML without extra dependencies:

```bash
# Fetch a URL and extract readable text — use when WebFetch is blocked
_fetch_text() {
  local url="$1"
  node --input-type=module <<EOF 2>/dev/null || python3 -c "
import urllib.request, html as ht, re
req = urllib.request.Request('$url', headers={'User-Agent':'Mozilla/5.0'})
try:
  with urllib.request.urlopen(req, timeout=15) as r:
    c = r.read().decode('utf-8','ignore')
  c = re.sub(r'<script[\s\S]*?</script>','',c,flags=re.I)
  c = re.sub(r'<style[\s\S]*?</style>','',c,flags=re.I)
  c = re.sub(r'<[^>]+>',' ',c)
  print(ht.unescape(re.sub(r'\s+',' ',c).strip())[:6000])
except Exception as e: print('FETCH_FAILED:', e)
"
const res = await fetch('$url', { headers: { 'User-Agent': 'Mozilla/5.0' } });
const html = await res.text();
const text = html
  .replace(/<script[\s\S]*?<\/script>/gi, '')
  .replace(/<style[\s\S]*?<\/style>/gi, '')
  .replace(/<[^>]+>/g, ' ')
  .replace(/&amp;|&lt;|&gt;|&quot;/g, ' ')
  .replace(/\s+/g, ' ').trim().slice(0, 6000);
console.log(text);
EOF
}

# Example: _fetch_text "https://playwright.dev/docs/best-practices"
# Run multiple in parallel: { _fetch_text URL1 & _fetch_text URL2 & wait; }
```

After fetching (by either method), synthesize the extracted text against the prompt above.
If both methods fail, synthesize from training knowledge and note the source in the file header.

### Existing reference files

Read the file for the current tool + language combination **before fetching** to extend
prior work rather than duplicate it.

| Tool | Language | File |
|------|----------|------|
| Playwright | TypeScript | `qa-web/references/playwright-patterns.md` |
| Playwright | TypeScript (baseline) | `qa-web/references/playwright-patterns-baseline.md` |
| Playwright | C# | `qa-web/references/playwright-patterns-csharp.md` |
| Cypress | TypeScript / JavaScript | `qa-web/references/cypress-patterns.md` |
| Selenium | TypeScript | `qa-web/references/selenium-patterns.md` |
| k6 | JavaScript | `qa-perf/references/k6-patterns.md` |
| k6 | JavaScript (baseline) | `qa-perf/references/k6-patterns-baseline.md` |
| JMeter | (XML / CLI) | `qa-perf/references/jmeter-patterns.md` |
| Locust | Python | `qa-perf/references/locust-patterns.md` |
| NBomber | C# | `qa-perf/references/nbomber-patterns.md` |
| Detox | JavaScript / TypeScript | `qa-mobile/references/detox-patterns.md` |
| Detox | JavaScript / TypeScript (baseline) | `qa-mobile/references/detox-patterns-baseline.md` |
| Appium / WDIO | TypeScript | `qa-mobile/references/appium-wdio-patterns.md` |
| Appium | Java | `qa-mobile/references/appium-patterns-java.md` |
| Appium | Python | `qa-mobile/references/appium-patterns-python.md` |
| Appium | C# | `qa-mobile/references/appium-patterns-csharp.md` |
| Maestro | YAML | `qa-mobile/references/maestro-patterns.md` |
| Vitest | TypeScript | `qa-web/references/vitest-patterns.md` |
| API testing | TypeScript | `qa-api/references/api-patterns-typescript.md` |
| API testing | Java | `qa-api/references/api-patterns-java.md` |
| API testing | Python | `qa-api/references/api-patterns-python.md` |
| API testing | C# (RestSharp or HttpClient) | `qa-api/references/api-patterns-csharp.md` |
| API testing | Ruby | `qa-api/references/api-patterns-ruby.md` |

**Playwright — URL set depends on TARGET_LANG:**

| Language | Base URL prefix |
|----------|----------------|
| TypeScript / JavaScript | `https://playwright.dev/docs/` |
| Java | `https://playwright.dev/java/docs/` |
| Python | `https://playwright.dev/python/docs/` |
| C# | `https://playwright.dev/dotnet/docs/` |

Pages to fetch (append to base URL):
`best-practices`, `pom`, `locators`, `test-fixtures`, `test-assertions`, `api-testing`, `network`, `auth`, `release-notes`, `test-retries`, `trace-viewer-intro`, `test-components`, `test-reporters`, `codegen`, `test-global-setup-teardown`, `test-parallel`, `test-sharding`, `accessibility-testing`

**See also:** `qa-web/references/playwright-patterns.md` (TypeScript), `qa-web/references/playwright-patterns-csharp.md` (C#), and `qa-web/references/vitest-patterns.md` (Vitest/TypeScript) — see reference files table above.
<!-- See also: qa-web/references/playwright-patterns.md — verified against v1.60; iteration 29 (2026-05-12) adds: npx playwright init-agents --loop=<vscode|claude|opencode> project setup workflow with seed tests (v1.56), worker.on('console') for service worker console messages (v1.57), page.emulateMedia({ contrast }) for prefers-contrast testing (v1.51), expect(fn).toPass({ intervals }) custom retry intervals (v1.44), expect(page).toHaveURL(predicate) function-based URL assertion (v1.44), expect(page).toMatchAriaSnapshot() full-page ARIA assertion (v1.60), HTML reporter noSnippets option (v1.54), page.close/browser.close/context.close with reason (v1.40); community gotchas #36 (toMatchAriaSnapshot locale drift — pin locale: en-US), #37 (worker.on console noise in parallel CI — filter by URL), #38 (toPass does not reset page state between retries — never put writes inside callback), #39 (contrast emulation has no effect in WebKit), #40 (init-agents overwrites definitions — commit to VCS); 40 community gotchas total; 8092 lines -->

**Vitest (TypeScript only):**
- `https://vitest.dev/guide/` — configuration, mocking, coverage, in-source testing
- `https://vitest.dev/guide/coverage` — V8 vs Istanbul coverage providers
- `https://vitest.dev/guide/workspace` — monorepo workspace setup
- `https://github.com/vitest-dev/vitest` — community examples and issues

**See also:** `qa-web/references/vitest-patterns.md` (TypeScript) — 7 community gotchas including `vi.mock` hoisting, jsdom environment overhead, globals TypeScript config, fake timer `Date` behavior, snapshot line endings, ES module spying, and V8 vs Istanbul branch coverage.

**k6 (JS only):**
- `https://grafana.com/docs/k6/latest/using-k6/best-practices/`
- `https://grafana.com/docs/k6/latest/test-types/`
- `https://grafana.com/docs/k6/latest/using-k6/scenarios/`
- `https://grafana.com/docs/k6/latest/using-k6/thresholds/`
- `https://grafana.com/docs/k6/latest/javascript-api/k6-metrics/`
- `https://grafana.com/docs/k6/latest/javascript-api/k6-secrets/`  (v1.4+ secrets management)
- `https://grafana.com/docs/k6/latest/javascript-api/k6-browser/`   (browser module getBy* locators)
- `https://grafana.com/docs/k6/latest/set-up/upgrade-to-k6-v2/`    (v2.0.0 migration guide)
- `https://grafana.com/docs/k6/latest/using-k6-browser/`           (browser module overview; Web Vitals)
- `https://grafana.com/docs/k6/latest/testing-guides/`             (test type hub: smoke/load/stress/soak/spike/breakpoint)
- `https://grafana.com/docs/k6/latest/using-k6/protocols/grpc/`    (gRPC unary + streaming + reflection)
- `https://grafana.com/docs/k6/latest/results-output/`             (summary, real-time, JSON/InfluxDB/cloud)
- `https://grafana.com/docs/k6/latest/using-k6/modules/`           (module types, Webpack bundling, TS native support)
- `https://grafana.com/docs/k6/latest/using-k6/protocols/http-2/`  (HTTP/2 automatic upgrade, r.proto check, multiplexing, GOAWAY)
<!-- See also: qa-perf/references/k6-patterns.md — verified against k6 v1.7.1; v2.0.0 final (2026-05-11) fully documented including: externally-controlled executor removed, CLI commands removed, browser_web_vital_fid → browser_web_vital_inp, options.ext.loadimpact → options.cloud, --no-summary → --summary-mode=disabled, --summary-mode=legacy removed, HTTP API server disabled by default (use --address/K6_ADDRESS), cloud secrets auto-injected in --local-execution (opt-out: --no-cloud-secrets), k6 cloud project list command added; HTTP/2 section added; Streams API (k6/experimental/streams) section added; 47 community gotchas including gotchas 34 (bidi stream.end() in finally), 35 (BrowserContext not shareable across VUs), 36 (browser Locator auto-retries in v2.0 — flaky selectors now silent), 37 (http.get() extra-arg warning in v2.0), 38 (coordinated omission — closed-model executors hide latency degradation), 39 (--stack mandatory in ALL k6 cloud v2.0 commands), 40 (--upload-only removed → k6 cloud upload), 41 (WebSocket binaryType defaults to blob — must set arraybuffer for binary frames), 42 (K6_WEB_DASHBOARD CI hang when port not disabled), 43 (require() removed in v1.4), 44 (Chromium process orphan leak), 45 (--vus ignored with scenarios), 46 (StatsD special-char tag drop), 47 (WS bufferedAmount TypedArray bug); new patterns (iteration 28): locator.filter()/all()/nth()/first()/last(), page.waitForRequest(), page.waitForEvent(), page.on('requestfailed'/'requestfinished'), frameLocator(), page.goBack()/goForward(), locator.evaluate()/evaluateHandle(), locator.pressSequentially(), k6 deps CLI command, --new-machine-readable-summary flag, page.unroute()/unrouteAll(), mcp-k6 AI integration (Playwright→k6 conversion), OpenTelemetry stable graduation + OTEL rate metric format change, PBKDF2 WebCrypto key derivation; 7910+ lines -->

**Detox (JS only):**
- `https://wix.github.io/Detox/docs/guide/design-principles`
- `https://wix.github.io/Detox/docs/api/matchers`
- `https://wix.github.io/Detox/docs/api/expect`
- `https://wix.github.io/Detox/docs/guide/test-flakiness`
- `https://wix.github.io/Detox/docs/api/device`
- `https://wix.github.io/Detox/docs/config/overview`
- `https://wix.github.io/Detox/docs/introduction/typescript`
- `https://wix.github.io/Detox/docs/api/webviews`    (by.web() matchers, web element APIs)

**See also:** `qa-mobile/references/detox-patterns.md` (JavaScript/TypeScript) — includes patterns for: matcher priority, auto-sync, waitFor, beforeEach reset, CI animation disable, artifact collection, advanced gestures (adjustSliderToPosition, longPressAndDrag, tapAtPoint, multiTap, pinch), accessibility testing (toHaveLabel, toHaveToggleValue), TypeScript setup, captureViewHierarchy for debugging, `--debug-synchronization` CLI flag, `--reuse` flag (local only), testRunner.retries vs jest retryTimes, dark mode testing (device.setAppearance), Handoff/Spotlight (device.sendUserActivity), feature-flag variant testing, Bridgeless Mode (RN 0.74+), multi-app install/uninstall, iOS PickerView (`scrollPickerViewToRowIndex`), `jestExpect` alias to avoid Jest/Detox expect collision, `element.scroll()` with `startPositionX`/`startPositionY`, MSW for React Native network mocking (JS-layer alternative to local mock server), complete Android GitHub Actions CI workflow (`ubuntu-22.04` + `reactivecircus/android-emulator-runner`), `device.getPlatform()` iOS-only API guard helper, native log inspection via `record-logs all`, Expo SDK 52 setup (`@expo/metro-config` format + `jsEngine: hermes` default), `testRunner.jest.bail` for fail-fast CI pipelines, `device.setLocation()` iOS 17+ `'always'` permission requirement, `by.text()` with `getAttributes()`+regex for dynamic text assertions, `device.clearUserNotifications()` for notification isolation, `launchApp({ userDefaults })` for fast iOS NSUserDefaults injection (iOS-only), `device.installApp()` post-install permission-grant pattern for multi-app tests, WebView testing with `by.web()` matchers (by.web.id/className/cssSelector/xpath/label/href, web element interactions including getText/getInnerHTML/scrollToView/runScript), visual regression testing (device.takeScreenshot + pixelmatch baseline comparison), JUnit XML CI reporting (`jest-junit` with shard-specific output filenames), `device.resetContentAndSettings()` deep simulator factory reset vs `delete: true`, per-configuration network synchronization control, React Native 0.78+ Strict Mode double-render flakiness on Debug builds, `by.system()` full dialog workflow (permissions/alerts/action sheets + locale-aware label map), `device.openURL()` deep link warm-start and cold-start patterns, parallel worker configuration (GitHub Actions matrix sharding + JEST_WORKER_ID isolation), `by.traits()` iOS accessibility traits testing (button/selected/notEnabled/adjustable + full trait table), `element.getAttributes()` extended inspection (frame/value/enabled/focused/hasKeyboardFocus), `device.shake()` iOS Simulator shake gesture with Android fallback pattern, 56 [community] gotchas including whileElement scroll overshoot, notification lifecycle states, missing `-c` configuration flag, `adjustSliderToPosition` Android silent no-op, duplicate testID on wrapper+inner component, Detox 20 `withTimeout` default changed to 6000 ms (Gotcha 33), app lifecycle testing with `sendToBackground`/`bringToForeground` (Gotcha 34), `tapBackspace()` for secure password fields (Gotcha 35), `--forceExit` for CI job hang prevention (Gotcha 24), iPadOS multi-window UIScene ambiguity (Gotcha 22), Android Linux CI `-gpu swiftshader_indirect` mandatory flag (Gotcha 36), RN 0.76+ New Architecture Fabric `by.type()` name changes (Gotcha 37), Android emulator `localhost` vs `10.0.2.2`/`reversePorts` network routing (Gotcha 38), RN 0.77+ `unstable_transformProfile` Hermes bytecode crash (Gotcha 39), `waitFor` condition chaining silently replaces rather than combines (Gotcha 40), Android 14 (API 34) permission dialog label changes breaking `by.system()` (Gotcha 41), `device.installApp()` does not grant permissions for secondary app (Gotcha 42), missing Hermes source maps causing unreadable CI crash reports (Gotcha 43), `by.web()` IPC latency vs native sync (Gotcha 44), visual diff false positives from dynamic content (Gotcha 45), jest-junit path collision in sharded CI (Gotcha 46), Android 15 predictive back gesture breaking back-navigation assertions (Gotcha 47), Hermes debugger port conflict on parallel CI jobs (Gotcha 48), WebView URL not yet updated when Detox selector fires (Gotcha 49), RN 0.78+ strictMode double-render timing issues (Gotcha 50), `by.system()` label locale mismatch (Gotcha 51), deep link cold-start race condition (Gotcha 52), parallel workers sharing global launchArgs via shared file paths (Gotcha 53), `getAttributes().value` returns string not boolean for Switch (Gotcha 54), `getAttributes()` returns null for off-screen elements (Gotcha 55), `device.shake()` no-op on physical devices (Gotcha 56), iOS 18 "Precise Location" prompt blocks `by.system()` selectors (Gotcha 57), `device.setStatusBar()` state bleed across tests without `afterAll` reset (Gotcha 58), `element.longPress(0)` behaves as `tap()` on Android — minimum 800 ms (Gotcha 59), Expo SDK 53 `expo-modules-core` v2 requires Detox 20.9+ (Gotcha 60), `--loglevel verbose` CI log overflow — use `--loglevel warn` + `--record-logs failing` (Gotcha 61), `waitFor.whileElement.scroll('up')` skips Android SectionList sticky headers (Gotcha 62), `device.setOrientation()` no-op on Android Emulator API 34+ without `-gpu swiftshader_indirect` (Gotcha 63); also covers `element.swipe()` `startNormalizedX`/`startNormalizedY` precision swipe control (Pattern 47) and test tiering with `--testNamePattern` `[smoke]`/`[regression]` describe-prefix CI tier strategy (Pattern 48).

**Appium / WebDriverIO — URL set depends on TARGET_LANG:**

| Language | Client docs |
|----------|-------------|
| TypeScript / JavaScript | `https://webdriver.io/docs/bestpractices/`, `https://webdriver.io/docs/pageobjects/`, `https://webdriver.io/docs/selectors/`, `https://appium.io/docs/en/2.0/guides/` |
| Java | `https://appium.io/docs/en/2.0/guides/` + `https://github.com/appium/java-client` README |
| Python | `https://appium.io/docs/en/2.0/guides/` + `https://github.com/appium/python-client` README |
| C# | `https://appium.io/docs/en/2.0/guides/` + `https://github.com/appium/dotnet-client` README |
| Ruby | `https://appium.io/docs/en/2.0/guides/` + `https://github.com/appium/ruby_lib` README |

**See also:** `qa-mobile/references/appium-wdio-patterns.md` (TypeScript) — 215+ sections, 315+ [community] gotchas including: W3C Actions API replacing touchAction, WDIO v9 BiDi (Shadow DOM auto-pierce, fake timers), browser.mock() CDP limitations on cloud providers, mobile:pressButton complete iOS reference (home/lock/siri/volume), Android AVD CI launch with -no-snapshot, parallel port management (wdaLocalPort iOS/systemPort Android), appium:newCommandTimeout session keepalive, TypeScript 'using' keyword for resource management, app version fixture management (installApp/removeApp/queryAppState), appium:webviewConnectRetries + ensureWebviewsHavePages, cookie injection for WebView auth state, element.getProperty() vs getAttribute() for live React DOM, file upload via pushFile+DataTransfer, TypeScript capability interface extension via declaration merging, @wdio/shared-store-service device pool pattern, WDIO specs/exclude/suite selective CI execution, browser.emulate() (clock/geolocation/device/colorScheme/userAgent/onLine BiDi), WDIO v9 migration breaking changes (getElement()/toHaveText(stringContaining)/isDisplayed({withinViewport})/Node20), trackSelectorPerformance beta selector profiler, scrollIntoView() native mobile v9 options (maxScrolls/platform defaults), Allure v3 ALLURE_TESTPLAN_PATH test plan filtering + historyId fix (v9.27.1), @wdio/appium-service appiumArgs CI best practices with Appium readiness healthcheck, getContexts() returnDetailedContexts typed interfaces (iOS+Android URL/title/bundleId), switchContext() regex/URL/title matching, tap() auto-scroll with maxScrolls/direction, longPress() with x/y offset, pinch()/zoom() with scale/duration, relaunchActiveApp() soft reset, touchId() with faceId type + withBiometricAuth pattern, gsmCall()/sendSms()/gsmSignal()/gsmVoice() Android Emulator telephony, clipboard testing (getClipboard base64/setClipboard), lock()/unlock() with iOS seconds parameter, getPerformanceData()/getPerformanceDataTypes() CPU/memory monitoring, powerAC()/powerCapacity() battery simulation, fingerPrint() Android biometric, openNotifications() notification shade, getSystemBars() immersive mode layout, network state toggles (toggleAirplaneMode/toggleData/toggleWiFi/toggleLocationServices), getDisplayDensity() DPI-bucket helper, getStrings() i18n/l10n validation, background() app backgrounding, getCurrentActivity()/getCurrentPackage() Android activity verification, @wdio/mcp Model Context Protocol server for AI-assisted mobile testing (Feb 2026), soft assertions (expect.soft()/SoftAssertionService/getSoftFailures), longPressKeyCode() Android long-press key events, toggleNetworkSpeed() Android emulator network presets, Appium 3 + WDIO v9.27 migration (driver matrix/Node 20/API 26 minimum), multiRemoteBrowser multi-device mobile testing (chat/push-notification patterns), pre-built WDA (appium:usePreinstalledWDA + download-wda CLI/CI cache), WDIO v9.23-v9.27 highlights (--exclude-suite/dynamic onPrepare specs/no-floating-promise ESLint rule), browser.throttleCPU() WebView CPU throttling, browser.setViewport() mobile viewport emulation with devicePixelRatio, Appium 3 protocol command rename table (37 commands appium-prefixed + WDIO wrapper strategy), screen recording API (startRecordingScreen/stopRecordingScreen iOS+Android with beforeEach/afterEach pattern), browser.on() event monitoring (request.start/end/retry/performance + bidiCommand/bidiResult), browser.addInitScript() emit() BiDi pattern for DOM mutation and JS error capture, TypeScript 7 erasableSyntaxOnly enum→const migration guide, disableElementImplicitWait v9.27.1 fix, defineConfig() typed config helper (v9.12), browser.deepLink() / browser.restartApp() native first-class commands (v9.10), maskingPatterns sensitive data masking (v9.15), @wdio/xvfb Linux CI virtual display (v9.19), npx wdio inspector CLI Appium Inspector launch (v9.22), browser.url() enhanced options (headers/auth/onBeforeLoad), native DOM snapshot testing (toMatchSnapshot/toMatchInlineSnapshot WDIO v9), isDisplayed() CSS visibility flags (contentVisibilityAuto/opacityProperty/visibilityProperty v9.18.4), WebDriver BiDi low-level network commands (networkAddIntercept/networkContinueRequest/networkProvideResponse/networkSetCacheBehavior v9.27.1), and create-wdio interactive scaffolding wizard (v9.17).

**Cypress (JS/TS only):**
- `https://docs.cypress.io/guides/core-concepts/introduction-to-cypress`
- `https://docs.cypress.io/guides/references/best-practices`
- `https://docs.cypress.io/api/commands/session`
- `https://docs.cypress.io/api/commands/intercept`
- `https://docs.cypress.io/api/commands/selectfile`
- `https://docs.cypress.io/api/commands/press`                  (cy.press() — Cy 14.3+, native keyboard events, Tab-order)
- `https://docs.cypress.io/api/commands/env`                    (cy.env() — Cy 15.10+, async secure env var access)
- `https://docs.cypress.io/guides/end-to-end-testing/testing-strategies`
- `https://docs.cypress.io/guides/component-testing/overview`
- `https://docs.cypress.io/guides/cloud/introduction`   (Smart Orchestration, parallel CI, MCP integration)
- `https://docs.cypress.io/app/references/migration-guide`      (Cy 14 → 15 breaking changes: exitCode, Vite ESM, Firefox BiDi)
- `https://docs.cypress.io/app/continuous-integration/github-actions`  (matrix parallelization, Cypress Cloud; updated Apr 2026)
- `https://docs.cypress.io/api/commands/prompt`                  (cy.prompt() — Cy 15.13+ beta, AI natural language → Cypress commands)
- `https://docs.cypress.io/api/cypress-api/stop`                 (Cypress.stop() — Cy 14.2+, halt remaining tests on failure)
- `https://docs.cypress.io/app/references/module-api`            (Module API posixExitCodes + expose options — Cy 15.10+)

**See also:** `qa-web/references/cypress-patterns.md` (TypeScript/JavaScript) — 121+ patterns including Shadow DOM, GraphQL intercept, CDP throttling, cy.all(), WebKit testing, Smart Orchestration, Cypress Cloud MCP integration, cy.press() Tab-order tests, cy.env() async secure vars (multi-key single-call + log:false), Cypress.expose() public config, Cypress 15 breaking changes (exitCode/Vite ESM/Firefox CDP/Node.js 22), Angular 21 zoneless CT, cy.readFile() query promotion, TypeScript 6 + Vite 8 setup, Svelte 5 CT (runes/callback props), React 19 CT, GitHub Actions v7 + Node.js 24 CI patterns, cy.prompt() AI test authoring (Cy 15.13+, BDD Gherkin + placeholder loop caching), Cypress.stop() fail-fast (Cy 14.2+), --posix-exit-codes/--pass-with-no-tests CLI flags (Cy 15.4/15.11), experimentalFastVisibility (Cy 15.8), Firefox WebDriver BiDi CDP guard pattern (Cy 14.1+), justInTimeCompile webpack CT default, experimentalRunAllSpecs for component testing (Cy 15.9+), React SSR hydration bootstrap script (data-cy-bootstrap, Cy 15.11+), Cypress.ElementSelector.defaults() selectorPriority config (Cy 15+), defaultBrowser config for local DX (Cy 13.16+), Cypress Module API expose + posixExitCodes orchestration (Cy 15.10+), cy.intercept() middleware routing global header injection (pattern 118), cy.press() focus trap + ARIA keyboard testing (pattern 119), Cypress Cloud UI Coverage AI-generated test suggestions (pattern 120), cy.session() parallel CI cache scope + multi-machine isolation (pattern 121), and 105+ [community] gotchas (including .invoke() throws on Promise in Cy 15, cy.wait([]) routeId crash 15.14.2, Chrome 137 --load-extension removal, transitive CVE monitoring, cy.prompt() rate-limit exhaustion in parallel CI, experimentalStudio flag removal in Cy 15.4, injectDocumentDomain removal in Cy 15, cy.intercept() delay >= 2^31 validation, <base target> iframe navigation break, cypress open memory leak, allowCypressEnv:false third-party plugin pitfall, cy.url()/cy.location() automation-client cross-origin change, cy.fixture() cache stale-data after writeFile, cy.wrap() circular reference freeze, synchronous XHR route handler deadlock, cacheAcrossSpecs false-sharing across CI machines, cy.intercept() resourceType deprecated in Cy 14, cy.session() validate() fires before setup on first warmup, UI Coverage test gen rate limit on large suites, cy.press() F-key browser shortcut interception)

**Selenium — language-independent docs (fetch for all `TARGET_LANG`):**
- `https://www.selenium.dev/documentation/webdriver/`
- `https://www.selenium.dev/documentation/test_practices/`
- `https://www.selenium.dev/documentation/webdriver/waits/`
- `https://www.selenium.dev/documentation/webdriver/elements/finders/`

**Selenium — language-specific additional sources:**

| Language | Additional source |
|----------|-------------------|
| Java | `https://github.com/SeleniumHQ/seleniumhq.github.io/tree/trunk/examples/java` |
| Python | `https://selenium-python.readthedocs.io/` |
| Ruby | `https://github.com/SeleniumHQ/selenium/tree/trunk/rb` |
| TypeScript / JavaScript / C# | *(selenium.dev docs are sufficient)* |

**See also:** `qa-web/references/selenium-patterns.md` (TypeScript) — see reference files table above.

**JMeter:**
- `https://jmeter.apache.org/usermanual/get-started.html`
- `https://jmeter.apache.org/usermanual/test_plan.html`
- `https://jmeter.apache.org/usermanual/best-practices.html`
- `https://jmeter.apache.org/usermanual/generating-dashboard.html`
- `https://jmeter.apache.org/usermanual/remote-test.html`

**Locust (Python only):**
- `https://docs.locust.io/en/stable/writing-a-locustfile.html`
- `https://docs.locust.io/en/stable/running-distributed.html`
- `https://docs.locust.io/en/stable/configuration.html`
- `https://docs.locust.io/en/stable/api.html`

**Maestro (YAML only):**
- `https://maestro.mobile.dev/getting-started/installing-maestro`
- `https://maestro.mobile.dev/api-reference/commands`
- `https://maestro.mobile.dev/getting-started/writing-your-first-flow`
- `https://maestro.mobile.dev/platform-support/ci-integration`
- `https://maestro.mobile.dev/advanced/nested-flows`

If WebFetch is blocked, use the `_fetch_text` bash helper defined above.
If both WebFetch and Bash fetch fail, synthesize from training knowledge and note the source.

---

## Phase 1b — Community & real-world sources

Run **in parallel with Phase 1a**. Prompt for community fetches:
> "Extract: (1) patterns used in production that differ from the official recommendation,
> (2) common gotchas and failure modes with root-cause explanations, (3) CI/CD quirks,
> (4) warnings about official patterns that don't scale."

**Playwright — community:**
- `https://github.com/mxschmitt/awesome-playwright`
- `https://github.com/microsoft/playwright-examples`
- `https://github.com/checkly/playwright-examples`
- WebSearch: `playwright best practices production scale {TARGET_LANG} 2026`
- WebSearch: `playwright flaky tests root causes solutions`

**k6 — community:**
- `https://github.com/grafana/awesome-k6`
- `https://github.com/grafana/k6/tree/master/examples`
- WebSearch: `k6 load testing production tips CI 2026`

**Detox — community:**
- `https://github.com/wix/Detox/tree/master/examples`
- WebSearch: `detox CI flaky tests solutions react native 2026`

**Appium / WebDriverIO — community:**
- `https://github.com/webdriverio/awesome-webdriverio`
- `https://github.com/saikrishna321/awesome-appium`
- WebSearch: `appium webdriverio mobile testing best practices {TARGET_LANG} 2026`

**Cypress — community:**
- `https://github.com/cypress-io/awesome-cypress`
- `https://github.com/cypress-io/cypress-realworld-app` (reference implementation)
- WebSearch: `cypress best practices production scale 2026`
- WebSearch: `cypress flaky tests solutions CI 2026`

**Selenium — community:**
- `https://github.com/SeleniumHQ/selenium/tree/trunk/examples`
- WebSearch: `selenium webdriver best practices {TARGET_LANG} 2026`
- WebSearch: `selenium page object model production pitfalls 2026`

**JMeter — community:**
- `https://github.com/abstracta/jmeter-java-dsl`
- WebSearch: `jmeter load testing best practices CI 2026`
- WebSearch: `jmeter performance test gotchas production 2026`

**Locust — community:**
- `https://github.com/locustio/locust/tree/master/examples`
- WebSearch: `locust load testing production tips CI 2026`
- WebSearch: `locust python performance testing patterns 2026`

**Maestro — community:**
- `https://github.com/mobile-dev-inc/maestro/tree/main/examples`
- WebSearch: `maestro mobile testing best practices 2026`
- WebSearch: `maestro CI integration react native 2026`

**For all languages, also check** `lang-refine/references/<TARGET_LANG>-patterns.md` if it
exists — it provides language idioms that test code examples should follow. Available:
`typescript-patterns.md`, `javascript-patterns.md`, `java-patterns.md`, `python-patterns.md`,
`csharp-patterns.md`, `ruby-patterns.md`, `kotlin-patterns.md`.

---

## Phase 2 — Write initial draft

Synthesize official docs + community sources into the reference file. Write as
iteration 0 even if imperfect — the loop improves it.

**Target paths:**
| Tool | Reference file |
|------|---------------|
| Playwright | `qa-web/references/playwright-patterns-<lang>.md` (or `playwright-patterns.md` for TS) |
| Cypress | `qa-web/references/cypress-patterns.md` |
| Selenium | `qa-web/references/selenium-patterns-<lang>.md` (or `selenium-patterns.md` for TS) |
| k6 | `qa-perf/references/k6-patterns.md` |
| JMeter | `qa-perf/references/jmeter-patterns.md` |
| Locust | `qa-perf/references/locust-patterns.md` |
| NBomber | `qa-perf/references/nbomber-patterns.md` |
| Detox | `qa-mobile/references/detox-patterns.md` |
| Appium / WebDriverIO | `qa-mobile/references/appium-wdio-patterns-<lang>.md` (or base name for TS) |
| Maestro | `qa-mobile/references/maestro-patterns.md` |

The existing base-name files (e.g. `playwright-patterns.md`) are the TypeScript references.
For all other languages, append the language suffix (e.g. `-csharp`, `-java`, `-python`,
`-ruby`, `-javascript`) so guides coexist without overwriting each other.

**Document structure:**
```
# <Tool> Patterns & Best Practices (<TARGET_LANG>)
<!-- lang: <TARGET_LANG> | sources: [official | community | mixed] | iteration: N | score: X/100 | date: YYYY-MM-DD -->

## Core Principles
<3-5 foundational ideas — the "why" before the "how">

## Recommended Patterns

### <Pattern name>  [community] if from community
<One paragraph on why this matters>
<Code example in TARGET_LANG — 15-25 lines>

## Selector / Locator Strategy
<Ordered priority list — language-specific API names>

## Real-World Gotchas  [community]
<≥5 production pitfalls, each tagged [community] with WHY sentence>

## CI Considerations
<What changes in CI vs. local — environment-specific quirks>

## Key APIs
<Table: method (in TARGET_LANG) | purpose | when to use>
```

All code examples must use the actual API for `TARGET_LANG`. For Java Playwright:
`Page.locator()`, `assertThat(locator).isVisible()`. For Python: `page.locator()`,
`expect(locator).to_be_visible()`. For C#: `Page.Locator()`, `Expect(locator).ToBeVisibleAsync()`.
Never use TypeScript syntax in a Java example.

---

## Phase 3 — Score the draft

Score after every write:

1. **Pattern Coverage (0–25):** Checklist from Preamble, score = (covered/total) × 25.
2. **Code Quality (0–25):** Each example — correct `TARGET_LANG` syntax + imports,
   ≥5 lines, demonstrates the pattern. Deduct 3 per failing example.
3. **Depth (0–25):** CI notes, timeout/retry, auth/MFA, parallel execution, scaling
   advice. Each distinct topic = +5, max 25.
4. **Community Signal (0–25):** Named `[community]`-tagged gotchas with WHY.
   Score = min(count × 5, 25). Need ≥5 for full marks.

**Scoring honesty rule:** Re-read with fresh eyes. 60–75 after first draft is normal.
Before giving 25/25, quote a specific line as evidence.

---

## Phase 4 — Refinement loop

Repeat until: **score ≥ 80**, OR **iterations ≥ 3**, OR **delta < 5**.

### 4a. Save: `cp <file> <file>.prev`

### 4b. Identify lowest-scoring dimension. Pick targeted source:

| Gap | Best source |
|-----|-------------|
| Missing official pattern | Language-specific docs from Phase 1a |
| Thin code examples for TARGET_LANG | Official example repo for that tool+language |
| Missing CI quirk | WebSearch: `"<tool> CI <issue> <TARGET_LANG> 2026"` |
| Thin community signal | WebSearch: `"<tool> production gotchas <TARGET_LANG>"` |
| Language idiom mismatch | `lang-refine/references/<TARGET_LANG>-patterns.md` |

### 4c. Rewrite only weak sections (Edit tool).

### 4d. Re-score (Phase 3).

### 4e. Keep or revert:
```
if new_score > prev_score → rm .prev, log improvement
else → cp .prev back, rm .prev, log revert, break
```

Print iteration trace after loop exits.

---

## Phase 5 — Update SKILL.md.tmpl

Surgical edits only:
1. Add/update "See also" pointer to the reference file.
2. Fix deprecated API names for `TARGET_LANG` if found.
3. Add pattern callouts for newly documented patterns.

---

## Phase 6 — Final report

```
## qa-refine: <Tool> (<TARGET_LANG>)

Reference file:   <path>
Final score:      <N>/100  (Coverage: X | Code: X | Depth: X | Community: X)
Iterations run:   N
Language:         <TARGET_LANG>
Sources used:     official docs | community | lang-refine reference
Skill updated:    <SKILL.md.tmpl path or "none">

Iteration trace:
  Iter 0: <score> — initial draft
  Iter 1: <score> (+delta) — <what changed>

Top 3 findings (with source):
1. <finding> [official | community]
2. ...

Community signal highlights:
- <Most impactful gotcha>

Re-run: /qa-refine <tool> (in a project with pom.xml for Java, etc.)
```
