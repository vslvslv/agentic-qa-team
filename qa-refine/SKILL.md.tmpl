---
name: qa-refine
version: 1.1.0.0
description: |
  Iteratively researches official documentation for QA tools used in this project
  (Playwright, k6, Detox, Appium, WebDriverIO), scores the result against a quality
  rubric, and keeps refining until the score plateaus or reaches 80/100. Each
  iteration: fetch targeted docs → rewrite weak sections → re-score → keep if better,
  revert if worse. Also makes surgical updates to the corresponding SKILL.md.tmpl.

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
Your job is not just to write a reference guide once — it is to iteratively improve it
until it scores ≥ 80/100 on the quality rubric below, then update the skill that uses it.

**Quality rubric (0–100, four dimensions of 25 each):**

| Dimension | 0 | 12 | 25 | What earns full marks |
|-----------|---|----|----|----------------------|
| Pattern Coverage | No patterns | Some | All major patterns for this tool | POM, fixture auth, locator hierarchy, test types, executor types, etc. — tool-specific checklist in Phase 3 |
| Code Quality | No examples | Generic snippets | Copy-paste-ready, idiomatic TS/JS | Correct APIs, real import paths, ≥ 3 runnable examples per tool |
| Depth | Surface only | Common cases | Edge cases + CI/flakiness | Covers CI quirks, retries, parallelism, timeout tuning |
| Anti-Pattern List | None | Vague warnings | Named mistakes + why | ≥ 5 concrete anti-patterns with one-sentence WHY each |

Target: **score ≥ 80** or **3 iterations** or **delta < 5 between iterations** → stop.

**Tool → skill mapping:**

| Tool | Skill dir(s) | Pattern checklist |
|------|-------------|-------------------|
| Playwright | qa-web, qa-visual, qa-api | POM, fixture-based auth, locator rank (getByRole→…→CSS), web-first assertions, API request context, network mocking, soft assertions |
| k6 | qa-perf | Test type taxonomy, scenarios/executors (ramping-vus, constant-arrival-rate), thresholds + abortOnFail, check() patterns, setup/teardown auth, custom metrics |
| Detox | qa-mobile | Matcher priority (by.id→by.label→by.text), synchronization/disableSynchronization, waitFor idioms, beforeEach reset strategy, CI animation disable, artifact collection |
| Appium/WebDriverIO | qa-mobile | Page Object pattern, accessibility-id selector, mobile gestures, driver.execute, CI Appium server config |

---

## Phase 1 — Initial research

Determine which tool to research from the user's message. If ambiguous, ask.

Fetch all pages for the target tool **in parallel**. Use this prompt for every WebFetch:
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
- `https://k6.io/docs/using-k6/best-practices/`
- `https://k6.io/docs/test-types/`
- `https://k6.io/docs/using-k6/scenarios/`
- `https://k6.io/docs/using-k6/thresholds/`
- `https://k6.io/docs/javascript-api/k6-metrics/`

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

If WebFetch is blocked by permissions, synthesize from training knowledge and note
`[source: training knowledge — re-run with WebFetch permissions for live docs]` at the
top of the reference file. Training knowledge is accurate for stable tool versions but
may miss features released in the last 6 months.

---

## Phase 2 — Write initial draft

Synthesize into a structured document at the target path. Write this now as iteration 0
even if it is imperfect — the loop will improve it.

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
<!-- source: [live docs | training knowledge] | iteration: N | score: X/100 | date: YYYY-MM-DD -->

## Core Principles
<3-5 ideas that underpin everything else — the "why" before the "how">

## Recommended Patterns

### <Pattern name>
<One paragraph on why this matters>
<Code example — 15-25 lines, TS for Playwright/WebDriverIO, JS for k6/Detox>

### <next pattern>
...

## Selector / Locator Strategy
<Ordered priority list with rationale for each rank>

## Anti-Patterns
<Named entries, one per bullet: what it is + one sentence WHY it's harmful>

## Key APIs
<Table: method | purpose | when to use>

## CI Considerations
<What changes in CI vs. local: timeouts, animations, parallelism, artifacts>
```

Keep examples focused and directly usable. A developer should be able to copy-paste
with minimal adaptation. Examples must use the tool's real API (no made-up method names).

---

## Phase 3 — Score the draft (the rubric loop)

**This is the core of the autoresearch loop. Run it after every write.**

Score the file you just wrote against the rubric:

1. **Pattern Coverage (0–25):** Open the tool's pattern checklist from the Preamble.
   Count how many are present in the guide. Score = (covered / total) × 25.
   List what is missing.

2. **Code Quality (0–25):** For each code example, check:
   - Uses real API methods (no invented names)?
   - Has correct imports?
   - Is it ≥ 5 lines and demonstrates the pattern (not just a one-liner)?
   - Is it TypeScript (Playwright/WebDriverIO) or JS (k6/Detox)?
   Deduct 3 points per failing example, floor 0.

3. **Depth (0–25):** Check for: CI-specific notes, timeout/retry guidance, animation
   handling, parallel execution notes, common gotchas. Each present = +5, max 25.

4. **Anti-Pattern List (0–25):** Count named anti-patterns with a WHY sentence.
   Score = min(count × 5, 25). Need ≥ 5 for full marks.

Compute total (0–100). Print the score breakdown and list the top gaps — these are the
inputs to the next iteration.

**Scoring honesty rule:** Re-read the file you just wrote before assigning marks. It is
common to write content that *looks* comprehensive at a glance but actually covers
only 2–3 examples where 5 are needed, or names anti-patterns without explaining WHY.
A score of 60–75 after the first draft is normal and expected. Do not inflate scores
to avoid another iteration — a genuine 65 that triggers iteration 2 produces a better
guide than an inflated 85 that exits early. If you find yourself giving 25/25 on a
dimension, quote a specific line from the file as evidence.

---

## Phase 4 — Refinement loop

Repeat until: **score ≥ 80**, OR **iterations ≥ 3**, OR **score delta < 5**.

At the start of each iteration:

### 4a. Save current version
```bash
cp <reference-file> <reference-file>.prev
```

### 4b. Identify the lowest-scoring dimension
Take the top 1-2 gaps from Phase 3. These are your search targets.

### 4c. Fetch targeted documentation
For the specific gaps (e.g., "CI animation handling", "custom metrics API", "fixture
patterns"), run targeted WebFetch or WebSearch calls. Example:
- Gap: "missing CI considerations for Detox" → fetch
  `https://wix.github.io/Detox/docs/introduction/getting-started` and search
  "Detox CI configuration best practices"
- Gap: "no custom metrics k6" → fetch
  `https://k6.io/docs/javascript-api/k6-metrics/`

If WebFetch is blocked, synthesize the gap from training knowledge and note it.

### 4d. Rewrite only the weak sections
Use the Edit tool to update the specific sections with low scores. Do not rewrite
sections that already scored well — you might degrade them.

### 4e. Re-score (run Phase 3 again)
Print the new score breakdown.

### 4f. Keep or revert
```
if new_score > prev_score:
    remove <reference-file>.prev   # keep improvement
    log "Iteration N: score improved X → Y (+delta)"
else:
    cp <reference-file>.prev <reference-file>  # revert
    remove <reference-file>.prev
    log "Iteration N: score did not improve (X → Y), reverted"
    break  # stop the loop — we've reached a local optimum
```

After the loop exits, print the full iteration trace:
```
Iteration 0: score 52/100  (Pattern Coverage: 15, Code Quality: 18, Depth: 10, Anti-patterns: 9)
Iteration 1: score 68/100  (+16) — added POM pattern, fixture examples, CI section
Iteration 2: score 79/100  (+11) — added 4 anti-patterns, improved k6 threshold examples
Stopped: delta < 5 / score ≥ 80 / iterations ≥ 3
Final score: 79/100
```

---

## Phase 5 — Update SKILL.md.tmpl

Read the target skill's `SKILL.md.tmpl`. Make **surgical edits only**:

1. **Add or update a "See also" pointer** near the first test-writing phase:
   ```
   > Reference: [<tool> patterns guide](<relative path>)
   ```
2. **Fix deprecated patterns** — e.g., `page.$()` → `page.locator()`, or `stages:` →
   `scenarios:` with executors.
3. **Add pattern callouts** for any major pattern the skill doesn't yet mention
   (POM, storageState auth, `abortOnFail` thresholds, etc.).

Do NOT rewrite phases wholesale. If a section already reflects current best practices,
leave it untouched. Print a one-paragraph summary of changes (or "No changes needed").

---

## Phase 6 — Final report

```
## qa-refine: <Tool>

Reference file:  <path>
Final score:     <N>/100  (Coverage: X | Code: X | Depth: X | Anti-patterns: X)
Iterations run:  N
Source:          [live docs | training knowledge | mixed]
Skill updated:   <SKILL.md.tmpl path or "none">

Iteration trace:
  Iter 0: <score> — initial draft
  Iter 1: <score> (+/-delta) — <what changed>
  ...

Top 3 findings:
1. <Most impactful pattern>
2. <Second finding>
3. <Third finding>

Gaps remaining (score < 80):
- <gap 1>
- <gap 2>
(or "None — guide meets quality threshold")

Re-run to refresh: /qa-refine <tool>
```
