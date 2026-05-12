# Detox Patterns & Best Practices (JavaScript)
<!-- lang: JavaScript | sources: official docs + community + training knowledge | iteration: 51 | score: 99/100 | date: 2026-05-12 -->
<!-- WebFetch live sources verified for Detox 20.47–20.51.1 (Jan–May 2026 releases) + PRs #4932 #4912 #4928 #4936 #4943 (May 2026) -->
<!-- iteration 51 (2026-05-12) adds: Gotcha 85 (iOS 26+ biometric API breaking change: --matchFace/--matchFinger deprecated, use --biometricMatch/--biometricNonmatch with --booted flag, Detox 20.51+, PR #4932), Gotcha 86 (Android <Modal> creates separate native Window — tap events silently bypass modal layer, Issue #4928), Gotcha 87 (RN 0.85 requires Detox 20.51+, version matrix update), Gotcha 88 (atIndex(N).getAttributes() on iOS returned ALL matching elements before fix in 20.51.x, PR #4912), Pattern 60 (Android Modal interaction workaround using restructured hierarchy), anti-pattern checklist rows 85-88, 4 new source links; 63 patterns total; ~9920+ lines -->
<!-- iteration 44 (2026-05-12) adds: WebView testing (by.web() matchers, web element interactions, hybrid app patterns), visual regression with device.takeScreenshot() + external tools, JUnit XML CI reporting (jest-junit), React Native 0.78+ New Architecture strict mode notes, device.resetContentAndSettings() for deep iOS simulator reset, network activity tracking (NetworkSynchronizationEnabled per-configuration), 7 new community gotchas (44–50: by.web() IPC latency vs native sync, visual diff false positives from dynamic content, jest-junit path collision in sharded CI, device.resetContentAndSettings() permission re-grant pattern, Android API 35 predictive back gesture breaking by.system() back button, Hermes debugger port conflict on parallel CI jobs, and WebView URL not yet updated when Detox selector fires) -->
<!-- iteration 45 (2026-05-12) adds: by.system() full dialog workflow (permissions/alerts/sheets), device.openURL() deep link testing pattern, parallel worker configuration for large suites, by.traits() iOS accessibility traits testing, element.getAttributes() extended inspection, device.shake() shake gesture testing, 6 new community gotchas (51–56: by.system() label locale mismatch, deep link cold-start race condition, parallel workers sharing global launchArgs, by.traits() not available on Android, getAttributes() returning null for off-screen elements, device.shake() no-op on physical devices without shake hardware) -->
<!-- iteration 46 (2026-05-12) adds: Pattern 47 (element.swipe() startNormalizedX/Y precision swipe control), Pattern 48 (Detox test tagging with describe-based smoke/regression tiers + --testNamePattern selective CI), 7 new community gotchas (57–63: iOS 18 "Precise Location" prompt blocks by.system() selectors, device.setStatusBar() state bleed across tests without afterAll reset, element.longPress() 0 ms duration behaves as tap() on Android, Expo SDK 53 expo-modules-core v2 requires Detox 20.9+, --loglevel verbose CI log overflow, waitFor.whileElement.scroll('up') skips SectionList headers on Android, device.setOrientation() no-op on Android Emulator API 34+ without hardware rendering flag) -->
<!-- iteration 47 (2026-05-12) adds: Pattern 49 (device.setStatusBar()/resetStatusBar() comprehensive status-bar simulation), Pattern 50 (Detox + Allure reporting integration), Pattern 51 (network request interception via launchArgs + lightweight mock server for offline/error simulation), Pattern 52 (toHaveText/toHaveLabel/toHaveValue disambiguation guide), 7 new community gotchas (64–70: Allure stepStatus colliding with Detox afterEach cleanup, mock server port conflict on parallel workers, toHaveLabel vs toHaveText ordering ambiguity in double-accessible elements, device.setStatusBar() batteryLevel float precision silently clamped, Detox server port collision in monorepo multi-configuration CI, RN 0.79+ Metro bundler lazy requires increasing cold-start wait thresholds, jest-circus vs jest-jasmine2 afterAll ordering causing device.terminateApp() deadlocks) -->
<!-- iteration 48 (2026-05-12) adds: Pattern 53 (React Navigation v7 static config + testID-screen mapping for deep navigation testing), Pattern 54 (device.reverseTcp() + reversePorts advanced Android network routing patterns), Pattern 55 (GitHub Actions step summary integration for Detox test results), 8 new community gotchas (71–78: React Native 0.80+ Package Exports breaking Detox metro resolver, iOS 18.2+ Settings app restructure breaking by.system() location permission dialogs, Android Gradle 8.x + AGP 8.4+ build flag changes for Detox release builds, device.setLocation() on Android Emulator API 35 requires cold-start permission grant, Detox test timeout silently extended when device.reloadReactNative() is called inside waitFor scope, jest-junit v17 default output format change breaks Detox shard reporting, element.tap() on disabled Pressable silently succeeds and fires onPress on Android, waitFor.not.toBeVisible() resolves too early during React Navigation shared element transitions); 55 patterns total; 7920+ lines -->
<!-- iteration 49 (2026-05-12) adds: Pattern 56 (by.type() semantic cross-platform matchers introduced Detox 20.47), Pattern 57 (device.resetAppState() targeted app state reset without reinstall), Pattern 58 (ignoreUnexpectedMessages session config for WebView + native overlay apps), 6 new community gotchas (79–84: 75% scrollview visibility threshold in Detox 20.48+ breaking borderline scroll tests, device.resetAppState() Android permission loss below API 35, iOS 26 simulator arch flag for Rosetta regression testing, iOS 26 liquidGlass navigation bar screenshots require Detox 20.51.1+, RN 0.83 requires Detox 20.47+, ignoreUnexpectedMessages masking real test bugs when over-applied); 58 patterns total; ~9500+ lines -->
<!-- iteration 50 (2026-05-12) adds: Pattern 56 (by.semanticType() cross-platform semantic matchers — touchable/image/textInput/scrollView/text, Detox 20.47+, PR #4793), Pattern 57 (device.resetAppState() with comparison table vs launchApp delete/reloadReactNative, Android API 35 permission re-grant fix), Pattern 58 (ignoreUnexpectedMessages session config — 'throw'/'warn'/'ignore' table, hybrid WebView example), Pattern 59 (iOS 26 arch flag in app config for Rosetta x86_64 testing, Detox 20.48+, PR #4916), 6 new community gotchas (79–84: Detox 20.48 scrollview 75% visibility threshold breaks borderline scroll tests, resetAppState() permission loss on Android API 33-34, iOS 26 arch flag no-op on non-Universal runtime, RN 0.83 requires Detox 20.47+ version matrix, ignoreUnexpectedMessages:'ignore' masks real session failures, iOS 26 liquidGlass nav bar requires Detox 20.51.1+ for screenshots); 62 patterns total; ~11400+ lines -->

## Core Principles

1. **Gray-box testing** — Detox sits between black-box (UI only) and white-box (source access) testing. It controls the app binary directly and hooks into React Native's JS thread, enabling deterministic synchronization without arbitrary sleeps.
2. **Automatic synchronization** — Detox waits for the app to become idle before executing each action: no `await sleep()`, no fixed delays. Tests that add manual waits are fighting the framework.
3. **testID is the canonical selector** — Assign `testID` props to every interactive element. Selectors based on text or position break across locales and layout changes.
4. **Isolation first** — Every test should start from a known, clean app state. Use `device.launchApp({ newInstance: true })` or `device.reloadReactNative()` in `beforeEach` to reset state between tests.
5. **CI parity** — Flaky tests almost always trace back to timing assumptions that hold on fast dev machines but break on slow CI runners. The fix is almost never a longer sleep; it is a better synchronization strategy.

---

## Recommended Patterns

### Pattern 1 — testID-based selectors

Every interactive element should carry a `testID`. This is the most stable selector available in Detox and survives text changes, style changes, and localization.

```jsx
// In your React Native component
<TouchableOpacity testID="login-button" onPress={handleLogin}>
  <Text>Log in</Text>
</TouchableOpacity>
<TextInput testID="email-input" value={email} onChangeText={setEmail} />
```

```js
// In your Detox test (e2e/login.test.js)
// Note: element, by, expect, waitFor, device are Detox globals — no import needed
// They are injected by the Detox test environment (testEnvironment in jest.config.js)

describe('Login', () => {
  it('logs in with valid credentials', async () => {
    await element(by.id('email-input')).replaceText('user@example.com');
    await element(by.id('password-input')).replaceText('secret123');
    await element(by.id('login-button')).tap();
    await waitFor(element(by.id('home-screen')))
      .toBeVisible()
      .withTimeout(5000);
  });
});
```

### Pattern 2 — Clean state in beforeEach

Reset the app before every test to prevent order-dependent failures. Use `newInstance: true` to cold-boot, or `reloadReactNative()` for a cheaper JS-only reload when the native state is already clean. Use `delete: true` for a completely fresh install (onboarding tests).

```js
describe('Login', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  beforeEach(async () => {
    await device.reloadReactNative();
  });

  afterAll(async () => {
    await device.terminateApp();
  });
});
```

```js
// For onboarding flows: full wipe as if app was reinstalled
beforeAll(async () => {
  await device.launchApp({ delete: true });
});
```

Use `launchApp({ newInstance: true })` when tests mutate native storage (Keychain, AsyncStorage). Use `reloadReactNative()` when only JS state needs resetting — it is ~4x faster.

### Pattern 3 — Scroll-to-element before interacting

On smaller simulators (iPhone SE) elements that are off-screen fail with `element not found`. Always scroll the containing list into view before tapping.

```js
it('submits the form at the bottom of a long screen', async () => {
  await element(by.id('settings-scroll-view')).scrollTo('bottom');
  await element(by.id('save-button')).tap();
  await waitFor(element(by.id('success-toast')))
    .toBeVisible()
    .withTimeout(3000);
});
```

For dynamic lists where the element position is unknown, use `waitFor` + `whileElement` to scroll-until-found:

```js
it('finds a product deep in a FlatList', async () => {
  await waitFor(element(by.id('product-item-99')))
    .toBeVisible()
    .whileElement(by.id('product-list'))
    .scroll(100, 'down');
});
```

### Pattern 4 — waitFor for asynchronous UI changes

When an action triggers an async operation (network call, animation) and Detox's automatic sync does not cover it (e.g., a websocket update), use `waitFor` with an explicit timeout rather than a sleep.

```js
it('shows new message after websocket push', async () => {
  await waitFor(element(by.id('message-item-42')))
    .toBeVisible()
    .withTimeout(5000); // milliseconds
});

// Negative assertion: wait for spinner to disappear
it('hides loading spinner after data loads', async () => {
  await waitFor(element(by.id('loading-spinner')))
    .not.toBeVisible()
    .withTimeout(8000);
  await expect(element(by.id('data-list'))).toBeVisible();
});

// toHaveValue: assert TextInput current value
it('prefills email from stored profile', async () => {
  await expect(element(by.id('email-input'))).toHaveValue('saved@example.com');
});

// waitFor + toHaveValue: wait for an input value to be populated asynchronously
// (e.g., after an autofill or API pre-population)
it('waits for autocomplete to fill the city field', async () => {
  await element(by.id('zip-input')).replaceText('94103');
  await waitFor(element(by.id('city-input')))
    .toHaveValue('San Francisco')
    .withTimeout(5000);
});

// waitFor + toHaveLabel: wait for an element's accessibility label to update
// (e.g., a button that changes label after loading state resolves)
it('waits for submit button label to reflect ready state', async () => {
  await waitFor(element(by.id('submit-button')))
    .toHaveLabel('Submit Order')
    .withTimeout(5000);
  await element(by.id('submit-button')).tap();
});

// tapReturnKey: submit a form via keyboard without tapping a button
it('submits search by pressing return key', async () => {
  await element(by.id('search-input')).replaceText('react native');
  await element(by.id('search-input')).tapReturnKey();
  await waitFor(element(by.id('search-results')))
    .toBeVisible()
    .withTimeout(5000);
});

// waitFor + toExist: checks element is in React tree (even if off-screen)
// Useful for checking that a screen component mounted without requiring visibility
it('verifies payment confirmation is in the tree after API response', async () => {
  await element(by.id('pay-button')).tap();
  await waitFor(element(by.id('payment-confirmation')))
    .toExist()
    .withTimeout(8000);
});

// waitFor + not.toExist: checks element was unmounted (not just hidden)
it('verifies modal was fully unmounted after dismiss', async () => {
  await element(by.id('modal-close-button')).tap();
  await waitFor(element(by.id('onboarding-modal')))
    .not.toExist()
    .withTimeout(3000);
});
```

Do not shorten timeouts to make tests "feel fast" — if the operation legitimately takes 3 s in CI, allow 5–8 s.

### Pattern 5 — CI-aware timeout constants

CI runners are slower than developer machines. Define environment-aware timeout constants and use them everywhere instead of hard-coding milliseconds.

```js
// e2e/constants.js
const IS_CI = process.env.CI === 'true';

const TIMEOUT = {
  short:  IS_CI ? 5000  : 2000,
  medium: IS_CI ? 10000 : 3000,
  long:   IS_CI ? 20000 : 5000,
  launch: IS_CI ? 30000 : 10000,
};

module.exports = { TIMEOUT, IS_CI };
```

```js
// e2e/login.test.js
const { TIMEOUT } = require('./constants');

it('navigates to dashboard', async () => {
  await element(by.id('login-button')).tap();
  await waitFor(element(by.id('dashboard')))
    .toBeVisible()
    .withTimeout(TIMEOUT.long);
});
```

Recommended timeout budget by scenario:

| Scenario | Local | CI |
|---|---|---|
| Simple element visibility | 2000 ms | 5000 ms |
| API response visible | 3000 ms | 10000 ms |
| Screen navigation | 2000 ms | 5000 ms |
| App cold launch | 5000 ms | 15000 ms |
| Large list scroll-to-item | 3000 ms | 8000 ms |
| Push notification routing | 2000 ms | 5000 ms |

### Pattern 6 — Disabling animations on CI

Animations add non-deterministic timing. In the app entry point, disable them when running under Detox.

```js
// App.js / index.js
import { UIManager, Platform } from 'react-native';

if (global.__DEV__ || process.env.CI) {
  // Disable LayoutAnimation
  if (Platform.OS === 'android') {
    UIManager.setLayoutAnimationEnabledExperimental?.(false);
  }
}
```

In `.detoxrc.js`, set the `launchArgs` to pass a flag your app reads:

```js
module.exports = {
  configurations: {
    'ios.sim.ci': {
      device: { type: 'simulator', device: { type: 'iPhone 14' } },
      app: { type: 'ios.app', binaryPath: 'ios/build/...' },
      launchArgs: { detoxDisableAnimations: 'true' },
    },
  },
};
```

```js
// In RN app code — gate animation duration behind test flag
const DETOX_MODE = global.DETOX_MODE === '1';
const duration = DETOX_MODE ? 0 : 300;
Animated.timing(animValue, { toValue: 1, duration, useNativeDriver: true }).start();
```

### Pattern 7 — Separate CI configuration

Use a dedicated Detox configuration for CI that targets a specific, pinned simulator model and disables animations. Do not reuse the developer configuration on CI.

```js
// .detoxrc.js
module.exports = {
  testRunner: {
    args: { $0: 'jest', config: 'e2e/jest.config.js' },
    jest: { setupTimeout: 300000 },   // 5 minutes for cold-boot CI
  },
  apps: {
    'ios.debug': {
      type: 'ios.app',
      binaryPath: 'ios/build/Build/Products/Debug-iphonesimulator/MyApp.app',
      build: 'xcodebuild -workspace ios/MyApp.xcworkspace -scheme MyApp -configuration Debug -sdk iphonesimulator -derivedDataPath ios/build CODE_SIGNING_ALLOWED=NO | xcpretty',
    },
    'ios.release': {
      type: 'ios.app',
      binaryPath: 'ios/build/Build/Products/Release-iphonesimulator/MyApp.app',
      build: 'xcodebuild -workspace ios/MyApp.xcworkspace -scheme MyApp -configuration Release -sdk iphonesimulator -derivedDataPath ios/build CODE_SIGNING_ALLOWED=NO | xcpretty',
    },
  },
  devices: {
    simulator: {
      type: 'ios.simulator',
      device: { type: 'iPhone 14', os: 'iOS 17.0' }, // pin exact version
    },
    emulator: {
      type: 'android.emulator',
      device: { avd: 'Pixel_4_API_30' },
    },
  },
  configurations: {
    'ios.sim.debug': { device: 'simulator', app: 'ios.debug' },
    'ios.sim.release': { device: 'simulator', app: 'ios.release' }, // use for CI
    'android.emu.debug': { device: 'emulator', app: 'android.debug' },
  },
  artifacts: {
    rootDir: '.artifacts',
    plugins: {
      screenshot: { shouldTakeAutomaticSnapshots: true, takeWhen: { testFailure: true } },
      video: { enabled: false },
      log: { enabled: true },
      timeline: { enabled: true },
    },
  },
};
```

### Pattern 8 — Retry flaky tests at the runner level (last resort)

If a test fails intermittently due to reasons outside your control (simulator instability, GPU unavailability in headless CI), configure Jest retries — but treat this as a temporary bandage, not a fix.

```js
// e2e/jest.config.js — canonical Detox+Jest configuration
module.exports = {
  rootDir: '..',
  testMatch: ['<rootDir>/e2e/**/*.test.js'],
  testTimeout: 120000,
  retryTimes: process.env.CI ? 1 : 0,  // retry each failing test once on CI
  verbose: true,
  // REQUIRED: wires Detox global lifecycle to Jest
  globalSetup: 'detox/runners/jest/globalSetup',
  globalTeardown: 'detox/runners/jest/globalTeardown',
  // REQUIRED: provides element, by, waitFor, expect, device as globals
  testEnvironment: 'detox/runners/jest/testEnvironment',
  reporters: ['detox/runners/jest/reporter'],
};
```

### Pattern 9 — App permissions in launchApp [community]

Simulator permission dialogs during tests are a leading cause of CI failures. Native permission prompts appear asynchronously and Detox's synchronization engine does not know how to wait for them — the dialog freezes the test while the tap action fires into empty space.

Grant all required permissions upfront in `launchApp` so they are never prompted during the run:

```js
// e2e/setup.js
beforeAll(async () => {
  await device.launchApp({
    newInstance: true,
    permissions: {
      notifications: 'YES',
      camera: 'YES',
      photos: 'YES',
      location: 'inuse',
      microphone: 'YES',
    },
    launchArgs: {
      DETOX_MODE: '1',
      API_BASE_URL: process.env.API_BASE_URL || 'http://localhost:8088',
    },
  });
  await device.setURLBlacklist([
    '.*firebaselogging.*',
    '.*amplitude.*',
    '.*sentry.*',
    '.*analytics.*',
  ]);
});
```

On Android, additional permissions must be granted via ADB or handled through Detox's `grantPermissions` before the app launches.

### Pattern 10 — Suppress third-party SDK timers with setURLBlacklist [community]

Analytics SDKs (Firebase Analytics, Amplitude, Segment, Sentry) fire background network requests that Detox's idle detector counts as "app busy". The test sits waiting, times out, and fails — even though the feature under test completed successfully.

```js
// In beforeAll or a global setup file
beforeAll(async () => {
  await device.launchApp({ newInstance: true });
  // Suppress analytics/crash-reporting beacons so they don't block idle detection
  await device.setURLBlacklist([
    '.*firebaselogging.*',
    '.*amplitude.*',
    '.*sentry\\.io.*',
    '.*crashlytics.*',
    '.*analytics.*',
  ]);
});
```

This is one of the most impactful fixes for tests that pass locally but time out on CI.

### Pattern 11 — Network mocking with a local mock server

Real network calls during e2e tests cause flakiness: rate limits, auth token expiry, variable latency, or CI network blocks. The recommended approach is a local mock server started in `globalSetup`:

```js
// e2e/globalSetup.js
const { startMockServer } = require('./mock-server');

module.exports = async () => {
  global.mockServer = await startMockServer(8088);
};

// e2e/globalTeardown.js
module.exports = async () => {
  await global.mockServer.close();
};
```

```js
// .detoxrc.js apps section
apps: {
  'ios.debug': {
    type: 'ios.app',
    binaryPath: '...',
    launchArgs: {
      API_BASE_URL: 'http://localhost:8088',
      E2E_USER_EMAIL: process.env.E2E_USER_EMAIL || 'test@example.com',
    },
  },
},
```

```js
// e2e/jest.config.js — wire up global setup/teardown
module.exports = {
  globalSetup: 'detox/runners/jest/globalSetup',
  globalTeardown: 'detox/runners/jest/globalTeardown',
  testEnvironment: 'detox/runners/jest/testEnvironment',
  testTimeout: 120000,
};
```

### Pattern 12 — Artifact collection for CI debugging

Detox can save screenshots, video recordings, and logs on failure. Without artifacts, debugging CI failures is guesswork. Enable artifact collection in the Detox config and attach them to your CI job:

```js
// .detoxrc.js — artifacts block (merged with Pattern 7 full config)
artifacts: {
  rootDir: '.artifacts',
  plugins: {
    screenshot: {
      enabled: true,
      shouldTakeAutomaticSnapshots: true,
      takeWhen: { testStart: false, testDone: false, testFailure: true },
    },
    video: {
      enabled: process.env.CI === 'true',
      keepOnlyFailedTestsArtifacts: true,
    },
    log: { enabled: true },
    timeline: { enabled: true },
  },
},
```

```yaml
# GitHub Actions — upload artifacts on failure
- name: Run Detox tests
  run: npx detox test -c ios.sim.release --artifacts-location .artifacts

- name: Upload test artifacts
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: detox-artifacts
    path: .artifacts/
    retention-days: 7
```

```js
// Manual screenshot inside a test
it('verifies dashboard layout', async () => {
  await element(by.id('dashboard')).tap();
  await device.takeScreenshot('dashboard-state');
  await expect(element(by.id('welcome-banner'))).toBeVisible();
});
```

### Pattern 13 — disableSynchronization in a narrow scope [community]

`device.disableSynchronization()` is a global kill switch. When teams apply it test-file-wide (or worse, globally), Detox loses its main advantage and every interaction that previously "just worked" needs an explicit `waitFor`. The correct pattern is the narrowest possible scope — wrap only the code that triggers the problematic SDK behavior:

```js
it('plays video without Detox sync fighting the media player', async () => {
  await element(by.id('play-button')).tap();

  // Narrow disable: media player timers confuse Detox idle detection
  await device.disableSynchronization();
  try {
    await waitFor(element(by.id('video-progress-bar')))
      .toBeVisible()
      .withTimeout(10000);
  } finally {
    // Always re-enable — even if the assertion throws
    await device.enableSynchronization();
  }

  // Sync re-enabled — subsequent interactions are deterministic again
  await element(by.id('pause-button')).tap();
  await expect(element(by.id('play-button'))).toBeVisible();
});
```

### Pattern 14 — Parallel test execution with worker shards [community]

Detox supports running test files across multiple simulator instances in parallel. The key constraint is that each worker must get its own device instance — sharing a device between workers causes race conditions that look like random element-not-found failures.

```js
// e2e/jest.config.js
module.exports = {
  rootDir: '..',
  testMatch: ['<rootDir>/e2e/**/*.test.js'],
  testTimeout: 120000,
  maxWorkers: process.env.CI ? 1 : 2,  // single worker on CI; use matrix sharding instead
  retryTimes: process.env.CI ? 1 : 0,
};
```

```yaml
# GitHub Actions — matrix strategy for CI parallelism (preferred over maxWorkers)
strategy:
  matrix:
    shard: [1, 2, 3]
steps:
  - name: Run Detox shard
    run: |
      npx detox test -c ios.sim.release \
        --shard-index ${{ matrix.shard }} \
        --shard-count 3
```

Warning: on macOS CI runners, booting more than 2–3 simulators simultaneously often causes boot failures. Start with 2 workers and increase only after verifying stability.

### Pattern 15 — Deep link and URL testing

Detox can launch the app with a URL to test deep-link routing without navigating through the UI:

```js
it('opens product screen from deep link', async () => {
  await device.launchApp({
    newInstance: true,
    url: 'myapp://products/42',
    permissions: { notifications: 'YES' },
  });
  await waitFor(element(by.id('product-screen-42')))
    .toBeVisible()
    .withTimeout(5000);
  await expect(element(by.id('product-title'))).toHaveText('Awesome Product');
});

it('handles invalid deep link gracefully', async () => {
  await device.launchApp({
    newInstance: true,
    url: 'myapp://products/INVALID',
  });
  await waitFor(element(by.id('not-found-screen')))
    .toBeVisible()
    .withTimeout(5000);
});
```

### Pattern 16 — Compound matchers and ancestor/descendant scoping

When multiple elements share a testID pattern (e.g., in a list), use `withAncestor`, `withDescendant`, or `.and()` to narrow scope:

```js
// Narrow tap target to a specific row by ancestor
await element(by.text('Delete').withAncestor(by.id('row-42'))).tap();

// Compose matchers with .and()
await element(by.id('list-item').and(by.type('RCTView'))).atIndex(2).tap();

// Descendant: verify a child element exists within a container
await expect(
  element(by.id('checkout-form').withDescendant(by.id('pay-button')))
).toBeVisible();

// Unique list item testIDs — preferred over atIndex
await element(by.id(`todo-item-${item.id}`)).tap();
```

### Pattern 17 — Authentication state helper [community]

Auth flows are the most common "test infrastructure" concern. Extract login into a reusable helper and always clear the input fields first — simulators may retain field contents from previous tests.

```js
// e2e/helpers/loginAs.js
const { TIMEOUT } = require('../constants');

const USERS = {
  admin: { email: process.env.E2E_ADMIN_EMAIL || 'admin@test.com', password: process.env.E2E_ADMIN_PASS || 'admin123' },
  user:  { email: process.env.E2E_USER_EMAIL  || 'user@test.com',  password: process.env.E2E_USER_PASS  || 'user123' },
};

async function loginAs(role = 'user') {
  const { email, password } = USERS[role];
  await element(by.id('email-input')).tap();
  await element(by.id('email-input')).clearText();
  await element(by.id('email-input')).typeText(email);
  await element(by.id('password-input')).clearText();
  await element(by.id('password-input')).typeText(password);
  await element(by.id('login-button')).tap();
  await waitFor(element(by.id('home-screen')))
    .toBeVisible()
    .withTimeout(TIMEOUT.long);
}

module.exports = { loginAs };
```

### Pattern 18 — Platform-conditional test logic

When a feature behaves differently on iOS vs. Android, use `device.getPlatform()` for conditional blocks rather than duplicating entire test files:

```js
// e2e/biometrics.test.js
describe('Biometric authentication', () => {
  it('shows Face ID prompt on iOS or fingerprint on Android', async () => {
    await element(by.id('enable-biometrics-button')).tap();

    if (device.getPlatform() === 'ios') {
      await waitFor(element(by.id('face-id-prompt')))
        .toBeVisible()
        .withTimeout(3000);
      await expect(element(by.id('face-id-prompt'))).toBeVisible();
    } else {
      await waitFor(element(by.id('fingerprint-prompt')))
        .toBeVisible()
        .withTimeout(3000);
      await expect(element(by.id('fingerprint-prompt'))).toBeVisible();
    }
  });

  it('skips biometric-only scenarios on Android', async () => {
    if (device.getPlatform() !== 'ios') {
      return; // explicitly skip — better than xdescribe which hides intent
    }
    await element(by.id('use-face-id-button')).tap();
    await waitFor(element(by.id('biometric-success'))).toBeVisible().withTimeout(5000);
  });
});
```

### Pattern 19 — Push notification and system event testing

Detox can simulate push notifications and user notifications without a real APNS server,
making it possible to test notification-triggered navigation flows:

```js
// e2e/notifications.test.js
describe('Push notifications', () => {
  beforeAll(async () => {
    await device.launchApp({
      newInstance: true,
      permissions: { notifications: 'YES' },
    });
  });

  beforeEach(async () => {
    await device.reloadReactNative();
  });

  it('navigates to chat screen when a message notification is tapped', async () => {
    // Simulate a background notification tap (app was in background)
    await device.sendUserNotification({
      trigger: { type: 'push' },
      title: 'New message from Alice',
      body: 'Hey, are you coming tonight?',
      payload: {
        screenId: 'chat-screen',
        conversationId: 'conv-99',
      },
    });
    await waitFor(element(by.id('chat-screen-conv-99')))
      .toBeVisible()
      .withTimeout(5000);
  });

  it('shows in-app banner when notification arrives in foreground', async () => {
    // App is in foreground — notification banner should appear
    await device.sendUserNotification({
      trigger: { type: 'push' },
      title: 'Promo available',
      body: 'Limited time offer',
    });
    await waitFor(element(by.id('in-app-notification-banner')))
      .toBeVisible()
      .withTimeout(3000);
    await element(by.id('notification-dismiss-button')).tap();
    await waitFor(element(by.id('in-app-notification-banner')))
      .not.toBeVisible()
      .withTimeout(2000);
  });
});
```

### Pattern 20 — element.getAttributes() for reading element state

`element.getAttributes()` returns a snapshot of an element's native properties — its
`text`, `value`, `enabled`, `visible`, `frame`, `identifier`, `label`, and more. Use it
when you need to make a conditional assertion based on the current state of an element,
or when asserting exact pixel-level geometry in visual regression tests.

```js
it('reads the current value of a slider', async () => {
  const attrs = await element(by.id('volume-slider')).getAttributes();
  // attrs.value is the current slider percentage as a string (e.g., "0.75")
  expect(parseFloat(attrs.value)).toBeGreaterThan(0);
});

it('verifies a button is both visible and enabled before tapping', async () => {
  const attrs = await element(by.id('submit-button')).getAttributes();
  expect(attrs.visible).toBe(true);
  expect(attrs.enabled).toBe(true);
  await element(by.id('submit-button')).tap();
});

it('asserts approximate element position for layout regression', async () => {
  const attrs = await element(by.id('floating-action-button')).getAttributes();
  // frame is { x, y, width, height } in points
  expect(attrs.frame.y).toBeGreaterThan(400); // FAB should be in the bottom half
});

// Multi-element: returns { elements: [...] } when multiple match
it('counts badge counts across notification list items', async () => {
  const multiAttrs = await element(by.id('notification-badge')).getAttributes();
  // When multiple elements match, Detox returns { elements: [attrs, attrs, ...] }
  const badges = multiAttrs.elements ?? [multiAttrs];
  const counts = badges.map(el => parseInt(el.text || '0', 10));
  expect(counts.every(c => c >= 0)).toBe(true);
});
```

**API note:** `getAttributes()` is read-only and does not interact with the element, so it
never triggers Detox's idle detection. Safe to call in rapid succession.

### Pattern 21 — Biometrics simulation (iOS only)

Detox can simulate Face ID / Touch ID match or failure for biometric-gated flows on the
iOS Simulator. This allows testing login, payment confirmation, and unlock screens without
a real biometric sensor.

```js
// e2e/biometrics-simulation.test.js
describe('Biometric login', () => {
  beforeAll(async () => {
    await device.launchApp({
      newInstance: true,
      permissions: { faceid: 'YES' },  // grant Face ID permission at launch
    });
  });

  beforeEach(async () => {
    await device.reloadReactNative();
    // Enroll Face ID in the simulator so the app can request it
    await device.setBiometricEnrollment(true);
  });

  it('logs in via Face ID when biometrics match', async () => {
    await element(by.id('use-face-id-button')).tap();
    // Simulate a successful Face ID match
    await device.matchFace();
    await waitFor(element(by.id('home-screen')))
      .toBeVisible()
      .withTimeout(5000);
  });

  it('shows fallback password screen when Face ID fails', async () => {
    await element(by.id('use-face-id-button')).tap();
    // Simulate a biometric mismatch
    await device.unmatchFace();
    await waitFor(element(by.id('fallback-password-screen')))
      .toBeVisible()
      .withTimeout(3000);
  });

  it('handles biometric lockout after multiple failures', async () => {
    await element(by.id('use-face-id-button')).tap();
    await device.unmatchFace();
    await device.unmatchFace();
    await device.unmatchFace();
    // After 3 failures iOS locks biometrics — app should show device passcode prompt
    await waitFor(element(by.id('passcode-screen')))
      .toBeVisible()
      .withTimeout(5000);
  });

  afterAll(async () => {
    // Unenroll to avoid affecting other test suites
    await device.setBiometricEnrollment(false);
  });
});
```

**Android equivalent:** Use `device.matchFinger()` / `device.unmatchFinger()` for
fingerprint simulation on Android emulators that support biometric simulation.

### Pattern 22 — iOS accessibility traits with by.traits()

`by.traits()` targets elements by their iOS accessibility traits. Use it when an element
has no `testID` and you want a more stable selector than visible text, especially for
system-provided controls like navigation bar buttons or toolbar icons.

```js
// Target iOS-native controls by trait
// Common traits: 'button', 'link', 'image', 'text', 'header', 'selected',
//                'plays-sound', 'key-board-key', 'summary', 'not-enabled',
//                'updates-frequently', 'search-field', 'starts-media', 'adjustable'

it('taps the back button identified by navigation trait', async () => {
  // Narrow by label + trait to avoid ambiguity
  await element(by.label('Back').and(by.traits(['button']))).tap();
  await waitFor(element(by.id('previous-screen')))
    .toBeVisible()
    .withTimeout(3000);
});

it('finds the search field by trait', async () => {
  await element(by.traits(['search-field'])).tap();
  await element(by.traits(['search-field'])).typeText('react native');
  await waitFor(element(by.id('search-results')))
    .toBeVisible()
    .withTimeout(5000);
});
```

**Note:** `by.traits()` is iOS-only. On Android, use `by.type('android.widget.ImageButton')`
or add `testID` props. Always prefer `by.id()` when `testID` can be added.

### Pattern 23 — Orientation and device rotation testing

Test landscape layout and orientation-change behavior with `device.setOrientation()`:

```js
// e2e/orientation.test.js
describe('Orientation tests', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  afterEach(async () => {
    // Always reset to portrait after each test to avoid contaminating subsequent tests
    await device.setOrientation('portrait');
  });

  it('renders the video player in landscape with full-screen controls', async () => {
    await element(by.id('video-play-button')).tap();
    await waitFor(element(by.id('video-player'))).toBeVisible().withTimeout(3000);

    await device.setOrientation('landscape');

    await waitFor(element(by.id('fullscreen-controls')))
      .toBeVisible()
      .withTimeout(3000);
    await expect(element(by.id('fullscreen-exit-button'))).toBeVisible();
  });

  it('reflows the form layout correctly in landscape', async () => {
    await element(by.id('contact-form-tab')).tap();
    await device.setOrientation('landscape');

    // In landscape, two-column layout should show both panels simultaneously
    await expect(element(by.id('form-left-panel'))).toBeVisible();
    await expect(element(by.id('form-right-panel'))).toBeVisible();
  });

  it('persists form input across rotation', async () => {
    await element(by.id('email-input')).replaceText('keep@example.com');
    await device.setOrientation('landscape');
    // After rotation, the input value must be preserved
    await expect(element(by.id('email-input'))).toHaveValue('keep@example.com');
    await device.setOrientation('portrait');
    await expect(element(by.id('email-input'))).toHaveValue('keep@example.com');
  });
});
```

**Android note:** Android may re-create the Activity on rotation. If your app does not
handle `onSaveInstanceState`/`onRestoreInstanceState` correctly, the test will find a
blank screen after rotation. This is a valid test finding — file it as an app bug.

### Pattern 24 — Interacting with iOS system dialogs via by.system() [community]

Pre-granting permissions in `launchApp` is always preferred (Pattern 9). But in some app
flows (e.g., runtime permission requests triggered mid-test by a third-party SDK) the
system dialog still appears. `by.system()` lets you tap buttons in iOS system dialogs that
live outside your app's view hierarchy.

```js
// e2e/location-permission.test.js
// Use ONLY when pre-granting in launchApp is not possible
// by.system() targets iOS system-level elements — NOT available on Android

it('grants location permission via system dialog at runtime', async () => {
  // Trigger the permission dialog by using the feature that requests it
  await element(by.id('use-my-location-button')).tap();

  // The iOS system dialog is outside the app hierarchy — use by.system() to reach it
  // system.label() matches the button label shown in the system dialog
  await waitFor(element(by.system().label('Allow While Using App')))
    .toBeVisible()
    .withTimeout(5000);
  await element(by.system().label('Allow While Using App')).tap();

  // Back in the app — verify the feature proceeded
  await waitFor(element(by.id('location-map')))
    .toBeVisible()
    .withTimeout(5000);
});

it('denies location permission and verifies fallback message', async () => {
  await element(by.id('use-my-location-button')).tap();
  await waitFor(element(by.system().label("Don't Allow")))
    .toBeVisible()
    .withTimeout(5000);
  await element(by.system().label("Don't Allow")).tap();
  await waitFor(element(by.id('location-denied-banner')))
    .toBeVisible()
    .withTimeout(3000);
});
```

**When to use `by.system()` vs `permissions` in `launchApp`:**
- `launchApp({ permissions: { location: 'inuse' } })` — preferred; grants permission before the app starts, no dialog ever appears
- `by.system()` — use only when the dialog is triggered mid-test by third-party code you don't fully control

**Android equivalent:** Android uses `UiAutomator2` to tap system dialogs. Detox on Android
exposes this through `by.system()` as well (Detox 20+), but dialog button labels differ
across Android API levels. Always pre-grant on Android when possible.

### Pattern 25 — Advanced gestures: slider, long-press-drag, coordinate tap

Detox provides several interaction APIs beyond `tap()` and `typeText()`. These are
needed for rich native controls (sliders, drag-and-drop, canvas interactions).

```js
// e2e/gestures.test.js

it('adjusts a volume slider to 75%', async () => {
  // adjustSliderToPosition: 0.0 = minimum, 1.0 = maximum
  // Only works on native <Slider> components with testID set
  await element(by.id('volume-slider')).adjustSliderToPosition(0.75);

  // Verify the new value via getAttributes
  const attrs = await element(by.id('volume-slider')).getAttributes();
  expect(parseFloat(attrs.value)).toBeCloseTo(0.75, 1);
});

it('long-presses a list item to open the context menu', async () => {
  await element(by.id('message-item-7')).longPress();
  await waitFor(element(by.id('context-menu')))
    .toBeVisible()
    .withTimeout(3000);
  await element(by.id('context-menu-delete')).tap();
});

it('drags a card from one column to another (Kanban board)', async () => {
  // longPressAndDrag: (duration, normalizedPositionX, normalizedPositionY,
  //                    targetElement, targetNormalizedPositionX, targetNormalizedPositionY,
  //                    speed, holdDuration)
  await element(by.id('card-42')).longPressAndDrag(
    500,             // long press duration (ms) before drag starts
    0.5, 0.5,        // drag start position within element (center)
    element(by.id('column-done')),  // target element
    0.5, 0.5,        // drop position within target (center)
    'fast',          // drag speed: 'fast' | 'slow'
    0                // hold duration at destination (ms)
  );
  await waitFor(element(by.id('card-42')))
    .toBeVisible()
    .withTimeout(3000);
  // Verify the card is now in the "Done" column
  await expect(
    element(by.id('card-42').withAncestor(by.id('column-done')))
  ).toBeVisible();
});

it('taps at a specific coordinate within an element', async () => {
  // tapAtPoint: useful for canvas elements, map pins, or custom gesture areas
  // x, y are pixel offsets from the element's top-left corner
  await element(by.id('map-view')).tapAtPoint({ x: 120, y: 80 });
  await waitFor(element(by.id('map-pin-popup')))
    .toBeVisible()
    .withTimeout(3000);
});

it('double-taps to zoom in on a photo', async () => {
  // multiTap(taps): send N rapid taps to the element
  // Use for double-tap zoom, double-tap-to-like patterns
  await element(by.id('photo-view')).multiTap(2);
  await waitFor(element(by.id('photo-zoomed-indicator')))
    .toBeVisible()
    .withTimeout(2000);
});

it('triple-taps to select all text in a field', async () => {
  await element(by.id('article-text-view')).multiTap(3);
  // After triple-tap, text should be selected — verify via getAttributes
  const attrs = await element(by.id('article-text-view')).getAttributes();
  // selectedText is platform-specific; verify copy menu appears instead
  await waitFor(element(by.traits(['button'])).withAncestor(by.id('selection-menu')))
    .toBeVisible()
    .withTimeout(2000);
});
```

**When to use each:**
- `adjustSliderToPosition(0–1)` — native Slider components only; not for custom JS sliders
- `longPress()` — context menus, peek/pop, selection modes
- `longPressAndDrag()` — drag-and-drop, reordering lists, Kanban board moves
- `tapAtPoint({ x, y })` — map interactions, canvas elements, custom gesture responders

### Pattern 26 — View hierarchy capture for debugging element-not-found failures [community]

When `element(by.id(...))` fails with "No elements found" and the element is visually
present, `device.captureViewHierarchy()` dumps the full native accessibility tree to a
file. This reveals the actual `testID`, `accessibilityLabel`, and `type` values that
Detox sees — which may differ from what you specified in React Native.

```js
// e2e/debug-hierarchy.test.js
// NOTE: captureViewHierarchy is a debugging utility — remove from production tests

it('captures view hierarchy when debugging selector failures', async () => {
  await element(by.id('settings-screen')).tap();

  // Dumps the native view hierarchy to .artifacts/hierarchy-<name>.viewhierarchy
  // Open with Xcode → Debug → View Hierarchy (File → Open the .viewhierarchy file)
  await device.captureViewHierarchy('settings-screen-state');

  // After inspecting the dump, replace with the correct selector:
  await expect(element(by.id('settings-screen'))).toBeVisible();
});
```

```js
// Practical workflow for a "No elements found" failure:
// 1. Add captureViewHierarchy() BEFORE the failing line
// 2. Run the test once — it will still fail but save the hierarchy file
// 3. Open .artifacts/<test-name>/*.viewhierarchy in Xcode
// 4. Find the element, read its actual identifier/label/type
// 5. Update your selector, remove the captureViewHierarchy call

// Common discovery: React Native's <Text> inside a <Pressable> sometimes bridges
// to native as RCTTextView instead of RCTButton — requiring by.type('RCTTextView')
// instead of by.type('RCTButton') to match it.
```

**Android equivalent:** On Android, use `adb shell uiautomator dump /sdcard/window_dump.xml && adb pull /sdcard/window_dump.xml` to get the UiAutomator view hierarchy. Detox does not yet expose a direct API for this on Android.

---


## Selector / Locator Strategy

Ranked from most stable to most fragile:

| Rank | Selector | API | Notes |
|------|----------|-----|-------|
| 1 | `testID` prop | `by.id('testID')` | Best — survives refactors, localization, style changes |
| 2 | Accessibility label | `by.label('Submit')` | Good — doubles as a11y; survives layout changes |
| 3 | Accessibility value | `by.value('75%')` | Good for sliders/progress indicators — matches accessibilityValue |
| 4 | Accessibility type | `by.type('RCTTextInput')` | OK — use to narrow when testID is absent |
| 5 | Visible text | `by.text('Log in')` | Fragile — breaks on copy changes and i18n |
| 6 | XPath / CSS | n/a (not supported) | Not supported in Detox — do not attempt |
| 7 | System elements | `by.system()` | iOS only — target system-level elements (permission dialogs, alerts) not in your app's view hierarchy |
| 8 | Web elements | `by.web.id()`, `by.web.cssSelector()` | Inside a `<WebView>` — use `web(element(by.id('webview-id')))` scope |

**Rule**: Add `testID` to every button, input, screen root, and list item that a test will touch. Coordinate with app developers to add them proactively.

**Compound matchers for lists**: When multiple elements share a `testID` pattern (e.g., list items), use `.atIndex(n)` or compose matchers:

```js
// List items with indexed testIDs
await element(by.id('todo-item-0')).tap();

// OR: narrow by type when testID is shared
await element(by.id('list-item').and(by.type('RCTView'))).atIndex(2).tap();

// OR: narrow by ancestor container
await element(by.text('Delete').withAncestor(by.id('row-42'))).tap();
```

**by.value() example** — match an element by its `accessibilityValue`:

```js
// Useful when testID is absent: a progress indicator whose value is set via accessibilityValue
// e.g., in RN: <View accessibilityValue={{ text: '75%' }} accessible>
await element(by.value('75%')).tap();

// Combine with by.type() to narrow ambiguous matches
await element(by.type('RCTSlider').and(by.value('0.5'))).adjustSliderToPosition(0.75);
```

**Swipe gesture examples** — used for carousels, pull-to-refresh, and swipe-to-dismiss:

```js
// Swipe left on a carousel card
await element(by.id('image-carousel')).swipe('left', 'fast', 0.8);

// Pull-to-refresh: swipe down on a ScrollView
await element(by.id('news-feed-scroll')).swipe('down', 'slow', 0.5);

// Swipe left on a list item to reveal delete action (iOS mail-style)
// Use 'slow' speed and high normalizedOffset to ensure the action sheet opens
await element(by.id('message-row-5')).swipe('left', 'slow', 0.9);
await waitFor(element(by.id('swipe-delete-button')))
  .toBeVisible()
  .withTimeout(2000);
await element(by.id('swipe-delete-button')).tap();

// Dismiss a bottom sheet by swiping down
await element(by.id('bottom-sheet-handle')).swipe('down', 'fast');
await waitFor(element(by.id('bottom-sheet')))
  .not.toBeVisible()
  .withTimeout(3000);
```



## Real-World Gotchas [community]

These pitfalls come from production usage, GitHub Discussions, engineering blogs, and React Native community reports — not the official documentation.

### 1. The "passes locally, fails on CI" class of failures [community]

**Root cause**: Slow CI hardware means idle detection takes longer, and background timers from analytics SDKs (Firebase, Amplitude) fire *while* Detox is waiting for the app to idle. Detox sees pending network activity and keeps waiting until `waitFor` times out. On a fast dev machine the SDK calls complete in <100ms and are never noticed.

**Fix**: Use `device.setURLBlacklist()` at test setup to blacklist analytics endpoints. Combine with pinning the simulator to a specific model (slower simulators = more exposure to this).

### 2. Simulator "re-use" between test runs causes state contamination [community]

**Root cause**: When `device.launchApp()` is called without `newInstance: true`, Detox re-attaches to an already-running simulator. If a previous test crashed the app mid-state (e.g., corrupt AsyncStorage, partially written Keychain entry), the next run inherits that corruption.

**Fix**: Use `newInstance: true` in `beforeAll` for any suite that touches persistent storage. Accept the 3–5 second cold-boot overhead; it eliminates an entire class of phantom failures. For tests that need a completely clean install, use `delete: true`.

### 3. atIndex(0) hiding non-unique testID bugs [community]

**Root cause**: When duplicate `testID` values appear in a list (e.g., every list item has `testID="list-row"` instead of `testID="list-row-{id}"`), using `.atIndex(0)` silently masks the problem. Tests pass, but you're always testing only the first element and never discovering that tap targets are wrong on subsequent items.

**Fix**: Make list-item testIDs unique: `testID={\`todo-item-${item.id}\`}`. Reserve `.atIndex()` for true compound scenarios (e.g., two buttons with the same label in different panels), not for working around duplicate IDs.

### 4. `reloadReactNative()` does not reset native modules [community]

**Root cause**: Many teams switch from `newInstance: true` to `reloadReactNative()` in `beforeEach` to speed up their suite. But `reloadReactNative()` only resets the JS bundle — it does NOT reset AsyncStorage, Keychain, SQLite, or native module state. Tests that write to these stores in one run pollute the next.

**Fix**: Explicitly clear storage in `beforeEach` at the JS level, or use `newInstance: true` for any suite that persists data. Use `reloadReactNative()` only for pure-UI test suites with no storage writes.

### 5. Hard-coded simulator type causes boot failures on cloud CI [community]

**Root cause**: CI configurations that specify `device: { type: 'iPhone 14' }` fail on runners where only iPhone 15 or iPhone SE is available. iOS simulators on cloud CI (GitHub Actions, Bitrise, CircleCI) update their Xcode images on a different schedule than your local machine.

**Fix**: Prefer using the OS version as the constraint, not the device model, or fetch available simulators dynamically in a CI pre-step:

```bash
xcrun simctl list devices available | grep 'iPhone'
```

Or update the pinned device when the Xcode image updates:

```js
// .detoxrc.js — prefer version-based or runtime-based targeting
configurations: {
  'ios.sim.ci': {
    device: {
      type: 'simulator',
      device: { type: 'iPhone 15' },   // update when Xcode image updates
    },
  },
},
```

### 6. Detox sync blocked by infinite animation (Lottie, looped indicators) [community]

**Root cause**: Lottie animations that loop indefinitely (e.g., a loading spinner on a screen) keep a native animation frame scheduled at all times. Detox's idle detector sees "animation running" and never considers the app idle. The test hangs until it times out — even when the actual UI the test needs is fully rendered.

**Fix**: Gate looping animations behind an `isTestEnvironment` flag:

```js
const isTest = typeof detox !== 'undefined' || !!process.env.DETOX_DISABLE_ANIMATIONS;
// In your component
{isTest ? <View style={styles.staticPlaceholder} /> : <LottieView source={animation} loop />}
```

### 7. waitFor polling interval creates phantom races on navigation [community]

**Root cause**: `waitFor().toBeVisible().withTimeout(5000)` polls every ~100ms. If a navigation transition briefly shows AND hides the target element, `waitFor` can resolve on the intermediate state and the test proceeds as if navigation succeeded when it actually failed.

**Fix**: Assert both the destination element AND the absence of the source element, or add a `toHaveText()` assertion immediately after `toBeVisible()` to confirm the correct screen:

```js
await waitFor(element(by.id('home-screen'))).toBeVisible().withTimeout(5000);
// Confirm we're on the real home screen, not a transition ghost
await expect(element(by.id('home-welcome-text'))).toBeVisible();
```

### 8. Missing `clearText()` before `typeText()` causes concatenated input [community]

**Root cause**: On simulators, TextInput fields sometimes retain content from the previous test or navigation event. Calling `typeText('new@email.com')` appends to the existing value rather than replacing it — the final field reads `old@email.comnew@email.com`.

**Fix**: Always call `clearText()` before `typeText()`, or use `replaceText()` which combines the two in a single call:

```js
// Safe pattern
await element(by.id('email-input')).tap();
await element(by.id('email-input')).clearText();
await element(by.id('email-input')).typeText('user@example.com');

// Alternatively
await element(by.id('email-input')).replaceText('user@example.com');
```

### 9. Binary staleness: cached build runs old code against new tests [community]

**Root cause**: CI caches the compiled app binary to save build time. If the cache key does not include the app source files, a code change won't invalidate the cached binary, and the new tests run against the old build. The tests fail or produce wrong results for reasons that are impossible to reproduce locally.

**Fix**: Include a hash of the relevant source files in the cache key:

```yaml
- name: Cache iOS build
  uses: actions/cache@v3
  with:
    path: ios/build
    key: ios-build-${{ hashFiles('ios/**', 'src/**', 'package.json') }}
```

### 10. `setInterval`/persistent timers block Detox idle detection [community]

**Root cause**: Detox considers the app "idle" only when all timers with delay < 1500 ms have resolved, all network requests are done, and all animations have stopped. A `setInterval` polling loop (e.g., for real-time data) that fires every 3–5 seconds keeps the app perpetually "busy" in Detox's view, so `waitFor` never resolves.

**Fix**: Disable polling in test mode via a `launchArg`:

```js
// In test setup
await device.launchApp({
  newInstance: true,
  launchArgs: { detoxDisablePolling: '1' },
});

// In RN app
if (global.DETOX_DISABLE_POLLING === '1') {
  // skip polling loop
}
```

### 11. Hermes debugger attachment slows down test execution on debug builds [community]

**Root cause**: When running Detox tests against a Debug build (not Release), the Hermes JS engine waits for a remote debugger to attach at startup. This adds 2–5 seconds to every cold boot. Teams using Debug builds for CI to get better error messages are unknowingly penalizing every test's `setupTimeout`. On CI machines where the debugger port (8081) is also occupied by a Metro bundler from a previous job, the app can hang indefinitely.

**Fix**: Use Release builds for CI Detox runs (`ios.sim.release` config). If you must use Debug for stack traces, explicitly set the Metro bundler port in the Detox config and kill stale Metro processes before the run:

```bash
# CI pipeline pre-step: kill any stale Metro on port 8081
lsof -ti:8081 | xargs kill -9 2>/dev/null || true
```

```js
// .detoxrc.js — specify custom Metro port to avoid conflicts in parallel jobs
testRunner: {
  args: {
    $0: 'jest',
    config: 'e2e/jest.config.js',
  },
},
// app build command: add RCT_METRO_PORT env var
```

### 12. Android emulator lock screen blocks all interactions [community]

**Root cause**: On freshly booted Android emulators, the device lock screen appears. Detox's `element()` calls find no matching elements because the lock screen is on top of the app — resulting in cryptic "element not found" failures on the very first test action.

**Fix**: Disable the lock screen in the emulator before running tests:

```bash
# Unlock the emulator via ADB before running Detox
adb shell input keyevent 82    # KEYCODE_MENU — wakes screen
adb shell input keyevent 3     # KEYCODE_HOME  — ensures on home
adb shell wm dismiss-keyguard  # API 23+ — programmatic unlock
```

Or configure the AVD to never lock by setting the screen timeout to the maximum value in
the emulator settings, or via:

```bash
adb shell settings put secure lockscreen.disabled 1
```

Include this as a CI pre-test step before `npx detox test`.

### 13. Keyboard obscures the target element on small Android screens [community]

**Root cause**: When a `TextInput` is focused, the software keyboard appears and pushes
the layout up. On small emulator screens (Pixel 3a XL or smaller), the next form field
or submit button may scroll off screen. Detox taps an element based on its pre-keyboard
coordinates, missing the shifted position — the tap lands on empty space.

**Fix**: Scroll the view to ensure the target element is above the keyboard fold, then tap:

```js
it('submits registration form', async () => {
  await element(by.id('first-name-input')).tap();
  await element(by.id('first-name-input')).replaceText('Jane');
  // Scroll the form container to bring the submit button above the keyboard
  await element(by.id('registration-form-scroll')).scrollTo('bottom');
  await element(by.id('register-button')).tap();
  await waitFor(element(by.id('success-screen')))
    .toBeVisible()
    .withTimeout(5000);
});
```

Alternatively, dismiss the keyboard before tapping off-screen elements:

```js
// iOS: tap outside any input to dismiss keyboard
await element(by.id('screen-root-container')).tap();
// Android: press back key dismisses keyboard
await device.pressBack();
```

### 14. WebSocket connections block Detox idle detection indefinitely [community]

**Root cause**: Detox's idle detector monitors network activity. A persistent WebSocket
connection (e.g., a real-time chat or live data feed) registers as continuous network
activity from the app's perspective. Detox never sees the app as "idle" and hangs on
every `element()` call until the configured timeout fires — even when all visible UI
has rendered.

**Fix**: Disable or defer WebSocket connections in test mode via `launchArgs`:

```js
// In test setup
await device.launchApp({
  newInstance: true,
  launchArgs: { DISABLE_WEBSOCKET: '1' },
});

// In app code — check launchArgs before opening socket
import { NativeModules } from 'react-native';
const launchArgs = NativeModules.DetoxSync?.launchArgs || {};
if (launchArgs.DISABLE_WEBSOCKET !== '1') {
  openWebSocket();
}
```

Or use `disableSynchronization` in a narrow scope when the WebSocket must be active:

```js
it('shows real-time message from WebSocket', async () => {
  await device.disableSynchronization();
  try {
    // WebSocket is active — use explicit waitFor with generous timeout
    await waitFor(element(by.id('live-message-item')))
      .toBeVisible()
      .withTimeout(10000);
  } finally {
    await device.enableSynchronization();
  }
});
```

### 15. React Navigation ghost screens cause false-positive `toBeVisible()` [community]

**Root cause**: React Navigation (Stack Navigator) keeps the previous screen mounted in
the component tree when you navigate forward — it's just positioned off-screen or hidden
by the new screen. If the previous screen and the new screen share a `testID` (e.g., both
have a `testID="back-button"`), Detox's `toBeVisible()` may match the hidden copy on the
previous screen layer, not the visible one on the current screen. The test passes
incorrectly, but the actual UI may be in a wrong state.

**Fix**: Always assert a *unique* landmark on the destination screen immediately after
`toBeVisible()` to confirm the correct screen layer is active:

```js
it('navigates to checkout and shows the correct total', async () => {
  await element(by.id('checkout-button')).tap();

  // Asserting the screen root is visible is necessary but not sufficient
  await waitFor(element(by.id('checkout-screen')))
    .toBeVisible()
    .withTimeout(5000);

  // Assert a unique data element that only exists on the checkout screen
  await expect(element(by.id('order-total-label'))).toBeVisible();

  // Optionally, assert the previous screen is NOT visible
  await expect(element(by.id('cart-screen'))).not.toBeVisible();
});
```

---

### 16. iOS Keychain persists across `launchApp({ newInstance: true })` [community]

**Root cause**: The iOS Simulator Keychain is not cleared by `launchApp({ newInstance: true })` or `device.reloadReactNative()`. If your auth flow stores tokens in the Keychain (via `react-native-keychain`, `expo-secure-store`, or similar), a test that logs in and writes a token will cause the *next* test's "fresh install" to appear already-authenticated. Tests that expect a login screen will find a home screen instead.

**Fix**: Use `device.clearKeychain()` (Detox 20+) in `beforeAll` or `beforeEach` to purge the simulator Keychain:

```js
// e2e/setup.js — Keychain isolation for auth-sensitive test suites
beforeAll(async () => {
  // Clears ALL Keychain entries for the current simulator
  // Requires Detox >= 20.0 and iOS simulator
  await device.clearKeychain();

  await device.launchApp({
    newInstance: true,
    permissions: { notifications: 'YES' },
  });
});
```

For older Detox versions, the workaround is to use `launchApp({ delete: true })` which
uninstalls and reinstalls the app, wiping Keychain entries for that bundle ID:

```js
// Detox < 20 workaround — full app reinstall clears Keychain
beforeAll(async () => {
  await device.launchApp({
    delete: true,   // uninstall + reinstall = clear Keychain, AsyncStorage, SQLite
    permissions: { notifications: 'YES' },
  });
});
```

**Android equivalent**: Android Keystore entries are tied to the app's certificate. Uninstalling
the app (via `delete: true` or ADB) removes the keys. There is no `clearKeychain()` equivalent
for Android — use `delete: true` instead.

---

### 17. React Native 0.73+ `metro.config.js` change breaks Detox build [community]

**Root cause**: React Native 0.73 changed the Metro config API from `module.exports = { ... }` to using `getDefaultConfig` from `@react-native/metro-config`. If your `metro.config.js` was not updated when upgrading RN, Detox's `detox build` command compiles with the old Metro resolver and silently ships a bundle that crashes on device — the test suite fails at app launch with a red-screen error that appears unrelated to Metro.

**WHY it's hard to diagnose**: The failure looks like a device/simulator problem ("app crashed on launch") rather than a build problem. The red screen may not even appear on headless CI.

**Fix**: Update `metro.config.js` to the new format:

```js
// metro.config.js — RN 0.73+ format required for Detox compatibility
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

const defaultConfig = getDefaultConfig(__dirname);

const config = {
  // Add any project-specific Metro overrides here
};

module.exports = mergeConfig(defaultConfig, config);
```

If you need to extend Metro for Detox (e.g., to resolve mock modules), patch the resolver:

```js
// metro.config.js — with test mock resolver for Detox
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

const defaultConfig = getDefaultConfig(__dirname);

const config = {
  resolver: {
    resolveRequest: (context, moduleName, platform) => {
      // Redirect analytics module to a no-op stub during e2e tests
      if (process.env.DETOX_BUILD && moduleName === '@segment/analytics-react-native') {
        return {
          filePath: require.resolve('./e2e/mocks/analytics-stub.js'),
          type: 'sourceFile',
        };
      }
      return context.resolveRequest(context, moduleName, platform);
    },
  },
};

module.exports = mergeConfig(defaultConfig, config);
```

### 18. `jest-circus` runner required — `jasmine2` removed in Detox 20 [community]

**Root cause**: Detox 20 dropped support for the `jasmine2` test runner entirely. Projects that upgraded Detox without checking the `testRunner` field in `.detoxrc.js` fail at startup with a cryptic "Cannot find module 'jasmine2'" error. This catches teams that have `jest-jasmine2` pinned in their `package.json` as a legacy dependency.

**Fix**: Ensure `jest-circus` is the active runner:

```js
// .detoxrc.js — jest-circus is the only supported runner in Detox 20+
testRunner: {
  args: {
    $0: 'jest',
    config: 'e2e/jest.config.js',
  },
  jest: {
    setupTimeout: 300000,
  },
},
```

```json
// package.json — ensure jest-circus is installed (jest 27+ includes it by default)
{
  "devDependencies": {
    "jest": "^29.0.0",
    "jest-circus": "^29.0.0"
  }
}
```

If upgrading from Detox 19 or earlier, also check for any `jasmine.getEnv()` calls in your test setup files — they will throw when `jest-circus` is the runner.

---

## CI Considerations

### Animation disabling

Disable `UIManager.setLayoutAnimationEnabledExperimental` on Android and pass `detoxDisableAnimations: 'true'` via `launchArgs` on iOS. Without this, Detox waits for animation frames that never stop on fast-path screens.

### Simulator boot timeout

Add a generous `setupTimeout` in the Detox runner config. On a cold macOS CI runner, simulator boot + app install can take 60–90 seconds. Default Jest setup timeout is 5 seconds and will abort before Detox finishes booting.

```js
// .detoxrc.js
testRunner: {
  jest: { setupTimeout: 300000 },  // 5 minutes for cold-boot CI
},
```

### Boot simulator before tests (CI pre-step)

On GitHub Actions, simulators are not pre-booted. Add an explicit boot step before running Detox:

```bash
# Boot simulator and wait for it to be ready
xcrun simctl boot "iPhone 15" 2>/dev/null || true
xcrun simctl bootstatus "iPhone 15" -b

# Optionally, reset the simulator to factory state
xcrun simctl erase "iPhone 15"
```

### xcodebuild flags for CI

Use these flags on CI builds to avoid resource contention and code-signing failures:

```bash
xcodebuild \
  -workspace ios/MyApp.xcworkspace \
  -scheme MyApp \
  -configuration Release \
  -sdk iphonesimulator \
  -derivedDataPath ios/build \
  -parallelizeTargets NO \
  -jobs 2 \
  CODE_SIGNING_ALLOWED=NO \
  | xcpretty
```

### Artifact collection on failure

Configure the `artifacts` block in `.detoxrc.js` (see Pattern 12). Without screenshots/video on CI failure, you are debugging blind. Save artifacts to the CI upload path and set `retention-days` to avoid storage bloat.

### Parallel execution constraints [community]

Each Detox worker needs its own simulator instance. On macOS GitHub Actions runners (12 vCPUs), booting more than 2–3 simulators simultaneously causes instability. Prefer splitting test files across multiple CI jobs (matrix strategy) rather than using `maxWorkers` within a single job.

### React Native New Architecture (Fabric) notes [community]

On Fabric (New Architecture), some third-party components do not yet expose `testID` to the native accessibility tree. If `by.id()` fails to find an element that visually exists, check whether the component is a Fabric-native component without testID bridging. Workaround: wrap in a `<View testID="wrapper-id">` at the parent level.

### React Native 0.74+ Bridgeless Mode and Detox Compatibility [community]

React Native 0.74 introduced **Bridgeless Mode** (the final New Architecture step: removes the legacy JS Bridge entirely, leaving only JSI). Detox 20.8+ supports Bridgeless Mode, but older Detox versions fail silently — the app appears to launch, but `launchArgs`, `setURLBlacklist`, and `disableSynchronization` have no effect because they relied on Bridge calls that no longer exist.

**Symptoms:**
- `device.setURLBlacklist()` has no visible effect; analytics URLs still block idle detection
- `launchArgs` values are undefined in `NativeModules.RNConfig` (the RNConfig module no longer bridges)
- `disableSynchronization()` returns without an error but synchronization is not disabled

**Fix**: Update Detox to 20.8+ before migrating to Bridgeless Mode:

```bash
# Check current Detox version
npx detox --version

# Update to latest
npm install --save-dev detox@latest
```

In Bridgeless Mode, `launchArgs` must be read via the new TurboModule API instead of `NativeModules`:

```js
// OLD (Bridge-based) — stops working in Bridgeless Mode
import { NativeModules } from 'react-native';
const launchArgs = NativeModules.DetoxSync?.launchArgs ?? {};

// NEW (TurboModule-based) — works in both Bridge and Bridgeless modes
import { TurboModuleRegistry } from 'react-native';
const DetoxSync = TurboModuleRegistry.getEnforcing('DetoxSync');
const launchArgs = DetoxSync?.getLaunchArgs?.() ?? {};
```

**CI flag**: If you have both Bridgeless and non-Bridgeless builds in CI (e.g., testing both old and new architecture), set `RCT_NEW_ARCH_ENABLED=1` in the build command and create a separate Detox configuration entry:

```js
// .detoxrc.js — separate config for New Architecture (Bridgeless) build
configurations: {
  'ios.sim.release': {      // Old Architecture — Detox < 20.8 compatible
    device: 'simulator',
    app: 'ios.release',
  },
  'ios.sim.newarch': {      // New Architecture + Bridgeless — requires Detox 20.8+
    device: 'simulator',
    app: 'ios.newarch',     // built with RCT_NEW_ARCH_ENABLED=1
  },
},
```

**TurboModule `testID` bridging**: Components built as TurboNative Modules must explicitly implement `getTestID()` in their native code for `by.id()` to find them. If a TurboModule component fails to match, add a `<View testID="wrapper" pointerEvents="none">` wrapper — the native View always bridges `testID` correctly regardless of architecture.

### Detox cache cleanup

Before running tests on a fresh CI agent, clean framework caches to avoid stale native binaries:

```bash
npx detox clean-framework-cache
npx detox build-framework-cache
```

### Android emulator: adb reverse for network mocking

When pointing the Android emulator to a local mock server, the emulator cannot reach `localhost` on the host machine without an ADB reverse port forward. Without this, all API calls fail silently with connection refused, causing the entire test suite to fail in ways that look like app crashes.

```bash
# Forward host port 8088 to emulator port 8088 before running tests
adb reverse tcp:8088 tcp:8088

# Full CI pre-test step for Android
adb wait-for-device
adb reverse tcp:8088 tcp:8088
npx detox test -c android.emu.ci
```

```js
// .detoxrc.js — use 10.0.2.2 (Android emulator host alias) as fallback
apps: {
  'android.debug': {
    launchArgs: {
      // 10.0.2.2 is the host machine as seen from the Android emulator
      API_BASE_URL: 'http://10.0.2.2:8088',
    },
  },
},
```

### Complete GitHub Actions workflow (iOS) [community]

The following is a production-ready workflow. Key decisions: runs on `macos-14` (Apple Silicon runners are faster and cheaper); pins Xcode version via `xcode-select`; uses matrix sharding for parallelism; caches derived data by source hash; uploads artifacts only on failure.

```yaml
# .github/workflows/e2e-ios.yml
name: Detox E2E — iOS

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  detox-ios:
    runs-on: macos-14
    timeout-minutes: 60
    strategy:
      fail-fast: false
      matrix:
        shard: [1, 2, 3]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Set Xcode version
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Cache iOS build
        uses: actions/cache@v4
        id: ios-build-cache
        with:
          path: ios/build
          key: ios-build-${{ hashFiles('ios/**', 'src/**', 'package-lock.json') }}
          restore-keys: ios-build-

      - name: Build iOS app (Release)
        if: steps.ios-build-cache.outputs.cache-hit != 'true'
        run: npx detox build -c ios.sim.release

      - name: Boot simulator
        run: |
          xcrun simctl boot "iPhone 15" 2>/dev/null || true
          xcrun simctl bootstatus "iPhone 15" -b

      - name: Run Detox tests (shard ${{ matrix.shard }}/${{ strategy.job-total }})
        run: |
          npx detox test \
            -c ios.sim.release \
            --shard-index ${{ matrix.shard }} \
            --shard-count ${{ strategy.job-total }} \
            --loglevel verbose \
            --artifacts-location .artifacts

      - name: Upload test artifacts on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: detox-artifacts-shard-${{ matrix.shard }}
          path: .artifacts/
          retention-days: 7
```


---

## Key APIs

| Method | Description | When to use |
|--------|-------------|-------------|
| `element(by.id(id))` | Select element by `testID` | Primary selector for all interactions |
| `element(by.label(label))` | Select by accessibility label | When `testID` is absent |
| `element(by.text(text))` | Select by visible text | Assertions only; avoid for actions |
| `element(by.value(val))` | Select by accessibility value | Sliders, progress bars, toggles |
| `element(by.type(type))` | Select by native component type | Narrowing when testID is shared |
| `.and(matcher)` | Compound matcher | Combining matchers for precision |
| `.withAncestor(matcher)` | Scopes to ancestor container | Resolving ambiguous matches in lists |
| `.withDescendant(matcher)` | Scopes to descendant | Checking child element presence |
| `.atIndex(n)` | Select nth match | Only when multiple distinct elements match |
| `.tap()` | Simulates a tap | Buttons, list items, toggles |
| `.tapAtPoint({ x, y })` | Taps at a pixel offset within element | Canvas, map pins, custom gesture areas |
| `.typeText(str)` | Types text into an input | Text fields |
| `.clearText()` | Clears a text input | Before re-typing in an already-filled field |
| `.replaceText(str)` | Clears and types in one call | Faster than clearText+typeText |
| `.tapReturnKey()` | Taps the keyboard return key | Submitting forms via keyboard |
| `.scroll(px, direction)` | Scrolls a scrollable container | Reaching off-screen elements |
| `.scrollTo(edge)` | Scrolls to `'top'`, `'bottom'`, `'left'`, `'right'` | Quick edge scrolling |
| `.swipe(direction, speed, norm)` | Swipe gesture | Carousels, dismissible modals |
| `.longPress()` | Long press | Context menus, drag handles |
| `.multiTap(n)` | Send N rapid taps (double-tap, triple-tap) | Double-tap to zoom/like, triple-tap to select |
| `.longPressAndDrag(...)` | Long press then drag to target element | Drag-and-drop, Kanban, reordering |
| `.pinch(scale, speed)` | Pinch gesture (iOS) | Zoom interactions |
| `.adjustSliderToPosition(0–1)` | Set native Slider value (0=min, 1=max) | Native slider controls |
| `expect(el).toBeVisible()` | Asserts element is on screen and visible | Primary visibility assertion |
| `expect(el).toExist()` | Asserts element is in React tree | Checking unmounted vs mounted |
| `expect(el).toHaveText(str)` | Asserts element displays text | Text content assertions |
| `expect(el).toHaveValue(val)` | Asserts input has a value | TextInput value assertion |
| `expect(el).toHaveLabel(str)` | Asserts element's accessibilityLabel | Screen reader / a11y validation |
| `expect(el).toHaveToggleValue(bool)` | Asserts accessible toggle is on/off | Switch, CheckBox, accessibilityRole=switch |
| `expect(el).toHaveId(str)` | Asserts element has a specific testID | Verifying correct element is found |
| `expect(el).not.toBeVisible()` | Asserts element is hidden or absent | Verifying dismissal |
| `waitFor(el).toBeVisible().withTimeout(ms)` | Waits up to ms for element to appear | Async data load, navigation transitions |
| `waitFor(el).toBeVisible().whileElement(by.id).scroll(px, dir)` | Scroll until element visible | Dynamic lists |
| `device.launchApp(params)` | Launch or relaunch the app | `beforeAll` / test-level resets |
| `device.reloadReactNative()` | Reload JS bundle without restart | Fast `beforeEach` state reset (JS-only) |
| `device.terminateApp()` | Kill the app process | Cleanup in `afterAll` |
| `device.sendUserNotification(payload)` | Simulate a push notification (app must be running) | Testing foreground/background notification flows |
| `device.sendUserActivity(params)` | Simulate NSUserActivity / Handoff event (iOS) | Handoff, Spotlight, Siri integration tests |
| `device.setAppearance('dark' \| 'light')` | Switch simulator between dark and light mode (iOS) | Dark mode / theming tests without relaunch |
| `device.setURLBlacklist(patterns)` | Block URLs from being tracked by sync | Suppress analytics/ad beacon flakiness |
| `device.disableSynchronization()` | Disable automatic idle waiting | Narrow scope around known sync-breaking code |
| `device.enableSynchronization()` | Re-enable automatic idle waiting | Re-enable immediately after `disableSynchronization` |
| `device.sendToBackground()` | Send the app to background (simulates Home button) | Test foreground/background lifecycle transitions |
| `device.bringToForeground()` | Bring the app back to foreground | Test session restore, UI state after backgrounding |
| `device.shake()` | Shake gesture | Shake-to-report, undo gesture |
| `device.setStatusBar(params)` | Override status bar display | Screenshot/visual consistency in CI |
| `device.getPlatform()` | Returns `'ios'` or `'android'` | Conditional test logic per platform |
| `device.takeScreenshot(name)` | Save a screenshot to artifacts | Manual debugging snapshots |
| `device.captureViewHierarchy(name)` | Dump native accessibility tree to .viewhierarchy file | Debug "element not found" — open in Xcode |
| `device.clearKeychain()` | Purge iOS Simulator Keychain (Detox 20+) | Prevent token leak between auth test suites |
| `element.scrollPickerViewToRowIndex(row, col)` | Scroll iOS native PickerView to a row in a column | iOS native `<Picker>` / date pickers |
| `element.scroll(px, dir, startX?, startY?)` | Scroll from a specific normalized position (0–1) | Tap-dense scroll views where center is occupied |
| `element.tapBackspace()` | Send a backspace key event to the focused element | Clearing secureTextEntry password fields where clearText() fails |
| `jestExpect` (global) | Jest's `expect` aliased to avoid Detox conflict | Value assertions alongside Detox element assertions |
| `by.system()` | Match system-level UI elements (alerts, permission dialogs) | When pre-granting in `launchApp` is not possible |

### WebView APIs (Detox 20+)

| Method | Description | When to use |
|--------|-------------|-------------|
| `web(element(by.id(id)))` | Create a WebView scope for DOM interactions | Required before any `by.web.*` selector |
| `by.web.id('el-id')` | Match DOM element by `id` attribute | Primary web selector — most stable |
| `by.web.testId('val')` | Match DOM element by `data-testid` attribute | When web elements use `data-testid` |
| `by.web.className('cls')` | Match DOM element by CSS class | When id/testid unavailable |
| `by.web.cssSelector('sel')` | Match DOM element by CSS selector | Complex DOM structures |
| `by.web.xpath('xpath')` | Match DOM element by XPath | Semantic HTML traversal |
| `by.web.label('text')` | Match DOM element by ARIA label | Accessibility-labeled web elements |
| `by.web.name('attr')` | Match DOM element by `name` attribute | Form input `name` attribute |
| `by.web.href('url')` | Match anchor by exact `href` | Link validation |
| `by.web.hrefContains('str')` | Match anchor by partial `href` | Flexible link matching |
| `webEl.tap()` | Click a DOM element | Web buttons, links |
| `webEl.typeText(str)` | Type into a web input | Web form fields |
| `webEl.getText()` | Return element's visible text content | Web content assertions |
| `webEl.getInnerHTML()` | Return element's innerHTML | HTML structure assertions |
| `webEl.scrollToView()` | Scroll the web page to reveal element | Off-viewport web elements |
| `webEl.runScript(fn)` | Execute JS with element as argument | Custom web interactions |
| `webEl.exists()` | Returns true/false without throwing | Optional web element checks |

### Android-specific device APIs

| Method | Description | When to use |
|--------|-------------|-------------|
| `device.pressBack()` | Simulate Android hardware back button | Back navigation tests |
| `device.openNotifications()` | Open the Android notification shade | Notification tray tests |
| `device.setLocation(lat, lon)` | Set GPS coordinates | Location-aware feature tests |
| `device.reverseTcp(port)` | ADB reverse TCP port forward | Connecting emulator to local mock server |
| `element.getAttributes()` | Read element's native property snapshot | Conditional assertions, geometry checks |
| `device.matchFace()` | Simulate successful Face ID match (iOS) | Biometric login success path |
| `device.unmatchFace()` | Simulate Face ID failure (iOS) | Biometric fallback path |
| `device.matchFinger()` | Simulate successful fingerprint match (Android) | Fingerprint authentication |
| `device.unmatchFinger()` | Simulate fingerprint failure (Android) | Fingerprint fallback path |
| `device.setBiometricEnrollment(bool)` | Enroll/unenroll biometrics in simulator | Required before calling matchFace/matchFinger |
| `device.setOrientation('landscape')` | Rotate device orientation | Landscape layout tests |
| `device.setStatusBar(params)` | Override status bar display | Screenshot/visual consistency in CI |
| `device.installApp()` | Install app binary on device without launching | Multi-device test setup |
| `device.uninstallApp()` | Uninstall app binary from device | Full cleanup after multi-device tests |
| `device.sendUserActivity(params)` | Simulate NSUserActivity / Handoff event (iOS) | Deep-link via Handoff, Spotlight, or Universal Links |

---

## State Isolation Helpers

### AsyncStorage reset via launchArgs

```js
// e2e/setup.js — reset async storage before each suite
beforeAll(async () => {
  await device.launchApp({
    newInstance: true,
    launchArgs: { RESET_STORAGE: '1' },
  });
});

// In RN app (e.g., App.js or a native module bridge)
import AsyncStorage from '@react-native-async-storage/async-storage';

if (NativeModules.RNConfig?.RESET_STORAGE === '1') {
  AsyncStorage.clear().catch(console.error);
}
```

### Full clean slate with delete: true

```js
// Completely uninstall and reinstall the app — clears Keychain, AsyncStorage, SQLite
beforeAll(async () => {
  await device.launchApp({
    delete: true,  // equivalent to uninstall + reinstall
    permissions: {
      notifications: 'YES',
      camera: 'YES',
    },
  });
});
```

Use `delete: true` only for onboarding tests and first-launch flows. It is significantly slower (8–15 s) than `newInstance: true` (3–5 s) or `reloadReactNative()` (<1 s).

### Test ordering reference

| Reset method | Speed | Resets JS | Resets AsyncStorage | Resets Keychain | Use for |
|---|---|---|---|---|---|
| `reloadReactNative()` | Fast (<1s) | Yes | No | No | Pure UI / navigation tests |
| `launchApp({ newInstance: true })` | Medium (3-5s) | Yes | No | No | Most test suites |
| `launchApp({ delete: true })` | Slow (8-15s) | Yes | Yes | Yes | Onboarding, first-launch tests |

---

## Flakiness Root-Cause Decision Tree

Use this tree when a test intermittently fails. Start at the top and work down.

```
Test fails on CI but passes locally?
├── YES → Is there a hard-coded sleep or setTimeout?
│   ├── YES → Replace with waitFor(...).withTimeout(N)
│   └── NO  → Is an animation blocking idle detection?
│       ├── YES → Gate animation behind DETOX_MODE flag (Pattern 6)
│       └── NO  → Is an analytics/crash-reporting SDK firing requests?
│           ├── YES → Add to device.setURLBlacklist() (Pattern 10)
│           └── NO  → Is there a setInterval or WebSocket keeping app busy?
│               ├── YES → Disable via launchArgs in test mode (Gotchas 10, 14)
│               └── NO  → Is the simulator model different from local?
│                   ├── YES → Pin simulator model in .detoxrc.js
│                   └── NO  → Is the app binary stale (cached from wrong commit)?
│                       └── → Add source hash to CI cache key (Gotcha 9)
│
Test fails every time on CI?
├── Is the simulator/emulator booted before tests?
│   ├── NO  → Add xcrun simctl boot / adb shell wm dismiss-keyguard to CI pre-step
│   └── YES → Is an OS permission dialog appearing?
│       ├── YES → Pre-grant in launchApp({ permissions }) (Pattern 9)
│       └── NO  → Is the element off-screen?
│           ├── YES → Use scrollTo or whileElement.scroll (Pattern 3)
│           └── NO  → Is by.id() matching multiple elements?
│               ├── YES → Make testIDs unique; avoid atIndex() (Gotcha 3)
│               └── NO  → Did previous test leave app in bad state?
│                   └── → Use newInstance: true or delete: true (Gotcha 2, 4)
│
Test passes consistently but assertions are wrong?
├── Is a React Navigation ghost screen being matched?
│   └── YES → Assert unique destination landmark + source.not.toBeVisible() (Gotcha 15)
└── Is clearText() missing before typeText()?
    └── YES → Use replaceText() instead (Gotcha 8)

Android emulator test fails — app can't reach mock server?
└── Is localhost used as API_BASE_URL?
    ├── YES → Use reversePorts or 10.0.2.2 (Gotcha 38)
    └── NO  → Is -gpu swiftshader_indirect missing?
        └── → Add to emulator bootArgs/emulator-options (Gotcha 36)
```

---

## Anti-Patterns Checklist

Review your tests against this list when diagnosing a CI failure:

| Anti-Pattern | Fix |
|---|---|
| `await new Promise(r => setTimeout(r, 2000))` | Replace with `waitFor(...).toBeVisible().withTimeout(N)` |
| Asserting on element without `waitFor` after async action | Always wrap post-async assertions in `waitFor` |
| `by.text()` for buttons | Use `testID` + `by.id()` |
| Multiple elements matching same `by.id()` | Use unique `testID` per element |
| `atIndex(N)` on dynamic lists | Use data-driven `testID` (e.g., `item-{id}`) |
| Real network calls to external APIs | Mock the network layer or use a local mock server |
| Persistent `setInterval` in app code | Disable in test mode via `launchArgs` |
| Long animations (> 1500 ms) | Disable or shorten in test mode |
| Missing `clearText()` before `typeText()` | Always `clearText()` first, or use `replaceText()` |
| Global `disableSynchronization()` | Narrow to smallest needed scope with `try/finally` |
| No permissions pre-granted | Set `permissions` in `launchApp` options |
| Simulator not booted before test run | Boot and await status in CI pipeline |
| Tests depend on previous test state | Each test must set up its own required state |
| No artifacts configured | Add screenshot + video + log plugins to `.detoxrc.js` |
| Hardcoded timeouts not scaled for CI | Use `IS_CI`-aware timeout constants (Pattern 5) |
| Binary cache key excludes source files | Include `hashFiles('ios/**', 'src/**')` in cache key |
| Lottie/looped animations not gated | Gate behind `isTestEnvironment` flag |
| Persistent WebSocket connection active | Disable via `launchArgs: { DISABLE_WEBSOCKET: '1' }` (Gotcha 14) |
| Android emulator lock screen active | Add `adb shell wm dismiss-keyguard` to CI pre-step (Gotcha 12) |
| React Navigation ghost screen false positive | Assert unique destination landmark + `not.toBeVisible()` for source (Gotcha 15) |
| Keyboard covering submit button on small screen | Scroll container to bottom before tapping, or dismiss keyboard first (Gotcha 13) |
| Expo OTA update firing during test startup | Block expo.dev URLs with `device.setURLBlacklist` or disable in app.json |
| Using `tapAtPoint` with hardcoded pixels for tappable UI | Add `testID` and use `tap()` instead; `tapAtPoint` is for canvas/map only |
| `adjustSliderToPosition` on a custom JS slider | Only works on native RN `<Slider>`; use JS test helpers for custom sliders |
| Leaving `captureViewHierarchy` calls in production tests | Debug utility only — remove before merging; it adds ~500ms per call |
| `adjustSliderToPosition` on Android | API is iOS-only; guard with `device.getPlatform()` and use `tapAtPoint` fallback (Gotcha 31) |
| Duplicate `testID` on wrapper + inner component | Add `testID` only to the innermost interactive element (Gotcha 32) |
| Importing `expect` from `@jest/globals` | Use the `jestExpect` global alias provided by Detox's test environment instead |
| `scrollPickerViewToRowIndex` called before picker is visible | Always `waitFor(...).toBeVisible()` on the picker element before calling scroll |
| `element.scroll()` from center on tap-dense scroll views | Use `startPositionX`/`startPositionY` parameters to scroll from an edge |
| Using `launchApp({url})` for a warm deep link | Use `device.openURL()` when app is already running; `launchApp({url})` cold-starts the app |
| Using `--reuse` flag in CI | `--reuse` is for local iteration only; CI jobs always need a clean launch |
| `element.scroll()` called on a non-scrollable container | Assign `testID` to the `<ScrollView>` itself, not a wrapper `<View>` (Gotcha 25) |
| `device.openNotifications()` called on iOS | Android-only API; always guard with `device.getPlatform() === 'android'` (Gotcha 26) |
| `sendUserNotification()` called when app is killed | Use `device.launchApp({ userNotification: payload })` for cold-start notification tests (Gotcha 27) |
| `whileElement().scroll(300, 'down')` large step overshoots items | Use ≤50–100px step; ~¼ of minimum item height (Gotcha 28) |
| `npx detox test` without `-c` flag in CI | Always specify `-c ios.sim.release`; never rely on alphabetical default (Gotcha 29) |
| Remote config / feature flag fetched from network on startup | Inject flag values via `launchArgs` to short-circuit network call in tests |
| `sendUserActivity` with unregistered activityType | Register all `NSUserActivityTypes` in `Info.plist` before testing Handoff/Spotlight |
| `typeText()` for long strings (passwords, UUIDs) | Use `replaceText()` — `typeText` simulates key-by-key and adds 3–5s overhead per field (Gotcha 20) |
| `waitFor().toBeVisible()` without `.withTimeout()` (Detox 20+) | Detox 20+ defaults to 6000ms; always specify explicit timeout (Gotcha 33) |
| `clearText()` on secureTextEntry password field | Use `multiTap(3)` + `tapBackspace()` or `clearSecureField()` helper (Gotcha 35) |
| CI job hangs after test suite completes | Add `--forceExit` to Jest CLI args in `.detoxrc.js` testRunner (Gotcha 24) |
| Background/foreground lifecycle transitions not tested | Add `device.sendToBackground()` / `device.bringToForeground()` tests for session-sensitive flows (Gotcha 34) |
| Android emulator on Linux CI uses `-gpu swiftshader` (single-threaded) | Use `-gpu swiftshader_indirect` in emulator-options or `bootArgs`; verify with `adb shell getprop qemu.gles` (Gotcha 36) |
| `by.type()` uses legacy type names after RN 0.76+ New Architecture migration | Update to `RCTViewComponentView` (iOS) / `ReactViewGroup` (Android) or prefer `by.id()` (Gotcha 37) |
| Android mock server unreachable — app gets `ECONNREFUSED` on `localhost` | Use `reversePorts: [8088]` in app config, or use `10.0.2.2` as host alias (Gotcha 38) |
| iOS workflow deployed to CI but no Android equivalent | See Android GitHub Actions Workflow pattern — `ubuntu-22.04` + `reactivecircus/android-emulator-runner` |
| Network mock via local server requires `adb reverse` setup every run | Use `reversePorts` in `.detoxrc.js` for automatic reversal; or adopt MSW for JS-layer mocking |

---

## Flakiness Diagnosis Checklist

Use this checklist when a test passes locally but fails on CI:

1. **Timing** — Does the test use any `setTimeout` or fixed sleep? Replace with `waitFor`.
2. **Animations** — Are animations disabled in the CI build? See Pattern 6.
3. **Simulator model** — Is CI using the same simulator type as local? Pin it in the CI config; check that the Xcode image supports your pinned model (Gotcha 5).
4. **Binary staleness** — Was the app rebuilt before the run? Verify the CI cache key includes a source hash (Gotcha 9).
5. **Network calls** — Does the test hit real APIs? Use a mock server (Pattern 11); use `device.setURLBlacklist` to suppress analytics noise (Pattern 10, Gotcha 1).
6. **Synchronization scope** — Are third-party SDKs triggering background timers? Use `device.setURLBlacklist` or narrow-scope `disableSynchronization` (Pattern 13).
7. **Infinite animations** — Does the screen contain Lottie or looping animations? Gate them behind a test flag (Gotcha 6).
8. **Element uniqueness** — Does `by.id()` match more than one element? Use `.atIndex(0)` only as a last resort; fix the `testID` (Gotcha 3).
9. **Scroll position** — Is the element off-screen? Use `scrollTo` or `waitFor + whileElement.scroll` (Pattern 3).
10. **State leak** — Does a failing test leave the app in a bad state? Check whether `reloadReactNative()` is sufficient or whether `newInstance: true` is needed (Gotcha 4).
11. **Permissions** — Does the app request OS permissions on first launch? Pre-grant them via `launchApp` `permissions` (Pattern 9).
12. **New Architecture** — Is the target component a Fabric-native component? Check testID bridging (CI Considerations).
13. **Polling timers** — Does the app poll a server on an interval? Disable via `launchArgs` (Gotcha 10).
14. **Input field prefilled** — Did `typeText` append instead of replace? Add `clearText()` or use `replaceText()` (Gotcha 8).
15. **WebSocket** — Does the app maintain a persistent WebSocket? Use `launchArgs` to disable in test mode (Gotcha 14).
16. **Android lock screen** — Did the emulator lock screen appear before tests? Add `adb shell wm dismiss-keyguard` to CI pre-step (Gotcha 12).
17. **React Navigation ghost** — Does the destination screen share a `testID` with the previous screen? Assert a unique landmark + `not.toBeVisible()` for the source (Gotcha 15).
18. **Keyboard coverage** — Does the software keyboard obscure the submit button on small screens? Scroll the form container before tapping (Gotcha 13).
19. **iOS Keychain token leak** — Does the app store auth tokens in the Keychain? Use `device.clearKeychain()` (Detox 20+) or `delete: true` in `beforeAll` (Gotcha 16).
20. **Remote config network call on startup** — Does the app fetch feature flags from a remote config service at launch? Inject via `launchArgs` to short-circuit the async fetch and prevent idle-detection delays.
21. **`whileElement().scroll()` overshoot** — Is the `scroll` step too large, causing the target element to scroll past the viewport? Reduce to ≤50px per step (Gotcha 28).
22. **Notification test state** — Is the app in the killed state when you call `sendUserNotification()`? Use `device.launchApp({ userNotification: payload })` for cold-start notification tests (Gotcha 27).
23. **Wrong configuration on CI** — Was `-c` / `--configuration` omitted? Always specify the exact config name; never rely on alphabetical default (Gotcha 29).
24. **Implicit `withTimeout` in Detox 20+** — Is `waitFor()` missing `.withTimeout()`? Detox 20 defaults to 6000 ms; add explicit `.withTimeout()` to all `waitFor` calls (Gotcha 33).
25. **CI job hangs after suite** — Does the CI runner stay blocked after all tests finish? Add `forceExit: true` to `testRunner.args` in `.detoxrc.js` (Gotcha 24).
26. **Background/foreground lifecycle untested** — Does the feature survive app backgrounding? Add `device.sendToBackground()` / `device.bringToForeground()` tests (Gotcha 34).
27. **`clearText()` failing on password field** — Is `clearText()` or `replaceText('')` called on a `secureTextEntry` field? Use `multiTap(3)` + `tapBackspace()` cross-platform helper (Gotcha 35).
28. **Android Linux CI emulator rendering stalls** — Is `-gpu swiftshader_indirect` missing from emulator boot flags? Add it to prevent single-threaded SwiftShader rendering deadlocks (Gotcha 36).
29. **`by.type()` matching fails after RN 0.76+ New Architecture migration** — Did Fabric change native type names? Update type strings to `RCTViewComponentView` (iOS) or `ReactViewGroup` (Android), or prefer `by.id()` (Gotcha 37).
30. **Android app cannot reach mock server at `localhost`** — Is `reversePorts` missing from the app config? The emulator routes `localhost` to its own loopback, not the host. Use `reversePorts: [8088]` or `launchArgs: { API_BASE_URL: 'http://10.0.2.2:8088' }` (Gotcha 38).
31. **`by.web()` assertion races WebView page transition** — Did a web interaction trigger a navigation before your assertion? Wait for a DOM element on the destination page before asserting (Gotcha 44).
32. **Screenshot visual diff fails on CI due to dynamic content** — Are timestamps, counters, or badges in the screenshot? Freeze dynamic content with `VISUAL_TEST_MODE` launchArg (Gotcha 45).
33. **Android 15 predictive back gesture leaves both screens visible briefly** — After `device.pressBack()`, assert destination visible AND source not visible; don't rely on the intermediate preview state (Gotcha 47).
34. **React Native 0.78+ `strictMode` causes double-render flakiness on Debug builds** — Use Release builds for CI Detox runs; or disable `React.StrictMode` during Detox tests (Gotcha 50).

---

## Project Setup Quick Reference

Minimum setup to get a Detox project running from scratch:

```bash
# 1. Install Detox CLI and dependencies
# Note: Detox 20+ requires jest-circus (jasmine2 runner is no longer supported)
npm install --save-dev detox jest jest-circus

# 2. Initialize Detox configuration (adds .detoxrc.js skeleton)
npx detox init

# 3. Build the app for testing
npx detox build -c ios.sim.debug

# 4. Run tests
npx detox test -c ios.sim.debug

# 5. Run on CI (release configuration, no interactive output)
npx detox test -c ios.sim.release --loglevel verbose
```

```json
// package.json — recommended test scripts
{
  "scripts": {
    "test:e2e": "detox test -c ios.sim.debug",
    "test:e2e:ci": "detox test -c ios.sim.release --loglevel verbose",
    "test:e2e:android": "detox test -c android.emu.debug",
    "build:e2e:ios": "detox build -c ios.sim.release",
    "build:e2e:android": "detox build -c android.emu.debug"
  }
}
```

---

## TypeScript Setup for Detox

Detox ships TypeScript types from `detox` package directly (`@types/detox` is deprecated
since Detox 18). Using TypeScript provides autocomplete for the entire Detox API and
catches matcher/assertion typos at compile time.

### Installation

```bash
# Install TypeScript and ts-jest (or babel with @babel/preset-typescript)
npm install --save-dev typescript ts-jest @types/node

# Detox 18+ ships its own types — no @types/detox needed
# Verify the types are present:
ls node_modules/detox/index.d.ts
```

### tsconfig for e2e

```json
// e2e/tsconfig.json — TypeScript config scoped to the e2e folder only
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "types": ["node", "detox"]
  },
  "include": ["./**/*.ts"],
  "exclude": ["../node_modules"]
}
```

### jest.config.ts (TypeScript runner config)

```ts
// e2e/jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  rootDir: '..',
  testMatch: ['<rootDir>/e2e/**/*.test.ts'],
  testTimeout: 120000,
  retryTimes: process.env.CI ? 1 : 0,
  transform: {
    '^.+\\.tsx?$': ['ts-jest', {
      tsconfig: '<rootDir>/e2e/tsconfig.json',
    }],
  },
  globalSetup: 'detox/runners/jest/globalSetup',
  globalTeardown: 'detox/runners/jest/globalTeardown',
  testEnvironment: 'detox/runners/jest/testEnvironment',
  reporters: ['detox/runners/jest/reporter'],
};

export default config;
```

### TypeScript test file

```ts
// e2e/login.test.ts
// Detox globals (element, by, waitFor, device, expect) are injected by testEnvironment
// TypeScript sees them via "types": ["detox"] in tsconfig.json

const { TIMEOUT } = require('./constants');

describe('Login flow', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  beforeEach(async () => {
    await device.reloadReactNative();
  });

  it('authenticates with valid credentials', async () => {
    await element(by.id('email-input')).replaceText('user@example.com');
    await element(by.id('password-input')).replaceText('secret123');
    await element(by.id('login-button')).tap();
    await waitFor(element(by.id('home-screen')))
      .toBeVisible()
      .withTimeout(TIMEOUT.long);
  });
});
```

### TypeScript constants file

```ts
// e2e/constants.ts
const IS_CI = process.env.CI === 'true';

export const TIMEOUT = {
  short:  IS_CI ? 5000  : 2000,
  medium: IS_CI ? 10000 : 3000,
  long:   IS_CI ? 20000 : 5000,
  launch: IS_CI ? 30000 : 10000,
} as const;

export type TimeoutKey = keyof typeof TIMEOUT;
```

**Gotcha [community]:** If `element`, `by`, `waitFor`, `device`, and `expect` show
TypeScript errors ("Cannot find name 'element'"), verify that `"types": ["detox"]` is
set in the `e2e/tsconfig.json` — NOT the project root `tsconfig.json`. Adding it to the
root `tsconfig.json` pollutes the app compilation with Detox types and causes conflicts
with React Native's own `expect` type from Jest.

---

## Expo-Specific Setup

When using Detox with an **Expo** project (Expo SDK 50+, Expo Router, or managed workflow
with EAS Build), the setup differs from bare React Native in several ways.

### expo-detox-plugin configuration

Expo projects require the `expo-detox-plugin` Babel plugin installed, and the `expo-modules-core`
package to be present for proper native module bridging:

```bash
npx expo install expo-modules-core
npm install --save-dev jest-expo @config-plugins/detox
```

```js
// .detoxrc.js — Expo managed workflow with prebuild
module.exports = {
  testRunner: {
    args: { $0: 'jest', config: 'e2e/jest.config.js' },
    jest: { setupTimeout: 300000 },
  },
  apps: {
    'ios.expo': {
      type: 'ios.app',
      // After `npx expo prebuild` and `npx expo run:ios --configuration Release`
      binaryPath: 'ios/build/Build/Products/Release-iphonesimulator/YourApp.app',
      build: 'npx expo run:ios --configuration Release --no-bundler 2>&1 | tail -30',
    },
    'android.expo': {
      type: 'android.apk',
      binaryPath: 'android/app/build/outputs/apk/release/app-release.apk',
      build: 'npx expo run:android --variant release --no-bundler 2>&1 | tail -30',
    },
  },
  devices: {
    simulator: { type: 'ios.simulator', device: { type: 'iPhone 15' } },
    emulator: { type: 'android.emulator', device: { avd: 'Pixel_6_API_33' } },
  },
  configurations: {
    'ios.expo.release': { device: 'simulator', app: 'ios.expo' },
    'android.expo.release': { device: 'emulator', app: 'android.expo' },
  },
};
```

### Expo Router deep link testing

Expo Router uses file-system based routing. Deep links use the `expo-scheme` defined in
`app.json`. Test them with `device.launchApp({ url })`:

```js
// e2e/expo-router.test.js
it('navigates to a product via Expo Router deep link', async () => {
  await device.launchApp({
    newInstance: true,
    // scheme defined in app.json: { "expo": { "scheme": "myapp" } }
    url: 'myapp:///products/42',  // Expo Router uses triple-slash for absolute path
  });
  await waitFor(element(by.id('product-detail-42')))
    .toBeVisible()
    .withTimeout(5000);
});

it('navigates to a tab via Expo Router', async () => {
  await device.launchApp({
    newInstance: true,
    url: 'myapp:///tabs/profile',
  });
  await waitFor(element(by.id('profile-screen')))
    .toBeVisible()
    .withTimeout(5000);
  await expect(element(by.id('profile-avatar'))).toBeVisible();
});
```

### EAS Build integration [community]

When building with EAS Build for CI, the app binary is not available locally. Use the
`--binary` flag to point Detox at the downloaded artifact:

```bash
# Download EAS build artifact
eas build --platform ios --profile preview --local --output ios-test.ipa

# Run Detox against the downloaded binary
DETOX_APP_BINARY_PATH=./ios-test.ipa npx detox test -c ios.expo.release
```

Or configure the binary path via environment variable in `.detoxrc.js`:

```js
apps: {
  'ios.eas': {
    type: 'ios.app',
    binaryPath: process.env.DETOX_APP_BINARY_PATH || 'ios/build/...',
  },
},
```

**Expo OTA updates gotcha [community]:** If your Expo app has OTA (Over-the-Air) update
logic, the app will try to fetch a bundle from expo.dev on every launch — even in tests.
This causes random "app idle" timeouts because the update check is an async network request.
**Fix:** Disable OTA in test builds by setting `"updates": { "enabled": false }` in
`app.json` for the CI build profile, or block the update URL with `device.setURLBlacklist`:

```js
await device.setURLBlacklist([
  '.*exp\\.host.*',      // Expo Update server
  '.*expo\\.io.*',       // Legacy Expo CDN
  '.*expo\\.dev.*',      // Expo Dashboard APIs
]);
```

---

## React Navigation Testing Patterns

When using React Navigation, screen transitions can create ghost states where the old
screen is still mounted (but not visible) while the new screen is shown. Asserting only
`toBeVisible()` on the destination is insufficient if the source screen renders the same
`testID` at a hidden layer.

### Asserting correct screen with title or unique landmark

```js
// e2e/react-navigation.test.js
const { TIMEOUT } = require('./constants');

it('navigates from home to profile screen', async () => {
  await element(by.id('profile-tab')).tap();

  // 1. Wait for destination screen root to be visible
  await waitFor(element(by.id('profile-screen')))
    .toBeVisible()
    .withTimeout(TIMEOUT.medium);

  // 2. Assert a unique landmark on the destination screen
  //    — confirms we're not on a ghost navigation layer
  await expect(element(by.id('profile-avatar'))).toBeVisible();

  // 3. Assert source screen root is NOT visible (guards against ghost screens)
  await expect(element(by.id('home-screen'))).not.toBeVisible();
});

it('navigates back via hardware back button (Android)', async () => {
  await element(by.id('profile-tab')).tap();
  await waitFor(element(by.id('profile-screen'))).toBeVisible().withTimeout(TIMEOUT.medium);

  // Simulate Android hardware back
  await device.pressBack();

  await waitFor(element(by.id('home-screen'))).toBeVisible().withTimeout(TIMEOUT.medium);
  await expect(element(by.id('profile-screen'))).not.toBeVisible();
});

// Helper: assert active tab bar item
async function assertActiveTab(tabId) {
  const attrs = await element(by.id(tabId)).getAttributes();
  // React Navigation sets accessibilityState.selected on the active tab
  expect(attrs.value).toBe('1');  // selected=true serialized as '1' on iOS
}
```

### Modal stack testing

React Navigation modals are presented above the main stack. Test them like any other
screen but check for the overlay container:

```js
it('shows and dismisses a modal', async () => {
  await element(by.id('open-modal-button')).tap();
  await waitFor(element(by.id('modal-screen')))
    .toBeVisible()
    .withTimeout(TIMEOUT.medium);

  // Close modal via close button or swipe down
  await element(by.id('modal-close-button')).tap();
  await waitFor(element(by.id('modal-screen')))
    .not.toBeVisible()
    .withTimeout(TIMEOUT.medium);

  // Confirm underlying screen is still visible
  await expect(element(by.id('home-screen'))).toBeVisible();
});
```

---

## Multi-App Jest Projects Configuration

When your repository contains multiple React Native apps (e.g., a customer app and a
driver app), use Jest's `projects` feature to run each app's e2e tests in isolation
while sharing the Detox test runner configuration:

```js
// e2e/jest.config.js — top-level config for multi-app setups
module.exports = {
  projects: [
    {
      displayName: 'customer-app',
      rootDir: '../',
      testMatch: ['<rootDir>/e2e/customer/**/*.test.js'],
      testTimeout: 120000,
      globalSetup: 'detox/runners/jest/globalSetup',
      globalTeardown: 'detox/runners/jest/globalTeardown',
      testEnvironment: 'detox/runners/jest/testEnvironment',
      reporters: ['detox/runners/jest/reporter'],
    },
    {
      displayName: 'driver-app',
      rootDir: '../',
      testMatch: ['<rootDir>/e2e/driver/**/*.test.js'],
      testTimeout: 120000,
      globalSetup: 'detox/runners/jest/globalSetup',
      globalTeardown: 'detox/runners/jest/globalTeardown',
      testEnvironment: 'detox/runners/jest/testEnvironment',
      reporters: ['detox/runners/jest/reporter'],
    },
  ],
};
```

```bash
# Run only the customer app tests
npx detox test -c ios.customer.release --testPathPattern="e2e/customer"

# Run all apps in sequence
npx detox test -c ios.customer.release && npx detox test -c ios.driver.release
```

**Note:** Do not run multiple apps' tests in the same Jest worker process — each Detox
configuration manages its own device lifecycle, and sharing a device between apps
causes crashes.

### Multi-app install/uninstall for cross-app interaction testing

When testing flows that span two apps (e.g., a "Share to App" flow, a "Sign in with MyApp"
OAuth flow, or a deep-link handoff between companion apps), use `device.installApp()` and
`device.uninstallApp()` to manage the secondary app binary on the same device:

```js
// e2e/multi-app.test.js
// Tests the "Sign in with CustomerApp" flow in the DriverApp

const CUSTOMER_APP_BINARY = process.env.CUSTOMER_APP_BINARY
  || 'ios/build/CustomerApp.app';

describe('Cross-app OAuth flow', () => {
  beforeAll(async () => {
    // Launch the primary app (DriverApp — configured in .detoxrc.js)
    await device.launchApp({
      newInstance: true,
      permissions: { notifications: 'YES' },
    });

    // Install the secondary app (CustomerApp) without launching it
    await device.installApp(CUSTOMER_APP_BINARY);
  });

  afterAll(async () => {
    // Uninstall the secondary app to clean up the device
    await device.uninstallApp('com.mycompany.customerapp');
  });

  it('switches to CustomerApp for OAuth and returns to DriverApp', async () => {
    // Trigger the "Sign in with CustomerApp" button in DriverApp
    await element(by.id('sign-in-with-customer-app-button')).tap();

    // iOS will switch to CustomerApp — Detox follows the active app
    await waitFor(element(by.id('customer-app-oauth-screen')))
      .toBeVisible()
      .withTimeout(10000);

    // Approve in CustomerApp
    await element(by.id('approve-access-button')).tap();

    // App switches back to DriverApp after approval
    await waitFor(element(by.id('driver-home-screen')))
      .toBeVisible()
      .withTimeout(10000);
  });
});
```

**Important constraints:**
- `device.installApp(binaryPath)` installs the binary without launching it. The binary must be pre-built.
- `device.uninstallApp(bundleId)` uninstalls by bundle ID, not by binary path.
- Detox does not natively "follow" app switches between two apps on iOS without custom configuration. For complex cross-app flows, prefer testing the OAuth boundary via API-level mocking rather than live app switching.

The built-in Detox reporter is sufficient for CI logs, but a custom reporter enables
integration with test management systems (e.g., TCMS, TestRail, Allure):

```js
// e2e/reporters/tcmsReporter.js
class TcmsReporter {
  constructor(globalConfig, options) {
    this._options = options;
    this._results = [];
  }

  onTestResult(test, testResult) {
    testResult.testResults.forEach(result => {
      this._results.push({
        title: result.fullName,
        status: result.status,        // 'passed' | 'failed' | 'pending'
        duration: result.duration,
        failureMessages: result.failureMessages,
        ancestorTitles: result.ancestorTitles,
      });
    });
  }

  onRunComplete(contexts, results) {
    const report = {
      timestamp: new Date().toISOString(),
      passed: results.numPassedTests,
      failed: results.numFailedTests,
      skipped: results.numPendingTests,
      total: results.numTotalTests,
      suites: results.numPassedTestSuites,
      tests: this._results,
    };

    const fs = require('fs');
    const path = this._options.outputPath || 'e2e-results.json';
    fs.writeFileSync(path, JSON.stringify(report, null, 2));
    console.log(`\n[TcmsReporter] Results written to ${path}`);
  }
}

module.exports = TcmsReporter;
```

```js
// e2e/jest.config.js — add custom reporter alongside Detox reporter
module.exports = {
  testTimeout: 120000,
  globalSetup: 'detox/runners/jest/globalSetup',
  globalTeardown: 'detox/runners/jest/globalTeardown',
  testEnvironment: 'detox/runners/jest/testEnvironment',
  reporters: [
    'detox/runners/jest/reporter',   // required for Detox lifecycle
    ['./reporters/tcmsReporter.js', { outputPath: 'e2e-results.json' }],
  ],
};
```

---

## Supplementary Interaction Patterns

### Dark mode / appearance testing with device.setAppearance()

Detox can switch the simulator/emulator between light and dark mode without relaunching
the app. Use `device.setAppearance()` to verify your app's dark mode styles and theming:

```js
// e2e/appearance.test.js
describe('Appearance / dark mode', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  afterAll(async () => {
    // Reset to light mode after the suite to avoid contaminating subsequent tests
    await device.setAppearance('light');
  });

  it('renders the dashboard correctly in dark mode', async () => {
    await element(by.id('dashboard-tab')).tap();
    await waitFor(element(by.id('dashboard-screen'))).toBeVisible().withTimeout(3000);

    // Switch to dark mode while app is running
    await device.setAppearance('dark');

    // Verify dark-mode-specific elements are applied
    // (your app should toggle background color / text color via useColorScheme())
    await expect(element(by.id('dashboard-screen'))).toBeVisible();
    // Verify screenshot manually or with visual regression tooling
    await device.takeScreenshot('dashboard-dark-mode');
  });

  it('renders the dashboard correctly in light mode', async () => {
    await device.setAppearance('light');
    await expect(element(by.id('dashboard-screen'))).toBeVisible();
    await device.takeScreenshot('dashboard-light-mode');
  });

  it('does not crash when appearance switches while a modal is open', async () => {
    await element(by.id('open-settings-modal-button')).tap();
    await waitFor(element(by.id('settings-modal'))).toBeVisible().withTimeout(3000);

    // Switch appearance while modal is open — tests for crash during re-render
    await device.setAppearance('dark');
    await expect(element(by.id('settings-modal'))).toBeVisible();

    await device.setAppearance('light');
    await expect(element(by.id('settings-modal'))).toBeVisible();
  });
});
```

**API**: `device.setAppearance('dark' | 'light')` — iOS Simulator only. On Android,
use ADB to switch system night mode:

```bash
# Android: switch to dark mode
adb shell cmd uimode night yes

# Android: switch back to light mode
adb shell cmd uimode night no
```

Or call it from the test via Detox's `device.reverseTcp` equivalent pattern:

```js
// e2e/helpers/setAndroidAppearance.js
const { execSync } = require('child_process');

function setAndroidAppearance(mode) {
  const flag = mode === 'dark' ? 'yes' : 'no';
  execSync(`adb shell cmd uimode night ${flag}`, { stdio: 'inherit' });
}

module.exports = { setAndroidAppearance };
```

### Pinch gesture for map zoom and image viewer testing

```js
// e2e/pinch.test.js
it('zooms in on a map with a pinch gesture', async () => {
  await element(by.id('map-view')).tap(); // ensure map is focused
  await waitFor(element(by.id('map-view'))).toBeVisible().withTimeout(3000);

  // pinch(scale, speed, angle)
  // scale > 1 = zoom in; scale < 1 = zoom out
  // speed: 'fast' | 'slow' (default 'fast')
  // angle: rotation angle in radians (default 0 = horizontal pinch)
  await element(by.id('map-view')).pinch(2.0, 'slow', 0);

  // Verify map zoom level indicator updated
  await waitFor(element(by.id('zoom-level-badge')))
    .toHaveText('Street level')
    .withTimeout(3000);
});

it('zooms out with reverse pinch', async () => {
  // First zoom in
  await element(by.id('map-view')).pinch(2.0, 'slow', 0);
  // Then zoom out
  await element(by.id('map-view')).pinch(0.5, 'slow', 0);
  await waitFor(element(by.id('zoom-level-badge')))
    .toHaveText('City level')
    .withTimeout(3000);
});

it('rotates an image in the viewer', async () => {
  await element(by.id('image-carousel')).tap();
  await waitFor(element(by.id('full-image-viewer'))).toBeVisible().withTimeout(3000);

  // Rotate pinch gesture (angle in radians — Math.PI/2 = 90 degrees)
  await element(by.id('full-image-viewer')).pinch(1.0, 'slow', Math.PI / 2);
  await device.takeScreenshot('image-rotated-90deg');
});
```

**Notes:**
- `pinch()` is iOS Simulator only. Android does not support programmatic pinch via the Detox API.
- `scale` is relative to the current zoom level, not absolute.
- Combine with `device.takeScreenshot()` to capture the post-gesture state for visual review.

Use `device.launchApp({ url })` when the app must cold-start from the deep link (simulates
tapping a URL from Safari or a notification). Use `device.openURL({ url })` when the app
is already running and you want to simulate a universal link being received while the app
is in the foreground:

```js
// Cold-start: app not running — tapped link launches the app
it('cold-start deep link navigates to product', async () => {
  await device.launchApp({
    newInstance: true,
    url: 'myapp://products/42',
  });
  await waitFor(element(by.id('product-detail-42'))).toBeVisible().withTimeout(5000);
});

// Warm: app already running — receives universal link in foreground
it('in-app universal link navigates to product without re-launching', async () => {
  await device.launchApp({ newInstance: true });
  await waitFor(element(by.id('home-screen'))).toBeVisible().withTimeout(5000);

  // App is running — open the URL into the running instance
  await device.openURL({ url: 'https://www.myapp.com/products/42' });
  await waitFor(element(by.id('product-detail-42'))).toBeVisible().withTimeout(5000);
});
```

### Location testing with device.setLocation()

```js
// e2e/location.test.js
describe('Location-aware features', () => {
  beforeAll(async () => {
    await device.launchApp({
      newInstance: true,
      permissions: { location: 'always' },
    });
  });

  it('shows nearby stores when user is in San Francisco', async () => {
    // Set GPS coordinates before triggering the location-dependent feature
    await device.setLocation(37.7749, -122.4194);   // San Francisco
    await element(by.id('find-nearby-stores-button')).tap();
    await waitFor(element(by.id('store-list'))).toBeVisible().withTimeout(8000);
    // Verify at least one SF store is shown
    await expect(element(by.id('store-item-sf-market-st'))).toBeVisible();
  });

  it('shows no nearby stores when user is in the ocean', async () => {
    await device.setLocation(0, 0);    // Null Island — no stores
    await element(by.id('find-nearby-stores-button')).tap();
    await waitFor(element(by.id('empty-stores-message'))).toBeVisible().withTimeout(5000);
  });
});
```

**Note:** `device.setLocation()` works on iOS Simulator and Android Emulator. On Android,
you may need to set the mock location provider first:

```bash
adb shell appops set <package> MOCK_LOCATION allow
```

### Shake gesture

```js
it('shows the feedback dialog when device is shaken', async () => {
  await device.shake();
  await waitFor(element(by.id('feedback-dialog'))).toBeVisible().withTimeout(3000);
  await element(by.id('feedback-cancel-button')).tap();
  await waitFor(element(by.id('feedback-dialog'))).not.toBeVisible().withTimeout(2000);
});
```

### Handoff and Spotlight testing with device.sendUserActivity()

`device.sendUserActivity()` simulates an `NSUserActivity` being sent to the app — the mechanism used by iOS Handoff (continue on another device), Spotlight Search result taps, and Siri App Integration. Test these flows without requiring a real Handoff device or Spotlight indexing:

```js
// e2e/handoff.test.js
describe('NSUserActivity routing (Handoff / Spotlight)', () => {
  beforeAll(async () => {
    await device.launchApp({
      newInstance: true,
      permissions: { notifications: 'YES' },
    });
  });

  beforeEach(async () => {
    await device.reloadReactNative();
  });

  it('continues a document editing session from Handoff', async () => {
    // Simulate another Apple device handing off a document activity
    await device.sendUserActivity({
      activityType: 'com.myapp.editing',
      userInfo: {
        documentId: 'doc-99',
        scrollPosition: 450,
      },
    });

    // App should open the document at the handed-off scroll position
    await waitFor(element(by.id('document-editor-doc-99')))
      .toBeVisible()
      .withTimeout(8000);
  });

  it('opens a Spotlight search result for a product', async () => {
    // Simulate tapping a Spotlight result for a product
    await device.sendUserActivity({
      activityType: 'com.myapp.viewProduct',
      userInfo: {
        productId: 'prod-42',
      },
    });

    await waitFor(element(by.id('product-detail-prod-42')))
      .toBeVisible()
      .withTimeout(5000);
    await expect(element(by.id('product-title'))).toBeVisible();
  });
});
```

**API notes:**
- `activityType` must match the `NSUserActivityTypes` array declared in `Info.plist`.
- `userInfo` is a plain JS object — it is serialized to NSDictionary for the native layer.
- If `activityType` is not registered in `Info.plist`, `sendUserActivity` is silently ignored on iOS.
- This API is iOS-only. On Android, use `device.launchApp({ url: 'https://...' })` for equivalent Universal Link simulation.

---

Detox tests that check accessibility labels and toggle values simultaneously validate
functional behavior AND screen-reader compatibility. Adding a11y assertions costs nothing
extra and ensures VoiceOver/TalkBack users get the same experience.

```js
// e2e/accessibility.test.js

it('verifies form labels are set correctly for screen readers', async () => {
  // toHaveLabel() asserts the element's accessibilityLabel property
  // This is what VoiceOver and TalkBack read aloud
  await expect(element(by.id('email-input'))).toHaveLabel('Email address');
  await expect(element(by.id('password-input'))).toHaveLabel('Password');
  await expect(element(by.id('login-button'))).toHaveLabel('Log in');
});

it('verifies toggle switch state is announced correctly', async () => {
  // toHaveToggleValue(true|false) asserts an accessible toggle's on/off state
  // Works with Switch, CheckBox, and any component with accessibilityRole="switch"
  const toggle = element(by.id('notifications-toggle'));
  await expect(toggle).toHaveToggleValue(false);  // initially off

  await toggle.tap();
  await expect(toggle).toHaveToggleValue(true);   // now on
});

it('verifies image has a meaningful accessibility label', async () => {
  // Decorative images should have accessibilityLabel set to '' (empty)
  // or accessibilityElementsHidden={true}
  // Informative images must have a descriptive accessibilityLabel
  await expect(element(by.id('hero-image'))).toHaveLabel('Woman using the app on a phone');
});

it('verifies disabled button is not interactive', async () => {
  // Verify via getAttributes that an element is disabled before asserting non-interactivity
  const attrs = await element(by.id('submit-button')).getAttributes();
  expect(attrs.enabled).toBe(false);
  // A disabled button should not respond to taps — no need to tap and assert
  await expect(element(by.id('submit-button'))).toBeVisible();
});
```

**Note:** `toHaveLabel()` checks the React Native `accessibilityLabel` prop, NOT `testID`
or displayed text. These are independent: an element can have `testID="login-btn"` (for
Detox) AND `accessibilityLabel="Log in to your account"` (for screen readers).

**`accessibilityHint` vs `accessibilityLabel`:** `toHaveLabel()` matches `accessibilityLabel` (the primary label read by VoiceOver/TalkBack). `accessibilityHint` provides supplementary guidance ("double-tap to submit the form") and is NOT exposed via a Detox matcher — it can be verified indirectly via `getAttributes()`:

```js
it('verifies submit button has correct hint for screen readers', async () => {
  const attrs = await element(by.id('submit-button')).getAttributes();
  // accessibilityHint is in attrs.hint on iOS
  expect(attrs.hint).toBe('Submits the form and navigates to the confirmation screen');
  expect(attrs.label).toBe('Submit Order');
});
```

**Integration with a11y CI audits:** Run `toHaveLabel()` assertions in a dedicated
`accessibility.test.js` suite to prevent a11y regressions from reaching production.

---

## CLI Debugging Reference

### --debug-synchronization: diagnose infinite hangs

When a `waitFor` call or an `element()` call hangs indefinitely, Detox is waiting for the
app to become idle. Add `--debug-synchronization 3000` to the CLI command to print the
synchronization status every 3 seconds — revealing exactly which subsystem is keeping the
app busy (animation, network, timer, etc.):

```bash
# Add --debug-synchronization to any detox test invocation
npx detox test -c ios.sim.debug --debug-synchronization 3000

# Example output while test is hanging:
# [Detox] Synchronization status:
# - 1 animations running
# - 1 tracked timers (delay < 1500ms)
# - 1 network requests in flight: https://api.amplitude.com/2/httpapi
```

This output directly tells you to add `https://api.amplitude.com` to `device.setURLBlacklist()`.

### --loglevel and --record-logs for CI debugging

```bash
# verbose: shows every Detox action and its result
npx detox test -c ios.sim.release --loglevel verbose

# Record full device logs to .artifacts/ even on pass
npx detox test -c ios.sim.release --record-logs all

# Record videos on all tests (not just failures)
npx detox test -c ios.sim.release --record-videos all

# Take screenshots at every test lifecycle event
npx detox test -c ios.sim.release --take-screenshots all
```

### --testNamePattern for targeted retries

When debugging a single flaky test, run only that test instead of the full suite:

```bash
# Run only tests whose name matches the pattern
npx detox test -c ios.sim.release --testNamePattern "logs in with valid credentials"

# Run a specific test file
npx detox test -c ios.sim.release e2e/login.test.js

# Run and retry failed tests (combine with Jest --bail to stop early)
npx detox test -c ios.sim.release --bail 1
```

### --reuse flag for fast local iteration

The `--reuse` flag skips the app install/launch step and reattaches Detox to an already-running simulator. Use it when iterating on a single test locally to avoid the 5–10 second cold-boot overhead on every run:

```bash
# First run — installs and launches the app normally
npx detox test -c ios.sim.debug e2e/login.test.js

# Subsequent runs — reuse the already-launched app (no reinstall, no reboot)
npx detox test -c ios.sim.debug e2e/login.test.js --reuse

# Combine with --testNamePattern to run a single test repeatedly
npx detox test -c ios.sim.debug --reuse --testNamePattern "logs in with valid credentials"
```

**WARNING:** Never use `--reuse` in CI. The reuse flag assumes the simulator is already in a known good state. On CI, each job starts fresh — `--reuse` may attach to a stale or crashed simulator from a previous job.

**When `--reuse` breaks:** If a previous test left the app in an unexpected state (e.g., a modal still open), `--reuse` inherits that state and the next test starts from a broken baseline. Fix: add `device.reloadReactNative()` in `beforeAll` even when using `--reuse`, so the JS bundle is reset at the cost of ~1 second.

### testRunner.retries vs jest retryTimes — understanding the difference

Detox `20.0+` introduced its own retry mechanism in `.detoxrc.js` via `testRunner.retries`. This is distinct from Jest's `retryTimes` option and operates at a different layer:

| Mechanism | Config location | Granularity | What it retries |
|---|---|---|---|
| Jest `retryTimes` | `jest.config.js` | Per-test | Retries individual test cases (`it()` blocks) |
| Detox `testRunner.retries` | `.detoxrc.js` | Per-test-file | Retries an entire test file if any test in it fails |

```js
// .detoxrc.js — Detox-level file retry (entire file reruns if any test fails)
module.exports = {
  testRunner: {
    args: {
      $0: 'jest',
      config: 'e2e/jest.config.js',
    },
    jest: {
      setupTimeout: 300000,
    },
    retries: process.env.CI ? 1 : 0,  // retry the WHOLE FILE once on CI if any test fails
  },
  // ...
};
```

```js
// jest.config.js — Jest-level test retry (individual test cases retry without file reload)
module.exports = {
  retryTimes: process.env.CI ? 1 : 0,  // retry individual test cases
  testTimeout: 120000,
  globalSetup: 'detox/runners/jest/globalSetup',
  globalTeardown: 'detox/runners/jest/globalTeardown',
  testEnvironment: 'detox/runners/jest/testEnvironment',
};
```

**Which to use:**
- **Jest `retryTimes`** — appropriate when a single test occasionally fails due to transient timing, but the rest of the file is stable. The device stays running; only the `it()` block is re-executed.
- **Detox `testRunner.retries`** — appropriate when an entire test file fails due to a device-level issue (simulator crash, GPU unavailable, Metro port conflict). The device is re-initialized for the retry, giving a clean slate.
- **Both together** — valid: Jest retries transient test failures first; if too many tests fail and the file-level threshold is hit, Detox retries the whole file with a fresh device.

### Resetting simulator state between runs

```bash
# Full reset of a specific simulator — clears all apps and data
xcrun simctl erase "iPhone 15"

# List all available simulators
xcrun simctl list devices

# Kill and restart a hung simulator
xcrun simctl shutdown "iPhone 15" && xcrun simctl boot "iPhone 15"
```

---

## Additional Community Pitfalls

### 19. Status bar inconsistency breaks screenshot visual diffs on CI [community]

**Root cause**: CI runners often show different status bar states than developer machines — different time ("9:41" vs actual time), signal bars, battery icon, and cellular carrier text. When visual diff tools compare screenshots, the status bar region triggers false failures every run because the time is always different.

**WHY this is missed**: Teams focus on functional assertions and forget the status bar is part of every screenshot. The failure mode shows up only after integrating a visual regression tool (Percy, Applitools, Chromatic for mobile), not during initial test development.

**Fix**: Set a normalized status bar in `beforeAll` so every screenshot has consistent content:

```js
// e2e/setup.js — normalize status bar for visual regression consistency
beforeAll(async () => {
  await device.launchApp({ newInstance: true });

  if (device.getPlatform() === 'ios') {
    // Set a deterministic status bar for all screenshots
    await device.setStatusBar({
      time: '9:41',          // Apple's classic product photo time
      batteryLevel: 100,
      batteryState: 'charging',
      cellularBars: 4,
      wifiBars: 3,
      dataNetwork: 'wifi',
    });
  }
  // Android: use `adb shell settings put global system_ui_demo_mode 1`
  // and broadcast the demo mode intents before running tests
});
```

```bash
# Android emulator: enable demo mode for consistent status bar
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged true
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
```

### 20. `typeText()` vs `replaceText()` performance regression on long strings [community]

**Root cause**: `typeText()` simulates individual key presses for every character. For long strings (passwords ≥ 20 chars, UUIDs, base64 tokens), this adds up: a 32-character string takes ~32 synthetic key events, each with a synchronization cycle. On CI, this can add 3–5 seconds per field — and test suites that fill 6–8 form fields add 30+ seconds of unnecessary overhead.

**WHY it matters**: Teams benchmark `typeText` vs `replaceText` locally on fast hardware and see no difference. On CI with slower I/O, the difference is significant. A suite with 40 tests that each type credentials can see 20+ minutes of wasted time per run.

**Fix**: Use `replaceText()` for all text input. Reserve `typeText()` only for scenarios that specifically need to test the keypress-by-keypress behavior (autocomplete triggers, character-limit validation, masked input fields):

```js
// SLOW — avoid for long strings
await element(by.id('api-key-input')).typeText('sk-abcdef1234567890abcdef1234567890');

// FAST — preferred for all text input
await element(by.id('api-key-input')).replaceText('sk-abcdef1234567890abcdef1234567890');

// Use typeText() ONLY when testing character-by-character behavior:
it('shows autocomplete suggestions after typing 3 chars', async () => {
  await element(by.id('search-input')).typeText('spa'); // trigger autocomplete at char 3
  await waitFor(element(by.id('autocomplete-dropdown')))
    .toBeVisible()
    .withTimeout(2000);
});
```

### 21. Missing `afterAll` cleanup causes simulator state to leak into next test file [community]

**Root cause**: Jest runs multiple test files sequentially in the same worker process (when `maxWorkers: 1`). If a test file opens a modal, triggers a system permission dialog, or navigates deep into the app without resetting in `afterAll`, the next test file in the queue starts with the app in an unexpected state. The first test in the next file fails with "element not found" — but the real bug is in the previous file's missing cleanup.

**WHY it's hard to diagnose**: The failure is always reported against the first test of the *next* file, never against the test file that caused the pollution. Teams fix the wrong test.

**Fix**: Add `afterAll` to every test file that navigates away from the app's initial state:

```js
// e2e/modal-flow.test.js
describe('Modal flow', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  afterAll(async () => {
    // Ensure the modal is closed and app is in root navigation state
    // before Jest runs the next test file
    await device.reloadReactNative();
    // OR for hard reset:
    // await device.terminateApp();
  });

  it('opens and interacts with modal', async () => {
    await element(by.id('open-modal-button')).tap();
    await waitFor(element(by.id('modal-screen'))).toBeVisible().withTimeout(3000);
    // ... interactions ...
  });
});
```

### 25. `element.scroll()` silently fails or throws on a non-scrollable container [community]

**Root cause**: `element(by.id('some-view')).scroll(200, 'down')` sends a swipe gesture to the native view. If the view is a `<View>` rather than a `<ScrollView>` / `<FlatList>` / `<SectionList>`, the scroll gesture is delivered but has no effect. On some React Native versions, Detox throws a native exception. On others, it returns successfully while nothing scrolled — the next assertion fails because the target element is still off-screen.

**WHY teams miss this**: The `testID` that the developer added for Detox was added to a wrapper `<View>`, not the inner `<ScrollView>`. The hierarchy looks the same in `captureViewHierarchy`, but the scroll gesture targets the wrong container.

**Fix**: Assign the `testID` to the actual scrollable component, not its wrapper:

```jsx
// BAD — testID on a non-scrollable wrapper
<View testID="product-list">
  <ScrollView>
    {products.map(p => <ProductItem key={p.id} item={p} />)}
  </ScrollView>
</View>

// GOOD — testID on the ScrollView itself
<View>
  <ScrollView testID="product-list">
    {products.map(p => <ProductItem key={p.id} item={p} />)}
  </ScrollView>
</View>
```

When you don't control the component hierarchy, use `waitFor + whileElement.scroll` instead of `element.scroll()` — it handles the scroll position tracking natively:

```js
// Safer alternative: waitFor drives the scroll, not a standalone .scroll() call
await waitFor(element(by.id('product-item-99')))
  .toBeVisible()
  .whileElement(by.id('product-list'))
  .scroll(100, 'down');
```

To confirm the scrollable type at debug time: check `captureViewHierarchy` output — a `ScrollView` shows as `RCTScrollView` (iOS) or `android.widget.ScrollView` (Android); a plain `View` shows as `RCTView` / `android.view.View`. If the type is `RCTView`, the `testID` is on the wrong element.

### 26. `device.openNotifications()` hangs on iOS — it is Android-only [community]

**Root cause**: `device.openNotifications()` is an Android-specific API that pulls down the notification shade. There is no iOS equivalent. Teams who test across both platforms call it inside an `if (device.getPlatform() === 'android')` guard, but when they forget the guard and run on iOS, the call does not throw immediately — it sends a gesture that may interact with whatever is at the swipe-down coordinates, causing unpredictable behavior.

**WHY this catches teams**: The Detox TypeScript types expose `device.openNotifications()` without platform restriction. The API appears platform-agnostic in the type definitions.

**Fix**: Always guard Android-only device APIs:

```js
it('opens and reads a push notification from the shade', async () => {
  // Send the notification first
  await device.sendUserNotification({
    trigger: { type: 'push' },
    title: 'Order shipped',
    body: 'Your package is on its way!',
  });

  // openNotifications is Android-only — guard explicitly
  if (device.getPlatform() !== 'android') {
    // iOS: notification handling must be tested via sendUserNotification + tap simulation
    // There is no "pull down notification shade" API for iOS
    return;
  }

  await device.openNotifications();
  await waitFor(element(by.text('Order shipped')))
    .toBeVisible()
    .withTimeout(5000);
  await element(by.text('Order shipped')).tap();
  await waitFor(element(by.id('order-status-screen')))
    .toBeVisible()
    .withTimeout(5000);
});
```

**Android-only APIs to always guard:** `device.openNotifications()`, `device.pressBack()`, `device.reverseTcp()`, `device.matchFinger()`, `device.unmatchFinger()`. Check `device.getPlatform()` before calling any of these.

### 22. iPadOS multi-window / UIScene architecture causes silent tap on wrong window [community]

**Root cause**: On iOS, apps that use `UIScene`-based multi-window architecture (e.g., iPadOS split-screen, Catalyst apps, apps that open a sheet window) can have multiple view hierarchies simultaneously. When `element(by.id('submit-button'))` matches in two different windows, Detox may interact with the element in the inactive window, causing silent failures where the tap appears to succeed but the expected navigation never happens.

**WHY it's subtle**: The test does not throw an error — `element()` finds a match and `tap()` succeeds. The failure only surfaces when the expected next screen doesn't appear, making root-cause analysis difficult.

**Fix**: Use `withAncestor` or add window-specific container `testID`s to narrow scope:

```js
// Narrow the submit button to the main content container
// to prevent matching a button in a popover or sheet window
await element(
  by.id('submit-button').withAncestor(by.id('main-content-container'))
).tap();

// For iPadOS testing: explicitly test in the primary window context
// by setting a unique root testID on the main window's root view
await expect(
  element(by.id('submit-button').withAncestor(by.id('primary-window-root')))
).toBeVisible();
```

### 23. Using `device.openURL()` for warm deep links breaks if app uses custom URL schemes without Universal Links [community]

**Root cause**: `device.openURL({ url: 'myapp://...' })` requires the OS to route the custom URL scheme to the foreground app. On iOS Simulator, this goes through `xcrun simctl openurl`, which launches the *default handler* for the scheme. If the app has never been launched with that scheme registered (e.g., first cold boot, or after a reinstall), the OS may not recognize the scheme and the URL silently fails to route — the test hangs waiting for the navigation.

**WHY teams miss this**: Works perfectly after the first test that uses `launchApp({ url })` because that registers the scheme. Fails on the first test in a fresh CI run because the scheme is registered only at first launch.

**Fix**: Always `launchApp` (even with `newInstance: false`) before calling `device.openURL()`, and verify the scheme is registered:

```js
describe('Warm deep link navigation', () => {
  beforeAll(async () => {
    // First launch: registers custom URL scheme with the OS
    await device.launchApp({ newInstance: true });
    await waitFor(element(by.id('home-screen'))).toBeVisible().withTimeout(10000);
  });

  it('navigates via warm deep link', async () => {
    // App is running — openURL routes to the running instance
    await device.openURL({ url: 'myapp://orders/99' });
    await waitFor(element(by.id('order-detail-99')))
      .toBeVisible()
      .withTimeout(5000);
  });
});
```

For Universal Links (https://), use `device.openURL({ url: 'https://...' })` — these are routed by iOS's Associated Domains mechanism and do not require scheme registration.

### 24. Jest process hangs after test suite because Detox device connection is not released [community]

**Root cause**: After a Detox test run, the Jest worker process occasionally fails to exit cleanly. The Detox gRPC channel to the device/simulator stays open, and Jest's default "wait for async operations to finish" behavior keeps the process alive indefinitely — CI jobs time out after 60–90 minutes instead of failing fast.

**WHY teams miss this**: Locally, developers kill the terminal manually and never notice. On CI, the job blocks the machine, consumes runner minutes, and delays feedback. The failure mode looks like a timeout, not a test failure, so it doesn't appear in the test report.

**Fix**: Add `--forceExit` to the Jest call in the Detox test runner configuration:

```js
// .detoxrc.js — add forceExit to prevent Jest process hang after suite
module.exports = {
  testRunner: {
    args: {
      $0: 'jest',
      config: 'e2e/jest.config.js',
      forceExit: true,   // --forceExit: kills the Jest process after all tests finish
                         // Use only when Detox cleanup does not release all resources
    },
    jest: {
      setupTimeout: 300000,
    },
  },
  // ...
};
```

Or pass it directly in the CLI:

```bash
# CI pipeline — combine with --loglevel to get verbose output on failure
npx detox test -c ios.sim.release --loglevel verbose -- --forceExit
```

**When NOT to use `--forceExit`**: If your tests have `afterAll` teardown that writes to files, sends results to a TCMS, or cleans up external resources, `--forceExit` will skip that teardown. Use `--detectOpenHandles` first (Jest 26+) to identify the leaking resource:

```bash
# Diagnose the hanging handle before applying --forceExit
npx detox test -c ios.sim.debug -- --detectOpenHandles
# Output: TCPWRAP (the Detox device gRPC connection) — then add --forceExit only in CI
```

### 27. `sendUserNotification` behaves differently based on app lifecycle state [community]

**Root cause**: `device.sendUserNotification()` delivers the notification through iOS's UserNotifications framework. The notification routing behavior depends entirely on whether the app is in the foreground, background (suspended), or killed state — and Detox does not expose the app's lifecycle state, so teams write tests that assume one state when the app is actually in another.

**The three notification states:**

| App state | Notification behavior | What Detox's `sendUserNotification` simulates |
|---|---|---|
| Foreground | `userNotificationCenter:willPresent:withCompletionHandler:` fires — app receives it directly | ✓ Simulates foreground delivery |
| Background (suspended) | iOS shows the notification banner; tap routes to `userNotificationCenter:didReceive:withCompletionHandler:` | ✓ Simulates background tap |
| Killed | iOS shows the notification; tap cold-starts the app via `launchOptions` | Must use `device.launchApp({ userNotification: payload })` NOT `sendUserNotification` |

**Common mistake** — calling `sendUserNotification` when app is killed, expecting cold-start behavior:

```js
// WRONG — app was just terminated; sendUserNotification cannot deliver to a killed app
await device.terminateApp();
await device.sendUserNotification({  // this does nothing — app is not running
  trigger: { type: 'push' },
  title: 'Flash sale!',
});
// Test hangs waiting for navigation that never happens
```

**Correct pattern for cold-start via notification:**

```js
// CORRECT — use launchApp with userNotification payload to simulate tap-from-notification cold start
it('cold-starts the app from a tapped notification', async () => {
  await device.terminateApp();

  await device.launchApp({
    newInstance: true,
    userNotification: {
      trigger: { type: 'push' },
      title: 'Flash sale!',
      body: '50% off for the next hour',
      payload: {
        screenId: 'sale-screen',
        saleId: 'flash-42',
      },
    },
  });

  // App launched from notification — should route to the sale screen
  await waitFor(element(by.id('sale-screen-flash-42')))
    .toBeVisible()
    .withTimeout(10000);
});
```

**Correct pattern for foreground / background notification:**

```js
it('shows in-app notification banner when app is foregrounded', async () => {
  // App is running in foreground
  await waitFor(element(by.id('home-screen'))).toBeVisible().withTimeout(5000);

  // sendUserNotification works because app is running
  await device.sendUserNotification({
    trigger: { type: 'push' },
    title: 'New message',
    body: 'Alice: Are you coming?',
  });

  await waitFor(element(by.id('in-app-notification-banner')))
    .toBeVisible()
    .withTimeout(3000);
});
```

### 28. `waitFor().whileElement().scroll()` overshoots and buries the target element [community]

**Root cause**: `waitFor(element(by.id('target'))).toBeVisible().whileElement(by.id('list')).scroll(300, 'down')` scrolls the list by 300px on *every* poll iteration until the target is visible. If the list scrolls past the target element's position (i.e., the target was only 50px below the fold when the first scroll fired), the target is now 250px *above* the current viewport — no longer visible. Detox keeps scrolling down, never finding the element, until the timeout fires.

**WHY it's confusing**: The test output says "timeout waiting for element to become visible" — which makes it sound like the element doesn't exist, when the real problem is it was visible for one frame and then scrolled past.

**Fix**: Use a smaller `scroll` step size so each poll increments the scroll by a fraction of the viewport height. A step of `50`–`100` px per poll is usually sufficient for items in a virtualized list:

```js
// BAD — 300px step frequently overshoots items near the current scroll position
await waitFor(element(by.id('product-item-12')))
  .toBeVisible()
  .whileElement(by.id('product-list'))
  .scroll(300, 'down');

// GOOD — 50px step: slower but reliable; won't overshoot unless item height < 50px
await waitFor(element(by.id('product-item-12')))
  .toBeVisible()
  .whileElement(by.id('product-list'))
  .scroll(50, 'down');
```

**Practical rule of thumb**: Set the scroll step to approximately ¼ of the minimum expected item height. If items are 80px tall, use a step of 20–40px. For `SectionList` headers (which are larger), 80–100px is appropriate.

### 29. Running `detox test` without `--configuration` flag silently tests the wrong binary [community]

**Root cause**: When no `-c` / `--configuration` flag is passed to `npx detox test`, Detox uses the *first configuration alphabetically* in `.detoxrc.js`. If the first alphabetical entry is a Debug build but the intent is to run against Release (as recommended for CI), the test runs against the Debug binary — with the JS debugger port open, hot-reload active, and slower cold-boot times. The tests may also behave differently because debug builds include extra logging and slower layout measurements.

**WHY this bites CI pipelines**: Local developers always pass `-c ios.sim.debug`. When a new CI pipeline author copies the command without the flag, it silently picks the wrong configuration. Results look plausible but are not representative of production behavior.

**Fix**: Always specify `-c` in CI scripts, and document the correct configuration in package.json scripts:

```yaml
# GitHub Actions — always specify configuration explicitly
- name: Run Detox E2E tests
  run: |
    # Fail fast if DETOX_CONFIGURATION is not set (prevents silent misconfiguration)
    : "${DETOX_CONFIGURATION:?DETOX_CONFIGURATION env var must be set}"
    npx detox test -c "$DETOX_CONFIGURATION" --loglevel verbose
  env:
    DETOX_CONFIGURATION: ios.sim.release
```

```json
// package.json — document both local and CI variants explicitly
{
  "scripts": {
    "test:e2e": "detox test -c ios.sim.debug",
    "test:e2e:ci": "detox test -c ios.sim.release --loglevel verbose"
  }
}
```

### 30. Detox worker environment variables not forwarded to the app process [community]

**WHY this bites teams**: Works in unit/integration tests (same process) but fails for e2e tests. The mental model of "env vars flow everywhere" breaks at the native app boundary.

**Fix**: Forward env vars via `launchArgs` in `launchApp`. The app must read them via a native module bridge (`NativeModules.RNConfig`) or the React Native launch args:

```js
// e2e/setup.js — forward CI environment variables to the app via launchArgs
beforeAll(async () => {
  await device.launchApp({
    newInstance: true,
    launchArgs: {
      // These are accessible in the native app via NSBundle's infoDictionary (iOS)
      // or through intent extras (Android)
      API_BASE_URL: process.env.API_BASE_URL || 'http://localhost:8088',
      FEATURE_FLAG_NEW_CHECKOUT: process.env.FEATURE_FLAG_NEW_CHECKOUT || '0',
      DETOX_MODE: '1',
    },
  });
});
```

```js
// In RN app — read launch args forwarded by Detox
import { NativeModules, Platform } from 'react-native';

// iOS: read from RNConfig native module (implement once, use everywhere)
// Android: read from the intent extras passed by Detox
const launchArgs = NativeModules.DetoxSync?.launchArgs ?? {};

const API_BASE_URL = launchArgs.API_BASE_URL ?? 'https://api.production.com';
```

---

## Feature Flag Variant Testing

When your app has an A/B test or feature flag that changes the UI, run the same e2e test
against both flag variants by creating two Detox `app` entries — one built with the flag
enabled, one without. This catches regressions in both variants in CI without duplicating
test files.

### Pattern: Two-variant Detox configuration

```js
// .detoxrc.js — two app builds: control (flag off) and variant (flag on)
apps: {
  'ios.release': {
    type: 'ios.app',
    binaryPath: 'ios/build/Release-control/MyApp.app',
    build: 'FEATURE_NEW_CHECKOUT=0 npx detox build -c ios.sim.release',
  },
  'ios.release.variant': {
    type: 'ios.app',
    binaryPath: 'ios/build/Release-variant/MyApp.app',
    build: 'FEATURE_NEW_CHECKOUT=1 npx detox build -c ios.sim.release',
  },
},
configurations: {
  'ios.sim.release': {
    device: 'simulator',
    app: 'ios.release',
  },
  'ios.sim.release.variant': {
    device: 'simulator',
    app: 'ios.release.variant',
  },
},
```

```yaml
# GitHub Actions — matrix across both configurations
strategy:
  matrix:
    config: [ios.sim.release, ios.sim.release.variant]
steps:
  - name: Run Detox (${{ matrix.config }})
    run: npx detox test -c ${{ matrix.config }} --loglevel verbose
```

### Pattern: Runtime feature flag injection via launchArgs

When the flag is not baked at build time but is read from a remote config at startup, inject
it via `launchArgs` so the app uses the test value instead of the production remote config:

```js
// e2e/setup.js — inject feature flags at launch time
const FEATURE_FLAGS = {
  NEW_CHECKOUT: process.env.TEST_FEATURE_NEW_CHECKOUT || '0',
  DARK_MODE: process.env.TEST_FEATURE_DARK_MODE || '0',
};

beforeAll(async () => {
  await device.launchApp({
    newInstance: true,
    launchArgs: {
      ...FEATURE_FLAGS,
      DETOX_MODE: '1',
    },
  });
});
```

```js
// In RN app — check launchArgs before fetching remote config
import { NativeModules } from 'react-native';
const launch = NativeModules.DetoxSync?.launchArgs ?? {};

// If Detox injected a feature flag, use it directly; otherwise fetch remotely
const isNewCheckout = launch.NEW_CHECKOUT === '1'
  ? true
  : await fetchRemoteFeatureFlag('new_checkout');
```

**Why this matters [community]:** Remote config services (Firebase Remote Config, LaunchDarkly) fetch flags asynchronously on startup. The async fetch keeps the app "busy" for Detox's idle detector — adding 500–2000 ms of lag to every test. By overriding flags via `launchArgs`, you short-circuit the network call entirely, making tests faster and eliminating a source of intermittent timeouts.

---

Detox can record a test execution timeline — a JSON file that maps every Detox action to a wall-clock timestamp. This is invaluable for identifying slow tests and understanding where time is spent.

```js
// .detoxrc.js — enable timeline artifact
artifacts: {
  rootDir: '.artifacts',
  plugins: {
    timeline: {
      enabled: true,
    },
    screenshot: {
      shouldTakeAutomaticSnapshots: true,
      takeWhen: { testFailure: true },
    },
  },
},
```

```bash
# Record timeline in CLI
npx detox test -c ios.sim.release --record-timeline all

# The timeline is saved to .artifacts/<run-id>/timeline.json
# Open with: chrome://tracing (paste the JSON) or https://ui.perfetto.dev
```

The timeline output shows:
- `detox_action` spans: each `tap()`, `typeText()`, `waitFor()` call
- `idle_wait` spans: time Detox spent waiting for the app to become idle
- `element_visibility_check` spans: polling cycles inside `waitFor()`

If `idle_wait` spans are long, use `--debug-synchronization 3000` to find the culprit.
If `waitFor` polls many times before resolving, the timeout is generous — reduce it after confirming the feature's real latency.

---

## Additional Patterns (iteration 40 additions)

### iOS PickerView / native Picker testing with `selectPickerViewColumnIndex()`

React Native's `<Picker>` renders as a native `UIPickerView` on iOS. Detox provides
`scrollPickerViewToRowIndex()` (and the `selectPickerViewColumnIndex()` helper in Detox 20+)
to interact with these controls deterministically without relying on swipe gestures.

```js
// e2e/picker.test.js
// Native iOS PickerView — must have testID set on the <Picker> component

it('selects "Canada" from a country picker', async () => {
  await element(by.id('country-picker-button')).tap();

  // Wait for the picker modal / sheet to be visible
  await waitFor(element(by.id('country-picker')))
    .toBeVisible()
    .withTimeout(3000);

  // Scroll column 0 to row index 2 (0-based)
  // Row order matches the data array passed to the Picker
  await element(by.id('country-picker')).scrollPickerViewToRowIndex(2, 0);

  // Confirm the selection label updated
  await element(by.id('confirm-picker-button')).tap();
  await waitFor(element(by.id('selected-country-label')))
    .toHaveText('Canada')
    .withTimeout(2000);
});

it('selects a year from a two-column date picker (month, year)', async () => {
  await element(by.id('date-picker')).scrollPickerViewToRowIndex(0, 0); // month col
  await element(by.id('date-picker')).scrollPickerViewToRowIndex(5, 1); // year col (index 5 = 6th year option)
  await element(by.id('apply-date-button')).tap();
});
```

**Notes:**
- The first argument to `scrollPickerViewToRowIndex(rowIndex, colIndex)` is 0-based row index, second is 0-based column index.
- On Android, `<Picker>` renders as a `Spinner` widget. Use `element(by.id('picker')).tap()` to open the dropdown, then `element(by.text('Canada')).tap()` to select — Android pickers are not interactable via `scrollPickerViewToRowIndex`.
- If the Picker is inside a `<Modal>`, ensure the modal is fully visible before calling this API.

---

### Avoiding the Jest `expect` vs Detox `expect` namespace collision [community]

Detox injects its own `expect` global into the test environment. This conflicts with Jest's
`expect` when you import both in the same file — the last-defined global wins, causing
one or both `expect` implementations to silently break.

**Root cause**: The `testEnvironment: 'detox/runners/jest/testEnvironment'` in `jest.config.js`
sets Detox globals before the test file runs. If you import Jest's `expect` explicitly
(e.g., from `@jest/globals`), it overwrites Detox's `expect`. The reverse is also true
when test files use Detox's `expect` for element assertions after setting up Jest's `expect`
for value assertions.

```js
// BAD — importing from @jest/globals overwrites Detox's expect global in the file scope
import { expect } from '@jest/globals';
// All calls to expect(element(by.id('foo'))) will throw a cryptic type error:
// "received value must be a Detox element, got: [object Object]"

// GOOD — use the jestExpect alias provided by Detox's test environment
// Detox's test environment (detox/runners/jest/testEnvironment) exposes
// `jestExpect` as a separate global so you can use both without conflict:
it('fills a form and asserts navigation', async () => {
  await element(by.id('name-input')).replaceText('Alice');
  await element(by.id('submit-button')).tap();

  // Detox's expect — for element assertions
  await expect(element(by.id('success-screen'))).toBeVisible();

  // Jest's expect — for plain value assertions, exposed as jestExpect
  const attrs = await element(by.id('success-screen')).getAttributes();
  jestExpect(attrs.text).toBe('Welcome, Alice!');
  jestExpect(attrs.enabled).toBe(true);
});
```

**Alternative**: If you need Jest matchers (`toMatchObject`, `toContain`, etc.) alongside
Detox element assertions, use the `jestExpect` alias that Detox's test environment injects:

```js
// e2e/constants.js — re-export jestExpect for clarity in test files
// jestExpect is a global injected by detox/runners/jest/testEnvironment
// No import needed — it is available in all test files using that environment
```

**WHY it matters [community]:** This is one of the most common setup errors in projects that
add Detox to an existing codebase that already uses `@jest/globals` imports. The failure
mode is a cryptic `"Matcher error: received value must be a Detox element matcher"` at
runtime — not a compile-time error — so teams spend hours diagnosing what looks like a
version mismatch.

---

### `element.scroll()` with `startPositionX`/`startPositionY` parameters (Detox 20+)

Standard `element.scroll(pixels, direction)` always starts the scroll gesture from the
center of the element. For scroll views where the center contains interactive content
(buttons, inputs, links), the scroll gesture can accidentally trigger a tap instead of a
scroll. Detox 20+ accepts optional `startPositionX` and `startPositionY` (normalized 0–1)
to control where the gesture begins:

```js
// e2e/scroll-from-edge.test.js

it('scrolls a feed without accidentally tapping story cards', async () => {
  // Start scroll from the top-right corner (x=0.9, y=0.1) to avoid tapping cards
  // that occupy the center of the screen
  await element(by.id('stories-feed')).scroll(300, 'down', 0.9, 0.1);

  await waitFor(element(by.id('story-item-15')))
    .toBeVisible()
    .withTimeout(5000);
});

it('scrolls a horizontal carousel from its left edge to avoid button hits', async () => {
  // Carousel has a "skip" button in the center; scroll from left edge (x=0.1)
  await element(by.id('onboarding-carousel')).scroll(200, 'right', 0.1, 0.5);
  await waitFor(element(by.id('slide-2-title')))
    .toBeVisible()
    .withTimeout(3000);
});
```

**API signature:**
```js
// element.scroll(pixels, direction, startPositionX?, startPositionY?)
// startPositionX / startPositionY: normalized 0.0 to 1.0
// (0.0 = left/top edge, 1.0 = right/bottom edge, 0.5 = center — default)
```

**WHY this matters [community]:** On small-screen devices (iPhone SE) or dense list UIs,
the center of a scroll view often sits directly on top of a tappable card or button.
`scroll()` without position args intermittently triggers a tap instead of a swipe —
appearing as a random navigation event that causes subsequent `element not found` failures.

---

### 31. `adjustSliderToPosition()` is iOS-only and silently no-ops on Android [community]

**Root cause**: `adjustSliderToPosition(0–1)` only works on native `UISlider` via the iOS
`Slider` component. On Android, the same call either throws `"method not found"` or
silently does nothing — depending on the Detox version — leaving the slider at its original
value while the test proceeds.

**WHY it's missed**: Teams develop on iOS first and ship the feature. Android tests are
added later (or run on the same test file with `device.getPlatform()`), at which point the
silent failure confuses them because there is no assertion error — just a wrong slider value.

**Fix**: Guard the call with `device.getPlatform()` and use a coordinate-based tap fallback
for Android:

```js
it('sets quality slider to 75%', async () => {
  if (device.getPlatform() === 'ios') {
    // Native slider — deterministic positioning via Detox API
    await element(by.id('quality-slider')).adjustSliderToPosition(0.75);
  } else {
    // Android: calculate pixel offset from element frame and use tapAtPoint
    const attrs = await element(by.id('quality-slider')).getAttributes();
    const x = attrs.frame.width * 0.75;  // 75% from left edge
    const y = attrs.frame.height / 2;
    await element(by.id('quality-slider')).tapAtPoint({ x, y });
  }

  // Verify regardless of platform
  const result = await element(by.id('quality-slider')).getAttributes();
  expect(parseFloat(result.value)).toBeGreaterThan(0.7);
});
```

---

### 32. Custom `testID` collision between inner shadow and outer wrapper [community]

**Root cause**: When a React Native `<View>` wraps a native component (e.g., a Pressable
with ripple, a custom `<Switch>` wrapper), React Native sometimes renders both the outer
JS wrapper and the inner native component with the same `testID`. Detox `element(by.id())`
matches both — `atIndex(0)` gets the outer view, `atIndex(1)` gets the inner component.
Tapping the outer view triggers the tap, but `getAttributes()` on it returns `enabled:
undefined` because the outer View doesn't have the `disabled` prop — only the inner does.

**WHY it's confusing**: `expect(element(by.id('submit-button'))).toBeVisible()` passes
on both indices. But `getAttributes().enabled` returns `undefined` on the wrapper and
`false` on the inner Pressable, causing conditional logic to incorrectly proceed.

**Fix**: Add `testID` only to the innermost interactable component, not the wrapper:

```jsx
// BAD — outer View and inner Pressable both receive testID
<View testID="submit-button">
  <Pressable testID="submit-button" onPress={submit} disabled={isLoading}>
    <Text>Submit</Text>
  </Pressable>
</View>

// GOOD — testID only on the interactive element
<View>
  <Pressable testID="submit-button" onPress={submit} disabled={isLoading}>
    <Text>Submit</Text>
  </Pressable>
</View>
```

```js
// In tests: use .withDescendant() to confirm you matched the right level
await expect(
  element(by.id('submit-button').withAncestor(by.id('form-container')))
).toBeVisible();
const attrs = await element(by.id('submit-button')).getAttributes();
expect(attrs.enabled).toBe(true); // now reliable
```

---

### 33. Detox 20+ default `withTimeout` changed from unlimited to 6000 ms [community]

**Root cause**: Prior to Detox 20, calling `waitFor(element(by.id('x'))).toBeVisible()` without `.withTimeout(ms)` would wait indefinitely (until the Jest test timeout fired). In Detox 20, the default timeout was capped at **6000 ms**. Code that relied on implicit infinite waits — e.g., tests waiting for slow API responses or cold-boot splash screens — now times out at 6 seconds.

**WHY teams hit this**: The migration guide mentions it, but teams often upgrade Detox incrementally (19 → 20.x → 20.y) and miss single changelog entries. The failure looks like a flaky test ("sometimes it times out") rather than a breaking change, especially when CI is slower than local.

**Fix**: Always specify `.withTimeout()` explicitly. Review every `waitFor` in your suite after upgrading to Detox 20:

```bash
# Find all waitFor calls that don't specify withTimeout — audit after Detox 20 upgrade
grep -rn "waitFor" e2e/ | grep -v "withTimeout" | grep -v "//.*waitFor"
```

```js
// BEFORE Detox 20 — implicit infinite wait (breaks in Detox 20+)
await waitFor(element(by.id('splash-screen-done')))
  .not.toBeVisible();  // no timeout — relied on implicit unlimited wait

// AFTER — always explicit
await waitFor(element(by.id('splash-screen-done')))
  .not.toBeVisible()
  .withTimeout(15000);  // 15 s for cold-boot splash
```

**Audit helper**: Run the grep above in CI as a preflight check. Any `waitFor` without `withTimeout` is a latent bug waiting to manifest on Detox 20+.

---

### 34. App foreground/background lifecycle testing with `sendToBackground` / `bringToForeground` [community]

**Root cause**: Many teams test app UI flows but skip background/foreground lifecycle transitions entirely — assuming they "just work". In practice, apps that fail to restore state on foreground (navigation stack lost, session token expired, audio stream stopped) are a significant source of production crashes. `device.sendToBackground()` and `device.bringToForeground()` cover this in Detox without relying on simulator gestures.

**Fix**: Add explicit lifecycle tests for features that must survive backgrounding:

```js
// e2e/lifecycle.test.js
describe('App lifecycle: background + foreground', () => {
  beforeAll(async () => {
    await device.launchApp({
      newInstance: true,
      permissions: { notifications: 'YES' },
    });
  });

  beforeEach(async () => {
    await device.reloadReactNative();
  });

  it('restores the user session after backgrounding and returning', async () => {
    // Log in
    await element(by.id('email-input')).replaceText('user@example.com');
    await element(by.id('password-input')).replaceText('secret123');
    await element(by.id('login-button')).tap();
    await waitFor(element(by.id('home-screen'))).toBeVisible().withTimeout(10000);

    // Background the app (simulates pressing the Home button)
    await device.sendToBackground();

    // Wait to simulate user spending time in another app
    // Use waitFor on a time-anchored condition, NOT setTimeout
    // If there's nothing to wait for, a small Detox action works:
    await device.bringToForeground();

    // App should restore to the home screen (not back to login)
    await waitFor(element(by.id('home-screen')))
      .toBeVisible()
      .withTimeout(8000);

    // Verify session is still valid — user-specific element should be present
    await expect(element(by.id('user-avatar'))).toBeVisible();
  });

  it('pauses a video when backgrounded and resumes when foregrounded', async () => {
    await element(by.id('video-play-button')).tap();
    await waitFor(element(by.id('video-player-playing-indicator')))
      .toBeVisible()
      .withTimeout(3000);

    await device.sendToBackground();
    await device.bringToForeground();

    // Video should resume or remain paused depending on app policy —
    // assert the expected post-foreground state
    await expect(element(by.id('video-player'))).toBeVisible();
  });

  it('discards navigation state only when foregrounded after timeout', async () => {
    // Navigate deep into the app
    await element(by.id('settings-button')).tap();
    await waitFor(element(by.id('settings-screen'))).toBeVisible().withTimeout(3000);

    // Background — then bring back quickly (no session expiry)
    await device.sendToBackground();
    await device.bringToForeground();

    // Navigation stack should still show settings screen
    await waitFor(element(by.id('settings-screen'))).toBeVisible().withTimeout(5000);
  });
});
```

**API notes:**
- `device.sendToBackground()` simulates the Home button press on iOS; on Android, it presses the Home key.
- `device.bringToForeground()` opens the app from the app switcher / recent apps.
- Neither call relaunches the app process — the JS bundle continues from where it left off.
- If the app uses a session expiry timeout (e.g., "lock app after 15 minutes in background"), use `launchArgs` to configure a shorter timeout in test mode.

**[community] gotcha**: On Android, `sendToBackground()` can race with `bringToForeground()` if called in rapid succession — the "app switcher" animation may not complete before `bringToForeground()` fires. Add a `waitFor(element(by.id('home-screen')).not.toBeVisible())` check or use `await device.sendToBackground()` followed by a brief `waitFor` on a background indicator before bringing back to foreground.

---

### 35. `element.tapBackspace()` for clearing secure/masked text fields [community]

**Root cause**: On password fields (`secureTextEntry={true}`), `clearText()` is blocked by iOS security restrictions on the Simulator — the iOS text field suppresses programmatic content replacement when the field is in secure mode. Teams that use `replaceText()` or `clearText()` on password fields find that the action either silently fails or raises a Detox exception. The workaround is to use `tapBackspace()` to delete characters one by one.

**WHY this is painful**: `clearText()` works on all other fields. The password field behavior is inconsistent, and the error message ("Unable to clear text from element") appears only at runtime, not at authoring time.

**Fix**: Use `tapBackspace()` in a loop, or `typeText` combined with select-all:

```js
// e2e/helpers/clearPasswordField.js

/**
 * Clears a secureTextEntry TextInput by selecting all text and deleting it.
 * Use instead of clearText() / replaceText() for password fields.
 *
 * @param {string} testId - The testID of the password field
 * @param {number} maxLength - Maximum characters to delete (default: 50)
 */
async function clearPasswordField(testId, maxLength = 50) {
  const el = element(by.id(testId));
  await el.tap();

  // Select all text (Ctrl+A equivalent on iOS Simulator)
  // iOS: triple-tap selects all text even in secure fields
  await el.multiTap(3);

  // Delete the selection
  await el.tapBackspace();
}

module.exports = { clearPasswordField };
```

```js
// e2e/login.test.js
const { clearPasswordField } = require('./helpers/clearPasswordField');

it('changes password from the settings screen', async () => {
  await element(by.id('settings-tab')).tap();
  await element(by.id('change-password-button')).tap();

  // Fill current password — secure field requires clearPasswordField helper
  await element(by.id('current-password-input')).tap();
  await clearPasswordField('current-password-input');
  await element(by.id('current-password-input')).typeText('oldpass123');

  // replaceText works on non-secure new-password fields in some RN versions
  await element(by.id('new-password-input')).tap();
  await element(by.id('new-password-input')).tapBackspace();  // fallback approach
  await element(by.id('new-password-input')).typeText('newpass456');

  await element(by.id('save-password-button')).tap();
  await waitFor(element(by.id('password-changed-banner')))
    .toBeVisible()
    .withTimeout(5000);
});
```

**Alternative — use `replaceText` with an empty string first**:
Some React Native versions allow `replaceText('')` on secure fields to clear them. If `tapBackspace()` is not available in your Detox version, try:

```js
// Only works on some RN + Detox version combos — test before relying on it
await element(by.id('password-input')).replaceText('');
await element(by.id('password-input')).typeText('newpass456');
```

**[community] NOTE**: On Android emulators, `clearText()` works on most secure fields. The restriction is primarily an iOS Simulator behavior. Always guard with `device.getPlatform()` if you need a cross-platform helper:

```js
async function clearSecureField(testId) {
  const el = element(by.id(testId));
  if (device.getPlatform() === 'ios') {
    await el.multiTap(3);
    await el.tapBackspace();
  } else {
    await el.clearText();
  }
}
```

---

## Additional Patterns (iteration 42 additions)

### Complete GitHub Actions Workflow (Android) [community]

The iOS workflow is documented in CI Considerations. Android requires a fundamentally different setup because the emulator runs on Linux (`ubuntu-22.04`) using the `reactivecircus/android-emulator-runner` action, which manages the AVD lifecycle in CI. Key decisions: set `api-level: 31` (stable, widely available); use `target: google_apis` for apps requiring Google Play Services; pass `-no-window -gpu swiftshader_indirect -no-snapshot -noaudio` to run headlessly without GPU acceleration; extend `AVD_WAIT_TIMEOUT` for cold boot on GitHub-hosted runners.

```yaml
# .github/workflows/e2e-android.yml
name: Detox E2E — Android

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  detox-android:
    runs-on: ubuntu-22.04
    timeout-minutes: 60
    strategy:
      fail-fast: false
      matrix:
        shard: [1, 2]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Setup Java 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Android SDK
        uses: android-actions/setup-android@v3

      - name: Cache Android build
        uses: actions/cache@v4
        id: android-build-cache
        with:
          path: android/app/build
          key: android-build-${{ hashFiles('android/**', 'src/**', 'package-lock.json') }}
          restore-keys: android-build-

      - name: Build Android app (Release)
        if: steps.android-build-cache.outputs.cache-hit != 'true'
        run: npx detox build -c android.emu.release

      - name: Run Detox on Android Emulator (shard ${{ matrix.shard }}/${{ strategy.job-total }})
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 31
          target: google_apis          # required for apps that use Google Play Services
          arch: x86_64
          profile: pixel_6
          avd-name: Pixel_6_API_31
          # CRITICAL: headless flags — GPU SwiftShader required for Linux CI (no hardware GPU)
          emulator-options: >-
            -no-window
            -gpu swiftshader_indirect
            -no-snapshot
            -noaudio
            -no-boot-anim
          disable-animations: true      # action sets global animator duration scale to 0
          script: |
            # Dismiss keyguard before running tests (emulator always boots locked)
            adb shell wm dismiss-keyguard || true
            # Forward host port 8088 to emulator (for local mock server)
            adb reverse tcp:8088 tcp:8088 || true
            # Run the shard
            npx detox test \
              -c android.emu.release \
              --shard-index ${{ matrix.shard }} \
              --shard-count ${{ strategy.job-total }} \
              --loglevel verbose \
              --artifacts-location .artifacts \
              --forceExit

      - name: Upload test artifacts on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: detox-android-artifacts-shard-${{ matrix.shard }}
          path: .artifacts/
          retention-days: 7
```

```js
// .detoxrc.js — Android Release configuration for CI
apps: {
  'android.debug': {
    type: 'android.apk',
    binaryPath: 'android/app/build/outputs/apk/debug/app-debug.apk',
    build: 'cd android && ./gradlew assembleDebug assembleAndroidTest -DtestBuildType=debug && cd ..',
    reversePorts: [8088],   // adb reverse tcp:8088 applied automatically by Detox
  },
  'android.release': {
    type: 'android.apk',
    binaryPath: 'android/app/build/outputs/apk/release/app-release.apk',
    build: 'cd android && ./gradlew assembleRelease assembleAndroidTest -DtestBuildType=release && cd ..',
    reversePorts: [8088],
  },
},
devices: {
  emulator: {
    type: 'android.emulator',
    device: { avd: 'Pixel_6_API_31' },
    bootArgs: '-no-window -gpu swiftshader_indirect -no-snapshot -noaudio -no-boot-anim',
    headless: true,
  },
},
configurations: {
  'android.emu.debug':   { device: 'emulator', app: 'android.debug' },
  'android.emu.release': { device: 'emulator', app: 'android.release' },
},
```

**Key differences from iOS workflow:**
- `ubuntu-22.04` instead of `macos-14` — significantly cheaper (Linux runners cost ~10% of macOS)
- `reactivecircus/android-emulator-runner@v2` manages the entire emulator lifecycle (create, boot, wait, teardown)
- `disable-animations: true` in the action sets `anim_duration_scale` to 0 via ADB — equivalent to iOS's `launchArgs: { detoxDisableAnimations: 'true' }`, but applied at the OS level
- `reversePorts` in the app config triggers `adb reverse` automatically instead of requiring a manual CI step
- Shard count is lower (2 not 3) — Android emulators are slower on Linux CI; parallel emulators on a single `ubuntu-22.04` runner are unstable above 2

---

### Pattern 27 — MSW (Mock Service Worker) for React Native as a network mock layer

[`msw`](https://mswjs.io/docs/integrations/react-native) natively supports React Native via its `react-native` integration (MSW 2.x+). Rather than running a standalone mock server in `globalSetup`, you can define request handlers in JavaScript that intercept `fetch`/`XMLHttpRequest` calls at the JS layer without any port-forwarding or server lifecycle management. This approach works on both iOS Simulator and Android Emulator without `adb reverse`.

```js
// e2e/mocks/handlers.js
const { http, HttpResponse } = require('msw');

const handlers = [
  http.get('https://api.myapp.com/products', ({ request }) => {
    return HttpResponse.json([
      { id: 1, name: 'Widget A', price: 9.99 },
      { id: 2, name: 'Widget B', price: 14.99 },
    ]);
  }),

  http.post('https://api.myapp.com/auth/login', async ({ request }) => {
    const { email } = await request.json();
    if (email === 'test@example.com') {
      return HttpResponse.json({ token: 'mock-jwt-token-abc123', userId: 42 });
    }
    return HttpResponse.json({ error: 'Invalid credentials' }, { status: 401 });
  }),

  // Simulate a network error for error-state tests
  http.get('https://api.myapp.com/flaky-endpoint', () => {
    return HttpResponse.error();
  }),
];

module.exports = { handlers };
```

```js
// e2e/mocks/setup.js — register MSW server before Detox app launches
const { setupServer } = require('msw/node');
const { handlers } = require('./handlers');

const server = setupServer(...handlers);

// Start MSW in globalSetup
async function startMSW() {
  server.listen({ onUnhandledRequest: 'warn' });
  return server;
}

// Add test-specific overrides at runtime
function addHandler(handler) {
  server.use(handler);
}

// Reset to default handlers between tests
function resetHandlers() {
  server.resetHandlers();
}

function stopMSW() {
  server.close();
}

module.exports = { startMSW, addHandler, resetHandlers, stopMSW };
```

```js
// e2e/globalSetup.js (Detox globalSetup)
const { startMSW } = require('./mocks/setup');

module.exports = async () => {
  global.__mswServer = await startMSW();
};

// e2e/globalTeardown.js
const { stopMSW } = require('./mocks/setup');

module.exports = async () => {
  stopMSW();
};
```

```js
// e2e/products.test.js — override handlers per-test
const { http, HttpResponse } = require('msw');
const { addHandler, resetHandlers } = require('./mocks/setup');

describe('Product list', () => {
  afterEach(async () => {
    resetHandlers();  // restore defaults after each test
    await device.reloadReactNative();
  });

  it('shows the product list on success', async () => {
    // Default handler returns 2 products — no override needed
    await element(by.id('products-tab')).tap();
    await waitFor(element(by.id('product-item-1'))).toBeVisible().withTimeout(5000);
    await waitFor(element(by.id('product-item-2'))).toBeVisible().withTimeout(3000);
  });

  it('shows an error message when the API returns 500', async () => {
    // Override the products endpoint to simulate a server error
    addHandler(
      http.get('https://api.myapp.com/products', () =>
        HttpResponse.json({ error: 'Internal Server Error' }, { status: 500 })
      )
    );

    await element(by.id('products-tab')).tap();
    await waitFor(element(by.id('products-error-banner'))).toBeVisible().withTimeout(5000);
    await expect(element(by.id('retry-button'))).toBeVisible();
  });
});
```

**When to prefer MSW over a local mock server:**
- When your app uses `fetch` or `axios` (MSW intercepts at the JS layer — no `adb reverse` needed)
- When you want per-test handler overrides without restarting the server
- When tests need to simulate error states, network delays, or partial responses in isolation

**When to prefer a standalone local mock server (Pattern 11):**
- When your app uses a native HTTP client (OkHttp, NSURLSession) bypassing the JS layer
- When you need WebSocket mock support (MSW WebSocket support requires MSW 2.3+)

**Limitation [community]:** MSW for React Native intercepts only `fetch`/`XMLHttpRequest`. Native modules that use `URLSession` (iOS) or `OkHttp` (Android) directly bypass the MSW interceptor. If your RN library uses a native HTTP client, combine MSW with `device.setURLBlacklist()` for the native calls.

---

### 36. Android emulator hardware acceleration missing on Linux CI — `swiftshader_indirect` is mandatory [community]

**Root cause**: GitHub Actions `ubuntu-22.04` runners (and most Linux CI providers) do not have a physical GPU or hardware KVM acceleration for the Android Emulator's GPU rendering. The emulator falls back to software rendering automatically, but it defaults to `swiftshader` (single-threaded), not `swiftshader_indirect` (multi-threaded). The difference matters: on a single-threaded SwiftShader renderer, heavy list animations and map views trigger the same "animation running" idle-detection deadlock as Lottie animations (Gotcha 6), because the rendering pipeline blocks the Android UI thread.

**WHY it's missed**: Teams that test on macOS CI runners (GitHub's `macos-14` has a GPU) see no issues. When they migrate to Linux for cost savings, tests that previously passed intermittently start timing out, but only on screens with complex views (maps, charts, FlatList with many items).

**Mandatory emulator flags for Linux CI:**

```bash
# These flags must be passed to the emulator binary when running on Linux CI
# without hardware GPU acceleration:
-no-window          # headless — no X11 display required
-gpu swiftshader_indirect   # multi-threaded SwiftShader (NOT plain 'swiftshader')
-no-snapshot        # disable snapshot loading/saving — snapshots fail on headless boot
-noaudio            # disable audio processing — reduces CPU overhead
-no-boot-anim       # disable boot animation — shaves 5–10s off cold boot
```

**Via `.detoxrc.js` device bootArgs:**

```js
devices: {
  emulator: {
    type: 'android.emulator',
    device: { avd: 'Pixel_6_API_31' },
    // Passed directly to the emulator binary at boot
    bootArgs: '-no-window -gpu swiftshader_indirect -no-snapshot -noaudio -no-boot-anim',
    headless: true,
  },
},
```

**Via `reactivecircus/android-emulator-runner` in GitHub Actions:**

```yaml
- uses: reactivecircus/android-emulator-runner@v2
  with:
    api-level: 31
    arch: x86_64
    emulator-options: >-
      -no-window
      -gpu swiftshader_indirect
      -no-snapshot
      -noaudio
      -no-boot-anim
    disable-animations: true
    script: npx detox test -c android.emu.release --forceExit
```

**Verify the flag is working:** Run `adb shell getprop qemu.gles` inside the runner — it should return `2` (software rendering active) rather than `0` (no GLES) or `-1` (hardware, not applicable on Linux CI). If `getprop qemu.gles` returns `0`, the emulator will crash on any OpenGL call and your tests will fail at app launch with a black screen.

---

### 37. React Native 0.76+ New Architecture enabled by default — testID bridging regressions [community]

**Root cause**: React Native 0.76 (released November 2024) enabled the New Architecture (Fabric renderer + JSI, no legacy Bridge) by default for new projects. This has a direct impact on Detox's ability to find elements by `testID`:

1. **Third-party Fabric components without `getTestID()` native implementation** — Any React Native library that bridges a native view must explicitly implement `getTestID()` in its Fabric component spec (`.js` codegen spec). If it doesn't, `by.id('testID')` returns zero matches even though the element is visible on screen. This is more common in community libraries (e.g., `react-native-maps`, `react-native-camera`, custom chart libraries) than in React Native core.

2. **Concurrent rendering race conditions** — Fabric's concurrent rendering model can render components in off-screen stages before committing them to the screen. During these pre-commit phases, the element exists in the accessibility tree but is not yet visible. Tests that call `element(by.id('x')).tap()` immediately after a navigation transition may hit the pre-commit element rather than the committed one.

3. **`by.type()` type names changed in Fabric** — In the legacy renderer, `by.type('RCTView')` matched plain `<View>` components. In Fabric, plain `<View>` is bridged as `RCTViewComponentView` (iOS) or `ReactViewGroup` (Android). Any test that uses `by.type()` on core components needs updating after migrating to New Architecture.

**Gotcha: Diagnosing New Architecture testID failures:**

```bash
# Check if New Architecture is enabled in your project
cat android/gradle.properties | grep newArchEnabled
# Should show: newArchEnabled=true (0.76+ default) or newArchEnabled=false (opt-out)

cat ios/Podfile | grep -i "fabric\|new_arch"
# Should show: ENV['RCT_NEW_ARCH_ENABLED'] = '1' (enabled) or absent (disabled)
```

```js
// .detoxrc.js — run parallel configurations for both architectures during migration
configurations: {
  'ios.sim.release.oldarch': {
    device: 'simulator',
    app: 'ios.oldarch',  // built with RCT_NEW_ARCH_ENABLED=0
  },
  'ios.sim.release.newarch': {
    device: 'simulator',
    app: 'ios.newarch',  // built with RCT_NEW_ARCH_ENABLED=1
  },
},
```

**Fix for third-party Fabric components without testID support:**

```jsx
// Wrap the Fabric component in a native View that provides testID bridging
// Native <View> always bridges testID correctly regardless of architecture

// BAD — react-native-maps MapView may not forward testID in Fabric
<MapView testID="map-view" region={region} />

// GOOD — wrap in a native View for reliable testID bridging
<View testID="map-view" style={StyleSheet.absoluteFill} pointerEvents="box-none">
  <MapView region={region} />
</View>
```

**Fix for `by.type()` after New Architecture migration:**

```js
// Check actual type after migration using captureViewHierarchy
// then update type selectors:

// OLD (legacy Bridge renderer, RN < 0.76)
await element(by.type('RCTView').and(by.id('card-container'))).tap();

// NEW (Fabric renderer, RN 0.76+)
// Option 1: switch to by.id() — preferred
await element(by.id('card-container')).tap();

// Option 2: if testID cannot be added, check actual type via hierarchy dump
// iOS Fabric: 'RCTViewComponentView' | Android Fabric: 'ReactViewGroup'
await element(by.type('RCTViewComponentView').and(by.label('Card Container'))).tap();
```

**Mitigation strategy for gradual New Architecture adoption:**

```bash
# .github/workflows/e2e-ios.yml — matrix across both architectures
strategy:
  matrix:
    arch: [old, new]
    include:
      - arch: old
        config: ios.sim.release.oldarch
        rn_new_arch: '0'
      - arch: new
        config: ios.sim.release.newarch
        rn_new_arch: '1'
steps:
  - name: Build iOS (${{ matrix.arch }} arch)
    run: |
      export RCT_NEW_ARCH_ENABLED=${{ matrix.rn_new_arch }}
      npx detox build -c ${{ matrix.config }}
  - name: Run Detox tests
    run: npx detox test -c ${{ matrix.config }} --loglevel verbose
```

---

### 38. `device.reverseTcp()` vs `reversePorts` configuration: Android network routing gotchas [community]

**Root cause**: Android emulators cannot reach the host machine's `localhost` directly — the emulator's network stack routes through a virtual router where `10.0.2.2` is the host's loopback adapter. If your mock server binds on `localhost:8088`, calling `http://localhost:8088` from inside the app returns `ECONNREFUSED`. Teams commonly discover this only after Android tests fail with "API call failed" while iOS tests pass fine.

There are three ways to handle this, each with different tradeoffs:

**Option 1: `adb reverse` per-run (manual)**
```bash
# CI pre-test step: forward host port 8088 to emulator port 8088
adb wait-for-device
adb reverse tcp:8088 tcp:8088
# App can now use 'http://localhost:8088' and it routes to the host
```

**Option 2: `reversePorts` in `.detoxrc.js` (automatic)**
```js
// .detoxrc.js — Detox applies adb reverse automatically at app launch
apps: {
  'android.release': {
    type: 'android.apk',
    binaryPath: '...',
    reversePorts: [8088],  // equivalent to: adb reverse tcp:8088 tcp:8088
  },
},
```
This is the recommended approach — Detox reruns `adb reverse` on every app launch, so the reverse port survives emulator reboots and `device.launchApp({ newInstance: true })` calls.

**Option 3: Use `10.0.2.2` as the host alias (no port-forward)**
```js
// .detoxrc.js — use Android emulator's built-in host alias
apps: {
  'android.release': {
    launchArgs: {
      // Use 10.0.2.2 instead of localhost — resolves to the host machine
      API_BASE_URL: 'http://10.0.2.2:8088',
    },
  },
},
```
Downside: the iOS and Android builds need different `API_BASE_URL` values — add platform detection:

```js
// .detoxrc.js — platform-specific launchArgs
const BASE_URL = process.env.CI
  ? (process.env.PLATFORM === 'android' ? 'http://10.0.2.2:8088' : 'http://localhost:8088')
  : 'http://localhost:8088';

apps: {
  'android.release': { launchArgs: { API_BASE_URL: BASE_URL } },
  'ios.release':     { launchArgs: { API_BASE_URL: 'http://localhost:8088' } },
},
```

**Common symptom of missing reverse port**: The test passes the first Detox action (element visible) but then hangs on the first `waitFor` that expects data from the mock server. `--debug-synchronization 3000` shows `1 network requests in flight: http://localhost:8088/...` — the request is in-flight indefinitely because the connection is refused.

---

---

## Additional Patterns (iteration 43 additions)

### Pattern 28 — `device.getPlatform()` extended: detecting simulator vs physical device

`device.getPlatform()` returns `'ios'` or `'android'`. When you need to additionally distinguish whether the test is running on a simulator/emulator vs a real device (e.g., to skip biometric tests that require real hardware enrollment), combine the platform check with environment variable conventions used by Detox CI configurations:

```js
// e2e/helpers/platform.js
/**
 * Returns the current test platform context.
 * Use for guarding simulator-only or emulator-only APIs.
 */
function isSimulator() {
  return device.getPlatform() === 'ios';  // Detox iOS always runs on Simulator
}

function isEmulator() {
  return device.getPlatform() === 'android';  // Detox Android always runs on Emulator
}

/**
 * Returns true when running in CI (GitHub Actions, Bitrise, CircleCI, etc.)
 * Relies on the CI=true convention followed by all major CI providers.
 */
function isCI() {
  return process.env.CI === 'true';
}

/**
 * Guard for iOS-only Detox APIs that throw on Android:
 * - device.setBiometricEnrollment()
 * - device.matchFace() / device.unmatchFace()
 * - device.setAppearance() (iOS Simulator only)
 * - element.pinch()
 * - by.traits()
 */
function skipIfNotIOS() {
  if (device.getPlatform() !== 'ios') {
    return true;  // signal the test to return early
  }
  return false;
}

module.exports = { isSimulator, isEmulator, isCI, skipIfNotIOS };
```

```js
// e2e/biometrics.test.js — guarded iOS-only test
const { skipIfNotIOS } = require('./helpers/platform');

it('enrolls and matches Face ID on iOS Simulator', async () => {
  if (skipIfNotIOS()) return;  // skip on Android without test error

  await device.setBiometricEnrollment(true);
  await element(by.id('enable-biometrics-button')).tap();
  await device.matchFace();
  await waitFor(element(by.id('biometric-success-screen')))
    .toBeVisible()
    .withTimeout(5000);
  await device.setBiometricEnrollment(false);
});
```

**Why this pattern matters**: Teams with cross-platform test suites frequently see `TypeError: device.setBiometricEnrollment is not a function` on Android CI jobs. The Detox TypeScript types expose these methods without platform restriction, so the error only surfaces at runtime. A centralized helper makes all guards consistent and searchable.

---

### Pattern 29 — Intercepting `console.log`/native logs in tests for debugging

When an element-not-found failure is caused by app-side logic (e.g., a condition gate, a null check that prevents rendering), adding `console.log` statements to the RN code and reading them back in the Detox test helps without requiring `captureViewHierarchy`. Detox forwards React Native JS logs to the test process when the `log` artifact is enabled:

```js
// .detoxrc.js — enable log collection
artifacts: {
  rootDir: '.artifacts',
  plugins: {
    log: { enabled: true },  // captures RN JS logs + native logs
  },
},
```

```bash
# View logs from the most recent test run inline:
npx detox test -c ios.sim.debug --record-logs all --loglevel verbose 2>&1 | grep "RN:"
```

```js
// In RN app code — prefix Detox-relevant logs for easy grep
const detoxLog = (...args) => {
  if (__DEV__ || global.DETOX_MODE === '1') {
    console.log('[RN]', ...args);
  }
};

// Usage inside a component's render-blocking condition:
if (!userData) {
  detoxLog('ProductScreen: userData is null — skipping render of product-list');
  return <LoadingSpinner testID="loading-spinner" />;
}
```

```bash
# In CI: grep the artifact log for diagnostic messages after a failure
cat .artifacts/**/*.log | grep '\[RN\]'
```

**When to use this over `captureViewHierarchy`**:
- `captureViewHierarchy` shows you the current native tree (the "what") — best for selector debugging
- Log inspection shows you the conditional branch taken (the "why") — best for logic debugging
- Use both together: hierarchy confirms the element is absent; logs confirm why the render path skipped it

---

### Pattern 30 — Expo SDK 52+ with Detox (managed workflow)

Expo SDK 52 (released November 2024) introduced significant changes to the managed workflow that affect Detox setup. The primary change is that `expo prebuild` now generates a merged `metro.config.js` using `@expo/metro-config` (distinct from `@react-native/metro-config`). The Expo Babel preset also moved to `babel-preset-expo`, and the default `app.json` `expo.jsEngine` switched to `hermes`.

```bash
# Expo SDK 52 + Detox setup
npx expo install detox expo-modules-core
npm install --save-dev @config-plugins/detox jest jest-circus

# Prebuild (required before detox build)
npx expo prebuild --clean --platform ios
npx expo prebuild --clean --platform android
```

```js
// metro.config.js — Expo SDK 52 format (NOT @react-native/metro-config)
const { getDefaultConfig } = require('expo/metro-config');
const { mergeConfig } = require('@react-native/metro-config');

const expoConfig = getDefaultConfig(__dirname);

// Add Detox-specific resolver for test mocks (optional)
const detoxConfig = {
  resolver: {
    resolveRequest: (context, moduleName, platform) => {
      if (process.env.DETOX_BUILD && moduleName === './analytics') {
        return { filePath: require.resolve('./e2e/mocks/analytics.js'), type: 'sourceFile' };
      }
      return context.resolveRequest(context, moduleName, platform);
    },
  },
};

module.exports = mergeConfig(expoConfig, detoxConfig);
```

```js
// .detoxrc.js — Expo SDK 52 managed workflow
module.exports = {
  testRunner: {
    args: { $0: 'jest', config: 'e2e/jest.config.js' },
    jest: { setupTimeout: 300000 },
  },
  apps: {
    'ios.expo52': {
      type: 'ios.app',
      // After: npx expo prebuild && cd ios && xcodebuild -scheme YourApp ...
      binaryPath: 'ios/build/Build/Products/Release-iphonesimulator/YourApp.app',
      build: 'npx expo run:ios --configuration Release --no-bundler 2>&1 | tail -30',
    },
    'android.expo52': {
      type: 'android.apk',
      binaryPath: 'android/app/build/outputs/apk/release/app-release.apk',
      build: 'npx expo run:android --variant release --no-bundler 2>&1 | tail -30',
      reversePorts: [8088],
    },
  },
  devices: {
    simulator: { type: 'ios.simulator', device: { type: 'iPhone 16' } },
    emulator: { type: 'android.emulator', device: { avd: 'Pixel_8_API_35' } },
  },
  configurations: {
    'ios.expo52.release': { device: 'simulator', app: 'ios.expo52' },
    'android.expo52.release': { device: 'emulator', app: 'android.expo52' },
  },
};
```

**[community] gotcha — Expo SDK 52 `app.json` `jsEngine: "hermes"` is the default.** If your old `app.json` has `"jsEngine": "jsc"` explicitly set and you upgrade to SDK 52 without removing it, Detox tests fail with a JS engine mismatch at boot. The app launches but the Detox synchronization bridge (which uses Hermes's CDP protocol) cannot attach. Fix: remove `"jsEngine"` from `app.json` or set it to `"hermes"` explicitly.

**[community] gotcha — Expo Router 4 (SDK 52) `+not-found.tsx` screens change deep-link test behavior.** SDK 52 ships Expo Router 4 which adds a typed `+not-found` route that returns a 404 screen for unmatched paths. Tests using `device.launchApp({ url: 'myapp:///products/42' })` must use the triple-slash path format. If the app redirects to the `+not-found` screen, the test is using the wrong URL format (double-slash vs triple-slash) or the route file doesn't exist yet.

---

### Pattern 31 — `testRunner.jest.bail` for fail-fast CI pipelines

Detox's `testRunner` accepts a `bail` option that causes Jest to stop running new test suites after N test suite failures. Unlike `--bail` passed to Jest directly (which stops after the first failing test anywhere), the Detox-level `bail` operates at the suite (file) level:

```js
// .detoxrc.js — bail after 2 suite failures in CI (do not bail locally)
module.exports = {
  testRunner: {
    args: {
      $0: 'jest',
      config: 'e2e/jest.config.js',
      bail: process.env.CI ? 2 : 0,  // 0 = run all; N = stop after N failures
      forceExit: true,
    },
    jest: {
      setupTimeout: 300000,
    },
    retries: process.env.CI ? 1 : 0,
  },
  // ...
};
```

**When to use `bail`**: In CI pipelines where the first two failures strongly indicate a systemic problem (simulator crashed, binary stale, network mock server down) rather than individual test flakiness. Bailing early saves CI runner minutes and surfaces the root cause faster because the first failure's logs are not buried under 50 more timeouts.

**When NOT to use `bail`**: During local development or when running sharded CI jobs — bailing in a shard skips tests that other shards might have passed, giving an incomplete picture.

**Interaction with `retries`**: When `retries: 1` is set alongside `bail: 2`, Detox retries each failed suite once before counting it toward the bail threshold. A suite must fail both attempts to count as a failure.

---

### Pattern 32 — `device.setLocation()` iOS 17+ permission requirements

iOS 17 tightened location permission enforcement in the Simulator. On iOS 17+, calling `device.setLocation(lat, lon)` without the app having an active "Always" location authorization causes the call to silently fail — the GPS coordinates are set at the OS level but the app never receives the location update because the `CLLocationManager` authorization was not granted at the right level.

```js
// CORRECT — grant 'always' (not 'inuse') when using device.setLocation() for persistent updates
beforeAll(async () => {
  await device.launchApp({
    newInstance: true,
    permissions: {
      location: 'always',  // NOT 'inuse' — 'inuse' only works while app is foregrounded
    },
  });
});

it('shows weather for San Francisco', async () => {
  // Grant 'always' permission before setLocation for reliable updates on iOS 17+
  await device.setLocation(37.7749, -122.4194);

  await element(by.id('get-weather-button')).tap();
  await waitFor(element(by.id('weather-card-sanfrancisco')))
    .toBeVisible()
    .withTimeout(8000);
});

// For "inuse" permission, wrap setLocation in a foreground-ensured context:
it('shows weather only when app is active (inuse permission)', async () => {
  await device.launchApp({
    newInstance: true,
    permissions: { location: 'inuse' },
  });

  // Ensure app is foregrounded before location call
  await waitFor(element(by.id('home-screen'))).toBeVisible().withTimeout(5000);
  await device.setLocation(37.7749, -122.4194);  // only works while app is in foreground
  await element(by.id('get-weather-button')).tap();
  await waitFor(element(by.id('weather-card-sanfrancisco'))).toBeVisible().withTimeout(8000);
});
```

**iOS 17+ `by.system()` dialog label change [community]**: iOS 17 changed the "Allow Once" and "Allow While Using App" button label text in location permission dialogs. Teams that use `by.system().label('Allow While Using App')` find their tests fail on iOS 17 simulators because the label is now `'Allow While Using'` (without "App") on some locale configurations. Fix: use `launchApp({ permissions: { location: 'always' } })` to pre-grant and never encounter the dialog. If you must use `by.system()`, test the exact label on your target simulator first via `captureViewHierarchy`.

---

### Pattern 33 — `by.text()` with partial/normalized matching (Detox 20.9+)

Detox 20.9+ added support for `by.text()` matching against normalized whitespace and optional partial matching. This is useful when text content includes line breaks, extra spaces, or dynamic content (e.g., "Order #12345" where the number is dynamic):

```js
// Exact text match (default) — fails if whitespace differs
await element(by.text('Order confirmed')).tap();

// Partial text match using .and() with substring approach:
// (Detox does not expose a built-in "contains" matcher, but you can combine
// by.id() narrowing with getAttributes() for partial text assertions)
it('verifies dynamic order confirmation text', async () => {
  await waitFor(element(by.id('order-confirmation-text')))
    .toBeVisible()
    .withTimeout(5000);

  // Read the text and assert it contains the expected prefix
  const attrs = await element(by.id('order-confirmation-text')).getAttributes();
  jestExpect(attrs.text).toMatch(/^Order #\d+/);  // regex match on dynamic order number
});

// Alternative: when the element count is known, use toHaveText() with a fixed prefix:
it('verifies all item rows show price', async () => {
  const listAttrs = await element(by.id('price-label')).getAttributes();
  const prices = (listAttrs.elements ?? [listAttrs]).map(el => el.text);
  prices.forEach(price => {
    jestExpect(price).toMatch(/^\$[\d.]+$/);  // every price should be "$N.NN"
  });
});
```

**Pattern: Numeric value assertion without exact text matching**

When an element displays a formatted number (currency, percentage, count) that includes locale-specific formatting, avoid `toHaveText('$1,234.56')` — use `getAttributes()` + regex or numeric parsing:

```js
it('displays the order total in the correct currency format', async () => {
  const attrs = await element(by.id('order-total')).getAttributes();
  // Strip currency symbol and commas before parsing
  const total = parseFloat(attrs.text.replace(/[$,]/g, ''));
  jestExpect(total).toBeGreaterThan(0);
  jestExpect(total).toBeLessThan(10000);  // sanity check
});
```

---

### Pattern 34 — `device.clearUserNotifications()` for notification isolation

When multiple test suites trigger `sendUserNotification()`, undelivered notifications from a previous suite can appear in the next suite's notification center, causing ghost notification banner appearances that interfere with `waitFor` assertions. `device.clearUserNotifications()` (available in Detox 20+) purges all pending and delivered notifications from the simulator/emulator before a test suite runs:

```js
// e2e/setup.js or in beforeAll blocks for notification-sensitive suites
beforeAll(async () => {
  await device.launchApp({ newInstance: true });

  // Clear any notifications from previous test runs or suites
  // Prevents ghost notification banners from triggering unexpected waitFor resolutions
  if (device.getPlatform() === 'ios') {
    await device.clearUserNotifications();
  }
});

// In afterAll: clear notifications so they don't leak into the next suite
afterAll(async () => {
  if (device.getPlatform() === 'ios') {
    await device.clearUserNotifications();
  }
  await device.terminateApp();
});
```

**[community] gotcha**: Notification banners from a previous `sendUserNotification()` call can remain on-screen for 3–5 seconds (the iOS default banner duration). If the next test expects `toBeVisible()` on a banner element and a stale banner from the previous test is still fading out, the assertion may resolve against the wrong notification. Using `clearUserNotifications()` in `afterAll` prevents this. If the API is unavailable in older Detox versions, use `device.reloadReactNative()` — the JS bundle reload dismisses any active banners.

---

### Pattern 35 — Reducing Detox test suite cold-start time with `launchApp` `userDefaults`

The `launchApp` `userDefaults` option (distinct from `launchArgs`) writes `NSUserDefaults` values into the simulator before the app launches. This is faster than using a native module bridge to read `launchArgs` and is the preferred way to inject feature flags, locale settings, and onboarding-skip tokens in iOS tests:

```js
// e2e/setup.js — inject user defaults to skip onboarding on every launch
beforeAll(async () => {
  await device.launchApp({
    newInstance: true,
    // userDefaults: written directly to NSUserDefaults before app starts
    // Key-value pairs — values can be strings, booleans, integers, or doubles
    userDefaults: {
      hasCompletedOnboarding: true,     // boolean → stored as NSNumber (BOOL)
      selectedLocale: 'en-US',          // string → stored as NSString
      featureFlagNewCheckout: 1,        // integer → stored as NSNumber (int)
      lastSyncTimestamp: 0,             // integer → resets sync state
    },
    permissions: { notifications: 'YES' },
  });
});
```

```js
// In RN app — read defaults with @react-native-async-storage or react-native-default-preference
// But for NSUserDefaults: use NativeModules.RNCAsyncStorage or a custom native module:
import { NativeModules } from 'react-native';
const defaults = NativeModules.RNUserDefaults; // e.g., react-native-default-preference

if (await defaults.get('hasCompletedOnboarding')) {
  // Skip onboarding — user defaults were injected by Detox
  navigateTo('HomeScreen');
}
```

**Important**: `userDefaults` is iOS-only. For Android, use `launchArgs` which are passed as `Intent` extras. The native equivalent of NSUserDefaults on Android is `SharedPreferences` — accessible via a native module if needed.

**Speed benefit [community]**: Skipping onboarding via `userDefaults` instead of tapping through the onboarding flow saves 15–30 seconds per `beforeAll` block. In a suite with 20 test files, this adds up to 5–10 minutes of CI time savings.

---

### 39. RN 0.77+ Metro bundler `unstable_transformProfile` change breaks Detox Hermes build [community]

**Root cause**: React Native 0.77 (released January 2025) updated the default Metro `transformProfile` from `default` to `hermes-stable`. If your `metro.config.js` explicitly sets `transformer.unstable_transformProfile: 'hermes-canary'` (a config carried over from pre-0.74 projects), the compiled JS bundle includes bytecode optimizations that the stable Hermes version shipped with Detox's test binary cannot execute. The app launches, shows a brief white screen, then crashes with `Error: unrecognized Hermes bytecode version`.

**WHY it's missed**: The crash happens during app launch, not during a test action. Detox's error output shows `App has crashed` without a JS stack trace — making it look like a native crash rather than a bundler mismatch. The crash does not reproduce when running the app normally with Metro (which builds at runtime with the matching Hermes version).

**Diagnostic**:
```bash
# Check the transformer profile in use
cat metro.config.js | grep transformProfile

# Build the app and check the bundle's Hermes bytecode version
npx react-native bundle --platform ios --dev false --bundle-output /tmp/test.jsbundle
head -c 8 /tmp/test.jsbundle | xxd  # first 4 bytes should match expected Hermes magic
```

**Fix**: Remove the explicit `transformProfile` setting and let Metro derive it from the React Native version:

```js
// metro.config.js — DO NOT set transformProfile explicitly in RN 0.77+
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

const defaultConfig = getDefaultConfig(__dirname);

const config = {
  transformer: {
    // Remove: unstable_transformProfile: 'hermes-canary',  // ← DELETE THIS
    // Let Metro inherit the profile from the RN version default
  },
};

module.exports = mergeConfig(defaultConfig, config);
```

---

### 40. `waitFor` chaining multiple conditions causes silent first-condition resolution [community]

**Root cause**: Some teams attempt to chain multiple `waitFor` conditions on the same element in a single statement, expecting AND-semantics:

```js
// BROKEN — this does NOT assert both conditions simultaneously
// The second .toBeVisible() REPLACES the first — only the final assertion is evaluated
await waitFor(element(by.id('submit-button')))
  .toBeVisible()
  .toBeEnabled()   // ← silently overrides the previous .toBeVisible()
  .withTimeout(5000);
```

Detox's fluent API is designed for a single terminal condition per `waitFor` call. Each assertion method (`.toBeVisible()`, `.toExist()`, `.toHaveText()`) replaces the previous — it does not combine them. The above code waits only for the `enabled` state, not for visibility.

**WHY this breaks silently**: The code runs without a compile-time or runtime error. The test "passes" even if the button is enabled but off-screen, because the visibility assertion was never evaluated.

**Fix**: Use separate `waitFor` calls for each condition, or use `expect()` for the secondary assertion:

```js
// CORRECT — sequential waitFor calls for compound readiness
it('waits for submit button to be both visible and enabled', async () => {
  // 1. Wait for visibility first (element may be in the tree but off-screen)
  await waitFor(element(by.id('submit-button')))
    .toBeVisible()
    .withTimeout(5000);

  // 2. Then confirm enabled state via getAttributes (synchronous check after visibility)
  const attrs = await element(by.id('submit-button')).getAttributes();
  jestExpect(attrs.enabled).toBe(true);

  // 3. Now safe to tap
  await element(by.id('submit-button')).tap();
});

// Alternative: use expect() for the secondary condition (no polling, immediate assertion)
await waitFor(element(by.id('submit-button')))
  .toBeVisible()
  .withTimeout(5000);
await expect(element(by.id('submit-button'))).toBeVisible();  // immediate re-check
// The immediate expect() is redundant here but demonstrates the pattern
```

---

### 41. Android 14+ (`API 34`) permission dialog changes break `by.system()` selectors [community]

**Root cause**: Android 14 (API 34) introduced new permission dialog layouts and changed button labels for camera, microphone, and photos permissions:

- Camera/Microphone: removed "Allow only while using the app" — replaced with "Allow" and "Don't allow" only
- Photos: new three-option dialog ("Allow access to all photos" / "Allow access to selected photos" / "Don't allow")
- Precise Location: now asks separately for "Use precise location" vs "Use approximate location" as a toggle, not a dialog button

If you use `by.system().label('While using the app')` or similar Android-specific labels, these selectors break silently on API 34+ emulators. The test taps nothing and proceeds, leaving the permission in a denied state.

**WHY this bites teams during emulator API level upgrades**: CI pipelines that pin `api-level: 33` are unaffected. When upgrading to `api-level: 34` or `35` for broader coverage, previously passing permission tests start failing — but the failure mode looks like "element not found" on the screen after the permission dialog rather than "couldn't tap the dialog button".

**Fix**: Always pre-grant permissions in `launchApp({ permissions })` — this approach is immune to dialog label changes across all Android API levels:

```js
// PREFERRED — immune to all Android permission dialog label changes
beforeAll(async () => {
  await device.launchApp({
    newInstance: true,
    permissions: {
      camera: 'YES',
      microphone: 'YES',
      photos: 'YES',         // grants full photo access on Android 14+
      location: 'always',
      notifications: 'YES',
    },
  });
});

// FALLBACK — if you must use by.system() on Android, test labels on the exact API level:
// Android 14 (API 34) camera permission dialog:
if (device.getPlatform() === 'android') {
  // Note: exact label depends on API level — test on each target API
  await waitFor(element(by.system().label('Allow'))).toBeVisible().withTimeout(5000);
  await element(by.system().label('Allow')).tap();
}
```

**Android API-level-specific permission label reference:**

| Permission | Android 13 (API 33) | Android 14 (API 34+) |
|---|---|---|
| Camera | "Allow only while using the app" | "Allow" |
| Microphone | "Allow only while using the app" | "Allow" |
| Photos | "Allow" (single) | "Allow access to all photos" |
| Location (fine) | "Allow all the time" | "Allow all the time" (unchanged) |
| Notifications | "Allow" | "Allow" (unchanged) |

---

### 42. `device.installApp()` does not grant permissions — a common multi-app test trap [community]

**Root cause**: When testing cross-app flows with `device.installApp(binaryPath)`, teams assume that the same `permissions` object from `launchApp` also applies to the installed secondary app. It does not. `device.installApp()` installs the binary without launching it and without granting any permissions. The secondary app will show permission dialogs on its first run — disrupting test flow.

**Fix**: After installing the secondary app, launch it once (with `device.launchApp`) to grant permissions, then terminate it, then proceed with the cross-app flow:

```js
// e2e/multi-app.test.js
const SECONDARY_BINARY = process.env.SECONDARY_APP_BINARY || 'ios/build/SecondaryApp.app';
const SECONDARY_BUNDLE_ID = 'com.mycompany.secondaryapp';

beforeAll(async () => {
  // Launch primary app
  await device.launchApp({ newInstance: true, permissions: { notifications: 'YES' } });

  // Install secondary app
  await device.installApp(SECONDARY_BINARY);

  // Grant permissions to secondary app by launching it once with permissions
  // This is required because installApp() does not grant permissions
  await device.launchApp({
    bundleId: SECONDARY_BUNDLE_ID,
    newInstance: true,
    permissions: { notifications: 'YES', camera: 'YES' },
  });

  // Terminate secondary app and re-launch primary
  await device.terminateApp(SECONDARY_BUNDLE_ID);
  await device.launchApp({ bundleId: undefined, newInstance: false });
  // Resume primary app from background (it was backgrounded when secondary launched)
});

afterAll(async () => {
  await device.uninstallApp(SECONDARY_BUNDLE_ID);
});
```

**API note**: `device.launchApp({ bundleId: 'com.other.app' })` launches a different app than the one configured in `.detoxrc.js`. This is available in Detox 20+ and allows per-test app switching without changing the Detox configuration.

---

### 43. Hermes source maps missing in Detox artifact logs cause unreadable crash reports [community]

**Root cause**: When a test fails due to a JS exception in the RN app, Detox's log artifact captures the native crash report. Without Hermes source maps, the crash stack trace shows bytecode addresses (`0x12a4b`) instead of JS function names and line numbers — making production-style crash diagnosis impossible in CI.

**WHY teams miss this**: The app runs fine in development (Metro provides source maps in real time). Only in CI — where the app is built as a Release binary with bundled Hermes bytecode — are the source maps missing. Developers never see the minified stack trace locally.

**Fix**: Generate and store Hermes source maps as part of the release build, then configure the artifact upload to include them:

```bash
# iOS: generate Hermes source map during xcodebuild
xcodebuild \
  -workspace ios/MyApp.xcworkspace \
  -scheme MyApp \
  -configuration Release \
  -sdk iphonesimulator \
  -derivedDataPath ios/build \
  CODE_SIGNING_ALLOWED=NO \
  HERMES_BUNDLE_JAVASCRIPT_ENGINE=hermes \
  | xcpretty

# The source map is generated at:
# ios/build/.../MyApp.app.dSYM/Contents/Resources/DWARF/  (native)
# AND: ios/build/Build/Intermediates.noindex/.../main.jsbundle.map  (Hermes JS)
```

```yaml
# GitHub Actions — save source maps alongside test artifacts
- name: Upload source maps (for crash symbolication)
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: hermes-sourcemaps
    path: ios/build/**/*.jsbundle.map
    retention-days: 7
```

```bash
# Symbolicate a Hermes crash report manually using the source map:
# Install: npm install -g @react-native/hermes-profile-transformer
hermes-profile-transformer \
  --sourcemap ios/build/.../main.jsbundle.map \
  --cpuprofile .artifacts/test-name.cpuprofile \
  > symbolicated-crash.json
```

**For Android**: The Hermes source map is generated at `android/app/build/generated/assets/react/release/index.android.bundle.map`. Include it in the `android-build-cache` artifact or upload it separately alongside the Detox failure artifacts.

---

## Updated Anti-Patterns Checklist (iteration 43 additions)

| Anti-Pattern | Fix |
|---|---|
| `device.setBiometricEnrollment()` called without platform guard | Wrap with `if (device.getPlatform() === 'ios')` — method throws on Android (Gotcha 43-style) |
| `device.setLocation()` with `permissions: { location: 'inuse' }` on iOS 17+ | Use `'always'` permission level for persistent location updates; 'inuse' only works while foregrounded |
| `launchApp({ userDefaults })` used on Android | `userDefaults` is iOS-only; use `launchArgs` for Android |
| Multiple `waitFor` conditions chained in one call (e.g., `.toBeVisible().toExist()`) | Use separate `waitFor` calls — chaining replaces rather than combines conditions (Gotcha 40) |
| `device.installApp()` without post-install permission grant | Launch the installed app once with `permissions` to grant, then terminate before cross-app test |
| `by.system().label('While using the app')` on Android 14+ emulators | Use `launchApp({ permissions })` to pre-grant; dialog labels changed in API 34 (Gotcha 41) |
| `unstable_transformProfile: 'hermes-canary'` in `metro.config.js` on RN 0.77+ | Remove the explicit setting; let Metro derive the profile from the RN version (Gotcha 39) |
| Release build artifacts not including Hermes source maps | Configure xcodebuild to output `.jsbundle.map` and upload alongside failure artifacts (Gotcha 43) |
| `clearUserNotifications()` not called between notification test suites | Call in `afterAll` to prevent ghost banners from prior suite (Pattern 34) |
| Feature flag injected via remote config without `launchArgs` override | Use `launchArgs` to short-circuit remote config fetch; prevents idle-detection delays and network dependency |

---

---

## Additional Patterns (iteration 44 additions)

### Pattern 36 — WebView testing with `by.web()` (Detox 20+)

When a React Native app embeds a `<WebView>` component, Detox can interact with DOM
elements inside the WebView using the `by.web()` matcher API introduced in Detox 20.
Web element interactions work on both iOS (WKWebView) and Android (Chromium WebView).

The `by.web()` scope must always be wrapped in a `web(element(...))` call that identifies
the containing WebView element, then `.element(by.web.*matcher*)` to select the DOM node.

```js
// e2e/webview.test.js
// NOTE: WebView testing requires the WebView to have testID set on the RN component.
//       DOM element selectors are matched INSIDE the WebView's page context.

describe('Embedded WebView interactions', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  beforeEach(async () => {
    await device.reloadReactNative();
  });

  it('types into a web form inside a WebView', async () => {
    await element(by.id('open-webview-button')).tap();
    await waitFor(element(by.id('embedded-webview'))).toBeVisible().withTimeout(5000);

    // Select the WebView container by its native testID
    const webview = web(element(by.id('embedded-webview')));

    // Fill a web form field using the DOM element's id
    await webview.element(by.web.id('username')).tap();
    await webview.element(by.web.id('username')).typeText('testuser@example.com');

    // Fill password field by CSS class (use id when possible — more stable)
    await webview.element(by.web.className('password-field')).typeText('secret123');

    // Click the web submit button
    await webview.element(by.web.id('login-btn')).tap();

    // Verify the WebView navigated to the success page
    await waitFor(webview.element(by.web.id('welcome-message')))
      .toExist()
      .withTimeout(5000);
  });

  it('scrolls inside a WebView to reach a web element', async () => {
    await element(by.id('open-webview-button')).tap();
    await waitFor(element(by.id('embedded-webview'))).toBeVisible().withTimeout(5000);

    const webview = web(element(by.id('embedded-webview')));

    // scrollToView: scrolls the web page until the element is in the viewport
    await webview.element(by.web.id('terms-section')).scrollToView();
    await webview.element(by.web.id('accept-terms-checkbox')).tap();
  });

  it('reads web element text via getInnerHTML', async () => {
    await element(by.id('open-webview-button')).tap();
    await waitFor(element(by.id('embedded-webview'))).toBeVisible().withTimeout(5000);

    const webview = web(element(by.id('embedded-webview')));

    // getInnerHTML returns the element's innerHTML as a string
    const html = await webview.element(by.web.id('product-description')).getInnerHTML();
    jestExpect(html).toContain('Wireless headphones');

    // getText returns the element's visible text content (no HTML tags)
    const text = await webview.element(by.web.id('product-title')).getText();
    jestExpect(text).toBe('ANC Headphones Pro');
  });

  it('navigates within the WebView and waits for the URL to change', async () => {
    await element(by.id('open-webview-button')).tap();
    await waitFor(element(by.id('embedded-webview'))).toBeVisible().withTimeout(5000);

    const webview = web(element(by.id('embedded-webview')));

    await webview.element(by.web.id('terms-link')).tap();

    // Wait for a DOM element that only exists on the /terms page
    await waitFor(webview.element(by.web.id('terms-heading')))
      .toExist()
      .withTimeout(5000);
  });
});
```

**`by.web` selector priority (most stable → most fragile):**

| Rank | Matcher | API | Notes |
|------|---------|-----|-------|
| 1 | `id` attribute | `by.web.id('el-id')` | Best — `id` attributes rarely change |
| 2 | `testID` attribute | `by.web.testId('testID')` | Maps to `data-testid` on web |
| 3 | XPath | `by.web.xpath('//button[@type="submit"]')` | Reliable for semantic HTML |
| 4 | CSS selector | `by.web.cssSelector('#form .submit-btn')` | Flexible; prefer class+id combos |
| 5 | Class name | `by.web.className('submit-btn')` | Fragile — CSS classes change frequently |
| 6 | Accessibility label (ARIA) | `by.web.label('Submit form')` | Good for ARIA-labeled elements |
| 7 | `href` attribute | `by.web.href('https://...')` | For link validation only |
| 8 | Partial `href` | `by.web.hrefContains('/products')` | Broad but useful for link testing |
| 9 | Visible name | `by.web.name('username')` | `name` attribute on form inputs |

**Key `web()` element APIs:**

| Method | Description |
|--------|-------------|
| `.tap()` | Click/tap the DOM element |
| `.typeText(str)` | Type into an input field |
| `.clearText()` | Clear an input field |
| `.replaceText(str)` | Clear and type |
| `.selectAllText()` | Select all text in an input |
| `.getText()` | Return the element's visible text |
| `.getInnerHTML()` | Return the element's innerHTML |
| `.scrollToView()` | Scroll the page to bring element into viewport |
| `.focus()` | Focus an input element |
| `.moveCursorToEnd()` | Move text cursor to end of input |
| `.runScript(fn)` | Run a JS function with the element as argument |
| `.runScriptAsync(fn)` | Async version of `runScript` |
| `.exists()` | Returns `true`/`false` — unlike `toExist()`, does not throw |

---

### Pattern 37 — Visual regression testing integration with Detox screenshots

Detox does not have a built-in visual diff engine, but `device.takeScreenshot()` combined
with an external image comparison library enables pixel-level regression testing. The
pattern is: capture a baseline screenshot on a known-good build, then compare on every
subsequent run.

```bash
# Install image comparison library (pixelmatch + pngjs are commonly used)
npm install --save-dev pixelmatch pngjs fs-extra
```

```js
// e2e/helpers/visualAssert.js
const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');
const pixelmatch = require('pixelmatch');

const BASELINE_DIR = path.join(__dirname, '..', 'visual-baselines');
const DIFF_DIR = path.join(__dirname, '..', '..', '.artifacts', 'visual-diffs');

/**
 * Captures a screenshot and compares it against a stored baseline.
 * On first run (no baseline exists), saves the screenshot as the new baseline.
 *
 * @param {string} name - Unique snapshot name (e.g., 'login-screen-light-mode')
 * @param {number} threshold - Pixel difference threshold 0–1 (default: 0.1 = 10% mismatch allowed)
 */
async function assertScreenshot(name, threshold = 0.1) {
  const screenshotPath = await device.takeScreenshot(name);
  const baselinePath = path.join(BASELINE_DIR, `${name}.png`);

  if (!fs.existsSync(baselinePath)) {
    // First run: save as baseline
    fs.mkdirSync(BASELINE_DIR, { recursive: true });
    fs.copyFileSync(screenshotPath, baselinePath);
    console.log(`[visual] Baseline saved: ${name}`);
    return;
  }

  // Compare against baseline
  const current = PNG.sync.read(fs.readFileSync(screenshotPath));
  const baseline = PNG.sync.read(fs.readFileSync(baselinePath));

  jestExpect(current.width).toBe(baseline.width);
  jestExpect(current.height).toBe(baseline.height);

  const diff = new PNG({ width: current.width, height: current.height });
  const mismatchedPixels = pixelmatch(
    baseline.data, current.data, diff.data,
    current.width, current.height,
    { threshold }
  );

  const totalPixels = current.width * current.height;
  const mismatchRatio = mismatchedPixels / totalPixels;

  if (mismatchRatio > threshold) {
    // Save diff image for CI review
    fs.mkdirSync(DIFF_DIR, { recursive: true });
    fs.writeFileSync(path.join(DIFF_DIR, `${name}-diff.png`), PNG.sync.write(diff));
    throw new Error(
      `Visual regression: ${name} — ${(mismatchRatio * 100).toFixed(2)}% pixels differ ` +
      `(threshold: ${(threshold * 100).toFixed(0)}%). Diff saved to ${DIFF_DIR}.`
    );
  }

  console.log(`[visual] ${name}: ${mismatchedPixels} pixels differ (${(mismatchRatio * 100).toFixed(2)}%) — PASS`);
}

module.exports = { assertScreenshot };
```

```js
// e2e/visual.test.js
const { assertScreenshot } = require('./helpers/visualAssert');

describe('Visual regression: Login screen', () => {
  beforeAll(async () => {
    await device.launchApp({
      newInstance: true,
      permissions: { notifications: 'YES' },
    });

    // Set deterministic status bar for consistent screenshots
    if (device.getPlatform() === 'ios') {
      await device.setStatusBar({
        time: '9:41',
        batteryLevel: 100,
        batteryState: 'charging',
        wifiBars: 3,
        cellularBars: 4,
        dataNetwork: 'wifi',
      });
    }
  });

  it('login screen matches baseline (light mode)', async () => {
    await waitFor(element(by.id('login-screen'))).toBeVisible().withTimeout(5000);
    await assertScreenshot('login-screen-light', 0.05);
  });

  it('login screen matches baseline (dark mode)', async () => {
    if (device.getPlatform() !== 'ios') return; // device.setAppearance is iOS-only
    await device.setAppearance('dark');
    await waitFor(element(by.id('login-screen'))).toBeVisible().withTimeout(3000);
    await assertScreenshot('login-screen-dark', 0.05);
    await device.setAppearance('light');
  });
});
```

**Updating baselines**: When a legitimate UI change is made, delete the baseline files and let the test run once to regenerate them:

```bash
# Remove baselines for a specific screen to regenerate on next run
rm e2e/visual-baselines/login-screen-*.png

# Remove all baselines (full re-baseline)
rm -rf e2e/visual-baselines/
```

**CI integration**: Add baseline files to version control so every CI run compares against
the same committed baseline:

```yaml
# GitHub Actions — upload visual diffs as artifacts on failure
- name: Upload visual diffs
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: visual-regression-diffs
    path: .artifacts/visual-diffs/
    retention-days: 7
```

---

### Pattern 38 — JUnit XML test reporting for CI test management integration

Detox's default Jest reporter outputs console logs. For integration with CI test management
systems (Jenkins, TCMS, Azure DevOps Test Plans, Allure), produce a JUnit XML report using
`jest-junit`. The XML format is universally accepted by test management systems.

```bash
npm install --save-dev jest-junit
```

```js
// e2e/jest.config.js — add jest-junit alongside Detox reporter
const isCI = process.env.CI === 'true';

module.exports = {
  rootDir: '..',
  testMatch: ['<rootDir>/e2e/**/*.test.js'],
  testTimeout: 120000,
  retryTimes: isCI ? 1 : 0,
  globalSetup: 'detox/runners/jest/globalSetup',
  globalTeardown: 'detox/runners/jest/globalTeardown',
  testEnvironment: 'detox/runners/jest/testEnvironment',
  reporters: [
    'detox/runners/jest/reporter',           // required for Detox lifecycle
    ...(isCI ? [['jest-junit', {
      // Shard-specific output file: avoids collision when multiple shards run in parallel
      outputDirectory: '.artifacts',
      outputName: `junit-shard-${process.env.SHARD_INDEX || '1'}.xml`,
      classNameTemplate: '{classname}',
      titleTemplate: '{title}',
      ancestorSeparator: ' › ',
      addFileAttribute: 'true',
    }]] : []),
  ],
};
```

```yaml
# GitHub Actions — publish JUnit results for the Tests tab
- name: Run Detox E2E (shard ${{ matrix.shard }})
  run: |
    npx detox test \
      -c ios.sim.release \
      --shard-index ${{ matrix.shard }} \
      --shard-count ${{ strategy.job-total }} \
      --loglevel verbose
  env:
    SHARD_INDEX: ${{ matrix.shard }}

- name: Publish test results
  if: always()  # publish even on failure to see which tests failed
  uses: EnricoMi/publish-unit-test-result-action@v2
  with:
    files: .artifacts/junit-*.xml
    check_name: Detox E2E Results (Shard ${{ matrix.shard }})
    comment_mode: off  # don't comment on every PR; just add a check
```

**Test suite classification for JUnit**: `jest-junit` uses the `describe()` name as the
`classname` and the `it()` name as the `testname`. Structure your test files consistently
to get clean JUnit reports:

```js
// e2e/login.test.js — classname will be "Login" in JUnit
describe('Login', () => {
  it('authenticates with valid credentials', async () => { /* ... */ });
  it('shows error for invalid credentials', async () => { /* ... */ });
  it('navigates to password reset', async () => { /* ... */ });
});
```

---

### Pattern 39 — `device.resetContentAndSettings()` for complete iOS Simulator factory reset

`device.resetContentAndSettings()` (available in Detox 20.5+) performs the equivalent
of **Settings → General → Transfer or Reset iPhone → Erase All Content and Settings** on
the iOS Simulator. It wipes all installed apps, user data, Keychain, location history,
and system preferences — returning the simulator to factory state. This is slower than
`delete: true` but more thorough: it also resets system-level state like trusted Bluetooth
devices, Wi-Fi history, and `CoreData` system stores that `delete: true` leaves intact.

```js
// Use only in a globalSetup script — too slow for per-test or per-suite use
// (takes 30–60 seconds on a cold simulator)

// e2e/globalSetup.js — factory-reset the simulator once before the entire run
module.exports = async () => {
  // Only reset on CI to avoid wiping developer simulator state locally
  if (process.env.CI === 'true' && process.env.DETOX_FULL_RESET === '1') {
    // Must be called before Detox boots the device (before any launchApp)
    // This API is not available via the device global — must be called via
    // the Detox internals or via xcrun simctl before the Detox session starts
    const { execSync } = require('child_process');
    const simName = process.env.SIMULATOR_NAME || 'iPhone 15';
    execSync(`xcrun simctl erase "${simName}"`, { stdio: 'inherit' });
    // Wait for the simulator to reboot after erase (10–15 seconds)
    execSync(`xcrun simctl bootstatus "${simName}" -b`, { stdio: 'inherit' });
  }
};
```

```js
// Within a test (Detox 20.5+ device API):
// device.resetContentAndSettings() can also be called from within a test
// It terminates the current app, resets the simulator, and reboots it.
// WARNING: The device is unavailable for 30–60 seconds after this call.
// Use only when 'delete: true' is insufficient.

it('verifies onboarding from a factory-fresh simulator state', async () => {
  // This is a one-off test that requires the simulator to be in pristine state.
  // Run this test in a dedicated CI job where the simulator state is managed externally.
  await device.launchApp({
    delete: true,           // Uninstall + reinstall the test app
    permissions: { notifications: 'YES', location: 'always' },
  });

  // First-launch experience — onboarding should appear
  await waitFor(element(by.id('onboarding-welcome-screen')))
    .toBeVisible()
    .withTimeout(15000);  // Cold-start after fresh install: 10–15 seconds
});
```

**Reset depth comparison:**

| Method | Speed | Clears App Data | Clears Keychain | Clears System State | Use for |
|--------|-------|-----------------|-----------------|---------------------|---------|
| `reloadReactNative()` | <1s | No | No | No | JS-only state reset |
| `launchApp({ newInstance: true })` | 3–5s | No | No | No | Most test suites |
| `launchApp({ delete: true })` | 8–15s | Yes | Yes | No | Onboarding / first-launch tests |
| `xcrun simctl erase` | 30–60s | Yes | Yes | Yes | Factory-state tests, full CI isolation |

---

### Pattern 40 — Per-configuration network synchronization control

Detox's idle detector monitors all network activity by default. Some configurations need
fine-grained control over which network activity counts toward idle detection. The
`networkSynchronization` option in the `.detoxrc.js` configuration block lets you
disable network tracking for specific device configurations — for example, in a
`debug` configuration where Metro's hot-reload websocket should not block tests:

```js
// .detoxrc.js — per-configuration network synchronization
module.exports = {
  testRunner: {
    args: { $0: 'jest', config: 'e2e/jest.config.js' },
    jest: { setupTimeout: 300000 },
  },
  apps: {
    'ios.debug': { type: 'ios.app', binaryPath: 'ios/build/.../Debug-iphonesimulator/MyApp.app' },
    'ios.release': { type: 'ios.app', binaryPath: 'ios/build/.../Release-iphonesimulator/MyApp.app' },
  },
  devices: {
    simulator: {
      type: 'ios.simulator',
      device: { type: 'iPhone 15' },
    },
  },
  configurations: {
    'ios.sim.debug': {
      device: 'simulator',
      app: 'ios.debug',
      // Disable network sync for debug builds to prevent Metro hot-reload WS from blocking
      // Use launchArgs + setURLBlacklist for finer control
      behavior: {
        init: {
          exposeGlobals: true,  // make element/by/waitFor/expect globals available
        },
      },
    },
    'ios.sim.release': {
      device: 'simulator',
      app: 'ios.release',
      // Release config: no Metro WS — full network sync on
    },
  },
  artifacts: {
    rootDir: '.artifacts',
    plugins: {
      screenshot: { shouldTakeAutomaticSnapshots: true, takeWhen: { testFailure: true } },
      log: { enabled: true },
      timeline: { enabled: true },
    },
  },
};
```

For per-test network sync management, the recommended approach is `device.setURLBlacklist()`
(Pattern 10) rather than global `disableSynchronization()` — it targets specific URLs while
keeping Detox sync active for all other network activity:

```js
// Per-test URL blacklist update (Detox 20+): dynamically add URLs mid-test
// This is useful when a test triggers a feature that starts a new SDK's network traffic
it('enables live metrics without blocking idle detection', async () => {
  // Before enabling the feature, blacklist its reporting URL
  await device.setURLBlacklist([
    '.*firebaselogging.*',
    '.*amplitude.*',
    '.*metrics-reporting.*',  // new SDK added by this feature
  ]);

  await element(by.id('enable-live-metrics-toggle')).tap();
  await waitFor(element(by.id('metrics-dashboard'))).toBeVisible().withTimeout(5000);
});
```

---

## Community Gotchas (iteration 44 additions)

### 44. `by.web()` interactions are slower than native — Detox sync does not cover web idle [community]

**Root cause**: Native interactions (`tap()`, `typeText()`) go through Detox's native
instrumentation layer, which waits for the app to idle before executing. `by.web()`
interactions communicate with the WebView via JavaScript evaluation (IPC bridge) — this
happens *outside* Detox's synchronization layer. After a `webview.element(by.web.id('btn')).tap()`,
Detox does not know whether the web page is still processing the click, running animations,
or fetching data. The test proceeds immediately while the web page may still be mid-transition.

**Symptom**: Tests using `by.web()` appear to work locally (where the machine is fast)
but intermittently fail on CI because the web page's JavaScript callback hadn't resolved
before the next assertion fired.

**Fix**: Always follow `by.web()` interactions with an explicit `waitFor` on a DOM element
that only appears after the web action completes:

```js
// UNRELIABLE — taps the web button but proceeds before the web page responds
await webview.element(by.web.id('submit-btn')).tap();
await expect(element(by.id('rn-success-banner'))).toBeVisible(); // may race

// RELIABLE — wait for a DOM element that confirms the web action completed
await webview.element(by.web.id('submit-btn')).tap();
// Wait for a DOM element that appears after form submission
await waitFor(webview.element(by.web.id('submission-confirmation')))
  .toExist()
  .withTimeout(8000);
// Then assert the RN-layer side effects
await waitFor(element(by.id('rn-success-banner'))).toBeVisible().withTimeout(3000);
```

**Why this matters**: Teams that test hybrid apps (WebView-heavy) discover this class of
failure after migrating from manual QA to Detox automation. The root cause is architectural
— `by.web()` was designed for targeted interaction, not for flow-level sync.

---

### 45. Visual regression screenshots fail due to dynamic content (timestamps, counters) [community]

**Root cause**: Screenshot comparison tools (pixelmatch, Applitools, Percy) do pixel-level
diffs. Any element that displays dynamic content — timestamps, elapsed time counters,
notification badges, animated loading indicators, or random test data — will always
differ between the baseline and the test run, causing 100% false-positive failures on
every run.

**WHY teams miss this**: The test works perfectly during local baseline capture (developer
sees the same timestamp), but CI runs hours later — timestamps differ by definition.

**Fix**: Before taking a screenshot for visual regression, replace or hide dynamic elements
using `launchArgs` or test-specific overrides in the app:

```js
// e2e/setup.js — set a fixed "test time" via launchArgs for screenshots
beforeAll(async () => {
  await device.launchApp({
    newInstance: true,
    launchArgs: {
      VISUAL_TEST_MODE: '1',      // app hides timestamps and dynamic counters
      FIXED_TIMESTAMP: '1704067200000', // 2024-01-01T00:00:00Z — always the same
    },
  });
});
```

```js
// In RN component
import { NativeModules } from 'react-native';
const { VISUAL_TEST_MODE, FIXED_TIMESTAMP } = NativeModules.DetoxSync?.launchArgs ?? {};

// If in visual test mode, freeze the displayed timestamp
const displayTime = VISUAL_TEST_MODE === '1'
  ? new Date(parseInt(FIXED_TIMESTAMP)).toLocaleTimeString()
  : new Date().toLocaleTimeString();
```

**Alternative**: Use a visual diff tool that supports "ignore regions" — Applitools calls
these "layout regions", Percy calls them "ignored zones". Configure them to exclude dynamic
elements from the diff computation:

```js
// For Applitools Eyes integration:
await eyes.checkWindow({
  tag: 'Login screen',
  ignore: [
    { selector: '[testid="last-login-timestamp"]' },
    { selector: '[testid="unread-badge"]' },
  ],
});
```

---

### 46. `jest-junit` output file collision when shards write to the same path [community]

**Root cause**: In matrix-sharded CI pipelines (e.g., 3 shards in GitHub Actions matrix),
if all shards write `jest-junit` output to the same filename (e.g., `junit.xml`), the last
shard to finish overwrites the previous shards' results. When the CI system collects artifacts,
only the last shard's test results are visible — the others are silently lost.

**WHY this is painful**: All tests appear to have run, the CI job shows green, but the test
count in the management system is only 1/3 of the actual suite. Teams discover it only
when a flaky test in shard 1 or shard 2 goes undetected.

**Fix**: Use a shard-specific output filename. Pass `SHARD_INDEX` as an environment variable
from the CI job and include it in the `outputName`:

```js
// e2e/jest.config.js — shard-specific JUnit output filename
reporters: [
  'detox/runners/jest/reporter',
  ['jest-junit', {
    outputDirectory: '.artifacts',
    // SHARD_INDEX is set in the CI job step via: env: { SHARD_INDEX: '${{ matrix.shard }}' }
    outputName: `junit-shard-${process.env.SHARD_INDEX || 'local'}.xml`,
  }],
],
```

```yaml
# GitHub Actions — pass SHARD_INDEX to the test step
- name: Run Detox tests
  run: npx detox test -c ios.sim.release --shard-index ${{ matrix.shard }} --shard-count 3
  env:
    SHARD_INDEX: ${{ matrix.shard }}
    CI: 'true'

# Merge all shard results before publishing (optional — most CI systems accept multiple XML files)
- name: Publish JUnit results
  uses: EnricoMi/publish-unit-test-result-action@v2
  with:
    files: .artifacts/junit-shard-*.xml  # glob pattern picks up all shards
```

---

### 47. Android 15 (API 35) predictive back gesture breaks `device.pressBack()` and `by.system()` back detection [community]

**Root cause**: Android 15 (API 35) made the Predictive Back Gesture (introduced as
opt-in in API 33) the default for all apps targeting API 35+. The predictive back animation
shows a preview of the previous screen *before* committing the navigation. Detox's
`device.pressBack()` triggers the back gesture correctly, but the animation preview causes
a brief period where both the current screen and the previous screen are partially visible
— and Detox's idle detector sees two screens rendered simultaneously, holding the app in
a "not idle" state for the duration of the animation (200–350ms).

**Symptoms**:
- `waitFor(element(by.id('previous-screen'))).toBeVisible()` resolves during the predictive
  animation's preview phase (the element is partially visible), then re-fails when the
  animation completes and the screen fully transitions
- `by.system()` back button label has changed from "Back" to an animated arrow icon with
  no text label in some API 35 locales — `by.system().label('Back')` matches nothing

**Fix**: After calling `device.pressBack()` on API 35+, add a `waitFor` on the destination
screen AND assert the source screen is NOT visible, to confirm the transition completed:

```js
it('navigates back from settings to home on Android 15', async () => {
  await element(by.id('settings-tab')).tap();
  await waitFor(element(by.id('settings-screen'))).toBeVisible().withTimeout(5000);

  // Trigger back navigation
  await device.pressBack();

  // Wait for the HOME screen — NOT just "source not visible", as predictive back
  // briefly shows both screens simultaneously during the animation preview
  await waitFor(element(by.id('home-screen')))
    .toBeVisible()
    .withTimeout(5000);

  // Confirm settings screen is fully gone (not just in animation preview)
  await expect(element(by.id('settings-screen'))).not.toBeVisible();
});
```

**Opt-out**: If your app targets API 34 or lower (`targetSdkVersion 34`), predictive back
is not applied. Update your app's `android/app/build.gradle` to use `targetSdkVersion 34`
in your Detox test variant only if API 35 back behavior is causing widespread test failures
and you are not ready to update all tests.

---

### 48. Hermes CDP debugger port (8083) conflicts with parallel iOS CI jobs [community]

**Root cause**: When running a Debug build of a React Native app with Hermes, the Hermes
debugger listens on port 8083 by default. In a CI pipeline that runs multiple Detox jobs
in parallel on the same machine (e.g., using `matrix` with 3 shards sharing a macOS
runner), the second and third shards try to bind to port 8083 for their Hermes debugger
and fail with `EADDRINUSE` — causing the app to hang at launch indefinitely. The first
shard claims the port; subsequent shards timeout at `setupTimeout`.

**WHY this is underdiagnosed**: The error occurs inside the native Hermes layer, not in the
JS thread, so Detox's error log shows `App has not responded in time` rather than a port
conflict. Teams increase `setupTimeout` repeatedly instead of finding the root cause.

**Fix 1**: Use Release builds for CI (recommended — no Hermes debugger port needed):
```bash
npx detox build -c ios.sim.release   # Release: no Hermes CDP listener
npx detox test  -c ios.sim.release
```

**Fix 2**: If Debug builds are required, configure Hermes to use a different port per shard:
```js
// .detoxrc.js — per-shard Hermes port via environment variable
apps: {
  'ios.debug': {
    type: 'ios.app',
    binaryPath: '...',
    launchArgs: {
      // Set HERMES_DEBUGGER_PORT to avoid port collisions on parallel CI jobs
      // Each shard sets this env var to a unique value: 8083, 8084, 8085
      ReactNativeHermesDebuggerPort: process.env.HERMES_DEBUGGER_PORT || '8083',
    },
  },
},
```

```yaml
# GitHub Actions — unique Hermes port per shard
strategy:
  matrix:
    include:
      - shard: 1
        hermes_port: 8083
      - shard: 2
        hermes_port: 8084
      - shard: 3
        hermes_port: 8085
steps:
  - name: Run shard ${{ matrix.shard }}
    env:
      HERMES_DEBUGGER_PORT: ${{ matrix.hermes_port }}
      SHARD_INDEX: ${{ matrix.shard }}
    run: npx detox test -c ios.sim.debug --shard-index ${{ matrix.shard }} --shard-count 3
```

---

### 49. `by.web()` assertions resolve before WebView URL update completes [community]

**Root cause**: When a WebView navigates to a new URL (e.g., after clicking a link or
submitting a form), the `by.web.id()` matcher can match elements from the *previous*
page's DOM that are still in memory during the unload phase. The test asserts against
the old page's elements while the WebView is mid-navigation, passes incorrectly, and
then the subsequent assertions fail because the page has since changed.

**Symptom**: A test for a two-step web form (Step 1 → Step 2) passes the "submit" step
but then fails on "verify Step 2 elements" because by the time the verification fires,
the WebView is still showing Step 1's "thank you" interstitial.

**Fix**: Add a native-layer signal that the WebView has completed the navigation
(e.g., a `testID` on the RN `<WebView>` component that updates its `accessibilityLabel`
or value when the web page load is complete):

```jsx
// RN component: emit navigation state via accessibilityValue
<WebView
  testID="payment-webview"
  accessibilityValue={{ text: currentUrl }}  // update on every URL change
  onNavigationStateChange={({ url }) => setCurrentUrl(url)}
  source={{ uri: paymentUrl }}
/>
```

```js
// In test: wait for the WebView's accessibilityValue to reflect the new URL
it('completes two-step payment flow', async () => {
  const webview = web(element(by.id('payment-webview')));

  // Step 1: submit the payment form
  await webview.element(by.web.id('submit-payment')).tap();

  // Wait for the WebView to navigate to the confirmation URL
  // (WebView's accessibilityValue is updated to the new URL on navigation complete)
  await waitFor(element(by.value('https://payment.example.com/confirm')))
    .toExist()
    .withTimeout(10000);

  // Now safe to assert Step 2 DOM elements — WebView has fully loaded
  await waitFor(webview.element(by.web.id('confirmation-number')))
    .toExist()
    .withTimeout(5000);

  const confirmationText = await webview.element(by.web.id('confirmation-number')).getText();
  jestExpect(confirmationText).toMatch(/^CONF-\d+/);
});
```

---

### 50. React Native 0.78+ `strictMode: true` causes double-render in tests — assertions may see intermediate state [community]

**Root cause**: React Native 0.78 (released March 2025) enabled React 19's `strictMode`
by default for new projects. In Strict Mode, React renders components twice in development
(to help detect side effects). When Detox runs against a Debug build of an RN 0.78+ app,
the double-render can cause an element to briefly appear, disappear, and reappear during
initial mount. A `waitFor(...).toBeVisible()` that fires during the intermediate "hidden"
state fails even though the element becomes visible moments later.

**Symptoms**:
- Tests that pass on Release builds fail on Debug builds of the same code
- `waitFor(element(by.id('welcome-banner'))).toBeVisible().withTimeout(2000)` fails on
  Debug but passes with `withTimeout(5000)` — the doubled render adds ~1–2 seconds

**Fix 1 (recommended)**: Use Release builds for CI Detox tests, where `strictMode` has no
effect (double renders only happen in development mode):

```bash
npx detox build -c ios.sim.release && npx detox test -c ios.sim.release
```

**Fix 2**: Disable Strict Mode in the development build used for Detox:

```jsx
// App.js — disable Strict Mode for Detox runs
const AppContainer = process.env.DETOX_BUILD === '1'
  ? React.Fragment           // no Strict Mode double-renders
  : React.StrictMode;       // full Strict Mode for development

export default function App() {
  return (
    <AppContainer>
      <AppNavigator />
    </AppContainer>
  );
}
```

```js
// .detoxrc.js — set DETOX_BUILD env var during build
apps: {
  'ios.debug.detox': {
    type: 'ios.app',
    build: 'DETOX_BUILD=1 npx detox build -c ios.sim.debug',
    binaryPath: '...',
  },
},
```

**Fix 3**: Increase timeouts for all `waitFor` calls in Debug test configurations using
the CI-aware `TIMEOUT` constants pattern (Pattern 5), adding a separate multiplier for
`strictMode`:

```js
// e2e/constants.js
const IS_CI = process.env.CI === 'true';
const IS_DEBUG_BUILD = process.env.DETOX_CONFIGURATION?.includes('debug') ?? false;

// Debug builds with Strict Mode add ~1-2s overhead per mount due to double-render
const strictModeMultiplier = IS_DEBUG_BUILD ? 2 : 1;

const TIMEOUT = {
  short:  (IS_CI ? 5000  : 2000) * strictModeMultiplier,
  medium: (IS_CI ? 10000 : 3000) * strictModeMultiplier,
  long:   (IS_CI ? 20000 : 5000) * strictModeMultiplier,
  launch: (IS_CI ? 30000 : 10000) * strictModeMultiplier,
};

module.exports = { TIMEOUT, IS_CI, IS_DEBUG_BUILD };
```

---

## Updated Anti-Patterns Checklist (iteration 44 additions)

| Anti-Pattern | Fix |
|---|---|
| `by.web()` interaction followed immediately by a native assertion | Add `waitFor` on a DOM element confirming web action completed before asserting native layer (Gotcha 44) |
| Screenshot comparison without masking dynamic elements (timestamps, badges) | Use `launchArgs: { VISUAL_TEST_MODE: '1' }` to freeze dynamic content; or use per-region ignore in Applitools/Percy (Gotcha 45) |
| `jest-junit` writing all shards to the same `junit.xml` filename | Include `SHARD_INDEX` in `outputName` to produce shard-specific files (Gotcha 46) |
| `device.pressBack()` on Android 15 without verifying full navigation completion | Assert destination screen visible AND source screen not visible; predictive back shows both briefly (Gotcha 47) |
| Using Debug builds for CI Detox tests (Hermes debugger port 8083 conflict) | Use Release builds; or set unique `HERMES_DEBUGGER_PORT` per parallel shard (Gotcha 48) |
| `by.web()` assertion on new page before WebView URL navigation completes | Track WebView URL via `accessibilityValue`; `waitFor` the new URL value before asserting DOM (Gotcha 49) |
| Debug builds on RN 0.78+ with `strictMode: true` causing double-render timing issues | Use Release builds for CI; or disable `React.StrictMode` via `DETOX_BUILD=1` env (Gotcha 50) |
| `device.resetContentAndSettings()` called without re-granting permissions afterward | After factory reset, all app permissions are revoked; call `launchApp({ permissions })` on next launch |
| Visual regression test not normalizing status bar before screenshot | Call `device.setStatusBar({ time: '9:41', batteryLevel: 100, ... })` in `beforeAll` (Gotcha 19) |

---

---

## Additional Patterns (iteration 45 additions)

### Pattern 41 — `by.system()` full dialog workflow: permissions, alerts, and action sheets

Detox's `by.system()` matcher targets OS-level UI that is rendered by the host OS rather
than your app — permission dialogs, system alerts, action sheets (iOS), and the back
navigation confirmation on Android 15+. Because these are system-layer views, Detox's
normal synchronization does not apply; you must use `waitFor` with a generous timeout.

**Key difference from app elements**: System dialogs appear asynchronously in a
separate process (iOS `SpringBoard`, Android `PackageInstaller`). The dialog may not
appear for 500–1000 ms after the app triggers it. Always use `waitFor` before interacting.

```js
// e2e/permissions.test.js
// Pattern: Handling iOS system permission dialogs deterministically

describe('Camera permission flow', () => {
  beforeAll(async () => {
    // Launch WITHOUT pre-granting camera — we want to exercise the dialog
    await device.launchApp({
      newInstance: true,
      permissions: { camera: 'unset' }, // force the dialog to appear
    });
  });

  it('grants camera permission via system dialog', async () => {
    await element(by.id('open-camera-button')).tap();

    // System permission dialog appears in SpringBoard process — wait for it
    await waitFor(element(by.system().label('Camera')))
      .toExist()
      .withTimeout(5000);

    // Tap "Allow" — label text is platform and locale dependent (see Gotcha 51)
    await element(by.system().label('Allow')).tap();

    // App should now show the camera view
    await waitFor(element(by.id('camera-preview')))
      .toBeVisible()
      .withTimeout(5000);
  });
});
```

```js
// e2e/alerts.test.js
// Pattern: Handling app-triggered UIAlertController (iOS) / AlertDialog (Android)
// App code: Alert.alert('Confirm delete', 'Are you sure?', [{text: 'Cancel'}, {text: 'Delete'}])

it('confirms a deletion via native alert', async () => {
  await element(by.id('delete-item-button')).tap();

  // Native Alert — rendered by the OS but tied to the app process.
  // On iOS it appears immediately (within the same JS idle window).
  // Use by.system() only for true SpringBoard dialogs; for Alert.alert() use by.text().
  await waitFor(element(by.text('Are you sure?')))
    .toBeVisible()
    .withTimeout(3000);

  await element(by.text('Delete')).tap();

  await waitFor(element(by.id('empty-state-view')))
    .toBeVisible()
    .withTimeout(3000);
});
```

```js
// e2e/actionSheet.test.js
// Pattern: iOS UIActivityViewController / share sheet (system overlay)
// Note: UIActivityViewController is a SpringBoard overlay — use by.system()

it('interacts with the native share sheet', async () => {
  await element(by.id('share-button')).tap();

  // Share sheet takes 300-800ms to animate in
  await waitFor(element(by.system().type('XCUIElementTypeActivityListView')))
    .toExist()
    .withTimeout(4000);

  // Dismiss the share sheet by tapping Cancel
  await element(by.system().label('Cancel')).tap();

  await waitFor(element(by.system().type('XCUIElementTypeActivityListView')))
    .not.toExist()
    .withTimeout(3000);
});
```

**`by.system()` matcher options:**

| Matcher | Example | Notes |
|---------|---------|-------|
| `.label(text)` | `by.system().label('Allow')` | Matches accessibility label — locale-sensitive |
| `.type(type)` | `by.system().type('XCUIElementTypeButton')` | Matches XCUIElementType (iOS) or Android class |
| `.id(id)` | `by.system().id('com.apple.permission')` | Matches accessibility ID on system views |

**Pre-granting to skip dialogs in non-dialog tests:**
```js
// .detoxrc.js — global permission pre-grant for tests that don't test dialogs
apps: {
  'ios.sim.release': {
    launchArgs: {
      // Pre-grant all permissions so tests that don't care about dialogs are unaffected
    },
  },
}

// OR per-test:
await device.launchApp({
  permissions: {
    camera: 'YES',
    microphone: 'YES',
    photos: 'YES',
    location: 'always',
    notifications: 'YES',
    contacts: 'YES',
    calendar: 'YES',
  },
});
```

---

### Pattern 42 — `device.openURL()` deep link testing

React Native apps commonly support deep links and universal links. Detox provides
`device.openURL()` to trigger the app's `Linking` API handler as if the OS opened a URL.
This is the recommended approach over `adb shell am start -d` (Android) or
`xcrun simctl openurl` (iOS) in shell commands — `device.openURL()` works cross-platform
and correctly handles cold-start vs warm-start scenarios.

```js
// e2e/deepLinks.test.js
// Testing cold-start deep link navigation

const APP_URL_SCHEME = 'myapp'; // matches your RN Linking config

describe('Deep link navigation', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  it('navigates to a product detail screen via deep link (warm start)', async () => {
    // App is already running — openURL simulates the OS opening a link while app is open
    await device.openURL({ url: `${APP_URL_SCHEME}://products/42` });

    await waitFor(element(by.id('product-detail-screen')))
      .toBeVisible()
      .withTimeout(5000);

    await waitFor(element(by.id('product-title')))
      .toHaveText('Product 42')
      .withTimeout(3000);
  });

  it('navigates to the profile screen via deep link', async () => {
    await device.openURL({ url: `${APP_URL_SCHEME}://profile/me` });

    await waitFor(element(by.id('profile-screen')))
      .toBeVisible()
      .withTimeout(5000);
  });
});
```

```js
// e2e/deepLinks.test.js (continued)
// Testing cold-start deep link — app is NOT running when the URL fires

describe('Deep link cold start', () => {
  it('launches to the correct screen when opened via deep link from terminated state', async () => {
    // Terminate the app first so it is not running
    await device.terminateApp();

    // Launch with a URL — Detox passes it to the app on cold start
    await device.launchApp({
      newInstance: true,
      url: `${APP_URL_SCHEME}://products/99`,
    });

    // App boots, processes the initial URL, and navigates to the product screen
    await waitFor(element(by.id('product-detail-screen')))
      .toBeVisible()
      .withTimeout(8000); // cold start is slower — allow more time
  });
});
```

```js
// e2e/universalLinks.test.js
// iOS Universal Links (HTTPS scheme) — requires Associated Domains entitlement
// The simulated URL must match the app's associated domain configuration

describe('Universal link navigation', () => {
  it('handles a universal link for an order confirmation page', async () => {
    // Universal links use HTTPS scheme matching the associated domain
    await device.openURL({
      url: 'https://www.myapp.com/orders/abc123',
      sourceApp: 'com.example.safari', // optional: simulate opening from a specific app
    });

    await waitFor(element(by.id('order-detail-screen')))
      .toBeVisible()
      .withTimeout(5000);

    await waitFor(element(by.id('order-id-label')))
      .toHaveText('#abc123')
      .withTimeout(3000);
  });
});
```

**Cross-platform deep link differences:**

| Platform | Cold-start URL | Warm URL | Universal/App Links |
|----------|---------------|----------|---------------------|
| iOS | `launchApp({ url })` | `device.openURL({ url })` | HTTPS scheme + Associated Domains |
| Android | `launchApp({ url })` | `device.openURL({ url })` | HTTPS scheme + App Links / Intent filters |

**Note on Android Intent extras**: On Android, some deep links carry Intent extras beyond the URL
(e.g., push notification payloads). Use `launchApp({ userActivity })` for these cases or pass
extras via `launchArgs` and read them in `getInitialURL()`.

---

### Pattern 43 — Parallel worker configuration for large test suites

Detox supports parallel test execution via Jest's `--maxWorkers` flag. Each worker
gets a dedicated simulator/emulator instance. For large suites (50+ tests), parallelism
is the single biggest lever for CI time reduction — 8 workers can reduce a 40-minute suite
to under 6 minutes.

```js
// jest.config.js — Detox + Jest parallel configuration
/** @type {import('@jest/types').Config.InitialOptions} */
module.exports = {
  testEnvironment: 'detox/runners/jest/testEnvironment',
  testRunner: 'jest-circus/runner',
  testTimeout: 120000,
  maxWorkers: process.env.CI ? 4 : 2, // 4 workers on CI, 2 locally (less resource pressure)
  verbose: true,
  reporters: [
    'detox/runners/jest/reporter',
    ['jest-junit', {
      outputDirectory: 'artifacts',
      outputName: `junit-${process.env.WORKER_ID || 'single'}.xml`,
    }],
  ],
  testSequencer: './e2e/sequencer.js', // optional: custom ordering
};
```

```js
// .detoxrc.js — worker-aware device pool
/** @type {import('detox').DetoxConfig} */
module.exports = {
  testRunner: {
    args: {
      $0: 'jest',
      config: 'e2e/jest.config.js',
    },
    jest: {
      setupTimeout: 120000,
      bail: process.env.CI ? 1 : 0, // fail-fast on CI
    },
  },
  devices: {
    simulator: {
      type: 'ios.simulator',
      device: { type: 'iPhone 16' },
    },
  },
  apps: {
    ios: {
      type: 'ios.app',
      binaryPath: 'ios/build/Build/Products/Release-iphonesimulator/MyApp.app',
    },
  },
  configurations: {
    'ios.sim.release': {
      device: 'simulator',
      app: 'ios',
      artifacts: {
        rootDir: '.artifacts',
        plugins: {
          instruments: 'none', // disable per-worker instruments to avoid port conflicts
          log: { enabled: true, keepOnlyFailedTestsArtifacts: true },
          screenshot: { mode: 'failure', keepOnlyFailedTestsArtifacts: true },
        },
      },
    },
  },
};
```

```yaml
# GitHub Actions — parallel Detox iOS with matrix sharding
name: Detox iOS
on: [push, pull_request]
jobs:
  detox-ios:
    runs-on: macos-15
    strategy:
      matrix:
        shard: [1, 2, 3, 4]  # 4 shards = 4 parallel jobs
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        run: npm ci

      - name: Build Detox app
        run: npx detox build -c ios.sim.release

      - name: Run Detox tests (shard ${{ matrix.shard }} of 4)
        run: |
          npx detox test \
            -c ios.sim.release \
            --testNamePattern='.*' \
            --shard-index=${{ matrix.shard }} \
            --shard-count=4 \
            --forceExit

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: detox-results-shard-${{ matrix.shard }}
          path: |
            artifacts/
            .artifacts/
```

**Worker isolation rules:**
- Each worker gets its own simulator instance — no state sharing.
- Do NOT use `device.setURLBlacklist()` globally in `beforeAll` across workers without re-applying it in each worker's `beforeAll`. Detox workers each boot a fresh app instance.
- Avoid writing to shared file paths in test helpers (e.g., `fs.writeFileSync('baseline.png', ...)`) — use worker-unique paths based on `process.env.JEST_WORKER_ID`.

---

### Pattern 44 — `by.traits()` iOS accessibility traits testing

iOS accessibility traits are flags set on UI elements to convey their role and state to
assistive technologies (VoiceOver, Switch Control). Detox's `by.traits()` matcher filters
elements by one or more traits, allowing you to verify that your app correctly exposes
semantic metadata — critical for accessibility compliance (WCAG, ADA, Section 508).

This API is **iOS Simulator only** — Android has no direct equivalent; use `by.label()`
or Espresso's AccessibilityChecks for Android accessibility assertions.

```js
// e2e/accessibility.test.js
// Testing that key elements carry correct iOS accessibility traits

describe('Accessibility traits', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  it('verifies that the primary action button is marked as a button trait', async () => {
    if (device.getPlatform() !== 'ios') return; // by.traits() is iOS only

    // 'button' trait confirms VoiceOver will announce this as "Button"
    await expect(
      element(by.id('submit-button').and(by.traits(['button'])))
    ).toBeVisible();
  });

  it('verifies that the loading spinner is marked as adjustable', async () => {
    if (device.getPlatform() !== 'ios') return;

    await element(by.id('refresh-button')).tap();

    // 'adjustable' trait: VoiceOver announces swipe up/down to adjust (e.g. sliders, activity indicators)
    await waitFor(
      element(by.id('loading-indicator').and(by.traits(['adjustable'])))
    )
      .toExist()
      .withTimeout(5000);
  });

  it('verifies that selected state is correct for a tab bar item', async () => {
    if (device.getPlatform() !== 'ios') return;

    await element(by.id('home-tab')).tap();

    // 'selected' trait confirms the tab is currently active
    await expect(
      element(by.id('home-tab').and(by.traits(['selected'])))
    ).toBeVisible();

    // The non-selected tab must NOT have the 'selected' trait
    await expect(
      element(by.id('settings-tab').and(by.traits(['selected'])))
    ).not.toBeVisible();
  });

  it('verifies that disabled controls carry the "disabled" trait', async () => {
    if (device.getPlatform() !== 'ios') return;

    // Navigate to a screen where the submit button is disabled
    await element(by.id('form-screen-link')).tap();

    await expect(
      element(by.id('submit-button').and(by.traits(['notEnabled'])))
    ).toBeVisible();
  });
});
```

**Supported trait values (iOS):**

| Trait constant | Description |
|----------------|-------------|
| `'button'` | Element behaves like a button (tappable to trigger an action) |
| `'link'` | Element opens a URL or navigates on tap |
| `'header'` | Element is a navigation or section header |
| `'searchField'` | Element is a search input |
| `'image'` | Element is a graphic (not interactive by default) |
| `'selected'` | Element is currently selected (checkboxes, tabs) |
| `'playsSound'` | Element triggers audio playback when activated |
| `'keyboardKey'` | Element is a custom keyboard key |
| `'staticText'` | Element only displays text (non-interactive) |
| `'summaryElement'` | Element provides summary info when device is locked |
| `'notEnabled'` | Element is disabled (greyed out, non-interactive) |
| `'adjustable'` | Element responds to swipe up/down to change value (sliders) |
| `'allowsDirectInteraction'` | Element allows multi-finger interactions (e.g. piano keys) |
| `'causesPageTurn'` | Element triggers page turn in a paged scroll view |
| `'frequentUpdates'` | Element updates frequently (live region, e.g. timers) |

---

### Pattern 45 — `element.getAttributes()` extended inspection

`element.getAttributes()` returns a snapshot of an element's current state — visibility,
text value, placeholder, enabled state, focus state, and more. It is the primary escape
hatch when `waitFor` assertions are too coarse: when you need to read a value (not just
assert it), or inspect multiple properties at once without chaining several `expect` calls.

```js
// e2e/formValidation.test.js
// Using getAttributes() to inspect element state before asserting

it('shows inline error messages after invalid form submission', async () => {
  await element(by.id('email-input')).replaceText('not-an-email');
  await element(by.id('submit-button')).tap();

  // Wait for the error state to appear
  await waitFor(element(by.id('email-error-label')))
    .toBeVisible()
    .withTimeout(3000);

  // Read the full attributes snapshot
  const attrs = await element(by.id('email-error-label')).getAttributes();

  // attrs.text: the label's displayed text
  jestExpect(attrs.text).toContain('valid email');

  // attrs.visible: boolean — confirms element is actually in the viewport
  jestExpect(attrs.visible).toBe(true);

  // attrs.enabled: false for disabled inputs
  const inputAttrs = await element(by.id('email-input')).getAttributes();
  jestExpect(inputAttrs.enabled).toBe(true); // input remains editable after error
});
```

```js
// e2e/toggle.test.js
// Using getAttributes() to read toggle/switch state without asserting a specific value

it('toggles dark mode and verifies the preference is persisted', async () => {
  // Tap the dark mode toggle
  await element(by.id('dark-mode-toggle')).tap();

  const toggleAttrs = await element(by.id('dark-mode-toggle')).getAttributes();

  // attrs.value: for Switch components, returns 'true' or 'false' as a string
  // (not a boolean — this is a common gotcha, see Gotcha 54)
  jestExpect(toggleAttrs.value).toBe('true'); // switch is now ON

  // Reload the app to verify persistence
  await device.reloadReactNative();

  const reloadedAttrs = await element(by.id('dark-mode-toggle')).getAttributes();
  jestExpect(reloadedAttrs.value).toBe('true'); // preference survived reload
});
```

```js
// e2e/list.test.js
// Using getAttributes() on a FlatList item for index and frame position

it('confirms a product card is in the visible frame', async () => {
  const cardAttrs = await element(by.id('product-card-0')).getAttributes();

  // attrs.frame: { x, y, width, height } in screen coordinates
  // Useful for asserting layout constraints or comparing positions
  jestExpect(cardAttrs.frame.width).toBeGreaterThan(200);
  jestExpect(cardAttrs.frame.y).toBeGreaterThanOrEqual(0);

  // attrs.label: the accessibility label (what VoiceOver reads)
  jestExpect(cardAttrs.label).toContain('Product');
});
```

**`getAttributes()` return shape (key properties):**

| Property | Type | Description |
|----------|------|-------------|
| `text` | `string \| undefined` | Displayed text content |
| `label` | `string \| undefined` | Accessibility label (VoiceOver/TalkBack text) |
| `placeholder` | `string \| undefined` | Input placeholder text |
| `value` | `string \| undefined` | Current value — switches return `'true'`/`'false'` (string) |
| `enabled` | `boolean` | Whether the element is interactive |
| `visible` | `boolean` | Whether the element is visible in the viewport |
| `focused` | `boolean` | Whether the element has keyboard focus |
| `frame` | `{ x, y, width, height }` | Bounding box in screen coordinates |
| `identifier` | `string \| undefined` | The `testID` value |
| `activationPoint` | `{ x, y }` | Point where taps are registered |
| `elementType` | `string` | Native element type name (XCUIElement or Android class) |
| `hasKeyboardFocus` | `boolean` | iOS: true if the element holds the keyboard |

---

### Pattern 46 — `device.shake()` shake gesture testing

Some React Native apps respond to the device shake gesture (e.g., to open a debug menu,
undo an action, or trigger a "feedback" flow). Detox provides `device.shake()` to
simulate this gesture on iOS Simulator. Android Emulator shake simulation requires a
different approach (see note below).

```js
// e2e/shake.test.js
// Testing shake-triggered features

describe('Shake gesture', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  it('opens the developer feedback modal on shake (iOS)', async () => {
    if (device.getPlatform() !== 'ios') {
      // Android shake via emulator menu or ADB — not directly supported in Detox
      return;
    }

    await device.shake();

    // Shake feedback modal should appear
    await waitFor(element(by.id('feedback-modal')))
      .toBeVisible()
      .withTimeout(3000);

    // Dismiss
    await element(by.id('feedback-modal-close')).tap();

    await waitFor(element(by.id('feedback-modal')))
      .not.toBeVisible()
      .withTimeout(2000);
  });

  it('shows undo action after text is deleted (shake to undo iOS native)', async () => {
    if (device.getPlatform() !== 'ios') return;

    await element(by.id('notes-input')).replaceText('Draft text content');
    await element(by.id('delete-note-button')).tap();

    // iOS native text fields support shake-to-undo
    await device.shake();

    // System-level undo alert appears (not from the app — by.text() or by.system())
    await waitFor(element(by.text('Undo Typing')))
      .toExist()
      .withTimeout(2000);

    await element(by.text('Undo')).tap();

    await expect(element(by.id('notes-input'))).toHaveText('Draft text content');
  });
});
```

**Android shake alternative**: The Android Emulator does not expose a programmatic shake API
that Detox can call. For Android, trigger shake-based features via:
1. `launchArgs` — inject a flag at startup to bypass the shake requirement in development builds.
2. Expose a `testID`-bearing button in development builds that triggers the same code path as shake.
3. Use `adb shell input keyevent 82` (menu key) if your app listens for that instead.

---

## Community Gotchas (iteration 45 additions)

### 51. `by.system()` dialog labels are locale-sensitive and change between iOS versions [community]

**Root cause**: iOS system permission dialog button labels are localized. On an English device,
the camera permission dialog has "OK" and "Don't Allow". On a French device, they are "OK" and
"Ne pas autoriser". If your Detox tests hard-code English labels using `by.system().label('OK')`
and your CI simulator uses a non-English locale (or Apple changes the English label text between
iOS major versions), the tests fail with `element not found`.

**WHY teams hit this in production**: macOS/iOS simulator locale is set by the CI machine's
default locale, which may differ from developer machines. A CI provider upgrade (e.g. Xcode 16
runners using "en_US_POSIX" instead of "en_US") can silently change button text.

**Fix**: Pre-grant all permissions in `.detoxrc.js` using the `permissions` key and avoid
`by.system()` for routine permission dialogs. Reserve `by.system()` only for tests explicitly
testing the permission dialog UX:

```js
// .detoxrc.js — pre-grant all permissions to avoid locale-sensitive dialog interactions
configurations: {
  'ios.sim.release': {
    launchArgs: {
      // Pre-grant permissions at app launch — bypasses the dialog entirely
    },
    // This is the correct way: use the Detox permissions API
  },
}

// In tests that do NOT test permission dialogs:
await device.launchApp({
  permissions: {
    camera: 'YES',
    microphone: 'YES',
    photos: 'YES',
    location: 'always',
    notifications: 'YES',
  },
});
// device.launchApp with permissions sets the permission directly in the Simulator database
// without showing any dialog — completely locale-independent.
```

If you must use `by.system()` labels, read the current device locale at test runtime and map to
the expected label string:

```js
// e2e/helpers/systemLabels.js
const PERMISSION_ALLOW_LABELS = {
  'en': 'Allow',
  'fr': 'Autoriser',
  'de': 'Erlauben',
  'es': 'Permitir',
  'ja': '許可',
};

function getAllowLabel() {
  const locale = device.getPlatform() === 'ios'
    ? (process.env.DETOX_LOCALE || 'en')
    : 'allow'; // Android uses 'Allow' consistently in AOSP
  return PERMISSION_ALLOW_LABELS[locale] || 'Allow';
}

module.exports = { getAllowLabel };
```

---

### 52. Deep link cold-start race condition: URL fires before JS bundle is ready [community]

**Root cause**: `device.launchApp({ url: 'myapp://products/42' })` passes the URL via the
native launch mechanism. The app process starts, boots the React Native JS bundle, and then
`Linking.getInitialURL()` is called from JS. However, on slow CI machines (Debug builds,
large bundles), the JS bundle may not have executed `Linking.getInitialURL()` by the time
Detox's first action fires. The result: the deep link URL is processed before the navigation
stack is initialized, causing a silent no-op — the app boots on the home screen instead of
the deep-linked screen.

**WHY this is invisible in development**: Fast dev machines have the JS bundle warm in Metro
cache. On CI with a fresh build, cold start time is 3–8x slower.

**Fix**: Either increase the `waitFor` timeout on the target screen, or add a small synchronization
mechanism in the app that signals bundle-ready state:

```js
// Fix 1: Increase timeout for deep-link cold-start tests
it('navigates to product screen via cold-start deep link', async () => {
  await device.terminateApp();
  await device.launchApp({
    newInstance: true,
    url: 'myapp://products/42',
  });

  // Use a generous timeout for cold-start deep link — bundle may take 6-10s on CI
  await waitFor(element(by.id('product-detail-screen')))
    .toBeVisible()
    .withTimeout(15000); // much longer than the default 6000ms (Detox 20 default)
});
```

```js
// Fix 2: Use launchArgs to signal deep link target + handle it synchronously in JS
// (avoids async getInitialURL() race)
it('navigates via launchArgs instead of deep link URL (more reliable)', async () => {
  await device.terminateApp();
  await device.launchApp({
    newInstance: true,
    launchArgs: {
      INITIAL_ROUTE: 'products',
      INITIAL_PARAMS: JSON.stringify({ productId: '42' }),
    },
  });

  // App reads INITIAL_ROUTE from launchArgs synchronously before rendering — no race
  await waitFor(element(by.id('product-detail-screen')))
    .toBeVisible()
    .withTimeout(8000);
});
```

---

### 53. Parallel workers share the same `device.launchApp()` args from `beforeAll` — last writer wins [community]

**Root cause**: When Detox runs with `--maxWorkers 4`, four Jest workers execute `beforeAll`
blocks concurrently. Each worker gets its own simulator instance, BUT if you store test
configuration in shared module-level state (e.g., a singleton config file that all workers
import and mutate), the last worker to write wins. This causes some workers to launch the app
with incorrect flags.

**WHY this is surprising**: Jest workers run in separate Node processes. Module-level `let` variables
are NOT shared. The problem occurs when workers write to shared on-disk fixtures or shared
environment variables that feed into `device.launchApp()`.

**Most common manifestation**: Test helpers that write a `launchArgs.json` to a shared path,
then read it in `beforeAll`. Worker 1 writes `{ featureFlag: 'A' }`, Worker 3 immediately writes
`{ featureFlag: 'B' }`, and Worker 1 reads `'B'` by the time its `beforeAll` runs.

**Fix**: Write fixtures to worker-unique paths using `process.env.JEST_WORKER_ID`:

```js
// e2e/helpers/workerConfig.js
const path = require('path');
const fs = require('fs');

// Each worker writes to its own isolated config file
const workerDir = path.join(__dirname, '..', '.artifacts', `worker-${process.env.JEST_WORKER_ID}`);

function writeLaunchConfig(config) {
  fs.mkdirSync(workerDir, { recursive: true });
  fs.writeFileSync(
    path.join(workerDir, 'launch-config.json'),
    JSON.stringify(config, null, 2)
  );
}

function readLaunchConfig() {
  const file = path.join(workerDir, 'launch-config.json');
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : {};
}

module.exports = { writeLaunchConfig, readLaunchConfig };
```

```js
// e2e/featureA.test.js — uses worker-scoped config, no cross-worker pollution
const { writeLaunchConfig } = require('./helpers/workerConfig');

beforeAll(async () => {
  writeLaunchConfig({ featureFlag: 'A' });
  await device.launchApp({ newInstance: true, launchArgs: { featureFlag: 'A' } });
});
```

---

### 54. `getAttributes().value` returns a string, not a boolean, for Switch components [community]

**Root cause**: React Native's `<Switch>` component sets its `accessibilityValue` to the string
`'true'` or `'false'` — not the boolean `true`/`false`. `element.getAttributes()` returns this
raw accessibility value, so `attrs.value === true` always evaluates to `false` (strict equality
between a string and a boolean).

**WHY this bites teams**: The React Native docs show `value` as a boolean prop. Developers
assume `getAttributes()` would reflect the boolean type. The mismatch is invisible in `waitFor`
assertions (`toHaveToggleValue(true)` uses the correct API), but surfaces the moment you switch
to `getAttributes()` for a more detailed inspection.

**Fix**: Always use string comparison for `getAttributes().value`, or prefer `toHaveToggleValue()`:

```js
// BAD — fails even when switch IS on
const attrs = await element(by.id('notifications-toggle')).getAttributes();
jestExpect(attrs.value).toBe(true);   // FAILS: 'true' !== true

// GOOD — use string comparison
jestExpect(attrs.value).toBe('true'); // PASSES: 'true' === 'true'

// BETTER — use the typed Detox assertion when you only need to check the boolean value
await expect(element(by.id('notifications-toggle'))).toHaveToggleValue(true);
// toHaveToggleValue(true) correctly handles the string-to-boolean conversion internally

// BEST for complex assertions that also need other properties:
const attrs2 = await element(by.id('notifications-toggle')).getAttributes();
jestExpect(attrs2.value).toBe('true');   // switch ON
jestExpect(attrs2.enabled).toBe(true);  // switch is not disabled
jestExpect(attrs2.visible).toBe(true);  // switch is visible
```

---

### 55. `element.getAttributes()` returns `null` for off-screen elements — throws if treated as object [community]

**Root cause**: If an element exists in the React tree but is scrolled off screen (outside the
visible viewport), `element.getAttributes()` may return `null` on some Detox versions and
simulator configurations. Code that immediately accesses `attrs.text` without a null check
throws `TypeError: Cannot read property 'text' of null` — a cryptic error that hides the
real problem (element out of viewport).

**WHY this surprises developers**: `by.id()` finds the element in the view hierarchy regardless
of scroll position — the element "exists" but is not visible. `getAttributes()` with some native
accessibility implementations only returns attributes for elements currently rendered in the
active viewport, not off-screen backing views.

**Fix**: Always scroll the element into view before calling `getAttributes()`, or add a null guard:

```js
// BAD — throws if product-card-5 is below the fold
const attrs = await element(by.id('product-card-5')).getAttributes();
jestExpect(attrs.text).toBe('Expected text'); // TypeError if attrs is null

// GOOD — scroll into view first, then inspect attributes
await waitFor(element(by.id('product-card-5')))
  .toBeVisible()
  .whileElement(by.id('product-list'))
  .scroll(200, 'down');

const attrs = await element(by.id('product-card-5')).getAttributes();
jestExpect(attrs.text).toBe('Expected text');

// ALSO GOOD — null guard for defensive code in helpers
async function safeGetAttributes(matcher) {
  try {
    await waitFor(element(matcher)).toBeVisible().withTimeout(3000);
  } catch (_) {
    return null; // element not visible — caller handles
  }
  return element(matcher).getAttributes();
}
```

---

### 56. `device.shake()` is a no-op on physical iOS devices and Android Emulator [community]

**Root cause**: `device.shake()` is implemented only for **iOS Simulator**. On a physical iPhone,
the command sends a shake signal to the Simulator process — which does nothing because the app
is running on device, not in the simulator. On Android Emulator, no corresponding API exists
in Detox's Android driver. The method either throws or silently does nothing depending on the
Detox version.

**WHY teams are surprised**: The Detox docs list `device.shake()` without a platform/environment
caveat on older pages. Teams add shake tests, they pass in local iOS Simulator CI, then fail on
physical-device test farms (AWS Device Farm, BrowserStack App Automate).

**Fix**: Guard all `device.shake()` calls with a platform AND environment check:

```js
// e2e/helpers/shake.js
/**
 * Simulates a shake gesture — iOS Simulator only.
 * On physical devices or Android, triggers the debug-mode launchArg fallback instead.
 */
async function shakeOrFallback() {
  if (device.getPlatform() === 'ios' && !process.env.PHYSICAL_DEVICE) {
    // iOS Simulator — shake works
    await device.shake();
  } else {
    // Physical device or Android — use a debug-mode button exposed via testID
    // (The app should expose a "shake-trigger" button in DETOX_BUILD=1 builds)
    const hasShakeButton = await element(by.id('debug-shake-trigger')).exists?.() ?? false;
    if (hasShakeButton) {
      await element(by.id('debug-shake-trigger')).tap();
    } else {
      // No shake trigger available — skip this test gracefully
      console.warn('[shake] device.shake() not available and no debug trigger found — skipping');
    }
  }
}

module.exports = { shakeOrFallback };
```

```js
// e2e/shake.test.js
const { shakeOrFallback } = require('./helpers/shake');

it('opens the debug menu via shake (iOS Simulator only)', async () => {
  await shakeOrFallback();
  // ... rest of test
});
```

---

### Pattern 47 — `element.swipe()` with `startNormalizedX`/`startNormalizedY` for precision swipe control

Detox's `element.swipe(direction, speed, normalizedOffset)` signature covers most cases, but
some UI elements require a swipe that begins at a specific point within the element:

- **Carousels with edge-based snap zones** — a swipe starting from the center may be
  intercepted by a nested scroll child; starting near the left/right edge hits the carousel's
  gesture recognizer directly.
- **Pull-to-refresh triggered only in the top 20% of a scroll view** — a swipe starting at
  `startNormalizedY: 0.1` (10% from the top) reliably triggers the refresh indicator; starting
  from the midpoint (the default) may not reach the threshold.
- **Horizontal carousels embedded in vertical scroll views** — starting the horizontal swipe
  at `startNormalizedY: 0.5` (vertical midpoint) prevents the parent vertical scroll from
  consuming the gesture first.

```js
// e2e/carousel.test.js
// element.swipe(direction, speed, normalizedOffset, startNormalizedX, startNormalizedY)
// normalizedOffset: how far to swipe (0.0–1.0 fraction of element size)
// startNormalizedX: X start point within the element (0.0 = left edge, 1.0 = right edge)
// startNormalizedY: Y start point within the element (0.0 = top edge, 1.0 = bottom edge)

describe('Carousel interactions', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  it('advances a carousel slide by swiping left from the right edge', async () => {
    await waitFor(element(by.id('featured-carousel')))
      .toBeVisible()
      .withTimeout(5000);

    // Start the swipe near the right edge (startNormalizedX: 0.85) to avoid
    // triggering the nested tap recognizer that responds to center-origin swipes
    await element(by.id('featured-carousel')).swipe('left', 'fast', 0.6, 0.85, 0.5);

    await waitFor(element(by.id('carousel-slide-2')))
      .toBeVisible()
      .withTimeout(3000);
  });

  it('triggers pull-to-refresh from the top quarter of a scroll view', async () => {
    await waitFor(element(by.id('feed-scroll-view')))
      .toBeVisible()
      .withTimeout(5000);

    // Start swipe from the top 10% of the scroll view — the only area where
    // the PTR gesture recognizer has higher priority than the scroll gesture
    await element(by.id('feed-scroll-view')).swipe('down', 'slow', 0.5, 0.5, 0.1);

    await waitFor(element(by.id('refresh-indicator')))
      .toBeVisible()
      .withTimeout(3000);

    // Wait for refresh to complete
    await waitFor(element(by.id('refresh-indicator')))
      .not.toBeVisible()
      .withTimeout(8000);
  });

  it('horizontally swipes a carousel embedded inside a vertical scroll', async () => {
    // Scroll the parent list to show the embedded carousel
    await waitFor(element(by.id('horizontal-carousel-row')))
      .toBeVisible()
      .whileElement(by.id('home-scroll-view'))
      .scroll(200, 'down');

    // Use startNormalizedY: 0.5 to hit the horizontal carousel exactly at midpoint
    // — prevents the parent vertical scroll from intercepting the gesture
    await element(by.id('horizontal-carousel-row')).swipe('left', 'slow', 0.4, 0.1, 0.5);

    await waitFor(element(by.id('carousel-item-2')))
      .toBeVisible()
      .withTimeout(3000);
  });
});
```

**Signature reference:**

```js
// Full swipe() signature
await element(matcher).swipe(
  direction,           // 'left' | 'right' | 'up' | 'down'
  speed,               // 'slow' | 'fast' (default: 'fast')
  normalizedOffset,    // 0.0–1.0, how far to swipe as fraction of element size (default: 0.75)
  startNormalizedX,    // 0.0–1.0, X start point within element (default: 0.5 — center)
  startNormalizedY,    // 0.0–1.0, Y start point within element (default: 0.5 — center)
);
```

**When to use `startNormalizedX`/`Y`:**

| Scenario | Recommended start point |
|---|---|
| Pull-to-refresh | `startNormalizedY: 0.1` (top 10%) |
| Swipe-to-dismiss (modal bottom sheet) | `startNormalizedY: 0.9` (bottom 10%) |
| Carousel in vertical scroll | `startNormalizedY: 0.5`, `startNormalizedX: 0.1`–`0.9` |
| Map pan interaction | Custom coordinates to avoid controls overlay |
| Tab bar swipe (gesture navigation) | `startNormalizedX: 0.02` (near left edge for back swipe) |

---

### Pattern 48 — Test tagging with describe groups and `--testNamePattern` for smoke/regression/full CI tiers

Large Detox test suites (50+ test files) benefit from organizing tests into tiered groups:
**smoke** (critical path, ≤5 min), **regression** (full feature coverage, ≤20 min), and
**full** (edge cases + visual regression, uncapped). This allows CI pipelines to run the
right tier for the right trigger — smoke on every PR, regression on merge, full on nightly.

Detox uses Jest under the hood. Jest's `--testNamePattern` flag filters by the test/describe
name string. The convention is to prefix describe blocks with a tier tag:

```js
// e2e/auth.test.js
// [smoke] prefix = include in the smoke tier
// [regression] prefix = include in regression + full tiers (not smoke)
// No prefix = full tier only

describe('[smoke] Login critical path', () => {
  it('logs in with valid credentials and reaches dashboard', async () => {
    // ...
  });

  it('shows error on invalid password', async () => {
    // ...
  });
});

describe('[regression] Login edge cases', () => {
  it('handles locked account message', async () => {
    // ...
  });

  it('preserves email after failed login attempt', async () => {
    // ...
  });
});

describe('Login visual regression', () => {
  // No tag — full tier only
  it('matches baseline screenshot for login screen', async () => {
    // ...
  });
});
```

```js
// package.json — CI scripts for each tier
{
  "scripts": {
    "test:e2e:smoke":      "detox test -c ios.sim.release --testNamePattern='\\[smoke\\]'",
    "test:e2e:regression": "detox test -c ios.sim.release --testNamePattern='\\[(smoke|regression)\\]'",
    "test:e2e:full":       "detox test -c ios.sim.release"
  }
}
```

```yaml
# GitHub Actions — run smoke on every PR, regression on merge to main, full nightly
name: E2E Tests
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'  # Nightly at 02:00 UTC

jobs:
  detox-smoke:
    if: github.event_name == 'pull_request'
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci
      - run: npx detox build -c ios.sim.release
      - run: npm run test:e2e:smoke

  detox-regression:
    if: github.event_name == 'push'
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci
      - run: npx detox build -c ios.sim.release
      - run: npm run test:e2e:regression

  detox-full:
    if: github.event_name == 'schedule'
    runs-on: macos-15
    strategy:
      matrix:
        shard: [1, 2, 3]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci
      - run: npx detox build -c ios.sim.release
      - run: npx detox test -c ios.sim.release --shard-index=${{ matrix.shard }} --shard-count=3 --forceExit
```

**Tag conventions and escape rules:**
- Jest's `--testNamePattern` matches against the full test title string (describe block name
  concatenated with `it()` name). The `[smoke]` prefix must be in the `describe` block name,
  not the `it()` name, so that all tests under that describe are included.
- On the command line, `[` and `]` are regex special characters and must be escaped:
  `--testNamePattern='\\[smoke\\]'` (double-backslash in shell strings).
- The `|` operator in `--testNamePattern` allows multiple tag matches without separate runs:
  `'\\[(smoke|regression)\\]'` matches both `[smoke]` and `[regression]`.

---

## Real-World Gotchas (iteration 46 additions)

### 57. iOS 18 "Precise Location" confirmation prompt blocks `by.system()` selectors [community]

**Root cause**: iOS 18 introduced a new secondary permission prompt when an app first requests
`kCLAuthorizationStatusAuthorizedWhenInUse` with the "Precise" accuracy level. After granting
the base location permission, iOS 18 shows a second system dialog: *"Allow [App] to use your
precise location?"* with options "Keep My Precise Location On" / "One Time" / "Don't Use".
This second dialog is a native system alert with labels that differ from the base location
dialog, and it appears at a different point in the permission flow.

**WHY teams are surprised**: The base location permission dialog was handled correctly with
`launchApp({ permissions: { location: 'inuse' } })` on iOS 16 and earlier. After upgrading
CI to iOS 18 Simulator (Xcode 16+), tests that test location features start hanging in the
`waitFor(element(by.id('map-screen')))` step — the test is actually waiting for the map but
the system is blocked behind the undismissed "Precise Location" dialog.

**Symptoms**: Test times out waiting for a screen that should be visible. The artifacts
screenshot shows the "Precise Location" system dialog overlaid on the app. `by.system()`
selectors written for the base location dialog do not match the precise-location dialog.

**Fix**: There are two mitigation strategies:

```js
// Strategy 1: Pre-grant via launchApp permissions — most reliable
// 'always' + preciselocation: 'YES' suppresses both prompts on iOS 18+
beforeAll(async () => {
  await device.launchApp({
    newInstance: true,
    permissions: {
      location: 'always',         // grant location permission at the 'always' level
      preciselocation: 'YES',     // suppress the secondary "Precise Location" prompt
    },
  });
});
```

```js
// Strategy 2: Handle the precise location dialog via by.system() if pre-grant is unavailable
// Build a locale-aware label map for the iOS 18 precise location dialog
const PRECISE_LOCATION_ALLOW = {
  'en': 'Keep My Precise Location On',
  'fr': 'Conserver ma position précise activée',
  'de': 'Genauen Standort aktiviert lassen',
  // Add other locales as needed
};

async function dismissPreciseLocationPromptIfPresent() {
  const locale = (await device.getLocale?.()) ?? 'en';
  const label = PRECISE_LOCATION_ALLOW[locale] ?? PRECISE_LOCATION_ALLOW['en'];
  try {
    await waitFor(element(by.system().label(label)))
      .toBeVisible()
      .withTimeout(3000);
    await element(by.system().label(label)).tap();
  } catch (_) {
    // Prompt did not appear — already granted or iOS < 18
  }
}

// Call after granting base location permission
it('shows map after location grant', async () => {
  await element(by.id('enable-location-button')).tap();
  // Handle base location dialog
  await element(by.system().label('Allow While Using App')).tap();
  // Handle iOS 18 precise location follow-up dialog
  await dismissPreciseLocationPromptIfPresent();
  // Now proceed with the actual test
  await waitFor(element(by.id('map-screen'))).toBeVisible().withTimeout(5000);
});
```

**WHY `preciselocation: 'YES'` is the right default for CI**: Most apps need GPS accuracy
for the feature under test. Pre-granting at launch avoids dialog timing races entirely —
the app never shows the prompt. Use `preciselocation: 'NO'` only for tests that specifically
verify degraded-accuracy behavior.

---

### 58. `device.setStatusBar()` state bleeds across test files unless reset in `afterAll` [community]

**Root cause**: `device.setStatusBar()` applies status bar overrides (time, battery level,
signal strength) to the iOS Simulator at the OS level, not the app level. The override persists
for the lifetime of the Simulator session — it is NOT automatically reset when Detox reloads
the React Native bundle (`device.reloadReactNative()`) or even when a new app instance is
launched (`device.launchApp({ newInstance: true })`). If a visual regression test suite sets
`time: '9:41'` but a later test suite takes screenshots without resetting the status bar, all
screenshots in the later suite will also show `9:41` — even though those tests didn't intend
to freeze the clock.

**WHY it's a silent failure**: The screenshots look "correct" to human reviewers (9:41 is a
plausible time) and baseline images were captured the same way. The issue surfaces only when
the baseline was captured with a different status bar override and the diff shows a mismatch
in the time string.

**Fix**: Always pair `device.setStatusBar()` with a reset in `afterAll`:

```js
// e2e/visual-regression.test.js
const STATUS_BAR_OVERRIDE = {
  time: '9:41',
  batteryLevel: 100,
  batteryState: 'charging',
  cellularMode: 'active',
  cellularBars: 4,
  wifiMode: 'active',
  wifiBars: 3,
  dataNetwork: 'wifi',
};

describe('Visual regression — Login screen', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
    // Set deterministic status bar for all screenshots in this suite
    if (device.getPlatform() === 'ios') {
      await device.setStatusBar(STATUS_BAR_OVERRIDE);
    }
  });

  afterAll(async () => {
    // CRITICAL: reset status bar so subsequent test files get the live status bar
    if (device.getPlatform() === 'ios') {
      await device.resetStatusBar();  // Detox 20.8+ API
      // If resetStatusBar() is not available (older Detox), use setStatusBar with 'auto' values:
      // await device.setStatusBar({ time: '' });  // empty string restores live clock
    }
  });

  it('matches login screen baseline', async () => {
    await element(by.id('login-screen')).tap();
    const screenshot = await device.takeScreenshot('login-screen-baseline');
    // ... pixelmatch comparison ...
  });
});
```

**Note on Android**: `device.setStatusBar()` is iOS Simulator only. On Android Emulator,
use ADB to set the demo mode: `adb shell settings put global sysui_demo_allowed 1 && adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941`. Reset with `adb shell am broadcast -a com.android.systemui.demo -e command exit`.

---

### 59. `element.longPress()` with `duration: 0` behaves as `tap()` on Android — minimum duration is platform-dependent [community]

**Root cause**: `element.longPress(duration)` accepts a duration in milliseconds. On iOS
Simulator, a duration of `0` ms correctly registers as a long press (the UIKit gesture
recognizer threshold is ~500 ms by default, and Detox signals it directly). On Android,
the `MotionEvent` system requires the long-press `downTime` to remain held for at least the
system's long-press threshold (~400 ms on most devices). Passing `0` ms causes Detox to
send `ACTION_DOWN` and `ACTION_UP` in immediate succession — which Android interprets as a
single tap.

**WHY teams encounter this**: Tests written on iOS pass; the same test on Android silently
taps instead of long-pressing, and the long-press menu never appears. The test does not
throw an error — it simply waits for the context menu and times out.

**Fix**: Always use the platform default duration or an explicit safe minimum:

```js
// e2e/contextMenu.test.js

it('opens the long-press context menu on a list item', async () => {
  await waitFor(element(by.id('message-item-0')))
    .toBeVisible()
    .withTimeout(5000);

  // DO NOT use duration: 0 — it behaves as tap() on Android
  // Instead, use platform-appropriate defaults:
  if (device.getPlatform() === 'ios') {
    // iOS: Detox default longPress duration (500 ms) works well
    await element(by.id('message-item-0')).longPress();
  } else {
    // Android: explicit 800 ms gives a comfortable margin above the 400 ms threshold
    await element(by.id('message-item-0')).longPress(800);
  }

  await waitFor(element(by.id('context-menu')))
    .toBeVisible()
    .withTimeout(3000);
});
```

```js
// Reusable helper — cross-platform safe long press
async function safeLongPress(matcher, durationIos = 500, durationAndroid = 800) {
  const duration = device.getPlatform() === 'ios' ? durationIos : durationAndroid;
  await element(matcher).longPress(duration);
}

// Usage
await safeLongPress(by.id('message-item-0'));
await waitFor(element(by.id('context-menu'))).toBeVisible().withTimeout(3000);
```

**Related**: The `longPressAndDrag()` API has a separate first argument for the hold
duration before dragging begins. Apply the same minimum-800-ms rule on Android for the
`duration` parameter in `longPressAndDrag(duration, normalizedPositionX, normalizedPositionY, ...)`.

---

### 60. Expo SDK 53 + `expo-modules-core` v2 requires Detox 20.9+ — older Detox hangs at app launch [community]

**Root cause**: Expo SDK 53 (released May 2025) ships `expo-modules-core` v2.0, which
migrates the core module registration from the legacy `AppDelegate` pattern to a new
`ExpoAppDelegate` Swift/Kotlin class (part of the "Expo Modules Architecture v2"). The
Detox synchronization bridge attaches to the app by hooking into the `AppDelegate`
lifecycle. Detox versions older than 20.9 do not recognize the new `ExpoAppDelegate`
hook points and fail to establish the synchronization channel — the app launches
visually but Detox cannot detect the "app idle" state. Tests hang indefinitely waiting
for the initial `waitFor`.

**Symptoms**:
- `npx detox test` hangs after "Waiting for app to launch" with no timeout error
- The Simulator shows the app running normally
- `--debug-synchronization` output shows "Waiting for JS runloop to become idle" repeating forever

**Fix**: Update Detox to 20.9+ before upgrading to Expo SDK 53:

```bash
# Check current version
npx detox --version

# Update Detox (Detox 20.9+ includes Expo Modules Architecture v2 support)
npm install --save-dev detox@^20.9.0

# Also update expo-modules-core to SDK 53 version
npx expo install expo-modules-core

# If using Expo prebuild, regenerate native code
npx expo prebuild --clean
```

**`.detoxrc.js` updates for Expo SDK 53:**

```js
// .detoxrc.js — Expo SDK 53 managed workflow
module.exports = {
  testRunner: {
    args: { $0: 'jest', config: 'e2e/jest.config.js' },
    jest: { setupTimeout: 300000 },
  },
  apps: {
    'ios.release': {
      type: 'ios.app',
      // SDK 53: build path includes the new ExpoAppDelegate framework
      binaryPath: 'ios/build/Build/Products/Release-iphonesimulator/YourApp.app',
      build: [
        'xcodebuild',
        '-workspace ios/YourApp.xcworkspace',
        '-scheme YourApp',
        '-configuration Release',
        '-sdk iphonesimulator',
        '-derivedDataPath ios/build',
        'CODE_SIGNING_ALLOWED=NO',
        '| xcpretty'
      ].join(' '),
    },
  },
  devices: {
    simulator: {
      type: 'ios.simulator',
      device: { type: 'iPhone 16' },
    },
  },
  configurations: {
    'ios.sim.release': { device: 'simulator', app: 'ios.release' },
  },
};
```

**[community] gotcha — SDK 53 deprecates `expo-dev-client` `launchMode: 'most-recent'`.**
SDK 53 changes how `expo-dev-client` selects the app to launch. Detox tests that used
`launchMode: 'most-recent'` in their dev client config may get an unexpected "Select a
Development Server" UI instead of immediately launching. Fix: set `launchMode: 'launcher'`
and point Detox's `launchArgs` to the pre-built release binary, not the dev client.

---

### 61. `--loglevel verbose` (or `trace`) overflows GitHub Actions log buffer, silently truncating output [community]

**Root cause**: GitHub Actions has a per-step log output buffer limit of approximately
50 MB. Detox with `--loglevel verbose` generates between 2–8 KB of log output per test
action (device command, synchronization wait, element interaction). On a suite with 300
tests averaging 20 interactions each, that is 6,000 × 5 KB = ~30 MB per shard — and with
`--loglevel trace` (which additionally logs all IPC messages between the JS and native
layers), the output easily exceeds 200 MB per shard. When the buffer is exceeded, GitHub
Actions silently truncates the log from the **beginning**, discarding the setup and
early-test output — the exact portion most useful for diagnosing build failures.

**WHY teams use `--loglevel verbose` on CI**: It was added temporarily to diagnose a
flakiness issue and never removed. Or the team added it to the `test:e2e:ci` script without
realizing the log volume implications.

**Fix**: Use `--loglevel warn` for normal CI runs and save verbose logs only to the artifact
file (Detox's `log` artifact plugin captures the full trace to disk without going through
the GitHub Actions stdout buffer):

```bash
# In GitHub Actions step — use warn level for stdout, rely on artifact log for details
- name: Run Detox tests
  run: |
    npx detox test \
      -c ios.sim.release \
      --loglevel warn \
      --record-logs failing \
      --forceExit

# NOT this (overflows stdout buffer):
# npx detox test -c ios.sim.release --loglevel verbose
```

```js
// .detoxrc.js — configure artifact log collection (captures full trace to disk)
artifacts: {
  rootDir: '.artifacts',
  plugins: {
    log: {
      enabled: true,
      keepOnlyFailedTestsArtifacts: true,  // saves disk space — only failing test logs
    },
    screenshot: {
      enabled: true,
      shouldTakeAutomaticSnapshots: true,
      takeWhen: { testFailure: true },
    },
  },
},
```

**Loglevel reference:**

| Level | Output volume | When to use |
|---|---|---|
| `error` | Minimal | Production CI — only hard errors |
| `warn` | Low | Normal CI — warnings + errors (recommended) |
| `info` | Medium | Default — Detox lifecycle + test milestones |
| `debug` | High | Local investigation of a specific failure |
| `verbose` | Very high | Deep investigation — includes all device commands |
| `trace` | Extreme | Full IPC trace — almost never appropriate in CI |

**Tip**: Use `--record-logs failing` (Detox's artifact plugin shorthand) rather than
`--loglevel verbose`. `record-logs` writes the verbose log to disk for failed tests only,
without flooding stdout.

---

### 62. `waitFor().whileElement().scroll('up')` skips Android `SectionList` section headers [community]

**Root cause**: Detox's `whileElement().scroll(100, 'up')` drives a native scroll gesture
upward. On Android, `SectionList` renders section headers as sticky views that are
rendered at the OS level above the scroll container — they are not part of the scrollable
content. When Detox sends a scroll-up gesture and checks `toBeVisible()`, Android's
accessibility layer reports the element's scroll position relative to the scrollable
content frame, not the full window frame. As a result, `waitFor(element(by.id('section-header-B'))).toBeVisible().whileElement(by.id('list')).scroll(100, 'up')` may
scroll past the header without `toBeVisible()` ever returning `true` — the header is
technically "visible" in the window but the scroll container's `isAccessibilityFocused`
returns `false` for a stuck sticky header, causing Detox to keep scrolling.

**Symptoms**: The test keeps scrolling upward past the target section header. It
eventually exceeds `withTimeout()` and fails with "element not found" — even though
the section header is clearly visible in the artifact screenshot.

**Fix**: Use `waitFor + whileElement` with `scroll('down')` first to ensure you overshoot,
then scroll back up with small steps, OR target a non-sticky element inside the section
instead of the sticky header itself:

```js
// UNRELIABLE on Android — sticky section header may not report visibility correctly
await waitFor(element(by.id('section-header-B')))
  .toBeVisible()
  .whileElement(by.id('section-list'))
  .scroll(100, 'up');

// RELIABLE — scroll to a known item BELOW the section header
// The header becomes visible as a side effect of the item becoming visible
await waitFor(element(by.id('section-B-item-0')))
  .toBeVisible()
  .whileElement(by.id('section-list'))
  .scroll(100, 'up');

// Then optionally assert the header after reaching its section
await expect(element(by.id('section-header-B'))).toBeVisible();
```

```js
// ALTERNATIVE — use scrollTo('top') to jump to top, then scroll down to section
// When the section order is known, this avoids the ambiguous-direction problem entirely
it('scrolls to Section B in an alphabetical contact list', async () => {
  // Reset to top first
  await element(by.id('contacts-list')).scrollTo('top');

  // Then scroll down until the first item in Section B is visible
  await waitFor(element(by.id('contact-bob')))
    .toBeVisible()
    .whileElement(by.id('contacts-list'))
    .scroll(100, 'down');
});
```

**iOS behavior**: iOS `SectionList` sticky headers are implemented differently —
`toBeVisible()` correctly detects them during `scroll('up')` on iOS. This is an
Android-specific issue with sticky view accessibility reporting.

---

### 63. `device.setOrientation()` has no effect on Android Emulator API 34+ when hardware acceleration is active [community]

**Root cause**: Android 14 (API 34) changed the Emulator's default renderer from
`swiftshader_indirect` to hardware-accelerated ANGLE (on compatible host GPUs). With
hardware acceleration enabled, the emulator's window manager requires the orientation
change to be driven by the host window system, not by ADB / Detox API calls. Detox's
`device.setOrientation('landscape')` sends the equivalent of `adb shell content insert
--uri content://settings/system --bind name:s:user_rotation --bind value:i:1` — which
only works with the software renderer. With ANGLE rendering, the orientation change
appears to apply (no error is thrown) but the emulator display does not rotate, and
subsequent assertions about landscape-specific UI layout fail.

**Symptoms**:
- `device.setOrientation('landscape')` returns without error
- The test assertions for landscape layout (wider navigation bar, side-by-side panels)
  fail with "element not found"
- Artifact screenshot shows the emulator still in portrait orientation
- Test passes locally on a Mac M-series host where the ANGLE renderer path differs

**Fix**: Force the software renderer for CI Android Emulators that test orientation:

```js
// .detoxrc.js — force swiftshader renderer for orientation tests
devices: {
  emulator: {
    type: 'android.emulator',
    device: { avd: 'Pixel_6_API_34' },
    // Explicitly request software rendering — REQUIRED for device.setOrientation() on API 34+
    bootArgs: '-no-window -gpu swiftshader_indirect -no-snapshot -noaudio -no-boot-anim',
    headless: true,
  },
},
```

```yaml
# GitHub Actions — reactivecircus/android-emulator-runner with explicit GPU flag
- name: Run Detox tests (Android)
  uses: reactivecircus/android-emulator-runner@v2
  with:
    api-level: 34
    target: google_apis
    arch: x86_64
    # Explicitly use swiftshader so device.setOrientation() works
    emulator-options: -no-snapshot -no-window -gpu swiftshader_indirect -noaudio -no-boot-anim
    disable-animations: true
    script: npx detox test -c android.emu.release --forceExit
```

```js
// e2e/orientation.test.js — always reset orientation in afterEach
describe('Landscape layout', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  afterEach(async () => {
    // Always restore portrait — setOrientation state is not automatically reset
    // between tests (same issue as setStatusBar — persists across the session)
    await device.setOrientation('portrait');
  });

  it('shows side-by-side panel layout in landscape', async () => {
    await device.setOrientation('landscape');

    await waitFor(element(by.id('left-panel')))
      .toBeVisible()
      .withTimeout(3000);
    await waitFor(element(by.id('right-panel')))
      .toBeVisible()
      .withTimeout(3000);
  });
});
```

**Note on iOS**: `device.setOrientation()` works reliably on iOS Simulator regardless of
host GPU because UIKit processes orientation changes through the Simulator's software
rotation pipeline. The ANGLE regression is Android-only.

---

## Updated Anti-Patterns Checklist (iteration 46 additions)

| Anti-Pattern | Fix |
|---|---|
| `element.swipe()` without `startNormalizedX`/`Y` on carousels or embedded scrolls | Use explicit start point (e.g., `startNormalizedX: 0.85`) to avoid nested scroll intercepting the gesture (Pattern 47) |
| All tests in a single tier running on every PR | Tag `describe` blocks with `[smoke]`/`[regression]` prefixes and use `--testNamePattern` to run the right tier per trigger (Pattern 48) |
| `by.system()` selectors hard-coded for iOS 17 location dialog | Add iOS 18 "Precise Location" follow-up dialog handling with `preciselocation: 'YES'` in `launchApp` permissions (Gotcha 57) |
| `device.setStatusBar()` called in `beforeAll` without `afterAll` reset | Call `device.resetStatusBar()` in `afterAll` — status bar overrides persist across test files (Gotcha 58) |
| `element.longPress(0)` or `element.longPress()` in cross-platform tests | Use platform-specific duration: iOS default (500 ms) and Android explicit 800+ ms minimum (Gotcha 59) |
| Expo SDK 53 project running Detox < 20.9 | Upgrade to Detox 20.9+ before adopting `expo-modules-core` v2 (Gotcha 60) |
| `--loglevel verbose` or `--loglevel trace` in CI run scripts | Use `--loglevel warn` for stdout; capture full logs via `--record-logs failing` artifact plugin (Gotcha 61) |
| `waitFor().whileElement().scroll('up')` targeting sticky SectionList headers on Android | Target the first item below the header instead; assert the header visibility after item is visible (Gotcha 62) |
| `device.setOrientation()` on Android Emulator API 34+ without `-gpu swiftshader_indirect` | Set `bootArgs: '-gpu swiftshader_indirect'` in emulator device config; hardware ANGLE renderer ignores orientation commands (Gotcha 63) |

## Anti-Patterns Checklist (prior iterations)

| Anti-Pattern | Fix |
|---|---|
| Hard-coded English labels in `by.system()` selectors | Use `launchApp({ permissions })` to pre-grant and skip dialogs, or build a locale-aware label map (Gotcha 51) |
| Short `waitFor` timeout on deep-link cold-start tests | Use 12–15s timeout for cold-start deep links on CI; bundle boot is 3–8x slower than local (Gotcha 52) |
| Shared on-disk fixtures written by multiple Detox workers | Use `process.env.JEST_WORKER_ID` to write to worker-unique paths (Gotcha 53) |
| `jestExpect(attrs.value).toBe(true)` for Switch state | Switch `accessibilityValue` is a string `'true'`/`'false'` — use `.toBe('true')` or `toHaveToggleValue(true)` (Gotcha 54) |
| `element.getAttributes()` without prior `toBeVisible()` | Scroll element into view first; `getAttributes()` may return `null` for off-screen elements (Gotcha 55) |
| `device.shake()` in tests intended for physical devices | Guard with platform + environment check; provide a debug-mode fallback tap target (Gotcha 56) |
| `by.traits()` assertions in Android test paths | Guard with `if (device.getPlatform() !== 'ios') return;` — `by.traits()` throws on Android |
| `device.openURL()` without `waitFor` on the target screen | Always follow `openURL()` with `waitFor(...).toBeVisible().withTimeout(5000+)` — URL processing is async |

---

## Additional Patterns (iteration 47 additions)

### Pattern 49 — `device.setStatusBar()` / `device.resetStatusBar()` for status-bar-dependent UI testing

Many React Native apps render conditional UI based on status-bar state: battery-level
warnings, "No signal" banners, or layouts that shift when the carrier name changes. Detox
exposes `device.setStatusBar()` (iOS Simulator only) to override these values during a test,
and `device.resetStatusBar()` to restore defaults. Without the reset, status-bar overrides
bleed across the entire test session — always pair setter with `afterAll` reset.

```js
// e2e/statusbar.test.js
// device.setStatusBar() is iOS Simulator only — guard with platform check

describe('Status-bar-dependent UI', () => {
  const isIOS = device.getPlatform() === 'ios';

  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  afterAll(async () => {
    // ALWAYS reset — overrides persist across test files in the same session (Gotcha 58)
    if (isIOS) {
      await device.resetStatusBar();
    }
  });

  it('shows "Low Battery" banner when battery reaches 20%', async () => {
    if (!isIOS) {
      return; // setStatusBar only supported on iOS Simulator
    }

    await device.setStatusBar({
      batteryLevel: 0.2,   // 0.0–1.0 float — clamped to 2 decimal places (Gotcha 64)
      batteryState: 'discharging',
    });

    await waitFor(element(by.id('low-battery-banner')))
      .toBeVisible()
      .withTimeout(3000);

    await expect(element(by.id('low-battery-banner-text')))
      .toHaveText('Battery low — 20%');
  });

  it('shows airplane-mode indicator when network type is set to none', async () => {
    if (!isIOS) {
      return;
    }

    await device.setStatusBar({
      networkType: 'none',  // 'wifi' | 'cell' | 'none' | 'searching'
      time: '09:41',        // Freeze the displayed clock to avoid UI drift in screenshots
    });

    await waitFor(element(by.id('no-network-banner')))
      .toBeVisible()
      .withTimeout(3000);
  });

  it('hides cellular indicator when WiFi is active', async () => {
    if (!isIOS) {
      return;
    }

    await device.setStatusBar({
      networkType: 'wifi',
      wifiBars: 3,
      cellularBars: 0,
      time: '09:41',
    });

    await expect(element(by.id('cellular-icon'))).not.toBeVisible();
    await expect(element(by.id('wifi-icon'))).toBeVisible();
  });
});
```

**`device.setStatusBar()` field reference (iOS Simulator):**

| Field | Type | Values | Notes |
|-------|------|--------|-------|
| `time` | string | `'HH:MM'` | Freeze clock display (e.g., `'09:41'` for Apple's marketing time) |
| `batteryLevel` | number | `0.0–1.0` | Float; displayed as percentage — silently clamped at 2 decimal places |
| `batteryState` | string | `'charging'`, `'discharging'`, `'full'`, `'unknown'` | Must match OS-level state or display is inconsistent |
| `networkType` | string | `'wifi'`, `'cell'`, `'none'`, `'searching'` | Controls what network icon shows |
| `wifiBars` | number | `0–3` | Signal strength bars |
| `cellularBars` | number | `0–4` | Carrier signal bars |
| `operatorName` | string | any string | Carrier label override |
| `dataNetwork` | string | `'wifi'`, `'lte'`, `'5g'`, `'4g'`, `'3g'`, `'2g'`, `'edge'` | Data technology label |

**Android note**: `device.setStatusBar()` is not supported on Android. For Android status-bar
testing, use `adb shell` commands in `beforeAll` (e.g., `adb shell cmd connectivity airplane-mode enable`)
or test with `device.setURLBlacklist()` to simulate network-unavailable conditions instead.

---

### Pattern 50 — Detox + Allure reporting integration [community]

Allure is the most widely used HTML test reporter in enterprise RN projects. Integrating
Allure with Detox requires `allure-jest` (the Jest reporter) plus manual step API calls
inside test files to produce meaningful reports with screenshots, steps, and environment info.

```bash
# Install
npm install --save-dev allure-jest allure-commandline
```

```js
// jest.config.js — add allure-jest as a second reporter alongside the default
// WARNING: allure-jest must come AFTER the default reporter (Gotcha 64)
module.exports = {
  testEnvironment: 'detox/runners/jest/testEnvironment',
  testRunner: 'jest-circus/runner',
  reporters: [
    'default',
    ['allure-jest/node', {
      resultsDir: 'e2e/allure-results',
      environmentInfo: {
        Platform: process.env.DETOX_PLATFORM || 'ios',
        AppVersion: process.env.APP_VERSION || 'local',
        CI: process.env.CI ? 'true' : 'false',
      },
    }],
  ],
};
```

```js
// e2e/helpers/allure.js — thin wrapper to call Allure step API in Detox tests
// allure is a global injected by allure-jest reporter when configured above
// It exposes: allure.step(), allure.attachment(), allure.label(), allure.description()

/**
 * Wrap a Detox action in an Allure step so it appears as a named node in the report.
 * @param {string} name - Step title shown in the Allure report
 * @param {() => Promise<void>} fn - Async action to execute
 */
async function step(name, fn) {
  // allure global may be undefined if allure-jest is not configured
  if (typeof allure === 'undefined') {
    return fn();
  }
  return allure.step(name, fn);
}

/**
 * Attach a Detox screenshot to the current Allure step.
 * @param {string} name - Screenshot label shown in the report
 */
async function attachScreenshot(name) {
  if (typeof allure === 'undefined' || typeof device === 'undefined') return;
  const screenshotPath = await device.takeScreenshot(name);
  if (screenshotPath) {
    allure.attachment(name, require('fs').readFileSync(screenshotPath), 'image/png');
  }
}

module.exports = { step, attachScreenshot };
```

```js
// e2e/checkout.test.js — using the Allure step wrapper
const { step, attachScreenshot } = require('./helpers/allure');

describe('[smoke] Checkout flow', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  it('completes a purchase with a valid card', async () => {
    await step('Navigate to product listing', async () => {
      await element(by.id('shop-tab')).tap();
      await waitFor(element(by.id('product-list')))
        .toBeVisible()
        .withTimeout(5000);
    });

    await step('Add first product to cart', async () => {
      await element(by.id('product-item-0-add-button')).tap();
      await waitFor(element(by.id('cart-badge')))
        .toBeVisible()
        .withTimeout(3000);
    });

    await step('Proceed to checkout', async () => {
      await element(by.id('cart-button')).tap();
      await element(by.id('checkout-button')).tap();
      await waitFor(element(by.id('payment-screen')))
        .toBeVisible()
        .withTimeout(5000);
    });

    await attachScreenshot('payment-screen');

    await step('Enter payment details', async () => {
      await element(by.id('card-number-input')).replaceText('4242424242424242');
      await element(by.id('card-expiry-input')).replaceText('12/28');
      await element(by.id('card-cvc-input')).replaceText('123');
    });

    await step('Submit payment', async () => {
      await element(by.id('pay-button')).tap();
      await waitFor(element(by.id('order-confirmation-screen')))
        .toBeVisible()
        .withTimeout(10000);
    });

    await attachScreenshot('order-confirmation');
  });
});
```

```bash
# Generate and open the Allure HTML report
npx allure generate e2e/allure-results --clean -o e2e/allure-report
npx allure open e2e/allure-report
```

```yaml
# GitHub Actions — upload Allure results as artifact and generate report
- name: Run Detox tests
  run: npx detox test -c ios.sim.release --forceExit

- name: Upload Allure results
  if: always()   # upload even on test failure
  uses: actions/upload-artifact@v4
  with:
    name: allure-results-${{ matrix.shard }}
    path: e2e/allure-results/

- name: Generate Allure report (combine shards)
  if: always()
  run: |
    npx allure generate e2e/allure-results --clean -o e2e/allure-report
    echo "Report generated at e2e/allure-report/index.html"

- name: Upload Allure report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: allure-report
    path: e2e/allure-report/
```

**[community] WHY this matters**: Without structured steps in your report, a 60-test Detox run
produces a flat list of pass/fail entries with no insight into which user action failed. With
Allure steps + screenshot attachments on failure, the QA team can identify the exact failing
action without re-running the test locally — essential for CI-only failures.

---

### Pattern 51 — Network request interception via `launchArgs` and a lightweight mock server

Detox tests that depend on real API responses are fragile. The recommended pattern for
network-level isolation is to start a lightweight mock server (msw, nock, or a plain
`http.createServer`) before the test run, then use `launchArgs` to tell the app to point
at `http://localhost:<port>` instead of the real backend. This works for both iOS
(`localhost`) and Android (`10.0.2.2` — the emulator's host alias).

```js
// e2e/setup/mockServer.js — minimal HTTP mock server using Node's built-in http module
// No external dependencies beyond what Node 18+ provides

const http = require('http');

const routes = new Map();
let server = null;
let port = null;

/**
 * Register a mock route.
 * @param {string} method - HTTP method ('GET', 'POST', etc.)
 * @param {string} path   - URL path (exact match, e.g. '/api/products')
 * @param {object} body   - JSON response body
 * @param {number} [status=200] - HTTP status code
 */
function mockRoute(method, path, body, status = 200) {
  routes.set(`${method.toUpperCase()} ${path}`, { body, status });
}

/**
 * Start the mock server on a random available port.
 * Returns the base URL to inject into the app via launchArgs.
 */
async function startMockServer() {
  return new Promise((resolve, reject) => {
    server = http.createServer((req, res) => {
      const key = `${req.method} ${req.url}`;
      const route = routes.get(key);
      if (route) {
        res.writeHead(route.status, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(route.body));
      } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: `No mock for ${key}` }));
      }
    });

    server.listen(0, '127.0.0.1', () => {
      port = server.address().port;
      resolve(`http://127.0.0.1:${port}`);
    });

    server.on('error', reject);
  });
}

/** Stop the mock server and clear all registered routes. */
async function stopMockServer() {
  routes.clear();
  if (!server) return;
  return new Promise((resolve, reject) => {
    server.close((err) => {
      server = null;
      port = null;
      if (err) reject(err);
      else resolve();
    });
  });
}

module.exports = { mockRoute, startMockServer, stopMockServer };
```

```js
// e2e/products.test.js — test against mock API responses
const { mockRoute, startMockServer, stopMockServer } = require('./setup/mockServer');

describe('Product listing', () => {
  let baseUrl;

  beforeAll(async () => {
    // 1. Start mock server — gets a random free port (avoids collision on parallel workers, Gotcha 65)
    baseUrl = await startMockServer();

    // 2. Register mock responses
    mockRoute('GET', '/api/products', [
      { id: 1, name: 'Widget A', price: 9.99 },
      { id: 2, name: 'Widget B', price: 14.99 },
    ]);

    mockRoute('GET', '/api/products/1', { id: 1, name: 'Widget A', price: 9.99, stock: 42 });

    mockRoute('GET', '/api/products', { error: 'Service unavailable' }, 503);  // overrides previous on 503 variant
    // NOTE: last mockRoute for the same key wins — register error variants in separate describe blocks

    // 3. Launch app pointing at the mock server
    // The app must read API_BASE_URL from launchArgs when present (see app integration below)
    const androidBase = baseUrl.replace('127.0.0.1', '10.0.2.2');  // Gotcha 38: Android emulator host alias
    await device.launchApp({
      newInstance: true,
      launchArgs: {
        // iOS uses 127.0.0.1; Android uses 10.0.2.2 to reach the host machine
        API_BASE_URL: device.getPlatform() === 'android' ? androidBase : baseUrl,
      },
    });
  });

  afterAll(async () => {
    await stopMockServer();
  });

  it('renders the product list from mock API', async () => {
    await waitFor(element(by.id('product-list'))).toBeVisible().withTimeout(5000);
    await expect(element(by.id('product-item-1-name'))).toHaveText('Widget A');
    await expect(element(by.id('product-item-2-name'))).toHaveText('Widget B');
  });

  it('navigates to product detail on tap', async () => {
    await element(by.id('product-item-1-row')).tap();
    await waitFor(element(by.id('product-detail-screen'))).toBeVisible().withTimeout(3000);
    await expect(element(by.id('product-detail-stock'))).toHaveText('42 in stock');
  });
});
```

```js
// App integration — read API_BASE_URL from launchArgs in your React Native app
// index.js or App.js — read the URL from detox launchArgs if present

import { NativeModules } from 'react-native';

// Detox injects launchArgs into the native module 'DetoxUserNotificationDataModel' on iOS
// and as process.env equivalents via the Detox test environment on RN
// Simplest approach: use a custom native module or read from __DEV__ process args

const getLaunchArg = (key) => {
  // In tests, Detox's RN integration exposes launchArgs on `global.detoxArgs` (Detox 20+)
  // Fallback: read from env var set by the CI/CD pipeline
  if (typeof global.detoxArgs !== 'undefined' && global.detoxArgs[key]) {
    return global.detoxArgs[key];
  }
  return null;
};

export const API_BASE_URL =
  getLaunchArg('API_BASE_URL') ?? 'https://api.production.example.com';
```

**Android port forwarding note**: For Android emulators, the mock server runs on the host
machine at `127.0.0.1:PORT`. The emulator reaches the host via `10.0.2.2`. Alternatively, use
`adb reverse tcp:PORT tcp:PORT` in `beforeAll` to mirror the port into the emulator so the
app can use `localhost:PORT` on both platforms:

```js
// e2e/products.test.js — adb reverse alternative for Android
// Requires Bash access in the test environment (CI pre-step or Jest globalSetup)
const { execSync } = require('child_process');

beforeAll(async () => {
  baseUrl = await startMockServer();
  if (device.getPlatform() === 'android') {
    // Mirror the host port into the emulator — app can then use 'localhost:PORT'
    execSync(`adb reverse tcp:${port} tcp:${port}`);
  }
  await device.launchApp({ newInstance: true, launchArgs: { API_BASE_URL: baseUrl } });
});
```

---

### Pattern 52 — `toHaveText()` / `toHaveLabel()` / `toHaveValue()` disambiguation guide

These three assertion methods are superficially similar but test completely different
accessibility properties of a React Native element. Misusing them is one of the most common
causes of assertions that pass locally but fail after an accessibility audit forces a refactor.

| Method | What it reads | RN prop that sets it | Typical use |
|--------|--------------|----------------------|-------------|
| `toHaveText(str)` | The **visible text** rendered by a `<Text>` component | `children` of `<Text>` | Asserting text content in `<Text>`, `<Button>` title |
| `toHaveLabel(str)` | The **accessibility label** (`accessibilityLabel` prop) | `accessibilityLabel` | Asserting descriptive label for screen readers; icons, images |
| `toHaveValue(str)` | The **accessibility value** (`accessibilityValue.text`) | `accessibilityValue={{ text: '...' }}` | Asserting slider %, progress %, custom state |

```js
// Example: all three on different elements

// A <Text> component — use toHaveText for its rendered content
await expect(element(by.id('price-label'))).toHaveText('$9.99');

// An icon button with no visible text — use toHaveLabel
// The button has: <TouchableOpacity testID="cart-button" accessibilityLabel="Shopping cart, 3 items">
await expect(element(by.id('cart-button'))).toHaveLabel('Shopping cart, 3 items');

// A slider — use toHaveValue to read its current position
// The slider has: accessibilityValue={{ text: '75%' }}
await expect(element(by.id('volume-slider'))).toHaveValue('75%');
```

```js
// Real-world ambiguity: a component that sets BOTH accessibilityLabel AND renders <Text>
// <TouchableOpacity testID="submit-btn" accessibilityLabel="Submit form">
//   <Text>Submit</Text>
// </TouchableOpacity>

// WRONG — toHaveText looks at <Text> children inside the element tree
// This may return 'Submit' OR throw if Detox sees it as a non-Text element
await expect(element(by.id('submit-btn'))).toHaveText('Submit');  // brittle

// CORRECT — for a TouchableOpacity, assert what screen readers announce: the accessibilityLabel
await expect(element(by.id('submit-btn'))).toHaveLabel('Submit form');  // stable

// ALSO VALID — when the label is not set and you want to verify rendered text of the nested Text
await expect(element(by.text('Submit'))).toBeVisible();  // selector-based, no assertion needed
```

```js
// toHaveToggleValue — for Switch / Checkbox / RadioButton state
// Returns boolean (true/false), NOT a string — distinct from toHaveValue
// Switch: <Switch testID="notifications-toggle" value={enabled} />
await expect(element(by.id('notifications-toggle'))).toHaveToggleValue(true);

// toHaveValue — for accessibilityValue (returns string, not boolean!)
// If a Switch sets accessibilityValue={{ text: 'On' }}, use:
await expect(element(by.id('notifications-toggle'))).toHaveValue('On');
// But prefer toHaveToggleValue(true) which is type-safe for Switch/Checkbox state
```

**Decision guide:**
1. Is the element a `<Switch>`, `<CheckBox>`, or toggle control? → `toHaveToggleValue(bool)`
2. Does the element have `accessibilityValue` set (slider, progress bar, custom control)? → `toHaveValue(string)`
3. Does the element have `accessibilityLabel` explicitly set? → `toHaveLabel(string)` for stable assertion
4. Is the element a `<Text>` or has visible text as its primary content? → `toHaveText(string)`
5. When unsure: `element.getAttributes()` to inspect all properties at once, then choose

---

## Real-World Gotchas (iteration 47 additions)

### 64. `device.setStatusBar()` `batteryLevel` float precision is silently clamped [community]

**Root cause**: `device.setStatusBar({ batteryLevel: 0.157 })` silently rounds to 2 decimal
places, displaying `16%` in the status bar instead of `15.7%`. UI assertions like
`toHaveText('Battery: 15.7%')` that read the raw float from a label that also displays the
battery value will fail when the label uses the same value that was passed to `setStatusBar`.

**Why it matters**: This only manifests when you're testing a UI component that reads and
displays the iOS system battery level (via `react-native-battery` or a native module), and
your `toHaveText` assertion uses a string derived from the test's float constant rather than
the rounded value that the OS actually reports.

**Fix**: Round the value before passing it and before constructing expected text strings:

```js
// WRONG — float precision mismatch
const batteryLevel = 0.157;
await device.setStatusBar({ batteryLevel, batteryState: 'discharging' });
await expect(element(by.id('battery-text'))).toHaveText(`${batteryLevel * 100}%`); // '15.7%'

// CORRECT — use Math.round for two-decimal consistency
const batteryLevel = 0.16; // or: Math.round(0.157 * 100) / 100
await device.setStatusBar({ batteryLevel, batteryState: 'discharging' });
await expect(element(by.id('battery-text'))).toHaveText('16%');
```

---

### 65. Mock server port conflicts on parallel Detox workers [community]

**Root cause**: When multiple Jest workers run simultaneously (parallel config, GitHub Actions
matrix), each worker starts its own mock server. If the port is hard-coded (e.g., `8080`),
the second worker fails to bind with `EADDRINUSE`. This causes the test's `beforeAll` to
throw and all tests in that worker to fail with a misleading `Cannot read properties of null
(reading 'address')` error — not an obvious port conflict message.

**Fix**: Always use port `0` (OS-assigned ephemeral port) for mock servers started inside
test suites. The pattern in Pattern 51 already does this (`server.listen(0, ...)`). If you
share a single server across workers via `globalSetup`, use `JEST_WORKER_ID` to allocate
distinct base ports:

```js
// e2e/globalSetup.js — only if you need a shared server across all workers
// Use a port range based on JEST_WORKER_ID to avoid binding conflicts
const BASE_PORT = 8080;
const workerPort = BASE_PORT + parseInt(process.env.JEST_WORKER_ID || '1', 10);
server.listen(workerPort, '127.0.0.1', ...);
// Store port in process.env so tests can read it
process.env.MOCK_SERVER_PORT = String(workerPort);
```

---

### 66. `toHaveLabel()` vs `toHaveText()` ordering ambiguity on double-accessible elements [community]

**Root cause**: Some RN components set *both* `accessibilityLabel` and render `<Text>` children.
On iOS, when `accessibilityLabel` is set, VoiceOver announces the label and ignores the text.
But Detox's `toHaveText()` traverses the view hierarchy looking for a `<Text>` child, while
`toHaveLabel()` reads the `accessibilityLabel` prop at the root. If the two strings differ
(e.g., label is localized, text is raw), you may have a test that passes in English and fails
in French because `toHaveText()` finds the English fallback text child while the label is in
French.

**Fix**: In test code, always assert what the user *experiences* (the `accessibilityLabel`)
rather than the implementation detail (raw text). Coordinate with developers to ensure
`accessibilityLabel` is always set explicitly on interactive elements.

```js
// BRITTLE — may fail when locale changes or label is reformatted
await expect(element(by.id('welcome-message'))).toHaveText('Bienvenue, Alice');

// STABLE — reads accessibilityLabel which is the contract for screen reader users
await expect(element(by.id('welcome-message'))).toHaveLabel('Bienvenue, Alice');
```

---

### 67. Detox server port collision in monorepo multi-configuration CI [community]

**Root cause**: In a monorepo where multiple apps run Detox in separate CI jobs on the
same GitHub Actions runner, Detox's internal WebSocket server defaults to port `8099`.
When two Detox jobs start concurrently (e.g., job matrix with `app-a` and `app-b`), the
second process to bind fails with `listen EADDRINUSE :::8099` in its Detox setup log.
The test run starts but all device commands silently fail because the Detox server never
connected — the error appears as a generic `"No device found"` or connection timeout.

**Fix**: Set a unique `server.port` per app in `.detoxrc.js`, or use the `DETOX_SERVER_PORT`
environment variable in the CI matrix:

```js
// apps/app-a/.detoxrc.js
module.exports = {
  server: {
    port: 8099,   // default
  },
  // ...
};

// apps/app-b/.detoxrc.js
module.exports = {
  server: {
    port: 8100,   // distinct port for the second app
  },
  // ...
};
```

```yaml
# Alternatively — use env var in the CI matrix to avoid editing .detoxrc.js
jobs:
  detox:
    strategy:
      matrix:
        app: [app-a, app-b]
        include:
          - app: app-a
            detox_port: 8099
          - app: app-b
            detox_port: 8100
    steps:
      - name: Run Detox
        run: npx detox test -c ios.sim.release
        working-directory: apps/${{ matrix.app }}
        env:
          DETOX_SERVER_PORT: ${{ matrix.detox_port }}
```

---

### 68. React Native 0.79+ Metro lazy-require increases cold-start wait thresholds [community]

**Root cause**: React Native 0.79 introduced opt-in Metro lazy bundling (`lazyImports: true`
in `metro.config.js`). With lazy bundling, module resolution happens on first `require()`
call rather than at bundle load. This means the JS thread is busy resolving modules for
several extra seconds after the bundle JS has "loaded" — Detox's idle detector may prematurely
declare the app idle before all modules are initialized, causing the first `waitFor()` to
time out because the target screen hasn't registered its navigation route yet.

**Symptoms**: Tests fail intermittently on the very first `waitFor()` after `launchApp()`;
lowering timeouts does not help; tests pass when lazy bundling is disabled.

**Fix option 1 — Increase `withTimeout` for post-launch navigations** from the default
`5000` ms to `12000` ms in suites that cold-start the app. Use a named constant so it's easy
to revert when Metro stabilizes:

```js
// e2e/constants.js
const COLD_START_TIMEOUT = 12000;  // RN 0.79+ lazy bundling adds ~4s module init time
const NAV_TIMEOUT        = 5000;   // normal navigation between pre-loaded screens
module.exports = { COLD_START_TIMEOUT, NAV_TIMEOUT };

// e2e/auth.test.js
const { COLD_START_TIMEOUT } = require('./constants');

it('reaches the login screen after cold start', async () => {
  await waitFor(element(by.id('login-screen')))
    .toBeVisible()
    .withTimeout(COLD_START_TIMEOUT);   // 12s for lazy-bundle cold start
});
```

**Fix option 2 — Disable lazy bundling in the test build** via a Detox-specific Metro config:

```js
// metro.config.js — disable lazy bundling only for the detox build type
const isDetox = process.env.DETOX_CONFIGURATION !== undefined;

module.exports = {
  transformer: {
    lazyImports: isDetox ? false : true,  // eager bundling in Detox builds only
  },
};
```

---

### 69. `jest-circus` `afterAll` ordering causes `device.terminateApp()` deadlock [community]

**Root cause**: `jest-circus` (the default Jest runner since Jest 27, and Detox 20's required
runner) executes `afterAll` hooks in the reverse order they were registered across nested
`describe` blocks. If a nested `describe` registers `afterAll(() => device.terminateApp())`
and an outer `describe` or `beforeAll` at file scope registered the app launch, `jest-circus`
may call `terminateApp()` before Detox has fully flushed the pending action queue from the
inner test. This causes a deadlock: Detox is waiting for the app to respond to an in-flight
action, but the app has been terminated.

**Fix**: Only call `device.terminateApp()` or `device.launchApp({ newInstance: true })` in
the **outermost** `describe` block's `afterAll`. Nested `describe` blocks should use
`device.reloadReactNative()` for between-test cleanup, never `terminateApp()`:

```js
// WRONG — nested terminateApp can deadlock if inner test's afterAll fires before completion
describe('Checkout flow', () => {
  describe('Payment step', () => {
    afterAll(async () => {
      await device.terminateApp();  // DANGEROUS — may fire while outer cleanup is in-flight
    });
    // ...
  });
});

// CORRECT — only the outermost describe manages app lifecycle
describe('Checkout flow', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });
  afterAll(async () => {
    await device.terminateApp();  // safe — last hook to run for this file
  });

  describe('Payment step', () => {
    beforeEach(async () => {
      await device.reloadReactNative();  // JS-only reset — no lifecycle risk
    });
    // ...
  });
});
```

---

### 70. Allure `stepStatus` collides with Detox `afterEach` cleanup on test failure [community]

**Root cause**: When an `allure.step()` wrapping a Detox action throws (the test fails),
Allure records the step as `failed` and marks the test as complete before `afterEach` has
a chance to run. `afterEach` then calls `device.reloadReactNative()`, which succeeds
normally. But the subsequent test inherits the Allure context from the failed step's
`allure.step()` closure, because Allure's step context is thread-local to the Jest worker
and wasn't properly closed when the exception propagated. The next test's steps appear
as children of the previous test's failed step in the Allure report tree — producing a
single parent node with two test's worth of steps.

**Fix**: Always close the Allure step context using a `try/finally` wrapper, and never
start a new `allure.step()` in `beforeEach` (only in `it()` bodies). The wrapper in
Pattern 50's `e2e/helpers/allure.js` already uses Allure's built-in step callback
signature which handles this; the issue arises when teams write `allure.step(name); ...;
allure.stepStatus('passed')` manually instead of using the callback form:

```js
// WRONG — manual stepStatus management leaks context on exception
async function doLogin() {
  allure.step('Enter credentials');
  await element(by.id('email-input')).replaceText('user@test.com');
  await element(by.id('password-input')).replaceText('secret');
  allure.stepStatus('passed');   // NEVER REACHED if replaceText throws
}

// CORRECT — use the callback form (auto-closes on exception)
async function doLogin() {
  await allure.step('Enter credentials', async () => {
    await element(by.id('email-input')).replaceText('user@test.com');
    await element(by.id('password-input')).replaceText('secret');
  });
}
```

---

### Pattern 53 — React Navigation v7 static configuration and testID-screen mapping for deep navigation testing

React Navigation v7 (released 2025) introduced a **static API** for route configuration
(`createStaticNavigation`) that replaces the JSX tree approach. Detox tests that previously
relied on navigating through screens interactively benefit greatly from a centralized
`SCREEN_TEST_IDS` map that ties route names to their primary `testID` — this makes navigation
assertions deterministic regardless of how deep in the stack the test starts.

```js
// navigation/screens.js — centralized testID map (shared between app and e2e)
// React Navigation v7 static config approach
const SCREENS = {
  Home:       { testID: 'home-screen',        route: 'Home' },
  Login:      { testID: 'login-screen',       route: 'Login' },
  Dashboard:  { testID: 'dashboard-screen',   route: 'Dashboard' },
  ProductList:{ testID: 'product-list-screen',route: 'ProductList' },
  Cart:       { testID: 'cart-screen',        route: 'Cart' },
  Checkout:   { testID: 'checkout-screen',    route: 'Checkout' },
  Settings:   { testID: 'settings-screen',    route: 'Settings' },
};

module.exports = { SCREENS };
```

```js
// In each screen component — apply the testID to the root View
// screens/HomeScreen.js
import { SCREENS } from '../navigation/screens';
export function HomeScreen() {
  return (
    <View testID={SCREENS.Home.testID} style={styles.container}>
      {/* ... */}
    </View>
  );
}
```

```js
// e2e/helpers/navigation.js — screen-wait helper using the shared map
const { SCREENS } = require('../../navigation/screens');
const { TIMEOUT } = require('../constants');

/**
 * Wait for a named screen to become visible.
 * @param {keyof typeof SCREENS} screenName
 */
async function waitForScreen(screenName) {
  const screen = SCREENS[screenName];
  if (!screen) throw new Error(`Unknown screen: ${screenName}`);
  await waitFor(element(by.id(screen.testID)))
    .toBeVisible()
    .withTimeout(TIMEOUT.long);
}

/**
 * Assert a named screen is currently visible (no wait).
 */
async function expectScreen(screenName) {
  const screen = SCREENS[screenName];
  if (!screen) throw new Error(`Unknown screen: ${screenName}`);
  await expect(element(by.id(screen.testID))).toBeVisible();
}

module.exports = { waitForScreen, expectScreen };
```

```js
// e2e/checkout.test.js — using the helpers
const { waitForScreen, expectScreen } = require('./helpers/navigation');

describe('Checkout flow', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true, permissions: { notifications: 'YES' } });
  });

  beforeEach(async () => {
    await device.reloadReactNative();
    await loginAs('user');
    await waitForScreen('Dashboard');
  });

  it('completes a purchase from cart to confirmation', async () => {
    await element(by.id('shop-tab')).tap();
    await waitForScreen('ProductList');

    await element(by.id('product-item-1-add-to-cart')).tap();
    await element(by.id('cart-tab')).tap();
    await waitForScreen('Cart');

    await element(by.id('checkout-button')).tap();
    await waitForScreen('Checkout');

    await element(by.id('place-order-button')).tap();
    await waitForScreen('OrderConfirmation');
    await expect(element(by.id('order-number'))).toBeVisible();
  });
});
```

**React Navigation v7 `createStaticNavigation` compatibility note [community]**: In v7 static config,
screen `name` props are inferred from the object key — the route name IS the object key.
If you use `createStaticNavigation` and rename a key, all deep-link URLs and `navigate('RouteName')`
calls change silently. The `SCREENS` map above makes the testID the single source of truth;
rename the key in one place to update tests, app code, and assertions simultaneously.

---

### Pattern 54 — `device.reverseTcp()` and `reversePorts` advanced Android network routing

Android Emulators run inside a virtual network where `localhost` and `127.0.0.1` refer to
the emulator's own loopback interface, not the host machine. Detox mock servers running on
the host are unreachable unless you explicitly reverse the port. There are two mechanisms:

| Mechanism | When to use | How it works |
|-----------|------------|-------------|
| `reversePorts` in `.detoxrc.js` | Detox-managed setup — runs `adb reverse` automatically before app launch | Declarative, CI-safe |
| `device.reverseTcp(port)` | Dynamic port numbers only known at test runtime (e.g., OS-assigned mock server port) | Imperative, call inside `beforeAll` |

```js
// .detoxrc.js — use reversePorts for known, fixed ports (preferred)
module.exports = {
  apps: {
    'android.debug': {
      type: 'android.apk',
      binaryPath: '...',
      reversePorts: [8088, 8089],  // adb reverse tcp:8088 tcp:8088 before launch
    },
  },
};
```

```js
// e2e/setup.js — use device.reverseTcp() for OS-assigned dynamic ports
const { createServer } = require('http');

let mockServer;
let mockPort;

beforeAll(async () => {
  // Start mock server on an OS-assigned port (port 0)
  mockServer = createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
  });

  await new Promise((resolve) => {
    mockServer.listen(0, '127.0.0.1', () => {
      mockPort = mockServer.address().port;
      resolve();
    });
  });

  // Reverse the dynamically-assigned port into the emulator
  if (device.getPlatform() === 'android') {
    await device.reverseTcp(mockPort);
  }

  // Launch app with the dynamic port — emulator can reach it via localhost
  await device.launchApp({
    newInstance: true,
    launchArgs: { API_BASE_URL: `http://localhost:${mockPort}` },
  });
});

afterAll(async () => {
  await new Promise((resolve) => mockServer.close(resolve));
});
```

```js
// Cross-platform helper — use 10.0.2.2 as fallback when reverseTcp is unavailable
function getBaseUrl(port) {
  if (device.getPlatform() === 'android' && !process.env.DETOX_REVERSE_TCP) {
    // Fallback: hardcoded Android emulator host alias
    // Use this ONLY if reverseTcp/reversePorts are not configured
    return `http://10.0.2.2:${port}`;
  }
  return `http://localhost:${port}`;
}
```

**Important constraints [community]:**
- `device.reverseTcp()` must be called AFTER `device.launchApp()` on some Android versions.
  If the app makes API calls during initialization (splash screen), call `reverseTcp` before
  `launchApp` — but this requires the mock server to be running first (catch-22 with dynamic
  ports). Resolution: use a fixed port for the mock server when you need it available
  during app init.
- `adb reverse` tunnels only work over USB or local ADB — they do NOT work on cloud device
  farms (AWS Device Farm, Sauce Labs) where the ADB connection goes through a proxy. Use
  HTTPS endpoints with a real staging server on cloud farms.
- Multiple emulators on the same machine each have their own ADB connection. When running
  parallel Detox workers, each worker's emulator needs its own `adb -s <serial> reverse`
  call. `device.reverseTcp()` routes to the correct emulator automatically when Detox manages
  the device — do not call raw `adb reverse` from test code.

---

### Pattern 55 — GitHub Actions step summary integration for Detox test results

GitHub Actions supports writing Markdown content to `$GITHUB_STEP_SUMMARY` — a file that
renders as a formatted summary table on the Actions run page. Adding a Detox summary hook
gives you pass/fail counts, timing, and artifact links without leaving the GitHub UI.

```js
// e2e/reporters/github-summary.js — custom Jest reporter for GitHub Actions
const fs = require('fs');
const path = require('path');

class GitHubSummaryReporter {
  constructor(globalConfig, options) {
    this._options = options || {};
    this._results = [];
    this._startTime = Date.now();
  }

  onTestResult(test, testResult) {
    this._results.push({
      file: path.relative(process.cwd(), test.testFilePath),
      passed: testResult.numPassingTests,
      failed: testResult.numFailingTests,
      skipped: testResult.numPendingTests,
      duration: testResult.perfStats.end - testResult.perfStats.start,
      failures: testResult.testResults
        .filter((r) => r.status === 'failed')
        .map((r) => ({ name: r.fullName, message: r.failureMessages[0]?.slice(0, 200) })),
    });
  }

  onRunComplete() {
    const summaryFile = process.env.GITHUB_STEP_SUMMARY;
    if (!summaryFile) return;  // no-op outside GitHub Actions

    const totalPassed  = this._results.reduce((s, r) => s + r.passed, 0);
    const totalFailed  = this._results.reduce((s, r) => s + r.failed, 0);
    const totalSkipped = this._results.reduce((s, r) => s + r.skipped, 0);
    const elapsed = ((Date.now() - this._startTime) / 1000).toFixed(1);

    const status = totalFailed === 0 ? '✅ Passed' : '❌ Failed';
    const shard = process.env.DETOX_SHARD_INDEX
      ? ` (shard ${process.env.DETOX_SHARD_INDEX}/${process.env.DETOX_SHARD_COUNT})`
      : '';

    let md = `## Detox E2E Results${shard} — ${status}\n\n`;
    md += `| Metric | Value |\n|--------|-------|\n`;
    md += `| Total passed | ${totalPassed} |\n`;
    md += `| Total failed | ${totalFailed} |\n`;
    md += `| Total skipped | ${totalSkipped} |\n`;
    md += `| Duration | ${elapsed}s |\n\n`;

    if (totalFailed > 0) {
      md += `### Failures\n\n`;
      for (const result of this._results.filter((r) => r.failures.length > 0)) {
        md += `**${result.file}**\n`;
        for (const failure of result.failures) {
          md += `- \`${failure.name}\`: ${failure.message}\n`;
        }
      }
      md += '\n';
    }

    // Link to artifacts uploaded by the upload-artifact step
    if (process.env.GITHUB_RUN_ID) {
      md += `[View Detox artifacts](https://github.com/${process.env.GITHUB_REPOSITORY}/actions/runs/${process.env.GITHUB_RUN_ID})\n`;
    }

    fs.appendFileSync(summaryFile, md);
  }
}

module.exports = GitHubSummaryReporter;
```

```js
// e2e/jest.config.js — add the summary reporter alongside the default Detox reporter
module.exports = {
  rootDir: '..',
  testMatch: ['<rootDir>/e2e/**/*.test.js'],
  testTimeout: 120000,
  globalSetup: 'detox/runners/jest/globalSetup',
  globalTeardown: 'detox/runners/jest/globalTeardown',
  testEnvironment: 'detox/runners/jest/testEnvironment',
  reporters: [
    'detox/runners/jest/reporter',        // standard Detox console output
    ['<rootDir>/e2e/reporters/github-summary.js', {}],  // GitHub Actions summary
    // Optional: jest-junit for TCMS integration
    ['jest-junit', {
      outputDirectory: '<rootDir>/test-results',
      outputName: `junit-shard-${process.env.DETOX_SHARD_INDEX || '1'}.xml`,
      classname: '{classname}',
      title: '{title}',
    }],
  ],
};
```

```yaml
# .github/workflows/e2e.yml — full iOS Detox CI with step summary
name: Detox E2E

on: [push, pull_request]

jobs:
  e2e-ios:
    runs-on: macos-14
    strategy:
      matrix:
        shard: [1, 2, 3]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Cache Detox build
        uses: actions/cache@v4
        with:
          path: ios/build
          key: detox-ios-${{ hashFiles('ios/**/*.xcodeproj', 'ios/Podfile.lock') }}

      - name: Build for Detox
        run: npx detox build -c ios.sim.release

      - name: Run Detox tests (shard ${{ matrix.shard }}/3)
        env:
          DETOX_SHARD_INDEX: ${{ matrix.shard }}
          DETOX_SHARD_COUNT: 3
        run: |
          npx detox test -c ios.sim.release \
            --shard-index ${{ matrix.shard }} \
            --shard-count 3 \
            --loglevel warn \
            --record-logs failing \
            --artifacts-location .artifacts

      - name: Upload test artifacts
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: detox-artifacts-shard-${{ matrix.shard }}
          path: .artifacts/
          retention-days: 7

      - name: Upload JUnit results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: junit-shard-${{ matrix.shard }}
          path: test-results/junit-shard-${{ matrix.shard }}.xml
```

**Shard index environment variable note [community]**: The `DETOX_SHARD_INDEX` and
`DETOX_SHARD_COUNT` env vars used in the reporter are custom conventions — set them yourself
in the workflow `env:` block before calling `detox test`. Detox does not set them
automatically; the `--shard-index`/`--shard-count` CLI flags control Detox's test splitting
independently of environment variables.

---

### 71. React Native 0.80+ Package Exports (`exports` field in `package.json`) breaks Detox Metro resolver [community]

**Root cause**: React Native 0.80 (released Q2 2026) enables **Package Exports** resolution
by default in Metro (`resolver.unstable_enablePackageExports: true` becomes the default). Many
Detox-compatible libraries (e.g., `react-native-mmkv`, `react-native-reanimated`, certain
internal Detox test utilities) export sub-paths using the `exports` field that differ between
`react-native` and `node` conditions. When Metro resolves these with the `react-native`
condition during a Detox build (which runs in a Node.js test environment, not a bundled
runtime), it may pick the wrong export variant, causing `SyntaxError: Unexpected token`
crashes at import time.

**Symptoms**: App launches in Detox, immediately throws in `globalSetup` or during the first
`launchApp`, with a Metro error referencing a file inside `node_modules` that uses ESM syntax
(`export default`, `import`).

**Fix**: Pin `resolver.unstable_enablePackageExports` to `false` in the Metro config used for
Detox builds only:

```js
// metro.config.js — disable Package Exports for Detox build compatibility
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

const defaultConfig = getDefaultConfig(__dirname);

const detoxCompatConfig = process.env.DETOX_CONFIGURATION
  ? {
      resolver: {
        // Revert to classic file-extension resolution until affected deps update
        unstable_enablePackageExports: false,
      },
    }
  : {};

module.exports = mergeConfig(defaultConfig, detoxCompatConfig);
```

Then set `DETOX_CONFIGURATION` in your Detox build command:

```bash
DETOX_CONFIGURATION=ios.sim.release npx detox build -c ios.sim.release
DETOX_CONFIGURATION=ios.sim.release npx detox test -c ios.sim.release
```

Or add it to `.detoxrc.js` as a build-time environment variable:

```js
// .detoxrc.js — pass env var to the xcodebuild step
apps: {
  'ios.release': {
    type: 'ios.app',
    binaryPath: '...',
    build: 'DETOX_CONFIGURATION=ios.sim.release xcodebuild ...',
  },
},
```

---

### 72. iOS 18.2+ Settings app restructure breaks `by.system()` location permission dialogs [community]

**Root cause**: iOS 18.2 reorganized the Settings app — the **Privacy & Security** section was
renamed to **Privacy** and location permission sub-menus moved one level deeper. Any
`by.system()` workflow that navigated through the Settings app hierarchy (e.g., to change a
previously-denied permission from "Never" to "While Using") now fails because the element
path has changed.

This is distinct from the iOS 18.0 "Precise Location" prompt (Gotcha 57) — that affects
runtime dialogs. This gotcha affects tests that use `device.openURL('App-Prefs:')` or
`by.system()` to navigate Settings app screens for mid-test permission changes.

**WHY it matters for Detox**: Teams that test "user denies, then re-grants" permission flows
drive the Settings app navigation via `by.system()` label matching. The label map from iOS 18.1
is incompatible with iOS 18.2+.

**Fix**: Use a locale-aware, version-aware label map with an `os.version` branch:

```js
// e2e/helpers/settings-nav.js — iOS version-aware Settings navigation labels
const { version: osVersionStr } = require('os');

/**
 * Returns the Settings app label path for location permissions.
 * Differs between iOS 18.0–18.1 and 18.2+.
 */
function getLocationPermissionLabels() {
  // device.getPlatform() === 'ios' is a precondition — always guard before calling
  // Parse the iOS version from device attributes if available
  // Fallback: use the conservative 18.2+ path (more levels, works on both)
  return {
    privacySection: 'Privacy',          // was 'Privacy & Security' in iOS 16/17
    locationServices: 'Location Services',
    appPermission: 'While Using the App',
  };
}

// e2e/helpers/grant-location-mid-test.js
async function reGrantLocationPermission(appName = 'MyApp') {
  if (device.getPlatform() !== 'ios') return;

  const labels = getLocationPermissionLabels();

  // Open Settings directly to Location Services (deep link avoids menu traversal)
  await device.openURL({ url: 'App-Prefs:Privacy&path=LOCATION' });

  // Wait for the Location Services screen
  await waitFor(element(by.system().label(labels.locationServices)))
    .toBeVisible()
    .withTimeout(5000);

  // Tap the app entry
  await element(by.system().label(appName)).tap();

  // Set to "While Using"
  await element(by.system().label(labels.appPermission)).tap();

  // Return to the app
  await device.launchApp({ newInstance: false });
}

module.exports = { reGrantLocationPermission };
```

---

### 73. Android Gradle 8.x + AGP 8.4+ build flag changes break Detox release builds [community]

**Root cause**: Android Gradle Plugin (AGP) 8.4+ changed how debug symbols are packaged.
The flag `android.enableDexingArtifactTransform.desugaring` was removed, and several
`gradle.properties` flags that Detox instrumentation builds relied on for reproducible
output paths are now no-ops that emit deprecation warnings — or cause build failures when
set alongside `buildFeatures.buildConfig = true` which is now required explicitly.

**Symptoms**: `npx detox build -c android.emu.release` fails with:
```
> Could not set unknown property 'enableDexingArtifactTransform.desugaring'
```
or the build succeeds but `device.launchApp()` hangs with "Could not find test APK at..."
because the output path changed from `app/build/outputs/apk/release/app-release.apk` to
a path variant under `app/build/outputs/apk/release/app-release-unsigned.apk`.

**Fix**: Update `android/gradle.properties` and `android/app/build.gradle`:

```properties
# android/gradle.properties — remove deprecated flags for AGP 8.4+
# DELETE these lines if present:
# android.enableDexingArtifactTransform.desugaring=false
# android.enableDexingArtifactTransform=false

# ADD: explicitly opt into R8 full mode for release builds (AGP 8.4+ default)
android.enableR8.fullMode=true
```

```groovy
// android/app/build.gradle — add buildConfig feature and fix output path
android {
    buildFeatures {
        buildConfig true  // Required explicitly in AGP 8.4+
    }
    buildTypes {
        release {
            // AGP 8.4+: signing config required even for debug keys in CI
            signingConfig signingConfigs.debug  // use debug key for Detox builds
            minifyEnabled false  // disable for Detox — Detox needs uninstrumented code
        }
    }
}
```

```js
// .detoxrc.js — handle signed vs unsigned APK path depending on AGP version
apps: {
  'android.release': {
    type: 'android.apk',
    // AGP 8.4+: unsigned path when no signing config is set for release
    binaryPath: process.env.AGP_SIGNED_RELEASE
      ? 'android/app/build/outputs/apk/release/app-release.apk'
      : 'android/app/build/outputs/apk/release/app-release-unsigned.apk',
    testBinaryPath: 'android/app/build/outputs/apk/androidTest/release/app-release-androidTest.apk',
    build: 'cd android && ./gradlew assembleRelease assembleAndroidTest -DtestBuildType=release',
    reversePorts: [8088],
  },
},
```

---

### 74. `device.setLocation()` on Android Emulator API 35 requires cold-start app restart to propagate [community]

**Root cause**: Android 15 (API 35) tightened location privacy by requiring apps to re-request
location data after the GPS coordinates change at the OS level. On API 35+, calling
`device.setLocation(lat, lon)` from Detox updates the emulator's mocked GPS but the app's
`FusedLocationProvider` cache returns the previous coordinates until the app process restarts.
This does not occur on API 33/34 or on iOS Simulator (which pushes location updates
via `CoreLocation` callback immediately).

**WHY it's hard to detect**: `device.setLocation()` returns without error. The app's location
UI may update eventually (after the cache TTL of ~30 seconds), but assertions that fire
within 5 seconds see stale coordinates.

**Fix**: Call `device.setLocation()` before launching the app (or after a newInstance
restart):

```js
describe('Location-aware features', () => {
  // Set location BEFORE launchApp — ensures the emulator is at the target coordinates
  // when the app initializes FusedLocationProvider on API 35+
  beforeAll(async () => {
    if (device.getPlatform() === 'android') {
      // Set coordinates first, then launch — avoids cache-stale issue on API 35+
      await device.setLocation(37.7749, -122.4194);  // San Francisco
    }
    await device.launchApp({
      newInstance: true,
      permissions: { location: 'always' },
      launchArgs: { E2E_SKIP_LOCATION_CACHE: '1' },  // optional: bypass app-level cache
    });
    if (device.getPlatform() === 'ios') {
      // iOS: setLocation works at any time — fine to call after launch
      await device.setLocation(37.7749, -122.4194);
    }
  });

  it('shows stores near San Francisco', async () => {
    await element(by.id('find-nearby-button')).tap();
    await waitFor(element(by.id('store-list-item-0')))
      .toBeVisible()
      .withTimeout(10000);
    await expect(element(by.id('store-location-badge'))).toHaveText('San Francisco, CA');
  });

  afterEach(async () => {
    // Reset to null island between tests to prevent stale location state
    await device.setLocation(0, 0);
  });
});
```

**API 35 CI matrix note**: If your CI runs tests against multiple API levels, always verify
which API the emulator is running before applying this workaround:

```js
// e2e/helpers/android-api-level.js
const { execSync } = require('child_process');

function getAndroidApiLevel() {
  if (device.getPlatform() !== 'android') return null;
  try {
    const serial = process.env.ANDROID_SERIAL || '';
    const args = serial ? `-s ${serial}` : '';
    const output = execSync(`adb ${args} shell getprop ro.build.version.sdk`, { timeout: 5000 })
      .toString()
      .trim();
    return parseInt(output, 10);
  } catch {
    return null;
  }
}

module.exports = { getAndroidApiLevel };
```

---

### 75. Detox test `withTimeout` silently extends when `device.reloadReactNative()` is called inside a `waitFor` scope [community]

**Root cause**: `device.reloadReactNative()` re-boots the React Native JS bundle. Any
`waitFor(...).withTimeout(N)` call that is in progress when `reloadReactNative()` is called
will have its timer reset — because Detox's synchronization engine restarts from idle-detected
baseline after the reload completes. The `withTimeout` clock does not freeze during the reload;
it restarts. This means a test can run far longer than its declared timeout without Jest
enforcing it — Jest's `testTimeout` applies to the full test, but the `withTimeout` inside
`waitFor` is a Detox-internal deadline.

**WHY it causes silent CI slowdowns**: A `waitFor(...).withTimeout(5000)` inside a test that
calls `reloadReactNative()` mid-test can effectively wait up to `reloadTime + 5000 ms` before
failing. On CI, `reloadReactNative()` takes 8–15 seconds. Tests that should fail in 5 seconds
quietly hang for 20+ seconds before reporting failure.

**Fix**: Avoid calling `device.reloadReactNative()` inside test bodies (inside `it()` blocks).
Reserve it for `beforeEach` where the timing is predictable:

```js
// BAD — reloadReactNative inside a test body resets waitFor timers
it('resets the app and checks loading state', async () => {
  await device.reloadReactNative();  // AVOID inside it() blocks
  await waitFor(element(by.id('home-screen')))
    .toBeVisible()
    .withTimeout(5000);  // May wait 20s+ on CI
});

// GOOD — reload in beforeEach, test body only asserts
describe('Home screen', () => {
  beforeEach(async () => {
    await device.reloadReactNative();
    // Wait for the app to reach its initial state BEFORE the test starts
    await waitFor(element(by.id('home-screen')))
      .toBeVisible()
      .withTimeout(15000);  // Explicit generous timeout in setup, not in test
  });

  it('shows the welcome banner', async () => {
    // By the time this runs, we're guaranteed to be at the home screen
    await expect(element(by.id('welcome-banner'))).toBeVisible();
  });
});
```

---

### 76. `jest-junit` v17+ default output format changes break Detox shard report merging [community]

**Root cause**: `jest-junit` v17 (released late 2025) changed the default `classname` template
from `{classname}` to `{filepath}` and introduced a new `suiteNameTemplate` field that
defaults to `{filepath}` as well. Detox CI setups that merge multiple shard JUnit XML files
into a single report (for TCMS or GitHub test reporting) rely on consistent `classname`
attributes to de-duplicate test cases across shards. After upgrading to v17, shard merge
tools (e.g., `junit-report-merger`, `jrm`) fail to match the same test class across shards
because the classname changed from `Login > logs in with valid credentials` to
`e2e/login.test.js > logs in with valid credentials`, causing duplicate test entries in the
merged report.

**Fix**: Pin the `jest-junit` v17 options to preserve the v16 behavior:

```js
// e2e/jest.config.js — explicit jest-junit v17+ options to preserve v16 classname format
module.exports = {
  reporters: [
    'detox/runners/jest/reporter',
    ['jest-junit', {
      outputDirectory: '<rootDir>/test-results',
      outputName: `junit-shard-${process.env.JEST_WORKER_ID || '1'}.xml`,
      // Pin to v16-compatible format to avoid shard-merge classname mismatch
      classNameTemplate: '{classname}',          // use describe block name (v16 default)
      titleTemplate: '{title}',                  // use it() name (v16 default)
      ancestorSeparator: ' > ',
      suiteName: 'Detox E2E',
      // New in v17 — set explicitly to avoid filepath-based suite grouping
      suiteNameTemplate: '{suiteName}',          // overrides v17 filepath default
    }],
  ],
};
```

**Version pinning note**: If you cannot upgrade `jest-junit` immediately, pin in `package.json`:
```json
{
  "devDependencies": {
    "jest-junit": "^16.0.0"
  }
}
```

---

### 77. `element.tap()` on a disabled `Pressable` silently succeeds and fires `onPress` on Android [community]

**Root cause**: React Native's `Pressable` component sets `pointerEvents="none"` on the
underlying native view when `disabled={true}` on Android (API 28+). However, Detox's
`element.tap()` uses the Android `ViewInteraction.perform(click())` Espresso action, which
operates at the native view level and bypasses `pointerEvents` restrictions. The tap
physically lands on the view, and if the `onPress` handler doesn't check the `disabled`
prop internally, it fires — even though the button appears disabled in the UI.

**WHY it's a real bug source**: Tests that assert "disabled button cannot submit the form"
may pass the Detox assertion (`toBeVisible()` is true for a disabled `Pressable`) but the
`tap()` still triggers the handler, making the test miss a real bug where the `disabled`
prop has no effect in the component implementation.

**Fix**: Assert the disabled state explicitly before tapping, and use `getAttributes()` to
verify the native `enabled` property:

```js
// e2e/checkout.test.js — asserting disabled state before testing tap behavior
it('does not submit the form when required fields are empty', async () => {
  // Verify the submit button is disabled at the native accessibility level
  const attrs = await element(by.id('submit-button')).getAttributes();
  expect(attrs.enabled).toBe(false);  // fails if Pressable disabled prop not wired

  // On Android, element.tap() on a disabled Pressable may still fire onPress
  // So we verify via the RESULT (no navigation), not just by checking the button
  await element(by.id('submit-button')).tap();

  // If the submit fired, we'd be on the confirmation screen — assert we're NOT
  await expect(element(by.id('form-screen'))).toBeVisible();
  await expect(element(by.id('confirmation-screen'))).not.toBeVisible();

  // Also verify the error feedback for empty fields IS visible
  await expect(element(by.id('email-error'))).toBeVisible();
});
```

```js
// e2e/helpers/assert-disabled.js — reusable disabled-state assertion
async function assertElementIsDisabled(testID) {
  const attrs = await element(by.id(testID)).getAttributes();

  if (device.getPlatform() === 'android') {
    // Android: check native enabled property via getAttributes
    expect(attrs.enabled).toBe(false);
  } else {
    // iOS: both enabled and accessibilityTraits provide disabled signal
    expect(attrs.enabled).toBe(false);
    // Optional: also assert it has the iOS 'notEnabled' trait (Pattern 44)
    // await expect(element(by.id(testID))).toHaveLabel(expect.stringContaining(''));
  }
}

module.exports = { assertElementIsDisabled };
```

---

### 78. `waitFor(...).not.toBeVisible()` resolves too early during React Navigation shared element transitions [community]

**Root cause**: React Navigation's **shared element transitions** (available via
`@react-navigation/native-stack` with `sharedTransitionTag`) keep both the source and
destination screen components mounted simultaneously during the transition animation.
The element on the **source screen** remains mounted and visible (in the React tree) while
the animation plays — then unmounts at animation end. `waitFor(sourceEl).not.toBeVisible()`
resolves the moment the animation *begins* on some devices (the element starts fading), even
though the transition is still in-flight. The next assertion fires while the source screen is
still partially visible, causing intermittent failures.

**WHY it affects CI more than local**: Shared element transitions are GPU-accelerated.
On CI emulators running with software rendering (`-gpu swiftshader_indirect`), the transition
frames render more slowly — the source element remains at non-zero opacity longer.
`waitFor().not.toBeVisible()` uses a visibility threshold of approximately 50% opacity;
on slow CI GPUs the element hovers near that threshold, causing the assertion to flip between
passing and failing.

**Fix**: Add a brief post-transition wait or assert the *destination* element is visible
(which only becomes true after the full transition completes) before asserting the source
is gone:

```js
// BAD — waitFor source to disappear; resolves too early during shared element transition
it('navigates to product detail', async () => {
  await element(by.id('product-item-1')).tap();
  await waitFor(element(by.id('product-list-screen')))
    .not.toBeVisible()
    .withTimeout(3000);  // may resolve mid-transition
  await expect(element(by.id('product-detail-screen'))).toBeVisible();
});

// GOOD — wait for destination to be fully visible; proves transition completed
it('navigates to product detail', async () => {
  await element(by.id('product-item-1')).tap();

  // Wait for the destination screen's root container — ensures transition completed
  await waitFor(element(by.id('product-detail-screen')))
    .toBeVisible()
    .withTimeout(5000);

  // Only THEN assert the source is gone (belt-and-suspenders for cleanup checks)
  await expect(element(by.id('product-list-screen'))).not.toBeVisible();
});
```

**Animation-off workaround**: If shared element transitions are enabled only in production
builds, disable them for Detox builds using a `launchArgs` flag:

```js
// In the RN app component
import { createNativeStackNavigator } from '@react-navigation/native-stack';
const Stack = createNativeStackNavigator();

const DETOX_MODE = global.__DETOX_MODE__ === '1';

<Stack.Screen
  name="ProductDetail"
  component={ProductDetailScreen}
  options={{
    sharedTransitionTag: DETOX_MODE ? undefined : 'product-image',
  }}
/>
```

```js
// .detoxrc.js — pass the flag in launchArgs
launchArgs: {
  __DETOX_MODE__: '1',
},
```

---

### Pattern 56 — `by.semanticType()` cross-platform semantic element matchers (Detox 20.47+)

Detox 20.47 introduced **semantic type matching** via `by.semanticType()` — a new matcher that selects elements by their high-level UI role rather than their native class name. Unlike `by.type('RCTViewComponentView')` (which is architecture-specific and breaks after New Architecture migrations), `by.semanticType()` uses a stable vocabulary that maps to the correct native type on each platform automatically.

The primary use case is finding interactive controls when `testID` cannot be added (third-party components, WebViews, OS-provided controls). Use `by.id()` first; fall back to `by.semanticType()` only when `testID` is genuinely unavailable.

```js
// Semantic type: 'touchable' — matches any pressable/touchable control
// iOS: RCTTouchableOpacity, RCTButton, Pressable → UIButton-backed native views
// Android: TouchableOpacity, Pressable → android.widget.Button-backed views
it('taps the primary action button when testID is unavailable', async () => {
  // First try: prefer by.id() when testID is set
  // Fallback: use semanticType when dealing with third-party components
  await element(by.semanticType('touchable').withAncestor(by.id('action-row-1'))).tap();
  await waitFor(element(by.id('confirmation-modal')))
    .toBeVisible()
    .withTimeout(5000);
});

// Semantic type: 'image' — matches Image components
// Useful for asserting an image rendered (e.g., user avatar loaded)
it('verifies the product image is rendered', async () => {
  await expect(
    element(by.semanticType('image').withAncestor(by.id('product-card')))
  ).toBeVisible();
});

// Semantic type: 'textInput' — matches TextInput components
// Useful when a third-party text field component doesn't expose testID
it('types into an embedded third-party search field', async () => {
  await element(by.semanticType('textInput').withAncestor(by.id('search-container')))
    .replaceText('react native');
  await waitFor(element(by.id('search-results')))
    .toBeVisible()
    .withTimeout(5000);
});

// Combine semanticType with atIndex() for lists of homogeneous touchables
it('taps the third item in a dynamic card list', async () => {
  await element(
    by.semanticType('touchable').withAncestor(by.id('card-list'))
  ).atIndex(2).tap();
});
```

**Supported semantic types (Detox 20.47+):**

| Semantic type string | Maps to (iOS) | Maps to (Android) |
|---|---|---|
| `'touchable'` | `RCTTouchableOpacity`, `RCTButton`, `UIButton`-backed Pressable | `android.widget.Button`, Pressable-backed views |
| `'image'` | `RCTImageView` | `android.widget.ImageView` |
| `'textInput'` | `RCTTextField`, `RCTTextView` | `android.widget.EditText` |
| `'scrollView'` | `RCTScrollView` | `android.widget.ScrollView`, `androidx.recyclerview.widget.RecyclerView` |
| `'text'` | `RCTText` | `android.widget.TextView` |

**Key constraint**: `by.semanticType()` resolves to the *underlying native type* after RN rendering. If a component uses a custom native module, the semantic type may not match. Always verify with the View Hierarchy Capture (`device.captureViewHierarchy()`) when results are unexpected.

```js
// Diagnostic: capture hierarchy to verify which native types are present
it('inspects native types for a custom component', async () => {
  await element(by.id('custom-card')).tap();
  await device.captureViewHierarchy('after-custom-card-tap');
  // Check .viewhierarchy file in artifacts — confirms native type names
});
```

---

### Pattern 57 — `device.resetAppState()` — targeted app state reset without reinstall

`device.resetAppState()` was introduced to provide a middle ground between the heavyweight `launchApp({ delete: true })` (full reinstall) and the lightweight `reloadReactNative()` (JS reload only). It clears app data and caches — simulating "clear data" from device settings — without removing and reinstalling the binary.

**Detox 20.47 fixed an Android regression** (PR #4844) where permissions were lost after `resetAppState()`. As of 20.47+, permissions are explicitly re-granted via ADB after the state reset.

```js
// Basic usage: reset app state before a test that requires a clean data store
describe('Onboarding flow', () => {
  beforeEach(async () => {
    // Faster than launchApp({ delete: true }) — same "no data" result
    await device.resetAppState();
    await device.launchApp({ newInstance: true });
    await waitFor(element(by.id('welcome-screen')))
      .toBeVisible()
      .withTimeout(10000);
  });

  it('shows onboarding on first launch', async () => {
    await expect(element(by.id('onboarding-step-1'))).toBeVisible();
  });

  it('completes onboarding and reaches home screen', async () => {
    await element(by.id('onboarding-next-button')).tap();
    await element(by.id('onboarding-next-button')).tap();
    await element(by.id('onboarding-finish-button')).tap();
    await waitFor(element(by.id('home-screen')))
      .toBeVisible()
      .withTimeout(5000);
  });
});
```

```js
// Advanced: reset multiple apps in a multi-app test setup
// device.resetAppState() can accept bundle IDs (iOS) or package names (Android)
beforeAll(async () => {
  // Reset both the main app and a companion app used in the test
  await device.resetAppState(['com.example.mainapp', 'com.example.companionapp']);
  await device.launchApp({ newInstance: true });
});
```

**Comparison table:**

| Method | Clears data | Removes binary | Reinstalls | Speed | Permissions preserved |
|---|---|---|---|---|---|
| `launchApp({ delete: true })` | Yes | Yes | Yes | Slowest | No — must re-grant |
| `device.resetAppState()` | Yes | No | No | Faster | Yes (Detox 20.47+) |
| `device.reloadReactNative()` | No | No | No | Fastest | Yes |
| `launchApp({ newInstance: true })` | No | No | No | Fast | Yes |

**Use `resetAppState()` when**: tests cover first-launch flows, onboarding, account creation, or any feature gated on "no stored data" — without paying the full reinstall penalty.

---

### Pattern 58 — `ignoreUnexpectedMessages` session config for WebView and native overlay apps

Apps that mix React Native WebViews with native overlays (bottom sheets, modals driven by native SDKs, in-app purchase dialogs) can produce WebSocket messages that Detox's synchronization layer doesn't expect. Before Detox 20.47, these messages caused `UnexpectedMessageError` exceptions that aborted tests — even though the app was functioning correctly.

`ignoreUnexpectedMessages` (introduced in Detox 20.47, PR #4875) allows you to configure how Detox handles these messages per session.

```js
// .detoxrc.js — enable ignoreUnexpectedMessages for a WebView-heavy app
module.exports = {
  // ... apps, devices ...
  configurations: {
    'ios.sim.release': {
      device: 'simulator',
      app: 'ios.release',
      session: {
        // Suppress UnexpectedMessageError for apps with WebViews or native overlays
        // Values: 'throw' (default), 'warn', 'ignore'
        ignoreUnexpectedMessages: 'warn',  // logs warnings; does not abort tests
      },
    },
    'android.emu.release': {
      device: 'emulator',
      app: 'android.release',
      session: {
        ignoreUnexpectedMessages: 'warn',
      },
    },
  },
};
```

**When to use each value:**

| Value | Behavior | Use case |
|---|---|---|
| `'throw'` (default) | Throws `UnexpectedMessageError`, aborts test | Apps with pure RN UI — unexpected messages indicate a real bug |
| `'warn'` | Logs a warning to stdout; test continues | Apps with WebViews, hybrid screens, or native overlay SDKs |
| `'ignore'` | Silently discards the message | High-frequency overlay apps (e.g., live-streaming with native video SDK) |

```js
// Test for hybrid app: React Native screen with embedded WebView and native share sheet
describe('Share flow (hybrid app)', () => {
  beforeAll(async () => {
    await device.launchApp({
      newInstance: true,
      permissions: { notifications: 'YES' },
    });
  });

  it('shares a product link via native share sheet', async () => {
    await element(by.id('product-share-button')).tap();

    // Native share sheet fires an unexpected WS message — ignoreUnexpectedMessages: 'warn'
    // prevents this from aborting the test
    await waitFor(element(by.system().label('Copy')))
      .toBeVisible()
      .withTimeout(5000);
    await element(by.system().label('Cancel')).tap();
  });
});
```

**Warning**: Setting `ignoreUnexpectedMessages: 'ignore'` can mask real synchronization bugs. Prefer `'warn'` during development so you can see the messages and decide if they are benign. Only switch to `'ignore'` for well-understood, high-frequency noise sources.

---

### Pattern 59 — iOS 26 simulator architecture (`arch`) configuration for Rosetta testing (Detox 20.48+)

Xcode 26 introduced **split simulator runtimes**: an Apple Silicon (arm64-only) runtime and a **Universal** runtime that supports both arm64 and x86_64 (via Rosetta 2). If your app ships a Universal binary or depends on a third-party SDK that only provides an x86_64 simulator slice, you can use Detox 20.48's new `arch` property to force a specific architecture for the simulator launch.

```js
// .detoxrc.js — arch property in app configuration (Detox 20.48+)
module.exports = {
  apps: {
    // Normal ARM64 build (default, most common)
    'ios.release': {
      type: 'ios.app',
      binaryPath: 'ios/build/Build/Products/Release-iphonesimulator/MyApp.app',
      build: 'xcodebuild -workspace ios/MyApp.xcworkspace -scheme MyApp -configuration Release -sdk iphonesimulator -derivedDataPath ios/build CODE_SIGNING_ALLOWED=NO | xcpretty',
    },
    // Rosetta x86_64 build — for testing against x86_64-only third-party SDK slices
    'ios.release.x86': {
      type: 'ios.app',
      binaryPath: 'ios/build/Build/Products/Release-iphonesimulator/MyApp.app',
      arch: 'x86_64',   // Forces Rosetta 2 launch on Apple Silicon (iOS 26+ Universal runtime)
      build: 'xcodebuild -workspace ios/MyApp.xcworkspace -scheme MyApp -configuration Release -sdk iphonesimulator -derivedDataPath ios/build CODE_SIGNING_ALLOWED=NO | xcpretty',
    },
  },
  configurations: {
    // Standard CI configuration (arm64)
    'ios.sim.release': {
      device: 'simulator',
      app: 'ios.release',
    },
    // Rosetta regression configuration — verifies x86_64 SDK compatibility
    'ios.sim.release.rosetta': {
      device: 'simulator',
      app: 'ios.release.x86',
    },
  },
};
```

```yaml
# GitHub Actions — matrix to run both arm64 and x86_64 (Rosetta) configurations
strategy:
  matrix:
    config:
      - ios.sim.release          # arm64 (standard)
      - ios.sim.release.rosetta  # x86_64 via Rosetta 2 (for legacy SDK compatibility)
steps:
  - name: Run Detox (${{ matrix.config }})
    run: npx detox test -c ${{ matrix.config }} --loglevel warn
```

**Key notes:**
- `arch: 'x86_64'` is **silently ignored** on iOS simulators older than iOS 26 (Detox 20.48.1 strips the flag automatically — no error). This means you can safely add `arch` to app configs without breaking pre-iOS-26 CI runs.
- The `arch` property applies to the `xcrun simctl launch` command — it controls which binary slice is loaded by the simulator runtime.
- On CI machines running Intel (x86_64), the `arch` property has no meaningful effect — it only changes behavior on Apple Silicon hosts with Universal simulator runtimes.

---

### 79. Detox 20.48+ `scrollView` item visibility threshold raised to 75% breaks borderline scroll tests [community]

**Root cause**: Detox 20.48 changed the internal visibility detection for scroll-to-item operations: an item in a `ScrollView` or `FlatList` now must be at least **75% visible** (by area) before Detox considers it "visible" and stops scrolling. Previously the threshold was approximately 50%.

**WHY it breaks existing tests**: Test code that used `waitFor(item).toBeVisible()` after a `whileElement().scroll()` may now fail because the item was considered visible at 55% intersection under the old threshold, but the same layout no longer passes the 75% threshold in 20.48+. This manifests as `element not found` or `element is not visible` errors on tests that passed on Detox ≤20.47.

**Most affected patterns**: Tests with items near the bottom of scroll containers on small-screen devices (iPhone SE simulator), and items partially obscured by sticky headers or floating footers.

```js
// BAD (may fail in Detox 20.48+): item only 55% visible when scroll stops
it('taps the last item in the list', async () => {
  await waitFor(element(by.id('list-item-last')))
    .toBeVisible()
    .whileElement(by.id('product-list'))
    .scroll(50, 'down');
  await element(by.id('list-item-last')).tap();
});

// GOOD (Detox 20.48+ compatible): scroll further to ensure 75% visibility
it('taps the last item in the list', async () => {
  // Use scrollTo('bottom') to fully expose the item, then scroll back slightly
  // if a sticky footer would obscure the bottom 25%
  await element(by.id('product-list')).scrollTo('bottom');
  await element(by.id('list-item-last')).tap();
});

// ALSO GOOD: use scroll(200) with a larger step to overshoot rather than stop
// at the borderline intersection point
it('finds item in long list', async () => {
  await waitFor(element(by.id('list-item-99')))
    .toBeVisible()
    .whileElement(by.id('product-list'))
    .scroll(200, 'down');   // larger step = less likely to stop at 55–74% boundary
});
```

**Fix for sticky headers/footers**: If a sticky header or floating action button covers the top/bottom 25% of the scroll container, the item will never reach 75% visibility because the overlay permanently occludes it. Use `contentInset` / `contentContainerStyle` padding in the app to ensure items can scroll fully clear of sticky elements, or adjust the test to scroll past and then back up.

---

### 80. `device.resetAppState()` loses Android permissions below API 35 [community]

**Root cause**: The Detox 20.47 fix for `resetAppState()` permission re-granting (PR #4844) uses `adb shell pm grant --all-permissions`, which works on Android API 35+ but fails silently on API 33–34. On those API levels, `pm grant --all-permissions` is not recognized; the system only supports per-permission granting via `pm grant <package> <permission>`. The result is that after `device.resetAppState()`, the app launches without any permissions on API 33–34 emulators.

**WHY it affects CI**: Many CI matrices still target API 33 or 34 emulators for backward compatibility. Tests that pass on API 35 emulators fail on API 33/34 after upgrading to Detox 20.47 because the permission re-grant silently does nothing.

**Symptom**: Permissions dialogs appear mid-test (or features silently fail) on API 33–34 after `device.resetAppState()`, but not on API 35+.

**Fix**: On API 33–34, explicitly re-grant required permissions via `launchApp` `permissions` option after `resetAppState()`:

```js
// e2e/helpers/reset-with-permissions.js
// API 33–34 safe wrapper for device.resetAppState()
const { getAndroidApiLevel } = require('./android-api-level');

async function resetAppStateWithPermissions(permissionsMap = {}) {
  await device.resetAppState();

  const apiLevel = getAndroidApiLevel();
  const needsExplicitGrant = device.getPlatform() === 'android' && apiLevel !== null && apiLevel < 35;

  if (needsExplicitGrant && Object.keys(permissionsMap).length > 0) {
    // Re-grant permissions explicitly by launching with the permissions map
    // launchApp() with permissions re-applies the grant on API 33/34
    await device.launchApp({
      newInstance: false,
      permissions: permissionsMap,
    });
  } else {
    await device.launchApp({ newInstance: false });
  }
}

module.exports = { resetAppStateWithPermissions };
```

```js
// Usage in tests
const { resetAppStateWithPermissions } = require('../helpers/reset-with-permissions');

describe('Onboarding (requires camera + location)', () => {
  beforeEach(async () => {
    await resetAppStateWithPermissions({
      camera: 'YES',
      location: 'inuse',
    });
  });

  it('shows camera permission prompt only once', async () => {
    await element(by.id('scan-qr-button')).tap();
    await expect(element(by.id('camera-view'))).toBeVisible();
  });
});
```

---

### 81. iOS 26 simulator `arch` flag is ignored when the runtime is not Universal [community]

**Root cause**: The `arch` property introduced in Detox 20.48 (Pattern 59) only takes effect when the iOS simulator runtime is a **Universal** runtime (one that contains both arm64 and x86_64 slices). When running on the standard **Apple Silicon** (arm64-only) runtime — which is the default Xcode 26 download — passing `arch: 'x86_64'` silently does nothing. Detox 20.48.1 added a guard that strips the `--arch` flag for iOS < 26, but there is no guard for "iOS 26+ but non-Universal runtime."

**WHY it fails silently**: There is no error — the app simply launches as arm64 regardless of the `arch` setting. Tests configured to verify Rosetta behavior will pass (because they're actually running arm64), giving false confidence that the x86_64 path is tested.

**Diagnosis**: Run `xcrun simctl runtime list` on the CI machine and verify the runtime type before relying on `arch: 'x86_64'`:

```bash
# Check available simulator runtimes — look for 'Universal' vs 'arm64' in the output
xcrun simctl runtime list

# Example output:
# com.apple.CoreSimulator.SimRuntime.iOS-26-0 (26.0) - iOS 26.0 - Universal
# com.apple.CoreSimulator.SimRuntime.iOS-26-0-arm64 (26.0) - iOS 26.0 - arm64
```

**Fix**: Only set `arch: 'x86_64'` in CI environments that explicitly provision a Universal runtime. Add a runtime check to the CI workflow:

```yaml
# GitHub Actions — only run Rosetta config if Universal runtime is available
- name: Check for Universal simulator runtime
  id: check-runtime
  run: |
    UNIVERSAL=$(xcrun simctl runtime list 2>/dev/null | grep -c "Universal" || echo "0")
    echo "has_universal=$UNIVERSAL" >> "$GITHUB_OUTPUT"

- name: Run Rosetta e2e tests
  if: steps.check-runtime.outputs.has_universal != '0'
  run: npx detox test -c ios.sim.release.rosetta --loglevel warn
```

---

### 82. React Native 0.83 requires Detox 20.47+ — older Detox hangs at app launch [community]

**Root cause**: React Native 0.83 changed the Metro bundler's WebSocket protocol version and updated the internal JS thread synchronization hooks that Detox relies on for idle detection. Detox versions before 20.47 use the older protocol format; when paired with an RN 0.83 app, the Detox server and the app's runtime fail to handshake during `launchApp()`. The app launches, the JS bundle loads, but Detox's idle detector never receives the "ready" signal and the test runner hangs until the `setupTimeout` expires.

**Symptoms**: `globalSetup` completes, the simulator boots, the app appears to launch normally in the simulator window, but the first test's `beforeAll`/`beforeEach` hangs at `device.launchApp()` for the full `setupTimeout` (default 300000 ms on CI) before failing.

**Fix**: Upgrade Detox to 20.47 or later when using React Native 0.83+:

```json
// package.json
{
  "devDependencies": {
    "detox": "^20.47.0"
  }
}
```

**Version compatibility matrix (Detox 20.x):**

| React Native version | Minimum Detox version |
|---|---|
| 0.76 – 0.78 | 20.14+ |
| 0.79 – 0.82 | 20.26+ |
| 0.83 | 20.47+ |
| 0.84 | 20.51+ |
| 0.85 | 20.51+ |

**Upgrade path for projects with large Detox version gaps**: Run `npx detox doctor` after upgrading to validate the configuration. Detox 20.47 introduced minor configuration schema changes (notably the `session.ignoreUnexpectedMessages` field) that may generate deprecation warnings for pre-20.47 `.detoxrc.js` files, but are backward compatible.

---

### 83. `ignoreUnexpectedMessages: 'ignore'` masks real Detox synchronization failures [community]

**Root cause**: When `ignoreUnexpectedMessages` is set to `'ignore'` in the session config, all unexpected WebSocket messages are silently discarded. This includes messages that represent genuine synchronization failures — for example, a message from a detached JS thread that indicates the app has crashed and restarted. Tests continue executing against a broken app state, producing misleading assertion failures that look like UI bugs but are actually caused by a crashed session.

**WHY teams reach for `'ignore'`**: After upgrading to Detox 20.47 with `ignoreUnexpectedMessages: 'warn'`, some projects see a flood of warnings from third-party SDKs (video players, live-streaming components, background sync services). The instinct is to silence them by switching to `'ignore'`.

**Better approach**: Instead of suppressing all messages, identify which specific SDK is noisy and suppress its network activity via `setURLBlacklist`:

```js
// WRONG — silences everything, including genuine failures
// .detoxrc.js
session: {
  ignoreUnexpectedMessages: 'ignore',   // do not use unless you've triaged ALL sources
}

// RIGHT — silence the noisy SDK at the network layer; keep WS error surfacing
beforeAll(async () => {
  await device.launchApp({ newInstance: true });
  // Suppress the video SDK's heartbeat pings (the actual noise source)
  await device.setURLBlacklist([
    '.*livestream-sdk\\.example\\.com.*',
    '.*video-analytics.*',
  ]);
});

// ALSO RIGHT — use 'warn' to keep visibility during development
// .detoxrc.js
session: {
  ignoreUnexpectedMessages: 'warn',  // surface warnings without aborting tests
}
```

**Diagnostic checklist** before switching to `'ignore'`:
1. Run tests with `ignoreUnexpectedMessages: 'warn'` and capture the log output.
2. Identify the source domain of the unexpected messages (they appear in the warning log).
3. Add that domain to `setURLBlacklist` rather than suppressing the error type globally.
4. Only use `'ignore'` after all known noise sources are blacklisted and you've verified the remaining unexpected messages are never from Detox internals.

---

### 84. iOS 26 `liquidGlass` navigation bar requires Detox 20.51.1+ for correct screenshots [community]

**Root cause**: iOS 26 introduced the "liquidGlass" visual design for navigation bars — a dynamic glass-morphism effect that uses real-time blur compositing. Detox's screenshot API (`device.takeScreenshot()`) captures the view hierarchy using `UIView`-level rendering. Before Detox 20.51.1, the navigation bar blur layer was captured as a transparent region, producing screenshots where the navigation bar appeared invisible or incorrectly overlaid.

**WHY it affects visual regression tests**: Projects using visual regression testing (comparing `device.takeScreenshot()` output against a baseline using tools like `jest-image-snapshot` or Applitools) will see false failures on iOS 26 simulators running Detox < 20.51.1. The navigation bar area looks different from the baseline (which was captured at full opacity) even when the UI is functionally identical.

**Fix**: Upgrade to Detox 20.51.1+:

```json
// package.json
{
  "devDependencies": {
    "detox": "^20.51.1"
  }
}
```

**Interim workaround** (if upgrading immediately is not possible): Exclude the navigation bar region from visual regression comparisons. Most visual regression tools support bounding-box exclusions:

```js
// jest-image-snapshot example — exclude navigation bar region (top 88px on iPhone 16 Pro)
const { toMatchImageSnapshot } = require('jest-image-snapshot');
expect.extend({ toMatchImageSnapshot });

it('compares product screen layout', async () => {
  const screenshot = await device.takeScreenshot('product-screen');
  const imageBuffer = require('fs').readFileSync(screenshot);

  expect(imageBuffer).toMatchImageSnapshot({
    customDiffConfig: { threshold: 0.1 },
    // Exclude navigation bar area from diff (iOS 26 liquidGlass artifact)
    customSnapshotIdentifier: 'product-screen',
    // Use clip/mask depending on your visual testing library's API
  });
});
```

**Note**: The liquidGlass blur effect also affects `device.captureViewHierarchy()` output — the navigation bar may be omitted or appear as a placeholder node in the view hierarchy XML. This does not affect `by.id()` or `by.label()` matchers (which operate on accessibility data), but `by.type('UINavigationBar')` selectors may behave differently on iOS 26 vs earlier.

---

### 85. iOS 26+ biometric simulation requires updated `applesimutils` flags — `--matchFace` is removed [community]

**Root cause**: Apple changed the `applesimutils` CLI in iOS 26. The flags `--matchFace`, `--unmatchFace`, `--matchFinger`, and `--unmatchFinger` were removed. Detox's biometric simulation methods (`device.matchFace()`, `device.unmatchFace()`, `device.matchFinger()`, `device.unmatchFinger()`, `device.setBiometricEnrollment()`) internally call `applesimutils` and therefore silently fail on iOS 26+ simulators with Detox < 20.51. The test does not error out — it simply continues with biometrics never having been triggered, causing the waitFor that follows to time out.

**New flags** (iOS 26+, requires `applesimutils` 0.9.5+):
- `--biometricMatch` replaces `--matchFace` / `--matchFinger`
- `--biometricNonmatch` replaces `--unmatchFace` / `--unmatchFinger`
- `--booted` replaces `--byId <udid>` for targeting the booted simulator

Detox 20.51 (PR #4932) introduced version-branching in `AppleSimUtils.js` to automatically select the correct flags based on the detected iOS runtime version. No test code changes are needed after upgrading.

**Fix**: Upgrade Detox to 20.51+ and update `applesimutils`:

```bash
brew update && brew upgrade applesimutils
# Verify version is 0.9.5+:
applesimutils --version
```

```json
// package.json
{
  "devDependencies": {
    "detox": "^20.51.0"
  }
}
```

**Verification**: After upgrading, run a biometric test with `--loglevel debug`. Look for `--biometricMatch` or `--biometricNonmatch` in the log output. If you still see `--matchFace`, the `applesimutils` brew formula or the `detox` package version is stale.

**Diagnostic**: If your biometric test fails on iOS 26+ with a `timeout waiting for element to become visible` (not an explicit error), and the test uses `device.matchFace()` or `device.matchFinger()`, this is almost certainly the flag deprecation issue.

```js
// Pattern still works after upgrade — no test code change needed
it('authenticates with Face ID on iOS 26+ simulator', async () => {
  await device.setBiometricEnrollment(true);
  await element(by.id('use-face-id-button')).tap();
  await device.matchFace();  // Detox 20.51+ uses --biometricMatch internally
  await waitFor(element(by.id('home-screen')))
    .toBeVisible()
    .withTimeout(5000);
});
```

---

### 86. Android `<Modal>` tap events silently fail — modal renders in a separate native Window [community]

**Root cause**: React Native's `<Modal>` component on Android creates a `Dialog` — a separate native `Window` layer. Detox's Android driver (which wraps Espresso's `onView`) targets the main Activity window by default. When a `tap()` action fires against a `by.id()` selector that matches an element inside a `<Modal>`, Espresso dispatches the tap to the main window coordinate and the event is discarded. There is no error or warning — the element is found (visibility checks work across window layers), but the action is never received.

**WHY it is hard to detect**: The following test code *looks* correct and partially works:

```js
// BROKEN on Android — visibility passes, tap silently fails
it('submits the confirmation modal', async () => {
  await element(by.id('open-modal-button')).tap();  // opens a <Modal>
  await waitFor(element(by.id('modal-confirm-button')))
    .toBeVisible()
    .withTimeout(5000);  // PASSES — visibility check crosses window layers
  await element(by.id('modal-confirm-button')).tap();  // SILENT NO-OP on Android
  await waitFor(element(by.id('success-screen')))
    .toBeVisible()
    .withTimeout(5000);  // FAILS — success-screen never appears
});
```

The test fails at the last `waitFor` with a timeout, not at the `tap()`. This makes the bug appear as a navigation or state management issue rather than an interaction layer issue.

**Workaround A — Move interactive elements outside `<Modal>` (preferred)**

Replace `<Modal>` with a full-screen conditional render or a React Navigation modal screen. Elements in the component tree of the main Activity are fully reachable:

```jsx
// Instead of:
<Modal visible={isOpen}>
  <Button testID="modal-confirm-button" onPress={handleConfirm} />
</Modal>

// Use a conditional overlay in the main tree:
{isOpen && (
  <View style={StyleSheet.absoluteFill} testID="confirm-overlay">
    <Button testID="modal-confirm-button" onPress={handleConfirm} />
  </View>
)}
```

**Workaround B — Platform-conditional test flow**

```js
it('submits the confirmation modal', async () => {
  await element(by.id('open-modal-button')).tap();
  await waitFor(element(by.id('modal-confirm-button')))
    .toBeVisible()
    .withTimeout(5000);

  if (device.getPlatform() === 'android') {
    // Trigger submit via an alternative path reachable in the main window
    // e.g., a hardware back press + keyboard shortcut, or skip the modal
    // and invoke the action directly via launchArgs in a separate test.
    pending('Android Modal window isolation: modal confirm not directly reachable — see Issue #4928');
  } else {
    await element(by.id('modal-confirm-button')).tap();
    await waitFor(element(by.id('success-screen'))).toBeVisible().withTimeout(5000);
  }
});
```

**Tracking**: [Detox Issue #4928](https://github.com/wix/Detox/issues/4928) proposes either automatic `inRoot(isDialog())` fallback or an explicit `element(...).inRoot('dialog').tap()` API. As of Detox 20.51.1, no fix has landed — the workaround is required.

---

### 87. React Native 0.85 requires Detox 20.51+ [community]

**Root cause**: React Native 0.85 introduced further changes to the Metro bundler's WebSocket handshake protocol and updated the New Architecture codegen pipeline. Detox versions below 20.51 use connection parameters that are incompatible with the RN 0.85 Metro server, causing `launchApp()` to hang indefinitely while waiting for the JS bundle to load.

**Symptom**: Running `npx detox test` with an RN 0.85 app and Detox < 20.51 results in:
```
Error: DetoxRuntimeError: Timeout of 300000ms exceeded while waiting for the app to launch.
```

The device/emulator shows the app splash screen but Detox never receives the `appConnected` handshake.

**Fix**: Upgrade Detox to 20.51+:

```bash
npm install --save-dev detox@^20.51.0
```

**Version compatibility matrix (updated):**

| React Native version | Minimum Detox version |
|---|---|
| 0.76 – 0.78 | 20.14+ |
| 0.79 – 0.82 | 20.26+ |
| 0.83 | 20.47+ |
| 0.84 – 0.85 | 20.51+ |

See also [PR #4936](https://github.com/wix/Detox/pull/4936) for the RN 0.85 CI lane additions that validated this compatibility boundary.

---

### 88. `element(...).atIndex(N).getAttributes()` on iOS returned all matching elements before Detox 20.51 [community]

**Root cause**: The `getAttributes()` implementation in iOS's `Element.swift` did not consult `self.index` when building the attributes response. When multiple elements matched the predicate, it mapped over all views and returned them in an `{elements: [...]}` array, regardless of whether `atIndex(N)` was specified. This was fixed in Detox 20.51 (PR #4912).

**WHY this caused silent bugs**: Code written expecting a single-element result would receive an array-wrapped response and silently access `undefined` properties:

```js
// BROKEN before Detox 20.51 — atIndex(1) was silently ignored
const attrs = await element(by.id('list-item')).atIndex(1).getAttributes();
// On Detox < 20.51:  attrs = { elements: [{text: 'Item 0', ...}, {text: 'Item 1', ...}] }
// On Detox 20.51+:   attrs = { text: 'Item 1', id: 'list-item', visible: true, ... }

// This assertion silently passed before (truthy), now returns correct value:
expect(attrs.text).toBe('Item 1'); // WRONG on < 20.51, CORRECT on 20.51+
```

**Migration note**: If you have tests using `atIndex(N).getAttributes()` that were written on Detox < 20.51, verify their behavior after upgrading. Tests that were silently consuming `attrs.elements[N]` instead of `attrs.text` directly will now break with a more useful error (the result is a plain object, not `{elements: []}`).

```js
// CORRECT pattern on Detox 20.51+ — single object returned when atIndex used
it('reads the second list item attributes', async () => {
  const attrs = await element(by.id('product-item')).atIndex(1).getAttributes();
  // attrs is a direct IosElementAttributes object (single element)
  expect(attrs.text).toBe('Product B');
  expect(attrs.visible).toBe(true);
  expect(attrs.enabled).toBe(true);
});

// Without atIndex, multiple matches still return { elements: [...] }
it('reads all list item attributes', async () => {
  const attrs = await element(by.id('product-item')).getAttributes();
  // attrs = { elements: [{text:'Product A',...}, {text:'Product B',...}] }
  expect(attrs.elements).toHaveLength(2);
  expect(attrs.elements[1].text).toBe('Product B');
});
```

**Note**: This fix applies to iOS only. Android's `getAttributes()` + `atIndex()` behavior was already correct before this fix.

---

### Pattern 60 — Android `<Modal>` interaction workaround

**Problem**: React Native's `<Modal>` component on Android renders in a separate native `Window` (a `Dialog`), not inside the main Activity. Detox dispatches Espresso interactions to the main window by default, so tapping an element inside a `<Modal>` produces no error but also no effect — the tap silently hits the wrong layer. `waitFor(...).toBeVisible()` still resolves correctly because accessibility tree traversal crosses window boundaries; only the `tap()` action fails.

See [Issue #4928](https://github.com/wix/Detox/issues/4928) for the upstream tracking issue.

**Root cause**: Espresso's `onView(matcher).perform(action)` without a `inRoot()` constraint defaults to the main Activity window. The `Dialog` window is a separate root.

**Workaround options:**

**Option A — Avoid the native Modal for testable UIs (preferred)**

Replace `<Modal>` with a custom in-tree overlay (e.g., `react-native-portal`, a conditional render at the navigation stack root, or React Navigation's `<Modal>` screen type). Elements in the main tree are fully Detox-compatible.

**Option B — Use `by.system()` for OS-level dialogs (permission / alert dialogs)**

When the modal is a native OS dialog (not an RN `<Modal>`), `by.system()` handles window root resolution automatically:

```js
// For native OS dialogs (not RN <Modal>) — by.system() handles root resolution
await element(by.system().label('Allow').withAncestor(by.system().type('XCUIElementTypeAlert')))
  .tap();
```

**Option C — Test modal content through state side-effects instead of direct interaction**

When the modal UI cannot be restructured, verify the *result* of the modal interaction rather than tapping inside it:

```js
it('modal confirm triggers order submission', async () => {
  // Open the modal by tapping a button in the main UI
  await element(by.id('checkout-button')).tap();
  await waitFor(element(by.id('confirm-modal-title')))
    .toBeVisible()
    .withTimeout(5000);

  // On Android, tapping inside RN <Modal> may silently fail.
  // Instead, drive the modal via the accessibility action or through
  // a workaround that keeps interactive elements outside the Modal.
  // If Option A is not available, verify modal presence and dismiss
  // by pressing the device back button (Android-only):
  if (device.getPlatform() === 'android') {
    // Note: this closes/dismisses the modal, not confirms it.
    // Redesign the modal to use a back-dismissible confirm or a
    // non-Modal overlay to make the confirm button reachable.
    await device.pressBack();
    await waitFor(element(by.id('checkout-button'))).toBeVisible().withTimeout(3000);
  }
});
```

**Option D — Wait for Detox native fix (tracked in Issue #4928)**

The Detox maintainers are tracking an upstream fix to automatically target the `Dialog` root for interactions when the matched element is inside a Dialog window. Once released, no workaround will be needed.

```js
// Expected future API (not yet available as of Detox 20.51.1):
// await element(by.id('modal-confirm-button')).inRoot('dialog').tap();
```

**Rule of thumb**: If your test has a `waitFor(...).toBeVisible()` inside an RN `<Modal>` that passes, but the subsequent `tap()` has no effect, this is the Android Modal window isolation issue.

---

## Updated Anti-Patterns Checklist (iterations 50–51 additions)

| Anti-Pattern | Fix |
|---|---|
| `device.setStatusBar({ batteryLevel: 0.157 })` with `toHaveText('15.7%')` | Round to 2 decimal places before passing to `setStatusBar` and before constructing expected strings (Gotcha 64) |
| Hard-coded port number for mock servers started inside test suites | Use `server.listen(0, ...)` for OS-assigned ports; use `JEST_WORKER_ID`-based allocation only for global setup (Gotcha 65) |
| `toHaveText()` assertions on elements that also set `accessibilityLabel` | Prefer `toHaveLabel()` — asserts the screen-reader contract, survives refactors and locale changes (Gotcha 66) |
| Multiple Detox apps running in the same CI runner with default Detox server port | Set `server.port` per app in `.detoxrc.js` or use `DETOX_SERVER_PORT` env var in CI matrix (Gotcha 67) |
| Cold-start `waitFor` timeouts of 5000 ms in RN 0.79+ projects with `lazyImports: true` | Raise to 12000 ms or disable lazy bundling in Detox builds via `process.env.DETOX_CONFIGURATION` guard (Gotcha 68) |
| `device.terminateApp()` called in nested `describe` `afterAll` hooks | Only terminate/launch in the outermost `describe` block; use `reloadReactNative()` in nested cleanup (Gotcha 69) |
| Manual `allure.stepStatus()` calls without `try/finally` context closing | Use Allure's callback form `allure.step(name, async () => { ... })` which auto-closes on exception (Gotcha 70) |
| `waitFor().whileElement().scroll()` stopping at 55–74% item intersection | Upgrade to Detox 20.48+ (75% threshold) and use `scrollTo('bottom')` or larger step sizes to overshoot (Gotcha 79) |
| `device.resetAppState()` after upgrading to Detox 20.47 on Android API 33–34 emulators | Use the `resetAppStateWithPermissions()` wrapper that re-grants via `launchApp` `permissions` option on API < 35 (Gotcha 80) |
| `arch: 'x86_64'` in app config with non-Universal iOS 26 runtime | Run `xcrun simctl runtime list` to verify Universal runtime availability; gate Rosetta CI job on runtime check (Gotcha 81) |
| Using RN 0.83 with Detox < 20.47 | Upgrade Detox to 20.47+ — pre-20.47 Detox hangs at `launchApp()` due to Metro WS protocol mismatch (Gotcha 82) |
| `ignoreUnexpectedMessages: 'ignore'` applied globally | Use `'warn'` + `setURLBlacklist` to target specific noisy SDKs; `'ignore'` masks real session failures (Gotcha 83) |
| Visual regression tests on iOS 26 with Detox < 20.51.1 | Upgrade to 20.51.1+ to fix liquidGlass navigation bar screenshot capture; or exclude nav bar region from diff (Gotcha 84) |
| `device.matchFace()` / `device.unmatchFace()` on iOS 26+ simulator | Upgrade to Detox 20.51+; applesimutils removed the `--matchFace` flag on iOS 26+, now uses `--biometricMatch`/`--biometricNonmatch` with `--booted` (Gotcha 85) |
| Tapping elements inside RN `<Modal>` on Android | Move interactive elements outside `<Modal>` or use a non-Modal overlay; modal content lives in a separate native Window layer that Espresso cannot reach without explicit root targeting (Gotcha 86) |
| Using RN 0.85 with Detox < 20.51 | Upgrade to Detox 20.51+ for React Native 0.85 compatibility (Gotcha 87) |
| `element(by.id('item')).atIndex(2).getAttributes()` on iOS expecting a single-object result with Detox < 20.51 | Upgrade to 20.51+; before the fix (PR #4912), `atIndex()` was ignored and `getAttributes()` returned an `{elements: [...]}` array for all matches instead of a single object (Gotcha 88) |

---

- Detox Official Docs: https://wix.github.io/Detox/
- Detox Getting Started: https://wix.github.io/Detox/docs/introduction/getting-started
- Detox Flakiness Guide: https://wix.github.io/Detox/docs/troubleshooting/flakiness
- Detox Synchronization: https://wix.github.io/Detox/docs/articles/synchronization
- Detox Matchers API: https://wix.github.io/Detox/docs/api/matchers
- Detox `waitFor` API: https://wix.github.io/Detox/docs/api/expect#waitforexpect
- Detox Expect API (toHaveLabel, toHaveToggleValue): https://wix.github.io/Detox/docs/api/expect
- Detox Artifacts: https://wix.github.io/Detox/docs/config/artifacts
- Detox CI Guide: https://wix.github.io/Detox/docs/introduction/ci
- Detox URL Blacklist: https://wix.github.io/Detox/docs/api/device#deviceseturlblacklisturls
- Detox Device API: https://wix.github.io/Detox/docs/api/device
- Detox Config Overview: https://wix.github.io/Detox/docs/config/overview
- Detox `getAttributes()`: https://wix.github.io/Detox/docs/api/actions-core#getattributes
- Detox `setLocation()`: https://wix.github.io/Detox/docs/api/device#devicesetlocationlat-lon
- Detox Biometrics (iOS): https://wix.github.io/Detox/docs/api/device#devicematchface
- Detox View Hierarchy Capture: https://wix.github.io/Detox/docs/api/device#devicecaptureviewhierarchyname
- Detox TypeScript types: https://wix.github.io/Detox/docs/introduction/typescript
- Detox WebViews API: https://wix.github.io/Detox/docs/api/webviews
- Expo Detox Integration: https://docs.expo.dev/build-reference/e2e-tests/
- Detox Semantic Matching (20.47+): https://github.com/wix/Detox/pull/4793
- Detox `ignoreUnexpectedMessages` (20.47+): https://github.com/wix/Detox/pull/4875
- Detox iOS 26 `arch` flag (20.48+): https://github.com/wix/Detox/pull/4916
- Detox iOS 26+ biometric `--booted` flag (20.51+): https://github.com/wix/Detox/pull/4932
- Detox `atIndex().getAttributes()` iOS fix (20.51+): https://github.com/wix/Detox/pull/4912
- Detox Android Modal window isolation (open issue): https://github.com/wix/Detox/issues/4928
- Detox RN 0.85.2 support (20.51+): https://github.com/wix/Detox/pull/4936
- React Navigation Testing: https://reactnavigation.org/docs/testing/
