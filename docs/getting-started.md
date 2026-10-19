# Getting Started

## Prerequisites

- [Claude Code](https://claude.ai/code) — CLI or VS Code / JetBrains extension
- Node.js ≥ 18
- Git

## Install

```
/plugin marketplace add vslvslv/agentic-qa-team
/plugin install qa@agentic-qa-team
```

or in one step on Claude Code 2.1.275+: `/plugin install qa --marketplace vslvslv/agentic-qa-team`. From a shell: `claude plugin marketplace add vslvslv/agentic-qa-team && claude plugin install qa@agentic-qa-team`.

The plugin provides:
1. The `/qa:*` skills (run only when you type them)
2. The `qa:*` subagents that `/qa:team` dispatches
3. Hooks: an `rm` guard and a TypeScript typecheck scoped to the plugin's own skills and agents, plus a Stop hook that nudges you to re-run QA when test files change

Upgrading from the old symlink install (v1.17 and earlier)? Run `bash bin/uninstall` from your old clone first.

## First run

Open Claude Code in **your project**  and type:

```
/qa:team
```

The orchestrator detects your stack, asks which agents to run, and spawns them in parallel. Results stream in as each agent finishes.

Or run a specific agent directly:

| Command | Does what |
|---------|-----------|
| `/qa:team` | Auto-detects stack, runs all relevant agents |
| `/qa:web` | Web E2E tests (Playwright / Cypress / Selenium) |
| `/qa:api` | API contract + integration tests |
| `/qa:mobile` | Mobile tests (Detox / Appium / Maestro) |
| `/qa:perf` | Load and performance tests (k6 / JMeter / Locust) |
| `/qa:visual` | Visual regression screenshots |
| `/qa:audit` | Test quality audit — pyramid, isolation, flakiness |
| `/qa:heal` | Fix broken CI tests automatically |
| `/qa:a11y` | Accessibility audit (WCAG 2.1 AA) |
| `/qa:security` | DAST scan (ZAP MCP + Nuclei) |
| `/qa:explore` | Freeform exploratory smoke test |
| `/qa:seed` | Generate realistic test data from your DB schema |
| `/qa:component` | Storybook + Vitest component testing |
| `/qa:simulate` | Scenario-based simulation and red-team testing |
| `/qa:manager` | Epic → Playwright pipeline / Figma → TCMS test cases |
| `/qa:meta-eval` | Adversarial red-teaming eval of QA skill outputs |

## Requirements per skill

### All skills
- Claude Code CLI
- `npx playwright install` (Playwright browsers — used by `/qa:web`, `/qa:visual`, and Web Vitals fallback in `/qa:perf`)

### `/qa:web`
- **Playwright**: built-in (no extra install)
- **Cypress**: `npm install -D cypress`
- **Selenium WebDriver**: `npm install -D selenium-webdriver` + ChromeDriver in PATH

### `/qa:api`
- Running API server (set `API_URL` env var)
- Optional: `openapi.yaml` or `swagger.json` for contract testing
- Optional: `npm install -D dredd` (OpenAPI contract drift), `pip install schemathesis` (property-based fuzzing)

### `/qa:mobile`
- **React Native / Expo**: `npm install -D detox` + `brew install applesimutils` (macOS)
- **Native iOS/Android**: `npm install -D appium @wdio/cli` + Appium server
- **Cross-platform**: `curl -Ls "https://get.maestro.mobile.dev" | bash`
- iOS Simulator (macOS) or Android Emulator via Android Studio

### `/qa:perf`
- **k6**: `winget install k6` · `brew install k6` · `snap install k6`
- **JMeter**: `brew install jmeter` or download from jmeter.apache.org
- **Locust**: `pip install locust`
- Falls back to Playwright Web Vitals if none installed

### `/qa:a11y`
- No extra install — uses `@axe-core/playwright` (installed automatically if missing)
- Optional: `claude mcp add navable -- npx -y @navable/mcp` for richer remediation

### `/qa:security`
- **ZAP**: `docker pull softwaresecurityproject/zap-stable` (full DAST)
- **Nuclei**: `go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest`
- Falls back to lightweight HTTP probes if neither is installed

### `/qa:seed`
- Running database with `TEST_DATABASE_URL` set
- Schema: Prisma (`schema.prisma`), SQL migrations, or raw DDL files

### `/qa:manager`
- Mode A (Epic → Playwright): `JIRA_URL` + `JIRA_TOKEN` env vars (or manual input fallback)
- Mode B (Figma → TCMS): `FIGMA_TOKEN` env var; `TESTRAIL_URL`/`XRAY_URL` for TCMS push

## Updates

Plugin updates go through Claude Code's plugin manager:

```
/plugin marketplace update agentic-qa-team
/reload-plugins
```

Or enable auto-update for the `agentic-qa-team` marketplace under `/plugin` → Marketplaces. Each release bumps the plugin version; see `CHANGELOG.md` for what changed.
