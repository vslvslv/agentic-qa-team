# Getting Started

## Prerequisites

- [Claude Code](https://claude.ai/code) — CLI or VS Code / JetBrains extension
- Node.js ≥ 18
- Git

## Install

```bash
git clone https://github.com/vslvslv/agentic-qa-team
cd qa-agentic-team
bash bin/setup
```

The setup script:
1. Creates symlinks in `~/.claude/skills/` (one per skill)
2. Installs sub-agents to `~/.claude/agents/`
3. Optionally wires a Stop hook that nudges you to re-run QA when test files change

Answer the hook prompt — you can always add it later with `bash bin/setup --hook-only`.

## First run

Open Claude Code in **your project** (not the qa-agentic-team repo) and type:

```
/qa-team
```

The orchestrator detects your stack, asks which agents to run, and spawns them in parallel. Results stream in as each agent finishes.

Or run a specific agent directly:

| Command | Does what |
|---------|-----------|
| `/qa-team` | Auto-detects stack, runs all relevant agents |
| `/qa-web` | Web E2E tests (Playwright / Cypress / Selenium) |
| `/qa-api` | API contract + integration tests |
| `/qa-mobile` | Mobile tests (Detox / Appium / Maestro) |
| `/qa-perf` | Load and performance tests (k6 / JMeter / Locust) |
| `/qa-visual` | Visual regression screenshots |
| `/qa-audit` | Test quality audit — pyramid, isolation, flakiness |
| `/qa-heal` | Fix broken CI tests automatically |
| `/qa-a11y` | Accessibility audit (WCAG 2.1 AA) |
| `/qa-security` | DAST scan (ZAP MCP + Nuclei) |
| `/qa-explore` | Freeform exploratory smoke test |
| `/qa-seed` | Generate realistic test data from your DB schema |
| `/qa-component` | Storybook + Vitest component testing |
| `/qa-simulate` | Scenario-based simulation and red-team testing |
| `/qa-manager` | Epic → Playwright pipeline / Figma → TCMS test cases |
| `/qa-meta-eval` | Adversarial red-teaming eval of QA skill outputs |
| `/qa-refine` | Research and update tool best-practice guides |
| `/qa-methodology-refine` | Research and update methodology guides |
| `/lang-refine` | Research and update language pattern guides |

## Requirements per skill

### All skills
- Claude Code CLI
- `npx playwright install` (Playwright browsers — used by `/qa-web`, `/qa-visual`, and Web Vitals fallback in `/qa-perf`)

### `/qa-web`
- **Playwright**: built-in (no extra install)
- **Cypress**: `npm install -D cypress`
- **Selenium WebDriver**: `npm install -D selenium-webdriver` + ChromeDriver in PATH

### `/qa-api`
- Running API server (set `API_URL` env var)
- Optional: `openapi.yaml` or `swagger.json` for contract testing
- Optional: `npm install -D dredd` (OpenAPI contract drift), `pip install schemathesis` (property-based fuzzing)

### `/qa-mobile`
- **React Native / Expo**: `npm install -D detox` + `brew install applesimutils` (macOS)
- **Native iOS/Android**: `npm install -D appium @wdio/cli` + Appium server
- **Cross-platform**: `curl -Ls "https://get.maestro.mobile.dev" | bash`
- iOS Simulator (macOS) or Android Emulator via Android Studio

### `/qa-perf`
- **k6**: `winget install k6` · `brew install k6` · `snap install k6`
- **JMeter**: `brew install jmeter` or download from jmeter.apache.org
- **Locust**: `pip install locust`
- Falls back to Playwright Web Vitals if none installed

### `/qa-a11y`
- No extra install — uses `@axe-core/playwright` (installed automatically if missing)
- Optional: `claude mcp add navable -- npx -y @navable/mcp` for richer remediation

### `/qa-security`
- **ZAP**: `docker pull softwaresecurityproject/zap-stable` (full DAST)
- **Nuclei**: `go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest`
- Falls back to lightweight HTTP probes if neither is installed

### `/qa-seed`
- Running database with `TEST_DATABASE_URL` set
- Schema: Prisma (`schema.prisma`), SQL migrations, or raw DDL files

### `/qa-manager`
- Mode A (Epic → Playwright): `JIRA_URL` + `JIRA_TOKEN` env vars (or manual input fallback)
- Mode B (Figma → TCMS): `FIGMA_TOKEN` env var; `TESTRAIL_URL`/`XRAY_URL` for TCMS push

## Updates

Skills auto-check for updates on each run. To check manually:

```bash
bash bin/qa-team-update-check
# UPGRADE_AVAILABLE: 1.14.0.0 → 1.15.0.0
#   cd ~/qa-agentic-team && git pull && bash bin/setup
```

Or just run `git pull && bash bin/setup` — setup is idempotent and safe to re-run.
