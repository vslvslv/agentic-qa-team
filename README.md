# QA Agentic Team

A suite of Claude Code skills that give any project an autonomous QA team. One command launches specialized agents for web, API, mobile, performance, and visual testing — each discovering your app's structure, generating test specs, executing them, and reporting results.

## Skills

| Skill | Command | What it does |
|-------|---------|--------------|
| **Orchestrator** | `/qa-team` | Auto-detects project type, spawns all relevant agents in parallel, aggregates results into a unified quality report |
| **Web E2E** | `/qa-web` | Discovers pages/routes, writes Playwright specs, executes against Chromium, reports coverage |
| **API** | `/qa-api` | Reads OpenAPI/routes, generates HTTP contract tests (status codes, schema, auth), executes via Playwright request context |
| **Mobile** | `/qa-mobile` | Detects RN/Expo (Detox) or native iOS/Android (Appium/WebDriverIO), generates screen tests, runs on simulator/emulator |
| **Performance** | `/qa-perf` | Writes k6 load scripts + Playwright Web Vitals tests, runs with ramp-up profiles, reports p50/p95/p99 |
| **Visual** | `/qa-visual` | Captures Playwright screenshots, diffs against baselines, masks dynamic content, reports pixel regressions |

## Install

### For users

```bash
git clone https://github.com/vslvslv/agentic-qa-team
cd qa-agentic-team
bash bin/setup
```

Skills are installed as **symlinks** in `~/.claude/skills/` — keeping them in sync with the repo.

To check for updates later:

```bash
bash bin/qa-team-update-check
# UPGRADE_AVAILABLE: 1.0.0.0 → 1.1.0.0
#   cd ~/qa-agentic-team && git pull && bash bin/setup
```

### For contributors

```bash
git clone https://github.com/vslvslv/agentic-qa-team
cd qa-agentic-team
bash bin/dev-setup      # creates ~/.claude/skills/qa-agentic-team → this repo
```

In dev mode, a single namespace symlink is created (`~/.claude/skills/qa-agentic-team → repo`). Edits to `SKILL.md.tmpl` files take effect after regenerating docs — no re-install needed:

```bash
# Edit source
vim qa-web/SKILL.md.tmpl

# Regenerate SKILL.md
bash scripts/gen-skill-docs.sh

# Done — skills update immediately
```

When finished: `bash bin/dev-teardown`

## Quick start

Open Claude Code in your project and type:

```
/qa-team
```

The orchestrator auto-detects your stack and asks which agents to run.

Or run individual agents:

```
/qa-web          # E2E browser tests only
/qa-api          # API contract tests only
/qa-mobile       # Mobile tests only
/qa-perf         # Load/performance tests only
/qa-visual       # Visual regression only
```

## Requirements

### All agents
- Claude Code CLI
- Node.js ≥ 18
- `npx playwright install` (Playwright browsers)

### `/qa-mobile`
- **React Native / Expo**: [Detox](https://wix.github.io/Detox/) (`npm install -D detox`)
- **Native iOS/Android**: [Appium](https://appium.io/) + [WebDriverIO](https://webdriver.io/) (`npm install -D appium @wdio/cli`)
- iOS Simulator (macOS only) or Android Emulator via Android Studio

### `/qa-perf`
- [k6](https://k6.io/): `winget install k6` (Windows) · `brew install k6` (macOS) · `snap install k6` (Linux)
- Or: Playwright Web Vitals tests (no extra install needed — falls back automatically)

## Configuration

### Environment variables

| Variable | Default | Used by |
|---|---|---|
| `E2E_USER_EMAIL` | `admin@example.com` | All agents |
| `E2E_USER_PASSWORD` | `password123` | All agents |
| `API_URL` | `http://localhost:3001` | `/qa-api`, `/qa-perf` |
| `WEB_URL` | `http://localhost:3000` | `/qa-web`, `/qa-visual`, `/qa-perf` |

Set these in your project's `.env.local` or export them before running.

### Playwright config

Agents look for `playwright.config.ts` at the project root and create one if missing. For best results, configure `baseURL` and `storageState`:

```typescript
import { defineConfig } from "@playwright/test";

export default defineConfig({
  use: {
    baseURL: process.env.WEB_URL || "http://localhost:3000",
    storageState: "e2e/.auth/user.json",
  },
  projects: [
    { name: "setup", testMatch: /auth\.setup/ },
    {
      name: "chromium",
      dependencies: ["setup"],
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  snapshotDir: "./visual-baselines",
});
```

## Design principles

- **Additive only** — agents append `test.describe` blocks to existing spec files; never delete them
- **Idempotent** — safe to run multiple times; fills gaps without creating duplicates
- **Portable** — Playwright request context for API tests; no extra test runner dependency
- **Progressive degradation** — if k6/Detox/Appium is missing, agents write tests and document setup steps
- **Stable selectors** — enforces `getByRole`, `getByLabel`, `getByTestId`; never raw CSS

## Repository structure

```
qa-agentic-team/
├── qa-team/              ← /qa-team orchestrator skill
│   ├── SKILL.md          ← generated (do not edit)
│   └── SKILL.md.tmpl     ← source (edit this)
├── qa-web/               ← /qa-web Playwright E2E skill
│   ├── SKILL.md
│   └── SKILL.md.tmpl
├── qa-api/               ← /qa-api REST + GraphQL skill
├── qa-mobile/            ← /qa-mobile Detox / Appium skill
├── qa-perf/              ← /qa-perf k6 + Web Vitals skill
├── qa-visual/            ← /qa-visual screenshot diffing skill
├── bin/
│   ├── setup             ← install: creates symlinks in ~/.claude/skills/
│   ├── dev-setup         ← dev mode: single namespace symlink
│   ├── dev-teardown      ← remove dev symlink
│   ├── qa-team-update-check  ← poll GitHub for new version
│   └── qa-team-next-version  ← calculate next 4-part semver
├── scripts/
│   ├── gen-skill-docs.sh     ← SKILL.md.tmpl → SKILL.md
│   └── check-skill-docs.sh   ← CI freshness gate
├── .github/workflows/
│   ├── version-gate.yml      ← validates VERSION + CHANGELOG on PRs
│   └── skill-docs.yml        ← fails if SKILL.md is stale vs .tmpl
├── VERSION               ← 4-part semver (1.0.0.0)
├── CHANGELOG.md
├── conductor.json
└── package.json
```

## Contributing

### Versioning

This repo uses 4-part semantic versioning: `MAJOR.MINOR.PATCH.MICRO`

| Bump | When | Command |
|------|------|---------|
| `major` | Breaking changes to skill interface | `bash bin/qa-team-next-version major` |
| `minor` | New skill or significant new capability | `bash bin/qa-team-next-version minor` |
| `patch` | Bug fix or improvement to existing skill | `bash bin/qa-team-next-version patch` |
| `micro` | Typo fix, minor wording change | `bash bin/qa-team-next-version micro` |

Every PR that changes skill content **must** bump VERSION and add a CHANGELOG entry. The `version-gate` CI job enforces this.

### Editing skills

1. Edit `<skill>/SKILL.md.tmpl` — never edit `SKILL.md` directly
2. Regenerate: `bash scripts/gen-skill-docs.sh`
3. Bump version: `bash bin/qa-team-next-version patch > VERSION`
4. Add CHANGELOG entry
5. Open PR — CI validates docs freshness and version bump

### Skill format

Each skill follows the Claude Code SKILL.md spec:

```markdown
---
name: qa-<name>
version: X.Y.Z.W
description: |
  <what it does — include trigger phrases>
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
---

## Preamble (run first)
...

## Phase N — <phase name>
...
```
