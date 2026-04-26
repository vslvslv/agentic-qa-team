---
name: qa-mobile
preamble-tier: 3
version: 1.0.0
description: |
  Mobile test agent. Detects the mobile framework (React Native / Expo with Detox,
  or native iOS/Android with Appium), generates test cases for critical user flows,
  executes them against a simulator/emulator or physical device, and produces a
  structured report. Works standalone or as a sub-agent of /qa-team. Use when
  asked to "qa mobile", "test the app", "mobile tests", "detox", "appium",
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
_DETOX=$(cat package.json 2>/dev/null | grep -c '"detox"' || echo 0)
echo "DETOX_PRESENT: $_DETOX"

# Detect Appium / WebDriverIO
_APPIUM=$(cat package.json 2>/dev/null | grep -c '"appium"\|"@wdio"' || echo 0)
echo "APPIUM_PRESENT: $_APPIUM"

# Detect available simulators/emulators
echo "--- DEVICES ---"
xcrun simctl list devices available 2>/dev/null | grep -E "Booted|iPhone|iPad" | head -10 || echo "iOS sim: not available"
adb devices 2>/dev/null | head -5 || echo "Android adb: not available"

# Existing mobile test files
echo "--- EXISTING TESTS ---"
find . \( -path "*/e2e/*.test.js" -o -path "*/e2e/*.spec.js" \
  -o -path "*/e2e/*.test.ts" -o -path "*/e2e/*.spec.ts" \
  -o -path "*/test/**/*.js" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -15

# App screens / navigation
echo "--- SCREENS ---"
find . \( -path "*/screens/*.tsx" -o -path "*/screens/*.jsx" \
  -o -path "*/navigation/*.tsx" -o -path "*/Navigation.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -20
```

Stop and ask the user if:
- Neither Detox nor Appium is detected and the project has `android/` or `ios/`
- No simulator/emulator is available

## Phase 1 — Detect Framework and Configuration

**If Detox is present:**

```bash
cat .detoxrc.js .detoxrc.ts .detoxrc.json 2>/dev/null | head -40
# Find which device config is set
grep -r "device\|simulator\|emulator\|configuration" .detoxrc.js .detoxrc.ts 2>/dev/null | head -20
```

**If Appium / WebDriverIO is present:**

```bash
cat wdio.conf.js wdio.conf.ts wdio.conf.mjs 2>/dev/null | head -40
cat appium.config.js appium.config.ts 2>/dev/null | head -20
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
find . \( -path "*/navigation/*.tsx" -o -path "*Navigation*.tsx" \
  -o -path "*Router*.tsx" -o -path "*Stack*.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -5 | xargs cat 2>/dev/null | head -100

# Screen names
find . -path "*/screens/*.tsx" ! -path "*/node_modules/*" 2>/dev/null | \
  xargs -I{} basename {} .tsx 2>/dev/null | sort

# Auth flow
find . \( -name "Login*.tsx" -o -name "Auth*.tsx" -o -name "Signin*.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -3 | xargs cat 2>/dev/null | head -50
```

Build a **screen inventory**:
- Screen name
- Route/navigation key
- Purpose (one sentence)
- Key interactions (text input, button tap, scroll, swipe)
- Priority: `critical` | `important` | `nice-to-have`

## Phase 3 — Generate Test Cases

**Detox tests (React Native / Expo):**

```javascript
// e2e/login.test.js (Detox)
describe("Login Flow", () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  beforeEach(async () => {
    await device.reloadReactNative();
  });

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

```typescript
// test/specs/login.spec.ts (WebDriverIO + Appium)
import { $, browser } from "@wdio/globals";
import { expect } from "expect-webdriverio";

describe("Login Flow", () => {
  it("shows login screen on launch", async () => {
    const loginScreen = await $("~login-screen");
    await expect(loginScreen).toBeDisplayed();
  });

  it("logs in with valid credentials", async () => {
    const emailInput = await $("~email-input");
    const passwordInput = await $("~password-input");
    const loginBtn = await $("~login-button");

    await emailInput.setValue(process.env.E2E_USER_EMAIL || "admin@example.com");
    await passwordInput.setValue(process.env.E2E_USER_PASSWORD || "password123");
    await loginBtn.click();

    const homeScreen = await $("~home-screen");
    await expect(homeScreen).toBeDisplayed();
  });
});
```

**Coverage targets per critical screen:**
1. Screen renders without crash (smoke test)
2. Primary action (login, submit form, tap CTA)
3. Error/empty state handling
4. Navigation: back, deep link if applicable

**Selector strategy:**
- Prefer `testID` / `accessibilityLabel` (set `testID` props in RN components)
- Use `by.id()` for Detox, `$("~testId")` for Appium accessibility ID
- Never use XPath — too brittle for mobile

Read existing test files before writing; append only missing `describe` blocks.

## Phase 4 — Execute Tests

**Detox:**

```bash
_DETOX_CONFIG=$(ls .detoxrc.js .detoxrc.ts .detoxrc.json 2>/dev/null | head -1)
_DETOX_CONF_NAME=$(cat "$_DETOX_CONFIG" 2>/dev/null | grep -o '"configurations"' | head -1)

# Build the app first if binary doesn't exist
_BUILD_NEEDED=false
[ ! -d "android/app/build" ] && [ ! -d "ios/build" ] && _BUILD_NEEDED=true

if [ "$_BUILD_NEEDED" = "true" ]; then
  echo "Building app for Detox..."
  npx detox build --configuration ios.sim.debug 2>&1 | tail -20 || \
  npx detox build --configuration android.emu.debug 2>&1 | tail -20
fi

# Run tests
npx detox test \
  --configuration ios.sim.debug \
  --reporter json \
  --artifacts-location "$_TMP/detox-artifacts" \
  2>&1 | tee "$_TMP/qa-mobile-output.txt"
_EXIT_CODE=$?
echo "DETOX_EXIT_CODE: $_EXIT_CODE"
```

**Appium / WebDriverIO:**

```bash
npx wdio run wdio.conf.ts \
  --reporters json \
  2>&1 | tee "$_TMP/qa-mobile-output.txt"
_EXIT_CODE=$?
echo "WDIO_EXIT_CODE: $_EXIT_CODE"
```

Parse output:

```bash
python3 - << 'PYEOF'
import json, os, re
tmp = os.environ.get("TEMP") or os.environ.get("TMP") or "/tmp"

output_file = os.path.join(tmp, "qa-mobile-output.txt")
if not os.path.exists(output_file):
    print("No output file found"); exit()

content = open(output_file).read()

# Extract pass/fail counts from common reporter patterns
passed = len(re.findall(r'✓|passing|PASS', content))
failed = len(re.findall(r'✗|failing|FAIL|Error:', content))
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
- Framework: Detox / Appium+WebDriverIO
- Platform: iOS / Android
- Device: <simulator/emulator name>

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
- **Device availability first** — if no simulator/emulator is available, write tests only and note setup steps
- **Platform-specific specs** — use separate describe blocks for iOS vs Android differences
- **Clean state** — use `device.launchApp({ newInstance: true })` or equivalent to ensure fresh state
- **Report even if build fails** — document what was blocked and why
- **Never run `adb root` or modify system settings** on physical devices without explicit confirmation
