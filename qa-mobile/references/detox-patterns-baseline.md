# Detox Patterns — Baseline Reference Guide

> Addresses the most common cause of Detox tests passing locally but failing on CI.
> Sources: Detox official documentation (wix.github.io/Detox), community best practices, and known CI failure patterns.

---

## Table of Contents

1. [Root Causes of Local-Pass / CI-Fail](#1-root-causes-of-local-pass--ci-fail)
2. [Synchronization — The #1 Source of Flakiness](#2-synchronization--the-1-source-of-flakiness)
3. [Element Matchers and Selectors](#3-element-matchers-and-selectors)
4. [Device and App Lifecycle](#4-device-and-app-lifecycle)
5. [Reliable Assertions with `waitFor`](#5-reliable-assertions-with-waitfor)
6. [Animations and Native Transitions](#6-animations-and-native-transitions)
7. [Network Mocking and External Calls](#7-network-mocking-and-external-calls)
8. [CI-Specific Configuration](#8-ci-specific-configuration)
9. [Test Isolation and State Reset](#9-test-isolation-and-state-reset)
10. [Artifact Collection for Debugging](#10-artifact-collection-for-debugging)
11. [Anti-Patterns Checklist](#11-anti-patterns-checklist)
12. [Quick Reference Patterns](#12-quick-reference-patterns)

---

## 1. Root Causes of Local-Pass / CI-Fail

| Root Cause | Why It Passes Locally | CI Symptom |
|---|---|---|
| Implicit timing assumptions (`sleep`) | Fast local device / hot cache | Timeout on slow CI runner |
| Animations not disabled | Dev build has `__DEV__` fast animations | Prod/Release build has full-duration animations |
| Non-deterministic test order | Single developer runs sequentially | Parallel shards expose order dependency |
| Leaked state between tests | Dev simulator retains state from prior run | Fresh CI simulator starts clean |
| Network calls to real APIs | Developer is authenticated, network is fast | CI has no credentials or is throttled |
| Bundle metro port conflict | Single process on dev machine | Multiple parallel builds share port 8081 |
| Missing `testID` in release build | Debug build includes all attributes | Release build strips certain attributes |
| Simulator version mismatch | Developer pinned to iOS 17 | CI runs iOS 16 by default |

---

## 2. Synchronization — The #1 Source of Flakiness

Detox has a built-in synchronization mechanism that waits for the JS thread, native animations, and timers to settle before proceeding. **Misunderstanding this mechanism causes the vast majority of flaky tests.**

### 2.1 How Detox Synchronizes

Detox auto-waits until:
- The React Native JS thread is idle
- All active `setTimeout` / `setInterval` calls with delay < 1500 ms have resolved
- All active network requests have completed (if not mocked)
- All animations driven by `Animated` or `LayoutAnimation` have ended

### 2.2 When Auto-Sync Breaks

**Problem:** Infinite polling loops, persistent timers, or streaming connections prevent Detox from detecting "idle."

```javascript
// BAD — a setInterval that never clears blocks Detox sync
setInterval(() => pollServer(), 3000);
```

**Fix — disable sync temporarily:**

```javascript
it('works while background polling runs', async () => {
  await device.disableSynchronization();
  await element(by.id('start-button')).tap();
  await waitFor(element(by.id('result-label')))
    .toBeVisible()
    .withTimeout(8000);
  await device.enableSynchronization();
});
```

**Fix — use `launchArgs` to suppress the timer in test mode:**

```javascript
// In test setup
await device.launchApp({
  newInstance: true,
  launchArgs: { detoxDisablePolling: '1' },
});
```

```javascript
// In app code (RN)
if (__DEV__ || process.env.DETOX_DISABLE_POLLING) {
  // skip polling
}
```

### 2.3 Long Animations that Block Sync

Any animation longer than 1500 ms will block Detox's idle detection:

```javascript
// Fix: disable animations for test builds
await device.setURLBlacklist(['.*']); // optional: also block network
// In .detoxrc.js — set testRunner args or launchArgs
```

Better: disable animations at the app level (see Section 6).

---

## 3. Element Matchers and Selectors

### 3.1 Preferred: `by.id()` (testID)

```jsx
// In React Native component
<TouchableOpacity testID="login-button">
  <Text>Login</Text>
</TouchableOpacity>
```

```javascript
// In Detox test
await element(by.id('login-button')).tap();
```

- `testID` maps to `accessibilityIdentifier` on iOS and `tag` on Android.
- Survives text copy changes, style refactors, and component hierarchy changes.
- Always prefer over `by.text()` or `by.type()` for interactive elements.

### 3.2 `by.text()` — Use with Caution

```javascript
// FRAGILE — breaks on copy changes, localization, truncation
await element(by.text('Submit')).tap();

// SAFER — combine with a container testID
await element(by.text('Submit').withAncestor(by.id('checkout-form'))).tap();
```

### 3.3 `by.label()` — Accessibility Label

```javascript
// Good for elements already marked for accessibility
await element(by.label('Open navigation menu')).tap();
```

### 3.4 Multiple Matches

Detox throws if a matcher returns more than one element. Narrow the scope:

```javascript
// BAD — may match multiple rows
await element(by.text('Delete')).tap();

// GOOD — scope to a specific row
await element(by.id('row-42').withDescendant(by.text('Delete'))).tap();
// or
await element(by.id('delete-button-42')).tap();
```

### 3.5 Index-Based Selection (Last Resort)

```javascript
// Fragile — breaks if order changes
await element(by.id('list-item')).atIndex(0).tap();
```

Only use when the list is deterministic and you control the data.

---

## 4. Device and App Lifecycle

### 4.1 `beforeAll` vs `beforeEach`

```javascript
describe('Checkout Flow', () => {
  // Launch once for the entire suite — faster but risks state leakage
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  // Reload JS between each test — safer, catches most state issues
  beforeEach(async () => {
    await device.reloadReactNative();
  });
});
```

**Rule of thumb:**
- Use `beforeAll` + `launchApp({ newInstance: true })` for top-level suites.
- Use `beforeEach` + `reloadReactNative()` for cheap state resets within a suite.
- Use `beforeEach` + `launchApp({ newInstance: true })` when native modules hold state (e.g., permissions, keychain).

### 4.2 `newInstance: true` vs `delete: true`

```javascript
// newInstance: terminates and restarts — keeps app data (Keychain, AsyncStorage)
await device.launchApp({ newInstance: true });

// delete: true — equivalent to uninstalling and reinstalling; full clean slate
await device.launchApp({ delete: true });
```

Use `delete: true` only when you need a fully clean device state (e.g., onboarding tests).

### 4.3 Permissions

```javascript
// Grant permissions before launch to avoid system dialog interruptions
await device.launchApp({
  newInstance: true,
  permissions: {
    notifications: 'YES',
    camera: 'YES',
    location: 'always',
    photos: 'YES',
  },
});
```

**CI gotcha:** System permission dialogs appear over the app and cannot be interacted with via `element()`. Always pre-grant.

### 4.4 URL / Deep Link Testing

```javascript
it('opens product screen from deep link', async () => {
  await device.launchApp({
    newInstance: true,
    url: 'myapp://products/42',
  });
  await expect(element(by.id('product-screen-42'))).toBeVisible();
});
```

---

## 5. Reliable Assertions with `waitFor`

### 5.1 Never Assert Without `waitFor` on Async State

```javascript
// FLAKY — element may not be visible yet when assertion runs
await expect(element(by.id('success-toast'))).toBeVisible();

// RELIABLE — waits up to 5 seconds
await waitFor(element(by.id('success-toast')))
  .toBeVisible()
  .withTimeout(5000);
```

### 5.2 `waitFor` + `whileElement` (Scroll to Reveal)

```javascript
// Scroll a FlatList until the target element is visible
await waitFor(element(by.id('product-item-99')))
  .toBeVisible()
  .whileElement(by.id('product-list'))
  .scroll(50, 'down');
```

### 5.3 Timeout Budgets on CI

CI runners are slower than developer machines. Recommended timeouts:

| Scenario | Local | CI |
|---|---|---|
| Simple element visibility | 2000 ms | 5000 ms |
| API response visible | 3000 ms | 10000 ms |
| Screen navigation | 2000 ms | 5000 ms |
| App cold launch | 5000 ms | 15000 ms |

Use environment-aware timeouts:

```javascript
const IS_CI = process.env.CI === 'true';
const TIMEOUT = {
  short: IS_CI ? 5000 : 2000,
  medium: IS_CI ? 10000 : 3000,
  long: IS_CI ? 15000 : 5000,
};

await waitFor(element(by.id('dashboard')))
  .toBeVisible()
  .withTimeout(TIMEOUT.long);
```

### 5.4 Negative Assertions

```javascript
// FLAKY — element may still be animating out when checked
await expect(element(by.id('loading-spinner'))).not.toBeVisible();

// RELIABLE — wait for it to disappear
await waitFor(element(by.id('loading-spinner')))
  .not.toBeVisible()
  .withTimeout(5000);
```

---

## 6. Animations and Native Transitions

### 6.1 Disable Animations in Test Builds (Recommended)

**iOS — add to `AppDelegate.m` / `AppDelegate.mm`:**

```objc
#if DEBUG
  // Allow Detox to disable animations
  [UIView setAnimationsEnabled:NO]; // only in test target, not release
#endif
```

Or via `launchArgs`:

```javascript
await device.launchApp({
  newInstance: true,
  launchArgs: { detoxDisableHierarchyDump: 'YES' }, // optional perf improvement
});
```

**Detox built-in animation control (iOS Simulator only):**

```javascript
// In global setup or beforeAll
await device.setStatusBar({ /* ... */ }); // forces deterministic status bar
```

**React Native `Animated` — set `useNativeDriver: false` and check `LayoutAnimation`:**

```javascript
// In RN app code — check for test environment
const isTest = !!process.env.JEST_WORKER_ID || !!global.__DEV__;
if (isTest) {
  jest.useFakeTimers(); // only in Jest env, not in Detox process
}
```

**Best approach — conditional in RN app:**

```javascript
import { Animated, Platform } from 'react-native';

// Detect Detox via launchArgs
const DETOX_MODE = global.__DETOX__ === true;

const duration = DETOX_MODE ? 0 : 300;
Animated.timing(animValue, { toValue: 1, duration, useNativeDriver: true }).start();
```

Set `__DETOX__` via launchArgs in your test setup:

```javascript
// jest-setup.js (Detox global setup)
await device.launchApp({
  newInstance: true,
  launchArgs: { DETOX_MODE: '1' },
});
```

```javascript
// In RN app
const DETOX_MODE = global.DETOX_MODE === '1';
```

### 6.2 `LayoutAnimation`

`LayoutAnimation` does not auto-integrate with Detox sync. Wrap with:

```javascript
// Disable in test mode
if (!DETOX_MODE) {
  LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
}
```

---

## 7. Network Mocking and External Calls

### 7.1 Why Real Network Calls Cause Flakiness on CI

- No credentials / auth tokens available
- Network latency varies — requests timeout intermittently
- External APIs may have rate limits
- CI may block outbound network

### 7.2 Recommended: Mock at the Server Level

Use a mock server (e.g., `nock`, `msw`, or a local Express server) started before Detox:

```javascript
// globalSetup.js
const { startMockServer } = require('./mock-server');

module.exports = async () => {
  global.mockServer = await startMockServer(8088);
};
```

```javascript
// .detoxrc.js — point app to mock server
apps: {
  'ios.debug': {
    launchArgs: {
      API_BASE_URL: 'http://localhost:8088',
    },
  },
},
```

### 7.3 Detox URL Blacklist (Block Specific URLs)

```javascript
// Block analytics and telemetry calls that can slow down sync
await device.setURLBlacklist([
  '.*analytics\\.example\\.com.*',
  '.*sentry\\.io.*',
  '.*crashlytics\\.com.*',
]);
```

This tells Detox's sync mechanism to ignore these requests when deciding "is the app idle."

### 7.4 Pass Credentials via `launchArgs`

```javascript
// Never hardcode — use environment variables
await device.launchApp({
  newInstance: true,
  launchArgs: {
    E2E_USER_EMAIL: process.env.E2E_USER_EMAIL,
    E2E_USER_PASSWORD: process.env.E2E_USER_PASSWORD,
  },
});
```

```javascript
// In RN app
const email = NativeModules.RNConfig?.E2E_USER_EMAIL || '';
```

---

## 8. CI-Specific Configuration

### 8.1 `.detoxrc.js` — Separate Debug and Release Configurations

```javascript
// .detoxrc.js
module.exports = {
  testRunner: {
    args: {
      config: 'e2e/jest.config.js',
      maxWorkers: process.env.CI ? 1 : 2, // Single worker on CI to avoid port conflicts
    },
    jest: {
      setupTimeout: 120000, // longer setup timeout on CI
    },
  },
  apps: {
    'ios.debug': {
      type: 'ios.app',
      binaryPath: 'ios/build/Build/Products/Debug-iphonesimulator/YourApp.app',
      build: 'xcodebuild -workspace ios/YourApp.xcworkspace -scheme YourApp -configuration Debug -sdk iphonesimulator -derivedDataPath ios/build',
    },
    'ios.release': {
      type: 'ios.app',
      binaryPath: 'ios/build/Build/Products/Release-iphonesimulator/YourApp.app',
      build: 'xcodebuild -workspace ios/YourApp.xcworkspace -scheme YourApp -configuration Release -sdk iphonesimulator -derivedDataPath ios/build',
    },
  },
  devices: {
    'simulator': {
      type: 'ios.simulator',
      device: { type: 'iPhone 14', os: 'iOS 16.4' }, // pin exact version
    },
  },
  configurations: {
    'ios.sim.debug': { device: 'simulator', app: 'ios.debug' },
    'ios.sim.release': { device: 'simulator', app: 'ios.release' }, // use for CI
  },
};
```

### 8.2 CI — Recommended `xcodebuild` Flags

```bash
# Disable parallelism during build to avoid resource contention on CI
xcodebuild \
  -workspace ios/YourApp.xcworkspace \
  -scheme YourApp \
  -configuration Release \
  -sdk iphonesimulator \
  -derivedDataPath ios/build \
  -parallelizeTargets NO \
  -jobs 2 \
  CODE_SIGNING_ALLOWED=NO \
  | xcpretty
```

### 8.3 Boot Simulator Before Running Tests

```bash
# In CI pipeline — boot and wait before running tests
xcrun simctl boot "iPhone 14" 2>/dev/null || true
xcrun simctl bootstatus "iPhone 14" -b
```

### 8.4 Detox Clean on CI

```bash
# Ensure no cached build artifacts from a previous run
npx detox clean-framework-cache
npx detox build-framework-cache
```

### 8.5 Retry Flaky Tests (Short-Term Mitigation)

```javascript
// jest.config.js
module.exports = {
  retries: process.env.CI ? 2 : 0, // retry up to 2 times on CI
  testTimeout: 120000,
};
```

Note: retries mask flakiness — always fix the root cause. Use this only as a CI safety net while investigating.

### 8.6 Parallel Sharding

```bash
# Split tests across multiple CI machines
npx detox test --configuration ios.sim.release --shard-index 0 --shard-count 3
npx detox test --configuration ios.sim.release --shard-index 1 --shard-count 3
npx detox test --configuration ios.sim.release --shard-index 2 --shard-count 3
```

Each shard must use a different simulator UDID to avoid conflicts:

```javascript
// .detoxrc.js — define multiple device entries
devices: {
  'simulator-0': { type: 'ios.simulator', device: { type: 'iPhone 14', id: 'UDID_0' } },
  'simulator-1': { type: 'ios.simulator', device: { type: 'iPhone 14', id: 'UDID_1' } },
  'simulator-2': { type: 'ios.simulator', device: { type: 'iPhone 14', id: 'UDID_2' } },
},
```

---

## 9. Test Isolation and State Reset

### 9.1 AsyncStorage Reset

```javascript
// In beforeEach or a shared helper
import AsyncStorage from '@react-native-async-storage/async-storage';

// From within the test process (requires bridge or native module)
// Preferred approach: launchApp({ delete: true }) for full storage wipe
// OR use a dedicated RN test helper screen

await device.launchApp({
  newInstance: true,
  launchArgs: { RESET_STORAGE: '1' },
});
```

In RN app:

```javascript
import AsyncStorage from '@react-native-async-storage/async-storage';

if (launchArgs.RESET_STORAGE === '1') {
  await AsyncStorage.clear();
}
```

### 9.2 Authentication State

```javascript
// helper: loginAs.js
async function loginAs(role = 'user') {
  await element(by.id('email-input')).clearText();
  await element(by.id('email-input')).typeText(USERS[role].email);
  await element(by.id('password-input')).clearText();
  await element(by.id('password-input')).typeText(USERS[role].password);
  await element(by.id('login-button')).tap();
  await waitFor(element(by.id('home-screen')))
    .toBeVisible()
    .withTimeout(TIMEOUT.long);
}
```

Always use `clearText()` before `typeText()` — simulators may retain field contents from previous tests.

### 9.3 Avoid Test Order Dependencies

```javascript
// BAD — test 2 depends on test 1 having run
describe('Cart', () => {
  it('adds item to cart', async () => { /* ... */ });
  it('checks out (assumes item is in cart)', async () => { /* ... */ }); // FRAGILE
});

// GOOD — each test sets up its own state
describe('Cart', () => {
  it('adds item to cart', async () => { /* ... */ });
  it('checks out after adding item', async () => {
    await addItemToCart('product-42'); // helper that ensures state
    await checkout();
  });
});
```

---

## 10. Artifact Collection for Debugging

Configure Detox to capture screenshots, videos, and logs on failure — essential for debugging CI-only failures.

### 10.1 `.detoxrc.js` Artifacts Configuration

```javascript
artifacts: {
  rootDir: '.artifacts',
  pathBuilder: './e2e/artifactPathBuilder.js',
  plugins: {
    screenshot: {
      enabled: true,
      shouldTakeAutomaticSnapshots: true,
      takeWhen: {
        testStart: false,
        testDone: false,
        testFailure: true, // capture only on failure
      },
    },
    video: {
      enabled: process.env.CI === 'true', // only on CI (slow locally)
      keepOnlyFailedTestsArtifacts: true,
    },
    log: {
      enabled: true,
    },
    timeline: {
      enabled: true,
    },
  },
},
```

### 10.2 CI — Publish Artifacts

```yaml
# GitHub Actions example
- name: Run Detox tests
  run: npx detox test --configuration ios.sim.release --artifacts-location .artifacts

- name: Upload test artifacts
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: detox-artifacts
    path: .artifacts/
    retention-days: 7
```

### 10.3 Manual Screenshots in Tests

```javascript
it('verifies layout', async () => {
  await element(by.id('dashboard')).tap();
  await device.takeScreenshot('dashboard-state'); // saved to artifacts dir
  await expect(element(by.id('welcome-banner'))).toBeVisible();
});
```

---

## 11. Anti-Patterns Checklist

Review your tests against this list when diagnosing a CI failure.

| Anti-Pattern | Fix |
|---|---|
| `await new Promise(r => setTimeout(r, 2000))` — hard-coded sleep | Replace with `waitFor(...).toBeVisible().withTimeout(N)` |
| Asserting on element without `waitFor` after async action | Always wrap post-async assertions in `waitFor` |
| `by.text()` for buttons | Use `testID` + `by.id()` |
| Multiple elements matching same `by.id()` | Use unique `testID` per element |
| `atIndex(N)` on dynamic lists | Use data-driven `testID` (e.g., `item-{id}`) |
| Real network calls to external APIs | Mock the network layer or use a local mock server |
| Persistent `setInterval` in app code | Disable in test mode via `launchArgs` |
| Long animations (> 1500 ms) | Disable or shorten in test mode |
| Missing `clearText()` before `typeText()` | Always `clearText()` first |
| `beforeEach` that does full `launchApp` | Use `reloadReactNative()` for speed; reserve `launchApp` for `beforeAll` |
| No permissions pre-granted | Set `permissions` in `launchApp` options |
| Simulator not booted before test run | Boot and await status in CI pipeline |
| Tests depend on previous test state | Each test must set up its own required state |
| No artifacts configured | Add screenshot + video + log plugins to `.detoxrc.js` |
| Hardcoded timeouts not scaled for CI | Use `IS_CI`-aware timeout constants |

---

## 12. Quick Reference Patterns

### 12.1 Global Setup File (`e2e/setup.js`)

```javascript
const { device } = require('detox');

beforeAll(async () => {
  await device.launchApp({
    newInstance: true,
    permissions: {
      notifications: 'YES',
      camera: 'YES',
      location: 'always',
    },
    launchArgs: {
      DETOX_MODE: '1',
      API_BASE_URL: process.env.API_BASE_URL || 'http://localhost:8088',
    },
  });
  await device.setURLBlacklist([
    '.*analytics\\..*',
    '.*sentry\\.io.*',
  ]);
});

afterAll(async () => {
  // Teardown mock server etc.
});
```

### 12.2 Timeout Constants (`e2e/constants.js`)

```javascript
const IS_CI = process.env.CI === 'true';

module.exports = {
  TIMEOUT: {
    short:  IS_CI ? 5000  : 2000,
    medium: IS_CI ? 10000 : 3000,
    long:   IS_CI ? 20000 : 5000,
    launch: IS_CI ? 30000 : 10000,
  },
};
```

### 12.3 Screen Navigation Helper

```javascript
const { TIMEOUT } = require('./constants');

async function navigateTo(screenId) {
  await waitFor(element(by.id(screenId)))
    .toBeVisible()
    .withTimeout(TIMEOUT.long);
}

module.exports = { navigateTo };
```

### 12.4 Typed Text with Clear

```javascript
async function fillInput(testId, value) {
  const input = element(by.id(testId));
  await input.tap();
  await input.clearText();
  await input.typeText(value);
  await input.tapReturnKey();
}
```

### 12.5 Wait for Toast / Snackbar to Disappear

```javascript
async function waitForToastToClose(toastId = 'toast-message') {
  // First confirm it appeared
  await waitFor(element(by.id(toastId)))
    .toBeVisible()
    .withTimeout(TIMEOUT.medium);
  // Then wait for it to go away
  await waitFor(element(by.id(toastId)))
    .not.toBeVisible()
    .withTimeout(TIMEOUT.long);
}
```

---

## Sources and Further Reading

- Detox Official Docs: https://wix.github.io/Detox/
- Detox Getting Started: https://wix.github.io/Detox/docs/introduction/getting-started
- Detox Flakiness Guide: https://wix.github.io/Detox/docs/troubleshooting/flakiness
- Detox Synchronization: https://wix.github.io/Detox/docs/articles/synchronization
- Detox Matchers API: https://wix.github.io/Detox/docs/api/matchers
- Detox `waitFor` API: https://wix.github.io/Detox/docs/api/expect#waitforexpect
- Detox Artifacts: https://wix.github.io/Detox/docs/config/artifacts
- Detox CI Guide: https://wix.github.io/Detox/docs/introduction/ci
- Detox URL Blacklist: https://wix.github.io/Detox/docs/api/device#deviceseturlblacklisturls

---

*Generated: 2026-04-26 | Baseline v1.0 — eval-1-detox-flakiness*
