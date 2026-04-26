---
name: qa-refine
version: 1.2.0.0
description: |
  Iteratively researches QA tools used in this project (Playwright, k6, Detox,
  Appium, WebDriverIO) across both official documentation AND community sources
  (awesome lists, example repos, engineering blogs, GitHub Discussions), scores
  the result against a quality rubric (0–100), and keeps refining until the score
  plateaus or reaches 80/100. Each iteration: fetch targeted sources → rewrite
  weak sections → re-score → keep if better, revert if worse. Also makes surgical
  updates to the corresponding SKILL.md.tmpl.

  Use this skill whenever the user asks to:
  - "research [tool] best practices / patterns / design"
  - "create a Page Object Model guide" or "set up POM for our tests"
  - "update qa-web / qa-perf / qa-mobile from the docs"
  - "improve our Playwright selectors / k6 scripts / Detox tests"
  - "refresh QA skills from official documentation"
  - "what are the latest best practices for Playwright / k6 / Detox / Appium?"
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
Your job is to synthesize knowledge from **official docs AND community sources**, then
iteratively improve the result until it scores ≥ 80/100 on the quality rubric below.

The official docs tell you how tools work. Community sources tell you what actually
breaks in production, what patterns survive team scale-up, and what the docs quietly
omit. Both layers are required for a genuinely useful reference guide.

**Quality rubric (0–100, four dimensions of 25 each):**

| Dimension | 0 | 12 | 25 | What earns full marks |
|-----------|---|----|----|----------------------|
| Pattern Coverage | No patterns | Some | All major patterns for this tool | POM, fixture auth, locator hierarchy, test types, executor types — see tool checklist below |
| Code Quality | No examples | Generic snippets | Copy-paste-ready, idiomatic TS/JS | Correct API names, real imports, ≥ 3 runnable examples ≥ 5 lines each |
| Depth | Surface only | Common cases | Edge cases + CI/flakiness + scale | CI quirks, retries, parallel execution, auth/MFA, scaling from small to large test suites |
| Community Signal | No community content | Some warnings | Named real-world gotchas + WHY | ≥ 5 concrete pitfalls sourced from community experience (blogs, issues, discussions) with one-sentence WHY each |

**Community Signal replaces Anti-Patterns** as the 4th dimension because community
sources are where real production pitfalls live — official docs rarely document failure modes.

Target: **score ≥ 80** or **3 iterations** or **delta < 5 between iterations** → stop.

**Tool → skill mapping:**

| Tool | Skill dir(s) | Pattern checklist |
|------|-------------|-------------------|
| Playwright | qa-web, qa-visual, qa-api | POM, fixture-based auth (storageState), locator rank (getByRole→getByLabel→getByPlaceholder→getByTestId→CSS), web-first assertions, API request context, network mocking, soft assertions, test sharding |
| k6 | qa-perf | Test type taxonomy, scenarios/executors (ramping-vus, constant-arrival-rate, ramping-arrival-rate), thresholds + abortOnFail, check() patterns, setup/teardown auth, custom metrics, handleSummary |
| Detox | qa-mobile | Matcher priority (by.id→by.label→by.text), auto-sync/disableSynchronization, waitFor idioms, beforeEach reset strategy, CI animation disable, artifact collection, device.launchApp config |
| Appium / WebDriverIO | qa-mobile | Page Object pattern, accessibility-id selector, mobile gestures, driver.execute, parallel device execution, CI Appium server config |

---

## Phase 1a — Official documentation

Determine which tool to research from the user's message. If ambiguous, ask.

Fetch all official pages **in parallel**. Prompt for every WebFetch:
> "Extract: (1) best practices as bullet points, (2) design patterns with TS/JS code
> examples, (3) recommended APIs with one-line descriptions, (4) anti-patterns and WHY
> they're harmful."

**Playwright:**
- `https://playwright.dev/docs/best-practices`
- `https://playwright.dev/docs/pom`
- `https://playwright.dev/docs/locators`
- `https://playwright.dev/docs/test-fixtures`
- `https://playwright.dev/docs/test-assertions`
- `https://playwright.dev/docs/api-testing`
- `https://playwright.dev/docs/network`

**k6:**
- `https://grafana.com/docs/k6/latest/using-k6/best-practices/`
- `https://grafana.com/docs/k6/latest/test-types/`
- `https://grafana.com/docs/k6/latest/using-k6/scenarios/`
- `https://grafana.com/docs/k6/latest/using-k6/thresholds/`
- `https://grafana.com/docs/k6/latest/javascript-api/k6-metrics/`

**Detox:**
- `https://wix.github.io/Detox/docs/guide/design-principles`
- `https://wix.github.io/Detox/docs/api/matchers`
- `https://wix.github.io/Detox/docs/guide/test-flakiness`
- `https://wix.github.io/Detox/docs/api/device`
- `https://wix.github.io/Detox/docs/config/overview`

**Appium / WebDriverIO:**
- `https://webdriver.io/docs/bestpractices/`
- `https://webdriver.io/docs/pageobjects/`
- `https://webdriver.io/docs/selectors/`
- `https://webdriver.io/docs/api/browser/`

If WebFetch is blocked, synthesize from training knowledge. Note the source in the
file header so users know when to re-run with live permissions.

---

## Phase 1b — Community & real-world sources

Run these **in parallel with Phase 1a** (or immediately after if parallelism is limited).
Use a different extraction prompt that targets what community sources uniquely provide:

> "Extract: (1) patterns that community members use in production that differ from the
> official recommendation, (2) common gotchas and failure modes with root-cause
> explanations, (3) CI/CD integration tips and environment-specific quirks, (4) any
> warnings about official patterns that don't scale or cause issues at production size."

**Playwright — community sources:**

Awesome list (curated ecosystem, CI integrations, tooling):
- `https://github.com/mxschmitt/awesome-playwright`

Official real-world examples (sanctioned patterns beyond the quickstart):
- `https://github.com/microsoft/playwright-examples`
- `https://github.com/checkly/playwright-examples`

Community knowledge (authentication flows, flakiness, scaling):
- WebSearch: `playwright best practices production scale 2025`
- WebSearch: `playwright flaky tests root causes solutions`
- WebFetch `https://playwrightsolutions.com/` with prompt: "List the top 10 most
  common real-world Playwright problems and their solutions."

**k6 — community sources:**

Awesome list (CI integrations, converters, extensions):
- `https://github.com/grafana/awesome-k6`

Official worked examples (gRPC, WebSocket, custom metrics — not in quickstart):
- `https://github.com/grafana/k6/tree/master/examples`

Community knowledge (CI pipelines, observability, common mistakes):
- WebSearch: `k6 load testing production tips 2025 CI pipeline`
- WebSearch: `k6 common mistakes thresholds scenarios`

**Detox — community sources:**

Official real-world examples (iOS/Android native, plugin architecture):
- `https://github.com/wix/Detox/tree/master/examples`

Community pain points (search GitHub Discussions for top recurring issues):
- WebSearch: `detox CI flaky tests solutions react native 2025`
- WebSearch: `detox beforeEach reset strategy best practices`

**Appium / WebDriverIO — community sources:**

Awesome lists (client libraries, device farms, parallel execution):
- `https://github.com/webdriverio/awesome-webdriverio`
- `https://github.com/saikrishna321/awesome-appium`

Community knowledge (mobile-specific quirks, CI device farms):
- WebSearch: `webdriverio appium mobile testing best practices 2025`
- WebSearch: `appium selector strategies accessibility id 2025`

---

## Phase 2 — Write initial draft

Synthesize official docs (Phase 1a) and community sources (Phase 1b) into one
document at the target path. Where a finding comes from community sources rather than
the official docs, mark it with `[community]`. Official-only patterns get no tag.
This makes provenance visible and helps readers know which patterns are doc-blessed
vs. battle-tested in the field.

**Target paths:**

| Tool | Reference file |
|------|---------------|
| Playwright | `qa-web/references/playwright-patterns.md` |
| k6 | `qa-perf/references/k6-patterns.md` |
| Detox | `qa-mobile/references/detox-patterns.md` |
| Appium / WebDriverIO | `qa-mobile/references/appium-wdio-patterns.md` |

**Document structure:**
```
# <Tool> Patterns & Best Practices
<!-- sources: [official docs | community | mixed] | iteration: N | score: X/100 | date: YYYY-MM-DD -->

## Core Principles
<3-5 foundational ideas — the "why" before the "how">

## Recommended Patterns

### <Pattern name>  [community] if sourced from community
<One paragraph on why this matters>
<Code example — 15-25 lines, TS for Playwright/WebDriverIO, JS for k6/Detox>

### <next pattern>
...

## Selector / Locator Strategy
<Ordered priority list with rationale for each rank>

## Real-World Gotchas  [community]
<Pitfalls discovered through production usage, NOT in official docs.
 Each entry: what it is + WHY it causes problems + how to fix it.
 This section directly addresses the Community Signal rubric dimension.>

## CI Considerations
<What changes in CI vs. local: timeouts, animations, parallelism, artifacts.
 Mix official guidance and community-discovered environment quirks.>

## Key APIs
<Table: method | purpose | when to use>
```

Keep examples focused and copy-paste ready. No invented API names. TS for
Playwright/WebDriverIO, JS for k6/Detox.

---

## Phase 3 — Score the draft

**Run this after every write. This is the core autoresearch evaluation step.**

Score the file against the rubric:

1. **Pattern Coverage (0–25):** Check the tool's pattern checklist from the Preamble.
   Score = (covered patterns / total patterns) × 25. List what is missing.

2. **Code Quality (0–25):** For each code example check: real API methods, correct
   imports, ≥ 5 lines, correct language (TS or JS). Deduct 3 per failing example.

3. **Depth (0–25):** Check for: CI-specific notes, timeout/retry guidance, animation
   handling, parallel execution, auth/MFA edge cases, scaling advice (what breaks when
   going from 20 to 200 tests). Each distinct topic present = +5, max 25.

4. **Community Signal (0–25):** Count named real-world pitfalls that come from
   community sources (not just official anti-patterns). Each needs a `[community]` tag
   and a WHY sentence. Score = min(count × 5, 25). Need ≥ 5 for full marks.

Compute total. Print score breakdown and list the **top gaps** as inputs to the loop.

**Scoring honesty rule:** Re-read the file with fresh eyes before scoring. A score of
60–75 after the first draft is normal. Do not inflate to avoid another iteration —
a genuine 65 that triggers iteration 2 produces a better guide than an inflated 85
that exits early. Before giving 25/25 on any dimension, quote a specific line as
evidence that the criterion is met.

---

## Phase 4 — Refinement loop

Repeat until: **score ≥ 80**, OR **iterations ≥ 3**, OR **score delta < 5**.

### 4a. Save current version
```bash
cp <reference-file> <reference-file>.prev
```

### 4b. Identify lowest-scoring dimension
Top 1–2 gaps from Phase 3 become your search targets.

### 4c. Fetch targeted sources for the gap
Choose source type based on what the gap needs:

| Gap type | Best source |
|----------|-------------|
| Missing official pattern | Official docs URL from Phase 1a |
| Missing CI/environment quirk | WebSearch: `"<tool> CI <specific issue> 2025"` |
| Thin community signal | WebSearch: `"<tool> production gotchas <issue>"` or tool's GitHub Discussions |
| Weak code example | Official example repo (k6/examples, Detox/examples, playwright-examples) |
| Missing ecosystem tooling | Awesome list (mxschmitt/awesome-playwright, grafana/awesome-k6, etc.) |

Always prefer fetching a specific targeted URL over a broad search — precision beats
volume. Keep fetches focused on the gap, not the whole topic.

### 4d. Rewrite only the weak sections
Use Edit to update low-scoring sections. Leave sections that scored well — touching
them risks regression.

### 4e. Re-score (Phase 3 again)
Print new breakdown.

### 4f. Keep or revert
```
if new_score > prev_score:
    rm <reference-file>.prev        # keep — improvement confirmed
    log "Iteration N: score X → Y (+delta) — <what changed>"
else:
    cp <reference-file>.prev <reference-file>  # revert — no improvement
    rm <reference-file>.prev
    log "Iteration N: score did not improve (X → Y), reverted"
    break                           # local optimum reached, stop
```

Print iteration trace after loop exits:
```
Iteration 0: 55/100  (Coverage 18 | Code 15 | Depth 12 | Community 10)
Iteration 1: 71/100  (+16) — added auth/MFA section, 3 community gotchas [community]
Iteration 2: 82/100  (+11) — added CI sharding, k6 exit-code 99 tip [community]
Stopped: score ≥ 80
Final score: 82/100
```

---

## Phase 5 — Update SKILL.md.tmpl

Read the target skill's `SKILL.md.tmpl`. Make **surgical edits only**:

1. Add/update a "See also" pointer near the first test-writing phase:
   ```
   > Reference: [<tool> patterns guide](<relative path>)
   ```
2. Fix deprecated patterns (e.g., `page.$()`, top-level `stages:` in k6).
3. Add callouts for any major pattern the skill doesn't mention yet.

Do NOT rewrite phases wholesale. Print a one-paragraph summary of changes.

---

## Phase 6 — Final report

```
## qa-refine: <Tool>

Reference file:   <path>
Final score:      <N>/100  (Coverage: X | Code: X | Depth: X | Community: X)
Iterations run:   N
Sources used:     official docs | community blogs | awesome lists | example repos | GitHub Discussions
Skill updated:    <SKILL.md.tmpl path or "none">

Iteration trace:
  Iter 0: <score> — initial draft
  Iter 1: <score> (+/-delta) — <what changed, which source type filled the gap>
  ...

Top 3 findings (with source):
1. <Pattern/finding> [official | community]
2. <Pattern/finding> [official | community]
3. <Pattern/finding> [official | community]

Community signal highlights:
- <Most impactful real-world gotcha found in community sources>
- <Second>

Gaps remaining (if score < 80):
- <gap> — suggested source to close it

Re-run to refresh: /qa-refine <tool>
```
