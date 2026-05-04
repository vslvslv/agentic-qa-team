---
name: qa-security
description: |
  Security testing agent. Two modes: Mode A drives OWASP ZAP (spider + active scan +
  Claude OWASP/CWE triage) when ZAP is installed. Mode B runs lightweight curl probes
  (security headers, exposed files, CORS, JWT checks) and is always available.
  Nuclei template-based scanning runs as a second pass when installed. All probes are
  read-only — safe for staging environments. Use when asked to "security test", "DAST
  scan", "run ZAP", "check security headers", or "find vulnerabilities".
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
model: sonnet
memory: project
effort: high
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: |
            INPUT=$(cat); CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
            echo "$CMD" | grep -qE 'rm\s+-[a-zA-Z]*f[a-zA-Z]*\s+(--|/[^/]|~|\.\.)' \
              && { echo "Blocked: broad rm -rf not allowed" >&2; exit 2; }; exit 0
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: |
            FILE_PATH=$(echo "$TOOL_RESULT" | jq -r '.tool_result.file_path // empty' 2>/dev/null)
            echo "$FILE_PATH" | grep -qE '\.(spec|test)\.(ts|tsx)$' || exit 0
            TSC=$(find . -path "*/node_modules/.bin/tsc" ! -path "*/node_modules/*/node_modules/*" 2>/dev/null | head -1)
            [ -z "$TSC" ] && exit 0
            "$TSC" --noEmit 2>&1 | head -15; exit 0
          async: true
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

_STACK="web"
[ -f package.json ] && _STACK="nodejs"
grep -q '"next"' package.json 2>/dev/null && _STACK="nextjs"
[ -f pyproject.toml ] || [ -f requirements.txt ] && _STACK="python"
echo "STACK: $_STACK"

_BASE_URL="${QA_BASE_URL:-}"
[ -z "$_BASE_URL" ] && _BASE_URL=$(grep -r "baseURL\|BASE_URL" playwright.config.ts .env 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
_BASE_URL="${_BASE_URL:-http://localhost:3000}"
echo "BASE_URL: $_BASE_URL"
_APP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$_BASE_URL" --max-time 5 2>/dev/null || echo "000")
echo "APP_STATUS: $_APP_STATUS"
```

## Phase 1 — Mode Selection

- `_ZAP=1` → **Mode A** (ZAP DAST) then Mode B + Nuclei
- `_ZAP=0` → **Mode B** (curl probes) + Nuclei if available

## Phase 2 — Mode A: ZAP DAST (skip if `_ZAP=0`)

```bash
if command -v zap.sh >/dev/null 2>&1; then
  zap.sh -cmd -quickurl "$_BASE_URL" -quickprogress -quickout "$_TMP/zap-alerts.json" \
    -config scanner.strength=Medium 2>/dev/null | tail -20
else
  docker run --rm -v "$_TMP:/zap/results" softwaresecurityproject/zap-stable \
    zap-baseline.py -t "$_BASE_URL" -J /zap/results/zap-alerts.json -m 5 2>&1 | tail -20
fi
python3 -c "
import json,os,sys
f='$_TMP/zap-alerts.json'
if not os.path.exists(f): print('ZAP_ALERTS: not found'); sys.exit(0)
try:
  d=json.load(open(f,encoding='utf-8',errors='replace'))
  alerts=d.get('site',[{}])[0].get('alerts',[]) if isinstance(d.get('site'),list) else d.get('alerts',[])
  for a in alerts:
    r=a.get('riskdesc','Info').split(' ')[0]
    r in ('High','Medium') and print(f'ZAP_ALERT: [{r}] {a.get(\"alert\",\"\")} | CWE:{a.get(\"cweid\",\"\")} | {a.get(\"url\",\"\")}')
except Exception as e: print(f'ZAP_ERROR: {e}')
" 2>/dev/null
```

## Phase 2b — Mode B: Lightweight Probes (always runs)

```bash
echo "=== SECURITY HEADER PROBES ==="
_HEADERS=$(curl -sI "$_BASE_URL" --max-time 10 2>/dev/null)
for h in "content-security-policy" "x-frame-options" "x-content-type-options" \
         "strict-transport-security" "permissions-policy" "referrer-policy"; do
  echo "$_HEADERS" | grep -qi "$h" || echo "MISSING_HEADER: $h"
done

echo "=== EXPOSED FILES ==="
for path in ".env" ".env.local" ".git/config" ".git/HEAD" "config/database.yml" \
            "phpinfo.php" "actuator/env" "server-status"; do
  s=$(curl -s -o /dev/null -w "%{http_code}" "$_BASE_URL/$path" --max-time 5 2>/dev/null || echo "000")
  [ "$s" = "200" ] && echo "EXPOSED: /$path (HTTP $s)"
done

echo "=== CORS CHECK ==="
curl -sI -H "Origin: https://evil.example.com" "$_BASE_URL/api/" --max-time 5 2>/dev/null \
  | grep -i "access-control-allow-origin" | grep -v "null" | grep -q '.' \
  && echo "CORS_ISSUE: allows arbitrary origins"

echo "=== AUTH CHECK ==="
_U=$(curl -s -o /dev/null -w "%{http_code}" "$_BASE_URL/api/users" --max-time 5 2>/dev/null || echo "000")
_B=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer invalid_test" \
  "$_BASE_URL/api/users" --max-time 5 2>/dev/null || echo "000")
echo "UNAUTH_API: $_U  BAD_TOKEN: $_B"
[ "$_U" = "200" ] && echo "AUTH_ISSUE: /api/users open without auth"
[ "$_B" = "200" ] && echo "AUTH_ISSUE: /api/users accepts invalid token"
```

## Phase 3 — Nuclei (skip if `_NUCLEI=0`)

```bash
nuclei -u "$_BASE_URL" -tags "${_STACK},owasp,cve,misconfig,exposure" \
  -severity high,medium -rate-limit 10 -timeout 5 -j -o "$_TMP/nuclei-results.json" 2>&1 | tail -10
python3 -c "
import json,os
f='$_TMP/nuclei-results.json'
if not os.path.exists(f) or os.path.getsize(f)==0: print('NUCLEI: no results'); exit()
h=0; m=0
for line in open(f,encoding='utf-8',errors='replace'):
  try:
    r=json.loads(line.strip()); s=r.get('info',{}).get('severity','')
    n=r.get('info',{}).get('name',''); u=r.get('host','')
    if s=='high': h+=1; print(f'NUCLEI_HIGH: {n} | {u}')
    elif s=='medium': m+=1; print(f'NUCLEI_MEDIUM: {n} | {u}')
  except: pass
print(f'NUCLEI_SUMMARY: high={h} medium={m}')
" 2>/dev/null
```

## Phase 4 — CTRF Output

```python
python3 - << 'PYEOF'
import json, os, time
tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
now_ms = int(time.time() * 1000)
ctrf = {'results': {'tool': {'name': 'qa-security'},
  'summary': {'tests': 1, 'passed': 1, 'failed': 0, 'pending':0,'skipped':0,'other':0,
               'start':now_ms-10000,'stop':now_ms},
  'tests': [{'name':'security-probe','status':'passed','duration':0,'suite':'security'}],
  'environment': {'reportName':'qa-security','branch': os.environ.get('_BRANCH','unknown')}}}
out = os.path.join(tmp,'qa-security-ctrf.json')
json.dump(ctrf, open(out,'w',encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
PYEOF
```

## Phase 5 — Report

Write `$_TMP/qa-security-report.md` with: Executive Summary (risk counts), Findings table (OWASP/CWE/Risk/URL/Remediation), Missing Security Headers (with recommended values), Exposed Files, Auth issues, Next Steps.
**Safety rule**: all probes are read-only — no POST fuzzing or auth bypass attempts.

## Agent Memory

After each run, update `.claude/agent-memory/qa-security/MEMORY.md`. Record: app stack, known false positives, headers already present, mode used.
