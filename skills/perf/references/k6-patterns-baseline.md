# k6 Patterns Baseline Reference

Source: k6.io/docs — captured 2026-04-26 via built-in knowledge (WebFetch unavailable; content reflects k6 v0.50+ stable patterns).

---

## 1. Test Types and When to Use Them

k6 recognizes several test types, each answering a different question about system behavior.

| Test Type | Goal | Typical VU Profile |
|-----------|------|--------------------|
| Smoke | Verify script runs without error at minimal load | 1–5 VUs, 1–2 min |
| Load | Validate system meets SLOs at expected traffic | Ramp to target, hold, ramp down |
| Stress | Find the breaking point / degradation point | Progressive ramp beyond normal load |
| Spike | Test sudden traffic bursts | Instant jump to high VU, then drop |
| Soak | Detect memory leaks and reliability over time | Moderate load held for hours |
| Breakpoint | Find max throughput (requires abort on failure) | Continuously ramping until threshold trips |

### Smoke test (minimal, always run first)

```javascript
export const options = {
  vus: 2,
  duration: "1m",
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<500"],
  },
};
```

### Load test (standard)

```javascript
export const options = {
  stages: [
    { duration: "2m",  target: 20  },  // ramp-up to 20 VUs
    { duration: "5m",  target: 20  },  // hold at 20 VUs
    { duration: "2m",  target: 50  },  // ramp-up to 50 VUs
    { duration: "5m",  target: 50  },  // hold at 50 VUs
    { duration: "2m",  target: 0   },  // ramp-down
  ],
};
```

### Stress test

```javascript
export const options = {
  stages: [
    { duration: "2m",  target: 100  },
    { duration: "5m",  target: 100  },
    { duration: "2m",  target: 200  },
    { duration: "5m",  target: 200  },
    { duration: "2m",  target: 300  },
    { duration: "5m",  target: 300  },
    { duration: "5m",  target: 0    },  // recovery
  ],
};
```

### Spike test

```javascript
export const options = {
  stages: [
    { duration: "1m",  target: 5    },  // baseline
    { duration: "30s", target: 200  },  // instant spike
    { duration: "3m",  target: 200  },  // hold spike
    { duration: "30s", target: 5    },  // recover
    { duration: "2m",  target: 5    },  // verify recovery
    { duration: "30s", target: 0    },
  ],
};
```

### Soak test

```javascript
export const options = {
  stages: [
    { duration: "5m",  target: 50  },  // ramp-up
    { duration: "4h",  target: 50  },  // hold for hours
    { duration: "5m",  target: 0   },  // ramp-down
  ],
};
```

---

## 2. Scenarios (preferred over `stages`)

Scenarios are the modern, preferred way to configure k6 load profiles. They allow multiple independent load profiles, different executors, and per-scenario thresholds — all in one test run.

### Executor types

| Executor | Use When | Key Options |
|----------|----------|-------------|
| `shared-iterations` | Fixed total iteration count split across VUs | `vus`, `iterations` |
| `per-vu-iterations` | Each VU runs exactly N iterations | `vus`, `iterations` |
| `constant-vus` | Fixed concurrency for a duration | `vus`, `duration` |
| `ramping-vus` | Staged VU ramp (replaces `stages`) | `stages[]` |
| `constant-arrival-rate` | Fixed request rate regardless of VU count | `rate`, `duration`, `preAllocatedVUs` |
| `ramping-arrival-rate` | Ramping request rate | `stages[]`, `preAllocatedVUs` |
| `externally-controlled` | VU count driven by k6 REST API at runtime | — |

### Scenario: ramping-vus (replaces top-level `stages`)

```javascript
export const options = {
  scenarios: {
    ramp_load: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "2m", target: 20 },
        { duration: "5m", target: 20 },
        { duration: "2m", target: 0  },
      ],
      gracefulRampDown: "30s",
    },
  },
};
```

### Scenario: constant-arrival-rate (throughput-focused)

Arrival-rate executors are preferred when you care about requests-per-second rather than concurrency. They keep the rate steady even if VUs are slow.

```javascript
export const options = {
  scenarios: {
    steady_rps: {
      executor: "constant-arrival-rate",
      rate: 100,            // 100 iterations/second
      timeUnit: "1s",
      duration: "5m",
      preAllocatedVUs: 50,  // pool to start with
      maxVUs: 200,          // allow scaling up if needed
    },
  },
};
```

### Scenario: ramping-arrival-rate (ramp RPS)

```javascript
export const options = {
  scenarios: {
    ramp_rps: {
      executor: "ramping-arrival-rate",
      startRate: 10,
      timeUnit: "1s",
      preAllocatedVUs: 20,
      maxVUs: 300,
      stages: [
        { duration: "2m", target: 50  },
        { duration: "5m", target: 50  },
        { duration: "2m", target: 100 },
        { duration: "5m", target: 100 },
        { duration: "2m", target: 0   },
      ],
    },
  },
};
```

### Multiple concurrent scenarios

```javascript
export const options = {
  scenarios: {
    browse_users: {
      executor: "ramping-vus",
      stages: [
        { duration: "2m", target: 30 },
        { duration: "5m", target: 30 },
        { duration: "1m", target: 0  },
      ],
      exec: "browseUsers",       // function to call
      tags: { scenario: "browse" },
    },
    create_orders: {
      executor: "constant-arrival-rate",
      rate: 20,
      timeUnit: "1s",
      duration: "8m",
      preAllocatedVUs: 20,
      maxVUs: 60,
      startTime: "1m",           // delay start by 1 minute
      exec: "createOrder",
      tags: { scenario: "write" },
    },
  },
};

export function browseUsers() { /* ... */ }
export function createOrder()  { /* ... */ }
```

### Per-scenario thresholds

Threshold tags match the scenario tag you define, enabling pass/fail per scenario:

```javascript
export const options = {
  scenarios: {
    api_reads: {
      executor: "constant-vus",
      vus: 20,
      duration: "5m",
      tags: { type: "read" },
    },
    api_writes: {
      executor: "constant-vus",
      vus: 5,
      duration: "5m",
      tags: { type: "write" },
    },
  },
  thresholds: {
    "http_req_duration{type:read}":  ["p(95)<200"],
    "http_req_duration{type:write}": ["p(95)<500"],
    "http_req_failed{type:read}":    ["rate<0.01"],
    "http_req_failed{type:write}":   ["rate<0.05"],
  },
};
```

---

## 3. Thresholds

Thresholds define pass/fail criteria. k6 exits with code 99 (non-zero) when any threshold is breached, making them CI-gate-friendly.

### Syntax

```javascript
thresholds: {
  "<metric_name>[{<tag>:<value>}]": ["<aggregator><comparator><value>", ...],
}
```

### Built-in metrics available for thresholds

| Metric | Type | Common Aggregators |
|--------|------|--------------------|
| `http_req_duration` | Trend | `p(50)`, `p(90)`, `p(95)`, `p(99)`, `avg`, `min`, `max` |
| `http_req_failed` | Rate | `rate` |
| `http_reqs` | Counter | `count`, `rate` |
| `http_req_waiting` | Trend | `p(95)` (TTFB proxy) |
| `http_req_connecting` | Trend | `avg` |
| `http_req_tls_handshaking` | Trend | `avg` |
| `vus` | Gauge | (informational, not typically thresholded) |
| `iteration_duration` | Trend | `p(95)` |
| `iterations` | Counter | `rate` |
| `data_received` | Counter | `rate` |
| `data_sent` | Counter | `rate` |

### Threshold examples

```javascript
export const options = {
  thresholds: {
    // Latency SLOs
    http_req_duration: [
      "p(50)<100",    // median under 100ms
      "p(95)<200",    // 95th percentile under 200ms
      "p(99)<500",    // 99th percentile under 500ms
      "max<2000",     // no single request over 2s
    ],

    // Error budget
    http_req_failed: ["rate<0.01"],   // < 1% failure

    // Throughput floor
    http_reqs: ["rate>50"],           // at least 50 req/s

    // Custom metric thresholds
    "my_api_latency": ["p(95)<300"],

    // Tag-scoped thresholds
    "http_req_duration{status:200}": ["p(95)<150"],
    "http_req_duration{url:http://api/login}": ["p(99)<300"],
  },
};
```

### Abort on threshold breach (breakpoint / fail-fast)

```javascript
thresholds: {
  http_req_duration: [
    {
      threshold: "p(95)<500",
      abortOnFail: true,
      delayAbortEval: "1m",   // give 1 minute before evaluating abort
    },
  ],
  http_req_failed: [
    {
      threshold: "rate<0.05",
      abortOnFail: true,
    },
  ],
},
```

`abortOnFail: true` stops the test early once the condition is exceeded — useful for breakpoint and CI pipelines where you want to fail fast.

---

## 4. Custom Metrics

```javascript
import { Counter, Gauge, Rate, Trend } from "k6/metrics";

// Counter: monotonically increasing (e.g., total errors)
const totalErrors = new Counter("total_errors");

// Gauge: current value at a point in time (e.g., active sessions)
const activeSessions = new Gauge("active_sessions");

// Rate: ratio of truthy values (e.g., cache hit ratio)
const cacheHitRate = new Rate("cache_hits");

// Trend: statistical distribution (e.g., per-endpoint latency)
const checkoutDuration = new Trend("checkout_duration", true); // 'true' = milliseconds display

export default function () {
  const start = Date.now();
  const res = http.post("/checkout", payload);
  checkoutDuration.add(Date.now() - start);
  cacheHitRate.add(res.headers["X-Cache"] === "HIT");
  totalErrors.add(res.status >= 400 ? 1 : 0);
}
```

Custom metrics can be used in thresholds exactly like built-in ones:

```javascript
thresholds: {
  checkout_duration: ["p(95)<800"],
  cache_hits: ["rate>0.5"],   // expect >50% cache hit
  total_errors: ["count<100"],
},
```

---

## 5. Test Lifecycle: init, setup, default, teardown

```javascript
// 1. Init — runs once per VU on startup (NOT inside functions)
//    Used for: imports, parsing env vars, loading files
import http from "k6/http";
const BASE = __ENV.API_URL || "http://localhost:3001";

// 2. setup() — runs ONCE before VU execution begins
//    Return value is passed to default() and teardown()
//    Used for: auth tokens, test data seeding
export function setup() {
  const res = http.post(`${BASE}/auth/token`, JSON.stringify({
    client_id: __ENV.CLIENT_ID,
    client_secret: __ENV.CLIENT_SECRET,
  }), { headers: { "Content-Type": "application/json" } });

  if (res.status !== 200) {
    throw new Error(`setup() auth failed: ${res.status} ${res.body}`);
  }
  return { token: res.json("access_token") };
}

// 3. default(data) — runs for every iteration of every VU
export default function (data) {
  const res = http.get(`${BASE}/api/resource`, {
    headers: { Authorization: `Bearer ${data.token}` },
  });
  check(res, { "status 200": (r) => r.status === 200 });
  sleep(1);
}

// 4. teardown(data) — runs ONCE after all VUs finish
//    Used for: deleting test data, posting results
export function teardown(data) {
  // cleanup any resources created during the test
  http.del(`${BASE}/api/test-session`, null, {
    headers: { Authorization: `Bearer ${data.token}` },
  });
}
```

**Key rule:** `setup()` runs on the k6 orchestrator process, not inside VUs. The returned object is serialized (JSON) and passed to each VU's `default()` call.

---

## 6. HTTP Best Practices

### Batch requests

```javascript
import http from "k6/http";

const responses = http.batch([
  ["GET", `${BASE}/api/users`],
  ["GET", `${BASE}/api/products`],
  ["POST", `${BASE}/api/events`, JSON.stringify({ type: "pageview" }),
    { headers: { "Content-Type": "application/json" } }],
]);
```

### Named requests (for per-URL metrics)

```javascript
const res = http.get(`${BASE}/api/users/${id}`, {
  tags: { name: "GET /api/users/:id" },  // prevents cardinality explosion
});
```

Without `tags.name`, each unique URL (with different IDs) creates a separate metric series.

### Connection reuse

k6 reuses connections by default. To test cold-start behavior:

```javascript
export const options = {
  noConnectionReuse: true,  // simulate fresh connections per iteration
};
```

### Response body parsing

```javascript
const res = http.get(`${BASE}/api/items`);

// Check status before parsing to avoid runtime errors
check(res, { "status 200": (r) => r.status === 200 });

if (res.status === 200) {
  const body = res.json();       // parse JSON
  const items = body.items ?? [];
  check(null, { "has items": () => items.length > 0 });
}
```

---

## 7. Checks vs Thresholds

| Aspect | `check()` | Thresholds |
|--------|-----------|------------|
| When evaluated | Per-iteration, per-request | At end of test (or on abort) |
| Failure effect | Increments `checks` failure counter only | Causes non-zero exit code |
| Best for | Response assertion, data validation | SLO gates, CI pass/fail |
| Combinable | Yes, many per request | Yes, multiple per metric |

A failed `check()` does NOT fail the test by itself. Pair checks with a threshold on the `checks` metric:

```javascript
thresholds: {
  checks: ["rate>0.99"],   // >99% of all checks must pass
},
```

---

## 8. Environment Variables and Configuration

### Passing env vars

```bash
k6 run --env API_URL=https://staging.example.com --env USER=admin script.js
```

### Accessing in script

```javascript
const BASE  = __ENV.API_URL  || "http://localhost:3001";
const EMAIL = __ENV.E2E_EMAIL || "test@example.com";
const PASS  = __ENV.E2E_PASS  || "changeme";
```

### Config files (k6 v0.46+)

```javascript
// k6.config.js  — loaded with: k6 run --config k6.config.js script.js
export const options = {
  scenarios: { /* ... */ },
  thresholds: { /* ... */ },
};
```

### JSON config override

```bash
k6 run --config options.json script.js
```

---

## 9. Groups and Tags

### Groups (logical sections in output)

```javascript
import { group } from "k6";

export default function () {
  group("Login flow", () => {
    const res = http.post(`${BASE}/auth/login`, payload);
    check(res, { "login 200": (r) => r.status === 200 });
  });

  group("Browse products", () => {
    const res = http.get(`${BASE}/api/products`);
    check(res, { "products 200": (r) => r.status === 200 });
  });
}
```

Metrics are automatically scoped to groups in k6 output and Grafana dashboards.

### Tags

```javascript
const res = http.get(`${BASE}/api/products`, {
  tags: {
    name: "GET /api/products",   // URL template (prevents cardinality explosion)
    team: "catalog",
    tier: "critical",
  },
});
```

Threshold on a tag:

```javascript
thresholds: {
  "http_req_duration{tier:critical}": ["p(95)<200"],
},
```

---

## 10. Output and Reporting

### Built-in output formats

```bash
k6 run --out json=results.json script.js        # line-delimited JSON (all metrics)
k6 run --out csv=results.csv script.js          # CSV
k6 run --summary-export=summary.json script.js  # end-of-test aggregate summary
```

### Grafana Cloud / InfluxDB

```bash
k6 run --out cloud script.js                    # Grafana Cloud (requires K6_CLOUD_TOKEN)
k6 run --out influxdb=http://localhost:8086/k6  # InfluxDB v1
```

### Summary export structure

```json
{
  "metrics": {
    "http_req_duration": {
      "type": "trend",
      "contains": "time",
      "values": {
        "avg": 45.3,
        "min": 12.1,
        "med": 38.7,
        "max": 312.4,
        "p(90)": 85.2,
        "p(95)": 112.0,
        "p(99)": 210.5
      },
      "thresholds": {
        "p(95)<200": { "ok": true }
      }
    },
    "http_req_failed": {
      "type": "rate",
      "values": { "rate": 0.002, "passes": 998, "fails": 2 },
      "thresholds": {
        "rate<0.01": { "ok": true }
      }
    }
  }
}
```

---

## 11. Complete Annotated Example: Staged Ramp-Up with Scenarios

```javascript
/**
 * api-load.k6.js
 * Staged ramp-up load test with scenarios, thresholds, and custom metrics.
 * Run: k6 run --env API_URL=http://localhost:3001 --summary-export=summary.json api-load.k6.js
 */
import http from "k6/http";
import { check, sleep, group } from "k6";
import { Rate, Trend } from "k6/metrics";

// ── Custom metrics ───────────────────────────────────────────────────────────
const errorRate     = new Rate("app_errors");
const listDuration  = new Trend("list_endpoint_ms", true);
const writeDuration = new Trend("write_endpoint_ms", true);

// ── Options ──────────────────────────────────────────────────────────────────
export const options = {
  scenarios: {
    // Read-heavy traffic
    reads: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "1m",  target: 10  },  // gentle ramp
        { duration: "3m",  target: 30  },  // ramp to target
        { duration: "5m",  target: 30  },  // sustain
        { duration: "1m",  target: 0   },  // ramp-down
      ],
      gracefulRampDown: "30s",
      exec: "readScenario",
      tags: { scenario: "reads" },
    },

    // Write traffic (lower VU count, starts 2min in)
    writes: {
      executor: "constant-arrival-rate",
      rate: 10,             // 10 writes/sec
      timeUnit: "1s",
      duration: "8m",
      preAllocatedVUs: 10,
      maxVUs: 30,
      startTime: "2m",      // writes start after reads are ramped
      exec: "writeScenario",
      tags: { scenario: "writes" },
    },
  },

  thresholds: {
    // Global latency
    http_req_duration: ["p(95)<300", "p(99)<800"],

    // Per-scenario latency
    "http_req_duration{scenario:reads}":  ["p(95)<200"],
    "http_req_duration{scenario:writes}": ["p(95)<500"],

    // Error budget
    http_req_failed: ["rate<0.01"],
    app_errors:      ["rate<0.01"],

    // Custom metric SLOs
    list_endpoint_ms:  ["p(95)<200"],
    write_endpoint_ms: ["p(95)<500"],

    // All checks must pass
    checks: ["rate>0.99"],
  },
};

// ── Setup: authenticate once ─────────────────────────────────────────────────
const BASE = __ENV.API_URL || "http://localhost:3001";

export function setup() {
  const res = http.post(
    `${BASE}/api/auth/login`,
    JSON.stringify({
      email:    __ENV.E2E_USER_EMAIL    || "loadtest@example.com",
      password: __ENV.E2E_USER_PASSWORD || "loadtest-secret",
    }),
    { headers: { "Content-Type": "application/json" } }
  );

  if (res.status !== 200) {
    throw new Error(`setup: auth failed (${res.status}): ${res.body}`);
  }

  return { token: res.json("token") };
}

// ── Read scenario ─────────────────────────────────────────────────────────────
export function readScenario(data) {
  const headers = {
    Authorization: `Bearer ${data.token}`,
    "Content-Type": "application/json",
  };

  group("List resources", () => {
    const t0  = Date.now();
    const res = http.get(`${BASE}/api/resources`, {
      headers,
      tags: { name: "GET /api/resources" },
    });
    listDuration.add(Date.now() - t0);

    check(res, {
      "list: status 200":   (r) => r.status === 200,
      "list: has results":  (r) => Array.isArray(r.json()),
    });
    errorRate.add(res.status >= 400);
  });

  sleep(1);
}

// ── Write scenario ────────────────────────────────────────────────────────────
export function writeScenario(data) {
  const headers = {
    Authorization: `Bearer ${data.token}`,
    "Content-Type": "application/json",
  };

  group("Create resource", () => {
    const payload = JSON.stringify({ name: `load-test-${Date.now()}`, type: "perf" });
    const t0      = Date.now();
    const res     = http.post(`${BASE}/api/resources`, payload, {
      headers,
      tags: { name: "POST /api/resources" },
    });
    writeDuration.add(Date.now() - t0);

    check(res, {
      "create: status 201": (r) => r.status === 201,
      "create: has id":     (r) => r.json("id") !== undefined,
    });
    errorRate.add(res.status >= 400);
  });

  sleep(0.5);
}

// ── Teardown: clean up test data ──────────────────────────────────────────────
export function teardown(data) {
  // Delete resources created with the load-test- prefix
  const res = http.del(`${BASE}/api/resources?prefix=load-test-`, null, {
    headers: { Authorization: `Bearer ${data.token}` },
  });
  check(res, { "teardown: cleanup ok": (r) => r.status < 300 });
}
```

---

## 12. Gaps Found in Current SKILL.md.tmpl

The current `qa-perf` skill template (v1.0.0) uses `stages:` at the top level. The following patterns are missing or could be improved:

### Gap 1: No `scenarios` usage
The skill template uses the legacy `stages` shorthand. Modern k6 best practice is `scenarios` with explicit executors — especially for multi-endpoint tests where reads and writes need separate configs.

**Current:**
```javascript
stages: [
  { duration: "30s", target: 10 },
  { duration: "60s", target: 50 },
  { duration: "20s", target: 0 },
],
```

**Recommended:**
```javascript
scenarios: {
  load: {
    executor: "ramping-vus",
    stages: [
      { duration: "1m",  target: 10 },
      { duration: "3m",  target: 50 },
      { duration: "1m",  target: 0  },
    ],
    gracefulRampDown: "30s",
  },
},
```

### Gap 2: Thresholds missing `abortOnFail`
For CI pipelines, add `abortOnFail: true` to fail-fast on latency spikes:

```javascript
thresholds: {
  http_req_duration: [
    { threshold: "p(95)<200", abortOnFail: true, delayAbortEval: "30s" },
  ],
},
```

### Gap 3: No per-scenario thresholds
When running multi-endpoint tests, thresholds should be scoped by scenario tag so reads and writes have different SLOs.

### Gap 4: No arrival-rate executor example
Arrival-rate executors (`constant-arrival-rate`, `ramping-arrival-rate`) are essential for throughput-focused tests and are completely absent from the skill.

### Gap 5: Named requests missing
The template does not use `tags: { name: "..." }` on HTTP calls. Without this, each unique URL (parameterized endpoints) creates separate metric series, causing cardinality explosions in dashboards.

### Gap 6: `gracefulRampDown` not set
Without `gracefulRampDown`, VUs are killed mid-iteration during ramp-down, which skews error rates at the tail of a test.

### Gap 7: Short ramp durations in defaults
The default `30s` ramp is often too short for meaningful baseline establishment. Recommend `2m` minimum ramp-up to allow the system to warm up.

### Gap 8: `checks` metric not thresholded
A failed `check()` does not fail the test unless the `checks` rate is thresholded. Add `checks: ["rate>0.99"]`.

---

## 13. Recommended Threshold Baselines by Endpoint Type

| Endpoint Class | p50 | p95 | p99 | Max | Error Rate |
|----------------|-----|-----|-----|-----|------------|
| Static assets / CDN | <50ms | <100ms | <200ms | <500ms | <0.1% |
| API read (GET, cached) | <50ms | <150ms | <300ms | <1s | <1% |
| API read (DB-backed) | <100ms | <200ms | <500ms | <2s | <1% |
| API write (POST/PUT) | <200ms | <500ms | <1s | <3s | <2% |
| Auth endpoints | <150ms | <300ms | <500ms | <2s | <1% |
| Search / aggregation | <200ms | <600ms | <1.5s | <5s | <2% |
| File upload | <500ms | <2s | <5s | <30s | <2% |
| Webhooks / async | <100ms | <300ms | <800ms | <3s | <1% |

---

## 14. k6 CLI Quick Reference

```bash
# Basic run
k6 run script.js

# With env vars
k6 run --env API_URL=https://staging.api.example.com script.js

# Override VU count and duration (ignores options in script)
k6 run --vus 20 --duration 5m script.js

# Export summary JSON
k6 run --summary-export summary.json script.js

# Export raw metrics (line-delimited JSON)
k6 run --out json=metrics.jsonl script.js

# Stream to InfluxDB
k6 run --out influxdb=http://localhost:8086/k6 script.js

# Run specific scenario only (k6 v0.43+)
k6 run --scenario reads script.js

# Quiet mode (no progress bar, just summary)
k6 run --quiet script.js

# No VU teardown on threshold breach
k6 run --no-teardown script.js
```

---

## 15. References

- k6 Scenarios documentation: https://k6.io/docs/using-k6/scenarios/
- k6 Thresholds documentation: https://k6.io/docs/using-k6/thresholds/
- k6 Test types: https://k6.io/docs/test-types/
- k6 HTTP API: https://k6.io/docs/javascript-api/k6-http/
- k6 Metrics: https://k6.io/docs/using-k6/metrics/
- k6 JavaScript API: https://k6.io/docs/javascript-api/
- Grafana k6 Cloud: https://grafana.com/products/cloud/k6/

> Note: This reference was compiled from built-in knowledge (k6 v0.50+ patterns). Cross-reference with https://k6.io/docs for the latest API changes.
