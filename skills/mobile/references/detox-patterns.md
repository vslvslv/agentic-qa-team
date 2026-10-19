# Detox Patterns & Best Practices (JavaScript)
<!-- lang: JavaScript | sources: official docs + community + training knowledge | iteration: 10 | score: 100/100 | date: 2026-04-27 -->
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

// tapReturnKey: submit a form via keyboard without tapping a button
it('submits search by pressing return key', async () => {
  await element(by.id('search-input')).replaceText('react native');
  await element(by.id('search-input')).tapReturnKey();
  await waitFor(element(by.id('search-results')))
    .toBeVisible()
    .withTimeout(5000);
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

---


Ranked from most stable to most fragile:

| Rank | Selector | API | Notes |
|------|----------|-----|-------|
| 1 | `testID` prop | `by.id('testID')` | Best — survives refactors, localization, style changes |
| 2 | Accessibility label | `by.label('Submit')` | Good — doubles as a11y; survives layout changes |
| 3 | Accessibility type | `by.type('RCTTextInput')` | OK — use to narrow when testID is absent |
| 4 | Visible text | `by.text('Log in')` | Fragile — breaks on copy changes and i18n |
| 5 | XPath / CSS | n/a (not supported) | Not supported in Detox — do not attempt |
| 6 | System elements | `by.system()` | iOS only — target system-level elements (permission dialogs, alerts) not in your app's view hierarchy |

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

---

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


---

## Key APIs

| Method | Description | When to use |
|--------|-------------|-------------|
| `element(by.id(id))` | Select element by `testID` | Primary selector for all interactions |
| `element(by.label(label))` | Select by accessibility label | When `testID` is absent |
| `element(by.text(text))` | Select by visible text | Assertions only; avoid for actions |
| `element(by.type(type))` | Select by native component type | Narrowing when testID is shared |
| `.and(matcher)` | Compound matcher | Combining matchers for precision |
| `.withAncestor(matcher)` | Scopes to ancestor container | Resolving ambiguous matches in lists |
| `.withDescendant(matcher)` | Scopes to descendant | Checking child element presence |
| `.atIndex(n)` | Select nth match | Only when multiple distinct elements match |
| `.tap()` | Simulates a tap | Buttons, list items, toggles |
| `.typeText(str)` | Types text into an input | Text fields |
| `.clearText()` | Clears a text input | Before re-typing in an already-filled field |
| `.replaceText(str)` | Clears and types in one call | Faster than clearText+typeText |
| `.tapReturnKey()` | Taps the keyboard return key | Submitting forms via keyboard |
| `.scroll(px, direction)` | Scrolls a scrollable container | Reaching off-screen elements |
| `.scrollTo(edge)` | Scrolls to `'top'`, `'bottom'`, `'left'`, `'right'` | Quick edge scrolling |
| `.swipe(direction, speed, norm)` | Swipe gesture | Carousels, dismissible modals |
| `.longPress()` | Long press | Context menus, drag handles |
| `.pinch(scale, speed)` | Pinch gesture (iOS) | Zoom interactions |
| `expect(el).toBeVisible()` | Asserts element is on screen and visible | Primary visibility assertion |
| `expect(el).toExist()` | Asserts element is in React tree | Checking unmounted vs mounted |
| `expect(el).toHaveText(str)` | Asserts element displays text | Text content assertions |
| `expect(el).toHaveValue(val)` | Asserts input has a value | TextInput value assertion |
| `expect(el).not.toBeVisible()` | Asserts element is hidden or absent | Verifying dismissal |
| `waitFor(el).toBeVisible().withTimeout(ms)` | Waits up to ms for element to appear | Async data load, navigation transitions |
| `waitFor(el).toBeVisible().whileElement(by.id).scroll(px, dir)` | Scroll until element visible | Dynamic lists |
| `device.launchApp(params)` | Launch or relaunch the app | `beforeAll` / test-level resets |
| `device.reloadReactNative()` | Reload JS bundle without restart | Fast `beforeEach` state reset (JS-only) |
| `device.terminateApp()` | Kill the app process | Cleanup in `afterAll` |
| `device.sendUserNotification(payload)` | Simulate a push notification | Testing notification-triggered flows |
| `device.setURLBlacklist(patterns)` | Block URLs from being tracked by sync | Suppress analytics/ad beacon flakiness |
| `device.disableSynchronization()` | Disable automatic idle waiting | Narrow scope around known sync-breaking code |
| `device.enableSynchronization()` | Re-enable automatic idle waiting | Re-enable immediately after `disableSynchronization` |
| `device.shake()` | Shake gesture | Shake-to-report, undo gesture |
| `device.setStatusBar(params)` | Override status bar display | Screenshot/visual consistency in CI |
| `device.getPlatform()` | Returns `'ios'` or `'android'` | Conditional test logic per platform |
| `device.takeScreenshot(name)` | Save a screenshot to artifacts | Manual debugging snapshots |

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
| Using `device.launchApp({url})` vs `device.openURL()` incorrectly | Use `launchApp({url})` for cold-start deep links; use `device.openURL()` to open a URL while app is already running |

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

---

## Project Setup Quick Reference

Minimum setup to get a Detox project running from scratch:

```bash
# 1. Install Detox CLI and dependencies
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

---

## Custom Jest Reporter for Detox

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

### openURL vs launchApp({url})

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

---

- Detox Official Docs: https://wix.github.io/Detox/
- Detox Getting Started: https://wix.github.io/Detox/docs/introduction/getting-started
- Detox Flakiness Guide: https://wix.github.io/Detox/docs/troubleshooting/flakiness
- Detox Synchronization: https://wix.github.io/Detox/docs/articles/synchronization
- Detox Matchers API: https://wix.github.io/Detox/docs/api/matchers
- Detox `waitFor` API: https://wix.github.io/Detox/docs/api/expect#waitforexpect
- Detox Artifacts: https://wix.github.io/Detox/docs/config/artifacts
- Detox CI Guide: https://wix.github.io/Detox/docs/introduction/ci
- Detox URL Blacklist: https://wix.github.io/Detox/docs/api/device#deviceseturlblacklisturls
- Detox Device API: https://wix.github.io/Detox/docs/api/device
- Detox Config Overview: https://wix.github.io/Detox/docs/config/overview
- Detox `getAttributes()`: https://wix.github.io/Detox/docs/api/actions-core#getattributes
- Detox `setLocation()`: https://wix.github.io/Detox/docs/api/device#devicesetlocationlat-lon
- Detox Biometrics (iOS): https://wix.github.io/Detox/docs/api/device#devicematchface
- Expo Detox Integration: https://docs.expo.dev/build-reference/e2e-tests/
- React Navigation Testing: https://reactnavigation.org/docs/testing/
