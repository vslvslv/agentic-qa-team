# Locust Patterns & Best Practices (Python)
<!-- lang: Python | sources: official | community | mixed | iteration: 0 | score: 88/100 | date: 2026-04-26 -->

## Core Principles

1. **User-centric model** — every simulated user is a `User` class instance; tasks are methods
   decorated with `@task`. This maps directly to real user behaviour.
2. **Greenlets, not threads** — Locust runs tasks inside gevent greenlets. Blocking I/O must use
   gevent-patched libraries or the built-in `HttpSession`; raw `requests` without patching will
   stall the event loop.
3. **Think time is mandatory** — omitting `wait_time` drives unrealistic 100 % CPU loads and
   saturates the target before user count ramp-up completes.
4. **Assertions in tasks, not after** — use `catch_response` context manager inside the task so
   failures are counted in Locust statistics, not silently swallowed.
5. **Parameterise, don't hard-code** — host, credentials, and thresholds belong in environment
   variables or `--host` CLI flags, never in source files.

---

## Recommended Patterns

### HttpUser vs FastHttpUser

`HttpUser` wraps the standard `requests` library with gevent patching. `FastHttpUser` uses
`geventhttpclient` which is 5–10x faster for high-concurrency tests, but does not support all
`requests` features (e.g. complex session adapters, `hooks`).

```python
# Standard — best for correctness and `requests` ecosystem
from locust import HttpUser, task, between

class BrowseUser(HttpUser):
    wait_time = between(1, 3)
    host = "https://api.example.com"

    @task
    def get_products(self):
        self.client.get("/products")


# Fast — use when simulating > 500 concurrent users on one node
from locust import task, between
from locust.contrib.fasthttp import FastHttpUser

class HighConcurrencyUser(FastHttpUser):
    wait_time = between(0.5, 1.5)
    host = "https://api.example.com"

    @task
    def get_products(self):
        self.client.get("/products")
```

> [community] Switch to `FastHttpUser` only after profiling — the debug story is harder because
> `geventhttpclient` errors surface as low-level socket exceptions, not `requests.HTTPError`.

---

### @task with weight

Assign relative weights to tasks to model realistic traffic mix. A weight of `3` means a task
runs roughly three times as often as a task with weight `1`.

```python
from locust import HttpUser, task, between

class ShopUser(HttpUser):
    wait_time = between(1, 5)

    @task(10)          # 10 / (10+3+1) = ~71 % of requests
    def browse_catalog(self):
        self.client.get("/catalog")

    @task(3)           # ~21 %
    def view_product(self):
        product_id = self.environment.parsed_options.product_id
        self.client.get(f"/products/{product_id}")

    @task(1)           # ~7 %
    def add_to_cart(self):
        self.client.post("/cart", json={"sku": "ABC-001", "qty": 1})
```

---

### on_start / on_stop lifecycle

`on_start` runs once per simulated user after spawn, before any task. Use it for login or
session setup. `on_stop` runs when the user stops (test end or manual stop).

```python
import os
from locust import HttpUser, task, between

class AuthenticatedUser(HttpUser):
    wait_time = between(1, 3)

    def on_start(self):
        """Called once per user — acquire auth token."""
        resp = self.client.post("/auth/login", json={
            "username": os.getenv("LOAD_USER", "testuser"),
            "password": os.getenv("LOAD_PASS", "secret"),
        })
        resp.raise_for_status()
        token = resp.json()["access_token"]
        self.client.headers.update({"Authorization": f"Bearer {token}"})

    def on_stop(self):
        """Called once per user on teardown."""
        self.client.post("/auth/logout")

    @task
    def fetch_dashboard(self):
        self.client.get("/dashboard")
```

> [community] Do not share a single token across all users — Locust spawns hundreds of user
> instances and concurrent logout/login races cause 401 cascades. Store the token on `self`.

---

### wait_time strategies

| Strategy | Import | Use case |
|---|---|---|
| `between(min, max)` | `from locust import between` | Simulates natural think time with random jitter |
| `constant(n)` | `from locust import constant` | Deterministic pacing, good for baseline benchmarks |
| `constant_pacing(n)` | `from locust import constant_pacing` | Keeps throughput at 1 task per `n` seconds per user regardless of task duration |
| Custom callable | any | Complex schedules (e.g. ramp-then-hold) |

```python
from locust import HttpUser, task, constant_pacing

class PacedUser(HttpUser):
    # Each user attempts exactly 1 task every 2 seconds.
    # If the task takes longer than 2 s, the next fires immediately (no negative wait).
    wait_time = constant_pacing(2)

    @task
    def ping(self):
        self.client.get("/health")
```

> [community] `constant_pacing` is the closest Locust equivalent to k6's `arrival-rate` executor —
> use it when SLA is defined in requests-per-second, not concurrent users.

---

### catch_response — response time assertions

Wrap requests in `catch_response=True` to override pass/fail and record custom failure messages.
Without this, a 200 response that violates an SLA is silently counted as success.

```python
from locust import HttpUser, task, between

class SlaUser(HttpUser):
    wait_time = between(1, 2)

    @task
    def checkout(self):
        with self.client.get(
            "/checkout/summary",
            catch_response=True,
            name="/checkout/summary",   # group dynamic URLs under one label
        ) as resp:
            if resp.elapsed.total_seconds() > 2.0:
                resp.failure(
                    f"Checkout exceeded 2 s SLA: {resp.elapsed.total_seconds():.2f}s"
                )
            elif resp.status_code != 200:
                resp.failure(f"Unexpected status {resp.status_code}")
            else:
                resp.success()
```

> [community] Always pass `name=` when the URL contains dynamic path segments like `/orders/123`.
> Without it, every unique ID creates a separate statistics row and the report becomes unreadable.

---

### events hook for custom metrics

Locust exposes a rich event system. Use `request` and `test_start`/`test_stop` for custom
instrumentation without modifying task code.

```python
import time
from locust import HttpUser, task, between, events

# --- custom counter registered at module import time ---
slow_requests = 0

@events.request.add_listener
def on_request(request_type, name, response_time, response_length,
               exception, context, **kwargs):
    global slow_requests
    if response_time > 1000:          # ms
        slow_requests += 1

@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    print(f"\n[custom] Requests > 1 s: {slow_requests}")
    if slow_requests > 50:
        environment.process_exit_code = 1   # fail the CI job

class MyUser(HttpUser):
    wait_time = between(1, 2)

    @task
    def homepage(self):
        self.client.get("/")
```

> [community] `environment.process_exit_code = 1` in `test_stop` is the canonical way to fail a
> CI pipeline on custom thresholds — much cleaner than parsing CSV output in a shell script.

---

### Headless CLI flags

Run Locust without the web UI for CI pipelines:

```bash
# Minimal headless run: 50 users, spawn rate 5/s, run for 60 s
locust \
  --headless \
  --users 50 \
  --spawn-rate 5 \
  --run-time 60s \
  --host https://staging.example.com \
  --locustfile locustfile.py \
  --csv results/run1 \
  --html results/run1.html \
  --exit-code-on-error 1

# Run specific User class only (multi-class locustfile)
locust --headless -u 100 -r 10 -t 2m --class-picker ShopUser
```

Key flags reference:

| Flag | Short | Purpose |
|---|---|---|
| `--headless` | | Disable browser UI |
| `--users N` | `-u N` | Peak concurrent users |
| `--spawn-rate N` | `-r N` | Users to spawn per second |
| `--run-time T` | `-t T` | Stop after duration (e.g. `30s`, `5m`, `1h`) |
| `--csv PREFIX` | | Write stats/failures/history CSVs |
| `--html PATH` | | Write HTML report |
| `--exit-code-on-error 1` | | Non-zero exit if any request fails |
| `--loglevel` | | `DEBUG`/`INFO`/`WARNING` |

---

### CSV output format

With `--csv results/prefix`, Locust writes three files:

- `prefix_stats.csv` — per-endpoint aggregated stats (RPS, p50/p90/p99, failures)
- `prefix_stats_history.csv` — time-series: one row per 10-second interval per endpoint
- `prefix_failures.csv` — unique failure messages with occurrence count

Sample `_stats.csv` columns:
```
Type,Name,Request Count,Failure Count,Median Response Time,
Average Response Time,Min Response Time,Max Response Time,
Average Content Size,Requests/s,Failures/s,
50%,66%,75%,80%,90%,95%,98%,99%,99.9%,99.99%,100%
```

> [community] Parse `_stats_history.csv` rather than `_stats.csv` when you need to detect
> latency degradation mid-test — the aggregated file hides time-of-failure information.

---

### Environment parametrization with os.getenv

Never hard-code hostnames or secrets. Use environment variables so the same locustfile works
across dev, staging, and production load environments.

```python
import os
from locust import HttpUser, task, between

# Read at module level — available to all User instances
BASE_HOST = os.getenv("TARGET_HOST", "https://localhost:8080")
PAGE_SIZE  = int(os.getenv("PAGE_SIZE", "20"))
API_KEY    = os.getenv("API_KEY", "")         # must be set in CI secrets

class ApiUser(HttpUser):
    host = BASE_HOST
    wait_time = between(
        float(os.getenv("WAIT_MIN", "0.5")),
        float(os.getenv("WAIT_MAX", "2.0")),
    )

    @task
    def list_orders(self):
        self.client.get(
            "/orders",
            params={"limit": PAGE_SIZE},
            headers={"X-API-Key": API_KEY},
        )
```

CI invocation:

```bash
TARGET_HOST=https://staging.example.com \
API_KEY=${{ secrets.LOAD_API_KEY }} \
locust --headless -u 200 -r 20 -t 3m --csv results/staging
```

---

### Distributed Locust (master / worker)

Scale beyond a single machine by running one master and N workers. Workers run tasks; master
aggregates results and serves the web UI.

```bash
# On the master node (serves UI on :8089, coordinates workers on :5557)
locust \
  --master \
  --master-bind-host 0.0.0.0 \
  --master-bind-port 5557 \
  --expect-workers 4 \
  --headless -u 2000 -r 50 -t 5m \
  --host https://prod-loadtest.example.com \
  --csv results/distributed

# On each worker node (4 workers, same locustfile)
locust \
  --worker \
  --master-host <MASTER_IP> \
  --master-port 5557 \
  --locustfile locustfile.py
```

Docker Compose example (`docker-compose.locust.yml`):

```yaml
services:
  master:
    image: locustio/locust:2.x
    command: >
      --master --headless
      -u 1000 -r 50 -t 3m
      --host https://staging.example.com
      --csv /results/run
      --expect-workers 2
    volumes: ["./results:/results", "./locustfile.py:/home/locust/locustfile.py"]
    ports: ["8089:8089"]

  worker:
    image: locustio/locust:2.x
    command: --worker --master-host master
    volumes: ["./locustfile.py:/home/locust/locustfile.py"]
    depends_on: [master]
    deploy:
      replicas: 2
```

> [community] `--expect-workers N` prevents the test from starting before all workers connect.
> Omit it in flaky network environments and use `--expect-workers-max-wait` instead.

---

## Real-World Gotchas [community]

1. **Greenlet starvation from blocking calls** [community] — calling synchronous, non-gevent-patched
   libraries (e.g. `psycopg2`, `boto3` without patching) inside a task blocks the entire greenlet
   thread, freezing all other simulated users on that process. Use `gevent.monkey.patch_all()` at
   the top of the locustfile, or offload blocking work to a `ThreadPoolExecutor`.

2. **Token expiry mid-test** [community] — JWTs issued in `on_start` expire during long-running
   tests. Users receive 401 errors that inflate the failure count without surfacing the real cause.
   Implement token refresh by checking `resp.status_code == 401` inside a `catch_response` block
   and re-authenticating before retrying.

3. **DNS resolution not cached per user** [community] — under high concurrency, repeated DNS lookups
   for the same hostname consume significant time and can cause timeout spikes. Run Locust workers
   behind a local DNS cache (e.g. `nscd` or `dnsmasq`) or resolve the IP once and pass `--host`
   with the resolved address.

4. **Aggregate statistics hide ramp-up noise** [community] — `_stats.csv` averages across the
   entire run, including the ramp-up phase when users are still connecting. Latency during ramp-up
   is lower because concurrency is lower; this artificially deflates reported p99. Use
   `_stats_history.csv` and discard the first N rows corresponding to ramp-up duration.

5. **File descriptor exhaustion on workers** [community] — each simulated user holds one or more
   open TCP connections. At 1000+ users per worker, the OS default `ulimit -n 1024` is hit,
   causing `OSError: [Errno 24] Too many open files`. Set `ulimit -n 65536` in the worker
   container/host before starting Locust.

6. **`on_start` failures are silent** [community] — if `on_start` raises an unhandled exception,
   the user is silently removed from the pool. This masks auth failures during high-load tests.
   Wrap `on_start` in a try/except and call `self.environment.runner.quit()` or log prominently
   so the operator knows users are not spawning correctly.

7. **Static content inflates RPS** [community] — if the locustfile naively fetches every asset
   on a page (images, JS, CSS), RPS appears much higher than meaningful application transactions.
   Separate static-asset tasks into a lower-weight `@task` or exclude them entirely to keep
   business-transaction metrics clean.

---

## CI Considerations

```yaml
# GitHub Actions example
- name: Run Locust load test
  env:
    TARGET_HOST: ${{ vars.STAGING_HOST }}
    API_KEY: ${{ secrets.LOAD_API_KEY }}
  run: |
    pip install locust
    ulimit -n 65536
    locust \
      --headless \
      --users 100 \
      --spawn-rate 10 \
      --run-time 90s \
      --host "$TARGET_HOST" \
      --csv results/locust \
      --html results/locust.html \
      --exit-code-on-error 1

- name: Upload Locust report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: locust-results
    path: results/
```

Key CI considerations:

- **Set `ulimit -n`** before the locust command on Linux runners (see gotcha 5).
- **Use `--exit-code-on-error 1`** so the CI step fails on any request failure.
- **Gate on p99** via the `test_stop` event hook (see events pattern above) rather than
  relying solely on `--exit-code-on-error`, which only checks for non-zero failure counts.
- **Upload the HTML report** as a CI artifact — it is the most readable post-mortem artefact.
- **Separate load tests from unit tests** in CI — run them in a dedicated job with
  `if: github.ref == 'refs/heads/main'` or nightly schedule to avoid blocking PRs.
- **Pin the Locust version** in `requirements.txt` (`locust==2.x.y`) to prevent silent
  behaviour changes between CI runs.

---

## Key APIs

| Method / Class | Purpose | When to use |
|---|---|---|
| `HttpUser` | Base class with `requests`-backed HTTP client | Default choice; full `requests` compatibility |
| `FastHttpUser` | Base class with `geventhttpclient` | > 500 concurrent users per worker node |
| `@task(weight)` | Marks a method as a Locust task | Every action a simulated user performs |
| `self.client.get/post/put/delete(...)` | HTTP verbs on the session | All HTTP requests inside tasks |
| `catch_response=True` | Override success/failure on a request | SLA assertions, custom failure messages |
| `resp.failure(msg)` | Mark response as failed with message | Inside `catch_response` context |
| `resp.success()` | Mark response as succeeded | Inside `catch_response` when status is unexpected but OK |
| `name="..."` | Group requests under a custom label | Dynamic URLs with path parameters |
| `on_start(self)` | User lifecycle hook — runs once at spawn | Login, session setup, test data fetch |
| `on_stop(self)` | User lifecycle hook — runs once at teardown | Logout, cleanup |
| `between(min, max)` | Random wait between tasks | Simulating human think time |
| `constant(n)` | Fixed wait between tasks | Deterministic benchmarks |
| `constant_pacing(n)` | Target throughput per user | RPS-defined SLA testing |
| `@events.request.add_listener` | Hook into every request event | Custom metrics, alerting, reporting |
| `@events.test_stop.add_listener` | Hook at test end | Threshold checks, CI exit code |
| `environment.process_exit_code` | Set CI exit code from Python | Fail pipeline on custom SLA breach |
| `--headless` CLI flag | Disable web UI | CI / automated runs |
| `--csv PREFIX` CLI flag | Write stats/failures/history CSVs | Post-test analysis, trending |
| `--master` / `--worker` CLI flags | Distributed mode coordination | Scaling beyond one machine |
