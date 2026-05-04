# Advanced Features

The skills include 20+ advanced capabilities enabled by integrations with best-in-class open-source tools. Most are opt-in via environment variables or auto-activated when the integration is detected.

---

## AI-powered testing

### AI Visual Consensus (multi-model)
*Skills: `/qa-visual`*

When a visual diff is detected, two AI models independently judge whether it's a meaningful regression or noise (font rendering, dynamic content, timestamps). A third model resolves disagreements. A SHA-based verdict cache avoids re-judging identical diffs.

**Why**: Pixel-diff alone generates high false-positive rates. Two-model agreement cuts this dramatically.  
**Enable**: Set `GEMINI_API_KEY` — triggers automatically when diff ratio is 0.1–20%.

---

### DOM Metric Extraction
*Skills: `/qa-visual`*

Instead of sending full screenshots to Claude on every run, `page.evaluate()` extracts structured layout metrics (bounding boxes, computed colors, font sizes, text) for key selectors. Claude diffs the JSON — only escalates to screenshot+VLM when metrics diverge.

**Why**: Full screenshots cost ~1000 tokens each. DOM metrics cost ~50. Major reduction for frequent runs.  
**Enable**: Automatic. Optionally define `.visual-spec/<page>.json` with expected metric ranges.

---

### TestZeus Hercules — Gherkin + DOM Distillation
*Skills: `/qa-web`*

Converts Gherkin `.feature` files to E2E tests at runtime using DOM Distillation — only relevant page elements are extracted. No hardcoded selectors; the agent re-discovers how to perform each action every run.

**Why**: Tests survive UI refactors because the Gherkin intent is the stable artifact.  
**Enable**: Automatic when `.feature` files detected and `hercules` in PATH.

---

### Natural Language Test Mode
*Skills: `/qa-web`*

Write a `tests.nl.md` file of plain-English test descriptions. Claude interprets each as Playwright actions at runtime — no selector code to maintain.

```markdown
# tests.nl.md
Login as admin, navigate to Users, verify the user count badge updates after adding a user
Complete checkout with a Visa card ending in 4242, verify order confirmation email
```

**Enable**: Automatic when `tests.nl.md` is found in the project root.

---

## Mobile testing (VLM layer)

### Midscene.js — Pure-Vision Mobile Testing
*Skills: `/qa-mobile`*

Abandons selectors entirely. All element localization uses screenshot reasoning via VLM (Qwen3-VL, UI-TARS, Gemini). Works on iOS, Android, React Native, Flutter — native pixels, no brittle selector drift.

```typescript
// Instead of: await element(by.id('login-btn')).tap()
await midscene.aiAction("tap the Login button")
```

**Enable**: `npm install @midscene/android` (or `@midscene/ios-client`). Used as fallback when standard selectors fail.

---

### OmniParser — Computer Vision for Canvas UIs
*Skills: `/qa-mobile`*

When accessibility labels are absent (Flutter canvas, games, custom-drawn UIs), device screenshots are piped through OmniParser — a CV model that parses any UI into labeled interactive regions.

**Enable**: `docker run -p 8000:8000 microsoft/omniparser`. Auto-triggered when accessibility tree returns 0 elements.

---

### Mobile-Agent Reflector
*Skills: `/qa-mobile`*

On step failure, Claude receives the failed screenshot + error and generates a revised action plan. Max 2 retries per step. Tests with > 1 reflection per run are flagged as flakiness candidates.

**Enable**: Automatic. Reflection rate visible in per-test report.

---

## API testing advanced layer

### Tracetest — Span Assertions
*Skills: `/qa-api`*

Assert on the distributed trace emitted by the system, not just the HTTP response. Write span assertions alongside HTTP tests:

```yaml
# Generated Tracetest YAML
type: Test
spec:
  trigger:
    type: http
    httpRequest: { url: "${API_URL}/checkout", method: POST }
  specs:
    - selector: span[tracetest.span.type="database"]
      assertions:
        - attr:duration < 100ms
```

**Enable**: Requires Tracetest server + OTel-instrumented backend.

---

### RESTler — Stateful REST Fuzzing
*Skills: `/qa-api`*

Infers producer-consumer dependencies from OpenAPI spec (e.g., `POST /users` returns `id` that `DELETE /users/{id}` consumes). Fuzzes state-machine paths — discovers resource leaks and state-transition 500s.

**Enable**: `QA_DEEP_FUZZ=1`. Runs via Docker (`mcr.microsoft.com/restlerfuzzer/restler:latest`).

---

### Keploy — eBPF API Traffic Recording
*Skills: `/qa-api`, `/qa-heal`*

Records real API traffic at the network layer using eBPF and auto-generates tests + mocks from recordings. When APIs change, re-record against the new behavior — the "test update" is re-running the recorder.

**Enable**: `QA_KEPLOY_RECORD=1` to record; stored fixtures auto-detected for replay.

---

### Pact Consumer Contract Verification
*Skills: `/qa-api`*

Runs provider verification when `*.pact.json` files are detected. Breaking changes visible before deployment.

**Enable**: Automatic when pact files found.

---

## Observability integration

### OTel `traceparent` Injection
*Skills: `/qa-web`, `/qa-api`*

In Playwright's `beforeEach`, creates an OTel span for the test and injects its `traceparent` header into all page requests via `page.route()`. Every test-driven HTTP call now carries a known trace ID. On failure, the trace ID is linked in the report.

**Enable**: Set `OTEL_EXPORTER_OTLP_ENDPOINT`. Added automatically to generated `playwright.config.ts`.

---

### Honeycomb buildevents — CI Pipeline Tracing
*CI workflows*

Wraps CI test commands in `buildevents cmd` to build a hierarchical OTel trace of the entire build. Each test phase becomes a child span; failures appear as errored spans with timing context in Honeycomb.

**Enable**: `BUILDEVENTS_APIKEY` in CI. See [CI/CD integration guide](../guides/ci-cd-integration.md).

---

### qa-observability RCA Sub-Agent
*Post-failure hook on all skills*

When any skill reports a failure with a trace ID, this sub-agent runs a HolmesGPT-style loop: fetch OTel spans from Jaeger/Tempo, query Loki logs in the ±30s window, synthesize a root cause with HIGH/MEDIUM/LOW confidence, and append it to the test report.

**Enable**: Set `JAEGER_URL`, `TEMPO_URL`, or `LOKI_URL`. Activated automatically on failures.

---

## Chaos and resilience

### LitmusChaos — Concurrent Resilience Testing
*Skills: `/qa-perf`*

Interleaves a LitmusChaos experiment with a k6 load test. Claude defines the SteadyStateHypothesis from existing k6 thresholds, then interprets the result: "System held SLO during 30% pod kill but breached at 50% — resilience threshold between 30–50%."

**Enable**: `QA_CHAOS=1`. Requires `litmusctl` in PATH and a Kubernetes cluster.

---

## Record and replay

### aimock — Offline API Mocking
*Skills: `/qa-web`, `/qa-api`, `/qa-team`*

First CI run: `aimock` records all external API calls (LLM providers, third-party services, internal microservices) as fixtures. Subsequent runs replay — fully offline, deterministic, near-zero cost. Supports Claude, OpenAI, Gemini, MCP tools, vector DBs.

**Enable**: `AIMOCK_RECORD=1` for first run; auto-detected fixture directory for replay.

---

### GoReplay — Production Traffic Replay
*Skills: `/qa-perf`*

Captures live HTTP traffic from production and replays it against staging. The load profile IS real users. Claude diffs replay results against baseline per endpoint: latency regressions, new error codes.

**Enable**: `QA_REPLAY_MODE=1` (replay from `requests.gor`) or `QA_GOREPLAY_CAPTURE=1` (capture). Requires production access.

---

## Continuous benchmarking

### Bencher — Performance Trend Store
*Skills: `/qa-perf`*

Pushes k6 summaries to a stable benchmarking trend store after each run. Claude reads 30-run history and writes regression narratives: "This endpoint's p99 has drifted +12% over the last 8 PRs — regression is gradual, not spike-shaped."

**Enable**: `BENCHER_API_TOKEN` + `BENCHER_PROJECT`. Activates automatically when token is set.

---

## Test environment isolation

### Testcontainers — Per-Agent Docker Isolation
*Skills: `/qa-team`*

When `test-env.yml` declares required services (PostgreSQL, Redis, Kafka), the orchestrator provisions isolated Docker containers before spawning sub-agents and tears them down after. Each sub-agent receives its own `DB_URL`, `REDIS_URL` injected as env vars.

```yaml
# test-env.yml
services:
  - image: postgres:16
    env: { POSTGRES_DB: testdb, POSTGRES_PASSWORD: test }
  - image: redis:7-alpine
```

**Enable**: Automatic when `test-env.yml` present and Docker running.

---

## Planning integrations

### JIRA + Figma + TCMS (via `/qa-manager`)

See [Skills Overview — qa-manager](overview.md#qa-manager--requirements-to-tests-bridge) for full details.

**Env vars**: `JIRA_URL`, `JIRA_TOKEN`, `JIRA_EPIC_ID`, `FIGMA_TOKEN`, `TESTRAIL_URL`, `XRAY_URL`
