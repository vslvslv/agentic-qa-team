# CI/CD Integration

## GitHub Actions — minimal setup

The simplest integration: run `/qa-team` as a step and get a CTRF report in your CI artifacts.

```yaml
# .github/workflows/qa.yml
name: QA Suite

on:
  pull_request:
  schedule:
    - cron: '0 2 * * *'   # nightly at 2am

jobs:
  qa:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with: { node-version: '20' }

      - name: Install Playwright browsers
        run: npx playwright install --with-deps

      - name: Start app
        run: npm run start:test &
        # Wait for server
        env:
          PORT: 3000

      - name: Run QA Suite
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          WEB_URL: http://localhost:3000
          API_URL: http://localhost:3001
          E2E_USER_EMAIL: ${{ secrets.TEST_EMAIL }}
          E2E_USER_PASSWORD: ${{ secrets.TEST_PASSWORD }}
        run: |
          npx @anthropic-ai/claude-code -p "/qa-team" \
            --output-format stream-json \
            2>&1 | tee qa-output.jsonl

      - name: Upload CTRF report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: qa-ctrf-report
          path: /tmp/qa-*-ctrf.json
```

---

## CTRF PR comments

After the QA run, post a rich pass/fail table as a PR comment using [ctrf-io/github-test-reporter](https://github.com/ctrf-io/github-test-reporter).

```yaml
      - name: Post PR test comment
        uses: ctrf-io/github-test-reporter@v1
        if: always()
        with:
          report-path: /tmp/qa-team-ctrf.json
          summary: true
          pull-request-comment: true
          job-summary: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## AI failure summaries

For each failing test, call Claude to explain the root cause in natural language — posted inline in the PR comment.

```yaml
      - name: AI failure summaries
        uses: ctrf-io/ai-test-reporter@v1
        if: failure()
        with:
          report-path: /tmp/qa-team-ctrf.json
          model: claude-sonnet-4-6
          api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          post-comment: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Auto-heal on CI failure

Run `/qa-heal` automatically when tests fail on a PR, before humans need to intervene.

```yaml
      - name: Auto-heal broken tests
        if: failure()
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          CI_FAILURE_LOG: qa-output.jsonl
        run: |
          npx @anthropic-ai/claude-code -p "/qa-heal"
```

The skill classifies the failure and either commits a fix, opens a review PR, or files a GitHub issue — no human required for routine selector breakage.

---

## Flaky test registry

Accumulate pass/fail history across runs to surface tests that flip randomly.

CTRF output is merged into `qa-flaky-registry.json` by `/qa-team` after each run. Commit this file to the repo (or store as a CI artifact and restore it at the start of each run):

```yaml
      - name: Restore flaky registry
        uses: actions/cache@v4
        with:
          path: qa-flaky-registry.json
          key: flaky-registry-${{ github.ref }}
          restore-keys: flaky-registry-

      # ... run QA ...

      - name: Save flaky registry
        uses: actions/cache/save@v4
        if: always()
        with:
          path: qa-flaky-registry.json
          key: flaky-registry-${{ github.ref }}
```

Tests with flake rate > 20% appear as `[FLAKY]` in reports rather than `[FAILED]`, keeping your CI signal clean.

---

## Honeycomb buildevents — CI pipeline tracing

Wrap each QA step in `buildevents cmd` to build an OTel trace of the entire build. Each phase becomes a child span visible in Honeycomb.

```yaml
      - name: Install buildevents
        run: go install github.com/honeycombio/buildevents@latest

      - name: Run QA with tracing
        env:
          BUILDEVENTS_APIKEY: ${{ secrets.HONEYCOMB_API_KEY }}
          BUILDEVENTS_DATASET: ci-builds
        run: |
          BUILD_ID="${{ github.run_id }}"
          buildevents build $BUILD_ID
          buildevents cmd $BUILD_ID qa-step -- \
            npx @anthropic-ai/claude-code -p "/qa-team"
```

---

## OTel test tracing (end-to-end)

Inject `traceparent` into Playwright tests so every test-driven HTTP call appears in your Jaeger/Tempo traces.

Set in your CI environment:

```yaml
env:
  OTEL_EXPORTER_OTLP_ENDPOINT: ${{ secrets.OTEL_ENDPOINT }}
  OTEL_SERVICE_NAME: qa-suite
```

On failure, the test report includes a clickable trace link: `Trace: http://jaeger:16686/trace/abc123`. The `qa-observability` sub-agent uses this trace to run automated RCA.

---

## Playwright multi-browser matrix

Generated `playwright.config.ts` includes all three browsers by default. To limit in CI for speed, set:

```yaml
env:
  QA_BROWSERS: chromium   # or "chromium,firefox" or "chromium,firefox,webkit"
```

---

## Chaos testing in CI (opt-in)

Run the chaos + load test in a dedicated nightly job, not on every PR:

```yaml
  chaos-test:
    runs-on: ubuntu-latest
    if: github.event_name == 'schedule'
    steps:
      # ... setup ...
      - name: Chaos resilience test
        env:
          QA_CHAOS: "1"
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: npx @anthropic-ai/claude-code -p "/qa-perf"
```

---

## Version gate

The repo's own CI enforces that every skill content change bumps `VERSION` and adds a `CHANGELOG` entry. If you're running qa-agentic-team in CI as part of another project, this gate only applies to contributors of the qa-agentic-team repo itself.

```yaml
# Enforced by .github/workflows/version-gate.yml and skill-docs.yml
# Contributors: see docs/contributing/contributing.md
```
