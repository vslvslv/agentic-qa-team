# Changelog

All notable changes to this project will be documented in this file.
Format: `vMAJOR.MINOR.PATCH.MICRO — YYYY-MM-DD — summary`

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
