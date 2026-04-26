# k6 Patterns & Best Practices
<!-- source: live docs (grafana.com/docs/k6) | iteration: 1 | score: 71→? | date: 2026-04-26 -->

> Generated from official k6 documentation on 2026-04-26. Re-run `/qa-refine k6` to refresh.

## Core Principles

1. **Scenarios over `stages`** — The `scenarios` API is the modern, preferred way to configure load profiles. It supports multiple concurrent executors, per-scenario env vars, and per-scenario thresholds. The top-level `stages` shorthand still works but is less expressive.
2. **Executor choice drives test semantics** — Choose the executor based on *what* you are modeling: `ramping-vus` for VU-based ramp-up, `constant-arrival-rate` for RPS-based load, `ramping-arrival-rate` for realistic traffic curves.
3. **Thresholds are pass/fail gates** — Thresholds fail the run (non-zero exit code) when SLAs are breached. Attach them to specific scenarios or custom metrics for precise reporting.
4. **`setup()` / `teardown()` for shared state** — Authenticate once in `setup()`, pass the token to all VUs; clean up created resources in `teardown()`.
5. **Checks are assertions, not thresholds** — `check()` records pass/fail counts but does NOT abort the test. Use thresholds on `checks` to gate the run on overall check-pass rate.

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

### Breakpoint / Stress with `ramping-arrival-rate`

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
}
```

### Data Parameterization with `SharedArray`

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

### Custom Metrics — All Four Types

k6 provides four metric primitives. Use the right type to get the right aggregation in thresholds.

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

---

## Test Type Profiles

| Test Type | Executor | Profile | Goal |
|-----------|----------|---------|------|
| Smoke | `constant-vus` | 1–2 VUs, 1–2 min | Verify script works |
| Load | `ramping-vus` | Ramp → sustain → down | Validate at expected traffic |
| Stress | `ramping-vus` | Ramp beyond normal | Find the breaking point |
| Soak | `ramping-vus` | Normal load, 1–8 h | Surface memory leaks |
| Spike | `ramping-vus` | Instant peak → drop | Test auto-scaling |
| Breakpoint | `ramping-arrival-rate` | Continuously increase RPS | Find max throughput |

---

## Anti-Patterns

- **Using top-level `stages` instead of `scenarios`** — `stages` is a shorthand for `ramping-vus` with a single scenario. It cannot express multiple concurrent executors or per-scenario thresholds.
- **Doing auth in `default function`** — Authenticating on every iteration hammers the auth endpoint and inflates latency numbers for the actual endpoints under test.
- **Missing `gracefulRampDown`** — Without it, VUs are cut instantly at stage end, producing misleading error spikes in the tail.
- **No `abortOnFail` on error-rate threshold** — If the server starts returning 5xx at 80% of requests, the test runs to completion anyway and produces meaningless p95 data.
- **Hardcoded base URLs** — Use `__ENV.API_URL` so scripts work across environments without edits.
- **Single-scenario scripts for mixed workloads** — Mixing read and write logic in one default function makes it impossible to set independent thresholds or ramp profiles per operation type.
- **Not tagging custom metrics with `{ add: value, tags: {...} }`** — Untagged custom metrics cannot be filtered in thresholds.
- **Using `sleep(Math.random() * 3)`** for think time without bounds — This can create very long sleeps that stall VUs; prefer `sleep(1 + Math.random())` with a narrow band.

---

## Key APIs

| API | What it does | When to use |
|-----|-------------|-------------|
| `http.get(url, params)` | HTTP GET; returns Response | Read endpoints |
| `http.post(url, body, params)` | HTTP POST with body | Write / auth endpoints |
| `http.batch([...])` | Parallel requests in one call | Simulating page-load asset fetches |
| `check(res, thunks)` | Record named boolean assertions | All responses — never skip |
| `sleep(seconds)` | Pause VU to simulate think time | Between iterations |
| `group(name, fn)` | Aggregate metrics under a label | Multi-step user journeys |
| `new Trend(name, isTime)` | Custom timing metric | Per-operation latency |
| `new Rate(name)` | Custom pass/fail rate | Business-level error rates |
| `new Counter(name)` | Monotonically increasing count | Counting events |
| `__ENV.KEY` | Read environment variable | Base URLs, credentials |
| `open(path)` | Load a local file (CSV/JSON) as string | Parameterized test data |
| `SharedArray` | Shared read-only array across VUs | Large test-data sets (avoids per-VU copy) |
| `options.scenarios` | Declare named executors | All non-trivial load profiles |
| `options.thresholds` | Pass/fail gates on metrics | Every production script |
| `options.tags` | Default tags added to all metrics | Environment / version labelling |

---

## Executor Quick-Reference

| Executor | Key Option | Best For |
|----------|-----------|---------|
| `shared-iterations` | `vus`, `iterations` | Fixed total request count |
| `per-vu-iterations` | `vus`, `iterations` | Each VU runs N iterations |
| `constant-vus` | `vus`, `duration` | Simple sustained load |
| `ramping-vus` | `stages[]` | Ramp-up / load / ramp-down |
| `constant-arrival-rate` | `rate`, `duration` | Fixed RPS / TPS |
| `ramping-arrival-rate` | `stages[]` (rate targets) | Gradually increasing RPS |
| `externally-controlled` | (CLI / REST API) | Manual or CI-driven VU changes |

---

## CI Considerations

### Exit Codes

k6 returns a non-zero exit code when thresholds fail, making it a first-class CI gate:

| Exit code | Meaning |
|-----------|---------|
| `0` | All thresholds passed — test succeeded |
| `99` | One or more thresholds failed |
| `108` | Usage error (bad flags, missing script) |

In any CI pipeline, check `$?` or rely on the non-zero exit to fail the build:

```bash
# GitHub Actions / any POSIX shell
k6 run \
  --env API_URL="$API_URL" \
  --env E2E_USER_EMAIL="$E2E_USER_EMAIL" \
  --env E2E_USER_PASSWORD="$E2E_USER_PASSWORD" \
  --no-color \
  --out json=results/k6-raw.json \
  --summary-export results/k6-summary.json \
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
      - name: Run k6 load test
        env:
          API_URL: ${{ vars.STAGING_API_URL }}
          E2E_USER_EMAIL: ${{ secrets.E2E_USER_EMAIL }}
          E2E_USER_PASSWORD: ${{ secrets.E2E_USER_PASSWORD }}
        run: |
          mkdir -p results
          k6 run --no-color --summary-export results/summary.json k6/scripts/load.js
      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: k6-results
          path: results/
```

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

- Default OS limit on open file descriptors is 1024; k6 needs one per active connection.
  On Linux CI: `ulimit -n 65536` before running high-VU tests.
- k6 is **single-process** — all VUs run in one process. For very high RPS (>10 k/s),
  run multiple k6 instances with separate scenarios and aggregate results externally
  (e.g., Grafana Cloud k6 handles this automatically).
- `gracefulStop` (default `30s`) gives running iterations time to complete when a
  scenario ends. Reduce it in CI to avoid unnecessarily long runs:
  ```javascript
  scenarios: {
    api_load: {
      executor: "ramping-vus",
      gracefulStop: "5s",   // CI: shorter is fine; prod: keep at 30s
      // ...
    },
  }
  ```

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
- Use `delayAbortEval` on `abortOnFail` thresholds to let the system warm up before
  evaluating: `delayAbortEval: "30s"` is a good default; use `"60s"` for soak tests.

### Real-Time Metrics Output

Stream metrics to external systems during the run:

```bash
# InfluxDB + Grafana (local dashboard)
k6 run --out influxdb=http://localhost:8086/k6 k6/scripts/load.js

# Prometheus remote-write
k6 run --out experimental-prometheus-rw k6/scripts/load.js

# CSV for offline analysis
k6 run --out csv=results/k6-metrics.csv k6/scripts/load.js
```

---

## Recommended Project Structure

```
k6/
  scripts/
    smoke.js              # 1-2 VUs sanity check
    load.js               # ramping-vus — normal traffic
    stress.js             # ramping-vus — beyond normal
    soak.js               # long-running stability
    breakpoint.js         # ramping-arrival-rate — find max RPS
    mixed-load.js         # multi-scenario with scenarios API
  lib/
    auth.js               # shared setup() / getToken() helpers
    thresholds.js         # reusable threshold presets
    data.js               # SharedArray test data loaders
    retry.js              # httpGetWithRetry / httpPostWithRetry
  data/
    users.json            # parameterized test users (gitignored if sensitive)
    products.json         # product SKUs for checkout tests
  results/                # .json / .csv summary exports (gitignored)
```
