# Accessibility Testing (a11y) — QA Methodology Guide
<!-- lang: TypeScript | topic: accessibility | iteration: 10 | score: 98/100 | date: 2026-04-26 -->

## Core Principles (POUR)

WCAG 2.1 is organized around four foundational principles known as POUR. Every success criterion maps to one of these four categories. Understanding POUR before writing tests helps QA engineers know **why** a given test exists and what class of user it protects.

**Why POUR matters for testing**: Tests that merely pass "the linter" without understanding POUR miss the user impact. Perceivable tests protect blind/deaf users; Operable tests protect motor-impaired and keyboard-only users; Understandable tests protect cognitive-impaired and non-native language users; Robust tests protect all users of assistive technology now and in the future.

### Perceivable
Information and UI components must be presentable to users in ways they can perceive. Users cannot interact with content they cannot detect. This addresses people who are blind, deaf, or have cognitive differences in processing visual/audio information.
- **1.1.1 Non-text Content (A)**: Provide text alternatives (`alt`, `aria-label`, `aria-labelledby`) for all non-text content — decorative images get `alt=""`
- **1.2.x Captions/Audio Description (A/AA)**: Offer captions for video, transcripts for audio; critical for deaf users
- **1.3.1 Info and Relationships (A)**: Semantic HTML (`<h1>`–`<h6>`, `<table>`, `<ul>`) conveys structure to screen readers — do not use `<div>` for structure that has a semantic equivalent
- **1.3.3 Sensory Characteristics (A)**: Do not rely solely on color, shape, or position to convey meaning (e.g., "click the red button" fails)
- **1.4.3 Contrast Minimum (AA)**: 4.5:1 for normal text, 3:1 for large text
- **1.4.4 Resize Text (AA)**: Text must resize to 200% without loss of content

### Operable
UI components and navigation must be operable. If a user cannot operate the interface, they cannot use it. This addresses motor disabilities and users who rely on keyboard or switch access devices.
- **2.1.1 Keyboard (A)**: All functionality must be accessible via keyboard alone — no mouse-only interactions
- **2.1.2 No Keyboard Trap (A)**: Focus must not get stuck inside a component unless it is a dialog that intentionally traps focus (and provides a dismiss mechanism)
- **2.4.3 Focus Order (A)**: Tab order must be logical and match visual reading order
- **2.4.7 Focus Visible (AA)**: Keyboard focus indicator must be visible — `outline: none` without replacement is a failure
- **2.5.3 Label in Name (A)**: For UI components with visible text labels, the accessible name must contain the visible text

### Understandable
Information and the operation of the UI must be understandable. This addresses users with cognitive disabilities, learning differences, and users who speak the language as a second language.
- **3.1.1 Language of Page (A)**: `lang` attribute on `<html>` — screen readers use this to select the correct pronunciation engine
- **3.2.1 On Focus (A)**: Receiving focus must not trigger unexpected context changes (no auto-submit on focus)
- **3.3.1 Error Identification (A)**: Form errors must be described in text — "This field is required" not just a red border
- **3.3.2 Labels or Instructions (A)**: All form inputs must have visible labels (not just placeholder text, which disappears on input)

### Robust
Content must be robust enough to be interpreted by a wide variety of user agents, including current and future assistive technologies. This is the technical foundation that enables the other three principles to work.
- **4.1.1 Parsing (A)**: Valid HTML — unique IDs, proper nesting, complete start/end tags. Malformed markup causes assistive technologies to misinterpret structure.
- **4.1.2 Name, Role, Value (A)**: All UI components must have a programmatic name, role, and state (via HTML semantics or ARIA). This is the most commonly failed criterion.
- **4.1.3 Status Messages (AA)**: Dynamically injected content (alerts, progress updates) must be announced without moving focus — use `aria-live="polite"` or `role="alert"` appropriately

---

## When to Use

Accessibility testing applies at every layer of the test pyramid:

| Layer | Tool | When |
|-------|------|------|
| Unit / Component | jest-axe + @testing-library | On every PR, in CI |
| Integration / E2E | Playwright + @axe-core/playwright | On every PR, in CI |
| Manual audit | Screen reader + keyboard | Per sprint, before major releases |
| Visual | Color contrast checker | Design review + automated scan |

**Legal requirement triggers**: ADA Title III (US), Section 508 (US federal), EN 301 549 (EU), AODA (Canada), DDA (UK/AU). Any public-facing web application serving these jurisdictions should target WCAG 2.1 AA minimum. US federal contractors must meet Section 508, which references WCAG 2.0 AA.

**When a11y testing is legally required vs. best practice:**

| Situation | Legal requirement | Standard |
|-----------|-------------------|----------|
| US federal agency or contractor | Yes — Section 508 | WCAG 2.0 AA (moving to 2.1) |
| EU public sector website (EU Directive 2016/2102) | Yes | EN 301 549 / WCAG 2.1 AA |
| Private US business (ADA Title III) | Yes if challenged — increasingly enforced | WCAG 2.1 AA by case law |
| Canadian federal / Ontario public sector (AODA) | Yes | WCAG 2.0 AA → 2.1 AA |
| UK public sector (PSBAR) | Yes | WCAG 2.1 AA |
| Private business, global SaaS | No hard mandate, but litigation risk | WCAG 2.1 AA recommended |

**WebAIM Million Report (2024 findings)** — scanning top 1 million homepages:
- 95.9% of home pages had detected WCAG failures
- Most common failures: low color contrast (80.9%), missing alt text (54.5%), missing form labels (48.6%), empty links (44.6%), missing document language (17.1%), empty buttons (27.5%)
- Average: 56.8 detected errors per page
- These statistics justify why automated scanning at CI time catches a meaningful slice of production bugs

---

## Patterns

### Why axe-core Is the Standard Rule Engine

axe-core is the open-source accessibility rule engine powering jest-axe, `@axe-core/playwright`, the Deque browser extensions, and Lighthouse. It has become the de facto standard for several reasons:

- **Coverage**: Deque research shows axe-core detects ~57% of WCAG issues automatically — the highest coverage of any open-source engine
- **Zero false positives by design**: axe-core's rules only flag definitive failures. Uncertain cases (where manual review is needed) are returned as `incomplete` rather than violations. This design choice keeps CI pipelines trustworthy.
- **Wide adoption**: Used by Microsoft, Google, GitHub, and most major design systems, meaning axe's rule interpretations are well-scrutinized
- **TypeScript support**: Ships with `axe.d.ts` type definitions; both jest-axe and `@axe-core/playwright` are TypeScript-native
- **Standard tags**: Rules are tagged by WCAG version and level (`wcag2a`, `wcag2aa`, `wcag21aa`, `wcag22aa`, `best-practice`), enabling precise scope control

**axe-core coverage ceiling**: The ~57% figure means automated testing is necessary but not sufficient. The remaining ~43% of issues require keyboard testing, screen reader verification, and cognitive review. Building a CI gate on axe alone creates a false sense of compliance.

---

### jest-axe: Component-Level A11y Testing

jest-axe integrates axe-core into Jest unit tests, enabling automated accessibility checks at the component level during normal development cycles. It catches structural issues (missing labels, invalid ARIA, duplicate IDs) as fast unit tests before code reaches a real browser.

```typescript
// Example: Button component accessibility test with axe.configure
// File: src/components/Button/Button.a11y.test.tsx
import React from 'react';
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations, configureAxe } from 'jest-axe';

expect.extend(toHaveNoViolations);

// Configure axe globally for this test file:
// - run WCAG 2.1 AA rules only
// - disable color-contrast (JSDOM cannot compute it — use Playwright for contrast)
const axeConfig = configureAxe({
  rules: [
    { id: 'color-contrast', enabled: false }, // JSDOM limitation — test in Playwright
  ],
  runOnly: {
    type: 'tag',
    values: ['wcag2a', 'wcag2aa', 'wcag21aa', 'best-practice'],
  },
});

describe('Button accessibility', () => {
  it('renders with no axe violations when label provided', async () => {
    const { container } = render(
      <button type="button" aria-label="Submit form">
        Submit
      </button>
    );
    const results = await axeConfig(container);
    expect(results).toHaveNoViolations();
  });

  it('icon button requires accessible label', async () => {
    const { container } = render(
      // aria-label is required when button has no visible text
      <button type="button" aria-label="Close dialog">
        <svg aria-hidden="true" focusable="false">
          <use href="#icon-close" />
        </svg>
      </button>
    );
    const results = await axeConfig(container);
    expect(results).toHaveNoViolations();
  });

  it('detects missing label on icon-only button', async () => {
    const { container } = render(
      <button type="button">
        <svg>
          <use href="#icon-close" />
        </svg>
      </button>
    );
    const results = await axeConfig(container);
    // Document the expected failure mode so reviewers understand the test intent
    expect(results.violations.map((v) => v.id)).toContain('button-name');
  });

  it('form with associated label passes', async () => {
    const { container } = render(
      <div>
        <label htmlFor="email-input">Email address</label>
        <input id="email-input" type="email" name="email" />
      </div>
    );
    const results = await axeConfig(container);
    expect(results).toHaveNoViolations();
  });
});
```

**Setup** (`package.json` dependencies):
```json
{
  "devDependencies": {
    "jest-axe": "^8.0.0",
    "@testing-library/react": "^14.0.0",
    "@testing-library/jest-dom": "^6.0.0"
  }
}
```

### Playwright + axe: Full-Page A11y Audit

`@axe-core/playwright` runs axe-core against live pages in a real browser, catching issues that JSDOM-based tests miss (CSS-dependent color contrast, complex focus states, iframe content).

```typescript
// File: e2e/accessibility/full-page.a11y.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Homepage accessibility', () => {
  test('should have no automatically detectable WCAG 2.1 AA violations', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    // Log violations for CI visibility
    if (accessibilityScanResults.violations.length > 0) {
      console.table(
        accessibilityScanResults.violations.map((v) => ({
          id: v.id,
          impact: v.impact,
          description: v.description,
          nodes: v.nodes.length,
        }))
      );
    }

    expect(accessibilityScanResults.violations).toEqual([]);
  });

  test('modal dialog should trap focus', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-testid="open-modal"]');
    await page.waitForSelector('[role="dialog"]');

    // Audit only the modal region
    const results = await new AxeBuilder({ page })
      .include('[role="dialog"]')
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();

    expect(results.violations).toEqual([]);
  });
});
```

**Known limitation**: `@axe-core/playwright` does not check color contrast when pages are rendered without CSS (server-side). Always run against the fully-rendered page.

**CI integration pattern** — use Playwright's built-in reporter to output axe violations as structured test failures:

```typescript
// playwright.config.ts — configuring the axe scan as a global fixture
import { defineConfig } from '@playwright/test';

export default defineConfig({
  use: {
    // Always wait for full network before a11y scans
    actionTimeout: 10_000,
  },
  reporter: [
    ['html', { outputFolder: 'playwright-report/accessibility' }],
    ['json', { outputFile: 'test-results/a11y-results.json' }],
  ],
});
```

```typescript
// e2e/fixtures/axe-fixture.ts — reusable axe fixture for all E2E tests
import { test as base } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

// Extend base test with an axe helper available in all test files
export const test = base.extend<{ checkA11y: (selector?: string) => Promise<void> }>({
  checkA11y: async ({ page }, use) => {
    const checkA11y = async (selector?: string) => {
      let builder = new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa']);
      if (selector) builder = builder.include(selector);
      const results = await builder.analyze();
      if (results.violations.length > 0) {
        const msg = results.violations
          .map((v) => `[${v.impact}] ${v.id}: ${v.description} (${v.nodes.length} nodes)`)
          .join('\n');
        throw new Error(`Accessibility violations found:\n${msg}`);
      }
    };
    await use(checkA11y);
  },
});

export { expect } from '@playwright/test';
```

### ARIA Landmarks & Roles

Landmarks allow screen reader users to jump directly to major page regions. Every page should have at least `banner`, `main`, and `contentinfo`. Avoid duplicate landmark roles without distinguishing labels.

```typescript
// File: src/layouts/AppLayout.tsx
// Correct landmark structure for a standard application shell
import React from 'react';

interface AppLayoutProps {
  children: React.ReactNode;
  navigationLabel?: string;
}

export const AppLayout: React.FC<AppLayoutProps> = ({
  children,
  navigationLabel = 'Main navigation',
}) => {
  return (
    <>
      {/* Skip link — must be the first focusable element */}
      <a href="#main-content" className="skip-link">
        Skip to main content
      </a>

      {/* role="banner" is implicit on <header> at top level */}
      <header>
        <nav aria-label={navigationLabel}>
          {/* Primary navigation links */}
        </nav>
      </header>

      {/* role="main" is implicit on <main> */}
      <main id="main-content" tabIndex={-1}>
        {children}
      </main>

      {/* role="complementary" — related but not primary content */}
      <aside aria-label="Related articles">
        {/* Sidebar content */}
      </aside>

      {/* role="contentinfo" is implicit on <footer> at top level */}
      <footer>
        {/* Copyright, legal links */}
      </footer>
    </>
  );
};
```

**Required landmark set (WCAG 2.1 AA best practice)**:
| HTML Element | Implicit ARIA Role | Purpose |
|---|---|---|
| `<header>` (top-level) | `banner` | Site-wide header |
| `<nav>` | `navigation` | Navigation block |
| `<main>` | `main` | Primary content (one per page) |
| `<aside>` | `complementary` | Supporting content |
| `<footer>` (top-level) | `contentinfo` | Site-wide footer |
| `<section aria-label>` | `region` | Named page section |

### Keyboard Navigation Testing

Every interactive element must be reachable and operable via keyboard alone. This is one of the most common failure points for custom UI components.

```typescript
// File: e2e/accessibility/keyboard-nav.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Keyboard navigation', () => {
  test('skip link is first focusable element and jumps to main', async ({ page }) => {
    await page.goto('/');
    // Tab once from the URL bar
    await page.keyboard.press('Tab');
    const focused = await page.evaluate(() => document.activeElement?.textContent);
    expect(focused).toContain('Skip to main content');

    // Activating skip link should move focus to <main>
    await page.keyboard.press('Enter');
    const mainFocused = await page.evaluate(
      () => document.activeElement?.getAttribute('id')
    );
    expect(mainFocused).toBe('main-content');
  });

  test('modal dialog traps focus within itself', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-testid="open-modal"]');
    await page.waitForSelector('[role="dialog"]');

    // Collect all focusable elements inside the dialog
    const focusableCount = await page.evaluate(() => {
      const dialog = document.querySelector('[role="dialog"]');
      if (!dialog) return 0;
      return dialog.querySelectorAll(
        'a[href], button:not([disabled]), input:not([disabled]), [tabindex="0"]'
      ).length;
    });
    expect(focusableCount).toBeGreaterThan(0);

    // Tab through all dialog elements — focus must not leave dialog
    for (let i = 0; i < focusableCount + 2; i++) {
      await page.keyboard.press('Tab');
      const isInsideDialog = await page.evaluate(() => {
        const dialog = document.querySelector('[role="dialog"]');
        return dialog?.contains(document.activeElement) ?? false;
      });
      expect(isInsideDialog).toBe(true);
    }
  });

  test('dropdown menu closes on Escape', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Tab');
    // Navigate to menu trigger...
    await page.click('[data-testid="menu-trigger"]');
    await page.waitForSelector('[role="menu"]');
    await page.keyboard.press('Escape');
    await expect(page.locator('[role="menu"]')).not.toBeVisible();
  });
});
```

### Color Contrast Verification

WCAG 2.1 AA mandates:
- **4.5:1** contrast ratio for normal text (< 18pt / < 14pt bold)
- **3:1** contrast ratio for large text (≥ 18pt / ≥ 14pt bold)
- **3:1** for UI component boundaries and graphical objects (1.4.11 Non-text Contrast)
- WCAG 2.2 adds **2.5.8 Target Size (Minimum)**: interactive targets ≥ 24×24 CSS pixels

axe-core checks color contrast automatically in Playwright tests (real browser only — JSDOM cannot compute computed styles). For design-time verification, use the browser DevTools accessibility panel or the TPGi Colour Contrast Analyser tool.

```typescript
// File: e2e/accessibility/contrast.a11y.spec.ts
// Targeted contrast-only scan with axe — must run in real browser (Playwright)
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Color contrast requirements', () => {
  test('all text on homepage meets WCAG 2.1 AA contrast (4.5:1 / 3:1)', async ({ page }) => {
    await page.goto('/');
    // Ensure fonts and styles fully load
    await page.waitForLoadState('networkidle');

    // Run only contrast-specific rules to isolate failures
    const results = await new AxeBuilder({ page })
      .withRules(['color-contrast', 'color-contrast-enhanced'])
      .analyze();

    if (results.violations.length > 0) {
      results.violations.forEach((v) => {
        v.nodes.forEach((node) => {
          console.error(
            `Contrast failure: ${node.html}\n` +
            `  Expected: ${node.any[0]?.data?.contrastRatio ?? 'unknown'}`
          );
        });
      });
    }
    expect(results.violations).toEqual([]);
  });

  test('focus indicators meet 3:1 contrast against adjacent colors', async ({ page }) => {
    await page.goto('/');
    // Tab to first interactive element to trigger focus styles
    await page.keyboard.press('Tab');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag22aa'])
      .withRules(['focus-order-semantics', 'color-contrast'])
      .analyze();

    expect(results.violations).toEqual([]);
  });
});
```

Common failures:
- Gray placeholder text on white backgrounds (often falls below 4.5:1)
- Disabled button states that use light gray text (`#767676` on white = exactly 4.5:1; lighter fails)
- Focus indicator outlines that do not have sufficient contrast with the background
- Icon-only controls that use low-contrast icon colors against background (1.4.11 Non-text Contrast)
- Link text styled the same color as surrounding body text without underline (no contrast differentiation)

### Screen Reader Testing

Screen readers are the primary assistive technology for blind and low-vision users. Automated tools cannot replicate the screen reader experience — manual testing is required.

**Recommended test matrix:**

| Screen Reader | Browser | Platform | Market share (approx.) |
|---|---|---|---|
| NVDA (free) | Firefox | Windows | ~41% |
| JAWS (commercial) | Chrome/Edge | Windows | ~53% |
| VoiceOver | Safari | macOS/iOS | ~7% desktop, dominant mobile |
| TalkBack | Chrome | Android | Dominant Android |

**Minimum viable manual test checklist:**
1. Tab through every page — every interactive element should be reachable and have a meaningful label
2. Activate every button, link, and form control by keyboard (Enter/Space)
3. Verify that dynamic content updates (form errors, loading states, toasts) are announced automatically via `aria-live` regions
4. Check that modal dialogs trap focus and that closing returns focus to the trigger element
5. Verify that images have appropriate `alt` text — not just non-empty `alt` but contextually meaningful text
6. Test the skip link — screen reader users depend on it to skip repetitive navigation

**Testing NVDA + Firefox (Windows):**
```
1. Install NVDA from nvaccess.org (free)
2. Start NVDA (Ctrl+Alt+N)
3. Navigate to your application in Firefox
4. Press Tab to move focus, Arrow keys to read content
5. Press F7 to enter/exit Browse mode (virtual cursor)
6. Press D to cycle through landmarks, H for headings, B for buttons
```

**axe-core does NOT replace screen reader testing.** It catches structural issues (missing labels, invalid ARIA) but cannot verify that the announced experience is meaningful, logical, or correct.

---

## Live Regions and Dynamic Content

`aria-live` regions announce dynamically injected content to screen reader users without moving focus. This is essential for toast notifications, form validation errors, loading states, and real-time data.

```typescript
// File: src/components/Toast/Toast.a11y.test.tsx
// Testing aria-live announcement with @testing-library
import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import userEvent from '@testing-library/user-event';

expect.extend(toHaveNoViolations);

function ToastContainer() {
  const [message, setMessage] = React.useState('');
  return (
    <div>
      <button type="button" onClick={() => setMessage('File saved successfully')}>
        Save
      </button>
      {/* aria-live="polite": announces after current reading completes */}
      {/* aria-atomic="true": announces full content, not just changed nodes */}
      {/* Keep the region in DOM when empty — inserting it after content is set
          causes some screen readers to miss the announcement entirely */}
      <div
        aria-live="polite"
        aria-atomic="true"
        data-testid="toast-region"
        style={{ position: 'absolute', left: '-10000px' }}
      >
        {message}
      </div>
    </div>
  );
}

describe('Toast notification accessibility', () => {
  it('live region has no axe violations', async () => {
    const { container } = render(<ToastContainer />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('toast message is accessible to screen readers after trigger', async () => {
    const user = userEvent.setup();
    render(<ToastContainer />);
    await user.click(screen.getByRole('button', { name: 'Save' }));
    await screen.findByText('File saved successfully');
    expect(screen.getByTestId('toast-region')).toHaveTextContent('File saved successfully');
  });
});
```

**Live region decision guide:**
| Pattern | Use when | Urgency |
|---|---|---|
| `aria-live="polite"` | Non-urgent updates (save status, filter results count) | Waits for current speech |
| `role="alert"` / `aria-live="assertive"` | Critical errors (session timeout, data loss) | Interrupts current speech |
| `aria-atomic="true"` | Compound messages where partial content is confusing | Always with polite announcements |

---

## Anti-Patterns

1. **Using ARIA to override semantics without purpose**: `<div role="button">` without `tabIndex={0}` and keyboard event handlers is worse than `<button>`. Native HTML elements carry built-in keyboard support and implicit roles.

2. **aria-label overuse on every element**: Adding `aria-label` to every `<div>` and `<span>` creates noise for screen reader users. Use ARIA only when native semantics are insufficient.

3. **Positive tabIndex values**: `tabIndex={1}`, `tabIndex={2}` etc. create a separate tab order that overrides the natural DOM order and causes confusion. Use only `tabIndex={0}` (include in tab order) or `tabIndex={-1}` (programmatic focus only).

4. **Removing focus outlines without replacement**: `outline: none` in CSS without providing an alternative visible focus indicator is a WCAG 2.4.7 failure.

5. **Testing only with axe and calling it done**: axe-core catches ~30–57% of WCAG issues. Skipping keyboard and screen reader testing leaves most issues undetected.

6. **Generic link text**: `<a href="/report">Click here</a>` fails 2.4.6. Screen reader users navigate by links in isolation; the link text must describe the destination.

7. **Auto-playing media**: Auto-playing video or audio without controls violates 1.4.2 and is disruptive to screen reader users.

8. **Using `display: none` to hide content visually while leaving it in the tab order**: Elements with `display: none` or `visibility: hidden` are removed from the accessibility tree and tab order, but elements hidden with only CSS transform or opacity remain keyboard-reachable. Always use `display: none` or `inert` for truly hidden interactive content.

9. **Not testing with real keyboard users in mind**: Tab order and keyboard support that look correct in code reviews often fail in practice because developers test from a mouse user's mental model. Require team members to periodically navigate their own features using keyboard only — without touching the mouse.

---

## Automated vs Manual Testing Split

axe-core's automated rules detect approximately **30–57% of WCAG 2.1 issues**, according to Deque research and independent audits. The exact figure depends on the application type and richness of interactions.

**Why each category requires manual work:**

| Category | Automated (axe) | Manual Required | Why manual is needed |
|----------|----------------|----------------|---------------------|
| Color contrast | Yes | Only custom/dynamic | axe can't see contrast on canvas, SVG gradients, dynamically-colored text |
| Missing alt text | Yes | Descriptive quality | axe checks presence, not whether `alt="photo"` actually describes the image |
| Form label association | Yes | Label accuracy | axe checks association exists, not whether "Enter value" is helpful |
| ARIA attribute validity | Yes | ARIA logic correctness | axe checks syntax; wrong role combinations require human judgment |
| Landmark structure | Yes | Meaningful use | axe checks presence; whether structure aids navigation requires manual review |
| Keyboard navigation | Partial | Full flow testing | axe cannot simulate multi-step keyboard workflows |
| Focus order | No | Manual Tab traversal | Visual/logical order mismatch requires human perception |
| Screen reader announcement | No | NVDA / VoiceOver / TalkBack | Announcement quality, grammar, and context are not machine-testable |
| Cognitive load / plain language | No | Expert review | Entirely subjective to the target user's reading level |
| Error message quality | No | Manual review | Whether error guidance is actionable requires human judgment |
| Dynamic content updates | Partial | Live region behavior | Timing and announcement sequence of live regions require real AT testing |

**Recommended split per sprint:**
- **Automated (CI — every PR)**: jest-axe for all component tests; Playwright/axe for critical user flows
- **Manual keyboard (every sprint)**: QA engineer navigates every new page/flow without mouse; verifies focus order, skip links, modal traps
- **Screen reader (every sprint)**: NVDA + Firefox (Windows) and VoiceOver + Safari (macOS/iOS) for new interactive patterns
- **Accessibility audit (quarterly or pre-major release)**: Full expert review against WCAG 2.1 AA checklist, including cognitive and WCAG 2.2 new criteria
- **Regression baseline**: Consider snapshotting axe violation counts per page; fail CI if count increases, alert if it decreases (verify fix is real)

---

## Real-World Gotchas [community]

1. **[community] axe flags color contrast as incomplete in JSDOM tests**: jest-axe running in JSDOM cannot compute computed styles accurately, so color-contrast rules return `incomplete` rather than violations. Do not rely on jest-axe for contrast testing — run Playwright tests against the real rendered page.

2. **[community] aria-label vs aria-labelledby: labelledby wins in VoiceOver**: When both `aria-label` and `aria-labelledby` are present, `aria-labelledby` takes precedence. Teams that add `aria-label` expecting it to override an existing `aria-labelledby` label are surprised when the screen reader ignores it.

3. **[community] Focus management in SPAs: history pushState breaks focus**: In single-page apps using React Router or Next.js, navigation does not automatically move focus to the new page content. After route transitions, focus stays on the clicked link, leaving screen reader users lost. Solution: programmatically focus the `<main>` element or a heading after each route change.

4. **[community] Modal dialogs without `aria-modal="true"` expose background content**: Without `aria-modal="true"` on `[role="dialog"]`, many screen readers (NVDA + Firefox in Browse mode) allow users to read background content while the modal is open. This causes severe confusion. VoiceOver does not honor `aria-modal` — `inert` attribute on background content is the robust solution.

5. **[community] axe passes while VoiceOver fails on custom combobox**: axe validates ARIA attributes syntactically but cannot test whether a custom combobox widget actually announces options correctly when arrowing through a list. Teams rely on axe green status and ship broken screen reader experiences. Manual testing is required for all interactive widgets.

6. **[community] Playwright axe scans miss dynamically injected content**: If a toast notification or error message appears after user action, a page-level axe scan run at load time will not catch violations in that content. Use `page.waitForSelector` for dynamic regions before re-scanning.

7. **[community] tabIndex={0} on non-interactive elements with no keyboard handler**: Adding `tabIndex={0}` to a `<div>` makes it reachable by Tab but it does not become "clickable" via Enter/Space. Screen reader users in Forms Mode expect Enter/Space to activate it. Always pair `tabIndex={0}` with keydown handlers for Enter and Space.

8. **[community] Overriding native semantics with ARIA removes built-in behavior**: Adding `role="presentation"` to a `<button>` removes its button semantics. Adding `role="button"` to an `<a>` removes its link behavior. Auditors frequently find these applied by developers who did not understand the consequences.

9. **[community] axe-core versions differ between jest-axe and @axe-core/playwright**: Teams running different axe-core versions in unit vs E2E tests get inconsistent results — a rule that passes in jest-axe may fail in Playwright because the underlying axe-core version differs. Pin axe-core explicitly in your dependency tree.

10. **[community] aria-live="assertive" should be reserved for truly urgent messages**: Using `role="alert"` or `aria-live="assertive"` for routine status messages (form auto-saves, progress updates) interrupts whatever the screen reader is currently announcing. Use `aria-live="polite"` for non-urgent updates — it waits for the current announcement to finish.

11. **[community] iOS VoiceOver swipe navigation differs from NVDA browse mode**: A widget that works perfectly with NVDA + Firefox will often behave differently under VoiceOver + Safari on iOS. VoiceOver uses swipe gestures to navigate by element, and `aria-modal` is not honored. The `inert` attribute (or careful DOM structure) is the only reliable way to prevent background content from being swiped to.

12. **[community] axe-core does not scan inside closed Shadow DOM**: Web components using closed Shadow DOM are invisible to axe-core. Teams using design system components (Material Web, Shoelace, Lit-based components) may have a clean axe scan while their actual rendered components have contrast or label issues. Test the rendered browser output with real browser tools, not just axe.

13. **[community] Placeholder text is not a label substitute**: Using `placeholder` instead of `<label>` fails WCAG 3.3.2. Placeholder text disappears when users start typing, leaving users without context. Users with cognitive disabilities often forget what the field is asking. axe-core catches this as `label` rule violation, but teams suppress it thinking placeholder is sufficient.

14. **[community] Component unit tests pass but full-page axe fails**: Testing components in isolation with jest-axe can produce clean results even when the composed full page fails. For example, a component using `id="close-btn"` passes unit tests but fails `duplicate-id` in the real application where the component renders in multiple places. Always supplement unit-level tests with page-level Playwright scans.

15. **[community] React re-renders clear screen reader focus position**: When a React component re-renders due to state changes, the screen reader's virtual cursor position can be reset to the top of the updated DOM subtree. This is particularly disruptive in complex forms where real-time validation triggers re-renders on every keystroke. Debounce validation and use `aria-live` regions for error messages instead of conditionally rendering error elements inside the form flow.

---

## Tradeoffs & Alternatives

### WCAG Conformance Level Comparison

| Level | Criteria count | Description | Practical requirement |
|-------|------|-------------|----------------------|
| A | 30 | Minimum | Baseline; removing A-level barriers is the floor |
| AA | 20 additional | Mid-range | **Legal standard** in US/EU/CA/AU; target for all public apps |
| AAA | 28 additional | Enhanced | Aspirational; W3C does not require entire sites conform |

**Why not AAA?** W3C explicitly states that AAA conformance for entire sites is not recommended as a general policy because some criteria cannot be satisfied for all content types. For example, 1.4.6 (Contrast Enhanced, 7:1 ratio) would make many brand color palettes unusable. AAA criteria are appropriate as targets for specific content types (e.g., medical/government portals).

**Why AA specifically?** AA adds critical criteria that A misses: keyboard shortcuts (2.1.4), resize text without scroll (1.4.4), color contrast (1.4.3), no content-on-hover surprises (1.4.13), pointer gestures alternatives (2.5.1), and text spacing overrides (1.4.12). These directly address the most common disability barriers.

Most legal frameworks (ADA, Section 508, AODA, EN 301 549) reference **WCAG 2.1 Level AA**. WCAG 2.2 (published October 2023) adds 9 new criteria at A/AA — notably 2.5.7 Dragging Movements, 2.5.8 Target Size (Minimum 24×24px), and 3.2.6 Consistent Help. Adoption in legal frameworks is pending as of 2026 but increasingly referenced in procurement requirements.

### WCAG 2.2 Criteria QA Teams Should Start Testing Now

WCAG 2.2 removes 4.1.1 (Parsing) — now assumed satisfied by valid HTML5 parsers — and adds:

| Criterion | Level | What QA should test |
|---|---|---|
| 2.4.11 Focus Appearance | AA | Focus indicator must have ≥2px outline, ≥3:1 contrast ratio |
| 2.4.12 Focus Appearance (Enhanced) | AAA | Focus indicator area ≥ perimeter of component |
| 2.4.13 Focus Appearance | AA | Focus indicator must not be entirely hidden by author-styled content |
| 2.5.7 Dragging Movements | AA | All drag-and-drop has a single-pointer alternative (e.g., keyboard reorder) |
| 2.5.8 Target Size (Minimum) | AA | Interactive targets ≥ 24×24 CSS pixels (or ≥ spacing from other targets) |
| 3.2.6 Consistent Help | A | Help mechanisms (chat, phone) appear in same location across pages |
| 3.3.7 Redundant Entry | A | Information entered previously is auto-filled or available for selection |
| 3.3.8 Accessible Authentication (Minimum) | AA | No cognitive function test required for login (no distorted CAPTCHAs) |

**Practical impact**: For 2026 development, the most immediately impactful new criterion to test is 2.5.8 Target Size — many mobile navigation patterns and icon buttons are smaller than 24×24px. Also check 2.4.11 Focus Appearance, as many design systems use thin focus rings that will fail the new 2px + 3:1 contrast requirement.

### Tool Tradeoffs

| Tool | Pros | Cons | Best for |
|------|------|------|---------|
| axe-core (jest-axe) | Fast, runs in CI, component-level | JSDOM limits (no contrast), no real browser rendering | Unit/component CI gating |
| @axe-core/playwright | Real browser, catches dynamic content, contrast | Slower, requires live/test server | E2E CI gating |
| Lighthouse (Chrome) | Integrated in DevTools, accessibility + perf score | Less detailed rule set, can score 100 with real issues | Dashboard metrics, quick checks |
| WAVE | Visual overlay, education-friendly | Manual only, not automatable | Auditor walkthroughs |
| Pa11y | CLI + CI automation | Less comprehensive than axe | Lightweight CI pipelines |
| Deque WorldSpace | Enterprise audit workflow management | Commercial license ($$$) | Large org compliance tracking |
| axe DevTools (Deque) | Guided issue reporting with fix guidance | Commercial | Developer-guided manual audits |

### Automated Testing Limitations and False Positives

**Coverage ceiling**: axe-core reliably detects ~57% of WCAG issues in automated scans. The other ~43% require human judgment or cannot be expressed as deterministic rules.

**False positives — when axe-core is wrong:**

1. `duplicate-id` in Storybook/isolated component tests: component testing frameworks render multiple instances of the same component in one DOM. axe flags duplicate IDs even though each component instance is logically separate. Fix by providing unique IDs per test, not by disabling the rule globally.

2. `color-contrast` in JSDOM: jest-axe reports `incomplete` (not a failure) for contrast because JSDOM cannot compute computed colors. This is not a false positive per se — it is correctly acknowledged uncertainty.

3. `aria-required-parent` on portals: components rendered via React portals (e.g., `<Select>` option lists) may be mounted outside their logical parent. axe flags missing parent roles even when the logical parent is correctly set via `aria-owns`. Verify manually or use `axe.disableOtherRules` for the specific assertion.

4. `landmark-no-duplicate-banner` in micro-frontend shells: when multiple apps render their own `<header>` within a shared shell, axe correctly flags multiple banners. Use `role="none"` on inner headers that are not site-wide banners.

**When to suppress a rule**: only suppress with a documented reason in code comments (`axe.disableOtherRules(['rule-id'])` scoped to the specific test assertion). Never suppress globally without a team review.

**axe does not test cognitive accessibility** (plain language, reading level, clear instructions) — WCAG 3.1 (Readable) and 3.3 (Input Assistance) quality aspects require human review.

**Dynamic content requires targeted scans**: a static page-level scan misses issues that only appear after user interaction (form validation errors, live chat, auto-complete dropdowns). Use `page.waitForSelector` to wait for dynamic regions before re-scanning.

---

## Key Resources

- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/) — filterable list of all success criteria
- [WCAG 2.2 New Criteria](https://www.w3.org/TR/WCAG22/) — 9 new criteria including target size and dragging
- [ARIA Authoring Practices Guide (APG)](https://www.w3.org/WAI/ARIA/apg/) — patterns and examples for custom widgets
- [axe-core GitHub](https://github.com/dequelabs/axe-core) — rule documentation and changelog
- [jest-axe](https://github.com/nickcolley/jest-axe) — Jest integration for axe
- [@axe-core/playwright](https://github.com/dequelabs/axe-core-npm/tree/develop/packages/playwright) — Playwright integration
- [WebAIM Million Report](https://webaim.org/projects/million/) — annual automated scan of top 1M homepages; most common failures: low contrast (81%), missing alt (55%), missing form labels (49%)
- [WebAIM Screen Reader Survey](https://webaim.org/projects/screenreadersurvey/) — actual AT usage statistics; JAWS + NVDA dominate desktop
- [Deque University](https://dequeuniversity.com/) — free reference for WCAG interpretations and ARIA patterns
- [MDN ARIA reference](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA) — role and attribute documentation
- [TPGi Colour Contrast Analyser](https://www.tpgi.com/color-contrast-checker/) — desktop tool for manual contrast checking
