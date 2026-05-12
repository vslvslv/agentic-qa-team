# k6 Patterns & Best Practices (JavaScript)
<!-- lang: JavaScript | sources: official | community | mixed | iteration: 36 | score: 100/100 | date: 2026-05-12 -->
<!-- official: grafana.com/docs/k6/latest/using-k6/best-practices/, /scenarios/, /thresholds/, /javascript-api/k6-metrics/, /javascript-api/k6-secrets/, /javascript-api/k6-browser/, /set-up/upgrade-to-k6-v2/, /using-k6-browser/, /testing-guides/, /using-k6/protocols/grpc/, /results-output/, /using-k6/modules/, /using-k6/protocols/http-2/, /javascript-api/k6-html/, /using-k6/scenarios/concepts/open-vs-closed/, /javascript-api/k6-http/asyncrequest/, /results-output/real-time/prometheus-remote-write/, /results-output/web-dashboard/, grafana.com/docs/k6-studio/, release-notes/v1.3.0, release-notes/v1.4.0, /release-notes/v1.5.0, /release-notes/v1.6.0, /release-notes/v2.0.0, /javascript-api/k6-browser/page/, /javascript-api/k6-browser/locator/, /testing-guides/running-large-tests/, /javascript-api/k6-experimental/webcrypto/, /javascript-api/k6-experimental/fs/, /javascript-api/k6-experimental/streams/, /javascript-api/k6-websockets/, /using-k6/scenarios/concepts/open-vs-closed/, release-notes/v1.7.0, release-notes/v1.7.1, /using-k6/secret-source/file/, /using-k6/secret-source/url/, github.com/mostafa/xk6-kafka, github.com/grafana/xk6-mqtt -->

> Generated from official k6 documentation and community sources on 2026-05-12. Verified against k6 v1.7.1 (security patch for CVE-2026-33186 in gRPC); **k6 v2.0.0 final released 2026-05-11** — breaking changes and new features documented below. Iteration 28 adds: locator.filter()/all()/nth()/first()/last(), page.waitForRequest(), page.waitForEvent(), page.on('requestfailed'/'requestfinished'), frameLocator(), page.goBack()/goForward(), locator.evaluate()/evaluateHandle(), locator.pressSequentially(), k6 deps CLI, --new-machine-readable-summary, page.unroute()/unrouteAll(), mcp-k6 AI integration, OpenTelemetry stable graduation, PBKDF2 WebCrypto; community gotchas 43–47 (require() removal, Chromium orphan leak, --vus ignored in scenarios, StatsD special-char tag drop, WS bufferedAmount TypedArray bug). Iteration 29 adds: WebSocket close code/reason tracking, csv.parse() asObjects option and skipFirstLine, environment variable -e vs K6_ precedence gotcha, extension ecosystem patterns (xk6-faker/xk6-sql/xk6-dns), community gotchas 48–52 (csv.parse in setup() SharedArray trap, browser mobile context missing required --browser.type, K6_CLOUD_STACK_ID required for non-default stacks, xk6-disruptor Kubernetes RBAC setup, -e flag K6_ prefix silent config miss). Iteration 30 adds: Prometheus Remote Write Native Histograms full pattern, --execution-segment manual distributed testing, Web Dashboard CI export artifact pattern, k6/websockets experimental deprecation migration, k6 v1.7.0 subcommand extension auto-resolution workflow, Promise.race() competitive failover pattern; community gotchas 53–55 (native histogram Prometheus version requirement, K6_WEB_DASHBOARD CI artifact pattern, k6/experimental/websockets deprecation migration). Iteration 31 adds: CVE-2026-33186 security advisory for gRPC (gotcha #56), k6 cloud project list CI pattern (v2.0.0), xk6 extension author v2.0.0 migration guide (easyjson → stdlib encoding/json + archive dependencies field). Iteration 32 adds: page.waitForResponse() pattern (v1.3+), locator.contentFrame() for iframe navigation chains, locator.boundingBox() for layout testing, getBy* locators on frameLocator scope, community gotchas 57–59 (waitForResponse race condition, boundingBox null on hidden elements, locator.contentFrame() vs frameLocator() disambiguation). Iteration 33 adds: locator.locator() hierarchical scoping pattern (v1.3+), k6chaijs version updated to 4.5.0.1, K6_CLOUD_STACK env var corrected to K6_CLOUD_STACK_ID throughout cloud stack section, community gotcha #60 (k6 cloud login --stack persists default stack in credentials file — subsequent commands pick it up but K6_CLOUD_STACK_ID or --stack flag overrides it). Iteration 34 adds: `file` secret source with key=value file format and Docker volume-mount pattern, `url` secret source advanced options table (urlTemplate, responsePath, headers.*, timeout, requestsPerMinuteLimit, requestsBurst, maxRetries, retryBackoff), multi-source file+url combination pattern, community gotcha #61 (url source URL-encodes {key} — Vault path slashes become %2F and return 404; fix by flattening key names or using a proxy). Iteration 35 adds: xk6-kafka v2 full load-test pattern (JSON messages, SASL-PLAIN auth, ~383k msgs/s throughput baseline, teardown consumer pattern), xk6-mqtt full load-test pattern (IoT broker testing, pub/sub with QoS levels, event-driven VU loop), community gotcha #62 (k6/experimental/fs file handle opened at init context is shared across all VU iterations — the file cursor advances per iteration; call `file.seek(0, SeekMode.Start)` at the top of default() to reset it, or open inside default() for per-iteration independence). Iteration 36 adds: Ramping Arrival Rate comprehensive multi-phase traffic example (startRate, preAllocatedVUs sizing via Little's Law, no-sleep rule), Threshold Configuration for SLOs full reference (abortOnFail, delayAbortEval, scenario-scoped thresholds, tag selector gotcha), Performance Regression Detection patterns (threshold-based CI gate, handleSummary JSON diff strategy, Grafana Cloud trend analysis), TypeScript Native Support section (k6 v0.57+ esbuild, @types/k6, tsconfig.k6.json, type-check-before-run CI pattern, esbuild bundler for Node.js deps), Grafana Dashboard Integration (web dashboard CI artifact, Prometheus Remote Write PromQL queries, InfluxDB 2.x + Grafana dashboard IDs), community gotchas 63–65 (ramping-arrival-rate startRate cold-start burst, abortOnFail delayAbortEval VU-exhaustion inaccuracy, handleSummary p(95) JSON key parentheses). Re-run `/qa-refine k6` to refresh.

> **k6 v2.0.0 migration notice:** Major version removes `externally-controlled` executor, CLI commands `k6 pause/resume/scale/status/login`, `--no-summary` flag (use `--summary-mode=disabled`), `--summary-mode=legacy`, `options.ext.loadimpact` (use `options.cloud`), browser metric `browser_web_vital_fid` (use `browser_web_vital_inp`), `k6/experimental/redis` module (use `k6/x/redis` extension), and automatic locator retries added to browser. See [v2.0.0 Migration](#v200-migration) section. **New in v2.0.0 final:** HTTP API server disabled by default, cloud secrets auto-injected in `--local-execution`, `k6 cloud project list` command, extension tab-completion.

## Core Principles

1. **Scenarios over `stages`** — The `scenarios` API is the modern, preferred way to configure load profiles. It supports multiple concurrent executors, per-scenario env vars, and per-scenario thresholds. The top-level `stages` shorthand still works but is less expressive.
2. **Executor choice drives test semantics** — Choose the executor based on *what* you are modeling: `ramping-vus` for VU-based ramp-up, `constant-arrival-rate` for RPS-based load, `ramping-arrival-rate` for realistic traffic curves.
3. **Thresholds are pass/fail gates** — Thresholds fail the run (non-zero exit code) when SLAs are breached. Attach them to specific scenarios or custom metrics for precise reporting.
4. **`setup()` / `teardown()` for shared state** — Authenticate once in `setup()`, pass the token to all VUs; clean up created resources in `teardown()`.
5. **Checks are assertions, not thresholds** — `check()` records pass/fail counts but does NOT abort the test. Use thresholds on `checks` to gate the run on overall check-pass rate.
6. **Size VUs with Little's Law** — The required VU count is derived from the system's throughput and the time each VU spends in one iteration:
   > **VUs = throughput (req/s) × (avg response time (s) + think time (s))**
   >
   > *Example:* Target = 100 req/s; avg response time = 300 ms; think time = 1 s.
   > VUs = 100 × (0.3 + 1.0) = **130 VUs**.
   >
   > Use `constant-arrival-rate` when you want to *specify* throughput directly (k6 auto-scales VUs). Use `ramping-vus` when you want to *specify* VU count and measure the resulting throughput.

---

## VU Lifecycle & Init Context

k6 executes test code in four distinct stages. Understanding this prevents hard-to-debug errors.

| Stage | Runs | Allowed |
|-------|------|---------|
| **Init** | Once per VU before the test | `import`, `open()`, `new SharedArray()`, metric declarations |
| **Setup** | Once before VU code starts | HTTP requests, return auth token |
| **VU code** (`default` fn) | Repeatedly during test duration | HTTP, checks, sleep — the hot loop |
| **Teardown** | Once after all VU iterations | Delete created resources |

**Critical rules:**
- `open()` and `new SharedArray()` **must** be called at the top level (init context), not inside `default`.
- `setup()` can make HTTP requests; init context **cannot**.
- Each VU receives a deep copy of `setup()`'s return value — mutations inside `default` are not visible to other VUs or `teardown()`.
- If `setup()` throws, `teardown()` is **not** called.

```javascript
// k6/scripts/lifecycle-example.js
import http from "k6/http";
import { check } from "k6";
import { SharedArray } from "k6/data";

// INIT CONTEXT — runs once per VU
const users = new SharedArray("users", function () {
  return JSON.parse(open("./data/users.json")); // file loaded once, shared across all VUs
});

export const options = { /* ... */ };

export function setup() {
  // Runs once before any VU starts. HTTP allowed here.
  const res = http.post(`${__ENV.API_URL}/api/auth/login`, JSON.stringify({
    email: users[0].email, password: users[0].password,
  }), { headers: { "Content-Type": "application/json" } });
  return { token: res.json("token") };
}

export default function (data) {
  // VU code — receives a copy of setup()'s return value
  const user = users[__VU % users.length]; // distribute users across VUs
  http.get(`${__ENV.API_URL}/api/profile`, {
    headers: { Authorization: `Bearer ${data.token}` },
  });
}

export function teardown(data) {
  // Runs once after all VUs finish. data is setup()'s return value.
  console.log("Run complete, token was:", data.token ? "valid" : "missing");
}
```

---

## Recommended Patterns

### Staged Ramp-Up with `ramping-vus` Executor

The `ramping-vus` executor is the idiomatic replacement for the top-level `stages` array.
It provides named stages, per-scenario graceful stop, and composes with other scenarios.

```javascript
// k6/scripts/api-ramp.js
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    api_ramp: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "30s", target: 10 },   // warm-up
        { duration: "1m",  target: 50 },   // ramp to target load
        { duration: "2m",  target: 50 },   // sustained load
        { duration: "30s", target: 0 },    // ramp down
      ],
      gracefulRampDown: "10s",
    },
  },
  thresholds: {
    "http_req_duration{scenario:api_ramp}": ["p(95)<300"],
    "http_req_failed{scenario:api_ramp}":   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  const res = http.get(`${BASE}/api/users`);
  check(res, { "status 200": (r) => r.status === 200 });
  sleep(1);
}
```

### RPS-Controlled Load with `constant-arrival-rate`

Use when you want to hold a fixed request rate regardless of response time.
Requires `preAllocatedVUs` (initial pool) and `maxVUs` (ceiling).

```javascript
// k6/scripts/api-steady.js
import http from "k6/http";
import { check } from "k6";

export const options = {
  scenarios: {
    steady_rps: {
      executor: "constant-arrival-rate",
      rate: 100,               // 100 iterations per second
      timeUnit: "1s",
      duration: "2m",
      preAllocatedVUs: 50,
      maxVUs: 200,
    },
  },
  thresholds: {
    "http_req_duration{scenario:steady_rps}": ["p(95)<200", "p(99)<500"],
    "http_req_failed{scenario:steady_rps}":   ["rate<0.005"],
    "dropped_iterations":                     ["count<50"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  const res = http.get(`${BASE}/api/health`);
  check(res, { "healthy": (r) => r.status === 200 });
}
```

### Multiple Concurrent Scenarios

Run a read-heavy scenario and a write scenario simultaneously with independent
ramp profiles and per-scenario thresholds.

```javascript
// k6/scripts/mixed-load.js
import http from "k6/http";
import { check, sleep } from "k6";
import { Trend } from "k6/metrics";

const readLatency  = new Trend("read_latency",  true);
const writeLatency = new Trend("write_latency", true);

export const options = {
  scenarios: {
    reads: {
      executor: "ramping-vus",
      stages: [
        { duration: "30s", target: 40 },
        { duration: "3m",  target: 40 },
        { duration: "15s", target: 0 },
      ],
      exec: "readFlow",
    },
    writes: {
      executor: "constant-arrival-rate",
      rate: 10,
      timeUnit: "1s",
      duration: "3m45s",
      preAllocatedVUs: 20,
      maxVUs: 50,
      startTime: "30s",   // start after reads warm up
      exec: "writeFlow",
    },
  },
  thresholds: {
    "read_latency":  ["p(95)<200"],
    "write_latency": ["p(95)<500"],
    "http_req_failed{scenario:reads}":  ["rate<0.01"],
    "http_req_failed{scenario:writes}": ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export function readFlow() {
  const res = http.get(`${BASE}/api/items`);
  check(res, { "read ok": (r) => r.status === 200 });
  readLatency.add(res.timings.duration);
  sleep(1);
}

export function writeFlow() {
  const payload = JSON.stringify({ name: `item-${Date.now()}` });
  const res = http.post(`${BASE}/api/items`, payload, {
    headers: { "Content-Type": "application/json" },
  });
  check(res, { "write ok": (r) => r.status === 201 });
  writeLatency.add(res.timings.duration);
}
```

### Auth in `setup()`, Resource Cleanup in `teardown()`

Fetch credentials once per test run; share the token with all VUs via `setup()` return value.
Clean up any created resources in `teardown()` to keep the environment clean.

```javascript
// k6/scripts/authed-load.js
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    authed_ramp: {
      executor: "ramping-vus",
      stages: [
        { duration: "20s", target: 10 },
        { duration: "1m",  target: 30 },
        { duration: "20s", target: 0 },
      ],
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<300"],
    http_req_failed:   ["rate<0.01"],
    checks:            ["rate>0.99"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export function setup() {
  const res = http.post(
    `${BASE}/api/auth/login`,
    JSON.stringify({
      email:    __ENV.E2E_USER_EMAIL    || "test@example.com",
      password: __ENV.E2E_USER_PASSWORD || "password123",
    }),
    { headers: { "Content-Type": "application/json" } }
  );
  check(res, { "login ok": (r) => r.status === 200 });
  return { token: res.json("token") };
}

export default function (data) {
  const headers = {
    Authorization: `Bearer ${data.token}`,
    "Content-Type": "application/json",
  };

  const res = http.get(`${BASE}/api/profile`, { headers });
  check(res, {
    "profile 200": (r) => r.status === 200,
    "has id":      (r) => r.json("id") !== undefined,
  });
  sleep(1);
}

export function teardown(data) {
  // Nothing to clean up in this example.
  // If setup() created test users, delete them here.
  console.log("Test complete. Token was:", data.token ? "present" : "missing");
}
```

### Per-Scenario Threshold Configuration

Thresholds can target a specific scenario, a specific URL, or a custom metric using tags.
This avoids one noisy scenario masking failures in another.

```javascript
export const options = {
  thresholds: {
    // Global — all scenarios combined
    http_req_duration: ["p(95)<500"],

    // Scoped to a scenario by the auto-tag {scenario:name}
    "http_req_duration{scenario:reads}":  ["p(95)<200"],
    "http_req_duration{scenario:writes}": ["p(95)<500"],

    // Scoped to a URL pattern using {url:...}
    "http_req_duration{url:http://localhost:3001/api/health}": ["p(99)<50"],

    // Custom metric threshold
    "my_custom_latency": ["p(95)<300", "max<1000"],

    // Check pass rate threshold
    "checks": ["rate>0.99"],

    // Abort early if error rate spikes: abortOnFail stops the test
    "http_req_failed": [
      { threshold: "rate<0.05", abortOnFail: true, delayAbortEval: "10s" },
    ],
  },
};
```

### Soak Test — Memory Leak & Stability Detection

Soak tests run at moderate load (50–70% of normal peak) for 1–8 hours. The goal is not
to find the breaking point — it is to surface memory leaks, connection pool exhaustion,
and gradual degradation that only appear after extended operation.

```javascript
// k6/scripts/soak.js — run overnight; schedule in CI as nightly job
import http from "k6/http";
import { check, sleep } from "k6";
import { Trend, Gauge } from "k6/metrics";

// Track iteration latency over time — flat line = healthy; upward drift = memory leak
const iterLatency = new Trend("iter_latency_ms", true);
// Track last response size — growing sizes may indicate response bloat
const responseSize = new Gauge("response_size_bytes");

export const options = {
  scenarios: {
    soak: {
      executor: "ramping-vus",
      stages: [
        { duration: "5m",  target: 30 },  // gentle ramp up
        { duration: "8h",  target: 30 },  // soak plateau — overnight
        { duration: "5m",  target: 0  },  // ramp down
      ],
      gracefulStop: "60s",  // longer graceful stop for soak — allow inflight to finish
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<500", "p(99)<1000"],
    http_req_failed:   ["rate<0.01"],
    // Drift detection: if median latency drifts above 200ms, soak is failing
    "iter_latency_ms": ["p(50)<200"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  const start = Date.now();
  const res = http.get(`${BASE}/api/items`);
  const elapsed = Date.now() - start;

  check(res, { "status 200": (r) => r.status === 200 });

  iterLatency.add(elapsed);
  responseSize.add(res.body ? res.body.length : 0);

  sleep(2);  // 2s think time — soak tests should not hammer at full rate
}
```

> **[community]:** After a soak test, compare the p(50) latency in the first 10 minutes
> vs. the last 10 minutes. A 30%+ increase in median latency indicates a leak or slow
> resource exhaustion — even if the p(95) threshold held.

### Spike Test — Auto-Scaling & Recovery Validation

Spike tests verify that the system recovers gracefully after sudden traffic surges.
Unlike stress tests (gradual ramp), spikes use an instantaneous VU jump then immediate
drop to test auto-scaling responses and queue drain behavior.

```javascript
// k6/scripts/spike.js
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    spike: {
      executor: "ramping-vus",
      stages: [
        { duration: "10s", target: 10  },  // baseline
        { duration: "1m",  target: 10  },  // hold baseline
        { duration: "10s", target: 200 },  // spike — instantaneous surge
        { duration: "3m",  target: 200 },  // hold spike — observe degradation
        { duration: "10s", target: 10  },  // drop back to baseline
        { duration: "3m",  target: 10  },  // recovery period — watch error rate
        { duration: "10s", target: 0   },  // ramp down
      ],
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<2000"],       // relax latency SLO during spike
    http_req_failed:   ["rate<0.10"],        // tolerate up to 10% errors during spike peak
    // The important metric: error rate MUST recover after spike
    "http_req_failed{scenario:spike}": [
      { threshold: "rate<0.01", abortOnFail: false },  // logged, not hard-fail
    ],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  const res = http.get(`${BASE}/api/items`);
  check(res, { "status ok": (r) => r.status < 500 });
  sleep(1);
}
```

Use `ramping-arrival-rate` to continuously increase RPS until the system breaks. Unlike
`ramping-vus`, arrival-rate keeps the iteration schedule fixed regardless of response time,
so you can observe exactly at what RPS latency degrades.

```javascript
// k6/scripts/breakpoint.js
import http from "k6/http";
import { check } from "k6";

export const options = {
  scenarios: {
    breakpoint: {
      executor: "ramping-arrival-rate",
      startRate: 10,          // start at 10 iterations/s
      timeUnit: "1s",
      preAllocatedVUs: 50,
      maxVUs: 500,
      stages: [
        { duration: "2m", target: 50  },  // ramp to 50 req/s
        { duration: "2m", target: 100 },  // push to 100 req/s
        { duration: "2m", target: 200 },  // push to 200 req/s
        { duration: "1m", target: 0   },  // ramp down
      ],
    },
  },
  thresholds: {
    // Abort if error rate exceeds 20% — system is broken
    "http_req_failed{scenario:breakpoint}": [
      { threshold: "rate<0.20", abortOnFail: true, delayAbortEval: "30s" },
    ],
    "http_req_duration{scenario:breakpoint}": ["p(95)<2000"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  const res = http.get(`${BASE}/api/items`);
  check(res, { "status 200": (r) => r.status === 200 });
  // NOTE: No sleep() in arrival-rate executors — the rate/timeUnit controls pacing.
  // Adding sleep() reduces actual throughput and causes dropped iterations.
}
```

The `params` object controls headers, timeouts, tags, cookies, and response handling on
a per-request basis. Build a shared params helper in `lib/auth.js` to avoid repetition:

```javascript
// k6/lib/auth.js — reusable param builder
export function authParams(token, extra = {}) {
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      "Accept":        "application/json",
      ...extra.headers,
    },
    timeout:      extra.timeout      || "30s",       // per-request timeout (default: 60s)
    responseType: extra.responseType || "text",      // "text" | "binary" | "none"
    tags:         extra.tags         || {},
    redirects:    extra.redirects    ?? 10,          // max redirects (default: 10)
  };
}

// k6/scripts/load.js — usage
import http from "k6/http";
import { check } from "k6";
import { authParams } from "../lib/auth.js";

export default function (data) {
  // Authenticated JSON request with scoped tag and 15s timeout
  const itemsRes = http.get(
    `${__ENV.API_URL}/api/items`,
    authParams(data.token, { timeout: "15s", tags: { endpoint: "items" } })
  );
  check(itemsRes, { "items 200": (r) => r.status === 200 });

  // High-volume health check — discard body, tag separately
  http.get(
    `${__ENV.API_URL}/api/health`,
    { responseType: "none", tags: { endpoint: "health" } }
  );
}
```

`SharedArray` loads test data once in init context and shares the underlying memory
across all VUs — critical for large datasets (10 k+ rows) where per-VU copies would
exhaust memory.

```javascript
// k6/scripts/parameterized-load.js
import http from "k6/http";
import { check, sleep } from "k6";
import { SharedArray } from "k6/data";

// Loaded once at init time — NOT per iteration, NOT per VU
const testUsers = new SharedArray("testUsers", function () {
  return JSON.parse(open("./data/users.json"));
  // users.json: [{ "email": "u1@test.com", "password": "pass1" }, ...]
});

export const options = {
  scenarios: {
    parameterized: {
      executor: "ramping-vus",
      stages: [
        { duration: "30s", target: 20 },
        { duration: "1m",  target: 20 },
        { duration: "15s", target: 0  },
      ],
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<400"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  // Each VU picks a different user; wraps around if VUs > users
  const user = testUsers[__VU % testUsers.length];

  const loginRes = http.post(
    `${BASE}/api/auth/login`,
    JSON.stringify({ email: user.email, password: user.password }),
    { headers: { "Content-Type": "application/json" } }
  );
  check(loginRes, { "login ok": (r) => r.status === 200 });
  sleep(1);
}
```

> **Warning:** Do not call `.filter()` or `.map()` on a `SharedArray` outside the constructor —
> those methods return regular JS arrays, discarding the shared-memory benefit.
> Perform data transformations inside the `new SharedArray(name, fn)` callback.

### CSV Data with SharedArray + papaparse  [community]

k6 has no built-in CSV parser. Use papaparse (via jslib.k6.io or bundled locally) inside
a `SharedArray` constructor to load CSV test data once, shared across all VUs.

```javascript
// k6/scripts/csv-users-load.js
import http from "k6/http";
import { check, sleep } from "k6";
import { SharedArray } from "k6/data";
import papaparse from "https://jslib.k6.io/papaparse/5.1.1/index.js";

// Load and parse CSV once at init — users.csv: email,password,role
const csvUsers = new SharedArray("csvUsers", function () {
  const raw = open("./data/users.csv");
  return papaparse.parse(raw, { header: true, skipEmptyLines: true }).data;
  // Result: [{ email: "u1@test.com", password: "pass1", role: "admin" }, ...]
});

export const options = {
  scenarios: {
    csv_load: {
      executor: "ramping-vus",
      stages: [
        { duration: "30s", target: 20 },
        { duration: "1m",  target: 20 },
        { duration: "15s", target: 0  },
      ],
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<400"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  // Use scenario.iterationInTest for unique assignment across all VUs (no collision)
  const user = csvUsers[__VU % csvUsers.length];

  const res = http.post(
    `${BASE}/api/auth/login`,
    JSON.stringify({ email: user.email, password: user.password }),
    { headers: { "Content-Type": "application/json" } }
  );
  check(res, { "login ok": (r) => r.status === 200 });
  sleep(1);
}
```

> **[community]:** k6 Cloud allocates 8 GB memory per 300 VUs. Without `SharedArray`, a 50 MB
> CSV parsed per-VU at 300 VUs = 15 GB — test crashes silently. Always wrap CSV data in
> `SharedArray`. Use `papaparse` from jslib.k6.io to avoid bundler setup for CSV parsing.

### Native CSV Parsing with `k6/experimental/csv`  [community]

The `k6/experimental/csv` module provides a **Go-native CSV parser** built into k6 —
faster and more memory-efficient than JavaScript-based papaparse. Two APIs:

| API | Use case |
|-----|---------|
| `csv.parse(file, opts)` | Parse entire file upfront into a SharedArray-like structure |
| `new csv.Parser(file)` | Stream CSV line-by-line for very large files |

```javascript
// k6/scripts/csv-native.js — native CSV parser (no papaparse dependency needed)
import { open } from "k6/experimental/fs";
import { parse, Parser } from "k6/experimental/csv";
import http from "k6/http";
import { check } from "k6";
import exec from "k6/execution";

// Option 1: Full-file parse (fast startup for < ~100 MB CSV)
// csv.parse() bypasses the JS runtime — parsed entirely in Go for max throughput
let csvRecords;  // populated in setup()

export async function setup() {
  const file = await open("./data/users.csv");
  // records: array of string arrays — [ ["alice@test.com","pw1"], ["bob@test.com","pw2"] ]
  csvRecords = await parse(file, { delimiter: "," });
}

export const options = {
  scenarios: {
    csv_load: {
      executor: "constant-arrival-rate",
      rate: 100, timeUnit: "1s", duration: "2m",
      preAllocatedVUs: 20, maxVUs: 50,
    },
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default async function (data) {
  // Use iterationInTest for unique user per iteration (no collision across VUs)
  const row = data.csvRecords[exec.scenario.iterationInTest % data.csvRecords.length];
  const [email, password] = row;

  const res = http.post(
    `${BASE}/api/auth/login`,
    JSON.stringify({ email, password }),
    { headers: { "Content-Type": "application/json" } }
  );
  check(res, { "login ok": (r) => r.status === 200 });
}
```

```javascript
// Option 2: Streaming parser — for CSV files too large to hold in memory
import { open } from "k6/experimental/fs";
import { Parser } from "k6/experimental/csv";
import { Counter } from "k6/metrics";

const rowsProcessed = new Counter("csv_rows_processed");

export default async function () {
  const file = await open("./data/huge-dataset.csv");
  const parser = new Parser(file);

  while (true) {
    const { done, value } = await parser.next();
    if (done) break;

    const [id, payload] = value;  // value is a string array (one CSV row)
    http.post(`${BASE}/api/items`, JSON.stringify({ id, payload }), {
      headers: { "Content-Type": "application/json" },
    });
    rowsProcessed.add(1);
  }
}
```

> **[community]:** `k6/experimental/csv` requires `k6/experimental/fs` to open the file —
> you cannot pass a plain `open()` string result to it. The module is experimental; it may
> graduate to `k6/csv` in a future release. **Choose between papaparse vs native csv**:
> - **papaparse**: Header-row support, JS-friendly object output, no `async default` needed
> - **`k6/experimental/csv`**: ~3–5× faster parsing, lower memory, no npm install required

### Memory-Efficient File I/O with `k6/experimental/fs`  [community]

The `k6/experimental/fs` module provides **low-memory file access** — unlike `open()` which
loads the entire file into a string for every VU, `k6/experimental/fs` shares a single
memory-mapped copy across all VUs and lets you seek/read in chunks. Use it for large test
data files (> 10 MB) or when you need random-access within a file.

```javascript
// k6/scripts/fs-data.js — memory-efficient large-file data loading
import { open, SeekMode } from "k6/experimental/fs";
import http from "k6/http";
import { check } from "k6";

// File is opened once at the module level (init context) and shared across VUs
let dataFile;

export async function setup() {
  // Open and stat the file during setup to validate it exists
  dataFile = await open("./data/large-payloads.json");
  const stat = await dataFile.stat();
  console.log(`Payload file: ${stat.name}, size: ${stat.size} bytes`);
}

export const options = {
  scenarios: {
    fs_load: {
      executor: "constant-vus",
      vus: 10,
      duration: "1m",
    },
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default async function () {
  // Seek to start of file (rewind)
  await dataFile.seek(0, SeekMode.Start);

  // Read into a fixed-size buffer — avoids creating large strings
  const buf = new Uint8Array(4096);
  const bytesRead = await dataFile.read(buf);

  if (bytesRead === null) return; // EOF

  const payload = new TextDecoder().decode(buf.subarray(0, bytesRead));
  const res = http.post(`${BASE}/api/ingest`, payload, {
    headers: { "Content-Type": "application/json" },
  });
  check(res, { "ingested": (r) => r.status === 202 });
}
```

| `SeekMode` | Value | Seek relative to |
|-----------|-------|-----------------|
| `SeekMode.Start` | 0 | Beginning of file |
| `SeekMode.Current` | 1 | Current position |
| `SeekMode.End` | 2 | End of file |

> **[community]:** `k6/experimental/fs` is async-only — your `default` function must be
> `async` when using it. The module is experimental: breaking API changes may occur before
> it graduates to `k6/fs`. Prefer `SharedArray` + `papaparse` for CSV; use
> `k6/experimental/fs` when you need streaming or chunked access to binary or very large
> text files that exceed SharedArray's practical size limits (~50 MB).

 Use the right type to get the right aggregation in thresholds.

```javascript
// k6/scripts/custom-metrics.js
import http from "k6/http";
import { check, sleep } from "k6";
import { Counter, Gauge, Rate, Trend } from "k6/metrics";

// TREND — stores min/max/avg/percentiles; use isTime=true for ms values
const checkoutLatency = new Trend("checkout_latency_ms", true);

// RATE — percentage of non-zero values; good for success/failure ratios
const paymentSuccess  = new Rate("payment_success_rate");

// COUNTER — monotonically increasing sum
const ordersCreated   = new Counter("orders_created");

// GAUGE — tracks last / min / max; use for snapshot values like queue depth
const cartItemCount   = new Gauge("cart_item_count");

export const options = {
  scenarios: {
    shop: { executor: "constant-vus", vus: 10, duration: "1m" },
  },
  thresholds: {
    checkout_latency_ms:  ["p(95)<800", "max<3000"],
    payment_success_rate: ["rate>0.98"],
    orders_created:       ["count>50"],      // ensure we actually processed orders
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  const res = http.post(`${BASE}/api/checkout`, JSON.stringify({ item: "sku-001", qty: 1 }), {
    headers: { "Content-Type": "application/json" },
  });

  checkoutLatency.add(res.timings.duration);
  paymentSuccess.add(res.status === 201);
  if (res.status === 201) ordersCreated.add(1);
  cartItemCount.add(Math.floor(Math.random() * 5) + 1);  // simulated

  check(res, { "checkout created": (r) => r.status === 201 });
  sleep(1);
}
```

### Multipart File Upload  [community]

File upload endpoints are often untested in load tests because teams don't know k6's
`http.file()` API. Skipping upload tests masks upload-service bottlenecks that only
appear under concurrent load.

```javascript
// k6/scripts/file-upload.js
import http from "k6/http";
import { check, sleep } from "k6";
import { SharedArray } from "k6/data";

// Load binary file content once at init — shared across VUs
const fileContent = open("./data/test-image.jpg", "b"); // "b" = binary mode

export const options = {
  scenarios: {
    upload_test: {
      executor: "constant-arrival-rate",
      rate: 5,           // 5 uploads/sec — intentionally low (uploads are expensive)
      timeUnit: "1s",
      duration: "1m",
      preAllocatedVUs: 10,
      maxVUs: 30,
    },
  },
  thresholds: {
    "http_req_duration{name:upload}": ["p(95)<5000"],  // uploads are slower
    http_req_failed:                   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  // Multipart form data — browser-equivalent file upload
  const formData = {
    file:        http.file(fileContent, `upload-${__ITER}.jpg`, "image/jpeg"),
    description: `Test upload ${__ITER}`,
  };

  const res = http.post(
    `${BASE}/api/uploads`,
    formData,
    { tags: { name: "upload" } }  // tag for threshold scoping
  );

  check(res, {
    "upload 200":   (r) => r.status === 200,
    "has file id":  (r) => r.json("id") !== undefined,
  });

  sleep(0.5);
}
```

### `handleSummary` — JUnit XML + JSON + HTML + CI-Friendly Text  [community]

CI systems (Jenkins, GitHub Actions, Azure DevOps) parse JUnit XML natively. Export
it from `handleSummary` to get pass/fail results visible directly in the CI test report
panel — without a separate Grafana dashboard. For stakeholder-facing HTML reports, use
the community `k6-reporter` library.

```javascript
// k6/scripts/load.js (complete handleSummary export — JUnit + JSON + HTML)
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.2/index.js";
import { jUnit }       from "https://jslib.k6.io/k6-summary/0.0.2/index.js";

// Community HTML reporter (bundle locally for offline use):
// npm install @benc-uk/k6-reporter
// import { htmlReport } from "../lib/k6-reporter.js";
// OR reference from jslib.k6.io:
// import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";

export function handleSummary(data) {
  // Build JUnit XML for CI test-results panel
  const junit = jUnit(data);

  // Build threshold-pass-only JSON for programmatic post-processing
  const failed = Object.entries(data.metrics)
    .filter(([, m]) => m.thresholds && Object.values(m.thresholds).some((t) => t.ok === false))
    .map(([name]) => name);

  const report = {
    timestamp:        new Date().toISOString(),
    thresholdsFailed: failed,
    passed:           failed.length === 0,
    metrics:          data.metrics,
  };

  // Minimal built-in HTML report (no external lib)
  const metricsHtml = Object.entries(data.metrics)
    .filter(([, m]) => m.type === "trend")
    .map(([name, m]) => {
      const v = m.values;
      return `<tr>
        <td>${name}</td>
        <td>${v["avg"] ? v["avg"].toFixed(2) + "ms" : "-"}</td>
        <td>${v["p(95)"] ? v["p(95)"].toFixed(2) + "ms" : "-"}</td>
        <td>${v["p(99)"] ? v["p(99)"].toFixed(2) + "ms" : "-"}</td>
      </tr>`;
    })
    .join("\n");

  const html = `<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<title>k6 Load Test Report — ${new Date().toISOString()}</title>
<style>body{font-family:sans-serif;padding:1rem}table{border-collapse:collapse;width:100%}
th,td{border:1px solid #ccc;padding:8px;text-align:left}th{background:#f5f5f5}
.pass{color:green}.fail{color:red}</style></head>
<body>
<h1>k6 Load Test Report</h1>
<p><strong>Date:</strong> ${new Date().toISOString()}</p>
<p><strong>Status:</strong> <span class="${failed.length === 0 ? "pass" : "fail"}">${failed.length === 0 ? "PASSED" : "FAILED"}</span></p>
${failed.length > 0 ? `<p><strong>Failed thresholds:</strong> ${failed.join(", ")}</p>` : ""}
<h2>Latency Metrics</h2>
<table><tr><th>Metric</th><th>avg</th><th>p(95)</th><th>p(99)</th></tr>
${metricsHtml}
</table>
</body></html>`;

  return {
    // stdout: CI-friendly text (no ANSI codes — caller should pass --no-color)
    stdout:                         textSummary(data, { indent: "→", enableColors: false }),
    "results/summary.json":         JSON.stringify(report, null, 2),
    "results/junit.xml":            junit,
    "results/report.html":          html,
  };
}
```

> **[community]:** For richer HTML reports with charts, use the `@benc-uk/k6-reporter`
> community library. It generates a complete HTML dashboard with metric graphs. Bundle it
> locally (not via raw GitHub URLs) in production CI to avoid network dependency failures
> during the summary phase.

### jslib Utility Libraries  [community]

The [jslib.k6.io](https://jslib.k6.io) catalog provides official k6-maintained utilities
that extend test scripting without requiring npm bundling.

| Library | URL | Purpose |
|---------|-----|---------|
| `k6-summary` | `jslib.k6.io/k6-summary/0.0.2/index.js` | `textSummary` + `jUnit` for handleSummary |
| `papaparse` | `jslib.k6.io/papaparse/5.1.1/index.js` | CSV parsing with header support |
| `httpx` | `jslib.k6.io/httpx/0.1.0/index.js` | HTTP session wrapper — reusable base URL, headers, auth |
| `k6chaijs` | `jslib.k6.io/k6chaijs/4.5.0.1/index.js` | BDD-style assertions (`expect`, `chai`) |
| `utils` | `jslib.k6.io/k6-utils/1.4.0/index.js` | `randomString()`, `uuidv4()`, `randomIntBetween()` |
| `totp` | `jslib.k6.io/totp/1.0.0/index.js` | TOTP/MFA code generation from shared secret |
| `http-instrumentation-tempo` | `jslib.k6.io/http-instrumentation-tempo/1.0.1/index.js` | Auto OTel trace context injection |
| `http-instrumentation-pyroscope` | `jslib.k6.io/http-instrumentation-pyroscope/1.0.1/index.js` | Pyroscope baggage header injection |

```javascript
// httpx — session wrapper with base URL + default headers baked in
import { Httpx } from "https://jslib.k6.io/httpx/0.1.0/index.js";

const session = new Httpx({
  baseURL: __ENV.API_URL || "http://localhost:3001",
  headers: { "Content-Type": "application/json" },
  timeout: 20_000,
});

export function setup() {
  const res = session.post("/api/auth/login", JSON.stringify({
    email: __ENV.E2E_USER_EMAIL,
    password: __ENV.E2E_USER_PASSWORD,
  }));
  return { token: res.json("token") };
}

export default function (data) {
  session.addHeader("Authorization", `Bearer ${data.token}`);
  const res = session.get("/api/profile");
  check(res, { "profile ok": (r) => r.status === 200 });
}
```

```javascript
// k6chaijs — BDD-style assertions (useful for teams migrating from Jest/Mocha)
import { describe, expect } from "https://jslib.k6.io/k6chaijs/4.5.0.1/index.js";
import http from "k6/http";

export default function () {
  const res = http.get(`${__ENV.API_URL}/api/items`);

  describe("GET /api/items", () => {
    expect(res.status, "status code").to.equal(200);
    expect(res.json("items"), "items array").to.be.an("array").that.is.not.empty;
    expect(res.json("items[0].id"), "item id").to.be.a("number");
  });
}
```

> **[community]:** The k6 `testing` jslib (`jslib.k6.io/testing/0.4.0/index.js`) provides
> a Playwright-inspired assertion API (`assert.equal`, `assert.contains`, `assert.ok`).
> Unlike `check()`, failed assertions throw errors that stop the current VU iteration —
> semantically equivalent to `fail()` but with richer error messages. Use it when you want
> test-style assertions rather than load-test-style pass/fail rates.

 (`k6/websockets`, stable since k6 v0.56) implements the
WebSocket living standard with a global event loop — use it for all new scripts.
The `k6/experimental/websockets` and legacy `k6/ws` modules are **deprecated** as of
k6 v1.x and will be removed in a future release. The key structural difference from
HTTP tests: the `default` function runs **once** per VU, not in a loop — the event loop
drives execution.

```javascript
// k6/scripts/websocket-load.js
import { WebSocket } from "k6/websockets";   // stable module — NOT k6/experimental/websockets
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    ws_load: {
      executor: "constant-vus",
      vus: 20,
      duration: "1m",
    },
  },
  thresholds: {
    // WebSocket sessions: verify HTTP 101 upgrade succeeded
    checks: ["rate>0.99"],
  },
};

const BASE_WS = (__ENV.API_URL || "http://localhost:3001")
  .replace("http://", "ws://")
  .replace("https://", "wss://");

export default function () {
  const ws = new WebSocket(`${BASE_WS}/ws/feed`);

  ws.onopen = () => {
    ws.send(JSON.stringify({ type: "subscribe", channel: "prices" }));
    // Close after 5 seconds — prevents VUs from blocking forever
    setTimeout(() => ws.close(), 5000);
  };

  ws.onmessage = (e) => {
    const msg = JSON.parse(e.data);
    check(msg, { "has payload": (m) => m.data !== undefined });
  };

  ws.onerror = (e) => {
    // Filter expected "close sent" noise from real errors
    if (e.error() !== "websocket: close sent") {
      console.error("WS error:", e.error());
    }
  };

  // Block until socket closes (event loop pattern — not a for loop)
  ws.addEventListener("close", () => {});
}
```

### Batch Requests & Page-Load Simulation  [community]

`http.batch()` sends multiple requests in parallel over separate TCP connections —
ideal for simulating real browser page loads that fetch HTML + CSS + JS simultaneously.
Use the named-object form so each response is identifiable by key.

```javascript
// k6/scripts/page-load.js
import http from "k6/http";
import { check, group, sleep } from "k6";

export const options = {
  scenarios: {
    page_load: {
      executor: "ramping-vus",
      stages: [
        { duration: "30s", target: 20 },
        { duration: "1m",  target: 20 },
        { duration: "15s", target: 0  },
      ],
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  group("home page load", function () {
    // Parallel fetch — simulates real browser asset loading
    const responses = http.batch({
      html:   { method: "GET", url: `${BASE}/` },
      css:    { method: "GET", url: `${BASE}/static/main.css` },
      js:     { method: "GET", url: `${BASE}/static/app.js` },
      api:    { method: "GET", url: `${BASE}/api/config` },
    });

    check(responses.html, {
      "HTML 200":     (r) => r.status === 200,
      "has title":    (r) => r.body && r.body.includes("<title>"),
    });
    check(responses.api, {
      "config 200":   (r) => r.status === 200,
    });
  });

  sleep(1);
}
```

### Concurrent Async HTTP Requests with `http.asyncRequest` + `Promise.all`  [community]

`http.asyncRequest()` returns a `Promise<Response>` — use `Promise.all()` to fire multiple
HTTP calls concurrently within a single VU iteration. This is distinct from `http.batch()`:
`asyncRequest` + `Promise.all` is for semantically-related co-dependent calls (e.g., fetch
user + fetch cart simultaneously); `http.batch()` is for independent asset/page loads.

**Key differences from `http.batch()`:**
- `http.batch()`: array/object API, simpler, no async function required
- `asyncRequest` + `Promise.all`: Promise-based, works with any async logic between calls,
  supports conditional branching on resolved values before continuing

```javascript
// k6/scripts/concurrent-async.js — two independent API calls fired in parallel per VU
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    concurrent_calls: {
      executor: "constant-vus",
      vus: 20,
      duration: "2m",
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<400"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default async function () {
  // Fire both requests simultaneously — total wait = max(userTime, cartTime), not sum
  const [userRes, cartRes] = await Promise.all([
    http.asyncRequest("GET", `${BASE}/api/users/${__VU}`, null, {
      headers: { Authorization: `Bearer ${__ENV.TOKEN}` },
      tags: { name: "GET /api/users/:id" },
    }),
    http.asyncRequest("GET", `${BASE}/api/cart/${__VU}`, null, {
      headers: { Authorization: `Bearer ${__ENV.TOKEN}` },
      tags: { name: "GET /api/cart/:id" },
    }),
  ]);

  check(userRes, { "user 200": (r) => r.status === 200 });
  check(cartRes, { "cart 200": (r) => r.status === 200 });

  // Dependent call uses results from the parallel calls
  const userId = userRes.json("id");
  if (userId) {
    const orderRes = await http.asyncRequest(
      "POST",
      `${BASE}/api/orders`,
      JSON.stringify({ userId, items: cartRes.json("items") }),
      { headers: { "Content-Type": "application/json" } }
    );
    check(orderRes, { "order created": (r) => r.status === 201 });
  }

  sleep(1);
}
```

> **[community]:** `http.asyncRequest` cannot abort in-flight requests. When using
> `Promise.race()` to get the first responder, the losing requests continue running until
> completion and block VU iteration end. This can cause iteration durations to exceed your
> `sleep()` target — use `Promise.race` only for truly fire-and-forget patterns, not as
> a timeout mechanism. For true per-request timeouts, use the `timeout` param on each
> individual `asyncRequest` call.

### Multi-Step User Journey with `group()`  [community]

`group()` aggregates all request durations within the group into a `group_duration`
metric, enabling per-step SLO thresholds. Use it to decompose a user flow into named
steps for diagnostic clarity.

```javascript
// k6/scripts/user-journey.js
import http from "k6/http";
import { check, group, sleep } from "k6";

export const options = {
  scenarios: {
    journey: {
      executor: "constant-vus",
      vus: 10,
      duration: "2m",
    },
  },
  thresholds: {
    // Per-group thresholds: group name prefixed with ":::"
    "group_duration{group:::login}":    ["avg<500"],
    "group_duration{group:::browse}":   ["avg<300"],
    "group_duration{group:::checkout}": ["avg<800"],
    http_req_failed:                    ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  let token;

  group("login", function () {
    const res = http.post(
      `${BASE}/api/auth/login`,
      JSON.stringify({ email: "test@example.com", password: "password123" }),
      { headers: { "Content-Type": "application/json" } }
    );
    check(res, { "login 200": (r) => r.status === 200 });
    token = res.json("token");
  });

  group("browse", function () {
    const res = http.get(`${BASE}/api/items`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    check(res, { "items 200": (r) => r.status === 200 });
  });

  group("checkout", function () {
    const res = http.post(
      `${BASE}/api/orders`,
      JSON.stringify({ itemId: "sku-001", qty: 1 }),
      { headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      }},
    );
    check(res, { "order 201": (r) => r.status === 201 });
  });

  sleep(1);
}
```

> **Naming tip:** Group names appear in the summary prefixed with `:::`. Keep them short
> and URL-safe — special characters in group names can break some output parsers.

### Browser Module (k6 v0.46+)  [community]

k6's built-in browser module allows mixed protocol + browser tests in one script.
Since v0.52.0 all browser APIs are **async** — always use `async/await`. Browser VUs
are expensive (~10× memory); keep browser scenario VUs low. As of k6 v0.54+ the browser
module includes semantic `getBy*` locators (role, text, label, placeholder, testId)
matching the Playwright API — prefer these over CSS/XPath selectors.

```javascript
// k6/scripts/browser-smoke.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    ui: {
      executor: "shared-iterations",
      vus: 1,
      iterations: 3,
      options: {
        browser: { type: "chromium" },
      },
    },
  },
  thresholds: {
    // Web Vitals thresholds — emitted automatically by the browser module
    "browser_web_vital_fcp":    ["p(75)<3000"],   // First Contentful Paint
    "browser_web_vital_lcp":    ["p(75)<2500"],   // Largest Contentful Paint
    checks:                      ["rate==1.0"],
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/`);

    // Semantic locators (k6 v0.54+ / getBy* API matches Playwright)
    const heading = page.getByRole("heading", { level: 1 });
    await heading.waitFor();
    const headingText = await heading.textContent();
    check(headingText, { "heading not empty": (h) => h && h.length > 0 });

    // Route interception — stub external APIs to isolate performance
    await page.route("**/api/analytics*", (route) => route.abort());

    // Screenshot on each iteration for visual diff
    await page.screenshot({ path: `results/screenshot-${__ITER}.png` });
  } finally {
    // Always close page — required for accurate Web Vitals flush
    await page.close();
  }
}
```

> **Critical [community]:** Browser VUs cannot share the same process as HTTP VUs in
> the same scenario. Use `exec` per scenario to separate browser from protocol flows.
> Each browser VU launches a Chromium subprocess — limit to 10–20 VUs max.

### Browser Route Interception — Mocking & Stubbing  [community]

`page.route(pattern, handler)` intercepts requests matching `pattern` (glob string or `RegExp`).
The handler receives a `Route` object with three response strategies:

| Method | Purpose | When to use |
|--------|---------|-------------|
| `route.abort()` | Block the request entirely | Block tracking pixels, ad scripts, analytics |
| `route.fulfill(response)` | Return a synthetic response | Stub third-party APIs, test error states |
| `route.continue(overrides?)` | Pass through with optional overrides | Add auth headers, rewrite URLs |

Only the **last** registered handler for an overlapping pattern runs. Use `page.unroute(pattern)` to deregister.

```javascript
// k6/scripts/browser-route-mock.js — stub external dependencies for isolated perf tests
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    ui_with_stubs: {
      executor: "shared-iterations",
      vus: 2,
      iterations: 5,
      options: { browser: { type: "chromium" } },
    },
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    // 1. Block analytics — prevents skewing response times with 3rd-party calls
    await page.route("**/gtm.js", (route) => route.abort());
    await page.route("**/analytics/**", (route) => route.abort());

    // 2. Stub a slow payment gateway with a fast synthetic response
    await page.route("**/api/payments/check", (route) =>
      route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({ eligible: true, limit: 5000 }),
      })
    );

    // 3. Inject auth header on all API calls (useful when browser tests need tokens)
    await page.route("**/api/**", (route) =>
      route.continue({
        headers: {
          ...route.request().headers(),
          Authorization: `Bearer ${__ENV.API_TOKEN}`,
        },
      })
    );

    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/checkout`);
    const confirmBtn = page.getByRole("button", { name: "Confirm Order" });
    await confirmBtn.waitFor();
    check(await confirmBtn.isEnabled(), { "confirm button enabled": Boolean });
  } finally {
    await page.close();
  }
}
```

> **[community]:** `route.fulfill()` does not send a real network request — Web Vital
> metrics (LCP, FCP) for the stubbed resource are not collected. Use stubs only for
> isolating the SUT from third-party latency, not for measuring the stub's performance.
> When testing error handling, set `status: 500` or `status: 503` in `route.fulfill()`
> to inject failure scenarios without modifying the server.

### Browser Device Emulation — Mobile Profile Testing  [community]

k6's browser module exposes a `devices` object containing pre-built device profiles (viewport size,
user agent, device scale factor, touch events). Use `browser.newContext({ ...devices['iPhone 14'] })`
to simulate a specific mobile device without manually specifying each option. Essential for measuring
Core Web Vitals from a mobile-user perspective.

```javascript
// k6/scripts/browser-device-emulation.js
// Emulate iPhone 14 for mobile Web Vitals baseline
import { browser, devices } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    mobile_iphone: {
      executor: "shared-iterations",
      vus: 1,
      iterations: 3,
      options: { browser: { type: "chromium" } },
    },
  },
  thresholds: {
    // Mobile budgets are tighter — use device-specific LCP/INP targets
    "browser_web_vital_lcp":    ["p(75)<4000"],   // 4s LCP for mobile on 4G
    "browser_web_vital_inp":    ["p(75)<300"],    // INP (replaces FID in v2.0)
    "browser_web_vital_fcp":    ["p(75)<3000"],   // 3s FCP for mobile
    checks:                      ["rate==1.0"],
  },
};

// Available profiles include: 'iPhone 14', 'iPhone 14 Plus', 'iPhone 14 Pro',
// 'Pixel 7', 'Galaxy S23', 'iPad Pro 11', 'Desktop Chrome', 'Desktop Firefox'
// Run `k6 x docs k6/browser` to list all available devices
const iPhoneProfile = devices["iPhone 14"];

export default async function () {
  // Spread device profile into context options — sets viewport, userAgent,
  // deviceScaleFactor, isMobile, hasTouch, defaultBrowserType automatically
  const ctx  = await browser.newContext({
    ...iPhoneProfile,
    // Override locale/timezone for locale-sensitive tests
    locale:   "en-US",
    timezoneId: "America/New_York",
  });
  const page = await ctx.newPage();

  try {
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/`);
    await page.waitForLoadState("networkidle");

    // Touch events fire correctly due to isMobile: true in the device profile
    const signupBtn = page.getByRole("button", { name: "Sign Up" });
    await signupBtn.waitFor({ state: "visible" });

    // Tap (not click) — correct for touch devices
    await signupBtn.tap();

    const heading = page.getByRole("heading", { level: 1 });
    check(await heading.textContent(), {
      "heading visible on mobile": (t) => t && t.length > 0,
    });

    await page.screenshot({ path: `results/mobile-${__ITER}.png` });
  } finally {
    await page.close();
    await ctx.close();
  }
}
```

```javascript
// Side-by-side: desktop vs. mobile Web Vitals comparison
import { browser, devices } from "k6/browser";
import { check } from "k6";
import { Trend } from "k6/metrics";

const lcpDesktop = new Trend("lcp_desktop_ms", true);
const lcpMobile  = new Trend("lcp_mobile_ms",  true);

export const options = {
  scenarios: {
    desktop: {
      executor: "shared-iterations",
      vus: 1, iterations: 3,
      exec: "desktopFlow",
      options: { browser: { type: "chromium" } },
    },
    mobile: {
      executor: "shared-iterations",
      vus: 1, iterations: 3,
      startTime: "15s",
      exec: "mobileFlow",
      options: { browser: { type: "chromium" } },
    },
  },
};

const APP = __ENV.APP_URL || "http://localhost:3001";

export async function desktopFlow() {
  const page = await browser.newPage();
  try {
    await page.goto(`${APP}/`);
    await page.waitForLoadState("networkidle");
    // LCP emitted automatically — read from data.metrics in handleSummary
    check(page.url(), { "desktop loaded": (u) => !u.includes("error") });
  } finally { await page.close(); }
}

export async function mobileFlow() {
  const ctx = await browser.newContext({ ...devices["Pixel 7"] });
  const page = await ctx.newPage();
  try {
    await page.goto(`${APP}/`);
    await page.waitForLoadState("networkidle");
    check(page.url(), { "mobile loaded": (u) => !u.includes("error") });
  } finally { await page.close(); await ctx.close(); }
}
```

> **[community]:** The `devices` object is imported from `"k6/browser"` — NOT from a
> separate module. It mirrors the Playwright `devices` object, so teams familiar with
> Playwright's device profiles can reuse the same names. If a device name doesn't exist
> in k6's built-in list, `devices['Unknown Device']` returns `undefined` and
> `browser.newContext({ ...undefined })` throws a runtime error — always verify device
> names against the k6 docs or `k6 x docs k6/browser`.

> **[community]:** When emulating mobile devices, set `K6_BROWSER_ARGS="--no-sandbox
> --disable-dev-shm-usage"` in Docker/CI environments — the device profile changes the
> viewport size which triggers Chromium to re-initialize its renderer process, consuming
> more `/dev/shm` than a headless desktop session.

Use `k6/net/grpc` for gRPC service performance tests. Load `.proto` files in the init
context (not inside `default`) — loading per-iteration recreates the client on every VU
iteration, causing severe memory and CPU overhead.

```javascript
// k6/scripts/grpc-load.js
import grpc from "k6/net/grpc";
import { check, sleep } from "k6";

// INIT CONTEXT: load proto once per VU
const client = new grpc.Client();
client.load(["./proto"], "items.proto");

export const options = {
  scenarios: {
    grpc_load: {
      executor: "constant-arrival-rate",
      rate: 50,
      timeUnit: "1s",
      duration: "1m",
      preAllocatedVUs: 20,
      maxVUs: 80,
    },
  },
  thresholds: {
    "grpc_req_duration":             ["p(95)<200", "p(99)<500"],
    "grpc_req_duration{status:OK}":  ["p(95)<150"],
    checks:                           ["rate>0.99"],
  },
};

const TARGET = __ENV.GRPC_TARGET || "localhost:50051";

export default function () {
  // Open a connection per VU iteration (close at end to return to pool)
  client.connect(TARGET, { plaintext: true });

  const payload = { name: `item-${__ITER}`, quantity: 1 };
  const response = client.invoke("items.ItemService/CreateItem", payload);

  check(response, {
    "status OK":    (r) => r && r.status === grpc.StatusOK,
    "has item id":  (r) => r.message && r.message.id !== undefined,
  });

  client.close();
  sleep(0.1);
}
```

### HMAC Request Signing  [community]

APIs that use HMAC signatures (AWS Signature v4, custom HMAC auth) require a valid
signature on every request. k6's legacy `k6/crypto` module provides `hmac()` for
synchronous signing; the newer WebCrypto `crypto.subtle` API supports async HMAC
and PBKDF2 for production-grade cryptographic operations.

```javascript
// k6/scripts/hmac-signed-load.js — HMAC request signing (synchronous legacy API)
import http from "k6/http";
import { check, sleep } from "k6";
import crypto from "k6/crypto";

const SECRET_KEY = __ENV.HMAC_SECRET || "test-hmac-secret-32bytes-padding!";
const BASE = __ENV.API_URL || "http://localhost:3001";

/**
 * Simple HMAC-SHA256 request signing helper.
 * Each request includes: X-Timestamp, X-Signature headers.
 */
function signedRequest(method, path, body = "") {
  const timestamp = String(Date.now());
  const signingString = `${method}\n${path}\n${timestamp}\n${body}`;

  // k6/crypto.hmac() — synchronous, no async overhead
  const signature = crypto.hmac("sha256", SECRET_KEY, signingString, "hex");

  return {
    headers: {
      "Content-Type":  "application/json",
      "X-Timestamp":   timestamp,
      "X-Signature":   signature,
    },
  };
}

export const options = {
  scenarios: {
    signed_load: {
      executor: "constant-vus",
      vus: 10,
      duration: "2m",
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<300"],
    http_req_failed:   ["rate<0.01"],
    checks:            ["rate>0.99"],
  },
};

export default function () {
  const path = "/api/secure/items";

  // GET — no body to sign
  const getRes = http.get(
    `${BASE}${path}`,
    signedRequest("GET", path)
  );
  check(getRes, {
    "list 200":         (r) => r.status === 200,
    "not 401":          (r) => r.status !== 401,  // catches invalid signatures
  });

  // POST with body signature
  const body = JSON.stringify({ name: `item-${__ITER}` });
  const postRes = http.post(
    `${BASE}${path}`,
    body,
    signedRequest("POST", path, body)
  );
  check(postRes, {
    "create 201":       (r) => r.status === 201,
    "not 401":          (r) => r.status !== 401,
  });

  sleep(1);
}
```

> **[community]:** Never use the `k6/crypto` `hmac()` function with rotating secrets
> loaded from `open()`. The secret is baked at init time per VU — if the secret rotates
> during a soak test, VUs continue using stale secrets and produce 401 errors. Use
> `k6/secrets` with async `get()` per iteration for rotating HMAC secrets.

> **Note:** `k6/crypto` is deprecated — the official docs recommend using the WebCrypto API
> (`crypto.subtle`) instead for new code. `k6/crypto` remains available for backward
> compatibility. The `crypto.subtle` API (k6 v1.6+) adds PBKDF2 support for password-based
> key derivation, enabling realistic simulation of client-side key derivation flows:
> ```javascript
> // WebCrypto PBKDF2 — derive an AES key from a password (async)
> const keyMaterial = await crypto.subtle.importKey(
>   "raw",
>   new TextEncoder().encode(__ENV.USER_PASSWORD),
>   { name: "PBKDF2" },
>   false,
>   ["deriveBits", "deriveKey"]
> );
> const derivedKey = await crypto.subtle.deriveKey(
>   { name: "PBKDF2", salt: new TextEncoder().encode("test-salt"), iterations: 100_000, hash: "SHA-256" },
>   keyMaterial,
>   { name: "AES-GCM", length: 256 },
>   true,
>   ["encrypt", "decrypt"]
> );
> ```

### Cookie Jar & Session Management  [community]

For scenarios requiring persistent session state across requests — such as login + cart +
checkout flows — use k6's built-in cookie jar API. The default jar persists cookies
automatically; for VU isolation, create an explicit jar per VU.

```javascript
// k6/scripts/session-flow.js
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    sessions: { executor: "constant-vus", vus: 10, duration: "2m" },
  },
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  // Each VU gets its own jar — prevents session leakage across VUs
  const jar = new http.CookieJar();

  const loginRes = http.post(
    `${BASE}/api/auth/login`,
    JSON.stringify({ email: "test@example.com", password: "pass123" }),
    { headers: { "Content-Type": "application/json" }, jar }
  );
  check(loginRes, { "login 200": (r) => r.status === 200 });

  // Authenticated request — session cookie flows automatically via jar
  const profileRes = http.get(`${BASE}/api/profile`, { jar });
  check(profileRes, { "profile 200": (r) => r.status === 200 });

  // Manual cookie inspection for debugging
  const cookies = jar.cookiesForURL(`${BASE}/api/profile`);
  check(Object.keys(cookies), { "session cookie present": (c) => c.length > 0 });

  sleep(1);
}
```

> **[community]:** k6's default HTTP client shares a global cookie jar across all requests
> in a VU. Creating an explicit `new http.CookieJar()` per VU prevents stale cookies from
> previous iterations from affecting auth state.

### Sequential Scenario Warm-Up with `startTime`  [community]

When multiple scenarios must not compete at startup, use `startTime` offsets to sequence
them. Running all scenarios at `t=0` creates resource contention that obscures which
scenario caused a degradation.

```javascript
// k6/scripts/sequenced.js
export const options = {
  scenarios: {
    // Phase 1: warm up the cache / auth system
    warm_up: {
      executor: "shared-iterations",
      vus: 5,
      iterations: 50,
      startTime: "0s",
    },
    // Phase 2: sustained load — only starts after warm-up completes
    sustained_load: {
      executor: "constant-vus",
      vus: 20,
      duration: "2m",
      startTime: "1m",   // wait 1 min for warm-up to finish
    },
    // Phase 3: spike — fires at the 3-minute mark to test recovery
    spike: {
      executor: "ramping-vus",
      startVUs: 10,
      stages: [
        { duration: "10s", target: 100 },
        { duration: "20s", target: 10  },
      ],
      startTime: "3m",
    },
  },
};
```

### Environment Configuration & Per-Environment Thresholds  [community]

Hardcoding thresholds for production-tier SLOs will fail in under-resourced QA environments.
Use a config module that scales thresholds based on `__ENV.TEST_ENV`:

```javascript
// k6/lib/thresholds.js — reusable threshold config per environment
export function getThresholds(env = "qa") {
  const profiles = {
    // QA env is under-resourced — looser SLOs acceptable for development validation
    qa: {
      http_req_duration: ["p(95)<1000", "p(99)<2000"],
      http_req_failed:   ["rate<0.05"],
      checks:            ["rate>0.95"],
    },
    // Staging matches production capacity — strict SLOs
    staging: {
      http_req_duration: ["p(95)<300", "p(99)<800"],
      http_req_failed:   ["rate<0.01"],
      checks:            ["rate>0.99"],
    },
    // Production canary — tightest SLOs
    production: {
      http_req_duration: ["p(95)<200", "p(99)<500"],
      http_req_failed:   ["rate<0.005"],
      checks:            ["rate>0.999"],
    },
  };
  return profiles[env] || profiles.qa;
}

// k6/scripts/load.js — use the config module
import { getThresholds } from "../lib/thresholds.js";

export const options = {
  scenarios: {
    load: {
      executor: "ramping-vus",
      stages: [
        { duration: "30s", target: 20 },
        { duration: "2m",  target: 20 },
        { duration: "15s", target: 0  },
      ],
    },
  },
  // Thresholds scale with the environment
  thresholds: getThresholds(__ENV.TEST_ENV || "qa"),
};
```

Run with:
```bash
# CI — QA environment (default)
k6 run -e API_URL=https://api.qa.example.com k6/scripts/load.js

# CI — Staging
k6 run -e API_URL=https://api.staging.example.com -e TEST_ENV=staging k6/scripts/load.js

# K6_ prefix options — configure k6 itself (not the script)
K6_VUS=5 K6_DURATION=60s k6 run k6/scripts/load.js  # quick override for local dev
```

> **[community]:** The `K6_` prefix configures k6 options (VUs, duration, etc.) via
> environment variables — but `K6_SCENARIOS` and `K6_THRESHOLDS` are NOT supported this way.
> For complex options, always use the `options` export in the script.

| Test Type | Executor | Profile | Goal |
|-----------|----------|---------|------|
| Smoke | `constant-vus` | 1–2 VUs, 1–2 min | Verify script works |
| Load | `ramping-vus` | Ramp → sustain → down | Validate at expected traffic |
| Stress | `ramping-vus` | Ramp beyond normal | Find the breaking point |
| Soak | `ramping-vus` | Normal load, 1–8 h | Surface memory leaks |
| Spike | `ramping-vus` | Instant peak → drop | Test auto-scaling |
| Breakpoint | `ramping-arrival-rate` | Continuously increase RPS | Find max throughput |

**Design philosophy:** "Stick to simple load patterns. For all test types, direction is enough: ramp-up, plateau, ramp-down. Avoid 'rollercoaster' series where load increases and decreases multiple times."

---

---

### HTML Parsing with `k6/html` — CSRF Token Extraction  [community]

The `k6/html` module provides a jQuery-compatible DOM parser for HTML responses. Its most
important production use case is **CSRF token extraction** from server-rendered forms —
a prerequisite for load testing traditional server-side applications with CSRF protection.

Without this pattern, POST/PUT requests are rejected with 403 (CSRF token mismatch) and
teams assume the test environment is broken when in reality they just need to read the token
from the page HTML first.

```javascript
// k6/scripts/csrf-form-submit.js — CSRF token extraction + form submission
import http from "k6/http";
import { parseHTML } from "k6/html";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    form_submit: {
      executor: "ramping-vus",
      stages: [
        { duration: "30s", target: 10 },
        { duration: "1m",  target: 10 },
        { duration: "15s", target: 0  },
      ],
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.APP_URL || "http://localhost:3001";

export default function () {
  // Step 1: GET the form page — server sets session cookie and renders CSRF token
  const loginPage = http.get(`${BASE}/login`);
  check(loginPage, { "login page 200": (r) => r.status === 200 });

  // Step 2: Extract CSRF token from the rendered HTML
  const doc   = parseHTML(loginPage.body);

  // Common patterns: hidden input, meta tag, or custom attribute
  const csrfToken =
    doc.find('input[name="_csrf"]').val()          ||   // Rails / Express CSRF hidden input
    doc.find('input[name="csrf_token"]').val()      ||   // Django CSRF input
    doc.find('meta[name="csrf-token"]').attr("content"); // Rails AJAX meta tag

  if (!csrfToken) {
    console.warn(`[VU ${__VU}] No CSRF token found — form submission may fail`);
  }

  // Step 3: Submit the form with the extracted token
  // k6 automatically sends cookies set by the GET request (same VU cookie jar)
  const loginRes = http.post(
    `${BASE}/login`,
    {
      email:      "user@example.com",
      password:   "password123",
      _csrf:      csrfToken,           // include the extracted token
    },
    {
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      redirects: 0,  // intercept redirect to check for successful login
      tags: { name: "POST /login" },
    }
  );

  check(loginRes, {
    "login redirect (302)": (r) => r.status === 302,  // success = redirect to dashboard
    "not 403 CSRF error":   (r) => r.status !== 403,
  });

  sleep(1);
}
```

**Additional `k6/html` patterns:**

```javascript
// Link extraction — spider/crawl pattern
const links = parseHTML(res.body).find("a[href]").toArray()
  .map((el) => el.attr("href"))
  .filter((href) => href && href.startsWith("/"));  // internal links only

// Table row parsing — extract data from HTML tables (e.g., pricing tables)
const rows = parseHTML(res.body).find("table tbody tr").toArray()
  .map((row) => ({
    name:  row.find("td:first-child").text().trim(),
    price: parseFloat(row.find("td.price").text().replace("$", "")),
  }));

// Form field serialization — build a form submission from a rendered form
const formData = parseHTML(res.body).find("#checkout-form").serializeObject();
// Returns: { field1: "value1", field2: "value2", _csrf: "token123", ... }
// Then submit:
http.post(`${BASE}/checkout`, formData);
```

> **[community]:** `k6/html` performs no CSS layout computation — `css()` and `offset()`
> methods are not available (they throw). DOM trees are read-only: you cannot call
> `setAttribute()` or modify nodes. Use it for extraction only, not DOM manipulation.
> For complex form flows with dynamic JS-rendered content, use the browser module instead.

---

## Real-World Gotchas  [community]

These are production-discovered pitfalls sourced from community experience — the official
docs mention none of them directly.

### 1. Duplicate threshold keys silently ignored  [community]
**What:** If you define the same metric key twice in the `thresholds` object, JavaScript
silently discards the second entry. No error, no warning — just phantom thresholds.
**WHY:** JavaScript object literals enforce key uniqueness; the second assignment overwrites
the first at parse time, so only one threshold expression ever runs.
**Fix:** Use array syntax for multiple expressions on one metric:
```javascript
thresholds: {
  http_req_duration: ["p(95)<200", "p(99)<500"],  // correct: array
  // NOT: http_req_duration: "p(95)<200", http_req_duration: "p(99)<500"
}
```

### 2. `abortOnFail` fires before warm-up completes  [community]
**What:** Setting `abortOnFail: true` without `delayAbortEval` causes the test to abort
during the initial ramp-up when the system is cold and error rates are transiently high.
The test exits with exit code 99 but the result is a false failure.
**WHY:** Threshold evaluation starts at time 0; a single failed request in the first few
seconds can push `rate` above the threshold before enough samples accumulate.
**Fix:** Always pair `abortOnFail` with `delayAbortEval: "30s"` (or `"60s"` for soak
tests) to let the system warm up before evaluation begins.

### 3. Grafana Cloud threshold evaluation has a 60-second lag  [community]
**What:** When running in Grafana Cloud, thresholds evaluate every 60 seconds — not in
real time. If you expect `abortOnFail` to stop a test within seconds of a spike, it won't.
**WHY:** Distributed cloud architecture requires periodic metric aggregation across
load-generation infrastructure; real-time threshold evaluation is not feasible at scale.
**Fix:** Use stricter margins in cloud thresholds to account for the lag, and use
`delayAbortEval` values larger than 60s.

### 4. All concurrent scenarios starting at t=0 causes root-cause blindness  [community]
**What:** Launching all scenarios simultaneously makes it impossible to attribute a
performance degradation to any specific scenario — all are running and all metrics mix.
**WHY:** When 3-5 scenarios all fire at the same time, CPU/DB connection saturation may
be caused by any one of them; per-scenario thresholds narrow it down but cannot isolate
contention at the infrastructure layer.
**Fix:** Use `startTime` offsets to stagger scenario launches (see Sequential Scenario
Warm-Up pattern above). Start with the scenario you most need a clean baseline on.

### 5. `SharedArray` `.filter()` / `.map()` breaks memory sharing  [community]
**What:** Calling `.filter()` or `.map()` on a `SharedArray` reference (outside its
constructor) silently converts it to a regular JS array, creating per-VU copies.
With 500 VUs and a 100 MB dataset this exhausts memory and crashes the test agent.
**WHY:** `SharedArray` wraps a shared memory buffer; standard Array prototype methods
return new plain JS arrays that are not backed by the shared buffer.
**Fix:** Do all data transformations inside the `new SharedArray(name, fn)` callback so
the result is baked into the shared memory at init time.

### 6. Node file-descriptor limit kills high-VU tests on Linux CI  [community]
**What:** At ~1,024 concurrent VUs (default OS limit), k6 starts failing with
"socket: too many open files". The test appears to "break" at that exact VU count, which
teams often misattribute to the target system rather than the load generator.
**WHY:** Each active HTTP connection consumes one file descriptor; the default Linux limit
of 1,024 is far too low for any serious load test.
**Fix:** Set `ulimit -n 250000` (or `65536` as a minimum) before running k6 in CI.
Also expand kernel port range: `sysctl -w net.ipv4.ip_local_port_range="1024 65535"`.

### 7. Large test datasets consume memory proportional to VU count without `SharedArray`  [community]
**What:** A 50 MB JSON fixture loaded via `open()` in `default()` costs 50 MB × VU count.
With 200 VUs that is 10 GB — the k6 process is OOM-killed and CI reports an unclear exit.
**WHY:** Without `SharedArray`, each VU parses and holds its own copy of the data in the
V8 heap. k6 does not automatically share read-only fixture data.
**Fix:** Always wrap fixture data in `new SharedArray(...)` at init time. One parse,
one memory allocation, shared across all VUs.

### 8. `--summary-export` is deprecated — use `handleSummary` instead  [community]
**What:** Teams relying on `--summary-export results/summary.json` find that newer k6
versions emit deprecation warnings and the flag may be removed in future releases. CI
pipelines silently produce empty or malformed output files.
**WHY:** The flag was superseded by the `handleSummary()` hook which gives full control
over output format (JSON, JUnit XML, HTML) and allows writing multiple output files in
one pass.
**Fix:** Replace `--summary-export` with a `handleSummary` export in your script (see
CI Considerations section below).

### 9. Closed-model VU executor under high latency creates explosive load  [community]
**What:** Under `ramping-vus` / `constant-vus` (closed models), if the target system slows
down, VUs pile up waiting for responses. When the backlog clears, all VUs fire simultaneously —
creating a self-reinforcing load spike that spirals beyond the intended profile.
**WHY:** Closed-model executors always maintain N concurrent VUs; they do NOT throttle based
on response time. If each request takes 10s instead of 1s, each VU queues for 10s then
fires again immediately — effectively multiplying throughput by 10×.
**Fix:** For SLA validation at a specific RPS, use `constant-arrival-rate`. Reserve
closed-model executors for simulating a fixed number of concurrent sessions.

### 10. Missing `sleep()` turns a load test into a DoS attack  [community]
**What:** VU-based executors run the `default` function as fast as possible. A script with
no `sleep()` call hammers the target at wire speed — far beyond any real user behavior.
**WHY:** k6 VUs are not throttled by default; they loop immediately on iteration completion.
Without `sleep(thinkTime)`, a 10-VU test can generate 10,000+ req/s on fast endpoints.
**Fix:** Always add `sleep(thinkTime)` at the end of each iteration. For realistic browser
simulation, model 1-3s think time between page requests. For API micro-benchmarks where
raw throughput is the goal, use `constant-arrival-rate` with explicit `rate` instead.

### 11. `K6_` env var prefix only configures scalar options  [community]
**What:** Teams try `K6_SCENARIOS=...` or `K6_THRESHOLDS=...` via environment variables
expecting them to work like the script's `options` export. They silently have no effect.
**WHY:** k6 only maps a specific subset of flat options to `K6_*` variables (e.g.,
`K6_VUS`, `K6_DURATION`, `K6_OUT`). Complex nested objects like `scenarios` and
`thresholds` are not supported via env vars — they require the script's `options` export.
**Fix:** Use the `options` export for all scenario and threshold configuration.
Use `K6_*` only for simple overrides (`K6_VUS=5 k6 run ...`) during local development.

### 12. Per-request `responseType: "none"` more granular than global `discardResponseBodies`  [community]
**What:** Setting `discardResponseBodies: true` globally prevents reading any response
body — including responses where `check()` validates body content. Flipping the global
flag breaks content assertions.
**WHY:** `discardResponseBodies` is a blunt global toggle. At high throughput, teams set
it to save memory, then discover their `check()` assertions on `r.json()` return null.
**Fix:** Leave `discardResponseBodies: false` (default) globally. For specific high-volume
endpoints where you don't need the body, set `responseType: "none"` per request:
```javascript
// Only discard body for the metrics ping — still read body for auth and checkout
http.get(`${BASE}/api/health`,   { responseType: "none" });  // high-freq, body unneeded
const res = http.post(`${BASE}/api/checkout`, body, params); // body needed for check()
check(res, { "order id present": (r) => r.json("id") !== undefined });
```

### 13. `dropped_iterations` silently skipped in arrival-rate tests  [community]
**What:** When `constant-arrival-rate` or `ramping-arrival-rate` cannot keep up — because
all `maxVUs` are busy — iterations are silently dropped. The metric `dropped_iterations`
increments but teams don't notice unless they threshold on it.
**WHY:** k6 design choice: it will not exceed `maxVUs` — but it also will not warn by default
if scheduled iterations are skipped. A test that drops 5% of iterations reports inflated
success rates on the iterations that DID run.
**Fix:** Always add a `dropped_iterations` threshold:
```javascript
thresholds: {
  dropped_iterations: ["count<50"],  // fail if more than 50 iterations dropped
}
```
If this threshold fires, increase `preAllocatedVUs` and `maxVUs`.

### 14. `discardResponseBodies` overlooked in high-throughput tests  [community]
**What:** At 10,000+ RPS, k6 allocates memory for every response body even if your
script never reads them. Memory climbs steadily; tests fail after 20-30 minutes.
**WHY:** k6 stores response bodies in VU memory by default. At scale this becomes the
dominant memory consumer, not VU count itself.
**Fix:** Set `discardResponseBodies: true` in `options` for any test that does not
inspect response bodies. For mixed scripts, set `responseType: "none"` per-request.
```javascript
export const options = {
  discardResponseBodies: true,
  // ...
};
```

### 15. Local ESM imports require explicit `.js` extension  [community]
**What:** Teams migrating from Node.js write `import { helper } from "./lib/auth"` — this
works in Node but silently fails in k6 with "cannot find module" or resolves to the wrong file.
**WHY:** k6 uses browser-style ESM resolution, not Node.js CJS resolution. Extensionless
imports are not auto-resolved to `.js` — the full filename is required.
**Fix:** Always include the `.js` extension in local imports:
```javascript
// ❌ Node-style — fails in k6
import { authParams } from "./lib/auth";

// ✓ k6/browser-style — works
import { authParams } from "./lib/auth.js";
```
Also: k6 does not support bare npm package imports (e.g., `import _ from "lodash"`) —
bundle npm dependencies with webpack/rollup first and import the bundle.

---

### 16. `k6/experimental/*` modules removed / deprecated in k6 v1.x  [community]
**What:** Scripts using `k6/experimental/websockets`, `k6/experimental/redis`, or
`k6/experimental/tracing` emit deprecation warnings in k6 v1.x and will break when
those namespaces are removed.
**WHY:** "Experimental" modules are graduation paths to stable APIs. Once graduated,
the `experimental/` path is deprecated. Continuing to use them creates a silent migration
debt that surfaces as breakage during k6 upgrades.
**Fix:** Audit imports on every k6 major version bump. Migrations to stable equivalents:
- `k6/experimental/websockets` → `k6/websockets`
- `k6/experimental/redis` → **removed in v2.0** — use `k6/x/redis` extension (`xk6 build --with github.com/grafana/xk6-redis`)
- `k6/experimental/tracing` → use OpenTelemetry output (`--out opentelemetry`) instead

### 17. GraphQL 200-response errors bypass HTTP error thresholds  [community]
**What:** GraphQL servers return HTTP 200 even for auth failures, missing fields, and resolver
crashes. A threshold on `http_req_failed` will show 0% failure even when 100% of queries are
returning `{ "errors": [...] }` in the body.
**WHY:** GraphQL spec mandates that the transport layer always uses HTTP 200 for query-level
errors; only genuine network or server errors produce 4xx/5xx responses. `http_req_failed`
monitors HTTP-layer errors only — it has no visibility into the GraphQL `errors` array.
**Fix:** Create a `Rate` custom metric for GraphQL errors, populate it in your `check()` body
assertion, and threshold on it:
```javascript
const graphqlErrors = new Rate("graphql_errors");
// In check: graphqlErrors.add(body.errors && body.errors.length > 0 ? 1 : 0);
thresholds: { "graphql_errors": ["rate<0.01"] }
```

### 18. `setup()` token cannot refresh itself — soak tests silently 401 after token expiry  [community]
**What:** Tokens obtained in `setup()` are serialized once and distributed to all VUs at
test start. They cannot be refreshed from within `setup()` because `setup()` runs once.
For 8-hour soak tests with 1-hour JWT TTLs, all VUs start failing at the 55-minute mark
while dashboards still show healthy throughput (because the 401 responses process quickly).
**WHY:** k6 serializes `setup()`'s return value to JSON and passes copies to VUs. There is
no mechanism for `setup()` to push a new value mid-run. Each VU must manage its own token
state using a per-VU token manager (see JWT Token Refresh pattern above).
**Fix:** Implement a token manager that tracks expiry and refreshes proactively. Initialize
it in the VU's init context; never rely on `setup()` for credentials in soak tests.

### 19. WebSocket `default` function runs once per VU, not in a loop  [community]
**What:** Teams migrating from HTTP tests wrap WebSocket code in the `default` function and
expect it to loop like HTTP. In the `k6/websockets` module, `default` runs **once** per VU —
the event loop drives the scenario. Without a `setTimeout()` to close the socket, VUs block
indefinitely, accumulating open connections until the test hangs.
**WHY:** The `k6/websockets` module implements the W3C WebSocket living standard, which uses
a persistent event loop. The VU is blocked by the active socket until it closes — there is
no iteration loop.
**Fix:** Always set a `setTimeout(() => ws.close(), durationMs)` inside `onopen`. For
iteration-based WebSocket tests, use `setInterval` to send periodic messages and
`setTimeout` for the connection lifetime cap.

### 20. Async/eventual consistency latency hidden by fast HTTP publish response  [community]
**What:** An event-driven endpoint responds in 5ms (accepted / 202 status). The `http_req_duration`
threshold of p(95)<200ms passes with flying colors. The actual task takes 45 seconds to process.

### 21. `browser_web_vital_fid` removed in k6 v2.0 — dashboards silently stop reporting  [community]
**What:** k6 v2.0 removes the `browser_web_vital_fid` metric (First Input Delay). CI pipelines
and Grafana dashboards that threshold on it receive no data — thresholds silently pass because
there is nothing to evaluate against.
**WHY:** Google replaced FID with INP (Interaction to Next Paint) as a Core Web Vital in March
2024. k6 v2.0 followed suit by removing FID tracking. Existing thresholds on `browser_web_vital_fid`
pass vacuously rather than failing with an error, masking a broken monitoring pipeline.
**Fix:** Update all browser thresholds to use `browser_web_vital_inp`. INP measures responsiveness
across all user interactions, not just the first one — the budget is higher (200ms recommended
vs. 100ms for FID).
```javascript
// BEFORE (k6 v1.x)
thresholds: { "browser_web_vital_fid": ["p(75)<100"] }

// AFTER (k6 v2.0)
thresholds: { "browser_web_vital_inp": ["p(75)<200"] }
```

### 22. `externally-controlled` executor removed in k6 v2.0 — scripts silently misconfigured  [community]
**What:** k6 v2.0 removes the `externally-controlled` executor entirely. A script with this
executor fails immediately at startup. CI pipelines that were controlling VUs via the k6 REST
API also break — the pause/resume/scale endpoints are gone.
**WHY:** The REST API for external control was a rarely-used feature requiring a separate
operator process. The k6 team removed it to simplify the runtime. The `k6 pause`, `k6 resume`,
`k6 scale`, and `k6 status` commands also relied on it and are all removed in v2.0.
**Fix:** Replace `externally-controlled` with `ramping-vus` using explicit `stages`. For
external sequencing, use `startTime` offsets between scenarios. For CI-driven VU changes,
use `k6 run` with different `options` objects per CI step.

### 23. `--no-summary` flag removed in k6 v2.0 — CI scripts error out on upgrade  [community]
**What:** k6 v2.0 removes the `--no-summary` CLI flag. Scripts and CI steps that use it
fail with an unrecognised flag error — typically surfacing as a `108 Usage error` exit code.
**WHY:** The flag was replaced by the more flexible `--summary-mode` option which supports
`disabled`, `compact`, `full`, and `legacy` modes. The goal was a consistent, extensible
summary control API rather than a simple boolean toggle.
**Fix:** Replace `--no-summary` with `--summary-mode=disabled` in all CI pipeline steps.

### 24. OTEL Rate metrics format changed in k6 v2.0 — Grafana dashboards break silently  [community]
**What:** k6 v2.0 changes how Rate custom metrics are exported via OpenTelemetry. Previously
Rate metrics exported as a pair of counters (`metric_name.occurred` / `metric_name.total`).
In v2.0, they export as a single `Int64Counter` with a `condition` attribute (`zero` / `nonzero`).
Existing dashboards and queries that used `metric_name.occurred` stop working silently.
**WHY:** The pair-of-counters approach required consumers to know about k6's internal
structure. The attribute-based approach follows OTEL conventions for categorical data.
**Fix:** Update Grafana panels that query OTEL Rate metrics. Replace `metric_name.occurred`
queries with a filter on the `condition="nonzero"` attribute on the unified counter.

### 25. Cloud non-threshold abort exit code changed to 97 in k6 v2.0  [community]
**What:** In k6 v1.x, k6 cloud tests aborted for non-threshold reasons (infrastructure failures,
programmatic `exec.test.abort()` calls) returned exit code `0`. Pipelines that checked `exit 0`
as "test passed" would silently accept these as successes. k6 v2.0 changes this to exit code `97`.
**WHY:** Returning `0` for an infrastructure abort was a misleading success signal. Exit code `97`
allows CI pipelines to distinguish between "test passed" (0), "threshold failed" (99), and
"test aborted abnormally" (97).
**Fix:** Update CI success conditions. Check for exit code `0` specifically for threshold-clean
passes; handle `97` as an abnormal abort requiring investigation; `99` as a threshold failure.

### 26. `sleep()` in arrival-rate executor iterations causes dropped iterations  [community]
**What:** Adding `sleep()` at the end of an iteration in a `constant-arrival-rate` or
`ramping-arrival-rate` script defeats the executor's pacing logic. The executor controls
iteration rate via the `rate` and `timeUnit` options — a VU blocked by `sleep()` cannot
accept new iterations, causing the rate to be lower than intended and iterations to be dropped.
**WHY:** Arrival-rate executors are open-model: they schedule iterations independently of
response time. Unlike `ramping-vus` where `sleep()` models think time, arrival-rate
executors already bake the inter-iteration gap into the `rate` parameter. Adding `sleep()`
effectively reduces the executor's actual throughput capacity.
**Fix:** Remove `sleep()` from arrival-rate executor scripts. If you want to model think
time as part of the load profile, factor it into the `rate` calculation or use
`ramping-vus` which is a closed-model executor designed for think-time simulation.
```javascript
// ❌ Wrong — sleep in arrival-rate halves effective throughput
export default function () {
  http.get(`${BASE}/api/items`);
  sleep(1);  // blocks VU for 1s, preventing new arrivals from being handled
}

// ✓ Correct — no sleep needed; rate/timeUnit controls pacing
export default function () {
  const res = http.get(`${BASE}/api/items`);
  check(res, { "status 200": (r) => r.status === 200 });
}
```

### 27. `http_req_duration` excludes DNS + TCP + TLS — user-perceived SLO validation is incomplete  [community]
**What:** `http_req_duration` measures only `sending + waiting + receiving` — it does NOT include
DNS resolution, TCP handshake, or TLS negotiation time. A threshold of `p(95)<200ms` on
`http_req_duration` can pass while users experience 600ms on cold connections (200ms DNS +
150ms TCP + 50ms TLS + 200ms server = 600ms).
**WHY:** k6 separates connection overhead (`http_req_blocked`, `http_req_connecting`,
`http_req_tls_handshaking`) from server processing (`http_req_waiting`) and data transfer
(`http_req_sending`, `http_req_receiving`). This is intentional — it lets you pinpoint WHERE
latency comes from. But teams only threshold on `http_req_duration` and miss the full picture.
**Fix:** Add a custom `Trend` metric for total perceived latency:
```javascript
const perceived = new Trend("perceived_latency_ms", true);
// After each request:
const t = res.timings;
perceived.add(t.blocked + t.connecting + t.tls_handshaking + t.duration);
```
Then threshold on `perceived_latency_ms` for user-facing SLOs, and `http_req_duration`
for server-side SLOs separately.

### 28. Dynamic URL IDs cause metric cardinality explosion — thresholds become unusable  [community]
**What:** URLs like `/api/users/123/orders` and `/api/users/456/orders` are tracked as
separate metrics by k6's URL tag. With 10,000 unique user IDs, you get 10,000 metric
series in InfluxDB/Prometheus — dashboards crash, threshold expressions become impossible
to write, and storage costs spike.
**WHY:** k6 auto-tags each request with the full URL string. Dynamic path segments generate
a unique metric series per distinct URL value. At 100+ unique IDs this is noisy; at 10k+ it
causes cardinality-related storage failures in most time-series databases.
**Fix:** Use the `name` tag to normalize URLs to a route pattern:
```javascript
http.get(
  `${BASE}/api/users/${userId}/orders`,
  { tags: { name: "GET /api/users/:id/orders" } }  // normalized name → 1 metric series
);

// For REST CRUD APIs, helper to auto-normalize:
function api(method, path, body, params = {}) {
  // Replace numeric IDs with :id placeholder
  const name = path.replace(/\/\d+/g, "/:id");
  return http.request(method, `${BASE}${path}`, body,
    { ...params, tags: { ...params.tags, name: `${method} ${name}` } }
  );
}
// Usage: api("GET", `/api/users/${id}/orders`, null)
// Metric name tag: "GET /api/users/:id/orders"
```

---

### 29. `__VU` is NOT globally unique in distributed cloud runs — VUs on different instances reuse the same ID  [community]
**What:** In Grafana Cloud k6 with geographic distribution, `__VU` resets per load-generator
instance. If you use `testUsers[__VU % testUsers.length]` to distribute test users across VUs,
multiple instances generate overlapping `__VU` values — VUs on different instances use the SAME
test user credentials, causing lock contention, false auth failures, and skewed results.
**WHY:** `K6_CLOUDRUN_INSTANCE_ID` identifies the load generator instance; `__VU` is local
to that instance. With 4 cloud instances running 25 VUs each, VU IDs are 1-25 on each instance
— they are NOT globally unique across the test.
**Fix:** Use `exec.scenario.iterationInTest` (globally unique across all instances) or combine
`K6_CLOUDRUN_INSTANCE_ID` with `__VU` for distributed-safe unique user assignment:
```javascript
import exec from "k6/execution";

// Globally unique across all distributed k6 instances
const globalVuId = exec.vu.idInTest;  // unique across all cloud instances

// OR use scenario.iterationInTest for per-iteration unique IDs
const userIdx = exec.scenario.iterationInTest % testUsers.length;
const user = testUsers[userIdx];
```

### 30. Unsafe response body access crashes checks silently  [community]
**What:** `check(res, { "has id": (r) => r.json("data.user.id") !== null })` throws when the
server is overloaded and returns an empty body, a plaintext error string, or a non-JSON
content type. The check registers as failed but the VU continues running — masking the real
problem (server crash / 502 gateway error).
**WHY:** k6's `r.json()` will throw if the body is not parseable JSON. Under load, servers
may return HTML error pages or empty bodies with 502/503 status codes. If the check callback
throws, k6 counts it as a failed check but the exception is swallowed — the VU doesn't abort.
**Fix:** Always guard body parsing with optional chaining or a try/catch:
```javascript
check(res, {
  "status 200":  (r) => r.status === 200,
  // Safe: only access json if status is 200 (and body exists)
  "has id":      (r) => r.status === 200 && r.json()?.data?.user?.id !== undefined,
});
// Or for complex assertions:
if (res.status === 200) {
  try {
    const body = res.json();
    check(body, { "has user id": (b) => b?.data?.user?.id !== undefined });
  } catch (e) {
    console.error(`Unexpected non-JSON response body [VU ${__VU}]:`, res.body?.substring(0, 200));
  }
}
```

### 31. `setup()` cannot access `exec` module — avoid `exec` calls there  [community]
**What:** `exec.scenario.iterationInTest`, `exec.vu.idInTest`, and other `exec` properties
return `undefined` or throw when called inside `setup()` or `teardown()`. These functions
run outside the VU execution context.
**WHY:** The `k6/execution` module provides data about the current VU and scenario — concepts
that don't exist during setup/teardown, which run once in a synthetic execution context.
**Fix:** Use `exec` APIs only inside `default()` or exported scenario functions. For setup
logic that needs unique IDs, use `Date.now()` or pass parameters from the script's module scope.

---

### 32. k6 v2.0 HTTP API server disabled by default — REST clients silently time out  [community]
**What:** k6 v1.x always started a REST API server on `localhost:6565` by default. In k6 v2.0, the server does **not** start unless you explicitly pass `--address localhost:6565` or set `K6_ADDRESS=localhost:6565`. Teams using `k6 pause`, `k6 resume`, or any tool that calls the k6 REST API (e.g., Gatling Enterprise integrations, custom CI dashboards) silently lose the endpoint after upgrading.
**WHY:** The v2.0 team disabled the default server because it consumed a socket even when never used, and the CLI commands that relied on it (`k6 pause`, `k6 resume`, `k6 scale`) were removed. Default-off reduces surface area for accidental exposure.
**Fix:** If you rely on the k6 REST API in CI:
```bash
# Explicit server enable (v2.0 required)
k6 run --address localhost:6565 k6/scripts/load.js

# Or: K6_ADDRESS env var (CI-friendly — no script change needed)
export K6_ADDRESS=localhost:6565
k6 run k6/scripts/load.js

# Audit CI pipelines that call the k6 REST API
grep -r "6565\|k6 pause\|k6 resume\|k6 scale\|k6 status" .github/ .gitlab-ci.yml Jenkinsfile
```

### 33. Cloud secrets auto-injected in v2.0 `--local-execution` — accidental production credential use  [community]
**What:** In k6 v2.0 final, cloud secrets are **automatically available** when running `k6 cloud run --local-execution`. If your Grafana Cloud k6 project stores production credentials and you run `--local-execution` against a staging environment, the production credentials are silently loaded without any explicit `--secret-source` flag.
**WHY:** The design intent is convenience — you don't need to reconfigure secret sources when switching between local and cloud execution. The risk is that teams with separate staging/production secrets in Grafana Cloud may inadvertently use the wrong set.
**Fix:** Use `--no-cloud-secrets` when running staging tests that should use only local/mock credentials:
```bash
# Staging — explicit mock secrets, no cloud injection
k6 cloud run --local-execution --no-cloud-secrets \
  --secret-source=mock=default,api_key="staging-key-1234" \
  k6/scripts/load.js

# Production — cloud secrets auto-injected (intended behavior)
k6 cloud run --local-execution k6/scripts/load.js
```

### 34. gRPC bidirectional streaming gotcha — `stream.end()` must precede VU closure  [community]
**What:** In bidirectional streaming tests, if the VU's `default()` function returns before `stream.end()` is called (e.g., due to an early `return` on a failed check), the gRPC stream is forcibly closed — the server sees an abrupt EOF, logs an error, and may increment its error counters. Under 50+ VUs this appears as a flood of unexpected server-side errors that are not reflected in k6's `http_req_failed` or `grpc_req_failed` metrics.
**WHY:** k6 closes the TCP connection when the VU iteration ends. If `stream.end()` was never called, the server never received the client's graceful half-close, and interprets it as a connection reset — not a clean stream termination.
**Fix:** Always `stream.end()` in a `try/finally` block so it fires even if the iteration exits early:
```javascript
export default function () {
  client.connect(TARGET, { plaintext: true });
  const stream = new grpc.Stream(client, "svc.Svc/BiDi");
  try {
    stream.write({ data: "hello" });
    // ... more writes ...
  } finally {
    stream.end();   // always signal graceful close
    client.close();
  }
}
```

### 35. `browser.newContext()` state NOT shared across VUs — each VU needs its own cookie injection  [community]
**What:** Teams who inject auth cookies into `browser.newContext()` in `setup()` expect VUs to share the authenticated context. They cannot — `setup()` returns a plain JSON-serializable object; the `BrowserContext` object itself is not serializable and cannot be passed to VUs.
**WHY:** k6's `setup()` return value is serialized to JSON and copied to each VU. Browser context state (cookies, localStorage, sessions) lives in Chromium's in-process memory — it cannot be serialized across VUs. Each VU runs its own Chromium subprocess.
**Fix:** In `setup()`, return only the raw cookie data (strings, not BrowserContext objects). In each VU's `default()`, create a new context and call `ctx.addCookies([cookieData])` before navigating:
```javascript
export function setup() {
  // Extract cookie values via HTTP — NOT via browser module
  const res = http.post(`${BASE}/api/auth/login`, ...);
  return { sessionCookie: res.cookies["session"]?.[0]?.value };
}

export default async function (data) {
  const ctx = await browser.newContext();
  try {
    // Re-inject per VU — this is correct; there is no other way
    await ctx.addCookies([{ name: "session", value: data.sessionCookie, domain: ... }]);
    const page = await ctx.newPage();
    await page.goto(APP_URL);
    // ...
  } finally {
    await ctx.close();
  }
}
```

### 36. Browser Locator API automatic retries in v2.0 — flaky selectors may now pass silently  [community]
**What:** k6 v2.0.0 adds automatic retry logic to all `newAction`-based Locator APIs (click, fill, check, etc.). In v1.x, a click on an element that wasn't immediately actionable would fail instantly. In v2.0, k6 retries the action for up to the default action timeout before failing. Teams migrating from v1.x may notice that previously-flaky tests now pass more consistently — but also that tests that were previously fast-failing on wrong selectors now take longer to fail because they wait through the retry window.
**WHY:** The retry logic mirrors Playwright's auto-waiting behavior: k6 waits for the element to be visible, stable, and actionable before dispatching the action. This eliminates a class of race conditions where the test clicks an element milliseconds before it is actually ready. However, it also means tests with incorrect selectors fail more slowly — the retry window masks the immediate "element not found" signal that teams used as a quick feedback indicator.
**Fix:** If test runs are slowing down on incorrect selectors, reduce the action timeout:
```javascript
const ctx = await browser.newContext({ defaultActionTimeout: 5000 });  // 5s vs 30s default
// Or per-page:
page.setDefaultTimeout(5000);
```
Keep the default (30s) for production tests where servers may have legitimate rendering delays.

### 37. `http.get()` extra-argument warning in v2.0 silently ignored in v1.x — audit your scripts  [community]
**What:** k6 v2.0.0 adds a warning when `http.get()` or `http.head()` are called with extra positional arguments (e.g., a request body). In v1.x, these extra arguments were silently ignored. Teams who accidentally wrote `http.get(url, body, params)` (using the `http.post()` signature) were sending GET requests without any body or params — their tests ran but the extra arguments were discarded without warning.
**WHY:** `http.get()` and `http.head()` accept only `(url, params?)` — there is no request body in a GET or HEAD request. The extra-argument warning catches typos where the developer meant to use `http.post()` or `http.put()` but wrote `http.get()`. In production, such mistakes produced requests that silently dropped auth headers or custom tags specified in the third positional argument.
**Fix:** Run `k6 run --log-level=warn k6/scripts/load.js` after upgrading to v2.0 and audit any "extra arguments" warnings. For requests that need a body, switch to `http.post()`, `http.put()`, or `http.request()`. For params-only GET requests, ensure params are the SECOND argument:
```javascript
// ❌ v1.x silently ignored the third arg
http.get(url, body, { tags: { name: "profile" } });

// ✓ Correct v2.0 patterns:
http.get(url, { tags: { name: "profile" } });  // params as second arg
http.post(url, body, { tags: { name: "profile" } });  // if you need a body
```

### 38. Coordinated omission — closed-model executors hide latency degradation under stress  [community]
**What:** Using `ramping-vus` or `constant-vus` (closed models) to load test a system that
is degrading causes the test to *automatically reduce load* as responses slow down. A stressed
server taking 10 s per response means each VU issues only 6 req/min instead of 60. The test
reports 90% lower throughput but "acceptable" latency percentiles — the slow requests are
never sent, so latency looks fine. You conclude the system handles load when it actually does not.
**WHY:** In a closed model, the next VU iteration starts only after the previous one finishes.
When the SUT is slow, VUs spend most of their time waiting for responses — they cannot issue
new requests. The arrival rate self-limits to match SUT capacity. Gil Tene coined this
"coordinated omission": the load generator unknowingly omits the load precisely when the system
is under the most stress, producing misleading results.
**Fix:** Switch to `constant-arrival-rate` or `ramping-arrival-rate` for stress and breakpoint
tests. These are *open models*: new iterations start on a fixed schedule regardless of how long
prior iterations take. The SUT faces constant pressure even when slow — which is how real users behave.
```javascript
// ❌ Closed model — load drops when SUT is slow (coordinated omission)
export const options = {
  scenarios: { stress: { executor: "constant-vus", vus: 50, duration: "5m" } },
};

// ✓ Open model — maintains constant RPS regardless of SUT response time
export const options = {
  scenarios: {
    stress: {
      executor: "constant-arrival-rate",
      rate: 50,           // 50 iterations/s — fixed regardless of response time
      timeUnit: "1s",
      duration: "5m",
      preAllocatedVUs: 100,  // pool must be large enough to absorb slow responses
      maxVUs: 300,           // ceiling for when SUT degrades badly
    },
  },
  thresholds: {
    // Under coordinated omission these thresholds may PASS; under open model they FAIL correctly
    "http_req_duration": ["p(95)<500"],
    "dropped_iterations": ["count<10"],  // alert if VU pool is exhausted
  },
};
```
> **When to use closed models:** Use `constant-vus` / `ramping-vus` to simulate a fixed number
> of concurrent users who will wait for a response (e.g., browser sessions with a think time).
> Use arrival-rate executors to simulate a fixed request rate from an independent source (e.g.,
> an API gateway, payment processor, or IoT fleet) that does not slow down when your SUT does.

---

## Lesser-Known Options

These `options` fields are valid in any k6 script but rarely appear in tutorials. Use them to solve specific production problems.

```javascript
export const options = {
  // Lifecycle function timeouts (default: "60s" each; Cloud max: 10m)
  setupTimeout:    "2m",    // give setup() more time if it seeds a database
  teardownTimeout: "1m",    // give teardown() time to clean up resources

  // Minimum iteration duration — VUs sleep if they finish faster than this.
  // Prevents arrival-rate executors from firing faster than intended under
  // very-fast endpoints; also prevents "sleep()" math errors.
  minIterationDuration: "1s",

  // Cookie behavior per VU
  noCookiesReset: false,   // true = cookies persist across iterations (session replay)

  // Connection reuse settings
  noVUConnectionReuse: false, // true = VU opens a new TCP connection each iteration
  noConnectionReuse:   false, // true = close TCP connection after every request

  // HTTP debug logging — WARNING: do NOT use in production load tests
  // "full" logs request + response headers and bodies; "" disables
  httpDebug: "",  // set to "full" for debugging auth issues locally

  // DNS override — like /etc/hosts in a script
  // Useful for routing requests to a staging host without changing the URL
  hosts: {
    "api.example.com":  "192.168.1.100",     // specific host
    "*.cdn.example.com": "192.168.1.200",    // wildcard subdomain (k6 v0.46+)
  },

  // TLS — skip certificate verification (self-signed certs on staging)
  insecureSkipTLSVerify: false,  // NEVER set true in production tests

  // Client certificate auth (mTLS) — pass cert+key per domain
  tlsAuth: [
    {
      domains: ["api.internal.example.com"],
      cert: open("./certs/client.pem"),
      key:  open("./certs/client-key.pem"),
    },
  ],

  // System tags — remove tags you don't need to reduce metric cardinality
  // Default: proto, subproto, status, method, url, name, group, check,
  //          error, error_code, tls_version, scenario, service, expected_response
  systemTags: ["status", "method", "url", "scenario", "check", "error"],

  // DNS resolver tuning — useful for load-balanced backends with multiple A records
  dns: {
    ttl:    "5m",         // default: "5m" — cache DNS results; set "0s" for no caching
    select: "roundRobin", // default: "random" | "first" | "roundRobin" — pick from multi-A
    policy: "preferIPv4", // default: "preferIPv4" | "preferIPv6" | "onlyIPv4" | "onlyIPv6" | "any"
  },

  // Override User-Agent globally — useful when target has bot detection
  userAgent: "k6-loadtest/1.0 (performance testing)",

  // Per-host concurrency limit for http.batch() — prevents hammering a single origin
  batchPerHost: 6,  // simulates browser's per-host connection limit (default: 6)

  // Enforce minimum TLS version — for compliance testing (PCI DSS requires TLS 1.2+)
  tlsVersion: { min: "tls1.2", max: "tls1.3" },
};
```

> **[community]:** `minIterationDuration` is the cleanest solution when you want `constant-vus`
> to behave more like `constant-arrival-rate` for fast endpoints. Instead of adding `sleep()`
> math, set `minIterationDuration` to the desired inter-iteration gap — k6 handles the sleep
> automatically and adjusts when iterations take longer than the minimum.

### GraphQL API Load Testing  [community]

GraphQL APIs receive all requests on a single endpoint. The k6 pattern differs from REST:
you must parse the `errors` array in **200 responses** (GraphQL never returns 4xx for query
errors), and use `tags.name` with the **operation name** (not URL) to prevent cardinality
explosions.

```javascript
// k6/scripts/graphql-load.js
import http from "k6/http";
import { check, sleep } from "k6";
import { Rate } from "k6/metrics";

const graphqlErrors = new Rate("graphql_errors");

export const options = {
  scenarios: {
    graphql_load: {
      executor: "ramping-vus",
      stages: [
        { duration: "30s", target: 20 },
        { duration: "2m",  target: 20 },
        { duration: "15s", target: 0  },
      ],
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<300"],
    http_req_failed:   ["rate<0.01"],
    // GraphQL errors come back as 200 with errors[] array — threshold on custom metric
    "graphql_errors":  ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:4000";
const GQL_ENDPOINT = `${BASE}/graphql`;

// Helper: send a GraphQL operation
function gql(query, variables = {}, operationName = "") {
  const res = http.post(
    GQL_ENDPOINT,
    JSON.stringify({ query, variables, operationName }),
    {
      headers: { "Content-Type": "application/json" },
      tags: {
        // Tag with operation name — prevents cardinality explosion from parameterized IDs
        name: operationName || "graphql",
      },
    }
  );
  return res;
}

const LIST_ITEMS_QUERY = `
  query ListItems($first: Int!) {
    items(first: $first) {
      edges {
        node { id name status }
      }
    }
  }
`;

const CREATE_ITEM_MUTATION = `
  mutation CreateItem($input: CreateItemInput!) {
    createItem(input: $input) {
      item { id name }
      errors { field message }
    }
  }
`;

export default function () {
  // Query
  const listRes = gql(LIST_ITEMS_QUERY, { first: 10 }, "ListItems");

  check(listRes, {
    "list: status 200": (r) => r.status === 200,
    "list: no errors":  (r) => {
      const body = r.json();
      const hasErrors = body.errors && body.errors.length > 0;
      graphqlErrors.add(hasErrors ? 1 : 0);
      return !hasErrors;
    },
    "list: has data":   (r) => r.json("data.items.edges") !== null,
  });

  sleep(0.5);

  // Mutation
  const createRes = gql(
    CREATE_ITEM_MUTATION,
    { input: { name: `item-${__ITER}`, type: "test" } },
    "CreateItem"
  );

  check(createRes, {
    "create: status 200": (r) => r.status === 200,
    "create: no errors":  (r) => {
      const body = r.json();
      const hasErrors = body.errors && body.errors.length > 0;
      graphqlErrors.add(hasErrors ? 1 : 0);
      return !hasErrors;
    },
    "create: has item id": (r) => r.json("data.createItem.item.id") !== null,
  });

  sleep(1);
}
```

> **[community]:** GraphQL always returns HTTP 200 even for auth failures, validation errors,
> and resolver crashes. A `check()` on `r.status === 200` will pass for 100% of requests —
> even completely broken queries. Always check `body.errors` separately and track it with
> a custom `Rate` metric to catch query-level failures.

### JWT Token Refresh in Long-Running Tests  [community]

Soak tests and nightly runs lasting 8+ hours outlive access tokens. Without refresh logic,
the test silently accumulates 401 errors in the second hour while the dashboard shows
healthy p(95) latency.

```javascript
// k6/lib/auth.js — reusable token manager with refresh
import http from "k6/http";

const BASE = __ENV.API_URL || "http://localhost:3001";
// Token expiry margin — refresh 5 minutes before actual expiry
const TOKEN_MARGIN_SEC = 300;

export function createTokenManager() {
  let token     = null;
  let expiresAt = 0;  // Unix timestamp in seconds

  function login() {
    const res = http.post(
      `${BASE}/api/auth/login`,
      JSON.stringify({
        email:    __ENV.E2E_USER_EMAIL    || "test@example.com",
        password: __ENV.E2E_USER_PASSWORD || "password123",
      }),
      { headers: { "Content-Type": "application/json" } }
    );

    if (res.status !== 200) {
      throw new Error(`auth failed: ${res.status} ${res.body}`);
    }

    token     = res.json("access_token");
    const exp = res.json("expires_in") || 3600;
    expiresAt = Math.floor(Date.now() / 1000) + exp - TOKEN_MARGIN_SEC;
  }

  return {
    getToken() {
      // Refresh proactively before expiry
      if (!token || Math.floor(Date.now() / 1000) >= expiresAt) {
        login();
      }
      return token;
    },
  };
}

// k6/scripts/soak-authed.js — usage
import http from "k6/http";
import { check, sleep } from "k6";
import { createTokenManager } from "../lib/auth.js";

// One token manager per VU — created during init context
const tokenManager = createTokenManager();

export const options = {
  scenarios: {
    soak: {
      executor: "ramping-vus",
      stages: [
        { duration: "5m", target: 20 },
        { duration: "8h", target: 20 },
        { duration: "5m", target: 0  },
      ],
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed:   ["rate<0.01"],
    checks:            ["rate>0.99"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  // Token automatically refreshed when near expiry — no manual tracking needed
  const token = tokenManager.getToken();

  const res = http.get(`${BASE}/api/resources`, {
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
  });

  check(res, {
    "status 200":       (r) => r.status === 200,
    "not 401 (expired token)": (r) => r.status !== 401,
  });

  sleep(2);
}
```

> **[community]:** Tokens obtained in `setup()` are serialized to JSON before being passed to
> VUs. After serialization, the `expiresAt` timestamp is baked in but the token itself cannot
> be refreshed via `setup()` — `setup()` runs once. For soak tests with expiring tokens,
> each VU must manage its own token refresh using a per-VU token manager (as above) or via
> a shared in-memory cache pattern.

### Distributed Tracing — HTTP Instrumentation  [community]

Correlate k6 load test requests with backend traces in Grafana Tempo, Jaeger, or any
OpenTelemetry-compatible tracing backend. The `http-instrumentation-tempo` jslib automatically
injects trace context headers (`Traceparent` for W3C, `Uber-Trace-Id` for Jaeger) into all
HTTP requests, enabling end-to-end trace correlation across microservices under load.

> **Migration note:** `k6/experimental/tracing` was removed in k6 v2.0. Use the
> `http-instrumentation-tempo` jslib instead — it's a drop-in replacement.

```javascript
// k6/scripts/traced-load.js
// Requires Grafana Tempo or any OTEL-compatible trace collector
import tempo from "https://jslib.k6.io/http-instrumentation-tempo/1.0.1/index.js";
import http from "k6/http";
import { check, sleep } from "k6";

// Initialize ONCE in init context — automatically injects trace headers into all requests
tempo.instrumentHTTP({
  propagator: "w3c",    // "w3c" (Traceparent) or "jaeger" (Uber-Trace-Id)
});

export const options = {
  scenarios: {
    traced: {
      executor: "constant-vus",
      vus: 10,
      duration: "2m",
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  // All requests automatically include W3C TraceContext headers:
  // Traceparent: 00-<trace_id>-<span_id>-01
  const itemsRes = http.get(
    `${BASE}/api/items`,
    {
      headers: { "X-Test-Iteration": String(__ITER) },
      tags: { name: "GET /api/items" },
    }
  );
  check(itemsRes, { "items 200": (r) => r.status === 200 });

  // POST also gets traced — trace IDs appear in Tempo linked to each k6 iteration
  const createRes = http.post(
    `${BASE}/api/items`,
    JSON.stringify({ name: `item-traced-${__ITER}` }),
    {
      headers: { "Content-Type": "application/json" },
      tags: { name: "POST /api/items" },
    }
  );
  check(createRes, { "create 201": (r) => r.status === 201 });

  sleep(1);
}
```

**Trace headers injected:**

| Propagator | Header injected | Trace ID format |
|-----------|-----------------|-----------------|
| `w3c` | `traceparent: 00-<32hex>-<16hex>-01` | W3C Trace Context v1 |
| `jaeger` | `Uber-Trace-Id: <trace>:<span>:<parent>:<flags>` | Jaeger B3 format |

> **[community]:** Trace IDs are not included in k6's default summary output — correlate
> them via the metrics output (InfluxDB/Prometheus tag `trace_id`) or by parsing the raw
> JSON output from `--out json=results/k6-raw.json`. In Grafana, link k6 dashboards to
> Tempo using the `trace_id` tag as a drill-down dimension.

### gRPC Streaming  [community]

k6's `k6/net/grpc` module supports server-side streaming in addition to unary calls.
Load `.proto` files once in init context — not inside `default()` — to avoid recreating
the client stub on every VU iteration.

```javascript
// k6/scripts/grpc-streaming.js
import grpc from "k6/net/grpc";
import { check, sleep } from "k6";

// INIT CONTEXT: load proto once per VU
const client = new grpc.Client();
client.load(["./proto"], "streaming.proto");

export const options = {
  scenarios: {
    grpc_stream: {
      executor: "constant-vus",
      vus: 10,
      duration: "2m",
    },
  },
  thresholds: {
    "grpc_req_duration": ["p(95)<500"],
    checks:               ["rate>0.99"],
  },
};

const TARGET = __ENV.GRPC_TARGET || "localhost:50051";

export default function () {
  client.connect(TARGET, { plaintext: true });

  // Server-side streaming: one request → multiple responses
  const stream = new grpc.Stream(
    client,
    "streaming.EventService/StreamEvents",
    null  // metadata — null for none
  );

  let eventCount = 0;

  stream.on("data", (event) => {
    check(event, {
      "event has type": (e) => e.type !== undefined,
      "event has id":   (e) => e.id !== undefined,
    });
    eventCount += 1;
  });

  stream.on("error", (err) => {
    console.error("gRPC stream error:", err.message);
  });

  stream.on("end", () => {
    check(eventCount, {
      "received events": (n) => n > 0,
    });
  });

  // Send the request to start the stream
  stream.write({ filter: "category:test" });
  stream.end();

  client.close();
  sleep(1);
}
```

> **[community]:** k6 v0.49.0+ supports all four gRPC streaming modes in the standard
> `k6/net/grpc` module: unary, server-side streaming, client-side streaming, and
> **bidirectional streaming**. The `k6/experimental/grpc` module no longer exists — do not
> reference it in new scripts. Always verify the streaming mode your proto defines
> (`rpc Foo(stream Bar) returns (stream Baz)`) before planning the load test.

### gRPC Authentication — Metadata Bearer Token  [community]

gRPC auth passes credentials via metadata (the gRPC equivalent of HTTP headers). The key pattern is passing a `metadata` object as the third argument to `client.invoke()`.

```javascript
// k6/scripts/grpc-authed.js — gRPC with Bearer token auth
import grpc from "k6/net/grpc";
import { check, sleep } from "k6";
import http from "k6/http";

const client = new grpc.Client();
client.load(["./proto"], "items.proto");

export const options = {
  scenarios: {
    grpc_authed: {
      executor: "constant-vus",
      vus: 20,
      duration: "2m",
    },
  },
  thresholds: {
    "grpc_req_duration": ["p(95)<300"],
    checks:               ["rate>0.99"],
  },
};

const BASE_HTTP = __ENV.API_URL    || "http://localhost:3001";
const GRPC_TARGET = __ENV.GRPC_TARGET || "localhost:50051";

export function setup() {
  // Get JWT token via HTTP REST auth
  const res = http.post(
    `${BASE_HTTP}/api/auth/token`,
    JSON.stringify({ client_id: __ENV.GRPC_CLIENT_ID, client_secret: __ENV.GRPC_CLIENT_SECRET }),
    { headers: { "Content-Type": "application/json" } }
  );
  check(res, { "token ok": (r) => r.status === 200 });
  return { token: res.json("access_token") };
}

export default function (data) {
  // Connect with TLS (plaintext: false = TLS enabled)
  client.connect(GRPC_TARGET, {
    plaintext: false,         // use TLS — set true for dev/internal plaintext
    timeout: "10s",           // connection timeout
    // tls_auth: { cert, key } for mTLS (mutual TLS)
  });

  // Pass Bearer token via metadata
  const metadata = {
    authorization: `Bearer ${data.token}`,
    "x-request-id": `k6-${__VU}-${__ITER}`,
  };

  const response = client.invoke(
    "items.ItemService/ListItems",
    { page: 1, pageSize: 10 },
    { metadata }
  );

  check(response, {
    "grpc status OK":  (r) => r && r.status === grpc.StatusOK,
    "has items":       (r) => r.message && Array.isArray(r.message.items),
  });

  client.close();
  sleep(0.2);
}
```

**gRPC connection reuse pattern** — open once per VU in init, close in teardown:

```javascript
// INIT CONTEXT — connection opened once per VU (more efficient for high-VU tests)
const client = new grpc.Client();
client.load(["./proto"], "items.proto");

// Setup runs once — connect here for persistent connection
export function setup() {
  // Cannot use client.connect() in setup() — it runs once, not per VU
  // Connect in default() function after client.load() in init
  return {};
}

export default function (data) {
  // Connect once per VU execution (lazy connect — only if not already connected)
  if (!client.connected) {
    client.connect(GRPC_TARGET, { plaintext: true });
  }
  const response = client.invoke("items.ItemService/GetItem", { id: __ITER });
  check(response, { "ok": (r) => r.status === grpc.StatusOK });
  // DO NOT call client.close() here — reuse the connection across iterations
  sleep(0.1);
}

export function teardown() {
  client.close();  // Close once when the VU lifecycle ends
}
```

> **[community]:** Opening and closing a gRPC connection per iteration (`connect()` + `invoke()` + `close()` in `default()`) adds ~5-15ms of TLS handshake overhead per request. For high-throughput gRPC tests, connect once per VU (in the first iteration check) and reuse. This matches how real gRPC clients operate (persistent multiplexed connections).

### gRPC Async Invoke  [community]

`client.asyncInvoke()` is the async version of `client.invoke()` — it returns a Promise
instead of blocking the VU. Use it when you want to fire multiple concurrent unary RPC
calls from a single VU iteration (fan-out pattern), or when your `default` function is
already `async` (e.g., mixing gRPC with `k6/experimental/fs`).

```javascript
// k6/scripts/grpc-async.js — concurrent gRPC calls per iteration
import grpc from "k6/net/grpc";
import { check } from "k6";

const client = new grpc.Client();
client.load(["./proto"], "items.proto", "users.proto");

export const options = {
  scenarios: {
    grpc_parallel: { executor: "constant-vus", vus: 10, duration: "2m" },
  },
};

const BASE = __ENV.GRPC_TARGET || "localhost:50051";

export async function setup() {
  client.connect(BASE, { plaintext: true });
}

export default async function () {
  // Fire both RPCs concurrently — no sequential wait between them
  const [itemResp, userResp] = await Promise.all([
    client.asyncInvoke("items.ItemService/GetItem",  { id: __ITER }),
    client.asyncInvoke("users.UserService/GetUser",  { id: __ITER % 100 }),
  ]);

  check(itemResp, { "item ok":  (r) => r.status === grpc.StatusOK });
  check(userResp, { "user ok":  (r) => r.status === grpc.StatusOK });
}

export function teardown() {
  client.close();
}
```

> **[community]:** `asyncInvoke()` requires your `default()` function to be `async`.
> In k6, a single VU runs one async context — concurrent `Promise.all()` calls are
> interleaved on the VU's event loop, not truly parallel. Use `constant-arrival-rate`
> to model concurrent requests from independent users; use `asyncInvoke` + `Promise.all`
> to model a single user making multiple simultaneous service calls (e.g., a dashboard
> loading data from 3 microservices in parallel).

### gRPC Client-Side Streaming  [community]

Client-side streaming — the client sends multiple messages, the server replies with
a single response. Classic pattern: collect a series of GPS waypoints and receive
a single `RouteSummary` back (the RouteGuide example from the gRPC docs).

```javascript
// k6/scripts/grpc-client-stream.js
import grpc from "k6/net/grpc";
import { check, sleep } from "k6";

const client = new grpc.Client();
client.load(["./proto"], "routing.proto");

export const options = {
  scenarios: {
    client_stream: { executor: "constant-vus", vus: 5, duration: "1m" },
  },
  thresholds: {
    "grpc_req_duration": ["p(95)<500"],
    checks:               ["rate>0.99"],
  },
};

const TARGET = __ENV.GRPC_TARGET || "localhost:50051";

// Sample waypoints to stream
const WAYPOINTS = [
  { latitude: 406109563, longitude: -742186778 },
  { latitude: 411733222, longitude: -744228360 },
  { latitude: 744_105_598, longitude: -743755555 },
];

export default function () {
  client.connect(TARGET, { plaintext: true });

  // Client-side streaming: client sends N messages, server responds once
  const stream = new grpc.Stream(client, "routing.RouteGuide/RecordRoute");

  // Collect summary from the single server response
  stream.on("data", (stats) => {
    check(stats, {
      "trip has points":  (s) => s.pointCount > 0,
      "trip has distance": (s) => s.distance >= 0,
    });
  });

  stream.on("error", (err) => {
    console.error("client-stream error:", JSON.stringify(err));
  });

  // Send multiple messages sequentially
  for (const wp of WAYPOINTS) {
    stream.write({ location: wp });
  }
  stream.end();  // signal end-of-stream → triggers server's aggregated response

  client.close();
  sleep(0.5);
}
```

> **[community]:** `stream.end()` is required for client-side and bidirectional streaming —
> it signals to the server that no more messages are coming, allowing it to produce its
> response. Omitting `stream.end()` causes the server to wait indefinitely and the VU to
> hang until the scenario timeout.

### gRPC Bidirectional Streaming  [community]

Bidirectional streaming — both client and server send multiple messages concurrently.
Supported in `k6/net/grpc` since k6 v0.49.0. Pattern: combine `stream.on('data', ...)` for
incoming messages and `stream.write(...)` for outgoing, then `stream.end()` when done sending.

```javascript
// k6/scripts/grpc-bidi-stream.js
import grpc from "k6/net/grpc";
import { check, sleep } from "k6";
import { Counter, Trend } from "k6/metrics";

const CLIENT_NOTES  = new Counter("bidi_client_notes_sent");
const SERVER_NOTES  = new Counter("bidi_server_notes_received");
const BIDI_LATENCY  = new Trend("bidi_round_trip_ms", true);

const client = new grpc.Client();
client.load(["./proto"], "routing.proto");

export const options = {
  scenarios: {
    bidi_stream: { executor: "constant-vus", vus: 5, duration: "1m" },
  },
  thresholds: {
    "bidi_server_notes_received": ["count>0"],
    checks:                        ["rate>0.99"],
  },
};

const TARGET = __ENV.GRPC_TARGET || "localhost:50051";

const ROUTE_POINTS = [
  { latitude: 406109563, longitude: -742186778 },
  { latitude: 411733222, longitude: -744228360 },
];

export default function () {
  client.connect(TARGET, { plaintext: true });

  // Bidirectional: client sends points, server replies with notes for each interesting location
  const stream = new grpc.Stream(client, "routing.RouteGuide/RouteChat");

  const sentAt = {};

  stream.on("data", (note) => {
    SERVER_NOTES.add(1);
    check(note, { "note has message": (n) => typeof n.message === "string" });
    // Round-trip latency if we tagged the outbound message
    const key = `${note.location?.latitude},${note.location?.longitude}`;
    if (sentAt[key]) BIDI_LATENCY.add(Date.now() - sentAt[key]);
  });

  stream.on("error", (err) => {
    console.error("bidi-stream error:", JSON.stringify(err));
  });

  stream.on("end", () => {
    check(SERVER_NOTES.name, { "received at least one note": () => true });
  });

  // Client and server are now both streaming concurrently
  for (const point of ROUTE_POINTS) {
    const key = `${point.latitude},${point.longitude}`;
    sentAt[key] = Date.now();
    stream.write({ location: point, message: `Passing through (${point.latitude})` });
    CLIENT_NOTES.add(1);
  }
  stream.end();  // no more messages from client; server will close its side when done

  client.close();
  sleep(0.5);
}
```

> **[community]:** In bidirectional streams, `stream.on('data')` and `stream.write()` run
> concurrently on the same event loop — the server may start sending responses before the
> client has finished writing. Do NOT assume responses arrive in the same order as writes;
> use a correlation ID in the message payload (as `key` above) to match requests and
> responses for latency measurement.

### gRPC Reflection — Dynamic Proto Loading  [community]

gRPC server reflection (RFC in grpc-proto) lets k6 discover service definitions at runtime
without `.proto` files. Pass `reflect: true` to `client.connect()`. The server must have
the reflection service enabled (standard in `grpc-go`, `grpc-java`, and most server frameworks).

```javascript
// k6/scripts/grpc-reflection.js — no .proto files needed
import grpc from "k6/net/grpc";
import { check, sleep } from "k6";

const client = new grpc.Client();
// NOTE: No client.load() call needed when using reflection

export const options = {
  scenarios: {
    reflected_load: { executor: "constant-vus", vus: 5, duration: "1m" },
  },
  thresholds: {
    "grpc_req_duration": ["p(95)<300"],
    checks:               ["rate>0.99"],
  },
};

const TARGET = __ENV.GRPC_TARGET || "localhost:50051";

export default function () {
  // reflect: true → k6 fetches service definitions from the server at connect time
  // plaintext: true → skip TLS (dev/staging only)
  client.connect(TARGET, {
    reflect: true,
    plaintext: true,
  });

  const response = client.invoke(
    "grpc.examples.echo.Echo/UnaryEcho",
    { message: `hello-${__ITER}` }
  );

  check(response, {
    "status OK":    (r) => r && r.status === grpc.StatusOK,
    "echo matches": (r) => r.message?.message?.startsWith("hello-"),
  });

  client.close();
  sleep(0.2);
}
```

> **[community]:** gRPC reflection requires the server to expose the reflection service —
> this is NOT always enabled in production services for security reasons (reflection leaks
> the full API surface). Always confirm reflection is available before writing scripts that
> depend on it. For production load tests, keep `.proto` files in version control so the
> test script can run without network access to the reflection endpoint during `client.load()`.

### gRPC Health Check Protocol  [community]

The gRPC Health Checking Protocol (`grpc.health.v1.Health/Check`) is a standard way to
probe service readiness before starting a load test. `Client.healthCheck([serviceName])`
implements this protocol — no `.proto` file needed for health checks (it is built in).

```javascript
// k6/scripts/grpc-health-preflight.js
// Use gRPC health check as a pre-flight gate before the actual load test
import grpc from "k6/net/grpc";
import { check } from "k6";
import exec from "k6/execution";

const client = new grpc.Client();
client.load(["./proto"], "items.proto");

export const options = {
  scenarios: {
    load: {
      executor: "ramping-vus",
      stages: [
        { duration: "30s", target: 20 },
        { duration: "2m",  target: 20 },
        { duration: "15s", target: 0  },
      ],
    },
  },
  thresholds: {
    "grpc_req_duration": ["p(95)<200"],
    checks:               ["rate>0.99"],
  },
};

const TARGET = __ENV.GRPC_TARGET || "localhost:50051";

export function setup() {
  // Pre-flight: verify the service is healthy before launching VUs
  client.connect(TARGET, { plaintext: true });

  // healthCheck() with service name → checks that specific service's health
  // healthCheck() with no arg      → checks overall server health
  const overall  = client.healthCheck();
  const specific = client.healthCheck("items.ItemService");

  check(overall,  { "server healthy":        (h) => h.status === grpc.HealthCheckServing });
  check(specific, { "ItemService healthy":   (h) => h.status === grpc.HealthCheckServing });

  if (overall.status !== grpc.HealthCheckServing) {
    // Abort immediately — no point running load against a sick server
    exec.test.abort("gRPC server not healthy at test start: " + overall.status);
  }

  client.close();
  return {};
}

export default function () {
  client.connect(TARGET, { plaintext: true });

  const res = client.invoke("items.ItemService/ListItems", { page: 1, pageSize: 10 });
  check(res, { "list ok": (r) => r.status === grpc.StatusOK });

  client.close();
}
```

**Health status values:**

| Constant | Meaning |
|----------|---------|
| `grpc.HealthCheckServing` | Service is healthy and accepting requests |
| `grpc.HealthCheckNotServing` | Service is degraded or refusing requests |
| `grpc.HealthCheckUnknown` | Service health is indeterminate |
| `grpc.HealthCheckServiceUnknown` | The named service does not exist |

> **[community]:** `Client.healthCheck()` does NOT require `client.load()` — the health
> check proto is built into k6. You CAN call it on a client that was connected with
> `reflect: true` (no `.proto` files) as long as the server has the health service registered.
> A common CI pattern: use `healthCheck()` in `setup()` as an early abort gate — if the
> health check fails, abort before allocating hundreds of VUs for a doomed test run.

### gRPC Message Size Limits  [community]

By default, gRPC sets a 4 MB receive size limit. For services that return large payloads
(bulk exports, binary data, large protos), configure `maxReceiveSize` on `client.connect()`.

```javascript
client.connect(TARGET, {
  plaintext: true,
  // Override gRPC default 4 MB receive limit — needed for large payload services
  maxReceiveSize: 32 * 1024 * 1024,  // 32 MB
  // Override send limit as well for large request payloads
  maxSendSize: 8 * 1024 * 1024,      // 8 MB
});
```

> **[community]:** The default gRPC `maxReceiveSize` (4 MB) is a frequent source of
> confusing errors: k6 reports `grpc_req_failed` or a stream error, but the root cause
> is a message that exceeds the size cap — not a server error. Check `error_code` and
> the error message for "grpc: received message larger than max" when debugging unexpected
> gRPC failures against bulk-data endpoints.

---

### Conditional Scenario Selection  [community]

Use `__ENV` to conditionally include scenarios so a single script serves as smoke, load,
and stress test. CI pipelines select the profile with a flag rather than maintaining
multiple scripts.

```javascript
// k6/scripts/universal.js — one script, three modes
import http from "k6/http";
import { check, sleep } from "k6";

const PROFILE = __ENV.PROFILE || "smoke";  // smoke | load | stress

const PROFILES = {
  smoke: {
    scenarios: {
      run: {
        executor: "shared-iterations",
        vus: 2,
        iterations: 10,
      },
    },
    thresholds: {
      http_req_duration: ["p(95)<1000"],
      http_req_failed:   ["rate<0.05"],
    },
  },
  load: {
    scenarios: {
      run: {
        executor: "ramping-vus",
        stages: [
          { duration: "1m",  target: 30 },
          { duration: "3m",  target: 30 },
          { duration: "30s", target: 0  },
        ],
      },
    },
    thresholds: {
      http_req_duration: ["p(95)<300"],
      http_req_failed:   ["rate<0.01"],
    },
  },
  stress: {
    scenarios: {
      run: {
        executor: "ramping-vus",
        stages: [
          { duration: "2m",  target: 100  },
          { duration: "5m",  target: 100  },
          { duration: "2m",  target: 200  },
          { duration: "5m",  target: 200  },
          { duration: "5m",  target: 0    },
        ],
      },
    },
    thresholds: {
      http_req_duration: ["p(95)<2000"],
      http_req_failed:   ["rate<0.05"],
    },
  },
};

// Merge the selected profile into options
export const options = PROFILES[PROFILE];

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  const res = http.get(`${BASE}/api/items`);
  check(res, { "status 200": (r) => r.status === 200 });
  sleep(1);
}
```

Run modes:
```bash
# Smoke test (fast, every PR)
k6 run -e PROFILE=smoke k6/scripts/universal.js

# Load test (nightly)
k6 run -e PROFILE=load -e API_URL=https://staging.api.example.com k6/scripts/universal.js

# Stress test (weekly / pre-release)
k6 run -e PROFILE=stress -e API_URL=https://staging.api.example.com k6/scripts/universal.js

# Run only a named scenario (k6 v0.43+)
k6 run --scenario run k6/scripts/universal.js

# Inspect script structure without executing
k6 inspect k6/scripts/universal.js

# Scaffold a new k6 script from a template (k6 v0.52+)
k6 new                                 # interactive prompts for type and name
k6 new --template browser browser-script.js  # browser module starter
k6 new --template protocol load.js          # HTTP/gRPC/WebSocket starter

# Analyze script dependencies — identifies required extensions and k6 version constraints
k6 deps k6/scripts/universal.js
# JSON output (for CI parsing)
k6 deps --json k6/scripts/universal.js > k6/results/deps.json
```

> **[community]:** `k6 inspect` outputs scenario configuration and VU count without running
> the test. Use it in CI to assert that a script has the expected structure before
> wasting a full test run on a malformed options object.

> **[community]:** `k6 deps` (k6 v1.6+) analyzes script imports and identifies which k6
> extensions are required. Use it in CI to validate that the k6 binary in your pipeline
> has all required extensions before running a potentially long test:
> ```bash
> # Fail CI early if extensions are missing
> k6 deps --json k6/scripts/load.js | jq '.customBuildRequired' | grep -q false \
>   || { echo "ERROR: Script requires custom k6 binary with extensions"; exit 1; }
> ```

> **[community]:** `K6_DEPENDENCY_MANIFEST` (k6 v1.6+) allows you to pin extension versions
> in a manifest file instead of the `xk6 build` command, preventing silent breakage when an
> extension releases a new version. Create a `k6-manifest.json` listing required extensions with
> exact versions:
> ```bash
> # Pin extensions via manifest rather than ad-hoc xk6 build flags
> export K6_DEPENDENCY_MANIFEST=./k6-manifest.json
> k6 run k6/scripts/load.js  # k6 reads manifest to resolve extension versions
> ```

> **[community]:** `k6 x docs` and `k6 x explore` (k6 v2.0+) are built-in discovery helpers
> surfaced in the main `k6 --help` output. `k6 x docs k6/browser` opens the browser module
> documentation and lists available device profiles, API methods, and options. `k6 x explore`
> lists all available extensions in the xk6 registry. Use these in onboarding scripts and
> team runbooks instead of linking to external URLs that may drift:
> ```bash
> # List all available k6 built-in and extension modules
> k6 x explore
>
> # Open browser module docs including available devices list
> k6 x docs k6/browser
>
> # Open secrets module docs
> k6 x docs k6/secrets
> ```

### Extensions (xk6)  [community]

k6 extensions add capabilities beyond HTTP — Redis shared state, Kafka producers, SQL
queries, Prometheus output, and more. Extensions require building a **custom k6 binary**.

```bash
# Install xk6 builder
go install go.k6.io/xk6/cmd/xk6@latest

# Build k6 with Redis extension
xk6 build --with github.com/grafana/xk6-redis

# Build with multiple extensions
xk6 build \
  --with github.com/grafana/xk6-redis \
  --with github.com/mostafa/xk6-kafka \
  --output ./k6-extended
```

Usage in script:
```javascript
// k6/scripts/redis-counter.js — shared counter across all VUs using Redis
// Requires: xk6 build --with github.com/grafana/xk6-redis
import { Client } from "k6/x/redis";
import http from "k6/http";
import { check } from "k6";

// Redis client (connection established on first command call — init context)
const redisClient = new Client({
  addr: __ENV.REDIS_ADDR || "localhost:6379",
});

export const options = {
  scenarios: {
    concurrent_users: {
      executor: "constant-vus",
      vus: 50,
      duration: "1m",
    },
  },
};

export async function setup() {
  // Reset shared counter before test starts
  await redisClient.set("total_orders", 0);
}

export default async function () {
  const res = http.post(
    `${__ENV.API_URL || "http://localhost:3001"}/api/orders`,
    JSON.stringify({ item: "sku-001" }),
    { headers: { "Content-Type": "application/json" } }
  );

  if (check(res, { "order created": (r) => r.status === 201 })) {
    // Atomic increment — safe across all VUs
    await redisClient.incr("total_orders");
  }
}

export async function teardown() {
  const totalOrders = await redisClient.get("total_orders");
  console.log(`Total orders created: ${totalOrders}`);
}
```

> **[community]:** xk6 extensions modify the k6 binary — your CI pipeline must build and
> cache the custom binary, not pull from the standard k6 release. Pin the extension version
> in the `xk6 build` command to prevent silent breakage on new releases. Use Docker to
> reproducibly build the extended binary:
> ```bash
> docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/xk6" grafana/xk6 \
>   build --with github.com/grafana/xk6-redis@v0.4.0
> ```

> **[community]:** For cross-VU shared mutable state (e.g., a shared counter, distributed
> lock, or globally unique ID generator), use the `xk6-kv` extension. Unlike `SharedArray`
> (read-only), `xk6-kv` provides a read-write key-value store backed by shared memory — safe
> for concurrent atomic operations across all VUs without an external Redis dependency:
> ```bash
> xk6 build --with github.com/szkiba/xk6-kv
> ```
> ```javascript
> import { open } from "k6/x/kv";
> const kv = open();
> export async function setup() { await kv.set("order_count", 0); }
> export default async function () {
>   await kv.set("order_count", (await kv.get("order_count") || 0) + 1);
> }
> ```
> Note: `xk6-kv` operations are async and add ~0.1ms overhead per call — avoid using them
> in tight inner loops at >10,000 RPS. Use Redis (via `k6/x/redis`) for production-scale
> distributed state.

> **[community]:** The `mcp-k6` MCP server (k6 v1.6+) enables AI-assisted script writing and
> validation through MCP-compatible editors (Claude, Cursor, VSCode with Copilot). It provides
> tools for generating scripts, validating syntax, and executing test runs from the editor.
> Useful for onboarding teams new to k6 or for generating boilerplate from natural-language
> descriptions. Configure in your editor's MCP settings pointing to the k6 binary's built-in
> MCP server: `k6 x mcp`.

---

### WebSocket Load Testing — Authenticated + Throughput  [community]

The stable `k6/websockets` module uses a browser-compatible event-loop model. Unlike the
legacy `k6/ws` API, the `default` function runs **once per VU** (not in a loop) — the
event loop drives execution until all listeners complete.

```javascript
// k6/scripts/ws-authed-throughput.js
import { WebSocket } from "k6/websockets";
import { check, sleep } from "k6";
import { Counter, Trend } from "k6/metrics";

const wsSent     = new Counter("ws_messages_sent");
const wsReceived = new Counter("ws_messages_received");
const wsLatency  = new Trend("ws_message_latency_ms", true);

export const options = {
  scenarios: {
    ws_load: {
      executor: "constant-vus",
      vus: 20,
      duration: "2m",
    },
  },
  thresholds: {
    "ws_message_latency_ms": ["p(95)<200"],
    "ws_messages_received":  ["count>0"],
    checks:                   ["rate>0.99"],
  },
};

const WS_URL = (__ENV.API_URL || "http://localhost:3001")
  .replace(/^http/, "ws")
  + "/ws/feed";

export default function () {
  // Pass auth header + tag in params
  const ws = new WebSocket(WS_URL, null, {
    headers: { Authorization: `Bearer ${__ENV.WS_TOKEN || "test-token"}` },
    tags: { name: "ws-feed" },
  });

  let sentAt = {};

  ws.onopen = () => {
    check(ws, { "connected": (s) => s.readyState === 1 });

    // Subscribe to a channel
    ws.send(JSON.stringify({ type: "subscribe", channel: "prices" }));
    wsSent.add(1);

    // Keep-alive ping every 30s
    const pingInterval = setInterval(() => {
      if (ws.readyState === 1) ws.ping();
    }, 30_000);

    // Close after 60s — prevent VU blocking forever
    setTimeout(() => {
      clearInterval(pingInterval);
      ws.close();
    }, 60_000);
  };

  ws.onmessage = (e) => {
    const msg = JSON.parse(e.data);

    if (msg.type === "ack") {
      wsReceived.add(1);
      sentAt[msg.id] = Date.now();
    }

    if (msg.type === "price" && sentAt[msg.requestId]) {
      wsLatency.add(Date.now() - sentAt[msg.requestId]);
      check(msg, {
        "has symbol": (m) => m.symbol !== undefined,
        "has price":  (m) => typeof m.price === "number",
      });
    }
  };

  ws.onerror = (e) => {
    // k6 sends "websocket: close sent" on clean close — filter it
    if (e.error() !== "websocket: close sent") {
      console.error(`WS error [VU ${__VU}]:`, e.error());
    }
  };

  ws.onpong = () => {
    // Pong received — connection still healthy
  };
}
```

### Async / Eventual Consistency Testing  [community]

Event-driven systems (message queues, async workers) require polling patterns to measure
true end-to-end latency. The key is measuring from publish to result available, not just
the API response time of the publish call.

```javascript
// k6/scripts/async-e2e.js
// Measures end-to-end latency: publish event → poll until result available
import http from "k6/http";
import { check, sleep } from "k6";
import { Trend, Rate } from "k6/metrics";

const e2eLatency = new Trend("async_e2e_latency_ms", true);
const completed  = new Rate("task_completed_rate");

export const options = {
  scenarios: {
    async_tasks: {
      executor: "constant-arrival-rate",
      rate: 5,          // 5 tasks/sec — keep low for async workflows
      timeUnit: "1s",
      duration: "2m",
      preAllocatedVUs: 20,
      maxVUs: 50,
    },
  },
  thresholds: {
    // E2E latency includes processing time — set realistic SLO
    "async_e2e_latency_ms": ["p(95)<5000"],    // 5s for 95% of tasks
    "task_completed_rate":  ["rate>0.99"],     // >99% tasks complete
    http_req_failed:         ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";
const POLL_INTERVAL = 0.5;   // seconds between polls
const POLL_TIMEOUT  = 30;    // seconds before giving up

export default function () {
  const startTime = Date.now();

  // 1. Publish the event / create the task
  const publishRes = http.post(
    `${BASE}/api/tasks`,
    JSON.stringify({ type: "image-process", data: `item-${__ITER}` }),
    { headers: { "Content-Type": "application/json" } }
  );

  check(publishRes, { "publish 202": (r) => r.status === 202 });
  const taskId = publishRes.json("id");
  if (!taskId) return;

  // 2. Poll until completed or timeout
  let done = false;
  while (!done && (Date.now() - startTime) / 1000 < POLL_TIMEOUT) {
    sleep(POLL_INTERVAL);

    const statusRes = http.get(
      `${BASE}/api/tasks/${taskId}`,
      { tags: { name: "GET /api/tasks/:id" } }
    );

    check(statusRes, { "poll 200": (r) => r.status === 200 });

    const status = statusRes.json("status");
    if (status === "completed" || status === "failed") {
      done = true;
      e2eLatency.add(Date.now() - startTime);
      completed.add(status === "completed" ? 1 : 0);
    }
  }

  if (!done) {
    // Timed out — log and count as incomplete
    completed.add(0);
    console.warn(`Task ${taskId} timed out after ${POLL_TIMEOUT}s`);
  }
}
```

> **[community]:** For async systems, `http_req_duration` measures only the publish call
> latency (typically <50ms). The true SLO is end-to-end time from publish to result
> available — always measure it with a custom `Trend` and polling loop. A system that
> processes all tasks in <50ms for the API call but takes 120s for the actual work looks
> "healthy" in k6 dashboards if you only monitor HTTP latency.

---

### Chaos Engineering with xk6-disruptor  [community]

`xk6-disruptor` combines load testing with controlled fault injection — essential for
validating circuit breakers, retry budgets, and error-rate SLOs under realistic failure
conditions. Requires a Kubernetes cluster and the disruptor extension binary.

```bash
# Build k6 with disruptor extension
xk6 build --with github.com/grafana/xk6-disruptor

# Verify the extension loaded
./k6 version  # should list xk6-disruptor in extensions
```

```javascript
// k6/scripts/chaos-load.js
// Combines sustained load + HTTP fault injection
import http from "k6/http";
import { check, sleep } from "k6";
import { ServiceDisruptor } from "k6/x/disruptor";
import { Rate } from "k6/metrics";

const errorRate = new Rate("error_rate");

export const options = {
  scenarios: {
    load: {
      executor: "constant-vus",
      vus: 20,
      duration: "3m",
      exec: "loadFlow",
      tags: { scenario: "load" },
    },
    inject_faults: {
      executor: "shared-iterations",
      vus: 1,
      iterations: 1,
      startTime: "30s",
      exec: "injectFaults",
      tags: { scenario: "chaos" },
    },
  },
  thresholds: {
    "error_rate": ["rate<0.20"],
    "http_req_duration{scenario:load}": ["p(95)<2000"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export function loadFlow() {
  const res = http.get(`${BASE}/api/items`);
  check(res, { "ok": (r) => r.status < 500 });
  errorRate.add(res.status >= 500 ? 1 : 0);
  sleep(0.5);
}

export function injectFaults() {
  const disruptor = new ServiceDisruptor(
    __ENV.SERVICE_NAME       || "items-service",
    __ENV.SERVICE_NAMESPACE  || "default"
  );
  disruptor.injectHTTPFaults(
    { averageDelay: "500ms", errorRate: 0.05, errorCode: 503 },
    "60s"
  );
}
```

> **[community]:** xk6-disruptor requires privileged Kubernetes access — it installs a
> sidecar proxy on target pods. Use `startTime` on the chaos scenario to establish a clean
> baseline before injecting faults; this separates pre-chaos from during-chaos metrics.

### Grafana Cloud k6 — Geographic Load Distribution  [community]

Grafana Cloud k6 supports running load from multiple geographic zones simultaneously.
Use `options.cloud.distribution` to split VUs across AWS/Azure regions for latency
profiling from different geographic origin points.

```javascript
// k6/scripts/geo-load.js — k6 Cloud geographic distribution
// NOTE: In k6 v2.0, use options.cloud (NOT options.ext.loadimpact which is removed)
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  // cloud block unifies name, projectID, and geographic distribution
  // k6 v2.0+: options.ext.loadimpact is removed — use options.cloud
  cloud: {
    name: "Global checkout flow",
    projectID: __ENV.K6_CLOUD_PROJECT_ID,
    // Distribution: percentages must sum to 100
    // Zones: amazon (AWS), azure (Azure), linode (Akamai)
    // Run: k6 cloud zones list   to see all available zones
    distribution: {
      "amazon:us:ashburn":  { loadZone: "amazon:us:ashburn",  percent: 34 },
      "amazon:gb:london":   { loadZone: "amazon:gb:london",   percent: 33 },
      "amazon:au:sydney":   { loadZone: "amazon:au:sydney",   percent: 33 },
    },
  },

  scenarios: {
    global_load: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "30s", target: 20 },
        { duration: "2m",  target: 20 },
        { duration: "15s", target: 0  },
      ],
      env: { ZONE: __ENV.ZONE || "us-east" },
    },
  },

  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  const res = http.get(`${BASE}/api/items`);
  check(res, { "items ok": (r) => r.status === 200 });
  sleep(1);
}
```

**Run from CLI:**
```bash
# Authenticate once (store credentials)
k6 cloud login --token "$K6_CLOUD_API_TOKEN" --stack "$K6_CLOUD_STACK"

# Run cloud test with distribution
k6 cloud run k6/scripts/geo-load.js

# Watch results in real time via Grafana Cloud UI or:
k6 cloud run --watch k6/scripts/geo-load.js
```

> **[community]:** Geographic distribution does NOT proportionally scale VU count per zone.
> If you configure 50% US + 50% EU with 100 VUs, each zone runs 50 VUs independently — total
> actual VU count is 100 (not 200). Latency results include zone-origin latency; always
> tag requests with `{ tags: { zone: __ENV.ZONE } }` to differentiate latency by origin.

### Distributed k6 with the k6 Operator (Kubernetes)  [community]

For extremely high load requirements (>100 k req/s) or when your application runs inside
a Kubernetes cluster, use the **k6 Operator** to distribute test execution across multiple
pods. Each pod runs an independent k6 instance; the Operator coordinates start timing via
a "starter" controller. Results aggregate into your configured output (Grafana Cloud,
Prometheus, InfluxDB).

**Install the k6 Operator:**
```bash
kubectl apply -f https://raw.githubusercontent.com/grafana/k6-operator/main/bundle.yaml
```

**Store your test script in a ConfigMap:**
```bash
# Single-file script
kubectl create configmap my-load-test --from-file k6/scripts/load.js

# Multi-file script + helpers (bundle as k6 archive first)
k6 archive k6/scripts/load.js -e API_URL=placeholder
kubectl create configmap my-load-test-archive --from-file archive.tar
```

**TestRun manifest:**
```yaml
# k6/k8s/testrun.yaml
apiVersion: k6.io/v1alpha1
kind: TestRun
metadata:
  name: load-test-run
spec:
  parallelism: 4        # 4 pods, each running 1/4 of the VU profile
  script:
    configMap:
      name: my-load-test
      file: load.js
  separate: false
  runner:
    image: grafana/k6:latest
    env:
      - name: API_URL
        valueFrom:
          secretKeyRef:
            name: k6-env-secrets
            key: API_URL
      - name: E2E_USER_EMAIL
        valueFrom:
          secretKeyRef:
            name: k6-env-secrets
            key: E2E_USER_EMAIL
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
      limits:
        cpu: 500m
        memory: 1Gi
  cleanup: "post"
```

**Run the test:**
```bash
kubectl apply -f k6/k8s/testrun.yaml

# Watch status
kubectl get testrun load-test-run -w

# Follow logs from all runner pods
kubectl logs -l app=k6 -f --prefix

# Clean up manually if cleanup: "post" is not set
kubectl delete -f k6/k8s/testrun.yaml
```

> **[community]:** With `parallelism: 4`, each pod receives `1/4` of the VU count defined in
> your script's `options`. A script with 400 VUs becomes 100 VUs per pod. k6 uses the
> `--execution-segment` flag automatically — you do NOT need to set it manually. Each pod
> evaluates thresholds independently; use a Grafana dashboard to aggregate results
> rather than relying on per-pod threshold pass/fail for the overall gate.

### Secrets Management with `k6/secrets`  [community]

The `k6/secrets` module (k6 v1.4+) provides secure secrets retrieval at runtime. Secrets
are automatically redacted as `***SECRET_REDACTED***` in all k6 logs — preventing accidental
credential leakage in CI output. Three source types are supported: `mock` (testing),
`file` (local), and `url` (HTTP endpoint).

```javascript
// k6/scripts/authed-with-secrets.js
// Requires k6 run --secret-source=mock=default,api_key="s3cr3t" script.js
import secrets from "k6/secrets";
import http from "k6/http";
import { check } from "k6";

export const options = {
  scenarios: {
    load: { executor: "constant-vus", vus: 10, duration: "1m" },
  },
  thresholds: {
    http_req_duration: ["p(95)<300"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default async function () {
  // Fetch secret at runtime — value is redacted in logs
  const apiKey = await secrets.get("api_key");

  const res = http.get(`${BASE}/api/data`, {
    headers: {
      "X-API-Key": apiKey,
      "Content-Type": "application/json",
    },
  });

  check(res, {
    "status 200":    (r) => r.status === 200,
    "not 401":       (r) => r.status !== 401,  // catches expired/revoked keys
  });
}
```

Multiple sources (for staging vs. production credentials):

```bash
# Mock source (local dev / CI testing)
k6 run --secret-source=mock=default,api_key="test-key-12345" script.js

# URL source (fetch from HashiCorp Vault, AWS Secrets Manager, etc.)
k6 run --secret-source=url=https://vault.internal/v1/secret/k6 script.js

# Named sources (use secrets.source("name").get("key") in script)
k6 run \
  --secret-source=mock=primary,api_key="staging-key" \
  --secret-source=url=https://vault.internal=secondary \
  script.js
```

> **[community]:** Before `k6/secrets`, teams embedded credentials in `--env` flags or
> hardcoded them in scripts. Both methods leak values into k6's stdout and CI logs. With
> `k6/secrets`, the actual value is only visible inside VU code — never in logs, never in
> the summary output. Rotate secrets in the source without changing the script.

### MFA / TOTP Authentication  [community]

Load testing MFA-protected endpoints requires generating real TOTP codes per iteration.
Use the `totp` jslib with `k6/secrets` to generate codes from a stored shared secret.

```javascript
// k6/scripts/mfa-load.js
// Requires: k6 run --secret-source=mock=default,totp_seed="BASE32SEED" script.js
import secrets from "k6/secrets";
import http from "k6/http";
import { check, sleep } from "k6";
import { TOTP } from "https://jslib.k6.io/totp/1.0.0/index.js";

export const options = {
  scenarios: {
    mfa_load: {
      executor: "constant-vus",
      vus: 5,    // Keep low — MFA flows are expensive (multiple round trips)
      duration: "2m",
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<2000"],  // MFA flows are slower
    http_req_failed:   ["rate<0.01"],
    checks:            ["rate>0.99"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default async function () {
  // 1. Fetch TOTP seed from secrets (redacted in logs)
  const totpSeed = await secrets.get("totp_seed");
  const totp = new TOTP(totpSeed, 6);
  const code = await totp.gen();

  // 2. First factor: username + password
  const loginRes = http.post(
    `${BASE}/api/auth/login`,
    JSON.stringify({ email: __ENV.E2E_USER_EMAIL || "mfa@example.com", password: __ENV.E2E_USER_PASSWORD }),
    { headers: { "Content-Type": "application/json" } }
  );
  check(loginRes, { "login 200": (r) => r.status === 200 });
  const challengeToken = loginRes.json("challenge_token");

  // 3. Second factor: TOTP code
  const mfaRes = http.post(
    `${BASE}/api/auth/mfa`,
    JSON.stringify({ challenge_token: challengeToken, totp_code: code }),
    { headers: { "Content-Type": "application/json" } }
  );
  check(mfaRes, {
    "mfa 200":       (r) => r.status === 200,
    "has jwt":       (r) => r.json("access_token") !== undefined,
  });

  // 4. Proceed with authenticated request
  const profileRes = http.get(`${BASE}/api/profile`, {
    headers: { Authorization: `Bearer ${mfaRes.json("access_token")}` },
  });
  check(profileRes, { "profile 200": (r) => r.status === 200 });

  sleep(2);
}
```

> **[community]:** TOTP codes are time-based (30-second windows). At high VU counts, clock
> skew between the k6 runner and the authentication server causes intermittent MFA failures.
> Test against an NTP-synced server; add `totp.gen(undefined, 1)` (bias=1) to generate
> the code for the next window if within the last 5 seconds.

### Per-Scenario Environment Variables  [community]

Each scenario can define its own `env` block. This is the cleanest way to point multiple
scenarios at different service tiers in a single test run — no global `__ENV` collisions.

```javascript
// k6/scripts/multi-env.js
import http from "k6/http";
import { check } from "k6";

export const options = {
  scenarios: {
    // Read scenario hits the read replica
    reads: {
      executor: "constant-vus",
      vus: 20,
      duration: "2m",
      exec: "readScenario",
      env: { SERVICE_URL: "http://read.api.internal", TIER: "read" },
      tags: { tier: "read" },
    },
    // Write scenario hits the primary
    writes: {
      executor: "constant-arrival-rate",
      rate: 10,
      timeUnit: "1s",
      duration: "2m",
      preAllocatedVUs: 10,
      maxVUs: 30,
      exec: "writeScenario",
      env: { SERVICE_URL: "http://write.api.internal", TIER: "write" },
      tags: { tier: "write" },
      startTime: "10s",
    },
  },
  thresholds: {
    "http_req_duration{tier:read}":  ["p(95)<150"],
    "http_req_duration{tier:write}": ["p(95)<400"],
  },
};

export function readScenario() {
  // Reads its own scenario-scoped SERVICE_URL — no global ENV needed
  const res = http.get(`${__ENV.SERVICE_URL}/api/items`);
  check(res, { "read ok": (r) => r.status === 200 });
}

export function writeScenario() {
  const res = http.post(
    `${__ENV.SERVICE_URL}/api/items`,
    JSON.stringify({ name: `item-${__ITER}` }),
    { headers: { "Content-Type": "application/json" } }
  );
  check(res, { "write 201": (r) => r.status === 201 });
}
```

---

## Browser Module — Advanced Patterns

### Locator Selector Priority

k6 browser's `getBy*` locators (available since k6 v0.54+) match the Playwright API.
Use them in priority order — more semantic = more resilient to DOM changes:

| Priority | Locator | Best for |
|----------|---------|---------|
| 1 | `page.getByRole('button', { name: 'Submit' })` | Interactive elements with ARIA roles |
| 2 | `page.getByLabel('Email address')` | Form inputs with associated labels |
| 3 | `page.getByPlaceholder('Search...')` | Inputs with placeholder text |
| 4 | `page.getByText('Delete account')` | Links, buttons, text elements |
| 5 | `page.getByAltText('Company Logo')` | Images with alt text |
| 6 | `page.getByTestId('user-profile-card')` | Elements with `data-testid` attribute |
| 7 | `page.locator('[data-cy="submit"]')` | Custom data attributes |
| 8 | `page.locator('.css-class')` | CSS selectors — fragile, last resort |
| 9 | `page.locator('//xpath')` | XPath — most fragile, avoid |

**Strict mode:** All `getBy*` and `locator()` methods throw if more than one element matches.
For multi-element assertions, use `.all()` or scope with a parent locator.

```javascript
// k6/scripts/browser-locators.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    ui: { executor: "shared-iterations", vus: 1, iterations: 1,
          options: { browser: { type: "chromium" } } },
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/login`);

    // Semantic locators — resilient to DOM refactors
    await page.getByLabel("Email address").fill("test@example.com");
    await page.getByLabel("Password").fill(__ENV.E2E_USER_PASSWORD || "password");
    await page.getByRole("button", { name: "Sign in" }).click();

    // Wait for navigation then assert with role
    await page.waitForLoadState("networkidle");
    const welcome = page.getByRole("heading", { level: 1 });
    check(await welcome.textContent(), { "logged in": (t) => t && t.length > 0 });

    // Scope a locator inside a region for precision
    const navRegion = page.getByRole("navigation");
    const homeLink  = navRegion.getByRole("link", { name: "Home" });
    await homeLink.click();
  } finally {
    await page.close();
  }
}
```

### CPU and Network Throttling for Realistic Conditions  [community]

The browser module's `throttleCPU()` and `throttleNetwork()` simulate constrained devices —
essential for testing mobile users or slow-network scenarios. These are underused because
teams focus on backend RPS, not frontend rendering performance.

```javascript
// k6/scripts/browser-mobile.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    mobile_slownet: {
      executor: "shared-iterations",
      vus: 2,
      iterations: 5,
      options: { browser: { type: "chromium" } },
    },
  },
  thresholds: {
    // LCP budget for mobile users on slow 3G
    "browser_web_vital_lcp": ["p(75)<4000"],
    "browser_web_vital_inp": ["p(75)<300"],   // INP (replaces FID removed in k6 v2.0)
    checks:                   ["rate==1.0"],
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    // Simulate 4x CPU slowdown (mid-range Android device)
    await page.throttleCPU({ rate: 4 });

    // Simulate Slow 3G network conditions
    await page.throttleNetwork({
      latency:       400,      // ms round-trip
      downloadThroughput: 500 * 1024 / 8,  // 500 kbps
      uploadThroughput:   200 * 1024 / 8,   // 200 kbps
    });

    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/`);

    // Wait for meaningful paint — not just document load
    await page.waitForLoadState("networkidle");

    const heading = page.getByRole("heading", { level: 1 });
    await heading.waitFor({ state: "visible" });

    check(await heading.textContent(), {
      "heading visible": (h) => h && h.length > 0,
    });
  } finally {
    await page.close();
  }
}
```

### Mixed HTTP + Browser Scenario  [community]

Run protocol-level (HTTP) and browser scenarios in the same k6 test. API VUs handle
backend load; browser VUs validate UI correctness under that load. Keep browser VU
counts very low — each Chromium subprocess uses ~200-400 MB RAM.

```javascript
// k6/scripts/mixed-protocol-browser.js
import http from "k6/http";
import { browser } from "k6/browser";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    // HTTP scenario — high throughput API load
    api_load: {
      executor: "constant-arrival-rate",
      rate: 50,
      timeUnit: "1s",
      duration: "2m",
      preAllocatedVUs: 30,
      maxVUs: 100,
      exec: "apiFlow",
      tags: { type: "http" },
    },
    // Browser scenario — low VU count, validates UI under load
    ui_check: {
      executor: "constant-vus",
      vus: 2,          // KEEP LOW — each browser VU = one Chromium process
      duration: "2m",
      exec: "uiFlow",
      tags: { type: "browser" },
      options: { browser: { type: "chromium" } },
    },
  },
  thresholds: {
    // HTTP SLOs
    "http_req_duration{type:http}": ["p(95)<200"],
    "http_req_failed{type:http}":   ["rate<0.01"],
    // Browser Web Vitals
    "browser_web_vital_lcp":        ["p(75)<3000"],
    checks:                          ["rate>0.99"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export function apiFlow() {
  const res = http.get(`${BASE}/api/items`);
  check(res, { "items 200": (r) => r.status === 200 });
  sleep(0.2);
}

export async function uiFlow() {
  const page = await browser.newPage();
  try {
    await page.goto(`${BASE}/`);
    await page.waitForLoadState("networkidle");
    const title = page.getByRole("heading", { level: 1 });
    await title.waitFor({ state: "visible" });
    check(await title.textContent(), { "title visible": (t) => t?.length > 0 });
    await page.screenshot({ path: `results/ui-${__ITER}.png` });
  } finally {
    await page.close();
  }
}
```

> **Critical [community]:** Never define both HTTP and browser VUs inside the same `exec`
> function. k6 enforces that browser context can only be used from the `exec` function
> designated in a browser scenario. Mixing them in one function causes a `context deadline
> exceeded` error. Always use separate `exec` functions.

### Browser Module Environment Variables

Control Chromium behavior without modifying scripts:

| Variable | Default | Purpose |
|----------|---------|---------|
| `K6_BROWSER_HEADLESS` | `true` | Show browser UI (`false`) for debugging — always `true` in CI |
| `K6_BROWSER_ARGS` | — | Extra Chromium command-line flags, e.g., `"--disable-gpu --no-sandbox"` |
| `K6_BROWSER_EXECUTABLE_PATH` | auto | Absolute path to a custom Chromium/Chrome binary |
| `K6_BROWSER_TIMEOUT` | `30s` | Timeout for connecting to the Chromium DevTools endpoint |
| `K6_BROWSER_DEBUG` | `false` | Log all CDP messages — very verbose, use for debugging only |
| `K6_BROWSER_IGNORE_DEFAULT_ARGS` | `false` | Remove k6's default launch args (rarely needed) |
| `K6_BROWSER_TRACES_METADATA` | — | Key=value pairs added to all browser trace spans |

```bash
# Run with visible browser (local debugging) — never use in CI
K6_BROWSER_HEADLESS=false k6 run k6/scripts/browser-smoke.js

# Docker: disable GPU + no sandbox required for containerized Chromium
K6_BROWSER_ARGS="--disable-gpu --no-sandbox --disable-dev-shm-usage" \
  k6 run k6/scripts/browser-smoke.js

# Use custom Chrome path (e.g., when testing against a specific Chrome version)
K6_BROWSER_EXECUTABLE_PATH="/usr/bin/google-chrome-stable" \
  k6 run k6/scripts/browser-smoke.js
```

> **[community]:** In Docker containers, always add `K6_BROWSER_ARGS="--no-sandbox --disable-dev-shm-usage"`. The `--no-sandbox` flag is required because Chromium's sandbox needs Linux namespaces which are often disabled in Docker. The `--disable-dev-shm-usage` flag prevents Chromium from crashing when `/dev/shm` is too small — an issue in containers with default 64 MB shared memory.

### BrowserContext — Auth State Sharing Across Pages  [community]

k6's browser module has no `storageState` equivalent (unlike Playwright's `storageState` file).
Instead, use `browser.newContext()` with pre-injected cookies from a single login flow —
the context shares cookies across all pages created within it.

**Pattern:** login once in `setup()` via HTTP (fast), extract the session cookie, inject it
into a `BrowserContext` via `addCookies()` — then every page created from that context is
already authenticated. This avoids repeated Chromium login flows per VU iteration.

```javascript
// k6/scripts/browser-reuse-auth.js
import http from "k6/http";
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    authed_ui: {
      executor: "shared-iterations",
      vus: 2,
      iterations: 6,
      options: { browser: { type: "chromium" } },
    },
  },
  thresholds: {
    "browser_web_vital_lcp": ["p(75)<3000"],
    checks:                   ["rate>0.99"],
  },
};

const BASE    = __ENV.API_URL  || "http://localhost:3001";
const APP_URL = __ENV.APP_URL  || "http://localhost:3001";

// ---- setup: fast HTTP login, return the session cookie ----
export function setup() {
  const res = http.post(
    `${BASE}/api/auth/login`,
    JSON.stringify({
      email:    __ENV.E2E_USER_EMAIL    || "test@example.com",
      password: __ENV.E2E_USER_PASSWORD || "password123",
    }),
    { headers: { "Content-Type": "application/json" } }
  );
  check(res, { "login ok": (r) => r.status === 200 });

  // Extract the session cookie set by the server on the login response
  const cookies = res.cookies;
  // Cookies are keyed by name; grab the session cookie value
  const sessionCookie = cookies["session"]?.[0] || cookies["sid"]?.[0];

  return {
    cookie: {
      name:    sessionCookie ? "session" : "connect.sid",
      value:   sessionCookie?.value || res.json("token") || "",
      domain:  new URL(APP_URL).hostname,
      path:    "/",
      secure:  APP_URL.startsWith("https"),
      sameSite: "Lax",
    },
  };
}

export default async function (data) {
  // Create a fresh context per VU iteration, then pre-inject the auth cookie
  const ctx  = await browser.newContext();
  const page = await ctx.newPage();

  try {
    // Inject auth cookie before navigating — page is already authenticated
    await ctx.addCookies([data.cookie]);

    await page.goto(`${APP_URL}/dashboard`);
    await page.waitForLoadState("networkidle");

    // Should land on the dashboard without redirecting to login
    check(page.url(), { "no redirect to login": (u) => !u.includes("/login") });

    const heading = page.getByRole("heading", { level: 1 });
    await heading.waitFor({ state: "visible" });
    check(await heading.textContent(), { "dashboard loaded": (t) => t?.length > 0 });

    await page.screenshot({ path: `results/dashboard-${__ITER}.png` });
  } finally {
    await page.close();
    await ctx.close();
  }
}
```

**`BrowserContext` API quick reference:**

| Method | Purpose |
|--------|---------|
| `browser.newContext([options])` | Create isolated context (separate cookies/cache/storage) |
| `browser.context()` | Return the current default context |
| `ctx.addCookies([...])` | Pre-inject cookies before any page navigation |
| `ctx.clearCookies()` | Wipe all cookies in the context |
| `ctx.cookies([urls])` | Read current cookies (for debugging or extraction) |
| `ctx.grantPermissions(['geolocation'])` | Grant browser permissions |
| `ctx.setGeolocation({ lat, lng })` | Simulate a geographic location |
| `ctx.setOffline(true)` | Simulate network offline |
| `ctx.addInitScript(fn)` | Inject JS that runs on every page load in this context |
| `ctx.setDefaultTimeout(ms)` | Override timeout for all locators in this context |
| `ctx.newPage()` | Open a new page within this context |
| `ctx.pages()` | List all open pages |
| `ctx.close()` | Close context and all its pages |

> **[community]:** k6 has no `storageState` file mechanism (Playwright's `context.storageState()` +
> `browser.newContext({ storageState: '...' })` flow). The alternative: use HTTP to obtain the session
> cookie in `setup()` and inject it via `ctx.addCookies()`. This is faster than a full browser login
> flow per VU and avoids race conditions when multiple VUs try to log in simultaneously at test start.

> **[community]:** Each `browser.newContext()` creates an isolated browser context with separate
> cookies, localStorage, and sessionStorage — analogous to opening an Incognito window. If you want
> all pages in the test to share auth state (not per-iteration isolation), open the context ONCE
> in a module-level init or per-VU init and reuse it; do NOT create a new context per iteration.

---

## HTTP Timing Metrics — What They Measure

A critical point often missed: **`http_req_duration` does NOT include DNS lookup or TCP connection time**. Thresholding only on `http_req_duration` may miss user-perceived latency spikes caused by connection overhead.

| Metric | What it measures | Includes |
|--------|-----------------|---------|
| `http_req_blocked` | Time waiting for a free TCP connection slot | Before DNS resolution |
| `http_req_lookup` | DNS resolution time | DNS only |
| `http_req_connecting` | TCP handshake time | Network round-trip to establish connection |
| `http_req_tls_handshaking` | TLS negotiation time | Certificate validation + key exchange |
| `http_req_sending` | Time to send the request | Upload body transfer |
| `http_req_waiting` | Time to first byte (TTFB) | Server processing time |
| `http_req_receiving` | Response download time | Download body transfer |
| **`http_req_duration`** | **`sending + waiting + receiving`** | **Does NOT include DNS, TCP, or TLS** |

**User-perceived latency = `http_req_blocked + http_req_connecting + http_req_tls_handshaking + http_req_duration`**

```javascript
// k6/scripts/full-timing.js — measure complete user-perceived latency
import http from "k6/http";
import { check } from "k6";
import { Trend } from "k6/metrics";

// Capture complete perceived latency including connection overhead
const perceivedLatency = new Trend("perceived_latency_ms", true);

export const options = {
  scenarios: {
    timing_test: { executor: "constant-vus", vus: 10, duration: "2m" },
  },
  thresholds: {
    http_req_duration:   ["p(95)<300"],       // server processing SLO
    "perceived_latency_ms": ["p(95)<500"],    // user-perceived SLO (includes connection)
    http_req_failed:     ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  const res = http.get(`${BASE}/api/items`);

  // res.timings has all phases in milliseconds
  const t = res.timings;
  const totalPerceived = t.blocked + t.connecting + t.tls_handshaking + t.duration;
  perceivedLatency.add(totalPerceived);

  // Log if connection overhead is > 50% of total perceived time (network problem)
  if (t.connecting > totalPerceived * 0.5) {
    console.warn(`High connection overhead: ${t.connecting.toFixed(1)}ms of ${totalPerceived.toFixed(1)}ms total`);
  }

  check(res, { "status 200": (r) => r.status === 200 });
}
```

> **[community]:** In a warm test with HTTP keep-alive enabled (the k6 default), `http_req_connecting`
> is 0 for most requests — connections are reused. But on cold starts, first-VU iterations, or
> after connection resets, the TCP+TLS overhead adds 50-200ms that `http_req_duration` silently
> ignores. Always add a `perceived_latency` custom trend for accurate user-facing SLO validation.

---

## HTTP/2 Protocol Support

k6 supports HTTP/2 automatically — no configuration required. When the target server announces HTTP/2 support via ALPN (TLS extension), k6 upgrades the connection. HTTP/2 multiplexes multiple requests over a single TCP connection, reducing connection-setup overhead and improving throughput accuracy under high concurrency.

### How HTTP/2 Negotiation Works

| Step | What happens |
|------|-------------|
| 1. TLS handshake | k6 sends ALPN extension advertising `h2` and `http/1.1` |
| 2. Server selects | Server responds with `h2` if it supports HTTP/2; `http/1.1` otherwise |
| 3. Automatic upgrade | k6 silently upgrades — no script change needed |
| 4. Multiplexed streams | All requests within a VU share one TCP connection with independent streams |

**Key insight for load testing:** HTTP/2 multiplexing means a single VU can achieve significantly higher concurrency than HTTP/1.1, which serialises requests per connection. This changes your VU sizing — fewer VUs may be needed to achieve the same RPS, because each VU's requests no longer queue behind one another.

### Verifying HTTP/2 Negotiation  [community]

Always verify the actual protocol in use before interpreting results. A test you believe is measuring HTTP/2 performance may silently fall back to HTTP/1.1 if the server is misconfigured.

```javascript
// k6/scripts/http2-verify.js
import http from "k6/http";
import { check, sleep } from "k6";
import { Trend, Counter } from "k6/metrics";

const h2Requests  = new Counter("http2_requests");
const h1Requests  = new Counter("http1_requests");
const h2Latency   = new Trend("http2_latency_ms", true);

export const options = {
  scenarios: {
    protocol_check: {
      executor: "ramping-vus",
      stages: [
        { duration: "30s", target: 20 },
        { duration: "1m",  target: 20 },
        { duration: "15s", target: 0  },
      ],
    },
  },
  thresholds: {
    // Ensure at least 95% of requests use HTTP/2
    http2_requests: ["count>0"],
    http_req_duration: ["p(95)<500"],
    checks: ["rate>0.99"],
  },
};

const BASE = __ENV.API_URL || "https://localhost:3443";

export default function () {
  const res = http.get(`${BASE}/api/items`);

  // r.proto returns "HTTP/2.0" or "HTTP/1.1" — use this to confirm negotiation
  const isH2 = res.proto === "HTTP/2.0";

  check(res, {
    "status 200":   (r) => r.status === 200,
    "protocol H2":  (r) => r.proto === "HTTP/2.0",
  });

  if (isH2) {
    h2Requests.add(1);
    h2Latency.add(res.timings.duration);
  } else {
    h1Requests.add(1);
    console.warn(`VU ${__VU} falling back to ${res.proto} — check server TLS/ALPN config`);
  }

  sleep(1);
}
```

### HTTP/2 Multiplexing — Concurrent Batch Requests  [community]

HTTP/2 multiplexing allows multiple requests to fly in parallel over one connection without the per-request overhead of new TCP handshakes. Use `http.batch()` to exploit this in k6:

```javascript
// k6/scripts/h2-batch-load.js — exploit HTTP/2 multiplexing for realistic page-load simulation
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    h2_batch: {
      executor: "constant-arrival-rate",
      rate: 50,
      timeUnit: "1s",
      duration: "2m",
      preAllocatedVUs: 20,
      maxVUs: 100,
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<300"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "https://localhost:3443";

export default function () {
  // HTTP/2 multiplexes all 4 requests over one connection — no serial queuing
  // Under HTTP/1.1, browsers open 6 parallel connections; k6 can do the same per VU
  const responses = http.batch([
    ["GET", `${BASE}/api/items`,          null, { tags: { name: "items" } }],
    ["GET", `${BASE}/api/categories`,     null, { tags: { name: "categories" } }],
    ["GET", `${BASE}/api/user/profile`,   null, { tags: { name: "profile" } }],
    ["GET", `${BASE}/api/notifications`,  null, { tags: { name: "notifications" } }],
  ]);

  // Verify all responses and check protocol
  for (const [name, res] of Object.entries(responses)) {
    check(res, {
      [`${name} status 200`]: (r) => r.status === 200,
      [`${name} is H2`]:      (r) => r.proto === "HTTP/2.0",
    });
  }

  sleep(0.5);
}
```

### Real-World Gotchas — HTTP/2  [community]

**1. Multiplexing changes VU sizing math.**
Under HTTP/1.1, Little's Law (`VUs = RPS × response_time`) assumes one connection per VU. Under HTTP/2, a single VU can multiplex dozens of concurrent streams over one connection — so you need *fewer* VUs to achieve the same RPS. Teams that copy VU counts from HTTP/1.1 tests and run them against HTTP/2 backends risk generating 5–10× the intended load. WHY: the HTTP/2 VU spends no time waiting for connection establishment between requests; each request is a new stream on the existing connection.

**2. Silent HTTP/1.1 fallback masks performance regressions.**
k6 silently falls back to HTTP/1.1 when the server does not advertise HTTP/2. If your baseline was measured against HTTP/2 and the target later loses `h2` ALPN support (misconfigured LB, cert rotation issue), your new test will appear slower — but the root cause is the protocol downgrade, not a regression. Always assert `r.proto === "HTTP/2.0"` in smoke tests before load tests. WHY: without the assertion, you cannot distinguish "server is slower" from "server lost HTTP/2 support".

**3. TCP HOL blocking under packet loss negates HTTP/2 benefits.**
HTTP/2 multiplexes streams over a single TCP connection. Under high packet loss (> 1%), a single dropped TCP segment stalls ALL streams on that connection — this is TCP head-of-line (HOL) blocking. HTTP/3 (QUIC over UDP) solves this, but k6 does not currently support HTTP/3. WHY: production load tests on lossy networks or throttled connections may show HTTP/2 performing *worse* than HTTP/1.1 with 6 parallel connections (each with independent TCP HOL).

**4. `http_req_connecting` stays at 0 after the first request — expected behavior.**
Under both HTTP/1.1 keep-alive and HTTP/2, subsequent requests on the same connection show `http_req_connecting = 0`. This is correct — k6 reuses the connection. It is NOT a bug. Teams sometimes flag this as "the metrics are missing data". WHY: connection reuse is the normal behavior and means the server is behaving correctly.

**5. TLS termination at the load balancer hides HTTP/2 from k6.**
If your load balancer (Nginx, Envoy, AWS ALB) terminates TLS and proxies to the backend over HTTP/1.1, k6's `res.proto` will show `HTTP/2.0` for the LB→k6 leg but the backend never receives H2 traffic. This means you're testing the LB's HTTP/2 handling, not the backend's. WHY: relevant when you are measuring backend server performance and need to test without LB in the path, or when testing internal services directly.

### HTTP/2 Error Codes Quick Reference  [community]

See the `Network Error Codes & Diagnostics` section (1600–1699 range) for k6 H2 error codes:

| Code | Meaning | Common cause |
|------|---------|-------------|
| 1600 | Generic HTTP/2 error | Check server logs |
| 1610 | GOAWAY frame received | Server initiated graceful shutdown; scale-down event |
| 1630 | Stream-level error | Protocol violation or server reset of a specific stream |
| 1650 | Connection-level error | Fatal H2 connection failure; reconnect required |

> **[community]:** `error_code=1610` (GOAWAY) is the most common HTTP/2 error in k6 tests against Kubernetes services. It appears when a Pod is terminated during a rolling deployment — the server sends GOAWAY to close existing connections gracefully before the Pod shuts down. To detect this, filter for `error_code=1610` in `handleSummary` or a Grafana dashboard: a spike during a deployment is expected and healthy; a sustained 1610 rate indicates an LB health-check misconfiguration.

---

## Key APIs

| API | What it does | When to use |
|-----|-------------|-------------|
| `http.get(url, params)` | HTTP GET; returns Response | Read endpoints |
| `http.post(url, body, params)` | HTTP POST with body | Write / auth endpoints |
| `http.put(url, body, params)` | HTTP PUT — replace resource | Update endpoints |
| `http.patch(url, body, params)` | HTTP PATCH — partial update | Partial update endpoints |
| `http.del(url, body, params)` | HTTP DELETE | Delete endpoints |
| `http.head(url, params)` | HTTP HEAD — headers only | Cache/exist checks |
| `http.options(url, body, params)` | HTTP OPTIONS | CORS pre-flight testing |
| `http.batch([...])` | Parallel requests in one call | Simulating page-load asset fetches |
| `http.file(data, name, type)` | Wrap data as multipart file | File upload tests |
| `check(res, thunks)` | Record named boolean assertions | All responses — never skip |
| `check(val, thunks, tags)` | Assertions with extra tags attached to check metrics | Per-operation categorization of check results |
| `fail(message)` | Throw an error stopping the current iteration (not the test) | Guard clauses after critical checks; auth flows where partial execution is meaningless |
| `sleep(seconds)` | Pause VU to simulate think time | Between iterations |
| `group(name, fn)` | Aggregate metrics under a label | Multi-step user journeys |
| `new Trend(name, isTime)` | Custom timing metric | Per-operation latency |
| `new Rate(name)` | Custom pass/fail rate | Business-level error rates |
| `new Counter(name)` | Monotonically increasing count | Counting events |
| `new Gauge(name)` | Last/min/max snapshot value | Queue depth, active sessions |
| `__ENV.KEY` | Read environment variable | Base URLs, credentials |
| `__VU` | Current VU number (1-based) | Data distribution across VUs |
| `__ITER` | Current iteration number (0-based) | Unique IDs, named screenshots |
| `open(path)` | Load a local file (CSV/JSON) as string | Parameterized test data |
| `SharedArray` | Shared read-only array across VUs | Large test-data sets (avoids per-VU copy) |
| `options.scenarios` | Declare named executors | All non-trivial load profiles |
| `options.thresholds` | Pass/fail gates on metrics | Every production script |
| `options.tags` | Default tags added to all metrics | Environment / version labelling |
| `options.discardResponseBodies` | Skip storing response bodies | High-throughput tests (saves memory) |
| `options.minIterationDuration` | Enforce minimum iteration time (VU sleeps if faster) | Prevents VU loops from running at wire speed |
| `options.noCookiesReset` | Keep cookies across iterations | Session-replay / stateful tests |
| `options.setupTimeout` | Max time allowed for `setup()` | Database seeding, slow auth flows |
| `options.hosts` | DNS override (like /etc/hosts) | Redirecting to staging without changing URLs |
| `options.httpDebug` | Log HTTP request/response details | Debugging auth flows locally |
| `options.insecureSkipTLSVerify` | Skip TLS cert validation | Self-signed certs on staging |
| `options.tlsAuth` | Client cert (mTLS) per domain | mTLS/zero-trust internal APIs |
| `options.systemTags` | Filter system tags on metrics | Reduce metric cardinality in dashboards |
| `options.dns` | DNS resolver behaviour (`ttl`, `select`, `policy`) | Round-robin DNS for load-balanced backends |
| `options.userAgent` | Override HTTP `User-Agent` header globally | Simulating specific client types or versions |
| `options.batchPerHost` | Max parallel requests per host in `http.batch()` | Prevents overwhelming a single origin with batch |
| `options.tlsVersion` | Restrict TLS version (`"tls1.2"`, `"tls1.3"`) | Enforce minimum TLS for compliance tests |
| `secrets.get(name)` | Retrieve secret from default source (async) | Credentials, API keys — values are log-redacted |
| `secrets.source(id).get(name)` | Retrieve from named secret source | Multi-environment credential routing |
| `page.frameLocator(selector)` | Locate elements inside an iframe | Testing embedded widgets / third-party frames |
| `page.waitForRequest(urlPattern)` | Wait for a specific HTTP request to fire | Asserting API calls are made on UI interactions |
| `page.waitForEvent(eventName)` | Wait for a browser event (popup, download, request) | Capturing popups, file downloads, navigation events |
| `page.on('requestfailed', fn)` | Subscribe to failed network requests (v1.6.0+) | Detecting broken asset loads, API call failures |
| `page.on('requestfinished', fn)` | Subscribe to completed network requests (v1.6.0+) | Auditing request timings without route interception |
| `locator.filter({ hasText })` | Filter locator results to only elements containing text | Scoping within lists to a specific item |
| `locator.pressSequentially(text)` | Type character-by-character with key events | Realistic input for auto-complete / event-driven fields |
| `page.evaluate(fn)` | Execute JavaScript in page context | Reading DOM state, counting elements, querying hidden data |
| `page.goBack()` / `page.goForward()` | Navigate browser history | Testing back-navigation flows |
| `page.route(pattern, handler)` | Intercept matching requests (abort/fulfill/continue) | Stub third-party APIs, inject auth headers, block noise |
| `route.fulfill(response)` | Return synthetic response without hitting server | Mock API errors (500/503), inject fixed payloads |
| `route.continue(overrides?)` | Pass through with optional modifications | Append auth headers, rewrite POST bodies |
| `open(path, 'b')` | Load local file as binary (ArrayBuffer) | Binary upload tests, WASM payloads |
| `k6/experimental/fs` open | Memory-mapped file sharing across all VUs | Large files > 10 MB; avoids per-VU string copies |
| `exec.test.fail(msg)` | Mark test failed (exit 110) without stopping | Flag pre-condition failures while collecting all metrics |
| `ReadableStream` (k6/experimental/streams) | Define a producer-consumer data pipeline | Line-by-line processing of very large files without full in-memory load |

---

## Network Error Codes & Diagnostics  [community]

k6 uses numeric error codes on `res.error_code` for non-HTTP errors (network failures, timeouts). Understanding these is essential for distinguishing load-generator problems from target-system problems.

| Range | Category | Key Codes |
|-------|----------|-----------|
| 1000–1099 | General | 1000=generic, 1010=non-TCP net error, 1020=invalid URL, 1050=HTTP timeout |
| 1100–1199 | DNS | 1100=generic DNS, 1101=no IP found, 1110=blacklisted IP |
| 1200–1299 | TCP | 1200=generic TCP, 1210=dial error, 1211=dial timeout, 1212=connection refused, 1220=connection reset |
| 1300–1399 | TLS | 1300=generic TLS, 1310=unknown CA, 1311=hostname mismatch |
| 1400–1499 | HTTP 4xx | Client-side errors |
| 1500–1599 | HTTP 5xx | Server-side errors |
| 1600–1699 | HTTP/2 | 1600=generic H2, 1610=GoAway, 1630=stream error, 1650=connection error |

```javascript
// k6/scripts/error-aware-load.js — differentiate network vs. server errors
import http from "k6/http";
import { check } from "k6";
import { Counter, Rate } from "k6/metrics";

const networkErrors  = new Counter("network_errors");    // non-HTTP errors (timeout, reset)
const serverErrors   = new Rate("server_error_rate");    // 5xx HTTP errors
const clientErrors   = new Rate("client_error_rate");    // 4xx HTTP errors

export const options = {
  scenarios: {
    load: { executor: "constant-vus", vus: 20, duration: "2m" },
  },
  thresholds: {
    network_errors:    ["count<10"],      // hard fail if any network errors accumulate
    server_error_rate: ["rate<0.01"],
    client_error_rate: ["rate<0.005"],    // 4xx are usually bugs in the test script
    http_req_failed:   ["rate<0.02"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  const res = http.get(`${BASE}/api/items`, { timeout: "15s" });

  // Categorize by error type for better diagnostics
  if (res.error_code !== 0) {
    // Non-HTTP error: timeout (1050), connection reset (1220), DNS failure (1101)
    networkErrors.add(1, { error_code: String(res.error_code) });
    // error_code 1211 = dial timeout → load generator can't reach target
    // error_code 1220 = connection reset → target closed connection under load
    // error_code 1050 = HTTP timeout → target too slow to respond within timeout
  }

  serverErrors.add(res.status >= 500 && res.status < 600 ? 1 : 0);
  clientErrors.add(res.status >= 400 && res.status < 500 ? 1 : 0);

  check(res, {
    "status 200":      (r) => r.status === 200,
    "no error":        (r) => r.error_code === 0,
  });
}
```

> **[community]:** `error_code 1220` (connection reset by peer) and `error_code 1212` (connection refused) are almost always the **target system** failing under load — not the load generator. `error_code 1211` (dial timeout) or `error_code 1101` (DNS failure) usually indicate a **network or infrastructure problem** between the load generator and target. Tag error counts by `error_code` to diagnose root cause without manual log inspection.

> **[community]:** `http_req_failed` by default is `true` when `error_code !== 0` OR `status >= 400`. Override this with `http.setResponseCallback(http.expectedStatuses(...))` if your API returns 4xx codes that should be considered "success" in your test (e.g., a 404 rate test or a 400-for-validation endpoint).

```javascript
// k6/scripts/custom-failure-def.js — redefine what "failed" means per-script
import http from "k6/http";
import { check } from "k6";

// Global override: only treat these as non-failures
// 200–204 range, 406, and 500 will NOT increment http_req_failed
http.setResponseCallback(
  http.expectedStatuses({ min: 200, max: 204 }, 406, 429)
  // 429 = rate limit: expected, not a bug → don't count it as a failure
);

export const options = {
  thresholds: {
    // Now http_req_failed only counts true unexpected errors
    http_req_failed: ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  // Per-request override — only for this specific request
  const res = http.get(`${BASE}/api/resource/missing`, {
    responseCallback: http.expectedStatuses(200, 404),  // 404 = OK here
  });
  check(res, { "200 or 404": (r) => r.status === 200 || r.status === 404 });
}
```



The `k6/execution` module (k6 v0.34+) provides real-time execution context. Prefer it
over `__VU` and `__ITER` for distributed-safe unique IDs.

```javascript
// k6/scripts/execution-context.js
import http from "k6/http";
import { check, sleep } from "k6";
import exec from "k6/execution";

export const options = {
  scenarios: {
    load: {
      executor: "ramping-vus",
      stages: [
        { duration: "30s", target: 20 },
        { duration: "1m",  target: 20 },
        { duration: "10s", target: 0  },
      ],
    },
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  // exec.scenario.iterationInTest is globally unique across all VUs and instances
  // Safer than __VU * __ITER for generating unique IDs in distributed runs
  const globalIter   = exec.scenario.iterationInTest;
  const vuIdInTest   = exec.vu.idInTest;
  const scenarioName = exec.scenario.name;

  // Progress monitoring — useful for long soak tests
  const progress = (exec.scenario.progress * 100).toFixed(1);

  // Abort the test from within VU code (use sparingly)
  if (exec.vu.iterationInScenario === 0 && exec.vu.idInTest === 1) {
    // First VU, first iteration — good place for pre-flight checks
    const healthRes = http.get(`${BASE}/api/health`);
    if (healthRes.status !== 200) {
      // Gracefully abort: all VUs will finish their current iteration then stop
      exec.test.abort("Health check failed at start of test");
    }
  }

  const res = http.post(
    `${BASE}/api/items`,
    JSON.stringify({ name: `item-${globalIter}`, vuId: vuIdInTest }),
    { headers: { "Content-Type": "application/json" } }
  );

  check(res, { "created": (r) => r.status === 201 });
  sleep(1);
}
```

**`exec.test.abort(message)`** — programmatically stops the test from within VU code.
Use for pre-flight failures (wrong environment, missing fixtures) where continuing would
produce meaningless results. The test exits with **exit code 108** (Usage error) and the
`teardown()` function still runs after the abort. In k6 v2.0.0+, cloud tests aborted this
way return exit code **97** instead of `0`.

| exec property | Type | What it provides |
|---------------|------|-----------------|
| `exec.scenario.name` | string | Running scenario name |
| `exec.scenario.executor` | string | Executor type |
| `exec.scenario.startTime` | number | Unix ms timestamp |
| `exec.scenario.progress` | number | 0.0–1.0 completion |
| `exec.scenario.iterationInTest` | number | Global unique iteration ID |
| `exec.vu.idInTest` | number | VU ID across full test (stable across segments) |
| `exec.vu.idInInstance` | number | VU ID within k6 instance |
| `exec.vu.iterationInScenario` | number | Per-VU iteration count within scenario |
| `exec.instance.iterationsCompleted` | number | Total iterations done by this instance |
| `exec.instance.currentTestRunDuration` | number | Milliseconds elapsed |
| `exec.test.abort(msg)` | function | Gracefully abort the entire test (exit 108) |
| `exec.test.fail(msg)` | function | Mark test as failed without interrupting (exit 110) |
| `exec.vu.metrics.metadata` | object | High-cardinality key-value store per VU (not exported to output) |

**Test Control exit codes:**
- `exec.test.abort(msg)` → exit code **108** (Usage error). All VUs finish their current iteration, then the test stops. `teardown()` still executes. In k6 v2.0.0+ cloud mode this returns exit **97** instead of `0`.
- `exec.test.fail(msg)` → exit code **110** (Threshold failure). The test continues running to completion — only the exit code changes. Use when you want to flag a pre-condition failure but still collect all metrics (e.g., a dependency check failed but you want partial results).

**Metric Enrichment — tags vs metadata:**
- `exec.vu.metrics.tags` — low-cardinality labels (role, environment, region). These are exported to every metric output format and can be used in threshold filters like `"http_req_duration{role:admin}": ["p(95)<500"]`. Supports strings, numbers, booleans only.
- `exec.vu.metrics.metadata` — high-cardinality key-value pairs (trace IDs, request IDs, user IDs). Included in the raw event stream but NOT indexed as metric dimensions, so they won't bloat your time-series cardinality. Use for correlating k6 spans with distributed tracing systems.

```javascript
export default function () {
  // Low-cardinality: use tags (filterable in thresholds)
  exec.vu.metrics.tags["region"] = __ENV.REGION || "us-east-1";

  // High-cardinality: use metadata (correlate with traces, not for thresholds)
  exec.vu.metrics.metadata["trace_id"] = generateTraceId();
  exec.vu.metrics.metadata["request_id"] = `req-${Date.now()}-${exec.vu.idInTest}`;
}
```

### Dynamic VU Tagging with `exec.vu.metrics.tags`

Tags set via `exec.vu.metrics.tags` persist across all iterations of a VU and are added to every metric emitted by that VU. Use this to stamp metrics with user-specific or role-specific context without repeating tags on every request.

```javascript
// k6/scripts/vu-tagged-load.js
import http from "k6/http";
import { check, sleep } from "k6";
import exec from "k6/execution";
import { SharedArray } from "k6/data";

const roles = new SharedArray("roles", function () {
  return ["reader", "writer", "admin", "viewer"];
});

export const options = {
  // Global tags — stamped on ALL metrics from ALL VUs
  tags: {
    environment: __ENV.TEST_ENV   || "qa",
    version:     __ENV.APP_VERSION || "unknown",
    test_run_id: __ENV.CI_RUN_ID  || `local-${Date.now()}`,
  },
  scenarios: {
    mixed_roles: { executor: "constant-vus", vus: 20, duration: "2m" },
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  // Set per-VU role tag — persists for all iterations of this VU
  const role = roles[exec.vu.idInTest % roles.length];
  exec.vu.metrics.tags["role"] = role;

  // Now every metric from this VU is tagged with the role
  const res = http.get(`${BASE}/api/resources`, {
    headers: { "X-Role": role },
  });
  check(res, { "status 200": (r) => r.status === 200 });
  sleep(1);
}
```

**Per-scenario role differentiation in thresholds:**
```javascript
thresholds: {
  "http_req_duration{role:admin}":  ["p(95)<500"],
  "http_req_duration{role:reader}": ["p(95)<200"],
  "http_req_duration{role:writer}": ["p(95)<400"],
}
```

> **[community]:** `exec.vu.metrics.tags` supports strings, numbers, and booleans only. Setting an object or array throws an error (or a warning if the `throw` option is false). Do NOT overwrite system tags like `url`, `method`, or `scenario` — those are managed by k6 and the overwrite has no effect on the actual metric values.

### Multiple Concurrent WebSocket Connections per VU  [community]

The `k6/websockets` stable module uses a **global event loop** — unlike the legacy `k6/ws` which used a local event loop. This means a single VU can maintain multiple simultaneous WebSocket connections, enabling fan-out patterns (subscribe to multiple channels) without multiplying VU count.

```javascript
// k6/scripts/ws-fanout.js — one VU, multiple WebSocket connections
import { WebSocket } from "k6/websockets";
import { check } from "k6";
import { Counter } from "k6/metrics";

const totalMessages = new Counter("total_messages_received");

export const options = {
  scenarios: {
    ws_fanout: {
      executor: "constant-vus",
      vus: 5,        // 5 VUs × 3 connections each = 15 concurrent WebSocket connections
      duration: "1m",
    },
  },
  thresholds: {
    total_messages_received: ["count>0"],
    checks:                   ["rate>0.99"],
  },
};

const WS_URL = (__ENV.API_URL || "http://localhost:3001")
  .replace(/^http/, "ws") + "/ws";

export default function () {
  const channels = ["prices", "trades", "orderbook"];
  const sockets  = [];

  // Open 3 connections per VU — all share the global event loop
  for (const channel of channels) {
    const ws = new WebSocket(`${WS_URL}/${channel}`);

    ws.onopen = () => {
      ws.send(JSON.stringify({ subscribe: channel }));
      setTimeout(() => ws.close(), 30_000);  // close after 30s
    };

    ws.onmessage = (e) => {
      totalMessages.add(1, { channel });
      const msg = JSON.parse(e.data);
      check(msg, { "has data": (m) => m.data !== undefined });
    };

    ws.onerror = (e) => {
      if (e.error() !== "websocket: close sent") {
        console.error(`WS error on ${channel}:`, e.error());
      }
    };

    sockets.push(ws);
  }

  // The global event loop blocks until all sockets close
  // No explicit "wait" needed — the VU is held until all ws.close() calls complete
}
```

> **[community]:** The legacy `k6/ws` module blocks on `ws.connect(url, null, callback)` — you cannot have two `ws.connect()` calls in the same `default()` function because the first one blocks until it closes. The `k6/websockets` module with its global event loop does not have this limitation. This is the primary reason to migrate from `k6/ws` to `k6/websockets` for fan-out patterns.



## Executor Quick-Reference

| Executor | Key Option | Best For |
|----------|-----------|---------|
| `shared-iterations` | `vus`, `iterations` | Fixed total request count |
| `per-vu-iterations` | `vus`, `iterations` | Each VU runs N iterations |
| `constant-vus` | `vus`, `duration` | Simple sustained load |
| `ramping-vus` | `stages[]` | Ramp-up / load / ramp-down |
| `constant-arrival-rate` | `rate`, `duration` | Fixed RPS / TPS |
| `ramping-arrival-rate` | `stages[]` (rate targets) | Gradually increasing RPS |
| ~~`externally-controlled`~~ | ~~(CLI / REST API)~~ | **Removed in k6 v2.0** — use `ramping-vus` + `startTime` |

---

## CI Considerations

### Exit Codes

k6 returns a non-zero exit code when thresholds fail, making it a first-class CI gate:

| Exit code | Meaning |
|-----------|---------|
| `0` | All thresholds passed — test succeeded |
| `97` | Cloud test aborted for non-threshold reason (k6 v2.0+) |
| `99` | One or more thresholds failed |
| `108` | Usage error (bad flags, missing script) |

> **v2.0 change:** Cloud non-threshold aborts (e.g., infrastructure failures, `exec.test.abort()`)
> now return exit code `97` instead of `0`. CI pipelines that checked for `exit 0` as "success" will
> need to differentiate between `97` (infrastructure/programmatic abort) and `99` (threshold failure).

In any CI pipeline, check `$?` or rely on the non-zero exit to fail the build:

```bash
# GitHub Actions / any POSIX shell
k6 run \
  --env API_URL="$API_URL" \
  --env E2E_USER_EMAIL="$E2E_USER_EMAIL" \
  --env E2E_USER_PASSWORD="$E2E_USER_PASSWORD" \
  --no-color \
  --out json=results/k6-raw.json \
  k6/scripts/load.js
# Build fails automatically if k6 exits with code 99 (threshold breach)
```

### GitHub Actions Example

```yaml
# .github/workflows/perf.yml
name: Performance Tests
on:
  push:
    branches: [main]
jobs:
  k6:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install k6
        run: |
          sudo gpg -k
          sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
            --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
          echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
            | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update && sudo apt-get install k6
      - name: Set file descriptor limit  # [community] prevents "too many open files" at high VU counts
        run: ulimit -n 65536
      - name: Run k6 load test
        env:
          API_URL: ${{ vars.STAGING_API_URL }}
          E2E_USER_EMAIL: ${{ secrets.E2E_USER_EMAIL }}
          E2E_USER_PASSWORD: ${{ secrets.E2E_USER_PASSWORD }}
        run: |
          mkdir -p results
          k6 run --no-color k6/scripts/load.js
      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: k6-results
          path: results/
```

### Synthetic Monitoring — Scheduled Smoke Tests  [community]

Run k6 smoke tests on a cron schedule against production or staging to detect regressions
between deployments. A 1-VU smoke test every 5 minutes acts as an SLO heartbeat —
catching endpoint degradations within one polling cycle.

```yaml
# .github/workflows/synthetic-monitor.yml — k6 as synthetic monitoring tool
name: Synthetic Monitor
on:
  schedule:
    - cron: "*/5 * * * *"   # every 5 minutes
  workflow_dispatch:          # allow manual trigger

jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install k6
        run: |
          sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
            --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
          echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
            | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update && sudo apt-get install k6

      - name: Run production smoke test
        env:
          API_URL: ${{ vars.PROD_API_URL }}
          E2E_USER_EMAIL: ${{ secrets.E2E_USER_EMAIL }}
          E2E_USER_PASSWORD: ${{ secrets.E2E_USER_PASSWORD }}
        run: |
          k6 run --no-color \
            --out json=smoke-results.json \
            k6/scripts/smoke.js
        # Non-zero exit = threshold violation = workflow fails = alert fires

      - name: Upload smoke results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: synthetic-monitor-${{ github.run_id }}
          path: smoke-results.json
          retention-days: 30
```

> **[community]:** For production synthetic monitoring, keep smoke tests to 1 VU and < 30s
> duration. Use `--no-color` and `--summary-mode=compact` to minimize log noise in scheduled
> runs. Set up GitHub Actions alert rules on workflow failure to notify on-call.
> For more advanced scheduled monitoring with regional coverage, use
> **Grafana Cloud Synthetic Monitoring** — it runs k6 scripts from multiple AWS regions
> on your schedule and integrates with Grafana alerting natively.

### GitLab CI Example

```yaml
# .gitlab-ci.yml
stages:
  - performance

k6-smoke:
  stage: performance
  image: grafana/k6:latest
  script:
    - mkdir -p results
    - k6 run --no-color -e API_URL="$STAGING_API_URL" -e E2E_USER_EMAIL="$E2E_USER_EMAIL"
        -e E2E_USER_PASSWORD="$E2E_USER_PASSWORD"
        --out json=results/k6-raw.json k6/scripts/load.js
  artifacts:
    when: always
    paths:
      - results/
    expire_in: 7 days
  variables:
    K6_NO_SUMMARY: "false"
  rules:
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH == "main"'

# Nightly load test — runs on a schedule, not on every push
k6-load-nightly:
  stage: performance
  image: grafana/k6:latest
  script:
    - ulimit -n 65536
    - mkdir -p results
    - k6 run --no-color -e API_URL="$STAGING_API_URL" -e TEST_ENV=staging k6/scripts/load.js
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
  variables:
    API_URL: $STAGING_API_URL
```

> **[community]:** In GitLab CI, use `image: grafana/k6:latest` for simple scripts with no npm dependencies. For scripts that need bundled npm packages, use `image: grafana/k6:latest-with-browser` for browser tests, or build a custom image with `xk6` for extension-based scripts. Always pin the image version in production (`grafana/k6:1.7.1`) — `latest` can break on major version upgrades.

### Docker k6 Usage  [community]

```bash
# Basic run — pipe script via stdin (avoids volume mount issues)
docker run --rm -i grafana/k6 run --vus 10 --duration 30s - <k6/scripts/load.js

# With environment variables and mounted results directory
docker run --rm -i \
  -e API_URL="$API_URL" \
  -e E2E_USER_EMAIL="$E2E_USER_EMAIL" \
  -e E2E_USER_PASSWORD="$E2E_USER_PASSWORD" \
  -v "$PWD/results:/results" \
  grafana/k6 run --no-color - <k6/scripts/load.js

# With script files mounted (necessary for scripts that use open() or local imports)
docker run --rm \
  -v "$PWD/k6:/k6" \
  -v "$PWD/results:/results" \
  -e API_URL="$API_URL" \
  grafana/k6 run --no-color /k6/scripts/load.js

# k6 browser module — requires --cap-add and shared memory
docker run --rm -i \
  --cap-add=SYS_ADMIN \
  --shm-size=2gb \
  -e API_URL="$API_URL" \
  -v "$PWD/results:/results" \
  grafana/k6:latest-with-browser run --no-color - <k6/scripts/browser-smoke.js
```

> **[community]:** The browser module requires `--cap-add=SYS_ADMIN` and `--shm-size` ≥ 1 GB when running in Docker. Without shared memory expansion, Chromium crashes immediately with "error while loading shared libraries." Use `grafana/k6:latest-with-browser` — the base `grafana/k6` image does not include Chromium.

### `k6 cloud run --local-execution` — Stream Results to Grafana Cloud  [community]

Stream metrics from a locally-executed test to Grafana Cloud k6 for real-time dashboarding without running on cloud infrastructure. Useful when you need Grafana Cloud's visualization and alerting but want the load to originate from your own machines (e.g., inside a VPC).

```bash
# Authenticate once (stores credentials in ~/.config/k6)
k6 cloud login --token "$K6_CLOUD_API_TOKEN" --stack "$K6_CLOUD_STACK"

# Run locally, stream results to Grafana Cloud
k6 cloud run --local-execution --no-color k6/scripts/load.js

# Fully headless — no stored credentials needed (CI use)
K6_CLOUD_TOKEN="$K6_CLOUD_API_TOKEN" \
K6_CLOUD_STACK_ID="$K6_CLOUD_STACK" \
  k6 cloud run --local-execution --no-color k6/scripts/load.js

# Disable archive upload (speeds up startup — useful if script uses open() files)
K6_CLOUD_TOKEN="$K6_CLOUD_API_TOKEN" \
K6_CLOUD_STACK_ID="$K6_CLOUD_STACK" \
  k6 cloud run --local-execution --no-archive-upload --no-color k6/scripts/load.js
```

> **[community]:** `--local-execution` and `k6 cloud run` (pure cloud) both consume VUH from your Grafana Cloud subscription. The difference: with `--local-execution` your machine generates the load; without it, Grafana Cloud's infrastructure does. Use `--local-execution` when your target API is inside a private network not accessible from Grafana Cloud load zones.

> **Note:** The `ulimit -n 65536` step is a community-discovered requirement. Without it,
> tests with more than ~1,000 concurrent VUs fail with "socket: too many open files" and
> the failure is mistakenly attributed to the target system rather than the test agent.

### Custom Summary Output (`handleSummary`)

`--summary-export` is deprecated in favor of `handleSummary()` for full control over the
output format (JSON, JUnit XML, HTML, plain text). Add it to any script:

```javascript
// k6/scripts/load.js (add this export)
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.2/index.js";

export function handleSummary(data) {
  return {
    stdout: textSummary(data, { indent: "→", enableColors: false }), // CI-friendly
    "results/summary.json": JSON.stringify(data, null, 2),           // machine-readable
  };
}
```

### Parallelism and VU Limits

- A single k6 instance can handle **30,000–40,000 concurrent VUs** efficiently, generating
  up to 300,000 HTTP req/s. Distributed execution is only needed above ~100,000 RPS.
- Default OS limit on open file descriptors is 1024; k6 needs one per active connection.
  On Linux CI: `ulimit -n 65536` (minimum) or `ulimit -n 250000` (recommended) before
  running high-VU tests. Also set:
  ```bash
  sysctl -w net.ipv4.ip_local_port_range="1024 65535"
  sysctl -w net.ipv4.tcp_tw_reuse=1
  ```
- Keep **CPU below 80%** on the load generator. If k6 is CPU-starved it throttles its own
  scheduling and produces artificially inflated latency numbers that don't reflect server perf.
- k6 is **single-process** — all VUs run in one process. For very high RPS (>10 k/s),
  run multiple k6 instances with `--execution-segment`:
  ```bash
  # Machine 1: first half of VUs
  k6 run --execution-segment "0:1/2" --execution-segment-sequence "0,1/2,1" script.js
  # Machine 2: second half
  k6 run --execution-segment "1/2:1" --execution-segment-sequence "0,1/2,1" script.js
  ```
  Note: each instance evaluates thresholds independently; aggregate results manually.
  For a **3-way split** (e.g., three CI runners in parallel):
  ```bash
  k6 run --execution-segment "0:1/3"     --execution-segment-sequence "0,1/3,2/3,1" script.js
  k6 run --execution-segment "1/3:2/3"   --execution-segment-sequence "0,1/3,2/3,1" script.js
  k6 run --execution-segment "2/3:1"     --execution-segment-sequence "0,1/3,2/3,1" script.js
  ```
  Each segment takes its proportional share of VUs and iterations. Use `--tag segment=N`
  to identify which machine produced which metrics when aggregating results in Grafana.
- `gracefulStop` (default `30s`) gives running iterations time to complete when a
  scenario ends. Reduce it in CI to avoid unnecessarily long runs:
  ```javascript
  scenarios: {
    api_load: {
      executor: "ramping-vus",
      gracefulStop: "5s",   // CI: shorter is fine; prod: keep at 30s
    },
  }
  ```

### CI-Specific Cautions  [community]

- **Not all tests belong in CI.** Smoke tests are the only load test type suitable for
  every PR pipeline. Stress, soak, and breakpoint tests belong in scheduled nightly or
  weekly runs — inserting them in PR pipelines causes 15-minute build delays.
- **QA environments often have different capacity than production.** A threshold that passes
  in QA (under-resourced) may false-positive; one that fails in QA may be fine in prod.
  Baseline-compare across identical environments, not across different tiers.
- **Run the same test twice to confirm a failure.** k6 threshold failures can be caused by
  transient infrastructure noise (shared CI runner CPU spikes, GC pauses). A failure that
  doesn't reproduce on an immediate re-run is noise, not a regression.
- **`--no-color` is required for readable CI logs.** ANSI escape codes render as garbage
  in most CI log viewers; always pass `--no-color` in pipeline steps.

### Timeout & Retry Guidance

- Set `options.timeout` at the scenario level (`"10m"` max per scenario) to prevent
  runaway tests in CI from blocking the pipeline.
- k6 does **not** retry failed requests automatically. For retry logic use a helper:
  ```javascript
  function httpGetWithRetry(url, params, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
      const res = http.get(url, params);
      if (res.status !== 0 && res.status < 500) return res;
      sleep(0.5 * (i + 1));  // back-off: 0.5s, 1s, 1.5s
    }
    return http.get(url, params); // final attempt
  }
  ```
- For **rate-limited APIs (HTTP 429)**, respect the `Retry-After` response header:
  ```javascript
  function httpGetRespectingRateLimit(url, params, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
      const res = http.get(url, params);
      if (res.status === 429) {
        // Respect Retry-After header (seconds); fall back to exponential back-off
        const retryAfter = res.headers["Retry-After"]
          ? Number(res.headers["Retry-After"])
          : Math.pow(2, i);   // 1s, 2s, 4s
        sleep(retryAfter);
        continue;
      }
      if (res.status !== 0 && res.status < 500) return res;
      sleep(0.5 * (i + 1));  // 5xx back-off: 0.5s, 1s, 1.5s
    }
    return http.get(url, params); // final attempt — let caller check status
  }
  ```
  > **[community]:** Load testing a rate-limited API with no retry logic reports misleading
  > 429 errors as "failures." For APIs where rate limiting is expected behavior (not a bug),
  > use a custom Rate metric to track 429 responses separately from genuine failures:
  > `const rateLimited = new Rate("rate_limited"); rateLimited.add(res.status === 429);`
- Use `delayAbortEval` on `abortOnFail` thresholds to let the system warm up before
  evaluating: `delayAbortEval: "30s"` is a good default; use `"60s"` for soak tests.
- Common CI error messages and their causes:
  - `"read: connection reset by peer"` — target cannot handle the load
  - `"context deadline exceeded"` — system unresponsive within the 60s default timeout
  - `"dial tcp: i/o timeout"` — TCP connection never established
  - `"socket: too many open files"` — `ulimit` not set; increase file descriptor limit

### Real-Time Metrics Output

Stream metrics to external systems during the run:

```bash
# k6 Web Dashboard — built-in real-time browser UI (no external tools required)
# NOTE (v2.0): Dashboard is now part of the core k6 binary — no xk6-dashboard extension needed.
# Default: http://localhost:5665 — open in browser while test runs
K6_WEB_DASHBOARD=true k6 run k6/scripts/load.js

# Web dashboard with automatic HTML report export at test end
K6_WEB_DASHBOARD=true \
K6_WEB_DASHBOARD_EXPORT=results/web-dashboard-report.html \
  k6 run k6/scripts/load.js

# Custom host/port (for CI machines where 5665 is occupied)
K6_WEB_DASHBOARD=true \
K6_WEB_DASHBOARD_HOST=0.0.0.0 \
K6_WEB_DASHBOARD_PORT=8888 \
K6_WEB_DASHBOARD_OPEN=false \
  k6 run k6/scripts/load.js
```

```bash
# InfluxDB + Grafana (local dashboard) — most common local stack
k6 run --out influxdb=http://localhost:8086/k6 k6/scripts/load.js

# Prometheus remote-write (requires Prometheus 2.x)
# Note: still uses "experimental-prometheus-rw" name as of k6 v1.x
K6_PROMETHEUS_RW_SERVER_URL=http://localhost:9090/api/v1/write \
  k6 run --out experimental-prometheus-rw k6/scripts/load.js

# Prometheus remote-write with native histograms (Prometheus 2.40+)
K6_PROMETHEUS_RW_SERVER_URL=http://localhost:9090/api/v1/write \
K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true \
K6_PROMETHEUS_RW_TREND_STATS=p(50),p(90),p(95),p(99),min,max \
K6_PROMETHEUS_RW_STALE_MARKERS=true \
  k6 run --tag testid=smoke-001 --out experimental-prometheus-rw k6/scripts/load.js

# OpenTelemetry (stable as of k6 v1.3) — OTLP HTTP or gRPC
# Metrics automatically prefixed with "k6_"; Rate → Int64Counter, Trend → Float64Histogram
K6_OTEL_GRPC_EXPORTER_ENDPOINT=localhost:4317 \
K6_OTEL_METRIC_PREFIX=k6_ \
K6_OTEL_SERVICE_NAME=my-load-test \
  k6 run --out opentelemetry k6/scripts/load.js

# OpenTelemetry via HTTP/protobuf (for Tempo or Jaeger ingestion)
K6_OTEL_HTTP_EXPORTER_ENDPOINT=http://localhost:4318 \
K6_OTEL_EXPORTER_PROTOCOL=http/protobuf \
  k6 run --out opentelemetry k6/scripts/load.js

# OpenTelemetry with custom service name, prefix, and flush settings
K6_OTEL_GRPC_EXPORTER_ENDPOINT=localhost:4317 \
K6_OTEL_METRIC_PREFIX=k6_ \
K6_OTEL_SERVICE_NAME=my-load-test \
K6_OTEL_FLUSH_INTERVAL=1s \
K6_OTEL_EXPORT_INTERVAL=10s \
  k6 run --out opentelemetry k6/scripts/load.js

# Note: k6 v2.0 removed the exporterType option and SingleCounterForRate.
# Use K6_OTEL_EXPORTER_PROTOCOL instead of exporterType.
# Rate metrics now export as a single counter with "condition" attribute (zero/nonzero)
# instead of the legacy pair-of-counters format (metric.occurred / metric.total).

# Datadog — add K6_STATSD_ENABLE_TAGS=true for tag support
K6_STATSD_ADDR=localhost:8125 \
  k6 run --out statsd k6/scripts/load.js

# CSV for offline analysis (large files — use only for debugging)
k6 run --out csv=results/k6-metrics.csv k6/scripts/load.js

# Multiple outputs simultaneously
k6 run \
  --out json=results/k6-raw.json \
  --out csv=results/k6-metrics.csv \
  k6/scripts/load.js
```

> **[community]:** When streaming to cloud (InfluxDB, Prometheus), add
> `--no-thresholds --summary-mode=disabled` to avoid duplicate computation. These flags skip the
> local summary output — useful when the external system handles alerting.
> Note: `--no-summary` was removed in k6 v2.0; use `--summary-mode=disabled` instead.

---

## K6_ Environment Variable Quick Reference

All k6 script `options` have a `K6_*` equivalent for CI/CD override without modifying scripts.
Note: Complex nested options (`scenarios`, `thresholds`) are NOT configurable via env vars.

| Variable | Default | Purpose |
|----------|---------|---------|
| `K6_VUS` | `1` | Virtual user count (overrides script) |
| `K6_DURATION` | `null` | Test duration, e.g., `"5m"` |
| `K6_ITERATIONS` | `1` | Fixed iteration count |
| `K6_RPS` | `0` (unlimited) | Global RPS cap across all VUs |
| `K6_COMPATIBILITY_MODE` | `"extended"` | `"base"` saves ~20-30% memory for large tests |
| `K6_DISCARD_RESPONSE_BODIES` | `false` | Discard all response bodies to save memory |
| `K6_NO_THRESHOLDS` | `false` | Skip threshold evaluation (dry run) |
| `K6_NO_SETUP` | `false` | Skip `setup()` (re-run without re-seeding) |
| `K6_NO_TEARDOWN` | `false` | Skip `teardown()` (preserve test state) |
| `K6_DNS` | `ttl=5m,select=random,policy=preferIPv4` | DNS TTL, selection, and IP policy |
| `K6_LOCAL_IPS` | — | Source IPs/CIDRs for load generator rotation |
| `K6_USER_AGENT` | `"Grafana k6/<version>"` | Override HTTP User-Agent globally |
| `K6_BATCH` | `20` | Max concurrent connections in `http.batch()` |
| `K6_BATCH_PER_HOST` | `6` | Max per-host connections in `http.batch()` |
| `K6_SETUP_TIMEOUT` | `"60s"` | Max time for `setup()` |
| `K6_TEARDOWN_TIMEOUT` | `"60s"` | Max time for `teardown()` |
| `K6_MIN_ITERATION_DURATION` | `0` | Minimum iteration duration (VU sleeps if faster) |
| `K6_LOG_FORMAT` | default | `"json"` for structured log ingestion |
| `K6_LOG_OUTPUT` | `stderr` | `"loki=http://loki:3100/loki/api/v1/push"` |
| `K6_TRACES_OUTPUT` | `none` | `"otel=grpc://tempo:4317"` for OTel traces |
| `K6_CONSOLE_OUTPUT` | `null` | File path for `console.log()` output |
| `K6_SUMMARY_MODE` | `"compact"` | `"full"`, `"disabled"` (v2.0: replaces `--no-summary`) |
| `K6_SUMMARY_TREND_STATS` | `"avg,min,med,max,p(90),p(95)"` | Percentiles in end-of-test summary |
| `K6_WEB_DASHBOARD` | `false` | `true` enables real-time browser UI at `localhost:5665` |
| `K6_WEB_DASHBOARD_EXPORT` | `null` | Auto-export HTML report at test end |
| `K6_SECRET_SOURCE` | — | Identical to `--secret-source` flag for secrets config |
| `K6_DEPENDENCY_MANIFEST` | `null` | JSON manifest for pinning xk6 extension versions |
| `K6_CLOUD_TOKEN` | — | Grafana Cloud k6 auth token |
| `K6_CLOUD_STACK_ID` | — | Grafana Cloud stack (mandatory in k6 v2.0) |
| `K6_PROFILING_ENABLED` | `false` | Enable pprof endpoint at `localhost:6565/debug/pprof/` |
| `K6_PAUSED` | `false` | Start test paused (resume via REST API or `k6 resume`) |
| `K6_NO_COLOR` | `false` | Disable ANSI colors in output (always use in CI) |
| `K6_ADDRESS` | `""` | Enable k6 REST API server at this address, e.g. `localhost:6565` (v2.0: disabled by default) |
| `K6_PROVISION_HOST_VERSION` | `""` | Exposes extension version compatibility info; used by xk6 auto-resolution to check host k6 semver against extension requirements |

```bash
# Typical CI override — no script modifications needed
K6_VUS=50 K6_DURATION=2m K6_NO_COLOR=true \
K6_COMPATIBILITY_MODE=base \
K6_SUMMARY_TREND_STATS="avg,p(95),p(99),max,count" \
  k6 run k6/scripts/load.js
```

> **[community]:** `K6_LOG_OUTPUT=loki=...` (k6 v1.x) routes all k6 logs (including
> `console.log()` from VU code) directly to Grafana Loki without a log-shipping sidecar.
> Pair with `K6_LOG_FORMAT=json` and the Loki log stream label `{app="k6",test="smoke"}`
> for centralized log correlation across distributed k6 runs.

> **[community]:** `K6_TRACES_OUTPUT=otel=grpc://tempo:4317` is the stable replacement
> for the deprecated `k6/experimental/tracing` module. It enables automatic OTel trace
> generation for every HTTP request without any script changes — just set the env var and
> add a Grafana data source pointing to your Tempo instance.

---

## Recommended Project Structure

```
k6/
  scripts/
    smoke.js              # 1-2 VUs sanity check
    load.js               # ramping-vus — normal traffic
    stress.js             # ramping-vus — beyond normal
    soak.js               # long-running stability
    soak-authed.js        # soak with per-VU JWT token refresh
    breakpoint.js         # ramping-arrival-rate — find max RPS
    mixed-load.js         # multi-scenario with scenarios API
    universal.js          # single script — smoke/load/stress via PROFILE env var
    websocket-load.js     # WebSocket load pattern (uses k6/websockets stable module)
    ws-authed-throughput.js # WebSocket with auth + latency metrics
    browser-smoke.js      # browser module UI smoke test
    browser-mobile.js     # browser module with CPU/network throttling
    mixed-protocol-browser.js  # HTTP + browser scenarios in one test
    grpc-load.js          # gRPC unary load test
    grpc-streaming.js     # gRPC server-side streaming
    graphql-load.js       # GraphQL query + mutation load test
    file-upload.js        # multipart file upload test
    csv-users-load.js     # CSV-parameterized load test
    page-load.js          # batch requests simulating page load
    user-journey.js       # multi-step user journey with groups
    session-flow.js       # cookie jar session management
    sequenced.js          # sequential scenario warm-up with startTime
    async-e2e.js          # async/eventual consistency E2E latency
    chaos-load.js         # load + xk6-disruptor fault injection (k8s only)
    mfa-load.js           # TOTP MFA authentication load test
    browser-advanced.js   # browser module with iframe, navigation, request interception
    streams-csv.js        # line-by-line CSV processing via k6/experimental/streams
    grpc-client-stream.js # gRPC client-side streaming (write N, receive 1)
    grpc-bidi-stream.js   # gRPC bidirectional streaming (write N, receive N)
    grpc-reflection.js    # gRPC without .proto files — uses server reflection
    grpc-health-preflight.js # gRPC health check in setup() as abort gate
    browser-reuse-auth.js # BrowserContext auth cookie injection pattern
  lib/
    auth.js               # shared setup() / getToken() helpers + token manager
    thresholds.js         # reusable threshold presets per environment
    data.js               # SharedArray test data loaders (JSON + CSV)
    retry.js              # httpGetWithRetry / httpPostWithRetry
    session.js            # cookie jar session helpers
  data/
    users.json            # parameterized test users (gitignored if sensitive)
    users.csv             # CSV user list — loaded via papaparse + SharedArray
    products.json         # product SKUs for checkout tests
  proto/
    items.proto           # .proto files for gRPC tests
    streaming.proto       # .proto for streaming tests
  k8s/
    testrun.yaml          # k6 Operator TestRun manifest for distributed execution
  dist/                   # webpack bundles (gitignored)
  results/                # .json / .csv / .html / JUnit summary exports (gitignored)
  webpack.config.js       # optional — only needed for npm dependency bundling
  tsconfig.json           # optional — k6 v0.57+ runs .ts files natively via esbuild
```

> **TypeScript note (k6 v0.57+):** k6 now runs `.ts` files directly — no bundler required
> for type annotations. Run `k6 run script.ts` directly. In k6 v0.57+, TypeScript support
> is enabled by default (the `experimental-enhanced-mode` flag was removed). k6 uses esbuild
> to transpile `.ts` files. Note: k6's TypeScript support is transpilation-only (esbuild
> strips types but does NOT type-check). For compile-time safety, add a `tsc --noEmit`
> pre-check step in CI before running k6.
>
> **Recommended tsconfig.json for k6 TypeScript projects:**
> ```json
> {
>   "compilerOptions": {
>     "target": "ES2020",
>     "module": "ESNext",
>     "lib": ["ES2020"],
>     "noEmit": true,
>     "strict": true,
>     "skipLibCheck": true,
>     "types": ["k6"]
>   }
> }
> ```
> Install k6 type definitions: `npm install --save-dev @types/k6`
> CI pre-check: `tsc --noEmit && k6 run script.ts`

---

## v2.0.0 Migration

k6 v2.0.0 (RC1 as of early 2026) is a major-version release with significant breaking changes.
Audit your scripts and CI pipelines before upgrading.

### What Was Removed

| Removed | Replacement |
|---------|-------------|
| `externally-controlled` executor | Use `ramping-vus` or `constant-vus` |
| `k6 pause`, `k6 resume`, `k6 scale`, `k6 status` | No replacement — use scenario `startTime` for sequencing |
| `k6 login` | `k6 cloud login` |
| `k6 cloud script.js` | `k6 cloud run script.js` |
| `--upload-only` | `k6 cloud upload script.js` |
| `--no-summary` | `--summary-mode=disabled` |
| `--summary-mode=legacy` | Only `full`, `compact`, `disabled` remain valid |
| `options.ext.loadimpact` | `options.cloud` |
| `k6/experimental/redis` | `k6/x/redis` (xk6 extension) |
| `browser_web_vital_fid` metric | `browser_web_vital_inp` (Interaction to Next Paint) |
| HTTP API server starts by default | Pass `--address localhost:6565` or set `K6_ADDRESS` to re-enable |
| `K6_BINARY_PROVISIONING` env var | Removed (deprecated since v1.2) |
| `K6_ENABLE_COMMUNITY_EXTENSIONS` env var | Removed |

### Migration Checklist

```bash
# 1. Find scripts using externally-controlled executor
grep -r "externally-controlled" k6/scripts/

# 2. Find scripts using deprecated CLI syntax in CI pipelines
grep -r "k6 cloud " .github/ .gitlab-ci.yml Jenkinsfile

# 3. Find deprecated browser metric in thresholds
grep -r "browser_web_vital_fid" k6/

# 4. Find scripts using --no-summary or options.ext.loadimpact
grep -r "no-summary\|loadimpact\|summary-mode=legacy" k6/

# 5. Find k6/experimental/redis imports
grep -r "experimental/redis" k6/

# 6. Find CI pipelines relying on the k6 REST API (disabled by default in v2.0)
grep -r "6565\|k6 pause\|k6 resume\|k6 scale\|k6 status" .github/ .gitlab-ci.yml Jenkinsfile

# 7. Check for K6_BINARY_PROVISIONING or K6_ENABLE_COMMUNITY_EXTENSIONS env vars
grep -r "K6_BINARY_PROVISIONING\|K6_ENABLE_COMMUNITY_EXTENSIONS" .github/ .gitlab-ci.yml
```

### Before/After Examples

```javascript
// BEFORE (v1.x) — externally-controlled executor
export const options = {
  scenarios: {
    controlled: {
      executor: "externally-controlled",
      vus: 10,
      maxVUs: 100,
    },
  },
};

// AFTER (v2.0) — use ramping-vus with explicit stages
export const options = {
  scenarios: {
    controlled: {
      executor: "ramping-vus",
      startVUs: 10,
      stages: [
        { duration: "2m",  target: 10  },
        { duration: "1m",  target: 50  },
        { duration: "2m",  target: 0   },
      ],
    },
  },
};
```

```javascript
// BEFORE (v1.x) — options.ext.loadimpact / cloud config
export const options = {
  ext: {
    loadimpact: {
      projectID: 12345,
      name: "My Load Test",
    },
  },
};

// AFTER (v2.0) — options.cloud
export const options = {
  cloud: {
    projectID: 12345,
    name: "My Load Test",
  },
};
```

```javascript
// BEFORE (v1.x) — browser Web Vitals threshold
thresholds: {
  "browser_web_vital_fid": ["p(75)<100"],  // First Input Delay — removed
}

// AFTER (v2.0) — use INP (Interaction to Next Paint — the Core Web Vital replacement)
thresholds: {
  "browser_web_vital_inp": ["p(75)<200"],  // INP replaces FID as a Core Web Vital
}
```

> **[community]:** `browser_web_vital_fid` was removed because Google replaced First Input
> Delay (FID) with Interaction to Next Paint (INP) as a Core Web Vital in March 2024.
> INP measures responsiveness across all interactions, not just the first — it is a more
> reliable indicator of real-world page responsiveness. Update dashboards and thresholds
> accordingly.

### Browser Module — New APIs (k6 v0.52+)

```javascript
// k6/scripts/browser-advanced.js — iframe + navigation + request interception
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    ui: {
      executor: "shared-iterations",
      vus: 1,
      iterations: 3,
      options: { browser: { type: "chromium" } },
    },
  },
  thresholds: {
    "browser_web_vital_lcp": ["p(75)<2500"],
    "browser_web_vital_inp": ["p(75)<200"],   // INP replaces FID in v2.0
    checks:                   ["rate==1.0"],
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/`);

    // waitForRequest: assert that a specific API call fires on button click
    const apiRequestPromise = page.waitForRequest("**/api/data");
    await page.getByRole("button", { name: "Load Data" }).click();
    const apiRequest = await apiRequestPromise;
    check(apiRequest.url(), { "correct endpoint": (u) => u.includes("/api/data") });

    // frameLocator: interact with content inside an iframe
    const frame = page.frameLocator("iframe#embedded-widget");
    const frameBtn = frame.locator("button.submit");
    if (await frameBtn.isVisible()) {
      await frameBtn.click();
    }

    // pressSequentially: character-by-character typing (triggers keyboard events)
    const searchInput = page.getByPlaceholder("Search...");
    await searchInput.pressSequentially("test query", { delay: 50 });

    // evaluate: run arbitrary JS in page context
    const itemCount = await page.evaluate(() => {
      return document.querySelectorAll(".item-card").length;
    });
    check(itemCount, { "items loaded": (n) => n > 0 });

    // goBack / goForward: browser history navigation
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/page2`);
    await page.goBack();
    check(page.url(), { "back to home": (u) => u.endsWith("/") || u.endsWith("/page1") });

    await page.screenshot({ path: `results/screenshot-${__ITER}.png` });
  } finally {
    await page.close();
  }
}
```

---

## Secrets Management — Extended Patterns

### `K6_SECRET_SOURCE` Environment Variable (k6 v1.7.0+)  [community]

The `K6_SECRET_SOURCE` env var is an alternative to the `--secret-source` CLI flag and uses identical syntax. This is valuable for CI systems where injecting environment variables is cleaner than modifying command-line arguments (e.g., when the k6 invocation is inside a Docker entrypoint or a CI template you cannot easily change).

```bash
# Equivalent: use env var instead of --secret-source flag
export K6_SECRET_SOURCE="mock=default,api_key=s3cr3t,db_password=hunter2"
k6 run k6/scripts/load.js

# URL source via env var (HashiCorp Vault or AWS Secrets Manager)
export K6_SECRET_SOURCE="url=https://vault.internal/v1/secret/k6"
k6 run k6/scripts/load.js

# Multiple named sources via env var (comma-separated)
export K6_SECRET_SOURCE="mock=primary,api_key=staging-key,url=https://vault.internal=secondary"
k6 run k6/scripts/load.js
```

**GitHub Actions pattern (env var approach):**
```yaml
- name: Run k6 with secrets from Vault
  env:
    K6_SECRET_SOURCE: "url=https://vault.internal/v1/secret/k6"
    VAULT_TOKEN: ${{ secrets.VAULT_TOKEN }}
  run: k6 run --no-color k6/scripts/load.js
```

> **[community]:** `K6_SECRET_SOURCE` and `--secret-source` cannot be used simultaneously — pick one per invocation. The env var form is preferable when deploying k6 inside Docker containers or Kubernetes pods where the command-line is baked into the image definition.

### Prometheus Remote-Write — Authentication Patterns  [community]

The Prometheus remote-write output (`--out experimental-prometheus-rw`) supports three authentication methods. Teams running k6 against Grafana Cloud's Prometheus-compatible endpoint or a secured Cortex/Thanos cluster need these configurations.

```bash
# Basic auth (Grafana Cloud Prometheus)
K6_PROMETHEUS_RW_SERVER_URL=https://prometheus-blocks-prod-us-central1.grafana.net/api/prom/push \
K6_PROMETHEUS_RW_USERNAME=12345 \
K6_PROMETHEUS_RW_PASSWORD="glc_token..." \
  k6 run --out experimental-prometheus-rw k6/scripts/load.js

# Bearer token (custom Prometheus with OAuth2 proxy)
K6_PROMETHEUS_RW_SERVER_URL=https://prometheus.internal/api/v1/write \
K6_PROMETHEUS_RW_BEARER_TOKEN="eyJhbGci..." \
  k6 run --out experimental-prometheus-rw k6/scripts/load.js

# mTLS (internal Prometheus with mutual TLS)
K6_PROMETHEUS_RW_SERVER_URL=https://prometheus.internal/api/v1/write \
K6_PROMETHEUS_RW_CLIENT_CERTIFICATE=/certs/client.pem \
K6_PROMETHEUS_RW_CLIENT_CERTIFICATE_KEY=/certs/client.key \
  k6 run --out experimental-prometheus-rw k6/scripts/load.js

# AWS SigV4 (Amazon Managed Prometheus — requires AWS credentials)
# AMP workspace URL format: https://aps-workspaces.<region>.amazonaws.com/workspaces/<workspace-id>/api/v1/remote_write
K6_PROMETHEUS_RW_SERVER_URL=https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-abc123/api/v1/remote_write \
K6_PROMETHEUS_RW_SIGV4_REGION=us-east-1 \
K6_PROMETHEUS_RW_SIGV4_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE \
K6_PROMETHEUS_RW_SIGV4_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
  k6 run --out experimental-prometheus-rw k6/scripts/load.js

# Full production configuration — native histograms + stale markers + TLS version enforcement
K6_PROMETHEUS_RW_SERVER_URL=https://prometheus.internal/api/v1/write \
K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true \
K6_PROMETHEUS_RW_TREND_STATS="p(50),p(90),p(95),p(99),min,max" \
K6_PROMETHEUS_RW_STALE_MARKERS=true \
K6_PROMETHEUS_RW_TLS_MIN_VERSION="1.3" \
K6_PROMETHEUS_RW_PUSH_INTERVAL=10s \
  k6 run --out experimental-prometheus-rw k6/scripts/load.js
```

> **[community]:** Without `K6_PROMETHEUS_RW_STALE_MARKERS=true`, time-series from a k6 run continue to exist in Prometheus after the test ends. Grafana dashboards show a flat line (last value) rather than going blank. Enable stale markers in long-running dashboard setups so panels correctly show "no data" between test runs.

### Browser Module — `waitForEvent` and Locator Filtering (k6 v1.5+)  [community]

`page.waitForEvent()` waits for a browser event (e.g., `"popup"`, `"download"`, `"request"`) before continuing. Locators now support `hasText` and `hasNotText` filter options for scoping within multi-element matches.

As of k6 v1.6+, you can also subscribe to `requestfailed` and `requestfinished` events via
`page.on()` for persistent monitoring without blocking test flow:

```javascript
// k6/scripts/browser-request-monitoring.js — page.on() for request event monitoring (v1.6+)
import { browser } from "k6/browser";
import { check } from "k6";
import { Counter, Trend } from "k6/metrics";

const failedRequests  = new Counter("browser_failed_requests");
const requestDuration = new Trend("browser_request_duration_ms", true);

export const options = {
  scenarios: {
    ui: { executor: "shared-iterations", vus: 1, iterations: 2,
          options: { browser: { type: "chromium" } } },
  },
  thresholds: {
    browser_failed_requests:    ["count<5"],    // tolerate at most 5 failed sub-requests
    browser_request_duration_ms: ["p(95)<2000"],
    checks: ["rate==1.0"],
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    // Subscribe to all failed requests — fires for broken assets, CORS errors, 4xx/5xx
    page.on("requestfailed", (req) => {
      failedRequests.add(1, { url: req.url().substring(0, 80) });
      console.warn(`Request failed: ${req.url()} — ${req.failure()}`);
    });

    // Subscribe to all completed requests — fires when response received
    page.on("requestfinished", (req) => {
      const resp = req.response();
      if (resp) {
        requestDuration.add(resp.timing().responseEnd - resp.timing().requestStart,
          { resource: new URL(req.url()).pathname }
        );
      }
    });

    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/`);
    await page.waitForLoadState("networkidle");

    const heading = page.getByRole("heading", { level: 1 });
    await heading.waitFor({ state: "visible" });
    check(await heading.textContent(), { "heading visible": (h) => h?.length > 0 });
  } finally {
    await page.close();
  }
}
```

> **[community]:** `page.on('requestfailed')` fires for EVERY sub-resource failure (broken
> images, CDN timeouts, blocked third-party scripts). Without the custom `Counter`, these
> failures are invisible — they don't increment `http_req_failed` (which only tracks k6/http
> requests, not browser sub-resources). Add this listener to any browser test that needs
> complete sub-resource health visibility.

```javascript
// k6/scripts/browser-events.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    ui: {
      executor: "shared-iterations",
      vus: 1,
      iterations: 2,
      options: { browser: { type: "chromium" } },
    },
  },
  thresholds: {
    checks: ["rate==1.0"],
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/`);

    // waitForEvent: capture a popup window before it disappears
    const popupPromise = page.waitForEvent("popup");
    await page.getByRole("button", { name: "Open preview" }).click();
    const popup = await popupPromise;
    await popup.waitForLoadState("domcontentloaded");
    check(popup.url(), { "popup opened": (u) => u.includes("/preview") });
    await popup.close();

    // Locator with hasText filter — scope within a list to one specific item
    const todoList = page.locator(".todo-item");
    const specificItem = todoList.filter({ hasText: "Complete documentation" });
    await specificItem.getByRole("checkbox").check();
    check(await specificItem.locator(".status").textContent(), {
      "item marked done": (t) => t?.includes("done"),
    });

    // hasNotText filter — find items that are NOT completed
    const pendingItems = todoList.filter({ hasNotText: "[done]" });
    const pendingCount = await pendingItems.count();
    check(pendingCount, { "pending items exist": (n) => n >= 0 });
  } finally {
    await page.close();
  }
}
```

### k6 Cloud — Stack is Mandatory in v2.0.0  [community]

In k6 v2.0.0-rc1 and later, the `--stack` option is **mandatory** for all `k6 cloud` commands. The previous behavior of falling back to a default stack is removed. CI pipelines that relied on the default will fail with an error on upgrade.

```bash
# v1.x — stack optional, falls back to default
k6 cloud run k6/scripts/load.js

# v2.0+ — stack REQUIRED (fails without it)
k6 cloud run --stack my-stack k6/scripts/load.js

# Set via environment variable to avoid repeating in every command
export K6_CLOUD_STACK_ID=my-stack
k6 cloud run k6/scripts/load.js
k6 cloud run k6/scripts/soak.js

# GitHub Actions example — pass stack from a repo variable
- name: Run cloud test
  env:
    K6_CLOUD_API_TOKEN: ${{ secrets.K6_CLOUD_API_TOKEN }}
    K6_CLOUD_STACK_ID: ${{ vars.K6_CLOUD_STACK_ID }}
  run: k6 cloud run --no-color k6/scripts/load.js
```

> **[community]:** The `K6_CLOUD_STACK_ID` environment variable is the cleanest migration path. Set it once in your CI environment (GitHub Actions vars, GitLab CI variables, or Jenkins credentials) and all `k6 cloud` commands in all pipelines pick it up automatically — no Jenkinsfile / workflow file changes needed per script.

### k6 Subcommand Extensions — Auto-Resolution (k6 v1.7.0+)  [community]

k6 v1.7.0 introduced automatic resolution for subcommand extensions. Extensions like `k6 x httpbin` no longer require a manual `xk6 build` step if the extension supports the auto-resolution protocol. This simplifies CI setups where teams previously needed custom Docker images.

```bash
# Old workflow: build custom binary, run, clean up
xk6 build --with github.com/szkiba/xk6-httpbin
./k6 run script.js

# New workflow (v1.7.0+): k6 resolves the extension automatically
k6 x httpbin  # discovers and runs the httpbin extension tool directly
```

> **[community]:** Subcommand auto-resolution only works for extensions that register themselves as k6 subcommands (not all xk6 extensions do). Check the extension's documentation for a `k6 x ...` entry point. For load-testing extensions (`k6/x/redis`, `k6/x/kafka`), you still need `xk6 build` to bake them into the binary. Auto-resolution is targeted at utility/tooling extensions, not runtime modules.

---

## OS Tuning for High-VU Tests

### Linux Tuning (CI and bare-metal)

```bash
# Minimum for most load tests (1,000–10,000 VUs)
ulimit -n 65536

# Recommended for high-VU tests (>10,000 VUs)
ulimit -n 250000

# Kernel network tuning — run before k6, persist via /etc/sysctl.conf
sysctl -w net.ipv4.ip_local_port_range="16384 65000"  # expands ephemeral port pool
sysctl -w net.ipv4.tcp_tw_reuse=1                      # reuse TIME_WAIT sockets

# RAM estimate: 1–5 MB per VU depending on script complexity
# 1000 VU test = 1–5 GB RAM needed on the load generator
```

> **[community]:** If k6 itself is CPU-bound (>80% CPU on the load generator), latency metrics are artificially inflated — you are measuring k6 scheduling overhead, not server performance. Monitor load-generator CPU during the test. If it exceeds 80%, either reduce VU count or use `--execution-segment` to split load across multiple machines.

### macOS Tuning (developer machines)  [community]

macOS defaults to 16,384 ephemeral ports and a soft file-descriptor limit of ~256 per process — far too low for high-VU tests. The permanent fix requires creating LaunchDaemon plist files.

```bash
# Temporary session fix (resets on restart)
sudo launchctl limit maxfiles 65536 200000
ulimit -n 65536

# Expand ephemeral port range (adds ~16,384 more ports)
sudo sysctl -w net.inet.ip.portrange.first=32768
```

For a permanent macOS configuration, create `/Library/LaunchDaemons/limit.maxfiles.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key><string>limit.maxfiles</string>
    <key>ProgramArguments</key>
    <array>
      <string>launchctl</string>
      <string>limit</string>
      <string>maxfiles</string>
      <string>64000</string>
      <string>524288</string>
    </array>
    <key>RunAtLoad</key><true/>
  </dict>
</plist>
```

Then reboot. Verification: `launchctl limit maxfiles` should show `64000 524288`.

> **[community]:** On Apple Silicon (M-series) Macs, the SIP disable step may not be required for `launchctl limit` changes. Test first without disabling SIP — many teams run k6 smoke tests on macOS laptops without needing SIP changes.

### `summaryTrendStats` — Custom Percentiles in Summary Output

The default end-of-test summary shows `avg, min, med, max, p(90), p(95)`. Add `p(99)` and `count` for production SLO dashboards:

### Machine-Readable Summary (k6 v1.5+)

The `--new-machine-readable-summary` flag (opt-in in v1.5, stabilized in later releases) emits
structured JSON output optimized for CI system ingestion. Use it with tools that parse k6 output
programmatically without the `handleSummary` hook:

```bash
# Emit structured JSON summary alongside normal stdout
k6 run --new-machine-readable-summary --no-color \
  --out json=results/k6-raw.json \
  k6/scripts/load.js

# Redirect machine-readable summary to file (pipe stdout separately)
k6 run --new-machine-readable-summary --no-color k6/scripts/load.js \
  2>results/k6-summary-structured.json
```

> **[community]:** The `--new-machine-readable-summary` format omits ANSI escape codes and
> formats thresholds as structured JSON objects — better for programmatic threshold inspection
> than parsing the human-readable text output. In k6 v2.0, this becomes the default machine
> output format when `--summary-mode` is used.



```javascript
export const options = {
  summaryTrendStats: ["avg", "min", "med", "max", "p(90)", "p(95)", "p(99)", "p(99.9)", "count"],

  // summaryTimeUnit overrides the time unit for trend stats in the summary
  // Default: "ms" — use "s" for long-duration soak metrics
  summaryTimeUnit: "ms",
};
```

Environment variable alternative (for CI overrides without modifying the script):
```bash
K6_SUMMARY_TREND_STATS="avg,p(95),p(99),max,count" k6 run k6/scripts/load.js
```

> **[community]:** `p(99.9)` and `p(99.99)` are valid percentile expressions in k6 — useful for services with extreme tail latency requirements (financial APIs, real-time trading). These are rarely surfaced in tutorials but fully supported by k6's histogram implementation.

### `--compatibility-mode=base` for Memory Reduction  [community]

k6 defaults to `--compatibility-mode=extended` which includes Babel transform support for broader ES6+ syntax. For high-VU tests (>5,000 VUs), switching to `--compatibility-mode=base` reduces JavaScript VM memory footprint by ~20-30%.

```bash
# Base mode: skips Babel transform — script must be vanilla ES6
k6 run --compatibility-mode=base k6/scripts/load.js

# Or set via env var
K6_COMPATIBILITY_MODE=base k6 run k6/scripts/load.js
```

**Requirements for base mode:**
- No CommonJS (`require()`) imports
- No transpiled TypeScript (use `k6 run script.ts` directly in v0.57+)
- All imports use native ESM `import` syntax
- Arrow functions, const/let, template literals are all fine

> **[community]:** For scripts using only k6 built-ins and standard ES6 syntax (which most production k6 scripts already do), base mode is safe and recommended for high-VU environments. The memory saving can mean the difference between fitting a 10,000 VU test on one 32 GB machine vs. needing two.

---

## v2.0.0 Migration — Additional Details

### k6 v2.0.0-rc1 Additional Breaking Changes

| Change | Details |
|--------|---------|
| `--stack` required for `k6 cloud` | No default stack fallback — must specify explicitly |
| Go module path change | Extensions must update imports: `go.k6.io/k6` → `go.k6.io/k6/v2` |
| `k6 cloud script.js` syntax | Use `k6 cloud run script.js` (the positional syntax is removed) |
| `k6 login` removed | Use `k6 cloud login --token "$TOKEN" --stack "$STACK"` |

```bash
# Migration checklist — cloud commands
grep -r "k6 cloud [^r]" .github/ .gitlab-ci.yml Jenkinsfile  # Find non-"run" cloud commands
grep -r "k6 login" .github/ .gitlab-ci.yml Jenkinsfile       # Find old login commands

# After: correct v2.0 cloud commands
k6 cloud login --token "$K6_CLOUD_API_TOKEN" --stack "$K6_CLOUD_STACK"
k6 cloud run --stack "$K6_CLOUD_STACK" k6/scripts/load.js
k6 cloud upload --stack "$K6_CLOUD_STACK" k6/scripts/load.js
```

### k6 v2.0.0 Final Release — Additional Changes (May 11, 2025)

These items were introduced between v2.0.0-rc1 and the final v2.0.0 release. Update pipelines accordingly.

| Change | Details |
|--------|---------|
| HTTP API server disabled by default | Previously started on `localhost:6565` automatically. Now requires `--address` flag or `K6_ADDRESS` env var to enable. |
| Cloud secrets auto-injected | Cloud secrets are automatically available in `k6 cloud run --local-execution` — no `--secret-source=cloud` flag needed. Opt-out: `--no-cloud-secrets`. |
| `k6 cloud project list` new command | Lists Grafana Cloud k6 projects in table or JSON format. |
| Extension tab-completion | Press TAB after an extension name to auto-provision a custom binary with that extension. |
| easyjson → stdlib `encoding/json` | Extension authors using easyjson-generated methods must update their serialization code. |
| `--summary-mode=legacy` removed | Previously kept for backward compat. Now only `full`, `compact`, `disabled` are valid. |
| Archive metadata `dependencies` field | `k6 archive` now embeds extension dependency info so `k6/x/` imports survive re-execution. |
| Dashboard in core binary | `K6_WEB_DASHBOARD` no longer requires the `xk6-dashboard` extension — it is built into the v2.0 binary. Remove `xk6-dashboard` from custom builds. |

**HTTP API server migration:**
```bash
# v1.x — API server always started on localhost:6565 (no flag needed)
# v2.0 — must explicitly enable the API server
k6 run --address localhost:6565 k6/scripts/load.js

# Or via env var
K6_ADDRESS=localhost:6565 k6 run k6/scripts/load.js

# CI pipelines that relied on the default REST endpoint (e.g., for k6 pause/scale)
# will silently lose the server on upgrade — add --address or remove the REST client code
```

**Cloud secrets auto-injection (v2.0 final):**
```bash
# v2.0 final — cloud secrets are auto-injected when running with --local-execution
k6 cloud run --local-execution k6/scripts/load.js
# All secrets configured in Grafana Cloud k6 are automatically available via secrets.get()
# without any --secret-source flag

# To opt OUT (e.g., when using only local mock secrets for privacy)
k6 cloud run --local-execution --no-cloud-secrets k6/scripts/load.js
```

> **[community]:** The auto-injection of cloud secrets is a convenience for teams that store all secrets in Grafana Cloud. However, if your local execution environment has different secret requirements (e.g., staging vs. production credentials), use `--no-cloud-secrets` and manage secrets explicitly via `--secret-source` or `K6_SECRET_SOURCE` to prevent accidentally using production credentials in staging tests.

**New `k6 cloud project list` command:**
```bash
# List all k6 cloud projects (requires authentication)
k6 cloud project list

# JSON output for CI parsing
k6 cloud project list --json | jq '.projects[].id'
```

### k6 v1.6.0 — Key New APIs (Backport Reference)

If you are on k6 v1.6.x and planning to migrate to v2.0, the following stable APIs were added in
v1.6 and are forward-compatible with v2.0:

| Feature | API / flag | Notes |
|---------|-----------|-------|
| Browser request events | `page.on('requestfailed', fn)` | Subscribe to sub-resource failures |
| Browser request events | `page.on('requestfinished', fn)` | Subscribe to completed requests |
| PBKDF2 key derivation | `crypto.subtle.deriveKey(PBKDF2, ...)` | WebCrypto API — replaces deprecated `k6/crypto` |
| Dependency manifest | `K6_DEPENDENCY_MANIFEST=./manifest.json` | Pin xk6 extension versions |
| Default cloud stack | `K6_CLOUD_STACK_ID` env var | Set once; used by all `k6 cloud` commands |
| MCP server | `k6 x mcp` | AI-assisted script writing (Claude, Cursor, Copilot) |
| iframe interaction | `page.frameLocator('#id')` | Interact with embedded iframes |
| History navigation | `page.goBack()` / `page.goForward()` | Test browser back/forward flows |

> **Note on `k6/crypto` deprecation (v1.6+):** The docs explicitly mark `k6/crypto` as deprecated
> in favor of the standard WebCrypto API (`crypto.subtle`). Existing `k6/crypto` code continues
> to work but will not receive new features. Migrate new cryptographic patterns to `crypto.subtle`.

---

## Readable Streams — Incremental Data Processing (`k6/experimental/streams`)

The `k6/experimental/streams` module implements a subset of the Web Streams API. Unlike
`open()` (which loads the entire file into a string per VU) or `k6/experimental/fs` (which
streams binary chunks), the Streams API lets you define a **pipeline** with a producer
(`start`/`pull` callbacks) and consume it incrementally via `getReader().read()`. This is
ideal for processing very large files line-by-line without ever holding the full content in
memory.

**When to use which file API:**

| API | Best for | Notes |
|-----|---------|-------|
| `open(path)` | Small JSON/CSV fixture (< 5 MB) | Simplest; loads entire file per VU |
| `SharedArray` + `papaparse` | Medium CSV (5–100 MB), VU count any | Shared memory, JS-friendly objects |
| `k6/experimental/csv` | Medium-large CSV (up to ~1 GB) | Go-native parser, ~3–5× faster than papaparse |
| `k6/experimental/fs` + `read(buf)` | Large binary/text files > 100 MB | Chunked random access; async |
| `k6/experimental/streams` | Very large files processed as a pipeline | Line-by-line producer/consumer; subset of W3C Streams spec |

```javascript
// k6/scripts/streams-csv.js — line-by-line CSV processing via Streams API
// Use when: file is too large for SharedArray AND you need object-per-line processing
import { open } from "k6/experimental/fs";
import { ReadableStream } from "k6/experimental/streams";
import http from "k6/http";
import { check } from "k6";

export const options = {
  scenarios: {
    streamed_load: {
      executor: "constant-arrival-rate",
      rate: 20,
      timeUnit: "1s",
      duration: "2m",
      preAllocatedVUs: 10,
      maxVUs: 30,
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<400"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default async function () {
  // Open the CSV file (shares memory across VUs via fs module)
  const file = await open("./data/large-users.csv");

  // Build a readable stream that reads one line at a time
  const lineStream = new ReadableStream({
    // start() fires once when the stream is created — connect to the data source
    async start(controller) {
      // Nothing to do here for a file-based source
    },

    // pull() fires repeatedly until the high-water mark is satisfied or stream closes
    async pull(controller) {
      const buf = new Uint8Array(4096);
      const bytesRead = await file.read(buf);

      if (bytesRead === null) {
        // EOF — signal the consumer that there is no more data
        controller.close();
        return;
      }

      // Decode the chunk and enqueue each complete line
      const text = new TextDecoder().decode(buf.subarray(0, bytesRead));
      const lines = text.split("\n").filter((l) => l.trim().length > 0);
      for (const line of lines) {
        controller.enqueue(line);
      }
    },
  });

  // Consume the stream — read one line at a time
  const reader = lineStream.getReader();
  try {
    let isFirstLine = true;
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      // Skip header row
      if (isFirstLine) { isFirstLine = false; continue; }

      // Parse CSV fields: email, password, role
      const [email, password] = value.split(",");
      if (!email || !password) continue;

      const res = http.post(
        `${BASE}/api/auth/login`,
        JSON.stringify({ email: email.trim(), password: password.trim() }),
        { headers: { "Content-Type": "application/json" } }
      );
      check(res, { "login ok": (r) => r.status === 200 });
    }
  } catch (err) {
    console.error(`Stream read error [VU ${__VU}]:`, err);
  }
}
```

> **[community]:** `k6/experimental/streams` currently implements **only ReadableStream** — WritableStream and TransformStream are not yet supported. The `start()` callback is synchronous in the current implementation (async is planned). For most production use cases, `k6/experimental/csv` with its Go-native parser is faster and simpler; use `k6/experimental/streams` when you need a producer-consumer pipeline with custom data transformation logic embedded in the stream definition.

> **[community]:** The Streams module is experimental and implements a subset of the W3C Streams specification. The API surface is stable enough for use in load tests but breaking changes may occur before it graduates to `k6/streams`. Monitor the k6 changelog for graduation announcements.

---

## k6 Module System

k6 supports four module categories. Understanding each prevents `require is not defined` and resolution errors that don't surface until CI runs.

| Module Type | Import syntax | Notes |
|-------------|--------------|-------|
| **Built-in** | `import http from 'k6/http'` | Core k6 APIs; always available |
| **Local** | `import { helper } from './helpers.js'` | Relative paths; file extension required (no Node.js resolution) |
| **Remote** | `import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js'` | Downloaded at run start; pin version in URL |
| **Extension** | `import redis from 'k6/x/redis'` | Go-based xk6 builds; requires custom binary |

### Using npm packages in k6 (Webpack/esbuild bundling)

k6 does not support Node.js module resolution natively. To use npm packages, bundle with Webpack or esbuild first:

```javascript
// webpack.config.js — bundle npm packages for k6
const path = require('path');

module.exports = {
  mode: 'production',
  entry: {
    load: './k6/scripts/load.js',
  },
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].bundle.js',
    libraryTarget: 'commonjs',
  },
  target: 'web',                    // k6 uses a browser-like global scope, not Node
  externals: /^k6(\/.*)?$/,         // exclude all k6 built-ins from the bundle
};
```

```bash
# Bundle and run
npx webpack --config webpack.config.js
k6 run dist/load.bundle.js
```

**Native TypeScript (k6 v0.57+):** k6 now runs `.ts` files directly via its built-in TypeScript transpiler. No bundler is required unless you need npm packages.

```javascript
// k6/scripts/load.ts — runs directly with k6 run k6/scripts/load.ts
import http from 'k6/http';
import { check } from 'k6';

export const options = { vus: 10, duration: '30s' };

export default function (): void {
  const res = http.get(`${__ENV.BASE_URL}/api/health`);
  check(res, { 'status 200': (r) => r.status === 200 });
}
```

**Remote module pinning:** Always pin remote jslib URLs to a specific version tag. The `latest` alias at jslib.k6.io is not guaranteed stable across k6 upgrades. [community]

```javascript
// Pinned (safe):
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';
// Unpinned (risk of breaking change on next run):
// import { textSummary } from 'https://jslib.k6.io/k6-summary/latest/index.js';
```

---

## k6 Testing Guides Navigation

The Grafana k6 Testing Guides hub (`grafana.com/docs/k6/latest/testing-guides/`) organizes recommended approaches by test goal. Use this as a decision map when authoring new scripts:

| Goal | Test Type | k6 executor | Grafana guide |
|------|-----------|------------|---------------|
| Baseline performance | **Smoke test** | `constant-vus` (1–5 VUs) | [Smoke testing](https://grafana.com/docs/k6/latest/testing-guides/test-types/smoke-testing/) |
| Sustained load | **Load test** | `ramping-vus` or `constant-arrival-rate` | [Load testing](https://grafana.com/docs/k6/latest/testing-guides/test-types/load-testing/) |
| Breaking point | **Stress test** | `ramping-arrival-rate` | [Stress testing](https://grafana.com/docs/k6/latest/testing-guides/test-types/stress-testing/) |
| Sustained stress | **Soak test** | `constant-arrival-rate` (long duration) | [Soak testing](https://grafana.com/docs/k6/latest/testing-guides/test-types/soak-testing/) |
| Sudden spike | **Spike test** | `ramping-vus` (steep ramp) | [Spike testing](https://grafana.com/docs/k6/latest/testing-guides/test-types/spike-testing/) |
| Breakeven throughput | **Breakpoint test** | `ramping-arrival-rate` + `abortOnFail` | [Breakpoint testing](https://grafana.com/docs/k6/latest/testing-guides/test-types/breakpoint-testing/) |
| Real user monitoring | **Synthetic monitoring** | Grafana Cloud Synthetic Monitoring | [Synthetic monitoring](https://grafana.com/docs/k6/latest/testing-guides/synthetic-monitoring/) |

> **[community]** WHY teams reach for load tests when they need smoke tests: the default `k6 run` docs example uses `vus: 10` and `duration: '30s'` — a load test, not a smoke test. New k6 users copy this and report "load tests pass in CI". In reality they're running no assertions, no thresholds, and 10 VUs against a dev server. A proper smoke test uses 1–3 VUs, explicit `check()` calls, and `thresholds: { checks: ['rate>0.99'] }`. Add a smoke test as a pre-requisite job before load tests in CI.

---

## k6 Studio — GUI Script Generation

k6 Studio is an open-source desktop application (macOS, Windows, Linux) for generating k6 test scripts from recorded browser interactions or HAR files. Use it to bootstrap scripts for complex user journeys before tuning them in code.

**Download:** `https://grafana.com/docs/k6-studio/`

### Workflow: Record → Generate → Validate

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. Record                                                           │
│     Browser proxy captures all HTTP traffic as HAR file.            │
│     OR: import an existing HAR exported from DevTools (Network tab   │
│     → right-click → "Save all as HAR with content").                │
├─────────────────────────────────────────────────────────────────────┤
│  2. Inspect                                                          │
│     Review captured requests, filter noise (static assets, analytics│
│     beacons), and flag sensitive values for parameterization.        │
├─────────────────────────────────────────────────────────────────────┤
│  3. Generate                                                         │
│     Apply customization rules:                                       │
│     - Correlation rules: extract dynamic values (tokens, IDs) from   │
│       responses and re-inject into subsequent requests.              │
│     - Custom code rules: inject arbitrary JS into the generated      │
│       script for checks, custom metrics, sleep() calls.             │
│     - Verification rules: add assertion predicates on response body  │
│       fields.                                                        │
├─────────────────────────────────────────────────────────────────────┤
│  4. Validate                                                         │
│     Run the generated script with 1 VU inside Studio's embedded k6  │
│     runner. Inspect request/response pairs in the visual debugger.  │
├─────────────────────────────────────────────────────────────────────┤
│  5. Deploy                                                           │
│     Export the .js script and run it with k6 CLI, or upload         │
│     directly to Grafana Cloud k6 / Synthetic Monitoring.            │
└─────────────────────────────────────────────────────────────────────┘
```

### Browser Recording — Script Generation

k6 Studio can record browser automation tests (page navigation, element interaction, text
assertions) that output browser module scripts rather than HTTP scripts:

```javascript
// Auto-generated browser script from k6 Studio recording
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    ui: {
      executor: "constant-vus",
      vus: 1,
      duration: "30s",
      options: { browser: { type: "chromium" } },
    },
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto("https://myapp.example.com/login");
    await page.getByLabel("Username").fill("testuser@example.com");
    await page.getByLabel("Password").fill(__ENV.TEST_PASSWORD);
    await page.getByRole("button", { name: "Sign in" }).click();
    await page.waitForURL("**/dashboard");
    check(page, {
      "dashboard loaded": () => page.url().includes("/dashboard"),
    });
  } finally {
    await page.close();
  }
}
```

### HAR Import → HTTP Script

For API load tests, import a HAR file recorded from DevTools or a proxy:

```bash
# 1. Record HAR in Chrome DevTools:
#    Open DevTools → Network tab → enable "Preserve log"
#    Perform the user journey
#    Right-click any request → "Save all as HAR with content"

# 2. Open in k6 Studio → File → Import HAR → apply correlation rules

# 3. Generated script skeleton (k6 Studio output):
# import http from 'k6/http';
# import { check, sleep } from 'k6';
# export const options = { vus: 10, duration: '30s' };
# export default function () {
#   // All captured requests + extracted correlation variables
# }

# 4. Run validation inside Studio with 1 VU before scaling
# 5. Export to k6/scripts/load.js and run with full scenario config
```

### Grafana Cloud Integration

k6 Studio can upload scripts directly to Grafana Cloud k6 for cloud execution or to
Synthetic Monitoring for recurring scheduled checks:

```bash
# After generating the script in Studio, deploy via CLI:
# (Studio generates the k6 cloud run command in its UI)

k6 cloud login --token "$K6_CLOUD_API_TOKEN" --stack "$K6_CLOUD_STACK"

# Run in cloud (results visible in Grafana Cloud k6 dashboard)
k6 cloud run --stack "$K6_CLOUD_STACK" k6/scripts/generated-load.js

# Upload as Synthetic Monitoring check:
# (Use Grafana Cloud Synthetic Monitoring UI to import script from file)
```

> **[community]:** k6 Studio is best used to bootstrap scripts, not as the primary editing
> environment. Generated scripts often contain unnecessary correlation variables or missing
> `sleep()` calls. After generating, move the script to your code editor, add proper scenarios,
> thresholds, and parameterization, and remove any auto-extracted correlation variables that are
> actually static constants. Track generated scripts in version control like any hand-authored
> k6 script.

> **[community]:** k6 Studio's browser recorder generates scripts that use `page.getByLabel()`,
> `page.getByRole()`, and `page.waitForURL()` — the same Playwright-style locator API as k6's
> browser module. This means generated browser scripts benefit from all the locator filtering
> and waiting patterns documented in the Browser Module section above. If your app has dynamic
> labels or ARIA changes, review generated locators before running under load.

---

## Additional Community Gotchas (Iteration 27)

### 39. `--stack` is required for ALL `k6 cloud` commands in v2.0 — no default fallback  [community]

**What:** k6 v2.0.0 makes the `--stack` flag mandatory for every `k6 cloud` subcommand —
including `k6 cloud run`, `k6 cloud upload`, and `k6 cloud login`. CI pipelines that relied
on a default stack (or the now-removed `K6_CLOUD_STACK_ID` env var as an implicit default
for bare `k6 cloud run`) fail with a stack-not-specified error after upgrading.

**WHY:** Grafana Cloud k6 supports multi-stack organizations where users may have access to
several regional stacks. Requiring explicit stack specification prevents accidentally running
production load tests against the wrong stack. The `K6_CLOUD_STACK_ID` variable still works
when set in the environment, but it is no longer a hidden implicit default — it must be set
deliberately.

**Fix:** Set `K6_CLOUD_STACK_ID` as a CI environment secret (preferred) or pass `--stack`
explicitly on every `k6 cloud` command. Audit all pipeline steps that call `k6 cloud`:

```bash
# Audit — find all cloud commands missing explicit --stack
grep -rn "k6 cloud" .github/ .gitlab-ci.yml Jenkinsfile Makefile \
  | grep -v "\-\-stack\|K6_CLOUD_STACK"

# Correct pattern — always specify stack via env or flag:
export K6_CLOUD_STACK_ID="your-stack-id"  # set once in CI secrets

k6 cloud login --token "$K6_CLOUD_API_TOKEN" --stack "$K6_CLOUD_STACK_ID"
k6 cloud run --stack "$K6_CLOUD_STACK_ID" k6/scripts/load.js
k6 cloud upload --stack "$K6_CLOUD_STACK_ID" k6/scripts/load.js
```

### 40. `--upload-only` flag removed in v2.0 — CI pipelines fail silently if not audited  [community]

**What:** k6 v2.0 removes the `--upload-only` flag from `k6 cloud`. Pipelines using
`k6 cloud script.js --upload-only` fail at the positional argument level (wrong command
form) AND at the flag level — giving a confusing "unrecognised flag" error that doesn't
mention that both the flag AND the command form were changed.

**WHY:** The v2.0 cloud command restructuring separated upload and run into distinct
subcommands (`k6 cloud upload` and `k6 cloud run`), making `--upload-only` redundant and
ambiguous. The old `k6 cloud script.js` form (positional script argument) was also removed —
the verb (`run` or `upload`) is now required.

**Fix:** Replace in all CI configurations:

```bash
# BEFORE (k6 v1.x)
k6 cloud k6/scripts/load.js --upload-only

# AFTER (k6 v2.0)
k6 cloud upload --stack "$K6_CLOUD_STACK_ID" k6/scripts/load.js

# BEFORE — cloud run (old positional form)
k6 cloud k6/scripts/load.js

# AFTER — cloud run (explicit verb required)
k6 cloud run --stack "$K6_CLOUD_STACK_ID" k6/scripts/load.js

# Migration search — find all affected pipeline steps:
grep -rn "k6 cloud [^lr]" .github/ .gitlab-ci.yml Jenkinsfile
#                  ^^^^ matches anything that isn't "login" or "run"
```

### 41. WebSocket `binaryType` defaults to `"blob"` — binary messages require `"arraybuffer"` to be readable in k6  [community]

**What:** The `k6/websockets` `WebSocket` constructor sets `binaryType` to `"blob"` by
default, matching the W3C standard. However, k6 does not implement the `Blob` type — binary
messages received with `binaryType = "blob"` arrive as a `Blob` object that cannot be decoded
with `TextDecoder` or processed as a `Uint8Array`. Teams testing WebSocket APIs that send
binary frames (Protocol Buffers, MessagePack, binary game state) see opaque `[object Blob]`
values in `onmessage` callbacks and cannot inspect or assert on the content.

**WHY:** The W3C WebSocket spec defaults to `"blob"` for binary frames. k6 implements the
spec interface but its runtime does not include a Blob implementation — the object exists but
has no `arrayBuffer()` method. Setting `binaryType = "arraybuffer"` before opening the
connection routes binary frames through k6's ArrayBuffer implementation, which is fully
supported.

**Fix:** Always set `ws.binaryType = "arraybuffer"` before the connection opens for any
WebSocket endpoint that sends binary frames:

```javascript
// k6/scripts/ws-binary.js — WebSocket with binary (protobuf/MessagePack) messages
import { WebSocket } from "k6/websockets";
import { check } from "k6";

export const options = {
  scenarios: {
    ws_binary: {
      executor: "constant-vus",
      vus: 10,
      duration: "30s",
    },
  },
};

const BASE_WS = (__ENV.API_URL || "ws://localhost:3001");

export default function () {
  const ws = new WebSocket(`${BASE_WS}/ws/stream`);

  // CRITICAL: set BEFORE onopen fires — controls how binary frames are delivered
  ws.binaryType = "arraybuffer";

  ws.onopen = () => {
    // Send a binary message (e.g., a minimal protobuf subscribe frame)
    const subscribe = new Uint8Array([0x0a, 0x06, 0x70, 0x72, 0x69, 0x63, 0x65, 0x73]);
    ws.send(subscribe.buffer);  // send() accepts ArrayBuffer
    setTimeout(() => ws.close(), 5000);
  };

  ws.onmessage = (e) => {
    // e.data is ArrayBuffer — wrap in Uint8Array for processing
    const bytes = new Uint8Array(e.data);
    check(bytes, {
      "received binary payload":   (b) => b.byteLength > 0,
      "payload starts with 0x0a":  (b) => b[0] === 0x0a,  // protobuf field 1 tag
    });

    // Decode as text if the server actually sends JSON strings over binary WS:
    // const text = new TextDecoder().decode(bytes);
    // const msg = JSON.parse(text);
  };

  ws.onerror = (e) => {
    if (e.error() !== "websocket: close sent") {
      console.error(`[VU ${__VU}] WS error:`, e.error());
    }
  };
}
```

### 42. `K6_WEB_DASHBOARD=true` blocks CI process until all browser tabs are closed  [community]

**What:** When `K6_WEB_DASHBOARD=true` is set, k6 does not exit immediately after the test
completes — it keeps the HTTP server running until all browser windows viewing
`http://localhost:5665` are closed. In CI environments (GitHub Actions, GitLab CI, Jenkins)
where no browser is open, the process hangs indefinitely: the CI runner waits for a process
exit that never comes, eventually killing the job after the timeout.

**WHY:** The web dashboard server stays alive to allow post-test investigation of results via
browser. This is useful locally but destructive in CI. The k6 process does not distinguish
between "browser connected" and "no browser ever connected" — it waits the same way in both
cases.

**Fix:** In CI, either disable `K6_WEB_DASHBOARD` entirely, or set the port to `-1` to
prevent the server from starting while still writing the HTML export:

```yaml
# GitHub Actions — two correct patterns:

# Pattern A: disable dashboard entirely in CI
- name: Run k6 load test
  run: k6 run k6/scripts/load.js
  env:
    K6_WEB_DASHBOARD: "false"        # explicit false (or just don't set it)
    K6_WEB_DASHBOARD_EXPORT: ""      # no HTML export needed

# Pattern B: keep HTML report export but disable the live server
- name: Run k6 load test
  run: k6 run k6/scripts/load.js
  env:
    K6_WEB_DASHBOARD: "true"
    K6_WEB_DASHBOARD_PORT: "-1"       # disable HTTP server — no hang
    K6_WEB_DASHBOARD_EXPORT: "results/k6-dashboard-report.html"  # still writes HTML

- name: Upload k6 dashboard report
  uses: actions/upload-artifact@v4
  with:
    name: k6-dashboard-report
    path: results/k6-dashboard-report.html
```

> **[community]:** The `K6_WEB_DASHBOARD_OPEN=false` flag (which prevents auto-launching
> a browser) does NOT prevent the CI hang — the server still stays alive waiting for
> connections. Only `K6_WEB_DASHBOARD_PORT=-1` or `K6_WEB_DASHBOARD=false` prevents the
> process from blocking. This is a common source of "job ran for 6 hours and was cancelled"
> incidents in CI pipelines that copy the web dashboard examples from local documentation.

---

## Browser Module — Locator Composition & Advanced Selection (k6 v1.4+)

### `locator.filter()` — Narrow Results by Text or Sub-locator

`locator.filter()` returns a new Locator targeting only the matching elements from the
parent locator's result set. Use it to select a row from a table, a card from a list, or
any element when you need to combine multiple conditions.

```javascript
// k6/scripts/browser-locator-filter.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    filter_demo: {
      executor: "shared-iterations",
      vus: 1, iterations: 2,
      options: { browser: { type: "chromium" } },
    },
  },
};

const APP = __ENV.APP_URL || "http://localhost:3001";

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${APP}/items`);

    // All items on the page
    const items = page.locator(".item");

    // Narrow to only items containing the text "Active" — returns a new Locator
    const activeItems = items.filter({ hasText: "Active" });

    // Count active items and verify at least one exists
    const count = await activeItems.count();
    check(count, { "at least one active item": (n) => n > 0 });

    // Narrow further: active items that contain a span with class "badge"
    const badgedActive = activeItems.filter({ has: page.locator(".badge") });
    const badgedCount = await badgedActive.count();
    check(badgedCount, { "badged active items ≥ 0": (n) => n >= 0 });

    // Iterate all matching elements — locator.all() returns array of Locator
    const allActive = await activeItems.all();
    for (const item of allActive) {
      const text = await item.textContent();
      check(text, { "item text non-empty": (t) => t && t.length > 0 });
    }
  } finally {
    await page.close();
  }
}
```

### `locator.nth()` / `first()` / `last()` — Positional Selection

When multiple elements match a selector, use positional methods to select a specific one.
Unlike CSS `:nth-child()` (DOM-position-based), k6's `nth()` is index into the result set.

```javascript
// k6/scripts/browser-positional.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    positional: {
      executor: "shared-iterations",
      vus: 1, iterations: 2,
      options: { browser: { type: "chromium" } },
    },
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/products`);

    const rows = page.locator("table tbody tr");

    // First row
    const firstRow = rows.first();
    await firstRow.waitFor({ state: "visible" });
    const firstText = await firstRow.textContent();
    check(firstText, { "first row has content": (t) => !!t });

    // Last row
    const lastRow = rows.last();
    const lastText = await lastRow.textContent();
    check(lastText, { "last row has content": (t) => !!t });

    // Third row (0-indexed → nth(2))
    const thirdRow = rows.nth(2);
    const exists = await thirdRow.count();
    if (exists > 0) {
      const thirdText = await thirdRow.textContent();
      check(thirdText, { "third row has content": (t) => !!t });
    }
  } finally {
    await page.close();
  }
}
```

> **[community]:** `locator.all()` resolves immediately — it returns all elements currently
> in the DOM without waiting. If the page is still rendering, call `waitFor()` on the parent
> locator before calling `.all()` to avoid empty arrays on dynamic content.

---

### `locator.locator()` — Hierarchical Scoping for Precise Element Targeting  [community]

`locator.locator(selector, opts?)` creates a new Locator scoped to children of the parent
locator's matched elements. Use it to reliably target elements inside repeating containers
(tables, lists, cards) without relying on fragile nth-child CSS rules.

```javascript
// k6/scripts/browser-locator-scope.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    scope_demo: {
      executor: "shared-iterations",
      vus: 1, iterations: 2,
      options: { browser: { type: "chromium" } },
    },
  },
};

const APP = __ENV.APP_URL || "http://localhost:3001";

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${APP}/shop`);

    // Scope 1: find the "apple" product card, then its "Add to Cart" button
    // without brittle CSS like "ul.products > li:nth-child(3) > button"
    const appleCard = page.locator('[data-product="apple"]');
    const addBtn    = appleCard.locator('button', { hasText: "Add to Cart" });
    await addBtn.click();
    check(await page.locator('[data-testid="cart-count"]').textContent(), {
      "cart updated": (t) => parseInt(t) > 0,
    });

    // Scope 2: iterate each row in a table and assert per-row structure
    const rows = page.locator("table.order-list tbody tr");
    const allRows = await rows.all();
    for (const row of allRows) {
      // Each row's locator() is automatically scoped to that row's subtree
      const statusCell = row.locator("td.status");
      const status     = await statusCell.textContent();
      check(status, { "row has status": (s) => s !== null && s.length > 0 });

      const actionBtn = row.locator("button.action");
      const btnCount  = await actionBtn.count();
      // Not all rows have action buttons — check is conditional
      if (btnCount > 0) {
        check(await actionBtn.first().isEnabled(), {
          "action button enabled": (enabled) => enabled,
        });
      }
    }

    // Scope 3: filter + locator() combo — find "Active" items and click their edit link
    const activeItems = page.locator(".item").filter({ hasText: "Active" });
    const firstActive = activeItems.first();
    // Scope to the edit link WITHIN the first active item
    const editLink = firstActive.locator('a[href^="/edit/"]');
    const editCount = await editLink.count();
    check(editCount, { "active item has edit link": (n) => n === 1 });
  } finally {
    await page.close();
  }
}
```

> **[community]:** `locator.locator()` is the recommended pattern for tables, lists, and
> any repeating structure. The scoped locator only searches within the parent's matched
> DOM subtree — it will NOT accidentally match elements outside the container even if the
> same selector exists elsewhere on the page. Prefer this over appending CSS descendant
> combinators (`.item .button`) which can match unintended siblings when the DOM changes.

---



### `page.waitForRequest()` — Intercept Outbound HTTP  [community]

`page.waitForRequest(url)` returns a Promise that resolves with the first matching `Request`
object. Use it with `Promise.all()` to trigger an action and then verify the request fired,
without polling or hard-coded timeouts.

```javascript
// k6/scripts/browser-wait-request.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    wait_request: {
      executor: "shared-iterations",
      vus: 1, iterations: 2,
      options: { browser: { type: "chromium" } },
    },
  },
};

const APP = __ENV.APP_URL || "http://localhost:3001";

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${APP}/dashboard`);

    // Wait for the analytics call AND click the button simultaneously
    const [analyticsRequest] = await Promise.all([
      page.waitForRequest(/\/api\/analytics\/event/),  // regex match
      page.getByRole("button", { name: "Load Data" }).click(),
    ]);

    // Verify the request was made with the expected payload
    const url = analyticsRequest.url();
    check(url, { "analytics request fired": (u) => u.includes("/api/analytics/event") });

    // waitForRequest can also match by exact URL string
    const [configRequest] = await Promise.all([
      page.waitForRequest(`${APP}/api/config`),
      page.reload(),
    ]);
    check(configRequest.url(), { "config request on reload": (u) => !!u });
  } finally {
    await page.close();
  }
}
```

### `page.waitForEvent()` — Synchronize with Browser Events  [community]

`page.waitForEvent(event)` blocks execution until the specified browser event fires. Use it
for popup windows, dialog boxes, file downloads, or any DOM event that occurs asynchronously.

```javascript
// k6/scripts/browser-popup.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    popup_test: {
      executor: "shared-iterations",
      vus: 1, iterations: 2,
      options: { browser: { type: "chromium" } },
    },
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/`);

    // Wait for a popup (new window/tab) triggered by a link click
    const [popup] = await Promise.all([
      page.waitForEvent("popup"),                              // resolves with new Page
      page.getByRole("link", { name: "Open in new tab" }).click(),
    ]);

    // Interact with the popup
    await popup.waitForLoadState("domcontentloaded");
    const title = await popup.title();
    check(title, { "popup has title": (t) => t.length > 0 });
    await popup.close();

    // waitForEvent with a predicate (only resolves when predicate returns true)
    // Useful when multiple events fire and you need a specific one
    const [targetPopup] = await Promise.all([
      page.waitForEvent("popup", {
        predicate: (p) => p.url().includes("/help"),
      }),
      page.getByRole("button", { name: "Help" }).click(),
    ]);
    check(targetPopup.url(), { "help popup URL": (u) => u.includes("/help") });
    await targetPopup.close();
  } finally {
    await page.close();
  }
}
```

### `page.on('requestfailed'/'requestfinished')` — Network Monitoring  [community]

Register event listeners for network lifecycle events to detect failed requests, measure
request timing, and validate that key resources loaded successfully.

```javascript
// k6/scripts/browser-network-monitor.js
import { browser } from "k6/browser";
import { check } from "k6";
import { Counter } from "k6/metrics";

const failedRequests = new Counter("browser_failed_requests");
const finishedRequests = new Counter("browser_finished_requests");

export const options = {
  scenarios: {
    network_monitor: {
      executor: "shared-iterations",
      vus: 1, iterations: 3,
      options: { browser: { type: "chromium" } },
    },
  },
  thresholds: {
    "browser_failed_requests": ["count==0"],  // zero tolerance for failed requests
  },
};

export default async function () {
  const page = await browser.newPage();

  // Register BEFORE navigation so early requests are captured
  page.on("requestfailed", (request) => {
    failedRequests.add(1);
    console.error(`[VU ${__VU}] Request FAILED: ${request.url()} — ${request.failure()}`);
  });

  page.on("requestfinished", (request) => {
    finishedRequests.add(1);
    // Optional: log slow requests
    // const timing = request.timing();
  });

  try {
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/`);
    await page.waitForLoadState("networkidle");

    const heading = page.getByRole("heading", { level: 1 });
    const headingText = await heading.textContent();
    check(headingText, { "page loaded": (t) => !!t });
  } finally {
    await page.close();
  }
}
```

### `frameLocator()` — Iframe Interaction Without Context Switching  [community]

`page.frameLocator(selector)` returns a `FrameLocator` that scopes all subsequent
locator calls inside the targeted iframe, without requiring explicit `frame()` switching.

```javascript
// k6/scripts/browser-iframe.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    iframe_test: {
      executor: "shared-iterations",
      vus: 1, iterations: 2,
      options: { browser: { type: "chromium" } },
    },
  },
};

const APP = __ENV.APP_URL || "http://localhost:3001";

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${APP}/checkout`);

    // Interact with elements inside an embedded payment iframe
    // frameLocator() scopes all .locator() calls to the iframe content
    const paymentFrame = page.frameLocator("#payment-iframe");

    await paymentFrame.locator("#card-number").fill("4242424242424242");
    await paymentFrame.locator("#card-expiry").fill("12/26");
    await paymentFrame.locator("#card-cvc").fill("123");

    // Nested iframes: chain frameLocator() calls
    // const nestedFrame = page.frameLocator("#outer-frame").frameLocator("#inner-frame");

    // Back on the main page — regular locators work normally
    const submitBtn = page.getByRole("button", { name: "Pay Now" });
    await submitBtn.waitFor({ state: "visible" });
    check(await submitBtn.isEnabled(), { "pay button enabled": Boolean });
  } finally {
    await page.close();
  }
}
```

> **[community]:** `frameLocator()` is a lazy reference — it does not throw if the iframe
> hasn't loaded yet; the error only surfaces when you call an action (`.fill()`, `.click()`).
> Add `await page.waitForSelector('#payment-iframe')` before using `frameLocator()` if the
> iframe is dynamically injected.

### `page.goBack()` / `page.goForward()` — Browser History Navigation  [community]

Navigate browser history in browser module tests — essential for testing multi-step flows
that use the back button, SPA navigation stacks, and history-based auth flows.

```javascript
// k6/scripts/browser-history.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    history_nav: {
      executor: "shared-iterations",
      vus: 1, iterations: 2,
      options: { browser: { type: "chromium" } },
    },
  },
};

const APP = __ENV.APP_URL || "http://localhost:3001";

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${APP}/`);
    const homeTitle = await page.title();

    await page.goto(`${APP}/products`);
    check(page.url(), { "on products page": (u) => u.includes("/products") });

    // Go back to home — equivalent to browser Back button
    await page.goBack();
    check(page.url(), { "back to home": (u) => !u.includes("/products") });

    const backTitle = await page.title();
    check(backTitle, { "title restored after back": (t) => t === homeTitle });

    // Go forward to products
    await page.goForward();
    check(page.url(), { "forward to products": (u) => u.includes("/products") });
  } finally {
    await page.close();
  }
}
```

### `locator.evaluate()` / `locator.evaluateHandle()` — In-Page JS Execution  [community]

Execute JavaScript in the browser context with direct access to the matched DOM element.
`evaluate()` returns a serializable value; `evaluateHandle()` returns a JSHandle for
further chaining.

```javascript
// k6/scripts/browser-evaluate.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    evaluate_test: {
      executor: "shared-iterations",
      vus: 1, iterations: 2,
      options: { browser: { type: "chromium" } },
    },
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/products`);

    // evaluate() — get computed CSS property (not available via textContent)
    const priceColor = await page.locator(".price").first().evaluate(
      (el) => window.getComputedStyle(el).color
    );
    check(priceColor, { "price has color": (c) => c && c.length > 0 });

    // evaluate() with args — pass data from k6 to the browser context
    const isHighlighted = await page.locator(".item").first().evaluate(
      (el, threshold) => parseInt(el.dataset.score) > threshold,
      85  // threshold arg passed to the browser function
    );
    check(isHighlighted, { "high-score item highlighted": (v) => typeof v === "boolean" });

    // evaluateHandle() — get a JSHandle for an object too complex to serialize
    const selectHandle = await page.locator("select#sort").evaluateHandle(
      (el) => el  // returns a JSHandle wrapping the select element
    );
    // Can pass the handle back to evaluate() for further processing
    const selectedValue = await selectHandle.evaluate((el) => el.value);
    check(selectedValue, { "select has a value": (v) => v !== undefined });
  } finally {
    await page.close();
  }
}
```

> **[community]:** `evaluate()` serializes the return value using `JSON.stringify` internally.
> Functions, DOM nodes, and circular references cannot be returned — use `evaluateHandle()`
> for those cases. The function runs in the browser context, not in k6: `__ENV` variables
> and k6 imports are NOT accessible inside the `evaluate()` callback.

---

## Browser Module — `locator.pressSequentially()` (k6 v1.5+)  [community]

`locator.pressSequentially(text, options)` types characters one by one, firing individual
`keydown`, `keypress`, `keyup`, and `input` events per character. Use it when the target
input field has a `keyup`-driven listener (e.g., autocomplete, real-time validation) that
requires individual keystroke events rather than the bulk-paste behavior of `.fill()`.

```javascript
// k6/scripts/browser-sequential-type.js
import { browser } from "k6/browser";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    autocomplete_test: {
      executor: "shared-iterations",
      vus: 1, iterations: 3,
      options: { browser: { type: "chromium" } },
    },
  },
};

const APP = __ENV.APP_URL || "http://localhost:3001";

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${APP}/search`);

    const searchInput = page.getByPlaceholder("Search products...");
    await searchInput.waitFor({ state: "visible" });

    // pressSequentially fires one keystroke event per character — triggers autocomplete
    await searchInput.pressSequentially("widget", {
      delay: 100,  // ms between keystrokes — simulates human typing speed
    });

    // Wait for autocomplete dropdown to appear
    const dropdown = page.locator(".autocomplete-results");
    await dropdown.waitFor({ state: "visible" });

    const suggestions = await dropdown.locator(".suggestion").all();
    check(suggestions.length, { "autocomplete has suggestions": (n) => n > 0 });

    // Click the first suggestion
    if (suggestions.length > 0) {
      await suggestions[0].click();
    }

    // Verify search was submitted
    await page.waitForLoadState("networkidle");
    check(page.url(), { "search results loaded": (u) => u.includes("search") });
  } finally {
    await page.close();
  }
}
```

> **[community]:** The `delay` option in `pressSequentially()` dramatically increases wall
> clock time for browser scenarios. Keep delay low (50–150ms) for correctness, not for
> human-speed simulation — k6 browser tests measure performance, not UX feel.
> For inputs without keystroke listeners, use `.fill()` which is 50–100× faster.

---

## CLI — `k6 deps` Dependency Analysis (k6 v1.6+)  [community]

`k6 deps` analyzes a script's imports and lists all required extensions. Use it in CI
to verify that a custom binary includes every extension needed before deploying a test.

```bash
# Analyze a script's dependencies
k6 deps k6/scripts/load.js

# Example output:
# Dependency   Version     Source
# k6/x/redis   >=0.2.0     pragma: use k6 >= "0.2.0"
# k6/x/sql     *           no pragma

# JSON output for CI parsing — check if extensions are satisfied
k6 deps --json k6/scripts/load.js | jq '.dependencies[] | select(.satisfied == false)'

# Analyze a pre-built archive
k6 deps archive.tar

# Set default version constraints via environment variable
export K6_DEPENDENCIES_MANIFEST=./k6-extensions.json
k6 run k6/scripts/load.js  # applies manifest constraints automatically
```

```json
// k6-extensions.json — dependency manifest format
{
  "k6/x/redis": ">=0.2.0",
  "k6/x/sql":   ">=1.0.0"
}
```

> **[community]:** Use `k6 deps` in CI as a pre-flight check before running tests with
> custom k6 binaries. A missing extension causes a cryptic "SyntaxError: Unknown import"
> rather than a clear "extension not found" message. The deps command surfaces this
> before wasting a test run.

---

## CLI — Machine-Readable Summary Output (k6 v1.5+)  [community]

The `--new-machine-readable-summary` flag (k6 v1.5+) emits the test summary as a
structured JSON document designed for programmatic consumption in CI/CD pipelines.
Unlike the human-readable text summary, the machine-readable format is stable across
k6 versions and includes threshold pass/fail status per metric.

```bash
# Write machine-readable JSON summary alongside the human-readable text summary
k6 run --new-machine-readable-summary=results/machine-summary.json k6/scripts/load.js

# CI pipeline usage: fail the step if any threshold failed
k6 run --new-machine-readable-summary=results/summary.json k6/scripts/load.js
THRESHOLDS_PASSED=$(jq '.thresholds | map(.ok) | all' results/summary.json)
if [ "$THRESHOLDS_PASSED" != "true" ]; then
  echo "k6 thresholds failed — see results/summary.json"
  exit 1
fi
```

```javascript
// Combining with handleSummary — both can coexist
// Machine-readable summary is written BEFORE handleSummary is called
export function handleSummary(data) {
  // data.metrics contains the same info as the machine-readable JSON
  // Use handleSummary for custom formats; use --new-machine-readable-summary for CI tooling
  return {
    stdout: `Tests complete. Threshold failures: ${
      Object.values(data.metrics)
        .filter((m) => m.thresholds && Object.values(m.thresholds).some((t) => !t.ok))
        .length
    }`,
  };
}
```

> **[community]:** The `--new-machine-readable-summary` flag was introduced to replace the
> older `--summary-export` (deprecated) with a richer, threshold-aware format. Unlike
> `--summary-export`, which outputs a flat metrics JSON, the new format includes nested
> threshold results with per-threshold `ok` booleans — making CI integration simpler
> without custom `handleSummary` logic.

---

## `page.unroute()` / `page.unrouteAll()` — Dynamic Route Management (k6 v1.4+)  [community]

Remove previously registered route handlers dynamically — useful for multi-phase browser
tests where you need different stub behavior in each phase.

```javascript
// k6/scripts/browser-route-lifecycle.js
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    route_lifecycle: {
      executor: "shared-iterations",
      vus: 1, iterations: 2,
      options: { browser: { type: "chromium" } },
    },
  },
};

const APP = __ENV.APP_URL || "http://localhost:3001";

export default async function () {
  const page = await browser.newPage();
  try {
    // Phase 1: stub the feature-flag API to return "enabled"
    const featureFlagHandler = (route) =>
      route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({ featureX: true }),
      });
    await page.route("**/api/feature-flags", featureFlagHandler);

    await page.goto(`${APP}/`);
    const featureXVisible = await page.locator("[data-feature='featureX']").count();
    check(featureXVisible, { "featureX shown when enabled": (n) => n > 0 });

    // Phase 2: remove the stub — real API now responds
    await page.unroute("**/api/feature-flags", featureFlagHandler);

    await page.reload();
    // Now the real feature-flag API responds — behavior depends on actual state

    // Remove ALL routes at once (for test cleanup)
    await page.unrouteAll({ behavior: "ignoreErrors" });  // ignoreErrors: skip if no routes match
  } finally {
    await page.close();
  }
}
```

> **[community]:** `unrouteAll()` accepts `{ behavior: "ignoreErrors" | "wait" }`. The
> `"wait"` option blocks until all in-flight route handlers for those patterns complete.
> Always call `unrouteAll()` in the `finally` block of long-running browser tests to
> prevent route handlers from leaking into subsequent iterations.

---

## mcp-k6 — AI-Assisted Load Test Authoring (k6 v1.6+)  [community]

`mcp-k6` is an experimental Model Context Protocol server that integrates k6 with AI
coding assistants (Cursor, VS Code with GitHub Copilot, Claude Code). Key capabilities:
- **Script validation**: validate a k6 script without running it
- **Local test execution**: run scripts directly from the AI assistant
- **Playwright-to-k6 conversion**: convert existing Playwright browser tests into k6 browser scripts

```bash
# Install mcp-k6 via Homebrew (macOS/Linux)
brew install grafana/k6/mcp-k6

# Or via Docker
docker pull grafana/mcp-k6

# Add to Cursor .cursorrules or VS Code MCP config:
# {
#   "mcpServers": {
#     "k6": {
#       "command": "mcp-k6",
#       "args": []
#     }
#   }
# }

# Conversion: Playwright test → k6 browser script
# In your AI assistant: "Convert this Playwright test to k6 browser script using mcp-k6"
# mcp-k6 reads the Playwright file and outputs an equivalent k6 browser test
```

**What mcp-k6 supports:**
- `validate` — syntax and semantic validation of a k6 script
- `run` — execute a k6 script with optional parameters
- `convert` — convert Playwright browser test to k6 format
- Works with local k6 binary or Docker

> **[community]:** mcp-k6 is marked experimental as of k6 v1.6. The Playwright-to-k6
> conversion handles the most common Playwright patterns (goto, click, fill, check,
> getByRole, getByText) but does NOT convert Playwright-specific APIs that have no k6
> equivalent (e.g., `page.evaluate()` closures with Node.js imports, `page.pdf()`).
> Review generated scripts before committing them.

---

## OpenTelemetry Output — Stable Since k6 v1.4  [community]

The OpenTelemetry output graduated from experimental to stable in k6 v1.4.0. Use
`--out opentelemetry` (not `--out experimental-opentelemetry`) to send k6 metrics to
any OTel-compatible backend (Tempo, Jaeger, Grafana Cloud).

```bash
# k6 v1.4+: stable OpenTelemetry output
k6 run \
  --out opentelemetry \
  k6/scripts/load.js

# With OTel collector endpoint and TLS
k6 run \
  --out opentelemetry \
  -e K6_OTEL_EXPORTER_PROTOCOL=grpc \
  -e K6_OTEL_GRPC_EXPORTER_ENDPOINT=otelcol:4317 \
  -e K6_OTEL_TLS_INSECURE_SKIP_VERIFY=true \
  k6/scripts/load.js
```

**Breaking change from k6 v1.4:** Rate metrics now export as a **single counter with
`is_ratio=true` label** instead of two separate metrics (`total` and `non-zero`). If your
dashboards were built on the old `*_total` / `*_non_zero` metric names, update them.

```bash
# Old dashboard query (pre-v1.4):
# k6_http_req_failed_non_zero / k6_http_req_failed_total

# New dashboard query (v1.4+):
# k6_http_req_failed{is_ratio="true"}
```

> **[community]:** The `K6_OTEL_EXPORTER_TYPE` env var was renamed to
> `K6_OTEL_EXPORTER_PROTOCOL` in k6 v1.4 — CI pipelines using the old name will silently
> use the default exporter (HTTP). Always run `k6 run --help` after upgrading to check
> for renamed flags. The `SingleCounterForRate` option was also removed; there is no
> per-metric opt-out for the new rate format.

---

## WebCrypto — PBKDF2 Key Derivation (k6 v1.6+)  [community]

k6 v1.6.0 added PBKDF2 support to the `k6/experimental/webcrypto` module. Use it to
test authentication systems that require client-side key derivation (e.g., zero-knowledge
auth, encrypted local storage initialization).

```javascript
// k6/scripts/pbkdf2-auth.js — test systems that use PBKDF2-derived keys
import { browser } from "k6/browser";
import { crypto } from "k6/experimental/webcrypto";
import { check } from "k6";
import http from "k6/http";

export const options = {
  scenarios: {
    pbkdf2_test: {
      executor: "constant-vus",
      vus: 5,
      duration: "1m",
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";
const SALT  = new TextEncoder().encode("fixed-test-salt-32bytes-padding!!");

/**
 * Derive an AES-GCM key from a password using PBKDF2.
 * Returns the derived key as a hex string.
 */
async function deriveKey(password) {
  const enc = new TextEncoder();

  // 1. Import the raw password as a PBKDF2 key
  const baseKey = await crypto.subtle.importKey(
    "raw",
    enc.encode(password),
    { name: "PBKDF2" },
    false,   // non-extractable
    ["deriveBits"]
  );

  // 2. Derive 256 bits using PBKDF2-SHA256
  const derivedBits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      hash: "SHA-256",
      salt: SALT,
      iterations: 100_000,  // match server-side iterations
    },
    baseKey,
    256   // output bit length
  );

  // 3. Convert to hex for transmission
  return Array.from(new Uint8Array(derivedBits))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export default async function () {
  const password = `test-password-${__VU}`;
  const derivedKey = await deriveKey(password);

  const res = http.post(
    `${BASE}/api/auth/zkp-login`,
    JSON.stringify({ userId: `user-${__VU}`, derivedKey }),
    { headers: { "Content-Type": "application/json" } }
  );

  check(res, {
    "zkp login ok":      (r) => r.status === 200,
    "has session token": (r) => r.json("token") !== undefined,
  });
}
```

> **[community]:** PBKDF2 in k6 is CPU-intensive — 100,000 iterations per call at 50 VUs
> can saturate a single CPU core. For load test scripts where authentication is not the
> focus, derive the key once in `setup()` and share it via the return value, rather than
> re-deriving per iteration. Consider reducing iterations to 10,000 for load test purposes
> (flag this divergence from production settings in a comment).

---

## Additional Community Gotchas (Iteration 28)

### 43. `require()` removed in k6 v1.4 — CommonJS imports silently fail  [community]

**What:** k6 v1.4.0 removed support for CommonJS `require()` calls. Scripts using
`const http = require("k6/http")` will fail with a module resolution error. This
affects teams that copied k6 examples from older blog posts or Stack Overflow answers.

**WHY:** k6 adopted native ESM (`import`/`export`) as its module system. CommonJS was
kept temporarily for backward compatibility but was removed to simplify the runtime
and align with the ES module specification. The removal was announced in v1.3 release notes.

**Fix:**
```javascript
// BEFORE (fails in k6 v1.4+)
const http = require("k6/http");
const { check, sleep } = require("k6");

// AFTER (correct for all k6 versions)
import http from "k6/http";
import { check, sleep } from "k6";
```

```bash
# Audit all k6 scripts for require() calls before upgrading
grep -r "require(" k6/ --include="*.js" --include="*.ts"
```

### 44. Chromium process cleanup — browser VU leak causes test agent memory exhaustion  [community]

**What:** If a browser VU throws an unhandled exception (e.g., a `check()` call crashes
before `page.close()`), the underlying Chromium process may not be properly terminated.
Over many iterations or a long test run, zombie Chromium processes accumulate until the
CI runner runs out of memory (OOM) or hits the process limit.

**WHY:** k6 relies on the browser context's `finally` block to issue the close signal to
Chromium. If the k6 VU goroutine panics before `finally` runs, the child process orphan
is not cleaned up. This is a known issue (GitHub #4317).

**Fix:** Always wrap browser VU code in `try/finally` — the `finally` block runs even
on panic or unhandled error:

```javascript
export default async function () {
  const page = await browser.newPage();
  try {
    // ALL browser interactions here
    await page.goto(URL);
    // ...
  } finally {
    // CRITICAL: this must always run — even if an assertion throws
    await page.close();
  }
}
```

```bash
# CI cleanup: kill all orphan Chromium processes after each k6 run
# (add to your GitHub Actions workflow as a post-step)
- name: Cleanup orphan Chromium
  if: always()
  run: pkill -f chromium || true
```

### 45. `--vus` flag ignored when `scenarios` are defined — VU count silently wrong  [community]

**What:** The `--vus` CLI flag has no effect when the script defines a `scenarios` object.
Passing `k6 run --vus 50 script.js` does not increase the VU count to 50 for scenario-
based tests — it is silently ignored.

**WHY:** The `--vus` flag only applies to the legacy top-level `vus`/`duration` configuration.
When `scenarios` is present, VU counts are specified per-scenario (`vus`, `preAllocatedVUs`,
`maxVUs`) inside the `scenarios` object. The CLI flag has no way to override per-scenario VU
counts.

**Fix:**
```javascript
// In the script: use per-scenario VU configuration
export const options = {
  scenarios: {
    my_scenario: {
      executor: "constant-vus",
      vus: 50,         // set VU count here — CLI --vus flag is ignored
      duration: "2m",
    },
  },
};

// Or use --env to parameterize VU counts:
export const options = {
  scenarios: {
    my_scenario: {
      executor: "constant-vus",
      vus: parseInt(__ENV.VUS || "10"),  // override via -e VUS=50
      duration: "2m",
    },
  },
};
```

```bash
# Override VU count at the command line via -e flag
k6 run -e VUS=50 k6/scripts/load.js
```

### 46. StatsD / CloudWatch Metrics output silently drops data if tags contain special chars  [community]

**What:** When sending k6 metrics to StatsD (and by extension AWS CloudWatch via the
CloudWatch StatsD agent), metric names or tag values containing characters illegal in
StatsD protocol (`.`, `=`, `:`, `|`, `@`) are silently dropped — no error, no warning,
just missing metrics in your dashboard.

**WHY:** The k6 StatsD output serializes tags as label=value pairs separated by `,`.
Special characters in those values break the protocol framing; the StatsD server silently
discards the malformed packet.

**Fix:**
```javascript
// AVOID: URL paths or query strings as tag values
const res = http.get(url, { tags: { endpoint: "/api/users?role=admin" } });

// PREFER: sanitized, short tag values
const res = http.get(url, { tags: { endpoint: "users-admin" } });

// PREFER: name-based URL grouping to avoid dynamic IDs
const res = http.get(url, { tags: { name: "GET /api/users/:id" } });
```

```bash
# Validate tag values before running in production
# Tag values should match: [a-zA-Z0-9_-]
```

### 47. WebSocket `bufferedAmount` not tracked for TypedArrays — binary throughput metrics are wrong  [community]

**What:** When sending binary data (e.g., `Uint8Array`, `Float32Array`) via
`ws.send(typedArray.buffer)`, k6's internal `ws_send_bytes` metric does not count the
bytes correctly — `bufferedAmount` tracks only `string` sends, not `ArrayBuffer` or
TypedArray sends (GitHub #5715).

**WHY:** The `k6/websockets` module's byte tracking was implemented for string messages
(the common case) and was not updated when binary send support was added. The fix is
planned but not yet released.

**Workaround:** Track binary send throughput manually using a custom Counter metric:

```javascript
import { WebSocket } from "k6/websockets";
import { Counter } from "k6/metrics";

const binarySentBytes = new Counter("ws_binary_sent_bytes");

export default function () {
  const ws = new WebSocket(`${BASE_WS}/ws/stream`);

  ws.onopen = () => {
    const payload = new Uint8Array(512);   // 512-byte binary payload
    ws.send(payload.buffer);
    binarySentBytes.add(payload.byteLength);  // track manually
    setTimeout(() => ws.close(), 3000);
  };
}
```

> **[community]:** This gotcha means that `ws_send_bytes` in k6's built-in metrics is
> unreliable for WebSocket tests with mixed text+binary traffic. Use custom Counters for
> binary payload tracking until the upstream bug is fixed.

---

## WebSocket Close Code and Reason Tracking (k6 v1.5+)  [community]

k6 v1.5.0 added **close code and reason string** capture to the WebSocket `onclose` event.
This allows tests to distinguish clean closes (code 1000) from server-driven closes
(code 1001/1006/4xxx) and validate that reconnect logic handles specific close semantics.

```javascript
// k6/scripts/ws-close-code.js — assert clean close vs server-initiated close
import { WebSocket } from "k6/websockets";
import { check } from "k6";
import { Counter } from "k6/metrics";

const serverClosedAbnormally = new Counter("ws_abnormal_close");

export const options = {
  scenarios: {
    ws_test: {
      executor: "constant-vus",
      vus: 10,
      duration: "30s",
    },
  },
  thresholds: {
    "ws_abnormal_close": ["count==0"],  // zero abnormal closes expected
  },
};

const BASE_WS = (__ENV.WS_URL || "ws://localhost:3001");

export default function () {
  const ws = new WebSocket(`${BASE_WS}/ws/session`);

  ws.onopen = () => {
    ws.send(JSON.stringify({ type: "ping" }));
    setTimeout(() => ws.close(1000, "normal closure"), 5000);
  };

  ws.onmessage = (e) => {
    const msg = JSON.parse(e.data);
    check(msg, { "pong received": (m) => m.type === "pong" });
  };

  // k6 v1.5+: onclose receives an event object with .code and .reason
  ws.onclose = (event) => {
    if (event.code !== 1000) {
      console.warn(`Unexpected WS close: code=${event.code} reason="${event.reason}"`);
      serverClosedAbnormally.add(1);
    }
  };

  ws.onerror = (e) => {
    if (e.error() !== "websocket: close sent") {
      console.error("WS error:", e.error());
    }
  };
}
```

> **[community]:** Before k6 v1.5, `onclose` received the raw `CloseEvent` but `.code` and
> `.reason` were not surfaced — you got `undefined` for both. In v1.5+ they are populated
> properly. If your test runs on older k6 versions, guard with `typeof event.code !== 'undefined'`.
> **Close code reference:**
> - `1000` — Normal closure
> - `1001` — Going away (server restart)
> - `1006` — Abnormal closure (no close frame sent — e.g. connection dropped)
> - `4000–4999` — Application-defined codes (e.g. 4001 = auth expired)

---

## CSV Parsing — `asObjects` Option and `skipFirstLine` (k6/experimental/csv)  [community]

The `k6/experimental/csv` module has two convenience options that significantly simplify
test data access when your CSV has a header row:

| Option | Default | Effect |
|--------|---------|--------|
| `asObjects: true` | `false` | Returns each row as `{ col_name: value }` instead of a string array; assumes first row is headers |
| `skipFirstLine: true` | `false` | Skips the header row but returns rows as string arrays (not objects) |
| `delimiter` | `","` | Field delimiter character |

**When to use which:**

- `asObjects: true` — cleanest for CSV files with descriptive headers; auto-skips header row
- `skipFirstLine: true` + array access — slightly faster, useful when headers don't need to be property names
- Neither — raw mode; every row including the header becomes an array element

```javascript
// k6/scripts/csv-as-objects.js — header-row CSV using asObjects
import { open } from "k6/experimental/fs";
import { parse } from "k6/experimental/csv";
import http from "k6/http";
import { check } from "k6";
import exec from "k6/execution";

export const options = { iterations: 20 };

// CSV file: email,password,role
// alice@test.com,pw1,admin
// bob@test.com,pw2,user
let users;

export async function setup() {
  const file = await open("./data/users.csv");
  // asObjects: true → rows become { email, password, role }
  // header row is automatically skipped
  users = await parse(file, { asObjects: true });
  return { users };
}

export default async function (data) {
  const user = data.users[exec.scenario.iterationInTest % data.users.length];

  const res = http.post(
    `${__ENV.API_URL}/api/auth/login`,
    JSON.stringify({ email: user.email, password: user.password }),
    { headers: { "Content-Type": "application/json" } }
  );
  check(res, {
    "login ok":         (r) => r.status === 200,
    "role in response": (r) => r.json("role") === user.role,
  });
}
```

```javascript
// k6/scripts/csv-streaming-objects.js — streaming large CSV with asObjects
import { open } from "k6/experimental/fs";
import { Parser } from "k6/experimental/csv";
import http from "k6/http";
import { check } from "k6";

export const options = { vus: 5, iterations: 50 };

export default async function () {
  // Parser is re-created per VU iteration — no shared state across VUs
  const file = await open("./data/products.csv");
  // skipFirstLine: true → discard header row, get arrays (faster than asObjects)
  const parser = new Parser(file, { skipFirstLine: true, delimiter: ";" });

  const { done, value } = await parser.next();  // read one row per VU iteration
  if (done) {
    console.warn("CSV exhausted — increase iterations limit or data file size");
    return;
  }

  const [productId, category, price] = value;  // string array
  const res = http.get(
    `${__ENV.API_URL}/api/products/${productId}`,
    { tags: { category } }
  );
  check(res, {
    "product found": (r) => r.status === 200,
    "price matches":  (r) => r.json("price") === parseFloat(price),
  });
}
```

> **[community]:** `csv.parse()` with `asObjects: true` **loads the entire CSV into memory at
> init time** (like `SharedArray`). For files over ~50 MB, prefer `new csv.Parser()` with
> `skipFirstLine: true` for streaming access. Also note that `asObjects` uses the first row's
> header values verbatim as JavaScript property names — headers with spaces or special chars
> (e.g. `"user email"`) become awkward keys (`user["user email"]`); sanitize your CSV headers.

---

## Environment Variable Precedence: `-e` vs `K6_` Prefix  [community]

There are two distinct ways to pass values to k6. Confusing them silently breaks test config.

| Method | Controls | Example |
|--------|----------|---------|
| `-e VAR=value` | Script access only via `__ENV` | `-e API_URL=https://staging.api.io` |
| `K6_VAR=value` (system env) | k6 option **and** `__ENV` | `K6_VUS=100 k6 run ...` |
| `--vus 100` (CLI flag) | k6 option only | Takes highest precedence |

**The trap:** `-e K6_ITERATIONS=50` does NOT set `options.iterations`. The `-e` flag
passes variables only to the script; it does not configure k6 options. Only the
`K6_` prefix in the *system environment* (or CLI flags) configures k6.

```javascript
// k6/scripts/env-config.js — correct patterns for environment-driven config
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  // PATTERN A: read options from __ENV (script-layer)
  // Set with: k6 run -e TARGET_VUS=50 -e TARGET_DURATION=2m script.js
  // (options are resolved at parse time, __ENV is available)
  vus: parseInt(__ENV.TARGET_VUS || "10"),
  duration: __ENV.TARGET_DURATION || "1m",
  thresholds: {
    http_req_duration: [`p(95)<${parseInt(__ENV.SLA_MS || "500")}`],
  },
};

export default function () {
  // PATTERN B: use __ENV for runtime values (base URL, secrets, flags)
  const base = __ENV.API_URL || "http://localhost:3001";

  const res = http.get(`${base}/api/health`);
  check(res, { "healthy": (r) => r.status === 200 });
  sleep(1);
}
```

```bash
# CORRECT — K6_ prefix in system env configures k6 options:
K6_VUS=100 K6_DURATION=5m k6 run script.js

# CORRECT — CLI flags take highest priority:
k6 run --vus 100 --duration 5m script.js

# INCORRECT — -e flag does NOT configure k6 options:
k6 run -e K6_VUS=100 script.js    # K6_VUS silently ignored as option config

# CORRECT — pass script-readable env via -e, configure k6 via K6_:
K6_VUS=100 k6 run -e API_URL=https://staging.api.io script.js
```

> **[community]:** The most common CI mistake is piping Vault/AWS Secrets Manager values via
> `-e` and then wondering why `k6` ignores the VU or iteration counts. The fix is always:
> *script-visible* vars → `-e`; *k6 option* vars → system environment `K6_` prefix or CLI flag.
> Note that `K6_` system env vars also appear in `__ENV`, so scripts can read them too — unlike
> CLI flags which are opaque to the script.

---

## Extension Ecosystem — Production-Ready xk6 Packages  [community]

k6's extension system enables protocol and data generation integrations beyond the built-ins.
These four extensions are widely used in production test suites.

### xk6-faker — Synthetic Test Data Generation

`xk6-faker` wraps the Faker.js API for generating realistic test data (names, emails, addresses,
UUIDs, credit cards) directly inside k6 scripts — no external data file needed.

```javascript
// k6/scripts/faker-data.js — requires xk6 build --with github.com/szkiba/xk6-faker
import { Faker } from "k6/x/faker";
import http from "k6/http";
import { check } from "k6";

const faker = new Faker(12345);   // seed for reproducibility (omit for random)

export const options = {
  scenarios: {
    registration: {
      executor: "constant-arrival-rate",
      rate: 20, timeUnit: "1s", duration: "2m",
      preAllocatedVUs: 10, maxVUs: 30,
    },
  },
  thresholds: { "http_req_duration": ["p(95)<800"] },
};

export default function () {
  const payload = {
    name:     faker.person.firstName() + " " + faker.person.lastName(),
    email:    faker.internet.email(),
    password: faker.internet.password(),
    address: {
      street: faker.address.streetAddress(),
      city:   faker.address.city(),
      zip:    faker.address.zipCode(),
    },
  };

  const res = http.post(
    `${__ENV.API_URL}/api/users/register`,
    JSON.stringify(payload),
    { headers: { "Content-Type": "application/json" } }
  );
  check(res, { "registered": (r) => r.status === 201 });
}
```

> **[community]:** xk6-faker calls are fast but not free — at >10,000 RPS the Faker
> RNG overhead is measurable. Cache generated values in a `SharedArray` during `setup()`
> if you need max throughput. Seeding with a fixed integer makes test data reproducible
> for debugging; omit the seed in production load tests for full variance.

### xk6-sql — Database Validation Inside Load Tests

`xk6-sql` lets k6 VUs execute SQL queries to validate database state during or after load
tests — useful for verifying that order creation under load doesn't produce duplicate rows.

```javascript
// k6/scripts/sql-validate.js — requires xk6 build --with github.com/grafana/xk6-sql
// with the appropriate driver: --with github.com/grafana/xk6-sql-driver-postgres
import sql from "k6/x/sql";
import http from "k6/http";
import { check } from "k6";
import driver from "k6/x/sql/driver/postgres";

const db = sql.open(driver, __ENV.DB_URL);  // e.g. postgres://user:pw@host/dbname

export function teardown() {
  // Validate: no duplicate orders created during the load test
  const rows = db.query(
    "SELECT order_id, COUNT(*) AS cnt FROM orders GROUP BY order_id HAVING COUNT(*) > 1"
  );
  check(rows, { "no duplicate orders": (r) => r.length === 0 });
  db.close();
}

export const options = {
  scenarios: {
    order_load: {
      executor: "constant-arrival-rate",
      rate: 50, timeUnit: "1s", duration: "2m",
      preAllocatedVUs: 20, maxVUs: 50,
    },
  },
  thresholds: {
    "http_req_duration": ["p(95)<1000"],
    "http_req_failed":   ["rate<0.01"],
  },
};

export default function () {
  const res = http.post(
    `${__ENV.API_URL}/api/orders`,
    JSON.stringify({ item: "widget", qty: 1 }),
    { headers: { "Content-Type": "application/json", Authorization: `Bearer ${__ENV.TOKEN}` } }
  );
  check(res, { "order created": (r) => r.status === 201 });
}
```

> **[community]:** xk6-sql queries run **synchronously in the VU goroutine** — a slow DB
> query (>500 ms) inflates VU utilization and distorts your load test results. Only use
> xk6-sql in `setup()` or `teardown()` for validation, not in the hot `default()` loop.
> Supported drivers: Postgres (`xk6-sql-driver-postgres`), MySQL (`xk6-sql-driver-mysql`),
> SQLite3 (`xk6-sql-driver-sqlite3`), MSSQL (`xk6-sql-driver-sqlserver`).

### xk6-dns — Custom DNS Resolver for Multi-Region Tests

`xk6-dns` exposes k6's internal DNS configuration so tests can pin hostnames to specific
IPs or use custom resolvers — useful for blue/green deployment testing where you want to
direct traffic to specific backend instances without changing `/etc/hosts`.

```javascript
// k6/scripts/dns-pinning.js — requires xk6 build --with github.com/szkiba/xk6-dns
import { Resolver } from "k6/x/dns";
import http from "k6/http";
import { check } from "k6";

// Pin api.internal → specific blue/green IPs for canary validation
const resolver = new Resolver({
  hosts: {
    "api.internal": __ENV.TARGET_IP || "10.0.1.100",
  },
});

export const options = {
  scenarios: {
    canary: {
      executor: "constant-vus",
      vus: 20,
      duration: "1m",
    },
  },
};

export default function () {
  // Requests to api.internal are resolved by xk6-dns, not system DNS
  const res = http.get("https://api.internal/health", {
    // associate the custom resolver with this VU's HTTP requests
    dns: resolver,
  });
  check(res, { "healthy": (r) => r.status === 200 });
}
```

> **[community]:** xk6-dns is particularly valuable for blue/green load tests where you
> want to target `10.0.1.100` (blue) vs `10.0.1.101` (green) without modifying system DNS
> or hardcoding IPs in script URLs. Combine with `-e TARGET_IP=$BLUE_IP` / `-e TARGET_IP=$GREEN_IP`
> in CI to parameterize the target.

---

## Additional Community Gotchas (Iteration 29)

### 48. `csv.parse()` inside `default()` re-reads the file on every iteration — memory explosion  [community]

**What:** Moving `await csv.parse(file)` inside the `default()` function (instead of `setup()`)
causes k6 to re-parse the entire CSV file on every VU iteration — leading to memory exhaustion
and dramatically skewed response-time metrics as the test progresses.

**WHY:** `csv.parse()` returns a `Promise` that performs Go-native file parsing. Each call
allocates a new buffer for the entire CSV content. With 100 VUs each iterating every 1 s,
a 10 MB CSV is re-allocated 100 times per second. This is analogous to calling `open()` in
the hot loop — explicitly prohibited by k6's VU lifecycle rules.

**Fix:** Always call `csv.parse()` in `setup()` and pass the result via the `data` argument,
or call it at module init level with `await` (k6 allows top-level `await` in ES module scripts):

```javascript
// WRONG — re-parses on every iteration
export default async function () {
  const file = await open("./data/users.csv");         // ← opens fresh each time
  const records = await csv.parse(file, { asObjects: true }); // ← parses fresh each time
  const user = records[exec.scenario.iterationInTest % records.length];
  // ...
}

// CORRECT — parse once in setup(), pass via data
export async function setup() {
  const file = await open("./data/users.csv");
  const users = await csv.parse(file, { asObjects: true });
  return { users };   // users is deep-copied to each VU — but only parsed once
}

export default function (data) {
  const user = data.users[exec.scenario.iterationInTest % data.users.length];
  // ...
}
```

> **[community]:** `csv.parse()` result is a SharedArray-compatible structure. When returned
> from `setup()`, k6 shares the underlying memory across VUs rather than deep-copying the full
> array. If your CSV is > 50 MB, even `setup()` allocation may cause timeout — use `csv.Parser`
> streaming instead.

### 49. Browser tests fail with `"browserType is not set"` when `--browser.type` is omitted  [community]

**What:** Browser scenarios require the `--browser.type` option. If omitted in CI (e.g., when
running with a generic k6 Docker image), the test fails immediately with:
`GoError: browserType is not set; please set browser.type in scenario options`.

**WHY:** k6 browser scenarios require an explicit `chromium` (the only currently supported type)
to be set in `options.scenarios.<name>.options.browser.type`. Unlike `--headless`, there is no
default — the absence of this key is a hard error, not a warning.

```javascript
// WRONG — missing browser.type causes immediate GoError
export const options = {
  scenarios: {
    ui: {
      executor: "shared-iterations",
      vus: 1, iterations: 1,
      options: { browser: {} },  // ← missing .type
    },
  },
};

// CORRECT — always specify browser.type: "chromium"
export const options = {
  scenarios: {
    ui: {
      executor: "shared-iterations",
      vus: 1, iterations: 1,
      options: {
        browser: {
          type: "chromium",      // ← required; only "chromium" is supported
          headless: true,        // ← set false for local debugging
        },
      },
    },
  },
};
```

```bash
# CI: make sure Chromium is installed in the k6 image
# Official Grafana k6 browser image includes Chromium:
docker run --rm -v "$PWD:/scripts" grafana/k6:latest-with-browser \
  run --env API_URL=http://host.docker.internal:3001 /scripts/browser-test.js
```

> **[community]:** The official `grafana/k6:latest-with-browser` Docker image bundles
> Chromium. The plain `grafana/k6:latest` image does NOT include Chromium — running browser
> scenarios with it will fail with a `chromium not found` error, not the `browserType` error.
> Always use the `-with-browser` variant for browser test CI jobs.

### 50. `K6_CLOUD_STACK_ID` required for non-default Grafana Cloud stacks — tests run against wrong org silently  [community]

**What:** When teams manage multiple Grafana Cloud orgs (e.g., one per product, or prod vs
staging), `k6 cloud run` always defaults to the *first* org/stack associated with the API token.
Scripts run successfully but results land in the wrong organization.

**WHY:** The `k6 cloud login --token <TOKEN>` command stores the token but does not record a
default stack ID. When running `k6 cloud run`, k6 picks the first stack returned by the Cloud
API — which may not be the intended target environment.

```bash
# WRONG — sends results to whichever stack is first for this token
k6 cloud run script.js

# CORRECT — explicitly specify the target stack
k6 cloud run --stack my-product-stack script.js

# ALSO CORRECT — use env var (safer for CI secrets injection)
K6_CLOUD_STACK_ID=my-product-stack k6 cloud run script.js
```

```yaml
# CI: GitHub Actions — explicit stack per environment
- name: Run k6 cloud load test
  env:
    K6_CLOUD_TOKEN: ${{ secrets.K6_CLOUD_TOKEN }}
    K6_CLOUD_STACK_ID: ${{ vars.K6_STACK_STAGING }}   # per-env variable
  run: k6 cloud run k6/scripts/load.js
```

> **[community]:** The `K6_CLOUD_STACK_ID` / `--stack` requirement became more visible in
> v2.0.0 where the CLI enforces it for some commands. However, `k6 cloud run` silently
> falls back to a default stack even in v2.0 — the gotcha is *correctness*, not a crash.
> Always pin `--stack` in CI pipelines to prevent cross-environment result contamination.

### 51. xk6-disruptor requires cluster-admin RBAC — silently fails in restricted namespaces  [community]

**What:** `xk6-disruptor`'s `PodDisruptor` and `ServiceDisruptor` inject a proxy sidecar into
the target pods. This requires `create pods/exec`, `get pods`, and `watch services` permissions
in the target namespace. Running the disruptor in a restricted namespace (e.g., a dev namespace
with read-only service accounts) causes the test to hang or fail with a cryptic timeout error
rather than a clear RBAC denial.

**WHY:** The disruptor communicates with the Kubernetes API server using the default service
account of the pod running k6. In many production clusters, pods cannot `exec` into other pods
by default (PodSecurityPolicy / OPA Gatekeeper / Kyverno may block it).

```bash
# Check if the k6 pod has the required permissions before running
kubectl auth can-i exec pods --namespace=target-ns --as=system:serviceaccount:k6-ns:k6-runner
# Expected: yes

# Create minimal RBAC for xk6-disruptor
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: xk6-disruptor
rules:
- apiGroups: [""]
  resources: ["pods", "pods/exec", "services", "endpoints"]
  verbs: ["get", "list", "watch", "create"]
EOF
kubectl create clusterrolebinding xk6-disruptor \
  --clusterrole=xk6-disruptor \
  --serviceaccount=k6-ns:k6-runner
```

> **[community]:** xk6-disruptor is Kubernetes-only; it has no support for Docker Compose
> or bare-metal deployments. Always validate RBAC with `kubectl auth can-i` before scheduling
> a fault-injection run in CI — the disruptor timeout error (`context deadline exceeded`) gives
> no indication of a permissions problem.

### 52. `-e` flag with `K6_`-prefixed var name does NOT configure k6 options — silent test misconfiguration  [community]

**What:** Running `k6 run -e K6_ITERATIONS=50 script.js` passes `K6_ITERATIONS` as a
script-visible `__ENV` variable **but does not configure `options.iterations`**. The `-e` flag
is exclusively for script-visible variables; it never drives k6's option resolution engine.
k6 continues with its default iterations (infinite) or whatever is in the `options` object.

**WHY:** k6's option resolution chain is: CLI flags → `K6_` system env vars → `options` object
→ config file → defaults. The `-e` flag injects into `__ENV` only — it bypasses the option
resolution chain entirely, regardless of the variable name.

```bash
# WRONG — K6_ITERATIONS via -e is ignored by k6 options engine
k6 run -e K6_ITERATIONS=50 -e K6_VUS=10 script.js
# → test runs with default/options-object config, NOT 50 iterations / 10 VUs

# CORRECT — K6_ in system environment configures k6 options
K6_ITERATIONS=50 K6_VUS=10 k6 run script.js

# CORRECT — explicit CLI flags always work
k6 run --iterations 50 --vus 10 script.js

# CORRECT — dynamic config via __ENV in options object (with -e):
# In script: export const options = { iterations: parseInt(__ENV.ITERS || "100") };
# Then: k6 run -e ITERS=50 script.js   ← uses custom var name, not K6_ prefix
```

> **[community]:** This is the single most common k6 CI misconfiguration. The tell is that
> CI runs take much longer than expected (or don't stop) — the VU and iteration counts are
> wrong. The fix: grep CI configs for `-e K6_` patterns and replace with system env `K6_`
> exports or explicit CLI flags.

---

## Prometheus Remote Write — Native Histograms (k6 v1.x+)  [community]

k6 can stream Trend metrics (e.g., `http_req_duration`) to Prometheus as **native histograms**
instead of multiple gauge-based percentile metrics. Native histograms require Prometheus ≥ 2.40.0
with `--enable-feature=native-histograms` and yield unlimited post-hoc `histogram_quantile()`
queries — the percentile is calculated at query time, not at collection time.

### When to Use Native Histograms vs `K6_PROMETHEUS_RW_TREND_STATS`

| Approach | Pros | Cons |
|----------|------|------|
| `K6_PROMETHEUS_RW_TREND_STATS=p(90),p(95),p(99)` | Works with Prometheus < 2.40 | Percentiles are fixed at collection time; can't query p(85) after the fact |
| `K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true` | Unlimited post-hoc percentiles; `histogram_quantile()` in PromQL; lower cardinality | Requires Prometheus 2.40+ with feature flag; some cloud-managed Prometheus builds may not support it |

### Setup and Script Pattern

```bash
# Launch Prometheus with native histogram feature flag
prometheus \
  --enable-feature=native-histograms \
  --config.file=prometheus.yml

# Run k6 with native histogram output
K6_PROMETHEUS_RW_SERVER_URL=http://localhost:9090/api/v1/write \
K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true \
K6_PROMETHEUS_RW_PUSH_INTERVAL=5s \
k6 run -o experimental-prometheus-rw script.js
```

```javascript
// k6/scripts/load-prom.js
import http from "k6/http";
import { check } from "k6";

export const options = {
  scenarios: {
    checkout_flow: {
      executor: "constant-arrival-rate",
      rate: 100,
      timeUnit: "1s",
      duration: "5m",
      preAllocatedVUs: 50,
      maxVUs: 200,
    },
  },
  // Tag every run with a testid so Grafana can isolate runs by date
  tags: {
    testid: __ENV.TEST_RUN_ID || `run-${Date.now()}`,
    env: __ENV.TARGET_ENV || "staging",
  },
  thresholds: {
    // These thresholds are evaluated by k6 at run time;
    // for richer post-hoc analysis use histogram_quantile() in Grafana.
    http_req_duration: ["p(95)<500", "p(99)<1500"],
    http_req_failed: ["rate<0.01"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  const res = http.get(`${BASE}/api/products`, {
    tags: { name: "GET /api/products" },
  });
  check(res, { "status 200": (r) => r.status === 200 });
}
```

```promql
# Grafana PromQL — native histogram queries after the test
# p95 latency for the current run (replace testid value)
histogram_quantile(0.95,
  sum by (le) (
    rate(k6_http_req_duration_bucket{testid="run-1716502800000"}[1m])
  )
)

# Compare p95 across two runs
histogram_quantile(0.95,
  sum by (le, testid) (
    rate(k6_http_req_duration_bucket{testid=~"run-.*"}[1m])
  )
)
```

### Stale Marker Configuration

Without stale markers, Prometheus retains the last value for 5 minutes after the test ends —
polluting dashboards with stale data. Set `K6_PROMETHEUS_RW_STALE_MARKERS=true` (default `false`):

```bash
K6_PROMETHEUS_RW_STALE_MARKERS=true \
K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true \
k6 run -o experimental-prometheus-rw script.js
```

> **[community]:** Do not mix `K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true` and
> `K6_PROMETHEUS_RW_TREND_STATS` at the same time — k6 will use histogram mode and ignore
> `TREND_STATS`. Pick one strategy per test run and document it in your CI pipeline env vars.
> Switching between strategies mid-sprint confuses Grafana dashboards that expect consistent
> metric shapes.

---

## Manual Distributed Testing — `--execution-segment`  [community]

When k6-operator is not available (e.g., bare-metal CI or Docker Compose environments), you can
distribute load across multiple machines manually using `--execution-segment` and
`--execution-segment-sequence`.

```bash
# === Machine 1 of 3 ===
k6 run \
  --execution-segment "0:1/3" \
  --execution-segment-sequence "0,1/3,2/3,1" \
  --tag instance=node-1 \
  -o experimental-prometheus-rw \
  k6/scripts/load.js

# === Machine 2 of 3 ===
k6 run \
  --execution-segment "1/3:2/3" \
  --execution-segment-sequence "0,1/3,2/3,1" \
  --tag instance=node-2 \
  -o experimental-prometheus-rw \
  k6/scripts/load.js

# === Machine 3 of 3 ===
k6 run \
  --execution-segment "2/3:1" \
  --execution-segment-sequence "0,1/3,2/3,1" \
  --tag instance=node-3 \
  -o experimental-prometheus-rw \
  k6/scripts/load.js
```

```javascript
// k6/scripts/load.js — script works unchanged for single or distributed runs
import http from "k6/http";
import { check, sleep } from "k6";
import { SharedArray } from "k6/data";

// Each segment automatically receives a non-overlapping slice of iterations
// and a non-overlapping slice of SharedArray users.
const users = new SharedArray("users", () => JSON.parse(open("./data/users.json")));

export const options = {
  scenarios: {
    load: {
      executor: "shared-iterations",
      vus: 100,
      iterations: 10000,   // total across ALL segments; each node gets ~3333
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<500"],
  },
};

export default function () {
  const user = users[__VU % users.length];
  const res = http.post(
    `${__ENV.API_URL}/api/login`,
    JSON.stringify({ email: user.email, password: user.password }),
    { headers: { "Content-Type": "application/json" } }
  );
  check(res, { "login 200": (r) => r.status === 200 });
  sleep(1);
}
```

**Key constraints:**
- Each node evaluates thresholds **independently** — you must aggregate metrics externally
  (e.g., Prometheus + Grafana) to get the combined pass/fail verdict.
- `--execution-segment` slices the VU and iteration space but does NOT synchronize clock.
  Start all nodes within a few seconds of each other or use `--paused` + the REST API
  (`PUT /v1/status` with `paused: false`) to coordinate a simultaneous start.
- `__VU` values overlap across nodes — use `--tag instance=<node-id>` to distinguish
  per-node VU metrics in your observability backend.

> **[community]:** The most common manual distribution mistake is omitting
> `--execution-segment-sequence`. Without it, k6 assumes the full `"0:1"` range and
> `--execution-segment` is silently ignored — all nodes run the full test load and you get
> 3× the intended throughput.

---

## Web Dashboard — CI Artifact Export Pattern  [community]

`K6_WEB_DASHBOARD=true` enables a real-time browser dashboard on port 5665. In CI, this
causes the k6 process to **hang** waiting for the browser tab to be closed (see Gotcha 42).
The correct pattern for CI is to use `K6_WEB_DASHBOARD_EXPORT` for artifact generation and
set the port to `-1` to disable the HTTP server:

```bash
# CI — generate HTML report artifact without blocking the process
K6_WEB_DASHBOARD=true \
K6_WEB_DASHBOARD_EXPORT=reports/k6-dashboard-${RUN_ID}.html \
K6_WEB_DASHBOARD_PORT=-1 \
k6 run k6/scripts/load.js
```

```yaml
# .github/workflows/load-test.yml
- name: Run k6 load test
  env:
    K6_WEB_DASHBOARD: "true"
    K6_WEB_DASHBOARD_PORT: "-1"                          # disable HTTP server
    K6_WEB_DASHBOARD_EXPORT: "reports/k6-dashboard.html" # write artifact
    K6_WEB_DASHBOARD_PERIOD: "10s"                        # aggregation window
    K6_PROMETHEUS_RW_SERVER_URL: ${{ secrets.PROM_URL }}
    API_URL: ${{ vars.STAGING_API_URL }}
  run: k6 run k6/scripts/load.js

- name: Upload k6 dashboard report
  uses: actions/upload-artifact@v4
  if: always()   # upload even if load test fails
  with:
    name: k6-dashboard-${{ github.run_number }}
    path: reports/k6-dashboard.html
    retention-days: 30
```

**Aggregation period rule:** The exported HTML report only includes graphs when the test
duration is **at least 3× the aggregation period**. For a 1-minute smoke test, use
`K6_WEB_DASHBOARD_PERIOD=10s` (10 × 3 = 30 s ≤ 60 s). For a 10-minute soak test,
`K6_WEB_DASHBOARD_PERIOD=30s` works fine.

> **[community]:** If both `K6_WEB_DASHBOARD_EXPORT` and `K6_WEB_DASHBOARD_PORT=-1` are set,
> k6 writes the HTML file and exits cleanly — no port is opened, no hang. The common mistake
> is setting `K6_WEB_DASHBOARD=true` without `-1` in CI, which blocks indefinitely until the
> server receives a `SIGTERM`. Set `-1` in CI unconditionally; the dashboard server is only
> useful for interactive local runs.

---

## `k6/websockets` — Migration from `k6/experimental/websockets`  [community]

In k6 v1.x, the WebSocket module graduated from `k6/experimental/websockets` to `k6/websockets`.
The experimental path is **deprecated** and will be removed in a future release. The API is
identical — only the import path changes.

```javascript
// BEFORE (deprecated — will be removed)
import { WebSocket } from "k6/experimental/websockets";

// AFTER (stable — use this)
import { WebSocket } from "k6/websockets";
```

Full migration example:

```javascript
// k6/scripts/ws-chat-load.js
import { WebSocket } from "k6/websockets";  // stable import
import { check } from "k6";
import { sleep } from "k6";

export const options = {
  scenarios: {
    ws_load: {
      executor: "constant-vus",
      vus: 50,
      duration: "2m",
    },
  },
  thresholds: {
    "ws_session_duration":       ["p(95)<30000"],
    "ws_msgs_received":          ["count>0"],
    "ws_connecting":             ["p(99)<1000"],
    http_req_failed:             ["rate<0.01"],
  },
};

const WS_URL = __ENV.WS_URL || "ws://localhost:3001/chat";

export default async function () {
  const ws = new WebSocket(WS_URL, null, {
    headers: { Authorization: `Bearer ${__ENV.AUTH_TOKEN}` },
  });

  ws.addEventListener("open", () => {
    // Join a room on connect
    ws.send(JSON.stringify({ event: "JOIN", room: "general" }));
  });

  ws.addEventListener("message", (e) => {
    const msg = JSON.parse(e.data);
    check(msg, { "message has event": (m) => m.event !== undefined });
  });

  ws.addEventListener("error", (e) => {
    console.error("WS error:", e.message);
  });

  // Run for 10 seconds per VU iteration, then close cleanly
  await new Promise((resolve) => setTimeout(resolve, 10_000));
  ws.send(JSON.stringify({ event: "LEAVE" }));
  ws.close();
}
```

**Key behavior of `k6/websockets` vs `k6/ws`:**
- `k6/ws` uses a **local event loop** — the `default` function runs once per VU per iteration
  and blocks until `ws.close()`. Good for simple sequential WS flows.
- `k6/websockets` uses the **global k6 event loop** — multiple `WebSocket` instances can coexist
  within a single VU iteration. Required for multi-connection or mixed HTTP+WS scenarios.

> **[community]:** The `binaryType` property defaults to `"blob"` — binary frames arrive as
> `Blob` objects whose contents are opaque in k6. Set `ws.binaryType = "arraybuffer"` before
> opening if your protocol sends binary data; otherwise `e.data` in the message handler is
> a zero-length Blob and your checks silently pass on empty content (see Gotcha 41).

---

## `Promise.race()` — Competitive Failover Testing  [community]

`http.asyncRequest()` combined with `Promise.race()` lets you test failover latency — which
of two endpoints responds first under load, or how long before a timeout fires.

```javascript
// k6/scripts/failover-race.js
import http from "k6/http";
import { check } from "k6";
import { Trend } from "k6/metrics";

const winnerLatency = new Trend("failover_winner_latency_ms");

export const options = {
  scenarios: {
    failover: {
      executor: "constant-vus",
      vus: 20,
      duration: "3m",
    },
  },
  thresholds: {
    failover_winner_latency_ms: ["p(95)<300"],
  },
};

const PRIMARY = __ENV.PRIMARY_URL || "http://primary:3001";
const SECONDARY = __ENV.SECONDARY_URL || "http://secondary:3002";

export default async function () {
  const start = Date.now();

  // Fire both requests in parallel; use whichever responds first
  const primaryReq   = http.asyncRequest("GET", `${PRIMARY}/api/health`);
  const secondaryReq = http.asyncRequest("GET", `${SECONDARY}/api/health`);

  const winner = await Promise.race([primaryReq, secondaryReq]);
  winnerLatency.add(Date.now() - start);

  check(winner, {
    "winner responded 200": (r) => r.status === 200,
  });

  // Allow the slower request to settle — k6 blocks the iteration until
  // all outstanding async requests resolve, even without explicit await.
  // Awaiting explicitly avoids resource exhaustion warnings (see Gotcha below).
  await Promise.all([primaryReq, secondaryReq]);
}
```

**Timeout race pattern** — enforce a max latency beyond which you fail fast:

```javascript
async function withTimeout(promise, ms) {
  const timeoutPromise = new Promise((_, reject) =>
    setTimeout(() => reject(new Error(`Timed out after ${ms}ms`)), ms)
  );
  return Promise.race([promise, timeoutPromise]);
}

export default async function () {
  try {
    const res = await withTimeout(
      http.asyncRequest("GET", `${PRIMARY}/api/data`),
      500
    );
    check(res, { "200 within SLA": (r) => r.status === 200 });
  } catch (e) {
    // Timeout fired — count as a failure
    check(null, { "200 within SLA": () => false });
  }
}
```

> **[community]:** The k6 docs note that "after `res` gets the value from the fastest request,
> the other requests will continue to execute" and there is currently **no way to abort an
> in-flight `asyncRequest`**. Always `await Promise.all([...])` at the end of an async
> `default` function to ensure all pending requests complete before the VU iteration closes —
> otherwise k6 emits resource leak warnings and in-flight requests are counted as interrupted
> in the summary metrics.

---

## k6 v1.7.0 — Subcommand Extension Auto-Resolution Workflow  [community]

k6 v1.7.0 extended automatic extension resolution to **subcommand extensions** (the `k6 x`
namespace). Previously, using a subcommand extension required a custom `xk6 build`. Now k6
auto-provisions the extension binary if it is absent.

```bash
# k6 v1.7.0+ — no xk6 build required; k6 fetches the extension on first run
k6 x httpbin start             # provisions xk6-httpbin automatically
k6 x generator run script.js  # provisions xk6-generator automatically

# The K6_SECRET_SOURCE env var (also added in v1.7.0) is an alternative to --secret-source
K6_SECRET_SOURCE=aws-secrets-manager://us-east-1/my-k6-secrets \
k6 run k6/scripts/secrets-test.js

# Equivalent --secret-source flag form:
k6 run \
  --secret-source aws-secrets-manager://us-east-1/my-k6-secrets \
  k6/scripts/secrets-test.js
```

**Extension resolution precedence:**
1. Extension binary already present in the local k6 build (highest priority)
2. Auto-resolution downloads the extension via the k6 extension registry
3. Falls back with an error if the extension is not registered

> **[community]:** Auto-resolution requires an internet connection to the Grafana extension
> registry. In air-gapped CI environments, pre-build a custom k6 binary with `xk6` and cache
> it as a CI artifact. Running `k6 x <extension>` in a network-restricted environment silently
> waits for a timeout before failing — add `--no-auto-resolve` (or build your own binary) to
> avoid the hang.

---

## Additional Community Gotchas (Iteration 30)

### 53. Prometheus Native Histograms silently fail when Prometheus version is too old  [community]

**What:** Setting `K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true` with Prometheus < 2.40.0
(or without `--enable-feature=native-histograms`) causes k6 to silently drop all Trend metric
data. The test runs normally — k6 reports no errors — but Prometheus refuses the histogram
write and discards the metric. You discover this only when Grafana shows empty latency panels.

**WHY:** Prometheus introduced native histograms as an experimental feature in v2.40.0 behind
a feature flag. Remote write endpoints on older versions accept the request HTTP 204 but discard
histogram-encoded series because the TSDB doesn't know the type. k6 has no mechanism to detect
remote write acceptance vs silent discard.

```bash
# Verify Prometheus version before enabling native histograms
curl -s http://localhost:9090/api/v1/status/buildinfo | python3 -m json.tool | grep version
# Expected: "version": "2.52.0" (or >= 2.40.0)

# Verify native histograms feature flag is active
curl -s http://localhost:9090/api/v1/status/flags | python3 -m json.tool | grep native
# Expected: "enable-feature": "native-histograms"

# Safe fallback: use TREND_STATS if version is uncertain
K6_PROMETHEUS_RW_TREND_STATS="p(50),p(90),p(95),p(99),max" \
k6 run -o experimental-prometheus-rw script.js
```

> **[community]:** Always pin `K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM` to `false` in
> environments where you don't control the Prometheus version (e.g., shared observability
> platforms, Grafana Cloud free tier, AWS Managed Service for Prometheus < certain dates).
> Use native histograms only on infrastructure you manage directly.

---

### 54. `K6_WEB_DASHBOARD=true` without `PORT=-1` hangs CI pipelines indefinitely  [community]

**What:** When `K6_WEB_DASHBOARD=true` is set without `K6_WEB_DASHBOARD_PORT=-1`, k6 starts
an HTTP server on port 5665 and **does not exit** when the test completes — it waits for all
connected browser clients to disconnect. In CI pipelines where no browser opens the dashboard,
the k6 process hangs forever and the job times out.

**WHY:** The web dashboard server stays alive to allow users to export the HTML report
interactively from the browser. k6 cannot distinguish a CI environment from a developer machine
and assumes someone may be viewing the dashboard.

```bash
# WRONG — hangs indefinitely in CI (no browser to close the connection)
K6_WEB_DASHBOARD=true k6 run script.js

# CORRECT — generate HTML artifact and exit immediately
K6_WEB_DASHBOARD=true \
K6_WEB_DASHBOARD_PORT=-1 \
K6_WEB_DASHBOARD_EXPORT=reports/dashboard.html \
k6 run script.js

# ALSO CORRECT — disable dashboard entirely in CI (simplest)
k6 run script.js   # no K6_WEB_DASHBOARD variable
```

> **[community]:** Add `K6_WEB_DASHBOARD_PORT=-1` as a CI-wide environment variable rather
> than setting it per-job. This way, even if a developer adds `K6_WEB_DASHBOARD=true` to a
> CI script by mistake, the port override prevents a hang. The HTML export still works with
> `PORT=-1`, so you don't lose the artifact — you just lose the interactive server.

---

### 55. `k6/experimental/websockets` is deprecated — migrate to `k6/websockets`  [community]

**What:** The import path `k6/experimental/websockets` was the temporary home for the modern
WebSocket module before it graduated to stable. In k6 v1.x, the module is available at both
`k6/websockets` (stable) and `k6/experimental/websockets` (deprecated alias). The deprecated
alias **will be removed** in a future major version. Teams that delay migration will encounter
a sudden import error after upgrading.

**WHY:** The graduation from experimental to stable is k6's standard lifecycle for new modules.
The experimental namespace (`k6/experimental/*`) signals "API may change" — graduating to core
signals "stable, breaking changes only in major versions". Keeping the experimental import after
graduation creates a false sense of stability while the removal countdown runs.

```javascript
// BEFORE — deprecated import path
import { WebSocket } from "k6/experimental/websockets";

// AFTER — stable import path (no API changes, pure rename)
import { WebSocket } from "k6/websockets";

// One-line sed migration for existing scripts:
// sed -i 's|k6/experimental/websockets|k6/websockets|g' k6/**/*.js
```

> **[community]:** Run `grep -r "k6/experimental/websockets" k6/` in your repo to find all
> scripts using the deprecated path. The `k6/ws` module (legacy, callback-based) is a
> **separate** module that remains available but is also being superseded by `k6/websockets`.
> Do not confuse the three: `k6/ws` (legacy), `k6/experimental/websockets` (deprecated alias),
> `k6/websockets` (stable, use this).

---

### Gotcha #56 — CVE-2026-33186: gRPC Dependency Security Vulnerability — Pin to v1.7.1+

**Affected versions:** k6 v0.x up to and including v1.7.0  
**Fixed in:** k6 v1.7.1 (released 2026-05-xx)  
**Severity:** High — remote code execution possible via malformed gRPC response in `k6/net/grpc`

If your CI/CD pipelines or Docker images pin a specific k6 version, you may be silently running
a vulnerable build. The vulnerability lives in a transitive gRPC dependency and can be triggered
by a malicious or misconfigured server sending a crafted protobuf response.

```yaml
# WRONG — pinned to vulnerable v1.7.0 Docker image
image: grafana/k6:1.7.0

# RIGHT — pin to the patched patch release
image: grafana/k6:1.7.1

# ALSO RIGHT — track the latest stable minor (auto-picks up security patches)
image: grafana/k6:1.7   # "1.7" floating tag resolves to latest 1.7.x
```

```bash
# GitHub Actions: dependabot can track k6 Docker image versions automatically
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    # Dependabot opens a PR when grafana/k6 releases a new patch/minor version
```

```bash
# Audit existing CI files for pinned vulnerable versions:
grep -r "grafana/k6:1\.[0-6]\|grafana/k6:1\.7\.0" .github/ ci/ Dockerfile* k8s/
# Any match is potentially vulnerable — upgrade to 1.7.1+
```

> **[official]:** The CVE-2026-33186 advisory is tracked on the k6 GitHub security advisories page.
> Subscribe at `https://github.com/grafana/k6/security/advisories` (click "Watch" → "Custom" →
> "Security alerts") to receive email notifications for future k6 CVEs.

> **[community]:** If you use `xk6 build` to compile custom binaries, you must also upgrade your
> build environment's k6 source to v1.7.1 before recompiling — the vulnerability is in the Go
> gRPC module resolved at build time, not injected at runtime. Running `go mod tidy` after
> updating the k6 module version in your `go.mod` is sufficient to pull in the patched dependency.

---

### Pattern — `k6 cloud project list` for Dynamic CI Project Selection (v2.0.0+)

k6 v2.0.0 added `k6 cloud project list` to enumerate Grafana Cloud k6 projects programmatically.
This is critical for multi-team setups where each team owns a separate project and you want CI to
target the correct project without hard-coding IDs.

```bash
# List all projects in the default organization (JSON output)
K6_CLOUD_TOKEN=$K6_TOKEN k6 cloud project list --output json

# Sample output:
# [
#   {"id": 123456, "name": "Platform API", "organization_id": 9876},
#   {"id": 123457, "name": "Checkout Service", "organization_id": 9876},
#   {"id": 123458, "name": "Search Service", "organization_id": 9876}
# ]
```

```bash
# GitHub Actions: dynamically resolve project ID by name, then run the test
- name: Resolve k6 Cloud Project ID
  id: k6-project
  env:
    K6_CLOUD_TOKEN: ${{ secrets.K6_CLOUD_TOKEN }}
  run: |
    PROJECT_NAME="${{ github.event.repository.name }}"
    PROJECT_ID=$(k6 cloud project list --output json \
      | jq --arg name "$PROJECT_NAME" '.[] | select(.name == $name) | .id')
    if [ -z "$PROJECT_ID" ]; then
      echo "ERROR: No k6 Cloud project named '$PROJECT_NAME'" >&2
      exit 1
    fi
    echo "project_id=$PROJECT_ID" >> "$GITHUB_OUTPUT"

- name: Run k6 Cloud Test
  env:
    K6_CLOUD_TOKEN: ${{ secrets.K6_CLOUD_TOKEN }}
    K6_CLOUD_PROJECT_ID: ${{ steps.k6-project.outputs.project_id }}
  run: k6 cloud run --project-id "$K6_CLOUD_PROJECT_ID" k6/load-test.js
```

```javascript
// Option B: set project ID from env inside the script (avoids CLI flag duplication)
import { options as cloudOptions } from "https://jslib.k6.io/k6-summary/0.0.2/index.js";

export const options = {
  cloud: {
    projectID: __ENV.K6_CLOUD_PROJECT_ID ? parseInt(__ENV.K6_CLOUD_PROJECT_ID) : undefined,
    name: "Load Test — " + (__ENV.CI_COMMIT_REF_NAME || "local"),
  },
};
```

> **[official]:** `k6 cloud project list` requires `K6_CLOUD_TOKEN` (or `--token` flag) and
> optionally `K6_CLOUD_STACK_ID` if targeting a non-default Grafana Cloud stack. The `--output json`
> flag was added alongside the command in v2.0.0; earlier beta releases used `--format json`.

> **[community]:** Cache the project-id lookup in CI to avoid an extra API call on every run.
> Write the resolved ID to a workflow artifact or use a job-level output as shown above. For
> monorepos where multiple services share one workflow file, build a map in a setup job and pass
> project IDs to downstream matrix jobs via `needs.<job>.outputs`.

---

### xk6 Extension Author Migration Guide for k6 v2.0.0

Two breaking changes in k6 v2.0.0 affect extension authors directly: the JSON serialization
library swap and the new archive metadata `dependencies` field.

#### 1. easyjson → stdlib `encoding/json`

k6 v2.0.0 dropped the `mailru/easyjson` code-generation library in favour of the standard
library's `encoding/json`. Extensions that called easyjson's generated `MarshalJSON` / `UnmarshalJSON`
methods (or used `go:generate` directives for easyjson) must remove or replace those.

```go
// BEFORE — easyjson-generated implementation in your extension
// File: myobj_easyjson.go (generated, should be deleted)
//go:generate easyjson -all myobj.go

// MarshalJSON was generated by easyjson; now conflicts with stdlib
func (v MyObj) MarshalJSON() ([]byte, error) { ... }

// AFTER — remove myobj_easyjson.go entirely.
// If you need custom marshaling, implement stdlib json.Marshaler:
import "encoding/json"

func (v MyObj) MarshalJSON() ([]byte, error) {
    type Alias MyObj
    return json.Marshal(&struct {
        Alias
        ExtraField string `json:"extra_field"`
    }{
        Alias:      Alias(v),
        ExtraField: v.computeExtra(),
    })
}
```

```bash
# Migration checklist for easyjson removal:
# 1. Delete all *_easyjson.go generated files
find . -name "*_easyjson.go" -delete

# 2. Remove easyjson from go.mod / go.sum
go mod edit -droprequire github.com/mailru/easyjson
go mod tidy

# 3. Remove //go:generate easyjson directives from source files
grep -r "go:generate easyjson" . --include="*.go" -l

# 4. Rebuild and run tests — stdlib encoding/json is slightly stricter on
#    map key types and cycles; fix any new marshal errors.
go build ./...
go test ./...
```

> **[official]:** k6's internal RPC and metric serialization paths no longer depend on easyjson
> as of v2.0.0. Extension authors who were relying on k6 re-exporting easyjson types will find
> those types gone. The migration is mechanical but requires a full rebuild.

#### 2. Archive Metadata `dependencies` Field

`k6 archive` now embeds a `dependencies` key in the archive metadata (the `metadata.json` entry
inside the `.tar` archive). This lists all resolved xk6 extensions with their module paths and
version hashes — useful for reproducible builds and supply-chain auditing.

```json
// metadata.json inside k6-archive.tar (v2.0.0+)
{
  "k6version": "2.0.0",
  "goos": "linux",
  "goarch": "amd64",
  "dependencies": [
    {
      "name": "xk6-sql",
      "path": "github.com/grafana/xk6-sql",
      "version": "v0.4.1"
    },
    {
      "name": "xk6-faker",
      "path": "github.com/szkiba/xk6-faker",
      "version": "v0.3.0"
    }
  ]
}
```

```bash
# Extract and inspect archive dependencies in CI:
k6 archive -o k6-archive.tar k6/load-test.js
tar xOf k6-archive.tar metadata.json | jq '.dependencies'

# Fail the build if an extension version is not pinned (has no semantic version):
tar xOf k6-archive.tar metadata.json \
  | jq -e '.dependencies[] | select(.version | test("^v[0-9]") | not) | .name' \
  && echo "ERROR: unpinned extension detected" && exit 1 || echo "All extensions pinned."
```

> **[community]:** Use the `dependencies` field as a Software Bill of Materials (SBOM) source for
> your k6 load-test binaries. Feed it into Grype, Trivy, or your organisation's vulnerability
> scanner alongside your application SBOMs. Teams shipping k6 archives in Docker images for
> Kubernetes Jobs can embed this metadata as a container label for traceability:
>
> ```dockerfile
> ARG K6_DEPS_JSON
> LABEL org.opencontainers.image.k6.dependencies="$K6_DEPS_JSON"
> ```
>
> Populate `K6_DEPS_JSON` from the `tar xOf k6-archive.tar metadata.json | jq '.dependencies'`
> output during the Docker build step.

---

## Additional Community Gotchas (Iteration 32)

### 57. `page.waitForResponse()` race condition — set the listener BEFORE triggering the action  [community]

**What:** `page.waitForResponse(urlPattern)` returns a Promise that resolves with the first
matching response. If the action that triggers the response (e.g., a button click) fires
*before* the `waitForResponse` Promise is set up, the response arrives before the listener
is registered — the Promise never resolves and the test hangs until the timeout.

**WHY:** Browser events are asynchronous. A `click()` that immediately fires a fetch request
may deliver the response in under 10 ms — faster than the JS scheduler gets to set up the
`waitForResponse` listener if the two are awaited sequentially rather than in a `Promise.all`.

**Fix:** Always use `Promise.all()` to set up `waitForResponse` and dispatch the action
simultaneously:

```javascript
// WRONG — response may arrive before listener is ready
await page.getByRole("button", { name: "Save" }).click();
const saveRes = await page.waitForResponse("**/api/items");   // ← may hang

// CORRECT — listener and action start at the same instant
const [saveRes] = await Promise.all([
  page.waitForResponse("**/api/items"),                        // set listener first
  page.getByRole("button", { name: "Save" }).click(),         // trigger action
]);
check(saveRes.status(), { "save 200": (s) => s === 200 });
```

> **[community]:** `waitForResponse` accepts a URL string (exact match), a glob pattern
> (`"**/api/**"`), or a predicate function `(res) => boolean`. The predicate form is the
> most powerful: `page.waitForResponse((res) => res.url().includes("/api/items") && res.status() === 200)`.
> Use the predicate when multiple requests to the same URL fire and you need a specific one.

---

### 58. `locator.boundingBox()` returns `null` for hidden elements — layout tests need visibility guards  [community]

**What:** `locator.boundingBox()` returns `null` when the matched element is hidden
(`display: none`, `visibility: hidden`, or `opacity: 0`). Tests that destructure the result
without a null check (`const { x, y, width, height } = await loc.boundingBox()`) throw
a `TypeError: Cannot destructure property 'x' of null` — which k6 records as a failed
check but the VU continues running, producing misleading "layout error" metrics.

**WHY:** Hidden elements have no layout box; the Chromium CDP call returns null rather
than throwing. This matches browser behavior but surprises teams used to Selenium's
`element.getRect()` which throws `ElementNotInteractableException` for hidden elements.

**Fix:** Always guard `boundingBox()` results before destructuring:

```javascript
// k6/scripts/browser-layout.js — viewport coverage and overlap testing
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    layout_test: {
      executor: "shared-iterations",
      vus: 1, iterations: 2,
      options: { browser: { type: "chromium" } },
    },
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/dashboard`);

    // boundingBox() — get element geometry for layout validation
    const heroBox = await page.getByRole("banner").boundingBox();

    // GUARD: null check before destructuring
    if (heroBox === null) {
      check(false, { "hero banner visible": () => false });
      return;
    }

    const { x, y, width, height } = heroBox;
    check({ x, y, width, height }, {
      "hero banner not off-screen": (b) => b.x >= 0 && b.y >= 0,
      "hero banner spans full width": (b) => b.width >= 900,
      "hero banner height > 0": (b) => b.height > 0,
    });

    // Verify two elements do not overlap (e.g. sticky nav covers content)
    const navBox  = await page.locator("nav.sticky").boundingBox();
    const heroTop = y;

    if (navBox) {
      const navBottom = navBox.y + navBox.height;
      check(heroTop, {
        "hero not obscured by sticky nav": (top) => top >= navBottom,
      });
    }

  } finally {
    await page.close();
  }
}
```

> **[community]:** Use `boundingBox()` to catch CSS regression bugs that don't appear in
> functional checks — elements that render at `width: 0` or are pushed off-screen by a
> flexbox overflow. Combine with `page.screenshot()` and a pixel-diff tool (e.g. `pixelmatch`)
> for automated visual regression alongside k6 load tests.

---

### 59. `locator.contentFrame()` vs `page.frameLocator()` — wrong method for the use case causes silent `null`  [community]

**What:** k6 (since v1.3) provides two ways to interact with iframe content:
- `page.frameLocator(selector)` — scope future `locator()` calls inside the iframe (lazy, no async)
- `locator.contentFrame()` — get the actual `Frame` object from a `<iframe>` element Locator (async)

Teams that use `locator.contentFrame()` expecting the `frameLocator` chaining API receive a
`Frame` object instead, which has a subtly different API. Conversely, teams using `page.frameLocator()`
and then calling `.contentFrame()` on the result get an error because `FrameLocator` does not
have a `contentFrame()` method.

**WHY:** These are two different abstraction levels. `frameLocator()` returns a `FrameLocator`
(query scope, lazy, supports `.locator()` chaining). `contentFrame()` returns a `Frame`
(the live CDP frame reference, supports `.goto()`, `.title()`, `.evaluate()` directly).

**Fix:** Use the right abstraction for the task:

```javascript
import { browser } from "k6/browser";
import { check } from "k6";

export const options = {
  scenarios: {
    iframe_demo: {
      executor: "shared-iterations",
      vus: 1, iterations: 1,
      options: { browser: { type: "chromium" } },
    },
  },
};

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${__ENV.APP_URL || "http://localhost:3001"}/embed`);

    // PATTERN A: frameLocator() — best for element interaction inside an iframe
    // Use when: you want to click/fill/check elements inside the frame
    const paymentFrame = page.frameLocator("#payment-iframe");
    await paymentFrame.locator("#card-number").fill("4242424242424242");

    // PATTERN B: locator.contentFrame() — best when you need Frame-level APIs
    // Use when: you need frame.title(), frame.url(), frame.evaluate(), frame.goto()
    const iframeElement = page.locator("iframe#analytics-frame");
    const frame = await iframeElement.contentFrame();

    if (frame) {
      // Frame has page-level methods: title(), url(), evaluate()
      const frameTitle = await frame.title();
      check(frameTitle, { "analytics frame has title": (t) => t.length > 0 });

      // Execute JS inside the frame context
      const trackingId = await frame.evaluate(() => window.GA_TRACKING_ID);
      check(trackingId, { "tracking ID injected in frame": (id) => !!id });
    }

    // getBy* locators work on frameLocator scope (k6 v1.3+)
    // All semantic locator methods (getByRole, getByLabel, etc.) are available
    const submitInFrame = paymentFrame.getByRole("button", { name: "Pay" });
    await submitInFrame.waitFor({ state: "visible" });
    check(await submitInFrame.isEnabled(), { "pay button enabled": Boolean });

  } finally {
    await page.close();
  }
}
```

| Use case | Method | Returns |
|----------|--------|---------|
| Click/fill/check elements inside iframe | `page.frameLocator(sel)` | `FrameLocator` |
| Get frame URL, title, or run JS | `iframeLoc.contentFrame()` | `Frame \| null` |
| Nested iframe element interaction | `fl.frameLocator(nestedSel)` | `FrameLocator` |
| Semantic `getBy*` selectors in iframe | `frameLocator.getByRole(...)` | `Locator` |

> **[community]:** `locator.contentFrame()` returns `null` if the `<iframe>` has not
> yet loaded its `src` document. Always `await page.waitForLoadState("networkidle")` or
> `await iframeLoc.waitFor({ state: "visible" })` before calling `contentFrame()` to
> ensure the frame is ready.

---

## Additional Community Gotchas (Iteration 33)

### 60. `k6 cloud login --stack` persists a default stack — subsequent commands inherit it silently  [community]

**What:** The `k6 cloud login` command (v1.6.0+) accepts a `--stack my-stack-slug` flag that
stores the stack slug in the local credentials file (`~/.config/k6/credentials.json`). All
subsequent `k6 cloud` commands in that shell session **and all future sessions** inherit this
default — even without setting `K6_CLOUD_STACK_ID` or passing `--stack` explicitly.

**WHY:** The intent is developer convenience: log in once, run cloud tests without repeating
`--stack` every time. But CI agents that run multiple pipeline types (e.g., staging and
production) may inherit a stale default from a prior `k6 cloud login` call, silently targeting
the wrong stack.

**Fix:** In CI, always explicitly set `K6_CLOUD_STACK_ID` or pass `--stack` on every
`k6 cloud run` command. Do not rely on the credentials file in shared CI agents; use a
fresh login step per job:

```bash
# CI best practice — explicit stack on every cloud command, never rely on stored default
k6 cloud login --token "$K6_CLOUD_API_TOKEN" --stack "$K6_CLOUD_STACK_ID"
k6 cloud run --stack "$K6_CLOUD_STACK_ID" k6/scripts/load.js

# To inspect or clear the stored default:
cat ~/.config/k6/credentials.json           # check what default is stored
k6 cloud login --token "$TOKEN" --stack ""  # clear the stored default (empty string)
```

> **[community]:** On self-hosted runners, if a prior job called `k6 cloud login --stack prod`,
> the next job that calls only `k6 cloud run script.js` (no `--stack`) will quietly target
> production. Always treat CI agents as potentially dirty — set `K6_CLOUD_STACK_ID` as a
> CI environment variable and pass `--stack` explicitly rather than relying on login state.

---

## Browser Module — `page.waitForResponse()` (k6 v1.3+)  [community]

`page.waitForResponse(urlOrPredicate, options?)` waits for a network response matching
the given URL string, glob pattern, or predicate. It complements `waitForRequest()` for
cases where you need to assert on the response status or body after a UI action triggers
a fetch. Essential for SPAs where navigation is driven by XHR/fetch, not full page loads.

```javascript
// k6/scripts/browser-wait-response.js
import { browser } from "k6/browser";
import { check } from "k6";
import { Trend } from "k6/metrics";

const apiLatency = new Trend("browser_api_latency_ms", true);

export const options = {
  scenarios: {
    ui: {
      executor: "shared-iterations",
      vus: 1, iterations: 3,
      options: { browser: { type: "chromium" } },
    },
  },
  thresholds: {
    browser_api_latency_ms: ["p(95)<1000"],
    checks: ["rate==1.0"],
  },
};

const APP = __ENV.APP_URL || "http://localhost:3001";

export default async function () {
  const page = await browser.newPage();
  try {
    await page.goto(`${APP}/products`);

    // 1. Wait for a specific status-code response — use predicate form
    const [searchResp] = await Promise.all([
      page.waitForResponse(
        (res) => res.url().includes("/api/search") && res.status() === 200
      ),
      page.getByPlaceholder("Search...").fill("widget"),
    ]);

    // Measure time-to-data: from action to API response received
    const timing = searchResp.timing();
    apiLatency.add(timing.responseEnd - timing.requestStart);

    const body = await searchResp.json();
    check(body, {
      "search results non-empty": (b) => Array.isArray(b.results) && b.results.length > 0,
    });

    // 2. Glob pattern — match any write to the cart endpoint
    const [cartResp] = await Promise.all([
      page.waitForResponse("**/api/cart/**"),
      page.getByRole("button", { name: "Add to cart" }).first().click(),
    ]);
    check(cartResp.status(), { "cart update 200/201": (s) => s === 200 || s === 201 });

    // 3. waitForResponse with timeout override (default is defaultTimeout, usually 30s)
    try {
      const [fastResp] = await Promise.all([
        page.waitForResponse("**/api/recommendations", { timeout: 2000 }),
        page.getByRole("link", { name: "Home" }).click(),
      ]);
      check(fastResp.status(), { "recommendations loaded quickly": (s) => s === 200 });
    } catch (e) {
      // Timeout is acceptable — recommendations are optional
      console.warn("Recommendations timed out (non-critical):", e.message);
    }

  } finally {
    await page.close();
  }
}
```

**`waitForResponse` vs `waitForRequest` comparison:**

| | `waitForRequest` | `waitForResponse` |
|-|-----------------|-------------------|
| Resolves when | Request is sent | Response is received |
| Has `.status()` | No | Yes |
| Has `.json()` / `.body()` | No | Yes |
| Has `.timing()` | No | Yes |
| Use case | Assert API is called | Assert API returns expected data |
| Measure API latency | No | Yes (`.timing().responseEnd - .timing().requestStart`) |

> **[community]:** `response.json()` in `waitForResponse` is async (returns a Promise) —
> this is different from k6's HTTP module where `res.json()` is synchronous. Always `await`
> it: `const body = await searchResp.json()`. Calling it synchronously returns a Promise
> object, not the body — this is a common migration mistake from `k6/http` patterns.

---

## Browser Module — `locator.contentFrame()` and `locator.boundingBox()` (k6 v1.3+)  [community]

### `locator.contentFrame()` — Get Frame Reference from `<iframe>` Locator

Returns the `Frame` object for the content inside a located `<iframe>` element.
Unlike `page.frameLocator()` (which returns a query scope), `contentFrame()` gives you
a live `Frame` reference with navigation and evaluation capabilities.

```javascript
// Pattern: navigate to a URL inside an iframe, then assert on the frame content
const iframeLocator = page.locator("iframe#help-widget");
await iframeLocator.waitFor({ state: "attached" });

const frame = await iframeLocator.contentFrame();
if (!frame) throw new Error("Help iframe not loaded");

// Frame-level navigation
await frame.goto("https://help.example.com/getting-started");

// Frame title and URL
check(await frame.title(), { "help page title": (t) => t.includes("Getting Started") });
check(frame.url(), { "correct help URL": (u) => u.includes("getting-started") });

// Evaluate JS inside the frame
const hasAnalytics = await frame.evaluate(
  () => typeof window.analytics !== "undefined"
);
check(hasAnalytics, { "analytics loaded in frame": Boolean });
```

### `locator.boundingBox()` — Element Geometry for Layout Assertions

Returns `{ x, y, width, height }` relative to the viewport, or `null` if the element
is not visible. Use it for CSS regression tests: verifying elements are within
the viewport, have non-zero dimensions, and do not overlap critical UI regions.

```javascript
// Verify responsive layout: all cards fit within viewport at 1280×720
await page.setViewportSize({ width: 1280, height: 720 });
const cards = page.locator(".product-card");
const cardCount = await cards.count();

for (let i = 0; i < cardCount; i++) {
  const box = await cards.nth(i).boundingBox();
  if (!box) continue;  // hidden cards are acceptable
  check(box, {
    [`card ${i} within viewport width`]:  (b) => b.x + b.width <= 1280,
    [`card ${i} within viewport height`]: (b) => b.y + b.height <= 720,
    [`card ${i} has content area`]:       (b) => b.width > 0 && b.height > 0,
  });
}
```

> **[community]:** `locator.boundingBox()` uses the Chromium CDP `getBoxModel` call, which
> includes CSS `transform` effects but NOT `clip-path`. An element clipped by `clip-path: inset(100%)`
> still reports its full un-clipped bounding box. For true visibility testing, combine
> `boundingBox()` with `locator.isVisible()` or `locator.isInViewport()`.

---

## Secret Sources — `file` and `url` Advanced Configuration

### `file` Secret Source — Key=Value File Format

The `file` source reads secrets from a plain-text `key=value` file on disk. Each line holds one
secret. Secrets are loaded at startup and cached for the test duration — not re-read on each VU
iteration.

**secrets.file** (plain text, one secret per line):
```
api_key=s3cr3t-prod-key-abc123
db_password=hunter2
jwt_secret=my-jwt-signing-secret
stripe_key=sk_live_xxxxxxxxxxxx
```

**Running with the file source:**
```bash
# Local run
k6 run --secret-source=file=secrets.file script.js

# Docker: mount the directory containing both the script and the secrets file
docker run -it --rm \
  -v /path/to/scripts:/scripts \
  grafana/k6 run \
  --secret-source=file=/scripts/secrets.file \
  /scripts/script.js

# Environment variable form (equivalent)
export K6_SECRET_SOURCE="file=secrets.file"
k6 run script.js
```

**Accessing file-sourced secrets in a script:**
```javascript
import secrets from "k6/secrets";
import http from "k6/http";
import { check } from "k6";

export const options = {
  scenarios: {
    api_load: { executor: "constant-vus", vus: 20, duration: "2m" },
  },
  thresholds: { http_req_duration: ["p(95)<500"], http_req_failed: ["rate<0.01"] },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default async function () {
  // Fetched from the file source at runtime — never appears in k6 logs
  const apiKey   = await secrets.get("api_key");
  const jwtSecret = await secrets.get("jwt_secret");

  const res = http.post(
    `${BASE}/api/auth/token`,
    JSON.stringify({ client_id: "k6", client_secret: jwtSecret }),
    {
      headers: {
        "X-API-Key":      apiKey,
        "Content-Type":   "application/json",
      },
    }
  );
  check(res, { "token 200": (r) => r.status === 200 });
}
```

> **[community]:** The `file` source resolves the path **relative to the working directory where
> `k6 run` is invoked**, not relative to the script file. In Docker, this typically means the
> container's root `/` unless you set `-w /scripts`. Mount the secrets file alongside the script
> and use an absolute container path (e.g., `/scripts/secrets.file`) to avoid "file not found"
> errors that are cryptic because k6 surfaces them as a fatal startup error with no path hint.

### `url` Secret Source — Advanced Options

The `url` source fetches secrets from an HTTP endpoint using a `{key}` placeholder URL template.
It supports per-source configuration as comma-separated key=value pairs after the source type.

**Full option reference:**

| Option | Default | Purpose |
|--------|---------|---------|
| `urlTemplate` | (required) | URL with `{key}` placeholder replaced per `secrets.get()` call |
| `method` | `GET` | HTTP verb (`GET` or `POST`) |
| `headers.<name>` | — | Custom request header; repeat for multiple headers |
| `responsePath` | — | Dot-delimited JSON path to extract the secret value (e.g., `data.value`) |
| `timeout` | `30s` | Per-request deadline |
| `requestsPerMinuteLimit` | `300` | Rate cap for all `secrets.get()` calls against this source |
| `requestsBurst` | `10` | Token-bucket burst allowance above the per-minute limit |
| `maxRetries` | `3` | Retry count on 5xx / network errors |
| `retryBackoff` | `1s` | Fixed delay between retries |

**Syntax:**
```
--secret-source=url=<option>=<value>,<option>=<value>,...
```

**Examples:**

```bash
# Basic: Vault KV v2 (flat response: {"value": "s3cr3t"})
k6 run \
  --secret-source="url=urlTemplate=https://vault.internal/v1/secret/k6/{key},\
headers.X-Vault-Token=${VAULT_TOKEN},\
responsePath=data.data.value" \
  script.js

# AWS Secrets Manager proxy (nested JSON, POST, custom auth header)
k6 run \
  --secret-source="url=urlTemplate=https://secrets-proxy.internal/{key},\
method=POST,\
headers.Authorization=Bearer ${PROXY_TOKEN},\
headers.Content-Type=application/json,\
responsePath=secret.value,\
timeout=10s,\
maxRetries=5,\
retryBackoff=2s" \
  script.js

# Rate-limited source (avoid hammering Vault with 500 VUs × iterations)
k6 run \
  --secret-source="url=urlTemplate=https://vault.internal/v1/kv/{key},\
headers.X-Vault-Token=${VAULT_TOKEN},\
requestsPerMinuteLimit=60,\
requestsBurst=5" \
  script.js

# Via K6_SECRET_SOURCE (same options, space-separated within quotes)
export K6_SECRET_SOURCE="url=urlTemplate=https://vault.internal/v1/secret/k6/{key},headers.X-Vault-Token=${VAULT_TOKEN},responsePath=data.data.value"
k6 run script.js
```

**Multi-source with named file + url sources:**
```bash
# Combine file source (fast, no network) and url source (dynamic/rotated secrets)
k6 run \
  --secret-source=file=name=static,./static-secrets.file \
  --secret-source="url=name=dynamic,urlTemplate=https://vault.internal/v1/kv/{key},headers.X-Vault-Token=${VAULT_TOKEN}" \
  script.js
```

```javascript
// Access each named source explicitly in your script
import secrets from "k6/secrets";

export default async function () {
  const staticKey  = await secrets.source("static").get("api_key");     // from file
  const rotatedKey = await secrets.source("dynamic").get("db_password"); // from Vault
  // … use both …
}
```

> **[community]:** The `url` source fetches each secret **once per VU per `secrets.get()` call**,
> not once globally. At 500 VUs × 10 iterations each, a single `secrets.get("api_key")` call
> generates 5,000 HTTP requests to your secret backend. Use `requestsPerMinuteLimit` to avoid
> triggering Vault rate-limits or AWS Secrets Manager throttling. Alternatively, call
> `secrets.get()` in the `setup()` function (or store the result in a module-level `let`) and
> pass the value to VUs via `exec.test.abort()` for short tests, or via `SharedArray` for read-only
> data — noting that `secrets.get()` inside `SharedArray` init runs in the init context and must
> be called with `await` from an async wrapper.

---

### 61. `url` secret source `{key}` template is URL-encoded — keys with `/` or `#` break Vault paths  [community]

When k6 substitutes `secrets.get("path/to/key")` into `urlTemplate`, it **URL-encodes** the key.
`path/to/key` becomes `path%2Fto%2Fkey`. For Vault KV v2 where the secret path IS the URL path
segment (e.g., `/v1/secret/data/path/to/key`), this encoding breaks routing and returns 404.

**Wrong:**
```bash
# urlTemplate with slash-containing keys silently URL-encodes them
--secret-source="url=urlTemplate=https://vault/v1/secret/data/{key}"
# secrets.get("db/password") → GET /v1/secret/data/db%2Fpassword → 404
```

**Fix — use a thin Vault proxy or sidecar that decodes the key and re-routes to the correct path:**
```bash
# Vault proxy normalises the path before forwarding
--secret-source="url=urlTemplate=https://vault-proxy.internal/secrets/{key},\
headers.X-Vault-Token=${VAULT_TOKEN}"
# proxy receives /secrets/db%2Fpassword → decodes → GET /v1/secret/data/db/password
```

**Or flatten your Vault key names to avoid slashes:**
```bash
# Flat key names: db_password instead of db/password
secrets.get("db_password")   # → GET /v1/secret/data/db_password → 200
```

---

## Key APIs — Additions (k6 v1.3–v1.6)

These APIs were added in k6 v1.3.0 through v1.6.0 and complement the main Key APIs table:

| API | What it does | When to use |
|-----|-------------|-------------|
| `page.waitForResponse(urlOrFn, opts?)` | Wait for a network response matching URL/predicate | Assert SPA fetch responses after UI actions |
| `locator.contentFrame()` | Get live `Frame` object for `<iframe>` element | Frame-level navigation, title, evaluate calls |
| `locator.boundingBox()` | Get `{x,y,width,height}` of element, or `null` if hidden | Layout regression tests, overlap detection |
| `locator.locator(sel, opts?)` | Scope a new Locator to children of the parent match | Hierarchical targeting in tables, lists, cards |
| `frameLocator.getByRole(...)` | Semantic selector inside a frame scope (v1.3+) | ARIA-based element interaction inside iframes |
| `frameLocator.locator(sel).contentFrame()` | Chain: scope to iframe, then get nested frame | Double-nested iframe interaction |
| `page.waitForURL(url, opts?)` | Wait for page URL to match pattern after navigation | SPA routing assertions after click/submit |
| `response.timing()` | Get `{ requestStart, responseEnd, ... }` timing breakdown | Measure API call latency from browser tests |
| `response.json()` | Async JSON body parse from `waitForResponse` result | Assert API response body from browser tests |

---

## xk6-kafka — Kafka Load Testing  [community]

`xk6-kafka` (maintained by [mostafa/xk6-kafka](https://github.com/mostafa/xk6-kafka)) extends k6
with a Kafka producer and consumer. Version 2 delivers ~383,000 messages/sec with 50 VUs — roughly
3× faster than the v1 branch. Use it to validate Kafka producer throughput, measure end-to-end
consumer latency, and test schema-registry-enforced serialization under load.

**Supported formats:** String, JSON, binary, Avro, JSON Schema, Protobuf (via Schema Registry).  
**Auth:** SASL PLAIN/SCRAM, AWS IAM, Azure Entra OAuth, TLS/mTLS.

```bash
# Build a custom k6 binary with xk6-kafka v2
xk6 build --with github.com/mostafa/xk6-kafka@v2.0.0 --output ./k6-kafka

# Or via Docker (reproducible — pin the extension version)
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/xk6" grafana/xk6 \
  build --with github.com/mostafa/xk6-kafka@v2.0.0
```

```javascript
// k6/scripts/kafka-producer.js — JSON producer with SASL-PLAIN authentication
// Requires: xk6 build --with github.com/mostafa/xk6-kafka@v2.0.0
import { Producer, Consumer, SASL_PLAIN, SchemaRegistry } from "k6/x/kafka";
import { check } from "k6";
import { Counter, Trend } from "k6/metrics";

const messagesProduced = new Counter("kafka_messages_produced");
const producerLatency  = new Trend("kafka_producer_latency_ms", true);

// Connection config — pass via env vars or CI secrets
const brokers = [__ENV.KAFKA_BROKER || "localhost:9092"];

const saslConfig = __ENV.KAFKA_USERNAME
  ? {
      mechanism:    SASL_PLAIN,
      username:     __ENV.KAFKA_USERNAME,
      password:     __ENV.KAFKA_PASSWORD,
      ssl:          { enable: true },
    }
  : undefined; // omit for local broker without auth

const producer = new Producer({
  brokers,
  sasl:     saslConfig,
  topic:    __ENV.KAFKA_TOPIC || "k6-load-test",
});

export const options = {
  scenarios: {
    kafka_load: {
      executor: "constant-arrival-rate",
      rate: 1000,          // 1,000 messages/sec target
      timeUnit: "1s",
      duration: "2m",
      preAllocatedVUs: 20,
      maxVUs: 50,
    },
  },
  thresholds: {
    kafka_producer_latency_ms: ["p(95)<100"],   // 95th pct produce latency < 100 ms
    kafka_messages_produced:   ["count>100000"], // at least 100k messages in 2m
    checks:                    ["rate>0.99"],
  },
};

export default function () {
  const start = Date.now();

  const msg = {
    key:   `key-${__VU}-${__ITER}`,
    value: JSON.stringify({
      userId:    __VU,
      iteration: __ITER,
      ts:        new Date().toISOString(),
      payload:   "synthetic-event",
    }),
  };

  const err = producer.produce({ messages: [msg] });
  const latency = Date.now() - start;

  producerLatency.add(latency);
  messagesProduced.add(1);
  check(err, { "produce ok (no error)": (e) => e === undefined || e === null });
}

export function teardown() {
  producer.close();
}
```

**Consumer-side latency measurement pattern** (run as a separate scenario):

```javascript
// k6/scripts/kafka-e2e-latency.js — measure end-to-end produce→consume latency
import { Producer, Consumer } from "k6/x/kafka";
import { check } from "k6";
import { Trend } from "k6/metrics";

const e2eLatency = new Trend("kafka_e2e_latency_ms", true);

const brokers = [__ENV.KAFKA_BROKER || "localhost:9092"];
const topic   = __ENV.KAFKA_TOPIC || "k6-e2e-test";

const producer = new Producer({ brokers, topic });
const consumer = new Consumer({
  brokers,
  topic,
  groupId: `k6-consumer-${Date.now()}`, // unique group per run
});

export const options = {
  scenarios: {
    e2e: { executor: "constant-vus", vus: 5, duration: "1m" },
  },
  thresholds: {
    kafka_e2e_latency_ms: ["p(95)<500"],   // e2e < 500 ms for 95% of messages
  },
};

export default function () {
  const sentAt = Date.now();
  producer.produce({ messages: [{ key: "e2e", value: String(sentAt) }] });

  // Consume — each call blocks until a message arrives or timeout
  const msgs = consumer.consume({ limit: 1 });
  check(msgs, { "consumed message": (m) => m.length === 1 });

  if (msgs.length > 0) {
    const receivedAt  = Date.now();
    const producedAt  = parseInt(new TextDecoder().decode(msgs[0].value), 10);
    e2eLatency.add(receivedAt - producedAt);
  }
}

export function teardown() {
  consumer.close();
  producer.close();
}
```

> **[community]:** xk6-kafka `consumer.consume({ limit: N })` is a synchronous blocking call — it
> waits up to the configured timeout (default 1 s) for messages. If the producer scenario runs
> slower than the consumer, `consume()` will time out and return an empty array. Use separate
> `producer` and `consumer` scenarios with `startTime` staggering to ensure the topic is populated
> before consumers start. For multi-partition topics, set `groupId` to a unique value per test run
> so consumers always start from the latest offset rather than replaying old messages from a
> previous test run.

---

## xk6-mqtt — MQTT Broker Load Testing  [community]

`xk6-mqtt` ([github.com/grafana/xk6-mqtt](https://github.com/grafana/xk6-mqtt)) adds MQTT v3.1.1
support to k6. It uses an event-driven model: each VU's `default()` function runs once and blocks
on the internal event loop until all registered event handlers close the connection. This makes it
different from HTTP tests where `default()` loops — for MQTT, the VU lifecycle IS the connection
lifecycle.

**Supported URL schemes:** `mqtt://`, `mqtts://` (TLS), `ws://`, `wss://` (WebSocket transport).

```bash
# Build custom k6 binary with xk6-mqtt
xk6 build --with github.com/grafana/xk6-mqtt --output ./k6-mqtt
```

```javascript
// k6/scripts/mqtt-load.js — publish and subscribe with round-trip latency measurement
// Requires: xk6 build --with github.com/grafana/xk6-mqtt
import { Client } from "k6/x/mqtt";
import { check } from "k6";
import { Trend, Counter, Rate } from "k6/metrics";

const roundTripLatency = new Trend("mqtt_round_trip_ms", true);
const messagesPublished = new Counter("mqtt_messages_published");
const deliveryRate      = new Rate("mqtt_delivery_success_rate");

export const options = {
  scenarios: {
    mqtt_load: {
      executor: "constant-vus",
      vus: 50,
      duration: "2m",
    },
  },
  thresholds: {
    mqtt_round_trip_ms:        ["p(95)<200"],   // 95th pct round-trip < 200 ms
    mqtt_delivery_success_rate: ["rate>0.99"],  // >99% messages delivered back
    checks:                    ["rate>0.99"],
  },
};

const BROKER_URL = __ENV.MQTT_BROKER_URL || "mqtt://localhost:1883";
const TOPIC      = __ENV.MQTT_TOPIC      || "k6/load-test";

export default function () {
  const client = new Client();
  const sentAt = Date.now();
  let   received = false;

  client.on("connect", () => {
    // QoS 1 = at-least-once delivery; 0 = fire-and-forget; 2 = exactly-once
    client.subscribe(TOPIC, 1 /* QoS */);

    const payload = JSON.stringify({ ts: sentAt, vu: __VU, iter: __ITER });
    client.publish(TOPIC, payload, 1 /* QoS */, false /* retain */);
    messagesPublished.add(1);

    // Close after 3 seconds — gives server time to echo back
    setTimeout(() => {
      if (!received) {
        deliveryRate.add(false);
        console.warn(`[VU ${__VU}] No echo received within 3s`);
      }
      client.end();
    }, 3000);
  });

  client.on("message", (topic, message) => {
    received = true;
    const latency = Date.now() - sentAt;
    roundTripLatency.add(latency);
    deliveryRate.add(true);

    const text = new TextDecoder().decode(new Uint8Array(message));
    check(text, { "echo contains ts": (t) => t.includes('"ts"') });
    client.end();
  });

  client.on("error", (err) => {
    console.error(`[VU ${__VU}] MQTT error:`, err);
    deliveryRate.add(false);
    client.end();
  });

  // connect() returns immediately — VU blocks on the event loop until client.end() is called
  client.connect(BROKER_URL);
}
```

> **[community]:** `client.connect()` is non-blocking — it initiates the TCP connection and
> returns immediately. The VU then enters the xk6-mqtt internal event loop and stays there until
> `client.end()` is called. Unlike `k6/websockets`, there is no global event loop: each VU has
> its own MQTT connection lifecycle. Do NOT call `client.connect()` inside an `onopen` callback
> or inside a `setTimeout` — put it at the end of `default()` after registering all event
> handlers, otherwise the connection fires before handlers are registered and messages may be
> missed.

> **[community]:** xk6-mqtt currently supports **MQTT v3.1.1 only** — MQTT v5 (which adds
> user properties, reason codes, and shared subscriptions) is not yet supported. For brokers
> that only accept MQTT v5 connections (e.g., some cloud IoT hubs), this extension will fail
> at the protocol handshake. Check broker compatibility before building your test binary.

---

## Additional Community Gotchas (Iteration 35)

### 62. `k6/experimental/fs` file handle opened at init context shares a cursor across iterations — seeking required  [community]

**What:** When you call `open(path)` at the module's top level (init context), the returned
`FileHandle` is shared across **all iterations** of a VU. Each `read()` call on a `Parser` or
`file.read(buf)` call advances the cursor. After the first iteration reads to EOF, every
subsequent iteration immediately gets `done: true` or 0 bytes — silently skipping all rows.

**WHY:** `k6/experimental/fs` uses memory-mapped file access for efficiency. A single file
descriptor is shared across all VUs and iterations to avoid re-mapping the same data repeatedly.
The `SharedArray` analogy breaks here: `SharedArray` returns immutable copies, but the `fs`
file handle maintains a mutable cursor position.

**Fix 1 (recommended for small-to-medium files):** Use `csv.parse()` with `asObjects` once at
init time. The resulting array is immutable and safe to index per iteration.

**Fix 2 (for large files):** Call `await file.seek(0, SeekMode.Start)` at the top of `default()`
to reset the cursor before each iteration:

```javascript
// k6/scripts/fs-seek-reset.js — correct pattern for per-iteration file reads via fs
import { open, SeekMode } from "k6/experimental/fs";
import { Parser }         from "k6/experimental/csv";
import http from "k6/http";
import { check } from "k6";

export const options = {
  scenarios: {
    load: { executor: "per-vu-iterations", vus: 5, iterations: 10 },
  },
};

// File handle opened ONCE at init context — cursor is shared!
const file = await open("./data/products.csv");

export default async function () {
  // REQUIRED: reset cursor to start of file before each iteration
  // Without this, iteration 2+ reads from where iteration 1 left off
  await file.seek(0, SeekMode.Start);

  // Re-create the Parser each iteration (it wraps the reset file handle)
  const parser = new Parser(file, { skipFirstLine: true });

  const { done, value } = await parser.next();
  if (done) {
    console.error("CSV exhausted — seek may have failed or file is empty");
    return;
  }

  const [productId, price] = value;
  const res = http.get(`${__ENV.API_URL}/api/products/${productId}`);
  check(res, { "product found": (r) => r.status === 200 });
}
```

**Fix 3 (simplest — avoids the problem entirely):** Open the file handle inside `default()`. This
creates a new handle per iteration — no shared cursor. The trade-off is a small overhead for
handle creation:

```javascript
export default async function () {
  // Open inside default() → fresh handle with cursor at position 0 every time
  const iterFile = await open("./data/products.csv");
  const parser   = new Parser(iterFile, { skipFirstLine: true });
  const { done, value } = await parser.next();
  // ... rest of iteration
}
```

> **[community]:** This gotcha is especially insidious because the first VU's first iteration
> succeeds perfectly, giving false confidence. The failure only appears when you run multiple
> iterations (`per-vu-iterations` with > 1 iteration, or `ramping-vus` over a long duration)
> and the file reaches EOF. Add an explicit EOF guard (`if (done) throw new Error("EOF")`) to
> make the failure visible rather than silently skipping work.

> **[community]:** `SeekMode.Start` (numeric value `0`) rewinds to the beginning of the file.
> `SeekMode.Current` (value `1`) and `SeekMode.End` (value `2`) are also available for
> partial-file reads (e.g., splitting a large file across VUs by seeking to a calculated offset).
> Import `SeekMode` from `"k6/experimental/fs"` — it is a named export, not a default export.

---

## Ramping Arrival Rate — Comprehensive Multi-Phase Traffic Example

The `ramping-arrival-rate` executor is the right choice when you need to model gradually increasing
RPS with distinct phases (warm-up → ramp → sustain → spike → ramp-down). Unlike `ramping-vus`,
it maintains a *fixed iteration rate* in each phase regardless of how long individual iterations
take — making it accurate for open-model load profiling.

**Key options:**
| Option | Required | Default | Purpose |
|--------|----------|---------|---------|
| `startRate` | No | `0` | Initial iterations per `timeUnit` at test start |
| `timeUnit` | No | `"1s"` | Period for the rate (e.g. `"1s"` = iterations per second, `"1m"` = per minute) |
| `preAllocatedVUs` | **Yes** | — | VUs allocated before the test starts (avoids cold-start ramp lag) |
| `maxVUs` | No | `preAllocatedVUs` | Upper ceiling — k6 allocates extra VUs if iteration time grows |
| `stages` | **Yes** | — | Array of `{ target, duration }` — each target is iterations per `timeUnit` |

**Critical rule:** Do NOT call `sleep()` inside iterations for arrival-rate executors. The executor
controls pacing through `rate` and `timeUnit`. Adding `sleep()` increases iteration duration, causing
k6 to allocate more VUs to maintain the target rate — potentially exceeding `maxVUs` and dropping iterations.

```javascript
// k6/scripts/ramping-arrival-complete.js
// Full lifecycle: warm-up → ramp → sustain → spike → ramp-down
// Uses ramping-arrival-rate + per-scenario thresholds + SLO-aware handleSummary
import http from "k6/http";
import { check, group } from "k6";
import { Trend, Counter } from "k6/metrics";
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.2/index.js";

// Custom metrics for fine-grained SLO tracking
const checkoutDuration = new Trend("checkout_duration_ms", true);
const cartErrors       = new Counter("cart_errors_total");

export const options = {
  discardResponseBodies: false,  // keep bodies for response validation
  scenarios: {
    api_traffic: {
      executor: "ramping-arrival-rate",
      startRate: 5,              // start at 5 RPS (avoids cold-start 0→100 shock)
      timeUnit: "1s",
      preAllocatedVUs: 20,       // pre-allocate VUs for initial load
      maxVUs: 200,               // k6 can scale up to 200 VUs if iterations slow down
      stages: [
        { target: 10,  duration: "1m"  },  // warm-up: ramp to 10 RPS
        { target: 50,  duration: "3m"  },  // ramp: steady climb to 50 RPS
        { target: 50,  duration: "5m"  },  // sustain: hold at 50 RPS
        { target: 100, duration: "2m"  },  // spike: sudden doubling of load
        { target: 50,  duration: "2m"  },  // recovery: return to baseline
        { target: 0,   duration: "1m"  },  // ramp-down: graceful cool-off
      ],
    },
  },
  thresholds: {
    // SLO-level thresholds — test fails with non-zero exit code if violated
    http_req_duration:      ["p(95)<500", "p(99)<1000"],  // 95th pct < 500ms, 99th < 1s
    http_req_failed:        ["rate<0.01"],                 // error rate < 1%
    checkout_duration_ms:   ["p(95)<800"],                 // checkout SLO
    cart_errors_total:      ["count<50"],                  // absolute error cap
    // Per-scenario threshold (tagged automatically by k6 with scenario name)
    "http_req_duration{scenario:api_traffic}": ["p(90)<400"],
  },
};

const BASE = __ENV.API_URL || "http://localhost:3001";

export default function () {
  // No sleep() here — ramping-arrival-rate controls pacing
  group("browse and cart", function () {
    const listRes = http.get(`${BASE}/api/products`, {
      tags: { name: "product_list" },
    });
    check(listRes, {
      "product list 200": (r) => r.status === 200,
      "products returned": (r) => {
        try { return Array.isArray(r.json()); } catch { return false; }
      },
    });

    const cartStart = Date.now();
    const cartRes = http.post(
      `${BASE}/api/cart`,
      JSON.stringify({ productId: "prod-001", qty: 1 }),
      { headers: { "Content-Type": "application/json" }, tags: { name: "add_to_cart" } }
    );
    const ok = check(cartRes, { "cart 201": (r) => r.status === 201 });
    if (!ok) cartErrors.add(1);

    const checkoutRes = http.post(
      `${BASE}/api/checkout`,
      JSON.stringify({ cartId: cartRes.json("id") }),
      { headers: { "Content-Type": "application/json" }, tags: { name: "checkout" } }
    );
    checkoutDuration.add(Date.now() - cartStart);
    check(checkoutRes, { "checkout 200": (r) => r.status === 200 });
  });
}

// handleSummary — output JSON artifact for CI + human-readable text to stdout
export function handleSummary(data) {
  return {
    "results/summary.json": JSON.stringify(data, null, 2),  // machine-readable for CI diff
    stdout: textSummary(data, { indent: "  ", enableColors: true }),
  };
}
```

**Sizing `preAllocatedVUs` correctly:**
- Use Little's Law: `preAllocatedVUs ≥ max_target_rate × avg_iteration_duration_seconds`
- Example: 100 RPS peak, avg iteration = 300 ms → `preAllocatedVUs = 100 × 0.3 = 30 VUs`
- Set `maxVUs` to 2–3× `preAllocatedVUs` to absorb latency spikes without dropping iterations
- k6 emits a warning `"insufficient VUs"` when `maxVUs` is exhausted — monitor this in CI logs

> **[community]:** The `stages` array in `ramping-arrival-rate` behaves differently from `ramping-vus`
> stages: targets are *iteration rates*, not *VU counts*. A `target: 0` final stage explicitly ramps
> down to 0 RPS, allowing in-flight iterations to drain gracefully. Without a ramp-down stage, k6
> cuts off iterations abruptly at test end, which can cause misleading "dropped request" counts in
> dashboards.

---

## Threshold Configuration for SLOs — Production Patterns

Thresholds are the mechanism for codifying Service Level Objectives (SLOs) into load test pass/fail
criteria. When a threshold is violated, k6 returns exit code `99` — distinguishing an SLO breach
from a script error (exit code `1`) or successful run (exit code `0`).

### SLO Threshold Reference

```javascript
// k6/scripts/slo-thresholds.js — comprehensive SLO gate configuration
export const options = {
  scenarios: {
    steady_state: {
      executor: "constant-arrival-rate",
      rate: 50, timeUnit: "1s",
      duration: "5m",
      preAllocatedVUs: 30, maxVUs: 100,
    },
  },

  thresholds: {
    // ── Latency SLOs ─────────────────────────────────────────────────────
    // p(95) = 95th percentile; p(50) = median (P50 catches mean-skew early)
    "http_req_duration":              ["p(50)<150", "p(95)<500", "p(99)<1000"],
    // Per-endpoint latency via URL normalization tags
    "http_req_duration{name:login}":  ["p(95)<300"],
    "http_req_duration{name:search}": ["p(95)<600"],

    // ── Error Rate SLOs ───────────────────────────────────────────────────
    "http_req_failed":                ["rate<0.005"],  // < 0.5% error rate (four-nines target)
    // Custom error metric (granular HTTP 5xx vs total)
    "http_req_failed{status:5..}":    ["rate<0.001"],  // 5xx only < 0.1%

    // ── Throughput SLOs ───────────────────────────────────────────────────
    // checks pass-rate: all checks should pass ≥ 99% of the time
    "checks":                         ["rate>0.99"],

    // ── Custom Metric SLOs ────────────────────────────────────────────────
    // Business-level SLOs on custom Trend/Counter metrics
    "checkout_duration_ms":           ["p(95)<800"],
    "payment_errors_total":           ["count<10"],

    // ── abortOnFail — stop the test immediately on catastrophic failure ───
    "http_req_failed": [{
      threshold:      "rate<0.10",   // abort if error rate exceeds 10%
      abortOnFail:    true,
      delayAbortEval: "30s",         // wait 30s of data before evaluating
    }],
  },
};
```

### Scenario-Scoped Thresholds

k6 automatically tags each metric with `scenario:<name>`. Use tag selectors to apply different
SLOs to different scenarios in multi-scenario tests:

```javascript
export const options = {
  scenarios: {
    read_traffic:  { executor: "constant-arrival-rate", rate: 100, duration: "5m", preAllocatedVUs: 20, maxVUs: 50  },
    write_traffic: { executor: "constant-arrival-rate", rate: 20,  duration: "5m", preAllocatedVUs: 10, maxVUs: 30  },
  },
  thresholds: {
    // Different SLOs per scenario — reads are faster than writes
    "http_req_duration{scenario:read_traffic}":  ["p(95)<200"],
    "http_req_duration{scenario:write_traffic}": ["p(95)<800"],
    "http_req_failed{scenario:write_traffic}":   ["rate<0.02"],
  },
};
```

> **[community]:** Tag selector threshold keys must be an **exact string match** of the metric name
> plus the tag expression in `{key:value}` format. Wildcards and regex are NOT supported in threshold
> tag selectors. A typo in the tag selector (e.g., `{scenarion:read_traffic}`) will silently create
> a new empty threshold that always passes — k6 will not warn you. Verify selectors by cross-checking
> the JSON summary output's `metrics` keys against your threshold config.

---

## Performance Regression Detection — CI Gate Patterns

Detecting performance regressions before they reach production requires a CI pipeline that
(a) stores baselines, (b) compares new runs against baselines, and (c) fails the build when
regressions exceed a tolerance band.

### Strategy 1 — Threshold-Based Gate (simplest, no baseline storage)

Define absolute thresholds as your SLA and let k6's exit code drive CI success/failure:

```yaml
# .github/workflows/perf-gate.yml
name: Performance Gate

on:
  push:
    branches: [main, "release/**"]

jobs:
  k6-smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run k6 smoke test
        uses: grafana/k6-action@v0.3.1
        with:
          filename: k6/scripts/smoke.js
        env:
          K6_CLOUD_TOKEN: ${{ secrets.K6_CLOUD_TOKEN }}
          API_URL:        ${{ vars.STAGING_URL }}

      # k6-action fails the step if k6 exits with code 99 (threshold breach)
      # or code 1 (script error). Exit code 0 = all thresholds passed.
```

```javascript
// k6/scripts/smoke.js — minimal CI smoke: < 2 min, 1 VU, SLO-gated
import http from "k6/http";
import { check } from "k6";

export const options = {
  scenarios: {
    smoke: {
      executor: "constant-vus",
      vus: 1,
      duration: "1m",
    },
  },
  thresholds: {
    http_req_duration: ["p(99)<500"],  // fail build if 99th pct > 500ms
    http_req_failed:   ["rate<0.01"],  // fail build if error rate > 1%
  },
};

export default function () {
  const r = http.get(`${__ENV.API_URL}/health`);
  check(r, { "health 200": (r) => r.status === 200 });
}
```

### Strategy 2 — Baseline Comparison with `handleSummary` + JSON Diff

Store the `summary.json` artifact from the reference run and compare subsequent runs against it:

```javascript
// k6/scripts/baseline-compare.js — save JSON summary for baseline comparison
import http from "k6/http";
import { check, sleep } from "k6";
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.2/index.js";

export const options = {
  scenarios: {
    load: {
      executor: "constant-arrival-rate",
      rate: 30, timeUnit: "1s",
      duration: "3m",
      preAllocatedVUs: 20, maxVUs: 80,
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed:   ["rate<0.01"],
  },
};

export default function () {
  const r = http.get(`${__ENV.API_URL}/api/products`);
  check(r, { "200 OK": (r) => r.status === 200 });
}

export function handleSummary(data) {
  const ts = new Date().toISOString().replace(/[:.]/g, "-");
  return {
    // Write versioned artifact — commit SHA in filename for traceability
    [`results/summary-${__ENV.GIT_SHA || ts}.json`]: JSON.stringify(data, null, 2),
    "results/summary-latest.json":                   JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: "  ", enableColors: true }),
  };
}
```

```bash
# .github/workflows/perf-regression.yml snippet
# Compares p(95) latency against stored baseline — fails if > 20% regression

- name: Run k6 load test
  run: |
    GIT_SHA=${{ github.sha }} \
    API_URL=${{ vars.STAGING_URL }} \
    k6 run k6/scripts/baseline-compare.js

- name: Check regression (p95 latency ≤ baseline × 1.20)
  run: |
    BASELINE=$(cat results/baseline.json | jq '.metrics.http_req_duration.values["p(95)"]')
    CURRENT=$(cat results/summary-latest.json | jq '.metrics.http_req_duration.values["p(95)"]')
    LIMIT=$(echo "$BASELINE * 1.20" | bc)
    echo "Baseline p(95): ${BASELINE}ms | Current: ${CURRENT}ms | Limit: ${LIMIT}ms"
    python3 -c "
    import sys
    baseline, current, limit = $BASELINE, $CURRENT, $LIMIT
    if current > limit:
        print(f'REGRESSION: p(95) {current:.1f}ms > limit {limit:.1f}ms ({((current/baseline)-1)*100:.1f}% above baseline)')
        sys.exit(1)
    else:
        print(f'PASS: p(95) {current:.1f}ms within 20% of baseline ({baseline:.1f}ms)')
    "

- name: Store baseline (main branch only)
  if: github.ref == 'refs/heads/main' && success()
  run: cp results/summary-latest.json results/baseline.json

- uses: actions/upload-artifact@v4
  with:
    name: k6-results-${{ github.sha }}
    path: results/
    retention-days: 90
```

> **[community]:** k6's `summary.json` stores metric values under `metrics.<name>.values["p(95)"]`
> as floating-point milliseconds. The key name for percentiles includes the parentheses and is
> double-quoted: `"p(95)"`. In `jq`, use single-quoted path: `jq '.metrics.http_req_duration.values["p(95)"]'`.
> The `rate` for `http_req_failed` is stored under `metrics.http_req_failed.values.rate` (0.0–1.0, not %).

### Strategy 3 — Grafana k6 Cloud Trend Analysis (recommended for teams)

For teams using Grafana Cloud k6, the platform stores all test runs and provides trend dashboards
without manual baseline management:

```javascript
// k6/scripts/cloud-trend.js — run on k6 cloud for automatic trend tracking
export const options = {
  cloud: {
    projectID: parseInt(__ENV.K6_CLOUD_PROJECT_ID),
    name:      `Load Test — ${__ENV.CI_COMMIT_REF_NAME || "local"}`,
    note:      `Commit: ${__ENV.GIT_SHA || "unknown"} | Branch: ${__ENV.BRANCH || "local"}`,
  },
  // Thresholds still gate the run — cloud stores the result regardless of pass/fail
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed:   ["rate<0.01"],
  },
  scenarios: {
    load: {
      executor: "ramping-vus",
      stages: [
        { duration: "1m", target: 20 },
        { duration: "3m", target: 50 },
        { duration: "1m", target: 0  },
      ],
    },
  },
};
```

```bash
# Run on Grafana Cloud k6 — results are stored and trended automatically
k6 cloud run \
  --project-id $K6_CLOUD_PROJECT_ID \
  --stack $K6_CLOUD_STACK_ID \
  k6/scripts/cloud-trend.js
```

---

## TypeScript Native Support in k6

k6 v0.57+ runs `.ts` files directly using built-in esbuild transpilation — no webpack bundler
required for most use cases. This section covers the full TypeScript setup spectrum.

### Native TypeScript (k6 v0.57+, recommended)

```bash
# Run a TypeScript k6 script directly — esbuild transpiles on-the-fly
k6 run script.ts

# Type-check separately (k6 does NOT type-check — it only strips types)
npx tsc --noEmit --project tsconfig.k6.json
```

**Install type definitions:**
```bash
npm install --save-dev @types/k6
# For browser module types:
npm install --save-dev @types/k6__browser
```

**`tsconfig.k6.json`** — separate tsconfig avoids mixing k6 types with your app's DOM/node types:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noEmit": true,
    "types": ["k6"],
    "paths": {
      "k6":         ["./node_modules/@types/k6/index.d.ts"],
      "k6/*":       ["./node_modules/@types/k6/*.d.ts"],
      "k6/browser": ["./node_modules/@types/k6__browser/index.d.ts"]
    }
  },
  "include": ["k6/**/*.ts"],
  "exclude": ["node_modules"]
}
```

**Typed k6 script example:**
```typescript
// k6/scripts/typed-api.ts — full TypeScript with @types/k6
import http, { RefinedResponse, ResponseType } from "k6/http";
import { check, sleep }                        from "k6";
import { Options }                             from "k6/options";
import { Counter, Trend }                      from "k6/metrics";

// Typed custom metrics
const apiErrors:   Counter = new Counter("api_errors_total");
const apiDuration: Trend   = new Trend("api_duration_ms", true);

// Typed options — compile-time validation of option names
export const options: Options = {
  scenarios: {
    load: {
      executor:          "constant-arrival-rate",
      rate:              30,
      timeUnit:          "1s",
      duration:          "3m",
      preAllocatedVUs:   20,
      maxVUs:            80,
    },
  },
  thresholds: {
    api_duration_ms: ["p(95)<500"],
    api_errors_total: ["count<100"],
  },
};

// Typed response body
interface Product {
  id:    string;
  name:  string;
  price: number;
}

export default function (): void {
  const res: RefinedResponse<"text"> = http.get<"text">(
    `${__ENV.API_URL}/api/products`
  );

  const ok = check(res, {
    "200 OK":         (r) => r.status === 200,
    "has products":   (r) => {
      try {
        const body = JSON.parse(r.body as string) as Product[];
        return body.length > 0;
      } catch {
        return false;
      }
    },
  });

  if (!ok) apiErrors.add(1);
  apiDuration.add(res.timings.duration);
}
```

> **[community]:** k6's native TypeScript support is **transpilation-only** — type errors do NOT
> fail the `k6 run` command. The `tsc --noEmit` step must be added to CI explicitly. Teams that
> skip the type-check step lose type safety silently: k6 runs the transpiled-but-type-incorrect
> script without complaint. Add `tsc --noEmit` as a pre-flight step before `k6 run` in CI:
>
> ```yaml
> - name: Type-check k6 scripts
>   run: npx tsc --noEmit --project tsconfig.k6.json
> - name: Run k6
>   run: k6 run k6/scripts/typed-api.ts
> ```

### Bundled TypeScript (for complex modules / Node.js imports)

When your k6 scripts need to import Node.js-only packages (e.g., `lodash`, `faker`, custom
shared utilities), you need a bundler since k6's native module resolution cannot resolve `node_modules`
at runtime. Use `esbuild` for the fastest build:

```bash
npm install --save-dev esbuild @types/k6
```

```javascript
// esbuild.config.mjs
import { build } from "esbuild";

await build({
  entryPoints: ["k6/scripts/complex-script.ts"],
  bundle:      true,
  outfile:     "dist/complex-script.js",
  format:      "esm",
  target:      "es2022",
  // Exclude k6 built-in modules from bundling — they are provided by the k6 runtime
  external:    [
    "k6",
    "k6/*",
    "https://*",   // jslib.k6.io URLs are fetched at runtime, not bundled
  ],
  platform:    "browser",  // avoids node built-in shims
});
```

```bash
# Build and run:
node esbuild.config.mjs && k6 run dist/complex-script.js
```

> **[community]:** The `external: ["k6", "k6/*"]` esbuild option is **mandatory**. Without it,
> esbuild tries to bundle k6's built-in modules (like `k6/http`) as if they were npm packages,
> fails to resolve them, and either errors out or produces a broken bundle. k6 built-in modules
> are resolved by the k6 runtime at execution time — they must remain as bare imports in the
> output bundle.

---

## Grafana Dashboard Integration — k6 Metrics Visualization

k6 supports multiple real-time output backends. This section covers the three most common
Grafana-centric setups and their trade-offs.

### Option 1 — k6 Web Dashboard (built-in, no setup)

The fastest way to get a live dashboard — no external dependencies:

```bash
# Start k6 with built-in web dashboard (opens at http://localhost:5665)
K6_WEB_DASHBOARD=true k6 run script.js

# CI: generate static HTML artifact instead of opening a server
K6_WEB_DASHBOARD=true \
K6_WEB_DASHBOARD_PORT=-1 \
K6_WEB_DASHBOARD_EXPORT=reports/dashboard-$(date +%Y%m%d-%H%M%S).html \
k6 run script.js
```

The HTML export is a fully self-contained single-file report with interactive charts — no server
required to view it. Attach it as a GitHub Actions artifact for test run traceability.

### Option 2 — Prometheus Remote Write + Grafana Cloud (production recommended)

```bash
# k6 → Prometheus Remote Write → Grafana Cloud / on-prem Grafana
K6_PROMETHEUS_RW_SERVER_URL="https://prometheus-prod.example.com/api/v1/write" \
K6_PROMETHEUS_RW_USERNAME="$PROM_USERNAME" \
K6_PROMETHEUS_RW_PASSWORD="$PROM_PASSWORD" \
K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM=true \   # requires Prometheus 2.40+
k6 run -o experimental-prometheus-rw script.js
```

**Useful PromQL queries for k6 metrics:**
```promql
# Request rate (RPS) over 1-minute windows
rate(k6_http_reqs_total[1m])

# P95 latency from native histograms (requires Prometheus 2.40+ + native histogram flag)
histogram_quantile(0.95, rate(k6_http_req_duration_bucket[1m]))

# Error rate — requests that returned non-2xx or network error
rate(k6_http_req_failed_total{value="true"}[1m]) /
rate(k6_http_reqs_total[1m])

# VU count over time
k6_vus

# Custom Trend metric P95 (e.g., checkout_duration_ms)
histogram_quantile(0.95, rate(k6_checkout_duration_ms_bucket[1m]))
```

### Option 3 — InfluxDB 2.x + Grafana (self-hosted team setup)

```bash
# k6 → InfluxDB 2 → Grafana (local dev / staging)
k6 run -o influxdb=http://localhost:8086/k6 script.js

# With authentication (InfluxDB 2.x token auth):
K6_INFLUXDB_TOKEN="my-influxdb-token" \
K6_INFLUXDB_ORG="myorg" \
K6_INFLUXDB_BUCKET="k6" \
k6 run -o influxdb=http://localhost:8086 script.js
```

**Grafana dashboard IDs for k6:**
- `2587` — official k6 + InfluxDB dashboard (classic, widely used)
- `18030` — k6 Prometheus native histogram dashboard (requires Prom 2.40+ + native histograms)
- `18793` — k6 browser metrics dashboard (Web Vitals — LCP, FID/INP, CLS)

> **[community]:** The official k6 Grafana dashboard (ID `2587`) expects metric names in the
> `k6.*` InfluxDB measurement format. If you rename k6 metrics using custom tags or the
> `--tag` flag with a `name` dimension, those metrics appear under a different measurement name
> and the pre-built panels show no data. Duplicate the dashboard and update the measurement
> variable in the top-level template variable, or use Explore to verify metric names before
> building custom panels.

---

## Additional Community Gotchas (Iteration 36)

### 63. `ramping-arrival-rate` `startRate` must be > 0 to avoid a cold-start burst  [community]

**What:** When `startRate` is omitted or set to `0`, k6 begins the first stage with 0 iterations
per second and ramps up from there. If your first stage target is high (e.g., `{ target: 100, duration: "30s" }`),
k6 linearly increases from 0 to 100 RPS over 30 seconds. This is correct behavior — but many teams
expect a "start at zero, jump to target immediately" effect and are surprised when the actual RPS
graph shows a gradual curve from 0 rather than a stair-step.

**The real risk:** If you set `startRate` to the same value as your first stage `target`, k6 holds
that rate constant until the stage `duration` elapses. This is the pattern for a **no warm-up,
full-rate-from-start** scenario — often desirable for breakpoint tests but surprising for teams
expecting a ramp.

```javascript
// PATTERN A — warm-up ramp (startRate = 0, implicit):
stages: [
  { target: 100, duration: "2m" },  // 0 → 100 RPS over 2 minutes
  { target: 100, duration: "5m" },  // hold 100 RPS
]

// PATTERN B — immediate full load (startRate = target):
startRate: 100,
stages: [
  { target: 100, duration: "5m" },  // holds exactly 100 RPS from second 0
]

// PATTERN C — soft start with explicit warm-up:
startRate: 5,
stages: [
  { target: 10,  duration: "30s" },  // gentle ramp 5 → 10 RPS
  { target: 100, duration: "2m"  },  // accelerate to full load
  { target: 100, duration: "5m"  },  // sustain
]
```

> **[community]:** For capacity planning tests, Pattern C (soft start) is the most realistic
> because it gives the system under test time to fill its connection pools and warm up caches —
> the same behavior real users produce when traffic grows organically. Cold-starting at full RPS
> (Pattern B) is appropriate for resilience/disaster-recovery tests where you want to simulate
> a sudden traffic surge without warm-up.

---

### 64. `abortOnFail` with `delayAbortEval` does NOT guarantee the delay is accurate under VU exhaustion  [community]

**What:** `abortOnFail: true` combined with `delayAbortEval: "30s"` is intended to let k6
collect 30 seconds of data before evaluating the threshold and aborting. However, if the test
is simultaneously exhausting `maxVUs` (because the system is responding slowly and k6 needs more
VUs to keep up with the arrival rate), the evaluation is delayed not by wall-clock time but by
iteration completion cycles. Under severe VU exhaustion, you may wait significantly longer than
`delayAbortEval` before the abort fires.

**WHY:** `delayAbortEval` tracks elapsed test time using k6's internal scheduler, but the
scheduler prioritizes dispatching new iterations over running threshold evaluations when VUs
are exhausted. Real-world observation: a `delayAbortEval: "30s"` test under 90% VU exhaustion
can take 45–90 seconds before the abort fires.

**Fix:** Set `delayAbortEval` conservatively (2–3× expected delay), add a `maxVUs` safety
ceiling well above `preAllocatedVUs`, and monitor the `vus_max` metric alongside `vus`:

```javascript
thresholds: {
  http_req_failed: [{
    threshold:      "rate<0.10",
    abortOnFail:    true,
    delayAbortEval: "60s",   // 2× the intended 30s — absorbs scheduler delay
  }],
},
```

---

### 65. `handleSummary` JSON — `http_req_duration.values["p(95)"]` key has parentheses and is case-sensitive  [community]

**What:** The k6 summary JSON stores percentile values with the exact key format `"p(95)"` —
including parentheses. Scripts that parse the summary with naive property access like
`data.metrics.http_req_duration.values.p95` or `.values.p_95` find `undefined` and silently
skip the regression check.

**WHY:** k6 uses the threshold expression string as the key to make the summary output directly
correspond to threshold definitions. This is convenient for humans reading the JSON but tricky
for automation that expects valid JavaScript identifier-style keys.

```bash
# Correct jq path:
jq '.metrics.http_req_duration.values["p(95)"]' summary.json    # ✓

# Wrong — returns null silently:
jq '.metrics.http_req_duration.values.p95'    summary.json      # ✗ returns null
jq '.metrics.http_req_duration.values["p95"]' summary.json      # ✗ returns null

# Full metric key list (useful for discovering available percentiles):
jq '.metrics.http_req_duration.values | keys' summary.json
# Output: ["avg","max","med","min","p(90)","p(95)","p(99)"]
```

> **[community]:** k6 only stores percentiles that were referenced in a threshold or in the
> `summaryTrendStats` option. If you need `p(99)` in the summary JSON for a regression check
> but have no threshold using it, add `options.summaryTrendStats = ["avg","p(90)","p(95)","p(99)","max"]`
> to ensure it appears in the output. Without this, the key is absent from the JSON entirely —
> not null, not 0, but absent — causing `jq` to return `null` and Python to raise a `KeyError`.

