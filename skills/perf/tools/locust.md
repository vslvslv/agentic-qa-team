# Locust — Performance Test Patterns

> Reference: [locust-patterns.md](../references/locust-patterns.md)

Locust test files are Python. The entrypoint is a `locustfile.py` (or any `.py` file
passed via `--locustfile`). Always Python 3.8+.

## Script Template

```python
# locustfile.py
import os
from locust import HttpUser, task, between, events

BASE = os.getenv("API_URL", "http://localhost:3001")

class ApiUser(HttpUser):
    host = BASE
    wait_time = between(1, 3)  # random wait between tasks (seconds)
    token: str = ""

    def on_start(self):
        """Login once per VU before tasks run."""
        resp = self.client.post("/api/auth/login", json={
            "email": os.getenv("E2E_USER_EMAIL", "admin@example.com"),
            "password": os.getenv("E2E_USER_PASSWORD", "password123"),
        })
        resp.raise_for_status()
        self.token = resp.json()["token"]
        self.client.headers.update({"Authorization": f"Bearer {self.token}"})

    @task(3)
    def list_users(self):
        """Weight 3 — most frequent operation."""
        with self.client.get("/api/users", catch_response=True) as resp:
            if resp.status_code != 200:
                resp.failure(f"Expected 200, got {resp.status_code}")
            elif not isinstance(resp.json(), list):
                resp.failure("Response is not a list")

    @task(1)
    def get_profile(self):
        """Weight 1 — less frequent."""
        with self.client.get("/api/profile", catch_response=True) as resp:
            if resp.status_code != 200:
                resp.failure(f"Expected 200, got {resp.status_code}")
```

## Multi-Class Pattern (mixed load)

```python
class LightUser(HttpUser):
    weight = 3       # 3x more light users than heavy
    wait_time = between(2, 5)
    @task def browse(self): self.client.get("/api/products")

class HeavyUser(HttpUser):
    weight = 1
    wait_time = between(0.5, 1)
    @task def search(self): self.client.get("/api/products?q=item&sort=price")
```

## Headless Run Flags

```bash
locust --headless \
  --locustfile locustfile.py \
  -u 50 \               # total users
  -r 5 \                # spawn rate (users/second)
  --run-time 2m \       # test duration
  --csv "$_TMP/locust" \ # writes locust_stats.csv, locust_failures.csv
  --only-summary \      # suppress per-request output in CI
  --exit-code-on-error 1
```

## CI Notes

- `--exit-code-on-error 1` fails CI when any request has errors
- `--only-summary` suppresses verbose per-request output
- `--html "$_TMP/locust-report.html"` produces a standalone HTML report
- Use `FastHttpUser` instead of `HttpUser` for CPU-bound scenarios with many VUs

## Execute Block

```bash
export API_URL="$_API_URL"
export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"

_LOCUST_FILE=$(find . -name "locustfile.py" ! -path "*/node_modules/*" 2>/dev/null | head -1)
_LOCUST_FILE="${_LOCUST_FILE:-locust/locustfile.py}"

if command -v locust &>/dev/null && [ -f "$_LOCUST_FILE" ]; then
  echo "=== Running Locust: $_LOCUST_FILE ==="
  locust --headless \
    --locustfile "$_LOCUST_FILE" \
    -u 20 -r 2 --run-time 90s \
    --csv "$_TMP/locust" \
    --only-summary \
    --exit-code-on-error 1 \
    2>&1 | tee "$_TMP/locust-output.txt"
  echo "LOCUST_EXIT_CODE: $?"
fi
```

## Result Parsing

```bash
[ -f "$_TMP/locust_stats.csv" ] && python3 - << 'PYEOF'
import csv, os
tmp = os.environ.get("TEMP") or os.environ.get("TMP") or "/tmp"
with open(f"{tmp}/locust_stats.csv") as f:
    for row in csv.DictReader(f):
        if row["Name"] == "Aggregated":
            print(f"Requests: {row['Request Count']}  Failures: {row['Failure Count']}")
            print(f"Median: {row['Median Response Time']}ms  95th: {row['95%']}ms")
            print(f"RPS: {row['Requests/s']}")
PYEOF
```
