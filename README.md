# QA Agentic Team

A suite of Claude Code skills that give any project an autonomous QA team. One command launches specialized agents for web, API, mobile, performance, visual, accessibility, security, and more — each discovering your app's structure, generating test specs, executing them, and reporting results.

> **Version:** see [VERSION](VERSION) · **Full docs:** [docs/](docs/index.md)

---

## Skills

| Command | What it does |
|---------|--------------|
| `/qa-team` | Orchestrator — auto-detects project type, spawns all relevant agents in parallel, aggregates results |
| `/qa-web` | Web E2E — Playwright, Cypress, or Selenium; discovers routes, writes specs, executes |
| `/qa-api` | API contract tests — language-driven (JS/TS, Java, Python, C#, Ruby); REST + GraphQL + OpenAPI |
| `/qa-mobile` | Mobile tests — Detox (RN/Expo), Appium+WebDriverIO (native), or Maestro (cross-platform) |
| `/qa-perf` | Performance — k6, JMeter, or Locust; ramp-up profiles, p50/p95/p99 thresholds |
| `/qa-visual` | Visual regression — Playwright screenshots diffed against baselines; masks dynamic content |
| `/qa-a11y` | Accessibility — axe-core + Playwright ARIA assertions + WCAG 2.2 AA reporting |
| `/qa-security` | Security — OWASP ZAP DAST + Nuclei CVE scanning; auth bypass + injection checks |
| `/qa-explore` | Exploratory testing — parallel swarm agents autonomously navigate and probe the app |
| `/qa-component` | Component tests — Storybook interaction tests + React Testing Library unit coverage |
| `/qa-seed` | Test data seeding — schema-aware (DDL / Prisma / TypeORM); clean or chaos mode |
| `/qa-heal` | Self-healing — classifies CI failures (broken selector, timing, logic) and commits fixes |
| `/qa-observability` | Observability RCA — reads OTel traces / Loki logs to root-cause QA failures |
| `/qa-simulate` | User journey simulation — generates realistic user flows and executes them end-to-end |
| `/qa-audit` | Methodology audit — scores test suite across pyramid balance, isolation, flakiness, naming, CI |
| `/qa-refine` | Tool research — generates scored best-practice guides for Playwright, Cypress, k6, Appium, etc. |
| `/qa-methodology-refine` | Methodology research — generates guides for TDD, BDD, test pyramid, contract testing, etc. |
| `/lang-refine` | Language best practices — GoF patterns, SOLID, Clean Code for TS, Java, Python, C#, Ruby |
| `/qa-meta-eval` | Adversarial eval — red-teams QA skill outputs using UserSimulatorAgent + JudgeAgent |
| `/qa-manager` | Requirements bridge — Epic → Playwright skeletons (Mode A) · Figma → TCMS test cases (Mode B) |

---

## Security & supply-chain skills

| Command | What it does |
|---------|--------------|
| `/qa-secrets` | Secrets scanning — TruffleHog git history + staged diff; verified secrets = FAIL |
| `/qa-sca` | Software composition analysis — Syft SBOM + Grype CVE + license compliance; delta mode |
| `/qa-slsa` | SLSA provenance attestation — verifies build artifacts via `gh attestation verify` |
| `/qa-env-parity` | Env var drift — detects required-missing / stale-orphaned keys across dev/staging/prod |

---

## Test quality DX skills

| Command | What it does |
|---------|--------------|
| `/qa-test-lint` | Static test smell scanner — sleep(), assertion-free, permanent skips, magic numbers |
| `/qa-test-order` | Randomized test order — detects order-dependent failures (shared global state) |
| `/qa-test-docs` | Test documentation generator — LLM reads test files → human-readable Markdown docs |
| `/qa-coverage-gate` | Per-file coverage delta gate; LLM stub suggestions for uncovered lines |

---

## Reporting & AI gate skills

| Command | What it does |
|---------|--------------|
| `/qa-report` | Unified QA dashboard — aggregates all CTRF files → sprint/PR report with LLM risk narrative |
| `/qa-cost` | Token cost tracking across QA runs; optional CI budget gate |
| `/qa-eval-gate` | Eval-driven CI gate — evals/ pass-rate must meet threshold before merge |
| `/qa-intent-assert` | NL code property assertions — `*.intent.yaml` evaluated by LLM judge |

---

## Web / mobile / infra skills

| Command | What it does |
|---------|--------------|
| `/qa-geo` | Playwright timezone + geolocation simulation matrix — catches locale/DST bugs |
| `/qa-deeplinks` | Deep link validator — parses AASA, assetlinks.json, AndroidManifest; cold-start + in-app |
| `/qa-deps` | Service dependency smoke test — docker-compose health checks before integration tests |
| `/qa-ci-trace` | CI build trace analysis (OTel/Honeycomb) → ranked optimization recommendations |
| `/qa-spec-to-test` | Markdown PRD/spec → YAML test plan → Playwright skeleton spec files |

---

## Install

```bash
git clone https://github.com/vslvslv/agentic-qa-team
cd qa-agentic-team
bash bin/setup
```

Skills are installed as symlinks in `~/.claude/skills/` — edits stay in sync with the repo automatically.

## Quick start

Open Claude Code in your project and type:

```
/qa-team
```

The orchestrator auto-detects your stack and spawns the relevant agents. Or invoke individual skills directly (`/qa-web`, `/qa-api`, `/qa-perf`, etc.).

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started.md) | Install, first run, per-skill requirements, environment variables |
| [Skills Overview](docs/skills/overview.md) | All skills grouped by category with detailed capability lists |
| [Advanced Features](docs/skills/advanced-features.md) | AI visual consensus, VLM mobile, OTel tracing, chaos testing, aimock, Bencher, and more |
| [Workflows](docs/guides/workflows.md) | Pre-PR, nightly, sprint kickoff, Epic→Playwright, self-healing, and other recipes |
| [CI/CD Integration](docs/guides/ci-cd-integration.md) | GitHub Actions setup, CTRF reports, AI failure summaries, auto-heal, flaky registry |
| [Configuration](docs/guides/configuration.md) | All env vars, JIRA/Figma/TCMS/observability integration config |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and fixes |
| [Contributing](docs/contributing/contributing.md) | Workflow, versioning rules, code style, PR requirements |
| [Adding a Skill](docs/contributing/adding-a-skill.md) | Complete step-by-step checklist for creating a new skill |
