# k6 Patterns & Best Practices (JavaScript)
<!-- lang: JavaScript | sources: official | community | mixed | iteration: 10 | score: 100/100 | date: 2026-04-28 -->

> Generated from official k6 documentation and community sources on 2026-04-27. Verified against k6 v1.7.1 (latest stable). Re-run `/qa-refine k6` to refresh.

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
}
```

### HTTP `params` — Per-Request Configuration

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

k6's stable WebSocket module (`k6/websockets`, stable since k6 v0.56) implements the
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

### gRPC Load Testing  [community]

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

### 17. GraphQL 200-response errors bypass HTTP error thresholds  [community]
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
- `k6/experimental/redis` → deprecated entirely (no stable replacement yet; use xk6-redis extension)
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
Teams declare the system "fast" based on publish latency, while users wait 45 seconds.
**WHY:** k6 measures HTTP response time, not end-to-end business transaction time. For
async workflows, the publish API's response time is entirely decoupled from the true SLO.
**Fix:** Implement a polling loop after publish to measure actual completion time (see
Async/Eventual Consistency Testing pattern above). Threshold on the custom `Trend` metric,
not on `http_req_duration`.

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

> **[community]:** k6 gRPC streaming does NOT support bidirectional streaming in the standard
> `k6/net/grpc` module — only server-side and client-side streaming. For bidirectional use
> the `k6/experimental/grpc` module (which graduates to stable in future versions). Always
> verify the streaming mode supported before planning a load test against a streaming endpoint.

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
```

> **[community]:** `k6 inspect` outputs scenario configuration and VU count without running
> the test. Use it in CI to assert that a script has the expected structure before
> wasting a full test run on a malformed options object.

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
    "browser_web_vital_fid": ["p(75)<300"],
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

### k6/execution Module — Test Introspection

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
produce meaningless results. The test exits with a non-zero code.

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
| `exec.test.abort(msg)` | function | Gracefully abort the entire test |



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
> `--no-thresholds --no-summary` to avoid duplicate computation. These flags skip the
> local summary output — useful when the external system handles alerting.

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
> for type annotations. Run `k6 run script.ts` directly. Note: k6's TypeScript support is
> transpilation-only (esbuild strips types but does NOT type-check). For compile-time
> safety, add a `tsc --noEmit` pre-check step in CI before running k6.
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

