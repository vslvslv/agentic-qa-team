# Detox Patterns & Best Practices

> Generated from official Detox documentation (wix.github.io/Detox) on 2026-04-26.
> Re-run `/qa-refine Detox` to refresh.

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
      app: { type: 'ios.app', binaryPath: 'ios/build/Build/Products/Debug-iphonesimulator/MyApp.app' },
    },
    'android.emu.ci': {
      device: { type: 'emulator', avd: 'Pixel_4_API_30' },
      app: { type: 'android.apk', binaryPath: 'android/app/build/outputs/apk/debug/app-debug.apk' },
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

---

## Anti-Patterns

- **`await new Promise(r => setTimeout(r, 2000))`** — Hard-coded sleep. Masks real timing problems and makes tests slower without making them more reliable. Use `waitFor` instead.
- **Relying on `by.text()` for navigation** — User-facing strings change. A copy update should not break your test suite. Always add a `testID`.
- **Single global `beforeAll` launch** — If any test mutates app state and the suite continues, downstream tests inherit broken state. Use `beforeEach` with `reloadReactNative()`.
- **Sharing Detox device across `describe` blocks without reset** — Leads to order-dependent failures that are invisible when running one file at a time but appear on CI (parallel execution or different file order).
- **Disabling Detox synchronization globally** (`device.disableSynchronization()`) — Kills automatic idle detection for the entire test run. Only disable synchronization in a narrow scope (e.g., while a background animation plays) and re-enable it immediately.
- **Using `by.id()` with non-unique testIDs** — If multiple elements share the same `testID` (e.g., in a list), Detox throws "multiple elements found". Use `by.id().atIndex(n)` or add unique IDs to list items.
- **Asserting on non-visible elements** — `toBeVisible()` checks that the element is on screen and not hidden. `toExist()` only checks the React tree. Prefer `toBeVisible()` for user-facing assertions.
- **Running tests against a stale binary** — A common CI failure pattern: the app binary is cached from a previous run and does not reflect new code. Always rebuild before running the full suite; use binary caching only if the source hash is verified.

---

## Key APIs

| Method | Description | When to use |
|--------|-------------|-------------|
| `element(by.id(id))` | Select element by `testID` | Primary selector for all interactions |
| `element(by.label(label))` | Select by accessibility label | When `testID` is absent |
| `element(by.text(text))` | Select by visible text | Assertions only; avoid for actions |
| `.tap()` | Simulates a tap | Buttons, list items, toggles |
| `.typeText(str)` | Types text into an input | Text fields |
| `.clearText()` | Clears a text input | Before re-typing in an already-filled field |
| `.scroll(px, direction)` | Scrolls a scrollable container | Reaching off-screen elements |
| `.scrollTo(edge)` | Scrolls to `'top'`, `'bottom'`, `'left'`, `'right'` | Quick edge scrolling |
| `.swipe(direction, speed, norm)` | Swipe gesture | Carousels, dismissible modals |
| `expect(el).toBeVisible()` | Asserts element is on screen and visible | Primary visibility assertion |
| `expect(el).toExist()` | Asserts element is in React tree | Checking unmounted vs mounted |
| `expect(el).toHaveText(str)` | Asserts element displays text | Text content assertions |
| `waitFor(el).toBeVisible().withTimeout(ms)` | Waits up to ms for element to appear | Async data load, navigation transitions |
| `device.launchApp(params)` | Launch or relaunch the app | `beforeAll` / test-level resets |
| `device.reloadReactNative()` | Reload JS bundle without restart | Fast `beforeEach` state reset |
| `device.terminateApp()` | Kill the app process | Cleanup in `afterAll` |
| `device.sendUserNotification(payload)` | Simulate a push notification | Testing notification-triggered flows |
| `device.setURLBlacklist(patterns)` | Block URLs from being tracked by sync | Suppress flakiness from analytics/ad beacons |
| `device.disableSynchronization()` | Disable automatic idle waiting | Narrow scope around known sync-breaking code |
| `device.enableSynchronization()` | Re-enable automatic idle waiting | Re-enable immediately after `disableSynchronization` |

---

## Flakiness Diagnosis Checklist

Use this checklist when a test passes locally but fails on CI:

1. **Timing** — Does the test use any `setTimeout` or fixed sleep? Replace with `waitFor`.
2. **Animations** — Are animations disabled in the CI build? See Pattern 5.
3. **Simulator model** — Is CI using the same simulator type as local? Pin it in the CI config.
4. **Binary staleness** — Was the app rebuilt before the run? Verify the CI cache key includes a source hash.
5. **Network calls** — Does the test hit real APIs? Mock or intercept network in e2e tests; use `device.setURLBlacklist` to suppress analytics noise.
6. **Synchronization scope** — Are third-party SDKs (Firebase, Amplitude, etc.) triggering background timers that confuse Detox's idle detection? Use `device.setURLBlacklist` or `disableSynchronization` in a narrow scope.
7. **Element uniqueness** — Does `by.id()` match more than one element? Use `.atIndex(0)` or fix the `testID`.
8. **Scroll position** — Is the element off-screen? Scroll the containing view before interacting.
9. **State leak** — Does a failing test leave the app in a bad state that affects the next test? Add `device.reloadReactNative()` in `beforeEach`.
10. **Permissions** — Does the app request OS permissions (camera, notifications) on first launch? Handle them in `launchApp` with `permissions: { notifications: 'YES', camera: 'YES' }`.
