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

### Step 0 — Detect target language

Before fetching any docs, determine which language to use for code examples:

1. **Scan for project signals** (use Glob/Bash, read only, do not modify anything):
   - `pom.xml` or `build.gradle` → **Java**
   - `requirements.txt`, `pytest.ini`, `conftest.py`, `pyproject.toml` → **Python**
   - `*.csproj` or `*.sln` → **C#**
   - `Gemfile` or `*.gemspec` → **Ruby**
   - `package.json` with `typescript` or `ts-jest` dependency → **TypeScript**
   - `package.json` without TypeScript → **JavaScript**

2. If the user explicitly names a language ("in Java", "Python examples"), use that.

3. If no signals found and none named, ask: "Which language should test examples use?
   (TypeScript / JavaScript / Java / Python / C# / Ruby / other)"

4. **Exceptions** — these tools are single-language regardless of project signals:
   - k6: always **JavaScript**
   - Detox: always **JavaScript**
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
| Playwright | qa-web, qa-visual, qa-api | POM, fixture-based auth (storageState), locator rank, web-first assertions, API request context, network mocking, soft assertions, test sharding |
| Cypress | qa-web | cy.session() auth, cy.intercept() mocking, data-cy selectors, custom commands, cy.request() API testing, Component Testing, cy.fixture(), retry-ability |
| Selenium | qa-web | By.* selector hierarchy, Page Object Model (language-specific), explicit waits (WebDriverWait + ExpectedConditions), fluent waits, headless mode, screenshot on failure, Actions class |
| k6 | qa-perf | Test type taxonomy, scenarios/executors, thresholds + abortOnFail, check() patterns, setup/teardown auth, custom metrics, handleSummary |
| JMeter | qa-perf | Thread Group (ramp-up, loop count), HTTP Request Sampler, CSV Data Set Config, Response Assertion, Summary/Aggregate Report, JMeter properties for CI, Dashboard generation, distributed testing, non-GUI mode |
| Locust | qa-perf | HttpUser vs FastHttpUser, @task with weight, on_start/on_stop, wait_time strategies, headless run flags, events hook for custom metrics, CSV output, environment parametrization |
| Detox | qa-mobile | Matcher priority, auto-sync/disableSynchronization, waitFor idioms, beforeEach reset, CI animation disable, artifact collection |
| Appium / WebDriverIO | qa-mobile | Page Object pattern, accessibility-id selector, mobile gestures, parallel device execution, CI Appium server config |
| Maestro | qa-mobile | Flow YAML structure, appId, tapOn/inputText/assertVisible, runFlow (sub-flows), envFile for secrets, scroll/swipe, launchApp/stopApp, CI headless runner |

---

## Phase 1a — Official documentation

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

**Playwright — URL set depends on TARGET_LANG:**

| Language | Base URL prefix |
|----------|----------------|
| TypeScript / JavaScript | `https://playwright.dev/docs/` |
| Java | `https://playwright.dev/java/docs/` |
| Python | `https://playwright.dev/python/docs/` |
| C# | `https://playwright.dev/dotnet/docs/` |

Pages to fetch (append to base URL):
`best-practices`, `pom`, `locators`, `test-fixtures`, `test-assertions`, `api-testing`, `network`

**k6 (JS only):**
- `https://grafana.com/docs/k6/latest/using-k6/best-practices/`
- `https://grafana.com/docs/k6/latest/test-types/`
- `https://grafana.com/docs/k6/latest/using-k6/scenarios/`
- `https://grafana.com/docs/k6/latest/using-k6/thresholds/`
- `https://grafana.com/docs/k6/latest/javascript-api/k6-metrics/`

**Detox (JS only):**
- `https://wix.github.io/Detox/docs/guide/design-principles`
- `https://wix.github.io/Detox/docs/api/matchers`
- `https://wix.github.io/Detox/docs/guide/test-flakiness`
- `https://wix.github.io/Detox/docs/api/device`
- `https://wix.github.io/Detox/docs/config/overview`

**Appium / WebDriverIO — URL set depends on TARGET_LANG:**

| Language | Client docs |
|----------|-------------|
| TypeScript / JavaScript | `https://webdriver.io/docs/bestpractices/`, `https://webdriver.io/docs/pageobjects/`, `https://webdriver.io/docs/selectors/` |
| Java | `https://appium.io/docs/en/2.0/guides/` + `https://github.com/appium/java-client` README |
| Python | `https://appium.io/docs/en/2.0/guides/` + `https://github.com/appium/python-client` README |
| C# | `https://appium.io/docs/en/2.0/guides/` + `https://github.com/appium/dotnet-client` README |
| Ruby | `https://appium.io/docs/en/2.0/guides/` + `https://github.com/appium/ruby_lib` README |

**Cypress (JS/TS only):**
- `https://docs.cypress.io/guides/core-concepts/introduction-to-cypress`
- `https://docs.cypress.io/guides/references/best-practices`
- `https://docs.cypress.io/api/commands/session`
- `https://docs.cypress.io/api/commands/intercept`
- `https://docs.cypress.io/guides/end-to-end-testing/testing-strategies`
- `https://docs.cypress.io/guides/component-testing/overview`

**Selenium — URL set depends on TARGET_LANG:**

| Language | Docs |
|----------|------|
| TypeScript / JavaScript | `https://www.selenium.dev/documentation/webdriver/`, `https://www.selenium.dev/documentation/test_practices/` |
| Java | `https://www.selenium.dev/documentation/webdriver/`, `https://www.selenium.dev/documentation/test_practices/`, `https://github.com/SeleniumHQ/seleniumhq.github.io/tree/trunk/examples/java` |
| Python | `https://www.selenium.dev/documentation/webdriver/`, `https://selenium-python.readthedocs.io/` |
| C# | `https://www.selenium.dev/documentation/webdriver/`, `https://www.selenium.dev/documentation/test_practices/` |
| Ruby | `https://www.selenium.dev/documentation/webdriver/`, `https://github.com/SeleniumHQ/selenium/tree/trunk/rb` |

- `https://www.selenium.dev/documentation/webdriver/waits/` (all languages)
- `https://www.selenium.dev/documentation/webdriver/elements/finders/` (all languages)

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
- WebSearch: `playwright best practices production scale {TARGET_LANG} 2025`
- WebSearch: `playwright flaky tests root causes solutions`

**k6 — community:**
- `https://github.com/grafana/awesome-k6`
- `https://github.com/grafana/k6/tree/master/examples`
- WebSearch: `k6 load testing production tips CI 2025`

**Detox — community:**
- `https://github.com/wix/Detox/tree/master/examples`
- WebSearch: `detox CI flaky tests solutions react native 2025`

**Appium / WebDriverIO — community:**
- `https://github.com/webdriverio/awesome-webdriverio`
- `https://github.com/saikrishna321/awesome-appium`
- WebSearch: `appium webdriverio mobile testing best practices {TARGET_LANG} 2025`

**Cypress — community:**
- `https://github.com/cypress-io/awesome-cypress`
- `https://github.com/cypress-io/cypress-realworld-app` (reference implementation)
- WebSearch: `cypress best practices production scale 2025`
- WebSearch: `cypress flaky tests solutions CI 2025`

**Selenium — community:**
- `https://github.com/SeleniumHQ/selenium/tree/trunk/examples`
- WebSearch: `selenium webdriver best practices {TARGET_LANG} 2025`
- WebSearch: `selenium page object model production pitfalls 2025`

**JMeter — community:**
- `https://github.com/abstracta/jmeter-java-dsl`
- WebSearch: `jmeter load testing best practices CI 2025`
- WebSearch: `jmeter performance test gotchas production 2025`

**Locust — community:**
- `https://github.com/locustio/locust/tree/master/examples`
- WebSearch: `locust load testing production tips CI 2025`
- WebSearch: `locust python performance testing patterns 2025`

**Maestro — community:**
- `https://github.com/mobile-dev-inc/maestro/tree/main/examples`
- WebSearch: `maestro mobile testing best practices 2025`
- WebSearch: `maestro CI integration react native 2025`

**For non-JS/TS languages, also fetch the language-specific guide** from
`lang-refine/references/<TARGET_LANG>-patterns.md` if it exists — it provides
language idioms that test code examples should follow.

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
| Detox | `qa-mobile/references/detox-patterns.md` |
| Appium / WebDriverIO | `qa-mobile/references/appium-wdio-patterns-<lang>.md` (or base name for TS) |
| Maestro | `qa-mobile/references/maestro-patterns.md` |

For TypeScript/JavaScript (the default), use the existing base filename with no suffix.
For other languages, append `-java`, `-python`, `-csharp`, `-ruby` etc. so guides
coexist without overwriting each other.

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
| Missing CI quirk | WebSearch: `"<tool> CI <issue> <TARGET_LANG> 2025"` |
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
