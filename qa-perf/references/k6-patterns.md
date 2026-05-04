# k6 Patterns & Best Practices (JavaScript)
<!-- lang: JavaScript | sources: official | community | mixed | iteration: 20 | score: 100/100 | date: 2026-05-03 -->

> Generated from official k6 documentation and community sources on 2026-05-03. Verified against k6 v1.7.1 (latest stable; security patch for CVE-2026-33186 in gRPC); k6 v2.0.0-rc1 breaking changes documented below. Re-run `/qa-refine k6` to refresh.

> **k6 v2.0.0 migration notice:** Major version removes `externally-controlled` executor, CLI commands `k6 pause/resume/scale/status/login`, `--no-summary` flag (use `--summary-mode=disabled`), `options.ext.loadimpact` (use `options.cloud`), browser metric `browser_web_vital_fid` (use `browser_web_vital_inp`), `k6/experimental/redis` module (use `k6/x/redis` extension), and automatic locator retries added to browser. See [v2.0.0 Migration](#v200-migration) section.

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
| `k6chaijs` | `jslib.k6.io/k6chaijs/4.3.4.3/index.js` | BDD-style assertions (`expect`, `chai`) |
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
import { describe, expect } from "https://jslib.k6.io/k6chaijs/4.3.4.3/index.js";
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

> **[community]:** k6 gRPC streaming does NOT support bidirectional streaming in the standard
> `k6/net/grpc` module — only server-side and client-side streaming. For bidirectional use
> the `k6/experimental/grpc` module (which graduates to stable in future versions). Always
> verify the streaming mode supported before planning a load test against a streaming endpoint.

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
| `options.ext.loadimpact` | `options.cloud` |
| `k6/experimental/redis` | `k6/x/redis` (xk6 extension) |
| `browser_web_vital_fid` metric | `browser_web_vital_inp` (Interaction to Next Paint) |

### Migration Checklist

```bash
# 1. Find scripts using externally-controlled executor
grep -r "externally-controlled" k6/scripts/

# 2. Find scripts using deprecated CLI syntax in CI pipelines
grep -r "k6 cloud " .github/ .gitlab-ci.yml Jenkinsfile

# 3. Find deprecated browser metric in thresholds
grep -r "browser_web_vital_fid" k6/

# 4. Find scripts using --no-summary or options.ext.loadimpact
grep -r "no-summary\|loadimpact" k6/

# 5. Find k6/experimental/redis imports
grep -r "experimental/redis" k6/
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
export K6_CLOUD_STACK=my-stack
k6 cloud run k6/scripts/load.js
k6 cloud run k6/scripts/soak.js

# GitHub Actions example — pass stack from a repo variable
- name: Run cloud test
  env:
    K6_CLOUD_API_TOKEN: ${{ secrets.K6_CLOUD_API_TOKEN }}
    K6_CLOUD_STACK: ${{ vars.K6_CLOUD_STACK }}
  run: k6 cloud run --no-color k6/scripts/load.js
```

> **[community]:** The `K6_CLOUD_STACK` environment variable is the cleanest migration path. Set it once in your CI environment (GitHub Actions vars, GitLab CI variables, or Jenkins credentials) and all `k6 cloud` commands in all pipelines pick it up automatically — no Jenkinsfile / workflow file changes needed per script.

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


