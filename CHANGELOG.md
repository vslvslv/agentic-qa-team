# Changelog

All notable changes to this project will be documented in this file.
Format: `vMAJOR.MINOR.PATCH.MICRO — YYYY-MM-DD — summary`

---

## v1.5.8.0 — 2026-04-28 — Extract test-file pattern + cost telemetry

Closes the **Impact 9** test-file-pattern duplication directly responsible for
three Copilot review rounds on PR #4, and ships the **Impact 6** cost telemetry
that was the last open item from the original audit.

### Added (`bin/qa-team-test-files`) — single source of truth

Multi-mode helper that owns the canonical "what is a test file?" definition.
Five modes:

- `--regex` — print the canonical `grep -E` pattern
- `--globs` — print the canonical `find -name` glob list (one per line)
- `--list` — list all test files in the cwd via `find`
- `--has-tests` — exit 0 if any test file found, 1 otherwise
- `--since=<git-ref>` — print test files changed since `<ref>` (validates ref,
  rejects unreachable refs with exit 3)

Canonical pattern: `\.(test|spec)\.[jt]sx?$|_test\.py$|(^|/)test_.*\.py$|Tests?\.cs$|_spec\.rb$|_test\.go$|Test\.java$|Tests\.java$`
plus the corresponding 16 find globs. Bash 3.2 compatible. No external deps
beyond git + grep + find.

### Changed — five drift sites collapsed to one

The same test-file pattern previously lived in five places:
- `qa-audit/SKILL.md` Preamble (delta regex)
- `qa-audit/SKILL.md` non-delta `_ALL_TESTS` find globs
- `qa-team/SKILL.md` Preamble `_HAS_TESTS` find globs
- `qa-team/SKILL.md` Phase 5 verify-loop regex
- `bin/qa-team-suggest-rerun` regex

All five now call `bin/qa-team-test-files` instead. Net deletion of inline
regex/globs in the SKILL.md files. The cross-reference comments added in
PR #4's fixups are gone — the helper is now the documentation. Future
extensions (e.g. Kotlin tests, Rust tests) only need to update the helper.

### Added (`bin/qa-team-cost-log` + `bin/qa-team-cost`) — cost observability

- **`bin/qa-team-cost-log <skill> <status> [duration_seconds]`** — appends one
  JSONL line per skill run to `<repo>/.qa-team/runs.jsonl`. Schema:
  `{timestamp, skill, status, branch, commit, duration_seconds}`. Silent on
  bad args, outside-of-git, and write failures (telemetry never blocks the
  wrapping skill). Always exits 0.

- **`bin/qa-team-cost`** — aggregator that reads `runs.jsonl` and prints a
  per-skill summary table:

  ```
    SKILL                    RUNS   PASS   WARN   FAIL  OTHER     WALL(s)  LAST
    ----------------------------------------------------------------------------
    qa-audit                    4      2      0      1      1          99  2026-04-28T08:38:29
    qa-api                      1      0      1      0      0          13  2026-04-28T08:38:29
    qa-team                     1      1      0      0      0         180  2026-04-28T08:38:29
  ```

  Flags: `--since=<N>h|<N>d` (time-window filter), `--skill=<name>` (single-
  skill filter), `--json` (raw aggregate for hooks/CI). Bash 3.2 compatible.
  Requires `jq` (errors with exit 2 if missing).

### Added (all 10 skill telemetry tails)

Every skill now invokes `bin/qa-team-cost-log` after its existing
`gstack-timeline-log` call. Three skills already had a `## Telemetry` section
(`qa-team`, `qa-audit`, `qa-methodology-refine`) — extended in place. The
other seven (`qa-api`, `qa-web`, `qa-visual`, `qa-perf`, `qa-mobile`,
`qa-refine`, `lang-refine`) had no telemetry tail before; one was added.

The cost-log call uses `2>/dev/null || true` so a misconfigured environment
never breaks a successful skill run.

### Notes

- **Deferred to a future PR (still under Impact 9):** version-check extraction
  (10 SKILL.md files repeat the same ~12-line block), JSON sidecar persistence
  extraction (6 sub-skills repeat the same ~10-line `cp + ln -sf` block).
  These are real duplication but lower drift risk than the test-file pattern,
  and touching all 10 SKILL.md files for a mechanical extraction is heavy
  review surface for marginal benefit. Tracked for a follow-up PR.
- **Schema for cost JSONL is informal** — it's a private telemetry stream
  consumed only by `bin/qa-team-cost`. If we eventually expose it as a
  public contract (e.g. CI dashboards), we should add a `schema_version`
  field at that point.

---

## v1.5.7.0 — 2026-04-28 — Delta mode + sticky scope

Closes **Impact 4** (`--since=<ref>` delta mode) and **Impact 8** (sticky scope) from the
original audit. Together they cut the cost of repeat runs and remove the friction of
re-confirming identical scope on every invocation.

### Added (`qa-audit`) — `--since=<git-ref>` delta mode

- New optional argument: `/qa-audit --since=<commit | branch | tag>`. When set,
  qa-audit scores **only the test files changed since `<ref>`** instead of the entire
  test tree. Designed for per-PR audits: `/qa-audit --since=main` in a feature branch
  scopes to the PR's test diff.
- Preamble validates the ref via `git rev-parse` and `git merge-base --is-ancestor`,
  aborting with a clear error if the ref is unknown or not reachable from `HEAD`.
- Phase 1 (Test Inventory) sampling switches from `find` globs to iterating the
  `_CHANGED_TEST_FILES` list. Existing layer-classification heuristics still apply.
- The markdown report prepends a "Delta scope" banner so readers know the score covers
  a subset, not the whole suite.
- The JSON sidecar gains a `delta_mode` object: `{ enabled, since_ref, base_sha,
  changed_files_count }`. Schema stays at `1.0` (additive field).
- **Delta runs are transient** — Phase 5c skips persistence to `.qa-team/` entirely
  when `_DELTA_MODE=1`. Full audits remain the canonical history; mixing in delta
  scores would corrupt trend rendering and the regression detection in qa-team Phase 5.
- `Important Rules` gain a new entry codifying the transient-by-design rule.

### Added (`qa-team`) — propagation + sticky scope + Phase 5 wiring

- **`--since=<ref>` propagation:** qa-team accepts the same arg, validates it once in
  the Preamble (before Phase 0), and threads it through to `qa-audit` in Phase 2's
  sub-agent template. Sub-agents that don't support delta mode (`qa-api`, `qa-web`,
  `qa-visual`, `qa-perf`, `qa-mobile`) ignore the flag harmlessly — their scoring is
  already incremental.
- **Sticky scope (Impact 8):** Phase 0 reads `<repo>/.qa-team/last-scope` if present
  and offers it as the **first** option in `AskUserQuestion` ("Re-run last scope
  (Recommended)"). Confirmed scope is persisted back to the same file at the end of
  Phase 0 so subsequent runs benefit. Eliminates re-clicking the same domain mix on
  every invocation in an established project.
- **Phase 5 verify loop now suggests `--since=`:** when the user has changed test
  files since the last full audit, the re-run prompt's first option is now
  `Yes — re-run /qa-audit --since=$_PRIOR_COMMIT (cheap, Recommended)`. This is the
  intended workflow — verify-after-fixes runs are exactly the case delta mode was
  designed for.
- Score-delta hint is now mode-aware: full re-runs render `Audit score: 76 → 84
  (+8 since 0939d0b)`; delta re-runs render `Delta-scope audit (12 changed test files
  since 0939d0b): 88/100`. Two different shapes because the numbers measure different
  things.
- `Important Rules` gain two new entries codifying delta-mode-is-for-verification and
  sticky-scope-is-a-default-not-a-lock.

### Notes
- No change to `bin/qa-team-history` or `bin/setup` — delta mode is invoked through
  the skill, not via CLI tools. `bin/qa-team-suggest-rerun` is touched only to fix a
  pre-existing test-file regex bug (subdir Python tests) and add a sync-comment
  cross-referencing the SKILL.md duplicates — no behavioural change to the hook.
- `schema_version` stays at `1.0`. The `delta_mode` field is additive; consumers that
  pin to 1.0 will see it as an unknown extra field and must tolerate it (per JSON
  contract conventions).

---

## v1.5.6.0 — 2026-04-28 — Default Stop-hook for re-run nudges

Closes Impact 7 from the original audit: skill discovery and re-run had been pull-only.
With this release, every Claude Code session now ends with an automatic check that
detects whether test files have changed since the last `/qa-*` run, and surfaces a
passive nudge to re-run the affected skill.

### Added (`bin/qa-team-suggest-rerun`)
- New shell script (bash 3.2 compatible, jq-optional) designed to run as a Claude Code
  Stop hook. On every Stop:
  1. Reads `.qa-team/qa-*-latest.json` from the active git repo (silently exits if
     none exists, the cwd is not a git repo, or `git` is missing).
  2. For each skill's recorded commit, compares against `HEAD`.
  3. If the prior commit is reachable from `HEAD` AND test files changed in between
     (matched against patterns for JS/TS, Python, C#, Java, Ruby, Go), prints a
     one-line nudge per skill to **stderr** (visible to the user, not consumed by
     the agent's stdout pipeline).
  4. Always exits 0 — this hook never blocks a Stop event.
- Performance budget: <200ms (no network, no LLM, no Docker).
- Five-case smoke-test covers: not-in-repo, no-history, no-changes-since,
  test-file-changed, and multi-skill deltas.

### Changed (`bin/setup`)
- New flags: `--with-hook` (skip prompt — install Stop hook unattended), `--no-hook`
  (skip the hook entirely), `--hook-only` (don't touch symlinks; install/update hook
  only). Default behaviour unchanged: prompt before installing.
- Default install now offers a Y/n prompt to wire `bin/qa-team-suggest-rerun` into
  `~/.claude/settings.json` under `.hooks.Stop`. Non-interactive stdin defaults to
  yes. Pre-existing hooks and other settings keys are preserved (verified end-to-end).
- Hook installation is **idempotent**: re-running setup detects an existing entry by
  command-string match and skips. Works with `jq` (preferred); without `jq`, prints a
  manual install snippet for the user to paste.
- Atomic merge: writes to a tempfile and `mv`s into place — no partial-write risk.
- Two new env-var overrides for testing: `CLAUDE_SETTINGS_FILE` and
  `CLAUDE_SKILLS_DIR` (pre-existing).

### Notes
- The hook is **passive** — it never auto-runs `/qa-*`. It only prints a nudge. The
  user (or agent) decides whether to re-run, preserving the same decision boundary
  the verify-after-fixes loop in v1.5.4.0 introduced.
- The hook references the absolute path of `qa-team-suggest-rerun`. If the repo is
  moved or symlinks are recreated under a different name, re-run `bash bin/setup
  --hook-only` to refresh the reference.
- Why a `Stop` hook and not `PostToolUse`: nudging on every edit would be noisy (the
  user is mid-flow). Stop fires once per session — exactly when the user is about to
  step away and ask "did I leave something undone?".

---

## v1.5.5.0 — 2026-04-28 — Extend JSON sidecar pattern to all sub-skills

### Added (sub-skills)
Every sub-skill now emits a parseable score file alongside its existing markdown report,
sharing the `schema_version: "1.0"` envelope (skill, branch, commit, timestamp, status,
report_md_path) introduced for `qa-audit` in v1.5.4.0:

- **qa-api:** Phase 5b/5c — `qa-api-score.json` with `tool`, `auth`, `counts{passed,
  failed, skipped, total}`, `endpoints{discovered, tested, missing}`, `schema_gaps_count`.
  History persisted to `<repo>/.qa-team/qa-api-*.{json,md}`.
- **qa-web:** Phase 4b/4c — `qa-web-score.json` with `tool`, `base_url`, `counts`,
  `pages{discovered, tested, missing}`, `failure_count`. Same history pattern.
- **qa-visual:** Phase 6b/6c — `qa-visual-score.json` with `tool`, `counts`,
  `screenshots{baselines, viewports_count}`, `regressions_count`,
  `baseline_update_required_count`. Same history pattern.
- **qa-perf:** Phase 4b/4c — `qa-perf-score.json` with `tool`, `target_url`,
  `thresholds_met`, `threshold_violations_count`, `scenarios{total, passed, failed}`,
  `metrics{p50_ms, p95_ms, p99_ms, rps, error_rate_pct}` (null = not measured).
  Same history pattern.
- **qa-mobile:** Phase 5b/5c — `qa-mobile-score.json` with `tool`, `platform`, `device`,
  `counts`, `screens{discovered, tested, missing}`, `failure_count`. Same history pattern.

Each skill's "Important Rules" gained a load-bearing entry: the JSON contract is consumed
by `qa-team` Phase 5 and `bin/qa-team-history`, so renames or removals require bumping
`schema_version` and updating consumers.

### Added (cross-link footers — Impact 5 from the original audit)
Every sub-skill's report now ends with an "After this run" block pointing at the next
relevant skill:
- `qa-audit` → `/qa-methodology-refine` for unfamiliar methodology, `/qa-refine` for
  language-specific patterns, re-run for delta
- `qa-api` → `/qa-audit` for methodology, `/qa-refine` for tooling, re-run for delta
- `qa-web` → `/qa-visual` for visual regression, `/qa-refine` for selectors, `/qa-audit`
- `qa-visual` → `/qa-web` for functional, `/qa-refine` for masking, `--update-snapshots`
  + re-run after intentional changes
- `qa-perf` → `/qa-api` for correctness, `/qa-refine` for tool patterns
- `qa-mobile` → `/qa-refine` for framework patterns, `/qa-audit` for methodology

This addresses the original audit's #5 finding: skill discovery has been pull-only;
inline cross-links make follow-ups self-evident in the report itself.

### Changed (bin/qa-team-history)
- New `--skill=<name>` flag. Recognised: `qa-audit`, `qa-api`, `qa-web`, `qa-visual`,
  `qa-perf`, `qa-mobile`, or `all`. Default unchanged: shows `qa-audit` history.
- New `--skill=all` mode renders one section per skill, with a placeholder when a skill
  has no history yet.
- Per-skill table shape:
  - `qa-audit`: `COMMIT · TIMESTAMP · OVERALL · DELTA · RATING` (existing)
  - others: `COMMIT · TIMESTAMP · STATUS · COUNTS · TOOL` (new, since these skills
    report `status` + `counts` rather than a 0–100 `overall`)
- Bash 3.2 portability fixes (`set -u` array-empty guard, `case` → `if` inside
  process-substitution loops). Smoke-tested with synthetic multi-skill history.
- New exit code `3` for unknown `--skill` argument.

### Notes
- The verify-after-fixes loop in `qa-team` (added in v1.5.4.0) now applies to every
  domain, not only audit. Any sub-skill whose JSON sits in `.qa-team/` can be diffed
  by commit and rendered in the trend table.
- Sub-skills that previously emitted only markdown continue to do so — the JSON is
  strictly additive. No existing consumer breaks.

---

## v1.5.4.0 — 2026-04-28 — Machine-readable score sidecar and verify-after-fixes loop

### Added (qa-audit)
- **Phase 5b — JSON sidecar:** writes `$TEMP/qa-audit-score.json` alongside the existing
  markdown report. Stable contract under `schema_version: "1.0"`: `overall`, `rating`,
  `dimensions{pyramid, isolation, test_data, naming, ci_coverage}`,
  `counts{unit, integration, e2e, unclassified, total}`,
  `flakiness{sleep_calls, retry_marks, risk}`, `critical_count`, `commit`, `branch`,
  `timestamp`, `report_md_path`. Validated as parseable JSON before continuing.
- **Phase 5c — History persistence:** copies the JSON sidecar and markdown report into
  `<repo>/.qa-team/qa-audit-<sha>-<ts>.{json,md}` with a `qa-audit-latest.json` symlink.
  Skipped silently outside a git repo. Enables score-trend analysis and per-commit
  comparisons across runs.
- **Important Rules:** new entry documenting the JSON contract is load-bearing —
  consumers (`qa-team` Phase 5, `bin/qa-team-history`, user-defined CI hooks) depend on
  it. Field renames or removals require bumping `schema_version`.

### Added (qa-team)
- **Phase 5 — Verify after fixes:** reads `.qa-team/qa-audit-latest.json`, computes which
  test files changed since the recorded commit, and uses `AskUserQuestion` to offer
  narrowed re-runs of affected sub-agents. Surfaces score delta in the Executive Summary
  on re-run ("76 → 84 (+8 since 0939d0b)"). Skipped silently when no history exists or
  HEAD already matches the recorded commit. Closes the loop between triage and
  measurement — turns the harness from one-shot report into a measurement instrument.
- **Important Rules:** new entry making Phase 5 the default expectation, not an
  optional nicety.

### Added (bin)
- **`bin/qa-team-history`:** new portable script (bash 3.2 compatible, jq-only
  dependency) that renders a score-trend table from `.qa-team/`. Modes: default table
  with delta column, `--limit=N`, `--json` (raw array for hooks/CI), `--delta` (skips
  the first row). Designed to be cheap enough to call from `Stop` hooks and CI gates.
  Smoke-tested with synthetic history.

### Notes
- Existing markdown reports are unchanged — this release is strictly additive.
- Sub-skills `qa-api`, `qa-web`, `qa-visual`, `qa-perf`, `qa-mobile` continue to emit
  markdown only. Adding JSON sidecars to them is a planned follow-up once the qa-audit
  shape is validated in practice.

---

## v1.5.3.0 — 2026-04-28 — Nightly refinement: all 22 guides reach 100/100

### Changed (reference guides + SKILL.md templates)
- **qa-methodology (12 guides):** All at 100/100. Language correction pass: tdd, test-isolation,
  coverage, ci-cd-testing, shift-left, contract-testing, test-pyramid rewrote code examples from
  TypeScript to JavaScript (project has no TypeScript dependency). New patterns added to flakiness
  (randomness seeding, React `act()`, Vitest concurrent isolation), accessibility (WCAG 2.2 SC 2.5.8
  target-size test, SPA focus management), bdd (`playwright-bdd`, step health tooling, CI sharding),
  exploratory (Whittaker tours, thread-based charters, AI-assisted debrief)
- **qa-web/references/playwright-patterns.md:** Added 15+ Playwright v1.49–v1.59 APIs: aria snapshots,
  `locator.describe()`, `toContainClass`, `setStorageState()`, CHIPS partitioned cookies,
  `--only-changed`, `failOnFlakyTests`, per-project workers, `page.pickLocator()`, Component Testing
  (experimental CT) with MSW router fixture; 10 iterations
- **qa-web/references/cypress-patterns.md:** Fixed `Cypress.Commands.addQuery()` (Cypress 12+) as
  correct retrying-selector API; `experimentalOriginDependencies` flag for `cy.origin()` custom
  commands; Cypress Module API; Vue 3 Component Testing; 3 iterations
- **qa-perf/references/k6-patterns.md:** Fixed deprecated `k6/experimental/websockets` →
  `k6/websockets` (stable); added k6 v0.57+ native TypeScript support via esbuild; CSV
  parameterisation with papaparse + SharedArray; OpenTelemetry stable output; 4 iterations
- **qa-mobile/references/detox-patterns.md:** Added `getAttributes()`, biometrics simulation
  (`matchFace`/`unmatchFace`), `by.traits()`, Expo/EAS integration, React Navigation ghost screen
  strategy, `device.setOrientation()`, flakiness root-cause decision tree; 10 iterations
- **qa-mobile/references/appium-wdio-patterns.md:** Added visual regression (`@wdio/visual-service`),
  device farm integration (BrowserStack/Sauce Labs), accessibility validation, test tagging
  (`WDIO_GREP`), environment/secrets management, quick-reference checklist; 10 iterations
- **lang-refine (5 guides):** All at 100/100. JavaScript: added CJS/ESM interop section, ES2023/2024
  features (`Object.groupBy`, `Promise.withResolvers`, `toSorted`), Symbol.iterator, Map/Set idioms.
  Python: added structural pattern matching (`match`/`case`). TypeScript: added `using`/`await using`
  (TS 5.2), assertion functions, typed decorators (TS 5.0), const type parameters
- **SKILL.md templates updated:** `qa-mobile`, `qa-perf`, `qa-refine`, `qa-web` regenerated from
  agent-updated `.tmpl` files

---

## v1.5.2.0 — 2026-04-26 — Auto-update check on every skill invocation

### Changed (all 10 skills)
- Added `## Version check` section to every `SKILL.md.tmpl` — runs before the Preamble on
  every skill invocation
- Calls `bin/qa-team-update-check` (existing script) to compare local vs remote VERSION
- If `UPGRADE_AVAILABLE`, uses `AskUserQuestion`: "Update before running?" with
  "Yes — update now (recommended)" / "No — run with current version" options
- If user selects "Yes": runs `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup"`
- 10-minute cooldown flag (`$_TMP/.qa-update-asked`) prevents repeated prompts when
  qa-team spawns multiple sub-agents in parallel within the same run
- Repo root resolved via `readlink ~/.claude/skills/<skill-name>` (short-names install)
  with fallback to `readlink ~/.claude/skills/qa-agentic-team` (namespaced/dev install)
- Applies to: `qa-team`, `qa-web`, `qa-api`, `qa-mobile`, `qa-perf`, `qa-visual`,
  `qa-audit`, `qa-refine`, `qa-methodology-refine`, `lang-refine`

---

## v1.5.1.0 — 2026-04-26 — Bash fetch fallback for WebFetch-restricted environments

### Changed (`/qa-refine`, `/qa-methodology-refine`)
- Added `_fetch_text` bash helper to Phase 1a of both research skills
- Helper tries Node 18+ built-in `fetch()` first (repo requires Node ≥ 18), falls back
  to Python3 `urllib.request`, strips HTML tags + entities + whitespace, truncates to 6000 chars
- Parallel fetch supported via `{ _fetch_text URL1 & _fetch_text URL2 & wait; }`
- Updated "if blocked" note at end of Phase 1a and Phase 1b to reference the helper
- Fixes research agents running as background subagents where WebFetch tool permission
  is restricted but outbound HTTP via Bash is still available

---

## v1.5.0.0 — 2026-04-26 — QA methodology layer: /qa-methodology-refine + /qa-audit

### Added (`/qa-methodology-refine`)
- New `/qa-methodology-refine` skill: runs the same autoresearch loop as `/qa-refine`
  but for QA methodology topics rather than tool-specific patterns
- Covers 12 methodology topics: `test-pyramid`, `tdd`, `bdd`, `test-isolation`,
  `test-data`, `contract-testing`, `flakiness`, `coverage`, `ci-cd-testing`,
  `accessibility`, `shift-left`, `exploratory`
- Step 0 topic detection: matches trigger phrases to topic key; prompts if unclear
- Step 0 language detection: same as `/qa-refine` — project signals → TARGET_LANG
- Phase 1a official sources per topic: martinfowler.com, cucumber.io, docs.pact.io,
  xunitpatterns.com, deque axe, WCAG quickref, Google Testing Blog, IBM shift-left
- Phase 1b community sources: Google Testing Blog, martinfowler.com/testing/,
  WebSearch per topic (production experience, anti-patterns, 2025)
- Quality rubric: Principle Coverage (topic checklist) · Code Examples (TARGET_LANG)
  · Tradeoffs & Context · Community Signal — same 0–100 scale as /qa-refine
- Per-topic concept checklist (drives Principle Coverage score): pyramid ratios,
  red-green-refactor, Feature file structure, FIRST principles, Object Mother, Pact
  workflow, flakiness root causes taxonomy, mutation testing tools, fail-fast CI
  ordering, WCAG 2.1 AA, cost-of-defects curve, SBTM charter format
- Output: `qa-methodology/references/<topic>-guide.md` (consumed by /qa-audit)

### Added (`/qa-audit`)
- New `/qa-audit` skill: static analysis of a project's test suite against methodology
  best practices, producing a scored report (0–100) with ranked recommendations
- 5-dimension scoring × 20 pts each: Pyramid Balance · Test Isolation · Test Data
  Strategy · Naming Quality · CI/Coverage Configuration
- Phase 1 test inventory: auto-classifies test files into unit / integration / e2e /
  unclassified using path patterns + import heuristics; computes pyramid ratios
- Phase 2 static checks: test naming quality (grep for vague names), AAA/GWT structure
  markers, shared mutable state detection, sleep/timing dependency count + locations,
  hardcoded test data vs factory/fixture ratio, coverage config & threshold presence,
  CI integration signals
- Phase 3 guide loading: reads `qa-methodology/references/` guides if present; maps
  each finding type to the relevant guide for enriched, sourced recommendations;
  graceful fallback to built-in knowledge when guides not yet generated
- Phase 5 audit report: per-dimension score table, test inventory table, up to 5
  ranked recommendations each with before/after code example and guide reference,
  flakiness risk summary, BDD signals, list of available methodology guides
- Works standalone or as qa-team sub-agent (writes to `$_TMP/qa-audit-report.md`)

### Changed (`/qa-team`)
- Preamble now detects test files (`*.spec.*`, `*.test.*`, `*_test.*`, `*Test.java`)
  and sets `_HAS_TESTS=1` flag
- Phase 0 auto-detection: any project with test files → include **qa-audit** domain
- Phase 0 `SELECTED_DOMAINS` and `DETECTED` echo updated to include `audit` and
  `AUDIT=${_HAS_TESTS}`
- Phase 2 sub-agent list: added `/qa-audit` → `$_TMP/qa-audit-report.md`
- Phase 3 aggregate loop: `for domain in web api mobile perf visual audit`
- Phase 4 report: added "Methodology Audit" section after Visual; updated "Domains
  Tested" line to include `audit`

### Changed (`bin/setup`)
- Echo section updated: reflects all 10 available skills with multi-tool descriptions;
  added `/qa-audit`, `/qa-methodology-refine`, `/qa-refine`, `/lang-refine` entries

---

## v1.4.0.0 — 2026-04-26 — Multi-tool support per QA category

### Added
- **`qa-web/tools/playwright.md`** — Auth (storageState), POM fixture pattern, selector
  ranking (getByRole > getByLabel > getByTestId), `page.route()` mocking, CI shard flags
- **`qa-web/tools/cypress.md`** — `cy.session()` auth, `cy.intercept()` mocking, data-cy
  selectors, Testing Library integration, headless CI flags, JSON reporter dispatch
- **`qa-web/tools/selenium.md`** — `BaseTest` pattern, `By.*` selector hierarchy,
  `WebDriverWait` explicit waits, Java/TS/Python examples, ChromeDriver pinning, headless mode
- **`qa-perf/tools/k6.md`** — Executor selection table, scenario/threshold script template,
  `SharedArray` parameterization, Web Vitals Playwright supplement, CI exit code 99 behavior
- **`qa-perf/tools/jmeter.md`** — Thread Group config, minimal JMX template, JSON token
  extractor, non-GUI `-n` mode, `-J` property overrides, JTL CSV parsing
- **`qa-perf/tools/locust.md`** — `HttpUser` + `@task(weight)` template, multi-class pattern,
  headless flags, `--csv` output, `--exit-code-on-error 1`, CSV stats parsing
- **`qa-web/references/cypress-patterns.md`** — qa-refine-generated Cypress best practices
- **`qa-web/references/selenium-patterns.md`** — qa-refine-generated Selenium best practices
- **`qa-perf/references/jmeter-patterns.md`** — qa-refine-generated JMeter best practices
- **`qa-perf/references/locust-patterns.md`** — qa-refine-generated Locust best practices
- **`qa-mobile/references/maestro-patterns.md`** — qa-refine-generated Maestro best practices

### Changed (`/qa-web`)
- Preamble now detects all three frameworks: Playwright (`playwright.config.*`), Cypress
  (`cypress.config.*`, `cypress/` dir, `"cypress"` in package.json), Selenium
  (`"selenium-webdriver"` in package.json; `selenium` in pom.xml/requirements.txt)
- Tool Selection Gate: exactly one → auto-select; zero or multiple → `AskUserQuestion`
  with recommendations based on project stack
- Phase 2 reads `qa-web/tools/<_WEB_TOOL>.md` sub-file after tool selection
- Phase 3 execute dispatches to the correct runner per `_WEB_TOOL`

### Changed (`/qa-perf`)
- Preamble now detects k6 (scripts/CLI), JMeter (`.jmx` files/CLI), and Locust
  (`locustfile.py`/CLI) with `_K6`, `_JMETER`, `_LOCUST` flags + JMX file count
- Tool Selection Gate: same 3-state pattern as qa-web
- Phase 2 reads `qa-perf/tools/<_PERF_TOOL>.md` sub-file
- Phase 3 execute dispatches per `_PERF_TOOL`

### Changed (`/qa-mobile`)
- Added Maestro detection: `.maestro/` directory, `which maestro`, YAML with Maestro
  commands (`appId:`, `tapOn:`, `assertVisible:`)
- Tool Selection Gate updated for three tools: Detox / Appium / Maestro
- Phase 3 adds inline Maestro YAML flow templates (login, invalid-login, suite runner)
  with Maestro tips (tapOn matching, runFlow reuse, envFile secrets, scrollUntilVisible)
- Phase 4 adds Maestro execute block (`maestro test --format junit --output`)
- Phase 5 report updated: Framework now lists "Detox / Appium+WebDriverIO / Maestro"

### Changed (`/qa-api`)
- Preamble adds language detection setting `_API_TOOL`: pom.xml/build.gradle → `java`;
  requirements.txt/conftest.py/pytest.ini/pyproject.toml → `python`; *.csproj/*.sln → `csharp`;
  Gemfile → `ruby`; package.json (default) → `playwright`
- Phase 3 replaced with 5 language-specific templates:
  TypeScript/JS (Playwright request context), Java (REST Assured + JUnit 5),
  Python (pytest + requests), C# (HttpClient + NUnit), Ruby (RSpec + Faraday)
- Phase 4 execute dispatches to mvn/gradle (Java), pytest (Python), dotnet (C#),
  rspec (Ruby), or npx playwright (JS/TS)
- "Portable by default" rule updated to "Language-native by default"

### Changed (`/qa-team`)
- Preamble now detects Cypress, Selenium, JMeter, Maestro signals alongside existing ones
- Adds `_WEB_TOOL`, `_PERF_TOOL`, `_MOB_TOOL` composite variables for orchestrator routing
- Phase 0 auto-detection rules updated: Cypress/Selenium → qa-web, JMeter → qa-perf,
  Maestro → qa-mobile
- Phase 2 sub-agent prompt template now passes `Detected tool:` field so sub-agents
  skip their tool selection gate when the orchestrator already knows the tool
- Phase 4 report headers now show dynamic tool names per domain

### Changed (`/qa-refine`)
- Tool→skill mapping expanded from 4 to 9 rows: added Cypress, Selenium, JMeter,
  Locust, Maestro — each with full pattern checklists and Phase 1a/1b source URLs
- Tool-language exceptions updated: Cypress (always TS/JS), Locust (always Python),
  Maestro (always YAML — skip TARGET_LANG detection, write flow files)
- Phase 2 reference file paths table updated with 5 new output paths

---

## v1.3.0.0 — 2026-04-26 — Multi-language qa-refine + new lang-refine skill

### Added (`/lang-refine`)
- New `/lang-refine` skill: researches programming language best practices using the same
  autoresearch loop as `/qa-refine` — official docs + community sources → score against a
  4-dimension rubric (Principle Coverage, Code Examples, Language Idioms, Community Signal)
  → iterative refinement until score ≥ 80 or 3 iterations
- Covers 10 language categories: `general` (SOLID, GoF, DRY/KISS/YAGNI, Law of Demeter,
  Composition over Inheritance), `typescript`, `javascript`, `java`, `python`, `csharp`,
  `kotlin`, `ruby`, `bash`, `functional`
- Per-language principle checklists in the rubric (e.g. Python: PEP 8, comprehensions,
  generators, context managers, type hints, dataclasses, EAFP vs LBYL)
- Phase 1a official sources per language (refactoring.guru, typescriptlang.org, peps.python.org,
  kotlinlang.org/docs/idioms, google styleguides, shellcheck.net, etc.)
- Phase 1b community sources per language (iluwatar/java-design-patterns 90k★,
  goldbergyoni/nodebestpractices 91k★, vinta/awesome-python, KotlinBy/awesome-kotlin, etc.)
- Output: `lang-refine/references/<language>-patterns.md` — standalone reference guides
  consumed by `/qa-refine` when a language idiom mismatch is identified

### Changed (`/qa-refine`)
- Added Step 0 — language detection: scans project signals (pom.xml → Java,
  conftest.py/requirements.txt → Python, *.csproj → C#, Gemfile → Ruby,
  package.json → JS/TS); k6, Detox, and WebDriverIO remain JS-only
- Added `TARGET_LANG` variable propagated through all phases
- Phase 1a Playwright URLs now language-specific (playwright.dev/java/docs/,
  playwright.dev/python/docs/, playwright.dev/dotnet/docs/)
- Phase 1a Appium client docs now language-specific (appium/java-client,
  appium/python-client, appium/dotnet-client, appium/ruby_lib)
- Phase 1b WebSearch queries now interpolate `{TARGET_LANG}` for targeted community research
- Phase 2 reference files now language-suffixed for non-TS languages
  (playwright-patterns-java.md, playwright-patterns-python.md) to coexist without overwriting
- Code example rule strengthened: must use actual TARGET_LANG API names, never TypeScript
  syntax in Java/Python examples
- Phase 4 gap→source table now includes "Language idiom mismatch →
  lang-refine/references/<TARGET_LANG>-patterns.md" for cross-skill knowledge transfer
- Phase 6 report now shows Language and Sources used fields

---

## v1.2.0.0 — 2026-04-26 — Expand qa-refine to community sources

### Changed (`/qa-refine`)
- Added Phase 1b: parallel community research alongside official docs — fetches
  awesome lists (mxschmitt/awesome-playwright, grafana/awesome-k6,
  webdriverio/awesome-webdriverio, saikrishna321/awesome-appium), official example
  repos (grafana/k6/examples, wix/Detox/examples, microsoft/playwright-examples,
  checkly/playwright-examples), and targeted WebSearch queries per tool
- Replaced Anti-Pattern rubric dimension with Community Signal (0–25): rewards
  production gotchas sourced from community blogs, GitHub Discussions, and awesome
  lists — patterns the official docs don't document
- Added `[community]` source tags to reference guide entries so readers know which
  patterns are doc-blessed vs. battle-tested in production
- Added "Real-World Gotchas" section to reference guide template (community-only)
- Added gap→source-type lookup table in Phase 4 so each gap is filled from the
  most appropriate source type
- Updated final report to list sources used and annotate top findings by source
- Updated k6 official doc URLs to grafana.com/docs/k6/latest (new canonical location)

---

## v1.1.0.0 — 2026-04-26 — Add qa-refine skill

### Added
- `/qa-refine` — Iterative research skill: fetches official docs for Playwright, k6, Detox,
  Appium/WebDriverIO, scores the result against a 4-dimension quality rubric (0–100), and
  runs an autoresearch-style loop (score → find gaps → targeted fetch → rewrite → re-score →
  keep/revert) until score ≥ 80 or 3 iterations. Also makes surgical updates to the
  corresponding skill's SKILL.md.tmpl. Includes scoring honesty enforcement to prevent
  premature loop exit.

---

## v1.0.0.0 — 2026-04-24 — Initial release

### Added
- `/qa-team` — Orchestrator: auto-detects project type, spawns specialized agents in parallel, aggregates results into a unified quality report
- `/qa-web` — Web E2E agent: discovers pages/routes, writes Playwright specs, executes, reports coverage
- `/qa-api` — API contract agent: reads OpenAPI/routes, generates HTTP tests (status codes, schema, auth enforcement), executes via Playwright request context
- `/qa-mobile` — Mobile agent: detects React Native/Expo (Detox) or native iOS/Android (Appium + WebDriverIO), generates screen tests, runs on simulator/emulator
- `/qa-perf` — Performance agent: writes k6 load scripts + Playwright Web Vitals tests, runs with ramp-up profiles, reports p50/p95/p99
- `/qa-visual` — Visual regression agent: captures Playwright screenshots, diffs against baselines, masks dynamic content, reports pixel regressions
- `bin/setup` — Symlink-based multi-platform installer
- `bin/dev-setup` / `bin/dev-teardown` — Developer mode: live-edits via single namespace symlink
- `bin/qa-team-update-check` — Periodic version check against GitHub main branch
- `bin/qa-team-next-version` — 4-part semver bump calculator
- `scripts/gen-skill-docs.sh` — Regenerates `SKILL.md` from `SKILL.md.tmpl` sources
- `scripts/check-skill-docs.sh` — CI freshness gate: fails if generated docs are stale
- GitHub Actions: `version-gate.yml`, `skill-docs.yml`
