# JMeter — Performance Test Patterns

> Reference: [jmeter-patterns.md](../references/jmeter-patterns.md)

JMeter uses XML test plans (`.jmx` files). Tests are created graphically or
generated via CLI / JMeter DSL. Always run in non-GUI (`-n`) mode for CI.

## Test Plan Structure

| Element | Purpose |
|---------|---------|
| Thread Group | Defines virtual users (threads), ramp-up period, and loop count |
| HTTP Request Sampler | Individual HTTP request to the target endpoint |
| HTTP Header Manager | Adds headers (Authorization, Content-Type) to requests |
| CSV Data Set Config | Loads test data (users, IDs) from a CSV file for parameterization |
| Response Assertion | Validates status code, response body, or response time |
| Constant Timer | Introduces think time between requests |
| Summary Report / Aggregate Report | Listener for results collection (use only in non-GUI mode) |

## Minimal JMX Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0">
  <hashTree>
    <TestPlan testname="API Load Test" enabled="true">
      <hashTree>
        <ThreadGroup testname="Load Group" enabled="true">
          <stringProp name="ThreadGroup.num_threads">50</stringProp>
          <stringProp name="ThreadGroup.ramp_time">30</stringProp>
          <stringProp name="ThreadGroup.duration">120</stringProp>
          <boolProp name="ThreadGroup.scheduler">true</boolProp>
          <hashTree>
            <HTTPSamplerProxy testname="GET /api/users" enabled="true">
              <stringProp name="HTTPSampler.domain">${__P(host,localhost)}</stringProp>
              <stringProp name="HTTPSampler.port">${__P(port,3001)}</stringProp>
              <stringProp name="HTTPSampler.path">/api/users</stringProp>
              <stringProp name="HTTPSampler.method">GET</stringProp>
              <hashTree>
                <HeaderManager testname="Auth Header" enabled="true">
                  <collectionProp name="HeaderManager.headers">
                    <elementProp name="Authorization" elementType="Header">
                      <stringProp name="Header.name">Authorization</stringProp>
                      <stringProp name="Header.value">Bearer ${token}</stringProp>
                    </elementProp>
                  </collectionProp>
                  <hashTree/>
                </HeaderManager>
                <ResponseAssertion testname="Status 200" enabled="true">
                  <collectionProp name="Assertion.test_strings"><stringProp>200</stringProp></collectionProp>
                  <stringProp name="Assertion.test_field">Assertion.response_code</stringProp>
                  <boolProp name="Assertion.assume_success">false</boolProp>
                  <intProp name="Assertion.test_type">8</intProp>
                  <hashTree/>
                </ResponseAssertion>
              </hashTree>
            </HTTPSamplerProxy>
          </hashTree>
        </ThreadGroup>
      </hashTree>
    </TestPlan>
  </hashTree>
</jmeterTestPlan>
```

## Auth Pattern

For bearer token auth, use a pre-request login step or extract the token from
a setup HTTP Sampler using a Regular Expression Extractor (JSON Extractor):

```xml
<!-- Add after login HTTP Sampler -->
<JSONPathExtractor testname="Extract Token" enabled="true">
  <stringProp name="JSONPathExtractor.referenceName">token</stringProp>
  <stringProp name="JSONPathExtractor.jsonPathExprs">$.token</stringProp>
</JSONPathExtractor>
```

## CI Notes

```bash
# Non-GUI run (mandatory for CI)
jmeter -n -t load-tests/api-load.jmx \
  -l "$_TMP/jmeter-results.jtl" \
  -e -o "$_TMP/jmeter-report/" \
  -Jhost=localhost -Jport=3001

# Exit code: non-zero on error or assertion failure (JMeter 5.3+)
# -Xms512m -Xmx1g recommended for large test plans
```

- Use JMeter properties (`-J`) to override host/port/threads without editing the JMX
- Dashboard report (`-e -o`) generates an HTML report in the output directory
- For distributed testing, start injectors with `jmeter-server` before running the controller

## Execute Block

```bash
_JMX_FILES=$(find . -name "*.jmx" ! -path "*/node_modules/*" 2>/dev/null | head -3)
if command -v jmeter &>/dev/null && [ -n "$_JMX_FILES" ]; then
  for jmx in $_JMX_FILES; do
    _BASE=$(basename "$jmx" .jmx)
    mkdir -p "$_TMP/jmeter-report-$_BASE"
    echo "=== Running JMeter: $jmx ==="
    jmeter -n -t "$jmx" \
      -l "$_TMP/jmeter-results-$_BASE.jtl" \
      -e -o "$_TMP/jmeter-report-$_BASE/" \
      -Jhost="${_API_HOST:-localhost}" \
      2>&1 | tee "$_TMP/jmeter-output-$_BASE.txt"
    echo "JMETER_EXIT_CODE: $?"
  done
fi
```

## Result Parsing

```bash
for f in "$_TMP"/jmeter-results-*.jtl; do
  [ -f "$f" ] && python3 - << PYEOF
import csv, statistics
rows = list(csv.DictReader(open("$f")))
latencies = [int(r["elapsed"]) for r in rows if r.get("elapsed","").isdigit()]
errors = sum(1 for r in rows if r.get("success","true").lower() == "false")
if latencies:
    latencies.sort()
    p95 = latencies[int(len(latencies)*0.95)]
    print(f"Samples: {len(latencies)}  p95: {p95}ms  Errors: {errors}")
PYEOF
done
```
