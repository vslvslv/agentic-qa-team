# Skills Overview

All 21 skills grouped by category. Each runs as a Claude Code slash command and/or as a sub-agent spawned by `/qa-team`.

---

## Testing agents

These skills actively run tests, generate specs, or probe your application.

### `/qa-team` — Orchestrator
Auto-detects your project stack, scores complexity (hardness 0–7), and spawns the right set of sub-agents in parallel. Aggregates all domain reports into a unified quality report with CTRF output.

- **Complexity routing**: score < 3 → smoke only; 3–5 → full suite; ≥ 6 → full suite + forced audit + explore
- **Test impact scoping**: runs `git diff --name-only origin/main` and maps changed files to affected tests for fast-path runs
- **Container isolation**: provisions isolated Docker containers (Testcontainers) per sub-agent when `test-env.yml` is present
- **Env**: `QA_FAST_MODE=1` (skip deep phases), `QA_DEEP_MODE=1` (force all agents), `QA_EXTRA_PATHS` (multi-repo)

---

### `/qa-web` — Web E2E
Discovers pages/routes, generates specs, executes, reports coverage with CI-grounding and anti-sycophancy quality gate.

- **Tools**: Playwright (default), Cypress, Selenium WebDriver — auto-detected
- **Spec generation**: Page Object Model, `getByRole`/`getByLabel`/`getByTestId` locators, multi-browser (Chromium + Firefox + WebKit)
- **NL mode**: reads `tests.nl.md` (plain-English test descriptions) and interprets them as Playwright actions at runtime
- **TestZeus Hercules**: when `.feature` (Gherkin) files detected, re-discovers selectors each run via DOM Distillation
- **aimock**: record/replay proxy for external API calls — offline deterministic CI
- **OTel injection**: `page.route()` injects `traceparent` header when `OTEL_EXPORTER_OTLP_ENDPOINT` is set
- **Env**: `WEB_URL`, `E2E_USER_EMAIL`, `E2E_USER_PASSWORD`, `QA_BROWSERS`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `AIMOCK_RECORD`

---

### `/qa-api` — API Testing
Language-driven REST/GraphQL/gRPC contract and integration testing pipeline.

- **Spec validation**: Spectral lint → Dredd contract drift → before any endpoint tests run
- **Test generation**: REST Assured (Java), pytest+requests (Python), HttpClient+NUnit (C#), RSpec+Faraday (Ruby), Playwright request context (JS/TS)
- **Fuzzing**: Schemathesis property-based fuzzing; RESTler stateful fuzzing (opt-in `QA_DEEP_FUZZ=1`)
- **Security fuzzing**: OWASP OFFAT from OpenAPI spec (opt-in `QA_SECURITY=1`)
- **Pact**: consumer contract verification when `*.pact.json` files found
- **Tracetest**: span assertions alongside HTTP tests (requires OTel backend)
- **Keploy**: eBPF record/replay — `QA_KEPLOY_RECORD=1` to record; auto-replays from stored fixtures
- **aimock**: record/replay proxy for external calls
- **GraphQL**: schema drift detection via graphql-inspector; introspection baseline diffing
- **gRPC**: service discovery via grpcurl + smoke tests per method
- **Env**: `API_URL`, `QA_DEEP_FUZZ`, `QA_SECURITY`, `QA_KEPLOY_RECORD`, `AIMOCK_RECORD`

---

### `/qa-mobile` — Mobile Testing
iOS/Android test generation and execution with VLM fallback layers.

- **Tools**: Detox (RN/Expo), Appium+WebDriverIO (native), Maestro (cross-platform YAML) — auto-detected
- **AndroidWorld templates**: 116 task templates across 20 apps as scenario seeds
- **Midscene.js**: VLM-based no-selector testing — `aiAction("tap the Login button")` when standard selectors fail
- **OmniParser**: CV parsing for Flutter canvas/games when accessibility tree returns 0 elements
- **Mobile-Agent Reflector**: automatic step recovery with max 2 retries; reflection rate tracked as flakiness signal
- **Env**: `DEVICE_ID`, `PLATFORM` (ios/android), `APP_PATH`, `OTEL_EXPORTER_OTLP_ENDPOINT`

---

### `/qa-perf` — Performance Testing
Load test generation, execution, and trend analysis.

- **Tools**: k6 (default), Artillery (via MCP), JMeter, Locust — auto-detected
- **SLO-as-Code**: auto-generates Sloth YAML from k6 thresholds; calculates error budget burn rate
- **Pyroscope**: flamegraph diff (idle vs load) → AI identifies top CPU hotspots
- **LitmusChaos**: concurrent chaos experiment + k6 load test (`QA_CHAOS=1`); ChaosEngine YAML auto-generated from thresholds
- **GoReplay**: production traffic capture → staging replay (`QA_GOREPLAY_CAPTURE=1` / `QA_REPLAY_MODE=1`)
- **Bencher**: pushes k6 results to trend store; Claude writes regression narrative from 30-run history
- **Env**: `API_URL`, `QA_CHAOS`, `QA_GOREPLAY_CAPTURE`, `QA_REPLAY_MODE`, `PYROSCOPE_URL`, `BENCHER_API_TOKEN`

---

### `/qa-visual` — Visual Regression
Three-layer visual pipeline with AI consensus and cost-efficient DOM metrics.

- **Layer 1**: Playwright `toHaveScreenshot()` at `[375, 768, 1440]` viewports + dark mode
- **Layer 2**: pixelmatch — auto-pass < 0.1% diff, auto-fail > 20%
- **Layer 3**: Claude vision classification for 0.1–20% range → PASS/WARN/FAIL with reasoning
- **DOM metric extraction**: `page.evaluate()` captures bounding boxes/colors/fonts — only escalates to full screenshot when metrics diverge (major token cost reduction)
- **AI visual consensus**: two-model agreement (Claude + Gemini) + arbiter on disagreement; verdict cache by SHA
- **BackstopJS**: reads existing `backstop.json`; auto-generates from Tailwind breakpoints
- **Lost Pixel**: self-hosted multi-browser fallback when cloud services unavailable
- **Env**: `VISUAL_BASELINE_DIR`, `VISUAL_DIFF_THRESHOLD`, `GEMINI_API_KEY` (for AI consensus)

---

### `/qa-a11y` — Accessibility Testing
WCAG 2.1 AA audit with AI-generated remediation.

- **Phase 1**: `@axe-core/playwright` — 35% of WCAG 2.1 AA issues, zero false positives
- **Phase 2**: Claude semantic layer — POUR-grouped impact statements + fix suggestions from page screenshot
- **Phase 3**: AI-generated alt text candidates for images with missing/empty alt attributes
- **Env**: `WEB_URL`, `A11Y_WCAG_LEVEL` (A/AA/AAA), `A11Y_PAGES` (comma-separated paths)

---

### `/qa-security` — Security Testing
DAST scanning with safe-mode default for staging environments.

- **Mode A** (full DAST): ZAP MCP add-on — spider → active scan (OWASP Top 10 policy) → Claude triage
- **Mode B** (lightweight): HTTP probes — missing CSP/X-Frame-Options, exposed `.env`/`.git`, JWT weaknesses
- **Nuclei**: template-based scan; `-ai` flag generates templates from natural language
- **BurpMCP** (deep-dive): authenticated session testing via Burp Suite MCP server (opt-in)
- **OFFAT**: OWASP API Top 10 security fuzzing from OpenAPI spec (`QA_SECURITY=1`)
- **Env**: `API_URL`, `WEB_URL`, `QA_SECURITY`, `ZAP_API_KEY`, `NUCLEI_TEMPLATES_PATH`

---

### `/qa-explore` — Exploratory Testing
Parallel freeform smoke testing — no test scripts required.

- Spawns N agents (configurable) to autonomously explore the running app
- Surfaces: 404s, JS console errors, broken links, unexpected redirects, accessibility violations
- Useful as a post-deploy smoke check or when no test scripts exist yet
- **Env**: `WEB_URL`, `QA_EXPLORE_AGENTS` (parallel agent count), `QA_EXPLORE_MAX_PAGES`

---

### `/qa-component` — Component Testing
Storybook + Vitest pipeline with mutation quality gate.

- Runs `storybook test --coverage` — interaction tests + accessibility + smoke from stories
- Runs `npx chromatic --only-changed` when `CHROMATIC_PROJECT_TOKEN` set
- Prop boundary testing via `fast-check` — generates TypeScript prop arbitraries, runs 200 combinations
- Stryker mutation gate on changed components — generates killing tests for surviving mutants
- **Env**: `CHROMATIC_PROJECT_TOKEN`, `WEB_URL`

---

### `/qa-simulate` — Scenario Simulation
AI-driven user journey simulation and red-team testing.

- `UserSimulatorAgent` generates contextually appropriate multi-turn interactions from a feature description
- `RedTeamAgent` runs adversarial multi-turn attacks (opt-in)
- `JudgeAgent` evaluates correctness at each turn
- Caches scenario fixtures for deterministic CI replay (no LLM cost after first run)
- **Env**: `WEB_URL`, `QA_REDTEAM=1` (enable adversarial mode), `QA_SCENARIO_CACHE_DIR`

---

### `/qa-seed` — Test Data Generation
Schema-aware synthetic test data with chaos mode.

- Reads Prisma schema, SQL DDL, or TypeORM migrations → generates relationship-aware test data
- Respects FK constraints, CHECK rules, statistical distributions (Faker for names, Pareto for amounts)
- Chaos mode (`--mode=chaos`): null injection, row duplication, date-format inconsistency
- Wraps in transaction — seeds at start, rollback at end (zero cleanup overhead)
- **Env**: `TEST_DATABASE_URL`, `QA_SEED_ROWS` (row count per table), `QA_SEED_MODE` (clean/chaos)

---

## Quality gate skills

### `/qa-audit` — Methodology Audit
Scores the existing test suite across 5 dimensions with risk-weighted coverage gap analysis.

- **Dimensions**: pyramid balance, test isolation, test data strategy, naming quality, CI/coverage
- **Coverage gap loop**: runs up to 3 iterations of coverage analysis + test generation until threshold met
- **Flaky test classification**: Order-Dependent vs Implementation-Dependent before patching
- **Mutation testing**: two-tier — Stryker/Pitest/mutmut (fast) + Claude analysis of survived mutants (LLM)
- **MutaHunter**: LLM-native mutant generation — semantically meaningful mutations resembling real bugs
- **Risk weighting**: recently changed files, fix-commit history, auth/payment paths → priority coverage score
- **Env**: `QA_AUDIT_COVERAGE_THRESHOLD` (default 80%), `QA_MUTATION_BUDGET`

---

## Maintenance skills

### `/qa-heal` — Self-Healing Tests
CI failure classification and repair pipeline with confidence-gated routing.

- **6-type taxonomy**: broken-selector, stale-element, moved-element, assertion-drift, navigation-change, timing-issue
- **Repair strategy dispatch**: DOM diff for selectors; inline-snapshot fix; Keploy re-record for API schema changes
- **Confidence gate**: auto-commit ≥ 0.87 · review PR 0.62–0.87 · GitHub issue < 0.62
- **Test impact scoping**: uses `git diff` to heal only tests impacted by changed files (bounds cost)
- **Env**: `GITHUB_TOKEN`, `CI_FAILURE_LOG` (path to CI output), `QA_HEAL_CONFIDENCE_THRESHOLD`

---

### `/qa-observability` — Failure RCA
HolmesGPT-style root cause analysis from distributed traces and logs.

- Fetches OTel spans from Jaeger or Tempo; queries Loki logs in ±30s window around failure timestamp
- Synthesizes `FAILURE_REASON` block with HIGH/MEDIUM/LOW confidence
- Only activates when observability stack configured
- Appends to test report; writes CTRF JSON
- **Env**: `JAEGER_URL`, `TEMPO_URL`, `LOKI_URL`, `FAILING_TEST_NAME`, `TRACE_ID`, `FAILURE_TIMESTAMP`, `FAILING_REPORT_PATH`

---

### `/qa-meta-eval` — Adversarial Eval
Red-teaming harness that turns the QA system inward.

- Runs 8 adversarial scenarios × UserSimulatorAgent + JudgeAgent
- Judges: output not empty, real assertions, correct failure classification, graceful degradation, no fabricated results
- Per-skill pass rate report; flags skills below 80%
- **Env**: `QA_META_TARGET` (scope to one skill, e.g. `qa-heal`)

---

## Planning / management skills

### `/qa-manager` — Requirements to Tests Bridge
Two modes for connecting requirements to Playwright specs.

- **Mode A (Epic → Playwright)**: JIRA Epic → Features → User Stories → Test Plan → Playwright skeletons; versioned JSON artifacts at each stage; AskUserQuestion confirmation gates; traceability matrix
- **Mode B (Figma → TCMS)**: parse Figma URLs from JIRA sprint tickets → Claude vision analysis → structured test cases → push to TestRail / Xray
- Both modes degrade gracefully when JIRA/Figma/TCMS unavailable (manual-input fallback)
- **Env**: `JIRA_URL`, `JIRA_TOKEN`, `JIRA_EPIC_ID`, `FIGMA_TOKEN`, `TESTRAIL_URL`/`XRAY_URL`, `TEST_SPECS_DIR`

---

## Knowledge refinement skills

These skills research the web and update the reference guides consumed by the testing agents. Run them periodically to keep best-practice guides current.

| Skill | Updates | Sources |
|-------|---------|---------|
| `/qa-refine` | `qa-web/references/`, `qa-mobile/references/`, `qa-perf/references/` | Official docs + GitHub top repos |
| `/qa-methodology-refine` | `qa-methodology/references/` | ISTQB, research papers, OWASP, W3C |
| `/lang-refine` | `lang-refine/references/` | Language docs, style guides, design pattern repos |
| `/learning-sources-refinement` | `learning-sources/` catalog | Searches for new official docs, GitHub repos, blogs across 4 domains |
