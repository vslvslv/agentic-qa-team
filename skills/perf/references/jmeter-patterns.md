# JMeter Patterns & Best Practices (XML / Shell)
<!-- lang: XML+Shell | sources: official (jmeter.apache.org) + community (training knowledge) | iteration: 1 | score: 88/100 | date: 2026-04-26 -->

> Generated from official Apache JMeter documentation and community best practices on 2026-04-26.
> Re-run `/qa-refine jmeter` to refresh. Loaded automatically when `_PERF_TOOL=jmeter`.

---

## Core Principles

1. **Always run non-GUI (`-n`) in CI** — The GUI is for test design only. Running JMeter with the GUI active in CI wastes ~30 % memory and skews results with rendering overhead.
2. **Parameterise everything via `-J` flags** — Hard-coding thread counts or host names in `.jmx` files makes the plan untestable across environments. Expose every tunable as a JMeter property and pass it at the command line.
3. **Use `CSV Data Set Config` for realistic data** — Static request bodies produce unrealistic cache-hit rates and may hit server-side duplicate-detection. Feed unique data from CSV for every scenario.
4. **Assertions are for correctness, not performance** — Response Assertions add CPU and memory overhead. Keep them targeted (status code + a key field), and disable them during high-concurrency stress runs if throughput accuracy matters more.
5. **Separate the `.jtl` result file from the dashboard** — Always write raw results to a `.jtl` and generate the HTML dashboard as a post-processing step (`-e -o`). This lets you re-generate the report without re-running the test.

---

## Thread Group Settings

The Thread Group is the top-level load driver. Every HTTP test needs at least one.

### Key properties

| Property | Element | Meaning |
|----------|---------|---------|
| `num_threads` | Thread Group | Total VUs (virtual users) |
| `ramp_time` | Thread Group | Seconds to reach full `num_threads` |
| `loops` | LoopController | Iterations per thread; `-1` = infinite |
| `scheduler` | Thread Group | Enable time-based duration instead of loop count |
| `duration` | Thread Group (scheduler) | Test duration in seconds |
| `delay` | Thread Group (scheduler) | Seconds before threads start |

**JMX snippet — parameterised Thread Group:**
```xml
<ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="API Load">
  <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
    <boolProp name="LoopController.continue_forever">false</boolProp>
    <stringProp name="LoopController.loops">${__P(loops,10)}</stringProp>
  </elementProp>
  <stringProp name="ThreadGroup.num_threads">${__P(threads,50)}</stringProp>
  <stringProp name="ThreadGroup.ramp_time">${__P(ramp,30)}</stringProp>
  <boolProp name="ThreadGroup.scheduler">true</boolProp>
  <stringProp name="ThreadGroup.duration">${__P(duration,300)}</stringProp>
  <stringProp name="ThreadGroup.delay">0</stringProp>
</ThreadGroup>
```

Pass values at runtime:
```bash
jmeter -n -t plan.jmx \
  -Jthreads=100 -Jramp=60 -Jduration=600 -Jloops=-1 \
  -l results/run.jtl
```

**[community] Ramp-up is per thread group, not global.** If you have multiple Thread Groups and want a staggered start, set a `delay` on each group rather than relying on `ramp_time` alone, otherwise all groups start simultaneously and ramp independently.

---

## HTTP Request Sampler

The primary sampler for HTTP/S testing.

```xml
<HTTPSamplerProxy guiclass="HttpTestSampleGui" testname="GET /api/products">
  <elementProp name="HTTPsampler.Arguments" elementType="Arguments">
    <collectionProp name="Arguments.arguments">
      <elementProp name="category" elementType="HTTPArgument">
        <stringProp name="Argument.name">category</stringProp>
        <stringProp name="Argument.value">${category}</stringProp>
        <boolProp name="HTTPArgument.use_equals">true</boolProp>
      </elementProp>
    </collectionProp>
  </elementProp>
  <stringProp name="HTTPSampler.domain">${__P(host,localhost)}</stringProp>
  <stringProp name="HTTPSampler.port">${__P(port,8080)}</stringProp>
  <stringProp name="HTTPSampler.protocol">${__P(protocol,https)}</stringProp>
  <stringProp name="HTTPSampler.path">/api/products</stringProp>
  <stringProp name="HTTPSampler.method">GET</stringProp>
  <boolProp name="HTTPSampler.follow_redirects">true</boolProp>
  <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
</HTTPSamplerProxy>
```

**HTTP Request Defaults** — Add one `HTTP Request Defaults` config element at the Test Plan level so individual samplers only need the path:

```xml
<ConfigTestElement guiclass="HttpDefaultsGui" testclass="ConfigTestElement"
                   testname="HTTP Request Defaults">
  <stringProp name="HTTPSampler.domain">${__P(host,localhost)}</stringProp>
  <stringProp name="HTTPSampler.port">${__P(port,443)}</stringProp>
  <stringProp name="HTTPSampler.protocol">https</stringProp>
  <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
</ConfigTestElement>
```

---

## CSV Data Set Config — Parameterisation

Feed each virtual user unique data (users, products, search terms) to avoid cache skew.

```xml
<CSVDataSet guiclass="TestBeanGUI" testname="Test Users">
  <stringProp name="filename">${__P(data_dir,./data)}/users.csv</stringProp>
  <stringProp name="variableNames">username,password,accountId</stringProp>
  <stringProp name="delimiter">,</stringProp>
  <boolProp name="quotedData">false</boolProp>
  <!-- ALL_THREADS: shared across threads — each row consumed once globally -->
  <!-- CURRENT_THREAD: each thread iterates the file independently           -->
  <stringProp name="shareMode">shareMode.all</stringProp>
  <boolProp name="recycle">true</boolProp>   <!-- wrap when EOF reached -->
  <boolProp name="stopThread">false</boolProp>
  <stringProp name="ignoreFirstLine">true</stringProp>
</CSVDataSet>
```

`users.csv` (first line is header, ignored):
```
username,password,accountId
alice@example.com,s3cur3!,1001
bob@example.com,p@ssw0rd,1002
charlie@example.com,abc123!,1003
```

**[community] `shareMode.all` vs `shareMode.currentthread` gotcha.** `shareMode.all` means one global pointer advances across all threads — good for ensuring each row is used once. `shareMode.currentthread` means every thread re-reads from the top — useful when you want each VU to cycle through the full dataset. Mixing them in one plan silently produces unexpected distributions.

---

## Response Assertion

Fail a sample when the response does not meet correctness criteria.

```xml
<ResponseAssertion guiclass="AssertionGui" testname="Status 200">
  <collectionProp name="Asserion.test_strings">
    <stringProp name="49586">200</stringProp>
  </collectionProp>
  <!-- Test field: Response Code -->
  <stringProp name="Assertion.test_field">Assertion.response_code</stringProp>
  <!-- Test type: EQUALS (2), CONTAINS (2), MATCHES (8), NOT (4+type) -->
  <intProp name="Assertion.test_type">8</intProp>
  <boolProp name="Assertion.assume_success">false</boolProp>
</ResponseAssertion>

<!-- Body content check -->
<ResponseAssertion guiclass="AssertionGui" testname="Has products array">
  <collectionProp name="Asserion.test_strings">
    <stringProp>\"products\":</stringProp>
  </collectionProp>
  <stringProp name="Assertion.test_field">Assertion.response_data</stringProp>
  <intProp name="Assertion.test_type">2</intProp>
</ResponseAssertion>
```

For JSON responses prefer the **JSON Assertion** (JSONPath-based) over body-substring matching:

```xml
<JSONPathAssertion guiclass="JSONPathAssertionGui" testname="Non-empty products">
  <stringProp name="JSON_PATH">$.products.length()</stringProp>
  <stringProp name="EXPECTED_VALUE">0</stringProp>
  <boolProp name="JSONVALIDATION">true</boolProp>
  <boolProp name="EXPECT_NULL">false</boolProp>
  <boolProp name="INVERT">true</boolProp>  <!-- assert length != 0 -->
</JSONPathAssertion>
```

---

## Summary Report vs Aggregate Report

| Feature | Summary Report | Aggregate Report |
|---------|---------------|-----------------|
| Memory use | Low (rolling) | Higher (stores percentile histogram) |
| Percentiles (90th, 95th, 99th) | No | Yes |
| Throughput column | Yes | Yes |
| Best for | Quick CI pass/fail | SLA validation with percentile SLOs |
| Saved to file | Yes (`.jtl`) | Yes (`.jtl`) |

Use **Summary Report** during exploratory runs; switch to **Aggregate Report** or the Dashboard for SLA sign-off.

**[community] Listeners in the test plan consume memory during the run.** Remove or disable all GUI Listeners (`View Results Tree`, `Summary Report`, etc.) from the `.jmx` before running non-GUI. They accumulate all sample data in-process and will OOM a long run. Write results to a `.jtl` file instead and view them post-run.

---

## JMeter Properties — `-J` Flags for CI

Properties override `${__P(name,default)}` placeholders in the plan.

```bash
# Minimal CI invocation
jmeter -n \
  -t test-plans/api-smoke.jmx \
  -Jhost=api.staging.example.com \
  -Jport=443 \
  -Jprotocol=https \
  -Jthreads=20 \
  -Jramp=10 \
  -Jduration=120 \
  -l results/smoke-$(date +%Y%m%d-%H%M%S).jtl \
  -j logs/jmeter.log
```

Properties can also be loaded from a file:
```bash
jmeter -n -t plan.jmx -q ci.properties -l results/run.jtl
```

`ci.properties`:
```properties
host=api.staging.example.com
port=443
protocol=https
threads=50
ramp=30
duration=300
data_dir=./data
```

**Key system properties (set with `-D` not `-J`):**

| Flag | Purpose |
|------|---------|
| `-Djmeter.save.saveservice.output_format=csv` | Force CSV `.jtl` (default); use `xml` for richer data |
| `-Djmeter.save.saveservice.response_data=false` | Do not save response bodies (reduces `.jtl` size) |
| `-Dsun.net.http.allowRestrictedHeaders=true` | Required when sending `Host` header manually |

---

## Dashboard HTML Generation (`-e -o`)

Generate a self-contained HTML report from a `.jtl` results file.

```bash
# Option A: generate dashboard at end of the run
jmeter -n -t plan.jmx -l results/run.jtl -e -o reports/dashboard/

# Option B: generate from a previously collected .jtl (no re-run)
jmeter -g results/run.jtl -o reports/dashboard/
```

The `-o` directory **must not exist** (or must be empty) before running; JMeter will refuse to overwrite a populated directory.

CI pattern — always wipe then regenerate:
```bash
#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
JTL="results/run-${TIMESTAMP}.jtl"
REPORT="reports/dashboard-${TIMESTAMP}"

jmeter -n -t test-plans/load.jmx \
  -Jhost="${TARGET_HOST}" \
  -Jthreads="${THREADS:-50}" \
  -Jduration="${DURATION:-300}" \
  -l "${JTL}" \
  -j logs/jmeter-${TIMESTAMP}.log

# Always generate — even if jmeter exits non-zero (assertion failures)
jmeter -g "${JTL}" -o "${REPORT}" || true

echo "Report: ${REPORT}/index.html"
```

**[community] JMeter exits 0 even when assertions fail during the run.** Parse the `.jtl` to detect failures in CI (see JTL Parsing section below). Never rely solely on the JMeter process exit code for a CI pass/fail gate.

---

## Non-GUI Mode (`-n`) — Full Reference

```
jmeter -n -t <plan.jmx> [options]

  -n              Non-GUI mode (required for CI)
  -t <file>       Test plan file (.jmx)
  -l <file>       Results file (.jtl) — created fresh each run
  -e              Generate dashboard after run
  -o <dir>        Dashboard output directory (must be empty/absent)
  -j <file>       JMeter log file (default: jmeter.log in working dir)
  -q <file>       Additional properties file
  -J<name>=<val>  Set JMeter property at runtime
  -D<name>=<val>  Set Java system property at runtime
  -G<name>=<val>  Set JMeter property on remote engines (distributed)
  -R <host,...>   Remote hosts to distribute load to
  -X              Exit remote engines after test (distributed)
```

---

## JTL Result Parsing

The `.jtl` file is a CSV (by default) with one row per sample. Parse it to gate CI.

Default column order (CSV format):
```
timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,
failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect
```

**Shell — fail build if error rate exceeds 1 %:**
```bash
#!/usr/bin/env bash
JTL="${1:-results/run.jtl}"

TOTAL=$(tail -n +2 "$JTL" | wc -l)
FAILURES=$(tail -n +2 "$JTL" | awk -F',' '$8 == "false"' | wc -l)

if [ "$TOTAL" -eq 0 ]; then
  echo "ERROR: No samples found in $JTL" >&2; exit 1
fi

ERROR_RATE=$(echo "scale=4; $FAILURES / $TOTAL * 100" | bc)
echo "Total: $TOTAL  Failures: $FAILURES  Error rate: ${ERROR_RATE}%"

# Fail if error rate > 1 %
if (( $(echo "$ERROR_RATE > 1" | bc -l) )); then
  echo "FAIL: error rate ${ERROR_RATE}% exceeds 1% threshold" >&2; exit 1
fi
echo "PASS"
```

**Python — percentile check against SLA:**
```python
import csv, sys, statistics

jtl_file = sys.argv[1]
p95_sla_ms = int(sys.argv[2]) if len(sys.argv) > 2 else 2000

with open(jtl_file) as f:
    rows = list(csv.DictReader(f))

elapsed = [int(r["elapsed"]) for r in rows if r.get("elapsed", "").isdigit()]
if not elapsed:
    sys.exit("No samples found")

elapsed.sort()
p95 = elapsed[int(len(elapsed) * 0.95)]
error_count = sum(1 for r in rows if r.get("success") == "false")
error_rate = error_count / len(rows) * 100

print(f"Samples: {len(rows)}  P95: {p95}ms  Errors: {error_rate:.2f}%")

if p95 > p95_sla_ms:
    sys.exit(f"FAIL: P95 {p95}ms exceeds SLA {p95_sla_ms}ms")
if error_rate > 1.0:
    sys.exit(f"FAIL: error rate {error_rate:.2f}% exceeds 1%")
print("PASS")
```

---

## Distributed Testing Basics

Distribute load across multiple injector machines when a single host cannot generate enough throughput.

**Architecture:**
- **Controller** — runs the GUI or `-n` non-GUI; coordinates the test
- **Agents (remote engines)** — run `jmeter-server`; receive the plan and inject load

**Agent setup (each injector machine):**
```bash
# On each remote agent machine
bin/jmeter-server -Djava.rmi.server.hostname=<agent-ip>
```

**Controller invocation:**
```bash
jmeter -n -t plan.jmx \
  -R 10.0.1.10,10.0.1.11,10.0.1.12 \
  -Jhost=api.prod.example.com \
  -Gthreads=100 \          # -G sets property on ALL remote engines
  -l results/dist-run.jtl \
  -X                       # shut down remote engines after test
```

**`jmeter.properties` additions for distributed mode:**
```properties
remote_hosts=10.0.1.10,10.0.1.11,10.0.1.12
server.rmi.ssl.disable=true   # only in trusted private networks
client.rmi.localport=7000     # fix controller-side RMI port for firewall rules
server.rmi.localport=4000     # fix agent-side RMI port
```

**[community] Thread count with distributed testing is multiplied, not shared.** `-Jthreads=100` with 3 agents = 300 total VUs. If you want 100 total, set `-Jthreads=34` (100 / 3, rounded). This surprises teams migrating from single-node runs.

**[community] CSV Data Set Config files must be present on every agent.** The controller does not automatically distribute data files. Use a shared network mount, Ansible, or pre-bake the data into a Docker image on each agent.

---

## Real-World Gotchas [community]

1. **[community] Listeners left enabled in the `.jmx` OOM long runs.** `View Results Tree` stores every response body in memory. For a 10-minute run at 500 RPS this easily exceeds heap. Remove all Listeners before committing the `.jmx`; rely on the `.jtl` file. WHY: listeners are designed for GUI debugging, not production load injection.

2. **[community] `Content-Type: application/json` must be set manually.** Unlike Postman or k6, JMeter does not auto-set `Content-Type` for JSON bodies. Add an HTTP Header Manager with `Content-Type: application/json` at the Thread Group level. Missing it causes the server to parse the body as form data, producing unexpected 400/415 errors that look like load-induced failures.

3. **[community] Correlation extractors must run before assertions.** If you use a `Regular Expression Extractor` or `JSON Extractor` to capture a token from a login response and then assert on a subsequent request, ensure the extractor and the assertion are ordered correctly in the element tree. JMeter processes pre/post-processors in top-to-bottom order within a sampler.

4. **[community] `ramp_time = 0` triggers a thundering herd.** Setting ramp-up to 0 seconds starts all threads simultaneously. This frequently overwhelms connection pools and produces artificial timeout spikes that do not reflect real traffic. Always use a non-zero ramp — even 5 seconds — for any run with more than 10 threads.

5. **[community] The default heap (`-Xmx1g`) is too small for large runs.** At 500+ threads or long run durations, JMeter will GC-pause or crash. Edit `bin/jmeter` (Linux/macOS) or `bin/jmeter.bat` (Windows) to increase: `JVM_ARGS="-Xms2g -Xmx4g"`. In CI, set via environment: `JVM_ARGS="-Xmx4g" jmeter -n ...`.

6. **[community] `timeStamp` in the `.jtl` is epoch milliseconds, not human-readable.** Tools like `awk` that parse the CSV will not recognise the timestamp column as a date unless converted. Use Python `datetime.fromtimestamp(ts/1000)` or pass the `.jtl` directly to JMeter's `-g` flag for the dashboard (which handles the conversion internally).

7. **[community] JMeter exit code is always 0 unless the engine itself crashes.** Assertion failures, high error rates, and threshold violations do NOT cause a non-zero exit. You must parse the `.jtl` and exit the CI shell script with an appropriate code (see JTL Parsing section).

---

## CI Considerations

```yaml
# GitHub Actions example
- name: Run JMeter load test
  env:
    JVM_ARGS: "-Xmx2g"
  run: |
    jmeter -n \
      -t test-plans/api-load.jmx \
      -Jhost=${{ vars.STAGING_HOST }} \
      -Jthreads=50 \
      -Jramp=30 \
      -Jduration=120 \
      -l results/run.jtl \
      -j logs/jmeter.log

- name: Generate dashboard
  if: always()    # generate even when jmeter step fails
  run: jmeter -g results/run.jtl -o reports/dashboard/ || true

- name: Check SLA thresholds
  run: python scripts/check-jtl.py results/run.jtl 2000

- name: Upload artifacts
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: jmeter-results
    path: |
      results/
      reports/
      logs/
```

**Key CI rules:**
- Set `JVM_ARGS=-Xmx2g` (or higher) as an environment variable before invoking JMeter.
- Use `if: always()` for dashboard generation and artifact upload so results are available even after a test failure.
- Gate the build with a separate script step (check-jtl.py) that exits non-zero on SLA breach — never rely on JMeter's own exit code.
- Pin the JMeter version in CI (e.g., `JMETER_VERSION=5.6.3`) to avoid unexpected behaviour after upstream releases.
- Run only the data files needed; avoid committing large CSV files to the repo — use CI secrets or an S3 pre-download step.

---

## Key APIs / CLI Flags

| Flag / Element | Purpose | When to use |
|---------------|---------|-------------|
| `jmeter -n -t` | Non-GUI run | All CI executions |
| `jmeter -g -o` | Generate dashboard from `.jtl` | Post-processing / re-reporting |
| `-Jname=val` | Set JMeter property | Parameterise host, threads, duration |
| `-Dname=val` | Set Java system property | JVM/network config, RMI settings |
| `-Gname=val` | Set property on remote agents | Distributed runs |
| `-R host,...` | Remote agent list | Distributed load injection |
| `-X` | Stop remote engines after test | Distributed teardown |
| `-e -o dir` | Dashboard generation inline | Single-step run + report |
| `Thread Group` | Load profile definition | Every test plan |
| `HTTP Request Defaults` | Shared host/port/protocol | Avoid repeating in every sampler |
| `CSV Data Set Config` | Drive requests with external data | User credentials, product IDs |
| `HTTP Header Manager` | Add headers to requests | Auth tokens, `Content-Type` |
| `Response Assertion` | Verify status code / body | Correctness gate on each sampler |
| `JSON Extractor` | Capture values from JSON responses | Correlation (login token → next request) |
| `Regular Expression Extractor` | Capture values via regex | Non-JSON response correlation |
| `Constant Timer` | Add think-time between requests | Simulate realistic user pacing |
| `Throughput Shaping Timer` (plugin) | Precise RPS targeting | Arrival-rate load models |
| `Summary Report` | Rolling throughput / error stats | Quick status during a run |
| `Aggregate Report` | Percentile breakdown per label | SLA validation, post-run analysis |
