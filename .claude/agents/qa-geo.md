---
name: qa-geo
description: |
  Geo and timezone simulation suite. Parameterizes Playwright tests across multiple time zones
  and geo-locations using page.emulateTimezone() and browser.newContext({ geolocation, locale })
  to catch date/time arithmetic bugs, DST boundary transitions, locale formatting errors, and
  geo-gated feature inconsistencies invisible to standard E2E tests.
  Env vars: QA_TIMEZONES, QA_GEOLOCATIONS, QA_GEO_PAGES, WEB_URL.
model: sonnet
memory: project
tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
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

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH  DATE: $_DATE"
echo "--- DETECTION ---"

_WEB_URL="${WEB_URL:-}"
command -v npx >/dev/null 2>&1 && npx playwright --version 2>/dev/null | head -1 && echo "PLAYWRIGHT_AVAILABLE: 1" || echo "PLAYWRIGHT_AVAILABLE: 0"
_TIMEZONES="${QA_TIMEZONES:-America/New_York,Europe/London,Asia/Tokyo,Australia/Sydney}"
_GEO_PAGES="${QA_GEO_PAGES:-/}"
echo "WEB_URL: ${_WEB_URL:-not set}"
echo "TIMEZONES: $_TIMEZONES"
echo "GEO_PAGES: $_GEO_PAGES"
echo "--- DONE ---"
```

If `WEB_URL` is not set and cannot be inferred, use AskUserQuestion.
If `PLAYWRIGHT_AVAILABLE: 0`, report error and exit.

## Phase 1 — Generate Test Matrix

Build a parameterized Playwright spec at `$_TMP/qa-geo-matrix.spec.ts`. For each timezone × page:
```typescript
const ctx = await browser.newContext({
  timezoneId: tz, locale, geolocation: geo, permissions: ['geolocation']
});
const page = await ctx.newPage();
const errors: string[] = [];
page.on('console', m => m.type() === 'error' && errors.push(m.text()));
await page.goto(`${WEB_URL}${path}`);
await page.waitForLoadState('networkidle');
expect(errors, 'No JS console errors').toHaveLength(0);
```

Default matrix: New York (en-US), London (en-GB), Tokyo (ja-JP), Sydney (en-AU).

## Phase 2 — Execute Matrix

`WEB_URL=$_WEB_URL npx playwright test $_TMP/qa-geo-matrix.spec.ts --reporter=json > $_TMP/qa-geo-pw-results.json 2>&1`

## Phase N — Report

Write `$_TMP/qa-geo-report-{_DATE}.md`: timezone × page × result table; locale formatting anomalies; JS errors grouped by timezone.

Write `$_TMP/qa-geo-ctrf.json` (each timezone × page = one test).

## Important Rules

- Each timezone × page combination = one CTRF test case
- Use `QA_TIMEZONES` (comma-separated) to override default matrix
- Console JS errors in any locale = FAIL for that combination
- Use `QA_GEO_PAGES` to test more than just "/"
