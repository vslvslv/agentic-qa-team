---
name: qa-mobile
preamble-tier: 3
version: 1.0.0
description: |
  Mobile test agent. Detects the mobile framework (React Native/Expo with Detox,
  native iOS/Android with Appium/WebDriverIO, or cross-platform with Maestro),
  generates test cases for critical user flows, executes them against a
  simulator/emulator or physical device, and produces a structured report.
  Works standalone or as a sub-agent of /qa-team. Use when asked to "qa mobile",
  "test the app", "mobile tests", "detox", "appium", "maestro",
  "react native testing", or "ios/android test agent". (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
---

## Version check

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_QA_ROOT=$(dirname "$(readlink ~/.claude/skills/qa-mobile 2>/dev/null)" 2>/dev/null) || true
[ ! -f "${_QA_ROOT:-x}/VERSION" ] && \
  _QA_ROOT="$(readlink ~/.claude/skills/qa-agentic-team 2>/dev/null)" || true
_QA_VER=$( [ -n "$_QA_ROOT" ] && bash "$_QA_ROOT/bin/qa-team-update-check" 2>/dev/null \
  || echo "UPDATE_CHECK_FAILED: not found" )
echo "VERSION_STATUS: $_QA_VER"
_QA_ASK_COOLDOWN="$_TMP/.qa-update-asked"
_QA_SKIP_ASK=0
if [ -f "$_QA_ASK_COOLDOWN" ]; then
  _qa_age=$(( $(date +%s) - $(cat "$_QA_ASK_COOLDOWN" | tr -d ' ') ))
  [ "$_qa_age" -lt 600 ] && _QA_SKIP_ASK=1
fi
```

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `_QA_SKIP_ASK` is `0`, use `AskUserQuestion`:
- Question: "qa-agentic-team update available (read vCURRENT → vNEW from VERSION_STATUS output). Update before running?"
- Options: "Yes — update now (recommended)" | "No — run with current version"
- Run `echo "$(date +%s)" > "$_QA_ASK_COOLDOWN"` to set a 10-minute cooldown (prevents repeated prompts in parallel sub-agents).
- If user selects "Yes": `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup" && echo "Updated successfully."`
- Continue regardless of choice.

---

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"

# Detect mobile framework
echo "--- FRAMEWORK DETECTION ---"
ls android/ ios/ 2>/dev/null | head -5
cat app.json 2>/dev/null | head -20
cat package.json 2>/dev/null | grep -E '"react-native"|"expo"|"detox"|"appium"|"@wdio"' | head -10
ls .detoxrc.js .detoxrc.ts .detoxrc.json 2>/dev/null

# Detect Detox
_DETOX=0
grep -q '"detox"' package.json 2>/dev/null && _DETOX=1
echo "DETOX_PRESENT: $_DETOX"

# Detect Appium / WebDriverIO
_APPIUM=0
grep -q '"appium"\|"@wdio"' package.json 2>/dev/null && _APPIUM=1
echo "APPIUM_PRESENT: $_APPIUM"

# Detect Maestro
_MAESTRO=0
[ -d ".maestro" ] && _MAESTRO=1
which maestro > /dev/null 2>&1 && _MAESTRO=1
find . -name "*.yaml" ! -path "*/node_modules/*" 2>/dev/null | \
  xargs grep -l "appId:\|tapOn:\|assertVisible:" 2>/dev/null | head -1 | grep -q '.' && _MAESTRO=1
echo "MAESTRO_PRESENT: $_MAESTRO"

# Target language detection (used for Appium multi-language support)
_TARGET_LANG="typescript"
find . -name "pom.xml" ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && _TARGET_LANG="java"
find . \( -name "requirements.txt" -o -name "pyproject.toml" \) \
  ! -path "*/node_modules/*" 2>/dev/null | grep -q '.' && _TARGET_LANG="python"
find . -name "*.csproj" ! -path "*/obj/*" 2>/dev/null | grep -q '.' && _TARGET_LANG="csharp"
[ -f "Gemfile" ] && _TARGET_LANG="ruby"
echo "TARGET_LANG: $_TARGET_LANG"

# Detect available simulators/emulators
echo "--- DEVICES ---"
xcrun simctl list devices available 2>/dev/null | grep -E "Booted|iPhone|iPad" | head -10 || echo "iOS sim: not available"
adb devices 2>/dev/null | head -5 || echo "Android adb: not available"

# Existing mobile test files
echo "--- EXISTING TESTS ---"
find . \( -path "*/e2e/*.test.js" -o -path "*/e2e/*.spec.js" \
  -o -path "*/e2e/*.test.ts" -o -path "*/e2e/*.spec.ts" \
  -o -path "*/.maestro/*.yaml" -o -path "*/test/**/*.js" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -15

# App screens / navigation
echo "--- SCREENS ---"
find . \( -path "*/screens/*.tsx" -o -path "*/screens/*.jsx" \
  -o -path "*/navigation/*.tsx" -o -path "*/Navigation.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -20

# --- MULTI-REPO SUPPORT ---
# Set QA_EXTRA_PATHS (space-separated absolute paths) to scan tests in other repos
# e.g.: export QA_EXTRA_PATHS="/path/to/mobile-tests-repo"
if [ -n "$QA_EXTRA_PATHS" ]; then
  echo "MULTI_REPO_PATHS: $QA_EXTRA_PATHS"
  for _qr in $QA_EXTRA_PATHS; do
    _extra=$(find "$_qr" \( \
      -name "*.spec.ts" -o -name "*.spec.js" -o -name "*.test.ts" -o -name "*.test.js" \
      -o -name "*.yaml" \) \
      ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
    echo "EXTRA_REPO $(basename "$_qr"): $_extra test files — $_qr"
  done
fi
```

If `MULTI_REPO_PATHS` output appeared: when sampling test files in subsequent phases, include files from those extra paths. All sub-agents inherit `QA_EXTRA_PATHS` automatically via the environment. Language detection uses CWD (the main application repository).

### Tool Selection Gate

Count detected tools from `DETOX_PRESENT`, `APPIUM_PRESENT`, `MAESTRO_PRESENT`.

**Exactly one detected** → use that tool automatically. Set `_MOB_TOOL` to `detox`,
`appium`, or `maestro`.

**Zero detected** → ask:
> "No mobile testing tool detected. Which would you like to use?
> 1. **Detox** (recommended for React Native/Expo — JS-native, fast, first-party)
> 2. **Appium + WebDriverIO** (best for fully native iOS/Android or cross-language teams)
> 3. **Maestro** (YAML-based, zero-code, cross-platform, rapid CI setup)
>
> Recommendation: Detox for React Native; Appium for native apps; Maestro for quick
> cross-platform flows with minimal scripting."

**Two or more detected** → list which were found, ask which to use for this run.

If no simulator/emulator is available: warn the user. Ask whether to write tests only
or resolve the device setup first.

## Phase 1 — Detect Framework and Configuration

**If Detox is present:**

```bash
cat .detoxrc.js .detoxrc.ts .detoxrc.json 2>/dev/null | head -40
grep -r "device\|simulator\|emulator\|configuration" .detoxrc.js .detoxrc.ts 2>/dev/null | head -20
```

**If Appium / WebDriverIO is present:**

```bash
cat wdio.conf.js wdio.conf.ts wdio.conf.mjs 2>/dev/null | head -40
cat appium.config.js appium.config.ts 2>/dev/null | head -20
```

**If Maestro is present:**

```bash
find . -name "*.yaml" ! -path "*/node_modules/*" 2>/dev/null | \
  xargs grep -l "appId:\|tapOn:\|assertVisible:" 2>/dev/null | head -10
ls .maestro/ 2>/dev/null
```

**React Native / Expo detection:**

```bash
cat app.json 2>/dev/null | python3 -c "
import sys, json
try:
  d = json.load(sys.stdin)
  expo = d.get('expo',{})
  print('NAME:', d.get('name') or expo.get('name'))
  print('SLUG:', expo.get('slug'))
  print('VERSION:', expo.get('version') or d.get('version'))
  print('SCHEME:', expo.get('scheme'))
except: pass
" 2>/dev/null
```

## Phase 2 — Discover Screens and Flows

Read navigation and screen files to build a flow inventory:

```bash
# Navigation structure
find . \( -path "*/navigation/*.tsx" -o -name "*Navigation*.tsx" \
  -o -name "*Router*.tsx" -o -name "*Stack*.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -5 | xargs cat 2>/dev/null | head -100

# Screen names
find . -path "*/screens/*.tsx" ! -path "*/node_modules/*" 2>/dev/null | \
  xargs -I{} basename {} .tsx 2>/dev/null | sort

# Auth flow
find . \( -name "Login*.tsx" -o -name "Auth*.tsx" -o -name "Signin*.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -3 | xargs cat 2>/dev/null | head -50
```

Build a **screen inventory**:
- Screen name · Route/navigation key · Purpose (one sentence)
- Key interactions (text input, button tap, scroll, swipe)
- Priority: `critical` | `important` | `nice-to-have`

## Phase 3 — Generate Test Cases

Read existing test files first — append missing `describe`/flow blocks, never delete.

**Detox tests (React Native / Expo):**

> Reference: [Detox patterns guide](references/detox-patterns.md)
> Key patterns: testID selectors · waitFor idioms (toBeVisible/toHaveValue/toHaveLabel/toExist) · CI-aware timeouts · disableSynchronization (narrow scope with try/finally) · artifact collection · setURLBlacklist for analytics · deep link testing · push notification simulation · platform-conditional logic · parallel sharding · element.getAttributes() · biometrics simulation (matchFace/unmatchFace) · Expo-specific setup · React Navigation ghost screen · WebSocket sync · Android lock screen · orientation testing · by.system() for runtime permission dialogs · device.clearKeychain() for auth isolation (Detox 20+) · Metro config RN 0.73+ · jest-circus required (Detox 20+) · flakiness decision tree

```javascript
// e2e/login.test.js
describe("Login Flow", () => {
  beforeAll(async () => { await device.launchApp({ newInstance: true }); });
  beforeEach(async () => { await device.reloadReactNative(); });

  it("shows login screen on launch", async () => {
    await expect(element(by.id("login-screen"))).toBeVisible();
  });
  it("logs in with valid credentials", async () => {
    await element(by.id("email-input")).typeText("admin@example.com");
    await element(by.id("password-input")).typeText("password123");
    await element(by.id("login-button")).tap();
    await expect(element(by.id("home-screen"))).toBeVisible();
  });
  it("shows error with invalid credentials", async () => {
    await element(by.id("email-input")).typeText("wrong@example.com");
    await element(by.id("password-input")).typeText("wrongpass");
    await element(by.id("login-button")).tap();
    await expect(element(by.text("Invalid credentials"))).toBeVisible();
  });
});
```

**Appium / WebDriverIO tests (Native iOS/Android):**

Select the reference guide based on `_TARGET_LANG`:

**TypeScript** (default):
> Reference: [Appium/WebDriverIO patterns guide (TypeScript)](references/appium-wdio-patterns.md)
> Key patterns: TypeScript POM with BasePage · accessibility-id selector hierarchy · explicit waits (waitForDisplayed/waitUntil/waitForStable) · mobile gestures (swipe/long-press/double-tap/pinch-zoom/drag-and-drop W3C Actions API) · parallel device execution with typed capabilities · auth bypass via API token + deep-link · network mock (browser.mock) · beforeEach app reset (terminateApp/activateApp) · CI Appium 2 driver installation + pin + wait-on · GitHub Actions matrix (iOS + Android parallel) · spec sharding (SHARD_INDEX/SHARD_TOTAL) · animation disable · performance tuning (snapshotMaxDepth + disableIdLocatorAutocompletion) · visual regression (@wdio/visual-service) · device farm integration (BrowserStack/Sauce Labs) · Cucumber BDD option · retry/flake quarantine · WebDriverIO v9 migration (tsx loader, bundled expect, no @wdio/sync) · Appium plugin system (relaxed-caps, wait-plugin, images) · browser vs driver disambiguation · Appium Inspector workflow · scrollIntoView() shorthand · Expo dev client requirement · scoped child queries (element.$$()) · geolocation simulation (setGeoLocation/mobile:setSimulatedLocation) · orientation testing · runtime permission dialogs (acceptAlert/grantAndroidPermission) · appium:permissions capability · lock/unlock device · push notification simulation (iOS Simulator) · network condition simulation · keyboard dismissal (hideKeyboard) · file push/pull (pushFile/pullFile) · device log capture (getLogs logcat/syslog) · dark mode simulation · deep link testing (mobile:deepLink) · app state assertions (queryAppState) · screen recording (startRecordingScreen/stopRecordingScreen) · TypeScript path aliases (@pages/@helpers tsconfig paths)

**Java**:
> Reference: [Appium patterns guide (Java)](references/appium-patterns-java.md)
> Key patterns: `AppiumDriver` setup (IOSDriver / AndroidDriver) · `MobileBy.AccessibilityId` selector hierarchy · explicit waits (WebDriverWait) · POM base class · `@BeforeAll`/`@AfterAll` lifecycle · W3C touch actions · capabilities via `AppiumOptions`

**Python**:
> Reference: [Appium patterns guide (Python)](references/appium-patterns-python.md)
> Key patterns: `webdriver.Remote` with Appium · `AppiumBy.ACCESSIBILITY_ID` selector hierarchy · `WebDriverWait` + `expected_conditions` · pytest fixtures for driver lifecycle · session-scoped setup/teardown

**C#**:
> Reference: [Appium patterns guide (C#)](references/appium-patterns-csharp.md)
> Key patterns: `IOSDriver`/`AndroidDriver` with `AppiumOptions` · `MobileBy.AccessibilityId` selector hierarchy · `WebDriverWait` explicit waits · NUnit/MSTest/xUnit base class setup · `OneTimeSetUp`/`OneTimeTearDown` driver lifecycle

```typescript
// test/specs/login.spec.ts  (TypeScript / WebDriverIO example)
import { $, browser } from "@wdio/globals";
import { expect } from "expect-webdriverio";

describe("Login Flow", () => {
  it("shows login screen on launch", async () => {
    await expect($("~login-screen")).toBeDisplayed();
  });
  it("logs in with valid credentials", async () => {
    await $("~email-input").setValue(process.env.E2E_USER_EMAIL || "admin@example.com");
    await $("~password-input").setValue(process.env.E2E_USER_PASSWORD || "password123");
    await $("~login-button").click();
    await expect($("~home-screen")).toBeDisplayed();
  });
});
```

**Maestro flows (YAML — cross-platform):**

> Reference: [Maestro patterns guide](references/maestro-patterns.md)

```yaml
# .maestro/login.yaml
appId: com.example.myapp
---
- launchApp
- tapOn:
    text: "Email"
- inputText: "${EMAIL:-admin@example.com}"
- tapOn:
    text: "Password"
- inputText: "${PASSWORD:-password123}"
- tapOn:
    text: "Log In"
- assertVisible:
    text: "Welcome"
- takeScreenshot: login_success
```

```yaml
# .maestro/login_invalid.yaml
appId: com.example.myapp
---
- launchApp
- tapOn:
    text: "Email"
- inputText: "wrong@example.com"
- tapOn:
    text: "Password"
- inputText: "wrongpass"
- tapOn:
    text: "Log In"
- assertVisible:
    text: "Invalid credentials"
```

```yaml
# .maestro/_suite.yaml  (run all flows in order)
flows:
  - login.yaml
  - login_invalid.yaml
  - home.yaml
```

**Maestro tips:**
- `tapOn` matches by text, id, or `{ id: "element-id" }` — prefer `testID`/`accessibilityLabel`
- Use `runFlow: setup.yaml` for shared setup (e.g. login) reused across flow files
- Pass secrets via `--env KEY=VALUE` or `envFile: .maestro.env`
- `scrollUntilVisible` + `assertVisible` for long lists; `swipe` for drawer/carousel

**Coverage targets per critical screen:**
1. Screen renders without crash (smoke test)
2. Primary action (login, submit form, tap CTA)
3. Error/empty state handling
4. Navigation: back, deep link if applicable

**Selector strategy (Detox/Appium):**
- `by.id(testID)` > `by.label()` > `by.type()` > `by.text()` (Detox — avoid by.text for actions)
- `$("~testId")` > `$("id=...")` > `$("xpath=...")` (Appium — avoid XPath)

**Flakiness / synchronization (Detox):**
- Use `waitFor(...).withTimeout(ms)` — never `setTimeout`/`sleep`
- Disable animations in CI: `launchArgs: { detoxDisableAnimations: 'true' }`
- Use `replaceText()` instead of `typeText()` to avoid appended-text gotcha
- Blacklist analytics URLs with `device.setURLBlacklist([...])` to prevent idle-detection hangs
- Narrow `disableSynchronization()` to smallest scope; always pair with `try/finally { enableSynchronization() }`

## Phase 4 — Execute Tests

**Detox:**

```bash
_DETOX_CONFIG=$(ls .detoxrc.js .detoxrc.ts .detoxrc.json 2>/dev/null | head -1)
[ ! -d "android/app/build" ] && [ ! -d "ios/build" ] && \
  npx detox build --configuration ios.sim.debug 2>&1 | tail -20
npx detox test \
  --configuration ios.sim.debug \
  --reporter json \
  --artifacts-location "$_TMP/detox-artifacts" \
  2>&1 | tee "$_TMP/qa-mobile-output.txt"
echo "DETOX_EXIT_CODE: $?"
```

**Appium / WebDriverIO:**

```bash
npx wdio run wdio.conf.ts \
  --reporters json \
  2>&1 | tee "$_TMP/qa-mobile-output.txt"
echo "WDIO_EXIT_CODE: $?"
```

**Maestro:**

```bash
_MAESTRO_DIR=$(ls -d .maestro/ maestro/ 2>/dev/null | head -1)
_MAESTRO_DIR="${_MAESTRO_DIR:-.maestro}"
if command -v maestro &>/dev/null && [ -d "$_MAESTRO_DIR" ]; then
  echo "=== Running Maestro flows in $_MAESTRO_DIR ==="
  maestro test "$_MAESTRO_DIR" \
    --env EMAIL="${E2E_USER_EMAIL:-admin@example.com}" \
    --env PASSWORD="${E2E_USER_PASSWORD:-password123}" \
    --format junit \
    --output "$_TMP/maestro-results.xml" \
    2>&1 | tee "$_TMP/qa-mobile-output.txt"
  echo "MAESTRO_EXIT_CODE: $?"
fi
```

Parse output:

```bash
python3 - << 'PYEOF'
import json, os, re
tmp = os.environ.get("TEMP") or os.environ.get("TMP") or "/tmp"
path = os.path.join(tmp, "qa-mobile-output.txt")
content = open(path).read() if os.path.exists(path) else ""
passed = len(re.findall(r'✓|passing|PASS|Flow Completed', content))
failed = len(re.findall(r'✗|failing|FAIL|Flow Failed|Error:', content))
print(json.dumps({"passed": passed, "failed": failed, "raw_summary": content[-500:]}))
PYEOF
```

## Phase 5 — Report

Write report to `$_TMP/qa-mobile-report.md`:

```markdown
# QA Mobile Report — <date>

## Summary
- **Status**: ✅ / ❌
- Passed: N · Failed: N · Skipped: N
- Framework: Detox / Appium+WebDriverIO / Maestro
- Platform: iOS / Android / Cross-platform
- Device: <simulator/emulator/device name>

## Screen Coverage
| Screen | Tests | Status |
|--------|-------|--------|
| Login  | 3     | ✅ |
| Home   | 2     | ❌ 1 fail |

## Failures
<list each failure with screen name + error snippet>

## Coverage Gaps
<screens not tested>

## Setup Notes
<any build commands or config changes needed>
```

## Important Rules

- **Build before test** — Detox requires a compiled binary; check before running
- **Use testID accessors** — always prefer `testID`/`accessibilityLabel`; coordinate with app devs to add them
- **No fixed sleeps** — use `waitFor(...).withTimeout(ms)`; hard-coded delays cause CI flakiness
- **Disable animations on CI** — pass `detoxDisableAnimations: 'true'` in `launchArgs` (Detox)
- **Device availability first** — if no simulator/emulator is available, write tests only and note setup steps
- **Platform-specific specs** — use separate describe blocks / flow files for iOS vs Android differences
- **Clean state** — use `device.launchApp({ newInstance: true })` or `launchApp` (Maestro) for fresh state
- **Report even if build fails** — document what was blocked and why
- **Never run `adb root` or modify system settings** on physical devices without explicit confirmation
