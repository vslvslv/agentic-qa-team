# k6 Patterns & Best Practices
<!-- sources: official docs (grafana.com/docs/k6) + community (awesome-k6, k6 blog, grafana docs) | iteration: 3 | score: 88/100 | date: 2026-04-26 -->

> Generated from official k6 documentation and community sources on 2026-04-26. Re-run `/qa-refine k6` to refresh.

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

### WebSocket Testing  [community]

k6 supports WebSocket load testing via two modules. The newer `k6/websockets` module
implements the WebSocket living standard with a global event loop — prefer it over the
legacy `k6/ws` for new scripts. The key structural difference from HTTP tests: the
`default` function runs **once** per VU, not in a loop — the event loop drives execution.

```javascript
// k6/scripts/websocket-load.js
import { WebSocket } from "k6/experimental/websockets";
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

### 9. `discardResponseBodies` overlooked in high-throughput tests  [community]
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
| `new Gauge(name)` | Last/min/max snapshot value | Queue depth, active sessions |
| `__ENV.KEY` | Read environment variable | Base URLs, credentials |
| `open(path)` | Load a local file (CSV/JSON) as string | Parameterized test data |
| `SharedArray` | Shared read-only array across VUs | Large test-data sets (avoids per-VU copy) |
| `options.scenarios` | Declare named executors | All non-trivial load profiles |
| `options.thresholds` | Pass/fail gates on metrics | Every production script |
| `options.tags` | Default tags added to all metrics | Environment / version labelling |
| `options.discardResponseBodies` | Skip storing response bodies | High-throughput tests (saves memory) |

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
    websocket-load.js     # WebSocket load pattern
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
