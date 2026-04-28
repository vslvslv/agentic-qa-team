---
name: qa-visual
preamble-tier: 3
version: 1.0.0
description: |
  Visual regression test agent. Navigates key pages, captures screenshots with
  Playwright, compares them against stored baselines using pixel-diff, and reports
  any visual regressions. Manages baseline creation, threshold configuration, and
  diff artifact storage. Works standalone or as a sub-agent of /qa-team. Use when
  asked to "qa visual", "visual testing", "visual regression", "screenshot diff",
  "UI regression", "pixel diff", or "visual test agent". (qa-agentic-team)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
---

## Version check

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_QA_ROOT=$(dirname "$(readlink ~/.claude/skills/qa-visual 2>/dev/null)" 2>/dev/null) || true
[ ! -f "${_QA_ROOT:-x}/VERSION" ] && \
  _QA_ROOT="$(readlink ~/.claude/skills/qa-agentic-team 2>/dev/null)" || true
_QA_VER=$( [ -n "$_QA_ROOT" ] && bash "$_QA_ROOT/bin/qa-team-update-check" 2>/dev/null \
  || echo "UPDATE_CHECK_FAILED: not found" )
echo "VERSION_STATUS: $_QA_VER"
_QA_ASK_COOLDOWN="$_TMP/.qa-update-asked"
_QA_SKIP_ASK=0
if [ -f "$_QA_ASK_COOLDOWN" ]; then
  _qa_age=$(( $(date +%s) - $(cat "$_QA_ASK_COOLDOWN" | tr -d ' ') ))
  [ "$_qa_age" -lt 600 ] && _QA_SKIP_ASK=1
fi
```

If `VERSION_STATUS` contains `UPGRADE_AVAILABLE` and `_QA_SKIP_ASK` is `0`, use `AskUserQuestion`:
- Question: "qa-agentic-team update available (read vCURRENT → vNEW from VERSION_STATUS output). Update before running?"
- Options: "Yes — update now (recommended)" | "No — run with current version"
- Run `echo "$(date +%s)" > "$_QA_ASK_COOLDOWN"` to set a 10-minute cooldown (prevents repeated prompts in parallel sub-agents).
- If user selects "Yes": `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup" && echo "Updated successfully."`
- Continue regardless of choice.

---

## Preamble (run first)

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_DATE=$(date +%Y-%m-%d)
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"

# Detect base URL
_BASE_URL=$(grep -r "baseURL\|BASE_URL" playwright.config.ts playwright.config.js .env .env.local 2>/dev/null \
  | grep -o 'http[s]*://[^"'"'"' ]*' | head -1)
_BASE_URL="${_BASE_URL:-http://localhost:3000}"
echo "BASE_URL: $_BASE_URL"

# Check if app is running
_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$_BASE_URL" 2>/dev/null || echo "000")
echo "APP_STATUS: $_STATUS"

# Detect existing visual test setup
echo "--- VISUAL TEST SETUP ---"
ls playwright.config.ts playwright.config.js 2>/dev/null
find . \( -path "*/visual/*.spec.ts" -o -path "*/visual-regression/*.spec.ts" \
  -o -path "*/*.visual.spec.ts" \) ! -path "*/node_modules/*" 2>/dev/null | head -10
find . -name "*.png" \( -path "*/__screenshots__/*" -o -path "*/snapshots/*" \
  -o -path "*/baselines/*" -o -path "*/visual-baseline/*" \) 2>/dev/null | wc -l | \
  xargs echo "EXISTING_BASELINE_COUNT:"

# Detect Playwright visual comparison support
grep -r "toHaveScreenshot\|toMatchSnapshot" --include="*.ts" --include="*.js" \
  ! -path "*/node_modules/*" 2>/dev/null | head -5

# App pages
echo "--- APP ROUTES ---"
find . \( -path "*/pages/*.tsx" -o -path "*/app/**/*.tsx" -o -path "*/views/*.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -20
```

If `APP_STATUS` is `000`: warn the user. Offer to:
1. Proceed in baseline-only mode (capture screenshots without comparison)
2. Wait for user to start the app

## Phase 1 — Discover Visual Targets

Read page/route files to identify screens worth visual testing:

```bash
# All route paths
find . \( -path "*/pages/*.tsx" -o -path "*/app/**/*.tsx" \) \
  ! -path "*/node_modules/*" 2>/dev/null | head -5 | xargs cat 2>/dev/null | \
  grep -o '"[/][^"]*"' | sort -u | head -20

# Nav links reveal canonical routes
grep -r "href=\|to=\|Link" --include="*.tsx" ! -path "*/node_modules/*" 2>/dev/null | \
  grep -o '"\(/[^"]*\)"' | sort -u | head -30
```

Build **visual target list** — prioritize:
1. **Critical**: login page, main dashboard, primary list view, detail view
2. **Important**: forms, modals, empty states, error pages (404, 500)
3. **Nice-to-have**: settings, profile, less-trafficked pages

For each target, note:
- Route path
- Login required: yes/no
- Viewport variants: desktop (1280×720) + mobile (375×812)
- Dynamic content that must be masked (timestamps, avatars, charts)

## Phase 2 — Configure Visual Testing

Check if `playwright.config.ts` has `snapshotDir` set. If not, configure it:

```typescript
// Add to playwright.config.ts
const config: PlaywrightTestConfig = {
  // ... existing config ...
  snapshotDir: "./visual-baselines",
  expect: {
    toHaveScreenshot: {
      maxDiffPixels: 100,          // allow minor anti-aliasing diffs
      threshold: 0.2,              // 20% pixel color difference tolerance
      animations: "disabled",      // freeze CSS animations
    },
  },
};
```

Create baseline directory:

```bash
mkdir -p visual-baselines
echo "BASELINE_DIR: visual-baselines"
```

## Phase 3 — Generate Visual Test Specs

Create or update `e2e/visual/visual-regression.spec.ts`.

Read the file first if it exists — append only missing `test.describe` blocks.

**Spec template:**

```typescript
// e2e/visual/visual-regression.spec.ts
import { test, expect } from "@playwright/test";

// Pages that do NOT require authentication
const PUBLIC_PAGES = [
  { name: "Login", url: "/login" },
  { name: "Register", url: "/register" },
  { name: "404", url: "/this-page-does-not-exist" },
];

// Pages that require authentication
const PROTECTED_PAGES = [
  { name: "Dashboard", url: "/dashboard" },
  { name: "List", url: "/list" },
  { name: "Settings", url: "/settings" },
];

// ── Public pages ──────────────────────────────────────────────────────────────
test.describe("Visual: Public Pages", () => {
  for (const { name, url } of PUBLIC_PAGES) {
    test(`${name} page matches baseline`, async ({ page }) => {
      await page.goto(url);
      await page.waitForLoadState("networkidle");

      // Mask dynamic content: clocks, dates, animated elements
      await page.evaluate(() => {
        document.querySelectorAll("[data-testid='timestamp'], time, .animated")
          .forEach((el) => ((el as HTMLElement).style.visibility = "hidden"));
      });

      await expect(page).toHaveScreenshot(`${name.toLowerCase()}-desktop.png`, {
        fullPage: true,
        animations: "disabled",
      });
    });

    test(`${name} page mobile matches baseline`, async ({ page }) => {
      await page.setViewportSize({ width: 375, height: 812 });
      await page.goto(url);
      await page.waitForLoadState("networkidle");

      await expect(page).toHaveScreenshot(`${name.toLowerCase()}-mobile.png`, {
        fullPage: true,
        animations: "disabled",
      });
    });
  }
});

// ── Protected pages ───────────────────────────────────────────────────────────
test.describe("Visual: Protected Pages", () => {
  test.use({ storageState: "e2e/.auth/user.json" });

  for (const { name, url } of PROTECTED_PAGES) {
    test(`${name} page matches baseline`, async ({ page }) => {
      await page.goto(url);
      await page.waitForLoadState("networkidle");

      // Mask user-specific and dynamic data
      await page.evaluate(() => {
        document.querySelectorAll(
          "[data-testid='user-avatar'], [data-testid='timestamp'], " +
          ".chart, canvas, [aria-label*='chart']"
        ).forEach((el) => ((el as HTMLElement).style.visibility = "hidden"));
      });

      await expect(page).toHaveScreenshot(`${name.toLowerCase()}-desktop.png`, {
        fullPage: true,
        animations: "disabled",
        mask: [
          page.locator("canvas"),                   // mask chart canvases
          page.locator("[data-dynamic='true']"),     // mask any element marked dynamic
        ],
      });
    });
  }
});

// ── Component states ──────────────────────────────────────────────────────────
test.describe("Visual: Component States", () => {
  test("empty state renders correctly", async ({ page }) => {
    // Navigate to a view that has an empty state
    await page.goto("/list?filter=__nonexistent__");
    await page.waitForLoadState("networkidle");
    await expect(page.getByText(/no results|empty|nothing here/i)).toBeVisible();
    await expect(page).toHaveScreenshot("empty-state.png", { animations: "disabled" });
  });

  test("error state renders correctly", async ({ page }) => {
    await page.goto("/404-trigger");
    await page.waitForLoadState("networkidle");
    await expect(page).toHaveScreenshot("error-state.png", { animations: "disabled" });
  });
});
```

**Type-check after writing:**

```bash
_TSC=$(find . -path "*/node_modules/.bin/tsc" ! -path "*/node_modules/*/node_modules/*" | head -1)
[ -n "$_TSC" ] && "$_TSC" --noEmit 2>&1 | grep -E "\.(spec|test)\." | head -20 || echo "tsc not found"
```

## Phase 4 — Baseline Management

**First run (no baselines exist):** Update snapshots to create the baseline.

```bash
_VISUAL_SPECS=$(find . -path "*/visual/*.spec.ts" ! -path "*/node_modules/*" 2>/dev/null | tr '\n' ' ')
_BASELINE_COUNT=$(find visual-baselines/ -name "*.png" 2>/dev/null | wc -l)

if [ "$_BASELINE_COUNT" -eq 0 ]; then
  echo "No baselines found — creating initial baseline"
  npx playwright test $_VISUAL_SPECS \
    --update-snapshots \
    --project=chromium \
    2>&1 | tee "$_TMP/qa-visual-baseline.txt"
  echo "BASELINE_CREATED: $?"
else
  echo "BASELINE_COUNT: $_BASELINE_COUNT — running comparison"
fi
```

## Phase 5 — Execute Visual Comparison

```bash
export E2E_USER_EMAIL="${E2E_USER_EMAIL:-admin@example.com}"
export E2E_USER_PASSWORD="${E2E_USER_PASSWORD:-password123}"

# Auth setup if needed
[ ! -f "e2e/.auth/user.json" ] && \
  npx playwright test e2e/auth.setup.ts --project=setup 2>/dev/null || true

_VISUAL_SPECS=$(find . -path "*/visual/*.spec.ts" ! -path "*/node_modules/*" 2>/dev/null | tr '\n' ' ')
_PW_JSON="$_TMP/qa-visual-pw-results.json"

npx playwright test $_VISUAL_SPECS \
  --project=chromium \
  --reporter=json \
  2>&1 > "$_TMP/qa-visual-pw-output.txt"
_EXIT_CODE=$?
echo "PW_EXIT_CODE: $_EXIT_CODE"
cat "$_TMP/qa-visual-pw-output.txt" | tail -20
```

Parse results and identify regressions:

```bash
python3 - << 'PYEOF'
import json, os
tmp = os.environ.get("TEMP") or os.environ.get("TMP") or "/tmp"
pw_json = os.path.join(tmp, "qa-visual-pw-results.json")
if not os.path.exists(pw_json):
    print("No JSON report found"); exit()

data = json.load(open(pw_json))
regressions = []

def walk(suites):
    for suite in suites:
        for test in suite.get("tests", []):
            results = test.get("results", [{}])
            last = results[-1] if results else {}
            if last.get("status") == "failed":
                msg = ""
                for r in results:
                    for e in r.get("errors", []):
                        msg = e.get("message", "")[:300]
                        break
                regressions.append({"title": test.get("title"), "error": msg})
        walk(suite.get("suites", []))

walk(data.get("suites", []))
print(f"REGRESSIONS: {len(regressions)}")
for r in regressions:
    print(f"  - {r['title']}: {r['error'][:100]}")
PYEOF
```

Diff artifacts are automatically saved to `playwright-report/` by Playwright.

## Phase 6 — Report

Write report to `$_TMP/qa-visual-report.md`:

```markdown
# QA Visual Report — <date>

## Summary
- **Status**: ✅ / ⚠️ / ❌
- Passed: N · Failed (regressions): N · Skipped: N
- Baseline screenshots: N
- Viewports tested: desktop (1280×720), mobile (375×812)

## Visual Regressions
| Page | Viewport | Diff | Status |
|------|----------|------|--------|
| Dashboard | Desktop | 0 pixels | ✅ |
| Login | Mobile | 450px | ❌ regression |

## Regression Details
<for each regression: page name, viewport, pixel diff count, likely cause>

## Masked Elements
<list of dynamic elements masked per page>

## Baseline Update Required
<list pages where `--update-snapshots` should be run after intentional UI changes>

## Diff Artifacts
- Location: playwright-report/
- View: npx playwright show-report
```

## Important Rules

- **Baseline first** — if no baseline exists, create it before reporting "regressions"
- **Mask dynamic content** — timestamps, avatars, charts, animated elements must be hidden/masked
- **Animations disabled** — always pass `animations: "disabled"` to `toHaveScreenshot`
- **Deterministic viewport** — fix viewport size per screenshot; never rely on responsive defaults
- **Never auto-update baselines on CI** — only update manually with explicit `--update-snapshots` flag
- **Pixel threshold is project-specific** — default `maxDiffPixels: 100` is conservative; adjust if too noisy
- **Report even without comparison** — if baseline missing, document that baselines were created
- **No full-page on infinite scroll** — use `clip` option for pages with endless scroll
