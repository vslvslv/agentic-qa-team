# Accessibility Testing (a11y) — QA Methodology Guide
<!-- lang: TypeScript | topic: accessibility | iteration: 30 | score: 100/100 | date: 2026-05-03 -->
<!-- sources: training knowledge + axe-core GitHub README (WebFetch) + navable MCP README (WebFetch) + Aura AI scanner (WebFetch) + qa-methodology-refine 10-iteration run 2026-05-03 -->

## ISTQB CTFL 4.0 Terminology for Accessibility Testing

ISTQB CTFL 4.0 (released 2023) treats accessibility testing as a specialized form of **usability testing** within the **quality characteristics** framework (ISO/IEC 25010:2023). Key terms QA teams should know:

| ISTQB / ISO Term | Definition | Accessibility relevance |
|---|---|---|
| **Accessibility** | Degree to which a product can be used by people with the widest range of characteristics (ISO/IEC 25010) | The quality characteristic being tested; POUR covers all four subdimensions |
| **Functional suitability** | Degree to which functions meet stated needs | Includes the ability of AT users to complete all functions keyboard-only |
| **Conformance testing** | Testing to check compliance with a standard | WCAG conformance testing; produces Accessibility Conformance Report (ACR/VPAT) |
| **Usability testing** | Testing to assess ease of use | AT usability testing: screen reader, switch access, voice control user sessions |
| **Non-functional testing** | Testing of non-behavioral quality characteristics | Accessibility is a non-functional quality attribute alongside performance |
| **Experience-based testing** | Testing derived from tester knowledge | Manual AT testing (NVDA, VoiceOver) is experience-based; axe is specification-based |
| **Static testing** | Testing without executing code | Accessibility code review, HTML validation, checking ARIA attribute correctness in source |
| **Confirmation testing** | Re-testing after a defect fix | After an axe violation is fixed: re-run axe scan + manual verification |
| **Defect density** | Number of defects per unit | WebAIM Million (2024): average 56.8 detected a11y errors per homepage |

**ISTQB CTFL 4.0 Quality Characteristics (ISO 25010:2023) mapping**:
- Accessibility testing primarily targets the **Usability > Accessibility** sub-characteristic
- It also contributes to **Compatibility** (works with AT software), **Reliability** (AT users can complete critical flows), and **Maintainability** (semantic HTML is easier to test and modify)

**Exit criteria for accessibility testing** (apply the ISTQB definition):
- All WCAG 2.1 AA automated violations = 0 (axe-core CI gate passing)
- Keyboard navigation audit complete with no keyboard traps or missing focus indicators
- Screen reader review completed for all new interactive patterns
- All known manual-only issues logged in the defect tracker with severity and WCAG SC reference



WCAG 2.1 is organized around four foundational principles known as POUR. Every success criterion maps to one of these four categories. Understanding POUR before writing tests helps QA engineers know **why** a given test exists and what class of user it protects.

**Why POUR matters for testing**: Tests that merely pass "the linter" without understanding POUR miss the user impact. Perceivable tests protect blind/deaf users; Operable tests protect motor-impaired and keyboard-only users; Understandable tests protect cognitive-impaired and non-native language users; Robust tests protect all users of assistive technology now and in the future.

### Perceivable
Information and UI components must be presentable to users in ways they can perceive. Users cannot interact with content they cannot detect. This addresses people who are blind, deaf, or have cognitive differences in processing visual/audio information.
- **1.1.1 Non-text Content (A)**: Provide text alternatives (`alt`, `aria-label`, `aria-labelledby`) for all non-text content — decorative images get `alt=""`
- **1.2.x Captions/Audio Description (A/AA)**: Offer captions for video, transcripts for audio; critical for deaf users
- **1.3.1 Info and Relationships (A)**: Semantic HTML (`<h1>`–`<h6>`, `<table>`, `<ul>`) conveys structure to screen readers — do not use `<div>` for structure that has a semantic equivalent
- **1.3.3 Sensory Characteristics (A)**: Do not rely solely on color, shape, or position to convey meaning (e.g., "click the red button" fails)
- **1.3.4 Orientation (AA)**: Content must not be restricted to a single screen orientation (portrait/landscape) unless the restriction is essential
- **1.3.5 Identify Input Purpose (AA)**: Form fields collecting personal data must expose their purpose via the `autocomplete` attribute — enables browser auto-fill and reduces burden for motor-impaired users
- **1.4.3 Contrast Minimum (AA)**: 4.5:1 for normal text, 3:1 for large text
- **1.4.4 Resize Text (AA)**: Text must resize to 200% without loss of content or functionality
- **1.4.10 Reflow (AA)**: Content must reflow to a single column at 320px CSS width without horizontal scrolling — ensures readability at 400% zoom
- **1.4.11 Non-text Contrast (AA)**: UI component boundaries and graphical objects must meet 3:1 contrast against adjacent colors
- **1.4.12 Text Spacing (AA)**: Content must not be lost when users override: line-height ≥ 1.5× font size, paragraph spacing ≥ 2× font size, letter spacing ≥ 0.12× font size, word spacing ≥ 0.16× font size
- **1.4.13 Content on Hover or Focus (AA)**: Tooltip/popover content triggered by hover or focus must be dismissible (Escape), hoverable (pointer can move to the content without it disappearing), and persistent (does not disappear until dismissed or trigger loses focus)

### Operable
UI components and navigation must be operable. If a user cannot operate the interface, they cannot use it. This addresses motor disabilities and users who rely on keyboard or switch access devices.
- **2.1.1 Keyboard (A)**: All functionality must be accessible via keyboard alone — no mouse-only interactions
- **2.1.2 No Keyboard Trap (A)**: Focus must not get stuck inside a component unless it is a dialog that intentionally traps focus (and provides a dismiss mechanism)
- **2.4.3 Focus Order (A)**: Tab order must be logical and match visual reading order
- **2.4.7 Focus Visible (AA)**: Keyboard focus indicator must be visible — `outline: none` without replacement is a failure
- **2.5.1 Pointer Gestures (A)**: All functionality using multi-point or path-based gestures (pinch-zoom, swipe-to-dismiss, draw gesture) must have a single-pointer alternative — critical for switch access and one-finger mobile users
- **2.5.3 Label in Name (A)**: For UI components with visible text labels, the accessible name must contain the visible text — voice control users say the visible label to activate controls; if the accessible name differs, voice control fails
- **2.5.4 Motion Actuation (A)**: Functionality triggered by device motion (shake to undo, tilt to scroll) must have a UI alternative and must be able to be disabled — prevents accidental activation for users with tremors

### Understandable
Information and the operation of the UI must be understandable. This addresses users with cognitive disabilities, learning differences, and non-native language users.
- **3.1.1 Language of Page (A)**: `lang` attribute on `<html>` — screen readers use this to select the correct pronunciation engine
- **3.2.1 On Focus (A)**: Receiving focus must not trigger unexpected context changes (no auto-submit on focus)
- **3.3.1 Error Identification (A)**: Form errors must be described in text — "This field is required" not just a red border
- **3.3.2 Labels or Instructions (A)**: All form inputs must have visible labels (not just placeholder text, which disappears on input)
- **3.3.4 Error Prevention (AA)**: For legal, financial, or data submission: provide the ability to check, correct, and confirm data before submission — prevents catastrophic errors for users with cognitive or motor disabilities

### Robust
Content must be robust enough to be interpreted by a wide variety of user agents, including current and future assistive technologies. This is the technical foundation that enables the other three principles to work.
- **4.1.1 Parsing (A)**: Valid HTML — unique IDs, proper nesting, complete start/end tags. Malformed markup causes assistive technologies to misinterpret structure.
- **4.1.2 Name, Role, Value (A)**: All UI components must have a programmatic name, role, and state (via HTML semantics or ARIA). This is the most commonly failed criterion.
- **4.1.3 Status Messages (AA)**: Dynamically injected content (alerts, progress updates) must be announced without moving focus — use `aria-live="polite"` or `role="alert"` appropriately

---

## When to Use

Accessibility testing applies to any web application serving users. WCAG 2.1 AA is the de facto international legal standard.

**Legal requirement triggers:**

| Situation | Legal requirement | Standard |
|-----------|-------------------|----------|
| US federal agency or contractor | Yes — Section 508 | WCAG 2.0 AA (moving to 2.1) |
| EU public sector website (EU Directive 2016/2102) | Yes | EN 301 549 / WCAG 2.1 AA |
| **EU private sector (EAA — European Accessibility Act)** | **Yes — deadline June 28, 2025** | **EN 301 549 / WCAG 2.2 AA** |
| Private US business (ADA Title III) | Yes if challenged — increasingly enforced | WCAG 2.1 AA by case law |
| Canadian federal / Ontario public sector (AODA) | Yes | WCAG 2.0 AA → 2.1 AA |
| UK public sector (PSBAR) | Yes | WCAG 2.1 AA |
| Private business, global SaaS | No hard mandate, but litigation risk | WCAG 2.1 AA recommended |

| Layer | Tool | When |
|-------|------|------|
| Unit / Component | jest-axe + @testing-library | On every PR, in CI |
| Integration / E2E | Playwright + @axe-core/playwright | On every PR, in CI |
| Manual audit | Screen reader + keyboard | Per sprint, before major releases |
| Visual | Color contrast checker | Design review + automated scan |

**Recommended CI pipeline configuration** (GitHub Actions example):

```yaml
# .github/workflows/accessibility.yml
# Accessibility gates for every PR:
#   1. Jest unit tests (includes jest-axe component tests) — fast, runs first
#   2. Playwright a11y tests — runs against dev/preview environment
name: Accessibility CI

on: [push, pull_request]

jobs:
  a11y-unit:
    name: Component accessibility (jest-axe)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npm test -- --testPathPattern="\.a11y\." --coverage=false

  a11y-e2e:
    name: Full-page accessibility (Playwright + axe)
    runs-on: ubuntu-latest
    needs: a11y-unit        # Only run E2E if unit tests pass
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npm run build                            # Build the app
      - run: npx playwright test e2e/accessibility/  # Run only a11y specs
        env:
          BASE_URL: http://localhost:3000
      - uses: actions/upload-artifact@v4              # Upload report on failure
        if: failure()
        with:
          name: playwright-a11y-report
          path: playwright-report/
```

---

## Patterns

### Why axe-core Is the Standard Rule Engine

axe-core is the open-source accessibility rule engine powering jest-axe, `@axe-core/playwright`, the Deque browser extensions, and Lighthouse. It has become the de facto standard because:

- **Coverage**: Deque research shows axe-core detects ~57% of WCAG issues automatically — the highest coverage of any open-source engine
- **Zero false positives by design**: Rules only flag definitive failures. Uncertain cases return as `incomplete` rather than violations — this keeps CI pipelines trustworthy
- **Wide adoption**: Used by Microsoft, Google, GitHub, and most major design systems, meaning axe's rule interpretations are well-scrutinized
- **TypeScript support**: Ships with `axe.d.ts` type definitions; jest-axe and `@axe-core/playwright` are TypeScript-native
- **Standard tags**: Rules tagged by WCAG version and level (`wcag2a`, `wcag2aa`, `wcag21aa`, `wcag22aa`, `best-practice`), enabling precise scope control

**axe-core coverage ceiling**: The ~57% figure means automated testing is necessary but not sufficient. Building a CI gate on axe alone creates a false sense of compliance.

---

### jest-axe: Component-Level A11y Testing

jest-axe integrates axe-core into Jest, enabling accessibility checks at the component level. It catches structural issues (missing labels, invalid ARIA) as fast unit tests before code reaches a real browser.

```typescript
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
      <button type="button" aria-label="Submit form">Submit</button>
    );
    const results = await axeConfig(container);
    expect(results).toHaveNoViolations();
  });

  it('icon button requires accessible label', async () => {
    const { container } = render(
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
        <svg><use href="#icon-close" /></svg>
      </button>
    );
    const results = await axeConfig(container);
    // Document the expected failure mode for reviewers
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

### Playwright + axe: Full-Page A11y Audit

`@axe-core/playwright` runs axe-core against live pages in a real browser, catching issues JSDOM-based tests miss (color contrast, complex focus states, iframe content).

```typescript
// File: e2e/accessibility/full-page.a11y.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Homepage accessibility', () => {
  test('no WCAG 2.1 AA violations', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

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

  test('modal dialog should be accessible in context', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-testid="open-modal"]');
    await page.waitForSelector('[role="dialog"]');

    // Audit only the modal region to isolate failures
    const results = await new AxeBuilder({ page })
      .include('[role="dialog"]')
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();

    expect(results.violations).toEqual([]);
  });
});
```

### Reusable axe Fixture for Playwright

```typescript
// File: e2e/fixtures/axe-fixture.ts
// Extend Playwright base test with a reusable checkA11y helper
import { test as base } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

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

### Form Validation with aria-describedby

Linking error messages to their form inputs via `aria-describedby` is one of the most important WCAG patterns. Screen reader users need errors announced when they interact with a field — not just visible text placed nearby.

```typescript
// File: src/components/FormField/FormField.tsx
import React from 'react';

interface FormFieldProps {
  id: string;
  label: string;
  type?: string;
  error?: string;
  required?: boolean;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
}

export const FormField: React.FC<FormFieldProps> = ({
  id,
  label,
  type = 'text',
  error,
  required = false,
  value,
  onChange,
}) => {
  const errorId = `${id}-error`;
  return (
    <div>
      <label htmlFor={id}>
        {label}
        {required && <span aria-hidden="true"> *</span>}
        {required && <span className="sr-only"> (required)</span>}
      </label>
      <input
        id={id}
        type={type}
        value={value}
        onChange={onChange}
        required={required}
        aria-invalid={error ? 'true' : undefined}
        aria-describedby={error ? errorId : undefined}
      />
      {error && (
        // role="alert" announces immediately when injected; use sparingly
        <p id={errorId} role="alert" aria-live="assertive">
          {error}
        </p>
      )}
    </div>
  );
};
```

```typescript
// File: src/components/FormField/FormField.a11y.test.tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import { FormField } from './FormField';

expect.extend(toHaveNoViolations);

describe('FormField accessibility', () => {
  it('renders a valid form field with no violations', async () => {
    const { container } = render(
      <FormField id="email" label="Email address" value="" onChange={() => {}} />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('error state links message to input via aria-describedby', async () => {
    const { container } = render(
      <FormField
        id="email"
        label="Email address"
        value=""
        onChange={() => {}}
        error="Enter a valid email address"
      />
    );
    const input = screen.getByLabelText('Email address');
    expect(input).toHaveAttribute('aria-invalid', 'true');
    expect(input).toHaveAttribute('aria-describedby', 'email-error');
    expect(screen.getByRole('alert')).toHaveTextContent('Enter a valid email address');
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});
```

### ARIA Landmarks

Landmarks allow screen reader users to jump directly to major page regions. Every page should have at least `banner`, `main`, and `contentinfo`.

```typescript
// File: src/layouts/AppLayout.tsx
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
        <nav aria-label={navigationLabel}>{/* Primary navigation links */}</nav>
      </header>
      {/* role="main" is implicit on <main> */}
      <main id="main-content" tabIndex={-1}>
        {children}
      </main>
      {/* role="contentinfo" is implicit on <footer> at top level */}
      <footer>{/* Copyright, legal links */}</footer>
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

Every interactive element must be reachable and operable via keyboard alone.

```typescript
// File: e2e/accessibility/keyboard-nav.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Keyboard navigation', () => {
  test('skip link is first focusable element and jumps to main', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Tab');
    const focused = await page.evaluate(() => document.activeElement?.textContent);
    expect(focused).toContain('Skip to main content');

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

axe-core checks color contrast only in a real browser — JSDOM cannot compute computed styles.

```typescript
// File: e2e/accessibility/contrast.a11y.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Color contrast requirements', () => {
  test('all text on homepage meets WCAG 2.1 AA contrast (4.5:1 / 3:1)', async ({ page }) => {
    await page.goto('/');
    // Ensure fonts and styles fully load before scanning
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
            `  Nodes affected: ${v.nodes.length}`
          );
        });
      });
    }
    expect(results.violations).toEqual([]);
  });
});
```

**Common contrast failures:**
- Gray placeholder text on white backgrounds (often below 4.5:1)
- Disabled button states using light gray text without sufficient contrast
- Focus indicator outlines without sufficient contrast against adjacent background
- Icon-only controls with low-contrast icon colors (1.4.11 Non-text Contrast)

### Live Regions and Dynamic Content

`aria-live` regions announce dynamically injected content to screen reader users without moving focus. Essential for toast notifications, form validation errors, and loading states.

```typescript
// File: src/components/Toast/Toast.a11y.test.tsx
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
      {/* Keep region in DOM when empty — inserting after content causes some
          screen readers to miss the announcement entirely */}
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

### Disclosure Widget: aria-expanded + aria-controls

`aria-expanded` communicates the open/closed state of interactive disclosure patterns (accordions, dropdowns, nav menus). This is required for 4.1.2 Name, Role, Value and is one of the most commonly missing ARIA attributes in custom components.

```typescript
// File: src/components/Accordion/Accordion.tsx
import React, { useState } from 'react';

interface AccordionItemProps {
  id: string;
  title: string;
  children: React.ReactNode;
}

export const AccordionItem: React.FC<AccordionItemProps> = ({ id, title, children }) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const panelId = `${id}-panel`;
  const buttonId = `${id}-button`;

  return (
    <div>
      <h3>
        <button
          id={buttonId}
          type="button"
          aria-expanded={isExpanded}
          aria-controls={panelId}
          onClick={() => setIsExpanded((prev) => !prev)}
        >
          {title}
          {/* Visual indicator — hidden from screen readers since aria-expanded carries the state */}
          <span aria-hidden="true">{isExpanded ? '▲' : '▼'}</span>
        </button>
      </h3>
      <div
        id={panelId}
        role="region"
        aria-labelledby={buttonId}
        hidden={!isExpanded}
      >
        {children}
      </div>
    </div>
  );
};
```

```typescript
// File: src/components/Accordion/Accordion.a11y.test.tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import { AccordionItem } from './Accordion';

expect.extend(toHaveNoViolations);

describe('AccordionItem accessibility', () => {
  it('has no axe violations in collapsed state', async () => {
    const { container } = render(
      <AccordionItem id="faq-1" title="What is WCAG?">
        <p>WCAG stands for Web Content Accessibility Guidelines.</p>
      </AccordionItem>
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('aria-expanded is false when collapsed, true when expanded', async () => {
    const user = userEvent.setup();
    render(
      <AccordionItem id="faq-1" title="What is WCAG?">
        <p>Content</p>
      </AccordionItem>
    );
    const button = screen.getByRole('button', { name: /What is WCAG/ });
    expect(button).toHaveAttribute('aria-expanded', 'false');

    await user.click(button);
    expect(button).toHaveAttribute('aria-expanded', 'true');
  });
});
```

### Accessible Modal Dialog Pattern  [community]

Modal dialogs are the most commonly implemented ARIA pattern — and the most commonly broken one in production. The requirements are: `role="dialog"`, `aria-modal="true"`, `aria-labelledby` pointing to the dialog heading, focus trapped inside, focus returned to the trigger on close, and background content inerted.

**Why this is hard:** Three separate mechanisms must work simultaneously: ARIA semantics (role, label), focus management (trap + return), and background inertness (prevent screen reader virtual cursor from wandering). Most component library dialogs handle ARIA but fail on `inert` for VoiceOver.

```typescript
// File: src/components/Modal/Modal.tsx
// Accessible modal dialog: role="dialog", focus trap, inert background, return focus on close.
import React, { useEffect, useRef, useCallback } from 'react';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  titleId: string;         // ID of the heading element inside the modal
  children: React.ReactNode;
}

const FOCUSABLE = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(', ');

export const Modal: React.FC<ModalProps> = ({ isOpen, onClose, titleId, children }) => {
  const dialogRef = useRef<HTMLDivElement>(null);
  // Remember which element opened the dialog so focus can return on close
  const triggerRef = useRef<Element | null>(null);

  useEffect(() => {
    if (!isOpen) return;

    // Save the element that opened the dialog
    triggerRef.current = document.activeElement;

    // Move focus into the dialog — first focusable element or dialog itself
    const firstFocusable = dialogRef.current?.querySelector<HTMLElement>(FOCUSABLE);
    (firstFocusable ?? dialogRef.current)?.focus();

    // Inert all top-level siblings to prevent screen reader virtual cursor escape
    const siblings = Array.from(document.body.children).filter((el) => el !== dialogRef.current?.closest('[data-modal-root]'));
    siblings.forEach((el) => el.setAttribute('inert', ''));

    return () => {
      // Remove inert and return focus to trigger
      siblings.forEach((el) => el.removeAttribute('inert'));
      (triggerRef.current as HTMLElement)?.focus();
    };
  }, [isOpen]);

  // Focus trap: keep Tab/Shift+Tab inside the dialog
  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLDivElement>) => {
      if (e.key === 'Escape') { onClose(); return; }
      if (e.key !== 'Tab') return;

      const focusables = Array.from(
        dialogRef.current?.querySelectorAll<HTMLElement>(FOCUSABLE) ?? []
      );
      if (focusables.length === 0) return;

      const first = focusables[0];
      const last = focusables[focusables.length - 1];

      if (e.shiftKey) {
        if (document.activeElement === first) { e.preventDefault(); last.focus(); }
      } else {
        if (document.activeElement === last) { e.preventDefault(); first.focus(); }
      }
    },
    [onClose]
  );

  if (!isOpen) return null;

  return (
    <div data-modal-root>
      {/* Backdrop */}
      <div aria-hidden="true" onClick={onClose} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)' }} />
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
        onKeyDown={handleKeyDown}
        style={{ position: 'fixed', top: '50%', left: '50%', transform: 'translate(-50%,-50%)', background: 'white', padding: '1.5rem', zIndex: 100 }}
      >
        {children}
        <button type="button" onClick={onClose} aria-label="Close dialog">
          Close
        </button>
      </div>
    </div>
  );
};
```

```typescript
// File: src/components/Modal/Modal.a11y.test.tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import { Modal } from './Modal';

expect.extend(toHaveNoViolations);

describe('Modal accessibility', () => {
  it('open modal has no axe violations', async () => {
    const { container } = render(
      <Modal isOpen onClose={() => {}} titleId="modal-title">
        <h2 id="modal-title">Confirm Action</h2>
        <p>Are you sure you want to delete this item?</p>
        <button type="button">Confirm</button>
      </Modal>
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('dialog has role="dialog" and aria-labelledby pointing to heading', () => {
    render(
      <Modal isOpen onClose={() => {}} titleId="modal-title">
        <h2 id="modal-title">Delete Item</h2>
      </Modal>
    );
    const dialog = screen.getByRole('dialog');
    expect(dialog).toHaveAttribute('aria-labelledby', 'modal-title');
  });

  it('Escape key closes the dialog', async () => {
    const user = userEvent.setup();
    const onClose = jest.fn();
    render(
      <Modal isOpen onClose={onClose} titleId="modal-title">
        <h2 id="modal-title">Delete Item</h2>
      </Modal>
    );
    await user.keyboard('{Escape}');
    expect(onClose).toHaveBeenCalledTimes(1);
  });
});
```

### Accessible Data Tables

WCAG 1.3.1 (Info and Relationships) and 1.3.2 (Meaningful Sequence) require that data tables communicate the relationship between header and data cells to screen readers. Simple tables need `<th scope="col">` or `<th scope="row">`; complex tables with multi-level headers need `id`/`headers` associations. Screen readers announce the column and row header for each data cell when these associations are present.

**Why test this:** Teams frequently use `<div>` grids or visually styled `<table>` elements without header associations. The content looks correct visually but is meaningless to screen reader users who can only hear one cell at a time without context.

```typescript
// File: src/components/DataTable/DataTable.tsx
import React from 'react';

interface Column<T> {
  key: keyof T;
  header: string;
  scope?: 'col' | 'colgroup';
}

interface DataTableProps<T extends Record<string, unknown>> {
  caption: string;            // Required: WCAG 1.3.1 — caption provides table context
  columns: Column<T>[];
  rows: T[];
  rowHeaderKey?: keyof T;     // Optional: column whose cells act as row headers
}

export function DataTable<T extends Record<string, unknown>>({
  caption,
  columns,
  rows,
  rowHeaderKey,
}: DataTableProps<T>): JSX.Element {
  return (
    <table>
      {/* caption is the first focusable element for screen readers navigating tables */}
      <caption>{caption}</caption>
      <thead>
        <tr>
          {columns.map((col) => (
            <th key={String(col.key)} scope={col.scope ?? 'col'}>
              {col.header}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {rows.map((row, rowIndex) => (
          <tr key={rowIndex}>
            {columns.map((col) => {
              const value = String(row[col.key] ?? '');
              // Row header cell uses <th scope="row"> instead of <td>
              if (col.key === rowHeaderKey) {
                return (
                  <th key={String(col.key)} scope="row">
                    {value}
                  </th>
                );
              }
              return <td key={String(col.key)}>{value}</td>;
            })}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

```typescript
// File: src/components/DataTable/DataTable.a11y.test.tsx
import React from 'react';
import { render, screen, within } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import { DataTable } from './DataTable';

expect.extend(toHaveNoViolations);

const testColumns = [
  { key: 'name' as const, header: 'Employee Name' },
  { key: 'dept' as const, header: 'Department' },
  { key: 'role' as const, header: 'Role' },
];
const testRows = [
  { name: 'Alice Chen', dept: 'Engineering', role: 'Senior Engineer' },
  { name: 'Bob Smith', dept: 'Design', role: 'UX Designer' },
];

describe('DataTable accessibility', () => {
  it('has no axe violations', async () => {
    const { container } = render(
      <DataTable
        caption="Employee Directory"
        columns={testColumns}
        rows={testRows}
        rowHeaderKey="name"
      />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('caption provides table context', () => {
    render(
      <DataTable caption="Employee Directory" columns={testColumns} rows={testRows} />
    );
    // caption must be present and correct for screen reader table navigation
    expect(screen.getByRole('table', { name: 'Employee Directory' })).toBeInTheDocument();
  });

  it('column headers have scope="col"', () => {
    const { container } = render(
      <DataTable caption="Test" columns={testColumns} rows={testRows} />
    );
    const headers = container.querySelectorAll('th[scope="col"]');
    expect(headers).toHaveLength(testColumns.length);
  });
});
```

**Setup dependencies** (`package.json`):
```json
{
  "devDependencies": {
    "jest-axe": "^9.0.0",
    "@axe-core/playwright": "^4.11.0",
    "axe-core": "^4.11.4",
    "@testing-library/react": "^16.0.0",
    "@testing-library/jest-dom": "^6.0.0",
    "@testing-library/user-event": "^14.0.0"
  }
}
```

> **Version pinning note**: axe-core 4.11.x (released Q1–Q2 2026) added new rules including `aria-dialog-name`, `aria-tooltip-name`, `scrollable-region-focusable`, and improved `color-contrast-enhanced` (WCAG 2.2 1.4.11). When upgrading axe-core across jest-axe and @axe-core/playwright, update both packages simultaneously to the same underlying axe-core transitive version — version skew between unit and E2E layers produces false discrepancies.

### Accessible Carousel / Auto-Rotating Content  [community]

Auto-rotating carousels are one of the most commonly broken interactive components in production. WCAG 2.2.2 (Pause/Stop/Hide, Level A) requires that auto-playing content can be paused; WCAG 2.1.1 requires carousel navigation is keyboard-accessible; and WCAG 4.1.3 requires that the active slide position is announced to screen readers. Most carousel libraries implement some but not all of these.

**Why this fails so often:** Teams implement auto-rotation and keyboard arrow-key navigation but forget: (1) `aria-live` region for slide change announcements, (2) `aria-roledescription="carousel"` and `aria-label` for the widget, (3) `prefers-reduced-motion` disabling auto-rotation, and (4) a pause button as the first interactive element. Passing `<img>` alt text is necessary but not sufficient — the structural carousel semantics are the real challenge.

```typescript
// File: src/components/Carousel/Carousel.tsx
// WCAG-compliant carousel with: pause button, aria-live announcements,
// keyboard navigation, prefers-reduced-motion support.
import React, { useState, useEffect, useCallback, useRef } from 'react';

interface CarouselSlide {
  id: string;
  title: string;
  description: string;
  imageUrl: string;
  imageAlt: string;
}

interface CarouselProps {
  slides: CarouselSlide[];
  label: string;            // aria-label for the carousel landmark
  autoPlayInterval?: number; // 0 or undefined = no auto-play
}

export const Carousel: React.FC<CarouselProps> = ({
  slides,
  label,
  autoPlayInterval = 5000,
}) => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isPaused, setIsPaused] = useState(false);
  const [reducedMotion, setReducedMotion] = useState(false);
  const liveRegionRef = useRef<HTMLDivElement>(null);

  // Detect prefers-reduced-motion at mount
  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    setReducedMotion(mq.matches);
    const handler = (e: MediaQueryListEvent) => setReducedMotion(e.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, []);

  const goTo = useCallback(
    (index: number) => {
      const newIndex = (index + slides.length) % slides.length;
      setCurrentIndex(newIndex);
      // Announce the new slide to screen reader users
      if (liveRegionRef.current) {
        liveRegionRef.current.textContent = `Slide ${newIndex + 1} of ${slides.length}: ${slides[newIndex].title}`;
      }
    },
    [slides]
  );

  // Auto-rotation: disabled if paused OR prefers-reduced-motion
  useEffect(() => {
    if (!autoPlayInterval || isPaused || reducedMotion) return;
    const timer = setInterval(() => goTo(currentIndex + 1), autoPlayInterval);
    return () => clearInterval(timer);
  }, [autoPlayInterval, currentIndex, goTo, isPaused, reducedMotion]);

  const slide = slides[currentIndex];

  return (
    <section
      aria-roledescription="carousel"
      aria-label={label}
    >
      {/* Pause button MUST be the first interactive element — WCAG 2.2.2 */}
      {autoPlayInterval > 0 && !reducedMotion && (
        <button
          type="button"
          aria-label={isPaused ? 'Resume auto-rotation' : 'Pause auto-rotation'}
          onClick={() => setIsPaused((p) => !p)}
          aria-pressed={isPaused}
        >
          {isPaused ? 'Play' : 'Pause'}
        </button>
      )}

      {/* Slide content */}
      <div
        aria-roledescription="slide"
        aria-label={`Slide ${currentIndex + 1} of ${slides.length}`}
      >
        <img src={slide.imageUrl} alt={slide.imageAlt} />
        <h3>{slide.title}</h3>
        <p>{slide.description}</p>
      </div>

      {/* Navigation controls */}
      <button
        type="button"
        aria-label="Previous slide"
        onClick={() => goTo(currentIndex - 1)}
      >
        ‹
      </button>
      <button
        type="button"
        aria-label="Next slide"
        onClick={() => goTo(currentIndex + 1)}
      >
        ›
      </button>

      {/* Slide position indicators */}
      <div role="group" aria-label={`Slide ${currentIndex + 1} of ${slides.length}`}>
        {slides.map((s, i) => (
          <button
            key={s.id}
            type="button"
            aria-label={`Go to slide ${i + 1}: ${s.title}`}
            aria-current={i === currentIndex ? 'true' : undefined}
            onClick={() => goTo(i)}
          />
        ))}
      </div>

      {/* Screen reader live region — announces slide changes */}
      {/* Must be in DOM at page load, never conditionally rendered */}
      <div
        ref={liveRegionRef}
        aria-live="polite"
        aria-atomic="true"
        className="sr-only"
      />
    </section>
  );
};
```

```typescript
// File: src/components/Carousel/Carousel.a11y.test.tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import { Carousel } from './Carousel';

expect.extend(toHaveNoViolations);

const testSlides = [
  { id: '1', title: 'First slide', description: 'Content 1', imageUrl: '/img1.jpg', imageAlt: 'Landscape photo' },
  { id: '2', title: 'Second slide', description: 'Content 2', imageUrl: '/img2.jpg', imageAlt: 'Portrait photo' },
  { id: '3', title: 'Third slide', description: 'Content 3', imageUrl: '/img3.jpg', imageAlt: 'Abstract art' },
];

describe('Carousel accessibility', () => {
  it('has no axe violations in initial state', async () => {
    const { container } = render(
      <Carousel slides={testSlides} label="Featured content" autoPlayInterval={0} />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('carousel landmark has aria-roledescription="carousel"', () => {
    render(<Carousel slides={testSlides} label="Featured content" autoPlayInterval={0} />);
    const carousel = screen.getByRole('region', { name: 'Featured content' });
    expect(carousel).toHaveAttribute('aria-roledescription', 'carousel');
  });

  it('pause button is present and accessible when auto-play is on', async () => {
    const { container } = render(
      <Carousel slides={testSlides} label="Featured content" autoPlayInterval={3000} />
    );
    const pauseButton = screen.getByRole('button', { name: /pause auto-rotation/i });
    expect(pauseButton).toBeInTheDocument();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('previous/next navigation buttons are keyboard accessible', async () => {
    const user = userEvent.setup();
    render(<Carousel slides={testSlides} label="Featured content" autoPlayInterval={0} />);
    const nextButton = screen.getByRole('button', { name: /next slide/i });
    nextButton.focus();
    await user.keyboard('{Enter}');
    // After pressing next, live region should announce slide 2
    expect(screen.getByRole('region', { name: /featured content/i })).toBeInTheDocument();
  });
});
```



In single-page applications using React Router, Next.js, or Vue Router, client-side navigation does not move browser focus. Screen reader users stay at the link they clicked, then hear the old page content re-read. This is one of the most common and impactful accessibility failures in modern SPAs.

**Why it fails:** The browser's built-in focus management only runs on full page loads. Client-side routing swaps DOM content silently. Without intervention, focus strands at the navigation trigger while the page context has completely changed.

```typescript
// File: src/hooks/useFocusOnRouteChange.ts
// Custom hook: moves focus to the page's h1 heading after each route change.
// Attach to your router's location/pathname change event.
import { useEffect, useRef } from 'react';
import { useLocation } from 'react-router-dom';

/**
 * After each route change, focus the first <h1> on the new page.
 * The <h1> must have tabIndex={-1} to accept programmatic focus without
 * entering the normal tab sequence.
 *
 * Why <h1>? Screen reader users can then immediately read the page title
 * via their normal reading flow. Focusing <main> is acceptable but h1 is
 * more specific to the content change.
 */
export function useFocusOnRouteChange(): void {
  const { pathname } = useLocation();
  const prevPathname = useRef(pathname);

  useEffect(() => {
    if (prevPathname.current === pathname) return;
    prevPathname.current = pathname;

    // Allow the DOM to settle after the route renders
    const raf = requestAnimationFrame(() => {
      const heading = document.querySelector<HTMLElement>('h1[tabindex="-1"]');
      if (heading) {
        heading.focus({ preventScroll: false });
      } else {
        // Fallback: focus main content region
        const main = document.querySelector<HTMLElement>('main[tabindex="-1"]');
        main?.focus({ preventScroll: false });
      }
    });

    return () => cancelAnimationFrame(raf);
  }, [pathname]);
}
```

```typescript
// File: e2e/accessibility/spa-focus.spec.ts
// Verify focus management after client-side navigation
import { test, expect } from '@playwright/test';

test.describe('SPA focus management', () => {
  test('focus moves to h1 heading after navigating to /about', async ({ page }) => {
    await page.goto('/');
    // Trigger client-side navigation
    await page.click('a[href="/about"]');
    await page.waitForURL('/about');

    // The focused element should be the h1 on the new page
    const focusedTag = await page.evaluate(() => document.activeElement?.tagName?.toLowerCase());
    const focusedText = await page.evaluate(() => document.activeElement?.textContent?.trim());

    expect(focusedTag).toBe('h1');
    expect(focusedText).toBeTruthy();
  });

  test('focus does not strand at clicked link after navigation', async ({ page }) => {
    await page.goto('/');
    await page.click('a[href="/about"]');
    await page.waitForURL('/about');

    const focusedHref = await page.evaluate(
      () => (document.activeElement as HTMLAnchorElement)?.href
    );
    // Focus must not remain on the nav link
    expect(focusedHref).not.toContain('/about');
  });
});
```

### Roving Tabindex for Custom Composite Widgets  [community]

Composite widgets (toolbars, tab lists, radio groups, grids, menus) use the **roving tabindex** pattern: exactly one child has `tabIndex={0}` (the "roving" active item), all others have `tabIndex={-1}`. The user presses Tab to enter the widget and arrow keys to navigate within it. This matches the expected keyboard behavior described in the ARIA Authoring Practices Guide (APG) and is what NVDA Application Mode expects.

**Why this matters:** Teams that give every button in a toolbar `tabIndex={0}` force keyboard users to Tab through every toolbar item before reaching the next focusable region. WCAG 2.4.3 (Focus Order) and 2.1.1 (Keyboard) require that composite widgets are navigable with arrow keys, not just Tab.

```typescript
// File: src/components/Toolbar/Toolbar.tsx
// ARIA toolbar with roving tabindex: Tab moves to the toolbar, arrow keys navigate items.
import React, { useRef, useState, KeyboardEvent } from 'react';

interface ToolbarProps {
  label: string;               // aria-label for the toolbar landmark
  children: React.ReactNode;
}

interface ToolbarButtonProps {
  label: string;
  icon: React.ReactNode;
  onClick: () => void;
}

// Internal context to share tabIndex state (simplified; use useContext in real code)
export const ToolbarButton: React.FC<ToolbarButtonProps & { tabIndex: number; buttonRef?: React.Ref<HTMLButtonElement> }> = ({
  label,
  icon,
  onClick,
  tabIndex,
  buttonRef,
}) => (
  <button
    ref={buttonRef}
    type="button"
    aria-label={label}
    tabIndex={tabIndex}
    onClick={onClick}
    style={{ padding: '0.5rem' }}
  >
    {icon}
  </button>
);

export const Toolbar: React.FC<ToolbarProps & { items: ToolbarButtonProps[] }> = ({ label, items }) => {
  const [activeIndex, setActiveIndex] = useState(0);
  const itemRefs = useRef<(HTMLButtonElement | null)[]>([]);

  const handleKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    const total = items.length;
    let next = activeIndex;

    if (e.key === 'ArrowRight') { next = (activeIndex + 1) % total; }
    else if (e.key === 'ArrowLeft') { next = (activeIndex - 1 + total) % total; }
    else if (e.key === 'Home') { next = 0; }
    else if (e.key === 'End') { next = total - 1; }
    else return;

    e.preventDefault();
    setActiveIndex(next);
    itemRefs.current[next]?.focus();
  };

  return (
    <div
      role="toolbar"
      aria-label={label}
      onKeyDown={handleKeyDown}
      style={{ display: 'flex', gap: '0.25rem' }}
    >
      {items.map((item, i) => (
        <ToolbarButton
          key={item.label}
          {...item}
          tabIndex={i === activeIndex ? 0 : -1}
          buttonRef={(el) => { itemRefs.current[i] = el; }}
        />
      ))}
    </div>
  );
};
```

```typescript
// File: src/components/Toolbar/Toolbar.a11y.test.tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import { Toolbar } from './Toolbar';

expect.extend(toHaveNoViolations);

const testItems = [
  { label: 'Bold', icon: <strong>B</strong>, onClick: jest.fn() },
  { label: 'Italic', icon: <em>I</em>, onClick: jest.fn() },
  { label: 'Underline', icon: <span>U</span>, onClick: jest.fn() },
];

describe('Toolbar accessibility', () => {
  it('has no axe violations', async () => {
    const { container } = render(<Toolbar label="Text formatting" items={testItems} />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('only first item has tabIndex=0, others have tabIndex=-1', () => {
    render(<Toolbar label="Text formatting" items={testItems} />);
    const buttons = screen.getAllByRole('button');
    expect(buttons[0]).toHaveAttribute('tabindex', '0');
    expect(buttons[1]).toHaveAttribute('tabindex', '-1');
    expect(buttons[2]).toHaveAttribute('tabindex', '-1');
  });

  it('ArrowRight moves focus to next toolbar item', async () => {
    const user = userEvent.setup();
    render(<Toolbar label="Text formatting" items={testItems} />);
    const firstButton = screen.getByRole('button', { name: 'Bold' });
    firstButton.focus();
    await user.keyboard('{ArrowRight}');
    expect(screen.getByRole('button', { name: 'Italic' })).toHaveFocus();
  });

  it('ArrowLeft wraps focus to last item from first', async () => {
    const user = userEvent.setup();
    render(<Toolbar label="Text formatting" items={testItems} />);
    screen.getByRole('button', { name: 'Bold' }).focus();
    await user.keyboard('{ArrowLeft}');
    expect(screen.getByRole('button', { name: 'Underline' })).toHaveFocus();
  });
});
```

### Date Picker Accessibility Testing  [community]

Date pickers are one of the most commonly broken ARIA patterns in production. The ARIA Authoring Practices Guide (APG) defines two patterns: a simple date field (native `<input type="date">`) and a widget date picker (calendar grid). Teams frequently reach for the calendar widget but underestimate the complexity. Screen reader testing reveals most calendar implementations are non-functional with AT.

**Key ARIA requirements for a calendar date picker:**
- The calendar button trigger must announce that it opens a dialog (`aria-haspopup="dialog"`)
- The calendar grid uses `role="grid"` with `role="row"` and `role="gridcell"` for cells
- The current date has `aria-current="date"`; selected date has `aria-selected="true"`
- Month navigation buttons must announce the month they navigate to (via `aria-label`)
- Focus trap inside the dialog; Escape closes and returns focus to the trigger
- Arrow keys navigate within the grid; Page Up/Down change months; Enter selects

**The case for `<input type="date">` as the accessible default:**

```typescript
// File: src/components/DateField/DateField.tsx
// Use native <input type="date"> for maximum accessibility with zero custom ARIA.
// Native date inputs are fully keyboard/AT accessible across all browsers since 2019.
// The custom calendar widget below is only needed for design-system visual requirements
// that cannot be met by the native input.
import React from 'react';

interface DateFieldProps {
  id: string;
  label: string;
  value: string;           // ISO 8601 format: "YYYY-MM-DD"
  min?: string;            // Minimum selectable date
  max?: string;            // Maximum selectable date
  onChange: (value: string) => void;
  required?: boolean;
  error?: string;
}

export const DateField: React.FC<DateFieldProps> = ({
  id,
  label,
  value,
  min,
  max,
  onChange,
  required = false,
  error,
}) => {
  const errorId = `${id}-error`;

  return (
    <div>
      <label htmlFor={id}>
        {label}
        {required && <span className="sr-only"> (required)</span>}
        {required && <span aria-hidden="true"> *</span>}
      </label>
      <input
        id={id}
        type="date"              // Native date input: fully accessible, no custom ARIA needed
        value={value}
        min={min}                // Constrains selectable range — announced by AT
        max={max}
        required={required}
        aria-invalid={error ? 'true' : undefined}
        aria-describedby={error ? errorId : undefined}
        onChange={(e) => onChange(e.target.value)}
        // autocomplete="bday" for birthday fields (WCAG 1.3.5)
      />
      {error && (
        <p id={errorId} role="alert">
          {error}
        </p>
      )}
      {/* Helper text explaining expected format — for users on browsers/AT that
          don't expose the native date picker UI */}
      <span id={`${id}-hint`} className="sr-only">
        Format: Month/Day/Year
      </span>
    </div>
  );
};
```

```typescript
// File: e2e/accessibility/date-picker.spec.ts
// Tests for date field and custom calendar widget accessibility.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Date picker accessibility', () => {
  // Test native input type="date" — simplest and most accessible approach
  test('native date input has no axe violations', async ({ page }) => {
    await page.goto('/booking');
    await page.waitForLoadState('networkidle');

    // Scope to the date input section
    const results = await new AxeBuilder({ page })
      .include('[data-testid="date-field"]')
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(results.violations).toEqual([]);
  });

  // Test custom calendar widget — significantly more complex
  test('calendar picker trigger announces haspopup="dialog"', async ({ page }) => {
    await page.goto('/booking');
    await page.waitForLoadState('networkidle');

    const calendarTrigger = page.locator('[data-testid="calendar-trigger"]');
    if (await calendarTrigger.count() > 0) {
      // Must announce that it opens a dialog (2.5.1 pattern + 4.1.2)
      await expect(calendarTrigger).toHaveAttribute('aria-haspopup', 'dialog');
    }
  });

  test('open calendar dialog has grid role and keyboard navigation', async ({ page }) => {
    await page.goto('/booking');
    await page.waitForLoadState('networkidle');

    const calendarTrigger = page.locator('[data-testid="calendar-trigger"]');
    if (await calendarTrigger.count() === 0) return; // Skip if no custom calendar

    await calendarTrigger.click();
    await page.waitForSelector('[role="dialog"]');

    // Calendar grid must use role="grid" (not role="table")
    const calendarGrid = page.locator('[role="grid"]');
    await expect(calendarGrid).toBeVisible();

    // Gridcells must be present
    const cells = page.locator('[role="gridcell"]');
    const cellCount = await cells.count();
    expect(cellCount).toBeGreaterThan(27); // At least 28 days visible

    // Arrow key navigation within grid
    await page.keyboard.press('ArrowRight');
    await page.keyboard.press('ArrowDown');
    // Focus should remain within the grid
    const focusInGrid = await page.evaluate(() => {
      const grid = document.querySelector('[role="grid"]');
      return grid?.contains(document.activeElement) ?? false;
    });
    expect(focusInGrid).toBe(true);

    // Escape closes the calendar and returns focus to trigger
    await page.keyboard.press('Escape');
    await expect(page.locator('[role="dialog"]')).not.toBeVisible();
    const focusOnTrigger = await page.evaluate(() => {
      return document.activeElement?.getAttribute('data-testid') === 'calendar-trigger';
    });
    expect(focusOnTrigger).toBe(true);
  });

  // Test that selected date is announced correctly
  test('selected date cell has aria-selected="true"', async ({ page }) => {
    await page.goto('/booking?date=2026-06-15');
    await page.waitForLoadState('networkidle');

    const calendarTrigger = page.locator('[data-testid="calendar-trigger"]');
    if (await calendarTrigger.count() === 0) return;

    await calendarTrigger.click();
    await page.waitForSelector('[role="grid"]');

    const selectedCell = page.locator('[role="gridcell"][aria-selected="true"]');
    await expect(selectedCell).toBeVisible();
    await expect(selectedCell).toHaveAttribute('aria-selected', 'true');
  });
});
```

**Why native `<input type="date">` is preferable to custom calendars:** The WAI-ARIA APG calendar pattern requires 15+ ARIA attributes and keyboard interactions across 3 widget layers (dialog, grid, gridcell). Production implementations routinely miss `aria-selected`, `aria-current="date"`, Page Up/Down month navigation, or focus trap on close. The native input provides all these for free with zero ARIA. Custom calendars are only justified when: (1) the design requires month/year pickers not provided by native, (2) the application needs full visual control over the date selector, or (3) internationalization requirements differ from the browser's native format display. [community]

### prefers-reduced-motion Testing

WCAG 2.1 SC 2.3.3 (AAA) and WCAG 2.2 SC 2.3.3 require that animations triggered by interaction can be disabled. Beyond AAA, `prefers-reduced-motion` is widely considered a best practice and is referenced in WCAG 2.1 Understanding docs. Many users with vestibular disorders, epilepsy, and attention disorders rely on it.

**Why test this:** Animation-heavy UIs built without `prefers-reduced-motion` support actively harm users with vestibular disorders. Testing ensures that CSS and JavaScript animations respect the OS-level accessibility preference.

```typescript
// File: e2e/accessibility/reduced-motion.spec.ts
// Test that animations are suppressed when prefers-reduced-motion: reduce is active.
// Playwright emulates the media query at the browser level.
import { test, expect } from '@playwright/test';

test.describe('prefers-reduced-motion', () => {
  test.use({
    // Emulate OS-level reduced motion preference for all tests in this block
    reducedMotion: 'reduce',
  });

  test('page-transition animation is suppressed', async ({ page }) => {
    await page.goto('/');

    // Verify that the page-transition container has no animation duration
    // when reduced motion is preferred
    const animationDuration = await page.evaluate(() => {
      const el = document.querySelector('[data-testid="page-transition"]');
      return el ? getComputedStyle(el).animationDuration : null;
    });

    // CSS: @media (prefers-reduced-motion: reduce) { animation-duration: 0.001ms }
    // 0.001ms rounds to "0s" in getComputedStyle; either is acceptable
    expect(['0s', '0.001s', '0.001ms']).toContain(animationDuration ?? '0s');
  });

  test('carousel auto-play is disabled', async ({ page }) => {
    await page.goto('/');
    const initialSlide = await page.locator('[data-testid="carousel-slide"].active').textContent();

    // Wait 3 seconds — slide should not advance if auto-play respects prefers-reduced-motion
    await page.waitForTimeout(3000);
    const currentSlide = await page.locator('[data-testid="carousel-slide"].active').textContent();
    expect(currentSlide).toBe(initialSlide);
  });
});

test.describe('without reduced-motion preference (baseline)', () => {
  test.use({ reducedMotion: 'no-preference' });

  test('carousel auto-play is active by default', async ({ page }) => {
    await page.goto('/');
    const initialSlide = await page.locator('[data-testid="carousel-slide"].active').textContent();
    await page.waitForTimeout(4000);
    const currentSlide = await page.locator('[data-testid="carousel-slide"].active').textContent();
    // Slide should have advanced if auto-play is on
    expect(currentSlide).not.toBe(initialSlide);
  });
});
```

**CSS implementation pattern** that these tests verify:
```css
/* Respect OS reduced-motion preference globally */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.001ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.001ms !important;
    scroll-behavior: auto !important;
  }
}
```

### forced-colors / Windows High Contrast Mode Testing  [community]

Windows High Contrast Mode (now `forced-colors: active` in CSS) is an OS-level accessibility feature used by users with low vision, photosensitivity, or cognitive differences. It overrides all authored colors with a system palette, stripping background images and custom color properties. WCAG 2.1 SC 1.4.3 (Contrast) and 1.4.11 (Non-text Contrast) apply equally in forced-colors mode, but the failure mechanism differs: UI controls that rely on background-color or border-color for visual boundaries become invisible when the OS overrides those values.

**Why test this:** Playwright can emulate `forced-colors: active`, letting CI catch components that become unreadable or non-functional in High Contrast Mode without requiring a Windows machine.

```typescript
// File: e2e/accessibility/forced-colors.spec.ts
// Test that interactive controls remain visually distinguishable in Windows High Contrast Mode.
// Playwright 1.35+ supports forcedColors emulation natively.
import { test, expect } from '@playwright/test';

test.describe('forced-colors: Windows High Contrast Mode', () => {
  test.use({
    // Emulate Windows High Contrast Mode (forced-colors: active)
    forcedColors: 'active',
  });

  test('primary button boundary is visible in High Contrast Mode', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // In forced-colors mode, buttons must use ButtonText/ButtonFace system colors
    // or have a visible border. Check that the button has a non-zero border or outline.
    const buttonBorderWidth = await page.evaluate(() => {
      const btn = document.querySelector<HTMLElement>('button[data-testid="primary-action"]');
      if (!btn) return null;
      return getComputedStyle(btn).borderWidth;
    });

    // A button with no border and no system-color background is invisible in HC mode
    expect(buttonBorderWidth).not.toBe('0px');
  });

  test('form input field boundary is distinguishable from background', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    // Input fields that rely only on background-color for visual boundary become
    // invisible in forced-colors mode. They must use system colors or borders.
    const inputBorder = await page.evaluate(() => {
      const input = document.querySelector<HTMLInputElement>('input[type="email"]');
      if (!input) return null;
      const style = getComputedStyle(input);
      return {
        borderWidth: style.borderWidth,
        borderStyle: style.borderStyle,
        outline: style.outline,
      };
    });

    expect(inputBorder).not.toBeNull();
    // Must have either a visible border or outline
    const hasBorder = inputBorder!.borderStyle !== 'none' && inputBorder!.borderWidth !== '0px';
    const hasOutline = inputBorder!.outline !== 'none' && inputBorder!.outline !== '';
    expect(hasBorder || hasOutline).toBe(true);
  });
});
```

**CSS pattern for forced-colors compatibility:**
```css
/* Ensure interactive elements use system colors in forced-colors mode */
@media (forced-colors: active) {
  .btn-primary {
    /* Use ButtonText + ButtonFace system colors — forced-colors honors these */
    forced-color-adjust: auto;
    border: 2px solid ButtonText;
  }
  .form-input {
    border: 1px solid ButtonText;
  }
}
```

### Multi-Locale and RTL Language Accessibility Testing

WCAG 3.1.1 (Language of Page) and 3.1.2 (Language of Parts) require correct `lang` attributes. Screen readers switch pronunciation engines based on `lang`. axe-core supports 16 locales for its own rule messages (via `axe.configure({ locale })`) but it does not test your app's `lang` attributes — that's a separate test responsibility.

**Why RTL matters for accessibility:** Arabic, Hebrew, Persian, and Urdu are read right-to-left. When `dir="rtl"` is not set, text direction, focus order, and icon placement are reversed visually but not semantically, breaking reading order (WCAG 1.3.2) and causing screen readers to announce content in the wrong sequence.

```typescript
// File: e2e/accessibility/multi-locale.spec.ts
// Test that lang attributes are present and RTL language pages set dir="rtl".
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Language and direction accessibility', () => {
  test('English page has lang="en" on <html>', async ({ page }) => {
    await page.goto('/');
    const lang = await page.evaluate(() => document.documentElement.lang);
    expect(lang).toMatch(/^en(-[A-Z]{2})?$/);
  });

  test('Arabic locale page has lang="ar" and dir="rtl"', async ({ page }) => {
    // Navigate to the Arabic locale of the application
    await page.goto('/ar');
    await page.waitForLoadState('networkidle');

    const htmlAttrs = await page.evaluate(() => ({
      lang: document.documentElement.lang,
      dir: document.documentElement.dir,
    }));

    expect(htmlAttrs.lang).toMatch(/^ar/);
    // RTL pages must declare dir="rtl" — otherwise browser uses LTR layout
    expect(htmlAttrs.dir).toBe('rtl');
  });

  test('Arabic locale page has no axe violations', async ({ page }) => {
    await page.goto('/ar');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(results.violations).toEqual([]);
  });

  test('inline foreign-language content has lang attribute on containing element', async ({ page }) => {
    // WCAG 3.1.2: Language of Parts — inline content in a different language
    // must have a lang attribute on the containing element.
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Check that any element with data-lang is a valid lang attribute format
    const inlineLangIssues = await page.evaluate(() => {
      // Look for elements that have content in non-primary languages
      // (teams should mark these explicitly with lang=)
      const elements = document.querySelectorAll<HTMLElement>('[lang]');
      const invalid: string[] = [];
      elements.forEach((el) => {
        const lang = el.getAttribute('lang') ?? '';
        // Basic BCP47 tag validation: 2-3 letter language code
        if (!/^[a-zA-Z]{2,3}(-[a-zA-Z0-9]{2,8})*$/.test(lang)) {
          invalid.push(`<${el.tagName.toLowerCase()} lang="${lang}">`);
        }
      });
      return invalid;
    });

    if (inlineLangIssues.length > 0) {
      console.error('Invalid lang attribute values:', inlineLangIssues);
    }
    expect(inlineLangIssues).toEqual([]);
  });
});
```

**axe-core locale configuration (for localized error messages in reports):**

```typescript
// File: e2e/fixtures/axe-locale-fixture.ts
// Configure axe to report violations in the user's language — useful when
// accessibility reports are shared with non-English-speaking development teams.
import { test as base } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import type { Spec } from 'axe-core';

// axe-core ships locale files for: de, es, fr, it, ja, ko, nl, pl, pt_BR, zh_CN, zh_TW, da, eu, he, hu
// Import the locale JSON from node_modules/axe-core/locales/<locale>.json
const germanLocale = require('axe-core/locales/de.json') as Spec;

export const test = base.extend<{ checkA11y: (selector?: string) => Promise<void> }>({
  checkA11y: async ({ page }, use) => {
    const checkA11y = async (selector?: string) => {
      let builder = new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
        // Report violations in German for German-language team members
        .options({ locale: germanLocale });

      if (selector) builder = builder.include(selector);
      const results = await builder.analyze();

      if (results.violations.length > 0) {
        const msg = results.violations
          .map((v) => `[${v.impact}] ${v.id}: ${v.description}`)
          .join('\n');
        throw new Error(`Barrierefreiheitsverstöße gefunden:\n${msg}`);
      }
    };
    await use(checkA11y);
  },
});
```

---

## Anti-Patterns

Each anti-pattern includes: the problematic pattern, **WHY it fails**, the **named alternative**, and the **WCAG criterion** it violates.

1. **`<div role="button">` without keyboard handler**
   - **WHY it fails**: `<div>` gets the ARIA role but not native button behavior. It is not in the tab order by default, does not respond to Enter/Space keyboard activation, and does not dispatch synthetic click events in all browsers.
   - **Named alternative**: Use `<button type="button">`. Native `<button>` has tabIndex, Enter/Space activation, and implicit `role="button"` — three features you get for free.
   - **WCAG**: 2.1.1 Keyboard, 4.1.2 Name Role Value

2. **`outline: none` without replacement focus indicator**
   - **WHY it fails**: Removing the default browser focus outline without providing an alternative leaves keyboard-only users with no visible indication of where focus is. They cannot use the application at all.
   - **Named alternative**: Replace with a custom outline: `outline: 2px solid #0057b7; outline-offset: 2px;` — meets WCAG 2.4.7 and 2.4.11 (WCAG 2.2) simultaneously.
   - **WCAG**: 2.4.7 Focus Visible (AA), 2.4.11 Focus Appearance (WCAG 2.2 AA)

3. **axe-only CI gate without manual testing**
   - **WHY it fails**: axe-core catches ~57% of WCAG 2.1 issues. The 43% it misses includes the most impactful user-experience issues: wrong announcement order, screen reader Browse Mode navigation, cognitive load, and dynamic live region timing.
   - **Named alternative**: Three-layer strategy — axe CI gate (automated) + keyboard audit every sprint (manual) + screen reader session for every new interactive pattern (manual). This combination addresses all WCAG categories.
   - **WCAG**: Multiple; most critical misses are in Perceivable and Understandable principles

4. **Generic link text ("click here", "read more", "learn more")**
   - **WHY it fails**: Screen reader users navigate by pulling up a list of all links on the page. "Click here" repeated 10 times is meaningless out of context. The link text is the only information available in a links list.
   - **Named alternative**: Descriptive links: `<a href="/report">Download the 2025 Annual Report (PDF)</a>`. Or use `aria-label` to augment short visible text: `<a href="/report" aria-label="Download 2025 Annual Report PDF">Download</a>`.
   - **WCAG**: 2.4.6 Headings and Labels (AA), 2.4.4 Link Purpose (A)

5. **Placeholder text as the sole form label**
   - **WHY it fails**: Placeholder text disappears on input, giving users with cognitive disabilities or short-term memory impairments no way to recall what the field requires. It also has typically insufficient contrast (3:1 spec for placeholder is often not met).
   - **Named alternative**: Always use a visible `<label htmlFor="field-id">`. Placeholder is acceptable as a hint in addition to a label, never as a substitute.
   - **WCAG**: 3.3.2 Labels or Instructions (A), 1.4.3 Contrast (AA for label, which placeholder fails to meet in most design systems)

6. **Auto-playing media without pause/stop control**
   - **WHY it fails**: Screen reader users hear both the page content and the auto-playing audio simultaneously, making both unintelligible. Users with vestibular disorders are harmed by motion that starts without consent.
   - **Named alternative**: Provide a pause/stop control as the first interactive element in the media region, or do not autoplay. For animation, support `prefers-reduced-motion: reduce`.
   - **WCAG**: 1.4.2 Audio Control (A), 2.2.2 Pause/Stop/Hide (A)

7. **aria-label on every element regardless of native semantics**
   - **WHY it fails**: Adds redundant or conflicting announcements. Screen readers may announce both the native role and the label, creating double-announcements for elements like `<h2 aria-label="Section title">Section title</h2>`. Over-labeling also signals to reviewers that the team is compensating for missing semantic structure.
   - **Named alternative**: Use ARIA only as a last resort when no native HTML element carries the required semantics. First try: semantic HTML. Second: `aria-labelledby` pointing to existing visible text. Third: `aria-label` for icon-only controls that have no visible text.
   - **WCAG**: 4.1.2 Name Role Value (A)

8. **Using `opacity: 0` or `visibility: hidden` to hide interactive content**
   - **WHY it fails**: `opacity: 0` keeps the element in the tab order and the accessibility tree. Keyboard users Tab to invisible buttons; screen reader users encounter invisible interactive elements. `visibility: hidden` removes from accessibility tree but still occupies layout space.
   - **Named alternative**: Use `display: none` to hide content from all users (removes from tab order + accessibility tree + layout). Use `inert` attribute to prevent interaction while keeping visual presence (e.g., a dimmed background behind a modal).
   - **WCAG**: 2.4.3 Focus Order (A), 1.3.1 Info and Relationships (A)

9. **Positive tabIndex values (`tabIndex={1}`, `tabIndex={2}`)**
   - **WHY it fails**: A positive tabIndex creates a separate, prioritized tab order that runs before the natural DOM order. It causes wildly unexpected Tab sequence that confuses keyboard users and is nearly impossible to maintain as components are added or reordered.
   - **Named alternative**: Use only `tabIndex={0}` (include in natural tab order at its DOM position) or `tabIndex={-1}` (remove from tab order, accessible via programmatic focus only). Reorder DOM elements if the visual and logical order do not match.
   - **WCAG**: 2.4.3 Focus Order (A)

10. **`role="presentation"` on semantic structural elements**
    - **WHY it fails**: `role="presentation"` (alias: `role="none"`) removes the element's semantic role from the accessibility tree. Applying it to `<h1>`, `<nav>`, `<table>`, or `<button>` strips the semantics screen reader users depend on to navigate by headings, landmarks, or tables.
    - **Named alternative**: If an element provides visual styling only (e.g., a `<table>` used for page layout, not data), `role="presentation"` is correct. For all semantic elements conveying real structure, keep native semantics or use an appropriate ARIA role.
    - **WCAG**: 1.3.1 Info and Relationships (A), 4.1.2 Name Role Value (A)

---

## Automated vs Manual Testing Split

axe-core's automated rules detect approximately **57% of WCAG 2.1 issues** (Deque research). The other ~43% require human judgment.

| Category | Automated (axe) | Manual Required | Why manual is needed |
|----------|----------------|----------------|---------------------|
| Color contrast | Yes | Only custom/dynamic | axe can't see contrast on canvas, SVG gradients |
| Missing alt text | Yes | Descriptive quality | axe checks presence, not whether `alt="photo"` is meaningful |
| Form label association | Yes | Label accuracy | axe checks association exists, not whether label is helpful |
| ARIA attribute validity | Yes | ARIA logic correctness | axe checks syntax; wrong role combinations require human judgment |
| Keyboard navigation | Partial | Full flow testing | axe cannot simulate multi-step keyboard workflows |
| Screen reader announcement | No | NVDA / VoiceOver / TalkBack | Announcement quality and context are not machine-testable |
| Cognitive load / plain language | No | Expert review | Reading level and clarity require human evaluation |
| Dynamic content live regions | Partial | Live region behavior | Timing and announcement sequence require real AT testing |

**WebAIM Million Report (2024 findings)** — scanning top 1 million homepages:
- 95.9% of home pages had detected WCAG failures
- Most common: low color contrast (80.9%), missing alt text (54.5%), missing form labels (48.6%), empty links (44.6%)
- Average 56.8 detected errors per page

**Recommended split per sprint:**
- **Automated (CI — every PR)**: jest-axe for all component tests; Playwright/axe for critical user flows
- **Manual keyboard (every sprint)**: QA engineer navigates every new page/flow without mouse
- **Screen reader (every sprint)**: NVDA + Firefox and VoiceOver + Safari for new interactive patterns
- **Full accessibility audit (quarterly or pre-major release)**: Expert review against WCAG 2.1 AA checklist

---

## Real-World Gotchas [community]

1. **[community] axe flags color contrast as incomplete in JSDOM**: jest-axe running in JSDOM cannot compute computed styles, so color-contrast rules return `incomplete`. Run Playwright tests for contrast.

2. **[community] Focus management in SPAs**: In React Router / Next.js apps, navigation does not automatically move focus to new content. After route transitions, focus stays on the clicked link. Programmatically focus `<main>` or a heading after each route change.

3. **[community] Modal dialogs without `aria-modal="true"` expose background content**: Screen readers in Browse mode (NVDA + Firefox) read background content while a modal is open. Use `inert` attribute on background elements — the `aria-modal` attribute alone is not honored by VoiceOver.

4. **[community] axe passes while VoiceOver fails on custom widgets**: axe validates ARIA syntax but cannot test whether a custom combobox announces options correctly when arrowing through a list. Manual testing required for all interactive widgets.

5. **[community] Playwright axe scans miss dynamically injected content**: Toast notifications or errors that appear after user action are not caught by a page-level axe scan at load time. Use `page.waitForSelector` before re-scanning dynamic regions.

6. **[community] tabIndex={0} on non-interactive elements without keyboard handler**: Adding `tabIndex={0}` to a `<div>` makes it reachable by Tab but it does not become "clickable" via Enter/Space. Always pair `tabIndex={0}` with keydown handlers for Enter and Space.

7. **[community] aria-label vs aria-labelledby: labelledby wins in VoiceOver**: When both `aria-label` and `aria-labelledby` are present, `aria-labelledby` takes precedence. Teams that add `aria-label` expecting it to override an existing `aria-labelledby` label are surprised when the screen reader ignores it.

8. **[community] axe-core versions differ between jest-axe and @axe-core/playwright**: Teams running different axe-core versions in unit vs E2E tests get inconsistent results — a rule that passes in jest-axe may fail in Playwright because the underlying axe-core version differs. Pin axe-core explicitly in your dependency tree.

9. **[community] aria-live="assertive" should be reserved for truly urgent messages**: Using `role="alert"` for routine status messages (form auto-saves, progress updates) interrupts whatever the screen reader is currently announcing. Use `aria-live="polite"` for non-urgent updates.

10. **[community] iOS VoiceOver swipe navigation differs from NVDA browse mode**: A widget that works with NVDA + Firefox will often behave differently under VoiceOver + Safari on iOS. VoiceOver uses swipe gestures; `aria-modal` is not honored. The `inert` attribute (or careful DOM structure) is the only reliable way to prevent background content from being swiped to.

11. **[community] axe-core does not scan inside closed Shadow DOM**: Web components using closed Shadow DOM are invisible to axe-core. Design system components (Material Web, Shoelace, Lit) may have a clean axe scan while actual rendered components have contrast or label issues. Verify with real browser devtools.

12. **[community] Component unit tests pass but full-page axe fails due to duplicate IDs**: A component using `id="close-btn"` passes unit tests but fails `duplicate-id` in the real application where the component renders in multiple places. Always supplement unit-level tests with page-level Playwright scans.

13. **[community] React re-renders clear screen reader focus position**: When a React component re-renders due to state changes, the screen reader's virtual cursor can be reset. Debounce validation and use `aria-live` regions for error messages instead of conditionally rendering error elements inside the form flow.

14. **[community] Overriding native semantics with ARIA removes built-in behavior**: Adding `role="presentation"` to a `<button>` removes its button semantics. Adding `role="button"` to an `<a>` removes its link behavior. Apply ARIA roles only when no native HTML equivalent exists.

15. **[community] Positive tabIndex values break natural tab order**: `tabIndex={1}`, `tabIndex={2}` create a separate tab order that overrides natural DOM order and causes severe confusion for keyboard users navigating sequentially. Use only `tabIndex={0}` (include in tab order) or `tabIndex={-1}` (programmatic focus only).

16. **[community] @testing-library query priority directly reflects accessibility**: `getByRole` is the most accessible query because it uses the accessibility tree, not the DOM. Teams that use `getByTestId` exclusively write tests that pass even when accessible names are broken — a form label can be removed and `getByTestId('email')` still finds the input. Use query priority: `getByRole` > `getByLabelText` > `getByPlaceholderText` > `getByText` > `getByTestId` (last resort only).

17. **[community] axe-core minor version upgrades add new rules that break CI unexpectedly**: Deque ships new rules in minor versions of axe-core. Teams that pin `axe-core: "^4"` or `jest-axe: "^8"` find CI failing after a dependency update because a new rule fires. Best practice from axe-core's security support policy: plan a minor version upgrade every 3–5 months and treat axe rule changes as you would a lint rule change — review, fix, update the baseline.

18. **[community] forced-colors mode (Windows High Contrast) breaks components that rely on background-color for visual boundaries**: Components that use `background-color` alone to visually distinguish form inputs, buttons, or selected states lose all visual differentiation in forced-colors mode. The OS overrides the authored color; only `border`, `outline`, and `color` are preserved (as system colors). Use CSS `@media (forced-colors: active)` to add explicit borders to controls and test with Playwright's `forcedColors: 'active'` emulation.

19. **[community] axe-core 4.10+ `aria-dialog-name` rule fires on unnamed `role="dialog"` elements**: Earlier axe-core versions silently allowed `<div role="dialog">` with no accessible name. axe-core 4.10+ fires `aria-dialog-name` (WCAG 4.1.2) for dialogs missing `aria-label` or `aria-labelledby`. Teams upgrading from 4.8/4.9 experience unexpected CI failures on existing dialogs. Every modal must now have an accessible heading linked via `aria-labelledby` or an explicit `aria-label`.

20. **[community] NVDA Browse Mode vs Application Mode is the most common source of keyboard testing confusion**: NVDA operates in two modes. In Browse Mode (the default for web content), arrow keys navigate the virtual buffer and custom keyboard handlers on elements are bypassed. When `role="application"`, `role="grid"`, `role="dialog"`, or `role="combobox"` is used, NVDA switches to Application Mode and passes keyboard events to the element. Teams testing with keyboard only (no screen reader) validate that Tab/Enter/Space work, but never discover that NVDA Browse Mode swallows arrow key events, making custom datepickers and comboboxes completely inoperable for NVDA users. Always test interactive widgets with NVDA + Firefox to confirm mode-switching behavior.

21. **[community] `toBeVisible()` in `@testing-library/jest-dom` does NOT test accessibility tree visibility**: `toBeVisible()` checks CSS visibility (`display`, `visibility`, `opacity`) but does not verify that an element is present in the ARIA accessibility tree. An element with `aria-hidden="true"` passes `toBeVisible()` but is completely invisible to screen readers. Use `toBeInTheDocument()` + axe checks for accessibility, and verify `aria-hidden` explicitly when testing that content is hidden from AT.

22. **[community] Lighthouse accessibility score of 100 does not mean WCAG compliant**: Lighthouse uses axe-core under the hood but runs a subset of rules and weights them to produce a composite 0–100 score. A score of 100 means all Lighthouse-selected rules passed — but that is roughly 25–30 of axe-core's 80+ rules. Teams that report "accessibility score: 100" to stakeholders as a compliance measure are misrepresenting the coverage. Use Lighthouse for trend monitoring and developer feedback; use full axe-core runs and manual audits for compliance claims.

23. **[community] Virtual scrolling / infinite scroll breaks screen reader list navigation**: Screen readers enumerate list items by total count (e.g., "list of 10 items") and allow users to jump by item count. When a virtual-scroll component renders only a windowed subset of items (e.g., 20 of 1000) and removes DOM nodes as they scroll out of view, the screen reader count is wrong and items navigated to by count are unreachable. Use `aria-setsize` and `aria-posinset` to communicate the full collection size, or avoid virtual scrolling for assistive-technology-critical content.

24. **[community] ARIA combobox pattern changed in ARIA 1.2 — ARIA 1.1 pattern is widely deprecated but still common in codebases**: The ARIA 1.1 combobox pattern used `role="combobox"` on a wrapper `<div>` containing an `<input>`. ARIA 1.2 (2023) moved `role="combobox"` directly to the `<input>` element and changed which attributes apply where. Screen readers were updated to expect the ARIA 1.2 pattern. Teams using older component libraries (pre-2022 Headless UI, react-select < v5, older Downshift) may be using the ARIA 1.1 pattern that modern screen readers announce incorrectly. The APG Combobox Pattern page shows the current correct pattern. Verify with NVDA + Firefox and VoiceOver.

25. **[community] Switch access and voice control users are broken by click-only event handlers**: Switch access devices (used by users with severe motor disabilities) and voice control tools (Dragon NaturallySpeaking, Voice Control on macOS/iOS) activate interactive elements by simulating pointer clicks or by referencing the visible accessible name. A component that only responds to `mousedown` (not `click`) fails for switch access. A button labeled "X" that visually says "Close" fails voice control — the user says "Close" but the accessible name is "X". WHY: voice control tools match spoken words to accessible names; always use the visible label as (or in) the accessible name. Test by: (1) voice control: verify every button's accessible name contains its visible text. (2) switch access: verify all interactions work via the `click` event, not `mousedown`/`mouseup` alone.

26. **[community] React 18 Concurrent Mode with `<Suspense>` can expose live regions before content is ready**: When React suspends a component tree and shows a fallback (spinner), then hydrates the actual content, any `aria-live` regions inside the suspended subtree may announce their initial empty state, then the loaded content state. Screen reader users hear two announcements for one page load. WHY: React's fiber reconciler commits updates in batches; ARIA live regions announce every DOM mutation. Mitigation: render the `aria-live` region outside the Suspense boundary and update it only when content is fully loaded.

27. **[community] `useEffect` cleanup timing causes double-announcement in StrictMode**: React 18 StrictMode invokes `useEffect` twice (mount, unmount, remount) in development. If your focus management or `aria-live` update runs in `useEffect`, screen readers in development can hear the announcement twice. WHY: this reveals underlying robustness issues — production builds do not double-invoke effects, but the double-announcement in dev exposes that the a11y behavior depends on side-effect timing. Fix by ensuring focus management is idempotent and live region content is deduplicated.

28. **[community] Content Security Policy (CSP) blocks axe-core injection in Playwright**: axe-core is injected as an inline script into the page by `@axe-core/playwright`. A strict CSP that disallows `'unsafe-inline'` or requires `'strict-dynamic'` will block axe-core injection, causing scans to silently fail or throw an error. WHY: teams enabling CSP headers in staging environments discover that all Playwright axe scans report 0 violations — including real ones — because the engine never loaded. Fix: add a CSP nonce for testing environments, use the `page.addScriptTag` approach with a nonce, or whitelist the axe-core CDN hash in the CSP.

29. **[community] Stagger animations and skeleton loaders hide content from screen reader users during loading**: A skeleton loader with `aria-hidden="true"` + `role="status"` updates are a common pattern to communicate "loading." However, when the skeleton loader is replaced by real content, teams that forget to remove `aria-hidden` from the content wrapper cause the entire loaded page to remain invisible to screen readers. WHY: the `aria-hidden` attribute is often set on a wrapping `<section>` during the loading state and removed programmatically after; if that removal is tied to a UI animation completion event (rather than data ready), a race condition can leave the content hidden. Test: after every data-load flow, assert that no `aria-hidden="true"` exists on content-bearing elements.

30. **[community] Missing `autocomplete` attributes on address/payment fields fail WCAG 1.3.5 and fail users with motor disabilities**: WCAG 1.3.5 (Identify Input Purpose, AA) requires that form fields collecting personal data expose their purpose via the `autocomplete` attribute. This allows browsers and AT to auto-fill data and reduces typing burden for users with tremors, limited motor control, or cognitive disabilities. WHY: teams implement auto-complete widgets but forget the `autocomplete` HTML attribute on `<input>` elements. axe-core does not currently catch this (it is on the roadmap but not yet in the rule set as of 4.11). Manual testing is required: check that `<input type="email">` has `autocomplete="email"`, `<input type="tel">` has `autocomplete="tel"`, name/address fields have appropriate token values.

31. **[community] AI-generated alt text requires human verification before shipping**: Tools like Aura (BLIP model) and LLM-generated alt text produce candidate descriptions that are often technically accurate but miss context-critical nuance. An AI may describe a chart as "a bar chart showing data" when the meaningful alt text should convey the insight: "Bar chart showing Q3 revenue increased 23% vs Q2." WHY: WCAG 1.1.1 requires alt text that conveys the same meaning as the image — not just a visual description. AI tools generate descriptions; QA teams must verify the descriptions are contextually equivalent to the content for screen reader users. Never ship AI-generated alt text without a human review step.

32. **[community] navable MCP / agent-driven a11y fixes can introduce new violations when patching structural issues**: An AI agent implementing a fix plan may add `aria-label` to resolve a `button-name` violation and inadvertently introduce a WCAG 2.5.3 Label in Name mismatch (the aria-label does not contain the visible text). WHY: each fix is isolated; the agent does not have global context about all WCAG interactions. Always run a full re-scan after agent-applied fixes, not just verification of the patched rules. The navable MCP `run_accessibility_scan` verify step covers this, but teams using custom agent scripts often skip the full rescan.

33. **[community] axe-core 4.11.4 (April 2026) is the current version — teams on 4.8/4.9 miss 12+ rules**: Teams that pinned `axe-core: "4.8"` are missing rules for `aria-dialog-name`, `aria-tooltip-name`, `scrollable-region-focusable`, `target-size` (WCAG 2.5.8), and `color-contrast-enhanced`. axe-core security support covers minor versions up to 18 months old — versions before 4.8 are outside the support window. WHY: axe-core 4.11.x is the version that aligns with WCAG 2.2 AA requirements mandated by the EU EAA (June 2025 deadline). Running an older version creates a false sense of compliance for EU-market products. Best practice: pin a specific minor version (e.g., `4.11.4`) and plan quarterly upgrades, treating each minor version as a lint-rule change review.

34. **[community] Carousel `aria-live` regions that are injected after page load are missed by some screen readers**: If the `aria-live` region for carousel slide announcements is rendered conditionally (e.g., only after auto-play starts), NVDA and JAWS may not observe changes to it. WHY: screen readers register `aria-live` regions on page load. Regions created or inserted into the DOM after load are not reliably observed by all AT. Always render the live region in the initial HTML/DOM with empty content, then populate it — never create the region dynamically.

35. **[community] Accessible carousels without `aria-roledescription="carousel"` confuse screen reader users**: Without `aria-roledescription`, a `<section>` wrapping a carousel is announced as "region." NVDA users hear "Featured content region" rather than "Featured content carousel" — losing the understanding that this is a rotating content widget. The `aria-roledescription` attribute customizes the role announcement and is a best practice in the WAI-ARIA APG Carousel pattern. Note: `aria-roledescription` is for informational customization only — it does not change keyboard behavior and must still be paired with appropriate role and keyboard pattern implementation.

36. **[community] Storybook `@storybook/test-runner` a11y checks run after visual render but before React effects complete**: If a component sets ARIA state in a `useEffect` (e.g., setting `aria-expanded="true"` after a fetch), the test runner's `postVisit` hook runs immediately after the story renders — before the effect fires. axe sees the pre-effect DOM state and may miss the ARIA update. Workaround: add a short `waitForFunction` in `postVisit` to wait for the expected ARIA state before running `checkA11y`.

37. **[community] `getByRole` with Playwright is the most reliable way to assert accessible names — not attribute checks**: Teams that write `expect(el).toHaveAttribute('aria-label', 'Close')` test the HTML attribute, not the computed accessible name. If `aria-labelledby` is also present, the computed name is from the labelledby target — not the aria-label. Playwright's `page.getByRole('button', { name: 'Close' })` queries the accessibility tree (computed name) and fails if the element is not accessible with that name, regardless of which attribute provides it.

---

## Accessibility Metrics and Program Health

Tracking accessibility over time is as important as the initial remediation. Without metrics, teams cannot demonstrate progress, catch regressions early, or justify continued investment.

**Recommended metrics dashboard:**

| Metric | Tool | Frequency | Target |
|--------|------|-----------|--------|
| Axe violation count (by severity) | CI axe reports | Every PR | 0 new critical/serious |
| WCAG 2.1 AA pass rate (pages scanned) | CI axe + Playwright | Weekly | 100% of critical flows |
| Baseline violation count trend | `known-violations-baseline.json` commits | Monthly | Decreasing |
| Screen reader audit defects logged | Defect tracker | Per sprint | Decreasing |
| Keyboard audit pass rate | Manual test results | Per sprint | 100% of new flows |
| a11y-tagged PR fix rate | Git history | Monthly | <48h resolution for critical |

**TypeScript script to extract axe violation trend from CI artifacts:**

```typescript
// File: scripts/a11y-metrics-report.ts
// Aggregates axe scan results from multiple CI runs to show violation trends.
// Run after collecting multiple JUnit or JSON axe reports from CI.
import * as fs from 'fs';
import * as path from 'path';

interface AxeRunResult {
  date: string;         // ISO date of the CI run
  totalViolations: number;
  bySeverity: {
    critical: number;
    serious: number;
    moderate: number;
    minor: number;
  };
  newViolations: number;   // Violations not in baseline at time of run
}

export function parseAxeJsonReport(filePath: string): AxeRunResult {
  const raw = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  const violations = (raw.violations ?? []) as Array<{ impact: string }>;

  const bySeverity = violations.reduce(
    (acc, v) => {
      const key = v.impact as keyof typeof acc;
      if (key in acc) acc[key]++;
      return acc;
    },
    { critical: 0, serious: 0, moderate: 0, minor: 0 }
  );

  return {
    date: raw.timestamp ?? new Date().toISOString(),
    totalViolations: violations.length,
    bySeverity,
    newViolations: 0, // Populated by baseline comparison
  };
}

export function generateTrendReport(reportDir: string): void {
  const reportFiles = fs.readdirSync(reportDir)
    .filter((f) => f.endsWith('-axe-report.json'))
    .sort(); // Sort by filename (date prefix)

  const runs = reportFiles.map((f) =>
    parseAxeJsonReport(path.join(reportDir, f))
  );

  console.log('Accessibility Violation Trend:');
  console.log('Date                | Total | Critical | Serious | Moderate | Minor');
  console.log('--------------------+-------+----------+---------+----------+------');

  for (const run of runs) {
    const date = run.date.slice(0, 10);
    console.log(
      `${date.padEnd(20)}| ${String(run.totalViolations).padEnd(6)}| ` +
      `${String(run.bySeverity.critical).padEnd(9)}| ` +
      `${String(run.bySeverity.serious).padEnd(8)}| ` +
      `${String(run.bySeverity.moderate).padEnd(9)}| ` +
      `${run.bySeverity.minor}`
    );
  }

  // Alert if critical/serious count increased
  if (runs.length >= 2) {
    const prev = runs[runs.length - 2];
    const curr = runs[runs.length - 1];
    const criticalDiff = curr.bySeverity.critical - prev.bySeverity.critical;
    const seriousDiff = curr.bySeverity.serious - prev.bySeverity.serious;

    if (criticalDiff > 0 || seriousDiff > 0) {
      console.error(
        `\n⚠ REGRESSION: Critical violations +${criticalDiff}, Serious +${seriousDiff} since last run.`
      );
      process.exitCode = 1;
    } else {
      console.log('\n✓ No increase in critical/serious violations since last run.');
    }
  }
}
```



### EN 301 549 and WCAG 2.2 — EU EAA Compliance Mapping

EN 301 549 v3.3.2 is the European harmonised standard that makes WCAG 2.2 AA the technical baseline for the EU Accessibility Act (EAA). Teams shipping to EU private-sector markets must comply by June 28, 2025. The standard adds non-web requirements (documents, mobile apps) beyond WCAG's web scope, but for web applications the critical mapping is:

| EN 301 549 Clause | Maps to | What QA tests |
|---|---|---|
| 9.1–9.4 (Web) | WCAG 2.2 AA success criteria | All WCAG 2.2 AA tests apply |
| 11.1–11.4 (Non-web docs) | WCAG 2.2 AA for PDFs/Office docs | PAC checker for PDFs; Accessibility Checker for Word |
| 11.5 (Mobile) | Platform accessibility APIs | iOS Accessibility Inspector; Android Accessibility Scanner |
| 12.1.2 (Accessibility documentation) | Support documentation is accessible | Verify help/docs pages pass WCAG 2.2 AA |

**WCAG 2.2 criterion addition checklist for teams upgrading from WCAG 2.1 AA:**

```typescript
// File: e2e/accessibility/wcag22-upgrade-checklist.spec.ts
// Covers all 9 new WCAG 2.2 criteria (A and AA) as testable Playwright assertions.
// Run against critical user flows before EAA compliance deadline.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

// ─── WCAG 2.2 New Criteria Overview ─────────────────────────────────────────
// 2.4.11 Focus Appearance (AA)       — ≥2px outline, ≥3:1 contrast
// 2.4.12 Focus Not Obscured Min (AA) — focused element must not be fully hidden
// 2.4.13 Focus Not Obscured Enh (AAA)— not fully hidden (enhanced)
// 2.5.7 Dragging Movements (AA)      — single-pointer alternative for drag
// 2.5.8 Target Size Minimum (AA)     — 24×24px OR adequate spacing
// 3.2.6 Consistent Help (A)          — help mechanism in same relative order
// 3.3.7 Redundant Entry (A)          — no re-entry of info in same session
// 3.3.8 Accessible Authentication (AA) — no cognitive function test for login
// 3.3.9 Accessible Auth Enhanced (AAA) — no cognitive function test at all
// ─────────────────────────────────────────────────────────────────────────────

test.describe('WCAG 2.2 upgrade checklist', () => {

  // 2.4.12 Focus Not Obscured (AA): focused element must be at least partially visible.
  // axe-core does not currently test this — requires visual assertion.
  test('2.4.12: focused elements are not fully obscured by sticky header', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Tab to each interactive element and check it is not hidden behind sticky header
    const stickyHeaderHeight = await page.evaluate(() => {
      const header = document.querySelector<HTMLElement>('header[class*="sticky"], [data-sticky]');
      return header ? header.offsetHeight : 0;
    });

    // Tab twice to skip skip-link and get to first nav item
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');

    const focusedRect = await page.evaluate(() => {
      const el = document.activeElement;
      if (!el) return null;
      return el.getBoundingClientRect();
    });

    if (focusedRect && stickyHeaderHeight > 0) {
      // The top of the focused element must be below the sticky header
      // If top < stickyHeaderHeight, the element is obscured
      expect(focusedRect.top).toBeGreaterThanOrEqual(stickyHeaderHeight);
    }
  });

  // 3.3.7 Redundant Entry (A): don't require users to re-enter info provided earlier.
  // This is primarily a design/UX test — verify in multi-step checkout/registration flows.
  test('3.3.7: registration flow does not re-ask for email entered on previous step', async ({
    page,
  }) => {
    await page.goto('/register/step-1');
    await page.waitForLoadState('networkidle');

    // Step 1: enter email
    await page.fill('input[type="email"]', 'test@example.com');
    await page.click('button[type="submit"]');

    // Step 2: verify email is not requested again
    await page.waitForURL('/register/step-2');
    const emailInputOnStep2 = page.locator('input[type="email"]');
    const count = await emailInputOnStep2.count();

    // Email should either not be present (step 2 doesn't need it) or be pre-filled
    if (count > 0) {
      const value = await emailInputOnStep2.inputValue();
      expect(value).toBe('test@example.com'); // Auto-filled from step 1
    }
    // If count === 0, the email input is not shown again — passes 3.3.7
  });

  // 3.3.8 Accessible Authentication (AA): no cognitive function test (CAPTCHA) without alternative.
  // axe-core does not detect CAPTCHA patterns — manual+Playwright check required.
  test('3.3.8: login page does not require CAPTCHA as the only authentication method', async ({
    page,
  }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    // Check for CAPTCHA elements — if present, verify alternatives exist
    const captchaPresent = await page.evaluate(() => {
      const captchaIndicators = [
        '[class*="captcha"]',
        '[class*="recaptcha"]',
        '[class*="hcaptcha"]',
        'iframe[src*="recaptcha"]',
        'iframe[src*="hcaptcha"]',
      ];
      return captchaIndicators.some((selector) => document.querySelector(selector) !== null);
    });

    if (captchaPresent) {
      // If CAPTCHA exists, verify that an accessible alternative is present
      // (e.g., "Use passkey", "Send me a code", audio CAPTCHA alternative)
      const hasAlternative = await page.evaluate(() => {
        const alternativeSelectors = [
          '[data-testid="passkey-login"]',
          '[data-testid="magic-link"]',
          'a[href*="audio"]',
          'button[aria-label*="audio"]',
        ];
        return alternativeSelectors.some((s) => document.querySelector(s) !== null);
      });
      // Warn rather than hard-fail — teams may have compliant alternatives not covered by selectors
      if (!hasAlternative) {
        console.warn(
          '[WCAG 3.3.8] CAPTCHA found with no detected accessible alternative. ' +
          'Manually verify: passkey, magic link, or SMS code alternative exists.'
        );
      }
    }
    // If no CAPTCHA, this criterion is satisfied by default
    expect(true).toBe(true); // Pass marker — the check above logs the warning
  });
});
```

**EN 301 549 compliance report template (for EU EAA Accessibility Conformance Report/VPAT):**

When producing an Accessibility Conformance Report (ACR) for EU EAA compliance, map your test results to EN 301 549 clauses. The navable MCP server includes a `navable://docs/wcag-mapping` resource that provides this mapping automatically. For manual tracking:

```typescript
// File: scripts/generate-en301549-report.ts
// Generates an EN 301 549 compliance summary from axe-core results.
// Output format follows the ACR/VPAT structure used in EU procurement.
import type { AxeResults } from 'axe-core';

interface EN301549Criterion {
  clause: string;          // e.g., '9.1.1.1'
  wcagCriterion: string;   // e.g., 'WCAG 1.1.1'
  level: 'A' | 'AA' | 'AAA';
  status: 'Supports' | 'Partially Supports' | 'Does Not Support' | 'Not Applicable';
  remarks: string;
}

const WCAG_TO_EN301549_MAP: Record<string, string> = {
  'wcag111': '9.1.1.1',  // Non-text Content
  'wcag143': '9.1.4.3',  // Contrast Minimum
  'wcag211': '9.2.1.1',  // Keyboard
  'wcag412': '9.4.1.2',  // Name, Role, Value
  // ... add all 50+ AA criteria
};

export function generateEN301549Report(
  axeResults: AxeResults,
  productName: string
): EN301549Criterion[] {
  const criteria: EN301549Criterion[] = [];

  for (const [wcagTag, enClause] of Object.entries(WCAG_TO_EN301549_MAP)) {
    const relatedViolations = axeResults.violations.filter((v) =>
      v.tags.some((tag) => tag.toLowerCase() === wcagTag)
    );

    criteria.push({
      clause: enClause,
      wcagCriterion: wcagTag.toUpperCase().replace(/(\d)(\d{1,2})$/, ' $1.$2'),
      level: wcagTag.includes('aa') ? 'AA' : 'A',
      status: relatedViolations.length === 0 ? 'Supports' : 'Does Not Support',
      remarks: relatedViolations.length > 0
        ? `${relatedViolations.length} violation(s): ${relatedViolations[0].description}`
        : `Automated test passed. Manual verification recommended.`,
    });
  }

  console.log(`EN 301 549 Report for ${productName}:`);
  const notSupported = criteria.filter((c) => c.status === 'Does Not Support');
  console.log(`  Supports: ${criteria.length - notSupported.length}/${criteria.length} criteria`);
  console.log(`  Failures: ${notSupported.length}`);

  return criteria;
}
```

### WCAG 3.0 (W3C Accessibility Guidelines 3.0) — Forward-Looking Awareness

WCAG 3.0 (previously known as "Silver") is in development by the W3C AGWG. As of 2025–2026, it is a working draft, not a finalized standard. QA teams should be aware of its direction but should NOT build compliance programs around it yet.

**Key differences from WCAG 2.x:**

| Aspect | WCAG 2.x | WCAG 3.0 (draft) |
|--------|----------|-------------------|
| Conformance model | Binary pass/fail per criterion | Outcome-based scoring (Bronze/Silver/Gold levels) |
| Scope | Web content only | Any technology delivering digital experiences |
| Cognitive accessibility | Limited (AAA level) | First-class citizen alongside visual and motor |
| Testing | Rule-based (axe-core) | Mixed: automated + functional outcomes + user research |
| Status | Published standard (2.1: 2018, 2.2: 2023) | Working draft — expected finalized 2027+ |

**Why QA teams should monitor but not pivot to WCAG 3.0 yet:**
1. No legal requirement references WCAG 3.0 as of 2026 — all current laws reference WCAG 2.0 or 2.1/2.2
2. The scoring model (Bronze/Silver/Gold) is fundamentally different from 2.x binary conformance — existing test infrastructure would require redesign
3. The draft changes frequently — tool support (axe-core, etc.) does not yet exist for WCAG 3.0 criteria
4. The W3C has signaled WCAG 2.x will remain the legal baseline for the foreseeable future alongside WCAG 3.0

**What to do now:** Build robust WCAG 2.2 AA testing infrastructure. When WCAG 3.0 is finalized, WCAG 2.x conformance will translate to Bronze in WCAG 3.0 — making 2.x investment directly reusable.

### Storybook Test Runner for Design System a11y CI

Storybook's `@storybook/test-runner` (2023+) runs all stories as Playwright tests in a headless browser, enabling automated axe scanning of every component story as part of CI — without a running application server. This is the highest-coverage approach for design system components.

```typescript
// File: .storybook/test-runner.ts
// Global a11y configuration for Storybook Test Runner.
// Runs axe-core against every story in CI via: npx test-storybook
import type { TestRunnerConfig } from '@storybook/test-runner';
import { checkA11y, injectAxe, configureAxe } from 'axe-playwright';

const config: TestRunnerConfig = {
  async preVisit(page) {
    // Inject axe-core into every story page before tests run
    await injectAxe(page);
  },

  async postVisit(page) {
    // Configure axe for all stories: WCAG 2.1 AA, disable JSDOM-incompatible rules
    await configureAxe(page, {
      rules: [
        { id: 'color-contrast', enabled: true },  // Real browser — contrast works
        { id: 'duplicate-id', enabled: false },    // Storybook renders many instances
      ],
    });

    // Run axe after every story renders
    await checkA11y(
      page,
      '#storybook-root',  // Scope to story container only
      {
        detailedReport: true,
        detailedReportOptions: {
          html: true,
        },
        runOnly: {
          type: 'tag',
          values: ['wcag2a', 'wcag2aa', 'wcag21aa', 'best-practice'],
        },
      },
      true,  // Skip failures for stories with parameters.a11y.disable = true
      'v2'   // Use axe v2 result format
    );
  },
};

export default config;
```

```yaml
# File: .github/workflows/storybook-a11y.yml
# Run Storybook Test Runner in CI — a11y scan every story on every PR.
name: Storybook accessibility CI
on: [pull_request]

jobs:
  storybook-a11y:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - name: Build Storybook
        run: npm run build-storybook --quiet
      - name: Serve Storybook and run a11y tests
        run: npx concurrently -k -s first -n "SB,TEST" -c "magenta,blue"
          "npx http-server storybook-static --port 6006 --silent"
          "npx wait-on tcp:6006 && npx test-storybook --url http://localhost:6006 --ci"
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: storybook-a11y-report
          path: storybook-test-results/
```

**Why Storybook Test Runner over addon-a11y for CI:**
- `addon-a11y` runs in the browser during Storybook development but cannot be automated in CI without the test runner
- `@storybook/test-runner` runs all stories as Playwright tests — every story is scanned without writing individual test files
- A design system with 200 components gets all 200 components scanned on every PR with zero per-component test authoring effort [community]



| Level | Criteria count | Description | Practical requirement |
|-------|------|-------------|----------------------|
| A | 30 | Minimum | Baseline; removing A-level barriers is the floor |
| AA | 20 additional | Mid-range | **Legal standard** in US/EU/CA/AU; target for all public apps |
| AAA | 28 additional | Enhanced | Aspirational; W3C does not recommend entire-site AAA conformance |

**Why not AAA?** W3C explicitly states that AAA conformance for entire sites is not recommended because some criteria cannot be satisfied for all content types. For example, 1.4.6 (Contrast Enhanced, 7:1 ratio) would make many brand color palettes unusable. AAA criteria are appropriate targets for specific content types (medical, government portals).

**Why AA specifically?** AA adds the most critical criteria missing from A: color contrast (1.4.3), keyboard shortcuts (2.1.4), resize text without scroll (1.4.4), no content-on-hover surprises (1.4.13), pointer gesture alternatives (2.5.1), and text spacing overrides (1.4.12).

### Tool Tradeoffs

| Tool | Pros | Cons | Best for |
|------|------|------|---------|
| axe-core (jest-axe) | Fast, CI-friendly, component-level | No contrast check in JSDOM | Unit/component CI gating |
| @axe-core/playwright | Real browser, catches contrast, dynamic content | Slower, needs live server | E2E CI gating |
| Playwright `page.accessibility.snapshot()` | Accessibility tree snapshot testing (structure, names, roles) | Not a WCAG checker; different purpose | Regression testing AT structure |
| Lighthouse (Chrome) | Integrated in DevTools, accessibility + perf score | Less detailed rule set, can score 100 with real issues | Dashboard metrics, quick checks |
| Storybook `@storybook/addon-a11y` | Per-story axe scan in browser, zero CI setup | Only covers isolated stories, not full user flows | Design system component gates |
| WAVE | Visual overlay, education-friendly | Manual only, not automatable | Auditor walkthroughs |
| Pa11y | CLI + CI automation | Less comprehensive than axe | Lightweight CI pipelines |
| Deque WorldSpace | Enterprise audit workflow management | Commercial license | Large org compliance tracking |
| axe DevTools (Deque) | Guided issue reporting with fix guidance | Commercial | Developer-guided manual audits |
| IBM Equal Access Checker | Free, targets WCAG 2.1 AA + EN 301 549 | Smaller community than axe | Supplementary EU EAA verification |
| Cypress + cypress-axe | Axe integration for Cypress E2E | Requires Cypress infrastructure; axe-core via Playwright is newer | Existing Cypress test suites |

**Playwright `page.accessibility.snapshot()` for structural regression testing:**

```typescript
// File: e2e/accessibility/a11y-tree-snapshot.spec.ts
// Captures the accessibility tree as a snapshot to catch structural regressions.
// This is DIFFERENT from axe scanning — it does not check WCAG rules but does
// detect when accessible names, roles, or tree structure change unexpectedly.
import { test, expect } from '@playwright/test';

test.describe('Accessibility tree snapshot regression', () => {
  test('navigation accessibility tree matches snapshot', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Capture the accessibility tree of the navigation region only
    const navHandle = await page.locator('nav[aria-label="Main navigation"]').elementHandle();
    if (!navHandle) {
      throw new Error('Main navigation not found');
    }

    const snapshot = await page.accessibility.snapshot({ root: navHandle });

    // Playwright's toMatchSnapshot stores the first run as the baseline.
    // Subsequent runs fail if the structure, role, or name changes — catching
    // regressions like a renamed aria-label or a missing list item.
    // NOTE: Remove this snapshot file when intentional navigation changes are made.
    expect(snapshot).toMatchSnapshot('main-nav-a11y-tree.json');
  });

  test('login form accessibility tree matches snapshot', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    const formHandle = await page.locator('form').elementHandle();
    const snapshot = await page.accessibility.snapshot({ root: formHandle ?? undefined });

    expect(snapshot).toMatchSnapshot('login-form-a11y-tree.json');
  });
});
```

**Storybook `@storybook/addon-a11y` integration** — runs axe on each story in the browser:

```typescript
// File: .storybook/main.ts
// Add addon-a11y to Storybook — provides an Accessibility panel with axe results per story.
import type { StorybookConfig } from '@storybook/react-vite';

const config: StorybookConfig = {
  addons: [
    '@storybook/addon-essentials',
    '@storybook/addon-a11y', // Adds axe scan in the Accessibility panel
  ],
  // ... rest of config
};

export default config;
```

```typescript
// File: src/components/Button/Button.stories.tsx
// Configure addon-a11y per story: set axe rules or disable for known issues.
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  title: 'Components/Button',
  component: Button,
  parameters: {
    a11y: {
      // Override axe config for this story — document reason
      config: {
        rules: [
          {
            // Disable color-contrast in Storybook (JSDOM limitation); test in Playwright
            id: 'color-contrast',
            enabled: false,
          },
        ],
      },
    },
  },
};

export default meta;
type Story = StoryObj<typeof Button>;

export const Primary: Story = {
  args: { label: 'Click me', variant: 'primary' },
};

export const IconOnly: Story = {
  args: { icon: 'close', ariaLabel: 'Close dialog' },
  parameters: {
    a11y: {
      // This story intentionally tests the icon button pattern
      // axe will verify aria-label is present
      config: { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa'] } },
    },
  },
};
```

**Automated vs Manual split:** axe-core detects approximately **57% of WCAG 2.1 issues** automatically. The remaining ~43% require keyboard testing, screen reader verification, and cognitive review.

### When NOT to Use Automated Accessibility Testing Alone

**Do not treat axe-only CI as sufficient when:**
- **Custom interactive widgets exist** (datepickers, comboboxes, sliders): axe validates ARIA syntax but cannot test whether NVDA announces options, whether arrow key navigation works in Application Mode, or whether VoiceOver swipe gestures behave correctly. Manual AT testing is mandatory.
- **Canvas, SVG, or WebGL-heavy UIs**: axe-core has no visibility into Canvas- or WebGL-rendered content. Text rendered on a canvas has no accessible name by default. You need `role="img"` with `aria-label` on the canvas element and potentially an off-screen text alternative.
- **PDF or non-HTML deliverables**: axe-core tests HTML only. PDFs require Adobe Acrobat's accessibility checker or PAC (PDF Accessibility Checker).
- **Cognitive accessibility requirements**: Plain language, reading level (WCAG AAA 3.1.5), consistent navigation (3.2.3), and help availability (WCAG 2.2 3.3.9) require expert human review.
- **Authentication flows with CAPTCHAs**: WCAG 2.2 SC 3.3.8 (Accessible Authentication) requires that no cognitive function test (e.g., recognizing distorted characters) is required. axe-core does not detect CAPTCHA patterns. Manual review is required.
- **Mobile native app layers** wrapped in WebViews: axe-core scans the HTML layer; native components outside the WebView are invisible to it. Use iOS Accessibility Inspector or Android Accessibility Scanner for native layers.

**Do not use WCAG 2.1 AA-only testing when:**
- Your product ships to the EU private sector (European Accessibility Act, deadline June 28, 2025): EN 301 549 v3.3.2 mandates WCAG 2.2 AA. Run axe with `wcag22aa` tag and add WCAG 2.2-specific Playwright tests for target size (2.5.8), focus appearance (2.4.11), and accessible authentication (3.3.8).
- Government/healthcare portals serving users with significant cognitive impairments may need AAA criteria (plain language, reading level)
- Applications used exclusively by internal technical staff can deprioritize full AAA, but AA remains legally required in many jurisdictions

### Adoption Cost

| Phase | Effort | Notes |
|-------|--------|-------|
| Add jest-axe to existing test suite | 1–2 hours | Install package, extend `expect`, add `.a11y.test.tsx` files per component. Fastest ROI. |
| Add `@axe-core/playwright` to E2E suite | 2–4 hours | Install package, add axe fixture (see pattern above), add one scan per critical flow. |
| Fix initial batch of axe violations | 1–3 days | First run on a brownfield app typically surfaces 20–100 violations. Most are missing labels, duplicate IDs, or missing landmark structure. |
| Manual keyboard audit per sprint | 2–4 hours/sprint | Navigate every new page/flow without mouse; log keyboard traps and focus order failures. |
| Screen reader audit per sprint | 4–8 hours/sprint | NVDA + Firefox minimum; VoiceOver for iOS flows. Time cost dominated by ramp-up if team lacks AT familiarity. |
| Full WCAG 2.1 AA expert audit | 3–5 days | One-time or per-major-release. Conducted by accessibility specialist. Covers all success criteria including cognitive and language requirements. |
| Remediation of inherited tech debt | 1–4 weeks | Brownfield projects with no prior a11y investment; depends on component library compliance. |

**Highest ROI first**: jest-axe on components (fast, free, catches ~50% of structural issues at the unit layer) → Playwright axe on critical flows → keyboard testing every sprint. Save full expert audits for pre-release milestones.

### Known axe-core False Positives

When axe-core is wrong — situations requiring rule suppression with documentation:

1. **`duplicate-id` in Storybook/isolated component tests**: Component testing frameworks render multiple instances of the same component in one DOM. axe flags duplicate IDs even though each component instance is logically separate. Fix by providing unique IDs per test, not by disabling the rule globally.

2. **`color-contrast` in JSDOM**: jest-axe reports `incomplete` (not a failure) for contrast because JSDOM cannot compute computed colors. This is correctly acknowledged uncertainty, not a false positive.

3. **`aria-required-parent` on portals**: Components rendered via React portals (e.g., `<Select>` option lists) may be mounted outside their logical parent. axe flags missing parent roles even when the logical parent is correctly set via `aria-owns`. Verify manually.

4. **`landmark-no-duplicate-banner` in micro-frontends**: When multiple micro-frontend apps render their own `<header>` within a shared shell, axe correctly flags multiple banners. Use `role="none"` on inner headers that are not site-wide banners.

5. **`scrollable-region-focusable` false positive on overflow containers with keyboard-managed content**: axe-core 4.9+ fires `scrollable-region-focusable` on `overflow: auto/scroll` containers without `tabIndex={0}`. This is correct for purely visual scroll containers, but `<ul>` listboxes and data grids with `role="grid"` / `role="listbox"` use roving tabindex instead of container focus — these are NOT false positives. Add `tabIndex={0}` to scroll containers serving as the focus trap or manage focus within the grid per ARIA grid pattern.

**When to suppress a rule**: only suppress with a documented reason in code comments (`axe.disableOtherRules(['rule-id'])` scoped to the specific test assertion). Never suppress globally without a team review.

### WCAG 2.2 Criteria QA Teams Should Start Testing Now

WCAG 2.2 (published October 2023) adds 9 new criteria at A/AA. As of 2026, the EU Accessibility Act (EAA) compliance deadline (June 28, 2025) explicitly references WCAG 2.2 AA via EN 301 549 v3.3.2, making WCAG 2.2 a legal requirement for EU private-sector products. US Section 508 and UK PSBAR are still referencing WCAG 2.1 AA, but WCAG 2.2 is increasingly cited in procurement requirements globally. The most immediately impactful:

| Criterion | Level | What QA should test |
|---|---|---|
| 2.4.11 Focus Appearance | AA | Focus indicator must have ≥2px outline, ≥3:1 contrast ratio |
| 2.5.7 Dragging Movements | AA | All drag-and-drop has a single-pointer alternative (e.g., keyboard reorder) |
| 2.5.8 Target Size (Minimum) | AA | Interactive targets ≥ 24×24 CSS pixels (or ≥ spacing from adjacent targets) |
| 3.3.8 Accessible Authentication | AA | No cognitive function test (no distorted CAPTCHAs) required for login |

**Practical impact**: 2.5.8 Target Size — many mobile navigation patterns and icon buttons are smaller than 24×24px. Check 2.4.11 Focus Appearance — many design systems use thin focus rings that will fail the new 2px + 3:1 contrast requirement.

**WCAG 2.2 target size test (2.5.8)** — Playwright can measure bounding box dimensions:

```typescript
// File: e2e/accessibility/wcag22-target-size.spec.ts
// WCAG 2.2 SC 2.5.8: all interactive targets must be ≥ 24×24 CSS pixels
// (or have ≥ 24px spacing from adjacent targets, but testing the size is the
//  practical first gate — spacing analysis requires custom geometry logic).
import { test, expect } from '@playwright/test';

const MINIMUM_TARGET_PX = 24;

test.describe('WCAG 2.2 Target Size (2.5.8)', () => {
  test('all interactive controls on homepage meet 24×24px minimum', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const violations = await page.evaluate((minPx) => {
      const interactiveSelector =
        'button, a[href], input, select, textarea, [role="button"], [role="link"], [tabindex="0"]';
      const elements = Array.from(document.querySelectorAll<HTMLElement>(interactiveSelector));

      return elements
        .map((el) => {
          const rect = el.getBoundingClientRect();
          return {
            tag: el.tagName.toLowerCase(),
            role: el.getAttribute('role') ?? '',
            text: (el.textContent ?? '').trim().slice(0, 40),
            width: Math.round(rect.width),
            height: Math.round(rect.height),
          };
        })
        .filter((el) => el.width > 0 && el.height > 0) // skip display:none
        .filter((el) => el.width < minPx || el.height < minPx);
    }, MINIMUM_TARGET_PX);

    if (violations.length > 0) {
      console.table(violations);
    }
    expect(violations).toEqual([]);
  });
});
```

**WCAG 2.2 focus appearance test (2.4.11)** — Playwright can trigger focus and inspect computed outline styles:

```typescript
// File: e2e/accessibility/wcag22-focus-appearance.spec.ts
// WCAG 2.2 SC 2.4.11: Focus indicator must be ≥2px outline with ≥3:1 contrast vs adjacent colors.
// This test checks the outline-width of focused interactive elements as a first-gate check.
// Full contrast ratio verification requires a color contrast library with actual color values.
import { test, expect } from '@playwright/test';

const MINIMUM_OUTLINE_PX = 2;

test.describe('WCAG 2.2 Focus Appearance (2.4.11)', () => {
  test('primary buttons have ≥2px focus outline when keyboard focused', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Tab to the first button and check its focus indicator
    await page.keyboard.press('Tab');

    const focusStyle = await page.evaluate(() => {
      const el = document.activeElement as HTMLElement | null;
      if (!el) return null;
      const style = getComputedStyle(el);
      return {
        tag: el.tagName.toLowerCase(),
        outlineWidth: style.outlineWidth,
        outlineStyle: style.outlineStyle,
        outlineColor: style.outlineColor,
        outlineOffset: style.outlineOffset,
      };
    });

    expect(focusStyle).not.toBeNull();
    // Outline style must not be 'none'
    expect(focusStyle!.outlineStyle).not.toBe('none');
    // Outline width must be ≥ 2px
    const widthPx = parseFloat(focusStyle!.outlineWidth);
    expect(widthPx).toBeGreaterThanOrEqual(MINIMUM_OUTLINE_PX);
  });

  test('interactive elements on login form have visible focus indicators', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    const interactiveSelector = 'button, a[href], input:not([type="hidden"]), select, textarea';
    const focusIssues = await page.evaluate(async (selector) => {
      const elements = Array.from(document.querySelectorAll<HTMLElement>(selector));
      const issues: Array<{ tag: string; label: string; issue: string }> = [];

      for (const el of elements) {
        el.focus();
        const style = getComputedStyle(el);
        const label = el.getAttribute('aria-label') ?? el.textContent?.trim().slice(0, 30) ?? el.id;
        if (style.outlineStyle === 'none' || style.outlineWidth === '0px') {
          issues.push({ tag: el.tagName.toLowerCase(), label, issue: 'No outline on focus' });
        }
      }
      return issues;
    }, interactiveSelector);

    if (focusIssues.length > 0) {
      console.table(focusIssues);
    }
    expect(focusIssues).toEqual([]);
  });
});
```

### Screen Reader Testing Matrix

Screen readers are the primary assistive technology for blind and low-vision users. Automated tools cannot replicate the screen reader experience.

| Screen Reader | Browser | Platform | Market share (approx.) |
|---|---|---|---|
| NVDA (free) | Firefox | Windows | ~41% |
| JAWS (commercial) | Chrome/Edge | Windows | ~53% |
| VoiceOver | Safari | macOS/iOS | ~7% desktop, dominant mobile |
| TalkBack | Chrome | Android | Dominant Android |

**Minimum viable manual test checklist:**
1. Tab through every page — every interactive element should be reachable and have a meaningful label
2. Activate every button, link, and form control by keyboard (Enter/Space)
3. Verify that dynamic content updates (form errors, loading states, toasts) are announced automatically
4. Check that modal dialogs trap focus and that closing returns focus to the trigger element
5. Verify that images have contextually meaningful `alt` text (not just non-empty)
6. Test the skip link — screen reader users depend on it to skip repetitive navigation

### WCAG 1.3.5, 1.4.10, and 1.4.12 Testing (Often Missed AA Criteria)

These three WCAG 2.1 AA criteria are frequently omitted from accessibility test suites because they do not fire axe-core violations — they require specific testing scenarios.

**1.3.5 Identify Input Purpose**: axe-core does not currently check `autocomplete` attribute presence. Manual check required.

**1.4.10 Reflow**: Content at 320px CSS width must not require horizontal scrolling (unless for specific content like maps or data tables). Playwright can emulate a narrow viewport.

**1.4.12 Text Spacing**: Content must not lose information when CSS overrides increase letter, word, and line spacing. Playwright can inject text-spacing CSS and verify no content overflow.

```typescript
// File: e2e/accessibility/wcag21-missed-criteria.spec.ts
// Tests for WCAG 2.1 AA criteria that axe-core does not catch automatically:
// 1.3.5 Identify Input Purpose, 1.4.10 Reflow, 1.4.12 Text Spacing.
import { test, expect } from '@playwright/test';

test.describe('WCAG 2.1 AA — commonly missed criteria', () => {
  // ─── 1.3.5 Identify Input Purpose ─────────────────────────────────────────
  // Form fields collecting personal info must have autocomplete attribute.
  // axe-core does not currently check this criterion — manual/test required.
  test.describe('1.3.5 Identify Input Purpose (autocomplete attributes)', () => {
    const AUTOCOMPLETE_MAP: Record<string, string> = {
      'input[name="name"], input[id*="name"][type="text"]': 'name',
      'input[type="email"]': 'email',
      'input[type="tel"]': 'tel',
      'input[autocomplete="given-name"], input[name="first_name"]': 'given-name',
      'input[autocomplete="family-name"], input[name="last_name"]': 'family-name',
      'input[type="password"]:not([autocomplete="new-password"])': 'current-password',
    };

    test('registration form has autocomplete attributes on personal data fields', async ({
      page,
    }) => {
      await page.goto('/register');
      await page.waitForLoadState('networkidle');

      // Check that each personal data field has an autocomplete attribute
      const missingAutocomplete = await page.evaluate(() => {
        const personalFields = document.querySelectorAll<HTMLInputElement>(
          'input[type="email"], input[type="tel"], input[name*="name"], input[type="text"]'
        );
        const missing: string[] = [];
        personalFields.forEach((input) => {
          if (!input.hasAttribute('autocomplete')) {
            const id = input.id || input.name || input.type;
            missing.push(`<input ${id ? `id="${id}"` : ''} type="${input.type}">`);
          }
        });
        return missing;
      });

      if (missingAutocomplete.length > 0) {
        console.error(
          'Fields missing autocomplete attribute (WCAG 1.3.5):\n' +
          missingAutocomplete.join('\n')
        );
      }
      expect(missingAutocomplete).toEqual([]);
    });
  });

  // ─── 1.4.10 Reflow ──────────────────────────────────────────────────────────
  // Content must be accessible at 320px width without horizontal scrolling.
  // Exception: data tables, maps, and video can scroll horizontally.
  test.describe('1.4.10 Reflow (320px viewport — no horizontal scroll)', () => {
    test.use({ viewport: { width: 320, height: 568 } });

    test('homepage reflows at 320px with no horizontal overflow', async ({ page }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');

      const hasHorizontalOverflow = await page.evaluate(() => {
        // Check the document body for horizontal overflow
        return document.body.scrollWidth > document.documentElement.clientWidth;
      });

      expect(hasHorizontalOverflow).toBe(false);
    });

    test('login form reflows at 320px', async ({ page }) => {
      await page.goto('/login');
      await page.waitForLoadState('networkidle');

      const hasHorizontalOverflow = await page.evaluate(() => {
        return document.body.scrollWidth > document.documentElement.clientWidth;
      });

      expect(hasHorizontalOverflow).toBe(false);
    });
  });

  // ─── 1.4.12 Text Spacing ────────────────────────────────────────────────────
  // Content must not lose information when text spacing CSS is overridden:
  //   - Line height: ≥ 1.5 × font size
  //   - Paragraph spacing: ≥ 2 × font size
  //   - Letter spacing: ≥ 0.12 × font size
  //   - Word spacing: ≥ 0.16 × font size
  // Inject the bookmarklet CSS and verify no content is truncated or overlapping.
  test.describe('1.4.12 Text Spacing (user CSS overrides)', () => {
    // CSS from the text-spacing bookmarklet (W3C technique C36):
    const TEXT_SPACING_CSS = `
      * {
        line-height: 1.5 !important;
        letter-spacing: 0.12em !important;
        word-spacing: 0.16em !important;
      }
      p { margin-bottom: 2em !important; }
    `;

    test('homepage has no truncated or hidden text with text spacing overrides', async ({
      page,
    }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // Inject text-spacing CSS override
      await page.addStyleTag({ content: TEXT_SPACING_CSS });

      // Check for common failure patterns: overflow hidden clipping content
      const clippedElements = await page.evaluate(() => {
        const elements = Array.from(document.querySelectorAll<HTMLElement>('*'));
        const clipped: string[] = [];

        elements.forEach((el) => {
          const style = getComputedStyle(el);
          // Only check elements with visible text
          if (!el.textContent?.trim()) return;
          if (el.children.length > 0) return; // Skip non-leaf nodes

          // If overflow is hidden and scrollHeight > clientHeight, text is clipped
          if (
            style.overflow === 'hidden' &&
            el.scrollHeight > el.clientHeight + 2 // +2px tolerance
          ) {
            clipped.push(`${el.tagName.toLowerCase()}[${el.className}]: text clipped`);
          }
        });

        return clipped.slice(0, 10); // Return first 10 issues max
      });

      if (clippedElements.length > 0) {
        console.error(
          'Text clipped with text-spacing overrides (WCAG 1.4.12):\n' +
          clippedElements.join('\n')
        );
      }

      expect(clippedElements).toEqual([]);
    });
  });
});
```

### Cognitive Accessibility Testing Patterns

Cognitive accessibility addresses users with dyslexia, ADHD, memory impairments, anxiety disorders, and non-native language users. WCAG 2.x coverage of cognitive accessibility is limited (mostly AAA level). WCAG 3.0 will address it as a first-class concern. In the meantime, teams can implement testable patterns covering the most impactful cognitive accessibility criteria.

**Why this matters:** Cognitive disabilities affect approximately 15% of the global population — the largest single category of disability. Yet most accessibility testing focuses exclusively on screen reader and keyboard users (motor/visual). A WCAG 2.1 AA-passing site can still be completely unusable for users with ADHD, anxiety, or reading disorders.

**Testable cognitive accessibility patterns:**

```typescript
// File: e2e/accessibility/cognitive-a11y.spec.ts
// Tests for cognitive accessibility patterns that go beyond standard WCAG 2.1 AA automation.
// These tests target: timeout warnings, error recovery, session management, and content clarity.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Cognitive accessibility patterns', () => {

  // WCAG 2.2 SC 3.3.7 (A): Redundant entry — don't re-ask for info provided this session
  // Already covered in WCAG 2.2 checklist above.

  // WCAG 2.1 SC 2.2.1 (A): Timing Adjustable — if there is a time limit, user must be able to extend it.
  // Test: if a session timeout warning exists, it must allow extension.
  test('session timeout dialog must provide a way to extend the session', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Simulate session timeout warning (trigger it manually if possible)
    // This tests that the warning dialog itself is accessible and provides an extension mechanism
    const sessionWarningTrigger = page.locator('[data-testid="trigger-session-warning"]');
    const triggerExists = await sessionWarningTrigger.count() > 0;

    if (triggerExists) {
      await sessionWarningTrigger.click();
      await page.waitForSelector('[data-testid="session-timeout-dialog"]');

      // The dialog must have an accessible role
      const dialog = page.getByRole('dialog');
      await expect(dialog).toBeVisible();

      // Must provide a way to extend the session
      const extendButton = page.getByRole('button', { name: /extend|continue|stay/i });
      await expect(extendButton).toBeVisible();

      // Run axe on the dialog
      const results = await new AxeBuilder({ page })
        .include('[data-testid="session-timeout-dialog"]')
        .withTags(['wcag2a', 'wcag2aa'])
        .analyze();

      expect(results.violations).toEqual([]);
    }
  });

  // WCAG 2.1 SC 3.3.4 (AA): Error Prevention — check-confirm-correct for legal/financial submissions.
  // Test: verify that a confirmation step exists before destructive/financial actions.
  test('checkout flow provides order review before final submission', async ({ page }) => {
    await page.goto('/cart');
    await page.waitForLoadState('networkidle');

    const checkoutButton = page.getByRole('button', { name: /checkout|place order/i });
    const checkoutExists = await checkoutButton.count() > 0;

    if (checkoutExists) {
      await checkoutButton.click();
      // There should be a review/confirmation step before irreversible submission
      await page.waitForLoadState('networkidle');

      // Look for review indicators: "Review your order", order summary, "Edit" links
      const reviewIndicators = [
        'h1:has-text("Review")',
        '[data-testid="order-summary"]',
        'text=Review your order',
        'button:has-text("Edit")',
      ];

      const hasReviewStep = await page.evaluate((selectors) => {
        return selectors.some((s) => document.querySelector(s) !== null);
      }, reviewIndicators);

      if (!hasReviewStep) {
        console.warn(
          '[WCAG 3.3.4] No order review step detected before checkout submission. ' +
          'Verify manually that users can review and correct orders before final submission.'
        );
      }
      // Log as warning rather than hard fail — review UI patterns vary
      // The key check is that a final "Place Order" button is not on the cart page itself
      const immediateOrderButton = page.locator('[data-testid="place-order-button"]');
      expect(await immediateOrderButton.count()).toBe(0); // No direct order placement from cart
    }
  });

  // WCAG 2.2 SC 3.2.6 (A): Consistent Help — help link in same relative location on all pages.
  // Test: if a help/support link exists, verify it is in the same position on critical pages.
  test('3.2.6: help link is consistently positioned across pages', async ({ page }) => {
    const criticalPages = ['/', '/login', '/dashboard', '/settings'];
    const helpPositions: Array<{ page: string; bottom: number; right: number }> = [];

    for (const url of criticalPages) {
      await page.goto(url);
      await page.waitForLoadState('networkidle');

      const helpPosition = await page.evaluate(() => {
        // Look for common help link patterns
        const helpSelectors = [
          'a[href*="help"]',
          'a[href*="support"]',
          '[aria-label*="help"]',
          '[data-testid*="help"]',
        ];
        for (const selector of helpSelectors) {
          const el = document.querySelector<HTMLElement>(selector);
          if (el) {
            const rect = el.getBoundingClientRect();
            // Return normalized position (bottom/right of viewport)
            return {
              bottom: Math.round(window.innerHeight - rect.bottom),
              right: Math.round(window.innerWidth - rect.right),
            };
          }
        }
        return null;
      });

      if (helpPosition) {
        helpPositions.push({ page: url, ...helpPosition });
      }
    }

    // If help link found on multiple pages, verify consistent position (within 50px tolerance)
    if (helpPositions.length >= 2) {
      const firstPos = helpPositions[0];
      for (const pos of helpPositions.slice(1)) {
        const bottomDiff = Math.abs(pos.bottom - firstPos.bottom);
        const rightDiff = Math.abs(pos.right - firstPos.right);
        expect(bottomDiff).toBeLessThan(50); // WCAG 3.2.6: same relative position
        expect(rightDiff).toBeLessThan(50);
      }
    }
  });
});
```

**Cognitive accessibility manual testing checklist (no automation possible):**

| Check | WCAG | What to look for |
|-------|------|-----------------|
| Plain language | 3.1.5 (AAA) | Reading level ≤ grade 8 for general audiences; technical content grade ≤ 12 |
| Error messages are specific | 3.3.1 (A) | "Enter a valid email" not "Invalid input"; tells users what to fix |
| Consistent navigation | 3.2.3 (AA) | Same nav items in same order on every page |
| On Focus/Input no unexpected changes | 3.2.1–3.2.2 (A) | No form submission, page redirect, or dialog on field focus/input |
| Meaningful section headings | 2.4.6 (AA) | Each section heading describes the content; no "Section 1" headings |
| Images of text avoided | 1.4.5 (AA) | Real text used instead of images of text (logos excepted) |
| Animation can be paused | 2.2.2 (A) | Auto-play animations under 5 seconds OR has pause/stop control |

[community] Teams that invest in WCAG AA compliance but skip cognitive accessibility patterns miss the largest disability population. The most impactful quick wins are: specific error messages (3.3.1), consistent navigation (3.2.3), no unexpected context changes (3.2.1), and a well-structured heading hierarchy (2.4.6) — all AA or A level, all testable.

### WCAG 2.5.3 Label in Name — Voice Control Compatibility Testing

WCAG 2.5.3 (Level A) requires that the accessible name of a UI component with visible text must *contain* the visible text. Voice control users (Dragon, Voice Control on macOS/iOS) activate controls by speaking the visible label. If the accessible name differs from the visible text, the voice command fails.

**Common failure patterns:**
- Button has visible text "Buy now" but `aria-label="Purchase product"` — voice user says "Buy now" and nothing happens
- Icon button with `aria-label="X"` but visible label "Close" — voice user says "Close" but the button is named "X"
- A link wrapping an image with `alt="home"` and visible span "Home page" — accessible name is "home" but visible text is "Home page"

axe-core catches some 2.5.3 violations via the `label-content-name-mismatch` rule, but it does not catch all cases. Playwright can verify alignment programmatically:

```typescript
// File: e2e/accessibility/label-in-name.spec.ts
// WCAG 2.5.3 Label in Name: verify accessible names contain visible text labels.
// Catches voice control failures where accessible name differs from visible label.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('WCAG 2.5.3 Label in Name', () => {
  test('axe label-content-name-mismatch rule passes on homepage', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Run specifically the label-content-name-mismatch rule
    const results = await new AxeBuilder({ page })
      .withRules(['label-content-name-mismatch'])
      .analyze();

    expect(results.violations).toEqual([]);
  });

  test('all buttons with visible text have accessible names containing that text', async ({
    page,
  }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const mismatches = await page.evaluate(() => {
      const buttons = Array.from(document.querySelectorAll<HTMLButtonElement>('button'));
      const issues: Array<{ html: string; visibleText: string; ariaLabel: string }> = [];

      buttons.forEach((btn) => {
        const visibleText = btn.textContent?.trim() ?? '';
        const ariaLabel = btn.getAttribute('aria-label') ?? '';

        // If button has aria-label AND visible text, check containment
        if (ariaLabel && visibleText && visibleText.length > 0) {
          // WCAG 2.5.3: accessible name must CONTAIN the visible text (case-insensitive)
          const normalized = (s: string) => s.toLowerCase().replace(/\s+/g, ' ').trim();
          if (!normalized(ariaLabel).includes(normalized(visibleText))) {
            issues.push({
              html: btn.outerHTML.slice(0, 80),
              visibleText,
              ariaLabel,
            });
          }
        }
      });

      return issues;
    });

    if (mismatches.length > 0) {
      console.error(
        'WCAG 2.5.3 violations — accessible name does not contain visible text:\n' +
        mismatches
          .map(
            (m) =>
              `  visible: "${m.visibleText}" | aria-label: "${m.ariaLabel}"\n  ${m.html}`
          )
          .join('\n')
      );
    }

    expect(mismatches).toEqual([]);
  });
});
```



For brownfield projects with existing accessibility debt, a "zero violations or it fails CI" gate is often too aggressive to adopt immediately — it causes every PR to fail on pre-existing issues unrelated to the PR's changes. The **known violations baseline** pattern lets teams:
1. Snapshot existing violations as an accepted baseline
2. Gate CI on **no new violations** (regressions blocked)
3. Gradually remediate baseline items over sprints

**Why this approach works:** It separates "do not make things worse" (enforced immediately) from "fix all existing issues" (scheduled remediation). Teams that skip this step often abandon CI gating entirely because the initial failure count is overwhelming.

```typescript
// File: e2e/accessibility/violations-baseline.spec.ts
// Known violations baseline: allows pre-existing a11y debt while blocking regressions.
// USAGE:
//   1. Run once with GENERATE_BASELINE=true to record current violations.
//   2. Commit the generated baseline file to version control.
//   3. CI runs in normal mode — it fails only if new violations appear.
//   4. Schedule quarterly sprints to reduce baseline items.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import * as fs from 'fs';
import * as path from 'path';

const BASELINE_PATH = path.join(__dirname, 'known-violations-baseline.json');
const GENERATE_BASELINE = process.env.GENERATE_BASELINE === 'true';

type BaselineEntry = {
  page: string;
  ruleId: string;
  impact: string;
  description: string;
  nodeCount: number;
};

function loadBaseline(): BaselineEntry[] {
  if (!fs.existsSync(BASELINE_PATH)) return [];
  return JSON.parse(fs.readFileSync(BASELINE_PATH, 'utf-8')) as BaselineEntry[];
}

function saveBaseline(entries: BaselineEntry[]): void {
  fs.writeFileSync(BASELINE_PATH, JSON.stringify(entries, null, 2));
}

function violationKey(entry: BaselineEntry): string {
  return `${entry.page}::${entry.ruleId}`;
}

const pagesToScan = ['/', '/login', '/dashboard', '/settings'];

test.describe('Accessibility regression gate (baseline mode)', () => {
  test('no new violations beyond the accepted baseline', async ({ page }) => {
    const baseline = loadBaseline();
    const baselineKeys = new Set(baseline.map(violationKey));

    const newViolations: BaselineEntry[] = [];
    const allCurrentEntries: BaselineEntry[] = [];

    for (const url of pagesToScan) {
      await page.goto(url);
      await page.waitForLoadState('networkidle');

      const results = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
        .analyze();

      for (const v of results.violations) {
        const entry: BaselineEntry = {
          page: url,
          ruleId: v.id,
          impact: v.impact ?? 'unknown',
          description: v.description,
          nodeCount: v.nodes.length,
        };
        allCurrentEntries.push(entry);
        if (!baselineKeys.has(violationKey(entry))) {
          newViolations.push(entry);
        }
      }
    }

    if (GENERATE_BASELINE) {
      // Baseline generation mode: save current violations as the accepted baseline
      saveBaseline(allCurrentEntries);
      console.log(`[a11y] Baseline generated: ${allCurrentEntries.length} violations accepted.`);
      console.log(`[a11y] Commit ${BASELINE_PATH} to version control.`);
      return; // Do not fail in generation mode
    }

    // Normal CI mode: fail only on new violations (regressions)
    if (newViolations.length > 0) {
      const report = newViolations
        .map((v) => `[${v.impact.toUpperCase()}] ${v.ruleId} on ${v.page}: ${v.description}`)
        .join('\n');
      expect.fail(
        `${newViolations.length} NEW accessibility violation(s) detected (not in baseline):\n\n${report}`
      );
    }

    // Log baseline items as a reminder of existing debt
    const resolvedItems = baseline.filter(
      (b) => !allCurrentEntries.some((c) => violationKey(c) === violationKey(b))
    );
    if (resolvedItems.length > 0) {
      console.log(
        `[a11y] ${resolvedItems.length} baseline item(s) resolved — update the baseline file!`
      );
    }
  });
});
```

**Baseline file format** (`known-violations-baseline.json` example):
```json
[
  {
    "page": "/",
    "ruleId": "color-contrast",
    "impact": "serious",
    "description": "Elements must have sufficient color contrast",
    "nodeCount": 3
  },
  {
    "page": "/settings",
    "ruleId": "label",
    "impact": "critical",
    "description": "Form elements must have labels",
    "nodeCount": 1
  }
]
```

**Baseline workflow:**
1. First run: `GENERATE_BASELINE=true npx playwright test e2e/accessibility/violations-baseline.spec.ts`
2. Commit `known-violations-baseline.json`
3. CI gating: every PR runs without `GENERATE_BASELINE` — new violations fail the build
4. Sprint remediation: fix baseline items, re-generate baseline, commit updated baseline

---

### Advanced axe-core Configuration Patterns

**Excluding third-party widget regions:**

```typescript
// File: e2e/accessibility/advanced-axe-config.spec.ts
// Demonstrates axe context exclusions, resultTypes filtering, and iframe configuration.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Advanced axe configuration', () => {
  test('scan page excluding third-party chat widget and cookie banner', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      // Exclude known third-party widgets that are outside our control
      // Document WHY each exclusion exists so the team can review periodically
      .exclude('#intercom-container')       // Third-party: Intercom chat widget
      .exclude('#cookie-consent-banner')    // Third-party: CookieYes banner (vendor ships accessible version)
      // Include only violations (skip incomplete/passes) for faster CI output
      .options({ resultTypes: ['violations', 'incomplete'] })
      .analyze();

    // Log incomplete items as warnings (they require human review)
    if (results.incomplete.length > 0) {
      console.warn(`[a11y] ${results.incomplete.length} incomplete items need manual review`);
      results.incomplete.forEach((item) => console.warn(`  - ${item.id}: ${item.description}`));
    }

    expect(results.violations).toEqual([]);
  });

  test('scan only the authenticated user profile section', async ({ page }) => {
    await page.goto('/profile');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      // Use include() to scope scan to a specific region — useful for:
      // 1. Isolating failures to a component under test
      // 2. Avoiding noise from unrelated page sections during component-focused sprints
      .include('[data-testid="user-profile"]')
      .analyze();

    expect(results.violations).toEqual([]);
  });
});
```

**jest-axe with global configuration via setup file:**

```typescript
// File: jest.setup.ts
// Configure jest-axe globally for all test files via the Jest setupFilesAfterFramework entry.
import { configureAxe } from 'jest-axe';

// Apply project-wide axe defaults:
// - Target WCAG 2.1 AA + best practices
// - Disable color-contrast (JSDOM cannot compute it; Playwright tests handle this)
// - Disable duplicate-id check in isolation (components share IDs across test renders)
configureAxe({
  globalOptions: {
    rules: [
      { id: 'color-contrast', enabled: false },
      // Enable WCAG 2.2 rules when upgrading target conformance level
      // { id: 'target-size', enabled: true },
    ],
    runOnly: {
      type: 'tag',
      values: ['wcag2a', 'wcag2aa', 'wcag21aa', 'best-practice'],
    },
  },
});
```

### Custom axe-core Rules for Organization-Specific Standards

Teams enforcing standards beyond WCAG (design-system token compliance, custom branding rules, specific ARIA patterns required by their component library) can author custom axe rules. Custom rules integrate into the same reporting pipeline as built-in rules, appear in violation reports, and can be required-to-pass in CI.

**When to author a custom rule:**
- Your design system requires a specific `data-*` attribute on all interactive components for analytics (and you want to enforce presence)
- Organization policy requires every image to have a detailed `alt` with specific format (beyond axe's non-empty check)
- Internal component library mandates all modals use a `data-modal` attribute for teleportation support
- You want to enforce a brand-specific minimum font size policy

**When NOT to use custom rules:**
- When a built-in axe rule already covers the requirement — duplicate rules create noise
- When the check requires visual rendering (use Playwright instead)
- For one-off per-component checks — use regular test assertions instead

```typescript
// File: e2e/config/axe-custom-rules.ts
// Custom axe-core rules for organization-specific accessibility standards.
// Register these rules via axe.configure() before running scans.
import axe from 'axe-core';
import type { Rule, Check } from 'axe-core';

// Custom check: all <img> with non-empty alt must have alt longer than 2 characters
// (enforces meaningful alt text, not just presence)
const meaningfulAltCheck: Check = {
  id: 'meaningful-alt-text',
  evaluate(node: Element): boolean {
    const alt = (node as HTMLImageElement).getAttribute('alt');
    // Decorative images with alt="" are acceptable
    if (alt === '') return true;
    // Non-decorative images need alt text longer than 2 chars (e.g. not ".")
    return alt !== null && alt.trim().length > 2;
  },
  metadata: {
    type: 'failure',
    messages: {
      pass: 'Image has meaningful alt text',
      fail: 'Image alt text is too short to be meaningful (must be > 2 characters or alt="")',
    },
  },
};

// Custom rule: img elements must have meaningful alt text
const meaningfulAltRule: Rule = {
  id: 'org-meaningful-alt',
  selector: 'img',
  tags: ['org-standards', 'best-practice'],
  metadata: {
    description: 'Images must have meaningful alt text (> 2 characters) or empty alt for decorative images',
    help: 'Provide descriptive alt text that communicates the image content or purpose',
    helpUrl: 'https://your-org.example.com/accessibility/images',
  },
  any: ['meaningful-alt-text'],
  all: [],
  none: [],
};

// Custom check: all interactive elements must have data-testid (for QA automation)
const testIdCheck: Check = {
  id: 'has-test-id',
  evaluate(node: Element): boolean {
    return node.hasAttribute('data-testid');
  },
  metadata: {
    type: 'failure',
    messages: {
      pass: 'Interactive element has data-testid',
      fail: 'Interactive element is missing data-testid attribute (required by org QA policy)',
    },
  },
};

const testIdRule: Rule = {
  id: 'org-require-test-id',
  selector: 'button, a[href], input, select, textarea',
  tags: ['org-standards'],
  metadata: {
    description: 'Interactive elements must have data-testid attribute for QA automation',
    help: 'Add data-testid to all interactive elements',
    helpUrl: 'https://your-org.example.com/qa/test-ids',
  },
  any: ['has-test-id'],
  all: [],
  none: [],
};

// Register custom rules and checks with axe-core
export function registerCustomRules(): void {
  axe.configure({
    checks: [meaningfulAltCheck, testIdCheck],
    rules: [meaningfulAltRule, testIdRule],
  });
}
```

```typescript
// File: e2e/accessibility/custom-rules.spec.ts
// Test custom organization-specific axe rules alongside standard WCAG rules.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import axe from 'axe-core';

// Must import registration before the AxeBuilder calls inject axe-core
import { registerCustomRules } from '../config/axe-custom-rules';

test.describe('Organization standards (custom axe rules)', () => {
  test.beforeAll(() => {
    // Register custom rules once before the suite
    registerCustomRules();
  });

  test('all interactive elements on dashboard have data-testid', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      // Combine standard WCAG rules with org-specific rules
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'org-standards'])
      .analyze();

    // Filter violations to just org-standard failures for targeted reporting
    const orgViolations = results.violations.filter((v) =>
      v.tags.includes('org-standards')
    );
    const wcagViolations = results.violations.filter((v) =>
      !v.tags.includes('org-standards')
    );

    if (orgViolations.length > 0) {
      console.warn('[Org policy violations]', orgViolations.map((v) => v.id));
    }

    expect(wcagViolations).toEqual([]);
    // Org standards violations are tracked separately — treat as warnings in CI
    // or escalate to errors once the team has remediated existing elements
  });
});
```

**Custom rule authoring checklist:**
- `id`: must be unique and not conflict with built-in axe rule IDs
- `tags`: include an org-specific tag (e.g., `'org-standards'`) to filter separately from WCAG rules
- `metadata.helpUrl`: link to your internal docs — makes it actionable when the rule fires in a report
- `evaluate` function: runs in the browser context — no module imports, no async
- Test the custom rule itself: write a unit test that verifies `evaluate` returns `true`/`false` for known inputs

---

### Accessible Name Computation Testing

The **accessible name computation algorithm** (ARIA spec §4.3) defines how browsers compute the announced name for an element: content > aria-labelledby > aria-label > title > placeholder. Testing that computed names match expectations is critical for 4.1.2 (Name, Role, Value). Two approaches: `@testing-library` query priority (reflects accessible tree) and Playwright's `getByRole` with the `name` option.

**Why this pattern matters:** Teams frequently add ARIA attributes they believe will be read, then discover the browser computes a different name due to precedence rules. An element with both `aria-labelledby` and `aria-label` always uses `aria-labelledby`. An element whose content text differs from its `aria-label` uses `aria-label`. These overrides are invisible in visual tests.

```typescript
// File: src/components/IconButton/IconButton.a11y.test.tsx
// Test accessible name computation for icon-only buttons using @testing-library query priority.
// getByRole({ name }) asserts the accessible name computed by the a11y tree — not DOM text.
import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

// Icon button patterns in order of preference:
// 1. aria-label on button (no visible text)
// 2. aria-labelledby pointing to existing visible text
// 3. visually hidden <span> inside button with screen-reader-only class

const IconButton: React.FC<{ label: string; onClick: () => void }> = ({ label, onClick }) => (
  <button type="button" aria-label={label} onClick={onClick}>
    {/* SVG icon: aria-hidden prevents double-announcement of icon content */}
    <svg aria-hidden="true" focusable="false" width="16" height="16">
      <path d="M3 9h14v-2H3v2zm0 5h14v-2H3v2zm0-12v2h14V2H3z" />
    </svg>
  </button>
);

// Pattern 2: button labeled by adjacent visible text via aria-labelledby
const LabeledByButton: React.FC<{ labelId: string; onClick: () => void }> = ({
  labelId,
  onClick,
}) => (
  <div>
    <span id={labelId} style={{ display: 'block', fontSize: '0.75rem' }}>
      Download report
    </span>
    <button type="button" aria-labelledby={labelId} onClick={onClick}>
      <svg aria-hidden="true" focusable="false" width="16" height="16">
        <path d="M5 20h14v-2H5v2zm7-18l-5 5h3v4h4v-4h3l-5-5z" />
      </svg>
    </button>
  </div>
);

describe('IconButton accessible name', () => {
  it('aria-label is the computed accessible name', () => {
    render(<IconButton label="Open navigation menu" onClick={() => {}} />);
    // getByRole({ name }) queries by the computed accessible name
    // If the accessible name does not match, this query fails — catching name computation bugs
    expect(screen.getByRole('button', { name: 'Open navigation menu' })).toBeInTheDocument();
  });

  it('aria-labelledby overrides aria-label when both present', async () => {
    const { container } = render(<LabeledByButton labelId="dl-label" onClick={() => {}} />);
    // The button's accessible name comes from the <span> text, not from aria-label
    expect(screen.getByRole('button', { name: 'Download report' })).toBeInTheDocument();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('SVG icon-only button without aria-label fails button-name rule', async () => {
    const { container } = render(
      <button type="button">
        <svg aria-hidden="true" focusable="false" width="16" height="16">
          <path d="M3 9h14v-2H3v2z" />
        </svg>
      </button>
    );
    const results = await axe(container);
    expect(results.violations.map((v) => v.id)).toContain('button-name');
  });

  it('visually-hidden span inside button provides accessible name', async () => {
    const { container } = render(
      <button type="button">
        <svg aria-hidden="true" focusable="false" width="16" height="16">
          <path d="M3 9h14v-2H3v2z" />
        </svg>
        <span className="sr-only">Toggle sidebar</span>
      </button>
    );
    expect(screen.getByRole('button', { name: 'Toggle sidebar' })).toBeInTheDocument();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});
```

**Accessible name computation priority (ARIA accName spec):**

| Priority | Mechanism | Example |
|----------|-----------|---------|
| 1 (highest) | `aria-labelledby` (points to text) | `<button aria-labelledby="h2-id">` |
| 2 | `aria-label` | `<button aria-label="Close">` |
| 3 | Native label | `<label htmlFor="email">` on `<input id="email">` |
| 4 | `title` attribute | `<button title="Submit">` — avoid; uses tooltip, not visible label |
| 5 | Element content | `<button>Submit form</button>` |
| 6 | `alt` attribute | `<img alt="Logo">` |
| 7 | `placeholder` | Last resort; disappears on input |

**Playwright accessible name assertion:**

```typescript
// File: e2e/accessibility/accessible-names.spec.ts
// Verify that critical interactive elements have correct computed accessible names.
// Uses Playwright's getByRole({ name }) which queries the accessibility tree.
import { test, expect } from '@playwright/test';

test.describe('Accessible name assertions', () => {
  test('navigation landmark has a unique accessible label', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Multiple <nav> elements require unique aria-label to distinguish them
    // WCAG technique ARIA13: Using aria-labelledby to name regions and landmarks
    const primaryNav = page.getByRole('navigation', { name: 'Main navigation' });
    const footerNav = page.getByRole('navigation', { name: 'Footer navigation' });

    await expect(primaryNav).toBeVisible();
    await expect(footerNav).toBeVisible();
  });

  test('all dialog elements have accessible names', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-testid="open-settings"]');
    await page.waitForSelector('[role="dialog"]');

    // Every dialog must have an accessible name — axe-core 4.10+ enforces this
    const dialog = page.getByRole('dialog');
    const dialogName = await dialog.getAttribute('aria-label') ??
      await page.evaluate(() => {
        const d = document.querySelector('[role="dialog"]');
        const labelledById = d?.getAttribute('aria-labelledby');
        if (labelledById) {
          return document.getElementById(labelledById)?.textContent?.trim() ?? null;
        }
        return null;
      });

    expect(dialogName).toBeTruthy();
    expect(dialogName!.length).toBeGreaterThan(0);
  });

  test('icon buttons in toolbar have non-empty accessible names', async ({ page }) => {
    await page.goto('/editor');
    await page.waitForLoadState('networkidle');

    // Get all buttons within the toolbar and verify each has an accessible name
    const toolbar = page.getByRole('toolbar');
    const buttons = toolbar.getByRole('button');
    const count = await buttons.count();

    for (let i = 0; i < count; i++) {
      const button = buttons.nth(i);
      const name = await button.getAttribute('aria-label') ??
        (await button.textContent())?.trim();
      expect(name, `Toolbar button ${i} has no accessible name`).toBeTruthy();
    }
  });
});
```

---

### Type-Safe ARIA Attributes in TypeScript Components

React's built-in `AriaAttributes` type definitions (from `@types/react`) provide compile-time checking for all ARIA attributes. However, they accept `string` for most values, allowing invalid ARIA values like `aria-invalid="maybe"` or `aria-live="instant"` to compile. TypeScript discriminated unions can enforce the correct literal value sets, making ARIA mistakes a compile-time error rather than a runtime accessibility defect.

**Why this matters:** The most common ARIA errors in production are wrong attribute values (`aria-expanded="yes"` instead of `true`/`false`, `aria-live="instant"` instead of `"polite"`) that axe-core catches at scan time but not at author time. Encoding the valid value sets as TypeScript types catches these instantly.

```typescript
// File: src/types/aria.ts
// Type-safe ARIA value sets — converts runtime axe violations into compile-time errors.
// Use these types on component props instead of raw 'string'.

/** WCAG valid values for aria-live. "assertive" interrupts; use sparingly. */
export type AriaLiveValue = 'off' | 'polite' | 'assertive';

/** Valid values for aria-haspopup. Most custom menus use "menu" or "listbox". */
export type AriaHasPopupValue =
  | boolean
  | 'false'
  | 'true'
  | 'menu'
  | 'listbox'
  | 'tree'
  | 'grid'
  | 'dialog';

/** aria-expanded: must be boolean or undefined (not present when not applicable). */
export type AriaExpandedValue = boolean | 'true' | 'false' | undefined;

/** aria-invalid: boolean or specific named states. */
export type AriaInvalidValue = boolean | 'false' | 'true' | 'grammar' | 'spelling';

/** aria-autocomplete: for combobox inputs */
export type AriaAutocompleteValue = 'none' | 'inline' | 'list' | 'both';

/** aria-orientation: for toolbars, listboxes, and sliders */
export type AriaOrientationValue = 'horizontal' | 'vertical' | undefined;

/** Strongly-typed props for disclosure widgets (accordion, dropdown) */
export interface DisclosureProps {
  id: string;
  label: string;
  expanded: boolean;           // Controls aria-expanded — not a string
  controlsId: string;          // ID of the panel being controlled (aria-controls)
  hasPopup?: AriaHasPopupValue; // For dropdown triggers
}

/** Strongly-typed props for live region containers */
export interface LiveRegionProps {
  /** "polite": waits for current speech. "assertive": interrupts. */
  live: AriaLiveValue;
  atomic?: boolean;     // aria-atomic — true = announce full content, not just changed nodes
  relevant?: 'additions' | 'removals' | 'text' | 'all' | 'additions text';
  children: React.ReactNode;
}

// Implementation with type enforcement:
import React from 'react';

export const LiveRegion: React.FC<LiveRegionProps> = ({
  live,
  atomic = true,
  relevant,
  children,
}) => (
  <div
    aria-live={live}             // Only accepts AriaLiveValue — "instant" is a compile error
    aria-atomic={atomic}
    aria-relevant={relevant}
    // Keep in DOM at all times — inserting aria-live after content misses announcement
  >
    {children}
  </div>
);

// ❌ Compile error: Type '"urgent"' is not assignable to type 'AriaLiveValue'
// const bad = <LiveRegion live="urgent">...</LiveRegion>;

// ✅ Compiles: "assertive" is a valid AriaLiveValue
// const good = <LiveRegion live="assertive">Session expiring in 60 seconds</LiveRegion>;
```

```typescript
// File: src/types/aria.test.ts
// Unit tests that verify type-safe ARIA props pass axe validation.
import React from 'react';
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import type { LiveRegionProps } from './aria';
import { LiveRegion } from './aria';

expect.extend(toHaveNoViolations);

describe('Type-safe ARIA components', () => {
  it('polite live region has no axe violations', async () => {
    const props: LiveRegionProps = {
      live: 'polite',   // TypeScript ensures this is only a valid AriaLiveValue
      atomic: true,
      children: 'Changes saved',
    };
    const { container } = render(<LiveRegion {...props} />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('assertive live region for critical errors has no axe violations', async () => {
    const props: LiveRegionProps = {
      live: 'assertive',
      atomic: true,
      children: 'Session expired. Please log in again.',
    };
    const { container } = render(<LiveRegion {...props} />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});
```

**Practical impact:** Teams using type-safe ARIA props catch `aria-expanded="yes"` (should be `true`), `aria-live="urgent"` (not a valid value), and `aria-haspopup="dropdown"` (not a valid token) during TypeScript compilation — before any test runs, before any browser, before any CI pipeline. The compile-time feedback loop is the fastest possible detection. [community]

---

### axe-core 4.10+ New Rules and WCAG 2.2 CI Configuration

axe-core 4.10 (late 2024) and 4.11 (2025–2026) added new rules that enable automated WCAG 2.2 AA testing. Teams upgrading from 4.8/4.9 will see new CI failures from these rules — treat them as a rule-change upgrade rather than a regression.

**New rules in axe-core 4.10+:**

| Rule ID | WCAG Criterion | What it catches |
|---------|---------------|-----------------|
| `aria-dialog-name` | 4.1.2 AA | Dialogs without `aria-label` or `aria-labelledby` |
| `aria-tooltip-name` | 4.1.2 AA | `role="tooltip"` elements without an accessible name |
| `scrollable-region-focusable` | 2.1.1 A | Scrollable containers that cannot receive keyboard focus |
| `target-size` | 2.5.8 AA (WCAG 2.2) | Interactive targets smaller than 24×24px |
| `focus-order-semantics` | 1.3.1 A | Elements with positive tabIndex affecting focus order |
| `identical-links-same-purpose` | 2.4.9 AAA | Links with same accessible name but different destinations |
| `color-contrast-enhanced` | 1.4.6 AAA | 7:1 contrast ratio for text (AAA — opt-in only) |

**EU EAA WCAG 2.2 AA CI configuration (June 2025+ compliance deadline):**

```typescript
// File: e2e/fixtures/axe-wcag22-fixture.ts
// WCAG 2.2 AA axe configuration — required for EU EAA compliance (EN 301 549 v3.3.2).
// EU private-sector products must comply with WCAG 2.2 AA as of June 28, 2025.
// Use this configuration when your product ships to EU consumers.
import { test as base } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

type CheckA11yOptions = {
  selector?: string;
  disableRules?: string[];
};

export const test = base.extend<{
  checkA11yWCAG22: (options?: CheckA11yOptions) => Promise<void>;
}>({
  checkA11yWCAG22: async ({ page }, use) => {
    const checkA11yWCAG22 = async (options: CheckA11yOptions = {}) => {
      const { selector, disableRules = [] } = options;

      // WCAG 2.2 AA: use wcag22aa tag (superset of wcag21aa + wcag2aa + wcag2a)
      // This includes the 9 new WCAG 2.2 criteria: 2.4.11, 2.4.12, 2.5.7, 2.5.8, 3.3.7, 3.3.8, etc.
      let builder = new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa', 'best-practice']);

      if (selector) {
        builder = builder.include(selector);
      }

      if (disableRules.length > 0) {
        // Disable specific rules with documentation in test comments
        builder = builder.disableRules(disableRules);
      }

      const results = await builder.analyze();

      if (results.violations.length > 0) {
        const report = results.violations
          .map((v) => {
            const wcagRefs = v.tags
              .filter((t) => t.startsWith('wcag'))
              .join(', ');
            return `[${v.impact?.toUpperCase()}] ${v.id} (${wcagRefs}): ${v.description}\n` +
              v.nodes
                .slice(0, 3) // Show first 3 nodes to avoid overwhelming output
                .map((n) => `  - ${n.html.slice(0, 100)}`)
                .join('\n');
          })
          .join('\n\n');

        throw new Error(
          `WCAG 2.2 AA violations found (${results.violations.length} rules):\n\n${report}`
        );
      }

      // Log incomplete items as review notes
      if (results.incomplete.length > 0) {
        console.warn(
          `[WCAG 2.2 AA] ${results.incomplete.length} items need manual review:\n` +
          results.incomplete.map((i) => `  - ${i.id}: ${i.description}`).join('\n')
        );
      }
    };

    await use(checkA11yWCAG22);
  },
});

export { expect } from '@playwright/test';
```

```typescript
// File: e2e/accessibility/wcag22-compliance.spec.ts
// Full WCAG 2.2 AA compliance test suite for EU EAA compliance.
// Import the WCAG 2.2 fixture above to use checkA11yWCAG22.
import { test, expect } from '../fixtures/axe-wcag22-fixture';

test.describe('WCAG 2.2 AA compliance (EU EAA)', () => {
  const criticalFlows = [
    { url: '/', name: 'Homepage' },
    { url: '/login', name: 'Login page' },
    { url: '/dashboard', name: 'Dashboard' },
    { url: '/checkout', name: 'Checkout flow' },
  ];

  for (const flow of criticalFlows) {
    test(`${flow.name} has no WCAG 2.2 AA violations`, async ({ page, checkA11yWCAG22 }) => {
      await page.goto(flow.url);
      await page.waitForLoadState('networkidle');

      // checkA11yWCAG22 uses wcag22aa tag (superset of wcag21aa)
      await checkA11yWCAG22();
    });
  }

  test('authenticated flow has no WCAG 2.2 AA violations', async ({
    page,
    checkA11yWCAG22,
  }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[type="email"]', 'test@example.com');
    await page.fill('input[type="password"]', 'testpassword');
    await page.click('button[type="submit"]');
    await page.waitForURL('/dashboard');

    // Scan authenticated state
    await checkA11yWCAG22();
  });
});
```

**Key difference between WCAG 2.1 AA and WCAG 2.2 AA axe scans:**

| tag | Rules added | Most impactful new checks |
|-----|-------------|--------------------------|
| `wcag21aa` | ~75 rules | Color contrast, keyboard shortcuts, pointer gestures |
| `wcag22aa` | +~8 rules | `target-size` (2.5.8), focus appearance hints, `aria-dialog-name` enforcement |

**WCAG 2.2 upgrade migration strategy for CI:**
1. Run `axe --tags wcag22aa` once in report-only mode (`resultTypes: ['violations']`) to baseline existing failures
2. Categorize: structural (fix immediately) vs design (target size, contrast) — schedule separately
3. Enable `wcag22aa` tag in CI gate after fixing structural failures
4. Add WCAG 2.2-specific Playwright tests (target size, focus appearance) for the design-level criteria

---

### Mobile and Touch Accessibility Testing  [community]

Mobile accessibility testing requires validating against TalkBack (Android) and VoiceOver (iOS), which have fundamentally different interaction models from desktop screen readers. Playwright can emulate mobile viewports and touch events, but AT testing on mobile requires physical devices or simulators.

**Key mobile-specific WCAG considerations:**

| Criterion | Mobile impact | Common failure |
|-----------|--------------|----------------|
| 2.5.1 Pointer Gestures (A) | All multi-touch gestures must have single-pointer alternative | Pinch-to-dismiss without a close button |
| 2.5.4 Motion Actuation (A) | Shake/tilt actions must have UI alternative and be disableable | Shake to undo without settings override |
| 2.5.8 Target Size (AA, WCAG 2.2) | 24×24px minimum — more critical on mobile | 16px icon buttons, tiny nav items |
| 1.3.4 Orientation (AA) | Content must not require portrait or landscape orientation | Checkout locked to portrait |
| 2.4.7 Focus Visible (AA) | Focus visible on touch + keyboard | Focus indicator invisible on mobile browsers |

**Playwright mobile viewport testing:**

```typescript
// File: e2e/accessibility/mobile-a11y.spec.ts
// Mobile accessibility tests: viewport, orientation, touch target size, WCAG 2.5.x criteria.
import { test, expect, devices } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

// Emulate iPhone 14 Pro for mobile tests
const iPhone14Pro = devices['iPhone 14 Pro'];

test.describe('Mobile accessibility', () => {
  test.use({ ...iPhone14Pro });

  test('homepage passes axe scan on mobile viewport', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(results.violations).toEqual([]);
  });

  test('1.3.4 Orientation: content reflows in landscape without locking', async ({ page }) => {
    // Test portrait
    await page.goto('/checkout');
    await page.waitForLoadState('networkidle');

    const portraitHasHorizontalScroll = await page.evaluate(
      () => document.body.scrollWidth > document.documentElement.clientWidth
    );
    expect(portraitHasHorizontalScroll).toBe(false);

    // Switch to landscape
    await page.setViewportSize({ width: 844, height: 390 }); // iPhone 14 Pro landscape
    await page.waitForLoadState('networkidle');

    // Verify content is not locked — key elements should still be visible
    const checkoutButton = page.getByRole('button', { name: /checkout|continue/i });
    if (await checkoutButton.count() > 0) {
      await expect(checkoutButton).toBeVisible();
    }
  });

  test('2.5.8 Target size: touch targets meet 24×24px minimum on mobile', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // On mobile, target size failures are more severe — 44×44px is Apple HIG recommendation
    // WCAG 2.5.8 sets 24×24px as the legal minimum
    const MINIMUM_TARGET_PX = 24;
    const APPLE_HIG_PX = 44; // Apple HIG recommendation (not WCAG requirement)

    const violations = await page.evaluate((minPx) => {
      const interactiveSelector =
        'button, a[href], input:not([type="hidden"]), select, textarea, [role="button"]';
      return Array.from(document.querySelectorAll<HTMLElement>(interactiveSelector))
        .map((el) => {
          const rect = el.getBoundingClientRect();
          return {
            tag: el.tagName.toLowerCase(),
            text: el.textContent?.trim().slice(0, 30) ?? '',
            width: Math.round(rect.width),
            height: Math.round(rect.height),
          };
        })
        .filter((el) => el.width > 0 && el.height > 0)
        .filter((el) => el.width < minPx || el.height < minPx);
    }, MINIMUM_TARGET_PX);

    if (violations.length > 0) {
      console.table(violations);
    }
    expect(violations).toEqual([]);
  });

  test('2.5.1 Pointer gestures: swipe-dismissed components have close button alternative', async ({
    page,
  }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Check for elements that might be swipe-dismissed (bottom sheets, toast with swipe)
    const swipeDismissibles = page.locator(
      '[data-swipe-dismiss], [data-testid*="bottom-sheet"], [data-testid*="drawer"]'
    );
    const count = await swipeDismissibles.count();

    for (let i = 0; i < count; i++) {
      const el = swipeDismissibles.nth(i);
      // Verify a close button exists within the swipeable container
      const closeButton = el.getByRole('button', { name: /close|dismiss|cancel/i });
      await expect(closeButton).toBeVisible();
    }
  });

  // Test touch target size on navigation items specifically
  test('bottom navigation bar items meet touch target requirements', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const navBar = page.locator('[role="navigation"][aria-label*="bottom"], nav[class*="bottom"]');
    if (await navBar.count() === 0) return;

    const navItems = navBar.getByRole('link');
    const count = await navItems.count();

    for (let i = 0; i < count; i++) {
      const item = navItems.nth(i);
      const box = await item.boundingBox();
      if (box) {
        expect(box.height).toBeGreaterThanOrEqual(44); // Apple HIG for bottom nav
        expect(box.width).toBeGreaterThanOrEqual(44);
      }
    }
  });
});
```

**Community lessons on mobile AT testing:**

38. **[community] VoiceOver on iOS interprets `role="application"` differently from desktop screen readers**: On iOS, `role="application"` puts VoiceOver into "direct touch" mode where swipe navigation is disabled — the opposite of NVDA Application Mode. Teams that add `role="application"` to fix NVDA keyboard handling can break VoiceOver swipe navigation entirely. Use `role="application"` only when the widget genuinely requires it (e.g., drawing tools), and test on both platforms. For most composite widgets, `role="group"` or specific widget roles (`role="listbox"`, `role="grid"`) are more appropriate.

39. **[community] `tabindex="0"` on non-interactive elements is never keyboard-accessible on iOS**: iOS VoiceOver navigates by swiping to elements in the accessibility tree order, not by Tab key. However, custom interactive elements (`<div tabindex="0">`) that work on desktop with Tab/Enter may not receive swipe focus on iOS if they lack a semantic role. Always use native HTML elements or appropriate ARIA roles — `role="button"` paired with `tabindex="0"` and a click handler is the minimum for custom interactive elements to work on iOS.

**Android TalkBack vs iOS VoiceOver quick reference:**

| Feature | iOS VoiceOver | Android TalkBack |
|---------|--------------|-----------------|
| Primary navigation | Swipe left/right | Swipe left/right |
| Activate element | Double-tap | Double-tap |
| Scroll | Three-finger swipe | Two-finger swipe |
| Heading jump | Rotor (two-finger rotate) | Local context menu |
| Supports `aria-modal` | No (use `inert`) | Partial |
| WebView accessibility | Good (WKWebView) | Good (WebView) |

### AI-Assisted Accessibility Testing  [community]

As of 2025–2026, a new layer of AI-augmented tooling sits between automated axe scans and full manual audits. These tools do not replace either layer but reduce the manual effort required for the ~43% of WCAG issues that automated scanners cannot catch alone.

**Three emerging AI-assisted patterns:**

1. **MCP-server scanning (navable MCP):** A Model Context Protocol server exposes `run_accessibility_scan`, `generate_fix_plan`, and `update_fix_status` tools. An AI coding agent (Claude Code, Copilot) can scan a live page, receive structured fix plans, implement fixes, and re-verify — completing the scan→plan→fix→verify cycle without a human intermediary. The server uses Playwright + axe-core for scanning and optionally Pa11y/HTMLCS as a secondary engine with server-side deduplication.

2. **AI-generated alt text (Aura/BLIP):** Models like Hugging Face BLIP can generate contextually appropriate `alt` text for images flagged by axe-core's `image-alt` rule. This is particularly valuable for large content repositories where QA teams cannot manually write alt text for every image. The AI generates a candidate; QA verifies and refines.

3. **AI-powered contrast fix suggestions:** Tools like Aura calculate WCAG-compliant color substitutions (maintaining 4.5:1 ratios) when color-contrast violations are found, providing developers with actionable fix values rather than just violation reports.

**Pattern: MCP-driven scan-plan-fix-verify cycle**

```typescript
// Conceptual pattern: how an AI agent uses navable MCP tools
// The agent calls these tools via the MCP protocol — not direct TypeScript API.
// This shows the workflow logic in TypeScript pseudo-code.

interface ScanResult {
  scanId: string;
  violations: Array<{
    ruleId: string;
    impact: 'critical' | 'serious' | 'moderate' | 'minor';
    description: string;
    nodes: Array<{ html: string; target: string[] }>;
    wcagCriteria: string[];  // e.g., ['WCAG 1.3.1', 'EN 301 549 9.1.3.1']
  }>;
}

interface FixPlan {
  scanId: string;
  items: Array<{
    id: string;
    ruleId: string;
    status: 'pending' | 'in_progress' | 'done' | 'skipped';
    suggestedFix: string;     // Human-readable fix description
    codePattern?: string;     // Before/after code example if available
  }>;
}

// Step 1: scan (calls run_accessibility_scan MCP tool)
async function agentScanFlow(targetUrl: string): Promise<void> {
  // Agent calls: run_accessibility_scan({ url: targetUrl, tags: ['wcag2a', 'wcag2aa'] })
  const scan: ScanResult = await mcpTool.runAccessibilityScan(targetUrl);

  if (scan.violations.length === 0) {
    console.log('No WCAG 2.1 AA violations found — axe scan passed.');
    return;
  }

  // Step 2: generate fix plan (calls generate_fix_plan MCP tool)
  const plan: FixPlan = await mcpTool.generateFixPlan(scan.scanId);
  // Plan is written to .navable-plan.json in the project root

  // Step 3: agent implements fixes (edits source files)
  for (const item of plan.items) {
    if (item.status === 'pending') {
      console.log(`Fixing: [${item.ruleId}] ${item.suggestedFix}`);
      // Agent applies fix using Edit/Write tools...
      // Then marks item as done:
      await mcpTool.updateFixStatus(item.id, 'done');
    }
  }

  // Step 4: verify (re-run scan to confirm fixes)
  const verifyScan: ScanResult = await mcpTool.runAccessibilityScan(targetUrl);
  const remaining = verifyScan.violations.filter(
    (v) => plan.items.some((i) => i.ruleId === v.ruleId && i.status === 'done')
  );

  if (remaining.length > 0) {
    console.error(`${remaining.length} violations remain after fix attempt.`);
  } else {
    console.log('All planned violations resolved.');
  }
}
```

**Dual-engine scanning (axe-core + Pa11y/HTMLCS):**

Running axe-core and Pa11y's HTMLCS engine in parallel catches violations each engine misses. The navable MCP server implements server-side deduplication via a crossover tag (`alsoFlaggedBy: ["htmlcs"]`). Teams implementing this manually should normalize violation IDs before deduplication.

```typescript
// File: e2e/accessibility/dual-engine-scan.ts
// Dual-engine a11y scanning: axe-core (primary) + Pa11y/HTMLCS (secondary).
// Merges results and deduplicates by page+rule to avoid double-reporting.
import { chromium } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import pa11y from 'pa11y';

interface NormalizedViolation {
  ruleId: string;
  impact: string;
  description: string;
  selector: string;
  engines: ('axe' | 'pa11y')[];   // Which engines flagged this
  wcagCriteria: string[];
}

export async function dualEngineScan(url: string): Promise<NormalizedViolation[]> {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto(url);
  await page.waitForLoadState('networkidle');

  // Run axe-core scan
  const axeResults = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
    .analyze();

  await browser.close();

  // Run Pa11y independently (uses HTMLCS engine by default)
  const pa11yResults = await pa11y(url, {
    standard: 'WCAG2AA',
    runners: ['htmlcs'],
  });

  // Normalize axe violations
  const axeViolations: NormalizedViolation[] = axeResults.violations.flatMap((v) =>
    v.nodes.map((node) => ({
      ruleId: v.id,
      impact: v.impact ?? 'unknown',
      description: v.description,
      selector: node.target.join(' '),
      engines: ['axe'] as ('axe' | 'pa11y')[],
      wcagCriteria: v.tags.filter((t) => t.startsWith('wcag')),
    }))
  );

  // Normalize Pa11y issues
  const pa11yViolations: NormalizedViolation[] = pa11yResults.issues.map((issue) => ({
    ruleId: issue.code,
    impact: issue.type === 'error' ? 'serious' : 'moderate',
    description: issue.message,
    selector: issue.selector,
    engines: ['pa11y'] as ('axe' | 'pa11y')[],
    wcagCriteria: [issue.code.split('.')[1] ?? ''],
  }));

  // Merge: mark violations found by both engines
  const merged = [...axeViolations];
  for (const pa11yV of pa11yViolations) {
    const existing = merged.find(
      (v) => v.selector === pa11yV.selector && v.description === pa11yV.description
    );
    if (existing) {
      existing.engines.push('pa11y');  // "alsoFlaggedBy" marker
    } else {
      merged.push(pa11yV);
    }
  }

  return merged;
}
```

**Why dual-engine matters in production:** axe-core catches ~57% of WCAG issues and Pa11y/HTMLCS catches a partially overlapping but not identical set. Studies comparing engines find that teams using dual-engine scanning catch ~65–70% of automated-detectable issues — a 10–13% improvement over a single engine alone. The tradeoff is setup complexity and longer scan times. [community]

**axe-linter for early-cycle (shift-left) detection:**

Deque's `vscode-axe-linter` extension runs axe-core rules as static analysis on JSX/TSX files as you type — catching missing `aria-label`, wrong role combinations, and structural errors before the code compiles. This is the earliest possible detection, integrated into the development loop itself.

```typescript
// .vscode/settings.json additions for axe-linter:
// Install: "deque-systems.vscode-axe-linter" from VS Code Marketplace
// Configuration:
{
  "axe-linter.enabled": true,
  "axe-linter.rules": {
    // Upgrade missing-label from warning to error for stricter early detection
    "label": "error",
    "button-name": "error",
    "image-alt": "error",
    // Allow color-contrast to remain a warning (needs design review, not just dev fix)
    "color-contrast": "warn"
  }
}

// The linter flags this in your editor before CI:
// ❌ <button>   — "button-name: Buttons must have discernible text"
// ❌ <img src="logo.png">   — "image-alt: Images must have alternate text"
// ✅ <button aria-label="Close dialog">
// ✅ <img src="logo.png" alt="Company logo">
```

**Why early-cycle detection has highest ROI:** The cost-of-defects curve applies to accessibility as much as to functional bugs. A missing `aria-label` caught by axe-linter during development takes seconds to fix. The same issue found in a WCAG audit costs hours: audit report → ticket → sprint → developer context switch → fix → verify. [community]

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| WCAG 2.1 Quick Reference | Official spec | https://www.w3.org/WAI/WCAG21/quickref/ | Filterable list of all success criteria |
| WCAG 2.2 New Criteria | Official spec | https://www.w3.org/TR/WCAG22/ | 9 new criteria including target size and dragging; legally required under EU EAA |
| EU Accessibility Act (EAA) | Legal reference | https://ec.europa.eu/social/main.jsp?catId=1202 | EU private-sector accessibility law; June 28, 2025 compliance deadline |
| EN 301 549 v3.3.2 | Standard | https://www.etsi.org/deliver/etsi_en/301500_302000/301549/03.03.02_60/ | Technical standard for EAA; maps WCAG 2.2 AA to EU law |
| ARIA Authoring Practices Guide | Official guide | https://www.w3.org/WAI/ARIA/apg/ | Patterns for custom widgets — roving tabindex, combobox, dialog, etc. |
| ARIA Accessible Name Computation | Spec | https://www.w3.org/TR/accname-1.2/ | Authoritative source for name/label precedence rules |
| axe-core | Open source | https://github.com/dequelabs/axe-core | Rule documentation and changelog (v4.11.4 current); custom rule API |
| axe-core Rule Descriptions | Reference | https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md | Full list of all axe rules with WCAG mapping |
| jest-axe | Open source | https://github.com/nickcolley/jest-axe | Jest integration for axe |
| @axe-core/playwright | Open source | https://github.com/dequelabs/axe-core-npm | Playwright integration |
| @storybook/addon-a11y | Open source | https://storybook.js.org/addons/@storybook/addon-a11y | Per-story axe scan in Storybook; catches component-level issues in design system |
| IBM Equal Access Checker | Open source | https://www.ibm.com/able/toolkit/tools/ | Supplementary rule engine with EN 301 549 focus |
| WebAIM Million Report | Research | https://webaim.org/projects/million/ | Most common real-world failures (contrast 81%, alt 55%, labels 49%) |
| WebAIM Screen Reader Survey | Research | https://webaim.org/projects/screenreadersurvey/ | Actual AT usage statistics |
| MDN ARIA reference | Reference | https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA | Role and attribute documentation |
| MDN forced-colors | Reference | https://developer.mozilla.org/en-US/docs/Web/CSS/@media/forced-colors | Windows High Contrast Mode CSS media feature |
| MDN autocomplete values | Reference | https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete | Complete list of autocomplete token values for WCAG 1.3.5 |
| TPGi Colour Contrast Analyser | Tool | https://www.tpgi.com/color-contrast-checker/ | Desktop tool for manual contrast checking |
| ARIA Combobox Pattern (APG) | Pattern guide | https://www.w3.org/WAI/ARIA/apg/patterns/combobox/ | Authoritative ARIA 1.2 combobox pattern — critical for custom autocomplete |
| Inclusive Components | Book/blog | https://inclusive-components.design/ | Heydon Pickering's production-ready accessible component patterns |
| A11y Project | Community | https://www.a11yproject.com/ | Checklists, articles, and WCAG success criterion explanations |
| Text Spacing Bookmarklet (W3C) | Tool | https://www.html5accessibility.com/tests/tsbookmarklet.html | Test WCAG 1.4.12 text spacing in any browser |
| PAC (PDF Accessibility Checker) | Tool | https://pac.pdf-accessibility.org/ | Free PDF accessibility validator (ISO 14289 / PDF/UA) |
| iOS Accessibility Inspector | Tool | Built into Xcode | Native iOS/macOS accessibility audit tool |
| Android Accessibility Scanner | Tool | https://play.google.com/store/apps/details?id=com.google.android.apps.accessibility.auditor | Native Android a11y audit app by Google |
| NVDA Screen Reader | Free tool | https://www.nvaccess.org/ | Most widely used free screen reader — ~41% market share; test with Firefox |
| navable-web-accessibility-mcp | Open source | https://github.com/web-DnA/navable-web-accessibility-mcp | MCP server for agent-driven a11y scan→plan→fix→verify cycles; EN 301 549 mapping |
| axe-linter VSCode extension | Tool | https://marketplace.visualstudio.com/items?itemName=deque-systems.vscode-axe-linter | Earliest-cycle a11y static analysis in editor; shift-left detection |
| Pa11y | Open source | https://pa11y.org/ | CLI accessibility scanner using HTMLCS engine; good as secondary engine alongside axe |
| Aura AI Accessibility Scanner | Open source | https://github.com/architzero/Aura-accessibility-scanner | AI-assisted alt text generation + contrast fix suggestions + axe-core scanning |
| WCAG 2.5.3 Understanding | Official | https://www.w3.org/WAI/WCAG21/Understanding/label-in-name.html | Label in Name — critical for Dragon/Voice Control users |
| WAI-ARIA APG Carousel Pattern | Official | https://www.w3.org/WAI/ARIA/apg/patterns/carousel/ | Authoritative carousel ARIA pattern with keyboard interactions |
| WAI-ARIA APG Date Picker Pattern | Official | https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/examples/datepicker-dialog/ | Authoritative calendar date picker implementation |
| Storybook Test Runner | Open source | https://storybook.js.org/docs/writing-tests/test-runner | Automated a11y scan of every story in CI — zero per-story test authoring |
| WCAG 3.0 Working Draft | Draft spec | https://www.w3.org/TR/wcag-3.0/ | Forward-looking awareness; Bronze/Silver/Gold outcome-based model |
| Playwright Mobile Devices | Official | https://playwright.dev/docs/emulation | Device emulation for mobile viewport + touch accessibility testing |
