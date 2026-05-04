# Configuration Reference

All environment variables, integration configs, and tool setup.

---

## Core environment variables

Set these in your project's `.env.local` (or export before running Claude Code).

### Auth + URLs

| Variable | Default | Used by |
|----------|---------|---------|
| `WEB_URL` | `http://localhost:3000` | `/qa-web`, `/qa-visual`, `/qa-perf`, `/qa-a11y`, `/qa-explore` |
| `API_URL` | `http://localhost:3001` | `/qa-api`, `/qa-perf`, `/qa-security` |
| `E2E_USER_EMAIL` | `admin@example.com` | All agents with auth flows |
| `E2E_USER_PASSWORD` | `password123` | All agents with auth flows |

### Behaviour flags

| Variable | Values | Default | Effect |
|----------|--------|---------|--------|
| `QA_FAST_MODE` | `0` / `1` | `0` | Skip deep phases; smoke tests only |
| `QA_DEEP_MODE` | `0` / `1` | `0` | Force all agents + audit + explore |
| `QA_DEEP_FUZZ` | `0` / `1` | `0` | Enable RESTler stateful REST fuzzing (`/qa-api`) |
| `QA_SECURITY` | `0` / `1` | `0` | Enable OWASP OFFAT security fuzzing (`/qa-api`, `/qa-security`) |
| `QA_CHAOS` | `0` / `1` | `0` | Enable LitmusChaos concurrent resilience test (`/qa-perf`) |
| `QA_BROWSERS` | `chromium`, `firefox`, `webkit` or comma-separated | `chromium,firefox,webkit` | Which browsers to run (`/qa-web`) |
| `QA_EXTRA_PATHS` | Comma-separated paths | (none) | Additional project directories for multi-repo setups (`/qa-team`) |
| `QA_META_TARGET` | Skill name | `all` | Scope adversarial eval to one skill (`/qa-meta-eval`) |

### Test data

| Variable | Default | Effect |
|----------|---------|--------|
| `TEST_DATABASE_URL` | (none) | Database connection string (`/qa-seed`, `/qa-api`) |
| `QA_SEED_ROWS` | `100` | Rows to generate per table (`/qa-seed`) |
| `QA_SEED_MODE` | `clean` | `clean` or `chaos` — chaos injects nulls/duplicates/bad dates |

---

## Observability integrations

### OpenTelemetry

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://your-otel-collector:4318
export OTEL_SERVICE_NAME=qa-suite
```

When set: `/qa-web` and `/qa-api` inject `traceparent` headers; `/qa-observability` RCA sub-agent auto-activates on failures.

### Jaeger / Tempo / Loki

```bash
export JAEGER_URL=http://localhost:16686        # or your Jaeger host
export TEMPO_URL=http://localhost:3200          # Grafana Tempo
export LOKI_URL=http://localhost:3100           # Grafana Loki
```

Auto-detected via health check if not set (probes default localhost ports).

### Bencher (continuous benchmarking)

```bash
export BENCHER_API_TOKEN=your-token
export BENCHER_PROJECT=my-project
```

When set: `/qa-perf` pushes k6 results after each run and fetches trend history for regression narrative.

---

## JIRA integration (`/qa-manager` Mode A)

```bash
export JIRA_URL=https://yourorg.atlassian.net
export JIRA_TOKEN=your-api-token          # Personal API token from id.atlassian.com
export JIRA_EPIC_ID=PROJ-100             # Optional: pass at skill invocation instead
```

Without these, `/qa-manager` falls back to manual input via `AskUserQuestion`.

---

## Figma integration (`/qa-manager` Mode B)

```bash
export FIGMA_TOKEN=your-figma-personal-access-token  # From figma.com/settings
```

Without this, the skill prompts you to share screenshots manually.

---

## TestRail / Xray TCMS (`/qa-manager`)

```bash
# TestRail
export TESTRAIL_URL=https://yourorg.testrail.io
export TESTRAIL_USER=your@email.com
export TESTRAIL_TOKEN=your-api-key
export TESTRAIL_SECTION_ID=1        # Section ID to push test cases into

# Xray (Jira Cloud)
export XRAY_URL=https://xray.cloud.getxray.app
export XRAY_CLIENT_ID=your-client-id
export XRAY_CLIENT_SECRET=your-client-secret
```

Without TCMS config: `/qa-manager` saves test cases as Markdown to `test-specs/`.

---

## Performance integrations

```bash
# Pyroscope (profiling during load tests)
export PYROSCOPE_URL=http://localhost:4040

# GoReplay
export QA_REPLAY_MODE=1            # Replay from requests.gor
export QA_GOREPLAY_CAPTURE=1       # Capture mode (production traffic)
```

---

## Security integrations

```bash
export ZAP_API_KEY=your-zap-key    # If ZAP running with API auth
export NUCLEI_TEMPLATES_PATH=/path/to/custom/templates
```

---

## Visual testing integrations

```bash
export GEMINI_API_KEY=your-key     # Enables multi-model AI visual consensus
export VISUAL_BASELINE_DIR=./visual-baselines   # Where baselines are stored
export VISUAL_DIFF_THRESHOLD=0.001              # pixelmatch: below this = auto-pass

# Cloud visual services (optional — Lost Pixel is used as self-hosted fallback)
export CHROMATIC_PROJECT_TOKEN=your-token
export APPLITOOLS_API_KEY=your-key
```

---

## Mobile integrations

```bash
export DEVICE_ID=emulator-5554      # Android emulator ID
export PLATFORM=android             # or ios
export APP_PATH=./android/app-debug.apk
```

---

## Playwright config

Agents look for `playwright.config.ts` at project root and create one if missing. Recommended baseline:

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  reporter: [['html'], ['json', { outputFile: 'test-results/results.json' }]],
  use: {
    baseURL: process.env.WEB_URL || 'http://localhost:3000',
    storageState: 'e2e/.auth/user.json',
    trace: 'on-first-retry',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'setup', testMatch: /auth\.setup\.ts/ },
    {
      name: 'chromium',
      dependencies: ['setup'],
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      dependencies: ['setup'],
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      dependencies: ['setup'],
      use: { ...devices['Desktop Safari'] },
    },
  ],
  snapshotDir: './visual-baselines',
});
```

Set `QA_BROWSERS=chromium` in CI to run only one browser for speed.

---

## Testcontainers (`test-env.yml`)

For parallel agent isolation, declare services in `test-env.yml` at project root:

```yaml
# test-env.yml
services:
  - name: postgres
    image: postgres:16
    env:
      POSTGRES_DB: testdb
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
    ports:
      - 5432
    healthCheck:
      command: pg_isready -U test
      interval: 2s
      retries: 10

  - name: redis
    image: redis:7-alpine
    ports:
      - 6379
```

When detected by `/qa-team`, each sub-agent receives isolated `DB_URL` and `REDIS_URL` env vars.

---

## Stop hook (re-run nudge)

The Stop hook fires at the end of each Claude Code session. If test files changed since the last QA run, it prints a passive nudge.

Install (or re-install if schema was wrong):

```bash
bash bin/setup --hook-only
```

To verify it's correctly installed:

```bash
jq '.hooks.Stop' ~/.claude/settings.json
# Should show: [{ "matcher": "main-agent", "hooks": [{ "type": "command", "command": "..." }] }]
```
