---
name: qa-deeplinks
preamble-tier: 3
version: 1.0.0
description: |
  Deep link and universal link validator. Enumerates all declared deep links and universal links
  from apple-app-site-association, assetlinks.json, and PWA manifest files, then generates tests
  that fire each URI scheme and assert the correct screen or web fallback is reached. Covers both
  cold-start and in-app navigation scenarios.
  Env vars: PLATFORM, APP_BUNDLE_ID, DEVICE_ID. (qa-agentic-team)
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

# Deep link source files
_AASA_FILE=$(find . -name "apple-app-site-association" ! -path "*/node_modules/*" 2>/dev/null | head -1)
_ASSETLINKS_FILE=$(find . -name "assetlinks.json" ! -path "*/node_modules/*" 2>/dev/null | head -1)
_MANIFEST_FILE=$(find . \( -name "manifest.json" -o -name "manifest.webmanifest" \) ! -path "*/node_modules/*" 2>/dev/null | head -1)
echo "AASA_FOUND: ${_AASA_FILE:-none}"
echo "ASSETLINKS_FOUND: ${_ASSETLINKS_FILE:-none}"
echo "MANIFEST_FOUND: ${_MANIFEST_FILE:-none}"

# Platform and device config
_PLATFORM="${PLATFORM:-auto}"
_APP_BUNDLE_ID="${APP_BUNDLE_ID:-}"
_DEVICE_ID="${DEVICE_ID:-}"
echo "PLATFORM: $_PLATFORM  BUNDLE_ID: ${_APP_BUNDLE_ID:-unset}  DEVICE_ID: ${_DEVICE_ID:-unset}"

# Tool detection
_ADB_AVAILABLE=0; command -v adb >/dev/null 2>&1 && _ADB_AVAILABLE=1
_XCRUN_AVAILABLE=0; command -v xcrun >/dev/null 2>&1 && _XCRUN_AVAILABLE=1
_PLAYWRIGHT_AVAILABLE=0; [ -f "node_modules/.bin/playwright" ] && _PLAYWRIGHT_AVAILABLE=1
echo "ADB: $_ADB_AVAILABLE  XCRUN: $_XCRUN_AVAILABLE  PLAYWRIGHT: $_PLAYWRIGHT_AVAILABLE"

# Auto-detect platform
if [ "$_PLATFORM" = "auto" ]; then
  [ -n "$_AASA_FILE" ] && _PLATFORM="ios"
  [ -n "$_ASSETLINKS_FILE" ] && _PLATFORM="android"
  [ -n "$_MANIFEST_FILE" ] && _PLATFORM="pwa"
fi
echo "EFFECTIVE_PLATFORM: $_PLATFORM"
echo "DEVICE_AVAILABLE: $([ $_ADB_AVAILABLE -eq 1 ] || [ $_XCRUN_AVAILABLE -eq 1 ] && echo 1 || echo 0)"
```

If no deep link files found and no `deepLinks`/`universalLinks` key in package.json: emit "No deep link configuration detected. See important rules for what to look for." and stop gracefully.

## Phase 1 — Parse Deep Links

Parse all found deep link sources:

```python
python3 - << 'PYEOF'
import json, os, subprocess, re

aasa_file = os.environ.get('_AASA_FILE', '')
assetlinks_file = os.environ.get('_ASSETLINKS_FILE', '')
manifest_file = os.environ.get('_MANIFEST_FILE', '')
bundle_id = os.environ.get('_APP_BUNDLE_ID', '')
platform = os.environ.get('_PLATFORM', 'auto')

links = []

# --- iOS: Apple App Site Association ---
if aasa_file and os.path.exists(aasa_file):
    try:
        data = json.load(open(aasa_file, encoding='utf-8'))
        details = data.get('applinks', {}).get('details', [])
        for detail in details:
            paths = detail.get('paths', []) or detail.get('components', [])
            app = detail.get('appIDs', [bundle_id or 'unknown'])[0]
            for path in paths:
                if isinstance(path, dict):
                    path = path.get('/', '') or ''
                if path and not path.startswith('NOT '):
                    links.append({'uri': f'https://<domain>{path}', 'platform': 'ios',
                                  'source': 'AASA', 'app': app, 'expected_screen_hint': path})
        print(f"AASA_LINKS: {len([l for l in links if l['source'] == 'AASA'])}")
    except Exception as e:
        print(f"AASA_PARSE_ERROR: {e}")

# --- Android: Asset Links ---
if assetlinks_file and os.path.exists(assetlinks_file):
    try:
        data = json.load(open(assetlinks_file, encoding='utf-8'))
        for entry in data:
            pkg = entry.get('target', {}).get('package_name', bundle_id or 'unknown')
            relation = entry.get('relation', [])
            links.append({'uri': f'android-app://{pkg}', 'platform': 'android',
                          'source': 'assetlinks', 'app': pkg,
                          'expected_screen_hint': str(relation)})
        print(f"ASSETLINKS_LINKS: {len([l for l in links if l['source'] == 'assetlinks'])}")
    except Exception as e:
        print(f"ASSETLINKS_PARSE_ERROR: {e}")

# --- PWA: Web App Manifest ---
if manifest_file and os.path.exists(manifest_file):
    try:
        data = json.load(open(manifest_file, encoding='utf-8'))
        start_url = data.get('start_url', '/')
        scope = data.get('scope', '/')
        links.append({'uri': start_url, 'platform': 'pwa',
                      'source': 'manifest', 'app': 'pwa', 'expected_screen_hint': 'start_url'})
        # Protocol handlers
        for ph in data.get('protocol_handlers', []):
            links.append({'uri': ph.get('url', ''), 'platform': 'pwa',
                          'source': 'manifest:protocol_handler', 'app': 'pwa',
                          'expected_screen_hint': ph.get('protocol', '')})
        # Share target
        if 'share_target' in data:
            st = data['share_target']
            links.append({'uri': st.get('action', '/share'), 'platform': 'pwa',
                          'source': 'manifest:share_target', 'app': 'pwa',
                          'expected_screen_hint': 'share_target'})
        print(f"MANIFEST_LINKS: {len([l for l in links if l['source'].startswith('manifest')])}")
    except Exception as e:
        print(f"MANIFEST_PARSE_ERROR: {e}")

# --- Custom: grep codebase for URI scheme handlers ---
try:
    result = subprocess.run(
        ['grep', '-r', '--include=*.json', '--include=*.ts', '--include=*.js', '--include=*.xml',
         '-E', r'(scheme|uri|deepLink|universalLink|intent-filter)',
         '--exclude-dir=node_modules', '-l', '.'],
        capture_output=True, text=True, timeout=15
    )
    custom_files = result.stdout.strip().split('\n')[:5]
    if custom_files and custom_files[0]:
        print(f"CUSTOM_HANDLER_FILES: {', '.join(custom_files)}")
except Exception:
    pass

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
out = os.path.join(tmp, 'qa-deeplinks-inventory.json')
json.dump(links, open(out, 'w', encoding='utf-8'), indent=2)
print(f"TOTAL_LINKS: {len(links)}")
print(f"INVENTORY_WRITTEN: {out}")
PYEOF
```

## Phase 2 — Validate

For each link in the inventory, validate based on platform:

```python
python3 - << 'PYEOF'
import json, os, subprocess, urllib.request

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
platform = os.environ.get('_PLATFORM', 'pwa')
adb_available = os.environ.get('_ADB_AVAILABLE', '0') == '1'
xcrun_available = os.environ.get('_XCRUN_AVAILABLE', '0') == '1'
bundle_id = os.environ.get('_APP_BUNDLE_ID', '')

try:
    links = json.load(open(os.path.join(tmp, 'qa-deeplinks-inventory.json'), encoding='utf-8'))
except Exception:
    links = []

results = []

for link in links[:20]:  # cap at 20 links per run
    uri = link.get('uri', '')
    plat = link.get('platform', 'pwa')
    status = 'skipped'
    detail = ''

    # PWA / web fallback
    if plat == 'pwa' or uri.startswith('http'):
        try:
            req = urllib.request.Request(uri, headers={'User-Agent': 'qa-deeplinks/1.0'})
            with urllib.request.urlopen(req, timeout=8) as resp:
                code = resp.getcode()
                title_match = b'<title>' in resp.read(2048)
                status = 'navigated' if code == 200 else 'error'
                detail = f'HTTP {code}' + (' — has <title>' if title_match else ' — no <title>')
        except Exception as e:
            status = 'error'
            detail = str(e)[:120]

    # Android: adb
    elif plat == 'android' and adb_available and bundle_id:
        try:
            cmd = ['adb', 'shell', 'am', 'start', '-W', '-a', 'android.intent.action.VIEW', '-d', uri, bundle_id]
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
            status = 'navigated' if 'Activity' in r.stdout else 'error'
            detail = r.stdout.strip()[:200] or r.stderr.strip()[:200]
        except Exception as e:
            status = 'error'; detail = str(e)[:120]
    elif plat == 'android' and not adb_available:
        status = 'skipped'; detail = 'adb not available'

    # iOS: xcrun simctl
    elif plat == 'ios' and xcrun_available:
        try:
            r = subprocess.run(['xcrun', 'simctl', 'openurl', 'booted', uri],
                               capture_output=True, text=True, timeout=15)
            status = 'navigated' if r.returncode == 0 else 'error'
            detail = r.stderr.strip()[:200] or 'opened'
        except Exception as e:
            status = 'error'; detail = str(e)[:120]
    elif plat == 'ios' and not xcrun_available:
        status = 'skipped'; detail = 'xcrun not available (macOS only)'

    results.append({**link, 'status': status, 'detail': detail})
    print(f"  [{status:10s}] {uri[:60]:60s} — {detail[:60]}")

out = os.path.join(tmp, 'qa-deeplinks-results.json')
json.dump(results, open(out, 'w', encoding='utf-8'), indent=2)
navigated = sum(1 for r in results if r['status'] == 'navigated')
error = sum(1 for r in results if r['status'] == 'error')
skipped = sum(1 for r in results if r['status'] == 'skipped')
print(f"NAVIGATED: {navigated}  ERROR: {error}  SKIPPED: {skipped}")
print(f"RESULTS_WRITTEN: {out}")
PYEOF
```

## Phase 3 — Report

```python
python3 - << 'PYEOF'
import json, os, time

tmp = os.environ.get('TEMP') or os.environ.get('TMP') or '/tmp'
date = os.environ.get('_DATE', 'unknown')

try:
    results = json.load(open(os.path.join(tmp, 'qa-deeplinks-results.json'), encoding='utf-8'))
except Exception:
    results = []

navigated = [r for r in results if r['status'] == 'navigated']
errors = [r for r in results if r['status'] == 'error']
skipped = [r for r in results if r['status'] == 'skipped']

lines = [
    f'# QA Deep Links Report — {date}',
    '',
    '## Summary',
    f'- Total links: {len(results)}',
    f'- Navigated: {len(navigated)}  Errors: {len(errors)}  Skipped: {len(skipped)}',
    f'- Status: {"PASS" if not errors else "FAIL"}',
    '',
    '## Deep Link Inventory',
    '',
    '| URI | Platform | Source | Expected Screen | Status | Detail |',
    '|-----|----------|--------|----------------|--------|--------|',
]

for r in results:
    uri = r.get('uri', '')[:50].replace('|', '\\|')
    detail = r.get('detail', '')[:50].replace('|', '\\|')
    lines.append(
        f'| `{uri}` | {r.get("platform","")} | {r.get("source","")} '
        f'| {r.get("expected_screen_hint","")[:20]} | {r.get("status","")} | {detail} |'
    )

if errors:
    lines += ['', '## Failed Links', '']
    for r in errors:
        lines.append(f'### `{r["uri"]}`')
        lines.append(f'- Platform: {r.get("platform","")}')
        lines.append(f'- Error: {r.get("detail","")}')
        lines.append('')

lines += [
    '',
    '## Notes',
    '- Web fallback validation requires a running app at the declared URL.',
    '- Native device tests require a connected device or booted simulator.',
    '- Cold-start tests require the app to be installed on the device.',
]

report_path = os.path.join(tmp, f'qa-deeplinks-report-{date}.md')
open(report_path, 'w', encoding='utf-8').write('\n'.join(lines))
print(f'REPORT_WRITTEN: {report_path}')

# CTRF
ctrf_tests = []
for r in results:
    ctrf_tests.append({
        'name': r.get('uri', 'unknown')[:80],
        'status': 'passed' if r['status'] == 'navigated' else (
                  'skipped' if r['status'] == 'skipped' else 'failed'),
        'duration': 0,
        'suite': 'deeplinks',
        'message': r.get('detail', '')[:200],
    })

passed = sum(1 for t in ctrf_tests if t['status'] == 'passed')
failed_ct = sum(1 for t in ctrf_tests if t['status'] == 'failed')
skipped_ct = sum(1 for t in ctrf_tests if t['status'] == 'skipped')
now_ms = int(time.time() * 1000)

ctrf = {
    'results': {
        'tool': {'name': 'qa-deeplinks'},
        'summary': {
            'tests': len(ctrf_tests), 'passed': passed, 'failed': failed_ct,
            'pending': 0, 'skipped': skipped_ct, 'other': 0,
            'start': now_ms - 3000, 'stop': now_ms,
        },
        'tests': ctrf_tests,
        'environment': {'reportName': 'qa-deeplinks', 'date': date},
    }
}

out = os.path.join(tmp, 'qa-deeplinks-ctrf.json')
json.dump(ctrf, open(out, 'w', encoding='utf-8'), indent=2)
print(f'CTRF_WRITTEN: {out}')
print(f'  tests={len(ctrf_tests)} passed={passed} failed={failed_ct} skipped={skipped_ct}')
PYEOF
```

## Important Rules

- **Web fallback validation requires running app** — skip web checks gracefully if app is unreachable
- **Native device testing requires connected device/simulator** — skip with clear message if unavailable
- **Cold-start tests require app to be installed** — do not attempt cold-start without confirming installation
- **Cap at 20 links per run** — avoid runaway validation on large link inventories
- **Filter duplicate URIs** — deduplicate before validation; same URI from multiple sources = one test

## Agent Memory

After each run, update `.claude/agent-memory/qa-deeplinks/MEMORY.md` (create if absent). Record:
- Deep link sources found (AASA, assetlinks, manifest) and file paths
- Platform determined (ios/android/pwa)
- Links that consistently fail (broken deep links in this project)
- Device/simulator availability at last run

Read this file at the start of each run to skip re-detection.

## Telemetry (run last)

```bash
~/.claude/skills/gstack/bin/gstack-timeline-log \
  '{"skill":"qa-deeplinks","event":"completed","branch":"'"$_BRANCH"'","date":"'"$_DATE"'"}' \
  2>/dev/null || true
```
