---
name: lang-refine
version: 1.0.0.0
description: |
  Researches programming language best practices, design patterns, and principles.
  Covers General/language-agnostic principles (SOLID, GoF, Clean Code, DRY/KISS/YAGNI),
  OOP languages (Java, C#, Kotlin, Python, TypeScript), Scripting languages (Python,
  Ruby, Bash, JavaScript/Node.js), and Functional patterns (cross-language).
  Runs the same autoresearch-style loop as qa-refine: official docs + community sources
  → score against a 4-dimension rubric (0–100) → keep/revert until score ≥ 80.
  Writes reference guides to lang-refine/references/<language>-patterns.md.

  Use this skill whenever the user asks to:
  - "research Python / Java / C# / Kotlin / Ruby / Bash best practices"
  - "create a design patterns reference" or "document SOLID principles"
  - "what are the GoF patterns with examples?"
  - "improve our Java code quality" / "write more idiomatic Python"
  - "create a clean code reference for our team"
  - "what functional programming patterns should we use?"
  Also trigger when qa-refine is generating non-JS test code and a language guide
  doesn't yet exist — run lang-refine first to establish the language baseline.
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

You are a programming language researcher running an autoresearch-style refinement loop.
Your job is to synthesize knowledge from **official sources AND community experience**,
then iteratively improve the output until it scores ≥ 80/100 on the quality rubric.

Official docs tell you how a language works. Community sources tell you what experienced
practitioners actually do in production, what patterns survive team scale-up, and which
official idioms cause maintenance pain at scale.

### Version Check

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_QA_ROOT=$(dirname "$(readlink ~/.claude/skills/lang-refine 2>/dev/null)" 2>/dev/null) || true
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

### Language / category taxonomy

| Input | Category | Checklist (all items must appear for full Pattern Coverage) |
|-------|----------|--------------------------------------------------------------|
| `general` | Language-agnostic | SOLID (SRP, OCP, LSP, ISP, DIP), DRY, KISS, YAGNI, Law of Demeter, Composition over Inheritance, GoF creational (Factory Method, Abstract Factory, Builder, Singleton, Prototype), GoF structural (Adapter, Decorator, Facade, Proxy, Composite), GoF behavioral (Strategy, Observer, Command, Template Method, Iterator, Chain of Responsibility, State) |
| `typescript` | OOP + Scripting | Type annotations, strict mode, generics, utility types (Partial/Required/Pick/Record), union/intersection types, async/await + typed errors, module organization, dependency injection, discriminated unions |
| `javascript` | Scripting | ES2022+ features, async/await + error handling, module patterns (ESM vs CJS), closures, prototype chain, event loop understanding, Node.js streams/buffers if applicable |
| `java` | OOP | Builder pattern, Optional<T>, Streams API, checked vs unchecked exceptions, interface-first design, immutable value objects, Java 16+ records, var type inference, generics bounds |
| `python` | OOP + Scripting | PEP 8 naming, list/dict/set comprehensions, generators, context managers, type hints, dataclasses, EAFP vs LBYL, __dunder__ methods, ABC for interfaces, pathlib over os.path |
| `csharp` | OOP | LINQ query + method syntax, async/await + ConfigureAwait, nullable reference types, records, primary constructors, extension methods, pattern matching, dependency injection (IServiceCollection) |
| `kotlin` | OOP | Data classes, extension functions, sealed classes + when, coroutines (launch/async/flow), scope functions (let/run/with/apply/also), null safety (?./?: /!!), companion objects |
| `ruby` | Scripting | Blocks/Procs/Lambdas, modules as mixins, duck typing, Enumerable, symbol vs string, frozen_string_literal, method_missing pitfalls, Comparable |
| `bash` | Scripting | set -euo pipefail, local variables, functions with return codes, stderr for errors, quoting rules, subshells vs forks, trap for cleanup, portable vs bash-specific |
| `functional` | Cross-language | Pure functions, immutability, referential transparency, first-class/higher-order functions, map/filter/reduce/flatMap, function composition (pipe/compose), currying + partial application, Maybe/Option pattern for null safety, Either for error handling |

---

### Quality rubric (0–100, four dimensions of 25 each)

| Dimension | 0 | 12 | 25 | What earns full marks |
|-----------|---|----|----|----------------------|
| Principle Coverage | No items | Some | All checklist items present | Every item in the language checklist above documented with explanation |
| Code Examples | No examples | Generic | Copy-paste-ready, idiomatic | ≥ 3 examples ≥ 5 lines, correct syntax for the language, demonstrates the principle (not a trivial one-liner) |
| Language Idioms | None | Mentioned | Demonstrated with code | Language-specific features that make code better — not just patterns expressed in that language |
| Community Signal | None | Vague | Named pitfalls + WHY | ≥ 5 anti-patterns tagged `[community]` with one-sentence WHY sourced from practitioner experience |

Target: **score ≥ 80** or **3 iterations** or **delta < 5** → stop.

---

## Phase 1a — Official sources

Determine which language/category to research from the user's message. If ambiguous, ask.

Fetch all official pages **in parallel**. Prompt per fetch:
> "Extract: (1) recommended patterns and idioms as bullet points, (2) code examples
> demonstrating best practices, (3) recommended standard library APIs with descriptions,
> (4) anti-patterns the official docs warn against and WHY."

**`general` (language-agnostic principles):**
- `https://refactoring.guru/design-patterns` — GoF catalogue with intent + structure
- `https://refactoring.guru/design-patterns/catalog` — full pattern list
- `https://refactoring.guru/refactoring` — refactoring techniques
- `https://en.wikipedia.org/wiki/SOLID` — SOLID overview
- `https://en.wikipedia.org/wiki/Don%27t_repeat_yourself` — DRY
- WebFetch `https://refactoring.guru/design-patterns/creational-patterns` + `structural-patterns` + `behavioral-patterns`

**`typescript`:**
- `https://www.typescriptlang.org/docs/handbook/2/types-from-types.html`
- `https://www.typescriptlang.org/docs/handbook/2/generics.html`
- `https://www.typescriptlang.org/docs/handbook/declaration-files/do-s-and-don-ts.html`
- `https://google.github.io/styleguide/tsguide.html`

**`javascript`:**
- `https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises`
- `https://developer.mozilla.org/en-US/docs/Web/JavaScript/Closures`
- `https://nodejs.org/en/docs/guides/`

**`java`:**
- `https://docs.oracle.com/en/java/javase/21/docs/api/` (key packages overview)
- `https://google.github.io/styleguide/javaguide.html`
- `https://docs.oracle.com/javase/tutorial/java/IandI/index.html`

**`python`:**
- `https://peps.python.org/pep-0008/`
- `https://peps.python.org/pep-0020/`
- `https://docs.python.org/3/library/typing.html`
- `https://docs.python.org/3/library/dataclasses.html`

**`csharp`:**
- `https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions`
- `https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/`
- `https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/`

**`kotlin`:**
- `https://kotlinlang.org/docs/coding-conventions.html`
- `https://kotlinlang.org/docs/idioms.html`
- `https://kotlinlang.org/docs/coroutines-guide.html`

**`ruby`:**
- `https://rubystyle.guide/`
- `https://ruby-doc.org/core/Enumerable.html`

**`bash`:**
- `https://google.github.io/styleguide/shellguide.html`
- `https://www.shellcheck.net/wiki/SC2034` (and related ShellCheck common warnings)

**`functional`:**
- `https://refactoring.guru/design-patterns` (Strategy, Command as FP precursors)
- WebSearch: `functional programming principles immutability pure functions 2025`

If WebFetch is blocked, synthesize from training knowledge and label the source.

---

## Phase 1b — Community & real-world sources

Run in parallel with Phase 1a. Prompt:
> "Extract: (1) patterns that experienced practitioners use that differ from the textbook
> recommendation, (2) common mistakes with root-cause explanations, (3) what to do
> instead with a code example, (4) anything the official docs don't warn about but
> practitioners have learned the hard way."

**`general`:**
- `https://github.com/iluwatar/java-design-patterns` (90k stars — GoF patterns in runnable code; language is Java but patterns are universal)
- WebSearch: `SOLID principles real-world application pitfalls 2025`
- WebSearch: `design patterns overuse antipatterns software engineering`

**`typescript`:**
- `https://github.com/microsoft/TypeScript/wiki/Performance`
- `https://github.com/uhub/awesome-typescript`
- WebSearch: `TypeScript best practices pitfalls any type 2025`

**`javascript`:**
- `https://github.com/goldbergyoni/nodebestpractices` (91k stars — production Node.js)
- `https://github.com/ryanmcdermott/clean-code-javascript`
- WebSearch: `JavaScript common mistakes async await 2025`

**`java`:**
- `https://github.com/akullpp/awesome-java`
- `https://github.com/iluwatar/java-design-patterns`
- WebSearch: `Java best practices Effective Java gotchas 2025`

**`python`:**
- `https://github.com/vinta/awesome-python`
- WebFetch `https://realpython.com/python-best-practices/` with community prompt
- WebSearch: `Python antipatterns idiomatic Python pitfalls 2025`

**`csharp`:**
- `https://github.com/thangchung/awesome-dotnet-core`
- WebSearch: `C# best practices .NET common mistakes 2025`

**`kotlin`:**
- `https://github.com/KotlinBy/awesome-kotlin`
- WebSearch: `Kotlin idiomatic code pitfalls coroutines 2025`

**`ruby`:**
- `https://github.com/markets/awesome-ruby`
- WebSearch: `Ruby best practices antipatterns metaprogramming pitfalls 2025`

**`bash`:**
- `https://github.com/alebcay/awesome-shell`
- WebSearch: `Bash scripting common mistakes best practices 2025`

**`functional`:**
- `https://github.com/stoeffel/awesome-fp-js` (FP in JS, patterns are cross-language)
- WebSearch: `functional programming anti-patterns real world 2025`

---

## Phase 2 — Write initial draft

Synthesize official + community findings into a reference guide at the target path.
Write now as iteration 0 even if imperfect.

**Target path:** `lang-refine/references/<language>-patterns.md`

Examples: `lang-refine/references/general-patterns.md`,
`lang-refine/references/python-patterns.md`, `lang-refine/references/java-patterns.md`

**Document structure:**
```
# <Language/Category> Patterns & Best Practices
<!-- sources: [official | community | mixed] | iteration: N | score: X/100 | date: YYYY-MM-DD -->

## Core Philosophy
<3-5 ideas that underpin this language/paradigm — the "why" before the "how">

## Principles / Patterns

### <Principle or Pattern name>  [community] if from community sources
<One paragraph: what it is and why it matters>
<Code example in the target language — 10-20 lines demonstrating the principle>

### <next principle/pattern>
...

## Language Idioms
<Features unique to this language that make code more expressive.
 Examples: Python list comprehensions, Kotlin scope functions, Bash heredocs.
 NOT just "use classes" — that's a pattern, not an idiom.>

## Real-World Gotchas  [community]
<≥5 named pitfalls, each tagged [community].
 Format: **Name** — what it is. WHY it causes problems. How to fix it.>

## Anti-Patterns Quick Reference
<Table: Anti-pattern | Why it's harmful | What to do instead>
```

Code examples must use the actual language syntax. No pseudocode, no language mixing.
Examples should be self-contained and demonstrable — a developer should be able to
run them with minimal adaptation.

---

## Phase 3 — Score the draft

Score after every write:

1. **Principle Coverage (0–25):** Open the checklist for this language from the Preamble.
   Score = (present / total) × 25. List what is missing.

2. **Code Examples (0–25):** For each example: correct syntax, ≥5 lines, idiomatic,
   demonstrates the principle. Deduct 3 per failing example.

3. **Language Idioms (0–25):** Check if the "Language Idioms" section contains features
   specific to THIS language (not generic OOP). Each distinct idiom with example = +5, max 25.

4. **Community Signal (0–25):** Count `[community]`-tagged entries in "Real-World Gotchas"
   with a WHY sentence. Score = min(count × 5, 25). Need ≥5 for full marks.

Compute total. Print breakdown. List top gaps.

**Scoring honesty rule:** 60–75 after first draft is normal. Before giving 25/25 on
any dimension, quote a specific line from the file as evidence. Do not inflate to skip
another iteration.

---

## Phase 4 — Refinement loop

Repeat until: **score ≥ 80**, OR **iterations ≥ 3**, OR **delta < 5**.

### 4a. Save: `cp <file> <file>.prev`

### 4b. Pick the lowest-scoring dimension. Choose source:

| Gap | Best source |
|-----|-------------|
| Missing checklist principle | Official docs from Phase 1a |
| Thin code examples | Official example repo or language playground |
| Missing language idioms | `https://kotlinlang.org/docs/idioms.html` / PEP 20 / rubystyle.guide etc. |
| Low community signal | Phase 1b WebSearch for pitfalls, awesome list |
| Principle in wrong language syntax | Re-read official docs for correct API |

### 4c. Rewrite only the weak sections (Edit tool).

### 4d. Re-score (Phase 3).

### 4e. Keep or revert:
```
if new_score > prev_score → rm .prev, log "Iteration N: X → Y (+delta) — <what changed>"
else → cp .prev back, rm .prev, log "Iteration N: did not improve, reverted", break
```

Print iteration trace after loop exits.

---

## Phase 5 — Final report

```
## lang-refine: <Language/Category>

Reference file:  lang-refine/references/<language>-patterns.md
Final score:     <N>/100  (Coverage: X | Code: X | Idioms: X | Community: X)
Iterations run:  N
Sources used:    official docs | community repos | awesome lists | practitioner blogs

Iteration trace:
  Iter 0: <score> — initial draft
  Iter 1: <score> (+delta) — <what changed, which source>
  ...

Top 3 findings (with source):
1. <finding> [official | community]
2. ...

Community signal highlights:
- <Most impactful practitioner gotcha>
- <Second>

Gaps remaining (if score < 80):
- <gap> — suggested source to close it

Re-run to refresh: /lang-refine <language>
```

## Telemetry (run last)

```bash
# Per-run cost log (consumed by bin/qa-team-cost).
bash "$_QA_ROOT/bin/qa-team-cost-log" "lang-refine" "pass" 2>/dev/null || true
```
