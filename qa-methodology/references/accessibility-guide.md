# Accessibility Testing (a11y) — QA Methodology Guide
<!-- lang: TypeScript | topic: accessibility | iteration: 10 | score: 100/100 | date: 2026-05-02 -->
<!-- sources: training knowledge + axe-core GitHub README (WebFetch) -->

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
- **1.4.3 Contrast Minimum (AA)**: 4.5:1 for normal text, 3:1 for large text
- **1.4.4 Resize Text (AA)**: Text must resize to 200% without loss of content or functionality
- **1.4.11 Non-text Contrast (AA)**: UI component boundaries and graphical objects must meet 3:1 contrast against adjacent colors

### Operable
UI components and navigation must be operable. If a user cannot operate the interface, they cannot use it. This addresses motor disabilities and users who rely on keyboard or switch access devices.
- **2.1.1 Keyboard (A)**: All functionality must be accessible via keyboard alone — no mouse-only interactions
- **2.1.2 No Keyboard Trap (A)**: Focus must not get stuck inside a component unless it is a dialog that intentionally traps focus (and provides a dismiss mechanism)
- **2.4.3 Focus Order (A)**: Tab order must be logical and match visual reading order
- **2.4.7 Focus Visible (AA)**: Keyboard focus indicator must be visible — `outline: none` without replacement is a failure
- **2.5.3 Label in Name (A)**: For UI components with visible text labels, the accessible name must contain the visible text

### Understandable
Information and the operation of the UI must be understandable. This addresses users with cognitive disabilities, learning differences, and non-native language users.
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

### SPA Focus Management After Route Changes  [community]

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

1. **Using ARIA to override semantics without purpose**: `<div role="button">` without `tabIndex={0}` and keyboard handlers is worse than `<button>`. Native HTML elements carry built-in keyboard support and implicit roles.

2. **Removing focus outlines without replacement**: `outline: none` in CSS without providing an alternative visible focus indicator is a WCAG 2.4.7 failure and locks out keyboard-only users.

3. **Testing only with axe and calling it done**: axe-core catches ~57% of WCAG issues. Skipping keyboard and screen reader testing leaves nearly half of all issues undetected.

4. **Generic link text**: `<a href="/report">Click here</a>` fails 2.4.6. Screen reader users navigate by links in isolation; the link text must describe the destination.

5. **Placeholder text as label substitute**: `placeholder` disappears on typing; it fails WCAG 3.3.2 when used instead of a visible `<label>`. Users with cognitive disabilities often forget what the field asks.

6. **Auto-playing media**: Auto-playing video or audio without controls violates WCAG 1.4.2 and is disruptive to screen reader users who cannot distinguish the page content from the media audio.

7. **aria-label overuse on every element**: Adding `aria-label` to every `<div>` and `<span>` creates noise for screen reader users. Use ARIA only when native semantics are insufficient.

8. **Using `display: none` incorrectly for visually-hidden content**: Elements with `display: none` are removed from the accessibility tree (correct for truly hidden content). Elements hidden with only CSS `opacity: 0` or `transform` remain in the tab order — always use `display: none` or `inert` to fully hide interactive content from all users.

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

---

## Tradeoffs & Alternatives

### WCAG Conformance Level Comparison

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
| Lighthouse (Chrome) | Integrated in DevTools, accessibility + perf score | Less detailed rule set, can score 100 with real issues | Dashboard metrics, quick checks |
| WAVE | Visual overlay, education-friendly | Manual only, not automatable | Auditor walkthroughs |
| Pa11y | CLI + CI automation | Less comprehensive than axe | Lightweight CI pipelines |
| Deque WorldSpace | Enterprise audit workflow management | Commercial license | Large org compliance tracking |
| axe DevTools (Deque) | Guided issue reporting with fix guidance | Commercial | Developer-guided manual audits |

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

**axe-core does NOT replace screen reader testing.** It catches structural issues but cannot verify that the announced experience is meaningful, logical, or correct.

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

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| WCAG 2.1 Quick Reference | Official spec | https://www.w3.org/WAI/WCAG21/quickref/ | Filterable list of all success criteria |
| WCAG 2.2 New Criteria | Official spec | https://www.w3.org/TR/WCAG22/ | 9 new criteria including target size and dragging; legally required under EU EAA |
| EU Accessibility Act (EAA) | Legal reference | https://ec.europa.eu/social/main.jsp?catId=1202 | EU private-sector accessibility law; June 28, 2025 compliance deadline |
| EN 301 549 v3.3.2 | Standard | https://www.etsi.org/deliver/etsi_en/301500_302000/301549/03.03.02_60/ | Technical standard for EAA; maps WCAG 2.2 AA to EU law |
| ARIA Authoring Practices Guide | Official guide | https://www.w3.org/WAI/ARIA/apg/ | Patterns for custom widgets |
| axe-core | Open source | https://github.com/dequelabs/axe-core | Rule documentation and changelog (v4.11.4 current) |
| jest-axe | Open source | https://github.com/nickcolley/jest-axe | Jest integration for axe |
| @axe-core/playwright | Open source | https://github.com/dequelabs/axe-core-npm | Playwright integration |
| WebAIM Million Report | Research | https://webaim.org/projects/million/ | Most common real-world failures (contrast 81%, alt 55%, labels 49%) |
| WebAIM Screen Reader Survey | Research | https://webaim.org/projects/screenreadersurvey/ | Actual AT usage statistics |
| MDN ARIA reference | Reference | https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA | Role and attribute documentation |
| MDN forced-colors | Reference | https://developer.mozilla.org/en-US/docs/Web/CSS/@media/forced-colors | Windows High Contrast Mode CSS media feature |
| TPGi Colour Contrast Analyser | Tool | https://www.tpgi.com/color-contrast-checker/ | Desktop tool for manual contrast checking |
| ARIA Combobox Pattern (APG) | Pattern guide | https://www.w3.org/WAI/ARIA/apg/patterns/combobox/ | Authoritative ARIA 1.2 combobox pattern — critical for custom autocomplete |
| Inclusive Components | Book/blog | https://inclusive-components.design/ | Heydon Pickering's production-ready accessible component patterns |
| A11y Project | Community | https://www.a11yproject.com/ | Checklists, articles, and WCAG success criterion explanations |
| PAC (PDF Accessibility Checker) | Tool | https://pac.pdf-accessibility.org/ | Free PDF accessibility validator (ISO 14289 / PDF/UA) |
| iOS Accessibility Inspector | Tool | Built into Xcode | Native iOS/macOS accessibility audit tool |
| Android Accessibility Scanner | Tool | https://play.google.com/store/apps/details?id=com.google.android.apps.accessibility.auditor | Native Android a11y audit app by Google |
