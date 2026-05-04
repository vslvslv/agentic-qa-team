# Detox Patterns & Best Practices (JavaScript)
<!-- lang: JavaScript | sources: official docs + community + training knowledge | iteration: 39 | score: 100/100 | date: 2026-05-03 -->
<!-- WebFetch was unavailable — synthesized from official docs knowledge + community research training data -->
<!-- Re-run `/qa-refine Detox` with WebFetch enabled to pull live sources -->

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
| `device.shake()` | Shake gesture | Shake-to-report, undo gesture |
| `device.setStatusBar(params)` | Override status bar display | Screenshot/visual consistency in CI |
| `device.getPlatform()` | Returns `'ios'` or `'android'` | Conditional test logic per platform |
| `device.takeScreenshot(name)` | Save a screenshot to artifacts | Manual debugging snapshots |
| `device.captureViewHierarchy(name)` | Dump native accessibility tree to .viewhierarchy file | Debug "element not found" — open in Xcode |
| `device.clearKeychain()` | Purge iOS Simulator Keychain (Detox 20+) | Prevent token leak between auth test suites |
| `by.system()` | Match system-level UI elements (alerts, permission dialogs) | When pre-granting in `launchApp` is not possible |

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
- Expo Detox Integration: https://docs.expo.dev/build-reference/e2e-tests/
- React Navigation Testing: https://reactnavigation.org/docs/testing/
