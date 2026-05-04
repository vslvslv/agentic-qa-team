---
name: qa-explore
description: |
  Swarm exploratory testing agent. Spawns N parallel browser agents that autonomously
  explore a running web app — clicking links, submitting forms with dummy data,
  recording console errors, broken links, 4xx/5xx responses, and unexpected redirects.
  No test scripts required. Use when asked to "explore the app", "smoke test",
  "find broken links", "exploratory test", or after a deploy.
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

_BASE_URL="${QA_BASE_URL:-}"
if [ -z "$_BASE_URL" ]; then
  _BASE_URL=$(grep -r "baseURL\|BASE_URL" playwright.config.ts playwright.config.js .env .env.local 2>/dev/null \
    | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
fi
_BASE_URL="${_BASE_URL:-http://localhost:3000}"
echo "BASE_URL: $_BASE_URL"

_EXPLORE_AGENTS="${QA_EXPLORE_AGENTS:-3}"
_MAX_PAGES="${QA_EXPLORE_MAX_PAGES:-20}"
echo "EXPLORE_AGENTS: $_EXPLORE_AGENTS  MAX_PAGES: $_MAX_PAGES"

echo "--- SEED ROUTES ---"
find . \( -path "*/pages/*.tsx" -o -path "*/pages/*.ts" -o -path "*/pages/*.jsx" \) \
  ! -path "*/node_modules/*" ! -path "*/\[*" 2>/dev/null | \
  sed 's|.*/pages||; s|/index\(\.tsx\|\.ts\|\.jsx\)$||; s|\.\(tsx\|ts\|jsx\)$||' | sort -u | head -20
find . -path "*/app/**/page.tsx" ! -path "*/node_modules/*" 2>/dev/null | \
  sed 's|.*/app||; s|/page\.tsx$||' | grep -v '^\[' | sort -u | head -20

_APP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$_BASE_URL" --max-time 5 2>/dev/null || echo "000")
echo "APP_STATUS: $_APP_STATUS"
```

If `_APP_STATUS` is `000` and `QA_OFFLINE` is not `1`: use `AskUserQuestion`: "App not reachable at $_BASE_URL. Proceed anyway?" Options: "Proceed in offline mode" | "Cancel — I'll start the app first".

## Phase 1 — Seed Discovery

Build seed URL list:
1. Collect routes from framework patterns (Next.js `pages/`, `app/`, Vue/React Router `router.ts`)
2. Probe sitemap: `curl -s "$_BASE_URL/sitemap.xml" --max-time 5 | grep -oE '<loc>[^<]+</loc>'`
3. Fallback: all agents start at `_BASE_URL`

Distribute seeds evenly among `_EXPLORE_AGENTS` agents.

## Phase 2 — Swarm Exploration

Spawn `_EXPLORE_AGENTS` sub-agents in parallel. Each agent receives:

```
You are QA explorer agent N of _EXPLORE_AGENTS. Autonomously explore the web app:
Starting seeds: <assigned seed URLs>
Base URL: <_BASE_URL>
Max pages: <_MAX_PAGES>

For each page: record URL+status, console errors, broken links, redirects, form errors, error indicators.
Navigation: prefer unvisited links; follow menus and sidebars aggressively.
Output (one line per finding):
  URL: <url> STATUS:<code>
  CONSOLE_ERROR: <url> | <message_100chars>
  BROKEN: <page_url> | <href> | STATUS:<code>
  REDIRECT: <from> → <to>
  FORM_ERROR: <url> | <form> | <error>
  ERROR_PAGE: <url> | <visible_error>
Write to: $_TMP/qa-explore-agent-<N>.txt
```

## Phase 3 — Aggregation

```bash
cat "$_TMP/qa-explore-agent-"*.txt 2>/dev/null | sort -u > "$_TMP/qa-explore-all.txt"
echo "PAGES_VISITED: $(grep -c "^URL:" "$_TMP/qa-explore-all.txt" 2>/dev/null || echo 0)"
echo "CONSOLE_ERRORS: $(grep -c "^CONSOLE_ERROR:" "$_TMP/qa-explore-all.txt" 2>/dev/null || echo 0)"
echo "BROKEN_LINKS: $(grep -c "^BROKEN:" "$_TMP/qa-explore-all.txt" 2>/dev/null || echo 0)"
echo "HTTP_ERRORS: $(grep -E "STATUS:[45][0-9][0-9]" "$_TMP/qa-explore-all.txt" 2>/dev/null | wc -l | tr -d ' ')"
grep "^CONSOLE_ERROR:" "$_TMP/qa-explore-all.txt" 2>/dev/null | awk -F'|' '{print $2}' | sort | uniq -c | sort -rn | head -20
```

## Phase 4 — CTRF Output

```python
python3 - << 'PYEOF'
import json, os, re, time
tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
content = open(os.path.join(tmp,'qa-explore-all.txt'), encoding='utf-8', errors='replace').read() \
          if os.path.exists(os.path.join(tmp,'qa-explore-all.txt')) else ''
pages = len(re.findall(r'^URL:', content, re.MULTILINE))
http_errors = len(re.findall(r'STATUS:[45]\d\d', content))
broken = len(re.findall(r'^BROKEN:', content, re.MULTILINE))
console = len(re.findall(r'^CONSOLE_ERROR:', content, re.MULTILINE))
failed = bool(http_errors + broken + console)
now_ms = int(time.time() * 1000)
ctrf = {'results': {'tool': {'name': 'qa-explore'},
  'summary': {'tests': max(pages,1), 'passed': max(pages,1)-http_errors, 'failed': http_errors,
               'pending':0,'skipped':0,'other':0,'start':now_ms-5000,'stop':now_ms},
  'tests': [{'name':'console-errors','status':'failed' if console else 'passed','duration':0,'suite':'explore'},
            {'name':'broken-links','status':'failed' if broken else 'passed','duration':0,'suite':'explore'},
            {'name':'http-errors','status':'failed' if http_errors else 'passed','duration':0,'suite':'explore'}],
  'environment': {'reportName':'qa-explore','branch': os.environ.get('_BRANCH','unknown')}}}
out = os.path.join(tmp,'qa-explore-ctrf.json')
json.dump(ctrf, open(out,'w',encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
PYEOF
```

## Phase 5 — Report

Write `$_TMP/qa-explore-report.md` with sections: Summary, HTTP Errors, Console Errors, Broken Links, Unexpected Redirects, Coverage, Recommendations.

## Agent Memory

After each run, update `.claude/agent-memory/qa-explore/MEMORY.md`. Record: base URL, known stable routes vs. expected 404s, pre-existing console errors, auth-redirect routes.
