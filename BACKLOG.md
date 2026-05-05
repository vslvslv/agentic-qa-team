# qa-agentic-team — Enhancement Backlog

> Research-driven backlog of ideas from similar repositories and AI testing tools.
> Last updated: 2026-05-05 (round 4 research added — 33 new items: AI/LLM testing, security gates, property-based, reporting)

---

## Similar Repositories

| Repo | Stars | Description |
|---|---|---|
| [proffesor-for-testing/agentic-qe](https://github.com/proffesor-for-testing/agentic-qe) | 335 | 60+ agents across 13 QA domains coordinated by a "Queen Coordinator". Persistent cross-session pattern memory, anti-sycophancy quality gate, ML-powered flaky test detection, risk-weighted coverage gap analysis. |
| [browser-use/vibetest-use](https://github.com/browser-use/vibetest-use) | 790 | MCP server that spins up N parallel Browser-Use AI agents to autonomously explore a website for bugs, broken links, and accessibility issues — no scripted selectors needed. |
| [testsigmahq/testsigma](https://github.com/testsigmahq/testsigma) | 1,200+ | Production-grade GenAI platform with 5 distinct agent roles: Generator / Runner / Analyzer / Healer / Optimizer. Self-healing selectors run continuously. |
| [Axolotl-QA/Axolotl](https://github.com/Axolotl-QA/Axolotl) | 213 | VS Code extension that runs real CI scripts first (CI grounding), then generates tests targeting changed code paths (diff-targeted). Hands fix instructions to Claude/Cursor rather than fixing itself. |
| [final-run/finalrun-agent](https://github.com/final-run/finalrun-agent) | 253 | Mobile QA (iOS/Android) via YAML natural-language specs. AI agent drives the device; outputs video recordings + device logs. BYOK multi-model support. |
| [Agent-Field/SWE-AF](https://github.com/Agent-Field/SWE-AF) | 742 | Autonomous SWE fleet (PM / architect / coder / reviewer / tester). Hardness-aware routing scales agent depth by task complexity. Typed/severity-rated technical debt as output artifact. |
| [modal-labs/devlooper](https://github.com/modal-labs/devlooper) | 468 | Program synthesis loop: write → run tests in sandbox → diagnose (explain what broke) → fix → repeat. Explicit diagnose-then-fix two-stage reasoning improves fix accuracy. |
| [NihadMemmedli/quorvex_ai](https://github.com/NihadMemmedli/quorvex_ai) | — | 4-stage AI pipeline (Plan → Generate → Validate → Heal) for Playwright TypeScript. Uses Claude Sonnet + LangGraph for up to 17 healing iterations. Generates stable code once rather than calling LLM every run. |
| [bug0inc/passmark](https://github.com/bug0inc/passmark) | 690 | Multi-model visual consensus (Claude + Gemini + arbiter). Redis-backed step cache. CUA mode: screenshot → AI judge "did this change matter?" — no DOM selectors. |
| [Codium-ai/cover-agent](https://github.com/Codium-ai/cover-agent) | — | Iterative coverage gap filler: runs tests, parses coverage, prompts LLM to generate tests for uncovered lines, repeats until threshold. Supports 100+ LLMs via LiteLLM. |
| [Intelligent-CAT-Lab/FlakyDoctor](https://github.com/Intelligent-CAT-Lab/FlakyDoctor) | — | Neurosymbolic flaky test repair. Classifies flakiness type (Order-Dependent vs. Implementation-Dependent) before LLM patching. 19 patches accepted into Apache/Dropwizard. ISSTA 2024. |
| [antiwork/shortest](https://github.com/antiwork/shortest) | — | Tests written as plain English strings, interpreted by Claude at runtime into Playwright interactions. Supports 2FA, email validation via Mailosaur, headless CI. |
| [langwatch/scenario](https://github.com/langwatch/scenario) | 869 | Agentic red-teaming framework: AI "user" agent adversarially probes your agent under test; third "judge" agent evaluates correctness. UserSimulatorAgent, RedTeamAgent, caching. Python/TypeScript/Go. |
| [ctrf-io/ctrf](https://github.com/ctrf-io/ctrf) + [ai-test-reporter](https://github.com/ctrf-io/ai-test-reporter) | — | CTRF open JSON standard for test results. Ecosystem includes GitHub PR reporter, AI failure summarizer (Claude/GPT/Gemini), Slack/Teams notifiers. Adapters for 15+ frameworks. |
| [web-DnA/navable-web-accessibility-mcp](https://github.com/web-DnA/navable-web-accessibility-mcp) | — | Claude Code / MCP integration for a11y: axe-core + Pa11y scan → prioritized fix plan JSON → fix status tracking. Built-in WCAG-to-EN 301 549 mappings. |
| [zaproxy/zaproxy](https://github.com/zaproxy/zaproxy) | 28k+ | OWASP ZAP with official MCP add-on (April 2026): spider, active scan, alert retrieval all via MCP tool calls. Production-grade DAST scanner. |
| [projectdiscovery/nuclei](https://github.com/projectdiscovery/nuclei) | 28k+ | Template-based vulnerability scanner. `-ai` flag generates YAML templates from natural language prompts and immediately executes them. 9000+ community templates. |
| [swgee/BurpMCP](https://github.com/swgee/BurpMCP) | 46 | Burp Suite extension exposing MCP server: retrieve captured requests, analyze for vulnerabilities, craft payloads, replay — with session tokens for authenticated testing. |
| [CopilotKit/aimock](https://github.com/CopilotKit/aimock) | 570 | Zero-dependency mock server intercepting 11 LLM providers + MCP tools + vector DBs. Record & Replay mode captures real API traffic as fixtures for offline/deterministic CI. |
| [hyangminj/ddl2data](https://github.com/hyangminj/ddl2data) | — | SQL DDL → relationship-aware synthetic test data. Respects FK constraints, CHECK rules, statistical distributions. Writes directly to DB via SQLAlchemy. |
| [SwissLife-OSS/squadron](https://github.com/SwissLife-OSS/squadron) | — | Resource-based test environment injection. Declares required services (PostgreSQL, Redis, Kafka) as typed fixtures; provisions isolated Docker containers per test class for true parallel isolation. |
| [gourav-shokeen/chaoslake](https://github.com/gourav-shokeen/chaoslake) | — | Generates chaos test data: null injection, row duplication, date-format inconsistency, concept drift. Polars/DuckDB engines, fully reproducible via seed. |

---

## Backlog Items

Items are grouped by skill target and tagged with effort: `[S]` small · `[M]` medium · `[L]` large.

---

### 🔴 P1 — High Impact, Low Effort

#### BL-001 — CI Grounding Before Test Generation `[S]` ✅ **Implemented v1.5.11.0**
**Source:** [Axolotl-QA/Axolotl](https://github.com/Axolotl-QA/Axolotl)
**Target skills:** `qa-web`, `qa-api`
**Description:**
Before generating new test specs, run the project's real test suite (lint, typecheck, existing tests) and inject the actual failure output into the generation prompt context. Currently skills start cold with no knowledge of existing failures, which means generated tests can duplicate passing scenarios instead of targeting real breakage.
**Implementation notes:**
- Add a "CI grounding" step at the start of Phase 2 in `qa-web` and `qa-api`
- Run: `npm test 2>&1 | tail -50` (or equivalent) and capture to `$_TMP/qa-ci-ground.txt`
- Inject summary into the sub-agent prompt: "Current CI failures: <output>"
- Only generate tests targeting failing or uncovered paths

---

#### BL-002 — Anti-Sycophancy Quality Gate `[S]` ✅ **Implemented v1.5.11.0**
**Source:** [proffesor-for-testing/agentic-qe](https://github.com/proffesor-for-testing/agentic-qe)
**Target skills:** `qa-web`, `qa-api`, `qa-mobile`
**Description:**
After generating test specs, a validation pass scores each test for quality. Rejects hollow tests (no meaningful assertions, trivial `expect(true).toBe(true)`, tests that always pass regardless of app state). This directly tackles the "LLMs generate confident but useless tests" failure mode.
**Implementation notes:**
- Add a Phase 2.5 "spec review" step after generation
- For each generated test block, verify: (a) has at least one non-trivial assertion, (b) covers a real user interaction (not just page load), (c) would actually fail if the feature broke
- Flag and optionally rewrite tests that fail the gate before execution

---

#### BL-003 — Diagnose-Then-Fix Two-Stage Failure Reporting `[S]` ✅ **Implemented v1.5.11.0**
**Source:** [modal-labs/devlooper](https://github.com/modal-labs/devlooper)
**Target skills:** `qa-web`, `qa-api`, `qa-mobile`, `qa-perf`
**Description:**
When tests fail, require the agent to write a diagnosis paragraph explaining *why* the test failed (root cause, affected component, reproduction steps) before proposing any fix. Chain-of-thought research shows this two-step improves fix accuracy vs. directly patching from test output.
**Implementation notes:**
- Modify Phase 4 report generation: when `EXIT_CODE != 0`, add a "Diagnosis" section above the "Failures" section
- Diagnosis must answer: what feature broke, what the test expected, what it got, likely cause
- The existing `/investigate` skill handles deep repair; this is a lighter triage step within the report itself

---

### 🟡 P2 — High Impact, Medium Effort

#### BL-004 — `qa-heal` Self-Healing Locators Skill `[M]` ✅ **Implemented v1.7.0.0**
**Source:** [NihadMemmedli/quorvex_ai](https://github.com/NihadMemmedli/quorvex_ai), [testsigmahq/testsigma](https://github.com/testsigmahq/testsigma)
**Target skills:** New `qa-heal` skill
**Description:**
A dedicated healing skill: reads a CI failure log, identifies broken selectors, rewrites them against the live DOM using a Plan → Diagnose → Rewrite → Validate loop (up to N iterations), then opens a PR with the fixes.
**Implementation notes:**
- Input: CI output file or pasted failure log
- Phase 1: extract broken selector strings from failure messages
- Phase 2: load the page at the relevant URL, read the live DOM
- Phase 3: propose replacement using stable selector hierarchy (role > testid > label > aria)
- Phase 4: validate by re-running the specific failing test
- Phase 5: commit fix and open PR (or print diff if no git access)
- Reference: Quorvex 4-stage pattern; LangGraph not required — the loop can be a simple `while` construct in the skill instructions

---

#### BL-005 — Natural Language Test Cases → Playwright Execution `[M]` ✅ **Implemented v1.14.0.0** (qa-web NL mode via BL-049; TCMS bridge pending qa-manager) ✅ **Implemented v1.14.0.0** (qa-web NL mode; TCMS bridge pending qa-manager)
**Source:** [antiwork/shortest](https://github.com/antiwork/shortest)
**Target skills:** `qa-web`, `qa-manager` (TCMS bridge)
**Description:**
Bridge the gap between text test cases (as written in TCMS or by `/qa-manager`) and automated Playwright execution. Plain-English test descriptions are interpreted by Claude at runtime into Playwright actions — no selector code maintained by hand.
**Implementation notes:**
- `qa-web` gains a "natural language mode": instead of reading existing `.spec.ts` files, it reads a `tests.nl.md` file of plain-English test cases
- Each case: `"Login as admin, navigate to Users, verify the user count badge updates after adding a user"`
- Runtime: Claude interprets each case → emits Playwright steps → executes → reports pass/fail
- This is how `/qa-manager` test cases could bypass the spec-authoring step entirely
- Reference: [antiwork/shortest](https://github.com/antiwork/shortest) for integration or inspiration

---

#### BL-006 — Coverage Gap Loop in `qa-audit` `[M]` ✅ **Implemented v1.7.0.0**
**Source:** [Codium-ai/cover-agent](https://github.com/Codium-ai/cover-agent)
**Target skills:** `qa-audit`
**Description:**
`qa-audit` currently scores test pyramid balance and recommends coverage improvements. Extend it to actually close the gap: run coverage analysis, identify untested modules/lines, generate targeted tests, re-run coverage, repeat until a configurable threshold is met or N iterations exhausted.
**Implementation notes:**
- After the existing audit scoring, add Phase 3: "Gap Fill Loop"
- Run: `npx jest --coverage --coverageReporters=json 2>/dev/null` (or equivalent)
- Parse `coverage-summary.json` to find files below threshold (default: 80% statements)
- For each under-threshold file: read source, generate unit/integration tests, write spec file
- Re-run coverage; repeat up to 3 iterations
- Final report includes: before/after coverage table, files improved, tests generated
- Reference: [Codium-ai/cover-agent](https://github.com/Codium-ai/cover-agent) — can be used directly or as pattern

---

#### BL-007 — Flaky Test Classification + Repair `[M]` ✅ **Implemented v1.7.0.0**
**Source:** [Intelligent-CAT-Lab/FlakyDoctor](https://github.com/Intelligent-CAT-Lab/FlakyDoctor) (ISSTA 2024)
**Target skills:** `qa-web`, `qa-api`, new `qa-heal` (see BL-004)
**Description:**
Before attempting to fix a flaky test, classify its failure mode: Order-Dependent (test passes in isolation, fails in suite) vs. Implementation-Dependent (non-deterministic behavior in the test or app). Different root causes require different fixes; unclassified patching produces random results.
**Implementation notes:**
- Detection: track tests with >1 result status across CI runs (requires CI history or local re-runs)
- Classification heuristic: run test in isolation → if passes, Order-Dependent; if still flaky, Implementation-Dependent
- OD fix: add setup/teardown to reset shared state; find and break the dependency chain
- ID fix: add explicit waits, mock non-deterministic calls, fix race conditions
- Reference: [FlakyDoctor ISSTA 2024 paper](https://github.com/Intelligent-CAT-Lab/FlakyDoctor) for classification taxonomy

---

### 🟢 P3 — Medium Impact, Medium-Large Effort

#### BL-008 — `qa-explore` Swarm Exploratory Testing Skill `[M]` ✅ **Implemented v1.9.0.0**
**Source:** [browser-use/vibetest-use](https://github.com/browser-use/vibetest-use)
**Target skills:** New `qa-explore` skill
**Description:**
A post-deploy smoke testing skill: spawn N parallel agents to freeform-explore the running app, surfacing 404s, JS console errors, broken links, unexpected redirects, and accessibility violations — no test script required. Configurable agent count.
**Implementation notes:**
- Uses gstack/Browser-Use headless browser agents
- Each agent gets: base URL, max pages to visit, list of seeds (known routes)
- Agents explore autonomously: click links, submit forms with dummy data, navigate menus
- Aggregate: collect all console errors, network 400/500s, broken hrefs
- Report: unique errors by type, pages not reachable, JS exceptions
- Reference: [vibetest-use](https://github.com/browser-use/vibetest-use) — can integrate as MCP tool call

---

#### BL-009 — AI Visual Consensus (Multi-Model) `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [bug0inc/passmark](https://github.com/bug0inc/passmark)
**Target skills:** `qa-visual`
**Description:**
Augment pixel-diff visual regression with an AI judge: after detecting a visual diff, pass the before/after screenshots to two models (e.g., Claude + Gemini) and ask "is this a meaningful regression or noise?". A third model resolves disagreements. Dramatically reduces false positives.
**Implementation notes:**
- Current `qa-visual` flow: screenshot → pixel diff → report
- New flow: screenshot → pixel diff → (if diff found) AI judge 1 + AI judge 2 → arbiter if disagreement → final verdict
- Judge prompt: "Here are before/after screenshots of <page>. Is there a meaningful visual regression, or is this noise (dynamic content, font rendering, timestamp)? Answer YES/NO with reason."
- Cache verdicts (Redis or file-based) to avoid re-judging identical diffs
- Reference: [bug0inc/passmark](https://github.com/bug0inc/passmark) for consensus pattern

---

#### BL-010 — OpenAPI Contract Testing in `qa-api` `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [PactFlow Drift + AI Beta](https://pactflow.io/blog/)
**Target skills:** `qa-api`
**Description:**
Add a contract testing layer: use the project's OpenAPI spec as the baseline, generate Pact consumer contracts from it, and verify the running API matches its spec on every QA run. Flags schema drift before integration tests run.
**Implementation notes:**
- Detect `openapi.yaml` / `swagger.json` in project root (already done in `qa-team` preamble)
- Phase 0.5: generate consumer-driven Pact tests from the spec (or use Dredd for simpler spec validation)
- Execute: `npx @dredd/dredd openapi.yaml http://localhost:$PORT`
- Report: endpoints passing spec, endpoints with schema drift, missing endpoints
- Reference: [PactFlow AI](https://pactflow.io) for Pact generation; [Dredd](https://github.com/apiaryio/dredd) as a simpler zero-config alternative

---

#### BL-011 — Meta-QA: Agentic Red-Teaming of QA Skills `[L]` ✅ **Implemented v1.15.0.0**
**Source:** [langwatch/scenario](https://github.com/langwatch/scenario)
**Target skills:** `qa-refine`, `qa-methodology-refine`
**Description:**
Turn the QA system inward: write adversarial test scenarios that simulate a developer invoking `/qa`, `/qa-web`, `/qa-manager` with edge-case inputs and verify the skills produce correct, non-hollow output. An AI "user" agent drives the skill under test; a "judge" agent evaluates the output quality at each turn.
**Implementation notes:**
- Build a `qa-refine-workspace/meta-evals/` directory with scenario definitions
- Each scenario: input context (project type, available files, running services), expected skill behavior, judge criteria
- Run via `langwatch/scenario` or a custom eval harness (already have `qa-refine-workspace/evals.json`)
- This is the natural next maturity step after the existing `qa-refine` + nightly eval loop
- Reference: [langwatch/scenario](https://github.com/langwatch/scenario)

---

#### BL-012 — Hardness-Aware Routing in `qa-team` Orchestrator `[M]` ✅ **Implemented v1.10.0.0**
**Source:** [Agent-Field/SWE-AF](https://github.com/Agent-Field/SWE-AF)
**Target skills:** `qa-team`
**Description:**
The current `qa-team` orchestrator always spawns the same set of sub-agents regardless of project complexity. Add a hardness classifier: small projects (few routes, no auth, no API) get a fast-path (single agent, lighter prompts); complex projects (auth, multi-role, microservices, mobile) get the full parallel fleet.
**Implementation notes:**
- After Phase 0 scope selection, score project complexity: count of routes, presence of auth, number of domains detected, LOC
- Simple (score < 3): run single `qa-web` with `--fast` flag (no POM, no auth setup, just smoke tests)
- Complex (score >= 3): current full parallel flow
- Very complex (score >= 6): add explicit `qa-audit` + `qa-explore` as additional agents
- This reduces cost and noise for simple projects while maintaining depth for complex ones

---

#### BL-013 — Risk-Weighted Coverage Gap Analysis `[M]` ✅ **Implemented v1.10.0.0**
**Source:** [proffesor-for-testing/agentic-qe](https://github.com/proffesor-for-testing/agentic-qe)
**Target skills:** `qa-audit`
**Description:**
Current coverage analysis treats all untested code equally. Risk-weight it instead: recently changed files (from `git log`), files with high cyclomatic complexity, files with past bug history (from `git log --grep="fix"`), and critical business paths (auth, payments, user data) get higher priority coverage scores.
**Implementation notes:**
- Phase 1 addition: run `git log --since="30 days ago" --name-only` to get recently changed files
- Score each file: changed_recently (+3) · has_fix_commits (+2) · auth/payment path (+3) · high complexity (+2) · already covered (-5)
- Sort coverage gaps by score descending
- Report: "Top 5 highest-risk untested areas" replaces flat file list
- Feeds naturally into BL-006 (coverage gap loop) to prioritize which gaps to close first

---

---

### 📊 CI/CD Integration & Reporting

#### BL-014 — CTRF as Universal Output Format `[S]` ✅ **Implemented v1.7.0.0**
**Source:** [ctrf-io/ctrf](https://github.com/ctrf-io/ctrf), [ctrf.io](https://ctrf.io)
**Target skills:** All skills (qa-web, qa-api, qa-mobile, qa-perf, qa-visual, qa-audit)
**Description:**
CTRF (Common Test Results Format) is a minimal open JSON standard with adapters for Playwright, Jest, Cypress, Pytest, Postman, and ~15 other frameworks. Adopting it as the internal wire format across all skills unlocks free interoperability with the entire ctrf-io toolchain: PR comments, AI failure summaries, Slack/Teams notifications, Jira integration — without writing any integration code.
**Implementation notes:**
- Add a CTRF serialization step at the end of each skill's Phase 4 (report generation)
- Write `$_TMP/qa-<domain>-ctrf.json` alongside the existing markdown report
- `qa-team` aggregates per-domain CTRF files into a single merged report
- All downstream tooling (BL-015, BL-016) consumes this format

---

#### BL-015 — GitHub PR Comments + AI Failure Summaries `[S]` ✅ **Implemented v1.7.0.0**
**Source:** [ctrf-io/github-test-reporter](https://github.com/ctrf-io/github-test-reporter), [ctrf-io/ai-test-reporter](https://github.com/ctrf-io/ai-test-reporter), [daun/playwright-report-summary](https://github.com/daun/playwright-report-summary)
**Target skills:** CI workflow (`.github/workflows/`)
**Description:**
Two GitHub Actions that consume CTRF output and post rich PR comments: `github-test-reporter` publishes job summaries, PR comments with pass/fail tables, inline code annotations, and duration trends. `ai-test-reporter` calls an LLM (Claude, GPT-4, Gemini) to generate per-failure root-cause explanations before posting. Comments are auto-updated (not duplicated) on re-runs.
**Implementation notes:**
- Add a `.github/workflows/qa-report.yml` that fires after any CI test step
- Step 1: `ctrf-io/github-test-reporter` for structured pass/fail table in PR comment
- Step 2 (optional): `ctrf-io/ai-test-reporter` with Claude model for failure explanations
- Alternative for Playwright-only: `daun/playwright-report-summary` — simpler, zero AI, includes re-run commands per failing test
- Prerequisite: BL-014 (CTRF output format)

---

#### BL-016 — Persistent Flaky Test Registry `[S]` ✅ **Implemented v1.7.0.0**
**Source:** [Trunk Flaky Tests](https://trunk.io/flaky-tests), [BuildPulse](https://buildpulse.io)
**Target skills:** `qa-manager`, `qa-team`
**Description:**
Maintain a `flaky-tests.json` file (committed to the repo or stored as a GitHub Actions artifact) that accumulates pass/fail history per test across runs. The skill reads this registry at start and flags known-flaky test failures as warnings rather than blockers. Changes human response from "test failed" to "test failed but has a 30% flake rate on unchanged code."
**Implementation notes:**
- Structure: `{ "test-id": { "title": "...", "results": ["pass","fail","pass",...], "flakeRate": 0.3 } }`
- After each run, update entries for all tests in the CTRF output
- Tests with `flakeRate > 0.2` get flagged as `[FLAKY]` in the report rather than `[FAILED]`
- The `qa-team` orchestrator uses this to decide whether a failure should block the overall status
- File path: `qa-flaky-registry.json` at repo root (gitignored or committed, user's choice)

---

#### BL-017 — Test Impact Analysis (Diff-Based Test Scoping) `[S]` ✅ **Implemented v1.7.0.0**
**Source:** [CloudBees Smart Tests](https://www.cloudbees.com/capabilities/cloudbees-smart-tests), [Axolotl-QA/Axolotl](https://github.com/Axolotl-QA/Axolotl)
**Target skills:** `qa-team`, `qa-manager`
**Description:**
Before running a full test suite, call `git diff --name-only origin/main` to get changed files. Map changed paths to related test files using naming conventions (e.g., `src/auth/login.ts` → `e2e/auth.spec.ts`, `tests/login.test.ts`). Run impact-matched tests first in a fast-path; run full suite only when no match found or when explicitly requested.
**Implementation notes:**
- Add to `qa-team` Phase 0: run `git diff --name-only origin/main` → parse changed files
- Build a path-map heuristic: source file stem → test file pattern
- If changed files map to ≤5 test files: run only those (fast-path, ~2 min)
- If changed files map to >5 or include config/infra files: run full suite
- Report which scoping was applied and why
- Optionally: use Launchable/Smart Tests ML model for better accuracy on large repos

---

### ♿ New Skill: `qa-a11y` (Accessibility Testing)

#### BL-018 — `qa-a11y` Skill: Automated Accessibility Audit `[M]` ✅ **Implemented v1.7.0.0**
**Source:** [web-DnA/navable-web-accessibility-mcp](https://github.com/web-DnA/navable-web-accessibility-mcp), [dequelabs/axe-core-npm](https://github.com/dequelabs/axe-core-npm), [Farhod75/ai-a11y-testing](https://github.com/Farhod75/ai-a11y-testing)
**Target skills:** New `qa-a11y` skill
**Description:**
A three-phase accessibility audit skill: (1) rule-based scan via `@axe-core/playwright` (zero false positives, covers ~35% of WCAG 2.1 AA issues), (2) Claude semantic layer — feed axe JSON + page screenshot to Claude for POUR-grouped impact statements and fix suggestions, (3) structured report with WCAG SC references, severity, selector, and fix confidence score.
**Implementation notes:**
- Phase 1: `npx playwright test --reporter=json` with axe injected via `@axe-core/playwright`
- Phase 2: Claude prompt: "Given these axe violations and this screenshot, group by WCAG principle (POUR), describe user impact for each, and suggest a code-level fix."
- Domain context: use `qa-methodology/references/accessibility-guide.md` as system prompt context
- Phase 3: Report format — WCAG SC, element, impact level (critical/serious/moderate/minor), suggested fix, confidence
- Optional: integrate Navable MCP if available (`claude mcp add navable -- npx -y @navable/mcp`)
- Trigger: `/qa-a11y` or included automatically in `qa-team` when a web app is detected

---

#### BL-019 — AI-Generated Alt Text for Images `[S]` ✅ **Implemented v1.7.0.0**
**Source:** [architzero/Aura-accessibility-scanner](https://github.com/architzero/Aura-accessibility-scanner)
**Target skills:** `qa-a11y`
**Description:**
After axe-core flags missing or empty alt text, use Claude's vision capability to screenshot the page, identify all images lacking adequate alt text, and generate semantically accurate alt text candidates — not just "missing alt text" violations but ready-to-use remediation strings.
**Implementation notes:**
- Phase 2 addition in `qa-a11y`: pass page screenshot to Claude with prompt: "Identify all images. For each lacking descriptive alt text, generate a candidate alt text string (max 125 chars, no 'image of' prefix, descriptive of content and purpose)."
- Output: a `suggested-alt-text.json` alongside the main a11y report
- This replaces the BLIP image captioning model from Aura — Claude's vision is equivalent for this use case
- Include in the accessibility report as an "actionable remediation" section

---

### 🔒 New Skill: `qa-security` (Security Testing)

#### BL-020 — `qa-security` Skill: DAST via ZAP MCP + Nuclei `[M]` ✅ **Implemented v1.9.0.0**
**Source:** [zaproxy/zaproxy MCP add-on](https://www.zaproxy.org/), [projectdiscovery/nuclei](https://github.com/projectdiscovery/nuclei)
**Target skills:** New `qa-security` skill
**Description:**
A two-mode security skill. Mode A (full DAST, requires ZAP): drive OWASP ZAP via its MCP add-on — spider, active scan, alert retrieval — then use Claude to triage by OWASP Top 10 + CWE with CVSS estimates. Nuclei provides targeted template-based checks as a second pass. Mode B (lightweight, zero install): Claude-native HTTP probing loop checking security headers, exposed sensitive files, common misconfigurations, JWT weaknesses.
**Implementation notes:**
- Prerequisite check: `zap.sh -version` or `docker pull softwaresecurityproject/zap-stable`
- Mode A: ZAP MCP add-on via Marketplace → spider → active scan (OWASP Top 10 policy) → fetch alerts → Claude triage
- Mode B: `httpx`/`curl` probes: missing `X-Frame-Options`, `CSP`, exposed `.env`/`.git`, `Authorization: Bearer none`
- Nuclei: `nuclei -ai "<app type> <detected stack>" -j -o $TMP/nuclei-results.json`
- Report: `security-report.md` with findings sorted by risk, OWASP category, CWE ID, remediation guidance
- Hard-code safe-mode default (read-only probes only) for use against staging environments

---

#### BL-021 — BurpMCP for Authenticated Session Security Testing `[M]` ✅ **Implemented v1.11.0.0**
**Source:** [swgee/BurpMCP](https://github.com/swgee/BurpMCP)
**Target skills:** `qa-security` (deep-dive mode)
**Description:**
BurpMCP exposes Burp Suite as an MCP server. The QA skill can retrieve captured HTTP requests from Burp, have Claude identify injection points and craft payloads, then replay modified requests — carrying existing session tokens for authenticated-path testing. Supports HTTP/2 and Burp Collaborator for out-of-band detection (SSRF, blind XSS).
**Implementation notes:**
- Detect: `burp.jar` present + BurpMCP add-on installed → activate deep-dive mode
- Skill flow: `burp_retrieve_requests` → Claude analyzes for injection points → `burp_send_request` with crafted payloads → report findings
- Most valuable for testing authenticated API endpoints where ZAP's auth support is limited
- Out-of-band: configure Burp Collaborator URL → detect blind SSRF/XXE in the report

---

### 🗄️ Test Data & Environment

#### BL-022 — `qa-seed` Skill: Schema-Aware Test Data Generation `[M]` ✅ **Implemented v1.9.0.0**
**Source:** [hyangminj/ddl2data](https://github.com/hyangminj/ddl2data)
**Target skills:** New `qa-seed` skill
**Description:**
Ingest the project's SQL DDL or live DB schema and generate relationship-aware synthetic test data that respects FK constraints, CHECK rules, and statistical distributions. Writes directly to the test DB via SQLAlchemy. Each test run gets a fresh, statistically realistic dataset scoped to the session.
**Implementation notes:**
- Detect: `*.sql` DDL files, `prisma/schema.prisma`, `migrations/` directory
- `ddl2data --schema prisma/schema.prisma --rows 100 --db-url $TEST_DATABASE_URL`
- Configure distributions per column type: names → realistic (Faker), amounts → Pareto, dates → recent range
- Wrap in transaction: seed at start, rollback at end → zero cleanup overhead
- Extend with chaos mode (BL-023) for robustness testing

---

#### BL-023 — Chaos Data Testing for Robustness `[S]` ✅ **Implemented v1.11.0.0**
**Source:** [gourav-shokeen/chaoslake](https://github.com/gourav-shokeen/chaoslake)
**Target skills:** `qa-seed`, `qa-web`, `qa-api`
**Description:**
Seed the test DB with intentionally chaotic data (null injection, row duplication, date-format inconsistency, concept drift) then run the test suite. Any test that only passes on clean data reveals a reliability gap. Run clean-seed by default; chaos-seed weekly or on data-pipeline PRs.
**Implementation notes:**
- `chaoslake --seed 42 --null-rate 0.05 --dupe-rate 0.02 --chaos-after 500`
- Use as a `qa-seed --mode=chaos` flag in the skill
- Tests failing on chaos data but passing on clean data → new defect tickets
- Report: "N tests newly failing in chaos mode — likely data handling regressions"

---

#### BL-024 — Isolated Container Environments for Parallel Agents `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [SwissLife-OSS/squadron](https://github.com/SwissLife-OSS/squadron)
**Target skills:** `qa-team` (parallel agent coordination)
**Description:**
When `qa-team` spawns multiple sub-agents in parallel, they can collide on shared DB state. Squadron's pattern: declare required services (PostgreSQL, Redis, Kafka, etc.) in a `test-env.yml` manifest, provision per-agent isolated Docker containers, inject connection strings as env vars, tear down on exit.
**Implementation notes:**
- `test-env.yml`: list service images and versions
- Before spawning sub-agents: `npx @testcontainers/cli start test-env.yml` → outputs per-service ports
- Inject `DB_URL`, `REDIS_URL`, etc. into each sub-agent's environment
- After all agents complete: `npx @testcontainers/cli stop`
- Reference: [Testcontainers Node.js](https://node.testcontainers.org/) as the underlying engine

---

#### BL-025 — Offline-First CI via API Record/Replay `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [CopilotKit/aimock](https://github.com/CopilotKit/aimock)
**Target skills:** `qa-web`, `qa-api`, `qa-team`
**Description:**
On the first CI run, start `aimock` in record mode to proxy and capture all external API calls (LLM providers, third-party services, internal microservices). Subsequent runs replay from fixtures — fully offline, deterministic, near-zero cost. A chaos flag injects random failures to validate error-handling paths.
**Implementation notes:**
- First run: `aimock --record --output fixtures/` as a pre-step
- Subsequent runs: `aimock --replay fixtures/` (or auto-detect via `AIMOCK_RECORD=false`)
- `aimock` supports Claude, OpenAI, Gemini, MCP tools, vector DBs on one port
- Add `chaos: true` to validate agent fallback behavior (timeout handling, retry logic)
- Prometheus metrics output: track which external calls are made per run (cost visibility)

---

#### BL-026 — Simulation-Based User Journey Testing `[M]` ✅ **Implemented v1.9.0.0**
**Source:** [langwatch/scenario](https://github.com/langwatch/scenario) (869 stars)
**Target skills:** New `qa-simulate` skill
**Description:**
Given a feature description (e.g., "checkout flow"), a `UserSimulatorAgent` generates contextually appropriate multi-turn user interactions. A `RedTeamAgent` runs adversarial multi-turn attacks to probe failure paths. A `JudgeAgent` evaluates correctness at each turn. Replaces hand-written fixture flows with AI-generated realistic journeys; cached for deterministic CI replay.
**Implementation notes:**
- Python/TypeScript/Go library: `pip install langwatch-scenario` or `npm install @langwatch/scenario`
- Skill phases: describe feature → generate persona + scenario → drive Playwright with generated turns → Judge evaluates → report
- Cache turn sequences (`--cache-dir fixtures/scenarios/`) for replay in CI (no LLM cost after first run)
- Red-team mode: `scenario.run(redTeam=True)` — auto-generate adversarial inputs
- Most useful for: multi-step wizard flows, shopping cart, multi-role collaboration features

---

### 🔌 Contract Testing & API Schema Validation

#### BL-027 — Schemathesis Property-Based API Fuzzing `[S]` ✅ **Implemented v1.8.0.0**
**Source:** [schemathesis/schemathesis](https://github.com/schemathesis/schemathesis) — 3.3k stars
**Target skills:** `qa-api`
**Description:** Derives thousands of edge-case test inputs (nulls, boundary integers, type mismatches) directly from an OpenAPI spec using property-based testing. Catches unhandled 500s and schema-violating responses no human would enumerate. `--stateful=links` chains create→read→delete flows automatically.
**Implementation notes:**
- Phase 3b in `qa-api`: `st run openapi.yaml --base-url $_API_URL --checks all --stateful=links --report-junit $_TMP/schemathesis-junit.xml`
- Only runs if `openapi.yaml`/`swagger.json` detected and `command -v st` succeeds
- Report: endpoints returning 5xx or body not matching declared schema

---

#### BL-028 — Spectral OpenAPI Spec Linting Pre-Flight `[S]` ✅ **Implemented v1.8.0.0**
**Source:** [stoplightio/spectral](https://github.com/stoplightio/spectral) — 3.1k stars
**Target skills:** `qa-api`
**Description:** Schema-level linter that catches contract drift before runtime: missing error declarations, broken `$ref` refs, undeclared auth, naming inconsistencies. Runs against the spec file with zero server dependency. Surface `error`-level violations as blocking failures before any endpoint tests run.
**Implementation notes:**
- Phase 0 pre-flight: `spectral lint openapi.yaml --format junit --output $_TMP/spectral-junit.xml`
- Falls back to `@stoplight/spectral-openapi` built-in ruleset if no `.spectral.yaml` found
- Any `error` severity = block execution; `warning` = surface in report

---

#### BL-029 — GraphQL Inspector Schema Drift Detection `[S]` ✅ **Implemented v1.8.0.0**
**Source:** [kamilkisiela/graphql-inspector](https://github.com/kamilkisiela/graphql-inspector) — 1.7k stars
**Target skills:** `qa-api`
**Description:** Diffs two GraphQL schemas and classifies each change as `BREAKING`, `DANGEROUS`, or `NON_BREAKING`. After introspecting the live schema, diff it against the committed baseline. Detects field removals, argument type changes, and deprecation drift before consumers break.
**Implementation notes:**
- After live introspection: `npx @graphql-inspector/cli diff schema.graphql $_TMP/schema-live.graphql`
- BREAKING = fail; DANGEROUS = warn; NON_BREAKING = informational in report
- Only runs when GraphQL detected (Phase 1, Strategy 3)

---

#### BL-030 — gRPC Coverage via grpcurl `[S]` ✅ **Implemented v1.8.0.0**
**Source:** [fullstorydev/grpcurl](https://github.com/fullstorydev/grpcurl) — 12.6k stars
**Target skills:** `qa-api`
**Description:** First gRPC coverage layer: detect `.proto` files, enumerate services via server reflection, describe methods, issue smoke-test calls with empty JSON payloads. Report which methods responded vs. errored.
**Implementation notes:**
- Trigger: `*.proto` files detected or `GRPC_HOST` env set
- `grpcurl -plaintext $GRPC_HOST list` → enumerate → `describe` each service
- Smoke test each method; flag non-zero exit as method-level failure
- Report: discovered services + methods, coverage gaps (methods never invoked)

---

#### BL-031 — Pact Consumer-Driven Contract Verification `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [pact-foundation/pact-js](https://github.com/pact-foundation/pact-js) — 1.8k stars
**Target skills:** `qa-api`
**Description:** If pact files exist in the repo, run provider verification. Breaking changes are visible before deployment: if a provider renames a field, the consumer's pact fails in the provider's CI. The existing `contract-testing-guide.md` already covers Pact conceptually.
**Implementation notes:**
- Detect: `find . -name "*.pact.json" -o -path "*/pacts/*.json"` 
- Run: `npx @pact-foundation/pact-verifier --provider-base-url $API_URL --pact-files-or-dirs ./pacts`
- Report: which consumer contracts passed/failed with field-level diff on shape mismatch

---

#### BL-032 — RESTler Stateful REST Fuzzing (Opt-In) `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [microsoft/restler-fuzzer](https://github.com/microsoft/restler-fuzzer) — 2.9k stars
**Target skills:** `qa-api`
**Description:** Infers producer-consumer dependencies from OpenAPI spec (e.g., `POST /users` returns `id` that `DELETE /users/{id}` consumes) then fuzzes state-machine paths. Discovers resource-leak bugs and state-transition 500s that flat endpoint testing never exercises.
**Implementation notes:**
- Opt-in via `QA_DEEP_FUZZ=1` env var (significantly increases run time)
- Runs via Docker: `mcr.microsoft.com/restlerfuzzer/restler:latest`
- Output: `bug_buckets/` directory with categorized 500 errors and resource leaks
- Report: bug bucket count by category; replay commands for reproduction

---

#### BL-033 — OWASP OFFAT Security Fuzzing from OpenAPI (Opt-In) `[S]` ✅ **Implemented v1.11.0.0**
**Source:** [OWASP/OFFAT](https://github.com/OWASP/OFFAT) — 661 stars
**Target skills:** `qa-api`, `qa-security`
**Description:** Security-specific fuzzing from OpenAPI spec: BOLA, mass assignment, SQL injection, XSS, restricted-method bypass. Complements Schemathesis' structural fuzzing with OWASP API Top 10 attack classes.
**Implementation notes:**
- Opt-in via `QA_SECURITY=1` env var
- `offat -f openapi.yaml -u $_API_URL --headers "Authorization: Bearer $_TOKEN" -o $_TMP/offat-results.json`
- `high` severity findings = blocking failure in report

---

### 🧬 Mutation Testing & Test Quality

#### BL-034 — Two-Tier Mutation Testing in `qa-audit` `[M]` ✅ **Implemented v1.10.0.0**
**Source:** [stryker-mutator/stryker-js](https://github.com/stryker-mutator/stryker-js) (2.9k), [hcoles/pitest](https://github.com/hcoles/pitest) (1.8k), [boxed/mutmut](https://github.com/boxed/mutmut) (1.3k)
**Target skills:** `qa-audit`
**Description:** Two-tier approach: Tier 1 = incremental tool-based mutation (fast, zero AI cost) scoped to diff files. Tier 2 = AI analysis of survived mutants (Claude classifies equivalent vs. genuine gap, generates killing tests). CI-viable via incremental mode: full run nightly, diff-scoped run on PRs.
**Implementation notes:**
- JS/TS: `npx stryker run --incremental --reporters json` on diff files; threshold `break: 60`
- Java: `mvn pitest:mutationCoverage -DwithHistory=true -DmutationThreshold=75`
- Python: `mutmut run --paths-to-mutate <diff-files> --use-coverage`
- Tier 2: feed survived mutants to Claude → classify EQUIVALENT / GENUINE-GAP → generate killing test for GENUINE-GAP
- Report: raw mutation score, adjusted score (post-equivalent filtering), suggested tests

---

#### BL-035 — MutaHunter LLM-Native Mutant Generation `[M]` ✅ **Implemented v1.10.0.0**
**Source:** [codeintegrity-ai/mutahunter](https://github.com/codeintegrity-ai/mutahunter) — 296 stars
**Target skills:** `qa-audit`
**Description:** Uses an LLM to generate semantically meaningful mutations (not fixed operator tables) that resemble real bugs. Higher-order mutants = fewer equivalent mutants = more accurate mutation score. Run on changed files in a PR diff; Claude reads survived mutants and generates killing tests.
**Implementation notes:**
- `mutahunter run --test-command "pytest tests/" --model "claude-haiku-4-5-20251001" --source-path <diff-file>`
- Cost control: use Haiku, limit to diff files, cap at 50 mutants/run (~$0.05/run)
- Combine with scientific debugging loop: Claude hypothesizes → generates test → validates → refines (max 3 turns)
- Use real bug commits from `git log --grep="fix"` as few-shot examples for richer mutations

---

### ⚡ Performance Testing Enhancements

#### BL-036 — Artillery MCP Server: Adaptive Test Sequencing `[S]` ✅ **Implemented v1.8.0.0**
**Source:** [jch1887/artillery-mcp-server](https://github.com/jch1887/artillery-mcp-server)
**Target skills:** `qa-perf`
**Description:** Exposes 15 MCP tools so Claude drives Artillery load tests natively — run tests from YAML, execute preset profiles (smoke/baseline/soak/spike), compare results against named baselines, detect regressions. Claude decides "run spike first, then if p99 < 500ms run soak" — adaptive test sequencing.
**Implementation notes:**
- `claude mcp add artillery-mcp-server` (or equivalent)
- Adaptive flow: smoke → read results → escalate to soak only if smoke passes → escalate to stress only if soak passes
- Baseline persistence: after every main-branch merge, save results as named baseline; PRs auto-compare
- Claude generates inline Artillery YAML scenarios from detected OpenAPI spec endpoints

---

#### BL-037 — Pyroscope Flamegraph AI Summary `[S]` ✅ **Implemented v1.8.0.0**
**Source:** [grafana/pyroscope](https://github.com/grafana/pyroscope) — 11.4k stars
**Target skills:** `qa-perf`
**Description:** Fetch the profile diff between the load-test window and idle baseline via the Pyroscope API. Feed flamegraph JSON to Claude: "Identify the top 3 functions consuming disproportionately more CPU under load vs. idle. For each, describe the likely cause and suggest one optimization."
**Implementation notes:**
- Post-test hook: `pyroscope_api/diff?leftFrom=<idle_start>&leftUntil=<idle_end>&rightFrom=<load_start>&rightUntil=<load_end>`
- k6 integration: `import { Pyroscope } from 'k6/experimental/pyroscope'` tags profiles by scenario
- Append "Profiling Insights" section to standard perf report (3-bullet flamegraph summary)
- Only runs if `PYROSCOPE_URL` env var set

---

#### BL-038 — SLO-as-Code from k6 Thresholds `[S]` ✅ **Implemented v1.8.0.0**
**Source:** [slok/sloth](https://github.com/slok/sloth) (2.5k), [OpenSLO/OpenSLO](https://github.com/OpenSLO/OpenSLO) (1.5k)
**Target skills:** `qa-perf`
**Description:** Auto-generate Sloth SLO YAML from the same thresholds defined in k6 scripts — single source of truth. After a load test, Claude calculates "at this error rate, 30-day error budget depletes in N days."
**Implementation notes:**
- Parse k6 `thresholds` block: `http_req_duration['p(95)<200']` → Sloth `objectivePercent: 99.5, window: 30d`
- Claude generates the Sloth YAML and commits it alongside the test
- Post-test: compute burn rate from observed error rate → project error budget exhaustion date
- Report addition: "Error budget status: X days remaining at current burn rate"

---

#### BL-039 — LitmusChaos Concurrent Resilience Testing `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [litmuschaos/litmus](https://github.com/litmuschaos/litmus) — 5.3k stars (CNCF)
**Target skills:** `qa-perf`
**Description:** A `--chaos` flag interleaves a LitmusChaos experiment with a k6 load test. Claude defines the `SteadyStateHypothesis` from existing k6 thresholds, then interprets the result: "System maintained p99 under load during 30% pod kill but breached during 50% — resilience threshold is between 30-50% instance loss."
**Implementation notes:**
- Opt-in: `QA_CHAOS=1` or `--chaos` flag
- Claude auto-generates `ChaosEngine` YAML with hypothesis derived from k6 thresholds
- Run concurrently: `litmusctl run chaosengine` + `k6 run test.js` in parallel
- Report: did system hold SLO during fault? boundary thresholds for each fault type

---

#### BL-040 — Bencher Continuous Benchmarking + Trend Narrative `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [bencherdev/bencher](https://github.com/bencherdev/bencher) — 832 stars
**Target skills:** `qa-perf`
**Description:** Stable bare-metal benchmarking infrastructure (<2% variance vs. >30% on CI runners) feeds k6 summaries into a historical trend store. Claude reads the trend history and writes narratives: "This endpoint's p99 has drifted +12% over the last 8 PRs — regression is gradual, not spike-shaped."
**Implementation notes:**
- Push k6 summary JSON to Bencher after each run: `bencher run --project <project> --adapter json k6`
- On threshold violation: pull trend history → Claude writes 1-paragraph regression explanation + suggests profiling steps
- Historical comparison: "Compare p95 trend of `/api/checkout` over the last 30 runs and explain the inflection at SHA `abc123`"

---

#### BL-041 — GoReplay Production Traffic Replay `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [buger/goreplay](https://github.com/buger/goreplay) — 19.3k stars
**Target skills:** `qa-perf`
**Description:** Capture live HTTP traffic from production and replay it verbatim against staging. The load profile IS real users — no synthetic traffic assumptions. Claude diffs replay results against baseline per endpoint: latency regressions, new error codes, coverage of previously untested flows.
**Implementation notes:**
- Requires production access; opt-in via `QA_REPLAY_MODE=1`
- `gor --input-raw :80 --output-file requests.gor` (capture); `gor --input-file requests.gor --output-http staging` (replay)
- Claude analysis prompt: "Compare baseline vs replay results. Identify endpoints with p95 regression >10%. Summarize likely root causes."
- Report: Markdown table of endpoint | baseline p99 | replay p99 | delta | verdict

---

### 🖼️ Visual Testing Enhancements

#### BL-042 — Three-Layer Visual Pipeline with VLM Classification `[S]` ✅ **Implemented v1.8.0.0**
**Source:** [Visual-Regression-Tracker/visual-regression-tracker](https://github.com/Visual-Regression-Tracker/visual-regression-tracker) (685), Playwright custom comparator, Claude Vision
**Target skills:** `qa-visual`
**Description:** Replace or augment pixel-diff with a three-layer pipeline: (1) Playwright capture at multiple viewports + dark mode, (2) pixelmatch noise filter (auto-pass < 0.1%, auto-flag structural > 20%), (3) Claude Vision classification for diffs in 0.1%–20% range → PASS/WARN/FAIL with reasoning. Cuts false positives dramatically.
**Implementation notes:**
- Layer 1: `toHaveScreenshot()` at `[375, 768, 1440]` viewports + `prefers-color-scheme: dark`
- Layer 2: pixelmatch diff; `diffRatio < 0.001` = auto-pass; `diffRatio > 0.20` = auto-fail
- Layer 3: send baseline + current + diff mask to Claude: `{ verdict: "PASS|WARN|FAIL", confidence: 0-1, reasoning: "...", affected_regions: [...] }`
- Cache verdicts by diff hash to avoid re-judging identical diffs

---

#### BL-043 — DOM Metric Extraction for Cost-Efficient Visual Comparison `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [simbo1905/gux-tool](https://github.com/simbo1905/gux-tool)
**Target skills:** `qa-visual`
**Description:** Instead of sending multi-MB screenshots to Claude on every run, extract structured DOM metrics (bounding boxes, computed colors, font sizes, text content for key selectors) via `page.evaluate()` and have Claude verify them against a recorded spec. Dramatically reduces token cost per comparison.
**Implementation notes:**
- Baseline capture: `page.evaluate()` → JSON of `{ selector, boundingBox, color, fontSize, text }` for key elements
- Each run: re-extract → Claude diff: "Here are baseline and current layout metrics. Identify meaningful regressions."
- Only escalate to screenshot+VLM when DOM metrics show divergence
- Optionally define a `.visual-spec` file per page with expected metric ranges

---

#### BL-044 — BackstopJS Scenario Config as qa-visual Input Schema `[S]` ✅ **Implemented v1.8.0.0**
**Source:** [garris/BackstopJS](https://github.com/garris/BackstopJS) — 7.1k stars
**Target skills:** `qa-visual`
**Description:** Adopt BackstopJS's battle-tested scenario config format as the input schema for `qa-visual` (URL + viewport + interaction steps + ignore regions + threshold). Already understood by thousands of engineers. Support responsive breakpoints derived from Tailwind/CSS breakpoint values found in the project.
**Implementation notes:**
- Auto-generate `backstop.json` during Phase 1 from detected routes + project breakpoints
- Parse Tailwind config for custom breakpoints: `tailwind.config.js → theme.screens`
- Import existing `backstop.json` if found — don't regenerate
- Interaction steps (hover/scroll before capture) map to Playwright actions in Phase 3

---

### 📱 Mobile Testing Enhancements

#### BL-045 — Midscene.js: Pure-Vision No-Selector Mobile Testing `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [web-infra-dev/midscene](https://github.com/web-infra-dev/midscene) — 12.9k stars
**Target skills:** `qa-mobile`
**Description:** Abandons selectors entirely — all element localization is based on screenshots via VLM (Qwen3-VL, UI-TARS, Gemini). Tests written in plain English; the model reasons over a screenshot to find and interact with UI elements. Works on iOS, Android, React Native, Flutter (native pixels). Zero brittleness from selector drift.
**Implementation notes:**
- Replaces `tapOn(id)` calls with `midscene.aiAction("tap the Login button")`
- On failure: Claude receives screenshot + VLM reasoning trace → natural-language fix suggestion
- Use as fallback executor when Maestro/Detox selectors break
- `npm install @midscene/android` or `@midscene/ios-client`

---

#### BL-046 — OmniParser Perception Layer for Canvas/Game UIs `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [microsoft/OmniParser](https://github.com/microsoft/OmniParser) — 24.7k stars
**Target skills:** `qa-mobile`
**Description:** Parses any UI screenshot into structured, labeled elements using CV (interactive region detection + icon classification). Acts as a universal "UI parser" when accessibility labels are absent (Flutter canvas, games, custom-drawn UIs). Claude reasons over OmniParser's structured output rather than raw pixels.
**Implementation notes:**
- Trigger: standard accessibility tree parsing fails (0 interactive elements found)
- Pipe device screenshot through OmniParser → labeled element map → Claude selects action target → ADB/XCUITest executes
- Particularly useful for Flutter apps and games that break all selector-based tools
- Self-host via Docker: `docker run -p 8000:8000 microsoft/omniparser`

---

#### BL-047 — Mobile-Agent Reflector: Automatic Test Recovery `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [X-PLUG/MobileAgent](https://github.com/X-PLUG/MobileAgent) — 8.6k stars
**Target skills:** `qa-mobile`
**Description:** Multi-agent system with a Reflector agent that detects step failures and re-plans without hard-failing. When a test step fails, pass the failed screenshot + error to Claude with the reflection prompt → get a revised action plan → re-execute. Ideal for flaky real-device tests.
**Implementation notes:**
- Add `onStepFail` hook to qa-mobile execution phase
- Reflection prompt: "Step N failed with error X. Here is the current screenshot. What alternative action achieves the same goal?"
- Max 2 reflection retries per step before marking test as failed
- Track reflection rate per test: tests with >1 reflection/run are flakiness candidates (→ BL-007)

---

#### BL-048 — AndroidWorld Task Templates as Scenario Seeds `[S]` ✅ **Implemented v1.13.0.0**
**Source:** [google-research/android_world](https://github.com/google-research/android_world) — 750 stars
**Target skills:** `qa-mobile`
**Description:** 116 validated task templates across 20 real-world Android apps with dynamic parameterization. Import as a "standard scenario library" — when testing a new app, Claude matches screens to the closest AndroidWorld task template and adapts it, cutting test authoring time significantly.
**Implementation notes:**
- Add `qa-mobile/references/android-world-tasks.md` with the 116 task templates
- Phase 1 addition: Claude reads app screenshots and matches to nearest task template category
- Adapted template becomes the starting spec; engineer reviews and refines
- Also useful for measuring qa-mobile agent quality (run on AndroidWorld benchmark)

---

### 📋 Requirements-to-Tests Bridge

#### BL-049 — Shortest: TCMS Test Cases → Playwright Execution `[S]` ✅ **Implemented v1.13.0.0**
**Source:** [antiwork/shortest](https://github.com/antiwork/shortest) — 5.6k stars
**Target skills:** `qa-web`, `qa-manager`
**Description:** Tests written as plain English strings are interpreted by Claude at runtime into Playwright actions. Bridge path: TCMS test case text → `shortest()` call → automated Playwright execution. Zero selector maintenance; the NL sentence is the stable artifact.
**Implementation notes:**
- Map TCMS `When/Then` acceptance criteria bullets directly to `shortest("...")` calls
- The skill generates a `<feature>.shortest.ts` file, runs `npx shortest`, reports pass/fail back
- On failure: Claude receives the failing sentence + DOM snapshot → rewrites intent statement (not selector)
- 2FA support built-in via GitHub OAuth; email validation via Mailosaur

---

#### BL-050 — Epic → Playwright Auditable Pipeline `[L]` ✅ **Implemented v1.15.0.0**
**Source:** [YiboLi1986/AIDRIVENTESTPROCESSAUTOMATION](https://github.com/YiboLi1986/AIDRIVENTESTPROCESSAUTOMATION)
**Target skills:** `qa-manager`
**Description:** Full Epic → Features → User Stories → Test Plan → Test Cases → Playwright skeletons pipeline. Every stage produces a versioned JSON artifact with human-in-the-loop confirmation before the next stage runs. Provides permanent audit trail from JIRA Epic to running test.
**Implementation notes:**
- Input: JIRA Epic ID → fetch stories via JIRA API
- Each stage: JSON saved to `/test-specs/<stage>_<name>.confirmed.v1.json`
- Playwright skeletons include inline comments linking back to test case ID
- Human confirmation gates between stages (AskUserQuestion)
- Final artifact: committed Playwright spec + traceability matrix

---

#### BL-051 — Figma Design → Test Cases at Sprint Kickoff `[S]` ✅ **Implemented v1.15.0.0**
**Source:** [bhanusdet/CaseVector-AI-effortless-test-case-generation](https://github.com/bhanusdet/CaseVector-AI-effortless-test-case-generation) — 13 stars
**Target skills:** `qa-manager`
**Description:** At sprint kickoff, fetch Figma frame URLs from JIRA ticket descriptions, run multimodal AI analysis (OCR + CV on design screenshots), and produce test case drafts in the TCMS before implementation starts. Creates a "test-first from design" workflow.
**Implementation notes:**
- Parse JIRA ticket body for Figma URLs (pattern: `figma.com/file/...`)
- Fetch Figma frame as PNG via Figma API → Claude vision analysis
- Claude generates structured test cases: preconditions, steps, expected results
- Push to TCMS (e.g., TestRail, Xray) via existing `qa-manager` TCMS integration
- Run at sprint kickoff, not at test execution time

---

### 🧩 New Skill: `qa-component` (Component Testing)

#### BL-052 — `qa-component` Skill: Storybook + Vitest Pipeline `[M]` ✅ **Implemented v1.9.0.0**
**Source:** [storybookjs/storybook](https://github.com/storybookjs/storybook) — 89.8k stars, Vitest addon
**Target skills:** New `qa-component` skill
**Description:** When Storybook is detected: (1) run `storybook test --coverage` to execute interaction tests + accessibility checks + smoke tests from stories, (2) run Chromatic visual snapshots per story, (3) identify components with no stories and optionally generate stubs. Stories are free tests — the skill harvests them.
**Implementation notes:**
- Phase 1: `find . -path "*/.storybook/main.*"` — detect Storybook
- Phase 2: `npx storybook test --coverage --json` — interaction + a11y + smoke
- Phase 3: parse coverage; components below threshold → Claude generates missing `play` functions
- Phase 4: `npx chromatic --only-changed` if `CHROMATIC_PROJECT_TOKEN` set
- Report: per-component status, coverage %, WCAG violation count, visual diff count

---

#### BL-053 — Prop Boundary Testing via fast-check + Claude `[M]` ✅ **Implemented v1.9.0.0**
**Source:** [dubzzz/fast-check](https://github.com/dubzzz/fast-check) — 4.9k stars
**Target skills:** `qa-component`
**Description:** Parse component TypeScript prop interfaces with `ts-morph`, send the type signature to Claude to generate a `fast-check` arbitrary, then run hundreds of prop combinations via `@fast-check/vitest` — catching crashes or assertion failures that hand-written tests miss.
**Implementation notes:**
- Use `ts-morph` to extract prop interface from component file
- Claude prompt: "Generate a `fc.record(...)` arbitrary for this TypeScript interface"
- Run: `@fast-check/vitest` with the generated arbitrary — 200 combinations by default
- Report: which prop combinations caused crashes (with minimal reproducible example via shrinking)

---

#### BL-054 — Component Mutation Quality Gate `[M]` ✅ **Implemented v1.9.0.0**
**Source:** [stryker-mutator/stryker-js](https://github.com/stryker-mutator/stryker-js) — 2.9k stars
**Target skills:** `qa-component`
**Description:** After generating tests, run Stryker on changed component files to find surviving mutants — tests that hit coverage numbers without actually verifying behavior. Claude generates assertions to kill surviving mutants, preventing hollow AI-generated tests.
**Implementation notes:**
- `npx stryker run --mutate "src/components/**" --incremental`
- Feed survived mutants to Claude: "Mutant survived in Button.tsx line 23: `disabled` check changed. Add an assertion that would kill it."
- Block merge if adjusted mutation score < 60% (after equivalent filtering)
- Nightly full run on `main`; incremental on PR diff

---

### 🔭 Test Observability & Distributed Tracing

#### BL-055 — `traceparent` Injection in Playwright Tests `[S]` ✅ **Implemented v1.13.0.0**
**Source:** [kubeshop/tracetest](https://github.com/kubeshop/tracetest) (1.3k), [open-telemetry/opentelemetry-js-contrib](https://github.com/open-telemetry/opentelemetry-js-contrib) (904), [open-telemetry/opentelemetry-demo](https://github.com/open-telemetry/opentelemetry-demo) (3.1k)
**Target skills:** `qa-web`, `qa-api`
**Description:** In Playwright's `beforeEach`, create an OTel span for the test and inject its `traceparent` header into all page requests via `page.route()`. Every test-driven HTTP call now carries a known trace ID. On failure, include the trace ID as a link to the project's Jaeger/Tempo backend.
**Implementation notes:**
- Add to generated `playwright.config.ts`: OTel SDK init + `page.route('**/*', ...)` traceparent injection
- Only activates if `OTEL_EXPORTER_OTLP_ENDPOINT` env var set
- Use OTel Demo's `src/frontend/utils/telemetry.ts` as the reference implementation
- Store trace ID in test metadata; include in Phase 4 failure reports as clickable link

---

#### BL-056 — Tracetest Span Assertions as API Tests `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [kubeshop/tracetest](https://github.com/kubeshop/tracetest) — 1.3k stars
**Target skills:** `qa-api`
**Description:** Assert on the distributed trace emitted by the system under test, not just the HTTP response body. Write span assertions: "every database span must complete in under 100ms" or "the auth gRPC call must return code 0." Test failures now identify the specific span that introduced a regression.
**Implementation notes:**
- Requires Tracetest server + OTel-instrumented backend
- `qa-api` Phase 3b: generate Tracetest YAML definitions alongside standard HTTP tests
- On failure: fetch OTel waterfall from Jaeger/Tempo using the trace ID → feed to Claude for RCA
- Report addition: "Root span: `api/checkout` | First error span: `postgres/query` | Duration: 2.4s | Attributes: `db.statement=...`"

---

#### BL-057 — `qa-observability` Sub-Agent for Failure RCA `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [robusta-dev/holmesgpt](https://github.com/robusta-dev/holmesgpt) — 2.3k stars (CNCF Sandbox)
**Target skills:** All skills (post-failure hook)
**Description:** When any skill reports a failure, a `qa-observability` sub-agent runs a HolmesGPT-style loop: fetch the test's network requests, query backend logs for the 30 seconds around the failure, fetch OTel spans for the trace ID, synthesize a root cause statement. Appended as `FAILURE_REASON` block to the test report.
**Implementation notes:**
- Sub-agent input: failing test name + trace ID + timestamp
- Tool calls: (1) query OTel store for trace by ID, (2) fetch error spans, (3) grep relevant service logs
- Claude synthesizes: "The checkout test failed because the `inventory-service` returned 503 (Redis timeout). Backend trace shows the Redis connection pool was exhausted 200ms before the test assertion."
- Only runs if observability stack configured (`OTEL_EXPORTER_OTLP_ENDPOINT`, `LOKI_URL`, etc.)

---

#### BL-058 — Honeycomb buildevents CI Trace Wrapper `[S]` ✅ **Implemented v1.13.0.0**
**Source:** [honeycombio/buildevents](https://github.com/honeycombio/buildevents) — 230 stars
**Target skills:** CI workflows (`.github/workflows/`)
**Description:** Wrap CI test commands in `buildevents cmd` to build a hierarchical OTel trace of the entire build — each test phase becomes a child span. View the full build timeline in Honeycomb with test phases as spans and failures as errored spans with timing context.
**Implementation notes:**
- `buildevents cmd $STEP_ID -- npx playwright test` wraps the skill's test execution
- Injects `HONEYCOMB_TRACE` env var so downstream processes can attach sub-spans
- CI pipeline becomes a Honeycomb waterfall: build → qa-web phase → playwright run → individual tests
- Zero app code changes required; pure CI configuration

---

### 🌐 Cross-Browser & Device Coverage

#### BL-059 — Multi-Browser Default in `qa-web` `[S]` ✅ **Implemented v1.8.0.0**
**Source:** Playwright built-in multi-project support
**Target skills:** `qa-web`
**Description:** The single highest-leverage cross-browser improvement with no external dependencies: expand the generated `playwright.config.ts` to emit `projects: [chromium, firefox, webkit]` by default. Add a browser-breakdown section to the Phase 5 report showing pass/fail by browser.
**Implementation notes:**
- `qa-web` generated config: `projects: [{ name: 'chromium' }, { name: 'firefox' }, { name: 'webkit' }]`
- Phase 5 report addition: table of test × browser showing browser-specific failures
- Flag tests that fail in Firefox/WebKit but pass in Chromium — likely selector or API compatibility issues
- Opt-out via `QA_BROWSERS=chromium` env var for speed

---

#### BL-060 — Cross-Browser Locator Stability Audit `[S]` ✅ **Implemented v1.8.0.0**
**Source:** [LambdaTest KaneAI](https://www.testmuai.com/kane-ai/)
**Target skills:** `qa-web`
**Description:** Before generating final Playwright specs, probe each target page on Chromium and Firefox. Compare `locator.count()` results across browsers. Locators returning different counts get flagged and rewritten to use `getByRole` or `getByLabel` — browser-agnostic locator strategies.
**Implementation notes:**
- Phase 2.5 "locator audit": open page in both browsers, run `page.locator(selector).count()` for each generated locator
- Count mismatch = rewrite using stable hierarchy: `getByRole` > `getByLabel` > `getByText` > `data-testid`
- Report: N locators rewritten for cross-browser stability
- Prevents failures that only surface on Safari/Firefox in production

---

#### BL-061 — Lost Pixel Self-Hosted Multi-Browser Visual `[S]` ✅ **Implemented v1.13.0.0**
**Source:** [lost-pixel/lost-pixel](https://github.com/lost-pixel/lost-pixel) — open source (MIT)
**Target skills:** `qa-visual`
**Description:** Open-source, fully self-hosted visual regression across Chrome, Firefox, Safari with configurable responsive breakpoints. Used when cloud visual-testing services are unavailable (privacy, security). Auto-generate `lostpixel.config.ts` with breakpoints derived from project's Tailwind/CSS config.
**Implementation notes:**
- Fallback path in `qa-visual`: if no `APPLITOOLS_API_KEY` or `CHROMATIC_PROJECT_TOKEN` → use Lost Pixel
- Auto-detect Tailwind breakpoints: `tailwind.config.js → theme.screens` → populate `breakpoints`
- `npx lost-pixel --config lostpixel.config.ts`
- Report: per-page, per-breakpoint, per-browser diff images with threshold results

---

### 🔧 Test Maintenance & Self-Healing

#### BL-062 — `qa-heal` Skill: Confidence-Gated Repair Pipeline `[M]` ✅ **Implemented v1.8.0.0**
**Source:** [EsraaKamel11/Autonomous-QA-Agent-Framework](https://github.com/EsraaKamel11/Autonomous-QA-Agent-Framework), [EsraaKamel11/Self-Healing-Selenium-Framework](https://github.com/EsraaKamel11/Self-Healing-Selenium-Framework)
**Target skills:** New `qa-heal` skill
**Description:** PR-triggered test maintenance: diff analysis → failure classification (6-type taxonomy) → repair strategy dispatch → confidence-gated routing (auto-commit ≥ 0.87, review PR at 0.62–0.87, GitHub issue below 0.62). Covers broken selectors, snapshot drift, assertion drift, API schema changes, and navigation changes.
**Implementation notes:**
- Trigger: CI failure on PR (via `gh pr view --json statusCheckRollup`)
- Step 1: classify failure from exception signal + DOM evidence into 6 types: broken-selector / stale-element / moved-element / assertion-drift / navigation-change / timing-issue
- Step 2: apply repair strategy per type (DOM diff for selectors, inline-snapshot fix for snapshots, Keploy re-record for API changes)
- Step 3: validate — functional re-run + DOM uniqueness check + regression guard
- Step 4: confidence gate → auto-commit | review PR | GitHub issue

---

#### BL-063 — Chisel MCP Test Impact Analysis for Scoped Healing `[S]` ✅ **Implemented v1.13.0.0**
**Source:** [GitHub test-impact-analysis topic](https://github.com/topics/test-impact-analysis)
**Target skills:** `qa-heal`, `qa-team`
**Description:** Before running the full repair pipeline, use test impact analysis to identify only the tests impacted by changed files. Bounds the cost and scope of `qa-heal` to tests that could actually be broken by the PR.
**Implementation notes:**
- Input: `gh pr diff --name-only` → list of changed files
- Test impact analysis: trace dependency graph from changed files to test files
- Only inspect + attempt repair on impacted test subset
- This bounds `qa-heal` cost from O(all tests) to O(impacted tests per PR)

---

#### BL-064 — Keploy eBPF API Traffic Recording for Test Updates `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [keploy/keploy](https://github.com/keploy/keploy) — 17.2k stars
**Target skills:** `qa-heal`, `qa-api`
**Description:** Record real API traffic at the network layer using eBPF and auto-generate tests + mocks from recordings. When APIs change, re-record against the new behavior — the "test update" is re-running the recorder, not editing test code.
**Implementation notes:**
- On PR touching API routes: `keploy record --command "node server.js"` during a smoke run
- Diff new captures against stored baseline → schema delta report
- Auto-update mocks if delta matches PR description; otherwise file review PR
- Complements Pact (BL-031): Keploy captures what the provider actually does; Pact verifies consumer expectations

---

#### BL-065 — inline-snapshot Drift Management `[S]` ✅ **Implemented v1.8.0.0**
**Source:** [15r10nk/inline-snapshot](https://github.com/15r10nk/inline-snapshot) — 727 stars
**Target skills:** `qa-heal`, `qa-web`, `qa-api`
**Description:** Snapshot values live inline in test code. `pytest --inline-snapshot=fix` auto-updates them. On a PR touching serialization/rendering/formatting code, the skill runs the fix command and if the diff is consistent with the PR intent, commits the snapshot updates as a new commit on the branch.
**Implementation notes:**
- Trigger: PR diff touches output-producing code (serializers, templates, formatters)
- Run: `pytest --inline-snapshot=fix` → git diff to see what changed
- If changed snapshot count is small and consistent with PR scope: `git commit -m "chore: update inline snapshots for <PR title>"`
- If diff is large or unexpected: post as PR comment for human review

---

#### BL-066 — TestZeus Hercules: Gherkin + DOM Distillation `[M]` ✅ **Implemented v1.14.0.0**
**Source:** [test-zeus-ai/testzeus-hercules](https://github.com/test-zeus-ai/testzeus-hercules) — 997 stars
**Target skills:** `qa-web`, `qa-manager`
**Description:** Converts Gherkin specifications to automated E2E tests at runtime using DOM Distillation — only relevant elements are extracted and tagged with custom attributes. No hardcoded selectors; the agent re-discovers how to perform each action every run. Tests survive UI refactors because the Gherkin intent is the stable artifact.
**Implementation notes:**
- When Gherkin `.feature` files exist, use Hercules as the execution engine instead of static Playwright specs
- `qa-heal` role: maintain only the Gherkin files; Hercules handles all selector-level adaptation
- On PR changing user-facing behavior: skill updates `Then` clauses in `.feature` files based on PR diff
- Particularly valuable for apps with frequent UI redesigns

---

## Research Sources

- [proffesor-for-testing/agentic-qe](https://github.com/proffesor-for-testing/agentic-qe)
- [browser-use/vibetest-use](https://github.com/browser-use/vibetest-use)
- [testsigmahq/testsigma](https://github.com/testsigmahq/testsigma)
- [Axolotl-QA/Axolotl](https://github.com/Axolotl-QA/Axolotl)
- [final-run/finalrun-agent](https://github.com/final-run/finalrun-agent)
- [Agent-Field/SWE-AF](https://github.com/Agent-Field/SWE-AF)
- [modal-labs/devlooper](https://github.com/modal-labs/devlooper)
- [NihadMemmedli/quorvex_ai](https://github.com/NihadMemmedli/quorvex_ai)
- [bug0inc/passmark](https://github.com/bug0inc/passmark) (690 stars)
- [Codium-ai/cover-agent](https://github.com/Codium-ai/cover-agent)
- [Intelligent-CAT-Lab/FlakyDoctor](https://github.com/Intelligent-CAT-Lab/FlakyDoctor)
- [antiwork/shortest](https://github.com/antiwork/shortest) (5.6k stars)
- [langwatch/scenario](https://github.com/langwatch/scenario) (869 stars)
- [Applitools Eyes](https://applitools.com/platform/eyes/)
- [PactFlow Drift + AI Beta](https://pactflow.io/blog/)
- [ctrf-io/ctrf](https://github.com/ctrf-io/ctrf) + [ctrf.io](https://ctrf.io)
- [ctrf-io/github-test-reporter](https://github.com/ctrf-io/github-test-reporter)
- [ctrf-io/ai-test-reporter](https://github.com/ctrf-io/ai-test-reporter)
- [daun/playwright-report-summary](https://github.com/daun/playwright-report-summary)
- [Trunk Flaky Tests](https://trunk.io/flaky-tests)
- [CloudBees Smart Tests / Launchable](https://www.cloudbees.com/capabilities/cloudbees-smart-tests)
- [BuildPulse](https://buildpulse.io)
- [web-DnA/navable-web-accessibility-mcp](https://github.com/web-DnA/navable-web-accessibility-mcp)
- [architzero/Aura-accessibility-scanner](https://github.com/architzero/Aura-accessibility-scanner)
- [Farhod75/ai-a11y-testing](https://github.com/Farhod75/ai-a11y-testing)
- [Aboudjem/sniff](https://github.com/Aboudjem/sniff)
- [zaproxy/zaproxy](https://github.com/zaproxy/zaproxy)
- [projectdiscovery/nuclei](https://github.com/projectdiscovery/nuclei) (28k+ stars)
- [swgee/BurpMCP](https://github.com/swgee/BurpMCP)
- [CyberWardion/ai-pentest-agent](https://github.com/CyberWardion/ai-pentest-agent)
- [hyangminj/ddl2data](https://github.com/hyangminj/ddl2data)
- [gourav-shokeen/chaoslake](https://github.com/gourav-shokeen/chaoslake)
- [SwissLife-OSS/squadron](https://github.com/SwissLife-OSS/squadron)
- [CopilotKit/aimock](https://github.com/CopilotKit/aimock) (570 stars)
- [dotenvx/dotenvx](https://github.com/dotenvx/dotenvx)
- [schemathesis/schemathesis](https://github.com/schemathesis/schemathesis) (3.3k)
- [pact-foundation/pact-js](https://github.com/pact-foundation/pact-js) (1.8k)
- [microsoft/restler-fuzzer](https://github.com/microsoft/restler-fuzzer) (2.9k)
- [stoplightio/spectral](https://github.com/stoplightio/spectral) (3.1k)
- [kamilkisiela/graphql-inspector](https://github.com/kamilkisiela/graphql-inspector) (1.7k)
- [fullstorydev/grpcurl](https://github.com/fullstorydev/grpcurl) (12.6k)
- [OWASP/OFFAT](https://github.com/OWASP/OFFAT) (661)
- [stryker-mutator/stryker-js](https://github.com/stryker-mutator/stryker-js) (2.9k)
- [hcoles/pitest](https://github.com/hcoles/pitest) (1.8k)
- [codeintegrity-ai/mutahunter](https://github.com/codeintegrity-ai/mutahunter) (296)
- [boxed/mutmut](https://github.com/boxed/mutmut) (1.3k)
- [Meta ACH: Mutation-Guided LLM Test Generation (arXiv:2501.12862)](https://arxiv.org/abs/2501.12862)
- [buger/goreplay](https://github.com/buger/goreplay) (19.3k)
- [coroot/coroot](https://github.com/coroot/coroot) (7.6k)
- [getanteon/anteon](https://github.com/getanteon/anteon) (8.5k)
- [jch1887/artillery-mcp-server](https://github.com/jch1887/artillery-mcp-server)
- [bencherdev/bencher](https://github.com/bencherdev/bencher) (832)
- [slok/sloth](https://github.com/slok/sloth) (2.5k) + [OpenSLO](https://github.com/OpenSLO/OpenSLO)
- [litmuschaos/litmus](https://github.com/litmuschaos/litmus) (5.3k)
- [grafana/pyroscope](https://github.com/grafana/pyroscope) (11.4k)
- [Visual-Regression-Tracker/visual-regression-tracker](https://github.com/Visual-Regression-Tracker/visual-regression-tracker) (685)
- [argos-ci/argos](https://github.com/argos-ci/argos) (580)
- [garris/BackstopJS](https://github.com/garris/BackstopJS) (7.1k)
- [simbo1905/gux-tool](https://github.com/simbo1905/gux-tool)
- [web-infra-dev/midscene](https://github.com/web-infra-dev/midscene) (12.9k)
- [mnotgod96/AppAgent](https://github.com/mnotgod96/AppAgent) (6.7k)
- [X-PLUG/MobileAgent](https://github.com/X-PLUG/MobileAgent) (8.6k)
- [bytedance/UI-TARS](https://github.com/bytedance/UI-TARS) (10.2k)
- [mobile-dev-inc/maestro](https://github.com/mobile-dev-inc/maestro) (13.9k)
- [google-research/android_world](https://github.com/google-research/android_world) (750)
- [microsoft/OmniParser](https://github.com/microsoft/OmniParser) (24.7k)
- [YiboLi1986/AIDRIVENTESTPROCESSAUTOMATION](https://github.com/YiboLi1986/AIDRIVENTESTPROCESSAUTOMATION)
- [bhanusdet/CaseVector-AI-effortless-test-case-generation](https://github.com/bhanusdet/CaseVector-AI-effortless-test-case-generation)
- [storybookjs/storybook](https://github.com/storybookjs/storybook) (89.8k)
- [dubzzz/fast-check](https://github.com/dubzzz/fast-check) (4.9k)
- [neu-se/testpilot2](https://github.com/neu-se/testpilot2)
- [kubeshop/tracetest](https://github.com/kubeshop/tracetest) (1.3k)
- [honeycombio/buildevents](https://github.com/honeycombio/buildevents) (230)
- [grafana/tempo](https://github.com/grafana/tempo) (5.2k)
- [robusta-dev/holmesgpt](https://github.com/robusta-dev/holmesgpt) (2.3k)
- [open-telemetry/opentelemetry-demo](https://github.com/open-telemetry/opentelemetry-demo) (3.1k)
- [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) (31.9k)
- [browserbase/stagehand](https://github.com/browserbase/stagehand)
- [lost-pixel/lost-pixel](https://github.com/lost-pixel/lost-pixel)
- [EsraaKamel11/Autonomous-QA-Agent-Framework](https://github.com/EsraaKamel11/Autonomous-QA-Agent-Framework)
- [EsraaKamel11/Self-Healing-Selenium-Framework](https://github.com/EsraaKamel11/Self-Healing-Selenium-Framework)
- [15r10nk/inline-snapshot](https://github.com/15r10nk/inline-snapshot) (727)
- [test-zeus-ai/testzeus-hercules](https://github.com/test-zeus-ai/testzeus-hercules) (997)
- [keploy/keploy](https://github.com/keploy/keploy) (17.2k)
- [GitHub ai-testing topic](https://github.com/topics/ai-testing)
- [GitHub topics/visual-testing](https://github.com/topics/visual-testing)
- [GitHub topics/mutation-testing](https://github.com/topics/mutation-testing)
- [GitHub topics/self-healing-tests](https://github.com/topics/self-healing-tests)

- [proffesor-for-testing/agentic-qe](https://github.com/proffesor-for-testing/agentic-qe)
- [browser-use/vibetest-use](https://github.com/browser-use/vibetest-use)
- [testsigmahq/testsigma](https://github.com/testsigmahq/testsigma)
- [Axolotl-QA/Axolotl](https://github.com/Axolotl-QA/Axolotl)
- [final-run/finalrun-agent](https://github.com/final-run/finalrun-agent)
- [Agent-Field/SWE-AF](https://github.com/Agent-Field/SWE-AF)
- [modal-labs/devlooper](https://github.com/modal-labs/devlooper)
- [NihadMemmedli/quorvex_ai](https://github.com/NihadMemmedli/quorvex_ai)
- [bug0inc/passmark](https://github.com/bug0inc/passmark) (690 stars)
- [Codium-ai/cover-agent](https://github.com/Codium-ai/cover-agent)
- [Intelligent-CAT-Lab/FlakyDoctor](https://github.com/Intelligent-CAT-Lab/FlakyDoctor)
- [antiwork/shortest](https://github.com/antiwork/shortest)
- [langwatch/scenario](https://github.com/langwatch/scenario) (869 stars)
- [Applitools Eyes Visual AI Platform](https://applitools.com/platform/eyes/)
- [PactFlow Drift + AI Beta](https://pactflow.io/blog/)
- [apiaryio/dredd](https://github.com/apiaryio/dredd)
- [ctrf-io/ctrf](https://github.com/ctrf-io/ctrf) + [ctrf.io](https://ctrf.io)
- [ctrf-io/github-test-reporter](https://github.com/ctrf-io/github-test-reporter)
- [ctrf-io/ai-test-reporter](https://github.com/ctrf-io/ai-test-reporter)
- [daun/playwright-report-summary](https://github.com/daun/playwright-report-summary)
- [Trunk Flaky Tests](https://trunk.io/flaky-tests)
- [CloudBees Smart Tests / Launchable](https://www.cloudbees.com/capabilities/cloudbees-smart-tests)
- [BuildPulse](https://buildpulse.io)
- [web-DnA/navable-web-accessibility-mcp](https://github.com/web-DnA/navable-web-accessibility-mcp)
- [architzero/Aura-accessibility-scanner](https://github.com/architzero/Aura-accessibility-scanner)
- [Farhod75/ai-a11y-testing](https://github.com/Farhod75/ai-a11y-testing)
- [Aboudjem/sniff](https://github.com/Aboudjem/sniff)
- [zaproxy/zaproxy](https://github.com/zaproxy/zaproxy)
- [projectdiscovery/nuclei](https://github.com/projectdiscovery/nuclei) (28k+ stars)
- [swgee/BurpMCP](https://github.com/swgee/BurpMCP)
- [CyberWardion/ai-pentest-agent](https://github.com/CyberWardion/ai-pentest-agent)
- [hyangminj/ddl2data](https://github.com/hyangminj/ddl2data)
- [gourav-shokeen/chaoslake](https://github.com/gourav-shokeen/chaoslake)
- [SwissLife-OSS/squadron](https://github.com/SwissLife-OSS/squadron)
- [CopilotKit/aimock](https://github.com/CopilotKit/aimock) (570 stars)
- [dotenvx/dotenvx](https://github.com/dotenvx/dotenvx)
- [GitHub ai-testing topic](https://github.com/topics/ai-testing)
- [browserbase/stagehand](https://github.com/browserbase/stagehand) (22.5k stars) — NL browser automation with action caching + auto-reheal; accessibility-tree-based interactions
- [codeintegrity-ai/mutahunter](https://github.com/codeintegrity-ai/mutahunter) — LLM-generated semantic mutations; mutation score + surviving mutants report
- [NVIDIA/garak](https://github.com/NVIDIA/garak) — LLM vulnerability scanner; 50+ probes (jailbreak, data leak, DAN, encoding tricks)
- [LLAMATOR-Core/llamator](https://github.com/LLAMATOR-Core/llamator) — OWASP-LLM-aligned adversarial test battery for chatbot/LLM APIs
- [confident-ai/deepeval](https://github.com/confident-ai/deepeval) — RAG/LLM eval metrics: faithfulness, relevancy, hallucination; LLM-as-judge CI gate
- [promptfoo/promptfoo](https://github.com/promptfoo/promptfoo) — Prompt regression: YAML config → multi-model × multi-prompt comparison vs baseline
- [invariantlabs-ai/invariant](https://github.com/invariantlabs-ai/invariant) — Guardrail policy assertions for AI agents; rule-based pass/fail on tool call sequences
- [dubzzz/fast-check](https://github.com/dubzzz/fast-check) — Property-based testing: arbitrary generators + shrinking for JS/TS
- [trufflesecurity/trufflehog](https://github.com/trufflesecurity/trufflehog) — Secrets scanning across git history; live API validation to distinguish active credentials
- [great-expectations/great_expectations](https://github.com/great-expectations/great_expectations) (11.5k stars) — Data quality expectations: schema, null rates, distributions, drift detection
- [slsa-framework/slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator) — SLSA L3 provenance for npm/Docker artifacts; supply chain attestation CI gate
- [langfuse/langfuse](https://github.com/langfuse/langfuse) — LLM observability + online evaluation; production response quality monitoring
- [whylabs/langkit](https://github.com/whylabs/langkit) — LLM output telemetry: toxicity, sentiment drift, refusal rate, injection detection
- [agentops-ai/agentops](https://github.com/agentops-ai/agentops) — AI agent observability: token cost, latency, tool call tracing per run
- [Giskard-AI/giskard-oss](https://github.com/Giskard-AI/giskard-oss) — ML model vulnerability scanner + multi-turn red-team probing; OWASP-LLM aligned
- [jacopotagliabue/reclist](https://github.com/jacopotagliabue/reclist) — Behavioral slice testing for recommenders: per-slice accuracy, fairness invariants
- [mattzcarey/shippie](https://github.com/mattzcarey/shippie) (2.4k stars) — AI PR code review: secrets, edge cases, missing test coverage, LLM security issues
- [Codium-ai/pr-agent](https://github.com/Codium-ai/pr-agent) — LLM-powered PR review + coverage analysis; SARIF output for CI integration
- [google/oss-fuzz-gen](https://github.com/google/oss-fuzz-gen) — LLM-generated libFuzzer/AFL harnesses; ClusterFuzzLite integration
- [web-arena-x/webarena](https://github.com/web-arena-x/webarena) — AI agent trajectory benchmarking; task batteries for web agent evaluation

---

## Round 4 Backlog — AI/LLM Testing, Security Gates, Property-Based, Reporting

### 🔴 P1 — High Impact, Low Effort

#### BL-067 — Secrets Scanning Gate `[S]`
**Source:** [trufflesecurity/trufflehog](https://github.com/trufflesecurity/trufflehog)
**Target skill:** new `qa-secrets`
**Description:**
Runs TruffleHog across the full git history and staged diff, validating detected credentials against live APIs to distinguish verified (active) secrets from unverified false positives. Blocks commit/merge if verified secrets are found. Reports secret type, file, and line for each finding. Complementary to qa-security (DAST) — this is a static, pre-merge gate.

---

#### BL-068 — Accessibility Regression Diffing `[S]`
**Source:** Lost Pixel / Argos baseline-diff pattern applied to axe-core data
**Target skill:** `qa-a11y` enhancement
**Description:**
Stores an axe-core violation baseline per page after each run and diffs on the next CI run — surfacing only *newly introduced* violations rather than the full list every time. Prevents the "fix one violation, ship three new ones" pattern that makes a11y CI alerts noisy. Mirrors the visual regression baseline approach already used in qa-visual.

---

#### BL-069 — Test Coverage Delta Gate `[S]`
**Source:** Codecov CI gate pattern + deepeval coverage enforcement
**Target skill:** new `qa-coverage-gate`
**Description:**
After test runs, computes per-file coverage delta between base branch and PR branch using the project's existing coverage tooling (Jest/pytest/go test/dotnet). Blocks merge if changed files drop below a configurable threshold. Generates LLM-suggested test stubs for the uncovered lines alongside the CTRF block report.

---

#### BL-070 — Unified QA Dashboard / Sprint Report `[S]`
**Source:** ctrf-io ecosystem (already used) + cross-skill aggregation pattern
**Target skill:** new `qa-report`
**Description:**
Aggregates CTRF output from all qa-* skills run in a CI pipeline or sprint, producing a single executive HTML/Markdown report: pass/fail trend by skill, flakiness index, coverage delta, performance budget adherence, and an LLM-generated "top 3 risk areas" narrative. Posts as a PR comment or Slack/Teams message via existing CTRF reporters.

---

#### BL-071 — Test Cost Tracking & Budget Gate `[S]`
**Source:** [agentops-ai/agentops](https://github.com/agentops-ai/agentops) + deepeval cost tracking
**Target skill:** new `qa-cost`
**Description:**
Instruments all AI API calls made during QA runs (qa-visual, qa-explore, qa-simulate, etc.) using token-count hooks, aggregates total cost per skill and per PR, and can block CI if a run exceeds a configured budget. Provides a cost breakdown report alongside CTRF output — financial observability alongside functional observability.

---

#### BL-072 — CI Build Intelligence from OTel Traces `[S]`
**Source:** Honeycomb buildevents (already integrated) + AgentOps analysis pattern
**Target skill:** new `qa-ci-trace`
**Description:**
Analyzes the OTel build trace data (already emitted via Honeycomb buildevents) to identify: slowest test stages, flappy infrastructure steps, parallelism opportunities, and recurring failure patterns across the last N runs. Produces an actionable CI optimization report as a Markdown artifact. Closes the observability loop on the test infrastructure itself, not just the application.

---

#### BL-073 — Natural Language Spec-to-Test Generation `[S]`
**Source:** [antiwork/shortest](https://github.com/antiwork/shortest) + [Addepto/contextcheck](https://github.com/Addepto/contextcheck)
**Target skill:** new `qa-spec-to-test`
**Description:**
Reads product spec documents (Markdown PRDs, Confluence exports, plain text) and uses an LLM to extract testable acceptance criteria, generating a structured YAML test plan that can be handed to the existing qa-team skill battery for execution. Lower-friction alternative to qa-manager Mode A — no JIRA/Figma integration required.

---

#### BL-074 — Multi-Model Functional Assertion Consensus `[S]`
**Source:** [bug0inc/passmark](https://github.com/bug0inc/passmark)
**Target skill:** `qa-explore` + `qa-simulate` enhancement
**Description:**
Extends the existing multi-model visual consensus (already implemented for screenshots) to cover *functional* browser assertions: "did the checkout flow complete correctly?" judged by Claude and Gemini independently, with a third model arbitrating disagreements. Reduces false positives in exploratory and simulate runs without selector dependency.

---

### 🟡 P2 — Medium Effort / Significant Capability

#### BL-075 — LLM Mutation Testing `[M]`
**Source:** [codeintegrity-ai/mutahunter](https://github.com/codeintegrity-ai/mutahunter)
**Target skill:** new `qa-mutate`
**Description:**
Uses an LLM to generate semantically meaningful code mutations (beyond rule-based operator sets) then runs the existing test suite against each mutant to score fault-detection effectiveness. Produces a mutation score, list of surviving mutants (pointing to undertested logic), and suggested test additions. Language-agnostic; emits CTRF-compatible report.
- Complements qa-audit (which evaluates test quality heuristically) with a rigorous empirical measure

---

#### BL-076 — LLM Red-Teaming / Jailbreak Scan `[M]`
**Source:** [NVIDIA/garak](https://github.com/NVIDIA/garak) + [LLAMATOR-Core/llamator](https://github.com/LLAMATOR-Core/llamator)
**Target skill:** new `qa-llm-redteam`
**Description:**
Runs a structured battery of adversarial probes (prompt injection, jailbreaks, data leakage, hallucination snowballing, DAN-style attacks, encoding tricks) against an LLM API endpoint or chatbot surface deployed in the target application. Produces an OWASP-LLM-aligned vulnerability report with severity ratings. Distinct from qa-security (web-surface DAST) and qa-meta-eval (skill harness eval).

---

#### BL-077 — Promptfoo Prompt Regression `[M]`
**Source:** [promptfoo/promptfoo](https://github.com/promptfoo/promptfoo)
**Target skill:** new `qa-prompt-regression`
**Description:**
Reads a prompt config YAML listing prompt variants, models, and expected output assertions (exact match, regex, semantic similarity, LLM judge). Runs all combinations and compares results against a stored golden baseline, flagging regressions when model behavior changes across releases or model upgrades. Ships prompts as code with the same regression safety net as traditional code.

---

#### BL-078 — RAG / Chatbot Eval Pipeline `[M]`
**Source:** [confident-ai/deepeval](https://github.com/confident-ai/deepeval) + [Addepto/contextcheck](https://github.com/Addepto/contextcheck)
**Target skill:** new `qa-rag-eval`
**Description:**
Given a set of question-answer pairs and retrieval context, evaluates a RAG or chatbot endpoint for answer relevancy, faithfulness, contextual precision, and hallucination rate using LLM-as-judge metrics. Generates a structured eval report and can block CI if hallucination rate exceeds a configured threshold. Emits CTRF with per-metric pass/fail assertions.

---

#### BL-079 — AI Agent Guardrail Policy Testing `[M]`
**Source:** [invariantlabs-ai/invariant](https://github.com/invariantlabs-ai/invariant)
**Target skill:** new `qa-guardrails`
**Description:**
Exercises an AI agent under test by feeding it adversarial multi-step scenarios designed to trigger guardrail violations (unauthorized tool calls, data exfiltration patterns, prompt injection chains). Uses Invariant-style rule assertions to verify the agent rejects or escalates each unsafe scenario. Generates a pass/fail CTRF report per rule.
- Complements qa-llm-redteam (attack discovery) with structured *policy assertion testing* (guardrail correctness)

---

#### BL-080 — Multi-Turn Conversation Red-Team `[M]`
**Source:** [langwatch/scenario](https://github.com/langwatch/scenario) RedTeamAgent + [Giskard-AI/giskard-oss](https://github.com/Giskard-AI/giskard-oss)
**Target skill:** `qa-llm-redteam` Mode B or standalone `qa-redteam-conv`
**Description:**
Extends single-turn LLM red-teaming with multi-turn scenarios: an adversarial UserSimulator sends increasingly manipulative messages across a session to test whether guardrails hold under accumulated context pressure (session-level injection, context poisoning, gradual jailbreak escalation). Single-turn and multi-turn escalation are fundamentally different attack surfaces.

---

#### BL-081 — Scenario-Based Agent Conversation Testing `[M]`
**Source:** [langwatch/scenario](https://github.com/langwatch/scenario) (871 stars)
**Target skill:** new `qa-scenario`
**Description:**
Defines multi-turn conversation scenarios (YAML or code) with a UserSimulator generating messages until a goal state or max turns is reached; a JudgeAgent evaluates the agent under test at configurable checkpoints. Supports scripted and autopilot modes. Distinct from qa-simulate (UI journeys) — targets *conversational AI agents* (chatbots, copilots, support agents).

---

#### BL-082 — Property-Based API Fuzz Testing `[M]`
**Source:** [dubzzz/fast-check](https://github.com/dubzzz/fast-check) + Hypothesis (Python)
**Target skill:** `qa-api` enhancement or new `qa-fuzz`
**Description:**
Uses fast-check (JS/TS) or Hypothesis (Python) to generate random, adversarial, and edge-case inputs against API endpoints with automatic shrinking to the minimal reproducing example. Catches integer overflows, injection points, and boundary failures not modeled in schema — complements contract testing with property-based exploration.

---

#### BL-083 — AI Code Review PR Gate `[M]`
**Source:** [mattzcarey/shippie](https://github.com/mattzcarey/shippie) (2.4k stars) + [Codium-ai/pr-agent](https://github.com/Codium-ai/pr-agent)
**Target skill:** new `qa-code-review`
**Description:**
On every PR diff, runs an LLM-powered review flagging: exposed secrets, unhandled edge cases, performance anti-patterns, missing test coverage for changed logic, and prompt injection in code. Blocks merge on high-severity findings. Outputs SARIF + CTRF report. Fills the static/diff-time gap not covered by runtime testing skills.

---

#### BL-084 — Data Quality Expectations Gate `[M]`
**Source:** [great-expectations/great_expectations](https://github.com/great-expectations/great_expectations) (11.5k stars)
**Target skill:** new `qa-data`
**Description:**
Reads Great Expectations suite YAMLs (or generates them from data samples) and validates data pipelines, test fixtures, or database states against typed expectations (row counts, column distributions, null rates, schema conformance). Flags data drift that could cause production regressions. Extends qa-seed (seeding) with correctness validation.

---

#### BL-085 — Production Trace Shadow Testing `[M]`
**Source:** GoReplay (already integrated) + OTel semantic diffing pattern from langfuse
**Target skill:** `qa-observability` enhancement or new `qa-shadow`
**Description:**
Captures a sample of live production requests (via GoReplay or OTel span tails), replays them against a staging/canary deployment, and compares response semantics (status codes, shape, latency P99) against the production baseline. Surfaces divergences before full traffic cut-over. Extends the existing GoReplay integration with semantic diff.

---

#### BL-086 — Test Flakiness Root-Cause Analysis `[M]`
**Source:** CTRF flaky registry (already built) + qa-observability + git blame pattern
**Target skill:** new `qa-flaky-rca`
**Description:**
Given a CTRF report showing flaky tests (tracked by the flaky registry), uses LLM analysis of test logs, git blame on affected files, and OTel traces from flaky runs to generate a ranked list of likely root causes with remediation suggestions. Goes beyond flagging *which* tests are flaky to diagnosing *why*. Distinct from qa-heal (broken selectors) — targets timing/state/infrastructure flakiness.

---

#### BL-087 — Ephemeral Preview Environment QA Gate `[M]`
**Source:** LambdaTest AI-native quality validation + Stagehand CI integration pattern
**Target skill:** new `qa-preview`
**Description:**
On PR open, orchestrates spinning up an ephemeral deployment (via existing deploy config), running the full qa-team suite against it, posting a consolidated QA report as a PR comment, and tearing down on PR close. Owns the full preview environment lifecycle — the orchestration glue between preview deploy workflows and the QA skill battery.

---

#### BL-088 — Service Dependency Smoke Test `[S]`
**Source:** [SwissLife-OSS/squadron](https://github.com/SwissLife-OSS/squadron) + Testcontainers (already integrated)
**Target skill:** new `qa-deps`
**Description:**
Uses Testcontainers to spin up all declared service dependencies (from docker-compose or test-env.yml), runs lightweight smoke tests verifying each service is healthy and correctly wired (DB migrations applied, queue reachable, cache responsive), then tears down. Catches infrastructure drift before full integration tests run. Distinct from per-agent isolation already in qa-team.

---

#### BL-089 — GraphQL Schema Testing `[M]`
**Source:** [schemathesis/schemathesis](https://github.com/schemathesis/schemathesis) GraphQL support
**Target skill:** `qa-api` enhancement or new `qa-graphql`
**Description:**
Given a GraphQL schema, generates and executes tests covering: query/mutation correctness, deprecation warnings, N+1 detection via query complexity scoring, field-level null safety, and breaking-change detection between branches. Flags breaking changes as CI blockers. Fills the gap between REST contract testing (already covered) and GraphQL's distinct concerns.

---

#### BL-090 — Schema-Driven E2E Test Generation `[M]`
**Source:** MeterSphere AI test generation + Stagehand + OpenAPI→Playwright pattern
**Target skill:** `qa-web` enhancement or new `qa-generate`
**Description:**
Reads the project's OpenAPI/GraphQL schema and uses an LLM to generate a Playwright E2E test suite covering user-facing flows implied by the API surface, storing tests under version control for human review. Targets UI flows exercising the API indirectly — complementary to qa-manager Mode A (JIRA-driven) with a purely technical, schema-driven route.

---

#### BL-091 — LLM Output Production Monitoring `[M]`
**Source:** [whylabs/langkit](https://github.com/whylabs/langkit) + [comet-ml/opik](https://github.com/comet-ml/opik)
**Target skill:** new `qa-llm-monitor`
**Description:**
Instruments production LLM calls (via SDK wrapper or proxy) to collect response quality metrics: toxicity score, sentiment drift, refusal rate, prompt injection detection, response length trends. Fires alerts when metrics cross configured thresholds. Analogous to qa-observability for OTel traces but focused on LLM output content quality in production.

---

### 🔵 P3 — Research / Evaluate Further

#### BL-092 — Smart Test Selection / Impact Analysis `[L]`
**Source:** Buildkite Test Engine + Meta just-in-time testing approach (InfoQ 2025)
**Target skill:** new `qa-impact`
**Description:**
Analyzes the PR diff to determine which source modules changed, maps them to corresponding test files via import graph traversal and heuristic coverage data, and produces a minimized test-run plan. Can reduce CI runtime by 40-80% on large test suites. High value but requires deep language-specific static analysis integration.

---

#### BL-093 — AI Agent Trajectory Regression Testing `[M]`
**Source:** [web-arena-x/webarena](https://github.com/web-arena-x/webarena) + LangChain Trajectory pattern
**Target skill:** new `qa-trajectory`
**Description:**
Captures the sequence of tool calls an LLM agent makes during a task ("trajectory"), stores it as a golden file, and asserts on subsequent runs that the agent follows the expected reasoning path (exact, wildcard, or unordered). Flags efficiency regressions where a model version makes more tool calls for the same result. Relevant to teams shipping AI-powered features.

---

#### BL-094 — Behavioral Slice Testing for ML/Recommenders `[M]`
**Source:** [jacopotagliabue/reclist](https://github.com/jacopotagliabue/reclist) (473 stars)
**Target skill:** new `qa-behavioral`
**Description:**
Defines sliced behavioral invariants for ML model outputs (e.g., "accuracy on new users must not be more than 5% below accuracy on returning users"). Runs assertions across data slices and generates a metric report per slice. Relevant to teams shipping recommendation engines, search ranking, or ML-backed features where aggregate metrics mask systematic regressions.

---

#### BL-095 — LLM Fuzz Harness Generation `[L]`
**Source:** [google/oss-fuzz-gen](https://github.com/google/oss-fuzz-gen)
**Target skill:** new `qa-oss-fuzz-gen`
**Description:**
Given the project's source tree, uses an LLM to auto-generate libFuzzer/AFL harnesses for C/C++/Rust/Go entry points. Submits harnesses to ClusterFuzzLite and reports coverage delta and crashes found. Relevant to projects with native modules, WebAssembly, or security-sensitive parsing code. Complementary to qa-security (DAST, not protocol-level fuzzing).

---

#### BL-096 — Agent Benchmark Scoring `[L]`
**Source:** [AgentBench](https://github.com/AgentBench/agentbench)
**Target skill:** new `qa-benchmark-agent`
**Description:**
Runs the project's AI agent(s) through a standardized task battery using a three-layer scoring rubric: structural (output exists?), metric (tool call count, error rate), and behavioral (tool choice appropriateness, error recovery). Produces a comparative score across agent configurations. Supports model upgrade decisions ("can we switch Sonnet → Haiku for this agent?").

---

#### BL-097 — Property-Based UI Testing `[M]`
**Source:** [dubzzz/fast-check](https://github.com/dubzzz/fast-check) + Playwright integration
**Target skill:** `qa-explore` enhancement or new `qa-ui-fuzz`
**Description:**
Generates random but valid user action sequences using property-based arbitraries: random form values, random navigation paths, random click sequences with invariant assertions ("cart total is always non-negative"). Uses algorithmic shrinking to find minimal reproducing sequences. Distinct from qa-explore (AI-driven) — catches different bug classes with deterministic reproducibility.

---

#### BL-098 — SLSA Supply Chain Provenance Gate `[S]`
**Source:** [slsa-framework/slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator)
**Target skill:** new `qa-slsa`
**Description:**
Verifies SLSA provenance attestations for all build artifacts and third-party dependencies before release. Checks that build provenance chains to a trusted, non-tampered CI environment; flags unsigned or unverified artifacts. Integrates with the existing GitHub Actions workflow. Extends qa-security with supply-chain integrity verification.

---

## Round 4 Sources (2026-05-05)

- [langwatch/scenario](https://github.com/langwatch/scenario)
- [bug0inc/passmark](https://github.com/bug0inc/passmark)
- [browserbase/stagehand](https://github.com/browserbase/stagehand)
- [codeintegrity-ai/mutahunter](https://github.com/codeintegrity-ai/mutahunter)
- [NVIDIA/garak](https://github.com/NVIDIA/garak)
- [LLAMATOR-Core/llamator](https://github.com/LLAMATOR-Core/llamator)
- [confident-ai/deepeval](https://github.com/confident-ai/deepeval)
- [promptfoo/promptfoo](https://github.com/promptfoo/promptfoo)
- [invariantlabs-ai/invariant](https://github.com/invariantlabs-ai/invariant)
- [dubzzz/fast-check](https://github.com/dubzzz/fast-check)
- [trufflesecurity/trufflehog](https://github.com/trufflesecurity/trufflehog)
- [great-expectations/great_expectations](https://github.com/great-expectations/great_expectations)
- [slsa-framework/slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator)
- [langfuse/langfuse](https://github.com/langfuse/langfuse)
- [whylabs/langkit](https://github.com/whylabs/langkit)
- [agentops-ai/agentops](https://github.com/agentops-ai/agentops)
- [Giskard-AI/giskard-oss](https://github.com/Giskard-AI/giskard-oss)
- [jacopotagliabue/reclist](https://github.com/jacopotagliabue/reclist)
- [mattzcarey/shippie](https://github.com/mattzcarey/shippie)
- [Codium-ai/pr-agent](https://github.com/Codium-ai/pr-agent)
- [google/oss-fuzz-gen](https://github.com/google/oss-fuzz-gen)
- [web-arena-x/webarena](https://github.com/web-arena-x/webarena)

---

## Legend

- **P1** — Implement next sprint
- **P2** — Implement next quarter
- **P3** — Research / evaluate further
- `[S]` Small — 1–2 days
- `[M]` Medium — 3–5 days
- `[L]` Large — 1–2 weeks
