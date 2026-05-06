---
name: qa-deeplinks
description: |
  Deep link and universal link validator. Enumerates all declared deep links and universal
  links from apple-app-site-association, assetlinks.json, and PWA manifest files, then
  generates tests that fire each URI scheme and assert the correct screen or web fallback
  is reached. Covers both cold-start and in-app navigation scenarios.
  Env vars: PLATFORM, APP_BUNDLE_ID, DEVICE_ID.
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

_PLATFORM="${PLATFORM:-}"
_APP_BUNDLE_ID="${APP_BUNDLE_ID:-}"

_AASA=$(find . -name "apple-app-site-association" -o -name ".well-known/apple-app-site-association" 2>/dev/null | head -1)
_ASSETLINKS=$(find . -name "assetlinks.json" -o -name ".well-known/assetlinks.json" 2>/dev/null | head -1)
_MANIFEST=$(find . -name "AndroidManifest.xml" 2>/dev/null | grep -v build | head -1)
_APP_CONFIG=$(find . -name "app.json" -o -name "app.config.js" 2>/dev/null | head -1)

echo "AASA_FILE: ${_AASA:-(not found)}"
echo "ASSETLINKS_FILE: ${_ASSETLINKS:-(not found)}"
echo "ANDROID_MANIFEST: ${_MANIFEST:-(not found)}"
echo "APP_CONFIG: ${_APP_CONFIG:-(not found)}"
command -v adb >/dev/null 2>&1 && echo "ADB_AVAILABLE: 1" || echo "ADB_AVAILABLE: 0"
command -v xcrun >/dev/null 2>&1 && echo "XCRUN_AVAILABLE: 1" || echo "XCRUN_AVAILABLE: 0"
echo "--- DONE ---"
```

## Phase 1 — Parse Deep Link Definitions

Extract URI patterns from all detected definition files. Build list of all deep link URIs/paths. If none found, use AskUserQuestion.

## Phase 2 — Cold-Start Tests

For each URI:
- **iOS**: `xcrun simctl openurl booted "${URI}" && sleep 2 && xcrun simctl io booted screenshot`
- **Android**: `adb shell am start -a android.intent.action.VIEW -d "${URI}" && sleep 2 && adb shell dumpsys activity activities | grep topResumedActivity`
- **Web**: Playwright navigate + assert route loaded without 404

## Phase 3 — In-App Navigation Tests

For web apps: generate Playwright spec that navigates home then triggers each deep link path and asserts correct route.

## Phase N — Report

Write `$_TMP/qa-deeplinks-report-{_DATE}.md`: table of URI → cold-start result → in-app result; AASA vs manifest mismatches.

Write `$_TMP/qa-deeplinks-ctrf.json` (each URI = one test; failed routing = failed).

## Important Rules

- Each deep link URI = one CTRF test case
- If no device/simulator running, mark mobile tests as `pending`
- AASA paths returning 404 on the web = FAIL even if app routing works
- Use `PLATFORM=ios|android|web` to restrict to one platform
