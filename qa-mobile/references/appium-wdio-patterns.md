# Appium / WebDriverIO Patterns & Best Practices (TypeScript)
<!-- lang: TypeScript | sources: training knowledge (WebFetch + WebSearch unavailable) | iteration: 5 | score: 100/100 | date: 2026-04-26 -->
<!-- Note: WebFetch and WebSearch were unavailable during generation. Synthesized from official docs training knowledge + community experience. -->
<!-- Re-run `/qa-refine Appium/WebDriverIO` with WebFetch enabled to pull live sources. -->

## Core Principles

1. **Page Object pattern is non-negotiable** — Centralise all element selectors and interactions in Page Object classes. Tests that embed raw selectors become unmaintainable the moment the UI changes.
2. **Accessibility-id is the gold selector** — Use `~accessibility-id` first. It is the most stable selector across iOS and Android, survives layout changes, and works with screen readers.
3. **Never use static `pause()`** — Replace all `browser.pause(ms)` calls with `waitUntil()`, `waitForDisplayed()`, or `waitForEnabled()`. Static sleeps are the root cause of most flaky suites.
4. **Parallel execution from day one** — Design tests to be stateless so they can run on multiple devices simultaneously. Shared mutable state (e.g. a logged-in account used by all tests) serialises your suite.
5. **CI parity starts with the Appium server** — Flakiness that only appears in CI almost always traces back to a mis-configured or version-mismatched Appium server, not the test code itself.

---

## Recommended Patterns

### Pattern 1 — Page Object Model

Centralise selectors and actions in a typed class. The test file only calls methods; it never touches `$()` directly.

```typescript
// src/pages/LoginPage.ts
import { ChainablePromiseElement } from 'webdriverio';

class LoginPage {
  get emailInput(): ChainablePromiseElement {
    return $('~email-input'); // accessibility-id
  }

  get passwordInput(): ChainablePromiseElement {
    return $('~password-input');
  }

  get loginButton(): ChainablePromiseElement {
    return $('~login-button');
  }

  get errorBanner(): ChainablePromiseElement {
    return $('~error-banner');
  }

  async login(email: string, password: string): Promise<void> {
    await this.emailInput.setValue(email);
    await this.passwordInput.setValue(password);
    await this.loginButton.click();
  }

  async waitForError(): Promise<void> {
    await this.errorBanner.waitForDisplayed({ timeout: 5000 });
  }
}

export default new LoginPage();
```

```typescript
// test/specs/login.spec.ts
import LoginPage from '../pages/LoginPage.js';
import HomePage from '../pages/HomePage.js';

describe('Login flow', () => {
  it('should log in with valid credentials', async () => {
    await LoginPage.login('user@example.com', 'ValidPass1');
    await expect(HomePage.welcomeHeader).toBeDisplayed();
  });

  it('should show error for wrong password', async () => {
    await LoginPage.login('user@example.com', 'wrongpass');
    await LoginPage.waitForError();
    await expect(LoginPage.errorBanner).toHaveText('Invalid credentials');
  });
});
```

### Pattern 2 — Accessibility-id selector hierarchy

Always prefer selectors in this order. Each step down increases brittleness.

```typescript
// Tier 1 — accessibility-id (most stable, cross-platform)
const btn = $('~submit-button');

// Tier 2 — iOS predicate string (iOS only — faster than XPath, supports compound conditions)
const iosLabel = $('-ios predicate string:label == "Submit" AND enabled == true');

// Tier 2 — Android UIAutomator (Android only — supports scrolling and chaining)
const androidBtn = $('android=new UiSelector().text("Submit").className("android.widget.Button")');

// Tier 3 — XPath (last resort — slow, breaks on layout changes)
const header = $('//android.widget.TextView[@text="Dashboard"]');

// Anti-pattern: positional XPath — breaks on any layout change
// BAD: $('//android.view.ViewGroup[2]/android.widget.TextView[1]')

// Platform-conditional selector helper (import ChainablePromiseElement at top of file)
import type { ChainablePromiseElement } from 'webdriverio';

function byPlatform(ios: string, android: string): ChainablePromiseElement {
  return browser.isIOS ? $(ios) : $(android);
}
// Usage: const submitBtn = byPlatform('~submit-button', '~submit-button');
// More useful when accessibility-id differs between platforms:
// const settingsIcon = byPlatform('-ios predicate string:name == "settings-icon"',
//                                  'android=new UiSelector().description("Settings")');
```

### Pattern 3 — Explicit waits instead of `pause()`

```typescript
// Good: wait for element to be displayed (polls internally)
await $('~confirm-button').waitForDisplayed({ timeout: 8000 });

// Good: custom condition with waitUntil
await browser.waitUntil(
  async () => {
    const text = await $('~status-label').getText();
    return text === 'Payment complete';
  },
  { timeout: 10000, timeoutMsg: 'Payment did not complete in 10 s', interval: 500 }
);

// Good: wait for enabled state before interaction
await $('~submit-button').waitForEnabled({ timeout: 5000 });
await $('~submit-button').click();

// Anti-pattern: static pause
// BAD: await browser.pause(3000);
```

### Pattern 4 — Mobile gestures

WebDriverIO wraps Appium's W3C Actions API. Use `getRect()` (available from WebDriverIO v8) to fetch element bounds in one call, and supply `duration` to `move()` actions for reliable gesture speed.

```typescript
// Swipe left on a card — uses getRect() for combined location + size
async function swipeLeft(element: WebdriverIO.Element): Promise<void> {
  const { x, y, width, height } = await element.getRect();
  const startX = Math.round(x + width * 0.8);
  const endX   = Math.round(x + width * 0.2);
  const midY   = Math.round(y + height / 2);

  await browser.action('pointer')
    .move({ duration: 0, x: startX, y: midY })
    .down({ button: 0 })
    .move({ duration: 500, x: endX, y: midY })  // duration in ms for realistic swipe speed
    .up({ button: 0 })
    .perform();
}

// Long-press on an element
async function longPress(element: WebdriverIO.Element, durationMs = 1500): Promise<void> {
  const { x, y, width, height } = await element.getRect();
  await browser.action('pointer')
    .move({ duration: 0, x: Math.round(x + width / 2), y: Math.round(y + height / 2) })
    .down({ button: 0 })
    .pause(durationMs)
    .up({ button: 0 })
    .perform();
}

// Scroll down until an element is visible (returns the found element)
async function scrollToElement(locator: string, maxAttempts = 10): Promise<WebdriverIO.Element> {
  for (let i = 0; i < maxAttempts; i++) {
    const el = await $(locator);
    if (await el.isDisplayed()) return el;
    await browser.execute('mobile: scrollGesture', {
      left: 100, top: 300, width: 200, height: 400,
      direction: 'down', percent: 0.5,
    });
  }
  throw new Error(`Element ${locator} not found after ${maxAttempts} scroll attempts`);
}
```

### Pattern 5 — Parallel device execution  [community]

Use `wdio.conf.ts` capabilities array to define multiple devices. WebDriverIO runs specs against each capability in parallel when `maxInstances` > 1.

### Pattern 6 — App state management and auth setup  [community]

Never log in through the UI in every test. Use the `onPrepare` / `before` hooks to set auth tokens via deep-link or API, then launch the app in a pre-authenticated state. This cuts suite time dramatically and removes dependency on the login UI.

```typescript
// test/helpers/authHelper.ts
import fetch from 'node-fetch';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

/**
 * Obtain auth tokens via API (bypasses login UI).
 * Call once in wdio.conf.ts onPrepare or in a beforeAll block.
 */
export async function getAuthTokens(email: string, password: string): Promise<AuthTokens> {
  const res = await fetch(`${process.env.API_BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) throw new Error(`Auth failed: ${res.status}`);
  return res.json() as Promise<AuthTokens>;
}

/**
 * Inject tokens into the app via deep link — avoids UI login flow.
 * The app must handle the deep link scheme and store tokens in SecureStorage.
 */
export async function injectTokensViaDeepLink(tokens: AuthTokens): Promise<void> {
  const deepLink = `myapp://auth/inject?token=${encodeURIComponent(tokens.accessToken)}`;
  await browser.url(deepLink);
  await $('~home-screen').waitForDisplayed({ timeout: 5000 });
}
```

```typescript
// test/specs/dashboard.spec.ts
import { getAuthTokens, injectTokensViaDeepLink } from '../helpers/authHelper.js';

describe('Dashboard', () => {
  before(async () => {
    const tokens = await getAuthTokens('test@example.com', process.env.TEST_PASSWORD!);
    await injectTokensViaDeepLink(tokens);
  });

  it('should display user name in header', async () => {
    await expect($('~user-name-header')).toBeDisplayed();
  });
});
```

```typescript
// wdio.conf.ts
import type { Options } from '@wdio/types';

export const config: Options.Testrunner = {
  runner: 'local',
  maxInstances: 4,  // run 4 devices in parallel
  capabilities: [
    {
      platformName: 'iOS',
      'appium:deviceName': 'iPhone 15',
      'appium:platformVersion': '17.0',
      'appium:automationName': 'XCUITest',
      'appium:app': process.env.IOS_APP_PATH,
    },
    {
      platformName: 'Android',
      'appium:deviceName': 'Pixel 7',
      'appium:platformVersion': '13',
      'appium:automationName': 'UiAutomator2',
      'appium:app': process.env.ANDROID_APP_PATH,
    },
  ],
  services: [['appium', { args: { port: 4723 }, command: 'appium' }]],
  specs: ['./test/specs/**/*.spec.ts'],
  framework: 'mocha',
  reporters: ['spec', ['allure', { outputDir: 'allure-results' }]],
};
```

---

## Selector / Locator Strategy

Priority order (highest to lowest stability):

| Priority | Selector | Example | Notes |
|----------|----------|---------|-------|
| 1 | `~accessibility-id` | `$('~submit-btn')` | Set `accessibilityLabel` (iOS) or `contentDescription` (Android) |
| 2 | `-ios predicate string` | `$('-ios predicate string:label == "Submit"')` | iOS only; faster than XPath |
| 3 | `-android uiautomator` | `$('android=new UiSelector().text("Submit")')` | Android only; flexible |
| 4 | `id` | `$('~com.example.app:id/submit_btn')` | Android resource-id; brittle on refactor |
| 5 | `class name` | `$('android.widget.Button')` | Useful for generic elements |
| 6 | XPath | `$('//android.widget.Button[@text="Submit"]')` | Last resort — slow, fragile |

**Never use** positional XPath (`//*[2]`) or CSS selectors for native apps (no DOM).

---

## Real-World Gotchas  [community]

1. **[community] Appium session not cleaning up between tests** — If `driver.quit()` is never called (e.g. test throws before teardown), the next test connects to a zombie session and sees stale state. WHY: Appium keeps sessions alive until explicit quit or timeout (default 60 s). Fix: always call `browser.deleteSession()` in `after` hook; set `newCommandTimeout: 0` in capabilities to prevent silent timeout disconnects.

2. **[community] `pause()` hides real timing bugs** — Developers add `browser.pause(2000)` when a flaky test appears, masking an underlying race condition. WHY: The root cause is usually an animation, a loading spinner, or a debounced network call. Static delays pass on fast machines and fail on slow CI runners. Fix: use `waitForDisplayed` / `waitUntil` with meaningful conditions.

3. **[community] iOS XCUITest crashes on real devices due to `WDA` signing** — WebDriverAgent (WDA) must be signed with a valid provisioning profile when targeting real iOS devices. Tests work fine on simulators but throw `SessionNotCreatedException` on device CI. WHY: Apple enforces code signing at install time. Fix: add `appium:xcodeOrgId` and `appium:xcodeSigningId` to capabilities; store the cert in CI secrets.

4. **[community] `setText` vs `setValue` leaves extra characters** — On Android, `$el.setValue('text')` sometimes prepends previous field content. WHY: WebDriverIO's `setValue` calls `clear()` then `sendKeys()`; but on some Android versions `clear()` does not fully reset the field focus. Fix: call `$el.clearValue()` explicitly, then `$el.addValue('text')`, or use `mobile: type` Appium command.

5. **[community] Appium version mismatch between dev and CI** — The local developer runs Appium 2.x; the CI pipeline installs `appium@latest` which may be a minor patch ahead and removes a deprecated capability. Tests fail only in CI with cryptic `unknown serverError`. WHY: npm's `latest` tag resolves to the newest published version. Fix: pin `"appium": "2.x.x"` in `devDependencies`; use `npx appium@2.5.0` in CI startup scripts.

6. **[community] Flaky tests from `getLocation()` race on Android** — Calling `$el.getLocation()` immediately after `waitForDisplayed()` can still return `{x:0, y:0}` if the element is animating into position. WHY: `waitForDisplayed` resolves when the element is in the viewport but before its final transform completes. Fix: add a short `waitUntil(() => el.getLocation().then(l => l.x > 0))` or use `waitForStable` (WebDriverIO ≥8).

7. **[community] `maxInstances` exceeding available emulators deadlocks** — Setting `maxInstances: 8` when only 2 Android AVDs are running causes 6 sessions to hang waiting for a device. WHY: Appium queues sessions but does not reject them, so tests appear to be running while actually blocked. Fix: match `maxInstances` to the number of licensed device slots or running emulators; use `appium:avd` capability to auto-start AVDs.

8. **[community] Deep-link auth injection fails on Android due to intent flag mismatch** — `browser.url('myapp://auth/inject?...')` silently does nothing on Android if the activity's `launchMode` is `singleTop` or `singleTask` and the app is already foregrounded. WHY: Android reuses the existing activity and may not call `onNewIntent()` unless the flag `FLAG_ACTIVITY_SINGLE_TOP` is set in the ADB intent. Fix: use `driver.execute('mobile: deepLink', { url: deepLinkUrl, package: 'com.example.myapp' })` (Appium 2 UiAutomator2 command) which correctly routes the intent; or restart the app with `launchApp({ url: deepLinkUrl })` capability.

---

## CI Considerations

### Appium driver installation in CI (Appium 2.x)

Appium 2 ships without drivers. Install them as part of the CI setup phase, and cache `APPIUM_HOME` by its driver manifest hash.

```yaml
# .github/workflows/mobile-tests.yml (excerpt)
- name: Cache Appium drivers
  uses: actions/cache@v4
  with:
    path: ${{ runner.temp }}/appium
    key: appium-drivers-${{ hashFiles('.appiumrc.json') }}

- name: Install Appium drivers
  run: |
    export APPIUM_HOME="${{ runner.temp }}/appium"
    npx appium@2.5.0 driver install uiautomator2
    npx appium@2.5.0 driver install xcuitest

- name: Start Appium server
  run: |
    export APPIUM_HOME="${{ runner.temp }}/appium"
    npx appium@2.5.0 --port 4723 --log appium.log &
    npx wait-on tcp:4723 --timeout 30000
```

`.appiumrc.json` (pins driver versions for cache-key stability):
```json
{
  "server": {
    "port": 4723,
    "log-level": "info"
  },
  "driver": {
    "uiautomator2": "3.7.5",
    "xcuitest": "7.28.3"
  }
}
```

### Appium server startup in CI

```yaml
# .github/workflows/mobile-tests.yml (excerpt)
- name: Start Appium server
  run: |
    npx appium@2.5.0 &
    npx wait-on tcp:4723 --timeout 30000
  env:
    APPIUM_HOME: ${{ runner.temp }}/appium
```

- **Pin the Appium version** — use `npx appium@2.x.x` not `npx appium`.
- **Use `wait-on`** — confirm port 4723 is listening before running tests; avoids race where test runner starts before Appium is ready.
- **Set `APPIUM_HOME`** — isolates plugin/driver installations per CI job; prevents cache collisions across parallel matrix jobs.

### Disable animations on Android

```typescript
// In wdio.conf.ts capabilities — disables window/transition/animator durations
'appium:settings[animationDuration]': 0,
'appium:settings[waitForSelectorTimeout]': 0,
```

Or via ADB in CI setup step:
```bash
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
```

### Disable iOS animations

Add to `beforeAll` hook:
```typescript
if (browser.isIOS) {
  // Disable animations in iOS Simulator via launch arguments in capabilities:
  // 'appium:processArguments': { args: ['-UIAnimationDragCoefficient', '0'] }
  // For XCUITest driver (Appium 2.x), set via capability:
  // 'appium:settings[snapshotMaxDepth]': 62  (improves element lookup speed)
}
```

### Artifact collection on failure

```typescript
// wdio.conf.ts
import fs from 'fs';
import path from 'path';

afterTest: async (test, _context, { error }) => {
  if (error) {
    const timestamp = Date.now();
    await browser.saveScreenshot(`./allure-results/screenshot-${timestamp}.png`);
    const source = await browser.getPageSource();
    fs.writeFileSync(`./allure-results/page-source-${timestamp}.xml`, source);
  }
}
```

### Environment-specific capabilities

```typescript
// Load app path from env vars — never hardcode paths
'appium:app': process.env.IOS_APP_PATH ?? path.resolve(__dirname, '../apps/MyApp.app'),
'appium:udid': process.env.IOS_DEVICE_UDID ?? 'auto',
```

---

## Key APIs

| Method (TypeScript) | Purpose | When to use |
|---------------------|---------|-------------|
| `$('~id')` | Find element by accessibility-id | Default selector for all interactive elements |
| `$$('~class')` | Find all matching elements | Lists, grids, repeated items |
| `el.click()` | Tap element | Standard button/link interaction |
| `el.setValue(text)` | Clear + type text | Form inputs |
| `el.clearValue()` | Clear field | Before re-entering text |
| `el.getText()` | Get visible text | Assertions on labels |
| `el.getAttribute(name)` | Get element attribute | Checking state flags (e.g. `enabled`, `selected`) |
| `el.getRect()` | Get `{x, y, width, height}` in one call | Gesture calculations (replaces `getLocation()+getSize()`) |
| `el.waitForDisplayed({ timeout })` | Wait for element to appear | After navigation, async loads |
| `el.waitForEnabled({ timeout })` | Wait for element to become interactive | Before clicking submit buttons |
| `el.isDisplayed()` | Boolean visibility check | Conditional logic in helpers |
| `browser.waitUntil(fn, opts)` | Custom wait condition | Complex state assertions |
| `browser.action('pointer')` | W3C pointer action (gestures) | Swipe, long-press, drag |
| `browser.execute('mobile: scrollGesture', opts)` | Appium scroll gesture | Scroll to off-screen element |
| `browser.saveScreenshot(path)` | Capture PNG | On-failure artifacts |
| `browser.getPageSource()` | Get XML page source | Debugging selector issues |
| `browser.isIOS` / `browser.isAndroid` | Platform detection | Platform-specific branches |
| `browser.deleteSession()` | Close Appium session | `after()` hook teardown |
