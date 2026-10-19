# Appium / WebDriverIO Patterns & Best Practices (TypeScript)
<!-- lang: TypeScript | sources: training knowledge (WebFetch + WebSearch unavailable) | iteration: 10 | score: 100/100 | date: 2026-04-27 -->
<!-- Note: WebFetch and WebSearch were unavailable during generation. Synthesized from official docs training knowledge + community experience. -->
<!-- Re-run `/qa-refine Appium/WebDriverIO` with WebFetch enabled to pull live sources. -->

## TypeScript Project Setup

### tsconfig.json for WebDriverIO test projects

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "outDir": "./dist",
    "rootDir": "./",
    "types": ["node", "@wdio/globals/types", "@wdio/mocha-framework"],
    "lib": ["ES2022"]
  },
  "include": ["test/**/*.ts", "src/**/*.ts", "wdio.conf.ts"],
  "exclude": ["node_modules", "dist"]
}
```

Key points:
- `"types": ["node", "@wdio/globals/types", "@wdio/mocha-framework"]` — adds `browser`, `$`, `$$`, `driver`, `describe`, `it` globals without ambient conflicts from other test frameworks.
- `"module": "NodeNext"` with `"moduleResolution": "NodeNext"` — required for `.js` extension imports in ESM projects. Use `"CommonJS"` if your project is CJS.
- Never use `@types/webdriverio` (deprecated); use `@wdio/globals/types` and `webdriverio` directly.

### Required `devDependencies` (pinned versions)

```json
{
  "devDependencies": {
    "webdriverio": "8.x.x",
    "@wdio/cli": "8.x.x",
    "@wdio/local-runner": "8.x.x",
    "@wdio/mocha-framework": "8.x.x",
    "@wdio/spec-reporter": "8.x.x",
    "@wdio/appium-service": "8.x.x",
    "@wdio/allure-reporter": "8.x.x",
    "@wdio/types": "8.x.x",
    "appium": "2.x.x",
    "appium-uiautomator2-driver": "3.x.x",
    "appium-xcuitest-driver": "7.x.x",
    "typescript": "5.x.x",
    "ts-node": "10.x.x"
  }
}
```

Pin `@wdio/types` to the same minor version as `webdriverio` — they're released separately and version drift causes TypeScript compilation failures with `strict: true`.

---

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

### Pattern 2 — Typed Page Object base class

Give every Page Object a shared base class that encodes the `waitForDisplayed` entry guard, screenshot-on-fail helper, and platform detection. This eliminates copy-paste boilerplate and keeps the type system consistent across all page objects.

```typescript
// src/pages/BasePage.ts
import type { ChainablePromiseElement } from 'webdriverio';

export abstract class BasePage {
  /**
   * Override in each subclass to point at the root element of the screen.
   * Used by `waitForScreenLoaded()` to confirm navigation completed.
   */
  protected abstract get rootElement(): ChainablePromiseElement;

  async waitForScreenLoaded(timeout = 10_000): Promise<void> {
    await this.rootElement.waitForDisplayed({ timeout });
  }

  protected get isIOS(): boolean {
    return browser.isIOS;
  }

  protected get isAndroid(): boolean {
    return browser.isAndroid;
  }

  /** Conditional selector — return the matching platform locator */
  protected byPlatform(ios: string, android: string): ChainablePromiseElement {
    return this.isIOS ? $(ios) : $(android);
  }

  /** Capture screenshot + page source on any unexpected state */
  async captureDebugArtifacts(label: string): Promise<void> {
    const ts = Date.now();
    await browser.saveScreenshot(`./allure-results/${label}-${ts}.png`);
    const src = await browser.getPageSource();
    require('fs').writeFileSync(`./allure-results/${label}-${ts}.xml`, src);
  }
}
```

```typescript
// src/pages/DashboardPage.ts
import { BasePage } from './BasePage.js';
import type { ChainablePromiseElement } from 'webdriverio';

class DashboardPage extends BasePage {
  protected get rootElement(): ChainablePromiseElement {
    return $('~dashboard-screen');
  }

  get userNameHeader(): ChainablePromiseElement {
    return $('~user-name-header');
  }

  get notificationBadge(): ChainablePromiseElement {
    return this.byPlatform(
      '-ios predicate string:name == "notification-badge"',
      'android=new UiSelector().description("notification-badge")',
    );
  }
}

export default new DashboardPage();
```



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

// Good (WebDriverIO ≥8): waitForStable — waits for element position to stop changing.
// Use after waitForDisplayed when the element is still animating into final position.
await $('~animated-card').waitForStable({ timeout: 5000 });
const { x, y } = await $('~animated-card').getLocation();
// Now x, y are the final resting coordinates — safe to use for gesture math.

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

Use `wdio.conf.ts` capabilities array to define multiple devices. WebDriverIO runs specs against each capability in parallel when `maxInstances` > 1. Keep test state fully isolated — no shared file handles, no shared accounts, no shared database rows.

```typescript
// wdio.conf.ts — typed capabilities with parallel execution
import type { Options } from '@wdio/types';

// Type helper: enforce required Appium keys are present at compile time
type AppiumCaps = WebdriverIO.Capabilities & {
  'appium:automationName': string;
  'appium:app': string;
  'appium:newCommandTimeout': number;  // prevent zombie sessions
};

const iosCaps: AppiumCaps = {
  platformName: 'iOS',
  'appium:deviceName': 'iPhone 15',
  'appium:platformVersion': '17.0',
  'appium:automationName': 'XCUITest',
  'appium:app': process.env.IOS_APP_PATH!,
  'appium:newCommandTimeout': 120,
  'appium:noReset': false,          // fresh install for each session
  'appium:processArguments': { args: ['-UIAnimationDragCoefficient', '0'] },
};

const androidCaps: AppiumCaps = {
  platformName: 'Android',
  'appium:deviceName': 'Pixel 7',
  'appium:platformVersion': '13',
  'appium:automationName': 'UiAutomator2',
  'appium:app': process.env.ANDROID_APP_PATH!,
  'appium:newCommandTimeout': 120,
  'appium:fullReset': false,
  'appium:settings[animationDuration]': 0,
  'appium:settings[waitForSelectorTimeout]': 0,
};

export const config: Options.Testrunner = {
  runner: 'local',
  maxInstances: 2,          // one per device type; increase for device farm
  capabilities: [iosCaps, androidCaps],
  services: [['appium', { args: { port: 4723 }, command: 'appium' }]],
  specs: ['./test/specs/**/*.spec.ts'],
  framework: 'mocha',
  mochaOpts: { timeout: 120_000 },
  reporters: ['spec', ['allure', { outputDir: 'allure-results' }]],
};
```

**`appium:noReset` vs `appium:fullReset`:** `noReset: true` skips app reinstall (fast, but carries state between tests). `fullReset: true` uninstalls + reinstalls (clean, slow). The recommended default for CI is `noReset: false, fullReset: false` — reinstalls the app but keeps system data. Set `noReset: true` only for smoke suites that must execute fast and don't mutate persistent state.

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

### Pattern 7 — Network interception / mock with Appium BiDi  [community]

Appium 2 + WebDriverIO 8 supports W3C BiDi network interception for simulators/emulators. Use it to stub flaky third-party APIs, simulate error states, or speed up tests by eliminating real network calls. **Note:** BiDi network interception requires Appium's `bidiEnabled: true` capability and is not yet supported on all real-device platforms — fall back to a test HTTP proxy (e.g. `mockttp`) for device farms.

```typescript
// test/helpers/networkMock.ts — wraps WebDriverIO mock API for mobile
export async function mockApiEndpoint(
  urlPattern: string,
  responseBody: unknown,
  statusCode = 200,
): Promise<WebdriverIO.Mock> {
  const mock = await browser.mock(urlPattern, { method: 'GET' });
  mock.respond(responseBody, {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
  });
  return mock;
}

export async function mockApiError(urlPattern: string, statusCode = 500): Promise<WebdriverIO.Mock> {
  const mock = await browser.mock(urlPattern, { method: 'GET' });
  mock.respond({ error: 'Internal Server Error' }, { statusCode });
  return mock;
}
```

```typescript
// test/specs/dashboard-offline.spec.ts
import { mockApiError } from '../helpers/networkMock.js';
import DashboardPage from '../pages/DashboardPage.js';

describe('Dashboard — error states', () => {
  let errorMock: WebdriverIO.Mock;

  before(async () => {
    errorMock = await mockApiError('**/api/dashboard*', 503);
  });

  after(async () => {
    await errorMock.restore();
  });

  it('should show offline banner when API returns 503', async () => {
    await browser.url('myapp://home');
    await expect($('~offline-banner')).toBeDisplayed();
  });
});
```

### Pattern 8 — `beforeEach` app reset for test isolation

Never assume the app is in a known state when a test starts. Use `beforeEach` to terminate and relaunch the app, clearing any in-memory state or partially-completed flows from the previous test.

```typescript
// test/specs/checkout.spec.ts
import LoginPage from '../pages/LoginPage.js';
import { getAuthTokens, injectTokensViaDeepLink } from '../helpers/authHelper.js';

describe('Checkout flow', () => {
  beforeEach(async () => {
    // Terminate the app completely — clears all in-memory navigation state
    await driver.terminateApp(
      browser.isIOS ? 'com.example.myapp' : 'com.example.myapp',
    );
    // Relaunch from a clean state
    await driver.activateApp(
      browser.isIOS ? 'com.example.myapp' : 'com.example.myapp',
    );
    // Re-inject auth tokens so each test starts authenticated
    const tokens = await getAuthTokens('test@example.com', process.env.TEST_PASSWORD!);
    await injectTokensViaDeepLink(tokens);
  });

  it('should add item to cart and proceed to checkout', async () => {
    await $('~product-item-0').click();
    await $('~add-to-cart-btn').waitForDisplayed({ timeout: 5000 });
    await $('~add-to-cart-btn').click();
    await expect($('~cart-count')).toHaveText('1');
  });

  it('should apply promo code correctly', async () => {
    // Starts fresh — no leftover cart state from previous test
    await $('~promo-field').setValue('SAVE20');
    await expect($('~discount-line')).toBeDisplayed();
  });
});
```

**`terminateApp` vs `closeApp`:** `terminateApp` sends SIGKILL on iOS and `force-stop` on Android — guaranteed clean slate. `closeApp` sends the app to background but keeps it alive in memory, meaning navigation state and singletons persist. Always use `terminateApp` in `beforeEach` for isolated tests.

---

## Selector / Locator Strategy

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

9. **[community] `browser.mock()` only works on simulators/emulators — silently no-ops on real devices** — Teams that work locally on simulators add network mocks via `browser.mock()`, then ship to CI which runs on real devices. The mocks are silently ignored and tests that relied on stubbed error responses always see the real API, breaking error-state coverage. WHY: WebDriverIO's `browser.mock()` uses Chrome DevTools Protocol (CDP) interception, which is only available in the simulator's browser runtime, not on physical hardware. Fix: use a real HTTP proxy (e.g. `mockttp` or `mitmproxy`) for device-farm scenarios; gate mock-based tests with `if (browser.isMobile && !process.env.REAL_DEVICE)`.

10. **[community] TypeScript `strict: true` breaks at runtime when `@wdio/types` version lags behind `webdriverio`** — Enabling `strict: true` plus `exactOptionalPropertyTypes` causes TypeScript to flag WebDriverIO's own type definitions as invalid when the `@wdio/types` package version is one patch behind `webdriverio`. Tests fail to compile in CI because `devDependencies` resolves `@wdio/types` and `webdriverio` independently. WHY: `@wdio/types` and `webdriverio` are released as separate packages and their versions can drift. Fix: pin both to the same exact version in `package.json`; use `overrides` (npm v7+) or `resolutions` (yarn) to enforce the constraint.

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

### Performance tuning — element lookup speed

Slow element lookups are the most common cause of flaky timeouts on CI. These settings directly reduce the time Appium spends building the element tree:

```typescript
// In capabilities — tune XCUITest element lookup performance (iOS)
'appium:settings[snapshotMaxDepth]': 62,         // default 50; 62 handles all standard iOS apps
'appium:settings[useFirstMatch]': true,          // stop after first match (don't scan full tree)
'appium:settings[snapshotTimeout]': 15000,       // give slow simulators more time

// In capabilities — tune UiAutomator2 performance (Android)
'appium:settings[waitForSelectorTimeout]': 0,   // disable implicit wait (use explicit waits only)
'appium:settings[normalizeTagNames]': false,     // skip tag normalisation (faster XML serialisation)
'appium:elementResponseAttributes': 'type,label,value,name,rect',  // reduce payload size
```

**Rule of thumb:** If element lookups average > 500 ms on CI, enable `useFirstMatch: true` (iOS) first, then reduce `snapshotMaxDepth` if the app's view hierarchy is shallow. Never lower `snapshotMaxDepth` below 50 without verifying all elements in your deepest screen are still reachable.

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
| `el.waitForStable({ timeout })` | Wait for element to stop moving | After `waitForDisplayed` when element is still animating |
| `el.isDisplayed()` | Boolean visibility check | Conditional logic in helpers |
| `browser.waitUntil(fn, opts)` | Custom wait condition | Complex state assertions |
| `browser.mock(url, opts)` | Intercept network request | Stub APIs, simulate error states |
| `mock.respond(body, opts)` | Return fixed response for mocked URL | Error-state and offline tests |
| `mock.restore()` | Remove network mock | `after()` hook cleanup |
| `browser.action('pointer')` | W3C pointer action (gestures) | Swipe, long-press, drag |
| `browser.execute('mobile: scrollGesture', opts)` | Appium scroll gesture | Scroll to off-screen element |
| `browser.execute('mobile: deepLink', opts)` | Open deep-link with correct Android intent | Auth injection, deep navigation |
| `browser.saveScreenshot(path)` | Capture PNG | On-failure artifacts |
| `browser.getPageSource()` | Get XML page source | Debugging selector issues |
| `browser.isIOS` / `browser.isAndroid` | Platform detection | Platform-specific branches |
| `browser.deleteSession()` | Close Appium session | `after()` hook teardown |

---

## Retry & Flake-Quarantine Strategy

### Built-in spec retry in WebDriverIO

WebDriverIO's `specFileRetries` re-runs an entire spec file when it fails. Use it as a last resort for known-flaky infra interactions (e.g. emulator cold-start), not as a substitute for fixing the root cause.

```typescript
// wdio.conf.ts
export const config: Options.Testrunner = {
  // ...
  specFileRetries: 1,                    // re-run failing spec files once
  specFileRetriesDelay: 5,               // wait 5 s before retry (emulator settle time)
  specFileRetriesDeferred: false,        // retry immediately (not at end of suite)
};
```

### Mocha-level test retry

For individual test retries (not whole file), use Mocha's `this.retries(N)` inside a `describe` block:

```typescript
describe('Flaky payment flow', () => {
  // Retry this entire describe block's tests up to 2 times
  before(function () {
    this.retries(2);
  });

  it('should complete payment', async () => {
    // ...
  });
});
```

**Quarantine pattern:** Tag truly-flaky tests with a `@quarantine` label and exclude them from the default CI run. Re-run quarantined tests nightly against a stable device farm. This prevents known flaky tests from blocking PRs while still tracking them for eventual fix.

```typescript
// wdio.conf.ts — exclude quarantined tests from standard run
exclude: process.env.INCLUDE_QUARANTINE ? [] : ['./test/specs/quarantine/**/*.spec.ts'],
```

### Framework selection guidance

| Framework | When to choose |
|-----------|---------------|
| **Mocha** (default) | Most mobile projects — familiar, flexible, good TypeScript support |
| **Jasmine** | Teams coming from Angular — behavioural matchers feel natural |
| **Cucumber** | Stakeholder-readable specs needed — BDD with `.feature` files |

For Cucumber with WebDriverIO, install `@wdio/cucumber-framework` and `@cucumber/cucumber`:

```typescript
// wdio.conf.ts (Cucumber variant)
import type { Options } from '@wdio/types';

export const config: Options.Testrunner = {
  framework: 'cucumber',
  specs: ['./test/features/**/*.feature'],
  cucumberOpts: {
    require: ['./test/step-definitions/**/*.ts'],
    timeout: 60000,
    tags: process.env.CUCUMBER_TAGS ?? '',    // filter tags in CI via env var
  },
  // ... rest of config
};
```

```typescript
// test/step-definitions/login.steps.ts
import { Given, When, Then } from '@cucumber/cucumber';
import LoginPage from '../../src/pages/LoginPage.js';
import DashboardPage from '../../src/pages/DashboardPage.js';

Given('I am on the login screen', async () => {
  await LoginPage.waitForScreenLoaded();
});

When('I log in as {string} with password {string}', async (email: string, password: string) => {
  await LoginPage.login(email, password);
});

Then('I should see the dashboard', async () => {
  await DashboardPage.waitForScreenLoaded();
  await expect(DashboardPage.userNameHeader).toBeDisplayed();
});
```

---

## Visual Regression Testing

Use `@wdio/visual-service` for screenshot-based visual regression testing on mobile. It integrates directly into the WebDriverIO lifecycle, storing baseline images per device/platform and comparing against them on subsequent runs.

```typescript
// wdio.conf.ts (add visual service)
import type { Options } from '@wdio/types';

export const config: Options.Testrunner = {
  // ...existing config...
  services: [
    ['appium', { args: { port: 4723 }, command: 'appium' }],
    ['visual', {
      baselineFolder: './test/visual/baselines',
      screenshotPath: './allure-results/visual',
      formatImageName: '{tag}-{platformName}-{deviceName}',  // unique baseline per device
      savePerInstance: true,           // one baseline per device/platform combo
      autoSaveBaseline: true,          // create baseline if it doesn't exist
      blockOutStatusBar: true,         // mask dynamic status bar (time, battery %)
      blockOutToolBar: true,           // mask iOS/Android navigation bars
      compareOptions: {
        scaleImagesToSameSize: true,   // handle different screen densities
        ignoreAntialiasing: true,
      },
    }],
  ],
};
```

```typescript
// test/specs/visual.spec.ts — visual regression check
describe('Dashboard visual regression', () => {
  it('should match baseline screenshot', async () => {
    await DashboardPage.waitForScreenLoaded();
    // Check full screen against stored baseline
    await expect(browser).toMatchScreenSnapshot('dashboard-home');
  });

  it('should match product card element', async () => {
    const card = $('~product-card-0');
    await card.waitForDisplayed({ timeout: 5000 });
    // Check only the element — faster and more stable than full screen
    await expect(card).toMatchElementSnapshot('product-card');
  });
});
```

**Visual testing gotchas:**
- Always use `blockOutStatusBar: true` — the status bar shows the current time and will fail every snapshot at a different minute.
- Use `formatImageName` with `{platformName}-{deviceName}` — iOS and Android render fonts differently; a shared baseline fails cross-platform.
- Set `scaleImagesToSameSize: true` when running on multiple screen densities (e.g. Pixel 6 at 2.6x vs Galaxy S20 at 3.0x dpi).
- Store baseline images in git LFS for large teams — raw PNGs can inflate the repo significantly over hundreds of snapshots.

---

## Data-Driven Testing

Use `mocha`'s data table approach or a simple TypeScript array to drive multiple variants through the same test flow. This catches form validation edge cases and localisation issues without duplicating test code.

```typescript
// test/specs/form-validation.spec.ts
interface LoginTestCase {
  description: string;
  email: string;
  password: string;
  expectedError: string;
}

const INVALID_CREDENTIALS: LoginTestCase[] = [
  { description: 'empty email',      email: '',              password: 'Pass123!', expectedError: 'Email is required' },
  { description: 'invalid email',    email: 'notanemail',    password: 'Pass123!', expectedError: 'Enter a valid email' },
  { description: 'short password',   email: 'a@example.com', password: 'abc',      expectedError: 'Password too short' },
  { description: 'wrong password',   email: 'a@example.com', password: 'WrongP@ss1', expectedError: 'Invalid credentials' },
];

describe('Login validation', () => {
  for (const tc of INVALID_CREDENTIALS) {
    it(`should show error for ${tc.description}`, async () => {
      await LoginPage.login(tc.email, tc.password);
      await LoginPage.waitForError();
      await expect(LoginPage.errorBanner).toHaveText(tc.expectedError);
    });
  }
});
```

**Pattern note:** Keep data tables in separate JSON/TypeScript files for large datasets. Import with `import type` to get type safety and zero runtime cost. For localisation testing, load locale strings from the same source as the production app — do not hardcode translated strings in test data.

---

## Reporting & Observability

### Allure reporter with environment metadata

```typescript
// wdio.conf.ts — Allure with device metadata
reporters: [
  'spec',
  ['allure', {
    outputDir: 'allure-results',
    disableWebdriverStepsReporting: false,
    disableWebdriverScreenshotsReporting: false,
    addConsoleLogs: true,
  }],
],

onPrepare: async (config, capabilities) => {
  // Write Allure environment.properties so reports show device info
  const lines = (capabilities as WebdriverIO.Capabilities[]).map(cap =>
    `${cap.platformName}_device=${cap['appium:deviceName'] ?? 'unknown'}`
  );
  require('fs').writeFileSync('allure-results/environment.properties', lines.join('\n'));
},
```

Generate and open Allure report after a run:
```bash
npx allure generate allure-results --clean -o allure-report
npx allure open allure-report
```

---

## Typed Appium Mobile Command Helpers

`browser.execute('mobile: <command>', args)` is untyped by default — the argument object is `unknown`. Define typed wrapper functions to get compile-time safety and IDE autocompletion.

```typescript
// test/helpers/mobileCommands.ts

/** Scroll to an element by predicate (iOS XCUITest only) */
export async function iosScrollTo(predicate: string, direction: 'up' | 'down' = 'down'): Promise<void> {
  await browser.execute('mobile: scroll', { direction, predicateString: predicate });
}

/** Set clipboard text (both platforms) */
export async function setClipboard(text: string): Promise<void> {
  const encoded = Buffer.from(text).toString('base64');
  await browser.execute('mobile: setClipboard', {
    content: encoded,
    contentType: 'plaintext',
  });
}

/** Get clipboard text */
export async function getClipboard(): Promise<string> {
  const encoded = await browser.execute('mobile: getClipboard', { contentType: 'plaintext' }) as string;
  return Buffer.from(encoded, 'base64').toString('utf8');
}

/** Tap at absolute screen coordinates (bypasses element lookup) */
export async function tapAt(x: number, y: number): Promise<void> {
  await browser.action('pointer')
    .move({ duration: 0, x, y })
    .down({ button: 0 })
    .up({ button: 0 })
    .perform();
}

/** Terminate + relaunch app — shorthand for beforeEach isolation */
export async function resetApp(bundleId: string): Promise<void> {
  await driver.terminateApp(bundleId);
  await driver.activateApp(bundleId);
}
```

### Avoiding WDA port conflicts in parallel iOS runs

When running multiple iOS simulators in parallel, each session needs a unique WebDriverAgent port. Set `appium:wdaLocalPort` per capability to avoid `Address already in use` errors:

```typescript
// wdio.conf.ts — unique WDA ports per parallel session
const iosCapabilities = ['iPhone 15', 'iPhone 14', 'iPad Pro'].map((device, index) => ({
  platformName: 'iOS' as const,
  'appium:deviceName': device,
  'appium:platformVersion': '17.0',
  'appium:automationName': 'XCUITest',
  'appium:app': process.env.IOS_APP_PATH!,
  'appium:wdaLocalPort': 8100 + index,   // 8100, 8101, 8102 — no collisions
  'appium:newCommandTimeout': 120,
}));
```

---

## Device Farm Integration (BrowserStack / Sauce Labs)

Switch from a local Appium server to a cloud device farm by swapping `services` and `hostname` in `wdio.conf.ts`. Use environment variables so the same config works locally and in CI.

```typescript
// wdio.conf.ts — cloud device farm configuration
import type { Options } from '@wdio/types';

const isCI = !!process.env.CI;

export const config: Options.Testrunner = {
  runner: 'local',
  hostname: isCI ? 'hub-cloud.browserstack.com' : '127.0.0.1',
  port: isCI ? 443 : 4723,
  protocol: isCI ? 'https' : 'http',
  path: isCI ? '/wd/hub' : '/',

  capabilities: [
    {
      platformName: 'iOS',
      'appium:deviceName': isCI ? 'iPhone 15' : 'iPhone 15 Simulator',
      'appium:platformVersion': '17',
      'appium:automationName': 'XCUITest',
      'appium:app': isCI
        ? `bs://YOUR_BROWSERSTACK_APP_ID`            // pre-uploaded app hash
        : process.env.IOS_APP_PATH!,
      // BrowserStack-specific capabilities
      ...(isCI && {
        'bstack:options': {
          userName: process.env.BROWSERSTACK_USERNAME!,
          accessKey: process.env.BROWSERSTACK_ACCESS_KEY!,
          projectName: 'MyApp Mobile Tests',
          buildName: `Build ${process.env.BUILD_NUMBER ?? 'local'}`,
          sessionName: 'iOS Smoke Suite',
          networkLogs: true,
          deviceLogs: true,
        },
      }),
    },
  ],

  // No appium service when using cloud — the cloud manages the Appium server
  services: isCI ? [] : [['appium', { args: { port: 4723 }, command: 'appium' }]],
  specs: ['./test/specs/**/*.spec.ts'],
  framework: 'mocha',
};
```

**Cloud farm tips:**
- Pre-upload your `.ipa`/`.apk` once and cache the app hash — re-uploading for every CI run slows down session creation.
- Set `networkLogs: true` and `deviceLogs: true` only when debugging; they add latency to every command.
- Use BrowserStack's `buildName` with your CI build number so runs are grouped in the dashboard.
- For Sauce Labs, replace `bstack:options` with `sauce:options` and update hostname to `ondemand.us-west-1.saucelabs.com`.

---

## Accessibility Validation

Use Appium's built-in accessibility scan to catch WCAG violations during test execution. Available for Android via `mobile: accessibilityScan` (UiAutomator2 2.x+).

```typescript
// test/specs/accessibility.spec.ts
describe('Dashboard accessibility', () => {
  it('should have no critical accessibility violations', async () => {
    await DashboardPage.waitForScreenLoaded();

    // Android: run accessibility scan on current screen
    if (browser.isAndroid) {
      const result = await driver.execute('mobile: accessibilityScan') as {
        issues: Array<{ type: string; element: string; message: string }>;
      };
      const criticalIssues = result.issues.filter(i => i.type === 'ERROR');
      expect(criticalIssues).toHaveLength(0,
        `Accessibility errors found:\n${criticalIssues.map(i => `  ${i.element}: ${i.message}`).join('\n')}`
      );
    }

    // iOS: verify accessibility-id presence on all interactive elements
    if (browser.isIOS) {
      const buttons = await $$('//XCUIElementTypeButton');
      for (const btn of buttons) {
        const label = await btn.getAttribute('label');
        const name = await btn.getAttribute('name');
        expect(label || name).toBeTruthy(
          `Button missing accessibility label — add accessibilityLabel in the app`
        );
      }
    }
  });
});
```

---

## Test Tagging & Selective Execution

Use Mocha's `grep` option (via `mochaOpts`) or filename conventions to run subsets of your suite without separate config files.

```typescript
// wdio.conf.ts — support --grep via environment variable
export const config: Options.Testrunner = {
  // ...
  mochaOpts: {
    timeout: 120_000,
    // Run only tests matching the tag: WDIO_GREP="@smoke" npx wdio run wdio.conf.ts
    grep: process.env.WDIO_GREP ?? undefined,
  },
};
```

```typescript
// test/specs/checkout.spec.ts — tag-based filtering with @smoke, @regression, @slow
describe('Checkout flow @regression', () => {
  it('should add item to cart @smoke', async () => { /* ... */ });
  it('should apply promo code @regression', async () => { /* ... */ });
  it('should complete full payment @slow @regression', async () => { /* ... */ });
});
```

**Execution examples:**
```bash
# Run only smoke tests
WDIO_GREP="@smoke" npx wdio run wdio.conf.ts

# Run all regression tests excluding slow ones
WDIO_GREP="@regression" npx wdio run wdio.conf.ts --mochaOpts.grep "@slow" --mochaOpts.invertGrep

# Run against a specific device capability (uses spec suite feature)
npx wdio run wdio.conf.ts --suite ios-only
```

Add named suites to `wdio.conf.ts` for structured CI matrix runs:

```typescript
// wdio.conf.ts
suites: {
  'ios-only':     ['./test/specs/**/*.spec.ts'],    // filtered by iOS capability
  'android-only': ['./test/specs/**/*.spec.ts'],
  'smoke':        ['./test/specs/smoke/**/*.spec.ts'],
  'visual':       ['./test/specs/visual/**/*.spec.ts'],
},
```

---

## Environment & Secrets Management

Never hardcode credentials, app paths, or device UDIDs in `wdio.conf.ts`. Use a typed environment loader that validates required variables at startup so failures are clear and immediate.

```typescript
// test/config/env.ts — typed, validated environment configuration
interface Env {
  API_BASE_URL: string;
  TEST_EMAIL: string;
  TEST_PASSWORD: string;
  IOS_APP_PATH: string;
  ANDROID_APP_PATH: string;
  IOS_DEVICE_UDID: string;
  ANDROID_DEVICE_SERIAL: string;
  BROWSERSTACK_USERNAME?: string;
  BROWSERSTACK_ACCESS_KEY?: string;
}

function requireEnv(key: keyof Env): string {
  const val = process.env[key];
  if (!val) throw new Error(`Missing required environment variable: ${key}`);
  return val;
}

export const ENV: Env = {
  API_BASE_URL:            requireEnv('API_BASE_URL'),
  TEST_EMAIL:              requireEnv('TEST_EMAIL'),
  TEST_PASSWORD:           requireEnv('TEST_PASSWORD'),
  IOS_APP_PATH:            requireEnv('IOS_APP_PATH'),
  ANDROID_APP_PATH:        requireEnv('ANDROID_APP_PATH'),
  IOS_DEVICE_UDID:         requireEnv('IOS_DEVICE_UDID'),
  ANDROID_DEVICE_SERIAL:   requireEnv('ANDROID_DEVICE_SERIAL'),
  BROWSERSTACK_USERNAME:   process.env.BROWSERSTACK_USERNAME,
  BROWSERSTACK_ACCESS_KEY: process.env.BROWSERSTACK_ACCESS_KEY,
};
```

```typescript
// wdio.conf.ts — import validated env
import { ENV } from './test/config/env.js';

// 'appium:app': ENV.IOS_APP_PATH,
// 'appium:udid': ENV.IOS_DEVICE_UDID,
```

**Secrets in CI:** Store `TEST_PASSWORD`, `BROWSERSTACK_ACCESS_KEY`, and signing certs as encrypted CI secrets (GitHub Actions `secrets.NAME`, GitLab CI `$VARIABLE_NAME`). Never print them to logs — add `--no-verbose` flag or mask patterns in your CI logger config.

---

## Quick Reference Checklist

Use this checklist to verify a new WebDriverIO/Appium test project is production-ready:

- [ ] `tsconfig.json` has `strict: true`, `@wdio/globals/types` in `types`, `NodeNext` module resolution
- [ ] `@wdio/types` pinned to same minor version as `webdriverio`
- [ ] All selectors use `~accessibility-id` first; XPath only as last resort
- [ ] No `browser.pause()` calls — replaced with `waitForDisplayed` / `waitUntil` / `waitForStable`
- [ ] Page Objects extend `BasePage` with `waitForScreenLoaded()` guard
- [ ] `beforeEach` calls `terminateApp` + `activateApp` for stateful flows
- [ ] Auth bypasses login UI via API token + deep-link injection
- [ ] `wdio.conf.ts` uses `ENV.*` for all paths/credentials — no hardcoded values
- [ ] `afterTest` captures screenshot + page source on failure
- [ ] `appium:newCommandTimeout` set to prevent zombie sessions
- [ ] Animations disabled in capabilities for CI
- [ ] `APPIUM_HOME` set and drivers pinned in `.appiumrc.json`
- [ ] `wait-on tcp:4723` used in CI before running tests
- [ ] `maxInstances` matches available device count
- [ ] `appium:wdaLocalPort` staggered for parallel iOS runs
- [ ] Visual baseline images stored in git LFS (if using visual regression)