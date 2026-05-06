---
name: qa-geo
preamble-tier: 3
version: 1.0.0
description: |
  Geo and timezone simulation suite. Parameterizes Playwright tests across multiple time zones and
  geo-locations using page.emulateTimezone() and browser.newContext({ geolocation, locale }) to catch
  date/time arithmetic bugs, DST boundary transitions, locale formatting errors, and geo-gated feature
  inconsistencies invisible to standard E2E tests.
  Env vars: QA_TIMEZONES, QA_GEOLOCATIONS, QA_GEO_PAGES, WEB_URL. (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
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
echo "BRANCH: $_BRANCH  DATE: $_DATE"
echo "--- DETECTION ---"

# Target URL
_WEB_URL="${WEB_URL:-http://localhost:3000}"
echo "WEB_URL: $_WEB_URL"

# Playwright detection
_PLAYWRIGHT=0
[ -f "node_modules/.bin/playwright" ] && _PLAYWRIGHT=1
echo "PLAYWRIGHT: $_PLAYWRIGHT"

# Timezone and geo configuration
_TIMEZONES="${QA_TIMEZONES:-America/New_York,Europe/London,Asia/Tokyo,Australia/Sydney}"
_GEOLOCATIONS="${QA_GEOLOCATIONS:-US,UK,JP,AU}"
_GEO_PAGES="${QA_GEO_PAGES:-/,/login,/dashboard}"
echo "TIMEZONES: $_TIMEZONES"
echo "GEOLOCATIONS: $_GEOLOCATIONS"
echo "GEO_PAGES: $_GEO_PAGES"

# App reachability
curl -sf --max-time 5 "$_WEB_URL" >/dev/null 2>&1 && _APP_REACHABLE=1 || _APP_REACHABLE=0
echo "APP_REACHABLE: $_APP_REACHABLE"
```

If `_APP_REACHABLE` is `0`: emit "App at $_WEB_URL is not reachable. Set WEB_URL env var or start the app. Skipping geo tests." and stop gracefully.

If `_PLAYWRIGHT` is `0`: emit "Playwright not found. Install with: npm install --save-dev @playwright/test && npx playwright install chromium" and stop gracefully.

## Geo-Location Map (internal reference)

Maps locale code (used in `QA_GEOLOCATIONS`) to coordinates and locale. Extended codes DE and BR are also supported.

| Code | Latitude   | Longitude   | Locale  | Timezone              |
|------|------------|-------------|---------|----------------------|
| US   | 37.7749    | -122.4194   | en-US   | America/New_York      |
| UK   | 51.5074    | -0.1278     | en-GB   | Europe/London         |
| JP   | 35.6762    | 139.6503    | ja-JP   | Asia/Tokyo            |
| AU   | -33.8688   | 151.2093    | en-AU   | Australia/Sydney      |
| DE   | 52.5200    | 13.4050     | de-DE   | Europe/Berlin         |
| BR   | -23.5505   | -46.6333    | pt-BR   | America/Sao_Paulo     |

## Phase 1 — Generate Playwright Geo Test Suite

Write `$_TMP/qa-geo-tests.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';

const TIMEZONES = process.env.QA_TIMEZONES?.split(',') || ['America/New_York', 'Europe/London', 'Asia/Tokyo', 'Australia/Sydney'];
const GEO_CONFIGS = [
  { timezone: 'America/New_York', geolocation: { latitude: 37.7749, longitude: -122.4194 }, locale: 'en-US', label: 'US' },
  { timezone: 'Europe/London',    geolocation: { latitude: 51.5074, longitude: -0.1278  }, locale: 'en-GB', label: 'UK' },
  { timezone: 'Asia/Tokyo',       geolocation: { latitude: 35.6762, longitude: 139.6503 }, locale: 'ja-JP', label: 'JP' },
  { timezone: 'Australia/Sydney', geolocation: { latitude: -33.8688, longitude: 151.2093 }, locale: 'en-AU', label: 'AU' },
].filter(c => TIMEZONES.includes(c.timezone));

const PAGES = process.env.QA_GEO_PAGES?.split(',') || ['/'];
const BASE_URL = process.env.WEB_URL || 'http://localhost:3000';

for (const config of GEO_CONFIGS) {
  test.describe(`Locale: ${config.label} (${config.timezone})`, () => {
    test.use({ timezoneId: config.timezone, geolocation: config.geolocation, locale: config.locale, permissions: ['geolocation'] });

    for (const path of PAGES) {
      test(`${path} — no JS errors, date/locale renders`, async ({ page }) => {
        const errors: string[] = [];
        page.on('pageerror', e => errors.push(e.message));
        await page.goto(BASE_URL + path);
        await page.waitForLoadState('networkidle');

        // Filter out known third-party noise (analytics, ads, favicon)
        const filteredErrors = errors.filter(e =>
          !e.includes('favicon') &&
          !e.toLowerCase().includes('analytics') &&
          !e.toLowerCase().includes('gtm') &&
          !e.toLowerCase().includes('hotjar')
        );
        if (filteredErrors.length > 0) console.error('JS ERRORS:', filteredErrors);
        expect(filteredErrors).toHaveLength(0);

        // Check page loaded
        await expect(page.locator('body')).toBeVisible();

        // Check no raw ISO dates visible (YYYY-MM-DDTHH:mm) — warning only
        const bodyText = await page.locator('body').innerText();
        const rawISODate = /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/.test(bodyText);
        if (rawISODate) {
          console.warn(`[WARN] Raw ISO date detected on ${path} in ${config.label} — may not be locale-formatted`);
        }
      });
    }
  });
}
```

## Phase 2 — Execute Tests

Run the generated spec file, capturing JSON output:

```bash
echo "--- RUNNING GEO TESTS ---"
QA_TIMEZONES="$_TIMEZONES" \
QA_GEOLOCATIONS="$_GEOLOCATIONS" \
QA_GEO_PAGES="$_GEO_PAGES" \
WEB_URL="$_WEB_URL" \
  npx playwright test "$_TMP/qa-geo-tests.spec.ts" --reporter=json \
  > "$_TMP/qa-geo-results.json" 2>&1
echo "PW_EXIT: $?"
```

Parse results — extract pass/fail per timezone×page combination:

```python
python3 - << 'PYEOF'
import json, os

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
try:
    raw = json.load(open(os.path.join(tmp, 'qa-geo-results.json'), encoding='utf-8'))
    suites = raw.get('suites', [])
except Exception as e:
    print(f"WARN: Could not parse results: {e}")
    suites = []

summary = []
def walk(suites, parent=''):
    for s in suites:
        label = f"{parent}/{s.get('title','')}" if parent else s.get('title','')
        for spec in s.get('specs', []):
            for t in spec.get('tests', []):
                r = t.get('results', [{}])[0]
                summary.append({
                    'suite': label,
                    'title': spec.get('title',''),
                    'status': t.get('status','unknown'),
                    'duration': r.get('duration', 0),
                    'errors': [e.get('message','')[:200] for e in r.get('errors', [])],
                })
        walk(s.get('suites', []), label)
walk(suites)

passed = [t for t in summary if t['status'] == 'passed']
failed = [t for t in summary if t['status'] == 'failed']
print(f"TOTAL: {len(summary)}  PASSED: {len(passed)}  FAILED: {len(failed)}")
for f in failed:
    print(f"  FAIL [{f['suite']}] {f['title']}: {'; '.join(f['errors'])[:100]}")

json.dump(summary, open(os.path.join(tmp, 'qa-geo-parsed.json'), 'w'), indent=2)
print(f"PARSED_WRITTEN: {os.path.join(tmp, 'qa-geo-parsed.json')}")
PYEOF
```

## Phase 3 — Report

Parse `$_TMP/qa-geo-parsed.json` and write the report:

```python
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
date = os.environ.get('_DATE', 'unknown')

try:
    tests = json.load(open(os.path.join(tmp, 'qa-geo-parsed.json'), encoding='utf-8'))
except Exception:
    tests = []

passed = [t for t in tests if t['status'] == 'passed']
failed = [t for t in tests if t['status'] == 'failed']
skipped = [t for t in tests if t['status'] not in ('passed', 'failed')]

lines = [
    f'# QA Geo/Timezone Report — {date}',
    '',
    '## Summary',
    f'- Total: {len(tests)}  Passed: {len(passed)}  Failed: {len(failed)}  Skipped: {len(skipped)}',
    f'- Status: {"PASS" if not failed else "FAIL"}',
    f'- App URL: {os.environ.get("_WEB_URL", "unknown")}',
    '',
    '## Results Matrix',
    '',
    '| Timezone | Locale | Page | Status | Issues |',
    '|----------|--------|------|--------|--------|',
]
for t in tests:
    icon = 'PASS' if t['status'] == 'passed' else ('FAIL' if t['status'] == 'failed' else 'SKIP')
    errs = '; '.join(t.get('errors', []))[:80].replace('|', '\\|')
    lines.append(f'| {t["suite"][:35]} | — | {t["title"][:25]} | {icon} | {errs} |')

if failed:
    lines += ['', '## Failures', '']
    for f in failed:
        lines.append(f'### {f["suite"]} > {f["title"]}')
        for err in f.get('errors', []):
            lines.append(f'```\n{err[:400]}\n```')
        lines.append('')

lines += [
    '',
    '## Notes',
    '- Raw ISO date warnings indicate dates not formatted for the user locale.',
    '- JS errors from third-party scripts (analytics, GTM, Hotjar) are automatically filtered.',
    '- DST boundary failures: re-run near US/EU DST transition dates for full coverage.',
]

report_path = os.path.join(tmp, f'qa-geo-report-{date}.md')
open(report_path, 'w', encoding='utf-8').write('\n'.join(lines))
print(f'REPORT_WRITTEN: {report_path}')
PYEOF
```

Write CTRF output:

```python
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
try:
    tests = json.load(open(os.path.join(tmp, 'qa-geo-parsed.json'), encoding='utf-8'))
except Exception:
    tests = []

ctrf_tests = []
for t in tests:
    ctrf_tests.append({
        'name': f'{t["suite"]} > {t["title"]}',
        'status': t['status'] if t['status'] in ('passed', 'failed', 'skipped') else 'other',
        'duration': t.get('duration', 0),
        'suite': 'geo',
        'message': '; '.join(t.get('errors', []))[:200],
    })

passed = sum(1 for t in ctrf_tests if t['status'] == 'passed')
failed = sum(1 for t in ctrf_tests if t['status'] == 'failed')
skipped = sum(1 for t in ctrf_tests if t['status'] == 'skipped')
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-geo'},
        'summary': {
            'tests': len(ctrf_tests),
            'passed': passed,
            'failed': failed,
            'pending': 0,
            'skipped': skipped,
            'other': 0,
            'start': now_ms - 5000,
            'stop': now_ms,
        },
        'tests': ctrf_tests,
        'environment': {
            'reportName': 'qa-geo',
            'webUrl': os.environ.get('_WEB_URL', 'unknown'),
            'date': os.environ.get('_DATE', 'unknown'),
        },
    }
}

out = os.path.join(tmp, 'qa-geo-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  tests={len(ctrf_tests)} passed={passed} failed={failed} skipped={skipped}')
PYEOF
```

## Important Rules

- **Requires running app** — skip gracefully if `_APP_REACHABLE=0`; do not attempt to start the app
- **Filter third-party JS errors** — analytics, GTM, Hotjar, and favicon errors must not cause test failure
- **Raw ISO date = warning, not failure** — emit a console warning and note it in the report, but do not fail the test
- **DST boundaries** — for meaningful DST testing, run near transition dates; document this limitation in the report
- **Geo-gated features** — if the app actively blocks by IP geo-location, note this as expected behavior, not a test failure
- **PLAYWRIGHT=0** — skip all phases gracefully; emit setup instructions

## Agent Memory

After each run, update `.claude/agent-memory/qa-geo/MEMORY.md` (create if absent). Record:
- WEB_URL confirmed working
- Pages tested and any that returned errors
- Timezones where date/time formatting issues were found
- Playwright version used

Read this file at the start of each run to skip re-detection of known facts.

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-geo","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
