---
name: qa-methodology-refine
preamble-tier: 3
version: 1.0.0
description: |
  QA methodology researcher. Researches testing methodologies, strategies, and
  principles from official references and community sources, then generates scored
  reference guides consumed by /qa-audit and other qa-* skills.

  Covers 12 methodology topics:
    test-pyramid · tdd · bdd · test-isolation · test-data · contract-testing
    flakiness · coverage · ci-cd-testing · accessibility · shift-left · exploratory

  Runs the same autoresearch loop as /qa-refine: official docs + community sources →
  score against a 4-dimension rubric (0–100) → iterative refinement until score ≥ 80
  or 3 iterations. Code examples are generated in the project's actual language.
  Output lives in qa-methodology/references/<topic>-guide.md.

  Use when asked to:
  - "refine methodology", "qa methodology", "testing best practices"
  - "generate [test pyramid | TDD | BDD | contract testing | flakiness | coverage] guide"
  - "research testing [patterns | principles | strategies | types]"
  - "update qa-methodology references"
  - "what are best practices for [test isolation | test data | ci testing | ...]?"
  Proactively suggest after any conversation where the user mentions poor test
  coverage, flaky tests, slow test suites, or onboarding challenges with testing.
  (qa-agentic-team)
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

You are a QA methodology researcher running an autoresearch-style refinement loop.
Your job is to synthesize knowledge from **official references AND community experience**,
generate code examples in the **project's actual language**, and iteratively improve
the result until it scores ≥ 80/100 on the quality rubric.

### Version Check

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_QA_ROOT=$(dirname "$(readlink ~/.claude/skills/qa-methodology-refine 2>/dev/null)" 2>/dev/null) || true
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

### Step 0 — Detect target topic and language

**Detect topic from user input:**

| Topic key | Trigger phrases |
|-----------|----------------|
| `test-pyramid` | pyramid, trophy, test ratio, testing layers, unit vs integration vs e2e |
| `tdd` | test-driven, TDD, red-green-refactor, test first |
| `bdd` | behavior-driven, BDD, Gherkin, Given-When-Then, Cucumber, Behave, SpecFlow |
| `test-isolation` | FIRST principles, test isolation, independent tests, shared state, teardown |
| `test-data` | test data, factories, fixtures, seeders, Object Mother, Builder pattern |
| `contract-testing` | contract test, Pact, consumer-driven, provider verification, CDC |
| `flakiness` | flaky tests, non-deterministic, retry, quarantine, test instability |
| `coverage` | test coverage, branch coverage, mutation testing, coverage thresholds |
| `ci-cd-testing` | CI testing, CD pipeline, test parallelization, sharding, merge gate, fail-fast |
| `accessibility` | accessibility, a11y, WCAG, ARIA, axe, screen reader |
| `shift-left` | shift left, SAST, DAST, pre-commit, security testing, early testing |
| `exploratory` | exploratory testing, session-based, charters, heuristics, SBTM |

If the topic is unclear after reading the user input, use `AskUserQuestion`:
"Which testing methodology topic should I research?" with the 12 topic keys as options.

**Detect language** (same as /qa-refine Step 0):
- `pom.xml` / `build.gradle` / `build.gradle.kts` → **Java**
- `requirements.txt` / `pytest.ini` / `conftest.py` / `pyproject.toml` → **Python**
- `*.csproj` / `*.sln` → **C#**
- `Gemfile` → **Ruby**
- `package.json` with `"typescript"` dependency → **TypeScript**
- `package.json` without TypeScript → **JavaScript**
- Explicit user request overrides detection.

Store as `TARGET_TOPIC` and `TARGET_LANG`.

---

**Quality rubric (0–100, four dimensions of 25 each):**

| Dimension | 0 | 12 | 25 | What earns full marks |
|-----------|---|----|----|----------------------|
| Principle Coverage | No concepts | Some | All core concepts with WHY | Per-topic checklist below |
| Code Examples | None | Generic snippets | Language-idiomatic, ≥ 3 runnable examples ≥ 8 lines each | Correct TARGET_LANG API names, show the methodology in action |
| Tradeoffs & Context | "Just do this" | Some nuance | When to use, when NOT to, alternatives, real costs | Covers anti-patterns with WHY, named alternatives, known adoption costs |
| Community Signal | None | Some warnings | ≥ 5 production lessons `[community]` with WHY | Named real-world pitfalls, not textbook truisms |

Target: **score ≥ 80** or **3 iterations** or **delta < 5** → stop.

**Topic → core concept checklist (drives Principle Coverage score):**

| Topic | Must cover |
|-------|-----------|
| `test-pyramid` | Unit/integration/e2e definitions + ratio targets (70/20/10 guideline), inverted pyramid + ice cream cone anti-patterns, Testing Trophy (Kent C. Dodds), Spotify Honeycomb, when to break the rules |
| `tdd` | Red-green-refactor cycle, baby steps, triangulation, fake-it-til-you-make-it, when TDD is hard (legacy, UI, algorithms) |
| `bdd` | Feature file structure (Feature/Scenario/Given-When-Then), step definitions, living documentation concept, Cucumber/Behave/SpecFlow setup, collaboration model (three amigos) |
| `test-isolation` | FIRST principles (Fast Independent Repeatable Self-validating Timely), Arrange-Act-Assert, test fixture setup/teardown, shared mutable state as flakiness root cause |
| `test-data` | Object Mother pattern, Test Data Builder pattern, factory library per language (factory_bot, FactoryBoy, AutoFixture, factory_girl), fixture vs factory tradeoffs, data isolation in parallel runs |
| `contract-testing` | Consumer-driven contracts definition, provider verification, Pact workflow (consumer writes → pact published → provider verifies), Pact Broker, CDC vs integration test tradeoffs |
| `flakiness` | Root causes taxonomy (timing, shared state, external deps, order-dependency), detection via reruns, quarantine strategy (tag don't delete), sleep() as smell |
| `coverage` | Line vs branch vs mutation coverage definitions, meaningful threshold origin (80% "smell detector" not quality guarantee), mutation testing tools (Pitest/Java, mutmut/Python, Stryker/JS), coverage ≠ quality |
| `ci-cd-testing` | Fail-fast ordering (unit first → integration → e2e), test parallelization strategies, test sharding, merge gates / required status checks, flaky test handling in CI (quarantine, retry with reporting) |
| `accessibility` | POUR principles (Perceivable Operable Understandable Robust), WCAG 2.1 AA conformance level, axe-core integration pattern, ARIA roles/landmarks, automated vs manual split (axe catches ~57%) |
| `shift-left` | Cost-of-defects curve (10x per phase), SAST tools per language, pre-commit hook setup, PR-level checks, developer ownership of tests |
| `exploratory` | Session-based test management (SBTM) definition, charter format ("Explore X with Y to discover Z"), FEW HICCUPS / HICCUPPS heuristics, bug taxonomy, when to use vs scripted testing |

---

## Phase 1a — Official sources (fetch in parallel)

Prompt for every WebFetch:
> "Extract: (1) core principles and WHY they matter, (2) methodology patterns with code
> examples in TARGET_LANG, (3) common anti-patterns with explanations, (4) tradeoffs
> and when this methodology does NOT apply."

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

# Run multiple in parallel: { _fetch_text URL1 & _fetch_text URL2 & wait; }
```

After fetching (by either method), synthesize against the prompt above.
If both methods fail, synthesize from training knowledge and note the source in the file header.

| Topic | URLs to fetch |
|-------|--------------|
| `test-pyramid` | `https://martinfowler.com/bliki/TestPyramid.html` · `https://martinfowler.com/articles/practical-test-pyramid.html` |
| `tdd` | `https://martinfowler.com/bliki/TestDrivenDevelopment.html` · `https://martinfowler.com/bliki/TestFirst.html` |
| `bdd` | `https://cucumber.io/docs/bdd/` · `https://cucumber.io/docs/gherkin/reference/` |
| `test-isolation` | `https://martinfowler.com/bliki/UnitTest.html` · `https://xunitpatterns.com/Four%20Phase%20Test.html` |
| `test-data` | `https://martinfowler.com/bliki/ObjectMother.html` · `https://martinfowler.com/bliki/TestDouble.html` |
| `contract-testing` | `https://docs.pact.io/` · `https://docs.pact.io/consumer` · `https://docs.pact.io/provider` |
| `flakiness` | `https://martinfowler.com/articles/nonDeterminism.html` · `https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html` |
| `coverage` | `https://martinfowler.com/bliki/TestCoverage.html` · `https://martinfowler.com/bliki/TestDrivenDevelopment.html` |
| `ci-cd-testing` | `https://martinfowler.com/articles/continuousIntegration.html` · `https://testing.googleblog.com/` |
| `accessibility` | `https://www.deque.com/axe/axe-for-web/` · `https://www.w3.org/WAI/WCAG21/quickref/` |
| `shift-left` | `https://www.ibm.com/topics/shift-left-testing` · `https://owasp.org/www-project-devsecops-guideline/` |
| `exploratory` | `https://www.satisfice.com/download/session-based-test-management` · `https://www.developsense.com/blog/2009/08/testing-from-an-exploratory-perspective/` |

If WebFetch is blocked, synthesize from training knowledge. Note the source in the
file header.

---

## Phase 1b — Community & real-world sources (run in parallel with 1a)

Prompt:
> "Extract: (1) patterns used in production that differ from textbook definitions,
> (2) common failure modes with root causes, (3) team adoption gotchas, (4) warnings
> about official patterns that don't scale or backfire."

**All topics — base community sources:**
- `https://testing.googleblog.com/` (search topic keywords)
- `https://martinfowler.com/testing/`
- WebSearch: `"<TARGET_TOPIC>" testing best practices production 2025`
- WebSearch: `"<TARGET_TOPIC>" testing anti-patterns real world 2025`

**Per-topic extras:**

| Topic | Additional community sources |
|-------|------------------------------|
| `test-pyramid` | `https://kentcdodds.com/blog/write-tests` · WebSearch: `test pyramid vs trophy practical 2025` |
| `tdd` | WebSearch: `TDD does it work production experience 2025` · `TDD false positives legacy code` |
| `bdd` | WebSearch: `BDD step definition bloat living documentation pitfalls 2025` |
| `test-isolation` | WebSearch: `test isolation shared state flakiness root causes 2025` |
| `test-data` | WebSearch: `test data factory pattern production tradeoffs 2025` |
| `contract-testing` | `https://github.com/pact-foundation/pact-js` README · WebSearch: `consumer-driven contracts real world adoption 2025` |
| `flakiness` | WebSearch: `flaky tests quarantine strategy CI pipeline 2025` · `flaky tests root causes detection 2025` |
| `coverage` | WebSearch: `100% test coverage harmful false confidence 2025` · `mutation testing pitest mutmut stryker production 2025` |
| `ci-cd-testing` | WebSearch: `test parallelization sharding monorepo CI strategy 2025` |
| `accessibility` | `https://github.com/dequelabs/axe-core` README · WebSearch: `axe-core WCAG automated testing limitations 2025` |
| `shift-left` | WebSearch: `shift left testing developer experience cost 2025` |
| `exploratory` | WebSearch: `exploratory testing session-based heuristics FEW HICCUPS 2025` |

**For non-JS/TS languages**, read `lang-refine/references/<TARGET_LANG>-patterns.md` if it
exists — use it to make code examples idiomatic for TARGET_LANG.

**If WebSearch is unavailable** and WebFetch is blocked, use the `_fetch_text` bash
helper from Phase 1a to fetch community URLs directly (GitHub READMEs, blog posts).
Use WebSearch queries as additional Bash search terms when synthesizing from training knowledge.

---

## Phase 2 — Write initial draft

Create the output directory if needed, then write the reference guide.

```bash
mkdir -p qa-methodology/references
```

Output path: `qa-methodology/references/<TARGET_TOPIC>-guide.md`

**Document structure:**

```
# <Topic Title> — QA Methodology Guide
<!-- lang: <TARGET_LANG> | topic: <TARGET_TOPIC> | iteration: 0 | score: ?/100 | date: YYYY-MM-DD -->

## Core Principles
<3–5 foundational ideas — the WHY before the HOW>

## When to Use
<Project types, team contexts, and maturity levels where this applies>

## Patterns

### <Pattern name>  [community] if from community
<One paragraph on why this matters>
<Code example in TARGET_LANG — ≥ 8 lines>

## Anti-Patterns
<What NOT to do, with WHY each is harmful>

## Real-World Gotchas  [community]
<≥ 5 production lessons, each tagged [community] with one-sentence WHY>

## Tradeoffs & Alternatives
<When this methodology doesn't apply; lighter alternatives; known adoption costs>

## Key Resources
| Name | Type | URL | Why useful |
|------|------|-----|------------|
```

All code examples must use actual TARGET_LANG syntax and APIs. Never use TypeScript
examples for Java output, etc. If a concept has no code (e.g., exploratory testing
charters), use YAML/pseudo-structured text instead.

---

## Phase 3 — Score the draft

Apply the rubric from Preamble. Be honest — 60–75 after a first draft is normal.

1. **Principle Coverage (0–25):** (concepts covered / total in checklist) × 25
2. **Code Examples (0–25):** each example — correct TARGET_LANG syntax, ≥ 8 lines, illustrates the methodology. Deduct 3 per weak example. Quote one line as evidence before giving 25/25.
3. **Tradeoffs & Context (0–25):** +5 for each present (max 5): when-to-use, when-NOT-to-use, named alternative, known adoption cost, anti-pattern with WHY.
4. **Community Signal (0–25):** min(count × 5, 25). Need ≥ 5 `[community]`-tagged lessons.

---

## Phase 4 — Refinement loop

Repeat until: **score ≥ 80**, OR **iterations ≥ 3**, OR **delta < 5**.

### 4a. Backup: `cp <file> <file>.prev`

### 4b. Identify lowest-scoring dimension. Pick targeted source:

| Gap | Best source |
|-----|-------------|
| Missing core concept | Phase 1a official URL for this topic |
| Thin code examples | Official example repo or lang-refine reference |
| Missing tradeoff | WebSearch: `<topic> when not to use costs tradeoffs` |
| Thin community signal | WebSearch: `<topic> production gotchas lessons learned 2025` |
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

## Phase 5 — Final report

```
## qa-methodology-refine: <TARGET_TOPIC> (<TARGET_LANG>)

Reference file:   qa-methodology/references/<TARGET_TOPIC>-guide.md
Final score:      <N>/100  (Coverage: X | Examples: X | Tradeoffs: X | Community: X)
Iterations run:   N
Language:         <TARGET_LANG>
Sources used:     [official | community | lang-refine]

Iteration trace:
  Iter 0: <score> — initial draft
  Iter 1: <score> (+delta) — <what changed>

Top 3 findings (with source):
1. <finding> [official | community]
2. ...

Community signal highlights:
- <most impactful production lesson>

Re-run:  /qa-methodology-refine <topic>
Used by: /qa-audit (reads qa-methodology/references/ for enriched recommendations)
```

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-methodology-refine","event":"completed","topic":"'"$TARGET_TOPIC"'","lang":"'"$TARGET_LANG"'","date":"'"$(date +%Y-%m-%d)"'"}' \
  2>/dev/null || true
```
