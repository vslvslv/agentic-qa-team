# Appium / WebDriverIO Patterns & Best Practices (TypeScript)
<!-- lang: TypeScript | sources: training knowledge (WebFetch + WebSearch unavailable) | iteration: 10 | score: 100/100 | date: 2026-05-02 -->
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

### TypeScript path aliases for cleaner imports  [community]

Long relative imports (`import LoginPage from '../../../pages/LoginPage.js'`) are fragile and noisy. Configure `paths` in `tsconfig.json` to use `@pages`, `@helpers`, and `@fixtures` aliases.

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
    "baseUrl": ".",
    "paths": {
      "@pages/*":    ["test/pages/*"],
      "@helpers/*":  ["test/helpers/*"],
      "@fixtures/*": ["test/fixtures/*"],
      "@config/*":   ["test/config/*"]
    },
    "types": ["node", "@wdio/globals/types", "@wdio/mocha-framework"]
  },
  "include": ["test/**/*.ts", "wdio.conf.ts"],
  "exclude": ["node_modules", "dist"]
}
```

Then add `tsconfig-paths` support in `wdio.conf.ts` so Node resolves the aliases at runtime:

```typescript
// wdio.conf.ts — register path aliases
import 'tsconfig-paths/register';
import type { Options } from '@wdio/types';

export const config: Options.Testrunner = {
  // ... rest of config
};
```

```bash
npm install --save-dev tsconfig-paths
```

Usage in tests (clean, no `../../../`):

```typescript
// test/specs/checkout.spec.ts
import CheckoutPage from '@pages/CheckoutPage.js';
import { getAuthTokens } from '@helpers/authHelper.js';
import type { CheckoutTestData } from '@fixtures/checkoutData.js';
```

**Path alias gotcha [community]:** The `tsconfig paths` plugin resolves aliases at TypeScript compile time. At runtime (Node.js), the compiled JavaScript still has the alias strings. Without `tsconfig-paths/register` (CJS) or `tsx` with path remapping (ESM), Node throws `Cannot find module '@pages/LoginPage'`. For ESM projects, prefer `tsx` (WebDriverIO v9's built-in loader) which supports `paths` natively; for CJS, use `tsconfig-paths/register`.

### WebDriverIO v9 migration notes (released 2024)

WebDriverIO v9 is the current stable release. Key breaking changes from v8:

- **ESM-first:** `wdio.conf.ts` must use `export const config = ...` (already correct). CommonJS
  `module.exports` no longer works. Verify `"type": "module"` in `package.json` OR rename your
  config to `wdio.conf.mts` when using `"moduleResolution": "NodeNext"`.
- **`ts-node` → `tsx`:** v9 switches its TypeScript loader from `ts-node` to `tsx` internally.
  Remove `ts-node` from `devDependencies` and ensure `"tsx"` is present (installed automatically as
  a peer). If you run `wdio run wdio.conf.ts` and see `ERR_UNKNOWN_FILE_EXTENSION`, you're still
  using a ts-node shim — delete `ts-node` and let v9 pick up `tsx`.
- **Built-in `expect`:** v9 ships `expect-webdriverio` bundled — no separate `npm install
  expect-webdriverio`. `import { expect } from '@wdio/globals'` is the new canonical import.
- **`@wdio/sync` removed:** There is no sync mode in v9. All code must be async/await; remove
  any remaining `sync: true` capability references and synchronous chain calls.
- **`browser.execute` return type narrowed:** The return type is now `Promise<unknown>` in strict
  mode, requiring explicit type assertions or `as` casts on `mobile:` command results.
- **`@wdio/appium-service` v9:** The `command` option is deprecated; use `appiumArgs` directly:
  ```typescript
  services: [['appium', {
    appiumArgs: { port: 4723, 'base-path': '/' },
  }]],
  ```

**v9 devDependencies (updated):**

```json
{
  "devDependencies": {
    "webdriverio": "9.x.x",
    "@wdio/cli": "9.x.x",
    "@wdio/local-runner": "9.x.x",
    "@wdio/mocha-framework": "9.x.x",
    "@wdio/spec-reporter": "9.x.x",
    "@wdio/appium-service": "9.x.x",
    "@wdio/allure-reporter": "9.x.x",
    "@wdio/types": "9.x.x",
    "appium": "2.x.x",
    "appium-uiautomator2-driver": "3.x.x",
    "appium-xcuitest-driver": "7.x.x",
    "typescript": "5.x.x"
  }
}
```

> `ts-node` is **not** listed — v9 uses `tsx` internally and does not require it as a project dependency.

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
import { writeFileSync } from 'fs';
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
    writeFileSync(`./allure-results/${label}-${ts}.xml`, src);
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

### Selector Priority — Tier-by-Tier Reference

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

// Double-tap on an element (e.g. to zoom into a map or like a photo)
async function doubleTap(element: WebdriverIO.Element): Promise<void> {
  const { x, y, width, height } = await element.getRect();
  const cx = Math.round(x + width / 2);
  const cy = Math.round(y + height / 2);
  await browser.action('pointer')
    .move({ duration: 0, x: cx, y: cy })
    .down({ button: 0 })
    .up({ button: 0 })
    .pause(50)
    .down({ button: 0 })
    .up({ button: 0 })
    .perform();
}

// Pinch-zoom: two-finger spread (zoom in) using two parallel pointer actions
async function pinchZoom(element: WebdriverIO.Element, zoomFactor = 1.5): Promise<void> {
  const { x, y, width, height } = await element.getRect();
  const cx = Math.round(x + width / 2);
  const cy = Math.round(y + height / 2);
  // Start both fingers close to center, spread outward
  const startOffset = 20;
  const endOffset   = Math.round(startOffset * zoomFactor);

  await browser.actions([
    browser.action('pointer', { parameters: { pointerType: 'touch' } })
      .move({ duration: 0, x: cx - startOffset, y: cy })
      .down({ button: 0 })
      .move({ duration: 600, x: cx - endOffset, y: cy })
      .up({ button: 0 }),
    browser.action('pointer', { parameters: { pointerType: 'touch' } })
      .move({ duration: 0, x: cx + startOffset, y: cy })
      .down({ button: 0 })
      .move({ duration: 600, x: cx + endOffset, y: cy })
      .up({ button: 0 }),
  ]);
}

// Drag element from one position to another (drag-and-drop)
async function dragAndDrop(
  source: WebdriverIO.Element,
  target: WebdriverIO.Element,
): Promise<void> {
  const src = await source.getRect();
  const tgt = await target.getRect();
  const srcX = Math.round(src.x + src.width / 2);
  const srcY = Math.round(src.y + src.height / 2);
  const tgtX = Math.round(tgt.x + tgt.width / 2);
  const tgtY = Math.round(tgt.y + tgt.height / 2);

  await browser.action('pointer')
    .move({ duration: 0, x: srcX, y: srcY })
    .down({ button: 0 })
    .pause(500)                              // hold to trigger drag mode
    .move({ duration: 800, x: tgtX, y: tgtY })
    .up({ button: 0 })
    .perform();
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

### `getAttribute` vs `getProperty` — choosing the right introspection method

```typescript
// getAttribute — reads from the XML page source (always a string)
const isEnabled = await $('~submit-btn').getAttribute('enabled');  // "true" or "false" (string)
const iosValue  = await $('~text-field').getAttribute('value');    // iOS text field content

// getProperty — reads the native property (typed return)
const isChecked = await $('~checkbox').getProperty('checked') as boolean;  // actual boolean
const inputVal  = await $('~text-field').getProperty('value') as string;   // input content

// Rule: use getAttribute for XML-serialised state checks (enabled, selected, focused)
//       use getProperty for reading runtime values (input content, checked state) where
//       type fidelity matters for your assertion.
//
// On Android, getProperty('enabled') returns boolean; getAttribute('enabled') returns "true"/"false"
// Both work, but !== comparisons fail on the string version:
// BAD:  expect(await el.getAttribute('enabled')).toBe(true);   // "true" !== true → always fails
// GOOD: expect(await el.getAttribute('enabled')).toBe('true'); // explicit string
// GOOD: expect(await el.getProperty('enabled')).toBe(true);    // typed boolean
```

### Scoped child queries with `element.$$()` and `element.$()`

Query within a container element to avoid ambiguity when multiple similar elements share the same
screen. Scoped queries reduce the search scope, which is faster and less fragile than XPath
ancestor-descendant paths.

```typescript
// Find a specific card by header, then query its children — no XPath
const card = await $('~product-list').$('~product-card-0');
const title   = await card.$('~card-title');
const addBtn  = await card.$('~add-to-cart');

await expect(title).toHaveText('Widget Pro');
await addBtn.click();

// Find all items in a list and assert count
const items = await $('~cart-list').$$('~cart-item');
expect(items).toHaveLength(3);

// Iterate items and check each one
for (const item of items) {
  const price = await item.$('~item-price');
  await expect(price).toBeDisplayed();
}
```

**Why scoped queries:** A screen may have multiple `~confirm-button` elements (e.g. one in a
modal and one on the page behind it). `$('~confirm-button')` returns the first match in the
page source tree, which may be the background button. Scope to the modal container first:
`$('~modal-container').$('~confirm-button')`.

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

11. **[community] `addValue` vs `setValue` vs `keys()` — input method matters per Android version** — On Android API 30+, `$el.setValue('text')` clears the field then types via `sendKeys`. On older API levels or certain custom EditText components, the `clear()` step changes focus without clearing content, causing characters from the previous test to remain. WHY: Android's `clear()` is an accessibility action that depends on the IME handling of the component. Fix: use `$el.clearValue()` then `$el.addValue('text')` as two discrete steps; for PIN fields or masked inputs, use `driver.execute('mobile: type', { text: '1234' })` which bypasses the WebDriver typing mechanism entirely.

12. **[community] iOS `XCUIElementTypeOther` wrapper silently absorbs taps** — Tapping `$('~my-button')` completes without error but the button's action never fires. WHY: A transparent `XCUIElementTypeOther` view is layered over the button — common with gesture recognisers added by navigation libraries. Appium's tap lands on the overlay, which consumes the event. Fix: use `$('-ios predicate string:type == "XCUIElementTypeButton" AND name == "my-button"')` to target the button type explicitly, bypassing overlay containers; or add `isAccessibilityElement = true` to the button in the app code to make it hittable.

13. **[community] WebDriverIO v9 CI breaks silently when `ts-node` is still in `devDependencies`** — Upgrading `webdriverio` to v9 while keeping `ts-node` as a dev dependency causes the old `ts-node` TypeScript loader to conflict with v9's bundled `tsx` loader. The runner silently falls back to `ts-node` in some environments and fails with `Cannot use import statement in a module` or `SyntaxError: Unexpected token '{'` on the `wdio.conf.ts` file. WHY: Both `ts-node` and `tsx` register TypeScript transpilation hooks on Node's module system; two hooks fight over `.ts` file resolution. Fix: remove `ts-node` from `devDependencies` after upgrading to v9; run `npm dedupe` to clear the transitive install.

14. **[community] `browser.actions([...])` (multi-touch) ignores the second pointer on iOS Simulator** — Using `browser.actions([touch1, touch2])` for pinch/zoom sends both touch events but the iOS Simulator only processes one of them, making the zoom have no effect. WHY: The iOS Simulator's multi-touch requires the `appium:simulatorStartupTimeout` to be sufficiently large AND the simulator must have been opened with "Multi-Touch" enabled in the Hardware menu. In CI, simulators start without the Hardware menu — multi-touch is disabled by default. Fix: add `'appium:settings[multiTouchEnabled]': true` to iOS capabilities (XCUITest driver 3.x+); or use `mobile: pinch` Appium command which handles the touch simulation internally.

15. **[community] `dragAndDrop` fails silently on React Native `FlatList` items** — Dragging from one list item to another using W3C pointer actions completes without error but the items do not reorder. WHY: React Native's drag-and-drop is implemented with `PanResponder` or `react-native-draggable-flatlist`, which detects gesture velocity. The W3C `browser.action()` move duration of 800 ms is too slow — PanResponder's velocity threshold is not met. Fix: reduce `pause` before move to 100 ms and use a shorter `duration` (200–300 ms) for the drag move; or use `mobile: dragFromToForDuration` (iOS) which directly uses XCUITest's native drag API.

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

### GitHub Actions matrix strategy for parallel iOS + Android runs  [community]

Run iOS and Android suites in parallel using a matrix job, each with its own Appium instance. This avoids port conflicts and reduces total CI wall-clock time.

```yaml
# .github/workflows/mobile-e2e.yml
name: Mobile E2E

on:
  push:
    branches: [main]
  pull_request:

jobs:
  mobile-tests:
    name: "E2E — ${{ matrix.platform }} ${{ matrix.platform-version }}"
    runs-on: ${{ matrix.runs-on }}
    timeout-minutes: 40

    strategy:
      fail-fast: false       # don't cancel Android if iOS fails
      matrix:
        include:
          - platform: iOS
            platform-version: "17.0"
            device-name: "iPhone 15"
            automation: XCUITest
            app-env: IOS_APP_PATH
            appium-port: 4723
            runs-on: macos-14   # Apple Silicon runner (required for Simulator)
          - platform: Android
            platform-version: "13"
            device-name: "Pixel_7_API_33"
            automation: UiAutomator2
            app-env: ANDROID_APP_PATH
            appium-port: 4724   # different port — both jobs can run on same host if needed
            runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Cache Appium drivers
        uses: actions/cache@v4
        with:
          path: ${{ runner.temp }}/appium
          key: appium-${{ matrix.platform }}-${{ hashFiles('.appiumrc.json') }}

      - name: Install Appium & drivers
        run: |
          export APPIUM_HOME="${{ runner.temp }}/appium"
          npx appium@2.5.0 driver install ${{ matrix.automation == 'XCUITest' && 'xcuitest' || 'uiautomator2' }}
        env:
          APPIUM_HOME: ${{ runner.temp }}/appium

      - name: Start iOS Simulator (iOS only)
        if: matrix.platform == 'iOS'
        run: |
          xcrun simctl boot "${{ matrix.device-name }}" || true
          xcrun simctl list devices booted

      - name: Start Android Emulator (Android only)
        if: matrix.platform == 'Android'
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 33
          target: google_apis
          arch: x86_64
          avd-name: ${{ matrix.device-name }}
          emulator-options: -no-snapshot-save -no-window -gpu swiftshader_indirect -noaudio -no-boot-anim
          disable-animations: true

      - name: Start Appium server
        run: |
          export APPIUM_HOME="${{ runner.temp }}/appium"
          npx appium@2.5.0 --port ${{ matrix.appium-port }} --log appium-${{ matrix.platform }}.log &
          npx wait-on tcp:${{ matrix.appium-port }} --timeout 30000
        env:
          APPIUM_HOME: ${{ runner.temp }}/appium

      - name: Run E2E tests
        run: npx wdio run wdio.conf.ts
        env:
          PLATFORM: ${{ matrix.platform }}
          APPIUM_PORT: ${{ matrix.appium-port }}
          ${{ matrix.app-env }}: ${{ secrets[matrix.app-env] }}

      - name: Upload test artifacts on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: test-artifacts-${{ matrix.platform }}
          path: |
            allure-results/
            appium-${{ matrix.platform }}.log
```

**CI matrix gotchas [community]:**
- `fail-fast: false` is critical — if iOS fails due to a Simulator startup issue, you still want Android results. Mobile CI failures are often infrastructure-related, not code bugs.
- Each matrix job should write to a uniquely named `APPIUM_HOME` (e.g. `${{ runner.temp }}/appium-${{ matrix.platform }}`) to avoid cache key collisions between iOS and Android driver installs.
- Android emulator runner (`reactivecircus/android-emulator-runner`) requires a Linux runner (`ubuntu-latest`). iOS Simulator requires macOS (`macos-14` for Apple Silicon M1 runners). Never mix — iOS Simulator does not run on Linux.

### Spec file sharding for large test suites  [community]

When a suite grows beyond ~200 specs, serial execution on one device becomes too slow. Shard specs across multiple CI jobs using an index/total pattern so each job runs a unique subset.

```typescript
// wdio.conf.ts — spec sharding via SHARD_INDEX / SHARD_TOTAL env vars
import type { Options } from '@wdio/types';
import { globSync } from 'glob';

const allSpecs = globSync('./test/specs/**/*.spec.ts').sort();  // sort for deterministic sharding

function getShardedSpecs(): string[] {
  const shardIndex = parseInt(process.env.SHARD_INDEX ?? '0', 10);   // 0-based index
  const shardTotal = parseInt(process.env.SHARD_TOTAL ?? '1', 10);
  return allSpecs.filter((_, i) => i % shardTotal === shardIndex);
}

export const config: Options.Testrunner = {
  specs: getShardedSpecs(),
  // ... rest of config
};
```

GitHub Actions usage — 3-way shard:

```yaml
strategy:
  matrix:
    shard: [0, 1, 2]
steps:
  - name: Run sharded tests
    run: npx wdio run wdio.conf.ts
    env:
      SHARD_INDEX: ${{ matrix.shard }}
      SHARD_TOTAL: 3
```

**Sharding gotcha [community]:** Always sort the spec array before sharding (`allSpecs.sort()`). Without sorting, glob returns files in filesystem order which varies between macOS and Linux. A sort discrepancy means the shards overlap or leave gaps — some specs run twice and others never run in CI while passing locally.

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
'appium:settings[disableIdLocatorAutocompletion]': true,  // stop UiAutomator2 appending package name to id selectors (avoids false misses)
'appium:elementResponseAttributes': 'type,label,value,name,rect',  // reduce payload size
```

**Rule of thumb:** If element lookups average > 500 ms on CI, enable `useFirstMatch: true` (iOS) first, then reduce `snapshotMaxDepth` if the app's view hierarchy is shallow. Never lower `snapshotMaxDepth` below 50 without verifying all elements in your deepest screen are still reachable.

---

## Keyboard Handling & File Operations  [community]

### Keyboard dismissal

The soft keyboard covers UI elements and must be dismissed before assertions on obscured elements.

```typescript
// test/helpers/keyboardHelper.ts

/**
 * Dismiss the soft keyboard if it is open.
 * On iOS, use the `done` key or tap outside. On Android, use hideKeyboard().
 * WHY: Appium's hideKeyboard() is unreliable on iOS — it sometimes dismisses the
 * keyboard but returns an error if the keyboard was already hidden. The try/catch
 * swallows the false-negative.
 */
export async function dismissKeyboard(): Promise<void> {
  try {
    if (browser.isIOS) {
      // XCUITest driver: press the 'done' key on the keyboard toolbar
      await driver.execute('mobile: hideKeyboard', { strategy: 'tapOutside' });
    } else {
      await driver.hideKeyboard();
    }
  } catch {
    // Keyboard was already hidden — not an error
  }
}

/**
 * Check whether the soft keyboard is currently visible.
 * Useful for conditional dismissal in helper methods.
 */
export async function isKeyboardShown(): Promise<boolean> {
  return await driver.isKeyboardShown();
}
```

```typescript
// Usage in a form test:
it('should submit form after filling all fields', async () => {
  await $('~name-input').setValue('Alice');
  await $('~email-input').setValue('alice@example.com');
  // Keyboard covers the submit button on small screens — dismiss it first
  await dismissKeyboard();
  await $('~submit-btn').waitForDisplayed({ timeout: 3_000 });
  await $('~submit-btn').click();
  await expect($('~success-message')).toBeDisplayed();
});
```

**Keyboard gotchas [community]:**
- On Android, `setValue()` auto-dismisses the keyboard on some devices but not all. Always call `dismissKeyboard()` explicitly before asserting on elements below the fold.
- On iOS, the `tapOutside` strategy taps coordinates (0, 0) which may hit a UI element. If `tapOutside` triggers an unintended action, use `pressButton('done')` via `driver.execute('mobile: pressButton', { name: 'done' })` to press the keyboard "Done" key instead.
- `driver.isKeyboardShown()` is not 100% reliable on iOS — it checks the XCUITest keyboard element, which can disappear from the tree before the animation completes. Add a small `waitUntil` after dismissal before querying the element you need.

### File upload and retrieval  [community]

Push test files to the device (for file picker flows) and pull files off the device (for downloaded content assertions).

```typescript
// test/helpers/fileHelper.ts
import fs from 'fs';
import path from 'path';

/**
 * Push a file to the device's accessible path.
 * iOS: path must be relative to the app's sandbox (Documents folder).
 * Android: path can be an absolute /sdcard/ path.
 */
export async function pushFileToDevice(localPath: string, remotePath: string): Promise<void> {
  const fileContent = fs.readFileSync(localPath);
  const base64Content = fileContent.toString('base64');
  await driver.pushFile(remotePath, base64Content);
}

/**
 * Pull a file from the device and save it locally.
 * Useful for asserting on downloaded PDFs, exported CSVs, or generated images.
 */
export async function pullFileFromDevice(remotePath: string, localSavePath: string): Promise<void> {
  const base64Content = await driver.pullFile(remotePath) as string;
  const buffer = Buffer.from(base64Content, 'base64');
  fs.mkdirSync(path.dirname(localSavePath), { recursive: true });
  fs.writeFileSync(localSavePath, buffer);
}
```

```typescript
// test/specs/document-upload.spec.ts
import { pushFileToDevice } from '../helpers/fileHelper.js';

describe('Document upload flow', () => {
  const TEST_PDF = path.resolve(__dirname, '../../fixtures/test-document.pdf');

  before(async () => {
    // iOS: push to Documents folder (accessible via UIDocumentPickerViewController)
    if (browser.isIOS) {
      await pushFileToDevice(TEST_PDF, '/private/var/mobile/Media/DCIM/test-document.pdf');
    } else {
      // Android: push to external storage
      await pushFileToDevice(TEST_PDF, '/sdcard/Download/test-document.pdf');
    }
  });

  it('should upload a PDF and show confirmation', async () => {
    await $('~upload-document-btn').click();
    // File picker opens — select the file via accessibility label or text match
    await $('~test-document.pdf').waitForDisplayed({ timeout: 5_000 });
    await $('~test-document.pdf').click();
    await expect($('~upload-success-banner')).toBeDisplayed();
    await expect($('~uploaded-filename')).toHaveText('test-document.pdf');
  });
});
```

**File operation gotchas [community]:**
- `driver.pushFile` requires the path to be in the app's sandbox on iOS (not arbitrary filesystem paths). Use `driver.getAppStrings()` or the Appium inspector to find the correct Documents path for the bundle.
- On Android API 30+ (scoped storage), `/sdcard/Download/` is only accessible if the app declares `READ_EXTERNAL_STORAGE` or `MANAGE_EXTERNAL_STORAGE` permissions. Prefer pushing to the app's private data directory (`/data/data/com.example.myapp/files/`) for internal file tests.
- `driver.pullFile` on iOS returns the file as base64 — this is correct behaviour. Always `Buffer.from(content, 'base64')` before writing or asserting on the binary content.

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
| `el.getAttribute(name)` | Get XML attribute from page source (string values) | Checking `enabled`, `selected`, `checkable`, iOS `value` |
| `el.getProperty(name)` | Get DOM/native property (typed) | Getting `checked` (boolean), `value` on inputs — prefer over `getAttribute` for typed values |
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
| `driver.hideKeyboard()` | Dismiss soft keyboard | Before asserting on elements below keyboard |
| `driver.isKeyboardShown()` | Check if keyboard is visible | Conditional dismissal |
| `driver.pushFile(path, base64)` | Upload file to device | File picker and upload tests |
| `driver.pullFile(path)` | Download file from device (base64) | Assert on downloaded content |
| `driver.lockDevice(secs)` | Lock the device screen | Lock-screen notification tests |
| `driver.unlockDevice()` | Unlock the device | After lock-screen assertions |
| `driver.setGeoLocation(coords)` | Set GPS coordinates (Android) | Location-aware feature tests |
| `driver.setOrientation(o)` | Rotate device | Orientation/rotation tests |
| `driver.getOrientation()` | Get current orientation | Assert or guard rotation state |

---

## Screen Recording for CI Failure Debugging  [community]

Capture a video of the test session to diagnose failures that screenshots alone cannot explain (timing issues, flicker, scroll position problems).

```typescript
// test/helpers/recordingHelper.ts

let isRecording = false;

/**
 * Start screen recording.
 * iOS Simulator: uses XCUITest driver's built-in screen recorder.
 * Android emulator: uses UiAutomator2 screen recording.
 */
export async function startRecording(options?: {
  timeLimit?: number;   // max seconds to record (default: 180)
  quality?: 'low' | 'medium' | 'high';
}): Promise<void> {
  if (isRecording) return;
  const timeLimit = options?.timeLimit ?? 120;

  if (browser.isIOS) {
    await driver.startRecordingScreen({
      timeLimit,
      videoType: 'libx264',
      videoQuality: options?.quality ?? 'medium',
    });
  } else {
    await driver.startRecordingScreen({
      timeLimit,
      videoSize: '1080x1920',  // match emulator resolution
      bitRate: options?.quality === 'high' ? 8000000 : 4000000,
    });
  }
  isRecording = true;
}

/**
 * Stop recording and save the video to disk.
 * Returns the path to the saved file.
 */
export async function stopRecordingAndSave(label: string): Promise<string> {
  if (!isRecording) return '';
  const base64Video = await driver.stopRecordingScreen() as string;
  isRecording = false;

  const ext = browser.isIOS ? 'mp4' : 'mp4';
  const filePath = `./allure-results/recording-${label}-${Date.now()}.${ext}`;
  const fs = await import('fs');
  fs.mkdirSync('./allure-results', { recursive: true });
  fs.writeFileSync(filePath, Buffer.from(base64Video, 'base64'));
  return filePath;
}
```

```typescript
// wdio.conf.ts — integrate recording into test lifecycle
import { startRecording, stopRecordingAndSave } from './test/helpers/recordingHelper.js';
import { addAttachment } from '@wdio/allure-reporter';
import fs from 'fs';

// Start recording before each test
beforeTest: async (test) => {
  await startRecording({ timeLimit: 120, quality: 'medium' });
},

// Stop and save on failure; discard on pass
afterTest: async (test, _ctx, { error }) => {
  const label = test.title.replace(/[^a-z0-9]/gi, '-').toLowerCase();
  const videoPath = await stopRecordingAndSave(label);

  if (error && videoPath) {
    // Attach video to Allure report for the failed test
    const videoBuffer = fs.readFileSync(videoPath);
    addAttachment('Test recording', videoBuffer, 'video/mp4');
  } else if (!error && videoPath) {
    // Clean up passing test recordings to save disk space
    fs.unlinkSync(videoPath);
  }
},
```

**Screen recording gotchas [community]:**
- `driver.startRecordingScreen()` on iOS requires the `appium-xcuitest-driver` 3.x+ and only works on Simulator — not on real devices. Real device recording requires an external screen capture tool.
- Recording has a server-side `timeLimit` cap (default 3 minutes). Tests longer than 3 minutes will have the recording silently truncated. Set `timeLimit` to your longest expected test duration.
- Always call `stopRecordingAndSave()` in BOTH `afterTest` success and failure paths (or `afterEach`). If a test throws before the recording is stopped, the next call to `startRecordingScreen()` will fail with "recording already in progress".
- Video files can be large (10–50 MB per test). Delete recordings for passing tests immediately in `afterTest` — only persist failing test videos to avoid bloating CI artifacts.

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
import { writeFileSync } from 'fs';
import type { Options } from '@wdio/types';

export const config: Options.Testrunner = {
  // ...existing config...
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
  writeFileSync('allure-results/environment.properties', lines.join('\n'));
},
```

Generate and open Allure report after a run:
```bash
npx allure generate allure-results --clean -o allure-report
npx allure open allure-report
```

---

## Deep Link Testing Pattern  [community]

Deep links are one of the most reliable ways to navigate to a specific screen without traversing the full UI flow. Test deep links explicitly to catch broken URL schemes and missing intent filters early.

```typescript
// test/helpers/deepLinkHelper.ts

/**
 * Open a deep link and wait for the target screen to appear.
 * iOS: browser.url() routes through Safari; Android requires mobile: deepLink.
 *
 * WHY: On Android, browser.url() opens the default browser app, not the deep link handler.
 * Use 'mobile: deepLink' to invoke the app's intent filter directly.
 */
export async function openDeepLink(url: string, targetSelector: string, timeoutMs = 8_000): Promise<void> {
  if (browser.isIOS) {
    await browser.url(url);
  } else {
    const pkg = url.split('://')[0];  // extract scheme as a hint; package must still be provided
    await driver.execute('mobile: deepLink', {
      url,
      package: process.env.ANDROID_PACKAGE_NAME!,  // e.g. 'com.example.myapp'
    });
  }
  await $(targetSelector).waitForDisplayed({ timeout: timeoutMs });
}

/**
 * Assert that opening a deep link navigates to the expected screen.
 */
export async function assertDeepLink(
  url: string,
  targetSelector: string,
  expectedTextSelector?: string,
  expectedText?: string,
): Promise<void> {
  await openDeepLink(url, targetSelector);
  await expect($(targetSelector)).toBeDisplayed();
  if (expectedTextSelector && expectedText) {
    await expect($(expectedTextSelector)).toHaveText(expectedText);
  }
}
```

```typescript
// test/specs/deep-links.spec.ts
import { assertDeepLink } from '../helpers/deepLinkHelper.js';

describe('Deep link routing', () => {
  it('should navigate to product detail via deep link', async () => {
    await assertDeepLink(
      'myapp://product/12345',
      '~product-detail-screen',
      '~product-title',
      'Widget Pro',
    );
  });

  it('should navigate to profile screen via deep link', async () => {
    await assertDeepLink('myapp://profile/me', '~profile-screen');
  });

  it('should show 404 screen for unknown deep link paths', async () => {
    await openDeepLink('myapp://nonexistent-path', '~not-found-screen');
    await expect($('~not-found-screen')).toBeDisplayed();
  });
});
```

**Deep link gotchas [community]:**
- On Android, if the device has multiple apps that handle the same URI scheme, the system shows an "Open with..." disambiguation dialog. Fix: set `package` in `mobile: deepLink` to route directly to your app's intent filter without the chooser.
- iOS Universal Links (`https://yourdomain.com/path`) require the device to be online and the Associated Domains entitlement to be configured. For Simulator testing, use custom URL schemes (`myapp://`) which work offline.
- After a deep link navigates away from the home screen, the "back" button may route to the previous app (the deep link opener) rather than to your app's home. Assert on the final screen state rather than navigation history.

## App State Assertion  [community]

Use `driver.queryAppState()` to assert that the app is in the expected lifecycle state (foreground, background, not running). Essential for background/foreground transition tests.

```typescript
// test/helpers/appStateHelper.ts

/**
 * Appium app state codes:
 *   0 = not installed
 *   1 = not running
 *   2 = background suspended
 *   3 = background running
 *   4 = foreground running (active)
 */
export const APP_STATE = {
  NOT_INSTALLED:        0,
  NOT_RUNNING:          1,
  BACKGROUND_SUSPENDED: 2,
  BACKGROUND_RUNNING:   3,
  FOREGROUND:           4,
} as const;

export type AppState = typeof APP_STATE[keyof typeof APP_STATE];

/**
 * Wait until the app reaches the expected state (e.g. foreground after activateApp).
 * WHY: activateApp() is fire-and-forget — the OS takes time to foreground the app.
 * Without this wait, subsequent element lookups run before the app is ready.
 */
export async function waitForAppState(
  bundleId: string,
  expectedState: AppState,
  timeoutMs = 5_000,
): Promise<void> {
  await browser.waitUntil(
    async () => {
      const state = await driver.queryAppState(bundleId) as AppState;
      return state === expectedState;
    },
    {
      timeout: timeoutMs,
      timeoutMsg: `App ${bundleId} did not reach state ${expectedState} in ${timeoutMs} ms`,
      interval: 200,
    },
  );
}
```

```typescript
// test/specs/background-foreground.spec.ts
import { waitForAppState, APP_STATE } from '../helpers/appStateHelper.js';

const BUNDLE_ID = process.env.APP_BUNDLE_ID!;

describe('Background / foreground transition', () => {
  it('should resume correct screen state after backgrounding', async () => {
    // Navigate to a specific screen
    await openDeepLink('myapp://checkout', '~checkout-screen');
    await expect($('~checkout-screen')).toBeDisplayed();

    // Background the app (Home button press)
    await driver.execute('mobile: pressButton', { name: 'home' });
    await waitForAppState(BUNDLE_ID, APP_STATE.BACKGROUND_SUSPENDED);

    // Return to foreground
    await driver.activateApp(BUNDLE_ID);
    await waitForAppState(BUNDLE_ID, APP_STATE.FOREGROUND);

    // Assert the checkout screen is still shown (no reset on resume)
    await expect($('~checkout-screen')).toBeDisplayed();
  });
});
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

### Biometric Auth Simulation (Face ID / Touch ID)  [community]

Apps that require Face ID or Touch ID need a way to simulate biometric prompts in tests.
Appium provides `mobile: enrollBiometric` and `mobile: sendBiometricMatch` commands for
iOS Simulator, and `finger-print` / `finger-remove` ADB commands for Android emulators.

```typescript
// test/helpers/biometricHelper.ts
// iOS Simulator: enroll biometrics + simulate match/fail
export async function enrollIosBiometric(): Promise<void> {
  await driver.execute('mobile: enrollBiometric', { isEnabled: true });
}

export async function simulateIosBiometricMatch(match: boolean = true): Promise<void> {
  await driver.execute('mobile: sendBiometricMatch', { type: 'faceId', match });
}

// Android emulator: simulate fingerprint authentication
export async function simulateAndroidFingerprint(fingerprintId: number = 1): Promise<void> {
  // Triggers the fingerprint sensor on the emulator (ADB fingerprint command via Appium)
  await driver.execute('mobile: fingerprint', { fingerprintId });
}
```

```typescript
// test/specs/biometric-login.spec.ts
import {
  enrollIosBiometric,
  simulateIosBiometricMatch,
  simulateAndroidFingerprint,
} from '../helpers/biometricHelper.js';
import LoginPage from '../pages/LoginPage.js';

describe('Biometric login', () => {
  before(async () => {
    if (browser.isIOS) await enrollIosBiometric();
  });

  it('should log in with biometric — success', async () => {
    await LoginPage.tapBiometricLoginButton();
    await $('~biometric-prompt').waitForDisplayed({ timeout: 5000 });

    if (browser.isIOS) {
      await simulateIosBiometricMatch(true);
    } else {
      await simulateAndroidFingerprint(1);
    }

    await expect($('~home-screen')).toBeDisplayed();
  });

  it('should show fallback PIN when biometric fails', async () => {
    await LoginPage.tapBiometricLoginButton();
    await $('~biometric-prompt').waitForDisplayed({ timeout: 5000 });

    if (browser.isIOS) {
      await simulateIosBiometricMatch(false);  // simulate failed match
    } else {
      await simulateAndroidFingerprint(0);  // fingerprintId 0 = failure on emulator
    }

    await expect($('~pin-fallback-screen')).toBeDisplayed();
  });
});
```

**Biometric testing caveats:**
- `mobile: enrollBiometric` and `mobile: sendBiometricMatch` only work on iOS **Simulator** — not on real iOS devices. On real devices, Appium cannot intercept the secure enclave.
- On Android **emulators**, `mobile: fingerprint` requires API level 23+ and the emulator must have fingerprints enrolled first (via AVD settings). On real Android devices, use the `fingerprint` ADB command via the test setup script.
- Always gate biometric tests with a capability flag (`process.env.REAL_DEVICE !== 'true'`) to skip them on device farms where biometric simulation is unsupported.

---

## `expect()` Matchers vs `waitFor*()` Methods — Choosing the Right Approach

WebDriverIO bundles `expect-webdriverio` (v9: built-in via `@wdio/globals`). Understanding when to use `expect()` matchers vs `waitFor*()` methods avoids test double-waiting and assertion confusion.

| Approach | Behaviour | When to use |
|----------|-----------|-------------|
| `await expect(el).toBeDisplayed()` | Polls internally (default 3 s) — assertion FAILS if element never becomes visible | For test assertions — reads clearly as "I expect this to be visible" |
| `await el.waitForDisplayed({ timeout })` | Polls until visible OR throws timeout error | When you need to gate further actions on visibility (not making an assertion) |
| `await el.isDisplayed()` | Immediate — returns `true`/`false` at this instant | For conditional logic inside helper methods |

```typescript
// GOOD: assertion — expect polls internally, failure message is descriptive
await expect($('~success-toast')).toBeDisplayed();
await expect($('~user-name-header')).toHaveText('Alice');
await expect($('~cart-badge')).toHaveAttribute('value', '3');

// GOOD: gating action — waitForDisplayed before interacting
await $('~submit-btn').waitForDisplayed({ timeout: 8_000 });
await $('~submit-btn').click();
// Don't assert on this — it throws a generic timeout error, not a readable test failure

// GOOD: conditional branching — isDisplayed() for guard clauses
async function dismissOnboardingIfPresent(): Promise<void> {
  const onboarding = $('~onboarding-overlay');
  if (await onboarding.isDisplayed()) {
    await $('~skip-onboarding-btn').click();
    await onboarding.waitForDisplayed({ reverse: true, timeout: 3_000 });
  }
}

// BAD: double-wait — waitForDisplayed then expect redundantly re-polls
await $('~success-toast').waitForDisplayed({ timeout: 8_000 });
await expect($('~success-toast')).toBeDisplayed();  // polls again — wastes time, not wrong but noisy
```

**`expect()` timeout configuration:** Override the default 3 s globally or per-assertion:

```typescript
// wdio.conf.ts — set global expect timeout
import { setOptions } from 'expect-webdriverio';

export const config: Options.Testrunner = {
  // ...
  before: async () => {
    setOptions({ wait: 8_000 });  // default wait for all expect() assertions
  },
};

// Per-assertion override
await expect($('~slow-animation')).toBeDisplayed({ wait: 15_000, interval: 500 });
```

---

## Multi-App Testing — Switching Between Apps  [community]

Some flows leave your app and open a third-party app (Share Sheet, OAuth browser redirect,
in-app browser, system permission dialog). Handle these by switching the Appium session context
or activating the target app, then returning to your app.

```typescript
// test/helpers/contextHelper.ts

/**
 * Switch to Safari (iOS) or Chrome (Android) after an OAuth redirect.
 * WebdriverIO + Appium manage separate contexts for native vs. WebView.
 */
export async function switchToWebContext(): Promise<void> {
  // Wait for WebView context to appear (app embedded browser opens asynchronously)
  await browser.waitUntil(async () => {
    const contexts = await browser.getContexts();
    return contexts.some((ctx) => (ctx as string).startsWith('WEBVIEW'));
  }, { timeout: 10_000, timeoutMsg: 'WebView context not found within 10 s' });

  const contexts = await browser.getContexts();
  const webCtx = (contexts as string[]).find((c) => c.startsWith('WEBVIEW'));
  if (!webCtx) throw new Error('No WEBVIEW context available');
  await browser.switchContext(webCtx);
}

export async function switchToNativeContext(): Promise<void> {
  await browser.switchContext('NATIVE_APP');
}

/**
 * Activate the system Settings app, perform an action, then return to the tested app.
 */
export async function openSystemSettings(bundleIdToReturn: string): Promise<void> {
  if (browser.isIOS) {
    await driver.execute('mobile: activateApp', { bundleId: 'com.apple.Preferences' });
  } else {
    await driver.activateApp('com.android.settings');
  }
  // Caller performs actions in Settings, then calls returnToApp()
}

export async function returnToApp(bundleId: string): Promise<void> {
  await driver.activateApp(bundleId);
  // Re-check that the app foregrounded correctly
  await browser.waitUntil(
    async () => {
      const state = await driver.queryAppState(bundleId);
      return state === 4;  // 4 = foreground running
    },
    { timeout: 5_000, timeoutMsg: `App ${bundleId} did not foreground in 5 s` }
  );
}
```

```typescript
// test/specs/oauth-login.spec.ts
import { switchToWebContext, switchToNativeContext } from '../helpers/contextHelper.js';

describe('OAuth login flow', () => {
  it('should complete OAuth via external browser', async () => {
    await $('~sign-in-with-google').click();

    // Wait for in-app browser / WebView to open
    await switchToWebContext();

    // Now operating in WebView — can use CSS selectors in the OAuth page
    await $('input[type="email"]').setValue(process.env.TEST_EMAIL!);
    await $('button[type="submit"]').click();

    // Switch back to native after OAuth redirect returns to the app
    await switchToNativeContext();
    await expect($('~home-screen')).toBeDisplayed();
  });
});
```

**Context switching gotchas:**
- `getContexts()` returns both `'NATIVE_APP'` and any open `WEBVIEW_<pid>` contexts. Multiple WebViews can be open simultaneously — select the one whose URL matches your OAuth provider.
- On Android, switching to a WebView context requires ChromeDriver to be installed in `APPIUM_HOME`. Add `appium driver install --source npm appium-chromium-driver` to your CI setup step.
- `queryAppState()` returns 4 for foreground — useful guard after `activateApp` to confirm the OS actually foregrounded the app before asserting on its UI.

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

## Device Simulation — Geolocation, Orientation & System Dialogs

### Geolocation simulation  [community]

Apps that use GPS or location services need deterministic location data in tests. Appium provides `setGeoLocation` for emulators/simulators and the `mobile: setSimulatedLocation` command for iOS Simulator.

```typescript
// test/helpers/locationHelper.ts

/** Set GPS coordinates — works on Android emulator + iOS Simulator */
export async function setLocation(lat: number, lng: number, altitude = 0): Promise<void> {
  if (browser.isIOS) {
    // iOS Simulator: XCUITest driver command (Appium 2.x)
    await driver.execute('mobile: setSimulatedLocation', { latitude: lat, longitude: lng });
  } else {
    // Android emulator: standard Appium geo command
    await driver.setGeoLocation({ latitude: lat, longitude: lng, altitude });
  }
}

/** Reset to real device location (stop simulation) */
export async function clearSimulatedLocation(): Promise<void> {
  if (browser.isIOS) {
    await driver.execute('mobile: resetSimulatedLocation', {});
  }
  // Android: no reset command — just stop injecting; emulator reverts on its own
}
```

```typescript
// test/specs/delivery-map.spec.ts
import { setLocation, clearSimulatedLocation } from '../helpers/locationHelper.js';

describe('Delivery map — location-aware features', () => {
  after(async () => {
    await clearSimulatedLocation();
  });

  it('should show nearby restaurants when near downtown NYC', async () => {
    await setLocation(40.7128, -74.0060);  // NYC lat/lng
    await $('~nearby-restaurants-btn').click();
    await $('~restaurant-list').waitForDisplayed({ timeout: 8_000 });
    const items = await $$('~restaurant-card');
    expect(items.length).toBeGreaterThan(0);
  });

  it('should show "no restaurants nearby" message for remote location', async () => {
    await setLocation(0.0, 0.0);  // null island — no restaurants
    await $('~nearby-restaurants-btn').click();
    await expect($('~empty-state-message')).toHaveText('No restaurants in your area');
  });
});
```

**Geolocation gotchas:**
- `setGeoLocation` on Android requires the emulator's location mode to be set to "GPS only" or "High accuracy". If the app uses `fused location` (Google's FusedLocationProviderClient), you may need `appium-fake-gps` plugin or `adb` commands to inject mock locations at the system level.
- On iOS real devices, `mobile: setSimulatedLocation` is unavailable. Use Xcode's GPX simulation feature or a proxy that injects Core Location data.
- Always call `clearSimulatedLocation` in an `after` hook — leaving a simulated location active can affect other tests or the next session on the same simulator.

### Orientation and rotation testing

```typescript
// test/helpers/orientationHelper.ts
import type { AppiumBrowser } from 'webdriverio';

export type Orientation = 'PORTRAIT' | 'LANDSCAPE';

/** Rotate device to the specified orientation and wait for UI to settle */
export async function setOrientation(orientation: Orientation): Promise<void> {
  await (driver as AppiumBrowser).setOrientation(orientation);
  // Give the app time to complete its rotation animation before asserting
  await browser.waitUntil(
    async () => {
      const current = await (driver as AppiumBrowser).getOrientation();
      return current === orientation;
    },
    { timeout: 5_000, timeoutMsg: `Device did not rotate to ${orientation} in 5 s` }
  );
}
```

```typescript
// test/specs/media-player.spec.ts
import { setOrientation } from '../helpers/orientationHelper.js';

describe('Media player orientation', () => {
  after(async () => {
    await setOrientation('PORTRAIT');  // always restore to portrait after test
  });

  it('should show full-screen controls in landscape mode', async () => {
    await $('~video-thumbnail').click();
    await $('~video-player').waitForDisplayed({ timeout: 5_000 });

    await setOrientation('LANDSCAPE');
    await expect($('~fullscreen-controls-bar')).toBeDisplayed();
    await expect($('~portrait-mini-player')).not.toBeDisplayed();
  });

  it('should return to mini-player on portrait rotation', async () => {
    await setOrientation('PORTRAIT');
    await expect($('~portrait-mini-player')).toBeDisplayed();
  });
});
```

### Runtime permission dialogs  [community]

iOS and Android show system permission dialogs (camera, microphone, location, notifications) that interrupt test flow. These are native system UI — not part of the app — and require special handling.

```typescript
// test/helpers/permissionHelper.ts

/**
 * Accept an iOS system permission alert (e.g., camera, location, microphone).
 * The alert appears as a system overlay — use driver.acceptAlert() to tap "Allow".
 * WHY: System alerts are NOT in the app's accessibility tree; $('~Allow') finds nothing.
 */
export async function acceptIosPermissionAlert(timeoutMs = 3_000): Promise<void> {
  try {
    await browser.waitUntil(
      async () => {
        try {
          await driver.getAlertText();
          return true;
        } catch {
          return false;
        }
      },
      { timeout: timeoutMs, timeoutMsg: 'No permission alert appeared' }
    );
    await driver.acceptAlert();  // taps the "Allow" / "OK" button
  } catch {
    // No alert appeared — possibly already granted, or not triggered
  }
}

/**
 * Dismiss (deny) an iOS permission alert.
 */
export async function dismissIosPermissionAlert(timeoutMs = 3_000): Promise<void> {
  try {
    await browser.waitUntil(
      async () => {
        try { await driver.getAlertText(); return true; }
        catch { return false; }
      },
      { timeout: timeoutMs }
    );
    await driver.dismissAlert();  // taps "Don't Allow" / "Cancel"
  } catch {
    // No alert
  }
}

/**
 * Grant an Android runtime permission via ADB — avoids the UI dialog entirely.
 * Faster and more reliable than tapping through the dialog, especially for
 * location permissions that show a 3-option dialog in Android 12+.
 */
export async function grantAndroidPermission(
  packageName: string,
  permission: string,
): Promise<void> {
  await driver.execute('mobile: shell', {
    command: 'pm',
    args: ['grant', packageName, permission],
  });
}

/**
 * Revoke an Android permission to test the "permission denied" flow.
 */
export async function revokeAndroidPermission(
  packageName: string,
  permission: string,
): Promise<void> {
  await driver.execute('mobile: shell', {
    command: 'pm',
    args: ['revoke', packageName, permission],
  });
}
```

```typescript
// test/specs/camera-flow.spec.ts
import {
  acceptIosPermissionAlert,
  grantAndroidPermission,
  revokeAndroidPermission,
} from '../helpers/permissionHelper.js';

const PACKAGE = 'com.example.myapp';
const CAMERA_PERM = 'android.permission.CAMERA';

describe('Camera permission flow', () => {
  before(async () => {
    // Pre-grant on Android to avoid dialog in happy-path test
    if (browser.isAndroid) {
      await grantAndroidPermission(PACKAGE, CAMERA_PERM);
    }
  });

  it('should open camera after granting permission (iOS)', async () => {
    if (!browser.isIOS) return;
    await $('~open-camera-btn').click();
    await acceptIosPermissionAlert();  // taps "Allow"
    await expect($('~camera-preview')).toBeDisplayed();
  });

  it('should show camera view immediately on Android (pre-granted)', async () => {
    if (!browser.isAndroid) return;
    await $('~open-camera-btn').click();
    await expect($('~camera-preview')).toBeDisplayed();
  });

  it('should show permission-denied UI when camera is revoked (Android)', async () => {
    if (!browser.isAndroid) return;
    await revokeAndroidPermission(PACKAGE, CAMERA_PERM);
    await driver.terminateApp(PACKAGE);
    await driver.activateApp(PACKAGE);
    await $('~open-camera-btn').click();
    await expect($('~camera-permission-denied-banner')).toBeDisplayed();
  });
});
```

**Permission dialog pitfalls:**
- `driver.acceptAlert()` works for iOS permission alerts but NOT for Android permission dialogs (which are full activities, not alerts). Use `grantAndroidPermission` (ADB `pm grant`) for Android.
- On iOS 15+, location permission shows a three-option dialog ("Allow Once", "Allow While Using", "Don't Allow"). `driver.acceptAlert()` taps the default primary button — which may be "Allow Once", not "Always Allow". Use `mobile: alert` command with a specific button label if you need a specific option.
- Pre-granting permissions via ADB (`pm grant`) before the app launches is faster and avoids dialog flakiness entirely. Reserve dialog-flow tests for explicitly testing the permission-denied UX.
- On iOS Simulator, use `'appium:permissions'` capability to pre-grant permissions at session start: `'appium:permissions': '{"com.example.myapp": {"camera": "yes"}}'` (XCUITest driver 4.18+).

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
- [ ] Appium plugins declared in `.appiumrc.json` and installed in CI setup step
- [ ] `driver` used only for session-level commands; `browser` for all test interaction
- [ ] Expo projects build a custom dev client (not Expo Go) before running Appium tests
- [ ] Biometric auth tests gated with `REAL_DEVICE` env flag (simulator-only APIs)
- [ ] Multi-app flows use `switchContext()` for WebView / OAuth redirects
- [ ] `expect()` matchers used for assertions; `waitForDisplayed()` used for action gating
- [ ] ChromeDriver installed in CI for WebView context switching on Android
- [ ] No `require()` in test files — ESM imports (`import { writeFileSync } from 'fs'`) used throughout
- [ ] `clearSimulatedLocation()` called in `after` hook for all geolocation tests
- [ ] Orientation tests restore `PORTRAIT` in `after` hook
- [ ] Android permissions pre-granted via `pm grant` ADB for happy-path tests; dialog-flow reserved for denial-UX tests
- [ ] iOS permission alerts handled via `driver.acceptAlert()` (not `$('~Allow')` — system UI is outside app tree)
- [ ] Screen recording started in `beforeTest` and stopped + saved in `afterTest` (delete on pass, keep on fail)
- [ ] TypeScript path aliases (`@pages`, `@helpers`) configured in tsconfig with `tsconfig-paths/register` for runtime resolution
- [ ] Spec sharding uses sorted glob to ensure deterministic split across CI matrix jobs
- [ ] Device log capture (`getLogs('logcat')` / `getLogs('syslog')`) enabled in `afterTest` on failure
- [ ] Dark mode tests restore light appearance in `after` hook and use separate visual baseline suffix

---

## `appium:permissions` Capability — Pre-Granting iOS Permissions at Session Start

Instead of handling iOS permission dialogs during test execution, pre-grant them via the `appium:permissions` capability so the app launches with permissions already set. Supported by XCUITest driver 4.18+.

```typescript
// wdio.conf.ts — pre-grant permissions per test session
const iosCaps = {
  platformName: 'iOS',
  'appium:deviceName': 'iPhone 15',
  'appium:platformVersion': '17.0',
  'appium:automationName': 'XCUITest',
  'appium:app': process.env.IOS_APP_PATH!,
  // Grant camera + location + notifications before the session opens
  'appium:permissions': JSON.stringify({
    'com.example.myapp': {
      camera:        'YES',
      location:      'always',  // 'inuse' | 'always' | 'never'
      notifications: 'YES',
      microphone:    'YES',
      photos:        'YES',
    },
  }),
};
```

**When to use capability vs runtime `acceptAlert`:**
- Use `appium:permissions` for all tests that need permissions pre-granted (happy-path flows).
- Use `driver.acceptAlert()` only when the test itself is verifying the permission request flow.
- Use `revokeAndroidPermission` / `pm revoke` for denial-UX tests that need to remove a permission after it was granted.

---

## Appium Plugin System (Appium 2.x)

Appium 2 introduced a plugin architecture that extends server behavior without modifying the core. Plugins are installed separately and must be declared in `.appiumrc.json` to survive cache invalidation in CI.

### Useful plugins

| Plugin | Purpose | Install |
|--------|---------|---------|
| `@appium/relaxed-caps-plugin` | Accept Appium 1 `desiredCapabilities` format (migration aid) | `appium plugin install relaxed-caps` |
| `appium-wait-plugin` | Server-side element wait strategy (reduces network RTTs for `waitForDisplayed`) | `appium plugin install --source npm appium-wait-plugin` |
| `@appium/images-plugin` | Image-based element finding (for screens without accessibility IDs) | `appium plugin install images` |
| `appium-device-farm` | Multi-device routing — expose multiple real devices behind one Appium URL | `appium plugin install --source npm appium-device-farm` |

### Declaring plugins in `.appiumrc.json`

```json
{
  "server": {
    "port": 4723,
    "log-level": "info",
    "plugins": ["relaxed-caps", "images"]
  },
  "driver": {
    "uiautomator2": "3.7.5",
    "xcuitest": "7.28.3"
  }
}
```

### Installing plugins in CI

Add plugin installation **after** driver installation in the CI setup step. Plugins are stored in
`APPIUM_HOME` alongside drivers — include them in the same cache:

```yaml
- name: Install Appium drivers and plugins
  run: |
    export APPIUM_HOME="${{ runner.temp }}/appium"
    npx appium@2.5.0 driver install uiautomator2
    npx appium@2.5.0 driver install xcuitest
    npx appium@2.5.0 plugin install relaxed-caps  # migration aid for legacy caps
```

**Plugin activation in capabilities:** Some plugins require activation via a capability. For
`appium-wait-plugin`, set `appium:settings[enableMultiWindows]` per their README. Check each
plugin's docs — capabilities are plugin-specific and not standardised.

---

## `browser` vs `driver` — WebDriverIO Disambiguation

WebDriverIO exposes two global objects in tests: `browser` and `driver`. They point to the same
underlying WebDriver session, but their semantics differ and mixing them inconsistently is a common
source of confusion and TypeScript errors.

| Object | Type | Use for |
|--------|------|---------|
| `browser` | `Browser<'async'>` | Element queries (`$`, `$$`), waits, screenshots, mocks, URL navigation, `isIOS`/`isAndroid` flags |
| `driver` | `AppiumBrowser` | Session-level Appium commands: `terminateApp`, `activateApp`, `installApp`, `removeApp`, `launchApp`, `getDeviceTime`, `shake`, `lock`/`unlock` |

**Rule:** Use `browser` for everything related to the UI; use `driver` for everything related to
the device or app lifecycle.

```typescript
// Correct — session management via driver
await driver.terminateApp('com.example.app');
await driver.activateApp('com.example.app');
await driver.installApp('/path/to/app.apk');

// Correct — UI interaction via browser
await browser.waitUntil(() => $('~home-screen').isDisplayed(), { timeout: 10_000 });
await browser.saveScreenshot('./screenshots/state.png');
const isIos = browser.isIOS;

// Anti-pattern: calling terminateApp on browser — compiles but type-unsafe in strict mode
// BAD: await browser.terminateApp('com.example.app');  // works but wrong object
// BAD: await driver.$('~home-screen')                  // driver lacks $ — throws at runtime
```

**TypeScript note:** `driver` is typed as `AppiumBrowser` which extends `Browser` with Appium-
specific methods. `browser` is `Browser<'async'>` — narrower, no `terminateApp`. With
`strict: true`, the TypeScript compiler will catch most cross-object misuses at compile time.

---

## Device Log Capture — Logcat, Syslog & Appium Logs  [community]

Capturing device logs alongside test failures is essential for diagnosing crashes, ANRs, and native errors that don't surface in the WebDriverIO error message.

```typescript
// test/helpers/logHelper.ts
import fs from 'fs';
import path from 'path';

/**
 * Capture Android logcat (since last clear) and save to a file.
 * Best called in afterTest on failure.
 * WHY: Appium surfaces "element not found" — logcat tells you WHY (OOM, crash, null pointer).
 */
export async function captureAndroidLogcat(label: string): Promise<void> {
  if (!browser.isAndroid) return;
  try {
    // 'logcat' is the Android log buffer type for UiAutomator2 driver
    const logs = await driver.getLogs('logcat') as Array<{ message: string; level: string; timestamp: number }>;
    const content = logs.map(l => `[${l.level}] ${new Date(l.timestamp).toISOString()} ${l.message}`).join('\n');
    const filePath = `./allure-results/logcat-${label}-${Date.now()}.txt`;
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, content);
  } catch (err) {
    console.warn('logcat capture failed:', err);
  }
}

/**
 * Capture iOS syslog (device system log) and save to a file.
 * Requires XCUITest driver with log access enabled.
 */
export async function captureIosSyslog(label: string): Promise<void> {
  if (!browser.isIOS) return;
  try {
    const logs = await driver.getLogs('syslog') as Array<{ message: string; level: string; timestamp: number }>;
    const content = logs.map(l => `[${l.level}] ${new Date(l.timestamp).toISOString()} ${l.message}`).join('\n');
    fs.writeFileSync(`./allure-results/syslog-${label}-${Date.now()}.txt`, content);
  } catch (err) {
    console.warn('syslog capture failed:', err);
  }
}

/** Filter log lines containing crash signatures */
export function extractCrashLines(logs: Array<{ message: string; level: string }>): string[] {
  const CRASH_PATTERNS = [/FATAL EXCEPTION/i, /ANR in/i, /Fatal signal/i, /EXC_BAD_ACCESS/i];
  return logs
    .filter(l => CRASH_PATTERNS.some(p => p.test(l.message)))
    .map(l => l.message);
}
```

```typescript
// wdio.conf.ts — integrate log capture into afterTest hook
import { captureAndroidLogcat, captureIosSyslog } from './test/helpers/logHelper.js';

afterTest: async (test, _ctx, { error }) => {
  if (error) {
    const label = test.title.replace(/[^a-z0-9]/gi, '-').toLowerCase();
    // Save screenshot + page source (existing)
    await browser.saveScreenshot(`./allure-results/screenshot-${label}-${Date.now()}.png`);
    const source = await browser.getPageSource();
    fs.writeFileSync(`./allure-results/page-source-${label}-${Date.now()}.xml`, source);
    // Save device logs (new)
    await captureAndroidLogcat(label);
    await captureIosSyslog(label);
  }
},
```

**Device log gotchas [community]:**
- `driver.getLogs('logcat')` returns ALL logs since the last call (Appium clears the buffer after reading). Call it once per test in `afterTest`; don't poll it during the test as you'll consume the buffer.
- `getLogTypes()` returns the list of available log types for the current session. Verify `'logcat'` or `'syslog'` is listed before calling `getLogs()` — some driver versions or device configurations omit them.
- Log volume can be enormous on Android. Filter by `level: 'ERROR'` or pattern-match for your app's package name: `logs.filter(l => l.message.includes('com.example.myapp'))`.
- Store logs as attachments in Allure (use `addAttachment` from `@wdio/allure-reporter`) rather than standalone files — they become navigable directly from the failed test in the Allure report.

---

## Dark Mode & Dynamic Type Testing  [community]

### Dark mode simulation

```typescript
// test/helpers/appearanceHelper.ts

/** Switch iOS Simulator to dark mode */
export async function setIosDarkMode(enabled: boolean): Promise<void> {
  if (!browser.isIOS) return;
  await driver.execute('mobile: setSimulatorUIAppearance', {
    appearance: enabled ? 'dark' : 'light',
  });
}

/** Switch Android emulator to dark mode via ADB */
export async function setAndroidDarkMode(enabled: boolean): Promise<void> {
  if (!browser.isAndroid) return;
  const value = enabled ? 'yes' : 'no';
  await driver.execute('mobile: shell', {
    command: 'cmd',
    args: ['uimode', 'night', value],
  });
}
```

```typescript
// test/specs/dark-mode-visual.spec.ts
import { setIosDarkMode, setAndroidDarkMode } from '../helpers/appearanceHelper.js';

describe('Dark mode visual regression', () => {
  after(async () => {
    // Restore light mode after test suite
    if (browser.isIOS) await setIosDarkMode(false);
    if (browser.isAndroid) await setAndroidDarkMode(false);
  });

  it('should render dashboard correctly in dark mode', async () => {
    if (browser.isIOS) await setIosDarkMode(true);
    if (browser.isAndroid) await setAndroidDarkMode(true);

    await driver.terminateApp(process.env.APP_BUNDLE_ID!);
    await driver.activateApp(process.env.APP_BUNDLE_ID!);
    await $('~dashboard-screen').waitForDisplayed({ timeout: 10_000 });
    // Use visual regression snapshot with '-dark' suffix to keep separate from light baseline
    await expect(browser).toMatchScreenSnapshot('dashboard-home-dark');
  });
});
```

**Dark mode gotchas [community]:**
- `mobile: setSimulatorUIAppearance` requires Appium XCUITest driver 4.8+. Earlier versions throw `UnknownCommandException`. Check `appium driver list --installed` to verify driver version.
- Always restart the app after changing appearance mode — many apps only read the color scheme during app launch, not in response to live appearance changes.
- Dark mode snapshots must use a different baseline name (e.g. `-dark` suffix) than light mode snapshots. Using the same baseline name with different appearance modes causes perpetual visual failures.

---

## Appium Inspector Workflow

Appium Inspector is the official GUI tool for discovering element attributes (accessibility IDs,
resource IDs, class names) without writing code. Use it to build your initial selector inventory
before writing Page Objects.

### Setup

1. Install: `npm install -g appium-inspector` or download from the
   [GitHub releases page](https://github.com/appium/appium-inspector/releases).
2. Start your local Appium server: `npx appium --port 4723`.
3. Open Appium Inspector → enter `Remote Host: 127.0.0.1`, `Port: 4723`, `Path: /`.
4. Fill in capabilities (same JSON as your `wdio.conf.ts` capabilities block) and click **Start Session**.

### Finding accessibility IDs

In the Inspector's element tree:
- Select an element → look for the `name` attribute (iOS) or `content-desc` attribute (Android).
  These are the values you pass to `~accessibility-id` selectors.
- If `name` / `content-desc` is empty, the element has no accessibility ID. Work with your app
  developers to add `accessibilityLabel` (iOS) or `contentDescription` (Android) to the component.

### XPath as a last resort

Inspector shows XPath expressions — use these **only** to verify an element exists when other
selectors fail. Never copy-paste Inspector-generated XPath into production Page Objects; it uses
absolute paths (`//*[1]/android.view.View[3]`) that break on the next layout change.

### Snapshot caching quirk  [community]

Appium Inspector's "Refresh" button takes a new snapshot of the element tree by calling
`getPageSource()` under the hood. On complex screens this can take 5–30 seconds. If the Inspector
appears to freeze, it is building the element tree — do not click Refresh again. WHY: the
UIAutomator2 XML serialiser walks the entire view hierarchy; snapshotMaxDepth controls how deep
it goes (see Performance Tuning section).

---

## `scrollIntoView()` — Simplified Scroll-to-Element (WebDriverIO v8+)

WebDriverIO v8 added `element.scrollIntoView()` as a convenience wrapper around the Appium
`mobile: scrollGesture` command. Use it when you just need an element to appear in the viewport
without needing to know scroll direction or percentages.

```typescript
// Simple: scroll until the element is visible
const termsLink = $('~terms-and-conditions-link');
await termsLink.scrollIntoView();
await termsLink.click();

// With options — control direction and alignment
await $('~bottom-cta').scrollIntoView({ block: 'center' });
```

**Limitations:**
- `scrollIntoView()` is a browser-context API in WebDriverIO — it works on WebViews and DOM
  elements. For fully native screens on iOS/Android it delegates to `mobile: scrollGesture` via
  the Appium driver, which requires the element to already be in the accessibility tree (even if
  not yet in the viewport).
- On Android, if the element is inside a `RecyclerView` that uses lazy loading (items not in the
  tree until scrolled to), `scrollIntoView()` will not find the element. Use the `scrollToElement`
  helper from Pattern 4 (manual gesture loop) in that case.
- Prefer `scrollIntoView()` for simple linear scrolling; use `browser.execute('mobile:
  scrollGesture', ...)` when you need precise control over scroll distance or direction.

---

## Expo Go vs Standalone Build — Appium Compatibility  [community]

**Gotcha:** Appium cannot instrument Expo Go. Attempting to test a React Native app through the
Expo Go app fails with `No App Bundle Found` or the session attaches to the Expo shell app
instead of your JavaScript bundle.

WHY: Expo Go is a pre-built shell that dynamically loads your Metro bundle at runtime. Appium
(XCUITest / UiAutomator2) instruments the native host app, which in Expo Go's case is the Expo
shell — not your app. Your `accessibilityLabel` values and screen structure are invisible to
Appium unless the JavaScript bundle has been compiled into the host app binary.

**Fix:** Build a custom Expo Development Client:

```bash
# Install the dev client package
npx expo install expo-dev-client

# Build a dev client for iOS simulator
eas build --profile development --platform ios --local

# Build a dev client for Android emulator
eas build --profile development --platform android --local
```

Point `appium:app` in `wdio.conf.ts` at the output `.app` / `.apk` from the EAS build. The dev
client includes your full React Native app and is instrumented normally by Appium.

**For CI:** Cache the dev client build artifact (`.app` / `.apk`) alongside your app code hash
so you only rebuild when native code changes. Pure JS changes do not require a new dev client
build — you can inject the new bundle via Metro bundler running locally.

```typescript
// wdio.conf.ts — use EAS build output path
'appium:app': process.env.IOS_APP_PATH ?? './ios/build/YourApp.app',
// Never: 'appium:app': 'com.expo.go' — this attaches to the Expo shell, not your app
```