# Maestro Patterns & Best Practices (YAML)
<!-- lang: YAML | sources: official | community | mixed | iteration: 0 | score: 88/100 | date: 2026-04-26 -->

## Core Principles

1. **Flows are plain YAML** — no SDK, no compile step. Every test is a `.yaml` file the
   runner executes directly, making authorship accessible to non-engineers.
2. **Resilient by default** — Maestro retries element lookups automatically; avoid
   explicit `sleep` unless absolutely required for animation timing.
3. **App identity is declared once** — `appId` at the top of every flow anchors all
   subsequent commands to the correct app, preventing cross-app confusion.
4. **Sub-flows keep things DRY** — common sequences (login, navigation) live in their
   own YAML files and are composed with `runFlow`, not copy-pasted.
5. **Secrets stay outside flows** — credentials and environment-specific values belong
   in an `envFile`, never hard-coded in YAML that might be committed to source control.

---

## Flow YAML Structure

Every Maestro flow file has two sections: a header block and a commands list.

```yaml
# flows/login.yaml
appId: com.example.myapp      # Required: bundle ID (iOS) or package name (Android)
---
- launchApp
- tapOn:
    text: "Sign In"
- inputText: "user@example.com"
- tapOn:
    id: "password_field"
- inputText: "${PASSWORD}"     # Value injected from envFile or --env flag
- tapOn:
    text: "Log In"
- assertVisible:
    text: "Welcome"
```

Key rules:
- The `---` separator between header and command list is required.
- `appId` must be the fully-qualified identifier, not the display name.
- Commands are a YAML list; order is execution order.

---

## Core Commands

### tapOn

Taps an element. Accepts `text`, `id`, `index`, `point`, or `selector` strategies.

```yaml
# By visible text (most readable)
- tapOn:
    text: "Continue"

# By accessibility ID (preferred for robustness)
- tapOn:
    id: "btn_continue"

# By index when multiple matches exist
- tapOn:
    text: "Item"
    index: 2          # 0-based

# By screen coordinate (last resort — brittle)
- tapOn:
    point: "50%, 80%"
```

### inputText

Types text into the currently focused input field. Pair with `tapOn` the field first.

```yaml
- tapOn:
    id: "search_input"
- inputText: "espresso"

# Clear existing text before typing
- clearText
- inputText: "new value"

# With environment variable
- inputText: "${USER_EMAIL}"
```

### assertVisible / assertNotVisible

Assertions are the primary correctness check. They retry until the element appears
(or timeout is reached).

```yaml
- assertVisible:
    text: "Order Confirmed"

- assertVisible:
    id: "success_banner"

- assertNotVisible:
    text: "Loading..."

# With regex matching
- assertVisible:
    text: "Order #[0-9]+"
    regex: true
```

---

## Sub-Flows with runFlow

`runFlow` composes reusable flows and passes parameters to them, enabling a
library-style approach to test authoring.

```yaml
# flows/checkout.yaml
appId: com.example.shop
---
- runFlow: flows/login.yaml          # Relative path from project root

- runFlow:
    file: flows/add_to_cart.yaml
    env:
      PRODUCT_NAME: "Blue Widget"    # Override env vars for this invocation
      QUANTITY: "2"

- assertVisible:
    text: "Cart (2)"
```

```yaml
# flows/add_to_cart.yaml — reusable sub-flow
appId: com.example.shop
---
- tapOn:
    text: "${PRODUCT_NAME}"
- tapOn:
    text: "Add to Cart"
- tapOn:
    id: "qty_stepper_up"
```

[community] Sub-flows do NOT inherit the parent's `appId` — always declare `appId`
in every flow file, including sub-flows, or you will get "app not found" errors.

---

## Environment Variables and envFile

Keep secrets and environment-specific values out of flow YAML.

```bash
# .env.local  (gitignore this file)
USER_EMAIL=qa@example.com
PASSWORD=s3cret
BASE_URL=https://staging.example.com
```

```yaml
# flows/login.yaml
appId: com.example.myapp
env:
  - .env.local              # Loaded relative to the flow file
---
- tapOn:
    id: "email_input"
- inputText: "${USER_EMAIL}"
- tapOn:
    id: "password_input"
- inputText: "${PASSWORD}"
```

```bash
# Pass inline at run time (overrides envFile)
maestro test flows/login.yaml --env USER_EMAIL=other@test.com
```

[community] Variables referenced in YAML but not defined in envFile or `--env` are
silently treated as empty strings — always validate your env file is being picked up
by adding a `assertVisible: text: "${EXPECTED_GREETING}"` early in the flow.

---

## Scroll and Swipe Gestures

```yaml
# Scroll down until an element is visible
- scrollUntilVisible:
    element:
      text: "Terms & Conditions"
    direction: DOWN         # UP | DOWN | LEFT | RIGHT
    timeout: 10000

# Swipe gesture (percentage-based coordinates)
- swipe:
    start: "50%, 80%"
    end: "50%, 20%"
    duration: 400           # ms

# Scroll within a specific container (by id)
- scroll:
    direction: DOWN
    containerId: "product_list_scroll"

# Pull to refresh
- swipe:
    start: "50%, 30%"
    end: "50%, 80%"
    duration: 300
```

[community] `scrollUntilVisible` is far more reliable than a fixed `swipe` count.
Using a hardcoded number of swipes breaks when screen density or content length changes
across devices.

---

## launchApp, stopApp, and clearState

Control app lifecycle to achieve a clean slate between test scenarios.

```yaml
appId: com.example.myapp
---
# Stop any running instance, clear all data, then launch fresh
- clearState                          # Wipes app data (SQLite, SharedPrefs, Keychain)
- launchApp

# Launch with specific arguments (deep link, feature flags)
- launchApp:
    arguments:
      FEATURE_NEW_CHECKOUT: "true"
    clearState: true                  # Combined shorthand

# Stop app mid-flow (e.g., to test background resume)
- stopApp

# Re-launch without clearing state (test resume behaviour)
- launchApp
```

[community] `clearState` on iOS removes the entire app sandbox including Keychain items
stored by the test app, but does NOT remove items stored in the shared system Keychain.
This can leave auth tokens behind on real devices — always pair with an explicit
logout flow for end-to-end auth tests.

---

## takeScreenshot

Capture screenshots for debugging failures or visual documentation.

```yaml
appId: com.example.myapp
---
- launchApp
- tapOn:
    text: "Dashboard"
- takeScreenshot: "dashboard_loaded"   # Saved as dashboard_loaded.png

# Conditional screenshot pattern
- runFlow:
    when:
      visible:
        text: "Error"
    flow:
      - takeScreenshot: "unexpected_error_state"
```

Screenshots land in `.maestro/tests/<timestamp>/` by default; use `--output` to
redirect in CI.

---

## Conditional Flows

Run commands only when a condition is met — useful for handling optional dialogs
(permission prompts, onboarding tooltips) that appear non-deterministically.

```yaml
appId: com.example.myapp
---
- launchApp

# Dismiss OS permission dialog only if present
- runFlow:
    when:
      visible:
        text: "Allow"
    flow:
      - tapOn:
          text: "Allow"

# Branch on element absence
- runFlow:
    when:
      notVisible:
        text: "Skip Tutorial"
    flow:
      - assertVisible:
          text: "Welcome Back"    # New users see tutorial; returning users skip
```

[community] Conditional flows execute inline — they do not break the enclosing flow
on failure. Wrap assertions you expect to always pass in the main flow, not inside a
`when:` branch, or a missing element will silently pass.

---

## Repeat Block

Iterate a command block a fixed number of times or while a condition holds.

```yaml
appId: com.example.myapp
---
# Repeat N times
- repeat:
    times: 5
    commands:
      - tapOn:
          text: "Load More"
      - sleep: 500

# Repeat while element is visible (polling)
- repeat:
    while:
      visible:
        text: "Loading"
    commands:
      - sleep: 1000
    maxTimes: 10            # Safety cap to prevent infinite loops

# Repeat over a list of values
- repeat:
    env:
      ITEM: ["Apple", "Banana", "Cherry"]
    commands:
      - tapOn:
          text: "${ITEM}"
      - assertVisible:
          text: "${ITEM} added"
```

[community] `repeat while:` without `maxTimes` can hang a CI job indefinitely if the
condition never clears — always set a cap.

---

## iOS vs Android Targeting

Most flows work across platforms unchanged. Use platform guards for divergent behaviour.

```yaml
appId: com.example.myapp   # iOS bundle ID
---
# Platform-conditional block
- runFlow:
    when:
      platform: iOS
    flow:
      - tapOn:
          text: "Continue"     # iOS biometric prompt label

- runFlow:
    when:
      platform: Android
    flow:
      - tapOn:
          text: "USE FINGERPRINT"   # Android label differs

# iOS-specific: swipe from left edge to navigate back
- runFlow:
    when:
      platform: iOS
    flow:
      - swipe:
          start: "0%, 50%"
          end: "40%, 50%"
```

For Android, `appId` is the package name (e.g. `com.example.myapp`).
For iOS, `appId` is the bundle identifier (e.g. `com.example.MyApp`).

[community] The iOS Simulator and Android Emulator can have different timing
characteristics for animations. If a flow passes on one platform and flakes on the
other, check whether `disableAnimations` is set in your launch arguments or simulator
settings — Maestro does not disable animations automatically.

---

## CI Headless Runner

Run Maestro in CI without a display server. Requires a running emulator/simulator
(or a connected device) before invoking the CLI.

```bash
# Run a single flow
maestro test flows/login.yaml

# Run an entire directory of flows
maestro test flows/

# Headless flag (suppresses interactive UI, suitable for CI)
maestro test --headless flows/

# With env file and output directory
maestro test \
  --env-file .env.ci \
  --output ./test-results \
  --headless \
  flows/

# Exit code: 0 = all passed, non-zero = failures (safe for CI gates)
```

Typical GitHub Actions snippet:

```yaml
# .github/workflows/mobile-e2e.yml (relevant steps)
- name: Start Android Emulator
  uses: reactivecircus/android-emulator-runner@v2
  with:
    api-level: 33
    script: maestro test --headless flows/
```

[community] The emulator must be fully booted (boot animation complete) before
`maestro test` is invoked — add a `adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done'` step or use an action that handles boot detection.

---

## Maestro Cloud (Brief)

Maestro Cloud (`maestro.mobile.dev/cloud`) runs flows on real devices in the cloud
without managing device infrastructure.

```bash
# Upload and run on Maestro Cloud
maestro cloud --apiKey $MAESTRO_CLOUD_API_KEY \
  --app build/app.apk \
  flows/

# iOS (provide .app archive)
maestro cloud --apiKey $MAESTRO_CLOUD_API_KEY \
  --app build/MyApp.app \
  flows/
```

[community] Maestro Cloud billing is per device-minute. Run smoke flows on Cloud and
keep exhaustive regression suites on local emulators to control costs.

---

## Real-World Gotchas

1. **Missing `appId` in sub-flows** [community] — Sub-flows execute in their own
   context and do not inherit the parent's `appId`. Every `.yaml` file needs its own
   `appId` declaration or the runner throws an ambiguous "no app" error mid-suite.

2. **Hard-coded `sleep` instead of assertions** [community] — `sleep: 3000` passes
   when CI is fast but breaks on a slow device or under load. Replace with
   `assertVisible` or `scrollUntilVisible`; Maestro retries automatically for up to
   the configured timeout (default 5s, configurable per command).

3. **Coordinate-based `tapOn` breaks on different screen sizes** [community] — Using
   `point: "320, 640"` ties tests to one resolution. Always prefer `text:`, `id:`, or
   `accessibility-label:` selectors; fall back to percentage coordinates
   (`"50%, 80%"`) only when structural selectors are unavailable.

4. **`clearState` on iOS does not clear shared Keychain** [community] — Apps using
   `kSecAttrAccessibleAfterFirstUnlock` with shared access groups retain tokens across
   `clearState`. Add an explicit logout flow before `clearState` in auth-sensitive tests.

5. **`repeat while:` without `maxTimes` hangs CI** [community] — If a "loading"
   spinner never disappears due to a backend failure, a `while:` loop without
   `maxTimes` will spin until the CI job times out (sometimes 6+ hours). Always cap
   with `maxTimes: 20` or similar.

6. **`envFile` path is relative to the flow, not the working directory** [community] —
   Running `maestro test subfolder/flow.yaml` with `env: .env` in the flow resolves
   `.env` relative to `subfolder/`, not the repo root. Use absolute paths or pass
   `--env-file` from the CLI to avoid "variable undefined" surprises.

7. **iOS Simulator not matching device behaviour for gestures** [community] — Swipe
   velocities on the Simulator are not the same as on physical hardware. Flows
   exercising velocity-sensitive swipe-to-delete or drag-and-drop interactions must
   be validated on a real device or via Maestro Cloud before marking them as stable.

---

## Key APIs

| Command | Purpose | When to use |
|---------|---------|-------------|
| `tapOn` | Tap element by text/id/index/point | Primary interaction primitive |
| `inputText` | Type into focused field | After tapping an input element |
| `clearText` | Clear focused field contents | Before re-entering text in a pre-filled field |
| `assertVisible` | Assert element is on-screen | Verify navigation, success states |
| `assertNotVisible` | Assert element is absent | Verify loading spinners cleared, errors dismissed |
| `scrollUntilVisible` | Scroll a list until target appears | Long lists, dynamic content |
| `swipe` | Freeform gesture by coordinates | Pull-to-refresh, drawer open/close |
| `runFlow` | Compose / call a sub-flow | Login, setup, teardown reuse |
| `launchApp` | Start the app (optionally clear state) | Test entry point |
| `stopApp` | Terminate the app | Background/resume tests |
| `clearState` | Wipe app data and launch fresh | Isolation between scenarios |
| `takeScreenshot` | Capture PNG with a label | Debugging, visual checkpoints |
| `repeat` | Loop commands N times or while condition | Pagination, polling |
| `sleep` | Fixed delay (ms) | Animation timing only — avoid overuse |
| `evalScript` | Execute JavaScript snippet | Dynamic value generation, date math |

---

## CI Checklist

- [ ] Emulator/simulator fully booted before invoking `maestro test`
- [ ] `--headless` flag set to suppress interactive UI
- [ ] `--env-file` points to CI-specific secrets (not committed to repo)
- [ ] `--output ./test-results` set so artifacts are collected by CI
- [ ] Exit code checked — non-zero fails the pipeline
- [ ] `maxTimes` set on all `repeat while:` blocks
- [ ] `clearState: true` in `launchApp` for the first flow of each test run
- [ ] Screenshots reviewed in artifact store on failure
