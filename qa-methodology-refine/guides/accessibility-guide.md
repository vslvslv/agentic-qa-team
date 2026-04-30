# Accessibility Testing (a11y) — QA Methodology Guide
<!-- lang: TypeScript | topic: accessibility | iteration: 2 | score: 100/100 | date: 2026-04-30 | final: true -->
<!-- sources: training knowledge (WebFetch/WebSearch partially available; axe-core README fetched) -->

## Core Principles (POUR)

WCAG 2.1 is organized around four foundational principles known as POUR. Every success criterion maps to one of these four categories. Understanding POUR before writing test cases helps QA engineers know **why** a given test case exists and what class of user it protects.

**Why POUR matters for testing**: Test cases that merely pass "the linter" without understanding POUR miss the user impact. Perceivable tests protect blind/deaf users; Operable tests protect motor-impaired and keyboard-only users; Understandable tests protect cognitive-impaired and non-native language users; Robust tests protect all users of assistive technology now and in the future.

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

**Test level mapping:**

| Test Level | Tool | When |
|-------|------|------|
| Unit / Component | jest-axe + @testing-library | On every PR, in CI |
| Integration / E2E | Playwright + @axe-core/playwright | On every PR, in CI |
| Manual audit | Screen reader + keyboard | Per sprint, before major releases |
| Visual | Color contrast checker | Design review + automated scan |

---

## Patterns

### Why axe-core Is the Standard Rule Engine

axe-core is the open-source accessibility rule engine powering jest-axe, `@axe-core/playwright`, the Deque browser extensions, and Lighthouse. Latest stable: **4.11.4** (April 28, 2026). It has become the de facto standard because:

- **Coverage**: Deque research shows axe-core detects ~57% of WCAG issues automatically — the highest coverage of any open-source engine
- **Zero false positives by design**: Rules only flag definitive violations. Uncertain test conditions return as `incomplete` rather than violations — this keeps CI pipelines trustworthy
- **Wide adoption**: Used by Microsoft, Google, GitHub, and most major design systems
- **TypeScript support**: Ships with `axe.d.ts` type definitions; jest-axe and `@axe-core/playwright` are TypeScript-native
- **Standard tags**: Rules tagged by WCAG version and level (`wcag2a`, `wcag2aa`, `wcag21aa`, `wcag22aa`, `best-practice`), enabling precise scope control
- **Shadow DOM support**: Evaluates nested iframes and shadow DOM of infinite depth — critical for design system components

**axe-core coverage ceiling**: The ~57% figure means automated testing is necessary but not sufficient. Building a CI gate on axe alone creates a false sense of compliance.

---

### jest-axe: Component-Level A11y Testing

jest-axe integrates axe-core into Jest, enabling accessibility checks at the component level. It catches structural defects (missing labels, invalid ARIA) as fast unit test cases before code reaches a real browser.

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

`@axe-core/playwright` runs axe-core against live pages in a real browser, catching defects JSDOM-based test cases miss (color contrast, complex focus states, iframe content).

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

    // Audit only the modal region to isolate violations
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

    // Run only contrast-specific rules to isolate violations
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

`aria-expanded` communicates the open/closed state of interactive disclosure patterns (accordions, dropdowns, nav menus). This is required for WCAG 4.1.2 Name, Role, Value and is one of the most commonly missing ARIA attributes in custom components.

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

### Accessible Data Tables

WCAG 1.3.1 (Info and Relationships) and 1.3.2 (Meaningful Sequence) require that data tables communicate the relationship between header and data cells to screen readers. Simple tables need `<th scope="col">` or `<th scope="row">`; complex tables with multi-level headers need `id`/`headers` associations.

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
      {/* caption is announced first when screen readers navigate to the table */}
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
import { render, screen } from '@testing-library/react';
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

> **Version pinning note**: axe-core 4.11.x (released Q1–Q2 2026) added new rules including `aria-dialog-name`, `aria-tooltip-name`, `scrollable-region-focusable`, and improved `color-contrast-enhanced` (WCAG 2.2 1.4.11). When upgrading axe-core across jest-axe and @axe-core/playwright, update both packages simultaneously to the same underlying axe-core transitive version — version skew between unit and E2E test levels produces false discrepancies.

### SPA Focus Management After Route Changes  [community]

In single-page applications using React Router, Next.js, or Vue Router, client-side navigation does not move browser focus. Screen reader users stay at the link they clicked, then hear the old page content re-read. This is one of the most common and impactful accessibility defects in modern SPAs.

**Why it fails:** The browser's built-in focus management only runs on full page loads. Client-side routing swaps DOM content silently. Without intervention, focus strands at the navigation trigger while the page context has completely changed.

```typescript
// File: src/hooks/useFocusOnRouteChange.ts
import { useEffect, useRef } from 'react';
import { useLocation } from 'react-router-dom';

/**
 * After each route change, focus the first <h1> on the new page.
 * The <h1> must have tabIndex={-1} to accept programmatic focus without
 * entering the normal tab sequence.
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

### prefers-reduced-motion Testing

WCAG 2.1 SC 2.3.3 (AAA) requires that animations triggered by interaction can be disabled. `prefers-reduced-motion` is widely considered a best practice and is referenced in WCAG 2.1 Understanding docs. Many users with vestibular disorders, epilepsy, and attention disorders rely on it.

```typescript
// File: e2e/accessibility/reduced-motion.spec.ts
import { test, expect } from '@playwright/test';

test.describe('prefers-reduced-motion', () => {
  test.use({
    // Emulate OS-level reduced motion preference for all test cases in this block
    reducedMotion: 'reduce',
  });

  test('page-transition animation is suppressed', async ({ page }) => {
    await page.goto('/');

    const animationDuration = await page.evaluate(() => {
      const el = document.querySelector('[data-testid="page-transition"]');
      return el ? getComputedStyle(el).animationDuration : null;
    });

    // CSS: @media (prefers-reduced-motion: reduce) { animation-duration: 0.001ms }
    expect(['0s', '0.001s', '0.001ms']).toContain(animationDuration ?? '0s');
  });

  test('carousel auto-play is disabled', async ({ page }) => {
    await page.goto('/');
    const initialSlide = await page.locator('[data-testid="carousel-slide"].active').textContent();
    await page.waitForTimeout(3000);
    const currentSlide = await page.locator('[data-testid="carousel-slide"].active').textContent();
    expect(currentSlide).toBe(initialSlide);
  });
});
```

**CSS implementation pattern that these test cases verify:**
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

Windows High Contrast Mode (now `forced-colors: active` in CSS) is an OS-level accessibility feature used by users with low vision, photosensitivity, or cognitive differences. It overrides all authored colors with a system palette, stripping background images and custom color properties. Playwright can emulate `forced-colors: active`, letting CI catch components that become unreadable in High Contrast Mode.

```typescript
// File: e2e/accessibility/forced-colors.spec.ts
import { test, expect } from '@playwright/test';

test.describe('forced-colors: Windows High Contrast Mode', () => {
  test.use({
    // Emulate Windows High Contrast Mode (forced-colors: active)
    forcedColors: 'active',
  });

  test('primary button boundary is visible in High Contrast Mode', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

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
    const hasBorder = inputBorder!.borderStyle !== 'none' && inputBorder!.borderWidth !== '0px';
    const hasOutline = inputBorder!.outline !== 'none' && inputBorder!.outline !== '';
    expect(hasBorder || hasOutline).toBe(true);
  });
});
```

### WCAG 2.2 Target Size Testing (2.5.8)

WCAG 2.2 SC 2.5.8 (AA) requires interactive targets to be at least 24×24 CSS pixels. Playwright can verify this via bounding box measurements.

```typescript
// File: e2e/accessibility/wcag22-target-size.spec.ts
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
        .filter((el) => el.width > 0 && el.height > 0)
        .filter((el) => el.width < minPx || el.height < minPx);
    }, MINIMUM_TARGET_PX);

    if (violations.length > 0) {
      console.table(violations);
    }
    expect(violations).toEqual([]);
  });
});
```

### CI/CD Pipeline Integration

Integrating axe-core into CI ensures accessibility defects are caught as part of the normal merge gate. The recommended approach follows the fail-fast test ordering principle: unit-level jest-axe runs first (fast), then E2E Playwright scans run against the deployed preview.

```typescript
// File: playwright.config.ts
// Configure axe-core Playwright integration for CI
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  expect: { timeout: 5_000 },
  // Run all test suites in parallel (axe scans are I/O-bound)
  fullyParallel: true,
  // Fail fast on first test suite failure in CI
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: [
    ['list'],
    // JUnit format for CI artifact ingestion (GitHub Actions, Jenkins, Azure DevOps)
    ['junit', { outputFile: 'test-results/playwright-results.xml' }],
  ],
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:3000',
    // Screenshots on failure for accessibility test case debugging
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
  projects: [
    // Chromium: primary accessibility testing browser (most AT users)
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    // Firefox: NVDA + Firefox is the highest market-share AT combination
    { name: 'firefox',  use: { ...devices['Desktop Firefox'] } },
  ],
});
```

```yaml
# File: .github/workflows/accessibility.yml
# GitHub Actions CI workflow: fail fast on accessibility violations
name: Accessibility CI

on:
  pull_request:
    branches: [main]

jobs:
  unit-a11y:
    name: Component accessibility (jest-axe)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      # jest-axe runs as part of the normal test suite — no separate step needed
      - run: npm test -- --testPathPattern="\.a11y\.test\."
        env:
          CI: true

  e2e-a11y:
    name: Full-page accessibility (Playwright + axe)
    needs: unit-a11y          # Only run if unit a11y passes
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx playwright install --with-deps chromium firefox
      - run: npx playwright test e2e/accessibility/
        env:
          BASE_URL: ${{ secrets.PREVIEW_URL }}
          CI: true
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-a11y-results
          path: test-results/
```

**axe-core rule tag reference for precise CI scope control:**

| Tag | Scope |
|-----|-------|
| `wcag2a` | WCAG 2.0 Level A |
| `wcag2aa` | WCAG 2.0 Level AA |
| `wcag21a` | WCAG 2.1 Level A (new criteria only) |
| `wcag21aa` | WCAG 2.1 Level AA (new criteria only) |
| `wcag22aa` | WCAG 2.2 Level AA (new criteria only) |
| `best-practice` | Non-WCAG best practices |
| `section508` | US Section 508 |
| `experimental` | Rules in development — higher false positive rate |

**Recommendation**: Use `['wcag2a', 'wcag2aa', 'wcag21aa']` as the baseline CI gate. Add `wcag22aa` as a separate non-blocking advisory scan until WCAG 2.2 is the team's target. Never include `experimental` in merge gates.

### @testing-library Query Priority and Accessibility Tree Coverage

`@testing-library`'s query priority directly reflects the accessibility tree. The recommended hierarchy ensures test cases fail when accessible names are broken — catching defects that visual queries miss entirely.

**Priority order (highest to lowest):**
1. `getByRole` — queries by ARIA role + accessible name (uses the accessibility tree)
2. `getByLabelText` — finds form elements by their associated label
3. `getByPlaceholderText` — fallback for inputs; weaker than label
4. `getByText` — finds by visible text content
5. `getByDisplayValue` — current value of form elements
6. `getByAltText` — for images with alt text
7. `getByTitle` — for elements with title attribute
8. `getByTestId` — **last resort only**; bypasses accessibility tree entirely

```typescript
// File: src/components/SearchForm/SearchForm.a11y.test.tsx
// Demonstrates why getByRole + getByLabelText catches defects that getByTestId misses
import React, { useState } from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

// ── Component being tested ──────────────────────────────────────────────────
function SearchForm() {
  const [query, setQuery] = useState('');
  const [submitted, setSubmitted] = useState(false);
  return (
    <form onSubmit={(e) => { e.preventDefault(); setSubmitted(true); }}>
      <label htmlFor="search-input">Search products</label>
      <input
        id="search-input"
        type="search"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        data-testid="search-input"
        aria-describedby="search-hint"
      />
      <p id="search-hint">Enter a product name or category</p>
      <button type="submit" aria-label="Run search">
        Search
      </button>
      {submitted && (
        <p role="status" aria-live="polite">
          Searching for: {query}
        </p>
      )}
    </form>
  );
}

// ── Test suite demonstrating query priority ────────────────────────────────
describe('SearchForm: query priority and accessibility', () => {
  it('getByRole finds the submit button by accessible name — axe passes', async () => {
    const { container } = render(<SearchForm />);

    // getByRole('button') uses the accessibility tree — will fail if aria-label is removed
    const submitBtn = screen.getByRole('button', { name: 'Run search' });
    expect(submitBtn).toBeInTheDocument();

    // getByRole('searchbox') finds the input via its implicit role
    const searchInput = screen.getByRole('searchbox', { name: 'Search products' });
    expect(searchInput).toBeInTheDocument();

    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('getByLabelText verifies label association — critical for WCAG 3.3.2', async () => {
    render(<SearchForm />);
    // This query succeeds only when <label htmlFor="search-input"> is correctly set
    // If the label's htmlFor is wrong or label is removed, this fails — catching a defect
    const input = screen.getByLabelText('Search products');
    expect(input).toHaveAttribute('type', 'search');
  });

  it('live region announces search query to screen readers', async () => {
    const user = userEvent.setup();
    render(<SearchForm />);

    await user.type(screen.getByLabelText('Search products'), 'laptop');
    await user.click(screen.getByRole('button', { name: 'Run search' }));

    // getByRole('status') finds the aria-live="polite" region
    const statusRegion = screen.getByRole('status');
    expect(statusRegion).toHaveTextContent('Searching for: laptop');
  });

  it('why getByTestId is a last resort: it passes even when accessible name is broken', async () => {
    // If aria-label="Run search" were removed, getByTestId would still find the input
    // because it queries by data-testid — bypassing the accessibility tree entirely.
    // This demonstrates why getByRole is superior: it enforces that names exist.
    const { container } = render(<SearchForm />);
    const inputByTestId = container.querySelector('[data-testid="search-input"]');
    expect(inputByTestId).not.toBeNull(); // Always passes — even if label is broken
    // Contrast: getByRole('searchbox', { name: 'Search products' }) would FAIL if label is removed
  });
});
```

**Why query priority matters for CI**: Teams using `getByTestId` exclusively write test cases that pass even when WCAG 3.3.2 (Labels or Instructions) is violated. `getByRole` and `getByLabelText` act as implicit WCAG conformance checks — they fail when the accessibility tree is broken, before axe runs.

---

## Anti-Patterns

1. **Using ARIA to override semantics without purpose**: `<div role="button">` without `tabIndex={0}` and keyboard handlers is worse than `<button>`. Native HTML elements carry built-in keyboard support and implicit roles.

2. **Removing focus outlines without replacement**: `outline: none` in CSS without providing an alternative visible focus indicator is a WCAG 2.4.7 defect and locks out keyboard-only users.

3. **Testing only with axe and calling it done**: axe-core catches ~57% of WCAG issues. Skipping keyboard and screen reader testing leaves nearly half of all defects undetected.

4. **Generic link text**: `<a href="/report">Click here</a>` fails WCAG 2.4.6. Screen reader users navigate by links in isolation; the link text must describe the destination.

5. **Placeholder text as label substitute**: `placeholder` disappears on typing; it fails WCAG 3.3.2 when used instead of a visible `<label>`. Users with cognitive disabilities often forget what the field asks.

6. **Auto-playing media**: Auto-playing video or audio without controls violates WCAG 1.4.2 and is disruptive to screen reader users.

7. **aria-label overuse on every element**: Adding `aria-label` to every `<div>` and `<span>` creates noise for screen reader users. Use ARIA only when native semantics are insufficient.

8. **Using `display: none` incorrectly for visually-hidden content**: Elements with `display: none` are removed from the accessibility tree (correct for truly hidden content). Elements hidden with only CSS `opacity: 0` or `transform` remain in the tab order — always use `display: none` or `inert` to fully hide interactive content from all users.

9. **Positive tabIndex values**: `tabIndex={1}`, `tabIndex={2}` create a separate tab order that overrides natural DOM order and causes severe confusion for keyboard users. Use only `tabIndex={0}` (include in tab order) or `tabIndex={-1}` (programmatic focus only).

10. **Using `toBeVisible()` as an accessibility check**: `toBeVisible()` in `@testing-library/jest-dom` checks CSS visibility but does NOT verify accessibility tree presence. An element with `aria-hidden="true"` passes `toBeVisible()` but is completely invisible to screen readers.

---

## Automated vs Manual Testing Split

axe-core's automated rules detect approximately **57% of WCAG 2.1 issues** (Deque research, confirmed in axe-core 4.11.4 README). The other ~43% require human judgment.

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

**Recommended split per sprint:**
- **Automated (CI — every PR)**: jest-axe for all component test cases; Playwright/axe for critical user flows
- **Manual keyboard (every sprint)**: QA engineer navigates every new page/flow without mouse
- **Screen reader (every sprint)**: NVDA + Firefox and VoiceOver + Safari for new interactive patterns
- **Full accessibility audit (quarterly or pre-major release)**: Expert review against WCAG 2.1 AA checklist

---

## Real-World Gotchas  [community]

1. **[community] axe flags color contrast as incomplete in JSDOM**: jest-axe running in JSDOM cannot compute computed styles, so color-contrast rules return `incomplete`. Run Playwright test cases for contrast. WHY: JSDOM has no rendering engine — computed color values are always empty strings.

2. **[community] Focus management in SPAs**: In React Router / Next.js apps, navigation does not automatically move focus to new content. After route transitions, focus stays on the clicked link. WHY: The browser's native focus management only fires on full page loads, not on DOM swaps.

3. **[community] Modal dialogs without `aria-modal="true"` expose background content**: Screen readers in Browse mode (NVDA + Firefox) read background content while a modal is open. Use `inert` attribute on background elements — the `aria-modal` attribute alone is not honored by VoiceOver on iOS.

4. **[community] axe passes while VoiceOver fails on custom widgets**: axe validates ARIA syntax but cannot test whether a custom combobox announces options correctly when arrowing through a list. WHY: axe-core is a static rule engine, not a screen reader simulation.

5. **[community] Playwright axe scans miss dynamically injected content**: Toast notifications or errors that appear after user action are not caught by a page-level axe scan at load time. WHY: The scan captures a point-in-time snapshot. Use `page.waitForSelector` before re-scanning dynamic regions.

6. **[community] tabIndex={0} on non-interactive elements without keyboard handler**: Adding `tabIndex={0}` to a `<div>` makes it reachable by Tab but it does not become operable via Enter/Space. WHY: Tab-reachability and keyboard activation are separate concerns; always pair `tabIndex={0}` with keydown handlers.

7. **[community] aria-label vs aria-labelledby: labelledby wins in VoiceOver**: When both `aria-label` and `aria-labelledby` are present, `aria-labelledby` takes precedence per ARIA spec. WHY: Teams that add `aria-label` expecting it to override an existing `aria-labelledby` label are surprised when the screen reader ignores it.

8. **[community] axe-core versions differ between jest-axe and @axe-core/playwright**: Teams running different axe-core versions in unit vs E2E test levels get inconsistent results. WHY: A rule that passes in jest-axe may fail in Playwright because the underlying axe-core transitive version differs. Pin axe-core explicitly.

9. **[community] aria-live="assertive" should be reserved for truly urgent messages**: Using `role="alert"` for routine status messages interrupts whatever the screen reader is currently announcing. WHY: `assertive` interrupts; `polite` waits. Most notifications are not urgent enough to interrupt.

10. **[community] iOS VoiceOver swipe navigation differs from NVDA browse mode**: A widget that works with NVDA + Firefox will often behave differently under VoiceOver + Safari on iOS. WHY: VoiceOver uses swipe gestures; `aria-modal` is not honored. The `inert` attribute is the only reliable way to prevent background content from being swiped to.

11. **[community] axe-core does not scan inside closed Shadow DOM**: Web components using closed Shadow DOM are invisible to axe-core. WHY: Design system components (Material Web, Shoelace, Lit) may have a clean axe scan while actual rendered components have contrast or label violations. Verify with real browser devtools.

12. **[community] Component unit test cases pass but full-page axe fails due to duplicate IDs**: A component using `id="close-btn"` passes unit test cases but fails `duplicate-id` in the real application where the component renders in multiple places. WHY: Unit test cases render in isolation; page-level Playwright scans see the full DOM.

13. **[community] React re-renders clear screen reader focus position**: When a React component re-renders due to state changes, the screen reader's virtual cursor can be reset. WHY: Debounce validation and use `aria-live` regions for error messages instead of conditionally rendering error elements inside the form flow.

14. **[community] Overriding native semantics with ARIA removes built-in behavior**: Adding `role="presentation"` to a `<button>` removes its button semantics entirely. WHY: ARIA roles replace native semantics rather than adding to them; use ARIA roles only when no native HTML equivalent exists.

15. **[community] axe-core minor version upgrades add new rules that break CI unexpectedly**: Deque ships new rules in minor versions of axe-core. WHY: Teams that pin `axe-core: "^4"` find CI failing after a dependency update. Best practice: plan a minor version upgrade every 3–5 months and treat axe rule changes like lint rule changes — review, fix, update the baseline.

16. **[community] @testing-library query priority directly reflects accessibility**: `getByRole` is the most accessible query because it uses the accessibility tree. WHY: Teams that use `getByTestId` exclusively write test cases that pass even when accessible names are broken — a form label can be removed and `getByTestId('email')` still finds the input. Use query priority: `getByRole` > `getByLabelText` > `getByPlaceholderText` > `getByText` > `getByTestId` (last resort only).

17. **[community] forced-colors mode breaks components that rely on background-color for visual boundaries**: Components that use `background-color` alone to visually distinguish form inputs, buttons, or selected states lose all visual differentiation in forced-colors mode. WHY: The OS overrides authored color; only `border`, `outline`, and `color` are preserved (as system colors). Test with Playwright's `forcedColors: 'active'` emulation.

18. **[community] axe-core 4.10+ `aria-dialog-name` rule fires on unnamed `role="dialog"` elements**: Earlier axe-core versions silently allowed `<div role="dialog">` with no accessible name. WHY: axe-core 4.10+ fires `aria-dialog-name` (WCAG 4.1.2) for dialogs missing `aria-label` or `aria-labelledby`. Teams upgrading from 4.8/4.9 experience unexpected CI failures. Every modal must now have an accessible heading linked via `aria-labelledby`.

19. **[community] NVDA Browse Mode vs Application Mode is the most common source of keyboard testing confusion**: NVDA operates in two modes. In Browse Mode (the default for web content), arrow keys navigate the virtual buffer and custom keyboard handlers are bypassed. WHY: Teams testing with keyboard only (no screen reader) validate that Tab/Enter/Space work, but never discover that NVDA Browse Mode swallows arrow key events, making custom datepickers and comboboxes completely inoperable. Always test interactive widgets with NVDA + Firefox.

20. **[community] `toBeVisible()` does NOT test accessibility tree visibility**: `toBeVisible()` in `@testing-library/jest-dom` checks CSS visibility but does not verify that an element is present in the ARIA accessibility tree. WHY: An element with `aria-hidden="true"` passes `toBeVisible()` but is completely invisible to screen readers. Use `toBeInTheDocument()` + axe checks for accessibility.

---

## Tradeoffs & Alternatives

### WCAG Conformance Level Comparison

| Level | Criteria count | Description | Practical requirement |
|-------|------|-------------|----------------------|
| A | 30 | Minimum | Baseline; removing A-level barriers is the floor |
| AA | 20 additional | Mid-range | **Legal standard** in US/EU/CA/AU; target for all public apps |
| AAA | 28 additional | Enhanced | Aspirational; W3C does not recommend entire-site AAA conformance |

**Why not AAA?** W3C explicitly states that AAA conformance for entire sites is not recommended because some criteria cannot be satisfied for all content types. For example, 1.4.6 (Contrast Enhanced, 7:1 ratio) would make many brand color palettes unusable.

**Why AA specifically?** AA adds the most critical criteria missing from A: color contrast (1.4.3), keyboard shortcuts (2.1.4), resize text without scroll (1.4.4), no content-on-hover surprises (1.4.13), pointer gesture alternatives (2.5.1), and text spacing overrides (1.4.12).

### WCAG 2.2 Criteria QA Teams Should Start Testing Now

WCAG 2.2 (published October 2023) adds 9 new criteria at A/AA. The EU Accessibility Act (EAA) compliance deadline (June 28, 2025) explicitly references WCAG 2.2 AA via EN 301 549 v3.3.2.

| Criterion | Level | What QA should test |
|---|---|---|
| 2.4.11 Focus Appearance | AA | Focus indicator must have ≥2px outline, ≥3:1 contrast ratio |
| 2.5.7 Dragging Movements | AA | All drag-and-drop has a single-pointer alternative (e.g., keyboard reorder) |
| 2.5.8 Target Size (Minimum) | AA | Interactive targets ≥ 24×24 CSS pixels |
| 3.3.8 Accessible Authentication | AA | No cognitive function test (no distorted CAPTCHAs) required for login |

### Tool Tradeoffs

| Tool | Pros | Cons | Best for |
|------|------|------|---------|
| axe-core (jest-axe) | Fast, CI-friendly, component-level | No contrast check in JSDOM | Unit/component CI gating |
| @axe-core/playwright | Real browser, catches contrast, dynamic content | Slower, needs live server | E2E CI gating |
| Lighthouse (Chrome) | Integrated in DevTools, accessibility + perf score | Less detailed rule set, can score 100 with real defects | Dashboard metrics, quick checks |
| WAVE | Visual overlay, education-friendly | Manual only, not automatable | Auditor walkthroughs |
| Pa11y | CLI + CI automation | Less comprehensive than axe | Lightweight CI pipelines |
| Deque WorldSpace | Enterprise audit workflow management | Commercial license | Large org compliance tracking |
| axe DevTools (Deque) | Guided issue reporting with fix guidance | Commercial | Developer-guided manual audits |

**Automated vs Manual split:** axe-core detects approximately **57% of WCAG 2.1 issues** automatically. The remaining ~43% require keyboard testing, screen reader verification, and cognitive review.

**When not to use AA-only automated testing:**
- Government/healthcare portals serving users with significant cognitive impairments may need AAA criteria (plain language, reading level)
- Applications used exclusively by internal technical staff can deprioritize full AAA, but AA remains legally required in many jurisdictions

### Known axe-core False Positives

When axe-core is wrong — situations requiring rule suppression with documentation:

1. **`duplicate-id` in Storybook/isolated component test cases**: Component testing frameworks render multiple instances of the same component in one DOM. Fix by providing unique IDs per test case, not by disabling the rule globally.

2. **`color-contrast` in JSDOM**: jest-axe reports `incomplete` (not a violation) for contrast because JSDOM cannot compute computed colors.

3. **`aria-required-parent` on portals**: Components rendered via React portals may be mounted outside their logical parent. Verify manually.

4. **`landmark-no-duplicate-banner` in micro-frontends**: When multiple micro-frontend apps render their own `<header>` within a shared shell, use `role="none"` on inner headers.

5. **`scrollable-region-focusable` false positive on overflow containers with keyboard-managed content**: axe-core 4.9+ fires this on `overflow: auto/scroll` containers without `tabIndex={0}`. Data grids with `role="grid"` / `role="listbox"` use roving tabindex instead — these are NOT false positives.

### Screen Reader Testing Matrix

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

---

## Key Resources

| Name | Type | URL | Why useful |
|------|------|-----|------------|
| WCAG 2.1 Quick Reference | Official spec | https://www.w3.org/WAI/WCAG21/quickref/ | Filterable list of all success criteria |
| WCAG 2.2 New Criteria | Official spec | https://www.w3.org/TR/WCAG22/ | 9 new criteria including target size and dragging; legally required under EU EAA |
| EU Accessibility Act (EAA) | Legal reference | https://ec.europa.eu/social/main.jsp?catId=1202 | EU private-sector accessibility law; June 28, 2025 compliance deadline |
| EN 301 549 v3.3.2 | Standard | https://www.etsi.org/deliver/etsi_en/301500_302000/301549/03.03.02_60/ | Technical standard for EAA; maps WCAG 2.2 AA to EU law |
| ARIA Authoring Practices Guide | Official guide | https://www.w3.org/WAI/ARIA/apg/ | Patterns for custom widgets |
| axe-core | Open source | https://github.com/dequelabs/axe-core | Rule documentation and changelog (v4.11.4 current as of 2026-04-28) |
| jest-axe | Open source | https://github.com/nickcolley/jest-axe | Jest integration for axe |
| @axe-core/playwright | Open source | https://github.com/dequelabs/axe-core-npm | Playwright integration |
| WebAIM Million Report | Research | https://webaim.org/projects/million/ | Most common real-world failures (contrast 81%, alt 55%, labels 49%) |
| WebAIM Screen Reader Survey | Research | https://webaim.org/projects/screenreadersurvey/ | Actual AT usage statistics |
| MDN ARIA reference | Reference | https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA | Role and attribute documentation |
| MDN forced-colors | Reference | https://developer.mozilla.org/en-US/docs/Web/CSS/@media/forced-colors | Windows High Contrast Mode CSS media feature |
| TPGi Colour Contrast Analyser | Tool | https://www.tpgi.com/color-contrast-checker/ | Desktop tool for manual contrast checking |

---

## ISTQB CTFL 4.0 Terminology Alignment

This guide uses ISTQB CTFL 4.0 standardized terminology to ensure consistency with industry certifications and onboarding materials. Key mappings for accessibility testing:

| ISTQB Term (preferred) | Avoid using | Context |
|---|---|---|
| **test case** | "test", "spec" | An individual axe scan or keyboard check is a test case |
| **test suite** | "test set" | A `.a11y.test.tsx` file is a test suite |
| **test level** | "test layer" | Unit (jest-axe), Integration (Playwright) are test levels |
| **defect** | "bug", "issue", "violation" | An axe `violation` result is a defect |
| **test condition** | "test scenario" | Each WCAG criterion is a test condition |
| **test object** | "component under test" | The React component or page is the test object |
| **test basis** | "test source" | WCAG 2.1/2.2 AA is the test basis for accessibility testing |

**Why this matters**: When accessibility findings are escalated to compliance teams, legal counsel, or procurement reviewers, ISTQB-aligned terminology prevents miscommunication. A "bug" implies a programming error; a "defect" is a deviation from a specified requirement (WCAG). Precision matters in accessibility audits, especially in legal contexts.
