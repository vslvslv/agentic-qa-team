# Changelog

All notable changes to this project will be documented in this file.
Format: `vMAJOR.MINOR.PATCH.MICRO — YYYY-MM-DD — summary`

---

## v1.16.0.0 — 2026-05-06 — 17 new skills + 2 enhancements (BL-067..BL-107)

### New skills

- **qa-secrets** (BL-067) — TruffleHog git history + staged diff secrets scanner; verified secrets = FAIL; unverified = warn; regex fallback when trufflehog absent
- **qa-sca** (BL-106) — Syft SBOM (CycloneDX) + Grype CVE scan + license compliance; delta vs previous SBOM to surface only new findings
- **qa-slsa** (BL-098) — SLSA provenance attestation verification via `gh attestation verify` + `slsa-verifier`; tampered artifacts = hard FAIL
- **qa-env-parity** (BL-099) — Env var drift detection across dev/staging/prod .env files; LLM classifies required-missing / expected-drift / stale-orphaned
- **qa-test-lint** (BL-103) — Static test smell scanner: sleep(), assertion-free, permanent skips, empty describes, console.log, magic numbers, duplicate bodies
- **qa-test-order** (BL-104) — Randomized test order runner (jest --randomize, pytest-randomly, go test -shuffle) to detect order-dependent state leakage
- **qa-test-docs** (BL-105) — LLM reads test files grouped by domain → human-readable Markdown docs with business rules, edge cases, and coverage gaps
- **qa-coverage-gate** (BL-069) — Per-file coverage delta gate vs base branch; LLM stub suggestions for uncovered lines on files below threshold
- **qa-report** (BL-070) — Aggregates all CTRF files → unified sprint/PR dashboard with LLM top-3 risk narrative and flaky registry enrichment
- **qa-cost** (BL-071) — Token cost tracking across QA runs using CTRF metadata; optional CI budget gate (`QA_COST_BUDGET`)
- **qa-eval-gate** (BL-101) — CI gate: discovers evals/ dir, runs promptfoo/deepeval/custom evals, blocks if pass-rate < `EVAL_PASS_THRESHOLD` (default 0.8)
- **qa-intent-assert** (BL-102) — NL code property assertions via `*.intent.yaml` files; LLM judge evaluates each assertion against target code
- **qa-geo** (BL-100) — Playwright timezone + geolocation simulation matrix (4 timezones × N pages); catches date/locale formatting bugs and geo-gated regressions
- **qa-deeplinks** (BL-107) — Deep link / universal link validator; parses AASA, assetlinks.json, AndroidManifest; tests cold-start + in-app via xcrun/adb/Playwright
- **qa-deps** (BL-088) — Docker Compose service dependency smoke test; type-aware health checks (pg_isready, redis-cli ping, kafka topics, HTTP /health); teardown on exit
- **qa-ci-trace** (BL-072) — OTel/Honeycomb build trace analysis → ranked CI optimization recommendations (slowest steps, parallelism gaps, cache misses)
- **qa-spec-to-test** (BL-073) — Markdown PRD/spec → YAML test plan → optional Playwright skeleton .spec.ts files; tags scenarios P1/P2/P3 by priority language

### Enhancements

- **qa-a11y** (BL-068) — Added `A11Y_BASELINE_MODE` (full|diff, default diff): saves per-branch baseline JSON; diff mode suppresses existing violations, surfacing only new regressions
- **qa-explore** (BL-074) — Added `CONSENSUS_MODE`: when `GEMINI_API_KEY` set, functional assertion findings are validated by Claude + Gemini with a third-Claude arbitration; only majority-FAIL findings count

### Infrastructure

- `qa-team/SKILL.md.tmpl`: added qa-secrets, qa-sca, qa-geo, qa-deps to auto-dispatch; qa-deeplinks added as opt-in (`QA_DEEPLINKS=1`)
- `bin/setup`: added 17 new `/qa-*` command descriptions to available commands footer
- `.claude/agents/`: 17 new agent files created

---

## v1.15.0.1 — 2026-05-06 — nightly learning-sources catalog update

### learning-sources
- +28 new sources: 13 QA tools (Playwright clock/mock/network/locators/actions/nav/screenshots/videos, k6 extensions/env vars, k6-operator, Karate, Jest), 6 languages (PEP 484, pytest good practices, TC39 proposals, Biome, Oxc, Jest), 4 methodology (Fowler Practical Test Pyramid, Pact University, Pact Broker sharing, Cucumber tutorial), 5 security/a11y/AI (OWASP ASVS v5, OWASP LLM VS, Trivy, Gitleaks, AgentOps)
- 0 stale entries flagged — all 258 catalog entries current

---

## v1.15.0.0 — 2026-05-04 — qa-meta-eval + qa-manager (BL-011, BL-050, BL-051)

### qa-meta-eval (new skill — BL-011)
- Adversarial red-teaming of QA skills: 8 scenarios × UserSimulatorAgent + JudgeAgent
- Scenarios cover: no-test-files (qa-web), no-OpenAPI-spec (qa-api), broken-selector (qa-heal),
  hollow-tests (qa-audit), zero-a11y-elements (qa-mobile), server-unreachable (qa-perf),
  high-complexity routing (qa-web), timing-flakiness classification (qa-heal)
- Phase 4 report: per-skill pass rate table; flags skills below 80% with anti-pattern breakdown
- CTRF output; `QA_META_TARGET=<skill>` env var scopes run to one target skill
- Scenarios defined in `qa-refine-workspace/meta-evals/scenarios.json` (versioned)

### qa-manager (new skill — BL-050 + BL-051)
- Mode A (Epic → Playwright, BL-050): JIRA Epic → Features → User Stories → Test Plan →
  Playwright spec skeletons with `// TC-{id}` + `// Story: {key}` traceability comments;
  versioned JSON artifacts at every stage (`test-specs/01_epic_*.confirmed.v1.json`, etc.);
  AskUserQuestion confirmation gates; final traceability matrix JSON
- Mode B (Figma → Test Cases, BL-051): parses Figma URLs from JIRA sprint ticket bodies;
  fetches frame PNGs via Figma API (`/v1/images/{fileKey}`); Claude vision analysis → structured
  test cases (Title, Preconditions, Steps, Expected Result, Priority); pushes to TestRail or
  Xray TCMS; markdown fallback when TCMS not configured
- Env vars: `JIRA_URL`, `JIRA_TOKEN`, `FIGMA_TOKEN`, `TESTRAIL_URL`/`XRAY_URL`, `JIRA_EPIC_ID`
- Both modes degrade gracefully when integrations are unavailable (manual-input fallback)

---

## v1.14.0.0 — 2026-05-04 — [M] batch: observability RCA, contract testing, chaos, VLM mobile, DOM metrics, offline CI

### qa-observability (new skill — BL-057)
- New skill + agent: HolmesGPT-style failure RCA loop — fetches OTel traces (Jaeger/Tempo), queries Loki logs (±30s window), synthesizes root cause with HIGH/MEDIUM/LOW confidence
- Auto-discovers local observability endpoints (localhost:16686 Jaeger, :3200 Tempo, :3100 Loki)
- Output: `FAILURE_REASON` block appended to failing skill's report; CTRF JSON emitted

### qa-api (BL-010 + BL-025 + BL-031 + BL-032 + BL-056 + BL-064)
- Phase 0.75: OpenAPI contract testing via Dredd — validates running API against spec, flags schema drift before test generation
- Phase 3: Tracetest span assertions — generates `tracetest/*.yaml` alongside HTTP tests; asserts DB span latency, auth gRPC status
- Phase 4d: Pact consumer contract verification — auto-runs when `*.pact.json` / `pacts/*.json` found
- Phase 4e: RESTler stateful REST fuzzing — opt-in via `QA_DEEP_FUZZ=1`; Docker-based; reports bug buckets by category
- Phase 4f: Keploy eBPF traffic re-recording — record mode (`QA_KEPLOY_RECORD=1`) + replay mode when fixtures exist
- Phase 4g: aimock offline record/replay — record mode + replay proxy for deterministic CI
- Preamble: aimock, Keploy, Pact file, Tracetest detections added

### qa-visual (BL-009 + BL-043)
- Phase 4.5: DOM metric extraction — `page.evaluate()` captures bounding boxes, colors, font sizes; only escalates to full screenshot when metrics diverge; `.visual-spec/` file support
- Phase 5.5: Multi-model consensus (Layer 2b) — second judge call + arbiter when models disagree; verdict caching by diff-file SHA

### qa-mobile (BL-045 + BL-046 + BL-047)
- Phase 4.5: Midscene VLM fallback — `aiAction()` when selectors break; Maestro `.midscene.yaml` parallel flows
- Phase 4.5: OmniParser perception layer — triggered when accessibility tree yields 0 elements; Docker service at localhost:8000
- Phase 4.5: Mobile-Agent Reflector — `withReflection()` wrapper; up to 2 retries per step; reflection rate tracking → flakiness candidates

### qa-perf (BL-039 + BL-040 + BL-041)
- Phase 3.5: LitmusChaos concurrent resilience — `QA_CHAOS=1`; ChaosEngine YAML auto-generated from k6 thresholds; concurrent chaos + load run
- Phase 3.5: GoReplay production traffic replay — `QA_REPLAY_MODE=1`; capture + replay modes; per-endpoint p99 regression analysis
- Phase 4.6: Bencher continuous benchmarking — pushes k6 summary to Bencher trend store; Claude writes 1-paragraph regression narrative

### qa-web (BL-005 + BL-025 + BL-066)
- Phase 2: aimock record/replay integration — fixture-based offline CI mode
- Phase 2: TestZeus Hercules — Gherkin `.feature` file detection; Hercules execution when available; fallback to Playwright spec generation from Gherkin steps
- BL-005 marked implemented (NL mode covered by BL-049)

### qa-team (BL-024 + BL-025)
- Phase 1.5: Container isolation — Testcontainers provisioning from `test-env.yml`; per-agent `DB_URL`/`REDIS_URL` injection; teardown after Phase 2
- Phase 1.5: aimock pre-spawn proxy — starts replay proxy before spawning sub-agents; stops after Phase 2

### qa-heal (BL-064)
- Phase 3: Keploy eBPF re-recording — triggered on `api-schema-change` failure type; schema delta analysis; auto-commit when ≤5 files changed

---

## v1.13.0.0 — 2026-05-03 — [S] quick-wins: AndroidWorld templates, NL tests, OTel tracing, Honeycomb CI, Lost Pixel, test impact scoping

### qa-mobile
- Phase 2.5: AndroidWorld template matching (BL-048) — maps discovered screens to 20 task categories (Clock, Calendar, Contacts, File Manager, Settings, Browser, Messaging, Email, Maps, Camera, Notes, Tasks, Shopping, Media, Health, Finance, Auth, Search, Notifications, Forms); generates framework-appropriate tests per category

### qa-web
- Phase 2 NL mode (BL-049): Shortest natural-language test generation — `<feature>.shortest.ts` pattern when `_SHORTEST_AVAILABLE=1`; reads `tests.nl.md` if present
- Preamble: `_SHORTEST_AVAILABLE` + `_NL_TESTS_EXIST` detection
- Phase 2 OTel tracing (BL-055): injects W3C `traceparent` header into all test-driven HTTP requests via `page.route()`; annotates failures with `traceId` for backend correlation

### qa-api
- Phase 3 OTel header (BL-055): injects `traceparent` into `APIRequestContext` when `_OTEL_AVAILABLE=1`; annotates CTRF failure messages with trace IDs
- Preamble: `_OTEL_AVAILABLE` detection (`OTEL_EXPORTER_OTLP_ENDPOINT` presence)

### qa-visual
- Phase 4 Lost Pixel fallback (BL-061): when neither `APPLITOOLS_API_KEY` nor `CHROMATIC_PROJECT_TOKEN` is set, auto-generates `lostpixel.config.ts` with Tailwind-derived breakpoints `[375, 768, 1280, 1920]`; coexists with Playwright `toHaveScreenshot`

### qa-heal
- Phase 0.5 test impact scoping (BL-063): `git diff --name-only origin/main` → stem-based co-located test mapping; scopes heal run to impacted tests when `_IMPACTED_COUNT > 0`; falls back to full suite when no mapping found

### CI (.github/workflows/qa-report.yml)
- Honeycomb opt-in step (BL-058): emits one OTel event per QA domain to Honeycomb Events API; activated by `HONEYCOMB_API_KEY` secret; dataset configurable via `HONEYCOMB_DATASET` var

### learning-sources (catalog expansion)
- `qa-tools.md`: expanded from 30 → 74 entries (BACKLOG sources: Storybook, fast-check, Litmus, Pyroscope, Stryker, BackstopJS, Playwright MCP, Midscene, shortest, Artillery MCP, GoReplay, 35+ repos)
- `qa-methodology.md`: expanded from 22 → 24 entries (Trunk flaky-tests blog, PactFlow blog, Meta ACH mutation testing research)
- `security-a11y-ai.md`: expanded from 20 → 36 entries (sniff, ai-pentest-agent, Aura, testsigma, AppAgent, MobileAgent, UI-TARS, OmniParser, HolmesGPT, TestZeus, TestPilot2, Autonomous-QA-Agent, FinalRun, SWE-AF, Passmark)
- `INDEX.md`: updated entry counts to 74/24/28/36

---

## v1.12.0.0 — 2026-05-03 — learning-sources-refinement skill + catalog-first integration

### learning-sources-refinement (new skill)
- Maintains shared knowledge base in `learning-sources/` across 4 domains:
  QA tools, QA methodology, programming languages, security/a11y/AI testing
- Phase 1: catalog review — stale detection (>6 months), gap analysis (<5 entries per section)
- Phase 2: domain search — WebSearch + WebFetch for new official docs, GitHub repos, blogs
- Phase 3: catalog update — appends new entries, flags stale inline, updates INDEX.md
- Phase 4: discovery report with per-skill source recommendations

### learning-sources/ (new catalog — 5 files, pre-seeded)
- `INDEX.md` — master index with domain pointers and usage mapping
- `qa-tools.md` — 30 entries: Playwright, Cypress, Selenium, k6, Detox, Appium + community repos
- `qa-methodology.md` — 22 entries: BDD/contract testing/accessibility/flakiness/ISTQB standards
- `languages.md` — 28 entries: TypeScript, Python, Java, C#, Kotlin, Ruby, Bash + GoF patterns
- `security-a11y-ai.md` — 20 entries: OWASP, ZAP, Nuclei, WCAG, axe-core, AI agent testing

### lang-refine / qa-refine / qa-methodology-refine
- Added catalog detection step — `_LS_AVAILABLE` detection runs before Phase 1a
- Phase 1a: catalog-first instruction — reads `learning-sources/*.md` before hardcoded fallbacks

---

## v1.11.0.0 — 2026-05-03 — BurpMCP authenticated testing, OFFAT security fuzzing, chaos mode wiring

### qa-security
- Phase 3.5: BurpMCP Authenticated Session Security Testing — retrieve captured Burp traffic, Claude identifies BOLA/IDOR/mass-assignment/SQLi/XSS/SSRF injection points, replays payloads with session tokens; Burp Collaborator support for out-of-band blind probes; `ATTACK_SUCCEEDED` = security finding (BL-021)
- Preamble: added `_BURP_AVAILABLE` detection (burp.jar scan + port 1337 health check)

### qa-api
- Phase 4c: OWASP OFFAT OpenAPI Security Fuzzing — opt-in (`QA_SECURITY=1`); OWASP API Top 10 attack classes (BOLA, mass assignment, SQLi, XSS, method bypass); high-severity findings block; OFFAT install hint when not found (BL-033)
- Preamble: added `_SEED_MODE` detection; chaos-mode warning in Phase 5 report when `QA_SEED_MODE=chaos` (BL-023)

### qa-web
- Preamble: added `_SEED_MODE` detection; chaos-mode warning in report when `QA_SEED_MODE=chaos` (BL-023)

---

## v1.10.0.0 — 2026-05-03 — Hardness routing, risk-weighted gaps, two-tier mutation, MutaHunter

### qa-team
- Phase 0.8: Hardness-Aware Routing — 0–7 complexity score (routes, auth, domains, LOC); simple (<3) → single qa-web smoke-only fast-path; complex (3–5) → full parallel fleet; very-complex (≥6) → full fleet + mandatory qa-audit + qa-explore (BL-012)
- Preamble: added `_ROUTE_COUNT`, `_HAS_AUTH`, `_DOMAIN_COUNT`, `_LOC` detection variables
- Phase 4 report: new "Routing" block — complexity tier, score breakdown, agent fleet used

### qa-audit
- Preamble: added `_STRYKER_AVAILABLE`, `_PITEST_AVAILABLE`, `_MUTMUT_AVAILABLE`, `_MUTAHUNTER_AVAILABLE`, `_DIFF_FILES`, `_DIFF_COUNT`, `_TEST_CMD`
- Phase 2.7: Risk-Weighted Coverage Gap Scoring — git log surfaces recently changed (+3) and fix-commit (+2) files; auth/payment path heuristic (+3); complexity heuristic (+2); covered discount (−5); Top 5 risk-ranked table drives Phase 3.5 fill order (BL-013)
- Phase 3.8: Two-Tier Mutation Testing — Tier 1 tool-based incremental (Stryker/Pitest/mutmut) scoped to diff files; Tier 2 Claude classifies survived mutants EQUIVALENT vs. GENUINE-GAP + generates killing assertions; warn <60%, BLOCK <40% adjusted score; skip via `QA_SKIP_MUTATION=1` (BL-034)
- Phase 3.9: MutaHunter LLM-native mutant generation — opt-in (`QA_MUTAHUNTER=1`); Haiku model; 50-mutant cap; scientific 3-turn debugging loop; few-shot from real bug commits (BL-035)

---

## v1.9.0.0 — 2026-05-03 — Five new skills: explore, security, seed, simulate, component

### qa-explore (new)
- Swarm exploratory testing: N parallel browser agents autonomously find 404s, JS errors, broken links (BL-008)
- Configurable via `QA_EXPLORE_AGENTS` (default: 3), `QA_EXPLORE_MAX_PAGES` (default: 20)
- Auto-detects seed routes from `pages/` and `app/` directories; sitemap.xml fallback

### qa-security (new)
- Mode A: OWASP ZAP DAST — spider + active scan + Claude OWASP/CWE triage (BL-020)
- Mode B: Lightweight curl probes — security headers, exposed files, CORS, JWT checks (always available)
- Nuclei template-based scanning as second pass when installed; stack-aware tag selection

### qa-seed (new)
- Schema-aware synthetic data: Prisma, SQL migrations, TypeORM, Django ORM, Drizzle (BL-022)
- FK-constraint-aware topological seeding; realistic distributions per column type
- Chaos mode (`QA_SEED_MODE=chaos`): null injection, boundary values, unicode edge cases, duplicate rows

### qa-simulate (new)
- UserSimulator generates multi-turn user journeys from feature descriptions (BL-026)
- RedTeam mode (`QA_REDTEAM=1`): adversarial inputs — SQL injection, XSS, auth bypass, race conditions
- Judge agent evaluates scenario correctness 0–1; scenarios cached as JSON for deterministic CI replay

### qa-component (new)
- Storybook test execution: interaction tests + a11y checks + Chromatic visual snapshots (BL-052)
- Prop boundary testing via fast-check: ts-morph extracts interfaces → Claude generates `fc.record()` arbitraries, 200 iterations (BL-053)
- Stryker mutation quality gate on changed components: surviving mutants classified EQUIVALENT/GENUINE-GAP; killing assertions generated for GENUINE-GAP (BL-054)

### qa-team
- Added qa-explore, qa-security, qa-seed, qa-component, qa-simulate to dispatch table
- Updated auto-detection rules for 5 new domains
- Updated aggregate loop: `for domain in web api mobile perf visual audit a11y heal explore security seed component simulate`

---

## v1.8.0.0 — 2026-05-03 — Multi-browser, API fuzzing, visual AI diff, perf Artillery, snapshot healing

### qa-web
- Multi-browser default: chromium + firefox + webkit in generated playwright.config.ts (BL-059)
- `QA_BROWSERS` env var to opt out of specific browsers (BL-062)
- Phase 2.6: Cross-browser locator audit — detect fragile CSS/XPath selectors, suggest getByRole/getByLabel/getByTestId rewrites (BL-060)
- Browser Matrix table in Phase 4 report
- Removed hardcoded `--project=chromium` from Phase 3 execution; config drives browser selection

### qa-api
- Phase 0.5: Spectral OpenAPI lint pre-flight — blocks on errors, surfaces warnings (BL-028)
- Phase 1.5: GraphQL schema diff via `@graphql-inspector/cli` — BREAKING/DANGEROUS/NON_BREAKING classification (BL-029)
- gRPC detection in Preamble + Phase 2b gRPC smoke tests via `grpcurl` (BL-030)
- Phase 4b: Schemathesis property-based fuzzing — 25 examples, all checks, stateful links (BL-027)

### qa-perf
- Artillery detection added to Preamble tool selection (BL-036)
- Phase 2.5: Artillery adaptive phase sequencing — smoke → baseline → soak with threshold gates (BL-036, BL-037)
- Phase 4.5: Pyroscope flamegraph diff → 3-bullet CPU hotspot insight when `PYROSCOPE_URL` set (BL-037)
- SLO Compliance table in Phase 4 report: parse k6 thresholds → Sloth YAML + error budget burn rate (BL-038)

### qa-visual
- Phase 1.5: BackstopJS config generation from Tailwind breakpoints + route discovery (BL-044)
- Phase 5.5: Three-layer AI diff pipeline — pixelmatch auto-pass (<0.1%) / auto-fail (>20%) + Claude Vision COSMETIC/FUNCTIONAL/CONTENT classification for 0.1–20% range (BL-042)

### qa-heal
- 7th failure classification: `snapshot-drift` — `pytest --inline-snapshot=fix` / `jest --updateSnapshot` repair (BL-065)
- Confidence score: +0.10 for snapshot-drift with ≤3 spec files changed (low-risk mechanical fix)

---

## v1.7.0.0 — 2026-05-03 — New skills: qa-heal + qa-a11y; CTRF output; coverage gap loop; flaky classifier

### New Skills
- `qa-heal` — Self-healing test repair: 6-type failure classification (broken-selector,
  stale-element, moved-element, assertion-drift, navigation-change, timing-issue),
  confidence-gated auto-commit/PR/issue routing (BL-004)
- `qa-a11y` — Accessibility audit: axe-core scan + POUR grouping + AI alt text generation (BL-018/019)
- Both skills added to `qa-team` auto-dispatch and `.claude/agents/`

### CI/CD Integration
- CTRF universal JSON output added to all 6 runner skills + qa-heal + qa-a11y + qa-team aggregation (BL-014)
- GitHub PR comment via `npx github-test-reporter` in qa-team (optional, requires gh CLI) (BL-015)
- `.github/workflows/qa-report.yml` for CI-native CTRF artifact reporting (BL-015)
- Persistent `qa-flaky-registry.json` updated after every qa-team run; flaky tests annotated (BL-016)
- Test impact analysis in qa-team Phase 0.5: diff-scoped fast-path when ≤5 test files affected (BL-017)

### qa-audit Enhancements
- Phase 2.5: Flaky test OD/ID classification via isolation run + registry lookup (BL-007)
- Phase 3.5: Coverage gap fill loop — run coverage, generate targeted tests, repeat ×3 (BL-006)

---

## v1.6.0.0 — 2026-05-03 — Architecture upgrade: subagents, hooks, DRY version check, memory

### Subagent definitions (`.claude/agents/`)
- Created `.claude/agents/qa-web.md`, `qa-api.md`, `qa-mobile.md`, `qa-perf.md`, `qa-visual.md`, `qa-audit.md`
- Each agent: `model: sonnet`, `memory: project`, `effort: high` (medium for `qa-visual`), inline safety hooks
- `bin/setup` updated to symlink agents to `~/.claude/agents/`

### Skill frontmatter additions (6 runner skills)
- `disable-model-invocation: true` — prevents accidental auto-triggering
- `model: sonnet` — makes model selection explicit
- `effort: high` (`medium` for `qa-visual`) — controls reasoning depth
- `hooks.PreToolUse` — blocks broad `rm -rf` commands via `bin/hooks/qa-pre-bash-safety.sh`
- `hooks.PostToolUse` — async `tsc --noEmit` after spec writes via `bin/hooks/qa-post-write-typecheck.sh`
- Added `disable-model-invocation: true` to `qa-team` frontmatter

### DRY version check
- Created `bin/qa-version-check-inline.sh`
- Replaced 45-line version check block in all 9 `.tmpl` files with 4-line `!bash` injection
- Saves ~405 lines of duplicate code across the repo

### Agent memory instructions
- All 6 runner skills now include `## Agent Memory` section
- Instructions to maintain `.claude/agent-memory/<domain>/MEMORY.md` across runs
- Accumulates: framework version, auth patterns, known flaky scenarios, base URL, infrastructure quirks

### New files
- `bin/hooks/qa-pre-bash-safety.sh` — blocks destructive `rm -rf` in QA agent context
- `bin/hooks/qa-post-write-typecheck.sh` — async TypeScript type-check after spec writes
- `bin/qa-version-check-inline.sh` — DRY version check helper for `!bash` injection
- `.claude/agents/qa-{web,api,mobile,perf,visual,audit}.md` — isolated subagent definitions
- `CLAUDE.md` — project contributor guide (architecture, build, version bumping, adding skills)

---

## v1.5.11.0 — 2026-05-03 — BL-001 CI grounding · BL-002 anti-sycophancy gate · BL-003 diagnose-then-fix (qa-web, qa-api, qa-mobile, qa-perf)

### BL-001 — CI Grounding (`qa-web`, `qa-api`)

Before generating new tests, run the existing test suite and capture its output. The generation phase uses this baseline to:
- Skip endpoints/pages that already have passing coverage
- Target failing tests with understanding of why they fail
- Tag pre-existing failures so Phase 5 diagnosis can distinguish regressions from known issues

- **`qa-web` Phase 1.5**: new `CI Grounding` phase — runs `playwright test`, `dotnet test`, or `cypress run` (branched on `_WEB_TOOL`); saves output to `$_TMP/qa-web-ci-ground.txt`; emits filtered pass/fail lines for generation context
- **`qa-api` Phase 2.5**: new `CI Grounding` phase — runs appropriate runner for `_API_TOOL` (playwright/java/python/csharp/ruby); saves output to `$_TMP/qa-api-ci-ground.txt`; skips gracefully when no existing specs found

### BL-002 — Anti-Sycophancy Quality Gate (`qa-web`, `qa-api`, `qa-mobile`)

After generating tests and before executing them, all generated test blocks must pass a 3-criteria quality gate. Tests that fail are rewritten (not skipped). The gate prevents hollow tests that assert nothing meaningful, duplicate passing tests, or copy-paste templates with wrong URLs.

- **`qa-web` Phase 2.5**: gate criteria: non-trivial assertion · real interaction coverage · failure sensitivity; bad/good TypeScript examples included
- **`qa-api` Phase 3.5**: gate criteria: non-trivial body assertion · correct method+path · auth coverage (authenticated + 401 unauthenticated variant)
- **`qa-mobile` Phase 3.5**: gate criteria: non-trivial assertion · real interaction (tap/input/swipe) · failure sensitivity; Detox/Maestro examples

### BL-003 — Diagnose-Then-Fix (`qa-web`, `qa-api`, `qa-mobile`, `qa-perf`)

When tests fail, the report requires a structured **Diagnosis** table before listing individual failures. The table forces the agent to articulate: what broke, what was expected, what happened, likely root cause, and whether the failure is pre-existing (cross-referenced against the CI grounding output) or a new regression.

- **`qa-web` Phase 4 report**: mandatory `## Diagnosis` table when `EXIT_CODE != 0`; cross-references `$_TMP/qa-web-ci-ground.txt`
- **`qa-api` Phase 5 report**: mandatory `## Diagnosis` table when `EXIT_CODE != 0`; cross-references `$_TMP/qa-api-ci-ground.txt`
- **`qa-mobile` Phase 5 report**: mandatory `## Diagnosis` table when `EXIT_CODE != 0`
- **`qa-perf` Phase 4 report**: mandatory `## Diagnosis` table when any threshold is violated; placed before `## Threshold Violations`

---

## v1.5.10.1 — 2026-04-28 — qa-api: add RestSharp as C# HTTP client option

- **`qa-api` preamble**: added `_CS_RESTSHARP` detection — greps `.csproj` files for RestSharp package reference; emits `CS_RESTSHARP: 1` when found, `CS_RESTSHARP: 0` otherwise
- **`qa-api` Phase 3 — C# reference pointer**: updated description from "HttpClient" to "RestSharp or HttpClient"; added routing rule — use RestSharp section when `CS_RESTSHARP=1`, HttpClient section otherwise; updated note to cross-reference both `CS_TEST_FW` and `CS_RESTSHARP`
- **`api-patterns-csharp.md`**: restructured file into two top-level sections (`## RestSharp Section` and `## HttpClient Section`); added full RestSharp v107+ `ApiClient` with typed generics (`GetAsync<T>` / `PostAsync<T>`) and untyped overloads; added RestSharp NUnit / MSTest / xUnit sub-sections with identical test coverage (happy path, 401, 404, 400, lifecycle DELETE); renamed existing HttpClient test sub-sections to `### HttpClient — NUnit/MSTest/xUnit`; header comment updated to include `http-clients: RestSharp, HttpClient`
- **`qa-refine` reference table**: updated C# API testing entry to "C# (RestSharp or HttpClient)"

---

## v1.5.10.0 — 2026-04-28 — multi-repo support (QA_EXTRA_PATHS) + ISTQB CTFL 4.0 terminology

### Multi-repo support (`QA_EXTRA_PATHS`) — all scanning skills

- **qa-audit, qa-web, qa-api, qa-mobile, qa-perf, qa-team**: added `QA_EXTRA_PATHS` multi-repo block to each skill's preamble — when the env var is set (space-separated absolute paths), the preamble counts test files in each extra repo and emits `EXTRA_REPO <name>: N files — <path>` lines
- **Post-preamble notes**: added "If `MULTI_REPO_PATHS` output appeared" instruction to all 6 skills — directs agents to include extra-repo files when sampling during subsequent phases; notes that language detection uses CWD and that sub-agents inherit `QA_EXTRA_PATHS` automatically via the environment
- **qa-team**: notes that sub-agents inherit the variable automatically so no manual forwarding is needed

### Language consistency — qa-audit

- **`_TARGET_LANG` detection**: added to preamble so recommendation code examples use the project's detected language (TypeScript, Java, Python, C#)
- **C# test file patterns**: `*Tests.cs`, `*Test.cs`, `*Spec.cs` added to `_ALL_TESTS` find patterns with `! -path "*/obj/*"` exclusion
- **C# framework detection**: added bash block to detect xUnit, NUnit, MSTest in `.csproj` files and emit `CS_TEST_FW: <framework>`
- **Recommendation template**: added `(use the project's detected TARGET_LANG for all code examples)` note

### ISTQB CTFL 4.0 terminology — qa-methodology-refine

- **Phase 1b base community sources**: added `WebSearch: '"ISTQB CTFL 4.0" "<TARGET_TOPIC>" terminology 2026'` to the base source list with explanatory note (ISTQB defines authoritative terms: "test case" vs "test", "test level" vs "test layer", etc.)
- **Phase 2 document structure**: added ISTQB CTFL 4.0 standardized terminology note listing key term mappings ("test case" not "test", "test level" not "test layer", "test basis" not "test source", "test suite", "test object", "test condition", "defect" not "bug") so generated guides stay consistent with industry certifications

---

## v1.5.9.9 — 2026-04-28 — lang-refine: update WebSearch queries from 2025 to 2026

- **lang-refine WebSearch queries**: all 11 occurrences of `2025` updated to `2026`

---

## v1.5.9.8 — 2026-04-28 — qa-methodology-refine: WebSearch-first sources, existing guide check, 2026 queries

- **Step 0 language detection**: TypeScript detection strengthened — now checks `tsconfig.json`, `@types/node`, `.ts`/`.tsx` files in addition to `typescript`/`ts-jest` in `package.json`
- **Phase 1a — check existing guide first**: added `ls qa-methodology/references/` step + instruction to read the existing `<TARGET_TOPIC>-guide.md` before fetching, so research extends prior work rather than duplicating it
- **Phase 1a — sources table**: replaced all old blog post URLs (martinfowler.com pre-2018, testing.googleblog.com/2016, satisfice.com PDF download, developsense.com/2009, xunitpatterns.com, ibm.com) with WebSearch queries; these URLs are unreliable and their content is already captured in the generated guide files; WebSearch naturally returns current, high-quality coverage of the same concepts
- **Phase 1a — active official docs preserved**: `cucumber.io/docs/bdd/`, `cucumber.io/docs/gherkin/reference/` (BDD), `docs.pact.io/` + consumer + provider (contract-testing), `www.deque.com/axe/axe-for-web/` + W3C WCAG quickref + axe-core GitHub (accessibility), `owasp.org/www-project-devsecops-guideline/` (shift-left) — these are actively maintained and worth fetching
- **Phase 1a — explanatory note**: added paragraph explaining the WebSearch-first rationale (old content already in guide files; WebSearch finds current articles vs fixed stale URL)
- **Phase 1b lang-refine fetch**: removed "For non-JS/TS languages" qualifier; applies to all languages
- **WebSearch queries**: all `2025` occurrences updated to `2026` (Phase 1a WebSearch table, Phase 1b base + per-topic queries, Phase 4b refinement gap table — 25 total occurrences)

---

## v1.5.9.7 — 2026-04-28 — qa-refine: full reference index, Selenium URL dedupe, 2026 queries, no JS bias

- **Step 0 language detection**: TypeScript detection strengthened — now checks for `tsconfig.json`, `@types/node`, and `.ts`/`.tsx` files in `src/` in addition to `typescript`/`ts-jest` in `package.json`
- **Step 0 exceptions**: k6 and Detox updated from "always JavaScript" to "always **JavaScript/TypeScript**" (TS supported via bundler; official docs use JS examples)
- **Phase 1a — Existing reference files table**: added comprehensive table listing all 22 reference files currently in the repo (Playwright TS + baseline + C#, Cypress, Selenium TS, k6 + baseline, JMeter, Locust, NBomber, Detox + baseline, Appium WDIO/Java/Python/C#, Maestro, API patterns TS/Java/Python/C#/Ruby); instructs agent to read the relevant file before fetching to extend prior work rather than duplicate it
- **Phase 1a — Playwright "See also"**: simplified to a short pointer; detail moved to reference files table
- **Phase 1a — Selenium URLs**: refactored from per-language table (which repeated the same 4 selenium.dev URLs for every language) to a shared "language-independent" block + a small language-specific additions table; TS/JS/C# now noted as needing no additional source beyond selenium.dev; added `See also` pointer to `selenium-patterns.md`
- **Phase 1b — lang-refine fetch**: removed "For non-JS/TS languages" qualifier; now applies to all languages; lists all 7 available lang-refine reference files explicitly
- **Phase 2 — target paths**: removed "TypeScript/JavaScript (the default)" framing; replaced with neutral note that base-name files are the TypeScript references and all other languages use a suffix
- **Phase 2 — target paths table**: added NBomber → `qa-perf/references/nbomber-patterns.md`
- **WebSearch queries**: all 15 occurrences of `2025` updated to `2026`

---

## v1.5.9.6 — 2026-04-28 — qa-audit: 4 new methodology checks + scoring/report updates

- **qa-audit preamble**: expanded `_RETRY_COUNT` grep to capture `.only`, `xdescribe`, `@Ignore`, `[Ignore]`, `[Skip]`, `pytest.mark.xfail`, `jest.retryTimes`, `retries: N`
- **Check 7 (CI test integration)**: added bash block to detect artifact-on-failure signals (`upload-artifact`, `store_artifacts`, `junit`, `screenshot`, `video`, `allure`); added "Artifacts on failure" checklist item; removed "Parallel test execution" bullet (moved to dedicated Check 11)
- **new Check 8 — Assertion quality**: greps for presence-only assertions (`notBeNull`, `assertNotNull`, `toBeDefined()`, `ShouldNotBeNull`, `assertIsNotNone`, etc.); flags tests that confirm an object exists but do not verify its content or behaviour
- **new Check 9 — Positive/negative test balance**: counts test names matching positive-path keywords vs negative-path keywords; flags suites where `_NEG_TESTS = 0` (only happy-path coverage) or extreme imbalance
- **new Check 10 — Retry / ignore / skip markers**: greps for `.skip`, `.only`, `xtest`, `@Ignore`, `[Ignore]`, `pytest.mark.skip/xfail`, `retries: N`, `flaky`; explains risk of each marker type; flags any committed `.only` as a definite bug
- **new Check 11 — Parallelization safety**: greps for hardcoded shared ports/DB names and for `--runInBand` / `maxWorkers=1` / `singleThread` config flags that suppress parallelism instead of fixing root causes; explicitly distinguished from Check 7's CI parallel-execution check
- **Phase 4 scoring table**: renamed "Naming Quality" → "Assertion & Naming Quality" (Checks 1 & 8); renamed "CI / Coverage" → "CI / Coverage & Reliability" (Checks 4, 6, 7 & 10); updated "Pyramid Balance" signal to include Check 9; updated "Test Isolation" signal to include Check 11
- **Phase 5 report template**: updated dimension score rows to surface new signals; renamed "Flakiness Risk Summary" → "Flakiness & Reliability Summary"; added weak assertion count and missing-negative-path verdict rows
- **skill description**: updated to enumerate all 11 checks

---

## v1.5.9.5 — 2026-04-28 — qa-perf: NBomber support, C# detection, blockquote reference format

- **qa-perf preamble**: added `_TARGET_LANG` detection; .NET base URL from `launchSettings.json`; `_NBOMBER` detection via `find . -name "*.csproj" | xargs grep -il "NBomber"`; C# existing perf file patterns (`*LoadTest*.cs`, `*PerfTest*.cs`); C# Controller route detection
- **qa-perf Tool Selection Gate**: `NBOMBER_PRESENT` counted alongside k6/JMeter/Locust; NBomber listed as option 2 in zero-detected case with recommendation note for `_TARGET_LANG=csharp`
- **qa-perf Phase 2**: converted from bullet/inline list to blockquote format (matching qa-web/qa-api/qa-mobile pattern); NBomber entry added with reference link and key patterns summary
- **new files** — `qa-perf/tools/`:
  - `nbomber.md` — load simulation types table, full auth+scenario script template, thresholds, DataFeed, execute block, result parsing, CI notes
- **new files** — `qa-perf/references/`:
  - `nbomber-patterns.md` — core principles (open vs closed model, one `HttpClient`, auth before scenario); all `LoadSimulation` variants; full multi-scenario script with auth + thresholds + report formats; `DataFeed` parameterised data; NUnit `[Explicit]` integration; cleanup-after-writes with `ConcurrentBag`; default SLA profiles table

---

## v1.5.9.4 — 2026-04-28 — Consistent blockquote reference format; qa-mobile multi-language Appium

- **qa-web Phase 2**: reference section converted from flat bullet list to blockquote format matching qa-mobile Phase 3 — each tool now has a bold heading, `> Reference: [title](path)` link, and `> Key patterns: a · b · c` summary
- **qa-api Phase 3**: "Load language patterns file" section converted to same blockquote format — one entry per language with link + key patterns summary; `CS_TEST_FW` focus note retained for C#
- **qa-mobile preamble**: added `_TARGET_LANG` detection (`typescript`, `java`, `python`, `csharp`, `ruby`) after Maestro detection block
- **qa-mobile Phase 3 Appium section**: split into per-language blockquote entries (TypeScript/WDIO, Java, Python, C#); TS example code retained; other languages redirect to new reference files
- **new files** — `qa-mobile/references/`:
  - `appium-patterns-java.md` — `AppiumTestBase` with JUnit 5, `AppiumBy.ACCESSIBILITY_ID` selectors, `WebDriverWait`, `@BeforeAll`/`@AfterAll` lifecycle
  - `appium-patterns-python.md` — pytest session-fixture driver, `AppiumBy.ACCESSIBILITY_ID`, `WebDriverWait`/`expected_conditions`, `autouse` app-reset fixture
  - `appium-patterns-csharp.md` — `AppiumTestBase` with `IOSDriver`/`AndroidDriver`, NUnit/MSTest/xUnit sections, `MobileBy.AccessibilityId`, `WebDriverWait`, `dotnet test` execute block

---

## v1.5.9.3 — 2026-04-28 — qa-api: C# support, ApiClient pattern, reference files, DELETE/cleanup rules

- **qa-api preamble**: `_CS_TEST_FW` detection (nunit/mstest/xunit); .NET base URL from `launchSettings.json` + `appsettings*.json`; `Controllers/*.cs` added to route file scan; all C# `find` calls exclude `*/obj/*`
- **qa-api Phase 1**: added C# Controller attribute grep (`[HttpGet]`, `[HttpPost]`, `[Route]` etc.) as Strategy 2b
- **qa-api Phase 3**: removed all inline language templates; Phase 3 now reads `qa-api/references/api-patterns-<_API_TOOL>.md`; prominent DELETE policy and cleanup obligations added before test generation
- **qa-api Important Rules**: replaced vague "idempotent tests" with explicit "shared ApiClient", "no bare DELETE tests", and "cleanup everything you create" rules
- **new files** — `qa-api/references/`:
  - `api-patterns-typescript.md` — `ApiClient` wrapping Playwright request context, cleanup via `afterAll`
  - `api-patterns-java.md` — `ApiClient` wrapping REST Assured, cleanup in `@AfterAll`
  - `api-patterns-python.md` — `ApiClient` wrapping `requests.Session`, cleanup via session-scoped `autouse` fixture
  - `api-patterns-csharp.md` — `ApiClient` wrapping `HttpClient` (single instance, `Anonymous()` helper); NUnit / MSTest / xUnit sections; `_created` list + teardown cleanup; lifecycle DELETE pattern
  - `api-patterns-ruby.md` — `ApiClient` wrapping Faraday, cleanup in `after(:all)`

---

## v1.5.9.2 — 2026-04-28 — C# support in qa-web (preamble, base URL, patterns)

- **qa-web preamble**: added `_PW_DOTNET` / `_SE_DOTNET` detection (grep `.csproj` for `Microsoft.Playwright` / `Selenium.WebDriver`); `_TARGET_LANG` variable (`typescript`, `csharp`, `java`, `python`); `_CS_TEST_FW` detection (`nunit`, `mstest`, `xunit`)
- **qa-web base URL**: extended detection chain — `launchSettings.json` (`applicationUrl`, semicolon-safe), then `appsettings.json`/`appsettings.Development.json` `BaseUrl` key, then JS/TS configs, then fallback `http://localhost:3000`
- **qa-web spec scan**: added `*Tests.cs`, `*Test.cs`, `*Spec.cs`; all C# `find` calls exclude `*/obj/*`
- **qa-web routes**: added `Controllers/*.cs`, `Pages/*.cs`, `Views/*.cs` + `.cshtml` to Phase 1 route discovery
- **qa-web Tool Gate**: treats `PLAYWRIGHT_DOTNET` / `SELENIUM_DOTNET` as Playwright/Selenium signals; documents that `_TARGET_LANG=csharp` drives Phase 2 pattern file selection and Phase 3 execute command
- **qa-web Phase 2**: patterns file selection now branches on `_TARGET_LANG` — C# projects read `playwright-patterns-csharp.md` and focus on `CS_TEST_FW` section
- **qa-web Phase 3**: added `dotnet test` execute block for `_TARGET_LANG=csharp`
- **new file**: `qa-web/references/playwright-patterns-csharp.md` — C# Playwright patterns covering NUnit / MSTest / xUnit base classes, POM with `IPage`/`ILocator`, `StorageStateAsync` auth, selector strategy, `Expect()` assertions, network mocking, `.runsettings` config, CI notes


---

## v1.5.9.1 — 2026-04-28 — C# support in qa-team project/web-tool detection

- **qa-team preamble**: detect `*.csproj`, `*.sln`, `global.json`, `Directory.Build.props`, `nuget.config` as project signals
- **qa-team web E2E detection**: grep `.csproj` files for `Microsoft.Playwright` → `playwright-dotnet` and `Selenium.WebDriver` → `selenium-dotnet`
- **qa-team test file scan**: add `*Tests.cs`, `*Test.cs`, `*Spec.cs` patterns; exclude `*/obj/*` from all C# `find` calls
- **qa-team Phase 0**: auto-detection rule for **qa-web** now mentions `.csproj` Playwright/Selenium signals
- **qa-team Phase 1**: added C# entry-point discovery (`*.csproj`, `Controllers/`, `Pages/`, `Views/`)

---

## v1.5.9.0 — 2026-04-28 — Extract version-check + history persistence (Impact 9 complete)

Closes the two **deferred** Impact 9 sub-tasks from PR #5. With this release, every
piece of "this code repeats across N skills" duplication identified in the original
audit is now collapsed into shared `bin/` scripts.

### Added — `bin/qa-team-precheck`

Centralizes the ~12-line version-check + prompt-cooldown logic that was previously
duplicated verbatim in all 10 `SKILL.md` files. Prints two stdout markers the agent
reads (`VERSION_STATUS` and `SKIP_UPDATE_PROMPT`); cooldown management is internal.
Exits 0 always — never blocks the wrapping skill.

Each `SKILL.md` version-check block went from 13 lines to 5:

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_QA_ROOT=$(dirname "$(readlink ~/.claude/skills/<skill> 2>/dev/null)" 2>/dev/null) || true
[ ! -f "${_QA_ROOT:-x}/VERSION" ] && \
  _QA_ROOT="$(readlink ~/.claude/skills/qa-agentic-team 2>/dev/null)" || true
bash "$_QA_ROOT/bin/qa-team-precheck"
```

The 4 surviving lines are the per-skill bootstrap (`$_TMP` and `$_QA_ROOT`) — those
remain inline because subsequent bash blocks in the same SKILL.md need them.

Prose updated: agents now read `SKIP_UPDATE_PROMPT` from stdout (was `_QA_SKIP_ASK`,
a shell variable) and write the cooldown to `$_TMP/.qa-update-asked` directly (was
`$_QA_ASK_COOLDOWN`, also a shell variable). Same observable behaviour.

### Added — `bin/qa-team-persist-history <skill-name>`

Centralizes the ~10-line "copy `$TMP/<skill>-{score.json,report.md}` to
`<repo>/.qa-team/<skill>-<commit>-<ts>.{json,md}` + update `<skill>-latest.json`
symlink" block that was duplicated as Phase Xc across the 6 sub-skills with sidecars
(`qa-audit`, `qa-api`, `qa-web`, `qa-visual`, `qa-perf`, `qa-mobile`).

The helper also handles the **delta-mode skip**: if `delta_mode.enabled == true` in
the sidecar JSON, it skips persistence entirely (delta runs are transient by design).
Previously this was inline in `qa-audit` only; centralizing means any sub-skill that
adopts delta mode in the future gets the correct behaviour for free.

Each Phase Xc block went from 11 lines to 1:

```bash
bash "$_QA_ROOT/bin/qa-team-persist-history" "<skill-name>"
```

### Net effect

- **2 new bin scripts**, ~120 LOC total
- **10 SKILL.md files** simplified (version-check)
- **6 SKILL.md files** further simplified (Phase Xc)
- **~8 lines saved per skill on the version-check** × 10 skills = ~80 lines
- **~10 lines saved per skill on Phase Xc** × 6 skills = ~60 lines
- **Single source of truth** for version-check, cooldown management, and history
  persistence (including delta-mode skip rules)

### Status of original 10-item audit plan

All 10 items are now fully shipped (PR #1 through #6):

| Impact | PR |
|--------|----|
| 1, 2, 3, 5, 7, 4, 8 | merged in #1 – #4 |
| 6 — Cost telemetry | merged in #5 |
| 9 — Extract test-file pattern | merged in #5 |
| 9 — Extract version-check | **#6** |
| 9 — Extract history persistence | **#6** |

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
