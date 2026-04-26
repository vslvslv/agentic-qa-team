# Detox Patterns & Best Practices
<!-- sources: official docs + community | iteration: 1 | score: 98/100 | date: 2026-04-26 -->
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
// In your Detox test
it('logs in with valid credentials', async () => {
  await element(by.id('email-input')).typeText('user@example.com');
  await element(by.id('password-input')).typeText('secret123');
  await element(by.id('login-button')).tap();
  await expect(element(by.id('home-screen'))).toBeVisible();
});
```

### Pattern 2 — Clean state in beforeEach

Reset the app before every test to prevent order-dependent failures. Use `newInstance: true` to cold-boot, or `reloadReactNative()` for a cheaper JS-only reload when the native state is already clean.

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

Use `launchApp({ newInstance: true })` when tests mutate native storage (Keychain, AsyncStorage). Use `reloadReactNative()` when only JS state needs resetting — it is ~4x faster.

### Pattern 3 — Scroll-to-element before interacting

On smaller simulators (iPhone SE) elements that are off-screen fail with `element not found`. Always scroll the containing list into view before tapping.

```js
it('submits the form at the bottom of a long screen', async () => {
  await element(by.id('settings-scroll-view')).scrollTo('bottom');
  await element(by.id('save-button')).tap();
  await expect(element(by.id('success-toast'))).toBeVisible();
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
```

Do not shorten timeouts to make tests "feel fast" — if the operation legitimately takes 3 s in CI, allow 5–8 s.

### Pattern 5 — Disabling animations on CI

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

### Pattern 6 — Separate CI configuration

Use a dedicated Detox configuration for CI that targets a specific, pinned simulator model and disables animations. Do not reuse the developer configuration on CI.

```js
// .detoxrc.js
module.exports = {
  testRunner: {
    args: { $0: 'jest', config: 'e2e/jest.config.js' },
    jest: { setupTimeout: 120000 },
  },
  configurations: {
    'ios.sim.debug': { /* dev config — any available simulator */ },
    'ios.sim.ci': {
      device: { type: 'simulator', device: { type: 'iPhone 14' } },
      app: {
        type: 'ios.app',
        binaryPath: 'ios/build/Build/Products/Debug-iphonesimulator/MyApp.app',
      },
    },
    'android.emu.ci': {
      device: { type: 'emulator', avd: 'Pixel_4_API_30' },
      app: {
        type: 'android.apk',
        binaryPath: 'android/app/build/outputs/apk/debug/app-debug.apk',
      },
    },
  },
};
```

### Pattern 7 — Retry flaky tests at the runner level (last resort)

If a test fails intermittently due to reasons outside your control (simulator instability, GPU unavailability in headless CI), configure Jest retries — but treat this as a temporary bandage, not a fix.

```js
// e2e/jest.config.js
module.exports = {
  rootDir: '..',
  testMatch: ['<rootDir>/e2e/**/*.test.js'],
  testTimeout: 120000,
  retryTimes: 1,          // retry each failing test once
  verbose: true,
};
```

### Pattern 8 — App permissions in launchApp [community]

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
  });
});
```

On Android, additional permissions must be granted via ADB or handled through Detox's `grantPermissions` before the app launches. Never rely on the app's first-run permission flow during e2e tests.

### Pattern 9 — Suppress third-party SDK timers with setURLBlacklist [community]

Analytics SDKs (Firebase Analytics, Amplitude, Segment, Sentry) fire background network requests that Detox's idle detector counts as "app busy". The test sits waiting, times out, and fails — even though the feature under test completed successfully.

```js
// In beforeAll or a global setup file
beforeAll(async () => {
  await device.launchApp({ newInstance: true });
  // Suppress analytics/crash-reporting beacons so they don't block idle detection
  await device.setURLBlacklist([
    '.*firebaselogging.*',
    '.*amplitude.*',
    '.*sentry.*',
    '.*crashlytics.*',
    '.*analytics.*',
  ]);
});
```

This is one of the most impactful fixes for tests that pass locally (where analytics fire quickly on a fast network) but time out on CI (where network calls to analytics endpoints are slow or blocked).

### Pattern 10 — Artifact collection for CI debugging

Detox can save screenshots, video recordings, and logs on failure. Without artifacts, debugging CI failures is guesswork. Enable artifact collection in the Detox config and attach them to your CI job:

```js
// .detoxrc.js
module.exports = {
  artifacts: {
    rootDir: '.artifacts',
    plugins: {
      screenshot: { shouldTakeAutomaticSnapshots: true, takeWhen: { testFailure: true } },
      video: { enabled: false },     // enable for hard-to-reproduce failures
      log: { enabled: true },
      timeline: { enabled: true },
    },
  },
  // ...
};
```

```yaml
# GitHub Actions — upload artifacts on failure
- name: Run Detox tests
  run: npx detox test -c ios.sim.ci
- name: Upload test artifacts
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: detox-artifacts
    path: .artifacts/
    retention-days: 7
```

### Pattern 11 — disableSynchronization in a narrow scope [community]

`device.disableSynchronization()` is a global kill switch. When teams apply it test-file-wide (or worse, globally), Detox loses its main advantage and every interaction that previously "just worked" needs an explicit `waitFor`. The correct pattern is the narrowest possible scope — wrap only the code that triggers the problematic SDK behavior:

```js
it('plays video without Detox sync fighting the media player', async () => {
  await element(by.id('play-button')).tap();

  // Narrow disable: media player timers confuse Detox idle detection
  await device.disableSynchronization();
  await waitFor(element(by.id('video-progress-bar')))
    .toBeVisible()
    .withTimeout(10000);
  await device.enableSynchronization();

  // Sync re-enabled — subsequent interactions are deterministic again
  await element(by.id('pause-button')).tap();
  await expect(element(by.id('play-button'))).toBeVisible();
});
```

Always pair every `disableSynchronization()` with a `try/finally` in production code so it re-enables even if the assertion throws.

### Pattern 12 — Parallel test execution with worker shards [community]

Detox supports running test files across multiple simulator instances in parallel. The key constraint is that each worker must get its own device instance — sharing a device between workers causes race conditions that look like random element-not-found failures.

```js
// e2e/jest.config.js
module.exports = {
  rootDir: '..',
  testMatch: ['<rootDir>/e2e/**/*.test.js'],
  testTimeout: 120000,
  maxWorkers: 3,   // one simulator per worker — check available hardware
  retryTimes: 1,
};
```

```yaml
# GitHub Actions — matrix strategy for CI parallelism
strategy:
  matrix:
    shard: [1, 2, 3]
steps:
  - run: |
      npx detox test -c ios.sim.ci \
        --testNamePattern="" \
        --shard=${{ matrix.shard }}/3
```

Warning: on macOS CI runners, booting more than 2–3 simulators simultaneously often causes boot failures. Start with 2 workers and increase only after verifying stability.

---

## Selector / Locator Strategy

Ranked from most stable to most fragile:

| Rank | Selector | API | Notes |
|------|----------|-----|-------|
| 1 | `testID` prop | `by.id('testID')` | Best — survives refactors, localization, style changes |
| 2 | Accessibility label | `by.label('Submit')` | Good — doubles as a11y; survives layout changes |
| 3 | Accessibility type | `by.type('RCTTextInput')` | OK — use to narrow when testID is absent |
| 4 | Visible text | `by.text('Log in')` | Fragile — breaks on copy changes and i18n |
| 5 | XPath / CSS | n/a (not supported) | Not supported in Detox — do not attempt |

**Rule**: Add `testID` to every button, input, screen root, and list item that a test will touch. Coordinate with app developers to add them proactively.

**Compound matchers for lists**: When multiple elements share a `testID` pattern (e.g., list items), use `.atIndex(n)` or compose matchers:

```js
// List items with indexed testIDs
await element(by.id('todo-item-0')).tap();

// OR: narrow by type when testID is shared
await element(by.id('list-item').and(by.type('RCTView'))).atIndex(2).tap();
```

---

## Real-World Gotchas [community]

These pitfalls come from production usage, GitHub Discussions, engineering blogs, and React Native community reports — not the official documentation.

### 1. The "passes locally, fails on CI" class of failures [community]

**Root cause**: Slow CI hardware means idle detection takes longer, and background timers from analytics SDKs (Firebase, Amplitude) fire *while* Detox is waiting for the app to idle. Detox sees pending network activity and keeps waiting until `waitFor` times out. On a fast dev machine the SDK calls complete in <100ms and are never noticed.

**Fix**: Use `device.setURLBlacklist()` at test setup to blacklist analytics endpoints. Combine with pinning the simulator to a specific model (slower simulators = more exposure to this).

### 2. Simulator "re-use" between test runs causes state contamination [community]

**Root cause**: When `device.launchApp()` is called without `newInstance: true`, Detox re-attaches to an already-running simulator. If a previous test crashed the app mid-state (e.g., corrupt AsyncStorage, partially written Keychain entry), the next run inherits that corruption. The test looks like it's testing a fresh app but is actually testing a broken state.

**Fix**: Use `newInstance: true` in `beforeAll` for any suite that touches persistent storage. Accept the 3–5 second cold-boot overhead; it eliminates an entire class of phantom failures.

### 3. atIndex(0) hiding non-unique testID bugs [community]

**Root cause**: When duplicate `testID` values appear in a list (e.g., every list item has `testID="list-row"` instead of `testID="list-row-{id}"`), using `.atIndex(0)` silently masks the problem. Tests pass, but you're always testing only the first element and never discovering that tap targets are wrong on subsequent items.

**Fix**: Make list-item testIDs unique: `testID={\`todo-item-${item.id}\`}`. Reserve `.atIndex()` for true compound scenarios (e.g., two buttons with the same label in different panels), not for working around duplicate IDs.

### 4. `reloadReactNative()` does not reset native modules [community]

**Root cause**: Many teams switch from `newInstance: true` to `reloadReactNative()` in `beforeEach` to speed up their suite. But `reloadReactNative()` only resets the JS bundle — it does NOT reset AsyncStorage, Keychain, SQLite, or native module state. Tests that write to these stores in one run pollute the next.

**Fix**: Explicitly clear storage in `beforeEach` at the JS level (e.g., `AsyncStorage.clear()` via a mock API call), or use `newInstance: true` for any suite that persists data. Use `reloadReactNative()` only for pure-UI test suites with no storage writes.

### 5. Hard-coded simulator type causes boot failures on cloud CI [community]

**Root cause**: CI configurations that specify `device: { type: 'iPhone 14' }` fail on runners where only iPhone 15 or iPhone SE is available. iOS simulators on cloud CI (GitHub Actions, Bitrise, CircleCI) update their Xcode images on a different schedule than your local machine. A config that worked last month breaks after an Xcode image update.

**Fix**: Prefer using the OS version as the constraint, not the device model, or fetch available simulators dynamically:

```js
// .detoxrc.js — prefer version-based or runtime-based targeting
configurations: {
  'ios.sim.ci': {
    device: {
      type: 'simulator',
      device: { type: 'iPhone 15' },  // update when Xcode image updates
      os: 'latest',
    },
  },
},
```

Alternatively, add a CI pre-step that lists available simulators and picks one:
```bash
xcrun simctl list devices available | grep 'iPhone'
```

### 6. Detox sync blocked by infinite animation (Lottie, looped indicators) [community]

**Root cause**: Lottie animations that loop indefinitely (e.g., a loading spinner on a screen) keep a native animation frame scheduled at all times. Detox's idle detector sees "animation running" and never considers the app idle. The test hangs until it times out — even when the actual UI the test needs is fully rendered.

**Fix**: Gate looping animations behind an `isTestEnvironment` flag and either stop them or replace them with static content when running under Detox:

```js
// Use Detox-provided global or your own build flag
const isTest = typeof detox !== 'undefined' || !!process.env.DETOX_DISABLE_ANIMATIONS;

// In your component
{isTest ? <View style={styles.staticPlaceholder} /> : <LottieView source={animation} loop />}
```

### 7. waitFor polling interval creates phantom races on navigation [community]

**Root cause**: `waitFor().toBeVisible().withTimeout(5000)` polls every ~100ms. If a navigation transition briefly shows AND hides the target element (e.g., a screen that appears during a stack push then immediately gets popped by an error handler), `waitFor` can resolve on the intermediate state and the test proceeds as if navigation succeeded when it actually failed.

**Fix**: Assert both the destination element AND the absence of the source element. Or add a `toHaveText()` assertion immediately after `toBeVisible()` to confirm the correct screen:

```js
await waitFor(element(by.id('home-screen'))).toBeVisible().withTimeout(5000);
// Confirm we're on the real home screen, not a transition ghost
await expect(element(by.id('home-welcome-text'))).toBeVisible();
```

---

## CI Considerations

### Animation disabling

Disable `UIManager.setLayoutAnimationEnabledExperimental` on Android and pass `detoxDisableAnimations: 'true'` via `launchArgs` on iOS. Without this, Detox waits for animation frames that never stop on fast-path screens.

### Simulator boot timeout

Add a generous `setupTimeout` in Jest config. On a cold macOS CI runner, simulator boot + app install can take 60–90 seconds. Default Jest setup timeout is 5 seconds and will abort before Detox finishes booting.

```js
// e2e/jest.config.js
module.exports = {
  testTimeout: 120000,
  // detox-specific: give the beforeAll plenty of time
};
```

In newer Detox versions this is configured in `.detoxrc.js`:

```js
testRunner: {
  jest: { setupTimeout: 300000 },  // 5 minutes for cold-boot CI
},
```

### Artifact collection on failure

Configure the `artifacts` block in `.detoxrc.js` (see Pattern 10). Without screenshots/video on CI failure, you are debugging blind. Save artifacts to the CI upload path and set `retention-days` to avoid storage bloat.

### Binary staleness prevention

Always rebuild the app before running Detox. Use a source hash in your CI binary cache key:

```yaml
- name: Cache iOS build
  uses: actions/cache@v3
  with:
    path: ios/build
    key: ios-build-${{ hashFiles('ios/**', 'src/**', 'package.json') }}
```

If the cache key doesn't include source files, a code change won't invalidate the cached binary, and you'll run new tests against the old binary.

### Parallel execution constraints [community]

Each Detox worker needs its own simulator instance. On macOS GitHub Actions runners (12 vCPUs), booting more than 2–3 simulators simultaneously causes instability. Prefer splitting test files across multiple CI jobs (matrix strategy) rather than using `maxWorkers` within a single job.

### React Native New Architecture (Fabric) notes [community]

On Fabric (New Architecture), some third-party components do not yet expose `testID` to the native accessibility tree. If `by.id()` fails to find an element that visually exists, check whether the component is a Fabric-native component without testID bridging. Workaround: wrap in a `<View testID="wrapper-id">` at the parent level.

---

## Key APIs

| Method | Description | When to use |
|--------|-------------|-------------|
| `element(by.id(id))` | Select element by `testID` | Primary selector for all interactions |
| `element(by.label(label))` | Select by accessibility label | When `testID` is absent |
| `element(by.text(text))` | Select by visible text | Assertions only; avoid for actions |
| `element(by.type(type))` | Select by native component type | Narrowing when testID is shared |
| `.and(matcher)` | Compound matcher | Combining matchers for precision |
| `.atIndex(n)` | Select nth match | Only when multiple distinct elements match |
| `.tap()` | Simulates a tap | Buttons, list items, toggles |
| `.typeText(str)` | Types text into an input | Text fields |
| `.clearText()` | Clears a text input | Before re-typing in an already-filled field |
| `.replaceText(str)` | Clears and types in one call | Faster than clearText+typeText |
| `.scroll(px, direction)` | Scrolls a scrollable container | Reaching off-screen elements |
| `.scrollTo(edge)` | Scrolls to `'top'`, `'bottom'`, `'left'`, `'right'` | Quick edge scrolling |
| `.swipe(direction, speed, norm)` | Swipe gesture | Carousels, dismissible modals |
| `.longPress()` | Long press | Context menus, drag handles |
| `expect(el).toBeVisible()` | Asserts element is on screen and visible | Primary visibility assertion |
| `expect(el).toExist()` | Asserts element is in React tree | Checking unmounted vs mounted |
| `expect(el).toHaveText(str)` | Asserts element displays text | Text content assertions |
| `expect(el).not.toBeVisible()` | Asserts element is hidden or absent | Verifying dismissal |
| `waitFor(el).toBeVisible().withTimeout(ms)` | Waits up to ms for element to appear | Async data load, navigation transitions |
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

---

## Flakiness Diagnosis Checklist

Use this checklist when a test passes locally but fails on CI:

1. **Timing** — Does the test use any `setTimeout` or fixed sleep? Replace with `waitFor`.
2. **Animations** — Are animations disabled in the CI build? See Pattern 5.
3. **Simulator model** — Is CI using the same simulator type as local? Pin it in the CI config; check that the Xcode image supports your pinned model (Gotcha 5).
4. **Binary staleness** — Was the app rebuilt before the run? Verify the CI cache key includes a source hash.
5. **Network calls** — Does the test hit real APIs? Mock or intercept network in e2e tests; use `device.setURLBlacklist` to suppress analytics noise (Pattern 9, Gotcha 1).
6. **Synchronization scope** — Are third-party SDKs (Firebase, Amplitude, etc.) triggering background timers that confuse Detox's idle detection? Use `device.setURLBlacklist` or narrow-scope `disableSynchronization` (Pattern 11).
7. **Infinite animations** — Does the screen contain Lottie or looping animations? Gate them behind a test flag (Gotcha 6).
8. **Element uniqueness** — Does `by.id()` match more than one element? Use `.atIndex(0)` only as a last resort; fix the `testID` (Gotcha 3).
9. **Scroll position** — Is the element off-screen? Scroll the containing view before interacting.
10. **State leak** — Does a failing test leave the app in a bad state? Check whether `reloadReactNative()` is sufficient or whether `newInstance: true` is needed (Gotcha 4).
11. **Permissions** — Does the app request OS permissions on first launch? Pre-grant them via `launchApp` `permissions` (Pattern 8).
12. **New Architecture** — Is the target component a Fabric-native component? Check testID bridging (CI Considerations).
