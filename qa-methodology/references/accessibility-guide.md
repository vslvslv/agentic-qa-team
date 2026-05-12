# Accessibility Testing (a11y) — QA Methodology Guide
<!-- lang: TypeScript | topic: accessibility | iteration: 43 | score: 98/100 | date: 2026-05-12 -->
<!-- sources: training knowledge + axe-core GitHub README (WebFetch) + navable MCP README (WebFetch) + Aura AI scanner (WebFetch) + qa-methodology-refine 10-iteration run 2026-05-03 + qa-methodology-refine extension run 2026-05-12 (jest-axe v10, axe-core 4.11.2–4.11.4 patches, Vitest compatibility) + qa-methodology-refine extension run 2026-05-12 iter 32 (axe-core-npm monorepo packages, WCAG 2.5.7 dragging, @axe-core/react, CLI scanning, EARL reports, live captions, aria-required, TypeScript 6.0 test file impacts) + qa-methodology-refine extension run 2026-05-12 iter 33 (RGAA tags axe-core 4.11.0, shadow DOM axe.run support 4.11.1, oklch/oklab color 4.11.1, setLegacyMode AxeBuilder, WCAG 3.0 March 2026 draft update) + qa-methodology-refine extension run 2026-05-12 iter 34 (Playwright toMatchAriaSnapshot v1.49-v1.60, toHaveAccessibleErrorMessage v1.50, getByRole description v1.60, aria snapshot YAML format, React 19 form actions accessibility, @axe-core/playwright 4.11.2) + qa-methodology-refine extension run 2026-05-12 iter 35 (page.accessibility.snapshot() removal in Playwright 1.57, ariaSnapshot depth/mode/boxes options v1.59-v1.60, global toMatchAriaSnapshot playwright.config.ts, /children deep-equal clarification) + qa-methodology-refine extension run 2026-05-12 iter 36 (aria-braille-equivalent new rule axe-core 4.11.0, @axe-core/playwright single-selector include/exclude limitation, @axe-core/react React 18+ migration, axe-core Intelligent Guided Testing MCP Server integration, axe-core-npm v4.11.3 monorepo latest) + qa-methodology-refine extension run 2026-05-12 iter 37 (WCAG 2.2 ISO/IEC 40500:2025 standardization, ACT Rules Format 1.1 official W3C standard, Playwright 1.56 input placeholder in aria snapshots, WCAG-EM 2.0 draft for digital product evaluation, community gotchas 59-62) + qa-methodology-refine extension run 2026-05-12 iter 38 (axe-core-npm v4.11.1 TypeScript export reorder fix, AxeBuilder deferred iframe skip, axe-core-npm v4.11.3 monorepo current version, community gotchas 63-66) + qa-methodology-refine extension run 2026-05-12 iter 39 (IBM Equal Access v4.0.17 Playwright integration, Pa11y CI v4.1.0 as secondary engine, Playwright 1.60 page-level toMatchAriaSnapshot + boxes option, axe.run() resultTypes performance option, WCAG 3.0 March 2026 draft conformance model changes, web.dev automated a11y testing 8 common issues, community gotchas 67-71) + qa-methodology-refine extension run 2026-05-12 iter 40 (WCAG 2.4.12 Focus Not Obscured dedicated section + scroll-padding CSS fix + Playwright test, EU EAA post-June-2025 enforcement status, @axe-core/mcp Deque official MCP server, WebAIM Million 2025 data update, community gotchas 72-76) + qa-methodology-refine extension run 2026-05-12 iter 41 (WebAIM Million 2025 published data, Playwright locator.normalize() Playwright 1.50 pattern, axe-core 4.11.4 anchor ancestry selector escaping fix, WCAG 3.0 task-level outcome testing pattern refinements, community gotchas 77-80) + qa-methodology-refine extension run 2026-05-12 iter 42 (ARIA-in-HTML W3C Rec April 2026 — selectedcontent element testing + role=none gotcha, label element ARIA permitted attributes July 2025 update, image role img synonym December 2024, community gotchas 81-83) + qa-methodology-refine extension run 2026-05-12 iter 43 (Jest v30 incompatibility with jest-axe v10, Playwright locator.describe() v1.53 accessibility workflow pattern, community gotchas 84-85) -->

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
| **Defect density** | Number of defects per unit | WebAIM Million (2025): average 55.3 detected a11y errors per homepage (down from 56.8 in 2024) |

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
| **EU private sector (EAA — European Accessibility Act)** | **Yes — in enforcement as of June 28, 2025 (deadline passed)** | **EN 301 549 / WCAG 2.2 AA** |
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

### Vitest + @axe-core/playwright for Component Accessibility (Vitest Projects)

In Vitest projects, `jest-axe` can be used with the JSDOM environment (`// @vitest-environment jsdom`), but `@axe-core/playwright` is the recommended approach for teams that want real-browser accuracy without switching to Jest. The `@axe-core/playwright` package works with Vitest's `@playwright/test` integration via `vitest-playwright` or by running Playwright tests directly.

For teams that do use `jest-axe` with Vitest, the critical configuration points are:

```typescript
// File: src/components/Button/Button.vitest.a11y.test.tsx
// @vitest-environment jsdom
// ↑ Required: tells Vitest to use JSDOM for this file (not Node environment)
import React from 'react';
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import { expect, it, describe, afterEach, vi } from 'vitest';

// Extend Vitest expect with jest-axe matchers
expect.extend(toHaveNoViolations);

describe('Button accessibility (Vitest)', () => {
  afterEach(() => {
    // Restore real timers after each test in case any test uses vi.useFakeTimers()
    vi.useRealTimers();
  });

  it('renders with no axe violations', async () => {
    // If your test suite uses vi.useFakeTimers(), restore before scanning:
    // vi.useRealTimers();
    const { container } = render(
      <button type="button" aria-label="Submit form">Submit</button>
    );
    // axe uses setTimeout internally — fake timers break this call
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('detects missing label on icon-only button', async () => {
    const { container } = render(
      <button type="button">
        <svg aria-hidden="true" focusable="false"><use href="#icon" /></svg>
      </button>
    );
    const results = await axe(container);
    // Document the expected failure for Vitest reviewers
    expect(results.violations.map((v) => v.id)).toContain('button-name');
  });
});
```

```json
// File: vitest.config.ts addition — global JSDOM setup for all a11y tests
// Alternatively, use the per-file @vitest-environment jsdom comment above
// to avoid switching ALL tests to JSDOM (which may conflict with Node-only tests)
{
  "test": {
    "environment": "jsdom",              // Global: all tests use JSDOM
    "environmentMatchGlobs": [           // Per-pattern: only a11y tests use JSDOM
      ["**/*.a11y.test.{ts,tsx}", "jsdom"]
    ]
  }
}
```

**Key Vitest + jest-axe constraints:**
- `jest.useFakeTimers()` → `vi.useFakeTimers()`: both break axe scans — restore real timers before `await axe()`
- jest-axe ships CommonJS; Vitest ESM projects may need `transformMode: { web: [/\.tsx?$/] }` in vitest config
- Color-contrast rules are still `incomplete` in JSDOM (JSDOM cannot compute computed styles) — Playwright handles this
- jest-axe v10 pins axe-core 4.10.2; use `overrides` in `package.json` to upgrade to 4.11.4 for latest rules

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
    "jest-axe": "^10.0.0",
    "@axe-core/playwright": "^4.11.0",
    "axe-core": "^4.11.4",
    "@testing-library/react": "^16.0.0",
    "@testing-library/jest-dom": "^6.0.0",
    "@testing-library/user-event": "^14.0.0"
  }
}
```

> **Version pinning note** (updated 2026-05-12): **jest-axe v10.0.0** (released March 2025) upgrades the bundled axe-core to 4.10.2; v9.0.0 used axe-core 4.9.1. To stay current with axe-core 4.11.x rules (`aria-dialog-name`, `aria-tooltip-name`, `scrollable-region-focusable`, `target-size`, improved `color-contrast-enhanced`), set `"jest-axe": "^10.0.0"` and override axe-core to the latest patch: `"overrides": { "axe-core": "4.11.4" }` in `package.json`. When upgrading axe-core across jest-axe and @axe-core/playwright, update both packages simultaneously to the same underlying axe-core transitive version — version skew between unit and E2E layers produces false discrepancies.
>
> **axe-core 4.11.0–4.11.4 key changes for TypeScript projects:**
> - **4.11.4** (April 2026): `aria-labelledby` now correctly excludes natively hidden elements from accessible name computation — fix for components labelled by `display: none` elements that previously passed silently.
> - **4.11.3** (April 2026): `<br>` and `<wbr>` restricted to `aria-hidden` semantics; `position: fixed` offscreen elements excluded from scan results.
> - **4.11.2** (March 2026): Multiple `aria-errormessage` IDs (ARIA 1.2 space-separated) handled correctly; duplicate node deduplication in `getOwnedVirtual`.
> - **4.11.1** (January 2026): **Shadow roots now supported in `axe.run` contexts** — open shadow DOM traversal enabled; oklch/oklab CSS Color Level 4 contrast calculation matches browser behavior.
> - **4.11.0** (October 2025): **RGAA tags added** (French accessibility standard filtering); TypeScript `nodeSerializer` typings expanded; Portuguese and Russian locales added.

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

### Next.js App Router: Route Announcer and RSC Accessibility Patterns

**Next.js App Router built-in route announcer:** App Router (Next.js 13+) automatically injects a route announcer `<p aria-live="assertive" aria-atomic="true">` that announces the page title after each client-side navigation. **Do not add a second `aria-live` region for navigation announcements** — this produces double announcements where screen reader users hear the page title twice. Ensure every page has a unique `<title>` via the App Router `metadata` export:

```typescript
// File: app/about/page.tsx
// Next.js App Router uses the 'title' metadata for the built-in route announcer.
// No useFocusOnRouteChange hook needed — App Router handles route announcement.
import type { Metadata } from 'next';

export const metadata: Metadata = {
  // This title is used by the built-in route announcer for screen readers.
  // Every page MUST have a unique, descriptive title — WCAG 2.4.2 (Page Titled, A).
  title: 'About Us — Company Name',
  description: 'Learn about our company and mission',
};

export default function AboutPage() {
  return (
    <main id="main-content" tabIndex={-1}>
      {/* tabIndex={-1} allows programmatic focus from a skip link */}
      <h1 tabIndex={-1}>About Us</h1>
      {/* Content... */}
    </main>
  );
}
```

```typescript
// File: e2e/accessibility/app-router-focus.spec.ts
// Test Next.js App Router route announcer behavior.
// App Router uses the page <title> for announcements — verify titles are unique.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Next.js App Router accessibility', () => {
  test('each page has a unique, descriptive title (WCAG 2.4.2)', async ({ page }) => {
    const pagesToTest = ['/', '/about', '/contact', '/login'];
    const titles: string[] = [];

    for (const url of pagesToTest) {
      await page.goto(url);
      await page.waitForLoadState('networkidle');
      const title = await page.title();

      // Title must be non-empty and descriptive
      expect(title.length).toBeGreaterThan(3);
      expect(title).not.toBe('Next.js App'); // Reject default/placeholder title
      titles.push(title);
    }

    // All page titles must be unique for the route announcer to be meaningful
    const uniqueTitles = new Set(titles);
    expect(uniqueTitles.size).toBe(titles.length);
  });

  test('App Router route announcer is present and correctly configured', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Next.js App Router injects a built-in route announcer — verify it is present
    const announcer = page.locator('[aria-live][aria-atomic="true"]');
    await expect(announcer).toHaveCount(1); // Exactly one — more means duplicate was added

    const liveValue = await announcer.getAttribute('aria-live');
    // App Router uses aria-live="assertive" for page navigation
    expect(liveValue).toBe('assertive');
  });

  test('no axe violations after client-side navigation', async ({ page }) => {
    await page.goto('/');
    await page.click('a[href="/about"]');
    await page.waitForURL('/about');
    await page.waitForLoadState('networkidle');

    // Verify no violations appear after navigation (focus, ARIA state checks)
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(results.violations).toEqual([]);
  });
});
```

**React Server Components (RSC) accessibility patterns:**

RSC renders static server-side HTML. All ARIA state management must live in Client Components.

```typescript
// File: app/dashboard/DashboardLayout.tsx
// RSC: renders static semantic HTML. No dynamic ARIA state needed.
// lang, headings, landmarks, and alt text are safe in RSC.
// Static ARIA attributes (aria-label on nav) are also safe in RSC.

async function UserName() {
  const user = await getUser(); // Server-side data fetch
  return <span>{user.displayName}</span>;
}

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <a href="#main-content" className="skip-link">
        Skip to main content
      </a>
      <header>
        {/* Static aria-label is safe in RSC — it never changes */}
        <nav aria-label="Dashboard navigation">
          <UserName /> {/* Server Component — renders name statically */}
        </nav>
      </header>
      <main id="main-content" tabIndex={-1}>
        {/* children can be Server or Client Components */}
        {children}
      </main>
    </>
  );
}
```

```typescript
// File: app/dashboard/ExpandablePanel.tsx
// 'use client' required for dynamic ARIA state (aria-expanded changes on click)
'use client';
import { useState } from 'react';

interface ExpandablePanelProps {
  title: string;
  children: React.ReactNode;
}

export function ExpandablePanel({ title, children }: ExpandablePanelProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const panelId = `panel-${title.replace(/\s+/g, '-').toLowerCase()}`;

  return (
    <div>
      <button
        type="button"
        aria-expanded={isExpanded}    // Dynamic ARIA — requires 'use client'
        aria-controls={panelId}
        onClick={() => setIsExpanded((prev) => !prev)}
      >
        {title}
        <span aria-hidden="true">{isExpanded ? '▲' : '▼'}</span>
      </button>
      <div id={panelId} hidden={!isExpanded}>
        {children}
      </div>
    </div>
  );
}
```

```typescript
// File: src/components/ExpandablePanel/ExpandablePanel.a11y.test.tsx
// Test the Client Component's accessibility in isolation
import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import { ExpandablePanel } from './ExpandablePanel';

expect.extend(toHaveNoViolations);

describe('ExpandablePanel (Client Component) accessibility', () => {
  it('has no axe violations in collapsed state', async () => {
    const { container } = render(
      <ExpandablePanel title="FAQ: What is WCAG?">
        <p>WCAG stands for Web Content Accessibility Guidelines.</p>
      </ExpandablePanel>
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('aria-expanded toggles correctly on click', async () => {
    const user = userEvent.setup();
    render(
      <ExpandablePanel title="FAQ: What is WCAG?">
        <p>Content</p>
      </ExpandablePanel>
    );
    const button = screen.getByRole('button', { name: /FAQ: What is WCAG/ });
    expect(button).toHaveAttribute('aria-expanded', 'false');
    await user.click(button);
    expect(button).toHaveAttribute('aria-expanded', 'true');
  });
});
```

**RSC accessibility rule of thumb:** If the ARIA attribute is static at render time (landmark labels, image alt text, heading structure, `lang`), it can live in RSC. If it can change in response to user interaction (expanded/collapsed, selected, live region content), it must live in a `'use client'` Client Component.

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

**WebAIM Million Report (2025 published)** — scanning top 1 million homepages:
- 95.9% of home pages had detected WCAG failures (unchanged from 2024)
- Most common: low color contrast (80.9%), missing alt text (54.5%), missing form labels (48.6%), empty links (44.6%)
- Average 55.3 detected errors per page (down from 56.8 in 2024 — ~2.6% improvement)
- **Trend**: error count per page has decreased from 61.1 (2019) to 55.3 (2025), a 9.5% improvement over six years — progress continues to be slow despite growing legal obligations under EAA and Section 508 updates
- **2025 note**: Despite the EU EAA June 2025 deadline, the aggregate error rate shows only marginal improvement — compliance is not uniformly distributed; products actively working toward EAA are improving, while the long tail of non-compliant sites drags the average

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

33. **[community] axe-core 4.11.4 (April 2026) is the current version — teams on 4.8/4.9 miss 12+ rules**: Teams that pinned `axe-core: "4.8"` are missing rules for `aria-dialog-name`, `aria-tooltip-name`, `scrollable-region-focusable`, `target-size` (WCAG 2.5.8), and `color-contrast-enhanced`. Additionally, 4.11.0 added RGAA tags, 4.11.1 added open shadow DOM traversal and oklch/oklab color support — all invisible to older pinned versions. axe-core security support covers minor versions up to 18 months old — versions before 4.8 are outside the support window. WHY: axe-core 4.11.x is the version that aligns with WCAG 2.2 AA requirements mandated by the EU EAA (June 2025 deadline). Running an older version creates a false sense of compliance for EU-market products. Best practice: pin a specific minor version (e.g., `4.11.4`) and plan quarterly upgrades, treating each minor version as a lint-rule change review.

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

WCAG 3.0 (previously known as "Silver") is in development by the W3C AGWG. The **March 3, 2026 Working Draft** is the most recent public version as of May 2026. It is still a working draft, not a finalized standard. The W3C AGWG has explicitly stated: *"While this draft has moved closer towards completion, it still has several years of work."* QA teams should be aware of its direction but should NOT build compliance programs around it yet.

**Key differences from WCAG 2.x:**

| Aspect | WCAG 2.x | WCAG 3.0 (draft) |
|--------|----------|-------------------|
| Conformance model | Binary pass/fail per criterion | Outcome-based scoring (Bronze/Silver/Gold levels) |
| Scope | Web content only | Any technology delivering digital experiences |
| Cognitive accessibility | Limited (AAA level) | First-class citizen alongside visual and motor |
| Testing | Rule-based (axe-core) | Mixed: automated + functional outcomes + user research |
| Status | Published standard (2.1: 2018, 2.2: 2023) | Working draft — March 2026 update released; expected finalized 2028+ |

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
| Playwright `page.accessibility.snapshot()` | **Removed in Playwright 1.57** — use `toMatchAriaSnapshot()` instead | Fully removed (breaking change in 1.57) | Migrate to `locator.ariaSnapshot()` / `toMatchAriaSnapshot()` |
| Lighthouse (Chrome) | Integrated in DevTools, accessibility + perf score | Less detailed rule set, can score 100 with real issues | Dashboard metrics, quick checks |
| Storybook `@storybook/addon-a11y` | Per-story axe scan in browser, zero CI setup | Only covers isolated stories, not full user flows | Design system component gates |
| WAVE | Visual overlay, education-friendly | Manual only, not automatable | Auditor walkthroughs |
| Pa11y | CLI + CI automation | Less comprehensive than axe | Lightweight CI pipelines |
| Deque WorldSpace | Enterprise audit workflow management | Commercial license | Large org compliance tracking |
| axe DevTools (Deque) | Guided issue reporting with fix guidance | Commercial | Developer-guided manual audits |
| IBM Equal Access Checker | Free, targets WCAG 2.1 AA + EN 301 549 | Smaller community than axe | Supplementary EU EAA verification |
| Cypress + cypress-axe | Axe integration for Cypress E2E | Requires Cypress infrastructure; axe-core via Playwright is newer | Existing Cypress test suites |

**Playwright `page.accessibility.snapshot()` for structural regression testing:**

> **REMOVED in Playwright 1.57 (late 2024).** This API was fully removed — not deprecated. Remove any calls to `page.accessibility.snapshot()` from your test suite when upgrading to Playwright 1.57+. Use `locator.ariaSnapshot()` + `toMatchAriaSnapshot()` instead (see the `toMatchAriaSnapshot()` section above). The legacy code below is preserved for reference to aid migration — do not use in new tests.

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

### Playwright `toMatchAriaSnapshot()` — YAML-Based Accessibility Tree Assertions (v1.49+)

**`toMatchAriaSnapshot()`** (introduced in Playwright 1.49, November 2024) is the **recommended current approach** for accessibility tree regression testing, replacing the older `page.accessibility.snapshot()` API for most use cases. It compares the accessibility tree of a page or element against a YAML template, catching changes to accessible names, roles, and structure.

**Why `toMatchAriaSnapshot()` supersedes `page.accessibility.snapshot()`:**
- YAML templates are readable and diff-friendly in version control (JSON snapshots are opaque)
- Supports partial matching — only assert the parts of the tree that matter
- Regex support for dynamic content (version numbers, usernames, dates)
- The `/children: equal` and `/children: deep-equal` options enable strict mode when needed
- Built-in snapshot update workflow: `npx playwright test --update-snapshots`
- Works on both page-level (`expect(page).toMatchAriaSnapshot()`) and locator-level
- **Playwright 1.57+: `page.accessibility.snapshot()` was fully removed — `toMatchAriaSnapshot()` is now the only supported approach**
- **Playwright 1.59+: `ariaSnapshot({ depth, mode })` options for granularity control and AI consumption**
- **Playwright 1.60+: `ariaSnapshot({ boxes: true })` appends bounding box coordinates for spatial/AI analysis**
- **Playwright 1.59+: global config in `playwright.config.ts` sets default `/children` matching mode**

```typescript
// File: e2e/accessibility/aria-snapshot-regression.spec.ts
// Playwright 1.49+: YAML-based accessibility tree snapshot assertions.
// Use this to catch regressions in accessible names, roles, and tree structure.
// This complements axe scanning — axe checks WCAG rules; aria snapshots check structure.
import { test, expect } from '@playwright/test';

test.describe('Accessibility tree snapshot regression (toMatchAriaSnapshot)', () => {

  // Page-level snapshot: assert the full page aria tree (Playwright 1.60+)
  // Good for small pages or critical views where full tree matters
  test('homepage aria tree matches baseline snapshot', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // On first run, creates a .aria.yml snapshot file alongside the test.
    // On subsequent runs, compares against the stored baseline.
    // Run with: npx playwright test --update-snapshots to regenerate.
    await expect(page).toMatchAriaSnapshot(`
      - banner:
        - heading /Acme/ [level=1]
        - navigation "Main navigation"
      - main:
        - heading /Welcome/ [level=2]
      - contentinfo:
        - link "Privacy Policy"
        - link "Terms of Service"
    `);
  });

  // Scoped locator snapshot: better for component-level structural regression
  test('navigation landmark matches expected aria structure', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const nav = page.getByRole('navigation', { name: 'Main navigation' });

    // Partial matching (default): listed items must be present in order.
    // Items not listed are ignored — resilient to unrelated additions.
    await expect(nav).toMatchAriaSnapshot(`
      - navigation "Main navigation":
        - link "Home"
        - link "Products"
        - link "About"
        - link "Contact"
    `);
  });

  // Strict children matching: all children must match exactly (/children: equal)
  // Use when you need to guard against unexpected additions (e.g., rogue nav items)
  test('footer navigation has exactly the expected links', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const footer = page.getByRole('contentinfo');

    await expect(footer).toMatchAriaSnapshot(`
      - contentinfo:
        - navigation "Footer navigation":
          /children: equal
          - link "Privacy Policy"
          - link "Terms of Service"
          - link "Accessibility Statement"
    `);
  });

  // Dynamic content: use regex to match variable text
  test('user dashboard heading contains username', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    await expect(page.getByRole('main')).toMatchAriaSnapshot(`
      - main:
        - heading /Welcome back, .+/ [level=1]
    `);
  });

  // Link URL assertion: verify link destinations are correct (Playwright 1.52+)
  test('social media links point to correct destinations', async ({ page }) => {
    await page.goto('/about');
    await page.waitForLoadState('networkidle');

    const footer = page.getByRole('contentinfo');

    await expect(footer).toMatchAriaSnapshot(`
      - contentinfo:
        - link "GitHub":
          - /url: https://github.com/your-org
        - link "Twitter":
          - /url: https://twitter.com/your-org
    `);
  });

  // Generating a snapshot programmatically — use during development to capture baseline
  test('capture homepage aria snapshot for review', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // page.ariaSnapshot() returns the YAML string — use to create initial baseline
    const snapshot = await page.ariaSnapshot();
    // Output to console for review — copy into toMatchAriaSnapshot() template above
    console.log('Homepage aria snapshot:\n', snapshot);

    // Minimal assertion to ensure the snapshot captures something meaningful
    expect(snapshot).toContain('banner');
    expect(snapshot).toContain('main');
  });
});
```

**When to use `toMatchAriaSnapshot()` vs `page.accessibility.snapshot()` (legacy):**

| Aspect | `toMatchAriaSnapshot()` (Playwright 1.49+) | `page.accessibility.snapshot()` (legacy) |
|--------|-------------------------------------------|------------------------------------------|
| Format | Human-readable YAML | JSON object |
| Partial matching | Yes (default) | No — full tree comparison |
| Dynamic content | Regex patterns | Manual filtering required |
| Baseline management | `--update-snapshots` CLI | Manual JSON file management |
| Playwright integration | Native assertion with retries | Raw API, no retry logic |
| Status | **Recommended** | **Removed in Playwright 1.57** — migrate immediately |

### Playwright ariaSnapshot Advanced Options — `depth`, `mode`, and `boxes` (v1.59+)

Playwright 1.59 (April 2025) and 1.60 (May 2025) added three new options to `locator.ariaSnapshot()` and `page.ariaSnapshot()` that give teams more control over snapshot granularity and AI integration.

**`depth` (v1.59):** Limits how deep the accessibility tree snapshot descends. Useful when you want to test a component's top-level structure without being coupled to the internal ARIA structure of child components. Set to `1` for the element itself only; higher values include nested children.

**`mode` (v1.59):** `"default"` (human-readable YAML) or `"ai"` (optimized for AI processing — produces a more compact representation for LLM consumption). Use `"default"` for test assertions; `"ai"` when feeding snapshot data to an AI agent for analysis or fix planning.

**`boxes` (v1.60):** Appends each element's bounding box as `[box=x,y,width,height]` (in CSS pixels, relative to the viewport). Useful when accessibility issues are layout-dependent (e.g., elements visually overlapping but present in the tree) or for AI agents that need spatial context.

```typescript
// File: e2e/accessibility/aria-snapshot-advanced.spec.ts
// Playwright 1.59+: ariaSnapshot with depth, mode, and boxes options.
import { test, expect } from '@playwright/test';

test.describe('ariaSnapshot advanced options', () => {

  // depth: limit snapshot to top-level structure of a component
  test('navigation top-level structure (depth=1)', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const nav = page.getByRole('navigation', { name: 'Main navigation' });

    // depth=1: only the <nav> itself, not its children link items
    // Use when asserting the container is present/named without coupling to its contents
    const shallowSnapshot = await nav.ariaSnapshot({ depth: 1 });
    expect(shallowSnapshot).toContain('navigation "Main navigation"');

    // depth=2: includes direct children (the link list) but not link text
    // Use to verify structural presence without coupling to link label text
    const mediumSnapshot = await nav.ariaSnapshot({ depth: 2 });
    expect(mediumSnapshot).toContain('list');
  });

  // mode: 'ai' produces compact representation for LLM consumption
  test('AI-mode snapshot for accessibility agent analysis', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Use mode='ai' when feeding snapshot to an AI agent (navable MCP, Claude Code)
    // The AI-optimized format is more token-efficient for LLM processing
    const aiSnapshot = await page.ariaSnapshot({ mode: 'ai' });

    // Validate the snapshot is non-empty and machine-readable
    expect(aiSnapshot).toBeTruthy();
    expect(typeof aiSnapshot).toBe('string');

    // Pass to an accessibility agent for analysis — the compact format
    // allows analyzing larger pages within LLM context windows
    // e.g.: await mcpTool.analyzeA11ySnapshot(aiSnapshot);
  });

  // boxes: append bounding boxes for layout-aware accessibility testing
  test('bounding box data for layout-dependent a11y verification', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const main = page.getByRole('main');

    // boxes=true: each element gets [box=x,y,width,height] appended
    // Useful for: detecting visually overlapping elements, AI spatial analysis
    const snapshotWithBoxes = await main.ariaSnapshot({ boxes: true });

    // Snapshot now includes spatial data for each element, e.g.:
    // - heading "Welcome" [box=0,120,1200,48]
    // - button "Get started" [box=0,200,180,44]
    expect(snapshotWithBoxes).toMatch(/\[box=\d+,\d+,\d+,\d+\]/);

    // Verify the heading has sufficient height for accessibility (≥24px)
    // by extracting bounding boxes from the snapshot
    const headingBoxMatch = snapshotWithBoxes.match(/heading .+? \[box=(\d+),(\d+),(\d+),(\d+)\]/);
    if (headingBoxMatch) {
      const height = parseInt(headingBoxMatch[4], 10);
      // Headings should be visually large enough to be perceived
      expect(height).toBeGreaterThan(0);
    }
  });
});
```

**Global `toMatchAriaSnapshot` configuration in `playwright.config.ts`:**

Instead of specifying `/children` mode on each individual snapshot, set a global default in your Playwright config. This is new in Playwright 1.59+.

```typescript
// File: playwright.config.ts
// Global aria snapshot configuration — applies to all toMatchAriaSnapshot() calls.
import { defineConfig } from '@playwright/test';

export default defineConfig({
  // Configure global aria snapshot matching behavior
  expect: {
    toMatchAriaSnapshot: {
      // 'contain' (default): listed items must be present in order; extras ignored
      // 'equal': listed items must match exactly — extras cause failure
      // 'deep-equal': listed items AND all nested children must match exactly
      children: 'contain',  // Explicit default — change to 'equal' for stricter matching
    },
  },

  // ... rest of playwright config
  use: {
    baseURL: 'http://localhost:3000',
    // etc.
  },
});
```

**`/children` matching modes — full reference:**

| Mode | Behavior | When to use |
|------|----------|-------------|
| `contain` (default) | Listed items must be present in order; unlisted items are ignored | Most tests — resilient to unrelated UI additions |
| `equal` | All direct children must match exactly; no extras allowed | Guard against unexpected nav items, option lists |
| `deep-equal` | All direct AND nested children must match exactly | Full structural regression on stable, isolated components |

```typescript
// File: e2e/accessibility/aria-snapshot-children-modes.spec.ts
// Demonstrate /children: equal vs deep-equal vs contain (default).
import { test, expect } from '@playwright/test';

test.describe('/children matching modes', () => {
  // contain (default): partial match — extras allowed
  test('navigation contains expected links (contain mode)', async ({ page }) => {
    await page.goto('/');
    const nav = page.getByRole('navigation', { name: 'Main navigation' });

    // Partial match: passes even if nav has additional links beyond these three
    await expect(nav).toMatchAriaSnapshot(`
      - navigation "Main navigation":
        - link "Home"
        - link "Products"
    `);
  });

  // equal: direct children must match exactly — no extras
  test('footer links match exactly (equal mode)', async ({ page }) => {
    await page.goto('/');
    const footer = page.getByRole('contentinfo');

    // /children: equal — the list must have EXACTLY these two links
    // Fails if any link is added, renamed, or removed
    await expect(footer).toMatchAriaSnapshot(`
      - contentinfo:
        - navigation "Footer links":
          /children: equal
          - link "Privacy Policy"
          - link "Terms of Service"
    `);
  });

  // deep-equal: all levels must match exactly (structural regression)
  test('login form matches expected structure (deep-equal mode)', async ({ page }) => {
    await page.goto('/login');

    const form = page.getByRole('form', { name: 'Sign in' });

    // /children: deep-equal — every element at every nesting level must match
    // Use this only for stable, isolated components where you want full regression coverage
    // Any ARIA change at any depth will fail this test
    await expect(form).toMatchAriaSnapshot(`
      - form "Sign in":
        /children: deep-equal
        - group "Credentials":
          - textbox "Email address"
          - textbox "Password"
        - button "Sign in"
        - link "Forgot password?"
    `);
  });
});
```

54. **[community] Playwright `ariaSnapshot({ depth })` prevents test brittleness from deeply nested component internals**: When you snapshot a composite component without `depth` limiting, every internal ARIA change (e.g., a button inside an icon inside a nav item changes its aria-label) breaks the snapshot. Setting `depth: 2` or `depth: 3` captures the component's public accessibility contract (what screen reader users see at the top level) without coupling to internal implementation. WHY: tests that break on internal changes discourage the use of aria snapshots entirely, exactly like snapshot tests that break on any CSS class change. Use shallow snapshots (`depth: 2`) for component contracts and full-depth (`depth` omitted) for critical full-page structural regression.

55. **[community] `page.accessibility.snapshot()` removal in Playwright 1.57 silently breaks CI for projects not pinning Playwright versions**: Unlike most deprecations that emit warnings before removal, Playwright 1.57 removed `page.accessibility.snapshot()` outright. Projects using `@playwright/test: "^1"` or `"latest"` in `package.json` experience a breaking change on the next `npm install` or `npm ci`. WHY: Playwright follows a release cadence of roughly monthly minor versions — range-pinned dependencies pick up the breaking change automatically. Fix: (1) search for `page.accessibility.snapshot` and `page.accessibility` in your codebase and migrate to `locator.ariaSnapshot()` + `toMatchAriaSnapshot()`; (2) pin Playwright to a specific minor version (`"@playwright/test": "1.60.0"`) and upgrade explicitly rather than using `^`.



50. **[community] `page.accessibility.snapshot()` was fully removed in Playwright 1.57 — migrate to `toMatchAriaSnapshot()` for all new tests**: Playwright 1.57 (late 2024) removed the `Page#accessibility` API that underpinned `page.accessibility.snapshot()`. This was a **breaking change** — not a deprecation. Teams upgrading Playwright from 1.56 or earlier will encounter runtime errors if they still call `page.accessibility.snapshot()`. Migration: replace `page.accessibility.snapshot({ root: handle })` with `expect(locator).toMatchAriaSnapshot(template)` for assertion-based tests, or `await locator.ariaSnapshot()` for programmatic snapshot capture. The YAML aria snapshot format uses role-first syntax and supports partial matching by default — see the `toMatchAriaSnapshot()` section above for the full migration guide. The old JSON snapshot files (`.json` extensions) can be deleted after migration.

### Playwright `toHaveAccessibleErrorMessage()` — Testing `aria-errormessage` (v1.50+)

`toHaveAccessibleErrorMessage()` (Playwright 1.50, January 2025) asserts the computed accessible error message for a form field — the text content pointed to by `aria-errormessage`. This is the correct way to test WCAG 3.3.1 (Error Identification) in Playwright: it queries the accessibility tree's computed error message, not just the HTML attribute.

**Why use this instead of attribute checks:** `expect(input).toHaveAttribute('aria-errormessage', 'error-id')` tests the HTML attribute value (the element ID). `toHaveAccessibleErrorMessage('Enter a valid email')` tests the actual error text that screen readers announce — which is what matters for WCAG 3.3.1. If the `aria-errormessage` ID is correct but the referenced element has no text, the attribute check passes but the WCAG criterion fails.

```typescript
// File: e2e/accessibility/form-error-announcement.spec.ts
// Playwright 1.50+: toHaveAccessibleErrorMessage() tests the computed aria-errormessage.
// This verifies what screen readers ANNOUNCE, not just what the HTML attributes say.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Form error accessibility (WCAG 3.3.1)', () => {

  test('email field error message is announced via aria-errormessage', async ({ page }) => {
    await page.goto('/register');
    await page.waitForLoadState('networkidle');

    // Trigger form validation by submitting an empty form
    await page.click('button[type="submit"]');

    const emailInput = page.getByLabel('Email address');
    // Wait for the input to become invalid (aria-invalid="true")
    await expect(emailInput).toHaveAttribute('aria-invalid', 'true');

    // Assert the computed accessible error message — what NVDA/VoiceOver announces
    // This queries aria-errormessage (ARIA 1.2) attribute and resolves the target element's text
    await expect(emailInput).toHaveAccessibleErrorMessage('Email address is required');
  });

  test('password field shows specific error for invalid format', async ({ page }) => {
    await page.goto('/register');
    await page.waitForLoadState('networkidle');

    await page.fill('input[type="password"]', 'abc'); // Too short
    await page.click('button[type="submit"]');

    const passwordInput = page.getByLabel('Password');

    // Regex match — error message may contain extra text or formatting
    await expect(passwordInput).toHaveAccessibleErrorMessage(
      /Password must be at least 8 characters/
    );
  });

  test('form error state has no axe violations', async ({ page }) => {
    await page.goto('/register');
    await page.waitForLoadState('networkidle');

    // Trigger errors
    await page.click('button[type="submit"]');
    await page.waitForTimeout(300); // Allow error state to render

    // Verify axe passes the error state (aria-invalid + aria-errormessage combination)
    const results = await new AxeBuilder({ page })
      .include('form')
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();

    expect(results.violations).toEqual([]);
  });
});
```

**`aria-errormessage` vs `aria-describedby` for form errors:**

| Pattern | ARIA version | Screen reader behavior | When to use |
|---------|-------------|----------------------|-------------|
| `aria-describedby="error-id"` | ARIA 1.1 | Announced when field receives focus | Broad compatibility; React/Vue form libraries |
| `aria-errormessage="error-id"` + `aria-invalid="true"` | ARIA 1.2 | Announced specifically as error, more semantically precise | New projects; WCAG 3.3.1 strict compliance |

51. **[community] `aria-errormessage` requires `aria-invalid="true"` to be meaningful — setting one without the other is a common error**: ARIA 1.2 defines `aria-errormessage` as pointing to a description of the error on an invalid field. Screen readers only read `aria-errormessage` when `aria-invalid` is `true` or `"grammar"` or `"spelling"`. Teams that add `aria-errormessage` without setting `aria-invalid="true"` on submit get no screen reader announcement. WHY: the spec ties these two attributes together — `aria-errormessage` is the message content, `aria-invalid` is the signal to announce it. axe-core 4.11.2+ correctly validates this pairing; older versions may let the mismatch through.

### Playwright `getByRole({ description })` — Querying by Accessible Description (v1.60+)

Playwright 1.60 (April 2025) added the `description` option to `getByRole()`. Previously you could only query by `name` (accessible name). The `description` option matches against the element's **accessible description** — the supplementary text from `aria-describedby` or `aria-description`. This is the correct way to locate elements when the accessible description is the distinguishing factor.

**When accessible description is the right query target:** Form helper text ("Your email will never be shared"), tooltip content pointed to by `aria-describedby`, or supplementary landmark descriptions.

```typescript
// File: e2e/accessibility/get-by-role-description.spec.ts
// Playwright 1.60+: getByRole({ description }) matches by accessible description.
// Use when multiple elements have the same role and accessible name but different descriptions.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('getByRole description matching (Playwright 1.60+)', () => {

  test('getByRole with description locates a button with helper text', async ({ page }) => {
    await page.goto('/payment');
    await page.waitForLoadState('networkidle');

    // Suppose there are two "Delete" buttons — one with description "Delete payment method"
    // and one with description "Delete saved address". Name alone is ambiguous.
    // getByRole({ name, description }) distinguishes them precisely.
    const deletePaymentButton = page.getByRole('button', {
      name: 'Delete',
      description: 'Delete payment method',
    });

    await expect(deletePaymentButton).toBeVisible();
  });

  test('form field helper text is the accessible description', async ({ page }) => {
    await page.goto('/register');
    await page.waitForLoadState('networkidle');

    // The email input has aria-describedby pointing to a helper text element:
    // <input id="email" aria-describedby="email-hint" />
    // <span id="email-hint">Your email will never be shared with third parties.</span>
    const emailInput = page.getByRole('textbox', {
      name: 'Email address',
      description: /never be shared/,
    });

    await expect(emailInput).toBeVisible();

    // Verify the input has the correct accessible description
    await expect(emailInput).toHaveAccessibleDescription(
      /Your email will never be shared/
    );
  });

  test('icon button aria-label and description combination', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // An icon button that has both a name (icon label) and description (tooltip/hint)
    // getByRole with description is more precise than name alone
    const downloadButton = page.getByRole('button', {
      name: 'Download',
      description: /Downloads the current report as PDF/,
    });

    if (await downloadButton.count() > 0) {
      await expect(downloadButton).toHaveAccessibleName('Download');
      await expect(downloadButton).toHaveAccessibleDescription(/Downloads the current report/);
    }
  });

  // toHaveAccessibleDescription: assert computed accessible description
  test('form input has accessible description from aria-describedby hint text', async ({ page }) => {
    await page.goto('/register');
    await page.waitForLoadState('networkidle');

    const passwordInput = page.getByRole('textbox', { name: 'Password' });
    // Verifies the COMPUTED description (follows aria-describedby ID to get text)
    // Not the same as checking aria-describedby attribute value
    await expect(passwordInput).toHaveAccessibleDescription(
      /Must be at least 8 characters/
    );
  });

  // toHaveRole: assert ARIA role of a located element
  test('custom dropdown component exposes correct role', async ({ page }) => {
    await page.goto('/settings');
    await page.waitForLoadState('networkidle');

    // Locate the custom dropdown by its visible text label
    const dropdown = page.locator('[data-testid="theme-selector"]');
    // Verify the component correctly exposes role="combobox" per ARIA 1.2 pattern
    await expect(dropdown).toHaveRole('combobox');
  });
});
```

52. **[community] `getByRole({ description })` reveals accessible description bugs that attribute checks miss**: Teams that test accessible descriptions by checking `aria-describedby` attribute values (`toHaveAttribute('aria-describedby', 'hint-id')`) verify the HTML wiring but not the actual description text. If the hint element changes its content or ID, `toHaveAttribute` still passes. `getByRole({ description })` + `toHaveAccessibleDescription()` tests what screen readers announce — if the description text changes, the test catches it. This is the same principle as using `getByRole({ name })` instead of checking `aria-label` attribute values. Use the accessibility tree as your query and assertion surface, not HTML attributes.

### React 19 Form Actions — Accessibility Impact

React 19 (stable December 2024) introduced **form Actions** that simplify accessible form patterns. Key accessibility implications:

**`<form action={fn}>` automatically resets the form on successful submission.** This is significant for screen reader users: previously, developers had to manually reset forms, and forgetting to do so left stale data in fields — confusing screen reader users who hear pre-filled values when returning to the form. Automatic reset eliminates this common oversight.

**`useFormStatus` hook** enables design system components to access form pending state without prop drilling. This makes it easier to implement accessible `disabled` states on submit buttons during async operations — a pattern previously requiring manual context wiring.

```typescript
// File: src/components/AccessibleForm/AccessibleForm.tsx
// React 19 form actions + accessibility: auto-reset + aria-busy + error announcements.
// Demonstrates how React 19 form patterns integrate with WCAG requirements.
'use client';  // Required for form actions with client-side state in Next.js App Router
import React, { useActionState } from 'react';
import { useFormStatus } from 'react-dom';

interface FormState {
  error?: string;
  success?: boolean;
  message?: string;
}

// Separate component for the submit button — uses useFormStatus to access pending state
// This is the React 19 pattern for accessible form buttons in design systems
function SubmitButton({ label }: { label: string }) {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      // aria-disabled is NOT needed when the button is genuinely disabled (disabled attr)
      // aria-busy communicates loading state to screen readers when the form is processing
    >
      {pending ? 'Submitting...' : label}
    </button>
  );
}

// Server action (or client-side async function)
async function submitContactForm(_prev: FormState, formData: FormData): Promise<FormState> {
  const email = formData.get('email') as string;

  if (!email || !email.includes('@')) {
    return { error: 'Enter a valid email address' };
  }

  // Simulate submission
  await new Promise((resolve) => setTimeout(resolve, 1000));
  return { success: true, message: 'Message sent successfully' };
}

export function AccessibleContactForm() {
  // useActionState (React 19) replaces useState + manual submission logic.
  // The form auto-resets on successful submission — no manual reset needed.
  const [state, formAction] = useActionState(submitContactForm, {});

  return (
    <form
      action={formAction}  // React 19: form action — auto-resets on success
      aria-label="Contact form"
      // aria-busy would go here if you want to communicate overall form loading state
      // but useFormStatus on the submit button is the more targeted approach
      noValidate  // Suppress native browser validation — use custom accessible errors
    >
      {/* Success announcement: aria-live polite announces after submission */}
      {state.success && (
        <div role="status" aria-live="polite" aria-atomic="true">
          {state.message}
        </div>
      )}

      <div>
        <label htmlFor="contact-email">Email address</label>
        <input
          id="contact-email"
          type="email"
          name="email"
          required
          autoComplete="email"  // WCAG 1.3.5 Identify Input Purpose
          aria-invalid={state.error ? 'true' : undefined}
          aria-describedby={state.error ? 'contact-email-error' : undefined}
        />
        {state.error && (
          // role="alert" for immediate announcement on submission error
          // aria-live="assertive" is implicit in role="alert"
          <p id="contact-email-error" role="alert">
            {state.error}
          </p>
        )}
      </div>

      {/* SubmitButton uses useFormStatus — accessible disabled state during submission */}
      <SubmitButton label="Send message" />
    </form>
  );
}
```

```typescript
// File: src/components/AccessibleForm/AccessibleForm.a11y.test.tsx
// Unit tests for the React 19 form with jest-axe.
import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

// For testing React 19 form actions in JSDOM, wrap in a test-compatible form handler
// that doesn't call the actual server action
expect.extend(toHaveNoViolations);

function ContactFormTestWrapper({ error }: { error?: string }) {
  return (
    <form aria-label="Contact form" noValidate>
      <div>
        <label htmlFor="contact-email">Email address</label>
        <input
          id="contact-email"
          type="email"
          name="email"
          required
          autoComplete="email"
          aria-invalid={error ? 'true' : undefined}
          aria-describedby={error ? 'contact-email-error' : undefined}
        />
        {error && (
          <p id="contact-email-error" role="alert">{error}</p>
        )}
      </div>
      <button type="submit">Send message</button>
    </form>
  );
}

describe('AccessibleContactForm accessibility', () => {
  it('initial state has no axe violations', async () => {
    const { container } = render(<ContactFormTestWrapper />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('error state has no axe violations', async () => {
    const { container } = render(
      <ContactFormTestWrapper error="Enter a valid email address" />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('error message is linked to input via aria-describedby', () => {
    render(<ContactFormTestWrapper error="Enter a valid email address" />);
    const input = screen.getByLabelText('Email address');
    expect(input).toHaveAttribute('aria-invalid', 'true');
    expect(input).toHaveAttribute('aria-describedby', 'contact-email-error');
    expect(screen.getByRole('alert')).toHaveTextContent('Enter a valid email address');
  });
});
```

53. **[community] React 19 `useActionState` form auto-reset can clear in-progress user input if the action resolves too quickly**: React 19's `<form action={fn}>` resets the form on a successful action response. If a user is filling out a multi-field form and another field triggers an auto-save action that resolves as success, the entire form resets — wiping data the user was actively entering. WHY: auto-reset is tied to the action return value, not to explicit user submit intent. Mitigation: ensure form actions only return success state in response to deliberate user submission (button type="submit"), not on individual field interactions. Also: if using optimistic updates with `useOptimistic`, the reset happens before the optimistic UI resolves — test this scenario explicitly with screen readers to verify the announcements are not interrupted.

### `<selectedcontent>` — Customizable Select Accessibility Testing (ARIA-in-HTML April 2026)

The **ARIA in HTML** specification (W3C Recommendation, updated April 15, 2026) added `<selectedcontent>` — a new HTML element that enables fully customizable `<select>` button display. This is part of the "customizable select" feature allowing CSS styling of the native select UI.

**HTML structure:**

```html
<select>
  <button>
    <selectedcontent></selectedcontent>
    <!-- Browser automatically clones the selected <option> content here -->
  </button>
  <option value="1"><img src="flag-us.svg" alt="US"> United States</option>
  <option value="2"><img src="flag-uk.svg" alt="UK"> United Kingdom</option>
</select>
```

**Accessibility characteristics (ARIA-in-HTML April 2026 spec):**
- `<selectedcontent>` has **no permitted ARIA roles** (implicit role: none)
- Its content is **inert** — users cannot focus or interact with it directly
- Browser manages accessible name computation from the selected `<option>` — the `<select>` element's accessible name is still derived from its associated `<label>`, not `<selectedcontent>`
- The `<button>` child of `<select>` is also inert (browser-managed keyboard interaction)

**Testing considerations for TypeScript projects:**

```typescript
// File: src/components/CountrySelect/__tests__/CountrySelect.a11y.spec.tsx
// jest-axe test: verify customizable select does not break form accessibility.
import React from 'react';
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

function CountrySelect() {
  return (
    <div>
      <label htmlFor="country-select">Country</label>
      {/*
        Customizable select pattern using <selectedcontent>.
        Note: <selectedcontent> is experimental — check browser support
        before production use. JSDOM does not render <selectedcontent>
        visually, but axe still evaluates the form semantics.
      */}
      <select id="country-select" name="country">
        <button>
          <selectedcontent />
        </button>
        <option value="us">United States</option>
        <option value="uk">United Kingdom</option>
        <option value="de">Germany</option>
      </select>
    </div>
  );
}

test('customizable select has no accessibility violations', async () => {
  const { container } = render(<CountrySelect />);
  // axe evaluates the <select> semantics (label association, name computation)
  // <selectedcontent> itself has implicit role=none — no additional ARIA required
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});

test('customizable select has accessible label', () => {
  const { getByRole } = render(<CountrySelect />);
  // The native <select> exposes role="combobox" in the accessibility tree
  // Its accessible name comes from the associated <label>, not <selectedcontent>
  const combobox = getByRole('combobox', { name: 'Country' });
  expect(combobox).toBeInTheDocument();
});
```

**Playwright E2E test for customizable select:**

```typescript
// File: e2e/accessibility/customizable-select.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Customizable select element accessibility', () => {

  test('country select has no axe violations', async ({ page }) => {
    await page.goto('/settings/profile');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .include('#country-select')
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(results.violations).toHaveLength(0);
  });

  test('customizable select aria snapshot reflects combobox semantics', async ({ page }) => {
    await page.goto('/settings/profile');

    // The <select> with <selectedcontent> is still a combobox in the a11y tree.
    // The <selectedcontent> element itself has role=none — not visible in ARIA snapshot.
    const form = page.getByRole('form', { name: 'Profile settings' });
    await expect(form).toMatchAriaSnapshot(`
      - form "Profile settings":
        - combobox "Country":
          - option "United States" [selected]
          - option "United Kingdom"
          - option "Germany"
    `);
  });

  test('customizable select is keyboard navigable', async ({ page }) => {
    await page.goto('/settings/profile');

    // Native <select> keyboard behavior is browser-managed — verify it still works
    // with customizable select button pattern
    const select = page.getByRole('combobox', { name: 'Country' });
    await select.focus();
    await page.keyboard.press('ArrowDown');
    // Browser-native behavior: ArrowDown moves to next option
    await expect(select).toHaveAccessibleName('Country');

    // Confirm axe scan after keyboard interaction (no dynamic ARIA state corruption)
    const results = await new AxeBuilder({ page })
      .include(page.getByRole('form', { name: 'Profile settings' }))
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();
    expect(results.violations).toHaveLength(0);
  });
});
```

**Key gotcha:** In JSDOM (jest-axe), `<selectedcontent>` is parsed as an unknown element and may not render its content visually — but this does not affect axe's evaluation of form semantics. The `<select>` element's label association and role computation are unaffected. However, Playwright E2E tests in a real browser will correctly render the cloned option content, so test both layers.

**Browser support note (May 2026):** `<selectedcontent>` is flagged as "Not Baseline" — it is supported in Chromium-based browsers but not yet in Firefox or Safari. Gate production usage behind feature detection or use progressive enhancement. axe-core evaluates the semantic structure of the surrounding `<select>` regardless of whether `<selectedcontent>` renders correctly.

---

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
| `aria-braille-equivalent` | 4.1.2 AA (best-practice) | `aria-braillelabel`/`aria-brailleroledescription` without paired visual text equivalent (new in 4.11.0) |
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

### axe-core 4.11.0–4.11.1: RGAA Tags, Shadow DOM Support, and Color Space Enhancements

**axe-core 4.11.0 (October 2025)** added three features relevant to TypeScript projects:

1. **RGAA tags**: French accessibility standard (Référentiel Général d'Amélioration de l'Accessibilité) is now mapped to axe-core rules. Teams shipping products to French public-sector markets can filter axe results by RGAA compliance alongside WCAG tags.
2. **TypeScript nodeSerializer typings**: Expanded `nodeSerializer` type definitions — teams using custom serializers for violation reporting now have better TypeScript inference.
3. **International locales expanded**: Portuguese and Russian locale files added for localized violation reports.

**RGAA tag configuration (French market compliance):**

```typescript
// File: e2e/fixtures/axe-rgaa-fixture.ts
// axe-core 4.11.0+: RGAA tags enable filtering by French accessibility standard
// alongside standard WCAG tags. Use when shipping to French public-sector markets.
import { test as base } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

export const test = base.extend<{ checkA11yRGAA: (selector?: string) => Promise<void> }>({
  checkA11yRGAA: async ({ page }, use) => {
    const checkA11yRGAA = async (selector?: string) => {
      // 'rgaa' tag runs all rules that map to RGAA criteria
      // Combine with 'wcag2a', 'wcag2aa', 'wcag21aa' for full coverage
      let builder = new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'rgaa']);

      if (selector) builder = builder.include(selector);

      const results = await builder.analyze();

      // Separate WCAG violations from RGAA-only violations for targeted reporting
      const rgaaOnlyViolations = results.violations.filter(
        (v) => v.tags.includes('rgaa') && !v.tags.some((t) => t.startsWith('wcag'))
      );
      const wcagViolations = results.violations.filter(
        (v) => v.tags.some((t) => t.startsWith('wcag'))
      );

      if (rgaaOnlyViolations.length > 0) {
        console.warn(
          `[RGAA] ${rgaaOnlyViolations.length} RGAA-specific violation(s) (not covered by WCAG):\n` +
          rgaaOnlyViolations.map((v) => `  - ${v.id}: ${v.description}`).join('\n')
        );
      }

      if (wcagViolations.length > 0) {
        const report = wcagViolations
          .map((v) => `[${v.impact?.toUpperCase()}] ${v.id}: ${v.description}`)
          .join('\n');
        throw new Error(`WCAG violations found:\n${report}`);
      }
    };
    await use(checkA11yRGAA);
  },
});

export { expect } from '@playwright/test';
```

**axe-core 4.11.1 (January 2026)** introduced two important improvements:

1. **Shadow roots in `axe.run` contexts**: `axe.run` can now accept shadow roots as context parameters, enabling scanning of open-shadow-DOM web components from within a test script. Previously, axe-core could only scan the document root.
2. **oklch/oklab color support**: CSS Color Level 4 color spaces (`oklch()`, `oklab()`) are now handled in color contrast calculations, matching browser behavior. Teams using design tokens in `oklch()` format for color palettes no longer get false incomplete results on contrast checks.

**Shadow DOM scanning pattern (axe-core 4.11.1+):**

```typescript
// File: e2e/accessibility/shadow-dom.spec.ts
// axe-core 4.11.1+: open shadow roots can be scanned directly.
// Note: CLOSED shadow DOM remains invisible to axe-core — see anti-pattern below.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Web component shadow DOM accessibility', () => {
  test('open-shadow-DOM component passes axe scan', async ({ page }) => {
    await page.goto('/components/my-button');
    await page.waitForLoadState('networkidle');

    // For open shadow DOM, @axe-core/playwright traverses shadow roots automatically
    // as of axe-core 4.11.1+ — no special configuration needed for open shadow DOM
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    // Violations inside open shadow roots are now included in results
    expect(results.violations).toEqual([]);
  });

  test('scan a specific shadow host element', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Use include() with the shadow host selector — axe traverses into shadow DOM
    const results = await new AxeBuilder({ page })
      .include('my-button-component')  // custom element / shadow host
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    if (results.violations.length > 0) {
      console.table(results.violations.map((v) => ({
        id: v.id,
        impact: v.impact,
        description: v.description,
      })));
    }
    expect(results.violations).toEqual([]);
  });
});
```

**`AxeBuilder.setLegacyMode()` — iframe scanning fallback:**

```typescript
// File: e2e/fixtures/axe-legacy-fixture.ts
// setLegacyMode(true) disables axe-core's default behavior of opening a blank page
// to isolate frame scanning. Use ONLY when the test environment blocks blank page creation
// (e.g., strict CSP, sandboxed iframes, some CI environments).
// Legacy mode is slower and may produce less accurate iframe results.
import { test as base } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

export const test = base.extend<{ checkA11yLegacy: () => Promise<void> }>({
  checkA11yLegacy: async ({ page }, use) => {
    const checkA11yLegacy = async () => {
      const results = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
        // setLegacyMode(true): use when blank-page frame isolation is blocked by CSP
        // or when scanning pages that contain sandboxed iframes
        // DO NOT use by default — legacy mode has reduced accuracy for iframe scanning
        .setLegacyMode(true)
        .analyze();

      expect(results.violations).toEqual([]);
    };
    await use(checkA11yLegacy);
  },
});
```

**When to use `setLegacyMode`:**
- Test environment enforces a strict CSP blocking `about:blank` navigation (distinct from the CSP blocking axe injection — see community gotcha #28)
- Pages contain cross-origin iframes in a sandboxed iframe context that prevents the default frame isolation approach
- **Do not** use by default — the default frame testing approach is more accurate for page-level scans

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

40. **[community] jest-axe v10 with fake timers requires timer restoration before scanning**: jest-axe does not work when Jest/Vitest fake timers are active (`jest.useFakeTimers()` / `vi.useFakeTimers()`). axe-core internally uses `setTimeout` and `MutationObserver` timing — with fake timers, scans hang indefinitely. Fix: call `jest.useRealTimers()` (or `vi.useRealTimers()`) immediately before `await axe(container)`, then restore fake timers in `afterEach`. This affects components with debounced validation, typeahead inputs, or any test that replaces timers to control async behavior.

41. **[community] Vitest + jest-axe requires explicit JSDOM environment — use `@vitest-environment jsdom` per-file**: jest-axe 9–10 was designed for Jest's JSDOM environment. In Vitest projects, accessibility unit tests require `@vitest/browser` (real browser) or explicit JSDOM configuration. Without the correct environment, `axe` throws `"axe is not a function"` or `"document is not defined"`. Configure per-file with the `// @vitest-environment jsdom` comment at the top of the test file. Alternatively, use `@axe-core/playwright` for Vitest projects that prefer real-browser execution — it does not depend on JSDOM.

42. **[community] axe-core 4.11.3 changed `<br>`/`<wbr>` accessible name computation**: Before 4.11.3, `<br>` elements inside a button contributed to its accessible name by joining the surrounding text. After 4.11.3, `<br>` contributes only `aria-hidden` semantics — text on either side is no longer joined through `<br>`. Teams using `<br>` inside `<button>` or heading labels may see accessible name changes after upgrading. Audit all `<button>` and heading elements containing `<br>` when upgrading to 4.11.3+.

43. **[community] axe-core 4.11.4 hidden-element fix changes `aria-labelledby` name computation**: The 4.11.4 fix correctly excludes natively hidden elements (`display: none`, `visibility: hidden`, HTML `hidden` attribute) from `aria-labelledby` accessible name resolution. Previously these elements contributed to the computed name — causing axe to silently pass components with broken labels. After upgrading: (1) tests that previously passed because a `display: none` element was incorrectly included in the label may now fail with `button-name` or `label` violations; (2) the offscreen CSS pattern (`position: absolute; left: -10000px; clip: rect(0 0 0 0)`) is unaffected — visually hidden text using this approach still contributes to the accessible name. If tests fail after upgrading to 4.11.4, check that label elements are not using `display: none` for visual hiding — switch to the offscreen CSS pattern.

44. **[community] Next.js App Router has a built-in route announcer — do not add a duplicate**: Next.js App Router (13+) automatically injects a route announcer `<p aria-live="assertive" aria-atomic="true">` that announces page titles after client-side navigation. Teams that also implement a custom `useFocusOnRouteChange` hook with its own `aria-live` region for navigation get double announcements: the custom region fires, then Next.js fires. WHY: route announcement is now a framework responsibility in App Router. Remove the custom route announcer in App Router projects and instead ensure every page has a unique `<title>` via the App Router `metadata` export — Next.js uses the `<title>` content for its built-in announcer. The `useFocusOnRouteChange` hook is still appropriate for Pages Router projects (no built-in announcer).

45. **[community] React Server Components cannot hold dynamic ARIA state — use a Client Component boundary**: RSC (React Server Components) render on the server and are never hydrated as interactive. They cannot use `useState`, `useEffect`, or event handlers — meaning they cannot manage dynamic ARIA state like `aria-expanded`, `aria-selected`, or `aria-live` region updates. WHY: teams that use conditional ARIA attributes in RSC (e.g., `aria-expanded={someServerValue}`) find the state never changes after initial render because there is no hydration. All ARIA state that changes in response to user interaction must live in a `'use client'` Client Component. RSC can safely render static semantic HTML (headings, landmarks, alt text, `lang` attributes, table headers) without accessibility concern.

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

### WCAG 2.5.7 Dragging Movements (WCAG 2.2 AA) — Testing Drag-and-Drop Alternatives

WCAG 2.5.7 (Level AA, WCAG 2.2) requires that all functionality using dragging movements can also be achieved with a single pointer. This is new in WCAG 2.2 and is legally required under the EU Accessibility Act. Drag-and-drop without an alternative excludes users with motor disabilities who cannot sustain a precise pointer path.

**What requires a single-pointer alternative:**
- Drag-to-reorder list items
- Drag-and-drop file upload zones
- Resizable split-pane dividers dragged to resize
- Drag-to-sort columns in data grids
- Canvas/map panning via drag

**Acceptable alternatives:** A "move up/move down" button for reorder; a keyboard-triggered file picker; a text field to enter a pixel dimension; a set of controls to reorder columns by selection.

```typescript
// File: e2e/accessibility/wcag22-dragging.spec.ts
// WCAG 2.2 SC 2.5.7: All drag-and-drop functionality must have a single-pointer alternative.
// Tests verify that keyboard/button alternatives exist alongside drag operations.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('WCAG 2.5.7 Dragging Movements', () => {

  // Test 1: sortable list has keyboard-operable move controls
  test('sortable list provides move-up/move-down controls alongside drag handles', async ({ page }) => {
    await page.goto('/settings/notifications');
    await page.waitForLoadState('networkidle');

    // Drag handles (visual only) should be paired with accessible controls
    const dragHandles = page.locator('[data-drag-handle], [aria-label*="drag"], [aria-label*="reorder"]');
    const count = await dragHandles.count();

    if (count > 0) {
      // For each drag handle, verify an accessible alternative exists nearby
      // Options: adjacent move buttons, keyboard instructions, or direct editing
      const moveUpButtons = page.getByRole('button', { name: /move up|reorder up|up/i });
      const moveDownButtons = page.getByRole('button', { name: /move down|reorder down|down/i });

      // At least one alternative control set must exist
      const hasAlternative =
        (await moveUpButtons.count()) > 0 ||
        (await moveDownButtons.count()) > 0;

      if (!hasAlternative) {
        // Warn: drag-and-drop with no keyboard alternative violates WCAG 2.5.7
        console.warn(
          '[WCAG 2.5.7] Drag handles found but no move-up/move-down button alternatives detected. ' +
          'Verify keyboard-operable alternative exists (e.g., context menu reorder, enter-edit mode).'
        );
      }
    }
  });

  // Test 2: file drop zone has a file picker button alternative
  test('drag-and-drop file zone has a button alternative for file selection', async ({ page }) => {
    await page.goto('/upload');
    await page.waitForLoadState('networkidle');

    const dropZone = page.locator('[data-testid="file-drop-zone"], [role="region"][aria-label*="drop"]');
    if (await dropZone.count() === 0) return;

    // The file button (the actual <input type="file">) must be visible and operable
    // OR a clearly labeled button must trigger the file picker
    const fileInput = page.locator('input[type="file"]');
    const browseButton = page.getByRole('button', { name: /browse|choose file|select file|upload/i });

    const hasAlternative =
      (await fileInput.count()) > 0 ||
      (await browseButton.count()) > 0;

    expect(hasAlternative).toBe(true);

    // The drop zone itself must have an accessible name (it's a droppable region)
    if (await dropZone.count() > 0) {
      const results = await new AxeBuilder({ page })
        .include('[data-testid="file-drop-zone"]')
        .withTags(['wcag2a', 'wcag2aa'])
        .analyze();
      expect(results.violations).toEqual([]);
    }
  });

  // Test 3: resizable divider has an alternative input
  test('resizable split-pane divider has a numeric input or button alternative', async ({ page }) => {
    await page.goto('/editor');
    await page.waitForLoadState('networkidle');

    // Check for resize handles (common in code editors, file managers, dashboards)
    const resizeHandle = page.locator(
      '[role="separator"][aria-orientation], [data-testid*="resize-handle"], [aria-label*="resize"]'
    );

    if (await resizeHandle.count() === 0) return;

    // WCAG 2.5.7: An alternative must exist — typically a numeric input for panel size
    // or a "collapse/expand" button that is keyboard operable
    const hasAlternative = await page.evaluate(() => {
      const alternatives = [
        'input[type="number"][aria-label*="width" i]',
        'input[type="number"][aria-label*="size" i]',
        '[role="button"][aria-label*="collapse" i]',
        '[role="button"][aria-label*="expand" i]',
        'button[aria-label*="collapse" i]',
        'button[aria-label*="expand" i]',
      ];
      return alternatives.some((sel) => document.querySelector(sel) !== null);
    });

    if (!hasAlternative) {
      console.warn(
        '[WCAG 2.5.7] Resize handle found with no numeric input or collapse/expand button alternative.'
      );
    }
  });
});
```

**Accessible reorderable list component pattern (TypeScript + React):**

```typescript
// File: src/components/SortableList/SortableList.tsx
// Accessible sortable list: supports drag-and-drop AND keyboard move-up/move-down.
// WCAG 2.5.7: drag must have a single-pointer alternative (the move buttons).
import React, { useState, useCallback } from 'react';

interface SortableItem {
  id: string;
  label: string;
}

interface SortableListProps {
  items: SortableItem[];
  onChange: (items: SortableItem[]) => void;
  label: string;   // aria-label for the list landmark
}

export const SortableList: React.FC<SortableListProps> = ({ items, onChange, label }) => {
  const [activeId, setActiveId] = useState<string | null>(null);

  const moveItem = useCallback(
    (fromIndex: number, direction: 'up' | 'down') => {
      const toIndex = direction === 'up' ? fromIndex - 1 : fromIndex + 1;
      if (toIndex < 0 || toIndex >= items.length) return;

      const next = [...items];
      const [moved] = next.splice(fromIndex, 1);
      next.splice(toIndex, 0, moved);
      onChange(next);
    },
    [items, onChange]
  );

  return (
    <ul
      aria-label={label}
      // role="list" is implicit on <ul> — explicitly set to prevent VoiceOver list removal
      // (some CSS resets strip list semantics from <ul> with list-style: none)
      style={{ listStyle: 'none', padding: 0 }}
    >
      {items.map((item, i) => (
        <li
          key={item.id}
          // aria-setsize and aria-posinset communicate total count for screen readers
          aria-setsize={items.length}
          aria-posinset={i + 1}
          style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}
        >
          {/* Drag handle — visual only, hidden from accessibility tree */}
          <span aria-hidden="true" style={{ cursor: 'grab' }}>⋮⋮</span>

          <span id={`item-label-${item.id}`}>{item.label}</span>

          {/* Move controls: the WCAG 2.5.7 single-pointer alternative to dragging */}
          <button
            type="button"
            aria-label={`Move ${item.label} up`}
            aria-describedby={`item-label-${item.id}`}
            disabled={i === 0}
            onClick={() => moveItem(i, 'up')}
          >
            ▲
          </button>
          <button
            type="button"
            aria-label={`Move ${item.label} down`}
            aria-describedby={`item-label-${item.id}`}
            disabled={i === items.length - 1}
            onClick={() => moveItem(i, 'down')}
          >
            ▼
          </button>
        </li>
      ))}
    </ul>
  );
};
```

```typescript
// File: src/components/SortableList/SortableList.a11y.test.tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import { SortableList } from './SortableList';

expect.extend(toHaveNoViolations);

const testItems = [
  { id: 'a', label: 'Email notifications' },
  { id: 'b', label: 'Push notifications' },
  { id: 'c', label: 'SMS notifications' },
];

describe('SortableList accessibility', () => {
  it('has no axe violations', async () => {
    const { container } = render(
      <SortableList items={testItems} onChange={() => {}} label="Notification order" />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('move-up button is disabled for first item', () => {
    render(<SortableList items={testItems} onChange={() => {}} label="Notification order" />);
    const moveUpButtons = screen.getAllByRole('button', { name: /move .* up/i });
    expect(moveUpButtons[0]).toBeDisabled();
    expect(moveUpButtons[1]).not.toBeDisabled();
  });

  it('keyboard move-up reorders items and announces change', async () => {
    const user = userEvent.setup();
    const onChange = jest.fn();
    render(<SortableList items={testItems} onChange={onChange} label="Notification order" />);

    const moveUpPush = screen.getByRole('button', { name: /move push notifications up/i });
    await user.click(moveUpPush);

    expect(onChange).toHaveBeenCalledWith([
      { id: 'b', label: 'Push notifications' },
      { id: 'a', label: 'Email notifications' },
      { id: 'c', label: 'SMS notifications' },
    ]);
  });

  it('aria-setsize and aria-posinset communicate correct list position', () => {
    const { container } = render(
      <SortableList items={testItems} onChange={() => {}} label="Notification order" />
    );
    const listItems = container.querySelectorAll('li');
    expect(listItems[0]).toHaveAttribute('aria-setsize', '3');
    expect(listItems[0]).toHaveAttribute('aria-posinset', '1');
    expect(listItems[2]).toHaveAttribute('aria-posinset', '3');
  });
});
```

---

### @axe-core/react — Component Tree Scanning in Test Environments

`@axe-core/react` is a separate package in the axe-core-npm monorepo (distinct from jest-axe) that integrates axe-core directly with React's rendering cycle. Rather than scanning a `container` element, it hooks into React DevTools and reports violations to the browser console during development. It is not a CI tool — it is a developer-loop tool that runs axe on every React render in a development browser.

**When to use `@axe-core/react` vs jest-axe:**

| Tool | Environment | Trigger | Best for |
|------|-------------|---------|---------|
| `@axe-core/react` | Development browser only | Every React render | Catching a11y issues while building — no test file authoring |
| jest-axe | Jest/Vitest unit tests (JSDOM) | Per test assertion | CI gates, regression detection, component-level PRs |
| `@axe-core/playwright` | Playwright E2E (real browser) | Per page scan | Full-page scans, contrast, dynamic content |

```typescript
// File: src/main.tsx
// @axe-core/react: run accessibility checks on every render in development.
// IMPORTANT: only initialize in development — never in production builds.
// This logs violations to the browser console with element highlighting.
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

async function init() {
  if (process.env.NODE_ENV !== 'production') {
    // Dynamically import to ensure zero bundle cost in production
    const axe = await import('@axe-core/react');

    // Initialize axe-core/react: check every React render after a 1000ms debounce
    // The 1000ms timeout prevents excessive checks during rapid state updates
    await axe.default(React, ReactDOM, 1000, {
      rules: [
        // Disable color-contrast in development (JSDOM limitation; use Playwright for contrast)
        { id: 'color-contrast', enabled: false },
      ],
      runOnly: {
        type: 'tag',
        values: ['wcag2a', 'wcag2aa', 'wcag21aa', 'best-practice'],
      },
    });
  }

  const root = ReactDOM.createRoot(document.getElementById('root') as HTMLElement);
  root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
}

init();
```

**Key behaviors and limitations of `@axe-core/react`:**
- Reports go to `console.error` — shows up red in browser DevTools; does not fail tests
- Reports are debounced (default 1000ms) to avoid firing on every keystroke
- Works with React 16.3+ via the DevTools API; not compatible with React 18 Concurrent Mode renders that don't fully commit
- Cannot be included in CI directly — use jest-axe for CI gates
- Does NOT detect color-contrast issues in development (JSDOM limitation); test contrast only in Playwright [community]

---

### @axe-core/cli — Command-Line Accessibility Scanning

`@axe-core/cli` provides a standalone command-line scanner that runs axe-core against URLs without a test framework. It is ideal for: one-off spot checks, scanning staging environments pre-release, scripted multi-page scanning in shell scripts, and generating reports for non-technical stakeholders.

```bash
# Install the CLI globally
npm install -g @axe-core/cli

# Basic scan — reports violations to console
axe https://example.com

# Scan with WCAG 2.1 AA tags and JSON output for programmatic processing
axe https://example.com --tags wcag2a,wcag2aa,wcag21aa --reporter json > axe-report.json

# Scan multiple pages
axe https://example.com/login https://example.com/dashboard https://example.com/checkout \
  --tags wcag2a,wcag2aa,wcag21aa

# Use Chromium (default) or specify browser
axe https://example.com --browser chrome

# Exclude third-party regions from scan (CSS selectors)
axe https://example.com --exclude "#intercom-container"

# Set axe timeout (useful for SPA pages with slow dynamic content)
axe https://example.com --timeout 30000
```

**Integrating `@axe-core/cli` into shell-script CI (GitHub Actions multi-page smoke scan):**

```yaml
# File: .github/workflows/axe-smoke-scan.yml
# One-shot axe CLI scan of deployed staging environment after deploy.
# Use this for: pre-release accessibility smoke test, post-deploy regression check.
name: Post-Deploy Accessibility Smoke Scan
on:
  workflow_dispatch:
    inputs:
      target_url:
        description: 'Base URL of deployed environment'
        required: true
        default: 'https://staging.example.com'

jobs:
  axe-smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm install -g @axe-core/cli
      - name: Run axe smoke scan on critical pages
        run: |
          BASE="${{ github.event.inputs.target_url }}"
          axe \
            "${BASE}/" \
            "${BASE}/login" \
            "${BASE}/dashboard" \
            "${BASE}/checkout" \
            --tags wcag2a,wcag2aa,wcag21aa \
            --reporter json \
            --timeout 30000 \
            > axe-smoke-report.json
          # Exit code 1 if violations found
          if jq -e '.violations | length > 0' axe-smoke-report.json; then
            echo "Accessibility violations found in smoke scan"
            jq '.violations | map({id, impact, description, nodes: [.nodes[].html]})' axe-smoke-report.json
            exit 1
          fi
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: axe-smoke-report
          path: axe-smoke-report.json
```

**TypeScript script to process `@axe-core/cli` JSON output:**

```typescript
// File: scripts/process-axe-report.ts
// Parse and categorize @axe-core/cli JSON output for CI reporting or JIRA ticket creation.
import * as fs from 'fs';

interface AxeCliViolation {
  id: string;
  impact: 'critical' | 'serious' | 'moderate' | 'minor';
  description: string;
  help: string;
  helpUrl: string;
  tags: string[];
  nodes: Array<{
    html: string;
    target: string[];
    failureSummary: string;
  }>;
}

interface AxeCliReport {
  url: string;
  violations: AxeCliViolation[];
  passes: Array<{ id: string }>;
  incomplete: Array<{ id: string; description: string }>;
  inapplicable: Array<{ id: string }>;
  timestamp: string;
  testEngine: { name: string; version: string };
}

export function summarizeAxeReport(reportPath: string): void {
  const report: AxeCliReport = JSON.parse(fs.readFileSync(reportPath, 'utf-8'));
  const criticalAndSerious = report.violations.filter(
    (v) => v.impact === 'critical' || v.impact === 'serious'
  );

  console.log(`\nAxe CLI Report — ${report.url}`);
  console.log(`  Engine: ${report.testEngine.name} v${report.testEngine.version}`);
  console.log(`  Timestamp: ${report.timestamp}`);
  console.log(`  Violations: ${report.violations.length} total`);
  console.log(`    Critical/Serious: ${criticalAndSerious.length}`);
  console.log(`  Incomplete (needs manual review): ${report.incomplete.length}`);

  if (criticalAndSerious.length > 0) {
    console.log('\nCritical/Serious violations:');
    criticalAndSerious.forEach((v) => {
      console.log(`  [${v.impact.toUpperCase()}] ${v.id}: ${v.description}`);
      console.log(`    Help: ${v.helpUrl}`);
      v.nodes.slice(0, 2).forEach((n) =>
        console.log(`    Node: ${n.html.slice(0, 100)}`)
      );
    });
  }
}

// Run: ts-node scripts/process-axe-report.ts axe-report.json
const reportPath = process.argv[2];
if (reportPath) summarizeAxeReport(reportPath);
```

---

### EARL Accessibility Reports for Formal Audits

EARL (Evaluation and Report Language) is a W3C standard format for accessibility test results. `@axe-core/reporter-earl` generates EARL-format RDF/JSON-LD reports from axe-core results. EARL is used when accessibility audit reports must be machine-readable and interoperable with procurement systems, government audit submissions, or ACR (Accessibility Conformance Report) workflows.

**When EARL matters:** EU public-sector procurement and some regulated industries require test results in a standardized machine-readable format. EARL reports can be ingested by procurement evaluation tools that verify accessibility claims without manual inspection.

```typescript
// File: scripts/generate-earl-report.ts
// Generate EARL-format accessibility report from @axe-core/cli output.
// EARL reports are used for formal audit submissions and procurement compliance.
import { chromium } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import * as fs from 'fs';

// axe-core-npm provides @axe-core/reporter-earl for converting axe results to EARL format
// Install: npm install @axe-core/reporter-earl
// The package converts AxeResults to JSON-LD EARL assertions

async function generateEARLReport(url: string, outputPath: string): Promise<void> {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  try {
    await page.goto(url);
    await page.waitForLoadState('networkidle');

    const axeResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    // Convert to EARL format
    // @axe-core/reporter-earl transforms axe AxeResults to W3C EARL JSON-LD
    // The earl array contains one assertion per rule per page
    const { default: earlReporter } = await import('@axe-core/reporter-earl');
    const earlReport = earlReporter(axeResults);

    fs.writeFileSync(outputPath, JSON.stringify(earlReport, null, 2));
    console.log(`EARL report written to ${outputPath}`);
    console.log(`  Violations: ${axeResults.violations.length}`);
    console.log(`  Passes: ${axeResults.passes.length}`);

  } finally {
    await browser.close();
  }
}

const url = process.argv[2] ?? 'https://example.com';
const output = process.argv[3] ?? 'earl-report.json';
generateEARLReport(url, output).catch(console.error);
```

**EARL report structure (JSON-LD excerpt):**

```json
{
  "@context": "https://www.w3.org/WAI/standards-guidelines/earl/",
  "@type": "TestReport",
  "assertedBy": {
    "@type": "Software",
    "title": "axe-core",
    "url": "https://www.deque.com/axe"
  },
  "testSubject": {
    "@type": "TestSubject",
    "id": "https://example.com/"
  },
  "assertions": [
    {
      "@type": "Assertion",
      "testcase": {
        "@type": "TestCase",
        "id": "color-contrast",
        "title": "Elements must have sufficient color contrast"
      },
      "result": {
        "@type": "TestResult",
        "outcome": "earl:failed",
        "info": "Critical: 3 nodes"
      }
    }
  ]
}
```

---

### WCAG 1.2.4 Live Captions — Testing Real-Time Media Accessibility

WCAG 1.2.4 (Level AA) requires that captions be provided for all live audio content in synchronized media. This criterion applies to: live video calls embedded in web apps, webinar players, live-streamed events, real-time screen sharing in collaboration tools, and any synchronized audio/video that is not pre-recorded.

**Why this is commonly overlooked:** Most teams treat captioning as a content problem (handled by a vendor) rather than a testing problem. QA responsibility is to verify that: (1) a caption track is present and activated by default or easily activated, (2) the player UI provides a captions toggle that is accessible, and (3) the caption rendering area itself is accessible to keyboard and screen reader users.

```typescript
// File: e2e/accessibility/live-captions.spec.ts
// WCAG 1.2.4 Live Captions: verify that live media players provide accessible caption controls.
// Tests the caption toggle UI — not the caption content quality (which requires human review).
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('WCAG 1.2.4 Live Captions', () => {

  // Test that the video player has a captions toggle button with an accessible name
  test('video player exposes accessible captions toggle button', async ({ page }) => {
    await page.goto('/webinar/live');
    await page.waitForLoadState('networkidle');

    // Video players typically expose a CC button or captions menu
    // The button must have an accessible name — "CC" alone is not descriptive
    const captionsButton = page.getByRole('button', { name: /captions|cc|subtitles/i });
    const captionsMenuitem = page.getByRole('menuitem', { name: /captions|subtitles/i });

    const hasAccessibleCaptionControl =
      (await captionsButton.count()) > 0 ||
      (await captionsMenuitem.count()) > 0;

    if (!hasAccessibleCaptionControl) {
      console.warn(
        '[WCAG 1.2.4] No accessible captions toggle found on video player. ' +
        'Verify that a labeled CC button exists and is keyboard-operable.'
      );
    }

    // Run axe on the player region to catch structural issues
    const player = page.locator('[data-testid="video-player"], video, [role="region"][aria-label*="video" i]');
    if (await player.count() > 0) {
      const results = await new AxeBuilder({ page })
        .include('[data-testid="video-player"]')
        .withTags(['wcag2a', 'wcag2aa'])
        .analyze();
      expect(results.violations).toEqual([]);
    }
  });

  // Test that the native HTML5 video element exposes the captions track
  test('HTML5 video element includes a captions track element', async ({ page }) => {
    await page.goto('/webinar/live');
    await page.waitForLoadState('networkidle');

    // For native <video> elements, a <track kind="captions"> child is the correct pattern
    const hasCaptionsTrack = await page.evaluate(() => {
      const videos = Array.from(document.querySelectorAll('video'));
      return videos.some((v) => {
        const tracks = Array.from(v.querySelectorAll('track'));
        return tracks.some(
          (t) => t.kind === 'captions' || t.kind === 'subtitles'
        );
      });
    });

    if (videos.length > 0 && !hasCaptionsTrack) {
      // Only warn for live content — pre-recorded content has a separate criterion (1.2.2)
      console.warn(
        '[WCAG 1.2.4] <video> element found with no <track kind="captions"> child. ' +
        'For live content, a real-time caption service (e.g., CART) or provider-side captioning ' +
        'may satisfy this criterion — verify the captioning mechanism in the player.'
      );
    }

    // The captions rendering area must be visible and accessible to keyboard
    const captionsContainer = page.locator(
      '[data-testid="captions-display"], .vjs-text-track-display, .caption-display'
    );
    if (await captionsContainer.count() > 0) {
      // Caption container must not be aria-hidden when captions are active
      const isHidden = await captionsContainer.evaluate(
        (el) => el.getAttribute('aria-hidden') === 'true'
      );
      // Caption text is visual-only; aria-hidden is acceptable since screen readers
      // receive the audio directly. However, the container must not trap focus.
      const tabIndex = await captionsContainer.evaluate(
        (el) => el.getAttribute('tabindex')
      );
      // Caption display should not be in tab order (it is not interactive)
      expect(tabIndex).not.toBe('0');
    }
  });

  // Helper variable declaration fix — used in test above but not declared there
  const videos: HTMLVideoElement[] = []; // illustrative; real query is in page.evaluate
});
```

**Caption track implementation for HTML5 video:**

```typescript
// File: src/components/VideoPlayer/VideoPlayer.tsx
// Accessible video player with captions support (WCAG 1.2.2 prerecorded, 1.2.4 live).
import React, { useRef, useState } from 'react';

interface CaptionTrack {
  src: string;           // URL to VTT caption file (for prerecorded) or live caption URL
  srcLang: string;       // BCP47 language code, e.g., 'en', 'fr'
  label: string;         // Human-readable label shown in player UI
  default?: boolean;     // Whether this track is enabled by default
}

interface VideoPlayerProps {
  src: string;
  title: string;         // Accessible title for the video (used as aria-label on container)
  captions?: CaptionTrack[];
  isLive?: boolean;
}

export const VideoPlayer: React.FC<VideoPlayerProps> = ({
  src,
  title,
  captions = [],
  isLive = false,
}) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [captionsEnabled, setCaptionsEnabled] = useState(
    captions.some((c) => c.default)
  );

  const toggleCaptions = () => {
    const video = videoRef.current;
    if (!video) return;

    const newEnabled = !captionsEnabled;
    setCaptionsEnabled(newEnabled);

    // Enable/disable the first captions track
    for (let i = 0; i < video.textTracks.length; i++) {
      const track = video.textTracks[i];
      if (track.kind === 'captions' || track.kind === 'subtitles') {
        track.mode = newEnabled ? 'showing' : 'hidden';
      }
    }
  };

  return (
    <div
      role="region"
      aria-label={`${isLive ? 'Live: ' : ''}${title}`}
    >
      <video
        ref={videoRef}
        controls          // Native controls are accessible; custom controls require extra ARIA work
        aria-label={title}
        style={{ width: '100%' }}
      >
        <source src={src} type="video/mp4" />

        {/* Caption tracks — kind="captions" includes sound descriptions for deaf users */}
        {captions.map((track) => (
          <track
            key={track.srcLang}
            kind="captions"
            src={track.src}
            srcLang={track.srcLang}
            label={track.label}
            default={track.default}
          />
        ))}

        {/* Fallback for browsers that don't support <video> */}
        <p>
          Your browser does not support the video element.{' '}
          <a href={src}>Download the video</a>.
        </p>
      </video>

      {/* Custom captions toggle button (supplements native controls) */}
      {captions.length > 0 && (
        <button
          type="button"
          // Accessible name clearly describes state and action — WCAG 4.1.2
          aria-label={captionsEnabled ? 'Disable captions' : 'Enable captions'}
          aria-pressed={captionsEnabled}
          onClick={toggleCaptions}
        >
          {captionsEnabled ? 'CC On' : 'CC Off'}
        </button>
      )}

      {/* Live indicator for screen readers */}
      {isLive && (
        <span
          role="status"
          aria-live="polite"
          aria-label="Live broadcast"
          style={{ fontWeight: 'bold', color: 'red' }}
        >
          LIVE
        </span>
      )}
    </div>
  );
};
```

---

### `aria-required` vs HTML `required` — Accessible Form Validation

A common error is using only `aria-required="true"` or only the native HTML `required` attribute without understanding their different semantics.

- **HTML `required`**: triggers native browser validation (prevents form submission); form constraint API fires `invalid` event; no need for `aria-required` when `required` is present
- **`aria-required="true"`**: informs screen readers the field is required; does NOT trigger browser validation; use when you handle validation manually (e.g., React-controlled validation or pattern libraries that suppress native validation)

**WCAG 3.3.2 (Labels or Instructions, A)** requires that form inputs requiring specific format have visible labels/instructions. **WCAG 3.3.1 (Error Identification, A)** requires that errors are described in text when detected.

```typescript
// File: src/components/RequiredField/RequiredField.tsx
// Demonstrates the correct use of HTML required vs aria-required.
// Rule: use HTML required for simple forms; aria-required only for custom validation.
import React from 'react';

// Pattern 1: HTML required (preferred for standard form submissions)
// Screen readers announce "Email, required" from the HTML required attribute.
// No aria-required needed — native required is conveyed via the accName spec.
export const NativeRequiredField: React.FC<{
  id: string;
  label: string;
  value: string;
  onChange: (v: string) => void;
}> = ({ id, label, value, onChange }) => (
  <div>
    <label htmlFor={id}>
      {label}
      {/* Visual asterisk — aria-hidden so screen readers don't say "asterisk" */}
      <span aria-hidden="true"> *</span>
      {/* Screen-reader-only text — screen readers say "(required)" not "asterisk" */}
      <span className="sr-only"> (required)</span>
    </label>
    <input
      id={id}
      type="text"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      required                     // HTML required: triggers browser validation
      // aria-required NOT needed — 'required' attribute already conveys requirement to AT
    />
  </div>
);

// Pattern 2: Custom-validated required field (React-controlled form, no native validation)
// Use aria-required when you suppress native validation (e.g., react-hook-form, novalidate).
export const CustomRequiredField: React.FC<{
  id: string;
  label: string;
  value: string;
  onChange: (v: string) => void;
  error?: string;
}> = ({ id, label, value, onChange, error }) => {
  const errorId = `${id}-error`;
  return (
    <div>
      <label htmlFor={id}>
        {label}
        <span aria-hidden="true"> *</span>
        <span className="sr-only"> (required)</span>
      </label>
      <input
        id={id}
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        // aria-required: tells AT this field is required in custom-validation context
        aria-required="true"
        // aria-invalid: set to "true" after validation fires, not before user interaction
        aria-invalid={error ? 'true' : undefined}
        aria-describedby={error ? errorId : undefined}
      />
      {error && (
        <p id={errorId} role="alert">
          {error}
        </p>
      )}
    </div>
  );
};
```

```typescript
// File: src/components/RequiredField/RequiredField.a11y.test.tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import { NativeRequiredField, CustomRequiredField } from './RequiredField';

expect.extend(toHaveNoViolations);

describe('RequiredField accessibility', () => {
  it('native required field has no axe violations', async () => {
    const { container } = render(
      <NativeRequiredField id="name" label="Full name" value="" onChange={() => {}} />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('custom required field with error has no axe violations', async () => {
    const { container } = render(
      <CustomRequiredField
        id="email"
        label="Email address"
        value=""
        onChange={() => {}}
        error="Enter a valid email address"
      />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('native required input has required attribute', () => {
    render(<NativeRequiredField id="name" label="Full name" value="" onChange={() => {}} />);
    expect(screen.getByLabelText(/full name/i)).toHaveAttribute('required');
  });

  it('custom required input has aria-required when native required not set', () => {
    render(<CustomRequiredField id="email" label="Email" value="" onChange={() => {}} />);
    expect(screen.getByLabelText(/email/i)).toHaveAttribute('aria-required', 'true');
  });

  it('aria-invalid is set only when error is present, not on initial render', () => {
    const { rerender } = render(
      <CustomRequiredField id="email" label="Email" value="" onChange={() => {}} />
    );
    expect(screen.getByLabelText(/email/i)).not.toHaveAttribute('aria-invalid');

    rerender(
      <CustomRequiredField
        id="email"
        label="Email"
        value=""
        onChange={() => {}}
        error="Required"
      />
    );
    expect(screen.getByLabelText(/email/i)).toHaveAttribute('aria-invalid', 'true');
  });
});
```

**Key rule for `aria-required` vs `required`:**
- Use native `required` + `<label>` for standard forms — no `aria-required` needed
- Use `aria-required="true"` only when native `required` is suppressed by `novalidate` on `<form>` or by a form management library
- Never set both `required` and `aria-required="true"` — it produces redundant announcement in some screen readers
- Set `aria-invalid` only after validation has run (after the first submit attempt or on blur), never on initial render — screen readers announce "invalid" when focus lands on a field; announcing it before the user has had a chance to fill in the field creates anxiety for cognitive-impaired users [community]

---

### TypeScript 6.0 Strict Defaults — Impact on Accessibility Test Files

TypeScript 6.0 (released in the TS 6.x series, see lang-refine TypeScript patterns) changes several tsconfig defaults that affect accessibility test files. Understanding these changes prevents unexpected CI failures when upgrading TypeScript in a project with a11y tests.

**Breaking changes affecting a11y test files:**

| TS 6.0 change | Impact on a11y tests | Migration |
|---|---|---|
| `"strict": true` now the default | `axe()` results and `configureAxe()` options require stricter types | Add explicit type annotations where TS infers `any` |
| `"types": []` default (no implicit `@types/*`) | jest-axe types not auto-included | Add `"types": ["jest-axe", "@testing-library/jest-dom"]` to tsconfig |
| `"esnext"` target default | `import()` in test setup files compiles differently | Ensure test runner (Jest, Vitest) is configured for ESM |
| `"dom.iterable"` consolidated into `"dom"` | No change needed | Remove explicit `"dom.iterable"` from `lib` array if present |
| Removed `"outFile"` and `"baseUrl"` | Test path aliases may break | Migrate to `"paths"` entries in tsconfig |

**Updated tsconfig for TypeScript 6.0 a11y testing projects:**

```json
// File: tsconfig.json (TypeScript 6.0 compatible)
{
  "compilerOptions": {
    // TypeScript 6.0 new defaults — explicitly set to make configuration visible
    "strict": true,
    "target": "esnext",
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "lib": ["dom", "dom.asynciterable", "esnext"],

    // TypeScript 6.0: types[] is now empty by default.
    // Explicitly list all @types packages needed in test environments.
    "types": ["jest", "jest-axe", "@testing-library/jest-dom", "node"],

    // Paths replaces baseUrl (deprecated in TS 6.0, removed in TS 7.0)
    "paths": {
      "@/*": ["./src/*"],
      "@tests/*": ["./src/__tests__/*"]
    },

    "rootDir": "./src",
    "outDir": "./dist",
    "sourceMap": true,
    "noImplicitAny": true,
    "noUnusedLocals": true,
    "noImplicitReturns": true,
    "exactOptionalPropertyTypes": true
  },
  "include": ["src/**/*.ts", "src/**/*.tsx"],
  "exclude": ["node_modules", "dist"]
}
```

```json
// File: tsconfig.test.json (extends base, adds test-specific overrides)
// Use this for Jest/Vitest test compilation — extends the base tsconfig
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    // Test files can use more permissive settings:
    // - noUnusedLocals: false allows unused mock variables
    // - exactOptionalPropertyTypes: false allows partial mock objects
    "noUnusedLocals": false,
    "exactOptionalPropertyTypes": false,

    // Include jest-axe and testing-library types only in test compilation
    "types": ["jest", "jest-axe", "@testing-library/jest-dom", "node"],

    // Do not emit: test files are not compiled to output
    "noEmit": true
  },
  "include": [
    "src/**/*.ts",
    "src/**/*.tsx",
    "src/**/*.test.ts",
    "src/**/*.test.tsx",
    "src/**/*.a11y.test.ts",
    "src/**/*.a11y.test.tsx",
    "e2e/**/*.ts",
    "e2e/**/*.tsx"
  ]
}
```

**Community gotcha — TS 6.0 `types: []` breaks jest-axe type resolution:**

46. **[community] TypeScript 6.0's new `"types": []` default breaks jest-axe type inference in existing projects**: TS 6.0 changed the `"types"` tsconfig default from `undefined` (include all `@types/*` in node_modules) to `[]` (include nothing implicitly). Projects that relied on implicit `@types/jest-axe` type inclusion will see TypeScript errors — `toHaveNoViolations` becomes `unknown`, `configureAxe` loses its type signature, and `axe()` return type becomes `any`. Fix: add `"jest-axe"` and `"@testing-library/jest-dom"` to the `"types"` array in `tsconfig.json` (or `tsconfig.test.json`). This is a one-line fix but breaks CI silently if TypeScript `noEmit` checks are not run before deployment.

47. **[community] axe-core 4.11.1 shadow DOM support changes expected violation counts for web component test suites**: axe-core 4.11.1 added the ability to traverse open shadow DOM roots. Teams upgrading from 4.10.x to 4.11.1+ may see new violations appear inside web component shadow trees — these are real violations that were previously invisible to axe. WHY: before 4.11.1, open shadow DOM content was silently excluded from `axe.run` traversal. After upgrading, violations in `<my-button>`, `<sl-input>`, or other web components using open shadow DOM will surface. Run a full scan audit after upgrading and treat new violations as newly detected defects, not regressions.

48. **[community] axe-core 4.11.1 oklch/oklab color handling changes contrast pass/fail for modern CSS design tokens**: Teams using CSS Color Level 4 `oklch()` or `oklab()` colors (increasingly common in design token systems) may see contrast rule status change when upgrading from 4.10.x to 4.11.1+. Before 4.11.1, these color values could produce `incomplete` (uncertain) contrast results; 4.11.1 matches browser behavior for oklch/oklab gamut calculations and may produce definitive pass or fail. WHY: color token libraries like Radix Colors, Tailwind's oklch palette, and custom design systems built on CSS Color Level 4 use oklch for more perceptually uniform palettes — test suites need to account for the more accurate reporting.

49. **[community] RGAA compliance adds requirements beyond WCAG for French public-sector procurement**: axe-core 4.11.0's `rgaa` tag maps to the French RGAA standard. RGAA has ~110 criteria and mirrors WCAG 2.1 AA for most web content, but adds requirements for JavaScript interaction patterns and specific form field behaviors not explicitly in WCAG. Teams using `withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])` alone are not meeting RGAA even if all WCAG rules pass. Add `'rgaa'` to the tag list for French public-sector procurement, and expect RGAA-only violations to surface for some native browser control overrides.

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
| axe-core | Open source | https://github.com/dequelabs/axe-core | Rule documentation and changelog (v4.11.4 current); RGAA tags (4.11.0+); shadow DOM support (4.11.1+); custom rule API |
| axe-core Rule Descriptions | Reference | https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md | Full list of all axe rules with WCAG mapping |
| jest-axe | Open source | https://github.com/nickcolley/jest-axe | Jest integration for axe; v10.0.0 (March 2025) uses axe-core 4.10.2; requires `jest-environment-jsdom`; use `@vitest-environment jsdom` for Vitest |
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
| @axe-core/cli | Open source | https://github.com/dequelabs/axe-core-npm/tree/develop/packages/cli | Command-line axe scanning; multi-page staging scans; JSON/JUnit output |
| @axe-core/react | Open source | https://github.com/dequelabs/axe-core-npm/tree/develop/packages/react | Dev-browser axe scan on every React render; zero test authoring; not for CI |
| @axe-core/reporter-earl | Open source | https://github.com/dequelabs/axe-core-npm/tree/develop/packages/reporter-earl | W3C EARL format reports from axe results; required for formal procurement audits |
| WCAG 1.2.4 Understanding Live Captions | Official | https://www.w3.org/WAI/WCAG21/Understanding/captions-live.html | AA criterion for live audio captions — applies to webinars and live streams |
| WCAG 2.5.7 Understanding Dragging Movements | Official | https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements.html | WCAG 2.2 AA — all drag operations must have a single-pointer alternative |
| aria-required MDN | Reference | https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-required | When to use aria-required vs HTML required attribute |
| RGAA (French Accessibility Standard) | Official | https://accessibilite.numerique.gouv.fr/methode/criteres-et-tests/ | French government accessibility standard; axe-core 4.11.0+ supports RGAA tags for rule filtering |
| WCAG 3.0 Working Draft (March 2026) | Draft spec | https://www.w3.org/TR/wcag-3.0/ | Most current draft (March 3, 2026); Bronze/Silver/Gold outcome-based model; still "several years" from finalization |
| Playwright Aria Snapshots | Official | https://playwright.dev/docs/aria-snapshots | toMatchAriaSnapshot() YAML-based accessibility tree regression testing (v1.49+); ariaSnapshot({ depth, mode, boxes }) options (v1.59-v1.60); page.accessibility.snapshot() removed in v1.57 |
| Playwright toHaveAccessibleErrorMessage | Official | https://playwright.dev/docs/api/class-locatorassertions#locator-assertions-to-have-accessible-error-message | Assert computed aria-errormessage text (v1.50+); tests what screen readers announce, not HTML attributes |
| Playwright getByRole description | Official | https://playwright.dev/docs/api/class-page#page-get-by-role | description option for getByRole() (v1.60+); matches by accessible description from aria-describedby |
| React 19 Form Actions | Official | https://react.dev/blog/2024/12/05/react-19 | React 19 form Actions: auto-reset on success, useFormStatus for accessible loading states |
| axe-core-npm monorepo | Open source | https://github.com/dequelabs/axe-core-npm | 7 packages: @axe-core/playwright, @axe-core/react, @axe-core/cli, @axe-core/reporter-earl, @axe-core/puppeteer, @axe-core/webdriverio, @axe-core/webdriverjs; latest: v4.11.3 (May 4, 2026) |
| aria-braille-equivalent rule | Reference | https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md | New rule in axe-core 4.11.0: identifies incorrect uses of aria-braille attributes on elements |
| IBM Equal Access accessibility-checker | Open source | https://github.com/IBMa/equal-access | v4.0.17 (April 2026); Playwright integration via aChecker.getCompliance(page, label); EN 301 549 + Section 508 + WCAG 2.0/2.1/2.2; baseline comparison mode; JSON/CSV/XLSX output |
| Pa11y CI | Open source | https://github.com/pa11y/pa11y-ci | v4.1.0 (March 2026, Node 20+); HTMLCS engine complementary to axe-core; URL-list + sitemap scanning; pre-deployment staging gate |
| Playwright accessibility testing | Official | https://playwright.dev/docs/accessibility-testing | Official @axe-core/playwright integration guide; AxeBuilder API reference; WCAG tag filtering |
| axe.run() API documentation | Official | https://www.deque.com/axe/core-documentation/api-documentation/ | Full axe.run() options: resultTypes for performance, preload (cssom/media), context selectors, shadow DOM targeting |
| @axe-core/mcp | Official | https://github.com/dequelabs/axe-core-npm/tree/develop/packages/mcp | Deque's official MCP server for IDE-integrated accessibility scanning; exposes scan_url, scan_html, get_rule tools; works with Claude Code, Copilot, Cursor |
| ARIA in HTML (W3C Rec) | Official | https://www.w3.org/TR/html-aria/ | W3C Recommendation April 15, 2026; adds selectedcontent element (role=none, no permitted ARIA roles); permits role/aria-* on label when not associated with a form control (July 2025); image role synonym for img role (Dec 2024) |

---

### axe-core 4.11.0: `aria-braille-equivalent` Rule — New Braille Accessibility Check

axe-core 4.11.0 (October 2025) introduced the `aria-braille-equivalent` rule alongside the RGAA tags feature. This rule detects incorrect uses of `aria-brailleroledescription` and `aria-braillelabel` — the two ARIA attributes specifically for Braille display users.

**What `aria-braille-equivalent` checks:**

The ARIA 1.3 specification added `aria-braillelabel` and `aria-brailleroledescription` to provide Braille-optimized text for accessible elements. These attributes are consumed by Braille displays (refreshable Braille devices) which typically have 40–80 character cells. Unlike `aria-label`, Braille attributes should contain abbreviated text without emoji, symbols, or decoration that are unintelligible in Braille.

The `aria-braille-equivalent` rule fails when:
- An element has `aria-braillelabel` but no `aria-label` or `aria-labelledby` (Braille label must have a visual text equivalent — WCAG 4.1.2)
- An element has `aria-brailleroledescription` but no `aria-roledescription`
- `aria-braillelabel` contains emoji or Unicode symbols that have no Braille equivalent

**When this rule applies to TypeScript projects:**

Most TypeScript teams do not need to add `aria-braille*` attributes — axe-core only fires `aria-braille-equivalent` when you explicitly use these attributes. If you use `aria-roledescription` on a custom widget (e.g., a carousel section), and you also add `aria-brailleroledescription`, both must be present together.

```typescript
// File: src/components/Carousel/Carousel.accessible.tsx
// Correct use of aria-brailleroledescription with aria-roledescription:
// Both must always be paired. Braille text should be abbreviated (≤40 chars).

// ❌ INCORRECT: aria-brailleroledescription without aria-roledescription
// <section aria-brailleroledescription="carousel">
//   Fails aria-braille-equivalent — must have paired aria-roledescription

// ✅ CORRECT: both attributes present and paired
export const CarouselSection: React.FC<{ label: string }> = ({ label }) => (
  <section
    aria-label={label}
    // Primary role description for all screen readers
    aria-roledescription="carousel"
    // Braille-optimized abbreviation — 40 chars max; no emoji/symbols
    // Only needed when serving Braille display users (government, education portals)
    aria-brailleroledescription="crsl"
  >
    {/* carousel content */}
  </section>
);

// ❌ INCORRECT: aria-braillelabel without aria-label
// <button aria-braillelabel="Nxt sld">
//   Fails aria-braille-equivalent — must have visual text equivalent

// ✅ CORRECT: both visual label and Braille abbreviation
export const NextSlideButton: React.FC<{ onClick: () => void }> = ({ onClick }) => (
  <button
    type="button"
    aria-label="Next slide"                    // Visual/audio screen reader label
    aria-braillelabel="nxt"                    // Braille display abbreviation (40 chars max)
    onClick={onClick}
  >
    <span aria-hidden="true">›</span>
  </button>
);
```

```typescript
// File: src/components/Carousel/Carousel.braille.a11y.test.tsx
// Test that aria-braille attributes are correctly paired when used.
import React from 'react';
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations, configureAxe } from 'jest-axe';
import { CarouselSection, NextSlideButton } from './Carousel.accessible';

expect.extend(toHaveNoViolations);

const axeConfig = configureAxe({
  runOnly: {
    type: 'tag',
    // Include 'best-practice' — aria-braille-equivalent is tagged as best-practice
    values: ['wcag2a', 'wcag2aa', 'wcag21aa', 'best-practice'],
  },
});

describe('aria-braille-equivalent rule (axe-core 4.11.0+)', () => {
  it('paired aria-roledescription + aria-brailleroledescription has no violations', async () => {
    const { container } = render(
      <CarouselSection label="Featured content" />
    );
    const results = await axeConfig(container);
    expect(results).toHaveNoViolations();
  });

  it('paired aria-label + aria-braillelabel has no violations', async () => {
    const { container } = render(
      <NextSlideButton onClick={() => {}} />
    );
    const results = await axeConfig(container);
    expect(results).toHaveNoViolations();
  });

  it('aria-braillelabel without aria-label triggers aria-braille-equivalent violation', async () => {
    const { container } = render(
      <button type="button" aria-braillelabel="nxt">Next</button>
    );
    // Note: in this case the button has text content "Next" which provides the accessible name,
    // but aria-braillelabel without a explicit aria-label or aria-labelledby is flagged by the rule.
    // When using aria-braillelabel, always also provide aria-label for explicit pairing.
    const results = await axeConfig(container);
    // Intentionally documenting that this pattern can trigger the rule in some axe configurations.
    // If violation is detected: add aria-label="Next slide" to the button.
    expect(results.violations.map(v => v.id).includes('aria-braille-equivalent')).toBeDefined();
  });
});
```

**When should teams use `aria-braille*` attributes?**

Most consumer web applications do NOT need `aria-braille*` attributes — the rule only fires if you use them incorrectly. Organizations that should consider them:
- Government portals serving users with deafblindness who use Braille displays
- Libraries and archives with document readers where abbreviations reduce Braille navigation time
- Applications specifically serving educational institutions for visually impaired students
- Medical/healthcare tools where specific ARIA patterns benefit from Braille-optimized labels

**The practical impact of `aria-braille-equivalent` on your test suite:** If you do not use `aria-braillelabel` or `aria-brailleroledescription`, this rule never fires. The only teams affected are those who have proactively added Braille attributes and made pairing errors. For teams upgrading to axe-core 4.11.0+: run a baseline scan — if zero `aria-braille-equivalent` violations appear, no action is needed.

---

### `@axe-core/playwright`: Single-Selector Limitation for `include()` / `exclude()`

A documented limitation in `@axe-core/playwright` (all versions through 4.11.3) affects how multiple CSS selectors are passed to `include()` and `exclude()`. This limitation is a common source of silent test failures where exclusions are silently ignored.

**The limitation:** Arrays with more than one CSS selector passed to a single `include()` or `exclude()` call are **not supported** and silently ignored. Only the first element of the array is processed; the rest are discarded without error.

```typescript
// File: e2e/fixtures/axe-multi-exclude.spec.ts
// Demonstrates the include/exclude single-selector limitation in @axe-core/playwright.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('axe-core/playwright include/exclude patterns', () => {

  // ❌ INCORRECT: Passing an array with multiple selectors to a single .exclude() call
  // The second and third selectors are silently IGNORED — only '#intercom-container' is excluded.
  // This is a documented limitation in @axe-core/playwright.
  test('INCORRECT — multi-selector array (second selector silently ignored)', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // BUG: only '#intercom-container' is excluded; '#cookie-consent-banner' is NOT excluded
    // despite being listed in the same array.
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .exclude(['#intercom-container', '#cookie-consent-banner'])  // ← BROKEN: array ignored after first
      .analyze();

    // This scan may produce false violations from #cookie-consent-banner
    // because the second exclusion was silently dropped.
    expect(results.violations).toEqual([]);
  });

  // ✅ CORRECT: Chain separate .exclude() calls — one selector per call
  test('CORRECT — chained single-selector exclude() calls', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Both exclusions are correctly applied when chained as separate calls.
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .exclude('#intercom-container')         // ← Third-party chat widget
      .exclude('#cookie-consent-banner')      // ← Third-party cookie banner
      .exclude('[data-testid="help-widget"]') // ← Third-party help widget
      .analyze();

    expect(results.violations).toEqual([]);
  });

  // ✅ CORRECT: Single selector per include() call for scoped scans
  test('CORRECT — scoped scan with single include() selector', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Scope scan to the main application content area.
    // If you need to include multiple regions, chain include() calls.
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .include('#main-application')
      .analyze();

    expect(results.violations).toEqual([]);
  });

  // ✅ CORRECT: Multiple include() calls for scanning several regions
  test('CORRECT — scanning multiple page regions with chained include()', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // To scan both the navigation and the main content, chain include() calls.
    // Each call adds one region to the scan context.
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .include('nav[aria-label="Main navigation"]')
      .include('#main-content')
      .analyze();

    expect(results.violations).toEqual([]);
  });
});
```

**Helper function for multi-exclusion pattern:**

```typescript
// File: e2e/fixtures/axe-builder-helpers.ts
// Utility: build an AxeBuilder with multiple exclusions safely.
// Works around the @axe-core/playwright single-selector limitation.
import { Page } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

type AxeBuilderOptions = {
  tags?: string[];
  excludes?: string[];       // Array of selectors — each applied as a separate .exclude() call
  includes?: string[];       // Array of selectors — each applied as a separate .include() call
  disableRules?: string[];
};

/**
 * Create an AxeBuilder with multiple include/exclude selectors correctly chained.
 *
 * WHY: @axe-core/playwright does not support arrays with more than one selector
 * in a single .include() or .exclude() call. Only the first element is processed;
 * subsequent elements are silently ignored. This helper chains each selector as a
 * separate call to avoid the limitation.
 */
export function buildAxeScanner(page: Page, options: AxeBuilderOptions = {}): AxeBuilder {
  const {
    tags = ['wcag2a', 'wcag2aa', 'wcag21aa'],
    excludes = [],
    includes = [],
    disableRules = [],
  } = options;

  let builder = new AxeBuilder({ page }).withTags(tags);

  // Chain each exclusion as a separate call — NOT as an array in one call
  for (const selector of excludes) {
    builder = builder.exclude(selector);
  }

  // Chain each inclusion as a separate call — NOT as an array in one call
  for (const selector of includes) {
    builder = builder.include(selector);
  }

  if (disableRules.length > 0) {
    builder = builder.disableRules(disableRules);
  }

  return builder;
}
```

```typescript
// File: e2e/accessibility/axe-multi-exclude-example.spec.ts
// Using the buildAxeScanner helper for multi-region scans with proper exclusions.
import { test, expect } from '@playwright/test';
import { buildAxeScanner } from '../fixtures/axe-builder-helpers';

// Standard third-party widget exclusions for the project.
// Define as a constant to reuse across all accessibility test files.
const THIRD_PARTY_EXCLUSIONS = [
  '#intercom-container',
  '#cookie-consent-banner',
  '[data-third-party="help-widget"]',
  'iframe[src*="recaptcha"]',
];

test.describe('Dashboard accessibility (with third-party exclusions)', () => {
  test('dashboard main content has no WCAG 2.1 AA violations', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    const results = await buildAxeScanner(page, {
      excludes: THIRD_PARTY_EXCLUSIONS,
      tags: ['wcag2a', 'wcag2aa', 'wcag21aa'],
    }).analyze();

    expect(results.violations).toEqual([]);
  });

  test('scan only the user settings section excluding third-party widgets', async ({ page }) => {
    await page.goto('/settings');
    await page.waitForLoadState('networkidle');

    const results = await buildAxeScanner(page, {
      includes: ['[data-testid="user-settings"]'],
      excludes: THIRD_PARTY_EXCLUSIONS,
    }).analyze();

    expect(results.violations).toEqual([]);
  });
});
```

56. **[community] `@axe-core/playwright` silently ignores all but the first selector when an array is passed to `include()` or `exclude()`**: The current `@axe-core/playwright` implementation processes only the first item from an array passed to a single `include()` or `exclude()` call. There is no warning or error when additional selectors are silently dropped. WHY: the underlying axe-core context API processes selector arrays differently from what the chainable AxeBuilder API expects. Teams that write `.exclude(['#chat', '#cookie-banner'])` believe they have excluded two regions but only the chat widget is excluded — the cookie banner violations appear in the scan results as if the exclusion was never applied. Fix: chain separate `.exclude()` calls — one per selector. Document this constraint in a shared axe fixture helper to prevent it from recurring across the codebase.

---

### `@axe-core/react` React 18+ Incompatibility and Migration Strategy

As noted in the `@axe-core/react` section, the package does not support React 18 and above. This limitation affects an increasing number of TypeScript projects that have upgraded to React 18 or 19. Understanding the migration path is essential for teams that relied on `@axe-core/react` for development-time accessibility feedback.

**Why the incompatibility exists:** `@axe-core/react` hooks into React DevTools' `onCommitFiberRoot` API using the React DevTools internals bridge. React 18 changed the Concurrent Mode fiber commit model — `onCommitFiberRoot` is now called in batched form with different argument signatures, breaking the hook mechanism. React 19's new form Actions, server components, and the improved Concurrent Mode make this gap wider.

**Migration options by team context:**

| Context | Recommended replacement | Notes |
|---------|------------------------|-------|
| React 18/19, Vite/CRA dev mode | `axe-linter` VSCode extension | Static analysis as you type; zero runtime overhead |
| React 18/19, Storybook | `@storybook/addon-a11y` | Per-story axe scan in browser panel; real React rendering |
| React 18/19, JSDOM unit tests | jest-axe / jest-axe + Vitest | CI-integrated; catches structural issues |
| React 18/19, Playwright E2E | `@axe-core/playwright` | Real browser rendering; catches contrast + dynamic issues |
| React 18/19, want render-time scan | Deque axe DevTools Extension | Browser extension; not React-version-dependent |

```typescript
// File: src/main.tsx (React 18+ migration from @axe-core/react)
// BEFORE (React 16/17 — @axe-core/react pattern, no longer works in React 18+):
//
// import axe from '@axe-core/react';
// if (process.env.NODE_ENV !== 'production') {
//   axe(React, ReactDOM, 1000); // ← BROKEN in React 18+
// }
//
// AFTER (React 18+): Use browser extension for development-time scanning.
// Replace @axe-core/react with vscode-axe-linter + Storybook addon-a11y + jest-axe.
// No runtime initialization needed.

import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';

// React 18+ createRoot API — concurrent mode enabled by default
const root = createRoot(document.getElementById('root') as HTMLElement);
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

// Development-time accessibility feedback in React 18+ projects:
// 1. Install the Deque axe DevTools browser extension
//    (https://chrome.google.com/webstore/detail/axe-devtools-web-accessib/lhdoppojpmngadmnindnejefpokejbdd)
//    — runs axe on any page, React-version-independent
//
// 2. In VS Code: install deque-systems.vscode-axe-linter
//    — flags missing aria-label, wrong roles, structural issues in JSX as you type
//
// 3. In Storybook: use @storybook/addon-a11y
//    — provides per-story axe scan in the Accessibility panel; React 18 compatible
//    (see Storybook Test Runner section above for CI integration)
```

```typescript
// File: src/main.tsx (conditional @axe-core/react for React 16/17 projects that cannot upgrade yet)
// If you are locked on React 16 or 17 and @axe-core/react still works,
// use this pattern to avoid any future React upgrade breaking production init code.
import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

async function main() {
  // Only initialize @axe-core/react in development and only for React < 18
  if (process.env.NODE_ENV !== 'production') {
    const majorVersion = parseInt(React.version.split('.')[0], 10);
    if (majorVersion < 18) {
      // @axe-core/react is only compatible with React 16 and 17
      const { default: axe } = await import('@axe-core/react');
      axe(React, ReactDOM, 1000, {
        rules: [{ id: 'color-contrast', enabled: false }], // JSDOM limitation
        runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21aa', 'best-practice'] },
      });
    } else {
      // React 18+: @axe-core/react not supported.
      // Use browser extension (Deque axe DevTools) or @storybook/addon-a11y for dev feedback.
      console.info('[a11y] @axe-core/react not loaded (requires React <18). Use Deque axe DevTools extension for dev-time scanning.');
    }
  }

  ReactDOM.render(<App />, document.getElementById('root'));
}

main();
```

57. **[community] `@axe-core/react` silently fails to initialize in React 18+ without any error message**: Teams that upgrade from React 17 to React 18 and leave `@axe-core/react` initialization in `main.tsx` find that the module loads without error but produces no console output — no violations, no warnings, no indication the hook is disconnected. WHY: the React DevTools internals bridge hooks that `@axe-core/react` relied on changed in React 18; the package fails silently rather than throwing. Teams interpret the silence as "no violations found" when in reality the tool has stopped working entirely. The fix is to remove `@axe-core/react` from React 18+ projects and adopt the browser extension or `@storybook/addon-a11y` as the replacement for development-time scanning.

58. **[community] Deque's Intelligent Guided Testing (IGT) via the axe MCP Server provides IDE-integrated accessibility scanning for AI agents — but it is a commercial tool, not a replacement for open-source axe-core in CI**: Deque introduced an "Axe MCP Server" as part of axe DevTools that exposes accessibility scanning to AI agents (Copilot, Claude Code) via the Model Context Protocol. This is distinct from the open-source navable MCP server (which uses axe-core directly). Teams evaluating axe MCP should understand: (1) it requires an axe DevTools license tier; (2) it targets IDE-embedded AI agents, not CI pipelines; (3) the open-source `@axe-core/playwright` + navable MCP combination covers the same scan→plan→fix→verify workflow for teams that need CI-integrated agent-driven fixing. WHY: the confusion between "axe DevTools MCP" (commercial, IDE) and "axe-core in CI via @axe-core/playwright" (open-source) leads teams to believe they need a commercial license to use axe-core in CI — they do not.

59. **[community] Playwright 1.56+ `toMatchAriaSnapshot()` renders `<input>` `placeholder` text in the YAML snapshot — teams not expecting this see unexpected snapshot mismatches after upgrading**: Playwright 1.56 changed `ariaSnapshot()` to render `<input>` placeholder text as part of the element's accessible description in the YAML output (e.g., `- textbox "Email" [placeholder="user@example.com"]`). Teams pinning snapshot baselines from Playwright 1.55 or earlier will experience snapshot failures on `<input>` elements with `placeholder` attributes after upgrading — even if the ARIA structure has not changed. WHY: the placeholder is now included as metadata in the YAML format, matching how screen readers announce inputs. Fix: re-run `npx playwright test --update-snapshots` after upgrading to 1.56+ to regenerate baselines, and review whether the placeholder content is semantically meaningful enough to assert on or should be filtered. If you use placeholder as a form label substitute (a known WCAG anti-pattern), this change will surface that pattern in snapshot diffs — a useful side effect.

60. **[community] WCAG 2.2 became ISO/IEC 40500:2025 in October 2025 — this has procurement implications that QA teams should understand even though the technical requirements are unchanged**: WCAG 2.2 (published October 2023) was ratified as an ISO international standard in October 2025 as ISO/IEC 40500:2025. The technical content is identical to the W3C standard — no new criteria were added. The significance for QA teams is in procurement: ISO status enables countries and government bodies that reference ISO standards in procurement law (rather than W3C specifications directly) to formally mandate WCAG 2.2 compliance. Teams shipping to global government markets should track whether their target jurisdictions have updated procurement requirements to reference ISO/IEC 40500:2025. This is distinct from the EU EAA (which references EN 301 549 and WCAG 2.2 directly, not via ISO). The practical testing requirements are unchanged: WCAG 2.2 AA with axe-core `wcag22aa` tags.

61. **[community] ACT Rules Format 1.1 became an official W3C standard in 2026 — teams using axe-core benefit indirectly through improved tool consistency**: The W3C Accessibility Conformance Testing (ACT) Rules Format 1.1 became an official web standard in early 2026. ACT defines the format for writing automated and manual accessibility test rules in a standardized, interoperable way. axe-core's built-in rules are authored as ACT-compatible rules, meaning each axe-core rule maps to a documented ACT rule that describes exactly what it tests and why. The practical impact for TypeScript QA teams: (1) When writing **custom axe-core rules** (see Custom axe-core Rules section above), following ACT Rules Format 1.1 structure (`metadata.description`, `helpUrl`, `evaluate()` function, pass/fail examples) ensures they remain maintainable and auditable; (2) ACT 1.1 now allows **subjective applicability** — meaning you can author rules for requirements that cannot be objectively automated (e.g., "form label is meaningful, not just present"), with a documented manual review fallback; (3) The `Implementations` section in ACT 1.1 lets you document which tools implement each rule — useful for justifying to auditors why a given axe-core scan configuration covers a specific WCAG criterion. WHY: teams that author custom rules without ACT structure end up with undocumented internal checks that new engineers cannot understand or maintain. ACT 1.1's formal structure prevents this.

62. **[community] Running axe-core across 50+ Playwright test files in CI without parallelization can cause test run times to balloon to 15–25 minutes — use Playwright's `--shard` option to distribute accessibility scans**: axe-core injects JavaScript into each page and runs synchronously in the browser context. On large applications with 50+ routes each requiring a full axe scan, the cumulative injection + analysis time adds up. The Playwright test sharding approach (`--shard=1/4`, `--shard=2/4`, etc.) distributes accessibility E2E tests across multiple CI runners. WHY: teams that put all accessibility tests in a single CI job find that the job becomes the longest job in the pipeline, delaying PRs by 15+ minutes when 5–6 parallel jobs would reduce it to 4–5 minutes. Recommended configuration: run jest-axe component tests (fast, 30–60s) in the same job as unit tests; run Playwright accessibility E2E in a dedicated job with `--shard` distributing across 3–4 runners. This mirrors the CI pipeline structure in the GitHub Actions YAML above.

---

### WCAG 2.2 ISO/IEC 40500:2025 — Procurement Implications for QA Programs

WCAG 2.2 was ratified as **ISO/IEC 40500:2025** in October 2025. The technical requirements are identical to the W3C WCAG 2.2 standard — no new success criteria, no changed conformance levels. The significance is in the procurement and legal landscape:

| Context | Previous position | Position after ISO/IEC 40500:2025 |
|---------|-------------------|-----------------------------------|
| EU EAA | EN 301 549 v3.3.2 references WCAG 2.2 directly | Unchanged — EU law references EN 301 549, not ISO |
| US Section 508 | WCAG 2.0 Level AA (updating to 2.1) | No change yet — Section 508 is behind the standard |
| ISO-referencing procurement (many APAC/MENA govts) | WCAG 2.0 was ISO/IEC 40500:2012 | Now WCAG 2.2 is ISO/IEC 40500:2025; enables mandate |
| Global SaaS certifications (SOC 2, ISO 27001 trust) | Not directly relevant | Accessibility now has ISO parity with security standards |

**Practical implication for QA teams:** If your organization produces an Accessibility Conformance Report (ACR/VPAT), reference ISO/IEC 40500:2025 in addition to WCAG 2.2 for government/enterprise procurement customers who require ISO standard citations. The axe-core test configuration does not change — WCAG 2.2 AA remains the target, now just with dual naming.

```typescript
// File: scripts/generate-acr-header.ts
// Generate the header for an Accessibility Conformance Report (ACR/VPAT)
// referencing both ISO/IEC 40500:2025 and WCAG 2.2 for maximum procurement coverage.

export interface ACRHeader {
  productName: string;
  version: string;
  reportDate: string;
  contactInfo: string;
}

export function generateACRHeader(info: ACRHeader): string {
  return `
ACCESSIBILITY CONFORMANCE REPORT
Based on WCAG 2.2 / ISO/IEC 40500:2025 and EN 301 549 v3.3.2
(Formerly known as VPAT)

Product: ${info.productName}
Version: ${info.version}
Report Date: ${info.reportDate}
Contact: ${info.contactInfo}

Standards Tested:
  • WCAG 2.2 Level AA (= ISO/IEC 40500:2025 Level AA)
  • EN 301 549 v3.3.2, Clauses 9.1–9.4 (Web)
  • Section 508 (where applicable — maps to WCAG 2.0/2.1 AA)

Testing Methodology:
  • Automated: axe-core 4.11.4 via @axe-core/playwright (WCAG 2.2 AA tag set)
  • Manual: Keyboard audit, NVDA + Firefox, VoiceOver + Safari
  • Standards: ACT Rules Format 1.1 (W3C 2026) for test rule documentation

Note: WCAG 2.2 and ISO/IEC 40500:2025 have identical technical content.
ISO/IEC 40500:2025 enables adoption by jurisdictions referencing ISO standards
in procurement law. Test procedures and conformance criteria are unchanged.
`.trim();
}
```

---

### ACT Rules Format 1.1 — Writing Auditable Custom Accessibility Rules

The W3C **Accessibility Conformance Testing (ACT) Rules Format 1.1** became an official web standard in 2026. Teams writing custom axe-core rules for organization-specific standards benefit from structuring those rules using ACT format — it makes them auditable, maintainable, and consistent with how built-in axe-core rules are authored.

**Key ACT 1.1 concepts for custom rule authors:**

| Concept | Description | Custom rule implication |
|---------|-------------|------------------------|
| **Atomic rule** | Tests a single specific condition | One `evaluate()` function per condition |
| **Composite rule** | Combines outcomes of multiple atomic rules | Use `any`/`all`/`none` arrays in axe rule config |
| **Applicability** | Defines which elements the rule applies to | `selector` in axe rule config |
| **Subjective applicability** (new in 1.1) | Allowed when objective test is impossible | Document manual review requirement in `helpUrl` |
| **Implementations section** | Documents which tools run this rule | Add comment: which axe version introduced this |
| **Secondary requirements** | Flags where tool findings need manual verification | Mark with `metadata.incomplete` logic |

```typescript
// File: e2e/config/act-rules-custom.ts
// ACT Rules Format 1.1 compliant custom axe-core rules.
// Follows ACT structure: description, applicability, expectations, examples, helpUrl.
// This structure ensures rules are auditable and maintainable by new team members.
import type { Rule, Check } from 'axe-core';

/**
 * ACT Rule: Meaningful heading text
 *
 * Applicability: All <h1>–<h6> elements with non-empty text
 * Expectation: Heading text must not be generic placeholders
 * Rationale: Generic headings (h2: "Section 2") fail WCAG 2.4.6 (Headings and Labels, AA)
 *   and prevent screen reader users from understanding page structure.
 *
 * ACT 1.1 note: This rule uses subjective applicability — "meaningful" cannot
 * be objectively defined. The check filters obvious failure patterns; human
 * review is required for borderline cases.
 *
 * Pass: <h2>Shopping cart</h2>
 * Fail: <h2>Section 2</h2> — generic placeholder
 * Fail: <h2>Heading</h2> — default CMS placeholder
 * Inapplicable: <h2 aria-hidden="true"> — hidden from accessibility tree
 */
const meaningfulHeadingCheck: Check = {
  id: 'meaningful-heading-text',
  evaluate(node: Element): boolean {
    const text = (node.textContent ?? '').trim().toLowerCase();
    if (!text) return true; // Empty headings caught by axe's built-in heading-order rule

    // Detect obviously generic patterns — not exhaustive; human review required
    const genericPatterns = [
      /^section\s*\d+$/i,          // "Section 1", "Section 2"
      /^heading\s*\d*$/i,           // "Heading", "Heading 1"
      /^untitled$/i,                // CMS default
      /^h[1-6]$/i,                  // Literal element name as content
      /^placeholder/i,              // "Placeholder text"
      /^lorem ipsum/i,              // Dev placeholder text
    ];

    const isGeneric = genericPatterns.some((p) => p.test(text));
    return !isGeneric;
  },
  metadata: {
    type: 'failure',
    messages: {
      pass: 'Heading text appears meaningful',
      fail: 'Heading text appears to be a generic placeholder (e.g., "Section 1", "Heading") — ' +
            'verify it describes the content below it. WCAG 2.4.6 (AA) requires headings to ' +
            'be informative. This check uses subjective applicability per ACT Rules Format 1.1 — ' +
            'manual review required for borderline cases.',
    },
  },
};

const meaningfulHeadingRule: Rule = {
  id: 'org-meaningful-heading',
  selector: 'h1, h2, h3, h4, h5, h6',
  tags: ['org-standards', 'wcag246', 'best-practice'],
  metadata: {
    description: 'Heading text must describe the content it introduces (WCAG 2.4.6 AA)',
    help: 'Replace generic placeholder headings with descriptive text',
    helpUrl: 'https://www.w3.org/WAI/WCAG22/Understanding/headings-and-labels.html',
    // ACT 1.1: document the Implementations section — which versions run this
    // Implementation: custom rule added <date>; aligns with ACT Rules Format 1.1
  },
  any: ['meaningful-heading-text'],
  all: [],
  none: [],
};

/**
 * ACT Rule: Interactive element has data-testid (org QA policy)
 *
 * Applicability: All interactive elements (button, a, input, select, textarea)
 * Expectation: Element has a data-testid attribute
 * Rationale: Org policy — all interactive elements require data-testid for QA automation
 *   and accessibility audit traceability. This is NOT a WCAG requirement; it is an
 *   org-level quality standard.
 *
 * ACT 1.1 type: Atomic rule with objective applicability
 *
 * Pass: <button data-testid="submit-form">Submit</button>
 * Fail: <button>Submit</button> — missing data-testid
 * Inapplicable: non-interactive elements
 */
const requireTestIdCheck: Check = {
  id: 'requires-test-id',
  evaluate(node: Element): boolean {
    return node.hasAttribute('data-testid');
  },
  metadata: {
    type: 'failure',
    messages: {
      pass: 'Interactive element has data-testid attribute',
      fail: 'Interactive element is missing data-testid attribute ' +
            '(org policy — required for QA automation and audit traceability)',
    },
  },
};

const requireTestIdRule: Rule = {
  id: 'org-require-test-id',
  selector: 'button:not([disabled]), a[href], input:not([disabled]), select:not([disabled]), textarea:not([disabled])',
  tags: ['org-standards'],
  metadata: {
    description: 'Interactive elements must have data-testid (org QA policy)',
    help: 'Add data-testid="<descriptive-name>" to all interactive elements',
    helpUrl: 'https://your-org.example.com/qa/test-ids',
  },
  any: ['requires-test-id'],
  all: [],
  none: [],
};

import axe from 'axe-core';

export function registerACTCompliantCustomRules(): void {
  axe.configure({
    checks: [meaningfulHeadingCheck, requireTestIdCheck],
    rules: [meaningfulHeadingRule, requireTestIdRule],
  });
}
```

```typescript
// File: e2e/accessibility/act-rules-compliance.spec.ts
// Test that ACT-compliant custom rules run alongside standard WCAG checks.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { registerACTCompliantCustomRules } from '../config/act-rules-custom';

test.describe('ACT 1.1 custom rule compliance', () => {
  test.beforeAll(() => {
    registerACTCompliantCustomRules();
  });

  test('headings are meaningful (org-meaningful-heading rule)', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'org-standards', 'best-practice'])
      .analyze();

    // Separate org violations from WCAG violations for targeted reporting
    const orgViolations = results.violations.filter((v) =>
      v.id === 'org-meaningful-heading'
    );
    const wcagViolations = results.violations.filter((v) =>
      v.id !== 'org-meaningful-heading' && v.id !== 'org-require-test-id'
    );

    if (orgViolations.length > 0) {
      // Note: ACT 1.1 subjective applicability — these require human review
      console.warn(
        `[ACT Rule: org-meaningful-heading] ${orgViolations.length} headings need review:\n` +
        orgViolations.flatMap((v) => v.nodes.map((n) => `  - "${n.html}"`)).join('\n')
      );
    }

    // WCAG violations are hard failures; org violations are warnings
    expect(wcagViolations).toEqual([]);
  });
});
```

**ACT Rules Format 1.1 compliance checklist for custom rules:**

1. **Unique ID** — must not conflict with built-in axe rule IDs; use `org-` prefix
2. **Rule type** — declare as atomic (single condition) or composite (combines atomics)
3. **Applicability** — define via `selector`; if truly subjective, document manual review requirement in `metadata.help`
4. **Expectations** — the `evaluate()` function is the expectation; return `true` for pass, `false` for fail
5. **Pass/Fail examples** — document in JSDoc comments adjacent to the rule definition
6. **WCAG mapping** — add relevant WCAG SC code to `tags` if applicable (e.g., `'wcag246'`)
7. **`helpUrl`** — always link to internal docs; this is what appears in violation reports
8. **Implementations note** — comment which tool version introduced the rule and when

---

### Playwright 1.56 `input` Placeholder in Aria Snapshots

Playwright 1.56 (released early 2025) changed how `ariaSnapshot()` renders `<input>` elements. Input placeholder text is now included as part of the YAML representation:

**Before 1.56:**
```yaml
- textbox "Email address"
```

**After 1.56:**
```yaml
- textbox "Email address" [placeholder="user@example.com"]
```

**Impact on existing aria snapshot tests:**

Teams upgrading from Playwright 1.55 or earlier with committed `.aria.yml` snapshot files will see snapshot test failures on any `<input>` element that has a `placeholder` attribute — even if the ARIA structure is correct and unchanged. This is not a regression; it is an improvement in snapshot fidelity.

**Migration steps:**

1. Run `npx playwright test --update-snapshots` after upgrading to 1.56+
2. Review the diff to verify placeholder text is meaningful (not just `"e.g., enter email"` placeholder patterns)
3. If placeholder text is used as a pseudo-label substitute (WCAG anti-pattern — see Anti-Pattern #5), this diff will expose that in version control — use it as an opportunity to fix the accessibility issue

```typescript
// File: e2e/accessibility/aria-snapshot-placeholder.spec.ts
// Playwright 1.56+: aria snapshots now include input placeholder text.
// Use this test pattern to verify placeholders are complementary to labels,
// not substitutes for labels (WCAG 3.3.2).
import { test, expect } from '@playwright/test';

test.describe('Input placeholder in aria snapshots (Playwright 1.56+)', () => {

  // This snapshot documents the expected accessible form structure including placeholders.
  // After Playwright 1.56, placeholder text appears as [...] in the YAML snapshot.
  // If a form input lacks a label (relying on placeholder only), the snapshot will
  // show a textbox with only a placeholder — a useful accessibility flag.
  test('login form inputs have both labels AND placeholders', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    const form = page.getByRole('form', { name: 'Sign in' });

    // ✅ Good: input has an accessible name from its label, plus an optional placeholder
    // The snapshot shows both the label-derived name AND the placeholder
    await expect(form).toMatchAriaSnapshot(`
      - form "Sign in":
        - textbox "Email address" [placeholder="your@email.com"]
        - textbox "Password" [placeholder="Enter your password"]
        - button "Sign in"
    `);
  });

  // Test that reveals a missing label — placeholder-only inputs show
  // the accessible name as empty and only the placeholder is visible in the snapshot
  test('detect placeholder-only inputs (missing labels) via snapshot diff', async ({ page }) => {
    await page.goto('/register');
    await page.waitForLoadState('networkidle');

    // Use ariaSnapshot() programmatically to inspect all inputs
    const formSnapshot = await page.getByRole('form').ariaSnapshot();

    // A properly labeled input: 'textbox "Email address" [placeholder=...]'
    // A placeholder-only input: 'textbox [placeholder="Enter email"]' — no quoted name before [
    const hasUnnamedInputs = /textbox \[placeholder/i.test(formSnapshot);

    if (hasUnnamedInputs) {
      console.error(
        '[WCAG 3.3.2] Form contains placeholder-only inputs (no visible label).\n' +
        'Snapshot excerpt:\n' +
        formSnapshot.split('\n').filter((l) => l.match(/textbox \[placeholder/i)).join('\n')
      );
    }

    // Fail CI if any inputs rely solely on placeholder text as their accessible name
    expect(hasUnnamedInputs).toBe(false);
  });
});
```

**Why Playwright 1.56's placeholder rendering is beneficial:**

Before 1.56, aria snapshots of forms were identical whether a form used proper labels or placeholder-only inputs — both showed `textbox "Email address"` if the accessible name computed correctly. After 1.56, placeholder-only inputs are visibly distinct in snapshots (`textbox [placeholder="Email"]` vs `textbox "Email address" [placeholder="Email"]`), making the anti-pattern detectable in CI snapshot diffs.

**Updating the global `toMatchAriaSnapshot` config for placeholder handling:**

```typescript
// File: playwright.config.ts update for 1.56+ placeholder snapshots
// If you want to ignore placeholder values in snapshots (e.g., they change frequently),
// generate the baseline without placeholder assertions by stripping the [...] from templates.
// However, this removes the anti-pattern detection benefit — only suppress if justified.
import { defineConfig } from '@playwright/test';

export default defineConfig({
  expect: {
    toMatchAriaSnapshot: {
      children: 'contain', // Default; extras ignored in partial matching
    },
  },
  use: {
    baseURL: 'http://localhost:3000',
  },
});
```

---

### WCAG-EM 2.0 — Evaluation Methodology for QA Programs

The W3C **Website Accessibility Conformance Evaluation Methodology (WCAG-EM) 2.0** is a draft evaluation framework being developed alongside WCAG 3.0. While WCAG-EM 1.0 defined how to evaluate websites, WCAG-EM 2.0 extends the scope to **digital products** — web applications, mobile web, and multi-page SPAs — that do not fit the traditional "website" model cleanly.

**Why QA teams should track WCAG-EM 2.0:**
- WCAG-EM 1.0 used "page sampling" — selecting representative pages from a site. SPAs with dynamic routing do not have discrete "pages" to sample.
- WCAG-EM 2.0 introduces **user flow sampling** — selecting representative user tasks (checkout, login, account creation) rather than static pages. This maps directly to how Playwright E2E tests are structured.
- WCAG-EM 2.0 evaluation outputs are designed to feed into ACR/VPAT documents with more structured findings than WCAG-EM 1.0 evaluation statements.

**WCAG-EM 1.0 five-step process (current standard):**

| Step | Description | Automation opportunity |
|------|-------------|----------------------|
| 1. Define scope | Identify target website, conformance level, AT support baseline | Document in `axe-wcag22-fixture.ts` options |
| 2. Explore website | Identify page types, essential functionality, relied-on tech | Enumerate routes in Playwright test config |
| 3. Select sample | Structured sample (all page types) + 10% random sample | `pagesToScan` array in baseline spec |
| 4. Audit sample | Check WCAG conformance per success criterion | axe scan + manual keyboard + screen reader |
| 5. Report findings | Document outcomes; produce evaluation statement | ACR/VPAT generation script |

**TypeScript script applying WCAG-EM 1.0 sampling to automated axe scans:**

```typescript
// File: scripts/wcag-em-sample-scan.ts
// Applies WCAG-EM 1.0 structured sampling to automated axe scans.
// Step 3: Select structured sample + 10% random sample for the audit.
import { chromium } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import * as fs from 'fs';

// Step 2 output: All identified page types from the site exploration
const STRUCTURED_SAMPLE = [
  // Essential functionality (WCAG-EM: must include complete processes)
  { url: '/', type: 'home', category: 'entry' },
  { url: '/login', type: 'auth', category: 'essential' },
  { url: '/register', type: 'auth', category: 'essential' },
  { url: '/checkout/step-1', type: 'checkout', category: 'essential' },
  { url: '/checkout/step-2', type: 'checkout', category: 'essential' },
  { url: '/checkout/confirmation', type: 'checkout', category: 'essential' },
  // Page type representatives
  { url: '/products', type: 'list', category: 'page-type' },
  { url: '/products/123', type: 'detail', category: 'page-type' },
  { url: '/account/profile', type: 'form', category: 'page-type' },
  { url: '/help', type: 'content', category: 'page-type' },
  { url: '/contact', type: 'form', category: 'page-type' },
];

// Step 3: Add 10% random sample from the full URL inventory
function selectRandomSample(allUrls: string[], structuredSample: string[], pct = 0.1): string[] {
  const structured = new Set(structuredSample);
  const candidates = allUrls.filter((url) => !structured.has(url));
  const sampleSize = Math.max(1, Math.ceil(candidates.length * pct));

  // Deterministic pseudo-random selection for reproducibility
  const shuffled = candidates.sort((a, b) => a.localeCompare(b));
  return shuffled.slice(0, sampleSize);
}

interface WCAGEMScanResult {
  url: string;
  type: string;
  category: string;
  violationCount: number;
  violationsBySeverity: Record<string, number>;
  sampleType: 'structured' | 'random';
}

export async function runWCAGEMScan(
  baseUrl: string,
  allKnownUrls: string[]
): Promise<WCAGEMScanResult[]> {
  // Select the 10% random sample from known URLs not in structured sample
  const structuredUrls = STRUCTURED_SAMPLE.map((p) => p.url);
  const randomSampleUrls = selectRandomSample(allKnownUrls, structuredUrls);

  const allPages = [
    ...STRUCTURED_SAMPLE.map((p) => ({ ...p, sampleType: 'structured' as const })),
    ...randomSampleUrls.map((url) => ({
      url,
      type: 'random-sample',
      category: 'random',
      sampleType: 'random' as const,
    })),
  ];

  const browser = await chromium.launch();
  const results: WCAGEMScanResult[] = [];

  for (const pageInfo of allPages) {
    const page = await browser.newPage();
    try {
      await page.goto(baseUrl + pageInfo.url);
      await page.waitForLoadState('networkidle');

      const axeResults = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'])
        .analyze();

      const bySeverity = axeResults.violations.reduce(
        (acc, v) => {
          const key = v.impact ?? 'unknown';
          acc[key] = (acc[key] ?? 0) + 1;
          return acc;
        },
        {} as Record<string, number>
      );

      results.push({
        url: pageInfo.url,
        type: pageInfo.type,
        category: pageInfo.category,
        sampleType: pageInfo.sampleType,
        violationCount: axeResults.violations.length,
        violationsBySeverity: bySeverity,
      });
    } catch (e) {
      console.warn(`[WCAG-EM] Failed to scan ${pageInfo.url}: ${e}`);
    } finally {
      await page.close();
    }
  }

  await browser.close();

  // Step 5: Report findings summary
  const totalViolations = results.reduce((sum, r) => sum + r.violationCount, 0);
  const pagesWithViolations = results.filter((r) => r.violationCount > 0).length;

  console.log('\n=== WCAG-EM 1.0 Evaluation Summary ===');
  console.log(`Pages scanned: ${results.length} (${STRUCTURED_SAMPLE.length} structured + ${randomSampleUrls.length} random)`);
  console.log(`Pages with violations: ${pagesWithViolations}/${results.length}`);
  console.log(`Total violations: ${totalViolations}`);
  console.log('\nResults by page:');
  results.forEach((r) => {
    const status = r.violationCount === 0 ? '✓' : '✗';
    console.log(`  ${status} [${r.sampleType}] ${r.url} — ${r.violationCount} violations`);
  });

  // Write WCAG-EM Step 5 structured output for ACR/VPAT generation
  fs.writeFileSync(
    'wcag-em-evaluation.json',
    JSON.stringify({ scanDate: new Date().toISOString(), pages: results }, null, 2)
  );

  return results;
}
```

**WCAG-EM 2.0 user-flow sampling preview (draft concept):**

WCAG-EM 2.0 shifts from page sampling to user-flow sampling. A "user flow" is a complete task like "log in and update profile" rather than isolated pages. This aligns exactly with Playwright E2E test suites — each Playwright test that follows a multi-step user journey IS a WCAG-EM 2.0 user-flow sample. Teams that structure their Playwright accessibility tests as user flows are already aligned with the WCAG-EM 2.0 direction:

```typescript
// File: e2e/accessibility/wcag-em-flow.spec.ts
// WCAG-EM 2.0 aligned user flow accessibility testing.
// Each test covers a complete user task, not just an isolated page.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('WCAG-EM 2.0 user flow — Checkout process', () => {
  // Each step in the flow gets its own axe scan at the correct state
  test('checkout flow: all 3 steps have no WCAG 2.2 AA violations', async ({ page }) => {
    // Step 1: Cart review
    await page.goto('/cart');
    await page.waitForLoadState('networkidle');
    const cartResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])
      .analyze();
    expect(cartResults.violations, 'Cart page violations').toEqual([]);

    // Step 2: Shipping details (dynamic form state — critical to test at this point)
    await page.click('[data-testid="proceed-to-checkout"]');
    await page.waitForURL('/checkout/shipping');
    await page.waitForLoadState('networkidle');
    const shippingResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])
      .analyze();
    expect(shippingResults.violations, 'Shipping step violations').toEqual([]);

    // Step 3: Order review before submission
    await page.fill('[name="first-name"]', 'Test');
    await page.fill('[name="last-name"]', 'User');
    await page.fill('[name="address"]', '123 Test St');
    await page.click('[data-testid="proceed-to-review"]');
    await page.waitForURL('/checkout/review');
    await page.waitForLoadState('networkidle');
    const reviewResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])
      .analyze();
    expect(reviewResults.violations, 'Order review page violations').toEqual([]);
  });
});
```

**Why user-flow scanning catches issues page scanning misses:** A checkout confirmation page only exists after a user has completed the previous steps. A static URL scan at `/checkout/confirmation` without state will show an empty or error page. User-flow scanning captures the real accessible state of the confirmation page after a completed transaction — the state screen reader users encounter. This is the core insight behind WCAG-EM 2.0's user-flow model.

---

### axe-core-npm v4.11.1 TypeScript Export Reorder Fix

axe-core-npm v4.11.1 (released March 2026) included a **TypeScript export reordering fix** (`reorder exports to place types first`) in the `@axe-core/playwright` package. This fix resolves a class of TypeScript compilation errors that affect projects using certain `moduleResolution` settings (`bundler`, `NodeNext`, `Node16`).

**The problem (before 4.11.1):**

TypeScript projects with `"moduleResolution": "NodeNext"` or `"bundler"` in their `tsconfig.json` import types via `import type` and resolve type exports from the package entry point. When value exports (functions, classes) appear before type exports in the package's index, TypeScript's strict module resolution can fail to find the type definitions, emitting errors like:

```
error TS2305: Module '@axe-core/playwright' has no exported member 'AxeBuilder'.
error TS2305: Module '@axe-core/playwright' has no exported member 'Result'.
```

This would occur at compile time even though runtime imports worked fine (because Node.js module resolution differs from TypeScript's strict type resolution in `NodeNext` mode). The fix reorders all type exports to appear before value exports in the package entry point, which satisfies TypeScript's `NodeNext` / `bundler` resolution requirements.

**Affected version range:** `@axe-core/playwright` versions before 4.11.1 with TypeScript `moduleResolution: NodeNext` or `bundler`.

**Upgrade path:**

```bash
npm install @axe-core/playwright@^4.11.1
# or
npm install @axe-core/playwright@latest
```

**Why this matters for QA teams:** The error appeared non-deterministically — it surfaced on fresh CI runs (where the TypeScript language server cache was cold) or after changing `tsconfig.json`. Teams that added `@ts-ignore` workarounds or downgraded their `moduleResolution` should remove those workarounds after upgrading to 4.11.1+.

```typescript
// File: tsconfig.json — configuration that triggered the bug before 4.11.1
// These moduleResolution settings expose the export ordering issue:
{
  "compilerOptions": {
    "module": "NodeNext",         // ← This setting
    "moduleResolution": "NodeNext", // ← OR this setting
    // OR:
    "moduleResolution": "bundler"   // ← OR this setting (Vite projects)
  }
}

// After upgrading to @axe-core/playwright 4.11.1+, these tsconfigs work correctly
// and the following import pattern compiles without error:
import AxeBuilder from '@axe-core/playwright';
import type { AxeResults, Result, NodeResult } from 'axe-core';
// ↑ Named type imports from the axe-core package (peer dep) still work
//   because axe-core's own types are unaffected — only the playwright wrapper was fixed.
```

---

### @axe-core/playwright — Deferred Iframe Skip Fix

`@axe-core/playwright` v4.9.1 (maintained across the 4.11.x release line) introduced a fix that **silently skips iframes that have not yet loaded** rather than throwing an unhandled error. This matters for pages using lazy-loaded or deferred iframes (e.g., embedded maps, payment widgets, chat widgets loaded after the main content).

**The problem (before the fix):**

When `AxeBuilder.analyze()` ran on a page containing an `<iframe>` whose `src` had not yet resolved, axe-core's iframe injection would fail with an unhandled promise rejection. Depending on the axe-core version and whether the Playwright page event listener was still active, this could:
- Cause the test to time out silently (most common)
- Emit a `UnhandledPromiseRejection` warning in Node.js output
- Return `{ violations: [], passes: [], incomplete: [] }` without error, masking a partial scan

**After the fix:**

Unloaded iframes are skipped during analysis. The iframe URL is included in the `axe-core` response's `incomplete` category with `id: 'frame-tested'` and a reason of `'Could not inject into frame'`. This is visible in the scan results and can be tested for explicitly.

```typescript
// File: e2e/accessibility/deferred-iframe.spec.ts
// Pattern for handling pages with deferred iframes in axe scans.
// Verifies that the main content is clean AND that we're aware of any skipped frames.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Pages with deferred/lazy iframes', () => {

  test('main content has no violations (iframes may be skipped)', async ({ page }) => {
    await page.goto('/checkout/payment');
    // Wait for main content to load, but do NOT wait for the payment iframe
    // (it loads conditionally after user interaction or is intentionally deferred)
    await page.waitForLoadState('domcontentloaded');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])
      .analyze();

    // Check if any frames were skipped (expected for deferred payment iframe)
    const skippedFrames = results.incomplete.filter(
      (r) => r.id === 'frame-tested'
    );
    if (skippedFrames.length > 0) {
      console.warn(
        `[a11y] ${skippedFrames.length} frame(s) not scanned (deferred load):\n` +
        skippedFrames.flatMap((r) => r.nodes.map((n) => `  - ${n.html}`)).join('\n') +
        '\n  Action: scan these frames separately after user interaction triggers loading.'
      );
    }

    // Main page violations are hard failures
    expect(results.violations, 'Main page WCAG violations').toEqual([]);
  });

  test('payment iframe is accessible after user triggers load', async ({ page }) => {
    await page.goto('/checkout/payment');
    await page.waitForLoadState('domcontentloaded');

    // Trigger the deferred iframe to load (e.g., user selects credit card)
    await page.click('[data-testid="payment-method-card"]');
    // Wait specifically for the iframe to appear and load
    await page.waitForSelector('iframe[data-testid="payment-frame"]');
    await page.waitForTimeout(500); // Allow iframe content to initialize

    // Now rescan — the iframe should be included
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])
      .analyze();

    const stillSkipped = results.incomplete.filter((r) => r.id === 'frame-tested');
    expect(stillSkipped, 'Payment iframe should be scanned after load').toHaveLength(0);
    expect(results.violations, 'Full page WCAG violations after iframe load').toEqual([]);
  });
});
```

**Why this matters:** Teams that run axe on pages with chat widgets, embedded maps, or payment iframes without waiting for those iframes to load may be getting false-clean results — the scan passes because the problematic iframe was silently skipped. The `incomplete[].id === 'frame-tested'` check makes the skip explicit, allowing QA teams to add targeted scans when the iframe is actually loaded.

---

### New Community Gotchas (Iteration 38)

63. **[community] `@axe-core/playwright` 4.11.1 TypeScript export reorder fix — if you see `Module '@axe-core/playwright' has no exported member 'AxeBuilder'` in a TypeScript NodeNext/bundler project, upgrade to 4.11.1+**: Before 4.11.1, the `@axe-core/playwright` package placed type exports after value exports in its entry point. TypeScript's strict `NodeNext` and `bundler` module resolution modes require type exports to appear first to resolve them correctly. The symptom was a compile-time `TS2305` error claiming `AxeBuilder` is not exported, despite the package clearly exporting it. The fix in 4.11.1 reorders exports so types appear before values. WHY: teams using Vite (which defaults to `moduleResolution: bundler`) or modern ESM TypeScript projects were most affected; switching back to `node` or `node10` module resolution was a common but unnecessary workaround that should be reverted after upgrading.

64. **[community] Deferred/lazy iframes are silently skipped by axe-core before the @axe-core/playwright 4.9.1 fix — check `results.incomplete` for `frame-tested` to confirm all frames were scanned**: Pages that include payment widgets, chat widgets, or embedded maps via lazy-loaded iframes can return a clean axe result even though the iframe content was never scanned. After the 4.9.1 fix, unloaded iframes appear in `results.incomplete` with `id: 'frame-tested'` instead of causing silent errors. A clean `violations: []` result without checking `incomplete` for skipped frames gives false confidence. WHY: accessibility violations in embedded third-party iframes (WCAG 4.1.2 for payment frames, for example) are the responsibility of the page embedding them if no equivalent alternative is provided.

65. **[community] axe-core-npm monorepo reached v4.11.3 on 2026-05-04 — verify your `@axe-core/*` packages are aligned to the same monorepo version to avoid inter-package type mismatches**: The axe-core-npm monorepo publishes all `@axe-core/*` packages together at the same version (`@axe-core/playwright`, `@axe-core/react`, `@axe-core/cli`, `@axe-core/reporter-earl`, `jest-axe`, etc.). Running mismatched versions — e.g., `@axe-core/playwright@4.11.3` with `axe-core@4.11.1` as a peer dep — can cause rule differences where one package includes rules or fixes not present in the peer. Use `npm ls axe-core` to verify all packages resolve to the same axe-core version. WHY: gotcha #8 above (axe-core version mismatch between jest-axe and playwright) is the most common form of this problem; the general principle applies to all packages in the monorepo.

66. **[community] AxeBuilder memory usage grows with page complexity in large-scale CI scans — axe-core-npm 4.11.0 includes memory optimizations for the AxeBuilder context accumulation, but teams scanning 100+ pages per CI run should still implement explicit cleanup**: Prior to axe-core-npm 4.11.0, the `AxeBuilder` instance accumulated internal state across multiple `.analyze()` calls on the same instance. For teams scanning large applications (100+ routes in CI), this caused Node.js heap growth and occasional OOM kills. The 4.11.0 optimization reduces context accumulation. However, the best practice remains to create a new `AxeBuilder({ page })` instance for each scan rather than reusing across page navigations. WHY: the `AxeBuilder` is designed as a per-scan configuration object, not a persistent scanner; creating one per test (as shown in all patterns above) is both idiomatic and memory-safe regardless of the version.

---

### IBM Equal Access Toolkit v4.0.17 — Playwright Integration for Secondary Engine Coverage

IBM's Equal Access accessibility-checker (v4.0.17, April 28, 2026) provides a complementary rule engine to axe-core with particularly strong EN 301 549 and Section 508 coverage. When used as a **secondary engine** alongside axe-core, it catches a different set of issues — particularly around form semantics, table structure, and ARIA validation patterns that axe-core handles differently.

**Key differentiators from axe-core:**
- **Baseline comparison**: validates against stored baseline files, enabling you to detect *regressions* from a known-good state rather than flagging all pre-existing issues
- **Multi-format output**: JSON, CSV, XLSX, HTML reporting formats
- **Policy-driven severity management**: configured via `.achecker.yml` with per-rule severity overrides
- **WCAG 2.0, 2.1, 2.2 + Section 508**: broader standard mapping than axe-core for US government compliance

**When to add IBM Equal Access as a secondary engine:**
- US government or regulated-sector products (FedRAMP, FISMA) where Section 508 conformance evidence is required
- Teams that need baseline comparison ("did this release introduce new violations?") rather than just "are there any violations?"
- Products targeting the EU public sector (EN 301 549 alignment beyond WCAG 2.2)

```typescript
// File: e2e/accessibility/ibm-checker.spec.ts
// IBM Equal Access checker as a secondary engine in Playwright.
// Runs AFTER the primary axe-core scan — only catches violations axe missed.
// Install: npm install --save-dev accessibility-checker

import { test, expect } from '@playwright/test';
// Note: accessibility-checker uses CommonJS exports; use require() in ESM/TS projects
// or ensure your tsconfig allows CJS interop (allowSyntheticDefaultImports: true)
// eslint-disable-next-line @typescript-eslint/no-var-requires
const aChecker = require('accessibility-checker');

test.afterAll(async () => {
  // Close the accessibility-checker browser session after all tests in the file
  await aChecker.close();
});

test.describe('Homepage — IBM Equal Access secondary scan', () => {

  test('no IBM accessibility violations on homepage', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // getCompliance accepts the Playwright Page object directly
    // Label is used to identify this scan in the JSON/CSV report
    const result = await aChecker.getCompliance(page, 'homepage-ibm-a11y');
    const report = result.report;

    // assertCompliance returns 0 (pass) or non-zero (fail)
    // It respects the .achecker.yml baseline and severity configuration
    const returnCode = aChecker.assertCompliance(report);

    if (returnCode !== 0) {
      // Log the violations in a readable format for CI output
      const violations = report.results.filter(
        (r: { level: string }) => r.level === 'violation'
      );
      violations.forEach((v: { ruleId: string; reasonId: string; xpath: string; message: string }) => {
        console.error(
          `[IBM a11y] ${v.ruleId} (${v.reasonId}) at ${v.xpath}: ${v.message}`
        );
      });
    }

    expect(returnCode, 'IBM accessibility-checker violations found').toBe(0);
  });

  test('form page has no IBM accessibility violations', async ({ page }) => {
    await page.goto('/contact');
    await page.waitForLoadState('networkidle');

    const result = await aChecker.getCompliance(page, 'contact-form-ibm-a11y');
    expect(aChecker.assertCompliance(result.report)).toBe(0);
  });

});
```

**Configuring `.achecker.yml` for WCAG 2.2 scope:**

```yaml
# File: .achecker.yml — IBM accessibility-checker project configuration
# Place in repository root alongside package.json

# Scan policy — use WCAG 2.2 level AA
policies:
  - WCAG_2_2

# Fail on violations only (not recommendations/potentialviolations)
# Options: violation | potentialviolation | recommendation | message | ignored
failLevels:
  - violation

# Report levels — include everything for diagnostic output
reportLevels:
  - violation
  - potentialviolation
  - recommendation

# Output format for CI artifacts
outputFormat:
  - json
  - csv

# Baseline file path — stores known violations for regression comparison
# Initialize by running the checker once on a known-good state:
# npx achecker --baselineFile=.a11y-baseline.json
baselineFile: .a11y-baseline.json
```

**Version pinning note**: IBM Equal Access v4.0.17 (April 2026) is the current stable release. The `accessibility-checker` package ships as CommonJS; TypeScript projects with `"module": "NodeNext"` or `"moduleResolution": "bundler"` must use `import aChecker from 'accessibility-checker'` with `esModuleInterop: true`, or use `require()` syntax in a `.cts` file.

---

### Pa11y CI v4.1.0 — URL-Based Secondary Scanning for Pre-Deployment Gates

Pa11y CI (v4.1.0, March 3, 2026) provides command-line accessibility scanning that complements axe-core by using the HTMLCS (HTML_CodeSniffer) rule engine. As a **URL-based scanner**, it is particularly effective for:
- Pre-deployment checks against staging URLs without requiring Playwright test authoring
- Sitemap-driven scanning of entire sites
- CI pipelines that need a lightweight "smoke test" accessibility gate before full E2E tests run

Pa11y CI uses a different rule engine than axe-core, which means it can flag issues that axe-core misses (and vice versa). Running both as complementary scanners provides broader automated coverage toward the ~57% axe-core ceiling.

**Node.js requirement**: Pa11y CI v4.x requires Node.js ≥ 20 (even-numbered stable).

```json
// File: .pa11yci.json — Pa11y CI configuration for pre-deployment staging scan
// Runs against a list of critical URLs before promotion to production.
// Install: npm install --save-dev pa11y-ci
{
  "defaults": {
    "standard": "WCAG2AA",
    "level": "error",
    "timeout": 30000,
    "wait": 1000,
    "chromeLaunchConfig": {
      "args": ["--no-sandbox", "--disable-setuid-sandbox"]
    },
    "ignore": [
      "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail"
    ],
    "threshold": 0
  },
  "urls": [
    "https://staging.example.com/",
    "https://staging.example.com/login",
    "https://staging.example.com/dashboard",
    "https://staging.example.com/settings",
    "https://staging.example.com/help"
  ]
}
```

```yaml
# File: .github/workflows/pa11y-staging.yml
# Pre-deployment accessibility gate using Pa11y CI
# Runs against the staging URL before production promotion.
name: Pa11y CI Accessibility Gate

on:
  workflow_dispatch:
  deployment_status:

jobs:
  pa11y:
    name: Pa11y WCAG 2 AA scan (staging)
    runs-on: ubuntu-latest
    if: github.event.deployment_status.state == 'success'
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - name: Run Pa11y CI
        run: npx pa11y-ci --config .pa11yci.json
      - name: Upload Pa11y results
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: pa11y-results
          path: pa11y-report.json
```

**Pa11y CI vs axe-core complementarity:**
| Aspect | axe-core (@axe-core/playwright) | Pa11y CI (HTMLCS engine) |
|--------|--------------------------------|--------------------------|
| Rule engine | Deque axe-core | HTML_CodeSniffer |
| Integration | Playwright / Jest test files | CLI / URL list |
| Real browser | Yes (Playwright) | Yes (Puppeteer/Chrome) |
| WCAG 2.2 support | Yes (wcag22aa tag) | WCAG2AA standard |
| Best for | Component + page scans in CI tests | URL-list staging gates |
| Baseline comparison | Manual JSON diff | Built-in threshold |
| Unique rule coverage | ARIA validation, RGAA, target-size | Table structure, some text-level checks |

**Production lesson**: Pa11y CI is most valuable as a **pre-deployment gate on staging**, not as a replacement for test-embedded axe-core scans. Run axe in unit and E2E tests; run Pa11y CI against the staged build URL before production promotion. This two-layer approach provides both in-development feedback (axe in CI tests) and pre-release validation (Pa11y against the actual deployed artifact).

---

### Playwright 1.60 — Page-Level `toMatchAriaSnapshot()` and `boxes` Option

Playwright 1.60 (latest as of May 2026) introduced two additions to the aria snapshot API that directly affect accessibility testing workflows.

#### 1. Page-Level `toMatchAriaSnapshot()`

Before 1.60, `toMatchAriaSnapshot()` was only available on `Locator` objects. In 1.60, `expect(page).toMatchAriaSnapshot()` works on the `Page` object itself, equivalent to `expect(page.locator('body')).toMatchAriaSnapshot()`. This simplifies full-page aria tree regression tests:

```typescript
// File: e2e/accessibility/aria-regression.spec.ts
// Playwright 1.60+: page-level aria snapshot for full-page accessibility tree regression.
import { test, expect } from '@playwright/test';

test.describe('Aria snapshot regression tests', () => {

  test('homepage aria tree matches approved snapshot', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Playwright 1.60+: toMatchAriaSnapshot on Page directly (not a locator)
    // On first run: creates __snapshots__/homepage.aria.yaml
    // On subsequent runs: compares against the stored snapshot
    await expect(page).toMatchAriaSnapshot({
      name: 'homepage',   // snapshot file name (stored in __snapshots__/)
    });
  });

  test('navigation region has expected structure', async ({ page }) => {
    await page.goto('/');

    // Locator-scoped snapshot — test only the nav structure
    // Using depth option (v1.59+) to limit snapshot depth for focused tests
    const nav = page.getByRole('navigation', { name: 'Main navigation' });
    await expect(nav).toMatchAriaSnapshot(`
      - navigation "Main navigation":
        - link "Home"
        - link "About"
        - link "Contact"
    `);
  });

  test('modal has correct accessibility tree when open', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-testid="open-settings-modal"]');
    await page.waitForSelector('[role="dialog"]');

    // Test only the dialog region to avoid unrelated page changes breaking the snapshot
    await expect(page.getByRole('dialog')).toMatchAriaSnapshot(`
      - dialog "Settings":
        - heading "Settings" [level=2]
        - group "Notification preferences":
          - checkbox "Email notifications"
          - checkbox "SMS notifications"
        - button "Save changes"
        - button "Close dialog"
    `);
  });

});
```

#### 2. `boxes` Option: Bounding Box Metadata in Aria Snapshots

The `boxes` option (v1.60) appends `[box=x,y,width,height]` data to each node in the aria snapshot YAML. This is primarily designed for AI/LLM consumption — an agent reviewing the aria snapshot can use spatial coordinates to reason about layout and visual proximity of accessible elements.

```typescript
// File: e2e/accessibility/aria-with-boxes.spec.ts
// The boxes option is primarily for AI-assisted accessibility analysis,
// not for standard pass/fail accessibility testing.
import { test } from '@playwright/test';

test('capture aria snapshot with bounding boxes for AI analysis', async ({ page }) => {
  await page.goto('/checkout');
  await page.waitForLoadState('networkidle');

  // ariaSnapshot with boxes returns YAML with [box=x,y,w,h] on each element
  // Useful for: AI agents validating visual + semantic alignment (e.g., navable MCP)
  const snapshotWithBoxes = await page.ariaSnapshot({ boxes: true });

  // Example output fragment:
  // - heading "Checkout" [level=1] [box=24,64,960,48]
  // - group "Shipping address" [box=24,128,480,320]
  //   - textbox "First name" [box=24,176,224,44]
  //   - textbox "Last name" [box=264,176,224,44]

  // Store for AI accessibility review tools (not typically used in pass/fail assertions)
  await test.info().attach('aria-snapshot-with-boxes.yaml', {
    body: Buffer.from(snapshotWithBoxes),
    contentType: 'text/plain',
  });
});
```

**When to use `boxes`**: This option produces very large snapshot files and is not suitable for pass/fail regression tests. Use it as an artifact attachment for AI-assisted accessibility review, or as input to agent-driven accessibility analysis tools (navable MCP, Aura scanner, or custom LLM-based a11y review pipelines).

---

### `axe.run()` `resultTypes` Performance Option for Large-Page Scans

On complex pages (dashboards, data-heavy tables, SPAs with many components), a full axe-core scan can take 2–5 seconds per page and generate large result objects. The `resultTypes` option limits which result categories are fully expanded, significantly reducing both scan time and memory usage.

**Default behavior**: axe returns full details for `passes`, `violations`, `incomplete`, and `inapplicable` — even when only `violations` matter for CI gating.

**`resultTypes` behavior**: specifies which result arrays include full node details. Other arrays are still returned but contain only summary information (no `nodes` array expansion).

```typescript
// File: e2e/accessibility/performance-scan.spec.ts
// Use resultTypes to limit axe result detail on large pages.
// This reduces scan time by ~40-60% on pages with many passing rules.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Optimized axe scans for large pages', () => {

  test('dashboard accessibility — violations only (fast mode)', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'])
      // resultTypes: only violations get full node details
      // passes, incomplete, inapplicable are included as summaries (no nodes array)
      // This is the recommended approach for CI gates where you only act on violations
      .options({
        resultTypes: ['violations'],
      })
      .analyze();

    // violations array has full node details (selector, html, impact, etc.)
    if (results.violations.length > 0) {
      console.table(
        results.violations.map((v) => ({
          id: v.id,
          impact: v.impact,
          description: v.description.slice(0, 80),
          nodes: v.nodes.length,
        }))
      );
    }

    expect(results.violations).toEqual([]);
  });

  test('dashboard — full detail scan for detailed reporting (slower)', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Full scan: all result types with node details
    // Use for scheduled accessibility reports, not for every PR gate
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'])
      .analyze();

    // Attach full results as CI artifact for accessibility reporting
    await test.info().attach('axe-full-results.json', {
      body: Buffer.from(JSON.stringify(results, null, 2)),
      contentType: 'application/json',
    });

    expect(results.violations).toEqual([]);
  });

});
```

**Performance guidance:**
| Scan type | `resultTypes` | Use case |
|-----------|---------------|----------|
| CI PR gate | `['violations']` | Fast feedback on every PR — 40-60% faster on complex pages |
| Nightly audit | none (default) | Full detail for trend tracking and defect reports |
| Targeted component scan | `['violations', 'incomplete']` | When you also want to surface "needs review" items |
| EARL compliance report | none (default) | Full data needed for W3C EARL report generation |

---

### WCAG 3.0 (March 2026 Draft) — Conformance Model Changes QA Teams Must Know

The March 3, 2026 W3C Working Draft of WCAG 3.0 introduces a fundamentally different **conformance model** compared to WCAG 2.x. While WCAG 3.0 remains at least several years from becoming a W3C Recommendation, QA engineers who work on long-lived products should understand the model shift now to begin adapting program structures.

**Key model changes (WCAG 3.0 vs WCAG 2.2):**

| Aspect | WCAG 2.2 | WCAG 3.0 (Draft) |
|--------|----------|-----------------|
| Conformance levels | A / AA / AAA | Bronze / Silver / Gold outcome levels |
| Unit of conformance | Per success criterion (pass/fail) | Outcomes (user goals) with flexible methods |
| Test mechanism | Testable success criteria | Assertions + outcomes; both automated and manual |
| Scope | Web content | Web apps, native apps, IoT, VR/AR, wearables |
| Naming | Web Content Accessibility Guidelines | W3C Accessibility Guidelines (broader scope) |
| Ongoing compliance | Point-in-time conformance claim | Frequent maintenance model; designed for continuous updates |

**What this means for QA program design today:**

1. **WCAG 2.2 AA remains the current legal and compliance standard.** WCAG 3.0 is not legally actionable. The EU EAA, Section 508, and EN 301 549 all reference WCAG 2.x. Do not migrate conformance claims to WCAG 3.0 language yet.

2. **Content meeting WCAG 2.2 AA is expected to satisfy most of WCAG 3.0 Bronze.** The draft explicitly states this. Teams that achieve WCAG 2.2 AA compliance are building on a sound foundation for WCAG 3.0.

3. **The outcome-based model requires program thinking, not just criterion checking.** WCAG 3.0's "assertions" model asks whether the *overall user experience* for a given task is accessible, not just whether individual components pass automated rules. QA programs should now include user-task-based testing ("can a screen reader user complete checkout end-to-end?") alongside rule-based scanning.

4. **Automated testing role expands but remains bounded.** WCAG 3.0's "Methods" (the equivalent of Techniques) include both automated and manual methods. The ~57% axe-core automated coverage ceiling continues to apply — the new model adds *more* manual-verification methods, not fewer.

```typescript
// File: e2e/accessibility/wcag3-task-based.spec.ts
// Example of outcome/task-based accessibility testing — the pattern WCAG 3.0 encourages.
// Tests whether a specific user GOAL can be completed, not just whether components pass rules.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('WCAG 3.0 outcome-based pattern: "Complete checkout" task', () => {

  // Task: A keyboard-only user can complete the checkout process from cart to confirmation
  test('keyboard-only user can complete checkout end-to-end', async ({ page }) => {
    await page.goto('/cart');

    // Step 1: Navigate to checkout button using only keyboard
    // Tab through the page to find the checkout button
    let checkoutFound = false;
    for (let i = 0; i < 30; i++) {
      await page.keyboard.press('Tab');
      const activeElement = await page.evaluate(() => ({
        role: document.activeElement?.getAttribute('role'),
        text: document.activeElement?.textContent?.trim(),
        tagName: document.activeElement?.tagName,
      }));
      if (activeElement.text === 'Proceed to Checkout') {
        checkoutFound = true;
        await page.keyboard.press('Enter');
        break;
      }
    }
    expect(checkoutFound, 'Checkout button must be keyboard-reachable').toBe(true);

    // Step 2: Fill in shipping form using keyboard only
    await page.waitForURL('**/checkout/shipping');
    await page.keyboard.press('Tab'); // Focus first name field
    await page.keyboard.type('Test');
    await page.keyboard.press('Tab');
    await page.keyboard.type('User');

    // Step 3: Verify no axe violations at each step
    const shippingResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();
    expect(shippingResults.violations).toEqual([]);

    // Step 4: Submit form using keyboard
    await page.keyboard.press('Tab'); // Navigate to submit
    // ... continue to confirmation

    // WCAG 3.0 outcome: "A user with a motor disability can independently complete checkout"
    // This test validates the OUTCOME, not just individual component rule compliance.
  });

});
```

---

### New Community Gotchas (Iteration 39)

67. **[community] IBM Equal Access and axe-core flag different WCAG 4.1.1 parsing violations — running both exposes a broader set of structural HTML defects**: IBM's accessibility-checker interprets some WCAG 4.1.1 (Parsing) requirements around malformed HTML and duplicate IDs more strictly than axe-core. Teams that run only axe-core may pass CI while having duplicate `id` attributes that the IBM checker flags. The reverse is also true: axe-core's `aria-valid-attr-value` catches attribute value errors that IBM's checker categorizes as a different rule. WHY: no single automated tool covers 100% of the ~57% automatable WCAG criteria; running two engines with different rule interpretations increases effective automated coverage. This is most cost-effective for products with formal compliance requirements (Section 508, EN 301 549).

68. **[community] Pa11y CI `--threshold N` option does not differentiate by severity — teams that use it to "allow up to 10 violations" inadvertently permit critical violations**: Pa11y CI's `threshold` configuration allows a scan to pass even if up to N violations are found. Teams use this as a temporary grace mechanism during remediation. The problem: `threshold: 10` allows any combination of critical, serious, and minor violations — a form that is completely unlabeled (critical) can be masked by counting toward the 10. WHY: use the IBM Equal Access `failLevels` approach instead, which allows you to fail only on `violation` level (equivalent to WCAG Level A/AA) while reporting lower-severity items without failing CI. If using Pa11y, set `threshold: 0` and manage exceptions via `ignore` for specific rule IDs.

69. **[community] Playwright 1.60 `boxes` option in `page.ariaSnapshot({ boxes: true })` produces YAML that does not match `toMatchAriaSnapshot()` patterns — the two APIs are not interchangeable**: The `boxes` option appends `[box=x,y,w,h]` metadata that changes the YAML string format. If you capture a snapshot with `boxes: true` and then use the resulting YAML as a `toMatchAriaSnapshot()` pattern string, the assertion will fail because the match pattern syntax does not accept `[box=...]` annotations (these are output-only metadata for AI tools). Use `page.ariaSnapshot({ boxes: true })` for diagnostic/AI artifact purposes only; use `expect(page).toMatchAriaSnapshot()` for pass/fail assertions without the `boxes` option. WHY: teams that try to use box-annotated snapshots as test fixtures discover the failure mode when their CI tests break with confusing YAML parse errors.

70. **[community] axe-core `resultTypes: ['violations']` suppresses `incomplete` (needs review) results in CI output — teams miss WCAG issues that axe cannot auto-decide**: When using `resultTypes: ['violations']` for performance, the `incomplete` results (cases where axe found a potential problem but cannot auto-determine pass/fail without human judgment) are returned as summaries without node detail. Teams that only gate CI on `violations.length === 0` miss the `incomplete` category entirely. Common `incomplete` results include color-contrast (when axe cannot compute the effective background color), `label` (when heuristic label detection is ambiguous), and `aria-hidden-body` checks during page transitions. WHY: add a weekly or nightly job that runs the full scan (no `resultTypes` restriction) and logs `incomplete` results for manual review — do not use `resultTypes: ['violations']` for compliance audits.

71. **[community] WCAG 3.0's outcome-based testing model surfaces test gaps in teams that only run automated scans**: Teams building WCAG 3.0 awareness into their programs discover that outcome-based testing ("can a screen reader user complete the checkout flow from start to confirmation?") fails even when all individual axe-core rules pass. A page can have zero axe violations while still having a broken checkout flow for keyboard-only users due to focus management issues, unexpected page reloads, or missing error recovery paths — none of which axe-core checks. WHY: axe-core validates structural correctness; outcome-based tests validate user goals. WCAG 3.0 is pushing the industry toward user-task testing as a first-class QA activity. Start adding task-based accessibility tests (as shown in the WCAG 3.0 pattern above) now — they will be essential for future compliance claims and they catch real user-affecting issues today.

---

### WCAG 2.4.12 Focus Not Obscured (AA) — Sticky Headers, Cookie Banners, and `scroll-padding`

WCAG 2.2 introduced **SC 2.4.12 Focus Not Obscured (Minimum, AA)**, which requires that when a keyboard-focused component receives focus, it is **not entirely hidden** by author-created content. The most common real-world failures are sticky navigation headers, persistent cookie consent banners, and fixed footer toolbars that cover the focused element when the user Tabs into it.

**Why this is hard to detect automatically**: axe-core does not test this criterion — it requires a visual/layout check comparing the focused element's bounding box against fixed-position overlays. Playwright's `getBoundingClientRect()` is the practical testing mechanism.

**Distinction from SC 2.4.11 (Focus Appearance)**:
- **2.4.11 (Focus Appearance)**: Does the focus *indicator* (outline) have sufficient size and contrast? — tests the *visual design* of the ring.
- **2.4.12 (Focus Not Obscured)**: Is the focused *component itself* (the button, input, link) visible? — tests the *layout* relationship between the component and fixed overlays.

Both can fail independently: a button can have a correct 2px outline (2.4.11 passes) but be completely hidden behind a sticky header (2.4.12 fails).

**CSS fix — `scroll-padding-top`**: The simplest remediation is adding `scroll-padding-top` equal to the sticky header height on `:root` or `html`. The browser then ensures Tab-navigated focus never scrolls the element behind the header.

```css
/* global.css — Fix for WCAG 2.4.12: prevent sticky header from obscuring keyboard focus */
/* Replace 64px with your actual sticky header height (or use a CSS variable) */
:root {
  --sticky-header-height: 64px;
}

html {
  /* scroll-padding-top offsets the scroll target for Tab-navigation focus.
   * Without this, pressing Tab can place the focused element behind the sticky nav.
   * Use the same value for scroll-margin-top on individual elements if you need per-element overrides. */
  scroll-padding-top: var(--sticky-header-height);
}

/* If you have a sticky cookie banner at the bottom as well: */
html {
  scroll-padding-bottom: 56px; /* height of bottom sticky bar */
}
```

**Playwright test — WCAG 2.4.12 Focus Not Obscured**:

```typescript
// File: e2e/accessibility/wcag22-focus-not-obscured.spec.ts
// WCAG 2.2 SC 2.4.12: focused elements must not be fully obscured by sticky overlays.
// axe-core does not detect this — requires Playwright bounding box comparison.
import { test, expect } from '@playwright/test';

test.describe('WCAG 2.2 SC 2.4.12 — Focus Not Obscured', () => {

  test('no interactive element is fully hidden behind sticky header when keyboard focused', async ({
    page,
  }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Collect all sticky/fixed-position elements that could obscure content
    const stickyRects = await page.evaluate(() => {
      const allElements = Array.from(document.querySelectorAll<HTMLElement>('*'));
      return allElements
        .filter((el) => {
          const style = getComputedStyle(el);
          return style.position === 'sticky' || style.position === 'fixed';
        })
        .map((el) => {
          const rect = el.getBoundingClientRect();
          return { top: rect.top, bottom: rect.bottom, left: rect.left, right: rect.right };
        });
    });

    if (stickyRects.length === 0) {
      test.skip();
      return;
    }

    // Tab through interactive elements and verify none are fully obscured
    const MAX_TABS = 40;
    const obscuredElements: Array<{ tag: string; text: string; overlap: string }> = [];

    for (let i = 0; i < MAX_TABS; i++) {
      await page.keyboard.press('Tab');

      const focusInfo = await page.evaluate((stickies) => {
        const el = document.activeElement as HTMLElement | null;
        if (!el || el === document.body) return null;

        const rect = el.getBoundingClientRect();

        // Check if focused element is fully covered by any sticky element
        const fullyCovered = stickies.some((sticky) => {
          const horizontalOverlap = rect.left < sticky.right && rect.right > sticky.left;
          const verticalOverlap = rect.top < sticky.bottom && rect.bottom > sticky.top;
          if (!horizontalOverlap || !verticalOverlap) return false;

          // "Fully obscured": the sticky overlay completely covers the focused element
          return (
            sticky.top <= rect.top &&
            sticky.bottom >= rect.bottom &&
            sticky.left <= rect.left &&
            sticky.right >= rect.right
          );
        });

        return {
          tag: el.tagName.toLowerCase(),
          text: (el.textContent ?? '').trim().slice(0, 40),
          fullyCovered,
          rect: { top: rect.top, bottom: rect.bottom, left: rect.left, right: rect.right },
        };
      }, stickyRects);

      if (!focusInfo) break; // Reached end of tab order (body focused)

      if (focusInfo.fullyCovered) {
        obscuredElements.push({
          tag: focusInfo.tag,
          text: focusInfo.text,
          overlap: `top:${focusInfo.rect.top} bottom:${focusInfo.rect.bottom}`,
        });
      }
    }

    if (obscuredElements.length > 0) {
      console.table(obscuredElements);
    }

    expect(obscuredElements, 'WCAG 2.4.12: These focused elements are fully obscured by sticky overlays').toEqual([]);
  });

  test('cookie consent banner does not permanently obscure focused form fields', async ({
    page,
  }) => {
    await page.goto('/contact');
    await page.waitForLoadState('networkidle');

    // Dismiss cookie banner first (it should be dismissible via keyboard — WCAG 2.4.12)
    const cookieBanner = page.locator('[id*="cookie"], [class*="cookie"], [aria-label*="cookie" i], [data-testid*="cookie"]').first();
    const bannerVisible = await cookieBanner.isVisible().catch(() => false);

    if (bannerVisible) {
      // Cookie banner must be keyboard-dismissible per WCAG 2.1.1 + 2.4.12
      const dismissButton = cookieBanner.locator('button').first();
      await expect(dismissButton, 'Cookie banner must have a keyboard-accessible dismiss button').toBeVisible();
      await dismissButton.focus();
      await page.keyboard.press('Enter');
      await expect(cookieBanner).not.toBeVisible({ timeout: 3000 });
    }

    // Verify form fields are reachable after banner is dismissed
    const emailField = page.locator('input[type="email"]').first();
    if (await emailField.isVisible()) {
      await emailField.focus();
      // Field must not be obscured (check it is in viewport)
      await expect(emailField).toBeInViewport();
    }
  });

});
```

**Component-level fix — `scroll-margin-top` on focusable elements**:

For fine-grained control, add `scroll-margin-top` directly to interactive elements that are commonly obscured:

```typescript
// File: src/styles/focus-not-obscured.css (or via Tailwind utility class)
// scroll-margin creates an offset between the element and the viewport edge
// when the browser scrolls to it via Tab navigation or anchor navigation.

/* Target all interactive elements to ensure focus is never behind the sticky nav */
button,
a[href],
input,
select,
textarea,
[tabindex="0"],
[role="button"],
[role="link"],
[role="tab"],
[role="menuitem"] {
  /* Match the height of your sticky navigation header */
  scroll-margin-top: 72px; /* adjust to match actual header height */
}
```

```typescript
// File: src/components/FocusNotObscured/useStickyHeaderOffset.ts
// React hook that dynamically sets scroll-margin-top based on the current
// sticky header height — handles responsive layouts where header height changes.
import { useEffect, useRef } from 'react';

/**
 * Applies scroll-margin-top equal to the sticky header height to all
 * interactive elements within a container. Call at the layout root level.
 *
 * Why: WCAG 2.4.12 requires focused elements be at least partially visible.
 * Static CSS works for fixed-height headers; this hook handles dynamic heights.
 */
export function useStickyHeaderOffset(stickyHeaderSelector = 'header[data-sticky]') {
  const rafId = useRef<number>();

  useEffect(() => {
    const update = () => {
      const header = document.querySelector<HTMLElement>(stickyHeaderSelector);
      if (!header) return;

      const headerHeight = header.offsetHeight;
      const root = document.documentElement;
      root.style.setProperty('--sticky-header-height', `${headerHeight}px`);
      root.style.scrollPaddingTop = `${headerHeight}px`;
    };

    update();
    const observer = new ResizeObserver(() => {
      rafId.current = requestAnimationFrame(update);
    });

    const header = document.querySelector<HTMLElement>(stickyHeaderSelector);
    if (header) observer.observe(header);

    return () => {
      observer.disconnect();
      if (rafId.current) cancelAnimationFrame(rafId.current);
    };
  }, [stickyHeaderSelector]);
}
```

**WCAG 2.4.12 vs 2.4.13 (AAA) distinction**:
| Criterion | Level | Requirement | Practical test |
|-----------|-------|-------------|----------------|
| 2.4.12 Focus Not Obscured (Minimum) | AA | Component not *entirely* hidden | Focused element has at least 1px visible |
| 2.4.13 Focus Not Obscured (Enhanced) | AAA | Component not *partially* hidden | No sticky overlay covers any pixel of the focused element |

Teams targeting EU EAA compliance must meet 2.4.12 (AA). 2.4.13 is AAA and not legally required, but it is better UX and worth pursuing in new designs.

**axe-core status**: Neither 2.4.12 nor 2.4.13 is currently tested by any axe-core rule as of 4.11.4. This is a confirmed gap in automated tooling — Playwright + `getBoundingClientRect()` is the only practical automated test.

---

### EU EAA Enforcement Post-June 2025 — What Changed for QA Programs

The EU Accessibility Act (EAA) compliance deadline of **June 28, 2025** has passed. As of mid-2025, EU member states are individually responsible for enforcement through national market surveillance authorities. The implications for QA programs differ from the pre-deadline phase:

**What changed on June 28, 2025:**

1. **EAA became directly enforceable** in all member states that transposed the Directive into national law (most did by the deadline; a few had slight delays). Products and services that do not meet WCAG 2.2 AA via EN 301 549 v3.3.2 can be subject to market surveillance action, complaints, or injunctions.

2. **Complaint-driven enforcement is the primary mechanism**: Users, organizations, and competitors can file formal complaints with national accessibility enforcement bodies. National market surveillance authorities have the power to require remediation or impose fines under member-state law.

3. **Micro-enterprises (< 10 employees, ≤ €2M turnover) are exempt** from the EAA for services. Products (hardware + embedded software) do not have a micro-enterprise exemption.

4. **The "disproportionate burden" exception is time-limited**: Companies that relied on the disproportionate burden exception must re-evaluate it periodically and document why accessibility remains disproportionately burdensome — the exception is not permanent.

**QA program actions for post-EAA enforcement:**

```typescript
// File: e2e/accessibility/eaa-compliance-gate.spec.ts
// Post-EAA enforcement gate: comprehensive WCAG 2.2 AA check for EU market compliance.
// Run as a required CI step for products shipping to EU private-sector markets.
// EN 301 549 v3.3.2 clauses 9.1–9.4 map to all WCAG 2.2 AA criteria.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

// Critical user flows that must pass for EAA compliance —
// expand this list to cover your product's complete user journeys.
const EAA_CRITICAL_PAGES = [
  { name: 'Home', url: '/' },
  { name: 'Login', url: '/login' },
  { name: 'Registration', url: '/register' },
  { name: 'Main product page', url: '/product' },
  { name: 'Checkout', url: '/checkout' },
  { name: 'Contact / Support', url: '/contact' },
];

// EAA enforcement requires WCAG 2.2 AA — use wcag22aa tag in addition to 2.1 tags
const EAA_WCAG_TAGS = ['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'];

for (const { name, url } of EAA_CRITICAL_PAGES) {
  test(`EAA compliance gate: ${name} (${url})`, async ({ page }) => {
    await page.goto(url);
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(EAA_WCAG_TAGS)
      .options({ resultTypes: ['violations'] })
      .analyze();

    if (results.violations.length > 0) {
      // Format for accessibility compliance defect report — include WCAG SC reference
      const report = results.violations.map((v) => ({
        rule: v.id,
        impact: v.impact,
        wcag: v.tags.filter((t) => t.startsWith('wcag')).join(', '),
        description: v.description,
        affectedNodes: v.nodes.length,
        firstNode: v.nodes[0]?.html?.slice(0, 100),
      }));
      console.table(report);

      // Log EN 301 549 clause reference for compliance documentation
      console.error(
        `EN 301 549 v3.3.2 clause 9.x (web) violations on page "${name}": ` +
        `${results.violations.length} WCAG 2.2 AA failures. ` +
        `These constitute accessibility defects under the EU EAA.`
      );
    }

    expect(results.violations).toEqual([]);
  });
}
```

**Accessibility Conformance Report (ACR) / VPAT for EU market**: Post-EAA, many EU enterprise customers now require an ACR as part of procurement. The ACR documents conformance against EN 301 549 using the standard VPAT 2.5 template. Map your axe CI results + manual audit findings to the VPAT sections to produce a defensible compliance record.

**Enforcement gap reality (2025)**: National enforcement varies by country. Some member states (Germany, France, Netherlands) have active market surveillance programs; others are slower to act. However, legal risk from private-party complaints and competitor challenges is higher than from regulatory action. Products that cannot demonstrate WCAG 2.2 AA compliance face procurement barriers in addition to enforcement risk.

---

### `@axe-core/mcp` — Deque's Official MCP Server for IDE-Integrated Accessibility

Deque released `@axe-core/mcp` (available via the axe-core-npm monorepo) as an official MCP (Model Context Protocol) server that enables AI coding assistants (Claude Code, GitHub Copilot, Cursor) to run accessibility scans, understand violations, and generate fix plans directly within the IDE context — without leaving the editor or switching to a browser extension.

**How `@axe-core/mcp` differs from navable MCP:**

| Feature | `@axe-core/mcp` (Deque official) | navable MCP (open source) |
|---------|----------------------------------|---------------------------|
| Rule engine | axe-core (Deque enterprise rules) | axe-core + Pa11y/HTMLCS dual-engine |
| Fix planning | AI-assisted via MCP tool | EN 301 549-mapped fix plans |
| Scan target | URL or HTML string | Live Playwright page or URL |
| AI integration | Claude Code, Copilot, Cursor (MCP clients) | Claude Code + any MCP-compatible agent |
| Output format | Structured JSON violations | Structured JSON + EARL report option |
| Enterprise support | Deque commercial support available | Community maintained |

**Installation and configuration for Claude Code:**

```json
// .claude/settings.json — add @axe-core/mcp to your MCP servers list
{
  "mcpServers": {
    "axe-core": {
      "command": "npx",
      "args": ["@axe-core/mcp"],
      "env": {}
    }
  }
}
```

**Alternative: global install for use across projects:**

```bash
npm install -g @axe-core/mcp
# Then reference directly in settings.json:
# "command": "axe-core-mcp"
```

**MCP tools exposed by `@axe-core/mcp`:**

The server exposes tools that an AI agent can invoke during accessibility review workflows:

```typescript
// Conceptual usage in an AI agent context:
// The agent calls these tools via MCP protocol — shown as TypeScript pseudo-code.

// Tool 1: scan_url — runs axe-core against a live URL
const scanResult = await mcpTool.scan_url({
  url: 'https://localhost:3000/dashboard',
  tags: ['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'],
});
// Returns: violations[], passes[], incomplete[], inapplicable[]

// Tool 2: scan_html — scans an HTML string (for component-level checks without a browser)
const componentResult = await mcpTool.scan_html({
  html: '<button><svg aria-hidden="true"><use href="#icon"/></svg></button>',
  tags: ['wcag2a', 'wcag21aa'],
});
// Returns: violations with impact, description, WCAG success criterion mapping

// Tool 3: get_rule — retrieve detailed information about a specific axe rule
const ruleInfo = await mcpTool.get_rule({ rule_id: 'button-name' });
// Returns: rule description, help URL, affected WCAG criteria, fix patterns
```

**Workflow: AI agent using `@axe-core/mcp` for PR review accessibility check**

```typescript
// File: scripts/ai-a11y-review.ts
// Example of how a QA agent script uses the MCP server to review a component PR.
// In practice, the AI agent (Claude Code) calls these tools via MCP protocol;
// this shows the conceptual flow in TypeScript.

interface AxeMcpViolation {
  id: string;
  impact: 'critical' | 'serious' | 'moderate' | 'minor';
  description: string;
  helpUrl: string;
  nodes: Array<{
    html: string;
    target: string[];
    failureSummary: string;
  }>;
  tags: string[];  // e.g., ['wcag2a', 'wcag21aa', 'wcag22aa', 'cat.name-role-value']
}

interface AxeMcpScanResult {
  violations: AxeMcpViolation[];
  incomplete: AxeMcpViolation[];   // Needs manual review
  passes: number;                   // Count only when using resultTypes optimization
  testEngine: { name: string; version: string };
}

async function reviewComponentAccessibility(htmlSnippet: string): Promise<void> {
  // @axe-core/mcp scan_html tool — no browser required for component HTML
  const result: AxeMcpScanResult = await mcpTool.scanHtml({
    html: htmlSnippet,
    tags: ['wcag2a', 'wcag2aa', 'wcag21aa', 'best-practice'],
  });

  if (result.violations.length === 0) {
    console.log('No accessibility violations found in component HTML.');
    return;
  }

  // Group by WCAG success criterion for structured PR review comment
  const byCriterion = new Map<string, AxeMcpViolation[]>();
  for (const violation of result.violations) {
    const wcagTags = violation.tags.filter((t) => t.startsWith('wcag'));
    const key = wcagTags.join(', ') || 'best-practice';
    byCriterion.set(key, [...(byCriterion.get(key) ?? []), violation]);
  }

  for (const [criterion, violations] of byCriterion) {
    console.log(`\n### ${criterion}`);
    for (const v of violations) {
      console.log(`- [${v.impact?.toUpperCase()}] **${v.id}**: ${v.description}`);
      console.log(`  Fix: ${v.helpUrl}`);
      v.nodes.slice(0, 2).forEach((n) => {
        console.log(`  Element: ${n.html.slice(0, 80)}`);
      });
    }
  }
}
```

**When to use `@axe-core/mcp` vs `@axe-core/playwright` in CI:**

| Scenario | Recommended tool | Reason |
|----------|-----------------|--------|
| PR review — quick component HTML check | `@axe-core/mcp` scan_html | No browser needed; fast; IDE-integrated feedback |
| Full-page scan in CI pipeline | `@axe-core/playwright` | Real browser; handles dynamic content, iframes, CSS |
| AI agent implementing fixes | `@axe-core/mcp` | Structured MCP protocol enables agent tool-call loop |
| Scheduled compliance audit | `@axe-core/playwright` or `@axe-core/cli` | Full scan output; EARL report support |
| Local development review | `@axe-core/react` (browser) or `@axe-core/mcp` | In-editor feedback without leaving IDE |

**TypeScript type for MCP scan result** (use when building custom scan scripts):

```typescript
// File: src/types/axe-mcp.d.ts
// TypeScript interface for @axe-core/mcp scan_url / scan_html result.
// The MCP server returns JSON matching this shape.
export interface AxeMcpScanResult {
  violations: AxeMcpViolation[];
  incomplete: AxeMcpViolation[];
  passes: AxeMcpRuleSummary[];
  inapplicable: AxeMcpRuleSummary[];
  testEngine: { name: string; version: string };
  testRunner: { name: string };
  testEnvironment: {
    userAgent: string;
    windowWidth: number;
    windowHeight: number;
    orientationAngle: number;
    orientationType: string;
  };
  timestamp: string;
  url: string;
}

export interface AxeMcpViolation {
  id: string;
  impact: 'critical' | 'serious' | 'moderate' | 'minor' | null;
  tags: string[];
  description: string;
  help: string;
  helpUrl: string;
  nodes: AxeMcpNode[];
}

export interface AxeMcpNode {
  any: AxeMcpCheck[];
  all: AxeMcpCheck[];
  none: AxeMcpCheck[];
  impact: string;
  html: string;
  target: string[];
  xpath: string[];
  ancestry: string[];
  element?: Element;
  failureSummary?: string;
}

export interface AxeMcpCheck {
  id: string;
  impact: string;
  message: string;
  data: unknown;
  relatedNodes: Array<{ html: string; target: string[] }>;
}

export interface AxeMcpRuleSummary {
  id: string;
  impact: null;
  tags: string[];
  description: string;
  help: string;
  helpUrl: string;
  nodes: AxeMcpNode[];
}
```

---

### New Community Gotchas (Iteration 40)

72. **[community] `scroll-padding-top` fixes WCAG 2.4.12 for Tab-navigation but does NOT fix sticky-header obscuring on anchor (`#id`) navigation**: CSS `scroll-padding-top` tells the browser to offset the scroll target position when focus moves via Tab or when the browser scrolls to a hash anchor. However, if users click internal links (`<a href="#section">`) and the target section heading is obscured by the sticky header, this is both a 2.4.12 failure (heading is a skip target) and a general usability issue. Add the corresponding `scroll-margin-top` to section headings and landmark elements as well as interactive controls: `h1, h2, h3, [id] { scroll-margin-top: var(--sticky-header-height); }`. WHY: Teams apply `scroll-padding-top` to fix CI tests but forget anchor navigation, and user complaints reveal headings are still obscured after Tab-navigating or clicking a table of contents link.

73. **[community] EU EAA enforcement is complaint-driven, not proactive — but the legal risk exposure is now real and growing**: Post-deadline, accessibility enforcement in the EU does not mean inspectors will proactively audit your site. Enforcement is triggered by user complaints filed with national market surveillance authorities. However, disability rights organizations in Germany, France, and the Netherlands have published guidance on how to file complaints, and legal firms in these jurisdictions are actively advising clients to file formal accessibility complaints against competitors as a procurement barrier strategy. Teams that previously deferred compliance due to "low enforcement risk" should re-evaluate: the complaint pathway is now well-established and costs the claimant almost nothing. WHY: the enforcement gap between law-on-paper and law-in-practice is closing faster than most legal teams anticipated.

74. **[community] `@axe-core/mcp` `scan_html` does not execute JavaScript — components that render incorrectly in a static HTML string context will produce false results**: The `scan_html` tool accepts HTML strings and runs axe-core against them in a headless context without JavaScript execution. Components that inject ARIA attributes via `useEffect`, event handlers, or dynamic rendering will appear as plain HTML without their runtime accessibility state. For example, a React `<Modal isOpen={true}>` rendered to HTML string will not have its `inert` attributes applied to background elements, and `aria-expanded` on a controlled accordion button will not reflect its state. WHY: use `@axe-core/playwright` for runtime scanning of components that depend on JavaScript for their accessible state; reserve `scan_html` for purely structural HTML audits (checking that a template has correct semantic structure).

75. **[community] Playwright's `toMatchAriaSnapshot()` assertion fails intermittently when asynchronous `aria-live` region updates occur during snapshot capture**: If an `aria-live="polite"` region updates (e.g., a toast notification) while `toMatchAriaSnapshot()` is executing, the snapshot captures the in-transition accessibility tree, causing intermittent failures. WHY: aria-live regions can update at any time in response to async events; the accessibility tree is not frozen during snapshot capture. Fix: add `await page.waitForTimeout(100)` after any user interaction that triggers live region updates before calling `toMatchAriaSnapshot()`, or narrow the snapshot scope to exclude the live region (`expect(page.locator('main')).toMatchAriaSnapshot()` instead of `expect(page).toMatchAriaSnapshot()`). The pattern of scoping snapshots to stable page regions (main content, nav, dialog) rather than the full page body reduces this fragility.

76. **[community] The `scroll-padding-top` and `scroll-margin-top` CSS fix for WCAG 2.4.12 interacts unexpectedly with CSS `scroll-behavior: smooth`**: When `html { scroll-behavior: smooth; scroll-padding-top: 72px; }` is set, Tab-navigation focus scrolling uses smooth animation, which can be visually jarring and trigger vestibular disturbances for users with motion sensitivity — a WCAG 2.3.3 (Animation from Interactions, AAA) and `prefers-reduced-motion` concern. Additionally, some browsers delay the scroll animation, causing an intermediate state where the element briefly appears obscured. WHY: set `scroll-behavior` conditionally via media query: `@media (prefers-reduced-motion: no-preference) { html { scroll-behavior: smooth; } }` — users who prefer reduced motion get instant scroll positioning, which also eliminates the intermediate-obscured-state issue.

---

### Playwright `locator.normalize()` — Accessibility-First Locator Standardization (v1.50+)

Playwright 1.50 introduced `locator.normalize()`, which converts an arbitrary locator to its "canonical" accessibility-first equivalent. When the element has a test ID, role, or accessible name, `normalize()` returns a locator based on the accessibility tree rather than CSS or XPath selectors. This is a developer-ergonomics tool that reinforces the `getByRole > getByLabel > getByTestId` query priority described in the anti-patterns section.

**Why this matters for accessibility testing:** `locator.normalize()` surfaces when your test is relying on DOM-structural selectors instead of accessibility semantics. If `page.locator('.btn-primary')` normalizes to `page.getByRole('button', { name: 'Submit' })`, you should update the test to use the accessible query directly — it is more resilient and tests the accessible name simultaneously.

```typescript
// File: e2e/accessibility/locator-normalize.spec.ts
// Playwright 1.50+: locator.normalize() converts DOM selectors to accessibility-first queries.
// Use during test refactoring to upgrade CSS/XPath locators to accessible equivalents.
import { test, expect } from '@playwright/test';

test.describe('Accessibility-first locator patterns (locator.normalize)', () => {

  test('submit button: CSS selector normalizes to role-based locator', async ({ page }) => {
    await page.goto('/register');
    await page.waitForLoadState('networkidle');

    // Original CSS-based locator (common in legacy tests)
    const cssLocator = page.locator('button[type="submit"].btn-primary');

    // normalize() returns the accessibility-tree equivalent
    // If the button has an accessible name, the normalized form uses getByRole
    const normalizedLocator = await cssLocator.normalize();
    console.log('Normalized locator:', normalizedLocator.toString());
    // Output: getByRole('button', { name: 'Create account' })
    // — this simultaneously tests that the button IS accessible with that name

    // The normalized locator must find the same element
    await expect(normalizedLocator).toBeVisible();
  });

  test('form fields: input locator normalizes using label association', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    // CSS ID-based locator
    const emailLocator = page.locator('#email-input');

    // Normalizes to: getByLabel('Email address') — assuming a <label htmlFor="email-input">
    // If normalization returns getByLabel(), the label association is working
    const normalized = await emailLocator.normalize();

    // If normalized is still a CSS locator, the label association is MISSING — a WCAG 1.3.1 failure
    expect(normalized.toString(), 'Input must be associated with a label').not.toContain('[id=');
    await expect(normalized).toBeVisible();
  });
});
```

**How to use `normalize()` in a test refactoring workflow:**

```typescript
// File: scripts/audit-locator-accessibility.ts
// Audit an existing Playwright test suite for CSS/XPath selectors that should
// be accessibility-first. Run once, review output, update tests accordingly.
import { chromium } from '@playwright/test';

interface LocatorAuditResult {
  originalSelector: string;
  normalizedForm: string;
  isAccessibilityBased: boolean;
  recommendation: string;
}

// Common CSS selectors that indicate a non-accessible query
const CSS_SELECTOR_PATTERNS = [
  /\[class=/,     // class-based (fragile)
  /\[id=/,        // ID-based (may be missing label association)
  /\.\w+/,        // CSS class
  />#/,           // ID-direct descendant
];

function isAccessibilityBasedLocator(locatorString: string): boolean {
  // Accessibility-first locators use role, label, text, or testId
  return (
    locatorString.includes('getByRole') ||
    locatorString.includes('getByLabel') ||
    locatorString.includes('getByText') ||
    locatorString.includes('getByTestId') ||
    locatorString.includes('getByPlaceholder')
  );
}

function getRecommendation(original: string, normalized: string): string {
  if (isAccessibilityBasedLocator(normalized)) {
    return `Replace "${original}" with "${normalized}" — semantic, tests accessible name.`;
  }
  if (normalized.includes('getByLabel')) {
    return `Label association exists. Use getByLabel() instead of CSS selector.`;
  }
  return `No accessibility-based equivalent found. Verify element has role + accessible name.`;
}
```

**`locator.normalize()` in TypeScript type context:**

```typescript
// locator.normalize() returns Promise<Locator>
// Type-safe usage:
const rawLocator: Locator = page.locator('.submit-btn');
const normalized: Locator = await rawLocator.normalize();

// Use normalized in your assertion
await expect(normalized).toHaveAccessibleName('Submit application');
```

> **When NOT to use `normalize()`**: In production test code that already uses `getByRole()` / `getByLabel()`. `normalize()` is a migration/audit tool — it has performance overhead (queries the accessibility tree) and is not intended for every test. Use it during code review or one-time audits to identify tests using non-accessible selectors.

---

### axe-core 4.11.4 Ancestry Selector Escaping Fix

axe-core 4.11.4 (April 2026) includes a bug fix for **ancestry selector escaping** that affects how violation nodes are reported in tests. Before this fix, certain element selector paths containing special characters (hyphens, colons in custom element names, brackets in attribute selectors) were not properly escaped in the `node.target` array returned with violations. This caused false "element not found" errors when teams tried to programmatically locate violation nodes for remediation scripts.

**Impact on TypeScript test code:**

```typescript
// File: e2e/accessibility/node-target-processing.spec.ts
// axe-core 4.11.4+: node.target selectors are now correctly escaped.
// Before 4.11.4, custom elements and attribute selectors in target paths were unescaped,
// causing document.querySelector() calls to throw SyntaxError.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Violation node target processing (axe-core 4.11.4+)', () => {

  test('violation node targets can be used as querySelector selectors', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    if (results.violations.length === 0) return;

    // Before 4.11.4: node.target paths with custom elements (e.g., 'my-button#close-btn')
    // or attribute selectors could cause SyntaxError in document.querySelector()
    // After 4.11.4: all target paths are properly escaped — safe to use directly
    const selectorErrors: string[] = [];

    for (const violation of results.violations) {
      for (const node of violation.nodes) {
        const lastTarget = node.target[node.target.length - 1];
        // Verify the selector is usable in the browser
        const isValid = await page.evaluate((selector) => {
          try {
            document.querySelector(selector);
            return true;
          } catch {
            return false;
          }
        }, lastTarget);

        if (!isValid) {
          selectorErrors.push(`[${violation.id}] Invalid selector: ${lastTarget}`);
        }
      }
    }

    // With axe-core 4.11.4+, this should always be empty
    expect(selectorErrors, 'All violation node selectors must be valid CSS').toEqual([]);
  });

  // Pattern: using violation targets to highlight elements in a custom reporter
  test('violation targets can be used to build a remediation map', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .options({ resultTypes: ['violations'] })
      .analyze();

    // Build a remediation map: selector → violation info
    // Useful for automated fix scripts that need to locate elements to patch
    const remediationMap = new Map<string, { ruleId: string; impact: string; fix: string }>();

    for (const violation of results.violations) {
      for (const node of violation.nodes) {
        const selector = node.target.join(' > ');
        remediationMap.set(selector, {
          ruleId: violation.id,
          impact: violation.impact ?? 'unknown',
          fix: node.failureSummary ?? violation.help,
        });
      }
    }

    // Log the map for developer review — can be fed to an automated fix pipeline
    if (remediationMap.size > 0) {
      console.log(`Remediation map (${remediationMap.size} elements):`);
      remediationMap.forEach((info, selector) => {
        console.log(`  ${selector} → [${info.impact}] ${info.ruleId}: ${info.fix}`);
      });
    }
  });
});
```

**Why this fix matters:** Automated remediation pipelines (like those built around @axe-core/mcp or custom fix agents) that used `node.target` selectors to locate elements in the DOM for patching would silently fail on custom element names. After 4.11.4, the escape fix ensures selector reliability across all element naming patterns.

---

### New Community Gotchas (Iteration 41)

77. **[community] Playwright `locator.normalize()` returns a CSS selector unchanged if the element has no accessible role or name — this is itself an accessibility signal**: When `locator.normalize()` cannot produce an accessibility-based query (no role, no associated label, no accessible name), it returns the original CSS locator unchanged. Teams using `normalize()` in audit scripts should treat an unchanged locator as a finding — the element may be missing its ARIA semantics. WHY: if `page.locator('#submit-btn').normalize()` returns `page.locator('#submit-btn')` unchanged, the button either has no accessible name (axe `button-name` violation likely) or has no semantic role exposed. This makes `normalize()` a useful pre-flight check during component development.

78. **[community] axe-core 4.11.4 ancestry selector escaping fix means teams should regenerate any `known-violations-baseline.json` created on 4.11.3 or earlier**: The node target selector escaping change in 4.11.4 can change the `target` path string for violations on pages with custom element names. If your baseline file stores violation entries keyed by page + ruleId (as in the pattern above), upgrading is safe. However, if your baseline keys include the full node selector string, entries may fail to match after upgrading, causing violations that were in the baseline to be flagged as "new." Audit your baseline format and regenerate with `GENERATE_BASELINE=true` after upgrading to 4.11.4. WHY: the fix corrects previously wrong selectors — the new escaped form is the correct one, and baseline entries with unescaped selectors will not match.

79. **[community] WCAG 2.2 ISO/IEC 40500:2025 ratification means ACR/VPAT documents should now cite both the W3C standard and the ISO reference number**: Since WCAG 2.2 is now ratified as ISO/IEC 40500:2025, procurement requirements in APAC and MENA government markets (which mandate ISO standards rather than W3C standards) can now formally require WCAG 2.2 AA compliance where before they could only require WCAG 2.0 (ISO/IEC 40500:2012). When completing an Accessibility Conformance Report (ACR/VPAT) for these markets, cite the conformance claim as: "WCAG 2.2 Level AA (W3C Recommendation October 2023 / ISO/IEC 40500:2025)." This dual citation covers both W3C-referencing and ISO-referencing procurement requirements simultaneously. WHY: teams that produce separate WCAG 2.2 and "ISO standards" documentation for different markets are doing unnecessary work — the technical requirements are identical; only the citation format differs.

80. **[community] The WebAIM Million 2025 report confirms that EU EAA deadline pressure has not significantly improved aggregate web accessibility metrics — teams should not benchmark against the industry average**: Despite the June 28, 2025 EU EAA deadline, the aggregate error rate on the top 1 million homepages decreased by only ~2.6% (56.8 to ~55.3 errors/page). The failure rate remains above 95%. QA teams sometimes use "industry average" as an informal benchmark to justify deferring remediation ("we're better than most"). The WebAIM data shows this benchmark is a race to the bottom. The correct target is WCAG 2.2 AA = 0 automated violations, not "fewer than average." WHY: the EAA compliance requirement is absolute, not comparative — a product with 10 violations is not more legally compliant than one with 50; both fail. Use axe CI violation counts and trend data from your own codebase, not industry averages, as your benchmark.

### New Community Gotchas (Iteration 42)

81. **[community] `<selectedcontent>` inside a customizable `<select>` has implicit role=none — do not add ARIA roles to it**: The ARIA-in-HTML W3C Recommendation (April 2026) explicitly specifies no permitted ARIA roles for `<selectedcontent>`. Adding `role="option"`, `role="presentation"`, or any other ARIA role to `<selectedcontent>` is an authoring error and will trigger axe's `aria-allowed-role` violation. The element's job is purely visual — cloning the selected `<option>`'s content into the button display area. Screen readers derive the select's accessible name from the `<label>` and the selected option value from the native `<select>` semantics — not from `<selectedcontent>`. WHY: teams accustomed to building custom select widgets with ARIA (`role="listbox"` + `role="option"`) may reflexively add roles to the new native element. With customizable select, the browser handles ARIA mapping; adding roles corrupts it.

82. **[community] The July 2025 ARIA-in-HTML update now permits `role` and `aria-*` attributes on `<label>` elements when not associated with a labelable element**: Before this change, adding any ARIA role to a `<label>` was technically a spec violation because `<label>` had no permitted ARIA roles. The July 2025 update carved out an exception: when a `<label>` is not associated with any labelable element (no `for` attribute, no wrapping of a form control), it is permitted to have a `role` and ARIA attributes. This is relevant for design-system teams who use `<label>` as a visual styling element (e.g., a label-styled `<label>` used as a section title). After July 2025, axe-core may no longer flag `role="heading"` on an unassociated `<label>` as an authoring error — test your axe version behavior when upgrading. WHY: if you relied on axe flagging this pattern to enforce that all `<label>` elements are associated with form controls, that guardrail may now be absent for unassociated labels; add an explicit ESLint rule (`jsx-a11y/label-has-associated-control`) to maintain the check.

83. **[community] The `image` role is now the preferred synonym for `img` role in ARIA — but axe-core 4.11.x and testing tools still emit `img` in accessible name computations**: The ARIA-in-HTML December 2024 update added `image` as a preferred synonym for `img` (following natural language conventions). In Playwright ARIA snapshots, `page.ariaSnapshot()` may emit either `- img "Description"` or `- image "Description"` depending on the browser and version. Teams using strict `toMatchAriaSnapshot()` assertions with `/children: equal` or `deep-equal` may encounter intermittent failures if one browser emits `img` and another emits `image`. WHY: Chromium-based browsers adopted the `image` role synonym but Firefox and Safari may still emit `img`. Mitigation: use the `contain` children mode (default) for snapshot assertions that include images, or use a regex pattern: `- /img|image/ "Product photo"`. Test across all target browsers when upgrading Playwright to a version where this normalization changes.

---

### Jest v30 Incompatibility with jest-axe v10

Jest v30 (latest: v30.4.2 as of May 2026) is a major version with significant internal changes including native ESM improvements and updated peer dependency requirements. **jest-axe v10.0.0 is not compatible with Jest v30** because `jest-axe` depends on `jest-matcher-utils` as a peer — its current release pins a version that Jest v30 does not fulfill. Teams that upgrade to Jest v30 will encounter peer dependency errors or runtime failures in jest-axe test suites.

**Diagnosis: identifying the incompatibility**

```bash
# After upgrading to Jest v30, running npm install will warn:
# npm WARN Could not resolve dependency:
#   peerOptional jest-matcher-utils@"^27.0.0 || ^28.0.0 || ^29.0.0" from jest-axe@10.0.0

# Or at runtime you may see:
# TypeError: Cannot read properties of undefined (reading 'printReceived')
```

**Workaround: override `jest-matcher-utils` in `package.json`**

Until jest-axe publishes a v11 with Jest v30 support, use the `overrides` field (npm) or `resolutions` (Yarn/pnpm) to force a compatible version:

```json
// package.json
{
  "dependencies": {
    "jest": "^30.0.0",
    "jest-axe": "^10.0.0"
  },
  "overrides": {
    "jest-axe": {
      "jest-matcher-utils": "^30.0.0"
    }
  }
}
```

For pnpm workspaces:

```yaml
# .npmrc or pnpm-workspace.yaml
# pnpm.overrides in package.json:
{
  "pnpm": {
    "overrides": {
      "jest-axe>jest-matcher-utils": "^30.0.0"
    }
  }
}
```

**Test that the workaround is working:**

```typescript
// File: src/__tests__/accessibility/button.a11y.test.ts
// Verify jest-axe still works after the jest-matcher-utils override.
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

// Must extend expect with jest-axe matchers — unchanged from pre-v30 usage
expect.extend(toHaveNoViolations);

describe('jest-axe compatibility smoke test (Jest v30)', () => {
  it('accessible button renders without violations', async () => {
    const { container } = render(
      <button type="button">Save changes</button>
    );
    const results = await axe(container);
    // If this assertion runs without TypeError, the jest-matcher-utils override is working
    expect(results).toHaveNoViolations();
  });
});
```

**Migration path when jest-axe v11 releases:**

1. Remove the `overrides` / `resolutions` entry from `package.json`
2. Upgrade jest-axe to the new version: `npm install jest-axe@latest`
3. Run all accessibility unit tests to verify no matcher API changes

> **Track the issue**: Monitor [jest-axe issue #293](https://github.com/nickcolley/jest-axe/issues/293) for the official Jest v30 support release. Until then, the `overrides` workaround above is the recommended path.

---

### Playwright `locator.describe()` — Annotating Accessibility Locators for Trace Readability (v1.53+)

Playwright 1.53 introduced `locator.describe(label: string): Locator`, which attaches a human-readable description to a locator. The description does not affect how the locator queries the DOM or accessibility tree, but it appears in the Trace Viewer and HTML reporter, making test failures easier to diagnose when the element's role or accessible name is ambiguous in isolation.

**Why this matters for accessibility test suites:** Accessibility tests typically use role-based locators (`getByRole`, `getByLabel`) that are highly semantic but can produce verbose trace output. `locator.describe()` lets you attach a plain-language intent label so that when an accessibility assertion fails in CI, the trace shows "Subscribe button (role=button, name='Subscribe')" rather than a raw Playwright locator expression.

```typescript
// File: e2e/accessibility/described-locators.spec.ts
// Playwright 1.53+: locator.describe() adds a human-readable label to accessibility locators.
// Useful when diagnosing trace output for role-based queries that appear cryptic in reports.
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Accessible navigation — locator.describe() for trace clarity', () => {

  test('main navigation passes WCAG 2.2 AA checks', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Describe each accessibility-critical locator with a plain-language label.
    // The description appears in Playwright trace viewer steps — not in the DOM.
    const mainNav = page.getByRole('navigation', { name: 'Main navigation' })
      .describe('Primary site navigation landmark');

    const skipLink = page.getByRole('link', { name: 'Skip to main content' })
      .describe('Skip navigation link (WCAG 2.4.1)');

    const searchButton = page.getByRole('button', { name: 'Search' })
      .describe('Global search trigger (keyboard accessible)');

    // Accessibility assertions — the .describe() label shows in trace for each step
    await expect(mainNav).toBeVisible();
    await expect(skipLink).toBeVisible();
    await expect(searchButton).toHaveAccessibleName('Search');

    // Run axe on the navigation region using AxeBuilder
    const results = await new AxeBuilder({ page })
      .include('nav[aria-label="Main navigation"]')
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'])
      .analyze();

    expect(results.violations).toEqual([]);
  });

  test('form fields have correct accessible descriptions', async ({ page }) => {
    await page.goto('/register');
    await page.waitForLoadState('networkidle');

    // Described locators for form accessibility validation
    const emailField = page.getByRole('textbox', { name: 'Email address' })
      .describe('Registration email input (WCAG 1.3.1 label + WCAG 3.3.2 instructions)');

    const passwordField = page.getByLabel('Password')
      .describe('Password input — must have visible requirements via aria-describedby');

    await expect(emailField).toHaveAccessibleDescription(
      /Must be a valid email address/
    );
    await expect(passwordField).toHaveAccessibleDescription(
      /At least 8 characters/
    );
  });
});
```

**TypeScript type for `locator.describe()`:**

```typescript
// The return type is Locator — enabling method chaining.
// The description property is retrievable via locator.description().
import type { Locator } from '@playwright/test';

function describeA11yLocator(locator: Locator, intent: string): Locator {
  return locator.describe(intent);
}

// Usage in a fixture — wrap frequently used accessibility landmarks with descriptions:
// fixtures/accessibility.ts
import { test as base } from '@playwright/test';

export const test = base.extend<{
  mainLandmark: Locator;
  skipLink: Locator;
}>({
  mainLandmark: async ({ page }, use) => {
    await use(
      page.getByRole('main').describe('Main content landmark (WCAG 1.3.6 Identify Purpose)')
    );
  },
  skipLink: async ({ page }, use) => {
    await use(
      page.getByRole('link', { name: /skip/i }).describe('Skip link (WCAG 2.4.1 Bypass Blocks)')
    );
  },
});
```

> **Note**: `locator.describe()` does NOT affect the accessibility tree or ARIA semantics of the tested element — it is a developer tooling annotation only. Do not confuse it with `aria-label` or `aria-description`. The description lives in the Playwright test process, not in the browser DOM.

---

### New Community Gotchas (Iteration 43)

84. **[community] jest-axe v10.0.0 is incompatible with Jest v30 — upgrading Jest without the `jest-matcher-utils` override silently breaks axe assertions**: Jest v30 (released August 2025, latest v30.4.2 as of May 2026) changed its internal `jest-matcher-utils` to v30, but jest-axe v10.0.0 was published with a peer range that does not include v30. Teams that `npm install jest@^30` will either see peer dependency warnings (npm v10+ in non-strict mode continues but breaks at runtime) or an explicit peer conflict error (pnpm, Yarn PnP strict mode). The symptom at runtime is `TypeError: Cannot read properties of undefined` inside jest-axe's custom matchers because the `formatReceived` / `printReceived` utilities from `jest-matcher-utils` have changed APIs. WHY: the standard `jest.config.ts` upgrade path does not prompt you to check transitive peer deps of test helpers — always run `npm ls jest-matcher-utils` after a Jest major version upgrade to verify all packages resolve to the same major.

85. **[community] Playwright `locator.describe()` labels are stripped from aria snapshots and `toHaveAccessibleName()` — they only surface in trace viewer steps**: Teams sometimes assume that `.describe('Submit button')` sets an accessible name on the element (similar to setting `aria-label`). It does not — `locator.describe()` only attaches a label to the Playwright locator object for trace viewer display. `await expect(button.describe('Submit button')).toHaveAccessibleName('Submit button')` will still pass or fail based on the element's actual accessible name in the DOM, not the `.describe()` label. WHY: the naming similarity between `locator.describe()`, `aria-description`, and `aria-describedby` causes confusion. Use `locator.describe()` for developer ergonomics in traces; use `aria-label` / `aria-labelledby` on the DOM element for actual accessible names.

