---
name: qa-explore
preamble-tier: 3
version: 1.0.0
description: |
  Swarm exploratory testing skill. Spawns N parallel browser agents that autonomously
  explore a running web app — clicking links, submitting forms with dummy data, recording
  console errors, broken links, 4xx/5xx responses, and unexpected redirects. No scripts
  required. Use when asked to "explore the app", "smoke test", "find broken links",
  "exploratory test", "vibetest", or after a deploy. (qa-agentic-team)
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

# Base URL detection
echo "--- BASE URL ---"
_BASE_URL="${QA_BASE_URL:-}"
if [ -z "$_BASE_URL" ]; then
  _BASE_URL=$(grep -r "baseURL\|BASE_URL" playwright.config.ts playwright.config.js .env .env.local 2>/dev/null \
    | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
fi
_BASE_URL="${_BASE_URL:-http://localhost:3000}"
echo "BASE_URL: $_BASE_URL"

# Swarm configuration
_EXPLORE_AGENTS="${QA_EXPLORE_AGENTS:-3}"
_MAX_PAGES="${QA_EXPLORE_MAX_PAGES:-20}"
echo "EXPLORE_AGENTS: $_EXPLORE_AGENTS"
echo "MAX_PAGES_PER_AGENT: $_MAX_PAGES"

# Detect seed routes from common framework patterns
echo "--- SEED ROUTES ---"
find . \( -path "*/pages/*.tsx" -o -path "*/pages/*.ts" -o -path "*/pages/*.jsx" \) \
  ! -path "*/node_modules/*" ! -path "*/\[*" 2>/dev/null | \
  sed 's|.*/pages||; s|/index\(\.tsx\|\.ts\|\.jsx\)$||; s|\.\(tsx\|ts\|jsx\)$||' | sort -u | head -20
find . -path "*/app/**/page.tsx" ! -path "*/node_modules/*" 2>/dev/null | \
  sed 's|.*/app||; s|/page\.tsx$||' | grep -v '^\[' | sort -u | head -20
find . \( -name "router.ts" -o -name "router.js" -o -name "routes.ts" -o -name "routes.js" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -3
```

Check app reachability:
```bash
echo "--- APP REACHABILITY ---"
_APP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$_BASE_URL" --max-time 5 2>/dev/null || echo "000")
echo "APP_STATUS: $_APP_STATUS"
```

If `_APP_STATUS` is `000` and `QA_OFFLINE` is not `1`: warn the user and use `AskUserQuestion`:
"App is not reachable at $_BASE_URL. Proceed anyway (analysis only) or cancel?" Options: "Proceed in offline mode" | "Cancel — I'll start the app first".
If offline mode: skip Phase 2 swarm execution; output a warning in the report.

## Phase 1 — Seed Discovery

Build a list of seed URLs to distribute among agents:

1. **From framework routing** (collect from Preamble bash output):
   - Next.js `pages/` entries → prepend `_BASE_URL`
   - Next.js `app/` segment entries → prepend `_BASE_URL`
   - Vue/React Router route paths from `router.ts`/`routes.js`

2. **From sitemap** (if available):
   ```bash
   curl -s "$_BASE_URL/sitemap.xml" --max-time 5 2>/dev/null | \
     grep -oE '<loc>[^<]+</loc>' | sed 's|<loc>||; s|</loc>||' | head -30
   ```

3. **Fallback**: if no routes found, all agents start at `_BASE_URL`.

Deduplicate seed list, cap at `_EXPLORE_AGENTS × 5` seeds. Distribute evenly:
- Agent 1 gets seeds 1, N+1, 2N+1, ...
- Agent 2 gets seeds 2, N+2, 2N+2, ...
- etc.

## Phase 2 — Swarm Exploration

Spawn `_EXPLORE_AGENTS` sub-agents in parallel using the Agent tool. Each agent receives this prompt:

```
You are a QA explorer agent (agent N of _EXPLORE_AGENTS). Your job is to autonomously
explore a running web app and surface bugs — no test scripts needed.

Starting seeds: <comma-separated seed URLs for this agent>
App base URL: <_BASE_URL>
Max pages to visit: <_MAX_PAGES>

For each page you visit:
1. Record: URL + HTTP status code
2. Record: all browser console errors (JS exceptions, TypeError, CSP violations)
3. Check all visible <a href> links on the page — probe each with a HEAD/GET request and flag non-200
4. Note any unexpected redirects (e.g., /dashboard redirecting to /login without auth)
5. Note visible error indicators: "404", "not found", "error occurred", "500", "something went wrong"
6. Submit any visible forms with realistic dummy data (name: "Test User", email: "test@example.com",
   phone: "555-0100", etc.) and record the result

Navigation strategy:
- Prefer unvisited links over already-visited ones
- Follow navigation menus and sidebar links aggressively
- Visit at most <_MAX_PAGES> unique URLs then stop

Output format (one line per finding):
URL: <url> STATUS:<code>
CONSOLE_ERROR: <url> | <error_message_first_100_chars>
BROKEN: <page_url> | <broken_href> | STATUS:<code>
REDIRECT: <from_url> → <to_url>
FORM_ERROR: <url> | <form_name> | <error_message>
ERROR_PAGE: <url> | <visible_error_text>

Write all findings to: $_TMP/qa-explore-agent-<N>.txt
```

Wait for all agents to complete before Phase 3.

## Phase 3 — Aggregation

Merge all agent output files and deduplicate:
```bash
cat "$_TMP/qa-explore-agent-"*.txt 2>/dev/null | sort -u > "$_TMP/qa-explore-all.txt"

echo "=== EXPLORE SUMMARY ==="
echo "PAGES_VISITED: $(grep -c "^URL:" "$_TMP/qa-explore-all.txt" 2>/dev/null || echo 0)"
echo "CONSOLE_ERRORS: $(grep -c "^CONSOLE_ERROR:" "$_TMP/qa-explore-all.txt" 2>/dev/null || echo 0)"
echo "BROKEN_LINKS: $(grep -c "^BROKEN:" "$_TMP/qa-explore-all.txt" 2>/dev/null || echo 0)"
echo "REDIRECTS: $(grep -c "^REDIRECT:" "$_TMP/qa-explore-all.txt" 2>/dev/null || echo 0)"
echo "FORM_ERRORS: $(grep -c "^FORM_ERROR:" "$_TMP/qa-explore-all.txt" 2>/dev/null || echo 0)"
echo "ERROR_PAGES: $(grep -c "^ERROR_PAGE:" "$_TMP/qa-explore-all.txt" 2>/dev/null || echo 0)"
echo "HTTP_4XX_5XX: $(grep -E "STATUS:[45][0-9][0-9]" "$_TMP/qa-explore-all.txt" 2>/dev/null | wc -l | tr -d ' ')"
```

Group console errors by message text (deduplicate across agents — same error on same page counts once):
```bash
grep "^CONSOLE_ERROR:" "$_TMP/qa-explore-all.txt" 2>/dev/null | \
  awk -F'|' '{print $2}' | sort | uniq -c | sort -rn | head -20
```

Identify routes from the seed list that were never visited (coverage gap):
```bash
# Compare seed list against visited URLs
```

## Phase 4 — CTRF Output

```python
python3 - << 'PYEOF'
import json, os, re, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
all_file = os.path.join(tmp, 'qa-explore-all.txt')
content = open(all_file, encoding='utf-8', errors='replace').read() if os.path.exists(all_file) else ''

pages = len(re.findall(r'^URL:', content, re.MULTILINE))
console_errors = len(re.findall(r'^CONSOLE_ERROR:', content, re.MULTILINE))
broken_links = len(re.findall(r'^BROKEN:', content, re.MULTILINE))
http_errors = len(re.findall(r'STATUS:[45]\d\d', content))
form_errors = len(re.findall(r'^FORM_ERROR:', content, re.MULTILINE))

total = pages
passed = pages - http_errors
failed = http_errors + broken_links + form_errors

now_ms = int(time.time() * 1000)
ctrf = {
    'results': {
        'tool': {'name': 'qa-explore'},
        'summary': {
            'tests': total,
            'passed': passed,
            'failed': failed,
            'pending': 0,
            'skipped': 0,
            'other': 0,
            'start': now_ms - 5000,
            'stop': now_ms
        },
        'tests': [
            {'name': 'console-errors', 'status': 'failed' if console_errors > 0 else 'passed',
             'duration': 0, 'suite': 'explore',
             'message': f'{console_errors} console errors found'},
            {'name': 'broken-links', 'status': 'failed' if broken_links > 0 else 'passed',
             'duration': 0, 'suite': 'explore',
             'message': f'{broken_links} broken links found'},
            {'name': 'http-errors', 'status': 'failed' if http_errors > 0 else 'passed',
             'duration': 0, 'suite': 'explore',
             'message': f'{http_errors} HTTP 4xx/5xx responses'},
        ],
        'environment': {'reportName': 'qa-explore', 'branch': os.environ.get('_BRANCH', 'unknown')}
    }
}

out = os.path.join(tmp, 'qa-explore-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
PYEOF
```

## Phase 5 — Report

Write `$_TMP/qa-explore-report.md`:

```markdown
# QA Explore Report — <date>

## Summary
- **Status**: ✅ / ⚠️ / ❌
- Agents deployed: N
- Pages visited: N (unique)
- Console errors: N (unique)
- Broken links: N
- HTTP errors (4xx/5xx): N
- Form errors: N

## HTTP Errors
| URL | Status | Notes |
|-----|--------|-------|
| ... | 404 | ... |

## Console Errors
| Error Message | Pages Affected | Occurrences |
|---------------|----------------|-------------|
| ... | ... | N |

## Broken Links
| Found on Page | Broken href | Status |
|---------------|-------------|--------|
| ... | ... | 404 |

## Unexpected Redirects
| From | To | Notes |
|------|----|-------|
| /dashboard | /login | Auth redirect (expected?) |

## Form Errors
| Page | Form | Error |
|------|------|-------|

## Coverage
- Routes seeded: N
- Routes visited: N
- Routes not reached: <list>

## Recommendations
<prioritized list of issues by severity>
```

## Important Rules

- **Read-only exploration** — agents navigate and observe; they do not create accounts, make purchases, or modify data
- **Realistic dummy data only** — never inject SQL, scripts, or suspicious payloads in forms
- **Respect rate limits** — add 100ms delay between page requests; do not flood the server
- **Dedup across agents** — the same error on the same page is one finding, not N

## Agent Memory

After each run, update `.claude/agent-memory/qa-explore/MEMORY.md` (create if absent). Record:
- Base URL and app framework confirmed
- Routes that consistently return errors vs. expected 404s (known non-routes)
- Console errors that are pre-existing vs. newly introduced
- Auth-protected routes that always redirect (expected behavior)

Read this file at the start of each run to avoid re-flagging known stable state.

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-explore","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
